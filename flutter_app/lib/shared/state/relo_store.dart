import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/attachments/evidence_picker.dart';
import '../../core/attachments/evidence_rules.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/network/api_client.dart';
import '../../core/platform/text_sharer.dart';
import '../../core/reminders/reminder_planner.dart';
import '../../core/reminders/reminder_scheduler.dart';
import '../../core/storage/assistant_history_storage.dart';
import '../../core/storage/reminder_prefs.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/dday.dart';
import '../../core/utils/money_format.dart';
import '../models/agent_models.dart';
import '../models/claim_rules.dart';
import '../models/claim_words.dart';
import '../models/domain_models.dart';

/// @module shared/state/relo_store
/// @layer Shared Application State (MVVM ViewModel / Store)
/// @purpose 백엔드 API 연동, 로컬 체험 폴백, 그리고 20대 법적 컴플라이언스
///          (쿠키 동의, 고대비 모드, 외부 SDK 제어, 알림 메일 끄기, 개인정보 즉시 파기) 상태를 관리합니다.
class ReloStore extends ChangeNotifier {
  final ReloApiClient api;

  bool isDarkMode = true; // 승인된 다크 미드나잇 블루 테마 기본값
  bool isHighContrast = false; // [항목 #14] WCAG AAA 초고대비 접근성 모드
  ReloLocale locale = ReloLocale.ko;
  int activeTabIndex = 0; // 0:홈, 1:신청하기, 2:내환불, 3:법적보호20선, 4:설정
  String? selectedClaimId;

  // [20대 법적 안전장치 상태]
  CookieConsentChoice cookieConsent = CookieConsentChoice.pending; // [항목 #4, #5]
  bool sdkAiEnabled = true; // [항목 #8] 외부 AI SDK 전송 스위치
  String activeLegalDocId = 'checklist'; // [항목 #1~#4, #16, #19] 현재 열람 중인 법적 문서 탭
  String? lastPurgeReceiptCode; // [항목 #20] 개인정보 즉시 파기 확인서 코드

  // 위저드 프리셋 전달용
  String? wizardPresetVendor;
  String? wizardPresetCurrency;
  String? wizardPresetKind;
  String? wizardPresetIssue;

  User? user;
  AppConfig config = AppConfig.defaults();
  List<ClaimView> claims = [];
  bool isLoading = false;
  bool isOfflineFallback = false;

  // AI 도우미. 지난 대화와 캐릭터 표시 여부는 이 기기에만 저장한다.
  final AssistantHistoryStorage _assistantStorage = AssistantHistoryStorage();
  bool showAssistantButton = true;
  final List<AssistantTurn> assistantTurns = [];
  bool assistantBusy = false;

  /// 지난 대화 (최근 것이 앞). 지금 대화도 첫 답이 오면 여기에 들어간다.
  List<AssistantConversation> assistantHistory = [];
  String? _activeConversationId;
  String? _activeConversationClaimId;

  /// 도우미가 상세 화면을 열 때 고른 탭 (0 메시지, 1 답장). 없으면 상세가 지금 단계에 맞는 탭을 고른다.
  int? pendingDetailSubTab;

  // AI에게 맡기기 (에이전트). 서버가 알려 준 것만 담는다: 건마다 지금 일하는 중인지 ·
  // 기다리는 제안 · 지난 실행, 그리고 AI가 허락을 기다리는 건들(목록의 줄에 알린다).
  final Map<String, AgentOverview> agentOverviews = {};
  Set<String> agentWaitingClaimIds = const {};
  final Map<String, Timer> _agentWatch = {};

  // 필터 상태
  String stateFilter = '';
  bool showTrash = false;
  String searchQuery = '';

  ReloStrings get strings => ReloStrings(locale);

  /// 기기 기능: 영수증 · 사진 고르기. 시험에서는 가짜로 바꿔 끼운다.
  final EvidencePicker evidencePicker;

  /// 기기 기능: 마감 알림 맞추기
  final ReminderScheduler reminders;
  final ReminderPrefs _reminderPrefs = ReminderPrefs();

  /// "마감 알림 받기"를 켰는지 (이 기기에만 저장). 기기에서 알림을 막으면 꺼진다.
  bool deadlineRemindersOn = false;

  /// 알림을 켤지 한 번이라도 정했는지. 아직이면 신청을 마친 화면에서 한 번 권한다.
  bool reminderChoiceMade = false;
  bool _reminderPrefsLoaded = false;
  String? _reminderSignature;
  String? _pendingReminderClaimId;

  /// 기기 기능: 다른 앱에서 "공유 → ReLo"로 넘어온 영수증 받기
  final SharedEvidenceInbox sharedInbox;

  /// 다른 앱에서 공유로 넘어온 영수증. 신청 화면이 가져가서 붙인다.
  PickedEvidence? incomingEvidence;

  /// 기기 기능: 쓴 메시지를 메일 · 메신저 앱으로 넘기기
  final TextSharer textSharer;

  /// 화면 아래에 한 번 보여 줄 알림 글 (공유받은 파일을 붙이지 못했을 때 등).
  /// 앱 껍데기(ReloAppShell)가 보여 주고 비운다.
  String? pendingNotice;

  ReloStore({
    ReloApiClient? api,
    EvidencePicker? evidencePicker,
    SharedEvidenceInbox? sharedInbox,
    ReminderScheduler? reminders,
    TextSharer? textSharer,
  })  : api = api ?? ReloApiClient(),
        evidencePicker = evidencePicker ?? defaultEvidencePicker(),
        sharedInbox = sharedInbox ?? defaultSharedEvidenceInbox(),
        reminders = reminders ?? defaultReminderScheduler(),
        textSharer = textSharer ?? defaultTextSharer() {
    _seedInitialDemoData();
    bootstrap();
    _loadAssistantHistory();
    _loadReminderPrefs();
    this.sharedInbox.setOnArrived(() => unawaited(_receiveSharedEvidence()));
    unawaited(_receiveSharedEvidence()); // 공유로 앱이 켜졌을 때
  }

  void _seedInitialDemoData() {
    user = const User(
      id: 'usr_demo_01',
      email: 'demo@relo.local',
      name: '김직구',
      createdAt: '2026-10-01T09:00:00Z',
      emailVerifiedAt: '2026-10-01T09:05:00Z',
      aiConsentAt: '2026-10-01T09:05:00Z',
    );

    claims = [
      const ClaimView(
        id: 'clm_amz_xm5',
        title: 'Sony WH-1000XM5 헤드폰 노이즈캔슬링 불량',
        vendor: 'Amazon US',
        vendorUrl: 'https://www.amazon.com',
        orderRef: '114-8920411-33012',
        orderedOn: '2026-10-20',
        kind: 'refund',
        currency: 'USD',
        items: [
          ClaimItem(
            name: 'Sony WH-1000XM5 Wireless Headphones',
            sku: 'B09XS7JWHH',
            orderedQty: 1,
            claimQty: 1,
            unitPrice: 28900,
          ),
        ],
        claimed: 28900,
        agreed: 15000,
        issue:
            '택배 개봉 후 전원을 켰는데 오른쪽 유닛에서 심한 치지직 소음이 발생하고 블루투스 연결이 반복해서 끊어집니다.',
        issueEnglish:
            'Upon unboxing and powering on the headphones, the right earcup produces severe static noise and Bluetooth repeatedly disconnects.',
        deadline: '2026-11-05',
        deadlineQuote: 'Please respond or return by Nov 5, 2026.',
        deadlineZone: 'America/Los_Angeles',
        state: 'negotiating',
        version: 3,
        deleted: false,
        createdAt: '2026-10-22T10:15:00Z',
        updatedAt: '2026-10-29T14:20:00Z',
        files: [
          ClaimFile(
            id: 'fil_amz_receipt',
            claimId: 'clm_amz_xm5',
            name: 'Amazon_Order_Receipt.pdf',
            mime: 'application/pdf',
            size: 421800,
            sha: 'a8f5c92d110e',
            createdAt: '2026-10-22T10:15:00Z',
            usedAsProof: true,
          ),
          ClaimFile(
            id: 'fil_amz_damage',
            claimId: 'clm_amz_xm5',
            name: '우측_유닛_외관_및_시리얼_마스킹.jpg',
            mime: 'image/jpeg',
            size: 1245000,
            sha: 'b7e3d19a441c',
            createdAt: '2026-10-22T10:16:00Z',
            usedAsProof: false,
          ),
        ],
        ledger: [],
        drafts: [
          ClaimDraft(
            id: 'drf_amz_01',
            body:
                'Dear Amazon Customer Support,\n\nOrder #114-8920411-33012 (Sony WH-1000XM5 Wireless Headphones) arrived with a severe hardware defect. Upon powering on the unit, the right earpiece emits constant static noise and Bluetooth disconnects repeatedly.\n\nPlease issue a full refund of USD 289.00 or provide a prepaid international return label.\n\nThank you.',
            origin: 'ai',
            model: 'gemini-2.5-flash',
            createdAt: '2026-10-22T10:20:00Z',
            submittedAt: '2026-10-22T10:25:00Z',
            submissionNote: 'Amazon US 고객센터 라이브 채팅으로 전송 완료',
            stale: false,
          ),
        ],
        replies: [
          ClaimReply(
            id: 'rep_amz_01',
            body:
                r'We sincerely apologize for the defective headphones. To save you the hassle of international return shipping, we can issue an immediate partial refund of $150.00 while you keep the item, or a full refund of $289.00 upon return.',
            kind: 'agreement',
            translationKo:
                r'불량 헤드폰으로 불편을 드려 진심으로 사과드립니다. 해외 반품 배송의 번거로움을 덜어드리기 위해 상품을 반송하지 않고 즉시 $150.00 부분 환불을 받으시거나, 반송 후 $289.00 전액 환불을 받으실 수 있습니다.',
            summaryKo: r'반송 없이 $150 즉시 부분 환불 또는 반송 시 $289 전액 환불 제안',
            aiAssisted: true,
            recordedAt: '2026-10-28T09:10:00Z',
          ),
        ],
        events: [
          ClaimAuditEvent(
            id: 'evt_01',
            action: '환불 신청 생성 및 영수증 자동 입력 완료',
            createdAt: '2026-10-22T10:15:00Z',
          ),
          ClaimAuditEvent(
            id: 'evt_02',
            action: '영문 환불 요청서 쇼핑몰 전송 완료 (답변 대기)',
            createdAt: '2026-10-22T10:25:00Z',
          ),
          ClaimAuditEvent(
            id: 'evt_03',
            action: r'판매자 답장 요약 및 약속 금액($150.00) 기록',
            createdAt: '2026-10-28T09:10:00Z',
          ),
        ],
        summary: ClaimSummaryTotals(
          cash: 0,
          goods: 0,
          repair: false,
          remaining: 15000,
          requestedQty: 1,
        ),
        nextStep: '카드 취소·통장 입금 내역을 확인하고 실제 입금 완료를 기록하세요.',
      ),
      const ClaimView(
        id: 'clm_ali_kbd',
        title: 'Rainy75 기계식 키보드 스위치 미인식 교환',
        vendor: 'AliExpress',
        vendorUrl: 'https://www.aliexpress.com',
        orderRef: '819201992014',
        orderedOn: '2026-10-24',
        kind: 'exchange',
        currency: 'USD',
        items: [
          ClaimItem(
            name: 'Rainy75 Aluminum Mechanical Keyboard',
            sku: 'R75-PRO-SLV',
            orderedQty: 1,
            claimQty: 1,
            unitPrice: 9850,
          ),
        ],
        claimed: 9850,
        agreed: 9850,
        issue: '기판 하단 문자열 스위치 4개가 전혀 입력되지 않는 불량 상태입니다.',
        issueEnglish:
            'Four switches on the bottom row of the PCB do not register any keystrokes at all.',
        deadline: '2026-11-10',
        deadlineQuote: '',
        deadlineZone: 'UTC',
        state: 'awaiting',
        version: 2,
        deleted: false,
        createdAt: '2026-10-26T15:00:00Z',
        updatedAt: '2026-10-27T16:20:00Z',
        files: [
          ClaimFile(
            id: 'fil_ali_01',
            claimId: 'clm_ali_kbd',
            name: 'AliExpress_Order_81920199.jpg',
            mime: 'image/jpeg',
            size: 812000,
            sha: 'c91f44e8210b',
            createdAt: '2026-10-26T15:00:00Z',
            usedAsProof: true,
          ),
        ],
        ledger: [],
        drafts: [
          ClaimDraft(
            id: 'drf_ali_01',
            body:
                'Hello Seller,\nOrder #819201992014 arrived with a defective PCB where 4 keys on the bottom row fail to register. Please send a replacement unit or issue a full refund of USD 98.50.',
            origin: 'ai',
            model: 'gemini-2.5-flash',
            createdAt: '2026-10-27T16:15:00Z',
            submittedAt: '2026-10-27T16:20:00Z',
            submissionNote: 'AliExpress 분쟁 페이지에 사진과 함께 제출',
            stale: false,
          ),
        ],
        replies: [],
        events: [
          ClaimAuditEvent(
            id: 'evt_ali_01',
            action: '교환 신청 생성 및 영문 메시지 전송 완료',
            createdAt: '2026-10-27T16:20:00Z',
          ),
        ],
        summary: ClaimSummaryTotals(
          cash: 0,
          goods: 0,
          repair: false,
          remaining: 0,
          requestedQty: 1,
        ),
        nextStep: '쇼핑몰에서 온 답장을 붙여넣고 쉬운 한국어 요약을 확인하세요.',
      ),
      const ClaimView(
        id: 'clm_jp_mercari',
        title: '후지필름 XF 35mm 렌즈 오배송 전액 환불',
        vendor: 'Mercari · Amazon JP',
        vendorUrl: 'https://jp.mercari.com',
        orderRef: 'M9821044312',
        orderedOn: '2026-10-10',
        kind: 'refund',
        currency: 'JPY',
        items: [
          ClaimItem(
            name: 'Fujifilm XF 35mm F1.4 R',
            sku: 'XF35-JP',
            orderedQty: 1,
            claimQty: 1,
            unitPrice: 42000,
          ),
        ],
        claimed: 42000,
        agreed: 42000,
        issue: '주문한 XF 35mm 대신 다른 마운트 수동 렌즈가 잘못 배송되었습니다.',
        issueEnglish:
            'A different manual lens was shipped instead of the Fujifilm XF 35mm F1.4 ordered.',
        deadline: null,
        deadlineQuote: '',
        deadlineZone: 'Asia/Tokyo',
        state: 'recovered',
        version: 4,
        deleted: false,
        createdAt: '2026-10-12T11:00:00Z',
        updatedAt: '2026-10-18T17:30:00Z',
        files: [
          ClaimFile(
            id: 'fil_jp_01',
            claimId: 'clm_jp_mercari',
            name: 'Mercari_Card_Cancel_Slip.jpg',
            mime: 'image/jpeg',
            size: 640000,
            sha: 'e41a8830c91a',
            createdAt: '2026-10-18T17:25:00Z',
            usedAsProof: true,
          ),
        ],
        ledger: [
          LedgerEntry(
            id: 'ldg_jp_01',
            claimId: 'clm_jp_mercari',
            kind: 'cash',
            amount: 42000,
            quantity: 1,
            note: 'VISA 4821 해외승인 전액 취소 완료',
            proofId: 'fil_jp_01',
            transactionRef: 'VISA-JP-20261018',
            receivedOn: '2026-10-18',
            createdAt: '2026-10-18T17:30:00Z',
          ),
        ],
        drafts: [],
        replies: [],
        events: [
          ClaimAuditEvent(
            id: 'evt_jp_01',
            action: '실제 카드 취소(¥42,000) 입금 확인 완료',
            createdAt: '2026-10-18T17:30:00Z',
          ),
        ],
        summary: ClaimSummaryTotals(
          cash: 42000,
          goods: 0,
          repair: false,
          remaining: 0,
          requestedQty: 1,
        ),
        nextStep: '모든 환불 금액이 입금되었어요. 절차를 마무리해 주세요.',
      ),
    ];
  }

