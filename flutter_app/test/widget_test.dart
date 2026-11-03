import 'dart:convert';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:relo_flutter/core/config/sdk_registry.dart';
import 'package:relo_flutter/core/utils/money_format.dart';
import 'package:relo_flutter/features/assistant/assistant_sheet.dart';
import 'package:relo_flutter/features/compliance/compliance_data.dart';
import 'package:relo_flutter/main.dart';
import 'package:relo_flutter/shared/models/domain_models.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';
import 'package:relo_flutter/shared/widgets/relo_mascot.dart';

void main() {
  group('MoneyFormat · 파일 시그니처 · 보호 항목 데이터', () {
    test('8개국 통화 소수점·정수 무오차 변환', () {
      expect(MoneyFormat.decimalStringToMinor('184.50', 'USD'), 18450);
      expect(MoneyFormat.formatMinor(18450, 'USD'), r'$184.50');
      expect(MoneyFormat.decimalStringToMinor('42000', 'JPY'), 42000);
      expect(MoneyFormat.formatMinor(42000, 'JPY'), '¥42,000');
    });

    test('백엔드 파일 업로드 매직 바이트 시그니처(%PDF-, JPEG, PNG) 보장 검증', () {
      final pdfBytes = ReloStore.ensureValidFileSignature(
        'application/pdf',
        [1, 2, 3],
      );
      expect(pdfBytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);

      final jpgBytes = ReloStore.ensureValidFileSignature(
        'image/jpeg',
        [1, 2, 3],
      );
      expect(jpgBytes.sublist(0, 3), [255, 216, 255]);

      final pngBytes = ReloStore.ensureValidFileSignature(
        'image/png',
        [1, 2, 3],
      );
      expect(pngBytes.sublist(0, 4), [137, 80, 78, 71]);
    });

    test('보호 항목 20개와 외부 SDK 목록이 비어 있지 않다', () {
      expect(ReloComplianceData.twentyPointChecklist.length, 20);
      expect(ReloComplianceData.verifiedAssetLicenses.isNotEmpty, true);
      expect(ReloSdkRegistry.auditedSdks.isNotEmpty, true);
      expect(ReloSdkRegistry.blockedTrackerSdks.length, 4);
    });
  });

  testWidgets(
    '390px 화면에서 홈 · 신청 · 내 환불 · 상세 · 약관 · 설정이 모두 그려진다',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 떠 있는 도우미는 계속 움직여서 pumpAndSettle이 끝나지 않으므로 이 테스트에서는 끈다
      final store = ReloStore()..showAssistantButton = false;
      await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
      await tester.pump();
      // 홈 등장 효과와 지구본 틱이 끝나도록 잠시 돌린다
      await tester.pump(const Duration(milliseconds: 1200));

      // 1. 홈: 신청 버튼, 돌려받을 돈, 오늘 할 일
      expect(find.textContaining('지금 3분 만에 환불 신청하기'), findsOneWidget);
      expect(find.text('돌려받을 돈'), findsOneWidget);
      expect(find.text('오늘 할 일'), findsOneWidget);

      // 2. 쿠키 배너는 띄우지 않는다 (필수 쿠키만 사용)
      expect(find.text('전체 쿠키 동의'), findsNothing);
      expect(store.cookieConsent, CookieConsentChoice.pending);

      // 3. 신청하기(Tab 1)
      store.navigateToTab(1);
      await tester.pumpAndSettle();
      expect(find.textContaining('어디서 주문하셨나요?'), findsOneWidget);

      // 4. 내 환불(Tab 2)과 상세
      store.navigateToTab(2);
      await tester.pumpAndSettle();
      expect(find.text('내 환불 통장'), findsOneWidget);
      expect(find.textContaining('아직 입금 전이에요'), findsWidgets);

      store.openClaimDetail('clm_amz_xm5');
      await tester.pumpAndSettle();
      expect(find.textContaining('외국어 환불 요청서 자동 생성'), findsOneWidget);

      // 5. 약관·정책(Tab 3)과 하위 문서
      store.openLegalDocument('checklist');
      await tester.pumpAndSettle();
      expect(find.text('약관과 개인정보 보호'), findsOneWidget);

      store.openLegalDocument('licenses');
      await tester.pumpAndSettle();
      expect(find.textContaining('상업적 라이선스 검증서'), findsOneWidget);

      store.openLegalDocument('delete');
      await tester.pumpAndSettle();
      expect(find.textContaining('즉시 영구 파기 요청'), findsOneWidget);

      // 6. 설정(Tab 4)
      store.navigateToTab(4);
      await tester.pumpAndSettle();
      expect(find.text('고대비 모드'), findsOneWidget);
      expect(find.text('약관 · 개인정보 처리방침 · 정책'), findsOneWidget);
    },
  );

  testWidgets(
    '떠 있는 도우미를 누르면 대화 창이 열리고, 서버 없이도 내 환불 기록으로 답하며, 대화는 기기에 남는다',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 지난번에 저장해 둔 대화 하나
      SharedPreferences.setMockInitialValues({
        'relo.assistant.history.v1': jsonEncode([
          AssistantConversation(
            id: 'conv_old',
            title: 'AliExpress 답장 해석',
            updatedAt: DateTime(2026, 10, 28, 14, 33),
            turns: const [
              AssistantTurn.user('AliExpress 답장 해석'),
              AssistantTurn(fromUser: false, text: '답장을 붙여 넣어 주세요.'),
            ],
          ).toStored(),
        ]),
      });

      final store = ReloStore()..isOfflineFallback = true;
      await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
      await tester.pump(const Duration(milliseconds: 1200));

      final launcher = find.descendant(
        of: find.byType(ReloAssistantLauncher),
        matching: find.byType(ReloMascot),
      );
      expect(launcher, findsOneWidget);
      await tester.tap(launcher);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('무엇을 도와드릴까요?'), findsOneWidget);

      await tester.tap(find.text('내 환불 어디까지 왔어?'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(store.assistantTurns.length, 2);
      final reply = store.assistantTurns.last;
      expect(reply.offline, true);
      expect(reply.action, 'open_claim');
      expect(find.textContaining('단계예요'), findsOneWidget);

      // ☰ 대화 기록: 방금 대화가 맨 위, 지난번 대화가 그 아래
      await tester.tap(find.byTooltip('대화 기록'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('지난 대화'), findsOneWidget);
      expect(store.assistantHistory.map((c) => c.title).toList(),
          ['내 환불 어디까지 왔어?', 'AliExpress 답장 해석']);
      expect(find.text('AliExpress 답장 해석'), findsOneWidget);
      final saved = (await SharedPreferences.getInstance())
          .getString('relo.assistant.history.v1');
      expect(saved, contains('내 환불 어디까지 왔어?'));

      // 지난 대화를 누르면 그 대화가 다시 열린다
      await tester.tap(find.text('AliExpress 답장 해석'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('답장을 붙여 넣어 주세요.'), findsOneWidget);

      await tester.tap(find.byTooltip('대화 기록'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('내 환불 어디까지 왔어?'));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('상세 열기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(store.activeTabIndex, 2);
      expect(store.selectedClaimId, reply.claimId);
      expect(find.text('이 건 물어보기'), findsOneWidget);
    },
  );
}
