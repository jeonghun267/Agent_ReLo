/**
 * @module client/features/claim-detail/ReceiptForm
 * @layer View ("It Actually Came In" Form)
 * @purpose Records what really came back, with the file that shows it: money for a refund
 *          (with the statement's number, or a note and a check when the line has no number),
 *          how many replacement items for an exchange, the result of a repair.
 */

import confetti from "canvas-confetti";
import { PartyPopper } from "lucide-react";
import { useId } from "react";
import { type UseFormRegisterReturn, useForm } from "react-hook-form";
import { Button, TextField, useToast } from "@/client/components/ui/Primitives";
import { useRecordReceiptMutation } from "@/client/hooks/useClaims";
import { useI18n } from "@/client/i18n";
import { errorText, fieldError, kindWords } from "@/client/lib/claim-words";
import { fill, minorToDecimalString, todayLocalIso } from "@/client/lib/format";
import { zodV4Resolver } from "@/client/lib/zod-resolver";
import {
	type ClaimView,
	type ReceiptFormValues,
	receiptFormSchema,
} from "@/client/types";

const RECEIPT_KIND = {
	refund: "cash",
	exchange: "goods",
	repair: "repair",
} as const;

function CheckLine({
	label,
	error,
	input,
}: {
	label: string;
	error?: string;
	input: UseFormRegisterReturn;
}) {
	return (
		<div className="space-y-1">
			<label className="flex cursor-pointer items-start gap-2 text-xs font-bold text-relo-ink">
				<input
					type="checkbox"
					className="mt-0.5 h-4 w-4 shrink-0 rounded accent-relo-brand"
					{...input}
				/>
				<span>{label}</span>
			</label>
			{error ? <p className="text-xs text-relo-danger">{error}</p> : null}
		</div>
	);
}

export function ReceiptForm({ claim }: { claim: ClaimView }) {
	const proofSelectId = useId();
	const { showToast } = useToast();
	const { t, locale } = useI18n();
	const refund = t.detail.settlement;
	const s = kindWords(t, claim.kind)?.settlement ?? refund;
	const recordReceiptMutation = useRecordReceiptMutation(claim.id);

	const isRefund = claim.kind === "refund";
	const needsAgreed = isRefund && claim.agreed === null;
	/** Replacement items still to come. */
	const left = Math.max(0, claim.summary.requestedQty - claim.summary.goods);

	const form = useForm<ReceiptFormValues>({
		resolver: zodV4Resolver(receiptFormSchema),
		defaultValues: {
			kind: RECEIPT_KIND[claim.kind],
			proofId: claim.files[0]?.id ?? "",
			receivedOn: todayLocalIso(),
			amount:
				claim.agreed !== null
					? minorToDecimalString(
							Math.max(0, claim.agreed - claim.summary.cash),
							claim.currency,
						)
					: "",
			quantity: Math.max(1, left),
			transactionRef: "",
			note: "",
			confirmed: false,
			missingReferenceConfirmed: false,
		},
	});
	const { errors } = form.formState;
	// A statement line with no number: ask where it was checked instead.
	const noRef = isRefund && !(form.watch("transactionRef") ?? "").trim();

	const onSubmit = form.handleSubmit(async (data) => {
		// The form rules already checked everything except how many items are still to come.
		const withoutRef = isRefund && !data.transactionRef;
		const quantity = data.quantity ?? 0;
		if (claim.kind === "exchange" && quantity > left) {
			form.setError("quantity", { message: "quantityInvalid" });
			return;
		}

		try {
			await recordReceiptMutation.mutateAsync({
				version: claim.version,
				input: {
					kind: data.kind,
					proofId: data.proofId,
					receivedOn: data.receivedOn,
					amount: isRefund ? data.amount : undefined,
					quantity: claim.kind === "exchange" ? quantity : undefined,
					transactionRef: data.transactionRef || undefined,
					note: data.note || undefined,
					confirmed: data.confirmed,
					// One check on the screen answers both of the server's questions.
					...(withoutRef
						? { missingReferenceConfirmed: true, duplicateReviewed: true }
						: {}),
				},
			});
			void confetti({ particleCount: 95, spread: 80, origin: { y: 0.6 } });
			showToast(s.toastDone);
		} catch (error) {
			showToast(errorText(error, s.toastFail, locale), "error");
		}
	});

	return (
		<form onSubmit={onSubmit} className="space-y-4">
			{needsAgreed ? (
				<p className="text-xs font-semibold text-relo-sunny-ink">
					{refund.needAgreed}
				</p>
			) : null}

			<div className="grid gap-4 sm:grid-cols-2">
				<div className="space-y-1.5">
					<label
						htmlFor={proofSelectId}
						className="block text-sm font-semibold text-relo-ink"
					>
						{s.proofLabel}
					</label>
					<select
						id={proofSelectId}
						className="min-h-12 w-full rounded-xl border border-relo-line-strong bg-white px-3 text-sm text-relo-ink"
						{...form.register("proofId")}
					>
						<option value="">{refund.proofPlaceholder}</option>
						{claim.files.map((f) => (
							<option key={f.id} value={f.id}>
								{f.name}
							</option>
						))}
					</select>
					{errors.proofId ? (
						<p className="text-xs text-relo-danger">
							{fieldError(t, errors.proofId.message)}
						</p>
					) : null}
				</div>

				<TextField
					label={s.dateLabel}
					type="date"
					max={todayLocalIso()}
					error={fieldError(t, errors.receivedOn?.message)}
					{...form.register("receivedOn")}
				/>
			</div>

			{isRefund ? (
				<div className="grid gap-4 sm:grid-cols-2">
					<TextField
						label={fill(refund.amountLabel, { cur: claim.currency })}
						placeholder={refund.amountPlaceholder}
						error={fieldError(t, errors.amount?.message)}
						{...form.register("amount")}
					/>
					<TextField
						label={refund.refLabel}
						placeholder={refund.refPlaceholder}
						hint={refund.refHint}
						error={fieldError(t, errors.transactionRef?.message)}
						{...form.register("transactionRef")}
					/>
				</div>
			) : null}

			{noRef ? (
				<div className="space-y-3 rounded-2xl bg-relo-sunken p-4">
					<TextField
						label={t.kinds.noRef.noteLabel}
						placeholder={t.kinds.noRef.notePlaceholder}
						error={fieldError(t, errors.note?.message)}
						{...form.register("note")}
					/>
					<CheckLine
						label={t.kinds.noRef.confirm}
						error={fieldError(t, errors.missingReferenceConfirmed?.message)}
						input={form.register("missingReferenceConfirmed")}
					/>
				</div>
			) : null}

			{claim.kind === "exchange" ? (
				<div className="sm:max-w-[calc(50%-0.5rem)]">
					<TextField
						label={fill(t.kinds.receipt.quantityLabel, { n: left })}
						type="number"
						min={1}
						max={left}
						error={
							errors.quantity ? fieldError(t, "quantityInvalid") : undefined
						}
						{...form.register("quantity", { valueAsNumber: true })}
					/>
				</div>
			) : null}

			<CheckLine
				label={s.confirmLabel}
				error={fieldError(t, errors.confirmed?.message)}
				input={form.register("confirmed")}
			/>

			<Button
				type="submit"
				variant="primary"
				size="lg"
				disabled={claim.files.length === 0 || needsAgreed}
				isLoading={recordReceiptMutation.isPending}
			>
				<PartyPopper className="h-5 w-5" aria-hidden="true" />
				<span>{s.submit}</span>
			</Button>
		</form>
	);
}
