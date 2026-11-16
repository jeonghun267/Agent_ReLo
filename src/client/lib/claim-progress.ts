/**
 * @module client/lib/claim-progress
 * @layer Model (What Has Come Back So Far)
 * @purpose Answers, for a refund, an exchange or a repair alike: how far along it is, whether
 *          everything has come back, whether it still takes new records, which received
 *          entries still count, and the facts to send back when one of them is edited.
 */

import { minorToDecimalString } from "@/client/lib/format";
import type {
	ClaimMutationInput,
	ClaimView,
	LedgerEntry,
} from "@/client/types";

function percent(part: number, whole: number): number {
	return whole > 0 ? Math.min(100, Math.round((part / whole) * 100)) : 0;
}

/** 0 to 100: money for a refund, items for an exchange, done or not for a repair. */
export function receivedPercent(claim: ClaimView): number {
	const { summary } = claim;
	if (claim.kind === "exchange")
		return percent(summary.goods, summary.requestedQty);
	if (claim.kind === "repair") return summary.repair ? 100 : 0;
	return percent(summary.cash, claim.claimed);
}

/** True when nothing more is left to record as received. */
export function isAllReceived(claim: ClaimView): boolean {
	const { summary } = claim;
	if (claim.kind === "exchange") return summary.goods >= summary.requestedQty;
	if (claim.kind === "repair") return summary.repair;
	return (
		claim.agreed !== null && claim.agreed > 0 && summary.cash >= claim.agreed
	);
}

/** True while something that still counts has been recorded (an undone record does not). */
export function hasReceived(claim: ClaimView): boolean {
	const { summary } = claim;
	return summary.cash > 0 || summary.goods > 0 || summary.repair;
}

/** A claim that takes no new records: in the trash, finished, or stopped. */
export function isLocked(claim: ClaimView): boolean {
	return (
		claim.deleted || claim.state === "completed" || claim.state === "waived"
	);
}

export interface ReceivedRow {
	entry: LedgerEntry;
	/** Taken back later; it stays in the list but no longer counts. */
	undone: boolean;
}

/** Each "I received it" record, newest as the server sends them, marked if it was undone. */
export function receivedRows(claim: ClaimView): ReceivedRow[] {
	const undone = new Set(claim.ledger.map((entry) => entry.reverses));
	return claim.ledger
		.filter((entry) => entry.kind !== "reversal")
		.map((entry) => ({ entry, undone: undone.has(entry.id) }));
}

/** The claim's own facts in the shape the server takes back, ready to change one of them. */
export function claimToInput(claim: ClaimView): ClaimMutationInput {
	return {
		title: claim.title,
		vendor: claim.vendor,
		vendorUrl: claim.vendorUrl,
		orderRef: claim.orderRef,
		orderedOn: claim.orderedOn,
		kind: claim.kind,
		currency: claim.currency,
		claimedAmount: minorToDecimalString(claim.claimed, claim.currency),
		agreedAmount: minorToDecimalString(claim.agreed, claim.currency),
		issue: claim.issue,
		issueEnglish: claim.issueEnglish,
		deadline: claim.deadline ?? "",
		deadlineQuote: claim.deadlineQuote,
		deadlineZone: claim.deadlineZone,
		items: claim.items.map((item) => ({
			name: item.name,
			sku: item.sku,
			orderedQty: item.orderedQty,
			claimQty: item.claimQty,
			unitPrice: minorToDecimalString(item.unitPrice, claim.currency),
		})),
	};
}
