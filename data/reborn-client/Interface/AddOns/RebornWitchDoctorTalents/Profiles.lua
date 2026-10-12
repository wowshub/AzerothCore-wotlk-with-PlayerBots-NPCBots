RebornWDRegisterTranslation("方案改名","Rename build")
RebornWDRegisterTranslation("关联套装衣柜","Linked wardrobe")
RebornWDRegisterTranslation("打开套装衣柜","Open wardrobe")
RebornWDRegisterTranslation("穿戴关联衣柜","Equip linked wardrobe")
local M=RebornWD8
local panel,rows
local names={[0]="巫毒",[1]="酿造",[2]="暗影狩猎",[3]="待选择专精"}
local function Label(parent,text,x,y,width)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");t:SetPoint("TOPLEFT",x,y);t:SetWidth(width or 230);t:SetJustifyH("LEFT");RebornWDSetText(t,text);return t
end
function RebornWD8RefreshProfiles()
 if not panel then return end
 local n=RebornWDBuildNames
 if panel.rename then if n and n.CanRename()then panel.rename:Enable()else panel.rename:Disable()end end
 for i,row in ipairs(rows) do
  local slot=i-1;local open=M.loaded and slot<M.unlocked
  -- WD108: reorder only the row position; slot identity/click/rename stays unchanged.
  local position=slot
  if M.loaded and M.active>=0 and M.active<M.unlocked then
   position=slot==M.active and 0 or (slot<M.active and slot+1 or slot)
  end
  row:ClearAllPoints();row:SetPoint("TOPLEFT",12,-34-position*38)
  local name=(RebornWDLanguage=="en" and "Build: " or "方案：")..i
  row.title:SetText(name)
  local active=open and M.loaded and M.active==slot
  local lockedText=i>3 and (RebornWDLanguage=="en" and "Reserved · unavailable" or "预留 · 尚未开放") or (RebornWDLanguage=="en" and "Locked · click for unlock price" or "锁定 · 点击查看解锁价格")
  local state=not open and lockedText or (active and (RebornWDLocalize("已激活").." · "..RebornWDLocalize(names[M.specs[i]])) or RebornWDLocalize(names[M.specs[i]]))
  if open and RebornWDBuildNames then state=(active and(RebornWDLocalize("已激活").." · ")or"")..RebornWDBuildNames.Label(slot)end
  row.status:SetText(state);row.status:SetTextColor(active and .2 or 1,open and 1 or .2,.2)
  row.selected:SetAlpha(open and M.slot==slot and .4 or 0)
 end
 local vault=RebornEquipmentVault and RebornEquipmentVault.server
 local info=vault and vault.linkInfo
 local linked=info and info.available and info.packs[M.slot+1] or 0
 RebornWDSetDropdown(panel.equipment,linked>0 and vault.Name(linked)or(RebornWDLanguage=="en"and"No wardrobe linked"or"未关联衣柜"))
 local can=info and info.available and M.loaded and not M.pending and M.slot==M.active and not vault.IsBusy()
 if can and linked>0 then panel.equip:Enable()else panel.equip:Disable()end
 if M.loaded and not M.pending and not M.HasDrafts() and M.slot<M.unlocked and M.slot~=M.active and M.specs[M.slot+1]~=3 then panel.activate:Enable() else panel.activate:Disable() end
