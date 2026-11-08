# 测试_test_birth_order.py：逐行讲解
实际测试原件逐行；Python路径保持当时输入，不保证当前可直接执行。C++夹具是生产函数加API替身，不是完整游戏引擎。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261106\codexwork_RACEJOINT1A\test_birth_order.py`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `IsRaceMaskAlias` | 判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同 |
| `IsRaceMaskable` | 判断是否允许走32位掩码运算，避免把36/37误卷入 |
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `GetRaceAliasTemplateRace` | 只把39映射到人类1、49映射到兽人2；其它返回0 |
| `decode` | 读取WDBC头和行区；检查文件长度以免写出损坏表 |
| `func` | 按花括号摘取实际生产函数体，不另抄一份理想化实现 |
| `run` | 在专用测试库执行SQL并检查预期成功/失败，绝不是生产执行器 |
| `HasSkill` | 检查已有技能，防止覆盖练过的熟练度 |
| `HasSpell` | 检查已学法术，保证重复登录不会重复授予 |
| `SetSkill` | 设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器 |
| `LearnDefaultSkill` | 沿核心默认技能学习路径授予模板已有基础技能，不强制练满 |

## 原代码
```python
from pathlib import Path
import subprocess,json
W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))
cpp=(W/'source/src/server/game/Entities/Player/Player.cpp').read_text(encoding='utf-8')
start=cpp.index('    if (uint8 templateRace = GetRaceAliasTemplateRace(getRace()))');pos=cpp.index('{',start);depth=1;end=pos+1
while depth:
 if cpp[end]=='{':depth+=1
 if cpp[end]=='}':depth-=1
 end+=1
block=cpp[start:end]
h=(W/'source/src/server/shared/SharedDefines.h').read_text(encoding='utf-8')
def func(name):
 start=h.index('inline constexpr ',h.index(name)-40);brace=h.index('{',start);end=brace+1;depth=1
 while depth:
  if h[end]=='{':depth+=1
  if h[end]=='}':depth-=1
  end+=1
 return h[start:end]
