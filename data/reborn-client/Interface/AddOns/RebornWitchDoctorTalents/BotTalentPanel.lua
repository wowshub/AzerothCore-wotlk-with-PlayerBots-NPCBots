-- MBWD2A: CoA artwork and real custom node data, with an isolated bot editor.
local M=RebornWDBotTalents
local specs={{key="Voodoo",name="巫毒 / Voodoo",role="法术输出 / Spell DPS"},
    {key="Brewing",name="酿造 / Brewing",role="治疗 / Healing"},
    {key="Shadowhunting",name="暗影狩猎 / Shadowhunting",role="远程输出 / Ranged DPS"}}
local frame,home,tree,status,title,budget,bind,save,activate,join,discard,reset,unlock
local nodes,slots,cards,links={},{},{},{}
local selectedView="home"
local function text(parent,value,x,y,width,font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormal")
    t:SetPoint("TOPLEFT",x,y);t:SetWidth(width);t:SetJustifyH("LEFT");t:SetText(value);return t
end
local palette={normal={.055,.085,.115},selected={.10,.20,.29},active={.045,.24,.15},primary={.38,.07,.055},danger={.25,.11,.045},purchase={.23,.17,.055}}
local function paint(b)
    local on=b:IsEnabled();on=on and on~=0
    local c=on and(palette[b.stateRole or b.role]or palette.normal)or{.045,.05,.06}
    local boost=on and b.hover and .045 or 0
    b:SetBackdropColor(c[1]+boost,c[2]+boost,c[3]+boost,1)
    local active=b.stateRole=="active";local selected=b.stateRole=="selected"
    b:SetBackdropBorderColor(on and(active and .95 or selected and .43 or .34)or .18,on and(active and .76 or selected and .72 or .40)or .20,on and(active and .32 or selected and .90 or .46)or .22,1)
    b.label:SetTextColor(on and .94 or .43,on and .94 or .46,on and .86 or .49)
end
local function button(parent,label,x,y,w,callback,role)
    local b=CreateFrame("Button",nil,parent);b.role=role or "normal"
    b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=2,right=2,top=2,bottom=2}})
    b.label=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");b.label:SetPoint("CENTER");b.label:SetWidth(w-12);b:SetFontString(b.label)
    b:SetPoint("TOPLEFT",x,y);b:SetSize(w,28);b:SetText(label);b:SetScript("OnClick",callback)
    b:HookScript("OnEnter",function(self)self.hover=true;paint(self)end);b:HookScript("OnLeave",function(self)self.hover=false;paint(self)end)
    b:SetScript("OnEnable",paint);b:SetScript("OnDisable",paint);paint(b);return b
end
local function atlas(t,key)
    local a=(RebornWDHomeArt and RebornWDHomeArt[key]) or (RebornWDArt and RebornWDArt[key])
    if not a then t:SetTexture(0.02,0.035,0.05,.95);return end
    t:SetTexture(a[1]);t:SetTexCoord(a[4],a[5],a[6],a[7])
end
local function enable(b,on) if on then b:Enable() else b:Disable() end end
local function coins(value)
    if value==nil then return "未同步 / Unknown" end
    return math.floor(value/10000).."g "..math.floor(value/100)%100 .."s "..value%100 .."c"
