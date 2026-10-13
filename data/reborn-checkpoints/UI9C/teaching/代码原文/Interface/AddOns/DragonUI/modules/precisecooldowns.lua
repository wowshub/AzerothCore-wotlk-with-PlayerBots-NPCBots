-- UI9C: display only. Also loaded by DragonUI, so a newly added addon is not required.
if _G.RebornCooldownDisplayVersion == "UI9C" then return end
_G.RebornCooldownDisplayVersion = "UI9C"
local tip = GameTooltip
if not tip or not hooksecurefunc then return end
local query, itemTip, elapsedTotal
local function Normalize(text)
    if type(text) ~= "string" then return "" end
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("：", ":"):gsub("%s", ""):lower()
end
local function IsRemaining(text)
    local s = Normalize(text)
    -- Native client text can differ from the Lua GlobalStrings punctuation/order.
    if s:find("冷却时间剩余:",1,true)==1 or s:find("剩余冷却时间:",1,true)==1 or
       s:find("冷卻時間剩餘:",1,true)==1 or s:find("剩餘冷卻時間:",1,true)==1 then return true end
    for _, key in ipairs({"ITEM_COOLDOWN_TIME", "ITEM_COOLDOWN_TIME_SEC", "ITEM_COOLDOWN_TIME_MIN", "ITEM_COOLDOWN_TIME_HOURS", "ITEM_COOLDOWN_TIME_DAYS", "COOLDOWN_REMAINING"}) do
        local value = _G[key]
        if type(value)=="string" then
            local at=value:find("%",1,true)
            local prefix=Normalize(at and value:sub(1,at-1) or value)
            if #prefix>0 and s:sub(1,#prefix)==prefix then return true end
        end
    end
    return false
end
local function Resolve()
    if query then return query end
    if itemTip then return end
    local owner=tip:GetOwner()
    if owner and type(owner.action)=="number" and owner.action>0 then
        local slot=owner.action
        return function() return GetActionCooldown(slot) end
    end
    local name,id=tip:GetSpell()
    name=(id and GetSpellInfo(id)) or name
    if name then return function() return GetSpellCooldown(name) end end
end
local function Refresh()
    if not tip:IsShown() then return end
    local read=Resolve()
    if not read then return end
    local start,duration,enable=read()
    if type(start)~="number" or type(duration)~="number" or enable==0 then return end
    local remaining=math.ceil(math.max(0,start+duration-GetTime()))
    if start==0 or duration==0 then remaining=0 end
    local locale=GetLocale()
    local suffix=(locale=="zhCN" or locale=="zhTW") and "秒" or "s"
    local replacement=remaining>0 and string.format(ITEM_COOLDOWN_TIME,tostring(remaining)..suffix) or ""
    local name=tip:GetName()
    if not name then return end
    for i=1,tip:NumLines() do
        for _,side in ipairs({"Left","Right"}) do
            local line=_G[name.."Text"..side..i]
            if line and IsRemaining(line:GetText()) then line:SetText(replacement) end
        end
    end
end
tip:HookScript("OnTooltipCleared",function()query=nil;itemTip=nil end)
tip:HookScript("OnHide",function()query=nil;itemTip=nil end)
tip:HookScript("OnTooltipSetItem",function()query=nil;itemTip=true end)
tip:HookScript("OnTooltipSetSpell",function()itemTip=nil;Refresh() end)
if tip.SetAction then hooksecurefunc(tip,"SetAction",function(self,slot)
    query=function()return GetActionCooldown(slot)end;Refresh()
end)end
if tip.SetSpell then hooksecurefunc(tip,"SetSpell",function(self,slot,book)
    query=function()return GetSpellCooldown(slot,book)end;itemTip=nil;Refresh()
end)end
if tip.SetHyperlink then hooksecurefunc(tip,"SetHyperlink",function(self,link)
    local id=type(link)=="string" and link:match("^spell:(%d+)")
    local name=id and GetSpellInfo(tonumber(id))
    if name then query=function()return GetSpellCooldown(name)end;itemTip=nil;Refresh() end
end)end
-- Independent timer survives another addon replacing GameTooltip's OnUpdate script.
local driver=CreateFrame("Frame")
driver:SetScript("OnUpdate",function(self,elapsed)
    elapsedTotal=(elapsedTotal or 0)+elapsed
    if elapsedTotal<0.1 then return end
    elapsedTotal=0;Refresh()
end)
SLASH_REBORNCOOLDOWNDISPLAY1="/rcd"
SlashCmdList.REBORNCOOLDOWNDISPLAY=function()
    print("UI9C: "..(GetLocale()=="zhCN" and "冷却秒数显示已加载" or "cooldowns in seconds loaded"))
end
