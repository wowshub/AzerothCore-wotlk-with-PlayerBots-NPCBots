-- RebornBoarRule.lua (VEH4A V1, 2026-11-26, Claude): the two ride-able giant boars of Exile's Reach only hurt Monstrous Cadavers.
-- Who may ride is decided by the VEH4A SQL (conditions on the spell click). This file stops the stomp / melee of the boar from
-- damaging anything else, so it cannot be used on other quest creatures. Uses the global creature damage hooks, which do not
-- replace the boar's own AI.
local BOARS = { [9167020] = true, [9167021] = true }     -- Horde, Alliance
local CADAVER = 165150

local function filter(event, creature, target)
    if not BOARS[creature:GetEntry()] then return end
    if target and target:GetEntry() == CADAVER then return end
    return 0
end

RegisterAllCreatureEvent(10, filter)     -- ALL_CREATURE_EVENT_ON_MODIFY_MELEE_DAMAGE
RegisterAllCreatureEvent(11, filter)     -- ALL_CREATURE_EVENT_ON_MODIFY_SPELL_DAMAGE_TAKEN
print("[RebornBoarRule] VEH4A V1 loaded: giant boars only damage Monstrous Cadavers")
