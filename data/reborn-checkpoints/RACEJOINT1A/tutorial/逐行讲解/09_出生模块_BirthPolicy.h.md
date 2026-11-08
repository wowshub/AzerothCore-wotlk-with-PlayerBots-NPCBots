# 出生模块_BirthPolicy.h：逐行讲解
新模块全文件逐行。Profile定义契约，Synchronize只补缺，CMake注册模块和配置；不是通过登录重复发装备。
来源：`A_服务端_Codex/交付/01_覆盖到源代码根目录/modules/mod-reborn-coa-birth/src/BirthPolicy.h`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `FindProfile` | 查39/49战士的固定语言/阵营契约，找不到返回空 |
| `IsBasicSkill` | 基础技能白名单；还要同时满足模板出生资料已有，不能只凭列表赠送 |

## 原代码
```cpp
#ifndef REBORN_COA_BIRTH_POLICY_H
#define REBORN_COA_BIRTH_POLICY_H

#include <cstdint>

namespace RebornCoaBirth
{
struct Profile
{
    std::uint8_t Race;
    std::uint8_t TemplateRace;
    std::uint8_t Alliance;
    std::uint32_t AliasMask;
    std::uint32_t LanguageSkill;
    std::uint32_t LanguageSpell;
};

inline constexpr Profile Profiles[] =
{
    {39, 1, 0, 64,    98,  668}, // Kul Tiran: Common; never Gnomish.
    {49, 2, 1, 65536, 109, 669}  // Mag'har: Orcish; never Draenei.
};

inline constexpr Profile const* FindProfile(std::uint8_t race, std::uint8_t playerClass)
{
    if (playerClass != 1) // First playable batch is Warrior only.
        return nullptr;
    for (Profile const& profile : Profiles)
        if (profile.Race == race)
            return &profile;
    return nullptr;
}

// Only existing parent-Warrior starting entries from this bounded list may be
// repaired. No racial, profession, riding, dual wield or advanced armor grant.
inline constexpr bool IsBasicSkill(std::uint32_t skill)
{
    switch (skill)
    {
        case 26: case 256: case 257: // Warrior skill-book sections.
        case 95: case 162:           // Defense, unarmed.
        case 43: case 44: case 54: case 55: case 160:
        case 172: case 173: case 176: // Parent's existing starting weapons only.
        case 413: case 414: case 415: case 433: // Mail, leather, cloth, shield.
            return true;
        default:
            return false;
    }
}
}
#endif
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>#ifndef REBORN_COA_BIRTH_POLICY_H</code> | 头文件防重复包含：只有此标记未定义才读下面声明。 |
| 2 | <code>#define REBORN_COA_BIRTH_POLICY_H</code> | 设置防重复标记，避免同一头文件被间接引入两次。 |
| 3 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 4 | <code>#include &lt;cstdint&gt;</code> | 引入<cstdint>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 5 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 6 | <code>namespace RebornCoaBirth</code> | 声明代码组织/数据类型：namespace RebornCoaBirth；把同类规则或测试替身成员放一起。 |
| 7 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 8 | <code>struct Profile</code> | 声明代码组织/数据类型：struct Profile；把同类规则或测试替身成员放一起。 |
| 9 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 10 | <code>    std::uint8_t Race;</code> | Profile字段Race：真实种族ID；uint8_t范围0–255，只存编号，不是掩码。 |
| 11 | <code>    std::uint8_t TemplateRace;</code> | Profile字段TemplateRace：基础战士技能/声望模板ID，39用1、49用2；并非实际种族替换。 |
| 12 | <code>    std::uint8_t Alliance;</code> | Profile字段Alliance：本DBC契约联盟0、部落1；用于前置阵营核对。 |
| 13 | <code>    std::uint32_t AliasMask;</code> | Profile字段AliasMask：32位共享资格位，39为64、49为65536；不是种族ID。 |
| 14 | <code>    std::uint32_t LanguageSkill;</code> | Profile字段LanguageSkill：语言技能号，98通用语/109兽人语。 |
| 15 | <code>    std::uint32_t LanguageSpell;</code> | Profile字段LanguageSpell：对应可学习语言法术号，668/669；与技能ID不同。 |
| 16 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 17 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 18 | <code>inline constexpr Profile Profiles[] =</code> | 编译期固定的Profile数组，下面每行按六个字段顺序列出两族契约，不从显示名猜身份。 |
| 19 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 20 | <code>    {39, 1, 0, 64,    98,  668}, // Kul Tiran: Common; never Gnomish.</code> | 库人契约：race39、模板1、联盟0、共享掩码64、语言98、法术668。 |
| 21 | <code>    {49, 2, 1, 65536, 109, 669}  // Mag'har: Orcish; never Draenei.</code> | 玛格汉契约：race49、模板2、部落1、共享掩码65536、语言109、法术669。 |
| 22 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 23 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 24 | <code>inline constexpr Profile const* FindProfile(std::uint8_t race, std::uint8_t playerClass)</code> | 定义/进入函数：查39/49战士的固定语言/阵营契约，找不到返回空。 |
| 25 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 26 | <code>    if (playerClass != 1) // First playable batch is Warrior only.</code> | 职业不等于战士ID1就返回空；当前仅支持两族战士，不能借修复模块给其它职业开资格。 |
| 27 | <code>        return nullptr;</code> | 返回失败/空结果，结束当前函数；不会继续后面的学习或写入。 |
| 28 | <code>    for (Profile const&amp; profile : Profiles)</code> | 循环：for (Profile const& profile : Profiles)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 29 | <code>        if (profile.Race == race)</code> | 逐条比较Profile真实种族ID和请求ID，找到才返回该规则地址。 |
| 30 | <code>            return &amp;profile;</code> | 返回已匹配的常量规则地址；&是取地址，const指针让调用者不改固定契约。 |
| 31 | <code>    return nullptr;</code> | 返回失败/空结果，结束当前函数；不会继续后面的学习或写入。 |
| 32 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 33 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 34 | <code>// Only existing parent-Warrior starting entries from this bounded list may be</code> | 说明注释：Only existing parent-Warrior starting entries from this bounded list may be；它不执行，实际条件仍以相邻代码为准。 |
| 35 | <code>// repaired. No racial, profession, riding, dual wield or advanced armor grant.</code> | 说明注释：repaired. No racial, profession, riding, dual wield or advanced armor grant.；它不执行，实际条件仍以相邻代码为准。 |
| 36 | <code>inline constexpr bool IsBasicSkill(std::uint32_t skill)</code> | 定义/进入函数：基础技能白名单；还要同时满足模板出生资料已有，不能只凭列表赠送。 |
| 37 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 38 | <code>    switch (skill)</code> | 按技能ID选择case分支；白名单中任意case都落到true，未列出的default返回false。 |
| 39 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 40 | <code>        case 26: case 256: case 257: // Warrior skill-book sections.</code> | 枚举当前允许的技能/种族分支：case 26: case 256: case 257: // Warrior skill-book sections.；这些编号的含义见核心参数表，仍需模板行存在。 |
| 41 | <code>        case 95: case 162:           // Defense, unarmed.</code> | 枚举当前允许的技能/种族分支：case 95: case 162:           // Defense, unarmed.；这些编号的含义见核心参数表，仍需模板行存在。 |
| 42 | <code>        case 43: case 44: case 54: case 55: case 160:</code> | 枚举当前允许的技能/种族分支：case 43: case 44: case 54: case 55: case 160:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 43 | <code>        case 172: case 173: case 176: // Parent's existing starting weapons only.</code> | 枚举当前允许的技能/种族分支：case 172: case 173: case 176: // Parent's existing starting weapons only.；这些编号的含义见核心参数表，仍需模板行存在。 |
| 44 | <code>        case 413: case 414: case 415: case 433: // Mail, leather, cloth, shield.</code> | 枚举当前允许的技能/种族分支：case 413: case 414: case 415: case 433: // Mail, leather, cloth, shield.；这些编号的含义见核心参数表，仍需模板行存在。 |
| 45 | <code>            return true;</code> | 返回检查通过，调用者才可继续该资格路径。 |
| 46 | <code>        default:</code> | 未列入白名单的编号走默认分支，不授予额外资格。 |
| 47 | <code>            return false;</code> | 返回失败/空结果，结束当前函数；不会继续后面的学习或写入。 |
| 48 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 49 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 50 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 51 | <code>#endif</code> | 结束这个头文件的条件包含范围。 |
