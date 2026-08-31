local AIO = AIO or require("AIO")

local handlers = AIO.AddHandlers("SpellDraftModeServer", {})

-- The client language button is authoritative for custom SpellDraft text.
-- Keep only an in-memory per-session value; the client SavedVariables sends it
-- again after every login, so no character database migration is required.
local playerLanguages = {}
local introReadyGUIDs = {}
local StartModeActivation

CharDBQuery([[
    CREATE TABLE IF NOT EXISTS `spelldraft_mode_intro_seen` (
        `guid` INT UNSIGNED NOT NULL,
        `mode` TINYINT UNSIGNED NOT NULL,
        `seen_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`guid`),
        CONSTRAINT `fk_spelldraft_intro_character`
            FOREIGN KEY (`guid`) REFERENCES `characters` (`guid`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]])

local function DefaultPlayerLanguage(player)
    if player and player.GetDbLocaleIndex ~= nil then
        local locale = player:GetDbLocaleIndex()
        if locale == 4 or locale == 5 then return "zhCN" end
    end
    return "enUS"
end

function SpellDraft_GetPlayerLanguage(player)
    if not player then return "enUS" end
    return playerLanguages[player:GetGUIDLow()] or DefaultPlayerLanguage(player)
end

function SpellDraft_SetPlayerLanguage(player, language, notifyClient)
    if not player or (player.IsBot ~= nil and player:IsBot()) then return false end
    if language ~= "zhCN" and language ~= "enUS" then return false end
    playerLanguages[player:GetGUIDLow()] = language
    if notifyClient then
        AIO.Handle(player, "SpellDraftModeClient", "ApplyLanguage", language)
    end
    return true
end

function handlers.SetLanguage(player, language)
    SpellDraft_SetPlayerLanguage(player, language, false)
    return false
end

local function IsBotPlayer(player)
    return player and player.IsBot ~= nil and player:IsBot()
end

local SetPickerLock

function handlers.FinishIntroduction(player, modeName)
    if not player or IsBotPlayer(player) then return false end
    local guid = player:GetGUIDLow()
    local expectedMode = introReadyGUIDs[guid]
    if expectedMode and expectedMode == tostring(modeName or ""):lower() then
        local modeId = expectedMode == "classic" and 1 or (expectedMode == "draft" and 2 or 3)
        CharDBQuery(string.format(
            "INSERT INTO spelldraft_mode_intro_seen (guid, mode) VALUES (%d, %d) " ..
            "ON DUPLICATE KEY UPDATE mode = VALUES(mode), seen_at = CURRENT_TIMESTAMP",
            guid, modeId))
        introReadyGUIDs[guid] = nil
        SetPickerLock(player, false)
    end
    return false
end

SetPickerLock = function(player, apply)
    if player and player.SetPlayerLock ~= nil then
        player:SetPlayerLock(apply == true)
    end
end

local function SendPicker(player)
    if not player or not player:IsInWorld() or IsBotPlayer(player) then return end
    if type(SpellDraft_GetCharacterModeName) ~= "function" then return end
    local modeName = SpellDraft_GetCharacterModeName(player)
    AIO.Handle(player, "SpellDraftModeClient", "ApplyMode", modeName)
    if modeName ~= "pending" then
        local seen = CharDBQuery(
            "SELECT 1 FROM spelldraft_mode_intro_seen WHERE guid = " ..
            player:GetGUIDLow() .. " LIMIT 1")
        if seen then return end

        -- Recover characters whose permanent choice was saved before the
        -- welcome page completed (disconnect, server restart, or A.31's early
        -- choice_not_created race). They resume the same idempotent activation
        -- and see the welcome page once; no mode selection is repeated.
        SetPickerLock(player, true)
        AIO.Handle(player, "SpellDraftModeClient", "ShowModeIntroduction", modeName)
        StartModeActivation(player, modeName)
        return
    end

    -- Pending is not a playable fourth mode. Stop movement and casting until
    -- the server has permanently accepted Classic or Random Draft.
    SetPickerLock(player, true)
    local isDeathKnight = player:GetClass() == 6
    local dkStatus = isDeathKnight and type(SpellDraft_GetDkBootstrapStatus) == "function"
        and SpellDraft_GetDkBootstrapStatus(player) or "not_death_knight"
    local dkReady = isDeathKnight and type(SpellDraft_IsDkBootstrapConversionReady) == "function"
        and SpellDraft_IsDkBootstrapConversionReady() or false

    AIO.Handle(player, "SpellDraftModeClient", "ShowPicker", {
        classic = true,
        draft = not isDeathKnight or (dkStatus == "eligible" and dkReady),
        free = type(SpellDraft_IsModeEnabled) == "function" and SpellDraft_IsModeEnabled("free") or false,
        isDeathKnight = isDeathKnight,
        dkStatus = dkStatus,
        dkConversionReady = dkReady,
    })
end

-- PLAYER_EVENT_ON_LOGIN does not fire for /reload. Let the reloaded AIO client
-- request the authoritative per-character mode again so its micro buttons do
-- not remain hidden in the temporary "pending" state.
function handlers.RequestMode(player)
    SendPicker(player)
    return false
end

StartModeActivation = function(player, modeName)
    local guid = player:GetGUIDLow()
    SpellDraft_ActivateSelectedMode(player, modeName, function(activationOk, activationResult)
        local current = GetPlayerByGUID(guid)
        if not current or not current:IsInWorld() then return end
        if activationOk then
            introReadyGUIDs[guid] = tostring(modeName):lower()
            AIO.Handle(current, "SpellDraftModeClient", "ApplyMode", tostring(modeName):lower())
            AIO.Handle(current, "SpellDraftModeClient", "ActivationResult", true, activationResult)
            current:SendBroadcastMessage("|cff00ff00[Three Modes]|r Progression mode activated without relogging.")
        else
            AIO.Handle(current, "SpellDraftModeClient", "ActivationResult", false, activationResult)
            current:SendBroadcastMessage("|cffff3333[Three Modes]|r Activation failed; your character remains locked for safe recovery.")
        end
    end)
end

function handlers.SelectMode(player, modeName)
    if not player or IsBotPlayer(player) then return false end
    if type(SpellDraft_SelectCharacterMode) ~= "function" then
        AIO.Handle(player, "SpellDraftModeClient", "SelectionResult", false, "server_not_ready")
        return false
    end
    if type(SpellDraft_ActivateSelectedMode) ~= "function" then
        AIO.Handle(player, "SpellDraftModeClient", "SelectionResult", false, "activation_not_ready")
        return false
    end

    local ok, result = SpellDraft_SelectCharacterMode(player, modeName)
    AIO.Handle(player, "SpellDraftModeClient", "SelectionResult", ok, result)
    if not ok then
        return false
    end

    StartModeActivation(player, modeName)
    return false
end

local function OnLogin(_, player)
    if IsBotPlayer(player) then return end
    if type(SpellDraft_GetCharacterModeName) == "function" then
        local modeName = SpellDraft_GetCharacterModeName(player)
        local needsIntro = modeName ~= "pending" and not CharDBQuery(
            "SELECT 1 FROM spelldraft_mode_intro_seen WHERE guid = " ..
            player:GetGUIDLow() .. " LIMIT 1")
        if modeName == "pending" or needsIntro then
        -- Lock immediately; the UI is sent after a short delay so AIO has time
            -- to initialize, but the character must not move or gain progress first.
            SetPickerLock(player, true)
        end
    end
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local current = GetPlayerByGUID(guid)
        SendPicker(current)
    end, 2500, 1)
end

RegisterPlayerEvent(3, OnLogin)

local function OnLogout(_, player)
    if player then
        local guid = player:GetGUIDLow()
        playerLanguages[guid] = nil
        introReadyGUIDs[guid] = nil
    end
end

RegisterPlayerEvent(4, OnLogout)
