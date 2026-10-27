/**
 * @module client/i18n/I18nProvider
 * @layer ViewModel (Localization State & Language Switcher)
 * @purpose Provides reactive 4-language switching (KO, EN, ZH, JA) with localStorage
 *          persistence, HTML lang attribute synchronization, and accessible header/footer
 *          switcher controls.
 */

import { Check, ChevronDown, Globe } from "lucide-react";
import {
	createContext,
	type ReactNode,
	useCallback,
	useContext,
	useEffect,
	useMemo,
	useRef,
	useState,
} from "react";
import { enMessages } from "@/client/i18n/en";
import { jaMessages } from "@/client/i18n/ja";
import { koMessages } from "@/client/i18n/ko";
import {
	LOCALE_OPTIONS,
	type LocaleCode,
	type LocaleOption,
	type TranslationDictionary,
} from "@/client/i18n/types";
import { zhMessages } from "@/client/i18n/zh";
import { cn } from "@/lib/utils";

const STORAGE_KEY = "relo_ui_locale";

const DICTIONARIES: Record<LocaleCode, TranslationDictionary> = {
	ko: koMessages,
	en: enMessages,
	zh: zhMessages,
	ja: jaMessages,
};

function isLocaleCode(value: string | null | undefined): value is LocaleCode {
	return value === "ko" || value === "en" || value === "zh" || value === "ja";
}

function readInitialLocale(): LocaleCode {
	if (typeof window === "undefined") {
		return "ko";
	}
	const paramLang = new URLSearchParams(window.location.search).get("lang");
	if (isLocaleCode(paramLang)) {
		return paramLang;
	}
	try {
		const saved = window.localStorage.getItem(STORAGE_KEY);
		if (isLocaleCode(saved)) {
			return saved;
		}
	} catch {
		// Ignore private-mode storage restrictions
	}
	return "ko";
}

interface I18nContextValue {
	locale: LocaleCode;
	localeOption: LocaleOption;
	t: TranslationDictionary;
	setLocale: (next: LocaleCode) => void;
}

const I18nContext = createContext<I18nContextValue | null>(null);

export function I18nProvider({ children }: { children: ReactNode }) {
	const [locale, setLocaleState] = useState<LocaleCode>(readInitialLocale);

	const setLocale = useCallback((next: LocaleCode) => {
		setLocaleState(next);
		try {
			window.localStorage.setItem(STORAGE_KEY, next);
		} catch {
			// Ignore private-mode storage restrictions
		}
	}, []);

	const localeOption = useMemo(
		() =>
			LOCALE_OPTIONS.find((item) => item.code === locale) ?? LOCALE_OPTIONS[0],
		[locale],
	);

	useEffect(() => {
		document.documentElement.lang = localeOption.bcp47;
	}, [localeOption]);

	const value = useMemo<I18nContextValue>(
		() => ({
			locale,
			localeOption,
			t: DICTIONARIES[locale],
			setLocale,
		}),
		[locale, localeOption, setLocale],
	);

	return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nContextValue {
	const ctx = useContext(I18nContext);
	if (!ctx) {
		throw new Error("useI18n must be used inside I18nProvider");
	}
	return ctx;
}

interface LanguageSwitcherProps {
	variant?: "header" | "footer";
	className?: string;
}

export function LanguageSwitcher({
	variant = "header",
	className,
}: LanguageSwitcherProps) {
	const { locale, localeOption, setLocale, t } = useI18n();
	const [open, setOpen] = useState(false);
	const containerRef = useRef<HTMLDivElement | null>(null);

	useEffect(() => {
		if (!open) return;
		const onPointerDown = (event: MouseEvent) => {
			if (
				containerRef.current &&
				!containerRef.current.contains(event.target as Node)
			) {
				setOpen(false);
			}
		};
		const onKeyDown = (event: KeyboardEvent) => {
			if (event.key === "Escape") {
				setOpen(false);
			}
		};
		window.addEventListener("mousedown", onPointerDown);
		window.addEventListener("keydown", onKeyDown);
		return () => {
			window.removeEventListener("mousedown", onPointerDown);
			window.removeEventListener("keydown", onKeyDown);
		};
	}, [open]);

	if (variant === "footer") {
		return (
			<fieldset
				aria-label={t.nav.languageLabel}
				className={cn("m-0 flex flex-wrap gap-1.5 border-0 p-0", className)}
			>
				{LOCALE_OPTIONS.map((option) => {
					const active = option.code === locale;
					return (
						<button
							key={option.code}
							type="button"
							onClick={() => setLocale(option.code)}
							data-testid={`footer-lang-${option.code}`}
							className={cn(
								"cursor-pointer rounded-lg px-2.5 py-1.5 text-xs font-semibold transition-colors",
								active
									? "bg-white text-[#191f28] shadow-2xs"
									: "bg-white/10 text-slate-200 hover:bg-white/18 hover:text-white",
							)}
						>
							{option.nativeName}
						</button>
					);
				})}
			</fieldset>
		);
	}

	return (
		<div ref={containerRef} className={cn("relative", className)}>
			<button
				type="button"
				aria-label={`${localeOption.nativeName} · ${t.nav.languageLabel}`}
				aria-expanded={open}
				aria-haspopup="listbox"
				data-testid="header-language-trigger"
				onClick={() => setOpen((prev) => !prev)}
				className="inline-flex min-h-9 cursor-pointer items-center gap-1.5 rounded-full border border-relo-line bg-white px-3 py-1.5 text-xs font-semibold text-relo-ink transition-colors hover:bg-relo-sunken"
			>
				<Globe className="h-3.5 w-3.5 text-relo-brand" aria-hidden="true" />
				<span className="hidden sm:inline">{localeOption.nativeName}</span>
				<span className="sm:hidden">{localeOption.shortLabel}</span>
				<ChevronDown
					className={cn(
						"h-3.5 w-3.5 text-relo-muted transition-transform",
						open && "rotate-180",
					)}
					aria-hidden="true"
				/>
			</button>

			{open ? (
				<div
					role="listbox"
					aria-label={t.nav.languageLabel}
					className="absolute right-0 z-50 mt-2 w-40 rounded-2xl border border-relo-line bg-white p-1.5 shadow-[0_18px_40px_-14px_rgba(15,23,42,0.22)]"
				>
					{LOCALE_OPTIONS.map((option) => {
						const active = option.code === locale;
						return (
							<button
								key={option.code}
								type="button"
								role="option"
								aria-selected={active}
								data-testid={`header-lang-${option.code}`}
								onClick={() => {
									setLocale(option.code);
									setOpen(false);
								}}
								className={cn(
									"flex w-full cursor-pointer items-center justify-between rounded-xl px-3 py-2 text-left text-xs font-semibold transition-colors",
									active
										? "bg-relo-brand-soft text-relo-brand"
										: "text-relo-body hover:bg-relo-sunken hover:text-relo-ink",
								)}
							>
								<span>{option.nativeName}</span>
								{active ? (
									<Check className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
								) : (
									<span className="text-[11px] font-medium text-relo-muted">
										{option.shortLabel}
									</span>
								)}
							</button>
						);
					})}
				</div>
			) : null}
		</div>
	);
}
