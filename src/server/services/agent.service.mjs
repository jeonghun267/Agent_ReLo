import {AppError, reject} from '../domain/errors.mjs';
import {newId, nowIso} from '../domain/primitives.mjs';
import {toDecimal} from '../domain/money.mjs';
import {signAs} from '../domain/draft-template.mjs';
import {transaction} from '../repositories/db.mjs';
import {CLOSED_STATES} from '../domain/claim.mjs';
import {ACTION_TOOLS} from '../ai/prompts/plan.mjs';
import {agentWaitingMessage} from '../mail/messages.mjs';

// The agent loop. Given the goal of a claim, the model chooses the next tool, the server runs
// it, and what came back goes into the next choice, until the model says the next move is not
// its own, it repeats itself, or the step limit is reached.
//
// Two kinds of tools:
// - tools that read (read_evidence, analyze_reply, write_draft) run at once and change nothing;
// - tools that change the claim (fix_order_facts, save_draft) are only proposed. The run stops
//   and waits; the person sees exactly what would change and approves or declines; then the run
//   goes on from there, with the claim read again.
//
// What the loop must never do:
// - change the claim without that approval. An approved action goes through the same services
//   the screens use (claims.update, drafts.save), so every existing safeguard keeps working:
//   the version check, the deadline guard, the facts fingerprint on drafts, immutable drafts.
// - write a value the model made up. The model only names the action; the values come from
//   what the server read (the document, the draft written in this run).
// - send or submit anything. No tool does: the person sends the message themself, in their
//   own name, and marks it as sent themself.
//
// A run starts in one of two ways: the person presses the button, or, if they have left their
// claims to the agent, it starts by itself when something happens on a claim (wake). Either
// way the rules above are the same: a run that started by itself stops and waits just like
// one the person started.
const FIXABLE = ['orderRef', 'orderedOn'];
const MEMORY_RUNS = 2;
// What can start a run: the person's button, or an event on the claim.
export const STARTED_BY = ['person', 'filed', 'file', 'reply'];

