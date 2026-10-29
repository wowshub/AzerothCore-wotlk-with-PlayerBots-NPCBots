#include "RebornTreasure.h"
#include "Chat.h"
#include "Config.h"
#include "ConditionMgr.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Item.h"
#include "DBCStores.h"
#include "Log.h"
#include "LootMgr.h"
#include "Mail.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <algorithm>
#include <cmath>
#include <ctime>

namespace
{
    char const* QualityName(uint8 quality)
    {
        return quality == TREASURE_QUALITY_COMMON ? "普通" : (quality == TREASURE_QUALITY_RARE ? "稀有" : "史诗");
    }

    bool IsTreasureEntry(uint32 entry)
    {
        return entry >= GO_TREASURE_ENTRY_FIRST && entry <= GO_TREASURE_ENTRY_LAST;
    }

    uint32 EntryForQuality(uint8 quality)
    {
        if (quality == TREASURE_QUALITY_RARE)
            return GO_TREASURE_CHEST_RARE;
        if (quality == TREASURE_QUALITY_EPIC)
            return GO_TREASURE_CHEST_EPIC;
        return GO_TREASURE_CHEST_COMMON;
    }

    uint32 RandomBetween(uint32 a, uint32 b)
    {
        return urand(std::min(a, b), std::max(a, b));
    }

    // TREASFIX2: where the ground is under a point. A GM who stood in water or on a flying mount put the point
    // at the water surface / in the air, and the chest hung there. The search starts a little above the point
    // and goes down (and finds floors of buildings too, not only the terrain).
    struct Ground
    {
        bool found = false;
        float z = 0.0f;
        bool wet = false;   // the ground is below a water surface
    };

    Ground FindGround(Map* map, float x, float y, float z)
    {
        Ground g;
        if (!map)
            return g;
        float ground = INVALID_HEIGHT;
        float const level = map->GetWaterOrGroundLevel(PHASEMASK_NORMAL, x, y, z + 1.0f, &ground);
        if (ground <= INVALID_HEIGHT + 1.0f)
            return g;
        g.found = true;
        g.z = ground + 0.05f;
        g.wet = level > ground + 0.3f;
        return g;
    }
}

RebornTreasureMgr* RebornTreasureMgr::instance()
{
    static RebornTreasureMgr instance;
    return &instance;
}

void RebornTreasureMgr::LoadConfig()
{
    m_enabled = sConfigMgr->GetOption<bool>("RebornTreasure.Enable", true);
    m_clueCheckIntervalMs = std::max<uint32>(500, sConfigMgr->GetOption<uint32>("RebornTreasure.ClueCheckIntervalMs", 2500));
    m_defaultClueDistance = sConfigMgr->GetOption<float>("RebornTreasure.DefaultClueDistance", 40.0f);
    m_clueSoundId = sConfigMgr->GetOption<uint32>("RebornTreasure.ClueSoundId", 0);
    m_announceMode = sConfigMgr->GetOption<uint8>("RebornTreasure.AnnounceOnClaim", 1);
    m_mailRewardOnFullBag = sConfigMgr->GetOption<bool>("RebornTreasure.MailRewardOnFullBag", true);
    m_debugLog = sConfigMgr->GetOption<bool>("RebornTreasure.DebugLog", false);
    m_defaultRespawnMin = sConfigMgr->GetOption<uint32>("RebornTreasure.DefaultRespawnMinSecs", 300);
    m_defaultRespawnMax = sConfigMgr->GetOption<uint32>("RebornTreasure.DefaultRespawnMaxSecs", 600);

    LOG_INFO("module", "mod-reborn-treasure: config loaded (Enable={}, ClueInterval={}ms, MailOnFull={})",
             m_enabled, m_clueCheckIntervalMs, m_mailRewardOnFullBag);
}

void RebornTreasureMgr::LoadFromDB()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    LoadFromDBLocked();
}

void RebornTreasureMgr::LoadFromDBLocked()
{
    m_spawns.clear();
    m_guidToSpawnId.clear();
    m_clueBySpawn.clear();
    m_opened.clear();
    m_dbReady = false;

    if (!m_enabled)
        return;

    // MAX over every row (also the deactivated ones) so a new id never collides.
    // A missing table gives an empty result: stay idle instead of failing later.
    QueryResult idResult = WorldDatabase.Query("SELECT IFNULL(MAX(spawn_id), 0) FROM reborn_treasure_spawns");
    if (!idResult)
    {
        LOG_WARN("module", "mod-reborn-treasure: table reborn_treasure_spawns is missing; the module stays idle until the TREAS1B SQL is imported.");
        return;
    }
    m_nextSpawnId = idResult->Fetch()[0].Get<uint32>() + 1;
    m_dbReady = true;

    LoadTypesLocked();

    QueryResult result = WorldDatabase.Query(
        "SELECT spawn_id, quality, entry, map, zone_id, position_x, position_y, position_z, "
        "orientation, respawn_time_min, respawn_time_max, last_claimed_time, next_respawn_time, "
        "comment FROM reborn_treasure_spawns WHERE is_active = 1");

    uint32 loadedSpawns = 0;
    if (result)
    {
        do
        {
            Field* fields = result->Fetch();
            TreasureSpawn spawn;
            spawn.spawnId         = fields[0].Get<uint32>();
            spawn.quality         = fields[1].Get<uint8>();
            // TREAS2A: the chest type in the row, when it is one of ours and active; else the quality's chest
            uint32 rowEntry       = fields[2].Get<uint32>();
            auto typeIt           = m_types.find(rowEntry);
            spawn.entry           = (typeIt != m_types.end() && typeIt->second.active) ? rowEntry : EntryForQuality(spawn.quality);
            spawn.mapId           = fields[3].Get<uint16>();
            spawn.zoneId          = fields[4].Get<uint32>();
            spawn.x               = fields[5].Get<float>();
            spawn.y               = fields[6].Get<float>();
            spawn.z               = fields[7].Get<float>();
            spawn.o               = fields[8].Get<float>();
            spawn.respawnMinSecs  = fields[9].Get<uint32>();
            spawn.respawnMaxSecs  = fields[10].Get<uint32>();
            spawn.lastClaimedTime = fields[11].Get<uint64>();
            spawn.nextRespawnTime = fields[12].Get<uint64>();
            spawn.isActive        = true;
            spawn.comment         = fields[13].Get<std::string>();
            uint32 id = spawn.spawnId;
            m_spawns[id] = std::move(spawn);
            ++loadedSpawns;
        } while (result->NextRow());
    }

    QueryResult clueResult = WorldDatabase.Query(
        "SELECT clue_id, spawn_id, clue_text, min_distance, max_distance FROM reborn_treasure_clues ORDER BY clue_id");
    uint32 loadedClues = 0;
    if (clueResult)
    {
        do
        {
            Field* fields = clueResult->Fetch();
            TreasureClue clue;
            clue.clueId      = fields[0].Get<uint32>();
            clue.spawnId     = fields[1].Get<uint32>();
            clue.clueText    = fields[2].Get<std::string>();
            clue.minDistance = fields[3].Get<float>();
            clue.maxDistance = fields[4].Get<float>();
            if (m_clueBySpawn.find(clue.spawnId) == m_clueBySpawn.end()) // the first clue of a spawn wins
            {
                uint32 id = clue.spawnId;
                m_clueBySpawn[id] = std::move(clue);
                ++loadedClues;
            }
        } while (clueResult->NextRow());
    }

    LOG_INFO("module", "mod-reborn-treasure: loaded {} spawns and {} clues.", loadedSpawns, loadedClues);
}

