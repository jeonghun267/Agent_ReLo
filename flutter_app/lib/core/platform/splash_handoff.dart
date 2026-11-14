import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'relo_native_channel.dart';

/// @module core/platform/splash_handoff
/// @purpose 기기의 시작 화면(가운데 로고)에서 앱 안의 시작 연출로 넘어가는 때를 맞춘다.
///
///          앱이 첫 화면을 "만든" 때와 그것이 실제로 "화면에 그려진" 때 사이에는 틈이 있다
///          (느린 기기에서는 1초 가까이). 그 틈에 연출을 시작하면 보이지 않는 채로 흘러가 버린다.
///          그래서 순서를 이렇게 맞춘다:
///          1. 앱의 첫 화면(시작 화면과 똑같은 모습)이 실제로 그려질 때까지 기다린다.
///          2. 기기에 "이제 시작 화면을 걷어 달라"고 한다. 그때까지 시작 화면은 그대로 떠 있다.
///          3. 걷히면 연출을 시작한다.
class SplashHandoff {
  SplashHandoff._();

  static const Duration _patience = Duration(seconds: 3);

  /// 기기의 시작 화면을 넘겨받는다. 넘겨받았을 때 로고의 가운데가 앱 화면에서
  /// 어디였는지(기기 픽셀)를 돌려준다. 그런 화면이 없거나 알 수 없으면 null.
  ///
  /// 기기가 답하지 않아도 화면이 멈추지 않도록 3초 뒤에는 그냥 시작한다.
  static Future<Offset?> takeOver() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final state = await reloNativeChannel
          .invokeMapMethod<String, Object?>('splashState')
          .timeout(_patience);
      if (state == null) return null;
      if (state['waitForFirstFrame'] == true) {
        await WidgetsBinding.instance.waitUntilFirstFrameRasterized
            .timeout(_patience, onTimeout: () {});
      }
      if (state['showing'] != true) return null;
      final taken = await reloNativeChannel
          .invokeMapMethod<String, Object?>('takeOverSplash')
          .timeout(_patience);
      return _center(taken);
    } catch (_) {
      return null; // 기기가 응답하지 않음 (시험 환경 등)
    }
  }

  static Offset? _center(Map<String, Object?>? data) {
    final x = data?['cx'];
    final y = data?['cy'];
    if (x is! num || y is! num) return null;
    return Offset(x.toDouble(), y.toDouble());
  }
}
