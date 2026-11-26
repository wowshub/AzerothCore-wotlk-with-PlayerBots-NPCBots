-- DARK2A V1 (2026-11-25, Claude) - candidate, NOT user-tested.
-- Exile's Reach Horde chain after 59981: 59984 Dungeon: Darkmaul Citadel -> 59985 An End to Beginnings.
-- Retail runs 59984 as a separate dungeon map (2236: Tunk, Gor'groth, Kalecgos + ~50 trash). User choice (2026-11-25): an OPEN-WORLD version on
-- the island: when 59984 is accepted, Dark2A.lua spawns the encounter on the citadel plateau around (490,-2010,143.8). 59985 ends with Kalecgos
-- teleporting you to Orgrimmar (the Dragon Isles map does not exist here); turn-in at Thrall (stock 4949) in Orgrimmar.
-- Safe to run twice. guids = live legal maximum + 1. Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'DARK2A %';
DELETE FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501, 167663, 9159801, 9159802, 9159803);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (157300, 156814, 156501, 167663, 9159801, 9159802, 9159803);
DELETE FROM `quest_template` WHERE `ID` IN (59984, 59985);
DELETE FROM `quest_template_addon` WHERE `ID` IN (59984, 59985);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (59984, 59985);
DELETE FROM `quest_request_items` WHERE `ID` IN (59984, 59985);
DELETE FROM `creature_queststarter` WHERE `quest` IN (59984, 59985);
DELETE FROM `creature_questender` WHERE `quest` IN (59984, 59985);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (59984, 59985);
DELETE FROM `quest_poi` WHERE `QuestID` IN (59984, 59985);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 5 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;
SELECT COUNT(*) AS thrall_4949_must_be_1 FROM `creature_template` WHERE `entry` = 4949;

