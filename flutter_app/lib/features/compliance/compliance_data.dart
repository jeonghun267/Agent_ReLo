/// @module features/compliance/compliance_data
/// @layer Feature Module — Legal, Privacy & Consumer Protection Data
/// @purpose 웹/앱 출시 시 법적 분쟁·고소를 예방하기 위한 필수 20대 안전장치 데이터 및
///          개인정보 처리방침, 이용약관, 환불정책, 쿠키정책, 사업자 정보, 폰트·이미지 라이선스 전문을 정의합니다.

class LegalChecklistItem {
  final int number;
  final String title;
  final String lawReference;
  final String implementationSummary;
  final String actionTabId;

  const LegalChecklistItem({
    required this.number,
    required this.title,
    required this.lawReference,
    required this.implementationSummary,
    required this.actionTabId,
  });
}

class AssetLicenseEntry {
  final String assetName;
  final String category;
  final String licenseType;
  final String copyrightHolder;
  final String commercialRightNote;

  const AssetLicenseEntry({
    required this.assetName,
    required this.category,
    required this.licenseType,
    required this.copyrightHolder,
    required this.commercialRightNote,
  });
}

class ReloComplianceData {
  /// [항목 #16] 운영 주체 정보. 아직 정해지지 않은 것(사업자등록번호, 통신판매업 신고번호,
  /// 주소, 전화, 이메일, 호스팅)은 지어내지 않고 비워 둔다. 화면은 빈 칸을 보여 주지 않는다.
  static const Map<String, String> businessInfo = {
    'companyName': 'RELO',
    'ceoName': '오정훈 · 방승훈',
    'bizRegNo': '',
    'ecommerceRegNo': '',
    'address': '',
    'cpoName': '오정훈 · 방승훈',
    'supportEmail': '',
    'supportPhone': '',
    'hostingProvider': '',
  };

