import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
/// @purpose 위에는 지구본을 배경으로 한 소개와 "3분 만에 환불 신청하기" 버튼,
///          아래에는 돌려받을 돈과 오늘 할 일. 처음 쓰는 사람에게는 버튼이,
///          이미 쓰는 사람에게는 내 상황이 먼저 보인다 (DESIGN.md 1절).
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
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context, store, palette, s, corridors, inFlight.length,
              reduceMotion, entrance),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child:
                  entrance(_buildMoneyCard(active, palette, reduceMotion), 3),
            ),
          ],
          if (inFlight.isNotEmpty) ...[
            const SizedBox(height: 24),
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

  Widget _buildHero(
    BuildContext context,
    ReloStore store,
    ReloPalette palette,
    dynamic s,
    List<GlobeCorridor> corridors,
    int inFlightCount,
    bool reduceMotion,
    Widget Function(Widget, int) entrance,
  ) {
    const globeHeight = 300.0;
    return SizedBox(
      height: 440,
      child: Stack(
        children: [
          // 배경 지구본. 아래쪽은 바탕색으로 녹아들게 한다.
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            height: globeHeight,
            child: _buildGlobe(corridors, reduceMotion),
          ),
          Positioned(
            top: globeHeight - 120,
            left: 0,
            right: 0,
            height: 140,
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
                if (inFlightCount > 0)
                  entrance(
                    Text(
                      '$inFlightCount건이 서울로 돌아오는 중',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.subtle),
                    ),
                    0,
                  ),
                if (inFlightCount > 0) const SizedBox(height: 12),
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
                            fontSize: 13, color: palette.muted, height: 1.5),
                      ),
                    ],
                  ),
                  1,
                ),
                const SizedBox(height: 20),
                entrance(
                  Column(
                    children: [
                      ReloButton(
                        text: s.ctaPrimary,
                        onPressed: () => store.navigateToTab(1),
                      ),
                      const SizedBox(height: 8),
                      ReloButton(
                        text: s.ctaSecondary,
                        isPrimary: false,
                        onPressed: () => store.navigateToTab(2),
                      ),
                    ],
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

  /// 돌려받을 돈. 건수가 가장 많은 통화를 기준으로 보여 주고,
  /// 다른 통화의 입금 완료 건은 아래 초록 칩으로 알린다.
  Widget _buildMoneyCard(
      List<ClaimView> active, ReloPalette palette, bool reduceMotion) {
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

    return ReloCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('돌려받을 돈', style: TextStyle(fontSize: 14, color: palette.muted)),
          const SizedBox(height: 4),
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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: palette.sunken)),
                  // 약속은 옅은 파랑, 실제 입금은 진한 파랑 (색은 파랑 하나만)
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legend('판매자 약속', MoneyFormat.formatMinor(promised, currency),
                  palette),
              _legend('입금', MoneyFormat.formatMinor(cash, currency), palette),
            ],
          ),
          for (final c in recoveredElsewhere) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_rounded, size: 16, color: palette.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_shortTitle(c.title)} ${MoneyFormat.formatMinor(c.summary.cash, c.currency)} 들어왔어요',
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legend(String label, String value, ReloPalette palette,
      {Color? color}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: '$label ',
              style: TextStyle(fontSize: 12, color: palette.subtle)),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? palette.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// "후지필름 XF 35mm 렌즈 오배송 전액 환불" → "후지필름 XF 35mm"
  static String _shortTitle(String title) {
    final words = title.split(' ');
    return words.take(3).join(' ');
  }

  Widget _buildTaskCard(ReloStore store, ClaimView claim, ReloPalette palette) {
    final dday = DDay.label(claim.deadline);
    final code =
        GlobeCorridor.fromClaim(claim).city.substring(0, 2).toUpperCase();

    return ReloCard(
      padding: const EdgeInsets.all(16),
      semanticLabel: '${claim.title} 상세 열기',
      onTap: () => store.openClaimDetail(claim.id),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.sunken,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              code,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.muted),
            ),
          ),
          const SizedBox(width: 12),
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
                      fontWeight: FontWeight.w600,
                      color: palette.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${claim.vendor} · ${_humanNextStep(claim)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.subtle),
                ),
              ],
            ),
          ),
          if (dday != null) ...[
            const SizedBox(width: 8),
            ReloDdayText(deadline: claim.deadline),
          ],
        ],
      ),
    );
  }

  static String _humanNextStep(ClaimView claim) {
    return switch (claim.state) {
      'preparing' || 'review' => '외국어 요청서를 보내세요',
      'awaiting' => '판매자 답장을 기다리는 중',
      'negotiating' => claim.agreed != null
          ? '판매자 제안 ${MoneyFormat.formatMinor(claim.agreed!, claim.currency)} 확인'
          : '조건을 조율하는 중',
      _ => claim.nextStep,
    };
  }
}
