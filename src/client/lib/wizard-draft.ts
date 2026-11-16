/**
 * @module client/lib/wizard-draft
 * @layer Model (Browser-Only Draft Storage)
 * @purpose Keeps the refund request a person is in the middle of writing in this browser,
 *          so a reload or a trip to another app does not wipe it. Text only (files cannot be
 *          kept, only their names), one draft per account, and it is gone after a week,
 *          on submit, on "start over" and on logout.
 */

import { todayLocalIso } from "@/client/lib/format";
import type { ClaimWizardFormValues } from "@/client/types";

const KEY_PREFIX = "relo_wizard_draft:";
const FORMAT = 1;
const MAX_AGE_MS = 7 * 24 * 60 * 60 * 1000;
const CURRENCIES = ["USD", "EUR", "GBP", "JPY", "CNY", "KRW", "CAD", "AUD"];
const KINDS = ["refund", "exchange", "repair"];

export interface WizardDraft {
	values: ClaimWizardFormValues;
	step: number;
	/** Names of the files that were attached; the files themselves are not kept. */
	fileNames: string[];
}

/** Storage can be blocked (private window, site data off); then drafts simply do not persist. */
function storage(): Storage | null {
	try {
		return window.localStorage;
	} catch {
		return null;
	}
}

const text = (value: unknown, max: number): string =>
	typeof value === "string" ? value.slice(0, max) : "";

const quantity = (value: unknown): number =>
	typeof value === "number" && Number.isInteger(value) && value >= 1
		? Math.min(value, 10000)
		: 1;

/** Rebuilds the form values from stored data, keeping only what the form can hold. */
function readValues(raw: unknown): ClaimWizardFormValues | null {
	if (!raw || typeof raw !== "object") return null;
	const v = raw as Record<string, unknown>;
	if (!CURRENCIES.includes(v.currency as string)) return null;
	if (!KINDS.includes(v.kind as string)) return null;
	return {
		vendor: text(v.vendor, 100),
		vendorUrl: text(v.vendorUrl, 300),
		orderRef: text(v.orderRef, 100),
		orderedOn: /^\d{4}-\d{2}-\d{2}$/.test(text(v.orderedOn, 10))
			? text(v.orderedOn, 10)
			: todayLocalIso(),
		title: text(v.title, 150),
		sku: text(v.sku, 100),
		orderedQty: quantity(v.orderedQty),
		claimQty: quantity(v.claimQty),
		currency: v.currency as ClaimWizardFormValues["currency"],
		claimedAmount: text(v.claimedAmount, 20),
		kind: v.kind as ClaimWizardFormValues["kind"],
		issue: text(v.issue, 3000),
		issueEnglish: text(v.issueEnglish, 3000),
	};
}

/** True once the person has typed something worth bringing back. */
export function isWorthKeeping(draft: WizardDraft): boolean {
	const v = draft.values;
	return (
		draft.step > 1 ||
		[v.vendor, v.orderRef, v.title, v.claimedAmount, v.issue, v.issueEnglish]
			.map((value) => (value ?? "").trim())
			.some((value) => value.length > 0)
	);
}

export function loadWizardDraft(userId: string): WizardDraft | null {
	const store = storage();
	if (!store) return null;
	const key = KEY_PREFIX + userId;
	try {
		const parsed = JSON.parse(store.getItem(key) ?? "null") as {
			format?: unknown;
			savedAt?: unknown;
			step?: unknown;
			fileNames?: unknown;
			values?: unknown;
		} | null;
		const values = readValues(parsed?.values);
		const fresh =
			typeof parsed?.savedAt === "number" &&
			Date.now() - parsed.savedAt < MAX_AGE_MS;
		if (!parsed || parsed.format !== FORMAT || !fresh || !values) {
			store.removeItem(key);
			return null;
		}
		const step =
			typeof parsed.step === "number" && Number.isInteger(parsed.step)
				? Math.min(5, Math.max(1, parsed.step))
				: 1;
		const fileNames = Array.isArray(parsed.fileNames)
			? parsed.fileNames
					.filter((name): name is string => typeof name === "string")
					.slice(0, 20)
			: [];
		const draft = { values, step, fileNames };
		return isWorthKeeping(draft) ? draft : null;
	} catch {
		store.removeItem(key);
		return null;
	}
}

export function saveWizardDraft(userId: string, draft: WizardDraft): void {
	const store = storage();
	if (!store) return;
	try {
		if (!isWorthKeeping(draft)) {
			store.removeItem(KEY_PREFIX + userId);
			return;
		}
		store.setItem(
			KEY_PREFIX + userId,
			JSON.stringify({ format: FORMAT, savedAt: Date.now(), ...draft }),
		);
	} catch {
		// Storage full or blocked: the draft just is not kept.
	}
}

export function clearWizardDraft(userId: string): void {
	try {
		storage()?.removeItem(KEY_PREFIX + userId);
	} catch {
		// Nothing to clear.
	}
}

/** On logout: nothing a person typed stays behind in a shared browser. */
export function clearAllWizardDrafts(): void {
	const store = storage();
	if (!store) return;
	try {
		const keys: string[] = [];
		for (let i = 0; i < store.length; i += 1) {
			const key = store.key(i);
			if (key?.startsWith(KEY_PREFIX)) keys.push(key);
		}
		for (const key of keys) store.removeItem(key);
	} catch {
		// Nothing to clear.
	}
}
