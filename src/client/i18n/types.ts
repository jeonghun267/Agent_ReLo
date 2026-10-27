/**
 * @module client/i18n/types
 * @layer Model (Localization Schema)
 * @purpose Defines supported locale codes (KO, EN, ZH, JA) and recursively widens
 *          the default Korean dictionary shape so TypeScript enforces 100% key parity
 *          across every language file.
 */

import type { koMessages } from "@/client/i18n/ko";

export type LocaleCode = "ko" | "en" | "zh" | "ja";

export interface LocaleOption {
	code: LocaleCode;
	shortLabel: string;
	nativeName: string;
	bcp47: string;
}

export const LOCALE_OPTIONS: ReadonlyArray<LocaleOption> = [
	{ code: "ko", shortLabel: "KR", nativeName: "한국어", bcp47: "ko-KR" },
	{ code: "en", shortLabel: "EN", nativeName: "English", bcp47: "en-US" },
	{ code: "zh", shortLabel: "ZH", nativeName: "中文", bcp47: "zh-CN" },
	{ code: "ja", shortLabel: "JA", nativeName: "日本語", bcp47: "ja-JP" },
] as const;

type DeepStringShape<T> = T extends string
	? string
	: T extends ReadonlyArray<infer U>
		? ReadonlyArray<DeepStringShape<U>>
		: T extends object
			? { readonly [K in keyof T]: DeepStringShape<T[K]> }
			: T;

export type TranslationDictionary = DeepStringShape<typeof koMessages>;
