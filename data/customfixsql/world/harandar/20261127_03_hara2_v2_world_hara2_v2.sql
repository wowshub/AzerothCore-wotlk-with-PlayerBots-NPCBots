-- HARA2 V2 (2026-11-26, Claude) - candidate, NOT user-tested. WORLD database. Run after world_hara2.sql (V1). Safe to run twice.
-- Cause: a goober with Data3 (auto close, milliseconds) = 0 is never deactivated by the core, so Data5 (consumable) never acts.
-- Data3 = 1500: the first click counts, the object is locked, vanishes after 1.5 s and returns after its spawn time (30 s).
SET NAMES utf8mb4;
UPDATE `gameobject_template` SET `Data3` = 1500, `castBarCaption` = 'Clearing 清除中' WHERE `entry` = 553763;
UPDATE `gameobject_template` SET `castBarCaption` = 'Communing 交感中' WHERE `entry` IN (554679, 546728, 554848, 554966);
SELECT `entry`, `Data1` AS quest_must_be_90958, `Data3` AS must_be_1500, `Data5` AS must_be_1,
       (SELECT COUNT(*) FROM `gameobject` WHERE `id` = 553763 AND `spawntimesecs` = 30) AS spawns_expect_6_or_more
FROM `gameobject_template` WHERE `entry` = 553763;
