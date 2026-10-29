-- MBWD3B: activate an existing bot build through the original owned-bot API.
-- Browsing, selecting and confirming are separate. No allocation or purchases.
local M=RebornWDBotTalents
local frame,title,note,status,details,refreshButton
local buttons={}
local focusGuid,focusName,filter,generation=nil,nil,nil,0
local observedNonce,lastSync=nil,-100
local observers=setmetatable({},{__mode="v"})
local specs={"巫毒 / Voodoo","酿造 / Brewing","暗影狩猎 / Shadowhunting"}
local icons={"spell_shadow_shadowbolt","spell_nature_healingwavegreater","ability_hunter_aimedshot"}
local function matching()return M.guid==focusGuid and M.name==focusName and M.ContextValid()end
local function fresh()return M.loaded and M.layoutReady and M.modern and GetTime()-lastSync<30 and M.ContextValid()end
local function suitable(spec)return filter=="heal" and spec==1 or filter=="dps" and (spec==0 or spec==2)end
local function allowed(slot)
    return matching() and fresh() and not M.pending and not M.HasDrafts() and not InCombatLockdown() and
        slot<M.unlocked and slot~=M.active and suitable(M.specs[slot+1])
end
local function enabled(button,on)if on then button:Enable()else button:Disable()end end
local function paintObservers()
    for name,f in pairs(observers)do
        local book=f.frames and f.frames.WDGuide
        local known=fresh() and name==M.name
        local spec=known and M.specs[M.active+1]
        for _,key in ipairs({"DPS","Heal"})do
            local b=book and book.buttons and book.buttons[key]
            if b then
                b.setDisable()
                if known and (key=="Heal" and spec==1 or key=="DPS" and (spec==0 or spec==2))then b.setEnable()end
                b.tip="|cffffd100"..(key=="Heal"and "治疗方案 / Healing build"or "输出方案 / DPS build").."|r\n"..
                    "左键读取已保存方案，选择后确认激活。 / Read saved builds; choose and confirm activation.\n"..
                    (known and ("服务器已同步 / Synced: "..(specs[spec+1]or "未绑定 / Unbound"))or "状态未读取或已过期 / State unknown or expired")..
                    "\n不会自动加点、重置或购买。 / No automatic allocation, reset or purchase."
            end
        end
    end
end
local function paint()
    if M.loaded and not M.pending and M.nonce~=observedNonce then observedNonce=M.nonce;lastSync=GetTime()end
    paintObservers()
    if not frame then return end
    title:SetText((filter=="heal"and "治疗方案 / Healing builds — "or "输出方案 / DPS builds — ")..(focusName or ""))
    local good=matching() and fresh()
    local count=0
    for i,b in ipairs(buttons)do
        local slot=i-1;local sp=good and M.specs[i]
        local text="方案 / Build "..i
        if not good then text=text.." — 等待同步 / Waiting for state"
        elseif slot>=M.unlocked then text=text.." — 未解锁 / Locked"
        else
            text=text.." — "..(specs[sp+1]or "未绑定 / Unbound")
            if suitable(sp)then count=count+1 end
            if slot==M.active then text=text.."  ★ 已激活 / Active"
            elseif not suitable(sp)then text=text.."\n不属于当前用途 / Does not match this role"end
        end
        b:SetText(text);b.icon:SetTexture("Interface\\Icons\\"..(icons[(sp or 3)+1]or "inv_misc_questionmark"))
        enabled(b,allowed(slot))
    end
    note:SetText(good and count==0 and "没有对应的已保存方案，请先到天赋大面板配置。\nNo matching saved build. Configure and save one in the talent panel."or
        "这里只切换已保存天赋；战斗/支援开关另行控制。\nSwitches saved talents only; combat/support toggles remain separate.")
    status:SetText(matching()and (M.message or "")or "对象已改变或离队，请关闭重开。 / Bot changed or unavailable; reopen.")
    enabled(details,not M.pending and matching())
    enabled(refreshButton,not M.pending and matching() and not M.HasDrafts())
