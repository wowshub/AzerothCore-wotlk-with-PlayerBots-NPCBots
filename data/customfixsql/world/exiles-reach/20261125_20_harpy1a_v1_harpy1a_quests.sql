-- HARPY1A V1 (2026-11-25, Claude) - candidate, NOT user-tested.
-- Exile's Reach Horde chain after 59950: 59943 The Harpy Problem -> 59944 The Rescue of Herbert Gloomburst -> 59945 Harpy Culling
--   -> 59946 Purge the Totems -> 59947 Message to Base.  Data from LoreWalkerTDB (12.x), rebuilt for AC 3.3.5, map 12175.
-- Simplified vs retail: no phasing (all NPCs exist at once), no torch item/lock for the totems (click them), no Re-Sizer item on 59944,
--   Bloodbeak (retail objective credit npc 153964) is killed to count as "Herbert rescued", stock WotLK harpy models.
-- Safe to run twice. guids = live legal maximum + 1 (must stay below 16777215). Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'HARPY1A %';
DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'HARPY1A %';
DELETE FROM `creature_template` WHERE `entry` IN (167290, 167291, 167182, 153964, 152843);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (167290, 167291, 167182, 153964, 152843);
DELETE FROM `gameobject_template` WHERE `entry` = 350803;
DELETE FROM `quest_template` WHERE `ID` IN (59943, 59944, 59945, 59946, 59947);
DELETE FROM `quest_template_addon` WHERE `ID` IN (59943, 59944, 59945, 59946, 59947);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (59943, 59944, 59945, 59946, 59947);
DELETE FROM `quest_request_items` WHERE `ID` IN (59943, 59944, 59945, 59946, 59947);
DELETE FROM `creature_queststarter` WHERE `quest` IN (59943, 59944, 59945, 59946, 59947);
DELETE FROM `creature_questender` WHERE `quest` IN (59943, 59944, 59945, 59946, 59947);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 30 + 10000 < @spawn_limit AND @o + 10 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max, @o AS go_max;

