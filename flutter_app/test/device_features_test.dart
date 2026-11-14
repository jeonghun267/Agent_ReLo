import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relo_flutter/core/attachments/evidence_picker.dart';
import 'package:relo_flutter/core/attachments/evidence_rules.dart';
import 'package:relo_flutter/core/i18n/relo_i18n.dart';
import 'package:relo_flutter/core/network/api_client.dart';
import 'package:relo_flutter/core/platform/relo_native_channel.dart';
import 'package:relo_flutter/core/platform/text_sharer.dart';
import 'package:relo_flutter/core/reminders/reminder_planner.dart';
import 'package:relo_flutter/core/reminders/reminder_scheduler.dart';
import 'package:relo_flutter/main.dart';
import 'package:relo_flutter/shared/models/domain_models.dart';
import 'package:relo_flutter/shared/state/relo_store.dart';
import 'package:relo_flutter/shared/widgets/relo_app_shell.dart';
import 'package:relo_flutter/shared/widgets/relo_icons.dart';
import 'package:relo_flutter/shared/widgets/relo_intro.dart';
import 'package:relo_flutter/shared/widgets/relo_mascot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 기기 기능: 영수증 · 사진 붙이기와 마감 알림.
/// 기기 없이 시험할 수 있게, 고르기 화면과 알림은 가짜로 바꿔 끼운다.

/// 고르기 화면 대신: 정해 둔 파일을 돌려주거나 정해 둔 문제를 낸다
class FakeEvidencePicker implements EvidencePicker {
  PickedEvidence? next;
  EvidenceProblem? problem;
  final List<EvidenceSource> asked = [];

  @override
  bool get isSupported => true;

  @override
  Future<PickedEvidence?> pick(EvidenceSource source) async {
    asked.add(source);
    if (problem != null) throw EvidenceException(problem!);
    return next;
  }
}

/// 기기 알림 대신: 무엇을 맞추라고 했는지 적어 둔다
class FakeReminderScheduler implements ReminderScheduler {
  bool grant;
  String? openedClaim;
  final List<List<ReminderNotice>> replaced = [];
  void Function(String claimId)? onOpened;

  FakeReminderScheduler({this.grant = true, this.openedClaim});

  @override
  bool get isSupported => true;

  @override
  Future<bool> isAllowed() async => grant;

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> replaceAll(List<ReminderNotice> notices) async =>
      replaced.add(notices);

  @override
  Future<String?> takeOpenedClaim() async {
    final id = openedClaim;
    openedClaim = null;
    return id;
  }

  @override
  void setOnOpened(void Function(String claimId)? handler) => onOpened = handler;
}

/// 다른 앱의 공유 대신: 넣어 둔 파일을 한 번 돌려준다
class FakeSharedInbox implements SharedEvidenceInbox {
  PickedEvidence? waiting;
  EvidenceProblem? problem;
  void Function()? onArrived;

  @override
  Future<PickedEvidence?> take() async {
    if (problem != null) {
      final p = problem!;
      problem = null;
      throw EvidenceException(p);
    }
    final evidence = waiting;
    waiting = null;
    return evidence;
  }

  @override
  void setOnArrived(void Function()? handler) => onArrived = handler;
}

/// 기기의 공유 화면 대신: 무엇을 넘기라고 했는지 적어 둔다
class FakeTextSharer implements TextSharer {
  final List<({String text, String? subject})> shared = [];

  @override
  bool get isSupported => true;

  @override
  Future<bool> share({required String text, String? subject}) async {
    shared.add((text: text, subject: subject));
    return true;
  }
}

/// 로그인해서 서버에 붙어 있는 것처럼 보이는 연결
class SignedInApi extends ReloApiClient {
  @override
  bool get hasSession => true;
}

