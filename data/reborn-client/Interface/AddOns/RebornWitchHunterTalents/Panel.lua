-- WHTAL7A: original CoA art, original packed node layout and original scoped view logic.
local M,D,O,Art=RebornWHTalents,RebornWHTalentData,RebornWHOriginalUI,RebornWHOriginalArt
local frame,canvas,home,treeView,header,status,language,search,save,cancel,reset,refresh,back,homeRefresh
local plans,wardrobe,recommend,collection,chooseSpec
local selected=10
local layoutBusy=false
local learnedIDs={[11218]={9005082},[7588]={9005080},[29150]={9005078},[34592]={9005079},[6413]={9005077},[34538]={9005067,9005076},[7451]={9005068},[6415]={9005069,9005070},[6457]={9005071},[7424]={9005073}}
local function Learned(id)
 local rank=M.Rank(id,false);local ids=learnedIDs[id];return rank>0 and ids and ids[rank]and type(IsSpellKnown)=="function"and IsSpellKnown(ids[rank]) or false
end
local cards,treeButtons={},{}
local function DB()RebornWHTalentUI=RebornWHTalentUI or {};return RebornWHTalentUI end
local function Zh()local v=DB().lang;if not v and DungeonClearDB then v=DungeonClearDB.lang end;return v~="en"end
local function T(z,e)if Zh()then return z else return e end end
local function Name(n)return Zh()and n.nameZh or n.name end
local function Atlas(texture,key)
 local v=assert(Art[key],key);texture:SetTexture(v[1]);texture:SetTexCoord(v[4],v[5],v[6],v[7]);texture:SetVertexColor(1,1,1,1)
end
local function Text(parent,size)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");f:SetFont(STANDARD_TEXT_FONT,size or 12,"OUTLINE");return f
end
local function Texture(parent,key,w,h)
 local t=parent:CreateTexture(nil,"ARTWORK");if key then Atlas(t,key)end
 if w then t:SetWidth(w);t:SetHeight(h)end;return t
end
local function Guard(stage,fn)
 local ok,e=pcall(fn);if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333WHTAL7A "..stage..": "..tostring(e).."|r")end;return ok
end
local function Button(parent,label,w,fn)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetWidth(w);b:SetHeight(25);b:SetText(label)
 b:SetScript("OnClick",function()Guard("click",fn)end);return b
end
local function Enable(b,yes)if yes then b:Enable()else b:Disable()end end
local function SavePoint(f,key)local p,_,rp,x,y=f:GetPoint(1);if p and rp then DB()[key]={p,rp,x,y}end end
local function RestorePoint(f,key,x,y)
 local v=DB()[key];f:ClearAllPoints()
 if type(v)=="table"and type(v[1])=="string"and type(v[2])=="string"and type(v[3])=="number"and type(v[4])=="number"then
  if pcall(f.SetPoint,f,v[1],UIParent,v[2],v[3],v[4])then return end
 end
 f:SetPoint("CENTER",UIParent,"CENTER",x,y)
