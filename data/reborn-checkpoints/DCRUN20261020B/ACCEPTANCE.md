# DCRUN20261020B — 副本测试队伍：诊断补全、Bjarngrim 流程、面板大小、GM 命令与复活（Claude）

- 日期：2026-10-20。
- 用户原话："这次 不错 应该可以通副本了 死了好多次但最终还是可以通副本了……前面所有的都测试通过 一个一个推送并release"。
- 范围：待测清单 K68–K80：DCBOSS1C2、DCBOSS1D、DCP1C、UP1B、DCP1C2、DCHOL2C、DCUI4B1、DCUI4B2、DCGM1C5、DCUI4B3、DCHOL2D、DCGM3A、DCGM1C6。
- **不在范围**：DCHOL3A（K81）、DCUI4B4（K82）刚做完，用户未测，保持候选。
- 性质：用户基本通过（整体可通副本）。不外推：Bjarngrim 首次尝试的全灭（小怪与首领同时参战、坦克先死）并未解决；DCHOL2C 的"拖拽失败后直接开打"逻辑保留但已无行使用；多个测试同时进行、NPCBot 队伍、"我的角色"名单模式没有测。
- 父提交：wowshub/threemodelcardpro 的 98b1bf6ef（Codex 的 WD167A）。

## 主仓库（每个包一个提交）

| 功能 | 提交 | 内容 |
|---|---|---|
| DCBOSS1C2 | 74c82c4cf | 施法检查改用无冷却的治疗法术 |
| DCBOSS1D | 5386bdd18 | 治疗者控制状态与有害光环；TIY 消息 |
| DCP1C | 8615e0407 | 测试队伍天赋指纹/雕文/装备进记录（schema 22） |
| UP1B | 978e4272d | 自定义联盟种族不再被机器人当成部落（playerbots 子模块 f327c8b4） |
| DCP1C2 | 895670a69 | 天赋点数按等级计 |
| DCHOL2C | 59ad0c6f7 | 拖拽失败后直接开打（默认关，仅 Bjarngrim） |
| DCGM1C5 | 21b2ef74c | 掉队传送距离跟着坦克的等待门槛 |
| DCHOL2D | 78cc2b698 | Bjarngrim 改回普通首领，不再"引怪回营地" |
| DCGM3A | 1607ff498 | 死亡时面板 GM 命令走插件通道（gmcmd） |
| DCGM1C6 | b22421c00 | 进队玩家单独死亡 20 秒后在坦克旁复活（记为作弊项） |

DCUI4B1/B2/B3 是纯客户端，在插件仓库。

## playerbots 子模块

- wowshub/mod-playerbots 分支 reborn-dcai1a-20261009：f327c8b4（UP1B），父 a09f38ed。
- 提交的是 UP1B 自己的 3 处修改（ChatHelper、PlayerbotFactory、PlayerbotAI）；工作树里 Codex 未提交的 DRBOT1A 改动没有带入。

## 客户端

- DungeonClear 插件仓库 wowshub/mod-dungeon-clear-addon：v3.6-reborn94（7be8b1a）、95（5f46d2d）、96（adef397）、97（d626a87）、98（210bd95）。

## 核对

- 重放链条：每个包覆盖前，工作树里的对应文件与该包"原文件备份"一致（LF 统一后比较），主仓库、插件仓库各 0 问题。
- 编译检查：各服务端包 `cl /Zs`（MSVC 14.44）0 错误并做反向验证（见各包 README）；客户端用 lupa 烟测。
- 未由我编译完整程序；用户自行编译部署。

## 实测证据

- 最近一局用户反馈"死了好多次但最终还是可以通副本"；日志里 DCGM1C5/1C3 掉队传送、DCRZ2A 全灭重整、DCBOSS1A 死亡记录均正常工作。
- 同一次测试发现的新问题（熔渣炉终点徘徊）已做成候选 DCHOL3A，未发布。
