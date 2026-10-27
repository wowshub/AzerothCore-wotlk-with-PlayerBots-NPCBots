-- WD7: CoA specialization-card artwork, adapted to the 3.3.5 frame API.
-- Navigation only: choosing a card never learns a spell or changes a saved build.
local root = "Interface\\AddOns\\RebornWitchDoctorTalents\\Art\\"
local specs = {
    {key="Shadowhunting", name="暗影狩猎", role="远程输出", roleAtlas="rangeddps", stats="敏捷", difficulty="常规",
     description="追随邦桑迪的教诲，以远程武器和暗影魔法宣泄洛阿的怒火。",
     samples={4006,12086,4505}},
    {key="Voodoo", name="巫毒", role="法术输出", roleAtlas="casterdps", stats="智力 · 精神", difficulty="进阶",
     description="操纵巫毒之力，以邪咒和灵魂法术削弱敌人，掌控战斗。",
     samples={4004,31154,31345}},
    {key="Brewing", name="酿造", role="治疗", roleAtlas="healer", stats="精神", difficulty="常规",
     description="调和丛林药材与神秘炼金术，酿制药剂，治疗并支援你的盟友。",
     samples={4005,12646,12645}},
}
local byID={}
for _,node in ipairs(RebornWDTreeData) do byID[node.ID]=node end
local function Atlas(parent,key,x,y,w,h,layer)
    local a=assert(RebornWDHomeArt[key],key)
    local t=parent:CreateTexture(nil,layer or "ARTWORK")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetHeight(h)
    t:SetTexture(a[1]);t:SetTexCoord(a[4],a[5],a[6],a[7]);return t
end
local function Label(parent,text,y,font,width)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    t:SetPoint("TOP",parent,"TOP",0,y);t:SetWidth(width or 320)
    t:SetJustifyH("CENTER");RebornWDSetText(t,text);return t
