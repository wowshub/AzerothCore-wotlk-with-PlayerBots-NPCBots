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
-- CoA artwork and catalogue, adapted to the existing 3.3.5 UI API.
local nodes, art = RebornWDTreeData, RebornWDArt
local M=RebornWD8
RebornWDArt["talents-node-square-green"]={RebornWDArt["talents-node-square-gray"][1],80,80,0.954102,0.993164,0.000977,0.079102}
local root = "Interface\\AddOns\\RebornWitchDoctorTalents\\Art\\"
local byID, frame, current = {}, nil, "Voodoo"
local talentButtons = {}
local home, ShowHome
local tabs = {{"Voodoo","巫毒"},{"Brewing","酿造"},{"Shadowhunting","暗影狩猎"}}
for _, n in ipairs(nodes) do byID[n.ID] = n end

local function Atlas(texture, name)
    local a = RebornWDHomeArt[name] or art[name]
    local tintGreen = false
    -- WD80C: choice/circle artwork has no green entry; retain its own shape.
    if not a and name:match("^talents%-node%-.*%-green$") then
        local grayName = name:gsub("%-green$", "-gray")
        a = RebornWDHomeArt[grayName] or art[grayName]
        tintGreen = a ~= nil
    end
    assert(a, name)
    texture:SetTexture(a[1]); texture:SetTexCoord(a[4],a[5],a[6],a[7])
    if tintGreen then texture:SetVertexColor(.3,1,.4,1)
    else texture:SetVertexColor(1,1,1,1) end
end
-- WD17: clip the existing atlas region geometrically; no new texture format.
-- 3.3.5 has no modern texture masks. Reuse 32 horizontal strips inside a circle.
local function RoundPortrait(portrait,name)
    local a=assert(RebornWDHomeArt[name] or art[name],name)
    portrait.rows=portrait.rows or {}
    local size,count=62,32
    local radius=size/2
    for i=1,count do
        local top=(i-1)*size/count
        local bottom=i*size/count
        -- Use the farther edge so the entire rectangular strip stays inside the circle.
        local edge=math.max(math.abs(top-radius),math.abs(bottom-radius))
        local half=math.sqrt(math.max(0,radius*radius-edge*edge))
        -- Skip the two zero-width tangent rows; the metal ring covers these caps.
        if half>0 then
            local row=portrait.rows[i]
            if not row then row=portrait:CreateTexture(nil,"ARTWORK");portrait.rows[i]=row end
            row:ClearAllPoints();row:SetPoint("TOPLEFT",portrait,"TOPLEFT",radius-half,-top)
            row:SetWidth(half*2);row:SetHeight(bottom-top)
            row:SetTexture(a[1])
            row:SetTexCoord(a[4]+(a[5]-a[4])*(radius-half)/size,
                a[4]+(a[5]-a[4])*(radius+half)/size,
                a[6]+(a[7]-a[6])*top/size,a[6]+(a[7]-a[6])*bottom/size)
        end
    end
end
local function Text(parent, font, value, point, relative, x, y)
    local s=parent:CreateFontString(nil,"OVERLAY",font)
    s:SetPoint(point,relative,point,x,y); RebornWDSetText(s,value); return s
end
-- WD94A: display-only styling; reuse the node and existing allocation lifecycle.
local function ClearFont(label,size)
    local font=label:GetFont()
    if font then label:SetFont(font,size,"OUTLINE") end
    label:SetShadowColor(0,0,0,1);label:SetShadowOffset(1,-1)
end
local function RankPlate(button)
    ClearFont(button.rank,14)
    button.rankPlate=button:CreateTexture(nil,"ARTWORK")
    button.rankPlate:SetTexture(0,0,0,.78)
    button.rankPlate:SetPoint("CENTER",button.rank,"CENTER",0,0)
    button.rankPlate:SetWidth(46);button.rankPlate:SetHeight(18)
end
local function RankColor(button,node,numeric)
    ClearFont(button.rank,numeric and 14 or 10)
    button.rankPlate:SetWidth(numeric and 46 or 58)
    if not numeric then button.rank:SetTextColor(.72,.72,.72,1)
    elseif node.Tab=="Class" then button.rank:SetTextColor(1,.9,.55,1)
    else button.rank:SetTextColor(.25,1,.25,1) end
