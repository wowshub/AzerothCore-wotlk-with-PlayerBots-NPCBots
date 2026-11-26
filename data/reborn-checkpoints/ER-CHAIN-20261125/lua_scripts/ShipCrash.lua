-- ShipCrash.lua  (SHIP2D V1, 2026-11-22, Claude)
-- Exile's Reach: the ship wreck sequence for the Horde ship (map 12369).
--   storm builds up -> cutscene movie -> teleport to the beach -> player lies knocked down -> gets up.
-- Test trigger (GM only):  .shipcrash
-- Other scripts (the quest chain later) call:  ShipCrash_Start(player)
-- Sources: the sequence follows zone_exiles_reach.cpp (RoleplayCore) scene_alliance_and_horde_ship / _crash,
-- re-built for 3.3.5 because the retail "Scene" system does not exist here.

local CFG = {
    shipMap = 12369,            -- Horde ship map (our id for retail 2369)
    shipZone = 50532,           -- area/zone id used by the ship terrain (see game_weather SQL)
    movieMode = "addon",        -- "addon" (client addon RebornShipMovie plays the file) | "server" (SMSG_TRIGGER_MOVIE by id) | "both"
    moviePath = "Interface" .. string.char(92) .. "Cinematics" .. string.char(92) .. "ExilesReachHordeCrash",
    movieId = 931,              -- retail Movie 931 "Horde ship crash" (registered in Movie.dbc)
    movieSeconds = 23,          -- the movie is 22.4 s long
    stormDelayToMovie = 7,      -- seconds of storm before the movie starts
    beach = { map = 12175, x = -432.0, y = -2608.0, z = 1.5, o = 4.0 },
    knockedDownSeconds = 6,
    weatherStorm = 3,           -- WEATHER_TYPE_STORM
    weatherFine = 0,
}

local running = {}   -- [guidLow] = true while a sequence is playing
local state = {}     -- [guidLow] = { moviePlaying = bool, done = bool }  (done: the beach step already happened)

local function say(player, text)
    if player and player:IsInWorld() then
        player:SendBroadcastMessage(text)
    end
end

local function after(player, seconds, fn)
    -- RegisterEvent callbacks get (eventId, delay, repeats, object); do nothing if the player left
    player:RegisterEvent(function(_, _, _, obj)
        if obj and obj:IsInWorld() then
            fn(obj)
        end
    end, seconds * 1000, 1)
end

local function setShipWeather(player, kind, grade)
    local map = player:GetMap()
    if map then
        map:SetWeather(CFG.shipZone, kind, grade)
    end
end

local function playMovie(p)
    if CFG.movieMode == "server" or CFG.movieMode == "both" then
        p:SendMovieStart(CFG.movieId)
    end
    if CFG.movieMode == "addon" or CFG.movieMode == "both" then
        -- RebornShipMovie (client addon) listens for this whisper-type addon message and plays the avi by path
        p:SendAddonMessage("RBSHIP", "MOVIE|" .. CFG.moviePath, 7, p)
        local st = state[p:GetGUIDLow()]
        if st then st.moviePlaying = true end
    end
end

-- teleport to the beach and the knocked-down scene; runs once per sequence, from the timer OR when the client reports
-- that the movie ended / was skipped with ESC (RebornShipMovie sends RBSHIP|DONE)
local function toBeach(p, why)
    local st = state[p:GetGUIDLow()]
    if not st or st.done then return end
    st.done = true
    setShipWeather(p, CFG.weatherFine, 0)
    p:Teleport(CFG.beach.map, CFG.beach.x, CFG.beach.y, CFG.beach.z, CFG.beach.o)

    -- 4. lying knocked down on the beach
    after(p, 1, function(p2)
        p2:SetRooted(true)
        p2:SetStandState(3)      -- sleeping/lying
        say(p2, "|cffffff00You wash up on a beach. Everything hurts... 你被冲到了海滩上，浑身剧痛……|r")
        after(p2, CFG.knockedDownSeconds, function(p3)
            p3:SetStandState(0)
            p3:SetRooted(false)
            running[p3:GetGUIDLow()] = nil
            state[p3:GetGUIDLow()] = nil
            say(p3, "|cffffff00You get back on your feet. 你重新站了起来。|r")
        end)
    end)
end

function ShipCrash_Start(player)
    if not player or not player:IsInWorld() then
        return false
    end
    local low = player:GetGUIDLow()
    if running[low] then
        say(player, "The ship wreck sequence is already running. 船失事过程正在进行。")
        return false
    end
    running[low] = true
    state[low] = { moviePlaying = false, done = false }

    -- 1. the weather turns
    say(player, "|cffff8040The sky darkens. The ship starts to shake! 天色暗了下来，船开始剧烈摇晃！|r")
    setShipWeather(player, CFG.weatherStorm, 0.9)

    after(player, 3, function(p)
        say(p, "|cffff8040Warlord Breka Grimaxe: Brace yourselves! 战争领主布蕾卡·格里马克斯：抓紧了！|r")
    end)

    -- 2. the movie
    after(player, CFG.stormDelayToMovie, function(p)
        playMovie(p)
    end)

    -- 3. teleport to the beach: normally when the client says the movie is over (finished or ESC); this timer is the fallback
    after(player, CFG.stormDelayToMovie + CFG.movieSeconds, function(p)
        toBeach(p, "timer")
    end)

    -- safety: if the player logs out in between, the table entry would stay; clear it after a minute
    after(player, 90, function(p)
        running[p:GetGUIDLow()] = nil
        state[p:GetGUIDLow()] = nil
    end)
    return true
end

-- GM test command
local function OnCommand(event, player, command)
    if not player then
        return
    end
    local c = tostring(command or ""):lower():gsub("^%.", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if c == "shipcrash" then
        if player:GetGMRank() < 1 then
            return
        end
        ShipCrash_Start(player)
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)   -- PLAYER_EVENT_ON_COMMAND

-- clear the guard when the player leaves the world
RegisterPlayerEvent(4, function(event, player)   -- PLAYER_EVENT_ON_LOGOUT
    if player then
        running[player:GetGUIDLow()] = nil
    end
end)

print("[ShipCrash] SHIP2D V1 loaded: GM command .shipcrash ready")

-- the client addon reports the end of the cutscene (movie finished, or ESC/SPACE/ENTER pressed): go to the island now
RegisterServerEvent(30, function(event, sender, msgType, prefix, msg)      -- ADDON_EVENT_ON_MESSAGE
    if prefix == "RBSHIP" and msg == "DONE" then
        local st = sender and state[sender:GetGUIDLow()]
        if st and st.moviePlaying and not st.done then
            toBeach(sender, "skip")
        end
        return false          -- do not forward this addon message to other players
    end
end)
