-- WORLD DATABASE. SEAT1A: the chairs, stools, benches and sofas of the server furniture become sittable (gameobject type 7).
-- Safe to run more than once. Restart the world server afterwards. Players must delete the client cache (Cache\WDB) once.
-- Data0 = seats, Data1 = sitting height (0 low, 1 medium, 2 high). Tune the numbers here if a piece sits wrong.
SET NAMES utf8mb4;

-- 1 seat(s), height 0: 3 pieces
--   9200154  11go goblin decor beanbagchair02  (lounge)
--   9200237  12ph leg 11ea earthen decor loungechair01  (lounge)
--   9200238  12ph leg 11go goblin decor beachchair01  (lounge)
UPDATE `gameobject_template` SET `type`=7, `Data0`=1, `Data1`=0, `Data2`=0, `Data3`=0 WHERE `entry` IN (9200154,9200237,9200238) AND `name` LIKE 'Reborn H3A:%';

-- 1 seat(s), height 1: 52 pieces
--   9200009  worgen rockingchair  (chair)
--   9200016  pa stool 02  (stool)
--   9200024  6dr draenei chair01  (chair)
--   9200029  6hu barracks woodstoolsmall  (stool)
--   9200040  6or garrison stool02  (stool)
--   9200043  6or inn stool01  (stool)
--   9200044  6or inn stool03  (stool)
--   9200065  7nb nightborn chair01  (chair)
--   9200086  7ne nightelf chair01  (chair)
--   9200088  7vr vrykul chair03  (chair)
--   9200089  8fk forsaken chair01  (chair)
--   9200090  8fk forsaken chair02  (chair)
--   9200096  8gn gnome chair01  (chair)
--   9200103  8hu kultiras chairlarge01  (chair)
--   9200104  8hu kultiras chairsmall02  (chair)
--   9200110  8tr zandalari chair01  (chair)
--   9200119  9vl aspirants chair01  (chair)
--   9200136  10rq reliquary chair01  (chair)
--   9200142  11ea earthen furniture chair01  (chair)
--   9200144  11ea earthen furniture rural chair01  (chair)
--   9200151  11go goblin casino fancychair01  (chair)
--   9200152  11go goblin chair03  (chair)
--   9200155  11go goblin furniture chair01  (chair)
--   9200160  11ko kobold stool01  (stool)
--   9200164  11we wildelves furniture chair01 sitmedium  (chair)
--   9200165  11we wildelves furniture chair02 sitmedium  (chair)
--   9200176  12be bloodelf furniture chair01  (chair)
--   9200177  12be bloodelf furniture fancychair01  (chair)
--   9200191  12fn fungarian furniture stool01  (stool)
--   9200201  12ph dwarf chair01  (chair)
--   9200208  12ph elwynn furniture stool01  (stool)
--   9200214  12ph folk chair01  (chair)
--   9200215  12ph folk chair dining large01  (chair)
--   9200216  12ph folk chair exterior01  (chair)
--   9200217  12ph folk chair small01  (chair)
--   9200226  12ph folk stool01  (stool)
--   9200234  12ph leg 10dg dragon stone living chair01  (chair)
--   9200235  12ph leg 10dg dragon stool01  (stool)
--   9200236  12ph leg 10ne nightelf stool01  (stool)
--   9200244  12ph leg 6hu inn smallchair01  (chair)
--   9200247  12ph leg 7ne nightelf chair03  (chair)
--   9200257  12ph opulent chair dining large01  (chair)
--   9200258  12ph opulent chair dining medium01  (chair)
--   9200259  12ph opulent chair dining small01  (chair)
--   9200270  12ph opulent stool01  (stool)
--   9200342  12ph shop spring cherryblossom chair01  (chair)
--   9200344  12ph shop spring gardengnome chair01  (chair)
--   9200364  12tr amani furniture stool01 sitmedium  (stool)
--   9200373  12ve voidelf furniture chair01  (chair)
--   9200374  12ve voidelf furniture stool01  (stool)
--   9200383  dwarvenhighendchair  (chair)
--   9200389  generalchairloend01  (chair)
UPDATE `gameobject_template` SET `type`=7, `Data0`=1, `Data1`=1, `Data2`=0, `Data3`=0 WHERE `entry` IN (9200009,9200016,9200024,9200029,9200040,9200043,9200044,9200065,9200086,9200088,9200089,9200090,9200096,9200103,9200104,9200110,9200119,9200136,9200142,9200144,9200151,9200152,9200155,9200160,9200164,9200165,9200176,9200177,9200191,9200201,9200208,9200214,9200215,9200216,9200217,9200226,9200234,9200235,9200236,9200244,9200247,9200257,9200258,9200259,9200270,9200342,9200344,9200364,9200373,9200374,9200383,9200389) AND `name` LIKE 'Reborn H3A:%';

