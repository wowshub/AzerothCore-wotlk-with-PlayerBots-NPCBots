#ifndef MOD_REBORN_TREASURE_H
#define MOD_REBORN_TREASURE_H

#include "Common.h"
#include "ObjectGuid.h"
#include <map>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

class Player;
class GameObject;
class Map;

enum TreasureQuality : uint8
{
    TREASURE_QUALITY_COMMON = 1,
    TREASURE_QUALITY_RARE   = 2,
    TREASURE_QUALITY_EPIC   = 3
};

enum TreasureEntries : uint32
{
    GO_TREASURE_CHEST_COMMON = 990200,
    GO_TREASURE_CHEST_RARE   = 990201,
    GO_TREASURE_CHEST_EPIC   = 990202,
    // TREAS2A: the TREAS2A SQL reserves 100 chest templates; a "chest type" is one of them
    GO_TREASURE_ENTRY_FIRST  = 990200,
    GO_TREASURE_ENTRY_LAST   = 990299
};

// One kind of chest (TREAS2A): its looks and gold; what is inside is `gameobject_loot_template`
// (Entry = this entry), so the GM panel, SQL and `.reload gameobject_loot_template` see the same data.
struct TreasureType
{
    uint32 entry = 0;
    std::string name;
    std::string icon;               // client texture path, only shown in the GM panel
    uint32 displayId = 259;
    float  size = 1.0f;
    uint32 goldMin = 0;             // copper
    uint32 goldMax = 0;
    uint8  rarity = TREASURE_QUALITY_COMMON;
    uint32 respawnMin = 300;
    uint32 respawnMax = 600;
    bool   active = true;
};

struct TreasureSpawn
{
    uint32 spawnId = 0;
    uint8  quality = TREASURE_QUALITY_COMMON;
    uint32 entry = GO_TREASURE_CHEST_COMMON;
    uint16 mapId = 0;
    uint32 zoneId = 0;
    float  x = 0.0f;
    float  y = 0.0f;
    float  z = 0.0f;
    float  o = 0.0f;
    uint32 respawnMinSecs = 300;
    uint32 respawnMaxSecs = 600;
    uint64 lastClaimedTime = 0;
    uint64 nextRespawnTime = 0;
    bool   isActive = true;
    std::string comment;

    // Runtime only, never stored. A dungeon exists once per group (an "instance"), so the chest is kept
    // per map copy: instanceId -> the chest standing in that copy. The open world is instanceId 0.
    std::unordered_map<uint32, ObjectGuid> chests;
    // dungeon copies where the chest was already opened (a dungeon chest is once per run)
    std::unordered_set<uint32> claimedInstances;
};

struct TreasureClue
{
    uint32 clueId = 0;
    uint32 spawnId = 0;
    std::string clueText;
    float  minDistance = 5.0f;
    float  maxDistance = 45.0f;
};

// one clue the player is close enough to hear
struct TreasureNearby
{
    uint32 spawnId;
    std::string text;
};

// Threading: Update() and the GM commands run on the world thread while no map is
// updating; OnChestUsed() and the clue scan run on map worker threads. Every access to
// the containers goes through m_mutex, and nothing outside this class keeps a pointer
// into them.
class RebornTreasureMgr
{
public:
    static RebornTreasureMgr* instance();

    void LoadConfig();
    void LoadFromDB();
    void Update(uint32 diff);
    void Reload();

    bool IsEnabled() const { return m_enabled; }
    uint32 GetClueIntervalMs() const { return m_clueCheckIntervalMs; }
    uint32 GetClueSoundId() const { return m_clueSoundId; }

    // true = the click was ours (loot window opened, or the chest swallowed); false = not ours
    bool OnChestUsed(Player* player, GameObject* go);
    void OnChestEmptied(ObjectGuid guid);  // TREAS2A4: everything was taken, remove the chest at the next tick

    void CollectNearby(uint16 mapId, uint32 instanceId, float px, float py, float pz, std::vector<TreasureNearby>& out);
    std::vector<TreasureSpawn> Snapshot();

    // GM interface
    // `where` is the map the GM stands in (the chest is put there at once)
    // `kind`: 1/2/3 = the three original chests, otherwise a chest type's entry (990200-990299)
    uint32 AddSpawn(uint32 kind, uint16 mapId, uint32 zoneId, float x, float y, float z, float o, uint32 respawnSecs, std::string comment, Map* where);
    bool RemoveSpawn(uint32 spawnId);
    bool ForceRespawn(uint32 spawnId, Map* where);
    bool IsDbReady() const { return m_dbReady; }

    // TREAS2A: chest types (GM panel). Errors come back as a plain sentence in `err`.
    std::vector<TreasureType> Types();
    bool GetType(uint32 entry, TreasureType& out);
    bool SaveType(TreasureType const& type, std::string& err);   // create or change; applies at once
    uint32 NewType(std::string const& name, std::string& err);   // the next free entry, 0 on failure
    bool DeleteType(uint32 entry, std::string& err);
    void MarkLootDirty() { m_lootDirty = true; }                  // reloads gameobject_loot_template shortly

private:
    RebornTreasureMgr() = default;

    // callers hold m_mutex
    bool SpawnChestLocked(TreasureSpawn& spawn, Map* map);
    void DespawnChestLocked(TreasureSpawn& spawn, uint32 instanceId, Map* hint = nullptr);
    void DespawnAllLocked(TreasureSpawn& spawn);
    void LoadFromDBLocked();
    void LoadTypesLocked();
    // copy a type into the in-memory chest template (looks, loot id, gold) and refresh its chests
    bool ApplyTypeLocked(TreasureType const& type, std::string& err);
    void RefreshEntryLocked(uint32 entry);
    uint32 EntryForKindLocked(uint32 kind) const;

    bool m_enabled = true;
    bool m_dbReady = false;
    uint32 m_clueCheckIntervalMs = 2500;
    float m_defaultClueDistance = 40.0f;
    uint32 m_clueSoundId = 0;
    uint8 m_announceMode = 1;
    bool m_mailRewardOnFullBag = true;
    bool m_debugLog = false;
    uint32 m_defaultRespawnMin = 300;
    uint32 m_defaultRespawnMax = 600;
    uint32 m_updateTimer = 1000;
    uint32 m_nextSpawnId = 1;

    std::mutex m_mutex;
    std::unordered_map<uint32, TreasureSpawn> m_spawns;
    std::unordered_map<ObjectGuid, uint32> m_guidToSpawnId;
    std::map<uint32, TreasureType> m_types;
    std::unordered_set<ObjectGuid> m_opened;   // chests whose first open was already counted
    std::unordered_set<ObjectGuid> m_emptied;  // chests that were looted empty, waiting to be removed
    bool m_lootDirty = false;
    std::unordered_map<uint32, TreasureClue> m_clueBySpawn;
};

#define sRebornTreasure RebornTreasureMgr::instance()

#endif // MOD_REBORN_TREASURE_H
