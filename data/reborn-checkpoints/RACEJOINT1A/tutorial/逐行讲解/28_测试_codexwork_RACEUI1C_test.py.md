# 测试_codexwork_RACEUI1C_test.py：逐行讲解
实际验证代码；原样归档供学习。私有路径/环境必须先核对，不能运行到生产库或覆盖运行客户端。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261105\codexwork_RACEUI1C\test.py`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `Open` | 上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它 |

## 原代码
```python
# -*- coding: utf-8 -*-
from pathlib import Path
import json
W=Path(__file__).resolve().parent;P=W.parent/'codexcandidate_RACEUI1C'
code=(W.parent/'codexwork_RACEUI1B/test.py').read_text(encoding='utf8').split("L.execute('''\nfor iteration=")[0]
code=code.replace('codexcandidate_RACEUI1B','codexcandidate_RACEUI1C')
exec(compile(code,str(W/'test.py'),'exec'))
W=Path(__file__).resolve().parent;P=W.parent/'codexcandidate_RACEUI1C'
L.execute('''
local F=getmetatable(CharCreateClassButton3)
function F:SetTextColor(r,g,b)self.rgb={r,g,b}end
for i=1,3 do _G["CharCreateClassButton"..i].selection=Widget()end
for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do b.normal=Widget();b.pushed=Widget();b.ascendNeutralRing=Widget();b.selection=Widget()end
function SetSelectedRace(v)race=v end
function SetSelectedSex(v)sex=v end
function SetCharacterRace(v)CharacterCreate.selectedRace=v end
function SetCharacterCreateFacing(v)facing=v end
CharacterCreate.backgroundRaceByListId={}
''')
base=P/'02_覆盖到客户端根目录/导入Patch-YB.mpq/Interface/GlueXML'
for f in base.glob('*.lua'):
 ok,err=L.eval('function(s)local f,e=loadstring(s);return f~=nil,e end')(f.read_text(encoding='utf8'));assert ok,(f,err)
old=(W/'RebornRacePreview.lua').read_text(encoding='utf8');new=(base/'RebornRacePreview.lua').read_text(encoding='utf8')
def open_chunk(text):
 start=text.index('local function Open(e, sex)');end=text.index('\nlocal function Hook()',start)
 return 'local bs,A,B={}\n'+text[start:end]+'\nreturn Open'
