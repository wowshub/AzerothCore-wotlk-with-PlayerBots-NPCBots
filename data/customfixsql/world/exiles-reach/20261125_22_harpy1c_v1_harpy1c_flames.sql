-- HARPY1C V1 (2026-11-25, Claude) - candidate, NOT user-tested. A flame-only object shown on a burning Harpy Totem (display 192 = campfire flames), no script, no loot.
DELETE FROM `gameobject_template` WHERE `entry` = 9350804;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES (9350804, 5, 192, 'Totem Flames 图腾火焰', '', '', '', 1.6, 0, 0, '', '', 0);
SELECT COUNT(*) AS flame_template_must_be_1 FROM `gameobject_template` WHERE `entry` = 9350804;
