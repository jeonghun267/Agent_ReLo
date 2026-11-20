import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:relo_flutter/core/attachments/evidence_rules.dart';
import 'package:relo_flutter/core/network/api_client.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI가 답하지 못했을 때 앱이 그럴듯한 답을 지어내지 않는지 본다.
/// (전에는 어떤 답장이든 "환불을 약속했습니다"로 요약하고, 미리 써 둔 영어 문장을 번역이라고 돌려줬다.)

/// 서버에 붙지 못한 것처럼 구는 가짜
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

/// AI 요청은 까닭을 적어 거절하고(한도 초과), 기본 틀은 돌려주는 가짜 서버
class LimitedApi extends ReloApiClient {
  final List<String> asked = [];

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
    asked.add('$method $path');
    if (path.endsWith('/draft-template')) {
      return {'body': 'TEMPLATE FROM SERVER'};
    }
    throw const ApiError(
      '한 시간에 쓸 수 있는 AI 횟수를 넘었어요.',
      code: 'ai_rate_limited',
      status: 429,
      explained: true,
    );
  }
}

const refundId = 'clm_amz_xm5';

Matcher unavailable([String? containing]) => throwsA(
      isA<AiUnavailable>().having(
        (e) => e.message,
        'message',
        containing == null ? isNotEmpty : contains(containing),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ReloStore storeWith(ReloApiClient api) =>
      ReloStore(api: api)..showAssistantButton = false;

  /// 서버에는 붙어 있는데 AI만 거절하는 상태. 켜질 때의 연결 시도가 끝난 뒤 "붙어 있음"으로 둔다.
  Future<ReloStore> connectedStore(LimitedApi api) async {
    final store = storeWith(api);
    await pumpEventQueue();
    store.isOfflineFallback = false;
    api.asked.clear();
    return store;
  }

  group('답장 분석', () {
    test('서버에 붙지 못하면 요약과 약속 금액을 지어내지 않는다', () async {
      final store = storeWith(OfflineApi());
      final claim = store.findClaim(refundId)!;
      await expectLater(
        store.analyzeSellerReply(claim, 'We cannot refund order 150.'),
        unavailable(),
      );
    });

    test('서버가 거절하면 그 까닭을 그대로 알린다', () async {
      final store = await connectedStore(LimitedApi());
      final claim = store.findClaim(refundId)!;
      await expectLater(
        store.analyzeSellerReply(claim, 'We cannot refund order 150.'),
        unavailable('횟수를 넘었어요'),
      );
    });

    test('AI 도우미가 꺼져 있으면 서버에 보내지 않고 꺼져 있다고 알린다', () async {
      final api = LimitedApi();
      final store = await connectedStore(api)
        ..sdkAiEnabled = false;
      final claim = store.findClaim(refundId)!;
      await expectLater(
        store.analyzeSellerReply(claim, 'Refund approved.'),
        unavailable(store.strings.aiOff),
      );
      expect(api.asked, isEmpty);
    });
  });

  group('문제 설명 번역', () {
    test('옮기지 못하면 미리 써 둔 영어 문장을 돌려주지 않는다', () async {
      final store = storeWith(OfflineApi());
      await expectLater(
        store.translateIssueToEnglish('상자가 깨진 채로 왔어요'),
        unavailable(),
      );
    });
  });

  group('보낼 글', () {
    test('AI가 쓰지 못하면 기본 틀로 채우고 AI가 쓴 글이 아니라고 알린다', () async {
      final store = await connectedStore(LimitedApi());
      final draft = await store.generateForeignDraft(store.findClaim(refundId)!);
      expect(draft.byAi, isFalse);
      expect(draft.body, 'TEMPLATE FROM SERVER');
      expect(draft.notice, contains('횟수를 넘었어요'));
      expect(draft.notice, contains(store.strings.dDraftByTemplate));
    });

    test('서버가 없을 때의 기본 틀은 저장된 사실만 적고 사유를 지어내지 않는다', () async {
      final store = storeWith(OfflineApi());
      final claim = store.findClaim(refundId)!;
      final draft = await store.generateForeignDraft(claim);
      expect(draft.byAi, isFalse);
      expect(draft.notice, isNotNull);
      expect(draft.body, contains(claim.orderRef));
      // 사용자가 적지 않은 주장은 들어가지 않는다
      expect(draft.body, isNot(contains('damaged and defective')));
      expect(draft.body, isNot(contains('personal residential details')));
      expect(draft.body, isNot(contains('return shipping fees')));
      // 고객 자신의 이름으로 나가는 글이다: 끝에 계정의 이름이 있고, ReLo의 이름은 없다
      expect(draft.body, endsWith('Thank you,\n${store.user!.name}'));
      expect(draft.body, isNot(contains('[이름]')));
      expect(draft.body.toLowerCase(), isNot(contains('relo')));
      if (claim.issueEnglish.isEmpty) {
        expect(draft.body, contains('[Describe the problem in English.'));
      } else {
        expect(draft.body, contains(claim.issueEnglish));
      }
    });
  });

  group('영수증', () {
    test('읽지 못하면 예시 값을 지어내지 않고 못 읽었다고 알린다', () async {
      final store = storeWith(OfflineApi());
      await expectLater(
        store.fillRequestWithAi(
          file: PickedEvidence(
            name: 'Amazon_Order_Receipt.pdf',
            mime: 'application/pdf',
            bytes: Uint8List.fromList(const [37, 80, 68, 70]),
          ),
          text: '한쪽에서 소리가 안 나요. 환불받고 싶어요.',
        ),
        unavailable(),
      );
    });

    test('샘플 영수증은 서버에 보내지 않는다', () async {
      final api = LimitedApi();
      final store = await connectedStore(api);
      final sample = store.sampleReceipt('AliExpress_Order_Slip.jpg');
      expect(sample['vendor'], 'AliExpress');
      expect(api.asked, isEmpty);
    });
  });
}
