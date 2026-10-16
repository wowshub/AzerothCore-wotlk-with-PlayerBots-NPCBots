# WD156A 教程（候选经验，未实机）

金布尔之眼把“暴击等级”“暴击几率百分点”和“对某个目标生效”分开。DBC的1%乘原生层数，GetTotalAuraModifier不再二次乘层数；nativeAura308的GetCasterGUID必须等于伤害来源。Family0使271作用于全技能，不能错误地沿用Family19却不给任何classmask。原核心只在有spellProto的攻击里结算271，因此补空spellProto白字，限定9004133及本人GUID，不重复法术路径。

驭蛇者要同时改两项：多2条蛇和多5秒冷却。服务器精确Hook与客户端私有family位配套；只改4→6会漏冷却，只改Tooltip则两项都不真实。保留一次施法只召一轮made标志、新召唤成功后才清旧群蛇，六个角度均分2π；不扩普通/妖火数量。每只成功守卫沿旧真神/巫毒火链。

狂乱灵魂在命中时读取Count，创建Buff，固定10N/5N/2N与4N秒，再消耗全部并调用既有Sync。每秒增加新灵魂不反算旧Buff。没有在CalcAmount读取GetTarget；没有用恢复后的层数动态提高暴击与治疗。由真实damage×percentage产生隐藏Heal，bonus coefficient清零，加入统一Derived集合防止恢复→灵魂/魔精递归。

当前只是候选。片段测试用对象替身，不能替代真实Aura apply/remove、随机触发、客户端倒计时、多人/PvP与生命周期。成功方法须待用户明确确认后同步项目永久Skill和同名Tutor。
