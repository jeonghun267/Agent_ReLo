import 'dart:math' as math;
import 'package:flutter/material.dart';

/// @module shared/widgets/relo_orb_emblem
/// @layer Shared UI Widget (3D Blue Glowing Orb Emblem with Accessibility Alt Text)
/// @purpose [법적 안전장치 #13 접근성을 위한 이미지 대체 텍스트 추가 & #19 자체 제작 그래픽 저작권 확보]
///          스크린 리더(TalkBack/VoiceOver)를 위한 Semantics 대체 텍스트를 내장하며,
///          외부 유료/무단 이미지 없이 100% 자체 CustomPainter 벡터로 구현되어 저작권 분쟁 위험이 없습니다.
class ReloOrbEmblem extends StatefulWidget {
  final double size;
  final String? speech;
  final String semanticLabel;

  const ReloOrbEmblem({
    super.key,
    this.size = 84,
    this.speech,
    this.semanticLabel = 'ReLo 3D 블루 글로우 오브 브랜드 엠블럼 — 해외직구 반품 및 환불 항공 궤적 그래픽',
  });

  @override
  State<ReloOrbEmblem> createState() => _ReloOrbEmblemState();
}

class _ReloOrbEmblemState extends State<ReloOrbEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.speech != null
          ? '${widget.semanticLabel}. 안내 문구: ${widget.speech}'
          : widget.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final dy = math.sin(_controller.value * math.pi) * 3.0;
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.28, -0.32),
                      radius: 0.92,
                      colors: [
                        Color(0xFF60A5FA),
                        Color(0xFF2563EB),
                        Color(0xFF1D4ED8),
                      ],
                      stops: [0.0, 0.58, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                        blurRadius: widget.size * 0.36,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: OrbFlightPainter(progress: _controller.value),
                  ),
                ),
              );
            },
          ),
          if (widget.speech != null && widget.speech!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                widget.speech!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrbFlightPainter extends CustomPainter {
  final double progress;
  const OrbFlightPainter({this.progress = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final highlightPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(w * 0.34, h * 0.28),
          radius: w * 0.32,
        ),
      );
    canvas.drawCircle(Offset(w * 0.34, h * 0.28), w * 0.32, highlightPaint);

    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.042
      ..strokeCap = StrokeCap.round;

    final start = Offset(w * 0.33, h * 0.55);
    final control = Offset(w * 0.48, h * 0.38);
    final end = Offset(w * 0.61, h * 0.45);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

    canvas.drawPath(path, arcPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(end, w * 0.048, dotPaint);
  }

  @override
  bool shouldRepaint(covariant OrbFlightPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
