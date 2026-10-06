-- Fix for Vincent in Shadowfang Keep (Entry 4444)
-- Rationale: This NPC is a decoration 'corpse' with 1 HP. AoE damage can aggro him, causing a 1-HP immortal combat bug.
-- This SQL makes him non-attackable and non-selectable to prevent accidental aggro.
-- [CUSTOM FIX] - 2026-05-16

-- Flag 2: UNIT_FLAG_NON_ATTACKABLE
-- Flag 33554432: UNIT_FLAG_NOT_SELECTABLE
UPDATE `creature_template` SET `unit_flags` = `unit_flags` | 2 | 33554432, `dynamicflags` = 0, `AIName` = '', `ScriptName` = '' WHERE `entry` = 4444;