  /// 웹/앱 고소 방지 필수 20가지 체크리스트 및 실제 구현 현황
  static const List<LegalChecklistItem> twentyPointChecklist = [
    LegalChecklistItem(
      number: 1,
      title: '개인정보 처리방침 (Privacy Policy)',
      lawReference: '개인정보보호법 제30조',
      implementationSummary: '수집 항목, 이용 목적, 보유·이용 기간, 제3자 위탁(Gemini/Resend) 및 파기 절차를 상시 열람 가능하도록 전문 공개',
      actionTabId: 'privacy',
    ),
    LegalChecklistItem(
      number: 2,
      title: '이용약관 (Terms of Service)',
      lawReference: '약관의 규제에 관한 법률 제3조',
      implementationSummary: '서비스 범위(직구 환불 기록·외국어 초안 작성 도우미이며, 회원을 대신해 요청·협상하지 않고 요청은 회원 자신의 이름으로 직접 보냄), 이용자 권리·의무 및 면책 기준 명시',
      actionTabId: 'terms',
    ),
    LegalChecklistItem(
      number: 3,
      title: '환불정책 (Refund & Billing Policy)',
      lawReference: '전자상거래법 제17조 (청약철회 등)',
      implementationSummary: '지금은 무료. 유료가 되더라도 기간제 구독 요금만 받고 건별 수수료·성공 보수는 받지 않는다고 명시, 구독은 결제 후 7일 이내 미사용 시 전액 환불',
      actionTabId: 'refund',
    ),
    LegalChecklistItem(
      number: 4,
      title: '쿠키정책 (Cookie Policy)',
      lawReference: '정보통신망법 및 GDPR ePrivacy 기준',
      implementationSummary: '필수 보안 세션 쿠키(relo_session, CSRF 토큰)와 선택 로컬 환경설정의 목적·수명·초기화 방법을 투명하게 공개',
      actionTabId: 'cookie',
    ),
    LegalChecklistItem(
      number: 5,
      title: '쿠키동의 배너 (Cookie Consent Banner)',
      lawReference: '개인정보보호법 및 공정위 다크패턴 가이드라인',
      implementationSummary: '첫 화면에 배너를 띄우지 않음(로그인에 꼭 필요한 보안 세션 쿠키만 쓰고 광고·추적 쿠키가 없음). 쿠키 탭에서 [필수만 허용]과 [전체 동의]를 같은 크기로 고를 수 있음',
      actionTabId: 'cookie',
    ),
    LegalChecklistItem(
      number: 6,
      title: '입력 양식 동의항목 확인 (Explicit Form Consent)',
      lawReference: '개인정보보호법 제15조 및 제22조',
      implementationSummary: '회원가입 및 5단계 환불 신청 양식에서 [필수]/[선택] 동의 체크박스를 분리하고 기본 미체크 상태로 개별 동의 확인',
      actionTabId: 'privacy',
    ),
    LegalChecklistItem(
      number: 7,
      title: '불필요한 개인정보 수집 금지 (Data Minimization)',
      lawReference: '개인정보보호법 제16조 (최소 수집 원칙)',
      implementationSummary: '주민등록번호, 개인통관고유부호, 상세 집 주소, 카드 16자리 전체 번호를 묻지 않음. 올린 파일 속 주소는 자동으로 가려지지 않으므로 가린 뒤 올리도록 안내',
      actionTabId: 'privacy',
    ),
    LegalChecklistItem(
      number: 8,
      title: '외부 SDK 점검 (External SDK & Package Audit)',
      lawReference: '개인정보보호위 모바일 앱 개인정보 점검 기준',
      implementationSummary: '광고 추적 SDK(Meta Pixel/AdMob) 제로 보증, Flutter 3.41.9 핀 호환 패키지 검증, 외부 AI 전송을 끄는 스위치와 알림 메일을 끄는 스위치 제공',
      actionTabId: 'sdk',
    ),
    LegalChecklistItem(
      number: 9,
      title: '원하지 않는 선택 유도 금지 (Anti-Dark Pattern)',
      lawReference: '전자상거래법 온라인 다크패턴 규제 (2025~2026)',
      implementationSummary: '선택 동의 미리 체크 금지, 거절 버튼 숨김 금지, 가입보다 어려운 탈퇴(Roach Motel) 구조 전면 배제',
      actionTabId: 'checklist',
    ),
    LegalChecklistItem(
      number: 10,
      title: '숨겨진 요금 없애기 (Zero Hidden Fees)',
      lawReference: '전자상거래법 순차공개 가격책정(Drip Pricing) 금지',
      implementationSummary: '홈 화면과 신청 최종 단계에 "이용료 0원 · 환불 성공보수 0% · 무료체험 후 몰래 유료전환 없음" 명확 고지',
      actionTabId: 'refund',
    ),
    LegalChecklistItem(
      number: 11,
      title: '가짜후기 없애기 (Zero Fake Reviews)',
      lawReference: '표시·광고의 공정화에 관한 법률 제3조',
      implementationSummary: '임의로 조작한 별점(★★★★★)이나 허위 소비자 체험담을 일절 사용하지 않고 검증된 기능 사실만 표기',
      actionTabId: 'checklist',
    ),
    LegalChecklistItem(
      number: 12,
      title: '근거없는 주장 없애기 (No Unsubstantiated Claims)',
      lawReference: '표시광고법 실증책임 원칙',
      implementationSummary: '"무조건 100% 환불 보장" 같은 과장 문구 배제 ➔ "8개국 통화 계산, 10MB 증빙 격리, 실제 입금 대조 기록" 사실만 명시',
      actionTabId: 'checklist',
    ),
    LegalChecklistItem(
      number: 13,
      title: '접근성 이미지 대체 텍스트 추가 (Semantics Alt Text)',
      lawReference: '장애인차별금지법 및 한국형 웹/앱 콘텐츠 접근성 지침(KWCAG 2.2)',
      implementationSummary: '3D 블루 오브, 브랜드 로고, 상태 배지, 금액 표시기에 Flutter Semantics(label: ...) 대체 텍스트 전수 적용',
      actionTabId: 'checklist',
    ),
    LegalChecklistItem(
      number: 14,
      title: '글자와 배경 색상대비 개선 (WCAG AA/AAA Contrast)',
      lawReference: 'KWCAG 2.2 텍스트 콘텐츠 명도 대비 (4.5:1 이상)',
      implementationSummary: '다크/라이트 모드 보조 텍스트 대비율 7.1:1 이상 개선 + 시각 약자용 WCAG AAA 초고대비(15:1) 모드 토글 탑재',
      actionTabId: 'checklist',
    ),
    LegalChecklistItem(
      number: 15,
      title: '키보드만으로 이동 가능 (Full Keyboard Navigation)',
      lawReference: 'KWCAG 2.2 키보드 사용 보장',
      implementationSummary: 'Tab/Shift+Tab 포커스 링, Enter/Space 실행, Alt+1~5 탭 즉시 이동 단축키로 마우스 없이 전 기능 조작 가능',
      actionTabId: 'checklist',
    ),
    LegalChecklistItem(
      number: 16,
      title: '사업자 정보 추가 (Business Registration Footer)',
      lawReference: '전자상거래법 제10조 (사이버몰의 표시)',
      implementationSummary: '상호와 책임자를 하단에 상시 표시. 사업자등록번호, 통신판매업신고번호, 주소, 연락처는 정해지면 채움 (지어낸 값을 넣지 않음)',
      actionTabId: 'terms',
    ),
    LegalChecklistItem(
      number: 17,
      title: '아동 정보 수집 시 나이 확인 절차 (Age Verification Gate)',
      lawReference: '개인정보보호법 제22조의2 (아동의 개인정보 보호)',
      implementationSummary: '회원가입 시 만 14세 이상 필수 연령 확인 + 만 14세 미만 선택 시 법정대리인(부모) 동의 확인 절차 작동',
      actionTabId: 'privacy',
    ),
    LegalChecklistItem(
      number: 18,
      title: '이메일 수신거부 링크 확인 (One-Click Unsubscribe)',
      lawReference: '정보통신망법 제50조 (영리목적 광고성 정보 제한)',
      implementationSummary: '광고 메일을 보내지 않음. 보내는 메일은 이메일 인증 · 비밀번호 재설정과, [스스로 시작하기]를 켠 회원에게 AI가 허락을 기다린다고 알리는 메일뿐. 알림 메일은 설정의 스위치로 끌 수 있고 끄는 방법을 메일에 적음 (메일 안의 원클릭 수신거부 링크는 아직 없음)',
      actionTabId: 'sdk',
    ),
    LegalChecklistItem(
      number: 19,
      title: '사용 이미지·글꼴 이용권 확보 (Font & Asset License)',
      lawReference: '저작권법 제46조 (저작물의 이용허락)',
      implementationSummary: 'Pretendard(SIL OFL 1.1), Lucide Icons(ISC), Material Icons(Apache 2.0), 100% 자체 제작 CustomPainter 그래픽으로 저작권 침해 위험 0%',
      actionTabId: 'licenses',
    ),
    LegalChecklistItem(
      number: 20,
      title: '개인정보 삭제요청 기능 추가 (Immediate Data Purge)',
      lawReference: '개인정보보호법 제36조 (개인정보의 정정·삭제)',
      implementationSummary: '설정 및 법적보호 센터에서 원클릭/비밀번호 확인 즉시 계정·클레임·영수증 사진을 영구 파기하고 파기 증명 번호 발급',
      actionTabId: 'delete',
    ),
  ];

