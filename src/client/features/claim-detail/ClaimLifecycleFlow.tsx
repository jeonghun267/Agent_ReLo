/**
 * @module client/features/claim-detail/ClaimLifecycleFlow
 * @layer View (Single-Case Progress Steps)
 * @purpose Shows where one refund, exchange or repair stands among its six stages, in the
 *          reader's language: a row of numbered steps joined by a line on wide screens, and
 *          the same six steps two per row on narrow ones. Plain text at a readable size on both.
 */

import { Check } from "lucide-react";
import { useI18n } from "@/client/i18n";
import { kindWords } from "@/client/lib/claim-words";
import type { ClaimKind, ClaimState } from "@/client/types";

const ORDERED_STAGES = [
	"preparing",
	"review",
	"awaiting",
	"negotiating",
	"recovered",
	"completed",
] as const;

type StageStatus = "done" | "current" | "upcoming" | "alert";

function stageRank(state: ClaimState): number {
	if (state === "partial") return 3.5;
	if (state === "disputed" || state === "waived") return 3;
	const idx = (ORDERED_STAGES as readonly ClaimState[]).indexOf(state);
	return idx === -1 ? 0 : idx;
}

/** The numbered circle of a step on wide screens. */
const DOT_STYLES: Record<StageStatus, string> = {
	done: "border-relo-brand bg-relo-brand text-white",
	current:
		"border-relo-brand bg-white text-relo-brand ring-4 ring-relo-brand/15",
	alert: "border-relo-danger bg-relo-danger-soft text-relo-danger",
	upcoming: "border-relo-line-strong bg-white text-relo-muted",
};

/** The box of a step on narrow screens. */
const BOX_STYLES: Record<StageStatus, string> = {
	done: "border-relo-brand-line bg-relo-brand-soft/85 text-relo-brand",
	current:
		"border-relo-brand bg-white text-relo-brand shadow-float ring-4 ring-relo-brand/15",
	alert: "border-relo-danger bg-relo-danger-soft text-relo-danger",
	upcoming: "border-relo-line bg-white/85 text-relo-muted",
};

export function ClaimLifecycleFlow({
	state,
	kind,
}: {
	state: ClaimState;
	kind: ClaimKind;
}) {
	const { t } = useI18n();
	const rank = stageRank(state);
	// An exchange or a repair names the last steps after what arrives, not after money.
	const own = kindWords(t, kind)?.stages;

	// The six stages with where this refund stands. Both layouts below draw from this.
	const stages = ORDERED_STAGES.map((id, idx) => {
		let status: StageStatus = "upcoming";
		if (idx < rank) status = "done";
		else if (Math.floor(rank) === idx) {
			status = state === "disputed" || state === "waived" ? "alert" : "current";
		}
		const words = t.detail.stages[id];
		let label: string = words.label;
		let sub: string = words.sub;
		if (own && id === "negotiating") sub = own.negotiatingSub;
		if (own && id === "recovered") {
			label = own.recoveredLabel;
			sub = own.recoveredSub;
		}
		if (idx === 3 && state === "partial")
			label = own?.partial ?? t.detail.stagePartial;
		if (idx === 3 && state === "disputed") label = t.detail.stageDisputed;
		return { id, status, label, sub };
	});

	return (
		// One wrapper, so the card around it spaces this as a single block (one list is always hidden).
		<div>
			{/* Wide screens: one row, each step joined to the one before it by a line. */}
			<ol
				aria-label={t.detail.stagesLabel}
				className="hidden grid-cols-6 rounded-2xl border border-relo-line bg-relo-sunken/70 px-2 py-5 sm:grid"
			>
				{stages.map((stage, idx) => (
					<li
						key={stage.id}
						aria-current={stage.status === "current" ? "step" : undefined}
						className="relative flex flex-col items-center px-1 text-center"
					>
						{idx > 0 ? (
							<span
								aria-hidden="true"
								className={`absolute top-4 right-1/2 h-0.5 w-full -translate-y-1/2 ${
									stage.status === "upcoming"
										? "bg-relo-line-strong"
										: "bg-relo-brand"
								}`}
							/>
						) : null}
						<span
							className={`relative z-10 flex h-8 w-8 items-center justify-center rounded-full border-2 text-xs font-extrabold tabular-nums ${DOT_STYLES[stage.status]}`}
						>
							{stage.status === "done" ? (
								<Check className="h-4 w-4" aria-hidden="true" />
							) : (
								idx + 1
							)}
						</span>
						<p
							className={`mt-2 text-[13px] leading-tight font-bold ${
								stage.status === "upcoming" ? "text-relo-body" : "text-relo-ink"
							}`}
						>
							{stage.label}
						</p>
						<p className="mt-1 text-xs leading-tight text-relo-muted">
							{stage.sub}
						</p>
					</li>
				))}
			</ol>

			{/* Narrow screens: the same six steps, two per row (read left to right, then down). */}
			<ol
				aria-label={t.detail.stagesLabel}
				className="grid grid-cols-2 gap-2 rounded-2xl border border-relo-line bg-relo-sunken/70 p-3 sm:hidden"
			>
				{stages.map((stage, idx) => (
					<li
						key={stage.id}
						aria-current={stage.status === "current" ? "step" : undefined}
						className={`rounded-xl border px-3 py-2.5 ${BOX_STYLES[stage.status]}`}
					>
						<div className="flex items-center gap-1.5">
							{stage.status === "done" ? (
								<Check className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
							) : (
								<span className="w-3.5 shrink-0 text-center text-xs font-extrabold tabular-nums">
									{idx + 1}
								</span>
							)}
							<p className="truncate text-[13px] font-extrabold text-relo-ink">
								{stage.label}
							</p>
						</div>
						<p className="mt-0.5 truncate pl-5 text-xs font-medium text-relo-muted">
							{stage.sub}
						</p>
					</li>
				))}
			</ol>
		</div>
	);
}
