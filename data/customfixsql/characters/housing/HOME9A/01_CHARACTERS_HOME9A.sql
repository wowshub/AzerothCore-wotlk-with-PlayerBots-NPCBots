-- CHARACTERS DATABASE (not world!). HOME9A: the per-character furniture stock. Safe to run more than once.
SET NAMES utf8mb4;
CREATE TABLE IF NOT EXISTS `reborn_housing_stock` (
  `guid`       INT UNSIGNED NOT NULL,
  `catalog_id` INT UNSIGNED NOT NULL,
  `count`      INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`, `catalog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
