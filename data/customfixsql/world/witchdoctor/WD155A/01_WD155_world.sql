-- WD155 additive. Current core direct/periodic Damage/Heal HIT stages explicit.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd155_world$$
CREATE PROCEDURE reborn_wd155_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004120 AND 9004124 AND ScriptName NOT IN('WD155::mojo','spell_reborn_wd44a_mass_allcure')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD155 script conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9004120 AND (ProcFlags<>349524 OR SpellTypeMask<>3 OR SpellPhaseMask<>2 OR Chance<>100 OR Cooldown<>0 OR Charges<>0 OR AttributesMask<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD155 proc conflict';END IF;
 INSERT INTO spell_script_names SELECT 9004120,'WD155::mojo' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004120 AND ScriptName='WD155::mojo');
 INSERT INTO spell_script_names SELECT 9004124,'spell_reborn_wd44a_mass_allcure' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004124 AND ScriptName='spell_reborn_wd44a_mass_allcure');
 INSERT INTO spell_proc(SpellId,ProcFlags,SpellTypeMask,SpellPhaseMask,Chance,Cooldown)VALUES(9004120,349524,3,2,100,0)ON DUPLICATE KEY UPDATE SpellPhaseMask=VALUES(SpellPhaseMask);
END$$
CALL reborn_wd155_world()$$
DROP PROCEDURE reborn_wd155_world$$
DELIMITER ;
