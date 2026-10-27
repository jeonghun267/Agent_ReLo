/**
 * @module client/lib/api-client
 * @layer Service / Repository (Typed HTTP Client)
 * @purpose Encapsulates CSRF headers, optimistic concurrency (If-Match / version),
 *          idempotency keys, and typed endpoints for `/api/*`.
 */

import type {
	AiExtractionResponse,
	AiReplyAnalysisResponse,
	AppConfig,
	ClaimMutationInput,
	ClaimTransitionAction,
	ClaimView,
	DraftSuggestionResponse,
	LoginFormValues,
	RecordReceiptInput,
	ReplyKind,
	SessionResponse,
	SignupFormValues,
	User,
} from "@/client/types";

export class ApiError extends Error {
	readonly code: string;
	readonly status: number;
	readonly field: string | null;

	constructor(
		message: string,
		code: string,
		status: number,
		field: string | null = null,
	) {
		super(message);
		this.name = "ApiError";
		this.code = code;
		this.status = status;
		this.field = field;
	}
}

interface RequestOptions {
	method?: "GET" | "POST" | "PATCH" | "DELETE";
	data?: unknown;
	raw?: BodyInit;
	headers?: Record<string, string>;
	idempotencyKey?: string;
	version?: number;
	quiet?: boolean;
	signal?: AbortSignal;
}

type UnauthorizedListener = () => void;

let csrfToken = "";
const unauthorizedListeners = new Set<UnauthorizedListener>();

export function setCsrfToken(token: string | null | undefined): void {
	csrfToken = token ?? "";
}

export function getCsrfToken(): string {
	return csrfToken;
}

export function onUnauthorized(listener: UnauthorizedListener): () => void {
	unauthorizedListeners.add(listener);
	return () => {
		unauthorizedListeners.delete(listener);
	};
}

export function newIdempotencyKey(): string {
	return crypto.randomUUID();
}

export async function apiRequest<TResponse>(
	path: string,
	options: RequestOptions = {},
): Promise<TResponse> {
	const {
		method = "GET",
		data,
		raw,
		headers = {},
		idempotencyKey,
		version,
		quiet = false,
		signal,
	} = options;

	const requestHeaders: Record<string, string> = { ...headers };
	if (data !== undefined) {
		requestHeaders["Content-Type"] = "application/json";
	}
	if (method !== "GET" && csrfToken) {
		requestHeaders["X-CSRF-Token"] = csrfToken;
	}
	if (idempotencyKey) {
		requestHeaders["Idempotency-Key"] = idempotencyKey;
	}
	if (version !== undefined) {
		requestHeaders["If-Match"] = String(version);
	}

	let response: Response;
	try {
		response = await fetch(path, {
			method,
			headers: requestHeaders,
			body: raw ?? (data === undefined ? undefined : JSON.stringify(data)),
			credentials: "same-origin",
			cache: "no-store",
			signal,
		});
	} catch (error) {
		if (error instanceof DOMException && error.name === "AbortError") {
			throw new ApiError("요청을 취소했어요.", "cancelled", 0);
		}
		throw new ApiError(
			"백엔드 서버(127.0.0.1:4180)에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.",
			"network",
			0,
		);
	}

	const contentType = response.headers.get("content-type") ?? "";
	const isJson = contentType.includes("application/json");
	const payload = isJson ? await response.json() : await response.blob();

	if (!response.ok) {
		if (response.status === 401 && !quiet) {
			for (const listener of unauthorizedListeners) {
				listener();
			}
		}
		const errBody = isJson ? (payload as Record<string, unknown>) : null;
		throw new ApiError(
			typeof errBody?.message === "string"
				? errBody.message
				: "요청을 처리하지 못했어요.",
			typeof errBody?.error === "string" ? errBody.error : "error",
			response.status,
			typeof errBody?.field === "string" ? errBody.field : null,
		);
	}

	if (isJson && payload && typeof payload === "object" && "csrf" in payload) {
		const nextCsrf = (payload as { csrf?: unknown }).csrf;
		if (typeof nextCsrf === "string") {
			csrfToken = nextCsrf;
		}
	}

	return payload as TResponse;
}

