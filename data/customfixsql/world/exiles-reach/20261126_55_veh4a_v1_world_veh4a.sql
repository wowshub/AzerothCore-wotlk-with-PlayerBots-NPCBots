-- VEH4A V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- Only a player who has the quest (Horde 59942 / Alliance 55879) with the cadaver objective unfinished can ride the giant boar.
SELECT COUNT(*) AS conditions_before_this_run_info FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` IN (9167020, 9167021) AND `SourceEntry` = 46598;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` IN (9167020, 9167021) AND `SourceEntry` = 46598;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`)
SELECT 18, 9167020, 46598, 0, 0, 9, 0, `ID`, 0, 0, 0, 0, 0, '', 'VEH4A boar: quest 59942 active' FROM `quest_template` WHERE `ID` = 59942
UNION ALL
SELECT 18, 9167020, 46598, 0, 0, 48, 0, `ID`, 0, `RequiredNpcOrGoCount1`, 1, 0, 0, '', 'VEH4A boar: quest 59942 cadaver objective not finished' FROM `quest_template` WHERE `ID` = 59942 AND `RequiredNpcOrGo1` = 165150
UNION ALL
SELECT 18, 9167021, 46598, 0, 0, 9, 0, `ID`, 0, 0, 0, 0, 0, '', 'VEH4A boar: quest 55879 active' FROM `quest_template` WHERE `ID` = 55879
UNION ALL
SELECT 18, 9167021, 46598, 0, 0, 48, 0, `ID`, 0, `RequiredNpcOrGoCount1`, 1, 0, 0, '', 'VEH4A boar: quest 55879 cadaver objective not finished' FROM `quest_template` WHERE `ID` = 55879 AND `RequiredNpcOrGo1` = 165150;
SELECT (SELECT COUNT(*) FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` IN (9167020, 9167021) AND `SourceEntry` = 46598) AS conditions_must_be_4,
       (SELECT `ConditionValue3` FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` = 9167020 AND `SourceEntry` = 46598 AND `ConditionTypeOrReference` = 48) AS horde_cadavers_must_be_6,
       (SELECT `ConditionValue3` FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` = 9167021 AND `SourceEntry` = 46598 AND `ConditionTypeOrReference` = 48) AS alliance_cadavers_must_be_8,
       (SELECT COUNT(*) FROM `npc_spellclick_spells` WHERE `npc_entry` IN (9167020, 9167021) AND `spell_id` = 46598) AS boar_click_rows_must_be_2;