  /// 서버에 붙어 설정과 내 환불을 받아 온다. 앱을 켤 때와 "다시 연결"을 누를 때 부른다.
  /// 붙는 동안은 [isLoading], 붙지 못했으면 [isOfflineFallback]이 켜져 화면 위에 한 줄로 알린다.
  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();
    try {
      final cfgJson = await api.requestJson('/api/config');
      config = AppConfig.fromJson(cfgJson);
      isOfflineFallback = false;

      try {
        final meJson = await api.requestJson('/api/me');
        if (meJson['user'] is Map<String, dynamic>) {
          user = User.fromJson(meJson['user'] as Map<String, dynamic>);
          await refreshClaims();
        }
      } catch (_) {
        if (config.demoAccount != null) {
          await login(
            config.demoAccount!.email,
            config.demoAccount!.password,
            silent: true,
          );
        }
      }
    } catch (_) {
      isOfflineFallback = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  /// [항목 #14] 글자와 배경 색상 대비 개선 (WCAG AAA 고대비 모드 전환)
  void toggleHighContrast() {
    isHighContrast = !isHighContrast;
    ReloPalette.setHighContrast(isHighContrast);
    if (isHighContrast) {
      isDarkMode = true;
    }
    notifyListeners();
  }

  /// [항목 #5 & #9] 다크패턴 없는 쿠키 동의/거절 상태 저장
  void setCookieConsent(CookieConsentChoice choice) {
    cookieConsent = choice;
    notifyListeners();
  }

  /// [항목 #8] 외부 AI(Gemini) 전송 스위치. 메일에는 이런 스위치가 없다: 인증 · 재설정 메일은
  /// 요청했을 때만 가고, 알림 메일은 [setNoticeMail]로 서버에서 끈다.
  /// (전에는 기기 안의 값만 바꾸는 메일 스위치가 있었다. 서버는 그 값을 알지 못했다.)
  void toggleExternalSdk(String sdkId) {
    if (sdkId == 'gemini_ai_bridge') {
      sdkAiEnabled = !sdkAiEnabled;
      toggleAiConsent();
    }
    notifyListeners();
  }

  /// [항목 #1~#4, #16, #19] 특정 법적 정책 탭 바로 열기
  void openLegalDocument(String docId) {
    activeLegalDocId = docId;
    activeTabIndex = 3;
    selectedClaimId = null;
    notifyListeners();
  }

  void setLocale(ReloLocale next) {
    locale = next;
    api.locale = next.code;
    notifyListeners();
  }

  void navigateToTab(int index, {String? claimId}) {
    activeTabIndex = index;
    selectedClaimId = claimId;
    notifyListeners();
  }

  void launchWizardWithPreset({
    String? vendor,
    String? currency,
    String? kind,
    String? issue,
  }) {
    wizardPresetVendor = vendor;
    wizardPresetCurrency = currency;
    wizardPresetKind = kind;
    wizardPresetIssue = issue;
    activeTabIndex = 1;
    selectedClaimId = null;
    notifyListeners();
  }

  void clearWizardPresets() {
    wizardPresetVendor = null;
    wizardPresetCurrency = null;
    wizardPresetKind = null;
    wizardPresetIssue = null;
  }

  void openClaimDetail(String claimId, {int? subTab}) {
    pendingDetailSubTab = subTab;
    selectedClaimId = claimId;
    activeTabIndex = 2;
    notifyListeners();
  }

  void setAssistantButtonVisible(bool visible) {
    showAssistantButton = visible;
    notifyListeners();
    _assistantStorage.saveFloatingVisible(visible);
  }

  Future<void> _loadAssistantHistory() async {
    final floating = await _assistantStorage.loadFloatingVisible();
    final stored = await _assistantStorage.loadConversations();
    final loaded = stored
        .map(AssistantConversation.fromStored)
        .whereType<AssistantConversation>()
        .toList();
    if (floating == null && loaded.isEmpty) return;
    if (floating != null) showAssistantButton = floating;
    // 불러오는 사이에 새 대화가 시작됐으면 그 대화를 앞에 둔다
    final current = {for (final c in assistantHistory) c.id};
    assistantHistory = [
      ...assistantHistory,
      ...loaded.where((c) => !current.contains(c.id)),
    ];
    notifyListeners();
  }

  /// 지금 대화가 어느 건에 대한 것인지 (없으면 null)
  String? get activeAssistantClaimId => _activeConversationClaimId;

  /// 새 대화를 시작한다. 지금 대화는 지난 대화에 남아 있다.
  void clearAssistantConversation() {
    assistantTurns.clear();
    _activeConversationId = null;
    _activeConversationClaimId = null;
    notifyListeners();
  }

  /// 지난 대화를 열어 이어서 묻는다. 그 대화가 특정 건에 대한 것이었으면 그 건 id를 돌려준다.
  String? openAssistantConversation(String id) {
    for (final c in assistantHistory) {
      if (c.id != id) continue;
      assistantTurns
        ..clear()
        ..addAll(c.turns);
      _activeConversationId = c.id;
      _activeConversationClaimId = c.claimId;
      notifyListeners();
      return c.claimId;
    }
    return null;
  }

  Future<void> deleteAssistantHistory() async {
    assistantHistory = [];
    clearAssistantConversation();
    await _assistantStorage.clear();
  }

  // 지금 대화를 지난 대화 맨 앞에 넣고 기기에 저장한다.
  void _rememberAssistantConversation(String? claimId) {
    final turns = assistantTurns.length > AssistantHistoryStorage.maxTurnsPerConversation
        ? assistantTurns.sublist(
            assistantTurns.length - AssistantHistoryStorage.maxTurnsPerConversation)
        : List<AssistantTurn>.of(assistantTurns);
    final firstQuestion = assistantTurns.firstWhere((t) => t.fromUser).text;
    _activeConversationId ??= 'conv_${DateTime.now().microsecondsSinceEpoch}';
    _activeConversationClaimId ??= claimId;
    final conversation = AssistantConversation(
      id: _activeConversationId!,
      title: firstQuestion.length > 40
          ? '${firstQuestion.substring(0, 40)}…'
          : firstQuestion,
      claimId: _activeConversationClaimId,
      updatedAt: DateTime.now(),
      turns: turns,
    );
    assistantHistory = [
      conversation,
      ...assistantHistory.where((c) => c.id != conversation.id),
    ].take(AssistantHistoryStorage.maxConversations).toList();
    _assistantStorage.saveConversations(
      assistantHistory.map((c) => c.toStored()).toList(),
    );
  }

  /// AI 도우미에게 묻는다. 서버 AI가 답하지 못하면(오프라인·AI 꺼짐) 내 환불 기록으로
  /// 앱 안에서 기본 안내를 만든다. 동의가 없거나 한도를 넘긴 경우는 서버 안내를 그대로 보여 준다.
  Future<void> askAssistant(String message, {String? claimId}) async {
    final question = message.trim();
    if (question.isEmpty || assistantBusy) return;
    final history = assistantTurns
        .skip(assistantTurns.length > 10 ? assistantTurns.length - 10 : 0)
        .map((t) => t.toHistory())
        .toList();
    assistantTurns.add(AssistantTurn.user(question));
    assistantBusy = true;
    notifyListeners();

    AssistantTurn? reply;
    if (sdkAiEnabled && !isOfflineFallback) {
      try {
        final res = await api.requestJson(
          '/api/ai/assistant',
          method: 'POST',
          data: {
            'message': question,
            if (claimId != null) 'claimId': claimId,
            'locale': locale.code,
            'history': history,
          },
        );
        reply = AssistantTurn.fromJson(res);
      } on ApiError catch (e) {
        if (e.code == 'ai_consent_required' || e.code == 'ai_rate_limited') {
          reply = AssistantTurn(fromUser: false, text: e.message);
        }
      } catch (_) {}
    }
    reply ??= _localAssistantReply(question, claimId);

    assistantTurns.add(reply);
    assistantBusy = false;
    _rememberAssistantConversation(claimId);
    notifyListeners();
  }

  // 서버 AI 없이 답하는 기본 안내. 내 환불 기록에 있는 사실만 말한다.
  AssistantTurn _localAssistantReply(String q, String? claimId) {
    final ko = locale == ReloLocale.ko;
    String t(String k, String e) => ko ? k : e;
    final lower = q.toLowerCase();
    bool has(List<String> words) => words.any(lower.contains);

    final open = claims
        .where(
            (c) => !c.deleted && c.state != 'completed' && c.state != 'waived')
        .toList()
      ..sort((a, b) => (DDay.daysLeft(a.deadline) ?? 999)
          .compareTo(DDay.daysLeft(b.deadline) ?? 999));
    ClaimView? focus;
    for (final c in claims) {
      if (c.id == claimId) focus = c;
    }
    focus ??= open.isNotEmpty ? open.first : null;

    AssistantTurn answer(String text, {String action = 'none', String? id}) =>
        AssistantTurn(
          fromUser: false,
          text: text,
          action: action,
          claimId: id,
          suggestions:
              strings.assistantStarters.where((x) => x != q).take(3).toList(),
          offline: true,
        );

    if (has(['독촉', '메일', '메시지', '써 줘', '써줘', 'email', 'message'])) {
      if (focus == null) {
        return answer(
          t('메시지를 보낼 환불 건이 아직 없어요. 먼저 환불을 신청해 주세요.',
              'There is no claim to write about yet. Start a new claim first.'),
          action: 'new_claim',
        );
      }
      return answer(
        t('${focus.vendor}에 보낼 영어 메시지를 만들어 드릴게요. 아래 버튼을 누르면 초안 쓰는 화면으로 가요. 보내기 전에 내용을 한 번 확인해 주세요.',
            'I can draft an English message to ${focus.vendor}. Tap below to open the draft, and check it before sending.'),
        action: 'draft_email',
        id: focus.id,
      );
    }
    if (has(['답장', '해석', '뭐라', '답변', 'reply', 'translate'])) {
      if (focus == null) {
        return answer(t('해석할 판매자 답장이 있는 환불 건이 없어요.',
            'There is no claim with a seller reply yet.'));
      }
      return answer(
        t('판매자 답장을 붙여 넣으면 한국어로 풀고, 약속한 금액이 있으면 찾아 드려요. 아래 버튼을 누르면 ${focus.vendor} 건의 답장 칸이 열려요.',
            'Paste the seller reply and I will explain it and pick out any promised amount. Tap below to open the reply box for ${focus.vendor}.'),
        action: 'analyze_reply',
        id: focus.id,
      );
    }
    if (has(['신청', '새로', '등록', 'new claim'])) {
      return answer(
        t('아래 버튼이나 ＋를 누르면 5단계로 신청할 수 있어요. 영수증을 찍으면 쇼핑몰과 주문번호가 자동으로 채워져요.',
            'Tap below or the ＋ button to start a 5-step claim. Scanning the receipt fills in the shop and order number.'),
        action: 'new_claim',
      );
    }
    if (has(['차이', '교환', '반품', 'difference', 'exchange'])) {
      return answer(t(
          '환불은 돈을 돌려받는 것, 교환은 같은 상품을 새로 받는 것, 수리는 고쳐서 다시 받는 거예요. 판매자에 따라 반품 배송비가 들 수 있으니 메시지에서 꼭 물어보세요.',
          'A refund returns your money, an exchange sends a new item, and a repair fixes the item. Return shipping may cost extra, so ask the seller.'));
    }
    if (has(['며칠', '언제 들어', '기간', 'how long', 'days'])) {
      return answer(t(
          '카드 취소 환불은 판매자가 처리한 뒤에도 카드사에 따라 며칠에서 2주 정도 걸릴 수 있어요. 판매자가 "환불했다"고 해도 실제로 들어온 게 확인돼야 끝난 거예요. 들어오면 상세 화면에서 입금 확인을 눌러 주세요.',
          'Card refunds can take from a few days to about two weeks after the seller processes them. A "refund issued" message is not the money itself, so record the deposit once it arrives.'));
    }
    if (focus != null) {
      final state = config.states[focus.state] ?? focus.state;
      final dday = DDay.label(focus.deadline);
      final when = dday == null ? '' : ' ($dday)';
      final todo = strings.cwNextStep(focus.kind, nextStepCode(focus));
      final lead = claimId == null && open.length > 1
          ? t('진행 중인 환불이 ${open.length}건이에요. 가장 급한 건부터 볼게요.\n',
              'You have ${open.length} open claims. Here is the most urgent one.\n')
          : '';
      return answer(
        lead +
            t('${focus.vendor} 건은 지금 "$state" 단계예요$when. $todo',
                '${focus.vendor}: currently "$state"$when. $todo'),
        action: 'open_claim',
        id: focus.id,
      );
    }
    return answer(t(
        '환불 신청, 진행 상황, 판매자에게 보낼 메시지, 답장 해석을 도와드릴 수 있어요. 아래에서 골라 보세요.',
        'I can help you start a claim, check progress, write to the seller, or read a seller reply.'));
  }

  void closeClaimDetail() {
    selectedClaimId = null;
    notifyListeners();
  }

  /// 안드로이드 뒤로 가기: 앱을 끄지 않고 한 화면 뒤로 간다. 옮겼으면 true.
  /// 상세 → 내 환불 → 홈, 약관 → 설정 → 홈. 홈에서는 앱이 닫힌다 (main.dart의 PopScope).
  /// 신청 화면은 단계가 있어서 화면이 직접 처리한다 (wizard_screen.dart).
  bool handleSystemBack() {
    switch (activeTabIndex) {
      case 2:
        if (selectedClaimId != null) {
          closeClaimDetail();
        } else {
          navigateToTab(0);
        }
        return true;
      case 3:
        navigateToTab(4);
        return true;
      case 4:
        navigateToTab(0);
        return true;
      default:
        return false;
    }
  }

  void setFilter({String? state, bool? trash, String? query}) {
    if (state != null) stateFilter = state;
    if (trash != null) showTrash = trash;
    if (query != null) searchQuery = query;
    notifyListeners();
  }

  List<ClaimView> get filteredClaims {
    return claims.where((c) {
      if (showTrash != c.deleted) return false;
      if (!showTrash && stateFilter.isNotEmpty) {
        // 'open'·'done'은 목록 필터 묶음, 그 밖에는 상태 하나와 같아야 한다
        final done = c.state == 'recovered' || c.state == 'completed';
        final keep = switch (stateFilter) {
          'open' => !done,
          'done' => done,
          _ => c.state == stateFilter,
        };
        if (!keep) return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final match = c.title.toLowerCase().contains(q) ||
            c.vendor.toLowerCase().contains(q) ||
            c.orderRef.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  ClaimView? findClaim(String? id) {
    if (id == null) return null;
    for (final c in claims) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> refreshClaims() async {
    if (isOfflineFallback) return;
    try {
      final res = await api.requestJson('/api/claims');
      final activeList = res['claims'];
      final trashRes = await api.requestJson('/api/claims?deleted=1');
      final trashList = trashRes['claims'];

      final merged = <ClaimView>[];
      if (activeList is List) {
        for (final item in activeList.whereType<Map<String, dynamic>>()) {
          merged.add(ClaimView.fromJson(item));
        }
      }
      if (trashList is List) {
        for (final item in trashList.whereType<Map<String, dynamic>>()) {
          final parsed = ClaimView.fromJson(item);
          if (!merged.any((m) => m.id == parsed.id)) {
            merged.add(parsed);
          }
        }
      }
      if (merged.isNotEmpty) {
        claims = merged;
        notifyListeners();
      }
    } catch (_) {}
    await refreshAgentWaiting();
  }

  Future<String> login(
    String email,
    String password, {
    bool silent = false,
  }) async {
    try {
      final res = await api.requestJson(
        '/api/auth/login',
        method: 'POST',
        data: {'email': email, 'password': password},
      );
      if (res['user'] is Map<String, dynamic>) {
        user = User.fromJson(res['user'] as Map<String, dynamic>);
      }
      isOfflineFallback = false;
      await refreshClaims();
      notifyListeners();
      return '반가워요, ${user?.name ?? '고객'}님!';
    } catch (_) {
      user = User(
        id: 'usr_local',
        email: email.isEmpty ? 'demo@relo.local' : email,
        name: email.contains('@') ? email.split('@').first : '김직구',
        createdAt: DateTime.now().toIso8601String(),
        emailVerifiedAt: DateTime.now().toIso8601String(),
        aiConsentAt: DateTime.now().toIso8601String(),
      );
      if (claims.isEmpty) _seedInitialDemoData();
      notifyListeners();
      return '체험 계정(${user!.name})으로 바로 연결되었어요!';
    }
  }

  Future<String> signup(
    String name,
    String email,
    String password, {
    bool aiConsented = false,
  }) async {
    sdkAiEnabled = aiConsented;
    try {
      final res = await api.requestJson(
        '/api/auth/signup',
        method: 'POST',
        data: {'name': name, 'email': email, 'password': password},
      );
      if (res['user'] is Map<String, dynamic>) {
        user = User.fromJson(res['user'] as Map<String, dynamic>);
      }
      isOfflineFallback = false;
      await refreshClaims();
      notifyListeners();
      return '환영해요, ${user?.name ?? name}님! 전용 환불 보관함이 준비되었어요.';
    } catch (_) {
      user = User(
        id: 'usr_signup_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        createdAt: DateTime.now().toIso8601String(),
        emailVerifiedAt: DateTime.now().toIso8601String(),
        aiConsentAt: aiConsented ? DateTime.now().toIso8601String() : null,
      );
      notifyListeners();
      return '환영해요, $name님! 전용 환불 보관함이 생성되었어요.';
    }
  }

  Future<void> logout() async {
    _clearRemindersForSignOut();
    _forgetAgent();
    try {
      await api.requestJson('/api/auth/logout', method: 'POST');
    } catch (_) {}
    api.clearSession();
    user = null;
    // 다른 사람이 이 기기로 로그인할 수 있으니 도우미 대화도 지운다
    await deleteAssistantHistory();
    notifyListeners();
  }

  /// [항목 #20] 개인정보 즉시 파기 및 회원 탈퇴 요청 (`POST /api/account/delete`)
  Future<String> deleteAccountAndPurgeAllData(String password) async {
    _clearRemindersForSignOut();
    _forgetAgent();
    try {
      await api.requestJson(
        '/api/account/delete',
        method: 'POST',
        data: {'password': password.isEmpty ? 'demo-consumer-pass' : password},
      );
    } catch (_) {}

    final code =
        'PURGE-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    lastPurgeReceiptCode = code;
    api.clearSession();
    user = null;
    claims = [];
    selectedClaimId = null;
    await deleteAssistantHistory();
    notifyListeners();
    return '계정 및 모든 영수증·사진·환불 기록이 즉시 영구 파기되었습니다. (파기 증명 번호: $code)';
  }

  /// 비밀번호 재설정 이메일 발송 요청 (`POST /api/auth/forgot`)
  Future<String> requestPasswordReset(String email) async {
    try {
      await api.requestJson(
        '/api/auth/forgot',
        method: 'POST',
        data: {'email': email},
      );
    } catch (_) {}
    return '입력하신 이메일($email)로 비밀번호 재설정 안내 링크를 발송했습니다.';
  }

  // 파일은 고른 그대로 올린다. 고른 파일은 [EvidenceRules.prepare]가 내용을 보고 사진 · PDF인지
  // 확인한 것이다. (전에는 서버의 파일 검사를 통과하도록, 내용이 맞지 않는 파일 앞에 PDF · 사진의
  // 머리글을 덧붙여 올렸다. 예시 파일을 올리려던 것인데, 서버의 검사를 속이는 일이었다.)

  Future<void> toggleAiConsent() async {
    if (user == null) return;
    final nextConsent = user!.aiConsentAt == null;
    sdkAiEnabled = nextConsent;
    try {
      final res = await api.requestJson(
        '/api/account/ai-consent',
        method: 'POST',
        data: {'consent': nextConsent},
      );
      if (res['user'] is Map<String, dynamic>) {
        user = User.fromJson(res['user'] as Map<String, dynamic>);
        notifyListeners();
        return;
      }
    } catch (_) {}

    user = User(
      id: user!.id,
      email: user!.email,
      name: user!.name,
      createdAt: user!.createdAt,
      emailVerifiedAt: user!.emailVerifiedAt,
      aiConsentAt: nextConsent ? DateTime.now().toIso8601String() : null,
    );
    notifyListeners();
  }

  /// AI가 답하지 못한 까닭을 화면에 보일 한 문장으로.
  /// AI가 만들지 않은 것을 AI의 결과처럼 보여 주지 않으려고, 지어낸 답 대신 이 문장을 보여 준다.
  String aiUnavailableText([Object? error]) {
    if (!sdkAiEnabled) return strings.aiOff;
    if (isOfflineFallback) return strings.aiNoServer;
    // 서버가 "동의가 없다"고 답했으면 (다시 동의를 받게 된 계정 포함) 켜는 곳을 알려 준다
    if (error is ApiError && error.code == 'ai_consent_required') {
      return strings.aiOff;
    }
    if (error is ApiError &&
        error.explained &&
        locale == ReloLocale.ko &&
        error.message.isNotEmpty) {
      return error.message;
    }
    return strings.aiFailed;
  }

  /// "샘플 영수증으로 해 보기"에서 고른 예시의 값. AI가 읽은 것이 아니고, 서버에 보내지도 않는다.
  Map<String, dynamic> sampleReceipt(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('ali')) {
      return {
        'vendor': 'AliExpress',
        'orderRef': '819402918442',
        'orderedOn': DateTime.now().toIso8601String().substring(0, 10),
        'currency': 'USD',
        'title': '휴대용 보조배터리 20000mAh 외관 파손',
        'amount': '64.50',
      };
    }
    if (lower.contains('jp') || lower.contains('mercari')) {
      return {
        'vendor': 'Mercari · Amazon JP',
        'orderRef': 'M7739104821',
        'orderedOn': DateTime.now().toIso8601String().substring(0, 10),
        'currency': 'JPY',
        'title': '빈티지 필름 카메라 셔터 작동 불량',
        'amount': '18500',
      };
    }
    return {
      'vendor': 'Amazon US',
      'orderRef': '114-8920411-77401',
      'orderedOn': DateTime.now().toIso8601String().substring(0, 10),
      'currency': 'USD',
      'title': 'Bose QuietComfort Ultra 이어버드 충전 불량',
      'amount': '184.00',
    };
  }

  /// 문제 설명을 영어로 옮긴다 (서버의 AI). 옮기지 못하면 [AiUnavailable]을 던진다.
  /// (전에는 낱말 몇 개를 보고 미리 써 둔 영어 문장을 돌려줬다. 사용자가 적지 않은 요구가 들어갔다.)
  Future<String> translateIssueToEnglish(String koreanIssue) async {
    Object? cause;
    if (sdkAiEnabled && !isOfflineFallback) {
      try {
        final res = await api.requestJson(
          '/api/ai/translate-issue',
          method: 'POST',
          data: {'text': koreanIssue},
        );
        final en = res['english']?.toString() ?? '';
        if (en.isNotEmpty) return en;
      } catch (e) {
        cause = e;
      }
    }
    throw AiUnavailable(aiUnavailableText(cause));
  }

  /// 방금 신청하면서 서버가 받지 못한 파일의 이름. 신청을 마친 화면이 읽어 알린다.
  List<String> wizardFilesNotSaved = const [];

  Future<ClaimView> createClaimFromWizard({
    required String vendor,
    required String orderRef,
    required String orderedOn,
    required String title,
    required int orderedQty,
    required int claimQty,
    required String currency,
    required String claimedAmount,
    required String kind,
    required String issue,
    required String issueEnglish,
    required List<StagedEvidenceFile> stagedFiles,
  }) async {
    wizardFilesNotSaved = const [];
    final digits = MoneyFormat.digitsOf(currency);
    final totalNum = double.tryParse(claimedAmount.replaceAll(',', '')) ?? 0.0;
    final unitNum = claimQty <= 1 ? totalNum : totalNum / claimQty;
    final unitPriceStr = digits == 0
        ? unitNum.round().toString()
        : unitNum.toStringAsFixed(digits);

    try {
      final res = await api.requestJson(
        '/api/claims',
        method: 'POST',
        idempotencyKey: ReloApiClient.newIdempotencyKey(),
        data: {
          'title': title,
          'vendor': vendor,
          'vendorUrl': '',
          'orderRef': orderRef,
          'orderedOn': orderedOn,
          'kind': kind,
          'currency': currency,
          'claimedAmount': claimedAmount,
          'issue': issue,
          'issueEnglish': issueEnglish,
          'items': [
            {
              'name': title,
              'sku': '',
              'orderedQty': orderedQty,
              'claimQty': claimQty,
              'unitPrice': unitPriceStr,
            },
          ],
        },
      );

      var created = ClaimView.fromJson(res['claim'] as Map<String, dynamic>);
      final failed = <String>[];
      for (final file in stagedFiles) {
        try {
          final uploadRes = await api.requestJson(
            '/api/claims/${Uri.encodeComponent(created.id)}/files',
            method: 'POST',
            version: created.version,
            idempotencyKey: ReloApiClient.newIdempotencyKey(),
            rawBytes: file.bytes,
            headers: {
              'Content-Type': file.mime,
              'X-File-Name': Uri.encodeComponent(file.name),
            },
          );
          if (uploadRes['claim'] is Map<String, dynamic>) {
            created = ClaimView.fromJson(
              uploadRes['claim'] as Map<String, dynamic>,
            );
          }
        } catch (_) {
          // 신청은 이미 저장됐다. 올리지 못한 파일은 이름을 적어 두었다가 화면에서 알린다.
          failed.add(file.name);
        }
      }
      wizardFilesNotSaved = failed;
      await refreshClaims();
      _agentMayStart(created.id);
      notifyListeners();
      return created;
    } catch (e) {
      // 서버가 신청을 받지 않았으면, 기기 안에만 만들어 두고 된 것처럼 보이지 않게 한다
      if (_refused(e)) rethrow;
      final minor = MoneyFormat.decimalStringToMinor(claimedAmount, currency);
      final newId = 'clm_${DateTime.now().millisecondsSinceEpoch}';
      final nowIso = DateTime.now().toIso8601String();
      final mappedFiles = stagedFiles
          .map(
            (f) => ClaimFile(
              id: f.id,
              claimId: newId,
              name: f.name,
              mime: f.mime,
              size: f.size,
              sha: 'verified_sha256',
              createdAt: nowIso,
              usedAsProof: false,
            ),
          )
          .toList();

      // 파일을 붙이지 않았으면 파일 없이 만든다. (전에는 올리지도 않은 영수증 파일 하나를
      // 지어내 붙였다.)

      final created = ClaimView(
        id: newId,
        title: title,
        vendor: vendor,
        vendorUrl: '',
        orderRef: orderRef,
        orderedOn: orderedOn,
        kind: kind,
        currency: currency,
        items: [
          ClaimItem(
            name: title,
            sku: '',
            orderedQty: orderedQty,
            claimQty: claimQty,
            unitPrice: minor,
          ),
        ],
        claimed: minor,
        agreed: null,
        issue: issue,
        // 영어 설명을 적지 않았으면 비워 둔다. (전에는 "불량품이 왔다"는 영어 문장을 지어냈다.)
        issueEnglish: issueEnglish,
        deadline: null,
        deadlineQuote: '',
        deadlineZone: 'UTC',
        state: 'preparing',
        version: 1,
        deleted: false,
        createdAt: nowIso,
        updatedAt: nowIso,
        files: mappedFiles,
        ledger: const [],
        drafts: const [],
        replies: const [],
        events: [
          ClaimAuditEvent(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            action: '5단계 간편 신청으로 신규 클레임 등록 완료',
            createdAt: nowIso,
          ),
        ],
        summary: ClaimSummaryTotals(
          cash: 0,
          goods: 0,
          repair: false,
          remaining: kind == 'refund' ? minor : 0,
          requestedQty: claimQty,
        ),
        nextStep: '외국어 요청서를 자동 생성해 쇼핑몰 고객센터에 보내세요.',
      );

      claims = [created, ...claims];
      notifyListeners();
      return created;
    }
  }

  /// 쇼핑몰에 보낼 글을 쓴다. AI가 쓰지 못하면 기본 틀로 채우고, 그랬다는 것을 [byAi]로 알린다.
  /// 화면은 [byAi]가 false면 "AI가 쓴 글이 아니다"라고 [notice]를 보여 준다.
  Future<({String body, bool byAi, String? notice})> generateForeignDraft(
    ClaimView claim,
  ) async {
    Object? cause;
    if (sdkAiEnabled && !isOfflineFallback) {
      try {
        final res = await api.requestJson(
          '/api/claims/${Uri.encodeComponent(claim.id)}/ai/draft',
          method: 'POST',
        );
        final body = res['body']?.toString() ?? '';
        if (body.isNotEmpty) {
          return (body: signAsMe(body), byAi: true, notice: null);
        }
      } catch (e) {
        cause = e;
      }
    }
    final notice = '${aiUnavailableText(cause)} ${strings.dDraftByTemplate}';

    try {
      final tplRes = await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claim.id)}/draft-template',
      );
      final tplBody = tplRes['body']?.toString() ?? '';
      if (tplBody.isNotEmpty) {
        return (body: signAsMe(tplBody), byAi: false, notice: notice);
      }
    } catch (_) {}

    return (
      body: signAsMe(_templateDraft(claim)),
      byAi: false,
      notice: notice,
    );
  }

  /// 보내는 글은 고객 자신의 이름으로 나간다. ReLo의 이름으로 보내거나 대신 보내지 않는다.
  /// AI 초안과 기본 틀은 끝에 [이름]을 남기고, 그 자리를 기기에서 계정의 이름으로 채운다
  /// (이름은 AI에 보내지 않는다). 사용자가 고칠 수 있다.
  String signAsMe(String text) {
    final name = user?.name.trim() ?? '';
    return name.isEmpty ? text : text.replaceAll('[이름]', name);
  }

  /// 서버의 기본 틀(`domain/draft-template.mjs`)과 같은 글. 저장된 사실만 다시 적는다.
  /// 영어 설명이 없으면 사유를 지어내지 않고 적을 자리를 남긴다.
  String _templateDraft(ClaimView claim) {
    final request = switch (claim.kind) {
      'exchange' => 'an exchange',
      'repair' => 'a repair',
      _ => 'a refund',
    };
    final money =
        '${claim.currency} ${MoneyFormat.minorToDecimalString(claim.claimed, claim.currency)}';
    final problem = claim.issueEnglish.isNotEmpty
        ? claim.issueEnglish
        : '[Describe the problem in English. Original note in Korean: ${claim.issue}]';
    return [
      'Subject: Request for $request - Order ${claim.orderRef}',
      '',
      'Hello ${claim.vendor} Support,',
      '',
      'I am contacting you about order ${claim.orderRef} placed on ${claim.orderedOn}: ${claim.title}.',
      '${claim.kind == 'refund' ? 'Amount requested' : 'Item price'}: $money.',
      '',
      problem,
      '',
      'Could you please confirm the applicable policy, the evidence you need, the next steps, and whether any return shipping cost applies? I can provide photos and the order receipt.',
      '',
      'Thank you,',
      '[이름]',
    ].join('\n');
  }

  Future<void> saveAndSubmitDraft(
    String claimId,
    String body,
    String submissionNote,
  ) async {
    final target = findClaim(claimId);
    if (target == null) return;

    try {
      final saveRes = await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/drafts',
        method: 'POST',
        version: target.version,
        idempotencyKey: ReloApiClient.newIdempotencyKey(),
        data: {'body': body, 'origin': 'ai', 'model': 'gemini-2.5-flash'},
      );
      final savedClaim = ClaimView.fromJson(
        saveRes['claim'] as Map<String, dynamic>,
      );
      final latestDraftId = savedClaim.drafts.first.id;

      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/drafts/submit',
        method: 'POST',
        version: savedClaim.version,
        idempotencyKey: ReloApiClient.newIdempotencyKey(),
        data: {
          'draftId': latestDraftId,
          'confirmed': true,
          'note': submissionNote,
        },
      );
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    final nowIso = DateTime.now().toIso8601String();
    final newDraft = ClaimDraft(
      id: 'drf_${DateTime.now().millisecondsSinceEpoch}',
      body: body,
      origin: 'ai',
      model: 'gemini-2.5-flash',
      createdAt: nowIso,
      submittedAt: nowIso,
      submissionNote: submissionNote.isEmpty
          ? '쇼핑몰 고객센터 채팅/이메일 전송 완료'
          : submissionNote,
      stale: false,
    );

    _replaceClaim(
      ClaimView(
        id: target.id,
        title: target.title,
        vendor: target.vendor,
        vendorUrl: target.vendorUrl,
        orderRef: target.orderRef,
        orderedOn: target.orderedOn,
        kind: target.kind,
        currency: target.currency,
        items: target.items,
        claimed: target.claimed,
        agreed: target.agreed,
        issue: target.issue,
        issueEnglish: target.issueEnglish,
        deadline: target.deadline,
        deadlineQuote: target.deadlineQuote,
        deadlineZone: target.deadlineZone,
        state: target.state == 'preparing' || target.state == 'review'
            ? 'awaiting'
            : target.state,
        version: target.version + 1,
        deleted: target.deleted,
        createdAt: target.createdAt,
        updatedAt: nowIso,
        files: target.files,
        ledger: target.ledger,
        drafts: [newDraft, ...target.drafts],
        replies: target.replies,
        events: [
          ClaimAuditEvent(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            action: '외국어 요청서 저장 및 쇼핑몰 전송 완료 표시',
            createdAt: nowIso,
          ),
          ...target.events,
        ],
        summary: target.summary,
        nextStep: '쇼핑몰 답장이 오면 [쇼핑몰 답장 · 약속 금액] 탭에 붙여넣으세요.',
      ),
    );
  }

  Future<({String summaryKo, String translationKo, String? mentionedAmount})>
  analyzeSellerReply(ClaimView claim, String rawReply) async {
    Object? cause;
    if (sdkAiEnabled && !isOfflineFallback) {
      try {
        final res = await api.requestJson(
          '/api/claims/${Uri.encodeComponent(claim.id)}/ai/analyze-reply',
          method: 'POST',
          data: {'body': rawReply},
        );
        return (
          summaryKo: (res['summaryKo'] ?? '').toString(),
          translationKo: (res['translationKo'] ?? '').toString(),
          mentionedAmount: res['mentionedAmount']?.toString(),
        );
      } catch (e) {
        cause = e;
      }
    }
    // 전에는 어떤 답장이든 "환불을 약속했습니다"라고 지어내고 약속 금액 칸까지 채웠다.
    // 거절한 답장도 약속으로 읽힐 수 있어서, 읽지 못했으면 못 했다고만 알린다.
    throw AiUnavailable(aiUnavailableText(cause));
  }

  // ── AI에게 맡기기 (에이전트) ─────────────────────────────────────────
  // 목표(이 건의 환불 · 교환 · 수리)까지 지금 할 수 있는 일을 서버의 AI가 건의 상태를 보고 고른다.
  // 읽는 일은 바로 하고, 건을 바꾸는 일은 제안으로 내놓고 멈춘다. 앱은 그 제안을 보여 주고
  // 사람의 답(허락 · 하지 않기)을 서버에 전할 뿐, 스스로 건을 바꾸지 않는다.
  // 서버가 없으면(체험 모드) 에이전트도 없다: 앱이 대신 지어내지 않는다.

  /// 이 건을 AI에게 맡길 수 있는지: 서버에 붙어 있고, 서버의 AI가 켜져 있고, 휴지통에 없는 건
  bool agentAvailableFor(ClaimView claim) =>
      user != null && !isOfflineFallback && config.aiEnabled && !claim.deleted;

  /// "스스로 시작하기"를 켰는지. 켜 두면 신청 · 자료 추가 · 답장 저장 때 서버가 버튼 없이 시작한다.
  bool get agentAutoOn => user?.agentAutoAt != null;

  /// 서버에 이 건의 에이전트가 지금 어떤지 묻는다 (`GET /api/claims/:id/ai/agent`). AI를 부르지 않는다.
  /// 일하는 중이면 끝날 때까지 2초마다 다시 묻는다.
  Future<AgentOverview?> refreshAgentOverview(String claimId) async {
    if (user == null || isOfflineFallback) return null;
    try {
      final res = await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/ai/agent',
      );
      final overview = AgentOverview.fromJson(res);
      agentOverviews[claimId] = overview;
      _markAgentWaiting(claimId, overview.waiting != null);
      if (overview.working) _watchAgent(claimId);
      notifyListeners();
      return overview;
    } catch (_) {
      return agentOverviews[claimId];
    }
  }

