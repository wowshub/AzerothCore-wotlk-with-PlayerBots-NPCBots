-- MAPSRV2A V1 undo (world database).
DELETE FROM `creature` WHERE `Comment` LIKE 'MAPSRV2A %';
DELETE FROM `graveyard_zone` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_graveyard` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_tele` WHERE `name` IN ('Dracthyr', 'Haranir');
