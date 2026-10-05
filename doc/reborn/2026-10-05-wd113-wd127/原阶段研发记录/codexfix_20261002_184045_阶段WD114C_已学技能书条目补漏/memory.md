

## 2026-10-02 WD114C 已学技能书条目补漏（候选）
用户已确认三个IsSpellKnown为true。实读当前Patch-XA，五条Spell/分类存在；enUS自定义FrameXML由最高等级槽生成列表，无独立已学补漏。增量Lua按ID只补五条已学且列表遗漏的技能，保留真实槽、无槽时使用现有按ID条目；巫毒分类、分页同步、去重、脱战刷新；/wdbook输出定位信息。根因具体层级仍需实机诊断，不宣称原生算法已修复。Lua回归通过，未部署。洛阿强化/WD114B用户基本通过不受改动；显性费用实测、假死/强效、同名节点叠加仍待验收。
[安装](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_20261002_184045_阶段WD114C_已学技能书条目补漏/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_20261002_184045_阶段WD114C_已学技能书条目补漏/tutor.md)
