-- Self-referencing 3-level category taxonomy (PLATFORM_ROADMAP.md decision #4) -
-- purely additive: does NOT touch/replace the existing asset_type/animal_type
-- enum columns or their dependent search/dashboard code (deferred to Phase 5,
-- since the target tree restructures the TOP level - Parrandachilik moves from
-- a sibling of Chorvachilik to nested under it - not just adding depth).
-- level/sort_order are INTEGER (not SMALLINT) to match the entity's Integer
-- fields - Hibernate's ddl-auto: validate rejects an int2/int4 mismatch.
CREATE TABLE asset_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES asset_categories(id),
    level INTEGER NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    name_uz VARCHAR(150) NOT NULL,
    icon VARCHAR(50),
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT now()
);
CREATE INDEX idx_asset_categories_parent ON asset_categories(parent_id);
CREATE INDEX idx_asset_categories_level ON asset_categories(level);
