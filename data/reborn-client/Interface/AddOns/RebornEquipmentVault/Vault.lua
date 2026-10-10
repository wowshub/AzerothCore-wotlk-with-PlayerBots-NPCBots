-- WD18: draw only the circular part of the existing ring, including its alpha.
-- Legacy client compatible; called once when constructing the owning frame.
local function DrawRoundRing(parent,path)
    local size,count=72,144
    local radius=size/2
    for i=1,count do
        local top=(i-1)*size/count
        local bottom=i*size/count
        local edge=math.max(math.abs(top-radius),math.abs(bottom-radius))
        local half=math.sqrt(math.max(0,radius*radius-edge*edge))
        if half>0 then
            local row=parent:CreateTexture(nil,"OVERLAY")
            row:SetPoint("TOPLEFT",parent,"TOPLEFT",radius-half,-top)
            row:SetWidth(half*2);row:SetHeight(bottom-top)
            row:SetTexture(path)
            row:SetTexCoord(.25+.5*(radius-half)/size,.25+.5*(radius+half)/size,
                .25+.5*top/size,.25+.5*bottom/size)
        end
    end
end
-- EV1: item links are previews, never storage ownership or equip instructions.
local V={selected=1,items={},buttons={},tabs={},lang='zh',initialized=false}
RebornEquipmentVault=V
local words={
 title={'装备套装包','Equipment Vault'},preview={'外观与装备预览','Equipment preview'},pack={'套装包','Equipment pack'},locked={'尚未开放','Unavailable'},first={'当前装备预览','Current gear preview'},
 hint={'拖入物品可预览；原物品仍在背包，未存入仓库。','Drop an item to preview. The original stays in your bags.'},
 status={'预览模式 · 不转移装备，不扣费','Preview mode · No items moved, no charges'},capture={'读取身上装备','Read equipped gear'},clear={'清空预览','Clear preview'},equip={'一键穿戴','Equip set'},buy={'解锁套装包','Unlock pack'},link={'关联天赋方案','Link talent build'},
 next={'真实仓库开放后可用','Available when storage is enabled'},price={'价格待服务端开放','Price pending server support'},
 stats={'装备基础属性对比','Base item stat comparison'},columns={'预览 / 当前 / 差值','Preview / Current / Delta'},
 note={'按物品属性接口汇总五维；不是穿戴后的最终属性，天赋及套装联动未计算。\n角色模型展示当前穿戴外观。','Item API stat totals, not final character stats. Talent and set interactions are not calculated.\nModel shows your currently equipped appearance.'},
 missing={'物品数据加载中，请稍后刷新','Item data loading; refresh shortly'},refresh={'衣柜刷新','Refresh wardrobe'},empty={'空装备槽','Empty slot'},wrong={'此物品不属于这个装备部位','This item does not fit this slot'},
 received={'已预览；物品仍在鼠标上，点击背包放回','Preview added; item remains on cursor. Return it to your bag'},remove={'右键清除预览，不移动原物品','Right-click clears preview without moving the item'},
 locktext={'这个套装包尚未开放\n可先在第一个标签体验装备布局','This pack is unavailable\nUse the first tab to preview the layout'},
 strength={'力量','Strength'},agility={'敏捷','Agility'},stamina={'耐力','Stamina'},intellect={'智力','Intellect'},spirit={'精神','Spirit'},
 head={'头部','Head'},neck={'颈部','Neck'},shoulder={'肩部','Shoulders'},shirt={'衬衣','Shirt'},chest={'胸部','Chest'},waist={'腰部','Waist'},legs={'腿部','Legs'},feet={'脚部','Feet'},wrist={'手腕','Wrists'},hands={'手部','Hands'},finger={'戒指','Ring'},trinket={'饰品','Trinket'},back={'背部','Back'},main={'主手','Main hand'},off={'副手','Off hand'},ranged={'远程/圣物','Ranged'},tabard={'战袍','Tabard'},
}
local function L(k) local t=words[k];return t and t[V.lang=='en' and 2 or 1] or k end
local slots={
 {1,'head','HeadSlot',0,0},{2,'neck','NeckSlot',0,1},{3,'shoulder','ShoulderSlot',0,2},{15,'back','BackSlot',0,3},{5,'chest','ChestSlot',0,4},{4,'shirt','ShirtSlot',0,5},{19,'tabard','TabardSlot',0,6},{9,'wrist','WristSlot',0,7},
 {10,'hands','HandsSlot',1,0},{6,'waist','WaistSlot',1,1},{7,'legs','LegsSlot',1,2},{8,'feet','FeetSlot',1,3},{11,'finger','Finger0Slot',1,4},{12,'finger','Finger1Slot',1,5},{13,'trinket','Trinket0Slot',1,6},{14,'trinket','Trinket1Slot',1,7},
 {16,'main','MainHandSlot',2,0},{17,'off','SecondaryHandSlot',2,1},{18,'ranged','RangedSlot',2,2}}
