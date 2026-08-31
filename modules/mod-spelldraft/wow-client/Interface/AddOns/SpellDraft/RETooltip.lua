-- RETooltip.lua — renders Mystic Enchants (Random Enchantments) on item tooltips.
--
-- Item links carry no usable per-instance id in 3.3.5 (uniqueId is 0 for
-- regular items), so the server identifies enchanted items BY POSITION.
-- spelldraft_re.lua pushes "SpellDraftRE" addon messages whenever the
-- inventory changes:
--     RESET                                          wipe the map
--     POS;<key>;<spellId>;<quality>;<name>;<tooltip> one enchanted item
-- where <key> is "inv:<1-19>" (equipped), "bag:0:<1-16>" (backpack) or
-- "bag:<1-4>:<1-36>" (side bags) — matching GameTooltip's SetInventoryItem /
-- SetBagItem arguments.
--
-- The enchant's effect text is resolved client-side from its aura spell (so
-- numbers are always accurate); the server tooltip string is a fallback.

local L = SpellDraft.L
SpellDraft.MYSTIC_FORMULA_VERSION = "B0.9.19.1-formula-v1"
local QUALITY_COLOR = {
    [2] = "|cff1eff00",
    [3] = "|cff0070dd",
    [4] = "|cffa335ee",
    [5] = "|cffff8000",
    [6] = "|cffe6cc80",
}

local cache = {}  -- [positionKey] = { spell, quality, name, tooltip }

-- Hidden tooltip used to read a spell's description text.
local scanTip = CreateFrame("GameTooltip", "SpellDraftREScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function GetSpellDescription(spellId)
    scanTip:ClearLines()
    scanTip:SetHyperlink("spell:" .. spellId)
    local lines = {}
    for i = 2, scanTip:NumLines() do
        local fs = _G["SpellDraftREScanTipTextLeft" .. i]
        local text = fs and fs:GetText()
        -- Skip rank/cast-time metadata rows; keep the description body.
        if text and #text > 20 then
            lines[#lines + 1] = text
        end
    end
    if #lines > 0 then
        return table.concat(lines, " ")
    end
    return nil
end

local function AppendEnchantLines(tooltip, data)
    local color = QUALITY_COLOR[data.quality] or "|cff1eff00"
    local nativeName = nil
    local nativeDesc = nil
    if data.spell and data.spell > 0 then
        nativeName = GetSpellInfo(data.spell)
        nativeDesc = GetSpellDescription(data.spell)
    end

    local name, desc, secondaryName, secondaryDesc = data.name, nativeDesc or data.tooltip, nil, nil
    if SpellDraft.GetMysticEnchantText then
        name, desc, secondaryName, secondaryDesc = SpellDraft.GetMysticEnchantText(
            data.name, data.tooltip, nativeName, nativeDesc)
    end

    tooltip:AddLine(" ")
    tooltip:AddLine(color .. L("Mystic Enchant") .. ": " .. name .. "|r")
    if secondaryName then
        tooltip:AddLine("|cffaaaaaa" .. secondaryName .. "|r", 0.67, 0.67, 0.67, true)
    end
    if desc and desc ~= "" then
        tooltip:AddLine(desc, 0.9, 0.9, 0.9, true)
    end
    if secondaryDesc and secondaryDesc ~= "" then
        tooltip:AddLine("|cff80c0ff" .. secondaryDesc .. "|r", 0.5, 0.75, 1.0, true)
    end
    if (desc and desc:find("%$")) or (secondaryDesc and secondaryDesc:find("%$")) then
        tooltip:AddLine("|cffff4040[Formula unresolved / 公式未解析] /sdmysticver|r", 1, 0.25, 0.25, true)
    end
    tooltip:Show()
end

hooksecurefunc(GameTooltip, "SetInventoryItem", function(self, unit, slot)
    if unit ~= "player" then return end
    local data = cache["inv:" .. slot]
    if data then
        AppendEnchantLines(self, data)
    end
end)

hooksecurefunc(GameTooltip, "SetBagItem", function(self, bag, slot)
    local data = cache["bag:" .. bag .. ":" .. slot]
    if data then
        AppendEnchantLines(self, data)
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, prefix, message)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Ask the server for a fresh map (covers /reload, which wipes us
        -- without any server-side inventory change to trigger a push).
        SendChatMessage("SDRE_SYNC", "WHISPER", nil, UnitName("player"))
        return
    end
    if prefix ~= "SpellDraftRE" then return end

    if message == "RESET" then
        wipe(cache)
        return
    end

    local key, spellId, quality, name, tooltipText =
        message:match("^POS;([^;]+);(%d+);(%d+);([^;]+);(.*)$")
    if not key then return end

    cache[key] = {
        spell = tonumber(spellId),
        quality = tonumber(quality),
        name = name,
        tooltip = tooltipText,
    }
end)
