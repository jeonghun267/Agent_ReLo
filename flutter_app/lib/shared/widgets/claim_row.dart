import 'package:flutter/material.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/dday.dart';
import '../../core/utils/money_format.dart';
import '../models/domain_models.dart';
import '../state/relo_store.dart';
import 'relo_primitives.dart';
import 'relo_icons.dart';

/// @module shared/widgets/claim_row
/// @purpose 홈의 "지금 할 일"과 내 환불 목록이 같이 쓰는 환불 건 한 줄, 그리고 그 줄에
///          들어가는 글(지금 할 일, 줄인 제목)과 돈 합계. 두 화면이 같은 말로 같은 건을
///          보여 주도록 한곳에 둔다.

/// 입금까지 끝난 건인지
bool isClaimDone(ClaimView c) =>
    c.state == 'recovered' || c.state == 'completed';

/// "후지필름 XF 35mm 렌즈 오배송 전액 환불" → "후지필름 XF 35mm"
String shortClaimTitle(String title) => title.split(' ').take(3).join(' ');

/// 지금 할 일을 사람 말로. 기록에 있는 사실만 말한다.
String claimStatusText(ClaimView c, {required bool korean}) {
  String t(String k, String e) => korean ? k : e;
  return switch (c.state) {
    'preparing' || 'review' => t('메시지 보낼 차례', 'Send your message'),
    'awaiting' => t('답장 기다리는 중', 'Waiting for a reply'),
    'negotiating' => c.agreed != null
        ? t('제안 확인할 차례', 'Check the offer')
        : t('조건 정하는 중', 'Working out terms'),
    'recovered' || 'completed' => t('입금 확인', 'Refund received'),
    _ => c.nextStep,
  };
}

/// 받을 돈 / 받은 돈. 서로 다른 통화는 합치지 않고 나란히 적는다: "$248.50 + ¥42,000"
/// (건수가 가장 많은 통화가 앞)
class ClaimMoney {
  final String due;
  final String received;

  /// 아직 받을 돈이 남은 건수
  final int dueCount;
  const ClaimMoney({
    required this.due,
    required this.received,
    required this.dueCount,
  });

  factory ClaimMoney.of(Iterable<ClaimView> active) {
    final counts = <String, int>{};
    final dueBy = <String, int>{};
    final receivedBy = <String, int>{};
    var dueCount = 0;
    for (final c in active) {
      counts[c.currency] = (counts[c.currency] ?? 0) + 1;
      if (c.summary.cash > 0) {
        receivedBy[c.currency] = (receivedBy[c.currency] ?? 0) + c.summary.cash;
      }
      if (!isClaimDone(c)) {
        dueBy[c.currency] = (dueBy[c.currency] ?? 0) + c.summary.remaining;
        dueCount++;
      }
    }
    final main = counts.isEmpty
        ? 'USD'
        : counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;

    String total(Map<String, int> by) {
      if (by.isEmpty) return MoneyFormat.formatMinor(0, main);
      final keys = [
        if (by.containsKey(main)) main,
        ...by.keys.where((k) => k != main),
      ];
      final shown = keys
          .take(2)
          .map((k) => MoneyFormat.formatMinor(by[k]!, k))
          .join(' + ');
      return keys.length > 2 ? '$shown …' : shown;
    }

    return ClaimMoney(
      due: total(dueBy),
      received: total(receivedBy),
      dueCount: dueCount,
    );
  }
}

/// 줄 앞의 아이콘 타일 (40, 모서리 12)
class ReloIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const ReloIconTile({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: palette.muted),
    );
  }
}

/// 환불 건 한 줄: 무엇을 · 어디서 · 지금 할 일 · 남은 날 (+ [showAmount]면 금액).
/// 목록에서는 상자 없이 가는 선으로만 나누고, 대화 속 답에 붙을 때만([boxed]) 상자에 담는다.
/// 누르면 상세가 열린다 ([onTap]을 주면 그것을 대신 부른다).
class ClaimRow extends StatelessWidget {
  final ClaimView claim;
  final bool boxed;
  final bool showAmount;
  final VoidCallback? onTap;

  /// 좌우 여백. 목록이 이미 여백 안에 있으면 0을 준다.
  final double inset;

  const ClaimRow({
    super.key,
    required this.claim,
    this.boxed = false,
    this.showAmount = false,
    this.onTap,
    this.inset = 20,
  });

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final title = shortClaimTitle(claim.title);
    final status =
        claimStatusText(claim, korean: store.locale == ReloLocale.ko);
    final done = isClaimDone(claim);
    final hasDeadline = !done && DDay.label(claim.deadline) != null;

    final content = Row(
      children: [
        ReloIconTile(
          icon: ReloIcons.package,
          color: boxed ? palette.inset : palette.raised,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: '${claim.vendor} · ',
                  children: [
                    TextSpan(
                      text: status,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: done ? palette.muted : palette.focusRing,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: palette.subtle),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (showAmount)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                // 끝난 건은 실제로 들어온 돈, 진행 중인 건은 받기로 한 돈
                MoneyFormat.formatMinor(
                  done ? claim.summary.cash : (claim.agreed ?? claim.claimed),
                  claim.currency,
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (hasDeadline) ...[
                const SizedBox(height: 2),
                ReloDdayText(deadline: claim.deadline, fontSize: 13),
              ],
            ],
          )
        else if (hasDeadline)
          ReloDdayText(deadline: claim.deadline, fontSize: 13),
        if (boxed)
          Icon(ReloIcons.chevronRight, size: 22, color: palette.subtle),
      ],
    );

    final open = onTap ?? () => store.openClaimDetail(claim.id);

    if (boxed) {
      return Semantics(
        button: true,
        label: '$title · $status',
        child: Material(
          color: palette.raised,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: content,
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: '$title · $status',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: open,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: palette.line.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
