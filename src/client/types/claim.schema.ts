/**
 * @module client/types/claim.schema
 * @layer Model (Validation Schemas — 5-Step Claim Wizard & Deposit Proof)
 * @purpose Zod v4 schemas validating consumer refund wizard inputs and bank-deposit proof forms.
 */

import { z } from "zod";

export const claimWizardSchema = z.object({
	vendor: z
		.string()
		.trim()
		.min(1, "구매하신 해외 쇼핑몰 이름을 선택하거나 입력해 주세요.")
		.max(100, "쇼핑몰 이름은 100자 이내로 입력해 주세요."),
	vendorUrl: z
		.string()
		.trim()
		.max(300, "주소는 300자 이내로 입력해 주세요.")
		.optional()
		.or(z.literal("")),
	orderRef: z
		.string()
		.trim()
		.min(1, "쇼핑몰 주문번호를 입력해 주세요.")
		.max(100, "주문번호는 100자 이내로 입력해 주세요."),
	orderedOn: z
		.string()
		.regex(/^\d{4}-\d{2}-\d{2}$/, "주문하신 날짜(YYYY-MM-DD)를 선택해 주세요."),
	title: z
		.string()
		.trim()
		.min(1, "문제 생겼던 상품 이름을 입력해 주세요.")
		.max(150, "상품명은 150자 이내로 입력해 주세요."),
	sku: z.string().trim().max(100).optional().or(z.literal("")),
	orderedQty: z
		.number({ message: "주문 수량을 숫자로 입력해 주세요." })
		.int()
		.min(1, "최소 1개 이상 입력해 주세요.")
		.max(10000),
	claimQty: z
		.number({ message: "문제 수량을 숫자로 입력해 주세요." })
		.int()
		.min(1, "최소 1개 이상 입력해 주세요.")
		.max(10000),
	currency: z.enum(["USD", "EUR", "GBP", "JPY", "CNY", "KRW", "CAD", "AUD"]),
	claimedAmount: z
		.string()
		.trim()
		.regex(
			/^\d+(\.\d{1,2})?$/,
			"환불받고 싶은 금액을 숫자로 입력해 주세요. (예: 49.99 또는 65000)",
		),
	kind: z.enum(["refund", "exchange", "repair"]),
	issue: z
		.string()
		.trim()
		.min(5, "어떤 문제가 있었는지 우리말로 편하게 5자 이상 적어 주세요.")
		.max(3000, "설명은 3,000자 이내로 작성해 주세요."),
	issueEnglish: z.string().trim().max(3000).optional().or(z.literal("")),
});

export type ClaimWizardFormValues = z.infer<typeof claimWizardSchema>;

export const receiptFormSchema = z.object({
	kind: z.enum(["cash", "goods", "repair", "reversal"]),
	proofId: z
		.string()
		.min(1, "실제 입금·수령을 증명할 증빙 파일을 선택해 주세요."),
	receivedOn: z
		.string()
		.regex(/^\d{4}-\d{2}-\d{2}$/, "실제로 받은 날짜를 선택해 주세요."),
	amount: z.string().trim().optional().or(z.literal("")),
	quantity: z.number().int().optional(),
	transactionRef: z.string().trim().max(100).optional().or(z.literal("")),
	reverses: z.string().optional().or(z.literal("")),
	note: z.string().trim().max(2000).optional().or(z.literal("")),
	confirmed: z.boolean().refine((v) => v === true, {
		message: "실제 카드/계좌 내역과 증빙을 직접 확인했다는 체크가 필요해요.",
	}),
	missingReferenceConfirmed: z.boolean().optional(),
	duplicateReviewed: z.boolean().optional(),
});

export type ReceiptFormValues = z.infer<typeof receiptFormSchema>;
