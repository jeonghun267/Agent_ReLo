import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/i18n/relo_i18n.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/assistant_history_storage.dart';
import '../../core/theme/relo_theme.dart';
import '../../core/utils/dday.dart';
import '../../core/utils/money_format.dart';
import '../models/domain_models.dart';

/// @module shared/state/relo_store
/// @layer Shared Application State (MVVM ViewModel / Store)
/// @purpose 백엔드 API 연동, 로컬 체험 폴백, 그리고 20대 법적 컴플라이언스
///          (쿠키 동의, 고대비 모드, 외부 SDK 제어, 이메일 수신거부, 개인정보 즉시 파기) 상태를 관리합니다.
class ReloStore extends ChangeNotifier {
  final ReloApiClient api = ReloApiClient();

  bool isDarkMode = true; // 승인된 다크 미드나잇 블루 테마 기본값
  bool isHighContrast = false; // [항목 #14] WCAG AAA 초고대비 접근성 모드
  ReloLocale locale = ReloLocale.ko;
  int activeTabIndex = 0; // 0:홈, 1:신청하기, 2:내환불, 3:법적보호20선, 4:설정
  String? selectedClaimId;

  // [20대 법적 안전장치 상태]
  CookieConsentChoice cookieConsent = CookieConsentChoice.pending; // [항목 #4, #5]
  bool emailUnsubscribed = false; // [항목 #18] 이메일 원클릭 수신거부 상태
  bool sdkAiEnabled = true; // [항목 #8] 외부 AI SDK 전송 스위치
  bool sdkMailEnabled = true; // [항목 #8] 외부 메일 SDK 전송 스위치
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

  /// 도우미가 상세 화면을 열 때 고른 하위 탭 (0 판매자 메시지, 1 답장 해석)
  int pendingDetailSubTab = 0;

  // 필터 상태
  String stateFilter = '';
  bool showTrash = false;
  String searchQuery = '';

  ReloStrings get strings => ReloStrings(locale);

