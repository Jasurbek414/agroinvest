INSERT INTO permissions (code, description) VALUES
  ('deposit.review', 'To''lov (depozit) so''rovini ko''rib chiqish')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission_code) VALUES
  ('MODERATOR', 'deposit.review'),
  ('ADMIN', 'deposit.review'),
  ('SUPERADMIN', 'deposit.review')
ON CONFLICT DO NOTHING;
