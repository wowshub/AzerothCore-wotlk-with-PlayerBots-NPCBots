-- HLBG1A: removes everything 01..04 added (battleground template, graveyards, battlemaster, NPC templates, spawns).
DELETE FROM `gameobject` WHERE `guid` BETWEEN 16200000 AND 16200421 AND `map` = 20411;
DELETE FROM `waypoint_data` WHERE `id` BETWEEN 895000000 AND 895000009;
DELETE FROM `creature_addon` WHERE `guid` BETWEEN 16000000 AND 16000155;
DELETE FROM `creature` WHERE `guid` BETWEEN 16000000 AND 16000155 AND `map` = 20411;
DELETE FROM `battlemaster_entry` WHERE `entry` = 900001;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 900001;
DELETE FROM `creature_template` WHERE `entry` = 900001;
DELETE FROM `game_graveyard` WHERE `ID` IN (1721, 1722);
DELETE FROM `battleground_template` WHERE `ID` = 20;
-- creature templates 600004-600011 / 810000-810023 are NOT removed here: check first that nothing else uses them.
