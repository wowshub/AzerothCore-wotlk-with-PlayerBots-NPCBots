-- ============================================================================
-- SpellDraft Grimoire - Fully Custom Standalone Spellbook UI
-- ============================================================================

SpellDraft = SpellDraft or {}
local L = SpellDraft.L
local DEBUG = false

local FALLBACK_SPELLS = {
    [75] = { name = "Auto Shot", icon = "Interface\\Icons\\Ability_Marksmanship", subName = "" },
    [5019] = { name = "Shoot", icon = "Interface\\Icons\\Ability_ShootWand", subName = "" },
    [3018] = { name = "Shoot", icon = "Interface\\Icons\\Ability_Marksmanship", subName = "" },
    [2764] = { name = "Throw", icon = "Interface\\Icons\\Ability_Throw", subName = "" },
    [6603] = { name = "Attack", icon = "Interface\\Icons\\INV_Sword_04", subName = "" }
}

-- Some client spells deliberately share both a localized name and an icon.
-- Never merge them by display name: they require different equipped weapons
-- and remain distinct abilities/action-bar entries.
local SPELL_DISPLAY_OVERRIDES = {
    [5019] = { name = "Shoot (Wand)", usage = "Requires a wand" },
    [3018] = { name = "Shoot (Ranged Weapon)", usage = "Requires a ranged weapon" }
}

local function GetSpellDisplayOverride(spellId)
    return SPELL_DISPLAY_OVERRIDES[tonumber(spellId) or 0]
end

local function GetSpellDisplayName(spellId, fallbackName)
    local displayOverride = GetSpellDisplayOverride(spellId)
    return displayOverride and L(displayOverride.name) or fallbackName
end

-- Rarity Mapping Details
local RARITY_NAMES = {
    [0] = "Common",
    [1] = "Uncommon",
    [2] = "Rare",
    [3] = "Epic",
    [4] = "Legendary",
    -- Internal rarity 5 is retained for protocol/data compatibility.  Its
    -- player-facing name describes the real rule: these racial, triggered or
    -- balance-risk spells are restricted from the normal draft pool.
    [5] = "Restricted"
}

-- Rarity color formatting
local RARITY_COLORS = {
    [0] = "|cffb0b0b0", -- Grey
    [1] = "|cff1eff00", -- Green
    [2] = "|cff0070dd", -- Blue
    [3] = "|cffa335ee", -- Purple
    [4] = "|cffff8000", -- Orange
    [5] = "|cffe74c3c"  -- Red (Restricted)
}

-- Rarity RGB values for borders
local RARITY_RGB = {
    [0] = { r = 0.6, g = 0.6, b = 0.6 },  -- Common (Grey)
    [1] = { r = 0.12, g = 1.0, b = 0.0 }, -- Uncommon (Green)
    [2] = { r = 0.0, g = 0.44, b = 0.87 }, -- Rare (Blue)
    [3] = { r = 0.64, g = 0.21, b = 0.93 }, -- Epic (Purple)
    [4] = { r = 1.0, g = 0.5, b = 0.0 },  -- Legendary (Orange)
    [5] = { r = 0.9, g = 0.3, b = 0.2 }   -- Restricted (Red)
}

-- Highest valid draft rarity. Anything above this (e.g. the DB default of 99)
-- is an uncategorized, non-draftable spell and is hidden from the Grimoire.
local MAX_DRAFT_RARITY = 5

-- Class Coordinates mapping (standard WoW client coords for UI-CharacterCreate-Classes)
local CLASS_ICON_TCOORDS = {
    ["WARRIOR"]       = {0, 0.25, 0, 0.25},
    ["MAGE"]          = {0.25, 0.5, 0, 0.25},
    ["ROGUE"]         = {0.5, 0.75, 0, 0.25},
    ["DRUID"]         = {0.75, 1, 0, 0.25},
    ["HUNTER"]        = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"]        = {0.25, 0.5, 0.25, 0.5},
    ["PRIEST"]         = {0.5, 0.75, 0.25, 0.5},
    ["WARLOCK"]        = {0.75, 1, 0.25, 0.5},
    ["PALADIN"]        = {0, 0.25, 0.5, 0.75},
    ["DEATHKNIGHT"]    = {0.25, 0.5, 0.5, 0.75},
}

-- Class Tabs Configuration
local tabClasses = {
    { value = "ALL",          text = SpellDraft.ClassName("ALL"), icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { value = "WARRIOR",      text = SpellDraft.ClassName("WARRIOR"), isClass = true },
    { value = "PALADIN",      text = SpellDraft.ClassName("PALADIN"), isClass = true },
    { value = "HUNTER",       text = SpellDraft.ClassName("HUNTER"), isClass = true },
    { value = "ROGUE",        text = SpellDraft.ClassName("ROGUE"), isClass = true },
    { value = "PRIEST",       text = SpellDraft.ClassName("PRIEST"), isClass = true },
    { value = "DEATHKNIGHT",  text = SpellDraft.ClassName("DEATHKNIGHT"), isClass = true },
    { value = "SHAMAN",       text = SpellDraft.ClassName("SHAMAN"), isClass = true },
    { value = "MAGE",         text = SpellDraft.ClassName("MAGE"), isClass = true },
    { value = "WARLOCK",      text = SpellDraft.ClassName("WARLOCK"), isClass = true },
    { value = "DRUID",        text = SpellDraft.ClassName("DRUID"), isClass = true },
    { value = "GENERAL",      text = SpellDraft.ClassName("GENERAL"), icon = "Interface\\Icons\\INV_Misc_QuestionMark" }
}

local ASCENSION_TEXTURE_PATH = "Interface\\AddOns\\SpellDraft\\Textures\\Ascension\\"
local ORIGINAL_TEXTURE_PATH = "Interface\\AddOns\\SpellDraft\\Textures\\Original\\"
local REFERENCE_TEXTURE_PATH = "Interface\\AddOns\\SpellDraft\\Textures\\Reference\\"
local advancementBackground

-- Texture coordinates copied from Ascension's public AtlasInfo.lua. Each entry
-- selects one complete two-page background from CharacterAdvancementBackgrounds.
local ASCENSION_BACKGROUND_TCOORDS = {
    ALL         = { 0.39306640625, 0.7802734375, 0.68994140625, 0.82568359375 },
    GENERAL     = { 0.001953125,   0.38916015625, 0.68994140625, 0.82568359375 },
    WARRIOR     = { 0.001953125,   0.38916015625, 0.0009765625,  0.13671875 },
    PALADIN     = { 0.39306640625, 0.7802734375,  0.41455078125, 0.55029296875 },
    HUNTER      = { 0.001953125,   0.38916015625, 0.55224609375, 0.68798828125 },
    ROGUE       = { 0.39306640625, 0.7802734375,  0.2763671875,  0.412109375 },
    PRIEST      = { 0.39306640625, 0.7802734375,  0.55224609375, 0.68798828125 },
    DEATHKNIGHT = { 0.001953125,   0.38916015625, 0.138671875,   0.2744140625 },
    SHAMAN      = { 0.39306640625, 0.7802734375,  0.0009765625,  0.13671875 },
    MAGE        = { 0.001953125,   0.38916015625, 0.41455078125, 0.55029296875 },
    WARLOCK     = { 0.39306640625, 0.7802734375,  0.138671875,   0.2744140625 },
    DRUID       = { 0.001953125,   0.38916015625, 0.2763671875,  0.412109375 },
}

local function ApplyAscensionBackground(classToken)
    if not advancementBackground then return end
    local coords = ASCENSION_BACKGROUND_TCOORDS[classToken] or ASCENSION_BACKGROUND_TCOORDS.ALL
    advancementBackground:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
end

-- Custom Grimoire Window Frame
local SpellDraftBookFrame
local currentPage = 1
-- SpellCraft opens as a character summary: all learned skills on the left and
-- confirmed talents on the right. The first tab remains the full skill pool.
local activeClass = "GENERAL"
local catalogStatusFilter = "LEARNED"
local catalogTypeFilter = "ALL"
local filteredSpells = {}
local buttons = {}
local tabs = {}
local catalogGroups
local catalogExpanded = false
local catalogToolbar
local catalogExpandBtn
local talentsTitleText
local leftPanelBg
local rightPanelBg
local catalogParchmentBackground
local catalogReferencePageLeft
local catalogReferencePageRight
local sectionTitleBandLeft
local sectionTitleBandRight
local centerDivider
local catalogLeftChapterText
local catalogRightChapterText
local catalogLeftChapterRule
local catalogRightChapterRule
local catalogLeftLeafText
local catalogRightLeafText
local catalogPageTurnFeedback

local function GetCatalogPageSize()
    return catalogExpanded and 18 or 12
end

-- The reference spellbook fades between physical pages. Recreate that
-- interaction rhythm with a lightweight stock-texture edge flash instead of
-- importing retail animation atlases or mixins that do not exist on 3.3.5.
local function PlayCatalogPageFeedback(direction)
    if not catalogExpanded or not catalogPageTurnFeedback then return end
    local frame = catalogPageTurnFeedback
    local glow = direction == "PREV" and frame.leftGlow or frame.rightGlow
    if not glow then return end

    if frame.leftGlow then frame.leftGlow:Hide() end
    if frame.rightGlow then frame.rightGlow:Hide() end
    frame.elapsed = 0
    frame.activeGlow = glow
    glow:SetAlpha(0.32)
    glow:Show()
    frame:Show()
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        local progress = self.elapsed / 0.22
        if progress >= 1 then
            if self.activeGlow then self.activeGlow:Hide() end
            self.activeGlow = nil
            self:SetScript("OnUpdate", nil)
            self:Hide()
        elseif self.activeGlow then
            self.activeGlow:SetAlpha(0.32 * (1 - progress))
        end
    end)
end

local function LoadCatalogPreferences()
    local saved = SpellDraftDB and SpellDraftDB.catalogFilters
    if type(saved) ~= "table" then return end
    if saved.status == "ALL" or saved.status == "LEARNED" or saved.status == "UNLEARNED" then
        catalogStatusFilter = saved.status
    end
    if saved.type == "ALL" or saved.type == "ACTIVE" or saved.type == "PASSIVE" then
        catalogTypeFilter = saved.type
    end
end

local function SaveCatalogPreferences()
    SpellDraftDB = SpellDraftDB or {}
    SpellDraftDB.catalogFilters = SpellDraftDB.catalogFilters or {}
    SpellDraftDB.catalogFilters.status = catalogStatusFilter
    SpellDraftDB.catalogFilters.type = catalogTypeFilter
end

local searchBox
local pageText
local prevPageBtn
local nextPageBtn
local pageNavigationFrame
local statusFilterBtn
local typeFilterBtn
local languageBtn
local languageMenu
local SpellDraftTalentsFrame
local SpellDraftTalentsScrollFrame
local SpellDraftTalentsScrollChild
local talentSearchBox
local talentSearchResultBtn
local talentSearchMatch
local talentSearchTargetSpellId
local talentSortBtn
local talentSortMenu
local talentSortMode = "LEARNED_ASC"
local grimoireTitleText
local prestigeText
local rerollsText
local bansText
local draftsText

local LOCKED_TALENTS = {
    -- DEATHKNIGHT (21)
    [61154] = true, [49028] = true, [55050] = true, [49016] = true, [49005] = true, [48982] = true, [55233] = true, [49189] = true,
    [49796] = true, [49143] = true, [49184] = true, [49203] = true, [49039] = true, [51271] = true, [51052] = true, [49222] = true,
    [49158] = true, [63560] = true, [49146] = true, [55090] = true, [49206] = true,
    -- DRUID (14)
    [33831] = true, [5570] = true, [24858] = true, [48505] = true, [50516] = true, [50334] = true, [49377] = true, [33917] = true,
    [37116] = true, [61336] = true, [17116] = true, [18562] = true, [65139] = true, [48438] = true,
    -- HUNTER (13)
    [53270] = true, [19574] = true, [19577] = true, [19434] = true, [53209] = true, [23989] = true, [34490] = true, [19506] = true,
    [3674] = true, [19306] = true, [53301] = true, [19503] = true, [19386] = true,
    -- MAGE (16)
    [44425] = true, [12042] = true, [54646] = true, [12043] = true, [31589] = true, [11113] = true, [11129] = true, [31661] = true,
    [64353] = true, [44457] = true, [11366] = true, [11958] = true, [44572] = true, [11426] = true, [12472] = true, [31687] = true,
    -- PALADIN (14)
    [31821] = true, [53563] = true, [20216] = true, [31842] = true, [20473] = true, [31935] = true, [20911] = true, [64205] = true,
    [53595] = true, [20925] = true, [35395] = true, [53385] = true, [20066] = true, [20375] = true,
    -- PRIEST (15)
    [14751] = true, [33206] = true, [47540] = true, [10060] = true, [34861] = true, [19236] = true, [47788] = true, [724] = true,
    [47585] = true, [15407] = true, [64044] = true, [15473] = true, [15487] = true, [15286] = true, [34914] = true,
    -- ROGUE (13)
    [14177] = true, [51662] = true, [1329] = true, [13750] = true, [13877] = true, [51690] = true, [14251] = true, [14278] = true,
    [16511] = true, [14183] = true, [14185] = true, [51713] = true, [36554] = true,
    -- SHAMAN (15)
    [16166] = true, [51490] = true, [30706] = true, [30798] = true, [51533] = true, [60103] = true, [30823] = true, [16268] = true,
    [17364] = true, [51886] = true, [974] = true, [16190] = true, [16188] = true, [61295] = true, [55198] = true,
    -- WARLOCK (13)
    [18223] = true, [18220] = true, [48181] = true, [30108] = true, [47193] = true, [18708] = true, [59672] = true, [19028] = true,
    [30146] = true, [50796] = true, [17962] = true, [17877] = true, [30283] = true,
    -- WARRIOR (13)
    [46924] = true, [12294] = true, [12328] = true, [23881] = true, [12292] = true, [60970] = true, [12323] = true, [46917] = true,
    [12809] = true, [20243] = true, [12975] = true, [46968] = true, [50720] = true,
}

-- 3.3.5-safe lock texture: SetTexture returns nil for missing files, so try
-- known-good paths in order and keep the first one that loads.
local function ApplyLockTexture(tex)
    if tex:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-LOCK") then
        tex:SetTexCoord(0, 0.71875, 0, 0.875)
        return
    end
    tex:SetTexCoord(0, 1, 0, 1)
    if not tex:SetTexture("Interface\\Buttons\\LockButton-Locked-Up") then
        tex:SetTexture("Interface\\Icons\\INV_Misc_Key_03")
    end
end

-- Shifted tier gating: Tier 0 unlocks at level 1, Tier N at level N*5
local function GetTalentReqLevel(talent)
    if talent.row and talent.row > 0 then
        return talent.row * 5
    end
    return 1
end

-- ----------------------------------------------------------------------------
-- Scanner, Rank Consolidation, and Refresh Logic (WotLK 3.3.5a Compatible)
-- ----------------------------------------------------------------------------

local SpellDraftDataByName = nil

local function GetSpellMetadata(spellId, spellName)
    if not SpellDraftData then return nil end
    
    -- 1. Direct lookup by ID
    local meta = SpellDraftData[spellId]
    if meta then return meta end
    
    -- 2. Build name cache on demand if not already built
    if not SpellDraftDataByName then
        SpellDraftDataByName = {}
        for id, m in pairs(SpellDraftData) do
            if m.name then
                local existing = SpellDraftDataByName[m.name]
                if not existing or (m.rarity and m.rarity <= MAX_DRAFT_RARITY and (not existing.rarity or existing.rarity > MAX_DRAFT_RARITY)) then
                    SpellDraftDataByName[m.name] = m
                end
            end
        end
    end

    -- 3. Fallback to name-based lookup (e.g. for higher ranks of spells)
    return SpellDraftDataByName[spellName]
end

local function CatalogGroupKey(spellId, metadata)
    local classToken = metadata and metadata.class or "GENERAL"
    local canonicalName = metadata and metadata.name or tostring(spellId)
    local displayOverride = GetSpellDisplayOverride(spellId)
    if displayOverride and displayOverride.name then canonicalName = displayOverride.name end
    return classToken .. "|" .. string.lower(canonicalName)
end

-- Some native talent roots are implemented as talent-owned Aura records and
-- do not carry SPELL_ATTR0_PASSIVE in Spell.dbc.  They still have no usable
-- action and must be rendered as passive in the classless catalog.  Keep this
-- small semantic override separate from the generated DBC flag table.
local CATALOG_PASSIVE_OVERRIDES = {
    [49146] = true, -- On a Pale Horse / 死神降临 rank 1
    [51267] = true, -- On a Pale Horse / 死神降临 rank 2
}

local function IsCatalogPassive(spellId)
    spellId = tonumber(spellId)
    if not spellId then return false end
    if CATALOG_PASSIVE_OVERRIDES[spellId] then return true end
    if SpellDraftCatalogPassive and SpellDraftCatalogPassive[spellId] == true then return true end

    -- Higher talent ranks are not all present in SpellData.lua.  Inherit the
    -- first-rank classification so a server-authoritative rank ID cannot turn
    -- an acquired passive into an active card.
    local mapped = SpellDraftTalentRankMap and SpellDraftTalentRankMap[spellId]
    local firstRankSpellId = mapped and tonumber(mapped[1])
    return firstRankSpellId and firstRankSpellId ~= spellId
        and (CATALOG_PASSIVE_OVERRIDES[firstRankSpellId]
            or (SpellDraftCatalogPassive and SpellDraftCatalogPassive[firstRankSpellId] == true))
        or false
end

local function BuildCatalogGroups()
    if catalogGroups then return catalogGroups end

    local byKey = {}
    for spellId, metadata in pairs(SpellDraftData or {}) do
        if metadata.rarity
            and metadata.rarity <= MAX_DRAFT_RARITY
            and not (SpellDraftCatalogExcluded and SpellDraftCatalogExcluded[spellId])
        then
            local key = CatalogGroupKey(spellId, metadata)
            local group = byKey[key]
            if not group then
                group = {
                    key = key,
                    class = metadata.class or "GENERAL",
                    canonicalName = metadata.name,
                    representativeId = spellId,
                    rarity = metadata.rarity,
                    spellIds = {},
                    passive = false,
                }
                byKey[key] = group
            end

            table.insert(group.spellIds, spellId)
            if spellId < group.representativeId then group.representativeId = spellId end
            if metadata.rarity < group.rarity then group.rarity = metadata.rarity end
            if IsCatalogPassive(spellId) then group.passive = true end
        end
    end

    -- SpellData.lua intentionally keeps one catalog row per ability, while
    -- the authoritative acquired stream sends the exact learned rank.  Attach
    -- every Talent.dbc rank ID to its first-rank catalog group; otherwise a
    -- Tome upgrade (for example 49146 -> 51267) disappears from "Learned"
    -- because the higher ID cannot be matched to any catalog card.
    for rankSpellId, mapped in pairs(SpellDraftTalentRankMap or {}) do
        rankSpellId = tonumber(rankSpellId)
        local firstRankSpellId = mapped and tonumber(mapped[1])
        local firstMetadata = firstRankSpellId and SpellDraftData and SpellDraftData[firstRankSpellId]
        if rankSpellId and firstMetadata and firstMetadata.rarity
            and firstMetadata.rarity <= MAX_DRAFT_RARITY
            and not (SpellDraftCatalogExcluded and SpellDraftCatalogExcluded[firstRankSpellId])
        then
            local group = byKey[CatalogGroupKey(firstRankSpellId, firstMetadata)]
            if group then
                local alreadyIncluded = false
                for _, existingSpellId in ipairs(group.spellIds) do
                    if existingSpellId == rankSpellId then
                        alreadyIncluded = true
                        break
                    end
                end
                if not alreadyIncluded then table.insert(group.spellIds, rankSpellId) end
                if IsCatalogPassive(rankSpellId) then group.passive = true end
            end
        end
    end

    catalogGroups = {}
    for _, group in pairs(byKey) do
        table.sort(group.spellIds)
        table.insert(catalogGroups, group)
    end
    return catalogGroups
end

local function PlayerHasNamedBuff(spellName)
    if not spellName or spellName == "" or not UnitBuff then return false end
    for auraIndex = 1, 40 do
        local auraName = UnitBuff("player", auraIndex)
        if not auraName then break end
        if auraName == spellName then return true end
    end
    return false
end

local function RefreshVisibleCatalogEffects()
    if not SpellDraftBookFrame or not SpellDraftBookFrame:IsShown() then return end
    for _, btn in ipairs(buttons) do
        if btn:IsShown() and btn.spellId then
            if btn.cooldown and CooldownFrame_Set then
                local start, duration, enabled = 0, 0, 0
                if btn.known and not btn.passive and btn.slot and GetSpellCooldown then
                    start, duration, enabled = GetSpellCooldown(btn.slot, "spell")
                end
                CooldownFrame_Set(btn.cooldown, start or 0, duration or 0, enabled or 0)
            end
            if btn.activeGlow then
                local glowing = btn.known and not btn.passive and PlayerHasNamedBuff(btn.spellName)
                if glowing then btn.activeGlow:Show() else btn.activeGlow:Hide() end
            end
        else
            if btn.cooldown and CooldownFrame_Set then CooldownFrame_Set(btn.cooldown, 0, 0, 0) end
            if btn.activeGlow then btn.activeGlow:Hide() end
        end
    end
