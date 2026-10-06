-- ============================================================
-- 狼人出生地任务链 - 第二个任务：被困的市民（救援门）
-- 日期: 2026-06-02
-- 功能:
--   1. 救援门 GO (entry 6201) - GOOBER类型, 点击消失, 自动任务计数
--   2. 被困市民 NPC (entry 50105) - 点门后颤抖+喊话+消失
--   3. 愤怒的血啸者狼人 NPC (entry 50104) - 50%几率刷出
--   4. 门与市民通过 SmartAI 数据信号(SET_DATA/DATA_SET)联动
--   5. 9扇门 + 9个市民, 30秒同步刷新
--
-- 核心机制讲解:
--   - GameObject type=10 是 GOOBER(可交互物体), 不是门(type=0)也不是理发椅(type=32)
--   - GOOBER 点击会自动 KillCreditGO 给任务计数
--   - Data5=1 consumable 让门点一次消失(防连点)
--   - Data1=0 去掉任务过滤, 任何人都能点门(防止玩家被关屋里)
--   - Data2=6201 eventId, 点门广播信号触发门的 SmartAI
--   - 门 SmartAI(event=71) -> SET_DATA 通知最近市民 + 50%生成狼人
--   - 市民 SmartAI(event=38) -> 收到信号 -> 颤抖(emote438) -> 喊话 -> 5秒消失30秒刷回
-- ============================================================

-- ------------------------------------------------------------
-- 1. 救援门模板 (entry 6201)
--    type=10 GOOBER, displayId=1189 绿色双开门
-- ------------------------------------------------------------
DELETE FROM `gameobject_template` WHERE `entry`=6201;
INSERT INTO `gameobject_template`
(`entry`,`type`,`displayId`,`name`,`IconName`,`castBarCaption`,`unk1`,`size`,
 `Data0`,`Data1`,`Data2`,`Data3`,`Data4`,`Data5`,`Data6`,`Data7`,`Data8`,`Data9`,
 `Data10`,`Data11`,`Data12`,`Data13`,`Data14`,`Data15`,`Data16`,`Data17`,
 `Data18`,`Data19`,`Data20`,`Data21`,`Data22`,`Data23`,`AIName`,`ScriptName`,`VerifiedBuild`)
VALUES
(6201,10,1189,'被困的屋门','','','',1,
 0,0,6201,1000,0,1,0,0,0,0,
 0,0,0,0,0,0,0,0,
 0,0,0,0,0,0,'SmartGameObjectAI','',0);

-- ------------------------------------------------------------
-- 2. 门的 SmartAI: 点门通知市民 + 50%刷狼人
--    event=71 GO_EVENT_INFORM(收到6201信号)
--    action=45 SET_DATA(发(1,1)信号给最近市民50105,10码内)
--    链接 50%几率 action=12 SUMMON_CREATURE(生成狼人50104,持续60秒)
-- ------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid`=6201 AND `source_type`=1;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,
 `event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(6201,1,0,1, 71,0,100,0, 6201,0,0,0,0,0, 45,1,1,0,0,0,0, 19,50105,10,0,0, 0,0,0,0,'点门:通知最近平民'),
(6201,1,1,0, 61,0,50,0,  0,0,0,0,0,0,    12,50104,3,60000,0,0,0, 11,0,0,0,0, 0,0,0,0,'50%狼人');

-- ------------------------------------------------------------
-- 3. 被困市民 NPC 模板 (entry 50105)
--    faction=35 友好, flags_extra=2 不可攻击, 难民外观(4种随机)
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry`=50105;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`faction`,`npcflag`,`minlevel`,`maxlevel`,
 `unit_class`,`DamageModifier`,`HealthModifier`,`AIName`,`MovementType`,`flags_extra`)
VALUES
(50105,'被困的市民','',35,0,1,1,1,0.1,0.3,'SmartAI',0,2);

DELETE FROM `creature_template_model` WHERE `CreatureID`=50105;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES
(50105,0,18619,1.0,1.0),
(50105,1,18618,1.0,1.0),
(50105,2,18617,1.0,1.0),
(50105,3,18616,1.0,1.0);

-- ------------------------------------------------------------
-- 4. 市民说话文本 (Type=14 YELL 头顶红字喊话)
-- ------------------------------------------------------------
DELETE FROM `creature_text` WHERE `CreatureID`=50105;
INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`comment`)
VALUES
(50105,0,0,'谢谢你救了我！狼人太可怕了，我得赶紧逃离这里！',14,0,100,0,0,0,'被困市民获救');

-- ------------------------------------------------------------
-- 5. 市民的 SmartAI: 收到信号->颤抖->喊话->5秒消失30秒刷回
--    event=38 DATA_SET(收到门发的(1,1)信号)
--    action=5  PLAY_EMOTE(emote438 持续畏缩颤抖)
--    action=1  TALK(喊话)
--    action=41 FORCE_DESPAWN(param1=5000ms延迟消失, param2=30秒后刷回, param3=0不删除)
-- ------------------------------------------------------------
DELETE FROM `smart_scripts` WHERE `entryorguid`=50105 AND `source_type`=0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,
 `event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,
 `target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
(50105,0,0,1, 38,0,100,0, 1,1,0,0,0,0, 5,438,0,0,0,0,0, 1,0,0,0,0, 0,0,0,0,'获救:持续畏缩'),
(50105,0,1,0, 61,0,100,0, 0,0,0,0,0,0, 1,0,0,0,0,0,0, 1,0,0,0,0, 0,0,0,0,'喊话:谢谢救命'),
(50105,0,2,0, 38,0,100,0, 1,1,0,0,0,0, 41,5000,30,0,0,0,0, 1,0,0,0,0, 0,0,0,0,'5秒后消失30秒刷回');

-- ------------------------------------------------------------
-- 6. 愤怒的血啸者狼人 NPC 模板 (entry 50104)
--    敌对狼人, 50%几率从门里冲出, 攻击玩家
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry`=50104;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`faction`,`npcflag`,`minlevel`,`maxlevel`,
 `unit_class`,`DamageModifier`,`HealthModifier`,`AIName`,`MovementType`,`flags_extra`)
