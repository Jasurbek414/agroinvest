-- Orthogonal freeze flag (mirrors users.is_blocked): a project can be frozen
-- from any status without losing its place in the state machine - money-moving
-- actions (invest, distribute payout) are blocked while frozen, and unfreezing
-- simply clears the flag rather than restoring a remembered prior status,
-- because status itself is never touched by freezing.
ALTER TABLE projects ADD COLUMN is_frozen BOOLEAN DEFAULT false;
ALTER TABLE projects ADD COLUMN frozen_reason VARCHAR(500);
ALTER TABLE projects ADD COLUMN frozen_at TIMESTAMP;
ALTER TABLE projects ADD COLUMN frozen_by UUID REFERENCES users(id);