void RebornTreasureMgr::Reload()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto& pair : m_spawns)
        DespawnAllLocked(pair.second);
    LoadConfig();
    LoadFromDBLocked();
}

// Runs from WorldScript::OnUpdate, i.e. on the world thread after the maps have finished
// their update, so touching a Map here cannot race with the map workers.
void RebornTreasureMgr::Update(uint32 diff)
{
    if (!m_enabled || !m_dbReady)
        return;

    // TREASFIX1: close the loot window of whoever emptied a chest. Done every tick and without our lock held: the
    // release fires OnLootStateChanged -> OnChestEmptied, which takes it.
    std::vector<std::pair<ObjectGuid, ObjectGuid>> release;
    bool emptiedWaiting = false;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        release.swap(m_pendingRelease);
    }
    for (auto const& pr : release)
        if (Player* p = ObjectAccessor::FindConnectedPlayer(pr.first))
            if (p->GetSession() && p->IsInWorld() && p->GetLootGUID() == pr.second)
                p->GetSession()->DoLootRelease(pr.second);
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        emptiedWaiting = !m_emptied.empty();
    }

    bool scan = true;
    if (m_updateTimer > diff)
    {
        m_updateTimer -= diff;
        scan = false;
    }
    else
        m_updateTimer = 2000;
    if (!scan && !emptiedWaiting)
        return;

    uint64 now = static_cast<uint64>(time(nullptr));
    std::lock_guard<std::mutex> lock(m_mutex);

    if (m_lootDirty)
    {
        // the GM panel changed `gameobject_loot_template`: read it again once, here, while no map is updating
        m_lootDirty = false;
        LoadLootTemplates_Gameobject();
        LootTemplates_Gameobject.CheckLootRefs();
        // TREAS3A: like `.reload gameobject_loot_template`: rebuilding the loot tables drops every condition attached to
        // them (ours and the other gameobjects'), so the conditions are read again and put back
        sConditionMgr->LoadConditions(true);
    }

    // TREAS2A4: a chest that was looted empty is removed here (an unowned summoned chest would otherwise stay and refill)
    for (ObjectGuid const& emptied : m_emptied)
    {
        auto idIt = m_guidToSpawnId.find(emptied);
        if (idIt == m_guidToSpawnId.end())
            continue;
        auto spawnIt = m_spawns.find(idIt->second);
        if (spawnIt == m_spawns.end())
            continue;
        for (auto const& chest : spawnIt->second.chests)
            if (chest.second == emptied)
            {
                DespawnChestLocked(spawnIt->second, chest.first);
                break;
            }
    }
    m_emptied.clear();
    if (!scan)
        return;

    for (auto& pair : m_spawns)
    {
        TreasureSpawn& spawn = pair.second;
        std::unordered_set<uint32> seen;

        // Every live copy of the map: the open world is one copy, a dungeon is one copy per group.
        // The map manager holds its lock while it walks them, so only collect the pointers there.
        std::vector<Map*> maps;
        sMapMgr->DoForAllMapsWithMapId(spawn.mapId, [&maps](Map* map) { maps.push_back(map); });

        for (Map* map : maps)
        {
            uint32 const instanceId = map->GetInstanceId();
            seen.insert(instanceId);

            auto it = spawn.chests.find(instanceId);
            if (it != spawn.chests.end())
            {
                if (map->GetGameObject(it->second))
                    continue;

                // The chest is gone without being opened (its grid was unloaded). Summoned objects
                // are not saved, so forget it and let it come back.
                m_guidToSpawnId.erase(it->second);
                m_opened.erase(it->second);
                spawn.chests.erase(it);
            }

            if (map->Instanceable())
            {
                if (spawn.claimedInstances.count(instanceId))  // once per dungeon run
                    continue;
            }
            else if (now < spawn.nextRespawnTime)
                continue;

            // only summon where players can actually see it: a chest put into an idle grid
            // would just be thrown away again
            if (map->IsGridLoaded(spawn.x, spawn.y))
                SpawnChestLocked(spawn, map);
        }

        // forget the dungeon copies that no longer exist (the group left, the instance reset)
        for (auto it = spawn.chests.begin(); it != spawn.chests.end();)
        {
            if (seen.count(it->first))
                ++it;
            else
            {
                m_guidToSpawnId.erase(it->second);
                m_opened.erase(it->second);
                it = spawn.chests.erase(it);
            }
        }
        for (auto it = spawn.claimedInstances.begin(); it != spawn.claimedInstances.end();)
            it = seen.count(*it) ? std::next(it) : spawn.claimedInstances.erase(it);
    }
}

