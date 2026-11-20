/**
 * @module client/features/settings/SettingsPage
 * @layer View (Account Privacy, AI Consent & Data Export)
 * @purpose Lets consumers manage their account, opt in/out of AI writing assistance,
 *          export all personal refund data as JSON, or permanently delete their account.
 */

import { Download, LogOut, Sparkles, Trash2, UserCheck } from "lucide-react";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { useAiConsentGate } from "@/client/components/AiConsentDialog";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Button,
	Card,
	PasswordField,
	useToast,
} from "@/client/components/ui/Primitives";
import { PasskeyCard } from "@/client/features/settings/PasskeyCard";
import {
	useAgentAutoMutation,
	useAiConsentMutation,
	useAppConfig,
	useDeleteAccountMutation,
	useLogoutMutation,
	useNoticeMailMutation,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { ApiError, accountApi } from "@/client/lib/api-client";
import { errorText, fieldError } from "@/client/lib/claim-words";
import { fill, formatLocalDate } from "@/client/lib/format";
import { useRouter } from "@/client/lib/router";
import { zodV4Resolver } from "@/client/lib/zod-resolver";
import {
	type DeleteAccountFormValues,
	deleteAccountSchema,
} from "@/client/types";

export function SettingsPage() {
	const { t, locale, localeOption } = useI18n();
	const st = t.settings;
	const { navigate } = useRouter();
	const { data: session, isLoading } = useSession();
	const { data: config } = useAppConfig();
	const aiConsentMutation = useAiConsentMutation();
	const agentAutoMutation = useAgentAutoMutation();
	const noticeMailMutation = useNoticeMailMutation();
	const { ensureConsent, consentDialog } = useAiConsentGate();
	const logoutMutation = useLogoutMutation();
	const deleteMutation = useDeleteAccountMutation();
	const { showToast } = useToast();
	const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
	const [isExporting, setIsExporting] = useState(false);

	const deleteForm = useForm<DeleteAccountFormValues>({
		resolver: zodV4Resolver(deleteAccountSchema),
		defaultValues: { password: "" },
	});

	const user = session?.user ?? null;

	if (isLoading) {
		return (
			<div className="mx-auto max-w-xl px-4 pt-12 text-center text-sm text-relo-muted">
				{st.loading}
			</div>
		);
	}

	if (!user) {
		return (
			<div className="mx-auto max-w-md px-4 pt-10">
				<Card className="space-y-5 text-center">
					<ReloOrbEmblem size="md" speech={st.guestSpeech} />
					<Button
						size="lg"
						fullWidth
						onClick={() => navigate("/auth?mode=login&next=%2Fsettings")}
					>
						{t.nav.login}
					</Button>
				</Card>
			</div>
		);
	}

	const aiConsented = Boolean(user.aiConsentAt);
	const agentAuto = Boolean(user.agentAutoAt);
	const auto = t.detail.agent.auto;
	const noticeMail = !user.noticeMailOffAt;

	// The same switch as on a case: the AI may start by itself when something happens there.
	const handleToggleAgentAuto = async () => {
		try {
			await agentAutoMutation.mutateAsync(!agentAuto);
			showToast(agentAuto ? auto.toastOff : auto.toastOn);
		} catch (error) {
			showToast(errorText(error, auto.toastFail, locale), "error");
		}
	};

	// The email that tells them the AI is waiting. Off here, the AI still starts by itself.
	const handleToggleNoticeMail = async () => {
		try {
			await noticeMailMutation.mutateAsync(!noticeMail);
			showToast(noticeMail ? st.toastNoticeMailOff : st.toastNoticeMailOn);
		} catch (error) {
			showToast(errorText(error, st.toastSaveFail, locale), "error");
		}
	};

	// Turning it on goes through the same notice as the AI buttons, so the answer is saved
	// only after the person has read what is sent. Turning it off needs no question.
	const handleToggleConsent = async () => {
		try {
			if (aiConsented) {
				await aiConsentMutation.mutateAsync(false);
				showToast(st.toastAiOff);
			} else if (await ensureConsent()) {
				showToast(st.toastAiOn);
			}
		} catch (error) {
			showToast(errorText(error, st.toastSaveFail, locale), "error");
		}
	};

	const handleExportData = async () => {
		setIsExporting(true);
		try {
			const archive = await accountApi.exportData();
			const blob = new Blob([JSON.stringify(archive, null, 2)], {
				type: "application/json",
			});
			const url = URL.createObjectURL(blob);
			const link = document.createElement("a");
			link.href = url;
			link.download = `relo-my-data-${new Date().toISOString().slice(0, 10)}.json`;
			link.click();
			URL.revokeObjectURL(url);
			showToast(st.toastExported);
		} catch (error) {
			showToast(errorText(error, st.toastExportFail, locale), "error");
		} finally {
			setIsExporting(false);
		}
	};

	const handleLogout = async () => {
		await logoutMutation.mutateAsync();
		showToast(st.toastLoggedOut);
		navigate("/");
	};

	const onDeleteSubmit = deleteForm.handleSubmit(async (values) => {
		try {
			await deleteMutation.mutateAsync(values.password);
			showToast(st.toastDeleted);
			navigate("/", { replace: true });
		} catch (error) {
			if (error instanceof ApiError && error.field === "password") {
				deleteForm.setError("password", {
					message: errorText(error, st.passwordWrong, locale),
				});
				return;
			}
			deleteForm.setError("root", {
				message: errorText(error, st.deleteFail, locale),
			});
		}
	});

	return (
		<div className="mx-auto max-w-xl space-y-5 px-4 pt-6 sm:px-6 sm:pt-8">
			{consentDialog}
			<div className="space-y-1">
				<span className="text-xs font-bold text-relo-brand">{st.eyebrow}</span>
				<h1 className="text-2xl font-extrabold tracking-tight text-relo-ink">
					{t.nav.settings}
				</h1>
			</div>

			{/* Profile Card */}
			<Card className="space-y-4">
				<div className="flex items-center justify-between gap-4">
					<div className="space-y-0.5">
						<p className="text-base font-extrabold text-relo-ink">
							{user.name}
						</p>
						<p className="text-sm text-relo-muted">{user.email}</p>
						<p className="text-xs text-relo-subtle">
							{fill(st.joined, {
								date: formatLocalDate(user.createdAt, localeOption.bcp47),
							})}{" "}
							· {user.emailVerifiedAt ? st.verified : st.unverified}
						</p>
					</div>
					<span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-relo-brand-soft text-relo-brand">
						<UserCheck className="h-5 w-5" aria-hidden="true" />
					</span>
				</div>
				<Button
					variant="secondary"
					fullWidth
					isLoading={logoutMutation.isPending}
					onClick={handleLogout}
				>
					<LogOut className="h-4 w-4" aria-hidden="true" />
					<span>{st.logout}</span>
				</Button>
			</Card>

			{/* AI Writing & Receipt Scan Consent Card */}
			<Card className="space-y-3">
				<div className="flex items-start justify-between gap-4">
					<div className="space-y-1">
						<span className="inline-flex items-center gap-1.5 text-xs font-bold text-relo-brand">
							<Sparkles className="h-3.5 w-3.5" aria-hidden="true" />
							<span>{st.aiEyebrow}</span>
						</span>
						<h2 className="text-base font-bold text-relo-ink">{st.aiTitle}</h2>
						<p className="text-xs leading-relaxed text-relo-muted">
							{st.aiBody}
						</p>
					</div>
				</div>
				<Button
					variant={aiConsented ? "secondary" : "primary"}
					fullWidth
					isLoading={aiConsentMutation.isPending}
					onClick={handleToggleConsent}
				>
					{aiConsented ? st.aiTurnOff : st.aiTurnOn}
				</Button>
				{aiConsented && config?.ai.enabled ? (
					<div
						className="flex flex-wrap items-center justify-between gap-x-3 gap-y-1 border-t border-relo-line pt-3 text-xs leading-relaxed text-relo-muted"
						data-testid="settings-agent-auto"
					>
						<p className="min-w-0 flex-1 basis-64">
							{agentAuto ? auto.onNote : auto.offNote}
						</p>
						<button
							type="button"
							aria-pressed={agentAuto}
							disabled={agentAutoMutation.isPending}
							onClick={handleToggleAgentAuto}
							className="inline-flex min-h-11 shrink-0 cursor-pointer items-center font-semibold text-relo-brand hover:underline disabled:opacity-60"
						>
							{agentAuto ? auto.turnOff : auto.turnOn}
						</button>
					</div>
				) : null}
				{aiConsented && config?.ai.enabled && agentAuto ? (
					<div
						className="flex flex-wrap items-center justify-between gap-x-3 gap-y-1 border-t border-relo-line pt-3 text-xs leading-relaxed text-relo-muted"
						data-testid="settings-notice-mail"
					>
						<p className="min-w-0 flex-1 basis-64">
							{/* No email goes to an address nobody has confirmed: say so instead of promising one. */}
							{!noticeMail
								? st.noticeMailOffNote
								: user.emailVerifiedAt
									? st.noticeMailOnNote
									: st.noticeMailUnverifiedNote}
						</p>
						<button
							type="button"
							aria-pressed={noticeMail}
							disabled={noticeMailMutation.isPending}
							onClick={handleToggleNoticeMail}
							className="inline-flex min-h-11 shrink-0 cursor-pointer items-center font-semibold text-relo-brand hover:underline disabled:opacity-60"
						>
							{noticeMail ? st.noticeMailTurnOff : st.noticeMailTurnOn}
						</button>
					</div>
				) : null}
			</Card>

			{config?.signIn?.passkey ? <PasskeyCard /> : null}

			{/* Data Export Card */}
			<Card className="space-y-3">
				<h2 className="text-base font-bold text-relo-ink">{st.exportTitle}</h2>
				<p className="text-xs leading-relaxed text-relo-muted">
					{st.exportBody}
				</p>
				<Button
					variant="secondary"
					fullWidth
					isLoading={isExporting}
					onClick={handleExportData}
				>
					<Download className="h-4 w-4" aria-hidden="true" />
					<span>{st.exportButton}</span>
				</Button>
			</Card>

			{/* Account Deletion Danger Zone */}
			<Card className="space-y-3 border-red-200/80">
				<h2 className="text-base font-bold text-relo-danger">
					{st.deleteTitle}
				</h2>
				<p className="text-xs leading-relaxed text-relo-muted">
					{st.deleteBody}
				</p>
				{!showDeleteConfirm ? (
					<Button
						variant="danger"
						fullWidth
						onClick={() => setShowDeleteConfirm(true)}
					>
						<Trash2 className="h-4 w-4" aria-hidden="true" />
						<span>{st.deleteStart}</span>
					</Button>
				) : (
					<form onSubmit={onDeleteSubmit} noValidate className="space-y-3 pt-1">
						<PasswordField
							label={st.passwordLabel}
							autoComplete="current-password"
							showLabel={t.auth.showPassword}
							hideLabel={t.auth.hidePassword}
							placeholder={st.passwordPlaceholder}
							error={fieldError(
								t,
								deleteForm.formState.errors.password?.message,
							)}
							{...deleteForm.register("password")}
						/>
						{deleteForm.formState.errors.root?.message ? (
							<p
								role="alert"
								className="text-xs font-semibold text-relo-danger"
							>
								{deleteForm.formState.errors.root.message}
							</p>
						) : null}
						<div className="flex gap-2">
							<Button
								variant="secondary"
								fullWidth
								onClick={() => {
									setShowDeleteConfirm(false);
									deleteForm.reset();
								}}
							>
								{st.cancel}
							</Button>
							<Button
								type="submit"
								variant="danger"
								fullWidth
								isLoading={deleteMutation.isPending}
							>
								{st.deleteConfirm}
							</Button>
						</div>
					</form>
				)}
			</Card>
		</div>
	);
}
