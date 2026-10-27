-- TG21A: one talent center; reuse native draft, collection and validation engines.
local G=RebornTalentGuide;local S=RebornTalentCollections;local W=G.WD
local C=RebornTalentTreeCanvas;local N=G.Navigation;local Windows=RebornTalentPanelWindows
local L=G.CenterLocale
local function put(widget,value)widget:SetText(L.Text(value))end
local function popup(key)L.Popup(key);StaticPopup_Show(key)end
local T={tab='recommend',scene='全部',selected={},choices={}};G.TalentCenter=T
local classes={{'WARRIOR','战士'},{'PALADIN','圣骑士'},{'HUNTER','猎人'},{'ROGUE','潜行者'},{'PRIEST','牧师'},{'DEATHKNIGHT','死亡骑士'},{'SHAMAN','萨满'},{'MAGE','法师'},{'WARLOCK','术士'},{'DRUID','德鲁伊'},{'DEMONHUNTER','恶魔猎手'},{'MONK','武僧'},{'WITCHDOCTOR','巫医'}}
local names={};for _,row in ipairs(classes)do names[row[1]]=row[2]end
local specNames={[0]='巫毒',[1]='酿造',[2]='暗影狩猎'}
local function enable(b,on)if on then b:Enable()else b:Disable()end end
local function move(f,x,y,w,h)f:ClearAllPoints();f:SetPoint('TOPLEFT',T.frame,'TOPLEFT',x,y);if w then f:SetWidth(w)end;if h then f:SetHeight(h)end end
local function text(x,y,w,s,font)return L.Bind(C.Text(T.frame,x,y,w,s,font),s)end
local function button(x,y,w,s,fn,style)
 local b=L.Bind(C.Button(T.frame,x,y,w,s,fn),s)
 if style then
  local paint=function(self)local on=self:IsEnabled();on=on and on~=0;self:SetBackdropColor(on and(style=='red'and .38 or .30)or .06,on and(style=='red'and .065 or .24)or .07,on and .045 or .08,1);self:SetBackdropBorderColor(on and .75 or .22,on and .49 or .24,on and .22 or .26,1)end
  b:SetScript('OnEnter',function(self)paint(self)end);b:SetScript('OnLeave',paint);b:SetScript('OnEnable',paint);b:SetScript('OnDisable',paint);b:SetScript('OnMouseDown',paint);b:SetScript('OnMouseUp',paint);b:SetScript('OnHide',paint);paint(b)
 end
 return b
end
function T.Message(msg)T.message=msg or'';if T.status then put(T.status,T.message)end end
local function stop()
 N.Stop();S.StopOwned('切换天赋中心页面，停止后续加点；已加点保留')
 if StaticPopup_Hide then for _,key in ipairs({'REBORN_TG_CENTER_DRAFT','REBORN_TG_CENTER_NAME','REBORN_TG_CENTER_RENAME','REBORN_TG_CENTER_DELETE','REBORN_TG_CENTER_NATIVE'})do StaticPopup_Hide(key)end end
end
local function plans()
 if T.class=='WITCHDOCTOR'then return RebornTalentGuideWDData.plans elseif T.class=='WARRIOR'then return RebornTalentGuideData.plans elseif T.class=='PALADIN'then return RebornTalentGuidePaladinData.plans elseif T.class=='HUNTER'or T.class=='ROGUE'then return S.NativeData(T.class).plans end
 return {}
end
local function selected()return T.selected[T.class]or 1 end
local function choose(index)
 T.selected[T.class]=index
 if T.class=='WITCHDOCTOR'then W.selected=index elseif T.class=='WARRIOR'then G.selected=index elseif T.class=='PALADIN'then RebornTalentGuidePaladin.selected=index elseif T.class=='HUNTER'or T.class=='ROGUE'then S.NativeEngine(T.class).selected=index end
end
local function dataClass()return S.NativeData(T.class)end
local function current()
 local b,why=S.Capture(T.class);return b,why
