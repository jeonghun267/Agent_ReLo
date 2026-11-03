import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// @module core/storage/assistant_history_storage
/// @purpose AI 도우미 대화 기록과 "도우미 캐릭터 띄우기" 설정을 이 기기에만 저장한다.
///          서버로는 보내지 않는다. 로그아웃·회원 탈퇴 때 지운다.
///          저장소를 쓸 수 없는 환경(테스트 등)에서는 조용히 아무것도 하지 않는다.
class AssistantHistoryStorage {
  static const _historyKey = 'relo.assistant.history.v1';
  static const _floatingKey = 'relo.assistant.floating.v1';

  /// 대화는 최근 30개까지, 대화 하나에는 최근 40줄까지 남긴다.
  static const maxConversations = 30;
  static const maxTurnsPerConversation = 40;

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadConversations() async {
    final raw = (await _prefs())?.getString(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveConversations(
      List<Map<String, dynamic>> conversations) async {
    await (await _prefs())?.setString(_historyKey, jsonEncode(conversations));
  }

  Future<bool?> loadFloatingVisible() async =>
      (await _prefs())?.getBool(_floatingKey);

  Future<void> saveFloatingVisible(bool visible) async =>
      (await _prefs())?.setBool(_floatingKey, visible);

  Future<void> clear() async {
    final prefs = await _prefs();
    await prefs?.remove(_historyKey);
  }
}
