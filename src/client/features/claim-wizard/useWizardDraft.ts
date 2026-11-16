/**
 * @module client/features/claim-wizard/useWizardDraft
 * @layer ViewModel (Refund Wizard Draft Keeper)
 * @purpose Brings back the refund request a person was writing when they return to the
 *          wizard, and keeps saving it as they type. Files are not kept, so the hook also
 *          reports how many files were attached before, for the "attach again" reminder.
 */

import { useCallback, useEffect, useState } from "react";
import type { UseFormReturn } from "react-hook-form";
import {
	clearWizardDraft,
	loadWizardDraft,
	saveWizardDraft,
} from "@/client/lib/wizard-draft";
import type { ClaimWizardFormValues } from "@/client/types";

interface UseWizardDraftOptions {
	/** The signed-in person; drafts are kept per account. Undefined until the session loads. */
	userId: string | undefined;
	form: UseFormReturn<ClaimWizardFormValues>;
	values: ClaimWizardFormValues;
	step: number;
	setStep: (step: number) => void;
	/** Names of the files attached right now. */
	fileNames: string[];
	/** The wizard was opened with details already chosen (a shop from the first screen): start fresh. */
	startFresh: boolean;
}

export interface RestoredDraft {
	step: number;
	fileCount: number;
}

export function useWizardDraft({
	userId,
	form,
	values,
	step,
	setStep,
	fileNames,
	startFresh,
}: UseWizardDraftOptions) {
	// The account whose draft has been looked up; saving waits for this, so the empty
	// form shown at first never overwrites what was stored.
	const [readyFor, setReadyFor] = useState<string | null>(null);
	const [restored, setRestored] = useState<RestoredDraft | null>(null);
	// Names of the files attached before the reload; kept until files are attached again,
	// so the reminder survives a second reload.
	const [earlierFiles, setEarlierFiles] = useState<string[]>([]);
	// Set once the request has been submitted: from then on nothing is saved.
	const [finished, setFinished] = useState(false);

	useEffect(() => {
		if (!userId || readyFor === userId) return;
		const draft = startFresh ? null : loadWizardDraft(userId);
		if (draft) {
			// keepDefaultValues: "start over" must go back to the blank form, not to this draft.
			form.reset(draft.values, { keepDefaultValues: true });
			setStep(draft.step);
			setRestored({ step: draft.step, fileCount: draft.fileNames.length });
			setEarlierFiles(draft.fileNames);
		}
		setReadyFor(userId);
	}, [userId, readyFor, startFresh, form, setStep]);

	const snapshot = JSON.stringify(values);
	const names = (fileNames.length > 0 ? fileNames : earlierFiles).join("\n");
	useEffect(() => {
		if (!userId || readyFor !== userId || finished) return;
		saveWizardDraft(userId, {
			values: JSON.parse(snapshot) as ClaimWizardFormValues,
			step,
			fileNames: names ? names.split("\n") : [],
		});
	}, [userId, readyFor, finished, snapshot, step, names]);

	/** Starting over: drop the draft; what is typed next is kept again. */
	const forget = useCallback(() => {
		if (userId) clearWizardDraft(userId);
		setRestored(null);
		setEarlierFiles([]);
	}, [userId]);

	/** Submitted: drop the draft and stop keeping anything. */
	const finish = useCallback(() => {
		if (userId) clearWizardDraft(userId);
		setRestored(null);
		setFinished(true);
	}, [userId]);

	return { restored, forget, finish };
}
