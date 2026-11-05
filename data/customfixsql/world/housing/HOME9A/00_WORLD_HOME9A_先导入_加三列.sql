-- WORLD DATABASE. HOME9A step 1: three new columns. Import this BEFORE 01_WORLD_HOME9A.sql.
-- Plain ALTERs (no PREPARE), so any import tool runs them. If a column is already there (the server added it itself, or you
-- imported this twice) the tool reports "Duplicate column name": that is harmless, skip the error and carry on.
SET NAMES utf8mb4;
ALTER TABLE `reborn_housing_recipe` ADD COLUMN `rarity` TINYINT UNSIGNED NOT NULL DEFAULT 1;
ALTER TABLE `reborn_housing_recipe` ADD COLUMN `ways` TINYINT UNSIGNED NULL DEFAULT NULL;
ALTER TABLE `reborn_housing_object` ADD COLUMN `stocked` TINYINT UNSIGNED NOT NULL DEFAULT 1;
