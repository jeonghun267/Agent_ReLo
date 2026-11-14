import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ReloMascotMood { idle, thinking, happy }

/// @module shared/widgets/relo_mascot
/// @purpose ReLo 도우미 캐릭터 "말랑이". 로고와 같은 파란 둥근 사각형을 말랑한 입체로 그린다.
///          빛은 왼쪽 위에서 온다: 몸통은 방사형 그라데이션, 위쪽에 번진 하이라이트,
///          아래쪽은 어둡게, 눈은 빛이 맺힌 검은 유리알. 64px 이상이면 바닥 그림자도 그린다.
///
///          늘 하는 움직임 (7.2초 한 바퀴): 살짝 떠 있으면서 몸이 말랑하게 늘었다 줄고,
///          3.6초에 한 번 눈을 깜빡이고, 그다음 3.6초에는 깜빡이는 대신 한쪽 눈으로 윙크한다.
///          thinking: 눈이 위를 보고 반짝이가 돈다 / happy: 눈이 ^^ 모양.
///
///          폴짝 뛰기 (0.7초): 몸을 움츠렸다가 뛰어오르고, 떨어지면서 납작해졌다 돌아온다.
///          뛰는 동안 윙크하고 반짝이가 한 바퀴 돈다. 누를 때([hopOnTap]), 처음 나타날 때
///          ([hopOnAppear]), [hopSignal] 값이 바뀔 때 뛴다.
///
///          기기의 모션 줄이기가 켜져 있으면 모두 멈춘다.
class ReloMascot extends StatefulWidget {
  final double size;
  final ReloMascotMood mood;
  final bool animate;

  /// 파란 카드 위에 올릴 때 true. 바탕에 묻히지 않도록 몸을 한 단계 밝게 그린다.
  final bool onBrand;

  /// 누르면 폴짝 뛴다 (가벼운 진동과 함께)
  final bool hopOnTap;

  /// 처음 나타나고 0.6초 뒤에 한 번 뛴다 (인사)
  final bool hopOnAppear;

  /// 이 값이 바뀌면 한 번 뛴다. 예: 도우미의 답이 도착한 횟수
  final Object? hopSignal;

  const ReloMascot({
    super.key,
    this.size = 48,
    this.mood = ReloMascotMood.idle,
    this.animate = true,
    this.onBrand = false,
    this.hopOnTap = false,
    this.hopOnAppear = false,
    this.hopSignal,
  });

  @override
  State<ReloMascot> createState() => _ReloMascotState();
}

class _ReloMascotState extends State<ReloMascot> with TickerProviderStateMixin {
  static const _hopDuration = Duration(milliseconds: 700);

  /// 인사로 뛸 때는 0.6초 기다렸다가 뛴다. 타이머 대신 0 아래 구간을 기다림으로 쓴다.
  static const double _appearLead = -0.86;

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7200),
  );

  /// 0~1이 뛰는 한 번. 0 이하는 가만히 있는 상태.
  late final AnimationController _hop = AnimationController(
    vsync: this,
    lowerBound: _appearLead,
    upperBound: 1,
    value: 0,
    duration: _hopDuration,
  );

  bool _greeted = false;

  bool get _still =>
      !widget.animate ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
    if (widget.hopOnAppear && !_greeted) {
      _greeted = true;
      if (!_still) {
        _hop.value = _appearLead;
        _hop.animateTo(1,
            duration: const Duration(milliseconds: 1300), curve: Curves.linear);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ReloMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
    if (widget.hopSignal != oldWidget.hopSignal) _playHop();
  }

  void _sync() {
    if (_still) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  void _playHop() {
    if (_still) return;
    // forward()는 전체 구간(-0.86~1) 기준으로 시간을 나누므로, 0에서 1까지 걸리는 시간을 직접 준다
    _hop.value = 0;
    _hop.animateTo(1, duration: _hopDuration, curve: Curves.linear);
  }

  @override
  void dispose() {
    _loop.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_loop, _hop]),
        builder: (context, _) => CustomPaint(
          painter: _MascotPainter(
            t: _loop.value,
            hop: _hop.value.clamp(0.0, 1.0),
            mood: widget.mood,
            onBrand: widget.onBrand,
          ),
        ),
      ),
    );
    if (!widget.hopOnTap) return face;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _playHop();
      },
      child: face,
    );
  }
}

