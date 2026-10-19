-- TG2A: render inside the existing guide. Warrior/Bot handlers remain unchanged.
local G,W,D=RebornTalentGuide,RebornTalentGuide.WD,RebornTalentGuideWDData
local specNames={[0]='巫毒',[1]='酿造',[2]='暗影狩猎'}
local function text(p,x,y,width,value,font)
 local f=p:CreateFontString(nil,'OVERLAY',font or'GameFontHighlightSmall');f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);f:SetJustifyH('LEFT');f:SetText(value or'');return f
end
local function btn(p,x,y,width,value,fn)
 return RebornTalentGuideTheme.Button(p,x,y,width,26,value,fn)
end
local function enable(b,on)if on then b:Enable()else b:Disable()end end
local function describe(result)
 local p=result.plan
 local lines={p.purpose,'','关键技能（当前等级）'}
 for _,id in ipairs(p.core)do local node=D.nodes[id];local rank=RebornWD8.AERank(id,result.mask);lines[#lines+1]=node.name..' '..rank..'/'..node.max..(rank==0 and'（尚未解锁，先按下方前置加点）'or'')end
 lines[#lines+1]='';lines[#lines+1]='联动顺序（相应技能解锁后）'
 for i,s in ipairs(p.rotation)do lines[#lines+1]=i..'. '..s end
 lines[#lines+1]='';lines[#lines+1]='前置与互斥';lines[#lines+1]=p.conflicts
 lines[#lines+1]='';lines[#lines+1]='属性方向';lines[#lines+1]=p.stats
 lines[#lines+1]='';lines[#lines+1]='点数预算';lines[#lines+1]=string.format('AE %d/%d，保留%d；TE %d/%d，保留%d。',result.ae,result.aeBudget,result.aeBudget-result.ae,result.te,result.teBudget,result.teBudget-result.te)
 lines[#lines+1]='保留点可按队伍需要选择通用工具，不为花满点数强塞技能。各等级重新计算前置，低等级不会直接载入80级模板。'
 if #result.blocked>0 then
  lines[#lines+1]='';lines[#lines+1]='后续目标及当前未满足条件'
  for _,x in ipairs(result.blocked)do lines[#lines+1]=D.nodes[x.id].name..'：'..x.reason end
 end
 lines[#lines+1]='';lines[#lines+1]='本服适配参考，依据WD161已发布技能与真实加点校验；不是官方最优配方或强度排名。载入只更改本地草稿，请在原巫医面板核对并保存。普通技能及后续等级仍需按本服导师流程学习。'
 return table.concat(lines,'\n')
end
local function glyphText()
 if G.Evidence then return G.Evidence.GlyphText('WITCHDOCTOR')end
 local a=D.glyphs;local lines={'巫医雕文核对',a.summary,'','已核对：本服雕文目录'..a.catalogCount..'项、GlyphProperties '..a.propertiesCount..'项＋数据库补充'..a.propertyDBCount..'项、自定义登记'..a.customCount..'项。','当前可信推荐：0项；不借其他职业雕文填满槽位。',''}
 for _,s in ipairs(a.rejected)do lines[#lines+1]='• '..s end
 lines[#lines+1]='';lines[#lines+1]='已安装雕文（名称仅作对照，不表示对本方案有效）'
 if not W.IsDoctor()or G.fromBot then lines[#lines+1]='当前不是本人巫医对象，不读取雕文槽。'
 elseif GetGlyphSocketInfo then
  for i=1,6 do
   local enabled,kind,id=GetGlyphSocketInfo(i,GetActiveTalentGroup and GetActiveTalentGroup(false,false)or nil)
   local name=id and GetSpellInfo(id)
   lines[#lines+1]='槽'..i..'：'..(name or(id and('技能 '..id)or'空/未解锁'))..(id and'（未列入可信推荐）'or'')
  end
 else lines[#lines+1]='客户端雕文接口未就绪。'end
 lines[#lines+1]='';lines[#lines+1]='没有经过本服效果验证的巫医专用雕文时，先不安装。后续新增需同时验证物品→镶嵌技能→GlyphProperties→实际效果和触发入口。'
 return table.concat(lines,'\n')
end
local function create()
 if W.panel then return end
 local f=CreateFrame('Frame',nil,G.frame);W.panel=f;f:SetPoint('TOPLEFT',G.frame,'TOPLEFT',296,-96);f:SetSize(600,546)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});f:SetBackdropColor(.02,.045,.065,.94);f:SetBackdropBorderColor(.55,.44,.22,1)
 W.summary=text(f,12,-12,570,'','GameFontNormal');W.summary:SetTextColor(1,.82,.3)
 W.levelText=text(f,12,-39,160,'')
 local function level(value)W.previewLevel=value;G.message=nil;G.Refresh()end
 btn(f,176,-32,78,'当前等级',function()level(UnitLevel('player'))end)
 for i,v in ipairs({20,40,60,80})do local n=v;btn(f,260+(i-1)*78,-32,72,n..'级',function()level(n)end)end
 local scroll=CreateFrame('ScrollFrame','RebornTGWDListScroll',f,'UIPanelScrollFrameTemplate');W.scroll=scroll;scroll:SetPoint('TOPLEFT',10,-70);scroll:SetSize(558,452)
 local content=CreateFrame('Frame',nil,scroll);W.content=content;content:SetSize(552,452);scroll:SetScrollChild(content);W.rows={}
 W.hint=text(G.frame,134,-96,150,'四类用途\n按等级计算\n仅生成本地草稿');W.hint:SetTextColor(.8,.8,.75)
 W.plans={};for i,p in ipairs(D.plans)do local n=i;local b=btn(G.frame,134,-206-(i-1)*46,150,p.title,function()W.selected=n;G.message=nil;if G.scroll then G.scroll:SetVerticalScroll(0)end;W.scroll:SetVerticalScroll(0);G.Refresh()end);b:SetHeight(40);W.plans[i]=b end
 local oldStop=G.stop:GetScript('OnClick')
 G.stop:SetScript('OnClick',function(self,...)if G.catalogClass~='巫医'then return oldStop(self,...)end;if not W.IsDoctor()or G.fromBot or InCombatLockdown()then return end;if RebornTalentPanelWindows then RebornTalentPanelWindows.OpenDoctor()elseif RebornWDTreePreviewAPI and RebornWDTreePreviewAPI.Open then RebornWDTreePreviewAPI.Open()end end)
 local old=G.apply:GetScript('OnClick')
 function W.RequestDraft(openAfter)
  local epoch=G.Lifecycle and G.Lifecycle.epoch or 0;local index=W.selected;local level=W.previewLevel or UnitLevel('player');local checked,why=W.CheckDraft(index,level)
  if not checked then G.Message(why);return end
  StaticPopupDialogs.REBORN_TG_WD_DRAFT={text='「'..D.plans[index].title..'」\n'..W.DraftText(checked),button1='载入草稿',button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()
   if(G.Lifecycle and not G.Lifecycle.Current(epoch))or G.catalogClass~='巫医'or W.selected~=index or W.previewLevel~=level then G.Message('所选推荐或等级已改变，请重新确认');return end
   local ok,message=W.LoadDraft(index,level,checked);G.Message(message);G.Refresh()
   if ok and openAfter and RebornWDTreePreviewAPI and RebornWDTreePreviewAPI.Open then
    if RebornTalentPanelWindows then RebornTalentPanelWindows.OpenDoctor()else RebornWDTreePreviewAPI.Open()end
   end
  end}
  StaticPopup_Show('REBORN_TG_WD_DRAFT')
 end
 G.apply:SetScript('OnClick',function(self,...)if G.catalogClass~='巫医'then return old(self,...)end;W.RequestDraft(false)end)
end
function W.Hide()
 if W.panel then W.panel:Hide();W.hint:Hide();for _,b in ipairs(W.plans)do b:Hide()end end
 if G.stop then G.stop:SetText('停止后续加点')end
 if G.categoryButtons then for _,b in ipairs(G.categoryButtons)do b:Show()end end
 if G.planPrev then G.planPrev:Show();G.planNext:Show()end
end
function W.Refresh()
 create();W.panel:Show();W.hint:Show()
 for _,b in ipairs(G.categoryButtons)do b:Hide()end
 if G.planPrev then G.planPrev:Hide();G.planNext:Hide()end
 G.planPageLabel:SetText('4 类方案');G.empty:Hide();G.glyphPanel:Hide()
 for _,f in ipairs(G.treePanels)do f:Hide()end
 for _,b in ipairs(G.plans)do b:Hide()end
 for i,b in ipairs(W.plans)do b:Show();b:SetText((i==W.selected and'> 'or'')..D.plans[i].title)end
 W.previewLevel=W.previewLevel or UnitLevel('player')
 local result,why=W.Build(W.selected,W.previewLevel)
 G.heading:SetText('巫医 · '..D.plans[W.selected].title)
 G.context:SetText('巫医天赋参考 · TG4C · '..(G.fromBot and'本人方案浏览；不会向机器人发送加点'or'推荐草稿与服务器已保存点数分开显示'))
 G.url:SetText('');G.stop:SetText('打开巫医天赋面板');enable(G.stop,W.IsDoctor()and not G.fromBot and not InCombatLockdown());G.apply:SetText('载入巫医草稿（不保存）')
 if not result then
  W.summary:SetText(why);W.levelText:SetText('等待巫医配套数据');for _,b in ipairs(W.rows)do b:Hide()end
  G.description:SetText(G.showGlyphs and glyphText()or why);G.content:SetHeight(math.max(394,G.description:GetStringHeight()+16));G.scroll:Show();G.apply:Disable();G.status:SetText(why);return
 end
 W.summary:SetText(string.format('%s · %d级 · AE %d/%d，TE %d/%d',specNames[result.plan.spec],result.level,result.ae,result.aeBudget,result.te,result.teBudget))
 W.levelText:SetText('预览等级：'..result.level..(result.level==UnitLevel('player')and'（当前）'or''))
 local used,list={},{};for _,x in ipairs(result.order)do if not used[x.id]then used[x.id]=true;list[#list+1]=x.id end end
 local ordered={};for _,id in ipairs(list)do if D.nodes[id].tab~='Class'then ordered[#ordered+1]=id end end;for _,id in ipairs(list)do if D.nodes[id].tab=='Class'then ordered[#ordered+1]=id end end;list=ordered
 local M=RebornWD8;local canRead=W.IsDoctor()and not G.fromBot and M.loaded and M.layoutReady and M.specs[M.active+1]==result.plan.spec
 for i,id in ipairs(list)do
  local b=W.rows[i]
  if not b then
   b=CreateFrame('Button',nil,W.content);b:SetSize(546,46);b:SetPoint('TOPLEFT',2,-(i-1)*49)
   b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',0,-4);b.icon:SetSize(32,32);b.icon:SetTexCoord(.07,.93,.07,.93)
   b.name=text(b,42,-3,350,'','GameFontNormalSmall');b.rank=text(b,398,-3,144,'');b.note=text(b,42,-23,498,'');b.note:SetTextColor(.65,.7,.75)
   b:SetScript('OnEnter',function(self)
    local node=D.nodes[self.id];GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(node.name..' / '..node.en)
    GameTooltip:AddLine('推荐 '..self.target..'/'..node.max..'；AE/TE前置已按本服校验',1,.85,.3,true)
    GameTooltip:AddLine('前置：'..node.path,.7,.85,1,true)
    GameTooltip:AddLine(node.effects[self.target]or node.effects[1],1,1,1,true);GameTooltip:AddLine(node.limit,.9,.6,.4,true);GameTooltip:Show()
   end);b:SetScript('OnLeave',function()GameTooltip:Hide()end);W.rows[i]=b
  end
  local n=D.nodes[id];b.id=id;b.target=M.AERank(id,result.mask);b.icon:SetTexture(n.icon);b.name:SetText(i..'. '..n.name)
  b.rank:SetText('荐 '..b.target..'/'..n.max..'  已存 '..(canRead and tostring(M.AERank(id,M.aeMasks[M.active+1]))or'—'))
  b.note:SetText((n.pool=='FREE'and'免费能力'or(n.tab=='Class'and'通用 AE'or(specNames[result.plan.spec]..' TE')))..' · 节点 '..id..' · 悬停查看作用范围');b:Show()
 end
 for i=#list+1,#W.rows do W.rows[i]:Hide()end
 W.content:SetHeight(math.max(452,#list*49));if W.scroll.UpdateScrollChildRect then W.scroll:UpdateScrollChildRect()end
 G.description:SetText(G.showGlyphs and glyphText()or describe(result));G.content:SetHeight(math.max(394,G.description:GetStringHeight()+16));G.scroll:Show()
 if G.scroll.UpdateScrollChildRect then G.scroll:UpdateScrollChildRect()end
 G.tabDesc:SetNavSelected(not G.showGlyphs);G.tabGlyph:SetNavSelected(G.showGlyphs and true or false)
 local draft,reason=W.CheckDraft(W.selected,W.previewLevel);enable(G.apply,draft~=nil)
 G.status:SetText(G.message or reason or'只载入本地草稿；请在原巫医面板核对后保存。')
end
local refresh=G.Refresh
function G.Refresh()
 W.Hide();refresh();if G.frame and G.catalogClass=='巫医'then W.Refresh()end
end
local open=G.Open
function G.Open(fromBot)
 open(fromBot)
 if not fromBot and W.IsDoctor()then G.catalogClass='巫医';G.classPage=2;W.previewCurrent=true;W.previewLevel=UnitLevel('player');G.Refresh()end
end
-- Saved snapshots arrive via Witch Doctor system packets, not native talent events.
local event=CreateFrame('Frame');local elapsed=0;local signature
 event:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
 if not G.frame or not G.frame:IsShown()or G.catalogClass~='巫医'then return end
 local M=RebornWD8;local value=M and table.concat({tostring(M.revision),tostring(M.loaded),tostring(M.pending),tostring(M.layoutReady),tostring(M.aeDirty),tostring(M.active),tostring(M.slot)},':')or'missing'
 if value~=signature then signature=value;W.Refresh()end
 end)
