import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/relo_theme.dart';
import '../models/domain_models.dart';
import 'refund_globe_data.dart';

/// @module shared/widgets/refund_globe
/// @purpose 웹 랜딩의 지구본(globeCanvasRenderer.ts)을 Dart Canvas로 옮긴 위젯.
///          해외 쇼핑몰 도시에서 서울로 비행기가 날아오는 궤적을 그린다.
///          홈에서는 배경(ambient)으로, 신청 완료 화면에서는 단독으로 쓴다.

/// 쇼핑몰(출발지) 하나
class GlobeCorridor {
  final String id;
  final String city;
  final double lat;
  final double lon;

  const GlobeCorridor({
    required this.id,
    required this.city,
    required this.lat,
    required this.lon,
  });

  /// 쇼핑몰 이름 → 출발 도시. 이름으로 못 찾으면 통화로 추정한다.
  static GlobeCorridor fromClaim(ClaimView claim) {
    final v = claim.vendor.toLowerCase();
    if (v.contains('mercari') ||
        v.contains('amazon jp') ||
        v.contains('rakuten')) {
      return _tokyo(claim.id);
    }
    if (v.contains('ali') ||
        v.contains('taobao') ||
        v.contains('1688') ||
        v.contains('temu')) {
      return _shenzhen(claim.id);
    }
    if (v.contains('farfetch') || v.contains('ssense') || v.contains('asos')) {
      return _london(claim.id);
    }
    if (v.contains('iherb') || v.contains('ebay')) {
      return GlobeCorridor(
          id: claim.id, city: 'Los Angeles', lat: 34.0522, lon: -118.2437);
    }
    if (v.contains('amazon')) {
      return _seattle(claim.id);
    }
    return switch (claim.currency) {
      'JPY' => _tokyo(claim.id),
      'CNY' => _shenzhen(claim.id),
      'EUR' || 'GBP' => _london(claim.id),
      'CAD' => GlobeCorridor(
          id: claim.id, city: 'Toronto', lat: 43.6532, lon: -79.3832),
      'AUD' => GlobeCorridor(
          id: claim.id, city: 'Sydney', lat: -33.8688, lon: 151.2093),
      _ => _seattle(claim.id),
    };
  }

  static GlobeCorridor _seattle(String id) =>
      GlobeCorridor(id: id, city: 'Seattle', lat: 47.6062, lon: -122.3321);
  static GlobeCorridor _tokyo(String id) =>
      GlobeCorridor(id: id, city: 'Tokyo', lat: 35.6762, lon: 139.6503);
  static GlobeCorridor _shenzhen(String id) =>
      GlobeCorridor(id: id, city: 'Shenzhen', lat: 22.5431, lon: 114.0579);
  static GlobeCorridor _london(String id) =>
      GlobeCorridor(id: id, city: 'London', lat: 51.5072, lon: -0.1276);
}

class RefundGlobe extends StatefulWidget {
  final List<GlobeCorridor> corridors;
  final int activeIndex;
  final String hubLabel;

  /// 배경용. 라벨을 숨기고 전체를 흐리게 그린다.
  final bool ambient;

  /// false면 멈춘 그림만 그린다 (모션 줄이기, 테스트).
  final bool animate;

  /// 서울이 가운데 오는 기본 각도 (휴대폰 세로 화면 기준)
  final double baseYaw;
  final double pitch;
  final double swing;

  const RefundGlobe({
    super.key,
    required this.corridors,
    this.activeIndex = 0,
    this.hubLabel = '서울 · 내 계좌 도착',
    this.ambient = false,
    this.animate = true,
    this.baseYaw = 2.48,
    this.pitch = 0.52,
    this.swing = 0.12,
  });

  @override
  State<RefundGlobe> createState() => _RefundGlobeState();
}

