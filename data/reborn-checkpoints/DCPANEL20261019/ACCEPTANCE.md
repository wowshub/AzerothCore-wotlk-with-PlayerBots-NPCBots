# DCPANEL20261019 — 清本面板三模式、测试模式嵌入、进队三种状态（Claude）

- 日期：2026-10-19。
- 用户原话："这次这个可以推送了 测试可以了 不是那么混乱了 现在推送吧"。
- 范围：待测清单 K47–K63（`000Ascendupdate/000Ascendupdate20261017/待测清单_Claude_20261017.md`），即 `000Ascendupdate20261019` 下 Claude 的 DCUI4A … DCTEST10E 共 17 个候选包。
  - 属于"基本通过"：用户测试了面板模式切换、测试模式嵌入、测试队伍血条、进队三种状态、再测一次、全部停止确认框。
  - 掉队传送（DCGM1C4 的 30 码规则）依赖用户部署的服务端，没有被单独报告验收；不外推。
  - 野外模式（DCFIELD1A）未开发。
- 父提交：606a607c8（Codex TG16A 发布）。

## 主仓库：服务端和主仓库客户端文件（每个有改动的包一个提交）

| 功能 | 提交 | 内容 |
|---|---|---|
| DCTEST9A | 86a8a4e4adbc163afdbff77b74f8477be8352eac | 测试队伍成员行加职业能量百分比（TRM 行） |
| DCTEST9D / WSC1G | 38daf472531927f6d084b1c18dfece625129700a | RebornWindowScale：被面板托管的窗口不再缩放、重设位置 |
| DCTEST10A | 88e6d4647c888c4ca1377b6bd09445eee99fde5a | 测试记录带开测 GM（schema 18），列表按 GM 区分 |
| DCTEST10B | b2c546a01fc214ef708409639d9688f2e3a42ac5 | 面板轮询带测试队伍编号；离线的加入者结束时移出机器人队伍 |
| DCGM1C3 | 778cfa3479e26d916b84e1abcdfcba506f50c25d | 加入者掉队 >50 码 8 秒传送到坦克 |
| DCGM1C4 | c29956111cbdda87632bb86b3822384555e4e97b | 掉队阈值 30 码、坦克须脱战，日志记卡住坐标 |

## 核对

- 重放链条：每个包覆盖前，发布工作树里的对应文件与该包的"原文件备份"一致（换行统一为 LF 后比较），0 问题。
- 编译检查：各服务端包均做过 `cl /Zs`（MSVC）0 错误并反向验证。
- 没有新增服务端文件，没有 SQL，没有 DBC。

## 客户端

- DungeonClear 插件在独立仓库 wowshub/mod-dungeon-clear-addon：v3.6-reborn74 … v3.6-reborn89，16 个提交，最终 bef2181583f22246c2ca6cdd3c866137e78d656b，tag v3.6-reborn89，附件 DungeonClear-3.6-reborn89.zip（SHA256 836d9f0f3dc5633dd8b84e8244d489769a98ac4fd37daaf6df5a3d6bd61a1f58）。
- 本仓库 Release 附件 `reborn-dcpanel-20261019-client.zip`：RebornWindowScale 两个文件（与 `data/reborn-client` 镜像逐字节一致）。

## 部署顺序（用户自行）

服务端：DCTEST9A → DCTEST10A → DCTEST10B → DCGM1C3 → DCGM1C4（重新编译）；客户端：覆盖 DungeonClear 3.6-reborn89 与 RebornWindowScale。
