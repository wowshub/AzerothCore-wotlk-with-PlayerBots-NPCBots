local AIO = AIO or require("AIO")

local handlers = AIO.AddHandlers("SpellDraftModeServer", {})

-- The client language button is authoritative for custom SpellDraft text.
-- Keep only an in-memory per-session value; the client SavedVariables sends it
-- again after every login, so no character database migration is required.
local playerLanguages = {}
local introReadyGUIDs = {}
local StartModeActivation
local DeliverIntroduction
local introDelivery = {}
local nextIntroDelivery = 0
local pickerDelivery = {}
local nextPickerToken = 0
function handlers.PickerVisible(player, token)
    if not player or (player.IsBot and player:IsBot()) then return false end
    local state = pickerDelivery[player:GetGUIDLow()]
    if state and state.token == tonumber(token) then state.visible = true end
    return false
end

-- RACECOMBO1C: render acknowledgement is separate from permanent completion.
-- Retry only this session/token. Never unlock because a delivery timer expires.
DeliverIntroduction = function(player, modeName, ready, result)
    local guid = player:GetGUIDLow()
    nextIntroDelivery = nextIntroDelivery + 1
    local token = nextIntroDelivery
    local state = { mode = tostring(modeName):lower(), token = token,
        ready = ready == true, result = result }
    introDelivery[guid] = state
    local function Send()
        local current = GetPlayerByGUID(guid)
        if introDelivery[guid] ~= state or state.displayed
            or not current or not current:IsInWorld() then return end
        AIO.Handle(current, "SpellDraftModeClient", "PresentIntroduction",
            state.mode, state.ready, state.result, token)
    end
    Send()
    for _, delay in ipairs({500, 1500, 3000, 6000, 10000, 16000}) do
        CreateLuaEvent(Send, delay, 1)
    end
end

function handlers.IntroductionVisible(player, modeName, token)
    if not player or (player.IsBot and player:IsBot()) then return false end
    local state = introDelivery[player:GetGUIDLow()]
    if state and state.mode == modeName and state.token == tonumber(token) then
        state.displayed = true
    end
    return false
end

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
local pickerLocks = {}

-- RACECOMBO1A: persist and acknowledge before the client closes its modal.
function handlers.FinishIntroduction(player, modeName)
    if not player or IsBotPlayer(player) then return false end
    local guid = player:GetGUIDLow()
    local requested = tostring(modeName or ""):lower()
    local expected = introReadyGUIDs[guid]
    local modeId = requested == "classic" and 1 or (requested == "draft" and 2 or 0)
    if modeId == 0 then return false end
    local actual = type(SpellDraft_GetCharacterModeName) == "function"
        and SpellDraft_GetCharacterModeName(player) or "pending"
    if requested ~= actual then
        AIO.Handle(player, "SpellDraftModeClient", "IntroductionFinished", false, "mode_mismatch")
        return false
    end
    if expected == requested then
        CharDBQuery(string.format(
            "INSERT INTO spelldraft_mode_intro_seen (guid, mode) VALUES (%d, %d) " ..
            "ON DUPLICATE KEY UPDATE mode = VALUES(mode), seen_at = CURRENT_TIMESTAMP", guid, modeId))
    end
    local saved = CharDBQuery(string.format(
        "SELECT 1 FROM spelldraft_mode_intro_seen WHERE guid = %d AND mode = %d LIMIT 1", guid, modeId))
    if saved and (expected == requested or expected == nil) then
        introReadyGUIDs[guid] = nil
        introDelivery[guid] = nil
        if pickerLocks[guid] then SetPickerLock(player, false) end
        AIO.Handle(player, "SpellDraftModeClient", "IntroductionFinished", true, requested)
    else
        AIO.Handle(player, "SpellDraftModeClient", "IntroductionFinished", false, "introduction_not_ready")
    end
    return false
end

