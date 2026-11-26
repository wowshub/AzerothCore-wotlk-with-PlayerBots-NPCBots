-- ALLY1G V1 (2026-11-26, Claude): Alliance 55992 (dungeon) and 55991 (finale, turn-in in Stormwind).
-- Needs the Horde DARK2A/3A/3E/3F SQL and ALLY1F V1. Safe to run twice. Keep worldserver stopped.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
DELETE FROM `creature` WHERE `Comment` LIKE 'ALLY1G %';
SELECT (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501, 244389)) AS bosses_and_credit_4,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (156961, 156965)) AS ally1f_npcs_2,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` IN (26752, 3450)) AS model_info_2;
DELETE FROM `creature_template` WHERE `entry` IN (161350, 154169);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (161350, 154169);
DELETE FROM `quest_template` WHERE `ID` IN (55992, 55991);
DELETE FROM `quest_template_addon` WHERE `ID` IN (55992, 55991);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (55992, 55991);
DELETE FROM `quest_request_items` WHERE `ID` IN (55992, 55991);
DELETE FROM `creature_queststarter` WHERE `quest` IN (55992, 55991);
DELETE FROM `creature_questender` WHERE `quest` IN (55992, 55991);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (55992, 55991);
DELETE FROM `quest_poi` WHERE `QuestID` IN (55992, 55991);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 100 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (161350, 'Kalecgos 卡雷苟斯', NULL, 1, 1, 35, 1, 1, 1.14286, 0, 8, 0, 2, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (161350, 0, 26752, 0.3, 1, 0);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES (154169, 'Captain Garrick 加里克队长', NULL, 80, 80, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (154169, 0, 3450, 1, 1, 0);
UPDATE `creature` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id1` IN (157300, 156814, 156501, 9159801, 9159802, 9159803, 6491);
UPDATE `gameobject` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id` IN (9159851, 9159852, 9159853);
UPDATE `creature` SET `phaseMask` = 1 WHERE `map` = 12175 AND `id1` = 167663;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 1, 161350, 12175, 1, 2, 0, 714.359, -1874.25, 186.882, 4.28795, 120, 0, 0, 'ALLY1G Kalecgos');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES (@g + 2, 154169, 0, 1, 1, 0, -8832.9, 633.8, 94.4, 4.62, 120, 0, 0, 'ALLY1G Captain Garrick in Stormwind');
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES (55992, 2, 1, 1, 8, 0, 'Dungeon: Darkmaul Citadel / 地下城：暗槌要塞', 'Defeat Tunk and Gor''groth, stop the ritual, then speak with Kalecgos. / 击败图克和戈尔格罗斯，阻止仪式，然后和卡雷苟斯说话。', 'You''ve slowed Gor''groth''s efforts to control Kalecgos atop the citadel, but the ritual itself needs to be thwarted.$B$BYou must storm the citadel and stop him from completing the ritual. His dark magic is an affront to the Light.$B$BWe will need all the help we can get. Gor''groth''s most elite lieutenants await within the citadel.$B$B(Accepting this quest takes you to the entrance of the citadel interior. Defeat Tunk and Gor''groth, fighting your way inward. Then Kalecgos, bound by the ritual, appears on the top platform. When he falls you are brought back here. 接任务后你会被传送到要塞内部入口。一路向里击败图克和戈尔格罗斯，之后被仪式控制的卡雷苟斯会出现在最高处的平台，击败他后你会被送回这里。)$B$B你拖慢了戈尔格罗斯在要塞顶上控制卡雷苟斯的进度，但仪式本身还得破除。$B$B你必须强攻要塞，不让他完成仪式。他的黑暗魔法是对圣光的亵渎。$B$B我们需要一切能得到的帮助，戈尔格罗斯最精锐的副手就在要塞里等着。', 'Return to Lady Jaina Proudmoore. / 回去向吉安娜复命。', '');
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 157300, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Tunk slain / 图克已被击杀' WHERE `ID` = 55992;
UPDATE `quest_template` SET `RequiredNpcOrGo2` = 156814, `RequiredNpcOrGoCount2` = 1, `ObjectiveText2` = 'Gor''groth slain / 戈尔格罗斯已被击杀' WHERE `ID` = 55992;
UPDATE `quest_template` SET `RequiredNpcOrGo3` = 156501, `RequiredNpcOrGoCount3` = 1, `ObjectiveText3` = 'Gor''groth''s final ritual stopped (defeat Kalecgos) / 阻止戈尔格罗斯的最后仪式（击败卡雷苟斯）' WHERE `ID` = 55992;
UPDATE `quest_template` SET `RequiredNpcOrGo4` = 161350, `RequiredNpcOrGoCount4` = 1, `ObjectiveText4` = 'Speak with Kalecgos to leave Darkmaul Citadel / 和卡雷苟斯说话离开暗槌要塞' WHERE `ID` = 55992;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55992, 55990, 55991);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (55992, 1, 0, 0, 0, 'It seems things are finally looking up for us. I think it''s time we returned to Stormwind.$B$B事情总算有了转机。我想是时候回暴风城了。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (55992, 0, 0, 'Has the ritual been stopped?$B$B仪式阻止了吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156965, 55992);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156961, 55992);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES (55991, 2, 1, 1, 8, 0, 'An End to Beginnings / 终结即开始', 'Speak with Kalecgos to travel to Stormwind, then report to Captain Garrick. / 和卡雷苟斯说话前往暴风城，再向加里克队长复命。', 'You''ve done fine work within Exile''s Reach, $n.$B$BI must go back to Stormwind. I need to find out how the ogres found such powerful shadow magic.$B$BSpeak with Kalecgos. He will take you there. Report to Captain Garrick when you arrive.$B$B你在流放者之岛干得很出色，$n。$B$B我得回暴风城，查清食人魔是从哪里弄到这么强大的暗影魔法的。$B$B去和卡雷苟斯说话，他会带你过去。到了以后向加里克队长报到。', 'Report to Captain Garrick in Stormwind. / 到暴风城向加里克队长复命。', '');
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 244389, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Speak to Kalecgos to travel to Stormwind / 和卡雷苟斯说话前往暴风城' WHERE `ID` = 55991;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55991, 55992, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES (55991, 1, 0, 0, 0, 'Good to see you back in Stormwind, $n. We have much to report to the king, and your journey has only begun.$B$B欢迎回到暴风城，$n。我们有很多事要向国王禀报，而你的旅程才刚刚开始。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES (55991, 0, 0, 'Welcome to Stormwind.$B$B欢迎来到暴风城。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156961, 55991);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (154169, 55991);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55992, 0, -1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 0, 0, 690, -1882, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 0, 1, 708, -1882, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 0, 2, 708, -1864, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 0, 3, 690, -1864, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55992, 1, 0, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 1, 0, 744, -1451, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 1, 1, 762, -1451, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 1, 2, 762, -1433, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 1, 3, 744, -1433, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55992, 2, 1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 2, 0, 843, -1634, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 2, 1, 861, -1634, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 2, 2, 861, -1616, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 2, 3, 843, -1616, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55992, 3, 2, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 3, 0, 744, -1449, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 3, 1, 762, -1449, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 3, 2, 762, -1431, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 3, 3, 744, -1431, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55992, 4, 3, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 4, 0, 705, -1883, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 4, 1, 723, -1883, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 4, 2, 723, -1865, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55992, 4, 3, 705, -1865, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55991, 0, -1, 0, 301, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 0, 0, -8842, 625, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 0, 1, -8824, 625, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 0, 2, -8824, 643, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 0, 3, -8842, 643, 0);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES (55991, 1, 0, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 1, 0, 705, -1883, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 1, 1, 723, -1883, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 1, 2, 723, -1865, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES (55991, 1, 3, 705, -1865, 0);
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (55992, 55991)) AS quests_2,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1G %') AS npcs_2,
       (SELECT COUNT(*) FROM `creature_queststarter` WHERE `quest` IN (55992, 55991)) AS starters_2,
       (SELECT COUNT(*) FROM `creature_questender` WHERE `quest` IN (55992, 55991)) AS enders_2,
       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `id1` IN (157300, 156814, 156501, 9159801, 9159802, 9159803, 6491) AND `phaseMask` <> 3) AS dungeon_not_shared_0,
       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (55992, 55991)) AS poi_7;
