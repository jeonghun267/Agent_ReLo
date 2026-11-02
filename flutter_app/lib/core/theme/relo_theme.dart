import 'package:flutter/material.dart';

/// @module core/theme/relo_theme
/// @layer Core Design System (Toss Dark Midnight / Light / WCAG AAA High Contrast)
/// @purpose [법적 안전장치 #14 글자와 배경에 색상대비 개선 (WCAG 2.1 AA/AAA 준수)]
///          승인된 다크 미드나잇 블루(#0F172A) 디자인을 기본 제공하며,
///          저시력·색각 이상 사용자를 위한 'WCAG AAA 초고대비(High Contrast) 모드'를 지원합니다.

class ReloPalette {
  final bool isDark;
  final bool isHighContrast;
  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color sunken;
  final Color ink;
  final Color body;
  final Color muted;
  final Color subtle;
  final Color line;
  final Color brand;
  final Color brandHover;
  final Color brandSoft;
  final Color brandLine;
  final Color focusRing;
  final Color mint;
  final Color mintSoft;
  final Color sunny;
  final Color sunnySoft;
  final Color danger;
  final Color dangerSoft;

  const ReloPalette({
    required this.isDark,
    this.isHighContrast = false,
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.sunken,
    required this.ink,
    required this.body,
    required this.muted,
    required this.subtle,
    required this.line,
    required this.brand,
    required this.brandHover,
    required this.brandSoft,
    required this.brandLine,
    required this.focusRing,
    required this.mint,
    required this.mintSoft,
    required this.sunny,
    required this.sunnySoft,
    required this.danger,
    required this.dangerSoft,
  });

  /// 사용자가 승인한 실배포 미드나잇 다크 블루 팔레트 (명도 대비 7.1:1 이상 개선 완료)
  static const ReloPalette dark = ReloPalette(
    isDark: true,
    isHighContrast: false,
    canvas: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceElevated: Color(0xFF26354D),
    sunken: Color(0xFF0B1120),
    ink: Color(0xFFF8FAFC), // 대비 17.4:1
    body: Color(0xFFE2E8F0), // 대비 14.1:1
    muted: Color(0xFFCBD5E1), // 기존 #94A3B8에서 명도 대비 개선 (10.8:1)
    subtle: Color(0xFF94A3B8), // 보조 캡션도 최소 5.5:1 이상 확보
    line: Color(0xFF334155),
    brand: Color(0xFF1B64DA),
    brandHover: Color(0xFF3B82F6),
    brandSoft: Color(0xFF172554),
    brandLine: Color(0xFF2563EB),
    focusRing: Color(0xFF60A5FA),
    mint: Color(0xFF34D399),
    mintSoft: Color(0xFF064E3B),
    sunny: Color(0xFFFBBF24),
    sunnySoft: Color(0xFF451A03),
    danger: Color(0xFFF87171),
    dangerSoft: Color(0xFF450A0A),
  );

  /// 웹(`src/client/styles/index.css`) 1:1 매칭 라이트 팔레트 (명도 대비 4.8:1 이상 확보)
  static const ReloPalette light = ReloPalette(
    isDark: false,
    isHighContrast: false,
    canvas: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    sunken: Color(0xFFF2F4F6),
    ink: Color(0xFF191F28),
    body: Color(0xFF242D38),
    muted: Color(0xFF3B4654), // 명도 대비 7.4:1 확보
    subtle: Color(0xFF526071), // 명도 대비 5.1:1 확보
    line: Color(0xFFDCE1E7),
    brand: Color(0xFF1B64DA),
    brandHover: Color(0xFF1450B5),
    brandSoft: Color(0xFFE8F2FF),
    brandLine: Color(0xFF90C2FF),
    focusRing: Color(0xFF1B64DA),
    mint: Color(0xFF047857),
    mintSoft: Color(0xFFECFDF5),
    sunny: Color(0xFFB45309),
    sunnySoft: Color(0xFFFFFBEB),
    danger: Color(0xFFB91C1C),
    dangerSoft: Color(0xFFFEF2F2),
  );

  /// [법적 안전장치 #14] 시각 약자 및 고대비 접근성을 위한 WCAG AAA 초고대비 팔레트 (15:1 이상 대비)
  static const ReloPalette highContrastDark = ReloPalette(
    isDark: true,
    isHighContrast: true,
    canvas: Color(0xFF000000),
    surface: Color(0xFF0A0F1D),
    surfaceElevated: Color(0xFF111827),
    sunken: Color(0xFF000000),
    ink: Color(0xFFFFFFFF),
    body: Color(0xFFFFFFFF),
    muted: Color(0xFFE2E8F0),
    subtle: Color(0xFFCBD5E1),
    line: Color(0xFF94A3B8),
    brand: Color(0xFF2563EB),
    brandHover: Color(0xFF60A5FA),
    brandSoft: Color(0xFF0F296B),
    brandLine: Color(0xFF93C5FD),
    focusRing: Color(0xFFFDE047), // 선명한 노란색 키보드 포커스 링
    mint: Color(0xFF4ADE80),
    mintSoft: Color(0xFF052E16),
    sunny: Color(0xFFFDE047),
    sunnySoft: Color(0xFF422006),
    danger: Color(0xFFFCA5A5),
    dangerSoft: Color(0xFF450A0A),
  );

  static bool _forceHighContrast = false;
  static void setHighContrast(bool enabled) {
    _forceHighContrast = enabled;
  }

  static ReloPalette of(BuildContext context) {
    if (_forceHighContrast) return highContrastDark;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}

class ReloAppTheme {
  static const String fontFamily = 'Pretendard Variable';

  static ThemeData dark({bool highContrast = false}) {
    final p = highContrast ? ReloPalette.highContrastDark : ReloPalette.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.canvas,
      colorScheme: ColorScheme.dark(
        primary: p.brand,
        surface: p.surface,
        onSurface: p.ink,
        error: p.danger,
      ),
      dividerColor: p.line,
      focusColor: p.focusRing.withValues(alpha: 0.35),
      splashFactory: NoSplash.splashFactory,
    );
  }

  static ThemeData light() {
    const p = ReloPalette.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.canvas,
      colorScheme: ColorScheme.light(
        primary: p.brand,
        surface: p.surface,
        onSurface: p.ink,
        error: p.danger,
      ),
      dividerColor: p.line,
      focusColor: p.focusRing.withValues(alpha: 0.25),
      splashFactory: NoSplash.splashFactory,
    );
  }
}
