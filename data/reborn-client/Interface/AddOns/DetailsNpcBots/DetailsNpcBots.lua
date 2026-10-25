-- DetailsNpcBots (RebornWOW DETNPC1A)
--
-- Why this exists: Details! lists in its group view only the actors it flags as group members.
-- A player is flagged from the combat-log source flags (party / raid affiliation) or from the
-- party roster (unit tokens party1..4 / raid1..40). An NPCBot is a creature and not a unit in
-- the client's party, so none of that applies and its damage and healing are recorded but never
-- shown in the group meters.
--
-- What this does, without editing Details: once a second it walks the actors Details has recorded
-- (the current fight, the overall data and the last few segments) and marks an actor as a group
-- member when it is an NPCBot, then asks the windows to redraw. An actor counts as an NPCBot when
--   1. its name is on the list (/dnb add, or the current target), or
--   2. (automatic, can be switched off) the combat log says it is a friendly, non-player creature
--      that is controlled by the player or affiliated with the group, and Details has not
--      already attached it to an owner (pets Details can resolve stay merged into their owner).
--
-- Commands: /dnb                 status and help
--           /dnb add [name] [CLASS]   add the target (or the name) to the list
--           /dnb del <name>       remove a name
--           /dnb list             show the list
--           /dnb auto on|off      the automatic rule above
--           /dnb probe            list friendly non-player actors Details has seen, with their
--                                 combat-log flags (send this to the developer if a bot is missed)

local band = bit.band
local DB

local FLAG_MINE_PARTY_RAID = 0x00000007
local FLAG_FRIENDLY = 0x00000010
local FLAG_HOSTILE = 0x00000040
local FLAG_CONTROL_PLAYER = 0x00000100
local FLAG_TYPE_PLAYER = 0x00000400