bool RebornTreasureMgr::SpawnChestLocked(TreasureSpawn& spawn, Map* map)
{
    if (!map || map->GetId() != spawn.mapId)
        return false;

    uint32 const instanceId = map->GetInstanceId();
    if (spawn.chests.count(instanceId))
        return false;

    // TREASFIX2: on the ground, whatever height the GM was standing at when the point was made
    float z = spawn.z;
    Ground const ground = FindGround(map, spawn.x, spawn.y, spawn.z);
    spawn.wet = ground.found && ground.wet;
    if (ground.found && std::fabs(ground.z - spawn.z) > 0.5f)
        z = ground.z;

    GameObject* go = map->SummonGameObject(spawn.entry, spawn.x, spawn.y, z, spawn.o, 0.0f, 0.0f, 0.0f, 0.0f, 0);
    if (!go)
    {
        LOG_ERROR("module", "mod-reborn-treasure: could not summon chest: spawnId={}, entry={}", spawn.spawnId, spawn.entry);
        return false;
    }

    spawn.chests[instanceId] = go->GetGUID();
    m_guidToSpawnId[go->GetGUID()] = spawn.spawnId;

    if (m_debugLog)
        LOG_INFO("module", "mod-reborn-treasure: chest summoned: spawnId={}, guid={}, map={}, instance={}", spawn.spawnId, go->GetGUID().ToString(), spawn.mapId, instanceId);
    return true;
}

void RebornTreasureMgr::DespawnChestLocked(TreasureSpawn& spawn, uint32 instanceId, Map* hint)
{
    auto it = spawn.chests.find(instanceId);
    if (it == spawn.chests.end())
        return;

    Map* map = hint ? hint : sMapMgr->FindMap(spawn.mapId, instanceId);
    if (map)
        if (GameObject* go = map->GetGameObject(it->second))
            go->Delete();

    m_guidToSpawnId.erase(it->second);
    m_opened.erase(it->second);
    m_chestGold.erase(it->second);
    spawn.chests.erase(it);
}

void RebornTreasureMgr::DespawnAllLocked(TreasureSpawn& spawn)
{
    std::vector<uint32> ids;
    for (auto const& pair : spawn.chests)
        ids.push_back(pair.first);
    for (uint32 id : ids)
        DespawnChestLocked(spawn, id);
    spawn.claimedInstances.clear();
}

void RebornTreasureMgr::OnChestEmptied(ObjectGuid guid)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_guidToSpawnId.count(guid))
        m_emptied.insert(guid);
}

bool RebornTreasureMgr::OnChestUsed(Player* player, GameObject* go)
{
    if (!m_enabled || !player || !go || !IsTreasureEntry(go->GetEntry()))
        return false;

    {
        std::lock_guard<std::mutex> lock(m_mutex);

        // A chest of ours that is no longer tracked is swallowed so the client never gets an
        // empty native loot window for it.
        auto guidIt = m_guidToSpawnId.find(go->GetGUID());
        if (guidIt == m_guidToSpawnId.end() || m_emptied.count(go->GetGUID()))
            return true;

        auto spawnIt = m_spawns.find(guidIt->second);
        if (spawnIt == m_spawns.end())
            return true;

        // Playerbots wander around opening things; a treasure is for real players.
        WorldSession* session = player->GetSession();
        if (!session || session->IsBot())
            return true;

        // TREAS2A: the first open counts (log, announcement, next respawn); later clicks on the same
        // chest only show the loot window again, so a half-emptied chest can be finished.
        if (m_opened.insert(go->GetGUID()).second)
        {
            TreasureSpawn& spawn = spawnIt->second;
            uint32 spawnId = spawn.spawnId;
            Map* chestMap = go->GetMap();
            uint32 const instanceId = chestMap ? chestMap->GetInstanceId() : 0;

            // audit log: what is inside is the chest's native loot, so only the chest and the opener are logged
            std::string safeName = player->GetName();
            WorldDatabase.EscapeString(safeName);
            WorldDatabase.Execute(
                "INSERT INTO reborn_treasure_claim_log (spawn_id, player_guid, player_name, reward_money, reward_items, delivery_method) "
                "VALUES ({}, {}, '{}', 0, 'NATIVE_LOOT entry {}', 'LOOT_WINDOW')",
                spawnId, player->GetGUID().GetCounter(), safeName, go->GetEntry());

            // zone announcement (Map::SendZoneText, the only zone broadcast this core has)
            if (m_announceMode == 1)
            {
                auto typeIt = m_types.find(spawn.entry);
                std::string typeName = typeIt != m_types.end() ? typeIt->second.name : std::string(QualityName(spawn.quality));
                std::string broadcastMsg = std::string("|cff00ff00[野外寻宝]|r 探险者 |cffffffff") + player->GetName() +
                                           "|r 成功开启了一处 |cffffd700" + typeName + "|r 宝箱！";
                if (chestMap)
                    chestMap->SendZoneText(spawn.zoneId, broadcastMsg.c_str());
            }

            // next respawn: the open world waits out the timer; a dungeon chest is once per run
            uint64 now = static_cast<uint64>(time(nullptr));
            if (chestMap && chestMap->Instanceable())
                spawn.claimedInstances.insert(instanceId);
            else
            {
                spawn.lastClaimedTime = now;
                spawn.nextRespawnTime = now + RandomBetween(spawn.respawnMinSecs, spawn.respawnMaxSecs);
                WorldDatabase.Execute("UPDATE reborn_treasure_spawns SET last_claimed_time = {}, next_respawn_time = {} WHERE spawn_id = {}",
                                      spawn.lastClaimedTime, spawn.nextRespawnTime, spawnId);
            }

            ChatHandler(session).SendSysMessage("你成功开启了野外寻宝宝箱！");
        }
    }

    // the standard loot window (items from gameobject_loot_template, gold from the template's min/max gold);
    // the chest is consumable, so the core removes it once everything was taken
    player->SendLoot(go->GetGUID(), LOOT_CORPSE);

    // TREAS2B: the gold as rolled; mod-dungeon-scale only scales it when it is taken
    if (go->loot.gold > 0)
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_chestGold[go->GetGUID()] = go->loot.gold;
    }

    // TREASFIX1: a chest that has nothing left (a second click after it was emptied, or a chest with an empty table
    // and no gold): the client opens no window for it and never sends a release, so the character would stay kneeling
    if (go->loot.isLooted() && player->GetLootGUID() == go->GetGUID())
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_pendingRelease.emplace_back(player->GetGUID(), go->GetGUID());
    }
    return true;
}

