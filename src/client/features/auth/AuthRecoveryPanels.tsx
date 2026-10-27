/**
 * @module client/features/auth/AuthRecoveryPanels
 * @layer View (Password Reset & Email Verification Sub-Views)
 * @purpose Renders one-time password recovery, new password setup, and email verification
 *          panels in plain everyday consumer language (zero technical jargon).
 */

import { KeyRound } from "lucide-react";
import type { UseFormReturn } from "react-hook-form";
import { Button, TextField } from "@/client/components/ui/Primitives";
import type {
	ForgotPasswordFormValues,
	ResetPasswordFormValues,
} from "@/client/types";

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
	return (
		<form onSubmit={onSubmit} noValidate className="space-y-4">
			<div className="space-y-1">
				<h1 className="text-xl font-extrabold text-relo-ink">
					비밀번호 다시 만들기
				</h1>
				<p className="text-sm text-relo-muted">
					가입하신 이메일로 비밀번호 변경 안내 메일을 보내드려요.
				</p>
			</div>
			{forgotSent ? (
				<div className="rounded-xl border border-relo-brand-line bg-relo-brand-soft p-4 text-sm font-medium text-relo-brand">
					입력하신 주소로 변경 링크를 보냈어요. 메일함을 확인해 주세요.
				</div>
			) : (
				<>
					<TextField
						label="가입한 이메일"
						type="email"
						placeholder="you@example.com"
						error={form.formState.errors.email?.message}
						{...form.register("email")}
					/>
					{form.formState.errors.root?.message ? (
						<p role="alert" className="text-xs font-semibold text-relo-danger">
							{form.formState.errors.root.message}
						</p>
					) : null}
					<Button type="submit" size="lg" fullWidth isLoading={isPending}>
						<KeyRound className="h-4 w-4" aria-hidden="true" />
						<span>비밀번호 변경 링크 받기</span>
					</Button>
				</>
			)}
			<Button variant="ghost" fullWidth onClick={onBackToLogin}>
				로그인으로 돌아가기
			</Button>
		</form>
	);
}

interface ResetPasswordPanelProps {
	form: UseFormReturn<ResetPasswordFormValues>;
	isPending: boolean;
	onSubmit: () => void;
}

export function ResetPasswordPanel({
	form,
	isPending,
	onSubmit,
}: ResetPasswordPanelProps) {
	return (
		<form onSubmit={onSubmit} noValidate className="space-y-4">
			<div className="space-y-1">
				<h1 className="text-xl font-extrabold text-relo-ink">
					새 비밀번호 입력
				</h1>
				<p className="text-sm text-relo-muted">
					앞으로 사용할 새 비밀번호(10자 이상)를 입력해 주세요.
				</p>
			</div>
			<TextField
				label="새 비밀번호"
				type="password"
				autoComplete="new-password"
				placeholder="10자 이상 입력"
				error={form.formState.errors.password?.message}
				{...form.register("password")}
			/>
			{form.formState.errors.root?.message ? (
				<p role="alert" className="text-xs font-semibold text-relo-danger">
					{form.formState.errors.root.message}
				</p>
			) : null}
			<Button type="submit" size="lg" fullWidth isLoading={isPending}>
				비밀번호 변경 완료
			</Button>
		</form>
	);
}

interface EmailVerifyPanelProps {
	isPending: boolean;
	isSuccess: boolean;
	onGoWizard: () => void;
}

export function EmailVerifyPanel({
	isPending,
	isSuccess,
	onGoWizard,
}: EmailVerifyPanelProps) {
	return (
		<div className="space-y-4 text-center">
			<h1 className="text-xl font-extrabold text-relo-ink">이메일 본인 확인</h1>
			<p className="text-sm text-relo-body">
				{isPending
					? "이메일 확인 링크를 점검하고 있어요..."
					: isSuccess
						? "본인 확인이 완료되었어요! 이제 모든 알림 기능을 이용하실 수 있어요."
						: "확인 링크가 만료되었거나 이미 사용되었어요."}
			</p>
			<Button fullWidth onClick={onGoWizard}>
				환불 신청으로 이동하기
			</Button>
		</div>
	);
}
