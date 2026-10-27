/**
 * @module client/components/media/UppyEvidenceUploader
 * @layer View (10MB Consumer Photo & Receipt Vault Uploader)
 * @purpose Manages up to 8 private photos/PDFs (max 10MB each) with inline PDF preview
 *          and address-trimming photo editor.
 */

import Uppy from "@uppy/core";
import { useUppyState } from "@uppy/react";
import Dashboard from "@uppy/react/dashboard";
import "@uppy/dashboard/css/style.min.css";
import {
	Crop,
	Eye,
	FileText,
	Image as ImageIcon,
	Sparkles,
	Trash2,
	UploadCloud,
} from "lucide-react";
import { type ChangeEvent, useEffect, useId, useMemo, useState } from "react";
import { DamagePhotoCropperModal } from "@/client/components/media/DamagePhotoCropperModal";
import { PdfPreviewCanvas } from "@/client/components/media/PdfPreviewCanvas";
import { Badge, Button, useToast } from "@/client/components/ui/Primitives";
import { formatFileSize } from "@/client/lib/format";

export interface StagedEvidenceItem {
	uppyId: string;
	file: File;
	name: string;
	mime: string;
	size: number;
}

interface UppyEvidenceUploaderProps {
	onFilesChange?: (items: StagedEvidenceItem[]) => void;
	onAiExtractFile?: (file: File) => void;
	isExtractingAi?: boolean;
	showNativeDashboard?: boolean;
}

const ALLOWED_MIMES = [
	"image/png",
	"image/jpeg",
	"image/webp",
	"application/pdf",
];

