/**
 * @module client/features/auth/ExtraSignIn
 * @layer View (Login — Other Ways To Sign In)
 * @purpose The "Continue with Google" link and the "Log in with a passkey" button. Each one
 *          is shown only when the server reports it switched on (GOOGLE_CLIENT_ID/SECRET,
 *          PASSKEY_RP_ID), so with neither set this renders nothing.
 */

import { KeyRound } from "lucide-react";
import { Button, useToast } from "@/client/components/ui/Primitives";
import {
	useAppConfig,
	usePasskeyLoginMutation,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { errorText } from "@/client/lib/claim-words";
import { fill } from "@/client/lib/format";
import { passkeysSupported } from "@/client/lib/passkey";
import { useRouter } from "@/client/lib/router";

/** Google's "G" mark, as its sign-in branding asks for on a "Continue with Google" button. */
function GoogleMark() {
	return (
		<svg viewBox="0 0 48 48" className="h-4.5 w-4.5" aria-hidden="true">
			<path
				fill="#EA4335"
				d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
			/>
			<path
				fill="#4285F4"
				d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
			/>
			<path
				fill="#FBBC05"
				d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
			/>
			<path
				fill="#34A853"
				d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
			/>
		</svg>
	);
}

export function ExtraSignIn({ redirectTo }: { redirectTo: string }) {
	const { t, locale } = useI18n();
	const { navigate } = useRouter();
	const { data: config } = useAppConfig();
	const { showToast } = useToast();
	const passkeyMutation = usePasskeyLoginMutation();

	const showGoogle = Boolean(config?.signIn?.google);
	const showPasskey = Boolean(config?.signIn?.passkey) && passkeysSupported();
	if (!showGoogle && !showPasskey) return null;

	const handlePasskeyLogin = async () => {
		try {
			const res = await passkeyMutation.mutateAsync();
			showToast(fill(t.auth.toastWelcomeBack, { name: res.user.name }));
			navigate(redirectTo, { replace: true });
		} catch (error) {
			// Closing the device's prompt is a choice, not a failure worth a message.
			if (error instanceof DOMException && error.name === "NotAllowedError") {
				return;
			}
			showToast(errorText(error, t.signin.passkeyFail, locale), "error");
		}
	};

	return (
		<>
			{showGoogle ? (
				// A plain link: the browser leaves for Google and comes back signed in.
				<a
					href={`/api/auth/google/start?next=${encodeURIComponent(redirectTo)}`}
					className="flex min-h-11 w-full items-center justify-center gap-2 rounded-2xl border border-relo-line-strong bg-white px-4.5 py-2.5 text-sm font-semibold text-relo-ink transition-colors hover:bg-relo-sunken"
				>
					<GoogleMark />
					<span>{t.signin.googleButton}</span>
				</a>
			) : null}

			{showPasskey ? (
				<Button
					variant="secondary"
					fullWidth
					isLoading={passkeyMutation.isPending}
					onClick={handlePasskeyLogin}
				>
					<KeyRound className="h-4 w-4" aria-hidden="true" />
					<span>{t.signin.passkeyButton}</span>
				</Button>
			) : null}
		</>
	);
}