/// 시험용 JPEG: 그림 정보(JFIF) · 촬영 정보(EXIF) · 색 정보(ICC) · 메모 · 그림 데이터
Uint8List jpegWithExif() {
  List<int> segment(int marker, List<int> payload) => [
        0xFF,
        marker,
        ((payload.length + 2) >> 8) & 0xFF,
        (payload.length + 2) & 0xFF,
        ...payload,
      ];
  return Uint8List.fromList([
    0xFF, 0xD8,
    ...segment(0xE0, 'JFIF\u0000'.codeUnits),
    ...segment(0xE1, 'Exif\u0000\u0000GPS 37.5665N 126.9780E'.codeUnits),
    ...segment(0xE2, 'ICC_PROFILE\u0000'.codeUnits),
    ...segment(0xFE, 'shot on a phone'.codeUnits),
    ...segment(0xDB, List.filled(8, 7)),
    ...segment(0xDA, [1, 2, 3]),
    9, 9, 9, 0xFF, 0x00, 9, // 그림 데이터 (FF 00은 데이터 안의 FF)
    0xFF, 0xD9,
  ]);
}

bool containsText(List<int> bytes, String text) =>
    String.fromCharCodes(bytes).contains(text);

ClaimView claim({
  required String id,
  String state = 'drafting',
  String? deadline,
  String updatedAt = '2026-11-01T10:00:00',
  bool deleted = false,
}) =>
    ClaimView(
      id: id,
      title: '헤드폰 $id',
      vendor: 'Amazon US',
      vendorUrl: '',
      orderRef: 'ORD-$id',
      orderedOn: '2026-10-20',
      kind: 'refund',
      currency: 'USD',
      items: const [],
      claimed: 10000,
      issue: '',
      issueEnglish: '',
      deadline: deadline,
      deadlineQuote: '',
      deadlineZone: 'Asia/Seoul',
      state: state,
      version: 1,
      deleted: deleted,
      createdAt: '2026-10-21T10:00:00',
      updatedAt: updatedAt,
      files: const [],
      ledger: const [],
      drafts: const [],
      replies: const [],
      events: const [],
      summary: const ClaimSummaryTotals(
        cash: 0,
        goods: 0,
        repair: false,
        remaining: 10000,
        requestedQty: 1,
      ),
      nextStep: '',
    );

