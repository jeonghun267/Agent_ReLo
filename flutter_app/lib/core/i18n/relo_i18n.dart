import '../attachments/evidence_rules.dart';
import '../utils/dday.dart';
import '../utils/money_format.dart';

export 'relo_i18n_agent.dart';

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
        ReloLocale.ko => '신청',
        ReloLocale.en => 'New',
        ReloLocale.ja => '申請',
        ReloLocale.zh => '申请',
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
        // 이 동의 하나로 도우미 · 영수증 읽기 · 답장 요약 · 글 쓰기가 모두 켜지므로, 보내는 것을 다 적는다
        ReloLocale.ko =>
          'AI 도우미는 해외에 있는 Google의 AI(Gemini)로 일해요. 주문 내용(쇼핑몰·주문번호·상품·금액·문제 설명), 붙여 넣은 판매자 답장, 읽어 달라고 고른 영수증 파일을 보내요. 파일에 적힌 이름·주소도 함께 가요. 가입할 때 적은 이름·이메일·비밀번호는 보내지 않아요.',
        ReloLocale.en =>
          'The AI helper works with Google\'s AI (Gemini) outside Korea. It sends your order details (shop, order number, product, amount, what went wrong), the seller reply you paste, and the receipt file you choose to have read, including any name or address printed on it. The name, email and password you signed up with are not sent.',
        ReloLocale.ja =>
          'AIアシスタントは海外にあるGoogleのAI（Gemini）で動きます。注文内容（ショップ・注文番号・商品・金額・問題の説明）、貼り付けた販売者の返信、読み取りのために選んだ領収書ファイルを送ります。ファイルに書かれた氏名・住所も一緒に送られます。登録時の氏名・メールアドレス・パスワードは送りません。',
        ReloLocale.zh =>
          'AI 助手使用位于海外的 Google AI（Gemini）。会发送订单内容（商城、订单号、商品、金额、问题说明）、你粘贴的卖家回复，以及你选来读取的收据文件，文件上的姓名和地址也会一起发送。注册时填写的姓名、邮箱和密码不会发送。',
      };

  String get assistantConsentButton => switch (locale) {
        ReloLocale.ko => '동의하고 시작하기',
        ReloLocale.en => 'Agree and start',
        ReloLocale.ja => '同意して始める',
        ReloLocale.zh => '同意并开始',
      };

  String get assistantHistory => switch (locale) {
        ReloLocale.ko => '대화 기록',
        ReloLocale.en => 'Chat history',
        ReloLocale.ja => '会話履歴',
        ReloLocale.zh => '对话记录',
      };

  String get assistantHistoryPast => switch (locale) {
        ReloLocale.ko => '지난 대화',
        ReloLocale.en => 'Past chats',
        ReloLocale.ja => '過去の会話',
        ReloLocale.zh => '历史对话',
      };

  String get assistantFloatingToggle => switch (locale) {
        ReloLocale.ko => '도우미 캐릭터 띄우기',
        ReloLocale.en => 'Show floating helper',
        ReloLocale.ja => 'アシスタントを画面に表示',
        ReloLocale.zh => '显示悬浮助手',
      };

  String get assistantHistoryEmpty => switch (locale) {
        ReloLocale.ko => '아직 저장된 대화가 없어요',
        ReloLocale.en => 'No saved chats yet',
        ReloLocale.ja => '保存された会話はまだありません',
        ReloLocale.zh => '还没有保存的对话',
      };

  String get assistantHistoryLocal => switch (locale) {
        ReloLocale.ko => '대화 기록은 이 기기에만 저장돼요',
        ReloLocale.en => 'Chats are saved only on this device',
        ReloLocale.ja => '会話履歴はこの端末にだけ保存されます',
        ReloLocale.zh => '对话记录只保存在本设备上',
      };

  String get assistantHistoryDeleteAll => switch (locale) {
        ReloLocale.ko => '대화 기록 모두 지우기',
        ReloLocale.en => 'Delete all chats',
        ReloLocale.ja => '会話履歴をすべて削除',
        ReloLocale.zh => '删除全部对话',
      };

  String get assistantHistoryDeleteConfirm => switch (locale) {
        ReloLocale.ko => '지난 대화를 모두 지울까요? 되돌릴 수 없어요.',
        ReloLocale.en => 'Delete all past chats? This cannot be undone.',
        ReloLocale.ja => '過去の会話をすべて削除しますか？元に戻せません。',
        ReloLocale.zh => '要删除全部历史对话吗？删除后无法恢复。',
      };

  String get assistantToday => switch (locale) {
        ReloLocale.ko => '오늘',
        ReloLocale.en => 'Today',
        ReloLocale.ja => '今日',
        ReloLocale.zh => '今天',
      };

  // ── 홈 (도우미와의 대화) ──────────────────────────────────────────────

  String get homeInputHint => switch (locale) {
        ReloLocale.ko => '무엇이든 부탁하세요',
        ReloLocale.en => 'Ask ReLo anything',
        ReloLocale.ja => '何でも頼んでください',
        ReloLocale.zh => '有什么都可以交给我',
      };

  String homeMoneyDue(int count) => switch (locale) {
        ReloLocale.ko => count > 0 ? '받을 돈 · $count건' : '받을 돈',
        ReloLocale.en => count > 0 ? 'To receive · $count' : 'To receive',
        ReloLocale.ja => count > 0 ? '受け取る金額 · $count件' : '受け取る金額',
        ReloLocale.zh => count > 0 ? '待收款 · $count笔' : '待收款',
      };

  String get homeMoneyReceived => switch (locale) {
        ReloLocale.ko => '받은 돈',
        ReloLocale.en => 'Received',
        ReloLocale.ja => '受け取り済み',
        ReloLocale.zh => '已到账',
      };

  String get homeNewClaim => switch (locale) {
        ReloLocale.ko => '새 환불 신청',
        ReloLocale.en => 'New claim',
        ReloLocale.ja => '新しい返金申請',
        ReloLocale.zh => '新的退款申请',
      };

  String get homeTodo => switch (locale) {
        ReloLocale.ko => '지금 할 일',
        ReloLocale.en => 'To do now',
        ReloLocale.ja => '今やること',
        ReloLocale.zh => '现在要做的',
      };

  /// 입력칸 위 고르는 말. 짧게 보여 주고, 물을 때는 assistantStarters의 온전한 문장을 보낸다.
  String get homeAskStatus => switch (locale) {
        ReloLocale.ko => '어디까지 왔어?',
        ReloLocale.en => 'Where is it now?',
        ReloLocale.ja => '今どこまで？',
        ReloLocale.zh => '到哪一步了？',
      };

  // ── 처음 화면 (환불 건이 하나도 없을 때) ──────────────────────────────

  String get homeFirstTitle => switch (locale) {
        ReloLocale.ko => '무슨 일이 있었어요?',
        ReloLocale.en => 'What went wrong?',
        ReloLocale.ja => '何がありましたか？',
        ReloLocale.zh => '遇到了什么问题？',
      };

  String get homeFirstSub => switch (locale) {
        ReloLocale.ko => '하나만 고르면 환불 신청을 바로 시작해요',
        ReloLocale.en => 'Pick one and we will start your refund claim',
        ReloLocale.ja => '一つ選ぶと、すぐに返金申請を始めます',
        ReloLocale.zh => '选一个，马上开始退款申请',
      };

  /// 고르는 세 가지. label은 화면에 보이는 말, issue는 신청 화면의 "무슨 문제인지" 칸에
  /// 미리 채워 두는 문장(사용자가 고칠 수 있다).
  List<({String label, String issue})> get homeFirstOptions => switch (locale) {
        ReloLocale.ko => const [
            (
              label: '물건이 안 왔어요',
              issue: '배송 완료로 표시되었지만 실제로 택배를 받지 못했습니다.',
            ),
            (
              label: '다른 물건이 왔거나 망가졌어요',
              issue: '주문한 것과 다른 상품이 왔거나 망가진 상태로 도착했습니다.',
            ),
            (
              label: '환불해 준다더니 돈이 안 들어와요',
              issue: '판매자가 환불을 약속했지만 아직 입금되지 않았습니다.',
            ),
          ],
        ReloLocale.ja => const [
            (
              label: '商品が届きません',
              issue: 'The order is marked as delivered, but I never received it.',
            ),
            (
              label: '違う商品が届いた・壊れていた',
              issue: 'I received a different item, or it arrived damaged.',
            ),
            (
              label: '返金すると言われたのに入金がない',
              issue: 'The seller promised a refund, but I have not received it.',
            ),
          ],
        ReloLocale.zh => const [
            (
              label: '没收到货',
              issue: 'The order is marked as delivered, but I never received it.',
            ),
            (
              label: '发错货或商品损坏',
              issue: 'I received a different item, or it arrived damaged.',
            ),
            (
              label: '说好退款却没到账',
              issue: 'The seller promised a refund, but I have not received it.',
            ),
          ],
        ReloLocale.en => const [
            (
              label: 'My order never arrived',
              issue: 'The order is marked as delivered, but I never received it.',
            ),
            (
              label: 'Wrong or damaged item',
              issue: 'I received a different item, or it arrived damaged.',
            ),
            (
              label: 'Refund promised but not paid',
              issue: 'The seller promised a refund, but I have not received it.',
            ),
          ],
      };

  String get homeFirstReceipt => switch (locale) {
        ReloLocale.ko => '영수증으로 시작하기',
        ReloLocale.en => 'Start from a receipt',
        ReloLocale.ja => '領収書から始める',
        ReloLocale.zh => '用收据开始',
      };

  // ── 내 환불 ─────────────────────────────────────────────────────────

  String get claimsAsk => switch (locale) {
        ReloLocale.ko => 'ReLo에게 물어보기',
        ReloLocale.en => 'Ask ReLo',
        ReloLocale.ja => 'ReLoに聞く',
        ReloLocale.zh => '问问 ReLo',
      };

  /// 내 환불 맨 위, 말랑이의 한 줄 요약
  String claimsSummary(int inFlight, int replied) => switch (locale) {
        ReloLocale.ko => inFlight == 0
            ? '지금 진행 중인 환불은 없어요.'
            : replied > 0
                ? '$inFlight건이 진행 중이에요. $replied건은 답장이 와 있어요.'
                : '$inFlight건이 진행 중이에요.',
        ReloLocale.ja => inFlight == 0
            ? '進行中の返金はありません。'
            : replied > 0
                ? '$inFlight件が進行中です。$replied件は返信が届いています。'
                : '$inFlight件が進行中です。',
        ReloLocale.zh => inFlight == 0
            ? '目前没有进行中的退款。'
            : replied > 0
                ? '$inFlight笔正在进行，其中$replied笔已有回复。'
                : '$inFlight笔正在进行。',
        ReloLocale.en => inFlight == 0
            ? 'No refunds in progress.'
            : replied > 0
                ? '$inFlight in progress. $replied ${replied == 1 ? 'has' : 'have'} a reply waiting.'
                : '$inFlight in progress.',
      };

  String get homeIdle => switch (locale) {
        ReloLocale.ko => '지금 진행 중인 환불은 없어요. 새로 돌려받을 게 생기면 말해 주세요.',
        ReloLocale.en =>
          'No refunds in progress. Tell me when there is something to get back.',
        ReloLocale.ja => '進行中の返金はありません。返金が必要になったら教えてください。',
        ReloLocale.zh => '目前没有进行中的退款。有需要退款的订单时告诉我。',
      };

  /// 네 언어를 한 줄로 적는다 (한국어 · 영어 · 일본어 · 중국어 순서)
  String _t(String ko, String en, String ja, String zh) => switch (locale) {
        ReloLocale.ko => ko,
        ReloLocale.en => en,
        ReloLocale.ja => ja,
        ReloLocale.zh => zh,
      };

  // ── 서버 연결 상태 (상단 바 아래 한 줄) ──
  String get connConnecting => _t('서버에 연결하는 중…', 'Connecting to the server…', 'サーバーに接続中…', '正在连接服务器…');
  String get connOffline => _t(
        '서버에 연결되지 않았어요. 체험 데이터를 보고 있어요',
        'Not connected. You are viewing sample data',
        'サーバーに接続できません。サンプルデータを表示中',
        '未连接服务器，正在显示示例数据',
      );
  String get connRetry => _t('다시 연결', 'Retry', '再接続', '重新连接');

  // ── 화면 문구 (상세 · 신청 · 설정 · 로그인 · 약관 · 내 환불) ──
  String get cmSaving => _t(
        '저장하는 중…',
        'Saving…',
        '保存中…',
        '正在保存…',
      );
  String get cmSave => _t(
        '저장하기',
        'Save',
        '保存する',
        '保存',
      );
  String get cmCopy => _t(
        '복사하기',
        'Copy',
        'コピー',
        '复制',
      );
  String get cmClose => _t(
        '닫기',
        'Close',
        '閉じる',
        '关闭',
      );
  String get cmConsent => _t(
        '동의',
        'Consent',
        '同意',
        '同意事项',
      );
  String get cmErrAmount => _t(
        '0보다 큰 금액을 숫자로 적어 주세요.',
        'Enter an amount greater than 0.',
        '0より大きい金額を数字で入力してください。',
        '请输入大于 0 的金额。',
      );
  String get cmOrderNo => _t(
        '주문번호',
        'Order number',
        '注文番号',
        '订单号',
      );
  String get cmAddressMasked => _t(
        '주소 가려짐',
        'Address hidden',
        '住所は非表示',
        '地址已隐藏',
      );
  String get cmRequired => _t(
        '필수',
        'Required',
        '必須',
        '必填',
      );
  String get cmOptional => _t(
        '선택',
        'Optional',
        '任意',
        '可选',
      );
  String get cmView => _t(
        '보기',
        'View',
        '見る',
        '查看',
      );
  String get cmToday => _t(
        '오늘',
        'Today',
        '今日',
        '今天',
      );
  String get csSend => _t(
        '메시지 보낼 차례',
        'Send your message',
        'メッセージを送る番',
        '该发送消息了',
      );
  String get csWaiting => _t(
        '답장 기다리는 중',
        'Waiting for a reply',
        '返信待ち',
        '等待回复',
      );
  String get csCheckOffer => _t(
        '제안 확인할 차례',
        'Check the offer',
        '提案を確認する番',
        '该确认方案了',
      );
  String get csNegotiating => _t(
        '조건 정하는 중',
        'Working out terms',
        '条件を調整中',
        '正在协商条件',
      );
  String get csReceived => _t(
        '입금 확인',
        'Refund received',
        '入金確認済み',
        '已到账',
      );
  String get dTabMessage => _t(
        '메시지',
        'Message',
        'メッセージ',
        '消息',
      );
  String get dTabReply => _t(
        '답장',
        'Reply',
        '返信',
        '回复',
      );
  String get dTabDeposit => _t(
        '입금',
        'Deposit',
        '入金',
        '到账',
      );
  String get dTabHistory => _t(
        '기록',
        'History',
        '履歴',
        '记录',
      );
  String get dNoteDefault => _t(
        '쇼핑몰 고객센터 채팅/이메일로 전송 완료',
        'Sent via the store\'s support chat / email',
        'ショップのサポートチャット／メールで送信済み',
        '已通过商家客服聊天/邮件发送',
      );
  String get dErrDraft => _t(
        '보낼 메시지를 먼저 적어 주세요.',
        'Write the message first.',
        '先に送るメッセージを入力してください。',
        '请先填写要发送的消息。',
      );
  String get dToastSent => _t(
        '저장했어요. 이제 답장을 기다리면 돼요.',
        'Saved. Now wait for the reply.',
        '保存しました。あとは返信を待つだけです。',
        '已保存，接下来等待回复即可。',
      );
  String get dErrReply => _t(
        '판매자가 보낸 답장을 붙여 넣어 주세요.',
        'Paste the seller\'s reply.',
        '販売者からの返信を貼り付けてください。',
        '请粘贴卖家的回复。',
      );
  String get dToastReplySaved => _t(
        '답장과 약속한 금액을 저장했어요.',
        'Saved the reply and the promised amount.',
        '返信と約束された金額を保存しました。',
        '已保存回复和承诺金额。',
      );
  String get dErrDate => _t(
        '확인한 날을 골라 주세요.',
        'Pick the date you confirmed it.',
        '確認した日を選んでください。',
        '请选择确认日期。',
      );
  String get dToastDeposit => _t(
        '들어온 돈을 기록했어요.',
        'Recorded the money received.',
        '入金を記録しました。',
        '已记录到账金额。',
      );
  String get dToastFileAdded => _t(
        '파일을 추가했어요.',
        'File added.',
        'ファイルを追加しました。',
        '已添加文件。',
      );
  String get dToastDone => _t(
        '끝난 건으로 표시했어요.',
        'Marked as finished.',
        '完了として表示しました。',
        '已标记为完成。',
      );
  String get dToastRestored => _t(
        '휴지통에서 꺼냈어요.',
        'Restored from trash.',
        'ゴミ箱から戻しました。',
        '已从回收站恢复。',
      );
  String get dToastTrashed => _t(
        '휴지통으로 옮겼어요.',
        'Moved to trash.',
        'ゴミ箱に移動しました。',
        '已移到回收站。',
      );
  String get dNotFound => _t(
        '이 환불 건을 찾을 수 없어요',
        'This refund could not be found',
        'この返金が見つかりません',
        '找不到这笔退款',
      );
  String get dBackToClaims => _t(
        '내 환불로 돌아가기',
        'Back to My Claims',
        'マイ返金に戻る',
        '返回我的退款',
      );
  String get dBackTooltip => _t(
        '내 환불 목록',
        'My Claims',
        'マイ返金',
        '我的退款',
      );
  String get dMore => _t(
        '더 보기',
        'More',
        'その他',
        '更多',
      );
  String get dMenuDone => _t(
        '끝난 건으로 표시',
        'Mark as finished',
        '完了として表示',
        '标记为完成',
      );
  String get dMenuRestore => _t(
        '휴지통에서 꺼내기',
        'Restore from trash',
        'ゴミ箱から戻す',
        '从回收站恢复',
      );
  String get dMenuTrash => _t(
        '휴지통으로 옮기기',
        'Move to trash',
        'ゴミ箱に移動',
        '移到回收站',
      );
  String get dAllDone => _t(
        '모두 끝났어요',
        'All done',
        'すべて完了',
        '全部完成',
      );
  String get dAgreedMoney => _t(
        '받기로 한 돈',
        'Promised',
        '受け取る予定',
        '承诺退款',
      );
  String get dClaimedMoney => _t(
        '요청한 돈',
        'Requested',
        '請求額',
        '申请金额',
      );
  String get dProgressLabel => _t(
        '약속과 입금 진행',
        'Promised and received progress',
        '約束と入金の進み具合',
        '承诺与到账进度',
      );
  String get dMsgTitle => _t(
        '판매자에게 보낼 메시지',
        'Message to the seller',
        '販売者に送るメッセージ',
        '给卖家的消息',
      );
  String get dAiWriting => _t(
        '쓰는 중…',
        'Writing…',
        '作成中…',
        '正在撰写…',
      );
  String get dAiWrite => _t(
        'AI로 쓰기',
        'Write with AI',
        'AIで作成',
        '用 AI 撰写',
      );
  String get dMsgField => _t(
        '보낼 메시지',
        'Message',
        '送るメッセージ',
        '要发送的消息',
      );
  String get dMsgHint => _t(
        'AI로 쓰기를 누르면 판매자 나라 말로 써 드려요',
        'Tap Write with AI to draft it in the seller\'s language',
        '「AIで作成」を押すと販売者の言語で作成します',
        '点击“用 AI 撰写”，用卖家的语言帮你写',
      );
  String get dNoteLabel => _t(
        '어디로 보냈는지 (선택)',
        'Where you sent it (optional)',
        '送信先（任意）',
        '发送到哪里（可选）',
      );
  String get dToastCopied => _t(
        '메시지를 복사했어요.',
        'Message copied.',
        'メッセージをコピーしました。',
        '已复制消息。',
      );
  String get dSent => _t(
        '보냈어요',
        'I sent it',
        '送信しました',
        '我已发送',
      );
  String get dMsgCaption => _t(
        'ReLo가 대신 보내지는 않아요. 복사해서 쇼핑몰에 보낸 다음 "보냈어요"를 눌러 주세요.',
        'ReLo does not send it for you. Copy it, send it to the store, then tap “I sent it”.',
        'ReLoが代わりに送ることはありません。コピーしてショップに送ってから「送信しました」を押してください。',
        'ReLo 不会替你发送。请复制后发给商家，再点击“我已发送”。',
      );
  String get dReplyTitle => _t(
        '판매자 답장',
        'Seller\'s reply',
        '販売者の返信',
        '卖家回复',
      );
  String get dAiReading => _t(
        '읽는 중…',
        'Reading…',
        '読み取り中…',
        '正在读取…',
      );
  String get dAiSummary => _t(
        'AI로 요약',
        'Summarize with AI',
        'AIで要約',
        '用 AI 总结',
      );
  String get dReplyField => _t(
        '답장 원문',
        'Original reply',
        '返信の原文',
        '回复原文',
      );
  String get dReplyHint => _t(
        '판매자가 보낸 답장을 붙여 넣어 주세요',
        'Paste the reply from the seller',
        '販売者からの返信を貼り付けてください',
        '请粘贴卖家的回复',
      );
  String get dReplyKind => _t(
        '어떤 답장이에요?',
        'What kind of reply is it?',
        'どんな返信ですか？',
        '这是哪种回复？',
      );
  String get dBannerTitle => _t(
        '돈이 돌아왔어요',
        'Your money is back',
        'お金が戻りました',
        '钱回来了',
      );
  String get dBannerSub => _t(
        '들어온 금액을 기록했어요.',
        'The amount received has been recorded.',
        '入金額を記録しました。',
        '已记录到账金额。',
      );
  String get dDepositTitle => _t(
        '들어온 돈 기록',
        'Record money received',
        '入金を記録',
        '记录到账',
      );
  String get dDateField => _t(
        '확인한 날',
        'Date confirmed',
        '確認した日',
        '确认日期',
      );
  String get dRefField => _t(
        '승인번호 · 메모',
        'Reference no. · note',
        '承認番号・メモ',
        '授权号 · 备注',
      );
  String get dCardCaption => _t(
        '카드 전체 번호는 적지 마세요. 취소 금액과 승인번호만 기록해요.',
        'Do not enter your full card number. Only the refunded amount and reference number are recorded.',
        'カード番号の全桁は入力しないでください。取消金額と承認番号だけを記録します。',
        '请不要填写完整卡号，只记录退款金额和授权号。',
      );
  String get dRecording => _t(
        '기록하는 중…',
        'Recording…',
        '記録中…',
        '正在记录…',
      );
  String get dRecord => _t(
        '입금 기록하기',
        'Record deposit',
        '入金を記録する',
        '记录到账',
      );
  String get dFilesCaption => _t(
        '10MB까지 올릴 수 있고, 내 계정에서만 볼 수 있어요.',
        'Up to 10 MB each. Only visible in your account.',
        '10MBまでアップロードでき、自分のアカウントでのみ表示されます。',
        '最大 10MB，仅在你的账户中可见。',
      );
  String get dNoFiles => _t(
        '아직 올린 파일이 없어요.',
        'No files yet.',
        'まだファイルがありません。',
        '还没有上传文件。',
      );
  String get dFileUsed => _t(
        '입금 증빙으로 씀',
        'Used as deposit proof',
        '入金の証拠に使用',
        '已用作到账凭证',
      );
  String get dFileKept => _t(
        '보관 중',
        'Stored',
        '保管中',
        '保存中',
      );
  String get dDeleteFile => _t(
        '파일 지우기',
        'Delete file',
        'ファイルを削除',
        '删除文件',
      );
  String get dAddFile => _t(
        '영수증 · 사진 추가',
        'Add receipt · photo',
        '領収書・写真を追加',
        '添加收据 · 照片',
      );
  String get dHistoryTitle => _t(
        '지금까지 한 일',
        'What has happened so far',
        'これまでの記録',
        '到目前为止的记录',
      );
  String get dNoHistory => _t(
        '아직 기록이 없어요.',
        'No history yet.',
        'まだ記録がありません。',
        '还没有记录。',
      );
  String get wStep1 => _t(
        '어디서 샀어요?',
        'Where did you buy it?',
        'どこで買いましたか？',
        '在哪里买的？',
      );
  String get wStep2 => _t(
        '어떤 상품이에요?',
        'Which item is it?',
        'どの商品ですか？',
        '是哪件商品？',
      );
  String get wStep3 => _t(
        '어떻게 해결할까요?',
        'How should it be resolved?',
        'どう解決しますか？',
        '希望怎么解决？',
      );
  String get wStep4 => _t(
        '영수증이나 사진이 있어요?',
        'Do you have a receipt or photos?',
        '領収書や写真はありますか？',
        '有收据或照片吗？',
      );
  String get wStep5 => _t(
        '마지막으로 확인해요',
        'One last check',
        '最後に確認します',
        '最后确认一下',
      );
  String get wIssueBroken => _t(
        '깨져서 왔어요',
        'It arrived broken',
        '壊れて届いた',
        '到货时已损坏',
      );
  String get wIssueBrokenText => _t(
        '택배 상자를 열었을 때 겉상자와 상품 외관이 깨진 상태로 도착했습니다.',
        'When I opened the parcel, the outer box and the item itself had arrived damaged.',
        '荷物を開けたところ、外箱と商品の外観が破損した状態で届きました。',
        '打开包裹时，外箱和商品外观已经破损。',
      );
  String get wIssueWrong => _t(
        '다른 물건이 왔어요',
        'Wrong item',
        '違う商品が届いた',
        '发错了商品',
      );
  String get wIssueWrongText => _t(
        '주문한 옵션과 다른 색상·모델의 상품이 잘못 배송되었습니다.',
        'I received an item in a different color or model from the option I ordered.',
        '注文したオプションと異なる色・モデルの商品が届きました。',
        '收到的商品颜色或型号与我订购的选项不符。',
      );
  String get wIssueDead => _t(
        '작동이 안 돼요',
        'It does not work',
        '動作しない',
        '无法使用',
      );
  String get wIssueDeadText => _t(
        '전원을 연결해도 켜지지 않는 작동 불량 상품입니다.',
        'The item is defective and does not turn on even when connected to power.',
        '電源を接続しても起動しない不良品です。',
        '商品有故障，接通电源后也无法开机。',
      );
  String get wIssueMissing => _t(
        '물건이 안 왔어요',
        'It never arrived',
        '届いていない',
        '没有收到',
      );
  String get wIssueMissingText => _t(
        '배송 완료로 표시되었지만 실제로 택배를 받지 못했습니다.',
        'It is marked as delivered, but I never actually received the parcel.',
        '配達完了と表示されていますが、実際には荷物を受け取っていません。',
        '显示已签收，但我实际没有收到包裹。',
      );
  String get wKindRefund => _t(
        '반품 · 환불',
        'Return and refund',
        '返品・返金',
        '退货退款',
      );
  String get wKindExchange => _t(
        '새 상품 교환',
        'Replacement',
        '新品と交換',
        '换新',
      );
  String get wKindRepair => _t(
        '무상 수리 · 부품',
        'Free repair or parts',
        '無償修理・部品',
        '免费维修或配件',
      );
  String get wSampleAmazon => _t(
        'Amazon US 영수증',
        'Amazon US receipt',
        'Amazon US の領収書',
        'Amazon US 收据',
      );
  String get wSampleAli => _t(
        'AliExpress 주문서',
        'AliExpress order slip',
        'AliExpress の注文書',
        'AliExpress 订单',
      );
  String get wSampleMercari => _t(
        'Mercari JP 영수증',
        'Mercari JP receipt',
        'Mercari JP の領収書',
        'Mercari JP 收据',
      );
  String get wSampleTitle => _t(
        '샘플 영수증으로 해 보기',
        'Try with a sample receipt',
        'サンプルの領収書で試す',
        '用示例收据试试',
      );
  String get wSampleFilled => _t(
        '샘플 영수증의 예시 값으로 채웠어요. AI가 읽은 값이 아니에요.',
        'Filled in with the sample receipt\'s example values. The AI did not read these.',
        'サンプルの領収書の例の値で入力しました。AIが読み取った値ではありません。',
        '已用示例收据的示例值填写。这不是 AI 读取的内容。',
      );
  String get wTranslateSkip => _t(
        '영어로 직접 적거나 비워 두어도 돼요.',
        'You can write it in English yourself or leave it empty.',
        '英語で直接入力するか、空のままでも大丈夫です。',
        '可以自己用英语填写，也可以留空。',
      );

  // ── AI가 답하지 못했을 때 (지어낸 답 대신 까닭을 말한다) ──
  String get aiOff => _t(
        'AI 도우미가 꺼져 있어요. 설정에서 켤 수 있어요.',
        'The AI helper is off. You can turn it on in Settings.',
        'AIアシスタントがオフです。設定からオンにできます。',
        'AI 助手已关闭，可以在设置里开启。',
      );
  String get aiNoServer => _t(
        '서버에 연결되지 않아 AI를 쓸 수 없어요.',
        'The AI is not available because the server is not connected.',
        'サーバーに接続されていないため、AIを使えません。',
        '未连接服务器，无法使用 AI。',
      );
  String get aiFailed => _t(
        'AI가 지금은 답하지 못했어요. 잠시 뒤 다시 해 주세요.',
        'The AI could not answer just now. Please try again shortly.',
        'AIが今は答えられませんでした。少ししてからもう一度お試しください。',
        'AI 暂时没能回答，请稍后再试。',
      );
  String get dDraftByTemplate => _t(
        '그래서 AI가 쓴 글 대신 기본 틀로 채웠어요. 문제 설명을 확인해 주세요.',
        'So this is the basic template, not written by the AI. Please check the problem description.',
        'そのため、AIの文章ではなく基本のひな形を入れました。問題の説明を確認してください。',
        '所以填入的是基本模板，不是 AI 写的。请检查问题说明。',
      );
  String get dReplySaveAnyway => _t(
        '답장은 직접 읽고 그대로 저장할 수 있어요.',
        'You can still read the reply yourself and save it as it is.',
        '返信は自分で読んで、そのまま保存できます。',
        '你仍然可以自己阅读回复并照原样保存。',
      );
  String get wSampleNote => _t(
        '예시 영수증으로 채워지는 모습을 볼 수 있어요.',
        'See how a sample receipt fills in the form.',
        'サンプルの領収書で入力される様子を確認できます。',
        '可以用示例收据看看自动填写的效果。',
      );
  String get wErrIssueFirst => _t(
        '먼저 어떤 문제가 있었는지 5자 이상 적어 주세요.',
        'First describe the problem in at least 5 characters.',
        'まず問題の内容を5文字以上で入力してください。',
        '请先用至少 5 个字描述问题。',
      );
  String get wErrVendor => _t(
        '쇼핑몰 이름을 적어 주세요.',
        'Enter the store name.',
        'ショップ名を入力してください。',
        '请填写商家名称。',
      );
  String get wErrVendorPick => _t(
        '쇼핑몰을 골라 주세요.',
        'Choose a store.',
        'ショップを選んでください。',
        '请选择商家。',
      );
  String get wSumFilesNone => _t(
        '없음',
        'None',
        'なし',
        '无',
      );
  String get wErrOrderRef => _t(
        '주문번호를 적어 주세요.',
        'Enter the order number.',
        '注文番号を入力してください。',
        '请填写订单号。',
      );
  String get wErrTitle => _t(
        '상품 이름을 적어 주세요.',
        'Enter the item name.',
        '商品名を入力してください。',
        '请填写商品名称。',
      );
  String get wErrQtyMin => _t(
        '1개 이상이어야 해요.',
        'Must be at least 1.',
        '1個以上にしてください。',
        '至少为 1。',
      );
  String get wErrQtyMax => _t(
        '주문한 수량보다 많을 수 없어요.',
        'Cannot be more than the quantity ordered.',
        '注文数量より多くはできません。',
        '不能超过订购数量。',
      );
  String get wErrIssue => _t(
        '어떤 문제가 있었는지 5자 이상 적어 주세요.',
        'Describe the problem in at least 5 characters.',
        '問題の内容を5文字以上で入力してください。',
        '请用至少 5 个字描述问题。',
      );
  String get wErrConsent => _t(
        '필수 동의 두 가지를 체크해 주세요.',
        'Check both required consents.',
        '必須の同意2つにチェックしてください。',
        '请勾选两项必填同意。',
      );
  String get wPrevStep => _t(
        '이전 단계',
        'Previous step',
        '前のステップ',
        '上一步',
      );
  String get wToHome => _t(
        '홈으로',
        'Home',
        'ホームへ',
        '返回首页',
      );
  String get wNext => _t(
        '다음',
        'Next',
        '次へ',
        '下一步',
      );
  String get wSubmitting => _t(
        '등록 중…',
        'Submitting…',
        '登録中…',
        '正在提交…',
      );
  String get wSubmit => _t(
        '환불 신청 등록하기',
        'Submit refund request',
        '返金申請を登録する',
        '提交退款申请',
      );
  String get wGlobeHub => _t(
        '서울 · 내 계좌로',
        'Seoul · to my account',
        'ソウル · 自分の口座へ',
        '首尔 · 到我的账户',
      );
  String get wGoMessage => _t(
        '판매자 메시지 보내러 가기',
        'Go send the seller a message',
        '販売者にメッセージを送る',
        '去给卖家发消息',
      );
  String get wViewClaims => _t(
        '내 환불 보기',
        'View My Claims',
        'マイ返金を見る',
        '查看我的退款',
      );
  String get wOrPick => _t(
        '또는 직접 고르기',
        'Or choose yourself',
        'または自分で選ぶ',
        '或自己选择',
      );
  String get wCustomVendor => _t(
        '직접 입력',
        'Other',
        '直接入力',
        '手动输入',
      );
  String get wVendorName => _t(
        '쇼핑몰 이름',
        'Store name',
        'ショップ名',
        '商家名称',
      );
  String get wVendorHint => _t(
        '예: Coupang Global, eBay',
        'e.g. Coupang Global, eBay',
        '例: Coupang Global, eBay',
        '例如：Coupang Global、eBay',
      );
  String get wOrderHint => _t(
        '예: 114-8920411-33012',
        'e.g. 114-8920411-33012',
        '例: 114-8920411-33012',
        '例如：114-8920411-33012',
      );
  String get wOrderDate => _t(
        '주문일',
        'Order date',
        '注文日',
        '下单日期',
      );
  String get wPrivacyLine => _t(
        '주민번호·통관번호·카드번호는 받지 않아요',
        'We never ask for ID, customs or card numbers',
        '住民番号・通関番号・カード番号は収集しません',
        '我们不收集身份证号、通关号和卡号',
      );
  String get wItemName => _t(
        '문제가 생긴 상품 이름',
        'Name of the item with the problem',
        '問題のある商品名',
        '出问题的商品名称',
      );
  String get wItemHint => _t(
        '예: 무선 노이즈캔슬링 헤드폰 블랙',
        'e.g. Wireless noise-cancelling headphones, black',
        '例: ワイヤレスノイズキャンセリングヘッドホン 黒',
        '例如：无线降噪耳机 黑色',
      );
  String get wQtyOrdered => _t(
        '주문한 수량',
        'Quantity ordered',
        '注文数量',
        '订购数量',
      );
  String get wQtyProblem => _t(
        '문제가 생긴 수량',
        'Quantity affected',
        '問題のある数量',
        '出问题的数量',
      );
  String get wCurrency => _t(
        '결제한 통화',
        'Currency paid',
        '支払い通貨',
        '支付货币',
      );
  String get wAmountHint => _t(
        '예: 289.00',
        'e.g. 289.00',
        '例: 289.00',
        '例如：289.00',
      );
  String get wResolution => _t(
        '원하는 해결 방법',
        'How you want it resolved',
        '希望する解決方法',
        '希望的解决方式',
      );
  String get wWhatProblem => _t(
        '무슨 문제가 있었어요?',
        'What went wrong?',
        'どんな問題がありましたか？',
        '出了什么问题？',
      );
  String get wDetail => _t(
        '자세한 설명',
        'Details',
        '詳しい説明',
        '详细说明',
      );
  String get wSellerDesc => _t(
        '판매자에게 보낼 설명',
        'Description for the seller',
        '販売者に送る説明',
        '发给卖家的说明',
      );
  String get wTranslating => _t(
        '번역하는 중…',
        'Translating…',
        '翻訳中…',
        '正在翻译…',
      );
  String get wTranslate => _t(
        'AI로 번역',
        'Translate with AI',
        'AIで翻訳',
        '用 AI 翻译',
      );
  String get wEnglishDesc => _t(
        '영어로 쓴 설명',
        'Description in English',
        '英語での説明',
        '英文说明',
      );
  String get wMaskNote => _t(
        '집 주소나 전화번호가 보이면 가린 뒤에 올려 주세요.',
        'If your home address or phone number is visible, cover it before adding.',
        '住所や電話番号が写っている場合は、隠してから追加してください。',
        '如果能看到住址或电话，请先遮住再添加。',
      );
  String get wAddressCheck => _t(
        '주소 확인 필요',
        'Check the address',
        '住所の確認が必要',
        '需确认地址',
      );
  String get wRemoveFile => _t(
        '파일 빼기',
        'Remove file',
        'ファイルを外す',
        '移除文件',
      );
  String get wAddFile => _t(
        '사진 · 영수증 추가',
        'Add photo · receipt',
        '写真・領収書を追加',
        '添加照片 · 收据',
      );
  String get wFileLimit => _t(
        '파일 하나에 10MB까지 올릴 수 있어요.',
        'Up to 10 MB per file.',
        '1ファイル10MBまでアップロードできます。',
        '每个文件最大 10MB。',
      );
  String get wSumVendor => _t(
        '쇼핑몰',
        'Store',
        'ショップ',
        '商家',
      );
  String get wSumItem => _t(
        '상품',
        'Item',
        '商品',
        '商品',
      );
  String get wSumAmount => _t(
        '요청 금액',
        'Amount requested',
        '請求金額',
        '申请金额',
      );
  String get wSumFiles => _t(
        '첨부',
        'Attachments',
        '添付',
        '附件',
      );
  String get wSumFee => _t(
        '수수료 · 성공보수',
        'Fee · success fee',
        '手数料・成功報酬',
        '手续费 · 成功酬金',
      );
  String get wFree => _t(
        '0원',
        'Free',
        '無料',
        '免费',
      );
  String get wConsent1Title => _t(
        '환불 내역과 증빙 사진 보관에 동의해요',
        'I agree to store my refund records and evidence photos',
        '返金履歴と証拠写真の保管に同意します',
        '我同意保存退款记录和凭证照片',
      );
  String get wConsent1Sub => _t(
        '내 보관함에만 두고, 언제든 바로 지울 수 있어요.',
        'They are kept in your vault only, and you can delete them at any time.',
        '自分の保管庫にのみ保存し、いつでもすぐに削除できます。',
        '仅保存在你的保管箱中，可随时删除。',
      );
  String get wConsent2Title => _t(
        '실제로 산 물건이고 사실대로 적었어요',
        'This is a real purchase and what I wrote is true',
        '実際に購入した商品で、事実どおりに記入しました',
        '这是真实购买，所填内容属实',
      );
  String get wConsent2Sub => _t(
        '거짓 신고가 아님을 확인하고 이용약관에 동의해요.',
        'I confirm this is not a false claim and I agree to the Terms of Service.',
        '虚偽の申告ではないことを確認し、利用規約に同意します。',
        '我确认并非虚假申报，并同意服务条款。',
      );
  String get stBackupTitle => _t(
        '내 환불 기록 백업',
        'Back up my refund records',
        '返金記録のバックアップ',
        '备份我的退款记录',
      );
  String get stBackupCopied => _t(
        '백업 내용을 복사했어요.',
        'Backup copied.',
        'バックアップをコピーしました。',
        '已复制备份内容。',
      );
  String get stSectionScreen => _t(
        '화면',
        'Display',
        '画面',
        '显示',
      );
  String get stDark => _t(
        '어두운 화면',
        'Dark mode',
        'ダークモード',
        '深色模式',
      );
  String get stContrast => _t(
        '고대비 모드',
        'High contrast',
        'ハイコントラスト',
        '高对比度',
      );
  String get stContrastSub => _t(
        '글자와 배경의 차이를 더 크게 하고, 키보드 포커스를 노란색으로 표시해요',
        'Increases the contrast between text and background and shows keyboard focus in yellow',
        '文字と背景のコントラストを強め、キーボードフォーカスを黄色で表示します',
        '增大文字与背景的对比度，并用黄色显示键盘焦点',
      );
  String get stHelper => _t(
        '도우미 캐릭터 띄우기',
        'Show the floating helper',
        'ヘルパーキャラクターを表示',
        '显示悬浮助手',
      );
  String get stHelperSub => _t(
        '설정과 약관 화면에 떠 있는 말랑이예요. 꺼도 홈과 내 환불에서 물어볼 수 있어요',
        'The helper that floats on Settings and Legal. You can still ask from Home and My Claims when it is off',
        '設定と規約の画面に浮かぶヘルパーです。オフにしてもホームとマイ返金から質問できます',
        '在设置和条款页面悬浮的助手。关闭后仍可在首页和我的退款中提问',
      );
  String get stLanguage => _t(
        '언어',
        'Language',
        '言語',
        '语言',
      );
  String get stSectionMe => _t(
        '내 정보',
        'My info',
        'マイ情報',
        '我的信息',
      );
  String get stAi => _t(
        'AI 기능 쓰기',
        'Use AI features',
        'AI機能を使う',
        '使用 AI 功能',
      );
  String get stAiSub => _t(
        '영수증 읽기와 번역에 써요. 끄면 영수증과 사유를 AI 서버로 보내지 않아요',
        'Used for reading receipts and translating. When off, receipts and reasons are not sent to the AI server',
        '領収書の読み取りと翻訳に使います。オフにすると領収書と理由をAIサーバーに送信しません',
        '用于读取收据和翻译。关闭后不会把收据和原因发送到 AI 服务器',
      );
  String get stEmail => _t(
        '알림 메일 받기',
        'Notice emails',
        'お知らせメールを受け取る',
        '接收提醒邮件',
      );
  String get stEmailOff => _t(
        '꺼져 있어요. AI가 허락을 기다려도 메일을 보내지 않아요',
        'Off. No email is sent when the AI is waiting for your OK',
        'オフです。AIが許可を待っていてもメールは送りません',
        '已关闭。AI 等你同意时也不会发邮件',
      );
  String get stEmailOn => _t(
        'AI가 허락을 기다리는데 한동안 답이 없으면 인증한 이메일로 한 번 알려 드려요. 메일에는 주문 내용을 적지 않아요',
        'If the AI is left waiting for your OK for a while, it emails you once at your verified address. The email says nothing about your order',
        'AIが許可を待ったまましばらくお返事がないときは、確認済みのメールアドレスに一度だけお知らせします。メールに注文の内容は書きません',
        '如果 AI 等你同意等了一段时间仍没有回答，会向你已验证的邮箱发一封提醒邮件。邮件里不写订单内容',
      );
  String get stEmailUnverified => _t(
        '이메일 인증 전이라 지금은 알림 메일을 보내지 않아요. 인증을 마치면, AI가 허락을 기다리는데 한동안 답이 없을 때 한 번 알려 드려요',
        'Your email address is not confirmed yet, so no notice email is sent for now. Once it is confirmed, the AI emails you once if it is left waiting for your OK for a while',
        'メールアドレスの確認がまだのため、今はお知らせメールを送りません。確認が済むと、AIが許可を待ったまましばらくお返事がないときに一度だけお知らせします',
        '邮箱还没有验证，所以现在不会发送提醒邮件。验证之后，如果 AI 等你同意等了一段时间仍没有回答，会发一封提醒邮件',
      );
  String get stEmailFail => _t(
        '알림 메일 설정을 바꾸지 못했어요. 잠시 후 다시 해 보세요.',
        'Could not change the notice email setting. Try again in a moment.',
        'お知らせメールの設定を変更できませんでした。しばらくしてからもう一度お試しください。',
        '没能更改提醒邮件设置。请稍后再试。',
      );
  String get lgMailFacts => _t(
        '광고 메일은 보내지 않아요. 보내는 메일은 세 가지예요: 가입할 때의 이메일 인증, 요청했을 때의 비밀번호 재설정, 그리고 [스스로 시작하기]를 켠 경우 AI가 허락을 기다린다는 알림. 알림 메일에는 주문 내용을 적지 않고, 설정의 [알림 메일 받기]로 끌 수 있어요. 끄는 방법은 메일에도 적혀 있어요.',
        'We send no advertising email. There are three kinds of email: confirming your address when you sign up, resetting your password when you ask, and, if "Let the AI start on its own" is on, a notice that the AI is waiting for your OK. The notice says nothing about your order, and you can turn it off under "Notice emails" in Settings. The email itself says how.',
        '広告メールは送りません。送るメールは3種類です: 登録時のメールアドレスの確認、依頼があったときのパスワード再設定、そして「AIが自分で始める」をオンにしている場合の、AIが許可を待っているというお知らせ。お知らせメールに注文の内容は書かず、設定の「お知らせメールを受け取る」でオフにできます。止め方はメールにも書いてあります。',
        '我们不发送广告邮件。发送的邮件只有三种：注册时的邮箱验证、你请求时的密码重置，以及在你打开“让 AI 自己开始”时，提醒你 AI 正在等你同意的邮件。提醒邮件里不写订单内容，可以在设置的“接收提醒邮件”中关闭。邮件里也写了关闭方法。',
      );
  String get stLegal => _t(
        '약관 · 개인정보 처리방침 · 정책',
        'Terms · privacy policy · policies',
        '利用規約・プライバシーポリシー・各種ポリシー',
        '条款 · 隐私政策 · 各项政策',
      );
  String get stLogout => _t(
        '로그아웃',
        'Log out',
        'ログアウト',
        '退出登录',
      );
  String get stDelete => _t(
        '회원 탈퇴 · 내 정보 모두 삭제',
        'Delete account · erase all my data',
        '退会・すべての情報を削除',
        '注销账户 · 删除我的全部信息',
      );
  String get auNameHint => _t(
        '김직구',
        'Alex Kim',
        '山田太郎',
        '王小明',
      );
  String get auErrName => _t(
        '이름이나 닉네임을 적어 주세요.',
        'Enter a name or nickname.',
        '名前またはニックネームを入力してください。',
        '请填写姓名或昵称。',
      );
  String get auErrEmail => _t(
        '이메일 주소를 다시 확인해 주세요.',
        'Check the email address.',
        'メールアドレスを確認してください。',
        '请检查邮箱地址。',
      );
  String get auErrPassword => _t(
        '비밀번호는 8자 이상이어야 해요.',
        'The password must be at least 8 characters.',
        'パスワードは8文字以上にしてください。',
        '密码至少需要 8 个字符。',
      );
  String get auErrConsent => _t(
        '필수 약관 동의 및 연령 확인 항목을 체크해 주세요.',
        'Check the required consents and the age confirmation.',
        '必須の同意と年齢確認にチェックしてください。',
        '请勾选必填同意项和年龄确认。',
      );
  String get auTitleSignup => _t(
        '내 환불 보관함 만들기',
        'Create my refund vault',
        '返金保管庫を作る',
        '创建我的退款保管箱',
      );
  String get auTitleLogin => _t(
        '내 환불 보관함 열기',
        'Open my refund vault',
        '返金保管庫を開く',
        '打开我的退款保管箱',
      );
  String get auNoCollect => _t(
        '주민등록번호·집 주소·카드 전체 번호는 받지 않아요.',
        'We never ask for your national ID, home address or full card number.',
        '住民登録番号・住所・カード番号の全桁は収集しません。',
        '我们不收集身份证号、家庭住址和完整卡号。',
      );
  String get auDemo => _t(
        '체험 계정으로 바로 시작',
        'Start with the demo account',
        '体験アカウントですぐ始める',
        '用体验账户立即开始',
      );
  String get auDemoSub => _t(
        '비밀번호 없이 샘플 환불 건으로 둘러봐요',
        'Look around with sample refunds, no password needed',
        'パスワードなしでサンプルの返金を見てみましょう',
        '无需密码，用示例退款先看看',
      );
  String get auName => _t(
        '이름 또는 닉네임 (실명이 아니어도 돼요)',
        'Name or nickname (a real name is not required)',
        '名前またはニックネーム（本名でなくても構いません）',
        '姓名或昵称（不必是真实姓名）',
      );
  String get auEmail => _t(
        '이메일 주소',
        'Email address',
        'メールアドレス',
        '邮箱地址',
      );
  String get auPassword => _t(
        '비밀번호',
        'Password',
        'パスワード',
        '密码',
      );
  String get auPasswordHint => _t(
        '8자 이상 비밀번호',
        'At least 8 characters',
        '8文字以上のパスワード',
        '至少 8 个字符',
      );
  String get auOptionalNote => _t(
        '선택 항목은 동의하지 않아도 가입할 수 있어요.',
        'You can sign up without agreeing to the optional items.',
        '任意の項目は同意しなくても登録できます。',
        '不同意可选项也可以注册。',
      );
  String get auC1 => _t(
        '개인정보 수집 및 이용 동의',
        'Consent to collection and use of personal information',
        '個人情報の収集・利用への同意',
        '同意收集和使用个人信息',
      );
  String get auC1Sub => _t(
        '수집항목: 이메일, 닉네임, 암호화 비밀번호 (탈퇴 시 즉시 파기)',
        'Collected: email, nickname, encrypted password (destroyed immediately when you leave)',
        '収集項目: メール、ニックネーム、暗号化パスワード（退会時に即時破棄）',
        '收集项目：邮箱、昵称、加密密码（注销时立即销毁）',
      );
  String get auC2 => _t(
        '서비스 이용약관 동의',
        'Agreement to the Terms of Service',
        '利用規約への同意',
        '同意服务条款',
      );
  String get auC2Sub => _t(
        '직구 환불 기록 및 외국어 초안 작성 도구 이용 기준',
        'Rules for using the refund-tracking and foreign-language drafting tools',
        '返金記録と外国語下書き作成ツールの利用基準',
        '退款记录和外语草稿工具的使用规则',
      );
  String get auC3 => _t(
        '만 14세 이상 본인입니다 (연령 확인)',
        'I am 14 or older (age confirmation)',
        '満14歳以上の本人です（年齢確認）',
        '本人已满 14 周岁（年龄确认）',
      );
  String get auC3Sub => _t(
        '개인정보보호법 제22조의2에 따른 필수 연령 확인 절차',
        'Required age check under Article 22-2 of the Personal Information Protection Act (Korea)',
        '個人情報保護法第22条の2に基づく必須の年齢確認',
        '依据韩国《个人信息保护法》第22条之2的必要年龄确认',
      );
  String get auBackToAdult => _t(
        '만 14세 이상 일반 가입으로 돌아가기',
        'Back to regular sign-up (14 or older)',
        '満14歳以上の通常登録に戻る',
        '返回满 14 周岁的普通注册',
      );
  String get auUnder14 => _t(
        '만 14세 미만이면 보호자 동의로 가입하기',
        'Under 14? Sign up with a guardian\'s consent',
        '満14歳未満の場合は保護者の同意で登録',
        '未满 14 周岁？经监护人同意后注册',
      );
  String get auGuardian => _t(
        '법정대리인(보호자) 성명 및 연락 이메일',
        'Legal guardian\'s name and contact email',
        '法定代理人（保護者）の氏名と連絡先メール',
        '法定代理人（监护人）姓名和联系邮箱',
      );
  String get auGuardianHint => _t(
        '예: 홍길동 (parent@example.com)',
        'e.g. Jane Doe (parent@example.com)',
        '例: 山田花子 (parent@example.com)',
        '例如：张三 (parent@example.com)',
      );
  String get auGuardianConsent => _t(
        '법정대리인 본인이 아동의 개인정보 수집·이용에 동의합니다.',
        'I, the legal guardian, consent to the collection and use of the child\'s personal information.',
        '法定代理人本人が、児童の個人情報の収集・利用に同意します。',
        '本人作为法定代理人，同意收集和使用该儿童的个人信息。',
      );
  String get auC4 => _t(
        'AI 영수증 자동 읽기 및 외국어 번역 도우미 사용 동의',
        'Consent to use AI receipt reading and translation help',
        'AIによる領収書の自動読み取りと翻訳サポートの利用に同意',
        '同意使用 AI 自动读取收据和翻译助手',
      );
  String get auC4Sub => _t(
        '주문 내용 · 붙여 넣은 답장 · 고른 영수증 파일이 해외의 Google AI로 보내져요. 동의하지 않아도 직접 적어서 다 쓸 수 있어요.',
        'Your order details, the reply you paste and the receipt file you choose are sent to Google\'s AI outside Korea. Without this, you can still enter everything yourself.',
        '注文内容・貼り付けた返信・選んだ領収書ファイルが海外のGoogleのAIへ送られます。同意しなくても、手入力ですべて利用できます。',
        '订单内容、粘贴的回复和所选的收据文件会发送到海外的 Google AI。不同意也可以手动填写，照常使用。',
      );
  String get auBusy => _t(
        '처리 중…',
        'Working…',
        '処理中…',
        '处理中…',
      );
  String get auSignup => _t(
        '동의하고 가입하기',
        'Agree and sign up',
        '同意して登録する',
        '同意并注册',
      );
  String get auLogin => _t(
        '로그인하기',
        'Log in',
        'ログイン',
        '登录',
      );
  String get auToLogin => _t(
        '이미 보관함이 있어요 · 로그인',
        'I already have a vault · Log in',
        'すでに保管庫があります · ログイン',
        '我已有保管箱 · 登录',
      );
  String get auToSignup => _t(
        '처음이에요 · 보관함 만들기',
        'New here · Create a vault',
        'はじめてです · 保管庫を作る',
        '第一次使用 · 创建保管箱',
      );
  String get lgTabChecklist => _t(
        '보호 항목',
        'Safeguards',
        '保護項目',
        '保护事项',
      );
  String get lgTabPrivacy => _t(
        '개인정보 처리방침',
        'Privacy policy',
        'プライバシーポリシー',
        '隐私政策',
      );
  String get lgTabTerms => _t(
        '이용약관',
        'Terms',
        '利用規約',
        '服务条款',
      );
  String get lgTabRefund => _t(
        '환불·요금',
        'Refunds · fees',
        '返金・料金',
        '退款 · 费用',
      );
  String get lgTabCookie => _t(
        '쿠키',
        'Cookies',
        'クッキー',
        'Cookie',
      );
  String get lgTabSdk => _t(
        '외부 서비스 · 메일',
        'Third parties · email',
        '外部サービス・メール',
        '第三方服务 · 邮件',
      );
  String get lgTabLicenses => _t(
        '글꼴·이미지',
        'Fonts · images',
        'フォント・画像',
        '字体 · 图片',
      );
  String get lgTabDelete => _t(
        '내 정보 삭제',
        'Delete my data',
        '情報の削除',
        '删除我的信息',
      );
  String get lgBack => _t(
        '설정으로',
        'Back to Settings',
        '設定へ',
        '返回设置',
      );
  String get lgTitle => _t(
        '약관과 개인정보 보호',
        'Terms and privacy',
        '規約と個人情報保護',
        '条款与隐私保护',
      );
  String get lgIntro => _t(
        '처리방침, 이용약관, 환불 정책, 쿠키 설정, 내 정보 삭제를 한곳에서 봐요.',
        'Privacy policy, terms, refund policy, cookie settings and data deletion in one place.',
        'プライバシーポリシー、利用規約、返金ポリシー、クッキー設定、情報の削除を1か所で確認できます。',
        '隐私政策、服务条款、退款政策、Cookie 设置和信息删除都在这里。',
      );
  String get lgPrivacyTitle => _t(
        '개인정보 처리방침 (최소 수집 · 아동 보호 · 즉시 파기)',
        'Privacy policy (minimal collection · child protection · immediate destruction)',
        'プライバシーポリシー（最小限の収集・児童保護・即時破棄）',
        '隐私政策（最少收集 · 儿童保护 · 立即销毁）',
      );
  String get lgPrivacyLaw => _t(
        '개인정보보호법 제30조 준수',
        'Complies with Article 30 of the Personal Information Protection Act (Korea)',
        '個人情報保護法第30条に準拠',
        '符合韩国《个人信息保护法》第30条',
      );
  String get lgTermsTitle => _t(
        '서비스 이용약관 및 법적 한계 고지',
        'Terms of Service and legal limitations',
        '利用規約および法的限界の告知',
        '服务条款及法律限制告知',
      );
  String get lgTermsLaw => _t(
        '약관규제법 · 변호사법 준수',
        'Complies with the Act on the Regulation of Terms and Conditions and the Attorney-at-Law Act (Korea)',
        '約款規制法・弁護士法に準拠',
        '符合韩国《约款规制法》《律师法》',
      );
  String get lgRefundTitle => _t(
        '환불정책 및 숨겨진 요금 제로(0원) 선언',
        'Refund policy and no-hidden-fees declaration',
        '返金ポリシーおよび隠れた料金ゼロの宣言',
        '退款政策及零隐藏费用声明',
      );
  String get lgRefundLaw => _t(
        '전자상거래법 제17조 준수',
        'Complies with Article 17 of the E-Commerce Act (Korea)',
        '電子商取引法第17条に準拠',
        '符合韩国《电子商务法》第17条',
      );
  String get lgChecklistIntro => _t(
        '개인정보보호법·전자상거래법·표시광고법·장애인차별금지법·저작권법 기준 20개 항목을 적용했습니다.',
        'Twenty safeguards are applied under Korea\'s Personal Information Protection Act, E-Commerce Act, Fair Labeling and Advertising Act, Disability Discrimination Act and Copyright Act.',
        '個人情報保護法・電子商取引法・表示広告法・障害者差別禁止法・著作権法に基づく20項目を適用しています。',
        '依据韩国《个人信息保护法》《电子商务法》《标示广告法》《禁止歧视残疾人法》《著作权法》，适用了 20 项保护措施。',
      );
  String get lgCookieTitle => _t(
        '쿠키 운영 정책 및 동의 상태 변경',
        'Cookie policy and consent settings',
        'クッキーポリシーと同意状態の変更',
        'Cookie 政策及同意状态变更',
      );
  String get lgCookiePending => _t(
        '아직 선택 전',
        'Not chosen yet',
        'まだ未選択',
        '尚未选择',
      );
  String get lgCookieEssential => _t(
        '필수 보안 쿠키만 허용 (선택 쿠키 거절됨)',
        'Essential security cookies only (optional cookies declined)',
        '必須のセキュリティクッキーのみ許可（任意のクッキーは拒否）',
        '仅允许必要的安全 Cookie（已拒绝可选 Cookie）',
      );
  String get lgCookieAll => _t(
        '전체 쿠키 동의 완료',
        'All cookies accepted',
        'すべてのクッキーに同意済み',
        '已同意全部 Cookie',
      );
  String get lgCookieDecline => _t(
        '필수만 허용 (거절)',
        'Essential only (decline)',
        '必須のみ許可（拒否）',
        '仅必要（拒绝）',
      );
  String get lgCookieAccept => _t(
        '전체 쿠키 동의',
        'Accept all cookies',
        'すべてのクッキーに同意',
        '同意全部 Cookie',
      );
  String get lgCookieReset => _t(
        '아직 고르지 않은 상태로 되돌리기',
        'Reset to not chosen',
        '未選択の状態に戻す',
        '恢复为未选择状态',
      );
  String get lgUnsubTitle => _t(
        '보내는 메일과 알림 메일 끄기',
        'Emails we send, and turning notices off',
        '送信するメールと、お知らせメールの停止',
        '我们发送的邮件，以及关闭提醒邮件',
      );
  String get lgSdkTitle => _t(
        '탑재 SDK · 패키지 버전 호환성 및 데이터 전송 제어',
        'Bundled SDKs · package version compatibility and data transfer controls',
        '搭載SDK・パッケージのバージョン互換性とデータ送信の制御',
        '内置 SDK · 包版本兼容性及数据传输控制',
      );
  String get lgLocalRequired => _t(
        '로컬 필수',
        'Required (local)',
        'ローカル必須',
        '本地必需',
      );
  String get lgBlockedTitle => _t(
        '차단된 제3자 광고·추적 SDK 목록 (0개 탑재 보증)',
        'Blocked third-party advertising and tracking SDKs (none bundled)',
        'ブロック済みの第三者広告・追跡SDK一覧（搭載数0を保証）',
        '已屏蔽的第三方广告和追踪 SDK 列表（保证内置 0 个）',
      );
  String get lgLicenseTitle => _t(
        '글꼴(Font) · 아이콘 · 그래픽 상업적 라이선스 검증서',
        'Commercial license verification for fonts, icons and graphics',
        'フォント・アイコン・グラフィックの商用ライセンス検証書',
        '字体 · 图标 · 图形商业许可验证书',
      );
  String get lgLicenseIntro => _t(
        '폰트 저작권 합의금 내용증명이나 무단 이미지 도용 분쟁을 원천 차단하기 위해, 상업적 무료 이용 및 임베딩이 검증된 오픈소스 글꼴과 100% 자체 제작 코드 그래픽만 사용합니다.',
        'To rule out font copyright claims and image misuse disputes, only open-source fonts verified for free commercial use and embedding, and graphics drawn entirely in our own code, are used.',
        'フォントの著作権トラブルや画像の無断使用による紛争を防ぐため、商用無料利用と埋め込みが確認されたオープンソースフォントと、100%自社制作のコードグラフィックのみを使用しています。',
        '为杜绝字体版权纠纷和图片盗用争议，仅使用已确认可免费商用和嵌入的开源字体，以及 100% 自行编写代码绘制的图形。',
      );
  String get lgPurgeTitle => _t(
        '개인정보 및 증빙 파일 즉시 영구 파기 요청 (Right to be Forgotten)',
        'Request immediate, permanent destruction of personal data and evidence files (Right to be Forgotten)',
        '個人情報および証拠ファイルの即時・永久破棄の請求（忘れられる権利）',
        '请求立即永久销毁个人信息和凭证文件（被遗忘权）',
      );
  String get lgPurgeIntro => _t(
        '고객센터에 별도로 전화하거나 이메일을 보낼 필요 없이, 지금 바로 아래 버튼 하나로 내 계정, 환불 클레임 내역, 영수증·파손 사진 원본을 데이터베이스에서 즉시 영구 삭제할 수 있습니다.',
        'Without calling or emailing support, you can permanently delete your account, refund claim history and the original receipt and damage photos from the database right now with the single button below.',
        'カスタマーセンターに電話やメールをしなくても、下のボタン1つで、アカウント、返金クレーム履歴、領収書・破損写真の原本を今すぐデータベースから永久に削除できます。',
        '无需致电或发邮件给客服，只需点击下方按钮，即可立即从数据库中永久删除你的账户、退款申请记录以及收据和破损照片原件。',
      );
  String get lgPurgePassword => _t(
        '본인 확인 비밀번호 (체험 계정이면 비워 두어도 바로 실행돼요)',
        'Password to confirm it is you (leave empty for the demo account)',
        '本人確認用パスワード（体験アカウントは空欄でも実行されます）',
        '用于确认本人的密码（体验账户可留空）',
      );
  String get lgPurgePasswordHint => _t(
        '현재 비밀번호 입력',
        'Enter your current password',
        '現在のパスワードを入力',
        '输入当前密码',
      );
  String get lgPurgeConsent => _t(
        '내 계정과 모든 환불 내역·사진을 복구 불가능하게 즉시 파기하는 것에 동의합니다.',
        'I agree to the immediate and irreversible destruction of my account and all refund records and photos.',
        'アカウントとすべての返金履歴・写真を、復元できない形で直ちに破棄することに同意します。',
        '我同意立即且不可恢复地销毁我的账户以及所有退款记录和照片。',
      );
  String get lgPurging => _t(
        '영구 파기 실행 중…',
        'Destroying permanently…',
        '永久破棄を実行中…',
        '正在永久销毁…',
      );
  String get lgPurgeButton => _t(
        '내 정보와 사진 모두 영구 삭제하기',
        'Permanently delete all my data and photos',
        '情報と写真をすべて永久に削除する',
        '永久删除我的全部信息和照片',
      );
  String get ftSemantics => _t(
        '사업자 등록 정보 및 법적 정책 안내 푸터',
        'Business registration and legal policy footer',
        '事業者登録情報および法的ポリシーの案内フッター',
        '企业登记信息及法律政策页脚',
      );
  String get ftTerms => _t(
        '서비스 이용약관',
        'Terms of Service',
        '利用規約',
        '服务条款',
      );
  String get ftRefund => _t(
        '환불·요금 정책',
        'Refund · fee policy',
        '返金・料金ポリシー',
        '退款 · 费用政策',
      );
  String get ftCookie => _t(
        '쿠키 운영 정책',
        'Cookie policy',
        'クッキーポリシー',
        'Cookie 政策',
      );
  String get ftSdk => _t(
        '외부 SDK 점검 · 메일',
        'Third-party SDKs · email',
        '外部SDKの点検・メール',
        '第三方 SDK 检查 · 邮件',
      );
  String get ftLicense => _t(
        '글꼴·이미지 라이선스',
        'Font · image licenses',
        'フォント・画像ライセンス',
        '字体 · 图片许可',
      );
  String get ftDelete => _t(
        '개인정보 즉시 삭제요청',
        'Request immediate data deletion',
        '個人情報の即時削除請求',
        '请求立即删除个人信息',
      );
  String get ftNotice => _t(
        '※ 법적 고지 (근거없는 주장 배제): ReLo는 해외직구 반품·교환·환불 증빙 정리, 8개국 통화 계산, 외국어 문의 초안 작성 및 실제 카드 취소 입금 확인 기록을 돕는 B2C 소프트웨어 도구이며, 법률 소송 대리인이 아닙니다.',
        '※ Legal notice: ReLo is a B2C software tool that helps you organize evidence for returns, exchanges and refunds on overseas purchases, calculate amounts in 8 currencies, draft inquiries in foreign languages and record confirmed card refunds. It does not act as your legal representative.',
        '※ 法的告知: ReLoは、海外通販の返品・交換・返金の証拠整理、8通貨の計算、外国語での問い合わせ下書きの作成、実際のカード取消・入金確認の記録を支援するB2Cソフトウェアツールであり、訴訟の代理人ではありません。',
        '※ 法律告知：ReLo 是一款 B2C 软件工具，帮助整理海外购物退货、换货、退款的凭证，进行 8 种货币计算，起草外语咨询，并记录实际的卡退款到账确认，并非法律诉讼代理人。',
      );
  String get mcAll => _t(
        '전체',
        'All',
        'すべて',
        '全部',
      );
  String get mcOpen => _t(
        '진행 중',
        'In progress',
        '進行中',
        '进行中',
      );
  String get mcDone => _t(
        '입금 완료',
        'Received',
        '入金完了',
        '已到账',
      );
  String get mcTrash => _t(
        '휴지통',
        'Trash',
        'ゴミ箱',
        '回收站',
      );
  String get mcSearchClose => _t(
        '검색 닫기',
        'Close search',
        '検索を閉じる',
        '关闭搜索',
      );
  String get mcSearch => _t(
        '검색',
        'Search',
        '検索',
        '搜索',
      );
  String get mcTrashClose => _t(
        '휴지통 닫기',
        'Close trash',
        'ゴミ箱を閉じる',
        '关闭回收站',
      );
  String get mcTrashOpen => _t(
        '휴지통 열기',
        'Open trash',
        'ゴミ箱を開く',
        '打开回收站',
      );
  String get mcSearchHint => _t(
        '상품명 · 쇼핑몰 · 주문번호',
        'Item · store · order number',
        '商品名・ショップ・注文番号',
        '商品名 · 商家 · 订单号',
      );
  String get mcTrashEmpty => _t(
        '휴지통이 비어 있어요',
        'The trash is empty',
        'ゴミ箱は空です',
        '回收站是空的',
      );
  String get mcEmpty => _t(
        '아직 환불 신청이 없어요',
        'No refund requests yet',
        'まだ返金申請がありません',
        '还没有退款申请',
      );
  String get mcStart => _t(
        '환불 신청 시작하기',
        'Start a refund request',
        '返金申請を始める',
        '开始申请退款',
      );
  String get shHomeLabel => _t(
        'ReLo 홈 화면으로 이동 (단축키 Alt+1)',
        'Go to ReLo home (shortcut Alt+1)',
        'ReLoホームへ移動（ショートカット Alt+1）',
        '前往 ReLo 首页（快捷键 Alt+1）',
      );
  String get shLogin => _t(
        '로그인 및 회원가입 열기',
        'Open log in and sign up',
        'ログイン・会員登録を開く',
        '打开登录和注册',
      );

  // ── 값이 끼어드는 문구 ──

  /// 마감까지 남은 날: "D-2", "오늘", "3일 지남"
  String? dday(String? iso) {
    final d = DDay.daysLeft(iso);
    if (d == null) return null;
    if (d == 0) return cmToday;
    if (d > 0) return 'D-$d';
    final n = -d;
    return _t(
      '${n}일 지남',
      n == 1 ? '1 day overdue' : '$n days overdue',
      '${n}日超過',
      '已过${n}天',
    );
  }

  /// 날짜: 한국어는 "2026년 10월 27일", 그 밖의 언어는 2026-10-27
  String date(String? iso) {
    if (locale == ReloLocale.ko) return MoneyFormat.formatKoreanDate(iso);
    if (iso == null || iso.isEmpty) return '-';
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }

  // 상세
  String dOrderLine(String vendor, String ref) => _t(
        '$vendor · 주문번호 $ref',
        '$vendor · Order $ref',
        '$vendor · 注文番号 $ref',
        '$vendor · 订单号 $ref',
      );
  String dDeadline(String date) =>
      _t('마감 $date · ', 'Due $date · ', '期限 $date · ', '截止 $date · ');
  String dStepOf(int n) =>
      _t('여섯 단계 중 ${n}단계', 'Step $n of 6', '6段階中${n}段階', '共6步，第${n}步');
  String dAgreedField(String cur) => _t(
        '약속한 환불 금액 ($cur)',
        'Promised refund ($cur)',
        '約束された返金額（$cur）',
        '承诺退款金额（$cur）',
      );
  String dDepositField(String cur) => _t(
        '들어온 금액 ($cur)',
        'Amount received ($cur)',
        '入金額（$cur）',
        '到账金额（$cur）',
      );
  String dLedgerCount(int n) => _t(
        '기록한 입금 ${n}건',
        n == 1 ? '1 deposit recorded' : '$n deposits recorded',
        '記録した入金 ${n}件',
        '已记录到账 $n 笔',
      );
  String dFilesCount(int n) => _t(
        '증빙 파일 ${n}개',
        'Evidence files · $n',
        '証拠ファイル ${n}件',
        '凭证文件 $n 个',
      );

  // 신청
  String wStepOf(int n) =>
      _t('다섯 단계 중 ${n}단계', 'Step $n of 5', '5段階中${n}段階', '共5步，第${n}步');
  String wDeparted(String city) => _t(
        '${city}에서 출발했어요',
        'On its way from $city',
        '${city}から出発しました',
        '已从${city}出发',
      );
  String wSavedLine(String vendor, String ref) => _t(
        '$vendor · 주문번호 $ref\n환불 신청과 증빙이 내 보관함에 저장됐어요.',
        '$vendor · Order $ref\nYour request and evidence are saved in your vault.',
        '$vendor · 注文番号 $ref\n返金申請と証拠が保管庫に保存されました。',
        '$vendor · 订单号 $ref\n退款申请和凭证已保存到你的保管箱。',
      );
  String wAmount(String cur) => _t(
        '문제가 생긴 상품 금액 ($cur)',
        'Price of the item with the problem ($cur)',
        '問題のあった商品の金額（$cur）',
        '出问题商品的金额（$cur）',
      );
  /// [masked]는 붙인 파일이 모두 주소를 가린 것일 때만 true (직접 고른 사진은 앱이 가려 주지 않는다)
  String wSumFilesValue(int n, {bool masked = true}) => masked
      ? _t(
          '${n}개 · 주소 가려짐',
          '$n · address hidden',
          '${n}件 · 住所は非表示',
          '$n 个 · 地址已隐藏',
        )
      : _t('${n}개', '$n', '${n}件', '$n 个');

  // 설정
  String stOffline(String email) => _t(
        '$email · 오프라인 데모',
        '$email · offline demo',
        '$email · オフラインデモ',
        '$email · 离线演示',
      );

  // 약관·정책
  /// 문서 본문은 한국어 원문 그대로 보여 준다. 다른 언어로 볼 때만 그렇다고 알린다
  /// (한국어에서는 빈 글자라 아무것도 나오지 않는다).
  String get lgKoreanOnly => _t(
        '',
        'The full text below is provided in Korean, the governing language of this service.',
        '以下の全文は、本サービスの準拠言語である韓国語で提供されます。',
        '以下全文以本服务的准据语言韩语提供。',
      );
  String lgCookieCurrent(String status) => _t(
        '현재 선택된 쿠키 설정: $status',
        'Current cookie setting: $status',
        '現在のクッキー設定: $status',
        '当前 Cookie 设置：$status',
      );
  String lgSdkPinned(String flutter, String dart) => _t(
        'Flutter $flutter / Dart $dart 기준 모든 서브 패키지 버전을 dependency_overrides로 고정하여 구형/신형 충돌을 원천 차단했습니다.',
        'All sub-package versions are pinned with dependency_overrides against Flutter $flutter / Dart $dart to prevent version conflicts.',
        'Flutter $flutter / Dart $dart を基準に、すべてのサブパッケージのバージョンを dependency_overrides で固定し、新旧の衝突を防いでいます。',
        '以 Flutter $flutter / Dart $dart 为基准，通过 dependency_overrides 固定所有子包版本，从源头避免新旧版本冲突。',
      );
  String lgSdkDetail(String purpose, String shared, String license) => _t(
        '용도: $purpose\n데이터 전송 범위: $shared\n라이선스: $license',
        'Purpose: $purpose\nData shared: $shared\nLicense: $license',
        '用途: $purpose\nデータ送信範囲: $shared\nライセンス: $license',
        '用途：$purpose\n数据传输范围：$shared\n许可证：$license',
      );
  String lgLicenseDetail(String category, String holder, String note) => _t(
        '분류: $category | 권리자: $holder\n검증 결과: $note',
        'Category: $category | Rights holder: $holder\nVerification: $note',
        '分類: $category | 権利者: $holder\n検証結果: $note',
        '分类：$category | 权利人：$holder\n验证结果：$note',
      );
  String lgPurgeReceipt(String code) => _t(
        '✓ 최근 개인정보 영구 파기 완료 증명 번호: $code',
        '✓ Latest destruction receipt number: $code',
        '✓ 直近の個人情報永久破棄の完了証明番号: $code',
        '✓ 最近一次个人信息永久销毁完成证明编号：$code',
      );

  // 앱 틀 (화면 읽기 프로그램용 이름)
  String shAccount(String name) => _t(
        '${name}님 계정 설정 열기',
        'Open account settings for $name',
        '${name}さんのアカウント設定を開く',
        '打开 $name 的账户设置',
      );
  String shTab(String label, int n) => _t(
        '$label 탭 (단축키 Alt+$n)',
        '$label tab (shortcut Alt+$n)',
        '${label}タブ（ショートカット Alt+$n）',
        '$label 标签（快捷键 Alt+$n）',
      );

  /// 판매자 답장의 종류. 서버 설정의 이름은 한국어라서, 아는 종류는 지금 언어로 바꿔 보여 준다.
  // ── 시작 화면 ──
  String get introTagline => _t(
        '해외 직구 환불, 끝까지 같이 챙겨요',
        'Overseas refunds, followed through together',
        '海外通販の返金を、最後まで一緒に',
        '海淘退款，陪你跟到底',
      );

  // ── 영수증 · 사진 고르기 ──
  String get evSheetTitle => _t(
        '어디서 가져올까요?',
        'Where should we get it from?',
        'どこから追加しますか？',
        '从哪里添加？',
      );
  String get evCamera => _t(
        '사진 찍기',
        'Take a photo',
        '写真を撮る',
        '拍照',
      );
  String get evPhoto => _t(
        '사진첩에서 고르기',
        'Choose from photos',
        '写真から選ぶ',
        '从相册选择',
      );
  String get evFile => _t(
        '파일에서 고르기 (PDF)',
        'Choose a file (PDF)',
        'ファイルから選ぶ (PDF)',
        '选择文件 (PDF)',
      );
  String get evNote => _t(
        '사진에 담긴 촬영 위치는 지우고 올려요. 파일 하나에 10MB까지.',
        'Location data in photos is removed before upload. Up to 10 MB per file.',
        '写真の位置情報は削除してからアップロードします。1ファイル10MBまで。',
        '上传前会删除照片中的位置信息。每个文件最大 10MB。',
      );
  String get evTooLarge => _t(
        '10MB보다 큰 파일은 올릴 수 없어요.',
        'Files over 10 MB cannot be added.',
        '10MBを超えるファイルは追加できません。',
        '无法添加超过 10MB 的文件。',
      );
  String get evUnsupportedType => _t(
        '사진(JPG · PNG · WebP)이나 PDF만 올릴 수 있어요.',
        'Only photos (JPG, PNG, WebP) or PDF files can be added.',
        '写真(JPG・PNG・WebP)またはPDFのみ追加できます。',
        '只能添加照片 (JPG、PNG、WebP) 或 PDF。',
      );
  String get evUnreadable => _t(
        '파일을 읽지 못했어요. 다시 골라 주세요.',
        'Could not read the file. Please choose it again.',
        'ファイルを読み込めませんでした。もう一度選んでください。',
        '无法读取文件，请重新选择。',
      );
  String get evUnavailable => _t(
        '이 기기에서는 아직 파일을 고를 수 없어요.',
        'Picking files is not available on this device yet.',
        'この端末ではまだファイルを選べません。',
        '此设备暂时无法选择文件。',
      );
  String evProblem(EvidenceProblem problem) => switch (problem) {
        EvidenceProblem.tooLarge => evTooLarge,
        EvidenceProblem.unsupportedType => evUnsupportedType,
        EvidenceProblem.unreadable => evUnreadable,
        EvidenceProblem.unavailable => evUnavailable,
      };
  String get evSharedAttached => _t(
        '공유받은 파일을 붙였어요.',
        'The shared file has been attached.',
        '共有されたファイルを添付しました。',
        '已添加分享过来的文件。',
      );
  String get dSendVia => _t(
        '메일 · 메신저로 보내기',
        'Send with mail or chat',
        'メール・メッセージで送る',
        '用邮件或聊天应用发送',
      );
  String dSendSubject(String orderRef) => _t(
        '주문 $orderRef 환불 요청',
        'Refund request for order $orderRef',
        '注文 $orderRef の返金リクエスト',
        '订单 $orderRef 退款申请',
      );
  String get dSendThenMark => _t(
        '보낸 뒤에 "보냈어요"를 눌러 주세요.',
        'After sending, tap "I sent it".',
        '送信したら「送信しました」を押してください。',
        '发送后请点“已发送”。',
      );

  // ── 마감일 정하기 ──
  String get dDeadlineSet => _t(
        '마감일 정하기',
        'Set a deadline',
        '期限を設定',
        '设置截止日',
      );
  String get dDeadlineChange => _t(
        '바꾸기',
        'Change',
        '変更',
        '修改',
      );
  String get dlTitle => _t(
        '판매자가 정한 기한이 있나요?',
        'Did the store give you a deadline?',
        'ショップから期限の案内はありましたか？',
        '商家给了截止日期吗？',
      );
  String get dlSub => _t(
        '반품이나 환불 요청을 언제까지 해야 하는지 적어 두면, 마감 전에 알려 드릴 수 있어요.',
        'Note the date you must return or request by, and we can remind you before it.',
        '返品や返金をいつまでに申請すべきか記録しておくと、期限の前にお知らせできます。',
        '记下必须退货或申请退款的日期，我们可以在截止前提醒你。',
      );
  String get dlDate => _t(
        '마감일',
        'Deadline',
        '期限',
        '截止日',
      );
  String get dlQuote => _t(
        '판매자가 쓴 말 그대로',
        "The store's exact words",
        'ショップの原文',
        '商家的原话',
      );
  String get dlErrDate => _t(
        '마감일을 골라 주세요.',
        'Choose a deadline.',
        '期限を選んでください。',
        '请选择截止日。',
      );
  String get dlErrQuote => _t(
        '판매자가 쓴 말을 그대로 적어 주세요.',
        "Enter the store's exact words.",
        'ショップの原文を入力してください。',
        '请填写商家的原话。',
      );
  String get dlClear => _t(
        '기한 지우기',
        'Remove deadline',
        '期限を削除',
        '删除截止日',
      );
  String get dToastDeadline => _t(
        '마감일을 저장했어요.',
        'Deadline saved.',
        '期限を保存しました。',
        '截止日已保存。',
      );
  String get dToastDeadlineCleared => _t(
        '마감일을 지웠어요.',
        'Deadline removed.',
        '期限を削除しました。',
        '截止日已删除。',
      );

  // ── 마감 알림 ──
  String get stReminders => _t(
        '마감 알림',
        'Deadline reminders',
        '期限のお知らせ',
        '截止提醒',
      );
  String get stRemindersSub => _t(
        '마감 3일 전 · 하루 전 · 당일 아침 9시에 알려요.',
        'At 9 AM: 3 days before, the day before, and on the deadline.',
        '期限の3日前・前日・当日の朝9時にお知らせします。',
        '在截止前 3 天、前 1 天和当天早上 9 点提醒。',
      );
  String get stRemindersDenied => _t(
        '기기 설정에서 ReLo 알림을 허용해 주세요.',
        'Allow notifications for ReLo in your device settings.',
        '端末の設定でReLoの通知を許可してください。',
        '请在设备设置中允许 ReLo 发送通知。',
      );
  String get stRemindersUnavailable => _t(
        '이 기기에서는 알림을 쓸 수 없어요.',
        'Reminders are not available on this device.',
        'この端末ではお知らせを使えません。',
        '此设备无法使用提醒。',
      );
  String get rmTurnedOn => _t(
        '마감 전에 알려 드릴게요.',
        "We'll remind you before the deadline.",
        '期限の前にお知らせします。',
        '会在截止前提醒你。',
      );
  String get rmAskAction => _t(
        '마감 전에 알림 받기',
        'Remind me before the deadline',
        '期限の前にお知らせを受け取る',
        '截止前提醒我',
      );
  String get rmIn3Title => _t(
        '환불 마감 3일 전이에요',
        'Refund deadline in 3 days',
        '返金の期限まであと3日です',
        '退款截止还有 3 天',
      );
  String get rmTomorrowTitle => _t(
        '환불 마감이 내일이에요',
        'Refund deadline is tomorrow',
        '返金の期限は明日です',
        '退款明天截止',
      );
  String get rmTodayTitle => _t(
        '오늘이 환불 마감일이에요',
        'Refund deadline is today',
        '今日が返金の期限です',
        '今天是退款截止日',
      );
  String get rmReplyTitle => _t(
        '답장이 왔는지 확인해 볼까요?',
        'Has the store replied yet?',
        'ショップから返信は来ましたか？',
        '商家回复了吗？',
      );
  String rmReplyBody(String vendor) => _t(
        '$vendor에 메시지를 보낸 지 3일이 지났어요.',
        'It has been 3 days since you messaged $vendor.',
        '$vendorにメッセージを送って3日が経ちました。',
        '给 $vendor 发消息已过去 3 天。',
      );

  String replyKind(String key, String fallback) {
    if (locale == ReloLocale.ko) return fallback;
    return switch (key) {
      'agreement' => _t(fallback, 'Refund / exchange promised', '返金・交換の約束', '承诺退款/换货'),
      'refund_notice' => _t(fallback, 'Refund processing notice', '返金処理の案内', '退款处理通知'),
      'evidence' => _t(fallback, 'More photos requested', '追加写真の依頼', '要求补充照片'),
      'denied' => _t(fallback, 'Refund denied', '返金拒否', '拒绝退款'),
      'other' => _t(fallback, 'Other', 'その他の案内', '其他通知'),
      _ => fallback,
    };
  }

  /// 지금 단계에서 할 일 한 줄. 서버가 주는 문장은 한국어라서, 다른 언어에서는 단계에 맞는 이 문장을 쓴다.
  String dNextStep(String state) => switch (state) {
        'preparing' || 'review' => _t(
            '판매자에게 보낼 메시지를 만들어 쇼핑몰에 보내세요.',
            'Draft your message and send it to the store.',
            'メッセージを作成してショップに送りましょう。',
            '撰写消息并发送给商家。',
          ),
        'awaiting' => _t(
            '쇼핑몰 답장이 오면 답장 탭에 붙여 넣으세요.',
            'When the store replies, paste it in the Reply tab.',
            'ショップから返信が来たら「返信」タブに貼り付けてください。',
            '收到商家回复后，粘贴到“回复”标签中。',
          ),
        'negotiating' => _t(
            '카드 취소나 통장 입금을 확인하고 입금 탭에 기록하세요.',
            'Check your card or bank account, then record the money you received in the Deposit tab.',
            'カードの取消や口座への入金を確認し、「入金」タブに記録してください。',
            '确认卡退款或银行到账后，在“到账”标签中记录。',
          ),
        'partial' || 'recovered' => _t(
            '모든 금액이 들어왔어요. 끝난 건으로 표시해 주세요.',
            'Everything has been received. You can mark this as finished.',
            'すべて入金されました。完了として表示してください。',
            '款项已全部到账，可以标记为完成。',
          ),
        'completed' => _t(
            '환불이 모두 끝났어요.',
            'This refund is finished.',
            'この返金は完了しました。',
            '这笔退款已完成。',
          ),
        _ => '',
      };
}
