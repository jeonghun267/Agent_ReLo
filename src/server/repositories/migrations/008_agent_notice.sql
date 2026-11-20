-- A run that started by itself may stop on a proposal when nobody is looking at the screen.
-- If the proposal is still unanswered a while later, one email tells the person so
-- (agent.service notifyWaiting). This column makes it one email per run, and it survives a
-- restart because the sweep reads the table, not a timer.
--
-- Additive only: no existing row is rewritten.

-- When this run was looked at for that email (sent, or decided not to send). NULL = not yet.
ALTER TABLE agent_runs ADD COLUMN notified_at TEXT;

-- The person can switch these emails off and still leave their claims to the agent.
-- When they did so. NULL = they receive them.
ALTER TABLE users ADD COLUMN notice_mail_off_at TEXT;
