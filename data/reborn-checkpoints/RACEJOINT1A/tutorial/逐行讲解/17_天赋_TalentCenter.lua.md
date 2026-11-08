# 天赋_TalentCenter.lua：逐行讲解
B保留A三文件，另将首页已学14号描边绿色；这里只讲实际变化行及必要上下文。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261107\codexfix_20261107_072718_阶段TGFIX1B_当前已学绿色醒目与经典天赋累计修复\02_覆盖到客户端根目录\Interface\AddOns\RebornTalentGuide\TalentCenter.lua`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `Open` | 上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它 |
| `Recommendation` | 给展示/收藏/应用返回同一当前等级推荐，避免看11点却用71点 |
| `stop` | 只停止本脚本自己启动的隔离MySQL，释放日志句柄 |

## 本次修改涉及的实际代码片段

原件第26–30行：
```lua
end
local function plans()
 if T.class=='WITCHDOCTOR'then return RebornTalentGuideWDData.plans elseif T.class=='WARRIOR'then return RebornTalentGuideData.plans elseif T.class=='PALADIN'then return RebornTalentGuidePaladinData.plans elseif S.NativeData(T.class)~=nil then return S.NativeData(T.class).plans end
 return {}
end
```

原件第36–40行：
```lua
local function choose(index)
 T.selected[T.class]=index
 if T.class=='WITCHDOCTOR'then W.selected=index elseif T.class=='WARRIOR'then G.selected=index elseif T.class=='PALADIN'then RebornTalentGuidePaladin.selected=index elseif S.NativeData(T.class)~=nil then S.NativeEngine(T.class).selected=index end
end
local function dataClass()return S.NativeData(T.class)end
```

原件第129–145行：
```lua
 T.rename=button(616,-740,105,'重命名',T.Rename);T.delete=button(730,-740,105,'删除',T.Delete)
 T.applySaved=button(850,-740,230,'比较并应用此天赋',function()S.RequestApply()end,'red')
 T.editSaved=button(1090,-740,190,'编辑收藏',function()local id=T.favorite;if (S.NativeData(T.class)~=nil)and id then stop();T.frame:Hide();S.Open(T.class,function()S.Load(id)end)end end)
 T.detailsButton=button(1092,-740,205,'查看方案说明',function()
  if T.details:IsShown()then T.details:Hide()else
   local p=plans()[selected()];local lines={p and L.Plan(p,'title')or L.Text('天赋说明'),p and L.Plan(p,p.purpose and'purpose'or'body')or'',p and L.Plan(p,'stats')or'',p and L.Plan(p,'conflicts')or''}
   for _,line in ipairs(p and L.Plan(p,'rotation')or{})do lines[#lines+1]=line end
   put(T.detailsText,table.concat(lines,'\n\n'));T.details:SetFrameStrata('TOOLTIP');T.details:Raise();T.details:Show()
  end
 end)
 T.details=CreateFrame('Frame',nil,f);T.details:SetPoint('TOPLEFT',414,-142);T.details:SetSize(884,510);T.details:SetFrameStrata('TOOLTIP');T.details:SetFrameLevel(f:GetFrameLevel()+100);T.details:EnableMouse(true)
 T.details:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});T.details:SetBackdropColor(.025,.04,.05,1)
 T.detailsText=C.Text(T.details,22,-20,836,'','GameFontHighlight');T.detailsText:SetHeight(470);T.details:Hide()
 T.status=text(420,-779,865,'');T.status:SetHeight(32)
 T.levelButtons={};for i,level in ipairs({0,20,40,60,80})do local value=level;T.levelButtons[i]=button(416+(i-1)*108,-700,102,level==0 and'当前等级'or(level..'级'),function()stop();local adapter=(S.NativeData(T.class)~=nil)and S.NativeEngine(T.class)or W;local target=T.class=='DEATHKNIGHT'and({[0]=0,[20]=55,[40]=60,[60]=70,[80]=80})[value]or value;adapter.previewCurrent=target==0;adapter.previewLevel=target==0 and UnitLevel('player')or target;T.Refresh()end)end
 f:HookScript('OnHide',stop)
