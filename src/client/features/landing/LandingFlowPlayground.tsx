/**
 * @module client/features/landing/LandingFlowPlayground
 * @layer View (Interactive 5-Step Consumer Progress Map)
 * @purpose Renders a plain-language 5-step interactive @xyflow/react diagram showing
 *          the refund journey from order receipt reading to verified card deposit.
 */

import {
	Background,
	BackgroundVariant,
	Controls,
	type Edge,
	Handle,
	type Node,
	type NodeProps,
	Position,
	ReactFlow,
	useEdgesState,
	useNodesState,
} from "@xyflow/react";
import {
	ArrowRight,
	Camera,
	CheckCircle2,
	FileSearch,
	Languages,
	MailCheck,
	MessageSquareText,
} from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Badge, Button } from "@/client/components/ui/Primitives";
import { useI18n } from "@/client/i18n";

type StepNodeData = {
	stepNo: string;
	title: string;
	subtitle: string;
	badge: string;
	active: boolean;
	index: number;
};

function RefundStepNode({ data }: NodeProps<Node<StepNodeData>>) {
	const icons = [FileSearch, Camera, MessageSquareText, Languages, MailCheck];
	const Icon = icons[data.index % icons.length] ?? CheckCircle2;

	return (
		<div
			className={`w-48 cursor-pointer rounded-2xl border-2 p-3.5 transition-all duration-200 ${
				data.active
					? "border-relo-brand bg-white shadow-float ring-4 ring-relo-brand/15"
					: "border-relo-line bg-white/95 shadow-card hover:border-relo-brand-line"
			}`}
		>
			<Handle
				type="target"
				position={Position.Left}
				className="!h-2.5 !w-2.5 !border-2 !border-white !bg-relo-brand"
			/>
			<div className="flex items-center justify-between gap-1">
				<span className="text-[10px] font-extrabold tracking-wider text-relo-brand">
					{data.stepNo}
				</span>
				<span className="rounded-md bg-relo-sunken px-1.5 py-0.5 text-[10px] font-bold text-relo-muted">
					{data.badge}
				</span>
			</div>
			<div className="mt-2 flex items-center gap-2">
				<span
					className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-xl ${
						data.active
							? "bg-relo-brand text-white"
							: "bg-relo-brand-soft text-relo-brand"
					}`}
				>
					<Icon className="h-4 w-4" aria-hidden="true" />
				</span>
				<div className="min-w-0">
					<p className="truncate text-xs font-extrabold text-relo-ink">
						{data.title}
					</p>
					<p className="truncate text-[11px] text-relo-muted">
						{data.subtitle}
					</p>
				</div>
			</div>
			<Handle
				type="source"
				position={Position.Right}
				className="!h-2.5 !w-2.5 !border-2 !border-white !bg-relo-brand"
			/>
		</div>
	);
}

const NODE_TYPES = { refundStep: RefundStepNode };

const INITIAL_POSITIONS = [
	{ x: 16, y: 36 },
	{ x: 244, y: 148 },
	{ x: 472, y: 36 },
	{ x: 700, y: 148 },
	{ x: 928, y: 36 },
];

export function LandingFlowPlayground({
	onStartWizard,
}: {
	onStartWizard: () => void;
}) {
	const { t } = useI18n();
	const [activeId, setActiveId] = useState<string>("draft");

	const buildNodes = useCallback(
		(selectedId: string): Node<StepNodeData>[] =>
			t.flow.steps.map((step, index) => ({
				id: step.id,
				type: "refundStep",
				position: INITIAL_POSITIONS[index] ?? { x: index * 220, y: 50 },
				data: {
					stepNo: step.stepNo,
					title: step.title,
					subtitle: step.subtitle,
					badge: step.badge,
					active: step.id === selectedId,
					index,
				},
			})),
		[t.flow.steps],
	);

	const initialEdges = useMemo<Edge[]>(
		() =>
			t.flow.steps.slice(0, -1).map((step, idx) => ({
				id: `e-${step.id}-${t.flow.steps[idx + 1]?.id ?? idx}`,
				source: step.id,
				target: t.flow.steps[idx + 1]?.id ?? step.id,
				animated: true,
				style: { stroke: "#1b64da", strokeWidth: 2.5 },
			})),
		[t.flow.steps],
	);

	const [nodes, setNodes, onNodesChange] = useNodesState<Node<StepNodeData>>(
		buildNodes("draft"),
	);
	const [edges, , onEdgesChange] = useEdgesState(initialEdges);

	useEffect(() => {
		setNodes((curr) =>
			t.flow.steps.map((step, index) => {
				const existing = curr.find((n) => n.id === step.id);
				return {
					id: step.id,
					type: "refundStep",
					position: existing?.position ??
						INITIAL_POSITIONS[index] ?? { x: index * 220, y: 50 },
					data: {
						stepNo: step.stepNo,
						title: step.title,
						subtitle: step.subtitle,
						badge: step.badge,
						active: step.id === activeId,
						index,
					},
				};
			}),
		);
	}, [t.flow.steps, activeId, setNodes]);

	const selectStep = useCallback((id: string) => {
		setActiveId(id);
	}, []);

	const activeMeta =
		t.flow.steps.find((s) => s.id === activeId) ?? t.flow.steps[2];

	return (
		<section id="interactive-tour" className="bg-relo-canvas py-24 sm:py-32">
			<div className="mx-auto max-w-6xl px-4 sm:px-6">
				<div className="mb-8 flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
					<div className="space-y-2">
						<p className="text-[15px] font-bold text-relo-brand">
							{t.flow.eyebrow}
						</p>
						<h2 className="text-3xl leading-[1.22] font-bold tracking-[-0.035em] text-relo-ink sm:text-[40px]">
							{t.flow.title}
						</h2>
						<p className="text-[16px] text-relo-muted">{t.flow.subtitle}</p>
					</div>
					<div className="flex flex-wrap gap-1.5">
						{t.flow.steps.map((s) => (
							<button
								key={s.id}
								type="button"
								onClick={() => selectStep(s.id)}
								className={`cursor-pointer rounded-full px-3.5 py-2 text-xs font-semibold transition ${
									activeId === s.id
										? "bg-relo-ink text-white"
										: "bg-white text-relo-muted hover:bg-[#e5e8eb]"
								}`}
							>
								{s.title}
							</button>
						))}
					</div>
				</div>

				<div className="relo-flow h-72 w-full overflow-hidden rounded-3xl border border-relo-line bg-white shadow-card sm:h-80">
					<ReactFlow
						nodes={nodes}
						edges={edges}
						onNodesChange={onNodesChange}
						onEdgesChange={onEdgesChange}
						nodeTypes={NODE_TYPES}
						onNodeClick={(_, node) => selectStep(node.id)}
						fitView
						fitViewOptions={{ padding: 0.2 }}
						minZoom={0.45}
						maxZoom={1.4}
					>
						<Background
							variant={BackgroundVariant.Dots}
							gap={20}
							size={1.2}
							color="#cbd5e1"
						/>
						<Controls showInteractive={false} />
					</ReactFlow>
				</div>

				{activeMeta ? (
					<AnimatePresence mode="wait">
						<motion.div
							key={activeMeta.id}
							initial={{ opacity: 0, y: 10 }}
							animate={{ opacity: 1, y: 0 }}
							exit={{ opacity: 0, y: -6 }}
							transition={{ duration: 0.2 }}
							className="mt-4 grid gap-4 rounded-3xl border border-relo-brand-line bg-white p-5 shadow-card sm:grid-cols-12 sm:p-6"
						>
							<div className="space-y-3 sm:col-span-5">
								<div className="flex items-center gap-2">
									<Badge tone="brand">{activeMeta.stepNo}</Badge>
									<span className="text-xs font-bold text-relo-muted">
										{activeMeta.badge}
									</span>
								</div>
								<h3 className="text-lg font-extrabold text-relo-ink">
									{activeMeta.title}
								</h3>
								<p className="rounded-2xl bg-relo-brand-soft/65 p-3.5 text-xs leading-relaxed font-semibold text-relo-ink">
									{activeMeta.guide}
								</p>
								<ul className="space-y-1.5">
									{activeMeta.points.map((pt) => (
										<li
											key={pt}
											className="flex items-center gap-2 text-xs font-medium text-relo-body"
										>
											<CheckCircle2
												className="h-4 w-4 shrink-0 text-relo-brand"
												aria-hidden="true"
											/>
											<span>{pt}</span>
										</li>
									))}
								</ul>
							</div>

							<div className="flex flex-col justify-between rounded-2xl border border-relo-line bg-relo-sunken p-4 sm:col-span-7">
								<div>
									<p className="text-xs font-extrabold text-relo-muted">
										{activeMeta.previewTitle}
									</p>
									<pre className="mt-2.5 overflow-x-auto rounded-xl border border-relo-line bg-white p-3.5 font-sans text-xs leading-relaxed whitespace-pre-wrap text-relo-ink">
										{activeMeta.sample}
									</pre>
								</div>
								<div className="mt-4 flex justify-end">
									<Button variant="primary" size="md" onClick={onStartWizard}>
										<span>{t.flow.startBtn}</span>
										<ArrowRight className="h-4 w-4" aria-hidden="true" />
									</Button>
								</div>
							</div>
						</motion.div>
					</AnimatePresence>
				) : null}
			</div>
		</section>
	);
}
