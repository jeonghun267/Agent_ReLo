import test from 'node:test';
import assert from 'node:assert/strict';
import {startApp, createClaim, current, key} from '../helpers/app.mjs';
import {createFakeProvider} from '../../src/server/ai/fake.provider.mjs';

// The agent starting by itself. A person may leave their claims to it; from then on a run
// starts when something happens on a claim (filed, a file added, a reply recorded). It is off
// until they turn it on, it needs the AI consent, it leaves part of the hourly limit for the
// person's own buttons, and a run that started by itself changes nothing without approval.

const DELAY = {AGENT_AUTO_DELAY_MS: '150'};

async function consentedUser(client, {auto = true} = {}) {
  const user = await client().signup();
  assert.equal((await user.call('/api/account/ai-consent', {method: 'POST', data: {consent: true}})).status, 200);
  if (auto) assert.equal((await setAuto(user, true)).status, 200);
  return user;
}

const setAuto = (user, on) => user.call('/api/account/agent-auto', {method: 'POST', data: {on}});
const overview = async (user, claim) => (await user.call(`/api/claims/${claim.id}/ai/agent`)).data;
const runAgent = (user, claim) => user.call(`/api/claims/${claim.id}/ai/agent`, {method: 'POST', data: {locale: 'ko'}});
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
const capabilities = provider => provider.calls.map(call => call.capability);
const stop = () => ({done: true, tool: null, fileId: null, replyId: null, reason: '더 할 일이 없어요.', userAction: '답장이 오면 붙여 넣어 주세요.'});

// Waits until the agent is no longer at work on the claim (nothing scheduled, nothing running).
async function settled(user, claim) {
  for (let turn = 0; turn < 200; turn += 1) {
    const now = await overview(user, claim);
    if (!now.working) return now;
    await sleep(25);
  }
  throw new Error('the agent is still at work');
}

const recordReply = async (user, claim, headers = {}) => {
  const now = await current(user, claim.id);
  const result = await user.call(`/api/claims/${claim.id}/replies`, {
    method: 'POST', version: now.version, headers,
    data: {body: 'Please send a photo of the defective unit.', kind: 'evidence'},
  });
  assert.equal(result.status, 200, JSON.stringify(result.data));
  return result.data.claim;
};

test('it is off until the person turns it on, and turning it on needs the AI consent', async t => {
  const {client, aiProvider} = await startApp(t, {env: DELAY});
  const user = await client().signup();

  const refused = await setAuto(user, true);
  assert.equal(refused.status, 403);
  assert.equal(refused.data.error, 'ai_consent_required');

  assert.equal((await user.call('/api/account/ai-consent', {method: 'POST', data: {consent: true}})).status, 200);
  assert.equal((await user.call('/api/me')).data.user.agentAutoAt, null, 'consenting to AI does not leave the claims to the agent');

  // Consented but not left to the agent: filing a request and adding a file start nothing.
  const claim = await createClaim(user);
  await sleep(300);
  const quiet = await overview(user, claim);
  assert.deepEqual({working: quiet.working, waiting: quiet.waiting, last: quiet.last}, {working: false, waiting: null, last: null});
  assert.deepEqual(capabilities(aiProvider), []);

  const on = await setAuto(user, true);
  assert.equal(on.status, 200);
  assert.ok(on.data.user.agentAutoAt);
  assert.equal((await user.call('/api/me')).data.user.agentAutoAt, on.data.user.agentAutoAt);
  assert.equal((await user.call('/api/account/export')).data.user.agentAutoAt, on.data.user.agentAutoAt);

  // Withdrawing the consent takes the claims back from the agent as well.
  const withdrawn = await user.call('/api/account/ai-consent', {method: 'POST', data: {consent: false}});
  assert.equal(withdrawn.data.user.agentAutoAt, null);
  await recordReply(user, claim);
  await sleep(300);
  assert.equal((await overview(user, claim)).last, null);
  assert.deepEqual(capabilities(aiProvider), []);
});

