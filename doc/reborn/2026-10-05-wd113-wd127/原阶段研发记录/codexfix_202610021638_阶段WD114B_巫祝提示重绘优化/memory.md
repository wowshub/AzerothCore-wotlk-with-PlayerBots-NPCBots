## 2026-10-02 WD114B 巫祝提示重绘优化（候选待测试）

用户澄清实际耗蓝很可能已减半，要求基于WD114A优化显示。保留WD114A原ZIP，仅交付NumericTooltip.lua增量：费用重绘、原生行重建识别、Show重入保护、异步回包当前技能核对；不修改实际费用或角色存档。旧提示回归与新增Lua回调测试通过，旧A触发新增布局断言预期失败。未编译未部署未实机；实际扣蓝仍未确认。下一批机制开发仍以WD114A累计源码与本B客户端为候选基线，不能登记WD114已验收。

[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610021638_阶段WD114B_巫祝提示重绘优化/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610021638_阶段WD114B_巫祝提示重绘优化/tutor.md)
