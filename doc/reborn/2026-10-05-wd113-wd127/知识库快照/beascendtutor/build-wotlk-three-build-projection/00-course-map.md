# 三套独立方案投影

先读 [tutor.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/build-wotlk-three-build-projection/tutor.md>)，再读 [01_成功失败与待测总表.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260914/codexsummary_202609142247_武僧修复复盘教学与新窗口交接/01_成功失败与待测总表.md>)。

完整代码、历史测试与解释：[04_历史阶段索引.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260914/codexsummary_202609142247_武僧修复复盘教学与新窗口交接/04_历史阶段索引.md>)。

来源与实测边界：[SKILL.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/build-wotlk-three-build-projection/SKILL.md>)。本地教学不替代用户安装与游戏验收。


## 2026-09-29 WD86A 两项用户实机通过

用户明确反馈：巫毒心智（按施放时灵魂层数调整暗影傀儡跳速和持续时间）、黑暗洛阿祝福（团队伤害提高3%，自身傀儡加速）测试通过。登记这两项基本效果通过；未提供每个层数逐跳日志、同类增伤全组合、多人归属、PvP/机器人、切方案/重登完整矩阵，不扩大结论。WD87A仍候选待测。

来源：[WD86A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/README_覆盖与测试说明.md)、[完整教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/tutor.md)。本次不改历史交付源码/DBC/SQL及SHA256清单；新增验收附件与永久知识记录。

复用方法：周期间隔在Aura初始化读取本人灵魂快照，用基础间隔×100/(100+10×层数)；持续时间×(100+10×层数)/100。祝福本人时间项再乘80%，团队增伤用原生1056组规则3取强。HasSpell加HasAura避免队友光环接收者误获本人专属傀儡收益。施放后新增层数不追改已开始周期。C++、Lua、SQL与双端独立DBC成套交付，32位最高位保存使用BIGINT重建值；WD87扩容另行验收。

永久方法：[来源移植](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)、[三方案投影](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/build-wotlk-three-build-projection/SKILL.md)。

逐步教学：[WD86A快照与团队增益](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/build-wotlk-three-build-projection/WD86A-puppet-snapshot.md)
