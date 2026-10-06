CREATE TABLE IF NOT EXISTS `character_re_pity` (
  `guid` INT UNSIGNED NOT NULL,
  `misses` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `character_re_pity` (`guid`, `misses`)
SELECT `item`.`owner_guid`, LEAST(COUNT(*), 4)
FROM `character_item_enchantments` AS `roll`
INNER JOIN `item_instance` AS `item` ON `item`.`guid` = `roll`.`item_guid`
WHERE `roll`.`enchantment_id` = 0
  AND `item`.`owner_guid` > 0
GROUP BY `item`.`owner_guid`
ON DUPLICATE KEY UPDATE `misses` = GREATEST(`misses`, VALUES(`misses`));
