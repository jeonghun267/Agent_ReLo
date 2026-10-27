/**
 * @module client/hooks/useSession
 * @layer ViewModel (Authentication, Session & Claims List Queries)
 * @purpose Manages authenticated consumer session state, CSRF lifecycle, AI consent,
 *          and user-isolated claims list queries.
 */

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import {
	ApiError,
	accountApi,
	authApi,
	claimsApi,
	metaApi,
	onUnauthorized,
	setCsrfToken,
} from "@/client/lib/api-client";
import type {
	LoginFormValues,
	SessionResponse,
	SignupFormValues,
} from "@/client/types";

export const queryKeys = {
	config: ["meta", "config"] as const,
	session: ["auth", "session"] as const,
	claims: (filter?: { q?: string; state?: string; deleted?: boolean }) =>
		["claims", "list", filter ?? {}] as const,
};

export function useAppConfig() {
	return useQuery({
		queryKey: queryKeys.config,
		queryFn: metaApi.config,
		staleTime: 5 * 60 * 1000,
		retry: 1,
	});
}

export function useSession() {
	const queryClient = useQueryClient();

	useEffect(() => {
		return onUnauthorized(() => {
			setCsrfToken("");
			queryClient.setQueryData(queryKeys.session, null);
		});
	}, [queryClient]);

	return useQuery<SessionResponse | null>({
		queryKey: queryKeys.session,
		queryFn: async () => {
			try {
				const session = await metaApi.me();
				setCsrfToken(session.csrf);
				return session;
			} catch (error) {
				if (error instanceof ApiError && error.status === 401) {
					setCsrfToken("");
					return null;
				}
				throw error;
			}
		},
		staleTime: 60 * 1000,
		retry: false,
	});
}

export function useLoginMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (input: LoginFormValues) => authApi.login(input),
		onSuccess: (session) => {
			setCsrfToken(session.csrf);
			queryClient.setQueryData(queryKeys.session, session);
			queryClient.invalidateQueries({ queryKey: ["claims"] });
		},
	});
}

export function useSignupMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (input: SignupFormValues) => authApi.signup(input),
		onSuccess: (session) => {
			setCsrfToken(session.csrf);
			queryClient.setQueryData(queryKeys.session, session);
			queryClient.invalidateQueries({ queryKey: ["claims"] });
		},
	});
}

export function useLogoutMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: () => authApi.logout(),
		onSettled: () => {
			setCsrfToken("");
			queryClient.setQueryData(queryKeys.session, null);
			queryClient.removeQueries({ queryKey: ["claims"] });
		},
	});
}

export function useForgotPasswordMutation() {
	return useMutation({
		mutationFn: (email: string) => authApi.forgotPassword(email),
	});
}

export function useResetPasswordMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: ({ token, password }: { token: string; password: string }) =>
			authApi.resetPassword(token, password),
		onSuccess: () => {
			setCsrfToken("");
			queryClient.setQueryData(queryKeys.session, null);
		},
	});
}

export function useVerifyEmailMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (token: string) => authApi.verifyEmail(token),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: queryKeys.session });
		},
	});
}

export function useResendVerificationMutation() {
	return useMutation({
		mutationFn: () => authApi.resendVerification(),
	});
}

export function useAiConsentMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (consent: boolean) => accountApi.setAiConsent(consent),
		onSuccess: () => {
			queryClient.invalidateQueries({ queryKey: queryKeys.session });
		},
	});
}

export function useDeleteAccountMutation() {
	const queryClient = useQueryClient();
	return useMutation({
		mutationFn: (password: string) => accountApi.deleteAccount(password),
		onSuccess: () => {
			setCsrfToken("");
			queryClient.setQueryData(queryKeys.session, null);
			queryClient.removeQueries({ queryKey: ["claims"] });
		},
	});
}

export function useMyClaims(enabled: boolean) {
	return useQuery({
		queryKey: queryKeys.claims(),
		queryFn: () => claimsApi.list(),
		enabled,
		staleTime: 15 * 1000,
	});
}

export function useClaimsQuery(
	filter?: { q?: string; state?: string; deleted?: boolean },
	enabled = true,
) {
	return useQuery({
		queryKey: queryKeys.claims(filter),
		queryFn: () => claimsApi.list(filter),
		enabled,
		staleTime: 10 * 1000,
	});
}
