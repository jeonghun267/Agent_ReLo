import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:relo_flutter/core/config/sdk_registry.dart';
import 'package:relo_flutter/core/utils/money_format.dart';
import 'package:relo_flutter/features/compliance/compliance_data.dart';
import 'package:relo_flutter/main.dart';
import 'package:relo_flutter/shared/models/domain_models.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';

void main() {
  group('ReLo MoneyFormat · 매직 바이트 시그니처 · 20대 법적 컴플라이언스 단위 검증', () {
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

    test('고소 방지 필수 20대 체크리스트 및 외부 SDK 점검 레지스트리 완비 확인', () {
      expect(ReloComplianceData.twentyPointChecklist.length, 20);
      expect(ReloComplianceData.verifiedAssetLicenses.isNotEmpty, true);
      expect(ReloSdkRegistry.auditedSdks.isNotEmpty, true);
      expect(ReloSdkRegistry.blockedTrackerSdks.length, 4);
    });
  });

  testWidgets(
    'ReLo Flutter 390px 모바일 뷰포트 전체 5대 탭 · 상세 워크스페이스 · 법적보호 20선 무오류 검증',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = ReloStore();
      await tester.pumpWidget(ReloFlutterApp(store: store));
      await tester.pump();

      // 1. 승인된 메인 홈 핵심 요소 및 숨겨진 요금 0원 고지 확인
      expect(find.textContaining('지금 3분 만에 환불 신청하기'), findsOneWidget);
      expect(find.textContaining('숨겨진 요금 0원'), findsOneWidget);

      // 2. 다크패턴 없는 쿠키 동의 배너(필수만 허용 vs 전체 동의) 작동 확인
      expect(find.text('필수만 허용 (거절)'), findsOneWidget);
      expect(find.text('전체 쿠키 동의'), findsOneWidget);
      await tester.tap(find.text('필수만 허용 (거절)'));
      await tester.pump();
      expect(store.cookieConsent, CookieConsentChoice.essentialOnly);

      // 3. 5단계 신청하기 위저드(Tab 1) 렌더링 확인
      store.navigateToTab(1);
      await tester.pump();
      expect(find.textContaining('어디서 주문하셨나요?'), findsOneWidget);

      // 4. 내 환불 통장(Tab 2) 및 개별 클레임 상세 워크스페이스 렌더링 확인
      store.navigateToTab(2);
      await tester.pump();
      expect(find.textContaining('내 직구 환불 통장'), findsOneWidget);

      store.openClaimDetail('clm_amz_xm5');
      await tester.pump();
      expect(find.textContaining('외국어 환불 요청서 자동 생성'), findsOneWidget);

      // 5. 법적보호 20선(Tab 3) 및 하위 정책 탭(개인정보 처리방침, 글꼴 라이선스, 즉시 삭제) 확인
      store.openLegalDocument('checklist');
      await tester.pump();
      expect(find.textContaining('20대 필수 컴플라이언스 센터'), findsOneWidget);

      store.openLegalDocument('licenses');
      await tester.pump();
      expect(find.textContaining('상업적 라이선스 검증서'), findsOneWidget);

      store.openLegalDocument('delete');
      await tester.pump();
      expect(find.textContaining('즉시 영구 파기 요청'), findsOneWidget);

      // 6. 설정 · 내 정보(Tab 4) 및 로그인/회원가입 화면 확인
      store.navigateToTab(4);
      await tester.pump();
      expect(find.textContaining('시각 약자용 WCAG AAA 초고대비 모드'), findsOneWidget);
    },
  );
}
