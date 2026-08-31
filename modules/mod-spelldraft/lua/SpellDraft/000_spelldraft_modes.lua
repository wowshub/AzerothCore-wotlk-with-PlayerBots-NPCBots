-- SpellDraft three-mode authority layer.
-- This file is prefixed with 000_ so it loads before the legacy SpellDraft files.

SPELLDRAFT_MODE = SPELLDRAFT_MODE or {
    PENDING = 0,
    CLASSIC = 1,
    RANDOM_DRAFT = 2,
    FREE_PICK = 3,
}

local MODE_NAME_TO_ID = {
    classic = SPELLDRAFT_MODE.CLASSIC,
    draft = SPELLDRAFT_MODE.RANDOM_DRAFT,
    free = SPELLDRAFT_MODE.FREE_PICK,
}

local MODE_ID_TO_NAME = {
    [SPELLDRAFT_MODE.PENDING] = "pending",
    [SPELLDRAFT_MODE.CLASSIC] = "classic",
    [SPELLDRAFT_MODE.RANDOM_DRAFT] = "draft",
    [SPELLDRAFT_MODE.FREE_PICK] = "free",
}

-- Free-pick needs its point spending panel before players may select it.
-- A.24 will change this to true after that server-authoritative path exists.
local MODE_ENABLED = {
    [SPELLDRAFT_MODE.CLASSIC] = true,
    [SPELLDRAFT_MODE.RANDOM_DRAFT] = true,
    [SPELLDRAFT_MODE.FREE_PICK] = false,
}

local modeCache = {}
local DEATH_KNIGHT_CLASS_ID = 6
local DK_BOOTSTRAP_VERSION = 1
local DK_ACHERUS_MAP_ID = 609
local DK_RELOCATION_DELAY_MS = 700
local DK_RELOCATION_VERIFY_MS = 750
local DK_RELOCATION_VERIFY_COUNT = 12

-- Stock WotLK creates a Death Knight at level 55 with Acherus equipment.
-- Random Draft DKs must lose only that hero-class bootstrap equipment; bags,
-- money, racial items and any unrelated custom items are deliberately kept.
-- Item list adapted from VenomekPL/mod-classic-deathknight (MIT).
local DK_ACHERUS_STARTER_ITEMS = {
    38145, 34652, 34655, 34659, 34650, 34653, 34649, 34651, 34656,
    34648, 34657, 34658, 38147, 41751, 40582, 34666, 34667,
}

local function IsBotPlayer(player)
    return player and player.IsBot ~= nil and player:IsBot()
end

-- Use synchronous DB calls here: the migration must finish before login events
-- can classify an old character as pending.
CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `spelldraft_character_mode` (
        `guid` INT UNSIGNED NOT NULL,
        `mode` TINYINT UNSIGNED NOT NULL,
        `locked` TINYINT UNSIGNED NOT NULL DEFAULT 1,
        `selected_level` TINYINT UNSIGNED NOT NULL DEFAULT 1,
        `selection_version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
        `free_skill_points` INT UNSIGNED NOT NULL DEFAULT 0,
        `free_talent_points` INT UNSIGNED NOT NULL DEFAULT 0,
        `selected_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`guid`),
        CONSTRAINT `fk_spelldraft_mode_character`
            FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

