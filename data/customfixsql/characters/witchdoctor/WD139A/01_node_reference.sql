-- Generated node reference; no character rows are modified.
CREATE TABLE IF NOT EXISTS reborn_wd_node_def(node_id INT UNSIGNED PRIMARY KEY,max_rank TINYINT UNSIGNED NOT NULL,layout_index SMALLINT UNSIGNED NOT NULL,bit_offset SMALLINT UNSIGNED NOT NULL,bit_width TINYINT UNSIGNED NOT NULL,spec TINYINT NOT NULL) ENGINE=InnoDB;
INSERT INTO reborn_wd_node_def VALUES
(29744,1,0,0,1,-1),
(6054,1,1,1,1,-1),
(6047,2,2,2,2,-1),
(7092,1,3,4,1,-1),
(29309,1,4,5,1,-1),
(29301,1,5,6,1,-1),
(4004,1,6,7,1,0),
(31154,1,7,8,1,0),
(31344,1,8,9,1,0),
(31340,1,9,10,1,0),
(7157,1,10,11,1,0),
(6058,1,11,12,1,0),
(29928,1,12,13,1,0),
(30973,3,13,14,2,0),
(4533,1,14,16,1,0),
(31341,1,15,17,1,0),
(6045,1,16,18,1,0),
(31347,1,17,19,1,0),
(31348,1,18,20,1,0),
(6644,1,19,21,1,0),
(6046,1,20,22,1,0),
(6062,2,21,23,2,0),
(30889,1,22,25,1,0),
(31343,1,23,26,1,0),
(6053,1,24,27,1,0),
(31350,1,25,28,1,0),
(5333,1,26,29,1,0),
(6059,1,27,30,1,0),
(5332,1,28,31,1,0),
(31345,2,29,32,2,0),
(6007,2,30,34,2,0),
(11532,1,31,36,1,0),
(4532,1,32,37,1,0),
(29121,1,33,38,1,0),
(31346,1,34,39,1,0),
(7100,1,35,40,1,0),
(29768,1,36,41,1,0),
(6057,1,37,42,1,0),
(30596,1,38,43,1,0),
(7088,2,39,44,2,-1),
(30147,1,40,46,1,-1),
(4132,1,41,47,1,-1),
(31349,1,42,48,1,0),
(29929,1,43,49,1,0),
(6055,1,44,50,1,0),
(11133,1,45,51,1,0),
(7033,1,46,52,1,-1),
(6051,1,47,53,1,-1),
(6048,1,48,54,1,-1),
(7131,2,49,55,2,1),
(30884,2,50,57,2,1),
(29736,2,51,59,2,1),
(9311,1,52,61,1,1),
(5055,1,53,62,1,1),
(4715,1,54,63,1,1),
(7129,1,55,64,1,1),
(7948,1,56,65,1,1),
(31137,1,57,66,1,1),
(30891,1,59,68,1,-1),
(6030,1,60,69,1,-1),
(7132,1,61,70,1,1),
(29753,1,62,71,1,1),
(6381,1,63,72,1,-1),
(12048,1,64,73,1,-1),
(11323,1,65,74,1,-1),
(31118,1,66,75,1,-1),
(12264,1,67,76,1,-1),
(6042,1,68,77,1,-1),
(9347,2,69,78,2,-1),
(29306,1,70,80,1,-1),
(6031,1,71,81,1,-1),
(6525,1,72,82,1,-1),
(12525,1,73,83,1,-1),
(4005,1,74,84,1,1),
(12645,1,75,85,1,1),
(12646,1,76,86,1,1),
(6498,2,77,87,2,1),
(29303,1,78,89,1,1),
(6020,1,79,90,1,1),
(29737,1,80,91,1,1),
(7128,1,81,92,1,1),
(35065,1,82,93,1,1),
(35064,2,83,94,2,1),
(35068,1,84,96,1,1),
(29738,1,85,97,1,1),
(30888,1,86,98,1,1),
(35051,1,87,99,1,1),
(6645,1,88,100,1,1),
(4112,1,89,101,1,1),
(7130,1,90,102,1,1),
(6021,1,91,103,1,1),
(6014,1,92,104,1,1),
(30823,1,93,105,1,1),
(6022,1,94,106,1,1),
(6013,1,95,107,1,1),
(6016,1,96,108,1,1),
(6009,1,97,109,1,1),
(4733,1,98,110,1,1),
(6015,1,99,111,1,1),
(29310,1,100,112,1,1),
(29754,1,101,113,1,1),
(30333,1,102,114,1,1),
(6027,1,103,115,1,1),
(13133,1,104,116,1,1),
(6026,1,105,117,1,1),
(29740,1,106,118,1,1),
(7133,1,107,119,1,1)
ON DUPLICATE KEY UPDATE max_rank=VALUES(max_rank),layout_index=VALUES(layout_index),bit_offset=VALUES(bit_offset),bit_width=VALUES(bit_width),spec=VALUES(spec);

DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd139_schema$$
CREATE PROCEDURE reborn_wd139_schema()
BEGIN
 IF EXISTS(SELECT 1 FROM reborn_wd67_nodes n LEFT JOIN reborn_wd_node_def d ON d.node_id=n.node_id
 WHERE d.node_id IS NULL OR n.node_rank<1 OR n.node_rank>d.max_rank)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD139A unknown or invalid existing rows; stop upgrade';END IF;
END$$
CALL reborn_wd139_schema()$$
DROP PROCEDURE reborn_wd139_schema$$
DROP TRIGGER IF EXISTS reborn_wd139_node_insert$$
CREATE TRIGGER reborn_wd139_node_insert BEFORE INSERT ON reborn_wd67_nodes FOR EACH ROW
BEGIN
 IF NOT EXISTS(SELECT 1 FROM reborn_wd_node_def WHERE node_id=NEW.node_id AND NEW.node_rank BETWEEN 1 AND max_rank)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD139A invalid node/rank';END IF;
END$$
DROP TRIGGER IF EXISTS reborn_wd139_node_update$$
CREATE TRIGGER reborn_wd139_node_update BEFORE UPDATE ON reborn_wd67_nodes FOR EACH ROW
BEGIN
 IF NOT EXISTS(SELECT 1 FROM reborn_wd_node_def WHERE node_id=NEW.node_id AND NEW.node_rank BETWEEN 1 AND max_rank)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD139A invalid node/rank';END IF;
END$$
DELIMITER ;
-- Phase 1 deliberately retains the old CHECK constraints as an additional ceiling.
-- They must be retired in the separately reviewed phase 2 that introduces nodes.
