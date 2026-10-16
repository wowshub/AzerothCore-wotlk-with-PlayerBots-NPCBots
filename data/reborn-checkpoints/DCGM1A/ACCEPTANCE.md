# DCGM1A / DCGM1A2 / DCTEST6A 验收记录

- 日期：2026-10-16；开发：Claude；验收：用户。
- 用户原话："测试通过 开始修理掉落问题""命令都可以用了"。
- 部署的 worldserver.exe（10-16 06:15）包含 `allbuttank`、`TRFC`、`DCGM1A`；`Playerbots.log` 有 `TESTRUN tr-20261016-070707-2 DCGM1A Uldal god on / clear / tele` 等实际执行记录。
- 现场源码 8 个文件、客户端插件 3 个文件与候选包最终输出逐字节一致（DCGM1A 的 3 个服务端文件与插件被 DCTEST6A 累积覆盖）。

## 内容
- **DCGM1A**：`.dc test bot <run> <who> <die|rez|god|power|tele|clear> [on|off]`，只限 GM，在世界线程执行。使用核心的 CHEAT_GOD / CHEAT_POWER；每次操作写入测试记录 `cheats`（schema 15）；测试结束时清除所有作弊。插件：右键成员显示"GM 操作"，队伍标题旁有"队伍操作"，成员行显示 `[无敌]`、`[无限蓝]`。
- **DCGM1A2**：修复"队伍操作"按钮在依赖定义之前创建，导致 Lua 报 nil。
- **DCTEST6A**：服务端保留最近 20 个已结束测试的记录（TRF/TRFC/TRFR），统计在测试结束后仍可读。插件把已结束测试保存在账号里（最多 50 条），右键可看统计、再测一次（"我的角色"测试用原角色）、填到左边、删除、全部删除。

## 未单独验证
- 每个群体命令和每种目标逐一验证；用户总体确认"命令都可以用了"。
- 50 条上限截断；服务器重启后已看过的统计是否保留；"我的角色"重测。

## 候选包
`000Ascendupdate/000Ascendupdate20261016/` 下的 `claudefix_20261016_043829_阶段DCGM1A_测试队GM操作`、`claudefix_20261016_053205_阶段DCGM1A2_队伍操作按钮报错`、`claudefix_20261016_055203_阶段DCTEST6A_测试记录保留`。
插件仓库 wowshub/mod-dungeon-clear-addon v3.6-reborn19–21，tag v3.6-reborn21（d3d5c3a8）。
