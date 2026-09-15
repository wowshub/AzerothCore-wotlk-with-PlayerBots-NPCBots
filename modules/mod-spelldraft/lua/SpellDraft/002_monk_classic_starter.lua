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
local MONK_SPEAR_HAND_STRIKE_ID = 9001516
local MONK_FISTS_OF_FURY_ID = 9001518
local MONK_DAMPEN_HARM_ID = 9001520
local MONK_TIGERS_LUST_ID = 9001521
local MONK_FORTIFYING_BREW_ID = 9001522
local MONK_DETOX_ID = 9001523
local MONK_PARALYSIS_ID = 9001524
local MONK_LEG_SWEEP_ID = 9001525
local MONK_REVIVE_ID = 9001526
local MONK_PROVOKE_ID = 9001527
local MONK_ENERGIZING_BREW_ID = 9001528
local MONK_DISABLE_ID = 9001529
local MONK_SPINNING_CRANE_KICK_ID = 9001531
local MONK_NIMBLE_BREW_ID = 9001533
local MONK_FLYING_SERPENT_KICK_ID = 9001535
local MONK_WHITE_TIGER_ID = 9001537
local MONK_CLASSIC_SPELLS = {
    { id = 9001542, minLevel = 52 },
    { id = 9001544, minLevel = 54 },
    { id = 9001545, minLevel = 56 },
    { id = 9001546, minLevel = 58 },
    { id = 9001548, minLevel = 60 },

    { id = 9001538, minLevel = 46 },
    { id = 9001540, minLevel = 48 },
    { id = 9001541, minLevel = 50 },
    { id = MONK_WHITE_TIGER_ID, minLevel = 44 },
    { id = MONK_FLYING_SERPENT_KICK_ID, minLevel = 18 },
    { id = MONK_NIMBLE_BREW_ID, minLevel = 42 },
    { id = MONK_SPINNING_CRANE_KICK_ID, minLevel = 40 },
    { id = MONK_DISABLE_ID, minLevel = 38 },
    { id = MONK_ENERGIZING_BREW_ID, minLevel = 36 },
    { id = MONK_PROVOKE_ID, minLevel = 34 },
    { id = MONK_REVIVE_ID, minLevel = 32 },
    { id = MONK_LEG_SWEEP_ID, minLevel = 30 },
    { id = MONK_PARALYSIS_ID, minLevel = 28 },
    { id = MONK_DETOX_ID, minLevel = 26 },
    { id = MONK_FORTIFYING_BREW_ID, minLevel = 24 },
    { id = MONK_TIGERS_LUST_ID, minLevel = 22 },
    { id = MONK_DAMPEN_HARM_ID, minLevel = 20 },
    { id = MONK_FISTS_OF_FURY_ID, minLevel = 15 },
    { id = MONK_SPEAR_HAND_STRIKE_ID, minLevel = 12 },
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
    if player:HasAura(MONK_SPINNING_CRANE_KICK_ID) then
        player:RemoveAura(MONK_SPINNING_CRANE_KICK_ID)
    end
    player:RemoveAura(9001542)
    player:RemoveAura(9001545)
    player:RemoveAura(9001546)
    player:RemoveAura(9001548)
    player:RemoveAura(9001538)
    player:RemoveAura(9001540)
    player:RemoveAura(9001541)
    player:RemoveAura(MONK_NIMBLE_BREW_ID)
    player:RemoveAura(9001534)
    player:RemoveAura(MONK_FLYING_SERPENT_KICK_ID)
    player:RemoveAura(MONK_WHITE_TIGER_ID)
    if player:HasAura(MONK_TIGER_POWER_ID) then
        player:RemoveAura(MONK_TIGER_POWER_ID)
    end
    if player:HasAura(MONK_CHI_AURA_ID) then
        player:RemoveAura(MONK_CHI_AURA_ID)
    end
    if player:HasAura(MONK_ENERGIZING_BREW_ID) then
        player:RemoveAura(MONK_ENERGIZING_BREW_ID)
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
