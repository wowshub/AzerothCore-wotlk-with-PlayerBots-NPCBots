-- DARK3A V1 (2026-11-25, Claude) - candidate, NOT user-tested. Builds on DARK2A/2B/2C (templates 157300/156814/156501/167663/9159801-3 must exist).
-- User-supplied coordinates inside the dungeon interior of THIS map (the interior is not at the retail map-2236 coordinates):
--   entrance  855.40 -1384.25 176.63 (o 3.72)   = where accepting 59984 sends you (Dark2A.lua)
--   boss 1    753.35 -1441.73 176.63 (o 0.60)   = Tunk        (assumed: lowest floor first)
--   boss 2    852.47 -1625.35 219.04 (o 1.91)   = Gor'groth
--   boss 3    753.59 -1439.72 272.74 (o 0.40)   = Kalecgos on the top platform (spawned by the script after boss 1 and 2 are dead)
-- Static spawns: Tunk, Gor'groth, a few guards beside them, one Spirit Healer + graveyard at the entrance. Guards stand 4-5 yards from the bosses on the same floor.
-- Safe to run twice. Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'DARK3A %';
DELETE FROM `graveyard_zone` WHERE `ID` = 117509;
DELETE FROM `game_graveyard` WHERE `ID` = 117509;
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 20 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;
SELECT COUNT(*) AS dark2a_templates_must_be_7 FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501, 167663, 9159801, 9159802, 9159803);
SELECT COUNT(*) AS spirit_healer_template_6491_must_be_1 FROM `creature_template` WHERE `entry` = 6491;

INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 157300, 12175, 1, 1, 0, 753.35, -1441.73, 176.63, 0.60, 600, 0, 0, 'DARK3A Tunk (boss 1)'),
(@g + 2, 9159801, 12175, 1, 1, 0, 757.0, -1445.5, 176.63, 0.60, 300, 0, 0, 'DARK3A centurion at boss 1'),
(@g + 3, 9159802, 12175, 1, 1, 0, 749.5, -1437.5, 176.63, 0.60, 300, 0, 0, 'DARK3A shadowcaller at boss 1'),
(@g + 4, 156814, 12175, 1, 1, 0, 852.47, -1625.35, 219.04, 1.91, 600, 0, 0, 'DARK3A Gor''groth (boss 2)'),
(@g + 5, 9159801, 12175, 1, 1, 0, 856.0, -1629.5, 219.04, 1.91, 300, 0, 0, 'DARK3A centurion at boss 2'),
(@g + 6, 9159801, 12175, 1, 1, 0, 848.5, -1629.5, 219.04, 1.91, 300, 0, 0, 'DARK3A centurion at boss 2'),
(@g + 7, 9159803, 12175, 1, 1, 0, 852.5, -1620.5, 219.04, 1.91, 300, 0, 0, 'DARK3A channeler at boss 2'),
(@g + 8, 9159803, 12175, 1, 1, 0, 757.0, -1443.5, 272.74, 0.40, 300, 0, 0, 'DARK3A channeler at the platform'),
(@g + 9, 9159803, 12175, 1, 1, 0, 750.0, -1436.0, 272.74, 0.40, 300, 0, 0, 'DARK3A channeler at the platform'),
(@g + 10, 6491, 12175, 1, 1, 0, 854.0, -1387.0, 176.63, 3.72, 300, 0, 0, 'DARK3A spirit healer at the entrance');

INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES
(117509, 12175, 855.4, -1384.25, 176.63, 'Exile''s Reach - Darkmaul Citadel entrance (DARK3A)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES
(117509, 12175, 0, 'Darkmaul Citadel entrance, both factions (DARK3A)');

-- 59984 text and map markers now point at the dungeon interior
UPDATE `quest_template` SET `QuestDescription` = 'Gor''groth seeks to use shadow magic to gain control of Kalecgos, the aspect of the Blue Dragonflight.$B$BHe''s collected enough life essence to attempt to finish the ritual. I do not know what will happen, but we cannot let him complete it!$B$BGor''groth will not stop until he is slain!$B$BYou must storm the citadel and slay Gor''groth before he can complete his ritual!$B$BI would charge in beside you, were I not still recovering from his dark magic.$B$B(Accepting this quest takes you to the entrance of the citadel interior. Defeat Tunk and Gor''groth, fighting your way inward. Then Kalecgos, bound by the ritual, appears on the top platform. When he falls you are brought back here. 接任务后你会被传送到要塞内部入口。一路向里击败图克和戈尔格罗斯，之后被仪式控制的卡雷苟斯会出现在最高处的平台，击败他后你会被送回这里。)$B$B戈尔格罗斯想用暗影魔法控制蓝龙军团的守护巨龙卡雷苟斯。$B$B他已经收集了足够的生命精华，打算完成仪式。我不知道会发生什么，但绝不能让他得逞！$B$B戈尔格罗斯不死不会罢休！$B$B你必须强攻要塞，在他完成仪式前杀掉戈尔格罗斯！$B$B我本想和你并肩冲锋，可惜我还没从他的黑暗魔法中恢复过来。' WHERE `ID` = 59984;
DELETE FROM `quest_poi_points` WHERE `QuestID` = 59984;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(59984, 0, 0, 703, -1888, 0), (59984, 0, 1, 721, -1888, 0), (59984, 0, 2, 721, -1870, 0), (59984, 0, 3, 703, -1870, 0),
(59984, 1, 0, 744, -1451, 0), (59984, 1, 1, 762, -1451, 0), (59984, 1, 2, 762, -1433, 0), (59984, 1, 3, 744, -1433, 0),
(59984, 2, 0, 843, -1634, 0), (59984, 2, 1, 861, -1634, 0), (59984, 2, 2, 861, -1616, 0), (59984, 2, 3, 843, -1616, 0),
(59984, 3, 0, 744, -1449, 0), (59984, 3, 1, 762, -1449, 0), (59984, 3, 2, 762, -1431, 0), (59984, 3, 3, 744, -1431, 0),
(59984, 4, 0, 700, -1893, 0), (59984, 4, 1, 718, -1893, 0), (59984, 4, 2, 718, -1875, 0), (59984, 4, 3, 700, -1875, 0);

SELECT (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'DARK3A %') AS spawns_must_be_10,
       (SELECT COUNT(*) FROM `game_graveyard` WHERE `ID` = 117509) AS graveyard_must_be_1,
       (SELECT COUNT(*) FROM `quest_poi_points` WHERE `QuestID` = 59984) AS poi_points_must_be_20;
