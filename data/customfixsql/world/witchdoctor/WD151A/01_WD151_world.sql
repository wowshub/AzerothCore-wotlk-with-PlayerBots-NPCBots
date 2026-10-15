-- WD151 additive script bindings and per-effect AP exclusion.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd151_world$$
CREATE PROCEDURE reborn_wd151_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004090 AND 9004095 AND ScriptName NOT IN('WD151::misery')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD151 ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004094 AND (comments IS NULL OR comments<>'WD151 manual Misery')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD151 coefficient conflict';END IF;
 IF NOT EXISTS(SELECT 1 FROM spell_group WHERE id=1029) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD151 requires base percent-AP group1029';END IF;
 IF EXISTS(SELECT 1 FROM spell_group WHERE id=909151 AND spell_id NOT IN(-1029,9004095)) OR EXISTS(SELECT 1 FROM spell_group_stack_rules WHERE group_id=909151 AND (stack_rule<>3 OR description<>'WD151 same-effect raid AP')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD151 AP group conflict';END IF;
 INSERT INTO spell_script_names SELECT 9003560,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003560 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003561,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003561 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003562,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003562 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003563,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003563 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003564,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003564 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003565,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003565 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003566,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003566 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003567,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003567 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003568,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003568 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003569,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003569 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003570,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003570 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003571,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003571 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003572,'WD151::dark' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003572 AND ScriptName='WD151::dark');
 INSERT INTO spell_script_names SELECT 9003220,'WD151::latent' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003220 AND ScriptName='WD151::latent');
 INSERT INTO spell_script_names SELECT 9003221,'WD151::latent' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003221 AND ScriptName='WD151::latent');
 INSERT INTO spell_script_names SELECT 9003222,'WD151::latent' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003222 AND ScriptName='WD151::latent');
 INSERT INTO spell_script_names SELECT 9003223,'WD151::latent' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003223 AND ScriptName='WD151::latent');
 INSERT INTO spell_script_names SELECT 9003224,'WD151::latent' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003224 AND ScriptName='WD151::latent');
 INSERT INTO spell_script_names SELECT 9003225,'WD151::latent' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003225 AND ScriptName='WD151::latent');
 INSERT INTO spell_script_names SELECT 9004094,'WD151::misery' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004094 AND ScriptName='WD151::misery');
 INSERT INTO spell_script_names SELECT 9003210,'WD151::jinx_caps' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003210 AND ScriptName='WD151::jinx_caps');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)VALUES(9004094,0,0,0,0,'WD151 manual Misery') ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
 INSERT INTO spell_group(id,spell_id)VALUES(909151,-1029),(909151,9004095)ON DUPLICATE KEY UPDATE spell_id=VALUES(spell_id);
 INSERT INTO spell_group_stack_rules(group_id,stack_rule,description)VALUES(909151,3,'WD151 same-effect raid AP')ON DUPLICATE KEY UPDATE stack_rule=VALUES(stack_rule);
END$$
CALL reborn_wd151_world()$$
DROP PROCEDURE reborn_wd151_world$$
DELIMITER ;
