-- STARTFIX1C: run ONLY in the characters database, with worldserver stopped.
-- Preserve rows and positions. Each ALTER TABLE is atomic DDL; rerunning is supported.
DROP PROCEDURE IF EXISTS codex_startfix1c_install;
DELIMITER $$
CREATE PROCEDURE codex_startfix1c_install()
BEGIN
 DECLARE birth_clause LONGTEXT;
 IF (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='character_reborn_birth_route' AND column_name IN('guid','race','class','sex','team','zone'))<>6 OR
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='character_reborn_neutral_origin' AND column_name IN('guid','race','class','sex','team','zone','created_at'))<>7 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='STARTFIX1C: select the CHARACTERS database containing both existing origin tables';
 END IF;
 SELECT cc.check_clause INTO birth_clause FROM information_schema.check_constraints cc
 JOIN information_schema.table_constraints tc ON tc.constraint_schema=cc.constraint_schema AND tc.constraint_name=cc.constraint_name
 WHERE tc.table_schema=DATABASE() AND tc.table_name='character_reborn_birth_route' AND tc.constraint_name='reborn3f_birth_zone';
 SET birth_clause=REPLACE(REPLACE(REPLACE(REPLACE(LOWER(birth_clause),'`',''),' ',''),'(',''),')','');
 IF birth_clause IS NULL OR birth_clause NOT IN('zonebetween129and140','zonebetween129and141') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='STARTFIX1C: unexpected birth-zone constraint; no migration performed';
 END IF;
 IF (SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_schema=DATABASE() AND table_name='character_reborn_neutral_origin' AND constraint_name IN('neutral2a_race','neutral2a_class','neutral2a_sex','neutral2e_zone'))<>4 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='STARTFIX1C: neutral origin schema differs; inspect constraints before migrating';
 END IF;
 -- The old ordinary-race table rejected zone 141 during the character save transaction.
 IF birth_clause='zonebetween129and140' THEN
  ALTER TABLE character_reborn_birth_route
   DROP CHECK reborn3f_birth_zone,
   ADD CONSTRAINT reborn3f_birth_zone CHECK(zone BETWEEN 129 AND 141);
 END IF;
 -- Keep scalar database integrity. Race/class/sex eligibility is authoritatively validated
 -- by the existing server creation pipeline, so future registered races need no SQL allowlist.
 ALTER TABLE character_reborn_neutral_origin
  DROP CHECK neutral2a_race,
  DROP CHECK neutral2a_class,
  DROP CHECK neutral2a_sex,
  DROP CHECK neutral2e_zone,
  ADD CONSTRAINT neutral2a_race CHECK(race BETWEEN 1 AND 255),
  ADD CONSTRAINT neutral2a_class CHECK(class BETWEEN 1 AND 255),
  ADD CONSTRAINT neutral2a_sex CHECK(sex IN(0,1)),
  ADD CONSTRAINT neutral2e_zone CHECK(
   (zone BETWEEN 129 AND 141) OR (class=6 AND zone=0) OR
   (class<>6 AND ((team=0 AND zone IN(1,3,4,11)) OR (team=1 AND zone IN(2,5,6,10)))));
 IF EXISTS(SELECT 1 FROM information_schema.table_constraints WHERE table_schema=DATABASE() AND table_name='character_reborn_neutral_origin' AND constraint_name='neutral2a_zone') THEN
  ALTER TABLE character_reborn_neutral_origin DROP CHECK neutral2a_zone;
 END IF;
END$$
DELIMITER ;
CALL codex_startfix1c_install();
DROP PROCEDURE codex_startfix1c_install;
SELECT tc.table_name,tc.constraint_name,cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc ON cc.constraint_schema=tc.constraint_schema AND cc.constraint_name=tc.constraint_name
WHERE tc.table_schema=DATABASE() AND tc.table_name IN('character_reborn_birth_route','character_reborn_neutral_origin')
ORDER BY tc.table_name,tc.constraint_name;