class _RefundGlobeState extends State<RefundGlobe>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      // 웹은 프레임마다 0.0055씩 더한다 (60fps ≈ 0.33/s)
      setState(() => _phase = elapsed.inMicroseconds / 1e6 * 0.33);
    });
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(covariant RefundGlobe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isActive) _ticker.start();
    if (!widget.animate && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _ticker.isActive) _ticker.stop();

    final yaw = widget.baseYaw + math.sin(_phase * 0.55) * widget.swing;
    return Semantics(
      label: '해외 쇼핑몰에서 서울로 환불이 돌아오는 지구본 그림',
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GlobePainter(
            yaw: yaw,
            pitch: widget.pitch,
            phase: _phase,
            corridors: widget.corridors,
            activeIndex: widget.activeIndex,
            hubLabel: widget.hubLabel,
            ambient: widget.ambient,
            textDirection: Directionality.of(context),
            fontFamily: ReloAppTheme.fontFamily,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

// ── 3D 투영 ─────────────────────────────────────────────────────────────

const double _degToRad = math.pi / 180;

class _Vec3 {
  final double x, y, z;
  const _Vec3(this.x, this.y, this.z);
}

_Vec3 _latLonToUnit(double lat, double lon) {
  final phi = (90 - lat) * _degToRad;
  final theta = (lon + 180) * _degToRad;
  return _Vec3(
    -math.sin(phi) * math.cos(theta),
    math.cos(phi),
    math.sin(phi) * math.sin(theta),
  );
}

_Vec3 _rotate(_Vec3 p, double yaw, double pitch) {
  final cosY = math.cos(yaw), sinY = math.sin(yaw);
  final x1 = p.x * cosY + p.z * sinY;
  final z1 = -p.x * sinY + p.z * cosY;
  final cosP = math.cos(pitch), sinP = math.sin(pitch);
  return _Vec3(x1, p.y * cosP - z1 * sinP, p.y * sinP + z1 * cosP);
}

/// 두 점 사이 대권 경로. 가운데가 살짝 떠오른다 (비행 궤적).
_Vec3 _slerpElevated(_Vec3 a, _Vec3 b, double t, double maxLift) {
  final dot = (a.x * b.x + a.y * b.y + a.z * b.z).clamp(-1.0, 1.0);
  final omega = math.acos(dot);
  final sinOmega = math.sin(omega);
  double x, y, z;
  if (sinOmega < 0.0005) {
    x = a.x + (b.x - a.x) * t;
    y = a.y + (b.y - a.y) * t;
    z = a.z + (b.z - a.z) * t;
  } else {
    final w1 = math.sin((1 - t) * omega) / sinOmega;
    final w2 = math.sin(t * omega) / sinOmega;
    x = a.x * w1 + b.x * w2;
    y = a.y * w1 + b.y * w2;
    z = a.z * w1 + b.z * w2;
  }
  final lift = 1 + math.sin(math.pi * t) * maxLift;
  return _Vec3(x * lift, y * lift, z * lift);
}

final _Vec3 _seoul = _latLonToUnit(37.5665, 126.978);

/// 해안선을 2.6도 간격으로 쪼개 구에 투영해도 매끄럽게 보이게 한다.
List<List<_Vec3>> _buildRings() {
  return kWorldLandPolygons.map((ring) {
    final out = <_Vec3>[];
    for (var i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];
      final dLon = b[0] - a[0], dLat = b[1] - a[1];
      final steps =
          math.max(1, (math.sqrt(dLon * dLon + dLat * dLat) / 2.6).ceil());
      for (var s = 0; s < steps; s++) {
        final r = s / steps;
        out.add(_latLonToUnit(a[1] + dLat * r, a[0] + dLon * r));
      }
    }
    return out;
  }).toList();
}

bool _pointInRing(double lon, double lat, List<List<double>> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i, i++) {
    final xi = ring[i][0], yi = ring[i][1];
    final xj = ring[j][0], yj = ring[j][1];
    final crosses = (yi > lat) != (yj > lat) &&
        lon < ((xj - xi) * (lat - yi)) / (yj - yi + 1e-9) + xi;
    if (crosses) inside = !inside;
  }
  return inside;
}

