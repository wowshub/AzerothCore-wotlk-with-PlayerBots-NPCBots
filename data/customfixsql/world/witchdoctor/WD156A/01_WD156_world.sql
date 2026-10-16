-- WD156 exact owned bindings and proc phases.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd156_world$$
CREATE PROCEDURE reborn_wd156_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004130 AND 9004135 AND ScriptName NOT IN('WD156::eye','WD156::mark','WD156::frenzy','WD156::buff')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD156 script conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9004130 AND (ProcFlags<>349524 OR SpellTypeMask<>1 OR SpellPhaseMask<>2 OR HitMask<>2 OR Chance<>100 OR Charges<>0 OR Cooldown<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD156 proc conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9004134 AND (ProcFlags<>349524 OR SpellTypeMask<>1 OR SpellPhaseMask<>2 OR HitMask<>0 OR Chance<>100 OR Charges<>0 OR Cooldown<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD156 proc conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004135 AND comments<>'WD156 actual damage heal') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD156 heal conflict';END IF;
 INSERT INTO spell_script_names SELECT 9004130,'WD156::eye' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004130 AND ScriptName='WD156::eye');
 INSERT INTO spell_script_names SELECT 9004132,'WD156::frenzy' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004132 AND ScriptName='WD156::frenzy');
 INSERT INTO spell_script_names SELECT 9004133,'WD156::mark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004133 AND ScriptName='WD156::mark');
 INSERT INTO spell_script_names SELECT 9004134,'WD156::buff' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004134 AND ScriptName='WD156::buff');
 INSERT INTO spell_proc(SpellId,ProcFlags,SpellTypeMask,SpellPhaseMask,HitMask,Chance)VALUES(9004130,349524,1,2,2,100)ON DUPLICATE KEY UPDATE Chance=VALUES(Chance);
 INSERT INTO spell_proc(SpellId,ProcFlags,SpellTypeMask,SpellPhaseMask,HitMask,Chance)VALUES(9004134,349524,1,2,0,100)ON DUPLICATE KEY UPDATE Chance=VALUES(Chance);
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)VALUES(9004135,0,0,0,0,'WD156 actual damage heal')ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd156_world()$$
DROP PROCEDURE reborn_wd156_world$$
DELIMITER ;
