# 种族核心_Player.cpp：逐行讲解
这是从Claude已核验核心输出到联合包的实际对照；SharedDefines等可能包含已由Claude完成的前置。正式发布种族增量另见release_scope.json，不夹带独立职业变化。
来源：`C_核心前置_联合增量/交付/01_覆盖到源代码根目录/src/server/game/Entities/Player/Player.cpp`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `IsRaceMaskAlias` | 判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同 |
| `GetRaceAliasTemplateRace` | 只把39映射到人类1、49映射到兽人2；其它返回0 |
| `IsFirstCoaPostCreationRace` | 识别先前蛇人36/食人魔37，保持既有显式兼容路径 |
| `IsFirstCoaSkillMaskAllowed` | 允许指定阵营语言或含模板位的共享行，排除其它单族特长 |
| `GetSkillRaceClassInfo` | 按技能、真实种族、职业筛首条资格行；单族行对别名族不继承 |
| `IsSkillLineAbilityRaceAllowedForPlayer` | 在技能奖励法术这一入口同样隔离共享位母族能力 |
| `LearnDefaultSkills` | 学基础技能；这一步位于出生物品之前，决定装备能否直接穿上 |
| `state` | 读取四张出生表快照，让测试能对比拒绝前后是否零改动 |
| `data` | 按测试当前职业返回真实插件天赋数据 |
| `clear` | 清空测试状态、确认职业/天赋组，防止上一测试污染下一测试 |
| `LearnTalent` | 测试替身只记录一次待确认请求；不是游戏内真的加点 |
| `HasSkill` | 检查已有技能，防止覆盖练过的熟练度 |
| `HasSpell` | 检查已学法术，保证重复登录不会重复授予 |
| `SetSkill` | 设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器 |
| `LearnDefaultSkill` | 沿核心默认技能学习路径授予模板已有基础技能，不强制练满 |

## 本次修改涉及的实际代码片段

原件第118–129行：
```cpp
bool IsSkillLineAbilityRaceAllowedForPlayer(Player const* player, SkillLineAbilityEntry const* ability)
{
    // RACENEXT3A: alias races (39 / 49) share a mask bit with another race but do not inherit its racials.
    if (IsRaceMaskAlias(player->getRace()))
    {
        if (!ability->RaceMask)
            return true;
        return (ability->RaceMask & (ability->RaceMask - 1)) && (ability->RaceMask & player->getRaceMask());
    }

    if (!ability->RaceMask || (ability->RaceMask & player->getRaceMask()))
        return true;
```

