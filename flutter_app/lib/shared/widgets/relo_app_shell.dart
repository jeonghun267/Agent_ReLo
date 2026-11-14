import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../state/relo_store.dart';
import 'relo_icons.dart';

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
/// @purpose 상단에는 로고 · 대화 기록 · 프로필, 하단에는 홈 · 내 환불 · 설정 세 탭을
///          같은 모양으로 떠 있는 바에 둔다. 신청은 홈 대화에서 시작한다.
///          언어·테마·고대비는 설정 화면에 있고, 약관·정책은 설정 안에서 연다.
///          키보드(Tab, Shift+Tab, Enter, Alt+1~5)만으로도 모든 화면을 이동할 수 있다.
class ReloAppShell extends StatelessWidget {
  final Widget body;
  final VoidCallback onUserTap;
  final VoidCallback onHistoryTap;

  const ReloAppShell({
    super.key,
    required this.body,
    required this.onUserTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = ReloScope.of(context);
    final palette = ReloPalette.of(context);
    final s = store.strings;

    // 저장소가 남긴 한 줄 알림(공유받은 파일을 붙이지 못했을 때 등)을 화면 아래에 한 번 보여 준다
    if (store.pendingNotice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final text = store.takePendingNotice();
        if (text == null || !context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      });
    }

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
                      _buildTopBar(context, store, palette, s),
                      // 서버에 붙는 중이거나 붙지 못했으면 한 줄로 알린다.
                      // (붙지 못해도 앱은 체험 데이터로 돌아가므로, 알리지 않으면 저장된 줄 안다)
                      if (store.isLoading || store.isOfflineFallback)
                        _ConnectionNotice(
                          connecting: store.isLoading,
                          onRetry: store.bootstrap,
                        ),
                      Expanded(child: body),
                      // 글자를 칠 때는 탭 바를 내려서 대화가 보이는 자리를 넓힌다
                      if (MediaQuery.viewInsetsOf(context).bottom == 0)
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
    ReloStrings s,
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
              label: s.shHomeLabel,
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
            const Spacer(),
            IconButton(
              tooltip: s.assistantHistory,
              onPressed: onHistoryTap,
              visualDensity: VisualDensity.compact,
              icon: Icon(ReloIcons.history, size: 22, color: palette.muted),
            ),
            const SizedBox(width: 6),
            Semantics(
              button: true,
              label: user != null ? s.shAccount(user.name) : s.shLogin,
              child: GestureDetector(
                onTap: onUserTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.raised,
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
                      : Icon(ReloIcons.person,
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
    // 신청(탭 1)은 홈 대화에서 시작하므로 홈을, 약관·정책(탭 3)은 설정 안에서
    // 열리므로 설정을 켜진 상태로 보여 준다
    final active = switch (store.activeTabIndex) {
      1 => 0,
      3 => 4,
      final i => i,
    };
    final activeColor =
        palette.isDark ? const Color(0xFFF8FAFC) : palette.brand;
    // 면은 밝기 차이로 구분한다: 바는 한 단계, 켜진 칸은 한 단계 더
    final barColor = palette.raised;
    final onColor = palette.isDark ? palette.surfaceElevated : palette.surface;

    Widget item(int index, IconData icon, String label) {
      final on = active == index;
      final color = on ? activeColor : palette.subtle;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: s.shTab(label, index + 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => store.navigateToTab(index),
              child: AnimatedContainer(
                duration: ReloMotion.tabSwitch,
                curve: ReloMotion.enter,
                decoration: BoxDecoration(
                  color: on ? onColor : onColor.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22, color: color),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        color: color,
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

    // 세 칸 모두 같은 모양(선 아이콘 + 이름). 켜진 칸은 그림을 바꾸지 않고 색과 밝은 면으로만 알린다.
    // 화면 가장자리에서 띄운 둥근 바 하나에 담는다.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            item(0, ReloIcons.chat, s.navHome),
            item(2, ReloIcons.receipt, s.navClaims),
            item(4, ReloIcons.person, s.navSettings),
          ],
        ),
      ),
    );
  }
}

/// 서버 연결 상태 한 줄 (상단 바 바로 아래). 붙는 중이면 그렇게 말하고, 붙지 못했으면
/// 지금 보이는 것이 이 기기에만 있는 체험 데이터라는 것과 다시 연결하는 길을 알려 준다.
class _ConnectionNotice extends StatelessWidget {
  final bool connecting;
  final VoidCallback onRetry;
  const _ConnectionNotice({required this.connecting, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    final s = ReloScope.of(context).strings;
    final text = connecting ? s.connConnecting : s.connOffline;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 14, 6),
        child: Row(
          children: [
            Icon(
              connecting ? ReloIcons.clock : ReloIcons.offline,
              size: 14,
              color: palette.subtle,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: palette.subtle),
              ),
            ),
            if (!connecting)
              InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    s.connRetry,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.focusRing,
                    ),
                  ),
                ),
              ),
          ],
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
