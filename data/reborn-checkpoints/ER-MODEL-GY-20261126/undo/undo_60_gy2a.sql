-- GY2A V1 undo: removes only the courtyard graveyard. Stop worldserver, run, restart.
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'GY2A %';
DELETE FROM `graveyard_zone` WHERE `ID` = 117510;
DELETE FROM `game_graveyard` WHERE `ID` = 117510;
-- To also remove the seven GY1A graveyards (only if they were NOT present before: first readback was 0), run the GY1A V1 undo.sql.
