/**
 * @module client/features/landing/PhoneHardwareFrame
 * @layer View (Realistic Smartphone Chassis Component)
 * @purpose Renders an authentic vertical titanium smartphone hardware bezel (9:19.2 ratio)
 *          with side buttons, Dynamic Island, status bar, glass reflection, and home indicator.
 */

import { BatteryFull, Signal, Wifi } from "lucide-react";
import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

interface PhoneHardwareFrameProps {
	children: ReactNode;
	className?: string;
}

export function PhoneHardwareFrame({
	children,
	className,
}: PhoneHardwareFrameProps) {
	return (
		<div
			className={cn(
				"relative mx-auto h-[568px] w-[278px] shrink-0 select-none sm:h-[612px] sm:w-[300px]",
				className,
			)}
		>
			{/* Left Hardware Buttons (Action + Volume Up/Down) */}
			<span
				aria-hidden="true"
				className="absolute top-24 -left-[3px] h-7 w-[3px] rounded-l-sm bg-slate-500"
			/>
			<span
				aria-hidden="true"
				className="absolute top-36 -left-[3px] h-12 w-[3px] rounded-l-sm bg-slate-500"
			/>
			<span
				aria-hidden="true"
				className="absolute top-51 -left-[3px] h-12 w-[3px] rounded-l-sm bg-slate-500"
			/>
			{/* Right Side Power Button */}
			<span
				aria-hidden="true"
				className="absolute top-40 -right-[3px] h-16 w-[3px] rounded-r-sm bg-slate-500"
			/>

			{/* Brushed Titanium Metallic Rim */}
			<div className="h-full w-full rounded-[50px] bg-linear-to-b from-[#64748b] via-[#1e293b] to-[#0f172a] p-[3.5px] shadow-[0_38px_80px_-18px_rgba(15,23,42,0.38),0_12px_28px_-10px_rgba(27,100,218,0.18)]">
				{/* Inner OLED Black Bezel */}
				<div className="relative flex h-full w-full flex-col overflow-hidden rounded-[47px] bg-[#0a0f18] p-[9px]">
					{/* Tempered Glass Diagonal Specular Highlight */}
					<div
						aria-hidden="true"
						className="pointer-events-none absolute inset-0 z-20 rounded-[44px] bg-linear-to-tr from-transparent via-white/6 to-white/14"
					/>

					{/* Bright App Screen Viewport */}
					<div className="relative flex h-full w-full flex-col overflow-hidden rounded-[39px] bg-[#f4f6f9]">
						{/* Top Status Bar + Dynamic Island */}
						<div className="relative z-10 flex h-11 shrink-0 items-center justify-between px-6 pt-1.5 text-[11px] font-bold text-[#191f28]">
							<span className="tracking-tight tabular-nums">9:41</span>

							{/* Dynamic Island */}
							<div
								aria-hidden="true"
								className="absolute top-2.5 left-1/2 flex h-[23px] w-[86px] -translate-x-1/2 items-center justify-end rounded-full bg-[#090d14] pr-2.5 shadow-inner"
							>
								<span className="h-2.5 w-2.5 rounded-full bg-[#172554] ring-1 ring-sky-400/30" />
							</div>

							<span
								aria-hidden="true"
								className="inline-flex items-center gap-1 text-[#191f28]"
							>
								<Signal className="h-3 w-3" />
								<Wifi className="h-3 w-3" />
								<BatteryFull className="h-3.5 w-3.5" />
							</span>
						</div>

						{/* Dynamic Screen Content */}
						<div className="relative flex flex-1 flex-col overflow-hidden px-4 pt-2 pb-4">
							{children}
						</div>

						{/* Bottom iOS Home Indicator */}
						<div className="flex h-5 shrink-0 items-center justify-center pb-1.5">
							<span
								aria-hidden="true"
								className="h-1 w-28 rounded-full bg-slate-900/22"
							/>
						</div>
					</div>
				</div>
			</div>
		</div>
	);
}
