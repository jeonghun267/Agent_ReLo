/**
 * @module client/features/claim-wizard/WizardInvoiceScanCard
 * @layer View (Step 1 Order Receipt Auto-Reader)
 * @purpose Lets consumers upload an order confirmation PDF or screenshot to fill
 *          store name, order ID, date, and amount automatically.
 */

import { FileScan, Sparkles } from "lucide-react";
import { type ChangeEvent, useId, useState } from "react";
import { PdfPreviewCanvas } from "@/client/components/media/PdfPreviewCanvas";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Badge, Button, useToast } from "@/client/components/ui/Primitives";
import { useAiExtractNewDocMutation } from "@/client/hooks/useClaims";
import {
	useAiConsentMutation,
	useAppConfig,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { errorText } from "@/client/lib/claim-words";
import { useCalmPreparation } from "@/client/lib/preparation";
import type { AiExtractionResponse } from "@/client/types";

interface WizardInvoiceScanCardProps {
	onExtracted: (result: AiExtractionResponse, scannedFile: File) => void;
}

export function WizardInvoiceScanCard({
	onExtracted,
}: WizardInvoiceScanCardProps) {
	const fileInputId = useId();
	const { data: session } = useSession();
	const { data: config } = useAppConfig();
	const aiConsentMutation = useAiConsentMutation();
	const extractMutation = useAiExtractNewDocMutation();
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();
	const { t, locale } = useI18n();
	const sc = t.wizard.scan;

	const [scannedPdf, setScannedPdf] = useState<File | null>(null);

	const aiEnabled = Boolean(config?.ai.enabled);
	const hasConsent = Boolean(session?.user?.aiConsentAt);

	const handleScanFile = async (event: ChangeEvent<HTMLInputElement>) => {
		const file = event.target.files?.[0];
		event.target.value = "";
		if (!file) return;

		if (file.type === "application/pdf") {
			setScannedPdf(file);
		} else {
			setScannedPdf(null);
		}

		if (!aiEnabled) {
			showToast(sc.toastPreviewOnly);
			return;
		}

		try {
			if (!hasConsent) {
				await aiConsentMutation.mutateAsync(true);
			}
			const res = await runCalmly(() =>
				extractMutation.mutateAsync({ file, fileName: file.name }),
			);
			if (res) {
				onExtracted(res, file);
				showToast(sc.toastFilled);
			}
		} catch (error) {
			showToast(errorText(error, sc.toastFail, locale), "error");
		}
	};

	return (
		<div className="space-y-3 rounded-2xl border border-relo-brand-line bg-relo-brand-soft/45 p-4">
			{isPreparing ? (
				<div className="py-2">
					<ReloOrbEmblem variant="processing" size="sm" speech={sc.reading} />
				</div>
			) : (
				<div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
					<div className="space-y-1">
						<div className="flex items-center gap-1.5">
							<Badge tone="brand">
								<Sparkles className="h-3 w-3" aria-hidden="true" />
								<span>{sc.eyebrow}</span>
							</Badge>
							<span className="text-xs font-semibold text-relo-muted">
								{sc.optional}
							</span>
						</div>
						<p className="text-xs font-semibold text-relo-ink">{sc.body}</p>
					</div>

					<div>
						<label
							htmlFor={fileInputId}
							className="inline-flex min-h-11 cursor-pointer items-center gap-1.5 rounded-xl border border-relo-brand-line bg-white px-3.5 py-2 text-xs font-bold whitespace-nowrap text-relo-brand transition hover:bg-relo-brand-soft"
						>
							<FileScan className="h-4 w-4" aria-hidden="true" />
							<span>{sc.button}</span>
						</label>
						<input
							id={fileInputId}
							type="file"
							accept=".pdf,.png,.jpg,.jpeg,.webp,application/pdf,image/png,image/jpeg,image/webp"
							onChange={handleScanFile}
							className="sr-only"
						/>
					</div>
				</div>
			)}

			{!hasConsent && aiEnabled ? (
				<div className="flex items-center justify-between gap-2 rounded-xl bg-white/85 px-3 py-2 text-xs text-relo-muted">
					<span>{sc.consentNote}</span>
					<Button
						variant="ghost"
						size="sm"
						isLoading={aiConsentMutation.isPending}
						onClick={() => void aiConsentMutation.mutateAsync(true)}
					>
						{sc.consentButton}
					</Button>
				</div>
			) : null}

			{scannedPdf ? (
				<PdfPreviewCanvas
					source={scannedPdf}
					fileName={scannedPdf.name}
					compact
				/>
			) : null}
		</div>
	);
}
