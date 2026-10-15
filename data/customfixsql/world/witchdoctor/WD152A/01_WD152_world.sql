-- WD152 additive bindings, Traditionalist proc and same-effect haste exclusion.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd152_world$$
CREATE PROCEDURE reborn_wd152_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004096 AND 9004099 AND ScriptName<>'WD152::traditionalist') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD152 script ownership conflict';END IF;
 IF NOT EXISTS(SELECT 1 FROM spell_group WHERE id=1020) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD152 requires base haste group1020';END IF;
 IF EXISTS(SELECT 1 FROM spell_group WHERE id=909152 AND spell_id NOT IN(-1020,9004096)) OR EXISTS(SELECT 1 FROM spell_group_stack_rules WHERE group_id=909152 AND (stack_rule<>3 OR description<>'WD152 same-effect raid haste')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD152 haste group conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9004096 AND (ProcFlags<>262144 OR Chance<>100 OR Cooldown<>0 OR Charges<>0 OR SpellFamilyName<>0 OR SpellFamilyMask0<>0 OR SpellFamilyMask1<>0 OR SpellFamilyMask2<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD152 proc conflict';END IF;
 INSERT INTO spell_script_names SELECT 9004096,'WD152::traditionalist' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004096 AND ScriptName='WD152::traditionalist');
 INSERT INTO spell_script_names SELECT 9004000,'WD152::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004000 AND ScriptName='WD152::eclipse');
 INSERT INTO spell_script_names SELECT 9004001,'WD152::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004001 AND ScriptName='WD152::eclipse');
 INSERT INTO spell_script_names SELECT 9004002,'WD152::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004002 AND ScriptName='WD152::eclipse');
 INSERT INTO spell_script_names SELECT 9004003,'WD152::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004003 AND ScriptName='WD152::eclipse');
 INSERT INTO spell_script_names SELECT 9004004,'WD152::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004004 AND ScriptName='WD152::eclipse');
 INSERT INTO spell_script_names SELECT 9004005,'WD152::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004005 AND ScriptName='WD152::eclipse');
 INSERT INTO spell_script_names SELECT 9004006,'WD152::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004006 AND ScriptName='WD152::eclipse');
 INSERT INTO spell_proc(SpellId,ProcFlags,Chance)VALUES(9004096,262144,100) ON DUPLICATE KEY UPDATE Chance=VALUES(Chance);
 INSERT INTO spell_group(id,spell_id)VALUES(909152,-1020),(909152,9004096)ON DUPLICATE KEY UPDATE spell_id=VALUES(spell_id);
 INSERT INTO spell_group_stack_rules(group_id,stack_rule,description)VALUES(909152,3,'WD152 same-effect raid haste')ON DUPLICATE KEY UPDATE stack_rule=VALUES(stack_rule);
END$$
CALL reborn_wd152_world()$$
DROP PROCEDURE reborn_wd152_world$$
DELIMITER ;
