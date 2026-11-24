// Does the real model choose by the state of the claim, or does it always go in one order?
// Asks the real Gemini for the NEXT choice of an agent run on six situations, several times
// each, and prints what it chose and why. The first two differ only in the state of the
// claim (the first choice of a run). The other four are in the middle of a run: a document
// that agrees with the saved order, one that disagrees with the saved order number, a draft
// that was just written, and a fix the person declined. They show whether the model proposes
// an action when one is called for, and stops when the person said no.
//   1. Put GEMINI_API_KEY (and optionally GEMINI_MODEL) in .env
//   2. npm run agent:branch            (3 tries per case = 18 small API calls, plus 3 for filing from one line)
//      npm run agent:branch -- 5       (5 tries per case)
// The fake provider used by the tests always follows a fixed order, so only this script can
// show whether the loop is an agent (the model picks the path) or a workflow in disguise.
// Both outcomes are results: if the choices do not differ, report that as a limit. Never prints the key.
import {loadConfig} from '../src/server/config.mjs';
import {createGeminiProvider} from '../src/server/ai/gemini.provider.mjs';
import {buildPlanRequest, parsePlan} from '../src/server/ai/prompts/plan.mjs';
import {buildIntakeRequest, parseIntake} from '../src/server/ai/prompts/intake.mjs';

const config = loadConfig();
if (config.ai.provider !== 'gemini') {
  console.error('GEMINI_API_KEY가 설정되지 않았어요. 프로젝트 루트 .env에 GEMINI_API_KEY=... 를 넣은 뒤 다시 실행하세요.');
  process.exit(1);
}
const tries = Math.max(1, Number.parseInt(process.argv[2] ?? '3', 10) || 3);
const provider = createGeminiProvider(config.ai);

const base = {
  title: 'USB-C 허브 7-in-1', vendor: 'Example Gadgets EU', orderRef: 'EG-2026-1001', orderedOn: '2026-10-01',
  kind: 'refund', currency: 'EUR', claimed: 3990, agreed: null, deadline: null,
  issue: '두 개 중 한 개가 전원이 들어오지 않습니다. 다른 노트북과 케이블로도 확인했습니다.', issueEnglish: '',
};
const orderFile = {id: 'file_order', name: 'order-EG-2026-1001.pdf', mime: 'application/pdf', usedAsProof: false};
const photo = {id: 'file_photo', name: 'defect-photo.jpg', mime: 'image/jpeg', usedAsProof: false};
const sentDraft = {createdAt: '2026-11-10T02:00:00Z', submittedAt: '2026-11-10T02:05:00Z', stale: false};
const askForPhoto = {
  id: 'reply_1', recordedAt: '2026-11-12T08:00:00Z', kind: 'other', summaryKo: '', aiAssisted: false,
  body: 'Thanks for reaching out. Before we can proceed, please send a clear photo of the defective unit and its serial number.',
};

// What the loop tells the planner after read_evidence on the order document (see forPlanner).
const readStep = {
  step: 1, tool: 'read_evidence', fileId: 'file_order', ok: true,
  read: {seller: 'Example Gadgets EU', orderNumber: 'EG-2026-1001', orderDate: '2026-10-01', currency: 'EUR', orderTotal: '79.80', items: 1},
};

const CASES = [
  {
    name: '자료만 올라옴, 답변 없음, 보낸 글 없음',
    expected: 'read_evidence',
    claim: {...base, state: 'preparing', files: [orderFile], replies: [], drafts: []},
  },
  {
    name: '글을 보냈고, 추가 자료를 달라는 답변이 저장돼 있음 (아직 풀지 않음)',
    expected: 'analyze_reply',
    claim: {...base, state: 'awaiting', files: [orderFile, photo], replies: [askForPhoto], drafts: [sentDraft]},
  },
  {
    // Until 2026-11-24 this case marked the file as proof of a received payment on a claim with
    // no message yet: a state that cannot happen, and the model's answers on it could not be
    // judged. It now is the plain middle of a run: the document was read and agrees.
    name: '(실행 중) 자료를 읽었고 저장된 값과 같음, 영어 설명 있음, 보낸 글 없음',
    expected: 'write_draft',
    claim: {
      ...base, state: 'preparing', issueEnglish: 'One of the two hubs does not power on. I tested it with another laptop and cable.',
      files: [orderFile], replies: [], drafts: [],
    },
    steps: [{...readStep, differsFromSaved: []}],
  },
  {
    name: '(실행 중) 자료를 읽었더니 주문번호가 저장된 값과 다름',
    expected: 'fix_order_facts',
    claim: {...base, orderRef: 'EG-2026-1010', state: 'preparing', files: [orderFile], replies: [], drafts: []},
    steps: [{...readStep, differsFromSaved: [{field: 'orderRef', saved: 'EG-2026-1010', read: 'EG-2026-1001'}]}],
  },
  {
    name: '(실행 중) 자료가 맞았고 방금 글을 썼음, 더 채울 것 없음',
    expected: 'save_draft',
    claim: {...base, state: 'preparing', issueEnglish: 'One of the two hubs does not power on.', files: [orderFile], replies: [], drafts: []},
    steps: [
      {...readStep, differsFromSaved: []},
      {step: 2, tool: 'write_draft', ok: true, summary: '불량 1개의 환불을 요청하고 필요한 증빙을 묻는 메일입니다.', stillMissing: [], writtenFromCurrentFacts: true},
    ],
  },
  {
    name: '(실행 중) 주문번호를 고치자고 했는데 고객이 허락하지 않음',
    expected: 'done',
    claim: {...base, orderRef: 'EG-2026-1010', state: 'preparing', files: [orderFile], replies: [], drafts: []},
    steps: [
      {...readStep, differsFromSaved: [{field: 'orderRef', saved: 'EG-2026-1010', read: 'EG-2026-1001'}]},
      {step: 2, tool: 'fix_order_facts', fileId: 'file_order', ok: true, decision: 'declined', changed: []},
    ],
  },
];

