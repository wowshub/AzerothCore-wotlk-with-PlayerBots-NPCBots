-- BRANCH1A V1 (2026-11-25, Claude) - candidate, NOT user-tested.
-- Two optional Exile's Reach side quests, retail ids kept (data: LoreWalkerTDB 12.x, rebuilt for AC 3.3.5, map 12175):
--   56839 Killclaw the Terrible: Danger Sign (go 330627) starts it, kill the elite bear Killclaw (153266), turn in at the Hidden Treasure Chest (go 9326800).
--   54933 Freeing the Light: Lightspawn (157114) starts/ends it, click the four Ritual Pedestals (go 9326716..9326719). Retail has NO summoned fight in this
--   quest; its reward is a blessing spell (retail 306396, here stock Blessing of Kings 20217).
-- Needs HARPY1C V4 applied first (the totem row 9350803 is the template of the click objects). Safe to run twice. Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'BRANCH1A %';
DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'BRANCH1A %';
DELETE FROM `creature_template` WHERE `entry` IN (153266, 157114);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (153266, 157114);
DELETE FROM `gameobject_template` WHERE `entry` IN (330627, 9326800, 9326716, 9326717, 9326718, 9326719);
DELETE FROM `quest_template` WHERE `ID` IN (54933, 56839);
DELETE FROM `quest_template_addon` WHERE `ID` IN (54933, 56839);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (54933, 56839);
DELETE FROM `quest_request_items` WHERE `ID` IN (54933, 56839);
DELETE FROM `creature_queststarter` WHERE `quest` IN (54933, 56839);
DELETE FROM `creature_questender` WHERE `quest` IN (54933, 56839);
DELETE FROM `gameobject_queststarter` WHERE `quest` IN (54933, 56839);
DELETE FROM `gameobject_questender` WHERE `quest` IN (54933, 56839);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (54933, 56839);
DELETE FROM `quest_poi` WHERE `QuestID` IN (54933, 56839);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 5 + 10000 < @spawn_limit AND @o + 10 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max, @o AS go_max;
SELECT COUNT(*) AS totem_row_9350803_must_be_1 FROM `gameobject_template` WHERE `entry` = 9350803;