local function Say(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff6fc8ff[Details NPCBots]|r " .. msg) end

local function D() return rawget(_G, "_detalhes") end

local function IsListed(name)
    return name and DB and DB.names[name] ~= nil
end

local function ClassFor(name)
    local c = DB and DB.names[name]
    if type(c) == "string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[c] then return c end
    local _, token = UnitClass(name or "")
    if token and RAID_CLASS_COLORS and RAID_CLASS_COLORS[token] then return token end
    return nil
end

-- is this recorded actor an NPCBot that should be treated as a group member?
local function IsBotActor(a)
    if type(a) ~= "table" or a.grupo or a.owner or a.enemy or a.monster then return false end
    local name = a.nome
    if not name then return false end
    if IsListed(name) then return true end
    if not (DB and DB.auto) then return false end
    local f = a.flag_original
    if not f then return false end
    if band(f, FLAG_FRIENDLY) == 0 or band(f, FLAG_HOSTILE) ~= 0 then return false end
    if band(f, FLAG_TYPE_PLAYER) ~= 0 then return false end              -- real players are handled by Details
    -- Pets and guardians whose owner Details resolved already carry actor.owner and were skipped
    -- above; one that is still ownerless here is, for our purposes, a companion of the group.
    return band(f, FLAG_CONTROL_PLAYER) ~= 0 or band(f, FLAG_MINE_PARTY_RAID) ~= 0
end

local function Promote(actor, combat, det)
    actor.grupo = true
    local token = ClassFor(actor.nome)
    if token and (actor.classe == nil or actor.classe == "UNKNOW") then actor.classe = token end
    -- while a fight runs, the group window reads these caches, not the containers
    if det.in_combat and combat == det.tabela_vigente then
        local cache = actor.tipo == 1 and det.cache_damage_group or (actor.tipo == 2 and det.cache_healing_group)
        if cache then
            local have = false
            for i = 1, #cache do if cache[i] == actor then have = true; break end end
            if not have then cache[#cache + 1] = actor end
        end
    end
end

local function ScanCombat(combat, det)
    if type(combat) ~= "table" then return 0 end
    local n = 0
    for attr = 1, 2 do                                   -- 1 damage, 2 healing
        local container = combat[attr]
        local list = container and container._ActorTable
        if list then
            for i = 1, #list do
                local a = list[i]
                if IsBotActor(a) then Promote(a, combat, det); n = n + 1 end
            end
        end
    end
    return n
end

local function Scan()
    local det = D()
    if not det or not det.tabela_vigente then return end
    local n = ScanCombat(det.tabela_vigente, det) + ScanCombat(det.tabela_overall, det)
    local hist = det.tabela_historico and det.tabela_historico.tabelas
    if hist then
        for i = 1, math.min(#hist, 8) do n = n + ScanCombat(hist[i], det) end
    end
    if n > 0 and det.AtualizaGumpPrincipal then
        pcall(det.AtualizaGumpPrincipal, det, -1, true)
    end
end

-- ------------------------------------------------------------------ commands
local function Probe()
    local det = D()
    if not det then Say("Details is not loaded."); return end
    local seen, count = {}, 0
    local function walk(combat, label)
        if type(combat) ~= "table" then return end
        for attr = 1, 2 do
            local list = combat[attr] and combat[attr]._ActorTable
            if list then
                for i = 1, #list do
                    local a = list[i]
                    local f = a.flag_original
                    if f and not seen[a.nome or "?"] and band(f, FLAG_FRIENDLY) ~= 0 and band(f, FLAG_TYPE_PLAYER) == 0 then
                        seen[a.nome or "?"] = true
                        count = count + 1
                        Say(string.format("%s  flags=0x%X  group=%s  owner=%s  listed=%s  (%s)", a.nome or "?", f,
                            tostring(a.grupo and true or false), tostring(a.ownerName or "-"), tostring(IsListed(a.nome) and true or false), label))
                    end
                end
            end
        end
    end
    walk(det.tabela_vigente, "now")
    walk(det.tabela_overall, "overall")
    if count == 0 then Say("No friendly non-player actors recorded yet. Fight something with the bot first.") end
end

SLASH_DETAILSNPCBOTS1 = "/dnb"
SlashCmdList["DETAILSNPCBOTS"] = function(msg)
    msg = msg or ""
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if cmd == "add" then
        local name, class = rest:match("^(%S+)%s*(%S*)$")
        if not name then
            if UnitExists("target") then name = UnitName("target") end
        end
        if not name or name == "" then Say("Target the NPCBot, or: /dnb add <name> [CLASS]"); return end
        class = (class ~= "" and class:upper()) or true
        DB.names[name] = class
        Say("added: " .. name)
        Scan()
    elseif cmd == "del" then
        if rest ~= "" and DB.names[rest] then DB.names[rest] = nil; Say("removed: " .. rest) else Say("not on the list: " .. rest) end
    elseif cmd == "list" then
        local any = false
        for name in pairs(DB.names) do any = true; Say(name) end
        if not any then Say("(empty)") end
    elseif cmd == "auto" then
        DB.auto = (rest:lower() ~= "off")
        Say("automatic rule: " .. (DB.auto and "on" or "off"))
    elseif cmd == "probe" then
        Probe()
    else
        Say("auto rule: " .. (DB.auto and "on" or "off") .. "   Details: " .. (D() and "loaded" or "NOT loaded"))
        Say("/dnb add [name] [CLASS]   /dnb del <name>   /dnb list   /dnb auto on|off   /dnb probe")
    end
end

-- ------------------------------------------------------------------ driver
local frame = CreateFrame("Frame")
local elapsed = 0
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == "DetailsNpcBots" then
        DetailsNpcBotsDB = DetailsNpcBotsDB or {}
        DB = DetailsNpcBotsDB
        DB.names = DB.names or {}
        if DB.auto == nil then DB.auto = true end
    end
end)
frame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 1 or not DB then return end
    elapsed = 0
    local ok = pcall(Scan)
    if not ok then DB.errors = (DB.errors or 0) + 1 end
end)