end
function RebornWD8ToggleProfiles(parent)
 if panel then if panel:IsShown() then panel:Hide() else panel:Show();if RebornWDBuildNames then RebornWDBuildNames.Query()end;local v=RebornEquipmentVault and RebornEquipmentVault.server;if v then v.Query()end;RebornWD8RefreshProfiles() end;return end
 panel=CreateFrame("Frame",nil,parent);panel:SetWidth(278);panel:SetHeight(592);panel:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",12,72)
 panel:SetFrameLevel(parent:GetFrameLevel()+20);panel:EnableMouse(true)
 panel:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 Label(panel,"可用方案",14,-12)
 local rename=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate");rename:SetWidth(74);rename:SetHeight(20);rename:SetPoint("TOPLEFT",163,-10);RebornWDSetText(rename,"方案改名");panel.rename=rename
 rename:SetScript("OnClick",function()if RebornWDBuildNames then RebornWDBuildNames.Prompt()end end)
 local close=CreateFrame("Button",nil,panel,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",3,3);close:SetScript("OnClick",function()panel:Hide()end)
 rows={}
 for i=1,10 do
  local slot=i-1;local b=CreateFrame("Button",nil,panel);b:SetWidth(252);b:SetHeight(37);b:SetPoint("TOPLEFT",12,-34-(i-1)*38)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10});b:SetBackdropColor(.07,.07,.07,.9)
  b.selected=b:CreateTexture(nil,"BACKGROUND");b.selected:SetAllPoints(b);b.selected:SetTexture(1,.75,.05,1)
  b.title=Label(b,"",10,-4,235);b.status=Label(b,"",10,-20,235)
  b:SetScript("OnClick",function() if M.loaded and slot<M.unlocked then M.SelectSlot(slot) elseif RebornWDUnlock then RebornWDUnlock.Quote(slot) end end)
  rows[i]=b
 end
 local activate=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate");activate:SetWidth(120);activate:SetHeight(24);activate:SetPoint("TOPLEFT",14,-423);RebornWDSetText(activate,"免费切换方案");activate:SetScript("OnClick",M.Activate);panel.activate=activate
 local discard=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate");discard:SetWidth(120);discard:SetHeight(24);discard:SetPoint("TOPLEFT",143,-423);RebornWDSetText(discard,"撤销草稿")
 discard:SetScript("OnClick",function() if not M.pending then M.ResetDraft(M.slot);if M.navigate then M.navigate(M.keys[M.draftSpec]) end end end)
 Label(panel,"关联套装衣柜",14,-459)
 panel.equipment=CreateFrame("Frame","RebornWD8EquipmentMenu",panel,"UIDropDownMenuTemplate");panel.equipment:SetPoint("TOPLEFT",0,-478);UIDropDownMenu_SetWidth(panel.equipment,223)
 UIDropDownMenu_Initialize(panel.equipment,function()
  local v=RebornEquipmentVault and RebornEquipmentVault.server
  local en=RebornWDLanguage=="en"
  local function add(text,func,disabled,checked)
   local row=UIDropDownMenu_CreateInfo();row.text=text;row.func=func;row.disabled=disabled;row.checked=checked;UIDropDownMenu_AddButton(row)
  end
  if not v or not v.linkInfo or not v.linkInfo.available then
   add(en and"Synchronize wardrobe / install EV2I1"or"请同步衣柜或安装EV2I1",nil,true);return
  end
  local can=v.ProfileCanLink and v.ProfileCanLink()
  local linked=v.linkInfo.packs[M.slot+1]or 0
  if M.slot~=M.active then add(en and"Activate this build before linking"or"请先激活此方案再关联",nil,true)end
  add(en and"Unlink wardrobe"or"取消衣柜关联",function()v.ProfileChoose(linked,true)end,not can or linked==0,linked==0)
  local first=v.page
  if first>v.owned then add(en and"Previous page of owned wardrobes"or"上一页已解锁衣柜",function()v.Page(-1)end,v.IsBusy());return end
  add((en and"Page "or"第")..(math.floor((first-1)/6)+1).." / "..math.ceil(v.owned/6)..(en and""or"页"),nil,true)
  if first>1 then add(en and"Previous page"or"上一页衣柜",function()v.Page(-1)end,v.IsBusy())end
  for pack=first,math.min(first+5,v.owned)do
   local index=pack
   local name=v.Name(index)
   -- Include ID so equal custom names remain distinguishable.
   add(name.."  (#"..index..")",function()v.ProfileChoose(index,false)end,not can,linked==index)
  end
  if first+5<v.owned then add(en and"Next page"or"下一页衣柜",function()v.Page(1)end,v.IsBusy())end
 end)
 local open=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate");open:SetWidth(120);open:SetHeight(24);open:SetPoint("TOPLEFT",14,-521);RebornWDSetText(open,"打开套装衣柜")
 open:SetScript("OnClick",function()local v=RebornEquipmentVault and RebornEquipmentVault.server;if v and v.OpenWardrobe then v.OpenWardrobe()end end)
 local equip=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate");equip:SetWidth(120);equip:SetHeight(24);equip:SetPoint("TOPLEFT",143,-521);RebornWDSetText(equip,"穿戴关联衣柜");panel.equip=equip
 equip:SetScript("OnClick",function()local v=RebornEquipmentVault and RebornEquipmentVault.server;if v and v.ProfileEquip then v.ProfileEquip()end end)
 local refresh=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate");refresh:SetWidth(249);refresh:SetHeight(24);refresh:SetPoint("TOPLEFT",14,-555);RebornWDSetText(refresh,"刷新服务器状态")
 refresh:SetScript("OnClick",function()M.Query();if RebornWDBuildNames then RebornWDBuildNames.Query()end;local v=RebornEquipmentVault and RebornEquipmentVault.server;if v then v.Query()end end)
 if RebornWDBuildNames then RebornWDBuildNames.Query()end
 local v=RebornEquipmentVault and RebornEquipmentVault.server;if v then v.Query()end

 RebornWD8RefreshProfiles()
end

-- WD108: startup slot=0 is only a placeholder, not the player's chosen build.
-- Run after Allocation's reply so both normal and exact high-bit masks are available.
local followedInitialState=false
local previousReply=M.AEOnReply
function M.AEOnReply(operation,confirmed)
 if previousReply then previousReply(operation,confirmed) end
 if M.loaded and not M.pending and not followedInitialState then
  followedInitialState=true
  if not M.HasDrafts() then
   M.ResetDraft(M.active)
   if M.navigate then M.navigate(M.keys[M.draftSpec]) end
  end
 end
end