end
-- Expose this helper through the existing SpellDraft table so the very large
-- InitializeGrimoire function does not consume another Lua 5.1 upvalue slot.
SpellDraft.RefreshVisibleCatalogEffects = RefreshVisibleCatalogEffects

function SpellDraft.RefreshSpellBook()
    if not SpellDraftBookFrame or not SpellDraftBookFrame:IsShown() then return end
    if InCombatLockdown() then
        SpellDraftBookFrame.catalogPendingRefresh = true
        return
    end
    
    -- 1. Scan the native spellbook. Slot indexes are authoritative for dragging
    -- active learned spells onto an action bar on a 3.3.5 client.
    local learnedById = {}
    local learnedByGroup = {}
    -- Cross-class passive spells (Titan's Grip is the most visible example)
    -- are persisted by SpellDraft but are not guaranteed to be enumerated by
    -- the stock 3.3.5 spellbook API. SCTState is the server-authoritative list
    -- of acquired draft/tome spells, so keep it as a second learned source.
    local serverKnownById = {}
    if type(SpellDraft.DraftedTalents) == "table" then
        for _, knownSpellId in ipairs(SpellDraft.DraftedTalents) do
            knownSpellId = tonumber(knownSpellId)
            if knownSpellId then
                serverKnownById[knownSpellId] = true
            end
        end
    end
    local numTabs = GetNumSpellTabs()

    for i = 1, numTabs do
        local tabName, texture, offset, numSlots = GetSpellTabInfo(i)

        for j = 1, numSlots do
            local index = offset + j

            local success, err = pcall(function()
                local spellName, spellSubName = GetSpellName(index, "spell")
                local link = GetSpellLink(index, "spell")

                if link then
                    local spellId = tonumber(link:match("spell:(%d+)"))
                    if spellId then
                        local metadata = GetSpellMetadata(spellId, spellName)
                        if metadata and metadata.rarity and metadata.rarity <= MAX_DRAFT_RARITY then
                            local isPassive = false
                            if IsPassiveSpell then
                                local passiveOK, passiveResult = pcall(IsPassiveSpell, index, "spell")
                                isPassive = passiveOK and passiveResult == true
                            end
                            isPassive = isPassive or IsCatalogPassive(spellId)

                            local displayOverride = GetSpellDisplayOverride(spellId)
                            local learned = {
                                spellId = spellId,
                                slot = index,
                                name = spellName,
                                displayName = GetSpellDisplayName(spellId, spellName),
                                usage = displayOverride and L(displayOverride.usage) or nil,
                                subtext = spellSubName,
                                rarity = metadata.rarity,
                                class = metadata.class,
                                passive = isPassive,
                            }
                            learnedById[spellId] = learned
                            -- Later/higher spellbook ranks replace earlier ranks in the
                            -- collapsed ability group.
                            learnedByGroup[CatalogGroupKey(spellId, metadata)] = learned
                        end
                    end
                end
            end)

            if not success and DEBUG then print("[SpellDraftBook] Error scanning slot " .. tostring(index) .. ": " .. tostring(err)) end
        end
    end

    -- 2. Compile the complete draft-pool catalog, collapsed by class + ability
    -- name so a rank chain occupies one card.
    filteredSpells = {}
    local searchPattern = string.lower(searchBox:GetText() or "")
    local catalogTotal = 0
    local catalogKnown = 0

    for _, group in ipairs(BuildCatalogGroups()) do
        local learned = learnedByGroup[group.key]
        if not learned then
            for _, spellId in ipairs(group.spellIds) do
                if learnedById[spellId] then learned = learnedById[spellId] end
            end
        end

        -- A server-confirmed acquired spell may be absent from the native
        -- spellbook enumeration solely because its original class differs
        -- from the character's class. Show it as learned in the left catalog.
        -- There is deliberately no native slot in this synthetic record:
        -- passive spells need no action-bar drag, while active spells will use
        -- their real slot whenever the client exposes one.
        if not learned then
            for _, spellId in ipairs(group.spellIds) do
                if serverKnownById[spellId] then
                    local knownName, knownSubName = GetSpellInfo(spellId)
                    local metadata = GetSpellMetadata(spellId, knownName)
                    local displayOverride = GetSpellDisplayOverride(spellId)
                    learned = {
                        spellId = spellId,
                        slot = nil,
                        name = knownName or group.canonicalName or ("Spell " .. tostring(spellId)),
                        displayName = GetSpellDisplayName(spellId, knownName),
                        usage = displayOverride and L(displayOverride.usage) or nil,
                        subtext = knownSubName,
                        rarity = (metadata and metadata.rarity) or group.rarity,
                        class = (metadata and metadata.class) or group.class,
                        passive = IsCatalogPassive(spellId) or group.passive,
                        serverConfirmed = true,
                    }
                    break
                end
            end
        end

        local spellId = learned and learned.spellId or group.representativeId
        local spellName, spellSubName = GetSpellInfo(spellId)
        spellName = spellName or group.canonicalName or ("Spell " .. tostring(spellId))
        local displayName = GetSpellDisplayName(spellId, spellName)
        local passive = (learned and learned.passive) or group.passive
        local known = learned ~= nil
        -- GENERAL is the learned character summary rather than another class
        -- bucket, so it spans every class while the learned-only filter keeps
        -- the left page focused on the player's actual build.
        local matchesClass = activeClass == "ALL" or activeClass == "GENERAL" or group.class == activeClass
        if matchesClass then
            catalogTotal = catalogTotal + 1
            if known then catalogKnown = catalogKnown + 1 end
        end
        local matchesStatus = catalogStatusFilter == "ALL"
            or (catalogStatusFilter == "LEARNED" and known)
            or (catalogStatusFilter == "UNLEARNED" and not known)
        local matchesType = catalogTypeFilter == "ALL"
            or (catalogTypeFilter == "ACTIVE" and not passive)
            or (catalogTypeFilter == "PASSIVE" and passive)
        local searchable = string.lower(displayName .. " " .. tostring(spellId))
        local matchesSearch = searchPattern == "" or string.find(searchable, searchPattern, 1, true)

        if matchesClass and matchesStatus and matchesType and matchesSearch then
            table.insert(filteredSpells, {
                spellId = spellId,
                slot = known and not passive and learned.slot or nil,
                name = spellName,
                displayName = displayName,
                usage = learned and learned.usage or nil,
                subtext = learned and learned.subtext or spellSubName,
                rarity = group.rarity,
                class = group.class,
                passive = passive,
                known = known,
                rankCount = #group.spellIds,
            })
        end
    end

    if grimoireTitleText then
        grimoireTitleText:SetText("|cffffd36a" .. L("Skill Catalog")
            .. " · " .. tostring(catalogKnown) .. "/" .. tostring(catalogTotal) .. "|r")
    end

    -- Learned abilities first, then active/passive, rarity, and name.
    table.sort(filteredSpells, function(a, b)
        if a.known ~= b.known then return a.known end
        if a.passive ~= b.passive then return not a.passive end
        if a.rarity ~= b.rarity then return a.rarity < b.rarity end
        return (a.displayName or a.name) < (b.displayName or b.name)
    end)

    -- 3. Set paging details.
    local totalSpells = #filteredSpells
    local pageSize = GetCatalogPageSize()
    local totalPages = math.max(1, math.ceil(totalSpells / pageSize))
    if currentPage > totalPages then
        currentPage = totalPages
    end
    
    pageText:SetText(L(catalogExpanded and "Spread %d of %d" or "Page %d of %d",
        currentPage, totalPages))
    if catalogLeftChapterText then
        catalogLeftChapterText:SetText(L("Chapter: %s", SpellDraft.ClassName(activeClass)))
    end
    if catalogRightChapterText then
        catalogRightChapterText:SetText(L("Learned %d of %d", catalogKnown, catalogTotal))
    end
    if catalogLeftLeafText and catalogRightLeafText then
        local leftLeaf = ((currentPage - 1) * 2) + 1
        catalogLeftLeafText:SetText(tostring(leftLeaf))
        catalogRightLeafText:SetText(tostring(leftLeaf + 1))
        if catalogExpanded and ((currentPage - 1) * pageSize + 10) <= totalSpells then
            catalogRightLeafText:Show()
        else
            catalogRightLeafText:Hide()
        end
    end
    
    if currentPage == 1 then
        prevPageBtn:Disable()
    else
        prevPageBtn:Enable()
    end
    if currentPage == totalPages then
        nextPageBtn:Disable()
    else
        nextPageBtn:Enable()
    end
    
    -- 4. Draw the 12 recycled cards.
    local startIdx = (currentPage - 1) * pageSize + 1
    for i = 1, #buttons do
        local idx = startIdx + (i - 1)
        local btn = buttons[i]
        
        if i <= pageSize and idx <= totalSpells then
            local spell = filteredSpells[idx]
            btn.spellId = spell.spellId
            btn.slot = spell.slot
            btn.known = spell.known
            btn.passive = spell.passive
            btn.spellName = spell.name
            btn.rankCount = spell.rankCount or 1
            btn.name:SetText(GetSpellDisplayName(spell.spellId, spell.displayName or spell.name))

            -- Translate at render time.  The catalog is created before the
            -- player's language choice may be finalized, so caching L(...)
            -- in RARITY_NAMES would leave English labels on Chinese clients.
            local rName = L(RARITY_NAMES[spell.rarity] or "Common")
            local rColor = RARITY_COLORS[spell.rarity] or "|cffb0b0b0"
            local rankText = spell.subtext or ""
            local displayOverride = GetSpellDisplayOverride(spell.spellId)
            local usage = displayOverride and L(displayOverride.usage) or spell.usage
            if usage and usage ~= "" then
                rankText = rankText ~= "" and (rankText .. " · " .. usage) or usage
            end
            local typeText = spell.passive and L("Passive") or L("Active")
            local statusText = spell.known and L("Learned") or L("Unlearned")
            btn.subtext:SetText((rankText ~= "" and (rankText .. " · ") or "")
                .. statusText .. " · " .. rColor .. rName .. "|r")

            -- War Within-inspired information hierarchy: interaction type is
            -- a dedicated pill instead of being buried in the metadata line.
            -- This is visual only; the authoritative passive flag still comes
            -- from the existing SpellDraft catalog projection above.
            if btn.typeBadgeText then btn.typeBadgeText:SetText(typeText) end
            if btn.typeBadgeBg then
                if spell.passive then
                    btn.typeBadgeBg:SetVertexColor(0.42, 0.20, 0.62, spell.known and 0.92 or 0.38)
                else
                    btn.typeBadgeBg:SetVertexColor(0.08, 0.38, 0.68, spell.known and 0.92 or 0.38)
                end
            end
            if btn.typeHoverGlow then
                btn.typeHoverGlow:SetVertexColor(spell.passive and 0.72 or 0.18,
                    spell.passive and 0.32 or 0.68,
                    spell.passive and 1.0 or 1.0, 0.95)
                btn.typeHoverGlow:Hide()
            end
            if btn.cardHover then
                if spell.passive then btn.cardHover:SetVertexColor(0.42, 0.18, 0.60, 0.22)
                else btn.cardHover:SetVertexColor(0.08, 0.36, 0.68, 0.20) end
            end
            if btn.rankChainText then
                if (spell.rankCount or 1) > 1 then
                    btn.rankChainText:SetText("x" .. tostring(spell.rankCount))
                    btn.rankChainText:Show()
                else
                    btn.rankChainText:Hide()
                end
            end

            local _, _, iconTexture = GetSpellInfo(spell.spellId)
            iconTexture = iconTexture or (FALLBACK_SPELLS[spell.spellId] and FALLBACK_SPELLS[spell.spellId].icon) or "Interface\\Icons\\INV_Misc_QuestionMark"
            local displayIcon = btn.icon
            if spell.passive and btn.iconRound and SetPortraitToTexture then
                local roundOK = pcall(SetPortraitToTexture, btn.iconRound, iconTexture)
                if roundOK then
                    btn.icon:Hide()
                    btn.iconRound:Show()
                    displayIcon = btn.iconRound
                else
                    btn.iconRound:Hide()
                    btn.icon:Show()
                    btn.icon:SetTexture(iconTexture)
                end
            else
                btn.iconRound:Hide()
                btn.icon:Show()
                btn.icon:SetTexture(iconTexture)
            end

            if displayIcon.SetDesaturated then displayIcon:SetDesaturated(not spell.known) end
            displayIcon:SetAlpha(spell.known and 1.0 or 0.35)
            btn.border:SetTexture(spell.passive
                and (ASCENSION_TEXTURE_PATH .. "SpellKitSpellBorder_Talent")
                or (ASCENSION_TEXTURE_PATH .. "SpellKitSpellBorder"))
            if spell.passive then btn.slotBg:Hide() else btn.slotBg:Show() end
            btn.rowBg:SetVertexColor(spell.known and 1.0 or 0.35, spell.known and 1.0 or 0.35, spell.known and 1.0 or 0.35, spell.known and 0.92 or 0.55)
            btn.name:SetTextColor(spell.known and 1.0 or 0.48, spell.known and 0.82 or 0.48, spell.known and 0.1 or 0.48)
            btn.subtext:SetTextColor(spell.known and 1.0 or 0.55, spell.known and 1.0 or 0.55, spell.known and 1.0 or 0.55)

            local color = spell.known and RARITY_RGB[spell.rarity] or { r = 0.3, g = 0.3, b = 0.3 }
            if color then
                btn.border:SetVertexColor(color.r, color.g, color.b)
                if btn.rarityRail then
                    btn.rarityRail:SetVertexColor(color.r, color.g, color.b, spell.known and 0.95 or 0.38)
                    btn.rarityRail:Show()
                end
                btn.border:Show()
            else
                if btn.rarityRail then btn.rarityRail:Hide() end
                btn.border:Hide()
            end
            
            if spell.known and not spell.passive then
                btn:SetAttribute("type", "spell")
                btn:SetAttribute("spell", spell.name)
            else
                btn:SetAttribute("type", nil)
                btn:SetAttribute("spell", nil)
            end

            btn:Show()
        else
            btn.spellId = nil
            btn.slot = nil
            btn.known = nil
            btn.passive = nil
            btn.spellName = nil
            btn.rankCount = nil
            btn:SetAttribute("type", nil)
            btn:SetAttribute("spell", nil)
            btn.border:Hide()
            if btn.rarityRail then btn.rarityRail:Hide() end
            if btn.typeHoverGlow then btn.typeHoverGlow:Hide() end
            btn:Hide()
        end
    end
    RefreshVisibleCatalogEffects()
end

-- ----------------------------------------------------------------------------
-- Bottom Tabs - Independent Grimoire panels (Grimoire, Talents)
-- ----------------------------------------------------------------------------

local specFrames = {}
local talentsFrameCreated = false
local talentDBInitialized = false
local LocalizedNameToSpellId = {}
local TalentsByClassAndSpec = {}
local currentRanks = {}
local stagedTalentRanks = {}
local talentCommitPending = false
local talentCommitSerial = 0
local talentCommitToken = nil
local talentCommitSnapshot = nil
local talentRefundPending = false
local talentRefundSerial = 0
local talentRefundToken = nil
local talentRefundDialog
local confirmedTalentCardPool = {}

-- General-page ordering is intentionally client-side: it changes only how
-- confirmed cards are presented and never mutates ranks, Pending or server
-- authority.  Learned order is stored per character. Existing characters are
-- seeded once from the stable class/spec/name view; every later acquisition is
-- appended, so "first/newest learned" becomes exact from this version onward.
local TALENT_SORT_OPTIONS = {
    { key = "LEARNED_ASC", label = "First learned" },
    { key = "LEARNED_DESC", label = "Newest learned" },
    { key = "CLASS", label = "Class and spec" },
    { key = "EFFECT", label = "Attribute or effect" },
    { key = "RANK", label = "Current rank" },
    { key = "NAME", label = "Talent name" },
}

-- Extensible display metadata for verified chains. Unknown talents remain in
-- Other Effects; adding a future chain here affects sorting only, never its
-- gameplay or persistence contract.
local TALENT_EFFECT_GROUPS = {
    [20257] = "Intellect", [17485] = "Intellect", [11232] = "Intellect", [18551] = "Intellect",
    [20262] = "Strength", [46865] = "Multiple Attributes", [49006] = "Multiple Attributes",
    [29140] = "Multiple Attributes", [34475] = "Multiple Attributes",
    [34151] = "Spirit", [44397] = "Spirit",
    [19255] = "Stamina", [18697] = "Stamina", [16252] = "Stamina",
    [19168] = "Agility",
    [49220] = "Damage Mechanics", [49140] = "Damage Mechanics", [19426] = "Damage Mechanics",
}

local TALENT_EFFECT_ORDER = {
    ["Strength"] = 1, ["Agility"] = 2, ["Stamina"] = 3,
    ["Intellect"] = 4, ["Spirit"] = 5, ["Multiple Attributes"] = 6,
    ["Damage Mechanics"] = 7, ["Healing Mechanics"] = 8,
    ["Defense Mechanics"] = 9, ["Utility Mechanics"] = 10,
    ["Other Effects"] = 99,
}

local function GetTalentSortCharacterKey()
    return tostring(GetRealmName() or "") .. ":" .. tostring(UnitName("player") or "")
end

local function GetTalentLearnOrderState()
    SpellDraftDB = SpellDraftDB or {}
    SpellDraftDB.talentCardOrder = SpellDraftDB.talentCardOrder or {}
    local key = GetTalentSortCharacterKey()
    local state = SpellDraftDB.talentCardOrder[key]
    if type(state) ~= "table" then
        state = { nextOrder = 1, positions = {} }
        SpellDraftDB.talentCardOrder[key] = state
    end
    if type(state.positions) ~= "table" then state.positions = {} end
    state.nextOrder = math.max(1, tonumber(state.nextOrder) or 1)
    return state
end

local function SaveTalentSortMode(mode)
    SpellDraftDB = SpellDraftDB or {}
    SpellDraftDB.talentCardSortMode = mode
end

local function LoadTalentSortMode()
    local saved = SpellDraftDB and SpellDraftDB.talentCardSortMode
    for _, option in ipairs(TALENT_SORT_OPTIONS) do
        if saved == option.key then talentSortMode = saved return end
    end
    talentSortMode = "LEARNED_ASC"
end

local function GetTalentSortLabel()
    for _, option in ipairs(TALENT_SORT_OPTIONS) do
        if option.key == talentSortMode then return L(option.label) end
    end
    return L("First learned")
end

local function IsTalentMutationPending()
    return talentCommitPending or talentRefundPending
end

local function GetStagedTalentPointCount()
    local total = 0
    for _, count in pairs(stagedTalentRanks) do total = total + count end
    return total
end

local function GetPreviewTalentRank(firstRankSpellId)
    local previewRank = (currentRanks[firstRankSpellId] or 0) + (stagedTalentRanks[firstRankSpellId] or 0)
    -- Rendering must never display an impossible rank even if an old pending
    -- point briefly survives until the next authoritative reconciliation.
    local talent = SpellDraftTalentDB and SpellDraftTalentDB[firstRankSpellId]
    if talent and talent.maxRank then
        previewRank = math.min(previewRank, tonumber(talent.maxRank) or previewRank)
    end
    return math.max(0, previewRank)
end

local function ClearStagedTalentPlan()
    for spellId in pairs(stagedTalentRanks) do stagedTalentRanks[spellId] = nil end
end

-- Restored from the user-verified B0.10.1 fix.  The database/server rank is
-- authoritative: when a saved rank arrives, consume only the local pending
-- points that no longer fit, while retaining unrelated valid pending choices.
function SpellDraft.ReconcileStagedTalentRanks(authoritativeRanks)
    if type(authoritativeRanks) ~= "table" then return false end
    local changed = false
    for firstRankSpellId, stagedCount in pairs(stagedTalentRanks) do
        local talent = SpellDraftTalentDB and SpellDraftTalentDB[firstRankSpellId]
        local confirmedRank = tonumber(authoritativeRanks[firstRankSpellId]) or 0
        local maxRank = talent and tonumber(talent.maxRank) or confirmedRank + stagedCount
        local remainingCapacity = math.max(0, maxRank - confirmedRank)
        if stagedCount > remainingCapacity then
            if remainingCapacity > 0 then
                stagedTalentRanks[firstRankSpellId] = remainingCapacity
            else
                stagedTalentRanks[firstRankSpellId] = nil
            end
            changed = true
        end
    end
    if changed and SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
    end
    return changed
end

function SpellDraft.HandleTalentCommitResult(ok, detail, token)
    if not talentCommitPending then return end
    if token and talentCommitToken and tostring(token) ~= tostring(talentCommitToken) then return end
    talentCommitPending = false
    talentCommitToken = nil
    talentCommitSnapshot = nil
    if ok then
        ClearStagedTalentPlan()
        UIErrorsFrame:AddMessage(L("Talent plan confirmed."), 0.2, 1.0, 0.2, 1)
    else
        UIErrorsFrame:AddMessage(detail and detail ~= "" and detail or L("Talent confirmation failed."), 1.0, 0.2, 0.2, 1)
    end
    if SpellDraft.UpdateStatsDisplay then SpellDraft.UpdateStatsDisplay() end
    if SpellDraft.RefreshTalentsList then SpellDraft.RefreshTalentsList() end
end

local TALENT_REFUND_ERRORS = {
    not_draft = "You are not in Draft Mode.",
    combat = "You cannot refund talents in combat.",
    invalid = "The selected talent is invalid.",
    drafted_only = "Tome of Talents ranks cannot be refunded.",
    no_manual_rank = "This talent has no manually purchased rank to refund.",
    dependency = "Refund the dependent talent first.",
    essence = "You do not have enough Talent Essence.",
    essence_commit = "Talent Essence could not be committed. Nothing changed.",
    points = "Your Talent Point record is unavailable.",
    points_commit = "The Talent Point refund could not be saved. Nothing changed.",
    apply = "The lower talent rank could not be applied. Nothing changed.",
    failed = "Talent rank refund failed. Nothing changed.",
}

local function SetTalentRefundDialogPending(pending, statusText)
    if not talentRefundDialog then return end
    if pending then
        talentRefundDialog.acceptBtn:Disable()
        talentRefundDialog.cancelBtn:Disable()
    else
        talentRefundDialog.acceptBtn:Enable()
        talentRefundDialog.cancelBtn:Enable()
    end
    talentRefundDialog.status:SetText(statusText or "")
end

local function EnsureTalentRefundDialog()
    if talentRefundDialog then return talentRefundDialog end

    local dialog = CreateFrame("Frame", "SpellDraftTalentRefundDialog", UIParent)
    dialog:SetSize(390, 220)
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetFrameLevel(100)
    dialog:SetToplevel(true)
    dialog:EnableMouse(true)
    dialog:SetClampedToScreen(true)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    local title = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -20)
    title:SetText(L("Refund one confirmed rank"))

    local body = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", dialog, "TOPLEFT", 28, -52)
    body:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -28, -52)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    dialog.body = body

    local status = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    status:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 52)
    status:SetText("")
    dialog.status = status

    local acceptBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    acceptBtn:SetSize(110, 24)
    acceptBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -8, 20)
    acceptBtn:SetText(L("Confirm Refund"))
    dialog.acceptBtn = acceptBtn

    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    cancelBtn:SetSize(110, 24)
    cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 8, 20)
    cancelBtn:SetText(L("Cancel"))
    dialog.cancelBtn = cancelBtn

    cancelBtn:SetScript("OnClick", function()
        if talentRefundPending then return end
        dialog:Hide()
    end)

    acceptBtn:SetScript("OnClick", function()
        if talentRefundPending or not dialog.firstRankSpellId then return end
        if InCombatLockdown() then
            dialog.status:SetText("|cffff4444" .. L("You cannot refund talents in combat.") .. "|r")
            return
        end

        talentRefundSerial = talentRefundSerial + 1
        local safeTick = math.floor((GetTime() or 0) * 1000) % 10000000
        local token = safeTick * 100 + (talentRefundSerial % 100)
        talentRefundPending = true
        talentRefundToken = tostring(token)
        SetTalentRefundDialogPending(true, "|cffffcc00" .. L("Waiting for the server...") .. "|r")
        SendChatMessage("SC_REFUND_TALENT:" .. token .. ":" .. dialog.firstRankSpellId, "WHISPER", nil, UnitName("player"))
        if SpellDraft.UpdateStatsDisplay then SpellDraft.UpdateStatsDisplay() end

        local pendingToken = talentRefundToken
        if SpellDraft.After then
            SpellDraft.After(8.0, function()
                if talentRefundPending and talentRefundToken == pendingToken then
                    talentRefundPending = false
                    talentRefundToken = nil
                    SetTalentRefundDialogPending(false, "|cffff8844" .. L("Talent refund timed out. Nothing changed.") .. "|r")
                    if SpellDraft.UpdateStatsDisplay then SpellDraft.UpdateStatsDisplay() end
                end
            end)
        end
    end)

    dialog:Hide()
    talentRefundDialog = dialog
    return dialog
