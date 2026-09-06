-- RebornWOW custom Monk (class 14) gameplay script bindings.
-- Spell.dbc/visual/sound records are distributed through the matching client
-- and server runtime package; this migration owns only world DB bindings.

DELETE FROM `spell_script_names`
WHERE (`spell_id` = 9001502 AND `ScriptName` = 'spell_reborn_monk_tiger_palm_animation')
   OR (`spell_id` = 9001504 AND `ScriptName` = 'spell_reborn_monk_expel_harm')
   OR (`spell_id` = 9001505 AND `ScriptName` = 'spell_reborn_monk_roll')
   OR (`spell_id` = 9001507 AND `ScriptName` = 'spell_reborn_monk_blackout_kick')
   OR (`spell_id` = 9001510 AND `ScriptName` = 'spell_reborn_monk_jab')
   OR (`spell_id` = 9001513 AND `ScriptName` = 'spell_reborn_monk_rising_sun_kick');

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
    (9001502, 'spell_reborn_monk_tiger_palm_animation'),
    (9001504, 'spell_reborn_monk_expel_harm'),
    (9001505, 'spell_reborn_monk_roll'),
    (9001507, 'spell_reborn_monk_blackout_kick'),
    (9001510, 'spell_reborn_monk_jab'),
    (9001513, 'spell_reborn_monk_rising_sun_kick');
