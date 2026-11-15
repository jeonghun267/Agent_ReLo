/**
 * @module client/features/auth/AuthPage
 * @layer ViewModel / View (Consumer Login & Signup)
 * @purpose Handles B2C account login, signup and the demo quick-start, and delegates the
 *          recovery/verification flows to AuthRecoveryPanels. Every panel follows the same
 *          shape as well-known sign-in screens: one title, labelled inputs, a show-password
 *          button, one main button, and a text link to the other form.
 */

import { UserCheck } from "lucide-react";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Button,
	Card,
	PasswordField,
	TextField,
	useToast,
} from "@/client/components/ui/Primitives";
import {
	AuthHeading,
	EmailVerifyPanel,
	ForgotPasswordPanel,
	FormAlert,
	ResetPasswordPanel,
} from "@/client/features/auth/AuthRecoveryPanels";
import { ExtraSignIn } from "@/client/features/auth/ExtraSignIn";
import {
	useAppConfig,
	useForgotPasswordMutation,
	useLoginMutation,
	useResetPasswordMutation,
	useSession,
	useSignupMutation,
	useVerifyEmailMutation,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { ApiError } from "@/client/lib/api-client";
import { errorText, fieldError } from "@/client/lib/claim-words";
import { fill } from "@/client/lib/format";
import { useRouter } from "@/client/lib/router";
import { zodV4Resolver } from "@/client/lib/zod-resolver";
import {
	type ForgotPasswordFormValues,
	forgotPasswordSchema,
	type LoginFormValues,
	loginSchema,
	type ResetPasswordFormValues,
	resetPasswordSchema,
	type SignupFormValues,
	signupSchema,
} from "@/client/types";

type AuthMode = "login" | "signup" | "forgot" | "reset" | "verify";

export function AuthPage() {
	const { t, locale } = useI18n();
	const a = t.auth;
	const { search, navigate } = useRouter();
	const params = new URLSearchParams(search);
	const initialMode = (params.get("mode") as AuthMode | null) ?? "login";
	const urlToken = params.get("token") ?? "";
	const redirectTo = params.get("next") || "/wizard";
	// A Google sign-in that failed comes back here with a code in the address.
	const signInError = params.get("error");
	const signInErrors: Record<string, string> = t.signin.errors;

	const [mode, setMode] = useState<AuthMode>(initialMode);
	const [forgotSent, setForgotSent] = useState(false);

	const { data: config } = useAppConfig();
	const { data: session } = useSession();
	const { showToast } = useToast();

	const loginMutation = useLoginMutation();
	const signupMutation = useSignupMutation();
	const forgotMutation = useForgotPasswordMutation();
	const resetMutation = useResetPasswordMutation();
	const verifyMutation = useVerifyEmailMutation();

	useEffect(() => {
		const nextMode =
			(new URLSearchParams(search).get("mode") as AuthMode | null) ?? "login";
		setMode(nextMode);
	}, [search]);

	// Opening a verification link checks it once. The panel itself says how it went.
	useEffect(() => {
		if (
			mode === "verify" &&
			urlToken &&
			!verifyMutation.isPending &&
			!verifyMutation.isSuccess &&
			!verifyMutation.isError
		) {
			verifyMutation.mutateAsync(urlToken).catch(() => {});
		}
	}, [mode, urlToken, verifyMutation]);

	const loginForm = useForm<LoginFormValues>({
		resolver: zodV4Resolver(loginSchema),
		defaultValues: { email: "", password: "" },
	});

	const signupForm = useForm<SignupFormValues>({
		resolver: zodV4Resolver(signupSchema),
		defaultValues: { name: "", email: "", password: "" },
	});

	const forgotForm = useForm<ForgotPasswordFormValues>({
		resolver: zodV4Resolver(forgotPasswordSchema),
		defaultValues: { email: "" },
	});

	const resetForm = useForm<ResetPasswordFormValues>({
		resolver: zodV4Resolver(resetPasswordSchema),
		defaultValues: { password: "" },
	});

	const onLoginSubmit = loginForm.handleSubmit(async (values) => {
		try {
			const res = await loginMutation.mutateAsync(values);
			showToast(fill(a.toastWelcomeBack, { name: res.user.name }));
			navigate(redirectTo, { replace: true });
		} catch (error) {
			const message = errorText(error, a.loginFail, locale);
			if (error instanceof ApiError && error.field === "email") {
				loginForm.setError("email", { message });
				return;
			}
			loginForm.setError("root", { message });
		}
	});

	const onSignupSubmit = signupForm.handleSubmit(async (values) => {
		try {
			const res = await signupMutation.mutateAsync(values);
			showToast(fill(a.toastWelcome, { name: res.user.name }));
			navigate(redirectTo, { replace: true });
		} catch (error) {
			if (error instanceof ApiError && error.field === "email") {
				signupForm.setError("email", {
					message: errorText(error, a.signupEmailFail, locale),
				});
				return;
			}
			if (error instanceof ApiError && error.field === "password") {
				signupForm.setError("password", {
					message: errorText(error, a.signupPasswordFail, locale),
				});
				return;
			}
			signupForm.setError("root", {
				message: errorText(error, a.signupFail, locale),
			});
		}
	});

	const onForgotSubmit = forgotForm.handleSubmit(async (values) => {
		try {
			await forgotMutation.mutateAsync(values.email);
			setForgotSent(true);
			showToast(a.forgot.toastSent);
		} catch (error) {
			forgotForm.setError("root", {
				message: errorText(error, a.forgot.fail, locale),
			});
		}
	});

	const onResetSubmit = resetForm.handleSubmit(async (values) => {
		try {
			await resetMutation.mutateAsync({
				token: urlToken,
				password: values.password,
			});
			showToast(a.reset.toastDone);
			navigate("/auth?mode=login", { replace: true });
		} catch (error) {
			resetForm.setError("root", {
				message: errorText(error, a.reset.fail, locale),
			});
		}
	});

	const handleDemoQuickLogin = async () => {
		if (!config?.demoAccount) return;
		try {
			const res = await loginMutation.mutateAsync({
				email: config.demoAccount.email,
				password: config.demoAccount.password,
			});
			showToast(fill(a.toastDemo, { name: res.user.name }));
			navigate(redirectTo, { replace: true });
		} catch (error) {
			showToast(errorText(error, a.toastDemoFail, locale), "error");
		}
	};

	if (session?.user && mode !== "verify" && mode !== "reset") {
		return (
			<div className="mx-auto max-w-md px-4 pt-10">
				<Card className="space-y-5 text-center">
					<ReloOrbEmblem
						size="md"
						speech={fill(a.alreadyIn, { name: session.user.name })}
					/>
					<div className="space-y-2">
						<Button fullWidth size="lg" onClick={() => navigate("/wizard")}>
							{t.nav.applyCta}
						</Button>
						<Button
							fullWidth
							variant="secondary"
							onClick={() => navigate("/claims")}
						>
							{t.nav.myRefunds}
						</Button>
					</div>
				</Card>
			</div>
		);
	}

	const isEntry = mode === "login" || mode === "signup";

	return (
		<div className="mx-auto max-w-md px-4 pt-8 sm:pt-12">
			<Card className="w-full space-y-6 p-6 sm:p-8">
				<ReloOrbEmblem
					size="sm"
					variant={
						mode !== "verify"
							? "still"
							: verifyMutation.isPending
								? "processing"
								: verifyMutation.isSuccess
									? "verified"
									: "still"
					}
				/>

				{mode === "login" ? (
					<form onSubmit={onLoginSubmit} noValidate className="space-y-5">
						<AuthHeading title={a.loginTitle} sub={a.loginSub} />
						<FormAlert
							message={
								signInError
									? (signInErrors[signInError] ?? t.signin.errors.other)
									: undefined
							}
						/>
						<TextField
							label={a.emailLabel}
							type="email"
							inputMode="email"
							autoComplete="username"
							placeholder={a.emailPlaceholder}
							error={fieldError(t, loginForm.formState.errors.email?.message)}
							{...loginForm.register("email")}
						/>
						<PasswordField
							label={a.passwordLabel}
							autoComplete="current-password"
							showLabel={a.showPassword}
							hideLabel={a.hidePassword}
							error={fieldError(
								t,
								loginForm.formState.errors.password?.message,
							)}
							{...loginForm.register("password")}
						/>
						<FormAlert message={loginForm.formState.errors.root?.message} />
						<Button
							type="submit"
							size="lg"
							fullWidth
							isLoading={loginMutation.isPending}
						>
							{a.loginSubmit}
						</Button>
						<div className="text-center">
							<button
								type="button"
								onClick={() => {
									setForgotSent(false);
									setMode("forgot");
								}}
								className="inline-flex min-h-11 cursor-pointer items-center text-sm font-semibold text-relo-muted underline underline-offset-4 hover:text-relo-brand"
							>
								{a.forgotLink}
							</button>
						</div>
					</form>
				) : null}

				{mode === "signup" ? (
					<form onSubmit={onSignupSubmit} noValidate className="space-y-5">
						<AuthHeading title={a.signupTitle} sub={a.signupSub} />
						<TextField
							label={a.nameLabel}
							type="text"
							autoComplete="name"
							placeholder={a.namePlaceholder}
							error={fieldError(t, signupForm.formState.errors.name?.message)}
							{...signupForm.register("name")}
						/>
						<TextField
							label={a.emailLabel}
							type="email"
							inputMode="email"
							autoComplete="email"
							placeholder={a.emailPlaceholder}
							error={fieldError(t, signupForm.formState.errors.email?.message)}
							{...signupForm.register("email")}
						/>
						<PasswordField
							label={a.passwordLabel}
							autoComplete="new-password"
							hint={a.passwordHint}
							showLabel={a.showPassword}
							hideLabel={a.hidePassword}
							error={fieldError(
								t,
								signupForm.formState.errors.password?.message,
							)}
							{...signupForm.register("password")}
						/>
						<FormAlert message={signupForm.formState.errors.root?.message} />
						<Button
							type="submit"
							size="lg"
							fullWidth
							isLoading={signupMutation.isPending}
						>
							{a.signupSubmit}
						</Button>
						<p className="text-center text-xs leading-relaxed text-relo-muted">
							{a.privacyNote}
						</p>
					</form>
				) : null}

				{mode === "forgot" ? (
					<ForgotPasswordPanel
						form={forgotForm}
						forgotSent={forgotSent}
						isPending={forgotMutation.isPending}
						onSubmit={onForgotSubmit}
						onBackToLogin={() => setMode("login")}
					/>
				) : null}

				{mode === "reset" ? (
					<ResetPasswordPanel
						form={resetForm}
						isPending={resetMutation.isPending}
						onSubmit={onResetSubmit}
						onRequestAgain={() => {
							setForgotSent(false);
							setMode("forgot");
						}}
					/>
				) : null}

				{mode === "verify" ? (
					<EmailVerifyPanel
						isPending={verifyMutation.isPending}
						isSuccess={verifyMutation.isSuccess}
						isLoggedIn={Boolean(session?.user)}
						onGoWizard={() => navigate("/wizard")}
						onGoLogin={() => navigate("/auth?mode=login")}
						onGoClaims={() => navigate("/claims")}
					/>
				) : null}

				{isEntry ? (
					<div className="space-y-4 border-t border-relo-line pt-5">
						{/* The way to the other form is a line of text, not a second button */}
						<p className="text-center text-sm text-relo-muted">
							{mode === "login" ? a.toSignupLead : a.toLoginLead}{" "}
							<button
								type="button"
								onClick={() => setMode(mode === "login" ? "signup" : "login")}
								className="inline-flex min-h-11 cursor-pointer items-center font-bold text-relo-brand hover:underline"
							>
								{mode === "login" ? a.toSignup : a.toLogin}
							</button>
						</p>

						<ExtraSignIn redirectTo={redirectTo} />

						{config?.demoAccount ? (
							<Button
								variant="secondary"
								fullWidth
								isLoading={loginMutation.isPending}
								onClick={handleDemoQuickLogin}
							>
								<UserCheck className="h-4 w-4" aria-hidden="true" />
								<span>{a.demoButton}</span>
							</Button>
						) : null}
					</div>
				) : null}
			</Card>
		</div>
	);
}
