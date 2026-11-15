/**
 * @module client/i18n/screens/signin
 * @layer Model (Localization Dictionary — Google sign-in and passkeys)
 * @purpose The words for the two extra ways to sign in, in four languages: their buttons on
 *          the login screen, what went wrong when one fails, and the passkey list in settings.
 *          Both stay hidden until the operator switches them on.
 */

import type { DeepStringShape } from "@/client/i18n/types";

export const signinKo = {
	googleButton: "Google로 계속하기",
	passkeyButton: "패스키로 로그인",
	passkeyFail: "패스키로 로그인하지 못했어요. 다시 해 주세요.",
	/** Keyed by the code the server puts in the address when a Google sign-in fails. */
	errors: {
		google_cancelled: "Google 로그인을 취소했어요.",
		google_denied: "Google 로그인을 확인하지 못했어요. 다시 해 주세요.",
		google_unreachable: "Google에 연결하지 못했어요. 잠시 뒤 다시 해 주세요.",
		google_email_unverified: "Google에서 인증된 이메일이 있어야 해요.",
		google_unverified_account:
			"이 이메일로 만든 계정이 있어요. 비밀번호로 로그인해 이메일 인증을 마치면 Google로도 들어올 수 있어요.",
		too_many_attempts: "시도가 너무 많아요. 잠시 뒤 다시 해 주세요.",
		other: "로그인하지 못했어요. 다시 해 주세요.",
	},
	passkey: {
		title: "패스키",
		body: "비밀번호 대신 이 기기의 지문 · 얼굴 · PIN으로 로그인할 수 있어요.",
		add: "이 기기를 패스키로 등록",
		defaultName: "내 기기",
		added: "{date} 등록",
		lastUsed: "마지막 사용 {date}",
		neverUsed: "아직 쓰지 않음",
		remove: "지우기",
		removeAria: "{name} 패스키 지우기",
		empty: "등록한 패스키가 없어요.",
		unsupported: "이 브라우저에서는 패스키를 쓸 수 없어요.",
		toastAdded: "패스키를 등록했어요.",
		toastAddFail: "패스키를 등록하지 못했어요.",
		toastRemoved: "패스키를 지웠어요.",
		toastRemoveFail: "패스키를 지우지 못했어요.",
	},
} as const;

type Shape = DeepStringShape<typeof signinKo>;

export const signinEn: Shape = {
	googleButton: "Continue with Google",
	passkeyButton: "Log in with a passkey",
	passkeyFail: "Could not log in with the passkey. Please try again.",
	errors: {
		google_cancelled: "The Google sign-in was cancelled.",
		google_denied: "Could not confirm the Google sign-in. Please try again.",
		google_unreachable: "Could not reach Google. Please try again shortly.",
		google_email_unverified: "Your Google account needs a verified email.",
		google_unverified_account:
			"There is already an account with this email. Log in with its password and verify the email, then Google will work too.",
		too_many_attempts: "Too many attempts. Please try again shortly.",
		other: "Could not log you in. Please try again.",
	},
	passkey: {
		title: "Passkeys",
		body: "Log in with this device's fingerprint, face or PIN instead of a password.",
		add: "Register this device as a passkey",
		defaultName: "My device",
		added: "Added {date}",
		lastUsed: "Last used {date}",
		neverUsed: "Not used yet",
		remove: "Remove",
		removeAria: "Remove the passkey {name}",
		empty: "No passkeys registered yet.",
		unsupported: "This browser cannot use passkeys.",
		toastAdded: "Passkey registered.",
		toastAddFail: "Could not register the passkey.",
		toastRemoved: "Passkey removed.",
		toastRemoveFail: "Could not remove the passkey.",
	},
};

export const signinJa: Shape = {
	googleButton: "Google で続ける",
	passkeyButton: "パスキーでログイン",
	passkeyFail: "パスキーでログインできませんでした。もう一度お試しください。",
	errors: {
		google_cancelled: "Google ログインをキャンセルしました。",
		google_denied:
			"Google ログインを確認できませんでした。もう一度お試しください。",
		google_unreachable:
			"Google に接続できませんでした。少ししてからもう一度お試しください。",
		google_email_unverified: "Google で認証済みのメールアドレスが必要です。",
		google_unverified_account:
			"このメールアドレスで作られたアカウントがあります。パスワードでログインしてメール認証を済ませると、Google でも入れます。",
		too_many_attempts:
			"試行回数が多すぎます。少ししてからもう一度お試しください。",
		other: "ログインできませんでした。もう一度お試しください。",
	},
	passkey: {
		title: "パスキー",
		body: "パスワードの代わりに、この端末の指紋・顔・PIN でログインできます。",
		add: "この端末をパスキーとして登録",
		defaultName: "自分の端末",
		added: "{date} 登録",
		lastUsed: "最終使用 {date}",
		neverUsed: "まだ使っていません",
		remove: "削除",
		removeAria: "パスキー {name} を削除",
		empty: "登録したパスキーはありません。",
		unsupported: "このブラウザではパスキーを使えません。",
		toastAdded: "パスキーを登録しました。",
		toastAddFail: "パスキーを登録できませんでした。",
		toastRemoved: "パスキーを削除しました。",
		toastRemoveFail: "パスキーを削除できませんでした。",
	},
};

export const signinZh: Shape = {
	googleButton: "使用 Google 继续",
	passkeyButton: "用通行密钥登录",
	passkeyFail: "没能用通行密钥登录，请再试一次。",
	errors: {
		google_cancelled: "已取消 Google 登录。",
		google_denied: "没能确认 Google 登录，请再试一次。",
		google_unreachable: "没能连接 Google，请稍后再试。",
		google_email_unverified: "需要在 Google 验证过的邮箱。",
		google_unverified_account:
			"这个邮箱已经有账号了。请用密码登录并完成邮箱验证，之后也可以用 Google 登录。",
		too_many_attempts: "尝试次数太多，请稍后再试。",
		other: "没能登录，请再试一次。",
	},
	passkey: {
		title: "通行密钥",
		body: "可以用这台设备的指纹、面容或 PIN 代替密码登录。",
		add: "把这台设备登记为通行密钥",
		defaultName: "我的设备",
		added: "{date} 登记",
		lastUsed: "上次使用 {date}",
		neverUsed: "尚未使用",
		remove: "删除",
		removeAria: "删除通行密钥 {name}",
		empty: "还没有登记通行密钥。",
		unsupported: "这个浏览器无法使用通行密钥。",
		toastAdded: "通行密钥已登记。",
		toastAddFail: "没能登记通行密钥。",
		toastRemoved: "通行密钥已删除。",
		toastRemoveFail: "没能删除通行密钥。",
	},
};
