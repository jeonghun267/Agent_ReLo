import 'domain_models.dart';

/// @module shared/models/claim_rules
/// @purpose 서버(`src/server/domain/claim.mjs`)와 같은 규칙을 앱에도 둔다. 화면이 "지금 무엇을
///          할 수 있는지"를 정할 때, 그리고 서버에 붙지 못한 체험 모드에서 기기 안의 건을
///          바꿀 때 본다. 환불은 돈, 교환은 받은 수량, 수리는 확인했는지로 센다.

/// 더 진행하지 않는 상태 (마무리 · 그만둠)
const Set<String> closedClaimStates = {'waived', 'completed'};

/// 메시지를 보냈는데 아직 다 받지 못한 상태. 여기서 "다른 해결 방법"으로 갈 수 있다.
const Set<String> waitingClaimStates = {'awaiting', 'negotiating', 'partial'};

/// 받은 기록 한 줄. 나중에 되돌렸으면 목록에는 남지만 더는 세지 않는다.
typedef ReceivedRow = ({LedgerEntry entry, bool undone});

/// "받았다"는 기록들 (되돌리기 줄 자체는 뺀다)
List<ReceivedRow> receivedRows(List<LedgerEntry> ledger) {
  final undone = {
    for (final e in ledger)
      if (e.reverses != null) e.reverses!,
  };
  return [
    for (final e in ledger)
      if (e.kind != 'reversal') (entry: e, undone: undone.contains(e.id)),
  ];
}

/// 되돌린 기록을 뺀, 실제로 받은 것의 합. [kind]와 [agreed]를 주면 그 값으로 다시 센다.
ClaimSummaryTotals claimTotals(
  ClaimView claim, {
  List<LedgerEntry>? ledger,
  String? kind,
  int? agreed,
}) {
  var cash = 0;
  var goods = 0;
  var repair = false;
  for (final row in receivedRows(ledger ?? claim.ledger)) {
    if (row.undone) continue;
    if (row.entry.kind == 'cash') cash += row.entry.amount;
    if (row.entry.kind == 'goods') goods += row.entry.quantity;
    if (row.entry.kind == 'repair') repair = true;
  }
  final asked = claim.items.fold<int>(0, (sum, item) => sum + item.claimQty);
  final target = agreed ?? claim.agreed ?? claim.claimed;
  return ClaimSummaryTotals(
    cash: cash,
    goods: goods,
    repair: repair,
    // 교환 · 수리는 돈으로 받을 것이 없다
    remaining: (kind ?? claim.kind) == 'refund' && target > cash
        ? target - cash
        : 0,
    requestedQty: asked > 0 ? asked : claim.summary.requestedQty,
  );
}

/// 받기로 한 것을 다 받았는지
bool isRecovered(String kind, int? agreed, ClaimSummaryTotals s) =>
    switch (kind) {
      'refund' => agreed != null && agreed > 0 && s.cash == agreed,
      'exchange' => s.requestedQty > 0 && s.goods >= s.requestedQty,
      _ => s.repair,
    };

/// 아직 세는 받은 기록이 하나라도 있는지 (있으면 해결 방법을 바꿀 수 없다)
bool hasReceived(ClaimSummaryTotals s) => s.cash > 0 || s.goods > 0 || s.repair;

String stateAfterReceipt(
  String current,
  String kind,
  int? agreed,
  ClaimSummaryTotals s,
) {
  if (current == 'disputed') return 'disputed';
  if (isRecovered(kind, agreed, s)) return 'recovered';
  return s.cash > 0 || s.goods > 0 ? 'partial' : 'negotiating';
}

/// "환불 처리했다"는 안내는 약속이지 돈이 아니다. 받은 것이 있으면 상태를 바꾸지 않는다.
String stateAfterReply(String replyKind, String current) {
  if (replyKind == 'denied') return 'disputed';
  if (replyKind == 'refund_notice' &&
      current != 'partial' &&
      current != 'recovered') {
    return 'awaiting';
  }
  return current;
}

/// 약속 금액이나 해결 방법을 고친 뒤의 상태. 받은 것이 있을 때만 다시 본다.
String stateAfterFactsChange(
  String current,
  String kind,
  int? agreed,
  ClaimSummaryTotals s,
) =>
    hasReceived(s) ? stateAfterReceipt(current, kind, agreed, s) : current;

