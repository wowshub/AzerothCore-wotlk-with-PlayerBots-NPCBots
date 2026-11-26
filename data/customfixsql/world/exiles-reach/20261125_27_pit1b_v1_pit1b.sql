-- PIT1B V1 (2026-11-25, Claude) - candidate, NOT user-tested. Builds on PIT1A V1 (user: "the flow works").
--  * Spiders next to the cocoons: retail's Barrow Spider (160394) and Barrow Spiderling (160433), retail display 1088 (MineSpider, exists in the client),
--    16 spawns at the retail positions (all within 40 yd of a cocoon).
--  * Crenna's escape ride: a new taxi mount creature 9167011 with a stock elk-like display (Shadowhorn Stag 1992); the route is retail's own path 55640
--    (Lua), the way back up the spiral cave.
-- Safe to run twice. guids = live legal maximum + 1. Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'PIT1B %';
DELETE FROM `creature_template` WHERE `entry` IN (160394, 160433, 9167011);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (160394, 160433, 9167011);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 20 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;
SELECT COUNT(*) AS mount_9167010_must_be_1 FROM `creature_template` WHERE `entry` = 9167010;

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `family`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(160394, 'Barrow Spider 洞穴蜘蛛', NULL, 4, 4, 14, 0, 1, 1.14286, 0, 1, 0, 1, 3, '', 1, 0.5, 1, 0, ''),
(160433, 'Barrow Spiderling 洞穴小蜘蛛', NULL, 3, 3, 14, 0, 1, 1.14286, 0, 1, 0, 1, 3, '', 1, 0.4, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(160394, 0, 1088, 1, 1, 0),
(160433, 0, 1088, 0.7, 1, 0);

-- Crenna's elk: copy of the flying mount creature 9167010 (BOOST1A), only the model differs
DROP TEMPORARY TABLE IF EXISTS tmp_elk;
CREATE TEMPORARY TABLE tmp_elk AS SELECT * FROM `creature_template` WHERE `entry` = 9167010;
UPDATE tmp_elk SET `entry` = 9167011, `name` = 'Crenna''s Elk 克蕾娜的麋鹿';
INSERT INTO `creature_template` SELECT * FROM tmp_elk;
DROP TEMPORARY TABLE tmp_elk;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9167011, 0, 1992, 1.2, 1, 0);

-- retail spawns: spider 160394 (boss-sized) and spiderling 160433 around the five cocoons
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 160433, 12175, 1, 1, 0, 121.064, -2257.41, -4.91313, 1.97313, 120, 8, 1, 'PIT1B spiderling'),
(@g + 2, 160394, 12175, 1, 1, 0, 101.504, -2252.28, 39.7665, 0.813437, 120, 8, 1, 'PIT1B spider'),
(@g + 3, 160433, 12175, 1, 1, 0, 112.086, -2235.11, -8.46908, 5.58137, 120, 8, 1, 'PIT1B spiderling'),
(@g + 4, 160433, 12175, 1, 1, 0, 95.7304, -2276.29, -2.21239, 1.17246, 120, 8, 1, 'PIT1B spiderling'),
(@g + 5, 160433, 12175, 1, 1, 0, 107.153, -2234.09, -9.70459, 2.51215, 120, 8, 1, 'PIT1B spiderling'),
(@g + 6, 160433, 12175, 1, 1, 0, 120.392, -2262.13, -4.70385, 4.59883, 120, 8, 1, 'PIT1B spiderling'),
(@g + 7, 160394, 12175, 1, 1, 0, 69.1578, -2270.68, -1.16921, 4.07044, 120, 0, 0, 'PIT1B spider'),
(@g + 8, 160394, 12175, 1, 1, 0, 81.3202, -2248.97, -15.6674, 3.38789, 120, 8, 1, 'PIT1B spider'),
(@g + 9, 160394, 12175, 1, 1, 0, 107.677, -2217.47, 31.7139, 5.71659, 120, 0, 0, 'PIT1B spider'),
(@g + 10, 160433, 12175, 1, 1, 0, 94.7324, -2276.17, -2.31392, 1.45087, 120, 0, 0, 'PIT1B spiderling'),
(@g + 11, 160433, 12175, 1, 1, 0, 94.6857, -2278.1, -2.42065, 4.1713, 120, 0, 0, 'PIT1B spiderling'),
(@g + 12, 160394, 12175, 1, 1, 0, 111.171, -2255.96, 40.4003, 6.05837, 120, 0, 0, 'PIT1B spider'),
(@g + 13, 160394, 12175, 1, 1, 0, 32.4226, -2196.04, 17.9964, 5.76379, 120, 0, 0, 'PIT1B spider'),
(@g + 14, 160433, 12175, 1, 1, 0, 67.7092, -2197.26, 23.6976, 0.674411, 120, 0, 0, 'PIT1B spiderling'),
(@g + 15, 160433, 12175, 1, 1, 0, 76.4135, -2190.3, 24.4721, 4.92498, 120, 0, 0, 'PIT1B spiderling'),
(@g + 16, 160394, 12175, 1, 1, 0, 32.4206, -2262.56, 1.16272, 5.51561, 120, 0, 0, 'PIT1B spider');

SELECT (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'PIT1B %') AS spiders_must_be_16,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (160394, 160433, 9167011)) AS templates_must_be_3,
       (SELECT `CreatureDisplayID` FROM `creature_template_model` WHERE `CreatureID` = 9167011) AS elk_display_must_be_1992;
