-- The agent can start by itself. A person may leave their claims to it ("맡겨 두기"): from then
-- on a run starts when something happens on a claim (the request is filed, a file is added, a
-- seller reply is recorded), not only when they press the button. It is off until they turn it
-- on, and it still changes nothing without their approval.
--
-- Additive only: no existing row is rewritten.

-- When the person turned it on. NULL = off.
ALTER TABLE users ADD COLUMN agent_auto_at TEXT;

-- What started a run: 'person' (the button) or the event ('filed', 'file', 'reply').
ALTER TABLE agent_runs ADD COLUMN started_by TEXT NOT NULL DEFAULT 'person';
