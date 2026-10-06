-- Formal dungeon bosses are registered by instance_encounters, not by
-- creature_template.rank=3 (which denotes world bosses).
UPDATE `creature_loot_template` AS `loot`
INNER JOIN `creature_template` AS `creature`
        ON `creature`.`lootid` = `loot`.`Entry`
INNER JOIN `instance_encounters` AS `encounter`
        ON `encounter`.`creditType` = 0
       AND `encounter`.`creditEntry` = `creature`.`entry`
SET `loot`.`Chance` = 15
WHERE `loot`.`Item` = 25462;