end
function T.ApplyRecommendation()
 if T.class=='WITCHDOCTOR'then
  local index,level=selected(),W.previewCurrent and UnitLevel('player')or W.previewLevel
  local result,why=W.CheckDraft(index,level);if not result then T.Message(why);return end
  StaticPopupDialogs.REBORN_TG_CENTER_DRAFT={text='保留全部已学点数，增加 AE '..result.addedAE..' / TE '..result.addedTE..'？\n只载入草稿，请到实际天赋面板核对保存。',button1='载入草稿',button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()
   if T.class~='WITCHDOCTOR'or selected()~=index then T.Message('当前推荐已改变，请重新确认');return end
   local ok,msg=W.LoadDraft(index,level,result);T.Message(msg or(ok and'已载入草稿，请到实际天赋面板核对保存'or'载入失败'));T.Refresh()
  end};popup('REBORN_TG_CENTER_DRAFT')
 else
  local build,title=S.Recommendation(T.class);if not build then T.Message(title);return end
  local token=T.class;local index=selected();local ctx,why=S.CanApply(build,T.frame);if not ctx then T.Message(why);return end
  StaticPopupDialogs.REBORN_TG_CENTER_NATIVE={text='保留已学并加点：'..title..'？\n仍通过原生接口逐点确认，不自动重置或收费。',button1='确认加点',button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()
   if T.class~=token or selected()~=index then T.Message('推荐已改变，请重新确认');return end
   local now,why=S.CanApply(build,T.frame);if not now or now.signature~=ctx.signature then T.Message(why or'当前方案已改变，请重新确认');return end
   local ok,msg=S.NativeEngine(token).StartPlan(now.plan,T.frame,function(_,why)T.Message(why);T.Refresh()end);T.Message(msg or(ok and'正在按原生接口逐点加点'or'无法开始加点'));T.Refresh()
  end};popup('REBORN_TG_CENTER_NATIVE')
 end
end
local function namedSave(build,default,profile)
 if not build then return end
 local snapshot=S.Copy(build);local fingerprint=S.Fingerprint(snapshot);local token=T.class
 local list=S.List(token);if #list>=S.limit then T.Message('免费收藏位已用完；已有收藏仍可查看、重命名或删除。扩展尚未开放。');return end
 StaticPopupDialogs.REBORN_TG_CENTER_NAME={text='保存当前的天赋加点\n请输入收藏名称（最多96字节）。',button1='保存收藏',button2=CANCEL,hasEditBox=true,maxLetters=96,timeout=0,whileDead=true,hideOnEscape=true,
  OnShow=function(self)self.editBox:SetText(default or'我的天赋');self.editBox:HighlightText()end,
  OnAccept=function(self)
   if T.class~=token then T.Message('职业已改变，请重新保存');return end
   if S.Fingerprint(snapshot)~=fingerprint then T.Message('收藏快照已改变，请重新保存');return end
   local id,version=S.Commit(self.editBox:GetText(),snapshot,nil,nil,nil,profile)
   if not id then T.Message(version);return end
   T.tab='favorites';T.favorite=id;S.Load(id,version);T.Message('已保存收藏；角色天赋未改变');T.Refresh()
  end};popup('REBORN_TG_CENTER_NAME')
end
function T.SaveCurrent()
 local b,why=current();if not b then T.Message(why);return end
 namedSave(b,(names[T.class]or'')..' · 当前天赋')
end
function T.SaveRecommended()
 local b,title=S.Recommendation(T.class);if not b then T.Message(title);return end
 namedSave(b,title,S.RecommendationProfile(T.class))
end
function T.Rename()
 local e=S.editor;if not e or not e.id or T.favorite~=e.id then return end
 local id,head,version,build,profile=e.id,e.head,e.version,S.Copy(e.build),S.Copy(e.profile)
 StaticPopupDialogs.REBORN_TG_CENTER_RENAME={text='重命名收藏',button1='保存名称',button2=CANCEL,hasEditBox=true,maxLetters=96,timeout=0,whileDead=true,hideOnEscape=true,OnShow=function(self)self.editBox:SetText(e.name);self.editBox:HighlightText()end,OnAccept=function(self)
  if T.favorite~=id then T.Message('收藏选择已改变，请重新确认');return end
  local saved,rev=S.Commit(self.editBox:GetText(),build,id,head,version,profile);if saved then S.Load(saved,rev);T.Refresh()else T.Message(rev)end
 end};popup('REBORN_TG_CENTER_RENAME')
