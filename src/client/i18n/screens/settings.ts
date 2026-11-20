/**
 * @module client/i18n/screens/settings
 * @layer Model (Localization Dictionary — settings)
 * @purpose The words of the settings screen in four languages: the profile, the AI helper
 *          switch, the download of one's own records, and leaving the service.
 */

import type { DeepStringShape } from "@/client/i18n/types";

export const settingsKo = {
	loading: "계정 정보를 불러오고 있어요...",
	guestSpeech:
		"계정과 개인정보를 관리하는 곳이에요. 로그인한 뒤에 쓸 수 있어요.",
	eyebrow: "내 정보 · 개인정보",
	joined: "가입일 {date}",
	verified: "이메일 인증 완료",
	unverified: "이메일 인증 전",
	logout: "로그아웃",
	aiEyebrow: "ReLo AI 도우미",
	aiTitle: "영수증 자동 읽기와 외국어 메시지 쓰기",
	aiBody:
		"켜 두면 영수증을 읽어 주문 정보를 채우고, 해외 쇼핑몰에 보낼 외국어 메시지를 써 드려요. 쓸 때마다 주문 내용, 붙여 넣은 답장, 고른 영수증 파일이 해외에 있는 Google의 AI로 보내져요. 언제든 끌 수 있어요.",
	aiTurnOn: "AI 도우미 켜기",
	aiTurnOff: "AI 도우미 끄기 (지금 켜져 있어요)",
	/** The notice shown before the first AI request. It lists everything the one consent covers. */
	consent: {
		title: "AI 도우미를 쓰려면 동의가 필요해요",
		lead: "ReLo의 AI 도우미는 Google의 AI(Gemini)로 일해요. 그래서 아래 내용이 해외에 있는 Google 서버로 보내져요.",
		sentTitle: "보내는 것",
		sentClaim: "적어 둔 주문 내용 (쇼핑몰, 주문번호, 상품, 금액, 문제 설명)",
		sentReply: "붙여 넣은 쇼핑몰 답장",
		sentFile:
			"읽어 달라고 고른 영수증 · 주문서 파일. 파일에 적힌 이름과 주소도 함께 보내져요.",
		notSent: "가입할 때 적은 이름 · 이메일 · 비밀번호는 보내지 않아요.",
		control:
			"AI가 만든 내용은 직접 저장하거나, AI가 물을 때 허락하기 전에는 기록에 들어가지 않아요. 동의는 설정에서 언제든 끌 수 있고, 동의하지 않아도 직접 적어서 그대로 쓸 수 있어요.",
		agree: "동의하고 계속하기",
		decline: "동의하지 않을게요",
		saveFail: "동의를 저장하지 못했어요. 잠시 뒤 다시 해 주세요.",
		policyLink: "개인정보 처리방침 보기",
	},
	/** The policy and terms pages. Their text is Korean; other languages say so in one line. */
	legal: {
		koreanOnly: "이 문서는 한국어로 제공됩니다.",
		seePrivacy: "개인정보 처리방침 보기",
		seeTerms: "서비스 이용약관 보기",
	},
	exportTitle: "내 환불 기록 내려받기",
	exportBody:
		"등록한 환불 내역과 기록을 언제든 내 기기에 파일로 받아 둘 수 있어요.",
	exportButton: "내 기록 전체 내려받기",
	deleteTitle: "회원 탈퇴",
	deleteBody:
		"탈퇴하면 내 환불 내역과 올린 영수증 · 사진이 바로 지워지고 되돌릴 수 없어요.",
	deleteStart: "회원 탈퇴하기",
	passwordLabel: "본인 확인용 비밀번호",
	passwordPlaceholder: "지금 쓰는 비밀번호",
	passwordWrong: "비밀번호가 맞지 않아요.",
	cancel: "취소",
	deleteConfirm: "계정 지우기",
	deleteFail: "탈퇴하지 못했어요. 잠시 뒤 다시 해 주세요.",
	toastAiOn: "AI 도우미를 켰어요.",
	toastAiOff: "AI 도우미를 껐어요.",
	toastSaveFail: "설정을 저장하지 못했어요.",
	noticeMailOnNote:
		"알림 메일 받기가 켜져 있어요. AI가 허락을 기다리는데 한동안 답이 없으면, 인증한 이메일로 한 번 알려 드려요. 메일에는 주문 내용을 적지 않아요.",
	noticeMailOffNote:
		"알림 메일 받기가 꺼져 있어요. AI가 허락을 기다려도 메일을 보내지 않아요.",
	noticeMailUnverifiedNote:
		"이메일 인증 전이라 지금은 알림 메일을 보내지 않아요. 인증을 마치면, AI가 허락을 기다리는데 한동안 답이 없을 때 한 번 알려 드려요.",
	noticeMailTurnOn: "알림 메일 켜기",
	noticeMailTurnOff: "알림 메일 끄기",
	toastNoticeMailOn: "알림 메일을 켰어요.",
	toastNoticeMailOff: "알림 메일을 껐어요.",
	toastExported: "내 환불 기록을 파일로 내려받았어요.",
	toastExportFail: "내려받지 못했어요.",
	toastLoggedOut: "로그아웃했어요.",
	toastDeleted: "계정과 모든 사진 · 영수증을 지웠어요.",
} as const;