-- Only Death Knights created after A.22.7 receive an eligibility row. This is
-- deliberate: an old level-55/80 DK must never be mistaken for a disposable
-- fresh hero character and silently lose levels, quests, spells, or equipment.
CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `spelldraft_dk_bootstrap` (
        `guid` INT UNSIGNED NOT NULL,
        `race` TINYINT UNSIGNED NOT NULL,
        `team` TINYINT UNSIGNED NOT NULL COMMENT '0=Alliance,1=Horde',
        `created_level` TINYINT UNSIGNED NOT NULL,
        `eligible` TINYINT UNSIGNED NOT NULL DEFAULT 0,
        `state` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=pending,1=converting,2=converted,3=failed',
        `selected_zone` TINYINT UNSIGNED NULL DEFAULT NULL,
        `version` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `converted_at` TIMESTAMP NULL DEFAULT NULL,
        PRIMARY KEY (`guid`),
        CONSTRAINT `fk_spelldraft_dk_bootstrap_character`
            FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

-- Backward compatibility: every character already known by the old system keeps
-- its current behaviour and will never be interrupted by the first-login picker.
CharDBQuery([[
    INSERT IGNORE INTO `spelldraft_character_mode`
        (`guid`, `mode`, `locked`, `selected_level`, `selection_version`)
    SELECT `player_id`, IF(`draft_state` = 1, 2, 1), 1, 1, 1
      FROM `prestige_stats`;
]])

local function ResolveGuid(playerOrGuid)
    if type(playerOrGuid) == "number" then
        return math.floor(playerOrGuid)
    end
    if playerOrGuid and playerOrGuid.GetGUIDLow then
        return playerOrGuid:GetGUIDLow()
    end
    return nil
end

function SpellDraft_GetCharacterModeId(playerOrGuid)
    local guid = ResolveGuid(playerOrGuid)
    if not guid then return SPELLDRAFT_MODE.PENDING end
    if modeCache[guid] ~= nil then return modeCache[guid] end

    local query = CharDBQuery(
        "SELECT mode FROM spelldraft_character_mode WHERE guid = " .. guid .. " LIMIT 1"
    )
    local modeId = query and query:GetUInt8(0) or SPELLDRAFT_MODE.PENDING
    modeCache[guid] = modeId
    return modeId
end

function SpellDraft_GetCharacterModeName(playerOrGuid)
    return MODE_ID_TO_NAME[SpellDraft_GetCharacterModeId(playerOrGuid)] or "pending"
end

function SpellDraft_IsModeEnabled(modeNameOrId)
    local modeId = tonumber(modeNameOrId) or MODE_NAME_TO_ID[tostring(modeNameOrId or ""):lower()]
    return modeId ~= nil and MODE_ENABLED[modeId] == true
end

function SpellDraft_IsRandomMode(playerOrGuid)
    return SpellDraft_GetCharacterModeId(playerOrGuid) == SPELLDRAFT_MODE.RANDOM_DRAFT
end

function SpellDraft_IsClassicMode(playerOrGuid)
    return SpellDraft_GetCharacterModeId(playerOrGuid) == SPELLDRAFT_MODE.CLASSIC
end

function SpellDraft_IsFreePickMode(playerOrGuid)
    return SpellDraft_GetCharacterModeId(playerOrGuid) == SPELLDRAFT_MODE.FREE_PICK
end

local CORE_START_RACES = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
    [6] = true, [7] = true, [8] = true, [10] = true, [11] = true,
}

function SpellDraft_GetDkDefaultStart(player)
    if not player then return false end
    local raceId = tonumber(player:GetRace())
    local teamId = tonumber(player:GetTeam())
    if not raceId or (teamId ~= 0 and teamId ~= 1) then return nil end

    -- The ten original races keep their native level-one starting positions.
    -- Class 1 is used only as a reliable lookup row; no class change occurs.
    if CORE_START_RACES[raceId] then
        local native = WorldDBQuery(string.format([[
            SELECT map, zone, position_x, position_y, position_z, orientation
              FROM playercreateinfo
             WHERE race = %d AND class = 1
             LIMIT 1
        ]], raceId))
        if not native then return nil end
        return {
            slot = 0,
            map = native:GetUInt32(0), zone = native:GetUInt32(1),
            x = native:GetFloat(2), y = native:GetFloat(3),
            z = native:GetFloat(4), o = native:GetFloat(5),
        }
    end

    -- New races are explicitly mapped to their dedicated NPC 750002 button.
    local custom = WorldDBQuery(string.format([[
        SELECT z.slot, z.map_id, 0, z.position_x, z.position_y, z.position_z, z.orientation
          FROM spelldraft_race_start_route r
          JOIN spelldraft_starting_zone z ON z.team = r.team AND z.slot = r.slot
         WHERE r.race_id = %d AND r.enabled = 1 AND z.enabled = 1 AND r.team = %d
         LIMIT 1
    ]], raceId, teamId))
    if not custom then return nil end
    return {
        slot = custom:GetUInt32(0),
        map = custom:GetUInt32(1), zone = custom:GetUInt32(2),
        x = custom:GetFloat(3), y = custom:GetFloat(4),
        z = custom:GetFloat(5), o = custom:GetFloat(6),
    }
