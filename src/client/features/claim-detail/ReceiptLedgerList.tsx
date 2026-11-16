/**
 * @module client/features/claim-detail/ReceiptLedgerList
 * @layer View (What Was Recorded As Received, And Taking A Line Back)
 * @purpose Lists each record of money, replacement items or a repair that actually came in.
 *          A wrong line is never edited: it is undone with a reason, stays in the list
 *          crossed out, and stops counting.
 */

import { CheckCircle2 } from "lucide-react";
import { useId, useState } from "react";
import { Button, useToast } from "@/client/components/ui/Primitives";
import { useRecordReceiptMutation } from "@/client/hooks/useClaims";
import { useI18n } from "@/client/i18n";
import { isLocked, receivedRows } from "@/client/lib/claim-progress";
import { errorText, fieldError } from "@/client/lib/claim-words";
import { fill, formatMinorMoney, todayLocalIso } from "@/client/lib/format";
import type { ClaimView, LedgerEntry } from "@/client/types";

export function ReceiptLedgerList({
	claim,
	title,
}: {
	claim: ClaimView;
	/** The heading with {n} for how many records still count. */
	title: string;
}) {
	const reasonId = useId();
	const { t, locale } = useI18n();
	const l = t.kinds.ledger;
	const { showToast } = useToast();
	const recordReceiptMutation = useRecordReceiptMutation(claim.id);
	const [undoId, setUndoId] = useState<string | null>(null);
	const [reason, setReason] = useState("");
	const [reasonError, setReasonError] = useState(false);

	const rows = receivedRows(claim);
	if (rows.length === 0) return null;
	const canUndo = !isLocked(claim);

	const amountText = (entry: LedgerEntry) => {
		if (entry.kind === "goods") return fill(l.goods, { n: entry.quantity });
		if (entry.kind === "repair") return l.repair;
		return formatMinorMoney(entry.amount, claim.currency);
	};

	const startUndo = (id: string | null) => {
		setUndoId(id);
		setReason("");
		setReasonError(false);
	};

	const handleUndo = async (entry: LedgerEntry) => {
		if (reason.trim().length < 3) {
			setReasonError(true);
			return;
		}
		try {
			await recordReceiptMutation.mutateAsync({
				version: claim.version,
				input: {
					kind: "reversal",
					reverses: entry.id,
					proofId: entry.proofId ?? claim.files[0]?.id ?? "",
					receivedOn: todayLocalIso(),
					note: reason.trim(),
					confirmed: true,
				},
			});
			startUndo(null);
			showToast(l.toastUndone);
		} catch (error) {
			showToast(errorText(error, l.toastUndoFail, locale), "error");
		}
	};

	return (
		<div className="space-y-2 border-t border-relo-line pt-4">
			<p className="text-xs font-extrabold text-relo-muted">
				{fill(title, { n: rows.filter((row) => !row.undone).length })}
			</p>
			<ul className="space-y-2">
				{rows.map(({ entry, undone }) => (
					<li
						key={entry.id}
						className={`rounded-xl px-3.5 py-2.5 text-xs ${
							undone ? "bg-relo-sunken" : "bg-relo-brand-soft/65"
						}`}
					>
						<div className="flex flex-wrap items-center justify-between gap-x-3 gap-y-1">
							<span
								className={`inline-flex items-center gap-1.5 font-bold ${
									undone ? "text-relo-muted" : "text-relo-brand"
								}`}
							>
								{undone ? null : (
									<CheckCircle2 className="h-4 w-4" aria-hidden="true" />
								)}
								<span>
									{entry.receivedOn}
									{entry.transactionRef ? ` · ${entry.transactionRef}` : ""}
									{undone ? ` · ${l.undone}` : ""}
								</span>
							</span>
							<span className="flex items-center gap-3">
								<span
									className={`font-extrabold tabular-nums ${
										undone ? "text-relo-muted line-through" : "text-relo-brand"
									}`}
								>
									{amountText(entry)}
								</span>
								{canUndo && !undone && undoId !== entry.id ? (
									<button
										type="button"
										onClick={() => startUndo(entry.id)}
										className="cursor-pointer font-semibold text-relo-muted underline-offset-2 hover:text-relo-ink hover:underline max-sm:min-h-11"
									>
										{l.undo}
									</button>
								) : null}
							</span>
						</div>

						{undoId === entry.id ? (
							<div className="mt-2.5 space-y-2 border-t border-relo-line pt-2.5">
								<label
									htmlFor={reasonId}
									className="block font-bold text-relo-muted"
								>
									{l.reasonLabel}
								</label>
								<input
									id={reasonId}
									type="text"
									value={reason}
									onChange={(e) => {
										setReason(e.target.value);
										setReasonError(false);
									}}
									placeholder={l.reasonPlaceholder}
									className="min-h-11 w-full rounded-xl border border-relo-line-strong bg-white px-3 text-sm text-relo-ink"
								/>
								{reasonError ? (
									<p className="text-relo-danger">
										{fieldError(t, "reasonTooShort")}
									</p>
								) : null}
								<div className="flex flex-wrap gap-2">
									<Button
										variant="secondary"
										size="sm"
										isLoading={recordReceiptMutation.isPending}
										onClick={() => void handleUndo(entry)}
										className="max-sm:min-h-11"
									>
										{l.confirmUndo}
									</Button>
									<Button
										variant="ghost"
										size="sm"
										disabled={recordReceiptMutation.isPending}
										onClick={() => startUndo(null)}
										className="text-relo-muted max-sm:min-h-11"
									>
										{l.cancel}
									</Button>
								</div>
							</div>
						) : null}
					</li>
				))}
			</ul>
		</div>
	);
}
