/**
 * @module client/components/media/PdfPreviewCanvas
 * @layer View (In-Browser Order Receipt Viewer)
 * @purpose Renders PDF order confirmations directly inside a zoomable HTML5 canvas
 *          so consumers can read tiny order numbers without downloading external viewers.
 */

import {
	ChevronLeft,
	ChevronRight,
	FileText,
	ZoomIn,
	ZoomOut,
} from "lucide-react";
import * as pdfjsLib from "pdfjs-dist";
import pdfWorkerUrl from "pdfjs-dist/build/pdf.worker.min.mjs?url";
import { useEffect, useRef, useState } from "react";
import { Button } from "@/client/components/ui/Primitives";

pdfjsLib.GlobalWorkerOptions.workerSrc = pdfWorkerUrl;

interface PdfPreviewCanvasProps {
	source: File | Blob;
	fileName?: string;
	compact?: boolean;
}

export function PdfPreviewCanvas({
	source,
	fileName = "영수증.pdf",
	compact = false,
}: PdfPreviewCanvasProps) {
	const canvasRef = useRef<HTMLCanvasElement | null>(null);
	const [pdfDoc, setPdfDoc] = useState<pdfjsLib.PDFDocumentProxy | null>(null);
	const [pageNum, setPageNum] = useState(1);
	const [numPages, setNumPages] = useState(1);
	const [scale, setScale] = useState(compact ? 0.9 : 1.15);
	const [errorMsg, setErrorMsg] = useState<string | null>(null);
	const [isLoading, setIsLoading] = useState(true);

	useEffect(() => {
		let cancelled = false;
		let activeTask: pdfjsLib.PDFDocumentLoadingTask | null = null;

		const loadDocument = async () => {
			setIsLoading(true);
			setErrorMsg(null);
			try {
				const buffer = await source.arrayBuffer();
				const loadingTask = pdfjsLib.getDocument({
					data: new Uint8Array(buffer),
				});
				activeTask = loadingTask;
				const doc = await loadingTask.promise;
				if (cancelled) {
					await loadingTask.destroy();
					return;
				}
				setPdfDoc(doc);
				setNumPages(doc.numPages);
				setPageNum(1);
			} catch {
				if (!cancelled) {
					setErrorMsg("PDF 영수증 미리보기를 열지 못했어요.");
				}
			} finally {
				if (!cancelled) {
					setIsLoading(false);
				}
			}
		};

		void loadDocument();

		return () => {
			cancelled = true;
			if (activeTask) {
				void activeTask.destroy();
			}
		};
	}, [source]);

	useEffect(() => {
		if (!pdfDoc || !canvasRef.current) return;
		let renderTask: pdfjsLib.RenderTask | null = null;
		let cancelled = false;

		const renderPage = async () => {
			try {
				const page = await pdfDoc.getPage(pageNum);
				if (cancelled || !canvasRef.current) return;
				const viewport = page.getViewport({ scale });
				const dpr = Math.min(window.devicePixelRatio || 1, 2);
				const canvas = canvasRef.current;
				const ctx = canvas.getContext("2d");
				if (!ctx) return;

				canvas.width = Math.floor(viewport.width * dpr);
				canvas.height = Math.floor(viewport.height * dpr);
				canvas.style.width = `${Math.floor(viewport.width)}px`;
				canvas.style.height = `${Math.floor(viewport.height)}px`;

				renderTask = page.render({
					canvas,
					canvasContext: ctx,
					viewport,
					transform: dpr !== 1 ? [dpr, 0, 0, dpr, 0, 0] : undefined,
				});
				await renderTask.promise;
			} catch {
				// Ignore cancelled render task exceptions on rapid zoom/page switch
			}
		};

		void renderPage();

		return () => {
			cancelled = true;
			renderTask?.cancel();
		};
	}, [pdfDoc, pageNum, scale]);

	return (
		<div className="overflow-hidden rounded-2xl border border-relo-line bg-relo-sunken">
			<div className="flex flex-wrap items-center justify-between gap-2 border-b border-relo-line bg-white px-3.5 py-2.5">
				<div className="flex min-w-0 items-center gap-2">
					<span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-relo-brand-soft text-relo-brand">
						<FileText className="h-4 w-4" aria-hidden="true" />
					</span>
					<span className="truncate text-xs font-bold text-relo-ink">
						{fileName}
					</span>
				</div>

				<div className="flex items-center gap-1.5">
					<Button
						variant="ghost"
						size="sm"
						aria-label="축소"
						onClick={() =>
							setScale((s) => Math.max(0.6, +(s - 0.2).toFixed(2)))
						}
					>
						<ZoomOut className="h-3.5 w-3.5" aria-hidden="true" />
					</Button>
					<span className="text-xs font-bold text-relo-muted tabular-nums">
						{Math.round(scale * 100)}%
					</span>
					<Button
						variant="ghost"
						size="sm"
						aria-label="확대"
						onClick={() =>
							setScale((s) => Math.min(2.2, +(s + 0.2).toFixed(2)))
						}
					>
						<ZoomIn className="h-3.5 w-3.5" aria-hidden="true" />
					</Button>

					{numPages > 1 ? (
						<div className="ml-2 flex items-center gap-1 border-l border-relo-line pl-2">
							<Button
								variant="ghost"
								size="sm"
								aria-label="이전 페이지"
								disabled={pageNum <= 1}
								onClick={() => setPageNum((p) => Math.max(1, p - 1))}
							>
								<ChevronLeft className="h-3.5 w-3.5" aria-hidden="true" />
							</Button>
							<span className="text-xs font-bold text-relo-ink tabular-nums">
								{pageNum} / {numPages}
							</span>
							<Button
								variant="ghost"
								size="sm"
								aria-label="다음 페이지"
								disabled={pageNum >= numPages}
								onClick={() => setPageNum((p) => Math.min(numPages, p + 1))}
							>
								<ChevronRight className="h-3.5 w-3.5" aria-hidden="true" />
							</Button>
						</div>
					) : null}
				</div>
			</div>

			<div className="flex max-h-96 justify-center overflow-auto p-4">
				{isLoading ? (
					<div className="flex h-44 items-center justify-center text-xs font-semibold text-relo-muted">
						영수증 화면을 불러오는 중이에요...
					</div>
				) : errorMsg ? (
					<div className="flex h-36 items-center justify-center text-xs font-semibold text-relo-danger">
						{errorMsg}
					</div>
				) : (
					<canvas ref={canvasRef} className="rounded-lg bg-white shadow-card" />
				)}
			</div>
		</div>
	);
}
