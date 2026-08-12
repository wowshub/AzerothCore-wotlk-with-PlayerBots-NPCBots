local AIO = AIO or require("AIO")

local handlers = AIO.AddHandlers("SpellDraftModeServer", {})

-- The client language button is authoritative for custom SpellDraft text.
-- Keep only an in-memory per-session value; the client SavedVariables sends it
-- again after every login, so no character database migration is required.
local playerLanguages = {}

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

local function SetPickerLock(player, apply)
    if player and player.SetPlayerLock ~= nil then
        player:SetPlayerLock(apply == true)
    end
end

local function SendPicker(player)
    if not player or not player:IsInWorld() or IsBotPlayer(player) then return end
    if type(SpellDraft_GetCharacterModeName) ~= "function" then return end
    local modeName = SpellDraft_GetCharacterModeName(player)
    AIO.Handle(player, "SpellDraftModeClient", "ApplyMode", modeName)
    if modeName ~= "pending" then return end

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

function handlers.SelectMode(player, modeName)
    if not player or IsBotPlayer(player) then return false end
    if type(SpellDraft_SelectCharacterMode) ~= "function" then
        AIO.Handle(player, "SpellDraftModeClient", "SelectionResult", false, "server_not_ready")
        return false
    end

    local ok, result = SpellDraft_SelectCharacterMode(player, modeName)
    AIO.Handle(player, "SpellDraftModeClient", "SelectionResult", ok, result)
    if not ok then
        return false
    end

    SetPickerLock(player, false)
    player:SendBroadcastMessage("|cff00ff00[Three Modes]|r Your mode has been saved and locked. Re-entering the world will activate it.")
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local current = GetPlayerByGUID(guid)
        if current and current:IsInWorld() then
            current:KickPlayer()
        end
    end, 3500, 1)
    return false
end

local function OnLogin(_, player)
    if IsBotPlayer(player) then return end
    if type(SpellDraft_GetCharacterModeName) == "function"
        and SpellDraft_GetCharacterModeName(player) == "pending" then
        -- Lock immediately; the UI is sent after a short delay so AIO has time
        -- to initialize, but the character must not move or gain progress first.
        SetPickerLock(player, true)
    end
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local current = GetPlayerByGUID(guid)
        SendPicker(current)
    end, 2500, 1)
end

RegisterPlayerEvent(3, OnLogin)

local function OnLogout(_, player)
    if player then playerLanguages[player:GetGUIDLow()] = nil end
end

RegisterPlayerEvent(4, OnLogout)