type Shape = DeepStringShape<typeof settingsKo>;

export const settingsEn: Shape = {
	loading: "Loading your account...",
	guestSpeech:
		"This is where you manage your account and personal data. Log in to use it.",
	eyebrow: "My details · Privacy",
	joined: "Joined {date}",
	verified: "Email verified",
	unverified: "Email not verified",
	logout: "Log out",
	aiEyebrow: "ReLo AI helper",
	aiTitle: "Read receipts and write messages for you",
	aiBody:
		"When it is on, it reads your receipt to fill in the order details and writes the message for the overseas shop. Each time you use it, the order details, the reply you paste and the receipt file you choose are sent to Google's AI outside Korea. You can turn it off any time.",
	aiTurnOn: "Turn the AI helper on",
	aiTurnOff: "Turn the AI helper off (it is on now)",
	consent: {
		title: "The AI helper needs your agreement first",
		lead: "ReLo's AI helper works with Google's AI (Gemini), so the things below are sent to Google's servers outside Korea.",
		sentTitle: "What is sent",
		sentClaim:
			"The order details you entered (shop, order number, product, amount, what went wrong)",
		sentReply: "The shop's reply you paste in",
		sentFile:
			"The receipt or order file you choose to have read. A name or address printed on it is sent with it.",
		notSent: "The name, email and password you signed up with are not sent.",
		control:
			"Nothing the AI makes goes into your records until you save it yourself or allow it when the AI asks. You can turn this off any time in Settings, and without it you can still type everything in yourself.",
		agree: "Agree and continue",
		decline: "I don't agree",
		saveFail: "Could not save your answer. Please try again shortly.",
		policyLink: "Read the privacy policy",
	},
	legal: {
		koreanOnly:
			"This document is provided in Korean, the language that governs it.",
		seePrivacy: "Read the privacy policy",
		seeTerms: "Read the terms of service",
	},
	exportTitle: "Download my refund records",
	exportBody:
		"Keep a copy of your refunds and their records as a file on your device, any time.",
	exportButton: "Download all my records",
	deleteTitle: "Delete my account",
	deleteBody:
		"Your refunds and the receipts and photos you uploaded are erased at once and cannot be brought back.",
	deleteStart: "Delete my account",
	passwordLabel: "Password, to confirm it is you",
	passwordPlaceholder: "Your current password",
	passwordWrong: "That password is not right.",
	cancel: "Cancel",
	deleteConfirm: "Erase my account",
	deleteFail: "Could not delete the account. Please try again shortly.",
	toastAiOn: "The AI helper is on.",
	toastAiOff: "The AI helper is off.",
	toastSaveFail: "Could not save the setting.",
	noticeMailOnNote:
		"Notice emails are on. If the AI is left waiting for your OK for a while, it emails you once at your verified address. The email says nothing about your order.",
	noticeMailOffNote:
		"Notice emails are off. No email is sent when the AI is waiting for your OK.",
	noticeMailUnverifiedNote:
		"Your email address is not confirmed yet, so no notice email is sent for now. Once it is confirmed, the AI emails you once if it is left waiting for your OK for a while.",
	noticeMailTurnOn: "Turn notice emails on",
	noticeMailTurnOff: "Turn notice emails off",
	toastNoticeMailOn: "Notice emails are on.",
	toastNoticeMailOff: "Notice emails are off.",
	toastExported: "Your refund records were downloaded as a file.",
	toastExportFail: "Could not download.",
	toastLoggedOut: "You are logged out.",
	toastDeleted: "Your account and all photos and receipts were erased.",
};