SetPickerLock = function(player, apply)
    if player and player.SetPlayerLock ~= nil then
        player:SetPlayerLock(apply == true)
        pickerLocks[player:GetGUIDLow()] = apply == true or nil
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
        if seen then
            local delivery = pickerDelivery[player:GetGUIDLow()]
            if delivery then delivery.complete = true end
            AIO.Handle(player, "SpellDraftModeClient", "SyncComplete", modeName)
            if pickerLocks[player:GetGUIDLow()] then SetPickerLock(player, false) end
            return
        end

        -- Recover characters whose permanent choice was saved before the
        -- welcome page completed (disconnect, server restart, or A.31's early
        -- choice_not_created race). They resume the same idempotent activation
        -- and see the welcome page once; no mode selection is repeated.
        local delivery = introDelivery[player:GetGUIDLow()]
        if delivery and delivery.mode == modeName and delivery.ready then
            if not delivery.displayed then
                AIO.Handle(player, "SpellDraftModeClient", "PresentIntroduction",
                    delivery.mode, true, delivery.result, delivery.token)
            end
            return
        end
        SetPickerLock(player, true)
        DeliverIntroduction(player, modeName, false, "preparing")
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

    local guid = player:GetGUIDLow()
    local delivery = pickerDelivery[guid]
    if not delivery then
        nextPickerToken = nextPickerToken + 1
        delivery = { token = nextPickerToken }
        pickerDelivery[guid] = delivery
    end
    AIO.Handle(player, "SpellDraftModeClient", "ShowPicker", {
        gateToken = delivery.token,
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
    -- A reloaded client has a new frame lifecycle; an earlier render receipt
    -- cannot prove that this new UI is still visible.
    local delivery = player and introDelivery[player:GetGUIDLow()]
    if delivery then delivery.displayed = false end
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
            DeliverIntroduction(current, modeName, true, activationResult)
            current:SendBroadcastMessage("|cff00ff00[Three Modes]|r Progression mode activated without relogging.")
        else
            DeliverIntroduction(current, modeName, false, activationResult)
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

    DeliverIntroduction(player, modeName, false, "preparing")
    StartModeActivation(player, modeName)
    return false
end

-- This is recovery of an already selected mode, never another selection.
function handlers.RequestIntroduction(player)
    if not player or IsBotPlayer(player) then return false end
    local actual = SpellDraft_GetCharacterModeName(player)
    if actual == "classic" or actual == "draft" then SendPicker(player) end
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
    nextPickerToken = nextPickerToken + 1
    local state = { token = nextPickerToken }
    pickerDelivery[guid] = state
    -- Keep trying across long FIRST world loads, not just one login timer.
    -- The ordinary addon also requests state until an authoritative visible UI.
    CreateLuaEvent(function()
        if pickerDelivery[guid] ~= state or state.complete then return end
        local current = GetPlayerByGUID(guid)
        if not current or not current:IsInWorld() then return end
        local actual = SpellDraft_GetCharacterModeName(current)
        if actual == "pending" and state.visible then return end
        local intro = introDelivery[guid]
        if actual ~= "pending" and intro and intro.ready and intro.displayed then return end
        SendPicker(current)
    end, 2500, 24)
end

-- A fixed login timer is not proof that uncached AIO code has loaded.
-- This message is appended AFTER the AIO initialization payload; the client
-- requests mode only after its handlers exist, even if ENTERING_WORLD was missed.
if type(AIO.AddOnInit) == "function" then
    AIO.AddOnInit(function(msg, player)
        if player and not IsBotPlayer(player) then
            msg:Add("SpellDraftModeClient", "InitializeModeSync")
        end
        return msg
    end)
end

RegisterPlayerEvent(3, OnLogin)

local function OnLogout(_, player)
    if player then
        local guid = player:GetGUIDLow()
        playerLanguages[guid] = nil
        introReadyGUIDs[guid] = nil
        pickerLocks[guid] = nil
        introDelivery[guid] = nil
        pickerDelivery[guid] = nil
    end
end

RegisterPlayerEvent(4, OnLogout)

print("[RACECOMBO1E] ModeServer: ordinary addon, picker receipt and first-world recovery loaded")