  /// [항목 #1] 개인정보 처리방침 전문
  static const String privacyPolicyFullText = '''
[ReLo 개인정보 처리방침 (시행일: 2026년 11월 18일)]

RELO(이하 "회사")는 『개인정보 보호법』 제30조에 따라 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 다음과 같이 개인정보 처리방침을 수립·공개합니다.

1. 개인정보의 수집 항목 및 최소 수집 원칙 (법 제16조 준수)
- 필수 수집 항목: 이메일 주소, 비밀번호(단방향 암호화 해시 저장), 이름(또는 닉네임)
- 고른 로그인 방법에 따라: 기기 패스키의 공개 키, Google 로그인 식별값과 이메일
- 환불 기록 시 이용자가 직접 입력하는 항목: 해외 쇼핑몰명, 주문번호, 상품명, 환불 요청 금액, 파손/오배송 사유 및 증빙 사진(최대 10MB)
- [묻지 않는 항목]: 회사는 주민등록번호, 개인통관고유부호, 상세 자택 주소, 신용카드 16자리 전체 번호, 계좌 비밀번호를 묻지 않습니다. 다만 올린 영수증·사진에 이런 정보가 찍혀 있으면 파일에 그대로 남으므로, 가린 뒤 올려 주세요.

2. 개인정보의 처리 목적
- 본인 확인, 그리고 본인만 볼 수 있는 환불 기록 보관
- 해외직구 반품·교환·환불 진행 현황 기록 및 실제 카드 취소·입금 내역 대조
- 이용자가 명시적으로 동의(Opt-in)한 경우에 한하여 AI 주문서 자동 읽기 및 외국어 환불 요청서 초안 생성 지원
- 이메일 본인 인증 및 비밀번호 재설정 메일 발송, 그리고 [스스로 시작하기]를 켠 경우에 한하여 AI가 허락을 기다린다는 알림 메일 발송

3. 개인정보의 제3자 제공 및 처리위탁 (외부 SDK 점검 공개)
회사는 이용자의 사전 동의 없이 개인정보를 외부에 판매하거나 광고 추적 브로커에게 제공하지 않습니다.
- Google (Gemini API, 국외 서버): 이용자가 [AI 도우미 동의]를 켠 경우에 한하여, AI 기능을 쓸 때마다 주문 내용(쇼핑몰·주문번호·상품·금액·문제 설명), 붙여 넣은 판매자 답장, 읽어 달라고 고른 영수증·주문서 파일을 가리지 않고 그대로 전송합니다. 파일에 적힌 이름·주소도 함께 전송됩니다. 가입할 때 적은 이름·이메일·비밀번호는 전송하지 않습니다. [AI에게 맡기기]를 쓰면 AI가 그 건에 올려 둔 자료와 저장된 답장 가운데 읽을 것을 스스로 골라 같은 방식으로 전송합니다. [스스로 시작하기]를 켠 경우에는 이용자가 버튼을 누르지 않아도, 신청하거나 자료를 올리거나 답장을 저장했을 때 그렇게 합니다. 이 기능은 처음에는 꺼져 있고, 이용자가 직접 켠 경우에만 작동하며, 언제든 끌 수 있습니다.
- Resend Inc.: 이메일 본인 인증 및 비밀번호 재설정 안내 메일 발송, 그리고 [스스로 시작하기]를 켠 이용자에게 AI가 허락을 기다린다고 알리는 메일 발송 (받는 이메일 주소와 메일 내용 전달). 알리는 메일에는 쇼핑몰·상품·금액 같은 주문 내용을 적지 않으며, 설정에서 끌 수 있습니다. 광고 메일은 보내지 않습니다.

4. 개인정보의 보유·이용 기간 및 즉시 파기 절차 (법 제36조 준수)
- 보유 기간: 회원 탈퇴 또는 개인정보 삭제 요청 시까지
- 즉시 파기: 이용자가 앱 내 [설정 > 회원 탈퇴 및 개인정보 즉시 삭제] 또는 [법적보호 20선 > 개인정보 삭제요청]을 실행하면, 데이터베이스(SQLite) 내 환불 기록, 초안, 답장 및 첨부된 증빙 사진이 즉시 삭제됩니다.

5. 만 14세 미만 아동의 개인정보 보호 (법 제22조의2 준수)
- 본 서비스는 원칙적으로 만 14세 이상 소비자를 대상으로 하며, 만 14세 미만 아동이 이용하고자 할 경우 법정대리인(부모)의 명시적 동의 확인 절차를 거칩니다.

6. 개인정보 보호책임자 (CPO)
- 성명: 오정훈 · 방승훈
- 연락처: 준비 중입니다. 정해지면 이곳에 적습니다.
''';

