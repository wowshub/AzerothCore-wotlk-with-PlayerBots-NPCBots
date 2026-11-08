# 出生模块_RebornCoaBirth.cpp：逐行讲解
新模块全文件逐行。Profile定义契约，Synchronize只补缺，CMake注册模块和配置；不是通过登录重复发装备。
来源：`A_服务端_Codex/交付/01_覆盖到源代码根目录/modules/mod-reborn-coa-birth/src/RebornCoaBirth.cpp`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `GetReputationRaceMaskForRace` | 给默认声望找同阵营模板位，不改变角色真实race |
| `GetSkillRaceClassInfo` | 按技能、真实种族、职业筛首条资格行；单族行对别名族不继承 |
| `FindProfile` | 查39/49战士的固定语言/阵营契约，找不到返回空 |
| `IsBasicSkill` | 基础技能白名单；还要同时满足模板出生资料已有，不能只凭列表赠送 |
| `CheckPrerequisites` | 先查全部核心/DBC/出生/语言依赖，返回空表示依赖完整 |
| `Synchronize` | 只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望 |
| `OnPlayerCreate` | 服务器建角回调，此时物品已分配，所以它不能解决创建前穿装资格 |
| `OnPlayerLogin` | 角色登录回调，调用同一补缺函数，避免新旧角色两种实现 |
| `AddRebornCoaBirthScripts` | 向模块加载器注册PlayerScript，同时报告配置开关 |
| `HasSkill` | 检查已有技能，防止覆盖练过的熟练度 |
| `HasSpell` | 检查已学法术，保证重复登录不会重复授予 |
| `SetSkill` | 设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器 |
| `LearnDefaultSkill` | 沿核心默认技能学习路径授予模板已有基础技能，不强制练满 |