void RebornTreasureMgr::OnLootTaken(Player* player, bool goldAboutToGo)
{
    if (!m_enabled || !player)
        return;
    ObjectGuid const guid = player->GetLootGUID();
    if (!guid.IsGameObject() || !IsTreasureEntry(guid.GetEntry()))
        return;
    Map* map = player->GetMap();
    GameObject* go = map ? map->GetGameObject(guid) : nullptr;
    if (!go)
        return;
    if (go->loot.unlootedCount > 0 || (go->loot.gold > 0 && !goldAboutToGo))
        return;   // something is still in it

    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_guidToSpawnId.count(guid))
        m_pendingRelease.emplace_back(player->GetGUID(), guid);
}

void RebornTreasureMgr::OnBeforeLootMoney(Player* player, Loot* loot)
{
    if (!m_enabled || !player || !loot)
        return;
    ObjectGuid guid = player->GetLootGUID();
    if (!guid.IsGameObject() || !IsTreasureEntry(guid.GetEntry()))
        return;

    std::lock_guard<std::mutex> lock(m_mutex);
    auto goldIt = m_chestGold.find(guid);
    auto typeIt = m_types.find(guid.GetEntry());
    if (goldIt == m_chestGold.end() || typeIt == m_types.end() || typeIt->second.dungeonGoldScale)
        return;
    loot->gold = goldIt->second;   // undo a scaling that ran before us
}

void RebornTreasureMgr::OnLootMoney(Player* player, uint32 gold)
{
    if (!m_enabled || !player)
        return;
    ObjectGuid guid = player->GetLootGUID();
    if (!guid.IsGameObject() || !IsTreasureEntry(guid.GetEntry()))
        return;
    OnLootTaken(player, true);   // TREASFIX1: the core zeroes loot->gold right after this hook

    uint32 full = 0;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        auto goldIt = m_chestGold.find(guid);
        if (goldIt == m_chestGold.end())
            return;
        auto typeIt = m_types.find(guid.GetEntry());
        if (typeIt != m_types.end() && !typeIt->second.dungeonGoldScale)
            full = goldIt->second;
        m_chestGold.erase(goldIt);   // the gold is taken once
    }

    // a scaling that ran after us: pay the difference
    if (full > gold)
    {
        player->ModifyMoney(full - gold);
        ChatHandler(player->GetSession()).PSendSysMessage("|cffffd700[野外寻宝]|r 宝箱金币不随副本人数缩放，已补足 {} 铜。", full - gold);
    }
}

void RebornTreasureMgr::CollectNearby(uint16 mapId, uint32 instanceId, float px, float py, float pz, std::vector<TreasureNearby>& out)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto const& pair : m_spawns)
    {
        TreasureSpawn const& spawn = pair.second;
        if (spawn.mapId != mapId || !spawn.chests.count(instanceId))
            continue;

        float minDist = 5.0f;
        float maxDist = m_defaultClueDistance;
        std::string text = "你感到附近的空气中弥漫着微弱的宝物灵气，似乎有什么东西藏在附近...";
        auto clueIt = m_clueBySpawn.find(spawn.spawnId);
        if (clueIt != m_clueBySpawn.end())
        {
            minDist = clueIt->second.minDistance;
            maxDist = clueIt->second.maxDistance;
            if (!clueIt->second.clueText.empty())
                text = clueIt->second.clueText;
        }

        float dx = px - spawn.x;
        float dy = py - spawn.y;
        float dz = pz - spawn.z;
        float distSq = dx * dx + dy * dy + dz * dz;
        if (distSq >= minDist * minDist && distSq <= maxDist * maxDist)
            out.push_back({ spawn.spawnId, std::move(text) });
    }
}

std::vector<TreasureSpawn> RebornTreasureMgr::Snapshot()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    std::vector<TreasureSpawn> copy;
    copy.reserve(m_spawns.size());
    for (auto const& pair : m_spawns)
        copy.push_back(pair.second);
    std::sort(copy.begin(), copy.end(), [](TreasureSpawn const& a, TreasureSpawn const& b) { return a.spawnId < b.spawnId; });
    return copy;
}