test('a new request starts one run by itself; it stops on a proposal and changes nothing', async t => {
  const {client, aiProvider} = await startApp(t, {env: DELAY});
  const user = await consentedUser(client);

  // Filing and the file that follows are two events; they make one run, named after the first.
  const claim = await createClaim(user);
  assert.equal((await overview(user, claim)).working, true, 'the screen can tell the agent is about to start');
  const after = await settled(user, claim);

  assert.equal(after.waiting.status, 'waiting');
  assert.equal(after.waiting.startedBy, 'filed');
  assert.equal(after.waiting.pending.tool, 'fix_order_facts', 'the document disagrees with the saved order number');
  assert.deepEqual(after.waiting.steps.map(step => step.tool), ['read_evidence']);
  assert.deepEqual(capabilities(aiProvider), ['plan', 'extract', 'plan'], 'one run, not one per event');
  assert.match(aiProvider.calls[0].parts[0].text, /"thisRunStarted": "It began by itself: the consumer has just filed this request\."/);

  // Nothing was changed: the proposal waits for the person.
  const now = await current(user, claim.id);
  assert.equal(now.version, claim.version);
  assert.equal(now.orderRef, claim.orderRef);
  assert.equal(now.drafts.length, 0);

  // The list of claims can mark it, and only for its owner.
  assert.deepEqual((await user.call('/api/ai/agent/waiting')).data.claims, [{claimId: claim.id, tool: 'fix_order_facts'}]);
  const other = await consentedUser(client);
  assert.deepEqual((await other.call('/api/ai/agent/waiting')).data.claims, []);

  // The person answers; the run goes on exactly like one they started themself.
  const next = await user.call(`/api/claims/${claim.id}/ai/agent/${after.waiting.runId}/decision`, {method: 'POST', data: {approve: true, locale: 'ko'}});
  assert.equal(next.status, 200, JSON.stringify(next.data));
  assert.equal(next.data.pending.tool, 'save_draft');
  assert.equal((await current(user, claim.id)).orderRef, 'EG-2026-1001');
  // The approved change is the agent's own: it does not wake the agent again.
  await sleep(300);
  assert.equal((await overview(user, claim)).waiting.runId, after.waiting.runId);
});

test('a recorded seller reply starts a run by itself, in the language of the screen', async t => {
  const {client, aiProvider} = await startApp(t, {env: DELAY});
  const user = await consentedUser(client, {auto: false});
  const claim = await createClaim(user);
  await setAuto(user, true);

  await recordReply(user, claim, {'X-Relo-Locale': 'en'});
  const after = await settled(user, claim);
  assert.equal(after.waiting.startedBy, 'reply');
  assert.match(aiProvider.calls[0].parts[0].text, /has just recorded a reply from the seller/);
  assert.match(aiProvider.calls[0].system, /Write reason and userAction in English/);
  assert.ok(capabilities(aiProvider).includes('analyze-reply'), 'it read the new reply');

  // A later event closes the unanswered proposal and starts over on the changed claim.
  const before = after.waiting.runId;
  await recordReply(user, claim);
  const again = await settled(user, claim);
  assert.notEqual(again.waiting.runId, before);
  const runs = (await user.call('/api/account/export')).data.agentRuns;
  assert.deepEqual(runs.map(run => [run.startedBy, run.endedBy]), [['reply', 'abandoned'], ['reply', 'waiting']]);
});

test('it leaves part of the hourly limit for the person, and never starts without room', async t => {
  // 2 x 5 steps for a run + a sixth of 12 kept back = 12 calls must be left.
  const {client, aiProvider} = await startApp(t, {env: {...DELAY, AI_HOURLY_LIMIT: '12'}});
  const user = await consentedUser(client, {auto: false});
  const claim = await createClaim(user);
  await setAuto(user, true);
  assert.equal((await overview(user, claim)).heldBack, false);

  // The person uses one call themself: 11 are left, one short.
  assert.equal((await user.call('/api/ai/translate-issue', {method: 'POST', data: {text: '전원이 켜지지 않습니다.'}})).status, 200);
  await recordReply(user, claim);
  const after = await settled(user, claim);
  assert.deepEqual({waiting: after.waiting, last: after.last}, {waiting: null, last: null});
  assert.deepEqual(capabilities(aiProvider), ['translate-issue']);
  assert.equal(after.heldBack, true, 'the screen is told why nothing started');

  // Their own button still works with what is left, and the notice goes away.
  assert.equal((await runAgent(user, claim)).status, 200);
  assert.equal((await overview(user, claim)).heldBack, false);
});

