# RebornWOW 自有数据库修复

项目约定：`data/customfixsql` 管理自有修复；`data/sql/updates` 此后用于上游 AzerothCore 同步。该约定是本项目的维护策略，不是 AzerothCore 对自定义目录的自动执行保证。

## 目录

```text
customfixsql/
  world/<feature>/<optional-stage>/*.sql
  characters/<feature>/<optional-stage>/*.sql
  auth/<feature>/<optional-stage>/*.sql
  catalog.json                   # 数据库、旧/新路径、哈希、状态
  MIGRATION_20261005.md           # 本次路径迁移映射
  heritage_lua_*/                 # 旧 Lua 配套材料，原位保留
```

使用 `characters` 复数，与核心数据库类型一致。功能名采用小写英文 kebab-case；新 SQL 建议 `YYYY_MM_DD_NN_description.sql`，日期相同按 NN 排序。旧文件本次保留原名、顺序及全部字节，方便追踪。

## 执行规则

- 分类目录不是一键安装清单。禁止把整个目录递归导入数据库；必须按具体版本说明选择所需脚本，并先核对前置版本、数据库、重复执行条件及备份/回退安排。
- Git commit 记录文件版本；`catalog.json` 记录归属与 SHA256，不代表生产库已经执行。部署记录应另记版本、文件 SHA256、目标库和执行结果，不能猜测当前线上状态。
- 当前保持手动执行。不修改生产 `updates_include`，不把同一 SQL 同时加入自有路径和上游更新路径。
- 将来需要自有自动迁移，可专门建立并验证自有迁移入口；重点是一次执行记录、依赖、数据库归属以及存储过程/DELIMITER兼容性。无需为了自动化而把自有文件混回上游目录。
- 已经进入 `data/sql/updates` 的历史自定义文件本次不搬动、不重命名；先审计更新器记录与部署历史，再设计独立迁移。不能宣称现有 updates 已经全部是上游文件。
- 新修复记录：目的、目标库、前置条件、顺序、重复执行条件、验证证据、回退办法及来源提交。涉及多个数据库时拆成分别执行的文件，不能把 World 与 Characters 语句直接混在一个执行文件里。
- 发布过的历史 SQL 不因排版、改名或分类重写内容；后续行为修正用新脚本和新版本记录。本次目录移动不意味着需要重跑任何 SQL。

## 当前巫医

WD128A Characters 脚本位于 `characters/witchdoctor/20261005_wd128/`；历史 World 依赖位于 `world/witchdoctor/20261005_wd128/historical-dependencies/`。新节点保存入口仍为 100 位，用户要求 WD128B 留到下次提交，本次未合入。

归档包里的 `server_SQL` 路径及原始 ZIP 不变；仓库 `data/reborn-checkpoints/WD128A/manifest.json` 的映射已更新，保留原路径供核对。
