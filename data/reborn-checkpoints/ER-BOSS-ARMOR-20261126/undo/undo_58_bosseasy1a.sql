-- BOSSEASY1A V1 undo: values of DARK2A + XP1A. Stop worldserver, run, restore the old Dark2A.lua, restart.
UPDATE `creature_template` SET `minlevel` = 10, `maxlevel` = 10, `rank` = 1, `HealthModifier` = 8, `DamageModifier` = 0.9, `ExperienceModifier` = 2 WHERE `entry` = 157300;
UPDATE `creature_template` SET `minlevel` = 11, `maxlevel` = 11, `rank` = 1, `HealthModifier` = 10, `DamageModifier` = 0.9, `ExperienceModifier` = 2 WHERE `entry` = 156814;
UPDATE `creature_template` SET `minlevel` = 12, `maxlevel` = 12, `rank` = 1, `HealthModifier` = 12, `DamageModifier` = 0.9, `ExperienceModifier` = 2 WHERE `entry` = 156501;
SELECT `entry`, `name`, `minlevel`, `maxlevel`, `rank`, `HealthModifier`, `DamageModifier`, `ExperienceModifier` FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501) ORDER BY `entry`;
