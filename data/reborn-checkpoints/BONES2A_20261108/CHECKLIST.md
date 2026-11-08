# BONES2A audit-and-port-upstream-features检查表
- 作者/审查：Codex自审，无跨成员评审冒称。
- 输入：当前YB ChrRaces/EXE实际哈希见audit.json；当前Patch-T四原生M2和对应skin/BLP，逐项来源见model_dependency_manifest.json。
- 上游：已取当前main 00ba053a91b878b0c48e8796d0ab535a2d769953，读取Corpse/Map/ObjectAccessor，Issue/PR查询见upstream.json。CoA资源1.92/官方参考库未找到四族专属骨骼；使用当前原生兼容资源而非编造专属来源。
- 契约：玩家死亡/释放/复活后现存bones对象，客户端按race ClientFileString和性别查资源。等级/天赋/伤害/费用/debuff与施法视觉均不适用，不新增机制。
- 联动：保留原服务器corpse→bones、删库/生命周期/回收及原race/sex字段；不关bones配置、不改mask、不替换角色模型，不回退Claude文件。
- 测试：8图/skin和4BLP、错误指针/索引负例通过；175当前/参考可读MPQ审查，其中64当前。Patch9/Housing锁定、部分listfile加密已记录；不能把64当所有归档。
- 生命周期实机：四族男女实际死亡→释放→复活→原地骨头，以及旧族、重复死亡、观察者/机器人待用户测试。
- 独立双端：无DBC/SQL/服务端变更，仅客户端新增路径；不涉及双端整表覆盖。当前角色/账号库不操作。
- 结论：候选待测；规则和Skill明确登记程序要求，不当成实机通过。十职业建角底座仍不发布。
