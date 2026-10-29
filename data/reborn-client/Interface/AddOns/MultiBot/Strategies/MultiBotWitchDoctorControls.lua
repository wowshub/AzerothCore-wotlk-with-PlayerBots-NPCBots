-- MBWD3A: native WD preferences, independent from generic strategies and talents.
-- Only an authenticated server reply changes the displayed confirmed mask.
local C={}
MultiBot.WDControls=C
local rows={}
local sequence=math.floor(GetTime()*1000)%2000000000
local function identity(name)
    local unit=MultiBot.toUnit and MultiBot.toUnit(name)
    if not unit or not UnitExists(unit) then return end
    local guid=UnitGUID(unit)
    local suffix=type(guid)=="string" and guid:match("^0x00000000(%x%x%x%x%x%x%x%x)$")
    local id=suffix and tonumber(suffix,16)
    if not id or id==0 or guid==UnitGUID("player") then return end
    return guid,id
end
local entries={
    {key="WDBuffs",bit=1,x=-180,icon="spell_nature_magicimmunity",title="自动巫祝增益 / Automatic Wuju buffs",
     body="控制脱战时自动补巫祝增益。/ Controls native out-of-combat Wuju buffs.\n不会移除已有增益，不影响手动施放。/ Existing buffs and manual casts remain."},
    {key="WDCures",bit=2,x=-210,icon="spell_nature_nullifypoison",title="自动净化 / Automatic cleansing",
     body="控制巫医自动驱散、净化与新放置的净化神像。/ Controls native automatic cures and new cleansing idols.\n不关闭治疗；已有神像和手动施法保留。/ Healing, existing idols and manual casts remain."},
}
local function enabled(mask,bit)return math.floor(mask/bit)%2==1 end
local function paint(row)
    for _,e in ipairs(entries)do
        local b=row.frame.buttons[e.key]
        if b then
            b.setDisable()
            if row.known and enabled(row.mask,e.bit)then b.setEnable()end
            local state=row.known and (enabled(row.mask,e.bit)and "已启用 / Enabled"or "已关闭 / Disabled")or "未读取 / Unknown"
            b.tip="|cffffd100"..e.title.."|r\n"..e.body.."\n"..state..
                "\n"..(row.storage=="persistent" and "服务端偏好已保存，重登保留。/ Saved on server; retained after relog.\n" or
                 row.storage=="unavailable" and "持久化不可用，请先导入3C角色库SQL。/ Storage unavailable; install 3C Characters SQL.\n" or
                 "持久化尚未确认；只显示当前会话状态。/ Persistence unconfirmed; showing session state.\n")..
                (row.pending and "等待服务器确认… / Waiting for server confirmation..."or row.message or "左键切换；亮起以服务器回读为准。/ Click to toggle; light follows server state.")
        end
    end
end
local function valid(row)
    local guid=identity(row.name)
    return guid and guid==row.guid
end
local function request(row,op,args)
    if row.pending then return false end
    if not valid(row)then row.known=false;row.message="已离队或身份改变，请刷新。/ Bot unavailable; refresh.";paint(row);return false end
    sequence=sequence%2147483646+1
    row.storage=nil;row.nonce=sequence;row.pending=true;row.sent=GetTime();row.retry=row.sent+15;row.message=nil
    paint(row)
    SendChatMessage(".wdcontrol "..op.." "..row.id.." "..row.nonce..(args and " "..args or ""),"SAY")
    return true
end
function C.Refresh(name)
    local row=rows[name]
    if not row then return false end
    return request(row,"state")
end
local function toggle(name,bit)
    local row=rows[name]
    if not row or row.pending then return end
    if not row.known or GetTime()-(row.updated or 0)>15 then C.Refresh(name);return end
    local mask=row.mask+(enabled(row.mask,bit)and -bit or bit)
    request(row,"set",row.revision.." "..mask)
end
function C.Attach(frame)
    local name=frame.name
    if type(name)~="string"then return end
    local guid,id=identity(name)
    local row=rows[name]
    if not row or row.guid~=guid then row={name=name,guid=guid,id=id,known=false,retry=0};rows[name]=row end
    row.frame=frame
    for _,e in ipairs(entries)do
        local bit=e.bit
        local b=frame.addButton(e.key,e.x,0,e.icon,"")
        b.doLeft=function()toggle(name,bit)end
    end
    paint(row)
    if guid and not row.pending and (not row.updated or GetTime()-row.updated>=15)then C.Refresh(name)end
end
function C.OnMessage(message)
    if type(message)~="string"then return false end
    local id,nonce,payload=message:match("^WDMB3|(%d+)|(%d+)|(.+)$")
    if not id then return false end
    id=tonumber(id);nonce=tonumber(nonce)
    for _,row in pairs(rows)do
        if row.pending and row.id==id and row.nonce==nonce then
            if not valid(row)then row.pending=false;row.known=false;paint(row);return true end
            local storage=payload:match("^STORE|1|(%a+)$")
            if storage=="persistent" or storage=="unavailable" then row.storage=storage;paint(row);return true end
            local reason=payload:match("^ERROR|([%w_]+)$")
            if reason then
                row.pending=false;row.known=false
                row.message=reason=="storage" and "保存未获确认，请刷新核对并检查角色库SQL。/ Save unconfirmed; refresh and check Characters SQL." or
                    ("读取/设置被拒绝 / Request rejected: "..reason);paint(row);return true
            end
            local version,status,revision,mask=payload:match("^STATE|(%d+)|(%a+)|(%d+)|(%d+)$")
            version=tonumber(version);revision=tonumber(revision);mask=tonumber(mask)
            if version~=1 or not revision or revision>2000000000 or not mask or mask>3 or
                (status~="ok"and status~="stale"and status~="invalid")then return true end
            row.pending=false;row.known=true;row.revision=revision;row.mask=mask;row.updated=GetTime()
            row.message=nil
            if status~="ok"then row.message="状态已变化，请核对后再次点击。/ State changed; review and click again."end
            paint(row);return true
        end
    end
    return false
end
local events=CreateFrame("Frame","MultiBotWitchDoctorControlsEvents")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent",function(_,event,message)if event=="CHAT_MSG_SYSTEM"then C.OnMessage(message)end end)
if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,message)
        return type(message)=="string" and message:match("^WDMB3|")~=nil
    end)
end
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
    local refresh
    for _,row in pairs(rows)do
        if not valid(row)then
            if row.known or row.pending then row.pending=false;row.known=false;paint(row)end
        elseif row.pending and GetTime()-row.sent>=6 then
            row.pending=false;row.known=false
            row.message="确认超时，请刷新核对；不会重发设置。/ Timed out; refresh. Set is never replayed.";paint(row)
        elseif not refresh and not row.pending and row.frame:IsShown() and GetTime()>=(row.retry or 0)then
            refresh=row.name
        end
    end
    if refresh then C.Refresh(refresh)end -- at most one read per tick; never retry a write
end)
