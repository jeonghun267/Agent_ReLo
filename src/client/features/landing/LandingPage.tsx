/**
 * @module client/features/landing/LandingPage
 * @layer View (B2C Consumer Homepage Composition)
 * @purpose Composes the Toss-inspired editorial hero, store marquee, real-continent 3D
 *          flight globe, sticky 3D smartphone storytelling, plain-language differentiator
 *          table, 5-step interactive map, and refund calculator across 4 languages.
 */

import { ArrowDown, ArrowRight, CheckCircle2 } from "lucide-react";
import { motion } from "motion/react";
import { InteractiveAuroraCanvas } from "@/client/components/effects/InteractiveAuroraCanvas";
import {
	type GlobalMallPreset,
	MagneticWrap,
	MallMarquee,
} from "@/client/components/effects/InteractivePrimitives";
import { Button } from "@/client/components/ui/Primitives";
import {
	type FlightCorridor,
	GlobalRefundGlobe,
} from "@/client/features/landing/GlobalRefundGlobe";
import { LandingFlowPlayground } from "@/client/features/landing/LandingFlowPlayground";
import { RefundSimulatorSection } from "@/client/features/landing/RefundSimulatorSection";
import { TossPhoneScenes } from "@/client/features/landing/TossPhoneScenes";
import { WhyReloSection } from "@/client/features/landing/WhyReloSection";
import { useSession } from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { useRouter } from "@/client/lib/router";
import type { ClaimKind, CurrencyCode } from "@/client/types";

