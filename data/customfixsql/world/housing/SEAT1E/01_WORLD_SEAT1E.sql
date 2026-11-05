-- WORLD DATABASE. SEAT1E: beds and bedrolls become lie-down furniture (gameobject type 7, Data5 = 1 marks a bed, Data6 = height offset in cm; Data0-Data4 stay exactly like a stool so the client shows the gear).
-- Needs the housing module build with SEAT1B (RebornHousing.cpp). Safe to run more than once, replaces the first SEAT1B SQL (Data1=10 was reset by the core).
-- Restart the world server afterwards; players delete Cache\WDB once. Tune Data3 (height) / Data0 (seats) here if a bed is off.
SET NAMES utf8mb4;

-- 1 seat(s), +12 cm: 4 pieces
--   9200019  sherpa bedroll 01  (bedroll)
--   9200020  sherpa bedroll 02  (bedroll)
--   9200371  12ve voidelf furniture bedroll01  (bedroll)
--   9200372  12ve voidelf furniture bedroll02  (bedroll)
UPDATE `gameobject_template` SET `type`=7, `Data0`=1, `Data1`=1, `Data2`=0, `Data3`=0, `Data4`=0, `Data5`=1, `Data6`=12 WHERE `entry` IN (9200019,9200020,9200371,9200372) AND `name` LIKE 'Reborn H3A:%';

-- 1 seat(s), +85 cm: 1 pieces
--   9200145  11ea earthen massagebed01  (massage)
UPDATE `gameobject_template` SET `type`=7, `Data0`=1, `Data1`=1, `Data2`=0, `Data3`=0, `Data4`=0, `Data5`=1, `Data6`=85 WHERE `entry` IN (9200145) AND `name` LIKE 'Reborn H3A:%';

-- 1 seat(s), +105 cm: 3 pieces
--   9200210  12ph folk bed small01  (small)
--   9200252  12ph opulent bed small01  (small)
--   9200283  12ph rugged bed small01  (small)
UPDATE `gameobject_template` SET `type`=7, `Data0`=1, `Data1`=1, `Data2`=0, `Data3`=0, `Data4`=0, `Data5`=1, `Data6`=105 WHERE `entry` IN (9200210,9200252,9200283) AND `name` LIKE 'Reborn H3A:%';

-- 1 seat(s), +110 cm: 1 pieces
--   9200038  6or barracks bunkbed01  (bunk)
UPDATE `gameobject_template` SET `type`=7, `Data0`=1, `Data1`=1, `Data2`=0, `Data3`=0, `Data4`=0, `Data5`=1, `Data6`=110 WHERE `entry` IN (9200038) AND `name` LIKE 'Reborn H3A:%';

-- 1 seat(s), +115 cm: 20 pieces
--   9200012  pa house bed 02  (bed)
--   9200022  6dr draenei bed01  (bed)
--   9200032  6hu inn bed02  (bed)
--   9200062  7nb nightborn bed02a  (bed)
--   9200076  7ne druid bed01  (bed)
--   9200077  7ne druid bed02  (bed)
--   9200099  8hu kultiras bed01  (bed)
--   9200107  8tr zandalari bed02  (bed)
--   9200125  10dg dragon rounded bed01  (bed)
--   9200140  11ea earthen bed01  (bed)
--   9200149  11go goblin bed01  (bed)
--   9200162  11we wildelves furniture bed01  (bed)
--   9200163  11we wildelves furniture bed02  (bed)
--   9200172  12be bloodelf furniture bed01  (bed)
--   9200173  12be bloodelf furniture bed01 open  (bed)
--   9200200  12ph dwarf bed01  (bed)
--   9200209  12ph folk bed01  (bed)
--   9200356  12pm primitive furniture bed01  (bed)
--   9200379  dwarvenbed01  (bed)
--   9200388  gnomebed01  (bed)
UPDATE `gameobject_template` SET `type`=7, `Data0`=1, `Data1`=1, `Data2`=0, `Data3`=0, `Data4`=0, `Data5`=1, `Data6`=115 WHERE `entry` IN (9200012,9200022,9200032,9200062,9200076,9200077,9200099,9200107,9200125,9200140,9200149,9200162,9200163,9200172,9200173,9200200,9200209,9200356,9200379,9200388) AND `name` LIKE 'Reborn H3A:%';

-- 2 seat(s), +120 cm: 3 pieces
--   9200007  worgen bed large 02  (large)
--   9200251  12ph opulent bed large01  (large)
--   9200282  12ph rugged bed large01  (large)
UPDATE `gameobject_template` SET `type`=7, `Data0`=2, `Data1`=1, `Data2`=0, `Data3`=0, `Data4`=0, `Data5`=1, `Data6`=120 WHERE `entry` IN (9200007,9200251,9200282) AND `name` LIKE 'Reborn H3A:%';

-- check: should list 32 rows
SELECT COUNT(*) AS lie_down FROM `gameobject_template` WHERE `entry` BETWEEN 9200001 AND 9299999 AND `type`=7 AND `Data5`=1;
