-- CAMP1A V3 (2026-11-24, Claude): campfire 9174074 cursor 'Cast' (glowing blue gauntlet). Safe to run twice.
UPDATE `gameobject_template` SET `IconName` = 'Cast' WHERE `entry` = 9174074;
SELECT `entry`, `name`, `IconName`, `castBarCaption`, `Data1` FROM `gameobject_template` WHERE `entry` = 9174074;
