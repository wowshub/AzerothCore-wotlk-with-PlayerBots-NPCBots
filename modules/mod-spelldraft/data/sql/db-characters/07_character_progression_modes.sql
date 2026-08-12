-- A.22: per-character three-mode authority and legacy migration.
CREATE TABLE IF NOT EXISTS `spelldraft_character_mode` (
    `guid` INT UNSIGNED NOT NULL,
    `mode` TINYINT UNSIGNED NOT NULL COMMENT '1=classic, 2=random draft, 3=free pick',
    `locked` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `selected_level` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `selection_version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    `free_skill_points` INT UNSIGNED NOT NULL DEFAULT 0,
    `free_talent_points` INT UNSIGNED NOT NULL DEFAULT 0,
    `selected_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`guid`),
    CONSTRAINT `fk_spelldraft_mode_character`
        FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Preserve every legacy character. Active draft characters remain Random Draft;
-- old non-draft/prestige characters remain Classic and are never prompted.
INSERT IGNORE INTO `spelldraft_character_mode`
    (`guid`, `mode`, `locked`, `selected_level`, `selection_version`)
SELECT `player_id`, IF(`draft_state` = 1, 2, 1), 1, 1, 1
  FROM `prestige_stats`;

