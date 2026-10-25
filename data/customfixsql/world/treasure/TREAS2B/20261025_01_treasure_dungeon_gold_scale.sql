-- TREAS2B: 在 world 库执行。宝箱种类加一列“副本金币是否随人数缩放”（0 = 不缩放，整份给；1 = 跟 mod-dungeon-scale 缩放）
-- 可重复执行：列已存在时什么都不做
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'reborn_treasure_types' AND COLUMN_NAME = 'dungeon_gold_scale');
SET @sql := IF(@has = 0,
    'ALTER TABLE reborn_treasure_types ADD COLUMN dungeon_gold_scale TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER is_active',
    'SELECT ''dungeon_gold_scale already exists''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT entry, name, dungeon_gold_scale FROM reborn_treasure_types ORDER BY entry;
