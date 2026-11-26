-- HARPY1C V2 (2026-11-25, Claude) - candidate, NOT user-tested. Self-contained (includes the V1 flame object).
--  * Harpy Totem 350803: cursor 'Cast' (the glowing blue-edged gauntlet that worked for the campfire in CAMP1A V3), consumable (Data5=1):
--    once clicked it disappears (so its quest sparkle goes) and respawns after 60 s; the Lua summons a non-glowing copy that burns meanwhile.
--  * 9350804 flames (display 192), 9350805 plain copy of the totem model (display 695), both type 5 generic, no script.
DELETE FROM `gameobject_template` WHERE `entry` IN (9350804, 9350805);
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(9350804, 5, 192, 'Totem Flames 图腾火焰', '', '', '', 1.6, 0, 0, '', '', 0),
(9350805, 5, 695, 'Burning Harpy Totem 燃烧的鹰身人图腾', '', '', '', 1, 0, 0, '', '', 0);
UPDATE `gameobject_template` SET `IconName` = 'Cast', `Data5` = 1 WHERE `entry` = 350803;
UPDATE `gameobject` SET `spawntimesecs` = 60 WHERE `id` = 350803 AND `map` = 12175;
SELECT (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` IN (9350804, 9350805)) AS new_templates_must_be_2,
       (SELECT `IconName` FROM `gameobject_template` WHERE `entry` = 350803) AS cursor_must_be_Cast,
       (SELECT `Data5` FROM `gameobject_template` WHERE `entry` = 350803) AS consumable_must_be_1,
       (SELECT COUNT(*) FROM `gameobject` WHERE `id` = 350803 AND `spawntimesecs` = 60) AS totems_must_be_5;
