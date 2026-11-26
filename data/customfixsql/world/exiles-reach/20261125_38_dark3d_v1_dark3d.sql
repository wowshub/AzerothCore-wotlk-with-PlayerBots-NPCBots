-- DARK3D V1 (2026-11-25, Claude) - candidate, NOT user-tested. Needs DARK3A applied.
-- Stop worldserver, run on the world database, restart. Safe to run twice.
-- 1) closed ogre door (stock arena door, display 7033) across the way out at the dungeon entrance; it cannot be clicked or opened.
-- 2) Tunk / Gorgroth / guards: stock HD armored ogre looks, much larger; guards moved a few yards out.

DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'DARK3D %';
DELETE FROM `gameobject_template_addon` WHERE `entry` = 9159850;
DELETE FROM `gameobject_template` WHERE `entry` = 9159850;
SELECT COUNT(*) AS arena_door_183971_must_be_1 FROM `gameobject_template` WHERE `entry` = 183971;
DROP TEMPORARY TABLE IF EXISTS tmp_gate;
CREATE TEMPORARY TABLE tmp_gate AS SELECT * FROM `gameobject_template` WHERE `entry` = 183971;
UPDATE tmp_gate SET `entry` = 9159850, `name` = 'Darkmaul Gate 暗槌大门', `size` = 1.1;
INSERT INTO `gameobject_template` SELECT * FROM tmp_gate;
DROP TEMPORARY TABLE tmp_gate;
-- flags 18 = locked (2) + not selectable (16)
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`) VALUES (9159850, 0, 18);
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < 16777215;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(@o + 1, 9159850, 12175, 1, 1, 866.16, -1377.17, 176.64, 3.6616, 0, 0, 0.966390, -0.257081, 300, 255, 1, 'DARK3D entrance gate');

UPDATE `creature_template_model` SET `CreatureDisplayID` = 18047, `DisplayScale` = 1.25 WHERE `CreatureID` = 157300 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 25192, `DisplayScale` = 1.75 WHERE `CreatureID` = 156814 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 11561, `DisplayScale` = 0.62 WHERE `CreatureID` = 9159801 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 14423, `DisplayScale` = 0.68 WHERE `CreatureID` = 9159802 AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 14423, `DisplayScale` = 0.68 WHERE `CreatureID` = 9159803 AND `Idx` = 0;

UPDATE `creature` SET `position_x` = 759.9, `position_y` = -1448.5 WHERE `map` = 12175 AND `Comment` = 'DARK3A centurion at boss 1' AND ABS(`position_x` - 757.0) < 0.2 AND ABS(`position_y` - (-1445.5)) < 0.2;
UPDATE `creature` SET `position_x` = 746.4, `position_y` = -1434.1 WHERE `map` = 12175 AND `Comment` = 'DARK3A shadowcaller at boss 1' AND ABS(`position_x` - 749.5) < 0.2 AND ABS(`position_y` - (-1437.5)) < 0.2;
UPDATE `creature` SET `position_x` = 858.5, `position_y` = -1632.4 WHERE `map` = 12175 AND `Comment` = 'DARK3A centurion at boss 2' AND ABS(`position_x` - 856.0) < 0.2 AND ABS(`position_y` - (-1629.5)) < 0.2;
UPDATE `creature` SET `position_x` = 845.7, `position_y` = -1632.4 WHERE `map` = 12175 AND `Comment` = 'DARK3A centurion at boss 2' AND ABS(`position_x` - 848.5) < 0.2 AND ABS(`position_y` - (-1629.5)) < 0.2;
UPDATE `creature` SET `position_x` = 852.5, `position_y` = -1617.1 WHERE `map` = 12175 AND `Comment` = 'DARK3A channeler at boss 2' AND ABS(`position_x` - 852.5) < 0.2 AND ABS(`position_y` - (-1620.5)) < 0.2;

SELECT (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` = 'DARK3D entrance gate') AS gate_must_be_1,
       (SELECT COUNT(*) FROM `creature_template_model` WHERE `CreatureID` IN (157300, 156814, 9159801, 9159802, 9159803) AND `CreatureDisplayID` IN (18047, 25192, 11561, 14423)) AS looks_must_be_5,
       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'DARK3A %' AND ((ABS(`position_x` - 759.9) < 0.2 AND ABS(`position_y` - (-1448.5)) < 0.2) OR (ABS(`position_x` - 746.4) < 0.2 AND ABS(`position_y` - (-1434.1)) < 0.2) OR (ABS(`position_x` - 858.5) < 0.2 AND ABS(`position_y` - (-1632.4)) < 0.2) OR (ABS(`position_x` - 845.7) < 0.2 AND ABS(`position_y` - (-1632.4)) < 0.2) OR (ABS(`position_x` - 852.5) < 0.2 AND ABS(`position_y` - (-1617.1)) < 0.2))) AS moved_guards_must_be_5;
