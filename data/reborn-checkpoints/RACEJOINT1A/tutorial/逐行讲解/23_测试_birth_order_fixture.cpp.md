# 测试_birth_order_fixture.cpp：逐行讲解
实际测试原件逐行；Python路径保持当时输入，不保证当前可直接执行。C++夹具是生产函数加API替身，不是完整游戏引擎。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261106\codexwork_RACEJOINT1A\birth_order_fixture.cpp`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `IsRaceMaskAlias` | 判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同 |
| `IsRaceMaskable` | 判断是否允许走32位掩码运算，避免把36/37误卷入 |
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `GetRaceAliasTemplateRace` | 只把39映射到人类1、49映射到兽人2；其它返回0 |
| `HasSkill` | 检查已有技能，防止覆盖练过的熟练度 |
| `HasSpell` | 检查已学法术，保证重复登录不会重复授予 |
| `SetSkill` | 设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器 |
| `LearnDefaultSkill` | 沿核心默认技能学习路径授予模板已有基础技能，不强制练满 |

## 原代码
```cpp

#include <cstdint>
#include <map>
#include <set>
#include <vector>
#include <cassert>
#include <iostream>
using uint8=std::uint8_t;using uint32=std::uint32_t;
enum {RACE_NONE=0,RACE_HUMAN=1,RACE_ORC=2,RACE_KUL_TIRAN=39,RACE_MAGHAR_ORC=49,CLASS_WARRIOR=1,SKILL_LANG_COMMON=98,SKILL_LANG_ORCISH=109};
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
inline constexpr uint8 GetRaceAliasTemplateRace(uint8 race)
{
    return race == RACE_KUL_TIRAN ? uint8(RACE_HUMAN) : race == RACE_MAGHAR_ORC ? uint8(RACE_ORC) : uint8(0);
}
static_assert(GetRaceMaskForRace(36)==0&&GetRaceMaskForRace(37)==0);
static_assert(GetRaceMaskForRace(39)==64&&GetRaceMaskForRace(49)==65536);
struct Skill{uint32 SkillId,Rank;};struct PlayerInfo{std::vector<Skill> skills;};
struct ObjectMgr{std::map<uint8,PlayerInfo> info;PlayerInfo const* GetPlayerInfo(uint8 race,uint8){return &info[race];}} obj,*sObjectMgr=&obj;
enum{SPEC_MASK_ALL=3};int grants=0;
struct Player{
 uint8 race=39,cls=1;bool world=false;std::map<uint32,uint32> skills;std::set<uint32> spells;
 uint8 getRace(){return race;}uint8 getClass(){return cls;}bool HasSkill(uint32 s){return skills.count(s);}bool HasSpell(uint32 s){return spells.count(s);}bool IsInWorld(){return world;}
 void LearnDefaultSkill(uint32 s,uint32){skills[s]=1;++grants;}
 void SetSkill(uint32 s,uint32,uint32 v,uint32){skills[s]=v;++grants;}
 void addSpell(uint32 s,uint32,bool){spells.insert(s);++grants;}void learnSpell(uint32 s){spells.insert(s);++grants;}
 void LearnBeforeItems(){
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
 }
};
int main(){
 for(auto race:{39,49})for(auto world:{false,true}){
  obj.info[1].skills={{26,0},{43,0},{413,0},{98,0},{118,0},{129,1},{183,0},{762,0}};
  obj.info[2].skills={{26,0},{44,0},{413,0},{109,0},{118,0},{129,1},{183,0},{762,0}};
  Player p;p.race=race;p.world=world;p.skills[43]=193;p.skills[129]=375;
  p.LearnBeforeItems();auto lang=race==39?98:109,spell=race==39?668:669;
  assert(p.HasSkill(413)&&p.HasSkill(race==39?43:44));
  assert(p.skills[43]==193&&p.skills[129]==375);
  assert(p.skills[lang]==300&&p.HasSpell(spell));
  assert(!p.HasSkill(race==39?109:98)&&!p.HasSkill(118)&&!p.HasSkill(183)&&!p.HasSkill(762));
  auto old=p.skills;auto spells=p.spells;auto g=grants;
  for(int i=0;i<100;i++)p.LearnBeforeItems();
  assert(p.skills==old&&p.spells==spells&&grants==g);
 }
 for(auto r:{1,2,7,17,36,37}){Player p;p.race=r;auto g=grants;p.LearnBeforeItems();assert(p.skills.empty()&&p.spells.empty()&&grants==g);}
 std::cout<<"PASS actual Player.cpp alias initialization block: 4 race/world combinations, 400 repeated calls, no parent racials or other language, old 36/37 unaffected; mask static_asserts\n";
}
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 2 | <code>#include &lt;cstdint&gt;</code> | 引入<cstdint>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 3 | <code>#include &lt;map&gt;</code> | 引入<map>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 4 | <code>#include &lt;set&gt;</code> | 引入<set>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 5 | <code>#include &lt;vector&gt;</code> | 引入<vector>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 6 | <code>#include &lt;cassert&gt;</code> | 引入<cassert>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 7 | <code>#include &lt;iostream&gt;</code> | 引入<iostream>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 8 | <code>using uint8=std::uint8_t;using uint32=std::uint32_t;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`using uint8=std::uint8_t;using uint32=std::uint32_t;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 9 | <code>enum {RACE_NONE=0,RACE_HUMAN=1,RACE_ORC=2,RACE_KUL_TIRAN=39,RACE_MAGHAR_ORC=49,CLASS_WARRIOR=1,SKILL_LANG_COMMON=98,SKILL_LANG_ORCISH=109};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`enum {RACE_NONE=0,RACE_HUMAN=1,RACE_ORC=2,RACE_KUL_TIRAN=39,RACE_MAGHAR_ORC=49,CLASS_WARRIOR=1,SKILL_LANG_COMMON=98,SKILL_LANG_ORCISH=109};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 10 | <code>inline constexpr bool IsRaceMaskAlias(uint8 race)</code> | 定义/进入函数：判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同。 |
| 11 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 12 | <code>    return race &gt;= 38;</code> | 本批约定高ID别名规则从38起；33–37保持mask0路径。 |
| 13 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 14 | <code>inline constexpr bool IsRaceMaskable(uint8 race)</code> | 定义/进入函数：判断是否允许走32位掩码运算，避免把36/37误卷入。 |
| 15 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 16 | <code>    return race &gt; RACE_NONE &amp;&amp; (race &lt;= 32 &#124;&#124; IsRaceMaskAlias(race));</code> | 返回表达式`race > RACE_NONE && (race <= 32 ／／ IsRaceMaskAlias(race))`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 17 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 18 | <code>inline constexpr uint32 GetRaceMaskForRace(uint8 race)</code> | 定义/进入函数：将真实race映射为旧接口资格位；36/37仍返回0。 |
| 19 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 20 | <code>    return IsRaceMaskable(race) ? (uint32(1) &lt;&lt; ((race - 1) &amp; 31)) : 0;</code> | 先减1转零基位号，再&31限制0–31；39→6、49→16，避免超宽移位。 |
| 21 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 22 | <code>inline constexpr uint8 GetRaceAliasTemplateRace(uint8 race)</code> | 定义/进入函数：只把39映射到人类1、49映射到兽人2；其它返回0。 |
| 23 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 24 | <code>    return race == RACE_KUL_TIRAN ? uint8(RACE_HUMAN) : race == RACE_MAGHAR_ORC ? uint8(RACE_ORC) : uint8(0);</code> | 返回表达式`race == RACE_KUL_TIRAN ? uint8(RACE_HUMAN) : race == RACE_MAGHAR_ORC ? uint8(RACE_ORC) : uint8(0)`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 25 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 26 | <code>static_assert(GetRaceMaskForRace(36)==0&amp;&amp;GetRaceMaskForRace(37)==0);</code> | 编译期断言：掩码常量若被误改，连测试程序都不能编译成功。 |
| 27 | <code>static_assert(GetRaceMaskForRace(39)==64&amp;&amp;GetRaceMaskForRace(49)==65536);</code> | 编译期断言：掩码常量若被误改，连测试程序都不能编译成功。 |
| 28 | <code>struct Skill{uint32 SkillId,Rank;};struct PlayerInfo{std::vector&lt;Skill&gt; skills;};</code> | 声明代码组织/数据类型：struct Skill{uint32 SkillId,Rank;};struct PlayerInfo{std::vector<Skill> skills;};；把同类规则或测试替身成员放一起。 |
| 29 | <code>struct ObjectMgr{std::map&lt;uint8,PlayerInfo&gt; info;PlayerInfo const* GetPlayerInfo(uint8 race,uint8){return &amp;info[race];}} obj,*sObjectMgr=&amp;obj;</code> | 声明代码组织/数据类型：struct ObjectMgr{std::map<uint8,PlayerInfo> info;PlayerInfo const* GetPlayerInfo(uint8 race,uint8){return &info[race];}} obj,*sObjectMgr=&obj;；把同类规则或测试替身成员放一起。 |
| 30 | <code>enum{SPEC_MASK_ALL=3};int grants=0;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`enum{SPEC_MASK_ALL=3};int grants=0;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 31 | <code>struct Player{</code> | 声明代码组织/数据类型：struct Player{；把同类规则或测试替身成员放一起。 |
| 32 | <code> uint8 race=39,cls=1;bool world=false;std::map&lt;uint32,uint32&gt; skills;std::set&lt;uint32&gt; spells;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint8 race=39,cls=1;bool world=false;std::map<uint32,uint32> skills;std::set<uint32> spells;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 33 | <code> uint8 getRace(){return race;}uint8 getClass(){return cls;}bool HasSkill(uint32 s){return skills.count(s);}bool HasSpell(uint32 s){return spells.count(s);}bool IsInWorld(){return world;}</code> | 调用HasSkill（检查已有技能，防止覆盖练过的熟练度）、HasSpell（检查已学法术，保证重复登录不会重复授予）；此行参数来自当前上下文。 |
| 34 | <code> void LearnDefaultSkill(uint32 s,uint32){skills[s]=1;++grants;}</code> | 定义/进入函数：沿核心默认技能学习路径授予模板已有基础技能，不强制练满。 |
| 35 | <code> void SetSkill(uint32 s,uint32,uint32 v,uint32){skills[s]=v;++grants;}</code> | 定义/进入函数：设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器。 |
| 36 | <code> void addSpell(uint32 s,uint32,bool){spells.insert(s);++grants;}void learnSpell(uint32 s){spells.insert(s);++grants;}</code> | 此行属于“void addSpell(uint32 s,uint32,bool)”：`void addSpell(uint32 s,uint32,bool){spells.insert(s);++grants;}void learnSpell(uint32 s){spells.insert(s);++grants;}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 37 | <code> void LearnBeforeItems(){</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 |
| 38 | <code>    if (uint8 templateRace = GetRaceAliasTemplateRace(getRace()))</code> | 条件分支：只有`if (uint8 templateRace = GetRaceAliasTemplateRace(getRace()))`成立才走随后分支；不满足进入else/跳过。 |
| 39 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 40 | <code>        // RACEJOINT1A: copy only existing parent Warrior starter skills.</code> | 说明注释：RACEJOINT1A: copy only existing parent Warrior starter skills.；它不执行，实际条件仍以相邻代码为准。 |
| 41 | <code>        // Never copy parent language/racial/profession lines through the shared mask.</code> | 说明注释：Never copy parent language/racial/profession lines through the shared mask.；它不执行，实际条件仍以相邻代码为准。 |
| 42 | <code>        if (getClass() == CLASS_WARRIOR)</code> | 条件分支：只有`if (getClass() == CLASS_WARRIOR)`成立才走随后分支；不满足进入else/跳过。 |
| 43 | <code>            if (PlayerInfo const* templateInfo = sObjectMgr-&gt;GetPlayerInfo(templateRace, getClass()))</code> | 条件分支：只有`if (PlayerInfo const* templateInfo = sObjectMgr->GetPlayerInfo(templateRace, getClass()))`成立才走随后分支；不满足进入else/跳过。 |
| 44 | <code>                for (auto const&amp; skill : templateInfo-&gt;skills)</code> | 循环：for (auto const& skill : templateInfo->skills)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 45 | <code>                {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 46 | <code>                    bool basic = false;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`bool basic = false;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 47 | <code>                    switch (skill.SkillId)</code> | 此行属于“void LearnBeforeItems()”：`switch (skill.SkillId)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 48 | <code>                    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 49 | <code>                        case 26: case 256: case 257: case 95: case 162:</code> | 枚举当前允许的技能/种族分支：case 26: case 256: case 257: case 95: case 162:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 50 | <code>                        case 43: case 44: case 54: case 55: case 160:</code> | 枚举当前允许的技能/种族分支：case 43: case 44: case 54: case 55: case 160:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 51 | <code>                        case 172: case 173: case 176:</code> | 枚举当前允许的技能/种族分支：case 172: case 173: case 176:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 52 | <code>                        case 413: case 414: case 415: case 433:</code> | 枚举当前允许的技能/种族分支：case 413: case 414: case 415: case 433:；这些编号的含义见核心参数表，仍需模板行存在。 |
| 53 | <code>                            basic = true;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`basic = true;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 54 | <code>                            break;</code> | 退出当前switch/循环，不会继续落到下一个case。 |
| 55 | <code>                        default:</code> | 未列入白名单的编号走默认分支，不授予额外资格。 |
| 56 | <code>                            break;</code> | 退出当前switch/循环，不会继续落到下一个case。 |
| 57 | <code>                    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 58 | <code>                    if (basic &amp;&amp; !HasSkill(skill.SkillId))</code> | 只有基础白名单且尚未学会时才授予，保护已有熟练度。 |
| 59 | <code>                        LearnDefaultSkill(skill.SkillId, skill.Rank);</code> | 调用LearnDefaultSkill（沿核心默认技能学习路径授予模板已有基础技能，不强制练满）；此行参数来自当前上下文。 |
| 60 | <code>                }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 61 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 62 | <code>        uint32 languageSkill = (templateRace == RACE_ORC) ? SKILL_LANG_ORCISH : SKILL_LANG_COMMON;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint32 languageSkill = (templateRace == RACE_ORC) ? SKILL_LANG_ORCISH : SKILL_LANG_COMMON;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 63 | <code>        if (!HasSkill(languageSkill))</code> | 条件分支：只有`if (!HasSkill(languageSkill))`成立才走随后分支；不满足进入else/跳过。 |
| 64 | <code>            SetSkill(languageSkill, 0, 300, 300);</code> | 调用SetSkill（设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器）；此行参数来自当前上下文。 |
| 65 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 66 | <code>        uint32 languageSpell = (templateRace == RACE_ORC) ? 669 : 668;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint32 languageSpell = (templateRace == RACE_ORC) ? 669 : 668;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 67 | <code>        if (!HasSpell(languageSpell))</code> | 条件分支：只有`if (!HasSpell(languageSpell))`成立才走随后分支；不满足进入else/跳过。 |
| 68 | <code>        {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 69 | <code>            if (!IsInWorld())</code> | 新建阶段尚未入世界，后面用addSpell；已入世界走learnSpell通知路径。 |
| 70 | <code>                addSpell(languageSpell, SPEC_MASK_ALL, true);</code> | 创建阶段注册语言法术到全部天赋组，SPEC_MASK_ALL不是种族掩码。 |
| 71 | <code>            else</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 72 | <code>                learnSpell(languageSpell);</code> | 此行属于“void LearnBeforeItems()”：`learnSpell(languageSpell);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 73 | <code>        }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 74 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 75 | <code> }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 76 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 77 | <code>int main(){</code> | 此行属于“void LearnBeforeItems()”：`int main(){`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 78 | <code> for(auto race:{39,49})for(auto world:{false,true}){</code> | 循环：for(auto race:{39,49})for(auto world:{false,true})；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 79 | <code>  obj.info[1].skills={{26,0},{43,0},{413,0},{98,0},{118,0},{129,1},{183,0},{762,0}};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`obj.info[1].skills={{26,0},{43,0},{413,0},{98,0},{118,0},{129,1},{183,0},{762,0}};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 80 | <code>  obj.info[2].skills={{26,0},{44,0},{413,0},{109,0},{118,0},{129,1},{183,0},{762,0}};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`obj.info[2].skills={{26,0},{44,0},{413,0},{109,0},{118,0},{129,1},{183,0},{762,0}};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 81 | <code>  Player p;p.race=race;p.world=world;p.skills[43]=193;p.skills[129]=375;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`Player p;p.race=race;p.world=world;p.skills[43]=193;p.skills[129]=375;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 82 | <code>  p.LearnBeforeItems();auto lang=race==39?98:109,spell=race==39?668:669;</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 |
| 83 | <code>  assert(p.HasSkill(413)&amp;&amp;p.HasSkill(race==39?43:44));</code> | 断言这行写出的条件必须成立：assert(p.HasSkill(413)&&p.HasSkill(race==39?43:44));；否则立刻停测，不能继续记通过。 |
| 84 | <code>  assert(p.skills[43]==193&amp;&amp;p.skills[129]==375);</code> | 预置剑熟练度193和专业375必须保留，不能被初始化重置。 |
| 85 | <code>  assert(p.skills[lang]==300&amp;&amp;p.HasSpell(spell));</code> | 断言这行写出的条件必须成立：assert(p.skills[lang]==300&&p.HasSpell(spell));；否则立刻停测，不能继续记通过。 |
| 86 | <code>  assert(!p.HasSkill(race==39?109:98)&amp;&amp;!p.HasSkill(118)&amp;&amp;!p.HasSkill(183)&amp;&amp;!p.HasSkill(762));</code> | 断言这行写出的条件必须成立：assert(!p.HasSkill(race==39?109:98)&&!p.HasSkill(118)&&!p.HasSkill(183)&&!p.HasSkill(762));；否则立刻停测，不能继续记通过。 |
| 87 | <code>  auto old=p.skills;auto spells=p.spells;auto g=grants;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`auto old=p.skills;auto spells=p.spells;auto g=grants;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 88 | <code>  for(int i=0;i&lt;100;i++)p.LearnBeforeItems();</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 |
| 89 | <code>  assert(p.skills==old&amp;&amp;p.spells==spells&amp;&amp;grants==g);</code> | 重复调用后授予计数不得变化，证明幂等，不是每次登录再发奖励。 |
| 90 | <code> }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 91 | <code> for(auto r:{1,2,7,17,36,37}){Player p;p.race=r;auto g=grants;p.LearnBeforeItems();assert(p.skills.empty()&amp;&amp;p.spells.empty()&amp;&amp;grants==g);}</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 重复调用后授予计数不得变化，证明幂等，不是每次登录再发奖励。 |
| 92 | <code> std::cout&lt;&lt;"PASS actual Player.cpp alias initialization block: 4 race/world combinations, 400 repeated calls, no parent racials or other language, old 36/37 unaffected; mask static_asserts\n";</code> | 编译期断言：掩码常量若被误改，连测试程序都不能编译成功。 |
| 93 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
