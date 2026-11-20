/**
 * @module client/hooks/useClaims
 * @layer ViewModel (TanStack Query Claim State & Mutations)
 * @purpose Synchronizes claim detail, file vault uploads, foreign letter drafts,
 *          seller reply analysis, and bank deposit confirmation with the backend API.
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	aiApi,
	claimsApi,
	filesApi,
	inquiryApi,
} from "@/client/lib/api-client";
import type {
	ClaimMutationInput,
	ClaimTransitionAction,
	ClaimView,
	RecordReceiptInput,
	ReplyKind,
} from "@/client/types";

export const claimKeys = {
	all: ["claims"] as const,
	detail: (id: string) => ["claims", "detail", id] as const,
	template: (id: string) => ["claims", "template", id] as const,
	agent: (id: string) => ["claims", "agent", id] as const,
};

export function useClaimDetailQuery(
	claimId: string | null,
	enabled = true,
	includeDeleted = true,
) {
	return useQuery({
		queryKey: claimKeys.detail(claimId ?? ""),
		queryFn: async () => {
			if (!claimId) throw new Error("claimId required");
			const res = await claimsApi.detail(claimId, includeDeleted);
			return res.claim;
		},
		enabled: Boolean(claimId) && enabled,
	});
}

function syncClaimCache(
	queryClient: ReturnType<typeof useQueryClient>,
	claim: ClaimView,
) {
	queryClient.setQueryData(claimKeys.detail(claim.id), claim);
	queryClient.invalidateQueries({ queryKey: claimKeys.all });
}

export function useCreateClaimMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (input: ClaimMutationInput) => claimsApi.create(input),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useUpdateClaimMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			version,
			input,
		}: {
			version: number;
			input: ClaimMutationInput;
		}) => claimsApi.update(claimId, version, input),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useTransitionClaimMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			version,
			action,
			reason,
		}: {
			version: number;
			action: ClaimTransitionAction;
			reason: string;
		}) => claimsApi.transition(claimId, version, action, reason),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useTrashClaimMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ version, reason }: { version: number; reason: string }) =>
			claimsApi.moveToTrash(claimId, version, reason),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useRestoreClaimMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (version: number) => claimsApi.restore(claimId, version),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useUploadClaimFileMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			version,
			file,
			fileName,
		}: {
			version: number;
			file: File | Blob;
			fileName: string;
		}) => filesApi.upload(claimId, version, file, fileName),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useRemoveClaimFileMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ fileId, version }: { fileId: string; version: number }) =>
			filesApi.remove(claimId, fileId, version),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useSaveDraftMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			version,
			body,
			origin,
			model,
		}: {
			version: number;
			body: string;
			origin?: "ai" | "template" | "manual";
			model?: string;
		}) => inquiryApi.saveDraft(claimId, version, { body, origin, model }),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useSubmitDraftMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			version,
			draftId,
			confirmed,
			note,
		}: {
			version: number;
			draftId: string;
			confirmed: boolean;
			note?: string;
		}) =>
			inquiryApi.submitDraft(claimId, version, { draftId, confirmed, note }),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useRecordReplyMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			version,
			body,
			kind,
			translationKo,
			summaryKo,
			aiAssisted,
		}: {
			version: number;
			body: string;
			kind: ReplyKind;
			translationKo?: string;
			summaryKo?: string;
			aiAssisted?: boolean;
		}) =>
			inquiryApi.recordReply(claimId, version, {
				body,
				kind,
				translationKo,
				summaryKo,
				aiAssisted,
			}),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useRecordReceiptMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			version,
			input,
		}: {
			version: number;
			input: RecordReceiptInput;
		}) => inquiryApi.recordReceipt(claimId, version, input),
		onSuccess: ({ claim }) => syncClaimCache(queryClient, claim),
	});
}

export function useAiDraftMutation(claimId: string) {
	return useMutation({
		mutationFn: () => aiApi.generateDraft(claimId),
	});
}

/**
 * Whether the agent is at work on the claim, a proposal still waiting for the person's answer,
 * and what the last run did. While the agent is at work on its own (nobody on this screen
 * started it), this asks again every two seconds, so the result appears when it is done.
 */
export function useAgentOverviewQuery(claimId: string, enabled: boolean) {
	return useQuery({
		queryKey: claimKeys.agent(claimId),
		queryFn: () => aiApi.agentOverview(claimId),
		enabled,
		refetchInterval: (query) => (query.state.data?.working ? 2000 : false),
	});
}

/** The claims where the agent is waiting for the person's answer, for the list of claims. */
export function useAgentWaitingQuery(enabled: boolean) {
	return useQuery({
		queryKey: [...claimKeys.all, "agent-waiting"] as const,
		queryFn: async () => (await aiApi.agentWaiting()).claims,
		enabled,
		staleTime: 10 * 1000,
	});
}

/** One agent run: the AI picks which tools to use, in what order, toward the claim's goal. */
export function useAgentRunMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (locale: string) => aiApi.runAgent(claimId, locale),
		onSuccess: () =>
			queryClient.invalidateQueries({ queryKey: claimKeys.agent(claimId) }),
	});
}

/**
 * The person's answer to an action the agent proposed. An allowed action changes the claim on
 * the server, so the claim is read again before this resolves: whatever is shown next (the
 * message box, the order facts) is already the saved state.
 */
export function useAgentDecisionMutation(claimId: string) {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({
			runId,
			approve,
			locale,
		}: {
			runId: string;
			approve: boolean;
			locale: string;
		}) => aiApi.decideAgent(claimId, runId, approve, locale),
		onSettled: () => queryClient.invalidateQueries({ queryKey: claimKeys.all }),
	});
}

export function useAiAnalyzeReplyMutation(claimId: string) {
	return useMutation({
		mutationFn: (body: string) => aiApi.analyzeReply(claimId, body),
	});
}

export function useAiTranslateIssueMutation() {
	return useMutation({
		mutationFn: (text: string) => aiApi.translateIssue(text),
	});
}

/** Filing from one line: the AI reads what the person wrote against their order's items. */
export function useAiIntakeMutation() {
	return useMutation({
		mutationFn: (input: Parameters<typeof aiApi.intake>[0]) =>
			aiApi.intake(input),
	});
}

export function useAiExtractNewDocMutation() {
	return useMutation({
		mutationFn: ({ file, fileName }: { file: File | Blob; fileName: string }) =>
			aiApi.extractDocument(file, fileName),
	});
}
