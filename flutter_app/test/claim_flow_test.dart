import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relo_flutter/core/i18n/relo_i18n.dart';
import 'package:relo_flutter/core/network/api_client.dart';
import 'package:relo_flutter/main.dart';
import 'package:relo_flutter/shared/models/claim_rules.dart';
import 'package:relo_flutter/shared/models/claim_words.dart';
import 'package:relo_flutter/shared/models/domain_models.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 환불 · 교환 · 수리 건이 막히지 않고 끝까지 가는지, 그리고 서버가 거절한 것을
/// 앱이 된 것처럼 보여 주지 않는지 본다.

/// 서버에 붙지 못한 것처럼 구는 가짜 (체험 모드: 기기 안에서만 바꾼다)
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

/// 무엇을 보내든 까닭을 적어 거절하는 가짜 서버
class RefusingApi extends ReloApiClient {
  final int status;
  final String code;
  final String message;
  final List<String> asked = [];
  RefusingApi({
    this.status = 422,
    this.code = 'validation',
    this.message = '서버가 받지 않았어요.',
  });

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
    throw ApiError(message, code: code, status: status, explained: true);
  }
}

const refundId = 'clm_amz_xm5'; // 환불 · 조율 중 · 약속 $150 · 받은 돈 없음
const exchangeId = 'clm_ali_kbd'; // 교환 1개 · 답변 대기

Matcher refuses([String? containing]) => throwsA(
      isA<ApiError>().having(
        (e) => e.message,
        'message',
        containing == null ? isNotEmpty : contains(containing),
      ),
    );

