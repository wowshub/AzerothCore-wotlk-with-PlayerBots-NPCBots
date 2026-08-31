local scriptPath = debug.getinfo(1).source:sub(2)
local parentPath = scriptPath:match("(.+[/\\])") or ""
local rootPath = parentPath:match("(.+[/\\])[^/\\]+[/\\]$") or parentPath
math.randomseed(os.time())
math.random(); math.random(); math.random() -- Warm up generator
dofile(rootPath .. "spelldraft_config.lua")

local lastMsgTimes = {}

-- Playerbots must never enter the draft/prestige system.
-- IsBot() requires mod-ale with playerbots support; fall back to "not a bot" if absent.
local function IsBotPlayer(player)
    return player.IsBot ~= nil and player:IsBot()
end

local function IsRandomDraftMode(player)
    if type(SpellDraft_IsRandomMode) == "function" then
        return SpellDraft_IsRandomMode(player)
    end
    -- Fail closed. Before the three-mode authority loads (or if it fails), a
    -- pending/Classic character must never be treated as Random Draft.
    return false
end

-- B0.9.11E: Random Draft and Free Pick use independent talent nodes.  The
-- native talent_dbc prerequisite graph remains untouched for Classic mode;
-- only SpellDraft's classless validators bypass parent-to-child links.
local function UsesIndependentClasslessTalentNodes(player)
    if not player then return false end
    if type(SpellDraft_IsRandomMode) == "function" and SpellDraft_IsRandomMode(player) then
        return true
    end
    if type(SpellDraft_IsFreePickMode) == "function" and SpellDraft_IsFreePickMode(player) then
        return true
    end
    return false
end

local activeTalentDrafts = {}

-- Tome rerolls use a separate, durable currency. Essence intentionally has no
-- gameplay cap: players may accumulate it like gold. Sellable Essence is
-- tracked separately so a GM can grant bound starter Essence without opening
-- a create/delete-character gold exploit.
local TALENT_ESSENCE_START = math.max(0, math.floor(tonumber(CONFIG.TALENT_ESSENCE_INITIAL_AMOUNT) or 0))
local TALENT_ESSENCE_START_SELLABLE = CONFIG.TALENT_ESSENCE_INITIAL_SELLABLE == true and TALENT_ESSENCE_START or 0
local TALENT_REROLL_COSTS = { 3, 6, 12 }
-- The client/server Item.dbc defines 900100 as a chest and 900101 as cloth
-- legs, so item_template SQL cannot make either entry non-equippable.  800101
-- is an unused DBC-backed book entry whose static class/inventory fields are
-- already non-equippable and match the working SpellDraft Tome-of-Talents path.
local GM_TEST_CARD_ITEM_ENTRY = 800101

CharDBQuery(string.format([[
    CREATE TABLE IF NOT EXISTS `spelldraft_talent_essence` (
        `guid` INT UNSIGNED NOT NULL,
        `essence` INT UNSIGNED NOT NULL DEFAULT %d,
        `sellable_essence` INT UNSIGNED NOT NULL DEFAULT %d,
        `round_rerolls` TINYINT UNSIGNED NOT NULL DEFAULT 0,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`guid`),
        CONSTRAINT `fk_spelldraft_talent_essence_character`
            FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]], TALENT_ESSENCE_START, TALENT_ESSENCE_START_SELLABLE))

