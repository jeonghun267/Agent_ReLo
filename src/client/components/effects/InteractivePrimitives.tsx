/**
 * @module client/components/effects/InteractivePrimitives
 * @layer View (Tactile Motion Primitives & Global Store Marquee)
 * @purpose Provides magnetic button wrappers, animated numeric tickers, and the
 *          4-language global overseas store marquee with unified neutral currency badges.
 */

import {
	animate,
	motion,
	useInView,
	useMotionValue,
	useSpring,
} from "motion/react";
import {
	type MouseEvent,
	type ReactNode,
	useEffect,
	useMemo,
	useRef,
	useState,
} from "react";
import { useI18n } from "@/client/i18n";
import type { CurrencyCode } from "@/client/types";
import { cn } from "@/lib/utils";

export function MagneticWrap({
	children,
	className,
	strength = 0.2,
}: {
	children: ReactNode;
	className?: string;
	strength?: number;
}) {
	const x = useMotionValue(0);
	const y = useMotionValue(0);
	const springX = useSpring(x, { stiffness: 200, damping: 16, mass: 0.3 });
	const springY = useSpring(y, { stiffness: 200, damping: 16, mass: 0.3 });

	const handleMove = (event: MouseEvent<HTMLDivElement>) => {
		const rect = event.currentTarget.getBoundingClientRect();
		const dx = event.clientX - (rect.left + rect.width / 2);
		const dy = event.clientY - (rect.top + rect.height / 2);
		x.set(dx * strength);
		y.set(dy * strength);
	};

	const handleLeave = () => {
		x.set(0);
		y.set(0);
	};

	return (
		<motion.div
			onMouseMove={handleMove}
			onMouseLeave={handleLeave}
			style={{ x: springX, y: springY }}
			className={cn("inline-block", className)}
		>
			{children}
		</motion.div>
	);
}

export function NumberTicker({
	value,
	prefix = "",
	suffix = "",
	decimals = 0,
	className,
}: {
	value: number;
	prefix?: string;
	suffix?: string;
	decimals?: number;
	className?: string;
}) {
	const { localeOption } = useI18n();
	const ref = useRef<HTMLSpanElement | null>(null);
	const isInView = useInView(ref, { once: true, margin: "-20px" });
	const [display, setDisplay] = useState(value);

	useEffect(() => {
		if (!isInView) return;
		const controls = animate(0, value, {
			duration: 0.85,
			ease: [0.16, 1, 0.3, 1],
			onUpdate: (latest) => {
				setDisplay(latest);
			},
		});
		return () => controls.stop();
	}, [isInView, value]);

	const formatted = new Intl.NumberFormat(localeOption.bcp47, {
		minimumFractionDigits: decimals,
		maximumFractionDigits: decimals,
	}).format(display);

	return (
		<span ref={ref} className={cn("tabular-nums", className)}>
			{prefix}
			{formatted}
			{suffix}
		</span>
	);
}

export interface GlobalMallPreset {
	name: string;
	country: string;
	currency: CurrencyCode;
	sampleOrder: string;
	tag: string;
}

export function MallMarquee({
	onSelectMall,
}: {
	onSelectMall: (mall: GlobalMallPreset) => void;
}) {
	const { t } = useI18n();

	const mallPresets = useMemo<GlobalMallPreset[]>(
		() => [
			{
				name: "Amazon US",
				country: t.malls.us,
				currency: "USD",
				sampleOrder: "114-8920411-33012",
				tag: t.malls.tagAmazon,
			},
			{
				name: "AliExpress",
				country: t.malls.global,
				currency: "USD",
				sampleOrder: "81920488192014",
				tag: t.malls.tagAli,
			},
			{
				name: "Taobao · Tmall",
				country: t.malls.cn,
				currency: "CNY",
				sampleOrder: "TB-39021849920",
				tag: t.malls.tagTaobao,
			},
			{
				name: "Mercari · Amazon JP",
				country: t.malls.jp,
				currency: "JPY",
				sampleOrder: "250-7719204-8812",
				tag: t.malls.tagMercari,
			},
			{
				name: "iHerb",
				country: t.malls.us,
				currency: "USD",
				sampleOrder: "IH-908112405",
				tag: t.malls.tagIherb,
			},
			{
				name: "eBay",
				country: t.malls.usUk,
				currency: "USD",
				sampleOrder: "21-10948-55019",
				tag: t.malls.tagEbay,
			},
			{
				name: "Farfetch · SSENSE",
				country: t.malls.euCa,
				currency: "EUR",
				sampleOrder: "FF-77410298",
				tag: t.malls.tagFarfetch,
			},
			{
				name: "Temu · Shein",
				country: t.malls.global,
				currency: "KRW",
				sampleOrder: "PO-082-9910421",
				tag: t.malls.tagTemu,
			},
		],
		[t],
	);

	return (
		<div className="relative overflow-hidden py-2 [mask-image:linear-gradient(to_right,transparent,#000_8%,#000_92%,transparent)]">
			<div className="animate-marquee flex w-max gap-3">
				{(["track-a", "track-b"] as const).flatMap((track) =>
					mallPresets.map((mall) => (
						<button
							key={`${track}-${mall.name}`}
							type="button"
							onClick={() => onSelectMall(mall)}
							className="group flex shrink-0 cursor-pointer items-center gap-3 rounded-2xl border border-relo-line bg-white px-4 py-2.5 text-left shadow-2xs transition-all hover:-translate-y-0.5 hover:border-relo-brand hover:shadow-card"
						>
							{/* Unified calm Toss neutral slate pill — no clashing multi-colored currency badges */}
							<span className="flex h-8 w-10 items-center justify-center rounded-xl bg-[#f2f4f6] text-[11px] font-extrabold tracking-tight text-[#333d4b] transition-colors group-hover:bg-relo-brand group-hover:text-white">
								{mall.currency}
							</span>
							<div>
								<p className="text-sm font-bold text-relo-ink">{mall.name}</p>
								<p className="text-[11px] font-medium text-relo-muted">
									{mall.country} · {mall.tag}
								</p>
							</div>
						</button>
					)),
				)}
			</div>
		</div>
	);
}
