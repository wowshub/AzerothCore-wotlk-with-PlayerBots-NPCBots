# 天赋_ClassicTalentLive.lua：逐行讲解
本次新文件全行。按服务器已学生成草稿，复用原NativeEngine，不自行乐观修改已学。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261107\codexfix_20261107_072718_阶段TGFIX1B_当前已学绿色醒目与经典天赋累计修复\02_覆盖到客户端根目录\Interface\AddOns\RebornTalentGuide\ClassicTalentLive.lua`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `levelBuild` | 从已有满级推荐的合法顺序取当前等级预算的前缀，不发明节点 |
| `Recommendation` | 给展示/收藏/应用返回同一当前等级推荐，避免看11点却用71点 |
| `liveClass` | 只有本人经典原生职业接逐点功能，不给武僧/巫医/猎巫套此协议 |
| `busy` | 统一判断已有申请、等确认、机器人等上下文，阻止并发误写玩家 |
| `candidate` | 捕获服务器真实已学，在独立草稿+1；不直接改已学状态 |
| `AddNativePoint` | 校验草稿后交给原NativeEngine发LearnTalent并等待确认 |
| `RefreshTree` | 重读原生已学和余点，连接按钮、可加绿框和解释文字 |
| `ShowTree` | 首次显示后再刷新，避免第一次打开没接上点击函数 |

## 原代码
```lua
-- TGFIX1A: native-class allocations remain authoritative in the original server/API.
-- This file never writes learned ranks, saved variables or preview points.
local G=RebornTalentGuide
local S=RebornTalentCollections
local B=G.ClassHome
local C=RebornTalentTreeCanvas
local function tr(zh,en)return G.CenterLocale and G.CenterLocale.English()and en or zh end

