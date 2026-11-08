# 测试_codexwork_TGFIX1A_test.py：逐行讲解
实际验证代码；原样归档供学习。私有路径/环境必须先核对，不能运行到生产库或覆盖运行客户端。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261107\codexwork_TGFIX1A\test.py`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `Open` | 上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它 |
| `Recommendation` | 给展示/收藏/应用返回同一当前等级推荐，避免看11点却用71点 |
| `AddNativePoint` | 校验草稿后交给原NativeEngine发LearnTalent并等待确认 |
| `RefreshTree` | 重读原生已学和余点，连接按钮、可加绿框和解释文字 |
| `ShowTree` | 首次显示后再刷新，避免第一次打开没接上点击函数 |
| `check` | 断言结果必须成立，并累积一条检查；失败立即停止 |
| `data` | 按测试当前职业返回真实插件天赋数据 |
| `clear` | 清空测试状态、确认职业/天赋组，防止上一测试污染下一测试 |
| `ack` | 模拟服务器确认后才改变已学；发出请求与确认是两个时间点 |
| `LearnTalent` | 测试替身只记录一次待确认请求；不是游戏内真的加点 |
| `GetTalentInfo` | 替身按打乱后的原生页/节点顺序返回真实测试已学，不应靠数组顺序匹配 |
| `GetTalentLink` | 替身返回TalentID链接，逼生产逻辑按身份匹配而非固定索引 |

## 原代码
```python
from pathlib import Path
import json
W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package.txt').read_text(encoding='utf-8'))
A=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornTalentGuide';BASE=R/'beascendclient/newrebornWOWli20261107beAscend/Interface/AddOns/RebornTalentGuide'
old=R/'000Ascendupdate/000Ascendupdate20261019/codexwork_TG16A/test.py'
setup=old.read_text(encoding='utf-8-sig').split("l.execute((g/'Theme.lua')")[0].replace('newrebornWOWli20261013beAscend','newrebornWOWli20261107beAscend')
ns={};exec(compile(setup,'historical actual UI fixture','exec'),ns);l=ns['l']
l.execute('''local old=CreateFrame
function CreateFrame(...)
 local f=old(...)
 function f:GetPushedTexture()self.pushed=self.pushed or self:CreateTexture();return self.pushed end
 function f:GetNormalTexture()self.normal=self.normal or self:CreateTexture();return self.normal end
 function f:GetHighlightTexture()self.highlight=self.highlight or self:CreateTexture();return self.highlight end
 function f:SetFrameLevel(v)self.frameLevel=v end
 function f:GetFrameLevel()return self.frameLevel or 1 end
 function f:SetFrameStrata(v)self.strata=v end
 function f:GetFrameStrata()return self.strata or'MEDIUM'end
 function f:EnableMouse(v)self.mouseEnabled=v end
 return f
end
function UIParent:GetCenter()return 960,540 end
''')
for line in (A/'RebornTalentGuide.toc').read_text(encoding='utf-8-sig').splitlines():
 f=line.strip()
 if f and not f.startswith('#'):
  src=A/f if (A/f).exists()else BASE/f
  try:l.execute(src.read_text(encoding='utf-8-sig'))
  except Exception as e:raise RuntimeError(str(src)+': '+str(e))
