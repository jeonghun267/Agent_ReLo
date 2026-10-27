/**
 * @module client/features/my-claims/ClaimsAnalyticsCard
 * @layer View (Currency-Isolated Passbook Summary Card)
 * @purpose Displays per-currency refund progress using a unified Toss Blue + Cool Slate
 *          color system so switching between KRW, EUR, USD, and JPY stays visually cohesive.
 */

import {
	BarElement,
	CategoryScale,
	Chart as ChartJS,
	Legend,
	LinearScale,
	Tooltip,
} from "chart.js";
import { motion } from "motion/react";
import { useMemo, useState } from "react";
import { Bar } from "react-chartjs-2";
import { Card, MoneyDisplay } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { minorToMajor } from "@/client/lib/format";
import type { ClaimView, CurrencyCode } from "@/client/types";

ChartJS.register(CategoryScale, LinearScale, BarElement, Tooltip, Legend);

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
			if (claim.deleted) continue;
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
	const claimedMajor = minorToMajor(activeBucket.claimedMinor, cur);
	const cashMajor = minorToMajor(activeBucket.cashMinor, cur);
	const remainingMajor = minorToMajor(activeBucket.remainingMinor, cur);
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
		<Card className="p-6 sm:p-8">
			{/* Top Eyebrow & Unified Currency Switcher */}
			<div className="flex flex-wrap items-center justify-between gap-3">
				<p className="text-sm font-semibold text-relo-muted">
					{allRecovered
						? `${cur} 기준 총 ${activeBucket.count}건 모두 입금 확인되었어요`
						: `${cur} 기준 총 ${activeBucket.count}건의 환불 진행 상황을 확인하고 있어요`}
				</p>

				{buckets.length > 1 ? (
					<div className="inline-flex rounded-full bg-[#f2f4f6] p-1">
						{buckets.map((b) => {
							const active = b.currency === cur;
							return (
								<button
									key={b.currency}
									type="button"
									data-testid={`currency-tab-${b.currency}`}
									onClick={() => setSelectedCurrency(b.currency)}
									className={`relative inline-flex cursor-pointer items-center gap-1.5 rounded-full px-3.5 py-1.5 text-xs font-semibold transition ${
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

			<div className="mt-4 grid gap-8 lg:grid-cols-12 lg:items-center">
				{/* Left Passbook Headline Balance — Unified Toss Blue Accent */}
				<div className="space-y-5 lg:col-span-7">
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
						<span
							className={`rounded-full px-3 py-1 text-xs font-bold ${
								allRecovered
									? "bg-relo-brand text-white"
									: "bg-relo-brand-soft text-relo-brand"
							}`}
						>
							{allRecovered
								? "전액 입금 완료"
								: activeBucket.cashMinor > 0
									? `${recoveryPct}% 입금 확인`
									: "입금 대기 중"}
						</span>
					</div>

					{/* Unified Toss Blue Gauge Track */}
					<div className="h-2.5 w-full overflow-hidden rounded-full bg-[#eef2f6]">
						<motion.div
							initial={{ width: 0 }}
							animate={{ width: `${Math.max(8, recoveryPct)}%` }}
							transition={{ duration: 0.45, ease: [0.22, 0.61, 0.36, 1] }}
							className="h-full rounded-full bg-relo-brand"
						/>
					</div>

					{/* Cohesive Summary Row (Ink + Toss Blue + Neutral Body, Zero Clashing Green) */}
					<div className="flex flex-wrap items-center gap-x-6 gap-y-2 border-t border-relo-line pt-4 text-sm">
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
				</div>

				{/* Right Minimalist Horizontal Bar (Monochromatic Slate + Toss Blue) */}
				<div className="h-32 rounded-2xl bg-[#f8fafc] p-4 lg:col-span-5">
					<Bar
						aria-label={`${cur} ${t.pages.sumClaimed}, ${t.pages.sumRecovered}, ${t.pages.sumRemaining}`}
						data={{
							labels: [
								t.pages.sumClaimed,
								t.pages.sumRecovered,
								t.pages.sumRemaining,
							],
							datasets: [
								{
									label: cur,
									data: [claimedMajor, cashMajor, remainingMajor],
									backgroundColor: ["#cbd5e1", "#1b64da", "#93c5fd"],
									borderRadius: 8,
									barThickness: 14,
								},
							],
						}}
						options={{
							indexAxis: "y",
							responsive: true,
							maintainAspectRatio: false,
							plugins: { legend: { display: false } },
							scales: {
								x: {
									beginAtZero: true,
									display: false,
								},
								y: {
									grid: { display: false },
									border: { display: false },
								},
							},
						}}
					/>
				</div>
			</div>
		</Card>
	);
}
