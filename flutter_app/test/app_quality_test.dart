import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relo_flutter/core/i18n/relo_i18n.dart';
import 'package:relo_flutter/core/utils/input_rules.dart';
import 'package:relo_flutter/main.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';
import 'wizard_helpers.dart';

/// 앱의 기본기: 입력 검사, 안드로이드 뒤로 가기, 네 언어.
void main() {
  group('입력 규칙', () {
    test('금액은 0보다 큰 숫자만 받는다', () {
      expect(InputRules.amount('289.00'), 289.0);
      expect(InputRules.amount('1,234.5'), 1234.5);
      expect(InputRules.amount(''), isNull);
      expect(InputRules.amount('0'), isNull);
      expect(InputRules.amount('-3'), isNull);
      expect(InputRules.amount('abc'), isNull);
    });

    test('통화를 바꾸면 금액의 소수 자릿수를 그 통화에 맞춘다', () {
      expect(InputRules.fitCurrency('289.00', 'JPY'), '289');
      expect(InputRules.fitCurrency('289.00', 'KRW'), '289');
      expect(InputRules.fitCurrency('289.00', 'USD'), '289.00');
      expect(InputRules.fitCurrency('289.999', 'USD'), '289.99');
      expect(InputRules.fitCurrency('42000', 'JPY'), '42000');
    });

    test('이메일과 날짜 모양을 본다', () {
      expect(InputRules.email('demo@relo.local'), true);
      expect(InputRules.email('demo@relo'), false);
      expect(InputRules.email('demo'), false);
      expect(InputRules.isoDate('2026-11-14'), true);
      expect(InputRules.isoDate('2026-02-31'), false, reason: '달력에 없는 날');
      expect(InputRules.isoDate('11/14/2026'), false);
    });

    test('금액 칸에는 숫자와 소수점 하나만 들어간다', () {
      TextEditingValue type(MoneyInputFormatter f, String before, String after) =>
          f.formatEditUpdate(
            TextEditingValue(text: before),
            TextEditingValue(text: after),
          );
      final usd = MoneyInputFormatter.of('USD');
      expect(type(usd, '', '12.34').text, '12.34');
      expect(type(usd, '12.34', '12.345').text, '12.34', reason: '소수 둘째 자리까지');
      expect(type(usd, '12', '12a').text, '12', reason: '글자는 들어가지 않는다');
      expect(type(usd, '1', '1.2.3').text, '1', reason: '소수점은 하나만');
      expect(type(usd, '', '1,234.50').text, '1234.50', reason: '붙여 넣은 쉼표는 뺀다');
      final jpy = MoneyInputFormatter.of('JPY');
      expect(type(jpy, '4200', '4200.5').text, '4200', reason: '엔은 소수가 없다');
    });
  });

  group('네 언어', () {
    test('화면 문구가 언어마다 채워져 있다', () {
      for (final locale in ReloLocale.values) {
        final s = ReloStrings(locale);
        for (final text in [
          s.dTabMessage,
          s.wStep1,
          s.wNext,
          s.stSectionScreen,
          s.lgTitle,
          s.auLogin,
          s.mcOpen,
          s.csWaiting,
          s.cmErrAmount,
          s.wAmount('USD'),
          s.dStepOf(3),
          s.connOffline,
        ]) {
          expect(text.trim(), isNotEmpty, reason: '${locale.code} 문구가 비어 있음');
        }
      }
      // 한국어가 아닌 언어에서 한국어가 그대로 나오지 않는다
      final hangul = RegExp('[가-힣]');
      for (final locale in [ReloLocale.en, ReloLocale.ja, ReloLocale.zh]) {
        final s = ReloStrings(locale);
        for (final text in [s.dTabMessage, s.wStep1, s.stSectionMe, s.lgTitle, s.auTitleLogin, s.mcDone]) {
          expect(hangul.hasMatch(text), false, reason: '${locale.code}: $text');
        }
      }
    });

    test('남은 날을 언어에 맞게 말한다', () {
      String iso(int days) => DateTime.now()
          .add(Duration(days: days))
          .toIso8601String()
          .substring(0, 10);
      expect(const ReloStrings(ReloLocale.ko).dday(iso(0)), '오늘');
      expect(const ReloStrings(ReloLocale.en).dday(iso(0)), 'Today');
      expect(const ReloStrings(ReloLocale.ko).dday(iso(2)), 'D-2');
      expect(const ReloStrings(ReloLocale.ko).dday(iso(-3)), '3일 지남');
      expect(const ReloStrings(ReloLocale.en).dday(iso(-3)), '3 days overdue');
      expect(const ReloStrings(ReloLocale.en).dday(iso(-1)), '1 day overdue');
      expect(const ReloStrings(ReloLocale.ja).dday(null), isNull);
    });
  });

  Future<ReloStore> startApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // 떠 있는 도우미는 계속 움직여서 pumpAndSettle이 끝나지 않으므로 끈다
    final store = ReloStore()..showAssistantButton = false;
    await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    return store;
  }

  // 말랑이가 계속 움직이는 화면(홈 · 내 환불)에서는 pumpAndSettle 대신 시간을 정해 돌린다
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('안드로이드 뒤로 가기는 앱을 끄지 않고 한 화면 뒤로 간다', (tester) async {
    final store = await startApp(tester);

    // 신청: 2단계 → 1단계 → 홈
    store.navigateToTab(1);
    await tester.pumpAndSettle();
    await wizardToStep(tester, 2);
    expect(find.text('어떤 상품이에요?'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('어디서 샀어요?'), findsOneWidget);
    expect(store.activeTabIndex, 1);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(store.activeTabIndex, 0);

    // 상세 → 내 환불 → 홈
    store.openClaimDetail('clm_amz_xm5');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(store.activeTabIndex, 2);
    expect(store.selectedClaimId, isNull);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(store.activeTabIndex, 0);

    // 약관 → 설정 → 홈
    store.openLegalDocument('privacy');
    await tester.pumpAndSettle();
    expect(store.activeTabIndex, 3);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(store.activeTabIndex, 4);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(store.activeTabIndex, 0);
  });

  testWidgets('금액을 비우고 다음으로 가려 하면 그 칸 아래에 알리고 머문다', (tester) async {
    final store = await startApp(tester);
    store.navigateToTab(1);
    await tester.pumpAndSettle();
    await wizardToStep(tester, 2);
    expect(find.text('어떤 상품이에요?'), findsOneWidget);
    // 금액 칸은 비어 있다 (전에는 예시 금액 289.00이 들어 있었다)
    expect(find.text('289.00'), findsNothing);
    await tester.enterText(find.byType(EditableText).at(0), '무선 헤드폰');

    // 금액 칸에는 글자가 들어가지 않는다: 숫자를 적은 뒤 글자를 붙여도 숫자만 남는다
    final amountField = find.byType(EditableText).at(3);
    await tester.enterText(amountField, '289.00');
    await tester.pump();
    await tester.enterText(amountField, '289.00원');
    await tester.pump();
    expect(find.text('289.00'), findsOneWidget);
    expect(find.text('289.00원'), findsNothing);

    // 비우면 다음으로 넘어가지 않고, 칸 아래에 빨간 글자로 알린다
    await tester.enterText(amountField, '');
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('어떤 상품이에요?'), findsOneWidget);
    expect(find.text('0보다 큰 금액을 숫자로 적어 주세요.'), findsOneWidget);

    // 문제가 생긴 수량이 주문한 수량보다 많아도 알린다
    await tester.enterText(find.text('1').last, '5');
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('주문한 수량보다 많을 수 없어요.'), findsOneWidget);
  });

  testWidgets('언어를 영어로 바꾸면 신청 · 상세 · 설정 · 약관 · 내 환불이 영어로 나온다', (tester) async {
    final store = await startApp(tester);
    store.setLocale(ReloLocale.en);
    await settle(tester);

    // 서버에 붙지 못했다는 한 줄도 영어로
    expect(find.textContaining('Not connected'), findsOneWidget);

    store.navigateToTab(1);
    await tester.pumpAndSettle();
    expect(find.text('Where did you buy it?'), findsOneWidget);
    expect(find.text('Let the AI fill it in'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('어디서 샀어요?'), findsNothing);
    // 다섯 단계를 끝까지 넘겨 본다 (글자가 길어진 언어에서 넘치는 줄이 없는지도 같이 본다)
    final titles = [
      'Which item is it?',
      'How should it be resolved?',
      'Do you have a receipt or photos?',
      'One last check',
    ];
    for (var i = 0; i < titles.length; i++) {
      // 빈 칸으로 열리므로 단계마다 채우고 넘어간다
      if (i == 0) await fillWizardStep1(tester);
      if (i == 1) await fillWizardStep2(tester, title: 'Wireless headphones');
      if (i == 2) await fillWizardStep3(tester, issue: 'It does not turn on.');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(titles[i]), findsOneWidget);
    }
    expect(find.text('Submit refund request'), findsOneWidget);

    store.openClaimDetail('clm_amz_xm5');
    await tester.pumpAndSettle();
    for (final tab in ['Message', 'Reply', 'Deposit', 'History']) {
      expect(find.text(tab), findsOneWidget);
    }
    expect(find.text('Check the offer'), findsOneWidget);
    expect(find.text('Record money received'), findsOneWidget);
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(find.text('Message to the seller'), findsOneWidget);
    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(find.text("Seller's reply"), findsOneWidget);
    // 시험용 글꼴은 글자가 넓어서 마지막 탭이 화면 밖에 있다. 탭 줄을 밀어 보이게 한 뒤 누른다.
    await tester.ensureVisible(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('What has happened so far'), findsOneWidget);

    store.navigateToTab(2);
    await settle(tester);
    expect(find.text('In progress'), findsNWidgets(2));
    expect(find.text('Received'), findsWidgets);

    store.navigateToTab(4);
    await tester.pumpAndSettle();
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('High contrast'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);

    store.openLegalDocument('privacy');
    await tester.pumpAndSettle();
    expect(find.text('Terms and privacy'), findsOneWidget);
    // 문서 본문은 한국어 원문이라는 것을 알려 준다
    expect(find.textContaining('provided in Korean'), findsOneWidget);

    // 로그아웃하면 설정 자리에 로그인 화면이 나온다. 가입으로 바꾸면 동의 줄도 영어로 나온다.
    // (맨 위 말랑이가 계속 움직이므로 시간을 정해 돌린다)
    store.user = null; // 로그아웃된 상태 (시험에서는 서버 응답을 기다릴 수 없다)
    store.navigateToTab(4);
    await settle(tester);
    expect(find.text('Open my refund vault'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    await tester.tap(find.text('New here · Create a vault'));
    await settle(tester);
    expect(find.text('Create my refund vault'), findsOneWidget);
    expect(find.textContaining('I am 14 or older'), findsOneWidget);
  });

  testWidgets('로그인할 때 이메일과 비밀번호를 칸 아래에서 바로 알려 준다', (tester) async {
    final store = await startApp(tester);
    store.user = null; // 로그아웃된 상태 (시험에서는 서버 응답을 기다릴 수 없다)
    store.navigateToTab(4);
    await settle(tester);
    expect(find.text('내 환불 보관함 열기'), findsOneWidget);

    await tester.enterText(find.text('demo@relo.local'), 'demo');
    await tester.enterText(find.byType(EditableText).last, '1234');
    await tester.pump();
    await tester.tap(find.text('로그인하기'));
    await settle(tester);
    expect(find.text('이메일 주소를 다시 확인해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 해요.'), findsOneWidget);
    expect(store.user, isNull, reason: '칸이 틀리면 로그인하지 않는다');
  });
}
