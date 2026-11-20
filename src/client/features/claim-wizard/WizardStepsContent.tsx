/**
 * @module client/features/claim-wizard/WizardStepsContent
 * @layer View (5-Step Refund Form Step Panels)
 * @purpose Pure consumer-facing form views for Steps 1 through 5 of the 3-minute refund wizard.
 */

import { Languages, ShieldCheck } from "lucide-react";
import { useId } from "react";
import type { UseFormReturn } from "react-hook-form";
import {
	type StagedEvidenceItem,
	UppyEvidenceUploader,
} from "@/client/components/media/UppyEvidenceUploader";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Button, TextField } from "@/client/components/ui/Primitives";
import type { WizardIntakeResult } from "@/client/features/claim-wizard/intake-fill";
import { WizardAgentIntake } from "@/client/features/claim-wizard/WizardAgentIntake";
import { useI18n } from "@/client/i18n";
import { fieldError } from "@/client/lib/claim-words";
import { CURRENCY_SYMBOLS, fill } from "@/client/lib/format";
import type { ClaimWizardFormValues, CurrencyCode } from "@/client/types";

const QUICK_MALL_OPTIONS: ReadonlyArray<{
	name: string;
	currency: CurrencyCode;
}> = [
	{ name: "Amazon US", currency: "USD" },
	{ name: "AliExpress", currency: "USD" },
	{ name: "Taobao · Tmall", currency: "CNY" },
	{ name: "Mercari · Amazon JP", currency: "JPY" },
	{ name: "iHerb", currency: "USD" },
	{ name: "Farfetch · SSENSE", currency: "EUR" },
];

const KIND_ORDER = ["refund", "exchange", "repair"] as const;

const CURRENCY_ORDER = [
	"USD",
	"KRW",
	"JPY",
	"CNY",
	"EUR",
	"GBP",
	"CAD",
	"AUD",
] as const;

interface WizardStepsContentProps {
	step: number;
	form: UseFormReturn<ClaimWizardFormValues>;
	todayIso: string;
	isTranslating: boolean;
	/** The English text came from the AI, so it is marked as the AI's. */
	englishByAi: boolean;
	/** The AI filled the form from the order and the person's line: the wizard keeps saying so. */
	filledByAi: boolean;
	/** How the AI said it read the person's line. */
	understood: string | null;
	stagedFilesCount: number;
	extraScannedCount: number;
	onIntakeFilled: (result: WizardIntakeResult) => Promise<number>;
	onTranslateIssue: () => void;
	onStagedFilesChange: (items: StagedEvidenceItem[]) => void;
}

