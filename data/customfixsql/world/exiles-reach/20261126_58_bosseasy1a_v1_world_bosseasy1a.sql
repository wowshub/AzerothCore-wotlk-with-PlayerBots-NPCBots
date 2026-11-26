-- BOSSEASY1A V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- Tunk 157300, Gor'groth 156814 and the boss Kalecgos 156501 become ordinary level 9 monsters. Needs lua_scripts/Dark2A.lua from this package.
-- ExperienceModifier 4 keeps their kill experience about where it was without the elite bonus.
SELECT `entry`, `name`, `minlevel`, `maxlevel`, `rank`, `HealthModifier`, `DamageModifier`, `ExperienceModifier` FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501) ORDER BY `entry`;
UPDATE `creature_template` SET `minlevel` = 9, `maxlevel` = 9, `rank` = 0, `HealthModifier` = 2, `DamageModifier` = 0.5, `ExperienceModifier` = 4 WHERE `entry` IN (157300, 156814, 156501);
SELECT `entry`, `name`, `minlevel`, `maxlevel`, `rank`, `HealthModifier`, `DamageModifier`, `ExperienceModifier` FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501) ORDER BY `entry`;
SELECT COUNT(*) AS ordinary_bosses_must_be_3 FROM `creature_template` WHERE `entry` IN (157300, 156814, 156501) AND `rank` = 0 AND `maxlevel` = 9 AND `HealthModifier` = 2;
