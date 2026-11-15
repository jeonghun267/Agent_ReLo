/**
 * @module client/features/auth/AuthRecoveryPanels
 * @layer View (Password Reset & Email Verification Sub-Views)
 * @purpose Renders the password recovery, new password, and email verification panels in
 *          the reader's language. Each panel is one title, one sentence and one main button.
 */

import type { UseFormReturn } from "react-hook-form";
import {
	Button,
	PasswordField,
	TextField,
} from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { fieldError } from "@/client/lib/claim-words";
import type {
	ForgotPasswordFormValues,
	ResetPasswordFormValues,
} from "@/client/types";

/** The title and the one sentence under it, shared by every panel of the account screens. */
export function AuthHeading({ title, sub }: { title: string; sub: string }) {
	return (
		<div className="space-y-1.5 text-center">
			<h1 className="text-2xl font-bold tracking-[-0.03em] text-relo-ink">
				{title}
			</h1>
			<p className="text-sm leading-relaxed text-relo-muted">{sub}</p>
		</div>
	);
}

/** What went wrong with the whole form (not one input), shown above the main button. */
export function FormAlert({ message }: { message?: string }) {
	if (!message) return null;
	return (
		<p
			role="alert"
			className="rounded-xl bg-relo-danger-soft px-3.5 py-2.5 text-xs font-semibold text-relo-danger"
		>
			{message}
		</p>
	);
}

interface ForgotPasswordPanelProps {
	form: UseFormReturn<ForgotPasswordFormValues>;
	forgotSent: boolean;
	isPending: boolean;
	onSubmit: () => void;
	onBackToLogin: () => void;
}

export function ForgotPasswordPanel({
	form,
	forgotSent,
	isPending,
	onSubmit,
	onBackToLogin,
}: ForgotPasswordPanelProps) {
	const { t } = useI18n();
	const f = t.auth.forgot;

	return (
		<form onSubmit={onSubmit} noValidate className="space-y-5">
			<AuthHeading title={f.title} sub={forgotSent ? f.sent : f.sub} />
			{forgotSent ? null : (
				<>
					<TextField
						label={f.emailLabel}
						type="email"
						inputMode="email"
						autoComplete="username"
						placeholder={t.auth.emailPlaceholder}
						error={fieldError(t, form.formState.errors.email?.message)}
						{...form.register("email")}
					/>
					<FormAlert message={form.formState.errors.root?.message} />
					<Button type="submit" size="lg" fullWidth isLoading={isPending}>
						{f.submit}
					</Button>
				</>
			)}
			<Button
				variant={forgotSent ? "primary" : "ghost"}
				size={forgotSent ? "lg" : "md"}
				fullWidth
				onClick={onBackToLogin}
			>
				{f.back}
			</Button>
		</form>
	);
}

interface ResetPasswordPanelProps {
	form: UseFormReturn<ResetPasswordFormValues>;
	isPending: boolean;
	onSubmit: () => void;
	onRequestAgain: () => void;
}

export function ResetPasswordPanel({
	form,
	isPending,
	onSubmit,
	onRequestAgain,
}: ResetPasswordPanelProps) {
	const { t } = useI18n();
	const r = t.auth.reset;

	return (
		<form onSubmit={onSubmit} noValidate className="space-y-5">
			<AuthHeading title={r.title} sub={r.sub} />
			<PasswordField
				label={r.label}
				autoComplete="new-password"
				hint={t.auth.passwordHint}
				showLabel={t.auth.showPassword}
				hideLabel={t.auth.hidePassword}
				error={fieldError(t, form.formState.errors.password?.message)}
				{...form.register("password")}
			/>
			<FormAlert message={form.formState.errors.root?.message} />
			<Button type="submit" size="lg" fullWidth isLoading={isPending}>
				{r.submit}
			</Button>
			{/* When the link turns out to be old or used, the way to a new one is right here. */}
			{form.formState.errors.root?.message ? (
				<Button variant="ghost" fullWidth onClick={onRequestAgain}>
					{t.auth.forgot.submit}
				</Button>
			) : null}
		</form>
	);
}

interface EmailVerifyPanelProps {
	isPending: boolean;
	isSuccess: boolean;
	isLoggedIn: boolean;
	onGoWizard: () => void;
	onGoLogin: () => void;
	onGoClaims: () => void;
}

/**
 * The result of opening a verification link. The button leads to what makes sense next:
 * a refund request once verified, otherwise the place where a new link can be asked for.
 */
export function EmailVerifyPanel({
	isPending,
	isSuccess,
	isLoggedIn,
	onGoWizard,
	onGoLogin,
	onGoClaims,
}: EmailVerifyPanelProps) {
	const { t } = useI18n();
	const v = t.auth.verify;

	return (
		<div className="space-y-5">
			<AuthHeading
				title={v.title}
				sub={isPending ? v.pending : isSuccess ? v.success : v.fail}
			/>
			{isPending ? null : isSuccess ? (
				<Button size="lg" fullWidth onClick={onGoWizard}>
					{v.goWizard}
				</Button>
			) : isLoggedIn ? (
				<Button size="lg" fullWidth onClick={onGoClaims}>
					{v.goClaims}
				</Button>
			) : (
				<Button size="lg" fullWidth onClick={onGoLogin}>
					{v.goLogin}
				</Button>
			)}
		</div>
	);
}
