import 'package:flutter/services.dart';

/// @module core/platform/relo_native_channel
/// @purpose 앱(Dart)과 기기(안드로이드 Kotlin) 사이의 통로 하나. 바깥 패키지를 쓰지 않고
///          안드로이드 기본 기능을 직접 부른다. 받는 쪽은
///          android/app/src/main/kotlin/com/relolabs/relo_flutter/MainActivity.kt 이다.
///
///          앱이 기기를 부르는 이름:
///          - pickEvidence {source: camera|photo|file, maxBytes}  → {name, bytes} 또는 null(취소)
///          - takeSharedEvidence {maxBytes}                       → {name, bytes} 또는 null(없음)
///          - shareText {text, subject}                           → bool
///          - notificationsAllowed                                → bool
///          - requestNotifications                                → bool
///          - replaceReminders {items: [{id, at, title, body, claimId}]}
///          - takeOpenedClaim                                     → String? (알림을 눌러 열렸을 때)
///          - splashState                                         → {showing, waitForFirstFrame} (시작 화면이 떠 있는지)
///          - takeOverSplash                                      → {cx, cy} 시작 화면을 걷고, 로고의 가운데가 있던 자리(기기 픽셀)를 받는다
///          기기가 앱을 부르는 이름 ([ReloNativeEvents]로 받는다):
///          - reminderOpened (claimId)   앱이 떠 있는 동안 알림을 눌렀다
///          - evidenceShared             앱이 떠 있는 동안 다른 앱에서 파일을 공유했다
const MethodChannel reloNativeChannel = MethodChannel('relo/native');

/// 기기가 앱을 부를 때 받는 곳을 이름별로 걸어 둔다.
/// (통로 하나에는 받는 곳을 하나만 둘 수 있어서 여기서 이름으로 나눈다.)
class ReloNativeEvents {
  ReloNativeEvents._();

  static final Map<String, void Function(Object? arguments)> _handlers = {};
  static bool _attached = false;

  static void on(String method, void Function(Object? arguments)? handler) {
    if (handler == null) {
      _handlers.remove(method);
    } else {
      _handlers[method] = handler;
    }
    if (_attached) return;
    _attached = true;
    reloNativeChannel.setMethodCallHandler((call) async {
      _handlers[call.method]?.call(call.arguments);
      return null;
    });
  }
}
