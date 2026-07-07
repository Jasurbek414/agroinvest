-- Operational expense ledger per project (feed, medicine, vet, transport...).
-- payer_source records WHO bore the cost: INVESTOR_BUDGET expenses are
-- transparency-only (the raise already funded them via milestones); FARMER
-- expenses are reimbursed at payout before the profit split.

CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES projects(id),
    submitted_by UUID NOT NULL REFERENCES users(id),
    category VARCHAR(20) NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    description TEXT,
    receipt_urls JSONB DEFAULT '[]',
    expense_date DATE NOT NULL,
    payer_source VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP,
    review_comment VARCHAR(500),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    CONSTRAINT chk_expense_category
        CHECK (category IN ('FEED', 'MEDICINE', 'VET_SERVICE', 'TRANSPORT', 'LABOR', 'EQUIPMENT', 'OTHER')),
    CONSTRAINT chk_expense_payer CHECK (payer_source IN ('INVESTOR_BUDGET', 'FARMER')),
    CONSTRAINT chk_expense_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    CONSTRAINT chk_expense_amount CHECK (amount > 0)
);

CREATE INDEX idx_expenses_project ON expenses(project_id, created_at DESC);
CREATE INDEX idx_expenses_pending ON expenses(status) WHERE status = 'PENDING';
