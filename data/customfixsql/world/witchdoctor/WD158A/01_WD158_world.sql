-- WD158 exact owned bindings; native Senjin stat auras require no dummy script.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd158_world$$
CREATE PROCEDURE reborn_wd158_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004160 AND 9004164 AND ScriptName NOT IN('WD158::talent','WD158::ready','WD158::umbral','WD158::leech','WD158::shock')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD158 script conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9004160 AND (ProcFlags<>320 OR SpellTypeMask<>1 OR SpellPhaseMask<>2 OR Chance<>100 OR Cooldown<>0 OR Charges<>0 OR HitMask<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD158 proc conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004164 AND comments<>'WD158 Umbral scripted RAP before native multipliers') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD158 bonus conflict';END IF;
 INSERT INTO spell_script_names SELECT 9004160,'WD158::talent' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004160 AND ScriptName='WD158::talent');
 INSERT INTO spell_script_names SELECT 9004163,'WD158::ready' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004163 AND ScriptName='WD158::ready');
 INSERT INTO spell_script_names SELECT 9004164,'WD158::umbral' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004164 AND ScriptName='WD158::umbral');
 INSERT INTO spell_script_names SELECT 9004164,'WD158::leech' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004164 AND ScriptName='WD158::leech');
 INSERT INTO spell_script_names SELECT 9004162,'WD158::shock' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004162 AND ScriptName='WD158::shock');
 INSERT INTO spell_proc(SpellId,ProcFlags,SpellTypeMask,SpellPhaseMask,Chance)VALUES(9004160,320,1,2,100)ON DUPLICATE KEY UPDATE Chance=VALUES(Chance);
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)VALUES(9004164,0,0,0,0,'WD158 Umbral scripted RAP before native multipliers')ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd158_world()$$
DROP PROCEDURE reborn_wd158_world$$
DELIMITER ;