  /// [항목 #2] 서비스 이용약관 전문
  static const String termsOfServiceFullText = '''
[ReLo 서비스 이용약관 (시행일: 2026년 11월 18일)]

제1조 (목적)
본 약관은 RELO(이하 "회사")가 제공하는 해외직구 반품·교환·환불 원스톱 기록 및 외국어 문의 초안 도우미 서비스 "ReLo"(이하 "서비스")의 이용 조건 및 절차, 회사와 회원의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (서비스의 성격 및 법적 한계 고지 — 근거없는 주장 배제)
1. ReLo는 소비자가 해외 쇼핑몰(Amazon, AliExpress, Taobao, Mercari 등)에 직접 반품·교환·환불을 요청할 때 필요한 증빙 정리, 8개국 통화 계산, 외국어 메시지 초안 작성, 실제 카드 취소 입금 확인 기록을 돕는 소프트웨어 도구입니다.
2. 회사는 변호사법상 법률 대리인이 아니며, 해외 판매자의 환불 승인 여부를 임의로 보증하거나("무조건 100% 환불 보장" 등) 법적 소송을 대행하지 않습니다. 최종 환불 승인 및 결제 취소는 해당 해외 쇼핑몰과 카드사의 정책에 따릅니다.
3. 회사는 회원을 대신해 쇼핑몰에 연락하거나, 요청을 보내거나, 협상하지 않습니다. 반품·교환·환불·수리 요청은 회원이 자신의 이름으로 직접 보냅니다. 서비스가 만드는 메시지 초안은 회원 자신의 글이며, 보내는 사람이나 대리인으로 ReLo의 이름을 적지 않습니다.
4. AI가 쓴 초안과 요약에는 AI가 만들었다고 표시합니다. AI가 만든 내용은 틀릴 수 있으므로, 보내거나 저장하기 전에 회원이 읽고 확인합니다.
5. AI가 스스로 다음 일을 골라서 하는 기능(AI에게 맡기기)도 같습니다. 기록을 고치거나 저장하는 일은 무엇이 바뀌는지 먼저 보여 주고 회원이 허락한 것만 하며, 쇼핑몰에 보내는 일은 하지 않습니다.
6. 회원이 [스스로 시작하기]를 켜 두면, 신청하거나 자료를 올리거나 답장을 저장했을 때 AI가 버튼을 누르지 않아도 그 건을 살펴봅니다. 이때에도 회원의 허락 없이는 기록을 고치거나 저장하지 않으며, 쇼핑몰에 보내는 일은 하지 않습니다. 설정이나 각 건의 화면에서 언제든 끌 수 있고, AI 동의를 끄면 함께 꺼집니다. AI가 허락을 기다리는데 한동안 답이 없으면 회원이 인증한 이메일로 한 번 알리며, 이 메일은 설정에서 따로 끌 수 있습니다.
7. 신청할 때 AI가 주문서와 회원이 적은 내용으로 칸을 채워 줄 수 있습니다. 채운 값은 AI가 채웠다고 표시하며, 회원이 확인하고 신청하기 전에는 저장되지 않습니다.

제3조 (이용자의 권리 및 데이터 소유권)
1. 회원이 등록한 모든 클레임 기록과 증빙 사진의 소유권은 회원 본인에게 있으며, 다른 회원이나 제3자에게 노출되지 않도록 엄격히 격리됩니다.
2. 회원은 언제든지 [내 전체 기록 JSON 내보내기]를 통해 데이터를 백업하거나 [즉시 삭제]를 요청할 수 있습니다.

제4조 (다크패턴 금지 및 공정한 선택 보장)
회사는 이용자가 원하지 않는 유료 결제나 마케팅 수신으로 유도하는 눈속임 설계(다크패턴)를 일절 사용하지 않으며, 해지 및 탈퇴 절차를 가입 절차보다 복잡하게 만들지 않습니다.

제5조 (요금)
1. 서비스는 현재 무료입니다.
2. 유료로 바꾸더라도 정해진 기간(월·연) 단위의 구독 요금만 받습니다. 환불 건마다 받는 수수료, 돌려받은 금액에 비례하는 수수료, 성공 보수는 받지 않습니다.
3. 요금을 받기 시작하거나 바꿀 때에는 미리 알리고, 회원이 직접 동의한 경우에만 결제가 이루어집니다.
''';

