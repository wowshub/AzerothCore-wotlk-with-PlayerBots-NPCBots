-- ============================================================
-- 狼人出生地任务链 - 第一个任务：清剿血啸者
-- 日期: 2026-06-02
-- 功能:
--   1. 设置狼人(race=16)出生点到自定义狼人出生地
--   2. 创建自定义低等级狼人NPC (entry 900001)
--   3. 刷新任务发布NPC将军 (entry 466) 到出生点
--   4. 刷新20只野性血啸者到出生地四个方向
--   5. 创建第一个任务：清剿血啸者 (ID 90001)
--   6. 绑定任务到将军NPC
--
-- 出生点坐标: X=-1440.1937 Y=1407.6298 Z=35.556 Map=0
-- 地图说明: 需要正确的MAP和MMAP文件才能正常运行
--           VMAP使用服务端原版（版本匹配）
-- ============================================================

-- 1. 狼人出生点
UPDATE `playercreateinfo`
SET `map`=0, `position_x`=-1440.1937, `position_y`=1407.6298,
    `position_z`=35.556004, `orientation`=0
WHERE `race`=16;

-- 2. 自定义狼人NPC模板
DELETE FROM `creature_template` WHERE `entry`=900001;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`faction`,`npcflag`,`minlevel`,`maxlevel`,
 `unit_class`,`DamageModifier`,`HealthModifier`,`AIName`,`MovementType`,`flags_extra`)
VALUES
(900001,'野性血啸者','',24,0,3,5,1,0.4,0.5,'',1,0);

DELETE FROM `creature_template_model` WHERE `CreatureID`=900001;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (900001,0,574,1.0,1.0);

-- 3. 将军NPC
DELETE FROM `creature` WHERE `guid`=10001365;
INSERT INTO `creature`
(`guid`,`id1`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,
 `position_x`,`position_y`,`position_z`,`orientation`,
 `spawntimesecs`,`wander_distance`,`curhealth`,`curmana`,`MovementType`)
VALUES
(10001365,466,0,0,0,1,1,1,-1440.19,1407.63,35.556,1.57,300,0,1,0,0);

-- 4. 20只野性血啸者（四个方向分散）
DELETE FROM `creature` WHERE `id1`=900001;
INSERT INTO `creature`
(`id1`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,
 `position_x`,`position_y`,`position_z`,`orientation`,
 `spawntimesecs`,`wander_distance`,`curhealth`,`curmana`,`MovementType`)
VALUES
(900001,0,0,0,1,1,0,-1440.0,1460.0,35.556,4.71,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1455.0,1475.0,35.556,4.00,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1425.0,1468.0,35.556,5.00,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1465.0,1455.0,35.556,3.50,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1418.0,1480.0,35.556,4.50,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1440.0,1350.0,35.556,1.57,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1425.0,1335.0,35.556,2.00,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1455.0,1342.0,35.556,1.00,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1465.0,1358.0,35.556,0.50,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1418.0,1348.0,35.556,2.50,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1365.0,1407.0,35.556,3.14,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1375.0,1425.0,35.556,2.75,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1370.0,1390.0,35.556,3.50,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1355.0,1410.0,35.556,3.00,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1380.0,1440.0,35.556,2.50,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1510.0,1407.0,35.556,0.00,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1498.0,1425.0,35.556,0.50,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1505.0,1390.0,35.556,6.00,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1520.0,1415.0,35.556,0.25,90,8,1,0,1),
(900001,0,0,0,1,1,0,-1495.0,1440.0,35.556,5.75,90,8,1,0,1);

-- 5. 任务模板
DELETE FROM `quest_template` WHERE `ID`=90001;
INSERT INTO `quest_template`
(`ID`,`QuestType`,`QuestLevel`,`MinLevel`,`QuestSortID`,
 `RewardXPDifficulty`,`RewardMoney`,
 `LogTitle`,`LogDescription`,`QuestDescription`,`AreaDescription`,`QuestCompletionLog`,
 `RequiredNpcOrGo1`,`RequiredNpcOrGoCount1`,
 `ObjectiveText1`,`AllowableRaces`,`VerifiedBuild`)
VALUES
(90001,2,2,1,-1,5,25,
 '清剿血啸者',
 '消灭附近出没的野性血啸者。',
 '你的第一个任务是清剿工作，$N。一群野性血啸者正在威胁我们的出生地。去吧，杀死5只野性血啸者，然后回来向我报告！',
 '狼人出生地',
 '回到将军处报告你的猎杀成果。',
 900001,5,'消灭野性血啸者',0,12340);

DELETE FROM `quest_offer_reward` WHERE `ID`=90001;
INSERT INTO `quest_offer_reward` (`ID`,`Emote1`,`RewardText`)
VALUES (90001,1,'干得好，勇士！你已经消灭了那些野性血啸者，我们的出生地暂时安全了。这是你应得的奖励，继续为我们的族人而战！');

DELETE FROM `quest_request_items` WHERE `ID`=90001;
INSERT INTO `quest_request_items` (`ID`,`EmoteOnComplete`,`EmoteOnIncomplete`,`CompletionText`)
VALUES (90001,1,6,'你的猎杀进行得如何，$N？那些血啸者消灭了吗？');

-- 6. NPC任务绑定
DELETE FROM `creature_queststarter` WHERE `id`=466 AND `quest`=90001;
INSERT INTO `creature_queststarter` (`id`,`quest`) VALUES (466,90001);

DELETE FROM `creature_questender` WHERE `id`=466 AND `quest`=90001;
INSERT INTO `creature_questender` (`id`,`quest`) VALUES (466,90001);

-- 传送点
DELETE FROM `game_tele` WHERE `id`=99001;
INSERT INTO `game_tele` (`id`,`position_x`,`position_y`,`position_z`,`orientation`,`map`,`name`)
VALUES (99001,-1440.1937,1407.6298,35.556004,0,0,'worgen_start');