export const settingsJa: Shape = {
	loading: "アカウント情報を読み込んでいます...",
	guestSpeech:
		"アカウントと個人情報を管理する場所です。ログインすると使えます。",
	eyebrow: "自分の情報 · 個人情報",
	joined: "登録日 {date}",
	verified: "メール認証済み",
	unverified: "メール未認証",
	logout: "ログアウト",
	aiEyebrow: "ReLo AI アシスタント",
	aiTitle: "領収書の自動読み取りと外国語メッセージの作成",
	aiBody:
		"オンにすると、領収書を読み取って注文情報を入力し、海外ショップに送る外国語メッセージを書きます。使うたびに、注文内容・貼り付けた返信・選んだ領収書ファイルが海外にあるGoogleのAIへ送られます。いつでもオフにできます。",
	aiTurnOn: "AIアシスタントをオンにする",
	aiTurnOff: "AIアシスタントをオフにする（現在オン）",
	consent: {
		title: "AIアシスタントを使うには同意が必要です",
		lead: "ReLoのAIアシスタントはGoogleのAI（Gemini）で動きます。そのため、下の内容が海外にあるGoogleのサーバーへ送られます。",
		sentTitle: "送るもの",
		sentClaim: "入力した注文内容（ショップ、注文番号、商品、金額、問題の説明）",
		sentReply: "貼り付けたショップからの返信",
		sentFile:
			"読み取りのために選んだ領収書・注文書のファイル。ファイルに書かれた氏名や住所も一緒に送られます。",
		notSent: "登録時に入力した氏名・メールアドレス・パスワードは送りません。",
		control:
			"AIが作った内容は、自分で保存するか、AIに聞かれて許可するまで記録に入りません。同意は設定からいつでもオフにでき、同意しなくても自分で入力してそのまま使えます。",
		agree: "同意して続ける",
		decline: "同意しません",
		saveFail:
			"同意を保存できませんでした。少ししてからもう一度お試しください。",
		policyLink: "プライバシーポリシーを見る",
	},
	legal: {
		koreanOnly: "この文書は韓国語で提供されます。",
		seePrivacy: "プライバシーポリシーを見る",
		seeTerms: "利用規約を見る",
	},
	exportTitle: "返金の記録をダウンロード",
	exportBody:
		"登録した返金とその記録を、いつでも自分の端末にファイルで保存できます。",
	exportButton: "すべての記録をダウンロード",
	deleteTitle: "退会",
	deleteBody:
		"退会すると、返金の内容とアップロードした領収書・写真がすぐに削除され、元に戻せません。",
	deleteStart: "退会する",
	passwordLabel: "本人確認用のパスワード",
	passwordPlaceholder: "現在のパスワード",
	passwordWrong: "パスワードが違います。",
	cancel: "キャンセル",
	deleteConfirm: "アカウントを削除",
	deleteFail: "退会できませんでした。少ししてからもう一度お試しください。",
	toastAiOn: "AIアシスタントをオンにしました。",
	toastAiOff: "AIアシスタントをオフにしました。",
	toastSaveFail: "設定を保存できませんでした。",
	noticeMailOnNote:
		"「お知らせメールを受け取る」がオンです。AIが許可を待ったまましばらくお返事がないときは、確認済みのメールアドレスに一度だけお知らせします。メールに注文の内容は書きません。",
	noticeMailOffNote:
		"「お知らせメールを受け取る」がオフです。AIが許可を待っていてもメールは送りません。",
	noticeMailUnverifiedNote:
		"メールアドレスの確認がまだのため、今はお知らせメールを送りません。確認が済むと、AIが許可を待ったまましばらくお返事がないときに一度だけお知らせします。",
	noticeMailTurnOn: "お知らせメールをオンにする",
	noticeMailTurnOff: "お知らせメールをオフにする",
	toastNoticeMailOn: "お知らせメールをオンにしました。",
	toastNoticeMailOff: "お知らせメールをオフにしました。",
	toastExported: "返金の記録をファイルでダウンロードしました。",
	toastExportFail: "ダウンロードできませんでした。",
	toastLoggedOut: "ログアウトしました。",
	toastDeleted: "アカウントとすべての写真・領収書を削除しました。",
};

