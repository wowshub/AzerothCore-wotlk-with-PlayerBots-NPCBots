-- WORLD DATABASE. HOME1A: housing tables (plots, placed decor, catalog) + the four HOME0A pieces as catalog entries.
-- Safe to run more than once. Needs mod-reborn-housing compiled in. No --force.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `reborn_housing_plot` (
  `plot_id`    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `owner_guid` INT UNSIGNED NOT NULL,
  `map_id`     SMALLINT UNSIGNED NOT NULL,
  `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
  `radius`     FLOAT NOT NULL DEFAULT 30,
  `name`       VARCHAR(64) NOT NULL DEFAULT '',
  `created`    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`plot_id`),
  UNIQUE KEY `uk_owner` (`owner_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `reborn_housing_object` (
  `object_id`     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plot_id`       INT UNSIGNED NOT NULL,
  `catalog_id`    INT UNSIGNED NOT NULL,
  `gobject_entry` INT UNSIGNED NOT NULL,
  `spawn_id`      INT UNSIGNED NOT NULL COMMENT 'guid of the row in the core gameobject table',
  `map_id`        SMALLINT UNSIGNED NOT NULL,
  `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL, `o` FLOAT NOT NULL,
  `created`       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`object_id`),
  KEY `idx_plot` (`plot_id`),
  KEY `idx_spawn` (`spawn_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `reborn_housing_catalog` (
  `catalog_id`    INT UNSIGNED NOT NULL,
  `gobject_entry` INT UNSIGNED NOT NULL COMMENT 'gameobject_template.entry',
  `name_zh`       VARCHAR(64) NOT NULL,
  `name_en`       VARCHAR(64) NOT NULL,
  `category`      VARCHAR(32) NOT NULL DEFAULT '',
  `enabled`       TINYINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`catalog_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- The four HOME0A test pieces (templates 9190001-9190004, displays 910001-910004: new-model look, WarcraftXL clients only).
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES
 (1, 9190001, '高书架',       'Tall bookshelf',     'WXL', 1),
 (2, 9190002, '小喷泉',       'Small fountain',     'WXL', 1),
 (3, 9190003, '暗夜精灵木箱', 'Night elf crate',    'WXL', 1),
 (4, 9190004, '狼人帐篷',     'Worgen tent',        'WXL', 1);

-- Rollback: DROP TABLE `reborn_housing_object`, `reborn_housing_plot`, `reborn_housing_catalog`;
--           (placed decor stays in `gameobject`; remove it first with .home plot delete <id>)