end
function T.Delete()
 local e=S.editor;if not e or T.favorite~=e.id then return end;local id,head,name=e.id,e.head,e.name
 StaticPopupDialogs.REBORN_TG_CENTER_DELETE={text=L.English()and('Delete favorite "'..name..'"?\nCharacter talents will not change.')or('删除收藏「'..name..'」？\n角色天赋不会改变。'),button1='删除收藏',button2=CANCEL,timeout=0,whileDead=true,hideOnEscape=true,OnAccept=function()
  if T.favorite~=id then T.Message('收藏选择已改变，请重新确认');return end
  local ok,why=S.Delete(id,head);if ok then T.favorite=nil;S.editor=nil;T.Message('收藏已删除，角色天赋未改变');T.Refresh()else T.Message(why)end
 end};popup('REBORN_TG_CENTER_DELETE')
end
local function create()
 if T.frame then return end
 local f=C.Window('RebornTalentCenterFrame','天赋中心');T.frame=f;f:SetSize(1320,830);Windows.Register('talentCenter',f)
 if f.title then L.Bind(f.title,'天赋中心')end
 T.language=button(670,-12,65,'EN',L.Toggle);T.language:SetText(L.English()and'中文'or'EN')
 if f.note then f.note:Hide()end;if f.legend then f.legend:Hide()end
 if f.tgBackgroundChoice then f.tgBackgroundChoice:Hide()end
 T.tabs={button(190,-12,150,'推荐天赋',function()stop();T.tab='recommend';T.message=nil;T.Refresh()end),button(350,-12,150,'我的收藏',function()stop();T.tab='favorites';T.favorite=nil;T.message=nil;T.Refresh()end)}
 T.summary=text(748,-10,510,'','GameFontNormal');T.summary:SetHeight(66)
 text(22,-86,145,'选择职业','GameFontNormal')
 T.classButtons={};for i,row in ipairs(classes)do local token=row[1];local b=button(20,-112-(i-1)*34,145,row[2],function()stop();T.class=token;T.favorite=nil;T.message=nil;T.Refresh()end);T.classButtons[token]=b end
 text(24,-588,135,'已登记职业\n未接入推荐的职业显示说明，不套用其他职业天赋。')
 T.choiceTitle=text(186,-86,210,'天赋加点','GameFontNormal')
 T.sceneButtons={};for i,scene in ipairs({'全部','PVE','PVP','练级'})do local value=scene;T.sceneButtons[i]=button(186+((i-1)%2)*103,-112-math.floor((i-1)/2)*31,98,scene,function()stop();T.scene=value;T.Refresh()end)end
 T.planScroll=CreateFrame('ScrollFrame','RebornTalentCenterPlans',f,'UIPanelScrollFrameTemplate');T.planScroll:SetPoint('TOPLEFT',184,-188);T.planScroll:SetSize(196,420)
 T.planContent=CreateFrame('Frame',nil,T.planScroll);T.planContent:SetSize(194,420);T.planScroll:SetScrollChild(T.planContent);T.planButtons={}
 T.currentButton=button(186,-112,205,'当前天赋加点',function()T.favorite=nil;T.Refresh()end)
 T.saveCurrent=button(186,-149,205,'保存当前的天赋加点',T.SaveCurrent,'red')
 T.slotText=text(190,-194,198,'')
 T.search=CreateFrame('EditBox',nil,f,'InputBoxTemplate');T.search:SetPoint('TOPLEFT',192,-224);T.search:SetSize(190,25);T.search:SetAutoFocus(false);T.search:SetMaxLetters(96);T.search:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);T.search:SetScript('OnTextChanged',function()if not T.painting then T.RefreshList()end end)
 T.searchHint=text(190,-211,195,'搜索收藏名称（包含匹配）')
 T.expand=button(186,-650,205,'＋ 扩展收藏位',function()T.Message('当前每职业提供1个免费收藏位。扩展方式尚未开放，不会扣费。')end)
 T.heading=text(416,-86,870,'','GameFontNormalLarge');T.subtitle=text(416,-112,870,'');T.subtitle:SetHeight(26)
 T.boards={};for i=1,3 do T.boards[i]=C.Board(f,416,-144,432,498,'')end
 T.description=text(420,-650,868,'');T.description:SetHeight(43)
 T.empty=text(480,-300,720,'','GameFontNormalLarge');T.empty:SetHeight(180)
 T.actual=button(416,-740,185,'实际天赋面板',function()N.Actual(names[T.class])end)
 T.collect=button(616,-740,180,'收藏此天赋',T.SaveRecommended,'gold')
 T.apply=button(812,-740,270,'按推荐天赋加点',T.ApplyRecommendation,'red')
 T.rename=button(616,-740,105,'重命名',T.Rename);T.delete=button(730,-740,105,'删除',T.Delete)
 T.applySaved=button(850,-740,230,'比较并应用此天赋',function()S.RequestApply()end,'red')
 T.editSaved=button(1090,-740,190,'编辑收藏',function()local id=T.favorite;if (T.class=='HUNTER'or T.class=='ROGUE')and id then stop();T.frame:Hide();S.Open(T.class,function()S.Load(id)end)end end)
 T.detailsButton=button(1092,-740,205,'查看方案说明',function()
  if T.details:IsShown()then T.details:Hide()else
   local p=plans()[selected()];local lines={p and L.Plan(p,'title')or L.Text('天赋说明'),p and L.Plan(p,p.purpose and'purpose'or'body')or'',p and L.Plan(p,'stats')or'',p and L.Plan(p,'conflicts')or''}
   for _,line in ipairs(p and L.Plan(p,'rotation')or{})do lines[#lines+1]=line end
   put(T.detailsText,table.concat(lines,'\n\n'));T.details:Show()
  end
 end)
 T.details=CreateFrame('Frame',nil,f);T.details:SetPoint('TOPLEFT',414,-142);T.details:SetSize(884,510);T.details:SetFrameLevel(f:GetFrameLevel()+4)
 T.details:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});T.details:SetBackdropColor(.025,.04,.05,1)
 T.detailsText=C.Text(T.details,22,-20,836,'','GameFontHighlight');T.detailsText:SetHeight(470);T.details:Hide()
 T.status=text(420,-779,865,'');T.status:SetHeight(32)
 T.levelButtons={};for i,level in ipairs({0,20,40,60,80})do local value=level;T.levelButtons[i]=button(416+(i-1)*108,-700,102,level==0 and'当前等级'or(level..'级'),function()stop();local adapter=(T.class=='HUNTER'or T.class=='ROGUE')and S.NativeEngine(T.class)or W;adapter.previewCurrent=value==0;adapter.previewLevel=value==0 and UnitLevel('player')or value;T.Refresh()end)end
 f:HookScript('OnHide',stop)
