/**
 * @module client/features/claim-detail/ClaimFilesVaultCard
 * @layer View (Stored 10MB Photo & Receipt Vault Card)
 * @purpose Displays and previews private photos and PDF receipts attached to a claim,
 *          and lets the consumer upload additional files.
 */

import {
	Eye,
	FileText,
	Image as ImageIcon,
	Trash2,
	Upload,
} from "lucide-react";
import { useState } from "react";
import { PdfPreviewCanvas } from "@/client/components/media/PdfPreviewCanvas";
import {
	type StagedEvidenceItem,
	UppyEvidenceUploader,
} from "@/client/components/media/UppyEvidenceUploader";
import {
	Badge,
	Button,
	Card,
	useToast,
} from "@/client/components/ui/Primitives";
import {
	useRemoveClaimFileMutation,
	useUploadClaimFileMutation,
} from "@/client/hooks/useClaims";
import { filesApi } from "@/client/lib/api-client";
import { formatFileSize, formatKoreanDate } from "@/client/lib/format";
import type { ClaimFile, ClaimView } from "@/client/types";

export function ClaimFilesVaultCard({ claim }: { claim: ClaimView }) {
	const { showToast } = useToast();
	const uploadMutation = useUploadClaimFileMutation(claim.id);
	const removeFileMutation = useRemoveClaimFileMutation(claim.id);

	const [stagedNewFiles, setStagedNewFiles] = useState<StagedEvidenceItem[]>(
		[],
	);
	const [previewFile, setPreviewFile] = useState<{
		meta: ClaimFile;
		blob: Blob;
		url: string;
	} | null>(null);

	const handlePreviewStoredFile = async (meta: ClaimFile) => {
		if (previewFile?.meta.id === meta.id) {
			URL.revokeObjectURL(previewFile.url);
			setPreviewFile(null);
			return;
		}
		try {
			const blob = await filesApi.downloadBlob(meta.id);
			if (previewFile) URL.revokeObjectURL(previewFile.url);
			setPreviewFile({ meta, blob, url: URL.createObjectURL(blob) });
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "파일 미리보기를 불러오지 못했어요.",
				"error",
			);
		}
	};

	const handleUploadStaged = async () => {
		if (stagedNewFiles.length === 0) return;
		try {
			let nextVersion = claim.version;
			for (const item of stagedNewFiles) {
				const res = await uploadMutation.mutateAsync({
					version: nextVersion,
					file: item.file,
					fileName: item.name,
				});
				nextVersion = res.claim.version;
			}
			setStagedNewFiles([]);
			showToast("추가한 파일이 내 전용 보관함에 저장되었어요!");
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "파일 업로드 중 오류가 발생했어요.",
				"error",
			);
		}
	};

	return (
		<Card className="space-y-4">
			<div>
				<Badge tone="brand">10MB 내 전용 사진 보관함</Badge>
				<h3 className="mt-1 text-lg font-extrabold text-relo-ink">
					보관된 영수증 · 불량 사진 ({claim.files.length}개)
				</h3>
			</div>

			{claim.files.length > 0 ? (
				<ul className="space-y-2">
					{claim.files.map((file) => {
						const isPdf = file.mime === "application/pdf";
						return (
							<li
								key={file.id}
								className="flex flex-wrap items-center justify-between gap-2.5 rounded-2xl border border-relo-line bg-relo-sunken p-3"
							>
								<div className="flex min-w-0 items-center gap-3">
									<span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-white text-relo-brand">
										{isPdf ? (
											<FileText className="h-4 w-4" aria-hidden="true" />
										) : (
											<ImageIcon className="h-4 w-4" aria-hidden="true" />
										)}
									</span>
									<div className="min-w-0">
										<p className="truncate text-sm font-bold text-relo-ink">
											{file.name}
										</p>
										<p className="text-xs text-relo-muted">
											{formatFileSize(file.size)} ·{" "}
											{formatKoreanDate(file.createdAt)}
											{file.usedAsProof ? " · 입금 확인 자료" : ""}
										</p>
									</div>
								</div>

								<div className="flex items-center gap-1.5">
									<Button
										variant="secondary"
										size="sm"
										onClick={() => void handlePreviewStoredFile(file)}
									>
										<Eye className="h-3.5 w-3.5" aria-hidden="true" />
										<span>
											{previewFile?.meta.id === file.id
												? "미리보기 닫기"
												: "열어보기"}
										</span>
									</Button>
									{!file.usedAsProof ? (
										<Button
											variant="ghost"
											size="sm"
											aria-label={`${file.name} 삭제`}
											onClick={() =>
												void removeFileMutation.mutateAsync({
													fileId: file.id,
													version: claim.version,
												})
											}
										>
											<Trash2
												className="h-4 w-4 text-relo-danger"
												aria-hidden="true"
											/>
										</Button>
									) : null}
								</div>
							</li>
						);
					})}
				</ul>
			) : (
				<p className="text-xs text-relo-muted">
					아직 보관된 파일이 없어요. 아래에서 카드 취소 내역 캡처나 영수증을
					올려 보세요.
				</p>
			)}

			{previewFile ? (
				previewFile.meta.mime === "application/pdf" ? (
					<PdfPreviewCanvas
						source={previewFile.blob}
						fileName={previewFile.meta.name}
					/>
				) : (
					<div className="overflow-hidden rounded-2xl border border-relo-line bg-slate-900 p-3 text-center">
						<img
							src={previewFile.url}
							alt={previewFile.meta.name}
							className="mx-auto max-h-96 rounded-xl object-contain"
						/>
					</div>
				)
			) : null}

			<div className="space-y-3 border-t border-relo-line pt-4">
				<UppyEvidenceUploader onFilesChange={setStagedNewFiles} />
				{stagedNewFiles.length > 0 ? (
					<div className="flex justify-end">
						<Button
							variant="primary"
							size="md"
							isLoading={uploadMutation.isPending}
							onClick={handleUploadStaged}
						>
							<Upload className="h-4 w-4" aria-hidden="true" />
							<span>추가한 파일 {stagedNewFiles.length}개 저장하기</span>
						</Button>
					</div>
				) : null}
			</div>
		</Card>
	);
}