end

local function HasEnabledDkStartRoute(player)
    return SpellDraft_GetDkDefaultStart(player) ~= nil
end

function SpellDraft_GetDkBootstrapStatus(player)
    if not player or player:GetClass() ~= DEATH_KNIGHT_CLASS_ID then
        return "not_death_knight"
    end

    local query = CharDBQuery(
        "SELECT eligible, state, version FROM spelldraft_dk_bootstrap WHERE guid = "
            .. player:GetGUIDLow() .. " LIMIT 1"
    )
    if not query then return "legacy_character" end
    if query:GetUInt8(0) ~= 1 then return "start_route_unavailable" end
    if query:GetUInt8(1) == 2 then return "converted" end
    if query:GetUInt8(1) ~= 0 then return "bootstrap_busy" end
    if query:GetUInt16(2) ~= DK_BOOTSTRAP_VERSION then return "version_mismatch" end
    if not HasEnabledDkStartRoute(player) then return "start_route_unavailable" end
    return "eligible"
end

function SpellDraft_IsDkBootstrapConversionReady()
    return true
end

local function ConvertDeathKnightToLevelOneDraft(player)
    if SpellDraft_GetDkBootstrapStatus(player) ~= "eligible" then
        return false, "dk_not_eligible"
    end

    local start = SpellDraft_GetDkDefaultStart(player)
    if not start then return false, "start_route_unavailable" end

    local guid = player:GetGUIDLow()
    -- Synchronous: the C++ level-change hook immediately reads state=1 to
    -- install the hot-session DK scaling identity and racial starter outfit.
    CharDBQuery(string.format([[
        UPDATE `spelldraft_dk_bootstrap`
           SET `state` = 1, `selected_zone` = %d
         WHERE `guid` = %d AND `state` = 0
    ]], tonumber(start.slot) or 0, guid))

    local ok, errorMessage = pcall(function()
        -- ALE's SetLevel calls GiveLevel, rebuilds talents and resets XP to zero.
        player:SetLevel(1)
        player:ResetTalents(true)

        for _, itemId in ipairs(DK_ACHERUS_STARTER_ITEMS) do
            local count = player:GetItemCount(itemId)
            if count and count > 0 then player:RemoveItem(itemId, count) end
        end

        -- A.22.8.2: the compiled SpellDraft DK service now reads the same
        -- race/gender CharStartOutfit row used by character creation, grants
        -- the correct racial clothing and weapon, and equips them on login.
        -- Keeping fixed item IDs here would give every race the human outfit.

        -- Save the racial hearthstone destination now, but perform the actual
        -- far teleport after the next login. TeleportTo is asynchronous and
        -- stock core also blocks an Acherus DK without Death Gate (50977).
        player:SetBindPoint(start.x, start.y, start.z, start.map, start.zone or 0)
        player:SaveToDB()
    end)

    if not ok then
        CharDBExecute("UPDATE spelldraft_dk_bootstrap SET state = 3 WHERE guid = " .. guid)
        print("[SpellDraft/DK] Conversion failed for " .. guid .. ": " .. tostring(errorMessage))
        return false, "dk_conversion_failed"
    end

    -- State 1 means that level/equipment conversion is complete but the
    -- destination has not yet been observed. The login relocation worker is
    -- the only code allowed to mark state 2.
    return true, "relocation_pending"
end