end
```

原件第191–196行：
```lua
local function paintNative(build)
 local data=dataClass();if not data then return false end
 local plan=build and S.NativePlan(build)or((S.NativeData(T.class)~=nil)and S.NativeEngine(T.class).Build(selected(),S.NativeEngine(T.class).previewCurrent~=false and subjectLevel()or S.NativeEngine(T.class).previewLevel)or data.plans[selected()]);if not plan then return false end
 local B=G.BotRecommendations;local own;if B and B.mode then if B.loaded and B.class==T.class then own={ranks=B.ranks}end else own=S.Capture(T.class)end;local treeNames=(S.NativeData(T.class)and S.NativeData(T.class).treeNames)or T.class=='WARRIOR'and{'武器','狂怒','防护'}or{'神圣','防护','惩戒'}
 for t,tree in ipairs(data.trees)do
  local board=T.boards[t];move(board,416+(t-1)*293,-144,285,498);board.width=265;board.height=450;board.canvas:SetSize(265,450);put(board.title,treeNames[t]);board:Show();local items,edges,ids={},{},{}
```

原件第213–217行：
```lua
 T.RefreshList();for _,b in ipairs(T.boards)do b:Hide()end
 for _,f in ipairs({T.collect,T.apply,T.rename,T.delete,T.applySaved,T.editSaved})do f:Hide()end
 for i,b in ipairs(T.levelButtons)do local lv=T.class=='DEATHKNIGHT'and({0,55,60,70,80})[i]or({0,20,40,60,80})[i];b:SetText(lv==0 and(L.English()and'Current'or'当前等级')or(tostring(lv)..(L.English()and' Lv'or'级'))); if favorite or(T.class~='WITCHDOCTOR'and not S.NativeData(T.class))then b:Hide()else b:Show()end end
 if favorite then T.detailsButton:Hide()else T.detailsButton:Show()end
 local data=plans();local p=data[selected()];local b,why;local result