-- 2 seat(s), height 0: 3 pieces
--   9200153  11go goblin couch01  (sofa)
--   9200194  12ph bloodelf decor chair porchswing01  (swing)
--   9200195  12ph bloodelf decor chair porchswing02  (swing)
UPDATE `gameobject_template` SET `type`=7, `Data0`=2, `Data1`=0, `Data2`=0, `Data3`=0 WHERE `entry` IN (9200153,9200194,9200195) AND `name` LIKE 'Reborn H3A:%';

-- 2 seat(s), height 1: 26 pieces
--   9200001  dr bench 01 nosound  (bench)
--   9200004  dalaran bench01  (bench)
--   9200049  6oc orcclans bench01  (bench)
--   9200063  7nb nightborn benchshort01  (bench)
--   9200108  8tr zandalari bench01  (bench)
--   9200123  10ct centaur logbench01  (bench)
--   9200124  10dg dragon bench04  (bench)
--   9200134  10ne nightelf bench01  (bench)
--   9200138  11xp bench02  (bench)
--   9200141  11ea earthen bench03  (bench)
--   9200143  11ea earthen furniture rural bench01  (bench)
--   9200150  11go goblin bench01  (bench)
--   9200174  12be bloodelf furniture bench01  (bench)
--   9200206  12ph elwynn furniture bench01  (bench)
--   9200207  12ph elwynn furniture bench02  (bench)
--   9200213  12ph folk bench short01  (bench)
--   9200224  12ph folk sofa medium01  (sofa)
--   9200225  12ph folk sofa small01  (sofa)
--   9200243  12ph leg 6hu barracks woodbenchsmall  (bench)
--   9200248  12ph leg pa innbench 01  (bench)
--   9200250  12ph leg worgen bench 02  (bench)
--   9200255  12ph opulent bench short01  (bench)
--   9200256  12ph opulent bench short01 nocloth  (bench)
--   9200268  12ph opulent sofa medium01  (sofa)
--   9200269  12ph opulent sofa small01  (sofa)
--   9200362  12tr amani furniture bench01 sitmedium  (bench)
UPDATE `gameobject_template` SET `type`=7, `Data0`=2, `Data1`=1, `Data2`=0, `Data3`=0 WHERE `entry` IN (9200001,9200004,9200049,9200063,9200108,9200123,9200124,9200134,9200138,9200141,9200143,9200150,9200174,9200206,9200207,9200213,9200224,9200225,9200243,9200248,9200250,9200255,9200256,9200268,9200269,9200362) AND `name` LIKE 'Reborn H3A:%';

-- 3 seat(s), height 1: 7 pieces
--   9200211  12ph folk bench exterior01  (bench)
--   9200212  12ph folk bench long01  (bench)
--   9200223  12ph folk sofa large01  (sofa)
--   9200253  12ph opulent bench exterior01  (bench)
--   9200254  12ph opulent bench long01  (bench)
--   9200266  12ph opulent sofa large01  (sofa)
--   9200267  12ph opulent sofa large01 nocloth  (sofa)
UPDATE `gameobject_template` SET `type`=7, `Data0`=3, `Data1`=1, `Data2`=0, `Data3`=0 WHERE `entry` IN (9200211,9200212,9200223,9200253,9200254,9200266,9200267) AND `name` LIKE 'Reborn H3A:%';

-- check: should list 91 rows
SELECT COUNT(*) AS sittable FROM `gameobject_template` WHERE `entry` BETWEEN 9200001 AND 9299999 AND `type`=7;
