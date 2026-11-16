/**
 * @module client/features/my-claims/ClaimsAnalyticsCard
 * @layer View (Currency-Isolated Passbook Summary Card)
 * @purpose Shows, for one currency at a time, how much of the requested refunds has actually
 *          come back: one large amount, one progress bar, and the three figures behind it.
 *          Each figure appears once (no second chart of the same numbers).
 */

import { motion } from "motion/react";
import { useMemo, useState } from "react";
import { Card, MoneyDisplay } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { fill } from "@/client/lib/format";
import type { ClaimView, CurrencyCode } from "@/client/types";

interface CurrencyBucket {
	currency: CurrencyCode;
	count: number;
	claimedMinor: number;
	cashMinor: number;
	remainingMinor: number;
}

export function ClaimsAnalyticsCard({ claims }: { claims: ClaimView[] }) {
	const { t } = useI18n();

	const buckets = useMemo<CurrencyBucket[]>(() => {
		const map = new Map<CurrencyCode, CurrencyBucket>();
		for (const claim of claims) {
			// Only a refund is money to get back; an exchange or a repair is not added up here.
			if (claim.deleted || claim.kind !== "refund") continue;
			const cur = claim.currency;
			const prev = map.get(cur) ?? {
				currency: cur,
				count: 0,
				claimedMinor: 0,
				cashMinor: 0,
				remainingMinor: 0,
			};
			prev.count += 1;
			prev.claimedMinor += claim.claimed;
			prev.cashMinor += claim.summary.cash;
			prev.remainingMinor += claim.summary.remaining;
			map.set(cur, prev);
		}
		return Array.from(map.values()).sort((a, b) => b.count - a.count);
	}, [claims]);

	const [selectedCurrency, setSelectedCurrency] = useState<CurrencyCode | null>(
		null,
	);

	if (buckets.length === 0) return null;

	const activeBucket =
		buckets.find((b) => b.currency === selectedCurrency) ?? buckets[0];
	if (!activeBucket) return null;

	const cur = activeBucket.currency;
	const recoveryPct =
		activeBucket.claimedMinor > 0
			? Math.min(
					100,
					Math.round(
						(activeBucket.cashMinor / activeBucket.claimedMinor) * 100,
					),
				)
			: 0;

	const allRecovered =
		activeBucket.claimedMinor > 0 && activeBucket.remainingMinor === 0;

	return (
		<Card className="space-y-5 p-6 sm:p-8">
			{/* What this card is about, and the currency switcher */}
			<div className="flex flex-wrap items-center justify-between gap-3">
				<p className="text-sm font-semibold text-relo-muted">
					{fill(
						allRecovered ? t.claims.summaryAllDone : t.claims.summaryProgress,
						{ cur, n: activeBucket.count },
					)}
				</p>

				{buckets.length > 1 ? (
					// biome-ignore lint/a11y/useSemanticElements: a pill row of toggle buttons, not a form fieldset
					<div
						role="group"
						aria-label={t.claims.currencyLabel}
						className="inline-flex rounded-full bg-[#f2f4f6] p-1"
					>
						{buckets.map((b) => {
							const active = b.currency === cur;
							return (
								<button
									key={b.currency}
									type="button"
									aria-pressed={active}
									data-testid={`currency-tab-${b.currency}`}
									onClick={() => setSelectedCurrency(b.currency)}
									className={`relative inline-flex cursor-pointer items-center gap-1.5 rounded-full px-3.5 py-1.5 text-xs font-semibold transition max-sm:min-h-10 ${
										active
											? "bg-white font-bold text-relo-ink shadow-2xs"
											: "text-relo-muted hover:text-relo-ink"
									}`}
								>
									{active ? (
										<span
											aria-hidden="true"
											className="h-1.5 w-1.5 rounded-full bg-relo-brand"
										/>
									) : null}
									<span>{b.currency}</span>
								</button>
							);
						})}
					</div>
				) : null}
			</div>

			{/* The headline amount: what has come back, or what was asked for while nothing has */}
			<div className="flex flex-wrap items-baseline gap-3">
				<MoneyDisplay
					minor={
						activeBucket.cashMinor > 0
							? activeBucket.cashMinor
							: activeBucket.claimedMinor
					}
					currency={cur}
					className="text-4xl text-relo-ink sm:text-[44px]"
				/>
				{/* Plain text next to the amount (no colored pill): blue once money has come in, gray while waiting */}
				<span
					className={`text-sm font-bold ${
						allRecovered || activeBucket.cashMinor > 0
							? "text-relo-brand"
							: "text-relo-muted"
					}`}
				>
					{allRecovered
						? t.claims.allRecovered
						: activeBucket.cashMinor > 0
							? fill(t.claims.pctRecovered, { pct: recoveryPct })
							: t.claims.waiting}
				</span>
			</div>

			<div className="h-2.5 w-full overflow-hidden rounded-full bg-[#eef2f6]">
				<motion.div
					initial={{ width: 0 }}
					animate={{ width: `${Math.max(8, recoveryPct)}%` }}
					transition={{ duration: 0.45, ease: [0.22, 0.61, 0.36, 1] }}
					className="h-full rounded-full bg-relo-brand"
				/>
			</div>

			{/* The three figures behind the bar, each shown once */}
			<div className="flex flex-wrap items-center gap-x-8 gap-y-2 border-t border-relo-line pt-4 text-sm">
				<div className="flex items-baseline gap-2">
					<span className="text-relo-muted">{t.pages.sumClaimed}</span>
					<MoneyDisplay
						minor={activeBucket.claimedMinor}
						currency={cur}
						className="text-base text-relo-ink"
					/>
				</div>
				<div className="flex items-baseline gap-2">
					<span className="text-relo-muted">{t.pages.sumRecovered}</span>
					<MoneyDisplay
						minor={activeBucket.cashMinor}
						currency={cur}
						className="text-base text-relo-brand"
					/>
				</div>
				<div className="flex items-baseline gap-2">
					<span className="text-relo-muted">{t.pages.sumRemaining}</span>
					<MoneyDisplay
						minor={activeBucket.remainingMinor}
						currency={cur}
						className="text-base text-relo-body"
					/>
				</div>
			</div>
		</Card>
	);
}
