-- WHTAL4A: a local draft is never a learned talent. Only a matching server reply commits it.
RebornWHTalents = {loaded=false,pending=false,revision=0,mask=0,draft=0,level=0,ae=0,te=0,active=false,message="offline"}
local M,D = RebornWHTalents,RebornWHTalentData
M.byID={}; for _,n in ipairs(D.nodes) do M.byID[n.id]=n end
M.byID[7424].cap=0;M.byID[6457].cap=0;M.byID[6415].cap=0 -- unlock only after a validated WHT2 server reply
local bits={[34538]=1,[7451]=2,[6415]=4,[6457]=16,[7424]=32}
local nonce=math.floor((GetTime()*1000)%1000000000)
local function Changed() if M.changed then M.changed() end end
function M.IsHunter() local _,token=UnitClass("player");return token=="WITCHHUNTER" end
function M.GUID() local g=UnitGUID("player");return type(g)=="string" and tonumber(g:sub(-8),16) or nil end
function M.Rank(id,draft) local b=bits[id];if not b then return 0 end;return math.floor((draft and M.draft or M.mask)/b)%(id==6415 and 4 or 2) end
function M.Spent(mask) return mask%2+math.floor(mask/2)%2+math.floor(mask/4)%4+math.floor(mask/16)%2+math.floor(mask/32)%2 end
function M.Dirty() return M.draft~=M.mask end
function M.CanAdd(id)
    local n=M.byID[id]
    return M.loaded and not M.pending and n and n.cap>0 and M.level>=n.level and
        M.Rank(id,true)<n.cap and M.Spent(M.draft)+n.ae<=M.ae
end
function M.Toggle(id)
    local b=bits[id];if not b or not M.loaded or M.pending then return end
    if M.CanAdd(id) then M.draft=M.draft+b
    elseif M.Rank(id,true)>M.Rank(id,false) then M.draft=M.draft-b else return end
    M.message="draft";Changed()
end
function M.CancelDraft() if not M.pending then M.draft=M.mask;M.message="cancelled";Changed() end end
function M.Undo(id)
    local b=bits[id]
    if b and M.loaded and not M.pending and M.Rank(id,true)>M.Rank(id,false) then
        M.draft=M.draft-b;M.message="draft";Changed()
    end
end
local function Request(kind,args)
    if not M.IsHunter() or M.pending then return end
    nonce=nonce%1999999999+1
    M.pending=true;M.nonce=nonce;M.kind=kind;M.sent=GetTime();M.requestMask=M.draft
    M.message="pending";Changed()
    SendChatMessage(".whtalent "..kind.." "..nonce..(args and " "..args or ""),"SAY")
end
function M.Query() Request("state") end
function M.Save()
    if not M.loaded or M.pending or not M.Dirty() then return end
    if InCombatLockdown() then M.message="unsafe";Changed();return end
    if M.draft>59 or M.Spent(M.draft)>M.ae then return end
    Request("save",M.revision.." "..M.draft)
end
function M.Quote()
    if M.loaded and not M.pending and M.mask>0 then Request("quote",tostring(M.revision)) end
end
function M.ConfirmQuote(q)
    if type(q)~="table" or not M.loaded or M.pending or q.revision~=M.revision or q.token~=M.quoteToken then
        M.message="stale";Changed();return
    end
    M.quoteToken=nil;Request("reset",q.revision.." "..q.token)
end
function M.Handle(msg)
    if type(msg)~="string" or not M.pending or not M.IsHunter() then return false end
    local version,n,g,r,mask,l,ae,te,active,loaded,gold,token,status=msg:match("^WHT([1234])|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|([01])|([01])|(%d+)|(%d+)|([a-z]+)$")
    if not status then return false end
    n,g,r,mask,l,ae,te,gold,token=tonumber(n),tonumber(g),tonumber(r),tonumber(mask),tonumber(l),tonumber(ae),tonumber(te),tonumber(gold),tonumber(token)
    version=tonumber(version)
    if n~=M.nonce or g~=M.GUID() or r<M.revision or r>=2000000000 or mask>(version==4 and 59 or version==3 and 27 or version==2 and 11 or 3) or math.floor(mask/4)%4>2 or l>255 or l<1 or gold~=10 or token>2000000000 then return false end
    local budget=D.budget[tostring(math.min(80,l))]
    if not budget or ae~=budget[1] or te~=budget[2] then return false end
    local oldRev,oldMask,oldDraft,kind=M.revision,M.mask,M.draft,M.kind
    M.pending=false;M.nonce=nil;M.kind=nil;M.revision=r;M.mask=mask;M.level=l;M.ae=ae;M.te=te
    M.serverVersion=version;M.byID[7424].cap=version==4 and 1 or 0;M.byID[6457].cap=version>=3 and 1 or 0;M.byID[6415].cap=version>=2 and 2 or 0
    M.loaded=loaded=="1";M.active=active=="1";M.gold=gold;M.message=status
    if status=="saved" or status=="reset" or status=="stale" or r~=oldRev or mask~=oldMask then M.draft=mask
    elseif kind=="state" or status=="database" then M.draft=oldDraft else M.draft=mask end
    if not M.loaded then M.draft=mask end
    Changed()
    if status=="quote" and token>0 then
        M.quoteToken=token
        if M.onQuote then M.onQuote({revision=r,token=token,gold=gold}) end
    end
    return true
end
local listener=CreateFrame("Frame")
listener:RegisterEvent("CHAT_MSG_SYSTEM");listener:RegisterEvent("PLAYER_LOGIN")
listener:SetScript("OnEvent",function(_,event,msg)
    if event=="PLAYER_LOGIN" then
        M.loaded=false;M.pending=false;M.revision=0;M.mask=0;M.draft=0;M.quoteToken=nil;M.serverVersion=nil;M.byID[7424].cap=0;M.byID[6457].cap=0;M.byID[6415].cap=0;M.message="offline";Changed()
    else M.Handle(msg) end
end)
listener:SetScript("OnUpdate",function()
    if M.pending and GetTime()-M.sent>10 then
        M.pending=false;M.loaded=false;M.nonce=nil;M.quoteToken=nil;M.message="timeout";Changed()
    end
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,msg) return type(msg)=="string" and msg:match("^WHT[1234]|")~=nil end)
