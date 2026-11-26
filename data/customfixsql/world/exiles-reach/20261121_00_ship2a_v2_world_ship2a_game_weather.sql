-- SHIP2A: weather rows for the two ship zones (area ids 50532 horde ship, 50531 alliance ship).
-- All chances are 0 so no natural weather happens; the Lua script sets the storm by hand.
-- Safe to run twice.
DELETE FROM `game_weather` WHERE `zone` IN (50531, 50532);
INSERT INTO `game_weather` (`zone`, `spring_rain_chance`, `spring_snow_chance`, `spring_storm_chance`, `summer_rain_chance`, `summer_snow_chance`, `summer_storm_chance`, `fall_rain_chance`, `fall_snow_chance`, `fall_storm_chance`, `winter_rain_chance`, `winter_snow_chance`, `winter_storm_chance`, `ScriptName`) VALUES
(50531, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ''),
(50532, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '');
