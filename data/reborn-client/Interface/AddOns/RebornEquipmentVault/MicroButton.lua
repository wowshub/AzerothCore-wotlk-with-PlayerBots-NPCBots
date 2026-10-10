-- EV2L: independent wardrobe entry; no talent activation and no item operation.
local V=RebornEquipmentVault
local b=CreateFrame('Button','RebornEquipmentVaultMicroButton',UIParent)
V.microButton=b
b:SetSize(32,40);b:SetFrameStrata('MEDIUM');b:SetClampedToScreen(true)
local path='Interface\\AddOns\\RebornEquipmentVault\\Textures\\WardrobeMicro'
b:SetNormalTexture(path);b:SetPushedTexture(path)
b:GetPushedTexture():SetVertexColor(.65,.65,.65)
b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
b:GetHighlightTexture():SetAlpha(.25)
local function Position()
 local p=RebornEVSettings and RebornEVSettings.microPosition
 if type(p)=='table'and type(p.x)=='number'and type(p.y)=='number'
  and p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1 then return p end
end
function b:evIsDetached()return self.evDetaching or self.evDragging or Position()~=nil end
local function Relayout()
 if RebornEVRefreshMicroMenu then RebornEVRefreshMicroMenu()end
end
local function FloatAt(x,y)
 b.SetPoint=UIParent.SetPoint -- DragonUI locks attached anchors after layout.
 b:SetParent(UIParent);b:SetScale(1);b:SetSize(32,40);b:SetFrameStrata('HIGH');b:SetFrameLevel(20);b:EnableMouse(true)
 b:ClearAllPoints();b:SetPoint('CENTER',UIParent,'BOTTOMLEFT',x,y)
 b.evDragonManaged=false;b:Show()
end
local function SavePosition()
 local x,y=b:GetCenter();if not x or not y then return end
 local scale=b:GetEffectiveScale()/UIParent:GetEffectiveScale()
 RebornEVSettings=RebornEVSettings or {}
 RebornEVSettings.microPosition={x=math.max(0,math.min(1,x*scale/UIParent:GetWidth())),y=math.max(0,math.min(1,y*scale/UIParent:GetHeight()))}
end
-- Compare effective screen rectangles, not differently-scaled local coordinates.
local neighbours={'CharacterMicroButton','SpellbookMicroButton','TalentMicroButton','AchievementMicroButton','QuestLogMicroButton','SocialsMicroButton','LFDMicroButton','CollectionsMicroButton','PVPMicroButton','MainMenuMicroButton','HelpMicroButton','RebornWDTalentMicroButton','SpellDraftMicroButton'}
local function Rect(f)
 if not f or not f.IsShown or not f:IsShown()or not f.GetLeft then return end
 local l,rr,t,bb=f:GetLeft(),f:GetRight(),f:GetTop(),f:GetBottom()
 if not l or not rr or not t or not bb then return end
 local scale=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
 return l*scale,rr*scale,t*scale,bb*scale
end
local function AvoidOverlap()
 if b.evDragging or b.evDetaching or not Position()then return end
 local l,rr,t,bb=Rect(b);if not l then return end
 local hit=false;local top=t
 for _,name in ipairs(neighbours)do
  local nl,nr,nt,nb=Rect(_G[name])
  if nl then
   if rr>nl+2 and l<nr-2 and t>nb+2 and bb<nt-2 then hit=true end
   top=math.max(top,nt)
  end
 end
 if hit then
  -- Above the entire visible button row; saved floating preference remains floating.
  local y=top+28
  if y>UIParent:GetHeight()-24 then
   local bottom=bb
   for _,name in ipairs(neighbours)do local _,_,_,nb=Rect(_G[name]);if nb then bottom=math.min(bottom,nb)end end
   y=math.max(24,bottom-28)
  end
  FloatAt((l+rr)/2,y);SavePosition()
 end
end
local dragWatch=CreateFrame('Frame',nil,UIParent)
local function StopDrag()
 -- Always release native movement, even if another script cleared our flag.
 b:StopMovingOrSizing();dragWatch:SetScript('OnUpdate',nil)
 if not b.evDragging then return end
 b.evDragging=false;SavePosition();AvoidOverlap();b.evIgnoreClickUntil=GetTime()+.2
end
local function Place()
 if b.evDragging then return end
 local p=Position()
 if p then FloatAt(p.x*UIParent:GetWidth(),p.y*UIParent:GetHeight());AvoidOverlap();return end
 Relayout()
 if b.evDragonManaged then
  local parent=b:GetParent();b:SetFrameStrata(parent:GetFrameStrata());b:SetFrameLevel(parent:GetFrameLevel()+10);b:EnableMouse(true)
  return
 end
 b.SetPoint=UIParent.SetPoint;b:SetParent(UIParent);b:SetScale(1);b:ClearAllPoints()
 if CharacterMicroButton then b:SetPoint('BOTTOM',CharacterMicroButton,'TOP',0,4)
 else b:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',-300,100)end
 b:Show()