end

local function OpenTalentRefundDialog(talent)
    if IsTalentMutationPending() then
        UIErrorsFrame:AddMessage(L("Another talent change is in progress."), 1.0, 0.82, 0.2, 1)
        return
    end
    if GetStagedTalentPointCount() > 0 then
        UIErrorsFrame:AddMessage(L("Confirm or cancel pending talent points first."), 1.0, 0.82, 0.2, 1)
        return
    end
    if talent.locked then
        UIErrorsFrame:AddMessage(L("Tome of Talents ranks cannot be refunded."), 1.0, 0.2, 0.2, 1)
        return
    end

    local currentRank = currentRanks[talent.firstRankSpellId] or 0
    if currentRank <= 0 then return end
    local spellName = GetSpellInfo(talent.firstRankSpellId) or ("Spell #" .. talent.firstRankSpellId)
    local cost = math.max(0, tonumber(SpellDraft.TalentRefundCost) or 1)
    local essence = math.max(0, tonumber(SpellDraft.TalentEssence) or 0)
    local dialog = EnsureTalentRefundDialog()
    dialog.firstRankSpellId = talent.firstRankSpellId
    dialog.body:SetText(L(
        "Refund one rank of %s?\n\nCurrent rank: %d/%d\nAfter refund: %d/%d\nRefund: 1 Talent Point\nCost: %d Talent Essence\nCurrent Essence: %d",
        spellName, currentRank, talent.maxRank, currentRank - 1, talent.maxRank, cost, essence))
    SetTalentRefundDialogPending(false, "")
    dialog:Show()
end

function SpellDraft.HandleTalentRefundResult(ok, detail, token)
    if not talentRefundPending then return end
    if token and talentRefundToken and tostring(token) ~= tostring(talentRefundToken) then return end
    talentRefundPending = false
    talentRefundToken = nil

    if ok then
        -- SCTRefund detail is `targetRank:cost`.  The server sends success only
        -- after DB rank, live spell and passive Aura all match targetRank.
        -- Apply that verified rank immediately; the following SC_CHECK remains
        -- a full-snapshot reconciliation rather than the only visible update.
        local firstRankSpellId = talentRefundDialog and tonumber(talentRefundDialog.firstRankSpellId)
        local targetRank = tonumber(tostring(detail or ""):match("^(%d+)"))
        local talent = firstRankSpellId and SpellDraftTalentDB and SpellDraftTalentDB[firstRankSpellId]
        if firstRankSpellId and targetRank and targetRank >= 0
            and (not talent or targetRank <= (tonumber(talent.maxRank) or targetRank)) then
            local ranks = {}
            for spellId, rank in pairs(SpellDraft.ConfirmedTalentRanks or {}) do
                ranks[spellId] = rank
            end
            if targetRank > 0 then ranks[firstRankSpellId] = targetRank
            else ranks[firstRankSpellId] = nil end
            if SpellDraft.ApplyAuthoritativeTalentRanks then
                SpellDraft.ApplyAuthoritativeTalentRanks(ranks)
            else
                SpellDraft.ConfirmedTalentRanks = ranks
            end
        end
        if talentRefundDialog then talentRefundDialog:Hide() end
        UIErrorsFrame:AddMessage(L("One talent rank was refunded."), 0.2, 1.0, 0.2, 1)
        local playerName = UnitName("player")
        if playerName then SendChatMessage("SC_CHECK", "WHISPER", nil, playerName) end
    else
        local errorKey = tostring(detail or "failed"):match("^([^:]+)") or "failed"
        local messageKey = TALENT_REFUND_ERRORS[errorKey] or TALENT_REFUND_ERRORS.failed
        SetTalentRefundDialogPending(false, "|cffff4444" .. L(messageKey) .. "|r")
        UIErrorsFrame:AddMessage(L(messageKey), 1.0, 0.2, 0.2, 1)
    end
    if SpellDraft.UpdateStatsDisplay then SpellDraft.UpdateStatsDisplay() end
    if SpellDraft.RefreshTalentsList then SpellDraft.RefreshTalentsList() end
end

-- The specs list in order of classes
local CLASS_ORDER = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID"}
local CLASS_SPECS = {
    WARRIOR = {"Arms", "Fury", "Protection"},
    PALADIN = {"Holy", "Protection", "Retribution"},
    HUNTER = {"Beast Mastery", "Marksmanship", "Survival"},
    ROGUE = {"Assassination", "Combat", "Subtlety"},
    PRIEST = {"Discipline", "Holy", "Shadow"},
    DEATHKNIGHT = {"Blood", "Frost", "Unholy"},
    SHAMAN = {"Elemental", "Enhancement", "Restoration"},
    MAGE = {"Arcane", "Fire", "Frost"},
    WARLOCK = {"Affliction", "Demonology", "Destruction"},
    DRUID = {"Balance", "Feral Combat", "Restoration"}
}

-- Hex colors for classes
local CLASS_COLORS = {
    WARRIOR = "C79C6E", PALADIN = "F58CBA", HUNTER = "ABD473", ROGUE = "FFF569",
    PRIEST = "FFFFFF", DEATHKNIGHT = "C41F3B", SHAMAN = "0070DE", MAGE = "69CCF0",
    WARLOCK = "9482C9", DRUID = "FF7D0A"
}

local function InitializeTalentDB()
    if talentDBInitialized then return end
    if not SpellDraftTalentDB then return end
    
    for spellId, info in pairs(SpellDraftTalentDB) do
        local name = GetSpellInfo(spellId)
        if name then
            LocalizedNameToSpellId[name] = spellId
            info.name = name
        else
            info.name = "Unknown Talent " .. spellId
        end
        
        -- Group by class and spec
        local c = info.class
        local s = info.spec
        if not TalentsByClassAndSpec[c] then
            TalentsByClassAndSpec[c] = {}
        end
        if not TalentsByClassAndSpec[c][s] then
            TalentsByClassAndSpec[c][s] = {}
        end
        
        info.firstRankSpellId = spellId
        table.insert(TalentsByClassAndSpec[c][s], info)
    end
    talentDBInitialized = true
end

