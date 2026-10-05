# WD121A 研发记录

用户要求继续下一批。保持WD120候选基线及全部累计修复，没有将本轮继续开发视为WD120验收。使用项目永久plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection；另读stabilize-spelldraft-client-ui用于保留技能书与图标负向回归。未创建子代理、未编译或部署。

范围为两个关联被动、三个技能等级。先核对官方节点和DBC，再固定新上游HEAD。新鲜配料来源审计发现“关闭但未解决”的例外，PotionBoss存在ALL_EFFECTS对本项目手动系数只覆盖基础值的问题。按官方说明约束目标，选用原生治疗末端百分比、精确ID路由；没有改全局治疗公式。原生SpellInfo未匹配私有modifier时直接false，防family0空mask通配所有技能。

保存index77使用bits87–88，index78使用bit89；上限90位。旧0–86位不动。AEIds79、C++Rank/Load/Valid/Apply/Save、LuaShift/Rank/Change/budget/Available、SQLschema/decode/rebuild/no-free-downgrade/TE预算同时变更。新增两节点只计TE，不计AE或基础8TE。补旧Lua层级前置用BrewingFoundation直接取五个基础节点，防新同层节点抬高旧门槛计数。

AEApply先移除不应存在的等级和Aura，然后学习唯一最高等级、恢复缺失被动Aura。SkillLine9005酿造，3个私有Spell可见；纯被动无新视觉依赖。原有Player.cpp、BrewingNumbers.h及全部旧Spell行保留。World只读私有ID碰撞为空，不执行生产SQL。本批无需新World绑定；累计仍须WD120依赖。

测试：累计Lua、三端预算与90位边界、414临时MySQL、720数值模型、完整DBC字符串/旧行、图标双路径均通过。首次SQL旧等级断言失败，原始返回未被捕获；补全SQL轨迹后413通过，再加20重复拒绝及存档不变后414通过，原因未定位，保留风险，未宣称修复。新一轮测试有独立@@datadir验证，finally关闭私有MySQL。没有运行生产服务器。

仍待用户：C++编译、实际正负向治疗数值、多人目标、重登/换方案被动、图标拖动。已有持续治疗采用施加时快照，新被动在重新投掷时更新。未实现更多配料/泼洒/双配料；未晋升成功Skill。