local allowed={INVTYPE_HEAD={1},INVTYPE_NECK={2},INVTYPE_SHOULDER={3},INVTYPE_BODY={4},INVTYPE_CHEST={5},INVTYPE_ROBE={5},INVTYPE_WAIST={6},INVTYPE_LEGS={7},INVTYPE_FEET={8},INVTYPE_WRIST={9},INVTYPE_HAND={10},INVTYPE_FINGER={11,12},INVTYPE_TRINKET={13,14},INVTYPE_CLOAK={15},INVTYPE_WEAPON={16,17},INVTYPE_2HWEAPON={16},INVTYPE_WEAPONMAINHAND={16},INVTYPE_WEAPONOFFHAND={17},INVTYPE_SHIELD={17},INVTYPE_HOLDABLE={17},INVTYPE_RANGED={18},INVTYPE_RANGEDRIGHT={18},INVTYPE_THROWN={18},INVTYPE_RELIC={18},INVTYPE_TABARD={19}}
local statKeys={'ITEM_MOD_STRENGTH_SHORT','ITEM_MOD_AGILITY_SHORT','ITEM_MOD_STAMINA_SHORT','ITEM_MOD_INTELLECT_SHORT','ITEM_MOD_SPIRIT_SHORT'}
local statNames={'strength','agility','stamina','intellect','spirit'}
function V.ReadEquipped()
 local items={};for _,s in ipairs(slots) do items[s[1]]=GetInventoryItemLink('player',s[1]) end;return items
end
function V.Totals(items)
 local result={0,0,0,0,0};local ready=true
 for _,item in pairs(items) do
  if not GetItemInfo(item) then ready=false else
   local stats=GetItemStats and GetItemStats(item)
   if not stats then ready=false else for i,key in ipairs(statKeys) do result[i]=result[i]+(stats[key] or 0) end end
  end
 end
 return result,ready
end
function V.Preview(slot,item)
 if V.selected~=1 or not item then return false end
 local _,resolved,_,_,_,_,_,_,loc=GetItemInfo(item)
 if not loc then V.message=L('missing');return false end
 local fits=false;for _,id in ipairs(allowed[loc] or {}) do if slot==id then fits=true end end
 if not fits then V.message=L('wrong');return false end
 V.items[slot]=resolved or item;V.message=L('received');return true
end
local function box(parent,x,y,w,h)
 local f=CreateFrame('Frame',nil,parent);f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetHeight(h)
 f:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=32,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
 f:SetBackdropColor(.045,.055,.05,.96);f:SetBackdropBorderColor(.4,.36,.24,1);return f
end
local function text(parent,x,y,w,font)
 local t=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlight');t:SetPoint('TOPLEFT',x,y);t:SetWidth(w);t:SetJustifyH('LEFT');return t