-- Search the complete Talent.dbc-derived client index, not only the class
-- currently being rendered.  This lets a player discover which class/spec a
-- talent belongs to before switching the top class tabs.
local function FindTalentSearchMatch(rawQuery)
    InitializeTalentDB()
    local query = string.lower((rawQuery or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    if query == "" or not SpellDraftTalentDB then return nil end

    local numericId = tonumber(query)
    local best, bestScore
    for firstRankSpellId, info in pairs(SpellDraftTalentDB) do
        local name = info.name or GetSpellInfo(firstRankSpellId) or ("Spell " .. firstRankSpellId)
        local loweredName = string.lower(name)
        local className = SpellDraft.ClassName(info.class) or info.class
        local specName = L(info.spec)
        local searchable = string.lower(table.concat({
            name, tostring(firstRankSpellId), info.class or "", className or "",
            info.spec or "", specName or ""
        }, " "))

        local score
        if numericId and numericId == firstRankSpellId then score = 0
        elseif loweredName == query then score = 1
        elseif string.sub(loweredName, 1, string.len(query)) == query then score = 2
        elseif string.find(loweredName, query, 1, true) then score = 3
        elseif string.find(searchable, query, 1, true) then score = 4 end

        if score and (not bestScore or score < bestScore
            or (score == bestScore and firstRankSpellId < best.firstRankSpellId)) then
            best = info
            bestScore = score
        end
    end
    return best
end

local function RefreshTalentSearchResult()
    if not talentSearchResultBtn or not talentSearchBox then return end
    talentSearchMatch = FindTalentSearchMatch(talentSearchBox:GetText())
    if not talentSearchMatch then
        talentSearchResultBtn:SetText(L("No matching talent"))
        talentSearchResultBtn:Disable()
        return
    end

    local name = talentSearchMatch.name or GetSpellInfo(talentSearchMatch.firstRankSpellId)
        or ("Spell " .. talentSearchMatch.firstRankSpellId)
    talentSearchResultBtn:SetText(string.format("%s / %s · %s",
        SpellDraft.ClassName(talentSearchMatch.class), L(talentSearchMatch.spec), name))
    talentSearchResultBtn:Enable()
end

local function LocateTalentInTree(talent)
    if not talent then return end
    activeClass = talent.class
    talentSearchTargetSpellId = talent.firstRankSpellId
    ApplyAscensionBackground(activeClass)
    for index, classInfo in ipairs(tabClasses) do
        if tabs[index] then tabs[index]:SetChecked(classInfo.value == activeClass) end
    end
    currentPage = 1
    SpellDraft.RefreshSpellBook()
    SpellDraft.RefreshTalentsList()

    local specIndex = 1
    for index, specName in ipairs(CLASS_SPECS[activeClass] or {}) do
        if specName == talent.spec then specIndex = index break end
    end
    if SpellDraftTalentsScrollFrame then
        local targetOffset = (specIndex - 1) * 616 + math.max(0, talent.row or 0) * 52
        SpellDraftTalentsScrollFrame:SetVerticalScroll(math.max(0, targetOffset - 34))
    end
    PlaySound("igAbilitiesOpen")
end

local function LocateTalentSearchResult()
    LocateTalentInTree(talentSearchMatch)
end

local function RecalculateTalentRanks()
    InitializeTalentDB()
    if not SpellDraftTalentDB then return end
    
    -- Clear current ranks
    for spellId in pairs(SpellDraftTalentDB) do
        currentRanks[spellId] = 0
    end

    -- Prefer the explicit server frame (first-rank spell ID -> confirmed
    -- rank).  This survives panel close/reload and avoids name collisions or
    -- arrival-order races in the legacy list of highest-rank spell IDs.
    local authoritative = SpellDraft.ConfirmedTalentRanks
    if type(authoritative) == "table" then
        for firstRankSpellId, rankNum in pairs(authoritative) do
            firstRankSpellId, rankNum = tonumber(firstRankSpellId), tonumber(rankNum)
            if firstRankSpellId and rankNum and SpellDraftTalentDB[firstRankSpellId] then
                currentRanks[firstRankSpellId] = rankNum
            end
        end
    end

    -- Important ownership boundary:
    --   ConfirmedTalentRanks = adjustable ranks rendered on the right page.
    --   DraftedTalents        = learned active/passive abilities rendered in
    --                           the left catalog.
    -- Never merge DraftedTalents into currentRanks. Doing so makes Tome skills
    -- flash on the right page until the next rank packet removes them.
end

-- An authoritative talent sync can prove a successful commit even when its
-- dedicated acknowledgement was delayed or dropped.
function SpellDraft.TryResolveTalentCommitFromSync()
    if not talentCommitPending or not talentCommitSnapshot then return end
    RecalculateTalentRanks()
    for firstRankSpellId, snapshot in pairs(talentCommitSnapshot) do
        if (currentRanks[firstRankSpellId] or 0) < snapshot.targetRank then
            return
        end
    end
    SpellDraft.HandleTalentCommitResult(true, nil, talentCommitToken)
end

local function GetKnownSpellId(talent)
    if not SpellDraft.DraftedTalents then return talent.firstRankSpellId end
    local bestSpellId = talent.firstRankSpellId
    local bestRank = 0
    for _, sid in ipairs(SpellDraft.DraftedTalents) do
        local mapped = SpellDraftTalentRankMap and SpellDraftTalentRankMap[sid]
        if mapped then
            if mapped[1] == talent.firstRankSpellId and mapped[2] > bestRank then
                bestSpellId, bestRank = sid, mapped[2]
            end
        elseif bestRank == 0 then
            local name = GetSpellInfo(sid)
            if name == talent.name then
                bestSpellId = sid
            end
        end
    end
    return bestSpellId
end

-- Resolve the exact spell record for the rank currently shown in the talent
-- preview.  A talent tooltip is rank-specific in the 3.3.5 client: linking the
-- first-rank spell forever makes a staged 5/5 talent still say 2% instead of
-- 10%, even though the rank counter itself is correct.
local talentRankSpellCache = {}
local function GetTalentSpellIdForRank(firstRankSpellId, rank)
    rank = math.max(1, tonumber(rank) or 1)
    local byRank = talentRankSpellCache[firstRankSpellId]
    if not byRank then
        byRank = {}
        for spellId, mapped in pairs(SpellDraftTalentRankMap or {}) do
            if mapped[1] == firstRankSpellId then
                byRank[mapped[2]] = spellId
            end
        end
        talentRankSpellCache[firstRankSpellId] = byRank
    end
    return byRank[rank] or firstRankSpellId
end

local function ShowTalentTooltip(button)
    local talent = button and button.talent
    if not talent then return end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local previewRank = GetPreviewTalentRank(talent.firstRankSpellId)
    local spellId = GetTalentSpellIdForRank(talent.firstRankSpellId, previewRank)
    GameTooltip:SetHyperlink("spell:" .. spellId)

    if talent.locked then
        GameTooltip:AddLine("|cffbbbbbb[" .. L("Locked: Requires Tome of Talents") .. "]|r")
    else
        local reqLevel = GetTalentReqLevel(talent)
        if UnitLevel("player") < reqLevel then
            GameTooltip:AddLine("|cffff2020" .. L("Requires level %d", reqLevel) .. "|r")
        end
    end

    -- SpellDraft's classless talent nodes are independent.  The DBC
    -- prerequisite graph belongs to the native/classic talent window and
    -- must not leak into this custom book as a red requirement.
    if not talent.locked and previewRank > 0 then
        if (stagedTalentRanks[talent.firstRankSpellId] or 0) > 0 then
            GameTooltip:AddLine("\n" .. L("Right-click to cancel one pending point."), 0.5, 1.0, 0.5)
        else
            local refundCost = math.max(0, tonumber(SpellDraft.TalentRefundCost) or 1)
            GameTooltip:AddLine("\n" .. L("Right-click to refund one confirmed rank (%d Essence).", refundCost), 0.75, 0.55, 1.0)
        end
    end
    GameTooltip:Show()
end

-- One interaction contract shared by classic tree nodes and the B0.9.1
-- General-page management cards.  UI surfaces must not reimplement purchase
-- checks independently or their Pending behavior will eventually diverge.
local function StageOneTalentRank(talent)
    if not talent then return false end
    if IsTalentMutationPending() then
        UIErrorsFrame:AddMessage(L("Another talent change is in progress."), 1.0, 0.82, 0.2, 1)
        return false
    end
    if talent.locked then
        UIErrorsFrame:AddMessage(L("This talent is locked and can only be acquired from a Tome of Talents."), 1.0, 0.1, 0.1, 1.0, 10)
        return false
    end
    local reqLevel = GetTalentReqLevel(talent)
    if UnitLevel("player") < reqLevel then
        UIErrorsFrame:AddMessage(L("This talent requires level %d.", reqLevel), 1.0, 0.1, 0.1, 1.0, 10)
        return false
    end
    local currentPoints = (SpellDraft.TalentPoints or 0) - GetStagedTalentPointCount()
    if currentPoints <= 0 then
        UIErrorsFrame:AddMessage(L("You do not have any Talent Points."), 1.0, 0.1, 0.1, 1.0, 10)
        return false
    end
    local previewRank = GetPreviewTalentRank(talent.firstRankSpellId)
    if previewRank >= talent.maxRank then
        UIErrorsFrame:AddMessage(L("This talent is already at maximum rank."), 1.0, 0.1, 0.1, 1.0, 10)
        return false
    end
    -- Do not validate native parent talents here.  The authoritative server
    -- applies the same independent-node rule in Random Draft / Free Pick.
    stagedTalentRanks[talent.firstRankSpellId] = (stagedTalentRanks[talent.firstRankSpellId] or 0) + 1
    SpellDraft.UpdateStatsDisplay()
    SpellDraft.RefreshTalentsList()
    return true
end

local function RemoveOneTalentRank(talent)
    if not talent then return false end
    if IsTalentMutationPending() then
        UIErrorsFrame:AddMessage(L("Another talent change is in progress."), 1.0, 0.82, 0.2, 1)
        return false
    end
    local staged = stagedTalentRanks[talent.firstRankSpellId] or 0
    if staged > 0 then
        stagedTalentRanks[talent.firstRankSpellId] = staged - 1
        if stagedTalentRanks[talent.firstRankSpellId] <= 0 then stagedTalentRanks[talent.firstRankSpellId] = nil end
        SpellDraft.UpdateStatsDisplay()
        SpellDraft.RefreshTalentsList()
        return true
    end
    OpenTalentRefundDialog(talent)
    return true
end

local function CreateTalentsPanel()
    if talentsFrameCreated then return end
    LoadTalentSortMode()
    
    SpellDraftTalentsFrame = CreateFrame("Frame", "SpellDraftTalentsFrame", SpellDraftBookFrame)
    SpellDraftTalentsFrame:SetSize(450, 410)
    SpellDraftTalentsFrame:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 550, -178)
    SpellDraftTalentsFrame:Hide()

    talentSearchBox = CreateFrame("EditBox", "SpellDraftTalentSearchBox", SpellDraftTalentsFrame, "InputBoxTemplate")
    talentSearchBox:SetSize(150, 20)
    -- Share the same lowered toolbar baseline as the skill-catalog filters.
    -- Anchoring to the book frame keeps both page headers and both search rows
    -- visually level while the talent frame still owns show/hide behavior.
    talentSearchBox:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 558, -163)
    talentSearchBox:SetAutoFocus(false)

    local talentSearchPlaceholder = talentSearchBox:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    talentSearchPlaceholder:SetPoint("LEFT", talentSearchBox, "LEFT", 4, 0)
    talentSearchPlaceholder:SetText(L("Search talents..."))

    talentSearchResultBtn = CreateFrame("Button", "SpellDraftTalentSearchResult", SpellDraftTalentsFrame, "UIPanelButtonTemplate")
    talentSearchResultBtn:SetSize(250, 22)
    talentSearchResultBtn:SetPoint("LEFT", talentSearchBox, "RIGHT", 10, 0)
    talentSearchResultBtn:SetText(L("No matching talent"))
    talentSearchResultBtn:Disable()
    talentSearchResultBtn:SetScript("OnClick", LocateTalentSearchResult)
    talentSearchResultBtn:SetScript("OnEnter", function(self)
        if not talentSearchMatch then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(talentSearchMatch.firstRankSpellId)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format(L("Class: %s · Spec: %s · Max rank: %d · SpellID: %d"),
            SpellDraft.ClassName(talentSearchMatch.class), L(talentSearchMatch.spec),
            talentSearchMatch.maxRank or 1, talentSearchMatch.firstRankSpellId), 1, 0.82, 0, true)
        GameTooltip:AddLine(L("Click to locate this talent."), 0.4, 1, 0.4, true)
        GameTooltip:Show()
    end)
    talentSearchResultBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- On the General page this occupies the same wide toolbar slot as the
    -- class-tree search result. Only one is visible at a time, so the search
    -- field keeps its current size and the parchment header does not grow.
    talentSortBtn = CreateFrame("Button", "SpellDraftTalentSortButton", SpellDraftTalentsFrame, "UIPanelButtonTemplate")
    talentSortBtn:SetSize(250, 22)
    talentSortBtn:SetPoint("LEFT", talentSearchBox, "RIGHT", 10, 0)
    talentSortBtn:SetText(L("Sort: %s", GetTalentSortLabel()))
    talentSortBtn:Hide()

    talentSortMenu = CreateFrame("Frame", "SpellDraftTalentSortMenu", SpellDraftTalentsFrame)
    talentSortMenu:SetSize(220, 160)
    talentSortMenu:SetPoint("TOPRIGHT", talentSortBtn, "BOTTOMRIGHT", 0, -2)
    talentSortMenu:SetFrameLevel(SpellDraftTalentsFrame:GetFrameLevel() + 70)
    talentSortMenu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    talentSortMenu:SetBackdropColor(0.04, 0.035, 0.03, 0.98)
    talentSortMenu:SetBackdropBorderColor(0.65, 0.48, 0.18, 1)
    talentSortMenu:Hide()

    for index, option in ipairs(TALENT_SORT_OPTIONS) do
        local optionKey, optionLabel = option.key, option.label
        local optionBtn = CreateFrame("Button", nil, talentSortMenu, "UIPanelButtonTemplate")
        optionBtn:SetSize(198, 22)
        optionBtn:SetPoint("TOP", talentSortMenu, "TOP", 0, -8 - (index - 1) * 24)
        optionBtn:SetText((talentSortMode == optionKey and "|cffffd36a> |r" or "") .. L(optionLabel))
        optionBtn:SetScript("OnClick", function()
            talentSortMode = optionKey
            SaveTalentSortMode(talentSortMode)
            talentSortBtn:SetText(L("Sort: %s", GetTalentSortLabel()))
            for buttonIndex, child in ipairs(talentSortMenu.buttons or {}) do
                local childOption = TALENT_SORT_OPTIONS[buttonIndex]
                child:SetText((childOption.key == talentSortMode and "|cffffd36a> |r" or "") .. L(childOption.label))
            end
            talentSortMenu:Hide()
            SpellDraft.RefreshTalentsList()
        end)
        talentSortMenu.buttons = talentSortMenu.buttons or {}
        talentSortMenu.buttons[index] = optionBtn
    end

    talentSortBtn:SetScript("OnClick", function()
        if talentSortMenu:IsShown() then talentSortMenu:Hide() else talentSortMenu:Show() end
    end)
    talentSortBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L("Talent card sorting"))
        GameTooltip:AddLine(L("Sorting changes presentation only; ranks and Pending are unchanged."), 0.82, 0.76, 0.62, true)
        GameTooltip:Show()
    end)
    talentSortBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    talentSearchBox:SetScript("OnTextChanged", function(self)
        if self:GetText() == "" then talentSearchPlaceholder:Show() else talentSearchPlaceholder:Hide() end
        RefreshTalentSearchResult()
        -- The General page is a live management view.  Repaint its cards as
        -- the shared talent search changes, while class-tree search continues
        -- to use the result button above for cross-class location.
        if activeClass == "GENERAL" and SpellDraft.RefreshTalentsList then
            SpellDraft.RefreshTalentsList()
        end
    end)
    talentSearchBox:SetScript("OnEnterPressed", function(self)
        LocateTalentSearchResult()
        self:ClearFocus()
    end)
    talentSearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- SpellCraft progression resources. Both values remain visible without
    -- requiring the player to consume/open a Tome first.
    local pointsText = SpellDraftTalentsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pointsText:SetPoint("BOTTOMLEFT", SpellDraftTalentsFrame, "BOTTOMLEFT", 10, 76)
    SpellDraftTalentsFrame.talentPointsText = pointsText

    local essenceText = SpellDraftTalentsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    essenceText:SetPoint("BOTTOMLEFT", SpellDraftTalentsFrame, "BOTTOMLEFT", 10, 60)
    SpellDraftTalentsFrame.talentEssenceText = essenceText
    
    -- Extend the card/tree viewport into the formerly unused gap above the
    -- progression summary. 312px keeps a safety gutter before the Talent
    -- Points text while revealing substantially more of the next card row.
    local scrollFrame = CreateFrame("ScrollFrame", "SpellDraftTalentsScrollFrame", SpellDraftTalentsFrame, "UIPanelScrollFrameTemplate")
    -- The search controls now live in the shared toolbar row above this frame,
    -- so restore the full tree viewport instead of reserving 28px internally.
    scrollFrame:SetSize(425, 312)
    scrollFrame:SetPoint("TOPLEFT", SpellDraftTalentsFrame, "TOPLEFT", 0, -3)
    
    local scrollChild = CreateFrame("Frame", "SpellDraftTalentsScrollChild", scrollFrame)
    scrollChild:SetSize(420, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    SpellDraftTalentsScrollChild = scrollChild
    SpellDraftTalentsScrollFrame = scrollFrame

    -- The "All" browser intentionally does not build all thirty talent trees.
    -- Besides matching Ascension's choose-a-class flow, this keeps the default
    -- window light enough to open and drag smoothly on the 3.3.5 client.
    local emptyText = SpellDraftTalentsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    emptyText:SetPoint("CENTER", SpellDraftTalentsFrame, "CENTER", -5, 20)
    emptyText:SetWidth(360)
    emptyText:SetJustifyH("CENTER")
    emptyText:SetText("|cffffd36a" .. L("Choose a class above") .. "|r\n|cffb8aa92" .. L("Its three talent trees will appear here") .. "|r")
    SpellDraftTalentsFrame.emptyText = emptyText

    -- Lock icon for bottom footnote
    local lockIcon = SpellDraftTalentsFrame:CreateTexture(nil, "ARTWORK")
    lockIcon:SetSize(14, 14)
    lockIcon:SetPoint("BOTTOMLEFT", SpellDraftTalentsFrame, "BOTTOMLEFT", 10, 38)
    ApplyLockTexture(lockIcon)
    
    -- Footnote Legend Text
    local legendText = SpellDraftTalentsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    legendText:SetPoint("LEFT", lockIcon, "RIGHT", 4, 0)
    legendText:SetText("|cffbbbbbb" .. L("Locked talents can only be drafted from a Tome of Talents") .. "|r")
    
    -- Respec Instructions Help Text
    local respecHelpText = SpellDraftTalentsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    respecHelpText:SetPoint("BOTTOMLEFT", SpellDraftTalentsFrame, "BOTTOMLEFT", 10, 22)
    respecHelpText:SetText("|cff888888" .. L("Right-click a talent to refund one rank; Nibbs resets the whole tree.") .. "|r")

    local cancelBtn
    local confirmBtn = CreateFrame("Button", nil, SpellDraftTalentsFrame, "UIPanelButtonTemplate")
    confirmBtn:SetSize(92, 22)
    confirmBtn:SetPoint("BOTTOMRIGHT", SpellDraftTalentsFrame, "BOTTOMRIGHT", -8, -4)
    confirmBtn:SetText(L("Confirm"))
    confirmBtn:SetScript("OnClick", function()
        if IsTalentMutationPending() then return end
        local parts = {}
        for spellId, count in pairs(stagedTalentRanks) do
            if count > 0 then table.insert(parts, spellId .. "=" .. count) end
        end
        if #parts == 0 then
            UIErrorsFrame:AddMessage(L("No pending talent changes."), 1, 0.82, 0.2, 1)
            return
        end
        table.sort(parts)
        talentCommitSerial = talentCommitSerial + 1
        -- Keep protocol tokens inside the signed 32-bit range used by the
        -- WoW 3.3.5 client formatter.
        local safeTick = math.floor((GetTime() or 0) * 1000) % 10000000
        local token = safeTick * 100 + (talentCommitSerial % 100)
        talentCommitSnapshot = {}
        for spellId, count in pairs(stagedTalentRanks) do
            if count > 0 then
                talentCommitSnapshot[spellId] = {
                    count = count,
                    targetRank = (currentRanks[spellId] or 0) + count,
                }
            end
        end
        talentCommitPending = true
        talentCommitToken = tostring(token)
        SendChatMessage("SC_COMMIT_TALENTS:" .. token .. ":" .. table.concat(parts, ","), "WHISPER", nil, UnitName("player"))
        confirmBtn:Disable()
        cancelBtn:Disable()

        -- A lost response must not leave Confirm/Cancel permanently gray.
        -- Preserve the staged plan on timeout so no points can disappear.
        local pendingToken = talentCommitToken
        if SpellDraft.After then
            SpellDraft.After(8.0, function()
                if talentCommitPending and talentCommitToken == pendingToken then
                    SpellDraft.TryResolveTalentCommitFromSync()
                    if talentCommitPending and talentCommitToken == pendingToken then
                        talentCommitPending = false
                        talentCommitToken = nil
                        talentCommitSnapshot = nil
                        UIErrorsFrame:AddMessage(L("Talent confirmation timed out; your pending plan was retained."), 1.0, 0.65, 0.15, 1)
                        SpellDraft.UpdateStatsDisplay()
                        SpellDraft.RefreshTalentsList()
                    end
                end
            end)
        end
    end)
    SpellDraftTalentsFrame.confirmBtn = confirmBtn

    cancelBtn = CreateFrame("Button", nil, SpellDraftTalentsFrame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(92, 22)
    cancelBtn:SetPoint("RIGHT", confirmBtn, "LEFT", -8, 0)
    cancelBtn:SetText(L("Cancel"))
    cancelBtn:SetScript("OnClick", function()
        if IsTalentMutationPending() then return end
        ClearStagedTalentPlan()
        SpellDraft.UpdateStatsDisplay()
        SpellDraft.RefreshTalentsList()
    end)
    SpellDraftTalentsFrame.cancelBtn = cancelBtn
    
    talentsFrameCreated = true
end

function SpellDraft.UpdateStatsDisplay()
    if not prestigeText then return end
    
    local prestige = SpellDraft.PrestigeLevel or 0
    local rerolls = SpellDraft.RerollsLeft or 0
    local bans = SpellDraft.BansLeft or 0
    local points = SpellDraft.TalentPoints or 0
    local pendingPoints = GetStagedTalentPointCount()
    local essence = SpellDraft.TalentEssence or 0
    
    if prestige > 0 then
        prestigeText:SetText("|cffffd100" .. L("Prestige") .. ":|r " .. prestige .. " |cff00ffff" .. L("(+50% XP)") .. "|r")
        if SpellDraft.ShopButton then
            SpellDraft.ShopButton:Show()
            SpellDraft.ShopButton:SetPoint("LEFT", prestigeText:GetParent(), "LEFT", 0, 0)
            prestigeText:SetPoint("LEFT", SpellDraft.ShopButton, "RIGHT", 6, 0)
        end
    else
        prestigeText:SetText("|cffb0b0b0" .. L("Prestige") .. ":|r " .. L("None"))
        if SpellDraft.ShopButton then
            SpellDraft.ShopButton:Hide()
        end
        prestigeText:SetPoint("LEFT", prestigeText:GetParent(), "LEFT", 0, 0)
    end
    
    rerollsText:SetText("|cff1eff00" .. L("Rerolls") .. ":|r " .. rerolls)
    bansText:SetText("|cffe74c3c" .. L("Bans") .. ":|r " .. bans)
    
    if draftsText then
        draftsText:Hide()
    end
    
    if SpellDraftTalentsFrame and SpellDraftTalentsFrame.talentPointsText then
        SpellDraftTalentsFrame.talentPointsText:SetText("|cffffcc00" .. L("Talent Points: %d", math.max(0, points - pendingPoints)) .. "|r |cff55ff55" .. L("Pending: %d", pendingPoints) .. "|r")
    end
    if SpellDraftTalentsFrame and SpellDraftTalentsFrame.talentEssenceText then
        SpellDraftTalentsFrame.talentEssenceText:SetText("|cffbb88ff" .. L("Talent Essence: %d", essence) .. "|r")
    end
    if SpellDraftTalentsFrame and SpellDraftTalentsFrame.confirmBtn then
        if pendingPoints > 0 and not IsTalentMutationPending() then
            SpellDraftTalentsFrame.confirmBtn:Enable()
            SpellDraftTalentsFrame.cancelBtn:Enable()
        else
            SpellDraftTalentsFrame.confirmBtn:Disable()
            SpellDraftTalentsFrame.cancelBtn:Disable()
        end
    end
end

local function GetOrCreateSpecFrame(index)
    local f = specFrames[index]
    if not f then
        f = CreateFrame("Frame", nil, SpellDraftTalentsScrollChild)
        f:SetSize(420, 616)

        local treeBg = f:CreateTexture(nil, "BACKGROUND")
        treeBg:SetAllPoints(f)
        treeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        -- Talent nodes now live directly on the book parchment.  Keep this
        -- region as a transparent layout anchor instead of a black canvas.
        treeBg:SetVertexColor(0, 0, 0, 0)
        f.treeBg = treeBg
        
        -- Header background banner (sleek dark grey panel)
        local headerBg = f:CreateTexture(nil, "BACKGROUND")
        headerBg:SetSize(420, 28)
        headerBg:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        headerBg:SetTexture(ASCENSION_TEXTURE_PATH .. "Talent_Bg")
        -- The old dark banner visually rebuilt the black panel we just
        -- removed.  Its texture remains as the title's positioning anchor.
        headerBg:SetVertexColor(1, 1, 1, 0)
        f.headerBg = headerBg
        
        -- Header bottom highlight line
        local headerBorder = f:CreateTexture(nil, "BORDER")
        headerBorder:SetSize(420, 1)
        headerBorder:SetPoint("TOPLEFT", headerBg, "BOTTOMLEFT", 0, 0)
        headerBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        headerBorder:SetVertexColor(0.45, 0.27, 0.10, 0.55)
        f.headerBorder = headerBorder
        
        -- Header text
        local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        title:SetPoint("CENTER", headerBg, "CENTER", 0, 0)
        f.title = title
        
        f.buttons = {}
        f.linePool = {}
        f.arrowPool = {}
        specFrames[index] = f
    end
    f:ClearAllPoints()
    f:Show()
    f.lineIndex = 0
    f.arrowIndex = 0
    return f
end

local function GetOrCreateTalentButton(specFrame, btnIndex)
    local btn = specFrame.buttons[btnIndex]
    if not btn then
        btn = CreateFrame("Button", nil, specFrame)
        btn:SetSize(32, 32)
        
        -- Dark border outline (peeks out 1px)
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetSize(34, 34)
        border:SetPoint("CENTER", btn, "CENTER", 0, 0)
        border:SetTexture(ASCENSION_TEXTURE_PATH .. "SpellKitSpellBorder_Talent")
        btn.border = border
        
        -- Dark backing behind icon
        local iconBg = btn:CreateTexture(nil, "BACKGROUND")
        iconBg:SetSize(32, 32)
        iconBg:SetPoint("CENTER", btn, "CENTER", 0, 0)
        iconBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        iconBg:SetVertexColor(0, 0, 0, 0.9)
        btn.iconBg = iconBg
        
        -- Icon texture
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(30, 30)
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        btn.icon = icon
        
        -- Rank text frame (so it renders on top of icon)
        local rankFrame = CreateFrame("Frame", nil, btn)
        rankFrame:SetAllPoints()

        local rankText = rankFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rankText:SetPoint("CENTER", btn, "BOTTOMRIGHT", -4, 2)
        btn.rankText = rankText

        -- Black plate behind the rank text so it stays readable over any border
        local rankBg = rankFrame:CreateTexture(nil, "ARTWORK")
        rankBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        rankBg:SetVertexColor(0, 0, 0, 0.85)
        rankBg:SetPoint("TOPLEFT", rankText, "TOPLEFT", -3, 1)
        rankBg:SetPoint("BOTTOMRIGHT", rankText, "BOTTOMRIGHT", 3, -1)
        btn.rankBg = rankBg

        -- Lock overlay texture
        local lockOverlay = btn:CreateTexture(nil, "OVERLAY")
        lockOverlay:SetSize(16, 16)
        lockOverlay:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 2)
        ApplyLockTexture(lockOverlay)
        lockOverlay:Hide()
        btn.lockOverlay = lockOverlay

        local searchGlow = btn:CreateTexture(nil, "OVERLAY")
        searchGlow:SetSize(46, 46)
        searchGlow:SetPoint("CENTER", btn, "CENTER", 0, 0)
        searchGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        searchGlow:SetBlendMode("ADD")
        searchGlow:SetVertexColor(0.2, 0.8, 1.0, 1.0)
        searchGlow:Hide()
        btn.searchGlow = searchGlow
        
        -- Highlight texture on hover
        local highlight = btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        if highlight then
            highlight:SetAllPoints(icon)
        end
        
        btn:SetScript("OnEnter", ShowTalentTooltip)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        btn:SetScript("OnClick", function(self, mouseButton)
            local talent = self.talent
            if not talent then return end
            if mouseButton == "RightButton" then
                RemoveOneTalentRank(talent)
            else
                StageOneTalentRank(talent)
            end
            if GameTooltip:IsOwned(self) then ShowTalentTooltip(self) end
        end)
        
        specFrame.buttons[btnIndex] = btn
    end
    btn:ClearAllPoints()
    btn:Show()
    return btn
end

local function HideConfirmedTalentCards()
    for _, card in ipairs(confirmedTalentCardPool) do
        card:Hide()
    end
end

local function ConfirmedTalentMatchesQuery(talent, query)
    if not query or query == "" then return true end
    local spellId = talent.firstRankSpellId
    local name = talent.name or GetSpellInfo(spellId) or ("Spell " .. spellId)
    local searchable = string.lower(table.concat({
        name,
        tostring(spellId),
        talent.class or "",
        SpellDraft.ClassName(talent.class) or "",
        talent.spec or "",
        L(talent.spec) or "",
    }, " "))
    return string.find(searchable, query, 1, true) ~= nil
end

local function ShowConfirmedTalentCardTooltip(self)
    if not self.talent then return end
    ShowTalentTooltip(self)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("Click the card to locate this talent in its class tree."), 0.35, 0.8, 1.0, true)
    GameTooltip:Show()
end

local function ShowCardControlTooltip(self, text)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine(text, 1, 0.82, 0, true)
    GameTooltip:Show()
end

