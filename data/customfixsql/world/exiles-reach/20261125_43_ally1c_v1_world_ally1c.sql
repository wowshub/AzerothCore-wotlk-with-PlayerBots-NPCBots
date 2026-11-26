-- ALLY1C V1 (2026-11-25, Claude) - candidate, NOT user-tested. Needs ALLY1A, ALLY1B and the Horde stages BEACH1C, VEH1A.
-- Stop worldserver, run on the world database, restart. Safe to run twice.
-- Alliance quests 55173, 55186, 55184, 55193, 56034, 55879 (rows cloned from the tested Horde rows).
SET @spawn_limit := 16777215;
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (59935, 59938, 59940, 59941, 59942)) AS horde_quests_must_be_5,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (154327, 149899, 167027, 167128, 150228, 9167020, 156280, 156607)) AS needed_templates_must_be_8,
       (SELECT COUNT(*) FROM `item_template` WHERE `entry` = 9178051) AS resizer_item_must_be_1;
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1C %';
DELETE FROM `creature_template` WHERE `entry` IN (149915, 156518, 156799, 9156280, 150238, 9167021);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (149915, 156518, 156799, 9156280, 150238, 9167021);
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 9167021;
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 9167021;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 9167021 AND `source_type` = 0;
DELETE FROM `quest_template` WHERE `ID` IN (55173, 55186, 55184, 55193, 56034, 55879);
DELETE FROM `quest_template_addon` WHERE `ID` IN (55173, 55186, 55184, 55193, 56034, 55879);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (55173, 55186, 55184, 55193, 56034, 55879);
DELETE FROM `quest_request_items` WHERE `ID` IN (55173, 55186, 55184, 55193, 56034, 55879);
DELETE FROM `creature_queststarter` WHERE `quest` IN (55173, 55186, 55184, 55193, 56034, 55879);
DELETE FROM `creature_questender` WHERE `quest` IN (55173, 55186, 55184, 55193, 56034, 55879);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (55173, 55186, 55184, 55193, 56034, 55879);
DELETE FROM `quest_poi` WHERE `QuestID` IN (55173, 55186, 55184, 55193, 56034, 55879);

DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 154327;
UPDATE tmp_c SET `entry` = 149915, `name` = 'Austin Huxworth 奥斯汀·赫克斯沃斯', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (149915, 0, 2150, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 167027;
UPDATE tmp_c SET `entry` = 156518, `name` = 'Scout-o-Matic 5000 侦察机5000型', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156518, 0, 7052, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 167128;
UPDATE tmp_c SET `entry` = 156799, `name` = 'Wrathion 拉希奥', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156799, 0, 15511, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 156280;
UPDATE tmp_c SET `entry` = 9156280, `name` = 'Lady Jaina Proudmoore 吉安娜·普罗德摩尔', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9156280, 0, 30863, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 150228;
UPDATE tmp_c SET `entry` = 150238, `name` = 'Quilboar Geomancer 野猪人地卜师', `subname` = NULL, `ScriptName` = '', `faction` = 14, `minlevel` = 3, `maxlevel` = 4, `lootid` = 0, `unit_class` = 8;
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (150238, 0, 6093, 1, 1, 0);

-- bombing-run vehicle: copy of the tested Horde gunship 9167020
DROP TEMPORARY TABLE IF EXISTS tmp_v;
CREATE TEMPORARY TABLE tmp_v AS SELECT * FROM `creature_template` WHERE `entry` = 9167020;
UPDATE tmp_v SET `entry` = 9167021, `name` = 'Scientifically Enhanced Boar 科学强化野猪', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_v;
DROP TEMPORARY TABLE tmp_v;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT 9167021, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = 9167020;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`)
SELECT 9167021, `Index`, `Spell`, `VerifiedBuild` FROM `creature_template_spell` WHERE `CreatureID` = 9167020;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT 9167021, `spell_id`, `cast_flags`, `user_type` FROM `npc_spellclick_spells` WHERE `npc_entry` = 9167020;
DROP TEMPORARY TABLE IF EXISTS tmp_sa;
CREATE TEMPORARY TABLE tmp_sa AS SELECT * FROM `smart_scripts` WHERE `entryorguid` = 9167020 AND `source_type` = 0;
UPDATE tmp_sa SET `entryorguid` = 9167021;
INSERT INTO `smart_scripts` SELECT * FROM tmp_sa;
DROP TEMPORARY TABLE tmp_sa;

SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 149915, 12175, 1, 2, 0, 99.4826, -2420.86, 90.3767, 0.751115, 120, 0, 0, 'ALLY1C Austin south'),
(@g + 2, 156518, 12175, 1, 2, 0, 107.872, -2414.18, 95.4484, 0, 120, 0, 0, 'ALLY1C Scout-o-Matic'),
(@g + 3, 9156280, 12175, 1, 2, 0, 102.613, -2420.63, 90.2006, 3.2404, 120, 0, 0, 'ALLY1C Jaina north camp'),
(@g + 4, 156799, 12175, 1, 2, 0, 230.828, -2297.07, 83.8167, 1.35623, 120, 0, 0, 'ALLY1C Wrathion'),
(@g + 5, 150238, 12175, 1, 3, 0, -35.8683, -2622.01, 53.5619, 0.32406, 60, 0, 0, 'ALLY1C quilboar 1'),
(@g + 6, 150238, 12175, 1, 3, 0, -8.36285, -2585.1, 58.7648, 0.471628, 60, 0, 0, 'ALLY1C quilboar 2'),
(@g + 7, 150238, 12175, 1, 3, 0, 57.8802, -2550.33, 66.335, 3.31176, 60, 0, 0, 'ALLY1C quilboar 3'),
(@g + 8, 150238, 12175, 1, 3, 0, 93.1875, -2609.77, 65.3175, 4.4345, 60, 0, 0, 'ALLY1C quilboar 4'),
(@g + 9, 150238, 12175, 1, 3, 0, 60.033, -2592.1, 65.5214, 4.60058, 60, 0, 0, 'ALLY1C quilboar 5'),
(@g + 10, 150238, 12175, 1, 3, 0, 0.965278, -2618.07, 56.0958, 5.63546, 60, 0, 0, 'ALLY1C quilboar 6'),
(@g + 11, 150238, 12175, 1, 3, 0, 23.224, -2587.09, 64.3402, 5.13771, 60, 0, 0, 'ALLY1C quilboar 7'),
(@g + 12, 150238, 12175, 1, 3, 0, 102.01, -2576.56, 64.2141, 3.31453, 60, 0, 0, 'ALLY1C quilboar 8'),
(@g + 13, 150238, 12175, 1, 3, 0, 59.5087, -2597.38, 65.3549, 5.03747, 60, 0, 0, 'ALLY1C quilboar 9'),
(@g + 14, 150238, 12175, 1, 3, 0, -26.5596, -2615.11, 54.2375, 1.56089, 60, 0, 0, 'ALLY1C quilboar 10'),
(@g + 15, 150238, 12175, 1, 3, 0, -35.9816, -2593.27, 55.3926, 0.348874, 60, 0, 0, 'ALLY1C quilboar 11'),
(@g + 16, 9167021, 12175, 1, 2, 0, 113.0, -2410.0, 95.4484, 0.6, 30, 0, 0, 'ALLY1C vehicle');

-- the two northern NPCs already stand there for the Horde line and are the same people for the Alliance: both factions see them
UPDATE `creature` SET `phaseMask` = 3 WHERE `map` = 12175 AND `id1` IN (154327, 149899);
-- Austin is a human (the earlier stand-in look was not)
UPDATE `creature_template_model` SET `CreatureDisplayID` = 2150 WHERE `CreatureID` = 154327;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59935;
UPDATE tmp_q SET `ID` = 55173, `LogTitle` = 'Northbound / 北行', `LogDescription` = 'Scout northward and find Austin Huxworth. / 向北侦察，找到奥斯汀·赫克斯沃斯。', `QuestDescription` = 'The quilboar kidnapped the rest of the expedition and took them to the north.$B$BI heard mention of needing more sacrifices for some sort of ritual...$B$BPlease, you must rescue them!$B$B野猪人绑走了远征队的其他人，带到北边去了。$B$B我听他们说某种仪式还需要更多祭品……$B$B求你一定要救他们！', `QuestCompletionLog` = 'Find Austin Huxworth further north. / 到更北边找奥斯汀·赫克斯沃斯。', `RewardNextQuest` = 0, `RequiredNpcOrGo1` = 0, `RequiredNpcOrGoCount1` = 0, `RequiredNpcOrGo2` = 0, `RequiredNpcOrGoCount2` = 0, `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0, `RequiredNpcOrGo4` = 0, `RequiredNpcOrGoCount4` = 0, `ObjectiveText1` = '', `ObjectiveText2` = '', `ObjectiveText3` = '', `ObjectiveText4` = '';
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55173, 55174, 55186);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (55173, 1, 'I''ve got some good news and some very, very bad news.$B$B我有个好消息，还有个非常非常坏的消息。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156607, 55173);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (154327, 55173);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 55173, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59935;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 55173, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59935;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59938;
UPDATE tmp_q SET `ID` = 55186, `LogTitle` = 'Down with the Quilboar / 打倒野猪人', `LogDescription` = 'Slay Geolord Grek''og. / 击杀地卜师格雷克奥格。', `QuestDescription` = 'From what I can gather, the quilboar are performing a shadow ritual on one of the expedition members.$B$BTheir chief is Geolord Grek''og. Slay him and save the captive.$B$B据我了解，野猪人正在对一名远征队员施行暗影仪式。$B$B它们的头领是地卜师格雷克奥格。杀了它，救出俘虏。', `QuestCompletionLog` = 'Meet Lindie Springstock north of the Briarpatch. / 到荆棘丛北边见琳迪。', `RewardNextQuest` = 0, `RequiredNpcOrGo1` = 151091, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Geolord slain / 地卜师已击杀';
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55186, 55173, 55193);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (55186, 1, 'Thanks for saving my life! They said this would be a run of the mill, uneventful expedition.$B$BIt definitely was NOT! And I couldn''t be happier!$B$B谢谢你救了我！他们说这趟远征平淡无奇。$B$B才不是呢！我高兴极了！', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (55186, 'Is Grek''og dead?$B$B格雷克奥格死了吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (154327, 55186);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (149899, 55186);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 55186, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59938;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 55186, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59938;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59938;
UPDATE tmp_q SET `ID` = 55184, `LogTitle` = 'Quilboar Shadow Magic / 野猪人的暗影魔法', `LogDescription` = 'Slay 7 Quilboar Geomancers in the Briarpatch. / 在荆棘丛击杀7个野猪人地卜师。', `QuestDescription` = 'Quilboar are primitive and savage. They rarely practice any magic other than geomancy.$B$BBut these particular quilboar seem to be dabbling in shadow magic. They must be stopped.$B$BSlay the quilboar in the den.$B$B野猪人原始又野蛮，除了地卜术很少使别的法术。$B$B可这群野猪人似乎在摆弄暗影魔法，必须阻止它们。$B$B去巢穴里消灭它们。', `QuestCompletionLog` = 'Return to Austin Huxworth south of the Briarpatch. / 回到奥斯汀那里。', `RewardNextQuest` = 0, `RequiredNpcOrGo1` = 150238, `RequiredNpcOrGoCount1` = 7, `ObjectiveText1` = 'Quilboar slain / 野猪人已击杀', `RequiredNpcOrGo2` = 0, `RequiredNpcOrGoCount2` = 0, `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0, `RequiredNpcOrGo4` = 0, `RequiredNpcOrGoCount4` = 0;
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55184, 55173, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (55184, 1, 'Good work. I hope those quilboar learn that necromancy is not a path to power.$B$B干得好。但愿野猪人明白，死灵术换不来力量。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (55184, 'Are the quilboar dealt with?$B$B野猪人解决了吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (154327, 55184);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (149915, 55184);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (149915, 55184);

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59940;
UPDATE tmp_q SET `ID` = 55193, `LogTitle` = 'The Scout-o-Matic 5000 / 侦察机5000型', `LogDescription` = 'Use the Scout-o-Matic 5000 to find Henry Garrick. / 使用侦察机5000型寻找亨利·加里克。', `QuestDescription` = 'You look like someone who needs help finding the scattered members of our expedition!$B$BI''ve got my Scout-o-Matic 5000 all set to go. It''ll fly up in the air and let you scout the entire area.$B$BI''ll give you the honors.$B$B你看起来需要帮手找散落的远征队员！$B$B我的侦察机5000型已经准备好了，它会飞上天让你看清整片地区。$B$B这份荣幸归你。', `QuestCompletionLog` = 'Return to Lindie. / 回到琳迪那里。', `RewardNextQuest` = 0, `RequiredNpcOrGo1` = 156518, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Island scouted from the air / 已从空中侦察';
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55193, 55186, 56034);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (55193, 1, 'There''s no problem a little re-sizing can''t fix! Let''s find something to stomp those undead flat!$B$B没有什么问题是缩放一下解决不了的！找个能把亡灵踩扁的东西！', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (55193, 'Have you scouted yet?$B$B侦察过了吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (149899, 55193);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (149899, 55193);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 55193, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59940;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 55193, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59940;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59941;
UPDATE tmp_q SET `ID` = 56034, `LogTitle` = 'Re-sizing the Situation / 缩放局势', `LogDescription` = 'Use the Re-Sizer on 3 Wandering Boars. / 对3头游荡野猪使用缩放器。', `QuestDescription` = 'The Re-Sizer barely works on inanimate objects. I have no idea what it will do to organic matter!$B$BBut if we do nothing, Wrathion will die!$B$BTake the Re-Sizer. We''re going to whip up a giant boar!$B$B缩放器连死物都不太灵，用在活物上会怎样我可不知道！$B$B可要是什么都不做，拉希奥会死的！$B$B拿着缩放器，我们要造一头巨型野猪！', `QuestCompletionLog` = 'Speak with Lady Jaina Proudmoore. / 和吉安娜·普罗德摩尔交谈。', `RewardNextQuest` = 0;
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (56034, 55193, 55879);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (56034, 1, 'I never thought I''d be so relieved to be face to face with a giant, scientifically enhanced boar.$B$BLet''s go save my son.$B$B真没想到，面对一头科学强化过的巨型野猪，我竟会这么安心。$B$B走，去救我的儿子。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (56034, 'Try it on the boars.$B$B在野猪身上试试。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (149899, 56034);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (9156280, 56034);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 56034, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59941;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 56034, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59941;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59942;
UPDATE tmp_q SET `ID` = 55879, `LogTitle` = 'Ride of the Scientifically Enhanced Boar / 强化野猪的冲锋', `LogDescription` = 'Ride the beast, destroy 8 Monstrous Cadavers and defeat Torgok. / 骑上坐骑，消灭8具巨大的尸骸，击败托戈克。', `QuestDescription` = 'We don''t know how long the re-sizing will last, so let''s get moving.$B$BYou''re going to ride and mow down the army of undead between us and Wrathion.$B$BLet''s hope Wrathion is willing to help us find Kalecgos.$B$B不知道缩放效果能撑多久，赶紧行动。$B$B骑上去，扫平我们和拉希奥之间的亡灵大军。$B$B但愿拉希奥肯帮我们找到卡雷苟斯。', `QuestCompletionLog` = 'Find Wrathion. / 去找拉希奥。', `RewardNextQuest` = 0, `RequiredNpcOrGoCount1` = 8, `ObjectiveText1` = 'Monstrous Cadavers slain / 巨大的尸骸已击杀';
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55879, 56034, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (55879, 1, 'Thank you, stranger. I thought I was going to be punished for failing to save my friends.$B$BI''m relieved that I was mistaken.$B$B谢谢你，陌生人。我以为没能救下朋友会受惩罚。$B$B很庆幸我想错了。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (55879, 'Clear the cadavers!$B$B清掉那些尸骸！', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (9156280, 55879);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156799, 55879);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 55879, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59942;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 55879, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59942;

INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(55184, 0, -1, 12175, 20414, 0, 0, 1, 0), (55184, 1, 0, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(55184, 0, 0, 90, -2430, 0), (55184, 0, 1, 108, -2430, 0), (55184, 0, 2, 108, -2412, 0), (55184, 0, 3, 90, -2412, 0),
(55184, 1, 0, -34, -2655, 0), (55184, 1, 1, 86, -2655, 0), (55184, 1, 2, 86, -2535, 0), (55184, 1, 3, -34, -2535, 0);

SELECT (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1C %') AS new_spawns_must_be_16,
       (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (55173, 55186, 55184, 55193, 56034, 55879)) AS quests_must_be_6,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (149915, 156518, 156799, 9156280, 150238, 9167021)) AS new_templates_must_be_6,
       (SELECT COUNT(*) FROM `npc_spellclick_spells` WHERE `npc_entry` = 9167021) AS vehicle_click_more_than_0,
       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `id1` IN (154327, 149899) AND `phaseMask` = 3) AS shared_north_npcs_at_least_2;
