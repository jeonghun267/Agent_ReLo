import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/input_rules.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/claim_rules.dart';
import '../../shared/models/claim_words.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/evidence_source_sheet.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../assistant/assistant_sheet.dart';
import 'agent_sheet.dart';
import 'deadline_sheet.dart';
import 'dispute_guide.dart';
import 'receipt_section.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/claims/claim_detail_screen
/// @layer Feature Module — Individual Claim Workspace
/// @purpose 환불 건 하나를 끝까지 따라가는 화면 (DESIGN.md 7절 "상세").
///          위에서 아래로: 무엇을 · 받기로 한 돈 / 받은 돈 · 지금 단계와 할 일 →
///          AI에게 맡기기 한 줄(누르면 아래 시트. AI가 물어볼 것이 있으면 여기에 알린다) →
///          막혔을 때의 길(분쟁 해결 안내 · 다른 해결 방법 보기 · 다시 열기) →
///          글자 탭 넷(메시지 · 답장 · 입금 · 기록) → 아래 고정 "이 건 물어보기".
///          교환은 돈 대신 받은 수량, 수리는 수리 결과로 보여 준다.
///          홈·내 환불과 같이 상자 없이 바탕 위에 바로 놓고, 화면을 열면 지금 단계에 맞는 탭이 켜져 있다.
class ClaimDetailScreen extends StatefulWidget {
  final String claimId;

  /// 목록에서 줄이 커지며 열렸을 때(OpenContainer)는 라우트를 닫는다.
  /// 없으면 스토어의 상세 선택을 해제한다.
  final VoidCallback? onClose;

  const ClaimDetailScreen({super.key, required this.claimId, this.onClose});

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  /// 지금 언어의 문구
  ReloStrings get _s => ReloScope.of(context).strings;

  /// 세 번째 탭은 받는 것의 이름을 딴다: 환불은 입금, 교환은 교환품, 수리는 수리
  List<String> _tabsFor(ClaimView c) =>
      [_s.dTabMessage, _s.dTabReply, _s.cwTabReceive(c.kind), _s.dTabHistory];

  int _activeTab = 0;
  bool _tabTaken = false;
  bool _agentAsked = false;

  final _draftCtrl = TextEditingController();
  final _submissionNoteCtrl = TextEditingController();
  bool _noteSeeded = false;
  bool _generatingDraft = false;
  bool _submittingDraft = false;

  final _replyCtrl = TextEditingController();
  final _agreedAmountCtrl = TextEditingController();
  String _replyKind = 'agreement';
  String _summaryKo = '';
  String _translationKo = '';

  /// AI가 요약 · 번역한 답장의 글. 그 뒤에 글을 고쳤다면 요약은 그 글의 것이 아니다.
  String _analyzedReply = '';
  bool _analyzingReply = false;
  bool _savingReply = false;

  bool _finishing = false;
  bool _addingFile = false;
  bool _showDepositConfetti = false;

