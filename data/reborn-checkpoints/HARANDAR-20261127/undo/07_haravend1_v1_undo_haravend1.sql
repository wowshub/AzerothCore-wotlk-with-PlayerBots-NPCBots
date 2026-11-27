-- undo HARAVEND1
DELETE FROM `creature` WHERE `map` = 12694 AND `Comment` LIKE 'HARAVEND %';
DELETE FROM `creature_template` WHERE `entry` IN (252203, 252211, 258354);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (252203, 252211, 258354);
DELETE FROM `npc_vendor` WHERE `entry` IN (252203, 252211, 258354);