-- ===== creature templates =====
-- bosses use the stock ogre model 11567 (scaled) and the stock Malygos blue dragon model 26752 (scaled) for Kalecgos; retail models are not in the client
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(157300, 'Tunk 图克', NULL, 10, 10, 14, 0, 1, 1.14286, 1, 1, 0, 7, '', 8, 0.9, 1, 0, ''),
(156814, 'Gor''groth 戈尔格罗斯', NULL, 11, 11, 14, 0, 1, 1.14286, 1, 8, 0, 7, '', 10, 0.9, 1, 0, ''),
(156501, 'Kalecgos 卡雷苟斯', 'Aspect of the Blue Dragonflight 蓝龙军团的守护巨龙', 12, 12, 14, 0, 1, 1.14286, 1, 8, 0, 2, '', 12, 0.9, 1, 0, ''),
(167663, 'Kalecgos 卡雷苟斯', NULL, 1, 1, 35, 1, 1, 1.14286, 0, 8, 0, 2, '', 3, 1, 1, 0, ''),
(9159801, 'Darkmaul Centurion 暗槌百夫长', NULL, 9, 9, 14, 0, 1, 1.14286, 0, 1, 0, 7, '', 3, 0.6, 1, 0, ''),
(9159802, 'Darkmaul Shadowcaller 暗槌暗影召唤师', NULL, 9, 9, 14, 0, 1, 1.14286, 0, 8, 0, 7, '', 2, 0.6, 1, 0, ''),
(9159803, 'Darkmaul Channeler 暗槌导灵者', NULL, 9, 9, 14, 0, 1, 1.14286, 0, 8, 0, 7, '', 2, 0.6, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(157300, 0, 11567, 1.5, 1, 0),
(156814, 0, 11567, 1.6, 1, 0),
(156501, 0, 26752, 0.6, 1, 0),
(167663, 0, 26752, 0.3, 1, 0),
(9159801, 0, 11567, 1.1, 1, 0),
(9159802, 0, 11567, 0.95, 1, 0),
(9159803, 0, 11567, 0.95, 1, 0);

-- ===== quests =====
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES
(59984, 2, 1, 1, 8, 0, 'Dungeon: Darkmaul Citadel / 副本：暗槌要塞', 'Storm the citadel and stop Gor''groth''s final ritual. / 强攻要塞，阻止戈尔格罗斯的最后仪式。',
 'Gor''groth seeks to use shadow magic to gain control of Kalecgos, the aspect of the Blue Dragonflight.$B$BHe''s collected enough life essence to attempt to finish the ritual. I do not know what will happen, but we cannot let him complete it!$B$BGor''groth will not stop until he is slain!$B$BYou must storm the citadel and slay Gor''groth before he can complete his ritual!$B$BI would charge in beside you, were I not still recovering from his dark magic.$B$B(Open-world version: accepting this quest summons Tunk, Gor''groth and Kalecgos with their guards on the citadel plateau near 490,-2010. 本版本为开放世界版：接任务后，图克、戈尔格罗斯和卡雷苟斯及其守卫会出现在要塞高地(490,-2010)附近。)$B$B戈尔格罗斯想用暗影魔法控制蓝龙军团的守护巨龙卡雷苟斯。$B$B他已经收集了足够的生命精华，打算完成仪式。我不知道会发生什么，但绝不能让他得逞！$B$B戈尔格罗斯不死不会罢休！$B$B你必须强攻要塞，在他完成仪式前杀掉戈尔格罗斯！$B$B我本想和你并肩冲锋，可惜我还没从他的黑暗魔法中恢复过来。',
 'Return to Thrall. / 回去向萨尔复命。', ''),
(59985, 2, 1, 1, 8, 0, 'An End to Beginnings / 终结即开始', 'Speak with Kalecgos to travel onward. / 和卡雷苟斯说话，继续旅程。',
 'You''ve done well here, $n. Kalecgos and Wrathion are planning to continue on to the Dragon Isles.$B$BI must return to Orgrimmar. This shadow magic is concerning... and requires that I look into it more.$B$BTalk with Kalecgos. He will get you out of here.$B$B(The Dragon Isles do not exist in this world yet: Kalecgos sends you to Orgrimmar, report to Thrall there. 巨龙群岛在本世界尚不存在：卡雷苟斯会把你送到奥格瑞玛，到那里向萨尔复命。)$B$B你在这里干得很好，$n。卡雷苟斯和瑞斯拉克打算继续前往巨龙群岛。$B$B我必须回奥格瑞玛。这种暗影魔法令人担忧……需要进一步调查。$B$B去和卡雷苟斯谈谈，他会送你离开这里。',
 'Speak with Kalecgos. / 和卡雷苟斯说话。', '');
UPDATE `quest_template` SET
  `RequiredNpcOrGo1` = 157300, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Tunk slain / 图克已被击杀',
  `RequiredNpcOrGo2` = 156814, `RequiredNpcOrGoCount2` = 1, `ObjectiveText2` = 'Gor''groth slain / 戈尔格罗斯已被击杀',
  `RequiredNpcOrGo3` = 156501, `RequiredNpcOrGoCount3` = 1, `ObjectiveText3` = 'Gor''groth''s final ritual stopped (defeat Kalecgos) / 阻止戈尔格罗斯的最后仪式（击败卡雷苟斯）',
  `RequiredNpcOrGo4` = 167663, `RequiredNpcOrGoCount4` = 1, `ObjectiveText4` = 'Speak with Kalecgos to leave Darkmaul Citadel / 和卡雷苟斯说话离开暗槌要塞'
WHERE `ID` = 59984;
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 244389, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Speak to Kalecgos to travel to Orgrimmar / 和卡雷苟斯说话前往奥格瑞玛' WHERE `ID` = 59985;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (59984, 59981, 0), (59985, 59984, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES
(59984, 1, 0, 0, 0, 'Thrall: It is done. Gor''groth''s ritual is broken and Kalecgos is free. The Horde thanks you.$B$B萨尔：结束了。戈尔格罗斯的仪式被打断，卡雷苟斯自由了。部落感谢你。', 0),
(59985, 1, 0, 0, 0, 'Thrall: You have come a long way from that wrecked shore. Walk well, $n.$B$B萨尔：你从那片破碎的海岸一路走到这里。一路走好，$n。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(59984, 0, 0, 'Is Gor''groth dead?$B$B戈尔格罗斯死了吗？', 0),
(59985, 0, 0, 'Did Kalecgos send you?$B$B是卡雷苟斯送你来的吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (167183, 59984), (167633, 59985);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (167633, 59984), (4949, 59985);

-- ===== static spawn: friendly Kalecgos next to Thrall inside the citadel (he gives the "speak" credit and the teleport) =====
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 167663, 12175, 1, 1, 0, 709.0, -1884.5, 186.88, 1.65, 120, 0, 0, 'DARK2A Kalecgos');

-- ===== quest map markers (4-corner squares +-9; ObjectiveIndex 0-based, -1 = turn-in) =====
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(59984, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59984, 1, 0, 12175, 20414, 0, 0, 1, 0),
(59984, 2, 1, 12175, 20414, 0, 0, 1, 0),
(59984, 3, 2, 12175, 20414, 0, 0, 1, 0),
(59984, 4, 3, 12175, 20414, 0, 0, 1, 0),
(59985, 0, 0, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(59984, 0, 0, 703, -1888, 0), (59984, 0, 1, 721, -1888, 0), (59984, 0, 2, 721, -1870, 0), (59984, 0, 3, 703, -1870, 0),
(59984, 1, 0, 495, -1995, 0), (59984, 1, 1, 513, -1995, 0), (59984, 1, 2, 513, -1977, 0), (59984, 1, 3, 495, -1977, 0),
(59984, 2, 0, 471, -2044, 0), (59984, 2, 1, 489, -2044, 0), (59984, 2, 2, 489, -2026, 0), (59984, 2, 3, 471, -2026, 0),
(59984, 3, 0, 481, -2029, 0), (59984, 3, 1, 499, -2029, 0), (59984, 3, 2, 499, -2011, 0), (59984, 3, 3, 481, -2011, 0),
(59984, 4, 0, 700, -1893, 0), (59984, 4, 1, 718, -1893, 0), (59984, 4, 2, 718, -1875, 0), (59984, 4, 3, 700, -1875, 0),
(59985, 0, 0, 700, -1893, 0), (59985, 0, 1, 718, -1893, 0), (59985, 0, 2, 718, -1875, 0), (59985, 0, 3, 700, -1875, 0);

-- read-back
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (59984, 59985)) AS quests_must_be_2,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501, 167663, 9159801, 9159802, 9159803)) AS templates_must_be_7,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'DARK2A %') AS static_spawns_must_be_1,
       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (59984, 59985)) AS poi_must_be_6;
