-- WD153 additive effects; proc stage is explicit.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd153_world$$
CREATE PROCEDURE reborn_wd153_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004100 AND 9004104 AND ScriptName NOT IN('WD153::mass','WD153::summon')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD153 script conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004103 AND (comments IS NULL OR comments<>'WD153 final arrow damage snapshot')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD153 poison coefficient conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9004101 AND (ProcFlags<>262144 OR SpellTypeMask<>1 OR SpellPhaseMask<>2 OR Chance<>100 OR Cooldown<>3000 OR Charges<>0 OR AttributesMask<>0 OR SpellFamilyName<>0 OR SpellFamilyMask0<>0 OR SpellFamilyMask1<>0 OR SpellFamilyMask2<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD153 proc conflict';END IF;
 INSERT INTO spell_script_names SELECT 9003969,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003969 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003970,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003970 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003971,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003971 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003972,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003972 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003973,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003973 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003974,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003974 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003975,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003975 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003976,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003976 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003977,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003977 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9003978,'WD153::poison' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003978 AND ScriptName='WD153::poison');
 INSERT INTO spell_script_names SELECT 9004101,'WD153::mass' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004101 AND ScriptName='WD153::mass');
 INSERT INTO spell_script_names SELECT 9004104,'WD153::summon' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004104 AND ScriptName='WD153::summon');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)VALUES(9004103,0,0,0,0,'WD153 final arrow damage snapshot')ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
 INSERT INTO spell_proc(SpellId,ProcFlags,SpellTypeMask,SpellPhaseMask,Chance,Cooldown)VALUES(9004101,262144,1,2,100,3000)ON DUPLICATE KEY UPDATE SpellPhaseMask=VALUES(SpellPhaseMask);
END$$
CALL reborn_wd153_world()$$
DROP PROCEDURE reborn_wd153_world$$
DELIMITER ;
