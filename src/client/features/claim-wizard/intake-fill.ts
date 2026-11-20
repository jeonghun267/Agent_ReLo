/**
 * @module client/features/claim-wizard/intake-fill
 * @layer ViewModel (Wizard Intake: the AI fills the form, the person checks it)
 * @purpose Puts what the AI read into the wizard form (the order document, and how it read the
 *          person's one line) and says which step to show next: the first step that still has
 *          a gap, or the review when nothing is missing. Every fact of the order comes from the
 *          document reading; the AI's own part is only which kind, which item and how many.
 */

import type { UseFormReturn } from "react-hook-form";
import { CURRENCY_DIGITS } from "@/client/lib/format";
import type {
	AiExtractionResponse,
	AiIntakeResponse,
	ClaimWizardFormValues,
} from "@/client/types";

export interface WizardIntakeResult {
	/** The reading of the order document, when one was uploaded. */
	extraction: AiExtractionResponse | null;
	/** The uploaded file itself: it is attached to the request as evidence. */
	file: File | null;
	/** What the person wrote, in their own words. It becomes the problem description. */
	text: string;
	/** How the AI read that line. null when nothing was written or the AI could not read it. */
	intake: AiIntakeResponse | null;
}

/** The fields each of the first three steps asks for; the wizard checks them before moving on. */
export const STEP_FIELDS: ReadonlyArray<
	ReadonlyArray<keyof ClaimWizardFormValues>
> = [
	["vendor", "orderRef", "orderedOn"],
	["title", "orderedQty", "claimQty", "currency", "claimedAmount"],
	["kind", "issue"],
];

/** A unit price times a quantity, as the decimal text the amount field takes. */
function timesQty(unitPrice: string, qty: number, digits: number): string {
	const scale = 10 ** digits;
	const total = (Math.round(Number(unitPrice) * scale) * qty) / scale;
	return digits === 0 ? String(Math.round(total)) : total.toFixed(digits);
}

/**
 * Fills the form and returns the step to show. With only a document (nothing written), the
 * person stays on the first step, as before, to check the order details.
 */
export async function applyIntake(
	form: UseFormReturn<ClaimWizardFormValues>,
	{ extraction, text, intake }: WizardIntakeResult,
): Promise<number> {
	const suggestion = extraction?.suggestion;
	if (suggestion?.vendor) form.setValue("vendor", suggestion.vendor);
	if (suggestion?.orderRef) form.setValue("orderRef", suggestion.orderRef);
	if (suggestion?.orderedOn) form.setValue("orderedOn", suggestion.orderedOn);
	if (suggestion?.currency) form.setValue("currency", suggestion.currency);

	// The item the request is about: the one the AI picked from the order, else the first one.
	const item = suggestion?.items[intake?.itemIndex ?? 0];
	if (item) {
		const claimQty = Math.min(
			intake?.claimQty ?? item.claimQty,
			item.orderedQty,
		);
		form.setValue("title", item.name);
		form.setValue("orderedQty", item.orderedQty);
		form.setValue("claimQty", claimQty);
		if (item.unitPrice) {
			const digits = CURRENCY_DIGITS[form.getValues("currency")] ?? 2;
			form.setValue(
				"claimedAmount",
				timesQty(item.unitPrice, claimQty, digits),
			);
		}
	} else if (extraction?.orderTotal) {
		form.setValue("claimedAmount", extraction.orderTotal);
	}

	if (!intake) return 1;
	form.setValue("kind", intake.kind);
	form.setValue("issue", text);
	form.setValue("issueEnglish", intake.issueEnglish);

	for (const [index, fields] of STEP_FIELDS.entries()) {
		if (!(await form.trigger([...fields]))) return index + 1;
	}
	return 5;
}
