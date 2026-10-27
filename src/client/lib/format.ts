/**
 * @module client/lib/format
 * @layer Model / Utility (Multi-Currency & Date Formatting)
 * @purpose Converts integer minor currency units into localized major amounts,
 *          split Toss-style money typography parts, dates, and human file sizes.
 */

import type { CurrencyCode } from "@/client/types/domain";

export const CURRENCY_DIGITS: Record<CurrencyCode, number> = {
	USD: 2,
	EUR: 2,
	GBP: 2,
	JPY: 0,
	CNY: 2,
	KRW: 0,
	CAD: 2,
	AUD: 2,
};

export const CURRENCY_SYMBOLS: Record<CurrencyCode, string> = {
	USD: "$",
	EUR: "€",
	GBP: "£",
	JPY: "¥",
	CNY: "¥",
	KRW: "₩",
	CAD: "CA$",
	AUD: "A$",
};

export function minorToMajor(minor: number, currency: CurrencyCode): number {
	const digits = CURRENCY_DIGITS[currency] ?? 2;
	return minor / 10 ** digits;
}

export function minorToDecimalString(
	minor: number | null,
	currency: CurrencyCode,
): string {
	if (minor === null) return "";
	const digits = CURRENCY_DIGITS[currency] ?? 2;
	const major = minor / 10 ** digits;
	return digits === 0 ? String(Math.round(major)) : major.toFixed(digits);
}

export function formatMinorMoney(
	minor: number,
	currency: CurrencyCode,
): string {
	const digits = CURRENCY_DIGITS[currency] ?? 2;
	const major = minor / 10 ** digits;
	const formatted = new Intl.NumberFormat("ko-KR", {
		minimumFractionDigits: digits,
		maximumFractionDigits: digits,
	}).format(major);
	const symbol = CURRENCY_SYMBOLS[currency] ?? `${currency} `;
	return `${symbol}${formatted}`;
}

export interface SplitMoneyParts {
	symbol: string;
	integerPart: string;
	fractionPart: string;
	fullText: string;
}

export function splitMinorMoneyParts(
	minor: number,
	currency: CurrencyCode,
): SplitMoneyParts {
	const digits = CURRENCY_DIGITS[currency] ?? 2;
	const major = minor / 10 ** digits;
	const formatted = new Intl.NumberFormat("ko-KR", {
		minimumFractionDigits: digits,
		maximumFractionDigits: digits,
	}).format(major);
	const symbol = CURRENCY_SYMBOLS[currency] ?? `${currency} `;
	const dotIdx = formatted.indexOf(".");
	const integerPart = dotIdx >= 0 ? formatted.slice(0, dotIdx) : formatted;
	const fractionPart = dotIdx >= 0 ? formatted.slice(dotIdx) : "";
	return {
		symbol,
		integerPart,
		fractionPart,
		fullText: `${symbol}${formatted}`,
	};
}

export function formatKoreanDate(isoOrDate: string | null | undefined): string {
	if (!isoOrDate) return "-";
	const parsed = new Date(isoOrDate);
	if (Number.isNaN(parsed.getTime())) return isoOrDate;
	return new Intl.DateTimeFormat("ko-KR", {
		year: "numeric",
		month: "short",
		day: "numeric",
	}).format(parsed);
}

export function formatFileSize(bytes: number): string {
	if (bytes < 1024) return `${bytes} B`;
	if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
	return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}
