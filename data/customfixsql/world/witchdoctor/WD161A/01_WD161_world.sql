-- WORLD: WD161 legacy effects retained, modern acquisition extended. No trainer deletion.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd161_world$$
CREATE PROCEDURE reborn_wd161_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_proc WHERE SpellId=9003532 AND (SchoolMask<>0 OR SpellFamilyName<>0 OR SpellFamilyMask0<>0 OR SpellFamilyMask1<>0 OR SpellFamilyMask2<>0 OR ProcFlags<>262144 OR SpellTypeMask<>1 OR SpellPhaseMask<>2 OR HitMask<>0 OR AttributesMask<>0 OR DisableEffectsMask<>0 OR ProcsPerMinute<>0 OR Chance<>25 OR Cooldown<>0 OR Charges<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD161 foreign Berserking proc';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id)=9003532 AND ScriptName<>'aura_reborn_wd51a_periodic') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD161 foreign Berserking binding';END IF;
 INSERT IGNORE INTO spell_proc(SpellId,SchoolMask,SpellFamilyName,SpellFamilyMask0,SpellFamilyMask1,SpellFamilyMask2,ProcFlags,SpellTypeMask,SpellPhaseMask,HitMask,AttributesMask,DisableEffectsMask,ProcsPerMinute,Chance,Cooldown,Charges)VALUES(9003532,0,0,0,0,0,262144,1,2,0,0,0,0,25,0,0);
 INSERT INTO spell_script_names SELECT 9003532,'aura_reborn_wd51a_periodic' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003532 AND ScriptName='aura_reborn_wd51a_periodic');
END$$
CALL reborn_wd161_world()$$
DROP PROCEDURE reborn_wd161_world$$
DELIMITER ;
