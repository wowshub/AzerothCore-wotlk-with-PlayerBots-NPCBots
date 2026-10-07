-- WORLD only. WD135 Spirit Link; reuse the accepted native Spirit Idol model.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd135_world$$
CREATE PROCEDURE reborn_wd135_world()
BEGIN
 IF NOT EXISTS(SELECT 1 FROM creature_template WHERE entry=900192) OR NOT EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900192 AND Idx=0) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD135 requires installed Spirit Idol 900192';END IF;
 IF EXISTS(SELECT 1 FROM creature_template WHERE entry=900232 AND ScriptName<>'npc_reborn_wd135_link') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD135 creature ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_template_model n WHERE n.CreatureID=900232 AND (n.Idx<>0 OR n.CreatureDisplayID<>(SELECT CreatureDisplayID FROM creature_template_model WHERE CreatureID=900192 AND Idx=0))) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD135 display ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003953 AND ScriptName<>'spell_reborn_wd135_link') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD135 spell ownership conflict';END IF;
 INSERT INTO creature_template(entry,name,minlevel,maxlevel,faction,unit_class,type,BaseAttackTime,RangeAttackTime,unit_flags,ExperienceModifier,RegenHealth,ScriptName)
 VALUES(900232,'Spirit Link Idol',50,50,35,1,11,2000,2000,0,0,0,'npc_reborn_wd135_link')
 ON DUPLICATE KEY UPDATE name=VALUES(name),ScriptName=VALUES(ScriptName);
 INSERT INTO creature_template_model(CreatureID,Idx,CreatureDisplayID,DisplayScale,Probability)
 SELECT 900232,0,CreatureDisplayID,DisplayScale,1 FROM creature_template_model WHERE CreatureID=900192 AND Idx=0
 ON DUPLICATE KEY UPDATE CreatureDisplayID=VALUES(CreatureDisplayID),DisplayScale=VALUES(DisplayScale),Probability=1;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003953,'spell_reborn_wd135_link');
END$$
CALL reborn_wd135_world()$$
DROP PROCEDURE reborn_wd135_world$$
DELIMITER ;
