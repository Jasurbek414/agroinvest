-- Seeds the confirmed taxonomy tree (see PLATFORM_ROADMAP.md "Tasdiqlangan
-- kategoriya tuzilmasi"). Parent lookups go through `code` (not hardcoded
-- UUIDs) so each INSERT stays readable and order-independent within its level.

-- Level 1 (9 top-level, mutually exclusive categories)
INSERT INTO asset_categories (level, code, name_uz, sort_order) VALUES
(1, 'CHORVACHILIK', 'Chorvachilik', 1),
(1, 'DEHQONCHILIK', 'Dehqonchilik', 2),
(1, 'BOGDORCHILIK', 'Bog''dorchilik', 3),
(1, 'UZUMCHILIK', 'Uzumchilik', 4),
(1, 'ISSIQXONA', 'Issiqxona', 5),
(1, 'ORMON_PLANTATSIYALARI', 'O''rmon plantatsiyalari', 6),
(1, 'ASALARICHILIK', 'Asalarichilik', 7),
(1, 'BALIQCHILIK', 'Baliqchilik', 8),
(1, 'BOSHQA', 'Boshqa', 9);

-- Level 2 under Chorvachilik
INSERT INTO asset_categories (parent_id, level, code, name_uz, sort_order)
SELECT id, 2, 'QORAMOLCHILIK', 'Qoramolchilik', 1 FROM asset_categories WHERE code = 'CHORVACHILIK'
UNION ALL SELECT id, 2, 'QOYCHILIK', 'Qo''ychilik', 2 FROM asset_categories WHERE code = 'CHORVACHILIK'
UNION ALL SELECT id, 2, 'ECHKICHILIK', 'Echkichilik', 3 FROM asset_categories WHERE code = 'CHORVACHILIK'
UNION ALL SELECT id, 2, 'QUYONCHILIK', 'Quyonchilik', 4 FROM asset_categories WHERE code = 'CHORVACHILIK'
UNION ALL SELECT id, 2, 'PARRANDACHILIK', 'Parrandachilik', 5 FROM asset_categories WHERE code = 'CHORVACHILIK'
UNION ALL SELECT id, 2, 'OTXONACHILIK', 'Otxonachilik', 6 FROM asset_categories WHERE code = 'CHORVACHILIK'
UNION ALL SELECT id, 2, 'TUYACHILIK', 'Tuyachilik', 7 FROM asset_categories WHERE code = 'CHORVACHILIK';

-- Level 3 under Qoramolchilik
INSERT INTO asset_categories (parent_id, level, code, name_uz, sort_order)
SELECT id, 3, 'QORAMOL_SUT', 'Sut', 1 FROM asset_categories WHERE code = 'QORAMOLCHILIK'
UNION ALL SELECT id, 3, 'QORAMOL_GOSHT', 'Go''sht', 2 FROM asset_categories WHERE code = 'QORAMOLCHILIK'
UNION ALL SELECT id, 3, 'QORAMOL_NASLDOR', 'Nasldor', 3 FROM asset_categories WHERE code = 'QORAMOLCHILIK'
UNION ALL SELECT id, 3, 'QORAMOL_BUQA_SEMIRTIRISH', 'Buqa semirtirish', 4 FROM asset_categories WHERE code = 'QORAMOLCHILIK';

-- Level 3 under Qo'ychilik
INSERT INTO asset_categories (parent_id, level, code, name_uz, sort_order)
SELECT id, 3, 'QOY_GOSHT', 'Go''sht', 1 FROM asset_categories WHERE code = 'QOYCHILIK'
UNION ALL SELECT id, 3, 'QOY_JUN', 'Jun', 2 FROM asset_categories WHERE code = 'QOYCHILIK'
UNION ALL SELECT id, 3, 'QOY_NASLDOR', 'Nasldor', 3 FROM asset_categories WHERE code = 'QOYCHILIK';

-- Level 3 under Echkichilik
INSERT INTO asset_categories (parent_id, level, code, name_uz, sort_order)
SELECT id, 3, 'ECHKI_SUT', 'Sut', 1 FROM asset_categories WHERE code = 'ECHKICHILIK'
UNION ALL SELECT id, 3, 'ECHKI_GOSHT', 'Go''sht', 2 FROM asset_categories WHERE code = 'ECHKICHILIK'
UNION ALL SELECT id, 3, 'ECHKI_NASLDOR', 'Nasldor', 3 FROM asset_categories WHERE code = 'ECHKICHILIK';

-- Level 3 under Parrandachilik
INSERT INTO asset_categories (parent_id, level, code, name_uz, sort_order)
SELECT id, 3, 'PARRANDA_TOVUQ', 'Tovuq', 1 FROM asset_categories WHERE code = 'PARRANDACHILIK'
UNION ALL SELECT id, 3, 'PARRANDA_BEDANA', 'Bedana', 2 FROM asset_categories WHERE code = 'PARRANDACHILIK'
UNION ALL SELECT id, 3, 'PARRANDA_KURKA', 'Kurka', 3 FROM asset_categories WHERE code = 'PARRANDACHILIK'
UNION ALL SELECT id, 3, 'PARRANDA_ORDAK', 'O''rdak', 4 FROM asset_categories WHERE code = 'PARRANDACHILIK'
UNION ALL SELECT id, 3, 'PARRANDA_GOZ', 'G''oz', 5 FROM asset_categories WHERE code = 'PARRANDACHILIK'
UNION ALL SELECT id, 3, 'PARRANDA_TUYAQUSH', 'Tuyaqush', 6 FROM asset_categories WHERE code = 'PARRANDACHILIK';

-- Level 2 under Dehqonchilik
INSERT INTO asset_categories (parent_id, level, code, name_uz, sort_order)
SELECT id, 2, 'GALLA', 'G''alla', 1 FROM asset_categories WHERE code = 'DEHQONCHILIK'
UNION ALL SELECT id, 2, 'SABZAVOT', 'Sabzavot', 2 FROM asset_categories WHERE code = 'DEHQONCHILIK'
UNION ALL SELECT id, 2, 'POLIZ', 'Poliz', 3 FROM asset_categories WHERE code = 'DEHQONCHILIK'
UNION ALL SELECT id, 2, 'DUKKAKLI', 'Dukkakli', 4 FROM asset_categories WHERE code = 'DEHQONCHILIK'
UNION ALL SELECT id, 2, 'MOYLI_EKINLAR', 'Moyli ekinlar', 5 FROM asset_categories WHERE code = 'DEHQONCHILIK'
UNION ALL SELECT id, 2, 'DORIVOR_OSIMLIKLAR', 'Dorivor o''simliklar', 6 FROM asset_categories WHERE code = 'DEHQONCHILIK';

-- Level 2 under Bog'dorchilik
INSERT INTO asset_categories (parent_id, level, code, name_uz, sort_order)
SELECT id, 2, 'URUGLI_MEVALAR', 'Urug''li mevalar', 1 FROM asset_categories WHERE code = 'BOGDORCHILIK'
UNION ALL SELECT id, 2, 'DANAKLI_MEVALAR', 'Danakli mevalar', 2 FROM asset_categories WHERE code = 'BOGDORCHILIK'
UNION ALL SELECT id, 2, 'YONGOQLI_DARAXTLAR', 'Yong''oqli daraxtlar', 3 FROM asset_categories WHERE code = 'BOGDORCHILIK'
UNION ALL SELECT id, 2, 'SITRUS_MEVALAR', 'Sitrus mevalar', 4 FROM asset_categories WHERE code = 'BOGDORCHILIK';
