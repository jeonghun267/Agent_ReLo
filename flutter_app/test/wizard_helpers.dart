import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 신청 화면은 빈 칸으로 열린다 (예시 값도, 예시 파일도 없다).
/// 시험에서 단계를 넘기려면 사람이 하듯 그 단계의 칸을 채워야 한다.

/// 1단계: 쇼핑몰 칩을 고르고 주문번호를 적는다.
/// 칸 순서: 0 "무슨 일인가요?" 한 줄 · 1 주문번호 · 2 주문한 날 (쇼핑몰 이름 칸은 칩을 고르면 닫혀 있다)
Future<void> fillWizardStep1(
  WidgetTester tester, {
  String mall = 'Amazon US',
  String orderRef = '114-0000000-0000001',
}) async {
  await tester.ensureVisible(find.text(mall));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mall));
  await tester.pump();
  await tester.enterText(find.byType(EditableText).at(1), orderRef);
  await tester.pump();
}

/// 2단계: 상품 이름과 금액을 적는다. 칸 순서: 0 상품 이름 · 1 주문 수량 · 2 문제 수량 · 3 금액
Future<void> fillWizardStep2(
  WidgetTester tester, {
  String title = '무선 헤드폰',
  String amount = '289.00',
}) async {
  await tester.enterText(find.byType(EditableText).at(0), title);
  await tester.enterText(find.byType(EditableText).at(3), amount);
  await tester.pump();
}

/// 3단계: 무슨 문제인지 적는다. 칸 순서: 0 문제 설명 · 1 영어 설명
Future<void> fillWizardStep3(
  WidgetTester tester, {
  String issue = '전원이 켜지지 않아요.',
}) async {
  await tester.enterText(find.byType(EditableText).at(0), issue);
  await tester.pump();
}

/// 1단계에서 시작해 [step]단계까지 칸을 채우며 넘어간다. [next]는 그 언어의 "다음" 버튼 글자.
Future<void> wizardToStep(
  WidgetTester tester,
  int step, {
  String next = '다음',
}) async {
  for (var now = 1; now < step; now++) {
    if (now == 1) await fillWizardStep1(tester);
    if (now == 2) await fillWizardStep2(tester);
    if (now == 3) await fillWizardStep3(tester);
    await tester.tap(find.text(next));
    await tester.pumpAndSettle();
  }
}
