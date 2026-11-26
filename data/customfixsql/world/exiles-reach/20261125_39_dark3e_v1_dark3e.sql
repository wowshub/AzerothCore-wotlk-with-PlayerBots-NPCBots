-- DARK3E V1 (2026-11-25, Claude) - candidate, NOT user-tested. Stop worldserver, run on the world database, restart. Safe to run twice.
-- Replaces the DARK3D entrance door (too low for the 26 yard high opening) with a rock fall that fills it from floor to ceiling.

DELETE FROM `gameobject` WHERE `map` = 12175 AND (`Comment` = 'DARK3D entrance gate' OR `Comment` LIKE 'DARK3E %');
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (9159850, 9159851, 9159852, 9159853);
DELETE FROM `gameobject_template` WHERE `entry` IN (9159850, 9159851, 9159852, 9159853);
SELECT COUNT(*) AS arena_door_183971_must_be_1 FROM `gameobject_template` WHERE `entry` = 183971;
DROP TEMPORARY TABLE IF EXISTS tmp_rock;
CREATE TEMPORARY TABLE tmp_rock AS SELECT * FROM `gameobject_template` WHERE `entry` = 183971;
UPDATE tmp_rock SET `entry` = 9159851, `displayId` = 753, `name` = 'Rockfall 落石', `size` = 1.0;
INSERT INTO `gameobject_template` SELECT * FROM tmp_rock;
UPDATE tmp_rock SET `entry` = 9159852, `displayId` = 753, `name` = 'Rockfall 落石', `size` = 0.7;
INSERT INTO `gameobject_template` SELECT * FROM tmp_rock;
UPDATE tmp_rock SET `entry` = 9159853, `displayId` = 2230, `name` = 'Rockfall 落石', `size` = 1.0;
INSERT INTO `gameobject_template` SELECT * FROM tmp_rock;
DROP TEMPORARY TABLE tmp_rock;
-- flags 18 = locked (2) + not selectable (16)
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`) VALUES (9159851, 0, 18), (9159852, 0, 18), (9159853, 0, 18);
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < 16777215;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(@o + 1, 9159851, 12175, 1, 1, 867.12, -1378.83, 176.64, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 01'),
(@o + 2, 9159852, 12175, 1, 1, 863.14, -1371.89, 176.64, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 02'),
(@o + 3, 9159853, 12175, 1, 1, 866.59, -1379.13, 182.64, 3.6616, 0, 0, 0.966390, -0.257081, 300, 255, 1, 'DARK3E rock 03'),
(@o + 4, 9159851, 12175, 1, 1, 865.13, -1375.36, 184.14, 3.6616, 0, 0, 0.966390, -0.257081, 300, 255, 1, 'DARK3E rock 04'),
(@o + 5, 9159851, 12175, 1, 1, 867.12, -1378.83, 187.14, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 05'),
(@o + 6, 9159852, 12175, 1, 1, 864.13, -1373.62, 187.14, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 06'),
(@o + 7, 9159853, 12175, 1, 1, 866.59, -1379.13, 193.14, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 07'),
(@o + 8, 9159853, 12175, 1, 1, 864.61, -1375.66, 196.14, 3.6616, 0, 0, 0.966390, -0.257081, 300, 255, 1, 'DARK3E rock 08'),
(@o + 9, 9159853, 12175, 1, 1, 866.59, -1379.13, 194.64, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 09'),
(@o + 10, 9159853, 12175, 1, 1, 865.65, -1377.48, 199.14, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 10'),
(@o + 11, 9159852, 12175, 1, 1, 869.35, -1382.74, 197.64, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 11'),
(@o + 12, 9159852, 12175, 1, 1, 865.13, -1375.36, 199.14, 0.5200, 0, 0, 0.257081, 0.966390, 300, 255, 1, 'DARK3E rock 12');

SELECT (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'DARK3E %') AS rocks_must_be_12,
       (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` IN (9159851, 9159852, 9159853)) AS templates_must_be_3,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` = 'DARK3D entrance gate') AS old_gate_must_be_0;
