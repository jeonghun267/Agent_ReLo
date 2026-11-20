/**
 * @module client/features/my-claims/ConsumerClaimsLedger
 * @layer View (Consumer Refund History Cards & Sortable Table)
 * @purpose Renders user refund cases in either Toss-style passbook cards or a sortable
 *          @tanstack/react-table view with unified Toss Blue money accents.
 */

import {
	createColumnHelper,
	createSortedRowModel,
	rowSortingFeature,
	type SortingState,
	sortFn_alphanumeric,
	sortFn_basic,
	tableFeatures,
	useTable,
} from "@tanstack/react-table";
import {
	ArrowUpDown,
	ChevronRight,
	LayoutGrid,
	ListFilter,
	Search,
} from "lucide-react";
import { useId, useMemo, useState } from "react";
import { Badge, Card, MoneyDisplay } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";
import { receivedPercent } from "@/client/lib/claim-progress";
import {
	nextStepText,
	receivedText,
	stateLabel,
} from "@/client/lib/claim-words";
import { fill, formatLocalDate } from "@/client/lib/format";
import { AppLink } from "@/client/lib/router";
import type { ClaimState, ClaimView } from "@/client/types";

const features = tableFeatures({
	rowSortingFeature,
	sortedRowModel: createSortedRowModel(),
	sortFns: {
		alphanumeric: sortFn_alphanumeric,
		basic: sortFn_basic,
	},
});

const columnHelper = createColumnHelper<typeof features, ClaimView>();

// A state is written in dark gray like any other fact about the claim. Only a dispute,
// which needs the person to act, is written in red. (The blue line on each row is the next step.)
function stateTone(state: ClaimState): "danger" | "neutral" {
	return state === "disputed" ? "danger" : "neutral";
}

