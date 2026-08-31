local scriptPath = debug.getinfo(1).source:sub(2)
local parentPath = scriptPath:match("(.+[/\\])") or ""
local rootPath = parentPath:match("(.+[/\\])[^/\\]+[/\\]$") or parentPath
dofile(rootPath .. "spelldraft_config.lua")

-- Playerbots must never enter the draft/prestige system.
-- IsBot() requires mod-ale with playerbots support; fall back to "not a bot" if absent.
local function IsBotPlayer(player)
    return player.IsBot ~= nil and player:IsBot()
end

local function IsRandomDraftMode(player)
    if type(SpellDraft_IsRandomMode) == "function" then
        return SpellDraft_IsRandomMode(player)
    end
    return true -- Backward-compatible fallback if the authority layer is absent.
end

local function IsPrestigeProgressionMode(player)
    if IsRandomDraftMode(player) then return true end
    if type(SpellDraft_IsFreePickMode) == "function" and SpellDraft_IsFreePickMode(player) then
        return true
    end
    if type(SpellDraft_IsClassicMode) == "function" and SpellDraft_IsClassicMode(player) then
        return CONFIG.PRESTIGE_ALLOW_CLASSIC == true
    end
    return false
end

local DUPLICATE_RACIAL_GROUPS = {
    -- Gift of the Naaru (Draenei)
    [59547] = { 28880, 59542, 59543, 59544, 59545, 59547, 59548 },
    -- Arcane Torrent (Blood Elf)
    [28730] = { 28730, 25046, 50613 }
}

local STARTER_TOME_ITEM_ID = 25462

