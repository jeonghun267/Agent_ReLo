/**
 * @module client/features/settings/SettingsPage
 * @layer View (Account Privacy, AI Consent & Data Export)
 * @purpose Lets consumers manage their account, opt in/out of AI writing assistance,
 *          export all personal refund data as JSON, or permanently delete their account.
 */

import { Download, LogOut, Sparkles, Trash2, UserCheck } from "lucide-react";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Button,
	Card,
	TextField,
	useToast,
} from "@/client/components/ui/Primitives";
import {
	useAiConsentMutation,
	useDeleteAccountMutation,
	useLogoutMutation,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { ApiError, accountApi } from "@/client/lib/api-client";
import { formatKoreanDate } from "@/client/lib/format";
import { useRouter } from "@/client/lib/router";
import { zodV4Resolver } from "@/client/lib/zod-resolver";
import {
	type DeleteAccountFormValues,
	deleteAccountSchema,
} from "@/client/types";

export function SettingsPage() {
	const { t } = useI18n();
	const { navigate } = useRouter();
	const { data: session, isLoading } = useSession();
	const aiConsentMutation = useAiConsentMutation();
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
				계정 정보를 불러오고 있어요...
			</div>
		);
	}

	if (!user) {
		return (
			<div className="mx-auto max-w-md px-4 pt-10">
				<Card className="space-y-5 text-center">
					<ReloOrbEmblem
						size="md"
						speech="내 계정 설정과 개인정보 보호 센터예요. 로그인 후 이용할 수 있어요."
					/>
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

	const handleToggleConsent = async () => {
		try {
			await aiConsentMutation.mutateAsync(!aiConsented);
			showToast(
				!aiConsented
					? "AI 외국어 편지·주문서 읽기 기능을 켰어요!"
					: "AI 기능 사용 동의를 철회했어요.",
			);
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "설정을 저장하지 못했어요.",
				"error",
			);
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
			showToast("내 모든 환불 기록을 파일로 내려받았어요.");
		} catch (error) {
			showToast(
				error instanceof Error ? error.message : "내보내기에 실패했어요.",
				"error",
			);
		} finally {
			setIsExporting(false);
		}
	};

	const handleLogout = async () => {
		await logoutMutation.mutateAsync();
		showToast("안전하게 로그아웃되었어요.");
		navigate("/");
	};

	const onDeleteSubmit = deleteForm.handleSubmit(async (values) => {
		try {
			await deleteMutation.mutateAsync(values.password);
			showToast("계정과 모든 사진·영수증 데이터가 영구 삭제되었어요.");
			navigate("/", { replace: true });
		} catch (error) {
			if (error instanceof ApiError && error.field === "password") {
				deleteForm.setError("password", { message: error.message });
				return;
			}
			deleteForm.setError("root", {
				message:
					error instanceof Error ? error.message : "탈퇴 처리에 실패했어요.",
			});
		}
	});

	return (
		<div className="mx-auto max-w-xl space-y-5 px-4 pt-6 sm:px-6 sm:pt-8">
			<div className="space-y-1">
				<span className="text-xs font-bold text-relo-brand">
					내 정보 · 개인정보 보호
				</span>
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
							가입일 {formatKoreanDate(user.createdAt)} ·{" "}
							{user.emailVerifiedAt ? "이메일 인증 완료" : "이메일 미인증"}
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
					<span>로그아웃</span>
				</Button>
			</Card>

			{/* AI Writing & Receipt Scan Consent Card */}
			<Card className="space-y-3">
				<div className="flex items-start justify-between gap-4">
					<div className="space-y-1">
						<span className="inline-flex items-center gap-1.5 text-xs font-bold text-relo-brand">
							<Sparkles className="h-3.5 w-3.5" aria-hidden="true" />
							<span>ReLo AI 외국어 도우미</span>
						</span>
						<h2 className="text-base font-bold text-relo-ink">
							AI 주문서 자동 입력 및 외국어 환불 편지 작성
						</h2>
						<p className="text-xs leading-relaxed text-relo-muted">
							동의하시면 주문 내역 자동 읽기와 해외 쇼핑몰에 보낼 외국어 편지
							작성을 도와드려요. 언제든 끄실 수 있어요.
						</p>
					</div>
				</div>
				<Button
					variant={aiConsented ? "secondary" : "primary"}
					fullWidth
					isLoading={aiConsentMutation.isPending}
					onClick={handleToggleConsent}
				>
					{aiConsented
						? "AI 기능 사용 중 (동의 철회하기)"
						: "AI 외국어 도우미 켜기 (동의)"}
				</Button>
			</Card>

			{/* Data Export Card */}
			<Card className="space-y-3">
				<h2 className="text-base font-bold text-relo-ink">
					내 환불 기록 파일로 내려받기
				</h2>
				<p className="text-xs leading-relaxed text-relo-muted">
					내가 등록한 환불 내역과 첨부 기록 사본을 언제든 내 기기에 파일로
					보관할 수 있어요.
				</p>
				<Button
					variant="secondary"
					fullWidth
					isLoading={isExporting}
					onClick={handleExportData}
				>
					<Download className="h-4 w-4" aria-hidden="true" />
					<span>내 전체 기록 내보내기</span>
				</Button>
			</Card>

			{/* Account Deletion Danger Zone */}
			<Card className="space-y-3 border-red-200/80">
				<h2 className="text-base font-bold text-relo-danger">
					회원 탈퇴 및 영구 삭제
				</h2>
				<p className="text-xs leading-relaxed text-relo-muted">
					탈퇴 시 내 모든 직구 환불 내역과 업로드한 영수증·사진이 즉시 영구
					삭제되며 복구할 수 없어요.
				</p>
				{!showDeleteConfirm ? (
					<Button
						variant="danger"
						fullWidth
						onClick={() => setShowDeleteConfirm(true)}
					>
						<Trash2 className="h-4 w-4" aria-hidden="true" />
						<span>회원 탈퇴 진행하기</span>
					</Button>
				) : (
					<form onSubmit={onDeleteSubmit} noValidate className="space-y-3 pt-1">
						<TextField
							label="본인 확인 비밀번호 입력"
							type="password"
							placeholder="현재 비밀번호 입력"
							error={deleteForm.formState.errors.password?.message}
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
								취소
							</Button>
							<Button
								type="submit"
								variant="danger"
								fullWidth
								isLoading={deleteMutation.isPending}
							>
								영구 삭제 확인
							</Button>
						</div>
					</form>
				)}
			</Card>
		</div>
	);
}
