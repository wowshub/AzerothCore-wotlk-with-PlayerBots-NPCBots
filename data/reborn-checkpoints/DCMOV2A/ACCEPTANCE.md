# DCMOV2A 验收记录：清本移动不再被换到地图下面

- 日期：2026-10-11；开发：Claude；验收：用户。
- 用户原话："DCMOV2A 测试通过"。
- 状态：用户实测通过 → 已提交、推送、打 tag、发布 Release（见本次发布）。

## 问题
古达克（地图 604）中，清本跟随坦克给出的目标点 x/y 正常，高度却变成 0：
`PBMOVE1A: 搞撒 skipped a straight move from action 'dungeon clear follow tank' map 604 (1768.8,657.3,126.7) -> (1763.9,648.4,0.0) dz 126.7 pathType 17`

## 原因
1. playerbots `MoveTo` → `SearchForBestPath` 用 `GetMapHeight(x, y, z)` 重取目的地高度；这个位置的 vmap 没找到地板，退回到副本下方地形的 0.0。
2. 核心 `PathGenerator::BuildPolyPath` 在终点找不到导航网格时，对玩家（含机器人）返回 `NORMAL | NOT_USING_PATH`（= 17），即一条直线。
3. `SearchForBestPath` 只检查 NORMAL 位，接受了这条直线，并把 z 换成 0。

## 改动
`modules/mod-dungeon-clear/src/Ai/Dungeon/DungeonClear/Action/DcActionShared.cpp`，`DcMovementAction::DcMoveTo`（清本所有移动的入口）：
- 预判 playerbots 会用的高度。和要求的高度相差超过 5 码时：
  - 在要求的高度上有 `PATHFIND_NORMAL` 路径：按要求的高度精确移动；
  - 没有：拒绝这次移动，调用方退回其他方式。
- 日志 `DCMOV2A:`，每个机器人 5 秒最多 1 行。
- 不改核心、不改 mod-playerbots。PBMOVE1A 的拦截保留，作为第二道保险。

## 哈希
- 输入 `94c207c30fd56c2f8d1f719ac4f755704734e15e374124e1498833d2ad462ab3`，等于发布基线 `e32028ee` 中的文件。
- 输出 `143532356c8402eb5ff7f1f83a792de528d7e41c09876261dcb72a2fa0312958`，等于候选包和用户实测程序所用源码。
- 候选包：`000Ascendupdate/000Ascendupdate20261011/claudefix_20261011_180900_阶段DCMOV2A_跟随坦克不再走到地图底`。

## 实测证据（2026-10-11 19:20～19:50，古达克整本）
- `DCMOV2A:` 触发 2 次，都是搞撒在斯拉德兰附近"原地待命站位"，playerbots 原本会改到高度 0.0（pathType 17）。两次都被拒绝，随后换了新站位继续，没有卡住。
- PBMOVE1A 本次 0 次拦截；`dc_falls.jsonl` 中没有落到 z=0 的记录。唯一一次坠落是 19:26 入口处的正常高低差（落到 120.9 的地面，全员存活）。
- 首领：斯拉德兰 118 秒、达卡莱巨像 61 秒、莫拉比 41 秒、迦尔达拉已击杀（本次战斗记录未写入，另查）；全程 0 死亡，副本判定清完。

## 验收范围和边界
- 已验证：古达克一次完整清本，跟随和原地待命的移动。
- 未专项验证：其他副本、多层地形（例如蒸汽地窟）。修复只在高度相差超过 5 码时才介入，其余情况行为不变。