原件第12284–12328行：
```cpp
    }

    // RACENEXT3A: 39 learns the human warrior base skills, 49 the orc ones. GetSkillRaceClassInfo rejects
    // single-race rows for alias races, so racials are never inherited; plus the faction language and its spell.
    // This runs from Player::Create BEFORE the starting outfit is distributed, so weapons/armour can be equipped.
    if (uint8 templateRace = GetRaceAliasTemplateRace(getRace()))
    {
        // RACEJOINT1A: copy only existing parent Warrior starter skills.
        // Never copy parent language/racial/profession lines through the shared mask.
        if (getClass() == CLASS_WARRIOR)
            if (PlayerInfo const* templateInfo = sObjectMgr->GetPlayerInfo(templateRace, getClass()))
                for (auto const& skill : templateInfo->skills)
                {
                    bool basic = false;
                    switch (skill.SkillId)
                    {
                        case 26: case 256: case 257: case 95: case 162:
                        case 43: case 44: case 54: case 55: case 160:
                        case 172: case 173: case 176:
                        case 413: case 414: case 415: case 433:
                            basic = true;
                            break;
                        default:
                            break;
                    }
                    if (basic && !HasSkill(skill.SkillId))
                        LearnDefaultSkill(skill.SkillId, skill.Rank);
                }

        uint32 languageSkill = (templateRace == RACE_ORC) ? SKILL_LANG_ORCISH : SKILL_LANG_COMMON;
        if (!HasSkill(languageSkill))
            SetSkill(languageSkill, 0, 300, 300);

        uint32 languageSpell = (templateRace == RACE_ORC) ? 669 : 668;
        if (!HasSpell(languageSpell))
        {
            if (!IsInWorld())
                addSpell(languageSpell, SPEC_MASK_ALL, true);
            else
                learnSpell(languageSpell);
        }
    }

    if (getRace() == RACE_DRACTHYR)
    {
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 118 | <code>bool IsSkillLineAbilityRaceAllowedForPlayer(Player const* player, SkillLineAbilityEntry const* ability)</code> | 定义/进入函数：在技能奖励法术这一入口同样隔离共享位母族能力。 |
| 119 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 120 | <code>    // RACENEXT3A: alias races (39 / 49) share a mask bit with another race but do not inherit its racials.</code> | 说明注释：RACENEXT3A: alias races (39 / 49) share a mask bit with another race but do not inherit its racials.；它不执行，实际条件仍以相邻代码为准。 |
| 121 | <code>    if (IsRaceMaskAlias(player-&gt;getRace()))</code> | 条件分支：只有`if (IsRaceMaskAlias(player->getRace()))`成立才走随后分支；不满足进入else/跳过。 |
| 122 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 123 | <code>        if (!ability-&gt;RaceMask)</code> | 条件分支：只有`if (!ability->RaceMask)`成立才走随后分支；不满足进入else/跳过。 |
| 124 | <code>            return true;</code> | 返回检查通过，调用者才可继续该资格路径。 |
| 125 | <code>        return (ability-&gt;RaceMask &amp; (ability-&gt;RaceMask - 1)) &amp;&amp; (ability-&gt;RaceMask &amp; player-&gt;getRaceMask());</code> | 检查这条法术资格至少包含两位，并且含玩家共享位；避免继承单族特长。 |
| 126 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 127 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 128 | <code>    if (!ability-&gt;RaceMask &#124;&#124; (ability-&gt;RaceMask &amp; player-&gt;getRaceMask()))</code> | 条件分支：只有`if (!ability->RaceMask ／／ (ability->RaceMask & player->getRaceMask()))`成立才走随后分支；不满足进入else/跳过。 |
| 129 | <code>        return true;</code> | 返回检查通过，调用者才可继续该资格路径。 |
| 12284 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 12285 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 12286 | <code>    // RACENEXT3A: 39 learns the human warrior base skills, 49 the orc ones. GetSkillRaceClassInfo rejects</code> | 说明注释：RACENEXT3A: 39 learns the human warrior base skills, 49 the orc ones. GetSkillRaceClassInfo rejects；它不执行，实际条件仍以相邻代码为准。 |
| 12287 | <code>    // single-race rows for alias races, so racials are never inherited; plus the faction language and its spell.</code> | 说明注释：single-race rows for alias races, so racials are never inherited; plus the faction language and its spell.；它不执行，实际条件仍以相邻代码为准。 |
| 12288 | <code>    // This runs from Player::Create BEFORE the starting outfit is distributed, so weapons/armour can be equipped.</code> | 说明注释：This runs from Player::Create BEFORE the starting outfit is distributed, so weapons/armour can be equipped.；它不执行，实际条件仍以相邻代码为准。 |
| 12289 | <code>    if (uint8 templateRace = GetRaceAliasTemplateRace(getRace()))</code> | 条件分支：只有`if (uint8 templateRace = GetRaceAliasTemplateRace(getRace()))`成立才走随后分支；不满足进入else/跳过。 |
| 12290 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 12291 | <code>        // RACEJOINT1A: copy only existing parent Warrior starter skills.</code> | 说明注释：RACEJOINT1A: copy only existing parent Warrior starter skills.；它不执行，实际条件仍以相邻代码为准。 |
| 12292 | <code>        // Never copy parent language/racial/profession lines through the shared mask.</code> | 说明注释：Never copy parent language/racial/profession lines through the shared mask.；它不执行，实际条件仍以相邻代码为准。 |
| 12293 | <code>        if (getClass() == CLASS_WARRIOR)</code> | 条件分支：只有`if (getClass() == CLASS_WARRIOR)`成立才走随后分支；不满足进入else/跳过。 |
| 12294 | <code>            if (PlayerInfo const* templateInfo = sObjectMgr-&gt;GetPlayerInfo(templateRace, getClass()))</code> | 条件分支：只有`if (PlayerInfo const* templateInfo = sObjectMgr->GetPlayerInfo(templateRace, getClass()))`成立才走随后分支；不满足进入else/跳过。 |
| 12295 | <code>                for (auto const&amp; skill : templateInfo-&gt;skills)</code> | 循环：for (auto const& skill : templateInfo->skills)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 12296 | <code>                {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 12297 | <code>                    bool basic = false;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`bool basic = false;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12298 | <code>                    switch (skill.SkillId)</code> | 此行属于“bool IsSkillLineAbilityRaceAllowedForPlayer(Player const* player, SkillLineAbilityEntry const* ability)”：`switch (skill.SkillId)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 12299 | <code>                    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 12300 | <code>                        case 26: case 256: case 257: case 95: case 162:</code> | 枚举当前允许的技能/种族分支：case 26: case 256: case 257: case 95: case 162:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 12301 | <code>                        case 43: case 44: case 54: case 55: case 160:</code> | 枚举当前允许的技能/种族分支：case 43: case 44: case 54: case 55: case 160:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 12302 | <code>                        case 172: case 173: case 176:</code> | 枚举当前允许的技能/种族分支：case 172: case 173: case 176:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 12303 | <code>                        case 413: case 414: case 415: case 433:</code> | 枚举当前允许的技能/种族分支：case 413: case 414: case 415: case 433:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 12304 | <code>                            basic = true;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`basic = true;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12305 | <code>                            break;</code> | 退出当前switch/循环，不会继续落到下一个case。 |
| 12306 | <code>                        default:</code> | 未列入白名单的编号走默认分支，不授予额外资格。 |
| 12307 | <code>                            break;</code> | 退出当前switch/循环，不会继续落到下一个case。 |
| 12308 | <code>                    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 12309 | <code>                    if (basic &amp;&amp; !HasSkill(skill.SkillId))</code> | 只有基础白名单且尚未学会时才授予，保护已有熟练度。 |
| 12310 | <code>                        LearnDefaultSkill(skill.SkillId, skill.Rank);</code> | 调用LearnDefaultSkill（沿核心默认技能学习路径授予模板已有基础技能，不强制练满）；此行参数来自当前上下文。 |
| 12311 | <code>                }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 12312 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 12313 | <code>        uint32 languageSkill = (templateRace == RACE_ORC) ? SKILL_LANG_ORCISH : SKILL_LANG_COMMON;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint32 languageSkill = (templateRace == RACE_ORC) ? SKILL_LANG_ORCISH : SKILL_LANG_COMMON;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12314 | <code>        if (!HasSkill(languageSkill))</code> | 条件分支：只有`if (!HasSkill(languageSkill))`成立才走随后分支；不满足进入else/跳过。 |
| 12315 | <code>            SetSkill(languageSkill, 0, 300, 300);</code> | 调用SetSkill（设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器）；此行参数来自当前上下文。 |
| 12316 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 12317 | <code>        uint32 languageSpell = (templateRace == RACE_ORC) ? 669 : 668;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint32 languageSpell = (templateRace == RACE_ORC) ? 669 : 668;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12318 | <code>        if (!HasSpell(languageSpell))</code> | 条件分支：只有`if (!HasSpell(languageSpell))`成立才走随后分支；不满足进入else/跳过。 |
| 12319 | <code>        {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 12320 | <code>            if (!IsInWorld())</code> | 新建阶段尚未入世界，后面用addSpell；已入世界走learnSpell通知路径。 |
| 12321 | <code>                addSpell(languageSpell, SPEC_MASK_ALL, true);</code> | 创建阶段注册语言法术到全部天赋组，SPEC_MASK_ALL不是种族掩码。 |
| 12322 | <code>            else</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 12323 | <code>                learnSpell(languageSpell);</code> | 此行属于“bool IsSkillLineAbilityRaceAllowedForPlayer(Player const* player, SkillLineAbilityEntry const* ability)”：`learnSpell(languageSpell);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 12324 | <code>        }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 12325 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 12326 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 12327 | <code>    if (getRace() == RACE_DRACTHYR)</code> | 条件分支：只有`if (getRace() == RACE_DRACTHYR)`成立才走随后分支；不满足进入else/跳过。 |
| 12328 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
