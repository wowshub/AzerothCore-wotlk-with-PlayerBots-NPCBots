-- TG1E: presentation only. No talent application, AIO calls, or spectator commands.
local G=RebornTalentGuide
local atlas='Interface\\AddOns\\RebornTalentGuide\\Art\\uimicromenu2x'
local function Settings()
 RebornTGEntrySettings=RebornTGEntrySettings or {}
 return RebornTGEntrySettings
end
local function Skin(b,icon)
 if b.tgEntrySkin then return end
 local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetTexture(atlas);bg:SetTexCoord(.0654297,.12793,.330078,.490234);bg:SetAllPoints(b)
 icon:SetDrawLayer('ARTWORK');icon:ClearAllPoints();icon:SetPoint('CENTER',b,'CENTER',-1,1)
 local function Size()icon:SetSize(b:GetWidth()*.73,b:GetHeight()*.64)end
 b:HookScript('OnSizeChanged',Size);Size()
 b:HookScript('OnMouseDown',function()bg:SetTexCoord(.0654297,.12793,.494141,.654297);icon:SetVertexColor(.65,.65,.65)end)
 local function Up()bg:SetTexCoord(.0654297,.12793,.330078,.490234);icon:SetVertexColor(1,1,1)end
 b:HookScript('OnMouseUp',Up);b:HookScript('OnHide',Up)
 b.tgEntrySkin=true
end
local b=CreateFrame('Button','RebornTalentGuideMicroButton',UIParent)
G.microButton=b;b:SetSize(32,40);b:SetFrameStrata('MEDIUM');b:SetClampedToScreen(true);b:EnableMouse(true)
b:SetNormalTexture('Interface\\Icons\\INV_Misc_Book_09');b:SetPushedTexture('Interface\\Icons\\INV_Misc_Book_09')
b:GetPushedTexture():SetAlpha(0)
b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD');b:GetHighlightTexture():SetAlpha(.2)
Skin(b,b:GetNormalTexture())
-- TG1G: use DragonUI's existing evIsDetached contract; keep docked until dragged.
local dragging=false
local suppressClickUntil=0
b.evIsDetached=function()return true end -- Always independent of the crowded micro-menu.
b:SetMovable(true);b:RegisterForDrag('LeftButton')
local function RestorePosition()
 if Settings().talentPositionVersion~=2 then
  Settings().talentPosition={x=.5,y=.42};Settings().talentPositionVersion=2
 end
 local pos=Settings().talentPosition
 if type(pos)~='table' or type(pos.x)~='number' or type(pos.y)~='number' then pos={x=.5,y=.42};Settings().talentPosition=pos end
 b:SetParent(UIParent);b:SetSize(32,40);b.evDragonManaged=false;b:ClearAllPoints()
 b:SetPoint('CENTER',UIParent,'BOTTOMLEFT',math.max(0,math.min(1,pos.x))*UIParent:GetWidth(),math.max(0,math.min(1,pos.y))*UIParent:GetHeight())
 return true
end
local function SavePosition()
 local x,y=b:GetCenter();if not x or not y then return end
 local scale=b:GetEffectiveScale()/UIParent:GetEffectiveScale()
 Settings().talentPosition={x=math.max(0,math.min(1,x*scale/UIParent:GetWidth())),y=math.max(0,math.min(1,y*scale/UIParent:GetHeight()))}
end
local function StopDrag()
 if not dragging then return end
 b:StopMovingOrSizing();SavePosition();dragging=false;suppressClickUntil=GetTime()+.2;RestorePosition()
end
b:SetScript('OnDragStart',function()
 if InCombatLockdown() then return end
 SavePosition();dragging=true;RestorePosition();GameTooltip:Hide()
 if RebornEVRefreshMicroMenu then RebornEVRefreshMicroMenu()end
 b:StartMoving()
end)
b:SetScript('OnDragStop',StopDrag);b:HookScript('OnHide',StopDrag)
local function Layout()
 if InCombatLockdown()then return end
 RestorePosition();b:Show()
 if RebornEVRefreshMicroMenu then RebornEVRefreshMicroMenu()end
end
b:RegisterForClicks('LeftButtonUp','RightButtonUp')
local racial
local function ApplyRacial()
 if not racial then return end
 if Settings().showLargeRacial then racial:Show()else racial:Hide()end
