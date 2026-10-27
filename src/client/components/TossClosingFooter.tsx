/**
 * @module client/components/TossClosingFooter
 * @layer View (Global Atmospheric Sitemap Footer)
 * @purpose Toss-inspired twilight slate-navy closing footer featuring orbital horizon arcs,
 *          a 2-line closing statement, a 4-column structured directory, 4-language switcher,
 *          and bold privacy/consumer protection policies across desktop and mobile.
 */

import { ShieldCheck } from "lucide-react";
import { LanguageSwitcher, useI18n } from "@/client/i18n";
import { AppLink } from "@/client/lib/router";

export function TossClosingFooter() {
	const { t } = useI18n();

	return (
		<footer
			data-testid="relo-global-footer"
			className="relative overflow-hidden bg-linear-to-b from-[#2c3a57] via-[#3c4962] to-[#323e52] text-slate-200"
		>
			{/* Subtle orbital latitude arcs echoing Toss reference horizon */}
			<svg
				aria-hidden="true"
				viewBox="0 0 1440 360"
				preserveAspectRatio="none"
				className="pointer-events-none absolute inset-x-0 top-0 h-64 w-full opacity-35"
			>
				<ellipse
					cx="720"
					cy="-40"
					rx="760"
					ry="230"
					fill="none"
					stroke="rgba(191,219,254,0.28)"
					strokeWidth="1.2"
				/>
				<ellipse
					cx="720"
					cy="-40"
					rx="560"
					ry="170"
					fill="none"
					stroke="rgba(191,219,254,0.2)"
					strokeWidth="1.1"
				/>
				<ellipse
					cx="720"
					cy="-40"
					rx="360"
					ry="110"
					fill="none"
					stroke="rgba(191,219,254,0.16)"
					strokeWidth="1"
				/>
				<line
					x1="720"
					y1="0"
					x2="720"
					y2="240"
					stroke="rgba(191,219,254,0.14)"
					strokeWidth="1"
				/>
			</svg>

			<div className="relative mx-auto max-w-6xl px-5 pt-16 pb-28 sm:px-6 md:pt-20 md:pb-16">
				{/* Top Closing Statement + Quick Language & Safety Strip */}
				<div className="flex flex-col justify-between gap-8 border-b border-white/12 pb-12 lg:flex-row lg:items-end">
					<div>
						<p className="text-2xl leading-[1.32] font-extrabold tracking-[-0.03em] text-white sm:text-[32px]">
							{t.footer.sloganLine1}
							<br />
							<span className="text-sky-200">{t.footer.sloganLine2}</span>
						</p>
					</div>

					<div className="space-y-2.5">
						<p className="text-xs font-bold tracking-wide text-slate-300">
							{t.footer.colLanguage}
						</p>
						<LanguageSwitcher variant="footer" />
					</div>
				</div>

				{/* 5-Column Structured Directory Grid */}
				<div className="grid grid-cols-2 gap-x-6 gap-y-9 py-12 sm:grid-cols-3 lg:grid-cols-5">
					{/* Column 1: Service */}
					<div className="space-y-3.5">
						<h2 className="text-[13px] font-bold text-white">
							{t.footer.colService}
						</h2>
						<ul className="space-y-2.5 text-[13px] text-slate-300/90">
							{t.footer.serviceLinks.map((item) => (
								<li key={item.label}>
									<AppLink
										to={item.to}
										className="transition-colors hover:text-white hover:underline"
									>
										{item.label}
									</AppLink>
								</li>
							))}
						</ul>
					</div>

					{/* Column 2: Supported Overseas Stores */}
					<div className="space-y-3.5">
						<h2 className="text-[13px] font-bold text-white">
							{t.footer.colMalls}
						</h2>
						<ul className="space-y-2.5 text-[13px] text-slate-300/90">
							{t.footer.mallLinks.map((mall) => (
								<li key={mall}>
									<AppLink
										to="/wizard"
										className="transition-colors hover:text-white hover:underline"
									>
										{mall}
									</AppLink>
								</li>
							))}
						</ul>
					</div>

					{/* Column 3: Customer Guide */}
					<div className="space-y-3.5">
						<h2 className="text-[13px] font-bold text-white">
							{t.footer.colSupport}
						</h2>
						<ul className="space-y-2.5 text-[13px] text-slate-300/90">
							{t.footer.supportLinks.map((item) => (
								<li key={item.label}>
									<AppLink
										to={item.to}
										className="transition-colors hover:text-white hover:underline"
									>
										{item.label}
									</AppLink>
								</li>
							))}
						</ul>
					</div>

					{/* Column 4: Account Management */}
					<div className="space-y-3.5">
						<h2 className="text-[13px] font-bold text-white">
							{t.footer.colAccount}
						</h2>
						<ul className="space-y-2.5 text-[13px] text-slate-300/90">
							{t.footer.accountLinks.map((item) => (
								<li key={item.label}>
									<AppLink
										to={item.to}
										className="transition-colors hover:text-white hover:underline"
									>
										{item.label}
									</AppLink>
								</li>
							))}
						</ul>
					</div>

					{/* Column 5: Consumer Protection Principles */}
					<div className="col-span-2 space-y-3.5 sm:col-span-1">
						<h2 className="text-[13px] font-bold text-white">
							{t.footer.colSafety}
						</h2>
						<ul className="space-y-2.5 text-[13px] text-slate-200">
							{t.footer.safetyItems.map((rule) => (
								<li key={rule} className="flex items-start gap-2">
									<ShieldCheck
										className="mt-0.5 h-4 w-4 shrink-0 text-sky-300"
										aria-hidden="true"
									/>
									<span>{rule}</span>
								</li>
							))}
						</ul>
					</div>
				</div>

				{/* Bottom Company Metadata & Legal Policy Row */}
				<div className="space-y-5 border-t border-white/12 pt-8 text-xs leading-relaxed text-slate-300/85">
					<div className="space-y-1.5">
						<p className="text-sm font-extrabold tracking-tight text-white">
							ReLo
						</p>
						<p>{t.footer.companyInfoLine1}</p>
						<p>{t.footer.companyInfoLine2}</p>
					</div>

					<div className="flex flex-wrap items-center gap-x-5 gap-y-2 pt-1 text-xs">
						<AppLink
							to="/settings"
							className="font-bold text-white hover:underline"
						>
							{t.footer.privacyBold}
						</AppLink>
						<AppLink
							to="/settings"
							className="text-slate-300 transition-colors hover:text-white hover:underline"
						>
							{t.footer.terms}
						</AppLink>
						<AppLink
							to="/settings"
							className="text-slate-300 transition-colors hover:text-white hover:underline"
						>
							{t.footer.dataSafety}
						</AppLink>
						<AppLink
							to="/claims"
							className="text-slate-300 transition-colors hover:text-white hover:underline"
						>
							{t.footer.consumerGuide}
						</AppLink>
						<AppLink
							to="/#why-relo"
							className="text-slate-300 transition-colors hover:text-white hover:underline"
						>
							{t.footer.disputeNotice}
						</AppLink>
					</div>
				</div>
			</div>
		</footer>
	);
}
