/**
 * @module client/features/claim-detail/SellerReplyAnalyzer
 * @layer View (Foreign Seller Reply Summary & Promised Refund Saver)
 * @purpose Summarizes foreign seller messages into plain 3-line Korean and records
 *          the seller's promised refund amount.
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
import { formatKoreanDate, minorToDecimalString } from "@/client/lib/format";
import { useCalmPreparation } from "@/client/lib/preparation";
import type { ClaimView, ReplyKind } from "@/client/types";

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

	const [rawReply, setRawReply] = useState("");
	const [replyKind, setReplyKind] = useState<ReplyKind>("agreement");
	const [translationKo, setTranslationKo] = useState("");
	const [summaryKo, setSummaryKo] = useState("");
	const [aiAssisted, setAiAssisted] = useState(false);

	const [agreedInput, setAgreedInput] = useState(
		minorToDecimalString(claim.agreed, claim.currency),
	);

	const handleAiAnalyze = async () => {
		if (rawReply.trim().length < 5) {
			showToast("쇼핑몰에서 받은 외국어 답장을 먼저 붙여넣어 주세요!", "error");
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
			showToast("쇼핑몰 답장의 핵심 내용과 약속 금액을 쉽게 정리했어요!");
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "답장 요약에 실패했어요.",
				"error",
			);
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
			showToast("쇼핑몰 답장 내역이 안전하게 저장되었어요!");
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "답장 저장에 실패했어요.",
				"error",
			);
		}
	};

	const handleSaveAgreedAmount = async () => {
		try {
			await updateClaimMutation.mutateAsync({
				version: claim.version,
				input: {
					title: claim.title,
					vendor: claim.vendor,
					vendorUrl: claim.vendorUrl,
					orderRef: claim.orderRef,
					orderedOn: claim.orderedOn,
					kind: claim.kind,
					currency: claim.currency,
					claimedAmount: minorToDecimalString(claim.claimed, claim.currency),
					agreedAmount: agreedInput.trim(),
					issue: claim.issue,
					issueEnglish: claim.issueEnglish,
					deadline: claim.deadline ?? "",
					deadlineQuote: claim.deadlineQuote,
					deadlineZone: claim.deadlineZone,
					items: claim.items.map((it) => ({
						name: it.name,
						sku: it.sku,
						orderedQty: it.orderedQty,
						claimQty: it.claimQty,
						unitPrice: minorToDecimalString(it.unitPrice, claim.currency),
					})),
				},
			});
			showToast(
				"쇼핑몰이 약속한 환불 금액을 저장했어요! 이제 실제 입금을 확인할 수 있어요.",
			);
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "약속 금액 저장에 실패했어요.",
				"error",
			);
		}
	};

	return (
		<div className="space-y-4">
			{claim.kind === "refund" ? (
				<Card className="border-relo-brand-line bg-relo-brand-soft/35 p-5">
					<div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
						<div className="flex-1">
							<Badge tone="brand">
								<HandCoins className="h-3.5 w-3.5" aria-hidden="true" />
								<span>쇼핑몰이 약속한 환불 금액</span>
							</Badge>
							<div className="mt-2">
								<TextField
									label={`쇼핑몰에서 돌려주기로 약속한 금액 (${claim.currency})`}
									value={agreedInput}
									onChange={(e) => setAgreedInput(e.target.value)}
									placeholder={`신청 금액: ${minorToDecimalString(claim.claimed, claim.currency)}`}
									hint="전액 환불하기로 했다면 신청 금액과 똑같이 적고 저장해 주세요."
								/>
							</div>
						</div>
						<Button
							variant="primary"
							size="md"
							isLoading={updateClaimMutation.isPending}
							onClick={handleSaveAgreedAmount}
						>
							<Check className="h-4 w-4" aria-hidden="true" />
							<span>약속 금액 저장</span>
						</Button>
					</div>
				</Card>
			) : null}

			<Card className="space-y-4">
				<div className="flex flex-wrap items-center justify-between gap-2">
					<div>
						<Badge tone="brand">외국어 답장 쉬운 요약</Badge>
						<h3 className="mt-1 text-lg font-extrabold text-relo-ink">
							쇼핑몰에서 온 이메일·채팅 답장을 그대로 붙여넣으세요
						</h3>
					</div>
					{config?.ai.enabled ? (
						<Button
							variant="primary"
							size="md"
							isLoading={isPreparing || analyzeMutation.isPending}
							onClick={handleAiAnalyze}
						>
							<Languages className="h-4 w-4" aria-hidden="true" />
							<span>쉬운 우리말로 요약하기</span>
						</Button>
					) : null}
				</div>

				{isPreparing ? (
					<div className="rounded-2xl bg-relo-brand-soft/50 py-6">
						<ReloOrbEmblem
							variant="processing"
							size="md"
							speech="답장 내용이 환불 승인인지, 추가 사진 요청인지, 반품 기한이 있는지 읽고 있어요..."
						/>
					</div>
				) : (
					<>
						<div className="space-y-1.5">
							<label
								htmlFor={replyTextareaId}
								className="block text-xs font-bold text-relo-muted"
							>
								쇼핑몰 답장 원문 (영어·일본어·중국어 등 모든 언어)
							</label>
							<textarea
								id={replyTextareaId}
								rows={4}
								value={rawReply}
								onChange={(e) => setRawReply(e.target.value)}
								placeholder="예: Hello, we sincerely apologize for the damaged package. We have approved a full refund of $129.99..."
								className="w-full rounded-2xl border border-relo-line-strong bg-white p-3.5 text-xs leading-relaxed text-relo-ink"
							/>
						</div>

						{summaryKo || translationKo ? (
							<div className="space-y-2 rounded-2xl border border-relo-brand-line bg-relo-brand-soft/45 p-4 text-xs">
								{summaryKo ? (
									<p className="font-extrabold text-relo-brand">
										핵심 요약: {summaryKo}
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
									답장 내용 분류
								</label>
								<select
									id={kindSelectId}
									value={replyKind}
									onChange={(e) => setReplyKind(e.target.value as ReplyKind)}
									className="min-h-11 rounded-xl border border-relo-line-strong bg-white px-3 text-xs font-bold text-relo-ink"
								>
									<option value="agreement">환불·교환 약속 (금액 합의)</option>
									<option value="refund_notice">
										환불 처리 안내 (아직 실제 입금 전)
									</option>
									<option value="evidence">추가 사진·자료 요청</option>
									<option value="denied">환불 거절 · 재문의 필요</option>
									<option value="other">기타 안내</option>
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
								<span>답장 내역 저장하기</span>
							</Button>
						</div>
					</>
				)}
			</Card>

			{claim.replies.length > 0 ? (
				<Card className="space-y-3">
					<h4 className="text-sm font-extrabold text-relo-ink">
						저장된 쇼핑몰 답장 ({claim.replies.length}건)
					</h4>
					<ul className="space-y-2.5">
						{claim.replies.map((rep) => (
							<li
								key={rep.id}
								className="space-y-1.5 rounded-2xl border border-relo-line bg-relo-sunken p-3.5 text-xs"
							>
								<div className="flex items-center justify-between">
									<Badge tone={rep.kind === "denied" ? "danger" : "brand"}>
										{config?.replyKinds[rep.kind] ?? rep.kind}
									</Badge>
									<span className="text-relo-muted">
										{formatKoreanDate(rep.recordedAt)}
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
