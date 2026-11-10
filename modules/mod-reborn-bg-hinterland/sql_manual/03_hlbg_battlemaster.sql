-- HLBG1A: a plain battlemaster NPC for the Hinterland BG. The core opens the battleground list for any creature with the
-- battlemaster flag whose entry is mapped in `battlemaster_entry`; no script is needed.
-- Spawn it with:  .npc add 900001     (GM, where you want it)
DELETE FROM `creature_template` WHERE `entry` = 900001;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `VerifiedBuild`) VALUES
(900001, 'Hinterland BG Battlemaster', 'Battleground', 80, 80, 35, 1048576, 1, 1.14286, 1, 2, 7, 1, 1, 1, 1, 1, 1, 2, 12340);
DELETE FROM `creature_template_model` WHERE `CreatureID` = 900001;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(900001, 0, 16345, 1, 100, 12340);
DELETE FROM `battlemaster_entry` WHERE `entry` = 900001;
INSERT INTO `battlemaster_entry` (`entry`, `bg_template`) VALUES (900001, 20);