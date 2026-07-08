-- Adds two new proj_status values (TZ: project state machine expansion):
--   DRAFT      - farmer-created, not yet submitted for admin review (new
--                "save draft" flow; publish moves it to PENDING)
--   MONITORING - an ACTIVE project the admin has moved into closer oversight;
--                payout can still be distributed from MONITORING same as ACTIVE
--
-- DDL-only, no DML: Postgres forbids using a newly added enum value in the
-- same transaction it was added in (V8/V13 established this pattern).
ALTER TYPE proj_status ADD VALUE IF NOT EXISTS 'DRAFT';
ALTER TYPE proj_status ADD VALUE IF NOT EXISTS 'MONITORING';
