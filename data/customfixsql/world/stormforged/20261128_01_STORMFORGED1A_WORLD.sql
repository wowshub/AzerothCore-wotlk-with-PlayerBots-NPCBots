SET NAMES utf8mb4;
DROP PROCEDURE IF EXISTS codex_stormforged1a_install;
DELIMITER $$
CREATE PROCEDURE codex_stormforged1a_install()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    IF DATABASE() <> 'acore_world'
       OR EXISTS (SELECT 1 FROM playercreateinfo WHERE race=84)
       OR EXISTS (SELECT 1 FROM player_race_stats WHERE Race=84)
       OR EXISTS (SELECT 1 FROM playercreateinfo_action WHERE race=84)
       OR EXISTS (SELECT 1 FROM playercreateinfo_item WHERE race=84)
       OR (SELECT COUNT(*) FROM playercreateinfo WHERE race=CASE class WHEN 3 THEN 3 WHEN 7 THEN 11 WHEN 11 THEN 4 ELSE 1 END AND class IN (1,2,3,4,5,6,7,8,9,11)) <> 10
       OR NOT EXISTS (SELECT 1 FROM playercreateinfo WHERE race=1 AND class=6 AND map=609)
       OR (SELECT COUNT(*) FROM player_race_stats WHERE Race=1) <> 1
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='STORMFORGED1A: WORLD baseline incomplete or race 84 already exists';
    END IF;
    INSERT INTO playercreateinfo(race,class,map,zone,position_x,position_y,position_z,orientation)
        SELECT 84,class,map,zone,position_x,position_y,position_z,orientation FROM playercreateinfo
        WHERE race=CASE class WHEN 3 THEN 3 WHEN 7 THEN 11 WHEN 11 THEN 4 ELSE 1 END AND class IN (1,2,3,4,5,6,7,8,9,11);
    INSERT INTO player_race_stats(Race,Strength,Agility,Stamina,Intellect,Spirit)
        SELECT 84,Strength,Agility,Stamina,Intellect,Spirit FROM player_race_stats WHERE Race=1;
    INSERT INTO playercreateinfo_action(race,class,button,action,type)
        SELECT 84,class,button,action,type FROM playercreateinfo_action
        WHERE race=CASE class WHEN 3 THEN 3 WHEN 7 THEN 11 WHEN 11 THEN 4 ELSE 1 END AND class IN (1,2,3,4,5,6,7,8,9,11) AND NOT (type=0 AND action IN (20599,20600,59752));
    INSERT INTO playercreateinfo_item(race,class,itemid,amount,Note)
        SELECT 84,class,itemid,amount,Note FROM playercreateinfo_item
        WHERE race=CASE class WHEN 3 THEN 3 WHEN 7 THEN 11 WHEN 11 THEN 4 ELSE 1 END AND class IN (1,2,3,4,5,6,7,8,9,11);
    COMMIT;
END$$
DELIMITER ;
CALL codex_stormforged1a_install();
DROP PROCEDURE codex_stormforged1a_install;
SELECT race,class,map,zone FROM playercreateinfo WHERE race=84 ORDER BY class;
