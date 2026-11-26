-- CAMP1A V2 (2026-11-24, Claude): campfire 9174074 cursor 'Point' (the gauntlet hand). V1 used 'LootAll' which is a pile of coin bags, not a hand. Safe to run twice.
UPDATE `gameobject_template` SET `IconName` = 'Point' WHERE `entry` = 9174074;
SELECT `entry`, `name`, `IconName`, `castBarCaption`, `Data1` FROM `gameobject_template` WHERE `entry` = 9174074;