end
local function refresh()
    if not frame then return end
    title:SetText("巫医机器人天赋 / Witch Doctor Bot Talents — "..(M.name or "").."  GUID "..(M.id or "?"))
    local spec=M.loaded and specs[M.specs[M.active+1]+1]
    local ae=M.loaded and M.AESpent(M.draftAE) or 0
    local te=M.loaded and M.TESpent(M.draftAE) or 0
    budget:SetText((M.loaded and ("Lv "..M.level.."  当前激活 / Active: "..(spec and spec.name or "未绑定 / Unbound")..
        "  |  草稿 / Draft AE "..ae.."/"..M.aeBudget.."  TE "..te.."/"..M.teBudget) or "等待该机器人服务器数据 / Waiting for this bot's server state")..
        "\n机器人余额（上次同步） / Bot balance (last sync): "..coins(M.money))
    status:SetText(M.message or "")
    for i,b in ipairs(slots) do
        local open=M.loaded and i<=M.unlocked
        b:SetText("方案 / Build "..i..(M.loaded and i-1==M.active and " ★" or ""))
        if not open then b:SetText("方案 / Build "..i.." [锁定 / Locked]") end
        enable(b,M.loaded and not M.pending and (open or i-1==M.unlocked))
        b.stateRole=M.loaded and i-1==M.active and "active"or i-1==M.slot and "selected"or nil
        if M.loaded and i-1==M.active then b:SetText("方案 / Build "..i.." · 已激活 / Active")end
        paint(b)
    end
    for i,c in ipairs(cards) do
        local chosen=M.loaded and M.specs[M.slot+1]==i-1
        c.state:SetText(chosen and (M.slot==M.active and "已激活 / Active" or "已绑定此方案 / Bound") or "浏览 / Preview")
        c.state:SetTextColor(chosen and .3 or .8,chosen and 1 or .8,.3)
        local live=M.loaded and M.specs[M.active+1]==i-1
        if live then c.state:SetText("当前激活 / Active now")end
        c:SetBackdropBorderColor(live and .94 or chosen and .4 or .25,live and .76 or chosen and .7 or .3,live and .3 or chosen and .9 or .35,1)
        c:SetBackdropColor(live and .03 or .02,live and .13 or .035,live and .08 or .05,.8)
        if c.view then c.view.stateRole=live and "active"or chosen and "selected"or nil;paint(c.view)end
    end
    enable(save,M.CanEdit() and M.HasDrafts())
    enable(bind,M.loaded and M.modern and not M.pending and M.slot<M.unlocked and M.specs[M.slot+1]==3 and not M.HasDrafts())
    enable(activate,M.loaded and not M.pending and M.slot~=M.active and M.specs[M.slot+1]<3 and not M.HasDrafts())
    enable(join,M.loaded and not M.pending and not M.modern)
    enable(discard,not M.pending and M.HasDrafts())
    enable(reset,M.loaded and not M.pending and M.slot<M.unlocked and M.specs[M.slot+1]~=3 and not M.HasDrafts())
    enable(unlock,M.loaded and not M.pending and M.unlocked<3 and not M.HasDrafts())
    for _,b in ipairs(nodes) do
        local id=b.node.ID
        local rank=M.loaded and M.AERank(id) or 0
        local maximum=RebornWDNodeLayout.maximum[id]
        b.rank:SetText(maximum and (rank.."/"..maximum) or "—")
        b.icon:SetDesaturated(not maximum)
        if rank>0 then b.border:SetVertexColor(.3,1,.4) else b.border:SetVertexColor(.65,.65,.65) end
    end
end
local function view(spec)
    if spec~=nil and not M.SelectSpec(spec) then return end
    selectedView=spec==nil and "home" or "tree"
    if selectedView=="home" then home:Show();tree:Hide() else home:Hide();tree:Show() end
    if spec~=nil then
        if tree.scroll then
            local bar=tree.scroll.ScrollBar or _G[tree.scroll:GetName().."ScrollBar"]
            if bar then bar:SetValue(0) end
            tree.scroll:SetVerticalScroll(0)
        end
        atlas(tree.bg,"talents-background-witchdoctor-"..specs[spec+1].key:lower())
        for _,b in ipairs(nodes) do
            if b.node.Tab=="Class" or b.node.Tab==specs[spec+1].key then b:Show() else b:Hide() end
        end
        for _,line in ipairs(links) do
            if line.tab=="Class" or line.tab==specs[spec+1].key then line:Show() else line:Hide() end
        end
        tree.label:SetText("通用 / Class                                      "..specs[spec+1].name.." · 左键加点，右键撤销未保存点数 / Left +, Right undo draft")
    end
    refresh()
