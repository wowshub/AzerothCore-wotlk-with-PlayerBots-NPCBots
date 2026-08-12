-- A.22.7: only newly-created Death Knights receive rows through Lua event 1.
-- Existing Death Knights intentionally remain absent and therefore protected.
CREATE TABLE IF NOT EXISTS `spelldraft_dk_bootstrap` (
  `guid` INT UNSIGNED NOT NULL,
  `race` TINYINT UNSIGNED NOT NULL,
  `team` TINYINT UNSIGNED NOT NULL COMMENT '0=Alliance,1=Horde',
  `created_level` TINYINT UNSIGNED NOT NULL,
  `eligible` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `state` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=pending,1=converting,2=converted,3=failed',
  `selected_zone` TINYINT UNSIGNED NULL DEFAULT NULL,
  `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `converted_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_spelldraft_dk_bootstrap_character`
    FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

