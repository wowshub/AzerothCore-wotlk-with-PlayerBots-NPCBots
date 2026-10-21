# WD170A: equip usable weapons and improve combat and summon decisions

2026-10-21 user explicitly selected the WD176A cumulative morning-test package for publication. Basic gameplay observation: improved damage output and use of the six-snake skill in addition to the regular serpent ward. This checkpoint identifies a component of that cumulative acceptance; it does not claim every individual transaction, ability, PvP or lifecycle matrix was separately measured.

Frozen source package: D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261020\codexfix_20261020_093359_阶段WD170A_暗影狩猎装备轮转走位与召唤回收累计包.zip
Original ZIP SHA256: 96b374600ad9cd74f93812f9fb4075bed6f7392139dab4e3f4f93cf6f1738da8
Playerbots commit: 09f142e7af5147bbbc340965c496de7e97468a05
Main parent before this stage: a2f338e233a759ee78d5b0652d89ea418a2b6c6f

Only this stage's delta was replayed onto the latest formal baseline. Unaccepted WD165/WD166 baseline changes and WD177–WD184 candidates are excluded. Existing Claude changes and unrelated workspace modifications remain. This is source publication, not EXE build/deployment. No new SQL, client, Data/DBC/MPQ or configuration is required.

Final cumulative integration: 22 changed production outputs, one unchanged Serpent dependency; all equivalent to the tested candidate after newline normalization except the explicitly excluded unrelated baseline. Four complete CPP /Zs checks passed on the final formal composition. Original WD176A 3011 offline tests remain archived; no claim of new full game/SQL/PvP coverage.

Known limitation discovered during continued testing on2026-10-21: WD170 equipment ranking may choose a high-score gun without carried bullets over a usable bow/arrow pair. The user reported repeated re-equipping and melee/follow behavior. This limits the equipment acceptance; a separate WD185 candidate will address it after testing. No claim that this release is a complete or stable class1.0.

Already tested users need not reinstall. Do not replace a newer WD177–WD184 candidate checkout with whole formal-baseline files; retain the active test version. Fresh users clone the main repository with the exact pinned Playerbots submodule and compile themselves. Follow source manifests and rollback only when files still match this release and no later work exists.
