/**
 * @module client/lib/claim-words
 * @layer ViewModel Helper (Refund Wording Lookup)
 * @purpose Turns what the server sends about a refund (a state, a next-step code, a history
 *          entry, a form error key) into the sentence for the reader's language, so every
 *          signed-in screen names the same thing with the same words. An exchange or a
 *          repair has its own words where a refund would talk about money.
 */

import type { LocaleCode, TranslationDictionary } from "@/client/i18n";
import type {
	ClaimKind,
	ClaimState,
	ClaimView,
	ReplyKind,
} from "@/client/types";

type HistoryKey = keyof TranslationDictionary["shared"]["history"];

/** The server stores each history entry under these names; they are record keys, not UI copy. */
const HISTORY_KEYS: Record<string, HistoryKey> = {
	"사건 등록": "created",
	"사건 정보 수정": "edited",
	"상태 변경 · awaiting": "markedSent",
	"상태 변경 · negotiating": "negotiating",
	"상태 변경 · disputed": "disputed",
	"상태 변경 · waived": "waived",
	"상태 변경 · reopen": "reopened",
	"상태 변경 · close": "closed",
	"휴지통으로 이동": "trashed",
	"휴지통에서 복원": "restored",
	"문의 버전 저장": "messageSaved",
	"판매처에 보낸 사실 기록": "markedSent",
	"증빙 저장": "fileAdded",
	"증빙 삭제": "fileRemoved",
	"실제 회수 확인": "receiptRecorded",
	"회수 기록 정정": "receiptCorrected",
	"판매처 답변 기록": "replyRecorded",
};

function lookup(
	table: object | undefined,
	key: string | undefined,
): string | undefined {
	if (!table || !key) return undefined;
	const value = (table as Record<string, unknown>)[key];
	return typeof value === "string" ? value : undefined;
}

/** The words an exchange or a repair uses in place of the refund ones; nothing for a refund. */
export function kindWords(
	t: TranslationDictionary,
	kind: ClaimKind | undefined,
) {
	return kind === "exchange" || kind === "repair" ? t.kinds[kind] : null;
}

export function stateLabel(
	t: TranslationDictionary,
	state: ClaimState,
	kind?: ClaimKind,
): string {
	return (
		lookup(kindWords(t, kind)?.states, state) ??
		lookup(t.shared.states, state) ??
		state
	);
}

/** The next thing to do, in the reader's language; the server's own sentence if the code is new. */
export function nextStepText(
	t: TranslationDictionary,
	claim: Pick<ClaimView, "nextStep" | "nextStepCode"> & { kind?: ClaimKind },
): string {
	return (
		lookup(kindWords(t, claim.kind)?.nextSteps, claim.nextStepCode) ??
		lookup(t.shared.nextSteps, claim.nextStepCode) ??
		claim.nextStep
	);
}

export function historyLabel(
	t: TranslationDictionary,
	action: string,
	kind?: ClaimKind,
): string {
	const key = HISTORY_KEYS[action];
	return (
		lookup(kindWords(t, kind)?.history, key) ??
		lookup(t.shared.history, key) ??
		action
	);
}

/** What kind of reply the shop sent, in the words of this claim's kind. */
export function replyKindLabel(
	t: TranslationDictionary,
	reply: ReplyKind,
	kind?: ClaimKind,
): string {
	return (
		lookup(kindWords(t, kind)?.replyKinds, reply) ?? t.shared.replyKinds[reply]
	);
}

/**
 * What has come back so far, in words, where it is not money: "1개 / 3개" for an exchange,
 * checked or not yet for a repair. Nothing for a refund, which shows an amount.
 */
export function receivedText(
	t: TranslationDictionary,
	claim: Pick<ClaimView, "kind" | "summary">,
): string | null {
	const p = t.kinds.progress;
	if (claim.kind === "exchange") {
		const got = p.count.replace("{n}", String(claim.summary.goods));
		const total = p.ofTotal.replace("{n}", String(claim.summary.requestedQty));
		return `${got} ${total}`;
	}
	if (claim.kind === "repair")
		return claim.summary.repair ? p.repairDone : p.repairPending;
	return null;
}

/** A form rule names its message by key; an unknown key is shown as it is. */
export function fieldError(
	t: TranslationDictionary,
	message: string | undefined,
): string | undefined {
	if (!message) return undefined;
	return (
		lookup(t.shared.fieldErrors, message) ??
		lookup(t.auth.fieldErrors, message) ??
		message
	);
}

/**
 * What to say when a request fails. The server explains itself in Korean only, so its
 * sentence is used for Korean readers and the screen's own sentence for everyone else.
 */
export function errorText(
	error: unknown,
	fallback: string,
	locale: LocaleCode,
): string {
	if (locale === "ko" && error instanceof Error && error.message) {
		return error.message;
	}
	return fallback;
}
