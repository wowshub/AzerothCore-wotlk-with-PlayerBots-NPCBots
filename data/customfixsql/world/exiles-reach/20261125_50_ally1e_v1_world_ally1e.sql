-- ALLY1E V1 (2026-11-25, Claude): Alliance 55194 -> 55965 -> 55639 -> 56344, cloned from the Horde 59950 / PIT1A-1D.
-- Needs PIT1A/PIT1B/PIT1D, ALLY1D and MODEL1A. Safe to run twice. Keep worldserver stopped.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1E %';
DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1E %';
SELECT (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` = 9350796) AS horde_cocoon_must_be_1,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (156900, 9167011)) AS hrun_and_mount_must_be_2,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` IN (1628, 3270, 1612, 1992, 710006)) AS model_info_must_be_5,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 9167001) AS horde_vendor_items;
DELETE FROM `creature_template` WHERE `entry` IN (154300, 156891, 156803, 156800, 156929, 156941, 9167012);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (154300, 156891, 156803, 156800, 156929, 156941, 9167012);
DELETE FROM `npc_vendor` WHERE `entry` = 156800;
DELETE FROM `quest_template` WHERE `ID` IN (55194, 55965, 55639, 56344);
DELETE FROM `quest_template_addon` WHERE `ID` IN (55194, 55965, 55639, 56344);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (55194, 55965, 55639, 56344);
DELETE FROM `quest_request_items` WHERE `ID` IN (55194, 55965, 55639, 56344);
DELETE FROM `creature_queststarter` WHERE `quest` IN (55194, 55965, 55639, 56344);
DELETE FROM `creature_questender` WHERE `quest` IN (55194, 55965, 55639, 56344);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (55194, 55965, 55639, 56344);
DELETE FROM `quest_poi` WHERE `QuestID` IN (55194, 55965, 55639, 56344);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 100 + 10000 < @spawn_limit AND @o + 100 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (154300, 'Bjorn Stouthands 比约恩·石手', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (154300, 0, 1628, 1, 1, 0);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (156891, 'Bjorn Stouthands 比约恩·石手', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156891, 0, 1628, 1, 1, 0);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (156803, 'Alaria 阿拉莉亚', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156803, 0, 3270, 1, 1, 0);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (156800, 'Quartermaster Richter 军需官里希特', NULL, 1, 1, 35, 129, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156800, 0, 1612, 1, 1, 0);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (156929, 'Ralia Dreamchaser 拉莉亚·追梦者', NULL, 1, 1, 35, 1, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156929, 0, 1992, 1, 1, 0);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (156941, 'Lady Jaina Proudmoore 吉安娜·普罗德摩尔', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156941, 0, 710006, 1, 1, 0);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) SELECT 156800, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild` FROM `npc_vendor` WHERE `entry` = 9167001;
-- escape mount: copy of the Horde mount creature, model changed later by the optional model package
DROP TEMPORARY TABLE IF EXISTS tmp_mount_a;
CREATE TEMPORARY TABLE tmp_mount_a AS SELECT * FROM `creature_template` WHERE `entry` = 9167011;
UPDATE tmp_mount_a SET `entry` = 9167012, `name` = 'Ralia''s Stag 拉莉亚的雄鹿';
INSERT INTO `creature_template` SELECT * FROM tmp_mount_a;
DROP TEMPORARY TABLE tmp_mount_a;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9167012, 0, 1992, 1.2, 1, 0);
-- Alliance cocoon: same row as the Horde cocoon, only the quest (Data1) differs
DELETE FROM `gameobject_template` WHERE `entry` = 9350797;
DROP TEMPORARY TABLE IF EXISTS tmp_cocoon_a;
CREATE TEMPORARY TABLE tmp_cocoon_a AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350796;
UPDATE tmp_cocoon_a SET `entry` = 9350797, `Data1` = 55639;
INSERT INTO `gameobject_template` SELECT * FROM tmp_cocoon_a;
DROP TEMPORARY TABLE tmp_cocoon_a;
-- phases: Horde cocoons 1, Alliance cocoons 2; Hrun and the spiders shared 3
UPDATE `gameobject` SET `phaseMask` = 1 WHERE `map` = 12175 AND `id` = 9350796;
UPDATE `creature` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id1` IN (156900, 160394, 160433);
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 1, 154300, 12175, 1, 2, 0, 184.972, -2292.13, 81.7709, 1.90291, 120, 0, 0, 'ALLY1E Bjorn camp');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 2, 156800, 12175, 1, 2, 0, 178.518, -2291.15, 81.8501, 0.869839, 120, 0, 0, 'ALLY1E Richter camp');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 3, 156891, 12175, 1, 2, 0, 89.7534, -2249.43, 94.7218, 1.8747, 120, 0, 0, 'ALLY1E Bjorn pit rim');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 4, 156803, 12175, 1, 2, 0, 91.9826, -2246.83, 94.4823, 2.02451, 120, 0, 0, 'ALLY1E Alaria pit rim');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 5, 156929, 12175, 1, 2, 0, 73.1613, -2127.24, -29.6948, 4.98427, 120, 0, 0, 'ALLY1E Ralia pit bottom');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 6, 156941, 12175, 1, 2, 0, 323.295, -2179.64, 106.099, 2.52876, 120, 0, 0, 'ALLY1E Jaina Darkmaul');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES (@o + 1, 9350797, 12175, 1, 2, 72.9353, -2183.72, 23.7982, 0, 0, 0, 0, 1, 60, 255, 1, 'ALLY1E cocoon');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES (@o + 2, 9350797, 12175, 1, 2, 123.301, -2237.83, -5.8769, 0, 0, 0, 0, 1, 60, 255, 1, 'ALLY1E cocoon');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES (@o + 3, 9350797, 12175, 1, 2, 64.7351, -2276.11, -0.592913, 0, 0, 0, 0, 1, 60, 255, 1, 'ALLY1E cocoon');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES (@o + 4, 9350797, 12175, 1, 2, 36.3941, -2190.78, 19.3433, 0, 0, 0, 0, 1, 60, 255, 1, 'ALLY1E cocoon');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES (@o + 5, 9350797, 12175, 1, 2, 109.15, -2223.37, 33.1916, 0, 0, 0, 0, 1, 60, 255, 1, 'ALLY1E cocoon');
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`, `RewardItem1`, `RewardAmount1`) VALUES (55194, 2, 1, 1, 4, 0, 'Stocking Up on Supplies / 补充补给', 'Speak with Quartermaster Richter and look at her wares. / 与军需官里希特交谈，看看她的货物。', 'Quartermaster Richter was able to scavenge supplies from the wreckages on this island.$B$BWhy don''t you visit her and see if she has anything that you need?$B$BYou''ll want to be well equipped for whatever we encounter next.$B$B军需官里希特从岛上的残骸里搜集到一些补给。$B$B去看看有没有你需要的东西，接下来遇到什么都得准备充分。', 'Return to Lady Jaina Proudmoore. / 回到吉安娜那里。', '', 4498, 1);
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 156800, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Speak with Quartermaster Richter / 与军需官里希特交谈' WHERE `ID` = 55194;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55194, 55882, 55965);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (55194, 1, 0, 0, 0, 'All stocked up? That''s great.$B$BPrivate Cole and Quartermaster Richter also found this bag in the nearby ruins. They thought you might make good use of it.$B$B补给好了？很好。$B$B科尔列兵和军需官在附近废墟里还找到了这个背包，他们觉得你用得上。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (55194, 0, 0, 'Have you seen the quartermaster?$B$B见过军需官了吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156807, 55194);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156807, 55194);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES (55965, 2, 1, 1, 3, 0, 'Westward Bound / 向西前进', 'Meet Bjorn Stouthands west of the Alliance Camp. / 在联盟营地以西与比约恩·石手会合。', 'Captain Garrick wants us tae search west o'' camp fer any other members of the expedition.$B$BAlaria and I will go on ahead. Meet us tae the west and we''ll see what we can find.$B$B队长要我们到营地西边搜找远征队的其他人。$B$B阿拉莉亚和我先走一步，到西边找我们碰头。', 'Meet Bjorn Stouthands west of the Alliance Camp. / 在营地以西与比约恩会合。', '');
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55965, 55194, 55639);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (55965, 1, 0, 0, 0, 'A giant pit of spiders right on our doorstep! Aren''t we the lucky ones?$B$B家门口就是个蜘蛛大坑！咱们可真走运。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (55965, 0, 0, 'Over here.$B$B这边。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (154300, 55965);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156891, 55965);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES (55639, 2, 1, 1, 6, 0, 'Who Lurks in the Pit / 深坑里的潜伏者', 'Rescue 5 Trapped Expedition Members. / 解救5名被困的远征队成员。', 'The winds whisper of people being trapped in the pit. It seems there may be more members of the expedition within.$B$BI fear it will be up to you to make the descent and save the survivors.$B$BThe winds say one is farther away from the others... With our luck, the last survivor is at the bottom of the pit.$B$BGood luck, $n. And... make sure no spiders follow you back out.$B$B风在低语，说有人困在这深坑里，恐怕远征队还有人在下面。$B$B只能靠你下去救他们了。$B$B风还说有一个人离其他人很远……照咱们的运气，最后那个肯定在坑底。$B$B祝你好运，$n。还有……别让蜘蛛跟着你上来。', 'Report back to Lady Jaina Proudmoore. / 回到营地向吉安娜复命。', '');
UPDATE `quest_template` SET `RequiredNpcOrGo1` = -9350797, `RequiredNpcOrGoCount1` = 5, `ObjectiveText1` = 'Trapped Expedition Members rescued from cocoons / 从茧中解救的被困远征队成员' WHERE `ID` = 55639;
UPDATE `quest_template` SET `RequiredNpcOrGo2` = 156900, `RequiredNpcOrGoCount2` = 1, `ObjectiveText2` = 'Defeat Hrun to rescue Ralia Dreamchaser / 击败赫鲁恩，解救拉莉亚' WHERE `ID` = 55639;
UPDATE `quest_template` SET `RequiredNpcOrGo3` = 156929, `RequiredNpcOrGoCount3` = 1, `ObjectiveText3` = 'Ride Ralia Dreamchaser to escape / 骑乘拉莉亚逃出深坑' WHERE `ID` = 55639;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55639, 55965, 56344);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (55639, 1, 0, 0, 0, 'Ralia Dreamchaser is a druid of the Cenarion Circle, an order dedicated to protecting the wilds of Azeroth.$B$BThank you for rescuing her. Her aid is sure to be of use against the ogres.$B$B拉莉亚·追梦者是塞纳里奥议会的德鲁伊，这个组织致力于守护艾泽拉斯的荒野。$B$B谢谢你救了她，对付食人魔一定用得上她的帮助。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (55639, 0, 0, 'Free them all, then get out of there.$B$B把他们都救出来，然后赶紧出来。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156803, 55639);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156807, 55639);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES (56344, 2, 1, 1, 3, 0, 'To Darkmaul Citadel / 前往暗槌要塞', 'Meet Lady Jaina Proudmoore outside of Darkmaul Citadel. / 在暗槌要塞外与吉安娜会合。', 'We''ve rescued everyone except for the expedition''s captain. Lindie''s Scout-o-Matic spotted her just outside Darkmaul Citadel.$B$BMeredy has come up with an... interesting plan to rescue the captain. It may be our only chance.$B$BCome. We''ll convene in the shadow of Darkmaul Citadel, and there we will begin our rescue mission.$B$B除了远征队的队长，人都救回来了。琳迪的侦察机在暗槌要塞外发现了她。$B$B梅瑞迪想出了一个……挺有意思的营救计划，这也许是唯一的机会。$B$B来吧，我们在暗槌要塞的阴影下集合，从那里开始营救。', 'Meet Jaina outside Darkmaul Citadel. / 到暗槌要塞外与吉安娜会合。', '');
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (56344, 55639, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (56344, 1, 0, 0, 0, 'All right, $n. I hope you''re a good actor, because you''re about to play to a very tough crowd.$B$B好了，$n。希望你演技不错，因为你要面对一群很难糊弄的观众。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (56344, 0, 0, 'You made it.$B$B你到了。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156807, 56344);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156941, 56344);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55194, 0, 0, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 0, 0, 169, -2300, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 0, 1, 187, -2300, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 0, 2, 187, -2282, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 0, 3, 169, -2282, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55194, 1, -1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 1, 0, 177, -2298, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 1, 1, 195, -2298, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 1, 2, 195, -2280, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55194, 1, 3, 177, -2280, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55965, 0, -1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55965, 0, 0, 81, -2258, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55965, 0, 1, 99, -2258, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55965, 0, 2, 99, -2240, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55965, 0, 3, 81, -2240, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55639, 0, 0, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 0, 0, 79, -2280, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 0, 1, 123, -2239, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 0, 2, 110, -2218, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 0, 3, 35, -2199, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 0, 4, 64, -2277, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55639, 1, 1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 1, 0, 60, -2131, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 1, 1, 78, -2131, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 1, 2, 78, -2113, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 1, 3, 60, -2113, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55639, 2, 2, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 2, 0, 65, -2143, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 2, 1, 83, -2143, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 2, 2, 83, -2125, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 2, 3, 65, -2125, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55639, 3, -1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 3, 0, 177, -2298, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 3, 1, 195, -2298, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 3, 2, 195, -2280, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55639, 3, 3, 177, -2280, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (56344, 0, -1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (56344, 0, 0, 314, -2189, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (56344, 0, 1, 332, -2189, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (56344, 0, 2, 332, -2171, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (56344, 0, 3, 314, -2171, 0);
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (55194, 55965, 55639, 56344)) AS quests_4,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1E %') AS npcs_6,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'ALLY1E %') AS cocoons_5,
       (SELECT `Data1` FROM `gameobject_template` WHERE `entry` = 9350797) AS cocoon_quest_55639,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 156800) AS vendor_items,
       (SELECT COUNT(*) FROM `creature_queststarter` WHERE `quest` IN (55194, 55965, 55639, 56344)) AS starters_4,
       (SELECT COUNT(*) FROM `creature_questender` WHERE `quest` IN (55194, 55965, 55639, 56344)) AS enders_4,
       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (55194, 55965, 55639, 56344)) AS poi_8;
