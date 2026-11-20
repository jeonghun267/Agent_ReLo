/// @module shared/models/agent_models
/// @layer Shared Domain Models
/// @purpose "AI에게 맡기기"(에이전트 실행)와 "AI가 채우기"(신청 한 줄 읽기)의 서버 응답 모양.
///          웹 `src/client/types/domain.ts`의 Agent* · AiIntakeResponse와 같다.
///          에이전트는 읽는 일(자료 읽기 · 답장 풀기 · 글 쓰기)은 바로 하고, 건을 바꾸는 일
///          (주문 정보 고치기 · 글 저장하기)은 [AgentPending]으로 내놓고 사람의 답을 기다린다.
library;

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) build) =>
    raw is List
        ? raw.whereType<Map<String, dynamic>>().map(build).toList()
        : <T>[];

String? _text(dynamic raw) {
  final text = raw?.toString() ?? '';
  return text.isEmpty ? null : text;
}

/// 고치려는 값 하나: 저장된 값 [from]을 자료에서 읽은 값 [to]로.
class AgentChange {
  /// orderRef · orderedOn · currency
  final String field;
  final String from;
  final String to;
  const AgentChange({required this.field, required this.from, required this.to});

  factory AgentChange.fromJson(Map<String, dynamic> json) => AgentChange(
        field: (json['field'] ?? '').toString(),
        from: (json['from'] ?? '').toString(),
        to: (json['to'] ?? '').toString(),
      );
}

/// 자료에서 읽은 값이 저장된 값과 다른 곳 하나.
class AgentMismatch {
  final String field;
  final String saved;
  final String read;
  const AgentMismatch({
    required this.field,
    required this.saved,
    required this.read,
  });

  factory AgentMismatch.fromJson(Map<String, dynamic> json) => AgentMismatch(
        field: (json['field'] ?? '').toString(),
        saved: (json['saved'] ?? '').toString(),
        read: (json['read'] ?? '').toString(),
      );
}

/// 실행의 한 단계: AI가 고른 도구, 고른 까닭, 그 결과.
class AgentStep {
  final int seq;

  /// read_evidence · analyze_reply · write_draft · fix_order_facts · save_draft
  final String tool;
  final String reason;
  final String? fileName;
  final bool ok;
  final String message;

  /// 읽는 도구가 돌려준 것 (서버 응답 그대로). 실패했거나 건을 바꾸는 도구면 null.
  final Map<String, dynamic>? result;
  final List<AgentMismatch> mismatches;

  /// 건을 바꾸는 단계에서 사람이 한 답: approved · declined. 읽는 단계는 빈 글.
  final String decision;
  final List<AgentChange> changes;

  const AgentStep({
    required this.seq,
    required this.tool,
    required this.reason,
    required this.fileName,
    required this.ok,
    required this.message,
    required this.result,
    required this.mismatches,
    required this.decision,
    required this.changes,
  });

