# DCRUN20261028 验收记录（清本、掉落工坊、宝箱）

日期：2026-10-28。验收人：用户（实测）。整理：Claude。基线：wowshub/threemodelcardpro `edb32897c`（含 Codex 的 MBWD/WDN/PBAOE 提交）。
本记录只写用户确认通过的范围；未测的写明原因，不外推。用户安装、编译、部署服务端，并自行执行生产 SQL。

## 一、本次发布的（用户实测通过）

| 编号 | 内容 | 验收范围与边界 |
|---|---|---|
| DCREC1A | 清本关闭后，记录页那一场按"所有者"补找并结束 | 用户确认：坦克死后清本关闭，记录显示"全清"，不再卡在"进行中"。**后来又遇到一次"进行中"残留，原因未查清（见 DCREC2A，未发布）** |
| DCUP2A | 合入上游 jrad7/mod-dungeon-clear 20 个 fix（上游 `7fb6ebd`，2026-10-26） | 用户在测试清单里确认通过（原话：除 DCHOL3A 外其余都测过、基本通过）；没有逐条给出每个上游修复的专项结论。**5 个防卡死项（停滞回退/仲裁器误报、5 码抖动、血色修道院陷阱通道、卡拉赞图书馆、ICC 英雄名单）需要真遇到才算，未专项验证；单元测试 `t/*.cpp` 未编译运行；CoA 职业托管后是否被选为复活者并真正施放未专项验证** |
| DCWD1A 第 1 步 | 法术账本（每人每个法术的施法、伤害、治疗，schema 24） | 用户确认通过。未测：账本"未归属"占比是否过高没有给出结论，后续步骤（固定放巫医、增益覆盖、客户端显示、报告页）都未做 |
| LAB1 | 掉落工坊（LootLab）只读浏览：10 个来源页签、模拟掉落、物品反查 | 用户确认通过。3D 模型取景、真实服务器 SQL 列名的边角情况未专项验证 |
| LAB2 | 掉落工坊编辑：撤销、还原官方、日志；默认关闭，需配置打开 | 用户确认通过。引用行暂不能编辑；`Edit.Lock`、权限的所有组合未逐一验证 |
| TREAS3A | 宝箱掉落条件与任务物品、按任务添加 | **部分通过**：任务物品（按任务 33 添加病狼皮毛）与"按任务添加"用户已测。**条件（阵营、职业、种族、等级、光环、背包物品、取反）未测：用户尚未试这些条件** |
| TREAS3B | 宝箱面板"任务测试"：给选中角色/指定角色名/自己接任务，去掉任务 | 用户确认通过（接任务、去掉任务、按名字、给自己） |

## 二、本次未发布的（标"未测"及原因，之后边玩边测）

| 编号 | 状态 | 原因 |
|---|---|---|
| DCHOL3A | 未测 | 用户还没清到闪电大厅熔渣炉那一关 |
| DCSTR2A / DCSTR2B / DCSTR2C | 2B 用户测试"传送距离正常"；2C 未测 | 追上传送在紫罗兰监狱曾使用户的托管角色掉进虚空，2C 是针对它的防护（传送前确认坦克脚下有地面），需要验证后一起发布，旧版不单发 |
| DCP1C-B / DCPREP2B | 未测 | 准备度面板的开打前警告、NpcBot 读取仍在修，NpcBot 巫医还没出现在面板里 |
| DCBAR2A | 用户确认顶栏数字一致 | 与上面几项改同一个客户端文件，随客户端一起发 |
| DCSET1A | 未测 | 清本面板"设置…"入口，刚做完 |
| DCREC2A | 未测 | 针对一次残留"进行中"记录的补漏，原因没证实 |
| MOPFIX1 | 此前已发布 | 崩溃（0x00620727）是否消除仍未验证，与本批无关 |

Codex 线（MBWD*、WDN*、PBAOE1A、天赋面板等）不在本批，沿用远端已有提交。

## 三、安装

- 服务端：`modules/mod-dungeon-clear`、`modules/mod-reborn-treasure` 有改动，新增 `modules/mod-reborn-lootlab`（需要重新生成 CMake）。重新编译 worldserver。无新增 Data/DBC/MPQ。
- world 库：执行 `data/customfixsql/world/lootlab/LAB0/LAB0_lootlab_tables.sql`（建 `reborn_lootlab_log`、`reborn_lootlab_baseline` 两张表，可重复执行）。
- 服务端配置：`mod_reborn_lootlab.conf` 中 `RebornLootLab.Edit.Enable = 1` 才能编辑（默认 0）。
- 客户端：`Interface/AddOns/RebornLootLab`（2.0.0）、`RebornTreasure`（1.6.0）覆盖到客户端。资源包 `reborn-dcrun20261028-resources.zip` 随 Release 附上。

## 四、来源包

DCWD1A 20261024、TREAS3A 20261025_150000、LAB1 20261025_170000、LAB2 20261026_020000、DCREC1A 20261028_090000、DCUP2A 20261028_110000、TREAS3B 20261028_210000。按此顺序放入发布目录，每个包的 `backup_原文件` 与放入前的发布目录文件逐一比对（统一换行后），0 处不一致。

## 五、提交与资源

- 清本（DCUP2A、DCWD1A、DCREC1A）：`8d99dd6e6`
- 掉落工坊（LAB1、LAB2）：`a179f933f`
- 宝箱（TREAS3A、TREAS3B）：`6671aad81`
- 资源包 `reborn-dcrun20261028-resources.zip`，SHA256 `7614620e944db67b58a2b969e102fd9b3a0e8669c2e3d5b14cc103f63c51b567`：RebornLootLab、RebornTreasure 两个客户端插件和 LAB0 SQL。Git 里保存的是同样内容的 `data/reborn-client` 与 `data/customfixsql/world/lootlab/LAB0`。
