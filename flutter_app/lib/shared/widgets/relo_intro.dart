import 'package:flutter/material.dart';

import '../../core/platform/splash_handoff.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../state/relo_store.dart';
import 'relo_app_shell.dart';
import 'relo_mascot.dart';

/// @module shared/widgets/relo_intro
/// @purpose 앱 시작 연출 (1.3초). 기기의 시작 화면(어두운 바탕 가운데 로고)에서 그대로 이어받는다.
///
///          0.00 ~ 0.18  가운데 로고가 말랑이로 깨어난다 (살짝 부풀며 바뀜)
///          0.08 ~ 0.30  그 아래에 `ReLo`와 한 줄 소개가 올라온다
///          0.20 ~       말랑이가 한 번 폴짝 뛰며 윙크한다 (0.7초)
///          0.66 ~ 0.76  글자가 사라진다
///          0.74 ~ 0.95  말랑이가 작아지며 상단 바의 로고 자리로 들어가 다시 로고가 된다
///          0.76 ~ 1.00  덮개가 걷히며 홈이 드러난다
///
///          이 화면의 첫 모습은 기기의 시작 화면과 똑같다(바탕색 + 같은 자리의 로고). 그 첫 모습이
///          실제로 화면에 그려진 뒤에 기기의 시작 화면을 걷고 연출을 시작한다 ([SplashHandoff]).
///          모션 줄이기가 켜져 있으면 연출 없이 바로 홈을 보여 준다.
class ReloIntro extends StatefulWidget {
  final Widget child;
  const ReloIntro({super.key, required this.child});

  /// 가운데 로고의 크기. 안드로이드 시작 화면의 로고(res/drawable/splash_logo.xml)와 같다.
  static const double logoSize = 96;

  @override
  State<ReloIntro> createState() => _ReloIntroState();
}

