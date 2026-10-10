-- Use the real inventory button; this does not equip or create ammunition.
local updating = false
local function ResolveSlots()
    return CharacterAmmoSlot or CharacterAmmoSlot9,
        CharacterRangedSlot or CharacterRangedSlot9
end

local function UsesAmmo(itemID)
    if not itemID then return false end
    local _, _, _, _, _, _, subtype, _, location = GetItemInfo(itemID)
    if location == "INVTYPE_RANGED" then return true end
    if location ~= "INVTYPE_RANGEDRIGHT" or not subtype then return false end
    -- Auction subclass results are a compact UI list, not ItemSubClass IDs.
    -- Prefer an ID-addressed API if supplied by the client extension.
    if GetItemSubClassInfo then
        for _, id in ipairs({2, 3, 18}) do
            local name = GetItemSubClassInfo(2, id)
            if name and subtype == name then return true end
        end
    end
    -- Current patch-X ItemSubClass rows 2/2, 2/3, 2/18 use these Chinese names,
    -- including the enUS locale field. Keep native English/TW spellings too.
    local ammoTypes = { ["弓"]=true, ["枪械"]=true, ["槍械"]=true, ["弩"]=true,
        ["Bows"]=true, ["Guns"]=true, ["Crossbows"]=true }
    return ammoTypes[subtype] == true
end

local function UpdateAmmoSlotVisibility()
    if updating or (InCombatLockdown and InCombatLockdown()) then return end
    local ammo, ranged = ResolveSlots()
    if not ammo or not ranged or not PaperDollFrame then return end
    local _, token, classID = UnitClass("player")
    local custom = classID == 13 or classID == 14
        or token == "WITCHDOCTOR" or token == "MONK"
    if not custom and not UnitHasRelicSlot("player") then return end
    updating = true
    ammo.shouldBeShown = UsesAmmo(GetInventoryItemID("player", 18))
    if ammo.shouldBeShown then
        ammo:SetParent(PaperDollFrame)
        ammo:ClearAllPoints()
        ammo:SetPoint("LEFT", ranged, "RIGHT", 15, 0)
        ammo:SetFrameStrata(ranged:GetFrameStrata())
        ammo:SetFrameLevel(ranged:GetFrameLevel() + 1)
        ammo:Show()
        if PaperDollItemSlotButton_Update then
            PaperDollItemSlotButton_Update(ammo)
        end
    else
        ammo:Hide()
    end
    updating = false
end

local function SetupAntiHideHook()
    local ammo = ResolveSlots()
    if not ammo or ammo.rebornAmmoVisibilityHooked then return end
    ammo.rebornAmmoVisibilityHooked = true
    hooksecurefunc(ammo, "Hide", function(self)
        if updating or (InCombatLockdown and InCombatLockdown()) then return end
        if self.shouldBeShown and PaperDollFrame:IsShown() then
            self:Show()
        end
    end)
end

hooksecurefunc("PaperDollFrame_OnShow", function()
    SetupAntiHideHook()
    UpdateAmmoSlotVisibility()
end)
hooksecurefunc("PaperDollItemSlotButton_Update", function(self)
    if self:GetID() == 18 then UpdateAmmoSlotVisibility() end
end)
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("BAG_UPDATE")
frame:SetScript("OnEvent", function(self, event, unit)
    if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
    SetupAntiHideHook()
    UpdateAmmoSlotVisibility()
end)
SetupAntiHideHook()
