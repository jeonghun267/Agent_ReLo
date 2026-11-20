import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relo_flutter/core/attachments/evidence_picker.dart';
import 'package:relo_flutter/core/attachments/evidence_rules.dart';
import 'package:relo_flutter/core/i18n/relo_i18n.dart';
import 'package:relo_flutter/core/network/api_client.dart';
import 'package:relo_flutter/main.dart';
import 'package:relo_flutter/shared/models/domain_models.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';
import 'package:relo_flutter/shared/widgets/relo_primitives.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wizard_helpers.dart';

/// "AI에게 맡기기"(에이전트) · "스스로 시작하기" · 신청의 "AI가 채우기"를 본다.
/// 지키는 것: 허락하기 전에는 건이 바뀌지 않는다, 동의하기 전에는 AI에 보내지 않는다,
/// 스스로 시작하기는 처음에 꺼져 있다, 서버가 없으면 앱이 대신 지어내지 않는다,
/// 신청을 채울 때 금액은 AI에 보내지 않고 주문서에서 읽은 값으로 계산한다.

const claimId = 'clm_hub';

typedef Asked = ({String method, String path, Map<String, dynamic>? data});

/// ReLo 서버처럼 답하는 가짜. AI는 정해 둔 답을 한다 (서버의 시험용 가짜 AI와 같은 순서).
class FakeServer extends ReloApiClient {
  FakeServer({this.consent = true, this.auto = false});

  final List<Asked> asked = [];
  bool consent;
  bool auto;
  String orderRef = 'EG-2026-1010';
  int version = 3;
  int files = 1;

  /// 서버가 알려 줄 에이전트의 모습
  bool working = false;
  bool heldBack = false;
  Map<String, dynamic>? waiting;

  /// AI가 한도에 걸린 것처럼 굴게 한다
  bool aiLimited = false;

  /// 알림 메일을 꺼 두었는지, 그리고 그 설정을 서버가 받지 못하게 할지
  bool noticeMailOff = false;
  bool emailVerified = true;
  bool failNoticeMail = false;

  /// 파일을 받지 못하는 것처럼 굴게 한다
  bool failUploads = false;

  /// 저장된 답장 (새것이 앞)
  final List<Map<String, dynamic>> replies = [];

  List<Asked> posted(String ending) => asked
      .where((a) => a.method == 'POST' && a.path.endsWith(ending))
      .toList();

  @override
  bool get hasSession => true;

  Map<String, dynamic> get user => {
        'id': 'usr_1',
        'email': 'tester@relo.test',
        'name': '김직구',
        'createdAt': '2026-11-01T00:00:00Z',
        'emailVerifiedAt': emailVerified ? '2026-11-01T00:00:00Z' : null,
        'aiConsentAt': consent ? '2026-11-02T00:00:00Z' : null,
        'agentAutoAt': auto ? '2026-11-03T00:00:00Z' : null,
        'noticeMailOffAt': noticeMailOff ? '2026-11-04T00:00:00Z' : null,
      };

  Map<String, dynamic> get claim => {
        'id': claimId,
        'title': 'USB-C 허브 7-in-1',
        'vendor': 'Example Gadgets EU',
        'vendorUrl': '',
        'orderRef': orderRef,
        'orderedOn': '2026-10-01',
        'kind': 'refund',
        'currency': 'EUR',
        'items': [
          {'name': 'USB-C Hub 7-in-1', 'sku': '', 'orderedQty': 2, 'claimQty': 1, 'unitPrice': 3990},
        ],
        'claimed': 3990,
        'agreed': null,
        'issue': '두 개 중 한 개가 전원이 들어오지 않습니다.',
        'issueEnglish': 'One of the two hubs does not power on.',
        'deadline': null,
        'deadlineQuote': '',
        'deadlineZone': 'UTC',
        'state': 'preparing',
        'version': version,
        'deleted': false,
        'createdAt': '2026-11-10T00:00:00Z',
        'updatedAt': '2026-11-10T00:00:00Z',
        'files': [
          for (var i = 0; i < files; i++)
            {
              'id': 'file_$i',
              'claimId': claimId,
              'name': i == 0 ? 'order.pdf' : 'photo_$i.jpg',
              'mime': i == 0 ? 'application/pdf' : 'image/jpeg',
              'size': 1200,
              'sha': 'x',
              'createdAt': '2026-11-10T00:00:00Z',
              'usedAsProof': false,
            },
        ],
        'ledger': [],
        'drafts': [],
        'replies': replies,
        'events': [],
        'summary': {'cash': 0, 'goods': 0, 'repair': false, 'remaining': 3990, 'requestedQty': 1},
        'nextStep': '',
      };

  static const reading = {
    'suggestion': {
      'vendor': 'Example Gadgets EU',
      'orderRef': 'EG-2026-1001',
      'orderedOn': '2026-10-01',
      'currency': 'EUR',
      'items': [
        {'name': 'USB-C Hub 7-in-1', 'orderedQty': 2, 'claimQty': 1, 'unitPrice': '39.90'},
        {'name': 'HDMI Cable 2m', 'orderedQty': 1, 'claimQty': 1, 'unitPrice': '9.50'},
      ],
    },
    'orderTotal': '89.30',
    'fields': [],
  };

  Map<String, dynamic> readStep() => {
        'seq': 1,
        'tool': 'read_evidence',
        'reason': '올린 자료가 있어서 먼저 읽어요.',
        'fileId': 'file_0',
        'fileName': 'order.pdf',
        'replyId': null,
        'ok': true,
        'errorCode': '',
        'message': '',
        'ms': 10,
        'result': reading,
        'mismatches': [
          {'field': 'orderRef', 'saved': 'EG-2026-1010', 'read': 'EG-2026-1001'},
        ],
        'decision': '',
        'changes': [],
      };

