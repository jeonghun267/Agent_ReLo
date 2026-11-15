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
import { useSession } from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import {
	errorText,
	historyLabel,
	nextStepText,
	stateLabel,
} from "@/client/lib/claim-words";
import { fill, formatLocalDate } from "@/client/lib/format";
import { useRouter } from "@/client/lib/router";

/** The four things to do on a refund. Their names come from the dictionary (detail.tabs). */
const DETAIL_TABS = [
	{ id: "inquiry", icon: FileText },
	{ id: "reply", icon: MessageSquare },
	{ id: "settlement", icon: Wallet },
	{ id: "history", icon: History },
] as const;

type DetailTabId = (typeof DETAIL_TABS)[number]["id"];

export function ClaimDetailPage({ claimId }: { claimId: string }) {
	const { navigate } = useRouter();
	const { t, locale, localeOption } = useI18n();
	const { data: session } = useSession();
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
					speech={t.detail.loading}
				/>
			</div>
		);
	}

	if (error || !claim) {
		return (
			<div className="mx-auto max-w-lg px-4 py-14">
				<Card className="space-y-4 text-center">
					<p className="text-base font-bold text-relo-ink">
						{t.detail.notFound}
					</p>
					<Button variant="primary" onClick={() => navigate("/claims")}>
						{t.detail.backToList}
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
			showToast(t.detail.toastClosed);
		} catch (err) {
			showToast(errorText(err, t.detail.toastCloseFail, locale), "error");
		}
	};

	const handleMoveTrash = async () => {
		try {
			await trashMutation.mutateAsync({
				version: claim.version,
				reason: "사용자 휴지통 이동",
			});
			showToast(t.detail.toastTrashed);
		} catch (err) {
			showToast(errorText(err, t.detail.toastTrashFail, locale), "error");
		}
	};

	const handleRestore = async () => {
		try {
			await restoreMutation.mutateAsync(claim.version);
			showToast(t.detail.toastRestored);
		} catch (err) {
			showToast(errorText(err, t.detail.toastRestoreFail, locale), "error");
		}
	};

	return (
		<div className="mx-auto max-w-4xl space-y-6 px-4 py-8 sm:px-6 sm:py-12">
			<div className="flex flex-wrap items-center justify-between gap-2">
				<button
					type="button"
					onClick={() => navigate("/claims")}
					className="inline-flex min-h-11 cursor-pointer items-center gap-1.5 text-sm font-semibold text-relo-muted hover:text-relo-ink"
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
						<span>{t.detail.restore}</span>
					</Button>
				) : (
					<Button
						variant="ghost"
						size="sm"
						isLoading={trashMutation.isPending}
						onClick={handleMoveTrash}
						className="rounded-full text-relo-muted max-sm:min-h-11"
					>
						<Trash2 className="h-3.5 w-3.5" aria-hidden="true" />
						<span>{t.detail.moveToTrash}</span>
					</Button>
				)}
			</div>

			<Card className="space-y-6 p-6 sm:p-8">
				<div className="flex flex-wrap items-start justify-between gap-4">
					<div className="space-y-1.5">
						<div className="flex flex-wrap items-center gap-2">
							<span className="rounded-lg bg-[#f2f4f6] px-2 py-0.5 text-xs font-extrabold text-[#333d4b]">
								{claim.currency}
							</span>
							<Badge tone={claim.state === "disputed" ? "danger" : "neutral"}>
								{stateLabel(t, claim.state)}
							</Badge>
							<span className="text-xs font-medium text-relo-muted">
								{claim.vendor} · {t.shared.orderNo} {claim.orderRef}
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
							<span>{t.detail.closeClaim}</span>
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
							{t.shared.nextStepLabel}: {nextStepText(t, claim)}
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
							{t.detail.agreedLabel}{" "}
							{claim.agreed !== null ? (
								<MoneyDisplay
									minor={claim.agreed}
									currency={claim.currency}
									className="ml-1 text-relo-ink"
								/>
							) : (
								<strong className="ml-1 font-semibold text-relo-body">
									{t.detail.agreedPending}
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
				<div
					role="tablist"
					aria-label={t.detail.tabsLabel}
					className="flex min-w-max items-center gap-6 px-1"
				>
					{DETAIL_TABS.map((tab) => {
						const Icon = tab.icon;
						const active = tab.id === activeTab;
						return (
							<button
								key={tab.id}
								type="button"
								role="tab"
								aria-selected={active}
								onClick={() => setActiveTab(tab.id)}
								className={`relative flex min-h-11 cursor-pointer items-center gap-2 pb-3.5 text-sm transition-colors ${
									active
										? "font-bold text-relo-ink"
										: "font-medium text-relo-muted hover:text-relo-ink"
								}`}
							>
								<Icon
									className={`h-4 w-4 ${active ? "text-relo-brand" : "text-relo-muted"}`}
									aria-hidden="true"
								/>
								<span>{t.detail.tabs[tab.id]}</span>
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
						{fill(t.detail.historyTitle, { n: claim.events.length })}
					</h3>
					<ul className="space-y-2">
						{claim.events.map((ev) => (
							<li
								key={ev.id}
								className="flex items-center justify-between rounded-2xl bg-relo-sunken px-4 py-3 text-xs"
							>
								<span className="font-semibold text-relo-ink">
									{historyLabel(t, ev.action)}
								</span>
								<span className="text-relo-muted tabular-nums">
									{formatLocalDate(ev.createdAt, localeOption.bcp47)}
								</span>
							</li>
						))}
					</ul>
				</Card>
			) : null}
		</div>
	);
}
