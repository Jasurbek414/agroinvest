-- Nullable, additive: existing asset_type/animal_type columns and every query
-- that filters/groups by them are untouched. New projects don't set this yet
-- either - Phase 5 migrates ProjectRepository.search/DashboardService group-by
-- to category_id and backfills existing rows via a reviewed mapping.
ALTER TABLE projects ADD COLUMN category_id UUID REFERENCES asset_categories(id);
