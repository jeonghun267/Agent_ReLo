/**
 * @module client/components/ReloOrbEmblem
 * @layer View (Brand Motion Emblem)
 * @purpose Characterless Toss-inspired 3D Glass Globe & Flight Verification Emblem
 *          used on empty states, completion screens, and authentication headers.
 *          Uses a unified Toss Blue palette with zero animal mascot imagery.
 */

import { motion } from "motion/react";
import { cn } from "@/lib/utils";

export type OrbVariant = "default" | "processing" | "verified" | "still";
export type OrbSize = "sm" | "md" | "lg" | "hero";

interface ReloOrbEmblemProps {
	variant?: OrbVariant;
	size?: OrbSize;
	speech?: string;
	badge?: string;
	className?: string;
}

const SIZE_CLASS: Record<OrbSize, string> = {
	sm: "w-16 h-16",
	md: "w-24 h-24",
	lg: "w-32 h-32",
	hero: "w-44 h-44 sm:w-52 sm:h-52",
};

export function ReloOrbEmblem({
	variant = "default",
	size = "md",
	speech,
	badge,
	className,
}: ReloOrbEmblemProps) {
	const isProcessing = variant === "processing";
	const isVerified = variant === "verified";

	return (
		<div className={cn("flex flex-col items-center", className)}>
			<motion.div
				initial={{ opacity: 0, scale: 0.92 }}
				animate={{
					opacity: 1,
					scale: 1,
					y: variant === "still" ? 0 : [0, -5, 0],
				}}
				transition={{
					opacity: { duration: 0.3 },
					scale: { duration: 0.35 },
					y: {
						duration: isProcessing ? 1.6 : 3.4,
						repeat: variant === "still" ? 0 : Number.POSITIVE_INFINITY,
						ease: "easeInOut",
					},
				}}
				className={cn(
					"relative flex items-center justify-center",
					SIZE_CLASS[size],
				)}
			>
				<div
					aria-hidden="true"
					className={cn(
						"absolute inset-1 rounded-full blur-xl transition-colors duration-500",
						isVerified ? "bg-sky-400/35" : "bg-blue-500/25",
					)}
				/>

				<svg
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 160 160"
					role="img"
					aria-label="ReLo 글로벌 직구 환불 심볼"
					className="relative h-full w-full overflow-visible"
				>
					<title>ReLo 글로벌 직구 환불 심볼</title>
					<defs>
						<radialGradient id="reloOrbCoreUnified" cx="35%" cy="28%" r="70%">
							<stop
								offset="0%"
								stopColor={isVerified ? "#93c5fd" : "#60a5fa"}
							/>
							<stop
								offset="52%"
								stopColor={isVerified ? "#2563eb" : "#1b64da"}
							/>
							<stop offset="100%" stopColor="#0f296b" />
						</radialGradient>
						<linearGradient
							id="reloGlassCardUnified"
							x1="0"
							y1="0"
							x2="1"
							y2="1"
						>
							<stop offset="0%" stopColor="rgba(255,255,255,0.96)" />
							<stop offset="100%" stopColor="rgba(232,242,255,0.86)" />
						</linearGradient>
					</defs>

					<ellipse
						cx="80"
						cy="82"
						rx="64"
						ry="24"
						transform="rotate(-22 80 82)"
						fill="none"
						stroke="#3b82f6"
						strokeOpacity="0.34"
						strokeWidth="2"
						strokeDasharray="5 5"
					/>

					<circle cx="80" cy="80" r="46" fill="url(#reloOrbCoreUnified)" />

					<path
						d="M 42 66 Q 80 50 118 66 M 40 92 Q 80 108 120 92"
						fill="none"
						stroke="rgba(255,255,255,0.22)"
						strokeWidth="1.4"
					/>
					<ellipse
						cx="80"
						cy="80"
						rx="22"
						ry="45"
						fill="none"
						stroke="rgba(255,255,255,0.2)"
						strokeWidth="1.4"
					/>

					<ellipse
						cx="64"
						cy="54"
						rx="18"
						ry="9"
						transform="rotate(-24 64 54)"
						fill="rgba(255,255,255,0.34)"
					/>

					<path
						d="M 24 98 C 48 44, 108 38, 136 68"
						fill="none"
						stroke="#ffffff"
						strokeWidth="3.5"
						strokeLinecap="round"
					/>
					{/* Directional airplane silhouette at flight tip */}
					<g transform="translate(134, 67) rotate(32)">
						<path d="M 7 0 L -5 -4.5 L -2.5 0 L -5 4.5 Z" fill="#ffffff" />
					</g>

					<g transform="translate(86, 86)">
						<rect
							x="0"
							y="0"
							width="52"
							height="36"
							rx="11"
							fill="url(#reloGlassCardUnified)"
							stroke="rgba(255,255,255,0.9)"
							strokeWidth="1.5"
						/>
						{isProcessing ? (
							<>
								<rect
									x="10"
									y="10"
									width="32"
									height="4"
									rx="2"
									fill="#1b64da"
								/>
								<rect
									x="10"
									y="19"
									width="22"
									height="4"
									rx="2"
									fill="#93c5fd"
								/>
							</>
						) : (
							<path
								d="M 16 18 L 23 25 L 37 11"
								fill="none"
								stroke="#1b64da"
								strokeWidth="3.5"
								strokeLinecap="round"
								strokeLinejoin="round"
							/>
						)}
					</g>
				</svg>
			</motion.div>

			{speech ? (
				<motion.div
					initial={{ opacity: 0, y: 6 }}
					animate={{ opacity: 1, y: 0 }}
					transition={{ duration: 0.25 }}
					className="mt-3 max-w-md text-center"
				>
					{badge ? (
						<span className="mb-1.5 inline-flex items-center rounded-full bg-relo-brand-soft px-2.5 py-0.5 text-[11px] font-semibold text-relo-brand">
							{badge}
						</span>
					) : null}
					<p className="text-sm leading-relaxed font-medium text-relo-body">
						{speech}
					</p>
				</motion.div>
			) : null}
		</div>
	);
}
