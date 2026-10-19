-- Only the custom Witch Doctor uses this route. Existing talent/glyph APIs remain available.
local function IsDoctor()
    local _,token,id=UnitClass("player")
    if token=="WITCHDOCTOR" then return true end
    if ({WARRIOR=true,PALADIN=true,HUNTER=true,ROGUE=true,PRIEST=true,DEATHKNIGHT=true,SHAMAN=true,MAGE=true,WARLOCK=true,DRUID=true})[token] then return false end
    return id==13
end
local function ToggleDoctor()
    if PlayerTalentFrame and PlayerTalentFrame:IsShown() then HideUIPanel(PlayerTalentFrame) end
    RebornWDTreePreviewAPI.Toggle()
end
function RebornWDTalentBindingText()
    local a,b=GetBindingKey("TOGGLETALENTS")
    local key=a or b
    local display=key and (GetBindingText and GetBindingText(key,"KEY_") or key)
    if RebornWDLanguage=="en" then
        return (display and ("Press "..display.." to open talents") or "Talent shortcut is unbound; set it in Key Bindings").."; click to open; Alt-drag to move"
    end
    return (display and ("按 "..display.." 打开新天赋面板") or "天赋快捷键未绑定，可在按键设置中设为N").."；点击打开，Alt拖动图标"
end
local installed={}
local function Wrap(name,petAware)
    local original=_G[name]
    if type(original)~="function" or installed[name]==original then return end
    local wrapper=function(...)
        if IsDoctor() and (not petAware or not select(1,...)) then
            return ToggleDoctor()
        end
        return original(...)
    end
    installed[name]=wrapper;_G[name]=wrapper
end
local f=CreateFrame("Frame")
local hookedButton
local function Refresh()
    -- On other characters even the function identity and old button are left untouched.
    if not IsDoctor() then return end
    Wrap("ToggleTalentFrame",false)
    Wrap("PlayerTalentFrame_Toggle",true)
    if InCombatLockdown() then return end
    local button=TalentMicroButton
    if button then
        -- DragonUI already excludes this flag from both skinning and layout.
        button.dragonUISuppressed=true
        button:Hide()
        if hookedButton~=button then
            hookedButton=button
            button:HookScript("OnShow",function(self)
                if IsDoctor() and not InCombatLockdown() then self:Hide() end
            end)
        end
    end
end
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent",Refresh)
-- No SetBinding/SaveBindings: N retains its normal TOGGLETALENTS action,
-- including any key the player deliberately remapped it to.
Refresh()
