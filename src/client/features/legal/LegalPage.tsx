/**
 * @module client/features/legal/LegalPage
 * @layer View (Privacy Policy & Terms of Service)
 * @purpose Shows one of the two documents the footer links to, as plain readable text.
 *          Open to everyone, signed in or not. The text is Korean; other languages get one
 *          line saying so.
 */

import { Card } from "@/client/components/ui/Primitives";
import {
	type LegalDocument,
	privacyPolicy,
	termsOfService,
} from "@/client/features/legal/legal-text";
import { useI18n } from "@/client/i18n";
import { AppLink } from "@/client/lib/router";

const DOCUMENTS: Record<"privacy" | "terms", LegalDocument> = {
	privacy: privacyPolicy,
	terms: termsOfService,
};

export function LegalPage({ doc }: { doc: "privacy" | "terms" }) {
	const { t, locale } = useI18n();
	const lg = t.settings.legal;
	const document = DOCUMENTS[doc];
	const other = doc === "privacy" ? "terms" : "privacy";

	return (
		<div className="mx-auto max-w-2xl space-y-5 px-4 pt-6 sm:px-6 sm:pt-8">
			<div className="space-y-1">
				<h1 className="text-2xl font-extrabold tracking-tight text-relo-ink">
					{document.title}
				</h1>
				<p className="text-xs text-relo-muted">{document.effective}</p>
				{locale !== "ko" ? (
					<p className="text-xs text-relo-muted">{lg.koreanOnly}</p>
				) : null}
			</div>

			<Card className="space-y-6">
				<p className="text-sm leading-relaxed text-relo-body">
					{document.intro}
				</p>
				{document.sections.map((section) => (
					<section key={section.heading} className="space-y-2">
						<h2 className="text-sm font-bold text-relo-ink">
							{section.heading}
						</h2>
						<ul className="list-disc space-y-1.5 pl-5 text-sm leading-relaxed text-relo-body">
							{section.lines.map((line) => (
								<li key={line}>{line}</li>
							))}
						</ul>
					</section>
				))}
			</Card>

			<AppLink
				to={`/${other}`}
				className="inline-block text-sm font-semibold text-relo-brand hover:underline"
			>
				{other === "terms" ? lg.seeTerms : lg.seePrivacy}
			</AppLink>
		</div>
	);
}
