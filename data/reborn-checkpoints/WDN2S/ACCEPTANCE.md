# WDN2S cumulative NPC Witch Doctor acceptance — 2026-10-25
User: “这个几个包测试通过 推送 把”. Accepted latest delivered cumulative WDN2S package and its included earlier NPC fixes as basic gameplay tested. Not an exhaustive PvP/rank/performance/lifecycle certification.
All 25 source overlay files match the current daily source byte-for-byte. Source ZIP SHA256: 3560fda16db04c4ac5290e9c219a1018dc8c6b829eaf2950145b9b7015801d43.
Includes NPC combat/debuff/summon support, healing wards, Big Bad Voodoo, mushroom/potion healing, healer role and offensive-stop handling, failed single-target potion fallback, and cumulative crash guards.
Offline checks: 1139 AI, 322 role, 33 spell callback, 5 destination, 38 domain, 132 ward, 21 coefficient cases; API substitutes, not engine tests. Changed NPC CPP syntax passed.
No new SQL/Data/client addon/EXE. Existing NPC/WD120A/WD123A data remain prerequisites. UI and Playerbot development excluded. User builds/deploys. Original package retained unchanged.
Remaining planned scope: healing repertoire, defensive recovery, specialization/summon policies, final dungeon regression; estimate 3 feature batches + 1 regression batch, subject to actual defects.