local function GetPendingDkRelocation(player)
    if not player or IsBotPlayer(player) then return nil end
    if player:GetClass() ~= DEATH_KNIGHT_CLASS_ID or player:GetLevel() ~= 1 then return nil end
    if not SpellDraft_IsRandomMode(player) then return nil end

    local query = CharDBQuery(string.format([[
        SELECT `eligible`, `state`
          FROM `spelldraft_dk_bootstrap`
         WHERE `guid` = %d
         LIMIT 1
    ]], player:GetGUIDLow()))
    if not query or query:GetUInt8(0) ~= 1 then return nil end

    local state = query:GetUInt8(1)
    -- State 1 is the new pending state. State 2 + map 609 repairs characters
    -- converted by A.22.8, which marked success before TeleportTo succeeded.
    if state ~= 1 and not (state == 2 and player:GetMapId() == DK_ACHERUS_MAP_ID) then
        return nil
    end
    return SpellDraft_GetDkDefaultStart(player)
end

local function UnlockDkRelocationPlayer(player)
    if player and player.SetPlayerLock then player:SetPlayerLock(false) end
end

function SpellDraft_BeginDkRelocation(player, callback)
    local start = GetPendingDkRelocation(player)
    if not start then
        if type(callback) == "function" then callback(false, "dk_relocation_not_pending") end
        return false
    end

    local guid = player:GetGUIDLow()
    if player.SetPlayerLock then player:SetPlayerLock(true) end
    CharDBExecute(string.format([[
        UPDATE `spelldraft_dk_bootstrap`
           SET `state` = 1, `selected_zone` = %d, `converted_at` = NULL
         WHERE `guid` = %d
    ]], tonumber(start.slot) or 0, guid))

    CreateLuaEvent(function()
        local current = GetPlayerByGUID(guid)
        if not current then return end

        local currentStart = SpellDraft_GetDkDefaultStart(current)
        if not currentStart then
            current:SendBroadcastMessage("|cffff3333[SpellDraft/DK]|r No racial starting route is configured.")
            if type(callback) == "function" then callback(false, "start_route_unavailable") end
            return
        end

        current:SetBindPoint(currentStart.x, currentStart.y, currentStart.z,
            currentStart.map, currentStart.zone or 0)
        local accepted = current:Teleport(currentStart.map, currentStart.x,
            currentStart.y, currentStart.z, currentStart.o)
        if not accepted then
            current:SendBroadcastMessage("|cffff3333[SpellDraft/DK]|r Starting-zone teleport was rejected; it will retry next login.")
            if type(callback) == "function" then callback(false, "dk_teleport_rejected") end
            return
        end

        local checks = 0
        local finished = false
        CreateLuaEvent(function()
            if finished then return end
            checks = checks + 1
            local arrived = GetPlayerByGUID(guid)
            if not arrived then return end

            if arrived:GetMapId() == currentStart.map then
                finished = true
                arrived:SetBindPoint(currentStart.x, currentStart.y, currentStart.z,
                    currentStart.map, arrived:GetZoneId())
                arrived:SaveToDB()
                -- Persist completion before notifying the activation state
                -- machine; an unlocked player must never still look pending.
                CharDBQuery(string.format([[
                    UPDATE `spelldraft_dk_bootstrap`
                       SET `state` = 2, `converted_at` = CURRENT_TIMESTAMP
                     WHERE `guid` = %d
                ]], guid))
                arrived:SendBroadcastMessage("|cff33ff66[SpellDraft/DK]|r Level-one racial starting route activated.")
                if type(callback) == "function" then callback(true, "dk_relocation_complete") end
                return
            end

            if checks >= DK_RELOCATION_VERIFY_COUNT then
                finished = true
                arrived:SendBroadcastMessage("|cffff3333[SpellDraft/DK]|r Teleport was not confirmed; it will retry next login.")
                if type(callback) == "function" then callback(false, "dk_relocation_timeout") end
            end
        end, DK_RELOCATION_VERIFY_MS, DK_RELOCATION_VERIFY_COUNT)
    end, DK_RELOCATION_DELAY_MS, 1)
    return true
end

