# 测试_test_joint.py：逐行讲解
实际测试原件逐行；Python路径保持当时输入，不保证当前可直接执行。C++夹具是生产函数加API替身，不是完整游戏引擎。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261106\codexwork_RACEJOINT1A\test_joint.py`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `IsWarriorOnlyNewRace` | 圈定39/49首批战士限制，供服务器最终拒绝非法组合 |
| `LearnDefaultSkills` | 学基础技能；这一步位于出生物品之前，决定装备能否直接穿上 |
| `SetBackgroundModel` | 选择Glue舞台背景；只对CharacterSelect做场景token别名 |
| `Open` | 上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它 |
| `check` | 断言结果必须成立，并累积一条检查；失败立即停止 |
| `decode` | 读取WDBC头和行区；检查文件长度以免写出损坏表 |
| `words` | 把二进制行按32位无符号整数展开，便于按字段断言 |

## 原代码
```python
from pathlib import Path
import json,struct,hashlib
from lupa.lua51 import LuaRuntime
W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))
CL=P/'B_客户端_整合候选/交付/02_MPQ导入目录/导入PATCH-YB'
checks=[]
def check(v,s):assert v,s;checks.append(s)
def decode(b):
 n,nf,rs,ss=struct.unpack_from('<4I',b,4);assert len(b)==20+n*rs+ss
 return [b[20+i*rs:20+(i+1)*rs] for i in range(n)],b[20+n*rs:],rs