export const settingsZh: Shape = {
	loading: "正在读取账号信息...",
	guestSpeech: "这里用来管理账号和个人信息。登录后可以使用。",
	eyebrow: "我的信息 · 个人信息",
	joined: "注册于 {date}",
	verified: "邮箱已验证",
	unverified: "邮箱未验证",
	logout: "退出登录",
	aiEyebrow: "ReLo AI 助手",
	aiTitle: "自动读取小票并撰写外语留言",
	aiBody:
		"开启后，它会读取小票填好订单信息，并写出发给海外商城的外语留言。每次使用时，订单内容、粘贴的回复和所选的小票文件会发送到位于海外的 Google AI。随时可以关闭。",
	aiTurnOn: "开启 AI 助手",
	aiTurnOff: "关闭 AI 助手（目前已开启）",
	consent: {
		title: "使用 AI 助手前需要你的同意",
		lead: "ReLo 的 AI 助手使用 Google 的 AI（Gemini），所以下面的内容会发送到位于海外的 Google 服务器。",
		sentTitle: "会发送的内容",
		sentClaim: "你填写的订单内容（商城、订单号、商品、金额、问题说明）",
		sentReply: "你粘贴的商城回复",
		sentFile:
			"你选来读取的小票或订单文件。文件上写着的姓名和地址也会一起发送。",
		notSent: "注册时填写的姓名、邮箱和密码不会发送。",
		control:
			"AI 生成的内容，在你自己保存或在 AI 询问时同意之前，不会进入记录。随时可以在设置里关闭同意；不同意也可以自己填写，照常使用。",
		agree: "同意并继续",
		decline: "不同意",
		saveFail: "没能保存你的选择，请稍后再试。",
		policyLink: "查看隐私政策",
	},
	legal: {
		koreanOnly: "本文件以韩语提供。",
		seePrivacy: "查看隐私政策",
		seeTerms: "查看服务条款",
	},
	exportTitle: "下载我的退款记录",
	exportBody: "随时可以把登记的退款和相关记录以文件形式保存到自己的设备。",
	exportButton: "下载我的全部记录",
	deleteTitle: "注销账号",
	deleteBody: "注销后，你的退款内容和上传的小票、照片会立即删除，无法恢复。",
	deleteStart: "注销账号",
	passwordLabel: "用于确认身份的密码",
	passwordPlaceholder: "当前密码",
	passwordWrong: "密码不正确。",
	cancel: "取消",
	deleteConfirm: "删除账号",
	deleteFail: "没能注销，请稍后再试。",
	toastAiOn: "AI 助手已开启。",
	toastAiOff: "AI 助手已关闭。",
	toastSaveFail: "没能保存设置。",
	noticeMailOnNote:
		"“接收提醒邮件”已打开。如果 AI 等你同意等了一段时间仍没有回答，会向你已验证的邮箱发一封提醒邮件。邮件里不写订单内容。",
	noticeMailOffNote: "“接收提醒邮件”已关闭。AI 等你同意时也不会发邮件。",
	noticeMailUnverifiedNote:
		"邮箱还没有验证，所以现在不会发送提醒邮件。验证之后，如果 AI 等你同意等了一段时间仍没有回答，会发一封提醒邮件。",
	noticeMailTurnOn: "打开提醒邮件",
	noticeMailTurnOff: "关闭提醒邮件",
	toastNoticeMailOn: "已打开提醒邮件。",
	toastNoticeMailOff: "已关闭提醒邮件。",
	toastExported: "已把退款记录下载为文件。",
	toastExportFail: "没能下载。",
	toastLoggedOut: "已退出登录。",
	toastDeleted: "账号和所有照片、小票已删除。",
};
