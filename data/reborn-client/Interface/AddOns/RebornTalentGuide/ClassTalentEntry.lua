-- TG10A: route the Ascension entry by the actual player, not the last browsed catalog.
local G=RebornTalentGuide;local N=G.Navigation;local C=RebornTalentTreeCanvas
local E={};G.ClassEntry=E
local native={WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,DEATHKNIGHT=true,SHAMAN=true,MAGE=true,WARLOCK=true,DRUID=true}
function E.PlayerClass()
 local _,token,id=UnitClass('player')
 if native[token]then return token end -- a stale custom numeric ID must not override a classic token
 if token=='WITCHDOCTOR'or id==13 then return'WITCHDOCTOR'end
 return token
end
function E.Open(toggle)
 if E.busy then return false end
 if InCombatLockdown()then G.Message('请脱战后打开飞升职业天赋面板');return false end
 local token=E.PlayerClass()
 if token=='WITCHDOCTOR'then return false end -- actual WD handlers retain their original behavior
 if token~='WARRIOR'and token~='PALADIN'and token~='HUNTER'and token~='ROGUE'and token~='PRIEST'then G.Message('该职业飞升大面板尚未接入，请使用原经典天赋入口');return false end
 G.fromBot=false
 if RebornWDSpecHome and RebornWDSpecHome:IsShown()then RebornWDSpecHome:Hide()end
 if RebornWDTreePreview and RebornWDTreePreview:IsShown()then RebornWDTreePreview:Hide()end
 if not G.ClassHome then G.Message('职业专精首页尚未加载，请确认完整安装TG10A');return false end
 return G.ClassHome.Open(token,toggle)
end
-- Existing public API/command/launcher paths can all reach the old local WD Toggle.
-- Wrap their entries, not ToggleTalentFrame, so the original classic panel stays available.
function E.Install()
 local api=RebornWDTreePreviewAPI
 if api then for _,key in ipairs({'Open','ShowHome','Toggle'})do
  E.hooked=E.hooked or{}
  local original=api[key]
  if type(original)=='function'and original~=E.hooked[key]then
   local isToggle=key=='Toggle'
   local wrapper=function(...)
    if E.PlayerClass()=='WITCHDOCTOR'then return original(...)end
    return E.Open(isToggle)
   end
   E.hooked[key]=wrapper;api[key]=wrapper
  end
 end end
 local slash=SlashCmdList.REBORNWDTREE
 if type(slash)=='function'and slash~=E.slash then
  E.slash=function(...)if E.PlayerClass()=='WITCHDOCTOR'then return slash(...)end;return E.Open(true)end
  SlashCmdList.REBORNWDTREE=E.slash
 end
 local button=RebornWDTalentMicroButton
 if button and button~=E.button then
  E.button=button;local click=button:GetScript('OnClick')
  local enter=button:GetScript('OnEnter')
  button:SetScript('OnEnter',function(self,...)
   if E.PlayerClass()=='WITCHDOCTOR'then if enter then return enter(self,...)end;return end
   GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('飞升天赋',1,.82,0)
   GameTooltip:AddLine('打开本人职业的专精介绍首页；选择方向后浏览天赋树。',1,1,1,true);GameTooltip:Show()
  end)
  button:SetScript('OnClick',function(self,...)
   if E.PlayerClass()=='WITCHDOCTOR'then if click then return click(self,...)end;return end
   if IsAltKeyDown and IsAltKeyDown()then return end
   return E.Open(true)
  end)
 end
end
local events=CreateFrame('Frame')
for _,event in ipairs({'ADDON_LOADED','PLAYER_LOGIN','PLAYER_ENTERING_WORLD'})do events:RegisterEvent(event)end
events:SetScript('OnEvent',E.Install);E.events=events;E.Install()
function RebornAscensionTalentToggle()
 if E.PlayerClass()=='WITCHDOCTOR'and RebornWDTreePreviewAPI then return RebornWDTreePreviewAPI.Toggle()end
 return E.Open(true)
end
SLASH_REBORNASCENSIONTREE1='/rtalents';SlashCmdList.REBORNASCENSIONTREE=RebornAscensionTalentToggle

-- Production art is opaque BLP2/DXT1, 1612x774 at the top-left of a 2048x1024 texture.
local function art(board,index,stem)
 if not board.art then board.art=board:CreateTexture(nil,'BORDER');board.art:SetPoint('TOPLEFT',4,-4);board.art:SetPoint('BOTTOMRIGHT',-4,4)end
 board:SetBackdropColor(.02,.025,.035,0)
 board.art:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..stem)
 board.art:SetTexCoord((index-1)/3*.787109375,index/3*.787109375,0,.755859375)
 board.art:SetAlpha(.22);board.art:Show()
end
function C.Art(board,index)art(board,index,'PaladinAscensionTG10A_blp')end
function C.WarriorArt(board,index)art(board,index,'WarriorAscensionTG10A_blp')end
