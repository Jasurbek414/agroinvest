-- Additive fine-grained permission layer on top of the existing 6 fixed roles
-- (UserRole enum / users.role native PG enum - untouched by this migration).
-- role_permissions is seeded in V15 to mirror TODAY's effective @PreAuthorize
-- behavior exactly, so shipping this table changes nothing on day one.
--
-- custom_roles/custom_role_permissions/user_custom_roles let SuperAdmin create
-- genuinely new named roles (e.g. "Katta Moderator") bundling arbitrary
-- permission codes and assign them to specific users, WITHOUT touching
-- users.role - a user's effective permission set is the union of their base
-- role's permissions and all assigned custom roles' permissions.
--
-- Scoped gap (intentional, see PLATFORM_ROADMAP.md): endpoints still gated by
-- the legacy hasRole()/hasAnyRole() SpEL do not consult this table at all -
-- only endpoints migrated to hasPermission() do. Custom roles are additive-only
-- until an endpoint is migrated.

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(80) UNIQUE NOT NULL,
    description VARCHAR(300) NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role VARCHAR(20) NOT NULL,
    permission_code VARCHAR(80) NOT NULL REFERENCES permissions(code) ON DELETE CASCADE,
    CONSTRAINT uq_role_permission UNIQUE (role, permission_code)
);
CREATE INDEX idx_role_permissions_role ON role_permissions(role);

CREATE TABLE custom_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description VARCHAR(300),
    created_by UUID REFERENCES users(id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE custom_role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    custom_role_id UUID NOT NULL REFERENCES custom_roles(id) ON DELETE CASCADE,
    permission_code VARCHAR(80) NOT NULL REFERENCES permissions(code) ON DELETE CASCADE,
    CONSTRAINT uq_custom_role_permission UNIQUE (custom_role_id, permission_code)
);

CREATE TABLE user_custom_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    custom_role_id UUID NOT NULL REFERENCES custom_roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMP DEFAULT now(),
    CONSTRAINT uq_user_custom_role UNIQUE (user_id, custom_role_id)
);
CREATE INDEX idx_user_custom_roles_user ON user_custom_roles(user_id);
