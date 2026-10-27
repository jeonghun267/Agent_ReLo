/**
 * @module client/features/landing/RefundSimulatorSection
 * @layer View (Interactive Expected Refund Calculator)
 * @purpose Lets consumers estimate protected refund value across USD, EUR, JPY, and KRW
 *          using a unified Toss Blue + Slate palette and launch the 3-minute wizard.
 */

import {
	ArcElement,
	BarElement,
	CategoryScale,
	Chart as ChartJS,
	Legend,
	LinearScale,
	Tooltip,
} from "chart.js";
import { ArrowRight, Languages } from "lucide-react";
import { motion } from "motion/react";
import { useId, useMemo, useState } from "react";
import { Bar, Doughnut } from "react-chartjs-2";
import { NumberTicker } from "@/client/components/effects/InteractivePrimitives";
import { Button, Card } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import type { ClaimKind, CurrencyCode } from "@/client/types";

ChartJS.register(
	CategoryScale,
	LinearScale,
	BarElement,
	ArcElement,
	Tooltip,
	Legend,
);

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
				soloRate: 0.52,
				reloRate: 0.96,
				issue: t.simulator.scenarios.damaged.issue,
				englishSnippet:
					"The item arrived visibly damaged upon delivery, as shown in the attached defect photos.",
			},
			{
				id: "wrong" as const,
				label: t.simulator.scenarios.wrong.label,
				kind: "refund" as ClaimKind,
				soloRate: 0.58,
				reloRate: 0.98,
				issue: t.simulator.scenarios.wrong.issue,
				englishSnippet:
					"The delivered item does not match the ordered option on the receipt, and accessories are missing.",
			},
			{
				id: "defect" as const,
				label: t.simulator.scenarios.defect.label,
				kind: "exchange" as ClaimKind,
				soloRate: 0.45,
				reloRate: 0.92,
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

	const soloExpected = Math.round(amount * scenario.soloRate);
	const reloExpected = Math.round(amount * scenario.reloRate);
	const extraSaved = Math.max(0, reloExpected - soloExpected);

	const barData = useMemo(
		() => ({
			labels: [t.simulator.barSolo, t.simulator.barRelo],
			datasets: [
				{
					label: `${t.simulator.expectedLabel} (${mall.currency})`,
					data: [soloExpected, reloExpected],
					backgroundColor: ["#cbd5e1", "#1b64da"],
					borderRadius: 12,
					barThickness: 44,
				},
			],
		}),
		[t, mall.currency, soloExpected, reloExpected],
	);

	const doughnutData = useMemo(
		() => ({
			labels: [t.simulator.expectedLabel, " Gap"],
			datasets: [
				{
					data: [
						Math.round(scenario.reloRate * 100),
						Math.round((1 - scenario.reloRate) * 100),
					],
					backgroundColor: ["#1b64da", "#e2e8f0"],
					borderWidth: 0,
				},
			],
		}),
		[t, scenario.reloRate],
	);

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

						{/* Live Chart.js Visualizations (Unified Toss Blue + Slate) */}
						<div className="flex flex-col justify-between rounded-3xl border border-relo-line bg-white p-5 lg:col-span-6">
							<div className="grid grid-cols-1 gap-4 sm:grid-cols-12 sm:items-center">
								<div className="h-52 sm:col-span-8">
									<Bar
										aria-label={t.simulator.title}
										data={barData}
										options={{
											responsive: true,
											maintainAspectRatio: false,
											plugins: { legend: { display: false } },
											scales: {
												y: {
													beginAtZero: true,
													grid: { color: "rgba(203, 213, 225, 0.35)" },
												},
												x: { grid: { display: false } },
											},
										}}
									/>
								</div>

								<div className="flex flex-col items-center justify-center sm:col-span-4">
									<div className="relative h-28 w-28">
										<Doughnut
											aria-label={`${t.simulator.completenessLabel} ${Math.round(scenario.reloRate * 100)}%`}
											data={doughnutData}
											options={{
												cutout: "74%",
												plugins: { legend: { display: false } },
											}}
										/>
										<div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
											<span className="text-lg font-extrabold text-relo-brand tabular-nums">
												{Math.round(scenario.reloRate * 100)}%
											</span>
											<span className="text-[10px] font-bold text-relo-muted">
												{t.simulator.completenessLabel}
											</span>
										</div>
									</div>
								</div>
							</div>

							<div className="mt-5 rounded-2xl bg-[#f4f6f9] p-4">
								<div className="flex flex-wrap items-center justify-between gap-3">
									<div>
										<p className="text-xs font-bold text-relo-muted">
											{t.simulator.extraTitle}
										</p>
										<p className="mt-0.5 text-xl font-extrabold text-relo-brand">
											+{" "}
											<NumberTicker
												value={extraSaved}
												prefix={mall.symbol}
												decimals={0}
											/>{" "}
											{t.simulator.extraSuffix}
										</p>
									</div>
									<Button
										variant="primary"
										size="md"
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
					</div>
				</Card>
			</div>
		</section>
	);
}
