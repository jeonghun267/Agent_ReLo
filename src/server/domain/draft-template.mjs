import {toDecimal} from './money.mjs';
import {requestedQuantity} from './claim.mjs';

const REQUEST_PHRASE = {refund: 'a refund', exchange: 'an exchange', repair: 'a repair'};

// Rule-based English inquiry used when AI is unavailable or not consented to.
// It only restates saved facts; the user edits it before saving a version.
export function templateDraft(claim) {
  const money = minor => `${claim.currency} ${toDecimal(minor, claim.currency)}`;
  const lines = [
    `Subject: Request for ${REQUEST_PHRASE[claim.kind]} - Order ${claim.orderRef}`,
    '',
    `Hello ${claim.vendor} Support,`,
    '',
    `I am contacting you about order ${claim.orderRef} placed on ${claim.orderedOn}: ${claim.title}.`,
    // Only a refund asks for money; for an exchange or a repair the amount is what the item cost.
    `Affected quantity: ${requestedQuantity(claim)}. ${claim.kind === 'refund' ? 'Amount requested' : 'Item price'}: ${money(claim.claimed)}.`,
  ];
  if (claim.kind === 'refund' && claim.agreed !== null) lines.push(`Amount previously agreed: ${money(claim.agreed)}.`);
  lines.push(
    '',
    claim.issueEnglish || `[Describe the problem in English. Original note in Korean: ${claim.issue}]`,
    '',
    'Could you please confirm the applicable policy, the evidence you need, the next steps, and whether any return shipping cost applies? I can provide photos and the order receipt.',
    '',
    'Thank you.',
  );
  return lines.join('\n');
}
