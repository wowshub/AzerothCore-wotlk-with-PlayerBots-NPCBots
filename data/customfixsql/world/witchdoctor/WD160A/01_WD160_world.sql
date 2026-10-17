-- WD160 independent owned summon groups, native primary pet untouched.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd160_world$$
CREATE PROCEDURE reborn_wd160_world()
BEGIN
 IF NOT EXISTS(SELECT 1 FROM creature_template WHERE entry=900190) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 needs base serpent';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004180 AND 9004185 AND ScriptName NOT IN('WD160::summon','WD160::blast')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 spell conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004183 AND comments<>'WD160 Hexfire Blast scripted RAP once') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 bonus conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_template WHERE entry=900255 AND (name<>'毒蛇守卫' OR ScriptName<>'npc_reborn_wd160_viper')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 creature conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900255 AND (Idx<>0 OR CreatureDisplayID<>891160 OR DisplayScale<>1)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 model conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_template WHERE entry=900256 AND (name<>'愚者把戏' OR ScriptName<>'npc_reborn_wd160_fool')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 creature conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900256 AND (Idx<>0 OR CreatureDisplayID<>11686 OR DisplayScale<>1)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 model conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_model_info WHERE DisplayID=891160 AND (ABS(BoundingRadius-0.3)>0.00001 OR ABS(CombatReach-1)>0.00001 OR Gender<>2)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD160 model-info conflict';END IF;
 DROP TEMPORARY TABLE IF EXISTS reborn_wd160_tmp;
 CREATE TEMPORARY TABLE reborn_wd160_tmp LIKE creature_template;
 DELETE FROM reborn_wd160_tmp;INSERT INTO reborn_wd160_tmp SELECT * FROM creature_template WHERE entry=900190;UPDATE reborn_wd160_tmp SET entry=900255,name='毒蛇守卫',subname='',ScriptName='npc_reborn_wd160_viper',AIName='',npcflag=0,unit_flags=0,unit_flags2=0,flags_extra=0,type=11,type_flags=type_flags|4096;INSERT INTO creature_template SELECT * FROM reborn_wd160_tmp WHERE NOT EXISTS(SELECT 1 FROM creature_template WHERE entry=900255);
 DELETE FROM reborn_wd160_tmp;INSERT INTO reborn_wd160_tmp SELECT * FROM creature_template WHERE entry=900190;UPDATE reborn_wd160_tmp SET entry=900256,name='愚者把戏',subname='',ScriptName='npc_reborn_wd160_fool',AIName='',npcflag=0,unit_flags=0,unit_flags2=0,flags_extra=0,type=11,type_flags=type_flags|4096;INSERT INTO creature_template SELECT * FROM reborn_wd160_tmp WHERE NOT EXISTS(SELECT 1 FROM creature_template WHERE entry=900256);
 DROP TEMPORARY TABLE reborn_wd160_tmp;
 INSERT INTO creature_template_model(CreatureID,Idx,CreatureDisplayID,DisplayScale,Probability,VerifiedBuild)SELECT 900255,0,891160,1,1,12340 WHERE NOT EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900255);
 INSERT INTO creature_template_model(CreatureID,Idx,CreatureDisplayID,DisplayScale,Probability,VerifiedBuild)SELECT 900256,0,11686,1,1,12340 WHERE NOT EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900256);
 INSERT INTO creature_model_info(DisplayID,BoundingRadius,CombatReach,Gender)SELECT 891160,0.3,1,2 WHERE NOT EXISTS(SELECT 1 FROM creature_model_info WHERE DisplayID=891160);
 INSERT INTO spell_script_names SELECT 9004181,'WD160::summon' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004181 AND ScriptName='WD160::summon');
 INSERT INTO spell_script_names SELECT 9004182,'WD160::summon' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004182 AND ScriptName='WD160::summon');
 INSERT INTO spell_script_names SELECT 9004183,'WD160::blast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004183 AND ScriptName='WD160::blast');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)VALUES(9004183,0,0,0,0,'WD160 Hexfire Blast scripted RAP once')ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd160_world()$$
DROP PROCEDURE reborn_wd160_world$$
DELIMITER ;
