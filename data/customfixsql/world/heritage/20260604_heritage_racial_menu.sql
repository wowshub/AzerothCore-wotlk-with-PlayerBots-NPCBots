-- ============================================================
-- 遗产种族技能菜单 (Heritage Horizons) - 数据库部分
-- 日期: 2026-06-04
-- 功能: 玩家自选种族技能的AIO菜单。为多种族(地精/熊猫人/高等精灵)技能打基础。
--
-- 注意: 主体实现是 AIO Lua 脚本(不在SQL里):
--   - lua_scripts/AIO_Server/racialServer.lua  (服务端逻辑)
--   - lua_scripts/AIO_Server/racialClient.lua  (客户端UI,AIO自动推送)
--   - lua_scripts/AIO_Server/AIO.lua           (改了RegisterEvent:重复注册改成覆盖)
--   这些Lua文件来自 /media/bealien15u/juan2black/0000/000老外/lua_scripts/AIO_Server/
--
-- 本SQL只含数据库部分:菜单NPC + 召唤大胖的生物 + 玩家选择记录表
-- ============================================================

-- ------------------------------------------------------------
-- 1. 玩家种族技能选择记录表 (acore_characters库)
--    注意:这条要在 acore_characters 库执行!
-- ------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS `player_swapped_racial` (
--   `guid` int unsigned NOT NULL,
--   `race_id` int unsigned NOT NULL,
--   PRIMARY KEY (`guid`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ------------------------------------------------------------
-- 2. 遗产菜单NPC 98888 Vorthelas (acore_world库)
--    npcflag=3(可对话), Lua脚本RegisterCreatureEvent需要它存在
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry`=98888;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`faction`,`npcflag`,`minlevel`,`maxlevel`,`unit_class`,
 `DamageModifier`,`HealthModifier`,`AIName`,`MovementType`,`flags_extra`,`RegenHealth`)
VALUES
(98888,'Vorthelas','Heritage Horizons',35,3,80,80,2,1,1,'',0,2,1);

DELETE FROM `creature_template_model` WHERE `CreatureID`=98888;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (98888,0,18258,1.0,1.0);

-- ------------------------------------------------------------
-- 3. 召唤大胖(呼叫大胖69046)召唤的生物 36613 Gobber
--    npcflag=131072(银行家), 大胖能开银行
--    模型32385(胖食人魔,符合"大胖"人设)需补model_info否则显示错误模型
-- ------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry`=36613;
INSERT INTO `creature_template`
(`entry`,`name`,`subname`,`faction`,`npcflag`,`minlevel`,`maxlevel`,`unit_class`,
 `DamageModifier`,`HealthModifier`,`AIName`,`MovementType`,`flags_extra`,`RegenHealth`)
VALUES
(36613,'Gobber','大胖',35,131072,1,1,1,1,1,'',0,2,1);

DELETE FROM `creature_template_model` WHERE `CreatureID`=36613;
INSERT INTO `creature_template_model` (`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`)
VALUES (36613,0,32385,1.0,1.0);

-- 模型32385缺model_info会回退默认模型(显示成兽人),必须补碰撞数据
DELETE FROM `creature_model_info` WHERE `DisplayID`=32385;
INSERT INTO `creature_model_info` (`DisplayID`,`BoundingRadius`,`CombatReach`,`Gender`)
VALUES (32385,0.306,1.5,0);
