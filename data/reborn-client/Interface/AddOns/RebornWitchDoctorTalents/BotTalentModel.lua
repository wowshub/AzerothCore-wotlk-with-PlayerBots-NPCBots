-- MBWD2A: independent remote model. Never writes RebornWD8 or uses self commands.
local M={loaded=false,pending=false,revision=0,active=0,slot=0,spec=0,specs={3,3,3},aeMasks={},message=""}
RebornWDBotTalents=M
local L=RebornWDNodeLayout
local sequence=math.floor(GetTime()*1000)%2000000000
local function changed() if M.changed then M.changed() end end
function M.Message(text) M.message=text;changed() end
function M.GuidCounter(guid)
    if type(guid)~="string" then return nil end
    local suffix=guid:match("^0x00000000(%x%x%x%x%x%x%x%x)$")
    return suffix and tonumber(suffix,16)
end
function M.ContextValid()
    local u=MultiBot and MultiBot.toUnit and MultiBot.toUnit(M.name)
    return u and UnitExists(u) and UnitGUID(u)==M.guid
end
function M.HasDrafts()
    return M.guid and M.draftAE and M.aeMasks[M.slot+1] and not M.MaskEqual(M.draftAE,M.aeMasks[M.slot+1]) or false
end
function M.CanEdit()
    return M.loaded and M.modern and M.layoutReady and not M.pending and M.slot<M.unlocked and M.specs[M.slot+1]==M.spec and M.ContextValid()
end
function M.ResetDraft() M.draftAE=M.aeMasks[M.slot+1] or M.MaskParse(0);changed() end
function M.CancelQuote()
    M.quote=nil
    if StaticPopup_Hide then StaticPopup_Hide("REBORN_WDBOT_PAY") end
end
function M.Begin(unit,name)
    if M.pending then M.Message("请等待上一操作确认 / Wait for the pending request.");return false end
    if M.HasDrafts() then M.Message("请先保存或撤销草稿 / Save or discard the draft first.");return false end
    local guid=unit and UnitExists(unit) and UnitGUID(unit)
    local id=M.GuidCounter(guid)
    if not id or id==0 or guid==UnitGUID("player") then
        M.Message("请选择队伍中的巫医机器人 / Select a Witch Doctor bot in your group.");return false
    end
    M.CancelQuote();M.money=nil;M.moneyNonce=nil
    M.name=name;M.guid=guid;M.id=id;M.loaded=false;M.layoutReady=false;M.modern=false
    M.revision=0;M.active=0;M.slot=0;M.spec=0;M.specs={3,3,3};M.unlocked=0;M.level=0;M.aeBudget=0;M.teBudget=0
    M.aeMasks={M.MaskParse(0),M.MaskParse(0),M.MaskParse(0)};M.draftAE=M.MaskParse(0)
    M.ResetBotCodec();M.Message("正在读取机器人天赋 / Reading bot talents...");return true
end
function M.Request(op,args,confirmation)
    if M.pending then return false end
    if not M.ContextValid() then M.loaded=false;M.Message("机器人已离队、不可见或身份改变，请重新打开 / Bot unavailable; reopen its panel.");return false end
    if op~="state" and (not M.loaded or not M.layoutReady or InCombatLockdown()) then
        M.Message("请脱战并刷新后操作 / Leave combat and refresh first.");return false
    end
    M.CancelQuote();M.confirming=confirmation
    sequence=sequence%2147483646+1;M.nonce=sequence;M.pending=true;M.sent=GetTime();M.operation=op;M.expected=M.revision
    M.Message("等待服务器确认 / Waiting for server confirmation...")
    SendChatMessage(".wdbot "..op.." "..M.id.." "..M.nonce.." "..(args or ""),"SAY")
    return true
end
function M.Query() return M.Request("state",L.version.." "..L.hash) end
function M.Save()
    if not M.CanEdit() or not M.HasDrafts() then return end
    local ok,reason=M.AEValid(M.draftAE)
    if not ok then M.Message(reason);return end
    M.Request("save",M.revision.." "..M.slot.." "..L.version.." "..L.hash.." "..M.MaskHex(M.draftAE))
end
function M.Bind()
    if not M.loaded or M.pending or not M.modern or M.HasDrafts() or M.slot>=M.unlocked or M.specs[M.slot+1]~=3 then return end
    M.Request("bind",M.revision.." "..M.slot.." "..M.spec)
end
function M.Activate()
    if not M.loaded or M.pending or M.HasDrafts() or M.slot==M.active or M.slot>=M.unlocked or M.specs[M.slot+1]==3 then return end
    M.Request("activate",M.revision.." "..M.slot)
end
function M.Join() if M.loaded and not M.modern then M.Request("join",tostring(M.revision)) end end
function M.SelectSlot(slot)
    M.CancelQuote()
    if M.pending or not M.loaded or slot>=M.unlocked then return end
    if M.HasDrafts() then M.Message("请先保存或撤销草稿 / Save or discard the draft first.");return end
    M.slot=slot;if M.specs[slot+1]<3 then M.spec=M.specs[slot+1] end;M.ResetDraft()
