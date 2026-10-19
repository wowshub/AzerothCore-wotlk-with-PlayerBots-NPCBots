# DCBATCH20261019 — 清本面板改版、副本记录、队友托管、playerbots 修复（Claude）

- 日期：2026-10-19。
- 用户原话："前面以及昨晚的都测试通过了 帮我一个一个推送吧 血条也测试通过了 其他面板 也改进的很棒"。
- 范围：待测清单 K17–K46（`000Ascendupdate/000Ascendupdate20261017/待测清单_Claude_20261017.md`），即 9fea152ae 之后 Claude 在 `000Ascendupdate20261018` 下的全部候选包。
  - 用户实测过的有：五栏面板、常用组、按钮外观、副本记录、阵营旗帜、职责色块、多选、血条。
  - 其余由上面这句话确认为通过。
  - 都属于"基本通过"，不外推所有副本、所有职业、长时间压力或异常矩阵。
- 父提交：9fea152ae（DCBATCH20261018）。

## 主仓库：每个服务端包一个提交

| 功能 | 提交 | 内容 |
|---|---|---|
| DCUI3B | 84c82cf452a879f544363969d2fa82930618a525 | 五栏面板的服务端列表：副本、名单、真人（新文件 DcPanelData.h/.cpp；conf `DungeonClear.PartyPicker.RealPlayers`） |
| DCUI3B5 | 309c0c66c2db1b9922aaa3d07d0d59e8ca2a4697 | RebornWindowScale 跳过清本面板（面板自己缩放） |
| DCUI3C3 | 01613666cc214bb3f001933a4a8fec4eed13d9df | 按职责从在线机器人补满队伍 |
| DCRUN1A | 3d84ca410f6639ed857d9ca4115214fcc1b0f3ea | 自己带队的副本记录（新文件 DcPlayerRuns.h/.cpp；`dc_playerruns.jsonl`） |
| DCTEST8A | 8d72ee53c4f1668f3c671ed78897db36750f32a8 | 测试窗口选人的机器人池分类 |
| DCGM1C | d52ebd60f01903429683c54d8b7fc691f328ab78 | 我加入测试队伍（可无敌） |
| DCSB2A | 6a37809509e957ff205f479c9f23c9888dd05651 | 队伍清本时询问真人队友托管或手动 |
| DCUI3C5 | e517baff850cb614b081d05e294694bcf5cd22c8 | 面板的队伍职责（我排第一，然后坦克/治疗/输出） |
| MBC1A | c02cb60847e1c895cf6f27b1a69d0d5c2f41454e | MultiBot 巫医、武僧职业、图标、筛选按钮（首次纳入 `Core/MultiBot.lua`） |
| LFG81B | 39b73d3ff8304f2208849190fd0e122c9441b711 | 新插件 RebornLFG81：81 级以上显示巫妖王普通本与随机普通 |
| DCSB2B | 8ab3a526251887f6b90006f9b1b992cb9f4c7af2 | 托管的真人不再抢坦克机器人的领队 |
| PBSELF1A | 084517e8fd713b790e9c540cfbccbdf333ce39eb | 托管逃跑防崩溃、飞行点作弊清除（含子模块） |
| PBUP1A | 2b2da2fa3483ce4776048fa7203741f4fa569432 | 子模块：上游 #2697、#2710 |
| DCRUN1B | 8be1836b3deaf1ffc5bfc867620f269cf9379436 | 队伍里的真人都有副本记录 |
| MBC1B | 6570136f059a07ab38bbcef79235b43f38944a26 | 子模块：机器人名单带巫医、武僧职业名 |
| DCSB2C | 9531983f9e332c1ec88a73c66c25482d89663558 | 每局都询问队友托管，读条丢失时重发 |

## playerbots 子模块

wowshub/mod-playerbots 分支 `reborn-dcai1a-20261009`：b0369e51 → a09f38ed8a664e92539ab290d4f3ab9fe526bf95，主仓库 gitlink 同步。

| 功能 | 子模块提交 | 文件 |
|---|---|---|
| PBSELF1A | 50ecc980b3b5fbc2281bf9710724b8ce7dd2f370 | MovementActions.cpp（Flee 只对生物取仇恨目标，上游 #2731 未修）、PlayerbotMgr.cpp（关闭托管清 taxi cheat，移植上游 #2824） |
| PBUP1A | d1aee0b45c7ed17f63117ce4cbabe182afe322ab | LootAction.cpp（上游 #2697）、NewRpgBaseAction.cpp（上游 #2710） |
| MBC1B | a09f38ed8a664e92539ab290d4f3ab9fe526bf95 | PlayerbotMgr.cpp（ListBots 职业名补 WitchDoctor/Monk） |

