## 新种族移植基础回归（用户2026-11-08要求，禁止重复漏项）

新增种族、扩职业、更换身体模型或ClientFileString/ClientPrefix前，必须读并填写[新种族基础回归清单](beascendskills/port-wotlk-custom-race-creation-flow/references/new-race-regression-checklist-20261108.md)，同步原种族移植Skill/Tutor；不只记在聊天或每日记忆。

- 每个本批开放族/性别/职业按需记录：建角出生技能/语言/声望；猎人弓枪弩和自动射击、匹配弹药及**原生弹药槽显示**；萨满四元素模型/贴图/动画/名字高度；变身取消后皮肤装备恢复；头盔/背盾在坐姿与NPC对话；属性/幻化预览；首次三模式→介绍→开始冒险不小退；**死亡→释放灵魂→复活后原地遗骨**。
- 遗骨按当前ChrRaces **ClientFileString**实际前缀与男女拼DeathSkeleton路径，连M2/SKIN/BLP/ANIM一起核对。不拿ClientPrefix或活体模型代替；不靠关遗骨/删尸体/重启清理绕过，不改已过活体前缀。兼容遗骨须说明外观取舍，不冒称专属解剖模型。
- 每行保留当前输入/输出指纹、来源、离线检查与用户实测状态、未覆盖项。旧族/单职业/单性别通过不能继承为新族全通过；缺资料或候选待测明确记录，用户选定的阶段范围仍优先，不擅自全开种族职业或部署。


## 2026-11-08 BONES2A用户基本验收
用户原话“测试通过 可以推送了”。四新族兼容遗骨修复按基本使用通过记录，当前YJ20/20匹配冻结原ZIP；全部男女/四族/观察者/真人与机器人/重复死亡矩阵未逐项确认，不扩写。无活体模型、DBC、服务端、SQL、DLL改动，十职业建角底座不发布。Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-bones2a-20261108；原ZIP SHA256 b3f14f8d75838ab047f4d58eb6124b5539437d26228edd98225301640410ed4c。原包待测文字保留为历史，此新记录更新状态；已装通过无需重装。
