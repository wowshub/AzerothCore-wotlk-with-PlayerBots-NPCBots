# DCAI1A 验收记录：机器人首领战术按生物编号识别（中文名数据库）

- 日期：2026-10-09；负责：Claude（mod-playerbots 共享区域，用户指定由 Claude 负责）
- 用户原话：「DCAI1A（首领战术按编号识别）算测试通过 先把这个推送和commit吧」
- 子模块：wowshub/mod-playerbots 分支 `reborn-dcai1a-20261009`，提交 `c36758dd709c4b1a3f2cae2cf5edea1340789941`（父提交 `89416294` = Codex DRBOT1A）

## 问题
本服 creature_template 名字已汉化，playerbots 副本/团本战术按英文名查找首领（find target 1165 处、EqualLowercaseName 16 处、Nex 1 处），全部失效；岩石大厅修复前 ground slam 触发 0 次。

## 修改
- 新增 `src/Util/CreatureNameAlias.{h,cpp}` 与生成的 `CreatureNameAliasData.inc`（278 个英文名 / 415 个编号；`garfrost` 手工映射 36494）。
- `TargetValue.cpp`（find target 先按 entry）、`PlayerbotAI.cpp`（EqualLowercaseName 兼容本服名字）、`NexActions.cpp`（混乱裂隙按 entry）。
- 生成脚本与报告：本目录 `gen_creature_aliases.py`、`alias_report.txt`（240 个 find target 名字全部覆盖）、`alias_db_coverage.txt`（本服 273/278 为中文名）。

## 测试范围
- 乌特加德城堡：dalronn dps 175、ingvar smash tank 49、not behind ingvar 156 次触发，0 死亡通关。
- 岩石大厅：shatter spread 成功 130、avoid lightning ring 成功 13（五人含托管巫医）；死亡 16→5、团灭 3→0，首次击杀斯约尼尔。
- 未测：其他副本与团本的具体战术效果（仅确认名字可匹配）。

## 来源
交付包 `000Ascendupdate20261008/claudefix_20261008_200354_阶段DCAI1A_机器人首领战术按编号识别.zip` SHA256 `7f1439c3a003481f850d1518c05cd9bdecce2a25a73d8a49a2c7f319730b1748`；提交前核对子模块 6 个文件与包逐字节一致。无 SQL、DBC、配置改动；需重跑 CMake（新增文件）。