end
local function FindRacial()
 if racial then return true end
 -- The legacy AIO launcher is anonymous. Match its exact label and direct parent,
 -- never hide the actual racial window or unrelated WorldFrame children.
 if not WorldFrame or not WorldFrame.GetChildren then return false end
 if not CustomRacialRadialButton and type(ToggleCustomRacialFrame)~='function' then return false end
 for _,child in ipairs({WorldFrame:GetChildren()})do
  if child.IsObjectType and child:IsObjectType('Button') and child.GetRegions then
   for _,region in ipairs({child:GetRegions()})do
    if region.GetText and region:GetText()=='Custom Racial' then
     racial=child
     child:HookScript('OnShow',function(self)if not Settings().showLargeRacial then self:Hide()end end)
     ApplyRacial();return true
    end
   end
  end
 end
 return false
end
b:SetScript('OnClick',function(_,key)
 if dragging or GetTime()<suppressClickUntil then return end
 GameTooltip:Hide()
 if key=='RightButton'then
  Settings().showLargeRacial=not Settings().showLargeRacial;FindRacial();ApplyRacial()
  print('[天赋推荐] Custom Racial 大图标：'..(Settings().showLargeRacial and'显示'or'隐藏')..'；小入口保留。')
 else
  if G.frame and G.frame:IsShown()then G.frame:Hide()else G.Open(false)end
 end
end)
b:SetScript('OnEnter',function(self)
 GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('天赋与雕文推荐',1,.82,0)
 GameTooltip:AddLine('左键：打开/关闭职业推荐图鉴',1,1,1)
 GameTooltip:AddLine('按住左键拖动；位置自动保存。/rticons reset 移回屏幕中间',.8,1,.8,true)
 GameTooltip:AddLine('右键：显示/隐藏 Custom Racial 大图标',.8,.8,.8,true);GameTooltip:Show()
end)
b:SetScript('OnLeave',function()GameTooltip:Hide()end)
local function Spectator()
 local eye=RebornSpectatorLauncherButton
 if not eye or not eye.icon then return false end
 if not eye.tgEntrySkin then
  -- Remove only the original full-size highlight texture, not click/drag handlers.
  for _,region in ipairs({eye:GetRegions()})do
   if region.GetDrawLayer and region:GetDrawLayer()=='HIGHLIGHT' then region:Hide()end
  end
  eye:SetSize(32,40);Skin(eye,eye.icon)
  eye:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD');eye:GetHighlightTexture():SetAlpha(.2)
 end
 return true
end
local ev=CreateFrame('Frame');local remaining,elapsed=0,0
local function Scan()Spectator();FindRacial()end
local function Begin()
 Layout();Scan();remaining=60;elapsed=0
 ev:SetScript('OnUpdate',function(self,dt)
  elapsed=elapsed+dt;if elapsed<1 then return end
  remaining=remaining-elapsed;elapsed=0;Scan()
  if remaining<=0 or (racial and RebornSpectatorLauncherButton and RebornSpectatorLauncherButton.tgEntrySkin)then self:SetScript('OnUpdate',nil)end
 end)
end
for _,event in ipairs({'PLAYER_LOGIN','PLAYER_ENTERING_WORLD','ADDON_LOADED','PLAYER_REGEN_ENABLED','UI_SCALE_CHANGED'})do ev:RegisterEvent(event)end
ev:SetScript('OnEvent',Begin)
SLASH_REBORNTGICONS1='/rticons'
SlashCmdList.REBORNTGICONS=function(command)
 command=(command or''):lower():match('^%s*(.-)%s*$')
 if command=='show'then Settings().showLargeRacial=true elseif command=='hide'then Settings().showLargeRacial=false end
 if command=='reset' and not InCombatLockdown() then StopDrag();Settings().talentPosition={x=.5,y=.42};Settings().talentPositionVersion=2;b.evDragonManaged=false;b:SetParent(UIParent)end
 Begin();ApplyRacial()
 print('[天赋推荐] /rticons show 显示旧种族大图标；/rticons hide 隐藏；/rticons reset 图标移回屏幕中间（脱战）。')
end
