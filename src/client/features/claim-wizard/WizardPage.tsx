/**
 * @module client/features/claim-wizard/WizardPage
 * @layer ViewModel & Page Container (5-Step Consumer Refund Wizard)
 * @purpose Coordinates react-hook-form validation, receipt auto-fill, translation,
 *          and multi-file attachment submission across the 5-step consumer wizard.
 */

import confetti from "canvas-confetti";
import { ArrowLeft, ArrowRight, Sparkles } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useMemo, useState } from "react";
import { useForm } from "react-hook-form";
import type { StagedEvidenceItem } from "@/client/components/media/UppyEvidenceUploader";
import { Button, Card, useToast } from "@/client/components/ui/Primitives";
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
	useAiConsentMutation,
	useAppConfig,
	useLoginMutation,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { filesApi } from "@/client/lib/api-client";
import { useCalmPreparation } from "@/client/lib/preparation";
import { useRouter } from "@/client/lib/router";
import { zodV4Resolver } from "@/client/lib/zod-resolver";
import {
	type AiExtractionResponse,
	type ClaimKind,
	type ClaimView,
	type ClaimWizardFormValues,
	type CurrencyCode,
	claimWizardSchema,
} from "@/client/types";

const STEP_TITLES = [
	{ step: 1, title: "어디서 주문하셨나요?", sub: "쇼핑몰 · 주문번호" },
	{ step: 2, title: "어떤 상품인가요?", sub: "상품 이름 · 결제 금액" },
	{ step: 3, title: "어떻게 해결해 드릴까요?", sub: "환불 방법 · 문제 설명" },
	{
		step: 4,
		title: "영수증이나 불량 사진이 있나요?",
		sub: "사진 자르기 · 10MB 안전 보관",
	},
	{ step: 5, title: "마지막으로 확인해 볼까요?", sub: "내용 확인 · 등록 완료" },
] as const;

function todayIsoDate(): string {
	return new Date().toISOString().slice(0, 10);
}

export function WizardPage() {
	const { search, navigate } = useRouter();
	const { t } = useI18n();
	const { data: session, isLoading: sessionLoading } = useSession();
	const { data: config } = useAppConfig();
	const loginMutation = useLoginMutation();
	const aiConsentMutation = useAiConsentMutation();
	const createClaimMutation = useCreateClaimMutation();
	const translateMutation = useAiTranslateIssueMutation();
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();

	const [step, setStep] = useState(1);
	const [stagedFiles, setStagedFiles] = useState<StagedEvidenceItem[]>([]);
	const [extraScannedFiles, setExtraScannedFiles] = useState<File[]>([]);
	const [createdClaim, setCreatedClaim] = useState<ClaimView | null>(null);
	const [isSubmittingAll, setIsSubmittingAll] = useState(false);

	const queryDefaults = useMemo(() => {
		const params = new URLSearchParams(search);
		const rawCurr = params.get("currency") as CurrencyCode | null;
		const rawKind = params.get("kind") as ClaimKind | null;
		return {
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
			orderedOn: todayIsoDate(),
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
		if (queryDefaults.vendor) form.setValue("vendor", queryDefaults.vendor);
		if (queryDefaults.currency)
			form.setValue("currency", queryDefaults.currency);
		if (queryDefaults.claimedAmount)
			form.setValue("claimedAmount", queryDefaults.claimedAmount);
		if (queryDefaults.kind) form.setValue("kind", queryDefaults.kind);
		if (queryDefaults.issue) form.setValue("issue", queryDefaults.issue);
	}, [queryDefaults, form]);

	const values = form.watch();

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
			showToast("체험 계정으로 바로 연결되었어요! 이어서 작성해 보세요.");
		} catch {
			navigate("/auth");
		}
	};

	const handleInvoiceExtracted = (
		res: AiExtractionResponse,
		scannedFile: File,
	) => {
		const { suggestion, orderTotal } = res;
		if (suggestion.vendor) form.setValue("vendor", suggestion.vendor);
		if (suggestion.orderRef) form.setValue("orderRef", suggestion.orderRef);
		if (suggestion.orderedOn) form.setValue("orderedOn", suggestion.orderedOn);
		if (suggestion.currency) form.setValue("currency", suggestion.currency);
		if (suggestion.items[0]) {
			form.setValue("title", suggestion.items[0].name);
			form.setValue("orderedQty", suggestion.items[0].orderedQty);
			form.setValue("claimQty", suggestion.items[0].claimQty);
			if (suggestion.items[0].unitPrice) {
				form.setValue("claimedAmount", suggestion.items[0].unitPrice);
			}
		} else if (orderTotal) {
			form.setValue("claimedAmount", orderTotal);
		}
		setExtraScannedFiles((prev) => [...prev, scannedFile]);
	};

	const handleTranslateIssue = async () => {
		const issueText = form.getValues("issue").trim();
		if (issueText.length < 5) {
			showToast("먼저 우리말 문제 설명을 5자 이상 적어 주세요!", "error");
			return;
		}
		try {
			if (!session?.user?.aiConsentAt) {
				await aiConsentMutation.mutateAsync(true);
			}
			const res = await runCalmly(() =>
				translateMutation.mutateAsync(issueText),
			);
			if (res) {
				form.setValue("issueEnglish", res.english);
				showToast("쇼핑몰에 보낼 자연스러운 영어로 번역했어요!");
			}
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "영어 변환 중 오류가 발생했어요.",
				"error",
			);
		}
	};

	const goNextStep = async () => {
		let fieldsToValidate: Array<keyof ClaimWizardFormValues> = [];
		if (step === 1) fieldsToValidate = ["vendor", "orderRef", "orderedOn"];
		if (step === 2) {
			fieldsToValidate = [
				"title",
				"orderedQty",
				"claimQty",
				"currency",
				"claimedAmount",
			];
		}
		if (step === 3) fieldsToValidate = ["kind", "issue"];

		if (fieldsToValidate.length > 0) {
			const ok = await form.trigger(fieldsToValidate);
			if (!ok) return;
		}
		if (step === 2 && values.claimQty > values.orderedQty) {
			form.setError("claimQty", {
				message: "문제가 생긴 수량은 전체 주문 수량보다 많을 수 없어요.",
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
			showToast("환불 신청서와 사진 파일이 안전하게 저장되었어요!");
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "신청서 저장 중 문제가 발생했어요.",
				"error",
			);
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

	const currentStepMeta = STEP_TITLES[step - 1] ?? STEP_TITLES[0];

	return (
		<div className="bg-relo-canvas py-8 sm:py-14">
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
										todayIso={todayIsoDate()}
										isTranslating={isPreparing || translateMutation.isPending}
										stagedFilesCount={stagedFiles.length}
										extraScannedCount={extraScannedFiles.length}
										claimKinds={config?.claimKinds}
										onInvoiceExtracted={handleInvoiceExtracted}
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
