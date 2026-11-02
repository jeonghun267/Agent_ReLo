import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/money_format.dart';

/// @module shared/widgets/relo_primitives
/// @layer Shared Accessible UI Primitives
/// @purpose [법적 안전장치 #13 이미지/버튼 대체 텍스트, #14 고대비 색상 대비, #15 키보드만으로 이동 가능]
///          모든 버튼과 카드는 FocusableActionDetector를 내장하여 Tab/Shift+Tab 포커스 링 표시 및
///          Enter/Space 키보드 실행을 100% 지원합니다.

class ReloButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDanger;
  final bool showTrailingArrow;
  final IconData? icon;
  final double height;
  final String? semanticLabel;

  const ReloButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isDanger = false,
    this.showTrailingArrow = false,
    this.icon,
    this.height = 52,
    this.semanticLabel,
  });

  @override
  State<ReloButton> createState() => _ReloButtonState();
}

class _ReloButtonState extends State<ReloButton> {
  bool _pressed = false;
  bool _focused = false;
  bool _hovered = false;

  void _trigger() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    final disabled = widget.onPressed == null;

    Color bgColor;
    Color textColor;
    Border? border;

    if (widget.isDanger) {
      bgColor = palette.dangerSoft;
      textColor = palette.danger;
      border = Border.all(
        color: _focused ? palette.focusRing : palette.danger.withValues(alpha: 0.5),
        width: _focused ? 2.5 : 1.0,
      );
    } else if (widget.isPrimary) {
      bgColor = _hovered ? palette.brandHover : palette.brand;
      textColor = Colors.white;
      if (_focused) {
        border = Border.all(color: palette.focusRing, width: 2.5);
      }
    } else {
      bgColor = palette.isDark ? const Color(0xFF1E293B) : palette.sunken;
      textColor = palette.ink;
      border = Border.all(
        color: _focused
            ? palette.focusRing
            : (palette.isDark ? const Color(0xFF334155) : palette.line),
        width: _focused ? 2.5 : 1.0,
      );
    }

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel ?? widget.text,
      child: FocusableActionDetector(
        enabled: !disabled,
        mouseCursor: disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _trigger();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: disabled ? null : () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 90),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: disabled ? 0.48 : 1.0,
              child: Container(
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: border,
                  boxShadow: widget.isPrimary && !disabled
                      ? [
                          BoxShadow(
                            color: palette.brand.withValues(alpha: 0.32),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (widget.showTrailingArrow) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: textColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 키보드 포커스(Tab/Enter)를 지원하는 공통 카드 컨테이너
class ReloCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final String? semanticLabel;

  const ReloCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.semanticLabel,
  });

  @override
  State<ReloCard> createState() => _ReloCardState();
}

class _ReloCardState extends State<ReloCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    final card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _focused
              ? palette.focusRing
              : (widget.borderColor ?? palette.line),
          width: _focused ? 2.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      ),
    );
  }
}

enum ReloBadgeTone { brand, mint, sunny, danger, neutral }

class ReloBadge extends StatelessWidget {
  final String label;
  final ReloBadgeTone tone;
  final IconData? icon;

  const ReloBadge({
    super.key,
    required this.label,
    this.tone = ReloBadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);

    late final Color bg;
    late final Color fg;
    switch (tone) {
      case ReloBadgeTone.brand:
        bg = palette.brandSoft;
        fg = palette.isDark ? const Color(0xFF93C5FD) : palette.brand;
        break;
      case ReloBadgeTone.mint:
        bg = palette.mintSoft;
        fg = palette.mint;
        break;
      case ReloBadgeTone.sunny:
        bg = palette.sunnySoft;
        fg = palette.sunny;
        break;
      case ReloBadgeTone.danger:
        bg = palette.dangerSoft;
        fg = palette.danger;
        break;
      case ReloBadgeTone.neutral:
        bg = palette.sunken;
        fg = palette.muted;
        break;
    }

    return Semantics(
      label: '상태 배지: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum MoneySize { sm, md, lg, xl }

class MoneyDisplay extends StatelessWidget {
  final int minorAmount;
  final String currency;
  final MoneySize size;
  final Color? color;

  const MoneyDisplay({
    super.key,
    required this.minorAmount,
    required this.currency,
    this.size = MoneySize.md,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    final parts = MoneyFormat.splitParts(minorAmount, currency);
    final textColor = color ?? palette.ink;

    final (double mainSize, double subSize) = switch (size) {
      MoneySize.sm => (14.0, 11.0),
      MoneySize.md => (17.0, 13.0),
      MoneySize.lg => (22.0, 15.0),
      MoneySize.xl => (28.0, 18.0),
    };

    return Semantics(
      label: '$currency ${MoneyFormat.formatMinor(minorAmount, currency)}',
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: ReloAppTheme.fontFamily,
            color: textColor,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
          children: [
            TextSpan(
              text: parts.symbol,
              style: TextStyle(
                fontSize: subSize,
                fontWeight: FontWeight.w800,
                color: textColor.withValues(alpha: 0.85),
              ),
            ),
            TextSpan(
              text: parts.whole,
              style: TextStyle(fontSize: mainSize),
            ),
            if (parts.fraction.isNotEmpty)
              TextSpan(
                text: parts.fraction,
                style: TextStyle(
                  fontSize: subSize,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.72),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ReloTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const ReloTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: palette.body,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: palette.subtle,
            ),
            filled: true,
            fillColor: palette.sunken,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: palette.focusRing, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}

/// [법적 안전장치 #6 & #9] 다크패턴 없는 양식 동의 체크박스 위젯
/// - 기본 미체크(Unchecked) 상태로 시작하며, 필수/선택 여부를 명확히 분리 표기하고
///   키보드 포커스(Tab/Space)와 전문 열람 링크를 제공합니다.
class ReloConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isRequired;
  final String title;
  final String? subtitle;
  final VoidCallback? onViewDetail;

  const ReloConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.isRequired,
    required this.title,
    this.subtitle,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      checked: value,
      label: '${isRequired ? "[필수]" : "[선택]"} $title',
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? palette.brandSoft.withValues(alpha: 0.65)
              : palette.sunken,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? palette.brandLine : palette.line,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: palette.brand,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!value),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isRequired
                                ? palette.brandSoft
                                : palette.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isRequired ? '필수' : '선택',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isRequired
                                  ? (palette.isDark
                                        ? const Color(0xFF93C5FD)
                                        : palette.brand)
                                  : palette.muted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: palette.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onViewDetail != null)
              TextButton(
                onPressed: onViewDetail,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(48, 28),
                ),
                child: Text(
                  '전문보기',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: palette.brandHover,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConfettiBurstBanner extends StatefulWidget {
  final String title;
  final String subtitle;

  const ConfettiBurstBanner({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<ConfettiBurstBanner> createState() => _ConfettiBurstBannerState();
}

class _ConfettiBurstBannerState extends State<ConfettiBurstBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.brandSoft,
                palette.mintSoft,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.mint.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.body,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
