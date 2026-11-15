import {reject, forField} from './errors.mjs';
import {cleanText, requireText, parseDate, parsePastDate, parseOptionalUrl, parseInteger} from './validation.mjs';
import {parseCurrency, parseMoney} from './money.mjs';
import {sha256} from './primitives.mjs';

export const CLAIM_KINDS = Object.freeze({refund: '반품·환불', exchange: '교환', repair: 'AS'});

// The words people see for each state. The web and the app use the same words
// (shop = 쇼핑몰, money that came back = 입금), so one refund is never called two things.
export const STATES = Object.freeze({
  preparing: '서류 준비',
  review: '메시지 검토',
  awaiting: '답변 대기',
  negotiating: '조율 중',
  partial: '일부 입금',
  disputed: '분쟁',
  waived: '포기',
  recovered: '입금 확인',
  completed: '완료',
});

export const CLOSED_STATES = Object.freeze(['waived', 'completed']);

export const REPLY_KINDS = Object.freeze({
  evidence: '자료 추가 요청',
  agreement: '환불 약속',
  refund_notice: '환불 처리 알림',
  denied: '거절',
  other: '기타',
});

export const DEADLINE_ZONES = Object.freeze([
  'Asia/Seoul', 'UTC', 'America/Los_Angeles', 'America/New_York',
  'Europe/London', 'Europe/Berlin', 'Asia/Tokyo', 'Asia/Shanghai',
]);

const MAX_ITEMS = 30;

// Validates the user-editable facts of a claim. Returns the stored payload.
// Fields are checked in form order so the first error matches the first wrong input.
// Each error carries the input name (forField) for inline display.
export function parseClaimInput(input = {}) {
  const title = forField('title', () => requireText(input.title, 150, '상품명을 입력하세요.'));
  const vendor = forField('vendor', () => requireText(input.vendor, 100, '판매처를 입력하세요.'));
  const orderRef = forField('orderRef', () => requireText(input.orderRef, 100, '주문번호를 입력하세요.'));
  const orderedOn = forField('orderedOn', () => parsePastDate(input.orderedOn));
  forField('kind', () => reject(!Object.hasOwn(CLAIM_KINDS, input.kind), '반품·환불, 교환, AS 중 하나를 선택하세요.'));
  const currency = forField('currency', () => parseCurrency(input.currency));
  const claimed = forField('claimedAmount', () => {
    const amount = parseMoney(input.claimedAmount, currency);
    reject(amount === 0, '청구액은 0보다 커야 합니다.');
    return amount;
  });
  const agreed = forField('agreedAmount', () => {
    if (input.agreedAmount === '' || input.agreedAmount == null) return null;
    const amount = parseMoney(input.agreedAmount, currency);
    reject(amount > claimed, '합의액은 청구액보다 클 수 없습니다.');
    return amount;
  });
  const vendorUrl = forField('vendorUrl', () => parseOptionalUrl(input.vendorUrl));
  const issue = forField('issue', () => requireText(input.issue, 3000, '문제 설명을 입력하세요.'));
  const items = parseItems(input.items, currency);
  const deadline = forField('deadline', () => input.deadline ? parseDate(input.deadline) : null);
  const deadlineQuote = cleanText(input.deadlineQuote, 1000);
  forField('deadlineQuote', () => reject(deadline && !deadlineQuote, '기한은 판매처 원문 근거와 함께 기록하세요.'));
  return {
    title,
    vendor,
    vendorUrl,
    orderRef,
    orderedOn,
    kind: input.kind,
    currency,
    items,
    claimed,
    agreed,
    issue,
    issueEnglish: cleanText(input.issueEnglish, 3000),
    deadline,
    deadlineQuote,
    deadlineZone: DEADLINE_ZONES.includes(input.deadlineZone) ? input.deadlineZone : 'Asia/Seoul',
  };
}

// Item errors point at "items.<index>.<field>".
function parseItems(items, currency) {
  forField('items', () => reject(!Array.isArray(items) || items.length < 1 || items.length > MAX_ITEMS, `품목을 1~${MAX_ITEMS}개 입력하세요.`));
  return items.map((item, index) => {
    const at = name => `items.${index}.${name}`;
    const name = forField(at('name'), () => requireText(item.name, 150, '품목명을 입력하세요.'));
    const orderedQty = forField(at('orderedQty'), () => parseInteger(item.orderedQty, {min: 1, max: 10000}, '주문 수량은 1~10000 사이로 입력하세요.'));
    const claimQty = forField(at('claimQty'), () => parseInteger(item.claimQty, {min: 1, max: orderedQty}, '문제 수량은 1 이상, 주문 수량 이하로 입력하세요.'));
    const unitPrice = forField(at('unitPrice'), () => parseMoney(item.unitPrice, currency));
    return {name, sku: cleanText(item.sku, 100), orderedQty, claimQty, unitPrice};
  });
}

export function requestedQuantity(claim) {
  return claim.items.reduce((sum, item) => sum + item.claimQty, 0);
}

