---
name: release-tested-reborn-features
description: Close out a user-tested RebornWOW skill or feature with scoped acceptance, matching source/SQL/client commits, verified remote push, and tag/Release handoff linked to resource hashes. Use after test confirmation or an explicit commit/release request.
---

# 小功能验收与版本发布

项目永久流程，来源于WD128–WD131的分批验收与源码/资源关联实践。先读项目AGENTS、ruleAscend、refResource和本阶段交接。不用于替代尚未完成的开发测试，不因新技能库存在就自动运行发布。

## 按实际状态收尾

1. 每个技能/功能分别记节点或ID、用户原话、日期、具体测试范围；区分候选、离线检查通过、用户基本通过、专项通过、已提交、已推送、已打tag、已发布Release。总体通过不外推PvP/机器人/全数值。未测试项保持待测。
2. 核对当前分支、HEAD、实际远端、工作树/暂存区，读取原包manifest和ZIP SHA256。逐文件比较用户覆盖源码和候选源码；差异先解释或隔离，不把未测试的新改动冒充验收版本。保留原包、旧失败证据和无关修改，禁止reset/clean及git add .。
3. 源码按原工程路径追踪；客户端可编辑Lua/TOC放data/reborn-client；自有SQL按data/customfixsql/{world,characters,auth}/功能/阶段分类，data/sql/updates留给上游。SQL手动按需执行，本流程不运行生产SQL。DBC/BLP/MPQ等二进制通过资源ZIP作Release附件，Git保存清单、哈希、来源、覆盖顺序和验收记录到data/reborn-checkpoints/阶段。双端DBC不可互换。GitHub自动Source code压缩包不等于可部署资源包。
4. 用户确认后依次更新每日记忆、相关既有Skill、同名Tutor、两个总目录，再验证路径与来源哈希；复用原技术Skill，不为每个技能重复创建同类Skill。包内历史候选记录不改写，以新验收记录说明后续状态。
5. 对必要文件显式白名单git add，检查暂存路径、diff --cached --check和实际差异后commit。相互关联的小技能可一个可审阅提交；A/B修复链保留，不强行把同一功能拆成每技能一个提交。没有代码变化的重复验收不制造空提交。默认交付授权不包含自动提交推送，依当前用户授权操作；已授权则直接完成，不重复询问。
6. 本项目目标wowshub，通常threemodelcardpro，操作前核对，不能误推origin/lisancth。推送正常分支，读回ls-remote验证SHA；遇远端前进先查分歧，不强推或覆盖别人的修改。保留无关工作树内容。提交号必须来自git rev-parse/log，不能编造。
7. 本用户当前分工：助手按明确请求commit/push；用户自行创建/推送tag并发布Release，助手交付精确两条命令和可复制Markdown正文。没有后续明确代发授权时，不自动打tag/Release；这不是要求每次重复征求确认。若用户以后明确授权代发，则核验并完成相应动作。
8. tag指向最终已验收提交（A→B时指向B即包含祖先A）；用完整SHA生成附注标签命令。建议reborn-阶段-YYYYMMDD命名并核对是否已存在；已有同名tag核验目标，绝不静默移动/强推。Release正文用完整commit/compare Markdown链接、验收范围、资源包清单/SHA256/覆盖顺序；上传包含最终修正的累计包，或明确A后B附件组合。只有实际读回Release及附件才可记“已发布”。

## 核验与常见反例

- 足够验证：包哈希/现场来源、暂存白名单与差异、必要受影响测试、远端分支SHA；纯归档不重跑全编译或生产数据库。
- 仅点准备技能不等于附效触发：WD131需5秒内投掷/泼洒命中，附效在受益目标；先排使用顺序，再决定改代码。
- tag只是提交别名，不能把未测试工作树打包后仍称与tag一致。版本表记每个功能的验收范围与最终提交；不能把提交成功等同Release发布。
- 40位提交SHA-1与64位ZIP SHA256用途不同；短提交号只是前缀。Release正文不要整体套代码块，否则链接不渲染。

权威证据与教学：[同名Tutor](../../beascendtutor/release-tested-reborn-features/TUTOR.md)。WD131原资源来源与18源码/91文件哈希见[data/reborn-checkpoints/WD131A](../../beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD131A/ACCEPTANCE.md)。此Skill不要求创建新任务或分派代理。
