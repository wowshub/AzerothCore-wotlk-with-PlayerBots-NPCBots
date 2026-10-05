# WD126A 阶段记忆

- 状态：候选包；静态 DBC 与隔离 MySQL 通过，C++ 编译、客户端和战斗实测待用户完成。不得晋升为已验证 Skill。
- 基线：WD125A 累计包，内含 WD124B `supportWanted` 编译修正；未重写历史 ZIP。
- 官方来源：`CharacterAdvancementData.json` 节点 30888、`patch-T.MPQ/DBFilesClient/Spell.dbc` 806282；节点要求 8 TE，三个效果槽原生 Dodge + Dummy + Scale，8 秒、120 秒冷却、15% 基础法力。参考的 CoA 最新源码 commit 为 `2099e7b9eb7a624347374069aed13b33df8b2924`，该源码未找到 Shrink Ally 专用脚本；因此采用官方 DBC 与本项目原生光环适配。
- 上游风险：公开 Issue #6294 指出 Splash Potion/蘑菇配料可能误触鱼油；本包保留 WD123B/WD125A 已做的私有区分。Issue #6371 记录 Potent Mixes 重复节点，本包不改其既有整合。
- WotLK 适配：新 ID 9003910；原生闪避和模型缩放，不额外叠加脚本效果；脚本只校验已学、巫医、友方与存活目标。技能书可见，方案失效或切走后撤技能。沿用本地友方 40 码和标准 GCD，待实机确认。
- 存档：节点 30888 使用第 98 位，宽度扩为 99；C++、Lua、Characters SQL 同步；8 点基础酿造 TE 不允许新点自凑。数据库升级冲突守卫、重复执行与旧版回退行为经隔离库执行。
- 验证：`tools/validate_wd126.py` 静态通过；`tools/test_mysql.py` 隔离库 463 项通过。未编译、未部署、未做真实战斗测试。
- 使用的工具：Python 3.9 读取官方 JSON／MPQ、做 DBC 定点追加和逐旧行比对；项目内隔离 MySQL 8.0 实例执行存档过程；PowerShell 仅检查文件。脚本和源数据快照在 `tools`、`research`。
- 当前用户另问“药水投手哪个是”：节点 35065，酿造被动；缩短药水投掷与泼洒各 5 秒，不能当作主动药水投掷 12646。截图具体图标需以悬停标题核对，不以颜色猜测。
- Skill 来源：`beascendskills/trace-and-port-coa-spell-resources/SKILL.md`（DBC 链和双端追加）、`beascendskills/plan-coa-class-migration/SKILL.md`（依赖批次）。本批未经实机，不更新成功 Skill/Tutor。
