import test from 'node:test';
import assert from 'node:assert/strict';
import {startApp, createClaim, current, editInput, key, PASSWORD} from '../helpers/app.mjs';
import {createFakeProvider} from '../../src/server/ai/fake.provider.mjs';
import {AppError} from '../../src/server/domain/errors.mjs';
import {parsePlan} from '../../src/server/ai/prompts/plan.mjs';
import {fixtureOrderPdf} from '../../src/server/dev/fixtures.mjs';

// The agent loop: the model chooses the next tool toward the goal of the claim, the server
// runs it, the result goes into the next choice. A tool that would change the claim is only
// proposed; it runs after the person approves. These tests use a scripted planner, so they
// check the machinery around the choice (limits, repeats, failed steps, foreign ids, waiting
// for approval, nothing changed without it), not the choosing itself.

async function consentedUser(client) {
  const user = await client().signup();
  assert.equal((await user.call('/api/account/ai-consent', {method: 'POST', data: {consent: true}})).status, 200);
  return user;
}

const runAgent = (user, claim) => user.call(`/api/claims/${claim.id}/ai/agent`, {method: 'POST', data: {locale: 'ko'}});
const decide = (user, claim, run, approve) =>
  user.call(`/api/claims/${claim.id}/ai/agent/${run.runId}/decision`, {method: 'POST', data: {approve, locale: 'ko'}});
const overview = async (user, claim) => (await user.call(`/api/claims/${claim.id}/ai/agent`)).data;

// A planner that answers from a script, one entry per call. The last entry repeats.
function scripted(...answers) {
  let turn = 0;
  return request => {
    const answer = answers[Math.min(turn, answers.length - 1)];
    turn += 1;
    return typeof answer === 'function' ? answer(request) : answer;
  };
}
const choose = (tool, ids = {}) => ({done: false, tool, fileId: null, replyId: null, ...ids, reason: `${tool}이(가) 필요해요.`, userAction: null});
const stop = (userAction = '글을 읽어 보고 직접 보내 주세요.') => ({done: true, tool: null, fileId: null, replyId: null, reason: '더 할 일이 없어요.', userAction});
const capabilities = provider => provider.calls.map(call => call.capability);
const tools = run => run.steps.map(step => step.tool);
const noIds = {fileIds: new Set(), replyIds: new Set()};

