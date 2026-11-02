import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/theme/relo_theme.dart';
import '../../features/compliance/cookie_consent_banner.dart';
import '../state/relo_store.dart';

class _SwitchTabIntent extends Intent {
  final int index;
  const _SwitchTabIntent(this.index);
}

/// @module shared/widgets/relo_app_shell
/// @layer Shared Application Shell (Top Bar + Keyboard Navigation + Cookie Banner + 5-Tab Bar)
/// @purpose [법적 안전장치 #5 쿠키동의 배너, #13 대체 텍스트, #14 고대비 토글, #15 키보드 이동(Tab / Alt+1~5)]
///          마우스 없이 키보드(Tab, Shift+Tab, Enter, Alt+1~5)만으로 모든 화면을 이동할 수 있습니다.
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
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      _buildTopBar(context, store, palette),
                      Expanded(child: body),
                      const CookieConsentBanner(),
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
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: palette.canvas.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: palette.line.withValues(alpha: 0.65)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 좌측 ReLo 브랜드 마크 (Semantics 대체 텍스트 포함)
          Semantics(
            button: true,
            label: 'ReLo 홈 화면으로 이동 (단축키 Alt+1)',
            child: GestureDetector(
              onTap: () => store.navigateToTab(0),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2B7FFF), Color(0xFF1B64DA)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: CustomPaint(painter: _ReloBrandMarkPainter()),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'ReLo',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: palette.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 우측 다국어 · 고대비(AAA) · 다크/라이트 · 계정 버튼
          Row(
            children: [
              // 4개국어 스위처
              PopupMenuButton<ReloLocale>(
                tooltip: '언어 선택 (KO/EN/JA/ZH)',
                onSelected: store.setLocale,
                color: palette.surface,
                itemBuilder: (context) => ReloLocale.values
                    .map(
                      (loc) => PopupMenuItem<ReloLocale>(
                        value: loc,
                        child: Text(
                          '${loc.shortLabel} · ${loc.nativeName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: store.locale == loc
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: palette.ink,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: palette.line),
                  ),
                  child: Row(
                    children: [
                      Text(
                        store.locale.shortLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: palette.body,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: palette.muted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // [항목 #14] WCAG AAA 고대비 모드 토글
              Semantics(
                button: true,
                label: store.isHighContrast ? '고대비 모드 끄기' : '시각 약자용 고대비 모드 켜기',
                child: GestureDetector(
                  onTap: store.toggleHighContrast,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: store.isHighContrast
                          ? palette.sunnySoft
                          : palette.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: store.isHighContrast
                            ? palette.sunny
                            : palette.line,
                      ),
                    ),
                    child: Icon(
                      Icons.contrast_rounded,
                      size: 16,
                      color: store.isHighContrast
                          ? palette.sunny
                          : palette.body,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 다크/라이트 테마 토글
              Semantics(
                button: true,
                label: store.isDarkMode ? '라이트 모드로 전환' : '다크 모드로 전환',
                child: GestureDetector(
                  onTap: store.toggleDarkMode,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: palette.line),
                    ),
                    child: Icon(
                      store.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 16,
                      color: palette.body,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 계정/로그인 버튼
              Semantics(
                button: true,
                label: store.user != null
                    ? '${store.user!.name}님 계정 설정 열기'
                    : '로그인 및 회원가입 열기',
                child: GestureDetector(
                  onTap: onUserTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.brandSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: palette.brandLine),
                    ),
                    child: Text(
                      store.user != null ? '${store.user!.name}님' : '로그인',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: palette.isDark
                            ? const Color(0xFF93C5FD)
                            : palette.brand,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    ReloStore store,
    ReloPalette palette,
    ReloStrings s,
  ) {
    final items = [
      (index: 0, icon: Icons.home_rounded, label: s.navHome),
      (index: 1, icon: Icons.add_circle_outline_rounded, label: s.navWizard),
      (index: 2, icon: Icons.description_outlined, label: s.navClaims),
      (index: 3, icon: Icons.gavel_rounded, label: s.navCompliance),
      (index: 4, icon: Icons.person_outline_rounded, label: s.navSettings),
    ];

    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: palette.isDark ? const Color(0xFF131C31) : palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: Row(
        children: items.map((item) {
          final active = store.activeTabIndex == item.index;
          final color = active
              ? (palette.isDark ? const Color(0xFF3B82F6) : palette.brand)
              : palette.muted;

          return Expanded(
            child: Semantics(
              button: true,
              selected: active,
              label: '${item.label} 탭 (단축키 Alt+${item.index + 1})',
              child: InkWell(
                onTap: () => store.navigateToTab(item.index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 21, color: color),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReloBrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.25, h * 0.56)
      ..cubicTo(w * 0.36, h * 0.25, w * 0.66, h * 0.25, w * 0.74, h * 0.45);
    canvas.drawPath(path, paint);

    final returnPath = Path()
      ..moveTo(w * 0.74, h * 0.52)
      ..cubicTo(w * 0.62, h * 0.76, w * 0.34, h * 0.76, w * 0.26, h * 0.54);
    canvas.drawPath(returnPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
