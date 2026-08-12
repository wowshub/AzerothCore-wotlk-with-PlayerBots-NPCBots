local AIO = AIO or require("AIO")




local enableItem = false  -- set to true if you want to use an item to remove racial
local itemRequired = 4540 -- item required to remove racial
local amountRequired = 1  -- amount of item required to remove racial

local IsNpc = true       --  set to true if you want to use an npc to open UI at
local npcEntry = 98888    --  npc entry to open UI at

local racialHandler = AIO.AddHandlers("RACIAL_SERVER", {})

local PLAYER_EVENT_ON_LOGIN = 30

-- Server-authoritative Heritage catalog. The client UI mirrors this list, but
-- every request is validated against this table before money or spells change.
local HERITAGE_LIMITS = { [1] = 2, [2] = 2, [3] = 1, [4] = 2 }
local HERITAGE_SPELLS = {
    [1] = {
        59752, 33697, 20594, 58984, 20549, 7744, 20577, 26297, 82381, 80025,
        59542, 800014, 2481, 20589, 255661, 800022, 800009, 10797, 100253,
        100257, 312411, 69041, 69070, 10001002, 100207, 100012, 2000104,
        800018, 800020, 68992, 800013, 4083, 800021, 875457, 100232,
        838809, 845857, 850253, 845859, 69046
    },
    [2] = {
        20592, 20596, 20579, 20551, 20573, 802255, 21563, 20555, 58943,
        20550, 20591, 5227, 28878, 20582, 21009, 20585, 58985, 20599,
        20598, 255665, 255664, 20557, 100255, 100256, 100254, 800023,
        107074, 80099, 100271, 312198, 312370, 312372, 312215, 69042,
        69044, 103370, 100258, 8000017, 800019, 68975, 100233, 100236,
        800012, 841282, 800008, 878248, 825070
    },
    [3] = {
        26290, 20595, 20574, 59224, 20597, 20558, 255663, 820574,
        814524, 826290, 910004
    },
    [4] = {
        20593, 20552, 28877, 28875, 69045, 68978, 255667, 878241, 878242,
        878243, 878244, 878245, 878246, 878247, 100117, 100118, 100105
    }
}

local HERITAGE_CATALOG = {}
local HERITAGE_GROUPS = {
    [312370] = { 312370, 312372 },
    [312372] = { 312370, 312372 }
}

for category, spells in pairs(HERITAGE_SPELLS) do
    for _, spellId in ipairs(spells) do
        HERITAGE_CATALOG[spellId] = {
            category = category,
            selectionKey = (spellId == 312372) and 312370 or spellId
        }
    end
end

