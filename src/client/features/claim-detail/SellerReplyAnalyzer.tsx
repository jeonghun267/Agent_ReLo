/**
 * @module client/features/claim-detail/SellerReplyAnalyzer
 * @layer View (Foreign Seller Reply Summary & Promised Refund Saver)
 * @purpose Summarizes foreign seller messages into plain 3-line Korean, records the
 *          seller's promised refund amount, and lets the way it is settled change (a refund
 *          that became an exchange, or the other way) until something has come in.
 */

import { Check, HandCoins, Languages, MessageSquarePlus } from "lucide-react";
import { useId, useState } from "react";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Badge,
	Button,
	Card,
	TextField,
	useToast,
} from "@/client/components/ui/Primitives";
import {
	useAiAnalyzeReplyMutation,
	useRecordReplyMutation,
	useUpdateClaimMutation,
} from "@/client/hooks/useClaims";
import {
	useAiConsentMutation,
	useAppConfig,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import {
	claimToInput,
	hasReceived,
	isLocked,
} from "@/client/lib/claim-progress";
import { errorText, kindWords, replyKindLabel } from "@/client/lib/claim-words";
import {
	fill,
	formatLocalDate,
	minorToDecimalString,
} from "@/client/lib/format";
import { useCalmPreparation } from "@/client/lib/preparation";
import type { ClaimKind, ClaimView, ReplyKind } from "@/client/types";

const KIND_ORDER: ClaimKind[] = ["refund", "exchange", "repair"];
const REPLY_KIND_ORDER: ReplyKind[] = [
	"agreement",
	"refund_notice",
	"evidence",
	"denied",
	"other",
];

export function SellerReplyAnalyzer({ claim }: { claim: ClaimView }) {
	const replyTextareaId = useId();
	const kindSelectId = useId();
	const { data: session } = useSession();
	const { data: config } = useAppConfig();
	const aiConsentMutation = useAiConsentMutation();
	const analyzeMutation = useAiAnalyzeReplyMutation(claim.id);
	const recordReplyMutation = useRecordReplyMutation(claim.id);
	const updateClaimMutation = useUpdateClaimMutation(claim.id);
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();
	const { t, locale, localeOption } = useI18n();
	const r = t.detail.reply;
	const method = t.kinds.method;
	// An exchange or a repair words three of the reply kinds after what is sent, not money.
	const replyOptions = {
		...r.kindOptions,
		...kindWords(t, claim.kind)?.replyOptions,
	};
	const methodFixed = hasReceived(claim) || isLocked(claim);

	const [rawReply, setRawReply] = useState("");
	const [replyKind, setReplyKind] = useState<ReplyKind>("agreement");
	const [translationKo, setTranslationKo] = useState("");
	const [summaryKo, setSummaryKo] = useState("");
	const [aiAssisted, setAiAssisted] = useState(false);

	const [agreedInput, setAgreedInput] = useState(
		minorToDecimalString(claim.agreed, claim.currency),
	);
	// The promised amount only needs the blue button while it differs from what is saved.
	const agreedChanged =
		agreedInput.trim() !== "" &&
		agreedInput.trim() !== minorToDecimalString(claim.agreed, claim.currency);

	const handleAiAnalyze = async () => {
		if (rawReply.trim().length < 5) {
			showToast(r.toastNeedReply, "error");
			return;
		}
		try {
			if (!session?.user?.aiConsentAt) {
				await aiConsentMutation.mutateAsync(true);
			}
			const res = await runCalmly(() => analyzeMutation.mutateAsync(rawReply));
			if (!res) return;
			setTranslationKo(res.translationKo);
			setSummaryKo(res.summaryKo);
			setReplyKind(res.suggestedKind);
			setAiAssisted(true);
			if (
				res.mentionedAmount &&
				(!res.mentionedCurrency || res.mentionedCurrency === claim.currency)
			) {
				setAgreedInput(res.mentionedAmount);
			}
			showToast(r.toastAnalyzed);
		} catch (error) {
			showToast(errorText(error, r.toastAnalyzeFail, locale), "error");
		}
	};

	const handleRecordReply = async () => {
		try {
			await recordReplyMutation.mutateAsync({
				version: claim.version,
				body: rawReply,
				kind: replyKind,
				translationKo,
				summaryKo,
				aiAssisted,
			});
			setRawReply("");
			setTranslationKo("");
			setSummaryKo("");
			setAiAssisted(false);
			showToast(r.toastSaved);
		} catch (error) {
			showToast(errorText(error, r.toastSaveFail, locale), "error");
		}
	};

	const handleSaveAgreedAmount = async () => {
		try {
			await updateClaimMutation.mutateAsync({
				version: claim.version,
				input: { ...claimToInput(claim), agreedAmount: agreedInput.trim() },
			});
			showToast(r.toastAgreedSaved);
		} catch (error) {
			showToast(errorText(error, r.toastAgreedFail, locale), "error");
		}
	};

	const handleChangeKind = async (kind: ClaimKind) => {
		if (kind === claim.kind) return;
		try {
			await updateClaimMutation.mutateAsync({
				version: claim.version,
				input: { ...claimToInput(claim), kind },
			});
			showToast(method.toastSaved);
		} catch (error) {
			showToast(errorText(error, method.toastFail, locale), "error");
		}
	};

	return (
		<div className="space-y-4">
			<div className="flex flex-wrap items-center justify-between gap-x-4 gap-y-2 px-1">
				<p className="text-sm font-semibold text-relo-ink">{method.label}</p>
				{/* biome-ignore lint/a11y/useSemanticElements: a three-way toggle, not a form fieldset */}
				<div
					role="group"
					aria-label={method.label}
					className="inline-flex rounded-full bg-relo-sunken p-1"
				>
					{KIND_ORDER.map((kind) => (
						<button
							key={kind}
							type="button"
							aria-pressed={claim.kind === kind}
							disabled={methodFixed || updateClaimMutation.isPending}
							onClick={() => void handleChangeKind(kind)}
							className={`rounded-full px-3 py-1.5 text-xs font-semibold transition enabled:cursor-pointer disabled:cursor-not-allowed max-sm:min-h-10 ${
								claim.kind === kind
									? "bg-white font-bold text-relo-ink shadow-2xs"
									: "text-relo-muted enabled:hover:text-relo-ink"
							}`}
						>
							{t.shared.kinds[kind]}
						</button>
					))}
				</div>
				{hasReceived(claim) ? (
					<p className="w-full text-xs text-relo-muted">{method.locked}</p>
				) : null}
			</div>

			{claim.kind === "refund" ? (
				<Card className="border-relo-brand-line bg-relo-brand-soft/35 p-5">
					<div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
						<div className="flex-1">
							<Badge tone="brand">
								<HandCoins className="h-3.5 w-3.5" aria-hidden="true" />
								<span>{r.agreedEyebrow}</span>
							</Badge>
							<div className="mt-2">
								<TextField
									label={fill(r.agreedLabel, { cur: claim.currency })}
									value={agreedInput}
									onChange={(e) => setAgreedInput(e.target.value)}
									placeholder={fill(r.agreedPlaceholder, {
										amount: minorToDecimalString(claim.claimed, claim.currency),
									})}
									hint={r.agreedHint}
								/>
							</div>
						</div>
						<Button
							variant={agreedChanged ? "primary" : "secondary"}
							size="md"
							isLoading={updateClaimMutation.isPending}
							onClick={handleSaveAgreedAmount}
						>
							<Check className="h-4 w-4" aria-hidden="true" />
							<span>{r.agreedSave}</span>
						</Button>
					</div>
				</Card>
			) : null}

			<Card className="space-y-4">
				<div className="flex flex-wrap items-center justify-between gap-2">
					<div>
						<Badge tone="brand">{r.eyebrow}</Badge>
						<h3 className="mt-1 text-lg font-extrabold text-relo-ink">
							{r.title}
						</h3>
					</div>
					{config?.ai.enabled ? (
						<Button
							variant="secondary"
							size="md"
							isLoading={isPreparing || analyzeMutation.isPending}
							onClick={handleAiAnalyze}
						>
							<Languages className="h-4 w-4" aria-hidden="true" />
							<span>{r.summarize}</span>
						</Button>
					) : null}
				</div>

				{isPreparing ? (
					<div className="rounded-2xl bg-relo-brand-soft/50 py-6">
						<ReloOrbEmblem
							variant="processing"
							size="md"
							speech={r.analyzing}
						/>
					</div>
				) : (
					<>
						<div className="space-y-1.5">
							<label
								htmlFor={replyTextareaId}
								className="block text-xs font-bold text-relo-muted"
							>
								{r.rawLabel}
							</label>
							<textarea
								id={replyTextareaId}
								rows={4}
								value={rawReply}
								onChange={(e) => setRawReply(e.target.value)}
								placeholder={r.rawPlaceholder}
								className="w-full rounded-2xl border border-relo-line-strong bg-white p-3.5 text-xs leading-relaxed text-relo-ink"
							/>
						</div>

						{summaryKo || translationKo ? (
							<div className="space-y-2 rounded-2xl border border-relo-brand-line bg-relo-brand-soft/45 p-4 text-xs">
								{summaryKo ? (
									<p className="font-extrabold text-relo-brand">
										{r.summaryPrefix} {summaryKo}
									</p>
								) : null}
								{translationKo ? (
									<p className="leading-relaxed whitespace-pre-wrap text-relo-ink">
										{translationKo}
									</p>
								) : null}
							</div>
						) : null}

						<div className="flex flex-wrap items-end justify-between gap-3">
							<div className="space-y-1">
								<label
									htmlFor={kindSelectId}
									className="block text-xs font-bold text-relo-muted"
								>
									{r.kindLabel}
								</label>
								<select
									id={kindSelectId}
									value={replyKind}
									onChange={(e) => setReplyKind(e.target.value as ReplyKind)}
									className="min-h-11 rounded-xl border border-relo-line-strong bg-white px-3 text-xs font-bold text-relo-ink"
								>
									{REPLY_KIND_ORDER.map((kind) => (
										<option key={kind} value={kind}>
											{replyOptions[kind]}
										</option>
									))}
								</select>
							</div>

							<Button
								variant="primary"
								size="md"
								disabled={!rawReply.trim()}
								isLoading={recordReplyMutation.isPending}
								onClick={handleRecordReply}
							>
								<MessageSquarePlus className="h-4 w-4" aria-hidden="true" />
								<span>{r.save}</span>
							</Button>
						</div>
					</>
				)}
			</Card>

			{claim.replies.length > 0 ? (
				<Card className="space-y-3">
					<h4 className="text-sm font-extrabold text-relo-ink">
						{fill(r.savedTitle, { n: claim.replies.length })}
					</h4>
					<ul className="space-y-2.5">
						{claim.replies.map((rep) => (
							<li
								key={rep.id}
								className="space-y-1.5 rounded-2xl border border-relo-line bg-relo-sunken p-3.5 text-xs"
							>
								<div className="flex items-center justify-between">
									<Badge tone={rep.kind === "denied" ? "danger" : "brand"}>
										{replyKindLabel(t, rep.kind, claim.kind)}
									</Badge>
									<span className="text-relo-muted">
										{formatLocalDate(rep.recordedAt, localeOption.bcp47)}
									</span>
								</div>
								{rep.summaryKo ? (
									<p className="font-bold text-relo-ink">{rep.summaryKo}</p>
								) : null}
								<p className="whitespace-pre-wrap text-relo-muted">
									{rep.body}
								</p>
							</li>
						))}
					</ul>
				</Card>
			) : null}
		</div>
	);
}
