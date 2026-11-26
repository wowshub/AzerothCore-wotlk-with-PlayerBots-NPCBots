-- PIT1D V1 (2026-11-25, Claude): Hrun the Exiled respawns after 60 s instead of 300 s, so an interrupted/retaken quest 59949 does not wait long for him.
-- Safe to run twice. Keep worldserver stopped, restart after.
UPDATE `creature` SET `spawntimesecs` = 60 WHERE `id1` = 156900 AND `map` = 12175;
SELECT `guid`, `id1`, `spawntimesecs` FROM `creature` WHERE `id1` = 156900 AND `map` = 12175;
