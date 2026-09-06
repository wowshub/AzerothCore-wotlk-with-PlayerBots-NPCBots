-- M6J: classID 14 receives its native skill progression only in Classic mode.
-- DBC AcquireMethod is intentionally zero; this authority layer owns learning.

local MONK_CLASS_ID = 14
local MONK_DIRECT_HIT_ID = 9001501
local MONK_TIGER_PALM_ID = 9001502
local MONK_TIGER_POWER_ID = 9001503
local MONK_EXPEL_HARM_ID = 9001504
local MONK_ROLL_ID = 9001505
local MONK_BLACKOUT_KICK_ID = 9001507
local MONK_JAB_ID = 9001510
local MONK_CHI_AURA_ID = 9001511
local MONK_RISING_SUN_KICK_ID = 9001513
local MONK_CLASSIC_SPELLS = {
    { id = MONK_DIRECT_HIT_ID, minLevel = 1 },
    { id = MONK_TIGER_PALM_ID, minLevel = 1 },
    { id = MONK_EXPEL_HARM_ID, minLevel = 1 },
    { id = MONK_ROLL_ID, minLevel = 1 },
    { id = MONK_BLACKOUT_KICK_ID, minLevel = 7 },
    { id = MONK_JAB_ID, minLevel = 3 },
    { id = MONK_RISING_SUN_KICK_ID, minLevel = 10 },
}
local LOGIN_RECONCILE_DELAY_MS = 900

local function IsBotPlayer(player)
    return player and player.IsBot ~= nil and player:IsBot()
end

function SpellDraft_ReconcileMonkClassicStarter(player)
    if not player or IsBotPlayer(player) or player:GetClass() ~= MONK_CLASS_ID then
        return false, "not_player_monk"
    end

    local isClassic = type(SpellDraft_IsClassicMode) == "function"
        and SpellDraft_IsClassicMode(player)

    if isClassic then
        local level = player:GetLevel()
        for _, spell in ipairs(MONK_CLASSIC_SPELLS) do
            if level >= spell.minLevel then
                if not player:HasSpell(spell.id) then
                    player:LearnSpell(spell.id)
                end
            elseif player:HasSpell(spell.id) then
                player:RemoveSpell(spell.id)
            end
        end
        return true, "classic_learned"
    end

    -- Pending, Random Draft and Free Pick must not inherit native Monk spells.
    for _, spell in ipairs(MONK_CLASSIC_SPELLS) do
        if player:HasSpell(spell.id) then
            player:RemoveSpell(spell.id)
        end
    end
    if player:HasAura(MONK_TIGER_POWER_ID) then
        player:RemoveAura(MONK_TIGER_POWER_ID)
    end
    if player:HasAura(MONK_CHI_AURA_ID) then
        player:RemoveAura(MONK_CHI_AURA_ID)
    end
    return true, "nonclassic_removed"
end

local function OnMonkStarterLogin(_, player)
    if not player or IsBotPlayer(player) or player:GetClass() ~= MONK_CLASS_ID then return end
    local guid = player:GetGUIDLow()
    CreateLuaEvent(function()
        local current = GetPlayerByGUID(guid)
        if current and current:IsInWorld() then
            SpellDraft_ReconcileMonkClassicStarter(current)
        end
    end, LOGIN_RECONCILE_DELAY_MS, 1)
end

RegisterPlayerEvent(3, OnMonkStarterLogin)
RegisterPlayerEvent(13, function(_, player, _)
    SpellDraft_ReconcileMonkClassicStarter(player)
end)
