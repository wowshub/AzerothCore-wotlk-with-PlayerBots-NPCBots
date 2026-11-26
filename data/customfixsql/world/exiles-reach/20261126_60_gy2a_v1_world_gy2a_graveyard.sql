-- GY2A V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- 1) New graveyard 117510 + Spirit Healer in the Darkmaul courtyard at the Thrall / Alliance leader camp (two-headed ogre area).
-- 2) Re-applies GY1A (seven island graveyards 117502-117508), now with the Spirit Healers visible to BOTH factions (phase 3).
SET @spawn_limit := 16777215;
SELECT COUNT(*) AS gy1a_graveyards_already_present_before_this_run FROM `game_graveyard` WHERE `ID` BETWEEN 117502 AND 117508;
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'GY2A %';
DELETE FROM `graveyard_zone` WHERE `ID` = 117510;
DELETE FROM `game_graveyard` WHERE `ID` = 117510;
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'GY1A %';
DELETE FROM `graveyard_zone` WHERE `ID` BETWEEN 117502 AND 117508;
DELETE FROM `game_graveyard` WHERE `ID` BETWEEN 117502 AND 117508;
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 10 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS legal_max_guid;
SELECT COUNT(*) AS spirit_healer_template_6491_must_be_1 FROM `creature_template` WHERE `entry` = 6491;

INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(117502, 12175, -486.288, -2619.87, 3.45449, 'Exile''s Reach - Murloc Hideaway (GY1A, retail 100034)'),
(117503, 12175, -246.226, -2542.43, 27.2975, 'Exile''s Reach - Abandoned Camp (GY1A, retail 100035)'),
(117504, 12175, 68.6424, -2411.65, 95.6735, 'Exile''s Reach - Darkmaul Plains (GY1A, retail 100036)'),
(117505, 12175, 126.362, -2267.02, 97.3479, 'Exile''s Reach - Hrun''s Barrow (GY1A, retail 100039)'),
(117506, 12175, 367.405, -2468.5, 131.252, 'Exile''s Reach - Harpy Roost (GY1A, retail 100038)'),
(117507, 12175, 288, -2393, 90, 'Exile''s Reach - Ogre Ruins (GY1A, retail 20112)'),
(117508, 12175, 339.646, -2005.96, 128.229, 'Exile''s Reach - Darkmaul Citadel (GY1A, retail 100037)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(117502, 12175, 0, 'Murloc Hideaway, both factions (GY1A)'),
(117503, 12175, 0, 'Abandoned Camp, both factions (GY1A)'),
(117504, 12175, 0, 'Darkmaul Plains, both factions (GY1A)'),
(117505, 12175, 0, 'Hrun''s Barrow, both factions (GY1A)'),
(117506, 12175, 0, 'Harpy Roost, both factions (GY1A)'),
(117507, 12175, 0, 'Ogre Ruins, both factions (GY1A)'),
(117508, 12175, 0, 'Darkmaul Citadel, both factions (GY1A)');

-- Spirit Healers: retail spawn positions; Darkmaul Plains has none in retail, one is placed 3 yards from its graveyard
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 6491, 12175, 1, 3, 0, -478.505, -2612.9, 5.29562, 3.85427, 300, 0, 0, 'GY1A spirit healer Murloc Hideaway'),
(@g + 2, 6491, 12175, 1, 3, 0, -237.892, -2533.05, 27.4599, 3.9533, 300, 0, 0, 'GY1A spirit healer Abandoned Camp'),
(@g + 3, 6491, 12175, 1, 3, 0, 71.0, -2409.0, 95.7, 3.9, 300, 0, 0, 'GY1A spirit healer Darkmaul Plains'),
(@g + 4, 6491, 12175, 1, 3, 0, 109.522, -2269.03, 97.0654, 0.878314, 300, 0, 0, 'GY1A spirit healer Hrun''s Barrow'),
(@g + 5, 6491, 12175, 1, 3, 0, 114.099, -2258.47, 97.7214, 5.69682, 300, 0, 0, 'GY1A spirit healer Hrun''s Barrow'),
(@g + 6, 6491, 12175, 1, 3, 0, 380.863, -2469.35, 131.078, 3.07736, 300, 0, 0, 'GY1A spirit healer Harpy Roost'),
(@g + 7, 6491, 12175, 1, 3, 0, 280.393, -2381.49, 86.2335, 5.3854, 300, 0, 0, 'GY1A spirit healer Ogre Ruins'),
(@g + 8, 6491, 12175, 1, 3, 0, 353.312, -2019.81, 128.113, 2.39936, 300, 0, 0, 'GY1A spirit healer Darkmaul Citadel');


-- ===== courtyard =====
SELECT COALESCE(MAX(`guid`), 0) INTO @c FROM `creature` WHERE `guid` < @spawn_limit;
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(117510, 12175, 709, -1884, 187.0, 'Exile''s Reach - Darkmaul courtyard camp (GY2A)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(117510, 12175, 0, 'Darkmaul courtyard camp, both factions (GY2A)');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@c + 1, 6491, 12175, 1, 3, 0, 703.5, -1886.5, 187.0, 0.45, 300, 0, 0, 'GY2A spirit healer Darkmaul courtyard');
-- every Spirit Healer of the island is shared by both factions
UPDATE `creature` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id1` = 6491;

SELECT (SELECT COUNT(*) FROM `game_graveyard` WHERE `ID` BETWEEN 117502 AND 117508 OR `ID` = 117510) AS graveyards_must_be_8,
       (SELECT COUNT(*) FROM `graveyard_zone` WHERE (`ID` BETWEEN 117502 AND 117508 OR `ID` = 117510) AND `GhostZone` = 12175) AS zone_rows_must_be_8,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'GY1A %' OR `Comment` LIKE 'GY2A %') AS healers_must_be_9,
       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `id1` = 6491 AND `phaseMask` <> 3) AS healers_not_shared_must_be_0,
       (SELECT MAX(`guid`) FROM `creature`) AS max_guid_after;
