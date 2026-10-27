/**
 * @module client/features/landing/TossPhoneScenes
 * @layer View (Sticky 3D Scroll-Triggered Smartphone Storytelling)
 * @purpose Pins a realistic vertical smartphone frame in 3D perspective space while scrolling,
 *          transitioning across 3 consumer scenes with 3D cards popping out of the screen.
 */

import { CreditCard, FileText, Languages, ShieldCheck } from "lucide-react";
import {
	AnimatePresence,
	motion,
	useMotionValueEvent,
	useScroll,
	useTransform,
} from "motion/react";
import { useRef, useState } from "react";
import { PhoneHardwareFrame } from "@/client/features/landing/PhoneHardwareFrame";
import { PhoneStoryScreens } from "@/client/features/landing/PhoneStoryScreens";
import { useI18n } from "@/client/i18n";
import { cn } from "@/lib/utils";

export function TossPhoneScenes() {
	const { t } = useI18n();
	const stageRef = useRef<HTMLElement | null>(null);
	const [activeScene, setActiveScene] = useState(0);

	const { scrollYProgress } = useScroll({
		target: stageRef,
		offset: ["start start", "end end"],
	});

	const phoneRotateY = useTransform(scrollYProgress, [0, 0.5, 1], [-11, 0, 10]);
	const phoneRotateX = useTransform(scrollYProgress, [0, 0.5, 1], [7, 1, -4]);
	const phoneScale = useTransform(
		scrollYProgress,
		[0, 0.5, 1],
		[0.97, 1.02, 0.99],
	);
	const popLeftY = useTransform(scrollYProgress, [0, 0.5, 1], [18, -10, -24]);
	const popRightY = useTransform(scrollYProgress, [0, 0.5, 1], [-14, 8, -18]);
	const progressHeight = useTransform(scrollYProgress, [0, 1], ["18%", "100%"]);

	useMotionValueEvent(scrollYProgress, "change", (latest) => {
		if (latest < 0.34) {
			if (activeScene !== 0) setActiveScene(0);
		} else if (latest < 0.68) {
			if (activeScene !== 1) setActiveScene(1);
		} else if (activeScene !== 2) {
			setActiveScene(2);
		}
	});

	const handleSelectScene = (index: number) => {
		setActiveScene(index);
		const el = stageRef.current;
		if (!el || window.innerWidth < 1024) return;
		const rect = el.getBoundingClientRect();
		const scrollTop = window.scrollY + rect.top;
		const scrollable = Math.max(0, el.offsetHeight - window.innerHeight);
		const targetProgress = index === 0 ? 0.1 : index === 1 ? 0.5 : 0.88;
		window.scrollTo({
			top: scrollTop + scrollable * targetProgress,
			behavior: "smooth",
		});
	};

	const scenes = t.phoneStory.scenes;
	const current = scenes[activeScene] ?? scenes[0];

	return (
		<section
			ref={stageRef}
			data-testid="phone-story-stage"
			className="relative border-b border-relo-line/70 bg-linear-to-b from-[#f9fafb] via-white to-[#f2f6fc] lg:min-h-[290vh]"
		>
			<div className="mx-auto max-w-6xl px-4 py-20 sm:px-6 lg:sticky lg:top-15 lg:flex lg:min-h-[calc(100vh-3.75rem)] lg:flex-col lg:justify-center lg:py-10">
				<div className="mb-10 flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center">
					<div>
						<p className="text-sm font-bold text-relo-brand">
							{t.phoneStory.eyebrow}
						</p>
						<p className="mt-1 text-xs font-medium text-relo-muted">
							{t.phoneStory.scrollHint}
						</p>
					</div>

					<div
						role="tablist"
						aria-label={t.phoneStory.headline}
						className="inline-flex flex-wrap gap-1.5 rounded-2xl bg-[#eef2f6] p-1.5"
					>
						{scenes.map((scene, idx) => {
							const active = idx === activeScene;
							return (
								<button
									key={scene.step}
									type="button"
									role="tab"
									aria-selected={active}
									data-testid={`phone-scene-tab-${idx}`}
									onClick={() => handleSelectScene(idx)}
									className={cn(
										"cursor-pointer rounded-xl px-3.5 py-2 text-xs font-bold transition-all sm:text-[13px]",
										active
											? "bg-white text-relo-ink shadow-xs"
											: "text-relo-muted hover:text-relo-ink",
									)}
								>
									<span className="mr-1.5 text-relo-brand">{scene.step}</span>
									<span>{scene.tab}</span>
								</button>
							);
						})}
					</div>
				</div>

				<div className="grid items-center gap-12 lg:grid-cols-12 lg:gap-8">
					{/* Left Editorial Narrative + Scroll Progress Rail */}
					<div className="flex gap-5 lg:col-span-5">
						<div
							aria-hidden="true"
							className="hidden w-1.5 shrink-0 overflow-hidden rounded-full bg-slate-200 lg:block"
						>
							<motion.div
								style={{ height: progressHeight }}
								className="w-full rounded-full bg-relo-brand"
							/>
						</div>

						<AnimatePresence mode="wait">
							{current ? (
								<motion.div
									key={current.step}
									initial={{ opacity: 0, y: 18 }}
									animate={{ opacity: 1, y: 0 }}
									exit={{ opacity: 0, y: -14 }}
									transition={{ duration: 0.28, ease: [0.22, 0.61, 0.36, 1] }}
									className="space-y-5"
								>
									<span className="inline-flex items-center gap-2 rounded-full bg-relo-brand-soft px-3.5 py-1.5 text-xs font-bold text-relo-brand">
										<span>STEP {current.step}</span>
										<span aria-hidden="true">·</span>
										<span>{current.badge}</span>
									</span>

									<h2 className="text-[28px] leading-[1.24] font-extrabold tracking-[-0.035em] text-relo-ink sm:text-[38px]">
										{current.titleLine1}
										<br />
										<span className="text-relo-brand">
											{current.titleLine2}
										</span>
									</h2>

									<p className="text-[16px] leading-[1.7] text-relo-body">
										{current.description}
									</p>
								</motion.div>
							) : null}
						</AnimatePresence>
					</div>

					{/* Right 3D Perspective Smartphone + Pop-Out Floating Objects */}
					<div
						className="relative flex items-center justify-center py-4 lg:col-span-7"
						style={{ perspective: "1300px" }}
					>
						<div
							aria-hidden="true"
							className="pointer-events-none absolute h-[420px] w-[420px] rounded-full bg-blue-500/12 blur-3xl"
						/>

						<motion.div
							style={{
								rotateY: phoneRotateY,
								rotateX: phoneRotateX,
								scale: phoneScale,
								transformStyle: "preserve-3d",
							}}
							className="relative flex items-center justify-center"
						>
							<PhoneHardwareFrame>
								<PhoneStoryScreens
									activeScene={activeScene}
									current={current}
								/>
							</PhoneHardwareFrame>

							{/* 3D POP-OUT CARD LEFT */}
							<AnimatePresence mode="wait">
								{current ? (
									<motion.div
										key={`pop-left-${current.step}`}
										style={{ y: popLeftY, translateZ: 78 }}
										initial={{ opacity: 0, scale: 0.78, x: 30 }}
										animate={{ opacity: 1, scale: 1, x: 0 }}
										exit={{ opacity: 0, scale: 0.84, x: 20 }}
										transition={{
											type: "spring",
											stiffness: 290,
											damping: 24,
										}}
										className="pointer-events-none absolute top-14 -left-3 z-30 hidden max-w-[215px] rounded-2xl border border-relo-brand-line bg-white p-3.5 shadow-[0_22px_45px_-12px_rgba(27,100,218,0.28)] sm:block sm:-left-28"
									>
										<div className="flex items-start gap-2.5">
											<span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-relo-brand text-white">
												{activeScene === 0 ? (
													<FileText className="h-4 w-4" aria-hidden="true" />
												) : activeScene === 1 ? (
													<Languages className="h-4 w-4" aria-hidden="true" />
												) : (
													<CreditCard className="h-4 w-4" aria-hidden="true" />
												)}
											</span>
											<div>
												<p className="text-xs font-extrabold text-relo-ink">
													{current.popLeftTitle}
												</p>
												<p className="mt-0.5 text-[11px] font-semibold text-relo-brand tabular-nums">
													{current.popLeftSub}
												</p>
											</div>
										</div>
									</motion.div>
								) : null}
							</AnimatePresence>

							{/* 3D POP-OUT CARD RIGHT */}
							<AnimatePresence mode="wait">
								{current ? (
									<motion.div
										key={`pop-right-${current.step}`}
										style={{ y: popRightY, translateZ: 96 }}
										initial={{ opacity: 0, scale: 0.78, x: -30 }}
										animate={{ opacity: 1, scale: 1, x: 0 }}
										exit={{ opacity: 0, scale: 0.84, x: -20 }}
										transition={{
											type: "spring",
											stiffness: 280,
											damping: 23,
											delay: 0.06,
										}}
										className="pointer-events-none absolute -right-3 bottom-16 z-30 hidden max-w-[220px] rounded-2xl border border-slate-900/10 bg-[#191f28] p-3.5 text-white shadow-[0_24px_50px_-12px_rgba(15,23,42,0.42)] sm:block sm:-right-28"
									>
										<div className="flex items-start gap-2.5">
											<span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-xl bg-sky-500/20 text-sky-300">
												<ShieldCheck className="h-4 w-4" aria-hidden="true" />
											</span>
											<div>
												<p className="text-xs font-bold text-white">
													{current.popRightTitle}
												</p>
												<p className="mt-0.5 text-[11px] font-medium text-sky-200">
													{current.popRightSub}
												</p>
											</div>
										</div>
									</motion.div>
								) : null}
							</AnimatePresence>
						</motion.div>
					</div>
				</div>
			</div>
		</section>
	);
}
