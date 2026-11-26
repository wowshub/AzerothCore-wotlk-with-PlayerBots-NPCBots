-- HARPY1B V1 (2026-11-25, Claude): quest map markers (POI) for 59943-59947, map 12175, WorldMapArea 20414. Candidate, NOT user-tested.
-- Retail (LoreWalkerTDB quest_poi_points) positions: Bloodbeak area (494,-2355), harpy area polygon, totem area polygon, turn-ins.
-- 3.3.5 draws the numbered circles / quest area on the world map and the minimap from these rows. Safe to run twice.
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (59943,59944,59945,59946,59947);
DELETE FROM `quest_poi` WHERE `QuestID` IN (59943,59944,59945,59946,59947);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(59943, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59944, 0, 0, 12175, 20414, 0, 0, 1, 0),
(59944, 1, -1, 12175, 20414, 0, 0, 1, 0),
(59945, 0, 0, 12175, 20414, 0, 0, 1, 0),
(59945, 1, -1, 12175, 20414, 0, 0, 1, 0),
(59946, 0, 0, 12175, 20414, 0, 0, 1, 0),
(59946, 1, -1, 12175, 20414, 0, 0, 1, 0),
(59947, 0, -1, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(59943, 0, 0, 385, -2454, 0),
(59943, 0, 1, 403, -2454, 0),
(59943, 0, 2, 403, -2436, 0),
(59943, 0, 3, 385, -2436, 0),
(59944, 0, 0, 485, -2364, 0),
(59944, 0, 1, 503, -2364, 0),
(59944, 0, 2, 503, -2346, 0),
(59944, 0, 3, 485, -2346, 0),
(59944, 1, 0, 377, -2452, 0),
(59944, 1, 1, 395, -2452, 0),
(59944, 1, 2, 395, -2434, 0),
(59944, 1, 3, 377, -2434, 0),
(59945, 0, 0, 499, -2586, 0),
(59945, 0, 1, 554, -2529, 0),
(59945, 0, 2, 500, -2376, 0),
(59945, 0, 3, 423, -2419, 0),
(59945, 1, 0, 382, -2451, 0),
(59945, 1, 1, 400, -2451, 0),
(59945, 1, 2, 400, -2433, 0),
(59945, 1, 3, 382, -2433, 0),
(59946, 0, 0, 501, -2590, 0),
(59946, 0, 1, 552, -2514, 0),
(59946, 0, 2, 481, -2452, 0),
(59946, 0, 3, 430, -2487, 0),
(59946, 1, 0, 381, -2453, 0),
(59946, 1, 1, 399, -2453, 0),
(59946, 1, 2, 399, -2435, 0),
(59946, 1, 3, 381, -2435, 0),
(59947, 0, 0, 176, -2292, 0),
(59947, 0, 1, 194, -2292, 0),
(59947, 0, 2, 194, -2274, 0),
(59947, 0, 3, 176, -2274, 0);
SELECT (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` BETWEEN 59943 AND 59947) AS poi_rows_must_be_8,
       (SELECT COUNT(*) FROM `quest_poi_points` WHERE `QuestID` BETWEEN 59943 AND 59947) AS point_rows_must_be_32;
