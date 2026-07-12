-- Add proposed payout details to projects table
ALTER TABLE projects ADD COLUMN proposed_sale_price NUMERIC(19, 2);
ALTER TABLE projects ADD COLUMN sale_documents JSONB;
ALTER TABLE projects ADD COLUMN payout_proposed_at TIMESTAMP WITHOUT TIME ZONE;

-- Seed default max expense percentage settings
INSERT INTO platform_settings (setting_key, setting_value, description)
VALUES ('max_expense_pct', '80', 'Loyihadan fermer yuboradigan va tasdiqlanadigan maksimal xarajat foizi')
ON CONFLICT (setting_key) DO NOTHING;
