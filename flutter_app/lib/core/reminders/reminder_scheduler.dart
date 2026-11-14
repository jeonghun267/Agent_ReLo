import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/relo_native_channel.dart';

/// @module core/reminders/reminder_scheduler
/// @purpose 정해진 시각에 기기 알림을 띄우도록 맞춰 둔다. "언제 무엇을"은
///          [ReminderPlanner]가 정하고, 여기서는 기기에 맡기는 일만 한다.
///          앱이 꺼져 있어도 알림이 오고, 서버를 거치지 않는다 (알림 내용이 기기 밖으로 나가지 않는다).

/// 기기에 맡길 알림 하나
class ReminderNotice {
  final int id;
  final DateTime when;
  final String title;
  final String body;

  /// 알림을 누르면 열 환불 건
  final String claimId;

  const ReminderNotice({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.claimId,
  });
}

abstract class ReminderScheduler {
  /// 이 기기에서 알림을 맞출 수 있는지
  bool get isSupported;

  /// 기기에서 이 앱의 알림이 허용되어 있는지
  Future<bool> isAllowed();

  /// 알림 허용을 물어본다 (이미 정했으면 그 답을 돌려준다)
  Future<bool> requestPermission();

  /// 맞춰 둔 알림을 모두 지우고 [notices]로 바꾼다. 빈 목록이면 모두 지운다.
  Future<void> replaceAll(List<ReminderNotice> notices);

  /// 알림을 눌러 앱이 열렸다면 그 환불 건의 id. 한 번 읽으면 비워진다.
  Future<String?> takeOpenedClaim();

  /// 앱이 떠 있을 때 알림을 누르면 불린다
  void setOnOpened(void Function(String claimId)? handler);
}

/// 알림 기능이 없는 곳 (웹 미리보기 · 데스크톱 · 시험)
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  bool get isSupported => false;

  @override
  Future<bool> isAllowed() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(List<ReminderNotice> notices) async {}

  @override
  Future<String?> takeOpenedClaim() async => null;

  @override
  void setOnOpened(void Function(String claimId)? handler) {}
}

/// 안드로이드: 기기의 알람과 알림 기능을 직접 쓴다 (ReloReminders.kt).
/// 기기가 응답하지 않으면 조용히 "안 됨"으로 돌려준다.
class ChannelReminderScheduler implements ReminderScheduler {
  final MethodChannel _channel;

  ChannelReminderScheduler([this._channel = reloNativeChannel]);

  @override
  bool get isSupported => true;

  @override
  Future<bool> isAllowed() async {
    try {
      return await _channel.invokeMethod<bool>('notificationsAllowed') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestNotifications') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> replaceAll(List<ReminderNotice> notices) async {
    try {
      await _channel.invokeMethod<void>('replaceReminders', {
        'items': [
          for (final n in notices)
            {
              'id': n.id,
              'at': n.when.millisecondsSinceEpoch,
              'title': n.title,
              'body': n.body,
              'claimId': n.claimId,
            },
        ],
      });
    } catch (_) {}
  }

  @override
  Future<String?> takeOpenedClaim() async {
    try {
      return await _channel.invokeMethod<String>('takeOpenedClaim');
    } catch (_) {
      return null;
    }
  }

  @override
  void setOnOpened(void Function(String claimId)? handler) => ReloNativeEvents.on(
        'reminderOpened',
        handler == null
            ? null
            : (arguments) {
                if (arguments is String) handler(arguments);
              },
      );
}

/// 지금 기기에 맞는 구현
ReminderScheduler defaultReminderScheduler() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return ChannelReminderScheduler();
  }
  return const NoopReminderScheduler();
}