end
local messages={offline={"尚未同步；点击刷新","Not synchronized; click Refresh"},pending={"等待服务端确认…","Waiting for server…"},ok={"已同步","Synchronized"},saved={"加点已保存；正在核对技能学习","Saved; verifying learned spells"},reset={"已完整洗点，扣除10金币","Reset complete; charged 10 gold"},draft={"草稿尚未生效，请保存或撤销","Draft has no effect; Save or Cancel"},cancelled={"已撤销草稿","Draft cancelled"},schema={"服务端组件尚未安装完整，暂不能加点","Server components are incomplete; purchases disabled"},database={"保存未确认；请刷新核对，不要重复提交","Database result not confirmed; refresh before retrying"},uncertain={"事务结果待恢复，请重连核对","Receipt recovery required; reconnect"},timeout={"服务端未响应，请刷新核对","No response; refresh to confirm state"},stale={"状态或报价已变化，请刷新","State or quote changed; refresh"},invalid={"等级或点数不满足，已保存点须完整洗点","Invalid level/budget; saved ranks require a full reset"},money={"金币不足，未洗点","Not enough gold; no reset"},unsafe={"战斗、死亡、施法、载具或飞行时不能修改","Cannot edit in combat, while dead, casting, in a vehicle or flying"},busy={"已有操作处理中","An operation is already pending"},quote={"请确认10金币完整洗点","Confirm a full 10-gold reset"}}
local function Tip(button)
 local n=button.node;if not n then return end
 GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:SetText(Name(n),1,1,1)
 if Zh()and n.nameZh~=n.name then GameTooltip:AddLine(n.name,1,.82,0)end
 if n.id==34538 then GameTooltip:AddLine(T("暴击率提高3%/6%，最高两级。二级替换一级，不叠加。","Increases critical strike chance by 3%/6%. Rank 2 replaces rank 1; they do not stack."),1,.82,0,true)
 elseif n.id==29150 then GameTooltip:AddLine(T("主动冲刺：按移动方向腾跃，无方向键时向前。基础距离15码乘移动速度倍率，消耗15怒气，冷却12秒，公共冷却1.5秒；定身时不能使用。","Active dash: follows movement input; forward while stationary. Base distance15 yards times run-speed rate, 15 Rage, 12-second cooldown and1.5-second GCD. Cannot be used while rooted."),1,.82,0,true)
 elseif n.id==11218 then GameTooltip:AddLine(T("先投入9点其它通用天赋。使涌动药剂、黑暗药剂和巫血药剂的持续时间延长5秒；不改伤害与冷却。","Requires9 prior common points. Surging, Dark and Witchblood Tonics last5 seconds longer; no damage or cooldown change."),1,.82,0,true)
 elseif n.id==7588 then GameTooltip:AddLine(T("先投入9点通用天赋。成功使用腾跃后恢复5%最大法力；仅对本人腾跃生效，失败施放、登录和刷新不会恢复法力。","Requires9 prior common points. A successful Vault restores5% maximum mana. No reward on failed casts, login or refresh."),1,.82,0,true)
 elseif n.id==34592 then GameTooltip:AddLine(T("腾跃距离额外增加3码；只强化本人腾跃，不影响其它技能。","Adds3 yards to your Vault distance; no effect on other abilities."),1,.82,0,true)
 elseif n.id==6413 then GameTooltip:AddLine(T("主动药剂：解除自身诅咒效果，魔法伤害降低60%，持续10秒；冷却120秒，与其它猎巫者药剂互斥。保存学习后从技能书拖到动作条使用。","Active tonic: removes curses from you and reduces Magic damage taken by 60% for 10 seconds. 120-second cooldown; only one Witch Hunter tonic may be active. Save, then drag it from your spellbook to cast."),1,.82,0,true)
 elseif n.id==7451 then GameTooltip:AddLine(T("受到的疾病效果持续时间缩短30%。","Reduces the duration of disease effects on you by 30%."),1,.82,0,true)
 elseif n.id==7424 then
        GameTooltip:AddLine(T("夜间18:00–06:00敏捷提高4%；白天06:00–18:00近战、远程和施法急速提高3%。按服务器当地时间自动切换，1AE，最高一级。","At night (18:00–06:00), Agility increases by 4%. By day (06:00–18:00), melee, ranged and spell haste increase by 3%. Uses realm-local time. 1 AE; one rank."),1,.82,0,true)
    elseif n.id==6457 then
        GameTooltip:AddLine(T("你造成有效伤害的暴击恢复10点怒气和5%最大法力值，每3秒最多触发一次。1AE，最高一级。","Your damaging critical strikes restore 10 Rage and 5% maximum Mana, at most once every 3 seconds. 1 AE; one rank."),1,.82,0,true)
    elseif n.id==6415 and n.cap>0 then GameTooltip:AddLine(T("每级物理伤害提高3%，招架几率额外提高3个百分点；两级共6%。原无招架资格时同时启用原生基础招架。","Each rank increases Physical damage by 3% and parry chance by 3 percentage points; two ranks grant 6%. Native base parry is enabled if previously unavailable."),1,.82,0,true)
 else GameTooltip:AddLine(T("此节点尚未接入本面板加点，不可购买；已通过等级获得的技能不受影响。","This node is not connected to talent allocation yet. Level-granted abilities are unaffected."),1,.65,0,true)end
 if n.cap>0 then
  local saved=M.Rank(n.id,false);local draft=M.Rank(n.id,true)
  if saved>0 then
   if Learned(n.id)then GameTooltip:AddLine((n.id==6413 or n.id==29150)and T("已学习 · 主动技能，请从技能书拖到动作条使用","Learned · Active; drag from the spellbook to cast")or T("已学习 · 被动技能，无需主动施放","Learned · Passive; no manual cast required"),.25,1,.25,true)
   else GameTooltip:AddLine(T("已保存，但尚未确认学习；请安装匹配服务端并重登核对","Saved, but learning is not confirmed. Install matching server files and relog."),1,.55,.1,true)end
  elseif draft>0 then GameTooltip:AddLine(T("未保存草稿；此时尚未学习","Unsaved draft; not learned yet"),1,.82,.2,true)
  else GameTooltip:AddLine(T("尚未学习；加点后需要保存","Not learned; add a point, then Save"),.75,.75,.75,true)end
  if n.tab==87 then GameTooltip:AddLine(T("通用天赋：四个专精共用此左树，不随浏览页改变","Common talent: the left tree is shared by all four specializations."),.7,.9,1,true)end
 end
 GameTooltip:AddLine(T("所需等级 ","Required level ")..n.level.."  AE "..n.ae.." / TE "..n.te,1,1,1)
 if n.needAE>0 or n.needTE>0 then GameTooltip:AddLine(T("原版树投入门槛：","Original tree investment: ")..n.needAE.." AE / "..n.needTE.." TE",1,1,1,true)end
 if n.cap>0 then
  GameTooltip:AddLine(T("已保存 ","Saved ")..M.Rank(n.id,false).." / "..n.max..T("；草稿 ","; Draft ")..M.Rank(n.id,true),1,1,1)
  GameTooltip:AddLine(T("左键增加；右键撤销本节点未保存点数。已保存点需10金币完整洗点。","Left click adds; right click removes an unsaved rank. Saved ranks require a full 10-gold reset."),.7,.9,1,true)
 end
 if button.group and #button.group>1 then
  GameTooltip:AddLine(T("原版选择节点：","Original choice entries: "),1,.82,0)
  for _,other in ipairs(button.group)do GameTooltip:AddLine(Name(other),.8,.8,.8,true)end
 end
 GameTooltip:Show()
