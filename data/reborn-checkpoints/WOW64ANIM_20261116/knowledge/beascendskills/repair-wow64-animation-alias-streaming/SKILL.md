---
name: repair-wow64-animation-alias-streaming
description: Diagnose WoW64 M2 animation loading hangs, unsafe keyframe searches and model rejection regressions using a matching executable, alias ownership and bounded runtime rings.
---

# M2动画加载止卡死与兼容

遇到选角卡死先固定无响应进程/线程、EXE和对应.text/符号；加载循环与渲染白模分开诊断。M2磁盘aliasNext不是现成的运行时owner闭环，按真实flag识别owner后构造有界环，保持轨道/flags；异常链的兼容策略不能直接升级为整模型拒载。
修改公共加载逻辑时枚举当前所有种族/性别的实际胜出模型，去重并保留条目映射。旧小样本通过不代表新族/HD旧族兼容。测试合法链、坏环、越界、无owner、重复初始化和生命周期；FindKey额外覆盖最小下界防无符号下溢。
按[现场复盘](references/accepted-20261116.md)核对JOY和15项消失回归，区分用户基本验收与全部动作矩阵。现场dump不随功能资源上传。此Skill不用于改伤害、职业动作仲裁或用隐藏种族掩盖故障。
