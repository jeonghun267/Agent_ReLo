import 'package:shared_preferences/shared_preferences.dart';

/// @module core/storage/reminder_prefs
/// @purpose "마감 알림 받기"를 켰는지와, 켤지 한 번 물어봤는지를 이 기기에만 저장한다.
///          저장소를 쓸 수 없는 환경(시험 등)에서는 조용히 아무것도 하지 않는다.
class ReminderPrefs {
  static const _onKey = 'relo.reminders.on.v1';
  static const _askedKey = 'relo.reminders.asked.v1';

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<bool> loadOn() async => (await _prefs())?.getBool(_onKey) ?? false;

  Future<void> saveOn(bool on) async => (await _prefs())?.setBool(_onKey, on);

  Future<bool> loadAsked() async =>
      (await _prefs())?.getBool(_askedKey) ?? false;

  Future<void> saveAsked(bool asked) async =>
      (await _prefs())?.setBool(_askedKey, asked);
}
