import 'package:flutter/material.dart';

import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import 'relo_app_shell.dart';

/// @module shared/widgets/relo_intro
/// @purpose 앱 시작 연출. 0~400ms 가운데서 로고 고리가 그려지고,
///          400~700ms 로고가 작아지며 상단 바 자리로 옮겨 간 뒤 덮개가 걷힌다.
///          홈 내용은 그 사이(450ms~) 아래에서 올라온다 (home_screen.dart).
///          모션 줄이기가 켜져 있으면 바로 홈을 보여 준다.
class ReloIntro extends StatefulWidget {
  final Widget child;
  const ReloIntro({super.key, required this.child});

  @override
  State<ReloIntro> createState() => _ReloIntroState();
}

class _ReloIntroState extends State<ReloIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: ReloMotion.intro,
  );
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        setState(() => _done = true);
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    final palette = ReloPalette.of(context);
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              // 0~0.44: 고리 그리기 / 0.44~0.78: 이동+축소 / 0.55~1: 덮개 걷힘
              final ring =
                  Curves.easeOutCubic.transform((t / 0.44).clamp(0, 1));
              final move = Curves.easeInOutCubic
                  .transform(((t - 0.44) / 0.34).clamp(0, 1));
              final veil = 1 -
                  Curves.easeInCubic.transform(((t - 0.55) / 0.45).clamp(0, 1));

              final size = MediaQuery.sizeOf(context);
              final padding = MediaQuery.paddingOf(context);
              final shellWidth = size.width < kReloShellMaxWidth
                  ? size.width
                  : kReloShellMaxWidth;
              final shellLeft = (size.width - shellWidth) / 2;

              const bigSize = 96.0;
              final startCenter = Offset(size.width / 2, size.height * 0.42);
              final endCenter = Offset(
                shellLeft + 20 + kReloLogoSize / 2,
                padding.top + kReloTopBarHeight / 2,
              );
              final center = Offset.lerp(startCenter, endCenter, move)!;
              final logoSize = bigSize + (kReloLogoSize - bigSize) * move;

              return IgnorePointer(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: palette.canvas.withValues(alpha: veil),
                      ),
                    ),
                    Positioned(
                      left: center.dx - logoSize / 2,
                      top: center.dy - logoSize / 2,
                      child: Opacity(
                        // 상단 바의 진짜 로고와 겹치는 마지막 구간에서 사라진다
                        opacity:
                            t > 0.9 ? (1 - (t - 0.9) / 0.1).clamp(0, 1) : 1,
                        child: ReloLogoMark(size: logoSize, ringProgress: ring),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
