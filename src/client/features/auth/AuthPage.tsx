/**
 * @module client/features/auth/AuthPage
 * @layer ViewModel / View (Consumer Login & 10-Second Signup)
 * @purpose Handles B2C account login, quick signup, demo consumer quick-start,
 *          and delegates recovery/verification flows to AuthRecoveryPanels.
 */

import { Check, Lock, ShieldCheck, Sparkles, UserCheck } from "lucide-react";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Button,
	Card,
	TextField,
	useToast,
} from "@/client/components/ui/Primitives";
import {
	EmailVerifyPanel,
	ForgotPasswordPanel,
	ResetPasswordPanel,
} from "@/client/features/auth/AuthRecoveryPanels";
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
	const { t } = useI18n();
	const { search, navigate } = useRouter();
	const params = new URLSearchParams(search);
	const initialMode = (params.get("mode") as AuthMode | null) ?? "login";
	const urlToken = params.get("token") ?? "";
	const redirectTo = params.get("next") || "/wizard";

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

	useEffect(() => {
		if (
			mode === "verify" &&
			urlToken &&
			!verifyMutation.isPending &&
			!verifyMutation.isSuccess &&
			!verifyMutation.isError
		) {
			verifyMutation
				.mutateAsync(urlToken)
				.then(() => {
					showToast("이메일 확인이 완료되었어요!");
				})
				.catch((error) => {
					showToast(
						error instanceof Error
							? error.message
							: "확인 링크를 다시 살펴봐 주세요.",
						"error",
					);
				});
		}
	}, [mode, urlToken, verifyMutation, showToast]);

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
			showToast(`반가워요, ${res.user.name}님!`);
			navigate(redirectTo, { replace: true });
		} catch (error) {
			if (error instanceof ApiError && error.field === "email") {
				loginForm.setError("email", { message: error.message });
				return;
			}
			loginForm.setError("root", {
				message:
					error instanceof Error ? error.message : "로그인에 실패했어요.",
			});
		}
	});

	const onSignupSubmit = signupForm.handleSubmit(async (values) => {
		try {
			const res = await signupMutation.mutateAsync(values);
			showToast(
				`환영해요, ${res.user.name}님! 이제 환불 신청을 시작해 볼까요?`,
			);
			navigate(redirectTo, { replace: true });
		} catch (error) {
			if (
				error instanceof ApiError &&
				(error.field === "email" || error.field === "password")
			) {
				signupForm.setError(error.field, { message: error.message });
				return;
			}
			signupForm.setError("root", {
				message:
					error instanceof Error ? error.message : "회원가입에 실패했어요.",
			});
		}
	});

	const onForgotSubmit = forgotForm.handleSubmit(async (values) => {
		try {
			await forgotMutation.mutateAsync(values.email);
			setForgotSent(true);
			showToast("비밀번호 변경 안내 메일을 보냈어요.");
		} catch (error) {
			forgotForm.setError("root", {
				message:
					error instanceof Error ? error.message : "요청을 처리하지 못했어요.",
			});
		}
	});

	const onResetSubmit = resetForm.handleSubmit(async (values) => {
		try {
			await resetMutation.mutateAsync({
				token: urlToken,
				password: values.password,
			});
			showToast("새 비밀번호로 변경되었어요. 다시 로그인해 주세요!");
			navigate("/auth?mode=login", { replace: true });
		} catch (error) {
			resetForm.setError("root", {
				message:
					error instanceof Error
						? error.message
						: "비밀번호 변경에 실패했어요.",
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
			showToast(`${res.user.name} 계정으로 바로 시작했어요!`);
			navigate(redirectTo, { replace: true });
		} catch (error) {
			showToast(
				error instanceof Error
					? error.message
					: "체험 계정 로그인에 실패했어요.",
				"error",
			);
		}
	};

	if (session?.user && mode !== "verify" && mode !== "reset") {
		return (
			<div className="mx-auto max-w-md px-4 pt-10">
				<Card className="space-y-5 text-center">
					<ReloOrbEmblem
						size="md"
						speech={`${session.user.name}님, 이미 로그인되어 있어요.`}
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

	return (
		<div className="mx-auto flex max-w-md flex-col items-center px-4 pt-6 sm:pt-10">
			<ReloOrbEmblem
				size="md"
				speech={
					mode === "signup"
						? "이메일 하나면 10초 만에 내 전용 직구 환불 보관함이 생겨요."
						: "내 직구 영수증과 환불 진행 기록을 안전하게 불러올게요."
				}
				className="mb-3"
			/>

			<Card className="w-full space-y-6 p-6 sm:p-7">
				{mode === "login" || mode === "signup" ? (
					<div className="grid grid-cols-2 rounded-xl bg-relo-sunken p-1">
						<button
							type="button"
							onClick={() => setMode("login")}
							className={`min-h-10 rounded-lg text-sm font-bold transition-colors ${
								mode === "login"
									? "bg-white text-relo-ink shadow-2xs"
									: "text-relo-muted hover:text-relo-ink"
							}`}
						>
							로그인
						</button>
						<button
							type="button"
							onClick={() => setMode("signup")}
							className={`min-h-10 rounded-lg text-sm font-bold transition-colors ${
								mode === "signup"
									? "bg-white text-relo-ink shadow-2xs"
									: "text-relo-muted hover:text-relo-ink"
							}`}
						>
							10초 회원가입
						</button>
					</div>
				) : null}

				{mode === "login" ? (
					<form onSubmit={onLoginSubmit} noValidate className="space-y-4">
						<TextField
							label="이메일"
							type="email"
							autoComplete="email"
							placeholder="you@example.com"
							error={loginForm.formState.errors.email?.message}
							{...loginForm.register("email")}
						/>
						<TextField
							label="비밀번호"
							type="password"
							autoComplete="current-password"
							placeholder="비밀번호 입력"
							error={loginForm.formState.errors.password?.message}
							{...loginForm.register("password")}
						/>
						{loginForm.formState.errors.root?.message ? (
							<p
								role="alert"
								className="rounded-xl bg-relo-danger-soft px-3.5 py-2.5 text-xs font-semibold text-relo-danger"
							>
								{loginForm.formState.errors.root.message}
							</p>
						) : null}
						<Button
							type="submit"
							size="lg"
							fullWidth
							isLoading={loginMutation.isPending}
						>
							로그인하고 계속하기
						</Button>

						<div className="text-center">
							<button
								type="button"
								onClick={() => {
									setForgotSent(false);
									setMode("forgot");
								}}
								className="text-xs font-semibold text-relo-muted underline underline-offset-4 hover:text-relo-brand"
							>
								비밀번호를 잊으셨나요?
							</button>
						</div>
					</form>
				) : null}

				{mode === "signup" ? (
					<form onSubmit={onSignupSubmit} noValidate className="space-y-4">
						<TextField
							label="이름 또는 별명 (선택)"
							type="text"
							autoComplete="name"
							placeholder="예: 홍길동"
							error={signupForm.formState.errors.name?.message}
							{...signupForm.register("name")}
						/>
						<TextField
							label="이메일"
							type="email"
							autoComplete="email"
							placeholder="you@example.com"
							error={signupForm.formState.errors.email?.message}
							{...signupForm.register("email")}
						/>
						<TextField
							label="비밀번호"
							type="password"
							autoComplete="new-password"
							placeholder="10자 이상 입력해 주세요"
							hint="영문·숫자·기호를 섞어 10자 이상 입력하면 안전해요."
							error={signupForm.formState.errors.password?.message}
							{...signupForm.register("password")}
						/>
						{signupForm.formState.errors.root?.message ? (
							<p
								role="alert"
								className="rounded-xl bg-relo-danger-soft px-3.5 py-2.5 text-xs font-semibold text-relo-danger"
							>
								{signupForm.formState.errors.root.message}
							</p>
						) : null}
						<Button
							type="submit"
							size="lg"
							fullWidth
							isLoading={signupMutation.isPending}
						>
							내 환불 보관함 만들기
						</Button>
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
					/>
				) : null}

				{mode === "verify" ? (
					<EmailVerifyPanel
						isPending={verifyMutation.isPending}
						isSuccess={verifyMutation.isSuccess}
						onGoWizard={() => navigate("/wizard")}
					/>
				) : null}

				{config?.demoAccount && (mode === "login" || mode === "signup") ? (
					<div className="space-y-2.5 border-t border-relo-line pt-4">
						<p className="text-xs font-medium text-relo-muted">
							빠르게 화면을 둘러보고 싶으신가요? 체험 계정으로 바로 살펴볼 수
							있어요.
						</p>
						<Button
							variant="soft"
							fullWidth
							isLoading={loginMutation.isPending}
							onClick={handleDemoQuickLogin}
						>
							<UserCheck className="h-4 w-4" aria-hidden="true" />
							<span>체험 계정으로 1초 만에 둘러보기</span>
						</Button>
					</div>
				) : null}

				<ul className="space-y-2 border-t border-relo-line pt-4 text-xs text-relo-muted">
					<li className="flex items-center gap-2">
						<Lock
							className="h-3.5 w-3.5 shrink-0 text-relo-brand"
							aria-hidden="true"
						/>
						<span>내 영수증과 환불 기록은 본인만 열람할 수 있어요.</span>
					</li>
					<li className="flex items-center gap-2">
						<Sparkles
							className="h-3.5 w-3.5 shrink-0 text-relo-brand"
							aria-hidden="true"
						/>
						<span>AI 외국어 편지 작성은 동의하신 경우에만 실행돼요.</span>
					</li>
					<li className="flex items-center gap-2">
						<ShieldCheck
							className="h-3.5 w-3.5 shrink-0 text-relo-brand"
							aria-hidden="true"
						/>
						<span>별도 대행 수수료 없이 내 직접 환불을 끝까지 도와드려요.</span>
					</li>
					<li className="sr-only">
						<Check className="h-3 w-3" aria-hidden="true" />
					</li>
				</ul>
			</Card>
		</div>
	);
}