-- Same prerequisite-preserving prefix method already used by the other classes.
-- Prefer the full build's main tree, then its secondary trees; never invent nodes.
local function levelBuild(token,index,level)
 local data=S.NativeData(token);local engine=S.NativeEngine(token)
 local full=data and data.plans[index];if not full then return nil,'推荐方案不存在'end
 level=math.max(10,math.min(80,math.floor(tonumber(level)or UnitLevel('player'))))
 local empty={{},{},{}};for t,tree in ipairs(data.trees)do for i in ipairs(tree)do empty[t][i]=0 end end
 local queue,why=engine.Queue(full,empty);if not queue then return nil,why end
 local main,largest=full.spec or 1,-1
 if not full.spec then
  for t,ranks in ipairs(full.ranks)do local total=0;for _,rank in ipairs(ranks)do total=total+rank end;if total>largest then main,largest=t,total end end
 end
 local ordered={};for _,step in ipairs(queue)do if step.tab==main then ordered[#ordered+1]=step end end
 for _,step in ipairs(queue)do if step.tab~=main then ordered[#ordered+1]=step end end
 local plan={title=full.title,ranks=empty,split={0,0,0},level=level}
 for i=1,math.min(level-9,#ordered)do local step=ordered[i];empty[step.tab][step.index]=step.rank;plan.split[step.tab]=plan.split[step.tab]+1 end
 return plan
end
for _,token in ipairs({'WARRIOR','PALADIN'})do
 local class=token;local engine=S.NativeEngine(class)
 engine.Build=function(index,level)return levelBuild(class,index,level)end
 engine.previewCurrent=true
end
local oldRecommendation=S.Recommendation
function S.Recommendation(class)
 if class~='WARRIOR'and class~='PALADIN'then return oldRecommendation(class)end
 local engine=S.NativeEngine(class)
 local index=class=='WARRIOR'and G.selected or RebornTalentGuidePaladin.selected
 local bot=G.BotRecommendations
 local level=bot and bot.mode and bot.class==class and bot.level or UnitLevel('player')
 local plan,why=engine.Build(index or 1,engine.previewCurrent~=false and level or engine.previewLevel)
 if not plan then return nil,why end
 local build=S.Blank(class,plan.level)
 for t,tree in ipairs(S.NativeData(class).trees)do for i,node in ipairs(tree)do if plan.ranks[t][i]>0 then build.ranks[node.id]=plan.ranks[t][i]end end end
 return build,plan.title
end

local function liveClass(token)
 return token~='MONK'and S.NativeData(token)and S.Class()==token
end
local function busy()
 return S.ActiveNativeJob()or G.job or S.waiting or G.fromBot or (G.BotRecommendations and G.BotRecommendations.mode)
end
local function candidate(token,id)
 if not liveClass(token)then return nil,tr('只能给自己的经典职业加点','Only your own native class can allocate')end
 if busy()then return nil,tr('请等待当前操作确认','Wait for the current operation')end
 local build,why=S.Capture(token);if not build then return nil,why end
 local node=S.Nodes(token)[id];if not node then return nil,'未知天赋节点'end
 local rank=build.ranks[id]or 0;if rank>=node.max then return nil,'该天赋已满级'end
 build.ranks[id]=rank+1
 return build
end
function B.AddNativePoint(id)
 if not B.tree or not B.tree:IsShown()then return false,'天赋面板已关闭'end
 local token=B.token;local build,why=candidate(token,id)
 if not build then B.liveMessage=why;B.RefreshTree();return false,why end
 -- The existing engine checks combat/death, preview drafts, budget, dependencies,
 -- class and active group. It sends one LearnTalent and waits for the server rank.
 local context,err=S.CanApply(build,B.tree)
 if not context then B.liveMessage=err;B.RefreshTree();return false,err end
 local ok,msg=S.NativeEngine(token).StartPlan(context.plan,B.tree,function(success,reason)
  B.liveMessage=reason or(success and tr('服务器已确认加点','Server confirmed the point')or tr('加点停止，已确认点数保留','Stopped; confirmed points retained'))
  if B.tree and B.tree:IsShown()then B.RefreshTree()end
 end)
 B.liveMessage=msg or(ok and tr('等待服务器确认；新旧面板以相同已学点数刷新','Waiting for the server; both panels use the same learned ranks')or tr('无法提交加点','Cannot submit'))
 B.RefreshTree();return ok,msg
end

local oldRefresh=B.RefreshTree
function B.RefreshTree()
 oldRefresh()
 if not B.tree or not B.tree:IsShown()or not liveClass(B.token)then return end
 local token=B.token;local engine=S.NativeEngine(token)
 local ranks,why=engine.Scan()
 local group=GetActiveTalentGroup(false,false)
 local free=group and GetUnspentTalentPoints(false,false,group)
 local allowed=ranks and type(free)=='number'and free>0 and not busy()and not InCombatLockdown()and not UnitIsDeadOrGhost('player')
 local preview=group and GetGroupPreviewTalentPointsSpent and GetGroupPreviewTalentPointsSpent(false,group)or 0
 allowed=allowed and preview==0
 for _,button in ipairs(B.board.buttons or{})do
  local item=button.node
  if item then
   local id=item.id
   item.onClick=function(mouse)if mouse=='LeftButton'or mouse==nil then B.AddNativePoint(id)end end
   local purchasable=false
   if allowed then
    local build=candidate(token,id)
    if build then
     local plan=S.NativePlan(build)
     local queue=engine.Queue(plan,ranks)
     purchasable=queue and #queue==1
    end
   end
   if purchasable then
    button.icon:SetDesaturated(false);button.icon:SetVertexColor(1,1,1,1)
    C.Atlas(button.border,'talents-node-'..(item.shape or'square')..'-green')
    button.rank:SetTextColor(.2,1,.2)
   end
   item.tooltip=function(tooltip)
    tooltip:AddLine((item.name or'')..' / TalentID '..id,1,.82,.3,true)
    tooltip:AddLine(tr('服务器已学：','Server learned: ')..tostring(item.actual or 0)..'/'..item.maximum,1,1,1,true)
    tooltip:AddLine(tr('左键：按原生接口加一点；服务器确认后生效。','Left click: add one point through the native API; wait for server confirmation.'),.2,1,.2,true)
   end
  end
 end
 B.tree.title:SetText((B.tree.title:GetText()or''):gsub('TG31A','TGFIX1A'))
 B.tree.note:SetText(B.liveMessage or why or(tr('可用天赋点：','Unspent talent points: ')..tostring(free or tr('未同步','unavailable'))..tr(' · 绿框可加点；新旧面板同步 · 洗点沿原流程',' / Green nodes available; both panels share native ranks; reset through the original flow')))
 if B.info then
  B.info:SetText(tr('当前职业天赋\n\n左键绿色节点：实际加一点。\n金色：服务器已学；灰色：前置或点数不足。\n\n可用点数：','Current class talents\n\nLeft-click a green node to add one real point.\nGold: learned; gray: unavailable.\n\nUnspent points: ')..tostring(free or tr('未同步','unavailable'))..tr('\n\n与原经典天赋面板共用服务器数据。\n不自动洗点、不收费、不切换专精。\n\n武僧/巫医/猎巫沿各自已有协议。','\n\nShares the server state with the native talent panel.\nNo automatic reset, charge or spec switch.\n\nCustom classes keep their existing protocols.'))
 end
end

local oldShow=B.ShowTree
function B.ShowTree(...)
 local ok=oldShow(...)
 if ok then B.liveMessage=nil;B.RefreshTree()end
 return ok
end

-- PLAYER_TALENT_UPDATE is already registered by ClassicSpecHome. A native-panel
-- point/reset/group change reaches this wrapper; no local learned-rank cache exists.
G.ClassicTalentLive={Build=levelBuild,Candidate=candidate,Version='TGFIX1A'}
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>-- TGFIX1A: native-class allocations remain authoritative in the original server/API.</code> | 说明注释：TGFIX1A: native-class allocations remain authoritative in the original server/API.；它不执行，实际条件仍以相邻代码为准。 |
| 2 | <code>-- This file never writes learned ranks, saved variables or preview points.</code> | 说明注释：This file never writes learned ranks, saved variables or preview points.；它不执行，实际条件仍以相邻代码为准。 |
| 3 | <code>local G=RebornTalentGuide</code> | 定义局部变量：local G=RebornTalentGuide；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 4 | <code>local S=RebornTalentCollections</code> | 定义局部变量：local S=RebornTalentCollections；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 5 | <code>local B=G.ClassHome</code> | 定义局部变量：local B=G.ClassHome；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 6 | <code>local C=RebornTalentTreeCanvas</code> | 定义局部变量：local C=RebornTalentTreeCanvas；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 7 | <code>local function tr(zh,en)return G.CenterLocale and G.CenterLocale.English()and en or zh end</code> | 定义局部变量：local function tr(zh,en)return G.CenterLocale and G.CenterLocale.English()and en or zh end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 8 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 9 | <code>-- Same prerequisite-preserving prefix method already used by the other classes.</code> | 说明注释：Same prerequisite-preserving prefix method already used by the other classes.；它不执行，实际条件仍以相邻代码为准。 |
| 10 | <code>-- Prefer the full build's main tree, then its secondary trees; never invent nodes.</code> | 说明注释：Prefer the full build's main tree, then its secondary trees; never invent nodes.；它不执行，实际条件仍以相邻代码为准。 |
| 11 | <code>local function levelBuild(token,index,level)</code> | 定义/进入函数：从已有满级推荐的合法顺序取当前等级预算的前缀，不发明节点。 |
| 12 | <code> local data=S.NativeData(token);local engine=S.NativeEngine(token)</code> | 定义局部变量：local data=S.NativeData(token);local engine=S.NativeEngine(token)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 13 | <code> local full=data and data.plans[index];if not full then return nil,'推荐方案不存在'end</code> | 定义局部变量：local full=data and data.plans[index];if not full then return nil,'推荐方案不存在'end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 14 | <code> level=math.max(10,math.min(80,math.floor(tonumber(level)or UnitLevel('player'))))</code> | 把等级转数字/取整并夹在10–80，不让缺值或超范围产生非法预算。 |
| 15 | <code> local empty={{},{},{}};for t,tree in ipairs(data.trees)do for i in ipairs(tree)do empty[t][i]=0 end end</code> | 定义局部变量：local empty={{},{},{}};for t,tree in ipairs(data.trees)do for i in ipairs(tree)do empty[t][i]=0 end end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 16 | <code> local queue,why=engine.Queue(full,empty);if not queue then return nil,why end</code> | 按已有天赋规则把满级方案排成合法逐点序列，不能跳过前置。 |
| 17 | <code> local main,largest=full.spec or 1,-1</code> | 定义局部变量：local main,largest=full.spec or 1,-1；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 18 | <code> if not full.spec then</code> | 条件分支：只有`if not full.spec`成立才走随后分支；不满足进入else/跳过。 |
| 19 | <code>  for t,ranks in ipairs(full.ranks)do local total=0;for _,rank in ipairs(ranks)do total=total+rank end;if total&gt;largest then main,largest=t,total end end</code> | 循环：for t,ranks in ipairs(full.ranks)do local total=0;for _,rank in ipairs(ranks)do total=total+rank end;if total>largest then main,largest=t,total end end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 20 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 21 | <code> local ordered={};for _,step in ipairs(queue)do if step.tab==main then ordered[#ordered+1]=step end end</code> | 定义局部变量：local ordered={};for _,step in ipairs(queue)do if step.tab==main then ordered[#ordered+1]=step end end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 22 | <code> for _,step in ipairs(queue)do if step.tab~=main then ordered[#ordered+1]=step end end</code> | 循环：for _,step in ipairs(queue)do if step.tab~=main then ordered[#ordered+1]=step end end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 23 | <code> local plan={title=full.title,ranks=empty,split={0,0,0},level=level}</code> | 定义局部变量：local plan={title=full.title,ranks=empty,split={0,0,0},level=level}；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 24 | <code> for i=1,math.min(level-9,#ordered)do local step=ordered[i];empty[step.tab][step.index]=step.rank;plan.split[step.tab]=plan.split[step.tab]+1 end</code> | 可用预算=等级-9：20级11点、60级51点、80级71点；只取队列允许步数。 |
| 25 | <code> return plan</code> | 返回表达式`plan`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 26 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 27 | <code>for _,token in ipairs({'WARRIOR','PALADIN'})do</code> | 循环：for _,token in ipairs({'WARRIOR','PALADIN'})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 28 | <code> local class=token;local engine=S.NativeEngine(class)</code> | 定义局部变量：local class=token;local engine=S.NativeEngine(class)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 29 | <code> engine.Build=function(index,level)return levelBuild(class,index,level)end</code> | 调用levelBuild（从已有满级推荐的合法顺序取当前等级预算的前缀，不发明节点）；此行参数来自当前上下文。 |
| 30 | <code> engine.previewCurrent=true</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`engine.previewCurrent=true`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 31 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 32 | <code>local oldRecommendation=S.Recommendation</code> | 定义局部变量：local oldRecommendation=S.Recommendation；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 33 | <code>function S.Recommendation(class)</code> | 定义/进入函数：给展示/收藏/应用返回同一当前等级推荐，避免看11点却用71点。 |
| 34 | <code> if class~='WARRIOR'and class~='PALADIN'then return oldRecommendation(class)end</code> | 条件分支：只有`if class~='WARRIOR'and class~='PALADIN' return oldRecommendation(class)end`成立才走随后分支；不满足进入else/跳过。 |
| 35 | <code> local engine=S.NativeEngine(class)</code> | 定义局部变量：local engine=S.NativeEngine(class)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 36 | <code> local index=class=='WARRIOR'and G.selected or RebornTalentGuidePaladin.selected</code> | 定义局部变量：local index=class=='WARRIOR'and G.selected or RebornTalentGuidePaladin.selected；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 37 | <code> local bot=G.BotRecommendations</code> | 定义局部变量：local bot=G.BotRecommendations；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 38 | <code> local level=bot and bot.mode and bot.class==class and bot.level or UnitLevel('player')</code> | 定义局部变量：local level=bot and bot.mode and bot.class==class and bot.level or UnitLevel('player')；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 39 | <code> local plan,why=engine.Build(index or 1,engine.previewCurrent~=false and level or engine.previewLevel)</code> | 定义局部变量：local plan,why=engine.Build(index or 1,engine.previewCurrent~=false and level or engine.previewLevel)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 40 | <code> if not plan then return nil,why end</code> | 条件分支：只有`if not plan  return nil,why end`成立才走随后分支；不满足进入else/跳过。 |
| 41 | <code> local build=S.Blank(class,plan.level)</code> | 定义局部变量：local build=S.Blank(class,plan.level)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 42 | <code> for t,tree in ipairs(S.NativeData(class).trees)do for i,node in ipairs(tree)do if plan.ranks[t][i]&gt;0 then build.ranks[node.id]=plan.ranks[t][i]end end end</code> | 循环：for t,tree in ipairs(S.NativeData(class).trees)do for i,node in ipairs(tree)do if plan.ranks[t][i]>0 then build.ranks[node.id]=plan.ranks[t][i]end end end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 43 | <code> return build,plan.title</code> | 返回表达式`build,plan.title`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 44 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 45 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 46 | <code>local function liveClass(token)</code> | 定义/进入函数：只有本人经典原生职业接逐点功能，不给武僧/巫医/猎巫套此协议。 |
| 47 | <code> return token~='MONK'and S.NativeData(token)and S.Class()==token</code> | 返回表达式`token~='MONK'and S.NativeData(token)and S.Class()==token`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 48 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 49 | <code>local function busy()</code> | 定义/进入函数：统一判断已有申请、等确认、机器人等上下文，阻止并发误写玩家。 |
| 50 | <code> return S.ActiveNativeJob()or G.job or S.waiting or G.fromBot or (G.BotRecommendations and G.BotRecommendations.mode)</code> | 返回表达式`S.ActiveNativeJob()or G.job or S.waiting or G.fromBot or (G.BotRecommendations and G.BotRecommendations.mode)`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 51 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 52 | <code>local function candidate(token,id)</code> | 定义/进入函数：捕获服务器真实已学，在独立草稿+1；不直接改已学状态。 |
| 53 | <code> if not liveClass(token)then return nil,tr('只能给自己的经典职业加点','Only your own native class can allocate')end</code> | 条件分支：只有`if not liveClass(token) return nil,tr('只能给自己的经典职业加点','Only your own native class can allocate')end`成立才走随后分支；不满足进入else/跳过。 |
| 54 | <code> if busy()then return nil,tr('请等待当前操作确认','Wait for the current operation')end</code> | 条件分支：只有`if busy() return nil,tr('请等待当前操作确认','Wait for the current operation')end`成立才走随后分支；不满足进入else/跳过。 |
| 55 | <code> local build,why=S.Capture(token);if not build then return nil,why end</code> | 捕获当前服务器已学为独立草稿；后续+1不能直接写真实已学缓存。 |
| 56 | <code> local node=S.Nodes(token)[id];if not node then return nil,'未知天赋节点'end</code> | 定义局部变量：local node=S.Nodes(token)[id];if not node then return nil,'未知天赋节点'end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 57 | <code> local rank=build.ranks[id]or 0;if rank&gt;=node.max then return nil,'该天赋已满级'end</code> | 定义局部变量：local rank=build.ranks[id]or 0;if rank>=node.max then return nil,'该天赋已满级'end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 58 | <code> build.ranks[id]=rank+1</code> | 只修改候选草稿中的一个节点，仍须CanApply及服务器确认才生效。 |
| 59 | <code> return build</code> | 返回表达式`build`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 60 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 61 | <code>function B.AddNativePoint(id)</code> | 定义/进入函数：校验草稿后交给原NativeEngine发LearnTalent并等待确认。 |
| 62 | <code> if not B.tree or not B.tree:IsShown()then return false,'天赋面板已关闭'end</code> | 条件分支：只有`if not B.tree or not B.tree:IsShown() return false,'天赋面板已关闭'end`成立才走随后分支；不满足进入else/跳过。 |
| 63 | <code> local token=B.token;local build,why=candidate(token,id)</code> | 定义局部变量：local token=B.token;local build,why=candidate(token,id)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 64 | <code> if not build then B.liveMessage=why;B.RefreshTree();return false,why end</code> | 只保存操作提示，不是已学点数；服务器确认才能改变已学。 |
| 65 | <code> -- The existing engine checks combat/death, preview drafts, budget, dependencies,</code> | 说明注释：The existing engine checks combat/death, preview drafts, budget, dependencies,；它不执行，实际条件仍以相邻代码为准。 |
| 66 | <code> -- class and active group. It sends one LearnTalent and waits for the server rank.</code> | 说明注释：class and active group. It sends one LearnTalent and waits for the server rank.；它不执行，实际条件仍以相邻代码为准。 |
| 67 | <code> local context,err=S.CanApply(build,B.tree)</code> | 复用原引擎的预算/前置/职业/战斗/死亡/草稿/天赋组检查。 |
| 68 | <code> if not context then B.liveMessage=err;B.RefreshTree();return false,err end</code> | 只保存操作提示，不是已学点数；服务器确认才能改变已学。 |
| 69 | <code> local ok,msg=S.NativeEngine(token).StartPlan(context.plan,B.tree,function(success,reason)</code> | 提交给现有NativeEngine逐点任务，真正发送LearnTalent并等待原生读回。 |
| 70 | <code>  B.liveMessage=reason or(success and tr('服务器已确认加点','Server confirmed the point')or tr('加点停止，已确认点数保留','Stopped; confirmed points retained'))</code> | 只保存操作提示，不是已学点数；服务器确认才能改变已学。 |
| 71 | <code>  if B.tree and B.tree:IsShown()then B.RefreshTree()end</code> | 条件分支：只有`if B.tree and B.tree:IsShown() B.RefreshTree()end`成立才走随后分支；不满足进入else/跳过。 |
| 72 | <code> end)</code> | 结束当前代码块/回调定义，并按末尾语句返回或登记结果。 |
| 73 | <code> B.liveMessage=msg or(ok and tr('等待服务器确认；新旧面板以相同已学点数刷新','Waiting for the server; both panels use the same learned ranks')or tr('无法提交加点','Cannot submit'))</code> | 只保存操作提示，不是已学点数；服务器确认才能改变已学。 |
| 74 | <code> B.RefreshTree();return ok,msg</code> | 调用RefreshTree（重读原生已学和余点，连接按钮、可加绿框和解释文字）；此行参数来自当前上下文。 |
| 75 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 76 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 77 | <code>local oldRefresh=B.RefreshTree</code> | 保存已有刷新函数，包装增强而不丢旧布局绘制逻辑。 |
| 78 | <code>function B.RefreshTree()</code> | 定义/进入函数：重读原生已学和余点，连接按钮、可加绿框和解释文字。 |
| 79 | <code> oldRefresh()</code> | 先沿已有布局画树，再添加原生逐点资格/事件，不复制另一整套绘制器。 |
| 80 | <code> if not B.tree or not B.tree:IsShown()or not liveClass(B.token)then return end</code> | 条件分支：只有`if not B.tree or not B.tree:IsShown()or not liveClass(B.token) return end`成立才走随后分支；不满足进入else/跳过。 |
| 81 | <code> local token=B.token;local engine=S.NativeEngine(token)</code> | 定义局部变量：local token=B.token;local engine=S.NativeEngine(token)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 82 | <code> local ranks,why=engine.Scan()</code> | 定义局部变量：local ranks,why=engine.Scan()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 83 | <code> local group=GetActiveTalentGroup(false,false)</code> | 使用当前原生天赋组；请求中途换组应取消而非加到另一组。 |
| 84 | <code> local free=group and GetUnspentTalentPoints(false,false,group)</code> | 读取当前天赋组真实余点，不根据图标颜色推算玩家余额。 |
| 85 | <code> local allowed=ranks and type(free)=='number'and free&gt;0 and not busy()and not InCombatLockdown()and not UnitIsDeadOrGhost('player')</code> | 定义局部变量：local allowed=ranks and type(free)=='number'and free>0 and not busy()and not InCombatLockdown()and not UnitIsDeadOrGhost('player')；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 86 | <code> local preview=group and GetGroupPreviewTalentPointsSpent and GetGroupPreviewTalentPointsSpent(false,group)or 0</code> | 检测原生未保存预览，不能用新树覆盖玩家尚未确认的草稿。 |
| 87 | <code> allowed=allowed and preview==0</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`allowed=allowed and preview==0`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 88 | <code> for _,button in ipairs(B.board.buttons or{})do</code> | 循环：for _,button in ipairs(B.board.buttons or{})do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 89 | <code>  local item=button.node</code> | 定义局部变量：local item=button.node；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 90 | <code>  if item then</code> | 条件分支：只有`if item`成立才走随后分支；不满足进入else/跳过。 |
| 91 | <code>   local id=item.id</code> | 定义局部变量：local id=item.id；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 92 | <code>   item.onClick=function(mouse)if mouse=='LeftButton'or mouse==nil then B.AddNativePoint(id)end end</code> | 给节点连接左键函数；其它鼠标按钮不新增学习副作用。 |
| 93 | <code>   local purchasable=false</code> | 定义局部变量：local purchasable=false；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 94 | <code>   if allowed then</code> | 条件分支：只有`if allowed`成立才走随后分支；不满足进入else/跳过。 |
| 95 | <code>    local build=candidate(token,id)</code> | 定义局部变量：local build=candidate(token,id)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 96 | <code>    if build then</code> | 条件分支：只有`if build`成立才走随后分支；不满足进入else/跳过。 |
| 97 | <code>     local plan=S.NativePlan(build)</code> | 定义局部变量：local plan=S.NativePlan(build)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 98 | <code>     local queue=engine.Queue(plan,ranks)</code> | 用现有已学到候选草稿求增量，只允许正好1步的节点亮绿。 |
| 99 | <code>     purchasable=queue and #queue==1</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`purchasable=queue and #queue==1`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 100 | <code>    end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 101 | <code>   end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 102 | <code>   if purchasable then</code> | 条件分支：只有`if purchasable`成立才走随后分支；不满足进入else/跳过。 |
| 103 | <code>    button.icon:SetDesaturated(false);button.icon:SetVertexColor(1,1,1,1)</code> | 取消可购买节点的去色；不擅自给尚未解锁节点上色。 |
| 104 | <code>    C.Atlas(button.border,'talents-node-'..(item.shape or'square')..'-green')</code> | 使用现有节点形状图集；绿框只表示当前可加，不是已激活专精。 |
| 105 | <code>    button.rank:SetTextColor(.2,1,.2)</code> | 此行属于“function B.RefreshTree()”：`button.rank:SetTextColor(.2,1,.2)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 106 | <code>   end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 107 | <code>   item.tooltip=function(tooltip)</code> | 生成当前节点说明，展示真实TalentID、服务器已学与点击规则。 |
| 108 | <code>    tooltip:AddLine((item.name or'')..' / TalentID '..id,1,.82,.3,true)</code> | 此行属于“function B.RefreshTree()”：`tooltip:AddLine((item.name or'')..' / TalentID '..id,1,.82,.3,true)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 109 | <code>    tooltip:AddLine(tr('服务器已学：','Server learned: ')..tostring(item.actual or 0)..'/'..item.maximum,1,1,1,true)</code> | 此行属于“function B.RefreshTree()”：`tooltip:AddLine(tr('服务器已学：','Server learned: ')..tostring(item.actual or 0)..'/'..item.maximum,1,1,1,true)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 110 | <code>    tooltip:AddLine(tr('左键：按原生接口加一点；服务器确认后生效。','Left click: add one point through the native API; wait for server confirmation.'),.2,1,.2,true)</code> | 此行属于“function B.RefreshTree()”：`tooltip:AddLine(tr('左键：按原生接口加一点；服务器确认后生效。','Left click: add one point through the native API; wait for server confirmation.'),.2,1,.2,true)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 111 | <code>   end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 112 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 113 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 114 | <code> B.tree.title:SetText((B.tree.title:GetText()or''):gsub('TG31A','TGFIX1A'))</code> | 此行属于“function B.RefreshTree()”：`B.tree.title:SetText((B.tree.title:GetText()or''):gsub('TG31A','TGFIX1A'))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 115 | <code> B.tree.note:SetText(B.liveMessage or why or(tr('可用天赋点：','Unspent talent points: ')..tostring(free or tr('未同步','unavailable'))..tr(' · 绿框可加点；新旧面板同步 · 洗点沿原流程',' / Green nodes available; both panels share native ranks; reset through the original flow')))</code> | 只保存操作提示，不是已学点数；服务器确认才能改变已学。 |
| 116 | <code> if B.info then</code> | 条件分支：只有`if B.info`成立才走随后分支；不满足进入else/跳过。 |
| 117 | <code>  B.info:SetText(tr('当前职业天赋\n\n左键绿色节点：实际加一点。\n金色：服务器已学；灰色：前置或点数不足。\n\n可用点数：','Current class talents\n\nLeft-click a green node to add one real point.\nGold: learned; gray: unavailable.\n\nUnspent points: ')..tostring(free or tr('未同步','unavailable'))..tr('\n\n与原经典天赋面板共用服务器数据。\n不自动洗点、不收费、不切换专精。\n\n武僧/巫医/猎巫沿各自已有协议。','\n\nShares the server state with the native talent panel.\nNo automatic reset, charge or spec switch.\n\nCustom classes keep their existing protocols.'))</code> | 此行属于“function B.RefreshTree()”：`B.info:SetText(tr('当前职业天赋\n\n左键绿色节点：实际加一点。\n金色：服务器已学；灰色：前置或点数不足。\n\n可用点数：','Current class talents\n\nLeft-click a green node to add one real point.\nGold: learned; gray: unavailable.\n\nUnspent points: ')..tostring(free or tr('未同步','unavailable'))..tr('\n\n与原经典天赋面板共用服务器数据。\n不自动洗点、不收费、不切换专精。\n\n武僧/巫医/猎巫沿各自已有协议。','\n\nShares the server state with the native talent panel.\nNo automatic reset, charge or spec switch.\n\nCustom classes keep their existing protocols.'))`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 118 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 119 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 120 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 121 | <code>local oldShow=B.ShowTree</code> | 保存原ShowTree，让包装函数在首次创建显示之后再接入刷新。 |
| 122 | <code>function B.ShowTree(...)</code> | 定义/进入函数：首次显示后再刷新，避免第一次打开没接上点击函数。 |
| 123 | <code> local ok=oldShow(...)</code> | 先沿原流程创建/显示树，再刷新挂点击，修第一次打开尚无处理器的时序。 |
| 124 | <code> if ok then B.liveMessage=nil;B.RefreshTree()end</code> | 只保存操作提示，不是已学点数；服务器确认才能改变已学。 |
| 125 | <code> return ok</code> | 返回表达式`ok`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 126 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 127 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 128 | <code>-- PLAYER_TALENT_UPDATE is already registered by ClassicSpecHome. A native-panel</code> | 说明注释：PLAYER_TALENT_UPDATE is already registered by ClassicSpecHome. A native-panel；它不执行，实际条件仍以相邻代码为准。 |
| 129 | <code>-- point/reset/group change reaches this wrapper; no local learned-rank cache exists.</code> | 说明注释：point/reset/group change reaches this wrapper; no local learned-rank cache exists.；它不执行，实际条件仍以相邻代码为准。 |
| 130 | <code>G.ClassicTalentLive={Build=levelBuild,Candidate=candidate,Version='TGFIX1A'}</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`G.ClassicTalentLive={Build=levelBuild,Candidate=candidate,Version='TGFIX1A'}`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