## 原代码
```cpp
// RACENEXT2A: explicit birth-language and missing basic-skill repair for 39/49.
// This module does not open creation, initialize reputation, or award items.
#include "ScriptMgr.h"
#include "Player.h"
#include "RaceMgr.h"
#include "ObjectMgr.h"
#include "DBCStores.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "Config.h"
#include "Log.h"
#include "BirthPolicy.h"
#include <algorithm>
#include <vector>

namespace
{
using namespace RebornCoaBirth;

char const* CheckPrerequisites(Profile const& profile)
{
    ChrRacesEntry const* race = sChrRacesStore.LookupEntry(profile.Race);
    if (!race || (race->Flags & CHRRACES_FLAGS_NOT_PLAYABLE) || race->alliance != profile.Alliance)
        return "missing/playability/faction ChrRaces contract";
    if (sRaceMgr->GetMaxRaces() <= profile.Race)
        return "runtime race capacity not ready";
    if (GetRaceMaskForRace(profile.Race) != profile.AliasMask)
        return "coordinated race-mask contract not ready";
    if (GetReputationRaceMaskForRace(profile.Race) != GetRaceMaskForRace(profile.TemplateRace))
        return "explicit reputation template not ready";
    if (!sObjectMgr->GetPlayerInfo(profile.Race, CLASS_WARRIOR) ||
        !sObjectMgr->GetPlayerInfo(profile.TemplateRace, CLASS_WARRIOR))
        return "missing Warrior birth information";
    if (!GetSkillRaceClassInfo(profile.LanguageSkill, profile.Race, CLASS_WARRIOR) ||
        !sSpellMgr->GetSpellInfo(profile.LanguageSpell))
        return "missing explicit language skill/spell data";
    auto bounds = sSpellMgr->GetSkillLineAbilityMapBounds(profile.LanguageSpell);
    for (auto i = bounds.first; i != bounds.second; ++i)
        if (i->second->SkillLine == profile.LanguageSkill)
            return nullptr;
    return "language spell is not linked to its language skill";
}

void Synchronize(Player* player)
{
    if (!player)
        return;
    Profile const* profile = FindProfile(player->getRace(true), player->getClass());
    if (!profile || !sConfigMgr->GetOption<bool>("RebornCoaBirth.Enable", false))
        return;

    if (char const* problem = CheckPrerequisites(*profile))
    {
        LOG_ERROR("module", "RACENEXT2A: race {} skipped: {}", uint32(profile->Race), problem);
        return;
    }
    if (!player->IsSpellFitByClassAndRace(profile->LanguageSpell))
    {
        LOG_ERROR("module", "RACENEXT2A: race {} explicit language eligibility missing", uint32(profile->Race));
        return;
    }

    PlayerInfo const* parent = sObjectMgr->GetPlayerInfo(profile->TemplateRace, CLASS_WARRIOR);
    std::vector<uint32> missing;
    for (PlayerCreateInfoSkill const& entry : parent->skills)
    {
        if (entry.Rank != 0 || !IsBasicSkill(entry.SkillId) || player->HasSkill(entry.SkillId) ||
            std::find(missing.begin(), missing.end(), entry.SkillId) != missing.end())
            continue;
        // Preflight all missing skills BEFORE the first grant. Skill reward
        // eligibility must be integrated in the core, not forced by this module.
        if (!GetSkillRaceClassInfo(entry.SkillId, profile->Race, CLASS_WARRIOR))
        {
            LOG_ERROR("module", "RACENEXT2A: race {} basic skill {} eligibility missing; no repair",
                uint32(profile->Race), uint32(entry.SkillId));
            return;
        }
        missing.push_back(entry.SkillId);
    }

    if (!player->HasSpell(profile->LanguageSpell))
        player->learnSpell(profile->LanguageSpell);
    if (!player->HasSpell(profile->LanguageSpell))
    {
        LOG_ERROR("module", "RACENEXT2A: race {} language learn failed; basic skills skipped", uint32(profile->Race));
        return;
    }
    if (!player->HasSkill(profile->LanguageSkill))
        player->SetSkill(profile->LanguageSkill, 0, 300, 300);
    // Existing values, progression and skills are never reset or maxed here.
    for (uint32 skill : missing)
        if (!player->HasSkill(skill))
            player->LearnDefaultSkill(skill, 0);
}

class RebornCoaBirthPlayerScript final : public PlayerScript
{
public:
    RebornCoaBirthPlayerScript() : PlayerScript("RebornCoaBirthPlayerScript",
        {PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerCreate(Player* player) override { Synchronize(player); }
    void OnPlayerLogin(Player* player) override { Synchronize(player); }
};
}

void AddRebornCoaBirthScripts()
{
    new RebornCoaBirthPlayerScript();
    LOG_INFO("module", "RACENEXT2A: birth repair registered for race39/49 Warrior; enabled={}",
        sConfigMgr->GetOption<bool>("RebornCoaBirth.Enable", false));
}
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>// RACENEXT2A: explicit birth-language and missing basic-skill repair for 39/49.</code> | 说明注释：RACENEXT2A: explicit birth-language and missing basic-skill repair for 39/49.；它不执行，实际条件仍以相邻代码为准。 |
| 2 | <code>// This module does not open creation, initialize reputation, or award items.</code> | 说明注释：This module does not open creation, initialize reputation, or award items.；它不执行，实际条件仍以相邻代码为准。 |
| 3 | <code>#include "ScriptMgr.h"</code> | 引入"ScriptMgr.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 4 | <code>#include "Player.h"</code> | 引入"Player.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 5 | <code>#include "RaceMgr.h"</code> | 引入"RaceMgr.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 6 | <code>#include "ObjectMgr.h"</code> | 引入"ObjectMgr.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 7 | <code>#include "DBCStores.h"</code> | 引入"DBCStores.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 8 | <code>#include "SpellMgr.h"</code> | 引入"SpellMgr.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 9 | <code>#include "SpellInfo.h"</code> | 引入"SpellInfo.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 10 | <code>#include "Config.h"</code> | 引入"Config.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 11 | <code>#include "Log.h"</code> | 引入"Log.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 12 | <code>#include "BirthPolicy.h"</code> | 引入"BirthPolicy.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 13 | <code>#include &lt;algorithm&gt;</code> | 引入<algorithm>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 14 | <code>#include &lt;vector&gt;</code> | 引入<vector>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 15 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 16 | <code>namespace</code> | 声明代码组织/数据类型：namespace；把同类规则或测试替身成员放一起。 |
| 17 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 18 | <code>using namespace RebornCoaBirth;</code> | 给类型/命名空间取本地简写，后面的uint8/uint32仍保持明确位宽。 |
| 19 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 20 | <code>char const* CheckPrerequisites(Profile const&amp; profile)</code> | 调用CheckPrerequisites（先查全部核心/DBC/出生/语言依赖，返回空表示依赖完整）；此行参数来自当前上下文。 |
| 21 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 22 | <code>    ChrRacesEntry const* race = sChrRacesStore.LookupEntry(profile.Race);</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`ChrRacesEntry const* race = sChrRacesStore.LookupEntry(profile.Race);`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 23 | <code>    if (!race &#124;&#124; (race-&gt;Flags &amp; CHRRACES_FLAGS_NOT_PLAYABLE) &#124;&#124; race-&gt;alliance != profile.Alliance)</code> | 条件分支：只有`if (!race ／／ (race->Flags & CHRRACES_FLAGS_NOT_PLAYABLE) ／／ race->alliance != profile.Alliance)`成立才走随后分支；不满足进入else/跳过。 |
| 24 | <code>        return "missing/playability/faction ChrRaces contract";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 25 | <code>    if (sRaceMgr-&gt;GetMaxRaces() &lt;= profile.Race)</code> | 条件分支：只有`if (sRaceMgr->GetMaxRaces() <= profile.Race)`成立才走随后分支；不满足进入else/跳过。 |
| 26 | <code>        return "runtime race capacity not ready";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 27 | <code>    if (GetRaceMaskForRace(profile.Race) != profile.AliasMask)</code> | 条件分支：只有`if (GetRaceMaskForRace(profile.Race) != profile.AliasMask)`成立才走随后分支；不满足进入else/跳过。 |
| 28 | <code>        return "coordinated race-mask contract not ready";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 29 | <code>    if (GetReputationRaceMaskForRace(profile.Race) != GetRaceMaskForRace(profile.TemplateRace))</code> | 条件分支：只有`if (GetReputationRaceMaskForRace(profile.Race) != GetRaceMaskForRace(profile.TemplateRace))`成立才走随后分支；不满足进入else/跳过。 |
| 30 | <code>        return "explicit reputation template not ready";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 31 | <code>    if (!sObjectMgr-&gt;GetPlayerInfo(profile.Race, CLASS_WARRIOR) &#124;&#124;</code> | 条件分支：只有`if (!sObjectMgr->GetPlayerInfo(profile.Race, CLASS_WARRIOR) ／／`成立才走随后分支；不满足进入else/跳过。 |
| 32 | <code>        !sObjectMgr-&gt;GetPlayerInfo(profile.TemplateRace, CLASS_WARRIOR))</code> | 此行属于“出生模块_RebornCoaBirth.cpp”：`!sObjectMgr->GetPlayerInfo(profile.TemplateRace, CLASS_WARRIOR))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 33 | <code>        return "missing Warrior birth information";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 34 | <code>    if (!GetSkillRaceClassInfo(profile.LanguageSkill, profile.Race, CLASS_WARRIOR) &#124;&#124;</code> | 条件分支：只有`if (!GetSkillRaceClassInfo(profile.LanguageSkill, profile.Race, CLASS_WARRIOR) ／／`成立才走随后分支；不满足进入else/跳过。 |
| 35 | <code>        !sSpellMgr-&gt;GetSpellInfo(profile.LanguageSpell))</code> | 此行属于“出生模块_RebornCoaBirth.cpp”：`!sSpellMgr->GetSpellInfo(profile.LanguageSpell))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 36 | <code>        return "missing explicit language skill/spell data";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 37 | <code>    auto bounds = sSpellMgr-&gt;GetSkillLineAbilityMapBounds(profile.LanguageSpell);</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`auto bounds = sSpellMgr->GetSkillLineAbilityMapBounds(profile.LanguageSpell);`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 38 | <code>    for (auto i = bounds.first; i != bounds.second; ++i)</code> | 循环：for (auto i = bounds.first; i != bounds.second; ++i)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 39 | <code>        if (i-&gt;second-&gt;SkillLine == profile.LanguageSkill)</code> | 条件分支：只有`if (i->second->SkillLine == profile.LanguageSkill)`成立才走随后分支；不满足进入else/跳过。 |
| 40 | <code>            return nullptr;</code> | 返回失败/空结果，结束当前函数；不会继续后面的学习或写入。 |
| 41 | <code>    return "language spell is not linked to its language skill";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 42 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 43 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 44 | <code>void Synchronize(Player* player)</code> | 定义/进入函数：只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望。 |
| 45 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 46 | <code>    if (!player)</code> | 条件分支：只有`if (!player)`成立才走随后分支；不满足进入else/跳过。 |
| 47 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 48 | <code>    Profile const* profile = FindProfile(player-&gt;getRace(true), player-&gt;getClass());</code> | 按真实种族查规则；变身显示race不应改变语言/出生修复对象。 |
| 49 | <code>    if (!profile &#124;&#124; !sConfigMgr-&gt;GetOption&lt;bool&gt;("RebornCoaBirth.Enable", false))</code> | 读显式功能开关，缺配置默认关闭；放了conf还要CMake注册加载。 |
| 50 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 51 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 52 | <code>    if (char const* problem = CheckPrerequisites(*profile))</code> | 条件分支：只有`if (char const* problem = CheckPrerequisites(*profile))`成立才走随后分支；不满足进入else/跳过。 |
| 53 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 54 | <code>        LOG_ERROR("module", "RACENEXT2A: race {} skipped: {}", uint32(profile-&gt;Race), problem);</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} skipped: {}", uint32(profile->Race), problem);；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 55 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 56 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 57 | <code>    if (!player-&gt;IsSpellFitByClassAndRace(profile-&gt;LanguageSpell))</code> | 语言法术必须符合真实职业/种族资格，不由模块强行绕过核心。 |
| 58 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 59 | <code>        LOG_ERROR("module", "RACENEXT2A: race {} explicit language eligibility missing", uint32(profile-&gt;Race));</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} explicit language eligibility missing", uint32(profile->Race));；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 60 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 61 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 62 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 63 | <code>    PlayerInfo const* parent = sObjectMgr-&gt;GetPlayerInfo(profile-&gt;TemplateRace, CLASS_WARRIOR);</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`PlayerInfo const* parent = sObjectMgr->GetPlayerInfo(profile->TemplateRace, CLASS_WARRIOR);`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 64 | <code>    std::vector&lt;uint32&gt; missing;</code> | 此行属于“void Synchronize(Player* player)”：`std::vector<uint32> missing;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 65 | <code>    for (PlayerCreateInfoSkill const&amp; entry : parent-&gt;skills)</code> | 循环：for (PlayerCreateInfoSkill const& entry : parent->skills)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 66 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 67 | <code>        if (entry.Rank != 0 &#124;&#124; !IsBasicSkill(entry.SkillId) &#124;&#124; player-&gt;HasSkill(entry.SkillId) &#124;&#124;</code> | 登录修复只处理模板初始Rank0；不越权教高级技能或降级已有熟练度。 |
| 68 | <code>            std::find(missing.begin(), missing.end(), entry.SkillId) != missing.end())</code> | 查待补列表是否已有此技能，排除模板重复行导致的重复学习。 |
| 69 | <code>            continue;</code> | 跳过当前不合格记录，进入下一条；不授予这条技能/种族。 |
| 70 | <code>        // Preflight all missing skills BEFORE the first grant. Skill reward</code> | 说明注释：Preflight all missing skills BEFORE the first grant. Skill reward；它不执行，实际条件仍以相邻代码为准。 |
| 71 | <code>        // eligibility must be integrated in the core, not forced by this module.</code> | 说明注释：eligibility must be integrated in the core, not forced by this module.；它不执行，实际条件仍以相邻代码为准。 |
| 72 | <code>        if (!GetSkillRaceClassInfo(entry.SkillId, profile-&gt;Race, CLASS_WARRIOR))</code> | 条件分支：只有`if (!GetSkillRaceClassInfo(entry.SkillId, profile->Race, CLASS_WARRIOR))`成立才走随后分支；不满足进入else/跳过。 |
| 73 | <code>        {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 74 | <code>            LOG_ERROR("module", "RACENEXT2A: race {} basic skill {} eligibility missing; no repair",</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} basic skill {} eligibility missing; no repair",；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 75 | <code>                uint32(profile-&gt;Race), uint32(entry.SkillId));</code> | 此行属于“void Synchronize(Player* player)”：`uint32(profile->Race), uint32(entry.SkillId));`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 76 | <code>            return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 77 | <code>        }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 78 | <code>        missing.push_back(entry.SkillId);</code> | 只收集缺失技能，先完成所有资格检查，后面才统一授予。 |
| 79 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 80 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 81 | <code>    if (!player-&gt;HasSpell(profile-&gt;LanguageSpell))</code> | 条件分支：只有`if (!player->HasSpell(profile->LanguageSpell))`成立才走随后分支；不满足进入else/跳过。 |
| 82 | <code>        player-&gt;learnSpell(profile-&gt;LanguageSpell);</code> | 此行属于“void Synchronize(Player* player)”：`player->learnSpell(profile->LanguageSpell);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 83 | <code>    if (!player-&gt;HasSpell(profile-&gt;LanguageSpell))</code> | 条件分支：只有`if (!player->HasSpell(profile->LanguageSpell))`成立才走随后分支；不满足进入else/跳过。 |
| 84 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 85 | <code>        LOG_ERROR("module", "RACENEXT2A: race {} language learn failed; basic skills skipped", uint32(profile-&gt;Race));</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} language learn failed; basic skills skipped", uint32(profile->Race));；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 86 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 87 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 88 | <code>    if (!player-&gt;HasSkill(profile-&gt;LanguageSkill))</code> | 条件分支：只有`if (!player->HasSkill(profile->LanguageSkill))`成立才走随后分支；不满足进入else/跳过。 |
| 89 | <code>        player-&gt;SetSkill(profile-&gt;LanguageSkill, 0, 300, 300);</code> | 调用SetSkill（设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器）；此行参数来自当前上下文。 |
| 90 | <code>    // Existing values, progression and skills are never reset or maxed here.</code> | 说明注释：Existing values, progression and skills are never reset or maxed here.；它不执行，实际条件仍以相邻代码为准。 |
| 91 | <code>    for (uint32 skill : missing)</code> | 循环：for (uint32 skill : missing)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 92 | <code>        if (!player-&gt;HasSkill(skill))</code> | 条件分支：只有`if (!player->HasSkill(skill))`成立才走随后分支；不满足进入else/跳过。 |
| 93 | <code>            player-&gt;LearnDefaultSkill(skill, 0);</code> | 调用LearnDefaultSkill（沿核心默认技能学习路径授予模板已有基础技能，不强制练满）；此行参数来自当前上下文。 |
| 94 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 95 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 96 | <code>class RebornCoaBirthPlayerScript final : public PlayerScript</code> | 声明代码组织/数据类型：class RebornCoaBirthPlayerScript final : public PlayerScript；把同类规则或测试替身成员放一起。 |
| 97 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 98 | <code>public:</code> | C++访问权限分界：下面成员按此权限提供给调用者。 |
| 99 | <code>    RebornCoaBirthPlayerScript() : PlayerScript("RebornCoaBirthPlayerScript",</code> | 此行属于“void Synchronize(Player* player)”：`RebornCoaBirthPlayerScript() : PlayerScript("RebornCoaBirthPlayerScript",`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 100 | <code>        {PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LOGIN}) { }</code> | 订阅创建和登录回调，两者共用补缺函数；穿装先后由核心提前处理。 |
| 101 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 102 | <code>    void OnPlayerCreate(Player* player) override { Synchronize(player); }</code> | 定义/进入函数：只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望；服务器建角回调，此时物品已分配，所以它不能解决创建前穿装资格。 |
| 103 | <code>    void OnPlayerLogin(Player* player) override { Synchronize(player); }</code> | 定义/进入函数：只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望；角色登录回调，调用同一补缺函数，避免新旧角色两种实现。 |
| 104 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 105 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 106 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 107 | <code>void AddRebornCoaBirthScripts()</code> | 定义/进入函数：向模块加载器注册PlayerScript，同时报告配置开关。 |
| 108 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 109 | <code>    new RebornCoaBirthPlayerScript();</code> | 此行属于“void AddRebornCoaBirthScripts()”：`new RebornCoaBirthPlayerScript();`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 110 | <code>    LOG_INFO("module", "RACENEXT2A: birth repair registered for race39/49 Warrior; enabled={}",</code> | 输出诊断日志：LOG_INFO("module", "RACENEXT2A: birth repair registered for race39/49 Warrior; enabled={}",；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 111 | <code>        sConfigMgr-&gt;GetOption&lt;bool&gt;("RebornCoaBirth.Enable", false));</code> | 读显式功能开关，缺配置默认关闭；放了conf还要CMake注册加载。 |
| 112 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