List<_Vec3> _buildLandDots() {
  final dots = <_Vec3>[];
  for (var lat = -54.0; lat <= 76; lat += 2.6) {
    final lonStep = 2.6 / math.max(0.32, math.cos(lat.abs() * _degToRad));
    for (var lon = -178.0; lon <= 178; lon += lonStep) {
      if (kWorldLandPolygons.any((r) => _pointInRing(lon, lat, r))) {
        dots.add(_latLonToUnit(lat, lon));
      }
    }
  }
  return dots;
}

final List<List<_Vec3>> _rings = _buildRings();
final List<_Vec3> _landDots = _buildLandDots();

// ── 그리기 ───────────────────────────────────────────────────────────────

class _Projected {
  final double x, y, z;
  const _Projected(this.x, this.y, this.z);
}

class _GlobePainter extends CustomPainter {
  final double yaw, pitch, phase;
  final List<GlobeCorridor> corridors;
  final int activeIndex;
  final String hubLabel;
  final bool ambient;
  final TextDirection textDirection;
  final String fontFamily;

  _GlobePainter({
    required this.yaw,
    required this.pitch,
    required this.phase,
    required this.corridors,
    required this.activeIndex,
    required this.hubLabel,
    required this.ambient,
    required this.textDirection,
    required this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.51;
    final radius = math.min(size.width, size.height) * 0.39;
    final dim = ambient ? 0.55 : 1.0;

    // 1. 바깥 대기 빛
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 1.28,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          radius * 1.28,
          [
            const Color(0xFF3182F6).withValues(alpha: 0.34 * dim),
            const Color(0xFF1B64DA).withValues(alpha: 0.11 * dim),
            const Color(0x00070F20),
          ],
          [0.0, 0.55, 1.0],
        ),
    );