class _MascotPainter extends CustomPainter {
  /// 늘 하는 움직임의 진행 (0~1 = 7.2초)
  final double t;

  /// 폴짝 뛰기의 진행 (0이면 가만히, 0~1 = 0.7초)
  final double hop;
  final ReloMascotMood mood;
  final bool onBrand;
  _MascotPainter({
    required this.t,
    required this.mood,
    this.hop = 0,
    this.onBrand = false,
  });

  /// a에서 b까지 가는 동안 0 → 1 → 0으로 부풀었다 꺼지는 값
  static double _swell(double x, double a, double b) =>
      math.sin(math.pi * ((x - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // 3.6초짜리 박자 두 번이 한 바퀴. 첫 박자는 깜빡임, 둘째 박자는 윙크.
    final beat = (t * 2) % 1;
    final winkBeat = (t * 2).floor() == 1;
    final wave = math.sin(beat * math.pi * 2);
    final hopping = hop > 0 && hop < 1;
    // 작게 쓸 때(채팅 속, 목록)는 바닥 그림자를 빼서 얼굴을 크게 보여 준다
    final grounded = s >= 64;

    // 뛰기: 0~0.16 움츠림 → 0.16~0.82 공중 → 0.82~1 내려앉으며 납작
    final air = hopping ? _swell(hop, 0.16, 0.82) : 0.0;
    final jump = air * s * 0.2;
    var stretchY = 1.0;
    if (hopping) {
      stretchY = 1 -
          0.14 * _swell(hop, 0, 0.16) +
          0.09 * _swell(hop, 0.16, 0.66) -
          0.12 * _swell(hop, 0.82, 1);
    } else if (mood != ReloMascotMood.thinking) {
      // 말랑하게: 떠오를 때 살짝 늘고 내려올 때 살짝 줄어든다
      stretchY = 1 - wave * 0.018;
    }
    final stretchX = 1 + (1 - stretchY) * 0.6;

    // 몸통: 반짝이 자리를 남기고 왼쪽 아래에 둔다
    final side = s * (grounded ? 0.8 : 0.86);
    final floor = s * (grounded ? 0.07 : 0.02);
    final bob = (hopping || mood == ReloMascotMood.thinking)
        ? 0.0
        : wave * s * 0.03;
    final body = Rect.fromLTWH(0, s - side - floor + bob, side, side);
    final rrect = RRect.fromRectAndRadius(body, Radius.circular(side * 0.34));

    if (grounded) {
      // 바닥 그림자: 높이 뜰수록 작고 옅어진다
      final lift = air + (hopping ? 0 : -wave * 0.12);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side / 2, s - s * 0.035),
          width: side * (0.84 - 0.3 * lift),
          height: s * 0.07 * (1 - 0.35 * lift),
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.38 - 0.2 * lift)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03),
      );
    }

    // 여기부터 몸과 얼굴은 발밑을 기준으로 뛰고 늘어난다
    canvas.save();
    canvas.translate(body.center.dx, body.bottom - jump);
    canvas.scale(stretchX, stretchY);
    canvas.translate(-body.center.dx, -body.bottom);

    // 말랑한 몸: 왼쪽 위가 밝고 오른쪽 아래로 갈수록 짙어진다
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.48),
          radius: 0.88,
          colors: onBrand
              ? const [Color(0xFFB9D8FF), Color(0xFF5E9BF7), Color(0xFF2A66D4)]
              : const [Color(0xFF86BBFF), Color(0xFF2F78EE), Color(0xFF0F45A6)],
          stops: const [0, 0.42, 1],
        ).createShader(body),
    );
    canvas.save();
    canvas.clipRRect(rrect);
    // 아래쪽 그늘
    canvas.drawRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0x00041A4D),
            Color(onBrand ? 0x59041A4D : 0x80041A4D),
          ],
          stops: const [0.5, 1],
        ).createShader(body),
    );
    // 위쪽에 번진 하이라이트
    canvas.save();
    canvas.translate(body.left + side * 0.35, body.top + side * 0.19);
    canvas.rotate(-0.17);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero, width: side * 0.56, height: side * 0.18),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.04),
    );
    canvas.restore();
    canvas.restore();

    Offset at(double x, double y) =>
        Offset(body.left + side * x, body.top + side * y);
    const inkColor = Color(0xFF0A1020);
    final ink = Paint()..color = inkColor;
    final stroke = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = side * 0.035;

    // 볼
    final cheek = Paint()
      ..color = const Color(0xFFFF8FB3).withValues(alpha: 0.55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.02);
    canvas.drawCircle(at(0.22, 0.65), side * 0.07, cheek);
    canvas.drawCircle(at(0.78, 0.65), side * 0.07, cheek);

    // 눈: 감은 눈은 ^ 모양으로 그린다 (happy는 두 눈 다, 윙크는 오른쪽 눈만)
    void closedEye(double x) {
      final p = Path()
        ..moveTo(body.left + side * (x - 0.07), body.top + side * 0.53)
        ..quadraticBezierTo(body.left + side * x, body.top + side * 0.4,
            body.left + side * (x + 0.07), body.top + side * 0.53);
      canvas.drawPath(p, stroke);
    }

    void openEye(double x, double open, Offset look) {
      final c = at(x, 0.5) + look;
      canvas.drawOval(
        Rect.fromCenter(
          center: c,
          width: side * 0.11,
          height: math.max(side * 0.02, side * 0.152 * open),
        ),
        ink,
      );
      if (open > 0.6) {
        // 눈에 맺힌 빛
        canvas.drawCircle(c + Offset(side * 0.018, -side * 0.033),
            side * 0.022, Paint()..color = Colors.white);
        canvas.drawCircle(c + Offset(-side * 0.018, side * 0.03),
            side * 0.01, Paint()..color = Colors.white.withValues(alpha: 0.45));
      }
    }

    // 윙크: 뛰는 동안, 그리고 둘째 박자의 끝(84~98%)에
    final winking = hopping
        ? hop > 0.12 && hop < 0.86
        : (winkBeat && mood == ReloMascotMood.idle && beat > 0.84 && beat < 0.98);

    if (mood == ReloMascotMood.happy) {
      closedEye(0.34);
      closedEye(0.66);
    } else {
      // 깜빡임: 첫 박자의 90~95% 구간에서 눈을 감았다 뜬다
      final blinkT = ((beat - 0.9) / 0.05).clamp(0.0, 1.0);
      final open =
          (mood == ReloMascotMood.thinking || winkBeat || hopping)
              ? 1.0
              : 1 - math.sin(blinkT * math.pi);
      final look = mood == ReloMascotMood.thinking
          ? Offset(side * 0.03, -side * 0.04)
          : Offset.zero;
      openEye(0.34, open, look);
      if (winking) {
        closedEye(0.66);
      } else {
        openEye(0.66, open, look);
      }
    }

    // 입: 로고 고리의 아래 곡선. 윙크하거나 기쁠 때 더 크게 웃는다
    final dip = mood == ReloMascotMood.thinking
        ? 0.69
        : (winking || mood == ReloMascotMood.happy)
            ? 0.775
            : 0.745;
    final mouth = Path()
      ..moveTo(body.left + side * 0.42, body.top + side * 0.665)
      ..quadraticBezierTo(body.left + side * 0.5, body.top + side * dip,
          body.left + side * 0.58, body.top + side * 0.665);
    canvas.drawPath(mouth, stroke);

    canvas.restore();

    // 반짝이 (오른쪽 위): 평소엔 반짝이고, 생각할 땐 돌고, 뛸 땐 같이 뛰면서 한 바퀴 돈다
    final twinkle = 0.85 + 0.15 * math.sin(beat * math.pi * 4);
    final angle = hopping
        ? hop * math.pi * 2
        : (mood == ReloMascotMood.thinking ? beat * math.pi * 2 : 0.0);
    _drawSparkle(
      canvas,
      Offset(s * 0.87, s * 0.13 + bob * 0.5 - jump * 0.55),
      s * 0.125 * twinkle * (1 + 0.35 * air),
      angle,
    );
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, double angle) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final p = Path()..moveTo(0, -r);
    for (var i = 1; i <= 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final mid = a - math.pi / 4;
      p.quadraticBezierTo(math.cos(mid) * r * 0.2, math.sin(mid) * r * 0.2,
          math.cos(a) * r, math.sin(a) * r);
    }
    final bounds = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawPath(
      p..close(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE08A), Color(0xFFF5A300)],
        ).createShader(bounds),
    );
    canvas.drawCircle(Offset(-r * 0.12, -r * 0.14), r * 0.14,
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) =>
      old.t != t ||
      old.hop != hop ||
      old.mood != mood ||
      old.onBrand != onBrand;
}
