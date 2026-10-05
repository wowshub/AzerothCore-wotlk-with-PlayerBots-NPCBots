

## 2026-09-29 WD89A 反例更正：空掩码不是排除（代码已证实，修正包待实机）

本地SpellInfo::IsAffected在familyName=0时直接true；非0同家族的空mask也不排除。GlobalScript::OnIsAffectedBySpellModCheck返回false是强制匹配，返回true只是继续原生判断。此前“空DBC mask能保护无关技能”的解释不成立，不再作为可复用保证。

实际当心巫毒9003752/53和扎拉赞恩9003611均family0/空mask，可误延长暗影傀儡。用户反馈单次施放超过5秒仍发射，数据基础3秒/冷却18秒未互换。WD89A提供私有精确来源回退拒绝和实际时间诊断；候选未编译、未实机。既有用户基本验收保留，不能扩大为全负向范围验收。

[源码证据与适配](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/research/来源与适配.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/tutor.md)。后续测试必须同时包含合法目标有加成、无关目标无加成、其他职业原生效果不变。别只测“看到增加了”就认定边界正确。
