/**
 * @module client/features/claim-detail/DisputeGuideCard
 * @layer View (What To Do After The Shop Says No)
 * @purpose When a refund is in dispute, shows the three ways people actually use next
 *          (the marketplace's own dispute, a card chargeback or PayPal dispute, the Korea
 *          Consumer Agency), the earliest closing days counted from the order date, a summary
 *          to paste into the form, and the two ways out: continue, or stop here.
 *          A refund that was stopped gets one line and a way to continue.
 */

import { Copy, ExternalLink, RotateCcw } from "lucide-react";
import { useMemo } from "react";
import { Button, Card, useToast } from "@/client/components/ui/Primitives";
import { useTransitionClaimMutation } from "@/client/hooks/useClaims";
import { useI18n } from "@/client/i18n";
import { errorText } from "@/client/lib/claim-words";
import {
	buildDisputeSummary,
	CARD_WINDOW_DAYS,
	type DisputeDeadline,
	disputeDeadline,
	LONG_WINDOW_DAYS,
} from "@/client/lib/dispute";
import { fill, formatLocalDate } from "@/client/lib/format";
import type { ClaimView } from "@/client/types";

/** The Korea Consumer Agency's portal for trouble with overseas purchases. */
const CONSUMER_PORTAL_URL = "https://crossborder.kca.go.kr";

