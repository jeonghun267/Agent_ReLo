/**
 * @module client/components/media/DamagePhotoCropperModal
 * @layer View (Interactive Photo Trimming & Address Redaction Modal)
 * @purpose Lets consumers trim out home addresses/phone numbers on parcel labels and
 *          keep only the damaged spot before uploading photos.
 */

import Cropper from "cropperjs";
import {
	Check,
	Crop,
	RotateCcw,
	RotateCw,
	X,
	ZoomIn,
	ZoomOut,
} from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { Button } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";

interface DamagePhotoCropperModalProps {
	file: File | null;
	onClose: () => void;
	onCropped: (croppedFile: File) => void;
}

const CROPPER_V2_TEMPLATE = `
  <cropper-canvas background style="height: 360px; width: 100%; border-radius: 16px; overflow: hidden;">
    <cropper-image initial-center-size="contain" rotatable scalable translatable></cropper-image>
    <cropper-shade hidden></cropper-shade>
    <cropper-handle action="select" plain></cropper-handle>
    <cropper-selection initial-coverage="0.78" movable resizable zoomable outlined>
      <cropper-grid role="grid" covered></cropper-grid>
      <cropper-crosshair centered></cropper-crosshair>
      <cropper-handle action="move" theme-color="rgba(255, 255, 255, 0.35)"></cropper-handle>
      <cropper-handle action="n-resize"></cropper-handle>
      <cropper-handle action="e-resize"></cropper-handle>
      <cropper-handle action="s-resize"></cropper-handle>
      <cropper-handle action="w-resize"></cropper-handle>
      <cropper-handle action="ne-resize"></cropper-handle>
      <cropper-handle action="nw-resize"></cropper-handle>
      <cropper-handle action="se-resize"></cropper-handle>
      <cropper-handle action="sw-resize"></cropper-handle>
    </cropper-selection>
  </cropper-canvas>
`;

export function DamagePhotoCropperModal({
	file,
	onClose,
	onCropped,
}: DamagePhotoCropperModalProps) {
	const hostRef = useRef<HTMLDivElement | null>(null);
	const cropperRef = useRef<Cropper | null>(null);
	const [isExporting, setIsExporting] = useState(false);
	const { t } = useI18n();
	const u = t.upload;

	useEffect(() => {
		if (!file || !hostRef.current) return;

		const objectUrl = URL.createObjectURL(file);
		const host = hostRef.current;
		host.innerHTML = "";

		const img = document.createElement("img");
		img.src = objectUrl;
		img.alt = u.cropImageAlt;
		host.appendChild(img);

		const instance = new Cropper(img, {
			container: host,
			template: CROPPER_V2_TEMPLATE,
		});
		cropperRef.current = instance;

		return () => {
			instance.destroy();
			cropperRef.current = null;
			URL.revokeObjectURL(objectUrl);
		};
	}, [file, u.cropImageAlt]);

	const handleZoom = (delta: number) => {
		cropperRef.current?.getCropperImage()?.$zoom(delta);
	};

	const handleRotate = () => {
		cropperRef.current?.getCropperImage()?.$rotate("90deg");
	};

	const handleReset = () => {
		cropperRef.current?.getCropperImage()?.$resetTransform();
		cropperRef.current?.getCropperImage()?.$center("contain");
		cropperRef.current?.getCropperSelection()?.$reset();
	};

	const handleApplyCrop = async () => {
		if (!file || !cropperRef.current) return;
		const selection = cropperRef.current.getCropperSelection();
		if (!selection) return;

		setIsExporting(true);
		try {
			const canvas = await selection.$toCanvas({ width: 1200 });
			const blob = await new Promise<Blob | null>((resolve) => {
				canvas.toBlob((b) => resolve(b), "image/png", 0.94);
			});
			if (!blob) return;

			const baseName = file.name.replace(/\.[^.]+$/, "");
			const croppedFile = new File([blob], `${baseName}-trimmed.png`, {
				type: "image/png",
			});
			onCropped(croppedFile);
			onClose();
		} finally {
			setIsExporting(false);
		}
	};

	return (
		<AnimatePresence>
			{file ? (
				<motion.div
					initial={{ opacity: 0 }}
					animate={{ opacity: 1 }}
					exit={{ opacity: 0 }}
					className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/65 p-4 backdrop-blur-xs"
					role="dialog"
					aria-modal="true"
					aria-labelledby="cropper-modal-title"
				>
					<motion.div
						initial={{ scale: 0.95, y: 12 }}
						animate={{ scale: 1, y: 0 }}
						exit={{ scale: 0.96, y: 8 }}
						className="w-full max-w-xl rounded-3xl border border-relo-line bg-white p-5 shadow-float sm:p-6"
					>
						<div className="mb-4 flex items-start justify-between gap-3">
							<div>
								<span className="inline-flex items-center gap-1 text-xs font-bold text-relo-brand">
									<Crop className="h-3.5 w-3.5" aria-hidden="true" />
									<span>{u.cropEyebrow}</span>
								</span>
								<h3
									id="cropper-modal-title"
									className="mt-1.5 text-lg font-extrabold text-relo-ink"
								>
									{u.cropTitle}
								</h3>
								<p className="text-xs text-relo-muted">{u.cropBody}</p>
							</div>
							<button
								type="button"
								onClick={onClose}
								aria-label={u.close}
								className="rounded-xl p-2 text-relo-muted hover:bg-relo-sunken hover:text-relo-ink"
							>
								<X className="h-5 w-5" aria-hidden="true" />
							</button>
						</div>

						<div
							ref={hostRef}
							className="min-h-[360px] w-full overflow-hidden rounded-2xl bg-slate-900"
						/>

						<div className="mt-4 flex flex-wrap items-center justify-between gap-3">
							<div className="flex flex-wrap items-center gap-1.5">
								<Button
									variant="secondary"
									size="sm"
									onClick={() => handleZoom(0.15)}
								>
									<ZoomIn className="h-3.5 w-3.5" aria-hidden="true" />
									<span>{u.zoomIn}</span>
								</Button>
								<Button
									variant="secondary"
									size="sm"
									onClick={() => handleZoom(-0.15)}
								>
									<ZoomOut className="h-3.5 w-3.5" aria-hidden="true" />
									<span>{u.zoomOut}</span>
								</Button>
								<Button variant="secondary" size="sm" onClick={handleRotate}>
									<RotateCw className="h-3.5 w-3.5" aria-hidden="true" />
									<span>{u.rotate}</span>
								</Button>
								<Button variant="ghost" size="sm" onClick={handleReset}>
									<RotateCcw className="h-3.5 w-3.5" aria-hidden="true" />
									<span>{u.reset}</span>
								</Button>
							</div>

							<div className="flex items-center gap-2">
								<Button variant="ghost" size="md" onClick={onClose}>
									{u.cancel}
								</Button>
								<Button
									variant="primary"
									size="md"
									isLoading={isExporting}
									onClick={handleApplyCrop}
								>
									<Check className="h-4 w-4" aria-hidden="true" />
									<span>{u.apply}</span>
								</Button>
							</div>
						</div>
					</motion.div>
				</motion.div>
			) : null}
		</AnimatePresence>
	);
}
