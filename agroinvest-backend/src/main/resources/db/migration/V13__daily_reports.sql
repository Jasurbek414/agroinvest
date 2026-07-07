-- DDL ONLY. ALTER TYPE ... ADD VALUE may run inside Flyway's transaction, but
-- the new value must not be USED (no DML) in the same migration - keep it here
-- and let application code start writing 'DAILY' afterwards.

ALTER TYPE rep_type ADD VALUE IF NOT EXISTS 'DAILY';

-- Structured daily-log metrics (headcount, deaths, feedKg, avgWeightKg, ...)
ALTER TABLE reports ADD COLUMN metrics JSONB;
