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
import { useI18n } from "@/client/i18n";
import { filesApi } from "@/client/lib/api-client";
import { errorText } from "@/client/lib/claim-words";
import { fill, formatFileSize, formatLocalDate } from "@/client/lib/format";
import type { ClaimFile, ClaimView } from "@/client/types";

export function ClaimFilesVaultCard({ claim }: { claim: ClaimView }) {
	const { showToast } = useToast();
	const { t, locale, localeOption } = useI18n();
	const v = t.detail.files;
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
			showToast(errorText(error, v.toastPreviewFail, locale), "error");
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
			showToast(v.toastUploaded);
		} catch (error) {
			showToast(errorText(error, v.toastUploadFail, locale), "error");
		}
	};

	return (
		<Card className="space-y-4">
			<div>
				<Badge tone="brand">{v.eyebrow}</Badge>
				<h3 className="mt-1 text-lg font-extrabold text-relo-ink">
					{fill(v.title, { n: claim.files.length })}
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
											{formatLocalDate(file.createdAt, localeOption.bcp47)}
											{file.usedAsProof ? ` · ${v.usedAsProof}` : ""}
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
												? v.closePreview
												: v.open}
										</span>
									</Button>
									{!file.usedAsProof ? (
										<Button
											variant="ghost"
											size="sm"
											aria-label={fill(v.deleteAria, { name: file.name })}
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
				<p className="text-xs text-relo-muted">{v.empty}</p>
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
							<span>{fill(v.saveStaged, { n: stagedNewFiles.length })}</span>
						</Button>
					</div>
				) : null}
			</div>
		</Card>
	);
}
