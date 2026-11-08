# 测试_codexwork_RACEJOINT1A_test_module.py：逐行讲解
实际验证代码；原样归档供学习。私有路径/环境必须先核对，不能运行到生产库或覆盖运行客户端。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261106\codexwork_RACEJOINT1A\test_module.py`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `GetReputationRaceMaskForRace` | 给默认声望找同阵营模板位，不改变角色真实race |
| `GetSkillRaceClassInfo` | 按技能、真实种族、职业筛首条资格行；单族行对别名族不继承 |
| `FindProfile` | 查39/49战士的固定语言/阵营契约，找不到返回空 |
| `IsBasicSkill` | 基础技能白名单；还要同时满足模板出生资料已有，不能只凭列表赠送 |
| `Synchronize` | 只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望 |
| `OnPlayerCreate` | 服务器建角回调，此时物品已分配，所以它不能解决创建前穿装资格 |
| `OnPlayerLogin` | 角色登录回调，调用同一补缺函数，避免新旧角色两种实现 |
| `decode` | 读取WDBC头和行区；检查文件长度以免写出损坏表 |
| `run` | 在专用测试库执行SQL并检查预期成功/失败，绝不是生产执行器 |
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
```python
# -*- coding: utf-8 -*-
from pathlib import Path
import subprocess,json,shutil
W=Path(__file__).resolve().parent;P=Path('D:\\000rebornWOW\\000RebornWOWHighForkPRO\\000Ascendupdate\\000Ascendupdate20261107\\codex-claude联合修复包_20261107_阶段RACEJOINT1A_库尔提拉斯与玛格汉战士联合候选\\A_服务端_Codex\\交付');M=P/'01_覆盖到源代码根目录/modules/mod-reborn-coa-birth/src'
source=(M/'RebornCoaBirth.cpp').read_text(encoding='utf8')
body='\n'.join(s for s in source.splitlines() if not s.startswith('#include "'))
shutil.copy2(M/'BirthPolicy.h',W/'BirthPolicy.h')
stub=r'''
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
'''
main=r'''
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
'''
(W/'module_fixture.cpp').write_text(stub+'\n'+body+'\n'+main,encoding='utf8')
cmd='call "D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat" >NUL && cl /nologo /EHsc /std:c++20 /utf-8 /MD /Fe:"'+str(W/'module_fixture.exe')+'" /Fo:"'+str(W/'module_fixture.obj')+'" "'+str(W/'module_fixture.cpp')+'"'
(W/'fixture.cmd').write_text('@echo off\n'+cmd+'\n',encoding='ascii')
q=subprocess.run(['cmd.exe','/d','/c',str(W/'fixture.cmd')],capture_output=True);(W/'fixture_build.log').write_bytes(q.stdout+q.stderr);assert q.returncode==0,q.stdout.decode(errors='replace')+q.stderr.decode(errors='replace')
q=subprocess.run([str(W/'module_fixture.exe')],capture_output=True);assert q.returncode==0,(q.returncode,q.stdout,q.stderr)
(W/'fixture_result.txt').write_bytes(q.stdout);print(q.stdout.decode(),end='')
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code># -*- coding: utf-8 -*-</code> | 说明注释：*- coding: utf-8 -*-；它不执行，实际条件仍以相邻代码为准。 |
| 2 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>import subprocess,json,shutil</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 4 | <code>W=Path(__file__).resolve().parent;P=Path('D:\\000rebornWOW\\000RebornWOWHighForkPRO\\000Ascendupdate\\000Ascendupdate20261107\\codex-claude联合修复包_20261107_阶段RACEJOINT1A_库尔提拉斯与玛格汉战士联合候选\\A_服务端_Codex\\交付');M=P/'01_覆盖到源代码根目录/modules/mod-reborn-coa-birth/src'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`W=Path(__file__).resolve().parent;P=Path('D:\\000rebornWOW\\000RebornWOWHighForkPRO\\000Ascendupdate\\000Ascendupdate20261107\\codex-claude联合修复包_20261107_阶段RACEJOINT1A_库尔提拉斯与玛格汉战士联合候选\\A_服务端_Codex\\交付');M=P/'01_覆盖到源代码根目录/modules/mod-reborn-coa-birth/src'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 5 | <code>source=(M/'RebornCoaBirth.cpp').read_text(encoding='utf8')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 6 | <code>body='\n'.join(s for s in source.splitlines() if not s.startswith('#include "'))</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`body='\n'.join(s for s in source.splitlines() if not s.startswith('#include "'))`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 7 | <code>shutil.copy2(M/'BirthPolicy.h',W/'BirthPolicy.h')</code> | 此行属于“测试_codexwork_RACEJOINT1A_test_module.py”：`shutil.copy2(M/'BirthPolicy.h',W/'BirthPolicy.h')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 8 | <code>stub=r'''</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`stub=r'''`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 9 | <code>#include &lt;cstdint&gt;</code> | 引入<cstdint>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 10 | <code>#include &lt;map&gt;</code> | 引入<map>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 11 | <code>#include &lt;set&gt;</code> | 引入<set>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 12 | <code>#include &lt;vector&gt;</code> | 引入<vector>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 13 | <code>#include &lt;string&gt;</code> | 引入<string>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 14 | <code>#include &lt;cassert&gt;</code> | 引入<cassert>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 15 | <code>#include &lt;iostream&gt;</code> | 引入<iostream>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 16 | <code>#include "BirthPolicy.h"</code> | 引入"BirthPolicy.h"的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 17 | <code>using uint8=std::uint8_t;using uint16=std::uint16_t;using uint32=std::uint32_t;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`using uint8=std::uint8_t;using uint16=std::uint16_t;using uint32=std::uint32_t;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 18 | <code>constexpr uint8 CLASS_WARRIOR=1;constexpr uint32 CHRRACES_FLAGS_NOT_PLAYABLE=4;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`constexpr uint8 CLASS_WARRIOR=1;constexpr uint32 CHRRACES_FLAGS_NOT_PLAYABLE=4;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 19 | <code>int errors=0,checks=0;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`int errors=0,checks=0;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 20 | <code>template&lt;class... A&gt; void Error(A...){++errors;}</code> | 此行属于“测试_codexwork_RACEJOINT1A_test_module.py”：`template<class... A> void Error(A...){++errors;}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 21 | <code>#define LOG_ERROR(...) Error(__VA_ARGS__)</code> | 此行属于“测试_codexwork_RACEJOINT1A_test_module.py”：`#define LOG_ERROR(...) Error(__VA_ARGS__)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 22 | <code>#define LOG_INFO(...) ((void)0)</code> | 此行属于“测试_codexwork_RACEJOINT1A_test_module.py”：`#define LOG_INFO(...) ((void)0)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 23 | <code>struct PlayerCreateInfoSkill {uint16 SkillId;uint16 Rank;};</code> | 声明代码组织/数据类型：struct PlayerCreateInfoSkill {uint16 SkillId;uint16 Rank;};；把同类规则或测试替身成员放一起。 |
| 24 | <code>struct PlayerInfo {std::vector&lt;PlayerCreateInfoSkill&gt; skills;};</code> | 声明代码组织/数据类型：struct PlayerInfo {std::vector<PlayerCreateInfoSkill> skills;};；把同类规则或测试替身成员放一起。 |
| 25 | <code>struct ChrRacesEntry {uint32 Flags=0;uint8 alliance=0;};</code> | 声明代码组织/数据类型：struct ChrRacesEntry {uint32 Flags=0;uint8 alliance=0;};；把同类规则或测试替身成员放一起。 |
| 26 | <code>struct Store {std::map&lt;uint32,ChrRacesEntry&gt; rows;ChrRacesEntry const* LookupEntry(uint32 r){auto i=rows.find(r);return i==rows.end()?nullptr:&amp;i-&gt;second;}} sChrRacesStore;</code> | 声明代码组织/数据类型：struct Store {std::map<uint32,ChrRacesEntry> rows;ChrRacesEntry const* LookupEntry(uint32 r){auto i=rows.find(r);return i==rows.end()?nullptr:&i->second;}} sChrRacesStore;；把同类规则或测试替身成员放一起。 |
| 27 | <code>uint32 masks[256]={}, reps[256]={};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint32 masks[256]={}, reps[256]={};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 28 | <code>uint32 GetRaceMaskForRace(uint8 r){return masks[r];}</code> | 调用GetRaceMaskForRace（将真实race映射为旧接口资格位；36/37仍返回0）；此行参数来自当前上下文。 |
| 29 | <code>uint32 GetReputationRaceMaskForRace(uint8 r){return reps[r];}</code> | 调用GetReputationRaceMaskForRace（给默认声望找同阵营模板位，不改变角色真实race）；此行参数来自当前上下文。 |
| 30 | <code>struct RaceMgr {uint32 max=50;uint32 GetMaxRaces(){return max;}} races,*sRaceMgr=&amp;races;</code> | 声明代码组织/数据类型：struct RaceMgr {uint32 max=50;uint32 GetMaxRaces(){return max;}} races,*sRaceMgr=&races;；把同类规则或测试替身成员放一起。 |
| 31 | <code>struct ObjectMgr {std::map&lt;uint32,PlayerInfo&gt; infos;PlayerInfo const* GetPlayerInfo(uint8 r,uint8){assert(r&lt;races.max);auto i=infos.find(r);return i==infos.end()?nullptr:&amp;i-&gt;second;}} objects,*sObjectMgr=&amp;objects;</code> | 声明代码组织/数据类型：struct ObjectMgr {std::map<uint32,PlayerInfo> infos;PlayerInfo const* GetPlayerInfo(uint8 r,uint8){assert(r<races.max);auto i=infos.find(r);return i==infos.end()?nullptr:&i->second;}} objects,*sObjectMgr=&objects;；把同类规则或测试替身成员放一起。 |
| 32 | <code>bool cfg=false;struct Config {template&lt;class T&gt;T GetOption(char const*,T){return cfg;}} config,*sConfigMgr=&amp;config;</code> | 定义/进入函数：读取模块Enable开关，默认false。同一行若有return，函数立即交回该结果。 |
| 33 | <code>std::set&lt;std::pair&lt;uint32,uint32&gt;&gt; eligible;</code> | 此行属于“bool cfg=false;struct Config ”：`std::set<std::pair<uint32,uint32>> eligible;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 34 | <code>void const* GetSkillRaceClassInfo(uint32 skill,uint8 race,uint8){return eligible.count({race,skill})?&amp;eligible:nullptr;}</code> | 定义/进入函数：按技能、真实种族、职业筛首条资格行；单族行对别名族不继承。同一行若有return，函数立即交回该结果。 |
| 35 | <code>struct SpellInfo {} spellInfo;</code> | 声明代码组织/数据类型：struct SpellInfo {} spellInfo;；把同类规则或测试替身成员放一起。 |
| 36 | <code>struct Ability {uint32 SkillLine;};Ability common{98},orcish{109};</code> | 声明代码组织/数据类型：struct Ability {uint32 SkillLine;};Ability common{98},orcish{109};；把同类规则或测试替身成员放一起。 |
| 37 | <code>struct SpellMgr {std::set&lt;uint32&gt; spells;std::multimap&lt;uint32,Ability*&gt; abilities;SpellInfo const* GetSpellInfo(uint32 spell){return spells.count(spell)?&amp;spellInfo:nullptr;} auto GetSkillLineAbilityMapBounds(uint32 spell){return abilities.equal_range(spell);}} spells,*sSpellMgr=&amp;spells;</code> | 声明代码组织/数据类型：struct SpellMgr {std::set<uint32> spells;std::multimap<uint32,Ability*> abilities;SpellInfo const* GetSpellInfo(uint32 spell){return spells.count(spell)?&spellInfo:nullptr;} auto GetSkillLineAbilityMapBounds(uint32 spell){return abilities.equal_range(spell);}} spells,*sSpellMgr=&spells;；把同类规则或测试替身成员放一起。 |
| 38 | <code>struct Player {</code> | 声明代码组织/数据类型：struct Player {；把同类规则或测试替身成员放一起。 |
| 39 | <code> uint8 race=39,displayRace=2,cls=1;bool fit=true,learnFails=false;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint8 race=39,displayRace=2,cls=1;bool fit=true,learnFails=false;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 40 | <code> std::set&lt;uint32&gt; known;std::map&lt;uint32,std::pair&lt;uint32,uint32&gt;&gt; skills;</code> | 此行属于“void const* GetSkillRaceClassInfo(uint32 skill,uint8 race,uint8)”：`std::set<uint32> known;std::map<uint32,std::pair<uint32,uint32>> skills;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 41 | <code> int learns=0,sets=0,defaults=0;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`int learns=0,sets=0,defaults=0;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 42 | <code> uint8 getRace(bool original){return original?race:displayRace;}uint8 getClass(){return cls;}</code> | 此行属于“void const* GetSkillRaceClassInfo(uint32 skill,uint8 race,uint8)”：`uint8 getRace(bool original){return original?race:displayRace;}uint8 getClass(){return cls;}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 43 | <code> bool HasSpell(uint32 s){return known.count(s);}bool HasSkill(uint32 s){return skills.count(s);}</code> | 定义/进入函数：检查已有技能，防止覆盖练过的熟练度；检查已学法术，保证重复登录不会重复授予。同一行若有return，函数立即交回该结果。 |
| 44 | <code> bool IsSpellFitByClassAndRace(uint32){return fit;}</code> | 语言法术必须符合真实职业/种族资格，不由模块强行绕过核心。 |
| 45 | <code> void learnSpell(uint32 s){++learns;if(!learnFails)known.insert(s);}</code> | 此行属于“void learnSpell(uint32 s)”：`void learnSpell(uint32 s){++learns;if(!learnFails)known.insert(s);}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 46 | <code> void SetSkill(uint32 s,uint16,uint16 value,uint16 max){++sets;skills[s]={value,max};}</code> | 定义/进入函数：设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器。 |
| 47 | <code> void LearnDefaultSkill(uint32 s,uint16 rank){assert(rank==0);++defaults;skills[s]={1,300};}</code> | 定义/进入函数：沿核心默认技能学习路径授予模板已有基础技能，不强制练满。 |
| 48 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 49 | <code>constexpr int PLAYERHOOK_ON_CREATE=1,PLAYERHOOK_ON_LOGIN=2;</code> | 订阅创建和登录回调，两者共用补缺函数；穿装先后由核心提前处理。 |
| 50 | <code>struct PlayerScript {PlayerScript(char const*,std::initializer_list&lt;int&gt;){}virtual ~PlayerScript()=default;virtual void OnPlayerCreate(Player*){}virtual void OnPlayerLogin(Player*){}};</code> | 声明代码组织/数据类型：struct PlayerScript {PlayerScript(char const*,std::initializer_list<int>){}virtual ~PlayerScript()=default;virtual void OnPlayerCreate(Player*){}virtual void OnPlayerLogin(Player*){}};；把同类规则或测试替身成员放一起。 |
| 51 | <code>'''</code> | 此行属于“void LearnDefaultSkill(uint32 s,uint16 rank)”：`'''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 52 | <code>main=r'''</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`main=r'''`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 53 | <code>void Check(bool ok){assert(ok);++checks;}</code> | 定义/进入函数：C++断言计数，失败终止测试。 |
| 54 | <code>void Setup(uint8 race){</code> | 定义/进入函数：准备某种族的最小合法测试依赖，再故意缺某项验证拒绝。 |
| 55 | <code> cfg=true;errors=0;races.max=50;objects.infos.clear();sChrRacesStore.rows.clear();eligible.clear();spells.spells={668,669};spells.abilities.clear();</code> | 调用clear（清空测试状态、确认职业/天赋组，防止上一测试污染下一测试）；此行参数来自当前上下文。 |
| 56 | <code> masks[1]=1;masks[2]=2;masks[39]=64;masks[49]=65536;reps[39]=1;reps[49]=2;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`masks[1]=1;masks[2]=2;masks[39]=64;masks[49]=65536;reps[39]=1;reps[49]=2;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 57 | <code> auto p=RebornCoaBirth::FindProfile(race,1);assert(p);</code> | 调用FindProfile（查39/49战士的固定语言/阵营契约，找不到返回空）；此行参数来自当前上下文。 |
| 58 | <code> sChrRacesStore.rows[race]={0,p-&gt;Alliance};objects.infos[race]={};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`sChrRacesStore.rows[race]={0,p->Alliance};objects.infos[race]={};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 59 | <code> objects.infos[p-&gt;TemplateRace].skills={{26,0},{256,0},{257,0},{95,0},{162,0},{43,0},{55,0},{413,0},{414,0},{415,0},{433,0},{55,0},{129,4},{762,0},{118,0},{293,0},{98,0},{109,0},{183,0}};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`objects.infos[p->TemplateRace].skills={{26,0},{256,0},{257,0},{95,0},{162,0},{43,0},{55,0},{413,0},{414,0},{415,0},{433,0},{55,0},{129,4},{762,0},{118,0},{293,0},{98,0},{109,0},{183,0}};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 60 | <code> for(auto const&amp; s:objects.infos[p-&gt;TemplateRace].skills)eligible.insert({race,s.SkillId});</code> | 循环：for(auto const& s:objects.infos[p->TemplateRace].skills)eligible.insert({race,s.SkillId});；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 61 | <code> eligible.insert({race,p-&gt;LanguageSkill});spells.abilities.emplace(668,&amp;common);spells.abilities.emplace(669,&amp;orcish);</code> | 此行属于“void Setup(uint8 race)”：`eligible.insert({race,p->LanguageSkill});spells.abilities.emplace(668,&common);spells.abilities.emplace(669,&orcish);`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 62 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 63 | <code>void NoChange(Player&amp; p){Check(p.known.empty()&amp;&amp;p.skills.empty()&amp;&amp;!p.learns&amp;&amp;!p.sets&amp;&amp;!p.defaults);}</code> | 定义/进入函数：C++断言计数，失败终止测试；验证被拒绝的玩家没有获得任何语言/技能副作用。 |
| 64 | <code>int main(){</code> | 此行属于“void NoChange(Player& p)”：`int main(){`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 65 | <code> Synchronize(nullptr);Check(true);</code> | 测试断言：Synchronize(nullptr);Check(true);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 66 | <code> for(uint8 race:{uint8(39),uint8(49)}){</code> | 循环：for(uint8 race:{uint8(39),uint8(49)})；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 67 | <code>  auto const* profile=RebornCoaBirth::FindProfile(race,1);uint32 lang=profile-&gt;LanguageSkill,spell=profile-&gt;LanguageSpell;</code> | 调用FindProfile（查39/49战士的固定语言/阵营契约，找不到返回空）；此行参数来自当前上下文。 |
| 68 | <code>  for(int gate=0;gate&lt;13;++gate){Setup(race);Player p;p.race=race;</code> | 循环：for(int gate=0;gate<13;++gate){Setup(race);Player p;p.race=race;；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 69 | <code>   switch(gate){case 0:cfg=false;break;case 1:sChrRacesStore.rows.clear();break;case 2:sChrRacesStore.rows[race].Flags=4;break;case 3:sChrRacesStore.rows[race].alliance^=1;break;</code> | 调用clear（清空测试状态、确认职业/天赋组，防止上一测试污染下一测试）；此行参数来自当前上下文。 |
| 70 | <code>    case 4:races.max=race;break;case 5:masks[race]=0;break;case 6:reps[race]=profile-&gt;AliasMask;break;case 7:objects.infos.erase(race);break;case 8:objects.infos.erase(profile-&gt;TemplateRace);break;</code> | 枚举当前允许的技能/种族分支：case 4:races.max=race;break;case 5:masks[race]=0;break;case 6:reps[race]=profile->AliasMask;break;case 7:objects.infos.erase(race);break;case 8:objects.infos.erase(profile->TemplateRace);break;；这些编号的含义见核心参数表，仍需模板行存在。 |
| 71 | <code>    case 9:eligible.erase({race,lang});break;case 10:spells.spells.erase(spell);break;case 11:spells.abilities.clear();break;case 12:p.fit=false;break;}</code> | 枚举当前允许的技能/种族分支：case 9:eligible.erase({race,lang});break;case 10:spells.spells.erase(spell);break;case 11:spells.abilities.clear();break;case 12:p.fit=false;break;}；这些编号的含义见核心参数表，仍需模板行存在。 |
| 72 | <code>   Synchronize(&amp;p);NoChange(p);</code> | 调用Synchronize（只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望）、NoChange（验证被拒绝的玩家没有获得任何语言/技能副作用）；此行参数来自当前上下文。 |
| 73 | <code>  }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 74 | <code>  Setup(race);Player p;p.race=race;eligible.erase({race,55});Synchronize(&amp;p);NoChange(p);</code> | 调用Synchronize（只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望）、Setup（准备某种族的最小合法测试依赖，再故意缺某项验证拒绝）、NoChange（验证被拒绝的玩家没有获得任何语言/技能副作用）；此行参数来自当前上下文。 |
| 75 | <code>  Setup(race);p=Player{};p.race=race;p.learnFails=true;Synchronize(&amp;p);Check(p.skills.empty()&amp;&amp;!p.defaults&amp;&amp;p.learns==1);</code> | 测试断言：Setup(race);p=Player{};p.race=race;p.learnFails=true;Synchronize(&p);Check(p.skills.empty()&&!p.defaults&&p.learns==1);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 76 | <code>  Setup(race);p=Player{};p.race=race;p.skills[43]={193,300};p.skills[129]={375,450};</code> | 调用Setup（准备某种族的最小合法测试依赖，再故意缺某项验证拒绝）；此行参数来自当前上下文。 |
| 77 | <code>  RebornCoaBirthPlayerScript script;script.OnPlayerCreate(&amp;p);</code> | 调用OnPlayerCreate（服务器建角回调，此时物品已分配，所以它不能解决创建前穿装资格）；此行参数来自当前上下文。 |
| 78 | <code>  Check(p.HasSpell(spell)&amp;&amp;p.skills[lang]==std::make_pair(uint32(300),uint32(300)));</code> | 测试断言：Check(p.HasSpell(spell)&&p.skills[lang]==std::make_pair(uint32(300),uint32(300)));。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 79 | <code>  Check(p.skills[43]==std::make_pair(uint32(193),uint32(300))&amp;&amp;p.skills[129].first==375);</code> | 测试断言：Check(p.skills[43]==std::make_pair(uint32(193),uint32(300))&&p.skills[129].first==375);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 80 | <code>  Check(!p.HasSkill(762)&amp;&amp;!p.HasSkill(118)&amp;&amp;!p.HasSkill(293)&amp;&amp;!p.HasSkill(183));</code> | 测试断言：Check(!p.HasSkill(762)&&!p.HasSkill(118)&&!p.HasSkill(293)&&!p.HasSkill(183));。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 81 | <code>  Check(!p.HasSkill(race==39?109:98));</code> | 测试断言：Check(!p.HasSkill(race==39?109:98));。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 82 | <code>  auto oldSkills=p.skills;auto oldKnown=p.known;int oldSets=p.sets,oldDefaults=p.defaults,oldLearns=p.learns;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`auto oldSkills=p.skills;auto oldKnown=p.known;int oldSets=p.sets,oldDefaults=p.defaults,oldLearns=p.learns;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 83 | <code>  for(int i=0;i&lt;100;++i)script.OnPlayerLogin(&amp;p);</code> | 循环：for(int i=0;i<100;++i)script.OnPlayerLogin(&p);；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 84 | <code>  Check(p.skills==oldSkills&amp;&amp;p.known==oldKnown&amp;&amp;p.sets==oldSets&amp;&amp;p.defaults==oldDefaults&amp;&amp;p.learns==oldLearns);</code> | 测试断言：Check(p.skills==oldSkills&&p.known==oldKnown&&p.sets==oldSets&&p.defaults==oldDefaults&&p.learns==oldLearns);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 85 | <code>  Setup(race);p=Player{};p.race=race;p.known.insert(spell);p.skills[lang]={300,300};script.OnPlayerLogin(&amp;p);Check(!p.learns&amp;&amp;!p.sets);</code> | 测试断言：Setup(race);p=Player{};p.race=race;p.known.insert(spell);p.skills[lang]={300,300};script.OnPlayerLogin(&p);Check(!p.learns&&!p.sets);。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 86 | <code>  for(uint8 cls:{uint8(2),uint8(13),uint8(14),uint8(15)}){Setup(race);p=Player{};p.race=race;p.cls=cls;Synchronize(&amp;p);NoChange(p);}</code> | 循环：for(uint8 cls:{uint8(2),uint8(13),uint8(14),uint8(15)}){Setup(race);p=Player{};p.race=race;p.cls=cls;Synchronize(&p);NoChange(p);}；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 87 | <code> }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 88 | <code> Setup(39);for(uint8 race:{uint8(0),uint8(1),uint8(2),uint8(7),uint8(17),uint8(36),uint8(37),uint8(113)}){Player p;p.race=race;Synchronize(&amp;p);NoChange(p);}</code> | 调用Synchronize（只给目标玩家补缺语言和基础技能，不发装备、不清空熟练度或声望）、Setup（准备某种族的最小合法测试依赖，再故意缺某项验证拒绝）、NoChange（验证被拒绝的玩家没有获得任何语言/技能副作用）；此行参数来自当前上下文。 |
| 89 | <code> for(uint32 id=0;id&lt;1000;++id){bool allowed=RebornCoaBirth::IsBasicSkill(id);if(id==98&#124;&#124;id==109&#124;&#124;id==129&#124;&#124;id==118&#124;&#124;id==183&#124;&#124;id==293&#124;&#124;id==762)Check(!allowed);}</code> | 枚举技能ID验证白名单边界，特别是语言/专业/骑乘等不准通过。 |
| 90 | <code> std::cout&lt;&lt;"PASS "&lt;&lt;checks&lt;&lt;" actual module-body/API-substitute checks, including 200 repeated logins\n";</code> | 把测试结果/计数输出为证据；前面的断言都没失败才能走到这里。 |
| 91 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 92 | <code>'''</code> | 此行属于“void NoChange(Player& p)”：`'''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 93 | <code>(W/'module_fixture.cpp').write_text(stub+'\n'+body+'\n'+main,encoding='utf8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 94 | <code>cmd='call "D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat" &gt;NUL &amp;&amp; cl /nologo /EHsc /std:c++20 /utf-8 /MD /Fe:"'+str(W/'module_fixture.exe')+'" /Fo:"'+str(W/'module_fixture.obj')+'" "'+str(W/'module_fixture.cpp')+'"'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`cmd='call "D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat" >NUL && cl /nologo /EHsc /std:c++20 /utf-8 /MD /Fe:"'+str(W/'module_fixture.exe')+'" /Fo:"'+str(W/'module_fixture.obj')+'" "'+str(W/'module_fixture.cpp')+'"'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 95 | <code>(W/'fixture.cmd').write_text('@echo off\n'+cmd+'\n',encoding='ascii')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 96 | <code>q=subprocess.run(['cmd.exe','/d','/c',str(W/'fixture.cmd')],capture_output=True);(W/'fixture_build.log').write_bytes(q.stdout+q.stderr);assert q.returncode==0,q.stdout.decode(errors='replace')+q.stderr.decode(errors='replace')</code> | 收集命令标准输出和错误到证据，不靠屏幕一闪而过判断成功。 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
| 97 | <code>q=subprocess.run([str(W/'module_fixture.exe')],capture_output=True);assert q.returncode==0,(q.returncode,q.stdout,q.stderr)</code> | 收集命令标准输出和错误到证据，不靠屏幕一闪而过判断成功。 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 |
| 98 | <code>(W/'fixture_result.txt').write_bytes(q.stdout);print(q.stdout.decode(),end='')</code> | 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
