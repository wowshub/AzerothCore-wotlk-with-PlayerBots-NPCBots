-- VEH4A V1 undo. Stop worldserver, run on the world database, delete lua_scripts/RebornBoarRule.lua, restart.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` IN (9167020, 9167021) AND `SourceEntry` = 46598;
SELECT COUNT(*) AS conditions_must_be_0 FROM `conditions` WHERE `SourceTypeOrReferenceId` = 18 AND `SourceGroup` IN (9167020, 9167021) AND `SourceEntry` = 46598;
