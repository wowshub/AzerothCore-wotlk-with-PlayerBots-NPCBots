# 旧族切换成功经验_CharacterCreate.lua：逐行讲解
这份C是在实际Open入口补刷新并隐藏selection长条；A/B失败不作为成功模板。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261105\codexfix_20261105_阶段RACEUI1C_真实种族按钮刷新与长框修复\02_覆盖到客户端根目录\导入Patch-YB.mpq\Interface\GlueXML\CharacterCreate.lua`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `RaceUIKind` | 从当前枚举项的内部token识别新族，不把按钮下标当raceID |
| `RaceUIRandomName` | 先尝试原生随机名，缺失或重复时用同性别候选池 |
| `SetBackgroundModel` | 选择Glue舞台背景；只对CharacterSelect做场景token别名 |
| `CharacterCreate_RefreshRaceClassState` | 在本次种族/性别确定后统一重算职业及独立职业按钮状态 |

## 本次修改涉及的实际代码片段

原件第6134–6142行：
```lua
-- RACEUI1B: class button state is a result of the current selection, not click history.
local function RaceUIFinishClassState()
 -- RACEUI1C: this XML texture is a 256x96 character-list bar, not the circular class ring.
 for i=1,MAX_CLASSES_PER_RACE do
  local button=_G["CharCreateClassButton"..i]
  if button and button.selection then button.selection:Hide() end
 end
 if not RaceUISelected() or PAID_SERVICE_TYPE then return end
 local warrior=RaceUIWarrior()
```

原件第6157–6161行：
```lua
   local cover=_G["CharCreateClassButton"..index.."DisableTexture"]
   if cover then if allowed then cover:Hide() else cover:Show() end end
   if button.selection then button.selection:Hide() end
   if button.nameFrame and button.nameFrame.text then
    button.nameFrame.text:SetText((allowed and "|cffffd100" or "|cff696969")..tostring(classes[offset]).."|r")
```

原件第6169–6189行：
```lua
   button:Disable();button:SetChecked(false);SetButtonDesaturated(button,true)
   if button.selection then button.selection:Hide() end
   if button.ascendNeutralRing then button.ascendNeutralRing:SetDesaturated(true);button.ascendNeutralRing:SetAlpha(.4) end
   local normal=button:GetNormalTexture()
   if normal then normal:SetAlpha(.4) end
   if button.nameFrame and button.nameFrame.text then button.nameFrame.text:SetTextColor(.45,.45,.45);button.nameFrame.text:SetAlpha(.65) end
  end
 end
 CharCreate_EnableNextButton(warrior~=nil and selected==warrior)
end
-- RACEUI1C: restore styling before the original whitelist computes old-race availability.
local function RaceUIResetDetachedStyles()
 for _,button in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton}) do
  if button then
   if button.ascendNeutralRing then button.ascendNeutralRing:SetAlpha(1);button.ascendNeutralRing:SetDesaturated(false) end
   local normal=button:GetNormalTexture();if normal then normal:SetAlpha(1) end
   if button.nameFrame and button.nameFrame.text then button.nameFrame.text:SetTextColor(1,.82,0);button.nameFrame.text:SetAlpha(1) end
  end
 end
end
do
```

原件第6201–6205行：
```lua
   if cover then cover:Hide() end
  end
  RaceUIResetDetachedStyles()
  enumerate(...)
  RaceUIFinishClassState()
```

原件第6221–6233行：
```lua
 end
end

-- RACEUI1C: public bridge for the actual custom race-button Open handler.
function CharacterCreate_RefreshRaceClassState(raceIndex)
 if PAID_SERVICE_TYPE then return end
 if raceIndex~=GetSelectedRace() then return end
 CharacterCreate.selectedRace=raceIndex
 CharacterCreateEnumerateClasses(GetAvailableClasses())
 local _,_,index=GetSelectedClass()
 SetCharacterClass(index)
 RaceUIFinishClassState()
