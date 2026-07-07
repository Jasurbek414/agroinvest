-- Livestock detail (animal type / headcount / price-per-head), farmer own-asset
-- contribution, per-project negotiated profit split bounds and expense policy.
-- New enums are VARCHAR + CHECK (not native PG enums) so future values need no
-- ALTER TYPE ceremony; ?stringtype=unspecified makes both bind identically.

ALTER TABLE projects
    ADD COLUMN animal_type VARCHAR(30),
    ADD COLUMN headcount INTEGER,
    ADD COLUMN price_per_head DECIMAL(18,2),
    ADD COLUMN funding_mode VARCHAR(20) NOT NULL DEFAULT 'INVESTOR_FUNDED',
    ADD COLUMN farmer_contribution_value DECIMAL(18,2) NOT NULL DEFAULT 0,
    ADD COLUMN farmer_contribution_notes TEXT,
    ADD COLUMN farmer_contribution_verified_at TIMESTAMP,
    ADD COLUMN expense_policy VARCHAR(20) NOT NULL DEFAULT 'INVESTOR_BUDGET';

ALTER TABLE projects
    ADD CONSTRAINT chk_project_funding_mode
        CHECK (funding_mode IN ('INVESTOR_FUNDED', 'FARMER_ASSETS', 'MIXED')),
    ADD CONSTRAINT chk_project_expense_policy
        CHECK (expense_policy IN ('INVESTOR_BUDGET', 'FARMER_REIMBURSED', 'MIXED')),
    ADD CONSTRAINT chk_project_animal_type
        CHECK (animal_type IS NULL OR animal_type IN ('CHICKEN', 'SHEEP', 'CATTLE', 'GOAT', 'HORSE', 'FISH', 'OTHER')),
    ADD CONSTRAINT chk_project_farmer_contribution CHECK (farmer_contribution_value >= 0),
    ADD CONSTRAINT chk_project_headcount CHECK (headcount IS NULL OR headcount > 0),
    ADD CONSTRAINT chk_project_price_per_head CHECK (price_per_head IS NULL OR price_per_head > 0);

CREATE INDEX idx_projects_animal_type ON projects(animal_type) WHERE animal_type IS NOT NULL;

-- Bounds within which a farmer may propose the investor/farmer profit split
INSERT INTO platform_settings (setting_key, setting_value, description) VALUES
  ('min_investor_share_pct', '50', 'Fermer taklif qilishi mumkin bo''lgan eng past investor ulushi (%)'),
  ('max_investor_share_pct', '90', 'Fermer taklif qilishi mumkin bo''lgan eng yuqori investor ulushi (%)')
ON CONFLICT (setting_key) DO NOTHING;