  /// 주문번호를 고치자고 내놓고 멈춘 실행
  Map<String, dynamic> waitingRun({String startedBy = 'person'}) => {
        'runId': 'run_1',
        'status': 'waiting',
        'endedBy': null,
        'startedBy': startedBy,
        'maxSteps': 5,
        'aiCalls': 3,
        'reason': '',
        'userAction': null,
        'errorCode': '',
        'steps': [readStep()],
        'pending': {
          'tool': 'fix_order_facts',
          'reason': '자료에 적힌 주문번호가 저장된 것과 달라요.',
          'fileName': 'order.pdf',
          'changes': [
            {'field': 'orderRef', 'from': 'EG-2026-1010', 'to': 'EG-2026-1001'},
          ],
          'draftBody': null,
        },
      };

  Map<String, dynamic> finishedRun({required bool approved}) => {
        'runId': 'run_1',
        'status': 'finished',
        'endedBy': 'done',
        'startedBy': 'person',
        'maxSteps': 5,
        'aiCalls': 5,
        'reason': '보낼 글까지 썼어요.',
        'userAction': '글을 읽어 보고 쇼핑몰에 직접 보내 주세요.',
        'errorCode': '',
        'steps': [
          readStep(),
          {
            'seq': 2,
            'tool': 'fix_order_facts',
            'reason': '자료에 적힌 주문번호가 저장된 것과 달라요.',
            'fileId': 'file_0',
            'fileName': 'order.pdf',
            'replyId': null,
            'ok': true,
            'errorCode': '',
            'message': '',
            'ms': 3,
            'result': null,
            'mismatches': [],
            'decision': approved ? 'approved' : 'declined',
            'changes': approved
                ? [
                    {'field': 'orderRef', 'from': 'EG-2026-1010', 'to': 'EG-2026-1001'},
                  ]
                : [],
          },
          {
            'seq': 3,
            'tool': 'write_draft',
            'reason': '보낸 글이 아직 없어요.',
            'fileId': null,
            'fileName': null,
            'replyId': null,
            'ok': true,
            'errorCode': '',
            'message': '',
            'ms': 20,
            'result': {
              'body': 'Hello Support,\n\nOne of the two USB-C hubs does not power on.\n\nThank you,\n[이름]',
              'summaryKo': '불량 1개의 환불을 요청하는 글이에요.',
              'model': 'fake',
            },
            'mismatches': [],
            'decision': '',
            'changes': [],
          },
        ],
        'pending': null,
      };

  Never refuse(int status, String code, String message) =>
      throw ApiError(message, code: code, status: status, explained: true);

  void needAi() {
    if (!consent) refuse(403, 'ai_consent_required', 'AI 기능을 쓰려면 먼저 AI 처리에 동의해 주세요.');
    if (aiLimited) refuse(429, 'ai_rate_limited', '한 시간에 쓸 수 있는 AI 횟수를 넘었어요.');
  }

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    List<int>? rawBytes,
    Map<String, String>? headers,
    int? version,
    String? idempotencyKey,
  }) async {
    asked.add((method: method, path: path, data: data));
    final get = method == 'GET';
    if (get && path == '/api/config') {
      return {
        'environment': 'test',
        'ai': {'enabled': true, 'model': 'fake', 'agentMaxSteps': 5},
        'demoAccount': null,
      };
    }
    if (get && path == '/api/me') return {'user': user};
    if (get && path == '/api/claims') return {'claims': [claim]};
    if (get && path == '/api/claims?deleted=1') return {'claims': []};
    if (get && path == '/api/ai/agent/waiting') {
      return {
        'claims': [
          if (waiting != null) {'claimId': claimId, 'tool': 'fix_order_facts'},
        ],
      };
    }
    if (path == '/api/claims/$claimId/ai/agent') {
      if (get) {
        return {'working': working, 'heldBack': heldBack, 'waiting': waiting, 'last': null};
      }
      needAi();
      waiting = waitingRun();
      return waiting!;
    }
    if (path == '/api/claims/$claimId/ai/agent/run_1/decision') {
      if (waiting == null) refuse(409, 'agent_not_waiting', '기다리고 있는 제안이 없어요. AI에게 다시 맡겨 주세요.');
      final approved = data!['approve'] == true;
      if (approved) {
        orderRef = 'EG-2026-1001';
        this.version += 1;
      }
      waiting = null;
      return finishedRun(approved: approved);
    }
    if (path == '/api/account/ai-consent') {
      consent = data!['consent'] == true;
      if (!consent) auto = false; // 동의를 거두면 스스로 시작하기도 꺼진다
      return {'user': user};
    }
    if (path == '/api/account/agent-auto') {
      if (!consent) refuse(403, 'ai_consent_required', 'AI에게 맡겨 두려면 먼저 AI 처리에 동의해 주세요.');
      auto = data!['on'] == true;
      return {'user': user};
    }
    if (path == '/api/ai/extract') {
      needAi();
      return reading;
    }
    if (path == '/api/ai/intake') {
      needAi();
      final exchange = data!['text'].toString().contains('바꿔');
      return {
        'kind': exchange ? 'exchange' : 'refund',
        'itemIndex': (data['items'] as List).isEmpty ? null : 0,
        'claimQty': 1,
        'issueEnglish': 'One of the two hubs does not power on. I would like a refund.',
        'understood': '허브 2개 가운데 1개가 켜지지 않아 환불을 원하는 것으로 읽었어요.',
        'model': 'fake',
      };
    }
    if (path == '/api/claims/$claimId/files') {
      if (failUploads) refuse(413, 'file_too_large', '파일이 너무 커요.');
      files += 1;
      this.version += 1;
      return {'claim': claim};
    }
    if (path == '/api/account/notice-mail') {
      if (failNoticeMail) refuse(503, 'unavailable', '잠시 후 다시 시도하세요.');
      noticeMailOff = data!['on'] != true;
      return {'user': user};
    }
    if (path == '/api/claims/$claimId/ai/analyze-reply') {
      needAi();
      return {
        'summaryKo': '불량품의 사진을 보내 달라고 해요.',
        'translationKo': '불량품의 사진을 보내 주세요.',
        'mentionedAmount': null,
      };
    }
    if (path == '/api/claims/$claimId/replies') {
      replies.insert(0, {
        'id': 'rep_${replies.length}',
        'body': data!['body'],
        'kind': data['kind'],
        'translationKo': data['translationKo'],
        'summaryKo': data['summaryKo'],
        'aiAssisted': data['aiAssisted'] == true,
        'recordedAt': '2026-11-20T00:00:00Z',
      });
      this.version += 1;
      return {'claim': claim};
    }
    // 새 신청: 시험에서는 같은 건을 돌려준다 (파일은 이어서 따로 올린다)
    if (method == 'POST' && path == '/api/claims') return {'claim': claim};
    refuse(404, 'not_found', '없는 주소예요.');
  }
}

