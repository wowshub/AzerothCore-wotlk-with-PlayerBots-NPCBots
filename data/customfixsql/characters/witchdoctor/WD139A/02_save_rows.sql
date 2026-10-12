-- CHARACTERS. Requires WD138B and 01_node_reference.sql. Old command/procedure retained.
DROP PROCEDURE IF EXISTS reborn_wd139_save;
DELIMITER $$
CREATE PROCEDURE reborn_wd139_save(IN p_guid INT UNSIGNED,IN p_account INT UNSIGNED,IN p_revision INT UNSIGNED,
 IN p_slot INT UNSIGNED,IN p_nodes JSON,IN p_level INT UNSIGNED, IN p_version INT UNSIGNED, IN p_hash VARCHAR(64))
SQL SECURITY INVOKER
proc:BEGIN
 DECLARE v_revision BIGINT DEFAULT -1;
 DECLARE v_account INT DEFAULT -1;
 DECLARE v_class INT DEFAULT 0;
 DECLARE v_race INT DEFAULT 0;
 DECLARE v_ae INT DEFAULT 0;








 DECLARE r0 INT DEFAULT 0;
 DECLARE r1 INT DEFAULT 0;
 DECLARE r2 INT DEFAULT 0;
 DECLARE r3 INT DEFAULT 0;
 DECLARE r4 INT DEFAULT 0;
 DECLARE r5 INT DEFAULT 0;
 DECLARE r6 INT DEFAULT 0;
 DECLARE r7 INT DEFAULT 0;
 DECLARE r8 INT DEFAULT 0;
 DECLARE r9 INT DEFAULT 0;
 DECLARE r10 INT DEFAULT 0;
 DECLARE r11 INT DEFAULT 0;
 DECLARE r12 INT DEFAULT 0;
 DECLARE r13 INT DEFAULT 0;
 DECLARE r14 INT DEFAULT 0;
 DECLARE r15 INT DEFAULT 0;
 DECLARE r16 INT DEFAULT 0;
 DECLARE r17 INT DEFAULT 0;
 DECLARE r18 INT DEFAULT 0;
 DECLARE r19 INT DEFAULT 0;
 DECLARE r20 INT DEFAULT 0;
 DECLARE r21 INT DEFAULT 0;
 DECLARE r22 INT DEFAULT 0;
 DECLARE r23 INT DEFAULT 0;
 DECLARE r24 INT DEFAULT 0;
 DECLARE r25 INT DEFAULT 0;
 DECLARE r26 INT DEFAULT 0;
 DECLARE r27 INT DEFAULT 0;
 DECLARE r28 INT DEFAULT 0;
 DECLARE r29 INT DEFAULT 0;
 DECLARE r30 INT DEFAULT 0;
 DECLARE r31 INT DEFAULT 0;
 DECLARE r32 INT DEFAULT 0;
 DECLARE r33 INT DEFAULT 0;
 DECLARE r34 INT DEFAULT 0;
 DECLARE r35 INT DEFAULT 0;
 DECLARE r36 INT DEFAULT 0;
 DECLARE r37 INT DEFAULT 0;
 DECLARE r38 INT DEFAULT 0;
 DECLARE r39 INT DEFAULT 0;
 DECLARE r40 INT DEFAULT 0;
 DECLARE r41 INT DEFAULT 0;
 DECLARE r42 INT DEFAULT 0;
 DECLARE r43 INT DEFAULT 0;
 DECLARE r44 INT DEFAULT 0;
 DECLARE r45 INT DEFAULT 0;
 DECLARE r46 INT DEFAULT 0;
 DECLARE r47 INT DEFAULT 0;
 DECLARE r48 INT DEFAULT 0;
 DECLARE r49 INT DEFAULT 0;
 DECLARE r50 INT DEFAULT 0;
 DECLARE r51 INT DEFAULT 0;
 DECLARE r52 INT DEFAULT 0;
 DECLARE r53 INT DEFAULT 0;
 DECLARE r54 INT DEFAULT 0;
 DECLARE r55 INT DEFAULT 0;
 DECLARE r56 INT DEFAULT 0;
 DECLARE r57 INT DEFAULT 0;
 DECLARE r58 INT DEFAULT 0;
 DECLARE r59 INT DEFAULT 0;
 DECLARE r60 INT DEFAULT 0;
 DECLARE r61 INT DEFAULT 0;
 DECLARE r62 INT DEFAULT 0;
 DECLARE r63 INT DEFAULT 0;
 DECLARE r64 INT DEFAULT 0;
 DECLARE r65 INT DEFAULT 0;
 DECLARE r66 INT DEFAULT 0;
 DECLARE r67 INT DEFAULT 0;
 DECLARE r68 INT DEFAULT 0;
 DECLARE r69 INT DEFAULT 0;
 DECLARE r70 INT DEFAULT 0;
 DECLARE r71 INT DEFAULT 0;
 DECLARE r72 INT DEFAULT 0;
 DECLARE r73 INT DEFAULT 0;
 DECLARE r74 INT DEFAULT 0;
 DECLARE r75 INT DEFAULT 0;
 DECLARE r76 INT DEFAULT 0;
 DECLARE r77 INT DEFAULT 0;
 DECLARE r78 INT DEFAULT 0;
 DECLARE r79 INT DEFAULT 0;
 DECLARE r80 INT DEFAULT 0;
 DECLARE r81 INT DEFAULT 0;
 DECLARE r82 INT DEFAULT 0;
 DECLARE r83 INT DEFAULT 0;
 DECLARE r84 INT DEFAULT 0;
 DECLARE r85 INT DEFAULT 0;
 DECLARE r86 INT DEFAULT 0;
 DECLARE r87 INT DEFAULT 0;
 DECLARE r88 INT DEFAULT 0;
 DECLARE r89 INT DEFAULT 0;
 DECLARE r90 INT DEFAULT 0;
 DECLARE r91 INT DEFAULT 0;
 DECLARE r92 INT DEFAULT 0;
 DECLARE r93 INT DEFAULT 0;
 DECLARE r94 INT DEFAULT 0;
 DECLARE r95 INT DEFAULT 0;
 DECLARE r96 INT DEFAULT 0;
 DECLARE r97 INT DEFAULT 0;
 DECLARE r98 INT DEFAULT 0;
 DECLARE r99 INT DEFAULT 0;
 DECLARE r100 INT DEFAULT 0;
 DECLARE r101 INT DEFAULT 0;
 DECLARE r102 INT DEFAULT 0;
 DECLARE r103 INT DEFAULT 0;
 DECLARE r104 INT DEFAULT 0;
 DECLARE r105 INT DEFAULT 0;
 DECLARE r106 INT DEFAULT 0;
 DECLARE r107 INT DEFAULT 0;
 DECLARE v_te INT DEFAULT 0;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;SELECT 0 AS result;END;
 IF p_slot IS NULL OR p_slot>2 OR p_level IS NULL OR p_level<1 OR p_level>255
 OR p_nodes IS NULL OR JSON_TYPE(p_nodes)<>'ARRAY' OR JSON_LENGTH(p_nodes)>256
 OR p_version IS NULL OR p_version<>1 OR p_hash IS NULL OR BINARY p_hash<>BINARY '6d8c782d8e48c6376c533a8a574372e534633321e4a0fc03a93a77965856f8c6'
 THEN SELECT 0 AS result;LEAVE proc;END IF;
 IF EXISTS(SELECT 1 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(ord FOR ORDINALITY)) j
 WHERE JSON_TYPE(JSON_EXTRACT(p_nodes,CONCAT('$[',j.ord-1,']')))<>'ARRAY'
 OR JSON_LENGTH(JSON_EXTRACT(p_nodes,CONCAT('$[',j.ord-1,']')))<>2
 OR JSON_TYPE(JSON_EXTRACT(p_nodes,CONCAT('$[',j.ord-1,'][0]')))<>'INTEGER'
 OR JSON_TYPE(JSON_EXTRACT(p_nodes,CONCAT('$[',j.ord-1,'][1]')))<>'INTEGER')
 THEN SELECT 0 AS result;LEAVE proc;END IF;
 IF EXISTS(SELECT 1 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value BIGINT PATH '$[1]')) j
 LEFT JOIN reborn_wd_node_def d ON d.node_id=j.id
 WHERE d.node_id IS NULL OR j.rank_value<1 OR j.rank_value>d.max_rank)
 OR EXISTS(SELECT id FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]')) j GROUP BY id HAVING COUNT(*)>1)
 THEN SELECT 0 AS result;LEAVE proc;END IF;
 SELECT COALESCE(MAX(rank_value),0) INTO r0 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29744;
 SELECT COALESCE(MAX(rank_value),0) INTO r1 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6054;
 SELECT COALESCE(MAX(rank_value),0) INTO r2 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6047;
 SELECT COALESCE(MAX(rank_value),0) INTO r3 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7092;
 SELECT COALESCE(MAX(rank_value),0) INTO r4 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29309;
 SELECT COALESCE(MAX(rank_value),0) INTO r5 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29301;
 SELECT COALESCE(MAX(rank_value),0) INTO r6 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4004;
 SELECT COALESCE(MAX(rank_value),0) INTO r7 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31154;
 SELECT COALESCE(MAX(rank_value),0) INTO r8 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31344;
 SELECT COALESCE(MAX(rank_value),0) INTO r9 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31340;
 SELECT COALESCE(MAX(rank_value),0) INTO r10 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7157;
 SELECT COALESCE(MAX(rank_value),0) INTO r11 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6058;
 SELECT COALESCE(MAX(rank_value),0) INTO r12 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29928;
 SELECT COALESCE(MAX(rank_value),0) INTO r13 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30973;
 SELECT COALESCE(MAX(rank_value),0) INTO r14 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4533;
 SELECT COALESCE(MAX(rank_value),0) INTO r15 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31341;
 SELECT COALESCE(MAX(rank_value),0) INTO r16 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6045;
 SELECT COALESCE(MAX(rank_value),0) INTO r17 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31347;
 SELECT COALESCE(MAX(rank_value),0) INTO r18 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31348;
 SELECT COALESCE(MAX(rank_value),0) INTO r19 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6644;
 SELECT COALESCE(MAX(rank_value),0) INTO r20 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6046;
 SELECT COALESCE(MAX(rank_value),0) INTO r21 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6062;
 SELECT COALESCE(MAX(rank_value),0) INTO r22 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30889;
 SELECT COALESCE(MAX(rank_value),0) INTO r23 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31343;
 SELECT COALESCE(MAX(rank_value),0) INTO r24 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6053;
 SELECT COALESCE(MAX(rank_value),0) INTO r25 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31350;
 SELECT COALESCE(MAX(rank_value),0) INTO r26 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=5333;
 SELECT COALESCE(MAX(rank_value),0) INTO r27 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6059;
 SELECT COALESCE(MAX(rank_value),0) INTO r28 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=5332;
 SELECT COALESCE(MAX(rank_value),0) INTO r29 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31345;
 SELECT COALESCE(MAX(rank_value),0) INTO r30 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6007;
 SELECT COALESCE(MAX(rank_value),0) INTO r31 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=11532;
 SELECT COALESCE(MAX(rank_value),0) INTO r32 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4532;
 SELECT COALESCE(MAX(rank_value),0) INTO r33 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29121;
 SELECT COALESCE(MAX(rank_value),0) INTO r34 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31346;
 SELECT COALESCE(MAX(rank_value),0) INTO r35 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7100;
 SELECT COALESCE(MAX(rank_value),0) INTO r36 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29768;
 SELECT COALESCE(MAX(rank_value),0) INTO r37 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6057;
 SELECT COALESCE(MAX(rank_value),0) INTO r38 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30596;
 SELECT COALESCE(MAX(rank_value),0) INTO r39 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7088;
 SELECT COALESCE(MAX(rank_value),0) INTO r40 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30147;
 SELECT COALESCE(MAX(rank_value),0) INTO r41 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4132;
 SELECT COALESCE(MAX(rank_value),0) INTO r42 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31349;
 SELECT COALESCE(MAX(rank_value),0) INTO r43 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29929;
 SELECT COALESCE(MAX(rank_value),0) INTO r44 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6055;
 SELECT COALESCE(MAX(rank_value),0) INTO r45 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=11133;
 SELECT COALESCE(MAX(rank_value),0) INTO r46 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7033;
 SELECT COALESCE(MAX(rank_value),0) INTO r47 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6051;
 SELECT COALESCE(MAX(rank_value),0) INTO r48 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6048;
 SELECT COALESCE(MAX(rank_value),0) INTO r49 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7131;
 SELECT COALESCE(MAX(rank_value),0) INTO r50 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30884;
 SELECT COALESCE(MAX(rank_value),0) INTO r51 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29736;
 SELECT COALESCE(MAX(rank_value),0) INTO r52 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=9311;
 SELECT COALESCE(MAX(rank_value),0) INTO r53 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=5055;
 SELECT COALESCE(MAX(rank_value),0) INTO r54 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4715;
 SELECT COALESCE(MAX(rank_value),0) INTO r55 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7129;
 SELECT COALESCE(MAX(rank_value),0) INTO r56 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7948;
 SELECT COALESCE(MAX(rank_value),0) INTO r57 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31137;
 SELECT COALESCE(MAX(rank_value),0) INTO r59 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30891;
 SELECT COALESCE(MAX(rank_value),0) INTO r60 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6030;
 SELECT COALESCE(MAX(rank_value),0) INTO r61 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7132;
 SELECT COALESCE(MAX(rank_value),0) INTO r62 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29753;
 SELECT COALESCE(MAX(rank_value),0) INTO r63 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6381;
 SELECT COALESCE(MAX(rank_value),0) INTO r64 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=12048;
 SELECT COALESCE(MAX(rank_value),0) INTO r65 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=11323;
 SELECT COALESCE(MAX(rank_value),0) INTO r66 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=31118;
 SELECT COALESCE(MAX(rank_value),0) INTO r67 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=12264;
 SELECT COALESCE(MAX(rank_value),0) INTO r68 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6042;
 SELECT COALESCE(MAX(rank_value),0) INTO r69 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=9347;
 SELECT COALESCE(MAX(rank_value),0) INTO r70 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29306;
 SELECT COALESCE(MAX(rank_value),0) INTO r71 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6031;
 SELECT COALESCE(MAX(rank_value),0) INTO r72 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6525;
 SELECT COALESCE(MAX(rank_value),0) INTO r73 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=12525;
 SELECT COALESCE(MAX(rank_value),0) INTO r74 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4005;
 SELECT COALESCE(MAX(rank_value),0) INTO r75 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=12645;
 SELECT COALESCE(MAX(rank_value),0) INTO r76 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=12646;
 SELECT COALESCE(MAX(rank_value),0) INTO r77 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6498;
 SELECT COALESCE(MAX(rank_value),0) INTO r78 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29303;
 SELECT COALESCE(MAX(rank_value),0) INTO r79 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6020;
 SELECT COALESCE(MAX(rank_value),0) INTO r80 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29737;
 SELECT COALESCE(MAX(rank_value),0) INTO r81 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7128;
 SELECT COALESCE(MAX(rank_value),0) INTO r82 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=35065;
 SELECT COALESCE(MAX(rank_value),0) INTO r83 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=35064;
 SELECT COALESCE(MAX(rank_value),0) INTO r84 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=35068;
 SELECT COALESCE(MAX(rank_value),0) INTO r85 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29738;
 SELECT COALESCE(MAX(rank_value),0) INTO r86 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30888;
 SELECT COALESCE(MAX(rank_value),0) INTO r87 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=35051;
 SELECT COALESCE(MAX(rank_value),0) INTO r88 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6645;
 SELECT COALESCE(MAX(rank_value),0) INTO r89 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4112;
 SELECT COALESCE(MAX(rank_value),0) INTO r90 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7130;
 SELECT COALESCE(MAX(rank_value),0) INTO r91 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6021;
 SELECT COALESCE(MAX(rank_value),0) INTO r92 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6014;
 SELECT COALESCE(MAX(rank_value),0) INTO r93 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30823;
 SELECT COALESCE(MAX(rank_value),0) INTO r94 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6022;
 SELECT COALESCE(MAX(rank_value),0) INTO r95 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6013;
 SELECT COALESCE(MAX(rank_value),0) INTO r96 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6016;
 SELECT COALESCE(MAX(rank_value),0) INTO r97 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6009;
 SELECT COALESCE(MAX(rank_value),0) INTO r98 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=4733;
 SELECT COALESCE(MAX(rank_value),0) INTO r99 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6015;
 SELECT COALESCE(MAX(rank_value),0) INTO r100 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29310;
 SELECT COALESCE(MAX(rank_value),0) INTO r101 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29754;
 SELECT COALESCE(MAX(rank_value),0) INTO r102 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=30333;
 SELECT COALESCE(MAX(rank_value),0) INTO r103 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6027;
 SELECT COALESCE(MAX(rank_value),0) INTO r104 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=13133;
 SELECT COALESCE(MAX(rank_value),0) INTO r105 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=6026;
 SELECT COALESCE(MAX(rank_value),0) INTO r106 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=29740;
 SELECT COALESCE(MAX(rank_value),0) INTO r107 FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j WHERE id=7133;
 START TRANSACTION;
 SELECT account,class,race INTO v_account,v_class,v_race FROM characters WHERE guid=p_guid FOR UPDATE;
 IF v_account<>p_account OR v_class<>13 OR v_race<>1 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 SELECT revision INTO v_revision FROM reborn_wd5a_builds WHERE guid=p_guid FOR UPDATE;
 IF v_revision<0 OR v_revision<>p_revision OR v_revision>=2000000000 THEN ROLLBACK;SELECT 2 AS result;LEAVE proc;END IF;
 SELECT ae,te INTO v_ae,v_te FROM reborn_wd67_budget WHERE level<=p_level ORDER BY level DESC LIMIT 1;
 SELECT v_ae+COALESCE(MAX(extra_ae),0),v_te+COALESCE(MAX(extra_te),0) INTO v_ae,v_te
 FROM reborn_wd95_test_points WHERE guid=p_guid AND account=p_account;

 IF r107<>0 AND (p_level<24 OR r101=0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r106<>0 AND (p_level<59 OR r105=0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r105<>0 AND (p_level<57 OR r74=0 OR r75=0 OR r92=0 OR r49+r50+r51+r53+r55+r56+r57+r61+r62+r77+r78+r79+r80+r81+r82+r83+r84+r85+r86+r87+r88+r89+r90+r91+r92+r93+r94+r95+r96+r97+r99+r100<23) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r104<>0 AND (p_level<50 OR r98=0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r102<>0 OR r103<>0) AND (p_level<57 OR r74=0 OR r49+r50+r51+r53+r55+r56+r57+r61+r62+r77+r78+r79+r80+r81+r82+r83+r84+r85+r86+r87+r88+r89+r90+r91+r92+r93+r94+r95+r96+r97+r99+r100+r101<23) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r102<>0 AND r92=0 AND r79=0 AND r80=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r103<>0 AND r102=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r99<>0 OR r100<>0 OR r101<>0) AND (p_level<10 OR r74=0 OR r49+r50+r51+r53+r55+r81<8) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r99<>0 AND (p_level<16 OR r56=0 OR r85=0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r100<>0 AND r97=0 AND r61=0 AND r62=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r101<>0 AND (r100=0 OR r49+r50+r51+r53+r55+r56+r57+r61+r62+r77+r78+r79+r80+r81+r82+r83+r84+r85+r86+r87+r88+r89+r90+r91+r92+r93+r94+r95+r96+r97+r99+r100<23) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r98<>0 AND (p_level<40 OR r54=0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r96<>0 OR r97<>0) AND (p_level<10 OR r74=0 OR r75=0 OR r49+r50+r51+r53+r55+r81<8) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r96<>0 AND r85=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r97<>0 AND r91=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r93<>0 OR r94<>0 OR r95<>0) AND (p_level<10 OR r74=0 OR r49+r50+r51+r53+r55+r81<8) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r93<>0 AND (p_level<29 OR (r81=0 AND r78=0)) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r94<>0 AND r81=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r95<>0 AND ((r78=0 AND r85=0) OR r56<>0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r91<>0 OR r92<>0) AND (p_level<10 OR r74=0 OR r49+r50+r51+r53+r55+r81<8) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r89<>0 AND r90<>0) OR ((r88<>0 OR r89<>0 OR r90<>0) AND r74=0) OR ((r89<>0 OR r90<>0) AND r49+r50+r51+r53+r55+r81<8) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r82<>0 OR r83<>0 OR r84<>0 OR r85<>0 OR r86<>0 OR r87<>0) AND r49+r50+r51+r53+r55+r81<8 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r83>2 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r85<>0 AND r74=0 AND r0=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r81<>0 AND p_level<17 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r79<>0 AND r80<>0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r77>2 OR ((r77<>0 OR r78<>0 OR r79<>0 OR r80<>0) AND r49+r50+r51+r53+r55+r81<8) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF ((r75<>0 OR r76<>0) AND r74=0 AND r0=0) OR (r76<>0 AND p_level<14) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF ((r71<>0 OR r72<>0 OR r73<>0) AND p_level<26) OR ((r72<>0 OR r73<>0) AND r71=0) OR (r72<>0 AND r73<>0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r70<>0 AND p_level<30 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r69>2 OR r58<>0 OR (r64<>0 AND r48<>0) OR ((r63<>0 OR r64<>0 OR r65<>0 OR r67<>0 OR r68<>0 OR r69<>0 OR r70<>0 OR r71<>0 OR r72<>0 OR r73<>0) AND r0+r1+r2+r3+r4+r5+r39+r60+r66<9) OR ((r58<>0 OR r59<>0) AND r0+r1+r2+r3+r4+r5+r39+r60+r66<9) OR (r58<>0 AND p_level<58) OR (r59<>0 AND p_level<30) OR ((r61<>0 OR r62<>0) AND p_level<31) OR (r61<>0 AND r62<>0) OR ((r61<>0 OR r62<>0) AND r49+r50+r51+r53+r55+r81<8) OR ((r56<>0 OR r57<>0) AND r49+r50+r51+r53+r55+r81<8) OR (r56<>0 AND p_level<16) OR (r57<>0 AND p_level<30) OR (r52<>0 AND p_level<20) OR (r54<>0 AND p_level<30) OR (r47<>0 AND p_level<28) OR (r48<>0 AND p_level<32) OR (r45<>0 AND p_level<50) OR (r42<>0 AND (p_level<59 OR r7+r8+r9+r10+r11+r12+r13+r29<8)) OR (r44<>0 AND p_level<59) OR ((r43<>0 OR r44<>0) AND (p_level<57 OR r7+r8+r9+r10+r11+r12+r13+r29+r15+r16+r17+r18+r19+r20+r21+r22+r23+r24+r25+r26+r27+r28+r30+r33+r38+r42<23)) OR ((r40<>0 OR r41<>0 OR r46<>0 OR r47<>0 OR r48<>0) AND r0+r1+r2+r3+r4+r5+r39+r60+r66<9) OR (r40<>0 AND p_level<28) OR (r39>2) OR (r38<>0 AND (p_level<27 OR r7+r8+r9+r10+r11+r12+r13+r29<8)) OR ((r36<>0 OR r37<>0) AND p_level<57) OR (r37<>0 AND r36=0) OR (r32<>0 AND p_level<30) OR (r33<>0 AND p_level<33) OR ((r34<>0 OR r35<>0 OR r36<>0 OR r37<>0) AND r7+r8+r9+r10+r11+r12+r13+r15+r16+r17+r18+r19+r20+r21+r22+r23+r24+r25+r26+r27+r28+r29+r30+r33+r38+r42<23) OR (r31<>0 AND p_level<40) OR (r14<>0 AND p_level<20) OR ((r15<>0 OR r16<>0 OR r17<>0 OR r18<>0 OR r19<>0 OR r20<>0 OR r21<>0 OR r22<>0 OR r23<>0 OR r24<>0 OR r25<>0 OR r26<>0 OR r27<>0 OR r28<>0 OR r30<>0 OR r33<>0) AND r7+r8+r9+r10+r11+r12+r13+r29<8) OR (r15<>0 AND r16<>0) OR (r49>2 OR r50>2 OR r51>2 OR r2>2 OR r21>2 OR r29>2 OR r30>2) OR r0+r1+r2+r3+r4+r5+r39+r40+r41+r46+r47+r48+r58+r59+r60+r63+r64+r65+r66+r67+r68+r69+r70+r71+r72+r73>v_ae OR r7+r8+r9+r10+r11+r12+r13+r15+r16+r17+r18+r19+r20+r21+r22+r23+r24+r25+r26+r27+r28+r29+r30+r33+r34+r35+r36+r37+r38+r42+r43+r44+r49+r50+r51+r53+r55+r56+r57+r61+r62+r77+r78+r79+r80+r81+r82+r83+r84+r85+r86+r87+r88+r89+r90+r91+r92+r93+r94+r95+r96+r97+r99+r100+r101+r102+r103+r105+r106+r107>v_te OR (r7<>0 AND (p_level<11 OR r5=0 OR r6=0)) OR (r12<>0 AND p_level<15) OR (r10<>0 AND p_level<15) OR (JSON_LENGTH(p_nodes)>0 AND p_level<10) OR (r4<>0 AND p_level<16)
 OR (r1<>0 AND r0=0 AND r5=0) OR ((r2<>0 OR r3<>0) AND r1=0) OR (r4<>0 AND r2=0 AND r3=0)
 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;

 IF NOT EXISTS(SELECT 1 FROM reborn_wd67_members WHERE guid=p_guid AND enabled=1)
 OR NOT EXISTS(SELECT 1 FROM reborn_wd13_slots WHERE guid=p_guid AND slot=p_slot)
 OR NOT EXISTS(SELECT 1 FROM reborn_wd16_profiles WHERE guid=p_guid AND slot=p_slot AND spec<3)
 OR ((r6<>0 OR r7<>0 OR r8<>0 OR r9<>0 OR r10<>0 OR r11<>0 OR r12<>0 OR r13<>0 OR r14<>0 OR r15<>0 OR r16<>0 OR r17<>0 OR r18<>0 OR r19<>0 OR r20<>0 OR r21<>0 OR r22<>0 OR r23<>0 OR r24<>0 OR r25<>0 OR r26<>0 OR r27<>0 OR r28<>0 OR r29<>0 OR r30<>0 OR r31<>0 OR r32<>0 OR r33<>0 OR r34<>0 OR r35<>0 OR r36<>0 OR r37<>0 OR r38<>0 OR r42<>0 OR r43<>0 OR r44<>0 OR r45<>0) AND NOT EXISTS(SELECT 1 FROM reborn_wd16_profiles WHERE guid=p_guid AND slot=p_slot AND spec=0))
 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF (r49+r50+r51+r52+r53+r54+r55+r56+r57+r61+r62+r74+r75+r76+r77+r78+r79+r80+r81+r82+r83+r84+r85+r86+r87+r88+r89+r90+r91+r92+r93+r94+r95+r96+r97+r98+r99+r100+r101+r102+r103+r104+r105+r106+r107>0) AND NOT EXISTS(SELECT 1 FROM reborn_wd16_profiles WHERE guid=p_guid AND slot=p_slot AND spec=1)
 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 -- Identity and revision row locks above serialize every update for this character.
 -- Unknown existing rows fail closed; never silently replace a newer build.
 IF EXISTS(SELECT 1 FROM reborn_wd67_nodes n LEFT JOIN reborn_wd_node_def d ON n.node_id=d.node_id
 WHERE n.guid=p_guid AND (d.node_id IS NULL OR n.node_rank>d.max_rank))
 OR EXISTS(SELECT 1 FROM reborn_wd67_nodes n LEFT JOIN
 JSON_TABLE(p_nodes,'$[*]' COLUMNS(id BIGINT PATH '$[0]',rank_value INT PATH '$[1]')) j ON j.id=n.node_id
 WHERE n.guid=p_guid AND n.slot=p_slot AND (j.id IS NULL OR j.rank_value<n.node_rank))
 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 DELETE FROM reborn_wd67_nodes WHERE guid=p_guid AND slot=p_slot;
 INSERT INTO reborn_wd67_nodes(guid,slot,node_id,node_rank) SELECT p_guid,p_slot,id,rank_value FROM JSON_TABLE(p_nodes,'$[*]' COLUMNS(id INT PATH '$[0]',rank_value INT PATH '$[1]')) j;
 UPDATE reborn_wd5a_builds SET revision=revision+1 WHERE guid=p_guid;
 COMMIT;SELECT 1 AS result;
END$$
DELIMITER ;
