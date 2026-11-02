import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../state/relo_store.dart';

class _SwitchTabIntent extends Intent {
  final int index;
  const _SwitchTabIntent(this.index);
}

/// 상단 바의 높이. 시작 연출(ReloIntro)이 로고를 이 자리로 옮길 때 같이 쓴다.
const double kReloTopBarHeight = 56;
const double kReloLogoSize = 30;
const double kReloShellMaxWidth = 480;

/// @module shared/widgets/relo_app_shell
/// @layer Shared Application Shell (Top Bar + Keyboard Navigation + 4-Tab Bar)
/// @purpose 상단에는 로고와 프로필만, 하단에는 홈 · 내 환불 · ＋신청 · 설정 네 탭을 둔다.
///          언어·테마·고대비는 설정 화면에 있고, 약관·정책은 설정 안에서 연다.
///          키보드(Tab, Shift+Tab, Enter, Alt+1~5)만으로도 모든 화면을 이동할 수 있다.
class ReloAppShell extends StatelessWidget {
  final Widget body;
  final VoidCallback onUserTap;

  const ReloAppShell({
    super.key,
    required this.body,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final s = store.strings;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.digit1, alt: true):
            _SwitchTabIntent(0),
        SingleActivator(LogicalKeyboardKey.digit2, alt: true):
            _SwitchTabIntent(1),
        SingleActivator(LogicalKeyboardKey.digit3, alt: true):
            _SwitchTabIntent(2),
        SingleActivator(LogicalKeyboardKey.digit4, alt: true):
            _SwitchTabIntent(3),
        SingleActivator(LogicalKeyboardKey.digit5, alt: true):
            _SwitchTabIntent(4),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SwitchTabIntent: CallbackAction<_SwitchTabIntent>(
            onInvoke: (intent) {
              store.navigateToTab(intent.index);
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Scaffold(
            backgroundColor: palette.canvas,
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: kReloShellMaxWidth),
                  child: Column(
                    children: [
                      _buildTopBar(context, store, palette),
                      Expanded(child: body),
                      _buildBottomNav(context, store, palette, s),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    ReloStore store,
    ReloPalette palette,
  ) {
    final user = store.user;
    return SizedBox(
      height: kReloTopBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: 'ReLo 홈 화면으로 이동 (단축키 Alt+1)',
              child: GestureDetector(
                onTap: () => store.navigateToTab(0),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const ReloLogoMark(size: kReloLogoSize),
                    const SizedBox(width: 9),
                    Text(
                      'ReLo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Semantics(
              button: true,
              label: user != null ? '${user.name}님 계정 설정 열기' : '로그인 및 회원가입 열기',
              child: GestureDetector(
                onTap: onUserTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: user != null
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name.substring(0, 1)
                              : 'R',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.body,
                          ),
                        )
                      : Icon(Icons.person_outline_rounded,
                          size: 18, color: palette.body),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    ReloStore store,
    ReloPalette palette,
    ReloStrings s,
  ) {
    // 약관·정책(탭 3)은 설정 안에서 열리므로 설정 탭을 켜진 상태로 보여 준다
    final active = store.activeTabIndex == 3 ? 4 : store.activeTabIndex;
    final activeColor =
        palette.isDark ? const Color(0xFFF8FAFC) : palette.brand;

    Widget item(int index, IconData icon, String label) {
      final on = active == index;
      final color = on ? activeColor : palette.subtle;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: '$label 탭 (단축키 Alt+${index + 1})',
          child: InkWell(
            onTap: () => store.navigateToTab(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: on ? 1.0 : 0.92,
                  duration: ReloMotion.press,
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: palette.isDark ? const Color(0xFF111A2E) : palette.surface,
      ),
      child: Row(
        children: [
          item(0, Icons.home_rounded, s.navHome),
          item(2, Icons.receipt_long_outlined, s.navClaims),
          Expanded(
            child: Semantics(
              button: true,
              label: '${s.navWizard} (단축키 Alt+2)',
              child: Center(
                child: _AddButton(
                  onTap: () => store.navigateToTab(1),
                  highlighted: active == 1,
                ),
              ),
            ),
          ),
          item(4, Icons.person_outline_rounded, s.navSettings),
        ],
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool highlighted;
  const _AddButton({required this.onTap, required this.highlighted});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? ReloMotion.pressScale : 1.0,
        duration: ReloMotion.press,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.highlighted ? palette.brandHover : palette.brand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.brand.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

/// ReLo 로고 마크 (파란 사각형 + 되돌아오는 고리). 상단 바와 시작 연출에서 같이 쓴다.
class ReloLogoMark extends StatelessWidget {
  final double size;

  /// 0~1. 고리가 그려지는 정도. 1이면 완성된 로고.
  final double ringProgress;

  const ReloLogoMark(
      {super.key, this.size = kReloLogoSize, this.ringProgress = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B7FFF), Color(0xFF1B64DA)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: CustomPaint(painter: ReloBrandMarkPainter(progress: ringProgress)),
    );
  }
}

class ReloBrandMarkPainter extends CustomPainter {
  final double progress;
  ReloBrandMarkPainter({this.progress = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.25, h * 0.56)
      ..cubicTo(w * 0.36, h * 0.25, w * 0.66, h * 0.25, w * 0.74, h * 0.45)
      ..moveTo(w * 0.74, h * 0.52)
      ..cubicTo(w * 0.62, h * 0.76, w * 0.34, h * 0.76, w * 0.26, h * 0.54);

    if (progress >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    // 시작 연출: 고리를 progress만큼만 그린다
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(
          metric.extractPath(0, metric.length * progress.clamp(0, 1)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ReloBrandMarkPainter old) =>
      old.progress != progress;
}
