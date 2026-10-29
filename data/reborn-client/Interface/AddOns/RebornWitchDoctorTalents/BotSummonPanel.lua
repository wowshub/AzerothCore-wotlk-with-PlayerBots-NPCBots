-- MBWD4A: owned-bot summon snapshots and explicit, non-retried manual casts.
local S={pending=false,loaded=false,rows={}}
RebornWDBotSummons=S
local bases={9003160,9003170,9003370,9003440,9004080,9003580,9003673,9003420}
local names={"蛇卫 / Serpent Ward","治疗守卫 / Healing Ward","法力神像 / Mana Idol","净化神像 / Cleansing Idol",
    "群蛇召唤 / Mass Serpents","大巫毒 / Big Bad Voodoo","拟态守卫 / Mimic","反施法雕像 / Spell Effigy"}
local reasons={ready="基础条件就绪 / Ready for native checks",unlearned="尚未学会 / Not learned",replacement="当前替换暂不支持 / Unsupported override",
    data="缺少技能数据 / Missing spell data",dead="角色已死亡 / Dead",unsafe="当前无法操作 / Unavailable",job="自动配置进行中 / Build job running",
    busy="正在施法 / Casting",cooldown="技能冷却中 / Cooldown",gcd="公共冷却中 / Global cooldown",resource="资源不足 / Not enough power",
    moving="移动中 / Moving",changed="技能或替换已变化 / Spell changed",duplicate="重复请求已拒绝 / Duplicate request"}
local frame,title,summary,status
local preferenceView
local cards={}
local sequence=math.floor(GetTime()*1000)%2000000000
local generation=0
local function context()
    local u=MultiBot and MultiBot.toUnit and MultiBot.toUnit(S.name)
    return u and UnitExists(u)and UnitGUID(u)==S.guid
end
local function fresh()return S.loaded and context()and GetTime()-S.updated<15 end
local function canCast(key)
    local r=S.rows[key]
    return fresh()and not S.pending and r and r.spell>0 and r.reason=="ready"
end
local function paint()
    if not frame then return end
    title:SetText("守卫与召唤 / Wards & Summons — "..(S.name or ""))
    local h=S.header
    summary:SetText(h and ("上次同步 / Last sync:  "..h.mana.." / "..h.maxMana.." 法力 / Mana\n"..
        "占槽 / Slots: 守卫 "..h.ward.."  神像 "..h.idol.."  雕像 "..h.effigy..
        "  群蛇数量 / Serpents "..h.mass.."  拟态 / Mimic "..(h.mimic==1 and "有"or "无").."  眼镜蛇 / Viper "..(h.viper==1 and "有"or "无"))or "等待服务器状态 / Waiting for server state")
    for key,c in ipairs(cards)do
        local r=S.rows[key];local spell=r and r.spell
        c.name:SetText(key==5 and spell==9004182 and "眼镜蛇守卫 / Viper Ward"or names[key])
        local icon=spell and spell>0 and GetSpellInfo and select(3,GetSpellInfo(spell))
        c.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local text=r and (reasons[r.reason]or r.reason)or "尚未读取 / Unknown"
        if r then
            local left=math.max(0,math.max(r.cooldown,r.gcd)-(GetTime()-(S.updated or GetTime()))*1000)
            if left==0 and (r.reason=="cooldown"or r.reason=="gcd")then text="计时结束，请刷新 / Timer elapsed; refresh"end
            text=text.."\n消耗 / Cost "..r.cost.."  剩余 / CD "..math.ceil(left/1000).."s"
        end
        if not fresh()then text=S.pending and "正在读取 / Waiting..."or "状态过期，请刷新 / Refresh state"end
        c.info:SetText(text)
        if canCast(key)then c.cast:Enable()else c.cast:Disable()end
    end
    status:SetText(S.message or "")
end
local function request(op,key,spell)
    if S.pending then return false end
    if not context()then S.loaded=false;S.message="机器人离队或身份改变，请重开。 / Bot unavailable; reopen.";paint();return false end
    sequence=sequence%2147483646+1;S.nonce=sequence;S.pending=true;S.sent=GetTime();S.operation=op;S.buffer=nil;S.ack=nil
    S.message="等待服务端确认；不自动重发。 / Waiting for server; no automatic retry."
    paint()
    SendChatMessage((op=="cast"and ".wdwardcast "or ".wdwardstate ")..S.id.." "..S.nonce..
        (op=="cast"and (" "..key.." "..spell)or ""),"SAY")
    return true
end
function S.Refresh()
    if StaticPopup_Hide then StaticPopup_Hide("REBORN_WDBOT_SUMMON")end
    return request("state")
