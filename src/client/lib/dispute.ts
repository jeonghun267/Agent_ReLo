/**
 * @module client/lib/dispute
 * @layer Model (Dispute Help: Closing Days & Summary Text)
 * @purpose Works out, from the order date, the earliest day a card chargeback or a PayPal
 *          dispute could close, and writes the plain-text summary of a refund, an exchange or
 *          a repair (order, problem, what was sent and answered, what came back, saved files)
 *          to paste into a form.
 */

import type { TranslationDictionary } from "@/client/i18n";
import { receivedRows } from "@/client/lib/claim-progress";
import { replyKindLabel } from "@/client/lib/claim-words";
import {
	fill,
	formatLocalDate,
	formatMinorMoney,
	todayLocalIso,
} from "@/client/lib/format";
import type { ClaimView } from "@/client/types";

/** VISA, Mastercard and AMEX usually take a chargeback request for about this long. */
export const CARD_WINDOW_DAYS = 120;
/** UnionPay cards and PayPal usually allow this long. */
export const LONG_WINDOW_DAYS = 180;

const DAY_MS = 86_400_000;

export interface DisputeDeadline {
	/** The last day, as YYYY-MM-DD. */
	date: string;
	/** Days from today to that day; negative once it has gone by. */
	daysLeft: number;
}

/**
 * The window counted from the order date. Card companies sometimes count from the day the
 * item was due instead, which is later, so this is the earliest (safest) day to show.
 */
export function disputeDeadline(
	orderedOn: string,
	windowDays: number,
	today: Date = new Date(),
): DisputeDeadline | null {
	const parts = /^(\d{4})-(\d{2})-(\d{2})$/.exec(orderedOn);
	if (!parts) return null;
	const start = Date.UTC(
		Number(parts[1]),
		Number(parts[2]) - 1,
		Number(parts[3]),
	);
	const end = start + windowDays * DAY_MS;
	const now = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
	return {
		date: new Date(end).toISOString().slice(0, 10),
		daysLeft: Math.round((end - now) / DAY_MS),
	};
}

/** One line of a long text: the first sentence or two, cut to a readable length. */
function brief(text: string): string {
	const oneLine = text.replace(/\s+/g, " ").trim();
	return oneLine.length > 220 ? `${oneLine.slice(0, 217)}...` : oneLine;
}

/** The text a person pastes into a marketplace dispute, a chargeback request or a counselling form. */
export function buildDisputeSummary(
	claim: ClaimView,
	t: TranslationDictionary,
	bcp47: string,
): string {
	const s = t.detail.dispute.summary;
	const k = t.kinds.summary;
	const p = t.kinds.progress;
	const isRefund = claim.kind === "refund";
	const money = (minor: number) => formatMinorMoney(minor, claim.currency);
	const day = (iso: string) => formatLocalDate(iso, bcp47);
	const item = claim.items[0];

	const lines = [
		s.heading,
		`${s.shop}: ${claim.vendor}`,
		`${t.shared.orderNo}: ${claim.orderRef}`,
		`${s.orderedOn}: ${day(claim.orderedOn)}`,
		`${s.item}: ${claim.title}${
			item
				? ` (${fill(s.quantity, { claim: item.claimQty, ordered: item.orderedQty })})`
				: ""
		}`,
		`${s.request}: ${t.shared.kinds[claim.kind]} · ${isRefund ? "" : `${p.itemPrice} `}${money(claim.claimed)}`,
		`${s.issue}: ${brief(claim.issue)}`,
	];
	if (claim.issueEnglish.trim()) {
		lines.push(`${s.issueEnglish}: ${brief(claim.issueEnglish)}`);
	}

	const happened: Array<{ at: string; text: string }> = [];
	for (const draft of claim.drafts) {
		if (draft.submittedAt)
			happened.push({ at: draft.submittedAt, text: s.sent });
	}
	for (const reply of claim.replies) {
		const said = brief(reply.summaryKo || reply.body);
		happened.push({
			at: reply.recordedAt,
			text: `${fill(s.reply, { kind: replyKindLabel(t, reply.kind, claim.kind) })}${said ? `: ${said}` : ""}`,
		});
	}
	// A record that was undone did not happen as far as the summary goes.
	for (const { entry, undone } of receivedRows(claim)) {
		if (undone) continue;
		let text = k.repairLine;
		if (entry.kind === "cash")
			text = `${s.receivedLine} ${money(entry.amount)}`;
		if (entry.kind === "goods") text = fill(k.goodsLine, { n: entry.quantity });
		happened.push({ at: entry.receivedOn, text });
	}
	// Order by the day each line shows: a time of day becomes the reader's date.
	const dayKey = (at: string) =>
		at.length > 10 ? todayLocalIso(new Date(at)) : at;
	happened.sort((a, b) => dayKey(a.at).localeCompare(dayKey(b.at)));

	lines.push("", s.timeline);
	if (happened.length === 0) lines.push(s.noTimeline);
	for (const event of happened)
		lines.push(`- ${day(event.at)} · ${event.text}`);

	lines.push("");
	if (isRefund) {
		lines.push(
			`${s.agreed}: ${claim.agreed !== null ? money(claim.agreed) : s.none}`,
			`${s.received}: ${money(claim.summary.cash)}`,
		);
	} else if (claim.kind === "exchange") {
		const got = claim.summary.goods;
		const total = claim.summary.requestedQty;
		lines.push(`${p.goodsLabel}: ${fill(k.goodsOf, { got, total })}`);
	} else {
		const result = claim.summary.repair ? p.repairDone : p.repairPending;
		lines.push(`${p.repairLabel}: ${result}`);
	}
	lines.push(
		`${s.files}: ${claim.files.map((file) => file.name).join(", ") || s.none}`,
	);
	return lines.join("\n");
}
