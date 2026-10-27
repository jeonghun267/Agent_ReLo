/**
 * @module client/features/claim-detail/ClaimDetailPage
 * @layer ViewModel & Page Container (Individual Refund Case Workspace)
 * @purpose Displays a single refund case's Toss-style passbook summary, status flow,
 *          foreign message writer, seller reply summary, and deposit verification tabs.
 */

import {
	ArrowLeft,
	CheckCircle2,
	FileText,
	History,
	MessageSquare,
	RotateCcw,
	Trash2,
	Wallet,
} from "lucide-react";
import { motion } from "motion/react";
import { useState } from "react";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import {
	Badge,
	Button,
	Card,
	MoneyDisplay,
	useToast,
} from "@/client/components/ui/Primitives";
import { ClaimLifecycleFlow } from "@/client/features/claim-detail/ClaimLifecycleFlow";
import { EvidenceAndSettlementTab } from "@/client/features/claim-detail/EvidenceAndSettlementTab";
import { ForeignMessageStudio } from "@/client/features/claim-detail/ForeignMessageStudio";
import { SellerReplyAnalyzer } from "@/client/features/claim-detail/SellerReplyAnalyzer";
import {
	useClaimDetailQuery,
	useRestoreClaimMutation,
	useTransitionClaimMutation,
	useTrashClaimMutation,
} from "@/client/hooks/useClaims";
import { useAppConfig, useSession } from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { formatKoreanDate } from "@/client/lib/format";
import { useRouter } from "@/client/lib/router";

const DETAIL_TABS = [
	{ id: "inquiry", label: "외국어 메시지 보내기", icon: FileText },
	{ id: "reply", label: "쇼핑몰 답장 · 약속 금액", icon: MessageSquare },
	{ id: "settlement", label: "사진 보관함 · 입금 확인", icon: Wallet },
	{ id: "history", label: "진행 기록 · 마무리", icon: History },
] as const;

type DetailTabId = (typeof DETAIL_TABS)[number]["id"];

