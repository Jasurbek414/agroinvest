-- Backs the new SuperAdmin category management UI (PLATFORM_ROADMAP.md Phase 2)
-- and its create/update endpoints on AssetCategoryController.
INSERT INTO permissions (code, description) VALUES
  ('category.manage', 'Aktiv kategoriyalarini boshqarish')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission_code) VALUES
  ('SUPERADMIN', 'category.manage')
ON CONFLICT DO NOTHING;