helpers='\n'.join(func(n) for n in ['IsRaceMaskAlias(','IsRaceMaskable(','GetRaceMaskForRace(','GetRaceAliasTemplateRace('])
stub=r'''
#include <cstdint>
#include <map>
#include <set>
#include <vector>
#include <cassert>
#include <iostream>
using uint8=std::uint8_t;using uint32=std::uint32_t;
enum {RACE_NONE=0,RACE_HUMAN=1,RACE_ORC=2,RACE_KUL_TIRAN=39,RACE_MAGHAR_ORC=49,CLASS_WARRIOR=1,SKILL_LANG_COMMON=98,SKILL_LANG_ORCISH=109};
'''+helpers+r'''
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
'''+block+r'''
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
'''
(W/'birth_order_fixture.cpp').write_text(stub,encoding='utf-8')
script='@echo off\r\ncall D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat >nul\r\ncd /d '+str(W)+'\r\ncl /nologo /EHsc /std:c++20 /Z7 /MD /Fe:birth_order_fixture.exe /Fo:birth_order_fixture.obj birth_order_fixture.cpp\r\n'
(W/'test_birth_order.cmd').write_bytes(script.encode('ascii'))
q=subprocess.run(['cmd.exe','/d','/c',str(W/'test_birth_order.cmd')],capture_output=True);(W/'birth_order_compile.log').write_bytes(q.stdout+q.stderr);assert q.returncode==0,(q.stdout,q.stderr)
q=subprocess.run([str(W/'birth_order_fixture.exe')],capture_output=True);assert q.returncode==0,(q.stdout,q.stderr)
(P/'checks/birth_order_test.txt').write_bytes(q.stdout);print(q.stdout.decode())
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 2 | <code>import subprocess,json</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 4 | <code>cpp=(W/'source/src/server/game/Entities/Player/Player.cpp').read_text(encoding='utf-8')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 5 | <code>start=cpp.index('    if (uint8 templateRace = GetRaceAliasTemplateRace(getRace()))');pos=cpp.index('{',start);depth=1;end=pos+1</code> | 调用GetRaceAliasTemplateRace（只把39映射到人类1、49映射到兽人2；其它返回0）；此行参数来自当前上下文。 |
| 6 | <code>while depth:</code> | 循环：while depth；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 7 | <code> if cpp[end]=='{':depth+=1</code> | 条件分支：只有`if cpp[end]=='`成立才走随后分支；不满足进入else/跳过。 |
| 8 | <code> if cpp[end]=='}':depth-=1</code> | 条件分支：只有`if cpp[end]=='}':depth-=1`成立才走随后分支；不满足进入else/跳过。 |
| 9 | <code> end+=1</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`end+=1`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 10 | <code>block=cpp[start:end]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`block=cpp[start:end]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 11 | <code>h=(W/'source/src/server/shared/SharedDefines.h').read_text(encoding='utf-8')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 12 | <code>def func(name):</code> | 定义/进入函数：按花括号摘取实际生产函数体，不另抄一份理想化实现。 |
| 13 | <code> start=h.index('inline constexpr ',h.index(name)-40);brace=h.index('{',start);end=brace+1;depth=1</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`start=h.index('inline constexpr ',h.index(name)-40);brace=h.index('{',start);end=brace+1;depth=1`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 14 | <code> while depth:</code> | 循环：while depth；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 15 | <code>  if h[end]=='{':depth+=1</code> | 条件分支：只有`if h[end]=='`成立才走随后分支；不满足进入else/跳过。 |
| 16 | <code>  if h[end]=='}':depth-=1</code> | 条件分支：只有`if h[end]=='}':depth-=1`成立才走随后分支；不满足进入else/跳过。 |
| 17 | <code>  end+=1</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`end+=1`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 18 | <code> return h[start:end]</code> | 返回表达式`h[start:end]`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 19 | <code>helpers='\n'.join(func(n) for n in ['IsRaceMaskAlias(','IsRaceMaskable(','GetRaceMaskForRace(','GetRaceAliasTemplateRace('])</code> | 调用IsRaceMaskAlias（判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同）、IsRaceMaskable（判断是否允许走32位掩码运算，避免把36/37误卷入）、GetRaceMaskForRace（将真实race映射为旧接口资格位；36/37仍返回0）；此行参数来自当前上下文。 |
| 20 | <code>stub=r'''</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`stub=r'''`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 21 | <code>#include &lt;cstdint&gt;</code> | 引入<cstdint>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 22 | <code>#include &lt;map&gt;</code> | 引入<map>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 23 | <code>#include &lt;set&gt;</code> | 引入<set>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 24 | <code>#include &lt;vector&gt;</code> | 引入<vector>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 25 | <code>#include &lt;cassert&gt;</code> | 引入<cassert>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 26 | <code>#include &lt;iostream&gt;</code> | 引入<iostream>的声明；编译器才能识别这里使用的类型/接口，不是运行时加载资源。 |
| 27 | <code>using uint8=std::uint8_t;using uint32=std::uint32_t;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`using uint8=std::uint8_t;using uint32=std::uint32_t;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 28 | <code>enum {RACE_NONE=0,RACE_HUMAN=1,RACE_ORC=2,RACE_KUL_TIRAN=39,RACE_MAGHAR_ORC=49,CLASS_WARRIOR=1,SKILL_LANG_COMMON=98,SKILL_LANG_ORCISH=109};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`enum {RACE_NONE=0,RACE_HUMAN=1,RACE_ORC=2,RACE_KUL_TIRAN=39,RACE_MAGHAR_ORC=49,CLASS_WARRIOR=1,SKILL_LANG_COMMON=98,SKILL_LANG_ORCISH=109};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 29 | <code>'''+helpers+r'''</code> | 此行属于“def func(name):”：`'''+helpers+r'''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 30 | <code>static_assert(GetRaceMaskForRace(36)==0&amp;&amp;GetRaceMaskForRace(37)==0);</code> | 编译期断言：掩码常量若被误改，连测试程序都不能编译成功。 |
| 31 | <code>static_assert(GetRaceMaskForRace(39)==64&amp;&amp;GetRaceMaskForRace(49)==65536);</code> | 编译期断言：掩码常量若被误改，连测试程序都不能编译成功。 |
| 32 | <code>struct Skill{uint32 SkillId,Rank;};struct PlayerInfo{std::vector&lt;Skill&gt; skills;};</code> | 声明代码组织/数据类型：struct Skill{uint32 SkillId,Rank;};struct PlayerInfo{std::vector<Skill> skills;};；把同类规则或测试替身成员放一起。 |
| 33 | <code>struct ObjectMgr{std::map&lt;uint8,PlayerInfo&gt; info;PlayerInfo const* GetPlayerInfo(uint8 race,uint8){return &amp;info[race];}} obj,*sObjectMgr=&amp;obj;</code> | 声明代码组织/数据类型：struct ObjectMgr{std::map<uint8,PlayerInfo> info;PlayerInfo const* GetPlayerInfo(uint8 race,uint8){return &info[race];}} obj,*sObjectMgr=&obj;；把同类规则或测试替身成员放一起。 |
| 34 | <code>enum{SPEC_MASK_ALL=3};int grants=0;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`enum{SPEC_MASK_ALL=3};int grants=0;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 35 | <code>struct Player{</code> | 声明代码组织/数据类型：struct Player{；把同类规则或测试替身成员放一起。 |
| 36 | <code> uint8 race=39,cls=1;bool world=false;std::map&lt;uint32,uint32&gt; skills;std::set&lt;uint32&gt; spells;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`uint8 race=39,cls=1;bool world=false;std::map<uint32,uint32> skills;std::set<uint32> spells;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 37 | <code> uint8 getRace(){return race;}uint8 getClass(){return cls;}bool HasSkill(uint32 s){return skills.count(s);}bool HasSpell(uint32 s){return spells.count(s);}bool IsInWorld(){return world;}</code> | 调用HasSkill（检查已有技能，防止覆盖练过的熟练度）、HasSpell（检查已学法术，保证重复登录不会重复授予）；此行参数来自当前上下文。 |
| 38 | <code> void LearnDefaultSkill(uint32 s,uint32){skills[s]=1;++grants;}</code> | 定义/进入函数：沿核心默认技能学习路径授予模板已有基础技能，不强制练满。 |
| 39 | <code> void SetSkill(uint32 s,uint32,uint32 v,uint32){skills[s]=v;++grants;}</code> | 定义/进入函数：设置单个技能阶段/当前值/上限；本案语言用300/300，不能套用所有武器。 |
| 40 | <code> void addSpell(uint32 s,uint32,bool){spells.insert(s);++grants;}void learnSpell(uint32 s){spells.insert(s);++grants;}</code> | 此行属于“void addSpell(uint32 s,uint32,bool)”：`void addSpell(uint32 s,uint32,bool){spells.insert(s);++grants;}void learnSpell(uint32 s){spells.insert(s);++grants;}`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 41 | <code> void LearnBeforeItems(){</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 |
| 42 | <code>'''+block+r'''</code> | 此行属于“void LearnBeforeItems()”：`'''+block+r'''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 43 | <code> }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 44 | <code>};</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 45 | <code>int main(){</code> | 此行属于“void LearnBeforeItems()”：`int main(){`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 46 | <code> for(auto race:{39,49})for(auto world:{false,true}){</code> | 循环：for(auto race:{39,49})for(auto world:{false,true})；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 47 | <code>  obj.info[1].skills={{26,0},{43,0},{413,0},{98,0},{118,0},{129,1},{183,0},{762,0}};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`obj.info[1].skills={{26,0},{43,0},{413,0},{98,0},{118,0},{129,1},{183,0},{762,0}};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 48 | <code>  obj.info[2].skills={{26,0},{44,0},{413,0},{109,0},{118,0},{129,1},{183,0},{762,0}};</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`obj.info[2].skills={{26,0},{44,0},{413,0},{109,0},{118,0},{129,1},{183,0},{762,0}};`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 49 | <code>  Player p;p.race=race;p.world=world;p.skills[43]=193;p.skills[129]=375;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`Player p;p.race=race;p.world=world;p.skills[43]=193;p.skills[129]=375;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 50 | <code>  p.LearnBeforeItems();auto lang=race==39?98:109,spell=race==39?668:669;</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 |
| 51 | <code>  assert(p.HasSkill(413)&amp;&amp;p.HasSkill(race==39?43:44));</code> | 断言这行写出的条件必须成立：assert(p.HasSkill(413)&&p.HasSkill(race==39?43:44));；否则立刻停测，不能继续记通过。 |
| 52 | <code>  assert(p.skills[43]==193&amp;&amp;p.skills[129]==375);</code> | 预置剑熟练度193和专业375必须保留，不能被初始化重置。 |
| 53 | <code>  assert(p.skills[lang]==300&amp;&amp;p.HasSpell(spell));</code> | 断言这行写出的条件必须成立：assert(p.skills[lang]==300&&p.HasSpell(spell));；否则立刻停测，不能继续记通过。 |
| 54 | <code>  assert(!p.HasSkill(race==39?109:98)&amp;&amp;!p.HasSkill(118)&amp;&amp;!p.HasSkill(183)&amp;&amp;!p.HasSkill(762));</code> | 断言这行写出的条件必须成立：assert(!p.HasSkill(race==39?109:98)&&!p.HasSkill(118)&&!p.HasSkill(183)&&!p.HasSkill(762));；否则立刻停测，不能继续记通过。 |
| 55 | <code>  auto old=p.skills;auto spells=p.spells;auto g=grants;</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`auto old=p.skills;auto spells=p.spells;auto g=grants;`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 56 | <code>  for(int i=0;i&lt;100;i++)p.LearnBeforeItems();</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 |
| 57 | <code>  assert(p.skills==old&amp;&amp;p.spells==spells&amp;&amp;grants==g);</code> | 重复调用后授予计数不得变化，证明幂等，不是每次登录再发奖励。 |
| 58 | <code> }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 59 | <code> for(auto r:{1,2,7,17,36,37}){Player p;p.race=r;auto g=grants;p.LearnBeforeItems();assert(p.skills.empty()&amp;&amp;p.spells.empty()&amp;&amp;grants==g);}</code> | 测试方法嵌入真实Player.cpp代码块，在物品模拟前检查基础穿装资格。 重复调用后授予计数不得变化，证明幂等，不是每次登录再发奖励。 |
| 60 | <code> std::cout&lt;&lt;"PASS actual Player.cpp alias initialization block: 4 race/world combinations, 400 repeated calls, no parent racials or other language, old 36/37 unaffected; mask static_asserts\n";</code> | 编译期断言：掩码常量若被误改，连测试程序都不能编译成功。 |
| 61 | <code>}</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 62 | <code>'''</code> | 此行属于“void LearnBeforeItems()”：`'''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 63 | <code>(W/'birth_order_fixture.cpp').write_text(stub,encoding='utf-8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 64 | <code>script='@echo off\r\ncall D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat &gt;nul\r\ncd /d '+str(W)+'\r\ncl /nologo /EHsc /std:c++20 /Z7 /MD /Fe:birth_order_fixture.exe /Fo:birth_order_fixture.obj birth_order_fixture.cpp\r\n'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`script='@echo off\r\ncall D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat >nul\r\ncd /d '+str(W)+'\r\ncl /nologo /EHsc /std:c++20 /Z7 /MD /Fe:birth_order_fixture.exe /Fo:birth_order_fixture.obj birth_order_fixture.cpp\r\n'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 65 | <code>(W/'test_birth_order.cmd').write_bytes(script.encode('ascii'))</code> | 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
| 66 | <code>q=subprocess.run(['cmd.exe','/d','/c',str(W/'test_birth_order.cmd')],capture_output=True);(W/'birth_order_compile.log').write_bytes(q.stdout+q.stderr);assert q.returncode==0,(q.stdout,q.stderr)</code> | 收集命令标准输出和错误到证据，不靠屏幕一闪而过判断成功。 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
| 67 | <code>q=subprocess.run([str(W/'birth_order_fixture.exe')],capture_output=True);assert q.returncode==0,(q.stdout,q.stderr)</code> | 收集命令标准输出和错误到证据，不靠屏幕一闪而过判断成功。 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 |
| 68 | <code>(P/'checks/birth_order_test.txt').write_bytes(q.stdout);print(q.stdout.decode())</code> | 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
