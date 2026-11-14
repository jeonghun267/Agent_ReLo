import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/motion_tokens.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/dday.dart';
import '../../core/utils/money_format.dart';
import 'relo_mascot.dart';
import 'relo_icons.dart';

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
        color: _focused
            ? palette.focusRing
            : palette.danger.withValues(alpha: 0.5),
        width: _focused ? 2.5 : 1.0,
      );
    } else if (widget.isPrimary) {
      bgColor = _hovered ? palette.brandHover : palette.brand;
      textColor = Colors.white;
      if (_focused) {
        border = Border.all(color: palette.focusRing, width: 2.5);
      }
    } else {
      // 보조 버튼은 테두리 없이 밝기 차이로만 구분한다 (DESIGN.md 2절)
      bgColor = _hovered
          ? (palette.isDark ? palette.surfaceElevated : palette.line)
          : palette.raised;
      textColor = palette.ink;
      if (_focused) {
        border = Border.all(color: palette.focusRing, width: 2.5);
      }
    }

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel ?? widget.text,
      child: FocusableActionDetector(
        enabled: !disabled,
        mouseCursor:
            disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
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
          onTapDown: disabled
              ? null
              : (_) {
                  HapticFeedback.lightImpact();
                  setState(() => _pressed = true);
                },
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTapCancel: disabled ? null : () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? ReloMotion.pressScale : 1.0,
            duration: ReloMotion.press,
            curve: ReloMotion.enter,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: disabled ? 0.48 : 1.0,
              child: Container(
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
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
                        ReloIcons.forward,
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
    this.padding = const EdgeInsets.all(16),
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
    // 카드는 테두리 없이 면 색으로만 구분한다. 테두리는 키보드 포커스 링과
    // 호출자가 명시한 경우에만 그린다 (DESIGN.md 2절).
    final card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: _focused
            ? Border.all(color: palette.focusRing, width: 2.2)
            : (widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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

/// 배지 색은 파랑·회색·빨강(오류) 셋만 쓴다. 초록·주황 알약은 쓰지 않는다 (DESIGN.md 2절).
/// 약속 → 입금 막대. 판매자가 약속한 몫은 옅은 파랑, 실제로 들어온 몫은 진한 파랑.
/// 두 값은 요청 금액 대비 비율(0~1)이다.
class ReloProgressBar extends StatelessWidget {
  final double promised;
  final double cash;
  final double height;

  /// 빈 부분의 색. 카드 안에서는 기본값(움푹한 면), 바탕 위에 바로 놓을 때는 카드 색을 준다.
  final Color? trackColor;
  const ReloProgressBar({
    super.key,
    required this.promised,
    required this.cash,
    this.height = 8,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: trackColor ?? palette.sunken),
            ),
            // heightFactor가 없으면 Stack 안에서 높이 0으로 접혀 막대가 안 보인다
            FractionallySizedBox(
              widthFactor: promised.clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(
                  color: palette.brandHover.withValues(alpha: 0.4)),
            ),
            FractionallySizedBox(
              widthFactor: cash.clamp(0.0, 1.0),
              heightFactor: 1,
              child: ColoredBox(color: palette.brandHover),
            ),
          ],
        ),
      ),
    );
  }
}

/// 마감까지 남은 날을 배지 없이 글자로 보여 준다. 마감이 지났을 때만 빨강.
class ReloDdayText extends StatelessWidget {
  final String? deadline;
  final double fontSize;
  const ReloDdayText({super.key, required this.deadline, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final label = DDay.label(deadline);
    if (label == null) return const SizedBox.shrink();
    final palette = ReloPalette.of(context);
    final overdue = (DDay.daysLeft(deadline) ?? 0) < 0;
    return Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: overdue ? palette.danger : palette.ink,
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

  /// 날짜처럼 직접 치지 않고 고르는 칸 (onTap으로 고르는 창을 연다)
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  /// 칸의 면 색. 카드 안에서는 기본값(움푹한 면), 바탕 위에 바로 놓을 때는 카드 색을 준다.
  final Color? fillColor;

  const ReloTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.trailingIcon,
    this.fillColor,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
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
            fillColor: fillColor ?? palette.sunken,
            suffixIcon: trailingIcon == null
                ? null
                : Icon(trailingIcon, size: 18, color: palette.muted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            // 테두리는 포커스 때만 (DESIGN.md 2절: 면은 밝기 차이로 구분)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.focusRing, width: 2.0),
            ),
          ),
        ),
      ],
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
            color: palette.raised,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  ReloIcons.check,
                  color: Colors.white,
                  size: 22,
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

