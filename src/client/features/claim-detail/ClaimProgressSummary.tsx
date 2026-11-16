/**
 * @module client/features/claim-detail/ClaimProgressSummary
 * @layer View (What Has Come Back, At A Glance)
 * @purpose The box at the top of one claim: how much has come back out of what was asked
 *          for, the next thing to do, and a bar. A refund counts money, an exchange counts
 *          replacement items, a repair is checked or not yet.
 */

import type { ReactNode } from "react";
import { MoneyDisplay } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { receivedPercent } from "@/client/lib/claim-progress";
import { nextStepText } from "@/client/lib/claim-words";
import { fill } from "@/client/lib/format";
import type { ClaimView } from "@/client/types";

interface Fact {
	label: string;
	value: ReactNode;
}

export function ClaimProgressSummary({ claim }: { claim: ClaimView }) {
	const { t } = useI18n();
	const p = t.kinds.progress;
	const { summary, currency } = claim;
	const money = (minor: number, className: string) => (
		<MoneyDisplay minor={minor} currency={currency} className={className} />
	);
	const plain = (text: string) => (
		<strong className="ml-1 font-semibold text-relo-ink">{text}</strong>
	);

	let label: string;
	let headline: ReactNode;
	let facts: Fact[];

	if (claim.kind === "exchange") {
		label = p.goodsLabel;
		headline = (
			<>
				<span className="text-3xl font-bold tracking-[-0.03em] text-relo-ink tabular-nums sm:text-4xl">
					{fill(p.count, { n: summary.goods })}
				</span>
				<span className="text-sm font-medium text-relo-muted tabular-nums">
					{fill(p.ofTotal, { n: summary.requestedQty })}
				</span>
			</>
		);
		facts = [
			{
				label: p.requested,
				value: plain(fill(p.count, { n: summary.requestedQty })),
			},
			{ label: p.received, value: plain(fill(p.count, { n: summary.goods })) },
			{
				label: p.left,
				value: (
					<strong className="ml-1 font-semibold text-relo-brand">
						{fill(p.count, {
							n: Math.max(0, summary.requestedQty - summary.goods),
						})}
					</strong>
				),
			},
		];
	} else if (claim.kind === "repair") {
		label = p.repairLabel;
		headline = (
			<span className="text-2xl font-bold tracking-[-0.03em] text-relo-ink sm:text-3xl">
				{summary.repair ? p.repairDone : p.repairPending}
			</span>
		);
		facts = [
			{ label: p.itemPrice, value: money(claim.claimed, "ml-1 text-relo-ink") },
		];
	} else {
		label = t.pages.sumRecovered;
		headline = (
			<>
				{money(summary.cash, "text-3xl text-relo-ink sm:text-4xl")}
				<span className="text-sm font-medium text-relo-muted">
					/ {money(claim.claimed, "text-sm text-relo-muted")}
				</span>
			</>
		);
		facts = [
			{
				label: t.pages.sumClaimed,
				value: money(claim.claimed, "ml-1 text-relo-ink"),
			},
			{
				label: t.detail.agreedLabel,
				value:
					claim.agreed !== null ? (
						money(claim.agreed, "ml-1 text-relo-ink")
					) : (
						<strong className="ml-1 font-semibold text-relo-body">
							{t.detail.agreedPending}
						</strong>
					),
			},
			{
				label: t.pages.sumRemaining,
				value: money(summary.remaining, "ml-1 text-relo-brand"),
			},
		];
	}

	return (
		<div className="rounded-2xl bg-relo-canvas p-5">
			<div className="flex flex-wrap items-baseline justify-between gap-2">
				<div>
					<p className="text-xs font-medium text-relo-muted">{label}</p>
					<div className="mt-1 flex items-baseline gap-2">{headline}</div>
				</div>
				<span className="text-xs font-semibold text-relo-brand">
					{t.shared.nextStepLabel}: {nextStepText(t, claim)}
				</span>
			</div>

			<div className="mt-4 h-2 w-full overflow-hidden rounded-full bg-[#e5e8eb]">
				<div
					style={{ width: `${Math.max(6, receivedPercent(claim))}%` }}
					className="h-full rounded-full bg-relo-brand transition-all"
				/>
			</div>

			<div className="mt-4 flex flex-wrap items-center gap-x-6 gap-y-1.5 border-t border-relo-line pt-3.5 text-xs sm:text-sm">
				{facts.map((fact) => (
					<span key={fact.label} className="text-relo-muted">
						{fact.label} {fact.value}
					</span>
				))}
			</div>
		</div>
	);
}
