-- EV2N: reuse DragonUI's own translucent micro-menu frame. Art only.
local V=RebornEquipmentVault
local atlas='Interface\\AddOns\\DragonUI\\Textures\\Micromenu\\uimicromenu2x'
local specs={
 RebornEquipmentVaultMicroButton={.10,.90,.04,.95,.72,.76},
 RebornWDTalentMicroButton={.19,.81,.50,.94,.60,.72},
 SpellDraftMicroButton={.03125,.96875,.515625,.984375,.75,.60},
}
local function Style(b,c)
 if b.evStyling then return end;b.evStyling=true
 if not b.evEntrySkin then
  local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetTexture(atlas)
  bg:SetTexCoord(.0654297,.12793,.330078,.490234);bg:SetPoint('CENTER',b,'CENTER',-1,1)
  local down=b:CreateTexture(nil,'BACKGROUND');down:SetTexture(atlas)
  down:SetTexCoord(.0654297,.12793,.494141,.654297);down:SetPoint('CENTER',b,'CENTER',0,0);down:Hide()
  b.evEntrySkin={bg=bg,down=down}
  b:HookScript('OnMouseDown',function(self)self.evEntrySkin.bg:Hide();self.evEntrySkin.down:Show()end)
  local function Up(self)self.evEntrySkin.bg:Show();self.evEntrySkin.down:Hide()end
  b:HookScript('OnMouseUp',Up);b:HookScript('OnHide',Up)
  b:HookScript('OnSizeChanged',function(self)Style(self,c)end)
 end
 local w,h=b:GetWidth(),b:GetHeight()
 b.evEntrySkin.bg:SetSize(w,h+1);b.evEntrySkin.down:SetSize(w,h+1)
 for _,tex in ipairs({b:GetNormalTexture(),b:GetPushedTexture()})do
  tex:ClearAllPoints();tex:SetPoint('CENTER',b,'CENTER',-1,1)
  tex:SetSize(w*c[5],h*c[6]);tex:SetTexCoord(c[1],c[2],c[3],c[4])
 end
 local hi=b:GetHighlightTexture()
 if hi then
  hi:SetTexture('Interface\\Buttons\\ButtonHilight-Square');hi:SetTexCoord(0,1,0,1)
  hi:ClearAllPoints();hi:SetAllPoints(b);hi:SetAlpha(.20)
 end
 b.evStyling=false
end
local function Scan()
 local complete=true
 for name,c in pairs(specs)do
  local b=_G[name]
  if b then
   if not b.evEntrySkin then
    if name~='RebornEquipmentVaultMicroButton'then b:SetSize(32,40)end
    Style(b,c)
   end
  else complete=false end
 end
 return complete
end
local events=CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGIN');events:RegisterEvent('PLAYER_ENTERING_WORLD');events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent',function(self)
 if Scan()then self:SetScript('OnUpdate',nil);return end
 self.remaining=10;self.elapsed=0
 self:SetScript('OnUpdate',function(f,elapsed)
  f.elapsed=f.elapsed+elapsed;if f.elapsed<.5 then return end;f.elapsed=0
  f.remaining=f.remaining-1
  if Scan()or f.remaining<=0 then f:SetScript('OnUpdate',nil)end
 end)
end)
Scan()
