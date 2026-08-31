-- Import into the CHARACTER database (normally acore_characters).
-- A.30: all Random Draft races share the same durable one-time Tome receipt.

CREATE TABLE IF NOT EXISTS `spelldraft_starter_tome_grant` (
  `guid` INT UNSIGNED NOT NULL,
  `item_id` INT UNSIGNED NOT NULL DEFAULT 25462,
  `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`guid`),
  CONSTRAINT `fk_spelldraft_starter_tome_character`
    FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `spelldraft_starter_tome_grant` (`guid`, `item_id`)
SELECT DISTINCT `ci`.`guid`, 25462
  FROM `character_inventory` AS `ci`
  INNER JOIN `item_instance` AS `ii` ON `ii`.`guid` = `ci`.`item`
 WHERE `ii`.`itemEntry` = 25462;
