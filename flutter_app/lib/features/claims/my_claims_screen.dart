import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/claim_row.dart';
import '../../shared/widgets/relo_app_shell.dart';
import '../../shared/widgets/relo_mascot.dart';
import '../../shared/widgets/relo_primitives.dart';
import '../assistant/assistant_sheet.dart';
import 'claim_detail_screen.dart';
import '../../shared/widgets/relo_icons.dart';

/// @module features/claims/my_claims_screen
/// @layer Feature Module — My Claims
/// @purpose 내 환불 전체를 조용한 목록으로 보여 준다 (DESIGN.md 7절).
///          맨 위에서 말랑이가 한 줄로 요약하고, 받을 돈 / 받은 돈, 필터·검색·휴지통,
///          그 아래 환불 건은 홈과 같은 줄(상자 없이 가는 선)로 나온다.
///          줄을 누르면 그대로 커지며 상세 화면이 된다 (OpenContainer).
///          맨 아래 "ReLo에게 물어보기"로 도우미 대화를 연다 (이 화면에서는 떠 있는 도우미 대신).
class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  /// 지금 언어의 문구
  ReloStrings get _s => ReloScope.of(context).strings;

  final _searchCtrl = TextEditingController();
  bool _searching = false;

  // 단계별 필터 대신 셋만: 전체 · 진행 중 · 입금 완료 (스토어의 'open' · 'done')
  List<({String id, String label})> get _filterTabs => [
    (id: '', label: _s.mcAll),
    (id: 'open', label: _s.mcOpen),
    (id: 'done', label: _s.mcDone),
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
    final s = store.strings;
    final list = store.filteredClaims;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final active = store.claims.where((c) => !c.deleted).toList();
    final inFlight = active.where((c) => !isClaimDone(c)).toList();
    final replied = inFlight.where((c) => c.replies.isNotEmpty).length;
    final money = ClaimMoney.of(active);

    Widget moneyCell(String label, String amount, {required bool strong}) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      );
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
              color: on ? (onColor ?? palette.brand) : palette.raised,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 18, color: on ? Colors.white : palette.muted),
          ),
        ),
      );
    }

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.subtle,
            ),
          ),
        );

    // 전체를 볼 때는 진행 중인 건과 입금이 끝난 건을 나눠서 보여 준다
    final grouped = store.stateFilter.isEmpty && !store.showTrash;
    final rows = <Widget>[];
    var index = 0;
    void addRows(Iterable<ClaimView> claims) {
      for (final c in claims) {
        rows.add(_withEntrance(_buildRow(c, palette), index++, reduceMotion));
      }
    }

    if (grouped) {
      final open = list.where((c) => !isClaimDone(c)).toList();
      final done = list.where(isClaimDone).toList();
      if (open.isNotEmpty) {
        rows.add(sectionLabel(_filterTabs[1].label));
        addRows(open);
      }
      if (done.isNotEmpty) {
        rows.add(sectionLabel(_filterTabs[2].label));
        addRows(done);
      }
    } else {
      addRows(list);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 말랑이의 한 줄 요약
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const ReloMascot(size: 48, hopOnTap: true),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.claimsSummary(inFlight.length, replied),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. 받을 돈 / 받은 돈 (상자 없이 가는 선으로만 나눈다)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        moneyCell(s.homeMoneyDue(money.dueCount), money.due,
                            strong: true),
                        VerticalDivider(
                          width: 33,
                          thickness: 1,
                          color: palette.line.withValues(alpha: 0.5),
                        ),
                        moneyCell(s.homeMoneyReceived, money.received,
                            strong: false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 3. 필터 · 검색 · 휴지통을 한 줄에
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // 다른 언어에서 필터 이름이 길어져도 검색 · 휴지통 단추를 밀어내지 않게,
                      // 필터 쪽만 남는 너비 안에서 옆으로 밀리게 한다
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (!store.showTrash)
                                for (final tab in _filterTabs)
                                  ReloTextTab(
                                    label: tab.label,
                                    selected: store.stateFilter == tab.id,
                                    onTap: () =>
                                        store.setFilter(state: tab.id),
                                  )
                              else
                                Text(
                                  _s.mcTrash,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: palette.ink,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      roundIcon(
                        icon: ReloIcons.search,
                        label: _searching ? _s.mcSearchClose : _s.mcSearch,
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
                        icon: ReloIcons.trash,
                        label: store.showTrash ? _s.mcTrashClose : _s.mcTrashOpen,
                        on: store.showTrash,
                        onColor: palette.danger,
                        onTap: () => store.setFilter(trash: !store.showTrash),
                      ),
                    ],
                  ),
                ),
                if (_searching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      onChanged: (v) => store.setFilter(query: v),
                      style: TextStyle(fontSize: 14, color: palette.ink),
                      decoration: InputDecoration(
                        hintText: _s.mcSearchHint,
                        hintStyle:
                            TextStyle(fontSize: 13, color: palette.subtle),
                        prefixIcon: Icon(ReloIcons.search,
                            size: 18, color: palette.subtle),
                        filled: true,
                        fillColor: palette.raised,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
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

                // 4. 환불 건
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                    child: Column(
                      children: [
                        Text(
                          store.showTrash ? _s.mcTrashEmpty : _s.mcEmpty,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        if (!store.showTrash) ...[
                          const SizedBox(height: 16),
                          ReloButton(
                            text: _s.mcStart,
                            onPressed: () => store.navigateToTab(1),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  ...rows,
              ],
            ),
          ),
        ),
        // 5. 도우미에게 묻기 (이 화면에서는 떠 있는 도우미 대신 여기 하나만 둔다)
        ReloAskBar(label: s.claimsAsk, onTap: () => showReloAssistant(context)),
      ],
    );
  }

  /// 줄이 하나씩 아래에서 올라온다 (항목당 40ms 간격)
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

  /// 홈과 같은 줄에 금액을 더해 보여 준다. 누르면 줄이 그대로 커지며 상세가 된다.
  Widget _buildRow(ClaimView claim, ReloPalette palette) {
    return OpenContainer<void>(
      transitionDuration: ReloMotion.openContainer,
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      openElevation: 0,
      closedColor: palette.canvas,
      openColor: palette.canvas,
      middleColor: palette.canvas,
      closedShape: const RoundedRectangleBorder(),
      openBuilder: (context, close) =>
          _ClaimDetailRoute(claimId: claim.id, onClose: close),
      closedBuilder: (context, open) =>
          ClaimRow(claim: claim, showAmount: true, onTap: open),
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