script=r'''
CHECKS=0
local function check(v,msg)assert(v,msg);CHECKS=CHECKS+1 end
local G,S,B,T=RebornTalentGuide,RebornTalentCollections,RebornTalentGuide.ClassHome,RebornTalentGuide.TalentCenter
local group,clock,preview=1,0,0
local current,sent,awaiting={},0,nil
local function data()return S.NativeData(CLASS)end
local function clear(token)
 CLASS=token;current={};group=1;preview=0;LEVEL=20;COMBAT=false;DEAD=false;G.fromBot=false;G.BotRecommendations.mode=false
 for t,tree in ipairs(data().trees)do current[t]={};for i in ipairs(tree)do current[t][i]=0 end end
end
function UnitClass()return CLASS,CLASS,CLASS=='WARRIOR'and 1 or CLASS=='PALADIN'and 2 or CLASS=='MONK'and 14 or 3 end
function GetTime()return clock end
function GetActiveTalentGroup()return group end
function GetNumTalentTabs()return 3 end
local permutation={3,1,2}
function GetNumTalents(tab)return #data().trees[permutation[tab]]end
function GetTalentLink(tab,i)local tree=data().trees[permutation[tab]];return 'talent:'..tree[#tree+1-i].id..':0'end
function GetTalentInfo(tab,i)local t=permutation[tab];local tree=data().trees[t];local k=#tree+1-i;local n=tree[k];return n.name,n.icon,n.row,n.col,current[t][k],n.max end
function GetGroupPreviewTalentPointsSpent()return preview end
function GetUnspentTalentPoints()local total=0;for _,r in ipairs(current)do for _,n in ipairs(r)do total=total+n end end;return math.max(0,LEVEL-9-total)end
function LearnTalent(tab,i,inspect,g)
 check(not COMBAT and not DEAD and g==group,'native submit guard');check(not awaiting,'must not resend pending point')
 local t=permutation[tab];local tree=data().trees[t];local k=#tree+1-i
 sent=sent+1;awaiting={t=t,i=k,group=g}
end
local function ack()
 check(awaiting~=nil,'must have real outstanding request')
 current[awaiting.t][awaiting.i]=current[awaiting.t][awaiting.i]+1;awaiting=nil
 B.events:GetScript('OnEvent')(B.events,'PLAYER_TALENT_UPDATE')
end
for _,token in ipairs({'WARRIOR','PALADIN'})do
 clear(token);local E=S.NativeEngine(token);local D=data()
 -- Every level prefix must itself satisfy the actual prerequisite queue.
 for index=1,#D.plans do for level=10,80 do
  local p=assert(E.Build(index,level));local total=p.split[1]+p.split[2]+p.split[3]
  check(total==level-9,'level budget')
  local build=S.Blank(token,level);for t,tree in ipairs(D.trees)do for i,n in ipairs(tree)do build.ranks[n.id]=p.ranks[t][i]end end
  check(S.Validate(build),'all level prefixes valid')
  if level==80 then for t,row in ipairs(p.ranks)do for i,v in ipairs(row)do check(v==D.plans[index].ranks[t][i],'full-level original build unchanged')end end end
 end end
 LEVEL=20;E.previewCurrent=true;T.Open('recommend',token,1)
 check(T.levelButtons[1]:IsShown()and T.levelButtons[5]:IsShown(),'classic level selectors restored')
 local build=assert(S.Recommendation(token));check(build.level==20,'recommendation is current level')
 local total=0;for _,board in ipairs(T.boards)do for _,item in ipairs(board.items)do total=total+item.target end end
 check(total==11,'actual rendered preview uses 11 points, not 71')
 check(T.apply:IsShown()and T.apply:IsEnabled(),'current-level apply button available')
 T.levelButtons[5]:GetScript('OnClick')();check(S.Recommendation(token).level==80);check(not T.apply:IsEnabled(),'level80 build must not apply at20')
 T.levelButtons[1]:GetScript('OnClick')();check(S.Recommendation(token).level==20)
 T.detailsButton:GetScript('OnClick')();check(T.details:IsShown());check(T.details:GetFrameStrata()=='TOOLTIP'and T.details.mouseEnabled,'details covers nodes and blocks click-through')
 for _,board in ipairs(T.boards)do for _,button in ipairs(board.buttons)do check(T.details:GetFrameLevel()>button.rankBox:GetFrameLevel(),'details above child rank captions')end end
 T.detailsButton:GetScript('OnClick')();check(not T.details:IsShown())
 -- Native learning is not local draft state. Both panels read identical native data.
 check(B.ShowTree(token,1),'open actual large tree');check(B.tree.note:GetText():find('11'),'show real unspent count')
 local id=D.trees[1][1].id
 local button=B.board.buttons[1];check(type(button.node.onClick)=='function','first show already has live click handlers')
 local initial=current[1][1];local before=sent
 check(B.AddNativePoint(id),'one point queued through original native engine')
 check(not B.AddNativePoint(id),'duplicate click while waiting rejected')
 clock=clock+.4;E.Tick();check(sent==before+1,'one LearnTalent request')
 check(current[1][1]==initial,'no optimistic learned-rank change before ack')
 B.RefreshTree();check(B.board.items[1].actual==initial,'new panel still shows old authoritative rank')
 ack();clock=clock+.4;E.Tick()
 check(not E.job,'server confirmation completes task');check(current[1][1]==initial+1)
 local ranks=assert(E.Scan());check(B.board.items[1].actual==ranks[1][1],'new and native read same confirmed rank')
 -- Old-panel change and reset trigger the same existing event handler.
 current[1][1]=math.min(2,D.trees[1][1].max);B.events:GetScript('OnEvent')(B.events,'PLAYER_TALENT_UPDATE')
 check(B.board.items[1].actual==current[1][1],'old -> new point event sync')
 current[1][1]=0;B.events:GetScript('OnEvent')(B.events,'ACTIVE_TALENT_GROUP_CHANGED');check(B.board.items[1].actual==0,'old -> new reset/group sync')
 before=sent;COMBAT=true;check(not B.AddNativePoint(id));COMBAT=false;DEAD=true;check(not B.AddNativePoint(id));DEAD=false
 preview=1;check(not B.AddNativePoint(id),'unsaved native preview cannot be overwritten');preview=0
 G.BotRecommendations.mode=true;check(not B.AddNativePoint(id),'bot context never writes player');G.BotRecommendations.mode=false
 check(sent==before and not E.job,'rejections submit zero points')
 -- Prerequisite and full-rank rejection use actual native queue.
 local last=D.trees[1][#D.trees[1]].id;check(not B.AddNativePoint(last),'cannot bypass tier gate')
 current[1][1]=D.trees[1][1].max;check(not B.AddNativePoint(id),'max rank cannot be exceeded')
 clear(token);B.ShowTree(token,1);check(B.AddNativePoint(id));group=2;clock=clock+.4;E.Tick();check(not E.job,'spec change cancels before submit')
end
check(OUTBOUND==0,'no chat commands, charges or alternate protocol writes')
RESULT='PASS '..CHECKS..' actual Lua checks; native APIs/widgets/ack events substituted; no game rendering'
'''
l.execute(script)
(P/'checks/test_results.json').write_text(json.dumps({'checks':l.globals().CHECKS,'result':l.globals().RESULT,'game':'未运行','boundary':'Actual current addon TOC/code loaded with native API/widget/server acknowledgment substitutions. Not actual WoW rendering or server networking.'},ensure_ascii=False,indent=2),encoding='utf-8')
print(l.globals().RESULT)
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 2 | <code>import json</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package.txt').read_text(encoding='utf-8'))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 4 | <code>A=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornTalentGuide';BASE=R/'beascendclient/newrebornWOWli20261107beAscend/Interface/AddOns/RebornTalentGuide'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`A=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornTalentGuide';BASE=R/'beascendclient/newrebornWOWli20261107beAscend/Interface/AddOns/RebornTalentGuide'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 5 | <code>old=R/'000Ascendupdate/000Ascendupdate20261019/codexwork_TG16A/test.py'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`old=R/'000Ascendupdate/000Ascendupdate20261019/codexwork_TG16A/test.py'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 6 | <code>setup=old.read_text(encoding='utf-8-sig').split("l.execute((g/'Theme.lua')")[0].replace('newrebornWOWli20261013beAscend','newrebornWOWli20261107beAscend')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 7 | <code>ns={};exec(compile(setup,'historical actual UI fixture','exec'),ns);l=ns['l']</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`ns={};exec(compile(setup,'historical actual UI fixture','exec'),ns);l=ns['l']`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 8 | <code>l.execute('''local old=CreateFrame</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`l.execute('''local old=CreateFrame`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 9 | <code>function CreateFrame(...)</code> | 此行属于“function CreateFrame(...)”：`function CreateFrame(...)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 10 | <code> local f=old(...)</code> | 定义局部变量：local f=old(...)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 11 | <code> function f:GetPushedTexture()self.pushed=self.pushed or self:CreateTexture();return self.pushed end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function f:GetPushedTexture()self.pushed=self.pushed or self:CreateTexture();return self.pushed end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12 | <code> function f:GetNormalTexture()self.normal=self.normal or self:CreateTexture();return self.normal end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function f:GetNormalTexture()self.normal=self.normal or self:CreateTexture();return self.normal end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 13 | <code> function f:GetHighlightTexture()self.highlight=self.highlight or self:CreateTexture();return self.highlight end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function f:GetHighlightTexture()self.highlight=self.highlight or self:CreateTexture();return self.highlight end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 14 | <code> function f:SetFrameLevel(v)self.frameLevel=v end</code> | 设置同层绘制顺序；要超过子rankBox，不只是超过父面板。 |
| 15 | <code> function f:GetFrameLevel()return self.frameLevel or 1 end</code> | 此行属于“function f:GetFrameLevel()return self.frameLevel or 1 end”：`function f:GetFrameLevel()return self.frameLevel or 1 end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 16 | <code> function f:SetFrameStrata(v)self.strata=v end</code> | 设置绘制层级大类；TOOLTIP让说明窗在天赋树和数字框上面。 |
| 17 | <code> function f:GetFrameStrata()return self.strata or'MEDIUM'end</code> | 此行属于“function f:GetFrameStrata()return self.strata or'MEDIUM'end”：`function f:GetFrameStrata()return self.strata or'MEDIUM'end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 18 | <code> function f:EnableMouse(v)self.mouseEnabled=v end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function f:EnableMouse(v)self.mouseEnabled=v end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 19 | <code> return f</code> | 返回表达式`f`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 20 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 21 | <code>function UIParent:GetCenter()return 960,540 end</code> | 此行属于“function UIParent:GetCenter()return 960,540 end”：`function UIParent:GetCenter()return 960,540 end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 22 | <code>''')</code> | 此行属于“function UIParent:GetCenter()return 960,540 end”：`''')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 23 | <code>for line in (A/'RebornTalentGuide.toc').read_text(encoding='utf-8-sig').splitlines():</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 24 | <code> f=line.strip()</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`f=line.strip()`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 25 | <code> if f and not f.startswith('#'):</code> | 条件分支：只有`if f and not f.startswith('#'):`成立才走随后分支；不满足进入else/跳过。 |
| 26 | <code>  src=A/f if (A/f).exists()else BASE/f</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`src=A/f if (A/f).exists()else BASE/f`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 27 | <code>  try:l.execute(src.read_text(encoding='utf-8-sig'))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 28 | <code>  except Exception as e:raise RuntimeError(str(src)+': '+str(e))</code> | 异常处理/清理边界：无论检查是否成功，都应关闭自己打开的归档或进程资源。 |
| 29 | <code>script=r'''</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`script=r'''`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 30 | <code>CHECKS=0</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`CHECKS=0`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 31 | <code>local function check(v,msg)assert(v,msg);CHECKS=CHECKS+1 end</code> | 定义/进入函数：断言结果必须成立，并累积一条检查；失败立即停止。 |
| 32 | <code>local G,S,B,T=RebornTalentGuide,RebornTalentCollections,RebornTalentGuide.ClassHome,RebornTalentGuide.TalentCenter</code> | 定义局部变量：local G,S,B,T=RebornTalentGuide,RebornTalentCollections,RebornTalentGuide.ClassHome,RebornTalentGuide.TalentCenter；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 33 | <code>local group,clock,preview=1,0,0</code> | 定义局部变量：local group,clock,preview=1,0,0；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 34 | <code>local current,sent,awaiting={},0,nil</code> | 仅记录待确认请求，暂不修改current已学；ack才确认。 |
| 35 | <code>local function data()return S.NativeData(CLASS)end</code> | 定义/进入函数：按测试当前职业返回真实插件天赋数据。同一行若有return，函数立即交回该结果。 |
| 36 | <code>local function clear(token)</code> | 定义/进入函数：清空测试状态、确认职业/天赋组，防止上一测试污染下一测试。 |
| 37 | <code> CLASS=token;current={};group=1;preview=0;LEVEL=20;COMBAT=false;DEAD=false;G.fromBot=false;G.BotRecommendations.mode=false</code> | 测试主动切入战斗状态；必须拒绝并且没有发出新加点请求。 测试死亡状态；必须拒绝并保持发送计数不变。 |
| 38 | <code> for t,tree in ipairs(data().trees)do current[t]={};for i in ipairs(tree)do current[t][i]=0 end end</code> | 循环：for t,tree in ipairs(data().trees)do current[t]={};for i in ipairs(tree)do current[t][i]=0 end end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 39 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 40 | <code>function UnitClass()return CLASS,CLASS,CLASS=='WARRIOR'and 1 or CLASS=='PALADIN'and 2 or CLASS=='MONK'and 14 or 3 end</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`function UnitClass()return CLASS,CLASS,CLASS=='WARRIOR'and 1 or CLASS=='PALADIN'and 2 or CLASS=='MONK'and 14 or 3 end`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 41 | <code>function GetTime()return clock end</code> | 此行属于“function GetTime()return clock end”：`function GetTime()return clock end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 42 | <code>function GetActiveTalentGroup()return group end</code> | 使用当前原生天赋组；请求中途换组应取消而非加到另一组。 |
| 43 | <code>function GetNumTalentTabs()return 3 end</code> | 此行属于“function GetNumTalentTabs()return 3 end”：`function GetNumTalentTabs()return 3 end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 44 | <code>local permutation={3,1,2}</code> | 故意打乱原生三个天赋页；测试按TalentID适配，不允许碰巧靠固定下标成功。 |
| 45 | <code>function GetNumTalents(tab)return #data().trees[permutation[tab]]end</code> | 定义/进入函数：按测试当前职业返回真实插件天赋数据。同一行若有return，函数立即交回该结果。 |
| 46 | <code>function GetTalentLink(tab,i)local tree=data().trees[permutation[tab]];return 'talent:'..tree[#tree+1-i].id..':0'end</code> | 定义/进入函数：按测试当前职业返回真实插件天赋数据；替身返回TalentID链接，逼生产逻辑按身份匹配而非固定索引。同一行若有return，函数立即交回该结果。 |
| 47 | <code>function GetTalentInfo(tab,i)local t=permutation[tab];local tree=data().trees[t];local k=#tree+1-i;local n=tree[k];return n.name,n.icon,n.row,n.col,current[t][k],n.max end</code> | 定义/进入函数：按测试当前职业返回真实插件天赋数据；替身按打乱后的原生页/节点顺序返回真实测试已学，不应靠数组顺序匹配。同一行若有return，函数立即交回该结果。 |
| 48 | <code>function GetGroupPreviewTalentPointsSpent()return preview end</code> | 检测原生未保存预览，不能用新树覆盖玩家尚未确认的草稿。 |
| 49 | <code>function GetUnspentTalentPoints()local total=0;for _,r in ipairs(current)do for _,n in ipairs(r)do total=total+n end end;return math.max(0,LEVEL-9-total)end</code> | 读取当前天赋组真实余点，不根据图标颜色推算玩家余额。 |
| 50 | <code>function LearnTalent(tab,i,inspect,g)</code> | 定义/进入函数：测试替身只记录一次待确认请求；不是游戏内真的加点。 |
| 51 | <code> check(not COMBAT and not DEAD and g==group,'native submit guard');check(not awaiting,'must not resend pending point')</code> | 等待确认时不可再发第二次请求，抓连点重复提交。 测试主动切入战斗状态；必须拒绝并且没有发出新加点请求。 测试死亡状态；必须拒绝并保持发送计数不变。 |
| 52 | <code> local t=permutation[tab];local tree=data().trees[t];local k=#tree+1-i</code> | 定义局部变量：local t=permutation[tab];local tree=data().trees[t];local k=#tree+1-i；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 53 | <code> sent=sent+1;awaiting={t=t,i=k,group=g}</code> | 仅记录待确认请求，暂不修改current已学；ack才确认。 |
| 54 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 55 | <code>local function ack()</code> | 定义/进入函数：模拟服务器确认后才改变已学；发出请求与确认是两个时间点。 |
| 56 | <code> check(awaiting~=nil,'must have real outstanding request')</code> | 只有确实存在待确认请求才允许确认，避免凭空给天赋点。 |
| 57 | <code> current[awaiting.t][awaiting.i]=current[awaiting.t][awaiting.i]+1;awaiting=nil</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`current[awaiting.t][awaiting.i]=current[awaiting.t][awaiting.i]+1;awaiting=nil`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 58 | <code> B.events:GetScript('OnEvent')(B.events,'PLAYER_TALENT_UPDATE')</code> | 此行属于“local function ack()”：`B.events:GetScript('OnEvent')(B.events,'PLAYER_TALENT_UPDATE')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 59 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 60 | <code>for _,token in ipairs({'WARRIOR','PALADIN'})do</code> | 循环：for _,token in ipairs({'WARRIOR','PALADIN'})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 61 | <code> clear(token);local E=S.NativeEngine(token);local D=data()</code> | 调用data（按测试当前职业返回真实插件天赋数据）、clear（清空测试状态、确认职业/天赋组，防止上一测试污染下一测试）；此行参数来自当前上下文。 |
| 62 | <code> -- Every level prefix must itself satisfy the actual prerequisite queue.</code> | 说明注释：Every level prefix must itself satisfy the actual prerequisite queue.；它不执行，实际条件仍以相邻代码为准。 |
| 63 | <code> for index=1,#D.plans do for level=10,80 do</code> | 循环：for index=1,#D.plans do for level=10,80 do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 64 | <code>  local p=assert(E.Build(index,level));local total=p.split[1]+p.split[2]+p.split[3]</code> | 定义局部变量：local p=assert(E.Build(index,level));local total=p.split[1]+p.split[2]+p.split[3]；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 65 | <code>  check(total==level-9,'level budget')</code> | 可用预算=等级-9：20级11点、60级51点、80级71点；只取队列允许步数。 |
| 66 | <code>  local build=S.Blank(token,level);for t,tree in ipairs(D.trees)do for i,n in ipairs(tree)do build.ranks[n.id]=p.ranks[t][i]end end</code> | 定义局部变量：local build=S.Blank(token,level);for t,tree in ipairs(D.trees)do for i,n in ipairs(tree)do build.ranks[n.id]=p.ranks[t][i]end end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 67 | <code>  check(S.Validate(build),'all level prefixes valid')</code> | 测试断言：check(S.Validate(build),'all level prefixes valid')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 68 | <code>  if level==80 then for t,row in ipairs(p.ranks)do for i,v in ipairs(row)do check(v==D.plans[index].ranks[t][i],'full-level original build unchanged')end end end</code> | 条件分支：只有`if level==80  for t,row in ipairs(p.ranks)do for i,v in ipairs(row)do check(v==D.plans[index].ranks[t][i],'full-level original build unchanged')end end end`成立才走随后分支；不满足进入else/跳过。 |
| 69 | <code> end end</code> | 此行属于“local function ack()”：`end end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 70 | <code> LEVEL=20;E.previewCurrent=true;T.Open('recommend',token,1)</code> | 调用Open（上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它）；此行参数来自当前上下文。 |
| 71 | <code> check(T.levelButtons[1]:IsShown()and T.levelButtons[5]:IsShown(),'classic level selectors restored')</code> | 测试断言：check(T.levelButtons[1]:IsShown()and T.levelButtons[5]:IsShown(),'classic level selectors restored')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 72 | <code> local build=assert(S.Recommendation(token));check(build.level==20,'recommendation is current level')</code> | 测试断言：local build=assert(S.Recommendation(token));check(build.level==20,'recommendation is current level')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 73 | <code> local total=0;for _,board in ipairs(T.boards)do for _,item in ipairs(board.items)do total=total+item.target end end</code> | 定义局部变量：local total=0;for _,board in ipairs(T.boards)do for _,item in ipairs(board.items)do total=total+item.target end end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 74 | <code> check(total==11,'actual rendered preview uses 11 points, not 71')</code> | 测试断言：check(total==11,'actual rendered preview uses 11 points, not 71')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 75 | <code> check(T.apply:IsShown()and T.apply:IsEnabled(),'current-level apply button available')</code> | 测试断言：check(T.apply:IsShown()and T.apply:IsEnabled(),'current-level apply button available')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 76 | <code> T.levelButtons[5]:GetScript('OnClick')();check(S.Recommendation(token).level==80);check(not T.apply:IsEnabled(),'level80 build must not apply at20')</code> | 调用实际已连接的点击处理器，避免只测试一个从未由界面调用的函数。 |
| 77 | <code> T.levelButtons[1]:GetScript('OnClick')();check(S.Recommendation(token).level==20)</code> | 调用实际已连接的点击处理器，避免只测试一个从未由界面调用的函数。 |
| 78 | <code> T.detailsButton:GetScript('OnClick')();check(T.details:IsShown());check(T.details:GetFrameStrata()=='TOOLTIP'and T.details.mouseEnabled,'details covers nodes and blocks click-through')</code> | 调用实际已连接的点击处理器，避免只测试一个从未由界面调用的函数。 |
| 79 | <code> for _,board in ipairs(T.boards)do for _,button in ipairs(board.buttons)do check(T.details:GetFrameLevel()&gt;button.rankBox:GetFrameLevel(),'details above child rank captions')end end</code> | 逐个子数字框检查说明窗确实在其上方，复现旧漏字缺口。 |
| 80 | <code> T.detailsButton:GetScript('OnClick')();check(not T.details:IsShown())</code> | 调用实际已连接的点击处理器，避免只测试一个从未由界面调用的函数。 |
| 81 | <code> -- Native learning is not local draft state. Both panels read identical native data.</code> | 说明注释：Native learning is not local draft state. Both panels read identical native data.；它不执行，实际条件仍以相邻代码为准。 |
| 82 | <code> check(B.ShowTree(token,1),'open actual large tree');check(B.tree.note:GetText():find('11'),'show real unspent count')</code> | 测试断言：check(B.ShowTree(token,1),'open actual large tree');check(B.tree.note:GetText():find('11'),'show real unspent count')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 83 | <code> local id=D.trees[1][1].id</code> | 定义局部变量：local id=D.trees[1][1].id；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 84 | <code> local button=B.board.buttons[1];check(type(button.node.onClick)=='function','first show already has live click handlers')</code> | 测试断言：local button=B.board.buttons[1];check(type(button.node.onClick)=='function','first show already has live click handlers')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 85 | <code> local initial=current[1][1];local before=sent</code> | 定义局部变量：local initial=current[1][1];local before=sent；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 86 | <code> check(B.AddNativePoint(id),'one point queued through original native engine')</code> | 测试断言：check(B.AddNativePoint(id),'one point queued through original native engine')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 87 | <code> check(not B.AddNativePoint(id),'duplicate click while waiting rejected')</code> | 测试断言：check(not B.AddNativePoint(id),'duplicate click while waiting rejected')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 88 | <code> clock=clock+.4;E.Tick();check(sent==before+1,'one LearnTalent request')</code> | 测试断言：clock=clock+.4;E.Tick();check(sent==before+1,'one LearnTalent request')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 89 | <code> check(current[1][1]==initial,'no optimistic learned-rank change before ack')</code> | 测试断言：check(current[1][1]==initial,'no optimistic learned-rank change before ack')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 90 | <code> B.RefreshTree();check(B.board.items[1].actual==initial,'new panel still shows old authoritative rank')</code> | 测试断言：B.RefreshTree();check(B.board.items[1].actual==initial,'new panel still shows old authoritative rank')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 91 | <code> ack();clock=clock+.4;E.Tick()</code> | 调用ack（模拟服务器确认后才改变已学；发出请求与确认是两个时间点）；此行参数来自当前上下文。 |
| 92 | <code> check(not E.job,'server confirmation completes task');check(current[1][1]==initial+1)</code> | 测试断言：check(not E.job,'server confirmation completes task');check(current[1][1]==initial+1)。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 93 | <code> local ranks=assert(E.Scan());check(B.board.items[1].actual==ranks[1][1],'new and native read same confirmed rank')</code> | 测试断言：local ranks=assert(E.Scan());check(B.board.items[1].actual==ranks[1][1],'new and native read same confirmed rank')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 94 | <code> -- Old-panel change and reset trigger the same existing event handler.</code> | 说明注释：Old-panel change and reset trigger the same existing event handler.；它不执行，实际条件仍以相邻代码为准。 |
| 95 | <code> current[1][1]=math.min(2,D.trees[1][1].max);B.events:GetScript('OnEvent')(B.events,'PLAYER_TALENT_UPDATE')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`current[1][1]=math.min(2,D.trees[1][1].max);B.events:GetScript('OnEvent')(B.events,'PLAYER_TALENT_UPDATE')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 96 | <code> check(B.board.items[1].actual==current[1][1],'old -&gt; new point event sync')</code> | 测试断言：check(B.board.items[1].actual==current[1][1],'old -> new point event sync')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 97 | <code> current[1][1]=0;B.events:GetScript('OnEvent')(B.events,'ACTIVE_TALENT_GROUP_CHANGED');check(B.board.items[1].actual==0,'old -&gt; new reset/group sync')</code> | 测试断言：current[1][1]=0;B.events:GetScript('OnEvent')(B.events,'ACTIVE_TALENT_GROUP_CHANGED');check(B.board.items[1].actual==0,'old -> new reset/group sync')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 98 | <code> before=sent;COMBAT=true;check(not B.AddNativePoint(id));COMBAT=false;DEAD=true;check(not B.AddNativePoint(id));DEAD=false</code> | 测试主动切入战斗状态；必须拒绝并且没有发出新加点请求。 测试死亡状态；必须拒绝并保持发送计数不变。 |
| 99 | <code> preview=1;check(not B.AddNativePoint(id),'unsaved native preview cannot be overwritten');preview=0</code> | 测试断言：preview=1;check(not B.AddNativePoint(id),'unsaved native preview cannot be overwritten');preview=0。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 100 | <code> G.BotRecommendations.mode=true;check(not B.AddNativePoint(id),'bot context never writes player');G.BotRecommendations.mode=false</code> | 测试断言：G.BotRecommendations.mode=true;check(not B.AddNativePoint(id),'bot context never writes player');G.BotRecommendations.mode=false。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 101 | <code> check(sent==before and not E.job,'rejections submit zero points')</code> | 测试断言：check(sent==before and not E.job,'rejections submit zero points')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 102 | <code> -- Prerequisite and full-rank rejection use actual native queue.</code> | 说明注释：Prerequisite and full-rank rejection use actual native queue.；它不执行，实际条件仍以相邻代码为准。 |
| 103 | <code> local last=D.trees[1][#D.trees[1]].id;check(not B.AddNativePoint(last),'cannot bypass tier gate')</code> | 测试断言：local last=D.trees[1][#D.trees[1]].id;check(not B.AddNativePoint(last),'cannot bypass tier gate')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 104 | <code> current[1][1]=D.trees[1][1].max;check(not B.AddNativePoint(id),'max rank cannot be exceeded')</code> | 测试断言：current[1][1]=D.trees[1][1].max;check(not B.AddNativePoint(id),'max rank cannot be exceeded')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 105 | <code> clear(token);B.ShowTree(token,1);check(B.AddNativePoint(id));group=2;clock=clock+.4;E.Tick();check(not E.job,'spec change cancels before submit')</code> | 测试断言：clear(token);B.ShowTree(token,1);check(B.AddNativePoint(id));group=2;clock=clock+.4;E.Tick();check(not E.job,'spec change cancels before submit')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 106 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 107 | <code>check(OUTBOUND==0,'no chat commands, charges or alternate protocol writes')</code> | 测试断言：check(OUTBOUND==0,'no chat commands, charges or alternate protocol writes')。把期望行为写成可失败条件，并计入检查数；不是游戏运行代码。 |
| 108 | <code>RESULT='PASS '..CHECKS..' actual Lua checks; native APIs/widgets/ack events substituted; no game rendering'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`RESULT='PASS '..CHECKS..' actual Lua checks; native APIs/widgets/ack events substituted; no game rendering'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 109 | <code>'''</code> | 此行属于“local function ack()”：`'''`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 110 | <code>l.execute(script)</code> | 此行属于“local function ack()”：`l.execute(script)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 111 | <code>(P/'checks/test_results.json').write_text(json.dumps({'checks':l.globals().CHECKS,'result':l.globals().RESULT,'game':'未运行','boundary':'Actual current addon TOC/code loaded with native API/widget/server acknowledgment substitutions. Not actual WoW rendering or server networking.'},ensure_ascii=False,indent=2),encoding='utf-8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 112 | <code>print(l.globals().RESULT)</code> | 把测试结果/计数输出为证据；前面的断言都没失败才能走到这里。 |
