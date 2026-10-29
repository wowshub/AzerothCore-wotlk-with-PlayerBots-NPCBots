-- MBWD4C: bounded opt-in observation, not another AI evaluator.
local D={pending=false,loaded=false}
RebornWDBotDecision=D
local frame,title,edit
local report=""
local sequence=math.floor(GetTime()*1000)%2000000000
local specs={[0]="巫毒 / Voodoo",[1]="酿造 / Brewing",[2]="暗影狩猎 / Shadowhunting",[3]="未绑定 / Unbound"}
local translated={plan_unavailable="方案不可用",actor_unavailable="执行条件未满足",not_loaded="尚未加载",unbound="未绑定",legacy="旧方案模式",disabled="已禁用",layout_mismatch="布局不匹配",invalid_slot="无效槽位",invalid_build="无效构筑",rotation="常规轮转",ready="可用",
 single_attack_ward_missing="缺少普通攻击守卫",three_engaged_enemies="已交战敌人数满足群蛇条件",viper_replacement_missing="眼镜蛇替换缺失",group_dispel_needed="队伍需要净化神像",voodoo_emergency_protection="应急大巫毒",uncovered_group_healing="缺少群体治疗覆盖",voodoo_mimic_window="拟态施法窗口",emergency_feign="应急假死",emergency_slither="应急化蛇",emergency_mirage="应急幻象",ward_coverage_move="移动至守卫覆盖位置"}
local function word(value)return (translated[value]and translated[value].." / "or "")..(value or "unknown")end
local function spell(id)
    if not id or id==0 then return "无技能 / None"end
    local name=GetSpellInfo and GetSpellInfo(id)
    return (name or "技能 / Spell").." ("..id..")"
end
local function bit(mask,n)return math.floor(mask/n)%2 end
local function context()
    local u=MultiBot and MultiBot.toUnit and MultiBot.toUnit(D.name)
    return u and UnitExists(u)and UnitGUID(u)==D.guid
