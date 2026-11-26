-- PIT1A V1 (2026-11-25, Claude) - candidate, NOT user-tested.
-- Exile's Reach Horde chain after 59947: 59948 Westward Bound (Lana Jordan) -> 59949 Who Lurks in the Pit
--   (free 5 trapped expedition members from cocoons, defeat Hrun the Exiled, ride Crenna Earth-Daughter out of the pit; turn in to Thrall).
-- Data from LoreWalkerTDB (12.x) rebuilt for AC 3.3.5, map 12175. Includes the quest map markers (quest_poi) of both quests.
-- Simplified vs retail: no phasing, no cutscene scripts for Lana; the cocoon is a click object that vanishes (cloned from the verified totem 9350803,
--   needs HARPY1C V4 applied first); Hrun yields at low health (Pit1A.lua); Crenna's escape is a taxi flight (Pit1A.lua), not a vehicle.
-- Safe to run twice. guids = live legal maximum + 1 (must stay below 16777215). Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'PIT1A %';
DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'PIT1A %';
DELETE FROM `creature_template` WHERE `entry` IN (167221, 167225, 156900, 167254);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (167221, 167225, 156900, 167254);
DELETE FROM `gameobject_template` WHERE `entry` = 9350796;
DELETE FROM `quest_template` WHERE `ID` IN (59948, 59949);
DELETE FROM `quest_template_addon` WHERE `ID` IN (59948, 59949);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (59948, 59949);
DELETE FROM `quest_request_items` WHERE `ID` IN (59948, 59949);
DELETE FROM `creature_queststarter` WHERE `quest` IN (59948, 59949);
DELETE FROM `creature_questender` WHERE `quest` IN (59948, 59949);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (59948, 59949);
DELETE FROM `quest_poi` WHERE `QuestID` IN (59948, 59949);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 10 + 10000 < @spawn_limit AND @o + 10 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max, @o AS go_max;
SELECT COUNT(*) AS totem_row_9350803_must_be_1 FROM `gameobject_template` WHERE `entry` = 9350803;