-- A.30: The starter Tome must be tied to Random Draft mode, not to a race
-- whitelist or to whether prestige_stats happened to exist first.  The mode
-- picker can create prestige_stats before this login handler runs, which made
-- the old "new prestige row only" grant silently skip custom races.
--
-- This durable receipt also prevents relogging, consuming or selling the Tome
-- from granting another copy.  If the inventory is full, no receipt is written
-- and the next login safely retries.
CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `spelldraft_starter_tome_grant` (
        `guid` INT UNSIGNED NOT NULL,
        `item_id` INT UNSIGNED NOT NULL DEFAULT 25462,
        `granted_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`guid`),
        CONSTRAINT `fk_spelldraft_starter_tome_character`
            FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

local function SendStarterTomeMessage(player, bagFull)
    local language = "enUS"
    if type(SpellDraft_GetPlayerLanguage) == "function" then
        language = SpellDraft_GetPlayerLanguage(player)
    elseif player.GetDbLocaleIndex ~= nil then
        local locale = player:GetDbLocaleIndex()
        if locale == 4 or locale == 5 then language = "zhCN" end
    end

    if bagFull then
        if language == "zhCN" then
            player:SendBroadcastMessage("|cffff4444背包空间不足，天赋之书尚未发放。清出一个空格后重新登录即可自动补发。|r")
        else
            player:SendBroadcastMessage("|cffff4444Your bags are full. Free one slot and log in again to receive the Tome of Talents.|r")
        end
        return
    end

    if language == "zhCN" then
        player:SendBroadcastMessage("你获得了 |cff00ccff天赋之书|r！保存至10级后使用，可从三项珍贵特殊天赋中选择一项。")
    else
        player:SendBroadcastMessage("You have been granted a |cff00ccffTome of Talents|r! Save it until level 10, then choose one of three rare special talents.")
    end
end

local function EnsureStarterTomeGrant(player)
    if not player or not player:IsInWorld() or IsBotPlayer(player) then return end
    if not IsRandomDraftMode(player) then return end

    local guid = player:GetGUIDLow()
    local receipt = CharDBQuery("SELECT 1 FROM spelldraft_starter_tome_grant WHERE guid = " .. guid .. " LIMIT 1")
    if receipt then return end

    -- Characters already holding a Tome are legacy successful grants.  Record
    -- the receipt without adding a duplicate; include bank storage in the check.
    if player:HasItem(STARTER_TOME_ITEM_ID, 1, true) then
        CharDBQuery(string.format(
            "INSERT IGNORE INTO spelldraft_starter_tome_grant (guid, item_id) VALUES (%d, %d)",
            guid, STARTER_TOME_ITEM_ID))
        return
    end

    local item = player:AddItem(STARTER_TOME_ITEM_ID, 1)
    if not item then
        SendStarterTomeMessage(player, true)
        return
    end

    -- Write the receipt immediately after AddItem succeeds.  From this point on
    -- consuming or deleting the book never makes the character eligible again.
    CharDBQuery(string.format(
        "INSERT IGNORE INTO spelldraft_starter_tome_grant (guid, item_id) VALUES (%d, %d)",
        guid, STARTER_TOME_ITEM_ID))
    SendStarterTomeMessage(player, false)
end

local function ScheduleStarterTomeGrant(player)
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if p and p:IsInWorld() then
            EnsureStarterTomeGrant(p)
        end
    end, 2500, 1)
end

local draftStateCache = {}

function SpellDraft_SetDraftStateCache(guid, state)
    draftStateCache[guid] = (state == 1 or state == true)
end

local function HasAnySpell(player, spellIds)
    for _, id in ipairs(spellIds) do
        if player:HasSpell(id) then
            return true
        end
    end
    return false
end


-- Configurable Chromie location messages
local CHROMIE_LOCATION_HORDE = CONFIG.CHROMIE_LOCATION_HORDE
local CHROMIE_LOCATION_ALLIANCE = CONFIG.CHROMIE_LOCATION_ALLIANCE
-- Check if the player is in draft state
local function IsPlayerInDraft(player)
    if not IsRandomDraftMode(player) then return false end
    local guid = player:GetGUIDLow()
    if draftStateCache[guid] ~= nil then
        return draftStateCache[guid]
    end

    local query = CharDBQuery("SELECT draft_state FROM prestige_stats WHERE player_id = " .. guid)
    local inDraft = (query and query:GetUInt32(0) == 1) or false
    draftStateCache[guid] = inDraft
    return inDraft
end

-- Apply custom power values
local function ApplyDraftPowerTypes(player)
    if not player or not player:IsInWorld() then return end

    -- B0.9: allocate only resources required by this character's drafted
    -- spells. Classic mode never reaches this function, and the compatibility
    -- registry also fails closed outside Random Draft / Free Pick.
    if type(SpellDraft_SyncResourceCompatibility) == "function" then
        SpellDraft_SyncResourceCompatibility(player, "core")
    else
        -- Safe compatibility fallback for servers that have not installed the
        -- registry file yet. Do not reintroduce universal Runic Power here.
        player:SetMaxPower(1, 1000)
        player:SetMaxPower(3, 100)
    end
end

-- Track ticking players
local draftTickerGUIDs = {}

local function StartDraftPowerTicker(player)
    local guid = player:GetGUIDLow()
    if draftTickerGUIDs[guid] then return end  -- Already ticking

    local eventId = CreateLuaEvent(function()
        local p = GetPlayerByGUID(guid)
        if not p or not p:IsInWorld() then
            RemoveEventById(draftTickerGUIDs[guid])
            draftTickerGUIDs[guid] = nil
            return
        end

        local preferred = type(SpellDraft_GetPreferredPowerType) == "function"
            and SpellDraft_GetPreferredPowerType(p) or nil
        if preferred ~= nil and p:GetPowerType() ~= preferred then
            p:SetPowerType(preferred)
        end
    end, 2000, 0)

    draftTickerGUIDs[guid] = eventId
end



-- On login: ensure DB row, give title, maybe start ticker
local function GetStoredClass(player)
    local guid = player:GetGUIDLow()
    local result = CharDBQuery("SELECT stored_class FROM prestige_stats WHERE player_id = " .. guid)
    if result then
        return result:GetUInt8(0)
    end
    return nil
end

-- On login: ensure DB row, give title, maybe start ticker
local function EnsurePrestigeEntry(_, player)
    if IsBotPlayer(player) then return end
    if not IsRandomDraftMode(player) then
        draftStateCache[player:GetGUIDLow()] = false
        return
    end
    CONFIG.EnsurePlayerLanguage(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT prestige_level, draft_state FROM prestige_stats WHERE player_id = " .. guid)

    if query then
        local prestigeLevel = query:GetUInt32(0)
        local draftState = query:GetUInt32(1)
        draftStateCache[guid] = (draftState == 1)
        
    if player then
        local titleId = CONFIG.PrestigeTitles[prestigeLevel]
        if titleId and not player:HasTitle(titleId) then
            player:SetKnownTitle(titleId)
        end
        if prestigeLevel >= 1 then
            player:SendBroadcastMessage("|cff00ff00[Prestige]|r Permanent 50% Experience Bonus is active!")
        end
    end
        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if not p then return end

            -- Sync draft title 535
            local hasTitle = p:HasTitle(535)
            if draftState == 1 then
                if not hasTitle then
                    p:SetKnownTitle(535)
                end
                ApplyDraftPowerTypes(p)
                StartDraftPowerTicker(p)

                -- Bypass the draft anti-cheat while the module itself teaches spells,
                -- or every grant below gets blocked and removed again.
                if type(SpellDraft_SetSystemLearning) == "function" then
                    SpellDraft_SetSystemLearning(guid, true)
                end

                -- Ensure all armor and weapon proficiencies
                local proficiencies = {
                    9078, 9077, 8737, 750,           -- Cloth, Leather, Mail, Plate
                    196, 197, 198, 199, 201, 202,    -- Axes, Maces, Swords (1H+2H)
                    227, 1180, 200, 15590,           -- Staves, Daggers, Polearms, Fists
                    264, 5011, 266, 2567, 5009, 107, -- Bows, Xbows, Guns, Thrown, Wands, Block
                    75, 5019, 2764,                  -- Auto Shot, Shoot, Throw
                }
                for _, sid in ipairs(proficiencies) do
                    if not p:HasSpell(sid) then
                        p:LearnSpell(sid)
                    end
                end

                -- Ensure all racial active and passive abilities
                local race = p:GetRace()
                local racialSpells = {
                    [1]  = { 59752, 20598, 20599, 20597, 20864 }, -- Human: Every Man for Himself, The Human Spirit, Diplomacy, Sword Spec, Mace Spec
                    [2]  = { 20572, 20573, 20575, 20574 },         -- Orc: Blood Fury, Hardiness, Command, Axe Spec
                    [3]  = { 20594, 20596, 20595, 2481, 59224 },   -- Dwarf: Stoneform, Frost Resistance, Gun Spec, Find Treasure, Mace Spec
                    [4]  = { 58984, 20582, 20585, 20583 },         -- Night Elf: Shadowmeld, Quickness, Wisp Spirit, Nature Resistance
                    [5]  = { 7744, 20577, 5227, 20579 },           -- Undead: Will of the Forsaken, Cannibalize, Underwater Breathing, Shadow Resistance
                    [6]  = { 20549, 20550, 20552, 20551 },         -- Tauren: War Stomp, Endurance, Cultivation, Nature Resistance
                    [7]  = { 20589, 20591, 20593, 20592 },         -- Gnome: Escape Artist, Expansive Mind, Engineering Spec, Arcane Resistance
                    [8]  = { 26297, 20555, 20557, 20558, 26290, 58943 }, -- Troll: Berserking, Regeneration, Beast Slaying, Bow Spec, Throwing Spec, Da Voodoo Shuffle
                    [10] = { 28730, 20554, 822 },                  -- Blood Elf: Arcane Torrent, Arcane Affinity, Magic Resistance
                    [11] = { 59547, 28878, 28875, 28877 },         -- Draenei: Gift of the Naaru, Heroic Presence, Gemcutting, Shadow Resistance
                    [16] = { 97710 },                              -- Custom Worgen: Two Forms / human-form toggle
                }
                local list = racialSpells[race]
                if list then
                    for _, spellId in ipairs(list) do
                        local hasSpell = false
                        if DUPLICATE_RACIAL_GROUPS[spellId] then
                            hasSpell = HasAnySpell(p, DUPLICATE_RACIAL_GROUPS[spellId])
                        else
                            hasSpell = p:HasSpell(spellId)
                        end
                        if not hasSpell then
                            p:LearnSpell(spellId)
                        end
                    end
                end

                -- Ensure starting class spells for their stored class
                local STARTING_CLASS_SPELLS = {
                    [1]  = { 78, 2457 },             -- Warrior: Heroic Strike, Battle Stance
                    [2]  = { 21084, 635 },           -- Paladin: Seal of Righteousness, Holy Light
                    [3]  = { 2973, 75 },            -- Hunter: Raptor Strike, Auto Shot
                    [4]  = { 1752 },                 -- Rogue: Sinister Strike
                    [5]  = { 585, 2050 },            -- Priest: Smite, Lesser Heal
                    [7]  = { 403, 331 },             -- Shaman: Lightning Bolt, Healing Wave
                    [8]  = { 133, 168 },             -- Mage: Fireball, Frost Armor
                    [9]  = { 686, 688 },             -- Warlock: Shadow Bolt, Summon Imp
                    [11] = { 5176, 5185 },           -- Druid: Wrath, Healing Touch
                }
                local storedClass = GetStoredClass(p)
                print(string.format("[EnsurePrestigeEntry] Player: %s (%d), StoredClass: %s", p:GetName(), guid, tostring(storedClass)))
                local classSpells = storedClass and STARTING_CLASS_SPELLS[storedClass]
                if classSpells then
                    for _, sid in ipairs(classSpells) do
                        print(string.format("[EnsurePrestigeEntry] Teaching starting spell: %d to %s", sid, p:GetName()))
                        if not p:HasSpell(sid) then
                            p:LearnSpell(sid)
                        end
                    end
                end

                if type(SpellDraft_SetSystemLearning) == "function" then
                    SpellDraft_SetSystemLearning(guid, false)
                end
            elseif hasTitle then
                p:UnsetKnownTitle(535)
            end
        end, 3000, 1)

    else
        local class = player:GetClass()
        -- A.22.8 converts eligible Random Draft DKs to level 1 before this
        -- first Draft login. Only an old, unconverted level-55 DK keeps the
        -- legacy 5-card/54-talent bootstrap; a level-1 DK starts like everyone.
        local legacyHeroDk = (class == 6 and player:GetLevel() > 1)
        local startingDrafts = legacyHeroDk and 5 or CONFIG.DRAFT_MODE_SPELLS
        local startingPoints = legacyHeroDk and 54 or 0
        -- Start drafting immediately on first login!
        -- Synchronous write: spell_choice.lua's delayed first-login retry (and any
        -- early SC_CHECK / zone change) must be able to read this row right away.
        CharDBQuery(string.format([[
            INSERT INTO prestige_stats
            (player_id, prestige_level, draft_state, stored_class, total_expected_drafts, rerolls, bans, talent_points)
            VALUES (%d, 0, 1, %d, %d, %d, %d, %d)
        ]], guid, class, startingDrafts, CONFIG.DRAFT_MODE_REROLLS, CONFIG.DRAFT_BANS_START, startingPoints))

        -- Custom Mage Race starting gear injection
        if class == 8 then
            local race = player:GetRace()
            if race == 2 or race == 4 or race == 6 then
                player:AddItem(45, 1)    -- Squire's Shirt
                player:AddItem(39, 1)    -- Recruit's Pants
                player:AddItem(55, 1)    -- Apprentice's Boots
                player:AddItem(35, 1)    -- Bent Staff
                player:AddItem(159, 5)   -- Refreshing Spring Water
                
                player:EquipItem(45, 3)
                player:EquipItem(39, 6)
                player:EquipItem(55, 7)
                player:EquipItem(35, 15)
            end
        end

        draftStateCache[guid] = true

        CreateLuaEvent(function()
            local p = GetPlayerByGUID(guid)
            if not p or not p:IsInWorld() then return end

            -- Remove default starting class spells so player starts classless (excluding any spells already drafted during the login race window)
            local spellsQ = CharDBQuery("SELECT spell FROM character_spell WHERE guid = " .. guid .. " AND spell NOT IN (SELECT spell_id FROM drafted_spells WHERE player_guid = " .. guid .. ")")
            if spellsQ then
                local spellsToRemove = {}
                repeat
                    local spellId = spellsQ:GetUInt32(0)
                    local spellCheck = WorldDBQuery("SELECT ClassMask FROM skilllineability_dbc WHERE Spell = " .. spellId)
                    if spellCheck and spellCheck:GetUInt32(0) > 0 then
                        table.insert(spellsToRemove, spellId)
                    end
                until not spellsQ:NextRow()

                for _, spellId in ipairs(spellsToRemove) do
                    p:RemoveSpell(spellId)
                end
            end

            -- Bypass the draft anti-cheat while the module itself teaches spells,
            -- or every grant below gets blocked and removed again.
            if type(SpellDraft_SetSystemLearning) == "function" then
                SpellDraft_SetSystemLearning(guid, true)
            end

            -- Grant all armor and weapon proficiencies
            local proficiencies = {
                -- Armor
                9078,   -- Cloth
                9077,   -- Leather
                8737,   -- Mail
                750,    -- Plate Mail
                -- Weapons
                196,    -- One-Handed Axes
                197,    -- Two-Handed Axes
                198,    -- One-Handed Maces
                199,    -- Two-Handed Maces
                201,    -- One-Handed Swords
                202,    -- Two-Handed Swords
                227,    -- Staves
                1180,   -- Daggers
                200,    -- Polearms
                15590,  -- Fist Weapons
                264,    -- Bows
                5011,   -- Crossbows
                266,    -- Guns
                2567,   -- Thrown
                5009,   -- Wands
                107,    -- Block (Shield use)
                75,     -- Auto Shot
                5019,   -- Shoot
                2764,   -- Throw
            }
            for _, spellId in ipairs(proficiencies) do
                if not p:HasSpell(spellId) then
                    p:LearnSpell(spellId)
                end
            end

            -- Ensure all racial active and passive abilities
            local race = p:GetRace()
            local racialSpells = {
                [1]  = { 59752, 20598, 20599, 20597, 20864 }, -- Human: Every Man for Himself, The Human Spirit, Diplomacy, Sword Spec, Mace Spec
                [2]  = { 20572, 20573, 20575, 20574 },         -- Orc: Blood Fury, Hardiness, Command, Axe Spec
                [3]  = { 20594, 20596, 20595, 2481, 59224 },   -- Dwarf: Stoneform, Frost Resistance, Gun Spec, Find Treasure, Mace Spec
                [4]  = { 58984, 20582, 20585, 20583 },         -- Night Elf: Shadowmeld, Quickness, Wisp Spirit, Nature Resistance
                [5]  = { 7744, 20577, 5227, 20579 },           -- Undead: Will of the Forsaken, Cannibalize, Underwater Breathing, Shadow Resistance
                [6]  = { 20549, 20550, 20552, 20551 },         -- Tauren: War Stomp, Endurance, Cultivation, Nature Resistance
                [7]  = { 20589, 20591, 20593, 20592 },         -- Gnome: Escape Artist, Expansive Mind, Engineering Spec, Arcane Resistance
                [8]  = { 26297, 20555, 20557, 20558, 26290, 58943 }, -- Troll: Berserking, Regeneration, Beast Slaying, Bow Spec, Throwing Spec, Da Voodoo Shuffle
                [10] = { 28730, 20554, 822 },                  -- Blood Elf: Arcane Torrent, Arcane Affinity, Magic Resistance
                [11] = { 59547, 28878, 28875, 28877 },         -- Draenei: Gift of the Naaru, Heroic Presence, Gemcutting, Shadow Resistance
                [16] = { 97710 },                              -- Custom Worgen: Two Forms / human-form toggle
            }
            local list = racialSpells[race]
            if list then
                for _, spellId in ipairs(list) do
                    local hasSpell = false
                    if DUPLICATE_RACIAL_GROUPS[spellId] then
                        hasSpell = HasAnySpell(p, DUPLICATE_RACIAL_GROUPS[spellId])
                    else
                        hasSpell = p:HasSpell(spellId)
                    end
                    if not hasSpell then
                        p:LearnSpell(spellId)
                    end
                end
            end

            if type(SpellDraft_SetSystemLearning) == "function" then
                SpellDraft_SetSystemLearning(guid, false)
            end

            -- Sync resource states
            ApplyDraftPowerTypes(p)
            StartDraftPowerTicker(p)

        end, 2000, 1)
    end

    -- Run for every Random Draft login path, including characters whose
    -- prestige_stats row was created early by the mode-selection handshake.
    ScheduleStarterTomeGrant(player)
end

-- A.31: one public runtime entry for both normal login and in-world mode
-- selection.  The legacy worker above remains the single implementation of
-- prestige-row creation, class-spell cleanup, proficiencies, racials, powers,
-- ticker startup and the durable starter-tome grant.
local draftRuntimeRuns = {}
local draftRuntimeReady = {}

function SpellDraft_IsDraftRuntimeReady(playerOrGuid)
    local guid = type(playerOrGuid) == "number" and playerOrGuid
        or (playerOrGuid and playerOrGuid:GetGUIDLow())
    return guid and draftRuntimeReady[guid] == true or false
end

local function FinishDraftRuntime(guid, ok, result)
    draftRuntimeReady[guid] = ok == true
    local callbacks = draftRuntimeRuns[guid]
    draftRuntimeRuns[guid] = nil
    if not callbacks then return end
    for _, callback in ipairs(callbacks) do
        if type(callback) == "function" then
            local callbackOk, callbackError = pcall(callback, ok, result)
            if not callbackOk then
                print("[SpellDraft/A.31] Runtime callback failed for " .. guid .. ": " .. tostring(callbackError))
            end
        end
    end
end

function SpellDraft_EnsureDraftRuntime(player, options, callback)
    if not player or not player:IsInWorld() or IsBotPlayer(player) then
        if type(callback) == "function" then callback(false, "invalid_player") end
        return false
    end
    if not IsRandomDraftMode(player) then
        draftStateCache[player:GetGUIDLow()] = false
        if type(callback) == "function" then callback(false, "not_random_draft") end
        return false
    end

    local guid = player:GetGUIDLow()
    if draftRuntimeRuns[guid] then
        if type(callback) == "function" then table.insert(draftRuntimeRuns[guid], callback) end
        return true
    end
    draftRuntimeRuns[guid] = {}
    draftRuntimeReady[guid] = false
    if type(callback) == "function" then table.insert(draftRuntimeRuns[guid], callback) end

    local ok, runtimeError = pcall(EnsurePrestigeEntry, nil, player)
    if not ok then
        if type(SpellDraft_SetSystemLearning) == "function" then
            SpellDraft_SetSystemLearning(guid, false)
        end
        print("[SpellDraft/A.31] Runtime start failed for " .. guid .. ": " .. tostring(runtimeError))
        FinishDraftRuntime(guid, false, "runtime_start_failed")
        return false
    end

    -- The existing worker intentionally performs Player-object changes after
    -- 2-3 seconds.  Verify its authoritative DB state only after that work has
    -- settled; all concurrent callers share this one completion point.
    CreateLuaEvent(function()
        local current = GetPlayerByGUID(guid)
        if type(SpellDraft_SetSystemLearning) == "function" then
            SpellDraft_SetSystemLearning(guid, false)
        end
        if not current or not current:IsInWorld() then
            FinishDraftRuntime(guid, false, "player_left_world")
            return
        end
        local state = CharDBQuery(
            "SELECT draft_state FROM prestige_stats WHERE player_id = " .. guid .. " LIMIT 1")
        if not state or state:GetUInt32(0) ~= 1 then
            FinishDraftRuntime(guid, false, "runtime_state_missing")
            return
        end
        draftStateCache[guid] = true
        FinishDraftRuntime(guid, true, "draft")
    end, 3400, 1)
    return true
end

local function OnDraftRuntimeLogin(_, player)
    SpellDraft_EnsureDraftRuntime(player, { source = "login" })
end


-- Apply draft state if needed
local function OnRebuildEvent(_, player)
    if IsBotPlayer(player) then return end
    if IsPlayerInDraft(player) then
        ApplyDraftPowerTypes(player)
        StartDraftPowerTicker(player)
    end
end
local function OnPlayerLogout(_, player)
    local guid = player:GetGUIDLow()
    if draftTickerGUIDs[guid] then
        RemoveEventById(draftTickerGUIDs[guid])
        draftTickerGUIDs[guid] = nil
    end


    draftStateCache[guid] = nil
    draftRuntimeReady[guid] = nil
end

local function OnLevelUp(event, player, oldLevel)
    if IsBotPlayer(player) then return end
    local newLevel = player:GetLevel()
    if newLevel == CONFIG.MAX_LEVEL and IsPrestigeProgressionMode(player) then
        local factionGroup = player:GetTeam()  -- 0 = Alliance, 1 = Horde
        local locationMsg = (factionGroup == 1) and CHROMIE_LOCATION_HORDE or CHROMIE_LOCATION_ALLIANCE

        local fullMessage = "|cffffcc00You have reached level " .. CONFIG.MAX_LEVEL .. "!|r You can now access |cffff8800Prestige|r and |cff00ccffPrestige Draft Mode|r. " .. locationMsg
        player:SendAreaTriggerMessage(fullMessage)
    end

    -- Custom Talent Points progression
    if IsPlayerInDraft(player) then
        local diff = newLevel - oldLevel
        if diff > 0 then
            local guid = player:GetGUIDLow()
            -- Synchronous write so the SyncTalentPoints read below can't race it
            CharDBQuery("UPDATE prestige_stats SET talent_points = talent_points + " .. diff .. " WHERE player_id = " .. guid)
            if type(SyncDraftStats) == "function" then
                SyncDraftStats(player)
            end
        end
    end
end

local function OnGiveXP(event, player, amount, victim)
    if IsBotPlayer(player) then return end
    local guid = player:GetGUIDLow()
    local q = CharDBQuery("SELECT prestige_level FROM prestige_stats WHERE player_id = " .. guid)
    if q then
        local prestigeLevel = q:GetUInt32(0)
        if prestigeLevel >= 1 then
            return math.floor(amount * 1.5)
        end
    end
end

-- Register only valid events
RegisterPlayerEvent(4, OnPlayerLogout)
RegisterPlayerEvent(13, OnLevelUp)  -- 13 = PLAYER_EVENT_ON_LEVEL_CHANGE
RegisterPlayerEvent(3, OnDraftRuntimeLogin)   -- On login and shared hot runtime
RegisterPlayerEvent(13, OnRebuildEvent)       -- On level change
RegisterPlayerEvent(28, OnRebuildEvent)       -- On map change
RegisterPlayerEvent(35, OnRebuildEvent)       -- On repop
RegisterPlayerEvent(36, OnRebuildEvent)       -- On resurrect
RegisterPlayerEvent(12, OnGiveXP)            -- PLAYER_EVENT_ON_GIVE_XP
