# 种族核心_ObjectMgr.cpp：逐行讲解
这是从Claude已核验核心输出到联合包的实际对照；SharedDefines等可能包含已由Claude完成的前置。正式发布种族增量另见release_scope.json，不夹带独立职业变化。
来源：`C_核心前置_联合增量/交付/01_覆盖到源代码根目录/src/server/game/Globals/ObjectMgr.cpp`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `IsRaceMaskAlias` | 判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同 |
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `GetReputationRaceMaskForRace` | 给默认声望找同阵营模板位，不改变角色真实race |
| `GetSkillRaceClassInfo` | 按技能、真实种族、职业筛首条资格行；单族行对别名族不继承 |
| `data` | 按测试当前职业返回真实插件天赋数据 |
| `clear` | 清空测试状态、确认职业/天赋组，防止上一测试污染下一测试 |

## 本次修改涉及的实际代码片段

原件第4598–4602行：
```cpp
                {
                    uint32 raceBit = GetRaceMaskForRace(raceIndex);
                    if (raceMask == 0 || (raceBit && !IsRaceMaskAlias(raceIndex) && (raceBit & raceMask))) // RACENEXT3A: alias races take only race-agnostic rows (templates: Player::LearnDefaultSkills)
                    {
                        for (uint32 classIndex = CLASS_WARRIOR; classIndex < MAX_CLASSES; ++classIndex)
```

原件第4660–4664行：
```cpp
                {
                    uint32 raceBit = GetRaceMaskForRace(raceIndex);
                    if (raceMask == 0 || (raceBit && !IsRaceMaskAlias(raceIndex) && (raceBit & raceMask))) // RACENEXT3A: alias races take only race-agnostic rows (templates: Player::LearnDefaultSkills)
                    {
                        for (uint32 classIndex = CLASS_WARRIOR; classIndex < MAX_CLASSES; ++classIndex)
```

原件第4719–4723行：
```cpp
                {
                    uint32 raceBit = GetRaceMaskForRace(raceIndex);
                    if (raceMask == 0 || (raceBit && !IsRaceMaskAlias(raceIndex) && (raceBit & raceMask))) // RACENEXT3A: alias races take only race-agnostic rows (templates: Player::LearnDefaultSkills)
                    {
                        for (uint32 classIndex = CLASS_WARRIOR; classIndex < MAX_CLASSES; ++classIndex)
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 4598 | <code>                {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 4599 | <code>                    uint32 raceBit = GetRaceMaskForRace(raceIndex);</code> | 调用GetRaceMaskForRace（将真实race映射为旧接口资格位；36/37仍返回0）；此行参数来自当前上下文。 |
| 4600 | <code>                    if (raceMask == 0 &#124;&#124; (raceBit &amp;&amp; !IsRaceMaskAlias(raceIndex) &amp;&amp; (raceBit &amp; raceMask))) // RACENEXT3A: alias races take only race-agnostic rows (templates: Player::LearnDefaultSkills)</code> | 别名族不按母族共享位收出生技能/法术；只收raceMask0通用行。 |
| 4601 | <code>                    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 4602 | <code>                        for (uint32 classIndex = CLASS_WARRIOR; classIndex &lt; MAX_CLASSES; ++classIndex)</code> | 循环：for (uint32 classIndex = CLASS_WARRIOR; classIndex < MAX_CLASSES; ++classIndex)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 4660 | <code>                {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 4661 | <code>                    uint32 raceBit = GetRaceMaskForRace(raceIndex);</code> | 调用GetRaceMaskForRace（将真实race映射为旧接口资格位；36/37仍返回0）；此行参数来自当前上下文。 |
| 4662 | <code>                    if (raceMask == 0 &#124;&#124; (raceBit &amp;&amp; !IsRaceMaskAlias(raceIndex) &amp;&amp; (raceBit &amp; raceMask))) // RACENEXT3A: alias races take only race-agnostic rows (templates: Player::LearnDefaultSkills)</code> | 别名族不按母族共享位收出生技能/法术；只收raceMask0通用行。 |
| 4663 | <code>                    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 4664 | <code>                        for (uint32 classIndex = CLASS_WARRIOR; classIndex &lt; MAX_CLASSES; ++classIndex)</code> | 循环：for (uint32 classIndex = CLASS_WARRIOR; classIndex < MAX_CLASSES; ++classIndex)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 4719 | <code>                {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 4720 | <code>                    uint32 raceBit = GetRaceMaskForRace(raceIndex);</code> | 调用GetRaceMaskForRace（将真实race映射为旧接口资格位；36/37仍返回0）；此行参数来自当前上下文。 |
| 4721 | <code>                    if (raceMask == 0 &#124;&#124; (raceBit &amp;&amp; !IsRaceMaskAlias(raceIndex) &amp;&amp; (raceBit &amp; raceMask))) // RACENEXT3A: alias races take only race-agnostic rows (templates: Player::LearnDefaultSkills)</code> | 别名族不按母族共享位收出生技能/法术；只收raceMask0通用行。 |
| 4722 | <code>                    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 4723 | <code>                        for (uint32 classIndex = CLASS_WARRIOR; classIndex &lt; MAX_CLASSES; ++classIndex)</code> | 循环：for (uint32 classIndex = CLASS_WARRIOR; classIndex < MAX_CLASSES; ++classIndex)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
