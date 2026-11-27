-- HARA3 V2 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, WORLD database, after world_hara3.sql (V1). Safe to run twice.
-- Cause: retail marks the Lashroom Bud as creature type 8 (critter). The core gives every critter the critter AI: it runs away when hit, never
-- fights back and gives no experience. Type 4 (like the other lashers) makes it a normal neutral monster.
SET NAMES utf8mb4;
UPDATE `creature_template` SET `type` = 4 WHERE `entry` = 237036;
SELECT `entry`, `type` AS must_be_4, `faction` AS must_be_7,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (237036, 237623, 240344, 240656, 240871, 248493) AND `type` = 8) AS critters_left_must_be_0
FROM `creature_template` WHERE `entry` = 237036;
