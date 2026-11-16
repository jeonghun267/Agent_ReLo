import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/models/claim_rules.dart';
import '../../shared/models/claim_words.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_primitives.dart';

/// 한국소비자원 국제거래 소비자포털
const String consumerPortalUrl = 'https://crossborder.kca.go.kr';

/// 상태를 바꾸고, 서버가 거절하면 그 까닭을 알린다. 됐으면 [done]을 알린다.
Future<void> _transition(
  BuildContext context,
  ClaimView claim,
  String action,
  String reason,
  String done,
) async {
  final store = ReloScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  String text = done;
  try {
    await store.transitionClaim(claim.id, action, reason);
  } on ApiError catch (e) {
    text = store.refusalText(e);
  }
  messenger.showSnackBar(SnackBar(content: Text(text)));
}

/// @module features/claims/dispute_guide
/// @purpose 쇼핑몰에서 해결이 안 될 때 실제로 쓰는 세 가지 길을 차례로 보여 준다:
///          쇼핑몰 분쟁 신청 → 결제한 곳 이의 제기(카드사 차지백 · PayPal 분쟁) → 한국소비자원 상담.
///          주문일부터 센 가장 이른 마감일, 신청서에 붙여 넣을 요약, 그리고 빠져나가는 두 길
///          (다시 진행하기 · 더 진행하지 않기)을 함께 둔다. 그만둔 건에는 한 줄과 다시 진행하기만 둔다.
class DisputeGuide extends StatefulWidget {
  final ClaimView claim;
  const DisputeGuide({super.key, required this.claim});

  @override
  State<DisputeGuide> createState() => _DisputeGuideState();
}

class _DisputeGuideState extends State<DisputeGuide> {
  bool _busy = false;

  ReloStrings get _s => ReloScope.of(context).strings;

  Future<void> _change(String action, String reason, String done) async {
    setState(() => _busy = true);
    await _transition(context, widget.claim, action, reason, done);
    if (mounted) setState(() => _busy = false);
  }

  void _continue() =>
      _change('reopen', '소비자가 다시 진행하기로 함', _s.dgToastReopened);
  void _stop() =>
      _change('waived', '분쟁 뒤 소비자가 더 진행하지 않기로 함', _s.dgToastWaived);

  void _copy(String text, String done) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  }

  String _deadlineText(({String date, int daysLeft})? d) {
    if (d == null) return '-';
    final date = _s.date(d.date);
    if (d.daysLeft > 0) return _s.dgUntil(date, d.daysLeft);
    return d.daysLeft == 0 ? _s.dgUntilToday(date) : _s.dgPassed(date);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    final claim = widget.claim;

    TextStyle body() =>
        TextStyle(fontSize: 14, color: palette.muted, height: 1.5);
    TextStyle small() =>
        TextStyle(fontSize: 12, color: palette.subtle, height: 1.45);

    if (claim.state == 'waived') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _s.dgWaivedTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(_s.dgWaivedBody, style: body()),
          const SizedBox(height: 14),
          ReloButton(
            text: _s.dgResolved,
            isPrimary: false,
            height: 48,
            busy: _busy,
            onPressed: _busy ? null : _continue,
          ),
        ],
      );
    }

    Widget step(int n, String title, String text, {Widget? extra}) => Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.raised,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$n',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.body,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(text, style: body()),
                    if (extra != null) extra,
                  ],
                ),
              ),
            ],
          ),
        );

    Widget window(String label, int days) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.raised,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: small()),
              const SizedBox(height: 2),
              Text(
                _deadlineText(disputeDeadline(claim.orderedOn, days)),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _s.dgEyebrow,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.focusRing,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _s.dgTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: palette.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(_s.dgSub, style: body()),
        step(1, _s.dgStep1Title, _s.dgStep1Body),
        step(
          2,
          _s.dgStep2Title,
          _s.dgStep2Body,
          extra: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              window(_s.dgCardWindow, cardDisputeWindowDays),
              window(_s.dgLongWindow, longDisputeWindowDays),
              const SizedBox(height: 8),
              Text(_s.dgDeadlineNote, style: small()),
            ],
          ),
        ),
        step(
          3,
          _s.dgStep3Title,
          _s.dgStep3Body,
          extra: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              SelectableText(consumerPortalUrl, style: small()),
              Transform.translate(
                // 글자 버튼의 안쪽 여백만큼 당겨서, 왼쪽 줄을 위 글자와 맞춘다
                offset: const Offset(-6, 0),
                child: ReloTextAction(
                  label: _s.dgPortalCopy,
                  onTap: () => _copy(consumerPortalUrl, _s.dgToastPortal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ReloButton(
          text: _s.dgSummaryCopy,
          isPrimary: false,
          height: 48,
          onPressed: () =>
              _copy(_s.disputeSummary(claim), _s.dgToastSummary),
        ),
        const SizedBox(height: 20),
        Text(_s.dgOutcomeHint, style: small()),
        const SizedBox(height: 10),
        ReloButton(
          text: _s.dgResolved,
          isPrimary: false,
          height: 48,
          busy: _busy,
          onPressed: _busy ? null : _continue,
        ),
        Center(
          child: ReloMutedAction(
            label: _s.dgGiveUp,
            onTap: _busy ? null : _stop,
          ),
        ),
      ],
    );
  }
}

/// 상세 맨 위 아래의 한 줄: 쇼핑몰이 답하지 않거나 약속을 지키지 않을 때 "다른 해결 방법"으로
/// 가는 길, 그리고 마무리한 건의 기록을 고치려고 "다시 열기". 다른 때에는 아무것도 그리지 않는다.
class ClaimStateNote extends StatefulWidget {
  final ClaimView claim;
  const ClaimStateNote({super.key, required this.claim});

  @override
  State<ClaimStateNote> createState() => _ClaimStateNoteState();
}

class _ClaimStateNoteState extends State<ClaimStateNote> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    final claim = widget.claim;
    final waiting = canEscalateClaim(claim);
    if (!waiting && !(claim.state == 'completed' && !claim.deleted)) {
      return const SizedBox.shrink();
    }

    Future<void> onTap() async {
      setState(() => _busy = true);
      await _transition(
        context,
        claim,
        waiting ? 'disputed' : 'reopen',
        waiting ? '쇼핑몰이 답하지 않거나 약속을 지키지 않음' : '마무리한 뒤 기록을 고치려고 다시 엶',
        waiting ? s.cwToastDisputed : s.cwToastReopened,
      );
      if (mounted) setState(() => _busy = false);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 6),
      decoration: BoxDecoration(
        color: palette.raised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            waiting ? s.cwNoAnswer : s.cwCompletedNote,
            style: TextStyle(fontSize: 14, color: palette.body, height: 1.45),
          ),
          Transform.translate(
            // 글자 버튼의 안쪽 여백만큼 당겨서, 왼쪽 줄을 위 글자와 맞춘다
            offset: const Offset(-6, 0),
            child: ReloTextAction(
              label: waiting ? s.cwNoAnswerAction : s.cwReopen,
              onTap: _busy ? null : onTap,
            ),
          ),
        ],
      ),
    );
  }
}
