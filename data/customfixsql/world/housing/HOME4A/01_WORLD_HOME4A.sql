-- WORLD DATABASE. HOME4A: one player may own several plots. Safe to run more than once. No --force.
-- Drops the "one plot per owner" unique key and puts a plain index in its place.
SET NAMES utf8mb4;

SET @has_uk := (SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE() AND table_name = 'reborn_housing_plot' AND index_name = 'uk_owner');
SET @sql := IF(@has_uk > 0, 'ALTER TABLE `reborn_housing_plot` DROP INDEX `uk_owner`', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @has_ix := (SELECT COUNT(*) FROM information_schema.statistics
                WHERE table_schema = DATABASE() AND table_name = 'reborn_housing_plot' AND index_name = 'ix_owner');
SET @sql := IF(@has_ix = 0, 'ALTER TABLE `reborn_housing_plot` ADD INDEX `ix_owner` (`owner_guid`)', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