end
local function Groups(tab)
    local map, groups = {}, {}
    for _,n in ipairs(nodes) do
        if n.Tab==tab then
            local key=n.PositionX..":"..n.PositionY
            if not map[key] then map[key]={}; groups[#groups+1]=map[key] end
            table.insert(map[key],n)
        end
    end
    for _,g in ipairs(groups) do table.sort(g,function(a,b) return a.ID<b.ID end) end
    return groups
end
-- WD186A: display the authoritative enrollment state, never opt in on opening.
local function EntryState()
    if not M.loaded then return "sync" end
    if M.pending and M.operation=="join" then return "joining" end
    if not M.modern then return "enroll" end
    if M.level<10 then return "level" end
    return "ready"
end
local function ConfirmEnrollment()
    if not M.loaded or M.modern or M.pending then return end
    if InCombatLockdown() then return end
    local revision=M.revision
    StaticPopupDialogs.REBORN_WD186_JOIN={text=RebornWDLocalize("启用此角色的新版巫医天赋系统？服务器会检查角色资格。启用不会自动选择专精或分配点数；10级起才能加点。"),button1=YES,button2=NO,timeout=0,whileDead=false,hideOnEscape=true,
        OnAccept=function()
            if M.loaded and not M.modern and not M.pending and M.revision==revision and not InCombatLockdown() then M.JoinAE() end
        end}
    StaticPopup_Show("REBORN_WD186_JOIN")
end
local entryTranslations={
    {"同步中","Syncing"},{"未启用","Not enabled"},
    {"启用巫医天赋系统","Enable Witch Doctor talents"},
    {"新角色：先启用天赋系统","New character: enable talents first"},
    {"当前节点尚未载入新版加点状态，不是技能都未实现。点击上方按钮启用；服务器会检查资格。","The modern talent state is not enabled yet. This does not mean all skills are unfinished. Use the button above; eligibility is checked by the server."},
    {"正在启用，请稍候","Enabling, please wait"},
    {"等待服务器确认后自动刷新，请勿重复点击。","The tree will refresh after the server confirms. Please do not click again."},
    {"正在读取角色天赋","Loading character talents"},
    {"还没有收到有效角色状态。请点击重新同步；若仍失败，请查看右下角提示。","No valid character state received. Click Sync again; check the bottom-right message if it still fails."},
    {"重新同步","Sync again"},
    {"已启用 · 10级开始加点","Enabled - allocation starts at level 10"},
    {"你可以先浏览三系技能。当前等级暂不能加点，AE/TE以服务器返回为准；升级后刷新。","Browse all three trees now. Allocation is locked at this level; AE/TE values come from the server. Refresh after leveling."},
    {"等待启用后读取 AE","Enable to load AE"},{"等待启用后读取 TE","Enable to load TE"},
    {"启用此角色的新版巫医天赋系统？服务器会检查角色资格。启用不会自动选择专精或分配点数；10级起才能加点。","Enable the modern Witch Doctor talents for this character? The server checks eligibility. This does not select a specialization or allocate points. Allocation starts at level 10."},
    {"此角色尚未启用新版巫医天赋，请先使用面板中间的启用按钮。","Enable modern Witch Doctor talents using the button in the middle of this panel first."},
    {"等待服务器同步；当前不能判断节点是否可用。","Waiting for the server; node availability is not known yet."},
}
for _,pair in ipairs(entryTranslations) do RebornWDRegisterTranslation(pair[1],pair[2]) end
local hoveredTalent
local function Tooltip(button)
    local n=button.group[button.choice]
    GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
    if not M.loaded or not M.modern then
        GameTooltip:SetText(n.Name,1,.82,0)
        GameTooltip:AddLine(RebornWDLocalize(not M.loaded and "等待服务器同步；当前不能判断节点是否可用。" or "此角色尚未启用新版巫医天赋，请先使用面板中间的启用按钮。"),1,.82,0,true)
        GameTooltip:Show();return
    end
    if M.AETooltip and M.AETooltip(n) then
        if #button.group>1 then GameTooltip:AddLine(RebornWDLocalize("悬停展开选项；点击圆形选项选择（"..button.choice.."/"..#button.group.."）"),.3,1,.4) end
        GameTooltip:Show();return
    end
    GameTooltip:SetText(n.Name,1,.82,0)
    GameTooltip:AddLine(RebornWDLocalize("需要等级："..((n.ID==29928 and 15) or (n.ID==6058 and 10) or n.RequiredLevel).."　最高点数："..n.MaxPoints),1,1,1)
    if #n.RequiredIDs>0 then
        local names={}
        for _,id in ipairs(n.RequiredIDs) do names[#names+1]=byID[id] and byID[id].Name or tostring(id) end
        GameTooltip:AddLine(RebornWDLocalize("前置记录：")..table.concat(names," / "),.8,.8,.8,true)
    end
    if n.ID==6058 or n.ID==29928 then
        GameTooltip:AddLine(RebornWDLocalize(n.ID==6058 and "黑暗魔法：恶毒之怒与邪恶巫术基础施法时间减少0.5秒。" or "邪恶巫术：15级开放。学习后加入技能书；2.5秒施法，15秒冷却，暗影伤害获得100%暗影法术强度与30%精神加成。"),.3,1,.4,true)
        if M.loaded and M.NodeRank(n.ID,M.TreeRank(M.slot,0))==1 and (M.slot~=M.active or M.specs[M.active+1]~=0) then
            GameTooltip:AddLine(RebornWDLocalize("已保存；切换到此绑定巫毒的方案后生效。"),1,.82,0,true)
        end
        GameTooltip:AddLine(RebornWDLocalize("10级起每级获得1点。未保存的加点可撤回；已保存点数需付费重置方案。"),1,.82,0,true)
        GameTooltip:AddLine(RebornWDLocalize("当前开放两个测试节点，暂不校验未开放节点前置；命中带有恶意妖术的目标并造成伤害时，使其受到的治疗降低20%，持续8秒。"),.7,.7,.7,true)
    else RebornWDProgress.Tooltip(n) end
    if #button.group>1 then GameTooltip:AddLine(RebornWDLocalize("悬停展开选项；点击圆形选项选择（"..button.choice.."/"..#button.group.."）"),.3,1,.4) end
    if RebornWDAudit and not M.modern then RebornWDAudit.Tooltip(n,button,Tooltip) end
    GameTooltip:Show()
end
-- WD67C hover lifecycle: redraw only the tooltip still owned by a visible node.
local function RefreshTalentTooltip()
    local button=hoveredTalent
    if not button then return end
    if not button:IsVisible() then
        if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
        hoveredTalent=nil;return
    end
    if not GameTooltip:IsOwned(button) then hoveredTalent=nil;return end
    Tooltip(button)
end
local function EnterTalent(button)
    hoveredTalent=button;Tooltip(button)
end
local function LeaveTalent(button)
    if hoveredTalent==button then hoveredTalent=nil end
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
end
-- WD67C hover lifecycle end.
local function Paint(b)
    -- WD80B: shared positions default to an available modern choice once state arrives.
    if M.modern and M.loaded and not b.modernChoice then
        for i,n in ipairs(b.group) do
            if M.IsAENode and M.IsAENode(n.ID) then b.choice=i;break end
        end
        b.modernChoice=true
    end
    if #b.group>1 and M.loaded then
        for i,entry in ipairs(b.group) do
            if M.IsAENode and M.IsAENode(entry.ID) and M.AERank(entry.ID)>0 then b.choice=i;break end
        end
    end
    local n=b.group[b.choice]
    local shape=b.choiceOption and "circle" or (#b.group>1 and "choice" or (n.NodeType:find("Circle") and "circle" or "square"))
    b.icon:SetTexCoord(.07,.93,.07,.93)
    if shape=="circle" and SetPortraitToTexture then SetPortraitToTexture(b.icon,n.Icon) else b.icon:SetTexture(n.Icon) end
    b.icon:SetDesaturated(true)
    Atlas(b.border,"talents-node-"..shape.."-gray")
    b.border:SetWidth(shape=="choice" and 50 or 44); b.border:SetHeight(44)
    RebornWDSetText(b.rank,RebornWDProgress.open[n.ID] and ("—/"..n.MaxPoints) or RebornWDProgress.Label(n))
    RebornWDSetText(b.choiceLabel,"") -- Selection index remains in the hover tooltip, not over the rank.
    if M.IsAENode and M.IsAENode(n.ID) and M.loaded then
        local rank=M.AERank(n.ID)
        local committed=M.AERank(n.ID,M.aeMasks[M.slot+1])==rank
        RebornWDSetText(b.rank,rank.."/"..n.MaxPoints..(committed and "" or " *"))
        b.icon:SetDesaturated(rank==0)
        Atlas(b.border,"talents-node-"..shape.."-"..(rank>0 and committed and "yellow" or "green"))
    elseif not M.modern and (n.ID==6058 or n.ID==29928) and M.loaded then
        local rank=M.NodeRank(n.ID)
        local committed=M.loaded and M.NodeRank(n.ID,M.TreeRank(M.slot,M.draftSpec))==rank
        RebornWDSetText(b.rank,rank.."/1"..(not committed and " *" or ""))
        local open=M.level>=(n.ID==29928 and 15 or 10)
        b.icon:SetDesaturated(not open)
        Atlas(b.border,"talents-node-"..shape.."-"..(rank==1 and committed and "yellow" or (open and "green" or "gray")))
    end
    if not M.loaded or not M.modern then
        RebornWDSetText(b.rank,not M.loaded and "同步中" or "未启用")
        b.icon:SetDesaturated(true);Atlas(b.border,"talents-node-"..shape.."-gray")
        RankColor(b,n,false)
    else
        RankColor(b,n,RebornWDProgress.open[n.ID] or (M.IsAENode and M.IsAENode(n.ID)))
    end
    if frame and frame.search then
        local q=(frame.search:GetText() or ""):lower()
        local name=RebornWDProgress.SearchName(n)
        b:SetAlpha((q=="" or name:find(q,1,true)) and 1 or .2)
    end
end
-- WD80D: CoA-style hover selection, with a short grace period between buttons.
local activeChoice
local function ChoiceRank(n)
    if not M.loaded then return 0 end
    if M.IsAENode and M.IsAENode(n.ID) then return M.AERank(n.ID) end
    if not M.modern and (n.ID==6058 or n.ID==29928) then return M.NodeRank(n.ID) end
    return 0
end
local function ChoiceBlocked(owner,index)
    for i,n in ipairs(owner.group) do
        if i~=index and ChoiceRank(n)>0 then return true end
    end
    return false
end
local function RefreshChoice(owner)
    for i,option in ipairs(owner.selection.options) do
        Paint(option)
        if ChoiceBlocked(owner,i) then
            option.icon:SetDesaturated(true)
            Atlas(option.border,"talents-node-circle-gray")
        end
    end
end
local function HideChoice(owner)
    if owner.selection then
        for _,option in ipairs(owner.selection.options) do LeaveTalent(option) end
        owner.selection:Hide()
    end
    owner:SetScript("OnUpdate",nil)
    if activeChoice==owner then activeChoice=nil end
end
local function InChoice(owner,focus)
    while focus do
        if focus==owner then return true end
        focus=focus.GetParent and focus:GetParent() or nil
    end
    return false
end
local function ChoiceUpdate(owner,elapsed)
    if not owner:IsVisible() then HideChoice(owner);return end
    if InChoice(owner,GetMouseFocus()) then owner.choiceAway=0
    else
        owner.choiceAway=(owner.choiceAway or 0)+elapsed
        if owner.choiceAway>.15 then HideChoice(owner) end
    end
end
local function ShowChoice(owner)
    if activeChoice and activeChoice~=owner then HideChoice(activeChoice) end
    if not owner.selection then
        local popup=CreateFrame("Frame",nil,owner)
        popup:SetWidth(#owner.group*60+16);popup:SetHeight(64)
        popup:SetPoint("BOTTOM",owner,"TOP",0,8)
        popup:SetFrameLevel(owner:GetFrameLevel()+10)
        popup:EnableMouse(true);popup.options={}
        local backdrop=popup:CreateTexture(nil,"BACKGROUND")
        backdrop:SetAllPoints(popup);backdrop:SetTexture(0,0,0,.82)
        owner.selection=popup
        for i,n in ipairs(owner.group) do
            local option=CreateFrame("Button",nil,popup)
            option:SetWidth(44);option:SetHeight(44)
            option:SetPoint("CENTER",popup,"CENTER",(i-(#owner.group+1)/2)*60,0)
            option.group,option.choice,option.choiceOption={n},1,true
            option.icon=option:CreateTexture(nil,"ARTWORK")
            option.icon:SetWidth(36);option.icon:SetHeight(36);option.icon:SetPoint("CENTER")
            option.border=option:CreateTexture(nil,"OVERLAY")
            option.border:SetPoint("CENTER")
            option.rank=Text(option,"GameFontNormal","","BOTTOM",option,0,-3)
            RankPlate(option)
            option.choiceLabel=Text(option,"GameFontNormalSmall","","TOP",option,0,0)
            option:RegisterForClicks("LeftButtonUp","RightButtonUp")
            option:SetScript("OnEnter",function(self)
                owner.choiceAway=0;EnterTalent(self)
                if ChoiceBlocked(owner,i) then
                    GameTooltip:AddLine(RebornWDLocalize("已选择另一个选项；先撤回该选项，已保存点数需重置。"),.7,.7,.7,true)
                    GameTooltip:Show()
                end
            end)
            option:SetScript("OnLeave",LeaveTalent)
            option:SetScript("OnHide",LeaveTalent)
            option:SetScript("OnClick",function(self,mouse)
                if mouse=="LeftButton" and ChoiceBlocked(owner,i) then
                    self:GetScript("OnEnter")(self);return
                end
                -- Pass the exact entry through the existing validated allocation path.
                owner.choice=i
                owner:GetScript("OnClick")(owner,mouse)
                Paint(owner);RefreshChoice(owner);EnterTalent(self)
            end)
            popup.options[i]=option
        end
    end
    activeChoice=owner;owner.choiceAway=0
    RefreshChoice(owner);owner.selection:Show()
    owner:SetScript("OnUpdate",ChoiceUpdate)
end

local function Tree(parent, tab, x)
    local tree=CreateFrame("Frame",nil,parent)
    tree:SetPoint("TOPLEFT",parent,"TOPLEFT",x, -106); tree:SetWidth(512);tree:SetHeight(512)
    local lines=tree:CreateTexture(nil,"BACKGROUND");lines:SetAllPoints(tree)
    lines:SetTexture(root.."Lines"..tab)
    if tab~="Class" then
        lines:ClearAllPoints();lines:SetPoint("TOPLEFT",tree,"TOPLEFT",0,0)
        lines:SetWidth(430);lines:SetHeight(512);lines:SetTexCoord(0,430/512,0,1)
        for step=0,3 do
            local line=tree:CreateTexture(nil,"BACKGROUND")
            line:SetPoint("TOPLEFT",tree,"TOPLEFT",464,-64-step*82)
            line:SetWidth(2);line:SetHeight(43);line:SetTexture(.38,.38,.38,1)
            local arrow=tree:CreateTexture(nil,"ARTWORK")
            arrow:SetPoint("CENTER",tree,"TOPLEFT",465,-107-step*82)
            arrow:SetWidth(10);arrow:SetHeight(9);Atlas(arrow,"talents-arrow-head-gray")
        end
    end
    for _,group in ipairs(Groups(tab)) do
        local n=group[1]
        local b=CreateFrame("Button",nil,tree);b:SetWidth(40);b:SetHeight(40)
        if n.PositionX==10 and tab~="Class" then
            b:SetPoint("CENTER",tree,"TOPLEFT",465,-46-n.PositionY*41)
        else b:SetPoint("CENTER",tree,"TOPLEFT",24+n.PositionX*44,-24-n.PositionY*44) end
        b.group,b.choice=group,1
        talentButtons[#talentButtons+1]=b
        b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetWidth(36);b.icon:SetHeight(36);b.icon:SetPoint("CENTER")
        b.border=b:CreateTexture(nil,"OVERLAY");b.border:SetPoint("CENTER")
        b.rank=Text(b,"GameFontNormal","","BOTTOM",b,0,-3)
        RankPlate(b)
        b.choiceLabel=Text(b,"GameFontNormalSmall","","TOP",b,0,10)
        Paint(b);b:RegisterForClicks("LeftButtonUp","RightButtonUp")
        b:SetScript("OnEnter",function(self)
            if #self.group>1 then LeaveTalent(self);ShowChoice(self) else EnterTalent(self) end
        end);b:SetScript("OnLeave",LeaveTalent)
        b:SetScript("OnHide",function(self) LeaveTalent(self);HideChoice(self) end)
        b:SetScript("OnClick",function(self,mouse)
            if mouse=="RightButton" and IsShiftKeyDown() and #self.group>1 then
                self.choice=self.choice % #self.group+1;Paint(self);Tooltip(self);return
            end
            local id=self.group[self.choice].ID
            if M.IsAENode and M.IsAENode(id) then
                M.SetNode(id,M.AERank(id)+(mouse=="RightButton" and -1 or 1));return
            end
            if not M.modern and (id==6058 or id==29928) then
                M.SetNode(id,(mouse=="RightButton" or M.NodeRank(id)==1) and 0 or 1);return
            end
            if mouse=="RightButton" then self.choice=self.choice % #self.group+1;Paint(self) end
            Tooltip(self)
        end)
    end
    return tree
end
local function SelectTab(tab)
    if M.SetSpec(tab)==false then return end
    current=tab
    if frame.portrait then RoundPortrait(frame.portrait,"specicon-witchdoctor-"..tab:lower()) end
    Atlas(frame.background,"talents-background-witchdoctor-"..tab:lower())
    for key,tree in pairs(frame.specTrees) do if key==tab then tree:Show() else tree:Hide() end end
    for _,tabInfo in ipairs(tabs) do
        if tabInfo[1]==tab then RebornWDSetText(frame.specTitle,tabInfo[2]);frame.specLabel=tabInfo[2] end
    end
    if frame.specDropDown then RebornWDSetDropdown(frame.specDropDown,"选择专精："..frame.specLabel) end

end
local function Open()
    if home then home:Hide() end
    if not frame then
        frame=CreateFrame("Frame","RebornWDTreePreview",UIParent)
        frame:SetWidth(1294);frame:SetHeight(690);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG")
        frame:SetClampedToScreen(true);frame:EnableMouse(true);frame:SetMovable(true);frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
        frame:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=false,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
        -- WD4D: keep the opaque fallback below the artwork, never in its draw layer.
        local fallback=frame:CreateTexture(nil,"BACKGROUND")
        fallback:SetPoint("TOPLEFT",4,-24);fallback:SetWidth(1286);fallback:SetHeight(617)
        fallback:SetTexture(.025,.025,.025,1)
        frame.background=frame:CreateTexture(nil,"BORDER")
        frame.background:SetPoint("TOPLEFT",4,-24);frame.background:SetWidth(1286);frame.background:SetHeight(617)
        local titlebar=frame:CreateTexture(nil,"BORDER");titlebar:SetTexture(0.07,0.07,0.07,1)
        titlebar:SetPoint("TOPLEFT",5,-4);titlebar:SetWidth(1284);titlebar:SetHeight(22)
        Text(frame,"GameFontNormal","飞升 · 巫医天赋","TOP",frame,0,-8)
        local portrait=CreateFrame("Frame",nil,frame);portrait:SetWidth(62);portrait:SetHeight(62)
        portrait:SetPoint("TOPLEFT",-20,18);RoundPortrait(portrait,"class-round-witchdoctor")
        -- Same neutral metal ring and UV crop as the creation-screen custom classes.
        local portraitFrame=CreateFrame("Frame",nil,frame)
        portraitFrame:SetWidth(72);portraitFrame:SetHeight(72)
        portraitFrame:SetPoint("CENTER",portrait,"CENTER",0,0)
        DrawRoundRing(portraitFrame,root.."ClassPortraitRing")
        local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",0,2)
        close:SetScript("OnClick",function() frame:Hide() end)
        Text(frame,"GameFontNormalLarge","巫医 · 通用","TOPLEFT",frame,263,-44)
        frame.specTitle=Text(frame,"GameFontNormalLarge","巫毒","TOPLEFT",frame,964,-44)
        frame.availablePoints=Text(frame,"GameFontNormal","等待同步","TOPLEFT",frame,263,-72)
        frame.spentPoints=Text(frame,"GameFontNormal","等待同步","TOPLEFT",frame,964,-72)
        local passive=frame:CreateTexture(nil,"ARTWORK");passive:SetPoint("TOPLEFT",1217,-88)
        passive:SetWidth(64);passive:SetHeight(438);Atlas(passive,"ca-passive-bg")
        frame.languageButton=RebornWDAddLanguageButton(frame)
        frame.portrait=portrait
        frame.classTree=Tree(frame,"Class",104)
        frame.specTrees={}
        for _,tab in ipairs(tabs) do frame.specTrees[tab[1]]=Tree(frame,tab[1],784) end
        local footer=frame:CreateTexture(nil,"BORDER");footer:SetPoint("BOTTOMLEFT",4,4)
        footer:SetWidth(1286);footer:SetHeight(65);Atlas(footer,"talents-background-bottombar")
        -- WD7A: CoA footer arrangement. Saved builds remain untouched on the server.
        local function Tip(button,text)
            button:SetScript("OnEnter",function(self)
                GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(RebornWDLocalize(text),1,.82,0,true);GameTooltip:Show()
            end)
            button:SetScript("OnLeave",function() GameTooltip:Hide() end)
        end
        frame.profileButton=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        frame.profileButton:SetWidth(235);frame.profileButton:SetHeight(23);frame.profileButton:SetPoint("BOTTOMLEFT",15,36)
        RebornWDSetText(frame.profileButton,"切换已保存方案")
        frame.profileButton:SetScript("OnClick",function() RebornWD8ToggleProfiles(frame) end)
        local builds=CreateFrame("Frame","RebornWDRecommendedBuilds",frame,"UIDropDownMenuTemplate")
        builds:SetPoint("BOTTOMLEFT",0,7);UIDropDownMenu_SetWidth(builds,218)
        RebornWDSetDropdown(builds,"查找推荐方案（待开放）");UIDropDownMenu_DisableDropDown(builds)
        local search=CreateFrame("EditBox",nil,frame)
        search:SetFontObject(GameFontHighlight);search:SetTextInsets(9,9,3,3)
        search:SetTextColor(.95,.95,.95,1);search:SetFrameLevel(frame:GetFrameLevel()+5)
        search:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=false,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
        search:SetBackdropColor(.035,.04,.045,.98);search:SetBackdropBorderColor(.55,.5,.35,1)
        search:SetWidth(310);search:SetHeight(24);search:SetPoint("BOTTOM",frame,"BOTTOM",0,36)
        search:SetAutoFocus(false);search:SetMaxLetters(60)
        search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        search:SetScript("OnTextChanged",function(self)
            local q=(self:GetText() or ""):lower()
            for _,b in ipairs(talentButtons) do
                local n=b.group[b.choice]
                local name=RebornWDProgress.SearchName(n)
                b:SetAlpha((q=="" or name:find(q,1,true)) and 1 or .2)
            end
        end)
        Tip(search,"搜索天赋名称；清空恢复全部节点")
        frame.search=search
        local save=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        save:SetWidth(180);save:SetHeight(22);save:SetPoint("BOTTOM",frame,"BOTTOM",0,10)
        RebornWDSetText(save,"保存本页更改");save:Disable()
        frame.saveButton=save
        save:SetScript("OnClick",function() M.Save() end)
        Tip(save,"保存本方案新增点数；已保存点数只能通过付费重置撤回")
        local reset=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        reset:SetWidth(180);reset:SetHeight(22);reset:SetPoint("BOTTOMRIGHT",-12,36);RebornWDSetText(reset,"付费重置方案")
        reset:SetScript("OnClick",M.QuoteReset)
        frame.resetButton=reset
        local change=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        change:SetWidth(180);change:SetHeight(22);change:SetPoint("BOTTOMRIGHT",-12,10)
        RebornWDSetText(change,"浏览天赋树");change:SetScript("OnClick",function() ShowHome() end);frame.backHome=change
        frame.syncText=Text(frame,"GameFontHighlightSmall","","BOTTOMRIGHT",frame,-210,12)
        frame.syncText:SetWidth(230);frame.syncText:SetJustifyH("RIGHT")
        local bind=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        bind:SetWidth(150);bind:SetHeight(22);bind:SetPoint("TOPLEFT",frame,"TOPLEFT",1086,-43)
        RebornWDSetText(bind,"选择本方案专精")
        bind:SetScript("OnClick",function()
            local slot,spec,rev=M.slot,M.draftSpec,M.revision
            StaticPopupDialogs.REBORN_WD16_BIND={text=RebornWDLocalize("确认选择此专精？首次选择免费，之后重新选择需要付费重置本方案。"),button1=YES,button2=NO,timeout=0,whileDead=false,hideOnEscape=true,
                OnAccept=function() if M.slot==slot and M.draftSpec==spec and M.revision==rev then M.Bind() end end}
            StaticPopup_Show("REBORN_WD16_BIND")
        end)
        frame.bindButton=bind
        local join=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
        join:SetWidth(200);join:SetHeight(22);join:SetPoint("TOPLEFT",frame,"TOPLEFT",480,-43)
        RebornWDSetText(join,"启用巫医天赋系统")
        join:SetScript("OnClick",ConfirmEnrollment)
        local guide=CreateFrame("Frame",nil,frame)
        guide:SetPoint("TOPLEFT",frame,"TOPLEFT",510,-112);guide:SetWidth(270);guide:SetHeight(180)
        guide:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=4,right=4,top=4,bottom=4}})
        guide:SetBackdropColor(.035,.045,.05,.94);guide:SetBackdropBorderColor(.5,.43,.25,1)
        guide.title=Text(guide,"GameFontNormalLarge","","TOPLEFT",guide,14,-14);guide.title:SetWidth(242);guide.title:SetJustifyH("LEFT")
        guide.body=Text(guide,"GameFontHighlight","","TOPLEFT",guide,14,-47);guide.body:SetWidth(242);guide.body:SetJustifyH("LEFT")
        guide.action=CreateFrame("Button",nil,guide,"UIPanelButtonTemplate");guide.action:SetWidth(230);guide.action:SetHeight(23);guide.action:SetPoint("BOTTOM",guide,"BOTTOM",0,12)
        guide.action:SetScript("OnClick",function() if M.loaded then ConfirmEnrollment() elseif not M.pending then M.Query() end end)
        frame.entryGuide=guide
        local function RefreshEntryGuide()
            local state=EntryState()
            if state=="ready" then guide:Hide();return end
            guide:Show();guide.action:Hide()
            local title,body
            if state=="enroll" then
                title="新角色：先启用天赋系统";body="当前节点尚未载入新版加点状态，不是技能都未实现。点击上方按钮启用；服务器会检查资格。"
                RebornWDSetText(guide.action,"启用巫医天赋系统");guide.action:Show()
                if not M.pending and M.layoutReady and not InCombatLockdown() then guide.action:Enable() else guide.action:Disable() end
            elseif state=="joining" then title="正在启用，请稍候";body="等待服务器确认后自动刷新，请勿重复点击。"
            elseif state=="level" then title="已启用 · 10级开始加点";body="你可以先浏览三系技能。当前等级暂不能加点，AE/TE以服务器返回为准；升级后刷新。"
            else
                title="正在读取角色天赋";body="还没有收到有效角色状态。请点击重新同步；若仍失败，请查看右下角提示。"
                RebornWDSetText(guide.action,"重新同步");guide.action:Show();if M.pending then guide.action:Disable() else guide.action:Enable() end
            end
            RebornWDSetText(guide.title,title);RebornWDSetText(guide.body,body)
        end
        guide.Refresh=RefreshEntryGuide

        M.changed=function()
            if M.loaded and not M.pending and M.slot<M.unlocked and M.specs[M.slot+1]==3 and M.level>=10 then bind:Enable() else bind:Disable() end
            if M.modern then join:Hide() else join:Show();if M.loaded and M.layoutReady and not M.pending and not InCombatLockdown() then join:Enable() else join:Disable() end end
            local total=M.TotalPoints()
            RebornWDSetText(frame.availablePoints,total and ("可用点数："..math.max(0,total-M.TotalSpent())) or "等待同步")
            RebornWDSetText(frame.spentPoints,total and ("本系已投入："..M.PointsUsed(M.draftRank).." / "..total) or "等待同步")
            if M.modern and M.loaded then
                RebornWDSetText(frame.availablePoints,"AE 剩余："..math.max(0,M.aeBudget-M.AESpent(M.draftAE)).." / "..M.aeBudget)
                RebornWDSetText(frame.spentPoints,"TE 剩余："..(M.teBudget-M.TESpent(M.draftAE)).." / "..M.teBudget)
            end
            if M.loaded and not M.modern then
                RebornWDSetText(frame.availablePoints,"等待启用后读取 AE");RebornWDSetText(frame.spentPoints,"等待启用后读取 TE")
            end
            RefreshEntryGuide()
            ClearFont(frame.availablePoints,17);ClearFont(frame.spentPoints,17)
            frame.availablePoints:SetTextColor(1,.9,.55);frame.spentPoints:SetTextColor(.25,1,.25)
            for _,b in ipairs(talentButtons) do Paint(b);if b.selection and b.selection:IsShown() then RefreshChoice(b) end end
            local ready=M.loaded and not M.pending and M.slot<M.unlocked and M.specs[M.slot+1]~=3
            if ready then reset:Enable() else reset:Disable() end
            if M.CanEdit() and M.dirty and not M.pending then save:Enable() else save:Disable() end
            RebornWDSetText(frame.syncText,M.message)
            if home and home.RefreshState then home:RefreshState() end
            if RebornWD8RefreshProfiles then RebornWD8RefreshProfiles() end
            RefreshTalentTooltip()
        end
        frame:RegisterEvent("PLAYER_REGEN_DISABLED");frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent",function() if frame:IsShown() then M.changed() end end)
        M.changed()
        UISpecialFrames[#UISpecialFrames+1]="RebornWDTreePreview"
    end
    frame:SetScale(math.min(1,(UIParent:GetWidth()-60)/1294,(UIParent:GetHeight()-80)/690))
    if RebornEquipmentVault and RebornEquipmentVault.AttachTalentEntry then RebornEquipmentVault.AttachTalentEntry(frame) end
    SelectTab(current);frame:Show();M.Query()
end
ShowHome=function()
    if frame then frame:Hide() end
    if not home then
        home=RebornWDCreateSpecHome(function(key)
            home:Hide();current=key;Open()
        end)
    end
    home:SetScale(math.min(1,(UIParent:GetWidth()-60)/1294,(UIParent:GetHeight()-80)/690))
    home:Show();home:RefreshState();if not M.loaded then M.Query() end
end
local function Toggle()
    if frame and frame:IsShown() then frame:Hide()
    elseif home and home:IsShown() then home:Hide()
    else ShowHome() end
end

-- Independent non-secure button: no replacement of Monk/SpellDraft microbuttons.
local launcher=CreateFrame("Button","RebornWDTalentMicroButton",UIParent)
launcher:SetWidth(30);launcher:SetHeight(44);launcher:SetFrameStrata("MEDIUM")
launcher:SetNormalTexture(root.."UI-MicroButton-Talents-Up")
launcher:SetPushedTexture(root.."UI-MicroButton-Talents-Down")
launcher:SetHighlightTexture("Interface\\Buttons\\UI-MicroButton-Hilight","ADD")
launcher:SetMovable(true);launcher:SetClampedToScreen(true);launcher:RegisterForDrag("LeftButton")
launcher:Hide()
launcher:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(RebornWDLocalize("巫医天赋"),1,.82,0)
    GameTooltip:AddLine(RebornWDTalentBindingText and RebornWDTalentBindingText() or RebornWDLocalize("点击打开专精首页；按住Alt拖动图标"),1,1,1);GameTooltip:Show()
end)
launcher:SetScript("OnLeave",function() GameTooltip:Hide() end)
launcher:SetScript("OnClick",function() if not IsAltKeyDown() then Toggle() end end)
launcher:SetScript("OnDragStart",function(self) if IsAltKeyDown() then self:StartMoving();self.dragging=true end end)
launcher:SetScript("OnDragStop",function(self)
    if not self.dragging then return end
    self:StopMovingOrSizing();self.dragging=false
    local x,y=self:GetCenter()
    RebornWDButtonPosition={x=x/UIParent:GetWidth(),y=y/UIParent:GetHeight()}
end)
launcher:RegisterEvent("PLAYER_LOGIN")
launcher:SetScript("OnEvent",function(self)
    local _,token,id=UnitClass("player")
    if token~="WITCHDOCTOR" and id~=13 then self:Hide();return end
    self:ClearAllPoints()
    local p=RebornWDButtonPosition
    if type(p)=="table" and type(p.x)=="number" and type(p.y)=="number" and p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1 then
        self:SetPoint("CENTER",UIParent,"BOTTOMLEFT",p.x*UIParent:GetWidth(),p.y*UIParent:GetHeight())
    elseif TalentMicroButton and TalentMicroButton:IsShown() then
        self:SetPoint("BOTTOM",TalentMicroButton,"TOP",0,4)
    else self:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-235,100) end
    self:Show()
end)
SLASH_REBORNWDTREE1="/wdtalent"
SlashCmdList.REBORNWDTREE=Toggle
M.navigate=function(key) if frame then SelectTab(key) end end
local previousChanged=M.changed
M.changed=function() if previousChanged then previousChanged() end;if home and home.RefreshState then home:RefreshState() end end
RebornWDTreePreviewAPI={Groups=Groups,Open=Open,SelectTab=SelectTab,ShowHome=ShowHome,Toggle=Toggle}

-- WD12A: only a server system message can request the trainer's talent entry.
local trainer=CreateFrame("Frame")
trainer:RegisterEvent("CHAT_MSG_SYSTEM")
trainer:SetScript("OnEvent",function(_,_,msg)
 if msg=="WD12A|open" and select(2,UnitClass("player"))=="WITCHDOCTOR" and not InCombatLockdown() then ShowHome() end
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,msg) return msg=="WD12A|open" end)