end
local function paint()
    if not frame then return end
    title:SetText("巫医AI原因 / AI trace — "..(D.name or ""))
    if not D.loaded then report=D.message or "等待服务器采样 / Waiting for a sample."
    else
        local v=D.value;local state=v.meta
        local remaining=math.max(0,state[4]-(GetTime()-D.updated)*1000)
        local lines={"机器人 / Bot: "..D.name.."  GUID "..D.id,
            "采样 / Sampling: "..(state[1]==1 and remaining>0 and "进行中 / Active"or "已停止 / Stopped").."  "..math.ceil(remaining/1000).."s  样本 / Samples "..state[5]}
        if state[2]==0 then
            lines[#lines+1]="尚未观察到巫医原生行动。 / No native WD action observed yet."
            lines[#lines+1]="请让机器人活动后刷新，并检查战斗/支援策略是否开启。"
            lines[#lines+1]="Let the bot act; check its combat/support strategies."
        else
            local p,b,c,a,s=v.plan,v.bot,v.decision,v.attempt,v.spell
            lines[#lines+1]="数据年龄 / Age: "..math.ceil((state[3]+(GetTime()-D.updated)*1000)/1000).."s"
            lines[#lines+1]="方案 / Plan: "..(p[1]==1 and "可用 "or "不可用 ")..(specs[p[3]]or "Unknown").."  槽 / Slot "..(p[2]+1).."  rev "..p[4].."  "..word(p[5])
            lines[#lines+1]="状态 / State: HP "..b[1].."%  Mana "..b[2].."/"..b[3].."  战斗 "..b[4].."  移动 "..b[5].."  施法 "..b[6]
            lines[#lines+1]="AI开关 / Flags: 增益 "..bit(b[7],1).." 净化 "..bit(b[7],2).." 普通召唤 "..bit(b[8],1).." 大型召唤 "..bit(b[8],2)
            lines[#lines+1]="实际选择 / Choice: "..spell(c[2]).."  ["..c[1].."]"
            lines[#lines+1]="选择原因 / Reason: "..word(c[3])
            lines[#lines+1]="目标 / Target: "..(v.target~=""and v.target or "无 / None").."  输出动作 "..c[4].."  需走位 "..c[5]
            lines[#lines+1]=s[1]==1 and ("技能采样 / Spell snapshot: 消耗 "..s[2].."  CD "..math.ceil(s[3]/1000).."s  GCD "..math.ceil(s[4]/1000).."s")or "技能元数据 / Spell data: 未观察 / None"
            lines[#lines+1]=a[2]>0 and ("最近AI施法调用 / Last call: "..spell(a[1]).."  "..(a[2]==1 and "返回true / true"or "返回false / false").."  "..math.ceil((a[3]+(GetTime()-D.updated)*1000)/1000).."s前")or "最近AI施法调用 / Last call: 未观察 / None"
        end
        lines[#lines+1]="只记录巫医原生行动；普通射击及其他模块动作不在此列。"
        lines[#lines+1]="这是观察记录，未选技能不等于所有技能都不可用。"
        report=table.concat(lines,"\n")
    end
    if not edit:HasFocus()then edit:SetText(report)end
end
local function request(mode)
    if D.pending then return false end
    if not context()then D.loaded=false;D.active=false;D.message="对象离队或身份改变，请重开。 / Bot unavailable; reopen.";paint();return false end
    sequence=sequence%2147483646+1;D.nonce=sequence;D.pending=true;D.sent=GetTime();D.lastQuery=D.sent;D.buffer=nil
    SendChatMessage(".wdwhystate "..D.id.." "..D.nonce.." "..mode,"SAY");return true
end
local function create()
    frame=CreateFrame("Frame","RebornWDBotDecisionPanel",UIParent);frame:SetSize(700,470);frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=16,tile=true,tileSize=16})
    frame:SetClampedToScreen(true);frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    local saved=type(RebornWDBotDecisionPosition)=="table"and RebornWDBotDecisionPosition or {}
    local anchors={CENTER=true,TOP=true,BOTTOM=true,LEFT=true,RIGHT=true,TOPLEFT=true,TOPRIGHT=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    frame:SetScale(math.max(.65,math.min(1.25,tonumber(saved.scale)or 1)));frame:SetPoint(anchors[saved.point]and saved.point or "CENTER",UIParent,anchors[saved.relativePoint]and saved.relativePoint or "CENTER",tonumber(saved.x)or 0,tonumber(saved.y)or 0)
    local function save()local p,_,rp,x,y=frame:GetPoint(1);RebornWDBotDecisionPosition={point=p,relativePoint=rp,x=x,y=y,scale=frame:GetScale()}end
    frame:SetScript("OnDragStart",function(self)self:StartMoving()end);frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing();save()end)
    title=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",18,-14);title:SetSize(550,26);title:SetJustifyH("LEFT")
    edit=CreateFrame("EditBox",nil,frame);edit:SetPoint("TOPLEFT",18,-52);edit:SetSize(664,310);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(GameFontHighlightSmall)
    edit:SetScript("OnEscapePressed",function(self)self:ClearFocus();paint()end)
    local function button(label,x,y,w,fn)local b=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,27);b:SetText(label);b:SetScript("OnClick",fn);return b end
    button("采样30秒 / Start",18,-382,170,function()edit:ClearFocus();request(1)end)
    button("刷新 / Refresh",198,-382,120,function()edit:ClearFocus();request(0)end)
    button("停止 / Stop",328,-382,110,function()edit:ClearFocus();request(2)end)
    button("全选报告 / Select",448,-382,200,function()edit:SetText(report);edit:SetFocus();edit:HighlightText()end)
    button("×",656,-12,27,function()frame:Hide()end)
    for i,delta in ipairs({-.05,.05})do button(delta<0 and "−"or "+",584+(i-1)*33,-12,28,function()frame:SetScale(math.max(.65,math.min(1.25,frame:GetScale()+delta)));save()end)end
    local note=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");note:SetPoint("TOPLEFT",18,-423);note:SetSize(664,35);note:SetText("全选后按 Ctrl+C；编辑焦点中暂停刷新显示，Esc退出焦点。\n采样默认关闭、30秒自动到期，不写文件日志、不改变战斗行为。")
    frame:SetScript("OnHide",function()edit:ClearFocus()end);UISpecialFrames[#UISpecialFrames+1]="RebornWDBotDecisionPanel";frame:Hide()
end
function D.Open(unit,name)
    if D.pending then return false end
    local guid=unit and UnitExists(unit)and UnitGUID(unit);local id=type(guid)=="string"and guid:match("^0x00000000(%x%x%x%x%x%x%x%x)$");id=id and tonumber(id,16)
    if not id or id==0 or guid==UnitGUID("player")then return false end
    if not frame then create()end
    if frame:IsShown()and D.guid==guid then frame:Hide();return true end
    D.guid=guid;D.id=id;D.name=name;D.loaded=false;D.active=false;D.message="等待下一次实际AI行动。 / Waiting for actual AI action."
    frame:Show();paint();return request(1)
end
local function split(s)local t={};for v in (s.."|"):gmatch("(.-)|")do t[#t+1]=v end;return t end
local function nums(f,start,last)
    local out={};for i=start,last do local v=tonumber(f[i]);if not v or v~=math.floor(v)or v<0 or v>4294967295 then return end;out[#out+1]=v end;return out
end
function D.Receive(message)
    if type(message)~="string"then return false end
    local id,nonce,payload=message:match("^WDWHY4|(%d+)|(%d+)|(.+)$")
    if not id or not D.pending or tonumber(id)~=D.id or tonumber(nonce)~=D.nonce then return false end
    if not context()then D.pending=false;D.loaded=false;D.active=false;D.message="机器人身份改变。 / Bot identity changed.";paint();return true end
    local f=split(payload);local key=f[1]
    if key=="ERROR"then D.pending=false;D.loaded=false;D.active=false;D.message="诊断未确认 / Unconfirmed: "..(f[2]or "error");paint();return true end
    if key=="BEGIN"then
        local n=nums(f,3,7);if #f~=7 or f[2]~="1"or not n or n[1]>1 or n[2]>1 or n[4]>30000 then return true end
        D.buffer={meta=n,seen={}}
    elseif D.buffer then
        local v=D.buffer
        if key=="PLAN"and #f==6 then local n=nums(f,2,5);if n and n[1]<=1 and n[2]<=2 and n[3]<=3 then n[5]=f[6];v.plan=n;v.seen.plan=true end
        elseif key=="BOT"and #f==9 then local n=nums(f,2,9);if n and n[1]<=100 and n[4]<=1 and n[5]<=1 and n[6]<=1 and n[7]<=3 and n[8]<=3 then v.bot=n;v.seen.bot=true end
        elseif key=="DECISION"and #f==6 then local id=tonumber(f[3]);local damage=tonumber(f[5]);local move=tonumber(f[6]);if id and id==math.floor(id)and id>=0 and id<=4294967295 and (damage==0 or damage==1)and (move==0 or move==1)then v.decision={f[2],id,f[4],damage,move};v.seen.decision=true end
        elseif key=="TARGET"and #f==2 then v.target=f[2];v.seen.target=true
        elseif key=="ATTEMPT"and #f==4 then local n=nums(f,2,4);if n and n[2]<=2 then v.attempt=n;v.seen.attempt=true end
        elseif key=="SPELL"and #f==5 then local n=nums(f,2,5);if n and n[1]<=1 then v.spell=n;v.seen.spell=true end
        elseif key=="END"and #f==1 and v.seen.plan and v.seen.bot and v.seen.decision and v.seen.target and v.seen.attempt and v.seen.spell then
            D.value=v;D.buffer=nil;D.pending=false;D.loaded=true;D.updated=GetTime();D.active=v.meta[1]==1;paint()
        end
    end
    return true
end
local events=CreateFrame("Frame","RebornWDBotDecisionEvents");events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent",function(_,_,message)D.Receive(message)end)
events:SetScript("OnUpdate",function()
    if D.pending and GetTime()-D.sent>=8 then D.pending=false;D.loaded=false;D.active=false;D.message="诊断超时，未自动重发。 / Trace timed out; no retry.";paint()end
    if frame and frame:IsShown()and not D.pending and D.loaded and D.active and GetTime()-D.lastQuery>=2 then request(0)end
end)
if ChatFrame_AddMessageEventFilter then ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,message)return type(message)=="string"and message:match("^WDWHY4|")~=nil end)end
