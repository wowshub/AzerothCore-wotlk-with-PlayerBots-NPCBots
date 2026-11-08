# 测试_module_fixture.cpp：逐行讲解
实际测试原件逐行；Python路径保持当时输入，不保证当前可直接执行。C++夹具是生产函数加API替身，不是完整游戏引擎。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261106\codexwork_RACEJOINT1A\module_fixture.cpp`。以下行号是所附原件的真实行号；空行/注释也保留。
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
| `clear` | 清空测试状态、确认职业/天赋组，防止上一测试污染下一测试 |
| `Setup` | 准备某种族的最小合法测试依赖，再故意缺某项验证拒绝 |
| `Check` | C++断言计数，失败终止测试 |
| `NoChange` | 验证被拒绝的玩家没有获得任何语言/技能副作用 |
| `HasSkill` | 检查已有技能，防止覆盖练过的熟练度 |
| `HasSpell` | 检查已学法术，保证重复登录不会重复授予 |
| `GetOption` | 读取模块Enable开关，默认false |
| `SetSkill` | 设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器 |
| `LearnDefaultSkill` | 沿核心默认技能学习路径授予模板已有基础技能，不强制练满 |

## 原代码
```cpp

#include <cstdint>
#include <map>
#include <set>
#include <vector>
#include <string>
#include <cassert>
#include <iostream>
#include "BirthPolicy.h"
using uint8=std::uint8_t;using uint16=std::uint16_t;using uint32=std::uint32_t;
constexpr uint8 CLASS_WARRIOR=1;constexpr uint32 CHRRACES_FLAGS_NOT_PLAYABLE=4;
int errors=0,checks=0;
template<class... A> void Error(A...){++errors;}
#define LOG_ERROR(...) Error(__VA_ARGS__)
#define LOG_INFO(...) ((void)0)
struct PlayerCreateInfoSkill {uint16 SkillId;uint16 Rank;};
struct PlayerInfo {std::vector<PlayerCreateInfoSkill> skills;};
struct ChrRacesEntry {uint32 Flags=0;uint8 alliance=0;};
struct Store {std::map<uint32,ChrRacesEntry> rows;ChrRacesEntry const* LookupEntry(uint32 r){auto i=rows.find(r);return i==rows.end()?nullptr:&i->second;}} sChrRacesStore;
uint32 masks[256]={}, reps[256]={};
uint32 GetRaceMaskForRace(uint8 r){return masks[r];}
uint32 GetReputationRaceMaskForRace(uint8 r){return reps[r];}
struct RaceMgr {uint32 max=50;uint32 GetMaxRaces(){return max;}} races,*sRaceMgr=&races;
struct ObjectMgr {std::map<uint32,PlayerInfo> infos;PlayerInfo const* GetPlayerInfo(uint8 r,uint8){assert(r<races.max);auto i=infos.find(r);return i==infos.end()?nullptr:&i->second;}} objects,*sObjectMgr=&objects;
bool cfg=false;struct Config {template<class T>T GetOption(char const*,T){return cfg;}} config,*sConfigMgr=&config;
std::set<std::pair<uint32,uint32>> eligible;
void const* GetSkillRaceClassInfo(uint32 skill,uint8 race,uint8){return eligible.count({race,skill})?&eligible:nullptr;}
struct SpellInfo {} spellInfo;
struct Ability {uint32 SkillLine;};Ability common{98},orcish{109};
struct SpellMgr {std::set<uint32> spells;std::multimap<uint32,Ability*> abilities;SpellInfo const* GetSpellInfo(uint32 spell){return spells.count(spell)?&spellInfo:nullptr;} auto GetSkillLineAbilityMapBounds(uint32 spell){return abilities.equal_range(spell);}} spells,*sSpellMgr=&spells;
struct Player {
 uint8 race=39,displayRace=2,cls=1;bool fit=true,learnFails=false;
 std::set<uint32> known;std::map<uint32,std::pair<uint32,uint32>> skills;
 int learns=0,sets=0,defaults=0;
 uint8 getRace(bool original){return original?race:displayRace;}uint8 getClass(){return cls;}
 bool HasSpell(uint32 s){return known.count(s);}bool HasSkill(uint32 s){return skills.count(s);}
 bool IsSpellFitByClassAndRace(uint32){return fit;}
 void learnSpell(uint32 s){++learns;if(!learnFails)known.insert(s);}
 void SetSkill(uint32 s,uint16,uint16 value,uint16 max){++sets;skills[s]={value,max};}
 void LearnDefaultSkill(uint32 s,uint16 rank){assert(rank==0);++defaults;skills[s]={1,300};}
};
constexpr int PLAYERHOOK_ON_CREATE=1,PLAYERHOOK_ON_LOGIN=2;
struct PlayerScript {PlayerScript(char const*,std::initializer_list<int>){}virtual ~PlayerScript()=default;virtual void OnPlayerCreate(Player*){}virtual void OnPlayerLogin(Player*){}};

// RACENEXT2A: explicit birth-language and missing basic-skill repair for 39/49.
// This module does not open creation, initialize reputation, or award items.
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

