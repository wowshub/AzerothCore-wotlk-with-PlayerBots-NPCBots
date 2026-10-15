-- Use the real inventory button; this does not equip or create ammunition.
local updating = false
local pending = false
local UpdateAmmoSlotVisibility
local queue = CreateFrame("Frame")
queue:Hide()
local function RequestLayout()
    if updating then return end
    pending = true
    if not (InCombatLockdown and InCombatLockdown()) then queue:Show() end
end
queue:SetScript("OnUpdate",function(self)
    self:Hide()
    if not pending or (InCombatLockdown and InCombatLockdown()) then return end
    pending = false
    if UpdateAmmoSlotVisibility then UpdateAmmoSlotVisibility() end
end)
local function AnchorRow(ammo,ranged)
    local cp = DragonUI and DragonUI.CharacterPanel
    local hdGear = PaperDollFrame and PaperDollFrame.EquipInset
    if hdGear and hdGear:IsShown() and RebornPaperDollWeaponRow then
        RebornPaperDollWeaponRow(ammo.shouldBeShown)
    elseif cp and cp.Enabled and cp:Enabled() and ranged._duiAnchored and cp.ReanchorWeaponRow then
        cp.ReanchorWeaponRow()
    else
        -- UI10A: gear pane excludes the expanded stats column.
        local gear = PaperDollFrame.EquipInset or ranged:GetParent() or PaperDollFrame
        local shift = ammo.shouldBeShown and -21 or 0
        for _,v in ipairs({{CharacterMainHandSlot,-42+shift},{CharacterSecondaryHandSlot,shift},{ranged,42+shift}}) do
            if v[1] then v[1]:ClearAllPoints();v[1]:SetPoint("BOTTOM",gear,"BOTTOM",v[2],14) end
        end
    end
    ammo:SetParent(ranged:GetParent() or PaperDollFrame)
    ammo:ClearAllPoints()
    ammo:SetPoint("LEFT",ranged,"RIGHT",15,0)
end
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

UpdateAmmoSlotVisibility = function()
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
        ammo:SetFrameStrata(ranged:GetFrameStrata())
        ammo:SetFrameLevel(ranged:GetFrameLevel() + 1)
        ammo:Show()
        if PaperDollItemSlotButton_Update then
            PaperDollItemSlotButton_Update(ammo)
        end
    else
        ammo:Hide()
    end
    AnchorRow(ammo,ranged)
    updating = false
end

local function SetupAntiHideHook()
    local ammo,ranged = ResolveSlots()
    if not ammo then return end
    for _,slot in pairs({CharacterMainHandSlot,CharacterSecondaryHandSlot,ranged,ammo}) do
        if slot and not slot.rebornWeaponAnchorHooked then
            slot.rebornWeaponAnchorHooked = true
            hooksecurefunc(slot,"SetPoint",RequestLayout)
        end
    end
    for _,panel in pairs({PaperDollFrame,PaperDollFrame and PaperDollFrame.EquipInset}) do
        if panel and not panel.rebornWeaponLayoutHooked then
            panel.rebornWeaponLayoutHooked = true
            panel:HookScript("OnShow",RequestLayout)
            panel:HookScript("OnSizeChanged",RequestLayout)
        end
    end
    if ammo.rebornAmmoVisibilityHooked then return end
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
    RequestLayout()
end)
hooksecurefunc("PaperDollItemSlotButton_Update", function(self)
    if self:GetID() == 18 then RequestLayout() end
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
    RequestLayout()
end)
SetupAntiHideHook()

RequestLayout()

-- UI10B: short read-only diagnostics, one line per real inventory button.
SLASH_REBORNGearCheck1 = "/gearcheck"
SlashCmdList["REBORNGearCheck"] = function()
    local gear=PaperDollFrame and PaperDollFrame.EquipInset
    print("UI10B gear="..tostring(gear and gear:IsShown()).." combat="..tostring(InCombatLockdown()))
    for _,name in ipairs({"CharacterMainHandSlot","CharacterSecondaryHandSlot","CharacterRangedSlot","CharacterAmmoSlot"}) do
        local slot=_G[name]
        if slot then
            local point,relative,relativePoint,x,y=slot:GetPoint(1)
            print(name.." "..slot:GetWidth().."x"..slot:GetHeight().." "..tostring(point).." -> "..tostring(relative and relative:GetName()).." "..tostring(x)..","..tostring(y))
        end
    end
end
