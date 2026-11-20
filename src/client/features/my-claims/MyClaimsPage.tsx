/**
 * @module client/features/my-claims/MyClaimsPage
 * @layer View (Authenticated Consumer Refund Dashboard)
 * @purpose Displays the user's refund overview, status filter pills, and currency-isolated
 *          refund records with a guest demo entry fallback.
 */

import { FilePlus2, LogIn, Sparkles, Trash2 } from "lucide-react";
import { motion } from "motion/react";
import { useMemo, useState } from "react";
import { ReloOrbEmblem } from "@/client/components/ReloOrbEmblem";
import { Button, Card } from "@/client/components/ui/Primitives";
import { ClaimsAnalyticsCard } from "@/client/features/my-claims/ClaimsAnalyticsCard";
import { ConsumerClaimsLedger } from "@/client/features/my-claims/ConsumerClaimsLedger";
import { useAgentWaitingQuery } from "@/client/hooks/useClaims";
import {
	useAppConfig,
	useClaimsQuery,
	useLoginMutation,
	useSession,
} from "@/client/hooks/useSession";
import { useI18n } from "@/client/i18n";
import { stateLabel } from "@/client/lib/claim-words";
import { useRouter } from "@/client/lib/router";
import type { ClaimState } from "@/client/types";

/** The stages offered as filters, in order ("" is every stage). Names come from the shared state words. */
const FILTER_STATES: Array<ClaimState | ""> = [
	"",
	"preparing",
	"awaiting",
	"negotiating",
	"recovered",
	"completed",
];

export function MyClaimsPage() {
	const { navigate } = useRouter();
	const { t } = useI18n();
	const { data: session, isLoading: sessionLoading } = useSession();
	const { data: config } = useAppConfig();
	const loginMutation = useLoginMutation();

	const [stateFilter, setStateFilter] = useState<ClaimState | "">("");
	const [showTrash, setShowTrash] = useState(false);

	const isLoggedIn = Boolean(session?.user);
	const { data: claimsData, isLoading: claimsLoading } = useClaimsQuery(
		{
			state: showTrash ? "" : stateFilter,
			deleted: showTrash,
		},
		isLoggedIn,
	);

	// Where the agent stopped on a question while the person was away.
	const { data: waiting } = useAgentWaitingQuery(
		isLoggedIn && Boolean(config?.ai.enabled) && !showTrash,
	);
	const agentWaiting = useMemo(
		() => new Set((waiting ?? []).map((item) => item.claimId)),
		[waiting],
	);

	if (!sessionLoading && !isLoggedIn) {
		return (
			<div className="mx-auto max-w-lg px-4 py-14">
				<Card className="space-y-6 p-7 text-center sm:p-9">
					<ReloOrbEmblem
						variant="default"
						size="md"
						speech={t.claims.guestSpeech}
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
								<span>{t.claims.demoButton}</span>
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
	// Someone with no refunds yet sees one thing to do (the button in the empty card),
	// so the filters and the second "new refund" button are left out.
	const isBrandNew =
		!claimsLoading && claims.length === 0 && !stateFilter && !showTrash;

	return (
		<div className="mx-auto max-w-5xl space-y-6 px-4 py-8 sm:px-6 sm:py-12">
			<div className="flex flex-wrap items-end justify-between gap-4">
				<div className="space-y-1">
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
						className="rounded-full max-sm:min-h-11"
					>
						<Trash2 className="h-3.5 w-3.5" aria-hidden="true" />
						<span>{showTrash ? t.claims.backToList : t.claims.trash}</span>
					</Button>
					{!isBrandNew ? (
						<Button
							variant="primary"
							size="sm"
							onClick={() => navigate("/wizard")}
							className="rounded-full px-4 max-sm:min-h-11"
						>
							<FilePlus2 className="h-4 w-4" aria-hidden="true" />
							<span>{t.pages.myClaimsNewBtn}</span>
						</Button>
					) : null}
				</div>
			</div>

			{!showTrash && claims.length > 0 ? (
				<ClaimsAnalyticsCard claims={claims} />
			) : null}

			{!showTrash && !isBrandNew ? (
				<div className="overflow-x-auto pb-1">
					{/* biome-ignore lint/a11y/useSemanticElements: a pill row of toggle buttons, not a form fieldset */}
					<div
						role="group"
						aria-label={t.claims.filterLabel}
						className="inline-flex min-w-max items-center gap-1 rounded-full bg-relo-sunken p-1"
					>
						{FILTER_STATES.map((id) => {
							const active = stateFilter === id;
							return (
								<button
									key={id || "all"}
									type="button"
									aria-pressed={active}
									onClick={() => setStateFilter(id)}
									className="relative cursor-pointer rounded-full px-4 py-2 text-xs font-semibold transition max-sm:min-h-11"
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
										{id ? stateLabel(t, id) : t.claims.filterAll}
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
								? t.claims.emptyTrash
								: stateFilter
									? t.claims.emptyFiltered
									: t.claims.empty
						}
					/>
					{!showTrash && stateFilter ? (
						<div className="flex justify-center">
							<Button
								variant="secondary"
								size="lg"
								onClick={() => setStateFilter("")}
								className="rounded-full px-7"
							>
								<span>{t.claims.showAll}</span>
							</Button>
						</div>
					) : null}
					{!showTrash && !stateFilter ? (
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
				<ConsumerClaimsLedger claims={claims} agentWaiting={agentWaiting} />
			)}
		</div>
	);
}