local function GetOrCreateConfirmedTalentCard(index)
    local card = confirmedTalentCardPool[index]
    if card then
        card:ClearAllPoints()
        card:Show()
        return card
    end

    card = CreateFrame("Button", nil, SpellDraftTalentsScrollChild)
    -- A little extra height gives the status and control rows their own air
    -- without returning to the oversized first-generation cards.
    card:SetSize(184, 78)
    card:RegisterForClicks("LeftButtonUp")
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    -- Let the native parchment remain visible through confirmed-talent cards.
    -- The gold/green border, icon and controls already provide sufficient
    -- grouping, so an opaque black panel only makes the right page heavier.
    card:SetBackdropColor(0, 0, 0, 0)
    card:SetBackdropBorderColor(0.42, 0.34, 0.20, 0.95)

    local selected = card:CreateTexture(nil, "BACKGROUND")
    selected:SetTexture("Interface\\Buttons\\WHITE8x8")
    selected:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
    selected:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4, 4)
    -- Keep only a faint warm wash for hover/selection depth; it should read as
    -- ink on parchment rather than a second opaque window inside the book.
    selected:SetVertexColor(0.40, 0.20, 0.05, 0.06)
    card.selected = selected

    local iconBorder = card:CreateTexture(nil, "BORDER")
    iconBorder:SetSize(42, 42)
    iconBorder:SetPoint("TOPLEFT", card, "TOPLEFT", 6, -7)
    iconBorder:SetTexture(ASCENSION_TEXTURE_PATH .. "SpellKitSpellBorder_Talent")
    card.iconBorder = iconBorder

    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetPoint("CENTER", iconBorder, "CENTER", 0, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    card.icon = icon

    local name = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    name:SetPoint("TOPLEFT", card, "TOPLEFT", 52, -7)
    name:SetWidth(122)
    name:SetHeight(16)
    name:SetJustifyH("LEFT")
    card.name = name

    local origin = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    origin:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    origin:SetWidth(122)
    origin:SetHeight(14)
    origin:SetJustifyH("LEFT")
    card.origin = origin

    local status = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    -- Keep the status on a strict 12px baseline. The taller card leaves a
    -- separate control shelf below it.
    status:SetPoint("TOPLEFT", origin, "BOTTOMLEFT", 0, 0)
    status:SetWidth(122)
    status:SetHeight(12)
    status:SetJustifyH("LEFT")
    card.status = status

    local minus = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    minus:SetSize(22, 18)
    minus:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 52, 5)
    minus:SetText("-")
    minus:SetFrameLevel(card:GetFrameLevel() + 3)
    card.minus = minus

    local rank = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rank:SetPoint("LEFT", minus, "RIGHT", 6, 0)
    rank:SetWidth(68)
    rank:SetJustifyH("CENTER")
    card.rank = rank

    local plus = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    plus:SetSize(22, 18)
    plus:SetPoint("LEFT", rank, "RIGHT", 6, 0)
    plus:SetText("+")
    plus:SetFrameLevel(card:GetFrameLevel() + 3)
    card.plus = plus

    card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    card:SetScript("OnClick", function(self)
        LocateTalentInTree(self.talent)
    end)
    card:SetScript("OnEnter", ShowConfirmedTalentCardTooltip)
    card:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minus:SetScript("OnEnter", function(self)
        ShowCardControlTooltip(self, L("Remove one rank"))
    end)
    minus:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minus:SetScript("OnClick", function(self)
        local owner = self:GetParent()
        if RemoveOneTalentRank(owner.talent) and GameTooltip:IsOwned(self) then
            ShowCardControlTooltip(self, L("Remove one rank"))
        end
    end)
    plus:SetScript("OnEnter", function(self)
        ShowCardControlTooltip(self, L("Add one pending rank"))
    end)
    plus:SetScript("OnLeave", function() GameTooltip:Hide() end)
    plus:SetScript("OnClick", function(self)
        local owner = self:GetParent()
        if StageOneTalentRank(owner.talent) and GameTooltip:IsOwned(self) then
            ShowCardControlTooltip(self, L("Add one pending rank"))
        end
    end)

    confirmedTalentCardPool[index] = card
    return card
end

local function RefreshConfirmedTalentCards()
    HideConfirmedTalentCards()
    if SpellDraftTalentsFrame.emptyText then SpellDraftTalentsFrame.emptyText:Hide() end

    local query = talentSearchBox and talentSearchBox:GetText() or ""
    query = string.lower((query or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    local talents = {}
    for firstRankSpellId, talent in pairs(SpellDraftTalentDB or {}) do
        local confirmed = currentRanks[firstRankSpellId] or 0
        local staged = stagedTalentRanks[firstRankSpellId] or 0
        -- Tome-only locked abilities (Titan's Grip, Stormstrike, Gargoyle,
        -- etc.) are learned spells, not refundable point allocations.  Keep
        -- them in the left catalog and never let a delayed legacy rank packet
        -- flash them into the right confirmed-card panel.
        if not LOCKED_TALENTS[firstRankSpellId]
            and (confirmed > 0 or staged > 0)
            and ConfirmedTalentMatchesQuery(talent, query) then
            table.insert(talents, talent)
        end
    end

    local classOrder = {}
    for order, classInfo in ipairs(tabClasses) do classOrder[classInfo.value] = order end
    local function ClassSpecNameLess(a, b)
        local ac, bc = classOrder[a.class] or 99, classOrder[b.class] or 99
        if ac ~= bc then return ac < bc end
        local as, bs = L(a.spec) or a.spec or "", L(b.spec) or b.spec or ""
        if as ~= bs then return as < bs end
        local an = a.name or GetSpellInfo(a.firstRankSpellId) or ""
        local bn = b.name or GetSpellInfo(b.firstRankSpellId) or ""
        if an ~= bn then return an < bn end
        return a.firstRankSpellId < b.firstRankSpellId
    end

    -- Establish a deterministic seed before assigning historical positions.
    -- SavedVariables cannot reconstruct acquisition timestamps that predate
    -- this feature, so existing cards keep this first stable visual order;
    -- all newly confirmed talents are appended exactly when first observed.
    table.sort(talents, ClassSpecNameLess)
    local learnOrderState = GetTalentLearnOrderState()
    for _, talent in ipairs(talents) do
        local firstRankSpellId = talent.firstRankSpellId
        if (currentRanks[firstRankSpellId] or 0) > 0
            and not learnOrderState.positions[firstRankSpellId] then
            learnOrderState.positions[firstRankSpellId] = learnOrderState.nextOrder
            learnOrderState.nextOrder = learnOrderState.nextOrder + 1
        end
    end

    local function LearnOrderOf(talent)
        return learnOrderState.positions[talent.firstRankSpellId] or (100000000 + talent.firstRankSpellId)
    end
    local function NameOf(talent)
        return string.lower(talent.name or GetSpellInfo(talent.firstRankSpellId) or "")
    end
    local function TieBreak(a, b)
        if a.firstRankSpellId == b.firstRankSpellId then return false end
        return ClassSpecNameLess(a, b)
    end

    table.sort(talents, function(a, b)
        if talentSortMode == "LEARNED_ASC" or talentSortMode == "LEARNED_DESC" then
            local av, bv = LearnOrderOf(a), LearnOrderOf(b)
            if av ~= bv then
                if talentSortMode == "LEARNED_ASC" then return av < bv end
                return av > bv
            end
        elseif talentSortMode == "EFFECT" then
            local ag = TALENT_EFFECT_GROUPS[a.firstRankSpellId] or "Other Effects"
            local bg = TALENT_EFFECT_GROUPS[b.firstRankSpellId] or "Other Effects"
            local av, bv = TALENT_EFFECT_ORDER[ag] or 99, TALENT_EFFECT_ORDER[bg] or 99
            if av ~= bv then return av < bv end
        elseif talentSortMode == "RANK" then
            local ar = (currentRanks[a.firstRankSpellId] or 0) + (stagedTalentRanks[a.firstRankSpellId] or 0)
            local br = (currentRanks[b.firstRankSpellId] or 0) + (stagedTalentRanks[b.firstRankSpellId] or 0)
            if ar ~= br then return ar > br end
            local ap = ar / math.max(1, a.maxRank or 1)
            local bp = br / math.max(1, b.maxRank or 1)
            if ap ~= bp then return ap > bp end
        elseif talentSortMode == "NAME" then
            local an, bn = NameOf(a), NameOf(b)
            if an ~= bn then return an < bn end
        end
        return TieBreak(a, b)
    end)

    for index, talent in ipairs(talents) do
        local card = GetOrCreateConfirmedTalentCard(index)
        local col = (index - 1) % 2
        local row = math.floor((index - 1) / 2)
        -- Start below the search toolbar and keep a 6px gutter between the
        -- taller rows. There is still ample room before the point summary.
        card:SetPoint("TOPLEFT", SpellDraftTalentsScrollChild, "TOPLEFT", 18 + col * 192, -12 - row * 84)
        card.talent = talent
        talent.locked = LOCKED_TALENTS[talent.firstRankSpellId] or false

        local _, _, iconTexture = GetSpellInfo(talent.firstRankSpellId)
        card.icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
        card.icon:SetDesaturated(false)
        card.name:SetText(talent.name or GetSpellInfo(talent.firstRankSpellId) or ("Spell " .. talent.firstRankSpellId))

        local classColor = CLASS_COLORS[talent.class] or "FFFFFF"
        card.origin:SetText("|cff" .. classColor .. SpellDraft.ClassName(talent.class) .. "|r · " .. L(talent.spec))

        local confirmed = currentRanks[talent.firstRankSpellId] or 0
        local staged = stagedTalentRanks[talent.firstRankSpellId] or 0
        local preview = confirmed + staged
        card.rank:SetText((preview >= talent.maxRank and "|cffffd100" or "|cff55ff55")
            .. preview .. "/" .. talent.maxRank .. "|r")
        if staged > 0 then
            card.status:SetText("|cff55ff55" .. L("Confirmed %d", confirmed) .. "|r  |cffffd36a" .. L("Pending +%d", staged) .. "|r")
        else
            card.status:SetText("|cff55ff55" .. L("Confirmed %d", confirmed) .. "|r")
        end

        local mutationPending = IsTalentMutationPending()
        local canMinus = not mutationPending and (staged > 0 or (confirmed > 0 and not talent.locked))
        local canPlus = not mutationPending and not talent.locked
            and preview < talent.maxRank
            and UnitLevel("player") >= GetTalentReqLevel(talent)
            and ((SpellDraft.TalentPoints or 0) - GetStagedTalentPointCount()) > 0
        if canMinus then card.minus:Enable() else card.minus:Disable() end
        if canPlus then card.plus:Enable() else card.plus:Disable() end
        if preview >= talent.maxRank then
            card:SetBackdropBorderColor(0.95, 0.72, 0.15, 1)
            card.iconBorder:SetVertexColor(1.0, 0.82, 0.0, 1.0)
        else
            card:SetBackdropBorderColor(0.18, 0.65, 0.32, 1)
            card.iconBorder:SetVertexColor(0.12, 1.0, 0.12, 1.0)
        end
    end

    for index = #talents + 1, #confirmedTalentCardPool do
        confirmedTalentCardPool[index]:Hide()
    end
    local rows = math.ceil(#talents / 2)
    SpellDraftTalentsScrollChild:SetHeight(math.max(1, rows * 84 + 12))

    if #talents == 0 and SpellDraftTalentsFrame.emptyText then
        local message = query ~= "" and L("No confirmed talents match this search.") or L("No confirmed custom talents")
        SpellDraftTalentsFrame.emptyText:SetText("|cffffd36a" .. L("Confirmed Custom Talents") .. "|r\n\n|cffb8aa92" .. message .. "|r")
        SpellDraftTalentsFrame.emptyText:Show()
    end
end

local function DrawPrereqLine(parentButton, childButton, specFrame, isMet)
    local r1, c1 = parentButton.row, parentButton.col
    local r2, c2 = childButton.row, childButton.col
    local color = isMet and {1.0, 0.82, 0.0, 0.8} or {0.25, 0.25, 0.25, 0.6}
    
    local function CreateLineTexture(sf)
        sf.lineIndex = sf.lineIndex + 1
        local line = sf.linePool[sf.lineIndex]
        if not line then
            line = sf:CreateTexture(nil, "BACKGROUND")
            line:SetTexture("Interface\\Buttons\\WHITE8x8")
            sf.linePool[sf.lineIndex] = line
        end
        line:ClearAllPoints()
        line:Show()
        return line
    end
    
    if c1 == c2 then
        local line = CreateLineTexture(specFrame)
        line:SetWidth(4)
        line:SetVertexColor(unpack(color))
        line:SetPoint("TOP", parentButton, "BOTTOM", 0, 0)
        line:SetPoint("BOTTOM", childButton, "TOP", 0, 10)
    elseif r1 == r2 then
        local line = CreateLineTexture(specFrame)
        line:SetHeight(4)
        line:SetVertexColor(unpack(color))
        if c1 < c2 then
            line:SetPoint("LEFT", parentButton, "RIGHT", 0, 0)
            line:SetPoint("RIGHT", childButton, "LEFT", -8, 0)
        else
            line:SetPoint("RIGHT", parentButton, "LEFT", 0, 0)
            line:SetPoint("LEFT", childButton, "RIGHT", 8, 0)
        end
    else
        local line1 = CreateLineTexture(specFrame)
        line1:SetWidth(4)
        line1:SetVertexColor(unpack(color))
        line1:SetPoint("TOP", parentButton, "BOTTOM", 0, 0)
        line1:SetHeight(10)
        
        local line2 = CreateLineTexture(specFrame)
        line2:SetHeight(4)
        line2:SetVertexColor(unpack(color))
        line2:SetPoint("TOP", line1, "BOTTOM", 0, 2)
        if c1 < c2 then
            line2:SetPoint("LEFT", line1, "CENTER", -2, -10)
            line2:SetWidth((c2 - c1) * 68 + 4)
        else
            line2:SetPoint("RIGHT", line1, "CENTER", 2, -10)
            line2:SetWidth((c1 - c2) * 68 + 4)
        end
        
        local line3 = CreateLineTexture(specFrame)
        line3:SetWidth(4)
        line3:SetVertexColor(unpack(color))
        if c1 < c2 then
            line3:SetPoint("TOP", line2, "RIGHT", -4, 2)
        else
            line3:SetPoint("TOP", line2, "LEFT", 4, 2)
        end
        line3:SetPoint("BOTTOM", childButton, "TOP", 0, 10)
    end
end

local function DrawArrow(childButton, specFrame, isMet)
    specFrame.arrowIndex = specFrame.arrowIndex + 1
    local arrow = specFrame.arrowPool[specFrame.arrowIndex]
    if not arrow then
        arrow = specFrame:CreateTexture(nil, "ARTWORK")
        arrow:SetSize(16, 16)
        specFrame.arrowPool[specFrame.arrowIndex] = arrow
    end
    arrow:ClearAllPoints()
    arrow:SetTexture(isMet and "Interface\\TalentFrame\\TalentFrame-Arrow-True" or "Interface\\TalentFrame\\TalentFrame-Arrow-False")
    
    local prereqId = childButton.talent.prereqSpellId
    local prereq = prereqId and prereqId > 0 and SpellDraftTalentDB[prereqId]
    local r1 = prereq and prereq.row or 0
    local c1 = prereq and prereq.col or 0
    local r2, c2 = childButton.row, childButton.col
    
    if r1 == r2 then
        if c1 < c2 then
            arrow:SetTexCoord(0.5, 1.0, 0, 0.5) -- Pointing right
            arrow:SetPoint("RIGHT", childButton, "LEFT", 2, 0)
        else
            arrow:SetTexCoord(1.0, 0.5, 0, 0.5) -- Pointing left
            arrow:SetPoint("LEFT", childButton, "RIGHT", -2, 0)
        end
    else
        arrow:SetTexCoord(0, 0.5, 0, 0.5) -- Pointing down
        arrow:SetPoint("BOTTOM", childButton, "TOP", 0, -2)
    end
    arrow:Show()
end

local buttonsByPos = {}

function SpellDraft.RefreshTalentsList()
    if not SpellDraftBookFrame or not SpellDraftTalentsFrame or not SpellDraftTalentsFrame:IsShown() then return end
    
    RecalculateTalentRanks()
    if not SpellDraftTalentDB then return end

    -- The same toolbar slot serves two contexts: class pages show the search
    -- result/locator, while General shows the card ordering control.
    if activeClass == "GENERAL" then
        if talentSearchResultBtn then talentSearchResultBtn:Hide() end
        if talentSortBtn then
            talentSortBtn:SetText(L("Sort: %s", GetTalentSortLabel()))
            talentSortBtn:Show()
        end
    else
        if talentSortBtn then talentSortBtn:Hide() end
        if talentSortMenu then talentSortMenu:Hide() end
        if talentSearchResultBtn then talentSearchResultBtn:Show() end
    end

    -- Rendering every class at once creates hundreds of buttons and connector
    -- textures. Keep Browse lightweight and ask the player to pick a class.
    if activeClass == "ALL" then
        HideConfirmedTalentCards()
        for _, specFrame in ipairs(specFrames) do
            specFrame:Hide()
        end
        SpellDraftTalentsScrollChild:SetHeight(1)
        if SpellDraftTalentsFrame.emptyText then
            SpellDraftTalentsFrame.emptyText:SetText("|cffffd36a" .. L("Choose a class above") .. "|r\n|cffb8aa92" .. L("Its three talent trees will appear here") .. "|r")
            SpellDraftTalentsFrame.emptyText:Show()
        end
        return
    elseif activeClass == "GENERAL" then
        for _, specFrame in ipairs(specFrames) do
            specFrame:Hide()
        end
        RefreshConfirmedTalentCards()
        return
    else
        HideConfirmedTalentCards()
        if SpellDraftTalentsFrame.emptyText then SpellDraftTalentsFrame.emptyText:Hide() end
    end
    
    local specsToRender = {}
    if activeClass ~= "GENERAL" then
        local classSpecs = CLASS_SPECS[activeClass]
        if classSpecs then
            for _, specName in ipairs(classSpecs) do
                table.insert(specsToRender, { class = activeClass, spec = specName })
            end
        end
    end
    
    local yOffset = 0
    for index, specInfo in ipairs(specsToRender) do
        local specFrame = GetOrCreateSpecFrame(index)
        specFrame:SetPoint("TOPLEFT", SpellDraftTalentsScrollChild, "TOPLEFT", 0, -yOffset)
        
        local classColor = CLASS_COLORS[specInfo.class] or "FFFFFF"
        specFrame.title:SetText(L(specInfo.spec) .. " |cff" .. classColor .. "(" .. L(specInfo.class) .. ")|r")
        
        local specTalents = TalentsByClassAndSpec[specInfo.class] and TalentsByClassAndSpec[specInfo.class][specInfo.spec]
        for k in pairs(buttonsByPos) do buttonsByPos[k] = nil end
        
        local btnIndex = 0
        if specTalents then
            for _, dt in ipairs(specTalents) do
                btnIndex = btnIndex + 1
                local btn = GetOrCreateTalentButton(specFrame, btnIndex)
                btn.talent = dt
                btn.row = dt.row
                btn.col = dt.col
                if btn.searchGlow then
                    if dt.firstRankSpellId == talentSearchTargetSpellId then btn.searchGlow:Show()
                    else btn.searchGlow:Hide() end
                end
                
                dt.locked = LOCKED_TALENTS[dt.firstRankSpellId] or false
                if dt.locked then
                    btn.lockOverlay:Show()
                else
                    btn.lockOverlay:Hide()
                end
                
                local x = dt.col * 82 + 45
                local y = -(dt.row * 52 + 10 + 24)
                btn:SetPoint("TOPLEFT", specFrame, "TOPLEFT", x, y)
                
                local _, _, iconTexture = GetSpellInfo(dt.firstRankSpellId)
                btn.icon:SetTexture(iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark")
                
                local rank = GetPreviewTalentRank(dt.firstRankSpellId)
                local maxRank = dt.maxRank
                -- Native tree prerequisites are intentionally ignored by the
                -- classless SpellDraft tree. Tome-only locks remain separate.
                local isMet = true
                
                local selectable = isMet and not dt.locked
                    and UnitLevel("player") >= GetTalentReqLevel(dt)

                if rank == maxRank then
                    btn.icon:SetDesaturated(false)
                    btn.border:SetVertexColor(1.0, 0.82, 0.0, 1.0)
                    btn.rankText:SetText("|cffffd100" .. rank .. "/" .. maxRank .. "|r")
                elseif rank > 0 then
                    btn.icon:SetDesaturated(false)
                    btn.border:SetVertexColor(0.12, 1.0, 0.12, 1.0)
                    btn.rankText:SetText("|cff00ff00" .. rank .. "/" .. maxRank .. "|r")
                elseif selectable then
                    -- Purchasable right now with talent points: full color
                    btn.icon:SetDesaturated(false)
                    btn.border:SetVertexColor(0.9, 0.9, 0.9, 1.0)
                    btn.rankText:SetText("|cffffffff0/" .. maxRank .. "|r")
                else
                    -- Locked, level-gated, or prereq unmet: greyed out
                    btn.icon:SetDesaturated(true)
                    btn.border:SetVertexColor(0.35, 0.35, 0.35, 0.8)
                    btn.rankText:SetText("|cff8080800/" .. maxRank .. "|r")
                end
                
                buttonsByPos[dt.row .. "_" .. dt.col] = btn
            end
        end
        
        for b = btnIndex + 1, #specFrame.buttons do
            specFrame.buttons[b]:Hide()
        end
        
        -- Do not draw the native prerequisite graph in the classless book.
        -- lineIndex/arrowIndex are zeroed when this frame is reused, and the
        -- pool cleanup below also removes lines left by an older build.
        
        for l = specFrame.lineIndex + 1, #specFrame.linePool do
            specFrame.linePool[l]:Hide()
        end
        for a = specFrame.arrowIndex + 1, #specFrame.arrowPool do
            specFrame.arrowPool[a]:Hide()
        end
        
        yOffset = yOffset + 616
    end
    
    for f = #specsToRender + 1, #specFrames do
        specFrames[f]:Hide()
    end
    
    SpellDraftTalentsScrollChild:SetHeight(math.max(1, yOffset))
end

function SpellDraft.ShowGrimoirePanel()
    searchBox:Show()
    if statusFilterBtn then statusFilterBtn:Show() end
    if typeFilterBtn then typeFilterBtn:Show() end
    prevPageBtn:Show()
    nextPageBtn:Show()
    pageText:Show()
    for _, btn in ipairs(buttons) do
        btn:Show()
    end
    for _, tab in ipairs(tabs) do
        tab:Show()
    end
    SpellDraft.RefreshSpellBook()
end

function SpellDraft.ShowTalentsPanel()
    if catalogExpanded then return end
    if not SpellDraftTalentsFrame then
        CreateTalentsPanel()
    end
    SpellDraftTalentsFrame:Show()
    SpellDraft.RefreshTalentsList()
end

local function ApplyCatalogLayout()
    if not SpellDraftBookFrame then return end
    SpellDraftBookFrame.catalogLayoutGeneration =
        (SpellDraftBookFrame.catalogLayoutGeneration or 0) + 1

    -- The two full-page reference slices already provide the complete book
    -- silhouette.  The older rectangular Ascension background must never sit
    -- underneath them: during the first login frame the atlas can be resolved
    -- one frame later, briefly exposing that rectangle beyond the curved page
    -- edges.  Keep every layer deterministic whenever layout is reapplied.
    if advancementBackground then advancementBackground:Hide() end

    if grimoireTitleText then
        grimoireTitleText:ClearAllPoints()
        -- The catalog title describes the left-page filter section in both
        -- layouts. Keep it centred over that page instead of the book spine.
        grimoireTitleText:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 265, -143)
    end
    if sectionTitleBandLeft then
        sectionTitleBandLeft:ClearAllPoints()
        sectionTitleBandLeft:SetSize(250, 20)
        sectionTitleBandLeft:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 265, -137)
        sectionTitleBandLeft:Show()
    end
    if sectionTitleBandRight then
        if catalogExpanded then sectionTitleBandRight:Hide()
        else sectionTitleBandRight:Show() end
    end
    if catalogToolbar then
        catalogToolbar:ClearAllPoints()
        -- Compact mode keeps the familiar left-page toolbar. Expanded mode
        -- treats the two filters as one control group centred on the left leaf,
        -- instead of letting them drift across the book spine.
        catalogToolbar:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT",
            catalogExpanded and 153 or 54, -163)
    end
    if searchBox then
        searchBox:ClearAllPoints()
        if catalogExpanded then
            -- The search field belongs to the right leaf in the two-page view.
            -- Its centre (778px) mirrors the left filter group's centre.
            searchBox:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 693, -163)
        else
            searchBox:SetPoint("LEFT", typeFilterBtn, "RIGHT", 14, 0)
        end
    end
    if catalogExpandBtn then
        catalogExpandBtn:ClearAllPoints()
        catalogExpandBtn:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT",
            catalogExpanded and 548 or 430, catalogExpanded and -163 or -140)
        catalogExpandBtn:SetText(L(catalogExpanded and "Collapse" or "Expand"))
    end
    if languageBtn then
        languageBtn:ClearAllPoints()
        if catalogExpanded then
            -- Complete the expanded right-page toolbar: Collapse | Search |
            -- Language. This keeps the selector off the bottom page ornament.
            languageBtn:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 884, -163)
        else
            -- In compact mode it becomes the first item in the bottom action
            -- row, followed by Cancel and Confirm on the talent panel.
            languageBtn:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -252, 58)
        end
    end
    if languageMenu and languageBtn then
        languageMenu:ClearAllPoints()
        if catalogExpanded then
            languageMenu:SetPoint("TOPRIGHT", languageBtn, "BOTTOMRIGHT", 0, -2)
        else
            languageMenu:SetPoint("BOTTOMRIGHT", languageBtn, "TOPRIGHT", 0, 2)
        end
    end

    if leftPanelBg then
        leftPanelBg:ClearAllPoints()
        leftPanelBg:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 22, -132)
        if catalogExpanded then
            leftPanelBg:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -22, 22)
        else
            leftPanelBg:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOM", -8, 22)
        end
    end

    if catalogExpanded then
        if rightPanelBg then rightPanelBg:Hide() end
        if catalogParchmentBackground then catalogParchmentBackground:Show() end
        if catalogReferencePageLeft then catalogReferencePageLeft:Show() end
        if catalogReferencePageRight then catalogReferencePageRight:Show() end
        -- Expanded mode is now a real two-page skill spread. Keep a visible
        -- spine instead of letting cards run through the book center. The
        -- original parchment art already carries the main fold, so this line
        -- is only a quiet alignment cue rather than a second heavy divider.
        if centerDivider then
            centerDivider:SetSize(1, 430)
            centerDivider:ClearAllPoints()
            centerDivider:SetPoint("TOP", SpellDraftBookFrame, "TOP", 0, -178)
            centerDivider:SetVertexColor(0.28, 0.18, 0.08, 0.28)
            centerDivider:Show()
        end
        if talentsTitleText then talentsTitleText:Hide() end
        if SpellDraftTalentsFrame then SpellDraftTalentsFrame:Hide() end
        if catalogLeftChapterText then catalogLeftChapterText:Show() end
        if catalogRightChapterText then catalogRightChapterText:Show() end
        if catalogLeftChapterRule then catalogLeftChapterRule:Show() end
        if catalogRightChapterRule then catalogRightChapterRule:Show() end
        if catalogLeftLeafText then catalogLeftLeafText:Show() end
        if catalogRightLeafText then catalogRightLeafText:Show() end
    else
        if rightPanelBg then rightPanelBg:Show() end
        -- Compact mode uses only the two complete book-page atlas slices.
        -- Showing the rectangular expanded-mode parchment here caused the
        -- intermittent bright square seen immediately after login/reload.
        if catalogParchmentBackground then catalogParchmentBackground:Hide() end
        if catalogReferencePageLeft then catalogReferencePageLeft:Show() end
        if catalogReferencePageRight then catalogReferencePageRight:Show() end
        if centerDivider then
            centerDivider:SetSize(2, 486)
            centerDivider:ClearAllPoints()
            centerDivider:SetPoint("TOP", SpellDraftBookFrame, "TOP", 0, -137)
            centerDivider:SetVertexColor(0.2, 0.2, 0.2, 0.4)
            centerDivider:Show()
        end
        if talentsTitleText then talentsTitleText:Show() end
        if catalogLeftChapterText then catalogLeftChapterText:Hide() end
        if catalogRightChapterText then catalogRightChapterText:Hide() end
        if catalogLeftChapterRule then catalogLeftChapterRule:Hide() end
        if catalogRightChapterRule then catalogRightChapterRule:Hide() end
        if catalogLeftLeafText then catalogLeftLeafText:Hide() end
        if catalogRightLeafText then catalogRightLeafText:Hide() end
        if catalogPageTurnFeedback then
            catalogPageTurnFeedback:SetScript("OnUpdate", nil)
            catalogPageTurnFeedback:Hide()
        end
        if SpellDraftTalentsFrame and SpellDraftBookFrame:IsShown() then
            SpellDraftTalentsFrame:Show()
            SpellDraft.RefreshTalentsList()
        end
    end

    for i, btn in ipairs(buttons) do
        local col, row, x, width, height, y
        if catalogExpanded then
            -- Nine wide cards per physical page: left page first, then right.
            -- Page size remains 18, so filtering/paging semantics do not change.
            col = math.floor((i - 1) / 9)
            row = (i - 1) % 9
            x = 42 + col * 506
            width = 448
            -- Keep the ninth row above the bottom page-turn controls. The icon
            -- remains 42px, while the row itself and its pitch are compacted
            -- just enough to leave a clear gap above both arrow buttons.
            height = 40
            y = -202 - row * 43
        else
            col = (i - 1) % 2
            row = math.floor((i - 1) / 2)
            -- Keep the compact catalog visually inside the left parchment.
            -- x=42 left only 20px after the page edge and made the first icon
            -- look pinned to the binding.  The smaller 210px cards retain a
            -- balanced gutter on both sides after moving both columns right.
            x = 54 + col * 232
            width = 210
            height = 44
            y = -198 - row * 62
        end
        btn:ClearAllPoints()
        btn:SetSize(width, height)
        btn:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", x, y)

        -- Compact skill/talent split uses a quieter icon scale so the artwork
        -- supports the text instead of dominating the parchment.  Expanded
        -- two-page mode restores the proven 42/38px geometry and therefore
        -- keeps the existing ninth-row/page-arrow clearance unchanged.
        local frameSize = catalogExpanded and 42 or 38
        local iconSize = catalogExpanded and 38 or 34
        btn.border:SetSize(frameSize, frameSize)
        btn.slotBg:SetSize(frameSize, frameSize)
        btn.icon:SetSize(iconSize, iconSize)
        btn.iconRound:SetSize(iconSize, iconSize)
        btn.cooldown:SetSize(iconSize, iconSize)
        btn.activeGlow:SetSize(catalogExpanded and 54 or 48, catalogExpanded and 54 or 48)
        btn.typeHoverGlow:SetSize(catalogExpanded and 50 or 46, catalogExpanded and 50 or 46)
        if btn.rankChainFrame then btn.rankChainFrame:SetSize(frameSize, frameSize) end
        if btn.iconHighlight then btn.iconHighlight:SetSize(frameSize, frameSize) end
        if btn.rarityRail then btn.rarityRail:SetSize(3, catalogExpanded and 40 or 36) end
        if btn.typeBadgeBg then btn.typeBadgeBg:SetSize(catalogExpanded and 54 or 50, catalogExpanded and 17 or 16) end
        if btn.typeBadgeText then btn.typeBadgeText:SetWidth(catalogExpanded and 50 or 46) end
        -- Reserve the right edge for the active/passive pill in both compact
        -- and expanded modes. Chinese names remain clear and expanded cards
        -- gain extra room automatically.
        btn.name:SetWidth(width - (catalogExpanded and 118 or 104))
        btn.subtext:SetWidth(width - (catalogExpanded and 118 or 104))
        if not catalogExpanded and i > 12 then btn:Hide() end
    end

    if pageNavigationFrame then
        pageNavigationFrame:ClearAllPoints()
        -- Compact mode centres the controls under the left skill leaf. When
        -- the catalog occupies both pages, the complete spread indicator is
        -- centred beneath the right leaf as requested.
        pageNavigationFrame:SetPoint("BOTTOMLEFT", SpellDraftBookFrame, "BOTTOMLEFT",
            catalogExpanded and 670 or 145, 27)
    end
