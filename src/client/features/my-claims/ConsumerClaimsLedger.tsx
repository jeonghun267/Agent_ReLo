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
import { formatKoreanDate } from "@/client/lib/format";
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

function stateTone(
	state: ClaimState,
): "brand" | "sunny" | "danger" | "neutral" {
	if (state === "disputed") return "danger";
	if (state === "awaiting" || state === "negotiating" || state === "partial")
		return "sunny";
	if (state === "waived") return "neutral";
	return "brand";
}

export function ConsumerClaimsLedger({
	claims,
	stateLabels,
}: {
	claims: ClaimView[];
	stateLabels?: Record<ClaimState, string>;
}) {
	const { t } = useI18n();
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
					header: "신청 상품 · 쇼핑몰",
					sortFn: "alphanumeric",
					cell: (info) => {
						const row = info.row.original;
						return (
							<div>
								<p className="font-extrabold text-relo-ink">{row.title}</p>
								<p className="text-xs text-relo-muted">
									{row.vendor} · 주문번호 {row.orderRef}
								</p>
							</div>
						);
					},
				}),
				columnHelper.accessor("state", {
					header: "진행 상태",
					sortFn: "alphanumeric",
					cell: (info) => {
						const st = info.getValue();
						return (
							<Badge tone={stateTone(st)}>{stateLabels?.[st] ?? st}</Badge>
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
					header: "최근 업데이트",
					sortFn: "alphanumeric",
					cell: (info) => (
						<span className="text-xs text-relo-muted tabular-nums">
							{formatKoreanDate(info.getValue())}
						</span>
					),
				}),
			]),
		[stateLabels, t],
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
						내 환불 내역 검색
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
						placeholder="쇼핑몰, 상품명, 주문번호 검색"
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
						<span>금액순</span>
					</button>

					<div className="inline-flex rounded-full bg-relo-sunken p-1">
						<button
							type="button"
							onClick={() => setViewMode("cards")}
							className={`inline-flex cursor-pointer items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold transition ${
								viewMode === "cards"
									? "bg-white font-bold text-relo-ink shadow-2xs"
									: "text-relo-muted"
							}`}
						>
							<LayoutGrid className="h-3.5 w-3.5" aria-hidden="true" />
							<span>카드로 보기</span>
						</button>
						<button
							type="button"
							onClick={() => setViewMode("table")}
							className={`inline-flex cursor-pointer items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold transition ${
								viewMode === "table"
									? "bg-white font-bold text-relo-ink shadow-2xs"
									: "text-relo-muted"
							}`}
						>
							<ListFilter className="h-3.5 w-3.5" aria-hidden="true" />
							<span>표로 보기</span>
						</button>
					</div>
				</div>
			</div>

			{viewMode === "cards" ? (
				<div className="grid gap-3">
					{rows.map((row) => {
						const c = row.original;
						const pct =
							c.claimed > 0
								? Math.min(100, Math.round((c.summary.cash / c.claimed) * 100))
								: 0;
						return (
							<AppLink
								key={c.id}
								to={`/claims/${c.id}`}
								className="group block rounded-[26px] border border-relo-line/80 bg-white p-6 shadow-[0_8px_28px_rgba(15,23,42,0.03)] transition-all hover:-translate-y-0.5 hover:border-relo-brand"
							>
								<div className="flex items-start justify-between gap-3">
									<div className="min-w-0 space-y-1">
										<div className="flex flex-wrap items-center gap-2">
											<span className="rounded-lg bg-[#f2f4f6] px-2 py-0.5 text-[11px] font-extrabold text-[#333d4b]">
												{c.currency}
											</span>
											<Badge tone={stateTone(c.state)}>
												{stateLabels?.[c.state] ?? c.state}
											</Badge>
											<span className="text-xs font-medium text-relo-muted">
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
									<span className="text-xs font-semibold text-relo-brand">
										{c.nextStep}
									</span>
								</div>

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
											상세
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
												<span>열기</span>
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
