/**
 * @module client/features/claim-wizard/WizardPage
 * @layer ViewModel & Page Container (5-Step Consumer Refund Wizard)
 * @purpose Coordinates react-hook-form validation, receipt auto-fill, translation,
 *          and multi-file attachment submission across the 5-step consumer wizard.
 *          What is being written is kept in this browser and brought back after a reload.
 */

import confetti from "canvas-confetti";
import { ArrowLeft, ArrowRight, Sparkles } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import { useAiConsentGate } from "@/client/components/AiConsentDialog";
import type { StagedEvidenceItem } from "@/client/components/media/UppyEvidenceUploader";
import { Button, Card, useToast } from "@/client/components/ui/Primitives";
import {
	applyIntake,
	STEP_FIELDS,
	type WizardIntakeResult,
} from "@/client/features/claim-wizard/intake-fill";
import { useWizardDraft } from "@/client/features/claim-wizard/useWizardDraft";
import {
	WizardGuestGate,
	WizardSuccessScreen,
} from "@/client/features/claim-wizard/WizardStatusScreens";
import { WizardStepsContent } from "@/client/features/claim-wizard/WizardStepsContent";
import {
	useAiTranslateIssueMutation,
	useCreateClaimMutation,
} from "@/client/hooks/useClaims";
import {
	useAppConfig,
	useLoginMutation,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { filesApi } from "@/client/lib/api-client";
import { errorText } from "@/client/lib/claim-words";
import { fill, todayLocalIso } from "@/client/lib/format";
import { useCalmPreparation } from "@/client/lib/preparation";
import { useRouter } from "@/client/lib/router";
import { zodV4Resolver } from "@/client/lib/zod-resolver";
import {
	type ClaimKind,
	type ClaimView,
	type ClaimWizardFormValues,
	type CurrencyCode,
	claimWizardSchema,
} from "@/client/types";

export function WizardPage() {
	const { search, navigate } = useRouter();
	const { t, locale } = useI18n();
	const w = t.wizard;
	const { data: session, isLoading: sessionLoading } = useSession();
	const { data: config } = useAppConfig();
	const loginMutation = useLoginMutation();
	const { ensureConsent, consentDialog } = useAiConsentGate();
	const createClaimMutation = useCreateClaimMutation();
	const translateMutation = useAiTranslateIssueMutation();
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();

	const [step, setStep] = useState(1);
	const [stagedFiles, setStagedFiles] = useState<StagedEvidenceItem[]>([]);
	const [extraScannedFiles, setExtraScannedFiles] = useState<File[]>([]);
	const [createdClaim, setCreatedClaim] = useState<ClaimView | null>(null);
	const [isSubmittingAll, setIsSubmittingAll] = useState(false);
	const [englishByAi, setEnglishByAi] = useState(false);
	const [filledByAi, setFilledByAi] = useState(false);
	const [understood, setUnderstood] = useState<string | null>(null);

	const queryDefaults = useMemo(() => {
		const params = new URLSearchParams(search);
		const rawCurr = params.get("currency") as CurrencyCode | null;
		const rawKind = params.get("kind") as ClaimKind | null;
		return {
			// Opened with details already chosen (a shop picked on the first screen).
			hasPrefill: ["vendor", "currency", "amount", "kind", "issue"].some(
				(key) => params.has(key),
			),
			vendor: params.get("vendor") ?? "",
			currency:
				rawCurr &&
				["USD", "EUR", "GBP", "JPY", "CNY", "KRW", "CAD", "AUD"].includes(
					rawCurr,
				)
					? rawCurr
					: ("USD" as CurrencyCode),
			claimedAmount: params.get("amount") ?? "",
			kind:
				rawKind && ["refund", "exchange", "repair"].includes(rawKind)
					? rawKind
					: ("refund" as ClaimKind),
			issue: params.get("issue") ?? "",
		};
	}, [search]);

	const form = useForm<ClaimWizardFormValues>({
		resolver: zodV4Resolver(claimWizardSchema),
		defaultValues: {
			vendor: queryDefaults.vendor,
			vendorUrl: "",
			orderRef: "",
			orderedOn: todayLocalIso(),
			title: "",
			sku: "",
			orderedQty: 1,
			claimQty: 1,
			currency: queryDefaults.currency,
			claimedAmount: queryDefaults.claimedAmount,
			kind: queryDefaults.kind,
			issue: queryDefaults.issue,
			issueEnglish: "",
		},
		mode: "onTouched",
	});

	useEffect(() => {
		if (!queryDefaults.hasPrefill) return;
		if (queryDefaults.vendor) form.setValue("vendor", queryDefaults.vendor);
		if (queryDefaults.currency)
			form.setValue("currency", queryDefaults.currency);
		if (queryDefaults.claimedAmount)
			form.setValue("claimedAmount", queryDefaults.claimedAmount);
		if (queryDefaults.kind) form.setValue("kind", queryDefaults.kind);
		if (queryDefaults.issue) form.setValue("issue", queryDefaults.issue);
	}, [queryDefaults, form]);

	const values = form.watch();

	const attachedNames = [
		...extraScannedFiles.map((file) => file.name),
		...stagedFiles.map((item) => item.file.name),
	];
	const draft = useWizardDraft({
		userId: session?.user?.id,
		form,
		values,
		step,
		setStep,
		fileNames: attachedNames,
		startFresh: queryDefaults.hasPrefill,
	});

	const handleStartOver = () => {
		draft.forget();
		form.reset();
		setStep(1);
		setStagedFiles([]);
		setExtraScannedFiles([]);
		setFilledByAi(false);
		setUnderstood(null);
		showToast(w.toastDraftCleared);
	};

	const handleQuickDemoLogin = async () => {
		if (!config?.demoAccount) {
			navigate("/auth");
			return;
		}
		try {
			await loginMutation.mutateAsync({
				email: config.demoAccount.email,
				password: config.demoAccount.password,
			});
			showToast(w.toastDemo);
		} catch {
			navigate("/auth");
		}
	};

	// The AI read the order and the person's line: the form is filled and the wizard moves to
	// the first step that still has a gap, or straight to the review.
	const handleIntakeFilled = async (result: WizardIntakeResult) => {
		const { file, intake } = result;
		if (file) setExtraScannedFiles((prev) => [...prev, file]);
		const next = await applyIntake(form, result);
		setFilledByAi(true);
		setUnderstood(intake?.understood ?? null);
		if (intake) {
			setEnglishByAi(true);
			setStep(next);
		}
		return next;
	};

	const handleTranslateIssue = async () => {
		const issueText = form.getValues("issue").trim();
		if (issueText.length < 5) {
			showToast(w.toastNeedIssue, "error");
			return;
		}
		// What was typed is sent for translation only after the person has agreed.
		if (!(await ensureConsent())) return;
		try {
			const res = await runCalmly(() =>
				translateMutation.mutateAsync(issueText),
			);
			if (res) {
				form.setValue("issueEnglish", res.english);
				setEnglishByAi(true);
				showToast(w.toastTranslated);
			}
		} catch (error) {
			showToast(errorText(error, w.toastTranslateFail, locale), "error");
		}
	};

	const goNextStep = async () => {
		const fieldsToValidate = STEP_FIELDS[step - 1] ?? [];
		if (fieldsToValidate.length > 0) {
			const ok = await form.trigger([...fieldsToValidate]);
			if (!ok) return;
		}
		if (step === 2 && values.claimQty > values.orderedQty) {
			form.setError("claimQty", {
				message: "claimQtyOver",
			});
			return;
		}
		setStep((s) => Math.min(5, s + 1));
	};

	const onSubmitWizard = form.handleSubmit(async (data) => {
		setIsSubmittingAll(true);
		try {
			const qty = Math.max(1, data.claimQty);
			const digits =
				config?.currencies[data.currency]?.digits ??
				(data.currency === "KRW" || data.currency === "JPY" ? 0 : 2);
			const totalNum = Number(data.claimedAmount);
			const unitNum = qty === 1 ? totalNum : totalNum / qty;
			const unitPriceStr =
				digits === 0 ? String(Math.round(unitNum)) : unitNum.toFixed(digits);

			const { claim: initialClaim } = await createClaimMutation.mutateAsync({
				title: data.title,
				vendor: data.vendor,
				vendorUrl: data.vendorUrl || "",
				orderRef: data.orderRef,
				orderedOn: data.orderedOn,
				kind: data.kind,
				currency: data.currency,
				claimedAmount: data.claimedAmount,
				issue: data.issue,
				issueEnglish: data.issueEnglish || "",
				items: [
					{
						name: data.title,
						sku: data.sku || "",
						orderedQty: data.orderedQty,
						claimQty: data.claimQty,
						unitPrice: unitPriceStr,
					},
				],
			});

			// The request now exists on the server; a reload must not offer to send it again.
			draft.finish();
			let latestClaim = initialClaim;
			const allFilesToUpload: File[] = [
				...extraScannedFiles,
				...stagedFiles.map((item) => item.file),
			];

			for (const file of allFilesToUpload) {
				const uploaded = await filesApi.upload(
					latestClaim.id,
					latestClaim.version,
					file,
					file.name,
				);
				latestClaim = uploaded.claim;
			}

			setCreatedClaim(latestClaim);
			void confetti({
				particleCount: 85,
				spread: 75,
				origin: { y: 0.55 },
			});
			showToast(w.toastSaved);
		} catch (error) {
			showToast(errorText(error, w.toastSaveFail, locale), "error");
		} finally {
			setIsSubmittingAll(false);
		}
	});

	if (!sessionLoading && !session?.user) {
		return (
			<WizardGuestGate
				demoAccountName={config?.demoAccount?.name}
				isLoggingIn={loginMutation.isPending}
				onDemoLogin={handleQuickDemoLogin}
				onNavigateAuth={() => navigate("/auth")}
			/>
		);
	}

	if (createdClaim) {
		return (
			<WizardSuccessScreen
				claim={createdClaim}
				onOpenDetail={() => navigate(`/claims/${createdClaim.id}`)}
				onOpenList={() => navigate("/claims")}
			/>
		);
	}

	const currentStepMeta = w.steps[step - 1] ?? w.steps[0];
	const mustReattach =
		!!draft.restored &&
		draft.restored.fileCount > 0 &&
		attachedNames.length === 0;
	const showDraftNotice =
		!!draft.restored &&
		(step === draft.restored.step || (step === 4 && mustReattach));

	return (
		<div className="bg-relo-canvas py-8 sm:py-14">
			{consentDialog}
			<div className="mx-auto max-w-2xl px-4 sm:px-6">
				<form onSubmit={onSubmitWizard}>
					<Card className="overflow-hidden p-0">
						<div className="h-1 w-full bg-relo-sunken">
							<motion.div
								initial={false}
								animate={{ width: `${(step / 5) * 100}%` }}
								transition={{ type: "spring", stiffness: 280, damping: 30 }}
								className="h-full bg-relo-brand"
							/>
						</div>

						<div className="p-6 sm:p-9">
							{showDraftNotice && draft.restored ? (
								<div
									role="status"
									className="mb-6 flex flex-wrap items-center justify-between gap-x-3 rounded-xl bg-relo-sunken px-3.5 py-1 text-xs text-relo-muted"
								>
									<span className="py-1.5">
										{w.draftRestored}
										{mustReattach
											? ` ${fill(w.draftFiles, { n: draft.restored.fileCount })}`
											: ""}
									</span>
									<button
										type="button"
										onClick={handleStartOver}
										className="inline-flex min-h-11 shrink-0 cursor-pointer items-center font-semibold text-relo-brand hover:underline"
									>
										{w.draftStartOver}
									</button>
								</div>
							) : null}
							<div className="mb-7 space-y-2">
								<div className="flex items-center justify-between text-xs font-semibold text-relo-muted">
									<span className="text-relo-brand">
										{t.pages.wizardTitle} · {currentStepMeta.sub}
									</span>
									<span className="tabular-nums">{step} / 5</span>
								</div>
								<h1 className="text-2xl leading-[1.24] font-bold tracking-[-0.035em] text-relo-ink sm:text-[30px]">
									{currentStepMeta.title}
								</h1>
							</div>

							<AnimatePresence mode="wait">
								<motion.div
									key={step}
									initial={{ opacity: 0, x: 14 }}
									animate={{ opacity: 1, x: 0 }}
									exit={{ opacity: 0, x: -14 }}
									transition={{ duration: 0.2 }}
									className="space-y-5"
								>
									<WizardStepsContent
										step={step}
										form={form}
										todayIso={todayLocalIso()}
										isTranslating={isPreparing || translateMutation.isPending}
										englishByAi={englishByAi}
										filledByAi={filledByAi}
										understood={understood}
										stagedFilesCount={stagedFiles.length}
										extraScannedCount={extraScannedFiles.length}
										onIntakeFilled={handleIntakeFilled}
										onTranslateIssue={handleTranslateIssue}
										onStagedFilesChange={setStagedFiles}
									/>
								</motion.div>
							</AnimatePresence>

							<div className="mt-7 flex items-center justify-between gap-3 border-t border-relo-line pt-5">
								{step > 1 ? (
									<Button
										variant="secondary"
										size="md"
										onClick={() => setStep((s) => Math.max(1, s - 1))}
									>
										<ArrowLeft className="h-4 w-4" aria-hidden="true" />
										<span>{t.pages.wizardPrev}</span>
									</Button>
								) : (
									<span />
								)}

								{step < 5 ? (
									<Button
										key="wizard-step-next"
										type="button"
										variant="primary"
										size="lg"
										onClick={goNextStep}
									>
										<span>{t.pages.wizardNext}</span>
										<ArrowRight className="h-4 w-4" aria-hidden="true" />
									</Button>
								) : (
									<Button
										key="wizard-step-submit"
										type="submit"
										variant="primary"
										size="lg"
										isLoading={isSubmittingAll}
									>
										<Sparkles className="h-5 w-5" aria-hidden="true" />
										<span>{t.pages.wizardSubmit}</span>
									</Button>
								)}
							</div>
						</div>
					</Card>
				</form>
			</div>
		</div>
	);
}