test('the model chooses the tools, the server runs them, and each result goes into the next choice', async t => {
  let fileId;
  const provider = createFakeProvider({plan: scripted(() => choose('read_evidence', {fileId}), choose('write_draft'), stop())});
  const {client} = await startApp(t, {aiProvider: provider});
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  fileId = claim.files[0].id;

  const result = await runAgent(user, claim);
  assert.equal(result.status, 200, JSON.stringify(result.data));
  const run = result.data;
  assert.equal(run.status, 'finished');
  assert.equal(run.endedBy, 'done');
  assert.equal(run.pending, null);
  assert.deepEqual(tools(run), ['read_evidence', 'write_draft']);
  assert.deepEqual(capabilities(provider), ['plan', 'extract', 'plan', 'draft', 'plan'], 'a choice before every tool, and one last choice to stop');
  assert.equal(run.aiCalls, 5);
  assert.equal(run.userAction, '글을 읽어 보고 직접 보내 주세요.');

  // The tools ran for real and returned what the buttons return.
  assert.equal(run.steps[0].result.suggestion.orderRef, 'EG-2026-1001');
  assert.equal(run.steps[0].fileName, 'order.pdf');
  assert.deepEqual(run.steps[0].mismatches, [{field: 'orderRef', saved: claim.orderRef, read: 'EG-2026-1001'}], 'the document disagrees with the saved order number');
  assert.match(run.steps[1].result.body, /^Subject: /);
  assert.equal(run.steps[0].reason, 'read_evidence이(가) 필요해요.', 'why the model chose it is kept');

  // The goal comes first, and the second choice was made knowing what the first step found.
  assert.match(provider.calls[0].parts[0].text, /"goal": "The consumer gets a refund of EUR 79\.80 from the seller/);
  const secondChoice = provider.calls[2].parts[0].text;
  assert.match(secondChoice, /"tool": "read_evidence"/);
  assert.match(secondChoice, /"differsFromSaved"/);
  assert.match(secondChoice, /"orderNumber": "EG-2026-1001"/);
  assert.match(provider.calls[4].parts[0].text, /"tool": "write_draft"/);
  // The planner is not shown the rule-based next step, so its choice is its own.
  assert.doesNotMatch(provider.calls[0].parts[0].text, /nextStep/);

  // Reading tools change nothing: no draft, same version, same facts.
  const after = await current(user, claim.id);
  assert.equal(after.version, claim.version);
  assert.equal(after.drafts.length, 0);
  assert.equal(after.orderRef, claim.orderRef);

  // The run is recorded and belongs to the user's data.
  const exported = (await user.call('/api/account/export')).data;
  assert.equal(exported.agentRuns.length, 1);
  const recorded = exported.agentRuns[0];
  assert.deepEqual({arm: recorded.arm, endedBy: recorded.endedBy, stepCount: recorded.stepCount, planCount: recorded.planCount, claimId: recorded.claimId},
    {arm: 'C', endedBy: 'done', stepCount: 2, planCount: 3, claimId: claim.id});
  assert.deepEqual(recorded.steps.map(step => [step.seq, step.tool, step.target, step.ok]), [[1, 'read_evidence', fileId, true], [2, 'write_draft', '', true]]);
});

test('an action is proposed, waits for the person, and runs only after approval; then the run goes on', async t => {
  const {client, aiProvider} = await startApp(t);
  const user = await consentedUser(client);
  const claim = await createClaim(user);

  // The document's order number differs from the saved one: the agent proposes the fix and stops.
  const first = (await runAgent(user, claim)).data;
  assert.equal(first.status, 'waiting');
  assert.equal(first.endedBy, null);
  assert.deepEqual(tools(first), ['read_evidence']);
  assert.deepEqual(first.pending, {
    tool: 'fix_order_facts', reason: first.pending.reason, fileName: 'order.pdf',
    changes: [{field: 'orderRef', from: claim.orderRef, to: 'EG-2026-1001'}], draftBody: null,
  });
  assert.deepEqual(capabilities(aiProvider), ['plan', 'extract', 'plan']);

  // Nothing has changed yet, and the proposal is still there when the claim is opened again.
  let now = await current(user, claim.id);
  assert.equal(now.version, claim.version);
  assert.equal(now.orderRef, claim.orderRef);
  const opened = await overview(user, claim);
  assert.equal(opened.waiting.runId, first.runId);
  assert.equal(opened.waiting.pending.tool, 'fix_order_facts');
  assert.equal(opened.last, null);

  // Approved: the fact is corrected through the normal update, and the run goes on to write.
  const second = (await decide(user, claim, first, true)).data;
  assert.equal(second.status, 'waiting');
  assert.deepEqual(tools(second), ['read_evidence', 'fix_order_facts', 'write_draft']);
  assert.deepEqual({decision: second.steps[1].decision, ok: second.steps[1].ok, changes: second.steps[1].changes},
    {decision: 'approved', ok: true, changes: [{field: 'orderRef', from: claim.orderRef, to: 'EG-2026-1001'}]});
  now = await current(user, claim.id);
  assert.equal(now.orderRef, 'EG-2026-1001');
  assert.equal(now.version, claim.version + 1);
  assert.deepEqual({items: now.items, claimed: now.claimed, agreed: now.agreed, issue: now.issue, orderedOn: now.orderedOn, kind: now.kind},
    {items: claim.items, claimed: claim.claimed, agreed: claim.agreed, issue: claim.issue, orderedOn: claim.orderedOn, kind: claim.kind}, 'only the order number changed');
  assert.equal(now.events.some(event => event.action === '사건 정보 수정'), true, 'the change is in the claim history like any edit');
  // The next choice saw the claim as it is now: the difference is gone.
  const afterFix = aiProvider.calls.filter(call => call.capability === 'plan')[2].parts[0].text;
  assert.match(afterFix, /"orderNumber": "EG-2026-1001"/);
  assert.match(afterFix, /"decision": "approved"/);
  assert.match(afterFix, /"differsFromSaved": \[\]/);

  // The message it wrote is proposed for saving, signed with the name on the account.
  assert.equal(second.pending.tool, 'save_draft');
  assert.match(second.pending.draftBody, /Thank you,\n테스트$/);
  assert.doesNotMatch(second.pending.draftBody, /\[이름\]/);
  assert.equal(now.drafts.length, 0, 'not saved before approval');

  const third = (await decide(user, claim, second, true)).data;
  assert.equal(third.status, 'finished');
  assert.equal(third.endedBy, 'done');
  assert.deepEqual(tools(third), ['read_evidence', 'fix_order_facts', 'write_draft', 'save_draft']);
  assert.match(third.userAction, /직접 보내/);
  assert.equal(third.aiCalls, 7, 'five choices and two reading tools; carrying out an action is not an AI call');
  now = await current(user, claim.id);
  assert.equal(now.drafts.length, 1);
  assert.deepEqual({origin: now.drafts[0].origin, body: now.drafts[0].body, stale: now.drafts[0].stale, sent: Boolean(now.drafts[0].submittedAt)},
    {origin: 'ai', body: second.pending.draftBody, stale: false, sent: false}, 'saved as a normal version; sending and marking as sent stay with the person');
  assert.equal(now.state, 'review');

  // The record: every step, the decisions, and what the agent asked the person to do.
  const [recorded] = (await user.call('/api/account/export')).data.agentRuns;
  assert.deepEqual({endedBy: recorded.endedBy, stepCount: recorded.stepCount, planCount: recorded.planCount, userAction: recorded.userAction},
    {endedBy: 'done', stepCount: 4, planCount: 5, userAction: third.userAction});
  assert.deepEqual(recorded.steps.map(step => [step.tool, step.decision]), [['read_evidence', ''], ['fix_order_facts', 'approved'], ['write_draft', ''], ['save_draft', 'approved']]);
  assert.equal('pausedState' in recorded, false, 'a finished run keeps no copy of what it read or wrote');
  const closed = await overview(user, claim);
  assert.equal(closed.waiting, null);
  assert.deepEqual({endedBy: closed.last.endedBy, userAction: closed.last.userAction, steps: closed.last.steps.length}, {endedBy: 'done', userAction: third.userAction, steps: 4});

  // The answer cannot be given twice.
  const again = await decide(user, claim, second, true);
  assert.equal(again.status, 409);
  assert.equal(again.data.error, 'agent_not_waiting');
  assert.equal((await current(user, claim.id)).drafts.length, 1);
});

test('a declined action changes nothing, the next choice sees the decision, and the next run remembers it', async t => {
  const {client, aiProvider} = await startApp(t);
  const user = await consentedUser(client);
  const claim = await createClaim(user);

  const first = (await runAgent(user, claim)).data;
  const declined = (await decide(user, claim, first, false)).data;
  assert.equal(declined.status, 'finished');
  assert.equal(declined.endedBy, 'done');
  assert.deepEqual(declined.steps.map(step => [step.tool, step.decision, step.ok]), [['read_evidence', '', true], ['fix_order_facts', 'declined', true]]);
  assert.match(declined.userAction, /주문번호/);
  const after = await current(user, claim.id);
  assert.deepEqual({version: after.version, orderRef: after.orderRef, drafts: after.drafts.length}, {version: claim.version, orderRef: claim.orderRef, drafts: 0});
  const plans = () => aiProvider.calls.filter(call => call.capability === 'plan').map(call => call.parts[0].text);
  assert.match(plans()[2], /"decision": "declined"/);
  assert.match(plans()[0], /<earlier_runs>\n\[\]\n<\/earlier_runs>/, 'the first run has nothing to remember');

  // The second run is told what the first one did and what the person decided.
  const second = (await runAgent(user, claim)).data;
  const memory = plans()[3];
  assert.match(memory, /<earlier_runs>/);
  assert.match(memory, /"endedBy": "done"/);
  assert.match(memory, /"tool": "fix_order_facts",[^}]*"decision": "declined"/);
  assert.match(memory, /"toldConsumer": "신청 내용의 주문번호/);

  // A proposal that is never answered is closed when another run starts.
  assert.equal(second.status, 'waiting');
  const third = (await runAgent(user, claim)).data;
  assert.equal(third.status, 'waiting');
  const late = await decide(user, claim, second, true);
  assert.equal(late.status, 409);
  assert.equal((await current(user, claim.id)).orderRef, claim.orderRef);
  const exported = (await user.call('/api/account/export')).data.agentRuns;
  assert.deepEqual(exported.map(run => run.endedBy), ['done', 'abandoned', 'waiting']);
  assert.equal(exported[2].pausedState.pending.tool, 'fix_order_facts', 'what a waiting run holds is part of the export');
  assert.equal((await overview(user, claim)).waiting.runId, third.runId);
});

test('when the document agrees the fake planner writes and proposes saving; declining leaves no draft', async t => {
  const {client} = await startApp(t);
  const user = await consentedUser(client);
  const claim = await createClaim(user, {orderRef: 'EG-2026-1001'});

  const drafted = (await runAgent(user, claim)).data;
  assert.deepEqual(tools(drafted), ['read_evidence', 'write_draft']);
  assert.deepEqual(drafted.steps[0].mismatches, []);
  assert.equal(drafted.pending.tool, 'save_draft');

  const declined = (await decide(user, claim, drafted, false)).data;
  assert.equal(declined.endedBy, 'done');
  assert.equal(declined.steps[2].decision, 'declined');
  assert.match(declined.userAction, /읽어 보고/);
  const after = await current(user, claim.id);
  assert.deepEqual({drafts: after.drafts.length, version: after.version, state: after.state}, {drafts: 0, version: claim.version, state: claim.state});
});

test('an action that is not possible in this run is dropped, and its values never come from the model', async t => {
  let fileId;
  const {client} = await startApp(t, {aiProvider: createFakeProvider({plan: scripted(choose('save_draft'))})});
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  const nothingWritten = (await runAgent(user, claim)).data;
  assert.equal(nothingWritten.endedBy, 'invalid_choice', 'there is no draft from this run to save');
  assert.equal(nothingWritten.pending, null);

  const notRead = await startApp(t, {aiProvider: createFakeProvider({plan: scripted(() => choose('fix_order_facts', {fileId}))})});
  const second = await consentedUser(notRead.client);
  const unread = await createClaim(second);
  fileId = unread.files[0].id;
  assert.equal((await runAgent(second, unread)).data.endedBy, 'invalid_choice', 'the document was not read in this run');

  // Nothing to fix when the document agrees. An extra orderRef in the model's answer is ignored.
  const agrees = await startApp(t, {aiProvider: createFakeProvider({plan: scripted(() => choose('read_evidence', {fileId}), () => ({...choose('fix_order_facts', {fileId}), orderRef: 'HACKED-1'}))})});
  const third = await consentedUser(agrees.client);
  const same = await createClaim(third, {orderRef: 'EG-2026-1001'});
  fileId = same.files[0].id;
  const run = (await runAgent(third, same)).data;
  assert.equal(run.endedBy, 'invalid_choice');
  assert.equal((await current(third, same.id)).orderRef, 'EG-2026-1001');

  // A draft written before the facts changed cannot be saved: it has to be written again.
  const stale = await startApp(t, {aiProvider: createFakeProvider({plan: scripted(() => choose('read_evidence', {fileId}), choose('write_draft'), () => choose('fix_order_facts', {fileId}), choose('save_draft'))})});
  const fourth = await consentedUser(stale.client);
  const differs = await createClaim(fourth);
  fileId = differs.files[0].id;
  const proposal = (await runAgent(fourth, differs)).data;
  assert.equal(proposal.pending.tool, 'fix_order_facts');
  const afterFix = (await decide(fourth, differs, proposal, true)).data;
  assert.equal(afterFix.endedBy, 'invalid_choice');
  assert.equal((await current(fourth, differs.id)).drafts.length, 0);

  assert.equal(parsePlan(choose('fix_order_facts', {fileId: 'nope'}), {fileIds: new Set(['f1']), replyIds: new Set()}).dropped, true);
  assert.equal(parsePlan(choose('fix_order_facts', {fileId: 'f1'}), {fileIds: new Set(['f1']), replyIds: new Set()}).fileId, 'f1');
  assert.equal(parsePlan(choose('save_draft'), noIds).tool, 'save_draft');
});

test('a claim edited between the proposal and the approval is not overwritten', async t => {
  const {client} = await startApp(t);
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  const proposal = (await runAgent(user, claim)).data;
  assert.equal(proposal.pending.tool, 'fix_order_facts');

  const edited = await user.call(`/api/claims/${claim.id}`, {method: 'PATCH', version: claim.version, data: editInput(claim, {orderRef: 'MY-OWN-FIX-7'})});
  assert.equal(edited.status, 200, JSON.stringify(edited.data));

  const run = (await decide(user, claim, proposal, true)).data;
  assert.deepEqual({tool: run.steps[1].tool, decision: run.steps[1].decision, ok: run.steps[1].ok, errorCode: run.steps[1].errorCode},
    {tool: 'fix_order_facts', decision: 'approved', ok: false, errorCode: 'conflict'});
  assert.equal(run.status, 'finished');
  assert.equal((await current(user, claim.id)).orderRef, 'MY-OWN-FIX-7');
});

test('only the owner can answer a proposal, and the answer must be yes or no', async t => {
  const {client} = await startApp(t);
  const owner = await consentedUser(client);
  const claim = await createClaim(owner);
  const proposal = (await runAgent(owner, claim)).data;

  const stranger = await consentedUser(client);
  assert.equal((await decide(stranger, claim, proposal, true)).status, 404);
  assert.equal((await stranger.call(`/api/claims/${claim.id}/ai/agent`)).status, 404);
  const vague = await owner.call(`/api/claims/${claim.id}/ai/agent/${proposal.runId}/decision`, {method: 'POST', data: {approve: 'yes'}});
  assert.equal(vague.status, 422);
  assert.equal((await current(owner, claim.id)).orderRef, claim.orderRef);
  assert.equal((await decide(owner, claim, proposal, true)).status, 200, 'the proposal was still waiting');
});

test('a saved seller reply can be chosen by its id; the text sent for analysis is the saved one', async t => {
  let replyId;
  const provider = createFakeProvider({plan: scripted(() => choose('analyze_reply', {replyId}), stop('사진을 보내 주세요.'))});
  const {client} = await startApp(t, {aiProvider: provider});
  const user = await consentedUser(client);
  let claim = await createClaim(user);
  const body = 'Please send a photo of the defect before we can refund you.';
  claim = (await user.call(`/api/claims/${claim.id}/replies`, {method: 'POST', version: claim.version, key: key(), data: {body, kind: 'evidence'}})).data.claim;
  replyId = claim.replies[0].id;

  const run = (await runAgent(user, claim)).data;
  assert.deepEqual(run.steps.map(step => [step.tool, step.replyId, step.ok]), [['analyze_reply', replyId, true]]);
  assert.equal(run.steps[0].result.suggestedKind, 'evidence');
  assert.ok(provider.calls[1].parts[0].text.includes(body), 'the reply text came from the claim, not from the model');
  assert.equal((await current(user, claim.id)).replies[0].summaryKo, '', 'the analysis is not attached to the saved reply');
});

test('the loop needs consent and enough calls left for a whole run before it starts', async t => {
  const {client, aiProvider} = await startApp(t, {env: {AI_HOURLY_LIMIT: '9'}});
  const stranger = await client().signup();
  const claim = await createClaim(stranger);
  assert.equal((await runAgent(stranger, claim)).data.error, 'ai_consent_required');

  await stranger.call('/api/account/ai-consent', {method: 'POST', data: {consent: true}});
  const refused = await runAgent(stranger, claim);
  assert.equal(refused.status, 429, 'five rounds need ten calls and only nine are allowed');
  assert.equal(refused.data.error, 'ai_rate_limited');
  assert.equal(aiProvider.calls.length, 0, 'nothing was sent in either case');
});

test('a choice outside the tool list or outside the claim is dropped, not run', async t => {
  let foreignFileId;
  const provider = createFakeProvider({plan: scripted(() => choose('read_evidence', {fileId: foreignFileId}))});
  const {client} = await startApp(t, {aiProvider: provider});
  const other = await consentedUser(client);
  foreignFileId = (await createClaim(other)).files[0].id;
  const user = await consentedUser(client);
  const claim = await createClaim(user);

  const run = (await runAgent(user, claim)).data;
  assert.equal(run.endedBy, 'invalid_choice');
  assert.deepEqual(run.steps, []);
  assert.deepEqual(capabilities(provider), ['plan'], 'the other user\'s file was never read');

  assert.equal(parsePlan(choose('send_email'), noIds).dropped, true, 'there is no tool that sends');
  assert.equal(parsePlan(choose('mark_as_sent'), noIds).dropped, true, 'or that says the person sent it');
  assert.equal(parsePlan(choose('analyze_reply', {replyId: 'nope'}), {fileIds: new Set(), replyIds: new Set(['r1'])}).dropped, true);
  assert.equal(parsePlan(choose('write_draft'), noIds).tool, 'write_draft');
  assert.equal(parsePlan(stop(), noIds).dropped, false);
  assert.throws(() => parsePlan({tool: 'write_draft'}, noIds), {code: 'ai_bad_output'});
});

test('the same tool on the same file again ends the run', async t => {
  let fileId;
  const provider = createFakeProvider({plan: scripted(() => choose('read_evidence', {fileId}))});
  const {client} = await startApp(t, {aiProvider: provider});
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  fileId = claim.files[0].id;

  const run = (await runAgent(user, claim)).data;
  assert.equal(run.endedBy, 'repeat');
  assert.equal(run.steps.length, 1);
  assert.deepEqual(capabilities(provider), ['plan', 'extract', 'plan']);
});

test('the step limit ends the run without one more choice', async t => {
  let fileId;
  const provider = createFakeProvider({plan: scripted(() => choose('read_evidence', {fileId}), choose('write_draft'))});
  const {client} = await startApp(t, {aiProvider: provider, env: {AGENT_MAX_STEPS: '2'}});
  assert.equal((await client().call('/api/config')).data.ai.agentMaxSteps, 2);
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  fileId = claim.files[0].id;

  const run = (await runAgent(user, claim)).data;
  assert.equal(run.endedBy, 'max_steps');
  assert.equal(run.maxSteps, 2);
  assert.deepEqual(capabilities(provider), ['plan', 'extract', 'plan', 'draft']);
});

test('an approved action counts as a step: the limit can end the run right after it', async t => {
  const {client} = await startApp(t, {env: {AGENT_MAX_STEPS: '2'}});
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  const proposal = (await runAgent(user, claim)).data;
  const run = (await decide(user, claim, proposal, true)).data;
  assert.equal(run.endedBy, 'max_steps');
  assert.deepEqual(tools(run), ['read_evidence', 'fix_order_facts']);
  assert.equal((await current(user, claim.id)).orderRef, 'EG-2026-1001');
});

test('a tool that fails is kept as a failed step and the run goes on', async t => {
  let fileId;
  const provider = createFakeProvider({
    plan: scripted(() => choose('read_evidence', {fileId}), choose('write_draft'), stop()),
    extract: () => { throw new AppError(502, 'ai_bad_output', 'AI 응답 형식이 올바르지 않아요. 다시 시도해 주세요.'); },
  });
  const {client} = await startApp(t, {aiProvider: provider});
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  fileId = claim.files[0].id;

  const run = (await runAgent(user, claim)).data;
  assert.equal(run.endedBy, 'done');
  assert.deepEqual(run.steps.map(step => [step.tool, step.ok, step.errorCode]), [['read_evidence', false, 'ai_bad_output'], ['write_draft', true, '']]);
  assert.match(provider.calls[2].parts[0].text, /"error": "ai_bad_output"/, 'the next choice sees the failure');
});

test('a run is only for the owner\'s claim, and it is erased with the account', async t => {
  const {client} = await startApp(t);
  const owner = await consentedUser(client);
  const claim = await createClaim(owner, {orderRef: 'EG-2026-1001'});
  const stranger = await consentedUser(client);
  assert.equal((await runAgent(stranger, claim)).status, 404);

  assert.equal((await runAgent(owner, claim)).status, 200);
  assert.equal((await owner.call('/api/account/export')).data.agentRuns.length, 1);
  const deleted = await owner.call('/api/account/delete', {method: 'POST', data: {password: PASSWORD}});
  assert.equal(deleted.status, 200, JSON.stringify(deleted.data));
});

test('uploading more evidence gives the planner more to choose from', async t => {
  const {client, aiProvider} = await startApp(t);
  const user = await consentedUser(client);
  let claim = await createClaim(user, {orderRef: 'EG-2026-1001'});
  claim = (await user.call(`/api/claims/${claim.id}/files`, {
    // Not the same bytes as order.pdf: the same file is not stored twice.
    method: 'POST', raw: Buffer.concat([fixtureOrderPdf(), Buffer.from(' % second copy')]), version: claim.version, key: key(),
    headers: {'Content-Type': 'application/pdf', 'X-File-Name': 'second.pdf'},
  })).data.claim;
  assert.equal(claim.files.length, 2);

  const run = (await runAgent(user, claim)).data;
  assert.deepEqual(tools(run), ['read_evidence', 'read_evidence', 'write_draft']);
  assert.deepEqual(run.steps.slice(0, 2).map(step => step.fileName).sort(), ['order.pdf', 'second.pdf']);
  assert.equal(run.pending.tool, 'save_draft');
  assert.equal(aiProvider.calls.filter(call => call.capability === 'plan').length, 4);
});