-- One physical GM card can represent any SpellDraft reward. The item instance
-- GUID is the durable key, so two cards never exchange their target SpellID and
-- a relog does not erase an unused test card's payload.
CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `spelldraft_gm_test_cards` (
        `item_guid` INT UNSIGNED NOT NULL,
        `owner_guid` INT UNSIGNED NOT NULL,
        `spell_id` INT UNSIGNED NOT NULL,
        `is_talent` TINYINT UNSIGNED NOT NULL DEFAULT 0,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`item_guid`),
        KEY `idx_spelldraft_gm_test_cards_owner` (`owner_guid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

-- Upgrade accounts created by A.31R3 without changing their balance or
-- retroactively making starter gifts sellable.
local sellableColumn = CharDBQuery([[
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'spelldraft_talent_essence'
      AND COLUMN_NAME = 'sellable_essence'
    LIMIT 1
]])
if not sellableColumn then
    CharDBQuery("ALTER TABLE spelldraft_talent_essence ADD COLUMN sellable_essence INT UNSIGNED NOT NULL DEFAULT 0 AFTER essence")
end

local function EnsureTalentEssenceRow(guid)
    CharDBQuery(string.format(
        "INSERT IGNORE INTO spelldraft_talent_essence (guid, essence, sellable_essence, round_rerolls) VALUES (%d, %d, %d, 0)",
        guid, TALENT_ESSENCE_START, TALENT_ESSENCE_START_SELLABLE
    ))
end

local function GetTalentEconomy(guid)
    EnsureTalentEssenceRow(guid)
    local q = CharDBQuery("SELECT essence, round_rerolls FROM spelldraft_talent_essence WHERE guid = " .. guid)
    if not q then return 0, 0 end
    return q:GetUInt32(0), q:GetUInt32(1)
end

local function SendTalentEconomyState(player)
    local essence, used = GetTalentEconomy(player:GetGUIDLow())
    local nextCost = TALENT_REROLL_COSTS[used + 1] or 0
    local refundCost = math.max(0, math.floor(tonumber(CONFIG.TALENT_SINGLE_REFUND_ESSENCE_COST) or 1))
    player:SendAddonMessage("SpellChoiceTalentEssence", tostring(essence), 0, player)
    player:SendAddonMessage("SpellChoiceTalentReroll", tostring(nextCost) .. ":" .. tostring(used) .. ":" .. tostring(#TALENT_REROLL_COSTS), 0, player)
    player:SendAddonMessage("SCTRefundCost", tostring(refundCost), 0, player)
end

local function SendDraftChoices(player, spells)
    local guid = player:GetGUIDLow()
    -- Final publication gate: require a durable locked Random-Draft selection.
    -- No cache/load-order fallback is allowed to display cards over the mode UI
    -- or after Classic was selected.
    local mode = CharDBQuery("SELECT mode, locked FROM spelldraft_character_mode WHERE guid = " .. guid .. " LIMIT 1")
    if not mode or mode:GetUInt8(0) ~= 2 or mode:GetUInt8(1) ~= 1 then
        player:SendAddonMessage("SpellChoiceStatus", "not_prestiged", 0, player)
        player:SendAddonMessage("SpellChoiceClose", "", 0, player)
        return false
    end
    local isTalent = (activeTalentDrafts and activeTalentDrafts[guid]) and "1" or "0"
    player:SendAddonMessage("SpellChoiceIsTalent", isTalent, 0, player)
    if isTalent == "1" then
        SendTalentEconomyState(player)
    end

    player:SendAddonMessage("SpellChoice", table.concat(spells, ","), 0, player)
    local rarityParts = {}
    if #spells > 0 then
        local q = WorldDBQuery("SELECT Id, Rarity FROM dbc_spells WHERE Id IN (" .. table.concat(spells, ",") .. ")")
        local rarityById = {}
        if q then
            repeat
                rarityById[q:GetUInt32(0)] = q:IsNull(1) and "-1" or tostring(q:GetUInt8(1))
            until not q:NextRow()
        end
        for _, id in ipairs(spells) do
            table.insert(rarityParts, rarityById[id] or "-1")
        end
    end
    player:SendAddonMessage("SpellChoiceRarities", table.concat(rarityParts, ","), 0, player)
    return true
end


local DRAFT_MODE_SPELLS = CONFIG.DRAFT_MODE_SPELLS
local DRAFT_CURVE_VERSION = 1

CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `spelldraft_dynamic_progression` (
        `guid` INT UNSIGNED NOT NULL,
        `curve_version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
        `configured_max_level` SMALLINT UNSIGNED NOT NULL,
        `highest_level` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
        `anchor_level` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
        `anchor_entitlement` INT UNSIGNED NOT NULL DEFAULT 1,
        `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`guid`),
        CONSTRAINT `fk_spelldraft_dynamic_progression_character`
            FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function GetConfiguredMaxLevel()
    return Clamp(math.floor(tonumber(CONFIG.MAX_LEVEL) or 255), 2, 255)
end

local function GetDynamicSkillCap(maxLevel)
    maxLevel = Clamp(math.floor(maxLevel or GetConfiguredMaxLevel()), 2, 255)
    local cap
    if maxLevel <= 80 then
        cap = math.floor(maxLevel / 2 + 0.5)
    else
        local ratio = math.log(maxLevel / 80) / math.log(255 / 80)
        cap = 40 + math.floor(10 * ratio + 0.5)
    end
    return Clamp(cap, 1, 50)
end

local function GetExpectedDraftsFormula(class, level)
    local maxLevel = GetConfiguredMaxLevel()
    local cappedLevel = Clamp(math.floor(tonumber(level) or 1), 1, maxLevel)
    local skillCap = math.max(DRAFT_MODE_SPELLS, GetDynamicSkillCap(maxLevel))
    local progress = (cappedLevel - 1) / (maxLevel - 1)
    -- Exponent below 1 front-loads build-defining choices while preserving an
    -- exact, bounded full-level total for every configured level cap.
    return DRAFT_MODE_SPELLS + math.floor((skillCap - DRAFT_MODE_SPELLS) * (progress ^ 0.72) + 0.000001)
end

local function ReadNormalEntitlement(guid)
    local q = CharDBQuery("SELECT total_expected_drafts, bonus_drafts FROM prestige_stats WHERE player_id = " .. guid)
    if not q then return DRAFT_MODE_SPELLS, 0 end
    local total = q:GetUInt32(0)
    local bonus = q:GetUInt32(1)
    return math.max(0, total - bonus), bonus
end


-- Returns the normal (non-consumable) cumulative entitlement. On first use it
-- adopts the character's current counters. If MAX_LEVEL or the curve version
-- changes, it rebases at the historical high: no instant windfall, no removal.
local function ReconcileDynamicProgression(player, candidateLevel, previousLevel)
    local guid = player:GetGUIDLow()
    local currentLevel = math.max(1, math.floor(tonumber(candidateLevel) or player:GetLevel()))
    local maxLevel = GetConfiguredMaxLevel()
    local currentNormal = select(1, ReadNormalEntitlement(guid))
    -- Mode activation can call the dynamic reconciler just before the
    -- prestige_stats row receives its configured starting allowance. Never
    -- anchor a Random Draft character below the real level-1 card count.
    currentNormal = math.max(DRAFT_MODE_SPELLS, currentNormal or 0)
    local state = CharDBQuery(string.format(
        "SELECT curve_version, configured_max_level, highest_level, anchor_level, anchor_entitlement " ..
        "FROM spelldraft_dynamic_progression WHERE guid = %d LIMIT 1", guid))

    if not state then
        local initialHighest = math.max(1, math.floor(tonumber(previousLevel) or currentLevel))
        CharDBQuery(string.format(
            "INSERT IGNORE INTO spelldraft_dynamic_progression " ..
            "(guid, curve_version, configured_max_level, highest_level, anchor_level, anchor_entitlement) " ..
            "VALUES (%d, %d, %d, %d, %d, %d)",
            guid, DRAFT_CURVE_VERSION, maxLevel, initialHighest, initialHighest, currentNormal))
        state = CharDBQuery(string.format(
            "SELECT curve_version, configured_max_level, highest_level, anchor_level, anchor_entitlement " ..
            "FROM spelldraft_dynamic_progression WHERE guid = %d LIMIT 1", guid))
        if not state then return currentNormal, 0 end
    end

    local version = state:GetUInt32(0)
    local savedMax = state:GetUInt32(1)
    local highest = math.max(1, state:GetUInt32(2))
    local anchorLevel = math.max(1, state:GetUInt32(3))
    local anchorEntitlement = state:GetUInt32(4)

    -- Repair characters created during the A.31 hot-selection race, where the
    -- progression row could be anchored at the table default (1) before the
    -- configured initial three drafts were written to prestige_stats.
    if anchorLevel == 1 and anchorEntitlement < DRAFT_MODE_SPELLS then
        anchorEntitlement = DRAFT_MODE_SPELLS
        CharDBQuery(string.format(
            "UPDATE spelldraft_dynamic_progression SET anchor_entitlement=%d WHERE guid=%d",
            anchorEntitlement, guid))
    end

    if version ~= DRAFT_CURVE_VERSION or savedMax ~= maxLevel then
        -- Preserve exactly what the character has already earned/pending at
        -- the moment an administrator changes the cap or algorithm.
        highest = math.max(highest, math.min(currentLevel, maxLevel))
        anchorLevel = highest
        anchorEntitlement = currentNormal
        CharDBQuery(string.format(
            "UPDATE spelldraft_dynamic_progression SET curve_version=%d, configured_max_level=%d, " ..
            "highest_level=%d, anchor_level=%d, anchor_entitlement=%d WHERE guid=%d",
            DRAFT_CURVE_VERSION, maxLevel, highest, anchorLevel, anchorEntitlement, guid))
        return anchorEntitlement, 0
    end

    local newHighest = math.max(highest, math.min(currentLevel, maxLevel))
    -- Re-distribute only the remaining capacity after a rebase. Example:
    -- raising an 80-cap character with 40 earned skills to cap 155 (target 46)
    -- grants exactly six more across levels 81-155, never the raw curve delta.
    local targetCap = math.max(anchorEntitlement, GetDynamicSkillCap(maxLevel))
    local entitlement = anchorEntitlement
    if anchorLevel < maxLevel and targetCap > anchorEntitlement then
        local anchorProgress = Clamp((anchorLevel - 1) / (maxLevel - 1), 0, 1)
        local currentProgress = Clamp((newHighest - 1) / (maxLevel - 1), 0, 1)
        local anchorWeight = anchorProgress ^ 0.72
        local currentWeight = currentProgress ^ 0.72
        local remainingWeight = math.max(0.000001, 1 - anchorWeight)
        local relativeGrowth = Clamp((currentWeight - anchorWeight) / remainingWeight, 0, 1)
        entitlement = anchorEntitlement
            + math.floor((targetCap - anchorEntitlement) * relativeGrowth + 0.000001)
    end
    if newHighest ~= highest then
        CharDBQuery(string.format(
            "UPDATE spelldraft_dynamic_progression SET highest_level=%d WHERE guid=%d",
            newHighest, guid))
    end
    return entitlement, math.max(0, newHighest - highest)
end

local function SyncDynamicDraftEntitlement(player, candidateLevel, previousLevel)
    local guid = player:GetGUIDLow()
    local stats = CharDBQuery(
        "SELECT successful_drafts, bonus_drafts FROM prestige_stats WHERE player_id = " .. guid)
    if not stats then return nil end
    local successful = stats:GetUInt32(0)
    local bonus = stats:GetUInt32(1)
    local normalEntitlement, newlyReachedLevels = ReconcileDynamicProgression(player, candidateLevel, previousLevel)
    local total = math.max(successful, normalEntitlement + bonus)
    CharDBQuery(string.format(
        "UPDATE prestige_stats SET total_expected_drafts=%d WHERE player_id=%d", total, guid))
    return total, newlyReachedLevels or 0
end

-- Repair only Death Knights that actually passed through our level-1 Draft
-- bootstrap.  Traditional level-55 Classic DKs have no matching bootstrap row
-- and are deliberately left untouched.
--
-- Older builds wrote a minimum expected total of 5 for every DK.  Depending on
-- how many choices the player had already completed, that appeared as 3 or 4
-- extra cards on the first level-up.  Clamp the expectation to the canonical
-- level-1 progression, but never below successful_drafts so already-learned
-- cards are not revoked and no artificial "debt" remains.
local function NormalizeConvertedDkDraftExpectation(player)
    -- Kept as a compatibility call site. Converted DKs now use the exact same
    -- dynamic progression state as every other Random-Draft character. The
    -- general session reconciliation below performs the actual sync.
end
local INCLUDE_RARITY_5 = CONFIG.INCLUDE_RARITY_5
local REROLLS_PER_LEVELUP = CONFIG.REROLLS_PER_LEVELUP
local POOL_AMOUNT = CONFIG.POOL_AMOUNT
local RARITY_DISTRIBUTION = CONFIG.RARITY_DISTRIBUTION

-- Returns true when the player is on their very first draft and free unlimited
-- rerolls are enabled. Gated purely on successful_drafts so the flag survives
-- levelling up before the first pick (draft entry resets the counter to 0, and
-- Death Knights start at 55 rather than 1, so level is not a reliable proxy).
local function IsFirstDrawUnlimited(successful)
    if not CONFIG.UNLIMITED_REROLLS_FIRST_DRAW then return false end
    return successful == 0
end

-- Emits the unlimited-reroll flag to the client so the Reroll button can show
-- "Reroll (∞)" and stay enabled while the condition holds. Callers pass the
-- successful_drafts count they already read from prestige_stats.
local function SendRerollState(player, successful)
    local unlimited = IsFirstDrawUnlimited(successful) and "1" or "0"
    player:SendAddonMessage("SpellChoiceUnlimitedReroll", unlimited, 0, player)
end
local protectedSpellIds = { 
  -- Riding Training
  [54197]=true, [33388]=true, [33391]=true, [34090]=true, [34091]= true,
  -- Custom Worgen (race 16): Two Forms / human-form toggle
  [97710]=true,
  -- Universal armor proficiencies granted by SpellDraft
  [9078]=true, [9077]=true, [8737]=true, [750]=true,
  -- Universal weapon proficiencies granted by SpellDraft
  [196]=true, [197]=true, [198]=true, [199]=true, [201]=true, [202]=true,
  [227]=true, [1180]=true, [200]=true, [15590]=true,
  [264]=true, [5011]=true, [266]=true, [2567]=true, [5009]=true, [107]=true,
  -- Basic ranged attacks paired with those proficiencies
  [75]=true, [5019]=true, [2764]=true,
   -- Alchemy
  [2259]=true, [3101]=true, [3464]=true, [11611]=true, [28596]=true, [51304]=true,
  -- Herbalism
  [2366]=true, [2368]=true, [3570]=true, [11993]=true, [28695]=true, [50300]=true,
  -- Herbalism Extras
  [2383]=true, [32605]=true,
  -- Enchanting
  [7411]=true, [7412]=true, [7413]=true, [13920]=true, [28029]=true, [51313]=true,
  -- Enchanting Extras
  [13262]=true,
  -- Blacksmithing
  [2018]=true, [3100]=true, [3538]=true, [9785]=true, [29844]=true, [51300]=true,
  -- Inscription
  [45357]=true, [45358]=true, [45359]=true, [45360]=true, [45361]=true, [45363]=true,
  --Inscription Extras
  [55005]=true,
  -- Engineering
  [4036]=true, [4037]=true, [4038]=true, [12656]=true, [30350]=true, [49383]=true, [51306]=true,
  -- Skinning
  [8163]=true, [8167]=true, [8168]=true, [10768]=true, [13697]=true, [32678]=true, [50305]=true, [52158]=true,
  -- Tailoring
  [3908]=true, [3909]=true, [3910]=true, [12180]=true, [26790]=true, [51309]=true,
  -- Leatherworking
  [2108]=true, [3104]=true, [3811]=true, [10662]=true, [32549]=true, [51302]=true,
  -- Jewelcrafting
  [25229]=true, [25230]=true, [28894]=true, [28895]=true, [28897]=true, [51311]=true,
  -- Cooking
  [2550]=true, [3102]=true, [3413]=true, [18260]=true, [33359]=true, [51296]=true,
  -- Cooking Extras
  [818]=true,
  -- First Aid
  [3273]=true, [3274]=true, [7924]=true, [10846]=true, [27028]=true, [45544]=true,
  -- Fishing
  [7620]=true, [7732]=true, [7731]=true, [18248]=true, [33095]=true, [51294]=true,
  -- Fishing Extras
  [7738]=true,
}
-- Tracks which players are actively “drafting” a spell (so we don’t block those)
local draftingPlayers = {}
local systemLearningGrace = {}
local systemLearningSerial = {}

-- Some native talents are containers rather than directly learnable spells.
-- 30798 (Shaman Dual Wield) owns SPELL_EFFECT_LEARN_SPELL -> 674; this core
-- deliberately rejects LearnSpell(30798), while the native talent path teaches
-- 674. Keep the authoritative Draft reward as 30798 and project its linked
-- gameplay spell through the same protected system-learning window.
local DRAFT_LINKED_SPELLS = {
    [30798] = { 674 },
}
local DRAFT_LINKED_PARENTS = {}
for parentSpellId, linkedSpells in pairs(DRAFT_LINKED_SPELLS) do
    for _, linkedSpellId in ipairs(linkedSpells) do
        DRAFT_LINKED_PARENTS[linkedSpellId] = DRAFT_LINKED_PARENTS[linkedSpellId] or {}
        table.insert(DRAFT_LINKED_PARENTS[linkedSpellId], parentSpellId)
    end
end

local function IsDraftSpellApplied(player, spellId)
    local linkedSpells = DRAFT_LINKED_SPELLS[tonumber(spellId) or 0]
    if not linkedSpells then return player:HasSpell(spellId) end
    for _, linkedSpellId in ipairs(linkedSpells) do
        if not player:HasSpell(linkedSpellId) then return false end
    end
    return true
end

local function ApplyAuthorizedDraftSpell(player, spellId)
    local linkedSpells = DRAFT_LINKED_SPELLS[tonumber(spellId) or 0]
    if not linkedSpells then
        if not player:HasSpell(spellId) then player:LearnSpell(spellId) end
        return player:HasSpell(spellId)
    end

    for _, linkedSpellId in ipairs(linkedSpells) do
        if not player:HasSpell(linkedSpellId) then
            player:LearnSpell(linkedSpellId)
        end
    end
    return IsDraftSpellApplied(player, spellId)
end

local function HasAuthoritativeLinkedDraftSpell(guid, linkedSpellId)
    local parents = DRAFT_LINKED_PARENTS[tonumber(linkedSpellId) or 0]
    if not parents then return false end
    for _, parentSpellId in ipairs(parents) do
        local drafted = CharDBQuery(string.format(
            "SELECT 1 FROM drafted_spells WHERE player_guid = %d AND spell_id = %d LIMIT 1",
            guid, parentSpellId))
        if drafted then return true end
    end
    return false
end

-- Lets other module scripts (prestige.lua grant loops) bypass the OnLearnSpell
-- anti-cheat while the SYSTEM teaches spells (proficiencies, racials, starter kits).
-- Without this, module-granted spells get blocked and removed 250ms later.
function SpellDraft_SetSystemLearning(guid, active)
    if active then
        local serial = (systemLearningSerial[guid] or 0) + 1
        systemLearningSerial[guid] = serial
        draftingPlayers[guid] = true
        systemLearningGrace[guid] = serial
        return
    end

    draftingPlayers[guid] = nil
    local serial = systemLearningGrace[guid]
    if not serial then return end
    -- LearnCustomTalentSpell/LearnSpell can enqueue linked learned-spell events
    -- that arrive after the native call returns. Keep a short, token-bound
    -- tail window; a newer system-learning operation invalidates this cleanup.
    CreateLuaEvent(function()
        if systemLearningGrace[guid] == serial then
            systemLearningGrace[guid] = nil
        end
    end, 1000, 1)
end
activeTalentDrafts = {}
local talentChains = {}
local SyncDraftedTalents
local BeginDraftLoop
local RebuildCustomTalentRuntime
local talentReconcileSerial = {}
-- B0.9 declarative registry.  One entry now owns the first-rank key, complete
-- rank chain, effect category and validation state used by persistence,
-- refund and final DB display projection.  New same-shape talents are added
-- here once; do not create another SCDI/SCAK/SCDS-style function or prefix.
local CUSTOM_TALENT_CHAINS = {
    [20257] = { ranks = {20257, 20258, 20259, 20260, 20261}, category = "static-native-attribute", status = "live-verified" }, -- Divine Intellect
    [17485] = { ranks = {17485, 17486, 17487, 17488, 17489}, category = "static-native-attribute", status = "live-verified" }, -- Ancestral Knowledge
    [20262] = { ranks = {20262, 20263, 20264, 20265, 20266}, category = "static-native-attribute", status = "live-verified" }, -- Divine Strength
    [46865] = { ranks = {46865, 46866}, category = "static-native-composite", status = "live-verified" }, -- Strength of Arms

    -- B0.9.2A controlled batch: Aura 137, one base-stat percentage per chain.
    -- These entries use the same persistence/application/display/refund path
    -- as the four golden samples above.  Composite-stat, expertise and
    -- prerequisite-bearing candidates remain outside this first batch.
    [34151] = { ranks = {34151, 34152, 34153}, category = "static-native-attribute", effect = "spirit-percent", class = "DRUID", status = "live-verified-rank-loop" }, -- Living Spirit
    [19255] = { ranks = {19255, 19256, 19257, 19258, 19259}, category = "static-native-attribute", effect = "stamina-percent", class = "HUNTER", status = "live-verified-rank-loop" }, -- Survivalist
    [19168] = { ranks = {19168, 19180, 19181, 24296, 24297}, category = "static-native-attribute", effect = "agility-percent", class = "HUNTER", status = "live-verified-rank-loop" }, -- Lightning Reflexes
    [44397] = { ranks = {44397, 44398, 44399}, category = "static-native-attribute", effect = "spirit-percent", class = "MAGE", status = "live-verified-rank-loop" }, -- Student of the Mind
    [11232] = { ranks = {11232, 12500, 12501, 12502, 12503}, category = "static-native-attribute", effect = "intellect-percent", class = "MAGE", status = "live-verified-rank-loop" }, -- Arcane Mind
    [18551] = { ranks = {18551, 18552, 18553, 18554, 18555}, category = "static-native-attribute", effect = "intellect-percent", class = "PRIEST", status = "live-verified-rank-loop" }, -- Mental Strength
    [18697] = { ranks = {18697, 18698, 18699}, category = "static-native-attribute", effect = "stamina-percent", class = "WARLOCK", status = "live-verified-rank-loop" }, -- Demonic Embrace

    -- B0.9.2B first native composite-Aura validation chain.  Toughness combines
    -- stamina, movement-impair duration reduction and an additional native
    -- mechanic; learning the real rank spell preserves all three effects.
    [16252] = { ranks = {16252, 16306, 16307, 16308, 16309}, category = "static-native-composite", effect = "stamina-movement-impair", class = "SHAMAN", status = "live-verified-rank-loop" }, -- Toughness

    -- B0.9.2C controlled native composite batch without prerequisite talents.
    -- These chains exercise multiple base stats and native expertise while
    -- continuing to use the shared save/display/refund protocol above.
    [49006] = { ranks = {49006, 49526, 50029}, category = "static-native-composite", effect = "strength-stamina-expertise", class = "DEATHKNIGHT", status = "live-verified" }, -- Veteran of the Third War
    [34475] = { ranks = {34475, 34476}, category = "static-native-composite", effect = "agility-intellect", class = "HUNTER", status = "live-verified" }, -- Combat Experience
    [29140] = { ranks = {29140, 29143, 29144}, category = "static-native-composite", effect = "strength-stamina-expertise", class = "WARRIOR", status = "live-verified" }, -- Vitality

    -- B0.9.5 controlled effect-passive sample.  Keep this on the exact same
    -- persistence/refund/SCTReg projection path as the three verified chains
    -- above; the native DK Aura remains responsible for Impurity gameplay.
    [49220] = { ranks = {49220, 49633, 49635, 49636, 49638}, category = "mixed-effect-passive", effect = "attack-power-coefficient", class = "DEATHKNIGHT", status = "live-verified-rank-loop" }, -- Impurity

    -- B0.9.6 second controlled effect-passive sample.  Black Ice is a native
    -- five-rank DK Aura that increases Frost and Shadow damage; the registry
    -- changes only persistence/rank projection, never the core damage formula.
    [49140] = { ranks = {49140, 49661, 49662, 49663, 49664}, category = "static-native-damage-aura", effect = "frost-shadow-damage-percent", class = "DEATHKNIGHT", status = "live-verified-rank-loop" }, -- Black Ice

    -- B0.9.7 first ranged-critical-strike sample.  Lethal Shots is a native
    -- five-rank hunter Aura (SPELL_AURA_MOD_CRIT_PERCENT).  SpellDraft owns
    -- only rank persistence/projection/refund; the core remains authoritative
    -- for the character-sheet ranged critical-strike calculation.
    [19426] = { ranks = {19426, 19427, 19429, 19430, 19431}, category = "static-native-combat-aura", effect = "ranged-crit-percent", class = "HUNTER", purpose = "offense", subtype = "weapon-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Lethal Shots

    -- B0.9.8 first avoidance sample. Anticipation is a native five-rank
    -- warrior Protection Aura (SPELL_AURA_MOD_DODGE_PERCENT). SpellDraft only
    -- persists and projects the selected rank; the core owns dodge calculation.
    [12297] = { ranks = {12297, 12750, 12751, 12752, 12753}, category = "static-native-avoidance-aura", effect = "dodge-percent", class = "WARRIOR", purpose = "defense", subtype = "dodge", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Anticipation

    -- B0.9.9 first dual-critical-strike sample. Thundering Strikes is a native
    -- five-rank shaman Enhancement Aura with weapon-critical (52) and
    -- spell-critical (57) effects. SpellDraft owns only rank persistence,
    -- projection and refund; the core remains authoritative for both values.
    [16255] = { ranks = {16255, 16302, 16303, 16304, 16305}, category = "static-native-dual-critical-aura", effect = "weapon-and-spell-crit-percent", class = "SHAMAN", purpose = "offense", subtype = "weapon-and-spell-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Thundering Strikes

    -- B0.9.11A first same-mechanism batch. These chains are exact Aura-shape
    -- matches for the verified Lethal Shots (52) or Thundering Strikes
    -- (52+57) samples. Purpose metadata is display/test guidance only and is
    -- deliberately excluded from persistence and native stat calculation.
    [48987] = { ranks = {48987, 49477, 49478, 49479, 49480}, category = "static-native-dual-critical-aura", effect = "weapon-and-spell-crit-percent", class = "DEATHKNIGHT", purpose = "offense", subtype = "weapon-and-spell-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Dark Conviction
    [20117] = { ranks = {20117, 20118, 20119, 20120, 20121}, category = "static-native-dual-critical-aura", effect = "weapon-and-spell-crit-percent", class = "PALADIN", purpose = "offense", subtype = "weapon-and-spell-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Conviction
    [19370] = { ranks = {19370, 19371, 19373}, category = "static-native-combat-aura", effect = "weapon-crit-percent", class = "HUNTER", purpose = "offense", subtype = "weapon-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Killer Instinct
    [14138] = { ranks = {14138, 14139, 14140, 14141, 14142}, category = "static-native-combat-aura", effect = "weapon-crit-percent", class = "ROGUE", purpose = "offense", subtype = "weapon-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Malice
    [12320] = { ranks = {12320, 12852, 12853, 12855, 12856}, category = "static-native-combat-aura", effect = "weapon-crit-percent", class = "WARRIOR", purpose = "offense", subtype = "weapon-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Cruelty

    -- B0.9.11B defense/dodge batch. Both chains exactly match the verified
    -- warrior Anticipation Aura 49 shape. Purpose fields remain read-only
    -- classification/test metadata and never participate in stat formulas.
    [55129] = { ranks = {55129, 55130, 55131, 55132, 55133}, category = "static-native-avoidance-aura", effect = "dodge-percent", class = "DEATHKNIGHT", purpose = "defense", subtype = "dodge", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Anticipation (Death Knight)
    [20096] = { ranks = {20096, 20097, 20098, 20099, 20100}, category = "static-native-avoidance-aura", effect = "dodge-percent", class = "PALADIN", purpose = "defense", subtype = "dodge", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Anticipation (Paladin)

    -- B0.9.11C first parry batch. These three chains contain only the native
    -- SPELL_AURA_MOD_PARRY_PERCENT effect (Aura 47), so they establish a new
    -- avoidance category without mixing in pet, movement or other composite
    -- effects. SpellDraft owns only rank persistence/projection/refund.
    [20060] = { ranks = {20060, 20061, 20062, 20063, 20064}, category = "static-native-avoidance-aura", effect = "parry-percent", class = "PALADIN", purpose = "defense", subtype = "parry", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Deflection (Paladin)
    [13713] = { ranks = {13713, 13853, 13854}, category = "static-native-avoidance-aura", effect = "parry-percent", class = "ROGUE", purpose = "defense", subtype = "parry", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Deflection (Rogue)
    [16462] = { ranks = {16462, 16463, 16464, 16465, 16466}, category = "static-native-avoidance-aura", effect = "parry-percent", class = "WARRIOR", purpose = "defense", subtype = "parry", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Deflection (Warrior)

    -- B0.9.11D attack-hit batch. Both chains contain only the native
    -- SPELL_AURA_MOD_HIT_CHANCE effect (Aura 54), with a strictly linear
    -- rank ladder. SpellDraft owns rank persistence/projection/refund only;
    -- the core remains authoritative for melee and ranged hit calculation.
    [30816] = { ranks = {30816, 30818, 30819}, category = "static-native-accuracy-aura", effect = "weapon-hit-percent", class = "SHAMAN", purpose = "offense", subtype = "weapon-hit", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Precise Actions
    [29590] = { ranks = {29590, 29591, 29592}, category = "static-native-accuracy-aura", effect = "weapon-hit-percent", class = "WARRIOR", purpose = "offense", subtype = "weapon-hit", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Precision

    -- B0.9.12 dual weapon-hit validation chain. Rogue Precision carries the
    -- native melee-hit (Aura 54) and ranged-hit (Aura 55) effects together.
    -- Registering the full five-rank chain lets the shared spell-backed
    -- protocol own save/reopen/login projection and one-rank refunds while
    -- the core remains authoritative for both character-sheet percentages.
    [13705] = { ranks = {13705, 13832, 13843, 13844, 13845}, category = "static-native-dual-accuracy-aura", effect = "weapon-and-spell-hit-percent", class = "ROGUE", purpose = "offense", subtype = "weapon-and-spell-hit", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Precision (Rogue)

    -- B0.9.13 spell-hit batch. Both chains carry native spell-hit Aura 55
    -- plus a native secondary effect. Preserve the complete rank spell so the
    -- core applies both effects; the registry only owns rank persistence,
    -- projection and one-rank refunds.
    [29438] = { ranks = {29438, 29439, 29440}, category = "static-native-spell-accuracy-composite", effect = "spell-hit-and-mana-cost", class = "MAGE", purpose = "offense", subtype = "spell-hit", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Precision (Mage)
    [30672] = { ranks = {30672, 30673, 30674}, category = "static-native-spell-accuracy-composite", effect = "spell-hit-and-threat-reduction", class = "SHAMAN", purpose = "offense", subtype = "spell-hit", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Elemental Precision

    -- B0.9.14 dual-critical composite pilot.  Both chains use the core's
    -- native weapon/spell critical Auras and retain their secondary effects;
    -- Lua owns only rank persistence, projection and one-rank rollback.
    [32043] = { ranks = {32043, 35396, 35397}, category = "static-native-dual-critical-composite", effect = "weapon-spell-crit-and-ability-damage", class = "PALADIN", purpose = "offense", subtype = "weapon-and-spell-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Sanctity of Battle
    [30242] = { ranks = {30242, 30245, 30246, 30247, 30248}, category = "static-native-dual-critical-composite", effect = "owner-and-pet-weapon-spell-crit", class = "WARLOCK", purpose = "offense", subtype = "weapon-and-spell-critical", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Demonic Tactics

    -- B0.9.15 first summoned-pet conditional talent sample.  Every rank is
    -- already mapped by AzerothCore's spell_pet_auras table for imp (416),
    -- voidwalker (1860), succubus (1863), felhunter (417) and felguard
    -- (17252).  SpellDraft must preserve only the selected rank; the core
    -- remains authoritative for applying, switching and removing the owner
    -- and pet effects when the active demon changes.
    [23785] = { ranks = {23785, 23822, 23823, 23824, 23825}, category = "conditional-native-pet-aura", effect = "active-demon-dependent-owner-and-pet-bonuses", class = "WARLOCK", purpose = "offense-defense", subtype = "summoned-demon-condition", testSurface = "pet-switch-and-combat", status = "conditional-pet-test" }, -- Master Demonologist

    -- B0.9.11F: Precision and Dual Wield Specialization are adjacent Fury
    -- talents but independent chains.  Register 23584 explicitly so both use
    -- the same spell-backed authority instead of mixing a custom spell rank
    -- (29590) with a legacy PlayerTalent rank (23584).  Aura 122 remains the
    -- native source of off-hand damage; this entry only owns persistence,
    -- projection and one-rank refund semantics.
    [23584] = { ranks = {23584, 23585, 23586, 23587, 23588}, category = "conditional-native-offhand-aura", effect = "offhand-damage-percent", class = "WARRIOR", purpose = "offense", subtype = "dual-wield-offhand-damage", testSurface = "combat-offhand", status = "live-verified-rank-loop" }, -- Dual Wield Specialization

    -- B0.9.16 first derived-stat conversion sample. Careful Aim is a native
    -- three-rank passive Aura 212 chain that converts 33/66/100 percent of
    -- Intellect into ranged attack power. SpellDraft owns only rank storage,
    -- projection and refund; the core remains authoritative for the derived
    -- ranged attack-power recalculation and its rounding.
    [34482] = { ranks = {34482, 34483, 34484}, category = "static-native-derived-stat", effect = "intellect-to-ranged-attack-power", class = "HUNTER", purpose = "offense", subtype = "ranged-attack-power-from-intellect", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Careful Aim

    -- B0.9.22.8 second derived-stat conversion sample. Armored to the Teeth is
    -- a native three-rank Fury Aura 285 chain that converts armor into melee
    -- attack power at 1 AP per 108/54/36 armor. SpellDraft owns only rank
    -- storage, projection and refund; the core remains authoritative. User
    -- live verification passed persistence and character-sheet AP changes.
    [61216] = { ranks = {61216, 61221, 61222}, category = "static-native-derived-stat", effect = "armor-to-melee-attack-power", class = "WARRIOR", purpose = "offense-defense", subtype = "melee-attack-power-from-armor", testSurface = "character-sheet", status = "live-verified-rank-loop" }, -- Armored to the Teeth

    -- B0.9.23.1 third derived-stat conversion sample. Mental Dexterity is a
    -- native three-rank Enhancement Aura 268 chain that converts 33/66/100
    -- percent of Intellect into melee attack power. No class, stance or
    -- equipment gate exists in the native aura/stat path, so SpellDraft owns
    -- only rank storage, projection and refund while the core owns the math.
    [51883] = { ranks = {51883, 51884, 51885}, category = "static-native-derived-stat", effect = "intellect-to-melee-attack-power", class = "SHAMAN", purpose = "offense", subtype = "melee-attack-power-from-intellect", testSurface = "character-sheet", status = "derived-stat-test" }, -- Mental Dexterity

    -- B0.9.10 first healing-critical proc sample. Inspiration is a native
    -- three-rank priest Holy proc Aura (42). SpellDraft owns rank persistence,
    -- projection and refund only; spell_proc/core own critical-heal filtering
    -- and the triggered target buff.
    [14892] = { ranks = {14892, 15362, 15363}, category = "native-healing-critical-proc", effect = "critical-heal-target-mitigation", class = "PRIEST", purpose = "healing-support", subtype = "critical-heal-proc", testSurface = "combat-proc", status = "live-verified-rank-loop" }, -- Inspiration
}

local SPELL_BACKED_CUSTOM_TALENTS = {}
for firstRankSpellId in pairs(CUSTOM_TALENT_CHAINS) do
    SPELL_BACKED_CUSTOM_TALENTS[firstRankSpellId] = true
end

local function IsSpellBackedCustomTalent(chainInfo)
    -- Preserve the proven controlled-rollout boundary.  Only explicitly
    -- registered chains use spell-backed persistence and SCTReg projection;
    -- unverified talent_dbc rows stay on the legacy path until classified.
    return chainInfo and SPELL_BACKED_CUSTOM_TALENTS[chainInfo.ranks[1]] == true
end
local blacklistedSpellIds = {
    [20184] = true, -- Judgement of Justice (Trigger)
    [20185] = true, -- Judgement of Light (Trigger)
    [20187] = true, -- Judgement of Righteousness (Trigger)
    [20425] = true, -- Judgement of Command (Trigger)
    [20467] = true, -- Judgement of Command (Trigger)
    [27285] = true, -- Seed of Corruption (Detonation Trigger)
    [47833] = true, -- Seed of Corruption (Detonation Trigger Rank 2)
    [47834] = true, -- Seed of Corruption (Detonation Trigger Rank 3)
    [55166] = true, -- Tidal Force (Trigger)
    [34919] = true, -- Vampiric Touch (Dispel Damage Trigger)
    [42234] = true, -- Volley (Damage Trigger Rank 1)
    [42243] = true, -- Volley (Damage Trigger Rank 2)
    [42244] = true, -- Volley (Damage Trigger Rank 3)
    [42245] = true, -- Volley (Damage Trigger Rank 4)
    [42651] = true, -- Army of the Dead (Ghoul Spawn Trigger)
    [47241] = true, -- Metamorphosis (Active Spell taught by Warlock Talent 59672)
    [12976] = true, -- Last Stand (Active Spell taught by Warrior Talent 12975)
    [33891] = true, -- Tree of Life (Active Shapeshift taught by Druid Talent 65139)
    [47666] = true, -- Penance (Damage Trigger)
    [47750] = true, -- Penance (Heal Trigger)
    [25912] = true, -- Holy Shock (Damage Trigger)
    [25914] = true, -- Holy Shock (Heal Trigger)
    [13797] = true, -- Immolation Trap (Periodic Trigger)
    [42231] = true, -- Hurricane (Damage Trigger)
}

local talentIdToChain = {}
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

local function LoadTalentChains()
    local query = WorldDBQuery([[
        SELECT ID, TierID, SpellRank_1, SpellRank_2, SpellRank_3, SpellRank_4,
               SpellRank_5, SpellRank_6, SpellRank_7, SpellRank_8, SpellRank_9,
               PrereqTalent_1, PrereqRank_1, PrereqTalent_2, PrereqRank_2, PrereqTalent_3, PrereqRank_3
          FROM talent_dbc
    ]])
    if not query then return end
    local count = 0
    repeat
        local talentId = query:GetInt32(0)
        local tierId = query:GetInt32(1)
        local ranks = {}
        for i = 2, 10 do
            local spellId = query:GetInt32(i)
            if spellId > 0 then
                table.insert(ranks, spellId)
            end
        end
        
        if #ranks > 0 then
            count = count + 1
            local prereqs = {}
            for k = 11, 15, 2 do
                local pTalent = query:GetInt32(k)
                local pRank = query:GetInt32(k+1)
                if pTalent > 0 then
                    table.insert(prereqs, { prereqTalentId = pTalent, reqRank = pRank + 1 })
                end
            end
            
            local chain = { talentId = talentId, tierId = tierId, ranks = ranks, prereqs = prereqs }
            talentIdToChain[talentId] = chain
            
            for rankIndex, spellId in ipairs(ranks) do
                talentChains[spellId] = {
                    talentId = talentId,
                    tierId = tierId,
                    rankIndex = rankIndex,
                    ranks = ranks,
                    chain = chain
                }
            end
        end
    until not query:NextRow()

    for firstRankSpellId, registered in pairs(CUSTOM_TALENT_CHAINS) do
        local loaded = talentChains[firstRankSpellId]
        local valid = loaded and #loaded.ranks == #registered.ranks
        if valid then
            for rankIndex, rankSpellId in ipairs(registered.ranks) do
                if loaded.ranks[rankIndex] ~= rankSpellId then valid = false break end
            end
        end
        if not valid then
            print("[SpellChoice][B0.9] Registered talent chain mismatch: " .. tostring(firstRankSpellId))
        end
    end

    print("[SpellChoice] Loaded " .. tostring(count) .. " talent chains from talent_dbc.")
end

-- This project intentionally shifts the native talent-tree gates forward:
-- tier 0 is available from level 1 and every later tier adds five levels.
-- Keep Tome rolls and manual Talent Point purchases on the same rule so a
-- rank-1 capstone (whose dbc_spells.SpellLevel is commonly 0) cannot be
-- mistaken for a level-1 character spell.
local function GetTalentRequiredLevel(chain)
    if not chain or not chain.tierId or chain.tierId <= 0 then
        return 1
    end
    return chain.tierId * 5
end

local function GetEligibleTalentsPool(player, level)
    local guid = player:GetGUIDLow()
    local playerLevel = math.max(1, tonumber(level) or player:GetLevel())
    
    -- 1. Get player's currently known/drafted spells
    local knownSpells = {}
    local knownQ = CharDBQuery("SELECT spell_id FROM drafted_spells WHERE player_guid = " .. guid)
    if knownQ then
        repeat
            knownSpells[knownQ:GetUInt32(0)] = true
        until not knownQ:NextRow()
    end
    local memSpells = player:GetSpells()
    for _, sid in ipairs(memSpells) do
        knownSpells[sid] = true
    end
    
    -- 2. For each talent chain, find the highest rank the player knows
    local knownTalentRanks = {}
    for spellId, info in pairs(talentChains) do
        if knownSpells[spellId] then
            local talentId = info.talentId
            local rankIndex = info.rankIndex
            knownTalentRanks[talentId] = math.max(knownTalentRanks[talentId] or 0, rankIndex)
        end
    end
    
    -- 3. Determine next rank for every talent chain
    local nextRankSpells = {}
    local talentIdToSpellId = {}
    for spellId, info in pairs(talentChains) do
        local talentId = info.talentId
        if not talentIdToSpellId[talentId] then
            local highestRank = knownTalentRanks[talentId] or 0
            local nextRankIndex = highestRank + 1
            if nextRankIndex <= #info.ranks then
                local nextSpellId = info.ranks[nextRankIndex]
                nextRankSpells[nextSpellId] = true
                talentIdToSpellId[talentId] = nextSpellId
            end
        end
    end
    
    -- 4. Filter nextRankSpells by level requirements directly using their tier.
    -- The Tome pool is restricted to the locked actives/playstyle passives; all
    -- other (passive) talents are bought with custom Talent Points instead.
    local pool = {}
    for spellId, _ in pairs(nextRankSpells) do
        local info = talentChains[spellId]
        if info
           and LOCKED_TALENTS[info.ranks[1]]
           and playerLevel >= GetTalentRequiredLevel(info.chain)
        then
            if not blacklistedSpellIds[spellId] and not knownSpells[spellId] then
                table.insert(pool, spellId)
            end
        end
    end
    
    return pool
end

local function RollTalentChoices(player, level, excludeSet)
    local eligiblePool = GetEligibleTalentsPool(player, level)
    local filtered = {}
    for _, spellId in ipairs(eligiblePool) do
        if not excludeSet or not excludeSet[spellId] then
            table.insert(filtered, spellId)
        end
    end
    -- If excluding the previous three exhausts a very small pool, allow them
    -- again rather than consuming currency and returning no cards.
    if #filtered == 0 then filtered = eligiblePool end
    if #filtered == 0 then return {} end

    local raritiesMap = {}
    for offset = 1, #filtered, 500 do
        local chunk = {}
        for i = offset, math.min(offset + 499, #filtered) do
            table.insert(chunk, filtered[i])
        end
        local q = WorldDBQuery("SELECT Id, Rarity FROM dbc_spells WHERE Id IN (" .. table.concat(chunk, ",") .. ")")
        if q then
            repeat
                raritiesMap[q:GetUInt32(0)] = q:GetUInt8(1)
            until not q:NextRow()
        end
    end

    local categorized = { [0]={}, [1]={}, [2]={}, [3]={}, [4]={} }
    for _, id in ipairs(filtered) do
        local rarity = raritiesMap[id] or 0
        if categorized[rarity] then table.insert(categorized[rarity], id) end
    end

    local function RollRarity()
        local r = math.random()
        if r < 0.50 then return 0
        elseif r < 0.77 then return 1
        elseif r < 0.91 then return 2
        elseif r < 0.97 then return 3
        else return 4 end
    end

    local spells = {}
    for _ = 1, math.min(3, #filtered) do
        local targetRarity = RollRarity()
        local chosenRarity = nil
        if #categorized[targetRarity] > 0 then
            chosenRarity = targetRarity
        else
            for rarity = 0, 4 do
                if #categorized[rarity] > 0 then chosenRarity = rarity break end
            end
        end
        if chosenRarity then
            local bucket = categorized[chosenRarity]
            local idx = math.random(#bucket)
            table.insert(spells, bucket[idx])
            table.remove(bucket, idx)
        end
    end
    return spells
end

local function IsChoiceAllowedAtLevel(spellId, playerLevel)
    if not spellId or spellId <= 0 then return false end
    playerLevel = math.max(1, tonumber(playerLevel) or 1)

    local talentInfo = talentChains[spellId]
    if talentInfo then
        return playerLevel >= GetTalentRequiredLevel(talentInfo.chain)
    end

    local q = WorldDBQuery("SELECT SpellLevel FROM dbc_spells WHERE Id = " .. spellId .. " LIMIT 1")
    return q ~= nil and q:GetUInt32(0) <= playerLevel
end

-- Tracks which spells were just blocked from a trainer, so UpgradeKnownSpells will skip exactly those
local justBlockedSpells = {}
local lastSpellChoiceSent = {}

-- Holds the full valid pool per player
local fullSpellPools = {}
-- Holds the current 3 choices shown to player

local currentDraftChoices = {}-- List of exact spell IDs to exclude
-- Utility: shuffle and select N random spells
local function GetRandomSpells(num, guid, excludeSet)
    local bannedSet = {}
    local q = CharDBQuery("SELECT spell_id FROM draft_bans WHERE player_id = " .. guid)
    if q then
        repeat
            bannedSet[q:GetUInt32(0)] = true
        until not q:NextRow()
    end

    local copy = {}
    for _, id in ipairs(fullSpellPools[guid] or {}) do
        if not bannedSet[id] and not (excludeSet and excludeSet[id]) then
            table.insert(copy, id)
        end
    end

    -- Shuffle and return
    for i = #copy, 2, -1 do
        local j = math.random(i)
        copy[i], copy[j] = copy[j], copy[i]
    end

    local result = {}
    local seen = {}
    for i = 1, #copy do
        local id = copy[i]
        if not seen[id] then
            table.insert(result, id)
            seen[id] = true
        end
        if #result >= num then break end
    end


    return result
end
local function LoadSpellsFromDB(guid, allowGenerateMissing)
    local banned = {}
    local banQ = CharDBQuery("SELECT spell_id FROM draft_bans WHERE player_id = " .. guid)
    if banQ then
        repeat
            banned[banQ:GetUInt32(0)] = true
        until not banQ:NextRow()
    end

    local res = CharDBQuery("SELECT offered_spell_1, offered_spell_2, offered_spell_3 FROM prestige_stats WHERE player_id = " .. guid)
    if not res then return nil end

    local spells = {}
    for i = 0, 2 do
        local id = res:GetUInt32(i)
        if id and id > 0 and not banned[id] then
            table.insert(spells, id)
        end
    end

    -- Restoration is read-only by default. Old SC_CHECK/zone/login callers must
    -- not manufacture cards merely because offered_spell columns are empty.
    -- Only an explicit creation/replacement flow may fill missing slots.
    if #spells < 3 and allowGenerateMissing == true then
        local needed = 3 - #spells
        local fill = GetRandomSpells(needed, guid)
        for _, id in ipairs(fill) do
            table.insert(spells, id)
        end

        -- Update DB with cleaned set
        CharDBQuery(string.format("UPDATE prestige_stats SET offered_spell_1 = %d, offered_spell_2 = %d, offered_spell_3 = %d WHERE player_id = %d",
            spells[1] or 0, spells[2] or 0, spells[3] or 0, guid))


    end

    currentDraftChoices[guid] = spells
    return spells
end


local function CheckAndRestorePendingDraft(player)
    local guid = player:GetGUIDLow()
    local res = CharDBQuery("SELECT offered_spell_1, offered_spell_2, offered_spell_3, offered_is_talent, successful_drafts, total_expected_drafts FROM prestige_stats WHERE player_id = " .. guid)
    if not res then return false end

    local s1 = res:GetUInt32(0)
    local isTalentDraft = res:GetUInt32(3) == 1
    local successful = res:GetUInt32(4)
    local expected = res:GetUInt32(5)

    -- A persisted Tome offer is a frozen server-side snapshot. UI dismissal,
    -- SC_CHECK, opening SpellCraft, reload/reconnect and zone changes must all
    -- restore these exact three cards. Revalidating (and especially refunding)
    -- here lets a player repeatedly close/reopen the Tome until a preferred
    -- random set appears. Only the explicit, paid SC_REROLL path may replace a
    -- persisted Tome offer.
    if s1 > 0 then
        local savedChoices = { s1, res:GetUInt32(1), res:GetUInt32(2) }
        if isTalentDraft then
            activeTalentDrafts[guid] = true
            currentDraftChoices[guid] = savedChoices
            player:SendAddonMessage("SpellChoiceStatus", "prestiged", 0, player)
            SendDraftChoices(player, savedChoices)
            return true
        end

        -- Normal level-up offers may still require compatibility cleanup when
        -- an older build persisted a spell above the character's level.
        local allAllowed = true
        for _, savedSpellId in ipairs(savedChoices) do
            if not IsChoiceAllowedAtLevel(savedSpellId, player:GetLevel()) then
                allAllowed = false
                break
            end
        end
        if not allAllowed then
            CharDBQuery("UPDATE prestige_stats SET offered_spell_1 = 0, offered_spell_2 = 0, offered_spell_3 = 0, offered_is_talent = 0 WHERE player_id = " .. guid)
            currentDraftChoices[guid] = nil
            activeTalentDrafts[guid] = nil
            player:SendAddonMessage("SpellChoiceClose", "", 0, player)
            return false
        end
    end

    -- A normal card set is invalid once its entitlement has been consumed.
    -- Never resurrect stale offered_spell columns into a zero-remaining loop.
    if s1 > 0 and not isTalentDraft and successful >= expected then
        CharDBQuery("UPDATE prestige_stats SET offered_spell_1 = 0, offered_spell_2 = 0, offered_spell_3 = 0, offered_is_talent = 0 WHERE player_id = " .. guid)
        currentDraftChoices[guid] = nil
        activeTalentDrafts[guid] = nil
        player:SendAddonMessage("SpellChoiceClose", "", 0, player)
        player:SendAddonMessage("SpellChoiceDrafts", "0", 0, player)
        return false
    end
    if s1 > 0 then
        local spells = {s1, res:GetUInt32(1), res:GetUInt32(2)}
        -- Trust the persisted flag: a NORMAL draft can legitimately roll three
        -- rank-1 talent actives (they are regular pool entries), so inferring
        -- "talent draft" from the spell ids misclassifies those drafts.
        if isTalentDraft then
            activeTalentDrafts[guid] = true
        else
            activeTalentDrafts[guid] = nil
        end
        currentDraftChoices[guid] = spells

        player:SendAddonMessage("SpellChoiceStatus", "prestiged", 0, player)

        SendDraftChoices(player, spells)
        return true
    end
    return false
end


local function SaveSpellsToDB(guid, spells, isTalentDraft)
    local s1 = spells[1] or 0
    local s2 = spells[2] or 0
    local s3 = spells[3] or 0
    -- The offered cards are the authority used to validate a click.  This must
    -- be visible before any login/zone/SC_CHECK callback can try to restore or
    -- create another set in the same tick.
    CharDBQuery(string.format([[
        UPDATE prestige_stats
        SET offered_spell_1 = %d, offered_spell_2 = %d, offered_spell_3 = %d, offered_is_talent = %d
        WHERE player_id = %d
    ]], s1, s2, s3, isTalentDraft and 1 or 0, guid))
end


-- Utility: check if spell ID is blacklisted
local function isBlacklistedSpellId(spellId)
    return blacklistedSpellIds[spellId] == true
end

-- Main loader function with randomization and filtering
local function LoadValidSpellChoices(player, maxLevel)
    local guid = player:GetGUIDLow()
    local pool = {}
    -- Fetch all banned spell *names* to exclude all ranks
    local bannedNames = {}
    local banIds = {}
    local banQ = CharDBQuery("SELECT spell_id FROM draft_bans WHERE player_id = " .. guid)
    if banQ then
        repeat
            table.insert(banIds, banQ:GetUInt32(0))
        until not banQ:NextRow()
    end
    if #banIds > 0 then
        for offset = 1, #banIds, 500 do
            local chunk = {}
            for i = offset, math.min(offset + 499, #banIds) do
                table.insert(chunk, banIds[i])
            end
            local nameQ = WorldDBQuery("SELECT Name_Lang_enUS FROM dbc_spells WHERE Id IN (" .. table.concat(chunk, ",") .. ")")
            if nameQ then
                repeat
                    if not nameQ:IsNull(0) then
                        bannedNames[nameQ:GetString(0)] = true
                    end
                until not nameQ:NextRow()
            end
        end
    end
    fullSpellPools[guid] = pool

    -- Step 1: Load known spells
    local knownSpellIds = {}
    local knownSpellNames = {}
    local rawKnownIds = {}
    local knownQuery = CharDBQuery("SELECT spell FROM character_spell WHERE guid = " .. player:GetGUIDLow())
    if knownQuery then
        repeat
            local sid = knownQuery:GetUInt32(0)
            knownSpellIds[sid] = true
            table.insert(rawKnownIds, sid)
        until not knownQuery:NextRow()
    end
    if #rawKnownIds > 0 then
        for offset = 1, #rawKnownIds, 500 do
            local chunk = {}
            for i = offset, math.min(offset + 499, #rawKnownIds) do
                table.insert(chunk, rawKnownIds[i])
            end
            local nameQ = WorldDBQuery("SELECT Name_Lang_enUS FROM dbc_spells WHERE Id IN (" .. table.concat(chunk, ",") .. ")")
            if nameQ then
                repeat
                    if not nameQ:IsNull(0) then
                        knownSpellNames[nameQ:GetString(0)] = true
                    end
                until not nameQ:NextRow()
            end
        end
    end

    -- Step 1b: Load drafted spells
    local draftedSpellIds = {}
    local rawDraftedIds = {}
    local draftedQuery = CharDBQuery("SELECT spell_id FROM drafted_spells WHERE player_guid = " .. player:GetGUIDLow())
    if draftedQuery then
        repeat
            local sid = draftedQuery:GetUInt32(0)
            draftedSpellIds[sid] = true
            table.insert(rawDraftedIds, sid)
        until not draftedQuery:NextRow()
    end
    if #rawDraftedIds > 0 then
        for offset = 1, #rawDraftedIds, 500 do
            local chunk = {}
            for i = offset, math.min(offset + 499, #rawDraftedIds) do
                table.insert(chunk, rawDraftedIds[i])
            end
            local nameQ = WorldDBQuery("SELECT Name_Lang_enUS FROM dbc_spells WHERE Id IN (" .. table.concat(chunk, ",") .. ")")
            if nameQ then
                repeat
                    if not nameQ:IsNull(0) then
                        knownSpellNames[nameQ:GetString(0)] = true
                    end
                until not nameQ:NextRow()
            end
        end
    end

    -- Never widen a low-level character's pool to level 20. Spell rank 1 does
    -- not mean character level 1; acquisition is gated by the spell's original
    -- SpellLevel, while true talents use their TierID gate above.
    local queryLevel = math.max(1, tonumber(maxLevel) or player:GetLevel())
    -- Preserve SpellDraft's cross-class design, but do not cross the faction
    -- boundary encoded by dbc_skilllineability.RaceMask. 1101 is the combined
    -- mask of the standard Alliance races; 690 is the Horde equivalent.
    -- Using the faction mask (instead of only player:GetRaceMask()) also keeps
    -- faction-appropriate spells available to this project's custom races.
    local factionRaceMask = (player:GetTeam() == 0) and 1101 or 690
    -- Step 2: Query spells from DBC
    local query = WorldDBQuery([[
        SELECT s.Id, s.Effect_1, s.Effect_2, s.Effect_3,
               s.Description_Lang_enUS, s.SpellLevel, s.MaxLevel,
               s.DurationIndex, s.Category, s.Name_Lang_enUS, s.SpellIconID,
               s.Rarity
          FROM dbc_spells s
          JOIN dbc_skilllineability sla ON s.Id = sla.Spell
          JOIN dbc_skillline sl ON sla.SkillLine = sl.ID
            AND sl.CategoryID IN (6, 7, 8, 9, 11)
         WHERE s.SpellLevel <= ]] .. queryLevel .. [[
           AND (s.Attributes & 0x00000040) = 0
           AND (sla.RaceMask = 0 OR (sla.RaceMask & ]] .. factionRaceMask .. [[) <> 0)
           AND s.Id NOT IN (
               SELECT spell_id FROM spell_ranks WHERE spell_id != first_spell_id
           )
    ]])

    if not query then

        return
    end

    -- Step 3: Filter & bucket by rarity
    local categorized = { [0]={}, [1]={}, [2]={}, [3]={}, [4]={}, [5]={} }
    local totalChecked, totalAccepted = 0, 0

    repeat
        totalChecked = totalChecked + 1

        local spellId = query:GetUInt32(0)
        local spellName = query:GetString(9)
        -- character_spell is not a complete snapshot during first-login class
        -- bootstrap. Warriors in particular can already know core spells in
        -- Player memory before/after the delayed classless cleanup. Check the
        -- live spellbook as well so a known spell can never enter a card set.
        if not player:HasSpell(spellId) and not knownSpellIds[spellId] and not draftedSpellIds[spellId] and not knownSpellNames[spellName] then
            local rarity = query:GetUInt8(11)
            if (rarity ~= 5 or INCLUDE_RARITY_5) and (rarity >= 0 and rarity <= 5) then
                local spell = {
                    spellId = spellId,
                    effect1 = query:GetUInt32(1),
                    effect2 = query:GetUInt32(2),
                    effect3 = query:GetUInt32(3),
                    desc    = query:GetString(4),
                    name    = query:GetString(9),
                    iconId  = query:GetUInt32(10)
                }

                if not isBlacklistedSpellId(spellId)
                   and not talentChains[spellId] -- EXCLUDE TALENTS FROM NORMAL ACTIVE DRAFTS
                   and spell.desc ~= ''
                   and spell.name ~= ''
                   and spell.iconId > 1
                   and not bannedNames[spell.name]
                   and (type(SpellDraft_IsResourceChoiceAllowed) ~= "function"
                        or SpellDraft_IsResourceChoiceAllowed(player, spellId))
                then
                    -- Prerequisite check: class-locked spells (e.g. DK rune-cost)
                    local classReq = CONFIG.CLASS_LOCKED_SPELLS[spellId]
                    if classReq and player:GetClass() ~= classReq then
                        -- Player's class doesn't match, skip this spell
                    -- Prerequisite check: requires a previously-drafted spell
                    elseif CONFIG.SPELL_PREREQUISITES[spellId] then
                        local prereq = CONFIG.SPELL_PREREQUISITES[spellId]
                        local satisfied = false
                        if type(prereq) == "table" then
                            for _, reqId in ipairs(prereq) do
                                if knownSpellIds[reqId] then
                                    satisfied = true
                                    break
                                end
                            end
                        else
                            satisfied = knownSpellIds[prereq] == true
                        end
                        if satisfied then
                            table.insert(categorized[rarity], spellId)
                            totalAccepted = totalAccepted + 1
                        end
                    else
                        table.insert(categorized[rarity], spellId)
                        totalAccepted = totalAccepted + 1
                    end
                end
            end
        end
    until not query:NextRow()


    -- Step 3b: Cross-faction Portal/Teleport injection.
    -- Force-guarantees every Portal/Teleport spell is draftable by either
    -- faction, independent of the dbc_skilllineability join or RaceMask data.
    -- Uses each spell's own DB Rarity (portals=3 Epic, teleports=0 Common).
    if CONFIG.CROSS_FACTION_PORTALS and CONFIG.PORTAL_TELEPORT_SPELLS then
        local ptCandidates = {}
        for _, id in ipairs(CONFIG.PORTAL_TELEPORT_SPELLS) do
            if not knownSpellIds[id] and not draftedSpellIds[id] then
                table.insert(ptCandidates, tostring(id))
            end
        end
        if #ptCandidates > 0 then
            -- Skip ids the Step 3 query already pooled, or they carry double draw weight
            local pooled = {}
            for rarity = 0, 5 do
                for _, id in ipairs(categorized[rarity] or {}) do
                    pooled[id] = true
                end
            end
            local ptQ = WorldDBQuery("SELECT Id, SpellLevel, Name_Lang_enUS, Rarity FROM dbc_spells WHERE Id IN (" .. table.concat(ptCandidates, ",") .. ")")
            if ptQ then
                repeat
                    local pid = ptQ:GetUInt32(0)
                    local pLevel = ptQ:GetUInt32(1)
                    local pName = ptQ:IsNull(2) and "" or ptQ:GetString(2)
                    local pRarity = ptQ:GetUInt8(3)
                    if not pooled[pid]
                       and pLevel <= queryLevel
                       and pName ~= ""
                       and not bannedNames[pName]
                       and not knownSpellNames[pName]
                       and pRarity <= 4
                       and categorized[pRarity]
                    then
                        table.insert(categorized[pRarity], pid)
                    end
                until not ptQ:NextRow()
            end
        end
    end

    -- Step 4: Shuffle buckets and pick N from each
    local draftedRarityCount = { [0]=0, [1]=0, [2]=0, [3]=0, [4]=0, [5]=0 }
    for rarity = 0, 4 do
        local bucket = categorized[rarity]
        for i = #bucket, 2, -1 do
            local j = math.random(i)
            bucket[i], bucket[j] = bucket[j], bucket[i]
        end
        local target = math.floor((RARITY_DISTRIBUTION[rarity] or 0) * POOL_AMOUNT)
        local added = 0
        for i = 1, #bucket do
            local id = bucket[i]
            if not knownSpellIds[id] then
                table.insert(pool, id)
                draftedRarityCount[rarity] = (draftedRarityCount[rarity] or 0) + 1
                added = added + 1
                if added >= target then break end
            end
        end
    end

    -- Optionally add Broken (5) spells last if allowed
    if INCLUDE_RARITY_5 then
        local bucket = categorized[5]
        for i = #bucket, 2, -1 do
            local j = math.random(i)
            bucket[i], bucket[j] = bucket[j], bucket[i]
        end
        for _, id in ipairs(bucket) do
            if #pool >= POOL_AMOUNT then break end
            table.insert(pool, id)
            draftedRarityCount[5] = (draftedRarityCount[5] or 0) + 1
        end
    end

end

-- Utility: check if table contains value
local function tableContains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end
-- Prevent players in Draft Mode from learning new spells (via trainer or other means)

-- A native talent rank rebuild can emit EVENT_ON_LEARN_SPELL for another rank
-- in the same chain, while the authority table stores only the final selected
-- rank.  Treat the event as authorized only when this character owns any
-- persisted manual/drafted rank from that exact talent chain.
local function HasAuthoritativeTalentChainRank(guid, spellId)
    local chainInfo = talentChains[tonumber(spellId) or 0]
    if not chainInfo or not chainInfo.ranks or #chainInfo.ranks == 0 then return false end
    local rankList = table.concat(chainInfo.ranks, ",")
    local manual = CharDBQuery(string.format(
        "SELECT 1 FROM manually_acquired_talents WHERE player_guid = %d AND spell_id IN (%s) LIMIT 1",
        guid, rankList))
    if manual then return true end
    local drafted = CharDBQuery(string.format(
        "SELECT 1 FROM drafted_spells WHERE player_guid = %d AND spell_id IN (%s) LIMIT 1",
        guid, rankList))
    return drafted ~= nil
end

-- Drafted active abilities use spell_ranks rather than talent_dbc. Learning
-- one stored/high rank can emit learn events for another rank in the same
-- family after the short in-memory system flag has already been cleared.
local authoritativeSpellFamilyCache = {}
local function GetSpellRankFamilyList(spellId)
    spellId = tonumber(spellId) or 0
    if spellId <= 0 then return nil end
    if authoritativeSpellFamilyCache[spellId] then
        return authoritativeSpellFamilyCache[spellId]
    end
    local rootQuery = WorldDBQuery("SELECT first_spell_id FROM spell_ranks WHERE spell_id = " .. spellId .. " LIMIT 1")
    local firstSpellId = rootQuery and rootQuery:GetUInt32(0) or spellId
    local ids, seen = {}, {}
    local familyQuery = WorldDBQuery("SELECT spell_id FROM spell_ranks WHERE first_spell_id = " .. firstSpellId .. " ORDER BY `rank`")
    if familyQuery then
        repeat
            local rankSpellId = familyQuery:GetUInt32(0)
            if rankSpellId > 0 and not seen[rankSpellId] then
                seen[rankSpellId] = true
                table.insert(ids, rankSpellId)
            end
        until not familyQuery:NextRow()
    end
    if not seen[spellId] then table.insert(ids, spellId) end
    local rankList = table.concat(ids, ",")
    authoritativeSpellFamilyCache[spellId] = rankList
    return rankList
end

local function HasAuthoritativeSpellFamilyRank(guid, spellId)
    if HasAuthoritativeTalentChainRank(guid, spellId) then return true end
    local rankList = GetSpellRankFamilyList(spellId)
    if not rankList or rankList == "" then return false end
    local manual = CharDBQuery(string.format(
        "SELECT 1 FROM manually_acquired_talents WHERE player_guid = %d AND spell_id IN (%s) LIMIT 1",
        guid, rankList))
    if manual then return true end
    local drafted = CharDBQuery(string.format(
        "SELECT 1 FROM drafted_spells WHERE player_guid = %d AND spell_id IN (%s) LIMIT 1",
        guid, rankList))
    return drafted ~= nil
end

-- EVENT_ON_LEARN_SPELL is also emitted by native PlayerTalent rank changes.
-- Those events are not trainer purchases and must never be removed by the
-- generic Draft-Mode spell anti-cheat.  Re-project the complete talent state
-- from our authoritative tables instead: valid ranks survive, while an
-- illegally injected talent rank has no authority row and is removed by the
-- rebuild.  Serial debouncing folds a burst of rank events into one rebuild.
local function ScheduleAuthoritativeTalentReconcile(guid)
    local serial = (talentReconcileSerial[guid] or 0) + 1
    talentReconcileSerial[guid] = serial
    CreateLuaEvent(function()
        if talentReconcileSerial[guid] ~= serial then return end
        talentReconcileSerial[guid] = nil
        local current = GetPlayerByGUID(guid)
        if not current or not current:IsInWorld() then return end
        if type(RebuildCustomTalentRuntime) ~= "function" then return end
        SpellDraft_SetSystemLearning(guid, true)
        RebuildCustomTalentRuntime(current)
        SpellDraft_SetSystemLearning(guid, false)
    end, 350, 1)
end

local function OnLearnSpell(event, player, spellId)
    if IsBotPlayer(player) then return end
    if not IsRandomDraftMode(player) then return end
    local guid = player:GetGUIDLow()

    -- Allow GMs to learn spells for testing
    if player:IsGM() then
        return
    end

    -- If this LearnSpell was triggered by our draft system, allow it immediately:
    if draftingPlayers[guid] or systemLearningGrace[guid] then
        return
    end

    -- A linked gameplay spell (674) is authorized by its persisted Draft parent
    -- (30798). This also protects character_spell load events on relog, after the
    -- short in-memory system-learning window no longer exists.
    if HasAuthoritativeLinkedDraftSpell(guid, spellId) then
        return
    end

    -- A spell present in talent_dbc is a native talent-rank transition, not a
    -- newly learned trainer spell.  Let the DB-authoritative projector decide
    -- its final rank instead of printing a false warning and deleting it.
    if talentChains[tonumber(spellId) or 0] then
        ScheduleAuthoritativeTalentReconcile(guid)
        return
    end

    -- Allow already drafted spells (prevents anti-cheat from deleting them on login/load)
    local dq = CharDBQuery("SELECT 1 FROM drafted_spells WHERE player_guid = " .. guid .. " AND spell_id = " .. spellId)
    if dq then
        return
    end

    -- Custom Talent Point purchases are just as authoritative as card picks.
    -- Without this check the login spell-load event schedules their removal
    -- before the delayed Draft runtime has a chance to restore them.
    local manualTalent = CharDBQuery("SELECT 1 FROM manually_acquired_talents WHERE player_guid = " .. guid .. " AND spell_id = " .. spellId .. " LIMIT 1")
    if manualTalent then
        return
    end

    -- Refund/relogin rebuilding may learn a lower/native companion rank from
    -- an already-authorized chain.  Exact-ID checks above cannot recognize it.
    if HasAuthoritativeSpellFamilyRank(guid, spellId) then
        return
    end

    -- Heritage choices are authorized dynamically per character. This keeps
    -- the catalog behind its server-side category limits instead of globally
    -- whitelisting every racial spell for every learning source.
    if type(Heritage_IsRecordedSpell) == "function" and Heritage_IsRecordedSpell(guid, spellId) then
        return
    end

    -- Allow companion pet and mount spells taught by items through the anti-cheat
    local itemCheck = WorldDBQuery("SELECT 1 FROM item_template WHERE class = 15 AND (spellid_1 = " .. spellId .. " OR spellid_2 = " .. spellId .. " OR spellid_3 = " .. spellId .. " OR spellid_4 = " .. spellId .. ") LIMIT 1")
    if itemCheck then
        -- Also teach Riding skill automatically if they are learning a mount
        if spellId == 43688 or spellId == 42776 then
            -- Ground mounts: teach Apprentice Riding
            if not player:HasSpell(33388) then
                player:LearnSpell(33388)
            end
        elseif spellId == 37015 or spellId == 40192 or spellId == 63796 or spellId == 64927 or spellId == 72286 then
            -- Flying mounts: teach all Riding progression up to Artisan Riding
            local riding = { 33388, 33391, 34090, 34091 }
            for _, rs in ipairs(riding) do
                if not player:HasSpell(rs) then
                    player:LearnSpell(rs)
                end
            end
        end
        return
    end

    --  Check if the player is in Draft Mode
    local res = CharDBQuery("SELECT draft_state FROM prestige_stats WHERE player_id = " .. guid)
    if res and res:GetUInt32(0) == 1 then
        -- Allow protected spells through
        if protectedSpellIds[spellId] then
            return
        end
        -- Allow any spell whose rarity is 99 (our “requires‑reagent” marker)
        do
            local rq = WorldDBQuery("SELECT rarity FROM dbc_spells WHERE Id = " .. spellId)
            if rq and rq:GetUInt32(0) == 99 then
                return
            end
        end
        -- Block all other spells
        print(string.format("[SpellChoice][AntiCheat] blocked unauthorized learn: guid=%d spell=%d", guid, spellId))
        player:SendBroadcastMessage(string.format(
            "You cannot learn new spells while in Draft Mode. [SpellID: %d]", spellId))

        --  Delay the removal slightly
        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if not p then return end

            -- The spell may have been accepted by the draft flow after this
            -- learn event was observed. Never remove a spell that is now
            -- recorded as an official draft pick.
            local drafted = CharDBQuery("SELECT 1 FROM drafted_spells WHERE player_guid = " .. guid .. " AND spell_id = " .. spellId)
            if drafted then
                if justBlockedSpells[guid] then
                    justBlockedSpells[guid][spellId] = nil
                end
                return
            end


            -- The learned event can precede or differ from the final rank row
            -- during a native talent rebuild. Recheck the whole authoritative
            -- chain before executing the delayed anti-cheat removal.
            local manualTalent = CharDBQuery("SELECT 1 FROM manually_acquired_talents WHERE player_guid = " .. guid .. " AND spell_id = " .. spellId .. " LIMIT 1")
            if manualTalent or HasAuthoritativeSpellFamilyRank(guid, spellId)
                or HasAuthoritativeLinkedDraftSpell(guid, spellId) then
                if justBlockedSpells[guid] then
                    justBlockedSpells[guid][spellId] = nil
                end
                return
            end

            p:RemoveSpell(spellId)
        end, 250, 1)

        -- Track it in justBlockedSpells
        justBlockedSpells[guid] = justBlockedSpells[guid] or {}
        justBlockedSpells[guid][spellId] = true
    end
end


local function UpgradeKnownSpells(player)
    local level = player:GetLevel()
    local upgraded = 0

    local visitedRoot = {}
    local knownSpells = player:GetSpells()  -- Returns an array of { spellId, … }

    for _, spellId in ipairs(knownSpells) do
        local rootQ = WorldDBQuery(
            "SELECT first_spell_id FROM spell_ranks WHERE spell_id = " .. spellId .. " LIMIT 1"
        )
        local firstSpellId = (rootQ and rootQ:GetUInt32(0)) or spellId

        if not visitedRoot[firstSpellId] then
            visitedRoot[firstSpellId] = true

            -- Learn only the single highest eligible rank. Teaching every
            -- missing intermediate rank emits several learned-spell packets;
            -- this client can then place the same-looking ability multiple
            -- times on the action bar.
            local rankQuery = WorldDBQuery([[
                SELECT sr.spell_id, ds.SpellLevel
                  FROM spell_ranks sr
                  JOIN dbc_spells ds ON sr.spell_id = ds.Id
                 WHERE sr.first_spell_id = ]] .. firstSpellId .. [[
                   AND ds.SpellLevel <= ]] .. level .. [[
                 ORDER BY ds.SpellLevel DESC, sr.`rank` DESC
                 LIMIT 1
            ]])

            if rankQuery then
                local candidateId = rankQuery:GetUInt32(0)
                if not player:HasSpell(candidateId) then
                    local guid = player:GetGUIDLow()
                    if not (justBlockedSpells[guid] and justBlockedSpells[guid][candidateId]) then
                        CharDBExecute(
                            "INSERT IGNORE INTO drafted_spells (player_guid, spell_id) VALUES (" .. guid .. ", " .. candidateId .. ")"
                        )

                        SpellDraft_SetSystemLearning(guid, true)
                        player:LearnSpell(candidateId)
                        SpellDraft_SetSystemLearning(guid, false)
                        upgraded = upgraded + 1
                    else
                        justBlockedSpells[guid][candidateId] = nil
                    end
                end
            end
        end
    end
end

-- Tell the client the exact final rank and every ID in its rank chain.
-- Localized names are not unique (475/2782 are both named Remove Curse), so
-- action-bar placement must never infer identity from the displayed name.
local function SendActionBarSync(player, selectedSpellId)
    if not player or not player:IsInWorld() or not selectedSpellId then return end
    local rootQ = WorldDBQuery("SELECT first_spell_id FROM spell_ranks WHERE spell_id=" .. selectedSpellId .. " LIMIT 1")
    local rootId = rootQ and rootQ:GetUInt32(0) or selectedSpellId
    local chain = {}
    local finalId = player:HasSpell(selectedSpellId) and selectedSpellId or nil
    -- MySQL 8 treats RANK as a window-function keyword. Leaving this column
    -- unquoted raises SQL 1064; this core turns SQL parser errors into a fatal
    -- assertion, so a harmless login repair used to terminate worldserver.
    local ranksQ = WorldDBQuery("SELECT spell_id FROM spell_ranks WHERE first_spell_id=" .. rootId .. " ORDER BY `rank` ASC")
    if ranksQ then
        repeat
            local rankId = ranksQ:GetUInt32(0)
            table.insert(chain, rankId)
            if player:HasSpell(rankId) then finalId = rankId end
        until not ranksQ:NextRow()
    else
        table.insert(chain, selectedSpellId)
    end
    if finalId then
        player:SendAddonMessage("SCBar", tostring(finalId) .. ":" .. table.concat(chain, ","), 0, player)
    end
end

-- Rank synchronization can issue many DB queries on characters with a large
-- spellbook. Never keep the card-selection request open while doing that work;
-- otherwise the client times out even though LearnSpell already succeeded.
local function QueueUpgradeKnownSpells(player, selectedSpellId)
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p and p:IsInWorld() then
            UpgradeKnownSpells(p)
            SendActionBarSync(p, selectedSpellId)
        end
    end, 100, 1)
end

local function QueueDraftedActionBarRepair(player)
    local guid = player:GetGUIDLow()
    local draftedQ = CharDBQuery("SELECT spell_id FROM drafted_spells WHERE player_guid=" .. guid .. " ORDER BY spell_id")
    if not draftedQ then return end
    local roots, seenRoots = {}, {}
    repeat
        local spellId = draftedQ:GetUInt32(0)
        local rootQ = WorldDBQuery("SELECT first_spell_id FROM spell_ranks WHERE spell_id=" .. spellId .. " LIMIT 1")
        local rootId = rootQ and rootQ:GetUInt32(0) or spellId
        if not seenRoots[rootId] then
            seenRoots[rootId] = true
            table.insert(roots, rootId)
        end
    until not draftedQ:NextRow()

    for index, rootId in ipairs(roots) do
        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if p and p:IsInWorld() then SendActionBarSync(p, rootId) end
        end, 700 + index * 80, 1)
    end
end





-- Event: Player level-up
local function OnLevelUp(event, player, oldLevel)
    if IsBotPlayer(player) then return end
    if not IsRandomDraftMode(player) then return end
    if type(SpellDraft_IsDraftRuntimeReady) == "function"
        and not SpellDraft_IsDraftRuntimeReady(player) then return end
    -- 1) compute actual level gain
    local newLevel = player:GetLevel()
    local diff     = newLevel - oldLevel
    if diff <= 0 then
        return
    end

    local guid = player:GetGUIDLow()

    -- 2) block if player hasn't unlocked spell draft
    local stateQ = CharDBQuery(
        "SELECT draft_state FROM prestige_stats WHERE player_id = " .. guid
    )
    if not stateQ or stateQ:GetUInt32(0) < 1 then
        return
    end

    -- Reconcile before granting any per-level currency. The returned delta is
    -- the count of levels that exceed this run's durable historical high.
    local expectedTotal, newlyReachedLevels = SyncDynamicDraftEntitlement(player, newLevel, oldLevel)
    if not expectedTotal then return end

    -- 3) Determine per-level reroll rate based on prestige level
    --    Prestige 0: 0 rerolls per level
    --    Prestige 1: PRESTIGE1_REROLLS_PER_LEVEL (1) per level
    --    Prestige 2+: +PRESTIGE_REROLL_SCALING (2) per prestige beyond 1
    local prestigeQ = CharDBQuery(
        "SELECT prestige_level, bonus_drafts FROM prestige_stats WHERE player_id = " .. guid
    )
    local prestigeLevel = 0
    local bonusDrafts = 0
    if prestigeQ then
        prestigeLevel = prestigeQ:GetUInt32(0)
        bonusDrafts = prestigeQ:GetUInt32(1)
    end

    local rerollsPerLevel
    if prestigeLevel <= 0 then
        rerollsPerLevel = CONFIG.REROLLS_PER_LEVELUP -- 0
    else
        rerollsPerLevel = CONFIG.PRESTIGE1_REROLLS_PER_LEVEL + CONFIG.PRESTIGE_REROLL_SCALING * (prestigeLevel - 1)
    end

    local rerollsToAdd = newlyReachedLevels * rerollsPerLevel
    CharDBExecute(string.format([[
        INSERT INTO prestige_stats
          (player_id, draft_state, rerolls)
        VALUES
          (%d, 1, %d)
        ON DUPLICATE KEY UPDATE
          rerolls               = rerolls + %d;
    ]], guid,
       rerollsToAdd,
       rerollsToAdd
    ))

    -- Normal spell ranks are progression, not new build choices. Every drafted
    -- spell automatically learns ranks allowed by the newly reached level.
    UpgradeKnownSpells(player)

    -- 4) Derive the entitlement from the character's actual level instead of
    -- adding to the previous value.  GM level-down/level-up sequences (notably
    -- `.level 1`) must not award the same levels again or create three phantom
    -- draft rounds.  Bonus drafts remain additive and completed picks are never
    -- revoked.
    -- 5) delay UI update by 250ms so DB writes can settle
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsInWorld() then return end

        -- send updated rerolls
        local rerollQ = CharDBQuery(
          "SELECT rerolls FROM prestige_stats WHERE player_id = " .. guid
        )
        if rerollQ then
            p:SendAddonMessage(
              "SpellChoiceRerolls",
              tostring(rerollQ:GetUInt32(0)),
              0, p
            )
        end

        -- send updated drafts remaining
        local draftQ = CharDBQuery(string.format([[
          SELECT successful_drafts, total_expected_drafts
          FROM prestige_stats
          WHERE player_id = %d
        ]], guid))
        if draftQ then
            local successful = draftQ:GetUInt32(0)
            local expected   = draftQ:GetUInt32(1)
            local remaining  = math.max(0, expected - successful)
            p:SendAddonMessage(
              "SpellChoiceDrafts",
              tostring(remaining),
              0, p
            )
            SendRerollState(p, successful)
        end
    end, 250, 1)

    -- 6) Generate or resend spell choices only when a real entitlement exists.
    -- Previously the level event displayed three phantom cards even when the
    -- front-loaded curve had not awarded a new pick; clicking one then reached
    -- REJECT_ENTITLEMENT and looked like an intermittent LearnSpell failure.
    local entitlementQ = CharDBQuery(string.format(
        "SELECT successful_drafts, total_expected_drafts FROM prestige_stats WHERE player_id=%d",
        guid))
    if not entitlementQ or entitlementQ:GetUInt32(0) >= entitlementQ:GetUInt32(1) then
        CharDBQuery(string.format([[UPDATE prestige_stats
            SET offered_spell_1=0, offered_spell_2=0, offered_spell_3=0, offered_is_talent=0
            WHERE player_id=%d]], guid))
        currentDraftChoices[guid] = nil
        activeTalentDrafts[guid] = nil
        player:SendAddonMessage("SpellChoiceClose", "", 0, player)
        return
    end

    -- The restore path also re-establishes
    -- whether a pending draft is a Tome of Talents draft (offered_is_talent).
    if not CheckAndRestorePendingDraft(player) then
        -- generate new draft
        LoadValidSpellChoices(player, newLevel)

        local spells = GetRandomSpells(3, guid)
        currentDraftChoices[guid] = spells
        SaveSpellsToDB(guid, spells)

        SendDraftChoices(player, spells)
    end
end


local function HandleBuyShopItem(player, itemId)
    if not player then return end
    local guid = player:GetGUIDLow()
    
    local costs = {
        -- Drafts
        [4427] = 1,  -- Scroll of Reroll
        [1078] = 1,  -- Scroll of Ban
        [13149] = 2, -- Lost Grimoire
        [25462] = 2, -- Tome of Talents
        
        -- Heirlooms
        [42943] = 3, -- Bloodied Arcanite Reaper
        [42945] = 3, -- Venerable Dal'Rend's Sacred Charge
        [42946] = 3, -- Charmed Ancient Bone Bow
        [42944] = 3, -- Balanced Heartseeker
        [42947] = 3, -- Dignified Headmaster's Charge
        [44100] = 3, -- Pristine Lightforge Spaulders
        [48685] = 3, -- Polished Breastplate of Valor
        [42952] = 3, -- Stained Shadowcraft Spaulders
        [48689] = 3, -- Stained Shadowcraft Tunic
        [48691] = 3, -- Tattered Dreadmist Robe
        [42951] = 3, -- Mystical Pauldrons of Elements
        [48683] = 3, -- Mystical Vest of Elements
        [42991] = 3, -- Swift Hand of Justice
        [42992] = 3, -- Discerning Eye of the Beast
        
        -- Mounts
        [33809] = 5,  -- Amani War Bear
        [49283] = 5,  -- Reins of the Spectral Tiger
        [32458] = 5,  -- Ashes of Al'ar
        [45693] = 5,  -- Mimiron's Head
        [50818] = 5,  -- Invincible's Reins
        [30609] = 5,  -- Swift Nether Drake
        [46708] = 5,  -- Deadly Gladiator's Frost Wyrm
        
        -- Pets
        [13584] = 3, -- Diablo Stone
        [13582] = 3, -- Zergling Leash
        [13583] = 3, -- Panda Collar
        [30360] = 3, -- Lurky's Egg
        
        -- Cosmetics
        [1973] = 4,  -- Orb of Deception
        [35275] = 4, -- Orb of the Sin'dorei
        [37254] = 5, -- Super Simian Sphere
        [43499] = 4, -- Iron Boot Flask
        [33079] = 4, -- Murloc Costume
        [46780] = 3, -- Ogre Pinata
        [34480] = 3  -- Romantic Picnic Basket
    }
    
    local cost = costs[itemId]
    if not cost then
        player:SendBroadcastMessage("Invalid shop item.")
        return
    end
    
    local q = CharDBQuery("SELECT prestige_tokens FROM prestige_stats WHERE player_id = " .. guid)
    if not q then
        player:SendBroadcastMessage("You must have prestige status to use the shop.")
        return
    end
    
    local tokens = q:GetUInt32(0)
    if tokens < cost then
        player:SendBroadcastMessage("You do not have enough Prestige Tokens.")
        return
    end
    
    local item = player:AddItem(itemId, 1)
    if not item then
        player:SendBroadcastMessage("Failed to purchase: inventory full.")
        return
    end
    
    local newTokens = tokens - cost
    CharDBQuery("UPDATE prestige_stats SET prestige_tokens = " .. newTokens .. " WHERE player_id = " .. guid)
    
    player:SendBroadcastMessage("Purchased " .. item:GetName() .. " for " .. cost .. " Prestige Tokens.")
    SyncDraftStats(player)
end


-- Short, token-aware result channel. WoW 3.3.5 addon prefixes are safest at
-- 16 characters or fewer; the previous SpellChoiceAccepted/Failed names could
-- be dropped by some clients, leaving the card UI waiting forever.
local function SendChoiceResult(player, ok, spellId, requestToken)
    local token = requestToken or ""
    player:SendAddonMessage("SCResult", (ok and "OK:" or "FAIL:") .. tostring(spellId or 0) .. ":" .. token, 0, player)
end

local function TraceChoice(player, spellId, requestToken, stage, detail)
    local guid = player and player:GetGUIDLow() or 0
    local level = player and player:GetLevel() or 0
    local line = string.format("[SpellDraftChoice] guid=%d level=%d spell=%d token=%s stage=%s detail=%s",
        guid, level, tonumber(spellId) or 0, tostring(requestToken or ""), tostring(stage or ""), tostring(detail or ""))
    print(line)
end

local function FindKnownSpellInChain(player, spellId)
    local linkedSpells = DRAFT_LINKED_SPELLS[tonumber(spellId) or 0]
    if linkedSpells then
        for _, linkedSpellId in ipairs(linkedSpells) do
            if not player:HasSpell(linkedSpellId) then return nil end
        end
        return linkedSpells[1]
    end
    if player:HasSpell(spellId) then return spellId end
    local rootQ = WorldDBQuery("SELECT first_spell_id FROM spell_ranks WHERE spell_id = " .. spellId .. " LIMIT 1")
    local rootId = rootQ and rootQ:GetUInt32(0) or spellId
    local ranksQ = WorldDBQuery("SELECT spell_id FROM spell_ranks WHERE first_spell_id = " .. rootId)
    if ranksQ then
        repeat
            local rankId = ranksQ:GetUInt32(0)
            if player:HasSpell(rankId) then return rankId end
        until not ranksQ:NextRow()
    end
    return nil
end

local function QueueChoicePersistenceCheck(player, spellId, requestToken)
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsInWorld() then return end

        local foundSpell = FindKnownSpellInChain(p, spellId)

        if foundSpell then
            TraceChoice(p, spellId, requestToken, "VERIFY_PERSISTED", "known rank=" .. foundSpell)
        else
            -- The choice is already durably authorized. Retry once after the
            -- core/client rank transition has settled; this repairs the small
            -- set of cross-class spells that do not stick on the first call.
            TraceChoice(p, spellId, requestToken, "VERIFY_RETRY", "authorized reward missing after 750ms; retrying projection")
            SpellDraft_SetSystemLearning(guid, true)
            ApplyAuthorizedDraftSpell(p, spellId)
            SpellDraft_SetSystemLearning(guid, false)
            CreateLuaEvent(function()
                local retryPlayer = GetPlayerByGUID(guid)
                if not retryPlayer or not retryPlayer:IsInWorld() then return end
                local retryFound = FindKnownSpellInChain(retryPlayer, spellId)
                if retryFound then
                    TraceChoice(retryPlayer, spellId, requestToken, "VERIFY_REPAIRED", "known rank=" .. retryFound)
                else
                    TraceChoice(retryPlayer, spellId, requestToken, "VERIFY_MISSING", "no rank known after repair retry")
                    retryPlayer:SendBroadcastMessage("[Draft diagnostic] Reward " .. spellId .. " is authorized but its gameplay spell is still missing. Please report this ID.")
                end
            end, 500, 1)
        end
    end, 750, 1)
end

-- Shared server-authoritative reward projection used by the physical GM test
-- card today and by the future free-choice point shop. Random Draft keeps its
-- own entitlement accounting, while every source shares linked-spell handling,
-- durable drafted_spells authority and login self-heal.
local function GrantAuthorizedCardReward(player, spellId, source)
    if not player or not player:IsInWorld() then return false, "offline" end
    spellId = tonumber(spellId) or 0
    if spellId <= 0 then return false, "invalid_spell" end
    local guid = player:GetGUIDLow()

    if CharDBQuery(string.format(
        "SELECT 1 FROM drafted_spells WHERE player_guid = %d AND spell_id = %d LIMIT 1",
        guid, spellId)) then
        return false, "already_drafted"
    end
    if IsDraftSpellApplied(player, spellId) then
        return false, "already_known"
    end

    -- Persist authority before learning so EVENT_ON_LEARN_SPELL and any linked
    -- child event can verify the reward even if they arrive after the Lua call.
    CharDBQuery(string.format(
        "INSERT IGNORE INTO drafted_spells (player_guid, spell_id) VALUES (%d, %d)",
        guid, spellId))

    SpellDraft_SetSystemLearning(guid, true)
    local applied = ApplyAuthorizedDraftSpell(player, spellId)
    if applied and type(SpellDraft_OnResourceSpellLearned) == "function" then
        SpellDraft_OnResourceSpellLearned(player, spellId)
    end
    SpellDraft_SetSystemLearning(guid, false)

    if not applied then
        CharDBQuery(string.format(
            "DELETE FROM drafted_spells WHERE player_guid = %d AND spell_id = %d",
            guid, spellId))
        return false, "core_rejected"
    end

    SyncDraftedTalents(player, spellId)
    QueueChoicePersistenceCheck(player, spellId, tostring(source or "card"))
    QueueUpgradeKnownSpells(player, spellId)
    return true, "ok"
end

-- Event: Player sends whisper to addon
local function OnAddonWhisper(event, player, msg, msgType, lang, receiver)
    if IsBotPlayer(player) then return end
    msg = msg:gsub("%s+$", "")

    -- Only process protocol whispers starting with "SC"
    if msg:sub(1, 2) ~= "SC" then return end
    if not IsRandomDraftMode(player) then
        player:SendAddonMessage("SpellChoiceStatus", "not_prestiged", 0, player)
        player:SendAddonMessage("SpellChoiceClose", "", 0, player)
        return false
    end

    local guid = player:GetGUIDLow()

    -- Signed matching keeps requests from already-running overflowed clients
    -- compatible; updated clients generate bounded positive tokens.
    local commitToken, commitPayload = msg:match("^SC_COMMIT_TALENTS:(%-?%d+):(.+)$")
    if commitToken then
        SpellDraftTalentCommitGuard = SpellDraftTalentCommitGuard or {}
        local requestKey = tostring(guid) .. ":" .. commitToken
        if SpellDraftTalentCommitGuard[requestKey] then return false end
        local now = os.time()
        SpellDraftTalentCommitGuard[requestKey] = now
        for key, seenAt in pairs(SpellDraftTalentCommitGuard) do
            if now - seenAt > 30 then SpellDraftTalentCommitGuard[key] = nil end
        end
        HandleCommitTalents(player, commitPayload, commitToken)
        return false
    end

    local refundToken, refundFirstRank = msg:match("^SC_REFUND_TALENT:(%-?%d+):(%d+)$")
    if refundToken then
        SpellDraftTalentRefundGuard = SpellDraftTalentRefundGuard or {}
        local requestKey = tostring(guid) .. ":" .. refundToken
        if SpellDraftTalentRefundGuard[requestKey] then return false end
        local now = os.time()
        SpellDraftTalentRefundGuard[requestKey] = now
        for key, seenAt in pairs(SpellDraftTalentRefundGuard) do
            if now - seenAt > 30 then SpellDraftTalentRefundGuard[key] = nil end
        end
        HandleRefundTalentRank(player, tonumber(refundFirstRank), refundToken)
        return false
    end

    -- A card selection is a transactional command, not UI chatter. It must
    -- never be silently discarded because login/status synchronization used
    -- the shared SC_* quota in the same second.
    local isChoiceCommand = msg:match("^SC:%d+:?%d*$") ~= nil

    -- Rate limit: allow at most 5 SC_* messages per second per player (guid)
    if not isChoiceCommand then
        local now = os.time()
        local limit = lastMsgTimes[guid]
        if not limit or limit.windowStart ~= now then
            lastMsgTimes[guid] = { count = 1, windowStart = now }
        else
            if limit.count >= 5 then
                return false
            end
            limit.count = limit.count + 1
        end
    end

    local buySpellId = tonumber(msg:match("^SC_BUY_TALENT:(%d+)"))
    if buySpellId then
        HandleBuyTalent(player, buySpellId)
        return false
    end

    local buyShopItemId = tonumber(msg:match("^SC_BUY_SHOP:(%d+)"))
    if buyShopItemId then
        HandleBuyShopItem(player, buyShopItemId)
        return false
    end

    -- Handle SC_CHECK (client re-checks prestige)    
    if msg == "SC_CHECK" then
        -- Opening/reopening SpellCraft is also a repair point.  Re-apply the
        -- server-authoritative manual ranks before publishing them so an old
        -- character whose native character_talent rows are missing heals
        -- without spending points again.
        if type(SpellDraft_RestoreManualTalents) == "function" then
            SpellDraft_RestoreManualTalents(player, false)
        end
        SyncDraftedTalents(player)
        local restoredPending = CheckAndRestorePendingDraft(player)
        local result = CharDBQuery("SELECT draft_state, rerolls FROM prestige_stats WHERE player_id = " .. guid)
        if not result then
            local startDrafts = GetExpectedDraftsFormula(player:GetClass(), player:GetLevel())
            CharDBQuery(string.format([[
                INSERT IGNORE INTO prestige_stats 
                (player_id, prestige_level, draft_state, stored_class, total_expected_drafts, rerolls, bans) 
                VALUES (%d, 0, 1, %d, %d, %d, %d)
            ]], guid, player:GetClass(), startDrafts, CONFIG.DRAFT_MODE_REROLLS, CONFIG.DRAFT_BANS_START))
            result = CharDBQuery("SELECT draft_state, rerolls FROM prestige_stats WHERE player_id = " .. guid)
        end
        
        SyncDraftStats(player)
        
        if result then
            local draftState = result:GetUInt32(0)
            local rerolls = result:GetUInt32(1)

            local status = draftState == 1 and "prestiged" or "not_prestiged"

            local drafts = CharDBQuery("SELECT total_expected_drafts FROM prestige_stats WHERE player_id = " .. player:GetGUIDLow())
            
            local playerGuid = player:GetGUIDLow()
            local query = CharDBQuery("SELECT total_expected_drafts, successful_drafts FROM prestige_stats WHERE player_id = " .. playerGuid)
            local bansQ = CharDBQuery("SELECT bans FROM prestige_stats WHERE player_id = " .. guid)
            if bansQ then
              local bansRemaining = bansQ:GetUInt32(0)
              player:SendAddonMessage("SpellChoiceBansLeft", tostring(bansRemaining), 0, player)
            end
            local successful = 0
            if query then
                local totalExpected = query:GetUInt32(0)
                successful = query:GetUInt32(1)
                local totalDrafts = totalExpected - successful
                if totalDrafts < 0 then totalDrafts = 0 end -- safety clamp
                player:SendAddonMessage("SpellChoiceDrafts", tostring(totalDrafts), 0, player)
            end
            player:SendAddonMessage("SpellChoiceStatus", status, 0, player)

            -- NEW: Send reroll count too
            player:SendAddonMessage("SpellChoiceRerolls", tostring(rerolls), 0, player)
            SendRerollState(player, successful)

            -- RESTORE DRAFT UI AFTER RELOAD: Send spell choices back
            if draftState == 1 then
                if not fullSpellPools[guid] or #fullSpellPools[guid] == 0 then
                    LoadValidSpellChoices(player, player:GetLevel())
                end
                if not restoredPending then
                    local query = CharDBQuery("SELECT total_expected_drafts, successful_drafts FROM prestige_stats WHERE player_id = " .. guid)
                    local totalExpected = query and query:GetUInt32(0) or 0
                    local successful = query and query:GetUInt32(1) or 0
                    if successful < totalExpected then
                        local spells = LoadSpellsFromDB(guid)
                        if spells and spells[1] > 0 then
                            currentDraftChoices[guid] = spells
                            SendDraftChoices(player, spells)
                        else
                            local stats = CharDBQuery("SELECT rerolls FROM prestige_stats WHERE player_id = " .. guid)
                            local rerolls = stats and stats:GetUInt32(0) or 0
                            BeginDraftLoop(player, guid, rerolls, successful, totalExpected)
                        end
                    end
                end
            end
        end
        return false
    end
    if msg == "SC_REPLACE_BANNED" then
        local guid = player:GetGUIDLow()
        local current = LoadSpellsFromDB(guid)
        local replaced = false
        local bansQ = CharDBQuery("SELECT bans FROM prestige_stats WHERE player_id = " .. guid)
        if bansQ then
          local bansRemaining = bansQ:GetUInt32(0)
          player:SendAddonMessage("SpellChoiceBansLeft", tostring(bansRemaining), 0, player)
        end
        if current then
        LoadValidSpellChoices(player, player:GetLevel())

        local newChoices = {}
        local excludeSet = {}
        local bannedIDs = {}

        -- Phase 1: Collect all unbanned spells first
        for _, id in ipairs(current) do
            local isBanned = CharDBQuery("SELECT 1 FROM draft_bans WHERE player_id = " .. guid .. " AND spell_id = " .. id)
            if isBanned then
                table.insert(bannedIDs, id)
            else
                table.insert(newChoices, id)
                excludeSet[id] = true
            end
        end

        -- Optional: fetch all banned spells into a set for safety check
        local bannedSet = {}
        local banQ = CharDBQuery("SELECT spell_id FROM draft_bans WHERE player_id = " .. guid)
        if banQ then
            repeat
                bannedSet[banQ:GetUInt32(0)] = true
            until not banQ:NextRow()
        end

        local replaced = false

        -- Phase 2: Replace each banned spell
        for _, _ in ipairs(bannedIDs) do
            local newList = GetRandomSpells(1, guid, excludeSet)
            local new = newList and newList[1]
            if new and not bannedSet[new] then
                table.insert(newChoices, new)
                excludeSet[new] = true
                replaced = true
            end
        end


            currentDraftChoices[guid] = newChoices
            SaveSpellsToDB(guid, newChoices)

            SendDraftChoices(player, newChoices)

        end

        return false
    end

    -- Handle SC_REROLL. New clients bind the request to a unique click token
    -- and the exact visible offer. The global guard is deliberately shared by
    -- all loaded Lua chunks, so even an accidentally duplicated event
    -- registration cannot charge one click twice.
    local rerollToken, expected1, expected2, expected3 =
        msg:match("^SC_REROLL:(%-?%d+):(%d+):(%d+):(%d+)$")
    if msg == "SC_REROLL" or rerollToken then
        local pendingQ = CharDBQuery("SELECT offered_is_talent, offered_spell_1, offered_spell_2, offered_spell_3 FROM prestige_stats WHERE player_id = " .. guid)
        if rerollToken then
            SpellDraftRerollRequestGuard = SpellDraftRerollRequestGuard or {}
            local now = os.time()
            local requestKey = tostring(guid) .. ":" .. rerollToken
            if SpellDraftRerollRequestGuard[requestKey] then
                return false
            end
            SpellDraftRerollRequestGuard[requestKey] = now
            for key, seenAt in pairs(SpellDraftRerollRequestGuard) do
                if now - seenAt > 30 then
                    SpellDraftRerollRequestGuard[key] = nil
                end
            end

            local offerMatches = pendingQ
                and pendingQ:GetUInt32(1) == tonumber(expected1)
                and pendingQ:GetUInt32(2) == tonumber(expected2)
                and pendingQ:GetUInt32(3) == tonumber(expected3)
            if not offerMatches then
                -- The cards already changed, so this request was stale or was
                -- the duplicate delivery of a click that has already settled.
                if pendingQ and pendingQ:GetUInt32(1) > 0 then
                    SendDraftChoices(player, {
                        pendingQ:GetUInt32(1),
                        pendingQ:GetUInt32(2),
                        pendingQ:GetUInt32(3)
                    })
                end
                return false
            end
        end
        local pendingTalent = pendingQ and pendingQ:GetUInt32(0) == 1 and pendingQ:GetUInt32(1) > 0
        if pendingTalent then
            activeTalentDrafts[guid] = true
            local essence, used = GetTalentEconomy(guid)
            local cost = TALENT_REROLL_COSTS[used + 1]
            if not cost then
                player:SendBroadcastMessage("|cffff4444This Tome draft has reached its reroll limit.|r")
                SendTalentEconomyState(player)
                return false
            end
            if essence < cost then
                player:SendBroadcastMessage(string.format("|cffff4444Not enough Talent Essence. Need %d, have %d.|r", cost, essence))
                SendTalentEconomyState(player)
                return false
            end

            local previous = {
                [pendingQ:GetUInt32(1)] = true,
                [pendingQ:GetUInt32(2)] = true,
                [pendingQ:GetUInt32(3)] = true
            }
            local spells = RollTalentChoices(player, player:GetLevel(), previous)
            if #spells == 0 then
                player:SendBroadcastMessage("|cffff4444No alternative special talents are currently available. Essence was not spent.|r")
                return false
            end

            -- Charge and advance the durable round counter before publishing
            -- the replacement cards.  A reload cannot restore the old price.
            CharDBQuery(string.format(
                "UPDATE spelldraft_talent_essence SET " ..
                "sellable_essence = LEAST(sellable_essence, essence - %d), " ..
                "essence = essence - %d, round_rerolls = round_rerolls + 1 " ..
                "WHERE guid = %d AND essence >= %d AND round_rerolls = %d",
                cost,
                cost, guid, cost, used
            ))
            local newEssence, newUsed = GetTalentEconomy(guid)
            if newUsed ~= used + 1 then
                player:SendBroadcastMessage("|cffff4444Talent reroll state changed. Please try again.|r")
                SendTalentEconomyState(player)
                return false
            end

            currentDraftChoices[guid] = spells
            SaveSpellsToDB(guid, spells, true)
            SendDraftChoices(player, spells)
            player:SendBroadcastMessage(string.format("|cffbb88ffTalent rerolled for %d Essence. %d Essence remains.|r", cost, newEssence))
            return false
        end
        local result = CharDBQuery("SELECT draft_state, rerolls, total_expected_drafts, successful_drafts FROM prestige_stats WHERE player_id = " .. guid)
        local successful = 0
        if result then
            successful = result:GetUInt32(3)
            local remaining = math.max(0, result:GetUInt32(2) - successful)
            player:SendAddonMessage("SpellChoiceDrafts", tostring(remaining), 0, player)
        end
        if not result or result:GetUInt32(0) < 1 then
            player:SendBroadcastMessage("You are not prestiged.")
            return false
        end

        local unlimited = IsFirstDrawUnlimited(successful)
        local rerolls = result:GetUInt32(1)

        if not unlimited and rerolls <= 0 then
            player:SendBroadcastMessage("No rerolls remaining.")
            SendRerollState(player, successful)
            return false
        end

        -- Reduce reroll count and update (skipped while unlimited free rerolls are active)
        -- Synchronous: SyncDraftStats below re-reads rerolls immediately, and the
        -- async CharDBExecute loses that race, re-sending the stale pre-decrement count.
        if not unlimited then
            CharDBQuery("UPDATE prestige_stats SET rerolls = rerolls - 1 WHERE player_id = " .. guid)
        end

        local spells = GetRandomSpells(3, guid)
        currentDraftChoices[guid] = spells
        SaveSpellsToDB(guid, spells)
        SendDraftChoices(player, spells)
        local newRerolls = unlimited and rerolls or (rerolls - 1)
        player:SendAddonMessage("SpellChoiceRerolls", tostring(newRerolls), 0, player)
        SendRerollState(player, successful)
        
        SyncDraftStats(player)
        return false
    end
    -- Handle SC_BAN:<spellId>
    local banSpellId = tonumber(msg:match("^SC_BAN:(%d+)"))
    if banSpellId then
        if activeTalentDrafts[guid] then
            player:SendBroadcastMessage("You cannot ban spells during a Tome of Talents draft.")
            return false
        end
        if not currentDraftChoices[guid] or not tableContains(currentDraftChoices[guid], banSpellId) then
            player:SendAddonMessage("SpellChoiceBanDenied", "invalid", 0, player)
            return false
        end
        local bansQ = CharDBQuery("SELECT bans FROM prestige_stats WHERE player_id = " .. guid)
        if not bansQ then return false end

        local bansLeft = bansQ:GetUInt32(0)

        if bansLeft <= 0 then
            player:SendAddonMessage("SpellChoiceBanDenied", "0", 0, player)
            return false
        end

        -- Subtract ban, insert ban into DB
        -- Synchronous decrement: SyncDraftStats below re-reads bans immediately
        CharDBQuery("UPDATE prestige_stats SET bans = bans - 1 WHERE player_id = " .. guid)
        CharDBExecute("INSERT IGNORE INTO draft_bans (player_id, spell_id) VALUES (" .. guid .. ", " .. banSpellId .. ")")

        -- Remove from global pool
        local removed = false
        for i = #(fullSpellPools[guid] or {}), 1, -1 do
            if fullSpellPools[guid][i] == banSpellId then
                table.remove(fullSpellPools[guid], i)
                removed = true
                break
            end
        end

        -- Also remove from player's 3 draft picks (if they match)
        if currentDraftChoices[guid] then
            for i = #currentDraftChoices[guid], 1, -1 do
                if currentDraftChoices[guid][i] == banSpellId then
                    table.remove(currentDraftChoices[guid], i)
                    break
                end
            end
        end

        player:SendAddonMessage("SpellChoiceBanAccepted", tostring(banSpellId), 0, player)
        SyncDraftStats(player)

        return false
    end


    local spellText, requestToken = msg:match("^SC:(%d+):?(%d*)$")
    local spellId = tonumber(spellText)
    if not spellId then return end
    TraceChoice(player, spellId, requestToken, "RECEIVED", "choice request reached server")

    local level = player:GetLevel()
    local result = CharDBQuery("SELECT draft_state, total_expected_drafts, successful_drafts, offered_is_talent FROM prestige_stats WHERE player_id = " .. guid)
    local draftState = result and result:GetUInt32(0) or 0
    local isPrestiged = draftState == 1
    local expected = result and result:GetUInt32(1) or 0
    local successful = result and result:GetUInt32(2) or 0
    local isTalentDraft = result and result:GetUInt32(3) == 1 or false

    if not isPrestiged then
        player:SendBroadcastMessage("You are not prestiged.")
        SendChoiceResult(player, false, spellId, requestToken)
        TraceChoice(player, spellId, requestToken, "REJECT_MODE", "character is not in random draft mode")
        return false
    end

    -- Entitlement is checked before HasSpell and every automatic replacement.
    -- Otherwise a stale known-spell card at 0 remaining can reroll forever.
    if not isTalentDraft and successful >= expected then
        CharDBQuery("UPDATE prestige_stats SET offered_spell_1 = 0, offered_spell_2 = 0, offered_spell_3 = 0, offered_is_talent = 0 WHERE player_id = " .. guid)
        currentDraftChoices[guid] = nil
        activeTalentDrafts[guid] = nil
        player:SendAddonMessage("SpellChoiceDrafts", "0", 0, player)
        player:SendAddonMessage("SpellChoiceClose", "", 0, player)
        SendChoiceResult(player, false, spellId, requestToken)
        TraceChoice(player, spellId, requestToken, "REJECT_ENTITLEMENT", "no normal draft entitlement remains")
        return false
    end

    if IsDraftSpellApplied(player, spellId) then
        player:SendBroadcastMessage("You already know that spell. Rerolling...")
        SendChoiceResult(player, false, spellId, requestToken)
        TraceChoice(player, spellId, requestToken, "REJECT_KNOWN", "spell or linked gameplay spell is already known")

        -- Rebuild instead of drawing again from the stale pool that contained
        -- this now-known spell.
        LoadValidSpellChoices(player, player:GetLevel())
        local spells = GetRandomSpells(3, guid)
        currentDraftChoices[guid] = spells
        SaveSpellsToDB(guid, spells)
        SendDraftChoices(player, spells)
        return false
    end

    local validChoices = currentDraftChoices[guid]

    -- Eluna reloads, zone callbacks, or reconnect timing can leave the
    -- in-memory choice table empty while the authoritative three choices are
    -- still persisted in prestige_stats. Rebuild memory from the DB before
    -- rejecting the click.
    if not validChoices or not tableContains(validChoices, spellId) then
        local saved = CharDBQuery("SELECT offered_spell_1, offered_spell_2, offered_spell_3 FROM prestige_stats WHERE player_id = " .. guid)
        if saved then
            local persistedChoices = {
                saved:GetUInt32(0),
                saved:GetUInt32(1),
                saved:GetUInt32(2)
            }
            if tableContains(persistedChoices, spellId) then
                validChoices = persistedChoices
                currentDraftChoices[guid] = persistedChoices
            end
        end
    end

    if not validChoices or not tableContains(validChoices, spellId) then
        -- A delayed client click can refer to a superseded visual set.  Refresh
        -- the authoritative cards instead of leaving the UI frozen and
        -- repeatedly printing "Invalid spell selection".
        if CheckAndRestorePendingDraft(player) then
            player:SendBroadcastMessage("Card choices were refreshed. Please choose again.")
        else
            player:SendBroadcastMessage("Invalid spell selection.")
        end
        SendChoiceResult(player, false, spellId, requestToken)
        TraceChoice(player, spellId, requestToken, "REJECT_STALE", "spell id is not in the persisted offered set")
        return false
    end

    -- Persist the accepted choice before LearnSpell. The in-memory bypass is
    -- still used, while the DB row also protects against a delayed or
    -- duplicate anti-cheat callback.
    CharDBQuery("INSERT IGNORE INTO drafted_spells (player_guid, spell_id) VALUES (" .. guid .. ", " .. spellId .. ")")

    -- Use the persisted flag read above as authority. In-memory state can be
    -- empty after a Lua reload even though this Tome round is still valid.
    if isTalentDraft then
        activeTalentDrafts[guid] = true
        SpellDraft_SetSystemLearning(guid, true)
        ApplyAuthorizedDraftSpell(player, spellId)
        if type(SpellDraft_OnResourceSpellLearned) == "function" then
            SpellDraft_OnResourceSpellLearned(player, spellId)
        end
        SpellDraft_SetSystemLearning(guid, false)
        -- Do not use an immediate exact-ID HasSpell check here. AzerothCore can
        -- supersede a rank, activate a talent in the current spec, or finish the
        -- spell-map update after the Lua call returns. The upstream module also
        -- commits after LearnSpell without this exact-ID postcondition. The
        -- durable drafted_spells row authorizes login self-heal, while the
        -- delayed persistence check below remains diagnostic-only.
        activeTalentDrafts[guid] = nil
        -- [beascend]关闭升级白柱特效 player:CastSpell(player, 24312, true)
        -- [beascend]关闭升级白柱特效 player:RemoveAura(24312)
        
        -- Persist the talent in drafted_spells
        CharDBExecute("INSERT IGNORE INTO drafted_spells (player_guid, spell_id) VALUES (" .. guid .. ", " .. spellId .. ")")
        -- If this is part of a talent chain, unlearn/delete previous ranks!
        local chainInfo = talentChains[spellId]
        if chainInfo then
            for rIndex = 1, chainInfo.rankIndex - 1 do
                local prevSpellId = chainInfo.ranks[rIndex]
                player:RemoveSpell(prevSpellId)
                CharDBExecute("DELETE FROM character_spell WHERE guid = " .. guid .. " AND spell = " .. prevSpellId)
                CharDBExecute("DELETE FROM drafted_spells WHERE player_guid = " .. guid .. " AND spell_id = " .. prevSpellId)
            end
        end
        -- Publish only the normalized final chain. Sending before the deletes
        -- exposed both old and new ranks until relog and made the learned
        -- catalog flicker or select the stale rank.
        SyncDraftedTalents(player, spellId)
        
        -- Close this Tome round authoritatively.  Clearing offered_is_talent in
        -- the same synchronous step prevents a double-click/reload from
        -- turning one book into a second selection.
        CharDBQuery("UPDATE prestige_stats SET offered_spell_1 = 0, offered_spell_2 = 0, offered_spell_3 = 0, offered_is_talent = 0 WHERE player_id = " .. guid)
        CharDBQuery("UPDATE spelldraft_talent_essence SET round_rerolls = 0 WHERE guid = " .. guid)
        currentDraftChoices[guid] = nil
        
        -- Acknowledge the committed choice before slower rank synchronization.
        SendChoiceResult(player, true, spellId, requestToken)
        TraceChoice(player, spellId, requestToken, "ACCEPT_TALENT", "learn request committed; delayed chain verification queued")
        player:SendBroadcastMessage("|cff00ff00You have successfully drafted your talent!|r")
        player:SendAddonMessage("SpellChoiceClose", "", 0, player)
        QueueChoicePersistenceCheck(player, spellId, requestToken)
        QueueUpgradeKnownSpells(player, spellId)
        return false
    end

    SpellDraft_SetSystemLearning(guid, true)
    player:LearnSpell(spellId)  -- [beascend] learnSpell 自带 SMSG_LEARNED_SPELL → SPELLS_CHANGED → 插件技能书实时刷新, 不用小退
    if type(SpellDraft_OnResourceSpellLearned) == "function" then
        SpellDraft_OnResourceSpellLearned(player, spellId)
    end
    SpellDraft_SetSystemLearning(guid, false)
    -- See the talent branch above: an immediate exact-ID HasSpell postcondition
    -- is not a reliable LearnSpell result on this core and caused valid cards
    -- (notably ranked Druid/Warlock spells) to be rejected intermittently.

    -- Increment only after LearnSpell has committed successfully.
    local newSuccessful = successful + 1
    CharDBQuery("UPDATE prestige_stats SET successful_drafts = " .. newSuccessful .. " WHERE player_id = " .. guid)
    local remaining = math.max(0, expected - newSuccessful)
    player:SendAddonMessage("SpellChoiceDrafts", tostring(remaining), 0, player)
    -- [beascend]关闭升级白柱特效 player:CastSpell(player,24312,true)
    -- [beascend]关闭升级白柱特效 player:RemoveAura(24312)

    -- Auto-grant Shaman totems if player drafts a totem spell
    local nameQuery = WorldDBQuery("SELECT Name_Lang_enUS FROM dbc_spells WHERE ID = " .. spellId)
    if nameQuery then
        local spellName = nameQuery:GetString(0)
        if string.find(spellName, "Totem") or string.find(spellName, "Call of the") then
            local totems = {5175, 5176, 5177, 5178}
            for _, itemId in ipairs(totems) do
                if not player:HasItem(itemId) then
                    player:AddItem(itemId, 1)
                end
            end
        end
    end

    -- Additional spell groups. Persist each kit spell in drafted_spells so the
    -- anti-cheat and login self-heal treat them like the parent draft pick.
    local function GrantKitSpells(extraSpells)
        for _, sid in ipairs(extraSpells) do
            CharDBExecute("INSERT IGNORE INTO drafted_spells (player_guid, spell_id) VALUES (" .. guid .. ", " .. sid .. ")")
            player:LearnSpell(sid)
            if type(SpellDraft_OnResourceSpellLearned) == "function" then
                SpellDraft_OnResourceSpellLearned(player, sid)
            end
            -- [beascend]关闭升级白柱特效 player:CastSpell(player,24312,true)
            -- [beascend]关闭升级白柱特效 player:RemoveAura(24312)
        end
    end
    if spellId == 1515 then -- Tame Beast Starter Kit
        GrantKitSpells({883, 2641, 6991, 982, 136}) -- Call, Dismiss, Feed, Revive, Mend Pet
    elseif spellId == 47241 then -- Metamorphosis Starter Kit
        GrantKitSpells({50581, 59671, 54785, 50589}) -- Shadow Cleave, Challenging Howl, Demon Charge, Immolation Aura
    elseif spellId == 9634 or spellId == 5487 then -- Bear Form / Dire Bear Form Starter Kit
        GrantKitSpells({6807, 6795, 99}) -- Maul, Growl, Demoralizing Roar (1062 is Entangling Roots R2, not Demo Roar!)
    elseif spellId == 768 then -- Cat Form Starter Kit
        GrantKitSpells({1082, 5215}) -- Claw, Prowl
    elseif spellId == 1784 then -- Rogue Stealth Starter Kit
        GrantKitSpells({921, 11297}) -- Pick Pocket, Sap
    elseif spellId == 2457 then -- Battle Stance Starter Kit
        GrantKitSpells({100}) -- Charge
    elseif spellId == 71 then -- Defensive Stance Starter Kit
        GrantKitSpells({355}) -- Taunt
    elseif spellId == 2458 then -- Berserker Stance Starter Kit
        GrantKitSpells({6552}) -- Pummel
    end
    for i = #(fullSpellPools[guid] or {}), 1, -1 do
        if fullSpellPools[guid][i] == spellId then
            table.remove(fullSpellPools[guid], i)
            break
        end
    end
    CharDBQuery(string.format([[
        UPDATE prestige_stats
        SET offered_spell_1 = 0, offered_spell_2 = 0, offered_spell_3 = 0
        WHERE player_id = %d
    ]], guid))
    CharDBQuery("INSERT IGNORE INTO drafted_spells (player_guid, spell_id) VALUES (" .. guid .. ", " .. spellId .. ")")
    currentDraftChoices[guid] = nil
    SendChoiceResult(player, true, spellId, requestToken)
    TraceChoice(player, spellId, requestToken, "ACCEPT_SPELL", "learn request committed; delayed chain verification queued")
    player:SendAddonMessage("SpellChoiceClose", "", 0, player)
    QueueChoicePersistenceCheck(player, spellId, requestToken)
    QueueUpgradeKnownSpells(player, spellId)
    -- The first pick ends any unlimited-reroll window; refresh the client flag
    SendRerollState(player, newSuccessful)

    -- Check for additional pending drafts using local counters
    if newSuccessful < expected then
        LoadValidSpellChoices(player, player:GetLevel())
        local spells = GetRandomSpells(3, guid)
        currentDraftChoices[guid] = spells
        SaveSpellsToDB(guid, spells)
        SendDraftChoices(player, spells)
    end

    return false
end


BeginDraftLoop = function(player, guid, rerolls, successful, expected)
    if not player or not player:IsInWorld() then return end
    if type(SpellDraft_IsDraftRuntimeReady) == "function"
        and not SpellDraft_IsDraftRuntimeReady(player) then return end
    if successful >= expected then return end
    if CheckAndRestorePendingDraft(player) then return end

    -- Send status and rerolls again, just to be safe

    local playerGuid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT total_expected_drafts, successful_drafts FROM prestige_stats WHERE player_id = " .. playerGuid)
    if query then
        local totalExpected = query:GetUInt32(0)
        successful = query:GetUInt32(1)
        local totalDrafts = totalExpected - successful
        if totalDrafts < 0 then totalDrafts = 0 end -- safety clamp
        player:SendAddonMessage("SpellChoiceDrafts", tostring(totalDrafts), 0, player)
    end

    player:SendAddonMessage("SpellChoiceStatus", "prestiged", 0, player)
    player:SendAddonMessage("SpellChoiceRerolls", tostring(rerolls), 0, player)
    SendRerollState(player, successful)

    -- First spell roll
    -- Load from DB or generate if missing
    local spells = LoadSpellsFromDB(guid)
    if not spells or not spells[1] or spells[1] <= 0 then
        spells = GetRandomSpells(3, guid)
        SaveSpellsToDB(guid, spells)
    end
    currentDraftChoices[guid] = spells
    SendDraftChoices(player, spells)
end

local function GetHighestManualTalentRanks(guid)
    local highestByTalent = {}
    local query = CharDBQuery("SELECT spell_id FROM manually_acquired_talents WHERE player_guid = " .. guid)
    if query then
        repeat
            local spellId = query:GetUInt32(0)
            local info = talentChains[spellId]
            if info then
                local current = highestByTalent[info.talentId]
                if not current or info.rankIndex > current.rankIndex then
                    highestByTalent[info.talentId] = info
                end
            end
        until not query:NextRow()
    end
    return highestByTalent
end

local function GetStoredTalentRank(guid, chainInfo)
    local highest = GetHighestManualTalentRanks(guid)[chainInfo.talentId]
    return highest and highest.rankIndex or 0
end

-- These two projections are intentionally independent from talent_dbc.  The
-- manually_acquired_talents table is the persistence authority, while the
-- generic talent snapshot can be incomplete during login/reload.  Keep these
-- packets last so an empty generic snapshot cannot turn a saved 5/5 into 0/5.
local function SendDivineIntellectDisplayRank(player)
    if not player then return 0 end
    local guid = player:GetGUIDLow()
    local query = CharDBQuery(string.format([[
        SELECT COALESCE(MAX(CASE spell_id
            WHEN 20257 THEN 1 WHEN 20258 THEN 2 WHEN 20259 THEN 3
            WHEN 20260 THEN 4 WHEN 20261 THEN 5 ELSE 0 END), 0)
        FROM manually_acquired_talents
        WHERE player_guid = %d AND spell_id BETWEEN 20257 AND 20261
    ]], guid))
    local rank = query and query:GetUInt32(0) or 0
    if player.SetSpellDraftDivineIntellectRank then
        pcall(function() player:SetSpellDraftDivineIntellectRank(rank) end)
    end
    player:SendAddonMessage("SCDI", tostring(rank), 0, player)
    return rank
end

local function SendAncestralKnowledgeDisplayRank(player)
    if not player then return 0 end
    local guid = player:GetGUIDLow()
    local query = CharDBQuery(string.format([[
        SELECT COALESCE(MAX(CASE spell_id
            WHEN 17485 THEN 1 WHEN 17486 THEN 2 WHEN 17487 THEN 3
            WHEN 17488 THEN 4 WHEN 17489 THEN 5 ELSE 0 END), 0)
        FROM manually_acquired_talents
        WHERE player_guid = %d AND spell_id BETWEEN 17485 AND 17489
    ]], guid))
    local rank = query and query:GetUInt32(0) or 0
    player:SendAddonMessage("SCAK", tostring(rank), 0, player)
    return rank
end

-- B0.5.1: display-only compatibility channel for Divine Strength.  With many
-- confirmed talents the generic SCTRanks payload can exceed the 3.3.5 addon
-- message size, so the controlled sample needs the same final DB projection
-- already proven by Divine Intellect and Ancestral Knowledge.
local function SendDivineStrengthDisplayRank(player)
    if not player then return 0 end
    local guid = player:GetGUIDLow()
    local query = CharDBQuery(string.format([[
        SELECT COALESCE(MAX(CASE spell_id
            WHEN 20262 THEN 1 WHEN 20263 THEN 2 WHEN 20264 THEN 3
            WHEN 20265 THEN 4 WHEN 20266 THEN 5 ELSE 0 END), 0)
        FROM manually_acquired_talents
        WHERE player_guid = %d AND spell_id BETWEEN 20262 AND 20266
    ]], guid))
    local rank = query and query:GetUInt32(0) or 0
    player:SendAddonMessage("SCDS", tostring(rank), 0, player)
    return rank
end

-- B0.8.3: final DB-authoritative display projection for Strength of Arms.
-- This deliberately mirrors the three user-verified SCDI/SCAK/SCDS samples:
-- gameplay remains native Aura state, while this short packet fixes only the
-- client rank key when bulk transport is absent or incomplete.
local function SendStrengthOfArmsDisplayRank(player)
    if not player then return 0 end
    local guid = player:GetGUIDLow()
    local query = CharDBQuery(string.format([[
        SELECT COALESCE(MAX(CASE spell_id
            WHEN 46865 THEN 1 WHEN 46866 THEN 2 ELSE 0 END), 0)
        FROM manually_acquired_talents
        WHERE player_guid = %d AND spell_id IN (46865, 46866)
    ]], guid))
    local rank = query and query:GetUInt32(0) or 0
    player:SendAddonMessage("SCSOA", tostring(rank), 0, player)
    return rank
end

-- B0.9 unified final projection.  It reads the purchase authority directly,
-- maps every registered rank SpellID back to its first-rank key, and uses one
-- shared prefix for all present and future registered chains.  The historical
-- dedicated packets remain during rollout, but this message is sent last.
local function SendRegisteredTalentDisplayRanks(player)
    if not player then return end
    local stored = {}
    local query = CharDBQuery("SELECT spell_id FROM manually_acquired_talents WHERE player_guid = " .. player:GetGUIDLow())
    if query then
        repeat stored[query:GetUInt32(0)] = true until not query:NextRow()
    end
    local firstRanks = {}
    for firstRankSpellId in pairs(CUSTOM_TALENT_CHAINS) do table.insert(firstRanks, firstRankSpellId) end
    table.sort(firstRanks)
    for _, firstRankSpellId in ipairs(firstRanks) do
        local rank = 0
        for rankIndex, rankSpellId in ipairs(CUSTOM_TALENT_CHAINS[firstRankSpellId].ranks) do
            if stored[rankSpellId] then rank = rankIndex end
        end
        player:SendAddonMessage("SCTReg", tostring(firstRankSpellId) .. "=" .. tostring(rank), 0, player)
    end
end

local function SyncCustomTalentRuntime(player)
    if not player then return 0 end
    local divineRank = SendDivineIntellectDisplayRank(player)
    SendAncestralKnowledgeDisplayRank(player)
    SendDivineStrengthDisplayRank(player)
    SendStrengthOfArmsDisplayRank(player)
    SendRegisteredTalentDisplayRanks(player)
    return divineRank
end

-- B0.7 scalable confirmed-rank transport.  A single SCTRanks payload grows
-- past the 3.3.5 addon-message limit once a character owns many talents.
-- Send one compact rank per packet inside a token/count-framed transaction;
-- the client applies it only after every item and the matching end marker.
local talentRankSyncSerial = {}
local acquiredSpellSyncSerial = {}

local function SendChunkedTalentRanks(player, rankParts)
    if not player then return end
    local guid = player:GetGUIDLow()
    local serial = ((talentRankSyncSerial[guid] or 0) % 999999) + 1
    talentRankSyncSerial[guid] = serial
    local count = #rankParts
    player:SendAddonMessage("SCTRBegin", tostring(serial) .. "|" .. tostring(count), 0, player)
    for _, rankPart in ipairs(rankParts) do
        player:SendAddonMessage("SCTRPart", tostring(serial) .. "|" .. rankPart, 0, player)
    end
    player:SendAddonMessage("SCTREnd", tostring(serial) .. "|" .. tostring(count), 0, player)
end

-- B0.9.15.11: acquired Tome/Draft abilities and adjustable talent ranks are
-- different kinds of state.  A locked one-rank ability such as Titan's Grip
-- belongs in the left learned-spell catalog, but must never appear as a
-- refundable card in the right talent panel.  Send every persisted acquired
-- spell on its own scalable, count-framed channel instead of deriving this
-- list from Talent.dbc chains.
local function SendChunkedAcquiredSpells(player, spellIds)
    if not player then return end
    local guid = player:GetGUIDLow()
    local serial = ((acquiredSpellSyncSerial[guid] or 0) % 999999) + 1
    acquiredSpellSyncSerial[guid] = serial
    local count = #spellIds
    player:SendAddonMessage("SCABegin", tostring(serial) .. "|" .. tostring(count), 0, player)
    for _, spellId in ipairs(spellIds) do
        player:SendAddonMessage("SCAPart", tostring(serial) .. "|" .. tostring(spellId), 0, player)
    end
    player:SendAddonMessage("SCAEnd", tostring(serial) .. "|" .. tostring(count), 0, player)
end

-- Small authoritative deltas for every currently confirmed talent.  Real
-- 3.3.5 transport can lose one packet from a large burst; the framed snapshot
-- then (correctly) refuses the incomplete transaction.  Sending the owned
-- first-rank keys again through one shared prefix makes login, reopen and
-- refund self-heal without maintaining a per-talent SCD*/whitelist protocol.
local function SendConfirmedTalentRankDeltas(player, bestByTalent)
    local rankParts = {}
    for _, confirmed in pairs(bestByTalent or {}) do
        if confirmed.ranks and confirmed.ranks[1] and confirmed.rankIndex then
            table.insert(rankParts,
                tostring(confirmed.ranks[1]) .. "=" .. tostring(confirmed.rankIndex))
        end
    end
    table.sort(rankParts)
    for _, rankPart in ipairs(rankParts) do
        player:SendAddonMessage("SCTRank", rankPart, 0, player)
    end
end

local function ApplyManualTalentRank(player, chainInfo, rankIndex)
    if not player or not chainInfo or rankIndex <= 0 then return false end
    local guid = player:GetGUIDLow()
    local finalSpellId = chainInfo.ranks[rankIndex]
    if not finalSpellId then return false end

    SpellDraft_SetSystemLearning(guid, true)
    for index, rankSpellId in ipairs(chainInfo.ranks) do
        if index ~= rankIndex then
            player:RemoveAura(rankSpellId)
            if player:HasSpell(rankSpellId) then player:RemoveSpell(rankSpellId) end
            CharDBQuery(string.format("DELETE FROM character_spell WHERE guid = %d AND spell = %d", guid, rankSpellId))
        end
    end
    local applied = false
    if IsSpellBackedCustomTalent(chainInfo) then
        -- B0: do not create PlayerTalent state.  The compiled helper learns the
        -- rank into m_spells and performs an immediate SaveToDB before returning
        -- true. Aura rejection must never roll back or hide a saved rank; the
        -- core stat system supplies the cross-class gameplay fallback.
        if player.LearnCustomTalentSpell then
            local ok, result = pcall(function()
                return player:LearnCustomTalentSpell(finalSpellId)
            end)
            applied = ok and result == true and player:HasSpell(finalSpellId)
        end
    elseif player.LearnTalentForced then
        -- Legacy path remains for non-B0 talents during the controlled rollout.
        local ok, result = pcall(function()
            return player:LearnTalentForced(chainInfo.talentId, rankIndex - 1)
        end)
        applied = ok and result == true
            and player:HasTalent(finalSpellId, player:GetActiveSpec())
    end
    SpellDraft_SetSystemLearning(guid, false)
    if applied then
        -- Native pet-condition talents can be known while their runtime
        -- spell_pet_auras set is absent after login/ResetTalents.  Re-register
        -- the selected rank explicitly; the core still selects the aura by
        -- the current pet entry and remains authoritative for its effects.
        if player.RefreshCustomTalentPetAura then
            pcall(function()
                player:RefreshCustomTalentPetAura(finalSpellId)
            end)
        end
        -- The B0 helper already saves before returning; retaining this call
        -- keeps legacy PlayerTalent ranks crash-safe as well.
        player:SaveToDB()
    end
    return applied
end

local function NormalizeManualTalents(player)
    local guid = player:GetGUIDLow()
    local highestByTalent = GetHighestManualTalentRanks(guid)
    for _, highest in pairs(highestByTalent) do
        for index, rankSpellId in ipairs(highest.ranks) do
            if index ~= highest.rankIndex then
                CharDBQuery(string.format(
                    "DELETE FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d",
                    guid, rankSpellId))
            end
        end
        ApplyManualTalentRank(player, highest, highest.rankIndex)
    end
    SyncCustomTalentRuntime(player, highestByTalent)
    return highestByTalent
end

SyncDraftedTalents = function(player, extraSpellId)
    local guid = player:GetGUIDLow()
    SyncCustomTalentRuntime(player)
    local acquiredQuery = CharDBQuery(string.format([[
        SELECT spell_id FROM drafted_spells WHERE player_guid = %d
        UNION
        SELECT spell_id FROM manually_acquired_talents WHERE player_guid = %d
    ]], guid, guid))

    local acquiredSpells = {}
    local acquiredSeen = {}
    if acquiredQuery then
        repeat
            local spellId = acquiredQuery:GetUInt32(0)
            if spellId > 0 and not acquiredSeen[spellId] then
                acquiredSeen[spellId] = true
                table.insert(acquiredSpells, spellId)
            end
        until not acquiredQuery:NextRow()
    end
    if extraSpellId and extraSpellId > 0 and not acquiredSeen[extraSpellId] then
        acquiredSeen[extraSpellId] = true
        table.insert(acquiredSpells, extraSpellId)
    end
    table.sort(acquiredSpells)
    SendChunkedAcquiredSpells(player, acquiredSpells)

    -- Only manually purchased, refundable talents belong to the right panel.
    -- Drafted/Tome abilities are intentionally excluded even when Talent.dbc
    -- happens to describe them as a one-rank talent.
    local bestByTalent = GetHighestManualTalentRanks(guid)
    local extraInfo = extraSpellId and talentChains[extraSpellId]
    if extraInfo and not LOCKED_TALENTS[extraInfo.ranks[1]] then
        local current = bestByTalent[extraInfo.talentId]
        if not current or extraInfo.rankIndex > current.rankIndex then
            bestByTalent[extraInfo.talentId] = extraInfo
        end
    end

    local talents = {}
    local rankParts = {}
    for _, info in pairs(bestByTalent) do
        table.insert(talents, info.ranks[info.rankIndex])
        table.insert(rankParts, tostring(info.ranks[1]) .. "=" .. tostring(info.rankIndex))
    end
    table.sort(talents)
    table.sort(rankParts)
    local data = table.concat(talents, ",")
    -- 3.3.5 addon-message prefixes are limited to 16 bytes.  The historical
    -- SpellChoiceTalents prefix is 18 bytes and can silently disappear after
    -- /reload, leaving the client at 0/5.  Use a short authoritative channel.
    player:SendAddonMessage("SCTalents", data, 0, player)
    -- Count-framed state prevents a truncated/empty legacy packet from
    -- erasing an already confirmed tree on the client.  SCTalents remains for
    -- rolling compatibility; updated clients prefer this authoritative frame.
    player:SendAddonMessage("SCTState", tostring(#talents) .. "|" .. data, 0, player)
    -- Direct first-rank=rank state prevents the client from having to infer a
    -- confirmed rank from spell names or packet ordering after close/reload.
    local rankData = table.concat(rankParts, ",")
    player:SendAddonMessage("SCTRanks", tostring(#rankParts) .. "|" .. rankData, 0, player)
    -- B0.7 is the scalable authority. Keep SCTRanks temporarily for rolling
    -- compatibility, but updated clients no longer depend on one long packet.
    SendChunkedTalentRanks(player, rankParts)
    -- B0.9.4: universal owned-rank delta safety net.
    SendConfirmedTalentRankDeltas(player, bestByTalent)
    -- B0.8.3: dedicated DB-authoritative projections must be the final word.
    -- The generic frame/delta is useful for normal chains, but it must never
    -- overwrite a proven persisted rank such as Strength of Arms (46865).
    SyncCustomTalentRuntime(player)
end

-- ResetTalents(true) is used to keep the native class talent UI locked in
-- Draft Mode. It also removes cross-class passive talents, so restore the
-- authoritative highest ranks immediately afterwards and on every session
-- resume. This function is intentionally global for spelldraft_talents.lua.
function SpellDraft_RestoreManualTalents(player, sendSync)
    if not player or not player:IsInWorld() or not IsRandomDraftMode(player) then return 0 end
    local guid = player:GetGUIDLow()
    local restored = 0
    local highestByTalent = NormalizeManualTalents(player)
    for _, info in pairs(highestByTalent) do
        local spellId = info.ranks[info.rankIndex]
        local present
        if IsSpellBackedCustomTalent(info) then
            present = player:HasSpell(spellId)
        else
            present = player:HasTalent(spellId, player:GetActiveSpec())
        end
        if present then restored = restored + 1 end
    end
    if sendSync then
        SyncDraftedTalents(player)
        SyncDraftStats(player)
    end
    return restored
end


-- Public, idempotent session entry shared by login and hot mode activation.
function SpellDraft_StartOrResumeChoiceSession(player, options, callback)
    if IsBotPlayer(player) then return end
    if not IsRandomDraftMode(player) then
        player:SendAddonMessage("SpellChoiceStatus", "not_prestiged", 0, player)
        player:SendAddonMessage("SpellChoiceClose", "", 0, player)
        if type(callback) == "function" then callback(false, "not_random_draft") end
        return
    end
    -- REQUIRED for the addon protocol: the client sends SC_* commands as whispers to
    -- the player's own name. With acceptWhispers off (the default for new characters),
    -- the core rejects them with "No player named X is currently playing".
    player:SetAcceptWhispers(true)
    CONFIG.EnsurePlayerLanguage(player)
    local guid = player:GetGUIDLow()
    NormalizeConvertedDkDraftExpectation(player)
    SyncDynamicDraftEntitlement(player, player:GetLevel())
    -- The native talent lock may have stripped these a moment earlier.
    SpellDraft_RestoreManualTalents(player, false)
    SyncDraftedTalents(player)
    SyncDraftStats(player)

    -- Self-healing: restore any drafted spells that might have been accidentally removed/lost
    local draftedQ = CharDBQuery("SELECT spell_id FROM drafted_spells WHERE player_guid = " .. guid)
    if draftedQ then
        SpellDraft_SetSystemLearning(guid, true)
        repeat
            local spellId = draftedQ:GetUInt32(0)
            if not IsDraftSpellApplied(player, spellId) then
                ApplyAuthorizedDraftSpell(player, spellId)
            end
        until not draftedQ:NextRow()
        SpellDraft_SetSystemLearning(guid, false)
    end
    -- Repair action-bar omissions left by older name-based clients. The client
    -- only fills empty primary slots and skips passive/already-present chains.
    QueueDraftedActionBarRepair(player)

    SyncDraftStats(player)

    local result = CharDBQuery("SELECT draft_state, rerolls, successful_drafts, total_expected_drafts FROM prestige_stats WHERE player_id = " .. guid)
    if result then
        local draft = result:GetUInt32(0)
        local rerolls = result:GetUInt32(1)
        local successful = result:GetUInt32(2)
        local expected = result:GetUInt32(3)

        if draft == 1 then
            if not CheckAndRestorePendingDraft(player) then
                --Ensure spell list is loaded
                if not fullSpellPools[guid] or #fullSpellPools[guid] == 0 then
                    LoadValidSpellChoices(player, player:GetLevel())
                end

                -- Start draft loop
                BeginDraftLoop(player, guid, rerolls, successful, expected)
            end
        else
            -- Send current bans list
            local bansQ = CharDBQuery("SELECT spell_id FROM draft_bans WHERE player_id = " .. guid)
            if bansQ then
                local banned = {}
                repeat
                    table.insert(banned, bansQ:GetUInt32(0))
                until not bansQ:NextRow()

                if #banned > 0 then
                    local data = table.concat(banned, ",")
                    player:SendAddonMessage("SpellChoiceBans", data, 0, player)
                end
            end
        end
        if type(callback) == "function" then callback(true, "choice_session_ready") end
    else
        -- Brand-new character: EnsurePrestigeEntry (spelldraft_core.lua) creates the
        -- prestige row AFTER this handler runs (script load order), so the first
        -- draft window never opened until the next relog. Retry once, after the
        -- first-login class-spell strip/grants (2s event) have settled.
        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if not p or not p:IsInWorld() then return end
            local r = CharDBQuery("SELECT draft_state, rerolls, successful_drafts, total_expected_drafts FROM prestige_stats WHERE player_id = " .. guid)
            if not r or r:GetUInt32(0) ~= 1 then
                if type(callback) == "function" then callback(false, "choice_state_missing") end
                return
            end
            if not CheckAndRestorePendingDraft(p) then
                if not fullSpellPools[guid] or #fullSpellPools[guid] == 0 then
                    LoadValidSpellChoices(p, p:GetLevel())
                end
                BeginDraftLoop(p, guid, r:GetUInt32(1), r:GetUInt32(2), r:GetUInt32(3))
            end
            if type(callback) == "function" then callback(true, "choice_session_ready") end
        end, 4000, 1)
    end
end

local function OnLogin(_, player)
    -- First-login class cleanup and the deliberate starter-spell regrant run
    -- 2-3 seconds after login. Starting cards before that point lets Warrior,
    -- Rogue and other starter actives enter the pool and become invalid later.
    if type(SpellDraft_EnsureDraftRuntime) == "function" then
        SpellDraft_EnsureDraftRuntime(player, { source = "choice_login" }, function(ok)
            if not ok then return end
            local current = GetPlayerByGUID(player:GetGUIDLow())
            if current and current:IsInWorld() then
                SpellDraft_StartOrResumeChoiceSession(current, { source = "login_runtime_ready" })
            end
        end)
        return
    end
    SpellDraft_StartOrResumeChoiceSession(player, { source = "login_legacy" })
end

local lastZoneDraft = {}

local function OnZoneChanged(event, player, newZone, newArea)
    if IsBotPlayer(player) then return end
    if not IsRandomDraftMode(player) then return end
    if type(SpellDraft_IsDraftRuntimeReady) == "function"
        and not SpellDraft_IsDraftRuntimeReady(player) then return end
    local guid = player:GetGUIDLow()
    if CheckAndRestorePendingDraft(player) then
        return
    end
    if currentDraftChoices[guid] and #currentDraftChoices[guid] == 3 then
      return
    end
    local now = os.time()
    if lastSpellChoiceSent[guid] and now - lastSpellChoiceSent[guid] < 10 then
        return
    end
    lastSpellChoiceSent[guid] = now

    local result = CharDBQuery("SELECT draft_state, successful_drafts, total_expected_drafts FROM prestige_stats WHERE player_id = " .. guid)
    if not result then return end

    local draftState = result:GetUInt8(0)
    if draftState ~= 1 then return end --not in draft mode, bail out

    local successful = result:GetUInt32(1)
    local expected = result:GetUInt32(2)

    if successful < expected then
        local now = os.time()
        if lastZoneDraft[guid] and now - lastZoneDraft[guid] < 5 then
            return
        end
        lastZoneDraft[guid] = now

        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if not p or not p:IsInWorld() then return end

            if not fullSpellPools[guid] or not currentDraftChoices[guid] then
                LoadValidSpellChoices(p, p:GetLevel())
            end

            -- Always re-read persisted choices after the delay; in-memory cards
            -- may belong to an older callback.
            local spells = LoadSpellsFromDB(guid)
            if not spells or not spells[1] or spells[1] <= 0 then
                spells = GetRandomSpells(3, guid)
                SaveSpellsToDB(guid, spells)
            end
            currentDraftChoices[guid] = spells

            SendDraftChoices(p, spells)
        end, 2000, 1)
    end
end








local function OnPlayerLogout(event, player)
    local guid = player:GetGUIDLow()
    justBlockedSpells[guid] = nil
    fullSpellPools[guid] = nil
    currentDraftChoices[guid] = nil
    lastSpellChoiceSent[guid] = nil
    lastZoneDraft[guid] = nil
    lastMsgTimes[guid] = nil
end

-- Register events
RegisterPlayerEvent(44, OnLearnSpell) -- EVENT_ON_LEARN_SPELL
RegisterPlayerEvent(13, OnLevelUp)       -- PLAYER_LEVEL_CHANGED
RegisterPlayerEvent(19, OnAddonWhisper) -- ON_WHISPER
RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(27, OnZoneChanged) -- EVENT_ON_UPDATE_ZONE
RegisterPlayerEvent(4, OnPlayerLogout) -- PLAYER_EVENT_ON_LOGOUT


-- ==========================================
-- DRAFT & REROLL CONSUMABLE ITEMS (PHASE 1)
-- ==========================================

-- Helper to check if player is in draft mode
local function IsPlayerPrestiged(player)
    if IsBotPlayer(player) then return false end
    if not IsRandomDraftMode(player) then return false end
    local guid = player:GetGUIDLow()
    local q = CharDBQuery("SELECT draft_state FROM prestige_stats WHERE player_id = " .. guid)
    return q and q:GetUInt32(0) == 1
end

-- Scroll of Rerolls (4427)
RegisterItemEvent(4427, 2, function(event, player, item, target)
    if not IsPlayerPrestiged(player) then
        player:SendBroadcastMessage("You must be in Classless Draft Mode to use this scroll.")
        return false -- prevents default consumption/spell
    end
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot use this scroll in combat.")
        return false
    end

    local guid = player:GetGUIDLow()
    
    -- Manually consume 1 scroll
    player:RemoveItem(4427, 1)
    
    CharDBExecute("UPDATE prestige_stats SET rerolls = rerolls + 1 WHERE player_id = " .. guid)
    
    player:SendBroadcastMessage("|cff00ff00Scroll of Reroll consumed. Gained +1 Draft Reroll!|r")
    player:CastSpell(player, 14752, true)
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then
            p:RemoveAura(14752)
            SyncDraftStats(p)
        end
    end, 200, 1)
    
    return false -- prevent default spell cast/consumption
end)

-- Scroll of Bans (1078)
RegisterItemEvent(1078, 2, function(event, player, item, target)
    if not IsPlayerPrestiged(player) then
        player:SendBroadcastMessage("You must be in Classless Draft Mode to use this scroll.")
        return false
    end
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot use this scroll in combat.")
        return false
    end

    local guid = player:GetGUIDLow()
    
    -- Manually consume 1 scroll
    player:RemoveItem(1078, 1)
    
    CharDBExecute("UPDATE prestige_stats SET bans = bans + 1 WHERE player_id = " .. guid)
    
    player:SendBroadcastMessage("|cff00ff00Scroll of Ban consumed. Gained +1 Draft Ban!|r")
    player:CastSpell(player, 14752, true)
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then
            p:RemoveAura(14752)
            SyncDraftStats(p)
        end
    end, 200, 1)
    
    return false
end)

-- Lost Grimoire (13149)
RegisterItemEvent(13149, 2, function(event, player, item, target)
    if not IsPlayerPrestiged(player) then
        player:SendBroadcastMessage("You must be in Classless Draft Mode to use this grimoire.")
        return false
    end
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot use this grimoire in combat.")
        return false
    end

    local guid = player:GetGUIDLow()
    -- Check if player already has an active draft open in client/DB
    local draftCheck = CharDBQuery("SELECT offered_spell_1 FROM prestige_stats WHERE player_id = " .. guid)
    if draftCheck and draftCheck:GetUInt32(0) > 0 then
        player:SendBroadcastMessage("You already have a pending draft choice. Please complete it first.")
        return false
    end

    -- Manually consume 1 grimoire
    player:RemoveItem(13149, 1)

    -- Trigger a bonus draft: increment bonus_drafts by 1 and recompute total_expected_drafts
    local bonusDrafts = 0
    local qBonus = CharDBQuery("SELECT bonus_drafts FROM prestige_stats WHERE player_id = " .. guid)
    if qBonus then
        bonusDrafts = qBonus:GetUInt32(0)
    end
    bonusDrafts = bonusDrafts + 1

    local level = player:GetLevel()
    local normalEntitlement = ReconcileDynamicProgression(player, level)
    local successfulQ = CharDBQuery("SELECT successful_drafts FROM prestige_stats WHERE player_id = " .. guid)
    local successful = successfulQ and successfulQ:GetUInt32(0) or 0
    local expectedTotal = math.max(successful, normalEntitlement + bonusDrafts)

    CharDBQuery(string.format(
        "UPDATE prestige_stats SET bonus_drafts = %d, total_expected_drafts = %d WHERE player_id = %d",
        bonusDrafts, expectedTotal, guid
    ))
    
    -- Load valid choices and roll
    LoadValidSpellChoices(player, player:GetLevel())
    local spells = GetRandomSpells(3, guid)
    currentDraftChoices[guid] = spells
    SaveSpellsToDB(guid, spells)
    
    SendDraftChoices(player, spells)
    
    player:SendBroadcastMessage("|cff00ff00Lost Grimoire consumed. A bonus draft has opened!|r")
    player:CastSpell(player, 14752, true)
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then
            p:RemoveAura(14752)
            SyncDraftStats(p)
        end
    end, 200, 1)
    
    return false
end)


-- Tome of Talents (25462)
local TOME_MINIMUM_LEVEL = 10
local tomeLevelNoticeTimes = {}

local function SendTomeMinimumLevelMessage(player)
    local guid = player:GetGUIDLow()
    local now = os.time()
    if now - (tomeLevelNoticeTimes[guid] or 0) < 2 then return end
    tomeLevelNoticeTimes[guid] = now

    local language = "enUS"
    if type(SpellDraft_GetPlayerLanguage) == "function" then
        language = SpellDraft_GetPlayerLanguage(player)
    elseif player.GetDbLocaleIndex ~= nil then
        local locale = player:GetDbLocaleIndex()
        if locale == 4 or locale == 5 then language = "zhCN" end
    end

    if language == "zhCN" then
        player:SendBroadcastMessage("|cffffcc00你尚未达到特殊天赋的最低等级（需要10级）。天赋之书未被消耗。|r")
    else
        player:SendBroadcastMessage("|cffffcc00You have not reached the minimum level for special talents (level 10 required). The Tome of Talents was not consumed.|r")
    end
end

RegisterItemEvent(25462, 2, function(event, player, item, target)
    if not IsPlayerPrestiged(player) then
        player:SendBroadcastMessage("You must be in Classless Draft Mode to use this tome.")
        return false
    end
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot use this tome in combat.")
        return false
    end

    if player:GetLevel() < TOME_MINIMUM_LEVEL then
        SendTomeMinimumLevelMessage(player)
        return false
    end

    local guid = player:GetGUIDLow()
    -- Check if player already has an active draft open in client/DB
    local draftCheck = CharDBQuery("SELECT offered_spell_1 FROM prestige_stats WHERE player_id = " .. guid)
    if draftCheck and draftCheck:GetUInt32(0) > 0 then
        player:SendBroadcastMessage("You already have a pending draft choice. Please complete it first.")
        return false
    end

    -- Roll one set of 3 special talents. One Tome always resolves to exactly
    -- one accepted choice; rerolls only replace this set.
    local level = player:GetLevel()
    local spells = RollTalentChoices(player, level)
    if #spells == 0 then
        player:SendBroadcastMessage("No unlearned special talents are currently available for your level. The Tome of Talents was not consumed.")
        return false
    end

    -- Manually consume 1 tome
    player:RemoveItem(25462, 1)

    EnsureTalentEssenceRow(guid)
    CharDBQuery("UPDATE spelldraft_talent_essence SET round_rerolls = 0 WHERE guid = " .. guid)
    activeTalentDrafts[guid] = true
    currentDraftChoices[guid] = spells
    SaveSpellsToDB(guid, spells, true)

    player:SendAddonMessage("SpellChoiceStatus", "prestiged", 0, player)
    
    SendDraftChoices(player, spells)
    
    player:SendBroadcastMessage("|cff00ff00Tome of Talents consumed. A passive talent draft has opened!|r")
    player:CastSpell(player, 14752, true)
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p then p:RemoveAura(14752) end
    end, 100, 1)

    return false
end)


-- Bypass level requirements on cosmetic toy/trinket spells by manually casting them triggered (bypassing restrictions)
local cosmeticItemSpells = {
    [1973] = 16739,   -- Orb of Deception
    [33079] = 42365,  -- Murloc Costume
    [34480] = 45094,  -- Romantic Picnic Basket
    [35275] = 46354,  -- Orb of the Sin'dorei
    [37254] = 48332,  -- Super Simian Sphere
    [43499] = 58501,  -- Iron Boot Flask
    [46780] = 65783,  -- Ogre Pinata
}

for itemId, spellId in pairs(cosmeticItemSpells) do
    RegisterItemEvent(itemId, 2, function(event, player, item, target)
        if player:IsInCombat() then
            player:SendBroadcastMessage("You cannot use this item in combat.")
            return true
        end
        player:CastSpell(player, spellId, true)
        return true
    end)
end



-- Execute talent chains loader
LoadTalentChains()

RegisterPlayerEvent(18, function(event, player, msg, type, lang)
    if msg == ".testpool" then
        local level = player:GetLevel()
        local pool = GetEligibleTalentsPool(player, level)
        player:SendBroadcastMessage("Eligible talents pool size: " .. #pool)
        
        local passives = 0
        local actives = 0
        
        for _, spellId in ipairs(pool) do
            local q = WorldDBQuery("SELECT Id FROM dbc_spells WHERE Id = " .. spellId)
            if q then
                actives = actives + 1
            else
                passives = passives + 1
            end
        end
        player:SendBroadcastMessage("Actives (in dbc_spells): " .. actives)
        player:SendBroadcastMessage("Passives (missing from dbc_spells): " .. passives)
        
        local passList = {}
        local actList = {}
        for _, spellId in ipairs(pool) do
            local name = GetSpellInfo(spellId) or ("Spell " .. spellId)
            local q = WorldDBQuery("SELECT Id FROM dbc_spells WHERE Id = " .. spellId)
            if q then
                if #actList < 10 then
                    table.insert(actList, name .. " (" .. spellId .. ")")
                end
            else
                if #passList < 10 then
                    table.insert(passList, name .. " (" .. spellId .. ")")
                end
            end
        end
        
        player:SendBroadcastMessage("Sample Actives:")
        for _, s in ipairs(actList) do
            player:SendBroadcastMessage("  - " .. s)
        end
        player:SendBroadcastMessage("Sample Passives:")
        for _, s in ipairs(passList) do
            player:SendBroadcastMessage("  - " .. s)
        end
        
        return false
    end
end)



-- Resolve a spell's display name across mod-ale variants (GetSpellInfo returns
-- a SpellInfo object on this core, not a name string)
local function GetSpellNameSafe(spellId)
    if type(GetSpellName) == "function" then
        local ok, name = pcall(GetSpellName, spellId)
        if ok and type(name) == "string" then return name end
    end
    if type(GetSpellInfo) == "function" then
        local ok, info = pcall(GetSpellInfo, spellId)
        if ok then
            if type(info) == "string" then return info end
            if info and info.GetName then
                local ok2, name = pcall(info.GetName, info)
                if ok2 and type(name) == "string" then return name end
            end
        end
    end
    return "Spell " .. tostring(spellId)
end

-- Draft-state check (each Eluna file is its own chunk; core's helper is file-local)
local function IsPlayerInDraft(player)
    if not IsRandomDraftMode(player) then return false end
    local query = CharDBQuery("SELECT draft_state FROM prestige_stats WHERE player_id = " .. player:GetGUIDLow())
    return (query and query:GetUInt32(0) == 1) or false
end

local function SendGmCardUsage(player)
    player:SendBroadcastMessage("GM SpellDraft test card: .sdmakecard <SpellID>  Example: .sdmakecard 30798")
end

-- Creates one bound physical card whose item-instance GUID carries the target
-- SpellID. It does not grant the reward and does not consume a normal draw;
-- right-clicking the card invokes GrantAuthorizedCardReward.  Right-click is
-- the native WoW inventory-item use action and reaches ITEM_EVENT_ON_USE.
RegisterPlayerEvent(42, function(event, player, command, chatHandler)
    if not player then return end
    command = command:gsub("%s+$", ""):lower()
    local spellText = command:match("^sdmakecard%s+(%d+)$")
    if command == "sdmakecard" then
        SendGmCardUsage(player)
        return false
    end
    if not spellText then return end
    if not player:IsGM() then
        player:SendBroadcastMessage("GM mode is required. Use .gm on first.")
        return false
    end
    if not IsPlayerInDraft(player) then
        player:SendBroadcastMessage("This test card can only be created in Random Draft Mode.")
        return false
    end

    local spellId = tonumber(spellText) or 0
    local spellRow = WorldDBQuery("SELECT Id FROM dbc_spells WHERE Id = " .. spellId .. " LIMIT 1")
    if not spellRow then
        player:SendBroadcastMessage("SpellID " .. spellId .. " is not present in the SpellDraft catalog database.")
        return false
    end
    if CharDBQuery(string.format(
        "SELECT 1 FROM drafted_spells WHERE player_guid = %d AND spell_id = %d LIMIT 1",
        player:GetGUIDLow(), spellId)) or IsDraftSpellApplied(player, spellId) then
        player:SendBroadcastMessage("SpellID " .. spellId .. " is already owned by this character.")
        return false
    end
    local card = player:AddItem(GM_TEST_CARD_ITEM_ENTRY, 1)
    if not card then
        player:SendBroadcastMessage("The GM test card could not be created. Check bag space and world item_template 800101.")
        return false
    end

    -- Public item-link field used by the client tooltip to identify the
    -- reward of this individual non-stackable book instance.
    card:SetUInt32Value(58, spellId) -- ITEM_FIELD_PROPERTY_SEED
    card:SaveToDB()

    local itemGuid = card:GetGUIDLow()
    local isTalent = talentChains[spellId] and 1 or 0
    CharDBQuery(string.format(
        "REPLACE INTO spelldraft_gm_test_cards (item_guid, owner_guid, spell_id, is_talent) VALUES (%d, %d, %d, %d)",
        itemGuid, player:GetGUIDLow(), spellId, isTalent))
    player:SendBroadcastMessage(string.format(
        "Created GM test card: %s (SpellID %d, %s). Right-click the card to commit it through SpellDraft.",
        GetSpellNameSafe(spellId), spellId, isTalent == 1 and "talent" or "spell"))
    return false
end)

RegisterItemEvent(GM_TEST_CARD_ITEM_ENTRY, 2, function(event, player, item, target)
    if not player:IsGM() then
        player:SendBroadcastMessage("GM mode is required to use this test card.")
        return false
    end
    if not IsPlayerInDraft(player) then
        player:SendBroadcastMessage("This test card can only be used in Random Draft Mode.")
        return false
    end
    if player:IsInCombat() then
        player:SendBroadcastMessage("This test card cannot be used in combat.")
        return false
    end

    local itemGuid = item:GetGUIDLow()
    local cardRow = CharDBQuery(string.format(
        "SELECT spell_id, owner_guid, is_talent FROM spelldraft_gm_test_cards WHERE item_guid = %d LIMIT 1",
        itemGuid))
    if not cardRow then
        player:SendBroadcastMessage("This is an unassigned GM test card. Create it with .sdmakecard <SpellID>.")
        return false
    end

    local spellId = cardRow:GetUInt32(0)
    local ownerGuid = cardRow:GetUInt32(1)
    if ownerGuid ~= player:GetGUIDLow() then
        player:SendBroadcastMessage("This GM test card belongs to another character.")
        return false
    end

    local ok, reason = GrantAuthorizedCardReward(player, spellId, "gm_item_" .. tostring(itemGuid))
    if not ok then
        player:SendBroadcastMessage(string.format(
            "GM test card failed: SpellID %d, reason=%s. The card was not consumed.",
            spellId, tostring(reason)))
        return false
    end

    CharDBQuery("DELETE FROM spelldraft_gm_test_cards WHERE item_guid = " .. itemGuid)
    player:RemoveItem(item, 1)
    player:SendBroadcastMessage(string.format(
        "GM test card accepted: %s (SpellID %d).",
        GetSpellNameSafe(spellId), spellId))
    return false
end)

local function MeetsPrerequisites(player, chain)
    -- 1. Check Level requirement based on Shifted Tier Gating (A.1)
    local level = player:GetLevel()
    local reqLevel = GetTalentRequiredLevel(chain)
    if level < reqLevel then
        return false, "Requires level " .. reqLevel
    end
    
    -- 2. Classic/native callers retain parent prerequisites. SpellDraft's
    -- classless modes deliberately treat every non-Tome node as independent.
    if not UsesIndependentClasslessTalentNodes(player) then
        for _, pre in ipairs(chain.prereqs) do
            local parentChain = talentIdToChain[pre.prereqTalentId]
            if parentChain then
                local parentRank = 0
                for rankIndex, spellId in ipairs(parentChain.ranks) do
                    if player:HasSpell(spellId) then
                        parentRank = rankIndex
                    end
                end
                if parentRank < pre.reqRank then
                    local parentSpellName = GetSpellNameSafe(parentChain.ranks[1])
                    return false, "Requires " .. pre.reqRank .. " ranks in " .. parentSpellName
                end
            end
        end
    end
    
    return true
end

-- Global: referenced by OnAddonWhisper, which is compiled earlier in this file
function HandleBuyTalent(player, spellId)
    local guid = player:GetGUIDLow()
    if not IsPlayerInDraft(player) then
        player:SendBroadcastMessage("You are not in Draft Mode.")
        return
    end
    if player:IsInCombat() then
        player:SendBroadcastMessage("You cannot purchase talents in combat.")
        return
    end

    -- 1. Verify player has talent points
    local qPoints = CharDBQuery("SELECT talent_points FROM prestige_stats WHERE player_id = " .. guid)
    if not qPoints or qPoints:GetUInt32(0) <= 0 then
        player:SendBroadcastMessage("You have no custom Talent Points to spend.")
        return
    end
    local currentPoints = qPoints:GetUInt32(0)

    -- 2. Verify the spell is a valid talent and find its chain info
    local chainInfo = talentChains[spellId]
    if not chainInfo then
        player:SendBroadcastMessage("Invalid talent spell.")
        return
    end
    
    -- 3. Check if the talent is locked (active/playstyle)
    if LOCKED_TALENTS[spellId] or LOCKED_TALENTS[chainInfo.ranks[1]] then
        player:SendBroadcastMessage("This talent is locked and can only be acquired from a Tome of Talents.")
        return
    end

    -- 4. Get player's current rank of this talent
    local currentRankIndex = 0
    for rankIndex, rSpellId in ipairs(chainInfo.ranks) do
        if player:HasSpell(rSpellId) then
            currentRankIndex = rankIndex
        end
    end

    if currentRankIndex >= #chainInfo.ranks then
        player:SendBroadcastMessage("You have already mastered this talent.")
        return
    end

    -- 5. Check prerequisites
    local allowed, errMsg = MeetsPrerequisites(player, chainInfo.chain)
    if not allowed then
        player:SendBroadcastMessage("|cffff0000Cannot learn: " .. errMsg .. "|r")
        return
    end

    local nextRankIndex = currentRankIndex + 1
    local nextSpellId = chainInfo.ranks[nextRankIndex]

    -- 6. Deduct talent point and insert/update manually_acquired_talents.
    CharDBQuery("UPDATE prestige_stats SET talent_points = talent_points - 1 WHERE player_id = " .. guid)
    
    -- Delete all ranks of this talent chain from DB & player to prevent duplicate/orphaned records
    for _, rSpellId in ipairs(chainInfo.ranks) do
        CharDBQuery(string.format("DELETE FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d", guid, rSpellId))
        
        SpellDraft_SetSystemLearning(guid, true)
        player:RemoveAura(rSpellId)
        player:RemoveSpell(rSpellId)
        SpellDraft_SetSystemLearning(guid, false)
        CharDBExecute(string.format("DELETE FROM character_spell WHERE guid = %d AND spell = %d", guid, rSpellId))
    end

    CharDBQuery(string.format("INSERT INTO manually_acquired_talents (player_guid, spell_id) VALUES (%d, %d)", guid, nextSpellId))
    
    -- Teach next rank to player
    SpellDraft_SetSystemLearning(guid, true)
    player:LearnSpell(nextSpellId)
    SpellDraft_SetSystemLearning(guid, false)

    -- [beascend]关闭升级白柱特效 player:CastSpell(player, 24312, true)
    -- [beascend]关闭升级白柱特效 player:RemoveAura(24312)

    -- Sync stats and talents to client
    SyncDraftStats(player)
    SyncDraftedTalents(player, nextSpellId)
    
    player:SendBroadcastMessage(string.format("|cff00ff00Learned %s (Rank %d)|r", GetSpellNameSafe(nextSpellId), nextRankIndex))
end

local function GetKnownTalentRank(player, chainInfo)
    -- The manual table is the authority.  HasSpell is not reliable for
    -- cross-class passive talents: the spellbook, talent map and aura can be
    -- populated at different times, especially after /reload or ResetTalents.
    return GetStoredTalentRank(player:GetGUIDLow(), chainInfo)
end

local function RejectTalentCommit(player, reason, token)
    player:SendAddonMessage("SCTCommit", tostring(token or "0") .. ":error:" .. tostring(reason or "Invalid talent plan."), 0, player)
    player:SendAddonMessage("SpellChoiceTalentCommit", "error:" .. tostring(reason or "Invalid talent plan."), 0, player)
    player:SendBroadcastMessage("|cffff4444" .. tostring(reason or "Invalid talent plan.") .. "|r")
end

-- Server-authoritative all-or-nothing validation for the client's staged plan.
-- The payload contains first-rank spell IDs and the number of ranks to add.
function HandleCommitTalents(player, payload, token)
    local guid = player:GetGUIDLow()
    if not IsPlayerInDraft(player) then
        RejectTalentCommit(player, "You are not in Draft Mode.", token)
        return
    end
    if player:IsInCombat() then
        RejectTalentCommit(player, "You cannot confirm talents in combat.", token)
        return
    end

    local allocations, byTalentId = {}, {}
    local totalPoints = 0
    for part in string.gmatch(payload or "", "[^,]+") do
        local firstText, countText = part:match("^(%d+)=(%d+)$")
        local firstSpellId, count = tonumber(firstText), tonumber(countText)
        local chainInfo = firstSpellId and talentChains[firstSpellId]
        if not chainInfo or chainInfo.ranks[1] ~= firstSpellId or not count or count < 1 then
            RejectTalentCommit(player, "Invalid talent plan.", token)
            return
        end
        if byTalentId[chainInfo.talentId] then
            RejectTalentCommit(player, "The talent plan contains a duplicate entry.", token)
            return
        end
        if LOCKED_TALENTS[firstSpellId] then
            RejectTalentCommit(player, "A locked talent can only be acquired from a Tome of Talents.", token)
            return
        end

        local currentRank = GetKnownTalentRank(player, chainInfo)
        local targetRank = currentRank + count
        if targetRank > #chainInfo.ranks then
            RejectTalentCommit(player, "A talent exceeds its maximum rank.", token)
            return
        end
        local reqLevel = GetTalentRequiredLevel(chainInfo.chain)
        if player:GetLevel() < reqLevel then
            RejectTalentCommit(player, "A talent requires level " .. reqLevel .. ".", token)
            return
        end

        local allocation = {
            firstSpellId = firstSpellId,
            chainInfo = chainInfo,
            currentRank = currentRank,
            targetRank = targetRank,
            count = count,
        }
        table.insert(allocations, allocation)
        byTalentId[chainInfo.talentId] = allocation
        totalPoints = totalPoints + count
    end

    if totalPoints <= 0 or #allocations == 0 then
        RejectTalentCommit(player, "No pending talent changes.", token)
        return
    end
    local pointsQ = CharDBQuery("SELECT talent_points FROM prestige_stats WHERE player_id = " .. guid)
    local pointsBefore = pointsQ and pointsQ:GetUInt32(0) or 0
    if not pointsQ or pointsBefore < totalPoints then
        RejectTalentCommit(player, "You do not have enough custom Talent Points.", token)
        return
    end

    -- Native/classic validation may still require a parent. Random Draft and
    -- Free Pick intentionally have no cross-node prerequisite graph.
    if not UsesIndependentClasslessTalentNodes(player) then
        for _, allocation in ipairs(allocations) do
            for _, prerequisite in ipairs(allocation.chainInfo.chain.prereqs or {}) do
                local parentChain = talentIdToChain[prerequisite.prereqTalentId]
                if parentChain then
                    local parentRank
                    local stagedParent = byTalentId[prerequisite.prereqTalentId]
                    if stagedParent then
                        parentRank = stagedParent.targetRank
                    else
                        parentRank = GetKnownTalentRank(player, talentChains[parentChain.ranks[1]])
                    end
                    if parentRank < prerequisite.reqRank then
                        RejectTalentCommit(player, "A talent prerequisite is not satisfied.", token)
                        return
                    end
                end
            end
        end
    end

    -- Snapshot the old state so a failed LearnSpell/DB verification can be
    -- rolled back without consuming points or leaving a half-applied plan.
    local oldManual = {}
    for _, allocation in ipairs(allocations) do
        oldManual[allocation.firstSpellId] = {}
        for _, rankSpellId in ipairs(allocation.chainInfo.ranks) do
            local oldQ = CharDBQuery(string.format(
                "SELECT 1 FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d LIMIT 1",
                guid, rankSpellId))
            if oldQ then table.insert(oldManual[allocation.firstSpellId], rankSpellId) end
        end
    end

    local function RollbackCommit()
        for _, allocation in ipairs(allocations) do
            for _, rankSpellId in ipairs(allocation.chainInfo.ranks) do
                CharDBQuery(string.format(
                    "DELETE FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d",
                    guid, rankSpellId))
                SpellDraft_SetSystemLearning(guid, true)
                player:RemoveAura(rankSpellId)
                player:RemoveSpell(rankSpellId)
                SpellDraft_SetSystemLearning(guid, false)
                CharDBQuery(string.format("DELETE FROM character_spell WHERE guid = %d AND spell = %d", guid, rankSpellId))
            end
            for _, oldSpellId in ipairs(oldManual[allocation.firstSpellId] or {}) do
                CharDBQuery(string.format(
                    "INSERT IGNORE INTO manually_acquired_talents (player_guid, spell_id) VALUES (%d, %d)",
                    guid, oldSpellId))
            end
        end
        -- LearnTalentForced owns native PlayerTalent entries. Remove any
        -- partially committed native entries in one pass, then rebuild every
        -- authoritative manual rank from the restored DB snapshot.
        player:ResetTalents(true)
        player:SetFreeTalentPoints(0)
        NormalizeManualTalents(player)
    end

    for _, allocation in ipairs(allocations) do
        for _, rankSpellId in ipairs(allocation.chainInfo.ranks) do
            -- Synchronous DML is required here: an asynchronous DELETE/INSERT
            -- followed immediately by SyncDraftedTalents produced false OKs.
            CharDBQuery(string.format(
                "DELETE FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d",
                guid, rankSpellId))
            SpellDraft_SetSystemLearning(guid, true)
            player:RemoveAura(rankSpellId)
            player:RemoveSpell(rankSpellId)
            SpellDraft_SetSystemLearning(guid, false)
            CharDBQuery(string.format("DELETE FROM character_spell WHERE guid = %d AND spell = %d", guid, rankSpellId))
        end

        local finalSpellId = allocation.chainInfo.ranks[allocation.targetRank]
        CharDBQuery(string.format(
            "INSERT IGNORE INTO manually_acquired_talents (player_guid, spell_id) VALUES (%d, %d)",
            guid, finalSpellId))
        local talentApplied = ApplyManualTalentRank(player, allocation.chainInfo, allocation.targetRank)

        local savedQ = CharDBQuery(string.format(
            "SELECT 1 FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d LIMIT 1",
            guid, finalSpellId))
        local liveApplied
        if IsSpellBackedCustomTalent(allocation.chainInfo) then
            liveApplied = player:HasSpell(finalSpellId)
        else
            liveApplied = player:HasTalent(finalSpellId, player:GetActiveSpec())
        end
        if not savedQ or not talentApplied or not liveApplied then
            RollbackCommit()
            RejectTalentCommit(player, "The talent could not be saved or applied. No points were consumed.", token)
            SyncDraftStats(player)
            SyncDraftedTalents(player)
            return
        end
    end

    -- Consume points only after every selected rank exists both in the DB and
    -- on the live character, then verify the authoritative balance.
    CharDBQuery(string.format(
        "UPDATE prestige_stats SET talent_points = talent_points - %d WHERE player_id = %d AND talent_points >= %d",
        totalPoints, guid, totalPoints))
    local afterQ = CharDBQuery("SELECT talent_points FROM prestige_stats WHERE player_id = " .. guid)
    if not afterQ or afterQ:GetUInt32(0) ~= pointsBefore - totalPoints then
        RollbackCommit()
        CharDBQuery(string.format("UPDATE prestige_stats SET talent_points = %d WHERE player_id = %d", pointsBefore, guid))
        RejectTalentCommit(player, "The Talent Point balance could not be committed. No points were consumed.", token)
        SyncDraftStats(player)
        SyncDraftedTalents(player)
        return
    end

    -- Short token-bound acknowledgement avoids a stale response unlocking a
    -- newer plan. Keep the legacy message during rolling client updates.
    player:SendAddonMessage("SCTCommit", tostring(token or "0") .. ":ok", 0, player)
    SyncDraftStats(player)
    SyncDraftedTalents(player)
    -- The changed keys are the final word even if a large snapshot packet was
    -- dropped by the 3.3.5 client during the preceding burst.
    for _, allocation in ipairs(allocations) do
        player:SendAddonMessage("SCTRank",
            tostring(allocation.firstSpellId) .. "=" .. tostring(allocation.targetRank), 0, player)
    end
    player:SendAddonMessage("SpellChoiceTalentCommit", "ok", 0, player)
    player:SendBroadcastMessage(string.format("|cff00ff00Talent plan confirmed. %d point(s) spent.|r", totalPoints))
end

local function RejectSingleTalentRefund(player, token, reason)
    player:SendAddonMessage("SCTRefund", tostring(token or "0") .. ":error:" .. tostring(reason or "failed"), 0, player)
    SendTalentEconomyState(player)
end

local function GetHighestDraftedTalentRanks(guid)
    local highestByTalent = {}
    local query = CharDBQuery("SELECT spell_id FROM drafted_spells WHERE player_guid = " .. guid)
    if query then
        repeat
            local spellId = query:GetUInt32(0)
            local info = talentChains[spellId]
            if info then
                local current = highestByTalent[info.talentId]
                if not current or info.rankIndex > current.rankIndex then
                    highestByTalent[info.talentId] = info
                end
            end
        until not query:NextRow()
    end
    return highestByTalent
end

local function RestoreDraftedSpellsAfterTalentReset(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT spell_id FROM drafted_spells WHERE player_guid = " .. guid)
    if not query then return end

    SpellDraft_SetSystemLearning(guid, true)
    repeat
        local spellId = query:GetUInt32(0)
        if not IsDraftSpellApplied(player, spellId) then
            ApplyAuthorizedDraftSpell(player, spellId)
        end
    until not query:NextRow()
    SpellDraft_SetSystemLearning(guid, false)
end

RebuildCustomTalentRuntime = function(player)
    player:ResetTalents(true)
    player:SetFreeTalentPoints(0)
    -- Drafted ranks are the non-refundable floor. Restore them first, then
    -- apply manually purchased ranks so a higher manual rank wins the chain.
    RestoreDraftedSpellsAfterTalentReset(player)
    NormalizeManualTalents(player)
end

-- Refund exactly one confirmed, manually purchased rank. The client supplies
-- only the first-rank spell ID; rank, cost, dependencies and balances are all
-- recalculated from authoritative server data.
function HandleRefundTalentRank(player, firstRankSpellId, token)
    local guid = player:GetGUIDLow()
    local chainInfo = talentChains[tonumber(firstRankSpellId) or 0]
    if not IsPlayerInDraft(player) then
        RejectSingleTalentRefund(player, token, "not_draft")
        return
    end
    if player:IsInCombat() then
        RejectSingleTalentRefund(player, token, "combat")
        return
    end
    if not chainInfo or chainInfo.ranks[1] ~= tonumber(firstRankSpellId) then
        RejectSingleTalentRefund(player, token, "invalid")
        return
    end
    if LOCKED_TALENTS[chainInfo.ranks[1]] then
        RejectSingleTalentRefund(player, token, "drafted_only")
        return
    end

    local manualByTalent = GetHighestManualTalentRanks(guid)
    local draftedByTalent = GetHighestDraftedTalentRanks(guid)
    local manualInfo = manualByTalent[chainInfo.talentId]
    local draftedInfo = draftedByTalent[chainInfo.talentId]
    local currentRank = manualInfo and manualInfo.rankIndex or 0
    local draftedFloor = draftedInfo and draftedInfo.rankIndex or 0
    if currentRank <= draftedFloor then
        RejectSingleTalentRefund(player, token, "no_manual_rank")
        return
    end
    local targetRank = currentRank - 1

    -- Only a native/classic tree needs protection against orphaning a child.
    -- Classless nodes are independent, so refunding a former parent is legal.
    if not UsesIndependentClasslessTalentNodes(player) then
        for childTalentId, childChain in pairs(talentIdToChain) do
            local childManual = manualByTalent[childTalentId]
            local childDrafted = draftedByTalent[childTalentId]
            local childRank = math.max(childManual and childManual.rankIndex or 0, childDrafted and childDrafted.rankIndex or 0)
            if childRank > 0 then
                for _, prerequisite in ipairs(childChain.prereqs or {}) do
                    if prerequisite.prereqTalentId == chainInfo.talentId and targetRank < prerequisite.reqRank then
                        RejectSingleTalentRefund(player, token, "dependency")
                        return
                    end
                end
            end
        end
    end

    local cost = math.max(0, math.floor(tonumber(CONFIG.TALENT_SINGLE_REFUND_ESSENCE_COST) or 1))
    EnsureTalentEssenceRow(guid)
    local economyQ = CharDBQuery("SELECT essence, sellable_essence FROM spelldraft_talent_essence WHERE guid = " .. guid)
    local essenceBefore = economyQ and economyQ:GetUInt32(0) or 0
    local sellableBefore = economyQ and economyQ:GetUInt32(1) or 0
    if essenceBefore < cost then
        RejectSingleTalentRefund(player, token, "essence")
        return
    end

    local pointsQ = CharDBQuery("SELECT talent_points FROM prestige_stats WHERE player_id = " .. guid)
    if not pointsQ then
        RejectSingleTalentRefund(player, token, "points")
        return
    end
    local pointsBefore = pointsQ:GetUInt32(0)

    local oldManualSpellIds = {}
    for _, rankSpellId in ipairs(chainInfo.ranks) do
        local oldQ = CharDBQuery(string.format(
            "SELECT 1 FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d LIMIT 1",
            guid, rankSpellId))
        if oldQ then table.insert(oldManualSpellIds, rankSpellId) end
    end

    local function RestoreSnapshot()
        for _, rankSpellId in ipairs(chainInfo.ranks) do
            CharDBQuery(string.format(
                "DELETE FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d",
                guid, rankSpellId))
        end
        for _, oldSpellId in ipairs(oldManualSpellIds) do
            CharDBQuery(string.format(
                "INSERT IGNORE INTO manually_acquired_talents (player_guid, spell_id) VALUES (%d, %d)",
                guid, oldSpellId))
        end
        CharDBQuery(string.format(
            "UPDATE prestige_stats SET talent_points = %d WHERE player_id = %d",
            pointsBefore, guid))
        CharDBQuery(string.format(
            "UPDATE spelldraft_talent_essence SET essence = %d, sellable_essence = %d WHERE guid = %d",
            essenceBefore, sellableBefore, guid))
        RebuildCustomTalentRuntime(player)
        SyncDraftStats(player)
        SyncDraftedTalents(player)
        SendTalentEconomyState(player)
        -- A failed refund restores the old DB snapshot.  Re-send this one key
        -- after the full sync so an optimistic/local 0/x display cannot remain.
        local restoredRank = GetStoredTalentRank(guid, chainInfo)
        player:SendAddonMessage("SCTRank",
            tostring(chainInfo.ranks[1]) .. "=" .. tostring(restoredRank), 0, player)
    end

    if cost > 0 then
        CharDBQuery(string.format(
            "UPDATE spelldraft_talent_essence SET sellable_essence = GREATEST(0, LEAST(sellable_essence, essence - %d)), essence = essence - %d WHERE guid = %d AND essence >= %d",
            cost, cost, guid, cost))
        local chargedQ = CharDBQuery("SELECT essence FROM spelldraft_talent_essence WHERE guid = " .. guid)
        if not chargedQ or chargedQ:GetUInt32(0) ~= essenceBefore - cost then
            RestoreSnapshot()
            RejectSingleTalentRefund(player, token, "essence_commit")
            return
        end
    end

    for _, rankSpellId in ipairs(chainInfo.ranks) do
        CharDBQuery(string.format(
            "DELETE FROM manually_acquired_talents WHERE player_guid = %d AND spell_id = %d",
            guid, rankSpellId))
    end
    -- When targetRank reaches the drafted floor, the manual row disappears;
    -- the drafted row remains and is restored by RebuildCustomTalentRuntime.
    if targetRank > draftedFloor then
        CharDBQuery(string.format(
            "INSERT IGNORE INTO manually_acquired_talents (player_guid, spell_id) VALUES (%d, %d)",
            guid, chainInfo.ranks[targetRank]))
    end

    -- ResetTalents only guarantees cleanup of native PlayerTalent state.  A
    -- spell-backed custom talent (notably Divine Intellect) can remain in
    -- m_spells when refunding rank 1 -> 0, because there is no lower manual
    -- rank for ApplyManualTalentRank to install and clean up around.  Remove
    -- the entire runtime chain first; the authoritative manual/drafted rows
    -- below then rebuild exactly the rank that must remain.
    SpellDraft_SetSystemLearning(guid, true)
    for _, rankSpellId in ipairs(chainInfo.ranks) do
        player:RemoveAura(rankSpellId)
        if player:HasSpell(rankSpellId) then player:RemoveSpell(rankSpellId) end
        CharDBQuery(string.format(
            "DELETE FROM character_spell WHERE guid = %d AND spell = %d",
            guid, rankSpellId))
    end
    SpellDraft_SetSystemLearning(guid, false)

    RebuildCustomTalentRuntime(player)
    local expectedStoredRank = targetRank > draftedFloor and targetRank or 0
    local storedRank = GetStoredTalentRank(guid, chainInfo)
    local liveApplied = true
    if targetRank > 0 then
        local targetSpellId = chainInfo.ranks[targetRank]
        if IsSpellBackedCustomTalent(chainInfo) then
            -- LearnCustomTalentSpell's contract is a known, persisted rank.
            -- Aura application is best-effort because several legitimate
            -- WotLK passive/proc talents do not expose their state through
            -- Player:HasAura even though the learned spell is authoritative.
            -- Requiring HasAura here made Impurity 5 -> 4 roll back to 5 while
            -- the client had already moved to 0/5.
            liveApplied = player:HasSpell(targetSpellId)
        else
            liveApplied = player:HasTalent(targetSpellId, player:GetActiveSpec())
        end
    else
        for _, rankSpellId in ipairs(chainInfo.ranks) do
            if player:HasSpell(rankSpellId) or player:HasTalent(rankSpellId, player:GetActiveSpec()) then
                liveApplied = false
                break
            end
        end
    end
    if storedRank ~= expectedStoredRank or not liveApplied then
        RestoreSnapshot()
        RejectSingleTalentRefund(player, token, "apply")
        return
    end

    CharDBQuery(string.format(
        "UPDATE prestige_stats SET talent_points = talent_points + 1 WHERE player_id = %d",
        guid))
    local afterPointsQ = CharDBQuery("SELECT talent_points FROM prestige_stats WHERE player_id = " .. guid)
    if not afterPointsQ or afterPointsQ:GetUInt32(0) ~= pointsBefore + 1 then
        RestoreSnapshot()
        RejectSingleTalentRefund(player, token, "points_commit")
        return
    end

    SyncDraftStats(player)
    SyncDraftedTalents(player)
    SendTalentEconomyState(player)
    -- Explicit changed-key projection: targetRank may be zero, which cannot be
    -- represented by the owned-only snapshot/delta list.
    player:SendAddonMessage("SCTRank",
        tostring(chainInfo.ranks[1]) .. "=" .. tostring(targetRank), 0, player)
    player:SendAddonMessage("SCTRefund", tostring(token or "0") .. ":ok:" .. tostring(targetRank) .. ":" .. tostring(cost), 0, player)
    player:SendBroadcastMessage(string.format(
        "|cff00ff00Refunded one rank of %s. Talent rank %d, +1 Talent Point, -%d Essence.|r",
        GetSpellNameSafe(chainInfo.ranks[1]), targetRank, cost))
end

function ResetCustomTalents(player)
    local guid = player:GetGUIDLow()
    local q = CharDBQuery("SELECT spell_id FROM manually_acquired_talents WHERE player_guid = " .. guid)
    local manual_spells = {}

    if q then
        repeat
            table.insert(manual_spells, q:GetUInt32(0))
        until not q:NextRow()
    end
    
    -- Disable anti-cheat while we modify spells
    if type(SpellDraft_SetSystemLearning) == "function" then
        SpellDraft_SetSystemLearning(guid, true)
    end

    -- Clear native talent state FIRST: ResetTalents can strip known talent spells,
    -- so it must run before any drafted ranks are restored below.
    player:ResetTalents(true)
    player:SetFreeTalentPoints(0)

    -- Safely calculate refund points by grouping by talent chain, finding the max manually purchased rank
    local talentMaxPurchased = {}
    for _, spellId in ipairs(manual_spells) do
        local chainInfo = talentChains[spellId]
        if chainInfo then
            local talentId = chainInfo.talentId
            local rankIndex = chainInfo.rankIndex
            talentMaxPurchased[talentId] = math.max(talentMaxPurchased[talentId] or 0, rankIndex)
        end
    end

    local refund_points = 0
    for talentId, R_purchased in pairs(talentMaxPurchased) do
        -- Find if player drafted a rank in this chain
        local chain = talentIdToChain[talentId]
        local R_drafted = 0
        if chain then
            for rankIndex, rSpellId in ipairs(chain.ranks) do
                local qD = CharDBQuery(string.format("SELECT 1 FROM drafted_spells WHERE player_guid = %d AND spell_id = %d", guid, rSpellId))
                if qD then
                    R_drafted = rankIndex
                end
            end
        end

        local spent = R_purchased - R_drafted
        if spent > 0 then
            refund_points = refund_points + spent
        end
    end

    -- Remove ALL ranks of the manually acquired talent chains from the player's spellbook
    for _, spellId in ipairs(manual_spells) do
        local chainInfo = talentChains[spellId]
        if chainInfo then
            for _, rSpellId in ipairs(chainInfo.ranks) do
                SpellDraft_SetSystemLearning(guid, true)
                player:RemoveAura(rSpellId)
                player:RemoveSpell(rSpellId)
                SpellDraft_SetSystemLearning(guid, false)
                CharDBExecute(string.format("DELETE FROM character_spell WHERE guid = %d AND spell = %d", guid, rSpellId))
            end
        else
            SpellDraft_SetSystemLearning(guid, true)
            player:RemoveAura(spellId)
            player:RemoveSpell(spellId)
            SpellDraft_SetSystemLearning(guid, false)
            CharDBExecute(string.format("DELETE FROM character_spell WHERE guid = %d AND spell = %d", guid, spellId))
        end
    end

    -- Wipe manual talents table
    CharDBQuery("DELETE FROM manually_acquired_talents WHERE player_guid = " .. guid)
    SyncCustomTalentRuntime(player, {})

    -- Update talent points in DB (synchronous so the sync below reads fresh)
    CharDBQuery("UPDATE prestige_stats SET talent_points = talent_points + " .. refund_points .. " WHERE player_id = " .. guid)

    -- Restore every drafted spell the player is missing (drafted ranks that were
    -- superseded by purchases, plus anything ResetTalents stripped). Mirrors the
    -- on-login self-heal so draft rewards always survive the reset.
    local qDrafted = CharDBQuery("SELECT spell_id FROM drafted_spells WHERE player_guid = " .. guid)
    if qDrafted then
        repeat
            local draftedSpellId = qDrafted:GetUInt32(0)
            if not IsDraftSpellApplied(player, draftedSpellId) then
                SpellDraft_SetSystemLearning(guid, true)
                ApplyAuthorizedDraftSpell(player, draftedSpellId)
                SpellDraft_SetSystemLearning(guid, false)
            end
        until not qDrafted:NextRow()
    end

    -- Enable anti-cheat back
    if type(SpellDraft_SetSystemLearning) == "function" then
        SpellDraft_SetSystemLearning(guid, false)
    end
    
    -- Sync
    SyncDraftStats(player)
    SyncDraftedTalents(player)
    
    return refund_points
end

function SyncDraftStats(player)
    if not player then return end
    local guid = player:GetGUIDLow()
    local result = CharDBQuery("SELECT draft_state, rerolls, bans, total_expected_drafts, successful_drafts, talent_points, prestige_tokens, prestige_level FROM prestige_stats WHERE player_id = " .. guid)
    if result then
        local draftState = result:GetUInt32(0)
        local rerolls = result:GetUInt32(1)
        local bans = result:GetUInt32(2)
        local totalExpected = result:GetUInt32(3)
        local successful = result:GetUInt32(4)
        local points = result:GetUInt32(5)
        local tokens = result:GetUInt32(6)
        local prestigeLevel = result:GetUInt32(7)
        
        local status = (draftState == 1) and "prestiged" or "not_prestiged"
        local totalDrafts = math.max(0, totalExpected - successful)
        
        player:SendAddonMessage("SpellChoiceStatus", status, 0, player)
        player:SendAddonMessage("SpellChoiceRerolls", tostring(rerolls), 0, player)
        player:SendAddonMessage("SpellChoiceBansLeft", tostring(bans), 0, player)
        player:SendAddonMessage("SpellChoiceDrafts", tostring(totalDrafts), 0, player)
        player:SendAddonMessage("SCTPoints", tostring(points), 0, player)
        player:SendAddonMessage("SpellChoicePrestigeTokens", tostring(tokens), 0, player)
        player:SendAddonMessage("SpellChoicePrestigeLevel", tostring(prestigeLevel), 0, player)
        -- Talent Essence is a persistent SpellCraft resource, not merely a
        -- value needed while a Tome card window happens to be open.
        SendTalentEconomyState(player)
    else
        player:SendAddonMessage("SpellChoiceStatus", "not_prestiged", 0, player)
        player:SendAddonMessage("SpellChoiceRerolls", "0", 0, player)
        player:SendAddonMessage("SpellChoiceBansLeft", "0", 0, player)
        player:SendAddonMessage("SpellChoiceDrafts", "0", 0, player)
        player:SendAddonMessage("SCTPoints", "0", 0, player)
        player:SendAddonMessage("SpellChoicePrestigeTokens", "0", 0, player)
        player:SendAddonMessage("SpellChoicePrestigeLevel", "0", 0, player)
        player:SendAddonMessage("SpellChoiceTalentEssence", "0", 0, player)
    end
end
