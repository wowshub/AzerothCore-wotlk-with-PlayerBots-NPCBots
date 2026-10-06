-- ============================================================
-- 科赞海滩 地精起始任务1「打理生意」 Taking Care of Business
-- 号段规范: quest=90011, NPC=900110(萨斯)/900111(丹普威克)
-- 地图: 648 科赞 Kezan (注意:648无.map/.mmaps,NPC站桩对话型)
-- 实测坐标: 出生点 377.48907,3087.112,-1.2 / 萨斯 403.98923,3027.5728,1.0
-- ============================================================

-- ---------- 1. 地精出生点改到科赞海滩(原值: map1 -2917.58,-257.98,52.9968) ----------
UPDATE `playercreateinfo`
SET `map`=648, `zone`=0, `position_x`=377.48907, `position_y`=3087.112, `position_z`=-1.2, `orientation`=0
WHERE `race`=9 AND `class`<>6;  -- class=6死亡骑士保留它自己的DK起始点(map609)不动

-- ---------- 2. NPC萨斯(接任务) creature_template entry=900110 ----------
DELETE FROM `creature_template` WHERE `entry`=900110;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`speed_walk`,`speed_run`,`unit_class`,`unit_flags`,`type`,`type_flags`,`RegenHealth`,`MovementType`,`AIName`)
VALUES
(900110,'萨斯','锈水财阀',1,1,35,2,1,1.14286,1,768,7,0,1,0,'');
-- npcflag=2 (QUESTGIVER 任务给予者), faction=35(对所有友好), unit_flags=768(不可攻击+不可选为敌)

-- 萨斯模型 (男地精 6781)
DELETE FROM `creature_template_model` WHERE `CreatureID`=900110;
INSERT INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (900110,0,7110,1,1);

-- 萨斯 spawn (实测坐标)
DELETE FROM `creature` WHERE `id1`=900110;
INSERT INTO `creature`
(`guid`,`id1`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`MovementType`)
VALUES
(10010001,900110,648,0,0,1,1,403.98923,3027.5728,1.0,3.5,300,0);

-- ---------- 3. NPC工头丹普威克(交任务) creature_template entry=900111 ----------
DELETE FROM `creature_template` WHERE `entry`=900111;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`minlevel`,`maxlevel`,`faction`,`npcflag`,`speed_walk`,`speed_run`,`unit_class`,`unit_flags`,`type`,`type_flags`,`RegenHealth`,`MovementType`,`AIName`)
VALUES
(900111,'工头丹普威克','锈水财阀',1,1,35,2,1,1.14286,1,768,7,0,1,0,'');

-- 丹普威克模型 (男地精 6781)
DELETE FROM `creature_template_model` WHERE `CreatureID`=900111;
INSERT INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (900111,0,7109,1,1);

-- 丹普威克 spawn (实测坐标)
DELETE FROM `creature` WHERE `id1`=900111;
INSERT INTO `creature`
(`guid`,`id1`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`MovementType`)
VALUES
(10010002,900111,648,0,0,1,1,447.73596,3029.532,3.2842288,3.5,300,0);

-- ---------- 4. 任务模板「打理生意」 quest_template entry=90011 ----------
DELETE FROM `quest_template` WHERE `ID`=90011;
INSERT INTO `quest_template`
(`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`QuestSortID`,`RewardXPDifficulty`,`RewardMoney`,`Flags`,`LogTitle`,`LogDescription`,`QuestDescription`,`QuestCompletionLog`)
VALUES
(90011, 2, 1, 1, 0, 1, 100, 0,
 '打理生意',
 '去找锈水财阀的工头丹普威克报到。',
 '欢迎来到科赞,新人!锈水财阀正缺人手。去海滩另一头找工头丹普威克<class>,他会安排你干活。',
 '你找到了工头丹普威克。');
-- QuestType=2(普通), RewardMoney=100铜, RewardXPDifficulty=1

-- 任务奖励经验(quest_template_addon可选;这里用RewardXPDifficulty已给基础经验)
DELETE FROM `quest_template_addon` WHERE `ID`=90011;
INSERT INTO `quest_template_addon` (`ID`,`MaxLevel`,`AllowableClasses`) VALUES (90011,0,0);

-- ---------- 5. 绑定: 萨斯给任务, 丹普威克收任务 ----------
DELETE FROM `creature_queststarter` WHERE `id`=900110 AND `quest`=90011;
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (900110,90011);

DELETE FROM `creature_questender` WHERE `id`=900111 AND `quest`=90011;
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (900111,90011);
