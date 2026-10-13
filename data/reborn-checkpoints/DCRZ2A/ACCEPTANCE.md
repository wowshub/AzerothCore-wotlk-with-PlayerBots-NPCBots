# DCRZ2A 测试队无人可复活/团灭时门口复活继续 验收记录

- 日期：2026-10-13；开发：Claude；验收：用户。
- 用户原话："DCRZ2A测试通过了"。
- 现场源码 8 个文件的 SHA256 与候选包输出一致（前 12 位：DcEngageActions.cpp 583610e638ce、DcRezRecovery.cpp 91aaaf9f5c5f、DcTestRunJob.cpp ea8432842571、DcTestRunJob.h 136782e0e005、DcTestRunManager.cpp 006e4eba26f3、DcTestRunManager.h 2ed363de9f66、DcTestRunRecord.cpp 8801d6221bdc、DcTestRunRecord.h 88e0b8a70c26）。

## 功能
只影响 `.dc test` 测试队，玩家自己带的队伍不变：
- 全队团灭 5 秒后，测试监控在世界线程上把全员复活到副本门口，清本继续；
- 有人死了、活着的人都不能复活，或复活超时：战斗结束后同样回门口复活继续；
- 每次测试最多 3 次，之后照旧结束；没有入口坐标的地图照旧结束；
- 测试记录 schema 14 新增 `testRegroups`、`testRegroupLog`，表示"由测试流程复活"，统计和排行需单独区分；
- 顺带修复门口复活提示里的乱码破折号。

## 未单独验证
- 连续 4 次团灭时第 4 次是否按上限结束；
- 没有入口坐标的地图的回退路径；
- 团本、魔环原有门口复活的回归（代码路径未改，只改了提示文字）。

## 候选包
`000Ascendupdate/000Ascendupdate20261013/claudefix_20261013_004409_阶段DCRZ2A_测试队门口复活继续`。