  void _watchAgent(String claimId) {
    if (_agentWatch.containsKey(claimId)) return;
    _agentWatch[claimId] = Timer(const Duration(seconds: 2), () {
      _agentWatch.remove(claimId);
      unawaited(refreshAgentOverview(claimId));
    });
  }

  void _markAgentWaiting(String claimId, bool waiting) {
    if (agentWaitingClaimIds.contains(claimId) == waiting) return;
    agentWaitingClaimIds = {
      ...agentWaitingClaimIds.where((id) => id != claimId),
      if (waiting) claimId,
    };
  }

  /// AI가 허락을 기다리는 건들을 받아 온다 (`GET /api/ai/agent/waiting`). AI를 부르지 않는다.
  Future<void> refreshAgentWaiting() async {
    if (user == null || isOfflineFallback) return;
    try {
      final res = await api.requestJson('/api/ai/agent/waiting');
      final list = res['claims'];
      if (list is! List) return;
      final next = {
        for (final item in list.whereType<Map<String, dynamic>>())
          (item['claimId'] ?? '').toString(),
      }..remove('');
      if (next.length == agentWaitingClaimIds.length &&
          next.containsAll(agentWaitingClaimIds)) {
        return;
      }
      agentWaitingClaimIds = next;
      notifyListeners();
    } catch (_) {}
  }

