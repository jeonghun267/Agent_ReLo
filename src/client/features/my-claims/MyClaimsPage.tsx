/**
 * @module client/features/my-claims/MyClaimsPage
 * @layer View (Authenticated Consumer Refund Dashboard)
 * @purpose Displays the user's refund overview, status filter pills, and currency-isolated
 *          refund records with a guest demo entry fallback.
 */

import { FilePlus2, LogIn, Sparkles, Trash2 } from "lucide-react";
import { motion } from "motion/react";
import { useState } from "react";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Button, Card } from "@/client/components/ui/Primitives";
import { ClaimsAnalyticsCard } from "@/client/features/my-claims/ClaimsAnalyticsCard";
import { ConsumerClaimsLedger } from "@/client/features/my-claims/ConsumerClaimsLedger";
import {
	useAppConfig,
	useClaimsQuery,
	useLoginMutation,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { useRouter } from "@/client/lib/router";

const FILTER_TABS = [
	{ id: "", label: "전체" },
	{ id: "preparing", label: "서류 준비" },
	{ id: "awaiting", label: "답변 대기" },
	{ id: "negotiating", label: "조율 중" },
	{ id: "recovered", label: "입금 확인" },
	{ id: "completed", label: "완료" },
] as const;

export function MyClaimsPage() {
	const { navigate } = useRouter();
	const { t } = useI18n();
	const { data: session, isLoading: sessionLoading } = useSession();
	const { data: config } = useAppConfig();
	const loginMutation = useLoginMutation();

	const [stateFilter, setStateFilter] = useState("");
	const [showTrash, setShowTrash] = useState(false);

	const isLoggedIn = Boolean(session?.user);
	const { data: claimsData, isLoading: claimsLoading } = useClaimsQuery(
		{
			state: showTrash ? "" : stateFilter,
			deleted: showTrash,
		},
		isLoggedIn,
	);

	if (!sessionLoading && !isLoggedIn) {
		return (
			<div className="mx-auto max-w-lg px-4 py-14">
				<Card className="space-y-6 p-7 text-center sm:p-9">
					<ReloOrbEmblem
						variant="default"
						size="md"
						speech="로그인하시면 진행 중인 직구 환불 내역과 실제 카드 취소 금액을 한눈에 확인할 수 있어요."
					/>
					<div className="space-y-2.5">
						{config?.demoAccount ? (
							<Button
								variant="primary"
								size="lg"
								fullWidth
								isLoading={loginMutation.isPending}
								onClick={() =>
									void loginMutation.mutateAsync({
										email: config.demoAccount?.email ?? "",
										password: config.demoAccount?.password ?? "",
									})
								}
							>
								<Sparkles className="h-5 w-5" aria-hidden="true" />
								<span>체험 계정으로 내 환불 내역 둘러보기</span>
							</Button>
						) : null}
						<Button
							variant="secondary"
							size="lg"
							fullWidth
							onClick={() => navigate("/auth")}
						>
							<LogIn className="h-4 w-4" aria-hidden="true" />
							<span>{t.nav.login}</span>
						</Button>
					</div>
				</Card>
			</div>
		);
	}

	const claims = claimsData?.claims ?? [];

	return (
		<div className="mx-auto max-w-5xl space-y-6 px-4 py-8 sm:px-6 sm:py-12">
			<div className="flex flex-wrap items-end justify-between gap-4">
				<div className="space-y-1">
					<p className="text-sm font-semibold text-relo-muted">
						{t.pages.myClaimsTitle}
					</p>
					<h1 className="text-2xl font-bold tracking-[-0.035em] text-relo-ink sm:text-[32px]">
						{session?.user?.name}
						{t.nav.userSuffix} · {t.pages.myClaimsTitle}
					</h1>
					<p className="text-xs text-relo-muted sm:text-sm">
						{t.pages.myClaimsSub}
					</p>
				</div>

				<div className="flex items-center gap-2">
					<Button
						variant={showTrash ? "danger" : "secondary"}
						size="sm"
						onClick={() => setShowTrash((v) => !v)}
						className="rounded-full"
					>
						<Trash2 className="h-3.5 w-3.5" aria-hidden="true" />
						<span>{showTrash ? "진행 목록으로" : "휴지통"}</span>
					</Button>
					<Button
						variant="primary"
						size="sm"
						onClick={() => navigate("/wizard")}
						className="rounded-full px-4"
					>
						<FilePlus2 className="h-4 w-4" aria-hidden="true" />
						<span>{t.pages.myClaimsNewBtn}</span>
					</Button>
				</div>
			</div>

			{!showTrash && claims.length > 0 ? (
				<ClaimsAnalyticsCard claims={claims} />
			) : null}

			{!showTrash ? (
				<div className="overflow-x-auto pb-1">
					<div className="inline-flex min-w-max items-center gap-1 rounded-full bg-relo-sunken p-1">
						{FILTER_TABS.map((tab) => {
							const active = stateFilter === tab.id;
							return (
								<button
									key={tab.id}
									type="button"
									onClick={() => setStateFilter(tab.id)}
									className="relative cursor-pointer rounded-full px-4 py-2 text-xs font-semibold transition"
								>
									{active ? (
										<motion.span
											layoutId="my-claims-filter-thumb"
											transition={{
												type: "spring",
												stiffness: 380,
												damping: 32,
											}}
											className="absolute inset-0 rounded-full bg-white shadow-2xs"
										/>
									) : null}
									<span
										className={`relative z-10 ${
											active
												? "font-bold text-relo-ink"
												: "text-relo-muted hover:text-relo-ink"
										}`}
									>
										{tab.label}
									</span>
								</button>
							);
						})}
					</div>
				</div>
			) : null}

			{claimsLoading ? (
				<Card className="py-14 text-center text-sm font-medium text-relo-muted">
					{t.common.loadingScreen}
				</Card>
			) : claims.length === 0 ? (
				<Card className="space-y-5 p-10 text-center">
					<ReloOrbEmblem
						variant="default"
						size="md"
						speech={
							showTrash
								? "휴지통이 비어 있어요."
								: "아직 등록된 직구 환불 내역이 없어요."
						}
					/>
					{!showTrash ? (
						<div className="flex justify-center">
							<Button
								variant="primary"
								size="lg"
								onClick={() => navigate("/wizard")}
								className="rounded-full px-7"
							>
								<span>{t.pages.myClaimsNewBtn}</span>
							</Button>
						</div>
					) : null}
				</Card>
			) : (
				<ConsumerClaimsLedger claims={claims} stateLabels={config?.states} />
			)}
		</div>
	);
}
