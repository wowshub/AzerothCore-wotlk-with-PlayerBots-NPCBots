-- 撤销 HARA4 V4 的首领改动(文字撤销见 V3，药剂撤销见 V2)
UPDATE `creature_template` SET `HealthModifier` = 3.0, `DamageModifier` = 1.1 WHERE `entry` = 248598;
UPDATE `smart_scripts` SET `event_param1` = 6000, `event_param2` = 9000 WHERE `entryorguid` = 248598 AND `source_type` = 0 AND `id` = 0 AND `action_param1` = 744;