export function ClaimDetailPage({ claimId }: { claimId: string }) {
	const { navigate } = useRouter();
	const { t } = useI18n();
	const { data: session } = useSession();
	const { data: config } = useAppConfig();
	const { showToast } = useToast();

	const {
		data: claim,
		isLoading,
		error,
	} = useClaimDetailQuery(claimId, Boolean(session?.user));
	const transitionMutation = useTransitionClaimMutation(claimId);
	const trashMutation = useTrashClaimMutation(claimId);
	const restoreMutation = useRestoreClaimMutation(claimId);

	const [activeTab, setActiveTab] = useState<DetailTabId>("inquiry");

	if (isLoading) {
		return (
			<div className="mx-auto max-w-4xl px-4 py-14 text-center">
				<ReloOrbEmblem
					variant="processing"
					size="md"
					speech="환불 진행 내역과 보관된 파일을 불러오고 있어요..."
				/>
			</div>
		);
	}

	if (error || !claim) {
		return (
			<div className="mx-auto max-w-lg px-4 py-14">
				<Card className="space-y-4 text-center">
					<p className="text-base font-bold text-relo-ink">
						환불 신청 정보를 찾을 수 없어요.
					</p>
					<Button variant="primary" onClick={() => navigate("/claims")}>
						내 환불 내역으로 돌아가기
					</Button>
				</Card>
			</div>
		);
	}

	const recoveryPct =
		claim.claimed > 0
			? Math.min(100, Math.round((claim.summary.cash / claim.claimed) * 100))
			: 0;

	const handleCloseClaim = async () => {
		try {
			await transitionMutation.mutateAsync({
				version: claim.version,
				action: "close",
				reason: "실제 입금·수령 확인 완료 후 소비자 직접 마무리",
			});
			showToast("모든 환불 절차가 마무리되었어요.");
		} catch (err) {
			showToast(
				err instanceof Error ? err.message : "마무리 처리에 실패했어요.",
				"error",
			);
		}
	};

	const handleMoveTrash = async () => {
		try {
			await trashMutation.mutateAsync({
				version: claim.version,
				reason: "사용자 휴지통 이동",
			});
			showToast("휴지통으로 옮겼어요. 언제든 복원할 수 있어요.");
		} catch (err) {
			showToast(
				err instanceof Error ? err.message : "휴지통 이동에 실패했어요.",
				"error",
			);
		}
	};

	const handleRestore = async () => {
		try {
			await restoreMutation.mutateAsync(claim.version);
			showToast("환불 내역이 다시 복원되었어요.");
		} catch (err) {
			showToast(
				err instanceof Error ? err.message : "복원에 실패했어요.",
				"error",
			);
		}
	};

	return (
		<div className="mx-auto max-w-4xl space-y-6 px-4 py-8 sm:px-6 sm:py-12">
			<div className="flex flex-wrap items-center justify-between gap-2">
				<button
					type="button"
					onClick={() => navigate("/claims")}
					className="inline-flex cursor-pointer items-center gap-1.5 text-sm font-semibold text-relo-muted hover:text-relo-ink"
				>
					<ArrowLeft className="h-4 w-4" aria-hidden="true" />
					<span>{t.pages.myClaimsTitle}</span>
				</button>

				{claim.deleted ? (
					<Button
						variant="primary"
						size="sm"
						isLoading={restoreMutation.isPending}
						onClick={handleRestore}
						className="rounded-full"
					>
						<RotateCcw className="h-3.5 w-3.5" aria-hidden="true" />
						<span>복원하기</span>
					</Button>
				) : (
					<Button
						variant="ghost"
						size="sm"
						isLoading={trashMutation.isPending}
						onClick={handleMoveTrash}
						className="rounded-full text-relo-muted"
					>
						<Trash2 className="h-3.5 w-3.5" aria-hidden="true" />
						<span>휴지통 이동</span>
					</Button>
				)}
			</div>

			<Card className="space-y-6 p-6 sm:p-8">
				<div className="flex flex-wrap items-start justify-between gap-4">
					<div className="space-y-1.5">
						<div className="flex flex-wrap items-center gap-2">
							<span className="rounded-lg bg-[#f2f4f6] px-2 py-0.5 text-[11px] font-extrabold text-[#333d4b]">
								{claim.currency}
							</span>
							<Badge tone="brand">
								{config?.states[claim.state] ?? claim.state}
							</Badge>
							<span className="text-xs font-medium text-relo-muted">
								{claim.vendor} · 주문번호 {claim.orderRef}
							</span>
						</div>
						<h1 className="text-2xl font-bold tracking-[-0.035em] text-relo-ink sm:text-[28px]">
							{claim.title}
						</h1>
					</div>

					{claim.state === "recovered" ? (
						<Button
							variant="primary"
							size="md"
							isLoading={transitionMutation.isPending}
							onClick={handleCloseClaim}
							className="rounded-full"
						>
							<CheckCircle2 className="h-4 w-4" aria-hidden="true" />
							<span>환불 절차 마무리하기</span>
						</Button>
					) : null}
				</div>

				{/* Unified Toss Blue Passbook Gauge */}
				<div className="rounded-2xl bg-relo-canvas p-5">
					<div className="flex flex-wrap items-baseline justify-between gap-2">
						<div>
							<p className="text-xs font-medium text-relo-muted">
								{t.pages.sumRecovered}
							</p>
							<div className="mt-1 flex items-baseline gap-2">
								<MoneyDisplay
									minor={claim.summary.cash}
									currency={claim.currency}
									className="text-3xl text-relo-ink sm:text-4xl"
								/>
								<span className="text-sm font-medium text-relo-muted">
									/{" "}
									<MoneyDisplay
										minor={claim.claimed}
										currency={claim.currency}
										className="text-sm text-relo-muted"
									/>
								</span>
							</div>
						</div>

						<span className="text-xs font-semibold text-relo-brand">
							다음 할 일: {claim.nextStep}
						</span>
					</div>

					<div className="mt-4 h-2 w-full overflow-hidden rounded-full bg-[#e5e8eb]">
						<div
							style={{ width: `${Math.max(6, recoveryPct)}%` }}
							className="h-full rounded-full bg-relo-brand transition-all"
						/>
					</div>

					<div className="mt-4 flex flex-wrap items-center gap-x-6 gap-y-1.5 border-t border-relo-line pt-3.5 text-xs sm:text-sm">
						<span className="text-relo-muted">
							{t.pages.sumClaimed}{" "}
							<MoneyDisplay
								minor={claim.claimed}
								currency={claim.currency}
								className="ml-1 text-relo-ink"
							/>
						</span>
						<span className="text-relo-muted">
							쇼핑몰 약속 금액{" "}
							{claim.agreed !== null ? (
								<MoneyDisplay
									minor={claim.agreed}
									currency={claim.currency}
									className="ml-1 text-relo-ink"
								/>
							) : (
								<strong className="ml-1 font-semibold text-relo-body">
									확인 전
								</strong>
							)}
						</span>
						<span className="text-relo-muted">
							{t.pages.sumRemaining}{" "}
							<MoneyDisplay
								minor={claim.summary.remaining}
								currency={claim.currency}
								className="ml-1 text-relo-brand"
							/>
						</span>
					</div>
				</div>

				<ClaimLifecycleFlow state={claim.state} />
			</Card>

			<div className="overflow-x-auto border-b border-relo-line">
				<div className="flex min-w-max items-center gap-6 px-1">
					{DETAIL_TABS.map((tab) => {
						const Icon = tab.icon;
						const active = tab.id === activeTab;
						return (
							<button
								key={tab.id}
								type="button"
								onClick={() => setActiveTab(tab.id)}
								className={`relative flex cursor-pointer items-center gap-2 pb-3.5 text-sm transition-colors ${
									active
										? "font-bold text-relo-ink"
										: "font-medium text-relo-muted hover:text-relo-ink"
								}`}
							>
								<Icon
									className={`h-4 w-4 ${active ? "text-relo-brand" : "text-relo-muted"}`}
									aria-hidden="true"
								/>
								<span>{tab.label}</span>
								{active ? (
									<motion.span
										layoutId="claim-detail-underline"
										className="absolute inset-x-0 bottom-0 h-[2.5px] rounded-full bg-relo-ink"
									/>
								) : null}
							</button>
						);
					})}
				</div>
			</div>

			{activeTab === "inquiry" ? <ForeignMessageStudio claim={claim} /> : null}
			{activeTab === "reply" ? <SellerReplyAnalyzer claim={claim} /> : null}
			{activeTab === "settlement" ? (
				<EvidenceAndSettlementTab claim={claim} />
			) : null}
			{activeTab === "history" ? (
				<Card className="space-y-4">
					<h3 className="text-base font-bold text-relo-ink">
						시간순 진행 기록 ({claim.events.length}건)
					</h3>
					<ul className="space-y-2">
						{claim.events.map((ev) => (
							<li
								key={ev.id}
								className="flex items-center justify-between rounded-2xl bg-relo-sunken px-4 py-3 text-xs"
							>
								<span className="font-semibold text-relo-ink">{ev.action}</span>
								<span className="text-relo-muted tabular-nums">
									{formatKoreanDate(ev.createdAt)}
								</span>
							</li>
						))}
					</ul>
				</Card>
			) : null}
		</div>
	);
}
