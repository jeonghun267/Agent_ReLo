/**
 * @module client/types/domain
 * @layer Model (Domain Entities & Backend API Contracts)
 * @purpose Defines strict TypeScript interfaces for multi-currency claims, file proofs,
 *          foreign message drafts, seller replies, and deposit settlement entries.
 */

export type CurrencyCode =
	| "USD"
	| "EUR"
	| "GBP"
	| "JPY"
	| "CNY"
	| "KRW"
	| "CAD"
	| "AUD";

export type ClaimKind = "refund" | "exchange" | "repair";

export type ClaimState =
	| "preparing"
	| "review"
	| "awaiting"
	| "negotiating"
	| "partial"
	| "disputed"
	| "waived"
	| "recovered"
	| "completed";

export type ReplyKind =
	| "evidence"
	| "agreement"
	| "refund_notice"
	| "denied"
	| "other";

export type ReceiptKind = "cash" | "goods" | "repair" | "reversal";

export type ClaimTransitionAction =
	| "awaiting"
	| "negotiating"
	| "disputed"
	| "waived"
	| "reopen"
	| "close";

export interface User {
	id: string;
	email: string;
	name: string;
	createdAt: string;
	emailVerifiedAt: string | null;
	aiConsentAt: string | null;
}

export interface AiStatus {
	enabled: boolean;
	provider: string;
	model: string | null;
	hourlyLimit: number;
	consented?: boolean;
}

export interface MailStatus {
	enabled: boolean;
	verifyLinkHours: number;
	resetLinkMinutes: number;
}

export interface DemoAccountHint {
	email: string;
	password: string;
	name: string;
}

export interface AppConfig {
	environment: "development" | "test" | "production";
	currencies: Record<CurrencyCode, { digits: number; label: string }>;
	claimKinds: Record<ClaimKind, string>;
	states: Record<ClaimState, string>;
	replyKinds: Record<ReplyKind, string>;
	receiptKinds: Record<ReceiptKind, string>;
	deadlineZones: string[];
	files: {
		types: Record<string, string>;
		maxBytes: number;
	};
	ai: AiStatus;
	mail: MailStatus;
	demoAccount?: DemoAccountHint;
}

export interface SessionResponse {
	user: User;
	csrf: string;
	ai?: AiStatus;
}

export interface ClaimItem {
	name: string;
	sku: string;
	orderedQty: number;
	claimQty: number;
	unitPrice: number;
}

export interface ClaimFile {
	id: string;
	claimId: string;
	name: string;
	mime: string;
	size: number;
	sha: string;
	createdAt: string;
	usedAsProof: boolean;
}

export interface ClaimDraft {
	id: string;
	body: string;
	origin: "ai" | "template" | "manual";
	model: string;
	dataRev: number;
	fingerprint: string;
	createdAt: string;
	submittedAt: string | null;
	submissionNote: string;
	stale: boolean;
}

export interface ClaimReply {
	id: string;
	body: string;
	kind: ReplyKind;
	translationKo: string;
	summaryKo: string;
	aiAssisted: boolean;
	recordedAt: string;
}

export interface LedgerEntry {
	id: string;
	claimId: string;
	kind: ReceiptKind;
	amount: number;
	quantity: number;
	note: string;
	proofId: string | null;
	reverses: string | null;
	transactionRef: string;
	receivedOn: string;
	createdAt: string;
}

export interface ClaimSummaryTotals {
	cash: number;
	goods: number;
	repair: boolean;
	remaining: number;
	requestedQty: number;
}

export interface ClaimAuditEvent {
	id: string;
	action: string;
	before?: Record<string, unknown>;
	after?: Record<string, unknown>;
	createdAt: string;
}

export interface ClaimView {
	id: string;
	title: string;
	vendor: string;
	vendorUrl: string;
	orderRef: string;
	orderedOn: string;
	kind: ClaimKind;
	currency: CurrencyCode;
	items: ClaimItem[];
	claimed: number;
	agreed: number | null;
	issue: string;
	issueEnglish: string;
	deadline: string | null;
	deadlineQuote: string;
	deadlineZone: string;
	state: ClaimState;
	version: number;
	dataRev: number;
	deleted: boolean;
	deletedAt: string | null;
	createdAt: string;
	updatedAt: string;
	files: ClaimFile[];
	ledger: LedgerEntry[];
	drafts: ClaimDraft[];
	replies: ClaimReply[];
	events: ClaimAuditEvent[];
	summary: ClaimSummaryTotals;
	nextStep: string;
}

export interface ClaimMutationInput {
	title: string;
	vendor: string;
	vendorUrl?: string;
	orderRef: string;
	orderedOn: string;
	kind: ClaimKind;
	currency: CurrencyCode;
	claimedAmount: string;
	agreedAmount?: string;
	issue: string;
	issueEnglish?: string;
	deadline?: string;
	deadlineQuote?: string;
	deadlineZone?: string;
	items: Array<{
		name: string;
		sku?: string;
		orderedQty: number;
		claimQty: number;
		unitPrice: string;
	}>;
}

export interface DraftSuggestionResponse {
	origin: "ai" | "template";
	model: string;
	body: string;
	notice: string;
	summaryKo?: string;
	missingInfo?: string[];
}

export interface AiReplyAnalysisResponse {
	translationKo: string;
	summaryKo: string;
	suggestedKind: ReplyKind;
	mentionedAmount: string | null;
	mentionedCurrency: CurrencyCode | null;
	deadline: string | null;
	deadlineQuote: string | null;
	model: string;
}

export interface AiExtractedItem {
	name: string;
	orderedQty: number;
	claimQty: number;
	unitPrice: string | null;
}

export interface AiExtractionResponse {
	suggestion: {
		vendor: string | null;
		orderRef: string | null;
		orderedOn: string | null;
		currency: CurrencyCode | null;
		items: AiExtractedItem[];
	};
	orderTotal: string | null;
	fields: Array<{
		field: string;
		value: string;
		quote: string;
	}>;
	source: {
		fileId: string | null;
		name: string;
	};
	model: string;
}

export interface RecordReceiptInput {
	kind: ReceiptKind;
	proofId: string;
	receivedOn: string;
	amount?: string;
	quantity?: number;
	transactionRef?: string;
	reverses?: string;
	note?: string;
	confirmed: boolean;
	missingReferenceConfirmed?: boolean;
	duplicateReviewed?: boolean;
}
