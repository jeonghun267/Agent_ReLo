/// @module core/i18n/relo_i18n
/// @layer Core Localization (KO / EN / JA / ZH 4-Language Dictionary)
/// @purpose 4개국어 다국어 사전. 사용자에게 보이는 문구는 DESIGN.md 6절의 말투를 따른다.

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
        ReloLocale.ja => '返金申請',
        ReloLocale.zh => '申请退款',
      };

  String get navClaims => switch (locale) {
        ReloLocale.ko => '내 환불',
        ReloLocale.en => 'My Claims',
        ReloLocale.ja => 'マイ返金',
        ReloLocale.zh => '我的退款',
      };

  String get navCompliance => switch (locale) {
        ReloLocale.ko => '약관·정책',
        ReloLocale.en => 'Terms & Policies',
        ReloLocale.ja => '規約・ポリシー',
        ReloLocale.zh => '条款与政策',
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
        ReloLocale.en =>
          'Get real money back without speaking foreign languages.',
        ReloLocale.ja => '外国語が分からなくても口座へしっかり返金。',
        ReloLocale.zh => '不懂外语也能轻松退回您的银行账户。',
      };

  String get heroSubtitle => switch (locale) {
        ReloLocale.ko =>
          '복잡한 영어·중국어·일본어 고객센터 문의부터\n말뿐인 환불 약속이 아닌 실제 카드 취소·계좌 입금까지 끝까지 기록해 드려요.',
        ReloLocale.en =>
          'From English, Chinese, and Japanese support messages to tracking real card cancellations and deposits.',
        ReloLocale.ja => '英語・中国語・日本語の問い合わせ作成から、実際のカード取消・口座入金確認まで最後までサポートします。',
        ReloLocale.zh => '从生成英中日客服申诉信，到核实银行卡实际退款入账，全程为您守护。',
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

  // --- AI 도우미 ---------------------------------------------------------

  String get assistantName => switch (locale) {
        ReloLocale.ko => 'ReLo 도우미',
        ReloLocale.en => 'ReLo Helper',
        ReloLocale.ja => 'ReLo アシスタント',
        ReloLocale.zh => 'ReLo 助手',
      };

  String get assistantGreeting => switch (locale) {
        ReloLocale.ko => '무엇을 도와드릴까요?',
        ReloLocale.en => 'How can I help?',
        ReloLocale.ja => '何をお手伝いしましょうか？',
        ReloLocale.zh => '需要什么帮助？',
      };

  String get assistantGreetingSub => switch (locale) {
        ReloLocale.ko => '내 환불 기록을 보고 답해요. 판매자에게 보낼 글도 같이 써요.',
        ReloLocale.en =>
          'I answer from your claims and help you write to sellers.',
        ReloLocale.ja => 'あなたの返金記録を見て答えます。販売者への文面も一緒に作ります。',
        ReloLocale.zh => '我会根据你的退款记录回答，也能帮你写给卖家的信。',
      };

  List<String> get assistantStarters => switch (locale) {
        ReloLocale.ko => const [
            '내 환불 어디까지 왔어?',
            '판매자한테 독촉 메일 써 줘',
            '판매자 답장 해석해 줘',
            '환불이랑 교환은 뭐가 달라?',
            '카드 취소는 보통 며칠 걸려?',
          ],
        ReloLocale.en => const [
            'Where is my refund now?',
            'Write a reminder to the seller',
            'Explain the seller reply',
            'Refund vs. exchange?',
            'How long do card refunds take?',
          ],
        ReloLocale.ja => const [
            '返金は今どこまで進んでる？',
            '販売者に催促メールを書いて',
            '販売者の返信を訳して',
            '返金と交換の違いは？',
            'カード取消は何日かかる？',
          ],
        ReloLocale.zh => const [
            '我的退款到哪一步了？',
            '帮我写催促卖家的邮件',
            '帮我解读卖家回复',
            '退款和换货有什么区别？',
            '银行卡退款一般要几天？',
          ],
      };

  List<String> get assistantClaimStarters => switch (locale) {
        ReloLocale.ko => const [
            '이 건 지금 어떤 상태야?',
            '이 건 독촉 메일 써 줘',
            '판매자 답장 해석해 줘'
          ],
        ReloLocale.en => const [
            'What is the status of this claim?',
            'Write a reminder for this claim',
            'Explain the seller reply'
          ],
        ReloLocale.ja => const ['この件は今どんな状態？', 'この件の催促メールを書いて', '販売者の返信を訳して'],
        ReloLocale.zh => const ['这笔现在是什么状态？', '帮这笔写催促邮件', '帮我解读卖家回复'],
      };

  String get assistantInputHint => switch (locale) {
        ReloLocale.ko => '궁금한 걸 물어보세요',
        ReloLocale.en => 'Ask anything about your refunds',
        ReloLocale.ja => '気になることを聞いてください',
        ReloLocale.zh => '有什么想问的',
      };

  String get assistantDisclaimer => switch (locale) {
        ReloLocale.ko => 'AI 답변은 틀릴 수 있어요. 금액과 날짜는 상세 화면에서 꼭 확인하세요.',
        ReloLocale.en =>
          'AI can be wrong. Check amounts and dates in the claim.',
        ReloLocale.ja => 'AIの回答は間違うことがあります。金額と日付は詳細画面で確認してください。',
        ReloLocale.zh => 'AI 回答可能有误，金额和日期请在详情页确认。',
      };

  String get assistantThinking => switch (locale) {
        ReloLocale.ko => '생각하는 중',
        ReloLocale.en => 'Thinking',
        ReloLocale.ja => '考え中',
        ReloLocale.zh => '思考中',
      };

  String get assistantOfflineNote => switch (locale) {
        ReloLocale.ko => '서버 AI 대신 기본 안내로 답했어요',
        ReloLocale.en => 'Basic answer (server AI unavailable)',
        ReloLocale.ja => 'サーバーAIの代わりに基本案内で回答しました',
        ReloLocale.zh => '未连接服务器 AI，这是基本说明',
      };

  String get assistantNewChat => switch (locale) {
        ReloLocale.ko => '새 대화',
        ReloLocale.en => 'New chat',
        ReloLocale.ja => '新しい会話',
        ReloLocale.zh => '新对话',
      };

  String get assistantAskThisClaim => switch (locale) {
        ReloLocale.ko => '이 건 물어보기',
        ReloLocale.en => 'Ask about this',
        ReloLocale.ja => 'この件を質問',
        ReloLocale.zh => '询问这笔',
      };

  String assistantContext(String vendor) => switch (locale) {
        ReloLocale.ko => '$vendor 건에 대해 물어보는 중',
        ReloLocale.en => 'Asking about $vendor',
        ReloLocale.ja => '$vendor の件について質問中',
        ReloLocale.zh => '正在询问 $vendor 这笔',
      };

  String assistantAction(String action) => switch ((locale, action)) {
        (ReloLocale.ko, 'open_claim') => '상세 열기',
        (ReloLocale.ko, 'draft_email') => '판매자 메시지 쓰기',
        (ReloLocale.ko, 'analyze_reply') => '답장 붙여 넣기',
        (ReloLocale.ko, 'new_claim') => '새 환불 신청',
        (ReloLocale.en, 'open_claim') => 'Open claim',
        (ReloLocale.en, 'draft_email') => 'Write to seller',
        (ReloLocale.en, 'analyze_reply') => 'Paste reply',
        (ReloLocale.en, 'new_claim') => 'New claim',
        (ReloLocale.ja, 'open_claim') => '詳細を開く',
        (ReloLocale.ja, 'draft_email') => '販売者へ書く',
        (ReloLocale.ja, 'analyze_reply') => '返信を貼り付け',
        (ReloLocale.ja, 'new_claim') => '新規申請',
        (ReloLocale.zh, 'open_claim') => '打开详情',
        (ReloLocale.zh, 'draft_email') => '写给卖家',
        (ReloLocale.zh, 'analyze_reply') => '粘贴回复',
        (ReloLocale.zh, 'new_claim') => '新建申请',
        _ => '',
      };

  String get assistantConsentTitle => switch (locale) {
        ReloLocale.ko => 'AI 처리에 동의하면 시작할 수 있어요',
        ReloLocale.en => 'Agree to AI processing to start',
        ReloLocale.ja => 'AI処理に同意すると始められます',
        ReloLocale.zh => '同意 AI 处理后即可开始',
      };

  String get assistantConsentBody => switch (locale) {
        ReloLocale.ko => '쇼핑몰·주문번호·금액·진행 상태만 AI에 보내요. 이름·주소·카드번호는 보내지 않아요.',
        ReloLocale.en =>
          'Only shop, order number, amounts and status are sent. Never your name, address or card number.',
        ReloLocale.ja => 'ショップ・注文番号・金額・進行状況だけを送ります。氏名・住所・カード番号は送りません。',
        ReloLocale.zh => '只发送商城、订单号、金额和进度，不发送姓名、地址和卡号。',
      };

  String get assistantConsentButton => switch (locale) {
        ReloLocale.ko => '동의하고 시작하기',
        ReloLocale.en => 'Agree and start',
        ReloLocale.ja => '同意して始める',
        ReloLocale.zh => '同意并开始',
      };
}