/// 서버에 붙지 못한 것처럼 구는 가짜 (체험 모드)
class OfflineApi extends ReloApiClient {
  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
    List<int>? rawBytes,
    Map<String, String>? headers,
    int? version,
    String? idempotencyKey,
  }) async {
    throw const ApiError('연결하지 못했어요.', code: 'network');
  }
}

/// 다른 앱의 공유 대신: 넣어 둔 파일을 한 번 돌려준다
class FakeSharedInbox implements SharedEvidenceInbox {
  PickedEvidence? waiting;
  void Function()? onArrived;

  @override
  Future<PickedEvidence?> take() async {
    final evidence = waiting;
    waiting = null;
    return evidence;
  }

  @override
  void setOnArrived(void Function()? handler) => onArrived = handler;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ReloStore> connected(FakeServer server) async {
    final store = ReloStore(api: server)..showAssistantButton = false;
    await pumpEventQueue();
    return store;
  }

  group('저장소', () {
    test('맡기면 허락이 필요한 일에서 멈추고, 허락하기 전에는 건이 그대로다', () async {
      final server = FakeServer();
      final store = await connected(server);
      expect(store.agentAvailableFor(store.findClaim(claimId)!), isTrue);

      final run = await store.runAgent(claimId);
      expect(run.isWaiting, isTrue);
      expect(run.pending!.tool, 'fix_order_facts');
      expect(run.pending!.changes.single.to, 'EG-2026-1001');
      expect(run.steps.single.mismatches.single.saved, 'EG-2026-1010');
      expect(store.findClaim(claimId)!.orderRef, 'EG-2026-1010');
      expect(store.agentWaitingClaimIds, {claimId});
      // 화면의 언어를 함께 보낸다
      expect(server.posted('/ai/agent').single.data, {'locale': 'ko'});
    });

    test('허락하면 서버가 그 일을 하고, 앱은 건을 다시 받아 온다', () async {
      final server = FakeServer();
      final store = await connected(server);
      final run = await store.runAgent(claimId);

      final next = await store.decideAgent(claimId, run.runId, approve: true);
      expect(next.isWaiting, isFalse);
      expect(next.endedBy, 'done');
      expect(next.steps[1].decision, 'approved');
      expect(server.posted('/decision').single.data, {'approve': true, 'locale': 'ko'});
      expect(store.findClaim(claimId)!.orderRef, 'EG-2026-1001');
      expect(store.agentWaitingClaimIds, isEmpty);
    });

    test('하지 않기를 누르면 아무것도 바뀌지 않는다', () async {
      final server = FakeServer();
      final store = await connected(server);
      final run = await store.runAgent(claimId);

      final next = await store.decideAgent(claimId, run.runId, approve: false);
      expect(next.steps[1].decision, 'declined');
      expect(store.findClaim(claimId)!.orderRef, 'EG-2026-1010');
      expect(store.agentWaitingClaimIds, isEmpty);
    });

    test('서버가 없으면 에이전트도 없다: 앱이 대신 지어내지 않는다', () async {
      final store = ReloStore(api: OfflineApi())..showAssistantButton = false;
      await pumpEventQueue();
      final claim = store.claims.first;
      expect(store.agentAvailableFor(claim), isFalse);
      await expectLater(
        store.runAgent(claim.id),
        throwsA(isA<AiUnavailable>()
            .having((e) => e.message, 'message', store.strings.aiNoServer)),
      );
      // 스스로 시작하기도 기기 안에서만 켜진 것처럼 보이지 않는다
      await expectLater(store.setAgentAuto(true), throwsA(isA<ApiError>()));
      expect(store.agentAutoOn, isFalse);
    });

    test('서버가 거절하면 그 까닭을 그대로 알린다', () async {
      final server = FakeServer()..aiLimited = true;
      final store = await connected(server);
      await expectLater(
        store.runAgent(claimId),
        throwsA(isA<AiUnavailable>()
            .having((e) => e.message, 'message', contains('횟수를 넘었어요'))),
      );
      expect(store.agentWaitingClaimIds, isEmpty);
    });

    test('스스로 시작하기는 처음에 꺼져 있고, AI 동의가 있어야 켜지고, 동의를 끄면 함께 꺼진다', () async {
      final server = FakeServer(consent: false);
      final store = await connected(server);
      expect(store.agentAutoOn, isFalse);

      await expectLater(store.setAgentAuto(true), throwsA(isA<ApiError>()));
      expect(store.agentAutoOn, isFalse);

      await store.toggleAiConsent();
      await store.setAgentAuto(true);
      expect(store.agentAutoOn, isTrue);
      expect(server.posted('/api/account/agent-auto').last.data, {'on': true});

      await store.toggleAiConsent();
      expect(store.user!.aiConsentAt, isNull);
      expect(store.agentAutoOn, isFalse);
    });

    test('언어를 바꾸면 저장하는 요청에 실어 보낼 언어도 바뀐다', () async {
      final server = FakeServer();
      final store = await connected(server);
      expect(server.locale, 'ko');
      store.setLocale(ReloLocale.ja);
      expect(server.locale, 'ja');
    });

    test('신청을 채울 때 금액은 AI에 보내지 않고, 읽은 값을 그대로 돌려준다', () async {
      final server = FakeServer();
      final store = await connected(server);
      final read = await store.fillRequestWithAi(
        file: EvidenceRules.prepare(
            name: 'order.pdf', bytes: '%PDF-1.7 order'.codeUnits),
        text: '허브 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.',
      );
      expect(read.order!.orderRef, 'EG-2026-1001');
      expect(read.order!.items.first.unitPrice, '39.90');
      expect(read.intake!.kind, 'refund');
      expect(read.intake!.itemIndex, 0);
      final sent = server.posted('/api/ai/intake').single.data!;
      expect(sent['items'], [
        {'name': 'USB-C Hub 7-in-1', 'orderedQty': 2},
        {'name': 'HDMI Cable 2m', 'orderedQty': 1},
      ]);
      expect(sent.toString(), isNot(contains('39.90')));
    });

    test('알림 메일은 서버가 받아야 꺼지고 켜진다: 기기 안에서만 바뀐 것처럼 보이지 않는다', () async {
      final server = FakeServer(auto: true);
      final store = await connected(server);
      expect(store.noticeMailOn, isTrue, reason: '처음에는 받는다');

      await store.setNoticeMail(false);
      expect(store.noticeMailOn, isFalse);
      expect(server.posted('/api/account/notice-mail').single.data, {'on': false});
      expect(store.agentAutoOn, isTrue, reason: '메일만 끈 것이다');

      // 서버가 받지 못하면 그대로다
      server.failNoticeMail = true;
      await expectLater(store.setNoticeMail(true), throwsA(isA<ApiError>()));
      expect(store.noticeMailOn, isFalse);

      // 서버가 없으면(체험 모드) 켜고 끌 수 없다
      final offline = ReloStore(api: OfflineApi())..showAssistantButton = false;
      await pumpEventQueue();
      await expectLater(offline.setNoticeMail(false), throwsA(isA<ApiError>()));
    });

    test('서버 없이 신청하면 올리지 않은 파일도, 적지 않은 영어 문장도 생기지 않는다', () async {
      final store = ReloStore(api: OfflineApi())..showAssistantButton = false;
      await pumpEventQueue();
      final created = await store.createClaimFromWizard(
        vendor: 'Amazon US',
        orderRef: '114-0000000-0000001',
        orderedOn: '2026-11-01',
        title: '무선 헤드폰',
        orderedQty: 1,
        claimQty: 1,
        currency: 'USD',
        claimedAmount: '289.00',
        kind: 'refund',
        issue: '전원이 켜지지 않아요.',
        issueEnglish: '',
        stagedFiles: const [],
      );
      expect(created.files, isEmpty);
      expect(created.issueEnglish, '');
    });

    test('신청은 저장됐는데 서버가 파일을 받지 못하면, 받지 못한 파일을 적어 둔다', () async {
      final server = FakeServer()..failUploads = true;
      final store = await connected(server);
      await store.createClaimFromWizard(
        vendor: 'Example Gadgets EU',
        orderRef: 'EG-2026-1001',
        orderedOn: '2026-10-01',
        title: 'USB-C Hub 7-in-1',
        orderedQty: 2,
        claimQty: 1,
        currency: 'EUR',
        claimedAmount: '39.90',
        kind: 'refund',
        issue: '전원이 켜지지 않아요.',
        issueEnglish: '',
        stagedFiles: const [
          StagedEvidenceFile(
            id: 'stg_1',
            name: '박스 사진.jpg',
            mime: 'image/jpeg',
            bytes: [0xFF, 0xD8, 0xFF, 0xE0],
            addressMasked: false,
          ),
        ],
      );
      expect(store.wizardFilesNotSaved, ['박스 사진.jpg']);

      // 다음 신청에서 다 올라가면 비워진다
      server.failUploads = false;
      await store.createClaimFromWizard(
        vendor: 'Example Gadgets EU',
        orderRef: 'EG-2026-1002',
        orderedOn: '2026-10-01',
        title: 'USB-C Hub 7-in-1',
        orderedQty: 2,
        claimQty: 1,
        currency: 'EUR',
        claimedAmount: '39.90',
        kind: 'refund',
        issue: '전원이 켜지지 않아요.',
        issueEnglish: '',
        stagedFiles: const [],
      );
      expect(store.wizardFilesNotSaved, isEmpty);
    });
  });

