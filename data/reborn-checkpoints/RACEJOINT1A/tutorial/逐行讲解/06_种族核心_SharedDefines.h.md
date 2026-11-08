# 种族核心_SharedDefines.h：逐行讲解
这是从Claude已核验核心输出到联合包的实际对照；SharedDefines等可能包含已由Claude完成的前置。正式发布种族增量另见release_scope.json，不夹带独立职业变化。
来源：`C_核心前置_联合增量/交付/01_覆盖到源代码根目录/src/server/shared/SharedDefines.h`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `IsRaceMaskAlias` | 判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同 |
| `IsRaceMaskable` | 判断是否允许走32位掩码运算，避免把36/37误卷入 |
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `GetRaceAliasTemplateRace` | 只把39映射到人类1、49映射到兽人2；其它返回0 |
| `GetReputationRaceMaskForRace` | 给默认声望找同阵营模板位，不改变角色真实race |
| `IsWarriorOnlyNewRace` | 圈定39/49首批战士限制，供服务器最终拒绝非法组合 |
| `IsFirstCoaPostCreationRace` | 识别先前蛇人36/食人魔37，保持既有显式兼容路径 |
| `GetFirstCoaParentMask` | 仅给36/37返回人类/兽人模板位，不能据此复制全部母族特长 |
| `IsFirstCoaLanguageSkill` | 只承认蛇人通用语98、食人魔兽人语109 |
| `IsFirstCoaSkillMaskAllowed` | 允许指定阵营语言或含模板位的共享行，排除其它单族特长 |
| `state` | 读取四张出生表快照，让测试能对比拒绝前后是否零改动 |

## 本次修改涉及的实际代码片段

原件第98–142行：
```cpp
    RACE_TUSKARR            = 28,
    RACE_SETHRAK            = 36, // Alliance, first CoA post-creation test
    RACE_TWO_HEADED_OGRE    = 37, // Horde; never alias the stored race ID
    RACE_KUL_TIRAN          = 39, // RACENEXT3A: Alliance, mask-alias of race 7 (bit 6), human template
    RACE_MAGHAR_ORC         = 49  // RACENEXT3A: Horde, mask-alias of race 17 (bit 16), orc template
};

// max+1 for player race
#define MAX_RACES         50

// 3.3.5-era race masks are uint32. Only race IDs 1..32 can be represented
// safely as 1 << (race - 1). Dracthyr now uses Race27, so it follows the
// normal mask path; the helper still protects any future high custom race.
//
// RACENEXT3A (CoA "mod 32" rule): race ids >= 38 reuse the bit of (id - 1) & 31, so 39 shares bit 6 with
// Gnome (7) and 49 shares bit 16 with Eredar (17). Races sharing a bit MUST be the same faction (RaceMgr checks it).
// Ids 33..37 stay mask 0: 36 / 37 run on the RACEFLOW2A template path and must not be migrated.
// A shared bit is NOT a shared identity: racial rows keyed to one race bit are not inherited (IsRaceMaskAlias).
inline constexpr bool IsRaceMaskAlias(uint8 race)
{
    return race >= 38;
}

inline constexpr bool IsRaceMaskable(uint8 race)
{
    return race > RACE_NONE && (race <= 32 || IsRaceMaskAlias(race));
}

inline constexpr uint32 GetRaceMaskForRace(uint8 race)
{
    return IsRaceMaskable(race) ? (uint32(1) << ((race - 1) & 31)) : 0;
}

// Parent race whose class/skill template an alias race borrows (0 = none).
inline constexpr uint8 GetRaceAliasTemplateRace(uint8 race)
{
    return race == RACE_KUL_TIRAN ? uint8(RACE_HUMAN) : race == RACE_MAGHAR_ORC ? uint8(RACE_ORC) : uint8(0);
}

// Races that may only be created as Warrior (enforced in HandleCharCreateOpcode, not by a greyed button).
inline constexpr bool IsWarriorOnlyNewRace(uint8 race)
{
    return race == RACE_KUL_TIRAN || race == RACE_MAGHAR_ORC;
}

```