uint32 RebornTreasureMgr::AddSpawn(uint32 kind, uint16 mapId, uint32 zoneId, float x, float y, float z, float o, uint32 respawnSecs, std::string comment, Map* where)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_dbReady)
        return 0;

    if (comment.size() > 200)
        comment.resize(200);

    uint32 const entry = EntryForKindLocked(kind);
    if (!entry)
        return 0;
    auto typeIt = m_types.find(entry);
    uint8 const quality = typeIt != m_types.end() ? typeIt->second.rarity : static_cast<uint8>(kind);

    if (where && where->GetId() == mapId)   // TREASFIX2: the saved point is on the ground, not where the GM floated
    {
        Ground const g = FindGround(where, x, y, z);
        if (g.found)
            z = g.z;
    }

    TreasureSpawn spawn;
    spawn.spawnId = m_nextSpawnId++;
    spawn.quality = quality;
    spawn.entry = entry;
    spawn.mapId = mapId;
    spawn.zoneId = zoneId;
    spawn.x = x;
    spawn.y = y;
    spawn.z = z;
    spawn.o = o;
    spawn.respawnMinSecs = respawnSecs > 0 ? respawnSecs : (typeIt != m_types.end() ? typeIt->second.respawnMin : m_defaultRespawnMin);
    spawn.respawnMaxSecs = respawnSecs > 0 ? spawn.respawnMinSecs + 120 : (typeIt != m_types.end() ? typeIt->second.respawnMax : spawn.respawnMinSecs + 120);
    spawn.nextRespawnTime = static_cast<uint64>(time(nullptr));
    spawn.comment = comment;

    // the id is ours (chosen under the lock), so there is no "what id did the database pick" guess
    std::string safeComment = comment;
    WorldDatabase.EscapeString(safeComment);
    WorldDatabase.Execute(
        "INSERT INTO reborn_treasure_spawns (spawn_id, quality, entry, map, zone_id, position_x, position_y, position_z, orientation, "
        "respawn_time_min, respawn_time_max, next_respawn_time, is_active, comment) VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, 1, '{}')",
        spawn.spawnId, quality, spawn.entry, mapId, zoneId, x, y, z, o, spawn.respawnMinSecs, spawn.respawnMaxSecs, spawn.nextRespawnTime, safeComment);

    uint32 id = spawn.spawnId;
    m_spawns[id] = std::move(spawn);
    SpawnChestLocked(m_spawns[id], where);  // in the map the GM stands in: the dungeon copy, or the open world
    return id;
}

bool RebornTreasureMgr::RemoveSpawn(uint32 spawnId)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_spawns.find(spawnId);
    if (it == m_spawns.end())
        return false;

    DespawnAllLocked(it->second);
    m_spawns.erase(it);
    m_clueBySpawn.erase(spawnId);

    WorldDatabase.Execute("DELETE FROM reborn_treasure_spawns WHERE spawn_id = {}", spawnId);
    WorldDatabase.Execute("DELETE FROM reborn_treasure_clues WHERE spawn_id = {}", spawnId);
    return true;
}

bool RebornTreasureMgr::ForceRespawn(uint32 spawnId, Map* where)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_spawns.find(spawnId);
    if (it == m_spawns.end())
        return false;

    TreasureSpawn& spawn = it->second;
    if (where && where->GetId() == spawn.mapId)
    {
        // the GM is standing in a copy of that map (a dungeon): put the chest in this copy
        DespawnChestLocked(spawn, where->GetInstanceId(), where);
        spawn.claimedInstances.erase(where->GetInstanceId());
        return SpawnChestLocked(spawn, where);
    }

    // otherwise the open-world copy
    DespawnChestLocked(spawn, 0);
    spawn.nextRespawnTime = static_cast<uint64>(time(nullptr));
    return SpawnChestLocked(spawn, sMapMgr->FindMap(spawn.mapId, 0));
}

// ------------------------------------------------------------------ TREAS2C: spawn management

bool RebornTreasureMgr::GetSpawn(uint32 spawnId, TreasureSpawn& out)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_spawns.find(spawnId);
    if (it == m_spawns.end())
        return false;
    out = it->second;
    return true;
}

bool RebornTreasureMgr::MoveSpawn(uint32 spawnId, uint16 mapId, uint32 zoneId, float x, float y, float z, float o, Map* where)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_spawns.find(spawnId);
    if (it == m_spawns.end())
        return false;

    if (where && where->GetId() == mapId)   // TREASFIX2
    {
        Ground const g = FindGround(where, x, y, z);
        if (g.found)
            z = g.z;
    }

    TreasureSpawn& spawn = it->second;
    DespawnAllLocked(spawn);   // the old chests go; the new ones come with the next tick (or now, where the GM stands)
    spawn.mapId = mapId;
    spawn.zoneId = zoneId;
    spawn.x = x;
    spawn.y = y;
    spawn.z = z;
    spawn.o = o;
    spawn.nextRespawnTime = static_cast<uint64>(time(nullptr));
    WorldDatabase.Execute(
        "UPDATE reborn_treasure_spawns SET map = {}, zone_id = {}, position_x = {}, position_y = {}, position_z = {}, "
        "orientation = {}, next_respawn_time = {} WHERE spawn_id = {}",
        mapId, zoneId, x, y, z, o, spawn.nextRespawnTime, spawnId);
    if (where && where->GetId() == mapId)
        SpawnChestLocked(spawn, where);
    return true;
}

bool RebornTreasureMgr::SetSpawnRespawn(uint32 spawnId, uint32 minSecs, uint32 maxSecs)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_spawns.find(spawnId);
    if (it == m_spawns.end())
        return false;
    minSecs = std::max<uint32>(10, minSecs);
    maxSecs = std::max(minSecs, maxSecs);
    it->second.respawnMinSecs = minSecs;
    it->second.respawnMaxSecs = maxSecs;
    WorldDatabase.Execute("UPDATE reborn_treasure_spawns SET respawn_time_min = {}, respawn_time_max = {} WHERE spawn_id = {}",
                          minSecs, maxSecs, spawnId);
    return true;
}

bool RebornTreasureMgr::SetSpawnComment(uint32 spawnId, std::string comment)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_spawns.find(spawnId);
    if (it == m_spawns.end())
        return false;
    if (comment.size() > 200)
        comment.resize(200);
    it->second.comment = comment;
    WorldDatabase.EscapeString(comment);
    WorldDatabase.Execute("UPDATE reborn_treasure_spawns SET comment = '{}' WHERE spawn_id = {}", comment, spawnId);
    return true;
}

