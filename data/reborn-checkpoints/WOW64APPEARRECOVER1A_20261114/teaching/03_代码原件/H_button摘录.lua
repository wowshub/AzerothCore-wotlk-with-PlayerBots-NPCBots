 local function button(b)
  if not b or b._rebornActionFrameH then return end
  b._rebornActionFrameH=true
  b._rebornCreatorSkin=true
  -- Clear only once: repeated list refreshes must not erase our new button textures.
  for _,region in ipairs({b:GetRegions()}) do
   if region:GetObjectType()=='Texture' then region:SetAlpha(0) end
  end
  local function state(setter,color,layer)
   local t=solid(b,layer or 'BACKGROUND',color[4]);t:SetAllPoints(b)
   t:SetBlendMode('BLEND');t:SetVertexColor(unpack(color));b[setter](b,t)
  end
  state('SetNormalTexture',{0.025,0.030,0.040,0.52})
  state('SetPushedTexture',{0.010,0.015,0.020,0.74})
  state('SetHighlightTexture',{0.70,0.58,0.32,0.16},'HIGHLIGHT')
  state('SetDisabledTexture',{0.025,0.030,0.040,0.34})
  -- Quiet one-pixel edges retain the dark-glass style without a heavy frame.
  for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
   local edge=solid(b,'BORDER',0.27);edge:SetVertexColor(0.48,0.43,0.32,0.27)
   if side=='TOP' or side=='BOTTOM' then
    edge:SetHeight(1);edge:SetPoint(side..'LEFT',b,side..'LEFT',0,0);edge:SetPoint(side..'RIGHT',b,side..'RIGHT',0,0)
   else
    edge:SetWidth(1);edge:SetPoint('TOP'..side,b,'TOP'..side,0,0);edge:SetPoint('BOTTOM'..side,b,'BOTTOM'..side,0,0)
   end
  end
  if not RebornSelectActionNormalH then
   local colors={Normal={0.91,0.77,0.42},Highlight={1.0,0.90,0.64},Disabled={0.48,0.48,0.46}}
   for name,color in pairs(colors) do
    local f=CreateFont('RebornSelectAction'..name..'H');font(f,14);f:SetTextColor(unpack(color))
   end
  end
  b:SetNormalFontObject(RebornSelectActionNormalH)
  b:SetHighlightFontObject(RebornSelectActionHighlightH)
  b:SetDisabledFontObject(RebornSelectActionDisabledH)
 end