export function UppyEvidenceUploader({
	onFilesChange,
	onAiExtractFile,
	isExtractingAi = false,
	showNativeDashboard = false,
}: UppyEvidenceUploaderProps) {
	const inputId = useId();
	const { showToast } = useToast();
	const [cropTarget, setCropTarget] = useState<{
		uppyId: string;
		file: File;
	} | null>(null);
	const [previewPdf, setPreviewPdf] = useState<File | null>(null);
	const [openDashboard, setOpenDashboard] = useState(showNativeDashboard);

	const uppy = useMemo(
		() =>
			new Uppy({
				autoProceed: false,
				restrictions: {
					maxFileSize: 10 * 1024 * 1024,
					maxNumberOfFiles: 8,
					allowedFileTypes: ALLOWED_MIMES,
				},
			}),
		[],
	);

	useEffect(() => {
		const onRestrictionFailed = (
			_file: unknown,
			error: { message?: string },
		) => {
			showToast(
				error?.message ??
					"PNG·JPG·WebP·PDF 형식의 10MB 이하 파일만 올릴 수 있어요.",
				"error",
			);
		};
		uppy.on("restriction-failed", onRestrictionFailed);
		return () => {
			uppy.off("restriction-failed", onRestrictionFailed);
			uppy.destroy();
		};
	}, [uppy, showToast]);

	const uppyFilesMap = useUppyState(uppy, (state) => state.files);

	const stagedItems = useMemo<StagedEvidenceItem[]>(() => {
		return Object.values(uppyFilesMap)
			.filter((f): f is typeof f & { data: File } => f.data instanceof File)
			.map((f) => ({
				uppyId: f.id,
				file: f.data,
				name: f.name ?? f.data.name,
				mime: f.type || f.data.type,
				size: f.size ?? f.data.size,
			}));
	}, [uppyFilesMap]);

	useEffect(() => {
		onFilesChange?.(stagedItems);
	}, [stagedItems, onFilesChange]);

	const handleSelectFiles = (event: ChangeEvent<HTMLInputElement>) => {
		const list = event.target.files;
		if (!list?.length) return;
		for (const file of Array.from(list)) {
			try {
				uppy.addFile({
					name: file.name,
					type: file.type,
					data: file,
				});
			} catch {
				// Handled by restriction-failed listener
			}
		}
		event.target.value = "";
	};

	const handleReplaceWithCropped = (croppedFile: File) => {
		if (!cropTarget) return;
		uppy.removeFile(cropTarget.uppyId);
		uppy.addFile({
			name: croppedFile.name,
			type: croppedFile.type,
			data: croppedFile,
		});
		showToast("불량 부분만 깔끔하게 잘라서 준비했어요!");
	};

	return (
		<div className="space-y-4">
			<div className="rounded-2xl border-2 border-dashed border-relo-brand-line bg-relo-brand-soft/35 p-5 transition-colors hover:border-relo-brand">
				<div className="flex flex-col items-center gap-3 text-center sm:flex-row sm:text-left">
					<div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-white text-relo-brand shadow-2xs">
						<UploadCloud className="h-6 w-6" aria-hidden="true" />
					</div>
					<div className="min-w-0 flex-1">
						<p className="text-sm font-extrabold text-relo-ink">
							주문 영수증(PDF·캡처)이나 불량 상품 사진을 올려주세요
						</p>
						<p className="mt-0.5 text-xs text-relo-muted">
							PNG · JPG · WebP · PDF 지원 (파일당 최대 10MB, 최대 8장 · 내
							계정에만 안전 보관)
						</p>
					</div>
					<div className="flex flex-wrap items-center gap-2">
						<label
							htmlFor={inputId}
							className="inline-flex min-h-10 cursor-pointer items-center gap-1.5 rounded-xl bg-relo-brand px-4 py-2 text-xs font-bold text-white shadow-2xs transition hover:bg-relo-brand-hover"
						>
							<UploadCloud className="h-4 w-4" aria-hidden="true" />
							<span>사진·영수증 선택</span>
						</label>
						<input
							id={inputId}
							type="file"
							multiple
							accept=".png,.jpg,.jpeg,.webp,.pdf,image/png,image/jpeg,image/webp,application/pdf"
							onChange={handleSelectFiles}
							className="sr-only"
						/>
						<Button
							variant="secondary"
							size="sm"
							onClick={() => setOpenDashboard((v) => !v)}
						>
							{openDashboard ? "창 닫기" : "끌어다 놓기 창 열기"}
						</Button>
					</div>
				</div>

				{openDashboard ? (
					<div className="mt-4 overflow-hidden rounded-2xl border border-relo-line bg-white p-2">
						<Dashboard
							uppy={uppy}
							height={230}
							hideUploadButton
							proudlyDisplayPoweredByUppy={false}
							note="최대 10MB · PNG, JPG, WebP, PDF"
						/>
					</div>
				) : null}
			</div>

			{stagedItems.length > 0 ? (
				<div className="space-y-2.5">
					<div className="flex items-center justify-between">
						<p className="text-xs font-bold text-relo-muted">
							준비된 파일 ({stagedItems.length}/8)
						</p>
						<Badge tone="brand">안전 보관 대기</Badge>
					</div>

					<ul className="space-y-2">
						{stagedItems.map((item) => {
							const isImage = item.mime.startsWith("image/");
							const isPdf = item.mime === "application/pdf";

							return (
								<li
									key={item.uppyId}
									className="flex flex-wrap items-center justify-between gap-2.5 rounded-2xl border border-relo-line bg-white p-3 shadow-2xs"
								>
									<div className="flex min-w-0 items-center gap-3">
										<span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-relo-sunken text-relo-brand">
											{isPdf ? (
												<FileText className="h-5 w-5" aria-hidden="true" />
											) : (
												<ImageIcon className="h-5 w-5" aria-hidden="true" />
											)}
										</span>
										<div className="min-w-0">
											<p className="truncate text-sm font-bold text-relo-ink">
												{item.name}
											</p>
											<p className="text-xs text-relo-muted">
												{formatFileSize(item.size)} ·{" "}
												{isPdf ? "PDF 영수증" : "상품 사진"}
											</p>
										</div>
									</div>

									<div className="flex flex-wrap items-center gap-1.5">
										{isImage ? (
											<Button
												variant="soft"
												size="sm"
												onClick={() =>
													setCropTarget({
														uppyId: item.uppyId,
														file: item.file,
													})
												}
											>
												<Crop className="h-3.5 w-3.5" aria-hidden="true" />
												<span>필요한 부분만 자르기</span>
											</Button>
										) : null}

										{isPdf ? (
											<Button
												variant="soft"
												size="sm"
												onClick={() =>
													setPreviewPdf((prev) =>
														prev === item.file ? null : item.file,
													)
												}
											>
												<Eye className="h-3.5 w-3.5" aria-hidden="true" />
												<span>
													{previewPdf === item.file
														? "영수증 닫기"
														: "영수증 크게 보기"}
												</span>
											</Button>
										) : null}

										{onAiExtractFile ? (
											<Button
												variant="primary"
												size="sm"
												isLoading={isExtractingAi}
												onClick={() => onAiExtractFile(item.file)}
											>
												<Sparkles className="h-3.5 w-3.5" aria-hidden="true" />
												<span>주문 정보 자동 채우기</span>
											</Button>
										) : null}

										<Button
											variant="ghost"
											size="sm"
											aria-label={`${item.name} 제거`}
											onClick={() => uppy.removeFile(item.uppyId)}
										>
											<Trash2
												className="h-4 w-4 text-relo-danger"
												aria-hidden="true"
											/>
										</Button>
									</div>
								</li>
							);
						})}
					</ul>
				</div>
			) : null}

			{previewPdf ? (
				<PdfPreviewCanvas source={previewPdf} fileName={previewPdf.name} />
			) : null}

			<DamagePhotoCropperModal
				file={cropTarget?.file ?? null}
				onClose={() => setCropTarget(null)}
				onCropped={handleReplaceWithCropped}
			/>
		</div>
	);
}