end
local function Shape(n)if n.shape=="SpendCircle"then return"circle"elseif n.shape=="SpendHex"then return"choice"else return"square"end end
local function Paint(b)
 local n=b.node;local rank=M.Rank(n.id,true);local state="gray"
 if n.cap>0 then if rank>0 then state="yellow"elseif M.CanAdd(n.id)then state="green"end end
 Atlas(b.border,"talents-node-"..(b.group and #b.group>1 and"choice"or Shape(n)).."-"..state)
 b.icon:SetTexture(n.uiIcon or n.icon);b.icon:SetDesaturated(n.cap==0);b.icon:SetAlpha(n.cap>0 and 1 or .62)
 local saved=M.Rank(n.id,false);local draft=rank~=saved
 b.rank:SetText((n.cap>0 and rank or "—").."/"..n.max..(draft and " *"or""))
 if n.cap==0 then b.rank:SetTextColor(.72,.72,.72)
 elseif draft then b.rank:SetTextColor(1,.65,.15)
 elseif Learned(n.id)then b.rank:SetTextColor(n.tab==87 and 1 or .25,n.tab==87 and .9 or 1,n.tab==87 and .55 or .25)
 else b.rank:SetTextColor(.75,.85,.75)end
 local query=search and search:GetText():lower()or""
 if query~=""then local match=Name(n):lower():find(query,1,true)or n.name:lower():find(query,1,true);b:SetAlpha(match and 1 or .18)else b:SetAlpha(1)end
 if GameTooltip:IsShown()and GameTooltip:GetOwner()==b then Tip(b)end
end
local function BuildTree(parent,tab,x)
 local tree=CreateFrame("Frame",nil,parent);tree:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-110);tree:SetWidth(512);tree:SetHeight(512)
 tree.Label=Text(tree,21);tree.Label:SetPoint("TOP",tree,"TOPLEFT",200,66)
 tree.Points=Text(tree,18);tree.Points:SetPoint("TOP",tree,"TOPLEFT",200,39);tree.Points:SetTextColor(.25,1,.15)
 local lines=tree:CreateTexture(nil,"BACKGROUND");lines:SetPoint("TOPLEFT");lines:SetWidth(512);lines:SetHeight(512);lines:SetTexture("Interface\\RebornWitchHunter\\TalentUI\\Connections"..tab)
 if tab~=87 then local passive=tree:CreateTexture(nil,"BACKGROUND");passive:SetPoint("CENTER",tree,"TOPLEFT",465,-220);passive:SetWidth(74);passive:SetHeight(480);Atlas(passive,"ca-passive-bg")end
 local groups={};local order={}
 for _,n in ipairs(D.nodes)do if n.tab==tab then local key=n.x..":"..n.y
  if not groups[key]then groups[key]={};order[#order+1]=key end;groups[key][#groups[key]+1]=n
 end end
 for _,key in ipairs(order)do
  local group=groups[key];local n=group[1];for _,v in ipairs(group)do if v.cap>n.cap then n=v end end
  local b=CreateFrame("Button",nil,tree);b:SetWidth(44);b:SetHeight(44);b.group=group;b.node=n
  if n.x==10 and tab~=87 then b:SetPoint("CENTER",tree,"TOPLEFT",465,-46-n.y*41)else b:SetPoint("CENTER",tree,"TOPLEFT",24+n.x*44,-24-n.y*44)end
  b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetWidth(38);b.icon:SetHeight(38);b.icon:SetPoint("CENTER")
  b.border=b:CreateTexture(nil,"OVERLAY");b.border:SetWidth(n.shape=="SpendHex"and 50 or 44);b.border:SetHeight(44);b.border:SetPoint("CENTER")
  b.rankPlate=b:CreateTexture(nil,"ARTWORK");b.rankPlate:SetTexture(0,0,0,.78);b.rankPlate:SetWidth(46);b.rankPlate:SetHeight(18);b.rankPlate:SetPoint("BOTTOM",b,"BOTTOM",0,-3)
  b.rank=Text(b,14);b.rank:SetPoint("CENTER",b.rankPlate,"CENTER",0,0)
  if b.rank.SetShadowColor then b.rank:SetShadowColor(0,0,0,1);b.rank:SetShadowOffset(1,-1)end
  b:RegisterForClicks("LeftButtonUp","RightButtonUp");b:SetScript("OnEnter",Tip);b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  b:SetScript("OnClick",function(self,mouse)Guard("node",function()if mouse=="RightButton"then M.Undo(self.node.id)else M.Toggle(self.node.id)end end)end)
  treeButtons[#treeButtons+1]=b;Paint(b)
 end
 return tree
end
local Render,ShowTree,ShowHome,UpdateCardVisual
local function BuildCard(parent)
 local card=CreateFrame("Frame",nil,parent);cards[#cards+1]=card
 card.Picture=Texture(card,nil,280,169);card.Picture:SetPoint("TOP",card,"TOP",0,-20)
 card.PictureBorder=Texture(card,"spec-thumbnailborder-off",292,184);card.PictureBorder:SetPoint("CENTER",card.Picture,"CENTER",0,0)
 card.Name=Text(card,20);card.Name:SetPoint("TOP",card,"TOP",0,-214)
 card.RoleIcon=Texture(card,nil,27,27);card.RoleIcon:SetPoint("TOPLEFT",card,"TOPLEFT",36,-250)
 card.Role=Text(card,13);card.Role:SetPoint("LEFT",card.RoleIcon,"RIGHT",5,0)
 card.Complexity=Text(card,12);card.Complexity:SetPoint("TOP",card,"TOP",0,-313)
 card.Description=Text(card,13);card.Description:SetPoint("TOP",card,"TOP",0,-343);card.Description:SetWidth(238);card.Description:SetHeight(102);card.Description:SetJustifyH("CENTER")
 card.Stats=Text(card,13);card.Stats:SetPoint("TOP",card,"TOP",0,-450)
 card.SampleTitle=Text(card,12);card.SampleTitle:SetPoint("TOP",card,"TOP",0,-518)
 card.Samples={}
 for i=1,3 do local b=CreateFrame("Button",nil,card);b:SetWidth(44);b:SetHeight(44);b:SetPoint("TOP",card,"TOP",(i-2)*58,-545)
  b.icon=Texture(b,nil,35,35);b.icon:SetPoint("CENTER");b.border=Texture(b,"talents-node-circle-yellow",45,45);b.border:SetPoint("CENTER")
  b:SetScript("OnEnter",Tip);b:SetScript("OnLeave",function()GameTooltip:Hide()end);card.Samples[i]=b
 end
 card.ActiveLabel=Text(card,13);card.ActiveLabel:SetPoint("TOP",card,"TOP",0,-598);card.ActiveLabel:SetTextColor(.25,1,.25)
 card.glows={}
 local function Glow(key,x,w,alpha,blend,flip)
  local g=card:CreateTexture(nil,"BORDER");g:SetPoint("TOPLEFT",card,"TOPLEFT",x,0);g:SetWidth(w);g:SetHeight(666);Atlas(g,key)
  if flip then local v=Art[key];g:SetTexCoord(v[5],v[4],v[6],v[7])end
  g:SetAlpha(alpha);g:SetBlendMode(blend);g:Hide();card.glows[#card.glows+1]=g
 end
 Glow("spec-selected-background1",0,322.5,.1,"ADD");Glow("spec-selected-background1",0,322.5,.1,"MOD")
 for side=1,2 do if(side==1 and #cards>1)or(side==2 and #cards<4)then for layer=2,5 do Glow("spec-selected-background"..layer,side==1 and 3.5 or 29.5,289,layer==3 and .1 or 1,"ADD",side==2)end end end
 card.View=Button(card,"",180,function()ShowTree(card.spec.id)end);card.View:SetPoint("BOTTOM",card,"BOTTOM",0,24)
 card.Divider=Texture(card,"spec-columndivider",7,666);card.Divider:SetPoint("RIGHT",card,"RIGHT",0,0)
 function card:SetSpecInfo(s,width,height,first,last)
  self.spec=s;self:SetWidth(width);self:SetHeight(height);Atlas(self.Picture,"spec-thumbnail-witchhunter-"..s.Spec:lower())
  for i,sample in ipairs(s.sampleDetails or{})do
   local n=M.byID[sample.node]or{id=sample.spell,name=sample.name,nameZh=sample.name,cap=0,max=1,level=10,ae=0,te=0,needAE=0,needTE=0}
   self.Samples[i].node=n;self.Samples[i].icon:SetTexture(sample.icon)
  end
 end
 function card:SetDividerShown(yes)if yes then self.Divider:Show()else self.Divider:Hide()end end
 function card:GetSpecID()return self.spec.id end
 function card:UpdateVisualState()if UpdateCardVisual then UpdateCardVisual(self)end end
 return card
end
UpdateCardVisual=function(card)
 local browsing=DB().previewSpec==card.spec.id
 for _,g in ipairs(card.glows)do if browsing then g:Show()else g:Hide()end end
 Atlas(card.PictureBorder,browsing and"spec-thumbnailborder-on"or"spec-thumbnailborder-off")
 card.ActiveLabel:SetText(browsing and T("已选择浏览","Selected for browsing")or"")
end
local function CardText(card)
 local s=card.spec;card.Name:SetText(Zh()and s.zh or s.Name)
 local role=s.Role=="tank"and T("坦克","Tank")or s.Role=="melee"and T("近战伤害输出","Melee Damage Dealer")or T("远程伤害输出","Ranged Damage Dealer")
 Atlas(card.RoleIcon,"ui-lfg-roleicon-"..(s.Role=="tank"and"tank"or s.Role=="melee"and"dps"or"rangeddps"));card.Role:SetText(role);card.Role:SetTextColor(s.Role=="tank"and .3 or .9,s.Role=="tank"and .6 or .12,s.Role=="tank"and 1 or .1)
 local difficulty={Normal="普通",Medium="中等",Intermediate="中等",Advanced="进阶"}
 card.Complexity:SetText(T("复杂度：","Complexity: ")..(Zh()and(difficulty[s.Difficulty]or s.Difficulty)or s.Difficulty));card.Description:SetText(Zh()and s.descriptionZh or s.description);card.Complexity:SetTextColor(.25,1,.25);card.Stats:SetTextColor(1,1,1)
 card.Stats:SetText(s.Role=="tank"and T("敏捷 · 耐力 · 锁甲","Agility · Stamina · Mail Armor")or T("敏捷 · 锁甲","Agility · Mail Armor"))
 card.SampleTitle:SetText(T("示例技能","Sample Spells"));card.View:SetText(T("查看此专精天赋","View this talent tree"));UpdateCardVisual(card)
end
ShowHome=function()GameTooltip:Hide();home:Show();treeView:Hide();back:SetText(T("返回天赋树","Return to tree"));Render()end
ShowTree=function(id)
 GameTooltip:Hide();selected=id;DB().previewSpec=id;home:Hide();treeView:Show();O.SelectSpec(treeView,id,Atlas);back:SetText(T("更换浏览专精","Browse specializations"));Render()
end
Render=function()
 if not frame then return end
 header:SetText(T("飞升 · 猎巫者天赋","Ascension · Witch Hunter Talents"));language:SetText(Zh()and"EN"or"中文")
 if frame.layout then frame.layout:SetText(T("重置布局","Reset layout"))end
 if plans then
  plans.title:SetText(T("可用方案","Available plans"));plans.rename:SetText(T("方案改名","Rename build"))
  for i,row in ipairs(plans.rows)do
   row.title:SetText(T("方案：","Build: ")..i)
   row.state:SetText(i==1 and (M.loaded and T("当前方案 · 专精未选择","Current build · no specialization")or T("等待服务器同步","Waiting for server"))or T("预留 · 尚未开放","Reserved · unavailable"))
   row.state:SetTextColor(i==1 and .2 or 1,i==1 and 1 or .2,.2);row.selected:SetAlpha(i==1 and M.loaded and .4 or 0)
  end
  plans.activate:SetText(T("免费切换方案","Switch build"));plans.discard:SetText(T("撤销草稿","Discard draft"));Enable(plans.discard,M.loaded and not M.pending and M.draft~=M.mask)
  plans.equipmentLabel:SetText(T("关联套装衣柜","Linked wardrobe"));plans.equipment:SetText(T("未关联衣柜","No wardrobe linked"))
  plans.wardrobe:SetText(T("打开套装衣柜","Open wardrobe"));plans.equip:SetText(T("穿戴关联衣柜","Equip linked wardrobe"));plans.query:SetText(T("刷新服务器状态","Refresh server state"))
  treeView.builds:SetText(T("查找推荐方案（待开放）","Find premade builds (unavailable)"));treeView.planToggle:SetText(T("切换已保存方案","Saved plans"));wardrobe:SetText(T("套装衣柜","Wardrobe"));recommend:SetText(T("天赋推荐","Recommendations"));collection:SetText(T("返回天赋收藏面板","Talent collections"));chooseSpec:SetText(T("选择本方案专精","Choose plan spec"))
 end
 if homeRefresh then homeRefresh:SetText(T("刷新","Refresh"))end
 for _,card in ipairs(cards)do CardText(card)end
 local s;for _,v in ipairs(O.specs)do if v.id==selected then s=v end end
 treeView.ClassTree.Label:SetText(T("猎巫者 · 通用","WITCH HUNTER · COMMON"));treeView.SpecTree.Label:SetText(s and(Zh()and s.zh or s.Name:upper())or"")
 treeView.ClassTree.Points:SetText(T("AE 剩余：","AE remaining: ")..math.max(0,M.ae-M.Spent(M.draft)).." / "..M.ae);treeView.ClassTree.Points:SetTextColor(1,.9,.55)
 treeView.SpecTree.Points:SetText(T("TE 剩余：","TE remaining: ")..M.te.." / "..M.te)
 local msg=messages[M.message]or messages.offline;status:SetText(T(msg[1],msg[2])..T(" · 专精尚未开放激活"," · Specialization activation is not enabled yet"))
 if M.loaded and M.mask>0 then local saved,known=0,0;for id in pairs(learnedIDs)do if M.Rank(id,false)>0 then saved=saved+1;if Learned(id)then known=known+1 end end end;status:SetText(status:GetText()..T(" · 已保存/已学："," · Saved/learned: ")..saved.."/"..known)end
 if M.loaded and not M.active and M.mask>0 then status:SetText(status:GetText()..T(" · 等级不足，效果暂停"," · Effects suspended at this level"))end
 save:SetText(T("保存加点","Save Changes"));cancel:SetText(T("撤销草稿","Cancel Draft"));reset:SetText(T("付费重置方案（10金）","Reset plan (10g)"));refresh:SetText(T("刷新","Refresh"))
 back:SetText(T("浏览天赋树","Browse talent trees"))
 Enable(save,M.loaded and not M.pending and M.Dirty()and M.Spent(M.draft)<=M.ae);Enable(cancel,not M.pending and M.Dirty());Enable(reset,M.loaded and not M.pending and M.mask>0);Enable(refresh,not M.pending)
 for _,b in ipairs(treeButtons)do Paint(b)end
end
local function Scale(value)
 local maximum=math.min(1.3,(UIParent:GetWidth()-20)/frame:GetWidth(),(UIParent:GetHeight()-20)/frame:GetHeight());value=math.max(.35,math.min(maximum,value));frame:SetScale(value);DB().scale=value
 frame:SetMaxResize(math.max(1000,(UIParent:GetWidth()-20)/value),math.max(600,(UIParent:GetHeight()-20)/value));SavePoint(frame,"point")
end
local function Layout()
 if layoutBusy then return end;layoutBusy=true
 -- The original card canvas has a fixed aspect. Trim stale saved height instead of leaving a black void.
 local scale=(frame:GetWidth()-4)/1290;local height=34+666*scale
 if math.abs(frame:GetHeight()-height)>1 then frame:SetHeight(height)end
 canvas:SetScale(scale);canvas:ClearAllPoints();canvas:SetPoint("TOP",frame,"TOP",0,-30/scale)
 DB().width=frame:GetWidth();DB().height=frame:GetHeight();status:SetWidth(220)
 layoutBusy=false
end
local function ResetLayout()
 DB().point=nil;DB().width=1294;DB().height=730;frame:SetWidth(1294);frame:SetHeight(730);RestorePoint(frame,"point",0,0);Scale(1);Layout();Render()
end

-- WHFIX1A: WD-style locations, with honest single-plan capability boundaries.
local function Notice(z,e) if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(T(z,e))end end
local function Wardrobe()
 local v=RebornEquipmentVault
 if v and type(v.Toggle)=="function"then v.Toggle()else Notice("套装衣柜插件尚未加载","Equipment Vault is not loaded")end
end
local function Unavailable(b,z,e)
 b:Disable();b:EnableMouse(true)
 b:SetScript("OnEnter",function(self)GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(T(z,e));GameTooltip:Show()end)
 b:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
local function BuildPlans()
 treeView.builds=Button(treeView,"",235,function()end);treeView.builds:SetHeight(22);treeView.builds:SetPoint("BOTTOMLEFT",treeView,"BOTTOMLEFT",15,7)
 Unavailable(treeView.builds,"猎巫者推荐方案尚未配置","Recommended builds are not configured")

 plans=CreateFrame("Frame",nil,treeView);plans:SetWidth(278);plans:SetHeight(592);plans:SetPoint("BOTTOMLEFT",treeView,"BOTTOMLEFT",12,72);plans:SetFrameLevel(treeView:GetFrameLevel()+20);plans:EnableMouse(true)
 plans:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 local function Label(parent,size,x,y,width)
  local f=Text(parent,size);f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(width or 235);f:SetJustifyH("LEFT");return f
 end
 plans.title=Label(plans,12,14,-12)
 plans.rename=Button(plans,"",74,function()end);plans.rename:SetHeight(20);plans.rename:SetPoint("TOPLEFT",plans,"TOPLEFT",163,-10)
 Unavailable(plans.rename,"猎巫者服务器方案改名尚未接入","Server build renaming is not integrated")
 local close=CreateFrame("Button",nil,plans,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",plans,"TOPRIGHT",3,3);close:SetScript("OnClick",function()plans:Hide()end)
 plans.rows={}
 for i=1,10 do
  local row=CreateFrame("Button",nil,plans);row:SetWidth(252);row:SetHeight(37);row:SetPoint("TOPLEFT",plans,"TOPLEFT",12,-34-(i-1)*38)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10});row:SetBackdropColor(.07,.07,.07,.9)
  row.selected=row:CreateTexture(nil,"BACKGROUND");row.selected:SetAllPoints(row);row.selected:SetTexture(1,.75,.05,1);row.selected:SetAlpha(0)
  row.title=Label(row,11,10,-4);row.state=Label(row,11,10,-20);plans.rows[i]=row
  Unavailable(row,i==1 and "当前服务器仅有方案1；专精激活尚未开放"or"猎巫者的服务器多方案尚未开发",i==1 and"Only server plan1 exists; spec activation is unavailable"or"Additional server builds are not implemented")
 end
 plans.activate=Button(plans,"",120,function()end);plans.activate:SetHeight(24);plans.activate:SetPoint("TOPLEFT",plans,"TOPLEFT",14,-423)
 Unavailable(plans.activate,"当前只有一个服务器方案，无需切换","There is only one server build")
 plans.discard=Button(plans,"",120,M.CancelDraft);plans.discard:SetHeight(24);plans.discard:SetPoint("TOPLEFT",plans,"TOPLEFT",143,-423)
 plans.equipmentLabel=Label(plans,11,14,-459)
 plans.equipment=Button(plans,"",223,function()end);plans.equipment:SetHeight(22);plans.equipment:SetPoint("TOPLEFT",plans,"TOPLEFT",22,-478)
 Unavailable(plans.equipment,"猎巫者方案与衣柜的服务器关联尚未接入","Server wardrobe linking is not integrated for Witch Hunter")
 plans.wardrobe=Button(plans,"",120,Wardrobe);plans.wardrobe:SetHeight(24);plans.wardrobe:SetPoint("TOPLEFT",plans,"TOPLEFT",14,-520)
 plans.equip=Button(plans,"",120,function()end);plans.equip:SetHeight(24);plans.equip:SetPoint("TOPLEFT",plans,"TOPLEFT",143,-520)
 Unavailable(plans.equip,"尚无关联衣柜，不能穿戴关联套装","No linked wardrobe is available")
 plans.query=Button(plans,"",249,M.Query);plans.query:SetHeight(24);plans.query:SetPoint("TOPLEFT",plans,"TOPLEFT",14,-557)
 plans:Hide()
end
local function Build()
 frame=CreateFrame("Frame","RebornWHTalentFrame",UIParent);frame:SetWidth(math.max(1000,DB().width or 1294));frame:SetHeight(math.max(600,DB().height or 730));frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true);frame:SetMovable(true);frame:SetResizable(true);frame:SetMinResize(1000,600);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
 -- Match the existing Witch Doctor shell; original CoA cards and tree art stay intact.
 frame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
 local shell=frame:CreateTexture(nil,"BACKGROUND");shell:SetAllPoints(frame);shell:SetTexture(.025,.025,.025,1)
 local titlebar=frame:CreateTexture(nil,"ARTWORK");titlebar:SetPoint("TOPLEFT",frame,"TOPLEFT",5,-4);titlebar:SetPoint("BOTTOMRIGHT",frame,"TOPRIGHT",-5,-27);titlebar:SetTexture(.07,.07,.07,1)
 frame:SetScript("OnDragStart",function(self)self:StartMoving()end);frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing();SavePoint(self,"point")end);frame:SetScript("OnHide",function()GameTooltip:Hide()end)
 tinsert(UISpecialFrames,"RebornWHTalentFrame")
 header=Text(frame,14);header:SetPoint("TOP",frame,"TOP",0,-10)
 -- A texture on the root was hidden by the canvas's child frames. Put the full badge above them.
 local badge=CreateFrame("Frame","RebornWHTalentPortrait",frame);badge:SetWidth(64);badge:SetHeight(64);badge:SetPoint("TOPLEFT",frame,"TOPLEFT",-16,16);badge:SetFrameLevel(frame:GetFrameLevel()+30);badge:EnableMouse(false)
 local portrait=Texture(badge,"class-round-witchhunter",64,64);portrait:SetAllPoints(badge);portrait:SetDrawLayer("OVERLAY")
 frame.portraitFrame=badge
 local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-3,-3)
 language=Button(frame,"EN",42,function()DB().lang=Zh()and"en"or"zh";Render()end);language:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-110,-5)
 Button(frame,"−",24,function()Scale(frame:GetScale()-.05)end):SetPoint("TOPRIGHT",frame,"TOPRIGHT",-77,-5);Button(frame,"+",24,function()Scale(frame:GetScale()+.05)end):SetPoint("TOPRIGHT",frame,"TOPRIGHT",-50,-5)
 canvas=CreateFrame("Frame",nil,frame);canvas:SetWidth(1290);canvas:SetHeight(666)
 home=CreateFrame("Frame",nil,canvas);home:SetWidth(1290);home:SetHeight(666);home:SetPoint("TOPLEFT");home.Background=Texture(home);home.Background:SetAllPoints(home)
 O.BuildHome(home,BuildCard,Atlas)
 treeView=CreateFrame("Frame",nil,canvas);treeView:SetWidth(1290);treeView:SetHeight(666);treeView:SetPoint("TOPLEFT")
 treeView.Background1=treeView:CreateTexture(nil,"BACKGROUND");treeView.Background1:SetAllPoints(treeView)
 treeView.Background3=treeView:CreateTexture(nil,"BACKGROUND");treeView.Background3:SetAllPoints(treeView);treeView.Background3:SetAlpha(0)
 treeView.ClassTree=BuildTree(treeView,87,128);treeView.SpecTree=BuildTree(treeView,39,760)
 local specTrees={[39]=treeView.SpecTree,[40]=BuildTree(treeView,40,760),[41]=BuildTree(treeView,41,760),[94]=BuildTree(treeView,94,760)}
 for _,tree in pairs(specTrees)do tree:Hide()end
 -- The unchanged original SetSpecID calls this private compatibility entry point.
 treeView.SpecTree.SetClassTab=function(_,class,tab)
  for id,tree in pairs(specTrees)do if id==tab then tree:Show();treeView.SpecTree=tree else tree:Hide()end end
 end
 for _,tree in pairs(specTrees)do tree.SetClassTab=treeView.SpecTree.SetClassTab end
 local bottom=Texture(treeView,"talents-background-bottombar",1290,66);bottom:SetPoint("BOTTOMLEFT")
 back=Button(treeView,"",180,function()if home:IsShown()then ShowTree(selected)else ShowHome()end end);back:SetHeight(22);back:SetPoint("BOTTOMRIGHT",treeView,"BOTTOMRIGHT",-12,10)
 search=CreateFrame("EditBox",nil,treeView,"InputBoxTemplate");search:SetAutoFocus(false);search:SetWidth(310);search:SetHeight(22);search:SetMaxLetters(80);search:SetPoint("BOTTOM",treeView,"BOTTOM",0,38)
 search:SetScript("OnTextChanged",function()if status then Render()end end);search:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);search:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
 save=Button(treeView,"",180,M.Save);save:SetHeight(22);save:SetPoint("BOTTOM",treeView,"BOTTOM",0,10)
 cancel=Button(treeView,"",105,M.CancelDraft);cancel:SetPoint("LEFT",save,"RIGHT",8,0);cancel:Hide()
 reset=Button(treeView,"",180,M.Quote);reset:SetHeight(22);reset:SetPoint("BOTTOMRIGHT",treeView,"BOTTOMRIGHT",-12,36)
 refresh=Button(treeView,"",70,M.Query);refresh:SetPoint("RIGHT",reset,"LEFT",-8,0);refresh:Hide()
 BuildPlans()
 local planToggle=Button(treeView,"",235,function()if plans:IsShown()then plans:Hide()else plans:Show()end end);planToggle:SetHeight(23);planToggle:SetPoint("BOTTOMLEFT",treeView,"BOTTOMLEFT",15,36);treeView.planToggle=planToggle
 wardrobe=Button(treeView,"",115,Wardrobe);wardrobe:SetWidth(95);wardrobe:SetHeight(22);wardrobe:SetPoint("BOTTOMLEFT",treeView,"BOTTOMLEFT",275,7)
 collection=Button(frame,"",180,function()end);collection:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-165,-5)
 recommend=Button(frame,"",110,function()end);recommend:SetPoint("RIGHT",collection,"LEFT",-8,0)
 Unavailable(collection,"猎巫者收藏尚未接入；不会打开其它职业的收藏","Witch Hunter collections are not integrated; no other class is opened")
 Unavailable(recommend,"猎巫者天赋推荐尚未配置","Witch Hunter recommendations are not configured")
 chooseSpec=Button(treeView,"",165,function()end);chooseSpec:SetWidth(150);chooseSpec:SetHeight(22);chooseSpec:SetPoint("TOPRIGHT",treeView,"TOPRIGHT",-54,-43)
 Unavailable(chooseSpec,"四专精目前仅可浏览，尚未开放服务器激活","Specializations are browse-only; server activation is not implemented")
 status=Text(treeView,10);status:SetPoint("BOTTOMRIGHT",treeView,"BOTTOMRIGHT",-210,12);status:SetWidth(220);status:SetJustifyH("RIGHT")
 local layout=Button(frame,T("重置布局","Reset layout"),105,ResetLayout);layout:SetPoint("TOPLEFT",frame,"TOPLEFT",74,-5);frame.layout=layout
 -- Dedicated home refresh remains usable before any server storage is installed.
 homeRefresh=Button(home,T("刷新","Refresh"),80,M.Query);homeRefresh:SetPoint("TOPRIGHT",home,"TOPRIGHT",-10,-4)
 local resize=CreateFrame("Button",nil,frame);resize:SetWidth(16);resize:SetHeight(16);resize:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-5,5);resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
 resize:SetScript("OnMouseDown",function()frame:StartSizing("BOTTOMRIGHT")end);resize:SetScript("OnMouseUp",function()frame:StopMovingOrSizing();DB().width=frame:GetWidth();DB().height=frame:GetHeight();Scale(frame:GetScale());Layout()end)
 frame:SetScript("OnSizeChanged",function()if status then Layout()end end)
 selected=DB().previewSpec or 10;local valid=false;for _,s in ipairs(O.specs)do if s.id==selected then valid=true end end;if not valid then selected=10 end
 O.SelectSpec(treeView,selected,Atlas);treeView:Hide();home:Show();RestorePoint(frame,"point",0,0);Layout();Scale(DB().scale or 1);Render();frame:Hide()
