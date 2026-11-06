-- WORLD DATABASE. WPICK1B: every housing catalog piece gets a clickable (type 10) twin template 9400000 + catalog_id,
-- so   .pickup new <catalog_id> <item> [count]   works for ANY furniture. Safe to run more than once (INSERT IGNORE);
-- run it again after new housing pieces are added.
SET NAMES utf8mb4;

INSERT IGNORE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`)
SELECT 9400000 + c.`catalog_id`, 10, t.`displayId`, LEFT(CONCAT('Reborn Pickup: ', c.`name_en`), 100), t.`size`, 0, 0, 0, 0
FROM `reborn_housing_catalog` c
JOIN `gameobject_template` t ON t.`entry` = c.`gobject_entry`
WHERE c.`catalog_id` < 100000;

SELECT COUNT(*) AS mirrored FROM `gameobject_template` WHERE `entry` BETWEEN 9400000 AND 9499999;