void Check(bool ok){assert(ok);++checks;}
void Setup(uint8 race){
 cfg=true;errors=0;races.max=50;objects.infos.clear();sChrRacesStore.rows.clear();eligible.clear();spells.spells={668,669};spells.abilities.clear();
 masks[1]=1;masks[2]=2;masks[39]=64;masks[49]=65536;reps[39]=1;reps[49]=2;
 auto p=RebornCoaBirth::FindProfile(race,1);assert(p);
 sChrRacesStore.rows[race]={0,p->Alliance};objects.infos[race]={};
 objects.infos[p->TemplateRace].skills={{26,0},{256,0},{257,0},{95,0},{162,0},{43,0},{55,0},{413,0},{414,0},{415,0},{433,0},{55,0},{129,4},{762,0},{118,0},{293,0},{98,0},{109,0},{183,0}};
 for(auto const& s:objects.infos[p->TemplateRace].skills)eligible.insert({race,s.SkillId});
 eligible.insert({race,p->LanguageSkill});spells.abilities.emplace(668,&common);spells.abilities.emplace(669,&orcish);
}
void NoChange(Player& p){Check(p.known.empty()&&p.skills.empty()&&!p.learns&&!p.sets&&!p.defaults);}
int main(){
 Synchronize(nullptr);Check(true);
 for(uint8 race:{uint8(39),uint8(49)}){
  auto const* profile=RebornCoaBirth::FindProfile(race,1);uint32 lang=profile->LanguageSkill,spell=profile->LanguageSpell;
  for(int gate=0;gate<13;++gate){Setup(race);Player p;p.race=race;
   switch(gate){case 0:cfg=false;break;case 1:sChrRacesStore.rows.clear();break;case 2:sChrRacesStore.rows[race].Flags=4;break;case 3:sChrRacesStore.rows[race].alliance^=1;break;
    case 4:races.max=race;break;case 5:masks[race]=0;break;case 6:reps[race]=profile->AliasMask;break;case 7:objects.infos.erase(race);break;case 8:objects.infos.erase(profile->TemplateRace);break;
    case 9:eligible.erase({race,lang});break;case 10:spells.spells.erase(spell);break;case 11:spells.abilities.clear();break;case 12:p.fit=false;break;}
   Synchronize(&p);NoChange(p);
  }
  Setup(race);Player p;p.race=race;eligible.erase({race,55});Synchronize(&p);NoChange(p);
  Setup(race);p=Player{};p.race=race;p.learnFails=true;Synchronize(&p);Check(p.skills.empty()&&!p.defaults&&p.learns==1);
  Setup(race);p=Player{};p.race=race;p.skills[43]={193,300};p.skills[129]={375,450};
  RebornCoaBirthPlayerScript script;script.OnPlayerCreate(&p);
  Check(p.HasSpell(spell)&&p.skills[lang]==std::make_pair(uint32(300),uint32(300)));
  Check(p.skills[43]==std::make_pair(uint32(193),uint32(300))&&p.skills[129].first==375);
  Check(!p.HasSkill(762)&&!p.HasSkill(118)&&!p.HasSkill(293)&&!p.HasSkill(183));
  Check(!p.HasSkill(race==39?109:98));
  auto oldSkills=p.skills;auto oldKnown=p.known;int oldSets=p.sets,oldDefaults=p.defaults,oldLearns=p.learns;
  for(int i=0;i<100;++i)script.OnPlayerLogin(&p);
  Check(p.skills==oldSkills&&p.known==oldKnown&&p.sets==oldSets&&p.defaults==oldDefaults&&p.learns==oldLearns);
  Setup(race);p=Player{};p.race=race;p.known.insert(spell);p.skills[lang]={300,300};script.OnPlayerLogin(&p);Check(!p.learns&&!p.sets);
  for(uint8 cls:{uint8(2),uint8(13),uint8(14),uint8(15)}){Setup(race);p=Player{};p.race=race;p.cls=cls;Synchronize(&p);NoChange(p);}
 }
 Setup(39);for(uint8 race:{uint8(0),uint8(1),uint8(2),uint8(7),uint8(17),uint8(36),uint8(37),uint8(113)}){Player p;p.race=race;Synchronize(&p);NoChange(p);}
 for(uint32 id=0;id<1000;++id){bool allowed=RebornCoaBirth::IsBasicSkill(id);if(id==98||id==109||id==129||id==118||id==183||id==293||id==762)Check(!allowed);}
 std::cout<<"PASS "<<checks<<" actual module-body/API-substitute checks, including 200 repeated logins\n";
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
| 6 | <code>#include &lt;string&gt;</code> | 引入<string>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 7 | <code>#include &lt;cassert&gt;</code> | 引入<cassert>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 8 | <code>#include &lt;iostream&gt;</code> | 引入<iostream>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 9 | <code>#include "BirthPolicy.h"</code> | 引入"BirthPolicy.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 10 | <code>using uint8=std::uint8_t;using uint16=std::uint16_t;using uint32=std::uint32_t;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`using uint8=std::uint8_t;using uint16=std::uint16_t;using uint32=std::uint32_t;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 11 | <code>constexpr uint8 CLASS_WARRIOR=1;constexpr uint32 CHRRACES_FLAGS_NOT_PLAYABLE=4;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`constexpr uint8 CLASS_WARRIOR=1;constexpr uint32 CHRRACES_FLAGS_NOT_PLAYABLE=4;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12 | <code>int errors=0,checks=0;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`int errors=0,checks=0;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 13 | <code>template&lt;class... A&gt; void Error(A...){++errors;}</code> | 此行属于“测试_module_fixture.cpp”：`template<class... A> void Error(A...){++errors;}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 14 | <code>#define LOG_ERROR(...) Error(__VA_ARGS__)</code> | 此行属于“测试_module_fixture.cpp”：`#define LOG_ERROR(...) Error(__VA_ARGS__)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 15 | <code>#define LOG_INFO(...) ((void)0)</code> | 此行属于“测试_module_fixture.cpp”：`#define LOG_INFO(...) ((void)0)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 16 | <code>struct PlayerCreateInfoSkill {uint16 SkillId;uint16 Rank;};</code> | 声明代码组织/数据类型：struct PlayerCreateInfoSkill {uint16 SkillId;uint16 Rank;};；把同类规则或测试替身成员放一起。 |
| 17 | <code>struct PlayerInfo {std::vector&lt;PlayerCreateInfoSkill&gt; skills;};</code> | 声明代码组织/数据类型：struct PlayerInfo {std::vector<PlayerCreateInfoSkill> skills;};；把同类规则或测试替身成员放一起。 |
| 18 | <code>struct ChrRacesEntry {uint32 Flags=0;uint8 alliance=0;};</code> | 声明代码组织/数据类型：struct ChrRacesEntry {uint32 Flags=0;uint8 alliance=0;};；把同类规则或测试替身成员放一起。 |
| 19 | <code>struct Store {std::map&lt;uint32,ChrRacesEntry&gt; rows;ChrRacesEntry const* LookupEntry(uint32 r){auto i=rows.find(r);return i==rows.end()?nullptr:&amp;i-&gt;second;}} sChrRacesStore;</code> | 声明代码组织/数据类型：struct Store {std::map<uint32,ChrRacesEntry> rows;ChrRacesEntry const* LookupEntry(uint32 r){auto i=rows.find(r);return i==rows.end()?nullptr:&i->second;}} sChrRacesStore;；把同类规则或测试替身成员放一起。 |
| 20 | <code>uint32 masks[256]={}, reps[256]={};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint32 masks[256]={}, reps[256]={};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 21 | <code>uint32 GetRaceMaskForRace(uint8 r){return masks[r];}</code> | 调用GetRaceMaskForRace（将真实race映射为旧接口资格位；36/37仍返回0）；此行参数来自当前上下文。 |
| 22 | <code>uint32 GetReputationRaceMaskForRace(uint8 r){return reps[r];}</code> | 调用GetReputationRaceMaskForRace（给默认声望找同阵营模板位，不改变角色真实race）；此行参数来自当前上下文。 |
| 23 | <code>struct RaceMgr {uint32 max=50;uint32 GetMaxRaces(){return max;}} races,*sRaceMgr=&amp;races;</code> | 声明代码组织/数据类型：struct RaceMgr {uint32 max=50;uint32 GetMaxRaces(){return max;}} races,*sRaceMgr=&races;；把同类规则或测试替身成员放一起。 |
| 24 | <code>struct ObjectMgr {std::map&lt;uint32,PlayerInfo&gt; infos;PlayerInfo const* GetPlayerInfo(uint8 r,uint8){assert(r&lt;races.max);auto i=infos.find(r);return i==infos.end()?nullptr:&amp;i-&gt;second;}} objects,*sObjectMgr=&amp;objects;</code> | 声明代码组织/数据类型：struct ObjectMgr {std::map<uint32,PlayerInfo> infos;PlayerInfo const* GetPlayerInfo(uint8 r,uint8){assert(r<races.max);auto i=infos.find(r);return i==infos.end()?nullptr:&i->second;}} objects,*sObjectMgr=&objects;；把同类规则或测试替身成员放一起。 |
| 25 | <code>bool cfg=false;struct Config {template&lt;class T&gt;T GetOption(char const*,T){return cfg;}} config,*sConfigMgr=&amp;config;</code> | 定义/进入函数：读取模块Enable开关，默认false。同一行若有return，函数立即交回该结果。 |
| 26 | <code>std::set&lt;std::pair&lt;uint32,uint32&gt;&gt; eligible;</code> | 此行属于“bool cfg=false;struct Config ”：`std::set<std::pair<uint32,uint32>> eligible;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 27 | <code>void const* GetSkillRaceClassInfo(uint32 skill,uint8 race,uint8){return eligible.count({race,skill})?&amp;eligible:nullptr;}</code> | 定义/进入函数：按技能、真实种族、职业筛首条资格行；单族行对别名族不继承。同一行若有return，函数立即交回该结果。 |
| 28 | <code>struct SpellInfo {} spellInfo;</code> | 声明代码组织/数据类型：struct SpellInfo {} spellInfo;；把同类规则或测试替身成员放一起。 |
| 29 | <code>struct Ability {uint32 SkillLine;};Ability common{98},orcish{109};</code> | 声明代码组织/数据类型：struct Ability {uint32 SkillLine;};Ability common{98},orcish{109};；把同类规则或测试替身成员放一起。 |
| 30 | <code>struct SpellMgr {std::set&lt;uint32&gt; spells;std::multimap&lt;uint32,Ability*&gt; abilities;SpellInfo const* GetSpellInfo(uint32 spell){return spells.count(spell)?&amp;spellInfo:nullptr;} auto GetSkillLineAbilityMapBounds(uint32 spell){return abilities.equal_range(spell);}} spells,*sSpellMgr=&amp;spells;</code> | 声明代码组织/数据类型：struct SpellMgr {std::set<uint32> spells;std::multimap<uint32,Ability*> abilities;SpellInfo const* GetSpellInfo(uint32 spell){return spells.count(spell)?&spellInfo:nullptr;} auto GetSkillLineAbilityMapBounds(uint32 spell){return abilities.equal_range(spell);}} spells,*sSpellMgr=&spells;；把同类规则或测试替身成员放一起。 |
| 31 | <code>struct Player {</code> | 声明代码组织/数据类型：struct Player {；把同类规则或测试替身成员放一起。 |
| 32 | <code> uint8 race=39,displayRace=2,cls=1;bool fit=true,learnFails=false;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint8 race=39,displayRace=2,cls=1;bool fit=true,learnFails=false;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 33 | <code> std::set&lt;uint32&gt; known;std::map&lt;uint32,std::pair&lt;uint32,uint32&gt;&gt; skills;</code> | 此行属于“void const* GetSkillRaceClassInfo(uint32 skill,uint8 race,uint8)”：`std::set<uint32> known;std::map<uint32,std::pair<uint32,uint32>> skills;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 34 | <code> int learns=0,sets=0,defaults=0;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`int learns=0,sets=0,defaults=0;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 35 | <code> uint8 getRace(bool original){return original?race:displayRace;}uint8 getClass(){return cls;}</code> | 此行属于“void const* GetSkillRaceClassInfo(uint32 skill,uint8 race,uint8)”：`uint8 getRace(bool original){return original?race:displayRace;}uint8 getClass(){return cls;}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 36 | <code> bool HasSpell(uint32 s){return known.count(s);}bool HasSkill(uint32 s){return skills.count(s);}</code> | 定义/进入函数：检查已有技能，防止覆盖练过的熟练度；检查已学法术，保证重复登录不会重复授予。同一行若有return，函数立即交回该结果。 |
| 37 | <code> bool IsSpellFitByClassAndRace(uint32){return fit;}</code> | 语言法术必须符合真实职业/种族资格，不由模块强行绕过核心。 |
| 38 | <code> void learnSpell(uint32 s){++learns;if(!learnFails)known.insert(s);}</code> | 此行属于“void learnSpell(uint32 s)”：`void learnSpell(uint32 s){++learns;if(!learnFails)known.insert(s);}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 39 | <code> void SetSkill(uint32 s,uint16,uint16 value,uint16 max){++sets;skills[s]={value,max};}</code> | 定义/进入函数：设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器。 |
| 40 | <code> void LearnDefaultSkill(uint32 s,uint16 rank){assert(rank==0);++defaults;skills[s]={1,300};}</code> | 定义/进入函数：沿核心默认技能学习路径授予模板已有基础技能，不强制练满。 |
| 41 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 42 | <code>constexpr int PLAYERHOOK_ON_CREATE=1,PLAYERHOOK_ON_LOGIN=2;</code> | 订阅创建和登录回调，两者共用补缺函数；穿装先后由核心提前处理。 |
| 43 | <code>struct PlayerScript {PlayerScript(char const*,std::initializer_list&lt;int&gt;){}virtual ~PlayerScript()=default;virtual void OnPlayerCreate(Player*){}virtual void OnPlayerLogin(Player*){}};</code> | 声明代码组织/数据类型：struct PlayerScript {PlayerScript(char const*,std::initializer_list<int>){}virtual ~PlayerScript()=default;virtual void OnPlayerCreate(Player*){}virtual void OnPlayerLogin(Player*){}};；把同类规则或测试替身成员放一起。 |
| 44 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 45 | <code>// RACENEXT2A: explicit birth-language and missing basic-skill repair for 39/49.</code> | 说明注释：RACENEXT2A: explicit birth-language and missing basic-skill repair for 39/49.；它不执行，实际条件仍以相邻代码为准。 |
| 46 | <code>// This module does not open creation, initialize reputation, or award items.</code> | 说明注释：This module does not open creation, initialize reputation, or award items.；它不执行，实际条件仍以相邻代码为准。 |
| 47 | <code>#include &lt;algorithm&gt;</code> | 引入<algorithm>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 48 | <code>#include &lt;vector&gt;</code> | 引入<vector>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 49 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 50 | <code>namespace</code> | 声明代码组织/数据类型：namespace；把同类规则或测试替身成员放一起。 |
| 51 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 52 | <code>using namespace RebornCoaBirth;</code> | 给类型/命名空间取本地简写，后面的uint8/uint32仍保持明确位宽。 |
| 53 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 54 | <code>char const* CheckPrerequisites(Profile const&amp; profile)</code> | 调用CheckPrerequisites（先查全部核心/DBC/出生/语言依赖，返回空表示依赖完整）；此行参数来自当前上下文。 |
| 55 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 56 | <code>    ChrRacesEntry const* race = sChrRacesStore.LookupEntry(profile.Race);</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`ChrRacesEntry const* race = sChrRacesStore.LookupEntry(profile.Race);`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 57 | <code>    if (!race &#124;&#124; (race-&gt;Flags &amp; CHRRACES_FLAGS_NOT_PLAYABLE) &#124;&#124; race-&gt;alliance != profile.Alliance)</code> | 条件分支：只有`if (!race ／／ (race->Flags & CHRRACES_FLAGS_NOT_PLAYABLE) ／／ race->alliance != profile.Alliance)`成立才走随后分支；不满足进入else/跳过。 |
| 58 | <code>        return "missing/playability/faction ChrRaces contract";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 59 | <code>    if (sRaceMgr-&gt;GetMaxRaces() &lt;= profile.Race)</code> | 条件分支：只有`if (sRaceMgr->GetMaxRaces() <= profile.Race)`成立才走随后分支；不满足进入else/跳过。 |
| 60 | <code>        return "runtime race capacity not ready";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 61 | <code>    if (GetRaceMaskForRace(profile.Race) != profile.AliasMask)</code> | 条件分支：只有`if (GetRaceMaskForRace(profile.Race) != profile.AliasMask)`成立才走随后分支；不满足进入else/跳过。 |
| 62 | <code>        return "coordinated race-mask contract not ready";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 63 | <code>    if (GetReputationRaceMaskForRace(profile.Race) != GetRaceMaskForRace(profile.TemplateRace))</code> | 条件分支：只有`if (GetReputationRaceMaskForRace(profile.Race) != GetRaceMaskForRace(profile.TemplateRace))`成立才走随后分支；不满足进入else/跳过。 |
| 64 | <code>        return "explicit reputation template not ready";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 65 | <code>    if (!sObjectMgr-&gt;GetPlayerInfo(profile.Race, CLASS_WARRIOR) &#124;&#124;</code> | 条件分支：只有`if (!sObjectMgr->GetPlayerInfo(profile.Race, CLASS_WARRIOR) ／／`成立才走随后分支；不满足进入else/跳过。 |
| 66 | <code>        !sObjectMgr-&gt;GetPlayerInfo(profile.TemplateRace, CLASS_WARRIOR))</code> | 此行属于“void LearnDefaultSkill(uint32 s,uint16 rank)”：`!sObjectMgr->GetPlayerInfo(profile.TemplateRace, CLASS_WARRIOR))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 67 | <code>        return "missing Warrior birth information";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 68 | <code>    if (!GetSkillRaceClassInfo(profile.LanguageSkill, profile.Race, CLASS_WARRIOR) &#124;&#124;</code> | 条件分支：只有`if (!GetSkillRaceClassInfo(profile.LanguageSkill, profile.Race, CLASS_WARRIOR) ／／`成立才走随后分支；不满足进入else/跳过。 |
| 69 | <code>        !sSpellMgr-&gt;GetSpellInfo(profile.LanguageSpell))</code> | 此行属于“void LearnDefaultSkill(uint32 s,uint16 rank)”：`!sSpellMgr->GetSpellInfo(profile.LanguageSpell))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 70 | <code>        return "missing explicit language skill/spell data";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 71 | <code>    auto bounds = sSpellMgr-&gt;GetSkillLineAbilityMapBounds(profile.LanguageSpell);</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`auto bounds = sSpellMgr->GetSkillLineAbilityMapBounds(profile.LanguageSpell);`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 72 | <code>    for (auto i = bounds.first; i != bounds.second; ++i)</code> | 循环：for (auto i = bounds.first; i != bounds.second; ++i)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 73 | <code>        if (i-&gt;second-&gt;SkillLine == profile.LanguageSkill)</code> | 条件分支：只有`if (i->second->SkillLine == profile.LanguageSkill)`成立才走随后分支；不满足进入else/跳过。 |
| 74 | <code>            return nullptr;</code> | 返回失败/空结果，结束当前函数；不会继续后面的学习或写入。 |
| 75 | <code>    return "language spell is not linked to its language skill";</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 76 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 77 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 78 | <code>void Synchronize(Player* player)</code> | 定义/进入函数：只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望。 |
| 79 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 80 | <code>    if (!player)</code> | 条件分支：只有`if (!player)`成立才走随后分支；不满足进入else/跳过。 |
| 81 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 82 | <code>    Profile const* profile = FindProfile(player-&gt;getRace(true), player-&gt;getClass());</code> | 按真实种族查规则；变身显示race不应改变语言/出生修复对象。 |
| 83 | <code>    if (!profile &#124;&#124; !sConfigMgr-&gt;GetOption&lt;bool&gt;("RebornCoaBirth.Enable", false))</code> | 读显式功能开关，缺配置默认关闭；放了conf还要CMake注册加载。 |
| 84 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 85 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 86 | <code>    if (char const* problem = CheckPrerequisites(*profile))</code> | 条件分支：只有`if (char const* problem = CheckPrerequisites(*profile))`成立才走随后分支；不满足进入else/跳过。 |
| 87 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 88 | <code>        LOG_ERROR("module", "RACENEXT2A: race {} skipped: {}", uint32(profile-&gt;Race), problem);</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} skipped: {}", uint32(profile->Race), problem);；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 89 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 90 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 91 | <code>    if (!player-&gt;IsSpellFitByClassAndRace(profile-&gt;LanguageSpell))</code> | 语言法术必须符合真实职业/种族资格，不由模块强行绕过核心。 |
| 92 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 93 | <code>        LOG_ERROR("module", "RACENEXT2A: race {} explicit language eligibility missing", uint32(profile-&gt;Race));</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} explicit language eligibility missing", uint32(profile->Race));；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 94 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 95 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 96 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 97 | <code>    PlayerInfo const* parent = sObjectMgr-&gt;GetPlayerInfo(profile-&gt;TemplateRace, CLASS_WARRIOR);</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`PlayerInfo const* parent = sObjectMgr->GetPlayerInfo(profile->TemplateRace, CLASS_WARRIOR);`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 98 | <code>    std::vector&lt;uint32&gt; missing;</code> | 此行属于“void Synchronize(Player* player)”：`std::vector<uint32> missing;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 99 | <code>    for (PlayerCreateInfoSkill const&amp; entry : parent-&gt;skills)</code> | 循环：for (PlayerCreateInfoSkill const& entry : parent->skills)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 100 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 101 | <code>        if (entry.Rank != 0 &#124;&#124; !IsBasicSkill(entry.SkillId) &#124;&#124; player-&gt;HasSkill(entry.SkillId) &#124;&#124;</code> | 登录修复只处理模板初始Rank0；不越权教高级技能或降级已有熟练度。 |
| 102 | <code>            std::find(missing.begin(), missing.end(), entry.SkillId) != missing.end())</code> | 查待补列表是否已有此技能，排除模板重复行导致的重复学习。 |
| 103 | <code>            continue;</code> | 跳过当前不合格记录，进入下一条；不授予这条技能/种族。 |
| 104 | <code>        // Preflight all missing skills BEFORE the first grant. Skill reward</code> | 说明注释：Preflight all missing skills BEFORE the first grant. Skill reward；它不执行，实际条件仍以相邻代码为准。 |
| 105 | <code>        // eligibility must be integrated in the core, not forced by this module.</code> | 说明注释：eligibility must be integrated in the core, not forced by this module.；它不执行，实际条件仍以相邻代码为准。 |
| 106 | <code>        if (!GetSkillRaceClassInfo(entry.SkillId, profile-&gt;Race, CLASS_WARRIOR))</code> | 条件分支：只有`if (!GetSkillRaceClassInfo(entry.SkillId, profile->Race, CLASS_WARRIOR))`成立才走随后分支；不满足进入else/跳过。 |
| 107 | <code>        {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 108 | <code>            LOG_ERROR("module", "RACENEXT2A: race {} basic skill {} eligibility missing; no repair",</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} basic skill {} eligibility missing; no repair",；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 109 | <code>                uint32(profile-&gt;Race), uint32(entry.SkillId));</code> | 此行属于“void Synchronize(Player* player)”：`uint32(profile->Race), uint32(entry.SkillId));`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 110 | <code>            return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 111 | <code>        }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 112 | <code>        missing.push_back(entry.SkillId);</code> | 只收集缺失技能，先完成所有资格检查，后面才统一授予。 |
| 113 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 114 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 115 | <code>    if (!player-&gt;HasSpell(profile-&gt;LanguageSpell))</code> | 条件分支：只有`if (!player->HasSpell(profile->LanguageSpell))`成立才走随后分支；不满足进入else/跳过。 |
| 116 | <code>        player-&gt;learnSpell(profile-&gt;LanguageSpell);</code> | 此行属于“void Synchronize(Player* player)”：`player->learnSpell(profile->LanguageSpell);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 117 | <code>    if (!player-&gt;HasSpell(profile-&gt;LanguageSpell))</code> | 条件分支：只有`if (!player->HasSpell(profile->LanguageSpell))`成立才走随后分支；不满足进入else/跳过。 |
| 118 | <code>    {</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 119 | <code>        LOG_ERROR("module", "RACENEXT2A: race {} language learn failed; basic skills skipped", uint32(profile-&gt;Race));</code> | 输出诊断日志：LOG_ERROR("module", "RACENEXT2A: race {} language learn failed; basic skills skipped", uint32(profile->Race));；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 120 | <code>        return;</code> | 此行属于“void Synchronize(Player* player)”：`return;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 121 | <code>    }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 122 | <code>    if (!player-&gt;HasSkill(profile-&gt;LanguageSkill))</code> | 条件分支：只有`if (!player->HasSkill(profile->LanguageSkill))`成立才走随后分支；不满足进入else/跳过。 |
| 123 | <code>        player-&gt;SetSkill(profile-&gt;LanguageSkill, 0, 300, 300);</code> | 调用SetSkill（设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器）；此行参数来自当前上下文。 |
| 124 | <code>    // Existing values, progression and skills are never reset or maxed here.</code> | 说明注释：Existing values, progression and skills are never reset or maxed here.；它不执行，实际条件仍以相邻代码为准。 |
| 125 | <code>    for (uint32 skill : missing)</code> | 循环：for (uint32 skill : missing)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 126 | <code>        if (!player-&gt;HasSkill(skill))</code> | 条件分支：只有`if (!player->HasSkill(skill))`成立才走随后分支；不满足进入else/跳过。 |
| 127 | <code>            player-&gt;LearnDefaultSkill(skill, 0);</code> | 调用LearnDefaultSkill（沿核心默认技能学习路径授予模板已有基础技能，不强制练满）；此行参数来自当前上下文。 |
| 128 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 129 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 130 | <code>class RebornCoaBirthPlayerScript final : public PlayerScript</code> | 声明代码组织/数据类型：class RebornCoaBirthPlayerScript final : public PlayerScript；把同类规则或测试替身成员放一起。 |
| 131 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 132 | <code>public:</code> | C++访问权限分界：下面成员按此权限提供给调用者。 |
| 133 | <code>    RebornCoaBirthPlayerScript() : PlayerScript("RebornCoaBirthPlayerScript",</code> | 此行属于“void Synchronize(Player* player)”：`RebornCoaBirthPlayerScript() : PlayerScript("RebornCoaBirthPlayerScript",`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 134 | <code>        {PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LOGIN}) { }</code> | 订阅创建和登录回调，两者共用补缺函数；穿装先后由核心提前处理。 |
| 135 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 136 | <code>    void OnPlayerCreate(Player* player) override { Synchronize(player); }</code> | 定义/进入函数：只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望；服务器建角回调，此时物品已分配，所以它不能解决创建前穿装资格。 |
| 137 | <code>    void OnPlayerLogin(Player* player) override { Synchronize(player); }</code> | 定义/进入函数：只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望；角色登录回调，调用同一补缺函数，避免新旧角色两种实现。 |
| 138 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 139 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 140 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 141 | <code>void AddRebornCoaBirthScripts()</code> | 定义/进入函数：向模块加载器注册PlayerScript，同时报告配置开关。 |
| 142 | <code>{</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 143 | <code>    new RebornCoaBirthPlayerScript();</code> | 此行属于“void AddRebornCoaBirthScripts()”：`new RebornCoaBirthPlayerScript();`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 144 | <code>    LOG_INFO("module", "RACENEXT2A: birth repair registered for race39/49 Warrior; enabled={}",</code> | 输出诊断日志：LOG_INFO("module", "RACENEXT2A: birth repair registered for race39/49 Warrior; enabled={}",；日志说明阶段和失败契约，不以打印了日志代替游戏验收。 |
| 145 | <code>        sConfigMgr-&gt;GetOption&lt;bool&gt;("RebornCoaBirth.Enable", false));</code> | 读显式功能开关，缺配置默认关闭；放了conf还要CMake注册加载。 |
| 146 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 147 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 148 | <code>void Check(bool ok){assert(ok);++checks;}</code> | 定义/进入函数：C++断言计数，失败终止测试。 |
| 149 | <code>void Setup(uint8 race){</code> | 定义/进入函数：准备某种族的最小合法测试依赖，再故意缺某项验证拒绝。 |
| 150 | <code> cfg=true;errors=0;races.max=50;objects.infos.clear();sChrRacesStore.rows.clear();eligible.clear();spells.spells={668,669};spells.abilities.clear();</code> | 调用clear（清空测试状态、确认职业/天赋组，防止上一测试污染下一测试）；此行参数来自当前上下文。 |
| 151 | <code> masks[1]=1;masks[2]=2;masks[39]=64;masks[49]=65536;reps[39]=1;reps[49]=2;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`masks[1]=1;masks[2]=2;masks[39]=64;masks[49]=65536;reps[39]=1;reps[49]=2;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 152 | <code> auto p=RebornCoaBirth::FindProfile(race,1);assert(p);</code> | 调用FindProfile（查39/49战士的固定语言/阵营契约，找不到返回空）；此行参数来自当前上下文。 |
| 153 | <code> sChrRacesStore.rows[race]={0,p-&gt;Alliance};objects.infos[race]={};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`sChrRacesStore.rows[race]={0,p->Alliance};objects.infos[race]={};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 154 | <code> objects.infos[p-&gt;TemplateRace].skills={{26,0},{256,0},{257,0},{95,0},{162,0},{43,0},{55,0},{413,0},{414,0},{415,0},{433,0},{55,0},{129,4},{762,0},{118,0},{293,0},{98,0},{109,0},{183,0}};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`objects.infos[p->TemplateRace].skills={{26,0},{256,0},{257,0},{95,0},{162,0},{43,0},{55,0},{413,0},{414,0},{415,0},{433,0},{55,0},{129,4},{762,0},{118,0},{293,0},{98,0},{109,0},{183,0}};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 155 | <code> for(auto const&amp; s:objects.infos[p-&gt;TemplateRace].skills)eligible.insert({race,s.SkillId});</code> | 循环：for(auto const& s:objects.infos[p->TemplateRace].skills)eligible.insert({race,s.SkillId});；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 156 | <code> eligible.insert({race,p-&gt;LanguageSkill});spells.abilities.emplace(668,&amp;common);spells.abilities.emplace(669,&amp;orcish);</code> | 此行属于“void Setup(uint8 race)”：`eligible.insert({race,p->LanguageSkill});spells.abilities.emplace(668,&common);spells.abilities.emplace(669,&orcish);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 157 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 158 | <code>void NoChange(Player&amp; p){Check(p.known.empty()&amp;&amp;p.skills.empty()&amp;&amp;!p.learns&amp;&amp;!p.sets&amp;&amp;!p.defaults);}</code> | 定义/进入函数：C++断言计数，失败终止测试；验证被拒绝的玩家没有获得任何语言/技能副作用。 |
| 159 | <code>int main(){</code> | 此行属于“void NoChange(Player& p)”：`int main(){`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 160 | <code> Synchronize(nullptr);Check(true);</code> | 测试断言：Synchronize(nullptr);Check(true);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 161 | <code> for(uint8 race:{uint8(39),uint8(49)}){</code> | 循环：for(uint8 race:{uint8(39),uint8(49)})；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 162 | <code>  auto const* profile=RebornCoaBirth::FindProfile(race,1);uint32 lang=profile-&gt;LanguageSkill,spell=profile-&gt;LanguageSpell;</code> | 调用FindProfile（查39/49战士的固定语言/阵营契约，找不到返回空）；此行参数来自当前上下文。 |
| 163 | <code>  for(int gate=0;gate&lt;13;++gate){Setup(race);Player p;p.race=race;</code> | 循环：for(int gate=0;gate<13;++gate){Setup(race);Player p;p.race=race;；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 164 | <code>   switch(gate){case 0:cfg=false;break;case 1:sChrRacesStore.rows.clear();break;case 2:sChrRacesStore.rows[race].Flags=4;break;case 3:sChrRacesStore.rows[race].alliance^=1;break;</code> | 调用clear（清空测试状态、确认职业/天赋组，防止上一测试污染下一测试）；此行参数来自当前上下文。 |
| 165 | <code>    case 4:races.max=race;break;case 5:masks[race]=0;break;case 6:reps[race]=profile-&gt;AliasMask;break;case 7:objects.infos.erase(race);break;case 8:objects.infos.erase(profile-&gt;TemplateRace);break;</code> | 枚举当前允许的技能/种族分支：case 4:races.max=race;break;case 5:masks[race]=0;break;case 6:reps[race]=profile->AliasMask;break;case 7:objects.infos.erase(race);break;case 8:objects.infos.erase(profile->TemplateRace);break;；这些编号的含义见核心参数表，仍需模板行存在。 |
| 166 | <code>    case 9:eligible.erase({race,lang});break;case 10:spells.spells.erase(spell);break;case 11:spells.abilities.clear();break;case 12:p.fit=false;break;}</code> | 枚举当前允许的技能/种族分支：case 9:eligible.erase({race,lang});break;case 10:spells.spells.erase(spell);break;case 11:spells.abilities.clear();break;case 12:p.fit=false;break;}；这些编号的含义见核心参数表，仍需模板行存在。 |
| 167 | <code>   Synchronize(&amp;p);NoChange(p);</code> | 调用Synchronize（只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望）、NoChange（验证被拒绝的玩家没有获得任何语言/技能副作用）；此行参数来自当前上下文。 |
| 168 | <code>  }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 169 | <code>  Setup(race);Player p;p.race=race;eligible.erase({race,55});Synchronize(&amp;p);NoChange(p);</code> | 调用Synchronize（只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望）、Setup（准备某种族的最小合法测试依赖，再故意缺某项验证拒绝）、NoChange（验证被拒绝的玩家没有获得任何语言/技能副作用）；此行参数来自当前上下文。 |
| 170 | <code>  Setup(race);p=Player{};p.race=race;p.learnFails=true;Synchronize(&amp;p);Check(p.skills.empty()&amp;&amp;!p.defaults&amp;&amp;p.learns==1);</code> | 测试断言：Setup(race);p=Player{};p.race=race;p.learnFails=true;Synchronize(&p);Check(p.skills.empty()&&!p.defaults&&p.learns==1);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 171 | <code>  Setup(race);p=Player{};p.race=race;p.skills[43]={193,300};p.skills[129]={375,450};</code> | 调用Setup（准备某种族的最小合法测试依赖，再故意缺某项验证拒绝）；此行参数来自当前上下文。 |
| 172 | <code>  RebornCoaBirthPlayerScript script;script.OnPlayerCreate(&amp;p);</code> | 调用OnPlayerCreate（服务器建角回调，此时物品已分配，所以它不能解决创建前穿装资格）；此行参数来自当前上下文。 |
| 173 | <code>  Check(p.HasSpell(spell)&amp;&amp;p.skills[lang]==std::make_pair(uint32(300),uint32(300)));</code> | 测试断言：Check(p.HasSpell(spell)&&p.skills[lang]==std::make_pair(uint32(300),uint32(300)));。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 174 | <code>  Check(p.skills[43]==std::make_pair(uint32(193),uint32(300))&amp;&amp;p.skills[129].first==375);</code> | 测试断言：Check(p.skills[43]==std::make_pair(uint32(193),uint32(300))&&p.skills[129].first==375);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 175 | <code>  Check(!p.HasSkill(762)&amp;&amp;!p.HasSkill(118)&amp;&amp;!p.HasSkill(293)&amp;&amp;!p.HasSkill(183));</code> | 测试断言：Check(!p.HasSkill(762)&&!p.HasSkill(118)&&!p.HasSkill(293)&&!p.HasSkill(183));。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 176 | <code>  Check(!p.HasSkill(race==39?109:98));</code> | 测试断言：Check(!p.HasSkill(race==39?109:98));。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 177 | <code>  auto oldSkills=p.skills;auto oldKnown=p.known;int oldSets=p.sets,oldDefaults=p.defaults,oldLearns=p.learns;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`auto oldSkills=p.skills;auto oldKnown=p.known;int oldSets=p.sets,oldDefaults=p.defaults,oldLearns=p.learns;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 178 | <code>  for(int i=0;i&lt;100;++i)script.OnPlayerLogin(&amp;p);</code> | 循环：for(int i=0;i<100;++i)script.OnPlayerLogin(&p);；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 179 | <code>  Check(p.skills==oldSkills&amp;&amp;p.known==oldKnown&amp;&amp;p.sets==oldSets&amp;&amp;p.defaults==oldDefaults&amp;&amp;p.learns==oldLearns);</code> | 测试断言：Check(p.skills==oldSkills&&p.known==oldKnown&&p.sets==oldSets&&p.defaults==oldDefaults&&p.learns==oldLearns);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 180 | <code>  Setup(race);p=Player{};p.race=race;p.known.insert(spell);p.skills[lang]={300,300};script.OnPlayerLogin(&amp;p);Check(!p.learns&amp;&amp;!p.sets);</code> | 测试断言：Setup(race);p=Player{};p.race=race;p.known.insert(spell);p.skills[lang]={300,300};script.OnPlayerLogin(&p);Check(!p.learns&&!p.sets);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 181 | <code>  for(uint8 cls:{uint8(2),uint8(13),uint8(14),uint8(15)}){Setup(race);p=Player{};p.race=race;p.cls=cls;Synchronize(&amp;p);NoChange(p);}</code> | 循环：for(uint8 cls:{uint8(2),uint8(13),uint8(14),uint8(15)}){Setup(race);p=Player{};p.race=race;p.cls=cls;Synchronize(&p);NoChange(p);}；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 182 | <code> }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 183 | <code> Setup(39);for(uint8 race:{uint8(0),uint8(1),uint8(2),uint8(7),uint8(17),uint8(36),uint8(37),uint8(113)}){Player p;p.race=race;Synchronize(&amp;p);NoChange(p);}</code> | 调用Synchronize（只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望）、Setup（准备某种族的最小合法测试依赖，再故意缺某项验证拒绝）、NoChange（验证被拒绝的玩家没有获得任何语言/技能副作用）；此行参数来自当前上下文。 |
| 184 | <code> for(uint32 id=0;id&lt;1000;++id){bool allowed=RebornCoaBirth::IsBasicSkill(id);if(id==98&#124;&#124;id==109&#124;&#124;id==129&#124;&#124;id==118&#124;&#124;id==183&#124;&#124;id==293&#124;&#124;id==762)Check(!allowed);}</code> | 枚举技能ID验证白名单边界，特别是语言/专业/骑乘等不准通过。 |
| 185 | <code> std::cout&lt;&lt;"PASS "&lt;&lt;checks&lt;&lt;" actual module-body/API-substitute checks, including 200 repeated logins\n";</code> | 把测试结果/计数输出为证据；前面的断言都没失败才能走到这里。 |
| 186 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
