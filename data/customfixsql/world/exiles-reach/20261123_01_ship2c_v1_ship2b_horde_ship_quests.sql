-- SHIP2B V2 (2026-11-22, Claude): Exile's Reach Horde ship - Thrall, Grunt Throg, combat dummies, quests 59926-59928.
-- Ship NPC coordinates = retail transport-local coordinates + ship origin (-1066.7, -1066.7, 0.0) on map 12369.
-- V3: creature.guid is NOT fixed any more. The core stops the server when the spawn guid generator reaches 16777215 (0xFFFFFF).
-- V1/V2 used 88200001-88200006 and caused a start-up halt. Here the guids are taken from the live legal maximum + 1.
-- Safe to run twice: deletes its own rows by map + Comment (also the old 8820000x ones) and re-inserts. Keep worldserver stopped.
-- V5: no creature spawn statements at all. Spawn rows (guid/positions) are left exactly as they are in the database.

DELETE FROM `creature_template` WHERE `entry` IN (166573,166583,155607,160737);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (166573,166583,155607,160737);
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 160737;
DELETE FROM `quest_template` WHERE `ID` IN (59926,59927,59928);
DELETE FROM `quest_template_addon` WHERE `ID` IN (59926,59927,59928);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (59926,59927,59928);
DELETE FROM `quest_request_items` WHERE `ID` IN (59926,59927,59928);
DELETE FROM `creature_queststarter` WHERE `quest` IN (59926,59927,59928);
DELETE FROM `creature_questender` WHERE `quest` IN (59926,59927,59928);

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(166573, 'Thrall 萨尔', 'Warchief 大酋长', 80, 80, 35, 3, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 2, ''),
(166583, 'Grunt Throg 步兵索格', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 6, 0.3, 1, 0, ''),
(155607, 'Private Cole 二等兵科尔', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 0, 7, '', 1, 1, 1, 0, ''),
(160737, 'Combat Dummy 战斗假人', NULL, 1, 1, 14, 0, 1, 1.14286, 0, 1, 0, 9, 'SmartAI', 1, 0, 0, 0, '');

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(166573, 0, 4527, 1, 1, 0),
(166583, 0, 4259, 1, 1, 0),
(155607, 0, 11686, 1, 1, 0),
(160737, 0, 27510, 1, 1, 0);

INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(160737, 0, 0, 0, 63, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Combat Dummy - On created - Set react state passive'),
(160737, 0, 1, 0, 11, 0, 100, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Combat Dummy - On respawn - Set react state passive'),
(160737, 0, 2, 0, 6, 0, 100, 0, 0, 0, 0, 0, 0, 0, 41, 1200, 8, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Combat Dummy - On death - Despawn after 1.2 s, respawn in 8 s');

INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `QuestSortID`, `QuestInfoID`, `SuggestedGroupNum`, `RewardNextQuest`, `RewardXPDifficulty`, `RewardMoney`, `RewardMoneyDifficulty`, `RewardDisplaySpell`, `RewardSpell`, `RewardHonor`, `RewardKillHonor`, `StartItem`, `Flags`, `RequiredPlayerKills`, `TimeAllowed`, `AllowableRaces`, `POIContinent`, `POIx`, `POIy`, `POIPriority`, `RewardTitle`, `LogTitle`, `LogDescription`, `QuestDescription`, `AreaDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGo2`, `RequiredNpcOrGo3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount1`, `RequiredNpcOrGoCount2`, `RequiredNpcOrGoCount3`, `RequiredNpcOrGoCount4`, `VerifiedBuild`) VALUES
(59926, 2, 1, 1, 0, 0, 0, 0, 2, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Warming Up / 热身', 'Warm up by fighting a Combat Dummy. / 与战斗假人对战热身。', 'We''re nearing the island where the Horde''s last expedition was lost.$B$BYou need to be prepared for what''s out there. Warm up on these combat dummies.$B$B我们正在接近部落上一支远征队失踪的那座岛。$B$B你必须为岛上的一切做好准备。先在这些战斗假人身上热热身。', '', 'Practice combat on a Combat Dummy. / 在战斗假人身上练习战斗。', 160737, 0, 0, 0, 1, 0, 0, 0, 0),
(59927, 2, 1, 1, 0, 0, 0, 0, 2, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Stand Your Ground / 守住阵地', 'Spar with Grunt Throg. / 与步兵索格切磋。', 'Lok-tar! Nothing quite like a good fight in the rain.$B$BWe will spar together and take the measure of your strength!$B$B洛克塔！在雨中痛快打一架再好不过。$B$B我们来切磋一场，试试你的实力！', '', 'Spar with Grunt Throg. / 与步兵索格切磋。', 155607, 0, 0, 0, 1, 0, 0, 0, 0),
(59928, 2, 1, 1, 0, 0, 0, 0, 1, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'Brace for Impact / 准备迎接冲击', 'Find Thrall. / 去找萨尔。', 'Well fought, $n. You bring strength and honor to the Horde!$B$BNow we just--wait...$B$BDo you hear that?$B$B打得好，$n。你为部落带来了力量与荣耀！$B$B现在我们只要……等等……$B$B你听到了吗？', '', 'Find Thrall. / 去找萨尔。', 0, 0, 0, 0, 0, 0, 0, 0, 0);

INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES
(59926, 0),
(59927, 59926),
(59928, 59927);

INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(59926, 0, 0, 'Do not bother me! Go and attack those combat dummies. Show me your power.$B$B别烦我！去攻击那些战斗假人，让我看看你的实力。', 0),
(59927, 0, 0, 'Keep at it. Show me what you can do.$B$B继续。让我看看你有多少本事。', 0);

INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES
(59926, 1, 0, 0, 0, 'Good, you''ve kept training since we set sail.$B$BI must investigate this storm. Some unnatural force is behind it.$B$BSpar with Throg. He will assess your skills and decide on your role once we make landfall.$B$B很好，自从启航以来你一直坚持训练。$B$B我必须调查这场风暴，背后有一股不自然的力量。$B$B去和索格切磋吧，登陆之后他会评估你的技能，决定你的职责。', 0),
(59927, 1, 0, 0, 0, 'You show promise, $c. Perhaps you too will find glory on the island!$B$B你很有潜力，$c。也许你也能在岛上赢得荣耀！', 0),
(59928, 1, 0, 0, 0, 'Some force is manipulating this storm!$B$BStay near me when the ship crashes. I''ll keep you safe.$B$B有股力量在操纵这场风暴！$B$B船撞毁的时候留在我身边，我会保护你。', 0);

INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(166573, 59926),
(166583, 59927),
(166583, 59928);

INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(166573, 59926),
(166583, 59927),
(166573, 59928);

DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (166573,166583,155607,160737);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`) VALUES
(166573, 1, 0, 1, 1),
(166583, 1, 0, 1, 0),
(155607, 1, 0, 1, 1),
(160737, 1, 0, 1, 1);

