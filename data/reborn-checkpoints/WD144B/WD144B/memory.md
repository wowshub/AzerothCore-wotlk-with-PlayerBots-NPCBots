# WD144B 状态记录
用户2026-10-13反馈：强化恶毒箭2/2保存但提示/图标/实际等待8秒；巨蛇意志面板未+10；洛阿属性有变化；腐朽0/1不知测试方法。
状态：WD144A尚未整体通过；B候选。已读取AGENTS、rule/ref、skills索引、coordinate-ai-team-parallel-development及完整v2规范/实时登记、trace-and-port-coa-spell-resources、synchronize-wotlk-spell-costs-and-cooldowns。
上游本轮gh API HEAD=4f66bddb12a32eeba49d42621651f19c46c4f570，与A冻结参考一致；开放/关闭Malefic及Serpent检索已复核；Issue200/670/691/1710与PR4753（merged，e17d84e40c219569f54f90945b99be6736255a57）。社区代码非官方源码；官方技能说明沿用A的原客户端donor.json，不改变数值设计。本次为本地私有ID同步适配遗漏。
明确发现：Spell.cpp post-GO白名单无9003990/91，NumericTooltip无恶毒箭；未得到真实运行服务器remaining证据，不能把客户端阻止再施法与服务器实际8秒等同。保留原生计算并增加只读检查，不全局改DBC、不双减。
本轮未改双端数据/SQL/共享存档；三文件哈希绑定；不修改旧A包或日常源码。不代Claude验收，不做跨线程消息。