export function DisputeGuideCard({ claim }: { claim: ClaimView }) {
	const { t, locale, localeOption } = useI18n();
	const d = t.detail.dispute;
	const { showToast } = useToast();
	const transitionMutation = useTransitionClaimMutation(claim.id);

	const summary = useMemo(
		() => buildDisputeSummary(claim, t, localeOption.bcp47),
		[claim, t, localeOption.bcp47],
	);

	const change = async (
		action: "reopen" | "waived",
		reason: string,
		done: string,
	) => {
		try {
			await transitionMutation.mutateAsync({
				version: claim.version,
				action,
				reason,
			});
			showToast(done);
		} catch (err) {
			showToast(errorText(err, d.toastFail, locale), "error");
		}
	};
	const handleContinue = () =>
		change("reopen", "소비자가 다시 진행하기로 함", d.toastReopened);
	const handleStop = () =>
		change("waived", "분쟁 뒤 소비자가 더 진행하지 않기로 함", d.toastWaived);

	if (claim.state === "waived") {
		return (
			<Card className="flex flex-wrap items-center justify-between gap-3 p-5 sm:p-6">
				<div className="space-y-1">
					<h2 className="text-base font-bold text-relo-ink">{d.waivedTitle}</h2>
					<p className="text-sm text-relo-muted">{d.waivedBody}</p>
				</div>
				<Button
					variant="secondary"
					isLoading={transitionMutation.isPending}
					onClick={handleContinue}
				>
					<RotateCcw className="h-4 w-4" aria-hidden="true" />
					<span>{d.resolved}</span>
				</Button>
			</Card>
		);
	}

	const deadlineText = (deadline: DisputeDeadline | null) => {
		if (!deadline) return "-";
		const date = formatLocalDate(deadline.date, localeOption.bcp47);
		if (deadline.daysLeft > 0)
			return fill(d.until, { date, n: deadline.daysLeft });
		return fill(deadline.daysLeft === 0 ? d.untilToday : d.passed, { date });
	};
	const windows = [
		{
			label: d.cardWindow,
			deadline: disputeDeadline(claim.orderedOn, CARD_WINDOW_DAYS),
		},
		{
			label: d.longWindow,
			deadline: disputeDeadline(claim.orderedOn, LONG_WINDOW_DAYS),
		},
	];

	const handleCopy = async () => {
		try {
			await navigator.clipboard.writeText(summary);
			showToast(d.toastCopied);
		} catch {
			showToast(d.toastCopyFail, "error");
		}
	};

	const steps = [
		{ title: d.step1Title, body: d.step1Body, extra: null },
		{
			title: d.step2Title,
			body: d.step2Body,
			extra: (
				<div className="mt-3 space-y-2">
					<ul className="space-y-1.5">
						{windows.map((row) => (
							<li
								key={row.label}
								className="flex flex-wrap items-center justify-between gap-x-4 gap-y-0.5 rounded-xl bg-relo-sunken px-3.5 py-2.5 text-sm"
							>
								<span className="text-relo-muted">{row.label}</span>
								<span className="font-semibold text-relo-ink tabular-nums">
									{deadlineText(row.deadline)}
								</span>
							</li>
						))}
					</ul>
					<p className="text-xs leading-relaxed text-relo-muted">
						{d.deadlineNote}
					</p>
				</div>
			),
		},
		{
			title: d.step3Title,
			body: d.step3Body,
			extra: (
				<a
					href={CONSUMER_PORTAL_URL}
					target="_blank"
					rel="noopener noreferrer"
					className="mt-1 inline-flex min-h-11 items-center gap-1.5 text-sm font-semibold text-relo-brand hover:underline"
				>
					<span>{d.portalLink}</span>
					<ExternalLink className="h-3.5 w-3.5" aria-hidden="true" />
				</a>
			),
		},
	];

	return (
		<Card className="space-y-6 p-6 sm:p-8">
			<div className="space-y-1.5">
				<p className="text-xs font-semibold text-relo-brand">{d.eyebrow}</p>
				<h2 className="text-xl font-bold tracking-[-0.03em] text-relo-ink">
					{d.title}
				</h2>
				<p className="text-sm leading-relaxed text-relo-muted">{d.sub}</p>
			</div>

			<ol className="space-y-5">
				{steps.map((step, index) => (
					<li key={step.title} className="flex gap-3.5">
						<span
							aria-hidden="true"
							className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-relo-sunken text-xs font-bold text-relo-body tabular-nums"
						>
							{index + 1}
						</span>
						<div className="min-w-0 flex-1">
							<h3 className="text-[15px] font-bold text-relo-ink">
								{step.title}
							</h3>
							<p className="mt-1 text-sm leading-relaxed text-relo-muted">
								{step.body}
							</p>
							{step.extra}
						</div>
					</li>
				))}
			</ol>

			<div className="space-y-2.5 border-t border-relo-line pt-5">
				<div className="flex flex-wrap items-center justify-between gap-2">
					<h3 className="text-[15px] font-bold text-relo-ink">
						{d.summaryTitle}
					</h3>
					<Button
						variant="secondary"
						size="sm"
						onClick={handleCopy}
						className="max-sm:min-h-11"
					>
						<Copy className="h-3.5 w-3.5" aria-hidden="true" />
						<span>{d.copy}</span>
					</Button>
				</div>
				<p className="text-xs leading-relaxed text-relo-muted">
					{d.summaryHint}
				</p>
				<textarea
					readOnly
					rows={9}
					value={summary}
					aria-label={d.summaryTitle}
					className="w-full resize-y rounded-2xl bg-relo-sunken p-4 text-xs leading-relaxed text-relo-body outline-none focus-visible:ring-2 focus-visible:ring-relo-brand"
				/>
			</div>

			<div className="space-y-3 border-t border-relo-line pt-5">
				<p className="text-xs leading-relaxed text-relo-muted">
					{d.outcomeHint}
				</p>
				<div className="flex flex-wrap items-center gap-2">
					<Button
						variant="secondary"
						isLoading={transitionMutation.isPending}
						onClick={handleContinue}
					>
						<RotateCcw className="h-4 w-4" aria-hidden="true" />
						<span>{d.resolved}</span>
					</Button>
					<Button
						variant="ghost"
						disabled={transitionMutation.isPending}
						onClick={handleStop}
						className="text-relo-muted"
					>
						{d.giveUp}
					</Button>
				</div>
			</div>
		</Card>
	);
}
