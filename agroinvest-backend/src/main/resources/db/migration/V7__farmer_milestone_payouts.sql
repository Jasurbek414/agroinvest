-- Tracks the two working-capital advances a farmer receives per the TZ's funding flow
-- (7.1: "50% yig'ilgach -> bosqich 1 | 100% yig'ilgach -> bosqich 2"): half the target
-- amount once raised_amount reaches 50% of target, the rest once fully funded. NULL
-- means that milestone hasn't been paid yet; a timestamp prevents paying it twice.
ALTER TABLE projects ADD COLUMN farmer_milestone1_paid_at TIMESTAMP;
ALTER TABLE projects ADD COLUMN farmer_milestone2_paid_at TIMESTAMP;
