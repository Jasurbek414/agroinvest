-- Manual top-up approval queue (interim replacement for a live Payme/Click
-- gateway, per product decision - PaymentService/PaymentController remain
-- untouched and dormant for future reactivation). Mirrors withdrawal_requests'
-- shape but does NOT touch the wallet at creation - only on APPROVED does the
-- balance move, unlike withdrawal_requests which debits immediately on request.
CREATE TABLE deposit_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    amount DECIMAL(18,2) NOT NULL,
    proof_url VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    admin_comment VARCHAR(500),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    CONSTRAINT chk_deposit_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    CONSTRAINT chk_deposit_amount CHECK (amount > 0)
);
CREATE INDEX idx_deposit_requests_user ON deposit_requests(user_id, created_at DESC);
CREATE INDEX idx_deposit_requests_pending ON deposit_requests(status) WHERE status = 'PENDING';