end
function M.SelectSpec(spec)
    M.CancelQuote()
    if M.pending then return false end
    if M.HasDrafts() then M.Message("请先保存或撤销草稿 / Save or discard the draft first.");return false end
    M.spec=spec;changed();return true
end
function M.SetNode(id,delta)
    M.CancelQuote()
    if not M.CanEdit() then M.Message("此页只能浏览；先选择已解锁方案并绑定专精 / Preview only; select an unlocked build and bind its specialization.");return end
    local i=L.index[id];if not i then return end
    local n=L.nodes[i];local rank=M.AERank(id)+delta
    if rank<0 or rank>n.maximum then return end
    if rank<M.AERank(id,M.aeMasks[M.slot+1]) then M.Message("已保存点数不能直接移除，请使用重置方案 / Saved points require the Reset build button.");return end
    local mask=M.MaskSet(M.draftAE,n.offset,n.width,rank)
    local ok,reason=M.AEValid(mask)
    if not ok then M.Message(reason);return end
    M.draftAE=mask;M.Message("机器人草稿已更改，请保存 / Bot draft changed; click Save.")
end
local errors={permission="无管理权限、距离过远或队伍改变 / Permission, range or group changed.",
    unavailable="机器人不可用 / Bot unavailable.",unsafe="请双方脱战并结束施法后操作 / Both characters must be safe and out of combat.",
    auto_job_running="机器人自动培养任务正在运行，请先停止该任务 / Automatic provisioning is running; stop it first.",
    stale="方案已变化，请刷新后重新核对 / Build changed; refresh and review.",layout="双端天赋布局不匹配 / Talent layouts do not match.",
    freshonly="该角色不满足旧方案转入条件 / Legacy enrollment is unavailable for this character.",
    money="机器人金币不足；未扣主人金币 / Bot has insufficient funds; the owner's money is not used.",
    level="机器人等级不足 / Bot level is too low.",expired="报价已失效，请重新询价 / Quote expired; request a new quote.",
    quoteexpired="报价已失效或已经使用，请重新询价 / Quote expired or already used; request a new quote.",
    disabled="服务器未开放该功能 / This feature is disabled on the server.",
    failed="操作未获确认，请刷新核对余额和方案 / Operation unconfirmed; refresh balance and builds.",
    refresh="方案版本已变化，请刷新后重新询价 / Build revision changed; refresh before requesting a quote.",
    database="天赋存档失败，请检查服务端日志 / Talent database operation failed.",locked="方案未解锁 / Build is locked."}
function M.QuoteReset()
    if not M.loaded or M.pending or M.slot>=M.unlocked or M.specs[M.slot+1]==3 then return end
    if M.HasDrafts() then M.Message("请先保存或撤销草稿 / Save or discard the draft first.");return end
    M.Request("resetquote",M.revision.." "..M.slot)
end
function M.QuoteUnlock()
    if not M.loaded or M.pending or M.unlocked>=3 then return end
    if M.HasDrafts() then M.Message("请先保存或撤销草稿 / Save or discard the draft first.");return end
    M.Request("unlockquote",M.revision.." "..M.unlocked)
end
function M.ConfirmQuote(q)
    if not q or M.quote~=q or M.pending then return false end
    M.CancelQuote()
    if not M.loaded or q.guid~=M.guid or q.revision~=M.revision or GetTime()-q.time>=55 or
        (q.kind=="reset" and q.slot~=M.slot) or (q.kind=="unlock" and q.slot~=M.unlocked) then
        M.Message(errors.quoteexpired);return false
    end
    local args=q.nonce.." "..q.revision.." "..q.slot.." "
    if q.kind=="unlock" then args=args..q.token.." " end
    return M.Request(q.kind,args..q.gold,q)
end
local function offer(kind,revision,slot,gold,token,level)
    if not M.loaded or M.HasDrafts() or not M.ContextValid() or revision~=M.revision or gold>200000 or
        M.moneyNonce~=M.nonce or M.money==nil then return false end
    if (kind=="reset" and slot~=M.slot) or (kind=="unlock" and slot~=M.unlocked) then return false end
    M.pending=false;M.operation=nil
    if M.level<(level or 0) then M.Message(errors.level);return true end
    if M.money<gold*10000 then M.Message(errors.money);return true end
    local q={kind=kind,guid=M.guid,name=M.name,nonce=M.nonce,revision=revision,slot=slot,
        gold=gold,token=token,level=level,balance=M.money,time=GetTime()}
    M.quote=q;M.Message("报价已收到；确认后由该机器人支付 / Quote received; this bot pays only after confirmation.")
    if M.ShowQuote then M.ShowQuote(q) end
    return true
