# WD119B 候选记录
读取项目AGENTS、ruleAscend、refResourceAscend、skillsAscend及stabilize-spelldraft-client-ui/SKILL.md与evidence-lineage.md。本阶段仅现有客户端显示/插件写入清理，没有新增CoA机制或修改C++/DBC/SQL，未宣称上游机制重新审计。
实际输入：当前客户端SkillBook/Cooldown；WD119A累计NumericTooltip；WD118B研究中的patch-enUS-5 SpellBookFrame.lua及当前loose SpellBookFrame.xml只读用于调用链对照，没有发布修改的FrameXML。
可证实路径：WD114D调用UpdateSpellRender/SkillLineTab_OnClick/UpdateButton并写searchSpellID及SPELLBOOK_PAGENUMBERS；WD114C插入spellbookCustomRender并调用UpdateButton；原生UpdateButton向spell/index属性写数据，OnClick读取属性后CastSpellByID。删除不必要的跨安全边界写入。历史用户诊断已显示目标技能在原生列表中，并非需要补入的缺失技能。
不能证实：DBM-Core是最初污染源；没有现场taint栈，删除上述路径是候选修正，不能把离线Lua通过当作受保护调用验证。
数字已核对现有WD117代码：duration10000/11000/12000ms；整数25/27/30，治疗200/220/240百分之一；原黄色正文包含“基础（未计灵魂行者）”，据此精确替换。协议/缓存/序号/方案校验原样保留。未改冷却公式。