end
local function activate(slot)
    if not allowed(slot)then M.Message("请脱战、保存或撤销草稿并刷新后再选择。 / Leave combat, resolve drafts and refresh first.");return end
    local data={guid=focusGuid,name=focusName,generation=generation,revision=M.revision,slot=slot,spec=M.specs[slot+1]}
    StaticPopupDialogs.REBORN_WDBOT_ROLE_SWITCH={
        text="将 %s 切换到 %s？\n仅激活已保存方案；不会重置、购买或自动加点。\nActivate this saved build? No reset, purchase or automatic allocation.",
        button1="确认切换 / Confirm",button2="取消 / Cancel",timeout=30,hideOnEscape=true,whileDead=false,
        OnAccept=function(_,d)
            if not d or not frame:IsShown() or generation~=d.generation or focusGuid~=d.guid or M.guid~=d.guid or
                M.name~=d.name or M.revision~=d.revision or M.specs[d.slot+1]~=d.spec or not allowed(d.slot)then
                M.Message("方案或对象已变化，请刷新重选。 / Build or bot changed; refresh and select again.");return
            end
            M.SelectSlot(d.slot)
            M.Activate() -- original GUID/nonce/owner/revision validation remains authoritative
        end}
    StaticPopup_Show("REBORN_WDBOT_ROLE_SWITCH",focusName,"方案 / Build "..(slot+1).." · "..specs[data.spec+1],data)
end
local function create()
    frame=CreateFrame("Frame","RebornWDBotRolePanel",UIParent)
    frame:SetSize(600,390);frame:SetFrameStrata("DIALOG");frame:SetClampedToScreen(true)
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
    local saved=type(RebornWDBotRolePosition)=="table"and RebornWDBotRolePosition or {}
    frame:SetScale(math.max(.65,math.min(1.25,tonumber(saved.scale)or 1)))
    local anchors={CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    frame:SetPoint(anchors[saved.point]and saved.point or "CENTER",UIParent,
        anchors[saved.relativePoint]and saved.relativePoint or "CENTER",tonumber(saved.x)or 0,tonumber(saved.y)or 0)
    local function savePosition()
        local point,_,relativePoint,x,y=frame:GetPoint(1)
        RebornWDBotRolePosition={point=point,relativePoint=relativePoint,x=x,y=y,scale=frame:GetScale()}
    end
    frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self)self:StartMoving()end)
    frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing();savePosition()end)
    local function text(y,height)
        local t=frame:CreateFontString(nil,"OVERLAY","GameFontNormal");t:SetPoint("TOPLEFT",18,y);t:SetSize(564,height);t:SetJustifyH("LEFT");return t
    end
    local function button(label,x,y,w,callback)
        local b=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,27);b:SetText(label);b:SetScript("OnClick",callback);return b
    end
    title=text(-12,25)
    button("×",562,-10,25,function()frame:Hide()end)
    for i=1,3 do
        local slot=i-1
        local b=button("",62,-48-(i-1)*61,514,function()activate(slot)end);b:SetHeight(52)
        b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetPoint("RIGHT",b,"LEFT",-7,0);b.icon:SetSize(32,32)
        buttons[i]=b
    end
    note=text(-236,42)
    details=button("配置天赋 / Edit talents",18,-286,230,function()
        if M.pending or not matching()then return end
        local unit=MultiBot and MultiBot.toUnit and MultiBot.toUnit(focusName)
        if not unit then return end
        frame:Hide();M.Open(unit,focusName)
    end)
    refreshButton=button("刷新 / Refresh",260,-286,150,function()if not M.pending and matching()and not M.HasDrafts()then M.Query()end end)
    for i,delta in ipairs({-.05,.05})do
        button(delta<0 and "−"or "+",422+(i-1)*40,-286,32,function()
            frame:SetScale(math.max(.65,math.min(1.25,frame:GetScale()+delta)));savePosition()
        end)
    end
    status=text(-326,48)
    frame:SetScript("OnHide",function()StaticPopup_Hide("REBORN_WDBOT_ROLE_SWITCH")end)
    local elapsed=0
    frame:SetScript("OnUpdate",function(_,dt)elapsed=elapsed+dt;if elapsed>=.5 then elapsed=0;paint()end end)
    UISpecialFrames[#UISpecialFrames+1]="RebornWDBotRolePanel"
    frame:Hide()
end
function M.OpenRole(unit,name,role)
    if role~="heal"and role~="dps"then return false end
    if M.pending or M.HasDrafts()then M.Message("请先完成当前请求，保存或撤销草稿。 / Finish the request and resolve drafts first.");return false end
    if not M.Begin(unit,name)then return false end
    if not frame then create()end
    generation=generation+1;focusGuid=M.guid;focusName=M.name;filter=role;lastSync=-100
    StaticPopup_Hide("REBORN_WDBOT_ROLE_SWITCH")
    if RebornWDBotTalentPanel then RebornWDBotTalentPanel:Hide()end
    frame:Show();paint();M.Query();return true
end
function M.RegisterRoleObserver(f)observers[f.name]=f;paintObservers()end
local previous=M.changed
M.changed=function()if previous then previous()end;paint()end
-- The picker may be hidden while the strategy book remains open.
local watcher=CreateFrame("Frame","RebornWDBotRoleEvents")
local elapsed=0
watcher:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt;if elapsed>=.5 then elapsed=0;paintObservers()end
end)
