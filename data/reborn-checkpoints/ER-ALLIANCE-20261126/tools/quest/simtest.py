# -*- coding: utf-8 -*-
"""Run the two packaged Lua files against a stand-in for the ALE API and walk both factions through the quests."""
import glob, os
from lupa import LuaRuntime

DAY = r'D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261126'
f1 = glob.glob(os.path.join(DAY, 'claudefix_20261126_*ALLY1F_V1_*', '02_*', 'Dark1A.lua'))[0]
f2 = glob.glob(os.path.join(DAY, 'claudefix_20261126_*ALLY1G_V1_*', '02_*', 'Dark2A.lua'))[0]
L = LuaRuntime(unpack_returned_tuples=True)
L.execute(r'''
G, C, O, P, loops, players, errors = {}, {}, {}, {}, {}, {}, {}
local function put(t, a, b, f) t[a] = t[a] or {}; assert(not t[a][b], "double registration " .. a .. "/" .. b); t[a][b] = f end
function RegisterCreatureGossipEvent(e, ev, f) put(G, e, ev, f) end
function RegisterCreatureEvent(e, ev, f) put(C, e, ev, f) end
function RegisterGameObjectEvent(e, ev, f) put(O, e, ev, f) end
function RegisterPlayerEvent(ev, f) P[ev] = P[ev] or {}; table.insert(P[ev], f) end
function CreateLuaEvent(f) table.insert(loops, f) end
function GetPlayersInWorld() return players end
local rawprint = print
function print(s) if tostring(s):find("ERROR") then table.insert(errors, tostring(s)) end rawprint(s) end
function newPlayer(guid, faction, map)
    local p = {quests = {}, credits = {}, faction = faction, map = map, display = 0, x = 0, y = 0, menu = 0, msgs = 0}
    function p:HasQuest(q) return self.quests[q] == true end
    function p:KilledMonsterCredit(e) self.credits[e] = (self.credits[e] or 0) + 1 end
    function p:GossipComplete() self.menu = 0 end
    function p:GossipClearMenu() self.menu = 0 end
    function p:GossipMenuAddItem() self.menu = self.menu + 1 end
    function p:GossipSendMenu() self.sent = self.menu end
    function p:IsMounted() return false end
    function p:Dismount() end
    function p:SetDisplayId(d) self.display = d end
    function p:SetFaction(f) self.faction = f end
    function p:GetFaction() return self.faction end
    function p:DeMorph() self.display = 0 end
    function p:GetGUIDLow() return guid end
    function p:GetObjectType() return "Player" end
    function p:SendBroadcastMessage() self.msgs = self.msgs + 1 end
    function p:GetMapId() return self.map end
    function p:IsAlive() return true end
    function p:GetX() return self.x end
    function p:GetY() return self.y end
    function p:Teleport(m, x, y, z, o) self.map, self.x, self.y = m, x, y end
    players[#players + 1] = p
    return p
end
creature = {SendUnitSay = function() end}
function creature:GetPlayersInRange() return {} end
function creature:RemoveEvents() end
function creature:RegisterEvent() end
function creature:SpawnCreature(e) spawned = e; return self end
function tick() for _, f in ipairs(loops) do f() end end
''')
g = L.globals()
for f in (f1, f2):
    L.execute(open(f, encoding='utf-8').read())
L.execute(r'''
local function hello(npc, p) assert(G[npc][1](1, p, creature) == nil, "gossip hello returned a value " .. npc) end
for _, side in ipairs({
    {team = "alliance", faction = 1, dq = 55981, npc = 156943, dungeon = 55992, finale = 55991, friend = 161350, mapEnd = 0},
    {team = "horde", faction = 2, dq = 59978, npc = 167598, dungeon = 59984, finale = 59985, friend = 167663, mapEnd = 1}}) do
    local p = newPlayer(side.faction * 10, side.faction, 12175)
    hello(side.npc, p); assert(p.display == 0 and p.faction == side.faction and next(p.credits) == nil, "no quest must change nothing")
    p.quests[side.dq] = true
    hello(side.npc, p); assert(p.display == 11567 and p.faction == 14 and p.credits[side.npc] == 1, side.team .. " disguise")
    p.x, p.y = 604, -2064; tick(); assert(p.credits[154103], "chef area")
    hello(153580, p); assert(p.credits[153580] == 1, "gorgroth")
    p.x, p.y = 695, -1897; tick(); assert(p.credits[9100210], "entrance area")
    assert(p.faction == 14, "still disguised while the quest is in the log")
    p.quests[side.dq] = nil; tick(); assert(p.faction == side.faction and p.display == 0, "disguise ends on turn-in")
    p.quests[side.dq] = true; hello(side.npc, p); p.map = 1; tick(); assert(p.faction == side.faction and p.display == 0, "disguise ends off the island")
    p.quests = {}; p.map = 12175; p.x = 0
    for _, fn in ipairs(P[63]) do fn(63, p, {GetId = function() return side.dungeon end}) end
    assert(p.x == 855.40, side.team .. " dungeon teleport")
    p.quests[side.dungeon] = true
    hello(side.friend, p); assert(p.credits[side.friend] == 1, "speak credit")
    p.quests = {[side.finale] = true}
    hello(side.friend, p); assert(p.sent == 2, "finale menu has two options")
    assert(G[side.friend][2](2, p, creature, 0, 2) == nil); assert(p.map == 12175 and not p.credits[244389], "not yet stays")
    G[side.friend][2](2, p, creature, 0, 1); assert(p.map == side.mapEnd and p.credits[244389] == 1, side.team .. " travel")
    print(side.team .. " walk-through ok, ends on map " .. p.map)
end
for _, e in ipairs({9326651, 9339865, 9326652, 9339866}) do assert(O[e] and O[e][14], "object " .. e) end
C[157300][4](4, creature, nil); assert(not spawned); C[156814][4](4, creature, nil); assert(spawned == 156501, "boss flow")
C[156501][4](4, creature, nil)
assert(#errors == 0, table.concat(errors, "\n"))
print("all checks passed")
''')
