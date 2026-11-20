/**
 * @module client/components/AiConsentDialog
 * @layer View (AI Consent Notice shown before the first AI request)
 * @purpose Says what an AI request sends to Google and waits for the person's answer.
 *          Consent is saved, and something is sent, only after they press the agree button.
 */

import { useCallback, useEffect, useId, useRef, useState } from "react";
import { Button } from "@/client/components/ui/Primitives";
import { useAiConsentMutation, useSession } from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";

/**
 * The one gate every AI button goes through, and the one a later agent run will use too.
 * `ensureConsent()` answers true when AI may be called: at once if the person already agreed,
 * otherwise after they agree in the notice. It answers false when they decline, and the
 * caller then sends nothing. Render `consentDialog` once in the component that calls it.
 */
export function useAiConsentGate() {
	const { data: session } = useSession();
	const consentMutation = useAiConsentMutation();
	const answerRef = useRef<((agreed: boolean) => void) | null>(null);
	const [isOpen, setIsOpen] = useState(false);
	const [failed, setFailed] = useState(false);
	const consented = Boolean(session?.user?.aiConsentAt);

	const ensureConsent = useCallback((): Promise<boolean> => {
		if (consented) return Promise.resolve(true);
		// Asked again before answering: the earlier question counts as "no".
		answerRef.current?.(false);
		return new Promise((resolve) => {
			answerRef.current = resolve;
			setFailed(false);
			setIsOpen(true);
		});
	}, [consented]);

	const answer = (agreed: boolean) => {
		answerRef.current?.(agreed);
		answerRef.current = null;
		setIsOpen(false);
	};

	const handleAgree = async () => {
		setFailed(false);
		try {
			await consentMutation.mutateAsync(true);
			answer(true);
		} catch {
			setFailed(true);
		}
	};

	// Leaving the screen with the notice open is a "no".
	useEffect(() => () => answerRef.current?.(false), []);

	const consentDialog = isOpen ? (
		<AiConsentDialog
			isSaving={consentMutation.isPending}
			failed={failed}
			onAgree={() => void handleAgree()}
			onDecline={() => answer(false)}
		/>
	) : null;

	return { ensureConsent, consentDialog };
}

function AiConsentDialog({
	isSaving,
	failed,
	onAgree,
	onDecline,
}: {
	isSaving: boolean;
	failed: boolean;
	onAgree: () => void;
	onDecline: () => void;
}) {
	const dialogRef = useRef<HTMLDialogElement | null>(null);
	const titleId = useId();
	const { t } = useI18n();
	const c = t.settings.consent;

	// A native modal dialog keeps focus inside it and makes the page behind it inert.
	// Focus starts on "no" (the first button), so Enter can neither agree by accident nor
	// open the policy link that comes before the buttons.
	useEffect(() => {
		const dialog = dialogRef.current;
		if (!dialog) return;
		if (!dialog.open) dialog.showModal();
		dialog.querySelector<HTMLButtonElement>("button")?.focus();
	}, []);

	return (
		<dialog
			ref={dialogRef}
			aria-labelledby={titleId}
			onCancel={(event) => {
				// Escape means "no", except while the "yes" is already being saved.
				event.preventDefault();
				if (!isSaving) onDecline();
			}}
			className="m-auto max-h-[calc(100dvh-2rem)] w-[calc(100%-2rem)] max-w-md overflow-y-auto rounded-3xl border border-relo-line bg-white p-6 text-relo-ink shadow-float backdrop:bg-slate-950/65"
		>
			<h2 id={titleId} className="text-lg font-extrabold tracking-tight">
				{c.title}
			</h2>
			<p className="mt-2 text-sm leading-relaxed text-relo-body">{c.lead}</p>

			<p className="mt-4 text-xs font-bold text-relo-muted">{c.sentTitle}</p>
			<ul className="mt-1.5 list-disc space-y-1 pl-5 text-sm leading-relaxed">
				<li>{c.sentClaim}</li>
				<li>{c.sentReply}</li>
				<li>{c.sentFile}</li>
			</ul>

			<p className="mt-4 text-xs leading-relaxed text-relo-muted">
				{c.notSent} {c.control}{" "}
				{/* A new tab, so reading the policy does not answer the question for them. */}
				<a
					href="/privacy"
					target="_blank"
					rel="noreferrer"
					className="font-semibold text-relo-brand hover:underline"
				>
					{c.policyLink}
				</a>
			</p>

			{failed ? (
				<p role="alert" className="mt-3 text-xs font-semibold text-relo-danger">
					{c.saveFail}
				</p>
			) : null}

			<div className="mt-5 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
				<Button variant="ghost" disabled={isSaving} onClick={onDecline}>
					{c.decline}
				</Button>
				<Button variant="primary" isLoading={isSaving} onClick={onAgree}>
					{c.agree}
				</Button>
			</div>
		</dialog>
	);
}