CharDBExecute([[
    CREATE TABLE IF NOT EXISTS character_heritage_spells (
        player_guid INT UNSIGNED NOT NULL,
        spell_id INT UNSIGNED NOT NULL,
        category TINYINT UNSIGNED NOT NULL,
        selection_key INT UNSIGNED NOT NULL,
        PRIMARY KEY (player_guid, spell_id),
        KEY idx_heritage_category (player_guid, category, selection_key)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
]])

CharDBExecute([[
    CREATE TABLE IF NOT EXISTS character_heritage_state (
        player_guid INT UNSIGNED NOT NULL,
        migrated TINYINT UNSIGNED NOT NULL DEFAULT 1,
        PRIMARY KEY (player_guid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
]])

----------------------------------------------------------
-----------------[Npc Interaction]------------------------
----------------------------------------------------------
if IsNpc then
    local function creatureOnSpawn(event, creature) creature:SetNPCFlags(3) end

    local CREATURE_EVENT_ON_MOVE_IN_LOS = 27

    local GOSSIP_EVENT_ON_HELLO         = 1
    local GOSSIP_EVENT_ON_SELECT        = 2
    local CREATURE_EVENT_ON_SPAWN       = 5
    local menuId                        = 0x7FFFFFFF


    local isWindowOpen = false -- add this global variable



    local function creatureOnMoveInLos(event, creature, object)
        if (object:GetObjectType() == "Player") then
            if object:GetDistance(creature) < 2 then
                -- dismount player if mounted
                if object:IsMounted() then
                    object:Dismount()
                end
                return false
            end
            if object:GetDistance(creature) > 2 then
                if isWindowOpen then     -- add this check to only close the window when it's open
                    AIO.Handle(object, "RACIAL_CLIENT", "racialCloseUI")
                    isWindowOpen = false -- set the global variable to false when the window is closed
                end
                return false
            elseif isWindowOpen then -- add this check to only execute the rest of the function when the window is open
                return false
            end
        end
    end

    local function helloOnVendor(event, player, object)
        if (player:IsInCombat() and player:InBattleground() == true) then
            player:SendBroadcastMessage("|cff00ff00[World]|r |cffff0000You can't use racial while in combat !")
            return false
        end

        AIO.Handle(player, "RACIAL_CLIENT", "racialOpenUI")
        isWindowOpen = true -- set the global variable to true when the window is opened
        -- player:GossipSendMenu(menuId, object)
    end

    -- local function vendorOnSelection(event, player, object, sender, intid, code)
    --     if (intid == 1) then
    --         -- send menu for racial change

    --         AIO.Handle(player, "RACIAL_CLIENT", "racialOpenUI")
    --         player:GossipComplete()
    --     elseif (intid == 2) then -- add this line to handle the new option
    --         -- AIO.Handle(player, "RACIAL_SERVER", "racialOpenUI")
    --         player:GossipComplete()
    --     elseif (intid == 999) then
    --         player:GossipComplete()
    --     end
    -- end

    RegisterCreatureEvent(npcEntry, CREATURE_EVENT_ON_MOVE_IN_LOS, creatureOnMoveInLos)
    RegisterCreatureEvent(npcEntry, CREATURE_EVENT_ON_SPAWN, creatureOnSpawn)
    RegisterCreatureGossipEvent(npcEntry, GOSSIP_EVENT_ON_HELLO, helloOnVendor)
    -- RegisterCreatureGossipEvent(npcEntry, GOSSIP_EVENT_ON_SELECT, vendorOnSelection)
end

--  handle player's first login
local function onPlayerFirstLogin(event, player)
    AIO.Handle(player, "RACIAL_CLIENT", "racialOpenUI")
end

RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, onPlayerFirstLogin)

----------------------------------------------------------
-----------------[End of Interaction]---------------------
----------------------------------------------------------

local function hasRequiredItem(player)
    if enableItem then
        return player:HasItem(itemRequired)
    else
        return true
    end
end

local function IsBotPlayer(player)
    return player.IsBot ~= nil and player:IsBot()
end

local function NormalizeSpellId(value)
    local spellId = tonumber(value)
    if not spellId then return nil end
    spellId = math.floor(spellId)
    if spellId <= 0 then return nil end
    return spellId
end

local function Notify(player, message)
    player:SendBroadcastMessage("|cffd8b400[Heritage]|r " .. message)
end

local function RefreshClient(player)
    AIO.Handle(player, "RACIAL_CLIENT", "heritageRefresh")
end

local function GetSelectionMembers(spellId)
    return HERITAGE_GROUPS[spellId] or { spellId }
end

local function IsMigrated(guid)
    return CharDBQuery("SELECT 1 FROM character_heritage_state WHERE player_guid = " .. guid .. " LIMIT 1") ~= nil
end

local function IsSelectionRecorded(guid, selectionKey)
    return CharDBQuery(
        "SELECT 1 FROM character_heritage_spells WHERE player_guid = " .. guid ..
        " AND selection_key = " .. selectionKey .. " LIMIT 1"
    ) ~= nil
end

function Heritage_IsRecordedSpell(guid, spellId)
    spellId = NormalizeSpellId(spellId)
    if not spellId or not HERITAGE_CATALOG[spellId] then return false end

    local recorded = CharDBQuery(
        "SELECT 1 FROM character_heritage_spells WHERE player_guid = " .. tonumber(guid) ..
        " AND spell_id = " .. spellId .. " LIMIT 1"
    )
    if recorded then return true end

    -- One-time migration grace: keep pre-A.20 Heritage spells alive until the
    -- login migration records the player's existing choices.
    return not IsMigrated(tonumber(guid))
end

local function RecordSelection(guid, spellId)
    local entry = HERITAGE_CATALOG[spellId]
    if not entry then return false end

    local values = {}
    for _, memberId in ipairs(GetSelectionMembers(spellId)) do
        local memberEntry = HERITAGE_CATALOG[memberId]
        if memberEntry then
            values[#values + 1] = string.format(
                "(%d,%d,%d,%d)", guid, memberId, memberEntry.category, entry.selectionKey
            )
        end
    end
    if #values == 0 then return false end

    -- Synchronous insert: OnLearnSpell may run during LearnSpell and must see
    -- the authorization record immediately.
    CharDBQuery(
        "INSERT IGNORE INTO character_heritage_spells " ..
        "(player_guid, spell_id, category, selection_key) VALUES " .. table.concat(values, ",")
    )
    return true
end

local function DeleteSelection(guid, selectionKey)
    CharDBQuery(
        "DELETE FROM character_heritage_spells WHERE player_guid = " .. guid ..
        " AND selection_key = " .. selectionKey
    )
end

local function GetCategorySelectionCount(guid, category)
    local query = CharDBQuery(
        "SELECT COUNT(DISTINCT selection_key) FROM character_heritage_spells " ..
        "WHERE player_guid = " .. guid .. " AND category = " .. category
    )
    return query and query:GetUInt32(0) or 0
end

local function WithSystemLearning(player, callback)
    local guid = player:GetGUIDLow()
    if type(SpellDraft_SetSystemLearning) == "function" then
        SpellDraft_SetSystemLearning(guid, true)
    end

    local ok, err = pcall(callback)

    if type(SpellDraft_SetSystemLearning) == "function" then
        SpellDraft_SetSystemLearning(guid, false)
    end

    if not ok then
        print("[HERITAGE_ERROR] " .. tostring(err))
    end
    return ok
end

local function LearnSelection(player, spellId)
    local guid = player:GetGUIDLow()
    if not RecordSelection(guid, spellId) then return false end

    local ok = WithSystemLearning(player, function()
        for _, memberId in ipairs(GetSelectionMembers(spellId)) do
            if not player:HasSpell(memberId) then
                player:LearnSpell(memberId)
            end
        end
    end)

    if not ok then
        local entry = HERITAGE_CATALOG[spellId]
        DeleteSelection(guid, entry.selectionKey)
    end
    return ok
end

local function RemoveSelection(player, spellId)
    local entry = HERITAGE_CATALOG[spellId]
    if not entry then return false end

    WithSystemLearning(player, function()
        for _, memberId in ipairs(GetSelectionMembers(spellId)) do
            if player:HasSpell(memberId) then
                player:RemoveSpell(memberId)
            end
        end
    end)
    DeleteSelection(player:GetGUIDLow(), entry.selectionKey)
    return true
end

local function EnsureLegacyMigration(player)
    local guid = player:GetGUIDLow()
    if IsMigrated(guid) then return end

    local seen = {}
    for category = 1, 4 do
        for _, spellId in ipairs(HERITAGE_SPELLS[category]) do
            local entry = HERITAGE_CATALOG[spellId]
            if not seen[entry.selectionKey] then
                seen[entry.selectionKey] = true
                local known = false
                for _, memberId in ipairs(GetSelectionMembers(spellId)) do
                    if player:HasSpell(memberId) then
                        known = true
                        break
                    end
                end
                if known then
                    RecordSelection(guid, spellId)
                end
            end
        end
    end

    CharDBQuery(
        "INSERT IGNORE INTO character_heritage_state (player_guid, migrated) VALUES (" .. guid .. ",1)"
    )
end

local function ReconcileHeritageSpells(player)
    if not player or not player:IsInWorld() or IsBotPlayer(player) then return end
    EnsureLegacyMigration(player)

    local guid = player:GetGUIDLow()
    local recorded = {}
    local query = CharDBQuery(
        "SELECT spell_id FROM character_heritage_spells WHERE player_guid = " .. guid
    )
    if query then
        repeat
            recorded[query:GetUInt32(0)] = true
        until not query:NextRow()
    end

    WithSystemLearning(player, function()
        for spellId in pairs(HERITAGE_CATALOG) do
            if recorded[spellId] then
                if not player:HasSpell(spellId) then
                    player:LearnSpell(spellId)
                end
            elseif player:HasSpell(spellId) then
                -- SpellDraft may re-grant native racials on login. Heritage is
                -- authoritative after migration, so deselected catalog spells
                -- are removed again while fixed birth utilities remain intact.
                player:RemoveSpell(spellId)
            end
        end
    end)
    player:SaveToDB()
    RefreshClient(player)
end

function racialHandler.racialActivate(player, rawSpellId, itemType)
    if IsBotPlayer(player) then return false end
    local spellId = NormalizeSpellId(rawSpellId)
    local entry = spellId and HERITAGE_CATALOG[spellId]
    if not entry or itemType ~= "spell" then
        Notify(player, "非法的遗产技能请求已被服务器拒绝。 / Invalid Heritage request rejected.")
        RefreshClient(player)
        return false
    end
    if player:IsInCombat() or player:InBattleground() then
        Notify(player, "战斗中不能修改遗产技能。 / Cannot change Heritage spells in combat.")
        RefreshClient(player)
        return false
    end

    EnsureLegacyMigration(player)
    local guid = player:GetGUIDLow()
    if IsSelectionRecorded(guid, entry.selectionKey) then
        Notify(player, "你已经选择了这个遗产技能。 / Heritage spell already selected.")
        RefreshClient(player)
        return false
    end

    local used = GetCategorySelectionCount(guid, entry.category)
    local limit = HERITAGE_LIMITS[entry.category]
    if used >= limit then
        Notify(player, string.format("该类别名额已满（%d/%d）。 / Category limit reached.", used, limit))
        RefreshClient(player)
        return false
    end

    local costToActivate = 10000 -- 1 gold
    if player:GetLevel() > 10 and player:GetCoinage() < costToActivate then
        Notify(player, "金币不足，需要 1 金。 / You need 1 gold.")
        RefreshClient(player)
        return false
    end

    if not LearnSelection(player, spellId) then
        Notify(player, "学习失败，未扣除金币。 / Learning failed; no money charged.")
        RefreshClient(player)
        return false
    end

    -- Charge only after every validation and a successful learn operation.
    if player:GetLevel() > 10 then
        player:ModifyMoney(-costToActivate)
    end
    if entry.category == 4 and not player:HasAura(882053) then
        player:AddAura(882053, player)
    end

    player:SaveToDB()
    Notify(player, "遗产技能学习成功。 / Heritage spell learned.")
    RefreshClient(player)
    return true
end

function racialHandler.racialDeactivate(player, rawSpellId, itemType)
    if IsBotPlayer(player) then return false end
    local spellId = NormalizeSpellId(rawSpellId)
    local entry = spellId and HERITAGE_CATALOG[spellId]
    if not entry or itemType ~= "spell" then
        Notify(player, "非法的遗产技能请求已被服务器拒绝。 / Invalid Heritage request rejected.")
        RefreshClient(player)
        return false
    end
    if player:IsInCombat() or player:InBattleground() then
        Notify(player, "战斗中不能修改遗产技能。 / Cannot change Heritage spells in combat.")
        RefreshClient(player)
        return false
    end

    EnsureLegacyMigration(player)
    local guid = player:GetGUIDLow()
    if not IsSelectionRecorded(guid, entry.selectionKey) then
        Notify(player, "这个技能不在你的遗产记录中。 / Heritage spell is not selected.")
        RefreshClient(player)
        return false
    end

    if entry.category == 4 and player:HasAura(882053) then
        local aura = player:GetAura(882053)
        local remaining = aura and math.max(0, math.floor(aura:GetDuration() / 1000)) or 0
        Notify(player, string.format("专业遗产仍在冷却：%d分%d秒。 / Profession cooldown active.", math.floor(remaining / 60), remaining % 60))
        RefreshClient(player)
        return false
    end

    RemoveSelection(player, spellId)
    player:SaveToDB()
    Notify(player, "遗产技能已移除。 / Heritage spell removed.")
    RefreshClient(player)
    return true
end

function racialHandler.resetAllHeritage(player)
    if IsBotPlayer(player) then return false end
    if player:IsInCombat() or player:InBattleground() then
        Notify(player, "战斗中不能重置遗产技能。 / Cannot reset Heritage spells in combat.")
        RefreshClient(player)
        return false
    end
    if not hasRequiredItem(player) then
        Notify(player, "缺少重置所需物品。 / Missing the required reset item.")
        RefreshClient(player)
        return false
    end

    EnsureLegacyMigration(player)
    local guid = player:GetGUIDLow()
    local keys = {}
    local query = CharDBQuery(
        "SELECT DISTINCT selection_key FROM character_heritage_spells WHERE player_guid = " ..
        guid .. " AND category <> 4"
    )
    if query then
        repeat
            keys[#keys + 1] = query:GetUInt32(0)
        until not query:NextRow()
    end

    for _, selectionKey in ipairs(keys) do
        RemoveSelection(player, selectionKey)
    end
    if enableItem then
        player:RemoveItem(itemRequired, amountRequired)
    end
    player:SaveToDB()
    Notify(player, "功能、被动和武器遗产已重置；专业遗产保持不变。 / Heritage reset complete.")
    RefreshClient(player)
    return true
end

-- Backward-compatible handler used by older cached clients.
function racialHandler.unLearnAllRacials(player, spellId, itemType)
    return racialHandler.racialDeactivate(player, spellId, itemType)
end

local function OnHeritageLogin(event, player)
    if IsBotPlayer(player) then return end
    -- Record legacy selections as early as possible, then reconcile after
    -- SpellDraft's delayed racial grant has finished.
    EnsureLegacyMigration(player)
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local current = GetPlayerByGUID(guid)
        if current then ReconcileHeritageSpells(current) end
    end, 4500, 1)
end

RegisterPlayerEvent(3, OnHeritageLogin)

local function showWindowPls(event, player, command)
    if (command == "rc") then
        AIO.Handle(player, "RACIAL_CLIENT", "racialOpenUI")
        return false
    end
end

RegisterPlayerEvent(42, showWindowPls)
