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
import {
	useAiConsentMutation,
	useAppConfig,
	useSession,
} from "@/client/hooks/useSession";
import { inquiryApi } from "@/client/lib/api-client";
import { formatKoreanDate } from "@/client/lib/format";
import { useCalmPreparation } from "@/client/lib/preparation";
import type { ClaimView } from "@/client/types";

export function ForeignMessageStudio({ claim }: { claim: ClaimView }) {
	const editorId = useId();
	const noteId = useId();
	const { data: session } = useSession();
	const { data: config } = useAppConfig();
	const aiConsentMutation = useAiConsentMutation();
	const aiDraftMutation = useAiDraftMutation(claim.id);
	const saveDraftMutation = useSaveDraftMutation(claim.id);
	const submitDraftMutation = useSubmitDraftMutation(claim.id);
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();

	const latestDraft = claim.drafts[0] ?? null;
	const [body, setBody] = useState(latestDraft?.body ?? "");
	const [origin, setOrigin] = useState<"ai" | "template" | "manual">(
		latestDraft?.origin ?? "manual",
	);
	const [modelName, setModelName] = useState(latestDraft?.model ?? "");
	const [summaryKo, setSummaryKo] = useState("");
	const [missingInfo, setMissingInfo] = useState<string[]>([]);
	const [sentConfirmed, setSentConfirmed] = useState(false);
	const [sentNote, setSentNote] = useState("");

	const handleGenerateAiDraft = async () => {
		try {
			if (!session?.user?.aiConsentAt) {
				await aiConsentMutation.mutateAsync(true);
			}
			const res = await runCalmly(() => aiDraftMutation.mutateAsync());
			if (!res) return;
			setBody(res.body);
			setOrigin("ai");
			setModelName(res.model);
			setSummaryKo(res.summaryKo ?? "");
			setMissingInfo(res.missingInfo ?? []);
			showToast("해외 쇼핑몰에 보낼 맞춤 외국어 요청서를 완성했어요!");
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "자동 작성에 실패했어요. 아래 표준 영문 양식을 불러올 수 있어요.",
				"error",
			);
		}
	};

	const handleLoadTemplate = async () => {
		try {
			const tpl = await inquiryApi.getTemplate(claim.id);
			setBody(tpl.body);
			setOrigin("template");
			setModelName("");
			setSummaryKo(tpl.notice);
			setMissingInfo([]);
			showToast("주문 정보가 담긴 기본 영문 요청서 양식을 불러왔어요!");
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "기본 양식을 불러오지 못했어요.",
				"error",
			);
		}
	};

	const handleCopy = async () => {
		if (!body.trim()) return;
		await navigator.clipboard.writeText(body);
		showToast(
			"외국어 메시지가 복사되었어요! 쇼핑몰 채팅창이나 이메일에 붙여넣어 보내세요.",
		);
	};

	const handleSaveDraft = async () => {
		try {
			await saveDraftMutation.mutateAsync({
				version: claim.version,
				body,
				origin,
				model: modelName,
			});
			showToast("작성한 메시지가 안전하게 저장되었어요!");
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "메시지 저장에 실패했어요.",
				"error",
			);
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
			showToast(
				"쇼핑몰에 메시지를 보낸 내역이 저장되어 '답변 대기'로 바뀌었어요!",
			);
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "전송 기록에 실패했어요.",
				"error",
			);
		}
	};

	return (
		<div className="space-y-4">
			<Card className="space-y-4">
				<div className="flex flex-wrap items-center justify-between gap-3">
					<div>
						<Badge tone="brand">외국어 환불 메시지 자동 작성</Badge>
						<h3 className="mt-1 text-lg font-bold text-relo-ink">
							해외 쇼핑몰 고객센터에 보낼 정중한 메시지
						</h3>
					</div>

					<div className="flex flex-wrap gap-2">
						{config?.ai.enabled ? (
							<Button
								variant="primary"
								size="md"
								isLoading={isPreparing || aiDraftMutation.isPending}
								onClick={handleGenerateAiDraft}
							>
								<Sparkles className="h-4 w-4" aria-hidden="true" />
								<span>맞춤 영문 메시지 자동 작성</span>
							</Button>
						) : null}
						<Button variant="secondary" size="md" onClick={handleLoadTemplate}>
							<FileText className="h-4 w-4" aria-hidden="true" />
							<span>기본 영문 양식 불러오기</span>
						</Button>
					</div>
				</div>

				{isPreparing ? (
					<div className="rounded-2xl bg-relo-brand-soft/50 py-6">
						<ReloOrbEmblem
							variant="processing"
							size="md"
							speech="주문번호, 돌려받을 금액, 불량 설명을 바탕으로 쇼핑몰 상담원이 바로 이해할 문장을 만들고 있어요..."
						/>
					</div>
				) : (
					<>
						{summaryKo ? (
							<div className="rounded-2xl bg-relo-brand-soft/65 p-3.5 text-xs font-semibold text-relo-ink">
								작성 요약: {summaryKo}
							</div>
						) : null}

						{missingInfo.length > 0 ? (
							<div className="rounded-2xl border border-amber-200 bg-relo-sunny-soft p-3.5 text-xs text-relo-sunny-ink">
								<p className="font-extrabold">
									보내기 전 대괄호 [확인 필요] 부분을 내 정보로 채워 주세요:
								</p>
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
								쇼핑몰에 보낼 메시지 내용 (직접 고칠 수 있어요 · 최소 20자)
							</label>
							<textarea
								id={editorId}
								rows={9}
								value={body}
								onChange={(e) => setBody(e.target.value)}
								placeholder="위의 [맞춤 영문 메시지 자동 작성] 또는 [기본 영문 양식 불러오기] 버튼을 눌러 바로 만들어 보세요."
								className="w-full rounded-2xl border border-relo-line-strong bg-relo-sunken/40 p-4 font-mono text-xs leading-relaxed text-relo-ink focus:border-relo-brand focus:bg-white"
							/>
						</div>

						<div className="flex flex-wrap items-center justify-between gap-2">
							<Button
								variant="secondary"
								size="md"
								disabled={!body.trim()}
								onClick={handleCopy}
							>
								<Copy className="h-4 w-4" aria-hidden="true" />
								<span>전체 내용 복사하기</span>
							</Button>

							<Button
								variant="primary"
								size="md"
								disabled={body.trim().length < 20}
								isLoading={saveDraftMutation.isPending}
								onClick={handleSaveDraft}
							>
								<Check className="h-4 w-4" aria-hidden="true" />
								<span>이 메시지 저장하기</span>
							</Button>
						</div>
					</>
				)}
			</Card>

			{latestDraft ? (
				<Card className="space-y-3 border-relo-brand-line bg-relo-brand-soft/35">
					<div className="flex flex-wrap items-center justify-between gap-2">
						<p className="text-sm font-extrabold text-relo-ink">
							쇼핑몰 이메일이나 채팅창에 위 내용을 붙여넣어 보냈나요?
						</p>
						<Badge tone="brand">
							{latestDraft.submittedAt
								? `${formatKoreanDate(latestDraft.submittedAt)} 전송 완료`
								: "전송 확인 전"}
						</Badge>
					</div>

					{latestDraft.stale && !latestDraft.submittedAt ? (
						<div className="flex items-center gap-2 rounded-xl bg-relo-sunny-soft p-3 text-xs font-semibold text-relo-sunny-ink">
							<AlertTriangle className="h-4 w-4 shrink-0" aria-hidden="true" />
							<span>
								주문 정보나 사진이 바뀌었어요. 위에서 [이 메시지 저장하기]를 한
								번 더 누른 뒤 전송 완료를 눌러 주세요.
							</span>
						</div>
					) : null}

					{!latestDraft.submittedAt ? (
						<div className="space-y-3 pt-1">
							<div className="space-y-1">
								<label
									htmlFor={noteId}
									className="text-xs font-bold text-relo-muted"
								>
									어디로 보냈는지 메모 (선택 · 예: Amazon 채팅 상담 전송)
								</label>
								<input
									id={noteId}
									type="text"
									value={sentNote}
									onChange={(e) => setSentNote(e.target.value)}
									placeholder="예: AliExpress 고객센터 페이지에 사진과 함께 제출함"
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
								<span>
									내용에 틀린 부분이 없는지 확인하고 쇼핑몰에 직접 보냈어요.
								</span>
							</label>

							<Button
								variant="primary"
								size="md"
								disabled={!sentConfirmed || latestDraft.stale}
								isLoading={submitDraftMutation.isPending}
								onClick={handleMarkSent}
							>
								<Send className="h-4 w-4" aria-hidden="true" />
								<span>쇼핑몰 전송 완료로 표시하기</span>
							</Button>
						</div>
					) : null}
				</Card>
			) : null}
		</div>
	);
}
