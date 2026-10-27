/**
 * @module client/features/claim-wizard/WizardInvoiceScanCard
 * @layer View (Step 1 Order Receipt Auto-Reader)
 * @purpose Lets consumers upload an order confirmation PDF or screenshot to fill
 *          store name, order ID, date, and amount automatically.
 */

import { FileScan, Sparkles } from "lucide-react";
import { type ChangeEvent, useId, useState } from "react";
import { PdfPreviewCanvas } from "@/client/components/media/PdfPreviewCanvas";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Badge, Button, useToast } from "@/client/components/ui/Primitives";
import { useAiExtractNewDocMutation } from "@/client/hooks/useClaims";
import {
	useAiConsentMutation,
	useAppConfig,
	useSession,
} from "@/client/hooks/useSession";
import { useCalmPreparation } from "@/client/lib/preparation";
import type { AiExtractionResponse } from "@/client/types";

interface WizardInvoiceScanCardProps {
	onExtracted: (result: AiExtractionResponse, scannedFile: File) => void;
}

export function WizardInvoiceScanCard({
	onExtracted,
}: WizardInvoiceScanCardProps) {
	const fileInputId = useId();
	const { data: session } = useSession();
	const { data: config } = useAppConfig();
	const aiConsentMutation = useAiConsentMutation();
	const extractMutation = useAiExtractNewDocMutation();
	const { isPreparing, runCalmly } = useCalmPreparation();
	const { showToast } = useToast();

	const [scannedPdf, setScannedPdf] = useState<File | null>(null);

	const aiEnabled = Boolean(config?.ai.enabled);
	const hasConsent = Boolean(session?.user?.aiConsentAt);

	const handleScanFile = async (event: ChangeEvent<HTMLInputElement>) => {
		const file = event.target.files?.[0];
		event.target.value = "";
		if (!file) return;

		if (file.type === "application/pdf") {
			setScannedPdf(file);
		} else {
			setScannedPdf(null);
		}

		if (!aiEnabled) {
			showToast(
				"영수증 미리보기를 열었어요! 아래 칸에 주문번호를 입력해 주세요.",
			);
			return;
		}

		try {
			if (!hasConsent) {
				await aiConsentMutation.mutateAsync(true);
			}
			const res = await runCalmly(() =>
				extractMutation.mutateAsync({ file, fileName: file.name }),
			);
			if (res) {
				onExtracted(res, file);
				showToast("주문 영수증에서 정보를 찾아 자동으로 채웠어요!");
			}
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "영수증 자동 읽기에 실패했어요. 직접 입력해 주세요.",
				"error",
			);
		}
	};

	return (
		<div className="space-y-3 rounded-2xl border border-relo-brand-line bg-relo-brand-soft/45 p-4">
			{isPreparing ? (
				<div className="py-2">
					<ReloOrbEmblem
						variant="processing"
						size="sm"
						speech="영수증에서 쇼핑몰·주문번호·날짜·금액을 읽고 있어요..."
					/>
				</div>
			) : (
				<div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
					<div className="space-y-1">
						<div className="flex items-center gap-1.5">
							<Badge tone="brand">
								<Sparkles className="h-3 w-3" aria-hidden="true" />
								<span>영수증 3초 자동 입력</span>
							</Badge>
							<span className="text-[11px] font-semibold text-relo-muted">
								선택 사항
							</span>
						</div>
						<p className="text-xs font-semibold text-relo-ink">
							결제 내역 캡처나 영수증 PDF가 있다면 올려보세요. 일일이 입력하지
							않아도 돼요.
						</p>
					</div>

					<div>
						<label
							htmlFor={fileInputId}
							className="inline-flex min-h-10 cursor-pointer items-center gap-1.5 rounded-xl bg-relo-brand px-3.5 py-2 text-xs font-bold text-white shadow-2xs transition hover:bg-relo-brand-hover"
						>
							<FileScan className="h-4 w-4" aria-hidden="true" />
							<span>영수증 사진·PDF 넣기</span>
						</label>
						<input
							id={fileInputId}
							type="file"
							accept=".pdf,.png,.jpg,.jpeg,.webp,application/pdf,image/png,image/jpeg,image/webp"
							onChange={handleScanFile}
							className="sr-only"
						/>
					</div>
				</div>
			)}

			{!hasConsent && aiEnabled ? (
				<div className="flex items-center justify-between gap-2 rounded-xl bg-white/85 px-3 py-2 text-[11px] text-relo-muted">
					<span>
						영수증 자동 읽기를 켜면 설정 화면에서 언제든 다시 끌 수 있어요.
					</span>
					<Button
						variant="ghost"
						size="sm"
						isLoading={aiConsentMutation.isPending}
						onClick={() => void aiConsentMutation.mutateAsync(true)}
					>
						자동 읽기 켜기
					</Button>
				</div>
			) : null}

			{scannedPdf ? (
				<PdfPreviewCanvas
					source={scannedPdf}
					fileName={scannedPdf.name}
					compact
				/>
			) : null}
		</div>
	);
}
