/**
 * @module client/features/landing/RefundSimulatorSection
 * @layer View (Interactive Refund Request Preview)
 * @purpose Lets consumers pick a store, a problem, and the amount they paid (USD, EUR,
 *          JPY, KRW), shows the request those choices produce, and launches the wizard
 *          with them filled in. It only echoes what the visitor chose: no success
 *          rates or "expected refund" figures, because we have no data behind them.
 */

import { ArrowRight, Languages } from "lucide-react";
import { motion } from "motion/react";
import { useId, useMemo, useState } from "react";
import { NumberTicker } from "@/client/components/effects/InteractivePrimitives";
import { Button, Card } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import type { ClaimKind, CurrencyCode } from "@/client/types";

interface SimulatorMallOption {
	label: string;
	vendor: string;
	currency: CurrencyCode;
	symbol: string;
	min: number;
	max: number;
	step: number;
	defaultAmount: number;
}

const MALL_OPTIONS: SimulatorMallOption[] = [
	{
		label: "Amazon US (USD $)",
		vendor: "Amazon",
		currency: "USD",
		symbol: "$",
		min: 20,
		max: 800,
		step: 10,
		defaultAmount: 180,
	},
	{
		label: "Farfetch · Europe (EUR €)",
		vendor: "Farfetch",
		currency: "EUR",
		symbol: "€",
		min: 30,
		max: 900,
		step: 10,
		defaultAmount: 210,
	},
	{
		label: "Mercari · Amazon JP (JPY ¥)",
		vendor: "Amazon JP",
		currency: "JPY",
		symbol: "¥",
		min: 2000,
		max: 80000,
		step: 1000,
		defaultAmount: 16000,
	},
	{
		label: "Temu · AliExpress (KRW ₩)",
		vendor: "Temu",
		currency: "KRW",
		symbol: "₩",
		min: 15000,
		max: 500000,
		step: 5000,
		defaultAmount: 85000,
	},
];

type ScenarioKey = "damaged" | "wrong" | "defect";

