-- MBWD4B: automatic summon preferences, independent from WDMB3 and talents.
-- Only an authenticated server reply changes the displayed confirmed mask.
local C={}
MultiBot.WDAutoSummons=C
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
    {key="WDAutoWards",bit=1,x=-270,icon="spell_nature_guardianward",title="自动普通召唤 / Automatic ward slots",
     body="控制三个普通槽，含治疗守卫。\nControls ordinary slots, including Healing Ward.\n直疗、手动施放与已有召唤保留。\nDirect healing, manual casts and existing summons remain.\n净化神像还需自动净化开启。\nCleansing idols also require automatic cleansing."},
    {key="WDAutoLarge",bit=2,x=-300,icon="spell_shadow_summonvoidwalker",title="自动大型召唤 / Automatic major summons",
     body="群蛇/眼镜蛇、拟态、大巫毒、魔像与进攻分身。\nMass wards, Mimic, Voodoo, golem and offensive clones.\n关闭也停止相关应急大巫毒/魔像。\nAlso disables automatic emergency Voodoo/golem.\n幻象脱险、假死、化蛇保留。\nDefensive illusions, feign and Slither remain."},
}

local function enabled(mask,bit)return math.floor(mask/bit)%2==1 end
local function paint(row)
    for view in pairs(row.views or {})do
    for _,e in ipairs(entries)do
        local b=view.buttons[e.key]
        if b then
            b.setDisable()
            if row.known and enabled(row.mask,e.bit)then b.setEnable()end
            local state=row.known and (enabled(row.mask,e.bit)and "已启用 / Enabled"or "已关闭 / Disabled")or "未读取 / Unknown"
            b.tip="|cffffd100"..e.title.."|r\n"..e.body.."\n"..state..
                "\n只影响后续自动决定，不取消已有召唤或读条。\nOnly future automatic decisions change.\n开启仍需原AI条件；手动施放单独确认。\nNative AI conditions still apply; manual casts are separate."..
                "\n"..(row.storage=="persistent" and "服务端偏好已保存，重登保留。/ Saved on server; retained after relog.\n" or
                 row.storage=="unavailable" and "持久化不可用，请先导入4B角色库SQL。/ Storage unavailable; install 4B Characters SQL.\n" or
                 "持久化尚未确认；只显示当前会话状态。/ Persistence unconfirmed; showing session state.\n")..
                (row.pending and "等待服务器确认… / Waiting for server confirmation..."or row.message or "左键切换；亮起以服务器回读为准。/ Click to toggle; light follows server state.")
        end
    end
    end
end
local function visible(row)
    for view in pairs(row.views or {})do if view:IsShown()then return true end end
    return false
end
local function valid(row)
    local guid=identity(row.name)
    return guid and guid==row.guid
end
local function request(row,op,args)
    if row.pending then return false end
    if not valid(row)then row.known=false;row.storage=nil;row.message="已离队或身份改变，请刷新。/ Bot unavailable; refresh.";paint(row);return false end
    sequence=sequence%2147483646+1
    row.storage=nil;row.nonce=sequence;row.pending=true;row.sent=GetTime();row.retry=row.sent+15;row.message=nil
    paint(row)
    SendChatMessage((op=="set" and ".wdautoset " or ".wdautostate ")..row.id.." "..row.nonce..(args and " "..args or ""),"SAY")
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
    if not row or row.guid~=guid then row={name=name,guid=guid,id=id,known=false,retry=0,views=row and row.views};rows[name]=row end
    for oldname,old in pairs(rows)do if oldname~=name and old.views then old.views[frame]=nil end end
    row.views=row.views or setmetatable({},{__mode="k"});row.views[frame]=true
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
    local id,nonce,payload=message:match("^WDAS4|(%d+)|(%d+)|(.+)$")
    if not id then return false end
    id=tonumber(id);nonce=tonumber(nonce)
    for _,row in pairs(rows)do
        if row.pending and row.id==id and row.nonce==nonce then
            if not valid(row)then row.pending=false;row.known=false;row.storage=nil;paint(row);return true end
            local storage=payload:match("^STORE|1|(%a+)$")
            if storage=="persistent" or storage=="unavailable" then row.storage=storage;paint(row);return true end
            local reason=payload:match("^ERROR|([%w_]+)$")
            if reason then
                row.pending=false;row.known=false;row.storage=nil
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
local events=CreateFrame("Frame","MultiBotWitchDoctorAutoSummonEvents")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent",function(_,event,message)if event=="CHAT_MSG_SYSTEM"then C.OnMessage(message)end end)
if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,message)
        return type(message)=="string" and message:match("^WDAS4|")~=nil
    end)
end
local elapsed=0
events:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
    local refresh
    for _,row in pairs(rows)do
        if not valid(row)then
            if row.known or row.pending then row.pending=false;row.known=false;row.storage=nil;paint(row)end
        elseif row.pending and GetTime()-row.sent>=6 then
            row.pending=false;row.known=false;row.storage=nil
            row.message="确认超时，请刷新核对；不会重发设置。/ Timed out; refresh. Set is never replayed.";paint(row)
        elseif not refresh and not row.pending and visible(row) and GetTime()>=(row.retry or 0)then
            refresh=row.name
        end
    end
    if refresh then C.Refresh(refresh)end -- at most one read per tick; never retry a write
end)
