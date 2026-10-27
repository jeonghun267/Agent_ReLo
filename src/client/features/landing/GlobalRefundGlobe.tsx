/**
 * @module client/features/landing/GlobalRefundGlobe
 * @layer View (Interactive 3D Earth & Flight Corridor Section)
 * @purpose Renders the Toss-style global refund network section with localized route pills,
 *          settlement preview card, and interactive drag-to-rotate 3D globe canvas.
 */

import { ArrowRight, CheckCircle2, Globe, Plane } from "lucide-react";
import { motion } from "motion/react";
import { useEffect, useMemo, useRef, useState } from "react";
import {
	type FlightCorridor,
	renderGlobeScene,
} from "@/client/features/landing/globeCanvasRenderer";
import { useI18n } from "@/client/i18n";

export type { FlightCorridor };

interface GlobalRefundGlobeProps {
	onSelectCorridor: (corridor: FlightCorridor) => void;
}

export function GlobalRefundGlobe({
	onSelectCorridor,
}: GlobalRefundGlobeProps) {
	const { t } = useI18n();
	const canvasRef = useRef<HTMLCanvasElement | null>(null);
	const [activeIdx, setActiveIdx] = useState(0);
	const activeIdxRef = useRef(0);
	const yawRef = useRef(0.54);
	const manualDragRef = useRef(false);
	const targetYawRef = useRef<number | null>(null);
	const draggingRef = useRef<{ active: boolean; lastX: number }>({
		active: false,
		lastX: 0,
	});

	const corridors = useMemo<FlightCorridor[]>(
		() => [
			{
				id: "us-sea",
				country: t.globe.corridors.usSea.country,
				city: "Seattle",
				vendor: "Amazon US",
				lat: 47.6062,
				lon: -122.3321,
				targetYaw: 0.26,
				currency: "USD",
				amount: "184.00",
				displayGain: "+$184.00",
				statusTag: t.globe.corridors.usSea.status,
				kind: "refund",
				issue: t.globe.corridors.usSea.issue,
			},
			{
				id: "jp-tyo",
				country: t.globe.corridors.jpTyo.country,
				city: "Tokyo",
				vendor: "Mercari · Amazon JP",
				lat: 35.6762,
				lon: 139.6503,
				targetYaw: 0.68,
				currency: "JPY",
				amount: "14800",
				displayGain: "+¥14,800",
				statusTag: t.globe.corridors.jpTyo.status,
				kind: "refund",
				issue: t.globe.corridors.jpTyo.issue,
			},
			{
				id: "cn-szx",
				country: t.globe.corridors.cnSzx.country,
				city: "Shenzhen",
				vendor: "AliExpress · Taobao",
				lat: 22.5431,
				lon: 114.0579,
				targetYaw: 0.56,
				currency: "USD",
				amount: "92.50",
				displayGain: "+$92.50",
				statusTag: t.globe.corridors.cnSzx.status,
				kind: "refund",
				issue: t.globe.corridors.cnSzx.issue,
			},
			{
				id: "eu-lon",
				country: t.globe.corridors.euLon.country,
				city: "London",
				vendor: "Farfetch · SSENSE",
				lat: 51.5072,
				lon: -0.1276,
				targetYaw: 1.16,
				currency: "EUR",
				amount: "210.00",
				displayGain: "+€210.00",
				statusTag: t.globe.corridors.euLon.status,
				kind: "refund",
				issue: t.globe.corridors.euLon.issue,
			},
			{
				id: "us-lax",
				country: t.globe.corridors.usLax.country,
				city: "Los Angeles",
				vendor: "iHerb · eBay",
				lat: 34.0522,
				lon: -118.2437,
				targetYaw: 0.22,
				currency: "USD",
				amount: "64.20",
				displayGain: "+$64.20",
				statusTag: t.globe.corridors.usLax.status,
				kind: "refund",
				issue: t.globe.corridors.usLax.issue,
			},
		],
		[t],
	);

	const seoulHubLabelRef = useRef(t.globe.seoulHubLabel);
	seoulHubLabelRef.current = t.globe.seoulHubLabel;
	const corridorsRef = useRef(corridors);
	corridorsRef.current = corridors;

	const handleSelectRoute = (idx: number) => {
		setActiveIdx(idx);
		activeIdxRef.current = idx;
		const chosen = corridors[idx];
		if (chosen) {
			targetYawRef.current = chosen.targetYaw;
		}
	};

	useEffect(() => {
		const canvas = canvasRef.current;
		if (!canvas) return;
		const ctx = canvas.getContext("2d");
		if (!ctx) return;

		let rafId = 0;
		const pitch = 0.34;
		let phase = 0;

		const renderFrame = () => {
			const rect = canvas.getBoundingClientRect();
			const dpr = Math.min(window.devicePixelRatio || 1, 2);
			const width = Math.max(280, Math.floor(rect.width));
			const height = Math.max(280, Math.floor(rect.height));

			if (canvas.width !== width * dpr || canvas.height !== height * dpr) {
				canvas.width = width * dpr;
				canvas.height = height * dpr;
			}

			ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
			ctx.clearRect(0, 0, width, height);

			if (!draggingRef.current.active) {
				if (targetYawRef.current !== null) {
					const diff = targetYawRef.current - yawRef.current;
					yawRef.current += diff * 0.09;
					if (Math.abs(diff) < 0.004) {
						targetYawRef.current = null;
					}
				} else if (!manualDragRef.current) {
					yawRef.current = 0.56 + Math.sin(phase * 0.55) * 0.34;
				} else {
					yawRef.current += 0.0009;
				}
			}
			phase += 0.0055;

			renderGlobeScene({
				ctx,
				width,
				height,
				yaw: yawRef.current,
				pitch,
				phase,
				corridors: corridorsRef.current,
				activeIdx: activeIdxRef.current,
				seoulHubLabel: seoulHubLabelRef.current,
			});

			rafId = window.requestAnimationFrame(renderFrame);
		};

		rafId = window.requestAnimationFrame(renderFrame);
		return () => window.cancelAnimationFrame(rafId);
	}, []);

	const activeCorridor = corridors[activeIdx] ?? corridors[0];

	return (
		<section className="relative overflow-hidden bg-[#081226] py-20 text-white sm:py-28">
			<div
				aria-hidden="true"
				className="pointer-events-none absolute -top-40 left-1/2 h-[520px] w-[860px] -translate-x-1/2 rounded-full bg-blue-500/14 blur-3xl"
			/>

			<div className="relative mx-auto max-w-6xl px-4 sm:px-6">
				<div className="grid items-center gap-10 lg:grid-cols-12 lg:gap-8">
					{/* Left Copy & Route Controls */}
					<div className="space-y-6 lg:col-span-5">
						<p className="inline-flex items-center gap-2 text-sm font-semibold text-sky-400">
							<Globe className="h-4 w-4" aria-hidden="true" />
							<span>{t.globe.eyebrow}</span>
						</p>

						<h2 className="text-3xl leading-[1.22] font-bold tracking-[-0.035em] text-white sm:text-[40px]">
							{t.globe.titleLine1}
							<br />
							{t.globe.titleLine2}
						</h2>

						<p className="text-[16px] leading-relaxed text-slate-300">
							{t.globe.description}
						</p>

						<div className="flex flex-wrap gap-2 pt-1">
							{corridors.map((route, idx) => {
								const active = idx === activeIdx;
								return (
									<button
										key={route.id}
										type="button"
										onClick={() => handleSelectRoute(idx)}
										className={`inline-flex cursor-pointer items-center gap-1.5 rounded-full px-3.5 py-2 text-xs font-semibold transition-all ${
											active
												? "bg-white text-[#0b172a] shadow-lg"
												: "bg-white/10 text-slate-200 hover:bg-white/18"
										}`}
									>
										<Plane
											className={`h-3.5 w-3.5 ${active ? "text-relo-brand" : "text-sky-300"}`}
											aria-hidden="true"
										/>
										<span>
											{route.country} · {route.vendor.split(" · ")[0]}
										</span>
									</button>
								);
							})}
						</div>

						{activeCorridor ? (
							<motion.div
								key={activeCorridor.id}
								initial={{ opacity: 0, y: 8 }}
								animate={{ opacity: 1, y: 0 }}
								transition={{ duration: 0.25 }}
								className="rounded-3xl border border-sky-300/20 bg-white/8 p-5 backdrop-blur-md"
							>
								<div className="flex items-center justify-between gap-3">
									<div>
										<p className="text-xs font-medium text-sky-200/90">
											{activeCorridor.city} ✈ Seoul · {t.globe.routeSuffix}
										</p>
										<p className="mt-1 text-lg font-bold text-white">
											{activeCorridor.vendor}
										</p>
									</div>
									<span className="text-2xl font-extrabold text-sky-300 tabular-nums">
										{activeCorridor.displayGain}
									</span>
								</div>

								<div className="mt-4 flex flex-wrap items-center justify-between gap-3 border-t border-white/12 pt-3.5">
									<span className="inline-flex items-center gap-1.5 text-xs font-semibold text-sky-200">
										<CheckCircle2
											className="h-3.5 w-3.5 text-sky-300"
											aria-hidden="true"
										/>
										<span>{activeCorridor.statusTag}</span>
									</span>
									<button
										type="button"
										onClick={() => onSelectCorridor(activeCorridor)}
										className="inline-flex cursor-pointer items-center gap-1.5 rounded-full bg-relo-brand px-4 py-2 text-xs font-bold text-white transition hover:bg-relo-brand-hover"
									>
										<span>{t.globe.startThisMall}</span>
										<ArrowRight className="h-3.5 w-3.5" aria-hidden="true" />
									</button>
								</div>
							</motion.div>
						) : null}
					</div>

					{/* Right Interactive 3D Canvas Globe */}
					<div className="relative lg:col-span-7">
						<div className="relative mx-auto aspect-square w-full max-w-[540px]">
							<canvas
								ref={canvasRef}
								aria-label={t.globe.canvasAria}
								onPointerDown={(e) => {
									draggingRef.current = { active: true, lastX: e.clientX };
									manualDragRef.current = true;
									targetYawRef.current = null;
								}}
								onPointerMove={(e) => {
									if (!draggingRef.current.active) return;
									const dx = e.clientX - draggingRef.current.lastX;
									draggingRef.current.lastX = e.clientX;
									yawRef.current += dx * 0.006;
								}}
								onPointerUp={() => {
									draggingRef.current.active = false;
								}}
								onPointerLeave={() => {
									draggingRef.current.active = false;
								}}
								className="h-full w-full cursor-grab touch-none active:cursor-grabbing"
							/>

							<p className="pointer-events-none absolute inset-x-0 bottom-2 text-center text-xs font-medium text-slate-300/80">
								{t.globe.dragHint}
							</p>
						</div>
					</div>
				</div>
			</div>
		</section>
	);
}