test('one run at a time: the button is refused while it works, and an event during a run starts another after it', async t => {
  let release;
  const gate = new Promise(resolve => { release = resolve; });
  let plans = 0;
  const provider = createFakeProvider({
    plan: async () => {
      plans += 1;
      if (plans === 1) await gate;
      return stop();
    },
  });
  const {client} = await startApp(t, {env: DELAY, aiProvider: provider});
  const user = await consentedUser(client, {auto: false});
  const claim = await createClaim(user);
  await setAuto(user, true);

  await recordReply(user, claim);
  // Wait until the run has started and is held inside its first choice.
  for (let turn = 0; turn < 200 && plans === 0; turn += 1) await sleep(25);
  assert.equal(plans, 1);
  assert.equal((await overview(user, claim)).working, true);

  const pressed = await runAgent(user, claim);
  assert.equal(pressed.status, 409);
  assert.equal(pressed.data.error, 'agent_busy');

  // A file arrives while the run is going on.
  const now = await current(user, claim.id);
  const uploaded = await user.call(`/api/claims/${claim.id}/files`, {
    method: 'POST', raw: Buffer.from('%PDF-1.4 second'), version: now.version, key: key(),
    headers: {'Content-Type': 'application/pdf', 'X-File-Name': 'photo.pdf'},
  });
  assert.equal(uploaded.status, 201, JSON.stringify(uploaded.data));
  await sleep(300);
  assert.equal(plans, 1, 'the second run waits for the first');

  release();
  const after = await settled(user, claim);
  assert.equal(after.last.startedBy, 'file');
  const runs = (await user.call('/api/account/export')).data.agentRuns;
  assert.deepEqual(runs.map(run => [run.startedBy, run.endedBy]), [['reply', 'done'], ['file', 'done']]);

  // Idle again: the button works.
  assert.equal((await runAgent(user, claim)).status, 200);
});

test('a claim in the trash or finished is left alone', async t => {
  const {client, aiProvider} = await startApp(t, {env: DELAY});
  const user = await consentedUser(client, {auto: false});
  const claim = await createClaim(user);
  await setAuto(user, true);

  // The reply is saved, then the claim goes to the trash before the agent starts.
  const replied = await recordReply(user, claim);
  const trashed = await user.call(`/api/claims/${claim.id}`, {method: 'DELETE', version: replied.version, data: {reason: '잘못 등록'}});
  assert.equal(trashed.status, 200, JSON.stringify(trashed.data));
  await sleep(400);
  assert.deepEqual(capabilities(aiProvider), []);
  assert.equal((await user.call('/api/account/export')).data.agentRuns.length, 0);
});

// --- Telling the person by email that a proposal is waiting ---

