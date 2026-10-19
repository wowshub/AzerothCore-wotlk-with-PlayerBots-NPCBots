-- TG11B: local presentation only. No global widget hooks or polling.
RebornTalentGuideTheme={surfaces={},selectors={}}
local T=RebornTalentGuideTheme
local ART='Interface\\AddOns\\RebornTalentGuide\\Art\\'
local captions={'暗石殿','夜色遗迹','墨色石室','素色'}
local function choice()
 RebornTGViewSettings=RebornTGViewSettings or{}
 local v=RebornTGViewSettings.quietBackground
 if type(v)~='number'or v~=v or v%1~=0 or v<1 or v>4 then v=2 end
 return v
end
function T.PaintButton(b)
 local enabled=b:IsEnabled();local disabled=not enabled or enabled==0;local selected=b.tgSelected
 local fill=disabled and{.045,.052,.060}or b.tgPressed and{.035,.065,.085}or selected and{.09,.17,.22}or b.tgHover and{.105,.135,.16}or{.055,.075,.095}
 b:SetBackdropColor(fill[1],fill[2],fill[3],1)
 local edge=disabled and{.17,.19,.21}or selected and{.72,.60,.35}or b.tgHover and{.5,.6,.65}or{.28,.33,.36}
 b:SetBackdropBorderColor(edge[1],edge[2],edge[3],1)
 b.tgLabel:SetTextColor(disabled and .48 or selected and 1 or .87,disabled and .51 or selected and .87 or .90,disabled and .54 or selected and .58 or .92)
 b.tgMark:SetAlpha(selected and not disabled and 1 or 0)
 b.tgTop:SetAlpha(disabled and .10 or .30)
end
function T.Button(parent,x,y,width,height,value,fn)
 local b=CreateFrame('Button',nil,parent);b:SetPoint('TOPLEFT',x,y);b:SetSize(width,height)
 b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
 b.tgLabel=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');b.tgLabel:SetPoint('TOPLEFT',8,-3);b.tgLabel:SetPoint('BOTTOMRIGHT',-8,3);b.tgLabel:SetJustifyH('CENTER')
 b.tgLabel:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',12,'OUTLINE');b:SetFontString(b.tgLabel);b.label=b.tgLabel;b:SetText(value)
 b.tgTop=b:CreateTexture(nil,'BORDER');b.tgTop:SetPoint('TOPLEFT',4,-3);b.tgTop:SetPoint('TOPRIGHT',-4,-3);b.tgTop:SetHeight(1);b.tgTop:SetTexture(.62,.69,.73,1)
 b.tgMark=b:CreateTexture(nil,'BORDER');b.tgMark:SetPoint('TOPLEFT',3,-4);b.tgMark:SetPoint('BOTTOMLEFT',3,4);b.tgMark:SetWidth(2);b.tgMark:SetTexture(.90,.73,.40,1)
 function b:Select(on)self.tgSelected=on and true or false;T.PaintButton(self)end
 b.SetNavSelected=b.Select
 b:SetScript('OnEnter',function(self)self.tgHover=true;T.PaintButton(self)end)
 b:SetScript('OnLeave',function(self)self.tgHover=false;self.tgPressed=false;T.PaintButton(self)end)
 b:SetScript('OnMouseDown',function(self)self.tgPressed=true;T.PaintButton(self)end)
 b:SetScript('OnMouseUp',function(self)self.tgPressed=false;T.PaintButton(self)end)
 b:SetScript('OnEnable',T.PaintButton);b:SetScript('OnDisable',T.PaintButton)
 b:SetScript('OnHide',function(self)self.tgPressed=false;self.tgHover=false;T.PaintButton(self)end)
 b:SetScript('OnClick',fn);T.PaintButton(b);return b
end
local function paintSurface(surface)
 local v=choice();local texture=surface.texture
 if v==4 then texture:SetTexture(.025,.033,.043,1);texture:SetTexCoord(0,1,0,1)
 else texture:SetTexture(ART..'QuietTalent'..({'A','B','C'})[v]..'TG11B_blp');texture:SetTexCoord(0,.787109375,0,.755859375)end
 texture:SetAlpha(1)
end
function T.Cycle()
 RebornTGViewSettings=RebornTGViewSettings or{};RebornTGViewSettings.quietBackground=choice()%4+1
 for _,s in ipairs(T.surfaces)do paintSurface(s)end
 for _,b in ipairs(T.selectors)do b:SetText('背景：'..captions[choice()])end
end
function T.Surface(frame,texture,selector)
 if frame.tgQuietSurface then return end
 frame.tgQuietSurface=true;T.surfaces[#T.surfaces+1]={texture=texture};paintSurface(T.surfaces[#T.surfaces])
 frame:SetBackdropBorderColor(.32,.37,.40,1)
 if selector then
  local b=T.Button(frame,870,-5,145,20,'背景：'..captions[choice()],T.Cycle)
  T.selectors[#T.selectors+1]=b;frame.tgBackgroundChoice=b
 end
end