end
function M.Receive(message)
    if type(message)~="string" then return end
    local guid,nonce,payload=message:match("^WDBOT|(%d+)|(%d+)|(.+)$")
    if not M.pending or tonumber(guid)~=M.id or tonumber(nonce)~=M.nonce then return end
    if not M.ContextValid() then M.pending=false;M.loaded=false;M.Message("机器人身份已变化，请重新打开 / Bot identity changed; reopen.");return end
    local copper=tonumber(payload:match("^MONEY|(%d+)$"))
    if copper and copper<=4294967295 then M.money=copper;M.moneyNonce=M.nonce;changed();return end
    local liveLevel=tonumber(payload:match("^LEVEL|(%d+)$"))
    if liveLevel and liveLevel>=1 and liveLevel<=255 then M.level=liveLevel;changed();return end
    local rev,slot,gold=payload:match("^WD16Q|(%d+)|(%d+)|(%d+)$")
    if rev and M.operation=="resetquote" then offer("reset",tonumber(rev),tonumber(slot),tonumber(gold));return end
    local seq,r,sl,token,level,cost=payload:match("^WD141|(%d+)|quote|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)$")
    if seq and M.operation=="unlockquote" and tonumber(seq)==M.nonce and tonumber(token)>0 and tonumber(token)<=4294967295
        and tonumber(level)>=1 and tonumber(level)<=80 then
        offer("unlock",tonumber(r),tonumber(sl),tonumber(cost),tonumber(token),tonumber(level));return
    end
    local errSeq,err=payload:match("^WD141|(%d+)|error|([%w_]+)$")
    if errSeq and tonumber(errSeq)==M.nonce then
        M.pending=false;M.loaded=false;M.confirming=nil;M.CancelQuote();M.Message(errors[err] or err);return
    end
    local reason=payload:match("^ERROR|([%w_]+)$")
    if reason then M.pending=false;M.loaded=false;M.confirming=nil;M.CancelQuote();M.Message(errors[reason] or reason);return end
    if payload:match("^WD16P|") then return end
    local assembled,modern=M.Receive139(payload)
    if not assembled then return end
    if not modern then return end
    local fields={};for v in assembled:gmatch("[^|]+") do fields[#fields+1]=v end
    if #fields~=18 or fields[1]~="WD16" then return end
    local rev,active,slot1,slot2,slot3,level,unlocked=tonumber(fields[3]),tonumber(fields[4]),tonumber(fields[6]),tonumber(fields[7]),tonumber(fields[8]),tonumber(fields[9]),tonumber(fields[12])
    if not rev or not active or active>2 or not unlocked or unlocked>3 or
        (fields[10]=="1" and active>=unlocked) or not level or level<1 or level>255 then return end
    for _,v in ipairs({slot1,slot2,slot3}) do if not v or v>3 then return end end
    local oldRevision,op,q=M.expected,M.operation,M.confirming
    M.confirming=nil
    local wasDirty=M.HasDrafts()
    M.pending=false;M.operation=nil;M.revision=rev;M.active=active;M.specs={slot1,slot2,slot3};M.level=level;M.unlocked=unlocked
    M.modern=fields[13]=="1";M.aeMasks={fields[14],fields[15],fields[16]};M.aeBudget=tonumber(fields[17]);M.teBudget=tonumber(fields[18])
    M.loaded=fields[10]=="1" and fields[2]=="ok"
    if M.slot>=unlocked then M.slot=active end
    local mutation=op=="save" or op=="bind" or op=="activate" or op=="join" or op=="reset"
    local confirmed=M.loaded and mutation and rev==oldRevision+1
    -- Native slot purchases add a unique ownership receipt without incrementing
    -- the talent revision. Confirm their returned ownership count instead.
    if op=="unlock" then confirmed=M.loaded and q and q.guid==M.guid and rev==oldRevision and unlocked==q.slot+1 end
    if confirmed or (M.loaded and not wasDirty) then M.draftAE=M.aeMasks[M.slot+1] end
    if M.loaded and op=="state" and not wasDirty and M.specs[M.slot+1]<3 then M.spec=M.specs[M.slot+1] end
    if fields[2]~="ok" then M.Message(errors[fields[2]] or ("服务器拒绝 / Server rejected: "..fields[2]))
    elseif op~="state" and not confirmed then M.loaded=false;M.Message("修改未获版本确认，请刷新核对 / Revision not confirmed; refresh before continuing.")
    else
        local done=op=="reset" and "机器人方案已重置 / Bot build reset." or
            (op=="unlock" and "机器人方案已解锁，请选择新方案 / Bot build unlocked; select the new slot." or "机器人方案已确认保存 / Bot build confirmed.")
        M.Message(confirmed and done or "机器人天赋已同步 / Bot talents synchronized.")
    end
end
local f=CreateFrame("Frame");M.listener=f
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:SetScript("OnEvent",function(_,_,msg) M.Receive(msg) end)
f:SetScript("OnUpdate",function()
    if M.quote and GetTime()-M.quote.time>=55 then M.CancelQuote();M.Message(errors.quoteexpired) end
    if M.pending and GetTime()-M.sent>8 then
        M.pending=false;M.loaded=false;M.operation=nil;M.confirming=nil;M.CancelQuote()
        M.Message("请求超时，未自动重发；请刷新核对 / Request timed out; refresh to verify. No automatic retry.")
    end
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,msg) return type(msg)=="string" and msg:match("^WDBOT|")~=nil end)
