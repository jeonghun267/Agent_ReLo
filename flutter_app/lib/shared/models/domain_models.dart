/// @module shared/models/domain_models
/// @layer Shared Domain Models
/// @purpose ReLo 백엔드(`src/server/`) 및 웹 클라이언트(`src/client/types/domain.ts`)와
///          100% 호환되는 불변 도메인 모델 및 법적 동의 상태 모델을 정의합니다.

enum CookieConsentChoice {
  pending,
  essentialOnly,
  allAccepted,
}

class User {
  final String id;
  final String email;
  final String name;
  final String createdAt;
  final String? emailVerifiedAt;
  final String? aiConsentAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.emailVerifiedAt,
    this.aiConsentAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      emailVerifiedAt: json['emailVerifiedAt']?.toString(),
      aiConsentAt: json['aiConsentAt']?.toString(),
    );
  }
}

class DemoAccountHint {
  final String email;
  final String password;
  final String name;

  const DemoAccountHint({
    required this.email,
    required this.password,
    required this.name,
  });

  factory DemoAccountHint.fromJson(Map<String, dynamic> json) {
    return DemoAccountHint(
      email: (json['email'] ?? 'demo@relo.local').toString(),
      password: (json['password'] ?? 'demo1234!').toString(),
      name: (json['name'] ?? '김직구').toString(),
    );
  }
}

class AppConfig {
  final String environment;
  final Map<String, String> states;
  final Map<String, String> claimKinds;
  final Map<String, String> replyKinds;
  final Map<String, String> receiptKinds;
  final bool aiEnabled;
  final String? aiModel;
  final DemoAccountHint? demoAccount;

  const AppConfig({
    required this.environment,
    required this.states,
    required this.claimKinds,
    required this.replyKinds,
    required this.receiptKinds,
    required this.aiEnabled,
    this.aiModel,
    this.demoAccount,
  });

  factory AppConfig.defaults() {
    return const AppConfig(
      environment: 'development',
      states: {
        'preparing': '서류 준비',
        'review': '메시지 준비',
        'awaiting': '답변 대기',
        'negotiating': '조건 조율',
        'partial': '부분 입금',
        'disputed': '분쟁 중',
        'waived': '포기',
        'recovered': '입금 확인',
        'completed': '완료',
      },
      claimKinds: {
        'refund': '반품 · 환불',
        'exchange': '새 상품 교환',
        'repair': '무상 수리·부품',
      },
      replyKinds: {
        'agreement': '환불·교환 약속',
        'refund_notice': '환불 처리 안내',
        'evidence': '추가 사진 요청',
        'denied': '환불 거절',
        'other': '기타 안내',
      },
      receiptKinds: {
        'cash': '카드 취소 · 계좌 입금',
        'goods': '교환 상품 수령',
        'repair': '무상 수리 완료',
        'reversal': '입금 취소 정정',
      },
      aiEnabled: true,
      aiModel: 'gemini-2.5-flash',
      demoAccount: DemoAccountHint(
        email: 'demo@relo.local',
        password: 'demo-consumer-pass',
        name: '김직구',
      ),
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final defaults = AppConfig.defaults();
    Map<String, String> parseMap(dynamic raw, Map<String, String> fallback) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return fallback;
    }

    final aiRaw = json['ai'];
    final demoRaw = json['demoAccount'];

    return AppConfig(
      environment: (json['environment'] ?? 'development').toString(),
      states: parseMap(json['states'], defaults.states),
      claimKinds: parseMap(json['claimKinds'], defaults.claimKinds),
      replyKinds: parseMap(json['replyKinds'], defaults.replyKinds),
      receiptKinds: parseMap(json['receiptKinds'], defaults.receiptKinds),
      aiEnabled: aiRaw is Map ? (aiRaw['enabled'] == true) : true,
      aiModel: aiRaw is Map ? aiRaw['model']?.toString() : 'gemini-2.5-flash',
      demoAccount: demoRaw is Map<String, dynamic>
          ? DemoAccountHint.fromJson(demoRaw)
          : defaults.demoAccount,
    );
  }
}

class ClaimItem {
  final String name;
  final String sku;
  final int orderedQty;
  final int claimQty;
  final int unitPrice;

  const ClaimItem({
    required this.name,
    required this.sku,
    required this.orderedQty,
    required this.claimQty,
    required this.unitPrice,
  });

