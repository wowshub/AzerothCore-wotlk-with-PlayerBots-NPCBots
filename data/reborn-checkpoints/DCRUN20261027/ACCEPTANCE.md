# DCRUN20261027 — acceptance record

Date: 2026-10-27. Accepted by the user: "测试进来啦 通过 把今天昨天 做的修复都推送下吧"; scope chosen by the user in the
release prompt: DCNPC2A, the server part of DCGM2A, and MOPFIX1.

| Id | What | Test evidence | Not covered |
|---|---|---|---|
| DCNPC2A | Panel puts an NPCBot into the group (addon command `npcjoin`, `BotMgr::AddBotToGroup`; own hired bots, or the bots of an online same-account character that is already in the group). Client: Invite button / menu / drag for NPCBot rows, saved-group "Form" asks the server, a saved party now marks NPCBots. | User, logged in as Jorn, formed the saved group and the NPCBot of Ereer joined ("测试进来啦 通过"). | Other accounts' bots (refused by design); full group / raid conversion; bot not in the world. |
| DCGM2A (server) | `.dc party tank die` (who=tank: playerbot and NPCBot tanks). The client menu entry ships inside the DCNPC2A client files (reborn113 includes reborn112). | Selected by the user for this release. No separate test report was received. | Several tanks: all are killed. |
| MOPFIX1 | Guard in the third-party addon zzzMoPItemTooltips (Core.lua, 10 added lines, diff only: `mopfix1_Core.lua.diff`). The addon itself is not tracked here. | Selected by the user for this release. **Whether the 0x00620727 compare-tooltip crash is gone has not been verified in game.** | Crash cause is an inference from the crash file (no line numbers). |

Source: `modules/mod-dungeon-clear/src/DungeonClearCommand.cpp` (DCGM2A), `DungeonClearAddonHook.cpp` (DCNPC2A). Client addon: wowshub/mod-dungeon-clear-addon v3.6-reborn112 (DCGM2A) and v3.6-reborn113 (DCNPC2A).
Packages: 000Ascendupdate20261027/claudefix_20261027_120000_阶段DCGM2A_GM菜单加杀死坦克, claudefix_20261027_150000_阶段DCNPC2A_面板拉NPCBot进组, claudefix_20261027_130000_阶段MOPFIX1_装备对比提示崩溃防护.

Not part of this release (candidates or other lines): WDN6B, PBAOE1A, WDN5I, TG24B/TG31A (Codex); LootLab LAB1/LAB2, TREAS3A.
Server rebuild needed (user compiles and deploys); no SQL, no DBC.
