import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/input_rules.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/evidence_source_sheet.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../assistant/assistant_sheet.dart';
import 'deadline_sheet.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/claims/claim_detail_screen
/// @layer Feature Module — Individual Claim Workspace
/// @purpose 환불 건 하나를 끝까지 따라가는 화면 (DESIGN.md 7절 "상세").
///          위에서 아래로: 무엇을 · 받기로 한 돈 / 받은 돈 · 지금 단계와 할 일 →
///          글자 탭 넷(메시지 · 답장 · 입금 · 기록) → 아래 고정 "이 건 물어보기".
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

  List<String> get _tabs => [_s.dTabMessage, _s.dTabReply, _s.dTabDeposit, _s.dTabHistory];

  int _activeTab = 0;
  bool _tabTaken = false;

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
  bool _analyzingReply = false;
  bool _savingReply = false;

  final _depositAmountCtrl = TextEditingController();
  final _txRefCtrl = TextEditingController(text: 'VISA-CANCEL-8841');
  final _receivedOnCtrl = TextEditingController(
    text: DateTime.now().toIso8601String().substring(0, 10),
  );
  bool _recordingDeposit = false;
  bool _addingFile = false;
  bool _showDepositConfetti = false;

  /// 칸마다의 오류 (칸 아래 빨간 글자). 키: draft, reply, agreed, deposit, receivedOn
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
    if (claim != null) {
      if (_draftCtrl.text.isEmpty && claim.drafts.isNotEmpty) {
        _draftCtrl.text = claim.drafts.first.body;
      }
      if (_agreedAmountCtrl.text.isEmpty) {
        final targetMinor = claim.agreed ?? claim.claimed;
        _agreedAmountCtrl.text = MoneyFormat.minorToDecimalString(
          targetMinor,
          claim.currency,
        );
      }
      if (_depositAmountCtrl.text.isEmpty) {
        final remMinor = claim.summary.remaining > 0
            ? claim.summary.remaining
            : (claim.agreed ?? claim.claimed);
        _depositAmountCtrl.text = MoneyFormat.minorToDecimalString(
          remMinor,
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
    _depositAmountCtrl.dispose();
    _confetti.dispose();
    _txRefCtrl.dispose();
    _receivedOnCtrl.dispose();
    super.dispose();
  }

  /// 지금 단계에서 먼저 볼 탭: 메시지 보낼 차례 → 메시지, 답장 기다리는 중 → 답장, 그 뒤 → 입금
  int _tabForState(ClaimView claim) => switch (claim.state) {
        'preparing' || 'review' => 0,
        'awaiting' => 1,
        'negotiating' => claim.agreed == null ? 1 : 2,
        _ => 2,
      };

  /// 여섯 단계 중 몇 번째인지 (0부터)
  int _stepIndex(String state) => switch (state) {
        'preparing' => 0,
        'review' => 1,
        'awaiting' => 2,
        'negotiating' => 3,
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

  /// 돈이 들어온 것을 확인한 날은 달력에서 고른다 (오늘까지만 고를 수 있다)
  Future<void> _pickReceivedOn() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_receivedOnCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _receivedOnCtrl.text = picked.toIso8601String().substring(0, 10);
      _fieldErrors.remove('receivedOn');
    });
  }

  Future<void> _handleGenerateDraft(ReloStore store, ClaimView claim) async {
    setState(() => _generatingDraft = true);
    final generated = await store.generateForeignDraft(claim);
    if (!mounted) return;
    setState(() {
      _generatingDraft = false;
      _draftCtrl.text = generated;
      _fieldErrors.remove('draft');
    });
  }

  Future<void> _handleSaveSubmitDraft(ReloStore store, ClaimView claim) async {
    if (_draftCtrl.text.trim().isEmpty) {
      setState(() => _fieldErrors['draft'] = _s.dErrDraft);
      return;
    }
    setState(() => _submittingDraft = true);
    await store.saveAndSubmitDraft(
      claim.id,
      _draftCtrl.text.trim(),
      _submissionNoteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submittingDraft = false);
    _toast(_s.dToastSent);
  }

  Future<void> _handleAnalyzeReply(ReloStore store, ClaimView claim) async {
    if (_replyCtrl.text.trim().isEmpty) {
      _replyCtrl.text =
          'We sincerely apologize for the defective item. We have approved a refund of ${claim.currency} ${MoneyFormat.minorToDecimalString(claim.claimed, claim.currency)} to your original card without requiring return shipping.';
    }
    setState(() => _analyzingReply = true);
    final res = await store.analyzeSellerReply(claim, _replyCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _analyzingReply = false;
      _fieldErrors.remove('reply');
      _summaryKo = res.summaryKo;
      _translationKo = res.translationKo;
      if (res.mentionedAmount != null && res.mentionedAmount!.isNotEmpty) {
        _agreedAmountCtrl.text = res.mentionedAmount!;
      }
    });
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
    await store.saveReplyAndAgreedAmount(
      claimId: claim.id,
      rawReply: _replyCtrl.text.trim(),
      replyKind: _replyKind,
      summaryKo: _summaryKo.isEmpty ? '판매자 환불 조건 답장 기록' : _summaryKo,
      translationKo:
          _translationKo.isEmpty ? _replyCtrl.text.trim() : _translationKo,
      agreedAmountStr: _agreedAmountCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingReply = false);
    _toast(_s.dToastReplySaved);
  }

  Future<void> _handleRecordDeposit(ReloStore store, ClaimView claim) async {
    final errors = <String, String>{};
    if (InputRules.amount(_depositAmountCtrl.text) == null) {
      errors['deposit'] = _s.cmErrAmount;
    }
    if (!InputRules.isoDate(_receivedOnCtrl.text)) {
      errors['receivedOn'] = _s.dErrDate;
    }
    if (errors.isNotEmpty) {
      setState(() => _fieldErrors.addAll(errors));
      return;
    }
    setState(() => _recordingDeposit = true);
    await store.recordRealDeposit(
      claimId: claim.id,
      amountStr: _depositAmountCtrl.text.trim(),
      transactionRef: _txRefCtrl.text.trim(),
      receivedOn: _receivedOnCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _recordingDeposit = false;
      _showDepositConfetti = true;
    });
    _confetti.play();
    _toast(_s.dToastDeposit);
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
    await store.uploadClaimFile(
      claimId: claim.id,
      fileName: picked.name,
      mime: picked.mime,
      bytes: picked.bytes,
    );
    if (!mounted) return;
    setState(() => _addingFile = false);
    _toast(_s.dToastFileAdded);
  }

  Future<void> _handleMore(
      ReloStore store, ClaimView claim, String choice) async {
    if (choice == 'done') {
      await store.completeClaim(claim.id);
      if (!mounted) return;
      _toast(_s.dToastDone);
    } else {
      final wasDeleted = claim.deleted;
      await store.toggleTrashClaim(claim.id);
      if (!mounted) return;
      _toast(wasDeleted ? _s.dToastRestored : _s.dToastTrashed);
    }
  }

  void _close(ReloStore store) {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      store.closeClaimDetail();
    }
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
                    _buildTabs(palette),
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
              if (claim.state != 'completed') item('done', _s.dMenuDone),
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
    final showBar = claim.agreed != null || cash > 0;
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
            _s.dOrderLine(claim.vendor, claim.orderRef),
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

          // 받기로 한 돈 / 받은 돈 (내 환불 목록과 같은 두 칸)
          IntrinsicHeight(
            child: Row(
              children: [
                _MoneyCell(
                  label: claim.agreed != null ? _s.dAgreedMoney : _s.dClaimedMoney,
                  amount: MoneyFormat.formatMinor(target, claim.currency),
                  strong: true,
                ),
                VerticalDivider(
                  width: 33,
                  thickness: 1,
                  color: palette.line.withValues(alpha: 0.5),
                ),
                _MoneyCell(
                  label: _s.homeMoneyReceived,
                  amount: MoneyFormat.formatMinor(cash, claim.currency),
                  strong: cash > 0,
                ),
              ],
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 12),
            Semantics(
              label: _s.dProgressLabel,
              child: ReloProgressBar(
                promised: ratio(claim.agreed ?? 0),
                cash: ratio(cash),
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
            // 서버가 주는 문장은 한국어다. 다른 언어에서는 단계에 맞는 문장을 쓴다.
            store.locale == ReloLocale.ko
                ? claim.nextStep
                : _s.dNextStep(claim.state),
            style: TextStyle(fontSize: 14, color: palette.muted, height: 1.45),
          ),
        ],
      ),
    );
  }

  // ── 글자 탭 넷 ───────────────────────────────────────────────────────
  Widget _buildTabs(ReloPalette palette) {
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
              for (var i = 0; i < _tabs.length; i++)
                ReloTextTab(
                  label: _tabs[i],
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
                  _summaryKo.isNotEmpty
                      ? _summaryKo
                      : claim.replies.first.summaryKo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _translationKo.isNotEmpty
                      ? _translationKo
                      : claim.replies.first.translationKo,
                  style: TextStyle(
                    fontSize: 13,
                    color: palette.body,
                    height: 1.5,
                  ),
                ),
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
                label: _s.replyKind(entry.key, entry.value),
                selected: _replyKind == entry.key,
                onTap: () => setState(() => _replyKind = entry.key),
              ),
          ],
        ),
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
            title: _s.dBannerTitle,
            subtitle: _s.dBannerSub,
          ),
          const SizedBox(height: 20),
        ],
        _sectionHead(_s.dDepositTitle),
        const SizedBox(height: 12),
        Row(
          // 한쪽에만 오류 글자가 나와도 칸 높이가 어긋나지 않게 위에 맞춘다
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ReloTextField(
                label: _s.dDepositField(claim.currency),
                controller: _depositAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                fillColor: palette.raised,
                inputFormatters: [MoneyInputFormatter.of(claim.currency)],
                errorText: _fieldErrors['deposit'],
                onChanged: (_) => _clearFieldError('deposit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ReloTextField(
                label: _s.dDateField,
                controller: _receivedOnCtrl,
                fillColor: palette.raised,
                // 글자로 치지 않고 달력에서 고른다
                readOnly: true,
                onTap: _pickReceivedOn,
                trailingIcon: ReloIcons.calendar,
                errorText: _fieldErrors['receivedOn'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: _s.dRefField,
          controller: _txRefCtrl,
          fillColor: palette.raised,
        ),
        const SizedBox(height: 8),
        _caption(_s.dCardCaption),
        const SizedBox(height: 16),
        ReloButton(
          text: _recordingDeposit ? _s.dRecording : _s.dRecord,
          busy: _recordingDeposit,
          onPressed: _recordingDeposit
              ? null
              : () => _handleRecordDeposit(store, claim),
        ),
        if (claim.ledger.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            _s.dLedgerCount(claim.ledger.length),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.subtle,
            ),
          ),
          for (final entry in claim.ledger)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: hairline)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.receivedOn} · ${entry.transactionRef}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: palette.ink,
                            ),
                          ),
                          if (entry.note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              entry.note,
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.subtle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      MoneyFormat.formatMinor(entry.amount, claim.currency),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
                        onPressed: () => store.removeClaimFile(
                          claimId: claim.id,
                          fileId: file.id,
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