def words(b):return struct.unpack('<'+'I'*(len(b)//4),b)
for f in CL.rglob('*.lua'):
 l=LuaRuntime();ok,err=l.eval('function(s)local f,e=loadstring(s);return f~=nil,e end')(f.read_text(encoding='utf-8-sig'));check(ok,'Lua 5.1 syntax '+f.name+str(err or ''))
# Reuse original race-state fixture, point it at NEW delivered Lua only.
fixture=(R/'000Ascendupdate/000Ascendupdate20261105/codexwork_RACEFIX1A/test_raceui.py').read_text(encoding='utf-8').split("g=(base/")[0]
fixture=fixture.replace("t=(base/'导入Patch-YB.mpq/Interface/GlueXML/CharacterCreate.lua').read_text(encoding='utf8')",'t='+repr((CL/'Interface/GlueXML/CharacterCreate.lua').read_text(encoding='utf-8')))
# Fixture initialization paths may be empty; syntax is checked above for actual deliveries.
exec(compile(fixture,str(W/'test_joint.py'),'exec'))
W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))
L.execute('''
local F=getmetatable(CharCreateClassButton3)
function F:GetNormalTexture()return self.normal end
function F:GetPushedTexture()return self.pushed end
function F:SetChecked(v)self.checked=not not v end
function F:SetDesaturated(v)assert(type(v)=="boolean");self.desaturated=v end
function F:SetTextColor(r,g,b)self.rgb={r,g,b}end
for i=1,3 do local b=_G["CharCreateClassButton"..i];b.normal=_G["CharCreateClassButton"..i.."NormalTexture"];b.pushed=_G["CharCreateClassButton"..i.."PushedTexture"];b.selection=Widget()end
CharCreateMonkButton=Widget();CharCreateWitchDoctorPreviewButton=Widget();CharCreateWitchHunterPreviewButton=Widget()
for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do b.normal=Widget();b.pushed=Widget();b.ascendNeutralRing=Widget();b.selection=Widget()end
function GetAvailableRaces()return "人类","Human",1,"未开放","NightElf",1,"蛇人","REBORNSETHRAK",1,"兽人","Orc",1,"食人魔","REBORNOGRE",1,"库尔提拉斯","REBORNKULTIRAN",1,"玛格汉","Maghar",1 end
function GetBGluSpecil(...)if race==1 then return {1,2,3}elseif race==4 then return {1,3}else return {}end end
function CharacterCreate_GetSafeRaceId(v)return v end
function GetAvailableClasses()return "法师","MAGE",1,"盗贼","ROGUE",1,"战士","WARRIOR",(race~=1 and race~=4)and 0 or 1 end
function CharacterRace_OnClick(_,id)race=id;CharacterCreate.selectedRace=id;CharacterCreateEnumerateClasses(GetAvailableClasses());SetCharacterClass(1)end
function SetCharacterGender(v)sex=v;CharacterCreateEnumerateClasses(GetAvailableClasses());SetCharacterClass(classIndex)end
function SetSelectedRace(v)race=v end
function SetSelectedSex(v)sex=v end
function SetCharacterRace(v)CharacterCreate.selectedRace=v end
function SetCharacterCreateFacing(v)end
CharacterCreate.backgroundRaceByListId={}
''')
start=t.index('function SetButtonDesaturated(button, desaturated)');end=t.index('\nfunction GetFlavorText(',start)
L.execute(t[start:end]);L.execute(helper+t[t.index('-- RACEUI1B: class button state'):])
v=(CL/'Interface/GlueXML/RebornRacePreview.lua').read_text(encoding='utf-8')
start=v.index('local function Open(e, sex)');end=v.index('\nlocal function Hook()',start)
L.globals().newOpen=L.execute('local bs,A,B={}\n'+v[start:end]+'\nreturn Open')
L.execute('''
for iteration=1,100 do
 for _,e in ipairs({{f="HUMAN"},{f="NIGHTELF"},{f="REBORNKULTIRAN"},{f="REBORNSETHRAK"},{f="ORC"},{f="MAGHAR",horde=true},{f="REBORNOGRE",horde=true}})do
  for _,s in ipairs({2,3})do
   newOpen(e,s)
   local managed=race==3 or race==5 or race==6 or race==7
   local allowed=managed and {[3]=true}or race==1 and {[1]=true,[2]=true,[3]=true}or race==4 and {[1]=true,[3]=true}or{}
   for i=1,3 do local b=_G["CharCreateClassButton"..i];assert(b.enabled==not not allowed[i]);assert(b.normal.desaturated==not allowed[i]);assert(not b.selection.shown)end
   if managed then
    assert(classIndex==3)
    for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do assert(not b.enabled and b.normal.desaturated)end
   end
  end
 end
end
''');checks.append('1400 actual V56 Open transitions: old/undeveloped/36/37/39/49, sexes, Warrior-only, detached buttons, no long selection rectangle')
L.execute('''for _,r in ipairs({6,7})do for _,s in ipairs({2,3})do CharacterCreate.selectedRace=r;race=r;sex=s;nativeName=nil;edit="old";CharacterCreate_GenerateRandomName();assert(edit~="old"and edit~="");local prev=edit;CharacterCreate_GenerateRandomName();assert(edit~=prev)end end''');checks.append('39/49 male/female random name fallback')
L.execute('''for _,r in ipairs({6,7})do CharacterCreate.selectedRace=r;race=r;classIndex=1;local prev=nativeCalls;CreateCharacter("bad");assert(nativeCalls==prev);classIndex=3;CreateCharacter("ok");assert(nativeCalls==prev+1)end''');checks.append('39/49 final CreateCharacter guard rejects stale class, accepts Warrior')
g=(CL/'Interface/GlueXML/GlueParent.lua').read_text(encoding='utf-8');start=g.index('function SetBackgroundModel(model, name, raza, zoom, gender)');end=g.index('\nfunction SetBackgroundModelRespaldo',start)
L.execute('CharacterSelect={};CharacterCreate={};strupper=string.upper;function SetCharSelectBackground(v)scene=v end;function SetLighting(...)end')
L.execute(g[start:end])
for token,scene in [('REBORNKULTIRAN','ui_kultiran'),('MAGHAR','UI_Troll')]:
 L.globals().SetBackgroundModel(L.globals().CharacterSelect,token)
 check(L.globals().scene=='Interface\\Glues\\Models\\'+scene+'\\'+scene+'.m2','actual character selection scene alias '+token)
