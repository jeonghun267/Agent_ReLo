import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../assistant/assistant_sheet.dart';
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
  static const List<String> _tabs = ['메시지', '답장', '입금', '기록'];

  int _activeTab = 0;
  bool _tabTaken = false;

  final _draftCtrl = TextEditingController();
  final _submissionNoteCtrl = TextEditingController(
    text: '쇼핑몰 고객센터 채팅/이메일로 전송 완료',
  );
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
  bool _showDepositConfetti = false;
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

  Future<void> _handleGenerateDraft(ReloStore store, ClaimView claim) async {
    setState(() => _generatingDraft = true);
    final generated = await store.generateForeignDraft(claim);
    if (!mounted) return;
    setState(() {
      _generatingDraft = false;
      _draftCtrl.text = generated;
    });
  }

  Future<void> _handleSaveSubmitDraft(ReloStore store, ClaimView claim) async {
    if (_draftCtrl.text.trim().isEmpty) return;
    setState(() => _submittingDraft = true);
    await store.saveAndSubmitDraft(
      claim.id,
      _draftCtrl.text.trim(),
      _submissionNoteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submittingDraft = false);
    _toast('저장했어요. 이제 답장을 기다리면 돼요.');
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
      _summaryKo = res.summaryKo;
      _translationKo = res.translationKo;
      if (res.mentionedAmount != null && res.mentionedAmount!.isNotEmpty) {
        _agreedAmountCtrl.text = res.mentionedAmount!;
      }
    });
  }

  Future<void> _handleSaveReply(ReloStore store, ClaimView claim) async {
    if (_replyCtrl.text.trim().isEmpty) return;
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
    _toast('답장과 약속한 금액을 저장했어요.');
  }

  Future<void> _handleRecordDeposit(ReloStore store, ClaimView claim) async {
    if (_depositAmountCtrl.text.trim().isEmpty) return;
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
    _toast('들어온 돈을 기록했어요.');
  }

  Future<void> _handleAddFile(ReloStore store, ClaimView claim) async {
    await store.uploadClaimFile(
      claimId: claim.id,
      fileName:
          'Card_Cancel_Slip_${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}.pdf',
      mime: 'application/pdf',
      bytes: const [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34],
    );
    if (!mounted) return;
    _toast('파일을 추가했어요.');
  }

  Future<void> _handleMore(
      ReloStore store, ClaimView claim, String choice) async {
    if (choice == 'done') {
      await store.completeClaim(claim.id);
      if (!mounted) return;
      _toast('끝난 건으로 표시했어요.');
    } else {
      final wasDeleted = claim.deleted;
      await store.toggleTrashClaim(claim.id);
      if (!mounted) return;
      _toast(wasDeleted ? '휴지통에서 꺼냈어요.' : '휴지통으로 옮겼어요.');
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
                '이 환불 건을 찾을 수 없어요',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 16),
              ReloButton(
                text: '내 환불로 돌아가기',
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
            tooltip: '내 환불 목록',
            icon: Icon(ReloIcons.back, color: palette.ink),
            onPressed: () => _close(store),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            tooltip: '더 보기',
            icon: Icon(ReloIcons.more, color: palette.muted),
            color: palette.surfaceElevated,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (choice) => _handleMore(store, claim, choice),
            itemBuilder: (_) => [
              if (claim.state != 'completed') item('done', '끝난 건으로 표시'),
              item('trash', claim.deleted ? '휴지통에서 꺼내기' : '휴지통으로 옮기기'),
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
        ? '모두 끝났어요'
        : claimStatusText(claim, korean: store.locale == ReloLocale.ko);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${claim.vendor} · 주문번호 ${claim.orderRef}',
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
                  label: claim.agreed != null ? '받기로 한 돈' : '요청한 돈',
                  amount: MoneyFormat.formatMinor(target, claim.currency),
                  strong: true,
                ),
                VerticalDivider(
                  width: 33,
                  thickness: 1,
                  color: palette.line.withValues(alpha: 0.5),
                ),
                _MoneyCell(
                  label: '받은 돈',
                  amount: MoneyFormat.formatMinor(cash, claim.currency),
                  strong: cash > 0,
                ),
              ],
            ),
          ),
          if (showBar) ...[
            const SizedBox(height: 12),
            Semantics(
              label: '약속과 입금 진행',
              child: ReloProgressBar(
                promised: ratio(claim.agreed ?? 0),
                cash: ratio(cash),
                height: 6,
                trackColor: palette.raised,
              ),
            ),
          ],
          if (hasDeadline && !isClaimDone(claim)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '마감 ${claim.deadline} · ',
                  style: TextStyle(fontSize: 13, color: palette.subtle),
                ),
                ReloDdayText(deadline: claim.deadline, fontSize: 13),
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
                label: '여섯 단계 중 ${stepIndex + 1}단계',
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
            claim.nextStep,
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
          '판매자에게 보낼 메시지',
          action: ReloTextAction(
            label: _generatingDraft ? '쓰는 중…' : 'AI로 쓰기',
            onTap: _generatingDraft
                ? null
                : () => _handleGenerateDraft(store, claim),
          ),
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: '보낼 메시지',
          hint: 'AI로 쓰기를 누르면 판매자 나라 말로 써 드려요',
          controller: _draftCtrl,
          maxLines: 6,
          fillColor: palette.raised,
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: '어디로 보냈는지 (선택)',
          controller: _submissionNoteCtrl,
          fillColor: palette.raised,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReloButton(
                text: '복사하기',
                isPrimary: false,
                icon: ReloIcons.copy,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _draftCtrl.text));
                  _toast('메시지를 복사했어요.');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ReloButton(
                text: _submittingDraft ? '저장하는 중…' : '보냈어요',
                onPressed: _submittingDraft
                    ? null
                    : () => _handleSaveSubmitDraft(store, claim),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _caption('ReLo가 대신 보내지는 않아요. 복사해서 쇼핑몰에 보낸 다음 "보냈어요"를 눌러 주세요.'),
      ],
    );
  }

  // ── 2. 답장 ──────────────────────────────────────────────────────────
  Widget _buildReplyTab(ReloStore store, ClaimView claim, ReloPalette palette) {
    final hasSummary = _summaryKo.isNotEmpty || claim.replies.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHead(
          '판매자 답장',
          action: ReloTextAction(
            label: _analyzingReply ? '읽는 중…' : 'AI로 요약',
            onTap:
                _analyzingReply ? null : () => _handleAnalyzeReply(store, claim),
          ),
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: '답장 원문',
          hint: '판매자가 보낸 답장을 붙여 넣어 주세요',
          controller: _replyCtrl,
          maxLines: 4,
          fillColor: palette.raised,
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
          '어떤 답장이에요?',
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
                label: entry.value,
                selected: _replyKind == entry.key,
                onTap: () => setState(() => _replyKind = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ReloTextField(
          label: '약속한 환불 금액 (${claim.currency})',
          controller: _agreedAmountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          fillColor: palette.raised,
        ),
        const SizedBox(height: 16),
        ReloButton(
          text: _savingReply ? '저장하는 중…' : '저장하기',
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
          const ConfettiBurstBanner(
            title: '돈이 돌아왔어요',
            subtitle: '들어온 금액을 기록했어요.',
          ),
          const SizedBox(height: 20),
        ],
        _sectionHead('들어온 돈 기록'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ReloTextField(
                label: '들어온 금액 (${claim.currency})',
                controller: _depositAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                fillColor: palette.raised,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ReloTextField(
                label: '확인한 날',
                controller: _receivedOnCtrl,
                fillColor: palette.raised,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ReloTextField(
          label: '승인번호 · 메모',
          controller: _txRefCtrl,
          fillColor: palette.raised,
        ),
        const SizedBox(height: 8),
        _caption('카드 전체 번호는 적지 마세요. 취소 금액과 승인번호만 기록해요.'),
        const SizedBox(height: 16),
        ReloButton(
          text: _recordingDeposit ? '기록하는 중…' : '입금 기록하기',
          onPressed: _recordingDeposit
              ? null
              : () => _handleRecordDeposit(store, claim),
        ),
        if (claim.ledger.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            '기록한 입금 ${claim.ledger.length}건',
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
        _sectionHead('증빙 파일 ${claim.files.length}개'),
        const SizedBox(height: 4),
        _caption('10MB까지 올릴 수 있고, 내 계정에서만 볼 수 있어요.'),
        if (claim.files.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              '아직 올린 파일이 없어요.',
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
                            '${(file.size / 1024).toStringAsFixed(1)} KB · ${file.usedAsProof ? '입금 증빙으로 씀' : '보관 중'}',
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
                        tooltip: '파일 지우기',
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
          text: '영수증 · 사진 추가',
          isPrimary: false,
          height: 48,
          icon: ReloIcons.add,
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
        _sectionHead('지금까지 한 일'),
        const SizedBox(height: 16),
        if (claim.events.isEmpty)
          Text(
            '아직 기록이 없어요.',
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
                        MoneyFormat.formatDateKo(ev.createdAt),
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
