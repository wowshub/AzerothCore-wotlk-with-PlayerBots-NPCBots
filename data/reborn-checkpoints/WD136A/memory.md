# WD136A 调制大师候选记录 — 2026-10-07
读取项目AGENTS/rule/refResource/永久技能索引，应用plan-coa-class-migration、trace-and-port-coa-spell-resources（含method/wd3参考）、build-wotlk-three-build-projection。范围为复杂施法身份依赖的一项完整被动，未凑无关技能。
基线源码a986fc2e2005ebefc1907065933c634251c0fb7c；当前客户端/服务端按refResource路径，Spell以当前patch-ZA累计保留LIGHT8B/WD135UI，其他表独立核对。旧源/运行文件不改。
ID6026 -> 9003954/55/56；index105 bit117、118位。配料八附效+20%，蘑菇3次/15秒/5%。Spell/Aura对象快照，直接/周期结算伤害回收；高级酿造前置不自举。
201隔离SQL、31数据/Lua、6实际单元/Zs、实际辅助头文件替身测试及10000整数案例、14MPQ读回通过。未完整编译/部署/实机/commit/tag/Release，候选不晋升成功Skill。
过程问题：Python脚本加显式utf8编码；验证复用scenario134路径修正；本地AuraEffect API差异修正；隔离头文件覆盖顺序修正；默认沙箱Path.resolve拒绝，由受限端口/目录校验的独立SQL测试获准执行。保留失败日志，不声称解决其他运行问题。
