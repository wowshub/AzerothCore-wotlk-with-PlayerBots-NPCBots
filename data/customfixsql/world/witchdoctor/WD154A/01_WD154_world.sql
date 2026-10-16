-- WD154 additive; requires installed snake template900190, preserve all prior SQL.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd154_world$$
CREATE PROCEDURE reborn_wd154_world()
BEGIN
 IF NOT EXISTS(SELECT 1 FROM creature_template WHERE entry=900190) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD154 requires existing snake template';END IF;
 IF NOT EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900190) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD154 requires existing source models';END IF;
 IF EXISTS(SELECT 1 FROM creature_template_model d WHERE d.CreatureID=900254 AND NOT EXISTS(SELECT 1 FROM creature_template_model s WHERE s.CreatureID=900190 AND s.Idx=d.Idx AND s.CreatureDisplayID=d.CreatureDisplayID AND s.DisplayScale=d.DisplayScale AND s.Probability=d.Probability)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD154 clone model conflict';END IF;
 IF EXISTS(SELECT 1 FROM creature_template WHERE entry=900254 AND (ScriptName<>'npc_reborn_wd154_mirage' OR name<>'幻象分身')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD154 creature conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004110 AND 9004114 AND ScriptName NOT IN('WD154::cast','WD154::aura')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD154 script conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9004110 AND (ProcFlags<>87380 OR SpellTypeMask<>3 OR SpellPhaseMask<>2 OR Chance<>100 OR Cooldown<>0 OR Charges<>0 OR AttributesMask<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD154 proc conflict';END IF;
 DROP TEMPORARY TABLE IF EXISTS reborn_wd154_clone_tmp;
 CREATE TEMPORARY TABLE reborn_wd154_clone_tmp LIKE creature_template;
 INSERT INTO reborn_wd154_clone_tmp SELECT * FROM creature_template WHERE entry=900190;
 UPDATE reborn_wd154_clone_tmp SET entry=900254,name='幻象分身',subname='',ScriptName='npc_reborn_wd154_mirage',AIName='',npcflag=0,unit_flags=0,unit_flags2=0,flags_extra=0,type=7;
 INSERT INTO creature_template SELECT * FROM reborn_wd154_clone_tmp WHERE NOT EXISTS(SELECT 1 FROM creature_template WHERE entry=900254);
 DROP TEMPORARY TABLE reborn_wd154_clone_tmp;
 INSERT INTO creature_template_model(CreatureID,Idx,CreatureDisplayID,DisplayScale,Probability,VerifiedBuild) SELECT 900254,s.Idx,s.CreatureDisplayID,s.DisplayScale,s.Probability,s.VerifiedBuild FROM creature_template_model s WHERE s.CreatureID=900190 AND NOT EXISTS(SELECT 1 FROM creature_template_model d WHERE d.CreatureID=900254 AND d.Idx=s.Idx);
 INSERT INTO spell_script_names SELECT 9004110,'WD154::cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004110 AND ScriptName='WD154::cast');
 INSERT INTO spell_script_names SELECT 9004110,'WD154::aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004110 AND ScriptName='WD154::aura');
 INSERT INTO spell_proc(SpellId,ProcFlags,SpellTypeMask,SpellPhaseMask,Chance,Cooldown)VALUES(9004110,87380,3,2,100,0)ON DUPLICATE KEY UPDATE SpellPhaseMask=VALUES(SpellPhaseMask);
END$$
CALL reborn_wd154_world()$$
DROP PROCEDURE reborn_wd154_world$$
DELIMITER ;