local function OnDkRelocationLogin(_, player)
    local start = GetPendingDkRelocation(player)
    if not start then return end
    local guid = player:GetGUIDLow()
    if player.SetPlayerLock then player:SetPlayerLock(true) end
    SpellDraft_BeginDkRelocation(player, function()
        local current = GetPlayerByGUID(guid)
        UnlockDkRelocationPlayer(current)
    end)
end

function SpellDraft_SelectCharacterMode(player, requestedMode)
    if not player or IsBotPlayer(player) then
        return false, "invalid_player"
    end

    local modeName = tostring(requestedMode or ""):lower()
    local modeId = MODE_NAME_TO_ID[modeName]
    if not modeId then
        return false, "invalid_mode"
    end
    if not MODE_ENABLED[modeId] then
        return false, "mode_not_ready"
    end
    -- A character that progressed while the old picker was dismissible may
    -- already own trainer/class spells. Never let that legacy pending state
    -- become a contaminated Random Draft profile. Classic remains safe.
    if modeId == SPELLDRAFT_MODE.RANDOM_DRAFT and player:GetLevel() > 1 then
        if player:GetClass() == DEATH_KNIGHT_CLASS_ID
            and SpellDraft_GetDkBootstrapStatus(player) == "eligible" then
            if not SpellDraft_IsDkBootstrapConversionReady() then
                return false, "dk_conversion_not_ready"
            end
        else
            return false, "draft_requires_fresh_character"
        end
    end

    local guid = player:GetGUIDLow()
    local existing = CharDBQuery(
        "SELECT mode, locked FROM spelldraft_character_mode WHERE guid = " .. guid .. " LIMIT 1"
    )
    if existing then
        modeCache[guid] = existing:GetUInt8(0)
        return false, "already_locked"
    end

    -- INSERT IGNORE plus an immediate read makes the choice idempotent if the
    -- client double-clicks or resends because of latency.
    CharDBQuery(string.format([[
        INSERT IGNORE INTO `spelldraft_character_mode`
            (`guid`, `mode`, `locked`, `selected_level`, `selection_version`)
        VALUES (%d, %d, 1, %d, 1);
    ]], guid, modeId, player:GetLevel()))

    local saved = CharDBQuery(
        "SELECT mode FROM spelldraft_character_mode WHERE guid = " .. guid .. " LIMIT 1"
    )
    if not saved or saved:GetUInt8(0) ~= modeId then
        return false, "save_failed"
    end

    modeCache[guid] = modeId

    if modeId == SPELLDRAFT_MODE.RANDOM_DRAFT
        and player:GetClass() == DEATH_KNIGHT_CLASS_ID
        and player:GetLevel() > 1 then
        local converted, convertResult = ConvertDeathKnightToLevelOneDraft(player)
        if not converted then
            -- Conversion can fail after a partial level/equipment mutation.
            -- Keep the permanent mode row and bootstrap failure state so an
            -- administrator can diagnose and safely retry instead of rolling
            -- the character back into a misleading Pending profile.
            return true, MODE_ID_TO_NAME[modeId]
        end
        CharDBExecute("UPDATE spelldraft_character_mode SET selected_level = 1 WHERE guid = " .. guid)
    end

    if modeId ~= SPELLDRAFT_MODE.RANDOM_DRAFT then
        -- A stale legacy row must never make trainers or Lua anti-cheat treat a
        -- Classic/Free character as a random-draft character.
        CharDBExecute("UPDATE prestige_stats SET draft_state = 0 WHERE player_id = " .. guid)
        if type(SpellDraft_SetDraftStateCache) == "function" then
            SpellDraft_SetDraftStateCache(guid, 0)
        end
    end

    return true, MODE_ID_TO_NAME[modeId]
end

local modeActivationRuns = {}

local function FinishModeActivation(guid, callback, ok, result)
    local callbacks = modeActivationRuns[guid]
    if not callbacks then return end
    modeActivationRuns[guid] = nil
    for _, waitingCallback in ipairs(callbacks) do
        if type(waitingCallback) == "function" then
            local callbackOk, callbackError = pcall(waitingCallback, ok, result)
            if not callbackOk then
                print("[SpellDraft/A.31R2] Mode activation callback failed for " .. guid .. ": " .. tostring(callbackError))
            end
        end
    end