# DBC preservation against each independent input.
manifest=json.loads((P/'checks/input_output_manifest.json').read_text(encoding='utf-8'))
for m in manifest:
 if not m['relative'].endswith('.dbc'):continue
 comp=P/m['component'];old=(comp/'backup_原文件'/m['relative']).read_bytes();new=(comp/'交付'/m['relative']).read_bytes();a,ast,rs=decode(old);b,bst,_=decode(new);bset=set(b)
 if rs==2:
  check([r for r in a if r[0] not in [39,49]]==[r for r in b if r[0] not in [39,49]],m['relative']+' other combinations preserved')
  check([tuple(r) for r in b if r[0] in [39,49]]==[(39,1),(49,1)],m['relative']+' Warrior only')
 elif 'ChrRaces' in m['relative']:
  check(all(row in bset for row in a if words(row)[0] not in [39,49]),m['relative']+' other races untouched')
  for r in [39,49]:check(not(words(next(x for x in b if words(x)[0]==r))[1]&4),m['relative']+' playable '+str(r))
 else:check(all(row in bset for row in a)and bst.startswith(ast),m['relative']+' all existing records/strings preserved')
 if 'CharStartOutfit' in m['relative']:
  for race,parent in [(39,1),(49,2)]:
   for sex in [0,1]:
    donor=next(x for x in a if tuple(x[4:7])==(parent,1,sex));row=next(x for x in b if tuple(x[4:7])==(race,1,sex))
    check(row[5:]==donor[5:],m['relative']+' same-sex parent items '+str((race,sex)))
