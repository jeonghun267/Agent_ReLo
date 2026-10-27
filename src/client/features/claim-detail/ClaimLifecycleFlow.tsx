/**
 * @module client/features/claim-detail/ClaimLifecycleFlow
 * @layer View (Single-Case Progress Pipeline)
 * @purpose Renders the 6-stage refund status pipeline for an individual claim using
 *          plain consumer Korean and a unified Toss Blue + Slate palette.
 */

import {
	Background,
	BackgroundVariant,
	type Edge,
	Handle,
	type Node,
	type NodeProps,
	Position,
	ReactFlow,
} from "@xyflow/react";
import { CheckCircle2, CircleDot } from "lucide-react";
import { useMemo } from "react";
import type { ClaimState } from "@/client/types";

const ORDERED_FLOW: Array<{ id: ClaimState; label: string; sub: string }> = [
	{ id: "preparing", label: "서류 준비", sub: "영수증 · 불량 사진" },
	{ id: "review", label: "메시지 준비", sub: "외국어 요청서 작성" },
	{ id: "awaiting", label: "답변 대기", sub: "쇼핑몰 전송 완료" },
	{ id: "negotiating", label: "조건 조율", sub: "환불 금액 확인" },
	{ id: "recovered", label: "입금 확인", sub: "실제 카드 취소" },
	{ id: "completed", label: "완료", sub: "마무리 완료" },
];

function stageRank(state: ClaimState): number {
	if (state === "partial") return 3.5;
	if (state === "disputed" || state === "waived") return 3;
	const idx = ORDERED_FLOW.findIndex((s) => s.id === state);
	return idx === -1 ? 0 : idx;
}

type LifecycleNodeData = {
	label: string;
	sub: string;
	status: "done" | "current" | "upcoming" | "alert";
};

function LifecycleNode({ data }: NodeProps<Node<LifecycleNodeData>>) {
	const styles = {
		done: "border-relo-brand-line bg-relo-brand-soft/85 text-relo-brand",
		current:
			"border-relo-brand bg-white text-relo-brand shadow-float ring-4 ring-relo-brand/15",
		alert: "border-relo-danger bg-relo-danger-soft text-relo-danger",
		upcoming: "border-relo-line bg-white/85 text-relo-muted",
	}[data.status];

	return (
		<div className={`w-36 rounded-2xl border-2 px-3 py-2.5 ${styles}`}>
			<Handle
				type="target"
				position={Position.Left}
				className="!h-2 !w-2 !border-0 !bg-slate-400"
			/>
			<div className="flex items-center gap-1.5">
				{data.status === "done" ? (
					<CheckCircle2 className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
				) : (
					<CircleDot className="h-3.5 w-3.5 shrink-0" aria-hidden="true" />
				)}
				<p className="truncate text-xs font-extrabold text-relo-ink">
					{data.label}
				</p>
			</div>
			<p className="mt-0.5 truncate text-[10px] font-medium text-relo-muted">
				{data.sub}
			</p>
			<Handle
				type="source"
				position={Position.Right}
				className="!h-2 !w-2 !border-0 !bg-slate-400"
			/>
		</div>
	);
}

const NODE_TYPES = { lifecycle: LifecycleNode };

export function ClaimLifecycleFlow({ state }: { state: ClaimState }) {
	const rank = stageRank(state);

	const nodes = useMemo<Node<LifecycleNodeData>[]>(
		() =>
			ORDERED_FLOW.map((stage, idx) => {
				let status: LifecycleNodeData["status"] = "upcoming";
				if (idx < rank) status = "done";
				else if (Math.floor(rank) === idx) {
					status =
						state === "disputed" || state === "waived" ? "alert" : "current";
				}
				return {
					id: stage.id,
					type: "lifecycle",
					position: { x: idx * 172, y: idx % 2 === 0 ? 18 : 66 },
					draggable: false,
					data: {
						label:
							idx === 3 && state === "partial"
								? "일부 입금 확인"
								: idx === 3 && state === "disputed"
									? "추가 확인 필요"
									: stage.label,
						sub: stage.sub,
						status,
					},
				};
			}),
		[rank, state],
	);

	const edges = useMemo<Edge[]>(
		() =>
			ORDERED_FLOW.slice(0, -1).map((stage, idx) => ({
				id: `lc-${stage.id}`,
				source: stage.id,
				target: ORDERED_FLOW[idx + 1]?.id ?? stage.id,
				animated: idx <= Math.ceil(rank),
				style: {
					stroke: idx <= rank ? "#1b64da" : "#cbd5e1",
					strokeWidth: 2,
				},
			})),
		[rank],
	);

	return (
		<div className="relo-flow h-44 w-full overflow-hidden rounded-2xl border border-relo-line bg-relo-sunken/70">
			<ReactFlow
				nodes={nodes}
				edges={edges}
				nodeTypes={NODE_TYPES}
				fitView
				fitViewOptions={{ padding: 0.18 }}
				nodesDraggable={false}
				nodesConnectable={false}
				zoomOnScroll={false}
				panOnDrag
			>
				<Background
					variant={BackgroundVariant.Dots}
					gap={18}
					size={1}
					color="#cbd5e1"
				/>
			</ReactFlow>
		</div>
	);
}
