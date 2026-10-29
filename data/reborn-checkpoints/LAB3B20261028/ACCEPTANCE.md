# LAB3B20261028 验收记录（掉落工坊：还原全部、日志大小与归档）

日期：2026-10-28。验收人：用户（实测）。整理：Claude。基线：wowshub/threemodelcardpro `9d060884c9`。
用户安装、编译、部署服务端，并自行执行生产SQL。

## 通过范围

| 编号 | 内容 | 验收 |
|---|---|---|
| LAB3B 归档并清理 | 日志页"归档并清理…"：先把 N 天前的旧日志写入 `lootlab_archive/*.jsonl`（worldserver.exe 所在目录），再从数据库删除，每张表保留最新一条，最后整理表 | 用户原话"可以了 测试通过"（2026-10-28）。归档与清理已实测 |
| LAB3A 还原全部 | "还原全部"按钮：按基线表把工坊改过的所有掉落表还原为官方内容，每张表写一条日志 | 用户看到并使用了界面，**未给出单独的通过结论**；包含在累计包内随发布，后续边用边验证 |
| LAB3B 日志大小 | 顶部居中按钮显示日志大小：绿 <20MB，橙 ≥20MB，红 ≥100MB，超限聊天栏提示一次 | 同上，颜色阈值在真实大日志下未实测 |
| 版本号 | 窗口标题版本改为读 toc（原为写死的 V2.0.0） | 用户反馈后修复，标题显示已按 toc |

## 一并更正

此前 DCRUN20261028 记录写"LAB2 编辑/添加/还原官方"，后来用户已实测：可以添加物品、还原官方（单个怪物）可用。以本记录为准。

## 重要：与本仓库无关但影响使用的服务器脚本

服务器运行文件 `lua_scripts/Gather_Rates.lua` 原来用 `command:find("ga")` 拦截命令，
所有含"ga"的 GM 命令（如 `.lootlab ui logarchive`、游戏物件页签 `gameobject`）都被当成采集倍率命令吞掉，
并回复 "Invalid gather rate"。已改为 `command == "ga" or command:match("^ga%s")`。
该文件不在 Git 中，换服务器目录时必须带上这一改动，并 `.reload eluna`。

## 未测

- 定时/手动时间点（LAB3C）尚未开发。
- 日志大小的橙/红颜色、聊天栏警告在真实大日志下未测。
- 归档目录配置 `RebornLootLab.Log.ArchiveDir` 使用相对路径以外的值未测。

## 安装

- 服务端：`modules/mod-reborn-lootlab` 有改动，重新编译 worldserver；`mod_reborn_lootlab.conf` 新增 `Log.WarnMB`、`Log.CriticalMB`、`Log.KeepDays`、`Log.ArchiveDir`（有默认值，不加也能用）。无SQL、无Data/DBC/MPQ。
- 客户端：覆盖 `Interface/AddOns/RebornLootLab`（2.2.0，lua + toc）。资源包 `reborn-lab3b20261028-resources.zip`。

## 来源

`claudefix_20261028_250000_阶段LAB3B_掉落工坊还原全部加日志大小与归档`（累计，含 LAB3A）。`backup_原文件` 与发布目录文件统一换行后逐一比对，4 处全部一致。

## 提交与资源

- 代码提交：`46d1daf36dcc3b5c9502568872ba5ea2c1bfbe36`
- 资源包 `reborn-lab3b20261028-resources.zip`，SHA256 `a26e181793450471295c3542ba2f59279b6c7e61e785bc27b742b9d6ccc2964d`：仅 RebornLootLab 两个文件（lua、toc）。Git 里保存同样内容的 `data/reborn-client/Interface/AddOns/RebornLootLab`。
