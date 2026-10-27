-- SPEC14: view selection and activation are separate server-authoritative states.
local tab,attached,enabled,active,view,ready,free = nil,false,false,nil,nil,false,0
local pending,deadline,lastQuery,refreshing,renderRequested = nil,0,-10,false,false
local oldClick,oldActivate = {},nil
local names={"第一天赋 / First Build","第二天赋 / Second Build","第三天赋 / Third Build"}
local function Monk()
    local _,token,id=UnitClass("player")
    return token=="MONK" or id==14
end
local function Tell(s) DEFAULT_CHAT_FRAME:AddMessage("[MONKSPEC14] "..s) end
local function Send(command,kind,index)
    pending={kind=kind,index=index};deadline=GetTime()+15
    SendChatMessage(command,"SAY")
end
local function Query()
    if Monk() and GetTime()-lastQuery>3 then
        lastQuery=GetTime();SendChatMessage(".monkspecstate","SAY")
    end
end
local function Refresh()
    if refreshing or not attached then return end
    refreshing=true
    if not Monk() or not PlayerSpecTab2:IsShown() then tab:Hide();refreshing=false;return end
    -- These identify logical builds, not the temporary two-group wire projection.
    PlayerSpecTab1:SetNormalTexture("Interface\\Icons\\RebornTalentUI_9103")
    PlayerSpecTab2:SetNormalTexture("Interface\\Icons\\RebornTalentUI_9101")
    PlayerSpecTab1.usingPortraitTexture=false
    PlayerSpecTab2.usingPortraitTexture=false
    tab:SetNormalTexture("Interface\\Icons\\ability_monk_guard")
    tab:ClearAllPoints();tab:SetPoint("TOPLEFT",PlayerSpecTab2,"BOTTOMLEFT",0,-22);tab:Show()
    if PlayerSpecTab3 and PlayerSpecTab3:IsShown() then
        PlayerSpecTab3:ClearAllPoints();PlayerSpecTab3:SetPoint("TOPLEFT",tab,"BOTTOMLEFT",0,-39)
    end
    if enabled and active and view and not PlayerTalentFrame.pet then
        PlayerSpecTab1:SetChecked(view==1);PlayerSpecTab2:SetChecked(view==2);tab:SetChecked(view==3)
        if PlayerTalentFrameTitleText then PlayerTalentFrameTitleText:SetText(names[view]) end
        if GlyphFrameTitleText then GlyphFrameTitleText:SetText(names[view].." 雕文 / Glyphs") end
        local same=active==view
        if PlayerTalentFrameStatusFrame then
            if same then PlayerTalentFrameStatusFrame:Show() else PlayerTalentFrameStatusFrame:Hide() end
        end
        if PlayerTalentFrameActivateButton then
            if same then PlayerTalentFrameActivateButton:Hide()
            else
                PlayerTalentFrameActivateButton:Show()
                if ready and not pending and not InCombatLockdown() and not UnitIsDeadOrGhost("player") then
                    PlayerTalentFrameActivateButton:Enable()
                else PlayerTalentFrameActivateButton:Disable() end
            end
        end
        if not same then
            if PlayerTalentFramePreviewBar then PlayerTalentFramePreviewBar:Hide() end
            if PlayerTalentFrameTalentPointsText then PlayerTalentFrameTalentPointsText:SetText("剩余天赋点数 / Available: "..free) end
        end
        if PlayerTalentFrameActiveSpecTabHighlight then
            local icon=active==3 and tab or _G["PlayerSpecTab"..active]
            PlayerTalentFrameActiveSpecTabHighlight:ClearAllPoints()
            PlayerTalentFrameActiveSpecTabHighlight:SetParent(icon)
            PlayerTalentFrameActiveSpecTabHighlight:SetAllPoints(icon)
            PlayerTalentFrameActiveSpecTabHighlight:Show()
        end
    elseif not enabled then tab:SetChecked(false) end
    refreshing=false
end
local function Render()
    if not attached or not enabled or not active or not view then return end
    if PlayerTalentFrame.pet and not renderRequested then return end
    -- Native group 1 contains the active build; group 2 contains the viewed build.
    PlayerSpecTab_OnClick(view==active and PlayerSpecTab1 or PlayerSpecTab2)
    renderRequested=false
    Refresh()
end
local function RequestView(index)
    if pending then Tell("请等当前请求完成。 / Please wait for the current request.");return end
    renderRequested=true
    Send(".monkspecview"..index,"view",index)
    Refresh()
end
StaticPopupDialogs["REBORN_MONK_BUY_THIRD"]={
    text="%s",
    button1="确认开通 / Confirm",button2=CANCEL,
    OnAccept=function(self)
        if self.data and self.data.token then Send(".monkspecbuy "..self.data.token,"unlock",3) end
    end,
    timeout=60,whileDead=false,hideOnEscape=true,
}
StaticPopupDialogs["REBORN_MONK_DISCARD_PREVIEW"]={
    text="放弃尚未确认的加点预览，再查看另一套？\nDiscard unconfirmed talent point preview and view another build?",
    button1=YES,button2=CANCEL,
    OnAccept=function(self)
        if ResetGroupPreviewTalentPoints then ResetGroupPreviewTalentPoints(false,PlayerTalentFrame.talentGroup) end
        RequestView(self.data)
    end,
    timeout=0,whileDead=true,hideOnEscape=true,
}
local function Click(index)
    if not enabled then
        if index==3 and not pending then Send(".monkspecunlock","quote",3) end
        return
    end
    if GetGroupPreviewTalentPointsSpent and PlayerTalentFrame and not PlayerTalentFrame.pet and
        GetGroupPreviewTalentPointsSpent(false,PlayerTalentFrame.talentGroup)>0 and index~=view then
        local popup=StaticPopup_Show("REBORN_MONK_DISCARD_PREVIEW")
        if popup then popup.data=index end
        return
    end
    RequestView(index)