std::string RebornTreasureMgr::GetSpawnClue(uint32 spawnId)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_clueBySpawn.find(spawnId);
    return it != m_clueBySpawn.end() ? it->second.clueText : std::string();
}

bool RebornTreasureMgr::SetSpawnClue(uint32 spawnId, std::string const& text)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_spawns.count(spawnId))
        return false;
    WorldDatabase.Execute("DELETE FROM reborn_treasure_clues WHERE spawn_id = {}", spawnId);
    if (text.empty())
    {
        m_clueBySpawn.erase(spawnId);
        return true;
    }
    std::string safe = text.size() > 400 ? text.substr(0, 400) : text;
    WorldDatabase.EscapeString(safe);
    WorldDatabase.Execute(
        "INSERT INTO reborn_treasure_clues (spawn_id, clue_text, min_distance, max_distance, comment) VALUES ({}, '{}', 5, 45, 'TREAS2C panel')",
        spawnId, safe);
    TreasureClue clue;
    clue.spawnId = spawnId;
    clue.clueText = text;
    clue.minDistance = 5.0f;
    clue.maxDistance = 45.0f;
    m_clueBySpawn[spawnId] = std::move(clue);
    return true;
}

bool RebornTreasureMgr::SetSpawnType(uint32 spawnId, uint32 entry, std::string& err)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_spawns.find(spawnId);
    if (it == m_spawns.end())
    {
        err = "没有这个点位";
        return false;
    }
    auto typeIt = m_types.find(entry);
    if (typeIt == m_types.end() || !typeIt->second.active)
    {
        err = "这种宝箱不存在或没有启用";
        return false;
    }
    TreasureSpawn& spawn = it->second;
    DespawnAllLocked(spawn);
    spawn.entry = entry;
    spawn.quality = typeIt->second.rarity;
    spawn.nextRespawnTime = static_cast<uint64>(time(nullptr));
    WorldDatabase.Execute("UPDATE reborn_treasure_spawns SET entry = {}, quality = {}, next_respawn_time = {} WHERE spawn_id = {}",
                          entry, uint32(spawn.quality), spawn.nextRespawnTime, spawnId);
    return true;
}

RebornTreasureMgr::SnapResult RebornTreasureMgr::SnapSpawns(uint32 spawnId, Map* where)
{
    SnapResult r;
    std::lock_guard<std::mutex> lock(m_mutex);
    for (auto& pair : m_spawns)
    {
        TreasureSpawn& s = pair.second;
        if (spawnId && s.spawnId != spawnId)
            continue;
        Map* map = (where && where->GetId() == s.mapId) ? where : sMapMgr->FindMap(s.mapId, 0);
        Ground const g = FindGround(map, s.x, s.y, s.z);
        if (!g.found)
        {
            ++r.skipped;
            continue;
        }
        s.wet = g.wet;
        if (g.wet)
            ++r.wet;
        if (std::fabs(g.z - s.z) <= 0.25f)
            continue;
        s.z = g.z;
        WorldDatabase.Execute("UPDATE reborn_treasure_spawns SET position_z = {} WHERE spawn_id = {}", s.z, s.spawnId);
        DespawnAllLocked(s);   // the chest comes back at the new height at the next tick
        s.nextRespawnTime = static_cast<uint64>(time(nullptr));
        ++r.moved;
    }
    return r;
}

// ------------------------------------------------------------------ TREAS2A: chest types

uint32 RebornTreasureMgr::EntryForKindLocked(uint32 kind) const
{
    if (kind >= 1 && kind <= 3)
        return EntryForQuality(static_cast<uint8>(kind));
    auto it = m_types.find(kind);
    return (it != m_types.end() && it->second.active) ? kind : 0;
}

void RebornTreasureMgr::LoadTypesLocked()
{
    m_types.clear();

    // TREAS2B: dungeon_gold_scale comes with the TREAS2B SQL; without it every type pays full gold
    m_hasScaleColumn = false;
    if (QueryResult col = WorldDatabase.Query(
            "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() "
            "AND TABLE_NAME = 'reborn_treasure_types' AND COLUMN_NAME = 'dungeon_gold_scale'"))
        m_hasScaleColumn = col->Fetch()[0].Get<uint64>() > 0;

    QueryResult result = WorldDatabase.Query(
        "SELECT entry, name, icon, display_id, size, gold_min, gold_max, rarity, respawn_min, respawn_max, is_active, {} "
        "FROM reborn_treasure_types ORDER BY entry", m_hasScaleColumn ? "dungeon_gold_scale" : "0");
    if (result)
    {
        do
        {
            Field* f = result->Fetch();
            TreasureType t;
            t.entry      = f[0].Get<uint32>();
            t.name       = f[1].Get<std::string>();
            t.icon       = f[2].Get<std::string>();
            t.displayId  = f[3].Get<uint32>();
            t.size       = f[4].Get<float>();
            t.goldMin    = f[5].Get<uint32>();
            t.goldMax    = f[6].Get<uint32>();
            t.rarity     = f[7].Get<uint8>();
            t.respawnMin = f[8].Get<uint32>();
            t.respawnMax = f[9].Get<uint32>();
            t.active     = f[10].Get<bool>();
            t.dungeonGoldScale = f[11].Get<uint32>() != 0;
            if (!IsTreasureEntry(t.entry))
                continue;
            m_types[t.entry] = t;
        } while (result->NextRow());
    }
    else
    {
        // the types table is missing: keep the three original chests so spawns still work
        LOG_WARN("module", "mod-reborn-treasure: table reborn_treasure_types is missing or empty; import the TREAS2A SQL.");
        struct Def { uint32 entry; char const* name; float size; uint32 gmin, gmax; uint8 rarity; uint32 rmin, rmax; };
        Def const defs[] = {
            { GO_TREASURE_CHEST_COMMON, "普通宝箱", 1.0f, 5000, 20000, 1, 300, 600 },
            { GO_TREASURE_CHEST_RARE, "稀有宝箱", 1.3f, 30000, 80000, 2, 600, 1200 },
            { GO_TREASURE_CHEST_EPIC, "史诗宝箱", 1.6f, 100000, 300000, 3, 1200, 2400 } };
        for (Def const& d : defs)
        {
            TreasureType t;
            t.entry = d.entry; t.name = d.name; t.size = d.size; t.goldMin = d.gmin; t.goldMax = d.gmax;
            t.rarity = d.rarity; t.respawnMin = d.rmin; t.respawnMax = d.rmax;
            m_types[t.entry] = t;
        }
    }

    for (auto const& pair : m_types)
    {
        std::string err;
        if (!ApplyTypeLocked(pair.second, err))
            LOG_WARN("module", "mod-reborn-treasure: chest type {} not applied: {}", pair.first, err);
    }
    LOG_INFO("module", "mod-reborn-treasure: loaded {} chest types.", m_types.size());
}

