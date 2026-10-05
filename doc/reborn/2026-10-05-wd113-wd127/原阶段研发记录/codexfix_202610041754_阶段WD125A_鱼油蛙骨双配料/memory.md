# WD125A 阶段记录

2026-10-04。基线：WD124A 原封不动作为累计包输入；WD123B 由用户确认，WD124A 的药水投手、药师、再生者仍待实机。实际阅读项目 `AGENTS.md`、`ruleAscend.md`、`refResourceAscend.md`、`beascendskills/skillsAscend.md`、`plan-coa-class-migration/SKILL.md` 及既有 `trace-and-port-coa-spell-resources` 工作法。最新在线社区源码固定到 `jealous-sound/azerothcore-wotlk-coa` commit `09e723bf23e7ef50f8c4f1a3e63ee7e1e54cabae`，查看 `AscensionWitchDoctorBrewing.cpp` 与 `Completion.h`；对应 Issues／PR 检索未发现可直接复用的鱼油／蛙骨新修复。飞升官方 20260925 客户端 `CharacterAdvancementData.json` 与 `patch-T.MPQ/Spell.dbc` 是本次技能效果和数值来源。Node 6600 的旧标签 “Frog Venom” 对应法术 801662 Fish Oil；Node 29738 的旧标签 “Fishbones” 对应法术 801663 Frog Bones。以法术实际描述、效果字段和本项目逻辑命名。用户同时反馈 WD124A 编译出现同一作用域 `wanted` 重定义；本批把前组改为 `supportWanted`，保留后组八项数组，并单独交付 WD124B 编译修正包。

新私有编号 9003901–9003908，只授予 9003901、9003905 两个准备法术；范围增益和药水附效为隐藏子法术。鱼油为 16 级巫医普通技能，无 AE／TE；蛙骨使用 AE 索引 85、mask bit97、酿造 8 基础 TE 后 1 TE，并要求已有大锅／通用基础路径。其余 0–84 索引和旧 DBC 行保持原值。现阶段只允许一个已准备配料；重复切换移除前一个，投掷／泼洒在施放时记录快照。为避免上游 Splash 803273/803698 映射混乱，直接按官方 DBC 的鱼油 803273、蛙骨 803699 建立私有子法术。

服务端端点：`RebornWitchDoctorBrewingFoundation.inc` 做配料互斥、施放快照及命中附效；`RebornWitchDoctorAllocation.inc` 做方案拥有权与生命周期；`RebornWitchDoctorTalents.cpp`／`TalentNodes.h` 做节点索引和前置；`WitchDoctorTalentPolicy.h` 限制私有法术的外部授予。客户端 `Allocation.lua`／`WD8.lua`／`Progress.lua` 扩 98 位与展示。独立的服务端／客户端 Spell、SkillLineAbility DBC 各新增八个私有法术记录与两个书页记录。Characters SQL 扩白名单、bit97、预算／专精／前置及不可免费退款；World SQL 绑定两个准备技能脚本。

验证：456 项隔离 MySQL 检查通过，包含旧场景、新节点保存、重读、缺前置、错专精、越界与回滚守卫；双端 DBC 旧行完全不变，8 新法术效果／目标／字符串偏移校验通过；核对目标核心 Aura 31、58、69、87、192、216 与团队范围法术效果 65。没有编译、部署、修改正式数据库或实机运行。鱼油／蛙骨及 WD124A 被动属于候选待测，不能写入已验证 Skill。鱼油达到 16 级后的自动学习和下线／升级边界需用户实机验证。

回退：`rollback_WD124A` 是本批覆盖文件的快照；已保存蛙骨的新库不得直接执行旧 Characters 过程。须恢复升级前完整数据库备份，防止未知节点记录被误删。旧 WD124A ZIP 保持原样。