export function LandingPage() {
	const { navigate } = useRouter();
	const { t } = useI18n();
	const { data: session } = useSession();

	const launchWizardWithParams = (params?: {
		vendor?: string;
		currency?: CurrencyCode;
		amount?: string;
		kind?: ClaimKind;
		issue?: string;
	}) => {
		if (!params) {
			navigate("/wizard");
			return;
		}
		const qs = new URLSearchParams();
		if (params.vendor) qs.set("vendor", params.vendor);
		if (params.currency) qs.set("currency", params.currency);
		if (params.amount) qs.set("amount", params.amount);
		if (params.kind) qs.set("kind", params.kind);
		if (params.issue) qs.set("issue", params.issue);
		navigate(`/wizard?${qs.toString()}`);
	};

	const handleSelectMall = (mall: GlobalMallPreset) => {
		launchWizardWithParams({
			vendor: mall.name,
			currency: mall.currency,
		});
	};

	const handleSelectCorridor = (corridor: FlightCorridor) => {
		launchWizardWithParams({
			vendor: corridor.vendor,
			currency: corridor.currency,
			amount: corridor.amount,
			kind: corridor.kind,
			issue: corridor.issue,
		});
	};

	return (
		<div className="bg-white">
			{/* 1. Toss-Style Clean Editorial Hero */}
			<InteractiveAuroraCanvas className="bg-white pt-14 pb-12 sm:pt-24 sm:pb-16">
				<section className="mx-auto max-w-4xl px-4 text-center sm:px-6">
					<motion.div
						initial={{ opacity: 0, y: 18 }}
						animate={{ opacity: 1, y: 0 }}
						transition={{ duration: 0.45, ease: [0.22, 0.61, 0.36, 1] }}
						className="space-y-6"
					>
						<p className="inline-flex items-center gap-2 rounded-full bg-relo-sunken px-4 py-1.5 text-xs font-semibold text-relo-body sm:text-sm">
							<span
								aria-hidden="true"
								className="h-2 w-2 rounded-full bg-relo-brand"
							/>
							<span>{t.hero.badge}</span>
						</p>

						<h1 className="text-[34px] leading-[1.18] font-bold tracking-[-0.04em] text-relo-ink sm:text-[56px]">
							{t.hero.titleLine1}
							<br />
							<span className="text-relo-brand">{t.hero.titleHighlight}</span>
						</h1>

						<p className="mx-auto max-w-2xl text-[16px] leading-[1.68] text-relo-muted sm:text-[18px]">
							{t.hero.subtitle}
						</p>

						<div className="flex flex-col items-center justify-center gap-3 pt-2 sm:flex-row">
							<MagneticWrap>
								<Button
									variant="primary"
									size="lg"
									onClick={() => launchWizardWithParams()}
									className="w-full rounded-full px-8 text-[16px] shadow-[0_14px_30px_rgba(27,100,218,0.26)] sm:w-auto"
								>
									<span>{t.hero.primaryCta}</span>
									<ArrowRight className="h-4.5 w-4.5" aria-hidden="true" />
								</Button>
							</MagneticWrap>

							{session?.user ? (
								<Button
									variant="secondary"
									size="lg"
									onClick={() => navigate("/claims")}
									className="w-full rounded-full px-7 text-[15px] sm:w-auto"
								>
									<span>{t.hero.secondaryWallet}</span>
								</Button>
							) : (
								<a
									href="#global-network"
									className="inline-flex min-h-13.5 items-center justify-center gap-1.5 rounded-full bg-relo-sunken px-6 text-[15px] font-semibold text-relo-body transition hover:bg-[#e5e8eb]"
								>
									<span>{t.hero.secondaryGlobe}</span>
									<ArrowDown className="h-4 w-4" aria-hidden="true" />
								</a>
							)}
						</div>

						<div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 pt-4 text-xs font-medium text-relo-muted sm:text-sm">
							<span className="inline-flex items-center gap-1.5">
								<CheckCircle2
									className="h-4 w-4 text-relo-brand"
									aria-hidden="true"
								/>
								<span>{t.hero.trust1}</span>
							</span>
							<span className="inline-flex items-center gap-1.5">
								<CheckCircle2
									className="h-4 w-4 text-relo-brand"
									aria-hidden="true"
								/>
								<span>{t.hero.trust2}</span>
							</span>
							<span className="inline-flex items-center gap-1.5">
								<CheckCircle2
									className="h-4 w-4 text-relo-brand"
									aria-hidden="true"
								/>
								<span>{t.hero.trust3}</span>
							</span>
						</div>
					</motion.div>
				</section>

				<div className="mx-auto mt-14 max-w-6xl px-4 sm:px-6">
					<MallMarquee onSelectMall={handleSelectMall} />
				</div>
			</InteractiveAuroraCanvas>

			{/* 2. Real-Continent 3D Globe with Airplanes Flying into Seoul */}
			<div id="global-network">
				<GlobalRefundGlobe onSelectCorridor={handleSelectCorridor} />
			</div>

			{/* 3. Sticky 3D Scroll-Driven Smartphone Pop-Out Storytelling */}
			<TossPhoneScenes />

			{/* 4. Plain-Language Value Comparison Matrix */}
			<WhyReloSection />

			{/* 5. Interactive 5-Step Consumer Progress Map */}
			<LandingFlowPlayground onStartWizard={() => launchWizardWithParams()} />

			{/* 6. Expected Refund Calculator */}
			<RefundSimulatorSection onLaunchWithPreset={launchWizardWithParams} />

			{/* 7. Pre-Footer Action Band */}
			<section className="border-t border-relo-line bg-[#f2f6fc] py-20 text-center sm:py-24">
				<div className="mx-auto max-w-3xl space-y-5 px-4 sm:px-6">
					<h2 className="text-3xl leading-[1.24] font-bold tracking-[-0.035em] text-relo-ink sm:text-[40px]">
						{t.closingCta.titleLine1}
						<br />
						<span className="text-relo-brand">{t.closingCta.titleLine2}</span>
					</h2>
					<p className="text-[16px] text-relo-body sm:text-[18px]">
						{t.closingCta.subtitle}
					</p>
					<div className="pt-2">
						<Button
							variant="primary"
							size="lg"
							onClick={() => launchWizardWithParams()}
							className="rounded-full px-9 text-[16px] shadow-[0_12px_28px_rgba(27,100,218,0.22)]"
						>
							<span>{t.closingCta.button}</span>
							<ArrowRight className="h-4.5 w-4.5" aria-hidden="true" />
						</Button>
					</div>
				</div>
			</section>
		</div>
	);
}