  /// [항목 #3 & #10] 환불정책 및 숨겨진 요금 제로 선언 전문
  static const String refundPolicyFullText = '''
[ReLo 요금 원칙 및 환불정책]

1. 지금은 무료
- ReLo의 환불 신청, 환불 기록, 증빙 보관, AI 초안 작성은 현재 무료입니다.

2. 유료가 되더라도 구독 요금만
- 유료로 바꾸더라도 정해진 기간(월·연) 단위의 구독 요금만 받습니다.
- 환불 건마다 받는 수수료, 돌려받은 금액에 비례하는 수수료, 성공 보수는 받지 않습니다. ReLo는 회원을 대신해 환불을 받아 주는 서비스가 아니기 때문입니다.
- 무료 체험 뒤에 동의 없이 유료로 넘어가지 않습니다.

3. 구독 요금의 청약철회 및 환불 기준
구독 요금을 받게 되면 『전자상거래 등에서의 소비자보호에 관한 법률』 제17조에 따라 아래 기준을 지킵니다:
- 결제일로부터 7일 이내이고 쓰지 않은 경우: 위약금이나 수수료 없이 전액 환불
- 결제 후 일부 이용한 경우: 이용한 기간을 뺀 나머지 기간의 요금을 일할 계산해 환불
- 서비스 장애 또는 표시·광고 내용과 다른 경우: 문제 발생을 안 날로부터 30일(또는 공급일로부터 3개월) 이내 전액 환불
''';

