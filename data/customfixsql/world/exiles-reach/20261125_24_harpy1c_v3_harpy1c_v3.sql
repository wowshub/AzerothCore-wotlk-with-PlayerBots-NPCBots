-- HARPY1C V3 (2026-11-25, Claude) - candidate, NOT user-tested. Self-contained.
-- V2 did not change the cursor and the clicked totem did not vanish (the core's "consumable" is not reliable). V3:
--  * new totem object 9350803 = an exact copy of the campfire 9174074 row (its cursor 'Cast' is user-verified), only display (695), name,
--    quest (Data1 = 59946) and cast bar text differ; the 5 totem spawns and the quest objective move to it
--  * Lua despawns the clicked totem itself (it respawns after 60 s) and leaves a plain burning copy meanwhile
-- Needs the campfire row 9174074 (BEACH1B/CAMP1A). Safe to run twice. Keep worldserver stopped, restart after.
DELETE FROM `gameobject_template` WHERE `entry` IN (9350803, 9350804, 9350805);
SELECT COUNT(*) AS campfire_row_must_be_1 FROM `gameobject_template` WHERE `entry` = 9174074;
DROP TEMPORARY TABLE IF EXISTS tmp_totem;
CREATE TEMPORARY TABLE tmp_totem AS SELECT * FROM `gameobject_template` WHERE `entry` = 9174074;
UPDATE tmp_totem SET `entry` = 9350803, `displayId` = 695, `name` = 'Harpy Totem 鹰身人图腾', `castBarCaption` = 'Burning 点燃中', `size` = 1, `Data1` = 59946;
INSERT INTO `gameobject_template` SELECT * FROM tmp_totem;
DROP TEMPORARY TABLE tmp_totem;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(9350804, 5, 192, 'Totem Flames 图腾火焰', '', '', '', 1.6, 0, 0, '', '', 0),
(9350805, 5, 695, 'Burning Harpy Totem 燃烧的鹰身人图腾', '', '', '', 1, 0, 0, '', '', 0);
UPDATE `gameobject` SET `id` = 9350803, `spawntimesecs` = 60 WHERE `id` IN (350803, 9350803) AND `map` = 12175;
UPDATE `quest_template` SET `RequiredNpcOrGo1` = -9350803 WHERE `ID` = 59946;
SELECT (SELECT `IconName` FROM `gameobject_template` WHERE `entry` = 9350803) AS cursor_must_be_Cast,
       (SELECT `type` FROM `gameobject_template` WHERE `entry` = 9350803) AS type_must_be_10,
       (SELECT `Data1` FROM `gameobject_template` WHERE `entry` = 9350803) AS quest_must_be_59946,
       (SELECT COUNT(*) FROM `gameobject` WHERE `id` = 9350803) AS totems_must_be_5,
       (SELECT `RequiredNpcOrGo1` FROM `quest_template` WHERE `ID` = 59946) AS objective_must_be_minus_9350803;
