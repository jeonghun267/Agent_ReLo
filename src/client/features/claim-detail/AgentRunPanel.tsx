/**
 * @module client/features/claim-detail/AgentRunPanel
 * @layer View (Agent Run: the AI works toward the goal of this case)
 * @purpose Names the goal, starts an agent run and shows what came back: which tool the AI
 *          chose at each step, why, and what that step found. When the AI wants to change the
 *          case (correct an order fact, save the message it wrote) the run stops here and asks:
 *          nothing is saved until the person allows it. Nothing is ever sent; the person sends
 *          the message themself. Also shows what the last run did, so the work reads as one thread.
 *          A run may also start by itself when something happens on the case, if the person has
 *          turned that on here; the panel then shows the agent at work and what it left waiting.
 */

import { useState } from "react";
import { useAiConsentGate } from "@/client/components/AiConsentDialog";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Badge,
	Button,
	Card,
	useToast,
} from "@/client/components/ui/Primitives";
import {
	AgentChangeLines,
	AgentRunSteps,
} from "@/client/features/claim-detail/AgentRunSteps";
import {
	useAgentDecisionMutation,
	useAgentOverviewQuery,
	useAgentRunMutation,
} from "@/client/hooks/useClaims";
import {
	useAgentAutoMutation,
	useAppConfig,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { errorText } from "@/client/lib/claim-words";
import { fill, formatLocalDate, formatMinorMoney } from "@/client/lib/format";
import { useCalmPreparation } from "@/client/lib/preparation";
import type {
	AgentOverview,
	AgentRunResponse,
	ClaimView,
	DraftSuggestionResponse,
} from "@/client/types";

interface AgentRunPanelProps {
	claim: ClaimView;
	/** Hands a draft the run wrote to the message box. Nothing is saved by this. */
	onUseDraft: (draft: DraftSuggestionResponse) => void;
}

export function AgentRunPanel({ claim, onUseDraft }: AgentRunPanelProps) {
	const { data: config } = useAppConfig();
	const { ensureConsent, consentDialog } = useAiConsentGate();
	const isOn = Boolean(config?.ai.enabled) && !claim.deleted;
	const { data: session } = useSession();
	const { data: overview, isFetching } = useAgentOverviewQuery(claim.id, isOn);
	const runMutation = useAgentRunMutation(claim.id);
	const decisionMutation = useAgentDecisionMutation(claim.id);
	const autoMutation = useAgentAutoMutation();
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();
	const { t, locale, localeOption } = useI18n();
	const a = t.detail.agent;
	const [latest, setLatest] = useState<AgentRunResponse | null>(null);

	const pressed =
		isPreparing || runMutation.isPending || decisionMutation.isPending;
	// The agent is at work without anyone here having pressed: it started by itself.
	const onItsOwn = Boolean(overview?.working) && !pressed;
	// What this screen holds from a press is dropped once the server has moved on without it:
	// a run that started by itself is under way, or it closed the proposal shown here.
	const outdated =
		latest !== null &&
		overview !== undefined &&
		!isFetching &&
		!pressed &&
		(overview.working ||
			(latest.status === "waiting"
				? overview.waiting?.runId !== latest.runId
				: overview.waiting !== null));
	if (outdated) setLatest(null);

	if (!isOn || !config) return null;
	const maxSteps = config.ai.agentMaxSteps ?? 5;
	const autoOn = Boolean(session?.user?.agentAutoAt);
	// A proposal that was waiting when the page was opened is picked up where it stopped.
	const run = onItsOwn ? null : (latest ?? overview?.waiting ?? null);
	const pending = run?.status === "waiting" ? run.pending : null;

	const handleAuto = async (on: boolean) => {
		// Starting by itself sends this case to the AI without a press each time, so it is
		// offered only after the same notice and consent as every AI button.
		if (on && !(await ensureConsent())) return;
		try {
			await autoMutation.mutateAsync(on);
			showToast(on ? a.auto.toastOn : a.auto.toastOff);
		} catch (error) {
			showToast(errorText(error, a.auto.toastFail, locale), "error");
		}
	};

	const handleRun = async () => {
		// The same notice and consent as every AI button, before anything is sent.
		if (!(await ensureConsent())) return;
		try {
			const result = await runCalmly(() => runMutation.mutateAsync(locale));
			if (result) setLatest(result);
		} catch (error) {
			showToast(errorText(error, a.toastFail, locale), "error");
		}
	};

	const handleDecision = async (approve: boolean) => {
		if (!run) return;
		try {
			const result = await runCalmly(() =>
				decisionMutation.mutateAsync({ runId: run.runId, approve, locale }),
			);
			if (result) setLatest(result);
		} catch (error) {
			showToast(errorText(error, a.toastDecisionFail, locale), "error");
		}
	};

	const handleUseDraft = (draft: DraftSuggestionResponse) => {
		onUseDraft(draft);
		showToast(a.draftUsed);
	};

	const isWorking = pressed || onItsOwn;
	const goal =
		claim.kind === "refund"
			? fill(a.goal.refund, {
					amount: formatMinorMoney(
						claim.agreed ?? claim.claimed,
						claim.currency,
					),
				})
			: a.goal[claim.kind];

	return (
		<Card className="space-y-4 p-5 sm:p-6">
			{consentDialog}
			<div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
				<div className="space-y-1">
					<Badge tone="brand">{a.eyebrow}</Badge>
					<p className="text-base font-bold text-relo-ink">
						<span className="font-medium text-relo-muted">{a.goalLabel}</span>{" "}
						{goal}
					</p>
					<p className="text-xs leading-relaxed text-relo-muted">{a.idle}</p>
				</div>
				{pending ? null : (
					<Button
						variant="secondary"
						size="md"
						isLoading={isWorking}
						onClick={handleRun}
						className="shrink-0"
					>
						{run ? a.again : a.start}
					</Button>
				)}
			</div>

			<div
				className="flex flex-wrap items-center justify-between gap-x-3 gap-y-1 border-t border-relo-line pt-3 text-xs leading-relaxed text-relo-muted"
				data-testid="agent-auto"
			>
				<p className="min-w-0 flex-1 basis-64">
					{autoOn ? a.auto.onNote : a.auto.offNote}
				</p>
				<button
					type="button"
					aria-pressed={autoOn}
					disabled={autoMutation.isPending}
					onClick={() => handleAuto(!autoOn)}
					className="inline-flex min-h-11 shrink-0 cursor-pointer items-center font-semibold text-relo-brand hover:underline disabled:opacity-60"
				>
					{autoOn ? a.auto.turnOff : a.auto.turnOn}
				</button>
			</div>

			{!run && !isWorking && overview?.heldBack ? (
				<p
					className="text-xs leading-relaxed text-relo-muted"
					data-testid="agent-held-back"
				>
					{a.auto.heldBack}
				</p>
			) : null}

			{!run && !isWorking && overview?.last ? (
				<LastRun last={overview.last} bcp47={localeOption.bcp47} />
			) : null}

			{isWorking ? (
				<div
					className="rounded-2xl bg-relo-brand-soft/50 py-5"
					data-testid="agent-working"
				>
					<ReloOrbEmblem
						variant="processing"
						size="sm"
						speech={onItsOwn ? a.autoRunning : fill(a.running, { n: maxSteps })}
					/>
				</div>
			) : null}

			{run && !isWorking ? (
				<div className="space-y-4" data-testid="agent-run-result">
					{run.startedBy !== "person" ? (
						<p className="text-xs leading-relaxed text-relo-muted">
							{a.startedBy[run.startedBy]}
						</p>
					) : null}
					{run.steps.length > 0 ? (
						<AgentRunSteps
							steps={run.steps}
							claim={claim}
							onUseDraft={handleUseDraft}
						/>
					) : null}

					{pending ? (
						<div
							className="space-y-3 rounded-2xl border border-relo-brand bg-relo-surface p-4 text-xs leading-relaxed"
							data-testid="agent-approval"
						>
							<div className="space-y-1">
								<h3 className="text-sm font-bold text-relo-ink">
									{a.approval.title}
								</h3>
								<p className="text-relo-muted">{a.approval.intro}</p>
							</div>
							<p className="text-sm font-bold text-relo-ink">
								{a.tools[pending.tool]}
							</p>
							<p className="text-relo-muted">
								{a.why} {pending.reason}
							</p>
							{pending.changes.length > 0 ? (
								<div className="space-y-1">
									<AgentChangeLines changes={pending.changes} />
									<p className="text-relo-muted">
										{fill(a.approval.fixNote, {
											file: pending.fileName ?? "",
										})}
									</p>
								</div>
							) : null}
							{pending.draftBody ? (
								<div className="space-y-1.5">
									<p className="text-relo-muted">{a.approval.draftNote}</p>
									<p className="max-h-64 overflow-y-auto whitespace-pre-wrap rounded-xl bg-relo-sunken/60 p-3 text-relo-ink">
										{pending.draftBody}
									</p>
								</div>
							) : null}
							<div className="flex flex-wrap gap-2">
								<Button size="md" onClick={() => handleDecision(true)}>
									{a.approval.approve}
								</Button>
								<Button
									variant="secondary"
									size="md"
									onClick={() => handleDecision(false)}
								>
									{a.approval.decline}
								</Button>
							</div>
						</div>
					) : null}

					{run.endedBy ? (
						<div className="space-y-1 text-xs leading-relaxed">
							<p className="text-relo-muted">
								{fill(a.ended[run.endedBy], { n: run.maxSteps })}
								{run.reason ? ` ${run.reason}` : ""}
							</p>
							{run.userAction ? (
								<p className="text-sm text-relo-ink">
									<span className="font-bold">{a.nextTitle}</span>{" "}
									{run.userAction}
								</p>
							) : null}
						</div>
					) : null}

					<p className="text-xs leading-relaxed text-relo-muted">
						{fill(a.note, { n: run.aiCalls })}
					</p>
				</div>
			) : null}
		</Card>
	);
}

/** What the agent did the last time, and what it asked the person to do. */
function LastRun({
	last,
	bcp47,
}: {
	last: NonNullable<AgentOverview["last"]>;
	bcp47: string;
}) {
	const { t } = useI18n();
	const a = t.detail.agent;
	if (last.steps.length === 0 && !last.userAction) return null;
	const steps = last.steps
		.map((step) => {
			const label = a.tools[step.tool];
			if (step.decision === "approved") return `${label} (${a.lastApproved})`;
			if (step.decision === "declined") return `${label} (${a.lastDeclined})`;
			return label;
		})
		.join(" → ");
	return (
		<div
			className="space-y-1 rounded-2xl bg-relo-sunken/50 p-3.5 text-xs leading-relaxed text-relo-muted"
			data-testid="agent-last-run"
		>
			{last.startedBy !== "person" ? (
				<p>{a.startedBy[last.startedBy]}</p>
			) : null}
			{steps ? (
				<p>
					{fill(a.last, {
						date: formatLocalDate(last.endedAt, bcp47),
						steps,
					})}
				</p>
			) : null}
			{last.userAction ? (
				<p>
					{a.lastSaid} <span className="text-relo-ink">{last.userAction}</span>
				</p>
			) : null}
		</div>
	);
}
