-- HLBG1A: battleground template 20 + the two start points (graveyards), map renumbered 1411 -> 20411.
-- Test values: MinPlayersPerTeam 1 so a single tester can start a match; raise to 5-10 for real use.
DELETE FROM `battleground_template` WHERE `ID` = 20;
INSERT INTO `battleground_template` (`ID`, `MinPlayersPerTeam`, `MaxPlayersPerTeam`, `MinLvl`, `MaxLvl`, `AllianceStartLoc`, `AllianceStartO`, `HordeStartLoc`, `HordeStartO`, `StartMaxDist`, `Weight`, `ScriptName`, `Comment`) VALUES
(20, 1, 10, 1, 255, 1721, 3.046, 1722, 1.125, 25, 1, '', 'Hinterland BG');

DELETE FROM `game_graveyard` WHERE `ID` IN (1721, 1722);
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(1721, 20411, 197.165, -4808.544, 7.848, 'Hinterland BG - Alliance Start'),
(1722, 20411, -628.484, -4684.510, 5.144, 'Hinterland BG - Horde Start');