void main() {
  // 스토어는 만들어질 때 기기 채널(공유받은 파일)을 듣기 시작하므로, 먼저 시험용 바인딩을 세운다
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ReloStore offlineStore() =>
      ReloStore(api: OfflineApi())..showAssistantButton = false;

  group('규칙 (서버와 같다)', () {
    final store = offlineStore();
    final refund = store.findClaim(refundId)!;
    final exchange = store.findClaim(exchangeId)!;

    LedgerEntry entry(String id, String kind,
            {int amount = 0, int quantity = 0, String? reverses}) =>
        LedgerEntry(
          id: id,
          claimId: 'x',
          kind: kind,
          amount: amount,
          quantity: quantity,
          note: '',
          reverses: reverses,
          transactionRef: '',
          receivedOn: '2026-11-01',
          createdAt: '2026-11-01T00:00:00Z',
        );

    test('되돌린 기록은 세지 않고, 교환 · 수리는 받을 돈이 없다', () {
      final ledger = [
        entry('a', 'cash', amount: 15000),
        entry('b', 'reversal', amount: 15000, reverses: 'a'),
        entry('c', 'cash', amount: 5000),
      ];
      final totals = claimTotals(refund, ledger: ledger);
      expect(totals.cash, 5000);
      expect(totals.remaining, 10000);
      expect(receivedRows(ledger).map((r) => r.undone), [true, false]);
      expect(claimTotals(exchange).remaining, 0);
      expect(claimTotals(refund, kind: 'repair').remaining, 0);
    });

    test('"환불 처리했다"는 안내는 받은 것이 있으면 상태를 바꾸지 않는다', () {
      expect(stateAfterReply('refund_notice', 'negotiating'), 'awaiting');
      expect(stateAfterReply('refund_notice', 'partial'), 'partial');
      expect(stateAfterReply('refund_notice', 'recovered'), 'recovered');
      expect(stateAfterReply('denied', 'recovered'), 'disputed');
      expect(stateAfterReply('other', 'awaiting'), 'awaiting');
    });

    test('약속 금액을 묻는 것은 환불뿐이고, 교환은 받은 수량으로 센다', () {
      expect(nextStepCode(refund), 'needProof');
      expect(nextStepCode(exchange), 'awaiting');
      final got = exchange.copyWith(
        state: 'recovered',
        summary: claimTotals(exchange,
            ledger: [entry('g', 'goods', quantity: 1)]),
      );
      expect(isRecovered(got.kind, got.agreed, got.summary), true);
      expect(canFinishClaim(got), true);
      expect(canFinishClaim(exchange), false);
      expect(canEscalateClaim(exchange), true);
    });

    test('이의 제기 마감은 주문일부터 센다', () {
      final d = disputeDeadline('2026-10-01', cardDisputeWindowDays,
          today: DateTime(2026, 11, 16))!;
      expect(d.date, '2027-01-29');
      expect(d.daysLeft, 74);
      expect(disputeDeadline('어제', 120), isNull);
    });

    test('교환 · 수리 문구가 네 언어로 채워져 있고 돈 이야기를 하지 않는다', () {
      final hangul = RegExp('[가-힣]');
      for (final locale in ReloLocale.values) {
        final s = ReloStrings(locale);
        final texts = [
          for (final kind in ['refund', 'exchange', 'repair']) ...[
            s.cwPartial(kind),
            s.cwReceived(kind),
            s.cwTabReceive(kind),
            s.cwRecord(kind),
            s.cwCaption(kind),
            s.cwReplyKind(kind, 'agreement'),
            for (final code in [
              'trashed', 'waived', 'disputed', 'completed', 'recovered',
              'remaining', 'awaiting', 'needFiles', 'needMessage',
              'needAgreed', 'needProof',
            ])
              s.cwNextStep(kind, code),
          ],
          s.cwNoAnswer,
          s.cwUndo,
          s.dgTitle,
          s.dgStep2Body,
          s.disputeSummary(exchange),
        ];
        for (final text in texts) {
          expect(text.trim(), isNotEmpty, reason: '${locale.code} 비어 있음');
        }
        if (locale != ReloLocale.ko) {
          for (final text in [s.cwNoAnswer, s.cwUndo, s.dgTitle, s.cwFinish]) {
            expect(hangul.hasMatch(text), false, reason: '${locale.code}: $text');
          }
        }
      }
      const ko = ReloStrings(ReloLocale.ko);
      expect(ko.cwNextStep('exchange', 'needProof'), contains('교환품'));
      expect(ko.cwNextStep('repair', 'recovered'), contains('수리'));
      expect(ko.cwNextStep('refund', 'recovered'), contains('입금'));
    });
  });

  group('기기 안에서 (체험 모드)', () {
    test('번호 없는 입금은 메모와 확인이 있어야 기록된다', () async {
      final store = offlineStore();
      Future<void> record({String note = '', bool checked = false}) =>
          store.recordReceipt(
            claimId: refundId,
            receivedOn: '2026-11-10',
            amountStr: '150.00',
            note: note,
            noRefConfirmed: checked,
          );
      await expectLater(record(), refuses('메모'));
      await expectLater(record(note: '카드 앱 취소 내역에서 확인함'), refuses());
      expect(store.findClaim(refundId)!.summary.cash, 0);

      await record(note: '카드 앱 취소 내역에서 확인함', checked: true);
      final c = store.findClaim(refundId)!;
      expect([c.state, c.summary.cash, c.ledger.first.transactionRef],
          ['recovered', 15000, '']);
    });

    test('돈을 다 받은 뒤에는 환불 안내 답장을 저장해도 마무리할 수 있고, 잘못 적은 기록은 되돌린다', () async {
      final store = offlineStore();
      await store.recordReceipt(
        claimId: refundId,
        receivedOn: '2026-11-10',
        amountStr: '150.00',
        transactionRef: 'VISA-REF-001',
      );
      await store.saveReplyAndAgreedAmount(
        claimId: refundId,
        rawReply: 'Your refund has been processed.',
        replyKind: 'refund_notice',
        summaryKo: '',
        translationKo: '',
        agreedAmountStr: '',
        aiAssisted: false,
      );
      var c = store.findClaim(refundId)!;
      expect(c.state, 'recovered');
      expect(canFinishClaim(c), true);

      // 같은 입금 번호는 다른 건에도 두 번 적히지 않는다
      await expectLater(
        store.recordReceipt(
          claimId: 'clm_jp_mercari',
          receivedOn: '2026-11-10',
          amountStr: '1',
          transactionRef: 'visa-ref-001',
        ),
        refuses(),
      );

      await store.undoReceipt(
          claimId: refundId, entryId: c.ledger.first.id, reason: '금액을 잘못 적음');
      c = store.findClaim(refundId)!;
      expect([c.state, c.summary.cash, c.summary.remaining],
          ['negotiating', 0, 15000]);
      expect(receivedRows(c.ledger).single.undone, true);
      // 다 받지 못한 건은 마무리되지 않는다 (전에는 기기 안에서만 "완료"로 바뀌었다)
      await expectLater(store.completeClaim(refundId), refuses());
      expect(store.findClaim(refundId)!.state, 'negotiating');
    });

    test('일부만 받고 약속 금액을 받은 돈에 맞추면 마무리할 수 있다', () async {
      final store = offlineStore();
      await store.recordReceipt(
        claimId: refundId,
        receivedOn: '2026-11-10',
        amountStr: '100.00',
        transactionRef: 'VISA-REF-002',
      );
      expect(store.findClaim(refundId)!.state, 'partial');
      await expectLater(
        store.recordReceipt(
          claimId: refundId,
          receivedOn: '2026-11-11',
          amountStr: '80.00',
          transactionRef: 'VISA-REF-003',
        ),
        refuses('약속 금액'),
      );
      await store.saveReplyAndAgreedAmount(
        claimId: refundId,
        rawReply: 'We can only refund 100 USD.',
        replyKind: 'agreement',
        summaryKo: '',
        translationKo: '',
        agreedAmountStr: '100.00',
        aiAssisted: false,
      );
      expect(store.findClaim(refundId)!.state, 'recovered');
      await store.completeClaim(refundId);
      expect(store.findClaim(refundId)!.state, 'completed');
      // 마무리한 건은 다시 열어야 고칠 수 있다
      await store.transitionClaim(refundId, 'reopen', '기록을 고치려고 다시 엶');
      expect(store.findClaim(refundId)!.state, 'recovered');
    });

    test('답 없는 쇼핑몰은 분쟁 안내로 보내고, 다시 진행 · 그만두기로 빠져나온다', () async {
      final store = offlineStore();
      await store.transitionClaim(exchangeId, 'disputed', '쇼핑몰이 답하지 않음');
      expect(store.findClaim(exchangeId)!.state, 'disputed');
      await store.transitionClaim(exchangeId, 'waived', '더 진행하지 않음');
      expect(store.findClaim(exchangeId)!.state, 'waived');
      await store.transitionClaim(exchangeId, 'reopen', '다시 진행');
      expect(store.findClaim(exchangeId)!.state, 'negotiating');
    });

    test('거절 답장은 분쟁으로 바꾸고, 약속 금액은 건드리지 않는다', () async {
      final store = offlineStore();
      await store.saveReplyAndAgreedAmount(
        claimId: 'clm_jp_mercari',
        rawReply: 'We cannot accept this return.',
        replyKind: 'denied',
        summaryKo: '',
        translationKo: '',
        agreedAmountStr: '',
        aiAssisted: false,
      );
      final c = store.findClaim('clm_jp_mercari')!;
      expect([c.state, c.agreed], ['disputed', 42000]);
    });

    test('교환은 받은 수량으로, 수리는 결과 확인으로 끝까지 간다', () async {
      final store = offlineStore();
      await expectLater(
        store.recordReceipt(
            claimId: exchangeId, receivedOn: '2026-11-10', quantity: 2),
        refuses('수량'),
      );
      await store.recordReceipt(
          claimId: exchangeId, receivedOn: '2026-11-10', quantity: 1);
      var c = store.findClaim(exchangeId)!;
      expect([c.state, c.summary.goods, c.summary.remaining],
          ['recovered', 1, 0]);
      // 받은 기록이 있으면 해결 방법을 바꿀 수 없다
      await expectLater(store.changeClaimKind(exchangeId, 'refund'), refuses());
      await store.completeClaim(exchangeId);
      expect(store.findClaim(exchangeId)!.state, 'completed');

      // 수리: 교환을 요청했지만 고쳐 주기로 한 건
      final other = offlineStore();
      await other.changeClaimKind(exchangeId, 'repair');
      await other.recordReceipt(claimId: exchangeId, receivedOn: '2026-11-10');
      c = other.findClaim(exchangeId)!;
      expect([c.kind, c.state, c.summary.repair], ['repair', 'recovered', true]);
      await expectLater(
        other.recordReceipt(claimId: exchangeId, receivedOn: '2026-11-11'),
        refuses(),
      );
    });
  });

  group('서버가 거절하면', () {
    test('된 것처럼 바꾸지 않고 서버의 말을 그대로 돌려준다', () async {
      final api = RefusingApi(message: '같은 날짜·금액의 입금이 이미 있어요.');
      final store = ReloStore(api: api);
      final before = store.findClaim(refundId)!;

      await expectLater(
        store.recordReceipt(
          claimId: refundId,
          receivedOn: '2026-11-10',
          amountStr: '150.00',
          transactionRef: 'VISA-REF-009',
        ),
        refuses('같은 날짜'),
      );
      await expectLater(store.completeClaim(refundId), refuses());
      await expectLater(
          store.transitionClaim(refundId, 'disputed', '답이 없음'), refuses());
      await expectLater(store.changeClaimKind(refundId, 'exchange'), refuses());
      await expectLater(
        store.setClaimDeadline(
            claimId: refundId, deadline: '2026-12-01', quote: 'by Dec 1'),
        refuses(),
      );

      final after = store.findClaim(refundId)!;
      expect([after.state, after.summary.cash, after.kind, after.version],
          [before.state, 0, 'refund', before.version]);
      expect(api.asked, isNotEmpty);
      // 한국어가 아니면 서버의 한국어 문장 대신 화면의 문장을 쓴다
      store.locale = ReloLocale.en;
      expect(store.refusalText(const ApiError('한국어 까닭', explained: true)),
          store.strings.cwFailed);
    });

    test('서버에 없는 보기용 건(404)과 로그인 전(401)은 전처럼 기기 안에서 바꾼다', () async {
      for (final api in [
        RefusingApi(status: 404, code: 'not_found'),
        RefusingApi(status: 401, code: 'unauthorized'),
      ]) {
        final store = ReloStore(api: api);
        await store.transitionClaim(exchangeId, 'disputed', '답이 없음');
        expect(store.findClaim(exchangeId)!.state, 'disputed');
      }
    });
  });

  group('화면', () {
    Future<ReloStore> openDetail(WidgetTester tester, String id) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = offlineStore();
      await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      store.openClaimDetail(id);
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('교환 건은 수량으로 보여 주고, 답이 없으면 다른 해결 방법으로 갔다가 돌아온다', (tester) async {
      final store = await openDetail(tester, exchangeId);
      expect(find.text('요청 수량'), findsOneWidget);
      expect(find.text('받은 수량'), findsOneWidget);
      expect(find.text('교환품'), findsOneWidget); // 세 번째 탭
      expect(find.text('입금'), findsNothing);

      expect(find.text('쇼핑몰이 답하지 않거나 약속을 지키지 않나요?'), findsOneWidget);
      await tester.tap(find.text('다른 해결 방법 보기'));
      await tester.pumpAndSettle();
      expect(store.findClaim(exchangeId)!.state, 'disputed');
      expect(find.text('다른 길로 해결할 수 있어요'), findsOneWidget);
      expect(find.text('쇼핑몰에 분쟁 신청하기'), findsOneWidget);

      await tester.ensureVisible(find.text('다시 진행하기'));
      await tester.tap(find.text('다시 진행하기'));
      await tester.pumpAndSettle();
      expect(store.findClaim(exchangeId)!.state, 'negotiating');
      expect(find.text('다른 길로 해결할 수 있어요'), findsNothing);
    });

    testWidgets('번호 없는 입금 → 마무리 버튼 → 기록 되돌리기', (tester) async {
      final store = await openDetail(tester, refundId);
      expect(find.text('입금'), findsOneWidget);
      // 가짜 번호를 미리 채워 두지 않는다
      expect(find.text('VISA-CANCEL-8841'), findsNothing);

      await tester.ensureVisible(find.text('입금 기록하기'));
      await tester.tap(find.text('입금 기록하기'));
      await tester.pumpAndSettle();
      expect(find.text('어디에서 확인했는지 10자 이상 적어 주세요.'), findsOneWidget);
      expect(find.text('번호가 없는 내역이 맞는지 확인하고 체크해 주세요.'), findsOneWidget);
      expect(store.findClaim(refundId)!.summary.cash, 0);

      await tester.enterText(
        find.widgetWithText(TextField, '예: 카드 앱 취소 내역에서 금액과 날짜를 확인함'),
        '카드 앱 취소 내역에서 금액과 날짜를 확인함',
      );
      await tester.tap(find.text('번호가 없는 내역이고, 같은 입금을 앞에서 적지 않았어요.'));
      await tester.pump();
      await tester.ensureVisible(find.text('입금 기록하기'));
      await tester.tap(find.text('입금 기록하기'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(store.findClaim(refundId)!.state, 'recovered');
      expect(find.text('마무리하기'), findsOneWidget);
      expect(find.text('받을 것을 모두 기록했어요.'), findsOneWidget);

      await tester.ensureVisible(find.text('기록 되돌리기'));
      await tester.tap(find.text('기록 되돌리기'));
      await tester.pump();
      await tester.ensureVisible(find.text('되돌리기'));
      await tester.tap(find.text('되돌리기'));
      await tester.pump();
      expect(find.text('되돌리는 이유를 3자 이상 적어 주세요.'), findsOneWidget);
      await tester.enterText(
          find.widgetWithText(TextField, '예: 금액을 잘못 적었어요'), '금액을 잘못 적었어요');
      await tester.tap(find.text('되돌리기'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(store.findClaim(refundId)!.summary.cash, 0);
      expect(find.text('마무리하기'), findsNothing);
      expect(find.textContaining('되돌린 기록'), findsOneWidget);
    });
  });
}
