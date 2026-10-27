/**
 * @module client/features/claim-detail/EvidenceAndSettlementTab
 * @layer View (Private Photo Vault & Real Card Deposit Confirmation Tab)
 * @purpose Combines ClaimFilesVaultCard with the 2-step card cancellation / bank deposit
 *          confirmation form using a unified Toss Blue accent.
 */

import confetti from "canvas-confetti";
import { CheckCircle2, PartyPopper, Wallet } from "lucide-react";
import { useId } from "react";
import { useForm } from "react-hook-form";
import {
	Badge,
	Button,
	Card,
	TextField,
	useToast,
} from "@/client/components/ui/Primitives";
import { ClaimFilesVaultCard } from "@/client/features/claim-detail/ClaimFilesVaultCard";
import { useRecordReceiptMutation } from "@/client/hooks/useClaims";
import { formatMinorMoney, minorToDecimalString } from "@/client/lib/format";
import { zodV4Resolver } from "@/client/lib/zod-resolver";
import {
	type ClaimView,
	type ReceiptFormValues,
	receiptFormSchema,
} from "@/client/types";

export function EvidenceAndSettlementTab({ claim }: { claim: ClaimView }) {
	const proofSelectId = useId();
	const { showToast } = useToast();
	const recordReceiptMutation = useRecordReceiptMutation(claim.id);

	const defaultReceiptKind =
		claim.kind === "refund"
			? "cash"
			: claim.kind === "exchange"
				? "goods"
				: "repair";

	const receiptForm = useForm<ReceiptFormValues>({
		resolver: zodV4Resolver(receiptFormSchema),
		defaultValues: {
			kind: defaultReceiptKind,
			proofId: claim.files[0]?.id ?? "",
			receivedOn: new Date().toISOString().slice(0, 10),
			amount:
				claim.agreed !== null
					? minorToDecimalString(
							Math.max(0, claim.agreed - claim.summary.cash),
							claim.currency,
						)
					: "",
			quantity: 1,
			transactionRef: "",
			note: "",
			confirmed: false,
		},
	});

	const onSubmitReceipt = receiptForm.handleSubmit(async (data) => {
		try {
			await recordReceiptMutation.mutateAsync({
				version: claim.version,
				input: {
					kind: data.kind,
					proofId: data.proofId,
					receivedOn: data.receivedOn,
					amount: data.amount || undefined,
					quantity: data.quantity,
					transactionRef: data.transactionRef || undefined,
					note: data.note || undefined,
					confirmed: data.confirmed,
				},
			});
			void confetti({
				particleCount: 95,
				spread: 80,
				origin: { y: 0.6 },
			});
			showToast("축하드려요! 실제 카드 취소·통장 입금 내역이 확인되었어요!");
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "입금 확인 기록 저장에 실패했어요.",
				"error",
			);
		}
	});

	return (
		<div className="space-y-5">
			<ClaimFilesVaultCard claim={claim} />

			<Card className="space-y-4 border-relo-brand-line">
				<div>
					<Badge tone="brand">
						<Wallet className="h-3.5 w-3.5" aria-hidden="true" />
						<span>실제 통장 입금 · 카드 취소 확인</span>
					</Badge>
					<h3 className="mt-1 text-lg font-extrabold text-relo-ink">
						쇼핑몰 말만 믿지 않고, 내 카드·통장 입금을 직접 확인해요
					</h3>
					{claim.kind === "refund" && claim.agreed === null ? (
						<p className="mt-1 text-xs font-semibold text-relo-sunny-ink">
							먼저 [쇼핑몰 답장 · 약속 금액] 탭에서 쇼핑몰이 돌려주기로 약속한
							금액을 저장해 주세요.
						</p>
					) : null}
				</div>

				<form onSubmit={onSubmitReceipt} className="space-y-4">
					<div className="grid gap-4 sm:grid-cols-2">
						<div className="space-y-1.5">
							<label
								htmlFor={proofSelectId}
								className="block text-sm font-semibold text-relo-ink"
							>
								입금·카드 취소 캡처 파일 선택
							</label>
							<select
								id={proofSelectId}
								className="min-h-12 w-full rounded-xl border border-relo-line-strong bg-white px-3 text-sm text-relo-ink"
								{...receiptForm.register("proofId")}
							>
								<option value="">보관된 파일 중 선택하세요</option>
								{claim.files.map((f) => (
									<option key={f.id} value={f.id}>
										{f.name}
									</option>
								))}
							</select>
							{receiptForm.formState.errors.proofId ? (
								<p className="text-xs text-relo-danger">
									{receiptForm.formState.errors.proofId.message}
								</p>
							) : null}
						</div>

						<TextField
							label="실제 입금·수령 날짜"
							type="date"
							max={new Date().toISOString().slice(0, 10)}
							error={receiptForm.formState.errors.receivedOn?.message}
							{...receiptForm.register("receivedOn")}
						/>
					</div>

					{claim.kind === "refund" ? (
						<div className="grid gap-4 sm:grid-cols-2">
							<TextField
								label={`실제 돌아온 금액 (${claim.currency})`}
								placeholder="예: 129.99"
								error={receiptForm.formState.errors.amount?.message}
								{...receiptForm.register("amount")}
							/>
							<TextField
								label="카드 취소·입금 번호 (선택)"
								placeholder="예: AMZ-RF-20261027"
								hint="영문·숫자·하이픈(-) 3자 이상 적으면 같은 내역이 두 번 적히지 않아요."
								error={receiptForm.formState.errors.transactionRef?.message}
								{...receiptForm.register("transactionRef")}
							/>
						</div>
					) : null}

					<label className="flex cursor-pointer items-center gap-2 text-xs font-bold text-relo-ink">
						<input
							type="checkbox"
							className="h-4 w-4 rounded accent-relo-brand"
							{...receiptForm.register("confirmed")}
						/>
						<span>
							쇼핑몰 안내 메일이 아니라, 내 실제 카드 취소·통장 입금 내역임을
							직접 확인했어요.
						</span>
					</label>
					{receiptForm.formState.errors.confirmed ? (
						<p className="text-xs text-relo-danger">
							{receiptForm.formState.errors.confirmed.message}
						</p>
					) : null}

					<Button
						type="submit"
						variant="primary"
						size="lg"
						disabled={claim.files.length === 0}
						isLoading={recordReceiptMutation.isPending}
					>
						<PartyPopper className="h-5 w-5" aria-hidden="true" />
						<span>실제 입금 완료 기록하기</span>
					</Button>
				</form>

				{claim.ledger.length > 0 ? (
					<div className="space-y-2 border-t border-relo-line pt-4">
						<p className="text-xs font-extrabold text-relo-muted">
							확인된 입금 내역 ({claim.ledger.length}건)
						</p>
						<ul className="space-y-2">
							{claim.ledger.map((entry) => (
								<li
									key={entry.id}
									className="flex items-center justify-between rounded-xl bg-relo-brand-soft/65 px-3.5 py-2.5 text-xs"
								>
									<span className="inline-flex items-center gap-1.5 font-bold text-relo-brand">
										<CheckCircle2 className="h-4 w-4" aria-hidden="true" />
										<span>
											{entry.receivedOn} · {entry.transactionRef || entry.kind}
										</span>
									</span>
									<span className="font-extrabold text-relo-brand tabular-nums">
										{formatMinorMoney(entry.amount, claim.currency)}
									</span>
								</li>
							))}
						</ul>
					</div>
				) : null}
			</Card>
		</div>
	);
}