end

local function WaitForChoiceSessionReady(guid, callback)
    local attempts = 0
    local finished = false
    CreateLuaEvent(function()
        if finished then return end
        attempts = attempts + 1
        local current = GetPlayerByGUID(guid)
        if not current or not current:IsInWorld() then
            finished = true
            FinishModeActivation(guid, callback, false, "player_left_world")
            return
        end

        local ready = CharDBQuery(
            "SELECT successful_drafts, total_expected_drafts, offered_spell_1 " ..
            "FROM prestige_stats WHERE player_id = " .. guid .. " LIMIT 1")
        if ready then
            local successful = ready:GetUInt32(0)
            local expected = ready:GetUInt32(1)
            local offered = ready:GetUInt32(2)
            if successful >= expected or offered > 0 then
                finished = true
                FinishModeActivation(guid, callback, true, "draft")
                return
            end

            -- The one-shot session start can be skipped by first-login event
            -- ordering even though runtime is ready and entitlement exists.
            -- Retry the idempotent entry at bounded intervals; it restores a
            -- persisted set or creates exactly one synchronously saved set.
            if successful < expected and offered == 0
                and (attempts == 1 or attempts == 5 or attempts == 10)
                and type(SpellDraft_StartOrResumeChoiceSession) == "function" then
                SpellDraft_StartOrResumeChoiceSession(current, {
                    source = "activation_ready_retry_" .. attempts
                })
            end
        end

        -- SaveSpellsToDB uses the asynchronous database queue.  The choice
        -- window can already be visible on the client while offered_spell_1 is
        -- still zero for a few ticks, so poll the postcondition instead of
        -- treating that normal queue delay as a permanent activation failure.
        if attempts >= 20 then
            finished = true
            local failure = ready and "choice_not_created" or "choice_state_missing"
            if ready then
                failure = string.format("%s(successful=%d,expected=%d,offered=%d)",
                    failure, ready:GetUInt32(0), ready:GetUInt32(1), ready:GetUInt32(2))
            end
            current:SendBroadcastMessage("|cffff3333[Three Modes]|r " .. failure)
            print("[SpellDraft/A.31R2] Activation failed guid=" .. guid .. " " .. failure)
            FinishModeActivation(guid, callback, false, failure)
        end
    end, 250, 20)
end

local function ActivateDraftRuntimeAndChoices(player, callback)
    local guid = player:GetGUIDLow()
    if type(SpellDraft_EnsureDraftRuntime) ~= "function" then
        FinishModeActivation(guid, callback, false, "draft_runtime_not_ready")
        return
    end

    SpellDraft_EnsureDraftRuntime(player, { source = "mode_activation" }, function(runtimeOk, runtimeResult)
        local current = GetPlayerByGUID(guid)
        if not runtimeOk or not current or not current:IsInWorld() then
            FinishModeActivation(guid, callback, false, runtimeResult or "player_left_world")
            return
        end

        if type(SpellDraft_ApplyDraftTalentLock) ~= "function" then
            FinishModeActivation(guid, callback, false, "talent_runtime_not_ready")
            return
        end
        local talentOk, talentResult = pcall(SpellDraft_ApplyDraftTalentLock, current)
        if not talentOk or talentResult ~= true then
            FinishModeActivation(guid, callback, false, "talent_lock_failed")
            return
        end

        if type(SpellDraft_StartOrResumeChoiceSession) ~= "function" then
            FinishModeActivation(guid, callback, false, "choice_runtime_not_ready")
            return
        end
        SpellDraft_StartOrResumeChoiceSession(current, { source = "mode_activation" }, function(choiceOk, choiceResult)
            if not choiceOk then
                FinishModeActivation(guid, callback, false, choiceResult or "choice_session_failed")
                return
            end
            WaitForChoiceSessionReady(guid, callback)
        end)
    end)
end