const MINUTES = 60 * 1000;
const notices = (mail, user) => mail.messages.filter(message => message.to === user.email && /\/claims\//.test(message.text));

async function confirmAddress(user, mail) {
  const token = mail.token(user.email, 'verify');
  assert.equal((await user.call('/api/auth/verify', {method: 'POST', data: {token}})).status, 200);
}

test('a proposal nobody answers is told once by email, with nothing from the claim in it', async t => {
  const {app, client, mail} = await startApp(t, {env: DELAY});
  const user = await consentedUser(client);
  await confirmAddress(user, mail);
  const claim = await createClaim(user);
  const after = await settled(user, claim);
  assert.equal(after.waiting.status, 'waiting');
  const {notifyWaiting} = app.services.agent;

  // Ten minutes by default: someone who is at the screen is not emailed.
  assert.equal(notifyWaiting(), 0);
  assert.equal(notifyWaiting(Date.now() + 9 * MINUTES), 0);
  assert.equal(notices(mail, user).length, 0);

  assert.equal(notifyWaiting(Date.now() + 11 * MINUTES), 1);
  const [notice] = notices(mail, user);
  assert.match(notice.subject, /AI가 물어볼 것이 있어요/);
  assert.ok(notice.text.includes(`/claims/${claim.id}`), 'it says where to answer');
  assert.match(notice.text, /답하기 전에는 아무것도 바뀌지 않고/);
  assert.match(notice.text, /메일만 그만 받으려면 설정에서 알림 메일을 끄세요/);
  // Nothing about the order goes through the mail service.
  for (const secret of [claim.vendor, claim.title, claim.orderRef, 'EG-2026-1001', '79.80', claim.issue]) {
    assert.ok(!notice.text.includes(secret) && !notice.subject.includes(secret), `the email carries "${secret}"`);
  }

  // One email per run: not again later, and not when the same run stops on its next proposal.
  assert.equal(notifyWaiting(Date.now() + 30 * MINUTES), 0);
  const next = await user.call(`/api/claims/${claim.id}/ai/agent/${after.waiting.runId}/decision`, {method: 'POST', data: {approve: true, locale: 'ko'}});
  assert.equal(next.data.pending.tool, 'save_draft');
  assert.equal(notifyWaiting(Date.now() + 60 * MINUTES), 0);
  assert.equal(notices(mail, user).length, 1);

  // It reads the table, so it is only ever about this owner's run.
  const other = await consentedUser(client);
  assert.equal(notices(mail, other).length, 0);
});

test('no email for a run the person started, an address not confirmed, or once they took the claims back', async t => {
  const {app, client, mail} = await startApp(t, {env: DELAY});
  const {notifyWaiting} = app.services.agent;
  const later = () => Date.now() + 11 * MINUTES;

  // The person pressed the button: they were there when it asked.
  const presser = await consentedUser(client, {auto: false});
  await confirmAddress(presser, mail);
  const pressed = await createClaim(presser);
  assert.equal((await runAgent(presser, pressed)).data.status, 'waiting');
  assert.equal(notifyWaiting(later()), 0);

  // Nobody has proved this address is theirs.
  const unconfirmed = await consentedUser(client);
  const first = await createClaim(unconfirmed);
  assert.equal((await settled(unconfirmed, first)).waiting.status, 'waiting');
  assert.equal(notifyWaiting(later()), 0);
  // Looked at once and left alone, also after the address is confirmed.
  await confirmAddress(unconfirmed, mail);
  assert.equal(notifyWaiting(later()), 0);

  // They turned it off before the email was due.
  const tookBack = await consentedUser(client);
  await confirmAddress(tookBack, mail);
  const second = await createClaim(tookBack);
  assert.equal((await settled(tookBack, second)).waiting.status, 'waiting');
  await setAuto(tookBack, false);
  assert.equal(notifyWaiting(later()), 0);

  for (const user of [presser, unconfirmed, tookBack]) assert.equal(notices(mail, user).length, 0);
});

test('notice emails can be switched off while the agent still starts by itself', async t => {
  const {app, client, mail} = await startApp(t, {env: DELAY});
  const user = await consentedUser(client);
  await confirmAddress(user, mail);
  const setNoticeMail = on => user.call('/api/account/notice-mail', {method: 'POST', data: {on}});
  assert.equal((await user.call('/api/me')).data.user.noticeMailOffAt, null, 'on until they switch it off');

  const off = await setNoticeMail(false);
  assert.equal(off.status, 200);
  assert.ok(off.data.user.noticeMailOffAt);
  assert.ok(off.data.user.agentAutoAt, 'the agent is still left with the claims');
  assert.equal((await user.call('/api/account/export')).data.user.noticeMailOffAt, off.data.user.noticeMailOffAt);

  // The agent starts and waits as before; no email is sent about it.
  const claim = await createClaim(user);
  assert.equal((await settled(user, claim)).waiting.status, 'waiting');
  assert.equal(app.services.agent.notifyWaiting(Date.now() + 11 * MINUTES), 0);
  assert.equal(notices(mail, user).length, 0);

  // Back on: the next run that is left waiting is told. Without a session it is refused.
  assert.equal((await setNoticeMail(true)).data.user.noticeMailOffAt, null);
  await recordReply(user, claim);
  assert.equal((await settled(user, claim)).waiting.status, 'waiting');
  assert.equal(app.services.agent.notifyWaiting(Date.now() + 11 * MINUTES), 1);
  assert.match(notices(mail, user)[0].text, /설정에서 알림 메일을 끄세요/);
  assert.equal((await client().call('/api/account/notice-mail', {method: 'POST', data: {on: false}})).status, 401);
});

test('the email is in the language of the screen, and a claim in the trash is left alone', async t => {
  const {app, client, mail} = await startApp(t, {env: DELAY});
  const {notifyWaiting} = app.services.agent;
  const user = await consentedUser(client, {auto: false});
  await confirmAddress(user, mail);
  const claim = await createClaim(user);
  const trashedLater = await createClaim(user);
  await setAuto(user, true);

  await recordReply(user, claim, {'X-Relo-Locale': 'en'});
  assert.equal((await settled(user, claim)).waiting.status, 'waiting');
  const replied = await recordReply(user, trashedLater);
  assert.equal((await settled(user, trashedLater)).waiting.status, 'waiting');
  const trashed = await user.call(`/api/claims/${trashedLater.id}`, {method: 'DELETE', version: replied.version, data: {reason: '잘못 등록'}});
  assert.equal(trashed.status, 200, JSON.stringify(trashed.data));

  assert.equal(notifyWaiting(Date.now() + 11 * MINUTES), 1);
  const sent = notices(mail, user);
  assert.equal(sent.length, 1);
  assert.match(sent[0].subject, /The AI has a question for you/);
  assert.ok(sent[0].text.includes(`/claims/${claim.id}`));
});

test('the mail service being off means no sweep at all', async t => {
  const off = {name: 'disabled', enabled: false, messages: [], async send() { throw new Error('must not be called'); }, token: () => null, count: () => 0};
  const {app, client} = await startApp(t, {env: DELAY, mail: off});
  const user = await consentedUser(client);
  const claim = await createClaim(user);
  assert.equal((await settled(user, claim)).waiting.status, 'waiting');
  assert.equal(app.services.agent.notifyWaiting(Date.now() + 11 * MINUTES), 0);
  // Nothing was marked either: turning mail on later still tells them.
  assert.equal(app.repos.agentRuns.listUnnoticedWaiting(new Date(Date.now() + MINUTES).toISOString(), 10).length, 1);
});

test('filing from one line: the model chooses the kind, the item and the quantity; the choice is re-checked', async t => {
  let answer = null;
  const provider = createFakeProvider();
  const fake = provider.generateJson.bind(provider);
  provider.generateJson = async request => {
    const result = await fake(request);
    return request.capability === 'intake' && answer ? {...result, data: {...result.data, ...answer}} : result;
  };
  const {client} = await startApp(t, {aiProvider: provider});
  const user = await client().signup();
  const input = {text: '허브 두 개 중 하나가 전원이 안 켜져요. 교환해 주세요.', items: [{name: 'USB-C Hub 7-in-1', orderedQty: 2}], locale: 'ko'};
  const intake = data => user.call('/api/ai/intake', {method: 'POST', data});

  const refused = await intake(input);
  assert.equal(refused.status, 403);
  assert.equal(refused.data.error, 'ai_consent_required');
  assert.equal(provider.calls.length, 0, 'nothing is sent before the person has agreed');

  await user.call('/api/account/ai-consent', {method: 'POST', data: {consent: true}});
  const read = await intake(input);
  assert.equal(read.status, 200, JSON.stringify(read.data));
  assert.deepEqual({kind: read.data.kind, itemIndex: read.data.itemIndex, claimQty: read.data.claimQty}, {kind: 'exchange', itemIndex: 0, claimQty: 1});
  assert.ok(read.data.issueEnglish);
  assert.ok(read.data.understood);

  // What goes to the model: the person's line and the item names with quantities. No prices.
  const sent = provider.calls.at(-1);
  assert.match(sent.parts[0].text, /<consumer_text>\n허브 두 개 중 하나가/);
  assert.match(sent.parts[0].text, /"name": "USB-C Hub 7-in-1"/);
  assert.doesNotMatch(sent.parts[0].text, /unitPrice|39\.90/);

  // An item that is not on the list is dropped; the quantity is never more than was ordered.
  answer = {itemIndex: 5, claimQty: 9};
  assert.deepEqual((({itemIndex, claimQty}) => ({itemIndex, claimQty}))((await intake(input)).data), {itemIndex: null, claimQty: 9});
  answer = {itemIndex: 0, claimQty: 9};
  assert.equal((await intake(input)).data.claimQty, 2);
  answer = {kind: 'lawsuit'};
  assert.equal((await intake(input)).data.error, 'ai_bad_output');
  answer = null;

  // Without an order document the item stays for the person to fill in.
  const bare = await intake({text: '신발이 한 치수 작게 왔어요. 환불받고 싶어요.', locale: 'ko'});
  assert.deepEqual({kind: bare.data.kind, itemIndex: bare.data.itemIndex}, {kind: 'refund', itemIndex: null});

  assert.equal((await intake({text: '   ', items: []})).status, 422);
});
