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
import { WizardInvoiceScanCard } from "@/client/features/claim-wizard/WizardInvoiceScanCard";
import type {
	AiExtractionResponse,
	ClaimKind,
	ClaimWizardFormValues,
	CurrencyCode,
} from "@/client/types";

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

const QUICK_ISSUE_CHIPS = [
	"택배 상자를 열었을 때 겉상자와 상품 외관이 깨진 상태로 도착했습니다.",
	"주문한 옵션과 다른 색상·모델의 상품이 잘못 배송되었습니다.",
	"전원을 연결해도 켜지지 않는 작동 불량 상품입니다.",
	"배송 완료로 표시되었지만 실제로 택배를 받지 못했습니다.",
] as const;

interface WizardStepsContentProps {
	step: number;
	form: UseFormReturn<ClaimWizardFormValues>;
	todayIso: string;
	isTranslating: boolean;
	stagedFilesCount: number;
	extraScannedCount: number;
	claimKinds?: Record<ClaimKind, string>;
	onInvoiceExtracted: (res: AiExtractionResponse, scannedFile: File) => void;
	onTranslateIssue: () => void;
	onStagedFilesChange: (items: StagedEvidenceItem[]) => void;
}

export function WizardStepsContent({
	step,
	form,
	todayIso,
	isTranslating,
	stagedFilesCount,
	extraScannedCount,
	claimKinds,
	onInvoiceExtracted,
	onTranslateIssue,
	onStagedFilesChange,
}: WizardStepsContentProps) {
	const currencySelectId = useId();
	const issueTextareaId = useId();
	const issueEnTextareaId = useId();

	const values = form.watch();
	const errors = form.formState.errors;

	if (step === 1) {
		return (
			<>
				<WizardInvoiceScanCard onExtracted={onInvoiceExtracted} />

				<div className="space-y-2">
					<p className="text-xs font-bold text-relo-muted">
						자주 찾는 해외 쇼핑몰 빠른 선택
					</p>
					<div className="flex flex-wrap gap-1.5">
						{QUICK_MALL_OPTIONS.map((mall) => (
							<button
								key={mall.name}
								type="button"
								onClick={() => {
									form.setValue("vendor", mall.name, { shouldValidate: true });
									form.setValue("currency", mall.currency);
								}}
								className={`cursor-pointer rounded-xl border px-3 py-1.5 text-xs font-bold transition ${
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
					label="구매한 쇼핑몰 이름"
					placeholder="예: Amazon US, AliExpress, Mercari"
					error={errors.vendor?.message}
					{...form.register("vendor")}
				/>

				<div className="grid gap-4 sm:grid-cols-2">
					<TextField
						label="주문번호"
						placeholder="예: 114-8920411-33012"
						error={errors.orderRef?.message}
						{...form.register("orderRef")}
					/>
					<TextField
						label="주문한 날짜"
						type="date"
						max={todayIso}
						error={errors.orderedOn?.message}
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
					label="문제가 생긴 상품 이름"
					placeholder="예: 무선 헤드폰 블랙"
					error={errors.title?.message}
					{...form.register("title")}
				/>

				<div className="grid grid-cols-2 gap-4">
					<TextField
						label="전체 주문 수량"
						type="number"
						min={1}
						error={errors.orderedQty?.message}
						{...form.register("orderedQty", { valueAsNumber: true })}
					/>
					<TextField
						label="문제가 생긴 수량"
						type="number"
						min={1}
						error={errors.claimQty?.message}
						{...form.register("claimQty", { valueAsNumber: true })}
					/>
				</div>

				<div className="grid gap-4 sm:grid-cols-12">
					<div className="space-y-1.5 sm:col-span-5">
						<label
							htmlFor={currencySelectId}
							className="block text-sm font-semibold text-relo-ink"
						>
							결제한 통화
						</label>
						<select
							id={currencySelectId}
							className="min-h-12 w-full rounded-xl border border-relo-line-strong bg-white px-3.5 py-2.5 text-[15px] font-semibold text-relo-ink"
							{...form.register("currency")}
						>
							<option value="USD">USD ($) 미국 달러</option>
							<option value="KRW">KRW (₩) 대한민국 원</option>
							<option value="JPY">JPY (¥) 일본 엔</option>
							<option value="CNY">CNY (¥) 중국 위안</option>
							<option value="EUR">EUR (€) 유로</option>
							<option value="GBP">GBP (£) 영국 파운드</option>
							<option value="CAD">CAD (CA$) 캐나다 달러</option>
							<option value="AUD">AUD (A$) 호주 달러</option>
						</select>
					</div>

					<div className="sm:col-span-7">
						<TextField
							label="돌려받을 금액"
							placeholder={
								values.currency === "KRW" || values.currency === "JPY"
									? "예: 65000"
									: "예: 129.99"
							}
							hint="통화 기호나 쉼표(,) 없이 숫자만 적어 주세요."
							error={errors.claimedAmount?.message}
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
					<p className="text-sm font-semibold text-relo-ink">
						원하시는 해결 방법을 골라 주세요
					</p>
					<div className="grid grid-cols-3 gap-2.5">
						{(
							[
								{
									value: "refund",
									label: "반품 · 환불",
									desc: "결제 금액 돌려받기",
								},
								{
									value: "exchange",
									label: "새 상품 교환",
									desc: "정상 상품 다시 받기",
								},
								{
									value: "repair",
									label: "무상 수리·부품",
									desc: "부품·수리 요청",
								},
							] as const
						).map((opt) => (
							<button
								key={opt.value}
								type="button"
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
								<p className="mt-0.5 text-[11px] text-relo-muted">{opt.desc}</p>
							</button>
						))}
					</div>
				</div>

				<div className="space-y-2">
					<label
						htmlFor={issueTextareaId}
						className="text-sm font-semibold text-relo-ink"
					>
						어떤 문제가 있었나요? (우리말로 편하게)
					</label>
					<div className="flex flex-wrap gap-1.5">
						{QUICK_ISSUE_CHIPS.map((chip) => (
							<button
								key={chip}
								type="button"
								onClick={() =>
									form.setValue("issue", chip, { shouldValidate: true })
								}
								className="cursor-pointer rounded-full border border-relo-line bg-relo-sunken px-2.5 py-1 text-[11px] font-semibold text-relo-body hover:border-relo-brand"
							>
								+ {chip.slice(0, 18)}...
							</button>
						))}
					</div>
					<textarea
						id={issueTextareaId}
						rows={4}
						placeholder="예: 택배 상자가 심하게 찌그러진 채 도착했고 본체 왼쪽 연결 부위가 부러져 있습니다."
						className="w-full rounded-xl border border-relo-line-strong bg-white p-3.5 text-sm text-relo-ink focus:border-relo-brand"
						{...form.register("issue")}
					/>
					{errors.issue ? (
						<p className="text-xs font-medium text-relo-danger">
							{errors.issue.message}
						</p>
					) : null}
				</div>

				<div className="space-y-2 rounded-2xl border border-relo-brand-line bg-relo-brand-soft/45 p-4">
					<div className="flex flex-wrap items-center justify-between gap-2">
						<label
							htmlFor={issueEnTextareaId}
							className="text-xs font-extrabold text-relo-brand"
						>
							외국어 사유 미리 변환 (선택 사항)
						</label>
						<Button
							variant="primary"
							size="sm"
							isLoading={isTranslating}
							onClick={onTranslateIssue}
						>
							<Languages className="h-3.5 w-3.5" aria-hidden="true" />
							<span>영어로 자동 변환</span>
						</Button>
					</div>
					{isTranslating ? (
						<ReloOrbEmblem
							variant="processing"
							size="sm"
							speech="쇼핑몰 상담원이 바로 이해할 수 있는 정중한 영어로 옮기고 있어요..."
						/>
					) : (
						<textarea
							id={issueEnTextareaId}
							rows={2}
							placeholder="비워 두셔도 등록 후 전체 외국어 환불 메시지를 바로 만들 수 있어요."
							className="w-full rounded-xl border border-relo-line bg-white p-3 text-xs text-relo-ink"
							{...form.register("issueEnglish")}
						/>
					)}
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
						✓ 1단계에서 읽은 주문 영수증 파일({extraScannedCount}개)도 함께 자동
						보관됩니다.
					</p>
				) : null}
			</div>
		);
	}

	return (
		<div className="space-y-4">
			<div className="space-y-3 rounded-2xl border border-relo-line bg-relo-sunken p-4 text-sm">
				<div className="flex justify-between border-b border-relo-line pb-2.5">
					<span className="text-relo-muted">쇼핑몰 / 주문번호</span>
					<span className="font-bold text-relo-ink">
						{values.vendor} · {values.orderRef}
					</span>
				</div>
				<div className="flex justify-between border-b border-relo-line pb-2.5">
					<span className="text-relo-muted">상품 및 수량</span>
					<span className="font-bold text-relo-ink">
						{values.title} ({values.claimQty}개)
					</span>
				</div>
				<div className="flex justify-between border-b border-relo-line pb-2.5">
					<span className="text-relo-muted">해결 방법 / 금액</span>
					<span className="font-extrabold text-relo-brand tabular-nums">
						{claimKinds?.[values.kind] ?? values.kind} · {values.currency}{" "}
						{values.claimedAmount}
					</span>
				</div>
				<div className="flex justify-between">
					<span className="text-relo-muted">첨부한 사진·영수증</span>
					<span className="font-bold text-relo-ink">
						총 {stagedFilesCount + extraScannedCount}개
					</span>
				</div>
			</div>

			<div className="flex items-start gap-2.5 rounded-2xl bg-relo-brand-soft/60 p-3.5 text-xs text-relo-body">
				<ShieldCheck
					className="mt-0.5 h-4 w-4 shrink-0 text-relo-brand"
					aria-hidden="true"
				/>
				<span>
					등록 즉시 내 계정에만 안전하게 암호화 보관되며, 다음 화면에서 해외
					쇼핑몰에 보낼 외국어 환불 메시지를 바로 복사할 수 있어요.
				</span>
			</div>
		</div>
	);
}
