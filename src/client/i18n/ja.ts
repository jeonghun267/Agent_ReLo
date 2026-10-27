/**
 * @module client/i18n/ja
 * @layer Model (Localization Dictionary)
 * @purpose Japanese (日本語) consumer copy written in polite, easy-to-understand everyday language.
 */

import type { TranslationDictionary } from "@/client/i18n/types";

export const jaMessages: TranslationDictionary = {
	common: {
		skipToContent: "本文へスキップ",
		loadingScreen: "画面を準備しています...",
		notFoundSpeech: "お探しのページは移動したか、存在しないアドレスです。",
		backHome: "ホーム画面へ戻る",
	},
	nav: {
		about: "サービス紹介",
		aboutMobile: "ホーム",
		apply: "返金申請",
		applyMobile: "申請する",
		myRefunds: "返金履歴",
		myRefundsMobile: "返金履歴",
		settings: "設定",
		settingsMobile: "設定",
		login: "ログイン",
		applyCta: "返金を申請する",
		userSuffix: "様",
		verifyNoticePrefix: "返金状況のお知らせを受け取るには",
		verifyNoticeSuffix: "の受信箱をご確認ください。",
		resendVerify: "確認メールを再送",
		sending: "送信中...",
		languageLabel: "言語選択",
	},
	hero: {
		badge: "海外通販の返品・返金・入金確認サポート",
		titleLine1: "海外から届いた荷物が壊れていた？",
		titleHighlight: "外国語がわからなくても口座へしっかり返金。",
		subtitle:
			"注文レシートの自動入力から自宅住所の切り取り、海外ショップへ送る外国語メッセージの作成、実際のカード返金確認までひとつで簡単に完結します。",
		primaryCta: "今すぐ3分で返金を申請する",
		secondaryWallet: "返金履歴を見る",
		secondaryGlobe: "世界の返金ルートを見る",
		trust1: "8通貨の金額を正確に自動計算",
		trust2: "写真・レシート10MBを安全に個別保管",
		trust3: "口約束ではなく実際のカード取消を確認",
	},
	malls: {
		us: "アメリカ",
		global: "グローバル",
		cn: "中国",
		jp: "日本",
		usUk: "米・英",
		euCa: "欧州・加",
		tagAmazon: "英語の返金依頼を即時作成",
		tagAli: "破損写真つきでスムーズ返金",
		tagTaobao: "誤配送・不足品の解決",
		tagMercari: "丁寧な日本語・英語メッセージ",
		tagIherb: "液漏れ・破損商品の返金",
		tagEbay: "販売者の返金約束を記録",
		tagFarfetch: "不良品の返送料負担を軽減",
		tagTemu: "不良品の現地通貨返金",
	},
	globe: {
		eyebrow: "ひと目でわかるグローバル返金ルート",
		titleLine1: "海の向こうで止まっていたお金が、",
		titleLine2: "ソウルの自分の口座へまっすぐ戻るように。",
		description:
			"アメリカ・日本・中国・ヨーロッパのどこで買った商品でも安心。海外ショップへ飛行機で返金依頼が届き、実際にカード決済が取り消されるまで見守ります。",
		routeSuffix: "リアルタイム返金ルート",
		startThisMall: "このショップの返金を始める",
		seoulHubLabel: "ソウル · 口座へ返金到着",
		dragHint: "地球儀をドラッグするか、下の国ボタンをタップしてください",
		canvasAria:
			"アメリカ、日本、中国、ヨーロッパの大陸からソウルへ飛行機で返金ルートを結ぶ3D世界地図地球儀",
		corridors: {
			usSea: {
				country: "アメリカ",
				status: "カード決済の取消完了",
				issue: "配送箱と本体のカバーが割れた状態で届きました。",
			},
			jpTyo: {
				country: "日本",
				status: "違う商品が到着 · 全額返金",
				issue: "注文したものと異なるカラーの商品が届きました。",
			},
			cnSzx: {
				country: "中国",
				status: "返送なしでそのまま返金完了",
				issue: "電源が入らない初期不良品が届きました。",
			},
			euLon: {
				country: "ヨーロッパ",
				status: "ショップ窓口で返金確定",
				issue: "付属品の一部が不足しており、内箱も破れていました。",
			},
			usLax: {
				country: "米国西部",
				status: "破損写真の確認後に即時承認",
				issue: "ボトルが割れて中身が箱の中に漏れていました。",
			},
		},
	},
	phoneStory: {
		eyebrow: "スクロールで見る3分解決ステップ",
		headline: "面倒な手続きはすべてスマホの中で完結します",
		scrollHint:
			"下にスクロールすると、画面からステップカードが立体的に浮かび上がります",
		scenes: [
			{
				step: "01",
				tab: "レシート読取",
				badge: "レシート自動入力 · 自宅住所を隠す",
				titleLine1: "長くて読みづらい外国語レシートも、",
				titleLine2: "スクショ1枚を入れるだけ。",
				description:
					"海外ショップの注文履歴から注文番号や金額を手入力する必要はありません。画像やPDFを入れるだけで自動入力され、箱に書かれた自宅住所や電話番号もきれいに切り取れます。",
				screenHeader: "注文レシートの自動読み取り",
				screenStatus: "自動入力完了",
				screenSubTitle: "見つかった注文情報",
				popLeftTitle: "注文番号を3秒で自動入力",
				popLeftSub: "#114-8920411 · $184.00",
				popRightTitle: "住所・電話番号をカット",
				popRightSub: "傷や破損箇所だけを鮮明に保存",
			},
			{
				step: "02",
				tab: "外国語メッセージ作成",
				badge: "ショップに合わせた外国語を自動作成",
				titleLine1: "いつもの言葉で1行書くだけで、",
				titleLine2: "そのまま送れる外国語が完成します。",
				description:
					"翻訳サイトでどんな表現にするか迷う必要はありません。破損状況と希望返金額を漏れなく盛り込んだ、丁寧で伝わりやすい英語・日本語・中国語文をすぐ作成します。",
				screenHeader: "ショップ窓口へ送るメッセージ",
				screenStatus: "コピー準備完了",
				screenSubTitle: "入力したお困りごと",
				popLeftTitle: "英語・日本語・中国語に対応",
				popLeftSub: "ショップの返品規約に沿った文章",
				popRightTitle: "高額な返送料の負担を防ぐ",
				popRightSub: "販売者責任の旨を自動で明記",
			},
			{
				step: "03",
				tab: "実際の入金確認",
				badge: "口約束の放置防止 · 2段階の返金確認",
				titleLine1: "「返金しました」の言葉だけを信じて",
				titleLine2: "待ちぼうけにならないために。",
				description:
					"ショップがチャットで返金を約束したままカード取消を忘れるトラブルを防ぎます。約束された金額と、実際にカードへ戻った金額を並べて最後まで確認します。",
				screenHeader: "カード返金の最終チェック",
				screenStatus: "全額返金済み",
				screenSubTitle: "未回収の残り金額 $0.00",
				popLeftTitle: "海外カード決済の取消を確認",
				popLeftSub: "AMZ*REFUND +$184.00 完了",
				popRightTitle: "約束額 vs 実際の返金額を照合",
				popRightSub: "1円単位まで漏れなく確認",
			},
		],
	},
	whyRelo: {
		eyebrow: "なぜ ReLo なのか？",
		titleLine1: "配送代行業者も、一般的な翻訳アプリも",
		titleLine2: "助けてくれなかった瞬間を解決します。",
		description:
			"自宅に届いて箱を開けてから気づいた破損や不良。どこへ連絡すればいいか迷う海外通販トラブルを、申請から入金までしっかり支えます。",
		colTopic: "比較ポイント",
		colAgent: "従来の配送代行業者",
		colTranslator: "翻訳アプリで自作",
		colRelo: "ReLo 返金サポート",
		rows: [
			{
				topic: "自宅に届いて開封したら壊れていたとき",
				agent: "海外倉庫を出発した後はサポート対象外",
				translator: "ショップの返金ルールを自分で調べる必要あり",
				relo: "自宅で開封した直後から最後まで案内",
			},
			{
				topic: "海外ショップへの連絡と高い国際返送料",
				agent: "別途手数料＋高額な国際返送料が自己負担",
				translator: "直訳になり重要な返金条件が抜けやすい",
				relo: "返送料負担を抑える丁寧な外国語を作成",
			},
			{
				topic: "配送ラベルの自宅住所・個人情報の保護",
				agent: "元写真をそのまま送ると個人情報露出の恐れ",
				translator: "別の画像編集アプリで隠す手間がかかる",
				relo: "画面上で不良箇所だけを簡単に切り抜き",
			},
			{
				topic: "「返金する」と言われたのにお金が戻らないとき",
				agent: "実際のカード入金までは確認不可",
				translator: "実際のカード入金までは確認不可",
				relo: "ショップの約束額と実際のカード取消を2回確認",
			},
		],
	},
	flow: {
		eyebrow: "ひと目でわかる5つのステップ",
		title: "申請から口座への返金まで、荷物追跡のようにわかりやすく",
		subtitle:
			"気になるステップを押して、どのようにお手伝いするかご覧ください。",
		startBtn: "この5ステップで返金を始める",
		steps: [
			{
				id: "scan",
				stepNo: "ステップ1",
				title: "注文レシート読取",
				subtitle: "画像・PDFを自動入力",
				badge: "3秒自動入力",
				guide:
					"購入履歴のスクショやPDFをアップロードすると、ショップ名・注文番号・金額を自動で入力します。",
				previewTitle: "自動で読み取った注文情報の例",
				sample:
					"ショップ: Amazon US · 注文番号 #114-8920411 · 注文日: 2026-10-18 · 商品: ワイヤレスヘッドホン ($298.00)",
				points: [
					"小さな文字のレシートも画面上で大きく確認",
					"長い注文番号や金額を手入力する手間なし",
				],
			},
			{
				id: "crop",
				stepNo: "ステップ2",
				title: "不良写真の準備",
				subtitle: "住所を隠して拡大",
				badge: "写真の切り抜き",
				guide:
					"配送シールの自宅住所は切り取り、割れたり傷ついたりした部分だけを鮮明に残します。",
				previewTitle: "専用の写真保管ボックス（最大10MB）",
				sample:
					"[切り抜き完了] 角の破損写真.png (1.4 MB · ご本人のアカウントのみで暗号化保管)",
				points: [
					"指やマウスで必要な部分だけを四角く選択",
					"アップロードした写真はご本人のみ閲覧可能",
				],
			},
			{
				id: "draft",
				stepNo: "ステップ3",
				title: "外国語メッセージ作成",
				subtitle: "コピーしてすぐ送信",
				badge: "自動翻訳・作成",
				guide:
					"困っている内容を普段の言葉で書くだけ。海外サポート担当者にすぐ伝わる丁寧な外国語に整えます。",
				previewTitle: "海外ショップ窓口へ送るメッセージ例",
				sample:
					"Subject: Refund Request for Damaged Item — Order #114-8920411\n\nDear Customer Support, The item arrived with exterior damage as shown in the attached photos. Could you please process a full refund of USD 298.00?",
				points: [
					"事実と異なる表現は作らず注文情報だけを正確に反映",
					"ワンクリックでチャットやメールに貼り付け可能",
				],
			},
			{
				id: "reply",
				stepNo: "ステップ4",
				title: "ショップ返信の要約",
				subtitle: "やさしい3行まとめ",
				badge: "返信を簡単解説",
				guide:
					"ショップから長い外国語の返信が届いたら貼り付けてください。要点と返送期限をわかりやすく整理します。",
				previewTitle: "外国語返信の要約サンプル",
				sample:
					"[解説結果：返金の約束] 商品の返送なしで $298.00 の全額返金が案内されました。3〜5日後に実際のカード取消明細をご確認ください！",
				points: [
					"「返金するという約束」と「実際の入金」を区別して案内",
					"見落としがちな返送期限日をわかりやすく表示",
				],
			},
			{
				id: "settled",
				stepNo: "ステップ5",
				title: "実際の入金確認",
				subtitle: "カード取消・口座入金",
				badge: "入金の最終確認",
				guide:
					"最後にカードや口座へ実際にお金が戻ったかを確認して、すっきり完了します。",
				previewTitle: "返金完了の確認シート",
				sample:
					"実際の入金確認: $298.00 / 約束額 $298.00 (残り金額 $0.00 · カード取消確認済み)",
				points: [
					"一部のみ返金された場合は不足額を自動で計算",
					"実際の入金が確認できてから安心の完了処理",
				],
			},
		],
	},
	simulator: {
		eyebrow: "戻ってくる金額シミュレーター",
		title: "トラブルがあった海外通販の金額はいくらですか？",
		subtitle: "選んだショップと金額のまま、すぐに申請画面を開けます。",
		mallLabel: "購入したショップ",
		issueLabel: "どんな問題がありましたか？",
		priceLabel: "支払った金額",
		previewBadge: "自動作成される英語メッセージの例",
		barSolo: "翻訳アプリだけで問い合わせる場合",
		barRelo: "ReLoでしっかり準備して申請する場合",
		expectedLabel: "予想返金額",
		completenessLabel: "準備の充実度",
		extraTitle: "ひとりで悩むより守れる見込みの追加返金額",
		extraSuffix: "しっかり守れます",
		applyWithPreset: "この条件ですぐ申請する",
		scenarios: {
			damaged: {
				label: "壊れて届いた",
				issue:
					"箱を開けた時点で外箱と商品の角が割れており、使用できない状態です。",
			},
			wrong: {
				label: "違う商品・部品不足",
				issue:
					"注文したオプションと違う商品が届き、付属品の一部も入っていません。",
			},
			defect: {
				label: "電源が入らない",
				issue: "届いてすぐ電源につなぎましたが、全く動作しない初期不良品です。",
			},
		},
	},
	closingCta: {
		titleLine1: "ショップの返金期限が過ぎてしまう前に、",
		titleLine2: "今すぐ大切なお金を守りましょう。",
		subtitle: "注文番号と写真1枚があれば、3分で完了します。",
		button: "3分で返金を申請する",
	},
	footer: {
		sloganLine1: "海外通販の開封から返金の入金まで",
		sloganLine2: "ついに、ReLo ひとつで。",
		colService: "サービス案内",
		serviceLinks: [
			{ label: "サービス紹介ホーム", to: "/" },
			{ label: "3分かんたん返金申請", to: "/wizard" },
			{ label: "返金履歴の確認", to: "/claims" },
			{ label: "外国語メッセージ作成", to: "/wizard" },
			{ label: "ショップ返信の要約", to: "/claims" },
		],
		colMalls: "対応ショップ",
		mallLinks: [
			"Amazon US · JP · UK",
			"AliExpress · Temu",
			"Taobao · Tmall",
			"Mercari · Rakuten",
			"Farfetch · SSENSE",
			"iHerb · eBay · 海外ショップ",
		],
		colSupport: "ご利用ガイド",
		supportLinks: [
			{ label: "5ステップ進行ガイド", to: "/#interactive-tour" },
			{ label: "返金額シミュレーター", to: "/#refund-calculator" },
			{ label: "世界の返金ルート", to: "/#global-network" },
			{ label: "10MB写真の暗号化案内", to: "/settings" },
		],
		colAccount: "アカウント管理",
		accountLinks: [
			{ label: "ログイン · 新規登録", to: "/auth" },
			{ label: "自動作成機能の設定", to: "/settings" },
			{ label: "記録のバックアップ保存", to: "/settings" },
			{ label: "アカウントと写真の削除", to: "/settings" },
		],
		colLanguage: "対応言語",
		colSafety: "消費者保護の原則",
		safetyItems: ["ご本人以外の写真閲覧を遮断", "カード取消の2段階確認"],
		companyInfoLine1:
			"ReLo（リロ）海外通販 消費者返金サポート  |  対応通貨: USD · EUR · JPY · CNY · KRW · GBP · CAD · AUD",
		companyInfoLine2:
			"注文レシートと不良写真（最大10MB）はご本人のアカウントにのみ分離・暗号化保管され、設定からいつでも即時削除できます。",
		privacyBold: "プライバシーポリシー",
		terms: "利用規約",
		dataSafety: "写真データ保護方針",
		consumerGuide: "海外カード取消ガイド",
		disputeNotice: "消費者保護基準",
	},
	pages: {
		wizardTitle: "3分かんたん返金申請",
		wizardPrev: "前のステップ",
		wizardNext: "次のステップへ",
		wizardSubmit: "返金申請を登録する",
		myClaimsTitle: "返金履歴",
		myClaimsSub:
			"申請した金額から実際のカード取消・入金完了までひと目で確認できます。",
		myClaimsNewBtn: "新しく申請",
		sumClaimed: "申請した合計額",
		sumRecovered: "入金確認済み",
		sumRemaining: "残りの受取予定額",
		authTitle: "海外通販の返金記録を安全に保管",
		settingsTitle: "アカウントとプライバシー設定",
	},
};
