# DCMOV3A 闪电大厅掉落 验收记录

- 日期：2026-10-16；开发：Claude；验收：用户。用户原话："测试通过 啦 继续修复下一个"。
- 部署的 worldserver.exe 生成于 10-16 07:31:03。`DungeonClearMultiplier.obj` 和 `MovementActions.obj` 在 07:30:43–44 重新编译，比源码（07:22:39）新；两个源码文件与候选包逐字节一致。

## 内容
- **清本运行中（含暂停）不跟主人穿传送门**：两个 DC 动作倍率把 playerbots 的 `reach area trigger` / `area trigger` 设为 0。原因：测试 tr-20261016-070707-2 中，GM 退出观战再进入，5 个机器人直线穿过大厅中间的坑，最后走出副本（"Left the dungeon"）。
- **playerbots `Move()` 在副本里不换层**：目标高度与当前高度相差超过 4 码时保持当前高度。原因：洛肯房间的服务器地面高度数据缺了地板，`LokenStackAction` 走进了虚空。
- mod-playerbots 从 c0b3010c 更新到 b0369e51（wowshub/mod-playerbots 分支 reborn-dcai1a-20261009）。

## 未单独验证
- 第一个首领比亚格里拖着坦克走的问题（另做）。
- 10-14 玩家队在洛肯走廊的非战斗掉落原因。

## 候选包
`000Ascendupdate/000Ascendupdate20261016/claudefix_20261016_072239_阶段DCMOV3A_闪电大厅掉落`。