-- ===== creature templates =====
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(167290, 'Wrathion 拉希奥', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167291, 'Bo 波', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167182, 'Herbert Gloomburst 赫伯特·格鲁姆伯斯特', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(153964, 'Bloodbeak 血喙', 'Terror of the Skies 空中之惧', 5, 5, 14, 0, 1, 1.14286, 1, 1, 0, 1, '', 4, 0.6, 1, 0, ''),
(152843, 'Harpy Boltcaller 鹰身人唤雷者', NULL, 3, 4, 14, 0, 1, 1.14286, 0, 1, 0, 7, '', 1, 0.5, 1, 0, '');
-- models: stock WotLK ids (10869 matriarch, 1350 windcaller); Wrathion = same as 167128, Bo / Herbert borrowed
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(167290, 0, 15511, 1, 1, 0),
(167291, 0, 4527, 1, 1, 0),
(167182, 0, 10256, 1, 1, 0),
(153964, 0, 10869, 1.2, 1, 0),
(152843, 0, 1350, 1, 1, 0);

-- ===== harpy totem (retail go 350803, type 10 goober, 'questinteract' icon, 'Burning'); stock totem model 695 =====
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES (350803, 10, 695, 'Harpy Totem 鹰身人图腾', 'questinteract', 'Burning 点燃中', '', 1, 0, 59946, 0, 30000, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, '', '', 0);

-- ===== quests =====
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES
(59943, 2, 1, 1, 3, 0, 'The Harpy Problem / 鹰身人问题', 'Meet with Bo near the Harpy Roost. / 在鹰身人巢穴附近与波会合。',
 'The ogres are planning to sacrifice the rest of the expedition to fuel this ritual to control Kalecgos, leader of the blue dragonflight.$B$BIt seems one of the survivors was taken to the hills north of here. Bo scouted ahead to investigate.$B$BCome, we''ll see what he has found.$B$B食人魔打算把远征队剩下的人献祭，用这个仪式去控制蓝龙军团的领袖卡雷苟斯。$B$B看来有个幸存者被带到了这里北边的山丘上。波先去侦察了。$B$B来吧，看看他发现了什么。',
 'Meet with Bo near the Harpy Roost. / 在鹰身人巢穴附近与波会合。', ''),
(59944, 2, 1, 1, 5, 0, 'The Rescue of Herbert Gloomburst / 营救赫伯特·格鲁姆伯斯特', 'Rescue Herbert Gloomburst from the harpies'' necromantic ritual. / 从鹰身人的死灵仪式中救出赫伯特·格鲁姆伯斯特。',
 'The harpies plan to sacrifice the expedition''s mage, a Forsaken by the name of Herbert Gloomburst.$B$BHerbert''s ethics are... questionable, but he always strives to serve the Horde. We''ll need his magic to stop the ogres.$B$BLet''s move.$B$B鹰身人打算献祭远征队的法师，一个名叫赫伯特·格鲁姆伯斯特的被遗忘者。$B$B赫伯特的道德……有点问题，但他一直尽力为部落效力。我们需要他的魔法去阻止食人魔。$B$B行动吧。',
 'Meet Herbert Gloomburst at the Harpy Roost entrance. / 在鹰身人巢穴入口与赫伯特会合。', ''),
(59945, 2, 1, 1, 5, 0, 'Harpy Culling / 猎杀鹰身人', 'Defeat 10 harpies and their allies. / 击败10只鹰身人及其同伙。',
 'The harpies seem to be in league with the ogres. Many of them are gathering to attack our camp.$B$BWe must thin their numbers and thwart their attempts to eliminate us.$B$BPerhaps they will learn it is best to leave the Horde be.$B$B鹰身人似乎和食人魔是一伙的。许多鹰身人正在集结，要攻击我们的营地。$B$B我们必须削减它们的数量，挫败它们消灭我们的企图。$B$B也许它们会明白最好别招惹部落。',
 '', ''),
(59946, 2, 1, 1, 5, 0, 'Purge the Totems / 清除图腾', 'Set fire to 5 Harpy Totems. / 点燃5个鹰身人图腾。',
 'The harpies have placed vile totems throughout the area to attain more power.$B$BWe must destroy those totems in order to debilitate our foes.$B$BBurn any totems you see. It is wise to weaken one''s enemy before the fight even begins.$B$B鹰身人在这一带立了邪恶的图腾来获取更多力量。$B$B我们必须毁掉这些图腾来削弱敌人。$B$B见到图腾就把它烧了。在战斗开始之前先削弱敌人是明智的。',
 '', ''),
(59947, 2, 1, 1, 3, 0, 'Message to Base / 向营地传讯', 'Return to the Horde Camp and speak with Thrall. / 回到部落营地，与萨尔交谈。',
 'Let us return to camp with Herbert in tow.$B$BWe''re one step closer towards thwarting the ogres and their plans.$B$B让我们带着赫伯特回营地吧。$B$B我们离挫败食人魔和他们的计划又近了一步。',
 'Return to the Horde Camp and speak with Thrall. / 回到部落营地，与萨尔交谈。', '');

-- objectives (59944: Bloodbeak kill counts as the rescue; 59946: negative id = gameobject)
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 153964, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Herbert Gloomburst rescued / 赫伯特·格鲁姆伯斯特获救' WHERE `ID` = 59944;
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 152843, `RequiredNpcOrGoCount1` = 10, `ObjectiveText1` = 'Harpies and cohorts slain / 已击杀的鹰身人及同伙' WHERE `ID` = 59945;
UPDATE `quest_template` SET `RequiredNpcOrGo1` = -350803, `RequiredNpcOrGoCount1` = 5, `ObjectiveText1` = 'Harpy Totems burned / 已点燃的鹰身人图腾' WHERE `ID` = 59946;

INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES
(59943, 59950, 59944), (59944, 59943, 59945), (59945, 59944, 59946), (59946, 59945, 59947), (59947, 59946, 0);

INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES
(59943, 1, 0, 0, 0, 'Bo: There you are. The harpies have a roost up on the hill, and I think they are holding one of ours.$B$B波：你来了。鹰身人在山上有个巢穴，我想他们关着我们的人。', 0),
(59944, 1, 0, 0, 0, 'Herbert: Oh, thank the Dark Lady! I was about to become a very unpleasant decoration.$B$B赫伯特：噢，感谢黑暗女王！我差点就成了一件非常糟糕的装饰品。', 0),
(59945, 1, 0, 0, 0, 'Bo: That should keep them off our backs, for now.$B$B波：这下它们暂时不会来烦我们了。', 0),
(59946, 1, 0, 0, 0, 'Bo: Good. Their magic will not hold without the totems.$B$B波：很好。没有图腾，它们的魔法撑不住。', 0),
(59947, 1, 0, 0, 0, 'Thrall: Herbert is safe, and the harpies are pushed back. Rest, then we go after the ogres.$B$B萨尔：赫伯特安全了，鹰身人也被击退了。先休息，然后我们去对付食人魔。', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(59943, 0, 0, 'Over here!$B$B这边！', 0),
(59944, 0, 0, 'Is it done?$B$B完成了吗？', 0),
(59945, 0, 0, 'Keep killing harpies.$B$B继续杀鹰身人。', 0),
(59946, 0, 0, 'Burn the totems.$B$B把图腾烧掉。', 0),
(59947, 0, 0, 'Report.$B$B汇报吧。', 0);

-- givers / enders (167128 Wrathion and 167212 Thrall already exist from BEACH1C)
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES
(167128, 59943), (167212, 59943), (167290, 59944), (167291, 59945), (167291, 59946), (167290, 59947);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES
(167291, 59943), (167182, 59944), (167291, 59945), (167291, 59946), (167212, 59947);

-- ===== spawns (retail positions; Wrathion 167290 twice: at the roost entrance and at the camp) =====
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 167291, 12175, 1, 1, 0, 394.486, -2445.07, 126.495, 1.95256, 120, 0, 0, 'HARPY1A Bo'),
(@g + 2, 167290, 12175, 1, 1, 0, 394.135, -2440.74, 126.16, 4.71088, 120, 0, 0, 'HARPY1A Wrathion roost'),
(@g + 3, 167290, 12175, 1, 1, 0, 172.115, -2287.21, 81.8489, 3.98125, 120, 0, 0, 'HARPY1A Wrathion camp'),
(@g + 4, 167182, 12175, 1, 1, 0, 391.849, -2445.4, 125.473, 0.356415, 120, 0, 0, 'HARPY1A Herbert'),
(@g + 5, 153964, 12175, 1, 1, 0, 500.555, -2337.76, 161.755, 4.58982, 300, 0, 0, 'HARPY1A Bloodbeak'),
-- harpies: 4 retail spots + 10 more near them (need 10 kills, respawn 60 s)
(@g + 6, 152843, 12175, 1, 1, 0, 432.856, -2411.98, 147.122, 4.60942, 60, 4, 1, 'HARPY1A harpy'),
(@g + 7, 152843, 12175, 1, 1, 0, 512.998, -2587.46, 155.684, 2.79665, 60, 4, 1, 'HARPY1A harpy'),
(@g + 8, 152843, 12175, 1, 1, 0, 512.896, -2596.15, 156.278, 2.85084, 60, 4, 1, 'HARPY1A harpy'),
(@g + 9, 152843, 12175, 1, 1, 0, 492.721, -2538.49, 152.213, 4.44049, 60, 4, 1, 'HARPY1A harpy'),
(@g + 10, 152843, 12175, 1, 1, 0, 436.0, -2408.0, 147.1, 4.6, 60, 4, 1, 'HARPY1A harpy'),
(@g + 11, 152843, 12175, 1, 1, 0, 429.0, -2415.0, 147.1, 4.6, 60, 4, 1, 'HARPY1A harpy'),
(@g + 12, 152843, 12175, 1, 1, 0, 509.0, -2583.0, 155.7, 2.8, 60, 4, 1, 'HARPY1A harpy'),
(@g + 13, 152843, 12175, 1, 1, 0, 516.0, -2592.0, 156.0, 2.8, 60, 4, 1, 'HARPY1A harpy'),
(@g + 14, 152843, 12175, 1, 1, 0, 496.0, -2534.0, 152.2, 4.4, 60, 4, 1, 'HARPY1A harpy'),
(@g + 15, 152843, 12175, 1, 1, 0, 489.0, -2542.0, 152.2, 4.4, 60, 4, 1, 'HARPY1A harpy'),
(@g + 16, 152843, 12175, 1, 1, 0, 478.0, -2455.0, 152.9, 2.6, 60, 4, 1, 'HARPY1A harpy'),
(@g + 17, 152843, 12175, 1, 1, 0, 470.0, -2500.0, 147.5, 5.4, 60, 4, 1, 'HARPY1A harpy'),
(@g + 18, 152843, 12175, 1, 1, 0, 536.0, -2490.0, 153.5, 0.3, 60, 4, 1, 'HARPY1A harpy'),
(@g + 19, 152843, 12175, 1, 1, 0, 440.0, -2485.0, 142.3, 5.4, 60, 4, 1, 'HARPY1A harpy');

INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(@o + 1, 350803, 12175, 1, 1, 435.549, -2488.26, 142.305, 5.41296, 0, 0, -0.421513, 0.906822, 60, 255, 1, 'HARPY1A totem'),
(@o + 2, 350803, 12175, 1, 1, 466.277, -2507.78, 147.457, 5.42474, 0, 0, -0.416164, 0.909289, 60, 255, 1, 'HARPY1A totem'),
(@o + 3, 350803, 12175, 1, 1, 540.87, -2492.4, 153.481, 0.345569, 0, 0, -0.171926, -0.98511, 60, 255, 1, 'HARPY1A totem'),
(@o + 4, 350803, 12175, 1, 1, 503.552, -2589.02, 155.422, 5.14822, 0, 0, -0.537509, 0.843258, 60, 255, 1, 'HARPY1A totem'),
(@o + 5, 350803, 12175, 1, 1, 478.538, -2450.95, 152.95, 2.5751, 0, 0, -0.960153, -0.279476, 60, 255, 1, 'HARPY1A totem');

-- read-back
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` BETWEEN 59943 AND 59947) AS quests_5,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARPY1A %') AS creatures_19,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'HARPY1A %') AS totems_5,
       (SELECT COUNT(*) FROM `creature_queststarter` WHERE `quest` BETWEEN 59943 AND 59947) AS starters_6,
       (SELECT COUNT(*) FROM `creature_questender` WHERE `quest` BETWEEN 59943 AND 59947) AS enders_5;
