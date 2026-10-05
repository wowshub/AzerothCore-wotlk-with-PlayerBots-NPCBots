# 大白话教学：购物车、订单与鼠标悬停

## 1. 为什么加了点却写0/1？

像购物车里放了1件商品，已付款订单还是0件。两个数字都能是真的，但用户最想先看“我当前选了几件”。旧Tooltip只强调已保存，就让你误以为点击没有起作用。

现在把draft（当前选择）放到第一行，把saved（服务器已保存）放到第二行。草稿1/1、已保存0/1时明确标注未保存，不用误导的已生效描述。真正保存回包后才显示已保存1/1。

## 2. 为什么鼠标不动就不更新？

OnEnter像“鼠标进门按门铃”。原来说明只在进门时画一次。点击修改了数据，图标重新画了，说明却还停在进门那一刻。

修复不是每帧不停刷新。我们保存当前悬停按钮，在原来的状态变更回调M.changed末尾调用RefreshTalentTooltip。这样加点、撤回、保存等待和保存回包都通过同一条已有通知链刷新说明，无需增加服务器查询。

Panel.lua新增函数职责：

- EnterTalent：记住当前按钮，再绘制说明。
- RefreshTalentTooltip：按钮仍可见、提示框仍属于它时重新绘制。
- LeaveTalent：移开或隐藏按钮时忘记它；只隐藏它自己的提示框。

核心保护如下：

```lua
if not button:IsVisible() then
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    hoveredTalent=nil
    return
end
if not GameTooltip:IsOwned(button) then
    hoveredTalent=nil
    return
end
Tooltip(button)
```

IsVisible防止关掉天赋页后旧说明重新弹出。IsOwned防止天赋刷新抢走背包物品的说明。清空hoveredTalent使后续服务器回包不会再碰已离开的按钮。这是事件驱动刷新和UI对象生命周期管理。

## 3. 收益对比怎样写才不误导？

睿智每级贡献最大法力5%、减耗3%，所以本天赋的累计贡献由rank乘这两个数给出。已存1级、草稿2级时显示5%→10%和3%→6%，不能显示多加10%而让人以为总计15%。

单级主动节点没有百分比变化，用“未获得→学会净化神像”更清楚。灵性传统和寻觅者显示各自被动贡献由0到对应数值。它们不代表把装备、其他光环、叠加规则都算进去后的最终面板属性。

`dirty = draft ~= saved`表示两份选择不一样。只在dirty时画变化预览；pending且operation为save时补正在保存提示。显示代码不调用施法、学技能或改属性。

## 4. 测试重点

wd67c_lua_test.lua执行实际WD8、Allocation，以及从实际Panel文件抽出的完整Tooltip/悬停函数。模拟鼠标进入一次后连续加点、撤回、保存等待、成功回包、失败回包，断言说明自动变化，不靠再次触发OnEnter。

还模拟隐藏按钮、移出按钮、其他提示框抢占所有权，保证服务器回包不会把它们打断。旧WD67A/B的加点和收费提示用例同时回归，防止改善外观时破坏原功能。

通过这些离线测试后仍要你实际登录检查位置、字高与鼠标反馈。程序模拟不能冒充游戏画面实测。


## 2026-09-24 WD67C 悬停同步基本实测通过
用户明确“这下点击就同步了”。确认点击天赋后、鼠标不移开也实时更新Tooltip；不扩大为收费重置、全部技能收益/双语、关闭页/其他Tooltip矩阵已验收。来源D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260924\codexfix_202609242013_阶段WD67C_天赋悬停实时刷新与加点收益对比，ZIP SHA256 4d1de527e2dfd3c3034c428f95f78014943851ce97a6e0c2923a5848c2fb5531。
复用：M.changed末尾刷新当前可见且仍拥有GameTooltip的按钮，OnLeave/OnHide清理；草稿与服务器已保存分开展示，不把预览当作已生效。
永久方法：beascendskills/build-wotlk-three-build-projection/SKILL.md；同名Tutor/WD67C-hover.md。下一批WD68候选不继承验收。