/// 상태를 직접 바꿀 때의 다음 상태. 할 수 없는 바꿈이면 null.
/// [action]: disputed · waived · reopen · close
String? stateAfterTransition(String action, ClaimView claim) {
  final s = claim.summary;
  switch (action) {
    case 'reopen':
      if (!const {'waived', 'disputed', 'completed'}.contains(claim.state)) {
        return null;
      }
      if (isRecovered(claim.kind, claim.agreed, s)) return 'recovered';
      return s.cash > 0 || s.goods > 0 ? 'partial' : 'negotiating';
    case 'close':
      return isRecovered(claim.kind, claim.agreed, s) ? 'completed' : null;
    case 'disputed' || 'waived':
      return closedClaimStates.contains(claim.state) ? null : action;
    default:
      return null;
  }
}

/// 새로 기록할 수 없는 건 (휴지통 · 마무리 · 그만둠)
bool isClaimLocked(ClaimView c) =>
    c.deleted || closedClaimStates.contains(c.state);

/// 더 받을 것이 없는지 (기록 칸을 치운다)
bool isAllReceived(ClaimView c) => switch (c.kind) {
      'refund' =>
        c.agreed != null && c.agreed! > 0 && c.summary.cash >= c.agreed!,
      'exchange' => c.summary.goods >= c.summary.requestedQty,
      _ => c.summary.repair,
    };

/// 지금 마무리할 수 있는지
bool canFinishClaim(ClaimView c) =>
    !isClaimLocked(c) &&
    c.state != 'disputed' &&
    isRecovered(c.kind, c.agreed, c.summary);

/// 쇼핑몰이 답하지 않거나 약속을 지키지 않을 때 "다른 해결 방법"으로 갈 수 있는지
bool canEscalateClaim(ClaimView c) =>
    !c.deleted && waitingClaimStates.contains(c.state);

/// 쇼핑몰이 해 주겠다고 약속했는지: 환불은 약속 금액이 적혀 있으면, 교환 · 수리는 약속 답장이 있으면.
bool hasPromise(ClaimView c) => c.kind == 'refund'
    ? c.agreed != null
    : c.replies.any((r) => r.kind == 'agreement');

/// 지금 할 일을 가리키는 이름. 문장은 언어마다 화면이 고른다 (서버의 nextStepCode와 같다).
String nextStepCode(ClaimView c) {
  if (c.deleted) return 'trashed';
  if (c.state == 'waived') return 'waived';
  if (c.state == 'disputed') return 'disputed';
  if (c.state == 'completed') return 'completed';
  if (c.state == 'recovered') return 'recovered';
  final some = c.kind == 'refund'
      ? c.summary.remaining > 0 && c.summary.cash > 0
      : c.summary.goods > 0;
  if (some) return 'remaining';
  // 쇼핑몰이 약속했으면 기다림은 끝났다. 다음은 실제로 받은 것을 기록하는 일이다.
  if (c.state == 'awaiting' && !hasPromise(c)) return 'awaiting';
  if (c.files.isEmpty) return 'needFiles';
  if (c.drafts.isEmpty) return 'needMessage';
  if (c.kind == 'refund' && c.agreed == null) return 'needAgreed';
  return 'needProof';
}

/// 카드(VISA · Mastercard · AMEX)는 보통 이 기간 안에 이의 제기를 받는다
const int cardDisputeWindowDays = 120;

/// 유니온페이 카드와 PayPal은 보통 이만큼
const int longDisputeWindowDays = 180;

/// 주문일부터 센 마지막 날과 남은 날 (지났으면 음수). 주문일을 읽을 수 없으면 null.
/// 카드사는 물건을 받기로 한 날부터 세기도 해서, 이 날짜가 가장 이른(안전한) 날이다.
({String date, int daysLeft})? disputeDeadline(
  String orderedOn,
  int windowDays, {
  DateTime? today,
}) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(orderedOn);
  if (m == null) return null;
  final end = DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  ).add(Duration(days: windowDays));
  final now = today ?? DateTime.now();
  final left =
      end.difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  return (date: end.toIso8601String().substring(0, 10), daysLeft: left);
}
