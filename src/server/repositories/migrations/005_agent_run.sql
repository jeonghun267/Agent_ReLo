-- Agent runs: the record of each time the model chose its own next steps for a claim.
-- It is the raw data for the comparison experiment and for the "why did it do that" view.
--   agent_runs:  one run. arm is 'C' for the loop (the model chooses); 'B' is kept for runs
--                of the rule-based next step, should those be recorded for comparison.
--   agent_steps: each step of a run: which tool, pointed at what, and why the model chose it.
-- Both tables carry owner_id: they hold the model's wording about a person's claim, so they
-- are erased with the account (account.repo.mjs) and included in the export.
-- Token counts are not here on purpose: every AI call of a run is already in ai_usage, and
-- the cost of a run is the sum of that owner's rows for the claim between started_at and ended_at.

CREATE TABLE agent_runs(
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL,
  claim_id TEXT NOT NULL,
  arm TEXT NOT NULL CHECK(arm IN ('B', 'C')),
  ended_by TEXT NOT NULL,
  step_count INTEGER NOT NULL DEFAULT 0,
  plan_count INTEGER NOT NULL DEFAULT 0,
  started_at TEXT NOT NULL,
  ended_at TEXT NOT NULL
);
CREATE INDEX agent_runs_owner_time ON agent_runs(owner_id, started_at);

CREATE TABLE agent_steps(
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL,
  run_id TEXT NOT NULL,
  seq INTEGER NOT NULL,
  tool TEXT NOT NULL,
  target TEXT NOT NULL DEFAULT '',
  reason TEXT NOT NULL DEFAULT '',
  ok INTEGER NOT NULL,
  error_code TEXT NOT NULL DEFAULT '',
  ms INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX agent_steps_run ON agent_steps(run_id, seq);