end
local function button(parent,x,y,w,key,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetPoint('TOPLEFT',x,y);b:SetWidth(w);b:SetHeight(26);b.key=key;b:SetScript('OnClick',fn);return b
end
function V.Refresh()
 if not V.frame then return end
 V.title:SetText(L('title')..' · EV1G');V.subtitle:SetText(L('preview'));V.hint:SetText(L('hint'))
 V.footer:SetText(V.message or L('status'));V.statsTitle:SetText(L('stats'));V.columns:SetText(L('columns'));V.note:SetText(L('note'))
 V.language:SetText(V.lang=='en' and '中文' or 'EN')
 if V.entry then V.entry:SetText(V.lang=='en' and 'Equipment' or '装备套装包') end
 for _,b in ipairs(V.controls) do if not V.server or (b~=V.capture and b~=V.clear and b~=V.controls[5]and b~=V.controls[4]and b~=V.controls[6]) then if b:GetText()~=L(b.key) then b:SetText(L(b.key)) end end end
 for i,t in ipairs(V.tabs) do if not V.server then
  t.label:SetText(L('pack')..' '..i);t.sub:SetText(i==1 and L('first') or L('locked'))
  t:SetBackdropBorderColor(i==V.selected and .9 or .32,i==V.selected and .68 or .3,i==V.selected and .2 or .24,1)
  t:SetBackdropColor(i==V.selected and .16 or .045,i==V.selected and .12 or .05,.035,i==V.selected and .62 or .38)
 end
 end
 local unlocked=V.server and V.server.CanUse()or(not V.server and V.selected==1)
 if unlocked then V.lock:Hide() else V.lock:Show() end
 V.lockLabel:SetText(L('locktext'));V.lockPrice:SetText(L('price'))
 for _,b in ipairs(V.buttons) do
  local item=unlocked and V.items[b.slot] or nil;b.item=item
  local texture=item and select(10,GetItemInfo(item))
  b.icon:SetTexture(texture or b.empty);b.icon:SetAlpha(item and 1 or .65);b.label:SetText(L(b.key))
 end
 local a,ar=V.Totals(V.items);local c,cr=V.Totals(V.ReadEquipped())
 for i,row in ipairs(V.rows) do
  row.name:SetText(L(statNames[i]));local delta=a[i]-c[i]
  row.value:SetText(unlocked and ar and cr and (a[i]..' / '..c[i]..' / '..(delta>0 and '+' or '')..delta) or '—')
 end
 if not V.server then if unlocked then V.capture:Enable();V.clear:Enable() else V.capture:Disable();V.clear:Disable() end end
 if not ar or not cr then V.footer:SetText(L('missing')) end
end
function V.Select(i) if type(i)~='number'or i<1 or i>2147483640 then return end;V.selected=i;V.message=nil;V.Refresh() end
local function drop(self)
 local kind,id,link=GetCursorInfo();if kind=='item' then V.Preview(self.slot,link or id);V.Refresh() end
 -- Deliberately do not ClearCursor, PickupItem, EquipItem or move the original.
end
local function create()
 if V.frame then return end
 local f=box(UIParent,0,0,1010,680);V.frame=f
 _G.RebornEquipmentVaultFrame=f
 f:ClearAllPoints();f:SetPoint('CENTER');f:SetFrameStrata('FULLSCREEN_DIALOG');f:SetToplevel(true);f:SetClampedToScreen(true);f:EnableMouse(true)
 local opaque=f:CreateTexture(nil,'BACKGROUND');opaque:SetPoint('TOPLEFT',4,-4);opaque:SetPoint('BOTTOMRIGHT',-4,4);opaque:SetTexture(.025,.028,.025,1);V.opaque=opaque
 local drag=CreateFrame('Frame',nil,f);drag:SetPoint('TOPLEFT',10,-5);drag:SetWidth(850);drag:SetHeight(40);drag:EnableMouse(true)
 f:SetMovable(true);drag:RegisterForDrag('LeftButton');drag:SetScript('OnDragStart',function()f:StartMoving()end);drag:SetScript('OnDragStop',function()f:StopMovingOrSizing()end)
 V.title=text(f,66,-16,710,'GameFontNormalLarge')
 local badge=CreateFrame('Frame',nil,f);badge:SetPoint('TOPLEFT',-16,16);badge:SetWidth(72);badge:SetHeight(72)
 local bag=badge:CreateTexture(nil,'ARTWORK');bag:SetPoint('CENTER',badge,'CENTER',0,0);bag:SetWidth(58);bag:SetHeight(58)
 SetPortraitToTexture(bag,'Interface\\Icons\\INV_Misc_Bag_08')
 DrawRoundRing(badge,'Interface\\AddOns\\RebornEquipmentVault\\Art\\ClassPortraitRing')
 V.badge=badge;V.bagIcon=bag

 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-2,-2);close:SetScript('OnClick',function()f:Hide()end)
 V.language=button(f,893,-10,65,'',function()V.lang=V.lang=='en' and 'zh' or 'en';RebornEVSettings.language=V.lang;V.message=nil;V.Refresh()end)
 local left=box(f,15,-54,190,548);local gear=box(f,215,-54,482,548);local right=box(f,707,-54,288,548)
 -- Full window background. UV excludes the padding added for EV1C's square canvas.
 local dragons=f:CreateTexture(nil,'BORDER');dragons:SetPoint('TOPLEFT',4,-4);dragons:SetPoint('BOTTOMRIGHT',-4,4)
 dragons:SetTexture('Interface\\AddOns\\RebornEquipmentVault\\Art\\TwinDragons_cartoon_v3_blp');dragons:SetTexCoord(0,1,170/1024,853/1024);V.dragons=dragons
 left:SetBackdropColor(.02,.025,.02,.35);gear:SetBackdropColor(.02,.025,.02,.16);right:SetBackdropColor(.02,.025,.02,.50)
 left:SetBackdropBorderColor(.4,.36,.24,.4);gear:SetBackdropBorderColor(.4,.36,.24,.2);right:SetBackdropBorderColor(.4,.36,.24,.4)
 for i=1,6 do
  local t=CreateFrame('Button',nil,left);t:SetPoint('TOPLEFT',10,-10-(i-1)*44);t:SetWidth(170);t:SetHeight(40)
  t:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=14})
  t.label=text(t,12,-7,145,'GameFontNormal');t.sub=text(t,12,-23,145,'GameFontHighlightSmall')
  t.label:SetHeight(14);t.sub:SetHeight(12)
  t:SetScript('OnEnter',function(self)if V.server then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(V.server.Name(self.pack));GameTooltip:Show()end end);t:SetScript('OnLeave',function()GameTooltip:Hide()end)
  t.pack=i;t:SetScript('OnClick',function(self)V.Select(self.pack)end);V.tabs[i]=t
 end
 V.pagePrev=button(left,12,-274,44,'',function()end);V.pagePrev:SetText('<');V.pagePrev:SetHeight(20)
 V.pageNext=button(left,134,-274,44,'',function()end);V.pageNext:SetText('>');V.pageNext:SetHeight(20)
 V.pageLabel=text(left,59,-279,72,'GameFontHighlightSmall');V.pageLabel:SetJustifyH('CENTER')
 V.rename=button(left,12,-299,166,'',function()end);V.rename:SetHeight(22)
 left:EnableMouseWheel(true);left:SetScript('OnMouseWheel',function(_,delta)if V.server and V.server.Page then V.server.Page(delta>0 and -1 or 1)end end)
 V.subtitle=text(gear,22,-14,440,'GameFontNormalLarge')
 local model=CreateFrame('PlayerModel',nil,gear);V.model=model;model:SetPoint('TOPLEFT',110,-67);model:SetWidth(260);model:SetHeight(355);model:SetUnit('player');model:SetRotation(.15)
 for _,s in ipairs(slots) do
  local x,y;if s[4]==2 then x=111+s[5]*105;y=-466 else x=s[4]==0 and 22 or 413;y=-55-s[5]*49 end
  local b=CreateFrame('Button',nil,gear);b:SetPoint('TOPLEFT',x,y);b:SetWidth(40);b:SetHeight(40);b.slot=s[1];b.key=s[2]
  b:SetNormalTexture('Interface\\Buttons\\UI-Quickslot2');b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
  local slotBase=b:CreateTexture(nil,'BACKGROUND');slotBase:SetAllPoints(b);slotBase:SetTexture(0,0,0,.55)
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetAllPoints()
  local emptyNames={[1]='Head',[2]='Neck',[3]='Shoulder',[4]='Shirt',[5]='Chest',[6]='Waist',[7]='Legs',[8]='Feet',[9]='Wrists',[10]='Hands',[11]='Finger',[12]='Finger',[13]='Trinket',[14]='Trinket',[15]='Chest',[16]='MainHand',[17]='SecondaryHand',[18]='Ranged',[19]='Tabard'}
  b.empty='Interface\\PaperDoll\\UI-PaperDoll-Slot-'..emptyNames[s[1]]
  b.label=text(b,s[4]==0 and 46 or (s[4]==1 and -110 or -20),-13,s[4]==2 and 80 or 105,'GameFontHighlightSmall');if s[4]==1 then b.label:SetJustifyH('RIGHT') end
  if s[4]==2 then b.label:ClearAllPoints();b.label:SetPoint('TOP',b,'BOTTOM',0,-5);b.label:SetJustifyH('CENTER') end
  b:RegisterForClicks('LeftButtonUp','RightButtonUp');b:SetScript('OnReceiveDrag',drop)
  b:SetScript('OnClick',function(self,key)if key=='RightButton' and V.selected==1 then V.items[self.slot]=nil;V.message=L('remove');V.Refresh() else drop(self) end end)
  b:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_RIGHT');if self.item then GameTooltip:SetHyperlink(self.item) else GameTooltip:SetText(L(self.key)..' · '..L('empty')) end;GameTooltip:AddLine(L('remove'),.8,.7,.4,true);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end);V.buttons[#V.buttons+1]=b
 end
 V.lock=box(gear,8,-45,466,493);V.lock:SetFrameLevel(gear:GetFrameLevel()+10);V.lock:EnableMouse(true)
 V.lockLabel=text(V.lock,38,-170,390,'GameFontNormalLarge');V.lockLabel:SetJustifyH('CENTER');V.lockPrice=text(V.lock,40,-245,386);V.lockPrice:SetJustifyH('CENTER')
 V.statsTitle=text(right,18,-19,250,'GameFontNormalLarge');V.columns=text(right,18,-53,250,'GameFontHighlightSmall');V.rows={}
 for i=1,5 do local y=-94-(i-1)*48;V.rows[i]={name=text(right,18,y,100),value=text(right,111,y,162)};V.rows[i].value:SetJustifyH('RIGHT') end
 V.note=text(right,18,-365,252,'GameFontHighlightSmall');V.note:SetTextColor(.65,.67,.62)
 V.hint=text(f,225,-612,765,'GameFontHighlightSmall');V.footer=text(f,225,-642,765,'GameFontHighlightSmall')
 V.capture=button(left,12,-325,166,'capture',function()V.items=V.ReadEquipped();V.message=nil;V.Refresh()end)
 V.clear=button(left,12,-359,166,'clear',function()V.items={};V.message=nil;V.Refresh()end)
 local refresh=button(left,12,-393,166,'refresh',function()V.message=nil;V.Refresh()end)
 V.controls={V.capture,V.clear,refresh}
 for i,key in ipairs({'buy','equip','link'}) do
  local b=button(left,12,-427-(i-1)*34,166,key,function()end);b:Disable();V.controls[#V.controls+1]=b
 end
 -- Keep controls indices stable: Bridge/BuildLink bind actions by index.
 -- This list changes presentation only, never the action bindings.
 local actionOrder={V.controls[4],V.rename,V.capture,V.controls[5],V.clear,V.controls[6],refresh}
 for row,b in ipairs(actionOrder)do
  b:ClearAllPoints();b:SetPoint('TOPLEFT',left,'TOPLEFT',12,-299-(row-1)*32);b:SetHeight(26)
 end
 f:SetScript('OnShow',function()f:Raise();model:SetUnit('player');V.Refresh()end)
 f:SetScript('OnHide',function()GameTooltip:Hide()end)
 UISpecialFrames[#UISpecialFrames+1]='RebornEquipmentVaultFrame'
end
function V.Toggle(command)
 if command=='version' then DEFAULT_CHAT_FRAME:AddMessage('RebornEquipmentVault EV1G');return end
 RebornEVSettings=RebornEVSettings or {};V.lang=RebornEVSettings.language=='en' and 'en' or 'zh'
 create()
 if V.initialized and V.frame:IsShown() then V.frame:Hide();return end
 if not V.initialized then V.items=V.ReadEquipped();V.initialized=true end
 V.frame:SetScale(math.min(1,(UIParent:GetWidth()-40)/1010,(UIParent:GetHeight()-50)/680));V.frame:Show();V.Refresh()
end
SLASH_REBORNEV1='/evault';SLASH_REBORNEV2='/equipvault';SlashCmdList.REBORNEV=V.Toggle
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_EQUIPMENT_CHANGED');events:RegisterEvent('UNIT_INVENTORY_CHANGED')
events:SetScript('OnEvent',function(_,_,unit)if (not unit or unit=='player' or type(unit)=='number') and V.frame and V.frame:IsShown() then V.model:SetUnit('player');V.Refresh() end end)
-- Called synchronously by the talent panel before its first Show.
function V.AttachTalentEntry(parent)
 if not parent or V.entry then return end
 V.entry=button(parent,270,-638,100,'title',function()V.Toggle()end)
 V.entry:SetText(V.lang=='en' and 'Wardrobe' or '套装衣柜')
 V.entry:ClearAllPoints();V.entry:SetPoint('BOTTOMLEFT',parent,'BOTTOMLEFT',270,10)
end
V.AttachTalentEntry(RebornWDTreePreview)
