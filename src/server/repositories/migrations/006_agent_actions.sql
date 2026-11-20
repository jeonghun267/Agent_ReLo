-- The agent can now propose an action that changes the claim (correct an order fact, save the
-- message it wrote). It never does so on its own: the run stops and waits, and the action runs
-- only after the person approves it. These columns hold what that needs.
--   agent_runs.ended_by     'waiting' while a run is stopped on a proposal (no new column).
--   agent_runs.paused_state the run so far, as JSON, while it waits. Emptied when the run ends,
--                           so finished runs keep no copy of the documents' contents or the draft.
--   agent_runs.user_action  what the agent told the person to do when it ended. The next run
--                           for the same claim is shown this (its memory of earlier runs).
--   agent_steps.decision    '' for a tool that only reads; 'approved' or 'declined' for an action.
--                           The share of declined actions is the human intervention rate.
-- Additive only: no existing row changes meaning.

ALTER TABLE agent_runs ADD COLUMN user_action TEXT NOT NULL DEFAULT '';
ALTER TABLE agent_runs ADD COLUMN paused_state TEXT NOT NULL DEFAULT '';
ALTER TABLE agent_steps ADD COLUMN decision TEXT NOT NULL DEFAULT '';
CREATE INDEX agent_runs_claim_time ON agent_runs(owner_id, claim_id, started_at);
