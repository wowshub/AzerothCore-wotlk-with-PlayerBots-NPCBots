-- A.20: server-authoritative Heritage selections (characters database)
CREATE TABLE IF NOT EXISTS `character_heritage_spells` (
    `player_guid` INT UNSIGNED NOT NULL,
    `spell_id` INT UNSIGNED NOT NULL,
    `category` TINYINT UNSIGNED NOT NULL,
    `selection_key` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`player_guid`, `spell_id`),
    KEY `idx_heritage_category` (`player_guid`, `category`, `selection_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `character_heritage_state` (
    `player_guid` INT UNSIGNED NOT NULL,
    `migrated` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (`player_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
