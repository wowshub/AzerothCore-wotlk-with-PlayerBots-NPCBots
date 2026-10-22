-- Add only WD196B's binding. Existing scripts are preserved. Execute on World, then restart.
INSERT INTO spell_script_names (spell_id,ScriptName) SELECT 9003861,'spell_reborn_wd196_control' WHERE NOT EXISTS (SELECT 1 FROM spell_script_names WHERE spell_id=9003861 AND ScriptName='spell_reborn_wd196_control');