-- ===== creatures: Killclaw = stock bear model 902 x2.1 (retail model 97258 not in the client); Lightspawn = spirit-healer model 5233 (retail 70162 not in the client) =====
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(153266, 'Killclaw the Terrible 可怕的杀爪', NULL, 9, 9, 14, 0, 1, 1.14286, 1, 1, 0, 1, '', 6, 0.9, 1, 0, ''),
(157114, 'Lightspawn 光明之灵', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 4, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(153266, 0, 902, 2.1, 1, 0),
(157114, 0, 5233, 1.3, 1, 0);

-- ===== game objects =====
-- quest-giver objects (type 2): clone of the totem row with every Data field cleared; sign = wooden wanted board 202, chest = treasure chest 259
DROP TEMPORARY TABLE IF EXISTS tmp_br;
CREATE TEMPORARY TABLE tmp_br AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_br SET `entry` = 330627, `type` = 2, `displayId` = 202, `name` = 'Danger Sign 危险告示牌', `IconName` = '', `castBarCaption` = '', `size` = 1,
  `Data0` = 0, `Data1` = 0, `Data2` = 0, `Data3` = 0, `Data4` = 0, `Data5` = 0, `Data6` = 0, `Data7` = 0, `Data8` = 0, `Data9` = 0, `Data10` = 0, `Data11` = 0, `Data12` = 0, `Data13` = 0;
INSERT INTO `gameobject_template` SELECT * FROM tmp_br;
UPDATE tmp_br SET `entry` = 9326800, `displayId` = 259, `name` = 'Hidden Treasure Chest 隐藏的宝箱', `size` = 1;
INSERT INTO `gameobject_template` SELECT * FROM tmp_br;
DROP TEMPORARY TABLE tmp_br;
-- click objects (goober, cursor 'Cast', consumable): four Ritual Pedestals, stock blue rune model 7658 (retail 56588 not in the client)
DROP TEMPORARY TABLE IF EXISTS tmp_ped;
CREATE TEMPORARY TABLE tmp_ped AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_ped SET `entry` = 9326716, `displayId` = 7658, `name` = 'Ritual Pedestal 仪式基座', `castBarCaption` = 'Dispersing 驱散中', `size` = 1.6, `Data1` = 54933;
INSERT INTO `gameobject_template` SELECT * FROM tmp_ped;
UPDATE tmp_ped SET `entry` = 9326717;
INSERT INTO `gameobject_template` SELECT * FROM tmp_ped;
UPDATE tmp_ped SET `entry` = 9326718;
INSERT INTO `gameobject_template` SELECT * FROM tmp_ped;
UPDATE tmp_ped SET `entry` = 9326719;
INSERT INTO `gameobject_template` SELECT * FROM tmp_ped;
DROP TEMPORARY TABLE tmp_ped;

-- ===== quests =====
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `RewardSpell`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES
(56839, 2, 1, 1, 7, 0, 0, 'Killclaw the Terrible / 可怕的杀爪', 'Defeat Killclaw the Terrible. / 击败可怕的杀爪。',
 '<You see a crude sign made by the ogres. It contains a warning.>$B$BBIG bear! Bad!$B$BBig bear guard big ogre treasure!$B$BKill after ritual! Get treasure, make more power!$B$B<你看到食人魔做的一块粗糙的牌子，上面是一条警告。>$B$B大熊！坏！$B$B大熊守着食人魔的大宝藏！$B$B仪式之后再杀！拿宝藏，变更强！',
 'Look for the treasure within Killclaw''s cave. / 到杀爪的洞穴里找宝藏。', ''),
(54933, 2, 1, 1, 1, 20217, 0, 'Freeing the Light / 解放光明', 'Use the Lightspawn''s light to dispel nearby shadow energy. / 用光明之灵的光芒驱散附近的暗影能量。',
 'Ah... you are not in league with the ogres. Please, you must aid me.$B$BI have been bound against my will by dark magic. I ask only that you free me.$B$BTake a piece of my light. Use it to dispel the shadow energies that are keeping me captive.$B$B啊……你不是和食人魔一伙的。请你帮帮我。$B$B我被黑暗魔法违背意愿地束缚住了。我只求你放我自由。$B$B拿走我的一片光芒，用它驱散囚禁我的暗影能量。',
 'Return to the Lightspawn. / 回到光明之灵那里。', '');
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 153266, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Killclaw the Terrible slain / 可怕的杀爪已被击杀' WHERE `ID` = 56839;
UPDATE `quest_template` SET
  `RequiredNpcOrGo1` = -9326716, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'First necrotic energy dispersed / 第一处死灵能量已驱散',
  `RequiredNpcOrGo2` = -9326717, `RequiredNpcOrGoCount2` = 1, `ObjectiveText2` = 'Second necrotic energy dispersed / 第二处死灵能量已驱散',
  `RequiredNpcOrGo3` = -9326718, `RequiredNpcOrGoCount3` = 1, `ObjectiveText3` = 'Third necrotic energy dispersed / 第三处死灵能量已驱散',
  `RequiredNpcOrGo4` = -9326719, `RequiredNpcOrGoCount4` = 1, `ObjectiveText4` = 'Fourth necrotic energy dispersed / 第四处死灵能量已驱散'
WHERE `ID` = 54933;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (56839, 0, 0), (54933, 0, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES
(56839, 1, 0, 0, 0, '<You find a cache of treasure, just like the ogres'' sign mentioned!>$B$B<你找到了一堆宝藏，正如食人魔的牌子所说！>', 0),
(54933, 1, 0, 0, 0, 'You have my thanks, $n. I must leave this world, but I wish you luck.$B$BTake my blessing. May it aid you against these monsters.$B$B谢谢你，$n。我必须离开这个世界了，祝你好运。$B$B收下我的祝福，愿它助你对抗这些怪物。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(56839, 0, 0, 'The bear still lives?$B$B熊还活着吗？', 0),
(54933, 0, 0, 'Please, free me from the shadow.$B$B求你，让我从暗影中解脱。', 0);
INSERT INTO `gameobject_queststarter` (`id`, `quest`) VALUES (330627, 56839);
INSERT INTO `gameobject_questender` (`id`, `quest`) VALUES (9326800, 56839);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (157114, 54933);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (157114, 54933);

-- ===== spawns (retail positions) =====
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 153266, 12175, 1, 1, 0, 235.846, -2022.37, 79.841, 3.55125, 300, 0, 0, 'BRANCH1A Killclaw'),
(@g + 2, 157114, 12175, 1, 1, 0, 301.391, -2486.31, 115.183, 1.60837, 120, 0, 0, 'BRANCH1A Lightspawn');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(@o + 1, 330627, 12175, 1, 1, 211.542, -2166.91, 92.5237, 4.0429, 0, 0, 0, 1, 120, 255, 1, 'BRANCH1A danger sign'),
(@o + 2, 9326800, 12175, 1, 1, 277.528, -1985.94, 77.6296, 3.99775, 0, 0, 0, 1, 60, 255, 1, 'BRANCH1A treasure chest'),
(@o + 3, 9326716, 12175, 1, 1, 313.165, -2460.54, 116.833, 0, 0, 0, 0, 1, 60, 255, 1, 'BRANCH1A pedestal'),
(@o + 4, 9326717, 12175, 1, 1, 325.092, -2496.61, 116.566, 0, 0, 0, 0, 1, 60, 255, 1, 'BRANCH1A pedestal'),
(@o + 5, 9326718, 12175, 1, 1, 290.399, -2514.1, 116.646, 0, 0, 0, 0, 1, 60, 255, 1, 'BRANCH1A pedestal'),
(@o + 6, 9326719, 12175, 1, 1, 278.943, -2473.46, 116.466, 0, 0, 0, 0, 1, 60, 255, 1, 'BRANCH1A pedestal');

-- ===== quest map markers (4-corner squares +-9 around the retail points; ObjectiveIndex 0-based, -1 = turn-in) =====
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(56839, 0, -1, 12175, 20414, 0, 0, 1, 0),
(56839, 1, 0, 12175, 20414, 0, 0, 1, 0),
(54933, 0, -1, 12175, 20414, 0, 0, 1, 0),
(54933, 1, 0, 12175, 20414, 0, 0, 1, 0),
(54933, 2, 1, 12175, 20414, 0, 0, 1, 0),
(54933, 3, 2, 12175, 20414, 0, 0, 1, 0),
(54933, 4, 3, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(56839, 0, 0, 268, -1995, 0), (56839, 0, 1, 286, -1995, 0), (56839, 0, 2, 286, -1977, 0), (56839, 0, 3, 268, -1977, 0),
(56839, 1, 0, 226, -2031, 0), (56839, 1, 1, 245, -2031, 0), (56839, 1, 2, 245, -2013, 0), (56839, 1, 3, 226, -2013, 0),
(54933, 0, 0, 292, -2495, 0), (54933, 0, 1, 310, -2495, 0), (54933, 0, 2, 310, -2477, 0), (54933, 0, 3, 292, -2477, 0),
(54933, 1, 0, 304, -2470, 0), (54933, 1, 1, 322, -2470, 0), (54933, 1, 2, 322, -2452, 0), (54933, 1, 3, 304, -2452, 0),
(54933, 2, 0, 316, -2506, 0), (54933, 2, 1, 334, -2506, 0), (54933, 2, 2, 334, -2488, 0), (54933, 2, 3, 316, -2488, 0),
(54933, 3, 0, 281, -2523, 0), (54933, 3, 1, 299, -2523, 0), (54933, 3, 2, 299, -2505, 0), (54933, 3, 3, 281, -2505, 0),
(54933, 4, 0, 270, -2482, 0), (54933, 4, 1, 288, -2482, 0), (54933, 4, 2, 288, -2464, 0), (54933, 4, 3, 270, -2464, 0);

-- read-back
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (54933, 56839)) AS quests_must_be_2,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'BRANCH1A %') AS creatures_must_be_2,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'BRANCH1A %') AS objects_must_be_6,
       (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` IN (330627, 9326800, 9326716, 9326717, 9326718, 9326719)) AS go_templates_must_be_6,
       (SELECT CONCAT(`type`, '/', `displayId`) FROM `gameobject_template` WHERE `entry` = 330627) AS sign_must_be_2_slash_202,
       (SELECT CONCAT(`IconName`, '/', `Data5`) FROM `gameobject_template` WHERE `entry` = 9326716) AS pedestal_must_be_Cast_slash_1,
       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (54933, 56839)) AS poi_must_be_7;
