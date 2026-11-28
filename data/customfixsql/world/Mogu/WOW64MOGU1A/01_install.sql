SET NAMES utf8mb4;
DROP PROCEDURE IF EXISTS codex_mogu1a_install;
DELIMITER $$
CREATE PROCEDURE codex_mogu1a_install()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    IF DATABASE() <> 'acore_world'
       OR EXISTS (SELECT 1 FROM playercreateinfo WHERE race=123)
       OR EXISTS (SELECT 1 FROM player_race_stats WHERE Race=123)
       OR EXISTS (SELECT 1 FROM playercreateinfo_action WHERE race=123)
       OR EXISTS (SELECT 1 FROM playercreateinfo_item WHERE race=123)
       OR (SELECT COUNT(*) FROM playercreateinfo WHERE race=1 AND class IN (1,2,4,5,6,8,9)) <> 7
       OR NOT EXISTS (SELECT 1 FROM playercreateinfo WHERE race=1 AND class=6 AND map=609)
       OR (SELECT COUNT(*) FROM player_race_stats WHERE Race=1) <> 1
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MOGU1A: WORLD baseline incomplete or race 123 already exists';
    END IF;
    INSERT INTO playercreateinfo(race,class,map,zone,position_x,position_y,position_z,orientation)
        SELECT 123,class,map,zone,position_x,position_y,position_z,orientation FROM playercreateinfo
        WHERE race=1 AND class IN (1,2,4,5,6,8,9);
    INSERT INTO player_race_stats(Race,Strength,Agility,Stamina,Intellect,Spirit)
        SELECT 123,Strength,Agility,Stamina,Intellect,Spirit FROM player_race_stats WHERE Race=1;
    INSERT INTO playercreateinfo_action(race,class,button,action,type)
        SELECT 123,class,button,action,type FROM playercreateinfo_action
        WHERE race=1 AND class IN (1,2,4,5,6,8,9) AND NOT (type=0 AND action IN (20599,20600,59752));
    INSERT INTO playercreateinfo_item(race,class,itemid,amount,Note)
        SELECT 123,class,itemid,amount,Note FROM playercreateinfo_item
        WHERE race=1 AND class IN (1,2,4,5,6,8,9);
    COMMIT;
END$$
DELIMITER ;
CALL codex_mogu1a_install();
DROP PROCEDURE codex_mogu1a_install;
SELECT race,class,map,zone FROM playercreateinfo WHERE race=123 ORDER BY class;
