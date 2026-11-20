/**
 * @module client/features/claim-detail/ForeignMessageStudio
 * @layer View (Foreign Support Message Writer & Submission Recorder)
 * @purpose Generates polite overseas customer-support refund requests from verified
 *          order facts and records when the consumer sends the message.
 */

import {
	AlertTriangle,
	Check,
	Copy,
	FileText,
	Send,
	Sparkles,
} from "lucide-react";
import { useId, useState } from "react";
import { useAiConsentGate } from "@/client/components/AiConsentDialog";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Badge,
	Button,
	Card,
	useToast,
} from "@/client/components/ui/Primitives";
import {
	useAiDraftMutation,
	useSaveDraftMutation,
	useSubmitDraftMutation,
} from "@/client/hooks/useClaims";
import { useAppConfig, useSession } from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { inquiryApi } from "@/client/lib/api-client";
import { errorText } from "@/client/lib/claim-words";
import { fill, formatLocalDate } from "@/client/lib/format";
import { useCalmPreparation } from "@/client/lib/preparation";
import type { ClaimView, DraftSuggestionResponse } from "@/client/types";

/**
 * `incoming` is a draft handed over from an agent run ("put it in the message box"). It only
 * fills the editor; like any AI draft it is saved when the person presses save.
 */
export function ForeignMessageStudio({
	claim,
	incoming = null,
}: {
	claim: ClaimView;
	incoming?: DraftSuggestionResponse | null;
}) {
	const editorId = useId();
	const noteId = useId();
	const { data: config } = useAppConfig();
	const { data: session } = useSession();
	const { ensureConsent, consentDialog } = useAiConsentGate();
	const aiDraftMutation = useAiDraftMutation(claim.id);
	const saveDraftMutation = useSaveDraftMutation(claim.id);
	const submitDraftMutation = useSubmitDraftMutation(claim.id);
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();
	const { t, locale, localeOption } = useI18n();
	const m = t.detail.message;

	// The message goes out in the consumer's own name, never the service's. Both the AI draft
	// and the template end with the [이름] placeholder; it is filled here, on this device, with
	// the name on the account (the name is not sent to the AI). It stays editable.
	const signAsMe = (text: string) => {
		const name = session?.user?.name?.trim();
		return name ? text.replaceAll("[이름]", name) : text;
	};

	const latestDraft = claim.drafts[0] ?? null;
	const [body, setBody] = useState(() =>
		incoming ? signAsMe(incoming.body) : (latestDraft?.body ?? ""),
	);
	const [origin, setOrigin] = useState<"ai" | "template" | "manual">(
		incoming ? "ai" : (latestDraft?.origin ?? "manual"),
	);
	const [modelName, setModelName] = useState(
		incoming?.model ?? latestDraft?.model ?? "",
	);
	const [summaryKo, setSummaryKo] = useState(incoming?.summaryKo ?? "");
	const [missingInfo, setMissingInfo] = useState<string[]>(
		incoming?.missingInfo ?? [],
	);
	const [sentConfirmed, setSentConfirmed] = useState(false);
	const [sentNote, setSentNote] = useState("");

	// The version this box last knew as the saved one. A newer one can appear that this box did
	// not save itself: the agent saved the message it wrote, after the person allowed it. Then
	// the box shows that version, but only if nothing unsaved is in it. Text the person is
	// still working on is never replaced.
	const [seenDraft, setSeenDraft] = useState(latestDraft);
	if (latestDraft && latestDraft.id !== seenDraft?.id) {
		setSeenDraft(latestDraft);
		const untouched =
			!body.trim() || body.trim() === (seenDraft?.body ?? "").trim();
		if (untouched && latestDraft.body.trim() !== body.trim()) {
			setBody(latestDraft.body);
			setOrigin(latestDraft.origin);
			setModelName(latestDraft.model);
			setSummaryKo("");
			setMissingInfo([]);
		}
	}

	// One blue button at a time: "write it" while the box is empty, "save" once there is
	// something new to save. The other one stays gray.
	const hasText = body.trim().length > 0;
	const hasUnsaved =
		hasText && body.trim() !== (latestDraft?.body ?? "").trim();

	const handleGenerateAiDraft = async () => {
		// Nothing goes to the AI until the person has read what is sent and agreed.
		if (!(await ensureConsent())) return;
		try {
			const res = await runCalmly(() => aiDraftMutation.mutateAsync());
			if (!res) return;
			setBody(signAsMe(res.body));
			setOrigin("ai");
			setModelName(res.model);
			setSummaryKo(res.summaryKo ?? "");
			setMissingInfo(res.missingInfo ?? []);
			showToast(m.toastAiDone);
		} catch (error) {
			showToast(errorText(error, m.toastAiFail, locale), "error");
		}
	};

	const handleLoadTemplate = async () => {
		try {
			const tpl = await inquiryApi.getTemplate(claim.id);
			setBody(signAsMe(tpl.body));
			setOrigin("template");
			setModelName("");
			setSummaryKo(tpl.notice);
			setMissingInfo([]);
			showToast(m.toastTemplateDone);
		} catch (error) {
			showToast(errorText(error, m.toastTemplateFail, locale), "error");
		}
	};

	const handleCopy = async () => {
		if (!body.trim()) return;
		await navigator.clipboard.writeText(body);
		showToast(m.toastCopied);
	};

	const handleSaveDraft = async () => {
		try {
			await saveDraftMutation.mutateAsync({
				version: claim.version,
				body,
				origin,
				model: modelName,
			});
			showToast(m.toastSaved);
		} catch (error) {
			showToast(errorText(error, m.toastSaveFail, locale), "error");
		}
	};

	const handleMarkSent = async () => {
		if (!latestDraft) return;
		try {
			await submitDraftMutation.mutateAsync({
				version: claim.version,
				draftId: latestDraft.id,
				confirmed: sentConfirmed,
				note: sentNote,
			});
			setSentConfirmed(false);
			setSentNote("");
			showToast(m.toastSent);
		} catch (error) {
			showToast(errorText(error, m.toastSentFail, locale), "error");
		}
	};

	return (
		<div className="space-y-4">
			{consentDialog}
			<Card className="space-y-4">
				<div className="flex flex-wrap items-center justify-between gap-3">
					<div>
						<Badge tone="brand">{m.eyebrow}</Badge>
						<h3 className="mt-1 text-lg font-bold text-relo-ink">{m.title}</h3>
						<p className="mt-1 text-xs text-relo-muted">{m.ownNote}</p>
					</div>

					<div className="flex flex-wrap gap-2">
						{config?.ai.enabled ? (
							<Button
								variant={hasText ? "secondary" : "primary"}
								size="md"
								isLoading={isPreparing || aiDraftMutation.isPending}
								onClick={handleGenerateAiDraft}
							>
								<Sparkles className="h-4 w-4" aria-hidden="true" />
								<span>{m.aiButton}</span>
							</Button>
						) : null}
						<Button variant="secondary" size="md" onClick={handleLoadTemplate}>
							<FileText className="h-4 w-4" aria-hidden="true" />
							<span>{m.templateButton}</span>
						</Button>
					</div>
				</div>

				{isPreparing ? (
					<div className="rounded-2xl bg-relo-brand-soft/50 py-6">
						<ReloOrbEmblem
							variant="processing"
							size="md"
							speech={m.preparing}
						/>
					</div>
				) : (
					<>
						{summaryKo ? (
							<div className="rounded-2xl bg-relo-brand-soft/65 p-3.5 text-xs font-semibold text-relo-ink">
								{m.summaryPrefix} {summaryKo}
							</div>
						) : null}

						{missingInfo.length > 0 ? (
							<div className="rounded-2xl border border-amber-200 bg-relo-sunny-soft p-3.5 text-xs text-relo-sunny-ink">
								<p className="font-extrabold">{m.missingTitle}</p>
								<ul className="mt-1 list-inside list-disc">
									{missingInfo.map((m) => (
										<li key={m}>{m}</li>
									))}
								</ul>
							</div>
						) : null}

						<div className="space-y-1.5">
							<label
								htmlFor={editorId}
								className="block text-xs font-bold text-relo-muted"
							>
								{m.editorLabel}
							</label>
							<textarea
								id={editorId}
								rows={9}
								value={body}
								onChange={(e) => setBody(e.target.value)}
								placeholder={m.editorPlaceholder}
								className="w-full rounded-2xl border border-relo-line-strong bg-relo-sunken/40 p-4 text-sm leading-relaxed text-relo-ink focus:border-relo-brand focus:bg-white"
							/>
							{/* What the AI wrote always says so, also when a saved AI draft is opened again. */}
							{origin === "ai" && hasText ? (
								<p className="text-xs text-relo-muted">{m.aiNote}</p>
							) : null}
						</div>

						<div className="flex flex-wrap items-center justify-between gap-2">
							<Button
								variant="secondary"
								size="md"
								disabled={!body.trim()}
								onClick={handleCopy}
							>
								<Copy className="h-4 w-4" aria-hidden="true" />
								<span>{m.copy}</span>
							</Button>

							<Button
								variant={hasUnsaved ? "primary" : "secondary"}
								size="md"
								disabled={body.trim().length < 20}
								isLoading={saveDraftMutation.isPending}
								onClick={handleSaveDraft}
							>
								<Check className="h-4 w-4" aria-hidden="true" />
								<span>{m.save}</span>
							</Button>
						</div>
					</>
				)}
			</Card>

			{latestDraft ? (
				<Card className="space-y-3 border-relo-brand-line bg-relo-brand-soft/35">
					<div className="flex flex-wrap items-center justify-between gap-2">
						<p className="text-sm font-extrabold text-relo-ink">
							{m.sentQuestion}
						</p>
						<Badge tone="brand">
							{latestDraft.submittedAt
								? fill(m.sentDone, {
										date: formatLocalDate(
											latestDraft.submittedAt,
											localeOption.bcp47,
										),
									})
								: m.sentPending}
						</Badge>
					</div>

					{latestDraft.stale && !latestDraft.submittedAt ? (
						<div className="flex items-center gap-2 rounded-xl bg-relo-sunny-soft p-3 text-xs font-semibold text-relo-sunny-ink">
							<AlertTriangle className="h-4 w-4 shrink-0" aria-hidden="true" />
							<span>{m.staleNotice}</span>
						</div>
					) : null}

					{!latestDraft.submittedAt ? (
						<div className="space-y-3 pt-1">
							<div className="space-y-1">
								<label
									htmlFor={noteId}
									className="text-xs font-bold text-relo-muted"
								>
									{m.noteLabel}
								</label>
								<input
									id={noteId}
									type="text"
									value={sentNote}
									onChange={(e) => setSentNote(e.target.value)}
									placeholder={m.notePlaceholder}
									className="min-h-10 w-full rounded-xl border border-relo-line-strong bg-white px-3 text-xs text-relo-ink"
								/>
							</div>

							<label className="flex cursor-pointer items-center gap-2 text-xs font-semibold text-relo-ink">
								<input
									type="checkbox"
									checked={sentConfirmed}
									onChange={(e) => setSentConfirmed(e.target.checked)}
									className="h-4 w-4 rounded accent-relo-brand"
								/>
								<span>{m.confirmSent}</span>
							</label>

							<Button
								variant="primary"
								size="md"
								disabled={!sentConfirmed || latestDraft.stale}
								isLoading={submitDraftMutation.isPending}
								onClick={handleMarkSent}
							>
								<Send className="h-4 w-4" aria-hidden="true" />
								<span>{m.markSent}</span>
							</Button>
						</div>
					) : null}
				</Card>
			) : null}
		</div>
	);
}