  factory AgentStep.fromJson(Map<String, dynamic> json) => AgentStep(
        seq: (json['seq'] as num?)?.toInt() ?? 0,
        tool: (json['tool'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        fileName: _text(json['fileName']),
        ok: json['ok'] == true,
        message: (json['message'] ?? '').toString(),
        result: json['result'] is Map<String, dynamic>
            ? json['result'] as Map<String, dynamic>
            : null,
        mismatches: _list(json['mismatches'], AgentMismatch.fromJson),
        decision: (json['decision'] ?? '').toString(),
        changes: _list(json['changes'], AgentChange.fromJson),
      );
}

/// AI가 하려는 일. 사람이 허락하기 전에는 아무것도 바뀌지 않는다.
class AgentPending {
  final String tool;
  final String reason;
  final String? fileName;
  final List<AgentChange> changes;

  /// 저장하려는 글 (save_draft일 때)
  final String? draftBody;

  const AgentPending({
    required this.tool,
    required this.reason,
    required this.fileName,
    required this.changes,
    required this.draftBody,
  });

  factory AgentPending.fromJson(Map<String, dynamic> json) => AgentPending(
        tool: (json['tool'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        fileName: _text(json['fileName']),
        changes: _list(json['changes'], AgentChange.fromJson),
        draftBody: _text(json['draftBody']),
      );
}

/// 실행 하나. [pending]이 있으면 사람의 답을 기다리며 멈춰 있는 것이다.
class AgentRun {
  final String runId;

  /// done · max_steps · repeat · invalid_choice · rate_limited · plan_failed. 기다리는 중이면 null.
  final String? endedBy;

  /// 무엇이 시작시켰는지: person(버튼) · filed(신청) · file(자료) · reply(답장)
  final String startedBy;
  final int maxSteps;
  final int aiCalls;
  final String reason;

  /// AI가 "다음에 사람이 할 일"로 적은 한 문장
  final String? userAction;
  final List<AgentStep> steps;
  final AgentPending? pending;

  const AgentRun({
    required this.runId,
    required this.endedBy,
    required this.startedBy,
    required this.maxSteps,
    required this.aiCalls,
    required this.reason,
    required this.userAction,
    required this.steps,
    required this.pending,
  });

  bool get isWaiting => pending != null && endedBy == null;

  factory AgentRun.fromJson(Map<String, dynamic> json) => AgentRun(
        runId: (json['runId'] ?? '').toString(),
        endedBy: _text(json['endedBy']),
        startedBy: (json['startedBy'] ?? 'person').toString(),
        maxSteps: (json['maxSteps'] as num?)?.toInt() ?? 5,
        aiCalls: (json['aiCalls'] as num?)?.toInt() ?? 0,
        reason: (json['reason'] ?? '').toString(),
        userAction: _text(json['userAction']),
        steps: _list(json['steps'], AgentStep.fromJson),
        pending: json['pending'] is Map<String, dynamic>
            ? AgentPending.fromJson(json['pending'] as Map<String, dynamic>)
            : null,
      );
}

/// 지난 실행에서 한 일 (도구 이름과 사람의 답만).
class AgentLastRun {
  final String endedAt;
  final String startedBy;
  final String? userAction;
  final List<({String tool, String decision})> steps;

  const AgentLastRun({
    required this.endedAt,
    required this.startedBy,
    required this.userAction,
    required this.steps,
  });

  factory AgentLastRun.fromJson(Map<String, dynamic> json) => AgentLastRun(
        endedAt: (json['endedAt'] ?? '').toString(),
        startedBy: (json['startedBy'] ?? 'person').toString(),
        userAction: _text(json['userAction']),
        steps: _list(
          json['steps'],
          (step) => (
            tool: (step['tool'] ?? '').toString(),
            decision: (step['decision'] ?? '').toString(),
          ),
        ),
      );
}

/// 건을 열었을 때 서버가 알려 주는 것: 지금 일하는 중인지, 기다리는 제안, 지난 실행.
class AgentOverview {
  /// AI가 지금 이 건을 살펴보고 있다 (스스로 시작했거나, 곧 시작한다)
  final bool working;

  /// 스스로 시작하려 했지만 이번 시간의 AI 횟수가 모자라서 하지 않았다
  final bool heldBack;
  final AgentRun? waiting;
  final AgentLastRun? last;

  const AgentOverview({
    this.working = false,
    this.heldBack = false,
    this.waiting,
    this.last,
  });

  factory AgentOverview.fromJson(Map<String, dynamic> json) => AgentOverview(
        working: json['working'] == true,
        heldBack: json['heldBack'] == true,
        waiting: json['waiting'] is Map<String, dynamic>
            ? AgentRun.fromJson(json['waiting'] as Map<String, dynamic>)
            : null,
        last: json['last'] is Map<String, dynamic>
            ? AgentLastRun.fromJson(json['last'] as Map<String, dynamic>)
            : null,
      );
}

/// 주문서에서 읽은 상품 한 줄. 이름 · 수량 · 값은 주문서의 것이고, AI가 지어내지 않는다.
class OrderItemReading {
  final String name;
  final int orderedQty;

  /// 한 개 값 (소수 글자, 예: "39.90"). 읽지 못했으면 null.
  final String? unitPrice;

  const OrderItemReading({
    required this.name,
    required this.orderedQty,
    required this.unitPrice,
  });

  factory OrderItemReading.fromJson(Map<String, dynamic> json) =>
      OrderItemReading(
        name: (json['name'] ?? '').toString(),
        orderedQty: (json['orderedQty'] as num?)?.toInt() ?? 1,
        unitPrice: _text(json['unitPrice']),
      );
}

/// 주문서 하나를 AI가 읽은 결과. 읽지 못한 칸은 null이고, 예시 값으로 채우지 않는다.
class OrderReading {
  final String? vendor;
  final String? orderRef;
  final String? orderedOn;
  final String? currency;
  final List<OrderItemReading> items;
  final String? orderTotal;

  const OrderReading({
    required this.vendor,
    required this.orderRef,
    required this.orderedOn,
    required this.currency,
    required this.items,
    required this.orderTotal,
  });

  /// `POST /api/ai/extract`의 응답에서
  factory OrderReading.fromJson(Map<String, dynamic> json) {
    final suggestion = json['suggestion'] is Map<String, dynamic>
        ? json['suggestion'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return OrderReading(
      vendor: _text(suggestion['vendor']),
      orderRef: _text(suggestion['orderRef']),
      orderedOn: _text(suggestion['orderedOn']),
      currency: _text(suggestion['currency']),
      items: _list(suggestion['items'], OrderItemReading.fromJson)
          .where((item) => item.name.isNotEmpty)
          .toList(),
      orderTotal: _text(json['orderTotal']),
    );
  }
}

/// 신청할 때 적은 한 줄을 AI가 읽은 결과: 어떤 종류인지, 주문서의 어느 상품 몇 개인지,
/// 그리고 그 한 줄의 영어. 상품 이름과 금액은 여기 없다 (주문서에서 읽은 값을 쓴다).
class IntakeReading {
  /// refund · exchange · repair
  final String kind;
  final int? itemIndex;
  final int? claimQty;
  final String issueEnglish;

  /// AI가 이해한 내용 한 문장 (화면에 그대로 보여 준다)
  final String? understood;

  const IntakeReading({
    required this.kind,
    required this.itemIndex,
    required this.claimQty,
    required this.issueEnglish,
    required this.understood,
  });

  factory IntakeReading.fromJson(Map<String, dynamic> json) => IntakeReading(
        kind: (json['kind'] ?? 'refund').toString(),
        itemIndex: (json['itemIndex'] as num?)?.toInt(),
        claimQty: (json['claimQty'] as num?)?.toInt(),
        issueEnglish: (json['issueEnglish'] ?? '').toString(),
        understood: _text(json['understood']),
      );
}
