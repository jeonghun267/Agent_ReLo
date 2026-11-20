import {toDecimal} from './money.mjs';
import {requestedQuantity} from './claim.mjs';

const REQUEST_PHRASE = {refund: 'a refund', exchange: 'an exchange', repair: 'a repair'};

// Rule-based English inquiry used when AI is unavailable or not consented to.
// It only restates saved facts; the user edits it before saving a version.
// The message is the consumer's own: written in the first person and signed with their name
// ([이름], the same placeholder the AI draft uses). ReLo is never the sender or an agent, so
// its name does not appear in the text.
export const NAME_PLACEHOLDER = '[이름]';

// Fills the placeholder with the name on the account. The name is added here, after the text
// came back, so it is never sent to the AI. Without a name the placeholder stays for the person.
export function signAs(body, name) {
  const mine = String(name ?? '').trim();
  return mine ? body.replaceAll(NAME_PLACEHOLDER, mine) : body;
}

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
    'Thank you,',
    NAME_PLACEHOLDER,
  );
  return lines.join('\n');
}
