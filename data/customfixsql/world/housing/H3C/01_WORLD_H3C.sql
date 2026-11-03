-- WORLD DATABASE. H3C: every placed piece may have its own scale. Safe to run more than once. No --force.
SET NAMES utf8mb4;

SET @has_col := (SELECT COUNT(*) FROM information_schema.columns
                 WHERE table_schema = DATABASE() AND table_name = 'reborn_housing_object' AND column_name = 'scale');
SET @sql := IF(@has_col = 0, 'ALTER TABLE `reborn_housing_object` ADD COLUMN `scale` FLOAT NOT NULL DEFAULT 1', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Rollback: ALTER TABLE `reborn_housing_object` DROP COLUMN `scale`;   (use the HOME4B RebornHousing.cpp again before that)
