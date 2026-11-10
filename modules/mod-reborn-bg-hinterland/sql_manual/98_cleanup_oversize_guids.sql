-- HLBG1A: URGENT cleanup if you imported an earlier 04 (guids 880000000+/890000000+): the core stops the server with
-- "GameObject spawn id overflow" at startup when a spawn guid is above 16777215. Run this BEFORE starting the server again.
DELETE ca FROM `creature_addon` ca JOIN `creature` c ON c.`guid` = ca.`guid` WHERE c.`map` = 20411;
DELETE FROM `creature` WHERE `map` = 20411;
DELETE FROM `gameobject` WHERE `map` = 20411;
DELETE FROM `waypoint_data` WHERE `id` BETWEEN 895000000 AND 895000009;
-- Check afterwards (both must be 0 / below 16777215):
SELECT COUNT(*) AS rows_on_map_20411_creature FROM `creature` WHERE `map` = 20411;
SELECT MAX(`guid`) AS max_creature_guid FROM `creature`;
SELECT MAX(`guid`) AS max_gameobject_guid FROM `gameobject`;