export function WizardStepsContent({
	step,
	form,
	todayIso,
	isTranslating,
	englishByAi,
	filledByAi,
	understood,
	stagedFilesCount,
	extraScannedCount,
	onIntakeFilled,
	onTranslateIssue,
	onStagedFilesChange,
}: WizardStepsContentProps) {
	const currencySelectId = useId();
	const issueTextareaId = useId();
	const issueEnTextareaId = useId();
	const { t } = useI18n();
	const w = t.wizard;

	const values = form.watch();
	const errors = form.formState.errors;

	if (step === 1) {
		return (
			<>
				<WizardAgentIntake
					onFilled={onIntakeFilled}
					filledByAi={filledByAi}
					understood={understood}
					initialLine={understood ? values.issue : ""}
				/>

				<div className="space-y-2">
					<p className="text-xs font-bold text-relo-muted">{w.quickMalls}</p>
					<div className="flex flex-wrap gap-1.5">
						{QUICK_MALL_OPTIONS.map((mall) => (
							<button
								key={mall.name}
								type="button"
								onClick={() => {
									form.setValue("vendor", mall.name, { shouldValidate: true });
									form.setValue("currency", mall.currency);
								}}
								aria-pressed={values.vendor === mall.name}
								className={`inline-flex cursor-pointer items-center rounded-xl border px-3 py-1.5 text-xs font-bold transition max-sm:min-h-10 ${
									values.vendor === mall.name
										? "border-relo-brand bg-relo-brand-soft text-relo-brand"
										: "border-relo-line bg-relo-sunken text-relo-body hover:bg-white"
								}`}
							>
								{mall.name}
							</button>
						))}
					</div>
				</div>

				<TextField
					label={w.vendorLabel}
					placeholder={w.vendorPlaceholder}
					error={fieldError(t, errors.vendor?.message)}
					{...form.register("vendor")}
				/>

				<div className="grid gap-4 sm:grid-cols-2">
					<TextField
						label={w.orderRefLabel}
						placeholder={w.orderRefPlaceholder}
						error={fieldError(t, errors.orderRef?.message)}
						{...form.register("orderRef")}
					/>
					<TextField
						label={w.orderedOnLabel}
						type="date"
						max={todayIso}
						error={fieldError(t, errors.orderedOn?.message)}
						{...form.register("orderedOn")}
					/>
				</div>
			</>
		);
	}

	if (step === 2) {
		return (
			<>
				<TextField
					label={w.titleLabel}
					placeholder={w.titlePlaceholder}
					error={fieldError(t, errors.title?.message)}
					{...form.register("title")}
				/>

				<div className="grid grid-cols-2 gap-4">
					<TextField
						label={w.orderedQtyLabel}
						type="number"
						min={1}
						error={fieldError(t, errors.orderedQty?.message)}
						{...form.register("orderedQty", { valueAsNumber: true })}
					/>
					<TextField
						label={w.claimQtyLabel}
						type="number"
						min={1}
						error={fieldError(t, errors.claimQty?.message)}
						{...form.register("claimQty", { valueAsNumber: true })}
					/>
				</div>

				<div className="grid gap-4 sm:grid-cols-12">
					<div className="space-y-1.5 sm:col-span-5">
						<label
							htmlFor={currencySelectId}
							className="block text-sm font-semibold text-relo-ink"
						>
							{w.currencyLabel}
						</label>
						<select
							id={currencySelectId}
							className="min-h-12 w-full rounded-xl border border-relo-line-strong bg-white px-3.5 py-2.5 text-[15px] font-semibold text-relo-ink"
							{...form.register("currency")}
						>
							{CURRENCY_ORDER.map((code) => (
								<option key={code} value={code}>
									{code} ({CURRENCY_SYMBOLS[code]}) {w.currencies[code]}
								</option>
							))}
						</select>
					</div>

					<div className="sm:col-span-7">
						<TextField
							label={w.amountLabel}
							placeholder={
								values.currency === "KRW" || values.currency === "JPY"
									? w.amountPlaceholderWhole
									: w.amountPlaceholderDecimal
							}
							hint={w.amountHint}
							error={fieldError(t, errors.claimedAmount?.message)}
							{...form.register("claimedAmount")}
						/>
					</div>
				</div>
			</>
		);
	}

	if (step === 3) {
		return (
			<>
				<div className="space-y-2">
					<p className="text-sm font-semibold text-relo-ink">{w.kindPrompt}</p>
					<div className="grid grid-cols-3 gap-2.5">
						{KIND_ORDER.map((kind) => ({
							value: kind,
							label: t.shared.kinds[kind],
							desc: w.kindDescs[kind],
						})).map((opt) => (
							<button
								key={opt.value}
								type="button"
								aria-pressed={values.kind === opt.value}
								onClick={() => form.setValue("kind", opt.value)}
								className={`cursor-pointer rounded-2xl border-2 p-3 text-left transition ${
									values.kind === opt.value
										? "border-relo-brand bg-relo-brand-soft/60"
										: "border-relo-line bg-white hover:bg-relo-sunken"
								}`}
							>
								<p className="text-sm font-extrabold text-relo-ink">
									{opt.label}
								</p>
								<p className="mt-0.5 text-xs text-relo-muted">{opt.desc}</p>
							</button>
						))}
					</div>
				</div>

				<div className="space-y-2">
					<label
						htmlFor={issueTextareaId}
						className="text-sm font-semibold text-relo-ink"
					>
						{w.issueLabel}
					</label>
					<div className="flex flex-wrap gap-1.5">
						{w.issueChips.map((chip) => (
							<button
								key={chip.label}
								type="button"
								onClick={() =>
									form.setValue("issue", chip.text, { shouldValidate: true })
								}
								className="inline-flex cursor-pointer items-center rounded-full border border-relo-line bg-relo-sunken px-3 py-1 text-xs font-semibold text-relo-body hover:border-relo-brand max-sm:min-h-10"
							>
								+ {chip.label}
							</button>
						))}
					</div>
					<textarea
						id={issueTextareaId}
						rows={4}
						placeholder={w.issuePlaceholder}
						className="w-full rounded-xl border border-relo-line-strong bg-white p-3.5 text-sm text-relo-ink focus:border-relo-brand"
						{...form.register("issue")}
					/>
					{errors.issue ? (
						<p className="text-xs font-medium text-relo-danger">
							{fieldError(t, errors.issue.message)}
						</p>
					) : null}
				</div>

				<div className="space-y-2 rounded-2xl border border-relo-brand-line bg-relo-brand-soft/45 p-4">
					<div className="flex flex-wrap items-center justify-between gap-2">
						<label
							htmlFor={issueEnTextareaId}
							className="text-xs font-extrabold text-relo-brand"
						>
							{w.englishLabel}
						</label>
						<Button
							variant="ghost"
							size="sm"
							isLoading={isTranslating}
							onClick={onTranslateIssue}
							className="border border-relo-brand-line bg-white text-relo-brand hover:bg-relo-brand-soft max-sm:min-h-11"
						>
							<Languages className="h-3.5 w-3.5" aria-hidden="true" />
							<span>{w.englishButton}</span>
						</Button>
					</div>
					{isTranslating ? (
						<ReloOrbEmblem
							variant="processing"
							size="sm"
							speech={w.translating}
						/>
					) : (
						<textarea
							id={issueEnTextareaId}
							rows={2}
							placeholder={w.englishPlaceholder}
							className="w-full rounded-xl border border-relo-line bg-white p-3 text-xs text-relo-ink"
							{...form.register("issueEnglish")}
						/>
					)}
					{englishByAi && !isTranslating && values.issueEnglish ? (
						<p className="text-xs text-relo-muted">{w.englishAiNote}</p>
					) : null}
				</div>
			</>
		);
	}

	if (step === 4) {
		return (
			<div className="space-y-4">
				<UppyEvidenceUploader onFilesChange={onStagedFilesChange} />
				{extraScannedCount > 0 ? (
					<p className="rounded-xl bg-relo-brand-soft px-3.5 py-2 text-xs font-bold text-relo-brand">
						{fill(w.scannedAlso, { n: extraScannedCount })}
					</p>
				) : null}
			</div>
		);
	}

	return (
		<div className="space-y-4">
			<div className="space-y-3 rounded-2xl border border-relo-line bg-relo-sunken p-4 text-sm">
				<div className="flex justify-between border-b border-relo-line pb-2.5">
					<span className="text-relo-muted">{w.sumShop}</span>
					<span className="font-bold text-relo-ink">
						{values.vendor} · {values.orderRef}
					</span>
				</div>
				<div className="flex justify-between border-b border-relo-line pb-2.5">
					<span className="text-relo-muted">{w.sumItem}</span>
					<span className="font-bold text-relo-ink">
						{fill(w.sumItemValue, { title: values.title, n: values.claimQty })}
					</span>
				</div>
				<div className="flex justify-between border-b border-relo-line pb-2.5">
					<span className="text-relo-muted">{w.sumKind}</span>
					<span className="font-extrabold text-relo-brand tabular-nums">
						{t.shared.kinds[values.kind]} · {values.currency}{" "}
						{values.claimedAmount}
					</span>
				</div>
				<div className="flex justify-between border-b border-relo-line pb-2.5">
					<span className="text-relo-muted">{w.sumFiles}</span>
					<span className="font-bold text-relo-ink">
						{fill(w.sumFilesValue, { n: stagedFilesCount + extraScannedCount })}
					</span>
				</div>
				{/* The words that go to the shop are checked here too, not only the numbers. */}
				<div className="space-y-1">
					<span className="text-relo-muted">{w.sumIssue}</span>
					<p className="whitespace-pre-wrap font-bold text-relo-ink">
						{values.issue}
					</p>
					{values.issueEnglish ? (
						<p className="whitespace-pre-wrap text-xs text-relo-muted">
							{values.issueEnglish}
						</p>
					) : null}
				</div>
			</div>

			{filledByAi ? (
				<p
					className="text-xs leading-relaxed text-relo-muted"
					data-testid="intake-review-note"
				>
					{w.intake.reviewNote}
				</p>
			) : null}

			<div className="flex items-start gap-2.5 rounded-2xl bg-relo-brand-soft/60 p-3.5 text-xs text-relo-body">
				<ShieldCheck
					className="mt-0.5 h-4 w-4 shrink-0 text-relo-brand"
					aria-hidden="true"
				/>
				<span>{w.confirmNote}</span>
			</div>
		</div>
	);
}
