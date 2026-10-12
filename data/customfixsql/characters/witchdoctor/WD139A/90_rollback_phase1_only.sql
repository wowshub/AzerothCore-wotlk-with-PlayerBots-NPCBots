-- Only after reverting to a verified WD138 binary; no phase-2 nodes may exist.
-- This does NOT undo other members' changes. Character rows remain untouched.
DROP PROCEDURE IF EXISTS reborn_wd139_save;
DROP TRIGGER IF EXISTS reborn_wd139_node_insert;
DROP TRIGGER IF EXISTS reborn_wd139_node_update;
-- Reference table may safely remain for audit; do not drop character data.
