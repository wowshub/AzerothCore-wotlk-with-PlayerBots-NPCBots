-- MAP12S V2 (2026-11-23, Claude): Exile's Reach (map 12175) graveyard + Spirit Healer at the wreck beach.
-- The island's server .map files now carry area id 12175 everywhere (the server AreaTable has no row for it: the core then uses
-- the raw id as the zone), so graveyard_zone.GhostZone = 12175. Safe to run twice. Keep worldserver stopped.
-- Spawn guid is taken from the live legal maximum + 1 (guid must stay below 16777215).
SET @spawn_limit := 16777215;
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` = 'MAP12S spirit healer (wreck beach)';
DELETE FROM `graveyard_zone` WHERE `ID` = 117501;
DELETE FROM `game_graveyard` WHERE `ID` = 117501;
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 1 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS legal_max_guid;

INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(117501, 12175, -424, -2606, 0.7, 'Exile''s Reach - wreck beach (MAP12S)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(117501, 12175, 0, 'Exile''s Reach - wreck beach, both factions (MAP12S)');

INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 6491, 12175, 1, 1, 0, -424, -2606, 0.7, 3.14159, 300, 0, 0, 'MAP12S spirit healer (wreck beach)');

SELECT `guid`, `id1`, `map`, `position_x`, `position_y`, `position_z` FROM `creature` WHERE `map` = 12175 AND `Comment` = 'MAP12S spirit healer (wreck beach)';
SELECT MAX(`guid`) AS max_guid_after, SUM(`guid` >= @spawn_limit) AS invalid_guids_after FROM `creature`;
