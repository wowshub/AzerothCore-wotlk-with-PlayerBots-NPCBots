# DCRUN20261024 — 宠物闲置修复、测试模式空栏修复，及其依赖（Claude）

- 日期：2026-10-24。
- 用户原话："昨天的两个修复都可以了 你可以推送并release"；范围确认（选项）："连同依赖一起发"。
- 用户实测通过：**DCPET1A**（K86，猎人宠物站着不打）、**DCUI4B5**（K85，测试模式三栏全空）。
- 作为依赖一起发布、在用户的版本里一直运行、**没有单独验收**：DCPREP1A（K83 准备度快照）、DCUI4B4（K82 本局统计滑块）、DCPREP1B（K84 准备度面板）。这两个修复的包是叠在它们之上的，用户装修复时它们也一起装上了。
- **不在本次范围**：DCHOL3A（K81 熔渣炉终点），未测。
- 父提交：wowshub/threemodelcardpro 的 6ba57ca1b（Codex 最新推送）。

## 主仓库（每个包一个提交）

| 功能 | 提交 | 状态 | 内容 |
|---|---|---|---|
| DCPREP1A | 043e98f84 | 依赖（未单独验收） | 新增 TestRun/DcPrepSnapshot.h/.cpp（需 CMake Generate）；记录 schema 23：comp[].prep、joined；插件命令 `prep [runId]`（PRP_* 消息） |
| DCPET1A | 57368d647 | **用户实测通过** | 营地按住后"改回防御"在宠物不在时不再丢失；测试局宠物看守 WatchPets（6 秒闲置 → 改回防御并派去打主人的目标，不引新怪），日志 DCPET1A |

## 客户端（wowshub/mod-dungeon-clear-addon）

| 版本 | 提交 | 功能 | 状态 |
|---|---|---|---|
| 3.6-reborn99 | 6082347 | DCUI4B4 本局统计滑块，刷新保持位置 | 依赖（未单独验收） |
| 3.6-reborn100 | a86cf61 | DCPREP1B 准备度面板（DungeonClearPrep.lua；标题栏按钮在"坐标"左边；窗口在大面板上一层） | 依赖（未单独验收） |
| 3.6-reborn101 | 1ece325 | DCUI4B5 停靠的测试窗口保持在测试视图之上（DCTestRepin + 停靠期间检查） | **用户实测通过** |

## 核对

- 重放链条：每个包覆盖前，工作树/插件仓库里对应文件与该包"原文件备份"一致（LF 统一后比较），0 问题；Codex 新推送的提交没有改到 mod-dungeon-clear。
- 编译检查：DCPREP1A、DCPET1A 各自 `cl /Zs`（MSVC 14.44）0 错误，反向验证 C2039；客户端 lupa 烟测 + 整个 DungeonClear.lua 语法加载通过。
- 完整程序由用户自行编译部署。
