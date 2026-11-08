## 2026-11-08：不要只验“能建号、能进世界”
已测试的角色倒地外形，与复活后原地留下的骨头是两套模型。模型正确不代表骨头文件存在。读当前种族表的ClientFileString（不是Hu/KT这类ClientPrefix），加Male/Female和DeathSkeleton查文件；再查skin、贴图、外置动画。只补遗骨资源就不需要动已经过的活体衣服/头盔/盾牌。
下次按[新族完整基础清单](../../beascendskills/port-wotlk-custom-race-creation-flow/references/new-race-regression-checklist-20261108.md)依次检查：出生能穿装；猎人会弓枪弩、能射且能看到弹药槽；萨满四元素能召回；变身能恢复原脸；坐下对话装备不放大；预览不抖；首登不小退；死后复活回原地看骨头。每项分男女/职业登记，没测写待测。
BONES2A这次交付兼容人类/兽人遗骨，不是新绘制蛇形/双头骨骼。8模型/8skin/4BLP离线通过，用户实际死亡复活仍待测；待用户通过再更新成功状态，不把“写进Skill”当游戏验收。


## 2026-11-08 BONES2A用户基本验收
用户原话“测试通过 可以推送了”。四新族兼容遗骨修复按基本使用通过记录，当前YJ20/20匹配冻结原ZIP；全部男女/四族/观察者/真人与机器人/重复死亡矩阵未逐项确认，不扩写。无活体模型、DBC、服务端、SQL、DLL改动，十职业建角底座不发布。Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-bones2a-20261108；原ZIP SHA256 b3f14f8d75838ab047f4d58eb6124b5539437d26228edd98225301640410ed4c。原包待测文字保留为历史，此新记录更新状态；已装通过无需重装。