## 核对

- 重放链条：每个包覆盖前，发布工作树（及子模块克隆）里的对应文件都与该包的"原文件备份"一致（换行统一为 LF 后比较）。
- 最终比对：主仓库 17 个服务端文件、子模块 4 个文件与用户编译并实测的现场源码完全一致（换行统一为 LF 后比较）。用户现场 worldserver.exe（10-19 02:37）含本批新代码（核对了 PBSELF1A、MBC1B 的字符串）。
- 编译检查：各包都做过 `cl /Zs`（MSVC 14.44，modules.vcxproj RelWithDebInfo 参数）0 错误，并做反向验证；最后 5 个包叠在一起又检查了一次，0 错误。
- 新增文件：`DcPanelData.h/.cpp`（DCUI3B）、`DcPlayerRuns.h/.cpp`（DCRUN1A）。新装时需要 CMake Generate。

## 客户端

- DungeonClear 插件在独立仓库 wowshub/mod-dungeon-clear-addon：v3.6-reborn39 … v3.6-reborn73，35 个提交（每个包一个），最终 86057003b434ab57359fb875b0ba2b33e429caf7，tag v3.6-reborn73。附件 DungeonClear-3.6-reborn73.zip（含 Art 三张背景）SHA256 `313ad208b0dc10a0f86012a63d88d7a3f0f1540c925e4497cafc0c27774ef279`。
- 本仓库 Release 附件 `reborn-dcbatch2-20261019-client.zip`：MultiBot（含 4 个新图标 BLP）、RebornLFG81、RebornWindowScale 的变更文件，取自候选包；文本文件与 `data/reborn-client` 镜像逐字节一致。逐文件 SHA256：

```
9f38ae5ca23873bdd5dc0d9fed0fce928c100205ccc1432df10b640b303c7a12  Interface/AddOns/MultiBot/Core/MultiBot.lua
48a8ba683655362a03500ba2d47ea4a0ae39b89ba29cfcf85f6d7f1f843ac792  Interface/AddOns/MultiBot/Core/MultiBotInit.lua
968fef792986902103c65a4f6e627c045690ab52e1ab92f2d23c6331751d7d9f  Interface/AddOns/MultiBot/Features/MultiBotRebornRoster.lua
4c2e445af4bd7c80dcb1441a735047e8e5e4be2e746542b8e03e9ae67cd997e5  Interface/AddOns/MultiBot/Icons/class_monk.blp
b96fa87c40b5900f330f2d8a76a8c441aaddd12ff93ce941fc48a198b8eddedd  Interface/AddOns/MultiBot/Icons/class_witchdoctor.blp
d92bba74061bed342354a4a919ba7c2f7db5c8662816dddcccb9ab85c04123d5  Interface/AddOns/MultiBot/Icons/filter_monk.blp
9cd83209f06d26f78712ce98559f98a613f934f15f851eac088bc3bd0e42a9bf  Interface/AddOns/MultiBot/Icons/filter_witchdoctor.blp
9e42b7b0fafc22f0e2fadc0738f59ed0f006efcc07ae8fc2cc15e872e62bf58b  Interface/AddOns/MultiBot/Locales/MultiBotLanguage-zhCN.lua
71abc50b8644bd141e829fdcc1dd264a5c7b1bbaca8cc5c2556db305f29c7255  Interface/AddOns/RebornLFG81/RebornLFG81.lua
9ff1bce42f55decd8917517d35a2db05121371745724ea2d46d42af489ec22c9  Interface/AddOns/RebornLFG81/RebornLFG81.toc
c26e57677868cc84db9246ef108cbea86feb858817983064ff461ec15f22ecd7  Interface/AddOns/RebornWindowScale/RebornWindowScale.lua
587d6fa42280a216c3978198db23cee3d2ba3e0e7740e099f66f646d02a7f86a  Interface/AddOns/RebornWindowScale/RebornWindowScale.toc
```

## 边界

- 没有 SQL、DBC、MPQ 改动，没有部署，没有生产 SQL，没有编译 EXE 上传。
- 英雄本装等要求（`dungeon_access_template.min_avg_item_level`）未改；如需放开由用户自行执行 LFG81B README 里的 SQL。
- 已知：playerbots 没有巫医职业 AI，托管或机器人巫医只会普通攻击；DCRUN1B 之前的旧记录只在队长名下。
