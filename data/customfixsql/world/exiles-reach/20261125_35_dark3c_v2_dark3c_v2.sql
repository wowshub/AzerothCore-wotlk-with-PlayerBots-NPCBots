-- DARK3C V2 (2026-11-25, Claude) - candidate, NOT user-tested. Replaces DARK3C V1's SQL (V1 failed: Unknown column 'InhabitType', this core keeps movement in a separate table).
-- Flight movement for the dungeon-interior creatures through `creature_template_movement`: Ground=1 (can walk), Swim=1, Flight=2 (CanFly).
-- A flyer chases in 3D at the target's height and never looks at the ground (the interior has no vmap/mmap, so ground creatures drop to the terrain below).
-- Safe to run twice. Restart the server after.
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (157300, 156814, 156501, 9159801, 9159802, 9159803);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`) VALUES
(157300, 1, 1, 2), (156814, 1, 1, 2), (156501, 1, 1, 2), (9159801, 1, 1, 2), (9159802, 1, 1, 2), (9159803, 1, 1, 2);
SELECT * FROM `creature_template_movement` WHERE `CreatureId` IN (157300, 156814, 156501, 9159801, 9159802, 9159803);
