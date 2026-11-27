-- MAPSRV2A V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- One graveyard + Spirit Healer (both factions) near the start of each new map, and the .tele names Dracthyr / Haranir.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
DELETE FROM `creature` WHERE `Comment` LIKE 'MAPSRV2A %';
DELETE FROM `graveyard_zone` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_graveyard` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_tele` WHERE `name` IN ('Dracthyr', 'Haranir');
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 5 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;
SELECT COALESCE(MAX(`id`), 0) INTO @t FROM `game_tele`;
-- Forbidden Reach 禁忌离岛
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES (125701, 12570, 6517.0, -3317.0, 163.26, 'Dracthyr start (MAPSRV2A)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES (125701, 12570, 0, 'Dracthyr start, both factions (MAPSRV2A)');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 6491, 12570, 1, 3, 0, 6521.0, -3315.0, 163.26, 3.6, 300, 0, 0, 'MAPSRV2A spirit healer Dracthyr');
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`) VALUES (@t + 1, 6517.0, -3317.0, 165.96, 0.0, 12570, 'Dracthyr');
-- Harandar 哈籁尼尔出生地
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES (126941, 12694, 1252.0, 908.0, 1331.77, 'Haranir start (MAPSRV2A)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES (126941, 12694, 0, 'Haranir start, both factions (MAPSRV2A)');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 2, 6491, 12694, 1, 3, 0, 1256.0, 910.0, 1330.84, 3.6, 300, 0, 0, 'MAPSRV2A spirit healer Haranir');
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`) VALUES (@t + 2, 1263.35, 922.787, 1332.45, 1.356, 12694, 'Haranir');
SELECT (SELECT COUNT(*) FROM `game_graveyard` WHERE `ID` IN (125701, 126941)) AS graveyards_must_be_2,
       (SELECT COUNT(*) FROM `graveyard_zone` WHERE `ID` IN (125701, 126941)) AS zone_rows_must_be_2,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'MAPSRV2A %') AS healers_must_be_2,
       (SELECT COUNT(*) FROM `game_tele` WHERE `name` IN ('Dracthyr', 'Haranir')) AS tele_names_must_be_2;
