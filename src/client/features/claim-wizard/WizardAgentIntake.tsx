/**
 * @module client/features/claim-wizard/WizardAgentIntake
 * @layer View (Step 1: the AI fills the request, the person checks it)
 * @purpose The person uploads their order confirmation and says what happened in one line. The
 *          AI reads the document, works out which kind of request it is, which item and how
 *          many, and hands back what the wizard needs to fill the form. Nothing is sent until
 *          the person has agreed; without the AI the file is only opened here.
 */

import { FileScan, Sparkles } from "lucide-react";
import { type ChangeEvent, useId, useState } from "react";
import { useAiConsentGate } from "@/client/components/AiConsentDialog";
import { PdfPreviewCanvas } from "@/client/components/media/PdfPreviewCanvas";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Badge, Button, useToast } from "@/client/components/ui/Primitives";
import type { WizardIntakeResult } from "@/client/features/claim-wizard/intake-fill";
import {
	useAiExtractNewDocMutation,
	useAiIntakeMutation,
} from "@/client/hooks/useClaims";
import { useAppConfig } from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { errorText } from "@/client/lib/claim-words";
import { useCalmPreparation } from "@/client/lib/preparation";
import type { AiExtractionResponse } from "@/client/types";

/** A line shorter than this says too little to read a request from. */
const MIN_LINE = 5;

interface WizardAgentIntakeProps {
	/** Fills the form with the result and answers with the step the wizard now shows. */
	onFilled: (result: WizardIntakeResult) => Promise<number>;
	/**
	 * The AI has filled the form. Kept by the wizard, not here: this card is taken off the
	 * screen when the wizard moves on, and the mark must still be there when the person comes back.
	 */
	filledByAi: boolean;
	/** How the AI said it read the person's line, when it did. */
	understood: string | null;
	/** What the person wrote before, when they come back to this step. */
	initialLine: string;
}

export function WizardAgentIntake({
	onFilled,
	filledByAi,
	understood,
	initialLine,
}: WizardAgentIntakeProps) {
	const fileInputId = useId();
	const lineId = useId();
	const { data: config } = useAppConfig();
	const { ensureConsent, consentDialog } = useAiConsentGate();
	const extractMutation = useAiExtractNewDocMutation();
	const intakeMutation = useAiIntakeMutation();
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();
	const { t, locale } = useI18n();
	const sc = t.wizard.intake;

	const [line, setLine] = useState(initialLine);
	// A chosen file that has not been read yet. Once read it belongs to the request.
	const [file, setFile] = useState<File | null>(null);
	const [shownPdf, setShownPdf] = useState<File | null>(null);
	// The last reading is kept, so the line can be read again against the same order.
	const [reading, setReading] = useState<AiExtractionResponse | null>(null);

	const aiEnabled = Boolean(config?.ai.enabled);

	const handleChooseFile = (event: ChangeEvent<HTMLInputElement>) => {
		const chosen = event.target.files?.[0];
		event.target.value = "";
		if (!chosen) return;
		setFile(chosen);
		setShownPdf(chosen.type === "application/pdf" ? chosen : null);
		if (!aiEnabled) showToast(sc.toastPreviewOnly);
	};

	const handleRun = async () => {
		const text = line.trim();
		const hasLine = text.length >= MIN_LINE;
		if (!file && !hasLine) {
			showToast(sc.needInput, "error");
			return;
		}
		// The file and the line stay on this device until the person has agreed to send them.
		if (!(await ensureConsent())) {
			showToast(sc.toastPreviewOnly);
			return;
		}

		try {
			const result = await runCalmly(async () => {
				const extraction = file
					? await extractMutation.mutateAsync({ file, fileName: file.name })
					: null;
				const items = (extraction ?? reading)?.suggestion.items ?? [];
				// The order can still be filled in when the line could not be read.
				const intake = hasLine
					? await intakeMutation
							.mutateAsync({
								text,
								items: items.map(({ name, orderedQty }) => ({
									name,
									orderedQty,
								})),
								locale,
							})
							.catch(() => null)
					: null;
				return { extraction, intake };
			});
			if (!result) return;

			if (result.extraction) setReading(result.extraction);
			const step = await onFilled({
				// Read again against the earlier order, the form keeps that order's details.
				extraction: result.extraction ?? (result.intake ? reading : null),
				file,
				text,
				intake: result.intake,
			});
			setFile(null);
			// Only the review step means nothing is left to fill in.
			showToast(step === 5 ? sc.toastFilled : sc.toastPartly);
		} catch (error) {
			showToast(errorText(error, sc.toastFail, locale), "error");
		}
	};

	return (
		<div className="space-y-3 rounded-2xl border border-relo-brand-line bg-relo-brand-soft/45 p-4">
			{consentDialog}

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
				{aiEnabled ? (
					<p className="text-xs font-semibold text-relo-ink">{sc.body}</p>
				) : null}
			</div>

			{isPreparing ? (
				<div className="py-2">
					<ReloOrbEmblem variant="processing" size="sm" speech={sc.reading} />
				</div>
			) : (
				<>
					{aiEnabled ? (
						<div className="space-y-1.5">
							<label
								htmlFor={lineId}
								className="block text-xs font-bold text-relo-muted"
							>
								{sc.lineLabel}
							</label>
							<textarea
								id={lineId}
								rows={2}
								value={line}
								onChange={(event) => setLine(event.target.value)}
								placeholder={sc.linePlaceholder}
								className="w-full rounded-xl border border-relo-line bg-white p-3 text-sm text-relo-ink focus:border-relo-brand"
							/>
						</div>
					) : null}

					<div className="flex flex-wrap items-center justify-between gap-2">
						<div className="flex min-w-0 flex-wrap items-center gap-x-2">
							<label
								htmlFor={fileInputId}
								className="inline-flex min-h-11 cursor-pointer items-center gap-1.5 rounded-xl border border-relo-brand-line bg-white px-3.5 py-2 text-xs font-bold whitespace-nowrap text-relo-brand transition hover:bg-relo-brand-soft"
							>
								<FileScan className="h-4 w-4" aria-hidden="true" />
								<span>{file ? sc.fileChange : sc.fileButton}</span>
							</label>
							<input
								id={fileInputId}
								type="file"
								accept=".pdf,.png,.jpg,.jpeg,.webp,application/pdf,image/png,image/jpeg,image/webp"
								onChange={handleChooseFile}
								className="sr-only"
							/>
							{file ? (
								<span
									className="max-w-full truncate text-xs text-relo-muted"
									data-testid="intake-file"
								>
									{file.name}
								</span>
							) : null}
						</div>
						{aiEnabled ? (
							<Button variant="secondary" size="md" onClick={handleRun}>
								{sc.run}
							</Button>
						) : null}
					</div>
				</>
			)}

			{/* What the AI filled in stays marked as the AI's after the toast is gone. */}
			{filledByAi && !isPreparing ? (
				<p className="text-xs text-relo-muted" data-testid="intake-note">
					{understood ? `${sc.understood} ${understood} ` : ""}
					{sc.aiNote}
				</p>
			) : null}

			{shownPdf ? (
				<PdfPreviewCanvas source={shownPdf} fileName={shownPdf.name} compact />
			) : null}
		</div>
	);
}
