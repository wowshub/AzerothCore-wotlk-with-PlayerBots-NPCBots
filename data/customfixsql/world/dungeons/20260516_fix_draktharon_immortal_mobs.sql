-- Fix for immortal mobs in Drak'Tharon Keep
-- Affected Entries: 26630 (Drakkari Risen Warrior), 26635 (Drakkari Risen Witch Doctor), 26620 (Drakkari Risen Defender)
-- Rationale: These mobs often get stuck at 1 HP due to broken SmartAI scripts or flags.
-- This SQL removes the invulnerability flag (if any) and clears problematic SmartAI scripts.

UPDATE `creature_template` SET `unit_flags` = `unit_flags` & ~256, `unit_flags` = `unit_flags` & ~2, `dynamicflags` = 0, `AIName` = '', `ScriptName` = '' WHERE `entry` IN (26630, 26635, 26620);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (26630, 26635, 26620);
