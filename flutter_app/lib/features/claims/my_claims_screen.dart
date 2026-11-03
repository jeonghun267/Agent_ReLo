import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/dday.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_app_shell.dart';
import '../../shared/widgets/relo_primitives.dart';
import 'claim_detail_screen.dart';

/// @module features/claims/my_claims_screen
/// @layer Feature Module — My Claims
/// @purpose 통화별 환불 통장 요약, 상태 필터·검색·휴지통, 환불 건 카드.
///          카드마다 "약속 → 입금" 막대와 남은 날(D-day)을 보여 주고,
///          누르면 카드가 그대로 커지며 상세 화면이 된다 (OpenContainer).
class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  String _selectedCurrencyTab = 'USD';
  final _searchCtrl = TextEditingController();

  static const List<({String id, String label})> _filterTabs = [
    (id: '', label: '전체'),
    (id: 'preparing', label: '서류 준비'),
    (id: 'awaiting', label: '답변 대기'),
    (id: 'negotiating', label: '조건 조율'),
    (id: 'recovered', label: '입금 확인'),
    (id: 'completed', label: '완료'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final list = store.filteredClaims;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final activeCurrencies = <String>{'USD'};
    for (final c in store.claims.where((e) => !e.deleted)) {
      activeCurrencies.add(c.currency);
    }
    if (!activeCurrencies.contains(_selectedCurrencyTab)) {
      _selectedCurrencyTab = activeCurrencies.first;
    }

    int totalClaimed = 0;
    int totalAgreed = 0;
    int totalCash = 0;
    for (final c in store.claims.where(
      (e) => !e.deleted && e.currency == _selectedCurrencyTab,
    )) {
      totalClaimed += c.claimed;
      totalAgreed += (c.agreed ?? c.claimed);
      totalCash += c.summary.cash;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 통화별 환불 통장 요약
          ReloCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '내 환불 통장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: activeCurrencies.map((cur) {
                        final selected = cur == _selectedCurrencyTab;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCurrencyTab = cur),
                          child: AnimatedContainer(
                            duration: ReloMotion.press,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? palette.brand : palette.sunken,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              cur,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : palette.body,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('입금 확인',
                    style: TextStyle(fontSize: 12, color: palette.subtle)),
                const SizedBox(height: 2),
                MoneyDisplay(
                  minorAmount: totalCash,
                  currency: _selectedCurrencyTab,
                  size: MoneySize.xl,
                  color: palette.ink,
                ),
                const SizedBox(height: 6),
                Text(
                  '판매자 약속 ${MoneyFormat.formatMinor(totalAgreed, _selectedCurrencyTab)} · 요청 ${MoneyFormat.formatMinor(totalClaimed, _selectedCurrencyTab)}',
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. 검색 & 휴지통
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => store.setFilter(query: v),
                  style: TextStyle(fontSize: 14, color: palette.ink),
                  decoration: InputDecoration(
                    hintText: '상품명 · 쇼핑몰 · 주문번호',
                    hintStyle: TextStyle(fontSize: 13, color: palette.subtle),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: palette.subtle,
                    ),
                    filled: true,
                    fillColor: palette.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: palette.focusRing),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: store.showTrash ? '휴지통 닫기' : '휴지통 열기',
                child: GestureDetector(
                  onTap: () => store.setFilter(trash: !store.showTrash),
                  child: AnimatedContainer(
                    duration: ReloMotion.press,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: store.showTrash
                          ? palette.dangerSoft
                          : palette.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: store.showTrash ? palette.danger : palette.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. 상태 필터 칩
          if (!store.showTrash)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterTabs.map((tab) {
                  final active = store.stateFilter == tab.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => store.setFilter(state: tab.id),
                      child: AnimatedContainer(
                        duration: ReloMotion.press,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? palette.brand : palette.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : palette.body,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),

          if (list.isEmpty)
            ReloCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: palette.subtle),
                  const SizedBox(height: 12),
                  Text(
                    store.showTrash ? '휴지통이 비어 있어요' : '아직 환불 신청이 없어요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ReloButton(
                    text: '환불 신청 시작하기',
                    onPressed: () => store.navigateToTab(1),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < list.length; i++)
              _withEntrance(
                _buildClaimCard(store, list[i], palette),
                i,
                reduceMotion,
              ),
        ],
      ),
    );
  }

  /// 카드가 하나씩 아래에서 올라온다 (항목당 40ms 간격)
  Widget _withEntrance(Widget child, int index, bool reduceMotion) {
    if (reduceMotion) return child;
    return child
        .animate(delay: ReloMotion.listStagger * index)
        .fadeIn(duration: ReloMotion.listItem, curve: ReloMotion.enter)
        .slideY(
            begin: 0.06,
            end: 0,
            duration: ReloMotion.listItem,
            curve: ReloMotion.enter);
  }

  Widget _buildClaimCard(
      ReloStore store, ClaimView claim, ReloPalette palette) {
    final stateLabel = store.config.states[claim.state] ?? claim.state;
    final isRecovered =
        claim.state == 'recovered' || claim.state == 'completed';
    final promised = claim.agreed ?? claim.claimed;
    final promisedRatio =
        claim.claimed == 0 ? 0.0 : (promised / claim.claimed).clamp(0.0, 1.0);
    final cashRatio = claim.claimed == 0
        ? 0.0
        : (claim.summary.cash / claim.claimed).clamp(0.0, 1.0);
    final dday = DDay.label(claim.deadline);
    // 진행 상태는 배지 대신 회색 글자로. 입금이 끝난 건은 "입금 완료"라고 쓴다
    final metaLabel =
        '${claim.vendor} · ${isRecovered ? '입금 완료' : stateLabel}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OpenContainer<void>(
        transitionDuration: ReloMotion.openContainer,
        transitionType: ContainerTransitionType.fadeThrough,
        closedElevation: 0,
        openElevation: 0,
        closedColor: palette.surface,
        openColor: palette.canvas,
        middleColor: palette.canvas,
        closedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        openBuilder: (context, close) =>
            _ClaimDetailRoute(claimId: claim.id, onClose: close),
        closedBuilder: (context, open) => Semantics(
          button: true,
          label: '${claim.vendor} ${claim.title} 상세 열기',
          child: InkWell(
            onTap: open,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                metaLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: palette.muted),
                              ),
                            ),
                            if (dday != null && !isRecovered) ...[
                              Text(' · ',
                                  style: TextStyle(
                                      fontSize: 12, color: palette.muted)),
                              ReloDdayText(deadline: claim.deadline),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyDisplay(
                        minorAmount: promised,
                        currency: claim.currency,
                        size: MoneySize.md,
                        color: palette.ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    claim.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 약속 → 입금 막대. ReLo가 끝까지 따라가는 차액이 한눈에 보인다
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Positioned.fill(
                              child: ColoredBox(color: palette.sunken)),
                          FractionallySizedBox(
                            widthFactor: promisedRatio,
                            child: ColoredBox(
                                color: palette.brand.withValues(alpha: 0.35)),
                          ),
                          FractionallySizedBox(
                            widthFactor: cashRatio,
                            child: ColoredBox(color: palette.brand),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRecovered
                        ? '✓ ${MoneyFormat.formatMinor(claim.summary.cash, claim.currency)} 들어왔어요'
                        : claim.summary.cash > 0
                            ? '입금 ${MoneyFormat.formatMinor(claim.summary.cash, claim.currency)} · 아직 ${MoneyFormat.formatMinor(claim.summary.remaining, claim.currency)} 남음'
                            : '아직 입금 전이에요',
                    style: TextStyle(
                      fontSize: 12,
                      color: isRecovered ? palette.body : palette.subtle,
                    ),
                  ),
                  if (claim.replies.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.sunken,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '판매자 답장: ${claim.replies.first.summaryKo}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: palette.body, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// OpenContainer로 열린 상세 화면. 앱 셸 밖의 전체 화면 라우트라서
/// 바탕색과 너비 제한을 직접 맞춘다.
class _ClaimDetailRoute extends StatelessWidget {
  final String claimId;
  final VoidCallback onClose;
  const _ClaimDetailRoute({required this.claimId, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kReloShellMaxWidth),
            child: ClaimDetailScreen(claimId: claimId, onClose: onClose),
          ),
        ),
      ),
    );
  }
}
