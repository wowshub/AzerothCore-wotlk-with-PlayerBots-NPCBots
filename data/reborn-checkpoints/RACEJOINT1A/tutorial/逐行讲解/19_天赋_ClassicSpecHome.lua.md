# 天赋_ClassicSpecHome.lua：逐行讲解
B保留A三文件，另将首页已学14号描边绿色；这里只讲实际变化行及必要上下文。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261107\codexfix_20261107_072718_阶段TGFIX1B_当前已学绿色醒目与经典天赋累计修复\02_覆盖到客户端根目录\Interface\AddOns\RebornTalentGuide\ClassicSpecHome.lua`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `Open` | 上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它 |
| `RefreshTree` | 重读原生已学和余点，连接按钮、可加绿框和解释文字 |
| `ShowTree` | 首次显示后再刷新，避免第一次打开没接上点击函数 |

## 本次修改涉及的实际代码片段

原件第142–146行：
```lua
  end
  card.points=label(card,'',-576,'GameFontHighlightSmall')
  card.points:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',14,'OUTLINE');card.points:SetHeight(18)
  card.choose=C.Button(card,76,-595,280,'查看天赋',function()B.ShowTree(B.token,index)end)
  B.cards[i]=card
```

原件第169–173行：
```lua
  local sum=0;if ranks then for _,n in ipairs(ranks[i])do sum=sum+n end end
  card.points:SetText(ranks and(tr('当前已学 ','Learned: ')..sum)or tr('当前点数尚未就绪','Points not available'))
  if ranks then card.points:SetTextColor(.25,1,.35)else card.points:SetTextColor(1,.7,.25)end
 end
end
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 142 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 143 | <code>  card.points=label(card,'',-576,'GameFontHighlightSmall')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`card.points=label(card,'',-576,'GameFontHighlightSmall')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 144 | <code>  card.points:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',14,'OUTLINE');card.points:SetHeight(18)</code> | 设置字体路径、14号逻辑字号和OUTLINE描边；字体缺省用现有标准路径。 为放大的已学文字留18逻辑单位行高，避免上下裁切。 |
| 145 | <code>  card.choose=C.Button(card,76,-595,280,'查看天赋',function()B.ShowTree(B.token,index)end)</code> | 调用ShowTree（首次显示后再刷新，避免第一次打开没接上点击函数）；此行参数来自当前上下文。 |
| 146 | <code>  B.cards[i]=card</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`B.cards[i]=card`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 169 | <code>  local sum=0;if ranks then for _,n in ipairs(ranks[i])do sum=sum+n end end</code> | 定义局部变量：local sum=0;if ranks then for _,n in ipairs(ranks[i])do sum=sum+n end end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 170 | <code>  card.points:SetText(ranks and(tr('当前已学 ','Learned: ')..sum)or tr('当前点数尚未就绪','Points not available'))</code> | 此行属于“天赋_ClassicSpecHome.lua”：`card.points:SetText(ranks and(tr('当前已学 ','Learned: ')..sum)or tr('当前点数尚未就绪','Points not available'))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 171 | <code>  if ranks then card.points:SetTextColor(.25,1,.35)else card.points:SetTextColor(1,.7,.25)end</code> | 确认有已学数据用亮绿色RGB(.25,1,.35)，未同步用橙黄(1,.7,.25)；不代表专精激活。 |
| 172 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 173 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
