/**
 * @module client/components/effects/InteractiveAuroraCanvas
 * @layer View (Ambient Hero Canvas)
 * @purpose Renders a crisp light-mode hero backdrop with pointer-following radial spotlight
 *          and gentle Toss-Blue ambient drift while preserving WCAG AA contrast.
 */

import {
	motion,
	useMotionTemplate,
	useMotionValue,
	useSpring,
} from "motion/react";
import { type ReactNode, useEffect, useRef } from "react";
import { cn } from "@/lib/utils";

interface InteractiveAuroraCanvasProps {
	children: ReactNode;
	className?: string;
	showFloatingBadges?: boolean;
}

const FLOATING_PARCELS = [
	{
		label: "Amazon US · $128.40 환불 완료",
		side: "left-4",
		y: "14%",
		delay: 0,
	},
	{
		label: "AliExpress · 파손 사진 첨부",
		side: "right-4",
		y: "16%",
		delay: 1.4,
	},
	{ label: "Mercari JP · ¥14,800 합의", side: "right-5", y: "72%", delay: 2.6 },
	{
		label: "Taobao · 오배송 외국어 편지",
		side: "left-5",
		y: "74%",
		delay: 3.4,
	},
];

export function InteractiveAuroraCanvas({
	children,
	className,
	showFloatingBadges = false,
}: InteractiveAuroraCanvasProps) {
	const containerRef = useRef<HTMLDivElement | null>(null);
	const mouseX = useMotionValue(520);
	const mouseY = useMotionValue(260);
	const smoothX = useSpring(mouseX, { stiffness: 110, damping: 24, mass: 0.5 });
	const smoothY = useSpring(mouseY, { stiffness: 110, damping: 24, mass: 0.5 });

	const spotlightBg = useMotionTemplate`radial-gradient(560px circle at ${smoothX}px ${smoothY}px, rgba(27, 100, 218, 0.12), rgba(56, 189, 248, 0.05) 45%, transparent 75%)`;

	useEffect(() => {
		const el = containerRef.current;
		if (!el) return;
		const onPointerMove = (event: PointerEvent) => {
			const rect = el.getBoundingClientRect();
			mouseX.set(event.clientX - rect.left);
			mouseY.set(event.clientY - rect.top);
		};
		el.addEventListener("pointermove", onPointerMove, { passive: true });
		return () => el.removeEventListener("pointermove", onPointerMove);
	}, [mouseX, mouseY]);

	return (
		<div
			ref={containerRef}
			className={cn(
				"relative isolate overflow-hidden bg-gradient-to-b from-[#f6f9ff] via-white to-[#f4f6fa]",
				className,
			)}
		>
			<div
				aria-hidden="true"
				className="bg-dot-matrix pointer-events-none absolute inset-0 opacity-70 [mask-image:radial-gradient(ellipse_80%_75%_at_50%_35%,#000_55%,transparent_100%)]"
			/>

			<div
				aria-hidden="true"
				className="animate-aurora-a pointer-events-none absolute -top-28 -left-24 h-96 w-96 rounded-full bg-[#3182f6]/13 blur-3xl"
			/>
			<div
				aria-hidden="true"
				className="animate-aurora-b pointer-events-none absolute top-16 -right-24 h-[26rem] w-[26rem] rounded-full bg-[#38bdf8]/11 blur-3xl"
			/>
			<div
				aria-hidden="true"
				className="animate-aurora-a pointer-events-none absolute -bottom-28 left-1/3 h-80 w-80 rounded-full bg-[#93c5fd]/14 blur-3xl"
			/>

			<motion.div
				aria-hidden="true"
				style={{ background: spotlightBg }}
				className="pointer-events-none absolute inset-0 transition-opacity duration-300"
			/>

			{showFloatingBadges ? (
				<div
					aria-hidden="true"
					className="pointer-events-none absolute inset-0 hidden 2xl:block"
				>
					{FLOATING_PARCELS.map((chip) => (
						<motion.div
							key={chip.label}
							style={{ top: chip.y }}
							animate={{ y: [0, -9, 0] }}
							transition={{
								duration: 5.2,
								repeat: Number.POSITIVE_INFINITY,
								delay: chip.delay,
								ease: "easeInOut",
							}}
							className={`absolute ${chip.side} rounded-full border border-white/90 bg-white/85 px-3 py-1.5 text-[11px] font-bold text-relo-muted shadow-card backdrop-blur-md`}
						>
							<span className="mr-1.5 inline-block h-1.5 w-1.5 rounded-full bg-relo-brand" />
							{chip.label}
						</motion.div>
					))}
				</div>
			) : null}

			<div className="relative z-10">{children}</div>
		</div>
	);
}