cpp=(W/'source/src/server/game/Entities/Player/Player.cpp').read_text(encoding='utf-8')
check(cpp.index('    LearnDefaultSkills();')<cpp.index('    LearnCustomSpells();')<cpp.index('if (CharStartOutfitEntry const*'), 'real Player::Create skill/custom spell initialization precedes outfit distribution')
handler=(W/'source/src/server/game/Handlers/CharacterHandler.cpp').read_text(encoding='utf-8')
check('IsWarriorOnlyNewRace(createInfo->Race) && createInfo->Class != CLASS_WARRIOR' in handler,'server Warrior guard exists')
(P/'checks/joint_tests.json').write_text(json.dumps({'checks':checks,'count':len(checks),'boundary':'Actual Lua function bodies with engine/widgets substituted; binary DBC assertions; no game run.'},ensure_ascii=False,indent=2),encoding='utf-8')
print('PASS',len(checks),'groups and 1400 actual Open checkpoints')
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 2 | <code>import json,struct,hashlib</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>from lupa.lua51 import LuaRuntime</code> | 创建Lua5.1运行器，用替身API执行实际插件/Glue函数。 |
| 4 | <code>W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 5 | <code>CL=P/'B_客户端_整合候选/交付/02_MPQ导入目录/导入PATCH-YB'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`CL=P/'B_客户端_整合候选/交付/02_MPQ导入目录/导入PATCH-YB'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 6 | <code>checks=[]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`checks=[]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 7 | <code>def check(v,s):assert v,s;checks.append(s)</code> | 定义/进入函数：断言结果必须成立，并累积一条检查；失败立即停止。 |
| 8 | <code>def decode(b):</code> | 定义/进入函数：读取WDBC头和行区；检查文件长度以免写出损坏表。 |
| 9 | <code> n,nf,rs,ss=struct.unpack_from('&lt;4I',b,4);assert len(b)==20+n*rs+ss</code> | 按明确二进制结构解WDBC头/行，防止字符串区或行宽错位。 |
| 10 | <code> return [b[20+i*rs:20+(i+1)*rs] for i in range(n)],b[20+n*rs:],rs</code> | 返回表达式`[b[20+i*rs:20+(i+1)*rs] for i in range(n)],b[20+n*rs:],rs`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 11 | <code>def words(b):return struct.unpack('&lt;'+'I'*(len(b)//4),b)</code> | 按明确二进制结构解WDBC头/行，防止字符串区或行宽错位。 |
| 12 | <code>for f in CL.rglob('*.lua'):</code> | 循环：for f in CL.rglob('*.lua')；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 13 | <code> l=LuaRuntime();ok,err=l.eval('function(s)local f,e=loadstring(s);return f~=nil,e end')(f.read_text(encoding='utf-8-sig'));check(ok,'Lua 5.1 syntax '+f.name+str(err or ''))</code> | Lua5.1先解析实际文件抓语法错误；通过不等于游戏接口或模型运行通过。 创建Lua5.1运行器，用替身API执行实际插件/Glue函数。 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 14 | <code># Reuse original race-state fixture, point it at NEW delivered Lua only.</code> | 说明注释：Reuse original race-state fixture, point it at NEW delivered Lua only.；它不执行，实际条件仍以相邻代码为准。 |
| 15 | <code>fixture=(R/'000Ascendupdate/000Ascendupdate20261105/codexwork_RACEFIX1A/test_raceui.py').read_text(encoding='utf-8').split("g=(base/")[0]</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 16 | <code>fixture=fixture.replace("t=(base/'导入Patch-YB.mpq/Interface/GlueXML/CharacterCreate.lua').read_text(encoding='utf8')",'t='+repr((CL/'Interface/GlueXML/CharacterCreate.lua').read_text(encoding='utf-8')))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 17 | <code># Fixture initialization paths may be empty; syntax is checked above for actual deliveries.</code> | 说明注释：Fixture initialization paths may be empty; syntax is checked above for actual deliveries.；它不执行，实际条件仍以相邻代码为准。 |
| 18 | <code>exec(compile(fixture,str(W/'test_joint.py'),'exec'))</code> | 此行属于“def words(b):return struct.unpack('<'+'I'*(len(b)//4),b)”：`exec(compile(fixture,str(W/'test_joint.py'),'exec'))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 19 | <code>W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 20 | <code>L.execute('''</code> | 此行属于“def words(b):return struct.unpack('<'+'I'*(len(b)//4),b)”：`L.execute('''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 21 | <code>local F=getmetatable(CharCreateClassButton3)</code> | 定义局部变量：local F=getmetatable(CharCreateClassButton3)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 22 | <code>function F:GetNormalTexture()return self.normal end</code> | 此行属于“function F:GetNormalTexture()return self.normal end”：`function F:GetNormalTexture()return self.normal end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 23 | <code>function F:GetPushedTexture()return self.pushed end</code> | 此行属于“function F:GetPushedTexture()return self.pushed end”：`function F:GetPushedTexture()return self.pushed end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 24 | <code>function F:SetChecked(v)self.checked=not not v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function F:SetChecked(v)self.checked=not not v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 25 | <code>function F:SetDesaturated(v)assert(type(v)=="boolean");self.desaturated=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function F:SetDesaturated(v)assert(type(v)=="boolean");self.desaturated=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 26 | <code>function F:SetTextColor(r,g,b)self.rgb={r,g,b}end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function F:SetTextColor(r,g,b)self.rgb={r,g,b}end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 27 | <code>for i=1,3 do local b=_G["CharCreateClassButton"..i];b.normal=_G["CharCreateClassButton"..i.."NormalTexture"];b.pushed=_G["CharCreateClassButton"..i.."PushedTexture"];b.selection=Widget()end</code> | 循环：for i=1,3 do local b=_G["CharCreateClassButton"..i];b.normal=_G["CharCreateClassButton"..i.."NormalTexture"];b.pushed=_G["CharCreateClassButton"..i.."PushedTexture"];b.selection=Widget()end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 28 | <code>CharCreateMonkButton=Widget();CharCreateWitchDoctorPreviewButton=Widget();CharCreateWitchHunterPreviewButton=Widget()</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`CharCreateMonkButton=Widget();CharCreateWitchDoctorPreviewButton=Widget();CharCreateWitchHunterPreviewButton=Widget()`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 29 | <code>for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do b.normal=Widget();b.pushed=Widget();b.ascendNeutralRing=Widget();b.selection=Widget()end</code> | 循环：for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do b.normal=Widget();b.pushed=Widget();b.ascendNeutralRing=Widget();b.selection=Widget()end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 30 | <code>function GetAvailableRaces()return "人类","Human",1,"未开放","NightElf",1,"蛇人","REBORNSETHRAK",1,"兽人","Orc",1,"食人魔","REBORNOGRE",1,"库尔提拉斯","REBORNKULTIRAN",1,"玛格汉","Maghar",1 end</code> | 此行属于“function GetAvailableRaces()return "人类","Human",1,"未开放","NightElf",1,"蛇人","REBORNSETHRAK",1,"兽人","Orc",1,"食人魔","REBORNOGRE",1,"库尔提拉斯","REBORNKULTIRAN",1,"玛格汉","Maghar",1 end”：`function GetAvailableRaces()return "人类","Human",1,"未开放","NightElf",1,"蛇人","REBORNSETHRAK",1,"兽人","Orc",1,"食人魔","REBORNOGRE",1,"库尔提拉斯","REBORNKULTIRAN",1,"玛格汉","Maghar",1 end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 31 | <code>function GetBGluSpecil(...)if race==1 then return {1,2,3}elseif race==4 then return {1,3}else return {}end end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function GetBGluSpecil(...)if race==1 then return {1,2,3}elseif race==4 then return {1,3}else return {}end end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 32 | <code>function CharacterCreate_GetSafeRaceId(v)return v end</code> | 此行属于“function CharacterCreate_GetSafeRaceId(v)return v end”：`function CharacterCreate_GetSafeRaceId(v)return v end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 33 | <code>function GetAvailableClasses()return "法师","MAGE",1,"盗贼","ROGUE",1,"战士","WARRIOR",(race~=1 and race~=4)and 0 or 1 end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function GetAvailableClasses()return "法师","MAGE",1,"盗贼","ROGUE",1,"战士","WARRIOR",(race~=1 and race~=4)and 0 or 1 end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 34 | <code>function CharacterRace_OnClick(_,id)race=id;CharacterCreate.selectedRace=id;CharacterCreateEnumerateClasses(GetAvailableClasses());SetCharacterClass(1)end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function CharacterRace_OnClick(_,id)race=id;CharacterCreate.selectedRace=id;CharacterCreateEnumerateClasses(GetAvailableClasses());SetCharacterClass(1)end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 35 | <code>function SetCharacterGender(v)sex=v;CharacterCreateEnumerateClasses(GetAvailableClasses());SetCharacterClass(classIndex)end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetCharacterGender(v)sex=v;CharacterCreateEnumerateClasses(GetAvailableClasses());SetCharacterClass(classIndex)end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 36 | <code>function SetSelectedRace(v)race=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetSelectedRace(v)race=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 37 | <code>function SetSelectedSex(v)sex=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetSelectedSex(v)sex=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 38 | <code>function SetCharacterRace(v)CharacterCreate.selectedRace=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetCharacterRace(v)CharacterCreate.selectedRace=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 39 | <code>function SetCharacterCreateFacing(v)end</code> | 此行属于“function SetCharacterCreateFacing(v)end”：`function SetCharacterCreateFacing(v)end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 40 | <code>CharacterCreate.backgroundRaceByListId={}</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`CharacterCreate.backgroundRaceByListId={}`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 41 | <code>''')</code> | 此行属于“function SetCharacterCreateFacing(v)end”：`''')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 42 | <code>start=t.index('function SetButtonDesaturated(button, desaturated)');end=t.index('\nfunction GetFlavorText(',start)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`start=t.index('function SetButtonDesaturated(button, desaturated)');end=t.index('\nfunction GetFlavorText(',start)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 43 | <code>L.execute(t[start:end]);L.execute(helper+t[t.index('-- RACEUI1B: class button state'):])</code> | 此行属于“function SetCharacterCreateFacing(v)end”：`L.execute(t[start:end]);L.execute(helper+t[t.index('-- RACEUI1B: class button state'):])`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 44 | <code>v=(CL/'Interface/GlueXML/RebornRacePreview.lua').read_text(encoding='utf-8')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 45 | <code>start=v.index('local function Open(e, sex)');end=v.index('\nlocal function Hook()',start)</code> | 调用Open（上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它）；此行参数来自当前上下文。 |
| 46 | <code>L.globals().newOpen=L.execute('local bs,A,B={}\n'+v[start:end]+'\nreturn Open')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`L.globals().newOpen=L.execute('local bs,A,B={}\n'+v[start:end]+'\nreturn Open')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 47 | <code>L.execute('''</code> | 此行属于“function SetCharacterCreateFacing(v)end”：`L.execute('''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 48 | <code>for iteration=1,100 do</code> | 循环：for iteration=1,100 do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 49 | <code> for _,e in ipairs({{f="HUMAN"},{f="NIGHTELF"},{f="REBORNKULTIRAN"},{f="REBORNSETHRAK"},{f="ORC"},{f="MAGHAR",horde=true},{f="REBORNOGRE",horde=true}})do</code> | 循环：for _,e in ipairs({{f="HUMAN"},{f="NIGHTELF"},{f="REBORNKULTIRAN"},{f="REBORNSETHRAK"},{f="ORC"},{f="MAGHAR",horde=true},{f="REBORNOGRE",horde=true}})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 50 | <code>  for _,s in ipairs({2,3})do</code> | 循环：for _,s in ipairs({2,3})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 51 | <code>   newOpen(e,s)</code> | 此行属于“function SetCharacterCreateFacing(v)end”：`newOpen(e,s)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 52 | <code>   local managed=race==3 or race==5 or race==6 or race==7</code> | 定义局部变量：local managed=race==3 or race==5 or race==6 or race==7；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 53 | <code>   local allowed=managed and {[3]=true}or race==1 and {[1]=true,[2]=true,[3]=true}or race==4 and {[1]=true,[3]=true}or{}</code> | 定义局部变量：local allowed=managed and {[3]=true}or race==1 and {[1]=true,[2]=true,[3]=true}or race==4 and {[1]=true,[3]=true}or{}；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 54 | <code>   for i=1,3 do local b=_G["CharCreateClassButton"..i];assert(b.enabled==not not allowed[i]);assert(b.normal.desaturated==not allowed[i]);assert(not b.selection.shown)end</code> | 循环：for i=1,3 do local b=_G["CharCreateClassButton"..i];assert(b.enabled==not not allowed[i]);assert(b.normal.desaturated==not allowed[i]);assert(not b.selection.shown)end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 55 | <code>   if managed then</code> | 条件分支：只有`if managed`成立才走随后分支；不满足进入else/跳过。 |
| 56 | <code>    assert(classIndex==3)</code> | 断言这行写出的条件必须成立：assert(classIndex==3)；否则立刻停测，不能继续记通过。 |
| 57 | <code>    for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do assert(not b.enabled and b.normal.desaturated)end</code> | 循环：for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do assert(not b.enabled and b.normal.desaturated)end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 58 | <code>   end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 59 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 60 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 61 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 62 | <code>''');checks.append('1400 actual V56 Open transitions: old/undeveloped/36/37/39/49, sexes, Warrior-only, detached buttons, no long selection rectangle')</code> | 此行属于“function SetCharacterCreateFacing(v)end”：`''');checks.append('1400 actual V56 Open transitions: old/undeveloped/36/37/39/49, sexes, Warrior-only, detached buttons, no long selection rectangle')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 63 | <code>L.execute('''for _,r in ipairs({6,7})do for _,s in ipairs({2,3})do CharacterCreate.selectedRace=r;race=r;sex=s;nativeName=nil;edit="old";CharacterCreate_GenerateRandomName();assert(edit~="old"and edit~="");local prev=edit;CharacterCreate_GenerateRandomName();assert(edit~=prev)end end''');checks.append('39/49 male/female random name fallback')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`L.execute('''for _,r in ipairs({6,7})do for _,s in ipairs({2,3})do CharacterCreate.selectedRace=r;race=r;sex=s;nativeName=nil;edit="old";CharacterCreate_GenerateRandomName();assert(edit~="old"and edit~="");local prev=edit;CharacterCreate_GenerateRandomName();assert(edit~=prev)end end''');checks.append('39/49 male/female random name fallback')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 64 | <code>L.execute('''for _,r in ipairs({6,7})do CharacterCreate.selectedRace=r;race=r;classIndex=1;local prev=nativeCalls;CreateCharacter("bad");assert(nativeCalls==prev);classIndex=3;CreateCharacter("ok");assert(nativeCalls==prev+1)end''');checks.append('39/49 final CreateCharacter guard rejects stale class, accepts Warrior')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`L.execute('''for _,r in ipairs({6,7})do CharacterCreate.selectedRace=r;race=r;classIndex=1;local prev=nativeCalls;CreateCharacter("bad");assert(nativeCalls==prev);classIndex=3;CreateCharacter("ok");assert(nativeCalls==prev+1)end''');checks.append('39/49 final CreateCharacter guard rejects stale class, accepts Warrior')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 65 | <code>g=(CL/'Interface/GlueXML/GlueParent.lua').read_text(encoding='utf-8');start=g.index('function SetBackgroundModel(model, name, raza, zoom, gender)');end=g.index('\nfunction SetBackgroundModelRespaldo',start)</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 66 | <code>L.execute('CharacterSelect={};CharacterCreate={};strupper=string.upper;function SetCharSelectBackground(v)scene=v end;function SetLighting(...)end')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`L.execute('CharacterSelect={};CharacterCreate={};strupper=string.upper;function SetCharSelectBackground(v)scene=v end;function SetLighting(...)end')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 67 | <code>L.execute(g[start:end])</code> | 此行属于“function SetCharacterCreateFacing(v)end”：`L.execute(g[start:end])`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 68 | <code>for token,scene in [('REBORNKULTIRAN','ui_kultiran'),('MAGHAR','UI_Troll')]:</code> | 循环：for token,scene in [('REBORNKULTIRAN','ui_kultiran'),('MAGHAR','UI_Troll')]；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 69 | <code> L.globals().SetBackgroundModel(L.globals().CharacterSelect,token)</code> | 调用SetBackgroundModel（选择Glue舞台背景；只对CharacterSelect做场景token别名）；此行参数来自当前上下文。 |
| 70 | <code> check(L.globals().scene=='Interface\\Glues\\Models\\'+scene+'\\'+scene+'.m2','actual character selection scene alias '+token)</code> | 测试断言：check(L.globals().scene=='Interface\\Glues\\Models\\'+scene+'\\'+scene+'.m2','actual character selection scene alias '+token)。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 71 | <code># DBC preservation against each independent input.</code> | 说明注释：DBC preservation against each independent input.；它不执行，实际条件仍以相邻代码为准。 |
| 72 | <code>manifest=json.loads((P/'checks/input_output_manifest.json').read_text(encoding='utf-8'))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 73 | <code>for m in manifest:</code> | 循环：for m in manifest；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 74 | <code> if not m['relative'].endswith('.dbc'):continue</code> | 条件分支：只有`if not m['relative'].endswith('.dbc'):continue`成立才走随后分支；不满足进入else/跳过。 |
| 75 | <code> comp=P/m['component'];old=(comp/'backup_原文件'/m['relative']).read_bytes();new=(comp/'交付'/m['relative']).read_bytes();a,ast,rs=decode(old);b,bst,_=decode(new);bset=set(b)</code> | 读取原始内容，哈希/归档按字节核对，避免换行归一掩盖变化。 |
| 76 | <code> if rs==2:</code> | 条件分支：只有`if rs==2:`成立才走随后分支；不满足进入else/跳过。 |
| 77 | <code>  check([r for r in a if r[0] not in [39,49]]==[r for r in b if r[0] not in [39,49]],m['relative']+' other combinations preserved')</code> | 测试断言：check([r for r in a if r[0] not in [39,49]]==[r for r in b if r[0] not in [39,49]],m['relative']+' other combinations preserved')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 78 | <code>  check([tuple(r) for r in b if r[0] in [39,49]]==[(39,1),(49,1)],m['relative']+' Warrior only')</code> | 测试断言：check([tuple(r) for r in b if r[0] in [39,49]]==[(39,1),(49,1)],m['relative']+' Warrior only')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 79 | <code> elif 'ChrRaces' in m['relative']:</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 80 | <code>  check(all(row in bset for row in a if words(row)[0] not in [39,49]),m['relative']+' other races untouched')</code> | 测试断言：check(all(row in bset for row in a if words(row)[0] not in [39,49]),m['relative']+' other races untouched')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 81 | <code>  for r in [39,49]:check(not(words(next(x for x in b if words(x)[0]==r))[1]&amp;4),m['relative']+' playable '+str(r))</code> | 循环：for r in [39,49]:check(not(words(next(x for x in b if words(x)[0]==r))[1]&4),m['relative']+' playable '+str(r))；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 82 | <code> else:check(all(row in bset for row in a)and bst.startswith(ast),m['relative']+' all existing records/strings preserved')</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 83 | <code> if 'CharStartOutfit' in m['relative']:</code> | 条件分支：只有`if 'CharStartOutfit' in m['relative']:`成立才走随后分支；不满足进入else/跳过。 |
| 84 | <code>  for race,parent in [(39,1),(49,2)]:</code> | 循环：for race,parent in [(39,1),(49,2)]；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 85 | <code>   for sex in [0,1]:</code> | 循环：for sex in [0,1]；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 86 | <code>    donor=next(x for x in a if tuple(x[4:7])==(parent,1,sex));row=next(x for x in b if tuple(x[4:7])==(race,1,sex))</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`donor=next(x for x in a if tuple(x[4:7])==(parent,1,sex));row=next(x for x in b if tuple(x[4:7])==(race,1,sex))`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 87 | <code>    check(row[5:]==donor[5:],m['relative']+' same-sex parent items '+str((race,sex)))</code> | 测试断言：check(row[5:]==donor[5:],m['relative']+' same-sex parent items '+str((race,sex)))。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 88 | <code>cpp=(W/'source/src/server/game/Entities/Player/Player.cpp').read_text(encoding='utf-8')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 89 | <code>check(cpp.index('    LearnDefaultSkills();')&lt;cpp.index('    LearnCustomSpells();')&lt;cpp.index('if (CharStartOutfitEntry const*'), 'real Player::Create skill/custom spell initialization precedes outfit distribution')</code> | 测试断言：check(cpp.index('    LearnDefaultSkills();')<cpp.index('    LearnCustomSpells();')<cpp.index('if (CharStartOutfitEntry const*'), 'real Player::Create skill/custom spell initialization precedes outfit distribution')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 90 | <code>handler=(W/'source/src/server/game/Handlers/CharacterHandler.cpp').read_text(encoding='utf-8')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 91 | <code>check('IsWarriorOnlyNewRace(createInfo-&gt;Race) &amp;&amp; createInfo-&gt;Class != CLASS_WARRIOR' in handler,'server Warrior guard exists')</code> | 测试断言：check('IsWarriorOnlyNewRace(createInfo->Race) && createInfo->Class != CLASS_WARRIOR' in handler,'server Warrior guard exists')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 92 | <code>(P/'checks/joint_tests.json').write_text(json.dumps({'checks':checks,'count':len(checks),'boundary':'Actual Lua function bodies with engine/widgets substituted; binary DBC assertions; no game run.'},ensure_ascii=False,indent=2),encoding='utf-8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 93 | <code>print('PASS',len(checks),'groups and 1400 actual Open checkpoints')</code> | 把测试结果/计数输出为证据；前面的断言都没失败才能走到这里。 |
