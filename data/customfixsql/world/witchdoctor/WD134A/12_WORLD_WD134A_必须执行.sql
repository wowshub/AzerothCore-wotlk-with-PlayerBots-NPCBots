-- WORLD database only. WD134; guarded private IDs, preserve previous script bindings.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd134_world$$
CREATE PROCEDURE reborn_wd134_world()
BEGIN
 IF EXISTS(SELECT 1 FROM creature_template WHERE entry=900231 AND ScriptName<>'npc_reborn_wd134_cauldron') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD134 creature entry ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900231 AND (CreatureDisplayID<>900231 OR Idx<>0)) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD134 creature model ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_model_info WHERE DisplayID=900231 AND (VerifiedBuild IS NULL OR VerifiedBuild<>134)) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD134 model info ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN(9003949,9003952) AND (comments IS NULL OR comments NOT LIKE 'WD134%')) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD134 coefficient ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE
 (spell_id=9003947 AND ScriptName<>'spell_reborn_wd134_cauldron') OR
 (spell_id IN(9003949,9003952) AND ScriptName<>'spell_reborn_wd134_heal')) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD134 script ownership conflict';END IF;
 INSERT INTO creature_template(entry,name,minlevel,maxlevel,faction,unit_class,type,BaseAttackTime,RangeAttackTime,unit_flags,ScriptName)
 VALUES(900231,'Voodoo Cauldron',57,57,35,1,11,2000,2000,33554434,'npc_reborn_wd134_cauldron')
 ON DUPLICATE KEY UPDATE name=VALUES(name),ScriptName=VALUES(ScriptName);
 INSERT INTO creature_template_model(CreatureID,Idx,CreatureDisplayID,DisplayScale,Probability) VALUES(900231,0,900231,1,1)
 ON DUPLICATE KEY UPDATE CreatureDisplayID=VALUES(CreatureDisplayID),DisplayScale=1,Probability=1;
 INSERT INTO creature_model_info(DisplayID,BoundingRadius,CombatReach,Gender,DisplayID_Other_Gender,VerifiedBuild) VALUES(900231,0.5,1,2,0,134)
 ON DUPLICATE KEY UPDATE BoundingRadius=0.5,CombatReach=1,Gender=2,DisplayID_Other_Gender=0,VerifiedBuild=134;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES
(9003947,'spell_reborn_wd134_cauldron'),
(9003949,'spell_reborn_wd134_heal'),
(9003952,'spell_reborn_wd134_heal'),
(9003101,'spell_reborn_wd134_unstable'),
(9003130,'spell_reborn_wd134_unstable'),
(9003131,'spell_reborn_wd134_unstable'),
(9003132,'spell_reborn_wd134_unstable'),
(9003133,'spell_reborn_wd134_unstable'),
(9003134,'spell_reborn_wd134_unstable'),
(9003135,'spell_reborn_wd134_unstable'),
(9003136,'spell_reborn_wd134_unstable'),
(9003137,'spell_reborn_wd134_unstable'),
(9003138,'spell_reborn_wd134_unstable'),
(9003460,'spell_reborn_wd134_unstable'),
(9003461,'spell_reborn_wd134_unstable'),
(9003462,'spell_reborn_wd134_unstable'),
(9003463,'spell_reborn_wd134_unstable'),
(9003464,'spell_reborn_wd134_unstable'),
(9003465,'spell_reborn_wd134_unstable'),
(9003466,'spell_reborn_wd134_unstable'),
(9003467,'spell_reborn_wd134_unstable'),
(9003870,'spell_reborn_wd134_unstable'),
(9003871,'spell_reborn_wd134_unstable'),
(9003872,'spell_reborn_wd134_unstable'),
(9003873,'spell_reborn_wd134_unstable'),
(9003874,'spell_reborn_wd134_unstable'),
(9003875,'spell_reborn_wd134_unstable'),
(9003876,'spell_reborn_wd134_unstable');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES
 (9003949,0,0,0,0,'WD134 Cauldron 0.60 bonus healing applied in script once'),
 (9003952,0,0,0,0,'WD134 Unstable 0.40 bonus healing applied in script once')
 ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0,comments=VALUES(comments);
END$$
CALL reborn_wd134_world()$$
DROP PROCEDURE reborn_wd134_world$$
DELIMITER ;
