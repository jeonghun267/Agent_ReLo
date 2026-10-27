/**
 * @module client/i18n
 * @layer Model & ViewModel Barrel
 * @purpose Public entry point for localization types, provider, hook, and language switcher.
 */

export {
	I18nProvider,
	LanguageSwitcher,
	useI18n,
} from "@/client/i18n/I18nProvider";
export {
	LOCALE_OPTIONS,
	type LocaleCode,
	type LocaleOption,
	type TranslationDictionary,
} from "@/client/i18n/types";