原件第181–189行：
```cpp
        case RACE_PANDAREN_ALLIANCE:
        case RACE_SETHRAK:
        case RACE_KUL_TIRAN:
            return GetRaceMaskForRace(RACE_HUMAN);
        case RACE_NAGA:
        case RACE_TWO_HEADED_OGRE:
        case RACE_MAGHAR_ORC:
            return GetRaceMaskForRace(RACE_ORC);
        case RACE_DRACTHYR:
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 98 | <code>    RACE_TUSKARR            = 28,</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`RACE_TUSKARR            = 28,`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 99 | <code>    RACE_SETHRAK            = 36, // Alliance, first CoA post-creation test</code> | 保存蛇人真实ID36，不把它改成低位母族身份。 |
| 100 | <code>    RACE_TWO_HEADED_OGRE    = 37, // Horde; never alias the stored race ID</code> | 保存双头食人魔真实ID37，不能用单头/巨魔代替。 |
| 101 | <code>    RACE_KUL_TIRAN          = 39, // RACENEXT3A: Alliance, mask-alias of race 7 (bit 6), human template</code> | 声明库尔提拉斯真实ID39；其共享位来自7，基本模板来自人类1。 |
| 102 | <code>    RACE_MAGHAR_ORC         = 49  // RACENEXT3A: Horde, mask-alias of race 17 (bit 16), orc template</code> | 声明玛格汉真实ID49；共享位来自17，基本模板来自兽人2。 |
| 103 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 104 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 105 | <code>// max+1 for player race</code> | 说明注释：max+1 for player race；它不执行，实际条件仍以相邻代码为准。 |
| 106 | <code>#define MAX_RACES         50</code> | 静态上限为最大ID+1，覆盖49；不自动证明客户端DLL/所有数组已支持。 |
| 107 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 108 | <code>// 3.3.5-era race masks are uint32. Only race IDs 1..32 can be represented</code> | 说明注释：3.3.5-era race masks are uint32. Only race IDs 1..32 can be represented；它不执行，实际条件仍以相邻代码为准。 |
| 109 | <code>// safely as 1 &lt;&lt; (race - 1). Dracthyr now uses Race27, so it follows the</code> | 说明注释：safely as 1 << (race - 1). Dracthyr now uses Race27, so it follows the；它不执行，实际条件仍以相邻代码为准。 |
| 110 | <code>// normal mask path; the helper still protects any future high custom race.</code> | 说明注释：normal mask path; the helper still protects any future high custom race.；它不执行，实际条件仍以相邻代码为准。 |
| 111 | <code>//</code> | 说明注释：；它不执行，实际条件仍以相邻代码为准。 |
| 112 | <code>// RACENEXT3A (CoA "mod 32" rule): race ids &gt;= 38 reuse the bit of (id - 1) &amp; 31, so 39 shares bit 6 with</code> | 说明注释：RACENEXT3A (CoA "mod 32" rule): race ids >= 38 reuse the bit of (id - 1) & 31, so 39 shares bit 6 with；它不执行，实际条件仍以相邻代码为准。 |
| 113 | <code>// Gnome (7) and 49 shares bit 16 with Eredar (17). Races sharing a bit MUST be the same faction (RaceMgr checks it).</code> | 说明注释：Gnome (7) and 49 shares bit 16 with Eredar (17). Races sharing a bit MUST be the same faction (RaceMgr checks it).；它不执行，实际条件仍以相邻代码为准。 |
| 114 | <code>// Ids 33..37 stay mask 0: 36 / 37 run on the RACEFLOW2A template path and must not be migrated.</code> | 说明注释：Ids 33..37 stay mask 0: 36 / 37 run on the RACEFLOW2A template path and must not be migrated.；它不执行，实际条件仍以相邻代码为准。 |
| 115 | <code>// A shared bit is NOT a shared identity: racial rows keyed to one race bit are not inherited (IsRaceMaskAlias).</code> | 说明注释：A shared bit is NOT a shared identity: racial rows keyed to one race bit are not inherited (IsRaceMaskAlias).；它不执行，实际条件仍以相邻代码为准。 |
| 116 | <code>inline constexpr bool IsRaceMaskAlias(uint8 race)</code> | 定义/进入函数：判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同。 |
| 117 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 118 | <code>    return race &gt;= 38;</code> | 本批约定高ID别名规则从38起；33–37保持mask0路径。 |
| 119 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 120 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 121 | <code>inline constexpr bool IsRaceMaskable(uint8 race)</code> | 定义/进入函数：判断是否允许走32位掩码运算，避免把36/37误卷入。 |
| 122 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 123 | <code>    return race &gt; RACE_NONE &amp;&amp; (race &lt;= 32 &#124;&#124; IsRaceMaskAlias(race));</code> | 返回表达式`race > RACE_NONE && (race <= 32 ／／ IsRaceMaskAlias(race))`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 124 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 125 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 126 | <code>inline constexpr uint32 GetRaceMaskForRace(uint8 race)</code> | 定义/进入函数：将真实race映射为旧接口资格位；36/37仍返回0。 |
| 127 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 128 | <code>    return IsRaceMaskable(race) ? (uint32(1) &lt;&lt; ((race - 1) &amp; 31)) : 0;</code> | 先减1转零基位号，再&31限制0–31；39→6、49→16，避免超宽移位。 |
| 129 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 130 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 131 | <code>// Parent race whose class/skill template an alias race borrows (0 = none).</code> | 说明注释：Parent race whose class/skill template an alias race borrows (0 = none).；它不执行，实际条件仍以相邻代码为准。 |
| 132 | <code>inline constexpr uint8 GetRaceAliasTemplateRace(uint8 race)</code> | 定义/进入函数：只把39映射到人类1、49映射到兽人2；其它返回0。 |
| 133 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 134 | <code>    return race == RACE_KUL_TIRAN ? uint8(RACE_HUMAN) : race == RACE_MAGHAR_ORC ? uint8(RACE_ORC) : uint8(0);</code> | 返回表达式`race == RACE_KUL_TIRAN ? uint8(RACE_HUMAN) : race == RACE_MAGHAR_ORC ? uint8(RACE_ORC) : uint8(0)`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 135 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 136 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 137 | <code>// Races that may only be created as Warrior (enforced in HandleCharCreateOpcode, not by a greyed button).</code> | 说明注释：Races that may only be created as Warrior (enforced in HandleCharCreateOpcode, not by a greyed button).；它不执行，实际条件仍以相邻代码为准。 |
| 138 | <code>inline constexpr bool IsWarriorOnlyNewRace(uint8 race)</code> | 定义/进入函数：圈定39/49首批战士限制，供服务器最终拒绝非法组合。 |
| 139 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 140 | <code>    return race == RACE_KUL_TIRAN &#124;&#124; race == RACE_MAGHAR_ORC;</code> | 返回表达式`race == RACE_KUL_TIRAN ／／ race == RACE_MAGHAR_ORC`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 141 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 142 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 181 | <code>        case RACE_PANDAREN_ALLIANCE:</code> | 枚举当前允许的技能/种族分支：case RACE_PANDAREN_ALLIANCE:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 182 | <code>        case RACE_SETHRAK:</code> | 枚举当前允许的技能/种族分支：case RACE_SETHRAK:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 183 | <code>        case RACE_KUL_TIRAN:</code> | 枚举当前允许的技能/种族分支：case RACE_KUL_TIRAN:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 184 | <code>            return GetRaceMaskForRace(RACE_HUMAN);</code> | 返回表达式`GetRaceMaskForRace(RACE_HUMAN)`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 185 | <code>        case RACE_NAGA:</code> | 枚举当前允许的技能/种族分支：case RACE_NAGA:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 186 | <code>        case RACE_TWO_HEADED_OGRE:</code> | 枚举当前允许的技能/种族分支：case RACE_TWO_HEADED_OGRE:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 187 | <code>        case RACE_MAGHAR_ORC:</code> | 枚举当前允许的技能/种族分支：case RACE_MAGHAR_ORC:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 188 | <code>            return GetRaceMaskForRace(RACE_ORC);</code> | 返回表达式`GetRaceMaskForRace(RACE_ORC)`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 189 | <code>        case RACE_DRACTHYR:</code> | 枚举当前允许的技能/种族分支：case RACE_DRACTHYR:；这些编号的含义见核心参数表，仍需模板行存在。 |
