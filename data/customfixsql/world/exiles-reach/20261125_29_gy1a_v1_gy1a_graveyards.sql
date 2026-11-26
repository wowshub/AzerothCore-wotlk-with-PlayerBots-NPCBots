-- GY1A V1 (2026-11-25, Claude) - candidate, NOT user-tested.
-- More graveyards + Spirit Healers (stock creature 6491) on Exile's Reach (map 12175), at the retail graveyards (LoreWalkerTDB world_safe_locs / graveyard_zone,
-- ghost zone 10424) and the retail Spirit Healer spawns next to them. The wreck-beach graveyard 117501 of MAP12S stays.
-- ids 117502-117508 are ours; graveyard_zone.GhostZone = 12175 like the MAP12S one (the server .map files carry area id 12175), faction 0 = both factions.
-- Safe to run twice. guids = live legal maximum + 1 (must stay below 16777215). Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;
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
(@g + 1, 6491, 12175, 1, 1, 0, -478.505, -2612.9, 5.29562, 3.85427, 300, 0, 0, 'GY1A spirit healer Murloc Hideaway'),
(@g + 2, 6491, 12175, 1, 1, 0, -237.892, -2533.05, 27.4599, 3.9533, 300, 0, 0, 'GY1A spirit healer Abandoned Camp'),
(@g + 3, 6491, 12175, 1, 1, 0, 71.0, -2409.0, 95.7, 3.9, 300, 0, 0, 'GY1A spirit healer Darkmaul Plains'),
(@g + 4, 6491, 12175, 1, 1, 0, 109.522, -2269.03, 97.0654, 0.878314, 300, 0, 0, 'GY1A spirit healer Hrun''s Barrow'),
(@g + 5, 6491, 12175, 1, 1, 0, 114.099, -2258.47, 97.7214, 5.69682, 300, 0, 0, 'GY1A spirit healer Hrun''s Barrow'),
(@g + 6, 6491, 12175, 1, 1, 0, 380.863, -2469.35, 131.078, 3.07736, 300, 0, 0, 'GY1A spirit healer Harpy Roost'),
(@g + 7, 6491, 12175, 1, 1, 0, 280.393, -2381.49, 86.2335, 5.3854, 300, 0, 0, 'GY1A spirit healer Ogre Ruins'),
(@g + 8, 6491, 12175, 1, 1, 0, 353.312, -2019.81, 128.113, 2.39936, 300, 0, 0, 'GY1A spirit healer Darkmaul Citadel');

SELECT (SELECT COUNT(*) FROM `game_graveyard` WHERE `ID` BETWEEN 117502 AND 117508) AS graveyards_must_be_7,
       (SELECT COUNT(*) FROM `graveyard_zone` WHERE `ID` BETWEEN 117502 AND 117508 AND `GhostZone` = 12175) AS zone_rows_must_be_7,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'GY1A %') AS healers_must_be_8,
       (SELECT MAX(`guid`) FROM `creature`) AS max_guid_after;