end
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 6134 | <code>-- RACEUI1B: class button state is a result of the current selection, not click history.</code> | 说明注释：RACEUI1B: class button state is a result of the current selection, not click history.；它不执行，实际条件仍以相邻代码为准。 |
| 6135 | <code>local function RaceUIFinishClassState()</code> | 定义局部变量：local function RaceUIFinishClassState()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6136 | <code> -- RACEUI1C: this XML texture is a 256x96 character-list bar, not the circular class ring.</code> | 说明注释：RACEUI1C: this XML texture is a 256x96 character-list bar, not the circular class ring.；它不执行，实际条件仍以相邻代码为准。 |
| 6137 | <code> for i=1,MAX_CLASSES_PER_RACE do</code> | 循环：for i=1,MAX_CLASSES_PER_RACE do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 6138 | <code>  local button=_G["CharCreateClassButton"..i]</code> | 定义局部变量：local button=_G["CharCreateClassButton"..i]；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6139 | <code>  if button and button.selection then button.selection:Hide() end</code> | 条件分支：只有`if button and button.selection  button.selection:Hide() end`成立才走随后分支；不满足进入else/跳过。 |
| 6140 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6141 | <code> if not RaceUISelected() or PAID_SERVICE_TYPE then return end</code> | 条件分支：只有`if not RaceUISelected() or PAID_SERVICE_TYPE  return end`成立才走随后分支；不满足进入else/跳过。 |
| 6142 | <code> local warrior=RaceUIWarrior()</code> | 定义局部变量：local warrior=RaceUIWarrior()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6157 | <code>   local cover=_G["CharCreateClassButton"..index.."DisableTexture"]</code> | 定义局部变量：local cover=_G["CharCreateClassButton"..index.."DisableTexture"]；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6158 | <code>   if cover then if allowed then cover:Hide() else cover:Show() end end</code> | 条件分支：只有`if cover  if allowed  cover:Hide() else cover:Show() end end`成立才走随后分支；不满足进入else/跳过。 |
| 6159 | <code>   if button.selection then button.selection:Hide() end</code> | 条件分支：只有`if button.selection  button.selection:Hide() end`成立才走随后分支；不满足进入else/跳过。 |
| 6160 | <code>   if button.nameFrame and button.nameFrame.text then</code> | 条件分支：只有`if button.nameFrame and button.nameFrame.text`成立才走随后分支；不满足进入else/跳过。 |
| 6161 | <code>    button.nameFrame.text:SetText((allowed and "&#124;cffffd100" or "&#124;cff696969")..tostring(classes[offset]).."&#124;r")</code> | 此行属于“local function RaceUIFinishClassState()”：`button.nameFrame.text:SetText((allowed and "／cffffd100" or "／cff696969")..tostring(classes[offset]).."／r")`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6169 | <code>   button:Disable();button:SetChecked(false);SetButtonDesaturated(button,true)</code> | 此行属于“local function RaceUIFinishClassState()”：`button:Disable();button:SetChecked(false);SetButtonDesaturated(button,true)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6170 | <code>   if button.selection then button.selection:Hide() end</code> | 条件分支：只有`if button.selection  button.selection:Hide() end`成立才走随后分支；不满足进入else/跳过。 |
| 6171 | <code>   if button.ascendNeutralRing then button.ascendNeutralRing:SetDesaturated(true);button.ascendNeutralRing:SetAlpha(.4) end</code> | 条件分支：只有`if button.ascendNeutralRing  button.ascendNeutralRing:SetDesaturated(true);button.ascendNeutralRing:SetAlpha(.4) end`成立才走随后分支；不满足进入else/跳过。 |
| 6172 | <code>   local normal=button:GetNormalTexture()</code> | 定义局部变量：local normal=button:GetNormalTexture()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6173 | <code>   if normal then normal:SetAlpha(.4) end</code> | 条件分支：只有`if normal  normal:SetAlpha(.4) end`成立才走随后分支；不满足进入else/跳过。 |
| 6174 | <code>   if button.nameFrame and button.nameFrame.text then button.nameFrame.text:SetTextColor(.45,.45,.45);button.nameFrame.text:SetAlpha(.65) end</code> | 条件分支：只有`if button.nameFrame and button.nameFrame.text  button.nameFrame.text:SetTextColor(.45,.45,.45);button.nameFrame.text:SetAlpha(.65) end`成立才走随后分支；不满足进入else/跳过。 |
| 6175 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6176 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6177 | <code> CharCreate_EnableNextButton(warrior~=nil and selected==warrior)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`CharCreate_EnableNextButton(warrior~=nil and selected==warrior)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 6178 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6179 | <code>-- RACEUI1C: restore styling before the original whitelist computes old-race availability.</code> | 说明注释：RACEUI1C: restore styling before the original whitelist computes old-race availability.；它不执行，实际条件仍以相邻代码为准。 |
| 6180 | <code>local function RaceUIResetDetachedStyles()</code> | 定义局部变量：local function RaceUIResetDetachedStyles()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6181 | <code> for _,button in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton}) do</code> | 循环：for _,button in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton}) do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 6182 | <code>  if button then</code> | 条件分支：只有`if button`成立才走随后分支；不满足进入else/跳过。 |
| 6183 | <code>   if button.ascendNeutralRing then button.ascendNeutralRing:SetAlpha(1);button.ascendNeutralRing:SetDesaturated(false) end</code> | 取消可购买节点的去色；不擅自给尚未解锁节点上色。 |
| 6184 | <code>   local normal=button:GetNormalTexture();if normal then normal:SetAlpha(1) end</code> | 定义局部变量：local normal=button:GetNormalTexture();if normal then normal:SetAlpha(1) end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6185 | <code>   if button.nameFrame and button.nameFrame.text then button.nameFrame.text:SetTextColor(1,.82,0);button.nameFrame.text:SetAlpha(1) end</code> | 条件分支：只有`if button.nameFrame and button.nameFrame.text  button.nameFrame.text:SetTextColor(1,.82,0);button.nameFrame.text:SetAlpha(1) end`成立才走随后分支；不满足进入else/跳过。 |
| 6186 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6187 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6188 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6189 | <code>do</code> | 此行属于“local function RaceUIResetDetachedStyles()”：`do`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6201 | <code>   if cover then cover:Hide() end</code> | 条件分支：只有`if cover  cover:Hide() end`成立才走随后分支；不满足进入else/跳过。 |
| 6202 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6203 | <code>  RaceUIResetDetachedStyles()</code> | 此行属于“local function RaceUIResetDetachedStyles()”：`RaceUIResetDetachedStyles()`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6204 | <code>  enumerate(...)</code> | 此行属于“local function RaceUIResetDetachedStyles()”：`enumerate(...)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6205 | <code>  RaceUIFinishClassState()</code> | 此行属于“local function RaceUIResetDetachedStyles()”：`RaceUIFinishClassState()`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6221 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6222 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 6223 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 6224 | <code>-- RACEUI1C: public bridge for the actual custom race-button Open handler.</code> | 说明注释：RACEUI1C: public bridge for the actual custom race-button Open handler.；它不执行，实际条件仍以相邻代码为准。 |
| 6225 | <code>function CharacterCreate_RefreshRaceClassState(raceIndex)</code> | 定义/进入函数：在本次种族/性别确定后统一重算职业及独立职业按钮状态。 |
| 6226 | <code> if PAID_SERVICE_TYPE then return end</code> | 条件分支：只有`if PAID_SERVICE_TYPE  return end`成立才走随后分支；不满足进入else/跳过。 |
| 6227 | <code> if raceIndex~=GetSelectedRace() then return end</code> | 条件分支：只有`if raceIndex~=GetSelectedRace()  return end`成立才走随后分支；不满足进入else/跳过。 |
| 6228 | <code> CharacterCreate.selectedRace=raceIndex</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`CharacterCreate.selectedRace=raceIndex`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 6229 | <code> CharacterCreateEnumerateClasses(GetAvailableClasses())</code> | 此行属于“function CharacterCreate_RefreshRaceClassState(raceIndex)”：`CharacterCreateEnumerateClasses(GetAvailableClasses())`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6230 | <code> local _,_,index=GetSelectedClass()</code> | 定义局部变量：local _,_,index=GetSelectedClass()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6231 | <code> SetCharacterClass(index)</code> | 此行属于“function CharacterCreate_RefreshRaceClassState(raceIndex)”：`SetCharacterClass(index)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6232 | <code> RaceUIFinishClassState()</code> | 此行属于“function CharacterCreate_RefreshRaceClassState(raceIndex)”：`RaceUIFinishClassState()`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6233 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