```

原件第222–231行：
```lua
  T.heading:SetText(T.favorite and S.editor and S.editor.name or L.Text('当前天赋加点'));put(T.subtitle,T.favorite and'个人收藏 · 只读预览'or'与实际天赋面板已保存配点一致 · 不包含未保存草稿')
  if b then if b.class=='WITCHDOCTOR'then paintWD(b)else paintNative(b)end end
  if T.favorite and b then if S.NativeData(T.class)~=nil then T.editSaved:Show()end;T.rename:Show();T.delete:Show();T.applySaved:Show();local can,reason=S.CanApply(b,S.frame);enable(T.applySaved,can~=nil);why=reason end
 else
  put(T.heading,p and L.Plan(p,'title') or((names[T.class]or'')..' · 暂无推荐天赋'));put(T.subtitle,'推荐天赋 · '..T.scene..' · 只载入草稿或通过原生加点确认')
  if p then
   if T.class=='WITCHDOCTOR'then local lev=W.previewCurrent and subjectLevel()or W.previewLevel or subjectLevel();result,why=W.Build(selected(),lev);if result then paintWD(nil,result);put(T.subtitle,'推荐'..result.level..'级：AE '..result.ae..'/'..result.aeBudget..' · TE '..result.te..'/'..result.teBudget..'；保留已学，只载入草稿。')end
   else paintNative();if S.NativeData(T.class)~=nil then local H=S.NativeEngine(T.class);local v=H.Build(selected(),H.previewCurrent~=false and subjectLevel()or H.previewLevel);if v then T.subtitle:SetText((L.English()and 'Level 'or'等级 ')..v.level..' · '..table.concat(v.split,'/')..' · '..(L.English()and 'Reference allocation' or '本服参考配点'))end end end
   T.collect:Show();enable(T.collect,#S.List(T.class)<S.limit);T.apply:Show()
   if T.class=='WITCHDOCTOR'then local draft,reason=W.CheckDraft(selected(),W.previewCurrent and subjectLevel()or W.previewLevel or subjectLevel());enable(T.apply,draft~=nil);why=reason
```

原件第238–245行：
```lua
 if S.Class()==T.class and summary.ae then put(T.summary,summary.reason..'\n|cff65d5efAE 已加点 '..summary.ae..'/'..summary.aeBudget..'  未加点数 '..summary.aeLeft..'|r\n|cffffd060TE 已加点 '..summary.te..'/'..summary.teBudget..'  未加点数 '..summary.teLeft..'|r')
 else put(T.summary,S.Class()==T.class and('角色 '..UnitLevel('player')..'级 · 当前天赋以已保存数据为准')or'浏览其他职业 · 不显示为本人已加点')end
 if (S.NativeData(T.class)~=nil)and S.Class()==T.class then
  local own=S.Capture(T.class);if own then local total=0;for _,v in pairs(own.ranks)do total=total+v end;local free=GetUnspentTalentPoints(false,false,GetActiveTalentGroup(false,false));T.summary:SetText((L.English()and(T.class=='WARRIOR'and 'Warrior Lv. 'or T.class=='PALADIN'and 'Paladin Lv. 'or T.class=='MONK'and 'Monk Lv. 'or T.class=='DRUID'and 'Druid Lv. 'or T.class=='WARLOCK'and 'Warlock Lv. 'or T.class=='MAGE'and 'Mage Lv. 'or T.class=='SHAMAN'and 'Shaman Lv. 'or T.class=='DEATHKNIGHT'and 'Death Knight Lv. 'or T.class=='PRIEST'and 'Priest Lv. 'or T.class=='ROGUE'and 'Rogue Lv. 'or'Hunter Lv. ')or(names[T.class]..' 等级 '))..UnitLevel('player')..' · '..(L.English()and 'Spent 'or'已加点 ')..total..' / '..(L.English()and 'Unspent 'or'剩余 ')..tostring(free or '—'))end
 end
 enable(T.actual,S.Class()==T.class and not InCombatLockdown());put(T.status,why or T.message or(favorite and'保存收藏不会改变角色；应用需比较并确认。'or((S.NativeData(T.class)~=nil)and'原生参考方案；应用通过原生接口逐点确认，不自动洗点。'or'按推荐天赋加点：保留已学，只载入草稿；请在实际天赋面板核对保存。')));T.painting=false
end
local oldGOpen=G.Open;local oldSOpen=S.Open
```

原件第253–257行：
```lua
 end
 if not T.favorite or tab=='favorites'then T.favorite=nil end
 for _,token in ipairs({'WARRIOR','PALADIN'})do local engine=S.NativeEngine(token);if engine.previewCurrent==nil then engine.previewCurrent=true end end;W.previewCurrent=W.previewCurrent~=false;W.previewLevel=W.previewLevel or UnitLevel('player');C.Fit(T.frame);T.frame:Show();T.Refresh();Windows.Focus(T.frame);return true
end
function G.Open(fromBot)if fromBot then if T.frame then T.frame:Hide()end;return oldGOpen(fromBot)end;return T.Open('recommend')end
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 26 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 27 | <code>local function plans()</code> | 定义局部变量：local function plans()；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 28 | <code> if T.class=='WITCHDOCTOR'then return RebornTalentGuideWDData.plans elseif T.class=='WARRIOR'then return RebornTalentGuideData.plans elseif T.class=='PALADIN'then return RebornTalentGuidePaladinData.plans elseif S.NativeData(T.class)~=nil then return S.NativeData(T.class).plans end</code> | 条件分支：只有`if T.class=='WITCHDOCTOR' return RebornTalentGuideWDData.plans elseif T.class=='WARRIOR' return RebornTalentGuideData.plans elseif T.class=='PALADIN' return RebornTalentGuidePaladinData.plans elseif S.NativeData(T.class)~=nil  return S.NativeData(T.class).plans end`成立才走随后分支；不满足进入else/跳过。 |
| 29 | <code> return {}</code> | 返回表达式`{}`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 30 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 36 | <code>local function choose(index)</code> | 定义局部变量：local function choose(index)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 37 | <code> T.selected[T.class]=index</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`T.selected[T.class]=index`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 38 | <code> if T.class=='WITCHDOCTOR'then W.selected=index elseif T.class=='WARRIOR'then G.selected=index elseif T.class=='PALADIN'then RebornTalentGuidePaladin.selected=index elseif S.NativeData(T.class)~=nil then S.NativeEngine(T.class).selected=index end</code> | 条件分支：只有`if T.class=='WITCHDOCTOR' W.selected=index elseif T.class=='WARRIOR' G.selected=index elseif T.class=='PALADIN' RebornTalentGuidePaladin.selected=index elseif S.NativeData(T.class)~=nil  S.NativeEngine(T.class).selected=index end`成立才走随后分支；不满足进入else/跳过。 |
| 39 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 40 | <code>local function dataClass()return S.NativeData(T.class)end</code> | 定义局部变量：local function dataClass()return S.NativeData(T.class)end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 129 | <code> T.rename=button(616,-740,105,'重命名',T.Rename);T.delete=button(730,-740,105,'删除',T.Delete)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`T.rename=button(616,-740,105,'重命名',T.Rename);T.delete=button(730,-740,105,'删除',T.Delete)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 130 | <code> T.applySaved=button(850,-740,230,'比较并应用此天赋',function()S.RequestApply()end,'red')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`T.applySaved=button(850,-740,230,'比较并应用此天赋',function()S.RequestApply()end,'red')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 131 | <code> T.editSaved=button(1090,-740,190,'编辑收藏',function()local id=T.favorite;if (S.NativeData(T.class)~=nil)and id then stop();T.frame:Hide();S.Open(T.class,function()S.Load(id)end)end end)</code> | 调用Open（上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它）、stop（只停止本脚本自己启动的隔离MySQL，释放日志句柄）；此行参数来自当前上下文。 |
| 132 | <code> T.detailsButton=button(1092,-740,205,'查看方案说明',function()</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`T.detailsButton=button(1092,-740,205,'查看方案说明',function()`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 133 | <code>  if T.details:IsShown()then T.details:Hide()else</code> | 条件分支：只有`if T.details:IsShown() T.details:Hide()else`成立才走随后分支；不满足进入else/跳过。 |
| 134 | <code>   local p=plans()[selected()];local lines={p and L.Plan(p,'title')or L.Text('天赋说明'),p and L.Plan(p,p.purpose and'purpose'or'body')or'',p and L.Plan(p,'stats')or'',p and L.Plan(p,'conflicts')or''}</code> | 定义局部变量：local p=plans()[selected()];local lines={p and L.Plan(p,'title')or L.Text('天赋说明'),p and L.Plan(p,p.purpose and'purpose'or'body')or'',p and L.Plan(p,'stats')or'',p and L.Plan(p,'conflicts')or''}；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 135 | <code>   for _,line in ipairs(p and L.Plan(p,'rotation')or{})do lines[#lines+1]=line end</code> | 循环：for _,line in ipairs(p and L.Plan(p,'rotation')or{})do lines[#lines+1]=line end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 136 | <code>   put(T.detailsText,table.concat(lines,'\n\n'));T.details:SetFrameStrata('TOOLTIP');T.details:Raise();T.details:Show()</code> | 设置绘制层级大类；TOOLTIP让说明窗在天赋树和数字框上面。 把说明窗提升到同层前面，再显示它。 |
| 137 | <code>  end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 138 | <code> end)</code> | 结束当前代码块/回调定义，并按末尾语句返回或登记结果。 |
| 139 | <code> T.details=CreateFrame('Frame',nil,f);T.details:SetPoint('TOPLEFT',414,-142);T.details:SetSize(884,510);T.details:SetFrameStrata('TOOLTIP');T.details:SetFrameLevel(f:GetFrameLevel()+100);T.details:EnableMouse(true)</code> | 设置绘制层级大类；TOOLTIP让说明窗在天赋树和数字框上面。 设置同层绘制顺序；要超过子rankBox，不只是超过父面板。 接收鼠标，挡住对下面天赋节点的点击穿透。 |
| 140 | <code> T.details:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});T.details:SetBackdropColor(.025,.04,.05,1)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`T.details:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});T.details:SetBackdropColor(.025,.04,.05,1)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 141 | <code> T.detailsText=C.Text(T.details,22,-20,836,'','GameFontHighlight');T.detailsText:SetHeight(470);T.details:Hide()</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`T.detailsText=C.Text(T.details,22,-20,836,'','GameFontHighlight');T.detailsText:SetHeight(470);T.details:Hide()`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 142 | <code> T.status=text(420,-779,865,'');T.status:SetHeight(32)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`T.status=text(420,-779,865,'');T.status:SetHeight(32)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 143 | <code> T.levelButtons={};for i,level in ipairs({0,20,40,60,80})do local value=level;T.levelButtons[i]=button(416+(i-1)*108,-700,102,level==0 and'当前等级'or(level..'级'),function()stop();local adapter=(S.NativeData(T.class)~=nil)and S.NativeEngine(T.class)or W;local target=T.class=='DEATHKNIGHT'and({[0]=0,[20]=55,[40]=60,[60]=70,[80]=80})[value]or value;adapter.previewCurrent=target==0;adapter.previewLevel=target==0 and UnitLevel('player')or target;T.Refresh()end)end</code> | 调用stop（只停止本脚本自己启动的隔离MySQL，释放日志句柄）；此行参数来自当前上下文。 |
| 144 | <code> f:HookScript('OnHide',stop)</code> | 此行属于“local function dataClass()return S.NativeData(T.class)end”：`f:HookScript('OnHide',stop)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 145 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 191 | <code>local function paintNative(build)</code> | 定义局部变量：local function paintNative(build)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 192 | <code> local data=dataClass();if not data then return false end</code> | 定义局部变量：local data=dataClass();if not data then return false end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 193 | <code> local plan=build and S.NativePlan(build)or((S.NativeData(T.class)~=nil)and S.NativeEngine(T.class).Build(selected(),S.NativeEngine(T.class).previewCurrent~=false and subjectLevel()or S.NativeEngine(T.class).previewLevel)or data.plans[selected()]);if not plan then return false end</code> | 定义局部变量：local plan=build and S.NativePlan(build)or((S.NativeData(T.class)~=nil)and S.NativeEngine(T.class).Build(selected(),S.NativeEngine(T.class).previewCurrent~=false and subjectLevel()or S.NativeEngine(T.class).previewLevel)or data.plans[selected()]);if not plan then return false end；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 194 | <code> local B=G.BotRecommendations;local own;if B and B.mode then if B.loaded and B.class==T.class then own={ranks=B.ranks}end else own=S.Capture(T.class)end;local treeNames=(S.NativeData(T.class)and S.NativeData(T.class).treeNames)or T.class=='WARRIOR'and{'武器','狂怒','防护'}or{'神圣','防护','惩戒'}</code> | 定义局部变量：local B=G.BotRecommendations;local own;if B and B.mode then if B.loaded and B.class==T.class then own={ranks=B.ranks}end else own=S.Capture(T.class)end;local treeNames=(S.NativeData(T.class)and S.NativeData(T.class).treeNames)or T.class=='WARRIOR'and{'武器','狂怒','防护'}or{'神圣','防护','惩戒'}；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 195 | <code> for t,tree in ipairs(data.trees)do</code> | 循环：for t,tree in ipairs(data.trees)do；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 196 | <code>  local board=T.boards[t];move(board,416+(t-1)*293,-144,285,498);board.width=265;board.height=450;board.canvas:SetSize(265,450);put(board.title,treeNames[t]);board:Show();local items,edges,ids={},{},{}</code> | 定义局部变量：local board=T.boards[t];move(board,416+(t-1)*293,-144,285,498);board.width=265;board.height=450;board.canvas:SetSize(265,450);put(board.title,treeNames[t]);board:Show();local items,edges,ids={},{},{}；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 213 | <code> T.RefreshList();for _,b in ipairs(T.boards)do b:Hide()end</code> | 此行属于“local function paintNative(build)”：`T.RefreshList();for _,b in ipairs(T.boards)do b:Hide()end`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 214 | <code> for _,f in ipairs({T.collect,T.apply,T.rename,T.delete,T.applySaved,T.editSaved})do f:Hide()end</code> | 循环：for _,f in ipairs({T.collect,T.apply,T.rename,T.delete,T.applySaved,T.editSaved})do f:Hide()end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 215 | <code> for i,b in ipairs(T.levelButtons)do local lv=T.class=='DEATHKNIGHT'and({0,55,60,70,80})[i]or({0,20,40,60,80})[i];b:SetText(lv==0 and(L.English()and'Current'or'当前等级')or(tostring(lv)..(L.English()and' Lv'or'级'))); if favorite or(T.class~='WITCHDOCTOR'and not S.NativeData(T.class))then b:Hide()else b:Show()end end</code> | 循环：for i,b in ipairs(T.levelButtons)do local lv=T.class=='DEATHKNIGHT'and({0,55,60,70,80})[i]or({0,20,40,60,80})[i];b:SetText(lv==0 and(L.English()and'Current'or'当前等级')or(tostring(lv)..(L.English()and' Lv'or'级'))); if favorite or(T.class~='WITCHDOCTOR'and not S.NativeData(T.class))then b:Hide()else b:Show()end end；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 216 | <code> if favorite then T.detailsButton:Hide()else T.detailsButton:Show()end</code> | 条件分支：只有`if favorite  T.detailsButton:Hide()else T.detailsButton:Show()end`成立才走随后分支；不满足进入else/跳过。 |
| 217 | <code> local data=plans();local p=data[selected()];local b,why;local result</code> | 定义局部变量：local data=plans();local p=data[selected()];local b,why;local result；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 222 | <code>  T.heading:SetText(T.favorite and S.editor and S.editor.name or L.Text('当前天赋加点'));put(T.subtitle,T.favorite and'个人收藏 · 只读预览'or'与实际天赋面板已保存配点一致 · 不包含未保存草稿')</code> | 此行属于“local function paintNative(build)”：`T.heading:SetText(T.favorite and S.editor and S.editor.name or L.Text('当前天赋加点'));put(T.subtitle,T.favorite and'个人收藏 · 只读预览'or'与实际天赋面板已保存配点一致 · 不包含未保存草稿')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 223 | <code>  if b then if b.class=='WITCHDOCTOR'then paintWD(b)else paintNative(b)end end</code> | 条件分支：只有`if b  if b.class=='WITCHDOCTOR' paintWD(b)else paintNative(b)end end`成立才走随后分支；不满足进入else/跳过。 |
| 224 | <code>  if T.favorite and b then if S.NativeData(T.class)~=nil then T.editSaved:Show()end;T.rename:Show();T.delete:Show();T.applySaved:Show();local can,reason=S.CanApply(b,S.frame);enable(T.applySaved,can~=nil);why=reason end</code> | 复用原引擎的预算/前置/职业/战斗/死亡/草稿/天赋组检查。 |
| 225 | <code> else</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 226 | <code>  put(T.heading,p and L.Plan(p,'title') or((names[T.class]or'')..' · 暂无推荐天赋'));put(T.subtitle,'推荐天赋 · '..T.scene..' · 只载入草稿或通过原生加点确认')</code> | 此行属于“local function paintNative(build)”：`put(T.heading,p and L.Plan(p,'title') or((names[T.class]or'')..' · 暂无推荐天赋'));put(T.subtitle,'推荐天赋 · '..T.scene..' · 只载入草稿或通过原生加点确认')`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 227 | <code>  if p then</code> | 条件分支：只有`if p`成立才走随后分支；不满足进入else/跳过。 |
| 228 | <code>   if T.class=='WITCHDOCTOR'then local lev=W.previewCurrent and subjectLevel()or W.previewLevel or subjectLevel();result,why=W.Build(selected(),lev);if result then paintWD(nil,result);put(T.subtitle,'推荐'..result.level..'级：AE '..result.ae..'/'..result.aeBudget..' · TE '..result.te..'/'..result.teBudget..'；保留已学，只载入草稿。')end</code> | 条件分支：只有`if T.class=='WITCHDOCTOR' local lev=W.previewCurrent and subjectLevel()or W.previewLevel or subjectLevel();result,why=W.Build(selected(),lev);if result  paintWD(nil,result);put(T.subtitle,'推荐'..result.level..'级：AE '..result.ae..'/'..result.aeBudget..' · TE '..result.te..'/'..result.teBudget..'；保留已学，只载入草稿。')end`成立才走随后分支；不满足进入else/跳过。 |
| 229 | <code>   else paintNative();if S.NativeData(T.class)~=nil then local H=S.NativeEngine(T.class);local v=H.Build(selected(),H.previewCurrent~=false and subjectLevel()or H.previewLevel);if v then T.subtitle:SetText((L.English()and 'Level 'or'等级 ')..v.level..' · '..table.concat(v.split,'/')..' · '..(L.English()and 'Reference allocation' or '本服参考配点'))end end end</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 230 | <code>   T.collect:Show();enable(T.collect,#S.List(T.class)&lt;S.limit);T.apply:Show()</code> | 此行属于“local function paintNative(build)”：`T.collect:Show();enable(T.collect,#S.List(T.class)<S.limit);T.apply:Show()`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 231 | <code>   if T.class=='WITCHDOCTOR'then local draft,reason=W.CheckDraft(selected(),W.previewCurrent and subjectLevel()or W.previewLevel or subjectLevel());enable(T.apply,draft~=nil);why=reason</code> | 条件分支：只有`if T.class=='WITCHDOCTOR' local draft,reason=W.CheckDraft(selected(),W.previewCurrent and subjectLevel()or W.previewLevel or subjectLevel());enable(T.apply,draft~=nil);why=reason`成立才走随后分支；不满足进入else/跳过。 |
| 238 | <code> if S.Class()==T.class and summary.ae then put(T.summary,summary.reason..'\n&#124;cff65d5efAE 已加点 '..summary.ae..'/'..summary.aeBudget..'  未加点数 '..summary.aeLeft..'&#124;r\n&#124;cffffd060TE 已加点 '..summary.te..'/'..summary.teBudget..'  未加点数 '..summary.teLeft..'&#124;r')</code> | 条件分支：只有`if S.Class()==T.class and summary.ae  put(T.summary,summary.reason..'\n／cff65d5efAE 已加点 '..summary.ae..'/'..summary.aeBudget..'  未加点数 '..summary.aeLeft..'／r\n／cffffd060TE 已加点 '..summary.te..'/'..summary.teBudget..'  未加点数 '..summary.teLeft..'／r')`成立才走随后分支；不满足进入else/跳过。 |
| 239 | <code> else put(T.summary,S.Class()==T.class and('角色 '..UnitLevel('player')..'级 · 当前天赋以已保存数据为准')or'浏览其他职业 · 不显示为本人已加点')end</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
| 240 | <code> if (S.NativeData(T.class)~=nil)and S.Class()==T.class then</code> | 条件分支：只有`if (S.NativeData(T.class)~=nil)and S.Class()==T.class`成立才走随后分支；不满足进入else/跳过。 |
| 241 | <code>  local own=S.Capture(T.class);if own then local total=0;for _,v in pairs(own.ranks)do total=total+v end;local free=GetUnspentTalentPoints(false,false,GetActiveTalentGroup(false,false));T.summary:SetText((L.English()and(T.class=='WARRIOR'and 'Warrior Lv. 'or T.class=='PALADIN'and 'Paladin Lv. 'or T.class=='MONK'and 'Monk Lv. 'or T.class=='DRUID'and 'Druid Lv. 'or T.class=='WARLOCK'and 'Warlock Lv. 'or T.class=='MAGE'and 'Mage Lv. 'or T.class=='SHAMAN'and 'Shaman Lv. 'or T.class=='DEATHKNIGHT'and 'Death Knight Lv. 'or T.class=='PRIEST'and 'Priest Lv. 'or T.class=='ROGUE'and 'Rogue Lv. 'or'Hunter Lv. ')or(names[T.class]..' 等级 '))..UnitLevel('player')..' · '..(L.English()and 'Spent 'or'已加点 ')..total..' / '..(L.English()and 'Unspent 'or'剩余 ')..tostring(free or '—'))end</code> | 读取当前天赋组真实余点，不根据图标颜色推算玩家余额。 使用当前原生天赋组；请求中途换组应取消而非加到另一组。 |
| 242 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 243 | <code> enable(T.actual,S.Class()==T.class and not InCombatLockdown());put(T.status,why or T.message or(favorite and'保存收藏不会改变角色；应用需比较并确认。'or((S.NativeData(T.class)~=nil)and'原生参考方案；应用通过原生接口逐点确认，不自动洗点。'or'按推荐天赋加点：保留已学，只载入草稿；请在实际天赋面板核对保存。')));T.painting=false</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`enable(T.actual,S.Class()==T.class and not InCombatLockdown());put(T.status,why or T.message or(favorite and'保存收藏不会改变角色；应用需比较并确认。'or((S.NativeData(T.class)~=nil)and'原生参考方案；应用通过原生接口逐点确认，不自动洗点。'or'按推荐天赋加点：保留已学，只载入草稿；请在实际天赋面板核对保存。')));T.painting=false`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 244 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 245 | <code>local oldGOpen=G.Open;local oldSOpen=S.Open</code> | 定义局部变量：local oldGOpen=G.Open;local oldSOpen=S.Open；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 253 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 254 | <code> if not T.favorite or tab=='favorites'then T.favorite=nil end</code> | 条件分支：只有`if not T.favorite or tab=='favorites' T.favorite=nil end`成立才走随后分支；不满足进入else/跳过。 |
| 255 | <code> for _,token in ipairs({'WARRIOR','PALADIN'})do local engine=S.NativeEngine(token);if engine.previewCurrent==nil then engine.previewCurrent=true end end;W.previewCurrent=W.previewCurrent~=false;W.previewLevel=W.previewLevel or UnitLevel('player');C.Fit(T.frame);T.frame:Show();T.Refresh();Windows.Focus(T.frame);return true</code> | 循环：for _,token in ipairs({'WARRIOR','PALADIN'})do local engine=S.NativeEngine(token);if engine.previewCurrent==nil then engine.previewCurrent=true end end;W.previewCurrent=W.previewCurrent~=false;W.previewLevel=W.previewLevel or UnitLevel('player');C.Fit(T.frame);T.frame:Show();T.Refresh();Windows.Focus(T.frame);return true；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 256 | <code>end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 257 | <code>function G.Open(fromBot)if fromBot then if T.frame then T.frame:Hide()end;return oldGOpen(fromBot)end;return T.Open('recommend')end</code> | 定义/进入函数：上排自绘种族头像真正的点击入口；标准CharacterRace_OnClick不覆盖它。同一行若有return，函数立即交回该结果。 |
