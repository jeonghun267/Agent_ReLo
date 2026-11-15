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
		"켜 두면 영수증을 읽어 주문 정보를 채우고, 해외 쇼핑몰에 보낼 외국어 메시지를 써 드려요. 언제든 끌 수 있어요.",
	aiTurnOn: "AI 도우미 켜기 (동의)",
	aiTurnOff: "AI 도우미 끄기 (지금 켜져 있어요)",
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
		"When it is on, it reads your receipt to fill in the order details and writes the message for the overseas shop. You can turn it off any time.",
	aiTurnOn: "Turn the AI helper on (I agree)",
	aiTurnOff: "Turn the AI helper off (it is on now)",
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
		"オンにすると、領収書を読み取って注文情報を入力し、海外ショップに送る外国語メッセージを書きます。いつでもオフにできます。",
	aiTurnOn: "AIアシスタントをオンにする（同意）",
	aiTurnOff: "AIアシスタントをオフにする（現在オン）",
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
		"开启后，它会读取小票填好订单信息，并写出发给海外商城的外语留言。随时可以关闭。",
	aiTurnOn: "开启 AI 助手（同意）",
	aiTurnOff: "关闭 AI 助手（目前已开启）",
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
	toastExported: "已把退款记录下载为文件。",
	toastExportFail: "没能下载。",
	toastLoggedOut: "已退出登录。",
	toastDeleted: "账号和所有照片、小票已删除。",
};
