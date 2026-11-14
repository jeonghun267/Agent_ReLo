import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'relo_native_channel.dart';

/// @module core/platform/text_sharer
/// @purpose 쓴 메시지를 다른 앱(메일 · 메신저 · 쇼핑몰 앱)으로 넘긴다. 기기의 "공유" 화면이 열리고,
///          어디로 보낼지는 사용자가 고른다. 앱이 대신 보내지는 않는다 (보낸 뒤 "보냈어요"는 사용자가 누른다).
abstract class TextSharer {
  bool get isSupported;

  /// 공유 화면을 열었으면 true
  Future<bool> share({required String text, String? subject});
}

class UnsupportedTextSharer implements TextSharer {
  const UnsupportedTextSharer();

  @override
  bool get isSupported => false;

  @override
  Future<bool> share({required String text, String? subject}) async => false;
}

class ChannelTextSharer implements TextSharer {
  final MethodChannel _channel;

  const ChannelTextSharer([this._channel = reloNativeChannel]);

  @override
  bool get isSupported => true;

  @override
  Future<bool> share({required String text, String? subject}) async {
    try {
      return await _channel.invokeMethod<bool>(
            'shareText',
            {'text': text, 'subject': subject},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}

TextSharer defaultTextSharer() =>
    (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? const ChannelTextSharer()
        : const UnsupportedTextSharer();