bool RebornTreasureMgr::ApplyTypeLocked(TreasureType const& type, std::string& err)
{
    // The core has no runtime reload of gameobject_template, so the module writes the fields it owns into
    // the in-memory template. Chests already standing share that template, so they change at once.
    GameObjectTemplate* tpl = const_cast<GameObjectTemplate*>(sObjectMgr->GetGameObjectTemplate(type.entry));
    if (!tpl || tpl->type != GAMEOBJECT_TYPE_CHEST)
    {
        err = "宝箱模板不存在，请先导入 TREAS2A 的 SQL（world 库）";
        return false;
    }
    tpl->displayId = type.displayId;
    tpl->size = type.size;
    tpl->name = type.name;
    tpl->IconName.clear();            // an empty icon name gives the loot-bag cursor
    tpl->chest.lootId = type.entry;   // loot rows use the chest's own entry
    tpl->chest.consumable = 1;        // gone once everything was taken
    tpl->chest.lockId = 57; // TREAS2A3: same lock as the stock "Battered Chest", so the client opens it the native way

    if (GameObjectTemplateAddon* addon = const_cast<GameObjectTemplateAddon*>(sObjectMgr->GetGameObjectTemplateAddon(type.entry)))
    {
        addon->mingold = std::min(type.goldMin, type.goldMax);
        addon->maxgold = std::max(type.goldMin, type.goldMax);
    }
    else if (type.goldMax > 0)
    {
        err = "该宝箱缺少 gameobject_template_addon 行，金币设置不会生效（导入 TREAS2A 的 SQL）";
        // the chest itself still works, only the gold is missing
    }
    return true;
}

void RebornTreasureMgr::RefreshEntryLocked(uint32 entry)
{
    // chests standing in the world keep the model the client saw: put them back, they come up again at once
    uint64 now = static_cast<uint64>(time(nullptr));
    for (auto& pair : m_spawns)
    {
        TreasureSpawn& spawn = pair.second;
        if (spawn.entry != entry)
            continue;
        DespawnAllLocked(spawn);
        spawn.nextRespawnTime = now;
    }
}

std::vector<TreasureType> RebornTreasureMgr::Types()
{
    std::lock_guard<std::mutex> lock(m_mutex);
    std::vector<TreasureType> out;
    for (auto const& pair : m_types)
        out.push_back(pair.second);
    return out;
}

bool RebornTreasureMgr::GetType(uint32 entry, TreasureType& out)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    auto it = m_types.find(entry);
    if (it == m_types.end())
        return false;
    out = it->second;
    return true;
}

bool RebornTreasureMgr::SaveType(TreasureType const& in, std::string& err)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (!m_dbReady)
    {
        err = "数据表还没有导入";
        return false;
    }
    if (!IsTreasureEntry(in.entry))
    {
        err = "宝箱编号必须在 990200-990299";
        return false;
    }

    TreasureType t = in;
    if (t.name.empty())
        t.name = "宝箱";
    if (t.name.size() > 60)
        t.name.resize(60);
    if (t.icon.size() > 120)
        t.icon.resize(120);
    t.size = std::max(0.3f, std::min(t.size, 4.0f));
    t.rarity = std::max<uint8>(1, std::min<uint8>(t.rarity, 3));
    t.respawnMin = std::max<uint32>(30, t.respawnMin);
    t.respawnMax = std::max(t.respawnMin, t.respawnMax);
    if (t.goldMin > t.goldMax)
        std::swap(t.goldMin, t.goldMax);
    if (t.displayId && !sGameObjectDisplayInfoStore.LookupEntry(t.displayId))
    {
        err = "没有这个外观编号";
        return false;
    }

    if (!ApplyTypeLocked(t, err))
        return false;

    m_types[t.entry] = t;

    std::string name = t.name, icon = t.icon;
    WorldDatabase.EscapeString(name);
    WorldDatabase.EscapeString(icon);
    WorldDatabase.Execute(
        "REPLACE INTO reborn_treasure_types (entry, name, icon, display_id, size, gold_min, gold_max, rarity, respawn_min, respawn_max, is_active) "
        "VALUES ({}, '{}', '{}', {}, {}, {}, {}, {}, {}, {}, {})",
        t.entry, name, icon, t.displayId, t.size, t.goldMin, t.goldMax, uint32(t.rarity), t.respawnMin, t.respawnMax, t.active ? 1 : 0);
    if (m_hasScaleColumn)
        WorldDatabase.Execute("UPDATE reborn_treasure_types SET dungeon_gold_scale = {} WHERE entry = {}", t.dungeonGoldScale ? 1 : 0, t.entry);
    // the template's gold lives in the addon table too, so a restart keeps it even without the types table
    WorldDatabase.Execute("REPLACE INTO gameobject_template_addon (entry, faction, flags, mingold, maxgold, artkit0, artkit1, artkit2, artkit3) "
                          "VALUES ({}, 0, 0, {}, {}, 0, 0, 0, 0)", t.entry, t.goldMin, t.goldMax);

    RefreshEntryLocked(t.entry);
    err.clear();
    return true;
}

