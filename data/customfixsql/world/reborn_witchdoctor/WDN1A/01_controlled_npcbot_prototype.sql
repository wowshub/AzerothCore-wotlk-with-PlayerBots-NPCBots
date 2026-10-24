-- WDN1A3SQL: split combat/equipment donor from Human appearance/model donor.
-- Replaces the old WDN1A installer; World only. Run with the server stopped, after a database backup.
-- Creates one controlled test prototype; never rewrites existing bots or owners.
SET NAMES utf8mb4;
DROP PROCEDURE IF EXISTS reborn_wdn1a_install;
DELIMITER $$
CREATE PROCEDURE reborn_wdn1a_install()
wdn_install:BEGIN
 DECLARE donor INT DEFAULT NULL;
 DECLARE human_donor INT DEFAULT NULL;
 DECLARE column_list LONGTEXT;
 DECLARE value_list LONGTEXT;
 DECLARE old_concat BIGINT DEFAULT @@SESSION.group_concat_max_len;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN ROLLBACK; SET SESSION group_concat_max_len=old_concat; RESIGNAL; END;
 IF (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()
     AND table_name IN ('creature_template','creature_template_model','creature_equip_template',
       'creature_template_npcbot_extras','creature_template_npcbot_appearance') AND engine='InnoDB')<>5 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WDN1A: requires the five current InnoDB NPCBot World tables';
 END IF;
 IF EXISTS(SELECT 1 FROM creature_template_npcbot_extras WHERE class=21 AND entry<>900260) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WDN1A: NPC internal class21 already reserved by another bot';
 END IF;
 IF EXISTS(SELECT 1 FROM creature_template WHERE entry=900260) THEN
  IF NOT EXISTS(SELECT 1 FROM creature_template c JOIN creature_template_npcbot_extras x ON x.entry=c.entry
       WHERE c.entry=900260 AND c.ScriptName='witch_doctor_bot' AND c.name='Witch Doctor WDN1A'
       AND x.class=21 AND x.race=1)
     OR NOT EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900260)
     OR NOT EXISTS(SELECT 1 FROM creature_equip_template WHERE CreatureID=900260 AND ID=1 AND ItemID3<>0)
     OR NOT EXISTS(SELECT 1 FROM creature_template_npcbot_appearance WHERE entry=900260) THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WDN1A: entry900260 collision or incomplete prototype; nothing overwritten';
  END IF;
  SELECT 'WDN1A already installed; owner, equipment and talents were not reset' AS status;
  LEAVE wdn_install;
 END IF;
 IF EXISTS(SELECT 1 FROM creature_template_npcbot_extras WHERE entry=900260)
 OR EXISTS(SELECT 1 FROM creature_template_npcbot_appearance WHERE entry=900260)
 OR EXISTS(SELECT 1 FROM creature_template_model WHERE CreatureID=900260)
 OR EXISTS(SELECT 1 FROM creature_equip_template WHERE CreatureID=900260) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WDN1A: orphan entry900260 data exists; nothing overwritten';
 END IF;
 SELECT MIN(c.entry) INTO donor FROM creature_template c
 JOIN creature_template_npcbot_extras x ON x.entry=c.entry AND x.class=3
 JOIN creature_equip_template e ON e.CreatureID=c.entry AND e.ID=1 AND e.ItemID3<>0
 WHERE c.ScriptName='hunter_bot';
 IF donor IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WDN1A: no installed Hunter NPCBot with ID1 ranged equipment';
 END IF;
 -- Human identity stays race 1. Appearance and model must come from the SAME Human.
 SELECT MIN(c.entry) INTO human_donor FROM creature_template c
 JOIN creature_template_npcbot_extras x ON x.entry=c.entry AND x.race=1
 JOIN creature_template_npcbot_appearance a ON a.entry=c.entry
 JOIN creature_template_model m ON m.CreatureID=c.entry AND m.CreatureDisplayID<>0
 WHERE x.class IN (1,2,3,4,5,6,7,8,9,11)
   AND c.ScriptName IN ('warrior_bot','paladin_bot','hunter_bot','rogue_bot','priest_bot',
       'death_knight_bot','shaman_bot','mage_bot','warlock_bot','druid_bot');
 IF human_donor IS NULL THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WDN1A: no installed Human NPCBot with appearance and model';
 END IF;
 SET SESSION group_concat_max_len=1048576;
 SELECT GROUP_CONCAT(CONCAT('`',REPLACE(column_name,'`','``'),'`') ORDER BY ordinal_position),
  GROUP_CONCAT(CASE column_name WHEN 'entry' THEN '900260'
   WHEN 'name' THEN QUOTE('Witch Doctor WDN1A')
   WHEN 'subname' THEN QUOTE('Shadowhunting Test / WDN1A')
   WHEN 'ScriptName' THEN QUOTE('witch_doctor_bot')
   WHEN 'minlevel' THEN '10' WHEN 'maxlevel' THEN '10'
   ELSE CONCAT('`',REPLACE(column_name,'`','``'),'`') END ORDER BY ordinal_position)
 INTO column_list,value_list FROM information_schema.columns
 WHERE table_schema=DATABASE() AND table_name='creature_template' AND generation_expression='';
 START TRANSACTION;
 SET @wdn1a_sql=CONCAT('INSERT INTO creature_template (',column_list,') SELECT ',value_list,
   ' FROM creature_template WHERE entry=',donor);
 PREPARE wdn1a_stmt FROM @wdn1a_sql; EXECUTE wdn1a_stmt; DEALLOCATE PREPARE wdn1a_stmt;
 INSERT INTO creature_template_npcbot_extras(entry,class,race) VALUES(900260,21,1);
 INSERT INTO creature_template_npcbot_appearance(entry,gender,skin,face,hair,haircolor,features)
  SELECT 900260,gender,skin,face,hair,haircolor,features FROM creature_template_npcbot_appearance WHERE entry=human_donor;
 INSERT INTO creature_equip_template(CreatureID,ID,ItemID1,ItemID2,ItemID3,VerifiedBuild)
  SELECT 900260,ID,ItemID1,ItemID2,ItemID3,VerifiedBuild FROM creature_equip_template WHERE CreatureID=donor;
 INSERT INTO creature_template_model(CreatureID,Idx,CreatureDisplayID,DisplayScale,Probability,VerifiedBuild)
  SELECT 900260,Idx,CreatureDisplayID,DisplayScale,Probability,VerifiedBuild FROM creature_template_model WHERE CreatureID=human_donor;
 COMMIT;
 SET SESSION group_concat_max_len=old_concat;
 SELECT 'WDN1A installed; restart new server, then .npcbot spawn 900260 outdoors' AS status, donor AS combat_equipment_donor, human_donor AS appearance_model_donor;
END$$
DELIMITER ;
CALL reborn_wdn1a_install();
DROP PROCEDURE reborn_wdn1a_install;