export const metaApi = {
	health: () => apiRequest<{ ok: boolean }>("/api/health", { quiet: true }),
	config: () => apiRequest<AppConfig>("/api/config", { quiet: true }),
	me: () => apiRequest<SessionResponse>("/api/me", { quiet: true }),
};

export const authApi = {
	signup: (input: SignupFormValues) =>
		apiRequest<SessionResponse>("/api/auth/signup", {
			method: "POST",
			data: input,
		}),
	login: (input: LoginFormValues) =>
		apiRequest<SessionResponse>("/api/auth/login", {
			method: "POST",
			data: input,
		}),
	logout: () =>
		apiRequest<{ ok: boolean }>("/api/auth/logout", { method: "POST" }),
	verifyEmail: (token: string) =>
		apiRequest<{ ok: boolean }>("/api/auth/verify", {
			method: "POST",
			data: { token },
			quiet: true,
		}),
	resendVerification: () =>
		apiRequest<{ sent: boolean }>("/api/auth/verify/resend", {
			method: "POST",
		}),
	forgotPassword: (email: string) =>
		apiRequest<{ ok: boolean }>("/api/auth/forgot", {
			method: "POST",
			data: { email },
			quiet: true,
		}),
	resetPassword: (token: string, password: string) =>
		apiRequest<{ ok: boolean }>("/api/auth/reset", {
			method: "POST",
			data: { token, password },
			quiet: true,
		}),
};

export const claimsApi = {
	list: (params?: { q?: string; state?: string; deleted?: boolean }) => {
		const search = new URLSearchParams();
		if (params?.q) search.set("q", params.q);
		if (params?.state) search.set("state", params.state);
		if (params?.deleted) search.set("deleted", "1");
		const qs = search.toString();
		return apiRequest<{ claims: ClaimView[] }>(
			`/api/claims${qs ? `?${qs}` : ""}`,
		);
	},
	detail: (id: string, includeDeleted = false) =>
		apiRequest<{ claim: ClaimView }>(
			`/api/claims/${encodeURIComponent(id)}${includeDeleted ? "?deleted=1" : ""}`,
		),
	create: (input: ClaimMutationInput, idempotencyKey = newIdempotencyKey()) =>
		apiRequest<{ claim: ClaimView }>("/api/claims", {
			method: "POST",
			data: input,
			idempotencyKey,
		}),
	update: (id: string, version: number, input: ClaimMutationInput) =>
		apiRequest<{ claim: ClaimView }>(`/api/claims/${encodeURIComponent(id)}`, {
			method: "PATCH",
			version,
			data: input,
		}),
	transition: (
		id: string,
		version: number,
		action: ClaimTransitionAction,
		reason: string,
	) =>
		apiRequest<{ claim: ClaimView }>(
			`/api/claims/${encodeURIComponent(id)}/transition`,
			{
				method: "POST",
				version,
				data: { action, reason },
			},
		),
	moveToTrash: (id: string, version: number, reason: string) =>
		apiRequest<{ claim: ClaimView }>(`/api/claims/${encodeURIComponent(id)}`, {
			method: "DELETE",
			version,
			data: { reason },
		}),
	restore: (id: string, version: number) =>
		apiRequest<{ claim: ClaimView }>(
			`/api/claims/${encodeURIComponent(id)}/restore`,
			{
				method: "POST",
				version,
			},
		),
};

export const filesApi = {
	upload: (
		claimId: string,
		version: number,
		file: File | Blob,
		fileName: string,
		idempotencyKey = newIdempotencyKey(),
	) =>
		apiRequest<{ claim: ClaimView; fileId: string; duplicate: boolean }>(
			`/api/claims/${encodeURIComponent(claimId)}/files`,
			{
				method: "POST",
				version,
				idempotencyKey,
				raw: file,
				headers: {
					"Content-Type": file.type || "application/octet-stream",
					"X-File-Name": encodeURIComponent(fileName),
				},
			},
		),
	remove: (claimId: string, fileId: string, version: number) =>
		apiRequest<{ claim: ClaimView }>(
			`/api/claims/${encodeURIComponent(claimId)}/files/${encodeURIComponent(fileId)}`,
			{
				method: "DELETE",
				version,
			},
		),
	downloadBlob: (fileId: string) =>
		apiRequest<Blob>(`/api/files/${encodeURIComponent(fileId)}`),
	fileUrl: (fileId: string) => `/api/files/${encodeURIComponent(fileId)}`,
};

