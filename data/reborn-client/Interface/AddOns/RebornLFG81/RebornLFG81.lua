-- RebornLFG81 (RebornWOW LFG81B)
-- This realm's level cap is above 80. The server already lets level 81+ characters
-- queue for the Wrath dungeons and the Wrath random dungeon (LFG81A: the per-dungeon
-- lock reads dungeon_access_template, and endgame random entries stay open past their
-- DBC max level). But the stock Dungeon Finder UI hides any dungeon whose DBC max level
-- is below the player's level, in two places:
--   * the "Type" drop-down (a local isRandomDungeonDisplayable in LFDFrame.lua), and
--   * the specific-dungeon list (LFDList_DefaultFilterFunction).
-- This file applies the server's rule on the client: an endgame dungeon (DBC max level
-- 80 or more) stays visible above its max level. The specific list only shows such a
-- dungeon when the server's lock list does not lock it, so nothing is shown that the
-- server would refuse. Item-level locks on heroics are untouched.

local ENDGAME = 80

local function Displayable(id)
    local _, _, minLevel, maxLevel, _, _, _, expansionLevel = GetLFGDungeonInfo(id)
    if not minLevel then return false end
    local level = UnitLevel("player")
    local fits = level <= maxLevel or maxLevel >= ENDGAME
    return level >= minLevel and fits and EXPANSION_LEVEL >= expansionLevel
end

-- The stock drop-down initializer, with Displayable in place of the local level check.
local function TypeDropDownInitialize()
    local info = UIDropDownMenu_CreateInfo()
    info.text = SPECIFIC_DUNGEONS
    info.value = "specific"
    info.func = LFDQueueFrameTypeDropDownButton_OnClick
    info.checked = LFDQueueFrame.type == info.value
    UIDropDownMenu_AddButton(info)
    for i = 1, GetNumRandomDungeons() do
        local id, name = GetLFGRandomDungeonInfo(i)
        local isAvailable = IsLFGDungeonJoinable(id)
        if Displayable(id) then
            info.text = name
            info.value = id
            info.isTitle = nil
            if isAvailable then
                info.func = LFDQueueFrameTypeDropDownButton_OnClick
                info.disabled = nil
                info.checked = (LFDQueueFrame.type == info.value)
                info.tooltipWhileDisabled = nil
                info.tooltipOnButton = nil
                info.tooltipTitle = nil
                info.tooltipText = nil
            else
                info.func = nil
                info.disabled = 1
                info.checked = nil
                info.tooltipWhileDisabled = 1
                info.tooltipOnButton = 1
                info.tooltipTitle = YOU_MAY_NOT_QUEUE_FOR_THIS
                info.tooltipText = LFDConstructDeclinedMessage(id)
            end
            UIDropDownMenu_AddButton(info)
        end
    end
end

local function Install()
    if type(LFDQueueFrameTypeDropDown_Initialize) == "function" and type(UIDropDownMenu_AddButton) == "function" then
        LFDQueueFrameTypeDropDown_Initialize = TypeDropDownInitialize
        if LFDQueueFrameTypeDropDown then LFDQueueFrameTypeDropDown.initialize = TypeDropDownInitialize end
    end
    local orig = LFDList_DefaultFilterFunction
    if type(orig) == "function" and type(LFGGetDungeonInfoByID) == "function" and LFG_RETURN_VALUES then
        local function Filter(dungeonID)
            if orig(dungeonID) then return true end
            local info = LFGGetDungeonInfoByID(dungeonID)
            if not info then return false end
            local V = LFG_RETURN_VALUES
            local level = UnitLevel("player")
            local maxLevel = info[V.maxLevel]
            return info[V.groupID] ~= 0 and EXPANSION_LEVEL >= info[V.expansionLevel]
                and level >= info[V.minLevel] and level > maxLevel and maxLevel >= ENDGAME
                and LFGLockList ~= nil and not LFGLockList[dungeonID]   -- only what the server allows
        end
        LFDList_DefaultFilterFunction = Filter
        if LFD_CURRENT_FILTER == orig then LFD_CURRENT_FILTER = Filter end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local ok, err = pcall(Install)
    if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333RebornLFG81: " .. tostring(err) .. "|r") end
end)
