-- VEH1A V1 (2026-11-25, Claude) - candidate, NOT user-tested.
-- Retail-Horde 59942 "The Re-Deather": ride the Choppy Booster as a vehicle and bomb the Monstrous Cadavers (165150).
-- Method: clone the stock WotLK quest vehicle "Forsaken Blight Spreader" (entry 26523, quest 12218 Spread the Good Word)
--   creature_template + creature_template_model + creature_template_spell (48211 Blight Bomb) + npc_spellclick_spells (48296 ride)
--   + smart_scripts (despawn 6 s after the passenger leaves) into custom entry 9167020, set faction 35, and spawn one next to the Booster.
-- V1 keeps the stock Spreader model on purpose (its seat/attachment is known to fit); the Booster look comes after the mechanism works.
-- Quest 59942 already requires 165150 x6 + 162817 x1 (BEACH1C V2), no quest change here.
-- Safe to run twice. Needs the stock rows of entry 26523 (AzerothCore base data). Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;
SET @NEW := 9167020;
SET @SRC := 26523;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'VEH1A %';
DELETE FROM `creature_template` WHERE `entry` = @NEW;
DELETE FROM `creature_template_model` WHERE `CreatureID` = @NEW;
DELETE FROM `creature_template_spell` WHERE `CreatureID` = @NEW;
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = @NEW;
DELETE FROM `smart_scripts` WHERE `entryorguid` = @NEW AND `source_type` = 0;

SELECT COUNT(*) AS source_rows_found_must_be_1 FROM `creature_template` WHERE `entry` = @SRC;

DROP TEMPORARY TABLE IF EXISTS tmp_veh_ct;
CREATE TEMPORARY TABLE tmp_veh_ct AS SELECT * FROM `creature_template` WHERE `entry` = @SRC;
UPDATE tmp_veh_ct SET `entry` = @NEW, `name` = 'Choppy Booster Mk. 5 Gunship 斩切者助推器5型炮艇', `faction` = 35, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_veh_ct;
DROP TEMPORARY TABLE tmp_veh_ct;

INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`)
SELECT @NEW, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild` FROM `creature_template_model` WHERE `CreatureID` = @SRC;

INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`)
SELECT @NEW, `Index`, `Spell`, `VerifiedBuild` FROM `creature_template_spell` WHERE `CreatureID` = @SRC;

INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`)
SELECT @NEW, `spell_id`, `cast_flags`, `user_type` FROM `npc_spellclick_spells` WHERE `npc_entry` = @SRC;

DROP TEMPORARY TABLE IF EXISTS tmp_veh_sa;
CREATE TEMPORARY TABLE tmp_veh_sa AS SELECT * FROM `smart_scripts` WHERE `entryorguid` = @SRC AND `source_type` = 0;
UPDATE tmp_veh_sa SET `entryorguid` = @NEW, `comment` = REPLACE(`comment`, 'Forsaken Blight Spreader', 'Choppy Booster Gunship');
INSERT INTO `smart_scripts` SELECT * FROM tmp_veh_sa;
DROP TEMPORARY TABLE tmp_veh_sa;

SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 1 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS legal_max_guid;
-- next to the Choppy Booster (107.872, -2414.18, 95.4484); respawn 30 s after the old one despawned
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
VALUES (@g + 1, @NEW, 12175, 1, 1, 0, 113.0, -2410.0, 95.4484, 0.6, 30, 0, 0, 'VEH1A gunship (clone of Forsaken Blight Spreader 26523)');

-- read-back (all must be non-zero / 1)
SELECT (SELECT COUNT(*) FROM `creature_template` WHERE `entry` = @NEW) AS tmpl,
       (SELECT `VehicleId` FROM `creature_template` WHERE `entry` = @NEW) AS vehicle_id,
       (SELECT `npcflag` FROM `creature_template` WHERE `entry` = @NEW) AS npcflag,
       (SELECT COUNT(*) FROM `creature_template_model` WHERE `CreatureID` = @NEW) AS models,
       (SELECT COUNT(*) FROM `creature_template_spell` WHERE `CreatureID` = @NEW) AS bar_spells,
       (SELECT COUNT(*) FROM `npc_spellclick_spells` WHERE `npc_entry` = @NEW) AS spellclick,
       (SELECT COUNT(*) FROM `smart_scripts` WHERE `entryorguid` = @NEW AND `source_type` = 0) AS smart,
       (SELECT COUNT(*) FROM `creature` WHERE `id1` = @NEW) AS spawned;