export function createAgentService({db, repos, config, claims, drafts, ai, mail, logger = console}) {
  const maxSteps = config.ai.agentMaxSteps;
  // One round is at most two AI calls (the choice and the tool), each counted against the
  // hourly limit. Starting without room for a whole run would end it half-way.
  const callsPerRun = 2 * maxSteps;
  // A run that starts by itself leaves this much of the hour for the person's own AI buttons.
  const autoReserve = Math.ceil(config.ai.hourlyLimit / 6);

  const READERS = {
    read_evidence: (user, claimId, plan) => ai.extract(user, claimId, {fileId: plan.fileId}),
    // The reply text comes from the saved claim, not from the model: it only named the reply.
    analyze_reply: (user, claimId, plan, view) => ai.analyzeReply(user, claimId, {body: view.replies.find(reply => reply.id === plan.replyId).body}),
    write_draft: (user, claimId) => ai.draft(user, claimId),
  };

  // Saved facts the order document disagrees with, against the claim as it is now. The planner
  // and the person both see this.
  function mismatches(view, found) {
    const same = (a, b) => String(a ?? '').trim().toLowerCase() === String(b ?? '').trim().toLowerCase();
    return [
      ['orderRef', view.orderRef, found.orderRef],
      ['orderedOn', view.orderedOn, found.orderedOn],
      ['currency', view.currency, found.currency],
    ].filter(([, saved, read]) => read && !same(saved, read)).map(([field, saved, read]) => ({field, saved, read}));
  }

  // The saved claim in the shape claims.update takes, with some facts replaced.
  function asInput(view, changes) {
    return {
      title: view.title, vendor: view.vendor, vendorUrl: view.vendorUrl, orderRef: view.orderRef, orderedOn: view.orderedOn,
      kind: view.kind, currency: view.currency,
      items: view.items.map(item => ({...item, unitPrice: toDecimal(item.unitPrice, view.currency)})),
      claimedAmount: toDecimal(view.claimed, view.currency),
      agreedAmount: view.agreed === null ? '' : toDecimal(view.agreed, view.currency),
      issue: view.issue, issueEnglish: view.issueEnglish,
      deadline: view.deadline, deadlineQuote: view.deadlineQuote, deadlineZone: view.deadlineZone,
      ...changes,
    };
  }

  // Runs one chosen reading tool. An AI failure is kept as a failed step instead of ending the
  // run: the next choice sees it and can go another way. Anything else is a bug and is thrown.
  async function read(user, view, plan, seq) {
    const began = Date.now();
    const step = {
      id: newId(), seq, tool: plan.tool, reason: plan.reason,
      fileId: plan.fileId, fileName: view.files.find(file => file.id === plan.fileId)?.name ?? null, replyId: plan.replyId,
      decision: '', changes: [], atVersion: view.version,
    };
    try {
      const result = await READERS[plan.tool](user, view.id, plan, view);
      return {
        ...step, ok: true, errorCode: '', message: '', ms: Date.now() - began, result,
        mismatches: plan.tool === 'read_evidence' ? mismatches(view, result.suggestion) : [],
      };
    } catch (error) {
      if (!(error instanceof AppError)) throw error;
      return {...step, ok: false, errorCode: error.code, message: error.message, ms: Date.now() - began, result: null, mismatches: []};
    }
  }

  // Turns a chosen action into a proposal the person can judge: what exactly would change.
  // Returns null when the action is not possible in this run (nothing to fix, no current draft).
  function propose(user, view, steps, plan) {
    const latest = (tool, match = () => true) => steps.findLast(step => step.tool === tool && step.ok && match(step));
    const base = {tool: plan.tool, reason: plan.reason, fileId: null, fileName: null, changes: [], draft: null, claimVersion: view.version};
    if (plan.tool === 'fix_order_facts') {
      const source = latest('read_evidence', step => step.fileId === plan.fileId);
      const changes = source
        ? mismatches(view, source.result.suggestion).filter(item => FIXABLE.includes(item.field)).map(item => ({field: item.field, from: item.saved, to: item.read}))
        : [];
      return changes.length ? {...base, fileId: source.fileId, fileName: source.fileName, changes} : null;
    }
    const written = latest('write_draft', step => step.atVersion === view.version);
    // The message is the person's own: it is signed with the name on their account.
    return written ? {...base, draft: {body: signAs(written.result.body, user.name), model: written.result.model}} : null;
  }

  // Carries out what the person decided about a proposal. Approved: the change goes through
  // the normal service with the version the proposal was made on, so a claim that was edited
  // in the meantime is refused, not overwritten. Declined: nothing is touched.
  function act(user, state, approved) {
    const {pending} = state;
    const began = Date.now();
    const step = {
      id: newId(), seq: state.steps.length + 1, tool: pending.tool, reason: pending.reason,
      fileId: pending.fileId, fileName: pending.fileName, replyId: null,
      decision: approved ? 'approved' : 'declined', changes: pending.changes, atVersion: pending.claimVersion,
      result: null, mismatches: [],
    };
    if (!approved) return {...step, ok: true, errorCode: '', message: '', ms: 0};
    try {
      if (pending.tool === 'fix_order_facts') {
        const facts = Object.fromEntries(pending.changes.map(change => [change.field, change.to]));
        claims.update(user.id, state.claimId, pending.claimVersion, asInput(claims.detail(user.id, state.claimId), facts));
      } else {
        drafts.save(user.id, state.claimId, pending.claimVersion, {body: pending.draft.body, origin: 'ai', model: pending.draft.model}, `agent-${state.runId}-${step.seq}`);
      }
      return {...step, ok: true, errorCode: '', message: '', ms: Date.now() - began};
    } catch (error) {
      if (!(error instanceof AppError)) throw error;
      return {...step, ok: false, errorCode: error.code, message: error.message, ms: Date.now() - began};
    }
  }

  // What the next choice needs from a finished step: not the full draft or translation.
  // A document's differences are worked out against the claim as it is now, so a difference
  // that an approved fix has settled is no longer reported.
  function forPlanner(step, view) {
    const base = {step: step.seq, tool: step.tool, fileId: step.fileId ?? undefined, replyId: step.replyId ?? undefined, ok: step.ok, decision: step.decision || undefined};
    if (!step.ok) return {...base, error: step.errorCode};
    if (step.tool === 'read_evidence') {
      const {suggestion, orderTotal} = step.result;
      return {
        ...base,
        read: {seller: suggestion.vendor, orderNumber: suggestion.orderRef, orderDate: suggestion.orderedOn, currency: suggestion.currency, orderTotal, items: suggestion.items.length},
        differsFromSaved: mismatches(view, suggestion),
      };
    }
    if (step.tool === 'analyze_reply') {
      const {suggestedKind, mentionedAmount, mentionedCurrency, deadline, summaryKo} = step.result;
      return {...base, suggestedKind, mentionedAmount, mentionedCurrency, deadline, summary: summaryKo};
    }
    if (step.tool === 'write_draft') {
      return {...base, summary: step.result.summaryKo, stillMissing: step.result.missingInfo, writtenFromCurrentFacts: step.atVersion === view.version};
    }
    if (step.tool === 'fix_order_facts') return {...base, changed: step.decision === 'approved' ? step.changes.map(change => change.field) : []};
    return {...base, saved: step.decision === 'approved'};
  }

  // What a later run is told about an earlier one: the tools, the person's decisions and what
  // the agent asked the person to do. No contents.
  const forMemory = run => ({
    endedAt: run.endedAt,
    endedBy: run.endedBy,
    toldConsumer: run.userAction || null,
    steps: run.steps.map(step => ({tool: step.tool, target: step.target || undefined, ok: step.ok, decision: step.decision || undefined})),
  });

  // The same tool on the same thing again would only spend calls. A draft may be written (and
  // saved) again once the saved facts have changed.
  const choiceKey = (plan, view) => `${plan.tool}:${plan.fileId ?? plan.replyId ?? `v${view.version}`}`;

  function store(user, state, endedBy, userAction) {
    transaction(db, () => repos.agentRuns.save({
      id: state.runId, ownerId: user.id, claimId: state.claimId, arm: 'C', endedBy, planCount: state.planCount,
      startedAt: state.startedAt, endedAt: nowIso(), userAction: userAction ?? '', startedBy: state.startedBy ?? 'person',
      // Kept only while the run waits; a finished run holds no copy of what it read or wrote.
      pausedState: endedBy === 'waiting' ? JSON.stringify(state) : '',
      steps: state.steps.map(step => ({
        id: step.id, seq: step.seq, tool: step.tool, target: step.fileId ?? step.replyId ?? '', reason: step.reason,
        ok: step.ok, errorCode: step.errorCode, ms: step.ms, decision: step.decision,
      })),
    }));
  }

  function respond(state, endedBy, closing = {}) {
    const {pending} = state;
    return {
      runId: state.runId,
      status: endedBy ? 'finished' : 'waiting',
      endedBy,
      startedBy: state.startedBy ?? 'person',
      maxSteps,
      // A choice is one AI call and so is a reading tool. Carrying out an action is not.
      aiCalls: state.planCount + state.steps.filter(step => !ACTION_TOOLS.includes(step.tool)).length,
      reason: closing.reason ?? '',
      userAction: closing.userAction ?? null,
      errorCode: closing.errorCode ?? '',
      steps: state.steps.map(({id, atVersion, ...step}) => step),
      pending: pending
        ? {tool: pending.tool, reason: pending.reason, fileName: pending.fileName, changes: pending.changes, draftBody: pending.draft?.body ?? null}
        : null,
    };
  }

  // Chooses and runs steps from where the run stands, until it ends or has to wait.
  async function advance(user, state) {
    // Ground truth: the claim is read again each time the run goes on, so the choice is made
    // on what is saved now, including a change the person has just approved.
    const view = claims.detail(user.id, state.claimId);
    const ids = {fileIds: new Set(view.files.map(file => file.id)), replyIds: new Set(view.replies.map(reply => reply.id))};
    let endedBy = 'max_steps';
    let closing = {};

    while (state.steps.length < maxSteps) {
      let plan;
      try {
        state.planCount += 1;
        plan = await ai.plan(user, state.claimId, view, state.steps.map(step => forPlanner(step, view)), {...ids, locale: state.locale, earlierRuns: state.memory, startedBy: state.startedBy});
      } catch (error) {
        if (!(error instanceof AppError)) throw error;
        endedBy = error.code === 'ai_rate_limited' ? 'rate_limited' : 'plan_failed';
        closing = {errorCode: error.code};
        break;
      }
      if (plan.done) {
        endedBy = plan.dropped ? 'invalid_choice' : 'done';
        closing = {reason: plan.reason, userAction: plan.userAction};
        break;
      }
      const key = choiceKey(plan, view);
      if (state.seen.includes(key)) {
        endedBy = 'repeat';
        closing = {reason: plan.reason};
        break;
      }
      state.seen.push(key);

      if (ACTION_TOOLS.includes(plan.tool)) {
        state.pending = propose(user, view, state.steps, plan);
        if (!state.pending) {
          endedBy = 'invalid_choice';
          closing = {reason: plan.reason};
          break;
        }
        store(user, state, 'waiting');
        return respond(state, null);
      }

      const step = await read(user, view, plan, state.steps.length + 1);
      state.steps.push(step);
      if (step.errorCode === 'ai_rate_limited') {
        endedBy = 'rate_limited';
        break;
      }
    }

    store(user, state, endedBy, closing.userAction);
    return respond(state, endedBy, closing);
  }

  // --- One run at a time per claim, and starting by itself ---

  const keyOf = (ownerId, claimId) => `${ownerId}:${claimId}`;
  const busy = new Set(); // claims with a run going on right now
  const timers = new Map(); // claims where a start is scheduled: key -> {timer, startedBy, locale}
  const queued = new Map(); // an event that arrived during a run: key -> {startedBy, locale}
  const skipped = new Set(); // claims where a start by itself was held back by the hourly limit

  function unschedule(key) {
    clearTimeout(timers.get(key)?.timer);
    timers.delete(key);
  }

  // Runs `work` as the only run on this claim. An event that arrived meanwhile starts another
  // run afterwards, because the claim has changed under this one.
  async function exclusive(ownerId, claimId, work) {
    const key = keyOf(ownerId, claimId);
    reject(busy.has(key), 'AI가 지금 이 건을 살펴보고 있어요. 잠시 후 다시 확인해 주세요.', 'agent_busy', 409);
    busy.add(key);
    try {
      return await work();
    } finally {
      busy.delete(key);
      const next = queued.get(key);
      queued.delete(key);
      if (next) wake(ownerId, claimId, next.startedBy, next.locale);
    }
  }

  async function start(user, claimId, {locale, startedBy = 'person'} = {}) {
    claims.detail(user.id, claimId);
    reject(ai.remaining(user) < callsPerRun,
      `AI가 스스로 살펴보려면 한 번에 최대 ${callsPerRun}번을 써요. 지금은 남은 횟수가 모자라니 잠시 후 다시 시도하세요.`, 'ai_rate_limited', 429);

    skipped.delete(keyOf(user.id, claimId));
    const startedAt = nowIso();
    // A proposal the person never answered is closed: only one run per claim waits at a time.
    transaction(db, () => repos.agentRuns.abandonWaiting(user.id, claimId, startedAt));
    return advance(user, {
      runId: newId(), claimId, startedAt, startedBy, locale, planCount: 0, steps: [], seen: [], pending: null,
      memory: repos.agentRuns.recentForClaim(user.id, claimId, MEMORY_RUNS).map(forMemory),
    });
  }

  // The person presses the button.
  async function run(user, claimId, input = {}) {
    // They are starting it themself, so a start that was scheduled for an event is not needed.
    unschedule(keyOf(user.id, claimId));
    return exclusive(user.id, claimId, () => start(user, claimId, {locale: input.locale}));
  }

  // The person's answer to a proposal: approve or decline. Either way the run goes on.
  async function decide(user, claimId, runId, input = {}) {
    return exclusive(user.id, claimId, () => {
      claims.detail(user.id, claimId);
      const waiting = repos.agentRuns.findWaiting(user.id, claimId);
      reject(!waiting || waiting.id !== runId, '기다리고 있는 제안이 없어요. AI에게 다시 맡겨 주세요.', 'agent_not_waiting', 409);
      reject(typeof input.approve !== 'boolean', '허락할지 말지 정해 주세요.');
      const state = JSON.parse(waiting.pausedState);
      if (input.locale) state.locale = input.locale;
      state.steps.push(act(user, state, input.approve));
      state.pending = null;
      return advance(user, state);
    });
  }

  // Something happened on a claim (the request was filed, a file was added, a seller reply was
  // recorded). If the person has left their claims to the agent, a run starts by itself a
  // moment later; several events in a row make one run, named after the first of them.
  // Never throws: the event that woke it is already saved and must not fail because of this.
  function wake(ownerId, claimId, startedBy, locale) {
    try {
      const user = repos.users.findById(ownerId);
      if (!user?.agentAutoAt || !user.aiConsentAt || !ai.status().enabled) return;
      const key = keyOf(ownerId, claimId);
      const first = timers.get(key);
      unschedule(key);
      const plan = {startedBy: first?.startedBy ?? startedBy, locale: typeof locale === 'string' ? locale.slice(0, 8) : first?.locale};
      const timer = setTimeout(() => {
        timers.delete(key);
        void startByItself(ownerId, claimId, plan);
      }, config.ai.agentAutoDelayMs);
      timer.unref();
      timers.set(key, {timer, ...plan});
    } catch (error) {
      logger.error(error);
    }
  }

  async function startByItself(ownerId, claimId, plan) {
    const key = keyOf(ownerId, claimId);
    if (busy.has(key)) {
      queued.set(key, plan);
      return;
    }
    try {
      await exclusive(ownerId, claimId, async () => {
        // Read again: the person may have taken it back, or withdrawn consent, in the meantime.
        const user = repos.users.findById(ownerId);
        if (!user?.agentAutoAt) return;
        if (CLOSED_STATES.includes(claims.detail(ownerId, claimId).state)) return;
        // Not enough of the hour left: it does not start, and the screen says so instead of
        // leaving the person to wonder why nothing happened.
        if (ai.remaining(user) < callsPerRun + autoReserve) {
          skipped.add(key);
          return;
        }
        await start(user, claimId, plan);
      });
    } catch (error) {
      // Nobody is waiting for this answer. An expected refusal (no consent, the hourly limit,
      // the claim is in the trash) simply means no run; anything else is a bug and is logged.
      if (!(error instanceof AppError)) logger.error(error);
      else if (error.code === 'ai_rate_limited') skipped.add(key);
    }
  }

  const isWorking = (ownerId, claimId) => {
    const key = keyOf(ownerId, claimId);
    return busy.has(key) || timers.has(key) || queued.has(key);
  };

  // What the screen shows when the claim is opened: whether the agent is at work right now, a
  // proposal still waiting for an answer, and the last finished run (what the agent did before
  // and what it asked the person to do).
  function overview(user, claimId) {
    claims.detail(user.id, claimId);
    const waiting = repos.agentRuns.findWaiting(user.id, claimId);
    const [last] = repos.agentRuns.recentForClaim(user.id, claimId, 1);
    return {
      working: isWorking(user.id, claimId),
      // It would have started by itself but the hourly limit held it back.
      heldBack: skipped.has(keyOf(user.id, claimId)),
      waiting: waiting ? respond(JSON.parse(waiting.pausedState), null) : null,
      last: last
        ? {
          endedAt: last.endedAt, endedBy: last.endedBy, startedBy: last.startedBy, userAction: last.userAction || null,
          steps: last.steps.map(step => ({tool: step.tool, ok: step.ok, decision: step.decision})),
        }
        : null,
    };
  }

  // Across all claims: where the agent is waiting for the person's answer. For the list of claims.
  function waitingList(user) {
    return repos.agentRuns.listWaiting(user.id).map(row => ({claimId: row.claimId, tool: JSON.parse(row.pausedState).pending?.tool ?? null}));
  }

  // --- Telling the person that a proposal is waiting ---
  //
  // A run that started by itself may stop on a proposal when nobody is looking at the screen.
  // If it is still unanswered after a while, one email says so. Called on a timer (app.mjs) and
  // read from the table, so a restart loses nothing.
  // - One email per run, and never for a run the person started themself: they were there.
  // - Only to an address the person has confirmed, only while they still leave their claims
  //   to the agent, and not if they switched notice emails off. A claim in the trash or
  //   finished is not worth an email.
  // - The email carries nothing from the claim (see agentWaitingMessage).
  // Never throws: it runs with nobody waiting for an answer.
  function notifyWaiting(now = Date.now()) {
    if (!mail?.enabled) return 0;
    let sent = 0;
    let rows = [];
    try {
      rows = repos.agentRuns.listUnnoticedWaiting(new Date(now - config.ai.agentNoticeDelayMs).toISOString(), 50);
    } catch (error) {
      logger.error(error);
    }
    for (const row of rows) {
      try {
        // Marked first: whatever fails after this costs one email, never a second one.
        transaction(db, () => repos.agentRuns.markNoticed(row.ownerId, row.id, nowIso()));
        const user = repos.users.findById(row.ownerId);
        if (!user?.agentAutoAt || !user.emailVerifiedAt || user.noticeMailOffAt) continue;
        const view = claims.detail(row.ownerId, row.claimId);
        if (view.deleted || CLOSED_STATES.includes(view.state)) continue;
        const message = agentWaitingMessage({
          to: user.email, name: user.name, link: `${config.appOrigin}/claims/${row.claimId}`, locale: JSON.parse(row.pausedState).locale,
        });
        // Not awaited: a slow or failing mail service must not hold up the sweep. The log
        // names the failure, not the address.
        (async () => mail.send(message))().catch(error => logger.error(`[mail] delivery failed: ${error.code ?? error.name}${error.detail ? ` (${error.detail})` : ''}`));
        sent += 1;
      } catch (error) {
        // A claim that is gone (deleted for good) is an expected refusal; anything else is a bug.
        if (!(error instanceof AppError)) logger.error(error);
      }
    }
    return sent;
  }

  // On shutdown: nothing more starts by itself.
  function stop() {
    for (const key of [...timers.keys()]) unschedule(key);
    queued.clear();
    skipped.clear();
  }

  return {run, decide, overview, waitingList, wake, notifyWaiting, stop, maxSteps};
}