end
local function Activate(self,...)
    if not enabled or not Monk() then if oldActivate then oldActivate(self,...) end;return end
    if pending or not ready or not view or view==active then return end
    if InCombatLockdown() or UnitIsDeadOrGhost("player") then Tell("请存活并脱战。 / Must be alive and out of combat.");return end
    renderRequested=true
    Send(".monkspecgo"..view,"activate",view)
    Refresh()
end
local function Attach()
    if attached or not PlayerTalentFrame or not PlayerSpecTab2 or not PlayerTalentFrameActivateButton then return end
    attached=true
    tab=CreateFrame("CheckButton","RebornMonkThirdSpecTab",PlayerTalentFrame,"PlayerSpecTabTemplate")
    tab:SetSize(32,32);tab:EnableMouse(true);tab:RegisterForClicks("LeftButtonUp")
    tab:SetFrameLevel(PlayerSpecTab2:GetFrameLevel()+1)
    local _,_,icon=GetSpellInfo(9001540)
    tab:SetNormalTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    tab:SetScript("OnClick",function() Click(3) end)
    tab:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(names[3],1,.82,0)
        GameTooltip:AddLine(enabled and "点击查看；再点上方按钮激活。\nView first; activate with the button above." or
            "尚未开启。点击查看开通价格，确认后开通。\nLocked. Click for the unlock price; confirm to purchase.",1,1,1,true)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave",function() GameTooltip:Hide() end)
    for i=1,2 do
        local index=i;local frame=_G["PlayerSpecTab"..i]
        oldClick[i]=frame:GetScript("OnClick")
        frame:SetScript("OnClick",function(self,...)
            if Monk() and enabled then Click(index) elseif oldClick[index] then oldClick[index](self,...) end
        end)
    end
    oldActivate=PlayerTalentFrameActivateButton:GetScript("OnClick")
    PlayerTalentFrameActivateButton:SetScript("OnClick",Activate)
    PlayerTalentFrame:HookScript("OnShow",function() Query();Render();Refresh() end)
    if hooksecurefunc then
        for _,name in ipairs({"PlayerTalentFrame_UpdateSpecs","PlayerTalentFrame_Refresh","PlayerTalentFrameActivateButton_Update","PlayerSpecTab_Update"}) do
            if _G[name] then hooksecurefunc(name,Refresh) end
        end
    end
    Refresh()
end
SLASH_REBORNMONKSPECCARD1="/monkspeccard";SlashCmdList.REBORNMONKSPECCARD=Query
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","ADDON_LOADED","CHAT_MSG_SYSTEM","PLAYER_TALENT_UPDATE","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(self,event,message)
    if event=="CHAT_MSG_SYSTEM" and type(message)=="string" then
        local token,currency,price=message:match("%[MONKSPEC16%] QUOTE=(%d+) CURRENCY=(%a+) PRICE=(%d+)")
        if token and pending and pending.kind=="quote" then
            pending=nil
            local unit=currency=="gold" and "金币 / Gold" or currency=="vp" and "VP" or "免费 / Free"
            local text="开通空白第三天赋："..price.." "..unit.."。\n第一、第二套保留；开通后切换免费。\nUnlock a blank third build for "..price.." "..unit..".\nExisting builds retained; switching is free."
            local popup=StaticPopup_Show("REBORN_MONK_BUY_THIRD",text)
            if popup then popup.data={token=token} end
        elseif message:find("[MONKSPEC16]",1,true) and pending and
            (pending.kind=="quote" or pending.kind=="unlock") then pending=nil end
        local a,v,r,e,f=message:match("%[MONKSPEC14%] ACTIVE=(%d) VIEW=(%d) READY=(%d) ENABLED=(%d) FREE=(%d+)")
        if a then
            a=tonumber(a);v=tonumber(v)
            if a>=1 and a<=3 and v>=1 and v<=3 then
                active=a;view=v;ready=r=="1";enabled=e=="1";free=tonumber(f)
                if pending and pending.kind=="activate" and message:match("CAST=1") then pending.sawCasting=true end
                if pending and ready then
                    if pending.kind=="unlock" or (pending.kind=="quote" and enabled) or (pending.kind=="view" and view==pending.index) or
                        (pending.kind=="activate" and (active==pending.index or pending.sawCasting)) then pending=nil end
                end
                Attach();Render();Refresh()
            end
        end
    elseif event=="PLAYER_LOGIN" then Query() end
    Attach();Refresh()
end)
events:SetScript("OnUpdate",function()
    if pending and GetTime()>deadline then
        pending=nil;Tell("请求未确认，请查看聊天提示。 / Request not confirmed; check chat.")
        Query();Refresh()
    end
end)
Attach()

-- TG31A: immutable read-only view of the existing authoritative state machine.
function RebornMonkGetBuildState()
 return {active=active,view=view,ready=ready,enabled=enabled,pending=pending~=nil}
end
