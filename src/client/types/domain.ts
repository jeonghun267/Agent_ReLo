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
	/** When the person left their claims to the agent (it may start by itself). null = off. */
	agentAutoAt: string | null;
	/** When the person switched notice emails off ("the AI is waiting for your OK"). null = they receive them. */
	noticeMailOffAt: string | null;
}

export interface AiStatus {
	enabled: boolean;
	provider: string;
	model: string | null;
	hourlyLimit: number;
	/** The most steps one agent run may take. */
	agentMaxSteps?: number;
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
	/** Extra ways to sign in that the operator has switched on. */
	signIn?: { google: boolean; passkey: boolean };
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
	/** What to do next as a code, so each language shows its own sentence. */
	nextStepCode?: string;
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

/**
 * The tools an agent run can choose from. The first three only read or write a suggestion.
 * The last two change the claim, so the run stops and asks first. None of them sends.
 */
export type AgentTool =
	| "read_evidence"
	| "analyze_reply"
	| "write_draft"
	| "fix_order_facts"
	| "save_draft";

export type AgentEndedBy =
	| "done"
	| "max_steps"
	| "repeat"
	| "invalid_choice"
	| "rate_limited"
	| "plan_failed";

/** A saved fact an action replaces, with the value it had and the value read from the file. */
export interface AgentChange {
	field: "orderRef" | "orderedOn" | "currency";
	from: string;
	to: string;
}

/** One step of an agent run: the tool the AI chose, why, and what it returned. */
export interface AgentStep {
	seq: number;
	tool: AgentTool;
	reason: string;
	fileId: string | null;
	fileName: string | null;
	replyId: string | null;
	ok: boolean;
	errorCode: string;
	message: string;
	ms: number;
	result:
		| AiExtractionResponse
		| AiReplyAnalysisResponse
		| DraftSuggestionResponse
		| null;
	/** Saved order facts the document read in this step disagrees with. */
	mismatches: Array<{
		field: "orderRef" | "orderedOn" | "currency";
		saved: string;
		read: string;
	}>;
	/** What the person answered when this step was an action; empty for a reading tool. */
	decision: "" | "approved" | "declined";
	changes: AgentChange[];
}

/** An action the AI wants to take. Nothing happens until the person allows it. */
export interface AgentPending {
	tool: AgentTool;
	reason: string;
	fileName: string | null;
	changes: AgentChange[];
	draftBody: string | null;
}

/** What started a run: the person's button, or something that happened on the claim. */
export type AgentStartedBy = "person" | "filed" | "file" | "reply";

export interface AgentRunResponse {
	runId: string;
	/** "waiting": stopped on `pending` until the person answers. */
	status: "waiting" | "finished";
	endedBy: AgentEndedBy | null;
	startedBy: AgentStartedBy;
	maxSteps: number;
	aiCalls: number;
	reason: string;
	userAction: string | null;
	errorCode: string;
	steps: AgentStep[];
	pending: AgentPending | null;
}

/**
 * What is known when the claim is opened: whether the agent is at work right now (it started by
 * itself, or is about to), a proposal still waiting, and the last run.
 */
export interface AgentOverview {
	working: boolean;
	/** It would have started by itself, but too little of the hourly AI limit was left. */
	heldBack: boolean;
	waiting: AgentRunResponse | null;
	last: {
		endedAt: string;
		endedBy: string;
		startedBy: AgentStartedBy;
		userAction: string | null;
		steps: Array<{
			tool: AgentTool;
			ok: boolean;
			decision: "" | "approved" | "declined";
		}>;
	} | null;
}

/** A claim where the agent is stopped on a proposal, for the list of claims. */
export interface AgentWaitingItem {
	claimId: string;
	tool: AgentTool | null;
}

/**
 * Filing from one line: how the AI read what the person wrote against the items of their order
 * document. It names the kind, the item and the quantity; names and prices stay the document's.
 */
export interface AiIntakeResponse {
	kind: ClaimKind;
	itemIndex: number | null;
	claimQty: number | null;
	issueEnglish: string;
	understood: string | null;
	model: string;
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
