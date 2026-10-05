# WD127F 证据与责任记录

用户WD127E实测：实际泼洒接近10秒，但标题15、动作条15、剩余12，说明9.999；药水投掷仍15。前批未完整追踪包时序、左右FontString和回包格式，独立表达式编译不能证明整体修复。此次承认前批验收范围过窄。

读取AGENTS、ruleAscend、refResourceAscend、skillsAscend与trace-and-port-coa-spell-resources Skill；应用其双端独立数据、ID闭包、候选与实测分开原则。另读取backport-wotlk-addon-api-compatibly，但本次没有缺失API，未使用兼容层方案，也没有覆盖原生冷却API。

来源是本项目Spell::cast既存WD63E/WD121B的SendSpellGo后修正代码、Player::AddSpellAndCategoryCooldowns、NumericTooltip、数字命令和DBCStructure/SpellEffectInfo::CalcValue。此次仅修私有药水被动及其两个七级系列，没有改变官方机制或新增节点。在线尝试上游master提交页面和Potion Slinger Issues：提交页面返回No commits history、Issues抓取失败，未能固定本次最新commit，没有声称获取了上游新实现。旧累计来源不能称本次最新代码。

DBC原验证误把第86列EffectImplicitTargetA当EffectDieSides，因此错误期待-5001自动加1；核心第74列为0。修正候选只变私有被动BasePoints为-5000。之前WD124四被动的其他数值不在本次验收范围，不能借本次结果宣称通过。

候选检查结论见README和checks；完整编译／部署／实机待用户，未晋升永久成功Skill。包保留前批数据、节点、图标和面板修复。此次没有继续新增技能，先闭合这次两个药水的同步缺口。