end

local function SetCatalogExpanded(expanded)
    expanded = expanded and true or false
    if expanded == catalogExpanded then return true end
    if InCombatLockdown() then
        UIErrorsFrame:AddMessage(L("The catalog layout cannot change during combat."), 1.0, 0.2, 0.2, 1)
        return false
    end
    catalogExpanded = expanded
    currentPage = 1
    ApplyCatalogLayout()
    SpellDraft.RefreshSpellBook()
    PlaySound("igSpellBookPageTurn")
    return true
end



-- ----------------------------------------------------------------------------
-- Initialization on PLAYER_LOGIN
-- ----------------------------------------------------------------------------
local function InitializeGrimoire()
    -- 1. Create Standalone Window Frame (strata set to HIGH to ensure it renders on top)
    SpellDraftBookFrame = CreateFrame("Frame", "SpellDraftBookFrame", UIParent)
    SpellDraftBookFrame:SetSize(1040, 650)
    SpellDraftBookFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    SpellDraftBookFrame:SetFrameStrata("HIGH")
    SpellDraftBookFrame:SetClampedToScreen(true)
    SpellDraftBookFrame:Hide()
    
    -- Allow window dragging
    SpellDraftBookFrame:SetMovable(true)
    SpellDraftBookFrame:EnableMouse(true)
    SpellDraftBookFrame:RegisterForDrag("LeftButton")
    SpellDraftBookFrame:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end

        -- The talent view can contain hundreds of regions. Hide the child frames
        -- while moving and leave only a light preview behind; restore them on stop.
        self.dragHiddenChildren = {}
        local children = { self:GetChildren() }
        for _, child in ipairs(children) do
            if child ~= self.dragOverlay and child:IsShown() then
                table.insert(self.dragHiddenChildren, child)
                child:Hide()
            end
        end
        self.dragHiddenRegions = {}
        local regions = { self:GetRegions() }
        for _, region in ipairs(regions) do
            if region:IsShown() then
                table.insert(self.dragHiddenRegions, region)
                region:Hide()
            end
        end
        if self.dragOverlay then self.dragOverlay:Show() end
        self:StartMoving()
    end)
    SpellDraftBookFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if self.dragOverlay then self.dragOverlay:Hide() end
        if self.dragHiddenChildren then
            for _, child in ipairs(self.dragHiddenChildren) do
                child:Show()
            end
            self.dragHiddenChildren = nil
        end
        if self.dragHiddenRegions then
            for _, region in ipairs(self.dragHiddenRegions) do
                region:Show()
            end
            self.dragHiddenRegions = nil
        end
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
        if point then
            SpellDraftDB = SpellDraftDB or {}
            SpellDraftDB.BookFramePoint = {
                point = point,
                relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
                relativePoint = relativePoint,
                xOfs = xOfs,
                yOfs = yOfs
            }
        end
    end)
    
    -- Escape Key support
    tinsert(UISpecialFrames, "SpellDraftBookFrame")
    
    -- Frameless outer shell: the open parchment is now the visible window
    -- silhouette.  The parent frame remains fully interactive and draggable,
    -- but the former rectangular DialogBox border, black backing plate and
    -- dark header strip are deliberately absent.

    advancementBackground = SpellDraftBookFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    advancementBackground:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 22, -132)
    advancementBackground:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -22, 22)
    advancementBackground:SetTexture(ASCENSION_TEXTURE_PATH .. "CharacterAdvancementBackgrounds")
    advancementBackground:SetVertexColor(1, 1, 1, 0.98)
    ApplyAscensionBackground("ALL")

    -- B0.9.1g: original two-page parchment made specifically for SpellDraft.
    -- It is deliberately isolated to expanded catalog mode; compact mode
    -- keeps the proven Ascension background and talent-tree presentation.
    -- BORDER places the parchment below all child-frame cards and controls
    -- while its own irregular edges define the visible window silhouette.
    catalogParchmentBackground = SpellDraftBookFrame:CreateTexture(nil, "BORDER", nil, -8)
    catalogParchmentBackground:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 22, -132)
    catalogParchmentBackground:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -22, 22)
    -- Use an explicit BLP path. BLP2/DXT1 is the native client format and
    -- avoids extension probing differences between legacy 3.3.5 builds.
    catalogParchmentBackground:SetTexture(ORIGINAL_TEXTURE_PATH .. "SpellDraftParchmentSpread.blp")
    catalogParchmentBackground:SetTexCoord(0, 1, 0, 1)
    catalogParchmentBackground:SetVertexColor(0.92, 0.88, 0.80, 0.94)
    catalogParchmentBackground:Show()

    -- B0.9.1g.2 local comparison: the reference file is a texture atlas, not
    -- a ready-to-stretch page. Reproduce only the two page slices declared by
    -- its SpellBook.xml. They sit one BORDER sublevel above our original
    -- parchment so removing these two textures restores the original safely.
    catalogReferencePageLeft = SpellDraftBookFrame:CreateTexture(nil, "BORDER", nil, -7)
    -- Extend the physical pages behind the title and class chapter tabs so
    -- the header belongs to the same open book instead of a separate black
    -- control strip.
    catalogReferencePageLeft:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 22, -17)
    catalogReferencePageLeft:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOM", -2, 22)
    catalogReferencePageLeft:SetTexture(REFERENCE_TEXTURE_PATH .. "SpellbookBackgroundEvergreen.blp")
    catalogReferencePageLeft:SetTexCoord(0.446289, 0.839844, 0.0595703, 0.845703)
    catalogReferencePageLeft:Show()

    catalogReferencePageRight = SpellDraftBookFrame:CreateTexture(nil, "BORDER", nil, -7)
    catalogReferencePageRight:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOP", 2, -17)
    catalogReferencePageRight:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -22, 22)
    catalogReferencePageRight:SetTexture(REFERENCE_TEXTURE_PATH .. "SpellbookBackgroundEvergreen.blp")
    catalogReferencePageRight:SetTexCoord(0.000488281, 0.394531, 0.0595703, 0.845703)
    catalogReferencePageRight:Show()

    leftPanelBg = SpellDraftBookFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    leftPanelBg:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 22, -132)
    leftPanelBg:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOM", -8, 22)
    leftPanelBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    leftPanelBg:SetVertexColor(0.18, 0.105, 0.045, 0.08)

    rightPanelBg = SpellDraftBookFrame:CreateTexture(nil, "BACKGROUND", nil, -7)
    rightPanelBg:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOP", 8, -132)
    rightPanelBg:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -22, 22)
    rightPanelBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    rightPanelBg:SetVertexColor(0.0, 0.0, 0.0, 0.22)
    
    -- Center Divider Line
    centerDivider = SpellDraftBookFrame:CreateTexture(nil, "ARTWORK")
    centerDivider:SetSize(2, 486)
    centerDivider:SetPoint("TOP", SpellDraftBookFrame, "TOP", 0, -137)
    centerDivider:SetTexture("Interface\\Buttons\\WHITE8x8")
    centerDivider:SetVertexColor(0.2, 0.2, 0.2, 0.4)

    -- Page-edge feedback uses two narrow stock textures and never intercepts
    -- the mouse. Only the edge in the chosen turn direction fades briefly.
    catalogPageTurnFeedback = CreateFrame("Frame", nil, SpellDraftBookFrame)
    catalogPageTurnFeedback:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 22, -178)
    catalogPageTurnFeedback:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -22, 42)
    catalogPageTurnFeedback:SetFrameLevel(SpellDraftBookFrame:GetFrameLevel() + 3)
    local leftTurnGlow = catalogPageTurnFeedback:CreateTexture(nil, "OVERLAY")
    leftTurnGlow:SetWidth(16)
    leftTurnGlow:SetPoint("TOPLEFT")
    leftTurnGlow:SetPoint("BOTTOMLEFT")
    leftTurnGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    leftTurnGlow:SetVertexColor(1.0, 0.72, 0.20, 1.0)
    leftTurnGlow:Hide()
    catalogPageTurnFeedback.leftGlow = leftTurnGlow
    local rightTurnGlow = catalogPageTurnFeedback:CreateTexture(nil, "OVERLAY")
    rightTurnGlow:SetWidth(16)
    rightTurnGlow:SetPoint("TOPRIGHT")
    rightTurnGlow:SetPoint("BOTTOMRIGHT")
    rightTurnGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    rightTurnGlow:SetVertexColor(1.0, 0.72, 0.20, 1.0)
    rightTurnGlow:Hide()
    catalogPageTurnFeedback.rightGlow = rightTurnGlow
    catalogPageTurnFeedback:Hide()

    -- Close Button
    local closeBtn = CreateFrame("Button", "SpellDraftBookFrameCloseButton", SpellDraftBookFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", SpellDraftBookFrame, "TOPRIGHT", -22, -17)
    closeBtn:SetScript("OnClick", function()
        SpellDraftBookFrame:Hide()
    end)

    -- Visible language selector.  Slash commands remain available as a
    -- fallback, but players no longer need to remember them.
    languageBtn = CreateFrame("Button", "SpellDraftLanguageButton", SpellDraftBookFrame, "UIPanelButtonTemplate")
    languageBtn:SetSize(112, 22)
    -- Compact layout aligns it with Cancel/Confirm; expanded layout moves it
    -- into the right-page toolbar from ApplyCatalogLayout().
    languageBtn:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -252, 58)
    languageBtn:SetText(L("Language") .. ": " .. SpellDraft.GetLanguageLabel())

    languageMenu = CreateFrame("Frame", "SpellDraftLanguageMenu", SpellDraftBookFrame)
    languageMenu:SetSize(146, 88)
    -- ApplyCatalogLayout reverses this anchor in expanded mode so the menu
    -- opens into the page rather than over the class navigation row.
    languageMenu:SetPoint("BOTTOMRIGHT", languageBtn, "TOPRIGHT", 0, 2)
    languageMenu:SetFrameLevel(SpellDraftBookFrame:GetFrameLevel() + 60)
    languageMenu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    languageMenu:SetBackdropColor(0.04, 0.035, 0.03, 0.98)
    languageMenu:SetBackdropBorderColor(0.65, 0.48, 0.18, 1)
    languageMenu:Hide()

    local languageOptions = {
        { setting = "auto", label = "Automatic" },
        { setting = "zhCN", label = "Chinese" },
        { setting = "enUS", label = "English" },
    }
    for i, option in ipairs(languageOptions) do
        local optionSetting = option.setting
        local optionLabel = option.label
        local optionBtn = CreateFrame("Button", nil, languageMenu, "UIPanelButtonTemplate")
        optionBtn:SetSize(126, 22)
        optionBtn:SetPoint("TOP", languageMenu, "TOP", 0, -8 - (i - 1) * 24)
        local selected = SpellDraft.GetLanguageSetting() == optionSetting
        optionBtn:SetText((selected and "|cffffd36a> |r" or "") .. L(optionLabel))
        optionBtn:SetScript("OnClick", function()
            SpellDraft.SetLanguage(optionSetting)
        end)
    end

    languageBtn:SetScript("OnClick", function()
        if languageMenu:IsShown() then languageMenu:Hide() else languageMenu:Show() end
    end)
    languageBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L("Language"))
        GameTooltip:AddLine(L("Automatic") .. " / " .. L("Chinese") .. " / " .. L("English"), 1, 1, 1)
        GameTooltip:Show()
    end)
    languageBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Lightweight preview shown only while the window is being dragged.
    local dragOverlay = CreateFrame("Frame", nil, SpellDraftBookFrame)
    dragOverlay:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 18, -18)
    dragOverlay:SetPoint("BOTTOMRIGHT", SpellDraftBookFrame, "BOTTOMRIGHT", -18, 18)
    dragOverlay:SetFrameLevel(SpellDraftBookFrame:GetFrameLevel() + 50)
    local dragOverlayBg = dragOverlay:CreateTexture(nil, "BACKGROUND")
    dragOverlayBg:SetAllPoints()
    dragOverlayBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    dragOverlayBg:SetVertexColor(0.055, 0.05, 0.045, 0.97)
    local dragOverlayText = dragOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    dragOverlayText:SetPoint("CENTER")
    dragOverlayText:SetText("|cffffd36a" .. L("Moving Character Advancement...") .. "|r")
    dragOverlay:Hide()
    SpellDraftBookFrame.dragOverlay = dragOverlay

    local windowTitle = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    windowTitle:SetPoint("TOP", SpellDraftBookFrame, "TOP", 0, -30)
    windowTitle:SetText("|cffffd36a" .. L("Character Advancement · Skills & Talents") .. "|r")

    -- Chapter boundary between the class selector and page contents. Two
    -- fine rules on each physical page preserve the parchment aesthetic
    -- while making the navigation/header hierarchy immediately readable.
    local function CreateChapterRule(centerX)
        local leftRule = SpellDraftBookFrame:CreateTexture(nil, "ARTWORK", nil, -2)
        leftRule:SetSize(203, 1)
        leftRule:SetPoint("RIGHT", SpellDraftBookFrame, "TOPLEFT", centerX - 10, -133)
        leftRule:SetTexture("Interface\\Buttons\\WHITE8x8")
        leftRule:SetVertexColor(0.35, 0.18, 0.06, 0.70)

        local rightRule = SpellDraftBookFrame:CreateTexture(nil, "ARTWORK", nil, -2)
        rightRule:SetSize(203, 1)
        rightRule:SetPoint("LEFT", SpellDraftBookFrame, "TOPLEFT", centerX + 10, -133)
        rightRule:SetTexture("Interface\\Buttons\\WHITE8x8")
        rightRule:SetVertexColor(0.35, 0.18, 0.06, 0.70)

        local ornament = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        ornament:SetPoint("CENTER", SpellDraftBookFrame, "TOPLEFT", centerX, -133)
        ornament:SetText("◆")
        ornament:SetTextColor(0.58, 0.34, 0.12, 0.85)
    end
    CreateChapterRule(265)
    CreateChapterRule(774)

    -- A restrained translucent title ribbon sits below each rule. It is a
    -- parchment-toned emphasis, not a return to the old opaque black header.
    sectionTitleBandLeft = SpellDraftBookFrame:CreateTexture(nil, "BORDER", nil, -5)
    sectionTitleBandLeft:SetSize(250, 20)
    sectionTitleBandLeft:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 265, -137)
    sectionTitleBandLeft:SetTexture("Interface\\Buttons\\WHITE8x8")
    sectionTitleBandLeft:SetVertexColor(0.24, 0.11, 0.035, 0.13)

    sectionTitleBandRight = SpellDraftBookFrame:CreateTexture(nil, "BORDER", nil, -5)
    sectionTitleBandRight:SetSize(250, 20)
    sectionTitleBandRight:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 780, -137)
    sectionTitleBandRight:SetTexture("Interface\\Buttons\\WHITE8x8")
    sectionTitleBandRight:SetVertexColor(0.24, 0.11, 0.035, 0.13)

    -- Section headings
    grimoireTitleText = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    -- Keep the title on its own row.  The old toolbar shared y=-137 with
    -- this label and covered part of the Chinese text at common UI scales.
    grimoireTitleText:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 265, -143)
    grimoireTitleText:SetText("|cffffd36a" .. L("Skill Catalog") .. "|r")
    
    -- Title Text (Right Page)
    talentsTitleText = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    talentsTitleText:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 780, -143)
    talentsTitleText:SetText("|cffffd36a" .. L("Talent Trees") .. "|r")

    -- Expanded catalog chapter headings. They are hidden in the normal
    -- skill/talent split and shown only when both physical pages belong to the
    -- skill book. Stock textures keep this safe for the 3.3.5 client.
    catalogLeftChapterText = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    -- Expanded toolbar buttons occupy y=163..185. Keep the chapter metadata
    -- below that control row and its separator immediately above the cards.
    catalogLeftChapterText:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 266, -187)
    catalogLeftChapterText:SetTextColor(0.96, 0.78, 0.36)
    catalogLeftChapterText:Hide()

    catalogRightChapterText = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    catalogRightChapterText:SetPoint("TOP", SpellDraftBookFrame, "TOPLEFT", 774, -187)
    catalogRightChapterText:SetTextColor(0.96, 0.78, 0.36)
    catalogRightChapterText:Hide()

    catalogLeftChapterRule = SpellDraftBookFrame:CreateTexture(nil, "ARTWORK")
    catalogLeftChapterRule:SetSize(390, 1)
    catalogLeftChapterRule:SetPoint("TOP", catalogLeftChapterText, "BOTTOM", 0, -4)
    catalogLeftChapterRule:SetTexture("Interface\\Buttons\\WHITE8x8")
    catalogLeftChapterRule:SetVertexColor(0.58, 0.38, 0.14, 0.55)
    catalogLeftChapterRule:Hide()

    catalogRightChapterRule = SpellDraftBookFrame:CreateTexture(nil, "ARTWORK")
    catalogRightChapterRule:SetSize(390, 1)
    catalogRightChapterRule:SetPoint("TOP", catalogRightChapterText, "BOTTOM", 0, -4)
    catalogRightChapterRule:SetTexture("Interface\\Buttons\\WHITE8x8")
    catalogRightChapterRule:SetVertexColor(0.58, 0.38, 0.14, 0.55)
    catalogRightChapterRule:Hide()

    -- Small folio numbers make the expanded view read as two physical pages.
    catalogLeftLeafText = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    catalogLeftLeafText:SetPoint("BOTTOM", SpellDraftBookFrame, "BOTTOMLEFT", 266, 31)
    catalogLeftLeafText:SetTextColor(0.55, 0.38, 0.18)
    catalogLeftLeafText:Hide()
    catalogRightLeafText = SpellDraftBookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    catalogRightLeafText:SetPoint("BOTTOM", SpellDraftBookFrame, "BOTTOMLEFT", 774, 31)
    catalogRightLeafText:SetTextColor(0.55, 0.38, 0.18)
    catalogRightLeafText:Hide()
    
    -- Stats Panel (relocated to the top bar)
    local statsFrame = CreateFrame("Frame", "SpellDraftStatsFrame", SpellDraftBookFrame)
    statsFrame:SetSize(620, 22)
    statsFrame:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 32, -112)
    
    -- Shop Button next to prestige text
    local shopBtn = CreateFrame("Button", "SpellDraftPrestigeShopButton", statsFrame)
    shopBtn:SetSize(16, 16)
    shopBtn:SetPoint("LEFT", statsFrame, "LEFT", 0, 0)
    shopBtn:SetNormalTexture("Interface\\Minimap\\TRACKING\\Auctioneer")
    shopBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    shopBtn:Hide() -- Hidden by default until UpdateStatsDisplay shows it

    prestigeText = statsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    prestigeText:SetPoint("LEFT", statsFrame, "LEFT", 0, 0)
    prestigeText:SetJustifyH("LEFT")

    shopBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cffffcc00" .. L("Prestige Shop") .. "|r")
        GameTooltip:AddLine(L("Click to open the Prestige Shop to spend your Prestige Tokens."), 1, 1, 1)
        local tokens = SpellDraft.PrestigeTokens or 0
        GameTooltip:AddLine(L("Your Tokens: %d", tokens), 1, 1, 1)
        GameTooltip:Show()
    end)
    shopBtn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    shopBtn:SetScript("OnClick", function()
        if SpellDraft.TogglePrestigeShop then
            SpellDraft.TogglePrestigeShop()
        end
    end)

    SpellDraft.ShopButton = shopBtn

    rerollsText = statsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    rerollsText:SetPoint("LEFT", statsFrame, "LEFT", 210, 0)
    rerollsText:SetJustifyH("LEFT")

    bansText = statsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    bansText:SetPoint("LEFT", statsFrame, "LEFT", 330, 0)
    bansText:SetJustifyH("LEFT")

    draftsText = statsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    draftsText:SetPoint("LEFT", statsFrame, "LEFT", 450, 0)
    draftsText:SetJustifyH("LEFT")

    -- Dedicated second-row toolbar.  Keeping all controls on one parent
    -- prevents localized titles and search text from drifting into each
    -- other when the client UI scale changes.
    catalogToolbar = CreateFrame("Frame", "SpellDraftCatalogToolbar", SpellDraftBookFrame)
    catalogToolbar:SetSize(470, 24)
    catalogToolbar:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 54, -163)
    
    -- Catalog filters: status and interaction type. Compact cycling buttons
    -- keep the 3.3.5 implementation independent from retail dropdown APIs.
    local function RefreshCatalogFilterLabels()
        if statusFilterBtn then
            local labels = { ALL = "All statuses", LEARNED = "Learned only", UNLEARNED = "Unlearned only" }
            statusFilterBtn:SetText(L(labels[catalogStatusFilter]))
        end
        if typeFilterBtn then
            local labels = { ALL = "All types", ACTIVE = "Active only", PASSIVE = "Passive only" }
            typeFilterBtn:SetText(L(labels[catalogTypeFilter]))
        end
    end

    statusFilterBtn = CreateFrame("Button", "SpellDraftCatalogStatusFilter", SpellDraftBookFrame, "UIPanelButtonTemplate")
    statusFilterBtn:SetSize(104, 22)
    statusFilterBtn:SetPoint("TOPLEFT", catalogToolbar, "TOPLEFT", 0, 0)
    statusFilterBtn:SetScript("OnClick", function()
        if catalogStatusFilter == "ALL" then catalogStatusFilter = "LEARNED"
        elseif catalogStatusFilter == "LEARNED" then catalogStatusFilter = "UNLEARNED"
        else catalogStatusFilter = "ALL" end
        currentPage = 1
        SaveCatalogPreferences()
        RefreshCatalogFilterLabels()
        SpellDraft.RefreshSpellBook()
    end)

    typeFilterBtn = CreateFrame("Button", "SpellDraftCatalogTypeFilter", SpellDraftBookFrame, "UIPanelButtonTemplate")
    typeFilterBtn:SetSize(104, 22)
    typeFilterBtn:SetPoint("LEFT", statusFilterBtn, "RIGHT", 6, 0)
    typeFilterBtn:SetScript("OnClick", function()
        if catalogTypeFilter == "ALL" then catalogTypeFilter = "ACTIVE"
        elseif catalogTypeFilter == "ACTIVE" then catalogTypeFilter = "PASSIVE"
        else catalogTypeFilter = "ALL" end
        currentPage = 1
        SaveCatalogPreferences()
        RefreshCatalogFilterLabels()
        SpellDraft.RefreshSpellBook()
    end)
    LoadCatalogPreferences()
    RefreshCatalogFilterLabels()

    -- 3. Expanded Search Box (Tucked next to the right header)
    searchBox = CreateFrame("EditBox", "SpellDraftBookSearchBox", SpellDraftBookFrame, "InputBoxTemplate")
    searchBox:SetSize(170, 20)
    searchBox:SetPoint("LEFT", typeFilterBtn, "RIGHT", 14, 0)
    searchBox:SetAutoFocus(false)
    
    local searchPlaceholder = searchBox:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    searchPlaceholder:SetPoint("LEFT", searchBox, "LEFT", 4, 0)
    searchPlaceholder:SetText(L("Search spells..."))
    
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text == "" then
            searchPlaceholder:Show()
        else
            searchPlaceholder:Hide()
        end
        currentPage = 1
        SpellDraft.RefreshSpellBook()
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    catalogExpandBtn = CreateFrame("Button", "SpellDraftCatalogExpandButton", SpellDraftBookFrame, "UIPanelButtonTemplate")
    catalogExpandBtn:SetSize(72, 22)
    catalogExpandBtn:SetText(L("Expand"))
    catalogExpandBtn:SetScript("OnClick", function()
        SetCatalogExpanded(not catalogExpanded)
    end)
    catalogExpandBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L(catalogExpanded and "Restore the talent tree" or "Expand the skill catalog"))
        GameTooltip:Show()
    end)
    catalogExpandBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 5. Prev/Next Page Controls. A fixed-width container keeps the complete
    -- triangle / page label / triangle group centred even when localized page
    -- text changes width.
    pageNavigationFrame = CreateFrame("Frame", "SpellDraftBookPageNavigation", SpellDraftBookFrame)
    pageNavigationFrame:SetSize(220, 32)
    pageNavigationFrame:SetPoint("BOTTOMLEFT", SpellDraftBookFrame, "BOTTOMLEFT", 145, 27)

    prevPageBtn = CreateFrame("Button", "SpellDraftBookPrevPageButton", pageNavigationFrame)
    prevPageBtn:SetSize(32, 32)
    prevPageBtn:SetPoint("LEFT", pageNavigationFrame, "LEFT", 0, 0)
    prevPageBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prevPageBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prevPageBtn:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    prevPageBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        prevPageBtn:SetScript("OnClick", function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            SpellDraft.RefreshSpellBook()
            PlayCatalogPageFeedback("PREV")
            PlaySound("igSpellBookPageTurn")
        end
    end)
    
    pageText = pageNavigationFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    pageText:SetWidth(136)
    pageText:SetPoint("CENTER", pageNavigationFrame, "CENTER", 0, 0)
    pageText:SetJustifyH("CENTER")
    pageText:SetText(L("Page %d of %d", 1, 1))

    nextPageBtn = CreateFrame("Button", "SpellDraftBookNextPageButton", pageNavigationFrame)
    nextPageBtn:SetSize(32, 32)
    nextPageBtn:SetPoint("RIGHT", pageNavigationFrame, "RIGHT", 0, 0)
    nextPageBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nextPageBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nextPageBtn:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    nextPageBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    nextPageBtn:SetScript("OnClick", function()
        local totalSpells = #filteredSpells
        local totalPages = math.max(1, math.ceil(totalSpells / GetCatalogPageSize()))
        if currentPage < totalPages then
            currentPage = currentPage + 1
            SpellDraft.RefreshSpellBook()
            PlayCatalogPageFeedback("NEXT")
            PlaySound("igSpellBookPageTurn")
        end
    end)
    
    -- 6. Create Standalone Custom Spell Slots Grid (Shifted to Right Page)
    for i = 1, 18 do
        local btn = CreateFrame("Button", "SpellDraftBookSpellButton" .. i, SpellDraftBookFrame, "SecureActionButtonTemplate")
        btn:SetSize(210, 44)

        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local x = 54 + col * 232
        -- First content row starts below the dedicated toolbar instead of
        -- touching/covering it.
        local y = -198 - row * 62
        btn:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", x, y)

        local rowBg = btn:CreateTexture(nil, "BACKGROUND")
        rowBg:SetAllPoints(btn)
        rowBg:SetTexture(ASCENSION_TEXTURE_PATH .. "Spell_Bg")
        rowBg:SetVertexColor(1, 1, 1, 0.92)
        btn.rowBg = rowBg

        -- A narrow rarity rail makes card scanning faster than relying on the
        -- icon frame alone, especially when several grey unlearned cards sit
        -- next to each other.
        local rarityRail = btn:CreateTexture(nil, "BORDER")
        rarityRail:SetSize(3, 36)
        rarityRail:SetPoint("LEFT", btn, "LEFT", -4, 0)
        rarityRail:SetTexture("Interface\\Buttons\\WHITE8x8")
        rarityRail:Hide()
        btn.rarityRail = rarityRail

        -- Colored rarity frame: a solid square that peeks out ~2px around the icon.
        local border = btn:CreateTexture(nil, "BORDER")
        border:SetSize(38, 38)
        border:SetPoint("LEFT", btn, "LEFT", 0, 0)
        border:SetTexture(ASCENSION_TEXTURE_PATH .. "SpellKitSpellBorder")
        border:Hide()
        btn.border = border

        -- Dark slot backing behind the icon
        local slotBg = btn:CreateTexture(nil, "BACKGROUND")
        slotBg:SetSize(38, 38)
        slotBg:SetPoint("CENTER", border, "CENTER", 0, 0)
        slotBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        slotBg:SetVertexColor(0, 0, 0, 0.9)
        btn.slotBg = slotBg

        -- Spell Icon (trimmed to hide the default icon border, centered on the frame)
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(34, 34)
        icon:SetPoint("CENTER", border, "CENTER", 0, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        btn.icon = icon

        -- A recycled texture that has been passed through SetPortraitToTexture
        -- keeps its circular crop.  Use a separate region for passive icons so
        -- an active card can never inherit that crop on a later page.
        local iconRound = btn:CreateTexture(nil, "ARTWORK")
        iconRound:SetSize(34, 34)
        iconRound:SetPoint("CENTER", border, "CENTER", 0, 0)
        iconRound:Hide()
        btn.iconRound = iconRound

        local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        cooldown:SetSize(34, 34)
        cooldown:SetPoint("CENTER", border, "CENTER", 0, 0)
        cooldown:SetFrameLevel(btn:GetFrameLevel() + 2)
        btn.cooldown = cooldown

        -- Lightweight Dragonflight-style state cue: known active buffs/forms
        -- receive a gold action-button glow while their aura is present.
        local activeGlow = btn:CreateTexture(nil, "OVERLAY")
        activeGlow:SetSize(48, 48)
        activeGlow:SetPoint("CENTER", border, "CENTER", 0, 0)
        activeGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        activeGlow:SetBlendMode("ADD")
        activeGlow:SetVertexColor(1.0, 0.72, 0.12, 0.95)
        activeGlow:Hide()
        btn.activeGlow = activeGlow

        -- Retail-style type hover: active skills use a cool blue ring while
        -- passives use a violet ring. It appears only on hover and does not
        -- replace the existing aura-active gold glow above.
        local typeHoverGlow = btn:CreateTexture(nil, "OVERLAY")
        typeHoverGlow:SetSize(46, 46)
        typeHoverGlow:SetPoint("CENTER", border, "CENTER", 0, 0)
        typeHoverGlow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        typeHoverGlow:SetBlendMode("ADD")
        typeHoverGlow:Hide()
        btn.typeHoverGlow = typeHoverGlow

        local rankChainFrame = CreateFrame("Frame", nil, btn)
        -- Anchor the overlay frame explicitly instead of SetAllPoints(texture).
        -- This stays inside APIs known to be reliable on the 3.3.5 client.
        rankChainFrame:SetSize(38, 38)
        rankChainFrame:SetPoint("CENTER", border, "CENTER", 0, 0)
        rankChainFrame:SetFrameLevel(btn:GetFrameLevel() + 4)
        local rankChainText = rankChainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rankChainText:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -1, 1)
        rankChainText:SetTextColor(1.0, 0.82, 0.18)
        rankChainText:SetShadowColor(0, 0, 0, 1)
        rankChainText:SetShadowOffset(1, -1)
        local rankFont, rankFontSize = rankChainText:GetFont()
        if rankFont and rankFontSize then rankChainText:SetFont(rankFont, rankFontSize, "OUTLINE") end
        rankChainText:Hide()
        btn.rankChainFrame = rankChainFrame
        btn.rankChainText = rankChainText

        -- The entire row receives a very soft type-colored hover wash. This
        -- mirrors the modern spellbook's full-card feedback while preserving
        -- the project's own Ascension parchment/card texture.
        local cardHover = btn:CreateTexture(nil, "HIGHLIGHT")
        cardHover:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        cardHover:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        cardHover:SetTexture("Interface\\Buttons\\WHITE8x8")
        cardHover:SetBlendMode("ADD")
        btn.cardHover = cardHover

        -- Spell Name
        local name = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        name:SetPoint("TOPLEFT", border, "TOPRIGHT", 8, 0)
        name:SetJustifyH("LEFT")
        name:SetWidth(106)
        btn.name = name

        -- Rank & Rarity Text
        local subtext = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        subtext:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        subtext:SetJustifyH("LEFT")
        subtext:SetWidth(106)
        btn.subtext = subtext

        local typeBadgeBg = btn:CreateTexture(nil, "ARTWORK")
        typeBadgeBg:SetSize(50, 16)
        typeBadgeBg:SetPoint("RIGHT", btn, "RIGHT", -7, 0)
        typeBadgeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        typeBadgeBg:SetVertexColor(0.08, 0.38, 0.68, 0.92)
        btn.typeBadgeBg = typeBadgeBg

        local typeBadgeText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        typeBadgeText:SetPoint("CENTER", typeBadgeBg, "CENTER", 0, 0)
        typeBadgeText:SetWidth(46)
        typeBadgeText:SetJustifyH("CENTER")
        typeBadgeText:SetTextColor(1, 1, 1)
        btn.typeBadgeText = typeBadgeText

        -- Hover highlight over the icon
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetSize(38, 38)
        highlight:SetPoint("CENTER", border, "CENTER", 0, 0)
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")
        btn.iconHighlight = highlight
        
        -- Interactive mouse actions
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        
        btn:SetScript("OnEnter", function(self)
            if self.spellId then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                -- The 3.3.5/V16 SetSpellByID path often leaves cross-class,
                -- passive and unlearned catalog entries with no native body.
                -- A spell hyperlink is the same proven path used by the
                -- talent tree and reliably renders the complete client DBC
                -- tooltip before our SpellDraft-only annotations.
                GameTooltip:SetHyperlink("spell:" .. tostring(self.spellId))
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffffd36a" .. L("SpellDraft Status") .. "|r")
                GameTooltip:AddLine((self.passive and L("Passive") or L("Active"))
                    .. " · " .. (self.known and L("Learned") or L("Unlearned")),
                    self.known and 0.3 or 0.65, self.known and 1.0 or 0.65, self.known and 0.3 or 0.65)
                if not self.known then
                    GameTooltip:AddLine(L("Known skills are bright; unlearned pool skills are grey."), 0.75, 0.7, 0.62, true)
                end
                if self.rankCount and self.rankCount > 1 then
                    GameTooltip:AddLine(L("Collapsed rank chain: %d ranks", self.rankCount), 0.45, 0.75, 1.0, true)
                end
                GameTooltip:Show()
                if self.typeHoverGlow then self.typeHoverGlow:Show() end
            end
        end)
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.typeHoverGlow then self.typeHoverGlow:Hide() end
        end)
        
        -- Action Bar Drag-and-Drop.
        -- In 3.3.5a PickupSpell takes the spellbook slot index + bookType, NOT the
        -- game spell ID. Passing the spell ID picks up nothing (out-of-range slot).
        btn:RegisterForDrag("LeftButton")
        btn:SetScript("OnDragStart", function(self)
            if InCombatLockdown() then return end
            if self.slot then
                -- pcall guards against edge cases (e.g. slot invalidated by relearn)
                pcall(PickupSpell, self.slot, "spell")
            end
        end)
        
        buttons[i] = btn
    end
    
    -- 7. Ascension-style horizontal class browser
    for i, classInfo in ipairs(tabClasses) do
        local tab = CreateFrame("CheckButton", "SpellDraftBookTab" .. i, SpellDraftBookFrame)
        tab:SetSize(36, 36)
        -- Centre the two six-icon chapter groups inside their physical pages.
        -- The previous x=33 origin pressed All against the outer binding and
        -- Death Knight against the centre fold. A 20px inset balances both
        -- pages while keeping the established 82px rhythm and hit areas.
        tab:SetPoint("TOPLEFT", SpellDraftBookFrame, "TOPLEFT", 53 + (i - 1) * 82, -55)

        -- The stock class atlas is square.  Draw it first, cover only its
        -- four corners with a transparent-centre mask, then place the
        -- Ascension gold ring on top.  This gives a real round badge without
        -- replacing Blizzard's class artwork.
        local bg = tab:CreateTexture(nil, "OVERLAY", nil, 7)
        bg:SetSize(52, 52)
        bg:SetPoint("CENTER", tab, "CENTER", 0, 0)
        bg:SetTexture(ASCENSION_TEXTURE_PATH .. "ca-naviatlas")
        bg:SetTexCoord(0, 112 / 1024, 446 / 1024, 558 / 1024)
        tab.bg = bg

        -- Square highlight textures would reveal four bright corners again.
        -- Reuse the circular Ascension ring for hover and selected states.
        tab:SetHighlightTexture(ASCENSION_TEXTURE_PATH .. "ca-naviatlas", "ADD")
        local highlightTex = tab:GetHighlightTexture()
        if highlightTex then
            highlightTex:ClearAllPoints()
            highlightTex:SetPoint("CENTER", tab, "CENTER", 0, 0)
            highlightTex:SetSize(48, 48)
            highlightTex:SetTexCoord(0, 112 / 1024, 446 / 1024, 558 / 1024)
        end

        tab:SetCheckedTexture(ASCENSION_TEXTURE_PATH .. "ca-naviatlas")
        local checkedTex = tab:GetCheckedTexture()
        if checkedTex then
            checkedTex:ClearAllPoints()
            checkedTex:SetPoint("CENTER", tab, "CENTER", 0, 0)
            checkedTex:SetSize(48, 48)
            checkedTex:SetTexCoord(0, 112 / 1024, 446 / 1024, 558 / 1024)
            checkedTex:SetBlendMode("ADD")
        end

        local icon = tab:CreateTexture(nil, "ARTWORK")
        -- The source atlas is square, but the visible window is circular.
        -- Enlarge the artwork behind that window so its flat square sides sit
        -- outside the transparent opening instead of showing inside the ring.
        icon:SetSize(38, 38)
        icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
        if classInfo.isClass then
            -- This is the native 3.3.5 circular class atlas used by the Arena
            -- UI. It has transparent corners, so it belongs naturally on the
            -- parchment and needs no background-coloured square mask.
            icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
            local coords = CLASS_ICON_TCOORDS[classInfo.value]
            if coords then
                icon:SetTexCoord(unpack(coords))
            end
        else
            if classInfo.value == "GENERAL" then
                -- A single dark talent-essence crystal gives Universal a
                -- heavier silhouette while the tab's native gold ring keeps
                -- it consistent with every class selector.
                icon:SetSize(34, 34)
                icon:SetTexture(ORIGINAL_TEXTURE_PATH .. "TalentEssenceCrystal.blp")
                icon:SetTexCoord(0, 1, 0, 1)
            elseif classInfo.value == "ALL" then
                -- Original transparent open grimoire. Unlike stock square
                -- inventory art, it has no opaque corners behind the ring.
                icon:SetSize(32, 32)
                icon:SetTexture(ORIGINAL_TEXTURE_PATH .. "AllAbilitiesBook.blp")
                icon:SetTexCoord(0, 1, 0, 1)
            else
                -- Stock inventory icons are square. Keep them entirely inside
                -- the circular ring so their corners cannot protrude.
                icon:SetSize(26, 26)
                icon:SetTexture(classInfo.icon)
                icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            end
        end
        tab.icon = icon

        -- Previous builds placed a dark, transparent-centre square over every
        -- icon to imitate a circle on the old black header. On parchment its
        -- four opaque corners became the visible black box reported in g.3.
        -- The native circular atlas above makes that compatibility mask
        -- unnecessary, so do not create it.
        tab.circleMask = nil

        local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOP", tab, "BOTTOM", 0, -2)
        label:SetWidth(76)
        label:SetJustifyH("CENTER")
        -- Resolve at render time instead of caching localized class names when
        -- this Lua file is parsed. This follows the active SpellDraft language
        -- reliably on English clients using the Chinese UI override.
        label:SetText(SpellDraft.ClassName(classInfo.value))
        tab.label = label

        -- A chapter underline is clearer than relying on the icon ring alone,
        -- especially for adjacent class colors with similar silhouettes.
        local chapterMarker = tab:CreateTexture(nil, "OVERLAY")
        chapterMarker:SetSize(54, 2)
        chapterMarker:SetPoint("TOP", label, "BOTTOM", 0, -2)
        chapterMarker:SetTexture("Interface\\Buttons\\WHITE8x8")
        chapterMarker:SetVertexColor(1.0, 0.70, 0.18, 0.95)
        chapterMarker:Hide()
        tab.chapterMarker = chapterMarker
        
        tab:SetScript("OnClick", function(self)
            activeClass = classInfo.value
            -- The two book-end chapters have explicit jobs: ALL browses the
            -- complete pool; GENERAL summarizes the current learned build.
            -- Class chapters are also browsing views and therefore start from
            -- all statuses. The player may still cycle the normal filters.
            catalogStatusFilter = activeClass == "GENERAL" and "LEARNED" or "ALL"
            catalogTypeFilter = "ALL"
            if RefreshCatalogFilterLabels then RefreshCatalogFilterLabels() end
            ApplyAscensionBackground(activeClass)
            for j, t in ipairs(tabs) do
                local selected = j == i
                t:SetChecked(selected)
                if t.chapterMarker then
                    if selected then t.chapterMarker:Show() else t.chapterMarker:Hide() end
                end
                if t.label then
                    if selected then t.label:SetTextColor(1.0, 0.82, 0.18)
                    else t.label:SetTextColor(0.78, 0.72, 0.62) end
                end
            end
            currentPage = 1
            SpellDraft.RefreshSpellBook()
            if SpellDraft.RefreshTalentsList then
                SpellDraft.RefreshTalentsList()
            end
            PlaySound("igAbilitiesOpen")
        end)
        
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(SpellDraft.ClassName(classInfo.value))
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        tabs[i] = tab
    end
    local summaryTab = tabs[#tabs]
    summaryTab:SetChecked(true)
    if summaryTab.chapterMarker then summaryTab.chapterMarker:Show() end
    if summaryTab.label then summaryTab.label:SetTextColor(1.0, 0.82, 0.18) end
    ApplyAscensionBackground("GENERAL")
    ApplyCatalogLayout()
    
    -- 8. Setup Refresh Hooks
    SpellDraftBookFrame:SetScript("OnShow", function()
        -- Always open on the useful character summary instead of an empty
        -- talent page under the full-pool chapter.
        activeClass = "GENERAL"
        catalogStatusFilter = "LEARNED"
        catalogTypeFilter = "ALL"
        currentPage = 1
        ApplyAscensionBackground(activeClass)
        for i, t in ipairs(tabs) do
            local selected = i == #tabs
            t:SetChecked(selected)
            if t.chapterMarker then
                if selected then t.chapterMarker:Show() else t.chapterMarker:Hide() end
            end
            if t.label then
                t.label:SetText(SpellDraft.ClassName(tabClasses[i].value))
                if selected then t.label:SetTextColor(1.0, 0.82, 0.18)
                else t.label:SetTextColor(0.78, 0.72, 0.62) end
            end
        end
        if RefreshCatalogFilterLabels then RefreshCatalogFilterLabels() end
        -- Pull authoritative balances each time SpellCraft opens. This also
        -- covers essence gained while the window was closed.
        -- Paint the last server-confirmed per-character ranks first; SC_CHECK
        -- then replaces them asynchronously. This prevents a false 0/5 frame
        -- and prevents the player staging ranks on top of a hidden real rank.
        if SpellDraft.RestoreTalentStateCache then
            SpellDraft.RestoreTalentStateCache(false)
        end
        local playerName = UnitName("player")
        if playerName then
            SendChatMessage("SC_CHECK", "WHISPER", nil, playerName)
        end
        -- Expanded mode is intentionally temporary. Reopening starts from the
        -- proven side-by-side skill + talent layout when secure frames can move.
        if catalogExpanded and not InCombatLockdown() then
            catalogExpanded = false
            currentPage = 1
        end
        -- Always normalize anchors and texture visibility on every open. The
        -- login path can construct this frame before the final UI scale and BLP
        -- atlas are ready, so relying only on the construction-time pass leaves
        -- stale geometry on some logins.
        ApplyCatalogLayout()
        local expectedLayoutGeneration = SpellDraftBookFrame.catalogLayoutGeneration
        if SpellDraft.After then
            SpellDraft.After(0.05, function()
                if SpellDraftBookFrame and SpellDraftBookFrame:IsShown()
                    and expectedLayoutGeneration == SpellDraftBookFrame.catalogLayoutGeneration then
                    ApplyCatalogLayout()
                end
            end)
        end
        SpellDraft.ShowGrimoirePanel()
        if not catalogExpanded then SpellDraft.ShowTalentsPanel() end
        if SpellDraft.UpdateStatsDisplay then
            SpellDraft.UpdateStatsDisplay()
        end
    end)
    
    SpellDraftBookFrame:SetScript("OnHide", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        if talentSearchBox then
            talentSearchBox:SetText("")
            talentSearchBox:ClearFocus()
        end
        talentSearchMatch = nil
        talentSearchTargetSpellId = nil
        activeClass = "GENERAL"
        catalogStatusFilter = "LEARNED"
        catalogTypeFilter = "ALL"
        ApplyAscensionBackground("GENERAL")
        for i, t in ipairs(tabs) do
            t:SetChecked(i == #tabs)
        end
        currentPage = 1
    end)

    -- Refresh spell list when spellbook changes while Grimoire is open
    SpellDraftBookFrame:RegisterEvent("SPELLS_CHANGED")
    SpellDraftBookFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
    SpellDraftBookFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    SpellDraftBookFrame:RegisterEvent("PLAYER_LEVEL_UP")
    SpellDraftBookFrame:RegisterEvent("UNIT_AURA")
    SpellDraftBookFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    SpellDraftBookFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    SpellDraftBookFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_REGEN_ENABLED" then
            if self.catalogPendingRefresh then
                self.catalogPendingRefresh = false
                SpellDraft.RefreshSpellBook()
            end
        elseif event == "UNIT_AURA" then
            if arg1 == "player" and self:IsShown() then SpellDraft.RefreshVisibleCatalogEffects() end
        elseif event == "UPDATE_SHAPESHIFT_FORM" or event == "SPELL_UPDATE_COOLDOWN" then
            if self:IsShown() then SpellDraft.RefreshVisibleCatalogEffects() end
        else
            if not self:IsShown() then return end
            SpellDraft.RefreshSpellBook()
            if SpellDraft.UpdateStatsDisplay then
                SpellDraft.UpdateStatsDisplay()
            end
        end
    end)

    -- Restore position if saved
    if SpellDraftDB and SpellDraftDB.BookFramePoint then
        pcall(function()
            local p = SpellDraftDB.BookFramePoint
            SpellDraftBookFrame:ClearAllPoints()
            SpellDraftBookFrame:SetPoint(p.point, _G[p.relativeTo] or UIParent, p.relativePoint, p.xOfs, p.yOfs)
        end)
    end
end

-- ----------------------------------------------------------------------------
-- Microbar Launcher Button
-- ----------------------------------------------------------------------------

local openButton

local function EnsureSavedVariables()
    SpellDraftDB = SpellDraftDB or {}
    SpellDraftDB.openButton = SpellDraftDB.openButton or {}
end

local function PositionOpenButton(useDefault)
    if not openButton then return end
    EnsureSavedVariables()
    openButton:ClearAllPoints()
    
    local pos = SpellDraftDB.openButton
    if not useDefault and pos.point and pos.relativePoint and pos.x and pos.y then
        openButton:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Default position: Anchor directly to the native WoW Spellbook MicroButton
        -- This guarantees it aligns perfectly across all resolutions and UI scales.
        if SpellbookMicroButton then
            openButton:SetPoint("TOPLEFT", SpellbookMicroButton, "TOPLEFT", 0, 0)
            openButton:SetPoint("BOTTOMRIGHT", SpellbookMicroButton, "BOTTOMRIGHT", 0, 0)
        else
            -- Fallback to your character Nix's calibrated coordinates
            openButton:SetPoint("BOTTOM", UIParent, "BOTTOM", 72.9, 61.6)
        end
    end
end

local function SaveOpenButtonPosition()
    if not openButton then return end
    EnsureSavedVariables()
    local point, _, relativePoint, x, y = openButton:GetPoint(1)
    SpellDraftDB.openButton.point = point
    SpellDraftDB.openButton.relativePoint = relativePoint
    SpellDraftDB.openButton.x = x
    SpellDraftDB.openButton.y = y
end

local function ResetOpenButtonPosition()
    EnsureSavedVariables()
    SpellDraftDB.openButton = {}
    PositionOpenButton(true)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[SpellDraft]|r " .. L("Button position reset."))
end

local function CreateOpenButton()
    if openButton then return end
    
    openButton = CreateFrame("Button", "SpellDraftMicroButton", UIParent)
    openButton:SetSize(32, 64) -- Match physical TGA dimensions
    openButton:SetFrameStrata("HIGH")
    openButton:SetFrameLevel(10)
    openButton:SetMovable(true)
    openButton:EnableMouse(true)
    openButton:SetClampedToScreen(true)
    openButton:RegisterForDrag("LeftButton")
    
    -- Set custom textures
    openButton:SetNormalTexture("Interface\\AddOns\\SpellDraft\\Textures\\grimoire_btn_up")
    openButton:SetPushedTexture("Interface\\AddOns\\SpellDraft\\Textures\\grimoire_btn_down")
    
    -- The stock micro-button highlight is a gold square.  A dedicated alpha
    -- texture brightens only the circular SpellDraft emblem on mouse-over.
    openButton:SetHighlightTexture("Interface\\AddOns\\SpellDraft\\Textures\\grimoire_btn_highlight", "ADD")
    local highlight = openButton:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("ADD")
    end
    
    PositionOpenButton(false)
    openButton:Show()
    
    openButton:SetScript("OnClick", function()
        if not SpellDraftBookFrame then return end
        if SpellDraftBookFrame:IsShown() then
            SpellDraftBookFrame:Hide()
        else
            SpellDraftBookFrame:Show()
        end
    end)
    
    openButton:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    openButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveOpenButtonPosition()
    end)
    
    openButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(L("SpellDraft Grimoire"))
        GameTooltip:AddLine(L("Click to toggle spellbook."), 1, 1, 1)
        GameTooltip:AddLine(L("Drag with Left Click to reposition."), 0.6, 0.8, 1)
        GameTooltip:Show()
    end)
    openButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- ----------------------------------------------------------------------------