    // 2. 바다
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx - radius * 0.32, cy - radius * 0.34),
          radius,
          const [Color(0xFF1D4587), Color(0xFF0D244D), Color(0xFF061126)],
          [0.08, 0.5, 1.0],
        ),
    );

    // 3. 구 안쪽: 위도선 + 대륙 + 땅 점
    canvas.save();
    canvas.clipPath(Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius)));

    final graticule = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.11 * dim)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;
    for (var lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      var started = false;
      for (var lon = -180; lon <= 180; lon += 6) {
        final r =
            _rotate(_latLonToUnit(lat.toDouble(), lon.toDouble()), yaw, pitch);
        if (r.z > 0) {
          final px = cx + r.x * radius, py = cy - r.y * radius;
          if (!started) {
            path.moveTo(px, py);
            started = true;
          } else {
            path.lineTo(px, py);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, graticule);
    }

    final landFill = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.24 * dim);
    final coast = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.65 * dim)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15;

    for (final ring in _rings) {
      var visible = 0;
      final projected = <_Projected>[];
      for (final v in ring) {
        final r = _rotate(v, yaw, pitch);
        if (r.z > 0) {
          visible++;
          projected.add(_Projected(cx + r.x * radius, cy - r.y * radius, r.z));
        } else {
          final len = math.sqrt(r.x * r.x + r.y * r.y);
          final xy = len == 0 ? 1.0 : len;
          projected.add(_Projected(
              cx + (r.x / xy) * radius, cy - (r.y / xy) * radius, 0));
        }
      }
      if (visible < 2) continue;

      final fill = Path();
      for (var i = 0; i < projected.length; i++) {
        final p = projected[i];
        if (i == 0) {
          fill.moveTo(p.x, p.y);
        } else {
          fill.lineTo(p.x, p.y);
        }
      }
      fill.close();
      canvas.drawPath(fill, landFill);

      final line = Path();
      var drawing = false;
      for (final p in projected) {
        if (p.z > 0.02) {
          if (!drawing) {
            line.moveTo(p.x, p.y);
            drawing = true;
          } else {
            line.lineTo(p.x, p.y);
          }
        } else {
          drawing = false;
        }
      }
      canvas.drawPath(line, coast);
    }

    final dotPaint = Paint();
    for (final dot in _landDots) {
      final r = _rotate(dot, yaw, pitch);
      if (r.z <= 0.04) continue;
      dotPaint.color =
          const Color(0xFFBFDBFE).withValues(alpha: (0.22 + r.z * 0.52) * dim);
      canvas.drawCircle(Offset(cx + r.x * radius, cy - r.y * radius),
          1.15 + r.z * 0.45, dotPaint);
    }
    canvas.restore();

    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = const Color(0xFF93C5FD).withValues(alpha: 0.36 * dim)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    // 4. 비행 궤적 + 비행기
    for (var idx = 0; idx < corridors.length; idx++) {
      final route = corridors[idx];
      final focused = idx == activeIndex;
      final lift = focused ? 0.2 : 0.14;
      final origin = _latLonToUnit(route.lat, route.lon);
      final originRot = _rotate(origin, yaw, pitch);

      const segments = 48;
      final arc = <_Projected>[];
      for (var s = 0; s <= segments; s++) {
        final rot = _rotate(
            _slerpElevated(origin, _seoul, s / segments, lift), yaw, pitch);
        arc.add(_Projected(cx + rot.x * radius, cy - rot.y * radius, rot.z));
      }

      final arcPath = Path();
      var started = false;
      for (final p in arc) {
        if (p.z > -0.18) {
          if (!started) {
            arcPath.moveTo(p.x, p.y);
            started = true;
          } else {
            arcPath.lineTo(p.x, p.y);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(
        arcPath,
        Paint()
          ..color = focused
              ? const Color(0xFF7DD3FC).withValues(alpha: 0.58 * dim)
              : const Color(0xFF60A5FA).withValues(alpha: 0.24 * dim)
          ..style = PaintingStyle.stroke
          ..strokeWidth = focused ? 2.1 : 1.2,
      );

      if (originRot.z > 0.05) {
        final ox = cx + originRot.x * radius, oy = cy - originRot.y * radius;
        canvas.drawCircle(
          Offset(ox, oy),
          focused ? 3.8 : 2.6,
          Paint()
            ..color = focused
                ? Colors.white.withValues(alpha: dim)
                : const Color(0xFFBAE6FD).withValues(alpha: 0.85 * dim),
        );
        if (!ambient) {
          _drawText(
            canvas,
            route.city,
            Offset(ox + 7, oy - 7),
            fontSize: 11,
            weight: focused ? FontWeight.w700 : FontWeight.w600,
            color: focused
                ? Colors.white
                : const Color(0xFFE2E8F0).withValues(alpha: 0.78),
          );
        }
      }

      final planes = focused
          ? [(phase + idx * 0.21) % 1, (phase + idx * 0.21 + 0.5) % 1]
          : [(phase * 0.85 + idx * 0.23) % 1];

      for (final progress in planes) {
        final trailStart = math.max(0.0, progress - 0.17);
        final startIdx = (trailStart * segments).floor();
        final endIdx = math.min(segments, (progress * segments).ceil());
        if (endIdx > startIdx) {
          final trail = Path();
          var open = false;
          for (var k = startIdx; k <= endIdx; k++) {
            final p = arc[k];
            if (p.z > -0.1) {
              if (!open) {
                trail.moveTo(p.x, p.y);
                open = true;
              } else {
                trail.lineTo(p.x, p.y);
              }
            }
          }
          canvas.drawPath(
            trail,
            Paint()
              ..color = focused
                  ? Colors.white.withValues(alpha: 0.92 * dim)
                  : const Color(0xFFBAE6FD).withValues(alpha: 0.62 * dim)
              ..style = PaintingStyle.stroke
              ..strokeWidth = focused ? 2.8 : 1.7
              ..strokeCap = StrokeCap.round,
          );
        }

        final pos =
            _rotate(_slerpElevated(origin, _seoul, progress, lift), yaw, pitch);
        if (pos.z > -0.08) {
          final ahead = _rotate(
            _slerpElevated(origin, _seoul, math.min(1, progress + 0.02), lift),
            yaw,
            pitch,
          );
          final behind = _rotate(
            _slerpElevated(origin, _seoul, math.max(0, progress - 0.02), lift),
            yaw,
            pitch,
          );
          final angle = math.atan2(-(ahead.y - behind.y), ahead.x - behind.x);
          _drawAirplane(
            canvas,
            Offset(cx + pos.x * radius, cy - pos.y * radius),
            angle,
            focused ? 1.08 : 0.82,
            focused,
            dim,
          );
        }
      }
    }

    // 5. 서울 도착점
    final seoulRot = _rotate(_seoul, yaw, pitch);
    if (seoulRot.z > 0) {
      final sx = cx + seoulRot.x * radius, sy = cy - seoulRot.y * radius;
      final pulse = (phase * 2.2) % 1;
      canvas.drawCircle(
        Offset(sx, sy),
        6 + pulse * 18,
        Paint()
          ..color = const Color(0xFF60A5FA)
              .withValues(alpha: (1 - pulse) * 0.85 * dim)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
          Offset(sx, sy), 6, Paint()..color = const Color(0xFF3182F6));
      canvas.drawCircle(Offset(sx, sy), 2.8, Paint()..color = Colors.white);

      if (!ambient && hubLabel.isNotEmpty) {
        final tp = _textPainter(
          hubLabel,
          fontSize: 11.5,
          weight: FontWeight.w700,
          color: const Color(0xFFF8FAFC),
        );
        // 서울 바로 옆 도시(도쿄)를 가리지 않게 이름표는 아래쪽에 둔다
        final pillRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(sx - (tp.width + 16) / 2, sy + 12, tp.width + 16, 23),
          const Radius.circular(11.5),
        );
        canvas.drawRRect(pillRect,
            Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.86));
        canvas.drawRRect(
          pillRect,
          Paint()
            ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
        tp.paint(canvas,
            Offset(pillRect.left + 8, pillRect.top + (23 - tp.height) / 2));
      }
    }
  }

  TextPainter _textPainter(
    String text, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: weight,
            color: color,
            fontFamily: fontFamily),
      ),
      textDirection: textDirection,
    )..layout();
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset at, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
  }) {
    _textPainter(text, fontSize: fontSize, weight: weight, color: color)
        .paint(canvas, at);
  }

  /// 위에서 본 여객기 실루엣. 0rad = 오른쪽.
  void _drawAirplane(Canvas canvas, Offset at, double angle, double scale,
      bool highlighted, double dim) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    final haloR = highlighted ? 16.0 : 11.0;
    canvas.drawCircle(
      Offset.zero,
      haloR,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          haloR,
          [
            (highlighted ? const Color(0xFF60A5FA) : const Color(0xFF93C5FD))
                .withValues(alpha: (highlighted ? 0.65 : 0.35) * dim),
            const Color(0x003B82F6),
          ],
        ),
    );

    final body = Path()
      ..moveTo(9.5, 0)
      ..lineTo(4.2, 1.55)
      ..lineTo(-1.8, 9.2)
      ..lineTo(-4.0, 9.2)
      ..lineTo(-1.4, 1.65)
      ..lineTo(-6.2, 1.2)
      ..lineTo(-8.8, 4.4)
      ..lineTo(-10.2, 4.4)
      ..lineTo(-8.6, 0.6)
      ..lineTo(-9.6, 0)
      ..lineTo(-8.6, -0.6)
      ..lineTo(-10.2, -4.4)
      ..lineTo(-8.8, -4.4)
      ..lineTo(-6.2, -1.2)
      ..lineTo(-1.4, -1.65)
      ..lineTo(-4.0, -9.2)
      ..lineTo(-1.8, -9.2)
      ..lineTo(4.2, -1.55)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..color = highlighted
            ? Colors.white.withValues(alpha: dim)
            : const Color(0xFFF1F5F9).withValues(alpha: 0.92 * dim),
    );
    if (highlighted) {
      canvas.drawPath(
        body,
        Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) =>
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.phase != phase ||
      old.corridors != corridors ||
      old.activeIndex != activeIndex ||
      old.ambient != ambient ||
      old.hubLabel != hubLabel;
}