  factory ClaimItem.fromJson(Map<String, dynamic> json) {
    return ClaimItem(
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      orderedQty: (json['orderedQty'] as num?)?.toInt() ?? 1,
      claimQty: (json['claimQty'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClaimFile {
  final String id;
  final String claimId;
  final String name;
  final String mime;
  final int size;
  final String sha;
  final String createdAt;
  final bool usedAsProof;

  const ClaimFile({
    required this.id,
    required this.claimId,
    required this.name,
    required this.mime,
    required this.size,
    required this.sha,
    required this.createdAt,
    required this.usedAsProof,
  });

  factory ClaimFile.fromJson(Map<String, dynamic> json) {
    return ClaimFile(
      id: (json['id'] ?? '').toString(),
      claimId: (json['claimId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      mime: (json['mime'] ?? 'image/jpeg').toString(),
      size: (json['size'] as num?)?.toInt() ?? 0,
      sha: (json['sha'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      usedAsProof: json['usedAsProof'] == true,
    );
  }
}

class ClaimDraft {
  final String id;
  final String body;
  final String origin;
  final String model;
  final String createdAt;
  final String? submittedAt;
  final String submissionNote;
  final bool stale;

  const ClaimDraft({
    required this.id,
    required this.body,
    required this.origin,
    required this.model,
    required this.createdAt,
    this.submittedAt,
    required this.submissionNote,
    required this.stale,
  });

  factory ClaimDraft.fromJson(Map<String, dynamic> json) {
    return ClaimDraft(
      id: (json['id'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      origin: (json['origin'] ?? 'manual').toString(),
      model: (json['model'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      submittedAt: json['submittedAt']?.toString(),
      submissionNote: (json['submissionNote'] ?? '').toString(),
      stale: json['stale'] == true,
    );
  }
}

class ClaimReply {
  final String id;
  final String body;
  final String kind;
  final String translationKo;
  final String summaryKo;
  final bool aiAssisted;
  final String recordedAt;

  const ClaimReply({
    required this.id,
    required this.body,
    required this.kind,
    required this.translationKo,
    required this.summaryKo,
    required this.aiAssisted,
    required this.recordedAt,
  });

  factory ClaimReply.fromJson(Map<String, dynamic> json) {
    return ClaimReply(
      id: (json['id'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      kind: (json['kind'] ?? 'agreement').toString(),
      translationKo: (json['translationKo'] ?? '').toString(),
      summaryKo: (json['summaryKo'] ?? '').toString(),
      aiAssisted: json['aiAssisted'] == true,
      recordedAt: (json['recordedAt'] ?? '').toString(),
    );
  }
}

class LedgerEntry {
  final String id;
  final String claimId;
  final String kind;
  final int amount;
  final int quantity;
  final String note;
  final String? proofId;
  final String transactionRef;
  final String receivedOn;
  final String createdAt;

  const LedgerEntry({
    required this.id,
    required this.claimId,
    required this.kind,
    required this.amount,
    required this.quantity,
    required this.note,
    this.proofId,
    required this.transactionRef,
    required this.receivedOn,
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: (json['id'] ?? '').toString(),
      claimId: (json['claimId'] ?? '').toString(),
      kind: (json['kind'] ?? 'cash').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      note: (json['note'] ?? '').toString(),
      proofId: json['proofId']?.toString(),
      transactionRef: (json['transactionRef'] ?? '').toString(),
      receivedOn: (json['receivedOn'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class ClaimAuditEvent {
  final String id;
  final String action;
  final String createdAt;

  const ClaimAuditEvent({
    required this.id,
    required this.action,
    required this.createdAt,
  });

  factory ClaimAuditEvent.fromJson(Map<String, dynamic> json) {
    return ClaimAuditEvent(
      id: (json['id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class ClaimSummaryTotals {
  final int cash;
  final int goods;
  final bool repair;
  final int remaining;
  final int requestedQty;

  const ClaimSummaryTotals({
    required this.cash,
    required this.goods,
    required this.repair,
    required this.remaining,
    required this.requestedQty,
  });

  factory ClaimSummaryTotals.fromJson(Map<String, dynamic> json) {
    return ClaimSummaryTotals(
      cash: (json['cash'] as num?)?.toInt() ?? 0,
      goods: (json['goods'] as num?)?.toInt() ?? 0,
      repair: json['repair'] == true,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      requestedQty: (json['requestedQty'] as num?)?.toInt() ?? 1,
    );
  }
}

class ClaimView {
  final String id;
  final String title;
  final String vendor;
  final String vendorUrl;
  final String orderRef;
  final String orderedOn;
  final String kind;
  final String currency;
  final List<ClaimItem> items;
  final int claimed;
  final int? agreed;
  final String issue;
  final String issueEnglish;
  final String? deadline;
  final String deadlineQuote;
  final String deadlineZone;
  final String state;
  final int version;
  final bool deleted;
  final String createdAt;
  final String updatedAt;
  final List<ClaimFile> files;
  final List<LedgerEntry> ledger;
  final List<ClaimDraft> drafts;
  final List<ClaimReply> replies;
  final List<ClaimAuditEvent> events;
  final ClaimSummaryTotals summary;
  final String nextStep;

  const ClaimView({
    required this.id,
    required this.title,
    required this.vendor,
    required this.vendorUrl,
    required this.orderRef,
    required this.orderedOn,
    required this.kind,
    required this.currency,
    required this.items,
    required this.claimed,
    this.agreed,
    required this.issue,
    required this.issueEnglish,
    this.deadline,
    required this.deadlineQuote,
    required this.deadlineZone,
    required this.state,
    required this.version,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
    required this.files,
    required this.ledger,
    required this.drafts,
    required this.replies,
    required this.events,
    required this.summary,
    required this.nextStep,
  });

  factory ClaimView.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) builder,
    ) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map((e) => builder(e))
            .toList();
      }
      return <T>[];
    }

    final claimedVal = (json['claimed'] as num?)?.toInt() ?? 0;
    final agreedVal = (json['agreed'] as num?)?.toInt();

    return ClaimView(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      vendor: (json['vendor'] ?? '').toString(),
      vendorUrl: (json['vendorUrl'] ?? '').toString(),
      orderRef: (json['orderRef'] ?? '').toString(),
      orderedOn: (json['orderedOn'] ?? '').toString(),
      kind: (json['kind'] ?? 'refund').toString(),
      currency: (json['currency'] ?? 'USD').toString(),
      items: parseList(json['items'], ClaimItem.fromJson),
      claimed: claimedVal,
      agreed: agreedVal,
      issue: (json['issue'] ?? '').toString(),
      issueEnglish: (json['issueEnglish'] ?? '').toString(),
      deadline: json['deadline']?.toString(),
      deadlineQuote: (json['deadlineQuote'] ?? '').toString(),
      deadlineZone: (json['deadlineZone'] ?? 'UTC').toString(),
      state: (json['state'] ?? 'preparing').toString(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      deleted: json['deleted'] == true,
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      files: parseList(json['files'], ClaimFile.fromJson),
      ledger: parseList(json['ledger'], LedgerEntry.fromJson),
      drafts: parseList(json['drafts'], ClaimDraft.fromJson),
      replies: parseList(json['replies'], ClaimReply.fromJson),
      events: parseList(json['events'], ClaimAuditEvent.fromJson),
      summary: json['summary'] is Map<String, dynamic>
          ? ClaimSummaryTotals.fromJson(json['summary'] as Map<String, dynamic>)
          : ClaimSummaryTotals(
              cash: 0,
              goods: 0,
              repair: false,
              remaining: agreedVal ?? claimedVal,
              requestedQty: 1,
            ),
      nextStep: (json['nextStep'] ?? '외국어 요청서를 작성해 쇼핑몰에 보내세요.').toString(),
    );
  }
}

/// 위저드 4단계 및 영수증 스캔 시 첨부되는 로컬 증빙 아이템
class StagedEvidenceFile {
  final String id;
  final String name;
  final String mime;
  final List<int> bytes;
  final bool addressMasked;
  final String? defectTag;

  const StagedEvidenceFile({
    required this.id,
    required this.name,
    required this.mime,
    required this.bytes,
    this.addressMasked = true,
    this.defectTag,
  });

  int get size => bytes.length;
}

/// AI 도우미 대화 한 줄. 서버 `/api/ai/assistant` 응답과 같은 모양이다.
/// action: none · open_claim · draft_email · analyze_reply · new_claim
class AssistantTurn {
  final bool fromUser;
  final String text;
  final String action;
  final String? claimId;
  final List<String> suggestions;

  /// 서버 AI 대신 앱 안 기본 안내로 답했을 때 true
  final bool offline;

  const AssistantTurn({
    required this.fromUser,
    required this.text,
    this.action = 'none',
    this.claimId,
    this.suggestions = const [],
    this.offline = false,
  });

  const AssistantTurn.user(this.text)
      : fromUser = true,
        action = 'none',
        claimId = null,
        suggestions = const [],
        offline = false;

  factory AssistantTurn.fromJson(Map<String, dynamic> json) {
    return AssistantTurn(
      fromUser: false,
      text: (json['reply'] ?? '').toString(),
      action: (json['action'] ?? 'none').toString(),
      claimId: json['claimId']?.toString(),
      suggestions: (json['suggestions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, String> toHistory() =>
      {'role': fromUser ? 'user' : 'assistant', 'text': text};
}