-- Slash Command: /spelldraft
-- ----------------------------------------------------------------------------

SLASH_SPELLDRAFT1 = "/spelldraft"
SlashCmdList["SPELLDRAFT"] = function(msg)
    if not SpellDraftBookFrame then DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[SpellDraft]|r " .. L("Grimoire not initialized yet.")) return end
    
    msg = string.lower(msg or "")
    if msg == "reset button" or msg == "resetbutton" or msg == "button reset" then
        ResetOpenButtonPosition()
        return
    end

    if SpellDraftBookFrame:IsShown() then
        SpellDraftBookFrame:Hide()
    else
        SpellDraftBookFrame:Show()
    end
end

-- ----------------------------------------------------------------------------
-- Event Frame for PLAYER_LOGIN initialization
-- ----------------------------------------------------------------------------

local function SetModeButtonVisible(button, visible)
    if not button then return end
    if visible then
        button:SetAlpha(1)
        button:EnableMouse(true)
        button:Show()
    else
        button:Hide()
        button:SetAlpha(0)
        button:EnableMouse(false)
    end
end

local function CharacterModeKey()
    local name = UnitName("player") or ""
    local realm = GetRealmName and (GetRealmName() or "") or ""
    if name == "" then return nil end
    return realm .. ":" .. name
end

