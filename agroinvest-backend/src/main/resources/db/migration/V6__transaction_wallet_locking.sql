-- Prevent duplicate webhook deliveries from creating two rows for the same external payment
CREATE UNIQUE INDEX uq_transactions_external_payment
    ON transactions (external_payment_id, payment_provider)
    WHERE external_payment_id IS NOT NULL;

-- Optimistic locking for wallet balance updates (prevents lost-update double-spend)
ALTER TABLE wallets ADD COLUMN version BIGINT NOT NULL DEFAULT 0;

-- Optimistic locking for project payout distribution (prevents double-payout)
ALTER TABLE projects ADD COLUMN version BIGINT NOT NULL DEFAULT 0;
