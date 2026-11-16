/**
 * @module client/features/claim-detail/EvidenceAndSettlementTab
 * @layer View (Private Photo Vault & "It Actually Came In" Tab)
 * @purpose Combines the stored files with the form that records what really came back
 *          (a card refund or deposit, replacement items, a repair) and the list of those
 *          records. The form steps aside once everything is recorded or the claim is closed.
 */

import { PackageCheck, Wallet, Wrench } from "lucide-react";
import { Badge, Card } from "@/client/components/ui/Primitives";
import { ClaimFilesVaultCard } from "@/client/features/claim-detail/ClaimFilesVaultCard";
import { ReceiptForm } from "@/client/features/claim-detail/ReceiptForm";
import { ReceiptLedgerList } from "@/client/features/claim-detail/ReceiptLedgerList";
import { useI18n } from "@/client/i18n";
import { isAllReceived, isLocked } from "@/client/lib/claim-progress";
import { kindWords } from "@/client/lib/claim-words";
import type { ClaimView } from "@/client/types";

const KIND_ICONS = { refund: Wallet, exchange: PackageCheck, repair: Wrench };

export function EvidenceAndSettlementTab({ claim }: { claim: ClaimView }) {
	const { t } = useI18n();
	const s = kindWords(t, claim.kind)?.settlement ?? t.detail.settlement;
	const Icon = KIND_ICONS[claim.kind];
	const locked = isLocked(claim);
	const { summary } = claim;

	return (
		<div className="space-y-5">
			<ClaimFilesVaultCard claim={claim} />

			<Card className="space-y-4 border-relo-brand-line">
				<div>
					<Badge tone="brand">
						<Icon className="h-3.5 w-3.5" aria-hidden="true" />
						<span>{s.eyebrow}</span>
					</Badge>
					<h3 className="mt-1 text-lg font-extrabold text-relo-ink">
						{s.title}
					</h3>
				</div>

				{locked || isAllReceived(claim) ? (
					<p className="rounded-2xl bg-relo-sunken px-4 py-3 text-sm text-relo-body">
						{locked ? t.kinds.receipt.locked : t.kinds.receipt.allDone}
					</p>
				) : (
					// A new form whenever what is still owed changes, so it never offers a stale amount.
					<ReceiptForm
						key={`${claim.kind}:${claim.agreed}:${summary.cash}:${summary.goods}:${summary.repair}`}
						claim={claim}
					/>
				)}

				<ReceiptLedgerList claim={claim} title={s.ledgerTitle} />
			</Card>
		</div>
	);
}
