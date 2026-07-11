-- SuperAdmin-authored news feed shown on the mobile app's home dashboard
-- (platform announcements, agro-market updates, seasonal tips).
CREATE TABLE news (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    image_url VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX idx_news_active_created ON news(is_active, created_at DESC);

INSERT INTO permissions (code, description) VALUES
  ('news.manage', 'Yangiliklarni boshqarish')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission_code) VALUES
  ('SUPERADMIN', 'news.manage')
ON CONFLICT DO NOTHING;
