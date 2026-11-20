const toRun = row => ({
  id: row.id,
  claimId: row.claim_id,
  arm: row.arm,
  endedBy: row.ended_by,
  stepCount: row.step_count,
  planCount: row.plan_count,
  startedAt: row.started_at,
  endedAt: row.ended_at,
  userAction: row.user_action,
  startedBy: row.started_by,
  // When the person was emailed (or the email was decided against) about this run waiting.
  notifiedAt: row.notified_at ?? null,
});

const toStep = row => ({
  seq: row.seq,
  tool: row.tool,
  target: row.target,
  reason: row.reason,
  ok: row.ok === 1,
  errorCode: row.error_code,
  ms: row.ms,
  decision: row.decision,
});

export function createAgentRunRepository(db) {
  const stepsOf = (ownerId, runIds) => {
    if (!runIds.length) return [];
    const marks = runIds.map(() => '?').join(', ');
    return db.prepare(`SELECT * FROM agent_steps WHERE owner_id = ? AND run_id IN (${marks}) ORDER BY run_id, seq`).all(ownerId, ...runIds);
  };
  const withSteps = (ownerId, rows) => {
    const steps = stepsOf(ownerId, rows.map(row => row.id));
    return rows.map(row => ({...toRun(row), steps: steps.filter(step => step.run_id === row.id).map(toStep)}));
  };

  return {
    // Writes a run and its steps as they are now. A run is written when it stops to wait for
    // the person and again when it ends, so both the row and its steps may already exist.
    // Call inside a transaction so a run is never stored without its steps.
    save({id, ownerId, claimId, arm, endedBy, planCount, startedAt, endedAt, userAction = '', pausedState = '', startedBy = 'person', steps}) {
      db.prepare(`INSERT INTO agent_runs(id, owner_id, claim_id, arm, ended_by, step_count, plan_count, started_at, ended_at, user_action, paused_state, started_by)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET ended_by = excluded.ended_by, step_count = excluded.step_count, plan_count = excluded.plan_count,
          ended_at = excluded.ended_at, user_action = excluded.user_action, paused_state = excluded.paused_state`)
        .run(id, ownerId, claimId, arm, endedBy, steps.length, planCount, startedAt, endedAt, userAction, pausedState, startedBy);
      const saveStep = db.prepare(`INSERT INTO agent_steps(id, owner_id, run_id, seq, tool, target, reason, ok, error_code, ms, decision)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO NOTHING`);
      for (const step of steps) {
        saveStep.run(step.id, ownerId, id, step.seq, step.tool, step.target, step.reason, step.ok ? 1 : 0, step.errorCode, step.ms, step.decision ?? '');
      }
    },

    // The run that is stopped on a proposal for this claim, with what it needs to go on.
    findWaiting(ownerId, claimId) {
      const row = db.prepare("SELECT * FROM agent_runs WHERE owner_id = ? AND claim_id = ? AND ended_by = 'waiting' ORDER BY started_at DESC, id LIMIT 1").get(ownerId, claimId);
      return row ? {...toRun(row), pausedState: row.paused_state} : null;
    },

    // Every claim of this owner where a run is stopped on a proposal: what the list of claims
    // marks as "waiting for your answer".
    listWaiting(ownerId) {
      return db.prepare("SELECT claim_id AS claimId, paused_state AS pausedState FROM agent_runs WHERE owner_id = ? AND ended_by = 'waiting' ORDER BY started_at DESC, id").all(ownerId);
    },

    // A waiting run the person never answered is closed when they start another one.
    abandonWaiting(ownerId, claimId, endedAt) {
      db.prepare("UPDATE agent_runs SET ended_by = 'abandoned', ended_at = ?, paused_state = '' WHERE owner_id = ? AND claim_id = ? AND ended_by = 'waiting'")
        .run(endedAt, ownerId, claimId);
    },

    // Runs that started by themselves and have waited for an answer since `before` or longer,
    // which nobody has been told about yet. This is the server's own sweep, so it reads across
    // owners; each row is only ever used to write to its own owner.
    listUnnoticedWaiting(before, limit) {
      return db.prepare(`SELECT id, owner_id AS ownerId, claim_id AS claimId, paused_state AS pausedState FROM agent_runs
        WHERE ended_by = 'waiting' AND started_by <> 'person' AND notified_at IS NULL AND ended_at <= ?
        ORDER BY ended_at, id LIMIT ?`).all(before, limit);
    },

    markNoticed(ownerId, id, at) {
      db.prepare('UPDATE agent_runs SET notified_at = ? WHERE id = ? AND owner_id = ?').run(at, id, ownerId);
    },

    // The latest finished runs for one claim, newest first: what the next run remembers.
    recentForClaim(ownerId, claimId, limit) {
      const rows = db.prepare("SELECT * FROM agent_runs WHERE owner_id = ? AND claim_id = ? AND ended_by <> 'waiting' ORDER BY started_at DESC, id LIMIT ?").all(ownerId, claimId, limit);
      return withSteps(ownerId, rows);
    },

    // Everything held about one owner's runs, oldest first, for the data export. A run that is
    // still waiting also holds the contents it has read so far (pausedState).
    listAll(ownerId) {
      const rows = db.prepare('SELECT * FROM agent_runs WHERE owner_id = ? ORDER BY started_at, id').all(ownerId);
      const pausedById = new Map(rows.map(row => [row.id, row.paused_state]));
      return withSteps(ownerId, rows).map(run => pausedById.get(run.id) ? {...run, pausedState: JSON.parse(pausedById.get(run.id))} : run);
    },
  };
}
