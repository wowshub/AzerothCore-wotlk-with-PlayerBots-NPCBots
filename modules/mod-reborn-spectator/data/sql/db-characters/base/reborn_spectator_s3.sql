-- RebornWOW S.4: authenticated carrier-login bridge plus automatic carrier metadata.
-- Database: characters

CREATE TABLE IF NOT EXISTS `reborn_spectator_carrier` (
  `account_id` INT UNSIGNED NOT NULL,
  `carrier_guid` INT UNSIGNED NOT NULL,
  `public_alias` VARCHAR(24) NOT NULL DEFAULT 'Spectator',
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `auto_created` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`account_id`),
  UNIQUE KEY `uq_reborn_spectator_carrier_guid` (`carrier_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @reborn_s4_auto_created_exists := (
  SELECT COUNT(*)
  FROM `information_schema`.`COLUMNS`
  WHERE `TABLE_SCHEMA` = DATABASE()
    AND `TABLE_NAME` = 'reborn_spectator_carrier'
    AND `COLUMN_NAME` = 'auto_created'
);
SET @reborn_s4_auto_created_sql := IF(
  @reborn_s4_auto_created_exists = 0,
  'ALTER TABLE `reborn_spectator_carrier` ADD COLUMN `auto_created` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `enabled`',
  'SELECT 1'
);
PREPARE reborn_s4_auto_created_stmt FROM @reborn_s4_auto_created_sql;
EXECUTE reborn_s4_auto_created_stmt;
DEALLOCATE PREPARE reborn_s4_auto_created_stmt;

CREATE TABLE IF NOT EXISTS `reborn_spectator_consent` (
  `character_guid` INT UNSIGNED NOT NULL,
  `allow_spectate` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`character_guid`),
  KEY `idx_reborn_spectator_consent_allow` (`allow_spectate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `reborn_spectator_request` (
  `account_id` INT UNSIGNED NOT NULL,
  `carrier_guid` INT UNSIGNED NOT NULL,
  `target_guid` INT UNSIGNED NOT NULL,
  `requested_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NOT NULL,
  PRIMARY KEY (`account_id`),
  KEY `idx_reborn_spectator_request_target` (`target_guid`),
  KEY `idx_reborn_spectator_request_expiry` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
