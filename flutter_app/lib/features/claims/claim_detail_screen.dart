import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/claims/claim_detail_screen
/// @layer Feature Module — Individual Claim Workspace
/// @purpose 외국어 메시지 생성, 쇼핑몰 답장 요약, 실제 카드 취소 입금 확인 및 증빙 사진 격리 보관함 화면입니다.
class ClaimDetailScreen extends StatefulWidget {
  final String claimId;

  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  int _activeSubTab = 0;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = ReloScope.of(context);
    final claim = store.findClaim(widget.claimId);
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
    _txRefCtrl.dispose();
    _receivedOnCtrl.dispose();
    super.dispose();
  }

  static const List<({String id, String label})> _lifecycleSteps = [
    (id: 'preparing', label: '서류 준비'),
    (id: 'review', label: '메시지 준비'),
    (id: 'awaiting', label: '답변 대기'),
    (id: 'negotiating', label: '조건 조율'),
    (id: 'recovered', label: '입금 확인'),
    (id: 'completed', label: '완료'),
  ];

  int _lifecycleIndex(String state) {
    switch (state) {
      case 'preparing':
        return 0;
      case 'review':
        return 1;
      case 'awaiting':
        return 2;
      case 'negotiating':
        return 3;
      case 'partial':
      case 'recovered':
        return 4;
      case 'completed':
        return 5;
      default:
        return 0;
    }
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('외국어 요청서를 저장하고 [답변 대기] 단계로 전환했어요!')),
    );
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
      translationKo: _translationKo.isEmpty
          ? _replyCtrl.text.trim()
          : _translationKo,
      agreedAmountStr: _agreedAmountCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingReply = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('쇼핑몰 답장과 약속 금액이 환불 통장에 반영되었어요!')),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('실제 카드 취소·입금 내역이 환불 통장에 기록되었어요!')),
    );
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
          child: ReloCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '선택한 환불 건을 찾을 수 없어요.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 12),
                ReloButton(
                  text: '내 환불 목록으로 돌아가기',
                  onPressed: store.closeClaimDetail,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final targetTotal = claim.agreed ?? claim.claimed;
    final progressRatio = targetTotal <= 0
        ? 0.0
        : (claim.summary.cash / targetTotal).clamp(0.0, 1.0);
    final currentStepIdx = _lifecycleIndex(claim.state);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: store.closeClaimDetail,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: palette.body,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '내 환불 목록',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: palette.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  if (claim.state != 'completed')
                    GestureDetector(
                      onTap: () async {
                        await store.completeClaim(claim.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('환불 절차가 최종 완료 처리되었어요!'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: palette.mintSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '절차 완료 표시',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: palette.mint,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => store.toggleTrashClaim(claim.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: palette.sunken,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        claim.deleted
                            ? Icons.restore_from_trash_rounded
                            : Icons.delete_outline_rounded,
                        size: 16,
                        color: palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          ReloCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ReloBadge(
                      label: claim.vendor,
                      tone: ReloBadgeTone.brand,
                      icon: Icons.storefront_rounded,
                    ),
                    ReloBadge(
                      label: '주문번호 #${claim.orderRef}',
                      tone: ReloBadgeTone.neutral,
                    ),
                    if (claim.deadline != null && claim.deadline!.isNotEmpty)
                      ReloBadge(
                        label: '마감 ${claim.deadline}',
                        tone: ReloBadgeTone.sunny,
                        icon: Icons.schedule_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  claim.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  claim.nextStep,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.brandHover,
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.sunken.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '실제 입금 확인 금액',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              MoneyDisplay(
                                minorAmount: claim.summary.cash,
                                currency: claim.currency,
                                size: MoneySize.lg,
                                color: claim.summary.cash > 0
                                    ? palette.mint
                                    : palette.ink,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                claim.agreed != null
                                    ? '쇼핑몰 약속 금액'
                                    : '요청 환불 금액',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              MoneyDisplay(
                                minorAmount: targetTotal,
                                currency: claim.currency,
                                size: MoneySize.md,
                                color: palette.body,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 8,
                          backgroundColor: palette.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressRatio >= 1.0 ? palette.mint : palette.brand,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_lifecycleSteps.length, (i) {
                      final step = _lifecycleSteps[i];
                      final done = i <= currentStepIdx;
                      final current = i == currentStepIdx;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: current
                                  ? palette.brand
                                  : (done ? palette.brandSoft : palette.sunken),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${i + 1}. ${step.label}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: current
                                    ? Colors.white
                                    : (done ? palette.brandHover : palette.muted),
                              ),
                            ),
                          ),
                          if (i < _lifecycleSteps.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: palette.subtle,
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabButton(
                  index: 0,
                  label: '1. 외국어 메시지 보내기',
                  icon: Icons.translate_rounded,
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  index: 1,
                  label: '2. 쇼핑몰 답장 · 약속 금액',
                  icon: Icons.mark_chat_read_rounded,
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  index: 2,
                  label: '3. 사진 보관함 · 입금 확인',
                  icon: Icons.account_balance_wallet_rounded,
                  palette: palette,
                ),
                const SizedBox(width: 8),
                _buildSubTabButton(
                  index: 3,
                  label: '4. 진행 기록',
                  icon: Icons.history_rounded,
                  palette: palette,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_activeSubTab == 0)
            _buildForeignMessageStudio(store, claim, palette),
          if (_activeSubTab == 1)
            _buildSellerReplyAnalyzer(store, claim, palette),
          if (_activeSubTab == 2)
            _buildEvidenceAndSettlementTab(store, claim, palette),
          if (_activeSubTab == 3) _buildAuditTimelineTab(claim, palette),
        ],
      ),
    );
  }

  Widget _buildSubTabButton({
    required int index,
    required String label,
    required IconData icon,
    required ReloPalette palette,
  }) {
    final active = _activeSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? palette.brand : palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? palette.brand : palette.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? Colors.white : palette.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: active ? Colors.white : palette.body,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForeignMessageStudio(
    ReloStore store,
    ClaimView claim,
    ReloPalette palette,
  ) {
    return ReloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '외국어 환불 요청서 자동 생성',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _generatingDraft
                    ? null
                    : () => _handleGenerateDraft(store, claim),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.brandLine),
                  ),
                  child: Text(
                    _generatingDraft ? '작성 중...' : 'AI 맞춤 초안 생성',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReloTextField(
            label: '쇼핑몰 제출용 외국어 메시지',
            controller: _draftCtrl,
            maxLines: 6,
          ),
          const SizedBox(height: 10),
          ReloButton(
            text: '메시지 복사하기',
            isPrimary: false,
            height: 44,
            icon: Icons.copy_rounded,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _draftCtrl.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('외국어 메시지가 클립보드에 복사되었어요!'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ReloTextField(
            label: '어디로 보냈는지 메모 (선택)',
            controller: _submissionNoteCtrl,
          ),
          const SizedBox(height: 12),
          ReloButton(
            text: _submittingDraft ? '저장 중...' : '쇼핑몰에 메시지 보냈어요 (답변 대기 전환)',
            icon: Icons.send_rounded,
            onPressed: _submittingDraft
                ? null
                : () => _handleSaveSubmitDraft(store, claim),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerReplyAnalyzer(
    ReloStore store,
    ClaimView claim,
    ReloPalette palette,
  ) {
    return ReloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '쇼핑몰 외국어 답장 3줄 요약 · 약속 금액',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _analyzingReply
                    ? null
                    : () => _handleAnalyzeReply(store, claim),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.brandLine),
                  ),
                  child: Text(
                    _analyzingReply ? '분석 중...' : 'AI 쉬운 한국어 요약',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '답장 유형 선택',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: palette.body,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: store.config.replyKinds.entries.map((entry) {
              final active = _replyKind == entry.key;
              return GestureDetector(
                onTap: () => setState(() => _replyKind = entry.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? palette.brand : palette.sunken,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : palette.body,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ReloTextField(
            label: '쇼핑몰 답장 원문 붙여넣기',
            controller: _replyCtrl,
            maxLines: 4,
          ),
          if (_summaryKo.isNotEmpty || claim.replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.brandSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.brandLine),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _summaryKo.isNotEmpty
                        ? _summaryKo
                        : claim.replies.first.summaryKo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _translationKo.isNotEmpty
                        ? _translationKo
                        : claim.replies.first.translationKo,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.body,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ReloTextField(
            label: '쇼핑몰이 약속한 환불 금액 (${claim.currency})',
            controller: _agreedAmountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          ReloButton(
            text: _savingReply ? '저장 중...' : '답장 요약 및 약속 금액 저장하기',
            onPressed: _savingReply
                ? null
                : () => _handleSaveReply(store, claim),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceAndSettlementTab(
    ReloStore store,
    ClaimView claim,
    ReloPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showDepositConfetti) ...[
          const ConfettiBurstBanner(
            title: '실제 카드 취소 · 입금 내역이 확인되었어요!',
            subtitle: '말뿐인 환불 약속이 아니라 내 통장/카드에 돌아온 진짜 환불 금액이 기록되었습니다.',
          ),
          const SizedBox(height: 14),
        ],
        // 1. 내 전용 격리 증빙 사진 · 영수증 보관함 (claim.files)
        ReloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '내 전용 격리 증빙 보관함 (${claim.files.length}개)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: palette.ink,
                    ),
                  ),
                  const ReloBadge(
                    label: '10MB 암호화 격리 보관',
                    tone: ReloBadgeTone.mint,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '업로드된 영수증과 불량 사진은 본인 계정에서만 열람할 수 있으며 SHA-256 무결성 해시로 보호됩니다.',
                style: TextStyle(fontSize: 11.5, color: palette.muted),
              ),
              const SizedBox(height: 12),
              if (claim.files.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.sunken,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '아직 첨부된 증빙 사진이나 영수증이 없어요.',
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                )
              else
                ...claim.files.map(
                  (file) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.sunken,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.line),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          file.mime.contains('pdf')
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          size: 20,
                          color: palette.brandHover,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: palette.ink,
                                ),
                              ),
                              Text(
                                '${(file.size / 1024).toStringAsFixed(1)} KB · ${file.usedAsProof ? '입금 증빙 사용됨' : '보관 중'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!file.usedAsProof)
                          IconButton(
                            tooltip: '증빙 파일 삭제',
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: palette.muted,
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
              const SizedBox(height: 6),
              ReloButton(
                text: '카드 취소 영수증 · 증빙 사진 추가 첨부 (10MB 이하)',
                isPrimary: false,
                height: 44,
                icon: Icons.upload_file_rounded,
                onPressed: () async {
                  await store.uploadClaimFile(
                    claimId: claim.id,
                    fileName:
                        'Card_Cancel_Slip_${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}.pdf',
                    mime: 'application/pdf',
                    bytes: const [0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34],
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('새 증빙 파일이 격리 보관함에 안전하게 추가되었어요!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 2. 실제 카드 취소 · 통장 입금 기록 폼
        ReloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '실제 카드 취소 · 통장 입금 기록하기',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '카드 전체 번호는 수집하지 않으며, 취소 금액과 승인 참조번호만 기록합니다.',
                style: TextStyle(fontSize: 11.5, color: palette.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ReloTextField(
                      label: '입금 확인 금액 (${claim.currency})',
                      controller: _depositAmountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ReloTextField(
                      label: '입금/취소 확인일',
                      controller: _receivedOnCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ReloTextField(
                label: '카드 취소 승인번호 · 메모 (카드 전체 번호 입력 금지)',
                controller: _txRefCtrl,
              ),
              const SizedBox(height: 12),
              ReloButton(
                text: _recordingDeposit
                    ? '기록 중...'
                    : '내 카드·통장 실제 입금 완료 기록하기',
                icon: Icons.verified_rounded,
                onPressed: _recordingDeposit
                    ? null
                    : () => _handleRecordDeposit(store, claim),
              ),
              if (claim.ledger.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: palette.line, height: 1),
                const SizedBox(height: 12),
                Text(
                  '확인된 입금 · 카드 취소 원장 (${claim.ledger.length}건)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                ...claim.ledger.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.mintSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.receivedOn} · ${entry.transactionRef}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: palette.ink,
                                ),
                              ),
                              if (entry.note.isNotEmpty)
                                Text(
                                  entry.note,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: palette.body,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        MoneyDisplay(
                          minorAmount: entry.amount,
                          currency: claim.currency,
                          size: MoneySize.sm,
                          color: palette.mint,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTimelineTab(ClaimView claim, ReloPalette palette) {
    return ReloCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 진행 타임라인 (${claim.events.length}건)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...claim.events.map(
            (ev) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ev.action,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          MoneyFormat.formatDateKo(ev.createdAt),
                          style: TextStyle(fontSize: 11, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