  group('화면', () {
    Future<ReloStore> startApp(
      WidgetTester tester,
      ReloApiClient api, {
      SharedEvidenceInbox? inbox,
    }) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = ReloStore(api: api, sharedInbox: inbox)
        ..showAssistantButton = false;
      await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      return store;
    }

    // 말랑이가 계속 움직이는 화면에서는 pumpAndSettle 대신 시간을 정해 돌린다
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
    }

    testWidgets('상세에서 맡기면 동의부터 묻고, 허락을 받아 고치고, 쓴 글은 내 이름으로 메시지 칸에 넣는다', (tester) async {
      final server = FakeServer(consent: false);
      final store = await startApp(tester, server);
      store.openClaimDetail(claimId);
      await settle(tester);

      // 상세의 한 줄: 목표가 적혀 있다
      expect(find.text('AI에게 맡기기'), findsOneWidget);
      expect(find.text('목표 · €39.90 환불 받기'), findsOneWidget);
      await tester.tap(find.text('AI에게 맡기기'));
      await settle(tester);
      expect(find.textContaining('쇼핑몰에 보내는 일은 하지 않아요'), findsOneWidget);
      // 스스로 시작하기는 처음에 꺼져 있다
      expect(find.text('스스로 시작하기 켜기'), findsOneWidget);

      // 동의하기 전에는 AI에 보내지 않는다
      await tester.tap(find.widgetWithText(ReloButton, 'AI에게 맡기기'));
      await settle(tester);
      expect(find.text('AI 처리에 동의하면 시작할 수 있어요'), findsOneWidget);
      expect(server.posted('/ai/agent'), isEmpty);
      await tester.tap(find.text('동의하고 시작하기'));
      await settle(tester);

      // AI가 고른 일과 까닭, 그리고 허락을 기다리는 일
      expect(find.text('AI가 한 일'), findsOneWidget);
      expect(find.textContaining('1. 올린 자료 읽기'), findsOneWidget);
      expect(find.text('고른 까닭: 올린 자료가 있어서 먼저 읽어요.'), findsOneWidget);
      expect(find.text('허락이 필요해요'), findsOneWidget);
      expect(find.text('주문번호: EG-2026-1010 → EG-2026-1001'), findsOneWidget);
      expect(store.findClaim(claimId)!.orderRef, 'EG-2026-1010',
          reason: '허락하기 전에는 그대로다');

      await tester.tap(find.text('허락하기'));
      await settle(tester);
      expect(store.findClaim(claimId)!.orderRef, 'EG-2026-1001');
      expect(find.text('허락해서 했어요.'), findsOneWidget);
      expect(find.text('허락이 필요해요'), findsNothing);
      expect(find.textContaining('쇼핑몰에는 아무것도 보내지 않았어요'), findsOneWidget);
      expect(find.text('다시 맡기기'), findsOneWidget);

      // AI가 쓴 글을 메시지 칸에 넣는다: 끝의 [이름]은 기기에서 내 이름으로 채운다
      await tester.ensureVisible(find.text('이 글을 메시지 칸에 넣기'));
      await tester.tap(find.text('이 글을 메시지 칸에 넣기'));
      await settle(tester);
      expect(find.text('AI가 한 일'), findsNothing, reason: '시트가 닫혔다');
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'AI로 쓰기를 누르면 판매자 나라 말로 써 드려요'),
      );
      expect(field.controller!.text, endsWith('Thank you,\n김직구'));
      expect(field.controller!.text, isNot(contains('[이름]')));
      // 넣기만 했다: 저장은 사람이 한다
      expect(server.asked.where((a) => a.path.endsWith('/drafts')), isEmpty);
    });

    testWidgets('켜 두면 자료를 올렸을 때 AI가 스스로 살펴보고, 물어볼 것이 생기면 목록과 상세에 알린다', (tester) async {
      final server = FakeServer(auto: true);
      final store = await startApp(tester, server);

      // 서버: 자료가 올라와서 곧 스스로 시작한다
      server.working = true;
      await store.uploadClaimFile(
        claimId: claimId,
        fileName: 'photo.jpg',
        mime: 'image/jpeg',
        bytes: const [255, 216, 255, 224, 1, 2, 3],
      );
      await tester.pump();
      expect(store.agentOverviews[claimId]!.working, isTrue);

      store.openClaimDetail(claimId);
      await settle(tester);
      expect(find.text('AI가 살펴보고 있어요…'), findsOneWidget);

      // 서버: 살펴보다가 주문번호를 고치자고 내놓고 멈췄다
      server
        ..working = false
        ..waiting = server.waitingRun(startedBy: 'file');
      await tester.pump(const Duration(seconds: 2));
      await settle(tester);
      expect(store.agentWaitingClaimIds, {claimId});
      expect(find.text('AI가 물어볼 것이 있어요'), findsOneWidget);
      expect(store.findClaim(claimId)!.orderRef, 'EG-2026-1010',
          reason: '스스로 시작해도 허락 없이는 바꾸지 않는다');

      await tester.tap(find.text('AI가 물어볼 것이 있어요'));
      await settle(tester);
      expect(find.text('자료가 올라와서 AI가 스스로 시작했어요.'), findsOneWidget);
      expect(find.text('허락이 필요해요'), findsOneWidget);
      // 켜져 있을 때는 끄는 글자가 보인다
      expect(find.text('끄기'), findsOneWidget);
      await tester.tap(find.text('하지 않기'));
      await settle(tester);
      expect(find.text('허락하지 않아서 그대로 뒀어요.'), findsOneWidget);
      expect(store.agentWaitingClaimIds, isEmpty);
    });

    testWidgets('앱을 떠나 있던 동안 AI가 물어볼 것이 생겼으면, 돌아왔을 때 바로 알린다', (tester) async {
      final server = FakeServer(auto: true);
      final store = await startApp(tester, server);
      store.resumeRefreshAfter = Duration.zero;
      store.navigateToTab(2);
      await settle(tester);
      expect(find.text('AI가 물어볼 것이 있어요'), findsNothing);

      // 다른 앱을 보는 동안, 스스로 시작한 AI가 허락이 필요한 일에서 멈췄다
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      server.waiting = server.waitingRun(startedBy: 'file');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(store.agentWaitingClaimIds, {claimId});
      expect(find.text('AI가 물어볼 것이 있어요'), findsOneWidget);
    });

    test('잠깐 나갔다 온 것은 다시 받아 오지 않고, 오래 비웠을 때만 받아 온다', () async {
      final server = FakeServer(auto: true);
      final store = await connected(server);
      final asked = server.asked.length;
      final left = DateTime(2026, 11, 20, 10);

      store.appPaused(now: left);
      await store.appResumed(now: left.add(const Duration(seconds: 5)));
      expect(server.asked.length, asked, reason: '사진을 고르고 온 정도');

      store.appPaused(now: left);
      server.waiting = server.waitingRun(startedBy: 'reply');
      await store.appResumed(now: left.add(const Duration(minutes: 3)));
      expect(store.agentWaitingClaimIds, {claimId});

      // 떠난 적이 없으면 아무 일도 하지 않는다
      final again = server.asked.length;
      await store.appResumed(now: left.add(const Duration(hours: 1)));
      expect(server.asked.length, again);
    });

    // 영어 · 일본어 · 중국어: 글자가 길어지거나 줄바꿈이 달라져도, 좁은 폰(360px)과 큰 글자(1.3배)에서
    // 넘치는 줄이 없어야 한다. (넘치면 Flutter가 오류를 내서 이 시험이 떨어진다.)
    for (final locale in [ReloLocale.en, ReloLocale.ja, ReloLocale.zh]) {
      testWidgets('${locale.code}: 좁은 화면 · 큰 글자에서도 AI 화면들이 그 언어로 다 그려진다', (tester) async {
        final server = FakeServer(auto: true);
        server.waiting = server.waitingRun(startedBy: 'file');
        final store = await startApp(tester, server);
        tester.view.physicalSize = const Size(360, 740);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        store.setLocale(locale);
        await settle(tester);
        final s = store.strings;

        // 목록: AI가 기다린다는 한 줄
        store.navigateToTab(2);
        await settle(tester);
        expect(find.text(s.agAsks), findsOneWidget);

        // 상세의 한 줄 → 시트: 무엇을 허락하는지, 그리고 두 버튼
        store.openClaimDetail(claimId);
        await settle(tester);
        await tester.ensureVisible(find.text(s.agTitle));
        await tester.tap(find.text(s.agTitle));
        await settle(tester);
        expect(find.text(s.agApprovalTitle), findsOneWidget);
        expect(find.text(s.agStartedBy('file')), findsOneWidget);
        expect(find.text(s.agApprove), findsOneWidget);
        expect(find.text(s.agDecline), findsOneWidget);

        // 허락한 뒤: 결론과 AI가 한 일
        await tester.tap(find.text(s.agApprove));
        await settle(tester);
        expect(find.textContaining(s.agNextTitle, findRichText: true), findsOneWidget);
        expect(find.text(s.agResultTitle), findsOneWidget);
        expect(find.text(s.agAgain), findsOneWidget);
        // 아래까지 내려 본다 (스스로 시작하기 줄과 쓴 글 넣기)
        await tester.ensureVisible(find.text(s.agUseDraft));
        await tester.ensureVisible(find.text(s.agAutoTurnOff));
        await settle(tester);
        Navigator.of(tester.element(find.text(s.agResultTitle))).pop();
        await settle(tester);

        // 설정: 스스로 시작하기와 알림 메일
        store.navigateToTab(4);
        await settle(tester);
        await tester.ensureVisible(find.text(s.stAgentAuto));
        expect(find.text(s.stAgentAutoSub), findsOneWidget);
        await tester.ensureVisible(find.text(s.stEmail));
        expect(find.text(s.stEmailOn), findsOneWidget);

        // 약관 · 정책의 메일 안내
        store.openLegalDocument('sdk');
        await tester.pumpAndSettle();
        expect(find.text(s.lgMailFacts), findsOneWidget);

        // 신청 1단계: AI가 채워 주기, 그리고 빈 칸으로 다음을 눌렀을 때의 안내
        store.navigateToTab(1);
        await tester.pumpAndSettle();
        expect(find.text(s.wIntakeTitle), findsOneWidget);
        expect(find.text(s.wIntakeRun), findsOneWidget);
        await tester.tap(find.text(s.wNext));
        await tester.pumpAndSettle();
        expect(find.text(s.wErrVendorPick), findsOneWidget);
        expect(find.text(s.wErrOrderRef), findsOneWidget);
        // AI가 채운 뒤의 마지막 확인
        await tester.enterText(find.byType(EditableText).at(0), 'One of the two hubs is dead. Refund please.');
        await tester.ensureVisible(find.text(s.wIntakeRun));
        await tester.pumpAndSettle();
        await tester.tap(find.text(s.wIntakeRun));
        await tester.pumpAndSettle();
        expect(find.text(s.wIntakeLineOnly), findsOneWidget);
      });
    }

    testWidgets('내 환불 목록에서 AI가 기다리는 건을 알린다', (tester) async {
      final server = FakeServer()..waiting = FakeServer().waitingRun();
      final store = await startApp(tester, server);
      store.navigateToTab(2);
      await settle(tester);
      expect(find.text('AI가 물어볼 것이 있어요'), findsOneWidget);
    });

    testWidgets('서버가 없으면(체험 모드) AI에게 맡기기와 스스로 시작하기를 보여 주지 않는다', (tester) async {
      final store = await startApp(tester, OfflineApi());
      store.openClaimDetail(store.claims.first.id);
      await settle(tester);
      expect(find.text('AI에게 맡기기'), findsNothing);
      store.navigateToTab(4);
      await settle(tester);
      expect(find.text('AI 기능 쓰기'), findsOneWidget);
      expect(find.text('AI가 스스로 시작하기'), findsNothing);
    });

    testWidgets('설정의 스스로 시작하기는 꺼져 있고, 켤 때 동의부터 받고, AI 동의를 끄면 함께 꺼진다', (tester) async {
      final server = FakeServer(consent: false);
      final store = await startApp(tester, server);
      store.navigateToTab(4);
      await settle(tester);

      await tester.ensureVisible(find.text('AI가 스스로 시작하기'));
      expect(store.agentAutoOn, isFalse);
      expect(find.textContaining('Google의 AI로 보내져요'), findsOneWidget);

      await tester.tap(find.text('AI가 스스로 시작하기'));
      await settle(tester);
      expect(find.text('AI 처리에 동의하면 시작할 수 있어요'), findsOneWidget);
      expect(server.posted('/api/account/agent-auto'), isEmpty);

      // 그만두면 켜지지 않는다
      await tester.tap(find.text('다음에 하기'));
      await settle(tester);
      expect(store.agentAutoOn, isFalse);
      expect(server.posted('/api/account/agent-auto'), isEmpty);

      await tester.tap(find.text('AI가 스스로 시작하기'));
      await settle(tester);
      await tester.tap(find.text('동의하고 시작하기'));
      await settle(tester);
      expect(store.agentAutoOn, isTrue);
      expect(find.text('켰어요. 이제 일이 생기면 AI가 스스로 시작해요.'), findsOneWidget);

      await tester.tap(find.text('AI 기능 쓰기'));
      await settle(tester);
      expect(store.user!.aiConsentAt, isNull);
      expect(store.agentAutoOn, isFalse);
    });

    testWidgets('신청: 주문서와 한 줄이면 AI가 채우고 마지막 확인으로 간다. 등록 전에는 저장되지 않는다', (tester) async {
      final server = FakeServer();
      final inbox = FakeSharedInbox();
      final store = await startApp(tester, server, inbox: inbox);

      inbox.waiting = EvidenceRules.prepare(
          name: 'Order Confirmation.pdf', bytes: '%PDF-1.7 order'.codeUnits);
      inbox.onArrived!();
      await tester.pumpAndSettle();
      expect(store.activeTabIndex, 1);
      expect(find.text('AI가 채워 주기'), findsOneWidget);
      expect(find.text('Order Confirmation.pdf'), findsOneWidget);
      // 파일을 붙이기만 해서는 AI에 보내지 않는다
      expect(server.posted('/api/ai/extract'), isEmpty);

      await tester.enterText(
        find.widgetWithText(TextField, '예: 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.'),
        '허브 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.',
      );
      await tester.tap(find.text('AI가 채우기'));
      await tester.pumpAndSettle();

      // 빈 칸이 없어서 바로 마지막 확인으로 왔다
      expect(find.text('마지막으로 확인해요'), findsOneWidget);
      expect(find.textContaining('AI가 주문서와 적은 내용으로 채웠어요'), findsOneWidget);
      expect(find.text('Example Gadgets EU'), findsOneWidget);
      expect(find.text('EG-2026-1001'), findsOneWidget);
      expect(find.text('USB-C Hub 7-in-1'), findsOneWidget);
      // 금액은 주문서의 한 개 값 × 수량 (39.90 × 1)
      expect(find.text('€39.90 EUR'), findsOneWidget);
      expect(find.text('반품 · 환불'), findsOneWidget);
      expect(find.text('허브 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.'), findsOneWidget);
      // 등록하기 전에는 아무것도 저장되지 않는다
      expect(server.posted('/api/claims'), isEmpty);

      // 첫 단계로 돌아가도 AI가 채웠다는 것과 어떻게 이해했는지가 남아 있다
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('이전 단계'));
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('AI가 채운 값이에요'), findsOneWidget);
      expect(find.textContaining('AI가 이렇게 이해했어요: 허브 2개 가운데 1개'), findsOneWidget);
    });

    testWidgets('신청: 아무것도 없으면 보내지 않고, 한 줄만 있으면 주문 정보는 직접 적으라고 한다', (tester) async {
      final server = FakeServer();
      final store = await startApp(tester, server);
      store.navigateToTab(1);
      await tester.pumpAndSettle();

      await tester.tap(find.text('AI가 채우기'));
      await tester.pumpAndSettle();
      expect(find.text('주문서를 고르거나 무슨 일인지 적어 주세요.'), findsOneWidget);
      expect(server.posted('/api/ai/intake'), isEmpty);

      await tester.enterText(
        find.widgetWithText(TextField, '예: 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.'),
        '케이블이 휘어서 왔어요. 새 걸로 바꿔 주세요.',
      );
      await tester.tap(find.text('AI가 채우기'));
      await tester.pumpAndSettle();
      expect(find.text('어디서 샀어요?'), findsOneWidget, reason: '첫 단계에 머문다');
      expect(
        find.text('적은 내용으로 해결 방법과 문제 설명을 채웠어요. 주문 정보는 직접 적어 주세요.'),
        findsOneWidget,
      );
      expect(server.posted('/api/ai/extract'), isEmpty);
      expect(server.posted('/api/ai/intake').single.data!['items'], isEmpty);
    });

    testWidgets('신청: AI가 읽지 못하면 값을 지어내지 않고 까닭만 말한다', (tester) async {
      final server = FakeServer()..aiLimited = true;
      final store = await startApp(tester, server);
      store.navigateToTab(1);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '예: 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.'),
        '허브가 안 켜져요. 환불받고 싶어요.',
      );
      await tester.tap(find.text('AI가 채우기'));
      await tester.pumpAndSettle();
      expect(find.text('한 시간에 쓸 수 있는 AI 횟수를 넘었어요.'), findsOneWidget);
      expect(find.textContaining('AI가 채운 값이에요'), findsNothing);
      expect(find.text('어디서 샀어요?'), findsOneWidget);
    });

    testWidgets('답장: AI를 쓰지 않고 저장하면 AI가 도왔다고 적지 않고, 원문을 번역 칸에 넣지 않는다', (tester) async {
      final server = FakeServer();
      final store = await startApp(tester, server);
      store.openClaimDetail(claimId, subTab: 1);
      await tester.pumpAndSettle();
      const reply = 'Please send a photo of the defective unit.';
      final field = find.widgetWithText(TextField, '판매자가 보낸 답장을 붙여 넣어 주세요');

      await tester.enterText(field, reply);
      await tester.ensureVisible(find.text('저장하기'));
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();
      final saved = server.posted('/replies').single.data!;
      expect(saved['aiAssisted'], isFalse);
      expect(saved['summaryKo'], '');
      expect(saved['translationKo'], '', reason: '영어 원문은 한국어 번역이 아니다');
      // 저장한 답장은 원문 그대로 보이고, AI가 만들었다는 표시는 없다
      expect(find.text('저장한 답장'), findsOneWidget);
      expect(find.textContaining('AI가 요약하고 옮긴 내용이에요'), findsNothing);
    });

    testWidgets('답장: AI가 읽은 글 그대로 저장할 때만 AI의 요약을 붙이고 AI가 했다고 적는다', (tester) async {
      final server = FakeServer();
      final store = await startApp(tester, server);
      store.openClaimDetail(claimId, subTab: 1);
      await tester.pumpAndSettle();
      const reply = 'Please send a photo of the defective unit.';
      final field = find.widgetWithText(TextField, '판매자가 보낸 답장을 붙여 넣어 주세요');

      await tester.enterText(field, reply);
      await tester.tap(find.text('AI로 요약'));
      await tester.pumpAndSettle();
      expect(find.text('불량품의 사진을 보내 달라고 해요.'), findsOneWidget);
      expect(find.textContaining('AI가 요약하고 옮긴 내용이에요'), findsOneWidget);

      // 읽은 뒤에 글을 고치면, 그 요약은 이 글의 것이 아니다: 붙이지 않는다
      await tester.enterText(field, '$reply Also the box.');
      await tester.ensureVisible(find.text('저장하기'));
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();
      expect(server.posted('/replies').last.data!['aiAssisted'], isFalse);
      expect(server.posted('/replies').last.data!['summaryKo'], '');

      // 다시 읽게 하고 그대로 저장하면 붙는다
      await tester.ensureVisible(find.text('AI로 요약'));
      await tester.tap(find.text('AI로 요약'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('저장하기'));
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();
      final saved = server.posted('/replies').last.data!;
      expect(saved['aiAssisted'], isTrue);
      expect(saved['summaryKo'], '불량품의 사진을 보내 달라고 해요.');
      expect(saved['translationKo'], '불량품의 사진을 보내 주세요.');
      expect(find.textContaining('AI가 요약하고 옮긴 내용이에요'), findsOneWidget);
    });

    testWidgets('설정의 알림 메일 스위치는 스스로 시작하기를 켰을 때만 보이고, 서버가 받아야 바뀐다', (tester) async {
      final server = FakeServer();
      final store = await startApp(tester, server);
      store.navigateToTab(4);
      await settle(tester);
      expect(find.text('알림 메일 받기'), findsNothing, reason: '보낼 메일이 없을 때는 스위치도 없다');

      await store.setAgentAuto(true);
      await settle(tester);
      await tester.ensureVisible(find.text('알림 메일 받기'));
      expect(find.textContaining('메일에는 주문 내용을 적지 않아요'), findsOneWidget);

      await tester.tap(find.text('알림 메일 받기'));
      await settle(tester);
      expect(server.posted('/api/account/notice-mail').single.data, {'on': false});
      expect(store.noticeMailOn, isFalse);
      expect(find.textContaining('AI가 허락을 기다려도 메일을 보내지 않아요'), findsOneWidget);

      // 서버가 받지 못하면 스위치는 그대로이고, 못 했다고 알린다
      server.failNoticeMail = true;
      await tester.tap(find.text('알림 메일 받기'));
      await settle(tester);
      expect(store.noticeMailOn, isFalse);
      expect(find.text('알림 메일 설정을 바꾸지 못했어요. 잠시 후 다시 해 보세요.'), findsOneWidget);

      // 이메일 인증 전이면 보낸다고 약속하지 않는다
      server
        ..failNoticeMail = false
        ..emailVerified = false;
      await tester.tap(find.text('알림 메일 받기'));
      await settle(tester);
      expect(store.noticeMailOn, isTrue);
      expect(find.textContaining('이메일 인증 전이라 지금은 알림 메일을 보내지 않아요'), findsOneWidget);
    });

    testWidgets('신청은 빈 칸으로 열린다: 예시 주문도, 예시 파일도 없다', (tester) async {
      final server = FakeServer();
      final store = await startApp(tester, server);
      store.navigateToTab(1);
      await tester.pumpAndSettle();
      for (final example in [
        '114-8920411-33012',
        'Sony WH-1000XM5 무선 노이즈캔슬링 헤드폰',
        '289.00',
      ]) {
        expect(find.text(example), findsNothing);
      }
      // 아무 쇼핑몰도 골라져 있지 않다
      expect(
        tester
            .widgetList<ReloChoiceChip>(find.byType(ReloChoiceChip))
            .where((chip) => chip.selected),
        isEmpty,
      );
      // 채우지 않고는 넘어가지 않는다
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('어디서 샀어요?'), findsOneWidget);
      expect(find.text('쇼핑몰을 골라 주세요.'), findsOneWidget);
      expect(server.posted('/api/claims'), isEmpty);
    });

    testWidgets('신청을 마쳤는데 올리지 못한 파일이 있으면 그렇다고 알린다', (tester) async {
      final server = FakeServer()..failUploads = true;
      final inbox = FakeSharedInbox();
      final store = await startApp(tester, server, inbox: inbox);
      inbox.waiting = EvidenceRules.prepare(
          name: 'Order Confirmation.pdf', bytes: '%PDF-1.7 order'.codeUnits);
      inbox.onArrived!();
      await tester.pumpAndSettle();
      expect(store.activeTabIndex, 1);

      await wizardToStep(tester, 5);
      expect(find.text('마지막으로 확인해요'), findsOneWidget);
      for (final consent in find.byType(ReloConsentRow).evaluate().toList()) {
        await tester.ensureVisible(find.byWidget(consent.widget));
        await tester.tap(find.byWidget(consent.widget));
        await tester.pump();
      }
      await tester.tap(find.text('환불 신청 등록하기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      expect(server.posted('/api/claims'), hasLength(1));
      expect(
        find.text('신청은 저장했지만 파일 1개는 올리지 못했어요. 이 건을 열어 다시 올려 주세요.'),
        findsOneWidget,
      );
    });
  });
}