function SpellDraft_ActivateSelectedMode(player, requestedMode, callback)
    if not player or not player:IsInWorld() or IsBotPlayer(player) then
        if type(callback) == "function" then callback(false, "invalid_player") end
        return false
    end

    local guid = player:GetGUIDLow()
    local modeName = SpellDraft_GetCharacterModeName(player)
    if modeName ~= tostring(requestedMode or ""):lower() then
        if type(callback) == "function" then callback(false, "mode_mismatch") end
        return false
    end
    -- Login recovery and the user's confirmation can reach this function in
    -- the same 2.5-second window. Join the in-flight activation instead of
    -- dropping the second callback and leaving its welcome page on Preparing.
    if modeActivationRuns[guid] then
        if type(callback) == "function" then
            table.insert(modeActivationRuns[guid], callback)
        end
        return true
    end
    modeActivationRuns[guid] = {}
    if type(callback) == "function" then
        table.insert(modeActivationRuns[guid], callback)
    end

    if modeName == "classic" then
        if type(SpellDraft_SetDraftStateCache) == "function" then
            SpellDraft_SetDraftStateCache(guid, false)
        end
        FinishModeActivation(guid, callback, true, "classic")
        return true
    end
    if modeName ~= "draft" then
        FinishModeActivation(guid, callback, false, "mode_not_ready")
        return false
    end

    if player:GetClass() == DEATH_KNIGHT_CLASS_ID then
        local bootstrap = CharDBQuery(
            "SELECT state FROM spelldraft_dk_bootstrap WHERE guid = " .. guid .. " LIMIT 1")
        local state = bootstrap and bootstrap:GetUInt8(0) or 3
        if state == 1 then
            SpellDraft_BeginDkRelocation(player, function(relocationOk, relocationResult)
                local current = GetPlayerByGUID(guid)
                if not relocationOk or not current or not current:IsInWorld() then
                    FinishModeActivation(guid, callback, false, relocationResult or "player_left_world")
                    return
                end
                ActivateDraftRuntimeAndChoices(current, callback)
            end)
            return true
        elseif state ~= 2 then
            FinishModeActivation(guid, callback, false, "dk_bootstrap_failed")
            return false
        end
    end

    ActivateDraftRuntimeAndChoices(player, callback)
    return true
end

local function OnModeCharacterCreate(_, player)
    if not player or IsBotPlayer(player) or player:GetClass() ~= DEATH_KNIGHT_CLASS_ID then return end

    local raceId = player:GetRace()
    local teamId = player:GetTeam()
    local eligible = HasEnabledDkStartRoute(player) and 1 or 0
    CharDBQuery(string.format([[
        INSERT INTO `spelldraft_dk_bootstrap`
            (`guid`, `race`, `team`, `created_level`, `eligible`, `state`, `version`)
        VALUES (%d, %d, %d, %d, %d, 0, %d)
        ON DUPLICATE KEY UPDATE
            `race` = VALUES(`race`),
            `team` = VALUES(`team`),
            `created_level` = VALUES(`created_level`),
            `eligible` = VALUES(`eligible`),
            `version` = VALUES(`version`);
    ]], player:GetGUIDLow(), raceId, teamId, player:GetLevel(), eligible, DK_BOOTSTRAP_VERSION))
end

local function OnModeLogout(_, player)
    if player then
        local guid = player:GetGUIDLow()
        modeCache[guid] = nil
        modeActivationRuns[guid] = nil
    end
end

local function OnModeCommand(_, player, command)
    if IsBotPlayer(player) then return end
    local cmd = tostring(command or ""):lower()
    if cmd ~= "sdmode" and cmd ~= "sdmode status" then return end

    local name = SpellDraft_GetCharacterModeName(player)
    player:SendBroadcastMessage("|cff00ccff[Three Modes]|r Current character mode: |cffffff00" .. name .. "|r")
    return false
end

RegisterPlayerEvent(4, OnModeLogout)
RegisterPlayerEvent(42, OnModeCommand)
RegisterPlayerEvent(1, OnModeCharacterCreate)
RegisterPlayerEvent(3, OnDkRelocationLogin)
