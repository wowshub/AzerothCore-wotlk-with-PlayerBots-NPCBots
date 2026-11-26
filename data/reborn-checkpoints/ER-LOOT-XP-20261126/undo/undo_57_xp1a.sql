-- undo XP1A V1
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 1 WHERE `ID` IN (54933, 54952, 55173, 55193, 58208, 59928, 59931, 59935, 59940, 59950);
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 2 WHERE `ID` IN (54951, 55122, 55174, 55184, 55186, 56034, 56775, 58209, 59254, 59926, 59927, 59929, 59930, 59932, 59933, 59938, 59941);
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 3 WHERE `ID` IN (55196, 55879, 55882, 55965, 56344, 59942, 59943, 59947, 59948, 59975);
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 4 WHERE `ID` IN (55194);
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 5 WHERE `ID` IN (55763, 55764, 55881, 55981, 55988, 55989, 55990, 59944, 59945, 59946, 59978, 59979, 59980, 59981);
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 6 WHERE `ID` IN (55639, 59949);
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 7 WHERE `ID` IN (56839);
UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = 8 WHERE `ID` IN (55991, 55992, 59984, 59985);
UPDATE `creature_template` SET `ExperienceModifier` = 1 WHERE `entry` IN (150228, 150229, 150238, 151091, 152843, 153239, 153266, 153581, 153582, 153583, 153964, 156501, 156814, 156900, 157300, 160394, 160433, 161130, 161131, 161133, 162817, 165150, 9159801, 9159802, 9159803);