  /// 칸마다의 오류 (칸 아래 빨간 글자). 키: draft, reply, agreed
  final Map<String, String> _fieldErrors = {};
  late final ConfettiController _confetti =
      ConfettiController(duration: ReloMotion.celebrate);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ReloScope.of(context);
    final claim = store.findClaim(widget.claimId);
    // 도우미가 "판매자 메시지 쓰기"·"답장 붙여 넣기"로 열었으면 그 탭부터,
    // 아니면 지금 단계에서 할 일이 있는 탭부터 보여 준다
    if (!_tabTaken) {
      _tabTaken = true;
      _activeTab = store.pendingDetailSubTab ??
          (claim == null ? 0 : _tabForState(claim));
      store.pendingDetailSubTab = null;
    }
    // 보낸 곳 메모의 기본 글은 지금 언어로 한 번만 채운다
    if (!_noteSeeded) {
      _noteSeeded = true;
      _submissionNoteCtrl.text = _s.dNoteDefault;
    }
    // 열 때 한 번, AI가 이 건을 살펴보는 중인지 · 물어볼 것이 있는지 서버에 묻는다 (AI를 부르지 않는다)
    if (!_agentAsked && claim != null && store.agentAvailableFor(claim)) {
      _agentAsked = true;
      store.refreshAgentOverview(claim.id);
    }
    if (claim != null) {
      if (_draftCtrl.text.isEmpty && claim.drafts.isNotEmpty) {
        // 저장된 글 끝의 [이름] 자리는 기기에서 계정의 이름으로 채운다
        _draftCtrl.text = store.signAsMe(claim.drafts.first.body);
      }
      // 약속 금액은 이미 적어 둔 것이 있을 때만 채운다 (아직 약속이 없으면 비워 둔다)
      if (_agreedAmountCtrl.text.isEmpty && claim.agreed != null) {
        _agreedAmountCtrl.text = MoneyFormat.minorToDecimalString(
          claim.agreed!,
          claim.currency,
        );
      }
    }
  }

  @override
  void dispose() {
    _draftCtrl.dispose();
    _submissionNoteCtrl.dispose();
    _replyCtrl.dispose();
    _agreedAmountCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  /// 지금 단계에서 먼저 볼 탭: 메시지 보낼 차례 → 메시지, 답장 기다리는 중 · 약속 금액 적을 차례 → 답장,
  /// 그 뒤 → 받은 것 기록
  int _tabForState(ClaimView claim) {
    if (claim.state == 'preparing' || claim.state == 'review') return 0;
    return switch (nextStepCode(claim)) {
      'awaiting' || 'needAgreed' => 1,
      _ => 2,
    };
  }

  /// 여섯 단계 중 몇 번째인지 (0부터)
  int _stepIndex(String state) => switch (state) {
        'preparing' => 0,
        'review' => 1,
        'awaiting' => 2,
        'negotiating' || 'disputed' || 'waived' => 3,
        'partial' || 'recovered' => 4,
        'completed' => 5,
        _ => 0,
      };

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) setState(() => _fieldErrors.remove(key));
  }

  /// 저장을 맡기고, 서버가 거절하면 그 까닭을 알린다. 됐으면 true.
  /// (전에는 서버가 거절해도 기기 안에서만 된 것처럼 바꿨다.)
  Future<bool> _attempt(ReloStore store, Future<void> Function() work) async {
    try {
      await work();
      return true;
    } on ApiError catch (e) {
      if (mounted) _toast(store.refusalText(e));
      return false;
    }
  }

  Future<void> _handleGenerateDraft(ReloStore store, ClaimView claim) async {
    setState(() => _generatingDraft = true);
    final generated = await store.generateForeignDraft(claim);
    if (!mounted) return;
    setState(() {
      _generatingDraft = false;
      _draftCtrl.text = generated.body;
      _fieldErrors.remove('draft');
    });
    // 기본 틀로 채웠으면 AI가 쓴 글이 아니라고 알린다
    if (generated.notice != null) _toast(generated.notice!);
  }

  Future<void> _handleSaveSubmitDraft(ReloStore store, ClaimView claim) async {
    if (_draftCtrl.text.trim().isEmpty) {
      setState(() => _fieldErrors['draft'] = _s.dErrDraft);
      return;
    }
    setState(() => _submittingDraft = true);
    final ok = await _attempt(
      store,
      () => store.saveAndSubmitDraft(
        claim.id,
        _draftCtrl.text.trim(),
        _submissionNoteCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _submittingDraft = false);
    if (ok) _toast(_s.dToastSent);
  }

  Future<void> _handleAnalyzeReply(ReloStore store, ClaimView claim) async {
    // 빈 칸에 판매자가 보내지도 않은 답장을 채워 넣지 않는다 (전에는 예시 답장을 넣었다)
    if (_replyCtrl.text.trim().isEmpty) {
      setState(() => _fieldErrors['reply'] = _s.dErrReply);
      return;
    }
    setState(() => _analyzingReply = true);
    final asked = _replyCtrl.text.trim();
    try {
      final res = await store.analyzeSellerReply(claim, asked);
      if (!mounted) return;
      setState(() {
        _analyzingReply = false;
        _fieldErrors.remove('reply');
        _summaryKo = res.summaryKo;
        _translationKo = res.translationKo;
        _analyzedReply = asked;
        if (res.mentionedAmount != null && res.mentionedAmount!.isNotEmpty) {
          _agreedAmountCtrl.text = res.mentionedAmount!;
        }
      });
    } on AiUnavailable catch (e) {
      if (!mounted) return;
      setState(() => _analyzingReply = false);
      // 읽지 못했으면 요약을 지어내지 않고, 답장은 그대로 저장할 수 있다고 알린다
      _toast('${e.message} ${_s.dReplySaveAnyway}');
    }
  }

  Future<void> _handleSaveReply(ReloStore store, ClaimView claim) async {
    final errors = <String, String>{};
    if (_replyCtrl.text.trim().isEmpty) {
      errors['reply'] = _s.dErrReply;
    }
    // 약속한 금액은 비워 둘 수 있다 (아직 약속이 없을 때). 적었다면 금액이어야 한다.
    final agreedText = _agreedAmountCtrl.text.trim();
    if (agreedText.isNotEmpty && InputRules.amount(agreedText) == null) {
      errors['agreed'] = _s.cmErrAmount;
    }
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors.addAll(errors));
      return;
    }
    setState(() => _savingReply = true);
    final raw = _replyCtrl.text.trim();
    // AI의 요약 · 번역은 AI가 바로 이 글을 읽은 것일 때만 함께 저장하고, 그때만 AI가 도왔다고 적는다.
    // (전에는 AI를 쓰지 않아도 "AI가 도움"으로 저장했고, 번역 칸에는 원문을 그대로 넣었다.)
    final byAi = _summaryKo.isNotEmpty && _analyzedReply == raw;
    final ok = await _attempt(
      store,
      () => store.saveReplyAndAgreedAmount(
        claimId: claim.id,
        rawReply: raw,
        replyKind: _replyKind,
        summaryKo: byAi ? _summaryKo : '',
        translationKo: byAi ? _translationKo : '',
        agreedAmountStr: _agreedAmountCtrl.text.trim(),
        aiAssisted: byAi,
      ),
    );
    if (!mounted) return;
    setState(() {
      _savingReply = false;
      if (ok) {
        // 저장했으니 아래 상자는 저장된 답장을 보여 준다
        _summaryKo = '';
        _translationKo = '';
        _analyzedReply = '';
      }
    });
    if (ok) _toast(_s.dToastReplySaved);
  }

  /// 받기로 한 것을 다 받았을 때 맨 위의 "마무리하기"
  Future<void> _handleFinish(ReloStore store, ClaimView claim) async {
    setState(() => _finishing = true);
    final ok = await _attempt(store, () => store.completeClaim(claim.id));
    if (!mounted) return;
    setState(() => _finishing = false);
    if (ok) _toast(_s.dToastDone);
  }

  /// 쇼핑몰과 정한 해결 방법을 바꾼다 (환불 ↔ 교환 ↔ 수리)
  Future<void> _handleChangeKind(
      ReloStore store, ClaimView claim, String kind) async {
    if (kind == claim.kind) return;
    final ok =
        await _attempt(store, () => store.changeClaimKind(claim.id, kind));
    if (ok && mounted) _toast(_s.cwToastMethod);
  }

  /// 판매자가 정한 기한을 적는다 (마감 알림이 이 날짜를 본다)
  Future<void> _handleDeadline(ClaimView claim) async {
    final saved = await showDeadlineSheet(context, claim);
    if (saved == null || !mounted) return;
    _toast(saved ? _s.dToastDeadline : _s.dToastDeadlineCleared);
  }

  /// 영수증 · 사진을 기기에서 골라 이 건에 붙인다
  Future<void> _handleAddFile(ReloStore store, ClaimView claim) async {
    if (_addingFile) return;
    final picked = await pickEvidenceWithSheet(context);
    if (picked == null || !mounted) return;
    setState(() => _addingFile = true);
    final ok = await _attempt(
      store,
      () => store.uploadClaimFile(
        claimId: claim.id,
        fileName: picked.name,
        mime: picked.mime,
        bytes: picked.bytes,
      ),
    );
    if (!mounted) return;
    setState(() => _addingFile = false);
    if (ok) _toast(_s.dToastFileAdded);
  }

  Future<void> _handleMore(
      ReloStore store, ClaimView claim, String choice) async {
    if (choice == 'done') {
      await _handleFinish(store, claim);
    } else {
      final wasDeleted = claim.deleted;
      final ok =
          await _attempt(store, () => store.toggleTrashClaim(claim.id));
      if (ok && mounted) {
        _toast(wasDeleted ? _s.dToastRestored : _s.dToastTrashed);
      }
    }
  }

  void _close(ReloStore store) {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      store.closeClaimDetail();
    }
  }

  /// AI에게 맡기기 시트를 연다. AI가 쓴 글을 메시지 칸에 넣겠다고 하면 칸에 넣고 메시지 탭을 보여 준다
  /// (저장은 사람이 [보냈어요]를 눌러야 된다).
  void _openAgent(ClaimView claim) {
    showAgentSheet(
      context,
      claim,
      onUseDraft: (body) {
        if (!mounted) return;
        setState(() {
          _draftCtrl.text = body;
          _fieldErrors.remove('draft');
          _activeTab = 0;
        });
        _toast(_s.agDraftUsed);
      },
    );
  }

  // 이 건을 담은 채로 도우미를 연다. 같은 건의 메시지·답장 버튼은 이 화면의 탭을 바꾼다.
  void _askAssistant(ReloStore store, ClaimView claim) {
    void onAction(AssistantTurn turn) {
      final sameClaim = turn.claimId == claim.id;
      if (sameClaim && turn.action == 'draft_email') {
        setState(() => _activeTab = 0);
      } else if (sameClaim && turn.action == 'analyze_reply') {
        setState(() => _activeTab = 1);
      } else if (!(sameClaim && turn.action == 'open_claim')) {
        if (widget.onClose != null) widget.onClose!();
        runAssistantAction(store, turn);
      }
    }

    showReloAssistant(context, claimId: claim.id, onAction: onAction);
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final claim = store.findClaim(widget.claimId);

    if (claim == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _s.dNotFound,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 16),
              ReloButton(
                text: _s.dBackToClaims,
                isPrimary: false,
                onPressed: () => _close(store),
              ),
            ],
          ),
        ),
      );
    }

    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(store, claim, palette),
                    _buildHeader(store, claim, palette),
                    // AI에게 맡기기. 서버의 AI가 있을 때만 보인다 (체험 모드에서는 지어내지 않는다).
                    if (store.agentAvailableFor(claim))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: AgentEntryRow(
                          claim: claim,
                          onTap: () => _openAgent(claim),
                        ),
                      ),
                    // 쇼핑몰에서 해결이 안 됐거나 그만둔 건: 다음에 할 수 있는 일
                    if (!claim.deleted &&
                        (claim.state == 'disputed' || claim.state == 'waived'))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: DisputeGuide(claim: claim),
                      ),
                    // 답이 없는 쇼핑몰 · 마무리한 건을 다시 열기
                    if (canEscalateClaim(claim) ||
                        (claim.state == 'completed' && !claim.deleted))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: ClaimStateNote(claim: claim),
                      ),
                    _buildTabs(claim, palette),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: switch (_activeTab) {
                        0 => _buildMessageTab(store, claim, palette),
                        1 => _buildReplyTab(store, claim, palette),
                        2 => _buildDepositTab(store, claim, palette),
                        _ => _buildHistoryTab(claim, palette),
                      },
                    ),
                  ],
                ),
              ),
            ),
            // 글자를 칠 때는 자리를 내준다
            if (!typing) ...[
              ReloAskBar(
                label: store.strings.assistantAskThisClaim,
                onTap: () => _askAssistant(store, claim),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 24,
          gravity: 0.25,
          colors: [palette.brand, palette.brandHover, Colors.white],
        ),
      ],
    );
  }

  // ── 맨 위: 뒤로 · 더 보기 ────────────────────────────────────────────
  Widget _buildTopBar(ReloStore store, ClaimView claim, ReloPalette palette) {
    PopupMenuItem<String> item(String value, String label) => PopupMenuItem(
          value: value,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: _s.dBackTooltip,
            icon: Icon(ReloIcons.back, color: palette.ink),
            onPressed: () => _close(store),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: _s.dMore,
            icon: Icon(ReloIcons.more, color: palette.muted),
            color: palette.surfaceElevated,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (choice) => _handleMore(store, claim, choice),
            itemBuilder: (_) => [
              // 받기로 한 것을 다 받았을 때만 끝낼 수 있다 (서버도 그때만 받는다)
              if (canFinishClaim(claim)) item('done', _s.dMenuDone),
              item('trash', claim.deleted ? _s.dMenuRestore : _s.dMenuTrash),
            ],
          ),
        ],
      ),
    );
  }

  // ── 무엇을 · 돈 · 지금 단계 ──────────────────────────────────────────
  Widget _buildHeader(ReloStore store, ClaimView claim, ReloPalette palette) {
    final target = claim.agreed ?? claim.claimed;
    final cash = claim.summary.cash;
    final base = claim.claimed <= 0 ? target : claim.claimed;
    double ratio(int minor) => base <= 0 ? 0.0 : minor / base;
    final isRefund = claim.kind == 'refund';
    final goods = claim.summary.goods;
    final asked = claim.summary.requestedQty;
    final showBar = isRefund
        ? claim.agreed != null || cash > 0
        : claim.kind == 'exchange' && goods > 0;
    final divider = VerticalDivider(
      width: 33,
      thickness: 1,
      color: palette.line.withValues(alpha: 0.5),
    );
    final hasDeadline = claim.deadline != null && claim.deadline!.isNotEmpty;

    final stepIndex = _stepIndex(claim.state);
    final status = claim.state == 'completed'
        ? _s.dAllDone
        : claimStatusText(claim, store.strings);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // 교환 · 수리는 무엇을 요청한 건인지부터 적는다
            '${isRefund ? '' : '${_s.cwKind(claim.kind)} · '}${_s.dOrderLine(claim.vendor, claim.orderRef)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: palette.subtle),
          ),
          const SizedBox(height: 4),
          Text(
            claim.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: palette.ink,
              letterSpacing: -0.4,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),

          // 받기로 한 것 / 받은 것 (내 환불 목록과 같은 두 칸).
          // 환불은 돈, 교환은 수량, 수리는 확인했는지를 적는다.
          IntrinsicHeight(
            child: Row(
              children: [
                if (claim.kind == 'exchange') ...[
                  _MoneyCell(
                    label: _s.cwRequestedQty,
                    amount: _s.cwCount(asked),
                    strong: true,
                  ),
                  divider,
                  _MoneyCell(
                    label: _s.cwReceivedQty,
                    amount: _s.cwCount(goods),
                    strong: goods > 0,
                  ),
                ] else if (claim.kind == 'repair') ...[
                  _MoneyCell(
                    label: _s.cwRepairResult,
                    amount: claim.summary.repair
                        ? _s.cwRepairDone
                        : _s.cwRepairPending,
                    strong: true,
                  ),
                  divider,
                  _MoneyCell(
                    label: _s.cwItemPrice,
                    amount: MoneyFormat.formatMinor(
                      claim.claimed,
                      claim.currency,
                    ),
                    strong: false,
                  ),
                ] else ...[
                  _MoneyCell(
                    label: claim.agreed != null
                        ? _s.dAgreedMoney
                        : _s.dClaimedMoney,
                    amount: MoneyFormat.formatMinor(target, claim.currency),
                    strong: true,
                  ),
                  divider,
                  _MoneyCell(
                    label: _s.homeMoneyReceived,
                    amount: MoneyFormat.formatMinor(cash, claim.currency),
                    strong: cash > 0,
                  ),
                ],
              ],
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 12),
            Semantics(
              label: _s.dProgressLabel,
              child: ReloProgressBar(
                promised: isRefund ? ratio(claim.agreed ?? 0) : 1,
                cash: isRefund
                    ? ratio(cash)
                    : (asked <= 0 ? 0.0 : goods / asked),
                height: 6,
                trackColor: palette.raised,
              ),
            ),
          ],
          if (!isClaimDone(claim)) ...[
            const SizedBox(height: 4),
            // 마감일이 있으면 "마감 · 남은 날 · 바꾸기", 없으면 "마감일 정하기".
            // 다른 언어에서 길어져도 넘치지 않게, 자리가 모자라면 다음 줄로 내린다.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (hasDeadline) ...[
                  Text(
                    _s.dDeadline(claim.deadline!),
                    style: TextStyle(fontSize: 13, color: palette.subtle),
                  ),
                  ReloDdayText(deadline: claim.deadline, fontSize: 13),
                  const SizedBox(width: 6),
                ],
                Transform.translate(
                  // 글자 버튼의 안쪽 여백만큼 당겨서, 왼쪽 줄을 다른 글자와 맞춘다
                  offset: Offset(hasDeadline ? 0 : -6, 0),
                  child: ReloTextAction(
                    label: hasDeadline ? _s.dDeadlineChange : _s.dDeadlineSet,
                    onTap: () => _handleDeadline(claim),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // 지금 단계 (여섯 단계 중 어디인지는 점으로) + 할 일 한 줄
          Row(
            children: [
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              Semantics(
                label: _s.dStepOf(stepIndex + 1),
                child: Row(
                  children: [
                    for (var i = 0; i < 6; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= stepIndex
                              ? palette.focusRing
                              : palette.line,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            // 지금 할 일 한 줄. 건의 종류(환불 · 교환 · 수리)와 받은 것에 맞춰 앱이 고른다.
            _s.cwNextStep(claim.kind, nextStepCode(claim)),
            style: TextStyle(fontSize: 14, color: palette.muted, height: 1.45),
          ),
          // 받기로 한 것을 다 받았으면, 살펴보고 여기서 끝낸다
          if (canFinishClaim(claim)) ...[
            const SizedBox(height: 16),
            ReloButton(
              text: _s.cwFinish,
              busy: _finishing,
              onPressed:
                  _finishing ? null : () => _handleFinish(store, claim),
            ),
          ],
        ],
      ),
    );
  }

  // ── 글자 탭 넷 ───────────────────────────────────────────────────────
  Widget _buildTabs(ClaimView claim, ReloPalette palette) {
    final tabs = _tabsFor(claim);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: palette.line.withValues(alpha: 0.5)),
          ),
        ),
        // 다른 언어에서 탭 이름이 길어져도 넘치지 않게, 옆으로 밀 수 있게 둔다
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                ReloTextTab(
                  label: tabs[i],
                  selected: _activeTab == i,
                  onTap: () => setState(() => _activeTab = i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHead(String title, {Widget? action}) {
    final palette = ReloPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _caption(String text) {
    final palette = ReloPalette.of(context);
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: palette.subtle, height: 1.4),
    );
  }

  // ── 1. 메시지 ────────────────────────────────────────────────────────
  Widget _buildMessageTab(
      ReloStore store, ClaimView claim, ReloPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(
          _s.dMsgTitle,
          action: ReloTextAction(
            label: _generatingDraft ? _s.dAiWriting : _s.dAiWrite,
            onTap: _generatingDraft
                ? null
                : () => _handleGenerateDraft(store, claim),
          ),
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: _s.dMsgField,
          hint: _s.dMsgHint,
          controller: _draftCtrl,
          maxLines: 6,
          fillColor: palette.raised,
          errorText: _fieldErrors['draft'],
          onChanged: (_) => _clearFieldError('draft'),
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: _s.dNoteLabel,
          controller: _submissionNoteCtrl,
          fillColor: palette.raised,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReloButton(
                text: _s.cmCopy,
                isPrimary: false,
                icon: ReloIcons.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _draftCtrl.text));
                  _toast(_s.dToastCopied);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReloButton(
                text: _submittingDraft ? _s.cmSaving : _s.dSent,
                busy: _submittingDraft,
                onPressed: _submittingDraft
                    ? null
                    : () => _handleSaveSubmitDraft(store, claim),
              ),
            ),
          ],
        ),
        // 쓴 메시지를 메일 · 메신저 앱으로 바로 넘긴다 (어디로 보낼지는 기기의 공유 화면에서 고른다)
        if (store.textSharer.isSupported) ...[
          const SizedBox(height: 6),
          Center(
            child: ReloTextAction(
              label: _s.dSendVia,
              onTap: () => _handleSendVia(store, claim),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _caption(_s.dMsgCaption),
      ],
    );
  }

  Future<void> _handleSendVia(ReloStore store, ClaimView claim) async {
    final text = _draftCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _fieldErrors['draft'] = _s.dErrDraft);
      return;
    }
    final opened = await store.textSharer.share(
      text: text,
      subject: _s.dSendSubject(claim.orderRef),
    );
    if (!mounted) return;
    _toast(opened ? _s.dSendThenMark : _s.evUnavailable);
  }

  // ── 2. 답장 ──────────────────────────────────────────────────────────
  Widget _buildReplyTab(ReloStore store, ClaimView claim, ReloPalette palette) {
    final hasSummary = _summaryKo.isNotEmpty || claim.replies.isNotEmpty;
    // 상자에 보일 것: 방금 AI가 읽은 요약, 없으면 마지막으로 저장한 답장.
    // 저장한 답장에 AI의 요약이 없으면(직접 읽고 저장한 것) 원문을 그대로 보여 준다.
    final fresh = _summaryKo.isNotEmpty;
    final latest = claim.replies.isEmpty ? null : claim.replies.first;
    final latestByAi =
        latest != null && latest.aiAssisted && latest.summaryKo.isNotEmpty;
    final boxTitle = fresh
        ? _summaryKo
        : (latest != null && latest.summaryKo.isNotEmpty)
            ? latest.summaryKo
            : _s.dSavedReply;
    final boxBody = fresh
        ? _translationKo
        : (latest != null && latest.translationKo.isNotEmpty)
            ? latest.translationKo
            : (latest?.body ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(
          _s.dReplyTitle,
          action: ReloTextAction(
            label: _analyzingReply ? _s.dAiReading : _s.dAiSummary,
            onTap:
                _analyzingReply ? null : () => _handleAnalyzeReply(store, claim),
          ),
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: _s.dReplyField,
          hint: _s.dReplyHint,
          controller: _replyCtrl,
          maxLines: 4,
          fillColor: palette.raised,
          errorText: _fieldErrors['reply'],
          onChanged: (_) => _clearFieldError('reply'),
        ),
        if (hasSummary) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.raised,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boxTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  boxBody,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.body,
                    height: 1.5,
                  ),
                ),
                // AI가 요약 · 번역한 것이면 그렇다고 적는다 (약관 제2조 4항)
                if (fresh || latestByAi) ...[
                  const SizedBox(height: 8),
                  Text(
                    _s.dAiMadeNote,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.subtle,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          _s.dReplyKind,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in store.config.replyKinds.entries)
              ReloChoiceChip(
                label: _s.cwReplyKind(claim.kind, entry.key),
                selected: _replyKind == entry.key,
                onTap: () => setState(() => _replyKind = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // 요청한 것과 다르게 정해졌을 때 (교환을 요청했는데 환불해 주기로 한 경우처럼)
        Text(
          _s.cwMethodLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in const ['refund', 'exchange', 'repair'])
              ReloChoiceChip(
                label: _s.cwKind(kind),
                selected: claim.kind == kind,
                onTap: () => _handleChangeKind(store, claim, kind),
              ),
          ],
        ),
        if (hasReceived(claim.summary)) ...[
          const SizedBox(height: 6),
          _caption(_s.cwMethodLocked),
        ],
        if (claim.kind == 'refund') ...[
          const SizedBox(height: 16),
          ReloTextField(
            label: _s.dAgreedField(claim.currency),
            controller: _agreedAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            fillColor: palette.raised,
            inputFormatters: [MoneyInputFormatter.of(claim.currency)],
            errorText: _fieldErrors['agreed'],
            onChanged: (_) => _clearFieldError('agreed'),
          ),
        ],
        const SizedBox(height: 16),
        ReloButton(
          text: _savingReply ? _s.cmSaving : _s.cmSave,
          busy: _savingReply,
          onPressed: _savingReply ? null : () => _handleSaveReply(store, claim),
        ),
      ],
    );
  }

  // ── 3. 입금 (들어온 돈 기록 + 증빙 파일) ─────────────────────────────
  Widget _buildDepositTab(
      ReloStore store, ClaimView claim, ReloPalette palette) {
    final hairline = BorderSide(color: palette.line.withValues(alpha: 0.5));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showDepositConfetti) ...[
          ConfettiBurstBanner(
            title: _s.cwBannerTitle(claim.kind),
            subtitle: _s.cwRecorded(claim.kind),
          ),
          const SizedBox(height: 20),
        ],
        ReceiptSection(
          // 받을 것이 바뀌면(기록 · 되돌리기 · 약속 금액 · 해결 방법) 칸을 새로 채운다
          key: ValueKey(
            '${claim.kind}:${claim.agreed}:${claim.summary.cash}:${claim.summary.goods}:${claim.summary.repair}:${claim.state}',
          ),
          claim: claim,
          onRecorded: () {
            if (!mounted) return;
            setState(() => _showDepositConfetti = true);
            _confetti.play();
          },
          onUndone: () {
            if (mounted) setState(() => _showDepositConfetti = false);
          },
        ),
        const SizedBox(height: 32),
        _sectionHead(_s.dFilesCount(claim.files.length)),
        const SizedBox(height: 4),
        _caption(_s.dFilesCaption),
        if (claim.files.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              _s.dNoFiles,
              style: TextStyle(fontSize: 14, color: palette.subtle),
            ),
          )
        else
          for (final file in claim.files)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: hairline)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    ReloIconTile(
                      icon: file.mime.contains('pdf')
                          ? ReloIcons.document
                          : ReloIcons.image,
                      color: palette.raised,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(file.size / 1024).toStringAsFixed(1)} KB · ${file.usedAsProof ? _s.dFileUsed : _s.dFileKept}',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.subtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!file.usedAsProof)
                      IconButton(
                        tooltip: _s.dDeleteFile,
                        icon: Icon(
                          ReloIcons.trash,
                          size: 20,
                          color: palette.subtle,
                        ),
                        onPressed: () => _attempt(
                          store,
                          () => store.removeClaimFile(
                            claimId: claim.id,
                            fileId: file.id,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 16),
        ReloButton(
          text: _s.dAddFile,
          isPrimary: false,
          height: 48,
          icon: ReloIcons.add,
          busy: _addingFile,
          onPressed: () => _handleAddFile(store, claim),
        ),
      ],
    );
  }

  // ── 4. 기록 ──────────────────────────────────────────────────────────
  Widget _buildHistoryTab(ClaimView claim, ReloPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHead(_s.dHistoryTitle),
        const SizedBox(height: 16),
        if (claim.events.isEmpty)
          Text(
            _s.dNoHistory,
            style: TextStyle(fontSize: 14, color: palette.subtle),
          ),
        for (final ev in claim.events)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: palette.subtle.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.action,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: palette.ink,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _s.date(ev.createdAt),
                        style: TextStyle(fontSize: 12, color: palette.subtle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 받기로 한 돈 / 받은 돈 한 칸 (상자 없이). 내 환불 목록의 돈 칸과 같은 크기다.
class _MoneyCell extends StatelessWidget {
  final String label;
  final String amount;
  final bool strong;
  const _MoneyCell({
    required this.label,
    required this.amount,
    required this.strong,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Expanded(
      child: Semantics(
        label: '$label $amount',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: palette.subtle,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
                  color: strong ? palette.ink : palette.muted,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