/// 글자만 있는 탭·필터 칸. 고른 칸은 굵은 글자와 밑줄로 알린다 (색칠한 알약을 쓰지 않는다).
/// 내 환불의 필터와 상세 화면의 탭이 같이 쓴다.
class ReloTextTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ReloTextTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: AnimatedContainer(
            duration: ReloMotion.press,
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: selected
                      ? palette.ink
                      : palette.ink.withValues(alpha: 0),
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? palette.ink : palette.subtle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 화면 아래에 고정된 "ReLo에게 물어보기" 칸. 누르면 도우미 대화가 아래에서 올라온다.
/// 내 환불과 상세 화면이 같이 쓴다 (이 두 화면에서는 떠 있는 도우미 대신).
class ReloAskBar extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const ReloAskBar({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: palette.raised,
          borderRadius: BorderRadius.circular(26),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const ReloMascot(size: 32, animate: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 15, color: palette.subtle),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.inset,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(ReloIcons.send,
                        size: 20, color: palette.subtle),
                  ),
                  const SizedBox(width: 7),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 구역 제목 오른쪽의 글자 버튼 ("AI로 쓰기" · "보기"). 버튼 면을 만들지 않고 강조색 글자로만 둔다.
/// 상세와 신청 화면이 같이 쓴다.
class ReloTextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const ReloTextAction({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: onTap == null ? palette.subtle : palette.focusRing,
            ),
          ),
        ),
      ),
    );
  }
}

/// 하나만 고르는 칩 (쇼핑몰 · 통화 · 해결 방법 · 답장 종류). 홈의 고르는 말과 같은 테두리 알약이고,
/// 고른 것은 밝은 테두리와 굵은 글자로 알린다 (파랗게 칠하지 않는다).
class ReloChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ReloChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: ReloMotion.press,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? palette.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              width: 1.4,
              color: selected ? palette.ink : palette.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? palette.ink : palette.body,
            ),
          ),
        ),
      ),
    );
  }
}

/// 상자 없이 아래 가는 선으로만 나눈 한 줄. 설정 · 약관 · 로그인 화면의 줄이 같이 쓴다.
class ReloHairline extends StatelessWidget {
  final Widget child;
  final double vertical;
  const ReloHairline({super.key, required this.child, this.vertical = 14});

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: palette.line.withValues(alpha: 0.5)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: vertical),
        child: child,
      ),
    );
  }
}

/// 켜고 끄는 줄: 이름 + (한 줄 설명) + 스위치. 줄 어디를 눌러도 바뀐다.
/// 스위치는 켜짐 = 파란 면에 흰 손잡이, 꺼짐 = 회색 면에 흰 손잡이 (테두리 없음).
class ReloSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ReloSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ReloPalette.of(context);
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ReloHairline(
          vertical: 12,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.subtle,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: palette.brand,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: palette.line,
                trackOutlineColor:
                    const WidgetStatePropertyAll(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 동의 한 줄 (상자 없이). 기본은 체크하지 않은 상태로 두고, 필수인지 선택인지 글자로 적고,
/// 전문을 볼 수 있으면 "보기"를 옆에 둔다. [법적 안전장치 #6 · #9 · #17]
/// 신청 · 회원가입 · 내 정보 삭제가 같이 쓴다.
class ReloConsentRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isRequired;
  final String title;
  final String? subtitle;
  final VoidCallback? onViewDetail;

  const ReloConsentRow({
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
    final p = ReloPalette.of(context);
    final tag = isRequired ? '필수' : '선택';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            checked: value,
            label: subtitle == null
                ? '[$tag] $title'
                : '[$tag] $title. $subtitle',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onChanged(!value),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: value,
                        activeColor: p.brand,
                        side: BorderSide(color: p.subtle, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (v) => onChanged(v ?? false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: title,
                              children: [
                                TextSpan(
                                  text: '  $tag',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: p.subtle,
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: p.ink,
                              height: 1.4,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: p.subtle,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onViewDetail != null)
          ReloTextAction(label: '보기', onTap: onViewDetail),
      ],
    );
  }
}
