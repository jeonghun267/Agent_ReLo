import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/relo_native_channel.dart';
import 'evidence_rules.dart';

/// @module core/attachments/evidence_picker
/// @purpose 기기에서 영수증 · 사진을 가져오는 두 가지 길.
///          - [EvidencePicker]: 앱 안에서 찍거나 고른다.
///          - [SharedEvidenceInbox]: 다른 앱(메일 · 사진첩 · 쇼핑몰 앱)에서 "공유 → ReLo"로 넘겨받는다.
///          화면은 이 두 이름만 알고, 실제 일은 기기마다 다른 구현이 맡는다 (시험에서는 가짜로 바꿔 끼운다).

/// 어디서 가져올지
enum EvidenceSource {
  /// 지금 사진을 찍는다
  camera,

  /// 사진첩에서 고른다
  photo,

  /// 파일(PDF · 사진)에서 고른다
  file,
}

abstract class EvidencePicker {
  /// 이 기기에서 고를 수 있는지. 아니면 화면이 "아직 안 돼요"라고 알린다.
  bool get isSupported;

  /// 하나를 골라 손본 뒤 돌려준다. 사용자가 그만두면 null.
  /// 올릴 수 없는 파일이면 [EvidenceException].
  Future<PickedEvidence?> pick(EvidenceSource source);
}

abstract class SharedEvidenceInbox {
  /// 다른 앱에서 공유로 넘어온 파일이 있으면 손봐서 돌려준다. 한 번 읽으면 비워진다. 없으면 null.
  /// 올릴 수 없는 파일이면 [EvidenceException].
  Future<PickedEvidence?> take();

  /// 앱이 떠 있는 동안 공유가 들어오면 불린다 (그때 [take]를 부르면 된다)
  void setOnArrived(void Function()? handler);
}

/// 고르기 기능이 없는 곳 (웹 미리보기 · 데스크톱)
class UnsupportedEvidencePicker implements EvidencePicker {
  const UnsupportedEvidencePicker();

  @override
  bool get isSupported => false;

  @override
  Future<PickedEvidence?> pick(EvidenceSource source) async =>
      throw const EvidenceException(EvidenceProblem.unavailable);
}

/// 공유받기가 없는 곳
class NoSharedEvidenceInbox implements SharedEvidenceInbox {
  const NoSharedEvidenceInbox();

  @override
  Future<PickedEvidence?> take() async => null;

  @override
  void setOnArrived(void Function()? handler) {}
}

/// 기기가 넘겨준 {name, bytes}를 올릴 수 있는 파일로 만든다. 기기 쪽 오류는 까닭으로 바꾼다.
Future<PickedEvidence?> _evidenceFromDevice(
  MethodChannel channel,
  String method,
  Map<String, Object?> arguments,
) async {
  final Map<String, Object?>? picked;
  try {
    picked = await channel.invokeMapMethod<String, Object?>(method, arguments);
  } on PlatformException catch (e) {
    throw EvidenceException(switch (e.code) {
      'too_large' => EvidenceProblem.tooLarge,
      'unsupported_type' => EvidenceProblem.unsupportedType,
      'unavailable' => EvidenceProblem.unavailable,
      _ => EvidenceProblem.unreadable,
    });
  } on MissingPluginException {
    throw const EvidenceException(EvidenceProblem.unavailable);
  }
  if (picked == null) return null;
  final bytes = picked['bytes'];
  if (bytes is! Uint8List) {
    throw const EvidenceException(EvidenceProblem.unreadable);
  }
  return EvidenceRules.prepare(
    name: picked['name']?.toString() ?? '',
    bytes: bytes,
  );
}

/// 안드로이드: 기기의 카메라 · 사진 고르기 · 파일 고르기 화면을 연다.
/// 큰 사진을 줄이고 바로 세우는 일은 기기 쪽(ReloEvidence.kt)에서 하고,
/// 종류 확인 · 촬영 정보 지우기 · 크기 확인은 [EvidenceRules.prepare]가 한 번 더 한다.
class ChannelEvidencePicker implements EvidencePicker {
  final MethodChannel _channel;

  const ChannelEvidencePicker([this._channel = reloNativeChannel]);

  @override
  bool get isSupported => true;

  @override
  Future<PickedEvidence?> pick(EvidenceSource source) => _evidenceFromDevice(
        _channel,
        'pickEvidence',
        {'source': source.name, 'maxBytes': EvidenceRules.maxBytes},
      );
}

/// 안드로이드: 다른 앱의 "공유"에서 ReLo를 고르면 그 파일이 여기로 온다.
class ChannelSharedEvidenceInbox implements SharedEvidenceInbox {
  final MethodChannel _channel;

  const ChannelSharedEvidenceInbox([this._channel = reloNativeChannel]);

  @override
  Future<PickedEvidence?> take() async {
    try {
      return await _evidenceFromDevice(
        _channel,
        'takeSharedEvidence',
        {'maxBytes': EvidenceRules.maxBytes},
      );
    } on EvidenceException catch (e) {
      // 기기가 응답하지 않는 것(시험 환경 등)은 "들어온 것이 없음"과 같다
      if (e.problem == EvidenceProblem.unavailable) return null;
      rethrow;
    }
  }

  @override
  void setOnArrived(void Function()? handler) => ReloNativeEvents.on(
        'evidenceShared',
        handler == null ? null : (_) => handler(),
      );
}

bool get _onAndroid =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// 지금 기기에 맞는 구현
EvidencePicker defaultEvidencePicker() => _onAndroid
    ? const ChannelEvidencePicker()
    : const UnsupportedEvidencePicker();

SharedEvidenceInbox defaultSharedEvidenceInbox() => _onAndroid
    ? const ChannelSharedEvidenceInbox()
    : const NoSharedEvidenceInbox();
