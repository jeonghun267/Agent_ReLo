/// @module core/i18n/relo_i18n
/// @layer Core Localization (KO / EN / JA / ZH 4-Language Dictionary)
/// @purpose 4개국어 다국어 사전 및 법적 보호/접근성 UI 문자열을 제공합니다.

enum ReloLocale {
  ko('ko', 'KO', '한국어'),
  en('en', 'EN', 'English'),
  ja('ja', 'JA', '日本語'),
  zh('zh', 'ZH', '中文');

  final String code;
  final String shortLabel;
  final String nativeName;
  const ReloLocale(this.code, this.shortLabel, this.nativeName);
}

class ReloStrings {
  final ReloLocale locale;
  const ReloStrings(this.locale);

  String get navHome => switch (locale) {
    ReloLocale.ko => '홈',
    ReloLocale.en => 'Home',
    ReloLocale.ja => 'ホーム',
    ReloLocale.zh => '首页',
  };

  String get navWizard => switch (locale) {
    ReloLocale.ko => '신청하기',
    ReloLocale.en => 'New Claim',
    ReloLocale.ja => ' 환불신청',
    ReloLocale.zh => '申请退款',
  };

  String get navClaims => switch (locale) {
    ReloLocale.ko => '내 환불',
    ReloLocale.en => 'My Claims',
    ReloLocale.ja => 'マイ返金',
    ReloLocale.zh => '我的退款',
  };

  String get navCompliance => switch (locale) {
    ReloLocale.ko => '법적보호 20선',
    ReloLocale.en => 'Legal & Safety',
    ReloLocale.ja => '法的保護20選',
    ReloLocale.zh => '合规与安全',
  };

  String get navSettings => switch (locale) {
    ReloLocale.ko => '설정',
    ReloLocale.en => 'Settings',
    ReloLocale.ja => '設定',
    ReloLocale.zh => '设置',
  };

  String get heroTitleLine1 => switch (locale) {
    ReloLocale.ko => '멀리서 깨져서 온 해외직구 택배,',
    ReloLocale.en => 'Damaged overseas package arrived?',
    ReloLocale.ja => '壊れて届いた海外通販の荷物、',
    ReloLocale.zh => '海淘包裹破损到达？',
  };

  String get heroTitleLine2 => switch (locale) {
    ReloLocale.ko => '외국어 한 줄 몰라도 내 통장으로 환불.',
    ReloLocale.en => 'Get real money back without speaking foreign languages.',
    ReloLocale.ja => '外国語が分からなくても口座へしっかり返金。',
    ReloLocale.zh => '不懂外语也能轻松退回您的银行账户。',
  };

  String get heroSubtitle => switch (locale) {
    ReloLocale.ko =>
        '복잡한 영어·중국어·일본어 고객센터 문의부터\n말뿐인 환불 약속이 아닌 실제 카드 취소·계좌 입금까지 끝까지 기록해 드려요.',
    ReloLocale.en =>
        'From English, Chinese, and Japanese support messages to tracking real card cancellations and deposits.',
    ReloLocale.ja =>
        '英語・中国語・日本語の問い合わせ作成から、実際のカード取消・口座入金確認まで最後までサポートします。',
    ReloLocale.zh =>
        '从生成英中日客服申诉信，到核实银行卡实际退款入账，全程为您守护。',
  };

  String get ctaPrimary => switch (locale) {
    ReloLocale.ko => '지금 3분 만에 환불 신청하기 →',
    ReloLocale.en => 'Start 3-Min Refund Wizard →',
    ReloLocale.ja => '今すぐ3分で返金申請する →',
    ReloLocale.zh => '立即3分钟申请退款 →',
  };

  String get ctaSecondary => switch (locale) {
    ReloLocale.ko => '내 환불 내역 보기',
    ReloLocale.en => 'View My Refund Claims',
    ReloLocale.ja => 'マイ返金履歴を見る',
    ReloLocale.zh => '查看我的退款记录',
  };

  String get metric1Title => switch (locale) {
    ReloLocale.ko => '8개국 통화',
    ReloLocale.en => '8 Currencies',
    ReloLocale.ja => '8通貨対応',
    ReloLocale.zh => '8国货币',
  };

  String get metric1Sub => switch (locale) {
    ReloLocale.ko => '정확한 금액 계산',
    ReloLocale.en => 'Exact minor-unit math',
    ReloLocale.ja => '正確な金額計算',
    ReloLocale.zh => '精确金额计算',
  };

  String get metric2Title => switch (locale) {
    ReloLocale.ko => '10MB 사진',
    ReloLocale.en => '10MB Photos',
    ReloLocale.ja => '10MB写真',
    ReloLocale.zh => '10MB照片',
  };

  String get metric2Sub => switch (locale) {
    ReloLocale.ko => '증빙 안전 보관',
    ReloLocale.en => 'Isolated proof vault',
    ReloLocale.ja => '証拠を安全保管',
    ReloLocale.zh => '凭证安全隔离',
  };

  String get metric3Title => switch (locale) {
    ReloLocale.ko => '카드 취소',
    ReloLocale.en => 'Card Refund',
    ReloLocale.ja => 'カード取消',
    ReloLocale.zh => '银行卡退单',
  };

  String get metric3Sub => switch (locale) {
    ReloLocale.ko => '실제 입금 확인',
    ReloLocale.en => 'Real deposit check',
    ReloLocale.ja => '実入金を確認',
    ReloLocale.zh => '核实实际入账',
  };

  String get frequentMallsHeader => switch (locale) {
    ReloLocale.ko => '자주 찾는 직구 쇼핑몰 즉시 환불',
    ReloLocale.en => 'Quick Start by Overseas Store',
    ReloLocale.ja => 'よく使う海外ショップから即申請',
    ReloLocale.zh => '常见海淘商城快速申请',
  };

  String get tapToStart => switch (locale) {
    ReloLocale.ko => '탭하여 시작',
    ReloLocale.en => 'Tap to start',
    ReloLocale.ja => 'タップして開始',
    ReloLocale.zh => '点击开始',
  };
}
