import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/dday.dart';
import '../../core/utils/money_format.dart';
import '../../shared/models/domain_models.dart';
import '../../shared/state/relo_store.dart';
import '../../shared/widgets/refund_globe.dart';
import '../../shared/widgets/relo_primitives.dart';

/// @module features/home/home_screen
/// @layer Feature Module — Home
/// @purpose 환불 건이 있으면 맨 위에 "돌려받을 돈"(지구본은 오른쪽 배경), 그 아래
///          신청 버튼 하나와 오늘 할 일. 환불 건이 하나도 없을 때만 소개 글을 보여 준다.
///          화면마다 큰 글자 하나 + 버튼 하나, 설명은 한 줄까지 (DESIGN.md 6절).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 등장 효과는 앱을 켠 첫 화면에서만 재생한다 (탭을 오갈 때는 즉시)
  static bool _playedEntrance = false;
  late final bool _animateEntrance = !_playedEntrance;

  /// 배경 지구본에 쓸 기본 출발지 (진행 중인 환불이 없을 때)
  static const List<GlobeCorridor> _defaultCorridors = [
    GlobeCorridor(id: 'us', city: 'Seattle', lat: 47.6062, lon: -122.3321),
    GlobeCorridor(id: 'cn', city: 'Shenzhen', lat: 22.5431, lon: 114.0579),
    GlobeCorridor(id: 'jp', city: 'Tokyo', lat: 35.6762, lon: 139.6503),
  ];

  @override
  void initState() {
    super.initState();
    _playedEntrance = true;
  }

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final s = store.strings;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final active = store.claims.where((c) => !c.deleted).toList();
    final inFlight = active
        .where((c) => c.state != 'completed' && c.state != 'recovered')
        .toList()
      ..sort(_byDeadline);
    final corridors = inFlight.isEmpty
        ? _defaultCorridors
        : inFlight.take(4).map(GlobeCorridor.fromClaim).toList();

    Widget entrance(Widget child, int order) {
      if (!_animateEntrance || reduceMotion) return child;
      return child
          .animate(delay: Duration(milliseconds: 450 + order * 60))
          .fadeIn(duration: ReloMotion.listItem, curve: ReloMotion.enter)
          .slideY(
              begin: 0.08,
              end: 0,
              duration: ReloMotion.listItem,
              curve: ReloMotion.enter);
    }

    return SingleChildScrollView(
      // 떠 있는 도우미 캐릭터에 마지막 카드가 가리지 않도록 아래를 넉넉히 둔다
      padding: const EdgeInsets.only(bottom: 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (active.isEmpty)
            _buildIntroHero(
                store, palette, s, corridors, reduceMotion, entrance)
          else
            _buildMoneyHero(store, palette, s, active, inFlight.length,
                corridors, reduceMotion, entrance),
          if (inFlight.isNotEmpty) ...[
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: entrance(
                Text(
                  '오늘 할 일',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.ink),
                ),
                4,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < inFlight.length && i < 3; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: entrance(
                    _buildTaskCard(store, inFlight[i], palette), 5 + i),
              ),
          ],
        ],
      ),
    );
  }

  /// 배경 지구본. 앱을 켠 첫 화면에서는 로고가 자리를 잡은 뒤(500ms) 서서히 나타난다
  Widget _buildGlobe(List<GlobeCorridor> corridors, bool reduceMotion) {
    // RefundGlobe에 animate 필드가 있어서 flutter_animate 확장을 쓰려면 Widget으로 받는다
    final Widget globe = RefundGlobe(
      corridors: corridors,
      ambient: true,
      animate: !reduceMotion,
    );
    if (!_animateEntrance || reduceMotion) return globe;
    return globe.animate().fadeIn(
          delay: const Duration(milliseconds: 500),
          duration: const Duration(milliseconds: 450),
        );
  }

  static int _byDeadline(ClaimView a, ClaimView b) {
    final da = DDay.daysLeft(a.deadline) ?? 9999;
    final db = DDay.daysLeft(b.deadline) ?? 9999;
    return da.compareTo(db);
  }

  /// 환불 건이 하나도 없을 때: 지구본 + 소개 + 신청 버튼
  Widget _buildIntroHero(
    ReloStore store,
    ReloPalette palette,
    ReloStrings s,
    List<GlobeCorridor> corridors,
    bool reduceMotion,
    Widget Function(Widget, int) entrance,
  ) {
    const globeHeight = 300.0;
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            height: globeHeight,
            child: _buildGlobe(corridors, reduceMotion),
          ),
          // 지구본 아래쪽은 바탕색으로 녹여서 글자가 지구본 선 위에 놓이지 않게 한다
          Positioned(
            top: globeHeight - 150,
            left: 0,
            right: 0,
            height: 170,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.canvas.withValues(alpha: 0), palette.canvas],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                entrance(
                  Column(
                    children: [
                      Text(
                        s.heroTitleLine1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                          height: 1.35,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        s.heroTitleLine2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: palette.isDark
                              ? const Color(0xFF60A5FA)
                              : palette.brand,
                          height: 1.35,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.heroSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: palette.muted, height: 1.5),
                      ),
                    ],
                  ),
                  1,
                ),
                const SizedBox(height: 20),
                entrance(
                  ReloButton(
                    text: s.ctaPrimary,
                    onPressed: () => store.navigateToTab(1),
                  ),
                  2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 환불 건이 있을 때: 돌려받을 돈을 맨 위에. 지구본은 오른쪽 뒤에서 은은하게 돈다.
  /// 건수가 가장 많은 통화를 기준으로 보여 주고, 다른 통화의 입금 완료 건은 한 줄로 알린다.
  Widget _buildMoneyHero(
    ReloStore store,
    ReloPalette palette,
    ReloStrings s,
    List<ClaimView> active,
    int inFlightCount,
    List<GlobeCorridor> corridors,
    bool reduceMotion,
    Widget Function(Widget, int) entrance,
  ) {
    final counts = <String, int>{};
    for (final c in active) {
      counts[c.currency] = (counts[c.currency] ?? 0) + 1;
    }
    final currency =
        counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;

    var claimed = 0, promised = 0, cash = 0;
    for (final c in active.where((c) => c.currency == currency)) {
      claimed += c.claimed;
      promised += c.agreed ?? c.claimed;
      cash += c.summary.cash;
    }
    final recoveredElsewhere = active
        .where((c) =>
            c.currency != currency &&
            (c.state == 'recovered' || c.state == 'completed'))
        .toList();

    final promisedRatio =
        claimed == 0 ? 0.0 : (promised / claimed).clamp(0.0, 1.0);
    final cashRatio = claimed == 0 ? 0.0 : (cash / claimed).clamp(0.0, 1.0);
    final caption =
        inFlightCount > 0 ? '돌려받을 돈 · $inFlightCount건 진행 중' : '돌려받을 돈';
    final secondary = TextStyle(
      fontSize: 13,
      color: palette.muted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 172,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                top: -50,
                right: -100,
                width: 320,
                height: 320,
                child: _buildGlobe(corridors, reduceMotion),
              ),
              // 글자가 놓이는 왼쪽은 바탕색으로 덮어 지구본 선과 겹치지 않게 한다
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0, 0.5, 0.85],
                      colors: [
                        palette.canvas,
                        palette.canvas.withValues(alpha: 0.85),
                        palette.canvas.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.canvas.withValues(alpha: 0),
                        palette.canvas
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: 28,
                child: entrance(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: palette.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                        duration: ReloMotion.ticker,
                        curve: ReloMotion.enter,
                        builder: (context, t, _) => MoneyDisplay(
                          minorAmount: (claimed * t).round(),
                          currency: currency,
                          size: MoneySize.xl,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '판매자 약속 ${MoneyFormat.formatMinor(promised, currency)}'
                        ' · 입금 ${MoneyFormat.formatMinor(cash, currency)}',
                        style: secondary,
                      ),
                    ],
                  ),
                  0,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: entrance(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReloProgressBar(promised: promisedRatio, cash: cashRatio),
                for (final c in recoveredElsewhere) ...[
                  const SizedBox(height: 12),
                  Text(
                    '✓ ${_shortTitle(c.title)} ${MoneyFormat.formatMinor(c.summary.cash, c.currency)} 들어왔어요',
                    style: secondary,
                  ),
                ],
                const SizedBox(height: 20),
                ReloButton(
                  text: s.ctaPrimary,
                  onPressed: () => store.navigateToTab(1),
                ),
              ],
            ),
            1,
          ),
        ),
      ],
    );
  }

  /// "후지필름 XF 35mm 렌즈 오배송 전액 환불" → "후지필름 XF 35mm"
  static String _shortTitle(String title) {
    final words = title.split(' ');
    return words.take(3).join(' ');
  }

  // 할 일 한 줄: 무엇을(제목) · 지금 할 일 · 남은 날. 판매처와 금액은 내 환불에서 본다.
  Widget _buildTaskCard(ReloStore store, ClaimView claim, ReloPalette palette) {
    return ReloCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      semanticLabel: '${claim.title} 상세 열기',
      onTap: () => store.openClaimDetail(claim.id),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortTitle(claim.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  _humanNextStep(claim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ],
            ),
          ),
          if (claim.deadline != null) ...[
            const SizedBox(width: 12),
            ReloDdayText(deadline: claim.deadline, fontSize: 13),
          ],
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 20, color: palette.subtle),
        ],
      ),
    );
  }

  static String _humanNextStep(ClaimView claim) {
    return switch (claim.state) {
      'preparing' || 'review' => '판매자에게 메시지 보내기',
      'awaiting' => '판매자 답장 기다리는 중',
      'negotiating' => claim.agreed != null
          ? '판매자 제안 ${MoneyFormat.formatMinor(claim.agreed!, claim.currency)} 확인하기'
          : '조건 정하는 중',
      _ => claim.nextStep,
    };
  }
}