uint32 RebornTreasureMgr::NewType(std::string const& name, std::string& err)
{
    uint32 entry = 0;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        for (uint32 e = GO_TREASURE_ENTRY_FIRST; e <= GO_TREASURE_ENTRY_LAST; ++e)
        {
            if (m_types.count(e))
                continue;
            if (!sObjectMgr->GetGameObjectTemplate(e))   // no template row: nothing to hang a type on
                continue;
            entry = e;
            break;
        }
    }
    if (!entry)
    {
        err = "没有空闲的宝箱编号（990200-990299 已用完，或模板没导入）";
        return 0;
    }
    TreasureType t;
    t.entry = entry;
    t.name = name.empty() ? "新宝箱" : name;
    t.goldMin = 0;
    t.goldMax = 0;
    return SaveType(t, err) ? entry : 0;
}

uint32 RebornTreasureMgr::CopyType(uint32 from, std::string& err)
{
    TreasureType src;
    if (!GetType(from, src))
    {
        err = "没有这种宝箱";
        return 0;
    }
    std::string name = src.name + " 副本";
    uint32 entry = NewType(name, err);
    if (!entry)
        return 0;
    TreasureType t = src;
    t.entry = entry;
    t.name = name;
    if (!SaveType(t, err))
        return 0;
    WorldDatabase.Execute(
        "INSERT INTO gameobject_loot_template (Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment) "
        "SELECT {}, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, 'TREAS2B copy' "
        "FROM gameobject_loot_template WHERE Entry = {}", entry, from);
    WorldDatabase.Execute(   // TREAS3A: the conditions of the loot lines come along
        "INSERT INTO conditions (SourceTypeOrReferenceId, SourceGroup, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, "
        "ConditionTarget, ConditionValue1, ConditionValue2, ConditionValue3, NegativeCondition, ErrorType, ErrorTextId, ScriptName, Comment) "
        "SELECT 4, {}, SourceEntry, SourceId, ElseGroup, ConditionTypeOrReference, ConditionTarget, ConditionValue1, ConditionValue2, "
        "ConditionValue3, NegativeCondition, ErrorType, ErrorTextId, ScriptName, 'TREAS3A copy' "
        "FROM conditions WHERE SourceTypeOrReferenceId = 4 AND SourceGroup = {}", entry, from);
    MarkLootDirty();
    return entry;
}

bool RebornTreasureMgr::DeleteType(uint32 entry, std::string& err)
{
    std::lock_guard<std::mutex> lock(m_mutex);
    if (entry >= GO_TREASURE_CHEST_COMMON && entry <= GO_TREASURE_CHEST_EPIC)
    {
        err = "三种基础宝箱不能删除";
        return false;
    }
    if (!m_types.count(entry))
    {
        err = "没有这种宝箱";
        return false;
    }
    for (auto const& pair : m_spawns)
        if (pair.second.entry == entry)
        {
            err = "还有点位在用这种宝箱，先 .treasure remove 那些点位";
            return false;
        }
    m_types.erase(entry);
    WorldDatabase.Execute("DELETE FROM reborn_treasure_types WHERE entry = {}", entry);
    WorldDatabase.Execute("DELETE FROM gameobject_loot_template WHERE Entry = {}", entry);
    WorldDatabase.Execute("DELETE FROM conditions WHERE SourceTypeOrReferenceId = 4 AND SourceGroup = {}", entry);   // TREAS3A
    m_lootDirty = true;
    return true;
}

class RebornTreasureGameObjectScript : public GameObjectScript
{
public:
    RebornTreasureGameObjectScript() : GameObjectScript("go_reborn_treasure_chest") { }

    bool OnGossipHello(Player* player, GameObject* go) override
    {
        return sRebornTreasure->OnChestUsed(player, go);
    }

    void OnLootStateChanged(GameObject* go, uint32 state, Unit* /*unit*/) override
    {
        // the last item and the gold were taken: the core marks the chest done
        if (go && state == GO_JUST_DEACTIVATED)
            sRebornTreasure->OnChestEmptied(go->GetGUID());
    }
};

class RebornTreasureMoneyPlayerScript : public PlayerScript
{
public:
    RebornTreasureMoneyPlayerScript() : PlayerScript("RebornTreasureMoneyPlayerScript", { PLAYERHOOK_ON_BEFORE_LOOT_MONEY, PLAYERHOOK_ON_LOOT_ITEM }) { }

    // TREASFIX1: the unlooted counter was already lowered when this runs
    void OnPlayerLootItem(Player* player, Item* /*item*/, uint32 /*count*/, ObjectGuid /*lootguid*/) override
    {
        sRebornTreasure->OnLootTaken(player, false);
    }

    void OnPlayerBeforeLootMoney(Player* player, Loot* loot) override
    {
        sRebornTreasure->OnBeforeLootMoney(player, loot);
    }
};

class RebornTreasureLootScript : public LootScript
{
public:
    RebornTreasureLootScript() : LootScript("RebornTreasureLootScript", { LOOTHOOK_ON_LOOT_MONEY }) { }

    void OnLootMoney(Player* player, uint32 gold) override
    {
        sRebornTreasure->OnLootMoney(player, gold);
    }
};

class RebornTreasureWorldScript : public WorldScript
{
public:
    RebornTreasureWorldScript() : WorldScript("RebornTreasureWorldScript") { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            sRebornTreasure->Reload();
        else
            sRebornTreasure->LoadConfig();
    }

    void OnStartup() override
    {
        sRebornTreasure->LoadFromDB();
    }

    void OnUpdate(uint32 diff) override
    {
        sRebornTreasure->Update(diff);
    }
};

void AddSC_mod_reborn_treasure()
{
    new RebornTreasureGameObjectScript();
    new RebornTreasureMoneyPlayerScript();
    new RebornTreasureLootScript();
    new RebornTreasureWorldScript();
}
