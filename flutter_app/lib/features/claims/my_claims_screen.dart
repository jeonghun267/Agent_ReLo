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
  bool _searching = false;

  // 단계별 필터 대신 셋만: 전체 · 진행 중 · 입금 완료 (스토어의 'open' · 'done')
  static const List<({String id, String label})> _filterTabs = [
    (id: '', label: '전체'),
    (id: 'open', label: '진행 중'),
    (id: 'done', label: '입금 완료'),
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

    Widget roundIcon({
      required IconData icon,
      required String label,
      required bool on,
      required VoidCallback onTap,
      Color? onColor,
    }) {
      return Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: ReloMotion.press,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: on ? (onColor ?? palette.brand) : palette.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 18, color: on ? Colors.white : palette.muted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      // 떠 있는 도우미 캐릭터에 마지막 카드가 가리지 않도록 아래를 넉넉히 둔다
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 들어온 돈 (통화별)
          ReloCard(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '들어온 돈',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.muted,
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
                const SizedBox(height: 4),
                MoneyDisplay(
                  minorAmount: totalCash,
                  currency: _selectedCurrencyTab,
                  size: MoneySize.xl,
                  color: palette.ink,
                ),
                const SizedBox(height: 6),
                Text(
                  '판매자 약속 ${MoneyFormat.formatMinor(totalAgreed, _selectedCurrencyTab)} · 요청 ${MoneyFormat.formatMinor(totalClaimed, _selectedCurrencyTab)}',
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. 필터 · 검색 · 휴지통을 한 줄에
          Row(
            children: [
              if (!store.showTrash)
                for (final tab in _filterTabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => store.setFilter(state: tab.id),
                      child: AnimatedContainer(
                        duration: ReloMotion.press,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: store.stateFilter == tab.id
                              ? palette.brand
                              : palette.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: store.stateFilter == tab.id
                                ? Colors.white
                                : palette.body,
                          ),
                        ),
                      ),
                    ),
                  )
              else
                Text(
                  '휴지통',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              const Spacer(),
              roundIcon(
                icon: Icons.search_rounded,
                label: _searching ? '검색 닫기' : '검색',
                on: _searching,
                onTap: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _searchCtrl.clear();
                    store.setFilter(query: '');
                  }
                }),
              ),
              const SizedBox(width: 6),
              roundIcon(
                icon: Icons.delete_outline_rounded,
                label: store.showTrash ? '휴지통 닫기' : '휴지통 열기',
                on: store.showTrash,
                onColor: palette.danger,
                onTap: () => store.setFilter(trash: !store.showTrash),
              ),
            ],
          ),
          if (_searching) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (v) => store.setFilter(query: v),
              style: TextStyle(fontSize: 14, color: palette.ink),
              decoration: InputDecoration(
                hintText: '상품명 · 쇼핑몰 · 주문번호',
                hintStyle: TextStyle(fontSize: 13, color: palette.subtle),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: palette.subtle),
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
          ],
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
                                    fontSize: 13, color: palette.muted),
                              ),
                            ),
                            if (dday != null && !isRecovered) ...[
                              Text(' · ',
                                  style: TextStyle(
                                      fontSize: 13, color: palette.muted)),
                              ReloDdayText(
                                  deadline: claim.deadline, fontSize: 13),
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
                  const SizedBox(height: 8),
                  Text(
                    claim.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 약속 → 입금 막대. ReLo가 끝까지 따라가는 차액이 한눈에 보인다
                  ReloProgressBar(
                      promised: promisedRatio, cash: cashRatio, height: 6),
                  const SizedBox(height: 8),
                  // 답장 내용은 상세 화면에서 보고, 목록에는 "답장 왔어요"만 알린다
                  Text.rich(
                    TextSpan(
                      children: [
                        if (claim.replies.isNotEmpty && !isRecovered)
                          TextSpan(
                            text: '답장 왔어요 · ',
                            style: TextStyle(
                              color: palette.brandHover,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        TextSpan(
                          text: isRecovered
                              ? '✓ ${MoneyFormat.formatMinor(claim.summary.cash, claim.currency)} 들어왔어요'
                              : claim.summary.cash > 0
                                  ? '입금 ${MoneyFormat.formatMinor(claim.summary.cash, claim.currency)} · ${MoneyFormat.formatMinor(claim.summary.remaining, claim.currency)} 남음'
                                  : '아직 입금 전',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: isRecovered ? palette.body : palette.muted,
                    ),
                  ),
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