local function LoadSavedCharacterMode()
    local key = CharacterModeKey()
    local modes = SpellDraftDB and SpellDraftDB.characterModes
    local mode = key and modes and modes[key]
    if mode == "classic" or mode == "draft" or mode == "free" then
        return mode
    end
    return nil
end

function _G.SpellDraft_SetCharacterModeLocal(mode)
    if mode ~= "classic" and mode ~= "draft" and mode ~= "free" and mode ~= "pending" then return end
    _G.SpellDraftCharacterMode = mode
    local key = CharacterModeKey()
    if key then
        SpellDraftDB = SpellDraftDB or {}
        SpellDraftDB.characterModes = SpellDraftDB.characterModes or {}
        if mode == "pending" then
            SpellDraftDB.characterModes[key] = nil
        else
            SpellDraftDB.characterModes[key] = mode
        end
    end
    if type(_G.SpellDraft_ApplyModeButtons) == "function" then
        _G.SpellDraft_ApplyModeButtons()
    end
end

local function ApplyModeEntryButtons()
    local mode = _G.SpellDraftCharacterMode or LoadSavedCharacterMode() or "pending"
    local classic = mode == "classic"
    local draft = mode == "draft" or mode == "free"

    -- Classic owns the native talent entry. Draft owns the SpellDraft entry.
    -- Pending owns neither because the mandatory mode picker is still active.
    SetModeButtonVisible(_G.TalentMicroButton, classic)
    SetModeButtonVisible(_G.TalentButton, classic)
    SetModeButtonVisible(openButton, draft)
end

-- The AIO mode synchronizer calls this after the server sends the authoritative
-- per-character mode on every login.
_G.SpellDraft_ApplyModeButtons = ApplyModeEntryButtons

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if not _G.SpellDraftCharacterMode then
            _G.SpellDraftCharacterMode = LoadSavedCharacterMode()
        end
        InitializeGrimoire()
        CreateOpenButton()
        ApplyModeEntryButtons()
        if hooksecurefunc and UpdateMicroButtons then
            hooksecurefunc("UpdateMicroButtons", ApplyModeEntryButtons)
        end
    end
end)

-- ----------------------------------------------------------------------------
-- Tooltip Enhancement: Show spell resource costs for mismatched power types
-- When a Warrior drafts Shadow Bolt, the client hides the "420 Mana" cost
-- because the player's primary power type is Rage. This hook adds it back.
-- Works globally: action bars, native spellbook, Grimoire, anywhere.
-- ----------------------------------------------------------------------------

local POWER_TYPE_INFO = {
    [0] = { name = L("Mana"),        r = 0.00, g = 0.00, b = 1.00 },
    [1] = { name = L("Rage"),        r = 1.00, g = 0.00, b = 0.00 },
    [2] = { name = L("Focus"),       r = 1.00, g = 0.50, b = 0.25 },
    [3] = { name = L("Energy"),      r = 1.00, g = 1.00, b = 0.00 },
    [6] = { name = L("Runic Power"), r = 0.00, g = 0.82, b = 1.00 },
}

GameTooltip:HookScript("OnTooltipSetSpell", function(self)
    local name, id = self:GetSpell()
    if not id then return end

    local _, _, _, cost, _, powerType = GetSpellInfo(id)
    if not cost or cost == 0 then return end

    local playerPowerType = UnitPowerType("player")
    if powerType == playerPowerType then return end -- client already shows it

    local info = POWER_TYPE_INFO[powerType]
    if not info then return end

    self:AddLine(cost .. " " .. info.name, info.r, info.g, info.b)
    self:Show() -- refresh to render the added line
end)
