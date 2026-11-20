import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:relo_flutter/core/config/sdk_registry.dart';
import 'package:relo_flutter/core/utils/money_format.dart';
import 'package:relo_flutter/features/assistant/assistant_sheet.dart';
import 'package:relo_flutter/features/compliance/compliance_data.dart';
import 'package:relo_flutter/main.dart';
import 'package:relo_flutter/shared/models/domain_models.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';
import 'package:relo_flutter/shared/widgets/relo_icons.dart';
import 'package:relo_flutter/shared/widgets/relo_mascot.dart';
import 'package:relo_flutter/shared/widgets/relo_primitives.dart';
import 'wizard_helpers.dart';

void main() {
  group('MoneyFormat · 파일 시그니처 · 보호 항목 데이터', () {
    test('8개국 통화 소수점·정수 무오차 변환', () {
      expect(MoneyFormat.decimalStringToMinor('184.50', 'USD'), 18450);
      expect(MoneyFormat.formatMinor(18450, 'USD'), r'$184.50');
      expect(MoneyFormat.decimalStringToMinor('42000', 'JPY'), 42000);
      expect(MoneyFormat.formatMinor(42000, 'JPY'), '¥42,000');
    });

    test('보호 항목 20개와 외부 SDK 목록이 비어 있지 않다', () {
      expect(ReloComplianceData.twentyPointChecklist.length, 20);
      expect(ReloComplianceData.verifiedAssetLicenses.isNotEmpty, true);
      expect(ReloSdkRegistry.auditedSdks.isNotEmpty, true);
      expect(ReloSdkRegistry.blockedTrackerSdks.length, 4);
    });
  });

  testWidgets(
    '390px 화면에서 홈(대화) · 신청 · 내 환불 · 상세 · 약관 · 설정이 모두 그려진다',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 떠 있는 도우미는 계속 움직여서 pumpAndSettle이 끝나지 않으므로 이 테스트에서는 끈다
      final store = ReloStore()..showAssistantButton = false;
      await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
      await tester.pump();
      // 홈 등장 효과가 끝나도록 잠시 돌린다
      await tester.pump(const Duration(milliseconds: 1200));

      // 1. 홈: 맨 위 파란 카드 하나(받을 돈 + 받은 돈 + 말랑이), 그 아래 지금 할 일은
      //    상자 없이 줄로, 맨 아래에 입력칸. 소개 글과 큰 신청 버튼은 없다.
      expect(find.textContaining('받을 돈'), findsOneWidget);
      expect(find.textContaining('받은 돈'), findsOneWidget);
      expect(find.byType(ReloMascot), findsOneWidget);
      expect(find.text('지금 할 일'), findsOneWidget);
      expect(find.textContaining('제안 확인할 차례'), findsOneWidget);
      expect(find.textContaining('답장 기다리는 중'), findsOneWidget);
      expect(find.text('무엇이든 부탁하세요'), findsOneWidget);
      expect(find.textContaining('지금 3분 만에 환불 신청하기'), findsNothing);
      expect(find.text(store.strings.heroSubtitle), findsNothing);

      // 하단 탭은 홈 · 내 환불 · 설정 세 칸. 신청 탭은 없다.
      expect(find.text('홈'), findsOneWidget);
      expect(find.text('내 환불'), findsOneWidget);
      expect(find.text('설정'), findsOneWidget);
      expect(find.text('신청'), findsNothing);

      // 2. 쿠키 배너는 띄우지 않는다 (필수 쿠키만 사용)
      expect(find.text('전체 쿠키 동의'), findsNothing);
      expect(store.cookieConsent, CookieConsentChoice.pending);

      // 3. 신청하기: 홈 대화 아래 "새 환불 신청"으로 연다
      await tester.tap(find.text('+ 새 환불 신청'));
      await tester.pumpAndSettle();
      expect(store.activeTabIndex, 1);
      expect(find.text('어디서 샀어요?'), findsOneWidget);
      expect(find.text('AI가 채워 주기'), findsOneWidget);
      expect(find.text('AI가 채우기'), findsOneWidget);
      expect(find.text('쇼핑몰 이름'), findsNothing, reason: '칩으로 고르면 이름 칸은 숨긴다');

      // 단계마다 질문 하나. "다음"은 아래에 고정돼 있어 단계가 바뀌어도 같은 자리다.
      expect(find.text('1 / 5'), findsOneWidget);
      // 신청은 빈 칸으로 열린다: 예시 값이 없으니, 채우지 않으면 넘어가지 않고 무엇이 비었는지 알린다
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('어디서 샀어요?'), findsOneWidget);
      expect(find.text('쇼핑몰을 골라 주세요.'), findsOneWidget);
      expect(find.text('주문번호를 적어 주세요.'), findsOneWidget);
      await fillWizardStep1(tester);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('어떤 상품이에요?'), findsOneWidget);
      expect(find.text('결제한 통화'), findsOneWidget);
      await fillWizardStep2(tester);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('어떻게 해결할까요?'), findsOneWidget);
      // 자주 있는 문제를 고르면 설명 칸에 문장이 채워진다
      await tester.tap(find.text('작동이 안 돼요'));
      await tester.pumpAndSettle();
      expect(find.textContaining('작동 불량 상품입니다'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('영수증이나 사진이 있어요?'), findsOneWidget);
      // 올리지 않은 파일이 미리 붙어 있지 않다 (전에는 예시 영수증과 사진이 두 개 붙어 있었다)
      expect(find.text('주소 가려짐'), findsNothing);
      expect(find.text('Amazon_Order_Receipt_Masked.pdf'), findsNothing);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('마지막으로 확인해요'), findsOneWidget);
      // 마지막 확인에는 적은 것만 나온다: 붙인 파일은 없다
      expect(find.text('없음'), findsOneWidget);
      expect(find.text('114-0000000-0000001'), findsOneWidget);
      expect(find.text('수수료 · 성공보수'), findsOneWidget);
      // 필수 동의를 체크하지 않으면 등록되지 않고, 버튼 위 빨간 글자로 알려 준다
      await tester.tap(find.text('환불 신청 등록하기'));
      await tester.pumpAndSettle();
      expect(find.text('필수 동의 두 가지를 체크해 주세요.'), findsOneWidget);
      expect(store.activeTabIndex, 1);

      // 4. 내 환불(Tab 2)과 상세
      // 맨 위 말랑이가 계속 움직이므로 pumpAndSettle 대신 시간을 정해 돌린다
      store.navigateToTab(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      // 말랑이의 한 줄 요약, 받을 돈 / 받은 돈, 홈과 같은 줄(상자 없이) + 금액
      expect(find.textContaining('2건이 진행 중이에요'), findsOneWidget);
      expect(find.textContaining('답장이 와 있어요'), findsOneWidget);
      expect(find.textContaining('받을 돈'), findsOneWidget);
      expect(find.text('받은 돈'), findsOneWidget);
      expect(find.textContaining('제안 확인할 차례'), findsOneWidget);
      expect(find.textContaining('답장 기다리는 중'), findsOneWidget);
      expect(find.textContaining('입금 확인'), findsOneWidget);
      // 전체를 볼 때는 진행 중과 입금 완료로 나눠 보여 준다 (필터 칸 + 구역 제목)
      expect(find.text('진행 중'), findsNWidgets(2));
      expect(find.text('입금 완료'), findsNWidgets(2));
      // 이 화면에서는 떠 있는 도우미 대신 아래 칸으로 묻는다
      expect(find.text('ReLo에게 물어보기'), findsOneWidget);

      // 필터는 셋: 입금 완료만 고르면 입금 끝난 건만 남는다
      store.setFilter(state: 'done');
      expect(
          store.filteredClaims.every(
              (c) => c.state == 'recovered' || c.state == 'completed'),
          true);
      expect(store.filteredClaims, isNotEmpty);
      store.setFilter(state: '');

      // 상세: 받기로 한 돈 / 받은 돈, 글자 탭 넷, 아래 고정 "이 건 물어보기".
      // 화면을 열면 지금 단계에 맞는 탭이 켜져 있다 (약속을 받은 건 → 입금)
      store.openClaimDetail('clm_amz_xm5');
      await tester.pumpAndSettle();
      expect(find.text('받기로 한 돈'), findsOneWidget);
      expect(find.text('받은 돈'), findsOneWidget);
      expect(find.text('제안 확인할 차례'), findsOneWidget);
      for (final tab in ['메시지', '답장', '입금', '기록']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(find.text('들어온 돈 기록'), findsOneWidget);
      expect(find.text('이 건 물어보기'), findsOneWidget);
      expect(find.byType(ReloAssistantLauncher), findsNothing);

      // 탭을 누르면 그 내용으로 바뀐다
      await tester.tap(find.text('메시지'));
      await tester.pumpAndSettle();
      expect(find.text('판매자에게 보낼 메시지'), findsOneWidget);
      expect(find.text('보냈어요'), findsOneWidget);
      await tester.tap(find.text('답장'));
      await tester.pumpAndSettle();
      expect(find.text('판매자 답장'), findsOneWidget);
      await tester.tap(find.text('기록'));
      await tester.pumpAndSettle();
      expect(find.text('지금까지 한 일'), findsOneWidget);

      // 5. 약관·정책(Tab 3)과 하위 문서
      store.openLegalDocument('checklist');
      await tester.pumpAndSettle();
      expect(find.text('약관과 개인정보 보호'), findsOneWidget);
      // 글자 탭 여덟 개, 보호 항목은 상자 없는 줄
      expect(find.text('보호 항목'), findsOneWidget);
      expect(find.text('내 정보 삭제'), findsOneWidget);
      expect(find.byType(ReloTextTab), findsNWidgets(8));

      store.openLegalDocument('licenses');
      await tester.pumpAndSettle();
      expect(find.textContaining('상업적 라이선스 검증서'), findsOneWidget);

      store.openLegalDocument('delete');
      await tester.pumpAndSettle();
      expect(find.textContaining('즉시 영구 파기 요청'), findsOneWidget);
      // 지우는 버튼은 동의를 체크해야 켜진다 (처음에는 체크하지 않은 상태)
      expect(find.byType(ReloConsentRow), findsOneWidget);
      expect(find.text('내 정보와 사진 모두 영구 삭제하기'), findsOneWidget);

      // 6. 설정(Tab 4)
      store.navigateToTab(4);
      await tester.pumpAndSettle();
      expect(find.text('고대비 모드'), findsOneWidget);
      expect(find.text('약관 · 개인정보 처리방침 · 정책'), findsOneWidget);
      // 상자 없이 줄로: 구역 이름표 둘, 켜고 끄는 줄 다섯(마감 알림 포함), 언어는 고르는 칩
      expect(find.text('화면'), findsOneWidget);
      expect(find.text('내 정보'), findsOneWidget);
      expect(find.text('마감 알림'), findsOneWidget);
      // "이메일 알림 받기" 스위치는 없다: 기기 안의 값만 바꾸고 서버에는 전해지지 않던 스위치였다.
      // 알림 메일 스위치는 서버에 붙어 있고 스스로 시작하기를 켰을 때만 보인다 (agent_test).
      expect(find.byType(Switch), findsNWidgets(5));
      expect(find.text('이메일 알림 받기'), findsNothing);
      expect(find.text('알림 메일 받기'), findsNothing);
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('회원 탈퇴 · 내 정보 모두 삭제'), findsOneWidget);
      // 켜고 끄는 줄은 글자를 눌러도 바뀐다
      final wasDark = store.isDarkMode;
      await tester.tap(find.text('어두운 화면'));
      await tester.pumpAndSettle();
      expect(store.isDarkMode, !wasDark);
      await tester.tap(find.text('어두운 화면'));
      await tester.pumpAndSettle();
      expect(store.isDarkMode, wasDark);
    },
  );

  testWidgets(
    '환불 건이 없으면 홈이 "무슨 일이 있었어요?"로 시작하고, 고르면 그 내용이 채워진 신청 화면이 열린다',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = ReloStore()..claims = [];
      await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('무슨 일이 있었어요?'), findsOneWidget);
      expect(find.byType(ReloMascot), findsOneWidget);
      expect(find.text('영수증으로 시작하기'), findsOneWidget);
      // 위의 세 가지가 신청을 맡으므로 고르는 말에는 신청을 또 두지 않는다
      expect(find.text('+ 새 환불 신청'), findsNothing);

      await tester.tap(find.text('물건이 안 왔어요'));
      await tester.pumpAndSettle();
      expect(store.activeTabIndex, 1);
      expect(find.text('어디서 샀어요?'), findsOneWidget);
      // 신청 화면이 미리 채울 내용을 가져갔다 (쇼핑몰 없이 문제만 있어도)
      expect(store.wizardPresetIssue, isNull);
      expect(store.wizardPresetKind, isNull);
    },
  );

  testWidgets(
    '홈 대화에서 물으면 서버 없이도 내 환불 기록으로 답하고, 대화는 기기에 남아 다시 열 수 있다',
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

      // 홈은 화면 전체가 도우미와의 대화라 떠 있는 도우미를 띄우지 않는다
      expect(find.byType(ReloAssistantLauncher), findsNothing);

      // 입력칸 위에서 고르는 말로 묻는다 (짧게 보이고, 온전한 문장으로 묻는다)
      final starter = find.text('어디까지 왔어?');
      await tester.ensureVisible(starter);
      await tester.pump();
      await tester.tap(starter);
      await tester.pump(const Duration(milliseconds: 600));
      expect(store.assistantTurns.length, 2);
      final reply = store.assistantTurns.last;
      expect(reply.offline, true);
      expect(reply.action, 'open_claim');
      expect(find.textContaining('단계예요'), findsOneWidget);

      // 말랑이를 누르면 윙크하며 폴짝 뛴다 (0.7초). 내 환불로 넘어가지 않는다.
      // (새 말이 와서 화면이 내려가는 동안에는 누를 수 없으니 먼저 기다린다)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(ReloMascot));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));
      expect(store.activeTabIndex, 0);

      // 상단 대화 기록: 방금 대화가 맨 위, 지난번 대화가 그 아래
      await tester.tap(find.byTooltip('대화 기록'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('지난 대화'), findsOneWidget);
      expect(store.assistantHistory.map((c) => c.title).toList(),
          ['내 환불 어디까지 왔어?', 'AliExpress 답장 해석']);
      expect(find.text('AliExpress 답장 해석'), findsOneWidget);
      final saved = (await SharedPreferences.getInstance())
          .getString('relo.assistant.history.v1');
      expect(saved, contains('내 환불 어디까지 왔어?'));

      // 지난 대화를 누르면 기록 창이 닫히고 홈 대화에 그 대화가 열린다
      await tester.tap(find.text('AliExpress 답장 해석'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('지난 대화'), findsNothing);
      expect(find.text('답장을 붙여 넣어 주세요.'), findsOneWidget);

      // 방금 대화로 돌아간다 (기록 창의 항목이 홈의 같은 글자보다 뒤에 그려진다)
      await tester.tap(find.byTooltip('대화 기록'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.tap(find.text('내 환불 어디까지 왔어?').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.textContaining('단계예요'), findsOneWidget);
      // 대화의 끝으로 내려가는 동안에는 누를 수 없으니 다 내려갈 때까지 기다린다
      await tester.pump(const Duration(milliseconds: 400));

      // 답 아래에 붙은 그 건의 카드를 누르면 상세가 열리고, 거기서는 떠 있는 도우미 대신
      // 아래에 고정된 "이 건 물어보기" 칸으로 묻는다.
      // (지금 할 일 목록 아래로 대화가 쌓이므로 맨 마지막 것이 방금 답에 붙은 카드다)
      await tester.tap(find.byIcon(ReloIcons.package).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(store.activeTabIndex, 2);
      expect(store.selectedClaimId, reply.claimId);
      expect(find.text('이 건 물어보기'), findsOneWidget);
      expect(find.byType(ReloAssistantLauncher), findsNothing);
    },
  );
}