export function ConsumerClaimsLedger({
	claims,
	agentWaiting,
}: {
	claims: ClaimView[];
	/** Claims where the agent stopped on a question and waits for the person's answer. */
	agentWaiting: ReadonlySet<string>;
}) {
	const { t, localeOption } = useI18n();
	const searchId = useId();
	const [searchQuery, setSearchQuery] = useState("");
	const [viewMode, setViewMode] = useState<"cards" | "table">("cards");
	const [sorting, setSorting] = useState<SortingState>([
		{ id: "updatedAt", desc: true },
	]);

	const filteredClaims = useMemo(() => {
		const q = searchQuery.toLowerCase().trim();
		if (!q) return claims;
		return claims.filter((c) =>
			[c.title, c.vendor, c.orderRef, c.issue]
				.join(" ")
				.toLowerCase()
				.includes(q),
		);
	}, [claims, searchQuery]);

	const columns = useMemo(
		() =>
			columnHelper.columns([
				columnHelper.accessor("title", {
					header: t.claims.colProduct,
					sortFn: "alphanumeric",
					cell: (info) => {
						const row = info.row.original;
						return (
							<div>
								<p className="font-extrabold text-relo-ink">{row.title}</p>
								<p className="text-xs text-relo-muted">
									{row.vendor} · {t.shared.orderNo} {row.orderRef}
								</p>
							</div>
						);
					},
				}),
				columnHelper.accessor("state", {
					header: t.claims.colState,
					sortFn: "alphanumeric",
					cell: (info) => {
						const st = info.getValue();
						return (
							<Badge tone={stateTone(st)}>
								{stateLabel(t, st, info.row.original.kind)}
							</Badge>
						);
					},
				}),
				columnHelper.accessor("claimed", {
					header: t.pages.sumClaimed,
					sortFn: "basic",
					cell: (info) => {
						const row = info.row.original;
						return (
							<MoneyDisplay
								minor={row.claimed}
								currency={row.currency}
								className="text-sm text-relo-ink"
							/>
						);
					},
				}),
				columnHelper.accessor((row) => row.summary.cash, {
					id: "recoveredCash",
					header: t.pages.sumRecovered,
					sortFn: "basic",
					cell: (info) => {
						const row = info.row.original;
						// An exchange or a repair has no money coming back: say what arrived instead.
						const arrived = receivedText(t, row);
						if (arrived !== null) {
							return (
								<span className="text-sm font-semibold text-relo-brand tabular-nums">
									{arrived}
								</span>
							);
						}
						return (
							<MoneyDisplay
								minor={row.summary.cash}
								currency={row.currency}
								className="text-sm text-relo-brand"
							/>
						);
					},
				}),
				columnHelper.accessor("updatedAt", {
					header: t.claims.colUpdated,
					sortFn: "alphanumeric",
					cell: (info) => (
						<span className="text-xs text-relo-muted tabular-nums">
							{formatLocalDate(info.getValue(), localeOption.bcp47)}
						</span>
					),
				}),
			]),
		[t, localeOption.bcp47],
	);

	const table = useTable({
		features,
		data: filteredClaims,
		columns,
		state: { sorting },
		onSortingChange: setSorting,
	});

	const rows = table.getRowModel().rows;

	return (
		<div className="space-y-4">
			<div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
				<div className="relative flex-1">
					<label htmlFor={searchId} className="sr-only">
						{t.claims.searchLabel}
					</label>
					<Search
						className="pointer-events-none absolute top-1/2 left-4 h-4 w-4 -translate-y-1/2 text-relo-muted"
						aria-hidden="true"
					/>
					<input
						id={searchId}
						type="search"
						value={searchQuery}
						onChange={(e) => setSearchQuery(e.target.value)}
						placeholder={t.claims.searchPlaceholder}
						className="min-h-11 w-full rounded-full border border-transparent bg-relo-sunken pr-4 pl-10 text-sm font-medium text-relo-ink transition focus:border-relo-brand focus:bg-white"
					/>
				</div>

				<div className="flex items-center gap-2">
					<button
						type="button"
						onClick={() =>
							setSorting((prev) => [
								{
									id: "claimed",
									desc: prev[0]?.id === "claimed" ? !prev[0].desc : true,
								},
							])
						}
						className="inline-flex min-h-10 cursor-pointer items-center gap-1.5 rounded-full bg-relo-sunken px-3.5 text-xs font-semibold text-relo-body hover:bg-[#e5e8eb]"
					>
						<ArrowUpDown className="h-3.5 w-3.5" aria-hidden="true" />
						<span>{t.claims.sortByAmount}</span>
					</button>

					{/* biome-ignore lint/a11y/useSemanticElements: a two-way toggle, not a form fieldset */}
					<div
						role="group"
						aria-label={t.claims.viewLabel}
						className="inline-flex rounded-full bg-relo-sunken p-1"
					>
						<button
							type="button"
							aria-pressed={viewMode === "cards"}
							onClick={() => setViewMode("cards")}
							className={`inline-flex cursor-pointer items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold transition max-sm:min-h-10 ${
								viewMode === "cards"
									? "bg-white font-bold text-relo-ink shadow-2xs"
									: "text-relo-muted"
							}`}
						>
							<LayoutGrid className="h-3.5 w-3.5" aria-hidden="true" />
							<span>{t.claims.viewCards}</span>
						</button>
						<button
							type="button"
							aria-pressed={viewMode === "table"}
							onClick={() => setViewMode("table")}
							className={`inline-flex cursor-pointer items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold transition max-sm:min-h-10 ${
								viewMode === "table"
									? "bg-white font-bold text-relo-ink shadow-2xs"
									: "text-relo-muted"
							}`}
						>
							<ListFilter className="h-3.5 w-3.5" aria-hidden="true" />
							<span>{t.claims.viewTable}</span>
						</button>
					</div>
				</div>
			</div>

			{rows.length === 0 ? (
				// Nothing matches the search: say so, and offer the way back to the full list.
				<Card className="space-y-4 py-12 text-center">
					<div className="space-y-1.5">
						<p className="text-base font-bold text-relo-ink">
							{fill(t.claims.noResults, { q: searchQuery.trim() })}
						</p>
						<p className="text-sm text-relo-muted">{t.claims.noResultsHint}</p>
					</div>
					<button
						type="button"
						onClick={() => setSearchQuery("")}
						className="inline-flex min-h-11 cursor-pointer items-center rounded-full bg-relo-sunken px-5 text-sm font-semibold text-relo-body hover:bg-[#e5e8eb]"
					>
						{t.claims.clearSearch}
					</button>
				</Card>
			) : viewMode === "cards" ? (
				<div className="grid gap-3">
					{rows.map((row) => {
						const c = row.original;
						const pct = receivedPercent(c);
						const arrived = receivedText(t, c);
						return (
							<AppLink
								key={c.id}
								to={`/claims/${c.id}`}
								className="group block rounded-[26px] border border-relo-line/80 bg-white p-6 shadow-[0_8px_28px_rgba(15,23,42,0.03)] transition-all hover:-translate-y-0.5 hover:border-relo-brand"
							>
								<div className="flex items-start justify-between gap-3">
									<div className="min-w-0 space-y-1">
										<div className="flex flex-wrap items-center gap-2">
											<span className="rounded-lg bg-[#f2f4f6] px-2 py-0.5 text-xs font-extrabold text-[#333d4b]">
												{c.currency}
											</span>
											<Badge tone={stateTone(c.state)}>
												{stateLabel(t, c.state, c.kind)}
											</Badge>
											<span className="text-xs font-medium text-relo-muted">
												{arrived !== null ? `${t.shared.kinds[c.kind]} · ` : ""}
												{c.vendor} · {c.orderRef}
											</span>
										</div>
										<h3 className="truncate text-lg font-bold tracking-[-0.025em] text-relo-ink">
											{c.title}
										</h3>
									</div>
									<ChevronRight
										className="h-5 w-5 shrink-0 text-relo-muted transition-transform group-hover:translate-x-1 group-hover:text-relo-brand"
										aria-hidden="true"
									/>
								</div>

								<div className="mt-4 flex flex-wrap items-baseline justify-between gap-2 text-xs sm:text-sm">
									{arrived !== null ? (
										<span className="text-relo-muted">
											{c.kind === "exchange"
												? t.kinds.progress.goodsLabel
												: t.kinds.progress.repairLabel}{" "}
											<strong className="ml-0.5 font-semibold text-relo-ink tabular-nums">
												{arrived}
											</strong>
										</span>
									) : (
										<div className="flex items-baseline gap-4">
											<span className="text-relo-muted">
												{t.pages.sumClaimed}{" "}
												<MoneyDisplay
													minor={c.claimed}
													currency={c.currency}
													className="ml-0.5 text-relo-ink"
												/>
											</span>
											<span className="text-relo-muted">
												{t.pages.sumRecovered}{" "}
												<MoneyDisplay
													minor={c.summary.cash}
													currency={c.currency}
													className="ml-0.5 text-relo-brand"
												/>
											</span>
										</div>
									)}
									<span className="text-xs font-semibold text-relo-brand">
										{nextStepText(t, c)}
									</span>
								</div>

								{agentWaiting.has(c.id) ? (
									<p
										className="mt-2 text-xs font-semibold text-relo-ink"
										data-testid="agent-waiting"
									>
										{t.claims.agentWaiting}
									</p>
								) : null}

								<div className="mt-3 h-1.5 w-full overflow-hidden rounded-full bg-[#eef2f6]">
									<div
										style={{ width: `${Math.max(8, pct)}%` }}
										className="h-full rounded-full bg-relo-brand"
									/>
								</div>
							</AppLink>
						);
					})}
				</div>
			) : (
				<Card className="overflow-hidden p-0">
					<div className="overflow-x-auto">
						<table className="w-full border-collapse text-left text-sm">
							<thead className="border-b border-relo-line bg-relo-sunken">
								{table.getHeaderGroups().map((hg) => (
									<tr key={hg.id}>
										{hg.headers.map((header) => (
											<th
												key={header.id}
												onClick={header.column.getToggleSortingHandler()}
												className="cursor-pointer px-4 py-3 text-xs font-extrabold text-relo-muted select-none hover:text-relo-ink"
											>
												{header.isPlaceholder ? null : (
													<table.FlexRender header={header} />
												)}
											</th>
										))}
										<th className="px-4 py-3 text-right text-xs font-extrabold text-relo-muted">
											{t.claims.colOpen}
										</th>
									</tr>
								))}
							</thead>
							<tbody className="divide-y divide-relo-line bg-white">
								{rows.map((row) => (
									<tr
										key={row.id}
										className="transition-colors hover:bg-relo-brand-soft/30"
									>
										{row.getAllCells().map((cell) => (
											<td key={cell.id} className="px-4 py-3.5">
												<table.FlexRender cell={cell} />
											</td>
										))}
										<td className="px-4 py-3.5 text-right">
											<AppLink
												to={`/claims/${row.original.id}`}
												className="inline-flex items-center gap-1 rounded-lg bg-relo-brand-soft px-2.5 py-1 text-xs font-bold text-relo-brand hover:bg-relo-brand hover:text-white"
											>
												<span>{t.claims.open}</span>
												<ChevronRight className="h-3.5 w-3.5" />
											</AppLink>
										</td>
									</tr>
								))}
							</tbody>
						</table>
					</div>
				</Card>
			)}
		</div>
	);
}
