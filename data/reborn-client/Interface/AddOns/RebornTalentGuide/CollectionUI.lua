local S=RebornTalentCollections;local G=RebornTalentGuide;local C=RebornTalentTreeCanvas;local W=RebornTalentPanelWindows;local PD=RebornTalentGuidePaladinData
local classes={WARRIOR='战士',PALADIN='圣骑士',HUNTER='猎人',ROGUE='潜行者',PRIEST='牧师',DEATHKNIGHT='死骑',SHAMAN='萨满',MAGE='法师',WARLOCK='术士',DRUID='德鲁伊',WITCHDOCTOR='巫医'};local specs={[0]='巫毒',[1]='酿造',[2]='暗影狩猎'}
-- Self-contained controls: no three-slice template regions for skins to resize.
local function button(parent,x,y,w,label,fn)
 return RebornTalentGuideTheme.Button(parent,x,y,w,25,label,fn)
end
-- Keep full size icons and place captions below them. Scroll rather than shrink
-- dense trees until badges obscure the artwork. Each board retains its own offset.
local function collectionLayout(board,items)
 local minX,maxX,minY,maxY=1e9,-1e9,1e9,-1e9
 for _,n in ipairs(items)do minX=math.min(minX,n.x);maxX=math.max(maxX,n.x);minY=math.min(minY,n.y);maxY=math.max(maxY,n.y)end
 local ordered={};for _,n in ipairs(items)do ordered[#ordered+1]=n end
 table.sort(ordered,function(a,b)if math.abs(a.y-b.y)<.01 then return a.x<b.x end;return a.y<b.y end)
 local placed={};local bottom=0
 local span=math.max(0,board.width-54);if board.compactAE then span=math.min(span,430)end
 local left=(board.width-span)/2
 for _,n in ipairs(ordered)do
  n.x=left+(n.x-minX)*span/math.max(1,maxX-minX)
  n.y=27+(n.y-minY)*1.8;n.size=32
  for _,prior in ipairs(placed)do if math.abs(n.x-prior.x)<45 then n.y=math.max(n.y,prior.y+58)end end
  placed[#placed+1]=n;bottom=math.max(bottom,n.y+40)
 end
 board.contentHeight=math.max(435,bottom);board.canvas:SetHeight(board.contentHeight)
 board.scrollMax=math.max(0,board.contentHeight-414);board.scrollOffset=math.min(board.scrollOffset or 0,board.scrollMax)
 board.scroll:SetVerticalScroll(board.scrollOffset)
 board.scrollLabel:SetText(board.scrollMax>0 and'滚轮上下浏览'or'')
end
local function enable(b,yes)if yes then b:Enable()else b:Disable()end end
function S.SetStatus(msg)S.status=msg;if S.frame then S.UpdateStatus()end end
function S.Dirty()
 S.StopOwned('编辑收藏，停止后续加点；已加点保留')
 if S.editor and not S.editor.readOnlyReason then S.editor.dirty=true end
end
function S.Change(fn)
 if S.editor and S.editor.dirty then
  StaticPopupDialogs.REBORN_COLLECTION_DISCARD={text='放弃这次尚未保存为收藏版本的编辑？角色当前天赋不会改变。',button1='放弃编辑',button2=CANCEL,timeout=0,whileDead=true,hideOnEscape=true,OnAccept=function()S.StopOwned();fn()end};StaticPopup_Show('REBORN_COLLECTION_DISCARD')
 else
  S.StopOwned()
  fn()
 end
end
function S.Load(id,version)
 local db=S.DB();local item=db and db.builds[id];if type(item)~='table'or type(item.versions)~='table'then return end;local rev=item.versions[version or #item.versions];if not rev then return end
 if type(rev)~='table'or type(rev.build)~='table'or rev.build.class~=item.class or type(rev.build.ranks)~='table'or type(rev.build.level)~='number'or type(rev.name)~='string'then S.SetStatus('此收藏记录损坏，原数据保留，请从当前方案重新建立');return end
 local shape,why=S.Shape(rev.build);local profile,profileError=S.Profile(rev.profile)
 S.class=item.class;S.editor={id=id,version=rev.version,head=#item.versions,name=rev.name,build=S.Copy(rev.build),profile=profile or S.Profile(),readOnlyReason=not shape and why or profileError,dirty=false};S.choices={};S.status=S.editor.readOnlyReason and('只读：'..S.editor.readOnlyReason..'；原记录保留，不能应用')or'已载入收藏版本，仅供编辑/比较，尚未应用';if S.detailScroll then S.detailScroll:SetVerticalScroll(0)end;S.Refresh()
end
function S.New(source)
 local b,name
 if source=='current'then b,name=S.Capture(S.class);name=b and'当前已保存天赋'or name
 elseif source=='recommendation'then b,name=S.Recommendation(S.class)
 else b=S.Blank(S.class,math.max(10,math.min(80,UnitLevel('player'))),2);name='新建方案'end
 if not b then S.SetStatus(name);return end
 S.editor={build=b,name=name,profile=source=='recommendation'and S.RecommendationProfile(S.class)or S.Profile(),dirty=true};S.choices={};S.status='本地编辑；尚未保存收藏或应用';S.Refresh()
end
function S.Save(copy)
 local e=S.editor;if not e then return end;if e.readOnlyReason then S.SetStatus('此版本只读，请从当前有效方案重新建立收藏');return end
 local id,v=S.Commit(copy and(e.name..' 副本')or e.name,e.build,not copy and e.id or nil,e.head,e.version,e.profile)
 if not id then S.SetStatus(v);return end
 S.Load(id,v);S.SetStatus('已保存收藏版本 '..v..'；角色天赋尚未改变')
end
local function editItem(item)
 local old=item.onClick;local id=item.id
 item.onClick=function(mouse)
  if IsShiftKeyDown and IsShiftKeyDown()and old then old();return end
  local e=S.editor;if not e then return end
  local rank=e.build.ranks[id]or 0;local nextRank=math.max(0,math.min(item.maximum,rank+(mouse=='RightButton'and-1 or 1)))
  if rank==nextRank then return end
  S.Dirty();e.build.ranks[id]=nextRank>0 and nextRank or nil;S.Refresh()
 end
 local tooltip=item.tooltip
 item.tooltip=function(t,n)
  if S.editor and S.editor.build.class=='WITCHDOCTOR'then
   local d=RebornTalentGuideWDData.nodes[id];t:SetText(d.name..' / '..d.en);t:AddLine('前置：'..d.path,.7,.85,1,true);t:AddLine(d.effects[math.max(1,item.target)]or d.effects[1],1,1,1,true);t:AddLine(d.limit,1,.7,.4,true)
   if item.alternatives then for _,choice in ipairs(item.alternatives)do local v=RebornTalentGuideWDData.nodes[choice];t:AddLine('同位选择：'..v.name..' '..(S.editor.build.ranks[choice]or 0)..'/'..v.max,.3,1,1,true)end end
  elseif tooltip then tooltip(t,n)else t:AddLine(item.name,1,.9,.25,true)end
  t:AddLine('角色已保存：'..(item.actual==nil and'未同步'or item.actual)..'/'..item.maximum,.3,1,1,true)
  t:AddLine('收藏编辑 '..item.target..'/'..item.maximum..'；左键+1，右键−1，仅改本地收藏草稿。',1,1,1,true)
  if item.alternatives then t:AddLine('Shift+点击切换互斥组的显示选项；预算与前置在右侧校验。',.3,1,1,true)end
 end
end
local function paint()
 local e=S.editor;if not e then return end;local b=e.build
 for _,board in ipairs(S.boards)do board:Hide()end
 local data=S.NativeData(b.class)
 if data then
  local current=S.Capture(b.class)
  for t,tree in ipairs(data.trees)do
   local board=S.boards[t];board.compactAE=false;board:Show();board:ClearAllPoints();board:SetPoint('TOPLEFT',S.frame,'TOPLEFT',240+(t-1)*254,-133);board:SetSize(248,480);board.canvas:SetSize(228,435);board.width=228;board.height=435;board.title:SetText(((b.class=='HUNTER'or b.class=='ROGUE'or b.class=='PRIEST'or b.class=='DEATHKNIGHT'or b.class=='SHAMAN'or b.class=='MAGE'or b.class=='WARLOCK'or b.class=='DRUID')and S.NativeData(b.class).treeNames or b.class=='WARRIOR'and{'武器','狂怒','防护'}or{'神圣','防护','惩戒'})[t]);if b.class=='HUNTER'or b.class=='ROGUE'or b.class=='PRIEST'or b.class=='DEATHKNIGHT'or b.class=='SHAMAN'or b.class=='MAGE'or b.class=='WARLOCK'or b.class=='DRUID'then if board.art then board.art:Hide()end;board:SetBackdropColor(.035,.09,.065,.8)elseif b.class=='WARRIOR'then C.WarriorArt(board,t)else C.Art(board,t)end
   local items,edges,ids={},{},{};for _,n in ipairs(tree)do ids[n.id]=true end
   for _,n in ipairs(tree)do
    local name,_,icon=GetSpellInfo(n.spells[1]);local item={id=n.id,x=28+(n.col-1)*53,y=20+(n.row-1)*35,size=30,icon=icon or n.icon,spell=n.spells[math.max(1,b.ranks[n.id]or 0)],name=name or n.name,target=b.ranks[n.id]or 0,actual=current and(current.ranks[n.id]or 0)or nil,maximum=n.max,shape=n.max>1 and'circle'or'square'}
    item.tooltip=function(tip)tip:AddLine('第'..n.row..'层，需要本系'..((n.row-1)*5)..'点；前置 '..(n.dep==0 and'无'or(n.dep..' 等级 '..n.depRank)),1,1,1,true)end
    editItem(item);items[#items+1]=item;if n.dep~=0 and ids[n.dep]then edges[#edges+1]={n.dep,n.id}end
   end
   collectionLayout(board,items);C.Paint(board,items,edges,{edit=true})
  end
 else
  local mask=S.Mask(b);if not mask then return end
  for t,tab in ipairs({'Class',({[0]='Voodoo',[1]='Brewing',[2]='Shadowhunting'})[b.spec]})do
   local mode=S.wdView or'Class'
   if mode=='both'or(mode=='Class'and t==1)or(mode=='Spec'and t==2)then
    local width=mode=='both'and 377 or(t==1 and 620 or 760);local board=S.boards[t];board.compactAE=t==1;board:Show();board:ClearAllPoints();board:SetPoint('TOPLEFT',S.frame,'TOPLEFT',240+(mode=='both'and(t-1)*383 or(760-width)/2),-133);board:SetSize(width,480);board.canvas:SetSize(width-20,435);board.width=width-20;board.height=435;if board.art then board.art:Hide()end;board:SetBackdropColor(.025,.04,.055,.95);board.title:SetText(tab=='Class'and'通用 AE'or(specs[b.spec]..' TE'))
    if not board.art then board.art=board:CreateTexture(nil,'BACKGROUND');board.art:SetPoint('TOPLEFT',4,-4);board.art:SetPoint('BOTTOMRIGHT',-4,4)end
    if C.Atlas(board.art,'talents-background-witchdoctor-'..({[0]='voodoo',[1]='brewing',[2]='shadowhunting'})[b.spec])then board:SetBackdropColor(.025,.04,.055,0);board.art:SetAlpha(.22);board.art:Show()end
    G.TreeViews.PaintWD(board,tab,{mask=mask,plan={spec=b.spec}},S.choices,S.Refresh,true)
    for _,item in ipairs(board.items)do editItem(item)end
    collectionLayout(board,board.items);C.Paint(board,board.items,board.edges,{edit=true})
   end
  end
 end
end
function S.UpdateStatus()
 if not S.frame then return end
 local job=S.ActiveNativeJob()
 local progress=job and job.owner==S.frame and('服务器逐点确认：'..job.done..'/'..#job.rows..'；可停止，已加点保留')or S.status
 S.frame.note:SetText(progress or'本机账号收藏，不是服务器角色存档；金：收藏配点，白：未选；角色已保存点见悬停与右侧差异。')
end
function S.RefreshList()
 if not S.frame then return {},0 end
 local filter=S.FilterState();local list,total=S.Find(S.class,filter.query,filter.scene,filter.role);S.rows=S.rows or{}
 for i,item in ipairs(list)do
  local b=S.rows[i]
  if not b then b=button(S.listContent,0,-(i-1)*47,200,'',function(self)S.Change(function()S.Load(self.buildId)end)end);b:SetHeight(42);S.rows[i]=b end
  local latest=type(item.versions[#item.versions])=='table'and item.versions[#item.versions]or{};local meta=S.Profile(latest.profile)or S.Profile()
  b.buildId=item.id;b:SetText((S.editor and S.editor.id==item.id and'● 'or'')..S.ShortName(item.name)..'\nv'..#item.versions..' · '..meta.scene..' / '..meta.role);b:Select(S.editor and S.editor.id==item.id);b:Show()
 end
 for i=#list+1,#S.rows do S.rows[i]:Hide()end
 S.listContent:SetHeight(math.max(330,#list*47));if S.listScroll.UpdateScrollChildRect then S.listScroll:UpdateScrollChildRect()end
 S.classText:SetText(classes[S.class]..' · '..#list..' / '..total..' 套')
 S.filterScene:SetText('用途：'..filter.scene);S.filterRole:SetText('职责：'..filter.role)
 S.noResults:SetText(total==0 and'本职业还没有收藏'or'没有匹配的收藏\n试试清空搜索或选“全部”')
 if #list==0 then S.noResults:Show()else S.noResults:Hide()end
 S.visibleBuilds=list;return list,total
end
function S.Refresh()
 if not S.frame then return end
 C.Legend(S.frame,'collection',617)
 for token,b in pairs(S.classTabs or{})do b:Select(token==S.class)end
 for i,b in ipairs(S.wdTabs)do b:Select(({'Class','Spec','both'})[i]==(S.wdView or'Class'))end
 S.profileToggle:Select(S.detailsMode);S.versionToggle:Select(S.showVersionChanges);S.diffToggle:Select(S.showDifferences)
 S.painting=true;local db,dbError=S.DB();local list=S.RefreshList();S.searchBox:SetText(S.FilterState().query)
 local e=S.editor
 if e then
  S.nameBox:EnableMouse(not e.readOnlyReason);S.levelBox:EnableMouse(not e.readOnlyReason);if e.readOnlyReason then S.nameBox:ClearFocus();S.levelBox:ClearFocus()end
  S.nameBox:SetText(e.name);S.levelBox:SetText(e.build.level);S.spec:SetText(e.build.class=='WITCHDOCTOR'and('专精：'..(specs[e.build.spec]or'?'))or'经典原生天赋');enable(S.spec,e.build.class=='WITCHDOCTOR'and not e.readOnlyReason)
  S.versionText:SetText((e.id and('版本 '..e.version..' / '..e.head)or'新收藏')..(e.readOnlyReason and' · 只读失效'or e.dirty and' · 未保存编辑'or' · 已存本地'))
  local ok,reason=S.Validate(e.build);if e.readOnlyReason then reason='只读版本：'..e.readOnlyReason end;local diff,why=S.Compare(e.build)
  local text={e.readOnlyReason and'|cffffbb66只读版本 · 原记录保留|r'or ok and'|cff77ff99✓ 配点规则有效|r'or'|cffff7777! 配点需要调整|r',''}
  if reason then text[#text+1]=reason;text[#text+1]=''end
  local meta=e.profile or S.Profile();text[#text+1]='用途：'..meta.scene..' · 职责：'..meta.role
  local filled=0;for _,key in ipairs({'skills','rotation','notes'})do if #meta[key]>0 then filled=filled+1 end end;text[#text+1]='方案资料：已填 '..filled..'/3 项（上方查看）'
  if S.showVersionChanges then text[#text+1]='';text[#text+1]='|cffffd46a版本变化|r';for _,line in ipairs(S.VersionSummary(e.id,e.version))do text[#text+1]=line end end
  text[#text+1]=''
  local added,removed,up,down=0,0,0,0
  for _,row in ipairs(diff or{})do
   if row.delta>0 then added=added+row.delta;up=up+1 elseif row.delta<0 then removed=removed-row.delta;down=down+1 end
  end
  text[#text+1]='|cffffd46a与角色当前配点比较|r'
  if why then text[#text+1]=why
  elseif #diff==0 then text[#text+1]='配点完全一致'
  else
   if up>0 then text[#text+1]='|cff77ff99增加 '..added..' 点 · '..up..' 项技能|r'end
   if down>0 then text[#text+1]='|cffffbb66减少 '..removed..' 点 · '..down..' 项技能|r'end
   if removed>0 then text[#text+1]='';text[#text+1]='需先在原天赋面板重置。';text[#text+1]='收藏不会自动洗点或扣费。'end
  end
  S.diffToggle:SetText(S.showDifferences and'收起技能差异'or('查看技能差异（'..#(diff or{})..'项）'))
  if S.showDifferences and not why then
   text[#text+1]='';text[#text+1]='|cffffd46a技能：当前 → 收藏|r'
   for _,row in ipairs(diff)do
    text[#text+1]='';text[#text+1]=row.name
    text[#text+1]=(row.delta<0 and'|cffffbb66'or'|cff77ff99')..row.current..' → '..row.target..'|r'
   end
  end
  local can,blocked=S.CanApply(e.build,S.frame);if e.readOnlyReason then can=nil;blocked='此版本仅供查看，不能直接应用'end;text[#text+1]='';text[#text+1]=removed>0 and'完成原面板重置后，请重新核对。'or(blocked or'可确认应用到自己的当前方案')
  text[#text+1]='';text[#text+1]='左键加点 / 右键减点';if e.build.class=='WITCHDOCTOR'then text[#text+1]='Shift+点击：切换同位技能'end;text[#text+1]='仅编辑收藏，保存后才可申请应用。'
  if db then for i=#db.receipts,1,-1 do local r=db.receipts[i];if type(r)=='table'and r.id==e.id and r.version==e.version and r.guid==UnitGUID('player')then text[#text+1]='';text[#text+1]='最近应用：'..(r.message or r.state);break end end end
  S.detail:SetText(table.concat(text,'\n'));S.detailContent:SetHeight(math.max(400,S.detail:GetStringHeight()+24));if S.detailScroll.UpdateScrollChildRect then S.detailScroll:UpdateScrollChildRect()end
  if S.detailsMode or e.readOnlyReason then for _,board in ipairs(S.boards)do board:Hide()end else paint()end
  enable(S.apply,can~=nil and e.id~=nil and not e.dirty and not e.readOnlyReason);enable(S.delete,e.id~=nil and not S.waiting and not S.ActiveNativeJob());enable(S.history,e.id~=nil);enable(S.save,db~=nil and not e.readOnlyReason);enable(S.copy,db~=nil and not e.readOnlyReason)
 else
  S.diffToggle:SetText('查看技能差异');S.nameBox:SetText('');S.versionText:SetText('从推荐/当前方案建立收藏，或新建空白');S.detail:SetText(dbError or'本职业还没有收藏。');for _,b in ipairs(S.boards)do b:Hide()end;S.apply:Disable();S.delete:Disable();S.save:Disable();S.copy:Disable();S.history:Disable()
 end
 S.SyncProfileEditor();local activeJob=S.ActiveNativeJob();enable(S.stop,activeJob and activeJob.owner==S.frame)
 for _,b in ipairs(S.wdTabs)do if S.class=='WITCHDOCTOR'then b:Show()else b:Hide()end end
 S.painting=false;S.UpdateStatus()
end
local function input(parent,x,y,w,changed)
 local f=CreateFrame('EditBox',nil,parent)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10,insets={left=3,right=3,top=3,bottom=3}})
 f:SetBackdropColor(.025,.035,.045,.98);f:SetBackdropBorderColor(.65,.53,.3,1);f:SetTextInsets(8,8,3,3);
 f:SetPoint('TOPLEFT',x,y);f:SetSize(w,24);f:SetAutoFocus(false);f:SetFontObject('GameFontHighlightSmall');f:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);f:SetScript('OnEnterPressed',function(self)self:ClearFocus();S.Refresh()end);f:SetScript('OnEditFocusLost',function()S.Refresh()end);f:SetScript('OnTextChanged',function(self)if not S.painting and S.editor and not S.editor.readOnlyReason then changed(self:GetText());S.Dirty()end end);return f
end
local function create()
 if S.frame then return end
 local f=C.Window('RebornTalentCollectionFrame','天赋收藏 · TG30A');S.frame=f;W.Register('collection',f)
 S.classTabs={};for i,token in ipairs({'WARRIOR','PALADIN','WITCHDOCTOR','HUNTER','ROGUE','PRIEST','DEATHKNIGHT','SHAMAN','MAGE','WARLOCK','DRUID'})do local class=token;S.classTabs[token]=button(f,20+((i-1)%4)*52,-35-math.floor((i-1)/4)*23,50,classes[class],function()S.Change(function()S.class=class;S.editor=nil;S.Refresh()end)end);S.classTabs[token]:SetHeight(20)end
 S.shareButton=button(f,1030,-3,230,'导入 / 导出',function()S.OpenShare()end);S.shareButton:SetHeight(20)
 S.classText=C.Text(f,20,-106,210,'','GameFontNormal')
 button(f,20,-131,200,'从自己当前已保存配点建立',function()S.Change(function()S.New('current')end)end)
 button(f,20,-163,200,'收藏当前所选推荐',function()S.Change(function()S.New('recommendation')end)end)
 button(f,20,-195,200,'新建空白方案',function()S.Change(function()S.New('blank')end)end)
 S.listScroll=CreateFrame('ScrollFrame','RebornTalentCollectionList',f,'UIPanelScrollFrameTemplate');S.listScroll:SetPoint('TOPLEFT',20,-318);S.listScroll:SetSize(200,291)
 S.listContent=CreateFrame('Frame',nil,S.listScroll);S.listContent:SetSize(200,395);S.listScroll:SetScrollChild(S.listContent)
 S.searchBox=input(f,20,-248,200,function()end);S.searchBox:SetMaxLetters(128)
 S.searchBox:SetScript('OnTextChanged',function(self)if not S.painting then S.FilterState().query=self:GetText();S.RefreshList()end end)
 S.searchBox:SetScript('OnEditFocusLost',function()end);S.searchBox:SetScript('OnEnterPressed',function(self)self:ClearFocus()end)
 S.searchBox:SetScript('OnEscapePressed',function(self)self:SetText('');S.FilterState().query='';self:ClearFocus();S.RefreshList()end)
 S.searchHint=C.Text(f,24,-230,196,'搜索名称 / 最新方案资料')
 S.filterScene=button(f,20,-281,96,'用途：全部',function()S.CycleFilter('scene')end)
 S.filterRole=button(f,124,-281,96,'职责：全部',function()S.CycleFilter('role')end)
 S.noResults=C.Text(S.listContent,4,-12,190,'')
 C.Text(f,242,-42,45,'名称：');S.nameBox=input(f,290,-37,360,function(text)S.editor.name=text end);S.nameBox:SetMaxLetters(96)
 C.Text(f,668,-42,40,'等级');S.levelBox=input(f,712,-37,42,function(text)S.editor.build.level=tonumber(text)or 0 end);S.levelBox:SetMaxLetters(2)
 S.spec=button(f,775,-37,222,'专精',function()local e=S.editor;if not e or e.readOnlyReason or e.build.class~='WITCHDOCTOR'then return end;S.Dirty();e.build.spec=(e.build.spec+1)%3;S.choices={};S.Refresh()end)
 S.versionText=C.Text(f,245,-83,410,'','GameFontNormal')
 S.history=button(f,670,-76,150,'查看前一个历史版本',function()local e=S.editor;if not e or not e.id then return end;local id=e.id;local version=e.version>1 and e.version-1 or e.head;S.Change(function()S.Load(id,version)end)end)
 S.returnButton=button(f,832,-76,165,'返回推荐',function()G.Navigation.Return(classes[S.class])end)
 button(f,1020,-76,240,'重新核对最近应用记录',S.RecheckLast)
 S.profileToggle=button(f,832,-104,165,'方案资料',function()S.detailsMode=not S.detailsMode;S.Refresh()end)
 S.versionToggle=button(f,1020,-104,240,'查看版本变化',function()S.showVersionChanges=not S.showVersionChanges;S.detailScroll:SetVerticalScroll(0);S.Refresh()end)
 local panel=CreateFrame('Frame',nil,f);S.profilePanel=panel;panel:SetPoint('TOPLEFT',240,-133);panel:SetSize(760,480)
 panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});panel:SetBackdropColor(.02,.035,.045,.96)
 C.Text(panel,16,-14,700,'方案资料 · 与收藏版本一起保存，不会改变角色配点','GameFontNormal')
 S.sceneEdit=button(panel,16,-43,300,'用途',function()S.CycleProfile('scene')end)
 S.roleEdit=button(panel,338,-43,300,'职责',function()S.CycleProfile('role')end)
 S.profileFields={};S.profileScrolls={}
 for _,field in ipairs({{key='skills',label='关键技能',y=80,h=55},{key='rotation',label='联动顺序',y=170,h=85},{key='notes',label='备注',y=290,h=100}})do
  local key=field.key;C.Text(panel,16,-field.y,700,field.label)
  local scroll=CreateFrame('ScrollFrame','RebornCollectionProfile_'..key,panel,'UIPanelScrollFrameTemplate');scroll:SetPoint('TOPLEFT',16,-field.y-22);scroll:SetSize(700,field.h)
  local box=input(scroll,0,0,680,function(text)S.SetProfile(key,text)end);box:SetMultiLine(true);box:SetHeight(field.h);box:SetMaxLetters(key=='skills'and 512 or key=='rotation'and 1024 or 2048);box:SetScript('OnEnterPressed',nil);scroll:SetScrollChild(box)
  box:HookScript('OnTextChanged',function(self)local text=self:GetText()or'';local _,lines=text:gsub('\n','');self:SetHeight(math.max(field.h,(lines+math.ceil(#text/70)+1)*16));if scroll.UpdateScrollChildRect then scroll:UpdateScrollChildRect()end end)
  box:SetScript('OnCursorChanged',function(_,x,y,w,h)
   if S.painting then return end
   local offset=scroll.GetVerticalScroll and scroll:GetVerticalScroll()or 0;local top=math.max(0,-(y or 0))
   if top<offset then offset=top elseif top+(h or 16)>offset+field.h then offset=top+(h or 16)-field.h end
   scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,box:GetHeight()-field.h),offset)))
  end)
  scroll:EnableMouseWheel(true);scroll:SetScript('OnMouseWheel',function(_,delta)
   if IsControlKeyDown()then return end
   local offset=scroll.GetVerticalScroll and scroll:GetVerticalScroll()or 0
   scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,box:GetHeight()-field.h),offset-delta*24)))
  end)
  S.profileFields[key]=box;S.profileScrolls[key]=scroll
 end
 C.Text(panel,16,-425,700,'纯文字；支持换行。填写后点击底部“保存为收藏新版本”。')
 panel:Hide()
 S.wdTabs={}
 for i,mode in ipairs({'Class','Spec','both'})do local value=mode;S.wdTabs[i]=button(f,245+(i-1)*175,-104,165,({'通用 AE 树','专精 TE 树','双树对照'})[i],function()S.wdView=value;S.Refresh()end)end
 S.boards={};for i=1,3 do
  local board=C.Board(f,240,-133,248,480,'');S.boards[i]=board
  local scroll=CreateFrame('ScrollFrame',nil,board);scroll:SetPoint('TOPLEFT',10,-35);scroll:SetPoint('BOTTOMRIGHT',-10,31)
  board.canvas:SetParent(scroll);board.canvas:ClearAllPoints();board.canvas:SetPoint('TOPLEFT');scroll:SetScrollChild(board.canvas);board.scroll=scroll
  board.scrollLabel=C.Text(board,12,-458,320,'')
  scroll:EnableMouseWheel(true);scroll:SetScript('OnMouseWheel',function(_,delta)
   if IsControlKeyDown()then return end
   board.scrollOffset=math.max(0,math.min(board.scrollMax or 0,(board.scrollOffset or 0)-delta*60));scroll:SetVerticalScroll(board.scrollOffset)
  end)
 end
 local sc=CreateFrame('ScrollFrame','RebornTalentCollectionDetails',f,'UIPanelScrollFrameTemplate');sc:SetPoint('TOPLEFT',1020,-133);sc:SetSize(245,440)
 sc:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10,insets={left=3,right=3,top=3,bottom=3}});sc:SetBackdropColor(.02,.035,.045,.96);sc:SetBackdropBorderColor(.4,.34,.22,1)
 S.detailContent=CreateFrame('Frame',nil,sc);S.detailContent:SetSize(230,440);sc:SetScrollChild(S.detailContent);S.detail=C.Text(S.detailContent,10,-10,213,'');S.detail:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',13,'OUTLINE');S.detail:SetSpacing(3);S.detailScroll=sc
 S.diffToggle=button(f,1020,-587,245,'查看技能差异',function()S.showDifferences=not S.showDifferences;S.detailScroll:SetVerticalScroll(0);S.Refresh()end)
 S.save=button(f,25,-630,190,'保存为收藏新版本',function()S.Save(false)end)
 S.copy=button(f,230,-630,130,'复制为新收藏',function()S.Save(true)end)
 S.delete=button(f,375,-630,130,'删除本地收藏',function()
  local e=S.editor;if not e or not e.id then return end;local id,head=e.id,e.head
  StaticPopupDialogs.REBORN_COLLECTION_DELETE={text='删除「'..e.name..'」及其全部本地历史版本？角色天赋不变。',button1='删除收藏',button2=CANCEL,timeout=0,whileDead=true,hideOnEscape=true,OnAccept=function()if not S.editor or S.editor.id~=id or S.editor.head~=head then S.SetStatus('收藏选择已改变，请重新确认删除');return end;local ok,why=S.Delete(id,head);if ok then S.editor=nil;S.status='本地收藏已删除，角色天赋未改变';S.Refresh()else S.SetStatus(why)end end};StaticPopup_Show('REBORN_COLLECTION_DELETE')
 end)
 S.apply=button(f,530,-630,230,'比较并应用到当前方案',S.RequestApply)
 S.stop=button(f,775,-630,150,'停止后续逐点加点',function()S.StopOwned() end)
 button(f,940,-630,320,'打开原职业天赋面板核对',function()if S.class=='WITCHDOCTOR'then W.OpenDoctor()else if InCombatLockdown()then return end;if ToggleTalentFrame then ToggleTalentFrame()end end end)
 f:HookScript('OnHide',function()if StaticPopup_Hide then StaticPopup_Hide('REBORN_COLLECTION_APPLY');StaticPopup_Hide('REBORN_COLLECTION_DELETE');StaticPopup_Hide('REBORN_COLLECTION_DISCARD')end;S.StopOwned('关闭收藏窗口，后续加点停止；已加点保留') end)
 UISpecialFrames[#UISpecialFrames+1]='RebornTalentCollectionFrame'
end
function S.SyncProfileEditor()
 local e=S.editor;local meta=e and(e.profile or S.Profile())or S.Profile()
 S.profileToggle:SetText(e and e.readOnlyReason and'只读方案资料'or S.detailsMode and'返回天赋树'or'方案资料');enable(S.profileToggle,e and not e.readOnlyReason);S.versionToggle:SetText(S.showVersionChanges and'收起版本变化'or'查看版本变化')
 if e and(S.detailsMode or e.readOnlyReason)then S.profilePanel:Show()else S.profilePanel:Hide()end
 S.sceneEdit:SetText('用途：'..meta.scene);S.roleEdit:SetText('职责：'..meta.role)
 local editable=e and not e.readOnlyReason;enable(S.sceneEdit,editable);enable(S.roleEdit,editable)
 for key,box in pairs(S.profileFields)do if box:GetText()~=meta[key]then box:SetText(meta[key])end;box:EnableMouse(editable and true or false);if not editable then box:ClearFocus()end end
end
function S.Open(class,after)
 create();local wanted=class or(S.class or S.Class());if not classes[wanted]then wanted='PALADIN'end
 local function open()
  if S.class~=wanted then S.editor=nil end;S.class=wanted
  if after then after()end
  C.Fit(S.frame);S.frame:Show();S.Refresh();W.Focus(S.frame)
 end
 -- Preserve the intended class and operation across the single discard prompt.
 if S.editor and(S.class~=wanted or after)then S.Change(open)else open()end
end
SLASH_REBORNTALENTCOLLECTION1='/rtcollection';SLASH_REBORNTALENTCOLLECTION2='/rtfavorites'
SlashCmdList.REBORNTALENTCOLLECTION=function()S.Open()end
local old=G.Refresh
function G.Refresh()
 old();if not G.frame then return end
 if not S.entry then S.entry=button(G.frame,134,-420,150,'我的天赋收藏',function()S.Open(G.catalogClass=='巫医'and'WITCHDOCTOR'or G.catalogClass=='战士'and'WARRIOR'or'PALADIN')end)end
 if G.catalogClass=='巫医'or G.catalogClass=='圣骑士'or G.catalogClass=='战士'then S.entry:Show()else S.entry:Hide()end
 for _,b in ipairs(G.categoryButtons or{})do
  if b.category=='我的收藏'and not b.rebornCollectionEntry then
   b.rebornCollectionEntry=true;local previous=b:GetScript('OnClick');b:SetScript('OnClick',function(self,...)if G.catalogClass=='圣骑士'or G.catalogClass=='巫医'or G.catalogClass=='战士'then S.Open(G.catalogClass=='巫医'and'WITCHDOCTOR'or G.catalogClass=='战士'and'WARRIOR'or'PALADIN')else previous(self,...)end end)
  end
 end
end




