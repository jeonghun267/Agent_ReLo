/**
 * @module client/features/landing/PhoneStoryScreens
 * @layer View (Smartphone Interior Screen Views for 3D Scroll Storytelling)
 * @purpose Renders the 3 interactive app screens inside PhoneHardwareFrame
 *          (Receipt Scan, Foreign Letter Auto-Draft, Card Refund Verification).
 */

import { CheckCircle2, FileText, Languages, Scissors } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import type { TranslationDictionary } from "@/client/i18n/types";

type PhoneSceneCopy = TranslationDictionary["phoneStory"]["scenes"][number];

interface PhoneStoryScreensProps {
	activeScene: number;
	current: PhoneSceneCopy | undefined;
}

export function PhoneStoryScreens({
	activeScene,
	current,
}: PhoneStoryScreensProps) {
	return (
		<AnimatePresence mode="wait">
			{activeScene === 0 && current ? (
				<motion.div
					key="screen-01"
					initial={{ opacity: 0, y: 16 }}
					animate={{ opacity: 1, y: 0 }}
					exit={{ opacity: 0, y: -12 }}
					transition={{ duration: 0.26 }}
					className="flex h-full flex-col justify-between"
				>
					<div className="space-y-3">
						<div className="flex items-center justify-between rounded-2xl bg-white px-3.5 py-2.5 shadow-2xs">
							<span className="text-xs font-bold text-relo-ink">
								{current.screenHeader}
							</span>
							<span className="rounded-full bg-relo-brand-soft px-2 py-0.5 text-[10px] font-bold text-relo-brand">
								{current.screenStatus}
							</span>
						</div>

						<div className="rounded-2xl border border-slate-200/80 bg-white p-3.5 shadow-2xs">
							<div className="flex items-center gap-2 text-xs font-bold text-relo-ink">
								<FileText
									className="h-4 w-4 text-relo-brand"
									aria-hidden="true"
								/>
								<span>Amazon_Order_Receipt.pdf</span>
							</div>
							<p className="mt-2.5 text-[10px] font-semibold text-relo-muted">
								{current.screenSubTitle}
							</p>
							<div className="mt-1.5 space-y-1.5 rounded-xl bg-[#f8fafc] p-2.5 text-[11px]">
								<div className="flex justify-between">
									<span className="text-relo-muted">Store</span>
									<span className="font-bold text-relo-ink">Amazon US</span>
								</div>
								<div className="flex justify-between">
									<span className="text-relo-muted">Order</span>
									<span className="font-bold text-relo-ink tabular-nums">
										#114-8920411
									</span>
								</div>
								<div className="flex justify-between">
									<span className="text-relo-muted">Paid</span>
									<span className="font-extrabold text-relo-brand tabular-nums">
										USD 184.00
									</span>
								</div>
							</div>
						</div>

						<div className="rounded-2xl border border-dashed border-relo-brand/50 bg-relo-brand-soft/45 p-3">
							<div className="flex items-center justify-between text-[11px] font-bold text-relo-brand">
								<span className="inline-flex items-center gap-1">
									<Scissors className="h-3.5 w-3.5" aria-hidden="true" />
									<span>{current.popRightTitle}</span>
								</span>
								<span>1.2 MB</span>
							</div>
							<div className="mt-2 h-20 rounded-xl bg-white p-2.5">
								<div className="h-2.5 w-24 rounded-full bg-slate-200 line-through" />
								<div className="mt-2 flex h-10 items-center justify-center rounded-lg border border-relo-brand/40 bg-blue-50/70 text-[11px] font-bold text-relo-brand">
									{current.popRightSub}
								</div>
							</div>
						</div>
					</div>

					<div className="rounded-2xl bg-relo-brand py-2.5 text-center text-xs font-bold text-white">
						✓ {current.screenStatus}
					</div>
				</motion.div>
			) : null}

			{activeScene === 1 && current ? (
				<motion.div
					key="screen-02"
					initial={{ opacity: 0, y: 16 }}
					animate={{ opacity: 1, y: 0 }}
					exit={{ opacity: 0, y: -12 }}
					transition={{ duration: 0.26 }}
					className="flex h-full flex-col justify-between"
				>
					<div className="space-y-3">
						<div className="flex items-center justify-between rounded-2xl bg-white px-3.5 py-2.5 shadow-2xs">
							<span className="text-xs font-bold text-relo-ink">
								{current.screenHeader}
							</span>
							<span className="rounded-full bg-relo-brand-soft px-2 py-0.5 text-[10px] font-bold text-relo-brand">
								{current.screenStatus}
							</span>
						</div>

						<div className="rounded-2xl bg-white p-3.5 shadow-2xs">
							<p className="text-[10px] font-bold text-relo-muted">
								{current.screenSubTitle}
							</p>
							<p className="mt-1 rounded-xl bg-[#f2f4f6] px-3 py-2 text-xs font-semibold text-relo-ink">
								“상자를 열었는데 모서리가 깨져 있어요.”
							</p>
						</div>

						<div className="rounded-2xl border border-relo-brand-line bg-white p-3.5 shadow-2xs">
							<div className="flex items-center gap-1.5 text-[11px] font-bold text-relo-brand">
								<Languages className="h-3.5 w-3.5" aria-hidden="true" />
								<span>EN · JP · ZH Auto-Ready</span>
							</div>
							<p className="mt-2 text-[11px] leading-relaxed font-medium text-relo-body">
								Dear Customer Support,
								<br />
								Order <strong>#114-8920411</strong> arrived with cracked housing
								as shown in the attached photo. Please issue a full refund of{" "}
								<strong className="text-relo-brand">USD 184.00</strong> without
								return shipping fees.
							</p>
						</div>
					</div>

					<div className="rounded-2xl bg-relo-brand py-2.5 text-center text-xs font-bold text-white">
						✓ {current.screenStatus}
					</div>
				</motion.div>
			) : null}

			{activeScene === 2 && current ? (
				<motion.div
					key="screen-03"
					initial={{ opacity: 0, y: 16 }}
					animate={{ opacity: 1, y: 0 }}
					exit={{ opacity: 0, y: -12 }}
					transition={{ duration: 0.26 }}
					className="flex h-full flex-col justify-between"
				>
					<div className="space-y-3">
						<div className="flex items-center justify-between rounded-2xl bg-white px-3.5 py-2.5 shadow-2xs">
							<span className="text-xs font-bold text-relo-ink">
								{current.screenHeader}
							</span>
							<span className="rounded-full bg-relo-brand-soft px-2 py-0.5 text-[10px] font-bold text-relo-brand">
								{current.screenStatus}
							</span>
						</div>

						<div className="rounded-3xl bg-linear-to-br from-[#1b64da] to-[#0f3d91] p-4 text-white shadow-md">
							<p className="text-[11px] font-medium text-sky-200">
								AMZ*REFUND · VISA 4821
							</p>
							<p className="mt-1 text-2xl font-extrabold tracking-tight tabular-nums">
								+$184.00
							</p>
							<p className="mt-2 inline-flex items-center gap-1 rounded-full bg-white/15 px-2.5 py-0.5 text-[10px] font-semibold text-white">
								<CheckCircle2 className="h-3 w-3" aria-hidden="true" />
								<span>{current.screenSubTitle}</span>
							</p>
						</div>

						<div className="space-y-2 rounded-2xl bg-white p-3.5 text-xs shadow-2xs">
							<div className="flex items-center justify-between">
								<span className="text-relo-muted">약속 금액</span>
								<span className="font-bold text-relo-ink tabular-nums">
									$184.00
								</span>
							</div>
							<div className="flex items-center justify-between">
								<span className="text-relo-muted">실제 카드 취소</span>
								<span className="font-extrabold text-relo-brand tabular-nums">
									$184.00
								</span>
							</div>
							<div className="h-2 overflow-hidden rounded-full bg-slate-100">
								<div className="h-full w-full rounded-full bg-relo-brand" />
							</div>
						</div>
					</div>

					<div className="rounded-2xl bg-[#191f28] py-2.5 text-center text-xs font-bold text-white">
						✓ {current.screenStatus}
					</div>
				</motion.div>
			) : null}
		</AnimatePresence>
	);
}