end
function M.Open()
 if not M.IsHunter()then return end
 Guard("open",function()if not frame then Build()end;frame:Show();frame:Raise();if frame.portraitFrame then frame.portraitFrame:SetFrameLevel(frame:GetFrameLevel()+30)end;Render();if not M.pending then M.Query()end end)
end
M.changed=function()if frame then Guard("refresh",Render)end end
StaticPopupDialogs["REBORN_WH_TALENT_RESET"]={text="",button1="",button2="",timeout=0,whileDead=false,hideOnEscape=true,preferredIndex=3,OnAccept=function(self,data)M.ConfirmQuote(data or self.data)end,OnHide=function(self)self:SetFrameStrata("DIALOG")end}
M.onQuote=function(q)
 if not frame or not frame:IsShown()then return end
 local d=StaticPopupDialogs["REBORN_WH_TALENT_RESET"];d.text=T("花费10金币，完整清空已保存的通用天赋？","Spend 10 gold to reset the saved common allocation?");d.button1=T("确定（10金币）","Confirm (10g)");d.button2=T("取消","Cancel")
 local p=StaticPopup_Show("REBORN_WH_TALENT_RESET",nil,nil,q);if p then p.data=q;p:SetFrameStrata("TOOLTIP");p:Raise()end
end
SLASH_REBORNWHTALENTS1="/wht";SlashCmdList.REBORNWHTALENTS=M.Open
-- Keep /wht as a diagnostic shortcut; the visible entry is the shared Ascension button.
function M.TogglePanel()
 if not M.IsHunter()then return end
 if frame and frame:IsShown()then frame:Hide()else M.Open()end
end
-- Hot-reload safety only. No standalone launcher is created by this version.
if RebornWHTalentOpenButton then RebornWHTalentOpenButton:Hide();RebornWHTalentOpenButton:SetScript("OnClick",nil)end

local learnedEvents=CreateFrame("Frame");learnedEvents:RegisterEvent("SPELLS_CHANGED");learnedEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
learnedEvents:SetScript("OnEvent",function()if frame and frame:IsShown()then Guard("learned",Render)end end)
