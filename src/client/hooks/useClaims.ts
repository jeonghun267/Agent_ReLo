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

export function useAiExtractNewDocMutation() {
	return useMutation({
		mutationFn: ({ file, fileName }: { file: File | Blob; fileName: string }) =>
			aiApi.extractDocument(file, fileName),
	});
}
