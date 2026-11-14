import '../../shared/models/domain_models.dart';

/// @module core/reminders/reminder_planner
/// @purpose 환불 건을 보고 "언제 무엇을 알릴지"만 정한다. 실제로 알림을 띄우는 일은 하지 않는다
///          (그래서 기기 없이도 시험할 수 있다). 규칙:
///          - 진행 중인 건의 마감 3일 전 · 하루 전 · 당일, 아침 9시
///          - 판매자에게 메시지를 보내고 사흘이 지나면 "답장이 왔는지 확인해 보세요", 아침 9시
///          끝난 건(입금 확인 · 완료 · 포기), 휴지통에 있는 건, 이미 지난 시각은 뺀다.

enum ReminderKind { deadlineIn3Days, deadlineTomorrow, deadlineToday, replyCheck }

class PlannedReminder {
  /// 알림을 다시 맞추거나 지울 때 쓰는 번호. 같은 건 · 같은 종류면 늘 같은 번호다.
  final int id;
  final String claimId;
  final ReminderKind kind;

  /// 알릴 시각 (기기 시간)
  final DateTime when;
  final String claimTitle;
  final String vendor;

  const PlannedReminder({
    required this.id,
    required this.claimId,
    required this.kind,
    required this.when,
    required this.claimTitle,
    required this.vendor,
  });
}

class ReminderPlanner {
  ReminderPlanner._();

  /// 알리는 시각 (아침 9시)
  static const int hour = 9;

  /// 답장을 기다리기 시작하고 며칠 뒤에 확인하라고 알릴지
  static const int replyCheckAfterDays = 3;

  /// 한꺼번에 맞춰 두는 알림 수의 위쪽 끝 (iOS는 앱마다 64개까지만 맞춰 둘 수 있다)
  static const int maxPlanned = 60;

  static List<PlannedReminder> plan(
    Iterable<ClaimView> claims, {
    required DateTime now,
  }) {
    final out = <PlannedReminder>[];

    void add(ClaimView c, ReminderKind kind, DateTime day) {
      final when = DateTime(day.year, day.month, day.day, hour);
      if (!when.isAfter(now)) return;
      out.add(
        PlannedReminder(
          id: idFor(c.id, kind),
          claimId: c.id,
          kind: kind,
          when: when,
          claimTitle: c.title,
          vendor: c.vendor,
        ),
      );
    }

    for (final c in claims) {
      if (c.deleted) continue;
      if (c.state == 'recovered' ||
          c.state == 'completed' ||
          c.state == 'waived') {
        continue;
      }

      final deadline = _date(c.deadline);
      if (deadline != null) {
        add(c, ReminderKind.deadlineIn3Days,
            deadline.subtract(const Duration(days: 3)));
        add(c, ReminderKind.deadlineTomorrow,
            deadline.subtract(const Duration(days: 1)));
        add(c, ReminderKind.deadlineToday, deadline);
      }

      if (c.state == 'awaiting') {
        final since = _date(c.updatedAt);
        if (since != null) {
          add(c, ReminderKind.replyCheck,
              since.add(const Duration(days: replyCheckAfterDays)));
        }
      }
    }

    out.sort((a, b) => a.when.compareTo(b.when));
    return out.length > maxPlanned ? out.sublist(0, maxPlanned) : out;
  }

  /// 같은 건 · 같은 종류면 앱을 다시 켜도 같은 번호가 나오게 직접 계산한다
  /// (String.hashCode는 실행마다 같다는 보장이 없다). 31비트 안에 들어온다.
  static int idFor(String claimId, ReminderKind kind) {
    var h = 0x811C9DC5; // FNV-1a
    for (final unit in claimId.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return ((h & 0x0FFFFFFF) << 2) | kind.index;
  }

  /// "2026-11-20" 또는 "2026-11-20T09:12:00Z" → 그날 (기기 시간의 날짜). 읽을 수 없으면 null.
  static DateTime? _date(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    return DateTime(local.year, local.month, local.day);
  }
}