  /// [항목 #4 & #5] 쿠키정책 전문
  static const String cookiePolicyFullText = '''
[ReLo 쿠키(Cookie) 및 로컬 스토리지 운영 정책]

1. 쿠키의 사용 목적
ReLo는 제3자 맞춤형 광고 추적 쿠키(Third-party Tracking Cookie)를 일절 사용하지 않으며, 오직 안전한 로그인 세션 유지와 사용자 환경설정을 위해서만 쿠키/로컬 저장소를 사용합니다.

2. 사용 중인 쿠키 및 저장 항목 상세
- [필수] relo_session (HttpOnly, SameSite=Lax): 로그인 본인 인증 세션 유지 및 타인 접근 차단 (로그아웃 시 즉시 소멸)
- [필수] X-CSRF-Token: 사이트 간 요청 위조(CSRF) 해킹 공격 방어용 보안 토큰
- [선택] relo_ui_prefs: 사용자가 선택한 다크/라이트/고대비 테마, 언어(KO/EN/JA/ZH), 위저드 작성 중 임시 입력값 보존

3. 이용자의 쿠키 선택권 (거절 권리 보장)
이용자는 하단 쿠키 동의 배너 또는 본 화면에서 언제든지 [필수 쿠키만 허용(선택 거절)]을 선택할 수 있으며, 선택 쿠키를 거절하더라도 환불 신청 및 내역 조회 등 모든 핵심 기능을 정상적으로 이용할 수 있습니다.
''';

  /// [항목 #19] 사용하는 이미지와 글꼴의 상업적 이용권(License) 확보 내역
  static const List<AssetLicenseEntry> verifiedAssetLicenses = [
    AssetLicenseEntry(
      assetName: 'Pretendard Variable (v1.3.9)',
      category: '글꼴 (Web / App Font)',
      licenseType: 'SIL Open Font License 1.1 (OFL)',
      copyrightHolder: 'Kil Hyung-jin (길형진) & Original Authors',
      commercialRightNote: '상업적·비상업적 웹/앱 임베딩, 번들링 및 배포가 100% 무료로 허락된 오픈소스 라이선스 확보 완료',
    ),
    AssetLicenseEntry(
      assetName: 'Lucide Icons (lucide_icons_flutter 4.0.1)',
      category: '아이콘 시스템 (앱 화면의 모든 아이콘)',
      licenseType: 'ISC License (아이콘) / MIT License (Flutter 패키지)',
      copyrightHolder: 'Lucide Contributors · Cole Bemis (Feather) / vqhapp',
      commercialRightNote: '상업용 애플리케이션 내 자유로운 사용·수정·배포 이용권 확보 완료',
    ),
    AssetLicenseEntry(
      assetName: 'Flutter Material Icons & Cupertino Icons',
      category: '아이콘 시스템 (날짜 고르기 등 Flutter 기본 위젯 안에서만)',
      licenseType: 'Apache License 2.0 / MIT License',
      copyrightHolder: 'Google LLC / Flutter Authors',
      commercialRightNote: '상업용 애플리케이션 내 자유로운 수정·배포 이용권 확보 완료',
    ),
    AssetLicenseEntry(
      assetName: 'ReLo 3D Blue Orb Emblem & Flight Trajectory',
      category: '브랜드 엠블럼 및 일러스트',
      licenseType: '100% In-house Original CustomPainter Code',
      copyrightHolder: 'RELO (자체 제작 코드 그래픽)',
      commercialRightNote: '외부 스톡 이미지나 타사 아이콘을 복제하지 않고 순수 Dart Canvas/SVG 수식으로 직접 제작하여 저작권 분쟁 위험 0%',
    ),
  ];
}