// Sums what was actually recovered. Reversal entries copy the amount/quantity
// of the entry they cancel, so subtracting them undoes it.
export function totals(claim, ledger) {
  const reversed = new Set(ledger.filter(entry => entry.reverses).map(entry => entry.reverses));
  let cash = 0;
  let goods = 0;
  for (const entry of ledger) {
    if (entry.kind === 'cash') cash += entry.amount;
    if (entry.kind === 'goods') goods += entry.quantity;
    if (entry.kind === 'reversal') { cash -= entry.amount; goods -= entry.quantity; }
  }
  const repair = ledger.some(entry => entry.kind === 'repair' && !reversed.has(entry.id));
  return {
    cash,
    goods,
    repair,
    remaining: Math.max(0, (claim.agreed ?? claim.claimed) - cash),
    requestedQty: requestedQuantity(claim),
  };
}

export function isRecovered(claim, summary) {
  if (claim.kind === 'refund') return claim.agreed !== null && claim.agreed > 0 && summary.cash === claim.agreed;
  if (claim.kind === 'exchange') return summary.goods === summary.requestedQty;
  return summary.repair;
}

export function stateAfterReceipt(currentState, claim, summary) {
  if (currentState === 'disputed') return 'disputed';
  if (isRecovered(claim, summary)) return 'recovered';
  return summary.cash || summary.goods ? 'partial' : 'negotiating';
}

export function stateAfterReply(kind, currentState) {
  if (kind === 'denied') return 'disputed';
  if (kind === 'refund_notice') return 'awaiting';
  return currentState;
}

export const TRANSITIONS = Object.freeze(['awaiting', 'negotiating', 'disputed', 'waived', 'reopen', 'close']);

export function nextStateForTransition(action, claim, currentState, summary) {
  if (action === 'reopen') {
    reject(!['waived', 'disputed', 'completed'].includes(currentState), '지금 상태에서는 재개할 수 없습니다.');
    if (isRecovered(claim, summary)) return 'recovered';
    return summary.cash || summary.goods ? 'partial' : 'negotiating';
  }
  if (action === 'close') {
    reject(!isRecovered(claim, summary), '합의액 입금이나 교환·수리 결과를 실제로 확인한 뒤에 종료할 수 있습니다.');
    return 'completed';
  }
  reject(!['awaiting', 'negotiating', 'disputed', 'waived'].includes(action), '지원하지 않는 상태 변경입니다.');
  reject(CLOSED_STATES.includes(currentState), '먼저 사유를 남기고 재개하세요.');
  return action;
}

// A hash of the facts an inquiry draft was written from. When it changes,
// earlier drafts are marked stale and must be rewritten before sending.
export function factualFingerprint(claim, files) {
  return sha256(JSON.stringify({
    title: claim.title,
    vendor: claim.vendor,
    orderRef: claim.orderRef,
    issue: claim.issue,
    issueEnglish: claim.issueEnglish,
    kind: claim.kind,
    items: claim.items,
    claimed: claim.claimed,
    agreed: claim.agreed,
    currency: claim.currency,
    files: files.map(file => [file.id, file.sha]).sort(),
  }));
}

// The one thing to do next, as a code. The web shows its own sentence for the code in the
// reader's language; NEXT_STEP_TEXT is the Korean sentence for anything that does not.
export function nextStepCode(view) {
  if (view.deleted) return 'trashed';
  if (view.state === 'waived') return 'waived';
  if (view.state === 'disputed') return 'disputed';
  if (view.state === 'completed') return 'completed';
  if (view.state === 'recovered') return 'recovered';
  if (view.summary.remaining && view.summary.cash) return 'remaining';
  if (view.state === 'awaiting') return 'awaiting';
  if (!view.files.length) return 'needFiles';
  if (!view.drafts.length) return 'needMessage';
  if (view.agreed === null) return 'needAgreed';
  return 'needProof';
}

export const NEXT_STEP_TEXT = Object.freeze({
  trashed: '휴지통에 있어요. 복원하면 이어서 진행할 수 있어요.',
  waived: '포기로 기록했어요. 필요하면 다시 진행할 수 있어요.',
  disputed: '쇼핑몰과 의견이 달라요. 근거를 더 올리고 다음 조건을 정리해 보세요.',
  completed: '마무리된 건이에요. 입금 기록을 확인할 수 있어요.',
  recovered: '입금을 확인했어요. 내용을 살펴보고 마무리해 주세요.',
  remaining: '남은 금액과 쇼핑몰이 정한 기한을 확인해 주세요.',
  awaiting: '쇼핑몰 답장이 오면 붙여 넣고 약속 금액을 적어 주세요.',
  needFiles: '주문 내역이나 불량 사진을 올려 주세요.',
  needMessage: '쇼핑몰에 보낼 메시지를 준비해 주세요.',
  needAgreed: '쇼핑몰이 약속한 금액이 정해지면 적어 주세요.',
  needProof: '실제로 들어온 돈을 캡처와 함께 기록해 주세요.',
});

export function nextStep(view) {
  return NEXT_STEP_TEXT[nextStepCode(view)];
}