console.log(`Gemini model: ${config.ai.model} · 경우마다 ${tries}번\n`);
const firstChoices = [];
let failed = 0;
for (const testCase of CASES) {
  const ids = {fileIds: new Set(testCase.claim.files.map(file => file.id)), replyIds: new Set(testCase.claim.replies.map(reply => reply.id))};
  const chosen = [];
  console.log(`■ ${testCase.name}\n  기대하는 선택: ${testCase.expected}`);
  for (let attempt = 1; attempt <= tries; attempt += 1) {
    try {
      const answer = await provider.generateJson(buildPlanRequest(testCase.claim, testCase.steps ?? [], 'ko'));
      const plan = parsePlan(answer.data, ids);
      const label = plan.done ? (plan.dropped ? '(버려진 선택)' : 'done') : plan.tool;
      chosen.push(label);
      console.log(`  ${attempt}. ${label}${plan.fileId ? ` ${plan.fileId}` : ''}${plan.replyId ? ` ${plan.replyId}` : ''} — ${plan.reason}`);
    } catch (error) {
      // A refused key or an unknown model fails every call the same way: stop at the first one.
      if (error.code === 'ai_config') {
        console.error(`  Google이 요청을 받지 않았어요 (키가 틀렸거나 만료됐거나, 모델 이름 ${config.ai.model} 을(를) 쓸 수 없는 키예요).`);
        console.error('  https://aistudio.google.com/apikey 에서 키를 확인해 .env 의 GEMINI_API_KEY 를 바꾼 뒤 다시 실행하세요. 재지 못했어요.');
        process.exit(1);
      }
      failed += 1;
      chosen.push('(실패)');
      console.log(`  ${attempt}. 실패: ${error.code ?? 'error'} ${error.message}`);
    }
  }
  const matched = chosen.filter(label => label === testCase.expected).length;
  console.log(`  → 기대와 같은 선택 ${matched}/${tries}, 고른 것: ${[...new Set(chosen)].join(', ')}\n`);
  firstChoices.push(new Set(chosen));
}

const distinct = new Set(firstChoices.flatMap(set => [...set]).filter(label => !label.startsWith('(')));
console.log(distinct.size > 1
  ? `상태에 따라 선택이 갈렸어요: ${[...distinct].join(', ')}`
  : `모든 경우에 선택이 같았어요 (${[...distinct].join(', ') || '없음'}). 루프가 고정 순서로 돈다는 뜻이니 한계로 적어야 해요.`);

// Filing from one line: does the model read the kind of request and pick the right item?
// Each line is asked once (3 more calls).
const orderItems = [{name: 'USB-C Hub 7-in-1', orderedQty: 2}, {name: 'HDMI Cable 2m', orderedQty: 1}];
const LINES = [
  {text: '허브 두 개 중 하나가 전원이 안 켜져요. 환불받고 싶어요.', expected: {kind: 'refund', itemIndex: 0, claimQty: 1}},
  {text: 'HDMI 케이블이 휘어서 왔어요. 새 걸로 바꿔 주세요.', expected: {kind: 'exchange', itemIndex: 1}},
  {text: '허브가 한 달 쓰니 충전이 안 돼요. 고쳐 주실 수 있나요?', expected: {kind: 'repair', itemIndex: 0}},
];
console.log('\n■ 신청 한 줄 읽기 (종류 · 상품 · 수량)');
for (const line of LINES) {
  try {
    const answer = await provider.generateJson(buildIntakeRequest({text: line.text, items: orderItems, locale: 'ko'}));
    const read = parseIntake(answer.data, orderItems);
    const same = Object.entries(line.expected).every(([name, value]) => read[name] === value);
    if (!same) failed += 1;
    console.log(`  ${same ? '같음' : '다름'}: "${line.text}"\n    기대 ${JSON.stringify(line.expected)}\n    읽은 것 ${JSON.stringify({kind: read.kind, itemIndex: read.itemIndex, claimQty: read.claimQty})} — ${read.understood}`);
  } catch (error) {
    failed += 1;
    console.log(`  실패: ${error.code ?? 'error'} ${error.message}`);
  }
}
process.exitCode = failed ? 1 : 0;