end
local function confirm(key)
    if not canCast(key)then S.message="请刷新并核对技能状态。 / Refresh and check readiness.";paint();return end
    local r=S.rows[key]
    local data={guid=S.guid,key=key,spell=r.spell,nonce=S.nonce,generation=generation}
    StaticPopupDialogs.REBORN_WDBOT_SUMMON={
        text="让 %s 手动施放 %s？\n按原技能消耗资源和冷却，可能替换已有同类召唤槽。大巫毒仍受原移动限制。\nManual cast uses native costs/cooldowns and may replace an occupied slot. Big Bad Voodoo keeps native movement restrictions.",
        button1="确认施放 / Cast",button2="取消 / Cancel",timeout=15,hideOnEscape=true,
        OnAccept=function(_,d)
            if not d or not frame:IsShown()or d.generation~=generation or d.guid~=S.guid or d.nonce~=S.nonce or
                not canCast(d.key)or S.rows[d.key].spell~=d.spell then
                S.message="对象或状态已变化，请刷新重选。 / Context changed; refresh and choose again.";paint();return
            end
            request("cast",d.key,d.spell)
        end}
    StaticPopup_Show("REBORN_WDBOT_SUMMON",S.name,names[key],data)
end
local function create()
    frame=CreateFrame("Frame","RebornWDBotSummonPanel",UIParent);frame:SetSize(750,555);frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    local saved=type(RebornWDBotSummonPosition)=="table"and RebornWDBotSummonPosition or {}
    local anchors={CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    frame:SetScale(math.max(.65,math.min(1.25,tonumber(saved.scale)or 1)))
    frame:SetPoint(anchors[saved.point]and saved.point or "CENTER",UIParent,anchors[saved.relativePoint]and saved.relativePoint or "CENTER",tonumber(saved.x)or 0,tonumber(saved.y)or 0)
    local function save()
        local p,_,rp,x,y=frame:GetPoint(1);RebornWDBotSummonPosition={point=p,relativePoint=rp,x=x,y=y,scale=frame:GetScale()}
    end
    frame:SetScript("OnDragStart",function(self)self:StartMoving()end)
    frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing();save()end)
    local function text(parent,x,y,w,h)
        local t=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");t:SetPoint("TOPLEFT",x,y);t:SetSize(w,h);t:SetJustifyH("LEFT");return t
    end
    local function button(parent,label,x,y,w,fn)
        local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,24);b:SetText(label);b:SetScript("OnClick",fn);return b
    end
    title=text(frame,18,-12,520,25);summary=text(frame,18,-44,714,46)
    button(frame,"刷新 / Refresh",535,-12,120,S.Refresh)
    button(frame,"×",705,-12,26,function()frame:Hide()end)
    for i,delta in ipairs({-.05,.05})do button(frame,delta<0 and "−"or "+",660+(i-1)*21,-12,20,function()
        frame:SetScale(math.max(.65,math.min(1.25,frame:GetScale()+delta)));save()
    end)end
    for key=1,8 do
        local k=key
        local c=CreateFrame("Frame",nil,frame);c:SetPoint("TOPLEFT",18+((key-1)%2)*357,-98-math.floor((key-1)/2)*95);c:SetSize(342,88)
        c:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10})
        c:SetBackdropColor(.055,.10,.12,.95)
        c.icon=c:CreateTexture(nil,"ARTWORK");c.icon:SetPoint("TOPLEFT",8,-13);c.icon:SetSize(34,34)
        c.name=text(c,50,-5,284,26);c.info=text(c,50,-32,284,40)
        c.cast=button(c,"施放 / Cast",244,-62,86,function()confirm(k)end)
        cards[key]=c
    end
    status=text(frame,18,-490,462,30)
    button(frame,"AI原因 / Why",18,-524,160,function()
        local unit=MultiBot and MultiBot.toUnit and MultiBot.toUnit(S.name)
        if unit and RebornWDBotDecision then RebornWDBotDecision.Open(unit,S.name) end
    end)
    frame:SetScript("OnHide",function()StaticPopup_Hide("REBORN_WDBOT_SUMMON")end)
    UISpecialFrames[#UISpecialFrames+1]="RebornWDBotSummonPanel";frame:Hide()
end
local function attachPreferences()
    local controller=MultiBot and MultiBot.WDAutoSummons
    if not controller then return end
    if not preferenceView then
        local view={buttons={}}
        function view:IsShown()return frame:IsShown()end
        view.addButton=function(key,_,_,icon)
            if view.buttons[key]then return view.buttons[key]end
            local b=CreateFrame("Button",nil,frame);view.buttons[key]=b
            b:SetPoint("TOPLEFT",key=="WDAutoWards"and 500 or 615,-494);b:SetSize(100,38)
            b:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square","ADD")
            b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetPoint("TOPLEFT",3,-8);b.icon:SetSize(22,22);b.icon:SetTexture("Interface\\Icons\\"..icon)
            b.label=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");b.label:SetPoint("TOPLEFT",28,-2);b.label:SetSize(70,34)
            b.label:SetText(key=="WDAutoWards"and "自动守卫\nAuto slots"or "大型召唤\nMajor")
            b.setEnable=function()b.icon:SetDesaturated(false);b.label:SetTextColor(.3,1,.4);return b end
            b.setDisable=function()b.icon:SetDesaturated(true);b.label:SetTextColor(.65,.65,.65);return b end
            b:SetScript("OnClick",function()if b.doLeft then b.doLeft(b)end end)
            b:SetScript("OnEnter",function(self)GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(self.tip or "");GameTooltip:Show()end)
            b:SetScript("OnLeave",function()GameTooltip:Hide()end)
            return b
        end
        preferenceView=view
    end
    preferenceView.name=S.name
    controller.Attach(preferenceView)
end
function S.Open(unit,name)
    if S.pending then S.message="请等待当前请求。 / Wait for the pending request.";paint();return false end
    local guid=unit and UnitExists(unit)and UnitGUID(unit)
    local suffix=type(guid)=="string"and guid:match("^0x00000000(%x%x%x%x%x%x%x%x)$")
    local id=suffix and tonumber(suffix,16)
    if not id or id==0 or guid==UnitGUID("player")then return false end
    if not frame then create()end
    if frame:IsShown()and S.guid==guid then frame:Hide();return true end
    generation=generation+1;S.guid=guid;S.id=id;S.name=name;S.rows={};S.header=nil;S.loaded=false;S.updated=0
    frame:Show();attachPreferences();return S.Refresh()
end
local function fields(payload)
    local out={};for v in (payload.."|"):gmatch("(.-)|")do out[#out+1]=v end;return out
end
local function number(value,low,high)
    local n=tonumber(value);if n and n==math.floor(n)and n>=low and n<=high then return n end
end
function S.Receive(message)
    if type(message)~="string"then return false end
    local id,nonce,payload=message:match("^WDWS4|(%d+)|(%d+)|(.+)$")
    if not id or not S.pending or tonumber(id)~=S.id or tonumber(nonce)~=S.nonce then return false end
    if not context()then S.pending=false;S.loaded=false;S.message="机器人身份改变，请重开。 / Bot identity changed.";paint();return true end
    local f=fields(payload)
    if f[1]=="ERROR"then S.pending=false;S.loaded=false;S.message="请求未确认 / Request unconfirmed: "..(reasons[f[2]]or f[2]or "error");paint();return true end
    if f[1]=="ACK"then
        if #f==3 and (f[2]=="accepted"or f[2]=="native"or f[2]=="rejected")then S.ack={kind=f[2],reason=f[3]}end
        return true
    end
    if f[1]=="BEGIN"then
        if #f~=12 or f[2]~="1"or f[3]~="8"then return true end
        local nums={};for i=4,12 do nums[i]=number(f[i],0,4294967295);if not nums[i]then return true end end
        for _,i in ipairs({4,7,8,9,11,12})do if nums[i]>1 then return true end end
        S.buffer={rows={},count=0,header={mana=nums[5],maxMana=nums[6],ward=nums[7],idol=nums[8],effigy=nums[9],mass=nums[10],mimic=nums[11],viper=nums[12]}}
    elseif f[1]=="ROW"and S.buffer then
        local key=number(f[2],1,8);local base=number(f[3],1,4294967295);local spell=number(f[4],0,4294967295)
        local cost=number(f[5],0,2147483647);local power=number(f[6],-2,8);local cd=number(f[7],0,4294967295);local gcd=number(f[8],0,4294967295)
        if #f~=9 or not key or base~=bases[key]or not spell or not cost or not power or not cd or not gcd or not reasons[f[9]]or S.buffer.rows[key]then return true end
        S.buffer.rows[key]={spell=spell,cost=cost,power=power,cooldown=cd,gcd=gcd,reason=f[9]};S.buffer.count=S.buffer.count+1
    elseif f[1]=="END"and #f==1 and S.buffer and S.buffer.count==8 then
        S.rows=S.buffer.rows;S.header=S.buffer.header;S.buffer=nil;S.pending=false;S.loaded=true;S.updated=GetTime()
        if S.operation=="cast"then
            S.message=S.ack and S.ack.kind=="accepted"and "施法请求已接受，请刷新确认召唤物。 / Cast accepted; refresh to verify summons."or
                ("施放结果 / Cast result: "..(S.ack and (reasons[S.ack.reason]or S.ack.reason)or "未确认 / Unconfirmed"))
        else S.message="状态已同步。手动施放不受自动净化开关限制，仍按原技能规则。 / Synced. Manual casts retain native costs and rules."end
        paint()
    end
    return true
end
local events=CreateFrame("Frame","RebornWDBotSummonEvents");events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent",function(_,_,message)S.Receive(message)end)
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
    if S.pending and GetTime()-S.sent>=8 then S.pending=false;S.loaded=false;S.buffer=nil;S.message="请求超时，请刷新核对；未重发施放。 / Timed out; refresh. Cast not retried."end
    if frame and frame:IsShown()then paint()end
end)
if ChatFrame_AddMessageEventFilter then ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,message)
    return type(message)=="string"and message:match("^WDWS4|")~=nil
end)end
