-- VMAP12175A V1: with real ground data the dungeon creatures can walk normally again; remove the flying workaround of DARK3C V2. Safe to run twice.
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (157300, 156814, 156501, 9159801, 9159802, 9159803);
SELECT COUNT(*) AS rows_left_must_be_0 FROM `creature_template_movement` WHERE `CreatureId` IN (157300, 156814, 156501, 9159801, 9159802, 9159803);