end
function RebornWDCreateSpecHome(onChoose)
    local f=CreateFrame("Frame","RebornWDSpecHome",UIParent)
    f:SetWidth(1294);f:SetHeight(690);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    f:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    local fallback=f:CreateTexture(nil,"BACKGROUND");fallback:SetAllPoints(f);fallback:SetTexture(.025,.025,.025,1)
    Atlas(f,"spec-background",4,-24,1286,662,"BORDER")
    local titlebar=f:CreateTexture(nil,"ARTWORK");titlebar:SetPoint("TOPLEFT",5,-4)
    titlebar:SetWidth(1284);titlebar:SetHeight(22);titlebar:SetTexture(.07,.07,.07,1)
    Label(f,"飞升 · 巫医天赋",-8)
    local portrait=f:CreateTexture(nil,"OVERLAY");portrait:SetPoint("TOPLEFT",-20,18)
    portrait:SetWidth(62);portrait:SetHeight(62)
    local p=RebornWDArt["class-round-witchdoctor"]
    portrait:SetTexture(p[1]);portrait:SetTexCoord(p[4],p[5],p[6],p[7])
    local ringFrame=CreateFrame("Frame",nil,f);ringFrame:SetWidth(72);ringFrame:SetHeight(72)
    ringFrame:SetPoint("CENTER",portrait,"CENTER",0,0)
    local ring=ringFrame:CreateTexture(nil,"OVERLAY");ring:SetAllPoints(ringFrame)
    ring:SetTexture(root.."ClassPortraitRing");ring:SetTexCoord(.25,.75,.25,.75)
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",0,2)
    close:SetScript("OnClick",function() f:Hide() end)
    f.languageButton=RebornWDAddLanguageButton(f)
    f.cards={}
    for i,spec in ipairs(specs) do
        local card=CreateFrame("Frame",nil,f);card:SetWidth(428);card:SetHeight(632)
        card:SetPoint("TOPLEFT",f,"TOPLEFT",5+(i-1)*428,-36);card.key=spec.key
        if i<3 then Atlas(card,"spec-columndivider",425,-8,4,604,"BORDER") end
        card.picture=Atlas(card,"spec-thumbnail-witchdoctor-"..spec.key:lower(),69,-30,290,175)
        card.border=Atlas(card,"spec-thumbnailborder-off",62,-24,304,187,"OVERLAY")
        card.glow=Atlas(card,"spec-selected-background1",0,0,428,632,"BORDER")
        card.glow:SetAlpha(.1);card.glow:SetBlendMode("ADD");card.glow:Hide()
        card.glows={card.glow}
        local shade=Atlas(card,"spec-selected-background1",0,0,428,632,"BORDER")
        shade:SetAlpha(.1);shade:SetBlendMode("MOD");shade:Hide();card.glows[#card.glows+1]=shade
        -- CoA uses layered, mirrored edges, not an opaque yellow panel.
        for side=1,2 do
            if (side==1 and i>1) or (side==2 and i<3) then
                for layer=2,5 do
                    local t=Atlas(card,"spec-selected-background"..layer,side==1 and 3.5 or 29.5,0,395,632,"BORDER")
                    if side==2 then local a=RebornWDHomeArt["spec-selected-background"..layer];t:SetTexCoord(a[5],a[4],a[6],a[7]) end
                    t:SetBlendMode("ADD");t:SetAlpha(layer==3 and .1 or 1);t:Hide();card.glows[#card.glows+1]=t
                end
            end
        end
        Label(card,spec.name,-233,"GameFontNormalLarge")
        Atlas(card,"ui-lfg-roleicon-"..spec.roleAtlas,193,-270,42,42)
        Label(card,spec.role,-315)
        Atlas(card,"spec-dividerline",69,-345,290,2)
        Label(card,spec.description,-364,"GameFontNormal",294)
        Label(card,"主要属性："..spec.stats,-442,"GameFontHighlight")
        local difficulty=Label(card,"上手难度："..spec.difficulty,-470)
        difficulty:SetTextColor(i==2 and .75 or .2,1,.1)
        Atlas(card,"spec-dividerline",69,-495,290,2)
        Label(card,"代表天赋",-506,"GameFontHighlightSmall")
        for j,id in ipairs(spec.samples) do
            local node=assert(byID[id],"missing representative node")
            local b=CreateFrame("Button",nil,card);b:SetWidth(46);b:SetHeight(46)
            b:SetPoint("TOPLEFT",card,"TOPLEFT",140+(j-1)*52,-530)
            local icon=b:CreateTexture(nil,"ARTWORK");icon:SetAllPoints(b)
            SetPortraitToTexture(icon,node.Icon)
            local border=b:CreateTexture(nil,"OVERLAY");border:SetAllPoints(b)
            border:SetTexture(root.."ClassPortraitRing");border:SetTexCoord(.25,.75,.25,.75)
            b:SetScript("OnEnter",function(self)
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(node.Name,1,.82,0)
                GameTooltip:AddLine(RebornWDLocalize("此处为天赋展示；进入天赋树查看开放情况。"),1,1,1,true);GameTooltip:Show()
            end)
            b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        local choose=CreateFrame("Button",nil,card,"UIPanelButtonTemplate")
        choose:SetWidth(290);choose:SetHeight(26);choose:SetPoint("TOP",card,"TOP",0,-595)
        RebornWDSetText(choose,"查看天赋");choose:SetScript("OnClick",function() onChoose(spec.key) end)
        card.activeLabel=Label(card,"",-576,"GameFontNormalSmall")
        card.activeLabel:SetTextColor(.2,1,.2)
        card.choose=choose;f.cards[i]=card
    end
    Label(f,"选择方向，浏览对应天赋树",-668,"GameFontHighlightSmall")
    UISpecialFrames[#UISpecialFrames+1]="RebornWDSpecHome"
    function f:RefreshState()
        local m=RebornWD8
        for _,card in ipairs(self.cards) do
            local active=m.loaded and m.slot==m.active and m.keys[m.specs[m.slot+1]]==card.key
            local bound=m.loaded and m.keys[m.specs[m.slot+1]]==card.key
            local selected=bound
            for _,glow in ipairs(card.glows) do if selected then glow:Show() else glow:Hide() end end
            local a=RebornWDHomeArt[selected and "spec-thumbnailborder-on" or "spec-thumbnailborder-off"]
            card.border:SetTexture(a[1]);card.border:SetTexCoord(a[4],a[5],a[6],a[7])
            RebornWDSetText(card.activeLabel,active and "已激活" or (bound and "本方案已选择" or ""))
            RebornWDSetText(card.choose,bound and "查看天赋" or "浏览天赋")
        end
    end
    -- Art selection never calls the talent/build protocol.
    f.artStyleButton=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    f.artStyleButton:SetSize(150,20)
    f.artStyleButton:SetPoint("TOPRIGHT",f,"TOPRIGHT",-104,-5)
    function f:RefreshArtStyle()
        RebornWDApplyArtStyle()
        for _,card in ipairs(self.cards) do
            local a=RebornWDHomeArt["spec-thumbnail-witchdoctor-"..card.key:lower()]
            card.picture:SetTexture(a[1]);card.picture:SetTexCoord(a[4],a[5],a[6],a[7])
        end
        self.artStyleButton:SetText(RebornWDArtStyle=="new" and "新绘 / New art" or "原版 / Original")
    end
    f.artStyleButton:SetScript("OnClick",function()
        RebornWDArtStyle=RebornWDArtStyle=="new" and "original" or "new"
        f:RefreshArtStyle()
    end)
    f:HookScript("OnShow",function() f:RefreshArtStyle() end)
    f:RefreshArtStyle()
    RebornWD8.homeChanged=function() f:RefreshState() end
    f:Hide();return f
end
