/**
 * @module client/lib/claim-words
 * @layer ViewModel Helper (Refund Wording Lookup)
 * @purpose Turns what the server sends about a refund (a state, a next-step code, a history
 *          entry, a form error key) into the sentence for the reader's language, so every
 *          signed-in screen names the same thing with the same words.
 */

import type { LocaleCode, TranslationDictionary } from "@/client/i18n";
import type { ClaimState, ClaimView } from "@/client/types";

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

function lookup(table: object, key: string | undefined): string | undefined {
	if (!key) return undefined;
	const value = (table as Record<string, unknown>)[key];
	return typeof value === "string" ? value : undefined;
}

export function stateLabel(
	t: TranslationDictionary,
	state: ClaimState,
): string {
	return lookup(t.shared.states, state) ?? state;
}

/** The next thing to do, in the reader's language; the server's own sentence if the code is new. */
export function nextStepText(
	t: TranslationDictionary,
	claim: Pick<ClaimView, "nextStep" | "nextStepCode">,
): string {
	return lookup(t.shared.nextSteps, claim.nextStepCode) ?? claim.nextStep;
}

export function historyLabel(t: TranslationDictionary, action: string): string {
	return lookup(t.shared.history, HISTORY_KEYS[action]) ?? action;
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