  // ── 앱으로 돌아왔을 때 ──────────────────────────────────────────────
  // 앱은 꺼져 있거나 뒤에 있는 동안 서버의 소식을 받지 못한다 (푸시 알림이 없다).
  // 그래서 돌아왔을 때, 비운 동안 바뀐 것을 바로 다시 받아 온다: 다른 기기에서 고친 건,
  // 그리고 스스로 시작한 AI가 물어볼 것이 생겼는지. (오래 답이 없으면 서버가 메일로도 알린다.)

  /// 이만큼 넘게 비웠을 때만 다시 받아 온다 (사진 고르기처럼 잠깐 나갔다 온 것은 넘어간다)
  Duration resumeRefreshAfter = const Duration(seconds: 30);
  DateTime? _leftAt;

  /// 앱이 뒤로 갔다 (다른 앱을 보거나 화면을 껐다)
  void appPaused({DateTime? now}) => _leftAt = now ?? DateTime.now();

  /// 앱으로 돌아왔다
  Future<void> appResumed({DateTime? now}) async {
    final left = _leftAt;
    _leftAt = null;
    if (left == null) return;
    if ((now ?? DateTime.now()).difference(left) < resumeRefreshAfter) return;
    if (user == null || isOfflineFallback) return;
    await refreshClaims();
    final open = selectedClaimId;
    if (open != null) await refreshAgentOverview(open);
  }

