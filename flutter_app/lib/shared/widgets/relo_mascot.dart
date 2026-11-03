import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ReloMascotMood { idle, thinking, happy }

/// @module shared/widgets/relo_mascot
/// @purpose ReLo 도우미 캐릭터. 로고와 같은 파란 둥근 사각형에 눈과 웃는 입을 그렸다.
///          입은 로고의 되돌아오는 고리 아래쪽 곡선과 같은 모양이다.
///          idle: 3.6초마다 한 번 눈을 깜빡이고 살짝 떠 있다 / thinking: 눈이 위를 보고
///          반짝이가 돈다 / happy: 눈이 ^^ 모양. 모션 줄이기가 켜져 있으면 멈춰 있다.
class ReloMascot extends StatefulWidget {
  final double size;
  final ReloMascotMood mood;
  final bool animate;

  const ReloMascot({
    super.key,
    this.size = 48,
    this.mood = ReloMascotMood.idle,
    this.animate = true,
  });

  @override
  State<ReloMascot> createState() => _ReloMascotState();
}

class _ReloMascotState extends State<ReloMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ReloMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduce) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) => CustomPaint(
          painter: _MascotPainter(t: _loop.value, mood: widget.mood),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  final double t;
  final ReloMascotMood mood;
  _MascotPainter({required this.t, required this.mood});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final wave = math.sin(t * math.pi * 2);

    // 몸통: 반짝이 자리를 남기고 왼쪽 아래에 둔다
    final side = s * 0.86;
    final bob = mood == ReloMascotMood.thinking ? 0.0 : wave * s * 0.025;
    final body = Rect.fromLTWH(0, s - side + bob - s * 0.02, side, side);
    final rrect = RRect.fromRectAndRadius(body, Radius.circular(side * 0.32));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B8BFF), Color(0xFF1B64DA)],
        ).createShader(body),
    );
    // 위쪽 하이라이트
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left + side * 0.14, body.top + side * 0.08,
            side * 0.34, side * 0.1),
        Radius.circular(side * 0.05),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    Offset at(double x, double y) =>
        Offset(body.left + side * x, body.top + side * y);
    final white = Paint()..color = Colors.white;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = side * 0.07;

    // 볼
    final cheek = Paint()
      ..color = const Color(0xFFFF9EBB).withValues(alpha: 0.5);
    canvas.drawCircle(at(0.2, 0.64), side * 0.065, cheek);
    canvas.drawCircle(at(0.8, 0.64), side * 0.065, cheek);

    // 눈
    if (mood == ReloMascotMood.happy) {
      for (final x in [0.34, 0.66]) {
        final p = Path()
          ..moveTo(body.left + side * (x - 0.07), body.top + side * 0.47)
          ..quadraticBezierTo(body.left + side * x, body.top + side * 0.34,
              body.left + side * (x + 0.07), body.top + side * 0.47);
        canvas.drawPath(p, stroke);
      }
    } else {
      // 깜빡임: 한 바퀴의 90~95% 구간에서 눈을 감았다 뜬다
      final blinkT = ((t - 0.9) / 0.05).clamp(0.0, 1.0);
      final open = mood == ReloMascotMood.thinking
          ? 1.0
          : 1 - math.sin(blinkT * math.pi);
      final look = mood == ReloMascotMood.thinking
          ? Offset(side * 0.05, -side * 0.05)
          : Offset.zero;
      for (final x in [0.34, 0.66]) {
        final c = at(x, 0.44) + look;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: c,
              width: side * 0.12,
              height: math.max(side * 0.025, side * 0.18 * open),
            ),
            Radius.circular(side * 0.06),
          ),
          white,
        );
      }
    }

    // 입: 로고 고리의 아래 곡선
    final mouth = Path()
      ..moveTo(body.left + side * 0.36, body.top + side * 0.64)
      ..cubicTo(
        body.left + side * 0.42,
        body.top + side * (mood == ReloMascotMood.thinking ? 0.7 : 0.76),
        body.left + side * 0.58,
        body.top + side * (mood == ReloMascotMood.thinking ? 0.7 : 0.76),
        body.left + side * 0.64,
        body.top + side * 0.64,
      );
    canvas.drawPath(mouth, stroke);

    // 반짝이 (오른쪽 위)
    final twinkle = 0.8 + 0.2 * math.sin(t * math.pi * 4);
    final angle = mood == ReloMascotMood.thinking ? t * math.pi * 2 : 0.0;
    _drawSparkle(
      canvas,
      Offset(s * 0.86, s * 0.14 + bob * 0.5),
      s * 0.13 * twinkle,
      angle,
      const Color(0xFFFFD166),
    );
    _drawSparkle(
      canvas,
      Offset(s * 0.97, s * 0.36 + bob * 0.5),
      s * 0.055 * (1.8 - twinkle),
      angle,
      const Color(0xFF7DD3FC),
    );
  }

  void _drawSparkle(
      Canvas canvas, Offset c, double r, double angle, Color color) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final p = Path()..moveTo(0, -r);
    for (var i = 1; i <= 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final mid = a - math.pi / 4;
      p.quadraticBezierTo(math.cos(mid) * r * 0.18, math.sin(mid) * r * 0.18,
          math.cos(a) * r, math.sin(a) * r);
    }
    canvas.drawPath(p..close(), Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.t != t || old.mood != mood;
}
