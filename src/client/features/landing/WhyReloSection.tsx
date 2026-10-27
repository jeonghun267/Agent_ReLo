/**
 * @module client/features/landing/WhyReloSection
 * @layer View (Plain-Language Value Comparison Matrix)
 * @purpose Explains in everyday consumer language how ReLo helps after home unboxing,
 *          where forwarding warehouses and plain translators stop.
 */

import { Check, Minus } from "lucide-react";
import { useI18n } from "@/client/i18n";

export function WhyReloSection() {
	const { t } = useI18n();

	return (
		<section id="why-relo" className="bg-white py-24 sm:py-32">
			<div className="mx-auto max-w-6xl px-4 sm:px-6">
				<div className="max-w-2xl space-y-4">
					<p className="text-[15px] font-bold text-relo-brand">
						{t.whyRelo.eyebrow}
					</p>
					<h2 className="text-3xl leading-[1.22] font-bold tracking-[-0.035em] text-relo-ink sm:text-[42px]">
						{t.whyRelo.titleLine1}
						<br />
						{t.whyRelo.titleLine2}
					</h2>
					<p className="text-[17px] leading-[1.65] text-relo-muted">
						{t.whyRelo.description}
					</p>
				</div>

				<div className="mt-12 overflow-hidden rounded-[28px] border border-relo-line bg-relo-canvas">
					<div className="hidden grid-cols-12 border-b border-relo-line bg-white px-7 py-5 text-xs font-semibold text-relo-muted md:grid">
						<div className="col-span-4">{t.whyRelo.colTopic}</div>
						<div className="col-span-2">{t.whyRelo.colAgent}</div>
						<div className="col-span-3">{t.whyRelo.colTranslator}</div>
						<div className="col-span-3 font-bold text-relo-brand">
							{t.whyRelo.colRelo}
						</div>
					</div>

					<div className="divide-y divide-relo-line">
						{t.whyRelo.rows.map((row) => (
							<div
								key={row.topic}
								className="grid gap-3 px-6 py-5 sm:px-7 md:grid-cols-12 md:items-center md:gap-4"
							>
								<div className="text-[15px] font-bold text-relo-ink md:col-span-4">
									{row.topic}
								</div>

								<div className="flex items-center gap-2 text-xs text-relo-muted md:col-span-2 md:text-sm">
									<Minus
										className="h-3.5 w-3.5 shrink-0 text-relo-subtle"
										aria-hidden="true"
									/>
									<span>
										<strong className="mr-1 font-medium md:hidden">
											{t.whyRelo.colAgent}:
										</strong>
										{row.agent}
									</span>
								</div>

								<div className="flex items-center gap-2 text-xs text-relo-muted md:col-span-3 md:text-sm">
									<Minus
										className="h-3.5 w-3.5 shrink-0 text-relo-subtle"
										aria-hidden="true"
									/>
									<span>
										<strong className="mr-1 font-medium md:hidden">
											{t.whyRelo.colTranslator}:
										</strong>
										{row.translator}
									</span>
								</div>

								<div className="flex items-center gap-2 rounded-xl bg-relo-brand-soft/80 px-3 py-2 text-sm font-bold text-relo-brand md:col-span-3 md:bg-transparent md:p-0">
									<span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-relo-brand text-white">
										<Check className="h-3 w-3" aria-hidden="true" />
									</span>
									<span>{row.relo}</span>
								</div>
							</div>
						))}
					</div>
				</div>
			</div>
		</section>
	);
}