L.globals().oldOpen=L.execute(open_chunk(old));L.globals().newOpen=L.execute(open_chunk(new))
L.execute('''
-- This is the actual Open body used by the custom button, not CharacterRace_OnClick.
race=1;CharacterCreate.selectedRace=1;classIndex=1
CharacterCreateEnumerateClasses(GetAvailableClasses())
assert(CharCreateClassButton1.enabled and CharCreateClassButton2.enabled)
oldOpen({f="REBORNSETHRAK"})
assert(race==3 and CharCreateClassButton1.enabled and CharCreateClassButton2.enabled)
''');checks.append('reproduced B stale-class failure using the real unpatched custom Open body')
L.execute('''
for repeatIndex=1,150 do
 for _,e in ipairs({{f="HUMAN"},{f="NIGHTELF"},{f="REBORNSETHRAK"},{f="ORC"},{f="REBORNOGRE",horde=true}})do
  for _,s in ipairs({2,3})do
   newOpen(e,s)
   local managed=race==3 or race==5
   local allowed=managed and {[3]=true}or race==1 and {[1]=true,[2]=true,[3]=true}or race==4 and {[1]=true,[3]=true}or{}
   for i=1,3 do
    local b=_G["CharCreateClassButton"..i]
    assert(b.enabled==not not allowed[i],"enabled race="..race.." class="..i);assert(b.normal.desaturated==not allowed[i],"desat race="..race.." class="..i);assert(not b.selection.shown,"bar race="..race.." class="..i)
   end
   if managed then
    assert(classIndex==3)
    for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do
     assert(not b.enabled and b.normal.desaturated and b.normal.alpha==.4)
     assert(b.ascendNeutralRing.desaturated and b.ascendNeutralRing.alpha==.4)
     assert(b.nameFrame.text.rgb[1]==.45 and b.nameFrame.text.alpha==.65)
    end
   else
    assert(CharCreateWitchDoctorPreviewButton.ascendNeutralRing.alpha==1)
   end
  end
 end
end
''');checks.append('1500 real custom Open race/sex transitions; only Warrior for new races, original policies restored')
L.execute('''
race=3;CharacterCreate.selectedRace=3;classIndex=3;CharCreateClassButton3.selection:Show()
SetCharacterClass(3);assert(not CharCreateClassButton3.selection.shown)
race=1;CharacterCreate.selectedRace=1;CharCreateClassButton3.selection:Show()
SetCharacterClass(3);assert(not CharCreateClassButton3.selection.shown)
''');checks.append('oversized XML selection remains hidden for new and old races')
L.execute('''local r=race;PAID_SERVICE_TYPE=true;newOpen({f="REBORNOGRE"});assert(race==r);PAID_SERVICE_TYPE=nil''');checks.append('actual custom Open preserves paid-service rejection')
input_xml=(W/'CharacterCreate.xml').read_text(encoding='utf8');assert 'parentKey="selection"'in input_xml and 'x="256" y="96"'in input_xml
checks.append('oversized selection dimensions traced to actual client XML')
(P/'checks/validation.json').write_text(json.dumps(dict(checks=checks,game='未测',boundary='Real custom Open body, enumerator and final refresh under Lua5.1; native API/widgets substituted. Does not render engine.'),ensure_ascii=False,indent=2),encoding='utf8');print('PASS',len(checks),'groups; 1500 actual Open transition checks; old Open failure reproduced')
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code># -*- coding: utf-8 -*-</code> | 说明注释：*- coding: utf-8 -*-；它不执行，实际条件仍以相邻代码为准。 |
| 2 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>import json</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 4 | <code>W=Path(__file__).resolve().parent;P=W.parent/'codexcandidate_RACEUI1C'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`W=Path(__file__).resolve().parent;P=W.parent/'codexcandidate_RACEUI1C'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 5 | <code>code=(W.parent/'codexwork_RACEUI1B/test.py').read_text(encoding='utf8').split("L.execute('''\nfor iteration=")[0]</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 6 | <code>code=code.replace('codexcandidate_RACEUI1B','codexcandidate_RACEUI1C')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`code=code.replace('codexcandidate_RACEUI1B','codexcandidate_RACEUI1C')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 7 | <code>exec(compile(code,str(W/'test.py'),'exec'))</code> | 此行属于“测试_codexwork_RACEUI1C_test.py”：`exec(compile(code,str(W/'test.py'),'exec'))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 8 | <code>W=Path(__file__).resolve().parent;P=W.parent/'codexcandidate_RACEUI1C'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`W=Path(__file__).resolve().parent;P=W.parent/'codexcandidate_RACEUI1C'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 9 | <code>L.execute('''</code> | 此行属于“测试_codexwork_RACEUI1C_test.py”：`L.execute('''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 10 | <code>local F=getmetatable(CharCreateClassButton3)</code> | 定义局部变量：local F=getmetatable(CharCreateClassButton3)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 11 | <code>function F:SetTextColor(r,g,b)self.rgb={r,g,b}end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function F:SetTextColor(r,g,b)self.rgb={r,g,b}end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12 | <code>for i=1,3 do _G["CharCreateClassButton"..i].selection=Widget()end</code> | 循环：for i=1,3 do _G["CharCreateClassButton"..i].selection=Widget()end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 13 | <code>for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do b.normal=Widget();b.pushed=Widget();b.ascendNeutralRing=Widget();b.selection=Widget()end</code> | 循环：for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do b.normal=Widget();b.pushed=Widget();b.ascendNeutralRing=Widget();b.selection=Widget()end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 14 | <code>function SetSelectedRace(v)race=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetSelectedRace(v)race=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 15 | <code>function SetSelectedSex(v)sex=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetSelectedSex(v)sex=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 16 | <code>function SetCharacterRace(v)CharacterCreate.selectedRace=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetCharacterRace(v)CharacterCreate.selectedRace=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 17 | <code>function SetCharacterCreateFacing(v)facing=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function SetCharacterCreateFacing(v)facing=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 18 | <code>CharacterCreate.backgroundRaceByListId={}</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`CharacterCreate.backgroundRaceByListId={}`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 19 | <code>''')</code> | 此行属于“function SetCharacterCreateFacing(v)facing=v end”：`''')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 20 | <code>base=P/'02_覆盖到客户端根目录/导入Patch-YB.mpq/Interface/GlueXML'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`base=P/'02_覆盖到客户端根目录/导入Patch-YB.mpq/Interface/GlueXML'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 21 | <code>for f in base.glob('*.lua'):</code> | 循环：for f in base.glob('*.lua')；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 22 | <code> ok,err=L.eval('function(s)local f,e=loadstring(s);return f~=nil,e end')(f.read_text(encoding='utf8'));assert ok,(f,err)</code> | Lua5.1先解析实际文件抓语法错误；通过不等于游戏接口或模型运行通过。 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 23 | <code>old=(W/'RebornRacePreview.lua').read_text(encoding='utf8');new=(base/'RebornRacePreview.lua').read_text(encoding='utf8')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 24 | <code>def open_chunk(text):</code> | 此行属于“def open_chunk(text):”：`def open_chunk(text):`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 25 | <code> start=text.index('local function Open(e, sex)');end=text.index('\nlocal function Hook()',start)</code> | 调用Open（上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它）；此行参数来自当前上下文。 |
| 26 | <code> return 'local bs,A,B={}\n'+text[start:end]+'\nreturn Open'</code> | 返回这段错误/提示文字，说明依赖或资格哪一项不成立；它不是成功标记。 |
| 27 | <code>L.globals().oldOpen=L.execute(open_chunk(old));L.globals().newOpen=L.execute(open_chunk(new))</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`L.globals().oldOpen=L.execute(open_chunk(old));L.globals().newOpen=L.execute(open_chunk(new))`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 28 | <code>L.execute('''</code> | 此行属于“def open_chunk(text):”：`L.execute('''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 29 | <code>-- This is the actual Open body used by the custom button, not CharacterRace_OnClick.</code> | 说明注释：This is the actual Open body used by the custom button, not CharacterRace_OnClick.；它不执行，实际条件仍以相邻代码为准。 |
| 30 | <code>race=1;CharacterCreate.selectedRace=1;classIndex=1</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`race=1;CharacterCreate.selectedRace=1;classIndex=1`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 31 | <code>CharacterCreateEnumerateClasses(GetAvailableClasses())</code> | 此行属于“def open_chunk(text):”：`CharacterCreateEnumerateClasses(GetAvailableClasses())`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 32 | <code>assert(CharCreateClassButton1.enabled and CharCreateClassButton2.enabled)</code> | 断言这行写出的条件必须成立：assert(CharCreateClassButton1.enabled and CharCreateClassButton2.enabled)；否则立刻停测，不能继续记通过。 |
| 33 | <code>oldOpen({f="REBORNSETHRAK"})</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`oldOpen({f="REBORNSETHRAK"})`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 34 | <code>assert(race==3 and CharCreateClassButton1.enabled and CharCreateClassButton2.enabled)</code> | 断言这行写出的条件必须成立：assert(race==3 and CharCreateClassButton1.enabled and CharCreateClassButton2.enabled)；否则立刻停测，不能继续记通过。 |
| 35 | <code>''');checks.append('reproduced B stale-class failure using the real unpatched custom Open body')</code> | 此行属于“def open_chunk(text):”：`''');checks.append('reproduced B stale-class failure using the real unpatched custom Open body')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 36 | <code>L.execute('''</code> | 此行属于“def open_chunk(text):”：`L.execute('''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 37 | <code>for repeatIndex=1,150 do</code> | 循环：for repeatIndex=1,150 do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 38 | <code> for _,e in ipairs({{f="HUMAN"},{f="NIGHTELF"},{f="REBORNSETHRAK"},{f="ORC"},{f="REBORNOGRE",horde=true}})do</code> | 循环：for _,e in ipairs({{f="HUMAN"},{f="NIGHTELF"},{f="REBORNSETHRAK"},{f="ORC"},{f="REBORNOGRE",horde=true}})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 39 | <code>  for _,s in ipairs({2,3})do</code> | 循环：for _,s in ipairs({2,3})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 40 | <code>   newOpen(e,s)</code> | 此行属于“def open_chunk(text):”：`newOpen(e,s)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 41 | <code>   local managed=race==3 or race==5</code> | 定义局部变量：local managed=race==3 or race==5；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 42 | <code>   local allowed=managed and {[3]=true}or race==1 and {[1]=true,[2]=true,[3]=true}or race==4 and {[1]=true,[3]=true}or{}</code> | 定义局部变量：local allowed=managed and {[3]=true}or race==1 and {[1]=true,[2]=true,[3]=true}or race==4 and {[1]=true,[3]=true}or{}；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 43 | <code>   for i=1,3 do</code> | 循环：for i=1,3 do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 44 | <code>    local b=_G["CharCreateClassButton"..i]</code> | 定义局部变量：local b=_G["CharCreateClassButton"..i]；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 45 | <code>    assert(b.enabled==not not allowed[i],"enabled race="..race.." class="..i);assert(b.normal.desaturated==not allowed[i],"desat race="..race.." class="..i);assert(not b.selection.shown,"bar race="..race.." class="..i)</code> | 断言这行写出的条件必须成立：assert(b.enabled==not not allowed[i],"enabled race="..race.." class="..i);assert(b.normal.desaturated==not allowed[i],"desat race="..race.." class="..i);assert(not b.selection.shown,"bar race="..race.." class="..i)；否则立刻停测，不能继续记通过。 |
| 46 | <code>   end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 47 | <code>   if managed then</code> | 条件分支：只有`if managed`成立才走随后分支；不满足进入else/跳过。 |
| 48 | <code>    assert(classIndex==3)</code> | 断言这行写出的条件必须成立：assert(classIndex==3)；否则立刻停测，不能继续记通过。 |
| 49 | <code>    for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do</code> | 循环：for _,b in pairs({CharCreateMonkButton,CharCreateWitchDoctorPreviewButton,CharCreateWitchHunterPreviewButton})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 50 | <code>     assert(not b.enabled and b.normal.desaturated and b.normal.alpha==.4)</code> | 断言这行写出的条件必须成立：assert(not b.enabled and b.normal.desaturated and b.normal.alpha==.4)；否则立刻停测，不能继续记通过。 |
| 51 | <code>     assert(b.ascendNeutralRing.desaturated and b.ascendNeutralRing.alpha==.4)</code> | 断言这行写出的条件必须成立：assert(b.ascendNeutralRing.desaturated and b.ascendNeutralRing.alpha==.4)；否则立刻停测，不能继续记通过。 |
| 52 | <code>     assert(b.nameFrame.text.rgb[1]==.45 and b.nameFrame.text.alpha==.65)</code> | 断言这行写出的条件必须成立：assert(b.nameFrame.text.rgb[1]==.45 and b.nameFrame.text.alpha==.65)；否则立刻停测，不能继续记通过。 |
| 53 | <code>    end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 54 | <code>   else</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 55 | <code>    assert(CharCreateWitchDoctorPreviewButton.ascendNeutralRing.alpha==1)</code> | 断言这行写出的条件必须成立：assert(CharCreateWitchDoctorPreviewButton.ascendNeutralRing.alpha==1)；否则立刻停测，不能继续记通过。 |
| 56 | <code>   end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 57 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 58 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 59 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 60 | <code>''');checks.append('1500 real custom Open race/sex transitions; only Warrior for new races, original policies restored')</code> | 此行属于“def open_chunk(text):”：`''');checks.append('1500 real custom Open race/sex transitions; only Warrior for new races, original policies restored')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 61 | <code>L.execute('''</code> | 此行属于“def open_chunk(text):”：`L.execute('''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 62 | <code>race=3;CharacterCreate.selectedRace=3;classIndex=3;CharCreateClassButton3.selection:Show()</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`race=3;CharacterCreate.selectedRace=3;classIndex=3;CharCreateClassButton3.selection:Show()`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 63 | <code>SetCharacterClass(3);assert(not CharCreateClassButton3.selection.shown)</code> | 此行属于“def open_chunk(text):”：`SetCharacterClass(3);assert(not CharCreateClassButton3.selection.shown)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 64 | <code>race=1;CharacterCreate.selectedRace=1;CharCreateClassButton3.selection:Show()</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`race=1;CharacterCreate.selectedRace=1;CharCreateClassButton3.selection:Show()`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 65 | <code>SetCharacterClass(3);assert(not CharCreateClassButton3.selection.shown)</code> | 此行属于“def open_chunk(text):”：`SetCharacterClass(3);assert(not CharCreateClassButton3.selection.shown)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 66 | <code>''');checks.append('oversized XML selection remains hidden for new and old races')</code> | 此行属于“def open_chunk(text):”：`''');checks.append('oversized XML selection remains hidden for new and old races')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 67 | <code>L.execute('''local r=race;PAID_SERVICE_TYPE=true;newOpen({f="REBORNOGRE"});assert(race==r);PAID_SERVICE_TYPE=nil''');checks.append('actual custom Open preserves paid-service rejection')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`L.execute('''local r=race;PAID_SERVICE_TYPE=true;newOpen({f="REBORNOGRE"});assert(race==r);PAID_SERVICE_TYPE=nil''');checks.append('actual custom Open preserves paid-service rejection')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 68 | <code>input_xml=(W/'CharacterCreate.xml').read_text(encoding='utf8');assert 'parentKey="selection"'in input_xml and 'x="256" y="96"'in input_xml</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 69 | <code>checks.append('oversized selection dimensions traced to actual client XML')</code> | 此行属于“def open_chunk(text):”：`checks.append('oversized selection dimensions traced to actual client XML')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 70 | <code>(P/'checks/validation.json').write_text(json.dumps(dict(checks=checks,game='未测',boundary='Real custom Open body, enumerator and final refresh under Lua5.1; native API/widgets substituted. Does not render engine.'),ensure_ascii=False,indent=2),encoding='utf8');print('PASS',len(checks),'groups; 1500 actual Open transition checks; old Open failure reproduced')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