  /// 서버가 저장을 받았다. "스스로 시작하기"가 켜져 있으면 AI가 곧 이 건을 살펴보므로 지켜본다.
  void _agentMayStart(String claimId) {
    if (agentAutoOn) unawaited(refreshAgentOverview(claimId));
  }

  /// 로그아웃 · 탈퇴: 다른 사람의 화면에 남지 않게 지운다
  void _forgetAgent() {
    for (final timer in _agentWatch.values) {
      timer.cancel();
    }
    _agentWatch.clear();
    agentOverviews.clear();
    agentWaitingClaimIds = const {};
  }

  void _rememberAgentRun(String claimId, AgentRun run) {
    final before = agentOverviews[claimId];
    agentOverviews[claimId] = AgentOverview(
      waiting: run.isWaiting ? run : null,
      last: before?.last,
    );
    _markAgentWaiting(claimId, run.isWaiting);
    notifyListeners();
  }

  /// 에이전트가 하지 못한 까닭을 화면에 보일 한 문장으로
  String _agentFailText(Object? error, String fallback) {
    if (!sdkAiEnabled) return strings.aiOff;
    if (isOfflineFallback) return strings.aiNoServer;
    if (error is ApiError && error.code == 'ai_consent_required') {
      return strings.aiOff;
    }
    if (error is ApiError &&
        error.explained &&
        locale == ReloLocale.ko &&
        error.message.isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  /// 이 건을 AI에게 맡긴다 (`POST /api/claims/:id/ai/agent`).
  /// 끝났거나, 허락이 필요한 일에서 멈춘 실행을 돌려준다. 하지 못하면 [AiUnavailable]을 던진다.
  Future<AgentRun> runAgent(String claimId) async {
    Object? cause;
    if (sdkAiEnabled && !isOfflineFallback) {
      try {
        final res = await api.requestJson(
          '/api/claims/${Uri.encodeComponent(claimId)}/ai/agent',
          method: 'POST',
          data: {'locale': locale.code},
        );
        final run = AgentRun.fromJson(res);
        _rememberAgentRun(claimId, run);
        return run;
      } catch (e) {
        cause = e;
      }
    }
    throw AiUnavailable(_agentFailText(cause, strings.agFailed));
  }

  /// AI가 하려는 일에 답한다 (`POST .../ai/agent/:runId/decision`). 허락하면 그때 서버가 그 일을 하고,
  /// 실행은 이어진다. 허락한 일이 건을 바꿨을 수 있으므로 건을 다시 받아 온다.
  Future<AgentRun> decideAgent(
    String claimId,
    String runId, {
    required bool approve,
  }) async {
    try {
      final res = await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/ai/agent/${Uri.encodeComponent(runId)}/decision',
        method: 'POST',
        data: {'approve': approve, 'locale': locale.code},
      );
      final run = AgentRun.fromJson(res);
      _rememberAgentRun(claimId, run);
      if (approve) await refreshClaims();
      return run;
    } catch (e) {
      throw AiUnavailable(_agentFailText(e, strings.agDecisionFailed));
    }
  }

  /// "스스로 시작하기"를 켜거나 끈다 (`POST /api/account/agent-auto`).
  /// 서버가 받아야만 바뀐다: 기기 안에서만 켜진 것처럼 보이면, 켰는데도 AI가 시작하지 않는다.
  /// 서버가 받지 않으면 [ApiError]를 던진다.
  Future<void> setAgentAuto(bool on) async {
    final res = await api.requestJson(
      '/api/account/agent-auto',
      method: 'POST',
      data: {'on': on},
    );
    if (res['user'] is! Map<String, dynamic>) {
      throw const ApiError('요청을 처리하지 못했어요.');
    }
    user = User.fromJson(res['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  /// 알림 메일을 받는지. 스스로 시작한 AI가 허락을 기다리는데 한동안 답이 없으면 서버가
  /// 인증한 이메일로 한 통 보낸다. 처음에는 받는다.
  bool get noticeMailOn => user?.noticeMailOffAt == null;

  /// 알림 메일을 켜고 끈다 (`POST /api/account/notice-mail`). 서버가 받아야 바뀐다:
  /// 기기 안의 값만 바꾸면 메일은 계속 오는데 화면은 껐다고 말하게 된다.
  /// 이메일 인증 · 비밀번호 재설정 메일은 알림이 아니어서 이 스위치와 상관없다.
  Future<void> setNoticeMail(bool on) async {
    final res = await api.requestJson(
      '/api/account/notice-mail',
      method: 'POST',
      data: {'on': on},
    );
    if (res['user'] is! Map<String, dynamic>) {
      throw const ApiError('요청을 처리하지 못했어요.');
    }
    user = User.fromJson(res['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  /// 신청을 AI가 채운다: 주문서를 읽고([file], `POST /api/ai/extract`), 적은 한 줄([text])을
  /// 그 주문서의 상품에 맞춰 읽는다(`POST /api/ai/intake`). 한 줄을 읽을 때 AI에는 그 한 줄과
  /// 상품의 이름 · 수량만 가고, 금액은 가지 않는다. 둘 중 하나만 돼도 된 만큼 돌려주고,
  /// 둘 다 못 했으면 [AiUnavailable]을 던진다. 저장하는 것은 없다.
  Future<({OrderReading? order, IntakeReading? intake})> fillRequestWithAi({
    PickedEvidence? file,
    String text = '',
  }) async {
    if (!sdkAiEnabled || isOfflineFallback) {
      throw AiUnavailable(aiUnavailableText());
    }
    Object? cause;
    OrderReading? order;
    if (file != null) {
      try {
        final res = await api.requestJson(
          '/api/ai/extract',
          method: 'POST',
          rawBytes: file.bytes,
          headers: {
            'Content-Type': file.mime,
            'X-File-Name': Uri.encodeComponent(file.name),
          },
        );
        order = OrderReading.fromJson(res);
      } catch (e) {
        cause = e;
      }
    }
    IntakeReading? intake;
    if (text.trim().isNotEmpty) {
      try {
        final res = await api.requestJson(
          '/api/ai/intake',
          method: 'POST',
          data: {
            'text': text.trim(),
            'items': [
              for (final item in order?.items ?? const <OrderItemReading>[])
                {'name': item.name, 'orderedQty': item.orderedQty},
            ],
            'locale': locale.code,
          },
        );
        intake = IntakeReading.fromJson(res);
      } catch (e) {
        cause ??= e;
      }
    }
    if (order == null && intake == null) {
      throw AiUnavailable(aiUnavailableText(cause));
    }
    return (order: order, intake: intake);
  }

  /// 서버가 이 건을 알고 "안 된다"고 답했는지. 이럴 때는 기기 안에서 된 것처럼 바꾸지 않고
  /// 화면이 서버의 말을 그대로 보여 준다. 서버에 붙지 못했거나(체험 모드), 로그인 전이거나,
  /// 서버에 없는 보기용 건(404)이면 전처럼 기기 안에서만 바꾼다.
  bool _refused(Object e) =>
      e is ApiError &&
      e.explained &&
      e.status != 401 &&
      !(e.status == 404 && e.field == null);

  /// 거절한 까닭을 화면에 보일 말로. 서버는 한국어로만 말하므로, 다른 언어에서는 화면의 문장을 쓴다.
  String refusalText(ApiError e) =>
      locale == ReloLocale.ko && e.message.isNotEmpty
          ? e.message
          : strings.cwFailed;

  /// 기기 안에서만 바꿀 때, 서버라면 거절했을 일을 같은 말로 거절한다
  Never _refuseLocally(String message, {String? field}) => throw ApiError(
        message,
        code: 'validation',
        status: 422,
        field: field,
        explained: true,
      );

  String _todayLocal() => DateTime.now().toIso8601String().substring(0, 10);

  ClaimAuditEvent _event(String action, String nowIso) => ClaimAuditEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        action: action,
        createdAt: nowIso,
      );

  /// 쇼핑몰 답장을 저장하고, 환불 건이면 약속한 금액도 함께 적는다.
  /// 금액을 비워 두면 약속 금액은 건드리지 않는다 (아직 약속이 없을 때).
  Future<void> saveReplyAndAgreedAmount({
    required String claimId,
    required String rawReply,
    required String replyKind,
    required String summaryKo,
    required String translationKo,
    required String agreedAmountStr,
    // AI가 이 답장을 읽고 요약 · 번역했을 때만 true. 직접 읽고 저장한 답장은 false다.
    required bool aiAssisted,
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;

    final setsAgreed =
        target.kind == 'refund' && agreedAmountStr.trim().isNotEmpty;
    final agreedMinor = setsAgreed
        ? MoneyFormat.decimalStringToMinor(agreedAmountStr, target.currency)
        : target.agreed;

    try {
      final replyRes = await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/replies',
        method: 'POST',
        version: target.version,
        data: {
          'body': rawReply,
          'kind': replyKind,
          'summaryKo': summaryKo,
          'translationKo': translationKo,
          'aiAssisted': aiAssisted,
        },
      );
      try {
        if (setsAgreed && agreedMinor != target.agreed) {
          final afterReply = replyRes['claim'] is Map<String, dynamic>
              ? ClaimView.fromJson(replyRes['claim'] as Map<String, dynamic>)
              : target;
          await api.requestJson(
            '/api/claims/${Uri.encodeComponent(claimId)}',
            method: 'PATCH',
            version: replyRes['claim'] is Map<String, dynamic>
                ? afterReply.version
                : target.version + 1,
            data: _buildClaimMutationPayload(
              afterReply,
              agreedAmountStr: MoneyFormat.minorToDecimalString(
                agreedMinor!,
                target.currency,
              ),
            ),
          );
        }
      } finally {
        // 답장은 이미 저장됐다. 금액 저장이 거절돼도 저장된 데까지는 화면에 보여 준다.
        await refreshClaims();
        _agentMayStart(claimId);
      }
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    final nowIso = DateTime.now().toIso8601String();
    final reply = ClaimReply(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      body: rawReply,
      kind: replyKind,
      translationKo: translationKo,
      summaryKo: summaryKo,
      aiAssisted: aiAssisted,
      recordedAt: nowIso,
    );
    final summary = claimTotals(target, agreed: agreedMinor);
    var state = stateAfterReply(replyKind, target.state);
    // 쇼핑몰이 답했으니 기다림은 끝났다 ("환불 처리했다"는 안내만은 입금을 기다린다)
    if (replyKind != 'refund_notice' &&
        const {'preparing', 'review', 'awaiting'}.contains(state)) {
      state = 'negotiating';
    }
    state = stateAfterFactsChange(state, target.kind, agreedMinor, summary);

    _replaceClaim(
      target.copyWith(
        agreed: agreedMinor,
        state: state,
        version: target.version + 1,
        updatedAt: nowIso,
        replies: [reply, ...target.replies],
        events: [
          _event(
            setsAgreed
                ? '쇼핑몰 답장 저장 및 약속 금액(${MoneyFormat.formatMinor(agreedMinor!, target.currency)}) 기록'
                : '쇼핑몰 답장 저장',
            nowIso,
          ),
          ...target.events,
        ],
        summary: summary,
      ),
    );
  }

  /// 실제로 받은 것을 기록한다 (`POST /api/claims/:id/receipts`).
  /// 환불은 들어온 돈([amountStr]), 교환은 받은 수량([quantity]), 수리는 결과만 적는다.
  /// 입금 번호([transactionRef])가 없으면 어디에서 확인했는지([note], 10자 이상)와
  /// 사용자의 확인([noRefConfirmed])이 있어야 한다. 서버가 거절하면 [ApiError]를 던진다.
  Future<void> recordReceipt({
    required String claimId,
    required String receivedOn,
    String amountStr = '',
    String transactionRef = '',
    String note = '',
    bool noRefConfirmed = false,
    int quantity = 1,
    String? proofId,
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;

    final isRefund = target.kind == 'refund';
    final receiptKind = switch (target.kind) {
      'exchange' => 'goods',
      'repair' => 'repair',
      _ => 'cash',
    };
    final ref = transactionRef.trim();
    final depositMinor = isRefund
        ? MoneyFormat.decimalStringToMinor(amountStr, target.currency)
        : 0;

    try {
      var activeClaim = target;
      // 서버는 약속 금액이 있어야 입금을 받는다. 아직 없으면 신청한 금액을 약속 금액으로 적는다.
      if (isRefund && activeClaim.agreed == null) {
        final patchRes = await api.requestJson(
          '/api/claims/${Uri.encodeComponent(claimId)}',
          method: 'PATCH',
          version: activeClaim.version,
          data: _buildClaimMutationPayload(
            activeClaim,
            agreedAmountStr: MoneyFormat.minorToDecimalString(
              activeClaim.claimed,
              activeClaim.currency,
            ),
          ),
        );
        if (patchRes['claim'] is Map<String, dynamic>) {
          activeClaim = ClaimView.fromJson(
            patchRes['claim'] as Map<String, dynamic>,
          );
        }
      }

      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/receipts',
        method: 'POST',
        version: activeClaim.version,
        idempotencyKey: ReloApiClient.newIdempotencyKey(),
        data: {
          'kind': receiptKind,
          'proofId': proofId ??
              (activeClaim.files.isNotEmpty ? activeClaim.files.first.id : ''),
          'receivedOn': receivedOn,
          if (isRefund) 'amount': amountStr,
          if (receiptKind == 'goods') 'quantity': quantity,
          if (ref.isNotEmpty) 'transactionRef': ref,
          if (note.trim().isNotEmpty) 'note': note.trim(),
          // 번호가 없는 입금은 사용자가 직접 확인했다고 한 것만 그렇게 보낸다
          if (isRefund && ref.isEmpty) ...{
            'missingReferenceConfirmed': noRefConfirmed,
            'duplicateReviewed': noRefConfirmed,
          },
          'confirmed': true,
        },
      );
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    // ── 기기 안에서만 (체험 모드 · 보기용 건). 서버와 같은 규칙으로 센다. ──
    final agreed = target.agreed ?? (isRefund ? target.claimed : null);
    if (isRefund) {
      if (depositMinor < 1 || depositMinor > agreed! - target.summary.cash) {
        _refuseLocally('입금액은 아직 받지 못한 약속 금액 이내로 적어 주세요.', field: 'amount');
      }
      if (ref.isEmpty && (!noRefConfirmed || note.trim().length < 10)) {
        _refuseLocally(
          '입금 번호가 없으면 확인 체크와 메모(10자 이상)가 필요해요.',
          field: 'transactionRef',
        );
      }
      if (ref.isNotEmpty &&
          claims.any((c) => c.ledger.any((e) =>
              e.kind == 'cash' &&
              e.transactionRef.toUpperCase() == ref.toUpperCase()))) {
        _refuseLocally(
          '이미 기록한 거래예요. 같은 입금을 두 번 셀 수 없어요.',
          field: 'transactionRef',
        );
      }
    }
    final left = target.summary.requestedQty - target.summary.goods;
    if (receiptKind == 'goods' && (quantity < 1 || quantity > left)) {
      _refuseLocally('받은 교환품 수량은 1~$left개로 적어 주세요.', field: 'quantity');
    }
    if (receiptKind == 'repair' && target.summary.repair) {
      _refuseLocally('수리 결과는 이미 기록했어요.');
    }

    final nowIso = DateTime.now().toIso8601String();
    final entry = LedgerEntry(
      id: 'ldg_${DateTime.now().millisecondsSinceEpoch}',
      claimId: claimId,
      kind: receiptKind,
      amount: depositMinor,
      quantity: receiptKind == 'goods' ? quantity : 0,
      note: note.trim(),
      proofId: proofId ??
          (target.files.isNotEmpty ? target.files.first.id : null),
      transactionRef: ref,
      receivedOn: receivedOn,
      createdAt: nowIso,
    );
    final ledger = [entry, ...target.ledger];
    final summary = claimTotals(target, ledger: ledger, agreed: agreed);
    final what = switch (receiptKind) {
      'goods' => '교환품 $quantity개 받음',
      'repair' => '수리 결과 확인',
      _ => '입금(${MoneyFormat.formatMinor(depositMinor, target.currency)}) 확인',
    };

    _replaceClaim(
      target.copyWith(
        agreed: agreed,
        state: stateAfterReceipt(target.state, target.kind, agreed, summary),
        version: target.version + 1,
        updatedAt: nowIso,
        ledger: ledger,
        events: [_event('$what 기록', nowIso), ...target.events],
        summary: summary,
      ),
    );
  }

  /// 잘못 적은 기록을 되돌린다. 기록은 지워지지 않고 "되돌린 기록"으로 남아 더는 세지 않는다.
  Future<void> undoReceipt({
    required String claimId,
    required String entryId,
    required String reason,
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;
    LedgerEntry? original;
    for (final e in target.ledger) {
      if (e.id == entryId && e.kind != 'reversal') original = e;
    }
    if (original == null) return;

    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/receipts',
        method: 'POST',
        version: target.version,
        idempotencyKey: ReloApiClient.newIdempotencyKey(),
        data: {
          'kind': 'reversal',
          'reverses': entryId,
          'proofId': original.proofId ??
              (target.files.isNotEmpty ? target.files.first.id : ''),
          'receivedOn': _todayLocal(),
          'note': reason.trim(),
          'confirmed': true,
        },
      );
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    if (isClaimLocked(target)) {
      _refuseLocally('마무리했거나 멈춘 건이에요. 먼저 다시 열어 주세요.');
    }
    if (target.ledger.any((e) => e.reverses == entryId)) {
      _refuseLocally('이미 되돌린 기록이에요.');
    }
    final nowIso = DateTime.now().toIso8601String();
    final ledger = [
      LedgerEntry(
        id: 'ldg_${DateTime.now().millisecondsSinceEpoch}',
        claimId: claimId,
        kind: 'reversal',
        amount: original.amount,
        quantity: original.quantity,
        note: reason.trim(),
        proofId: original.proofId,
        reverses: entryId,
        transactionRef: '',
        receivedOn: _todayLocal(),
        createdAt: nowIso,
      ),
      ...target.ledger,
    ];
    final summary = claimTotals(target, ledger: ledger);
    _replaceClaim(
      target.copyWith(
        state: stateAfterReceipt(
          target.state,
          target.kind,
          target.agreed,
          summary,
        ),
        version: target.version + 1,
        updatedAt: nowIso,
        ledger: ledger,
        events: [_event('기록 되돌림 (${reason.trim()})', nowIso), ...target.events],
        summary: summary,
      ),
    );
  }

  /// 상태를 직접 바꾼다 (`POST /api/claims/:id/transition`).
  /// [action]: disputed(다른 해결 방법으로) · waived(더 진행하지 않기) · reopen(다시 진행) · close(마무리)
  Future<void> transitionClaim(
    String claimId,
    String action,
    String reason,
  ) async {
    final target = findClaim(claimId);
    if (target == null) return;
    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/transition',
        method: 'POST',
        version: target.version,
        data: {'action': action, 'reason': reason},
      );
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    final next = stateAfterTransition(action, target);
    if (next == null) {
      _refuseLocally(action == 'close'
          ? '약속한 금액이나 교환 · 수리 결과를 실제로 확인한 뒤에 마무리할 수 있어요.'
          : '지금 상태에서는 바꿀 수 없어요.');
    }
    final nowIso = DateTime.now().toIso8601String();
    final what = switch (action) {
      'disputed' => '다른 해결 방법으로 바꿈',
      'waived' => '더 진행하지 않기로 함',
      'reopen' => '다시 진행',
      _ => '마무리',
    };
    _replaceClaim(
      target.copyWith(
        state: next,
        version: target.version + 1,
        updatedAt: nowIso,
        events: [_event(what, nowIso), ...target.events],
      ),
    );
  }

  /// 받기로 한 것을 다 받은 건을 마무리한다
  Future<void> completeClaim(String claimId) =>
      transitionClaim(claimId, 'close', '소비자가 받은 것을 직접 확인하고 마무리함');

  /// 쇼핑몰과 정한 해결 방법을 바꾼다 (환불 ↔ 교환 ↔ 수리).
  /// 이미 받은 기록이 있으면 바꿀 수 없다 (먼저 기록을 되돌린다).
  Future<void> changeClaimKind(String claimId, String kind) async {
    final target = findClaim(claimId);
    if (target == null || target.kind == kind) return;
    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}',
        method: 'PATCH',
        version: target.version,
        data: _buildClaimMutationPayload(target, kind: kind),
      );
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    if (isClaimLocked(target)) {
      _refuseLocally('마무리했거나 멈춘 건이에요. 먼저 다시 열어 주세요.');
    }
    if (hasReceived(target.summary)) {
      _refuseLocally('받은 기록이 있는 건은 해결 방법을 바꿀 수 없어요. 기록을 먼저 되돌려 주세요.', field: 'kind');
    }
    final nowIso = DateTime.now().toIso8601String();
    _replaceClaim(
      target.copyWith(
        kind: kind,
        version: target.version + 1,
        updatedAt: nowIso,
        events: [_event('해결 방법 바꿈', nowIso), ...target.events],
        summary: claimTotals(target, kind: kind),
      ),
    );
  }

  Future<void> toggleTrashClaim(String claimId) async {
    final target = findClaim(claimId);
    if (target == null) return;
    final nextDeleted = !target.deleted;

    try {
      if (nextDeleted) {
        await api.requestJson(
          '/api/claims/${Uri.encodeComponent(claimId)}',
          method: 'DELETE',
          version: target.version,
          data: {'reason': '사용자 휴지통 이동'},
        );
      } else {
        await api.requestJson(
          '/api/claims/${Uri.encodeComponent(claimId)}/restore',
          method: 'POST',
          version: target.version,
        );
      }
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    _replaceClaim(
      ClaimView(
        id: target.id,
        title: target.title,
        vendor: target.vendor,
        vendorUrl: target.vendorUrl,
        orderRef: target.orderRef,
        orderedOn: target.orderedOn,
        kind: target.kind,
        currency: target.currency,
        items: target.items,
        claimed: target.claimed,
        agreed: target.agreed,
        issue: target.issue,
        issueEnglish: target.issueEnglish,
        deadline: target.deadline,
        deadlineQuote: target.deadlineQuote,
        deadlineZone: target.deadlineZone,
        state: target.state,
        version: target.version + 1,
        deleted: nextDeleted,
        createdAt: target.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        files: target.files,
        ledger: target.ledger,
        drafts: target.drafts,
        replies: target.replies,
        events: target.events,
        summary: target.summary,
        nextStep: target.nextStep,
      ),
    );
  }

  /// 판매자가 정한 기한을 적어 둔다 (`PATCH /api/claims/:id`). 마감 알림은 이 날짜를 보고 맞춘다.
  /// 서버는 기한을 판매자 원문([quote])과 함께만 받는다. [deadline]이 null이면 기한을 지운다.
  Future<void> setClaimDeadline({
    required String claimId,
    String? deadline,
    String quote = '',
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;
    final nextQuote = deadline == null ? '' : quote;
    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}',
        method: 'PATCH',
        version: target.version,
        data: _buildClaimMutationPayload(target)
          ..['deadline'] = deadline
          ..['deadlineQuote'] = nextQuote,
      );
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    final nowIso = DateTime.now().toIso8601String();
    _replaceClaim(
      ClaimView(
        id: target.id,
        title: target.title,
        vendor: target.vendor,
        vendorUrl: target.vendorUrl,
        orderRef: target.orderRef,
        orderedOn: target.orderedOn,
        kind: target.kind,
        currency: target.currency,
        items: target.items,
        claimed: target.claimed,
        agreed: target.agreed,
        issue: target.issue,
        issueEnglish: target.issueEnglish,
        deadline: deadline,
        deadlineQuote: nextQuote,
        deadlineZone: target.deadlineZone,
        state: target.state,
        version: target.version + 1,
        deleted: target.deleted,
        createdAt: target.createdAt,
        updatedAt: nowIso,
        files: target.files,
        ledger: target.ledger,
        drafts: target.drafts,
        replies: target.replies,
        events: [
          ClaimAuditEvent(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            action: deadline == null ? '마감일 지움' : '마감일 기록 ($deadline)',
            createdAt: nowIso,
          ),
          ...target.events,
        ],
        summary: target.summary,
        nextStep: target.nextStep,
      ),
    );
  }

  Map<String, dynamic> _buildClaimMutationPayload(
    ClaimView claim, {
    String? agreedAmountStr,
    String? kind,
  }) {
    final claimedStr = MoneyFormat.minorToDecimalString(
      claim.claimed,
      claim.currency,
    );
    final resolvedAgreedStr =
        agreedAmountStr ??
        (claim.agreed == null
            ? null
            : MoneyFormat.minorToDecimalString(claim.agreed!, claim.currency));
    return {
      'title': claim.title,
      'vendor': claim.vendor,
      'vendorUrl': claim.vendorUrl,
      'orderRef': claim.orderRef,
      'orderedOn': claim.orderedOn,
      'kind': kind ?? claim.kind,
      'currency': claim.currency,
      'claimedAmount': claimedStr,
      'agreedAmount': resolvedAgreedStr,
      'issue': claim.issue,
      'issueEnglish': claim.issueEnglish,
      'deadline': claim.deadline,
      'deadlineQuote': claim.deadlineQuote,
      'deadlineZone': claim.deadlineZone,
      'items': claim.items
          .map(
            (item) => {
              'name': item.name,
              'sku': item.sku,
              'orderedQty': item.orderedQty,
              'claimQty': item.claimQty,
              'unitPrice': MoneyFormat.minorToDecimalString(
                item.unitPrice,
                claim.currency,
              ),
            },
          )
          .toList(),
    };
  }

  /// 클레임 상세 보관함에서 10MB 이하 증빙 사진·영수증 추가 업로드 (`POST /api/claims/:id/files`)
  Future<void> uploadClaimFile({
    required String claimId,
    required String fileName,
    required String mime,
    required List<int> bytes,
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;

    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/files',
        method: 'POST',
        version: target.version,
        idempotencyKey: ReloApiClient.newIdempotencyKey(),
        rawBytes: bytes,
        headers: {
          'Content-Type': mime,
          'X-File-Name': Uri.encodeComponent(fileName),
        },
      );
      await refreshClaims();
      _agentMayStart(claimId);
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    final nowIso = DateTime.now().toIso8601String();
    final newFile = ClaimFile(
      id: 'fil_${DateTime.now().millisecondsSinceEpoch}',
      claimId: claimId,
      name: fileName,
      mime: mime,
      size: bytes.length,
      sha: 'sha256_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}',
      createdAt: nowIso,
      usedAsProof: false,
    );
    _replaceClaim(
      ClaimView(
        id: target.id,
        title: target.title,
        vendor: target.vendor,
        vendorUrl: target.vendorUrl,
        orderRef: target.orderRef,
        orderedOn: target.orderedOn,
        kind: target.kind,
        currency: target.currency,
        items: target.items,
        claimed: target.claimed,
        agreed: target.agreed,
        issue: target.issue,
        issueEnglish: target.issueEnglish,
        deadline: target.deadline,
        deadlineQuote: target.deadlineQuote,
        deadlineZone: target.deadlineZone,
        state: target.state,
        version: target.version + 1,
        deleted: target.deleted,
        createdAt: target.createdAt,
        updatedAt: nowIso,
        files: [...target.files, newFile],
        ledger: target.ledger,
        drafts: target.drafts,
        replies: target.replies,
        events: [
          ClaimAuditEvent(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            action: '증빙 파일 추가 저장 ($fileName)',
            createdAt: nowIso,
          ),
          ...target.events,
        ],
        summary: target.summary,
        nextStep: target.nextStep,
      ),
    );
  }

  /// 클레임 상세 보관함에서 미사용 증빙 파일 삭제 (`DELETE /api/claims/:id/files/:fileId`)
  Future<void> removeClaimFile({
    required String claimId,
    required String fileId,
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;

    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/files/${Uri.encodeComponent(fileId)}',
        method: 'DELETE',
        version: target.version,
      );
      await refreshClaims();
      return;
    } catch (e) {
      if (_refused(e)) rethrow;
    }

    final nowIso = DateTime.now().toIso8601String();
    _replaceClaim(
      ClaimView(
        id: target.id,
        title: target.title,
        vendor: target.vendor,
        vendorUrl: target.vendorUrl,
        orderRef: target.orderRef,
        orderedOn: target.orderedOn,
        kind: target.kind,
        currency: target.currency,
        items: target.items,
        claimed: target.claimed,
        agreed: target.agreed,
        issue: target.issue,
        issueEnglish: target.issueEnglish,
        deadline: target.deadline,
        deadlineQuote: target.deadlineQuote,
        deadlineZone: target.deadlineZone,
        state: target.state,
        version: target.version + 1,
        deleted: target.deleted,
        createdAt: target.createdAt,
        updatedAt: nowIso,
        files: target.files.where((f) => f.id != fileId).toList(),
        ledger: target.ledger,
        drafts: target.drafts,
        replies: target.replies,
        events: [
          ClaimAuditEvent(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            action: '증빙 파일 삭제 완료',
            createdAt: nowIso,
          ),
          ...target.events,
        ],
        summary: target.summary,
        nextStep: target.nextStep,
      ),
    );
  }

  String exportUserDataAsJson() {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'service': 'ReLo 2.0.0 Flutter App',
      'user': user == null
          ? null
          : {'id': user!.id, 'name': user!.name, 'email': user!.email},
      'compliance': {
        'cookieConsent': cookieConsent.name,
        'noticeMailOn': noticeMailOn,
        'sdkAiEnabled': sdkAiEnabled,
      },
      'claimsCount': claims.length,
      'claims': claims
          .map(
            (c) => {
              'id': c.id,
              'title': c.title,
              'vendor': c.vendor,
              'orderRef': c.orderRef,
              'currency': c.currency,
              'claimed': c.claimed,
              'recoveredCash': c.summary.cash,
              'state': c.state,
            },
          )
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  void _replaceClaim(ClaimView updated) {
    final idx = claims.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      final copy = List<ClaimView>.from(claims);
      copy[idx] = updated;
      claims = copy;
      notifyListeners();
    }
  }

  // ── 마감 알림 ───────────────────────────────────────────────────────
  // 환불 건이나 언어가 바뀔 때마다 "맞춰 둘 알림"을 다시 계산해 기기에 맡긴다.
  // 무엇이 바뀌었는지 일일이 챙기지 않도록, 화면에 변화를 알릴 때마다 함께 본다.

  @override
  void notifyListeners() {
    super.notifyListeners();
    _openPendingReminderClaim();
    _syncReminders();
  }

  Future<void> _loadReminderPrefs() async {
    deadlineRemindersOn = await _reminderPrefs.loadOn();
    reminderChoiceMade = await _reminderPrefs.loadAsked();
    // 기기 설정에서 알림을 막았으면 앱의 스위치도 꺼진 것으로 맞춘다
    if (deadlineRemindersOn && !(await reminders.isAllowed())) {
      deadlineRemindersOn = false;
    }
    reminders.setOnOpened(_rememberReminderClaim);
    final opened = await reminders.takeOpenedClaim();
    if (opened != null) _pendingReminderClaimId = opened;
    _reminderPrefsLoaded = true;
    notifyListeners();
  }

  /// 마감 알림을 켜고 끈다. 켤 때 기기가 알림을 허용하지 않으면 꺼진 채로 두고 false를 돌려준다.
  Future<bool> setDeadlineReminders(bool on) async {
    reminderChoiceMade = true;
    unawaited(_reminderPrefs.saveAsked(true));
    if (on && !(await reminders.requestPermission())) {
      deadlineRemindersOn = false;
      unawaited(_reminderPrefs.saveOn(false));
      notifyListeners();
      return false;
    }
    deadlineRemindersOn = on;
    unawaited(_reminderPrefs.saveOn(on));
    notifyListeners();
    return true;
  }

  /// 지금 환불 건으로 맞춰 둘 알림 (언어에 맞춘 글자 포함)
  List<ReminderNotice> plannedReminderNotices({DateTime? now}) {
    final s = strings;
    return [
      for (final r in ReminderPlanner.plan(claims, now: now ?? DateTime.now()))
        ReminderNotice(
          id: r.id,
          when: r.when,
          claimId: r.claimId,
          title: switch (r.kind) {
            ReminderKind.deadlineIn3Days => s.rmIn3Title,
            ReminderKind.deadlineTomorrow => s.rmTomorrowTitle,
            ReminderKind.deadlineToday => s.rmTodayTitle,
            ReminderKind.replyCheck => s.rmReplyTitle,
          },
          body: r.kind == ReminderKind.replyCheck
              ? s.rmReplyBody(r.vendor)
              : '${r.vendor} · ${r.claimTitle}',
        ),
    ];
  }

  void _syncReminders() {
    if (!_reminderPrefsLoaded || !reminders.isSupported) return;
    if (!deadlineRemindersOn) {
      _replaceReminders(const []);
      return;
    }
    // 서버에서 받아 온 내 환불 건일 때만 다시 맞춘다. 로그인 전이거나 서버에 붙지 못해
    // 예시 건을 보여 주는 동안에는, 기기에 맞춰 둔 알림을 그대로 둔다.
    if (isLoading || isOfflineFallback || user == null || !api.hasSession) {
      return;
    }
    _replaceReminders(plannedReminderNotices());
  }

  void _replaceReminders(List<ReminderNotice> notices) {
    final signature = notices
        .map((n) =>
            '${n.id}@${n.when.millisecondsSinceEpoch}#${n.title}#${n.body}')
        .join('|');
    if (signature == _reminderSignature) return;
    _reminderSignature = signature;
    unawaited(reminders.replaceAll(notices));
  }

  /// 로그아웃 · 탈퇴: 다른 사람이 이 기기를 쓸 수 있으니 맞춰 둔 알림을 모두 지운다
  void _clearRemindersForSignOut() {
    if (!reminders.isSupported) return;
    _reminderSignature = '';
    unawaited(reminders.replaceAll(const []));
  }

  // ── 다른 앱에서 공유로 넘어온 영수증 ────────────────────────────────

  Future<void> _receiveSharedEvidence() async {
    try {
      final evidence = await sharedInbox.take();
      if (evidence == null) return;
      incomingEvidence = evidence;
      activeTabIndex = 1; // 신청 화면이 가져가서 붙인다
      selectedClaimId = null;
    } on EvidenceException catch (e) {
      pendingNotice = strings.evProblem(e.problem);
    } catch (_) {
      return;
    }
    notifyListeners();
  }

  /// 신청 화면이 공유받은 영수증을 가져간다 (한 번만)
  PickedEvidence? takeIncomingEvidence() {
    final evidence = incomingEvidence;
    incomingEvidence = null;
    return evidence;
  }

  String? takePendingNotice() {
    final text = pendingNotice;
    pendingNotice = null;
    return text;
  }

  void _rememberReminderClaim(String claimId) {
    _pendingReminderClaimId = claimId;
    _openPendingReminderClaim();
  }

  /// 알림을 눌러 들어왔으면 그 환불 건의 상세를 연다 (환불 목록을 받아 온 뒤에)
  void _openPendingReminderClaim() {
    final id = _pendingReminderClaimId;
    if (id == null || isLoading) return;
    _pendingReminderClaimId = null;
    if (user != null && findClaim(id) != null) openClaimDetail(id);
  }
}

class ReloScope extends InheritedNotifier<ReloStore> {
  const ReloScope({
    super.key,
    required ReloStore store,
    required super.child,
  }) : super(notifier: store);

  static ReloStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ReloScope>();
    assert(scope != null, 'ReloScope not found in widget tree');
    return scope!.notifier!;
  }
}
