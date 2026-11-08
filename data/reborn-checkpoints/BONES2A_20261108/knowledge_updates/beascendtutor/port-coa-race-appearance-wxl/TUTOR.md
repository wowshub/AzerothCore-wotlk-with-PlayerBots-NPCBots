## 复活后遗骨占位方块（2026-11-08）
活体/装备正常不等于bones资源完整。死亡遗骨按ClientFileString与性别构造DeathSkeleton路径，不能改活体模型或ClientPrefix来绕过。参见[新种族回归与遗骨专节](../port-wotlk-custom-race-creation-flow/references/new-race-regression-checklist-20261108.md)。BONES2A补36/37/39/49共8套兼容遗骨及依赖，实机待测，已过Claude装备层/射击动作和Codex头盔/背盾不改。


## 2026-11-08 BONES2A用户基本验收
用户原话“测试通过 可以推送了”。四新族兼容遗骨修复按基本使用通过记录，当前YJ20/20匹配冻结原ZIP；全部男女/四族/观察者/真人与机器人/重复死亡矩阵未逐项确认，不扩写。无活体模型、DBC、服务端、SQL、DLL改动，十职业建角底座不发布。Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-bones2a-20261108；原ZIP SHA256 b3f14f8d75838ab047f4d58eb6124b5539437d26228edd98225301640410ed4c。原包待测文字保留为历史，此新记录更新状态；已装通过无需重装。
