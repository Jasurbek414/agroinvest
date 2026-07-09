-- SuperAdmin-managed announcements/ads shown in the mobile app's "Market" tab
-- (repurposed from an earlier fake-data marketplace mock into a real,
-- superadmin-authored content feed) and optionally the web landing page.
CREATE TABLE banners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    link_url VARCHAR(500),
    target_audience VARCHAR(20) NOT NULL DEFAULT 'ALL',
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER NOT NULL DEFAULT 0,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    CONSTRAINT chk_banner_audience CHECK (target_audience IN ('ALL', 'INVESTOR', 'FARMER'))
);
CREATE INDEX idx_banners_active ON banners(is_active, sort_order);

INSERT INTO permissions (code, description) VALUES
  ('banner.manage', 'Reklama/e''lonlarni boshqarish')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission_code) VALUES
  ('SUPERADMIN', 'banner.manage')
ON CONFLICT DO NOTHING;
