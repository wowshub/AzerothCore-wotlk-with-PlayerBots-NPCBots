# RACEJOINT1A限定验收与可复用经验（2026-11-07）

用户“测试通过，先把昨天的新种族的添加修复进行提交和推送吧”。范围39/49男女战士的联合首测基本反馈，不外推逐项全矩阵、其它职业/特性/PvP。原ZIP0a5068bece8d688831d662e0eaf15e8a3e842c49660c68639a2bbba6f4dd4da4，不能改写历史候选记录；后续状态以新验收记录说明。

1. 核心前置先验输入/输出，再拼出生模块。Player::Create先LearnDefaultSkills/LearnCustomSpells再发服装；OnPlayerCreate太晚，只能补缺，不能自动补穿已经进包物品。基础技能必须在物品前授予，使用模板已有项+明确白名单+HasSkill保护。
2. 语言技能号与语言法术号分别校验，并追首条资格/SkillLineAbility链接；39=98/668、49=109/669。登录恢复先查全部缺项资格再授予，不发装备、不重置熟练度/声望。getRace(true)按真身份。
3. 本项目39/49采用批准的>=38别名规则，36/37保持mask0；MAX_RACES50不替代运行容量/客户端核对。同位必须同阵营；出生三入口、SkillRaceClassInfo和SkillLineAbility隔离母族单一位。不得说任务/物品等全部已隔离。
4. 共享DBC分别从双端最新母版记录增量；根/zhCN各自输入。CharStartOutfit归XA，不能在YB再放旧表遮盖它；创建页状态走实际Open桥。
5. 原ZIP与解压目录需双重核对。本次发现解压SQL确认默认值被改成1，原ZIP仍0；按原ZIP补提交恢复。完整93条只这项不同，不能用README保证代替实际读SQL。默认守卫不得自动SET1，不运行生产SQL。
6. 全编译/替身/数据/用户基本通过分别登记。原候选实际worldserver完整链接；发布分离4个无关职业hunk，14种族关键函数相同，5CPP语法通过，但正式整树完整链接未重跑。已测用户不用因发布重新覆盖。

18项日常源/服务端表和6项MPQ匹配，远端发布与资源哈希见000Ascendupdate/000Ascendupdate20261107/release_RACEJOINT1A_20261107/publication.json。
详细教学：../../../000Ascendupdate/000Ascendupdate20261107/总结教学_20261107_新种族联合移植与天赋修复/00_从这里开始.md。