export const inquiryApi = {
	getTemplate: (claimId: string) =>
		apiRequest<DraftSuggestionResponse>(
			`/api/claims/${encodeURIComponent(claimId)}/draft-template`,
		),
	saveDraft: (
		claimId: string,
		version: number,
		input: {
			body: string;
			origin?: "ai" | "template" | "manual";
			model?: string;
		},
		idempotencyKey = newIdempotencyKey(),
	) =>
		apiRequest<{ claim: ClaimView }>(
			`/api/claims/${encodeURIComponent(claimId)}/drafts`,
			{
				method: "POST",
				version,
				idempotencyKey,
				data: input,
			},
		),
	submitDraft: (
		claimId: string,
		version: number,
		input: { draftId: string; confirmed: boolean; note?: string },
		idempotencyKey = newIdempotencyKey(),
	) =>
		apiRequest<{ claim: ClaimView }>(
			`/api/claims/${encodeURIComponent(claimId)}/drafts/submit`,
			{
				method: "POST",
				version,
				idempotencyKey,
				data: input,
			},
		),
	recordReply: (
		claimId: string,
		version: number,
		input: {
			body: string;
			kind: ReplyKind;
			translationKo?: string;
			summaryKo?: string;
			aiAssisted?: boolean;
		},
	) =>
		apiRequest<{ claim: ClaimView }>(
			`/api/claims/${encodeURIComponent(claimId)}/replies`,
			{
				method: "POST",
				version,
				data: input,
			},
		),
	recordReceipt: (
		claimId: string,
		version: number,
		input: RecordReceiptInput,
		idempotencyKey = newIdempotencyKey(),
	) =>
		apiRequest<{ claim: ClaimView; receiptId: string; duplicate: boolean }>(
			`/api/claims/${encodeURIComponent(claimId)}/receipts`,
			{
				method: "POST",
				version,
				idempotencyKey,
				data: input,
			},
		),
};

export const aiApi = {
	translateIssue: (text: string) =>
		apiRequest<{ english: string; model: string }>("/api/ai/translate-issue", {
			method: "POST",
			data: { text },
		}),
	extractDocument: (file: File | Blob, fileName: string) =>
		apiRequest<AiExtractionResponse>("/api/ai/extract", {
			method: "POST",
			raw: file,
			headers: {
				"Content-Type": file.type || "application/octet-stream",
				"X-File-Name": encodeURIComponent(fileName),
			},
		}),
	extractClaimFile: (claimId: string, fileId: string) =>
		apiRequest<AiExtractionResponse>(
			`/api/claims/${encodeURIComponent(claimId)}/ai/extract`,
			{
				method: "POST",
				data: { fileId },
			},
		),
	generateDraft: (claimId: string) =>
		apiRequest<DraftSuggestionResponse>(
			`/api/claims/${encodeURIComponent(claimId)}/ai/draft`,
			{
				method: "POST",
			},
		),
	analyzeReply: (claimId: string, body: string) =>
		apiRequest<AiReplyAnalysisResponse>(
			`/api/claims/${encodeURIComponent(claimId)}/ai/analyze-reply`,
			{
				method: "POST",
				data: { body },
			},
		),
};

export const accountApi = {
	setAiConsent: (consent: boolean) =>
		apiRequest<{ user: User }>("/api/account/ai-consent", {
			method: "POST",
			data: { consent },
		}),
	exportData: () => apiRequest<Record<string, unknown>>("/api/account/export"),
	deleteAccount: (password: string) =>
		apiRequest<{ ok: boolean }>("/api/account/delete", {
			method: "POST",
			data: { password },
		}),
};
