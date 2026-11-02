import 'package:flutter/material.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/relo_orb_emblem.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/claims/my_claims_screen
/// @layer Feature Module — My Claims Passbook & Dashboard
/// @purpose 통화별 분리 환불 통장 요약 카드 및 상태별 필터·검색·휴지통 관리 화면입니다.
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 통화별 환불 통장 요약 카드
          ReloCard(
            backgroundColor: palette.brandSoft.withValues(alpha: 0.65),
            borderColor: palette.brandLine,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '내 직구 환불 통장 ($_selectedCurrencyTab)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? palette.brand : palette.surface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              cur,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
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
                          minorAmount: totalCash,
                          currency: _selectedCurrencyTab,
                          size: MoneySize.xl,
                          color: totalCash > 0 ? palette.mint : palette.ink,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '쇼핑몰 약속 / 총 요청',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${MoneyFormat.formatMinor(totalAgreed, _selectedCurrencyTab)} / ${MoneyFormat.formatMinor(totalClaimed, _selectedCurrencyTab)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: palette.body,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. 검색어 입력 & 휴지통 토글
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => store.setFilter(query: v),
                  style: TextStyle(fontSize: 13, color: palette.ink),
                  decoration: InputDecoration(
                    hintText: '상품명 · 쇼핑몰 · 주문번호 검색',
                    hintStyle: TextStyle(fontSize: 12, color: palette.subtle),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: palette.muted,
                    ),
                    filled: true,
                    fillColor: palette.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.focusRing),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => store.setFilter(trash: !store.showTrash),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: store.showTrash
                        ? palette.dangerSoft
                        : palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: store.showTrash ? palette.danger : palette.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: store.showTrash ? palette.danger : palette.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '휴지통',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: store.showTrash
                              ? palette.danger
                              : palette.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. 상태별 필터 칩
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? palette.brand : palette.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active ? palette.brand : palette.line,
                          ),
                        ),
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: active ? Colors.white : palette.body,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 14),

          if (list.isEmpty)
            ReloCard(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  const ReloOrbEmblem(size: 64),
                  const SizedBox(height: 12),
                  Text(
                    store.showTrash
                        ? '휴지통이 비어 있어요.'
                        : '조건에 맞는 환불 신청 내역이 없어요.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ReloButton(
                    text: '새 환불 신청 시작하기',
                    onPressed: () => store.navigateToTab(1),
                  ),
                ],
              ),
            )
          else
            ...list.map((claim) => _buildClaimItemCard(store, claim, palette)),
        ],
      ),
    );
  }

  Widget _buildClaimItemCard(
    ReloStore store,
    ClaimView claim,
    ReloPalette palette,
  ) {
    final stateLabel = store.config.states[claim.state] ?? claim.state;
    final isRecovered =
        claim.state == 'recovered' || claim.state == 'completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ReloCard(
        semanticLabel: '${claim.vendor} ${claim.title} 상세 열기',
        onTap: () => store.openClaimDetail(claim.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ReloBadge(
                        label: '${claim.vendor} · $stateLabel',
                        tone: isRecovered
                            ? ReloBadgeTone.mint
                            : ReloBadgeTone.brand,
                      ),
                      if (claim.deadline != null && claim.deadline!.isNotEmpty)
                        ReloBadge(
                          label: '마감 ${claim.deadline}',
                          tone: ReloBadgeTone.sunny,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MoneyDisplay(
                  minorAmount: claim.agreed ?? claim.claimed,
                  currency: claim.currency,
                  size: MoneySize.md,
                  color: isRecovered ? palette.mint : palette.ink,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              claim.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '주문번호 #${claim.orderRef} · ${claim.nextStep}',
              style: TextStyle(
                fontSize: 11.5,
                color: palette.muted,
              ),
            ),
            if (claim.replies.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.sunken,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.line),
                ),
                child: Text(
                  '💬 판매자 답장 요약: ${claim.replies.first.summaryKo}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: palette.brandHover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