-- ===== creature templates =====
-- models: Lana = the display of the wounded Lana (BEACH1A, 15516); Hrun = ogre 11567 x1.2; Crenna = stock Tauren female (Aponi Brightmane's display 29249)
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(167221, 'Lana Jordan 拉娜·乔丹', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167225, 'Lana Jordan 拉娜·乔丹', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(156900, 'Hrun the Exiled 被放逐者赫鲁恩', NULL, 6, 6, 14, 0, 1, 1.14286, 1, 1, 0, 7, '', 4, 0.6, 1, 0, ''),
(167254, 'Crenna Earth-Daughter 克蕾娜·大地之女', NULL, 1, 1, 35, 1, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(167221, 0, 15516, 1, 1, 0),
(167225, 0, 15516, 1, 1, 0),
(156900, 0, 11567, 1.2, 1, 0),
(167254, 0, 29249, 1, 1, 0);

-- ===== cocoon (click object): exact clone of the totem row 9350803 (cursor 'Cast', consumable), cocoon model 7657, quest 59949 =====
DROP TEMPORARY TABLE IF EXISTS tmp_cocoon;
CREATE TEMPORARY TABLE tmp_cocoon AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_cocoon SET `entry` = 9350796, `displayId` = 7657, `name` = 'Thick Cocoon 厚茧', `castBarCaption` = 'Freeing 解救中', `size` = 1, `Data1` = 59949;
INSERT INTO `gameobject_template` SELECT * FROM tmp_cocoon;
DROP TEMPORARY TABLE tmp_cocoon;

-- ===== quests =====
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES
(59948, 2, 1, 1, 3, 0, 'Westward Bound / 向西前进', 'Meet Lana Jordan west of the Horde Camp. / 在部落营地以西与拉娜·乔丹会合。',
 'Thrall wants us to search west of here for the site of the next ritual.$B$BWe could use your help. I''ve already died once. It''s not an experience I''d care to repeat.$B$B萨尔想让我们去这里以西搜寻下一场仪式的地点。$B$B我们需要你的帮助。我已经死过一次了，那种经历我可不想再来一次。',
 'Meet Lana Jordan west of the Horde Camp. / 在部落营地以西与拉娜·乔丹会合。', ''),
(59949, 2, 1, 1, 6, 0, 'Who Lurks in the Pit / 深坑里的潜伏者', 'Rescue 5 Trapped Expedition Members. / 解救5名被困的远征队成员。',
 'There''s a whole lot of shadow energy coming from this pit. I''m guessing a ritual is being performed down there. And that means a sacrifice.$B$BDo you hear that? I''ve got the best hearing around, ever since I got this new ear sewn onto me.$B$BIt sounds like there are some more of our soldiers trapped down there. Probably all webbed up.$B$BWon''sa and I will... stay up here and help anyone who gets out.$B$BYou should jump in and rescue anyone who is left down there!$B$B这个深坑里涌出大量暗影能量。我猜下面正在举行仪式，那就意味着要有祭品。$B$B你听见了吗？自从缝上这只新耳朵，我的听力可是天下第一。$B$B听起来下面还困着我们的一些士兵，多半被蛛网裹住了。$B$B我和温萨……就留在上面，接应逃出来的人。$B$B你该跳下去，救出下面所有还活着的人！',
 'Report back to Warleader Breka. / 向战争领袖布蕾卡复命。', '');
UPDATE `quest_template` SET `RequiredNpcOrGo1` = -9350796, `RequiredNpcOrGoCount1` = 5, `ObjectiveText1` = 'Trapped Expedition Members rescued from cocoons / 从茧中解救的被困远征队成员',
  `RequiredNpcOrGo2` = 156900, `RequiredNpcOrGoCount2` = 1, `ObjectiveText2` = 'Defeat Hrun to rescue Crenna Earth-Daughter / 击败赫鲁恩，解救克蕾娜·大地之女',
  `RequiredNpcOrGo3` = 167254, `RequiredNpcOrGoCount3` = 1, `ObjectiveText3` = 'Ride Crenna Earth-Daughter to escape / 骑乘克蕾娜·大地之女逃出深坑'
WHERE `ID` = 59949;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (59948, 59947, 59949), (59949, 59948, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES
(59948, 1, 0, 0, 0, 'Lana: There you are. Look at that pit. Nothing good lives down there.$B$B拉娜：你来了。看看那个深坑，下面可没有什么好东西。', 0),
(59949, 1, 0, 0, 0, 'Thrall: You freed our people and survived the pit. The Horde owes you.$B$B萨尔：你救出了我们的人，还从深坑里活着出来了。部落欠你一份情。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(59948, 0, 0, 'Over here.$B$B这边。', 0),
(59949, 0, 0, 'Free them all, then get out of there.$B$B把他们都救出来，然后赶紧出来。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (167221, 59948), (167225, 59949);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (167225, 59948), (167212, 59949);

-- ===== spawns (retail positions) =====
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 167221, 12175, 1, 1, 0, 178.824, -2282.03, 81.8485, 5.1867, 120, 0, 0, 'PIT1A Lana camp'),
(@g + 2, 167225, 12175, 1, 1, 0, 89.8073, -2251.8, 95.1326, 1.82236, 120, 0, 0, 'PIT1A Lana pit rim'),
(@g + 3, 156900, 12175, 1, 1, 0, 68.2663, -2123.14, -30.2449, 5.66247, 300, 0, 0, 'PIT1A Hrun'),
(@g + 4, 167254, 12175, 1, 1, 0, 73.1613, -2127.24, -29.6948, 4.98427, 120, 0, 0, 'PIT1A Crenna');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(@o + 1, 9350796, 12175, 1, 1, 72.9353, -2183.72, 23.7982, 0, 0, 0, 0, 1, 60, 255, 1, 'PIT1A cocoon'),
(@o + 2, 9350796, 12175, 1, 1, 123.301, -2237.83, -5.8769, 0, 0, 0, 0, 1, 60, 255, 1, 'PIT1A cocoon'),
(@o + 3, 9350796, 12175, 1, 1, 64.7351, -2276.11, -0.592913, 0, 0, 0, 0, 1, 60, 255, 1, 'PIT1A cocoon'),
(@o + 4, 9350796, 12175, 1, 1, 36.3941, -2190.78, 19.3433, 0, 0, 0, 0, 1, 60, 255, 1, 'PIT1A cocoon'),
(@o + 5, 9350796, 12175, 1, 1, 109.15, -2223.37, 33.1916, 0, 0, 0, 0, 1, 60, 255, 1, 'PIT1A cocoon');

-- ===== quest map markers (retail quest_poi_points; map 12175, WorldMapArea 20414). ObjectiveIndex is 0-based, -1 = turn-in =====
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(59948, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59949, 0, 0, 12175, 20414, 0, 0, 1, 0),
(59949, 1, 1, 12175, 20414, 0, 0, 1, 0),
(59949, 2, 2, 12175, 20414, 0, 0, 1, 0),
(59949, 3, -1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(59948, 0, 0, 96, -2260, 0), (59948, 0, 1, 114, -2260, 0), (59948, 0, 2, 114, -2242, 0), (59948, 0, 3, 96, -2242, 0),
(59949, 0, 0, 79, -2280, 0), (59949, 0, 1, 123, -2239, 0), (59949, 0, 2, 110, -2218, 0), (59949, 0, 3, 35, -2199, 0), (59949, 0, 4, 64, -2277, 0),
(59949, 1, 0, 60, -2131, 0), (59949, 1, 1, 78, -2131, 0), (59949, 1, 2, 78, -2113, 0), (59949, 1, 3, 60, -2113, 0),
(59949, 2, 0, 65, -2143, 0), (59949, 2, 1, 83, -2143, 0), (59949, 2, 2, 83, -2125, 0), (59949, 2, 3, 65, -2125, 0),
(59949, 3, 0, 176, -2292, 0), (59949, 3, 1, 194, -2292, 0), (59949, 3, 2, 194, -2274, 0), (59949, 3, 3, 176, -2274, 0);

-- read-back
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (59948, 59949)) AS quests_must_be_2,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'PIT1A %') AS creatures_must_be_4,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'PIT1A %') AS cocoons_must_be_5,
       (SELECT `IconName` FROM `gameobject_template` WHERE `entry` = 9350796) AS cursor_must_be_Cast,
       (SELECT `Data5` FROM `gameobject_template` WHERE `entry` = 9350796) AS consumable_must_be_1,
       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (59948, 59949)) AS poi_must_be_5,
       (SELECT COUNT(*) FROM `quest_poi_points` WHERE `QuestID` IN (59948, 59949)) AS points_must_be_21;
