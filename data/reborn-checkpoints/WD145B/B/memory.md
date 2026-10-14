# WD145B 候选记录

用户截图指出灵魂信徒/村落智慧在综合，命中等级没变。确认WD145A只给主动灵魂蚀追加分类，漏7个暗影被动rank；补双端SkillLineAbility，不改Spell.dbc。命中等级和命中百分比不同；现场Aura54/55各5、原生StatSystem累加路径有效。新增自有只读服务器协议与插件后置钩子，显示来自实际服务器光环，不根据草稿或IsSpellKnown伪造加成。

实际采用项目coordinate-ai-team-parallel-development与integrate-wotlk-custom-class-ui-eligibility技能，并读新增职业检查表；只回归本次技能分类、人物提示、状态同步，组队/专业/新种族不在本次范围，不标通过。参考现有RebornMonkPanel的PaperDollFrame_SetRating后置钩子，但用服务器回包而非已知法术推断。AllStats源文件不修改。

新增.wd145hit sequence仅读取自身AuraEffect1/2及总命中光环，400ms限流与旧数字查询共用；插件仅可见命中栏期间每1.5秒请求，3秒过期，切方案和UNIT_AURA清缓存。保留等级原数与原生提示。由用户编译部署，候选未游戏验收。