end
b:SetMovable(true);b:RegisterForDrag('LeftButton');b:RegisterForClicks('LeftButtonUp','RightButtonUp')
b:SetScript('OnDragStart',function(self)
 if not IsAltKeyDown()or InCombatLockdown()then return end
 local x,y=self:GetCenter();if not x or not y then return end
 local scale=self:GetEffectiveScale()/UIParent:GetEffectiveScale()
 -- Reparenting can fire OnHide. Do not start the drag until that finishes.
 self.evDetaching=true;FloatAt(x*scale,y*scale);Relayout();self.evDetaching=false
 self.evDragging=true;GameTooltip:Hide();self:StartMoving()
 dragWatch:SetScript('OnUpdate',function()
  if not IsMouseButtonDown('LeftButton')then StopDrag()end
 end)
end)
b:SetScript('OnDragStop',StopDrag)
b:SetScript('OnMouseUp',function(_,key)if key=='LeftButton'then StopDrag()end end)
b:SetScript('OnHide',StopDrag)
b:SetScript('OnClick',function(self,key)
 GameTooltip:Hide()
 if IsAltKeyDown()then
  if key=='RightButton'and not InCombatLockdown()then
   StopDrag();RebornEVSettings=RebornEVSettings or {};RebornEVSettings.microPosition=nil
   self.evDragonManaged=false;Place()
  end
  return
 end
 if key=='LeftButton'and not self.evDragging and GetTime()>=(self.evIgnoreClickUntil or 0)then V.Toggle()end
end)
b:SetScript('OnEnter',function(self)
 GameTooltip:SetOwner(self,'ANCHOR_TOP')
 GameTooltip:SetText(V.lang=='en'and'Equipment Wardrobe'or'精品套装收藏衣柜',1,.82,0)
 GameTooltip:AddLine(V.lang=='en'and'Click to open or close your wardrobe.'or'点击直接打开或关闭衣柜。',1,1,1)
 GameTooltip:AddLine(V.lang=='en'and'Alt + left-drag: move; Alt + right-click: return to menu.'or'Alt＋左键拖动：移动；Alt＋右键：恢复菜单位置。',.8,.8,.8,true)
 GameTooltip:Show()
end)
b:SetScript('OnLeave',function()GameTooltip:Hide()end)
-- Saved normalized UI coordinates also survive resolution/UI scale changes.
b:RegisterEvent('PLAYER_ENTERING_WORLD');b:RegisterEvent('DISPLAY_SIZE_CHANGED');b:RegisterEvent('UI_SCALE_CHANGED');b:RegisterEvent('PLAYER_REGEN_DISABLED');b:RegisterEvent('PLAYER_REGEN_ENABLED')
b:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_REGEN_DISABLED'then StopDrag();return end
 if not InCombatLockdown()then Place()end
end)

-- Recovery never requires clicking the obscured button. No SavedVariables deletion.
SLASH_REBORNEVBUTTON1='/evbutton'
SlashCmdList.REBORNEVBUTTON=function(command)
 if InCombatLockdown()then DEFAULT_CHAT_FRAME:AddMessage('请脱离战斗后调整衣柜入口。 / Leave combat first.');return end
 StopDrag();b.evDetaching=false;RebornEVSettings=RebornEVSettings or {}
 command=(command or ''):lower():match('^%s*(.-)%s*$')
 if command=='rescue'then
  FloatAt(UIParent:GetWidth()/2,UIParent:GetHeight()/2);SavePosition();Relayout();AvoidOverlap()
 elseif command=='reset'or command==''then
  RebornEVSettings.microPosition=nil;b.evDragonManaged=false;Place()
 else DEFAULT_CHAT_FRAME:AddMessage('/evbutton reset — 恢复菜单原位；/evbutton rescue — 移到屏幕中央')end
end
-- A short post-login pass catches layouts that finalize after entering the world.
local settle=CreateFrame('Frame',nil,UIParent)
b:HookScript('OnEvent',function(_,event)
 if event=='PLAYER_ENTERING_WORLD'or event=='DISPLAY_SIZE_CHANGED'or event=='UI_SCALE_CHANGED'then
  settle.elapsed=0;settle:SetScript('OnUpdate',function(self,elapsed)
   self.elapsed=self.elapsed+elapsed;if self.elapsed<.5 then return end
   self:SetScript('OnUpdate',nil)
   if not InCombatLockdown()and not b.evDragging then AvoidOverlap()end
  end)
 end
end)
