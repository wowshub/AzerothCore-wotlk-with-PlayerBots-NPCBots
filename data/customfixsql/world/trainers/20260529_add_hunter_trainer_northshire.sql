-- 在人族出生地(北郡山谷)白马(guid 79943)右前方添加猎人训练师
-- NPC: 恩瑞斯·锐矛 <猎人训练师> entry=5515
-- Map: 0, 坐标: X=-8928, Y=-160, Z=81.03

DELETE FROM `creature` WHERE `guid` IN (5300747, 5300748, 5300749, 5300750);
INSERT INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`) VALUES
(5300750, 5515, 0, 0, 0, 0, 0, 1, 1, 1, -8928, -160, 81.03, 2.79253, 300, 0, 0, 1, 0, 0, 0, 0, 0);
