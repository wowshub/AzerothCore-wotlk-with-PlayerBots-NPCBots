-- HARAFOG1 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, WORLD database. Safe to run twice.
-- With sub-area terrain the zone of map 12694 becomes 15355, so the Haranir graveyard needs a link for that zone (the old link stays).
SET NAMES utf8mb4;
DELETE FROM `graveyard_zone` WHERE `ID` = 126941 AND `GhostZone` = 15355;
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES (126941, 15355, 0, 'Haranir start, zone 15355 (HARAFOG1)');
SELECT (SELECT COUNT(*) FROM `graveyard_zone` WHERE `ID` = 126941) AS links_must_be_2,
       (SELECT COUNT(*) FROM `game_graveyard` WHERE `ID` = 126941) AS graveyard_must_be_1;