VALUES
(50104,'愤怒的血啸者','',24,0,3,5,1,0.4,0.5,'',1,0);

DELETE FROM `creature_template_model` WHERE `CreatureID`=50104;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (50104,0,574,1.0,1.0);

-- ------------------------------------------------------------
-- 7. 9扇救援门实例 (map=0, 30秒刷新)
-- ------------------------------------------------------------
DELETE FROM `gameobject` WHERE `id`=6201;
INSERT INTO `gameobject`
(`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,
 `position_x`,`position_y`,`position_z`,`orientation`,
 `rotation0`,`rotation1`,`rotation2`,`rotation3`,
 `spawntimesecs`,`animprogress`,`state`)
VALUES
(8101303,6201,0,0,0,1,1,-1513.6136,1371.3425,36.5378,6.1644,0,0,0.0594,-0.9982,30,100,1),
(8101304,6201,0,0,0,1,1,-1493.0854,1371.0236,36.5417,3.0228,0,0,0.9982,0.0594,30,100,1),
(8101305,6201,0,0,0,1,1,-1569.4862,1384.3234,36.9881,1.6483,0,0,0.734,0.6792,30,100,1),
(8101306,6201,0,0,0,1,1,-1563.4083,1409.7052,36.6445,0.0697,0,0,0.0348,0.9994,30,100,1),
(8101332,6201,0,0,0,1,1,-1463.7257,1445.0013,36.6446,4.5951,0,0,0.7473,-0.6644,30,100,1),
(8101333,6201,0,0,0,1,1,-1537.418,1444.9624,36.6446,4.7561,0,0,0.6915,-0.7224,30,100,1),
(8101334,6201,0,0,0,1,1,-1576.6106,1336.1992,36.5352,0.2126,0,0,0.1061,0.9944,30,100,1),
(8101335,6201,0,0,0,1,1,-1393.6466,1403.152,36.4233,3.1814,0,0,0.9998,-0.0199,30,100,1),
(8101336,6201,0,0,0,1,1,-1421.25,1412.4358,36.7945,1.4064,0,0,0.6467,0.7628,30,100,1);

-- ------------------------------------------------------------
-- 8. 9个被困市民实例 (放在各门内侧, 30秒刷新)
-- ------------------------------------------------------------
DELETE FROM `creature` WHERE `id1`=50105;
INSERT INTO `creature`
(`guid`,`id1`,`map`,`zoneId`,`areaId`,`spawnMask`,`phaseMask`,`equipment_id`,
 `position_x`,`position_y`,`position_z`,`orientation`,
 `spawntimesecs`,`wander_distance`,`curhealth`,`curmana`,`MovementType`)
VALUES
(10001501,50105,0,0,0,1,1,0,-1515.5959,1371.578,36.54,6.164,30,0,1,0,0),
(10001502,50105,0,0,0,1,1,0,-1491.104,1370.783,36.54,3.023,30,0,1,0,0),
(10001503,50105,0,0,0,1,1,0,-1569.3361,1382.326,36.99,1.648,30,0,1,0,0),
(10001504,50105,0,0,0,1,1,0,-1565.405,1409.5699,36.64,0.07,30,0,1,0,0),
(10001505,50105,0,0,0,1,1,0,-1463.496,1446.986,36.64,4.595,30,0,1,0,0),
(10001506,50105,0,0,0,1,1,0,-1537.507,1446.958,36.64,4.756,30,0,1,0,0),
(10001507,50105,0,0,0,1,1,0,-1578.5649,1335.777,36.54,0.213,30,0,1,0,0),
(10001508,50105,0,0,0,1,1,0,-1391.652,1403.229,36.42,3.181,30,0,1,0,0),
(10001509,50105,0,0,0,1,1,0,-1421.578,1410.467,36.79,1.406,30,0,1,0,0);
