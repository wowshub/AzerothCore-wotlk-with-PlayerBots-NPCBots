-- Optional rollback. CHARACTERS only, worldserver stopped.
-- Refuses to narrow constraints when any saved row needs the expanded rules.
DROP PROCEDURE IF EXISTS codex_startfix1c_rollback;
DELIMITER $$
CREATE PROCEDURE codex_startfix1c_rollback()
BEGIN
 IF EXISTS(SELECT 1 FROM character_reborn_birth_route WHERE zone NOT BETWEEN 129 AND 140) OR
    EXISTS(SELECT 1 FROM character_reborn_neutral_origin WHERE
      race NOT IN(56,73,76,83,89,90,93,96,97,98,103,106,112,114,115,116) OR
      class NOT IN(1,2,3,4,5,6,7,8,9,11) OR
      NOT((race IN(56,90) AND sex=1) OR (race IN(73,76,89,93) AND sex IN(0,1)) OR (race NOT IN(56,90,73,76,89,93) AND sex=0)) OR
      NOT((zone BETWEEN 129 AND 140) OR (class=6 AND zone=0) OR
       (class<>6 AND ((team=0 AND zone IN(1,3,4,11)) OR (team=1 AND zone IN(2,5,6,10)))))) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='STARTFIX1C: rollback blocked by saved zone141/future-race rows; retain new constraints and do not delete characters';
 END IF;
 ALTER TABLE character_reborn_birth_route DROP CHECK reborn3f_birth_zone,ADD CONSTRAINT reborn3f_birth_zone CHECK(zone BETWEEN 129 AND 140);
 ALTER TABLE character_reborn_neutral_origin
  DROP CHECK neutral2a_race,DROP CHECK neutral2a_class,DROP CHECK neutral2a_sex,DROP CHECK neutral2e_zone,
  ADD CONSTRAINT neutral2a_race CHECK(race IN(56,73,76,83,89,90,93,96,97,98,103,106,112,114,115,116)),
  ADD CONSTRAINT neutral2a_class CHECK(class IN(1,2,3,4,5,6,7,8,9,11)),
  ADD CONSTRAINT neutral2a_sex CHECK((race IN(56,90) AND sex=1) OR (race IN(73,76,89,93) AND sex IN(0,1)) OR (race NOT IN(56,90,73,76,89,93) AND sex=0)),
  ADD CONSTRAINT neutral2e_zone CHECK((zone BETWEEN 129 AND 140) OR (class=6 AND zone=0) OR (class<>6 AND ((team=0 AND zone IN(1,3,4,11)) OR (team=1 AND zone IN(2,5,6,10)))));
END$$
DELIMITER ;
CALL codex_startfix1c_rollback();
DROP PROCEDURE codex_startfix1c_rollback;
