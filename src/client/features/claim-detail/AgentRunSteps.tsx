/**
 * @module client/features/claim-detail/AgentRunSteps
 * @layer View (Agent Run: what each step did)
 * @purpose Lists the steps of an agent run in order: the tool the AI chose, why, and what
 *          came of it. A reading step shows what it found, the way the matching AI button
 *          shows it. An action step shows what would change and what the person answered.
 */

import { Button } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { replyKindLabel } from "@/client/lib/claim-words";
import { fill } from "@/client/lib/format";
import type {
	AgentChange,
	AgentStep,
	AiExtractionResponse,
	AiReplyAnalysisResponse,
	ClaimView,
	DraftSuggestionResponse,
} from "@/client/types";

interface AgentRunStepsProps {
	steps: AgentStep[];
	claim: ClaimView;
	onUseDraft: (draft: DraftSuggestionResponse) => void;
}

export function AgentRunSteps({
	steps,
	claim,
	onUseDraft,
}: AgentRunStepsProps) {
	const { t } = useI18n();
	const a = t.detail.agent;

	return (
		<div className="space-y-2">
			<h3 className="text-sm font-bold text-relo-ink">{a.resultTitle}</h3>
			<ol className="space-y-2.5">
				{steps.map((step) => (
					<li
						key={step.seq}
						className="space-y-1.5 rounded-2xl border border-relo-line bg-relo-sunken/50 p-3.5 text-xs leading-relaxed"
					>
						<p className="text-sm font-bold text-relo-ink">
							{step.seq}. {a.tools[step.tool]}
							{step.fileName ? (
								<span className="font-medium text-relo-muted">
									{" "}
									· {step.fileName}
								</span>
							) : null}
						</p>
						<p className="text-relo-muted">
							{a.why} {step.reason}
						</p>
						{step.decision ? (
							<ActionOutcome step={step} />
						) : (
							<StepResult step={step} claim={claim} onUseDraft={onUseDraft} />
						)}
					</li>
				))}
			</ol>
		</div>
	);
}

/** The facts an action replaces, one per line: "주문번호: A → B". */
export function AgentChangeLines({ changes }: { changes: AgentChange[] }) {
	const { t } = useI18n();
	const a = t.detail.agent;
	return (
		<>
			{changes.map((change) => (
				<p key={change.field} className="font-semibold text-relo-ink">
					{fill(a.approval.changeLine, {
						field: a.fields[change.field],
						from: change.from,
						to: change.to,
					})}
				</p>
			))}
		</>
	);
}

/** An action step: what it would change, and what the person answered. */
function ActionOutcome({ step }: { step: AgentStep }) {
	const { t } = useI18n();
	const a = t.detail.agent;

	if (step.decision === "declined") {
		return <p className="text-relo-muted">{a.decided.declined}</p>;
	}
	if (!step.ok) {
		return (
			<p className="font-semibold text-relo-danger">
				{a.decided.failed} {step.message}
			</p>
		);
	}
	return (
		<>
			<AgentChangeLines changes={step.changes} />
			<p className="text-relo-muted">{a.decided.approved}</p>
		</>
	);
}

/** What one reading step found, shown the way the matching AI button shows it. */
function StepResult({
	step,
	claim,
	onUseDraft,
}: {
	step: AgentStep;
	claim: ClaimView;
	onUseDraft: (draft: DraftSuggestionResponse) => void;
}) {
	const { t } = useI18n();
	const a = t.detail.agent;

	if (!step.ok || !step.result) {
		return (
			<p className="font-semibold text-relo-danger">
				{a.stepFailed} {step.message}
			</p>
		);
	}

	if (step.tool === "read_evidence") {
		const { suggestion, orderTotal } = step.result as AiExtractionResponse;
		const rows: Array<[string, string | null]> = [
			[a.fields.vendor, suggestion.vendor],
			[a.fields.orderRef, suggestion.orderRef],
			[a.fields.orderedOn, suggestion.orderedOn],
			[a.fields.currency, suggestion.currency],
			[a.fields.total, orderTotal],
		];
		return (
			<>
				<p className="text-relo-ink">
					{rows
						.filter(([, value]) => value)
						.map(([label, value]) => `${label} ${value}`)
						.join(" · ")}
				</p>
				{step.mismatches.length > 0 ? (
					<div className="font-semibold text-relo-danger">
						<p>{a.mismatchTitle}</p>
						{step.mismatches.map((item) => (
							<p key={item.field}>
								{fill(a.mismatchLine, {
									field: a.fields[item.field],
									saved: item.saved,
									read: item.read,
								})}
							</p>
						))}
					</div>
				) : (
					<p className="text-relo-muted">{a.noMismatch}</p>
				)}
			</>
		);
	}

	if (step.tool === "analyze_reply") {
		const reply = step.result as AiReplyAnalysisResponse;
		return (
			<>
				<p className="font-semibold text-relo-ink">{reply.summaryKo}</p>
				<p className="text-relo-muted">
					{a.replyKind} {replyKindLabel(t, reply.suggestedKind, claim.kind)}
					{reply.mentionedAmount
						? ` · ${fill(a.mentioned, {
								amount: `${reply.mentionedCurrency ?? claim.currency} ${reply.mentionedAmount}`,
							})}`
						: ""}
					{reply.deadline
						? ` · ${fill(a.deadline, { date: reply.deadline })}`
						: ""}
				</p>
			</>
		);
	}

	const draft = step.result as DraftSuggestionResponse;
	return (
		<>
			{draft.summaryKo ? (
				<p className="font-semibold text-relo-ink">{draft.summaryKo}</p>
			) : null}
			<p className="line-clamp-4 whitespace-pre-wrap text-relo-muted">
				{draft.body}
			</p>
			<Button variant="secondary" size="sm" onClick={() => onUseDraft(draft)}>
				{a.useDraft}
			</Button>
		</>
	);
}
