/**
 * @module client/types/claim.schema
 * @layer Model (Validation Schemas — 5-Step Claim Wizard & Deposit Proof)
 * @purpose Zod v4 schemas validating consumer refund wizard inputs and bank-deposit proof forms.
 *          Each rule names its message by key; the screen shows the sentence for that key in
 *          the reader's language (shared.fieldErrors, read through fieldError()).
 */

import { z } from "zod";

export const claimWizardSchema = z.object({
	vendor: z.string().trim().min(1, "vendorRequired").max(100, "vendorTooLong"),
	vendorUrl: z
		.string()
		.trim()
		.max(300, "urlTooLong")
		.optional()
		.or(z.literal("")),
	orderRef: z
		.string()
		.trim()
		.min(1, "orderRefRequired")
		.max(100, "orderRefTooLong"),
	orderedOn: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "orderedOnInvalid"),
	title: z.string().trim().min(1, "titleRequired").max(150, "titleTooLong"),
	sku: z.string().trim().max(100).optional().or(z.literal("")),
	orderedQty: z
		.number({ message: "orderedQtyNumber" })
		.int()
		.min(1, "qtyMin")
		.max(10000),
	claimQty: z
		.number({ message: "claimQtyNumber" })
		.int()
		.min(1, "qtyMin")
		.max(10000),
	currency: z.enum(["USD", "EUR", "GBP", "JPY", "CNY", "KRW", "CAD", "AUD"]),
	claimedAmount: z
		.string()
		.trim()
		.regex(/^\d+(\.\d{1,2})?$/, "amountInvalid"),
	kind: z.enum(["refund", "exchange", "repair"]),
	issue: z.string().trim().min(5, "issueTooShort").max(3000, "issueTooLong"),
	issueEnglish: z.string().trim().max(3000).optional().or(z.literal("")),
});

export type ClaimWizardFormValues = z.infer<typeof claimWizardSchema>;

export const receiptFormSchema = z.object({
	kind: z.enum(["cash", "goods", "repair", "reversal"]),
	proofId: z.string().min(1, "proofRequired"),
	receivedOn: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "receivedOnInvalid"),
	amount: z.string().trim().optional().or(z.literal("")),
	quantity: z.number().int().optional(),
	transactionRef: z.string().trim().max(100).optional().or(z.literal("")),
	reverses: z.string().optional().or(z.literal("")),
	note: z.string().trim().max(2000).optional().or(z.literal("")),
	confirmed: z.boolean().refine((v) => v === true, {
		message: "confirmRequired",
	}),
	missingReferenceConfirmed: z.boolean().optional(),
	duplicateReviewed: z.boolean().optional(),
});

export type ReceiptFormValues = z.infer<typeof receiptFormSchema>;