end
local function create()
    frame=CreateFrame("Frame","RebornWDBotTalentPanel",UIParent)
    frame:SetSize(1320,820);frame:SetPoint("CENTER");frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true);frame:SetClampedToScreen(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self)self:StartMoving()end)
    frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing()end)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16})
    frame:SetBackdropColor(.015,.025,.035,.98)
    frame:SetScale(math.min(1,(UIParent:GetWidth()-50)/1320,(UIParent:GetHeight()-70)/820))
    title=text(frame,"",26,-14,1070,"GameFontNormalLarge")
    budget=text(frame,"",26,-49,1260)
    button(frame,"×",1274,-7,30,function()frame:Hide()end)
    button(frame,"−",1197,-7,30,function()frame:SetScale(math.max(.45,frame:GetScale()-.05))end)
    button(frame,"+",1233,-7,30,function()frame:SetScale(math.min(1.3,frame:GetScale()+.05))end)
    for i=1,3 do
        local slot=i-1
        slots[i]=button(frame,"",26+(i-1)*220,-80,212,function()
            if M.loaded and slot==M.unlocked then M.QuoteUnlock() else M.SelectSlot(slot);refresh() end
        end)
        slots[i]:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText("方案 / Build "..i)
            GameTooltip:AddLine("已解锁：点击切换浏览。下一个锁定槽：点击获取服务器报价。\nUnlocked: select it. Next locked slot: request a server quote.",1,1,1,true)
            GameTooltip:Show()
        end)
        slots[i]:SetScript("OnLeave",function()GameTooltip:Hide()end)
    end
    button(frame,"三系首页 / Specs",700,-80,190,function()view(nil)end)
    button(frame,"刷新 / Refresh",900,-80,170,function()M.Query()end)
    discard=button(frame,"撤销草稿 / Discard",1080,-80,212,function()if not M.pending then M.ResetDraft()end end)
    home=CreateFrame("Frame",nil,frame);home:SetPoint("TOPLEFT",16,-118);home:SetSize(1288,570)
    local bg=home:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(home);atlas(bg,"spec-background")
    for i,sp in ipairs(specs) do
        local c=CreateFrame("Frame",nil,home);c:SetPoint("TOPLEFT",(i-1)*428,0);c:SetSize(428,570);c:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8})
        local image=c:CreateTexture(nil,"ARTWORK");image:SetPoint("TOPLEFT",43,-36);image:SetSize(342,207)
        atlas(image,"spec-thumbnail-witchdoctor-"..sp.key:lower())
        text(c,sp.name,42,-266,345,"GameFontNormalLarge")
        text(c,sp.role,42,-306,345)
        c.state=text(c,"",42,-360,345)
        text(c,"选择卡片只浏览；绑定与保存需另行确认。\nSelecting a card previews its tree. Bind and save separately.",42,-406,345)
        local index=i-1;c.view=button(c,"查看天赋 / View talents",42,-490,345,function()view(index)end)
        cards[i]=c
    end
    tree=CreateFrame("Frame",nil,frame);tree:SetPoint("TOPLEFT",16,-118);tree:SetSize(1288,570)
    tree.bg=tree:CreateTexture(nil,"BACKGROUND");tree.bg:SetAllPoints(tree);tree.bg:SetAlpha(.45)
    tree.label=text(tree,"",20,-5,1240)
    -- MBWD2D: legacy OnLoad and wheel scripts resolve $parentScrollBar
    -- through self:GetName(). An anonymous templated ScrollFrame is invalid.
    local scroll=CreateFrame("ScrollFrame","RebornWDBotTalentScroll",tree,"UIPanelScrollFrameTemplate")
    tree.scroll=scroll
    local function wheel(_,delta)
        local bar=scroll.ScrollBar or _G[scroll:GetName().."ScrollBar"]
        if not bar then return end
        local low,high=bar:GetMinMaxValues()
        bar:SetValue(math.max(low,math.min(high,bar:GetValue()-delta*64)))
    end
    scroll:EnableMouseWheel(true);scroll:SetScript("OnMouseWheel",wheel)
    tree:EnableMouseWheel(true);tree:SetScript("OnMouseWheel",wheel)
    scroll:SetPoint("TOPLEFT",10,-32);scroll:SetSize(1244,522)
    local content=CreateFrame("Frame",nil,scroll);content:SetSize(1244,900);scroll:SetScrollChild(content)
    content:EnableMouseWheel(true);content:SetScript("OnMouseWheel",wheel)
    local maxRow=0
    local byCell,byID={},{}
    local function cell(n)return n.Tab..":"..(n.PositionX or 0)..":"..(n.PositionY or 0)end
    for _,n in ipairs(RebornWDTreeData)do
        local k=cell(n);byCell[k]=byCell[k] or {};table.insert(byCell[k],n.ID)
    end
    for _,n in ipairs(RebornWDTreeData) do
        local b=CreateFrame("Button",nil,content);b.node=n
        local base=n.Tab=="Class" and 10 or 632
        local group=byCell[cell(n)];local size=#group>1 and 24 or 36
        local order=1;for i,id in ipairs(group)do if id==n.ID then order=i end end
        local offset=#group>1 and (6+(order-(#group+1)/2)*26) or 0
        b.cx=base+(n.PositionX or 0)*51+offset+size/2
        b.cy=12+(n.PositionY or 0)*64+18
        b:SetPoint("TOPLEFT",b.cx-size/2,-b.cy+size/2);b:SetSize(size,size)
        byID[n.ID]=b
        maxRow=math.max(maxRow,n.PositionY or 0)
        b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetAllPoints(b);b.icon:SetTexture(n.Icon or n.IconSource)
        b.border=b:CreateTexture(nil,"OVERLAY");b.border:SetTexture("Interface\\Buttons\\UI-Quickslot2");b.border:SetPoint("CENTER");b.border:SetSize(size+18,size+18)
        b.rank=text(b,"",0,-size,size+5,"GameFontNormalSmall")
        b:RegisterForClicks("LeftButtonUp","RightButtonUp")
        b:EnableMouseWheel(true);b:SetScript("OnMouseWheel",wheel)
        b:SetScript("OnClick",function(_,mouse)M.SetNode(n.ID,mouse=="RightButton" and -1 or 1)end)
        b:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            local p=RebornWDProgress and RebornWDProgress.nodes[n.ID]
            GameTooltip:SetText((p and p.name or n.Name).." / "..n.Name)
            GameTooltip:AddLine("对象 / Bot: "..(M.name or ""),.3,.8,1)
            GameTooltip:AddLine("已保存 / Saved: "..(M.loaded and M.AERank(n.ID,M.aeMasks[M.slot+1]) or 0).."  草稿 / Draft: "..(M.loaded and M.AERank(n.ID) or 0),1,1,1)
            GameTooltip:AddLine("AE "..(n.AECost or 0).."  TE "..(n.TECost or 0).."  节点 / Node "..n.ID,1,.82,0)
            GameTooltip:AddLine(RebornWDNodeLayout.index[n.ID] and "左键加点，右键撤销未保存点数；服务端最终校验。 / Left +, right undo draft; server validates." or "此节点尚未开放 / Node not enabled.",.8,.8,.8,true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function()GameTooltip:Hide()end)
        nodes[#nodes+1]=b
    end
    local function segment(tab,x,y,w,h)
        local line=content:CreateTexture(nil,"BACKGROUND");line.tab=tab
        line:SetTexture("Interface\\Buttons\\WHITE8X8");line:SetVertexColor(.6,.52,.29,.65)
        line:SetPoint("TOPLEFT",x,-y);line:SetSize(math.max(2,w),math.max(2,h));links[#links+1]=line
    end
    for _,b in ipairs(nodes)do
        for _,id in ipairs(b.node.ConnectedNodes or {})do
            local other=byID[id]
            if other and other.node.Tab==b.node.Tab then
                segment(b.node.Tab,math.min(b.cx,other.cx),b.cy,math.abs(other.cx-b.cx),2)
                segment(b.node.Tab,other.cx,math.min(b.cy,other.cy),2,math.abs(other.cy-b.cy))
            end
        end
    end
    content:SetHeight((maxRow+2)*64)
    join=button(frame,"启用系统 / Enroll",25,-704,220,function()M.Join()end)
    bind=button(frame,"绑定所选专精 / Bind spec",255,-704,260,function()
        StaticPopupDialogs.REBORN_WDBOT_BIND={text="将 %s 的当前保存槽绑定为 %s？之后改专精需要重置。 / Bind this bot build? Changing it later requires a reset.",button1=YES,button2=NO,timeout=30,hideOnEscape=true,
            OnAccept=function(_,data) if data and data.guid==M.guid and data.revision==M.revision and data.slot==M.slot and data.spec==M.spec then M.Bind() end end}
        StaticPopup_Show("REBORN_WDBOT_BIND",M.name,specs[M.spec+1].name,{guid=M.guid,revision=M.revision,slot=M.slot,spec=M.spec})
    end)
    save=button(frame,"保存机器人加点 / Save",525,-704,255,function()M.Save()end)
    activate=button(frame,"激活本方案 / Activate",790,-704,250,function()M.Activate()end)
    reset=button(frame,"重置方案 / Reset build",1050,-704,242,function()M.QuoteReset()end)
    unlock=button(frame,"解锁方案 / Unlock build",1050,-744,242,function()M.QuoteUnlock()end)
    save.role="primary";activate.role="primary";reset.role="danger";unlock.role="purchase"
    button(frame,"推荐 / Recommend",25,-665,200,function()if RebornTalentGuide and RebornTalentGuide.BotRecommendations then RebornTalentGuide.BotRecommendations.Open(M.name)end end)
    text(frame,"本人天赋独立 · 机器人自身金币 / 所属账号DP、VP · 确认前先核对报价\nOwn talents are separate. Gold: bot character. DP/VP: bot account. Confirm before paying.",25,-745,1000,"GameFontNormalSmall")
    status=text(frame,"",25,-784,1260,"GameFontNormalSmall")
    frame:SetScript("OnHide",function()M.CancelQuote()end)
    UISpecialFrames[#UISpecialFrames+1]="RebornWDBotTalentPanel"
    frame:Hide()
end
function M.ShowQuote(q)
    if not frame or not frame:IsShown() then M.CancelQuote();M.Message("面板已关闭，请重开后重新询价 / Panel closed; reopen and request a new quote.");return end
    local action=q.kind=="reset" and "重置 / Reset" or "永久解锁 / Permanently unlock"
    local effect=q.kind=="reset" and "清空此方案的专精与全部已保存点数；其他方案保留。\nClears this build's specialization and saved points; other builds are kept." or
        "一次性购买，之后切换免费；不重置或激活已有方案。\nOne-time purchase; switching is free. Existing builds are not reset or activated."
    local label=action.." "..q.name.." · 方案 / Build "..(q.slot+1).."？\n"..
        "费用 / Cost: "..q.gold.."g\n"..
        "支付者 / Payer: "..q.name.."（机器人自身金币 / bot's own gold）\n"..
        "报价时机器人余额 / Bot balance at quote: "..coins(q.balance).."\n"..
        (q.level and ("需要机器人等级 / Required bot level: "..q.level.."\n") or "")..effect..
        "\n报价55秒后失效；不会自动重发。 / Expires in 55 seconds; no automatic retry."
    StaticPopupDialogs.REBORN_WDBOT_PAY={text=label,button1="确认支付 / Confirm",button2="取消 / Cancel",timeout=55,
        whileDead=false,hideOnEscape=true,
        OnAccept=function(_,data) if frame:IsShown() then M.ConfirmQuote(data) end end,
        OnCancel=function(_,data) if M.quote==data then M.CancelQuote() end end}
    StaticPopup_Show("REBORN_WDBOT_PAY",nil,nil,q)
end
M.changed=refresh
function M.ShowPanel()if frame then frame:Show();view(M.spec)end end
function M.Open(unit,name)
    if not frame then create() end
    if frame:IsShown() and M.guid==UnitGUID(unit) then frame:Hide();return end
    if M.guid and M.guid==UnitGUID(unit) then
        frame:Show();view(nil);if not M.pending then M.Query() end;return
    end
    if not M.Begin(unit,name) then return end
    -- Self windows are visually closed, but their independent drafts are untouched.
    if RebornWDTreePreview then RebornWDTreePreview:Hide() end
    if RebornWDSpecHome then RebornWDSpecHome:Hide() end
    frame:Show();view(nil);M.Query()
end
