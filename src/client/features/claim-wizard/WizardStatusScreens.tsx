/**
 * @module client/features/claim-wizard/WizardStatusScreens
 * @layer View (Wizard Gate & Completion Screens)
 * @purpose Renders the guest sign-in gate before starting a private refund request
 *          and the celebratory confirmation screen once a request is saved.
 */

import { CheckCircle2, LogIn, Sparkles } from "lucide-react";
import { InteractiveAuroraCanvas } from "@/client/components/effects/InteractiveAuroraCanvas";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Badge, Button, Card } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { nextStepText } from "@/client/lib/claim-words";
import { fill } from "@/client/lib/format";
import type { ClaimView } from "@/client/types";

interface WizardGuestGateProps {
	demoAccountName?: string;
	isLoggingIn: boolean;
	onDemoLogin: () => void;
	onNavigateAuth: () => void;
}

export function WizardGuestGate({
	demoAccountName,
	isLoggingIn,
	onDemoLogin,
	onNavigateAuth,
}: WizardGuestGateProps) {
	const { t } = useI18n();
	const w = t.wizard;
	return (
		<InteractiveAuroraCanvas className="py-12">
			<div className="mx-auto max-w-lg px-4">
				<Card className="space-y-5 p-6 text-center sm:p-8">
					<Badge tone="brand">{w.guestEyebrow}</Badge>
					<ReloOrbEmblem variant="default" size="md" speech={w.guestSpeech} />
					<div className="space-y-2.5 pt-2">
						{demoAccountName ? (
							<Button
								variant="primary"
								size="lg"
								fullWidth
								isLoading={isLoggingIn}
								onClick={onDemoLogin}
							>
								<Sparkles className="h-5 w-5" aria-hidden="true" />
								<span>{fill(w.demoStart, { name: demoAccountName })}</span>
							</Button>
						) : null}
						<Button
							variant="secondary"
							size="lg"
							fullWidth
							onClick={onNavigateAuth}
						>
							<LogIn className="h-4 w-4" aria-hidden="true" />
							<span>{w.emailStart}</span>
						</Button>
					</div>
				</Card>
			</div>
		</InteractiveAuroraCanvas>
	);
}

interface WizardSuccessScreenProps {
	claim: ClaimView;
	onOpenDetail: () => void;
	onOpenList: () => void;
}

export function WizardSuccessScreen({
	claim,
	onOpenDetail,
	onOpenList,
}: WizardSuccessScreenProps) {
	const { t } = useI18n();
	const w = t.wizard;
	return (
		<InteractiveAuroraCanvas className="py-10">
			<div className="mx-auto max-w-xl px-4">
				<Card className="space-y-6 p-6 text-center sm:p-8">
					<Badge tone="brand">
						<CheckCircle2 className="h-3.5 w-3.5" aria-hidden="true" />
						<span>
							{claim.files.length > 0
								? fill(w.doneWithFiles, { n: claim.files.length })
								: w.doneEyebrow}
						</span>
					</Badge>
					<ReloOrbEmblem variant="verified" size="lg" speech={w.doneSpeech} />
					<div className="space-y-1.5 rounded-2xl bg-relo-sunken p-4 text-left text-xs">
						<p className="text-sm font-extrabold text-relo-ink">
							{claim.vendor} · {claim.title}
						</p>
						<p className="text-relo-muted">
							{t.shared.orderNo} {claim.orderRef} · {t.shared.nextStepLabel}:{" "}
							<strong className="text-relo-brand">
								{nextStepText(t, claim)}
							</strong>
						</p>
					</div>
					<div className="flex flex-col gap-2.5 sm:flex-row">
						<Button
							variant="primary"
							size="lg"
							fullWidth
							onClick={onOpenDetail}
						>
							<Sparkles className="h-5 w-5" aria-hidden="true" />
							<span>{w.goMessage}</span>
						</Button>
						<Button
							variant="secondary"
							size="lg"
							onClick={onOpenList}
							className="whitespace-nowrap"
						>
							{t.nav.myRefunds}
						</Button>
					</div>
				</Card>
			</div>
		</InteractiveAuroraCanvas>
	);
}
