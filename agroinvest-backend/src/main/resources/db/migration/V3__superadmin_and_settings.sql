-- Platform settings table
CREATE TABLE platform_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    description VARCHAR(500),
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT now()
);

-- Audit log for tracking actions of admins/superadmins (IMMUTABLE)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(100) NOT NULL, -- e.g., 'CREATE_ADMIN', 'UPDATE_SETTINGS', 'BLOCK_USER'
    entity_type VARCHAR(100), -- e.g., 'User', 'Project', 'PlatformSettings'
    entity_id VARCHAR(100),
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_date ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
