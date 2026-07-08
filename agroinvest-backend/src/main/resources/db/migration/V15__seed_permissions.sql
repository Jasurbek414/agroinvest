-- Permission codes covering every distinct @PreAuthorize pattern found across
-- the backend today (see PLATFORM_ROADMAP.md Phase 0.1). Endpoints themselves
-- are NOT migrated to hasPermission() in this migration - that's Phase 1,
-- endpoint by endpoint. This seed only makes the permission layer usable and
-- pre-populated with a role_permissions mapping that mirrors current
-- hasRole()/hasAnyRole() behavior, so adopting hasPermission() on any given
-- endpoint later is a behavior-neutral swap, not a re-design.
INSERT INTO permissions (code, description) VALUES
  ('project.create', 'Yangi loyiha yaratish'),
  ('project.update', 'O''z loyihasini tahrirlash'),
  ('project.delete', 'O''z loyihasini o''chirish'),
  ('project.moderate', 'Loyihani tasdiqlash, rad etish yoki bekor qilish'),
  ('project.freeze', 'Loyihani muzlatish yoki bo''shatish'),
  ('project.payout', 'Loyiha daromadini taqsimlash'),
  ('investment.create', 'Sarmoya kiritish'),
  ('investment.cancel', 'Sarmoyani bekor qilish'),
  ('investment.view-project', 'Loyiha investorlari ro''yxatini ko''rish'),
  ('report.submit', 'Hisobot yuklash'),
  ('report.verify', 'Hisobotni tasdiqlash'),
  ('expense.submit', 'Harajat kiritish'),
  ('expense.review', 'Harajatni ko''rib chiqish'),
  ('vet.submit', 'Veterinar hujjat yuklash'),
  ('vet.verify', 'Veterinar hujjatini tasdiqlash'),
  ('withdrawal.review', 'Pul yechish so''rovini ko''rib chiqish'),
  ('dispute.resolve', 'Nizoni hal qilish'),
  ('user.block', 'Foydalanuvchini bloklash'),
  ('user.kyc-review', 'KYC holatini ko''rib chiqish'),
  ('user.manage-staff', 'Xodim hisoblarini yaratish va boshqarish'),
  ('settings.update', 'Platforma sozlamalarini o''zgartirish'),
  ('audit.view', 'Audit logni ko''rish'),
  ('permission.manage', 'Ruxsat va rollarni boshqarish')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permissions (role, permission_code) VALUES
  ('FARMER', 'project.create'),
  ('FARMER', 'project.update'),
  ('FARMER', 'project.delete'),
  ('FARMER', 'report.submit'),
  ('FARMER', 'expense.submit'),
  ('FARMER', 'vet.submit'),

  ('VERIFIER', 'report.submit'),

  ('INVESTOR', 'investment.create'),
  ('INVESTOR', 'investment.cancel'),

  ('MODERATOR', 'project.moderate'),
  ('MODERATOR', 'report.verify'),
  ('MODERATOR', 'expense.review'),
  ('MODERATOR', 'vet.verify'),
  ('MODERATOR', 'withdrawal.review'),
  ('MODERATOR', 'investment.view-project'),
  ('MODERATOR', 'user.kyc-review'),
  ('MODERATOR', 'dispute.resolve'),

  ('ADMIN', 'project.moderate'),
  ('ADMIN', 'project.payout'),
  ('ADMIN', 'report.verify'),
  ('ADMIN', 'expense.review'),
  ('ADMIN', 'vet.verify'),
  ('ADMIN', 'withdrawal.review'),
  ('ADMIN', 'investment.view-project'),
  ('ADMIN', 'user.block'),
  ('ADMIN', 'user.kyc-review'),
  ('ADMIN', 'dispute.resolve'),

  ('SUPERADMIN', 'project.moderate'),
  ('SUPERADMIN', 'project.payout'),
  ('SUPERADMIN', 'project.freeze'),
  ('SUPERADMIN', 'report.verify'),
  ('SUPERADMIN', 'expense.review'),
  ('SUPERADMIN', 'vet.verify'),
  ('SUPERADMIN', 'withdrawal.review'),
  ('SUPERADMIN', 'investment.view-project'),
  ('SUPERADMIN', 'user.block'),
  ('SUPERADMIN', 'user.kyc-review'),
  ('SUPERADMIN', 'user.manage-staff'),
  ('SUPERADMIN', 'dispute.resolve'),
  ('SUPERADMIN', 'settings.update'),
  ('SUPERADMIN', 'audit.view'),
  ('SUPERADMIN', 'permission.manage')
ON CONFLICT DO NOTHING;