class _ReloIntroState extends State<ReloIntro>
    with SingleTickerProviderStateMixin {
  static const double _hopAt = 0.20;

  /// 말랑이 그림 상자의 크기. 몸통(상자의 0.8)이 로고 크기와 같아지게 잡는다.
  static const double _mascotBox = ReloIntro.logoSize / 0.8;

  // 연출을 천천히 돌려 장면을 하나씩 확인할 때:
  //   flutter run --dart-define=RELO_INTRO_SLOW=6
  static const int _slow = int.fromEnvironment('RELO_INTRO_SLOW', defaultValue: 1);

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: ReloMotion.intro * _slow,
  );
  bool _done = false;
  int _hop = 0;

  /// 기기의 시작 화면에서 로고가 있던 자리 (기기 픽셀). 모르면 화면 한가운데에서 시작한다.
  /// 화면 배율은 앱이 막 떴을 때는 아직 알 수 없어서(1.0으로 나온다), 그릴 때마다 그때의 배율로 나눈다.
  Offset? _handoffCenterPx;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTick);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      setState(() => _done = true);
      return;
    }
    final center = await SplashHandoff.takeOver();
    if (!mounted) return;
    if (center != null) setState(() => _handoffCenterPx = center);
    _ctrl.forward();
  }

  void _onTick() {
    if (_hop == 0 && _ctrl.value >= _hopAt) setState(() => _hop = 1);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static double _span(double t, double from, double to) =>
      ((t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    // 홈은 처음부터 덮개 아래에 그려 둔다. 처음 그릴 때 드는 준비를 기기의 시작 화면이 떠 있는 동안
    // 끝내 두어야, 연출 도중에 화면이 버벅이지 않는다. 늘 같은 자리(첫째 칸)에 두므로
    // 덮개를 걷어도 홈이 처음부터 다시 그려지지 않는다.
    return Stack(
      children: [
        widget.child,
        if (!_done)
          Positioned.fill(
            child: AnimatedBuilder(animation: _ctrl, builder: _buildOverlay),
          ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context, Widget? _) {
    final palette = ReloPalette.of(context);
    final strings = ReloScope.of(context).strings;
    final t = _ctrl.value;

    final wake = Curves.easeOutCubic.transform(_span(t, 0, 0.18));
    final textIn = Curves.easeOutCubic.transform(_span(t, 0.08, 0.30));
    final textOut = Curves.easeInCubic.transform(_span(t, 0.66, 0.76));
    final move = Curves.easeInOutCubic.transform(_span(t, 0.74, 0.95));
    final veil = 1 - Curves.easeInCubic.transform(_span(t, 0.76, 1));
    // 옮겨 가는 뒤 절반에서 말랑이가 다시 로고가 된다
    final backToLogo = _span(move, 0.45, 1);
    final mascotOpacity = wake * (1 - backToLogo);
    // 로고는 말랑이가 다 나타날 때까지 그 밑에 그대로 둔다 (둘 다 흐려지면 가운데가 어두워 보인다).
    // 상단 바의 진짜 로고와 겹치는 마지막 구간에서 사라진다.
    final logoOpacity = mascotOpacity >= 1 ? 0.0 : 1 - _span(t, 0.95, 1);
    // 시작하기 전(기기의 시작 화면이 덮고 있는 동안)에 말랑이와 글자를 거의 안 보이게 한 번 그려 둔다.
    // 처음 그릴 때 드는 준비를 미리 끝내서, 연출의 첫 장면이 버벅이지 않게 한다.
    final warmUp = t == 0 ? 0.01 : 0.0;
    final mascotShown = mascotOpacity > warmUp ? mascotOpacity : warmUp;
    final textOpacity = textIn * (1 - textOut);
    final textShown = textOpacity > warmUp ? textOpacity : warmUp;

    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final shellWidth =
        size.width < kReloShellMaxWidth ? size.width : kReloShellMaxWidth;
    final shellLeft = (size.width - shellWidth) / 2;

    final handoff = _handoffCenterPx;
    final startCenter = handoff != null
        ? handoff / MediaQuery.devicePixelRatioOf(context)
        : Offset(size.width / 2, size.height / 2);
    final endCenter = Offset(
      shellLeft + 20 + kReloLogoSize / 2,
      padding.top + kReloTopBarHeight / 2,
    );
    final center = Offset.lerp(startCenter, endCenter, move)!;
    const big = ReloIntro.logoSize;
    final logoSize = big + (kReloLogoSize - big) * move;
    // 깨어날 때 살짝 부풀었다 돌아온다
    final pop = 1 + 0.12 * Curves.easeInOut.transform(1 - (2 * wake - 1).abs());
    final scale = logoSize / big * pop;

    // 말랑이 몸통의 가운데 (그림 상자 안에서의 자리, relo_mascot.dart의 몸통 수식과 같다)
    const bodyCenter = Offset(_mascotBox * 0.4, _mascotBox * 0.53);

    // 이 덮개는 화면 틀(Scaffold) 바깥에 있다. 글자가 앱의 글꼴 · 기본 모양을 따르도록 Material로 감싼다.
    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: palette.canvas.withValues(alpha: veil)),
          ),
          // 로고 (기기의 시작 화면과 같은 모습에서 출발)
          if (logoOpacity > 0)
            Positioned(
              left: center.dx - logoSize * pop / 2,
              top: center.dy - logoSize * pop / 2,
              child: Opacity(
                opacity: logoOpacity,
                child: ReloLogoMark(size: logoSize * pop),
              ),
            ),
          // 말랑이: 몸통이 로고와 같은 자리 · 같은 크기에 오게 놓는다
          if (mascotShown > 0)
            Positioned(
              left: center.dx - bodyCenter.dx,
              top: center.dy - bodyCenter.dy,
              child: Opacity(
                opacity: mascotShown,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  origin: bodyCenter,
                  child: ReloMascot(size: _mascotBox, hopSignal: _hop),
                ),
              ),
            ),
          // 이름과 한 줄 소개
          Positioned(
            left: 24,
            right: 24,
            top: startCenter.dy + big / 2 + 34 + 10 * (1 - textIn),
            child: Opacity(
              opacity: textShown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 이 덮개는 화면 틀(Scaffold) 바깥에 있어서, 글자에 밑줄이 붙지 않게 직접 끈다
                  Text(
                    'ReLo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: palette.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.introTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: palette.muted,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