void main() {
  // 기기 저장소(알림을 켰는지 등)는 빈 가짜로 둔다
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('붙일 파일 손보기', () {
    test('종류는 파일 앞머리로 알아낸다', () {
      expect(EvidenceRules.sniffMime(jpegWithExif()), 'image/jpeg');
      expect(
        EvidenceRules.sniffMime([137, 80, 78, 71, 13, 10, 26, 10, 0]),
        'image/png',
      );
      expect(
        EvidenceRules.sniffMime('RIFF\u0000\u0000\u0000\u0000WEBPVP8 '.codeUnits),
        'image/webp',
      );
      expect(EvidenceRules.sniffMime('%PDF-1.7'.codeUnits), 'application/pdf');
      expect(EvidenceRules.sniffMime('PK\u0003\u0004zipzip'.codeUnits), isNull);
      expect(EvidenceRules.sniffMime(const []), isNull);
    });

    test('사진에서 촬영 위치 같은 덧붙은 정보를 지우고 그림은 그대로 둔다', () {
      final original = jpegWithExif();
      expect(EvidenceRules.hasJpegExif(original), true);
      expect(containsText(original, 'GPS 37.5665N'), true);

      final cleaned = EvidenceRules.stripJpegMetadata(original);
      expect(EvidenceRules.hasJpegExif(cleaned), false);
      expect(containsText(cleaned, 'GPS'), false, reason: '촬영 위치');
      expect(containsText(cleaned, 'shot on a phone'), false, reason: '메모');
      expect(containsText(cleaned, 'JFIF'), true, reason: '그림 정보는 남긴다');
      expect(containsText(cleaned, 'ICC_PROFILE'), true, reason: '색 정보는 남긴다');
      // 그림 데이터와 끝 표식은 한 바이트도 달라지지 않는다
      final tail = [9, 9, 9, 0xFF, 0x00, 9, 0xFF, 0xD9];
      expect(cleaned.sublist(cleaned.length - tail.length), tail);
      expect(EvidenceRules.sniffMime(cleaned), 'image/jpeg');
    });

    test('구조를 읽을 수 없는 사진은 손대지 않는다', () {
      final broken = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0xFF, 0xFF, 1, 2]);
      expect(EvidenceRules.stripJpegMetadata(broken), broken);
      final notJpeg = Uint8List.fromList('%PDF-1.4'.codeUnits);
      expect(EvidenceRules.stripJpegMetadata(notJpeg), notJpeg);
    });

    test('파일 이름에서 경로와 이상한 글자를 빼고 확장자를 종류에 맞춘다', () {
      expect(
        EvidenceRules.safeName(r'C:\Users\me\Pictures\영수증 1.JPEG', 'image/jpeg'),
        '영수증 1.jpg',
      );
      expect(
        EvidenceRules.safeName('/storage/emulated/0/invoice.final.pdf', 'application/pdf'),
        'invoice.final.pdf',
      );
      expect(EvidenceRules.safeName('IMG_0012.heic', 'image/jpeg'), 'IMG_0012.jpg');
      expect(EvidenceRules.safeName('a<b>:"c"|?*.png', 'image/png'), 'abc.png');
      expect(EvidenceRules.safeName('', 'image/webp'), 'evidence.webp');
      expect(EvidenceRules.safeName('.hidden', 'image/png'), 'hidden.png');
      expect(
        EvidenceRules.safeName('${'가' * 200}.jpg', 'image/jpeg').length,
        lessThanOrEqualTo(64),
      );
    });

    test('올릴 수 없는 파일은 까닭과 함께 막는다', () {
      EvidenceProblem? problemOf(List<int> bytes) {
        try {
          EvidenceRules.prepare(name: 'x', bytes: bytes);
          return null;
        } on EvidenceException catch (e) {
          return e.problem;
        }
      }

      expect(problemOf(const []), EvidenceProblem.unreadable);
      expect(problemOf('hello world, not a photo'.codeUnits), EvidenceProblem.unsupportedType);
      final huge = Uint8List(EvidenceRules.maxBytes + 1)
        ..setAll(0, '%PDF-'.codeUnits);
      expect(problemOf(huge), EvidenceProblem.tooLarge);

      final ok = EvidenceRules.prepare(name: 'DCIM/photo.jpeg', bytes: jpegWithExif());
      expect(ok.name, 'photo.jpg');
      expect(ok.mime, 'image/jpeg');
      expect(EvidenceRules.hasJpegExif(ok.bytes), false);
    });
  });

  group('마감 알림 계획', () {
    final now = DateTime(2026, 11, 15, 10); // 아침 10시

    test('마감 3일 전 · 하루 전 · 당일 아침 9시에 알린다', () {
      final plan = ReminderPlanner.plan(
        [claim(id: 'a', deadline: '2026-11-25')],
        now: now,
      );
      expect(plan.map((r) => r.kind), [
        ReminderKind.deadlineIn3Days,
        ReminderKind.deadlineTomorrow,
        ReminderKind.deadlineToday,
      ]);
      expect(plan.map((r) => r.when), [
        DateTime(2026, 11, 22, 9),
        DateTime(2026, 11, 24, 9),
        DateTime(2026, 11, 25, 9),
      ]);
    });

    test('이미 지난 시각은 뺀다', () {
      // 마감이 내일: 3일 전은 지났고, 오늘 9시(하루 전)도 지났다. 내일 아침 것만 남는다.
      final plan = ReminderPlanner.plan(
        [claim(id: 'a', deadline: '2026-11-16')],
        now: now,
      );
      expect(plan.single.kind, ReminderKind.deadlineToday);
      expect(plan.single.when, DateTime(2026, 11, 16, 9));
      // 마감이 지난 건은 아무것도 없다
      expect(
        ReminderPlanner.plan([claim(id: 'b', deadline: '2026-11-10')], now: now),
        isEmpty,
      );
    });

    test('끝난 건 · 휴지통에 있는 건 · 마감이 없는 건은 알리지 않는다', () {
      final plan = ReminderPlanner.plan(
        [
          claim(id: 'done', deadline: '2026-11-25', state: 'completed'),
          claim(id: 'paid', deadline: '2026-11-25', state: 'recovered'),
          claim(id: 'gave-up', deadline: '2026-11-25', state: 'waived'),
          claim(id: 'trash', deadline: '2026-11-25', deleted: true),
          claim(id: 'no-deadline'),
        ],
        now: now,
      );
      expect(plan, isEmpty);
    });

    test('답장을 기다린 지 사흘이면 확인하라고 알린다', () {
      final plan = ReminderPlanner.plan(
        [claim(id: 'w', state: 'awaiting', updatedAt: '2026-11-14T21:30:00')],
        now: now,
      );
      expect(plan.single.kind, ReminderKind.replyCheck);
      expect(plan.single.when, DateTime(2026, 11, 17, 9));
    });

    test('같은 건 · 같은 종류는 늘 같은 번호, 다른 것은 다른 번호', () {
      final a3 = ReminderPlanner.idFor('clm_a', ReminderKind.deadlineIn3Days);
      expect(ReminderPlanner.idFor('clm_a', ReminderKind.deadlineIn3Days), a3);
      final ids = {
        for (final id in ['clm_a', 'clm_b', 'clm_amz_xm5'])
          for (final kind in ReminderKind.values) ReminderPlanner.idFor(id, kind),
      };
      expect(ids.length, 3 * ReminderKind.values.length);
      expect(ids.every((id) => id >= 0 && id < 0x7FFFFFFF), true);
    });

    test('가까운 것부터, 많아도 60개까지만 맞춘다', () {
      final many = [
        for (var i = 0; i < 40; i++)
          claim(id: 'c$i', deadline: '2026-12-${(i % 20 + 1).toString().padLeft(2, '0')}'),
      ];
      final plan = ReminderPlanner.plan(many, now: now);
      expect(plan.length, ReminderPlanner.maxPlanned);
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].when.isBefore(plan[i - 1].when), false);
      }
    });
  });

  // ── 앱과 함께 ───────────────────────────────────────────────────────
  Future<ReloStore> startApp(
    WidgetTester tester, {
    EvidencePicker? picker,
    ReminderScheduler? reminders,
    SharedEvidenceInbox? inbox,
    TextSharer? sharer,
    bool signedIn = false,
  }) async {
    tester.view.physicalSize = const Size(390, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = ReloStore(
      api: signedIn ? SignedInApi() : null,
      evidencePicker: picker,
      reminders: reminders,
      sharedInbox: inbox ?? FakeSharedInbox(),
      textSharer: sharer,
    )..showAssistantButton = false;
    await tester.pumpWidget(ReloFlutterApp(store: store, showIntro: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    return store;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  testWidgets('시작 연출: 로고에서 시작해 이름과 한 줄 소개를 보여 주고, 끝나면 홈만 남는다', (tester) async {
    tester.view.physicalSize = const Size(390, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // 기기 대신 답한다: 시작 화면은 이미 걷혔다
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      reloNativeChannel,
      (call) async => call.method == 'splashState' ? {'showing': false} : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(reloNativeChannel, null),
    );
    final store = ReloStore(
      sharedInbox: FakeSharedInbox(),
      reminders: FakeReminderScheduler(),
    )..showAssistantButton = false;
    await tester.pumpWidget(ReloFlutterApp(store: store));
    await tester.pump(); // 첫 화면: 기기의 시작 화면과 같은 모습 (바탕 + 가운데 로고)
    // 가운데의 큰 로고(96)가 있고, 홈은 덮개 아래에 미리 그려져 있다
    expect(
      tester.widgetList<ReloLogoMark>(find.byType(ReloLogoMark)).map((w) => w.size),
      contains(ReloIntro.logoSize),
    );
    double taglineOpacity() => tester
        .widget<Opacity>(
          find.ancestor(
            of: find.text('해외 직구 환불, 끝까지 같이 챙겨요'),
            matching: find.byType(Opacity),
          ).first,
        )
        .opacity;
    expect(taglineOpacity(), lessThan(0.02), reason: '시작 전에는 글자가 보이지 않는다');

    // 0.4초: 로고가 말랑이로 깨어나 있고 글자가 보인다
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ReloMascot), findsWidgets);
    final tagline = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('해외 직구 환불, 끝까지 같이 챙겨요'),
        matching: find.byType(Opacity),
      ).first,
    );
    expect(tagline.opacity, greaterThan(0.9));

    // 끝나면 덮개와 글자는 사라지고 홈만 남는다
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('해외 직구 환불, 끝까지 같이 챙겨요'), findsNothing);
    expect(find.text('ReLo'), findsOneWidget, reason: '상단 바의 이름만 남는다');
    expect(store.activeTabIndex, 0);
  });

  testWidgets('신청 4단계에서 고른 사진이 목록에 붙는다', (tester) async {
    final picker = FakeEvidencePicker()
      ..next = EvidenceRules.prepare(name: '박스 파손.jpeg', bytes: jpegWithExif());
    final store = await startApp(tester, picker: picker);
    store.navigateToTab(1);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    expect(find.text('영수증이나 사진이 있어요?'), findsOneWidget);

    await tester.ensureVisible(find.text('사진 · 영수증 추가'));
    await tester.tap(find.text('사진 · 영수증 추가'));
    await tester.pumpAndSettle();
    // 어디서 가져올지 세 가지 길
    expect(find.text('사진 찍기'), findsOneWidget);
    expect(find.text('사진첩에서 고르기'), findsOneWidget);
    expect(find.text('파일에서 고르기 (PDF)'), findsOneWidget);

    await tester.tap(find.text('사진첩에서 고르기'));
    await tester.pumpAndSettle();
    expect(picker.asked, [EvidenceSource.photo]);
    expect(find.text('박스 파손.jpg'), findsOneWidget);
    // 앱이 그림 속 주소를 가려 주지는 않으므로 확인하라고 표시한다
    expect(find.text('주소 확인 필요'), findsOneWidget);
  });

  testWidgets('올릴 수 없는 파일을 고르면 까닭을 말하고 붙이지 않는다', (tester) async {
    final picker = FakeEvidencePicker()..problem = EvidenceProblem.tooLarge;
    final store = await startApp(tester, picker: picker);
    store.navigateToTab(1);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('사진 · 영수증 추가'));
    await tester.tap(find.text('사진 · 영수증 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('파일에서 고르기 (PDF)'));
    await tester.pumpAndSettle();
    expect(find.text('10MB보다 큰 파일은 올릴 수 없어요.'), findsOneWidget);
    expect(find.text('주소 확인 필요'), findsNothing);
  });

  testWidgets('마감 알림은 기기가 허용할 때만 켜지고, 막히면 까닭을 말한다', (tester) async {
    final reminders = FakeReminderScheduler(grant: false);
    final store = await startApp(tester, reminders: reminders);
    store.navigateToTab(4);
    await settle(tester);

    await tester.ensureVisible(find.text('마감 알림'));
    await tester.tap(find.text('마감 알림'));
    await settle(tester);
    expect(store.deadlineRemindersOn, false);
    expect(find.text('기기 설정에서 ReLo 알림을 허용해 주세요.'), findsOneWidget);

    reminders.grant = true;
    await tester.tap(find.text('마감 알림'));
    await settle(tester);
    expect(store.deadlineRemindersOn, true);
  });

  testWidgets('알림을 켜면 환불 건에 맞춰 알림을 맡기고, 언어를 바꾸거나 로그아웃하면 다시 맞춘다', (tester) async {
    final reminders = FakeReminderScheduler();
    final store = await startApp(tester, reminders: reminders, signedIn: true);
    // 서버에 붙은 상태로 만든다 (시험에서는 서버가 없어 예시 건을 보여 주는 상태로 시작한다)
    store.isOfflineFallback = false;
    final in5Days = DateTime.now()
        .add(const Duration(days: 5))
        .toIso8601String()
        .substring(0, 10);
    store.claims = [claim(id: 'clm_x', deadline: in5Days)];

    await store.setDeadlineReminders(true);
    await tester.pump();
    expect(reminders.replaced.last.length, 3);
    expect(reminders.replaced.last.first.title, '환불 마감 3일 전이에요');
    expect(reminders.replaced.last.first.body, 'Amazon US · 헤드폰 clm_x');
    expect(reminders.replaced.last.first.claimId, 'clm_x');

    // 바뀐 것이 없으면 다시 맡기지 않는다
    final calls = reminders.replaced.length;
    store.navigateToTab(0);
    await tester.pump();
    expect(reminders.replaced.length, calls);

    store.setLocale(ReloLocale.en);
    await tester.pump();
    expect(reminders.replaced.last.first.title, 'Refund deadline in 3 days');

    // 서버에 붙지 못한 동안에는 맞춰 둔 알림을 건드리지 않는다
    store.isOfflineFallback = true;
    store.claims = [];
    store.navigateToTab(4);
    await tester.pump();
    expect(reminders.replaced.last.length, 3);

    // 로그아웃하면 모두 지운다 (다른 사람이 이 기기를 쓸 수 있다).
    // 서버 응답을 기다리지 않고 바로 지우므로, 여기서도 기다리지 않는다.
    unawaited(store.logout());
    await tester.pump();
    expect(reminders.replaced.last, isEmpty);
  });

  testWidgets('로그인 전이거나 서버에 붙지 못했으면 맞춰 둔 알림을 건드리지 않고, 끄면 지운다', (tester) async {
    final reminders = FakeReminderScheduler();
    final store = await startApp(tester, reminders: reminders);
    // 서버가 없는 시험 환경: 예시 건이 보이지만 내 환불 건이 아니다
    await store.setDeadlineReminders(true);
    await tester.pump();
    expect(store.deadlineRemindersOn, true);
    expect(
      reminders.replaced.where((notices) => notices.isNotEmpty),
      isEmpty,
      reason: '예시 건으로는 알림을 맞추지 않는다',
    );

    await store.setDeadlineReminders(false);
    await tester.pump();
    expect(reminders.replaced.last, isEmpty);
  });

  testWidgets('상세에서 판매자가 정한 마감일을 적으면 그 날짜로 알림을 맞춘다', (tester) async {
    final reminders = FakeReminderScheduler();
    final store = await startApp(tester, reminders: reminders, signedIn: true);
    store.openClaimDetail('clm_amz_xm5');
    await tester.pumpAndSettle();

    // 마감일이 이미 있으면 "바꾸기", 없으면 "마감일 정하기"
    final open = find.text('바꾸기').evaluate().isNotEmpty
        ? find.text('바꾸기')
        : find.text('마감일 정하기');
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('판매자가 정한 기한이 있나요?'), findsOneWidget);

    // 판매자가 쓴 말이 없으면 저장하지 않는다 (지어낸 기한이 근거처럼 남지 않게)
    await tester.enterText(find.byType(TextField).last, '');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.text('판매자가 쓴 말을 그대로 적어 주세요.'), findsOneWidget);

    // 달력에서 날짜를 고르고, 판매자가 쓴 말을 적어 저장한다
    await tester.tap(find.byIcon(ReloIcons.calendar).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Return within 30 days of delivery');
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

    final saved = store.findClaim('clm_amz_xm5')!;
    expect(saved.deadline, isNotNull);
    expect(saved.deadlineQuote, 'Return within 30 days of delivery');
    expect(DateTime.parse(saved.deadline!).isAfter(DateTime.now().subtract(const Duration(days: 1))), true);

    // 알림을 켜 두었다면 이 마감일로 다시 맞춘다
    store.isOfflineFallback = false;
    await store.setDeadlineReminders(true);
    await tester.pump();
    expect(
      reminders.replaced.last.where((n) => n.claimId == 'clm_amz_xm5'),
      isNotEmpty,
    );
  });

  testWidgets('다른 앱에서 공유한 영수증으로 신청이 열리고, 예시 파일 대신 그 파일이 붙는다', (tester) async {
    final inbox = FakeSharedInbox();
    final store = await startApp(tester, inbox: inbox);
    expect(store.activeTabIndex, 0);

    inbox.waiting =
        EvidenceRules.prepare(name: 'Order Confirmation.pdf', bytes: '%PDF-1.7 order'.codeUnits);
    inbox.onArrived!();
    await tester.pumpAndSettle();
    expect(store.activeTabIndex, 1);
    expect(store.incomingEvidence, isNull, reason: '신청 화면이 가져갔다');
    // 서버가 읽어 주지 못해도 예시 값을 지어내지 않고, 붙였다고만 알린다
    expect(find.text('영수증을 붙였어요. 내용은 직접 적어 주세요.'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Order Confirmation.pdf'), findsOneWidget);
    expect(find.text('Amazon_Order_Receipt_Masked.pdf'), findsNothing, reason: '예시 파일은 뺀다');
  });

  testWidgets('공유받은 파일을 붙일 수 없으면 까닭을 말한다', (tester) async {
    final inbox = FakeSharedInbox();
    final store = await startApp(tester, inbox: inbox);
    inbox.problem = EvidenceProblem.unsupportedType;
    inbox.onArrived!();
    await settle(tester);
    expect(store.activeTabIndex, 0);
    expect(find.text('사진(JPG · PNG · WebP)이나 PDF만 올릴 수 있어요.'), findsOneWidget);
  });

  testWidgets('쓴 메시지를 메일 · 메신저로 넘긴다', (tester) async {
    final sharer = FakeTextSharer();
    final store = await startApp(tester, sharer: sharer);
    store.openClaimDetail('clm_amz_xm5', subTab: 0);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('메일 · 메신저로 보내기'));
    await tester.tap(find.text('메일 · 메신저로 보내기'));
    await tester.pump();
    final claim = store.findClaim('clm_amz_xm5')!;
    expect(sharer.shared.single.subject, '주문 ${claim.orderRef} 환불 요청');
    expect(sharer.shared.single.text, isNotEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('보낸 뒤에 "보냈어요"를 눌러 주세요.'), findsOneWidget);
  });

  testWidgets('알림을 눌러 들어오면 그 환불 건을 연다', (tester) async {
    final reminders = FakeReminderScheduler(openedClaim: 'clm_amz_xm5');
    final store = await startApp(tester, reminders: reminders);
    await settle(tester);
    expect(store.activeTabIndex, 2);
    expect(store.selectedClaimId, 'clm_amz_xm5');

    // 앱이 떠 있는 동안 다른 알림을 누르면 그 건으로 바뀐다. 없는 건이면 그대로 둔다.
    store.navigateToTab(0);
    await settle(tester);
    reminders.onOpened?.call('clm_없는건');
    await settle(tester);
    expect(store.activeTabIndex, 0);
  });
}
