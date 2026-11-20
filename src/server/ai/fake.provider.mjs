// Deterministic provider for tests and offline development (AI_PROVIDER=fake).
// Pass responders to override one capability, e.g. to return bad output.
const DEFAULT_RESPONDERS = {
  draft: () => ({
    subject: 'Request for a refund - Order EG-2026-1001',
    body: 'Hello Support,\n\nOne of the two USB-C hubs from order EG-2026-1001 does not power on. I would like to request a refund for the defective unit. Please let me know which evidence you need.\n\nThank you,\n[이름]',
    summaryKo: '불량 1개에 대한 환불을 요청하고 필요한 증빙을 묻는 메일입니다.',
    missingInfo: ['보내는 사람 이름'],
  }),
  'translate-issue': () => ({english: 'One of the two units does not power on.'}),
  'analyze-reply': () => ({
    translationKo: '불량 제품 사진을 보내 주시면 환불을 진행하겠습니다.',
    summaryKo: '판매처가 불량 사진을 요청했어요. 사진을 보내면 환불을 진행한다고 합니다.',
    suggestedKind: 'evidence',
    mentionedAmount: null,
    mentionedCurrency: null,
    deadline: null,
    deadlineQuote: null,
  }),
  assistant: () => ({
    reply: '판매처가 아직 답하지 않았어요. 독촉 메일을 한 번 더 보내 보세요.',
    action: 'none',
    claimId: null,
    suggestions: ['독촉 메일 써 줘', '환불은 보통 며칠 걸려?'],
  }),
  extract: () => ({
    vendor: 'Example Gadgets EU',
    orderRef: 'EG-2026-1001',
    orderedOn: '2026-10-01',
    currency: 'EUR',
    total: '79.80',
    items: [{name: 'USB-C Hub 7-in-1', quantity: 2, unitPrice: '39.90'}],
    fields: [
      {field: 'vendor', value: 'Example Gadgets EU', quote: 'Seller: Example Gadgets EU'},
      {field: 'orderRef', value: 'EG-2026-1001', quote: 'Order: EG-2026-1001'},
      {field: 'total', value: '79.80', quote: 'Total: EUR 79.80'},
    ],
  }),
  // Filing a new request from one line. The fake reads the kind from a few words, takes the
  // first item of the order and one piece of it.
  intake: request => {
    const text = request.parts[0].text;
    const open = '<consumer_text>\n';
    const said = text.slice(text.indexOf(open) + open.length, text.indexOf('\n</consumer_text>'));
    const kind = /교환|exchange|交換|换货/i.test(said) ? 'exchange' : /수리|고쳐|repair|修理|维修/i.test(said) ? 'repair' : 'refund';
    const hasItems = !text.includes('<order_items>\n[]');
    const word = {refund: '환불', exchange: '교환', repair: '수리'}[kind];
    return {
      kind,
      itemIndex: hasItems ? 0 : null,
      claimQty: 1,
      issueEnglish: 'One of the two units does not power on.',
      understood: hasItems ? `주문한 물건 1개에 문제가 있어 ${word}을 요청하는 것으로 읽었어요.` : `${word}을 요청하는 것으로 읽었어요. 주문서가 없어 어떤 물건인지는 직접 적어 주세요.`,
    };
  },
  // The agent loop's choice. The fake goes in a fixed order: read each file, analyze each
  // reply that has no analysis, propose correcting an order number or date a document
  // disagrees with (and stop if that was declined or cannot be fixed), write one draft, propose
  // saving it, then stop. That exercises the loop offline, but it says nothing about whether a
  // real model chooses by the state of the claim; that is checked with the real one.
  plan: request => {
    const text = request.parts[0].text;
    // The request carries the facts as JSON between <claim> and <steps_so_far> tags (factsBlock).
    const block = name => {
      const open = `<${name}>\n`;
      const start = text.indexOf(open) + open.length;
      return JSON.parse(text.slice(start, text.indexOf(`\n</${name}>`, start)));
    };
    const claim = block('claim');
    const steps = block('steps_so_far');
    const ran = (tool, id) => steps.some(step => step.tool === tool && (id === undefined || step.fileId === id || step.replyId === id));
    const choose = (tool, ids, reason) => ({done: false, tool, fileId: null, replyId: null, ...ids, reason, userAction: null});
    const stop = (reason, userAction) => ({done: true, tool: null, fileId: null, replyId: null, reason, userAction});

    const file = claim.files.find(item => !ran('read_evidence', item.fileId));
    if (file) return choose('read_evidence', {fileId: file.fileId}, `올린 자료 "${file.name}"을(를) 아직 읽지 않았어요. 저장된 주문 정보와 맞는지 먼저 확인해요.`);
    const reply = claim.sellerReplies.find(item => !item.hasAnalysis && !ran('analyze_reply', item.replyId));
    if (reply) return choose('analyze_reply', {replyId: reply.replyId}, '쇼핑몰 답장이 저장돼 있는데 아직 풀어 본 적이 없어요. 무엇을 요구하는지 먼저 읽어요.');

    const differing = steps.filter(step => step.differsFromSaved?.length);
    if (differing.length) {
      const fixable = differing.find(step => step.differsFromSaved.some(item => ['orderRef', 'orderedOn'].includes(item.field)));
      if (fixable && !ran('fix_order_facts')) {
        return choose('fix_order_facts', {fileId: fixable.fileId}, '자료에서 읽은 주문 정보가 저장된 값과 달라요. 틀린 정보로 글을 쓰지 않으려고 먼저 자료대로 고칠지 여쭤봐요.');
      }
      return stop('자료에서 읽은 값이 저장된 주문 정보와 달라요. 틀린 정보로 글을 쓰지 않으려고 여기서 멈춰요.', '신청 내용의 주문번호 · 주문일 · 통화가 자료와 맞는지 먼저 확인해 주세요.');
    }
    if (!ran('write_draft') && (claim.savedMessages === 0 || claim.latestMessage?.outOfDate || claim.sellerReplies.length > 0)) {
      return choose('write_draft', {}, '확인할 자료와 답장을 다 봤어요. 이제 쇼핑몰에 보낼 글이 필요해요.');
    }
    const draft = steps.find(step => step.tool === 'write_draft' && step.ok);
    if (draft?.writtenFromCurrentFacts && !ran('save_draft')) {
      return choose('save_draft', {}, '쓴 글을 이 건에 저장해 두면 복사해서 바로 보낼 수 있어요. 저장할지 여쭤봐요.');
    }
    const saved = steps.some(step => step.tool === 'save_draft' && step.saved);
    if (saved) return stop('보낼 글을 저장했어요. 이제 보내는 일은 직접 하셔야 해요.', '저장된 글을 복사해 쇼핑몰에 내 이름으로 직접 보내고, 보냈으면 "보냈어요"를 눌러 주세요.');
    return stop('지금 AI가 더 할 수 있는 일이 없어요.', ran('write_draft') ? '써 둔 글을 읽어 보고 고친 뒤, 내 이름으로 직접 보내 주세요.' : '쇼핑몰 답장이 오면 붙여 넣어 주세요.');
  },
};

export function createFakeProvider(responders = {}) {
  const all = {...DEFAULT_RESPONDERS, ...responders};
  return {
    name: 'fake',
    model: 'fake-model',
    enabled: true,
    calls: [],
    async generateJson(request) {
      this.calls.push(request);
      return {data: await all[request.capability](request), model: 'fake-model', usage: {inputTokens: 10, outputTokens: 20}};
    },
  };
}
