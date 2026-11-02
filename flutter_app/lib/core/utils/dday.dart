/// @module core/utils/dday
/// @purpose 마감일(YYYY-MM-DD)을 "D-2", "오늘", "3일 지남"처럼 남은 날로 바꾼다 (DESIGN.md 6절).
class DDay {
  DDay._();

  /// 마감일까지 남은 날. 마감이 없거나 형식이 틀리면 null.
  static int? daysLeft(String? iso, {DateTime? now}) {
    if (iso == null || iso.isEmpty) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    final today = now ?? DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(date.year, date.month, date.day);
    return b.difference(a).inDays;
  }

  static String? label(String? iso, {DateTime? now}) {
    final d = daysLeft(iso, now: now);
    if (d == null) return null;
    if (d == 0) return '오늘';
    if (d > 0) return 'D-$d';
    return '${-d}일 지남';
  }

  /// 3일 안쪽이면 주황으로 강조한다
  static bool isUrgent(String? iso, {DateTime? now}) {
    final d = daysLeft(iso, now: now);
    return d != null && d <= 3;
  }
}