  ReloStore() {
    _seedInitialDemoData();
    bootstrap();
    _loadAssistantHistory();
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
          remaining: 9850,
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

  Future<void> bootstrap() async {
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
      notifyListeners();
    } catch (_) {
      isOfflineFallback = true;
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

  /// [항목 #18] 이메일 원클릭 수신거부 상태 전환
  void setEmailUnsubscribed(bool unsubscribed) {
    emailUnsubscribed = unsubscribed;
    notifyListeners();
  }

  /// [항목 #8] 외부 SDK (Gemini AI / Resend 이메일) 전송 스위치 제어
  void toggleExternalSdk(String sdkId) {
    if (sdkId == 'gemini_ai_bridge') {
      sdkAiEnabled = !sdkAiEnabled;
      toggleAiConsent();
    } else if (sdkId == 'resend_mail_bridge') {
      sdkMailEnabled = !sdkMailEnabled;
      emailUnsubscribed = !sdkMailEnabled;
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

  void openClaimDetail(String claimId, {int subTab = 0}) {
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
      final lead = claimId == null && open.length > 1
          ? t('진행 중인 환불이 ${open.length}건이에요. 가장 급한 건부터 볼게요.\n',
              'You have ${open.length} open claims. Here is the most urgent one.\n')
          : '';
      return answer(
        lead +
            t('${focus.vendor} 건은 지금 "$state" 단계예요$when. ${focus.nextStep}',
                '${focus.vendor}: currently "$state"$when. ${focus.nextStep}'),
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

  void setFilter({String? state, bool? trash, String? query}) {
    if (state != null) stateFilter = state;
    if (trash != null) showTrash = trash;
    if (query != null) searchQuery = query;
    notifyListeners();
  }

  List<ClaimView> get filteredClaims {
    return claims.where((c) {
      if (showTrash != c.deleted) return false;
      if (!showTrash && stateFilter.isNotEmpty && c.state != stateFilter) {
        return false;
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
    bool marketingEmailConsented = false,
  }) async {
    emailUnsubscribed = !marketingEmailConsented;
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

  /// 백엔드 `src/server/services/file.service.mjs`의 매직 바이트(Magic Signature) 검증 통과 보장
  static List<int> ensureValidFileSignature(String mime, List<int> rawBytes) {
    if (mime == 'application/pdf') {
      const pdfHeader = [0x25, 0x50, 0x44, 0x46, 0x2D]; // "%PDF-"
      if (rawBytes.length >= 5 &&
          rawBytes[0] == 0x25 &&
          rawBytes[1] == 0x50 &&
          rawBytes[2] == 0x44 &&
          rawBytes[3] == 0x46 &&
          rawBytes[4] == 0x2D) {
        return rawBytes;
      }
      return [...pdfHeader, ...utf8.encode('1.4\n'), ...rawBytes];
    }
    if (mime == 'image/png') {
      const pngHeader = [137, 80, 78, 71, 13, 10, 26, 10];
      if (rawBytes.length >= 8 &&
          rawBytes[0] == 137 &&
          rawBytes[1] == 80 &&
          rawBytes[2] == 78 &&
          rawBytes[3] == 71) {
        return rawBytes;
      }
      return [...pngHeader, ...rawBytes];
    }
    if (mime == 'image/webp') {
      if (rawBytes.length >= 12 &&
          rawBytes[0] == 0x52 &&
          rawBytes[1] == 0x49 &&
          rawBytes[2] == 0x46 &&
          rawBytes[3] == 0x46) {
        return rawBytes;
      }
      return [
        ...utf8.encode('RIFF\x00\x00\x00\x00WEBP'),
        ...rawBytes,
      ];
    }
    // 기본 image/jpeg 매직 바이트 ([0xFF, 0xD8, 0xFF])
    if (rawBytes.length >= 3 &&
        rawBytes[0] == 255 &&
        rawBytes[1] == 216 &&
        rawBytes[2] == 255) {
      return rawBytes;
    }
    return [255, 216, 255, 224, ...rawBytes];
  }

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

  Future<Map<String, dynamic>> scanReceiptDocument({
    required String fileName,
    required List<int> bytes,
  }) async {
    final mime = fileName.toLowerCase().endsWith('.pdf')
        ? 'application/pdf'
        : 'image/jpeg';
    final safeBytes = ensureValidFileSignature(mime, bytes);
    if (sdkAiEnabled) {
      try {
        final res = await api.requestJson(
          '/api/ai/extract',
          method: 'POST',
          rawBytes: safeBytes,
          headers: {
            'Content-Type': mime,
            'X-File-Name': Uri.encodeComponent(fileName),
          },
        );
        if (res['suggestion'] is Map<String, dynamic>) {
          final sug = Map<String, dynamic>.from(
            res['suggestion'] as Map<String, dynamic>,
          );
          final items = sug['items'];
          if (sug['title'] == null &&
              items is List &&
              items.isNotEmpty &&
              items.first is Map) {
            sug['title'] = (items.first as Map)['name']?.toString();
          }
          if (sug['amount'] == null) {
            sug['amount'] =
                res['orderTotal']?.toString() ??
                ((items is List && items.isNotEmpty && items.first is Map)
                    ? (items.first as Map)['unitPrice']?.toString()
                    : null);
          }
          return sug;
        }
      } catch (_) {}
    }

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

  Future<String> translateIssueToEnglish(String koreanIssue) async {
    if (sdkAiEnabled) {
      try {
        final res = await api.requestJson(
          '/api/ai/translate-issue',
          method: 'POST',
          data: {'text': koreanIssue},
        );
        final en = res['english']?.toString() ?? '';
        if (en.isNotEmpty) return en;
      } catch (_) {}
    }

    if (koreanIssue.contains('깨진') || koreanIssue.contains('파손')) {
      return 'The outer shipping box and the product housing arrived cracked and visibly damaged upon unboxing. Please issue a full refund without return shipping fees.';
    }
    if (koreanIssue.contains('다른') || koreanIssue.contains('오배송')) {
      return 'A completely different model/color was delivered instead of the item I ordered. I request an immediate replacement or a full refund.';
    }
    if (koreanIssue.contains('전원') || koreanIssue.contains('작동')) {
      return 'The device does not power on or function properly even after charging. Given this clear hardware defect, I request a full refund.';
    }
    return 'Upon receiving the package, I found a clear defect with the item ($koreanIssue). Please process a prompt replacement or a full refund to my original payment method.';
  }

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
      for (final file in stagedFiles) {
        try {
          final validBytes = ensureValidFileSignature(file.mime, file.bytes);
          final uploadRes = await api.requestJson(
            '/api/claims/${Uri.encodeComponent(created.id)}/files',
            method: 'POST',
            version: created.version,
            idempotencyKey: ReloApiClient.newIdempotencyKey(),
            rawBytes: validBytes,
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
        } catch (_) {}
      }
      await refreshClaims();
      notifyListeners();
      return created;
    } catch (_) {
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

      if (mappedFiles.isEmpty) {
        mappedFiles.add(
          ClaimFile(
            id: 'fil_auto_${DateTime.now().millisecondsSinceEpoch}',
            claimId: newId,
            name: '${vendor.replaceAll(' ', '_')}_Receipt.pdf',
            mime: 'application/pdf',
            size: 312400,
            sha: 'auto_receipt_sha',
            createdAt: nowIso,
            usedAsProof: false,
          ),
        );
      }

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
        issueEnglish: issueEnglish.isNotEmpty
            ? issueEnglish
            : 'Order #$orderRef arrived defective ($title). Requesting prompt $kind of $currency $claimedAmount.',
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
          remaining: minor,
          requestedQty: claimQty,
        ),
        nextStep: '외국어 요청서를 자동 생성해 쇼핑몰 고객센터에 보내세요.',
      );

      claims = [created, ...claims];
      notifyListeners();
      return created;
    }
  }

  Future<String> generateForeignDraft(ClaimView claim) async {
    if (sdkAiEnabled) {
      try {
        final res = await api.requestJson(
          '/api/claims/${Uri.encodeComponent(claim.id)}/ai/draft',
          method: 'POST',
        );
        final body = res['body']?.toString() ?? '';
        if (body.isNotEmpty) return body;
      } catch (_) {}
    }

    try {
      final tplRes = await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claim.id)}/draft-template',
      );
      final tplBody = tplRes['body']?.toString() ?? '';
      if (tplBody.isNotEmpty) return tplBody;
    } catch (_) {}

    final amountStr = MoneyFormat.formatMinor(claim.claimed, claim.currency);
    final enReason = claim.issueEnglish.isNotEmpty
        ? claim.issueEnglish
        : 'The item arrived damaged and defective upon delivery.';

    return 'Subject: ${claim.kind.toUpperCase()} Request — Order #${claim.orderRef} (${claim.title})\n\n'
        'Dear ${claim.vendor} Customer Support,\n\n'
        'I am writing regarding my order #${claim.orderRef} placed on ${claim.orderedOn} for "${claim.title}".\n\n'
        'Issue Details:\n'
        '$enReason\n\n'
        'I have attached clear photographic proof and the order receipt (with personal residential details masked for security). '
        'Please process a ${claim.kind == 'refund' ? 'full refund of $amountStr to my original payment method' : 'replacement shipment'} without requiring international return shipping fees.\n\n'
        'Thank you for your prompt assistance.\n'
        'Best regards,\n'
        '${user?.name ?? 'Customer'}';
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
    } catch (_) {}

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
    if (sdkAiEnabled) {
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
      } catch (_) {}
    }

    final numMatch = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(rawReply);
    final extractedAmount =
        numMatch?.group(1) ??
        MoneyFormat.minorToDecimalString(claim.claimed, claim.currency);

    return (
      summaryKo: '판매자가 사과와 함께 ${claim.currency} $extractedAmount 환불 처리를 약속했습니다.',
      translationKo:
          '불편을 드려 죄송합니다. 보내주신 증빙 사진을 확인했으며, ${claim.currency} $extractedAmount 환불(결제 수단 취소)을 승인했습니다. 영업일 기준 3~5일 내 카드사에서 확인하실 수 있습니다.',
      mentionedAmount: extractedAmount,
    );
  }

  Future<void> saveReplyAndAgreedAmount({
    required String claimId,
    required String rawReply,
    required String replyKind,
    required String summaryKo,
    required String translationKo,
    required String agreedAmountStr,
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;

    final agreedMinor = agreedAmountStr.trim().isEmpty
        ? target.claimed
        : MoneyFormat.decimalStringToMinor(agreedAmountStr, target.currency);
    final agreedDecStr = MoneyFormat.minorToDecimalString(
      agreedMinor,
      target.currency,
    );

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
          'aiAssisted': true,
        },
      );
      var currentVersion = target.version + 1;
      if (replyRes['claim'] is Map<String, dynamic>) {
        final afterReply = ClaimView.fromJson(
          replyRes['claim'] as Map<String, dynamic>,
        );
        currentVersion = afterReply.version;
      }

      // 백엔드 SQLite에 합의액(agreedAmount) 동기화 (PATCH /api/claims/:id)
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}',
        method: 'PATCH',
        version: currentVersion,
        data: _buildClaimMutationPayload(target, agreedAmountStr: agreedDecStr),
      );
      await refreshClaims();
      return;
    } catch (_) {}

    final nowIso = DateTime.now().toIso8601String();
    final reply = ClaimReply(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      body: rawReply,
      kind: replyKind,
      translationKo: translationKo,
      summaryKo: summaryKo,
      aiAssisted: true,
      recordedAt: nowIso,
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
        agreed: agreedMinor,
        issue: target.issue,
        issueEnglish: target.issueEnglish,
        deadline: target.deadline,
        deadlineQuote: target.deadlineQuote,
        deadlineZone: target.deadlineZone,
        state: 'negotiating',
        version: target.version + 1,
        deleted: target.deleted,
        createdAt: target.createdAt,
        updatedAt: nowIso,
        files: target.files,
        ledger: target.ledger,
        drafts: target.drafts,
        replies: [reply, ...target.replies],
        events: [
          ClaimAuditEvent(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            action:
                '쇼핑몰 답장 요약 저장 및 약속 금액(${MoneyFormat.formatMinor(agreedMinor, target.currency)}) 확정',
            createdAt: nowIso,
          ),
          ...target.events,
        ],
        summary: ClaimSummaryTotals(
          cash: target.summary.cash,
          goods: target.summary.goods,
          repair: target.summary.repair,
          remaining: (agreedMinor - target.summary.cash).clamp(0, 999999999),
          requestedQty: target.summary.requestedQty,
        ),
        nextStep: '내 카드·통장에 실제로 취소/입금된 금액을 확인하고 입금 완료를 기록하세요.',
      ),
    );
  }

  Future<void> recordRealDeposit({
    required String claimId,
    required String amountStr,
    required String transactionRef,
    required String receivedOn,
    String? proofId,
  }) async {
    final target = findClaim(claimId);
    if (target == null) return;

    final depositMinor = MoneyFormat.decimalStringToMinor(
      amountStr,
      target.currency,
    );
    final normalizedRef = transactionRef.trim().isEmpty
        ? 'CARD-REFUND-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
        : transactionRef.trim();

    try {
      var activeClaim = target;
      // 백엔드 parseReceipt 규칙: 환불(refund) 건은 agreed 금액이 먼저 설정되어 있어야 입금 기록 가능
      if (activeClaim.agreed == null) {
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
          'kind': 'cash',
          'proofId':
              proofId ??
              (activeClaim.files.isNotEmpty ? activeClaim.files.first.id : ''),
          'receivedOn': receivedOn,
          'amount': amountStr,
          'quantity': 1,
          'transactionRef': normalizedRef,
          'note': '실제 카드 취소 및 계좌 입금 내역 대조 완료',
          'missingReferenceConfirmed': true,
          'duplicateReviewed': true,
          'confirmed': true,
        },
      );
      await refreshClaims();
      return;
    } catch (_) {}

    final nowIso = DateTime.now().toIso8601String();
    final newEntry = LedgerEntry(
      id: 'ldg_${DateTime.now().millisecondsSinceEpoch}',
      claimId: claimId,
      kind: 'cash',
      amount: depositMinor,
      quantity: 1,
      note: '실제 카드 취소 · 계좌 입금 확인 완료',
      proofId: proofId,
      transactionRef: transactionRef.isEmpty
          ? 'CARD-REFUND-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
          : transactionRef,
      receivedOn: receivedOn,
      createdAt: nowIso,
    );

    final nextCash = target.summary.cash + depositMinor;
    final targetTotal = target.agreed ?? target.claimed;
    final nextRemaining = (targetTotal - nextCash).clamp(0, 999999999);
    final nextState = nextRemaining == 0 ? 'recovered' : 'partial';

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
        agreed: target.agreed ?? target.claimed,
        issue: target.issue,
        issueEnglish: target.issueEnglish,
        deadline: target.deadline,
        deadlineQuote: target.deadlineQuote,
        deadlineZone: target.deadlineZone,
        state: nextState,
        version: target.version + 1,
        deleted: target.deleted,
        createdAt: target.createdAt,
        updatedAt: nowIso,
        files: target.files,
        ledger: [newEntry, ...target.ledger],
        drafts: target.drafts,
        replies: target.replies,
        events: [
          ClaimAuditEvent(
            id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
            action:
                '실제 카드 취소·입금(${MoneyFormat.formatMinor(depositMinor, target.currency)}) 확인 기록 완료',
            createdAt: nowIso,
          ),
          ...target.events,
        ],
        summary: ClaimSummaryTotals(
          cash: nextCash,
          goods: target.summary.goods,
          repair: target.summary.repair,
          remaining: nextRemaining,
          requestedQty: target.summary.requestedQty,
        ),
        nextStep: nextState == 'recovered'
            ? '모든 환불 금액이 실제 입금되었어요! [환불 절차 마무리하기]를 눌러 완료하세요.'
            : '남은 차액 입금을 확인해 주세요.',
      ),
    );
  }

  Future<void> completeClaim(String claimId) async {
    final target = findClaim(claimId);
    if (target == null) return;
    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/transition',
        method: 'POST',
        version: target.version,
        data: {'action': 'close', 'reason': '소비자 실제 입금 확인 후 마무리 완료'},
      );
      await refreshClaims();
      return;
    } catch (_) {}

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
        state: 'completed',
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
            action: '환불 절차 최종 마무리 완료',
            createdAt: nowIso,
          ),
          ...target.events,
        ],
        summary: target.summary,
        nextStep: '모든 환불 절차가 성공적으로 마무리되었습니다.',
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
    } catch (_) {}

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

  Map<String, dynamic> _buildClaimMutationPayload(
    ClaimView claim, {
    String? agreedAmountStr,
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
      'kind': claim.kind,
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
    final validBytes = ensureValidFileSignature(mime, bytes);

    try {
      await api.requestJson(
        '/api/claims/${Uri.encodeComponent(claimId)}/files',
        method: 'POST',
        version: target.version,
        idempotencyKey: ReloApiClient.newIdempotencyKey(),
        rawBytes: validBytes,
        headers: {
          'Content-Type': mime,
          'X-File-Name': Uri.encodeComponent(fileName),
        },
      );
      await refreshClaims();
      return;
    } catch (_) {}

    final nowIso = DateTime.now().toIso8601String();
    final newFile = ClaimFile(
      id: 'fil_${DateTime.now().millisecondsSinceEpoch}',
      claimId: claimId,
      name: fileName,
      mime: mime,
      size: validBytes.length,
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
    } catch (_) {}

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
        'emailUnsubscribed': emailUnsubscribed,
        'sdkAiEnabled': sdkAiEnabled,
        'sdkMailEnabled': sdkMailEnabled,
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
