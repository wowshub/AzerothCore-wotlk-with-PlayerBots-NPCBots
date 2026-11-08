# 种族核心_CharacterHandler.cpp：逐行讲解
这是从Claude已核验核心输出到联合包的实际对照；SharedDefines等可能包含已由Claude完成的前置。正式发布种族增量另见release_scope.json，不夹带独立职业变化。
来源：`C_核心前置_联合增量/交付/01_覆盖到源代码根目录/src/server/game/Handlers/CharacterHandler.cpp`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `IsWarriorOnlyNewRace` | 圈定39/49首批战士限制，供服务器最终拒绝非法组合 |
| `IsFirstCoaPostCreationRace` | 识别先前蛇人36/食人魔37，保持既有显式兼容路径 |
| `HandleCharCreateOpcode` | 检查客户端提交的真实组合，不能信灰按钮或预览外观 |
| `HandleCharFactionOrRaceChangeCallback` | 限制付费/服务改种族入口；本次不开放39/49转换服务 |
| `OnPlayerCreate` | 服务器建角回调，此时物品已分配，所以它不能解决创建前穿装资格 |
| `OnPlayerLogin` | 角色登录回调，调用同一补缺函数，避免新旧角色两种实现 |
| `data` | 按测试当前职业返回真实插件天赋数据 |
| `clear` | 清空测试状态、确认职业/天赋组，防止上一测试污染下一测试 |

## 本次修改涉及的实际代码片段

原件第325–335行：
```cpp
    // Keep all existing custom-class whitelists and saved characters intact.
    if (IsFirstCoaPostCreationRace(createInfo->Race) && createInfo->Class != CLASS_WARRIOR)
    {
        SendCharCreate(CHAR_CREATE_DISABLED);
        return;
    }

    // RACENEXT3A: Kul Tiran (39) / Mag'har Orc (49) are Warrior only - enforced here, not by a greyed button.
    if (IsWarriorOnlyNewRace(createInfo->Race) && createInfo->Class != CLASS_WARRIOR)
    {
        SendCharCreate(CHAR_CREATE_DISABLED);
```

原件第2229–2239行：
```cpp
    }

    // RACENEXT3A: no race / faction change into the Warrior-only new races (the class is not checked here).
    if (IsWarriorOnlyNewRace(factionChangeInfo->Race))
    {
        SendCharFactionChange(CHAR_CREATE_ERROR, factionChangeInfo.get());
        return;
    }

    if (!HasPermission(rbac::RBAC_PERM_SKIP_CHECK_CHARACTER_CREATION_RACEMASK))
    {
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 325 | <code>    // Keep all existing custom-class whitelists and saved characters intact.</code> | 说明注释：Keep all existing custom-class whitelists and saved characters intact.；它不执行，实际条件仍以相邻代码为准。 |
| 326 | <code>    if (IsFirstCoaPostCreationRace(createInfo-&gt;Race) &amp;&amp; createInfo-&gt;Class != CLASS_WARRIOR)</code> | 条件分支：只有`if (IsFirstCoaPostCreationRace(createInfo->Race) && createInfo->Class != CLASS_WARRIOR)`成立才走随后分支；不满足进入else/跳过。 |
| 327 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 328 | <code>        SendCharCreate(CHAR_CREATE_DISABLED);</code> | 此行属于“种族核心_CharacterHandler.cpp”：`SendCharCreate(CHAR_CREATE_DISABLED);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 329 | <code>        return;</code> | 此行属于“种族核心_CharacterHandler.cpp”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 330 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 331 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 332 | <code>    // RACENEXT3A: Kul Tiran (39) / Mag'har Orc (49) are Warrior only - enforced here, not by a greyed button.</code> | 说明注释：RACENEXT3A: Kul Tiran (39) / Mag'har Orc (49) are Warrior only - enforced here, not by a greyed button.；它不执行，实际条件仍以相邻代码为准。 |
| 333 | <code>    if (IsWarriorOnlyNewRace(createInfo-&gt;Race) &amp;&amp; createInfo-&gt;Class != CLASS_WARRIOR)</code> | 条件分支：只有`if (IsWarriorOnlyNewRace(createInfo->Race) && createInfo->Class != CLASS_WARRIOR)`成立才走随后分支；不满足进入else/跳过。 |
| 334 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 335 | <code>        SendCharCreate(CHAR_CREATE_DISABLED);</code> | 此行属于“种族核心_CharacterHandler.cpp”：`SendCharCreate(CHAR_CREATE_DISABLED);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 2229 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 2230 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 2231 | <code>    // RACENEXT3A: no race / faction change into the Warrior-only new races (the class is not checked here).</code> | 说明注释：RACENEXT3A: no race / faction change into the Warrior-only new races (the class is not checked here).；它不执行，实际条件仍以相邻代码为准。 |
| 2232 | <code>    if (IsWarriorOnlyNewRace(factionChangeInfo-&gt;Race))</code> | 条件分支：只有`if (IsWarriorOnlyNewRace(factionChangeInfo->Race))`成立才走随后分支；不满足进入else/跳过。 |
| 2233 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 2234 | <code>        SendCharFactionChange(CHAR_CREATE_ERROR, factionChangeInfo.get());</code> | 此行属于“种族核心_CharacterHandler.cpp”：`SendCharFactionChange(CHAR_CREATE_ERROR, factionChangeInfo.get());`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 2235 | <code>        return;</code> | 此行属于“种族核心_CharacterHandler.cpp”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 2236 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 2237 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 2238 | <code>    if (!HasPermission(rbac::RBAC_PERM_SKIP_CHECK_CHARACTER_CREATION_RACEMASK))</code> | 条件分支：只有`if (!HasPermission(rbac::RBAC_PERM_SKIP_CHECK_CHARACTER_CREATION_RACEMASK))`成立才走随后分支；不满足进入else/跳过。 |
| 2239 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