export function RefundSimulatorSection({
	onLaunchWithPreset,
}: {
	onLaunchWithPreset: (preset: {
		vendor: string;
		currency: CurrencyCode;
		amount: string;
		kind: ClaimKind;
		issue: string;
	}) => void;
}) {
	const { t, localeOption } = useI18n();
	const sliderId = useId();
	const [mallIdx, setMallIdx] = useState(0);
	const [scenarioKey, setScenarioKey] = useState<ScenarioKey>("damaged");
	const mall = MALL_OPTIONS[mallIdx] ?? MALL_OPTIONS[0];
	const [amount, setAmount] = useState(mall.defaultAmount);

	const scenarios = useMemo(
		() => [
			{
				id: "damaged" as const,
				label: t.simulator.scenarios.damaged.label,
				kind: "refund" as ClaimKind,
				issue: t.simulator.scenarios.damaged.issue,
				englishSnippet:
					"The item arrived visibly damaged upon delivery, as shown in the attached defect photos.",
			},
			{
				id: "wrong" as const,
				label: t.simulator.scenarios.wrong.label,
				kind: "refund" as ClaimKind,
				issue: t.simulator.scenarios.wrong.issue,
				englishSnippet:
					"The delivered item does not match the ordered option on the receipt, and accessories are missing.",
			},
			{
				id: "defect" as const,
				label: t.simulator.scenarios.defect.label,
				kind: "exchange" as ClaimKind,
				issue: t.simulator.scenarios.defect.issue,
				englishSnippet:
					"The unit fails to power on out of the box despite following the official instructions.",
			},
		],
		[t],
	);

	const scenario = scenarios.find((s) => s.id === scenarioKey) ?? scenarios[0];

	const handleSelectMall = (idx: number) => {
		const next = MALL_OPTIONS[idx] ?? MALL_OPTIONS[0];
		setMallIdx(idx);
		setAmount(next.defaultAmount);
	};

	// The request these choices produce: exactly what the visitor picked, nothing estimated.
	const summaryRows = [
		{ label: t.simulator.mallLabel, value: mall.vendor },
		{ label: t.simulator.rowIssue, value: scenario.label },
		{
			label: t.simulator.rowKind,
			value:
				scenario.kind === "exchange"
					? t.simulator.kindExchange
					: t.simulator.kindRefund,
		},
	];

	return (
		<section id="refund-calculator" className="bg-white py-24 sm:py-32">
			<div className="mx-auto max-w-6xl px-4 sm:px-6">
				<Card className="overflow-hidden border-relo-line bg-relo-canvas p-6 sm:p-10">
					<div className="mb-8 flex flex-wrap items-end justify-between gap-3">
						<div className="space-y-2">
							<p className="text-[15px] font-bold text-relo-brand">
								{t.simulator.eyebrow}
							</p>
							<h2 className="text-3xl leading-[1.22] font-bold tracking-[-0.035em] text-relo-ink sm:text-[38px]">
								{t.simulator.title}
							</h2>
						</div>
						<p className="text-sm text-relo-muted">{t.simulator.subtitle}</p>
					</div>

					<div className="grid gap-8 lg:grid-cols-12">
						{/* Interactive Controls */}
						<div className="space-y-6 lg:col-span-6">
							<div className="space-y-2.5">
								<p className="text-xs font-semibold text-relo-muted">
									{t.simulator.mallLabel}
								</p>
								<div className="grid grid-cols-2 gap-2">
									{MALL_OPTIONS.map((opt, idx) => (
										<button
											key={opt.label}
											type="button"
											onClick={() => handleSelectMall(idx)}
											className={`cursor-pointer rounded-2xl px-4 py-3 text-left text-xs font-semibold transition ${
												mallIdx === idx
													? "bg-relo-ink text-white shadow-xs"
													: "bg-white text-relo-body hover:bg-[#e5e8eb]"
											}`}
										>
											{opt.label}
										</button>
									))}
								</div>
							</div>

							<div className="space-y-2.5">
								<p className="text-xs font-semibold text-relo-muted">
									{t.simulator.issueLabel}
								</p>
								<div className="grid grid-cols-3 gap-1.5 rounded-2xl bg-[#e8ebef] p-1">
									{scenarios.map((item) => {
										const active = item.id === scenario.id;
										return (
											<button
												key={item.id}
												type="button"
												onClick={() => setScenarioKey(item.id)}
												className="relative cursor-pointer rounded-xl py-2.5 text-xs font-semibold transition-colors"
											>
												{active ? (
													<motion.span
														layoutId="sim-scenario-pill"
														className="absolute inset-0 rounded-xl bg-white shadow-2xs"
													/>
												) : null}
												<span
													className={`relative z-10 ${
														active
															? "font-bold text-relo-ink"
															: "text-relo-muted"
													}`}
												>
													{item.label}
												</span>
											</button>
										);
									})}
								</div>
							</div>

							<div className="rounded-2xl bg-white p-5">
								<div className="flex items-baseline justify-between">
									<label
										htmlFor={sliderId}
										className="text-xs font-semibold text-relo-muted"
									>
										{t.simulator.priceLabel}
									</label>
									<span className="text-2xl font-extrabold text-relo-ink tabular-nums">
										{mall.symbol}
										{amount.toLocaleString(localeOption.bcp47)}
									</span>
								</div>
								<input
									id={sliderId}
									type="range"
									min={mall.min}
									max={mall.max}
									step={mall.step}
									value={amount}
									onChange={(e) => setAmount(Number(e.target.value))}
									className="mt-3 h-2 w-full cursor-pointer accent-relo-brand"
								/>
								<div className="mt-1 flex justify-between text-[11px] font-medium text-relo-muted tabular-nums">
									<span>
										{mall.symbol}
										{mall.min.toLocaleString(localeOption.bcp47)}
									</span>
									<span>
										{mall.symbol}
										{mall.max.toLocaleString(localeOption.bcp47)}
									</span>
								</div>
							</div>

							<div className="rounded-2xl border border-relo-brand-line bg-white p-4">
								<div className="flex items-center gap-1.5 text-xs font-bold text-relo-brand">
									<Languages className="h-3.5 w-3.5" aria-hidden="true" />
									<span>{t.simulator.previewBadge}</span>
								</div>
								<p className="mt-1.5 text-xs leading-relaxed font-medium text-relo-body">
									“{scenario.englishSnippet}”
								</p>
							</div>
						</div>

						{/* Request preview: the choices on the left, laid out as the request they become */}
						<div className="flex flex-col justify-between rounded-3xl border border-relo-line bg-white p-6 lg:col-span-6">
							<div>
								<p className="text-xs font-bold text-relo-brand">
									{t.simulator.summaryTitle}
								</p>
								<p className="mt-4 text-xs font-semibold text-relo-muted">
									{t.simulator.requestLabel}
								</p>
								<p className="mt-1 flex items-baseline gap-2 text-[40px] leading-none font-extrabold tracking-[-0.03em] text-relo-ink tabular-nums">
									<NumberTicker
										value={amount}
										prefix={mall.symbol}
										decimals={0}
									/>
									<span className="text-base font-bold tracking-normal text-relo-muted">
										{mall.currency}
									</span>
								</p>

								<dl className="mt-6 divide-y divide-relo-line border-y border-relo-line text-sm">
									{summaryRows.map((row) => (
										<div
											key={row.label}
											className="flex items-center justify-between gap-4 py-3"
										>
											<dt className="text-relo-muted">{row.label}</dt>
											<dd className="text-right font-bold text-relo-ink">
												{row.value}
											</dd>
										</div>
									))}
								</dl>

								<p className="mt-6 text-xs font-semibold text-relo-muted">
									{t.simulator.nextTitle}
								</p>
								<ol className="mt-2.5 space-y-2.5">
									{t.simulator.nextSteps.map((step, idx) => (
										<li
											key={step}
											className="flex items-center gap-2.5 text-sm font-medium text-relo-body"
										>
											<span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-relo-brand-soft text-[11px] font-bold text-relo-brand tabular-nums">
												{idx + 1}
											</span>
											<span>{step}</span>
										</li>
									))}
								</ol>
							</div>

							<div className="mt-7">
								<Button
									variant="primary"
									size="lg"
									fullWidth
									onClick={() =>
										onLaunchWithPreset({
											vendor: mall.vendor,
											currency: mall.currency,
											amount: String(amount),
											kind: scenario.kind,
											issue: scenario.issue,
										})
									}
								>
									<span>{t.simulator.applyWithPreset}</span>
									<ArrowRight className="h-4 w-4" aria-hidden="true" />
								</Button>
							</div>
						</div>
					</div>
				</Card>
			</div>
		</section>
	);
}
