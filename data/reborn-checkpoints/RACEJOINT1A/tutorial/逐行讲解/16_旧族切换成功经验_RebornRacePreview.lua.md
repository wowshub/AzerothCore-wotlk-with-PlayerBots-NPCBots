# 旧族切换成功经验_RebornRacePreview.lua：逐行讲解
这份C是在实际Open入口补刷新并隐藏selection长条；A/B失败不作为成功模板。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261105\codexfix_20261105_阶段RACEUI1C_真实种族按钮刷新与长框修复\02_覆盖到客户端根目录\导入Patch-YB.mpq\Interface\GlueXML\RebornRacePreview.lua`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `Open` | 上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它 |
| `CharacterCreate_RefreshRaceClassState` | 在本次种族/性别确定后统一重算职业及独立职业按钮状态 |

## 本次修改涉及的实际代码片段

原件第85–93行：
```lua
    A, B = e, s
    SetSelectedRace(s) SetSelectedSex(sex or 0) SetCharacterRace(s) SetCharacterCreateFacing(-15)
    -- RACEUI1C: this custom button bypasses CharacterRace_OnClick; refresh the real class UI here.
    if type(CharacterCreate_RefreshRaceClassState) == "function" then
        CharacterCreate_RefreshRaceClassState(s)
    end

    if CharacterCreate_UpdateModel then CharacterCreate_UpdateModel(CharacterCreate) end
    if e.drac and CharacterCreate_SetDracthyrBackground then pcall(CharacterCreate_SetDracthyrBackground, 1) CharacterCreate.r27WheelZoomLevel = 1 end
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 85 | <code>    A, B = e, s</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`A, B = e, s`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 86 | <code>    SetSelectedRace(s) SetSelectedSex(sex or 0) SetCharacterRace(s) SetCharacterCreateFacing(-15)</code> | 此行属于“旧族切换成功经验_RebornRacePreview.lua”：`SetSelectedRace(s) SetSelectedSex(sex or 0) SetCharacterRace(s) SetCharacterCreateFacing(-15)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 87 | <code>    -- RACEUI1C: this custom button bypasses CharacterRace_OnClick; refresh the real class UI here.</code> | 说明注释：RACEUI1C: this custom button bypasses CharacterRace_OnClick; refresh the real class UI here.；它不执行，实际条件仍以相邻代码为准。 |
| 88 | <code>    if type(CharacterCreate_RefreshRaceClassState) == "function" then</code> | 条件分支：只有`if type(CharacterCreate_RefreshRaceClassState) == "function"`成立才走随后分支；不满足进入else/跳过。 |
| 89 | <code>        CharacterCreate_RefreshRaceClassState(s)</code> | 调用CharacterCreate_RefreshRaceClassState（在本次种族/性别确定后统一重算职业及独立职业按钮状态）；此行参数来自当前上下文。 |
| 90 | <code>    end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 91 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 92 | <code>    if CharacterCreate_UpdateModel then CharacterCreate_UpdateModel(CharacterCreate) end</code> | 条件分支：只有`if CharacterCreate_UpdateModel  CharacterCreate_UpdateModel(CharacterCreate) end`成立才走随后分支；不满足进入else/跳过。 |
| 93 | <code>    if e.drac and CharacterCreate_SetDracthyrBackground then pcall(CharacterCreate_SetDracthyrBackground, 1) CharacterCreate.r27WheelZoomLevel = 1 end</code> | 条件分支：只有`if e.drac and CharacterCreate_SetDracthyrBackground  pcall(CharacterCreate_SetDracthyrBackground, 1) CharacterCreate.r27WheelZoomLevel = 1 end`成立才走随后分支；不满足进入else/跳过。 |
