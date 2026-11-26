-- ALLY1A V1 (2026-11-25, Claude) - candidate, NOT user-tested. Alliance ship (map 12261): Jaina, Private Cole, six dummies,
-- quests 56775 -> 58209 -> 58208 (retail ids, retail deck positions). Stop worldserver, run on the world database, restart.
-- Safe to run twice. Dummy 160737 and credit creature 155607 are shared with the Horde ship and are only added when missing.
SET @spawn_limit := 16777215;
DELETE FROM `creature` WHERE `map` = 12261 AND `Comment` LIKE 'ALLY1A %';
DELETE FROM `creature_template` WHERE `entry` IN (156280, 160664);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (156280, 160664);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (156280, 160664);
DELETE FROM `quest_template` WHERE `ID` IN (56775, 58209, 58208);
DELETE FROM `quest_template_addon` WHERE `ID` IN (56775, 58209, 58208);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (56775, 58209, 58208);
DELETE FROM `quest_request_items` WHERE `ID` IN (56775, 58209, 58208);
DELETE FROM `creature_queststarter` WHERE `quest` IN (56775, 58209, 58208);
DELETE FROM `creature_questender` WHERE `quest` IN (56775, 58209, 58208);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 20 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(156280, 'Lady Jaina Proudmoore 吉安娜·普罗德摩尔', 'Lord Admiral 海军统帅', 80, 80, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 2, ''),
(160664, 'Private Cole 二等兵科尔', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 6, 0.3, 1, 0, '');
INSERT IGNORE INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(155607, 'Private Cole 二等兵科尔', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 0, 7, '', 1, 1, 1, 0, ''),
(160737, 'Combat Dummy 战斗假人', NULL, 1, 1, 14, 0, 1, 1.14286, 0, 1, 0, 9, 'SmartAI', 1, 0, 0, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(156280, 0, 30863, 1, 1, 0), (160664, 0, 3167, 1, 1, 0);
INSERT IGNORE INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(155607, 0, 11686, 1, 1, 0), (160737, 0, 27510, 1, 1, 0);
-- no server ground data on the ship: creatures are held by flight movement
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES (156280, 1, 0, 1, 1), (160664, 1, 0, 1, 0);
INSERT IGNORE INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES (155607, 1, 0, 1, 1), (160737, 1, 0, 1, 1);
INSERT IGNORE INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(160737, 0, 0, 0, 63, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Combat Dummy - On created - Set react state passive'),
(160737, 0, 1, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Combat Dummy - On respawn - Set react state passive'),
(160737, 0, 2, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1200, 8, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Combat Dummy - On death - Despawn after 1.2 s, respawn in 8 s');
INSERT IGNORE INTO `game_weather` (`zone`, `spring_rain_chance`, `spring_snow_chance`, `spring_storm_chance`, `summer_rain_chance`, `summer_snow_chance`, `summer_storm_chance`, `fall_rain_chance`, `fall_snow_chance`, `fall_storm_chance`, `winter_rain_chance`, `winter_snow_chance`, `winter_storm_chance`, `ScriptName`) VALUES (50531, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `RewardMoney`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`) VALUES
(56775, 2, 1, 1, 2, 30, 'Warming Up / 热身', 'Warm up by fighting a Combat Dummy. / 与战斗假人对战热身。', 'Prepare yourself, $n. We''re nearing the island where the previous expedition was lost.$B$BWarm up on these combat dummies. We need everyone ready for whatever we find on that island.$B$B做好准备，$n。我们正在接近上一支远征队失踪的那座岛。$B$B先在这些战斗假人身上热热身。岛上不管有什么，我们都需要每个人做好准备。', '', 'Practice combat on a Combat Dummy. / 在战斗假人身上练习战斗。'),
(58209, 2, 1, 1, 2, 30, 'Stand Your Ground / 守住阵地', 'Spar with Private Cole. / 与二等兵科尔切磋。', 'I hope this rain isn''t a bad omen... this is supposed to be a simple rescue mission.$B$BYou''ll be sparring with me today. We have to make sure you can handle yourself once we make landfall.$B$BLet''s see what you''ve got!$B$B但愿这场雨不是什么坏兆头……这本该只是一次简单的救援任务。$B$B今天由我陪你切磋。登陆之后你得能照顾好自己。$B$B让我看看你的本事！', '', 'Spar with Private Cole. / 与二等兵科尔切磋。'),
(58208, 2, 1, 1, 1, 20, 'Brace for Impact / 准备迎接冲击', 'Find Lady Jaina Proudmoore. / 去找吉安娜·普罗德摩尔。', 'That''s it for warming up. You and the other new recruits are a promising bunch, I''ll tell you that much.$B$BHold on... what''s that sound? I think something big is headed our way!$B$B热身到此为止。我敢说，你和其他新兵都很有前途。$B$B等等……那是什么声音？好像有个大家伙朝我们来了！', '', 'Find Lady Jaina Proudmoore. / 去找吉安娜·普罗德摩尔。');
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 160737, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Practice combat on a Combat Dummy / 在战斗假人身上练习' WHERE `ID` = 56775;
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 155607, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Spar with Private Cole / 与二等兵科尔切磋' WHERE `ID` = 58209;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (56775, 0), (58209, 56775), (58208, 58209);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES
(56775, 1, 'Good, looks like you''ve kept up your $c training during our voyage.$B$BI''m concerned about the sudden turn in weather. Spar with Private Cole while I speak with the ship''s crew.$B$B很好，看来航行途中你一直没有荒废$c的训练。$B$B天气突然变坏让我很担心。我去和船员谈谈，你先和二等兵科尔切磋。', 0),
(58209, 1, 'You''re a skilled $c, recruit. I think you''ll prove a welcome addition to the main rescue team.$B$B你是个熟练的$c，新兵。救援主队会欢迎你的。', 0),
(58208, 1, 'This ship may not make it to the island.$B$BHold on to something sturdy and stick with your fellow recruits. We''ll get through this.$B$B这艘船也许撑不到岛上了。$B$B抓紧结实的东西，和其他新兵待在一起。我们会挺过去的。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES
(56775, 'Don''t be shy. Just walk up to the target dummies, select them, and use your main attack.$B$B别害羞。走到假人跟前，选中它，用你的主要攻击打它。', 0),
(58209, 'Keep at it. Show me what you can do.$B$B继续。让我看看你有多少本事。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156280, 56775), (160664, 58209), (160664, 58208);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156280, 56775), (160664, 58209), (156280, 58208);

INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 156280, 12261, 1, 1, 0, -1064.9, -1063.89, 13.18, 4.042, 120, 0, 0, 'ALLY1A Jaina'),
(@g + 2, 160664, 12261, 1, 1, 0, -1056.82, -1057.69, 13.47, 3.927, 120, 0, 0, 'ALLY1A Private Cole'),
(@g + 3, 160737, 12261, 1, 1, 0, -1064.29, -1053.22, 13.23, 4.601, 120, 0, 0, 'ALLY1A dummy 1'),
(@g + 4, 160737, 12261, 1, 1, 0, -1053.59, -1059.92, 13.39, 3.927, 120, 0, 0, 'ALLY1A dummy 2'),
(@g + 5, 160737, 12261, 1, 1, 0, -1054.46, -1068.08, 13.03, 2.819, 120, 0, 0, 'ALLY1A dummy 3'),
(@g + 6, 160737, 12261, 1, 1, 0, -1060.01, -1053.77, 13.39, 3.927, 120, 0, 0, 'ALLY1A dummy 4'),
(@g + 7, 160737, 12261, 1, 1, 0, -1067.64, -1054.62, 13.05, 4.924, 120, 0, 0, 'ALLY1A dummy 5'),
(@g + 8, 160737, 12261, 1, 1, 0, -1052.97, -1064.42, 13.23, 3.011, 120, 0, 0, 'ALLY1A dummy 6');

SELECT (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1A %') AS spawns_must_be_8,
       (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (56775, 58209, 58208)) AS quests_must_be_3,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (156280, 160664, 155607, 160737)) AS templates_must_be_4,
       (SELECT COUNT(*) FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 160737) AS dummy_ai_must_be_3;
