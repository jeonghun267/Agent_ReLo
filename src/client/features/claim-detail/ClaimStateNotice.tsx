/**
 * @module client/features/claim-detail/ClaimStateNotice
 * @layer View (One Quiet Line With A Way Out)
 * @purpose Under the summary of a claim, one line for the two moments a person can get
 *          stuck: the shop has gone silent or is not keeping its promise (opens the other
 *          ways to settle it), and a finished claim whose record needs fixing (opens it again).
 */

import { useToast } from "@/client/components/ui/Primitives";
import { useTransitionClaimMutation } from "@/client/hooks/useClaims";
import { useI18n } from "@/client/i18n";
import { errorText } from "@/client/lib/claim-words";
import type { ClaimState, ClaimView } from "@/client/types";

/** The message has gone out and nothing, or only part, has come back. */
const WAITING_STATES: ClaimState[] = ["awaiting", "negotiating", "partial"];

export function ClaimStateNotice({ claim }: { claim: ClaimView }) {
	const { t, locale } = useI18n();
	const n = t.kinds.notices;
	const { showToast } = useToast();
	const transitionMutation = useTransitionClaimMutation(claim.id);

	const waiting = WAITING_STATES.includes(claim.state);
	if (claim.deleted || (!waiting && claim.state !== "completed")) return null;

	const handleClick = async () => {
		try {
			await transitionMutation.mutateAsync(
				waiting
					? {
							version: claim.version,
							action: "disputed",
							reason: "쇼핑몰이 답하지 않거나 약속을 지키지 않음",
						}
					: {
							version: claim.version,
							action: "reopen",
							reason: "마무리한 뒤 기록을 고치려고 다시 엶",
						},
			);
			showToast(waiting ? n.toastDisputed : n.toastReopened);
		} catch (err) {
			showToast(errorText(err, n.toastFail, locale), "error");
		}
	};

	return (
		<div className="flex flex-wrap items-center justify-between gap-x-4 rounded-2xl bg-relo-sunken px-5 py-1.5">
			<p className="py-2 text-sm text-relo-body">
				{waiting ? n.noAnswer : n.completed}
			</p>
			<button
				type="button"
				disabled={transitionMutation.isPending}
				onClick={handleClick}
				className="inline-flex min-h-11 cursor-pointer items-center text-sm font-semibold text-relo-brand hover:underline disabled:cursor-wait disabled:opacity-60"
			>
				{waiting ? n.noAnswerAction : n.reopen}
			</button>
		</div>
	);
}