end
function T.RefreshList()
 if not T.frame then return end
 local list={};local all=plans();local query=T.search and T.search:GetText()or''
 if T.tab=='recommend'then
  for i,p in ipairs(all)do local scene=p.category or(i==1 and T.class=='WITCHDOCTOR'and'练级'or'PVE');if T.scene=='全部'or T.scene==scene then list[#list+1]={index=i,name=L.Plan(p,'title')}end end
  local found=false;for _,row in ipairs(list)do if row.index==selected()then found=true end end;if not found and list[1]then choose(list[1].index)end
 else
  local saved=S.List(T.class);local q=string.lower(query or'')
  for _,item in ipairs(saved)do if q==''or string.find(string.lower(item.name),q,1,true)then list[#list+1]={id=item.id,name=item.name}end end
  put(T.slotText,'我的收藏 '..#saved..' / 免费1个');enable(T.saveCurrent,#saved<S.limit and S.Class()==T.class)
 end
 for i,row in ipairs(list)do
  local b=T.planButtons[i]
  if not b then b=C.Button(T.planContent,0,-(i-1)*56,190,'',function(self)
   stop();if self.favorite then T.favorite=self.favorite;S.Load(self.favorite)else choose(self.index)end;T.message=nil;T.Refresh()
  end);b:SetHeight(49);T.planButtons[i]=b end
  b.index,b.favorite=row.index,row.id;b:SetText(row.name);b:Select(T.tab=='recommend'and row.index==selected()or T.tab=='favorites'and row.id==T.favorite);b:Show()
 end
 for i=#list+1,#T.planButtons do T.planButtons[i]:Hide()end
 T.planContent:SetHeight(math.max(360,#list*56));if T.planScroll.UpdateScrollChildRect then T.planScroll:UpdateScrollChildRect()end
 return list
end
local function paintWD(build,result)
 local M=RebornWD8;local mask=result and result.mask or build and S.Mask(build)
 if not mask then return false end
 local spec=result and result.plan.spec or build.spec
 for i,tab in ipairs({'Class',({[0]='Voodoo',[1]='Brewing',[2]='Shadowhunting'})[spec]})do
  local board=T.boards[i];move(board,416+(i-1)*440,-144,432,498);board.width=412;board.height=450;board.canvas:SetSize(412,450);board:Show();put(board.title,i==1 and'巫医 · 通用 AE'or(specNames[spec]..' · 专精 TE'))
  G.TreeViews.PaintWD(board,tab,{mask=mask},T.choices,T.Refresh,true)
  if build then for _,item in ipairs(board.items)do item.onClick=nil;item.tooltip=function(t,n)local d=RebornTalentGuideWDData.nodes[n.id];t:SetText(d.name);t:AddLine((T.favorite and'收藏配点 'or'当前已保存 ')..n.target..'/'..n.maximum,1,.85,.3,true);t:AddLine(d.effects[math.max(1,n.target)]or'',1,1,1,true);t:AddLine(d.limit,1,.7,.4,true)end end end
  if L.English()then for _,item in ipairs(board.items)do
   item.tooltip=function(t,n)
    local d=RebornTalentGuideWDData.nodes[n.id];t:SetText(d.en or d.name)
    t:AddLine((build and(T.favorite and'Favorite rank 'or'Saved rank ')or'Recommended rank ')..n.target..'/'..n.maximum,1,.85,.3,true)
    t:AddLine('Spell descriptions use your game client language.',.7,.7,.7,true)
    t:AddLine(d.effects[math.max(1,n.target)]or'',1,1,1,true)
    t:AddLine(d.limit or'',1,.7,.4,true)
   end
  end end
  C.ScrollTree(board,board.items,true)
  C.Paint(board,board.items,board.edges,{captionBelow=true})
  put(board.title,board.title:GetText())
 end
 return true
end
local function paintNative(build)
 local data=dataClass();if not data then return false end
 local plan=build and S.NativePlan(build)or((T.class=='HUNTER'or T.class=='ROGUE')and S.NativeEngine(T.class).Build(selected(),S.NativeEngine(T.class).previewCurrent~=false and UnitLevel('player')or S.NativeEngine(T.class).previewLevel)or data.plans[selected()]);if not plan then return false end
 local own=S.Capture(T.class);local treeNames=(T.class=='HUNTER'or T.class=='ROGUE')and S.NativeData(T.class).treeNames or T.class=='WARRIOR'and{'武器','狂怒','防护'}or{'神圣','防护','惩戒'}
 for t,tree in ipairs(data.trees)do
  local board=T.boards[t];move(board,416+(t-1)*293,-144,285,498);board.width=265;board.height=450;board.canvas:SetSize(265,450);put(board.title,treeNames[t]);board:Show();local items,edges,ids={},{},{}
  for _,n in ipairs(tree)do ids[n.id]=true end
  for i,n in ipairs(tree)do local rank=plan.ranks[t][i]or 0;local _,_,icon=GetSpellInfo(n.spells[math.max(1,rank)]);items[#items+1]={id=n.id,x=34+(n.col-1)*60,y=24+(n.row-1)*40,size=31,spell=n.spells[math.max(1,rank)],icon=icon or n.icon,name=L.English()and(n.nameEN or GetSpellInfo(n.spells[math.max(1,rank)])or n.name)or n.name,target=rank,actual=own and(own.ranks[n.id]or 0)or nil,maximum=n.max,shape=n.max>1 and'circle'or'square'};if n.dep and n.dep~=0 and ids[n.dep]then edges[#edges+1]={n.dep,n.id}end end
  C.Paint(board,items,edges,{captionBelow=true,current=build~=nil})
 end;return true
end
function T.Refresh()
 if not T.frame or T.painting then return end;T.painting=true
 L.Refresh();T.language:SetText(L.English()and'中文'or'EN')
 G.catalogClass=names[T.class]or T.class;G.fromBot=false
 T.details:Hide()
 local favorite=T.tab=='favorites';T.tabs[1]:Select(not favorite);T.tabs[2]:Select(favorite)
 for token,b in pairs(T.classButtons)do b:Select(token==T.class)end
 put(T.choiceTitle,favorite and'我的天赋'or'天赋加点')
 for i,b in ipairs(T.sceneButtons)do if favorite then b:Hide()else b:Show();b:Select(({'全部','PVE','PVP','练级'})[i]==T.scene)end end
 for _,f in ipairs({T.currentButton,T.saveCurrent,T.slotText,T.search,T.searchHint,T.expand})do if favorite then f:Show()else f:Hide()end end
 T.planScroll:ClearAllPoints();T.planScroll:SetPoint('TOPLEFT',T.frame,'TOPLEFT',184,favorite and-266 or-188);T.planScroll:SetHeight(favorite and 364 or 430)
 T.RefreshList();for _,b in ipairs(T.boards)do b:Hide()end
 for _,f in ipairs({T.collect,T.apply,T.rename,T.delete,T.applySaved,T.editSaved})do f:Hide()end
 for _,b in ipairs(T.levelButtons)do if favorite or(T.class~='WITCHDOCTOR'and T.class~='HUNTER'and T.class~='ROGUE')then b:Hide()else b:Show()end end
 if favorite then T.detailsButton:Hide()else T.detailsButton:Show()end
 local data=plans();local p=data[selected()];local b,why;local result
 if not favorite and p and T.scene~='全部'and(p.category or 'PVE')~=T.scene then p=nil;why='当前筛选暂无推荐方案。';T.detailsButton:Hide()end
 if favorite then
  if T.favorite then local e=S.editor;if e and e.id==T.favorite and e.build.class==T.class then b=e.build end
  else b,why=current()end
  T.heading:SetText(T.favorite and S.editor and S.editor.name or L.Text('当前天赋加点'));put(T.subtitle,T.favorite and'个人收藏 · 只读预览'or'与实际天赋面板已保存配点一致 · 不包含未保存草稿')
  if b then if b.class=='WITCHDOCTOR'then paintWD(b)else paintNative(b)end end
  if T.favorite and b then if T.class=='HUNTER'or T.class=='ROGUE'then T.editSaved:Show()end;T.rename:Show();T.delete:Show();T.applySaved:Show();local can,reason=S.CanApply(b,S.frame);enable(T.applySaved,can~=nil);why=reason end
 else
  put(T.heading,p and L.Plan(p,'title') or((names[T.class]or'')..' · 暂无推荐天赋'));put(T.subtitle,'推荐天赋 · '..T.scene..' · 只载入草稿或通过原生加点确认')
  if p then
   if T.class=='WITCHDOCTOR'then local lev=W.previewCurrent and UnitLevel('player')or W.previewLevel or UnitLevel('player');result,why=W.Build(selected(),lev);if result then paintWD(nil,result);put(T.subtitle,'推荐'..result.level..'级：AE '..result.ae..'/'..result.aeBudget..' · TE '..result.te..'/'..result.teBudget..'；保留已学，只载入草稿。')end
   else paintNative();if T.class=='HUNTER'or T.class=='ROGUE'then local H=S.NativeEngine(T.class);local v=H.Build(selected(),H.previewCurrent~=false and UnitLevel('player')or H.previewLevel);if v then T.subtitle:SetText((L.English()and 'Level 'or'等级 ')..v.level..' · '..table.concat(v.split,'/')..' · '..(L.English()and 'Reference allocation' or '本服参考配点'))end end end
   T.collect:Show();enable(T.collect,#S.List(T.class)<S.limit);T.apply:Show()
   if T.class=='WITCHDOCTOR'then local draft,reason=W.CheckDraft(selected(),W.previewCurrent and UnitLevel('player')or W.previewLevel or UnitLevel('player'));enable(T.apply,draft~=nil);why=reason
   else local b=S.Recommendation(T.class);local ctx,reason;if b then ctx,reason=S.CanApply(b,T.frame)end;enable(T.apply,ctx~=nil);why=reason end
  end
 end
 local has=T.boards[1]:IsShown();if has then T.empty:Hide()else T.empty:Show();put(T.empty,why or'此职业尚无可用的推荐或收藏数据。\n不会用其他职业天赋代替。')end
 put(T.description,favorite and'当前天赋与收藏都只读预览；保存收藏不会改变角色，应用仍需原校验与确认。'or p and(L.Plan(p,p.purpose and'purpose'or'body')..(T.class=='WITCHDOCTOR'and('\n'..L.Plan(p,'reserveNote'))or''))or'')
 local summary=G.PointSummary.Current(false)
 if S.Class()==T.class and summary.ae then put(T.summary,summary.reason..'\n|cff65d5efAE 已加点 '..summary.ae..'/'..summary.aeBudget..'  未加点数 '..summary.aeLeft..'|r\n|cffffd060TE 已加点 '..summary.te..'/'..summary.teBudget..'  未加点数 '..summary.teLeft..'|r')
 else put(T.summary,S.Class()==T.class and('角色 '..UnitLevel('player')..'级 · 当前天赋以已保存数据为准')or'浏览其他职业 · 不显示为本人已加点')end
 if (T.class=='HUNTER'or T.class=='ROGUE')and S.Class()==T.class then
  local own=S.Capture(T.class);if own then local total=0;for _,v in pairs(own.ranks)do total=total+v end;local free=GetUnspentTalentPoints(false,false,GetActiveTalentGroup(false,false));T.summary:SetText((L.English()and(T.class=='ROGUE'and 'Rogue Lv. 'or'Hunter Lv. ')or(names[T.class]..' 等级 '))..UnitLevel('player')..' · '..(L.English()and 'Spent 'or'已加点 ')..total..' / '..(L.English()and 'Unspent 'or'剩余 ')..tostring(free or '—'))end
 end
 enable(T.actual,S.Class()==T.class and not InCombatLockdown());put(T.status,why or T.message or(favorite and'保存收藏不会改变角色；应用需比较并确认。'or((T.class=='HUNTER'or T.class=='ROGUE')and'原生参考方案；应用通过原生接口逐点确认，不自动洗点。'or'按推荐天赋加点：保留已学，只载入草稿；请在实际天赋面板核对保存。')));T.painting=false
end
local oldGOpen=G.Open;local oldSOpen=S.Open
function T.Open(tab,class,index)
 stop();G.Create();create();if not S.frame then oldSOpen('WITCHDOCTOR');S.frame:Hide()end
 if G.frame then G.frame:Hide()end;if G.TreeViews.frame then G.TreeViews.frame:Hide()end
 T.class=class or S.Class();T.tab=tab or'recommend';T.message=nil
 if not names[T.class]then T.class=S.Class()end
 if index then choose(index)elseif T.class=='WITCHDOCTOR'and not T.selected[T.class]then
  local M=RebornWD8;local spec=M and M.draftSpec;for i,p in ipairs(plans())do if p.spec==spec then choose(i);break end end
 end
 if not T.favorite or tab=='favorites'then T.favorite=nil end
 W.previewCurrent=W.previewCurrent~=false;W.previewLevel=W.previewLevel or UnitLevel('player');C.Fit(T.frame);T.frame:Show();T.Refresh();Windows.Focus(T.frame);return true
end
function G.Open(fromBot)if fromBot then if T.frame then T.frame:Hide()end;return oldGOpen(fromBot)end;return T.Open('recommend')end
local oldReturn=N.Return
function N.Return(class,index,view)
 local token;for key,value in pairs(names)do if value==class then token=key end end
 if not token then return oldReturn(class,index,view)end
 return T.Open('recommend',token,index)
end
function S.Open(class,after)
 if after then return oldSOpen(class,after)end
 return T.Open('favorites',class or S.Class())
end
local oldSRefresh=S.Refresh
function S.Refresh(...)local result=oldSRefresh(...);if T.frame and T.frame:IsShown()and not T.painting then T.Refresh()end;return result end
-- Lifecycle.lua owns the existing debounced snapshot/level watcher, including this window.
SLASH_REBORNTALENTCENTER1='/rttalentcenter';SlashCmdList.REBORNTALENTCENTER=function()T.Open('recommend')end
