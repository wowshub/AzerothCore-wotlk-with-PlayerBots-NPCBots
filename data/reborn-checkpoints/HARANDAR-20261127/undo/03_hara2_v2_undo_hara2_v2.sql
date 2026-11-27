-- undo HARA2 V2 (back to V1 values)
SET NAMES utf8mb4;
UPDATE `gameobject_template` SET `Data3` = 0, `castBarCaption` = 'Burning 点燃中' WHERE `entry` IN (553763, 554679, 546728, 554848, 554966);
