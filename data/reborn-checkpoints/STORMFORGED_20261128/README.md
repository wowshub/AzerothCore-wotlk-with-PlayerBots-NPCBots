# Source checkpoint and local resource provenance

This checkpoint records the user-accepted Stormforged port. `client-source/src` is the exact accepted client snapshot. `server-source/src` and `server-diffs` preserve the race-specific server edits against their actual local baseline; they are not a promise that the older public core has every prerequisite integrated.

Custom Glue source is in `data/reborn-client/Interface/GlueXML/RebornCreator.lua`; the world installation SQL is in `data/customfixsql/world/stormforged`. Existing tested installations must not rerun initial-install SQL.

Binary game resources remain local under the project's dated update/release folder. `resources-manifest.json` provides per-file SHA256 and provenance, `source-packages.json` records the immutable packages. No original game assets, DBC, MPQ, EXE/PDB, crash dumps, account configuration or player database is committed or uploaded.

Generation scripts reproduce the archived workspace pipeline with separately obtained local donor resources and the documented `stormforged-intake/bodygear1a` layout. They do not embed or download the source game assets. Body/cape overlays must remain intact when later changing attachments.
