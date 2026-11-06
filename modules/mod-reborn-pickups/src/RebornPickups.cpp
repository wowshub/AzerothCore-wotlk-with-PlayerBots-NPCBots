// mod-reborn-pickups  (WPICK1A)
//
// World pickups: a decor object in the open world (a weapon lying on the ground, ...) that hands out one item,
// once per character, and sparkles like a gatherable for everyone who has not taken it yet.
//
// * World DB  `reborn_pickup`            spawn_id -> item_id, count, note   (created here if missing)
// * Char DB   `character_reborn_pickup`  (guid, spawn_id) = this character already took it
// * The pickup object is a normal `gameobject` spawn of a type 10 (goober) template, so the client shows the
//   interact cursor. The click is answered here (AllGameObjectScript::CanGameObjectGossipHello), the core's
//   goober code never runs for it.
// * The sparkle is per viewer: this module registers a hook with GameObject (core patch WPICK1A in
//   GameObject.h/.cpp: SetPerViewerFlagsHook / SetPerViewerFlags) that adds GO_DYNFLAG_LO_ACTIVATE|SPARKLE for a
//   character who may still take the item and GO_FLAG_LOCKED|NOT_SELECTABLE for one who already did.
// * Identity = the spawn id (`gameobject`.`guid`), never the runtime guid.
// * The ledger row is written BEFORE the item is handed over and removed again if the item cannot be stored, so
//   a crash can lose the item but never hand it out twice.
//
// GM commands:
//   .pickup new <template_entry> <item_id> [count]   spawn a pickup at your feet (templates: .pickup models)
//   .pickup set <item_id> [count]                    change the item of the nearest pickup (within 15 yards)
//   .pickup del                                      delete the nearest pickup (spawn, definition and ledger rows)
//   .pickup list                                     pickups on this map
//   .pickup models                                   the weapon templates that can be used
//   .pickup reset [all]                              forget what the selected player (or yourself) already took;
//                                                    "all" clears every character

#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Item.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <atomic>
#include <cmath>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    struct PickupDef
    {
        uint32 itemId = 0;       // 0 = hands out no item (quest credit only)
        uint32 count = 1;
        // WPICK2A: optional quest hooks and repeat rule
        uint32 questId = 0;      // != 0: only a character with this quest in progress can use / see it lit
        uint32 creditNpc = 0;    // != 0: Player::KilledMonsterCredit(entry) on use (quest objective "creature")
        uint32 creditGo = 0;     // != 0: Player::KillCreditGO(entry) on use (quest objective "game object", RequiredNpcOrGo < 0)
        uint32 mode = 0;         // 0 once per character, 1 every click, 2 again after `secs` seconds
        uint32 secs = 0;
    };

    std::mutex g_mutex;
    std::unordered_map<uint32, std::unordered_map<uint32, time_t>> g_takenAt;  // character guid -> spawn id -> time (mode 2)
    std::unordered_map<uint32, PickupDef> g_defs;                          // spawn_id -> definition
    std::unordered_map<uint32, std::unordered_set<uint32>> g_looted;       // character guid -> spawn ids

    bool Enabled() { return sConfigMgr->GetOption<bool>("Pickups.Enable", true); }
    bool SparkleOn() { return sConfigMgr->GetOption<bool>("Pickups.Sparkle", true); }

    bool FindDef(uint32 spawnId, PickupDef& out)
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        auto it = g_defs.find(spawnId);
        if (it == g_defs.end())
            return false;
        out = it->second;
        return true;
    }

    bool HasLooted(uint32 charGuid, uint32 spawnId)
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        auto it = g_looted.find(charGuid);
        return it != g_looted.end() && it->second.count(spawnId) != 0;
    }

    // Has this character used the pickup and may not use it again right now? (mode 1 = never "taken")
    bool IsTaken(uint32 charGuid, uint32 spawnId, PickupDef const& d, uint32* remainOut = nullptr)
    {
        if (d.mode == 1)
            return false;
        if (d.mode == 2)
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            auto it = g_takenAt.find(charGuid);
            if (it == g_takenAt.end())
                return false;
            auto jt = it->second.find(spawnId);
            if (jt == it->second.end())
                return false;
            time_t const until = jt->second + static_cast<time_t>(d.secs);
            time_t const now = time(nullptr);
            if (until <= now)
                return false;
            if (remainOut)
                *remainOut = static_cast<uint32>(until - now);
            return true;
        }
        return HasLooted(charGuid, spawnId);
    }

    // Quest-bound pickup: usable only while the quest is in progress.
    bool QuestOk(Player const* p, PickupDef const& d)
    {
        return !d.questId || p->GetQuestStatus(d.questId) == QUEST_STATUS_INCOMPLETE;
    }

    void RefreshAll(Map* map)
    {
        // Make every client re-read the flags of the pickups on this map (each viewer gets their own answer).
        std::vector<uint32> ids;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            for (auto const& d : g_defs)
                ids.push_back(d.first);
        }
        for (uint32 id : ids)
        {
            auto bounds = map->GetGameObjectBySpawnIdStore().equal_range(id);
            for (auto it = bounds.first; it != bounds.second; ++it)
            {
                it->second->ForceValuesUpdateAtIndex(GAMEOBJECT_FLAGS);
                it->second->ForceValuesUpdateAtIndex(GAMEOBJECT_DYNAMIC);
            }
        }
    }

    // WEAPDECOR1C: housing ground-weapon decor (type 5, entries 9200401-9200403) glows for everyone. The core rebuilds the dynamic flags for
    // every viewer by object type, so a value set from a script is overwritten; the per-viewer hook is the only place that sticks.
    bool IsGlowDecor(uint32 entry) { return entry >= 9200401 && entry <= 9200403; }

    // Hook called by GameObject::BuildValuesUpdate for every viewer.
    void PerViewerFlags(GameObject const* go, Player const* target, uint16& dynFlags, uint32& goFlags)
    {
        if (!go || !target)
            return;
        if (IsGlowDecor(go->GetEntry()))
        {
            dynFlags |= GO_DYNFLAG_LO_ACTIVATE | GO_DYNFLAG_LO_SPARKLE;
            static std::atomic<int> logged{0};
            if (logged.fetch_add(1) < 8)
                LOG_INFO("server.loading", "mod-reborn-pickups: glow hook entry {} spawn {} type {} viewer {} dynFlags {}",
                         go->GetEntry(), go->GetSpawnId(), uint32(go->GetGoType()), target->GetName(), uint32(dynFlags));
            return;
        }
        uint32 const spawnId = static_cast<uint32>(go->GetSpawnId());
        if (!spawnId)
            return;
        PickupDef def;
        if (!FindDef(spawnId, def))
            return;
        if (!QuestOk(target, def) || IsTaken(target->GetGUID().GetCounter(), spawnId, def))
        {
            goFlags |= GO_FLAG_LOCKED | GO_FLAG_NOT_SELECTABLE;
            return;
        }
        if (SparkleOn())
            dynFlags |= GO_DYNFLAG_LO_ACTIVATE | GO_DYNFLAG_LO_SPARKLE;
    }

    void EnsureTables()
    {
        WorldDatabase.DirectExecute("CREATE TABLE IF NOT EXISTS `reborn_pickup` ("
            "`spawn_id` INT UNSIGNED NOT NULL, `item_id` INT UNSIGNED NOT NULL, `count` INT UNSIGNED NOT NULL DEFAULT 1, "
            "`note` VARCHAR(100) NOT NULL DEFAULT '', `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, "
            "PRIMARY KEY (`spawn_id`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        // WPICK2A columns (added to an existing table once)
        static char const* cols[][2] = {
            { "quest_id", "INT UNSIGNED NOT NULL DEFAULT 0" }, { "credit_npc", "INT UNSIGNED NOT NULL DEFAULT 0" },
            { "credit_go", "INT UNSIGNED NOT NULL DEFAULT 0" }, { "repeat_mode", "TINYINT UNSIGNED NOT NULL DEFAULT 0" },
            { "repeat_secs", "INT UNSIGNED NOT NULL DEFAULT 0" } };
        for (auto const& c : cols)
        {
            if (!WorldDatabase.Query("SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'reborn_pickup' AND COLUMN_NAME = '{}'", c[0]))
            {
                WorldDatabase.DirectExecute("ALTER TABLE `reborn_pickup` ADD COLUMN `{}` {}", c[0], c[1]);
                LOG_INFO("server.loading", ">> mod-reborn-pickups: column reborn_pickup.{} added.", c[0]);
            }
        }
        CharacterDatabase.DirectExecute("CREATE TABLE IF NOT EXISTS `character_reborn_pickup` ("
            "`guid` INT UNSIGNED NOT NULL, `spawn_id` INT UNSIGNED NOT NULL, `item_id` INT UNSIGNED NOT NULL DEFAULT 0, "
            "`taken` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`guid`, `spawn_id`)) "
            "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    }

    // WPICK1B: pickup rows whose world object no longer exists (deleted with the object editor) are removed,
    // together with the "already taken" marks of those rows. Returns how many were removed.
    uint32 CleanOrphans()
    {
        std::vector<uint32> orphans;
        if (QueryResult r = WorldDatabase.Query("SELECT p.`spawn_id` FROM `reborn_pickup` p LEFT JOIN `gameobject` g ON g.`guid` = p.`spawn_id` WHERE g.`guid` IS NULL"))
        {
            do
            {
                orphans.push_back(r->Fetch()[0].Get<uint32>());
            } while (r->NextRow());
        }
        for (uint32 id : orphans)
        {
            WorldDatabase.DirectExecute("DELETE FROM `reborn_pickup` WHERE `spawn_id` = {}", id);
            CharacterDatabase.DirectExecute("DELETE FROM `character_reborn_pickup` WHERE `spawn_id` = {}", id);
        }
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            for (uint32 id : orphans)
            {
                g_defs.erase(id);
                for (auto& l : g_looted)
                    l.second.erase(id);
            }
        }
        return static_cast<uint32>(orphans.size());
    }

    // WPICK1B: a housing catalog id (not a gameobject_template entry) names the mirrored pickup template 9400000 + id
    uint32 ResolveTemplate(uint32 entry)
    {
        if (entry > 0 && entry < 100000 && sObjectMgr->GetGameObjectTemplate(9400000u + entry))
            return 9400000u + entry;
        return entry;
    }

    void LoadDefs()
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_defs.clear();
        if (QueryResult r = WorldDatabase.Query("SELECT `spawn_id`, `item_id`, `count`, `quest_id`, `credit_npc`, `credit_go`, `repeat_mode`, `repeat_secs` FROM `reborn_pickup`"))
        {
            do
            {
                Field* f = r->Fetch();
                PickupDef d;
                d.itemId = f[1].Get<uint32>();
                d.count = std::max<uint32>(f[2].Get<uint32>(), 1u);
                d.questId = f[3].Get<uint32>();
                d.creditNpc = f[4].Get<uint32>();
                d.creditGo = f[5].Get<uint32>();
                d.mode = std::min<uint32>(f[6].Get<uint32>(), 2u);
                d.secs = f[7].Get<uint32>();
                g_defs[f[0].Get<uint32>()] = d;
            } while (r->NextRow());
        }
        LOG_INFO("server.loading", ">> mod-reborn-pickups: {} pickups loaded (WPICK1A).", g_defs.size());
    }

    // Same as the core's ".gobject add" (and the housing module): create, save to `gameobject`, load a clean instance.
    bool SpawnPickup(Player* player, uint32 entry, uint32& spawnIdOut)
    {
        Map* map = player->GetMap();
        GameObjectTemplate const* info = sObjectMgr->GetGameObjectTemplate(entry);
        if (!info || info->type != GAMEOBJECT_TYPE_GOOBER)
            return false;

        float const x = player->GetPositionX(), y = player->GetPositionY(), z = player->GetPositionZ(), o = player->GetOrientation();
        GameObject* object = new GameObject();
        ObjectGuid::LowType guidLow = map->GenerateLowGuid<HighGuid::GameObject>();
        G3D::Quat rotation = G3D::Quat::fromAxisAngleRotation(G3D::Vector3::unitZ(), o);
        if (!object->Create(guidLow, entry, map, player->GetPhaseMaskForSpawn(), x, y, z, o, rotation, 0, GO_STATE_READY))
        {
            delete object;
            return false;
        }
        object->SaveToDB(map->GetId(), (1 << map->GetSpawnMode()), player->GetPhaseMaskForSpawn());
        guidLow = object->GetSpawnId();
        delete object;

        object = new GameObject();
        if (!object->LoadGameObjectFromDB(guidLow, map, true))
        {
            delete object;
            return false;
        }
        sObjectMgr->AddGameobjectToGrid(guidLow, sObjectMgr->GetGameObjectData(guidLow));
        spawnIdOut = static_cast<uint32>(guidLow);
        return true;
    }

    GameObject* NearestPickup(Player* player, float maxDist, uint32& spawnIdOut)
    {
        GameObject* best = nullptr;
        float bestDist = maxDist;
        std::vector<uint32> ids;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            for (auto const& d : g_defs)
                ids.push_back(d.first);
        }
        for (uint32 id : ids)
        {
            auto bounds = player->GetMap()->GetGameObjectBySpawnIdStore().equal_range(id);
            for (auto it = bounds.first; it != bounds.second; ++it)
            {
                float const d = player->GetDistance(it->second);
                if (d < bestDist)
                {
                    bestDist = d;
                    best = it->second;
                    spawnIdOut = id;
                }
            }
        }
        return best;
    }

    std::string ItemLabel(uint32 itemId)
    {
        if (ItemTemplate const* t = sObjectMgr->GetItemTemplate(itemId))
            return t->Name1;
        return "?";
    }
}

class RebornPickupObjectScript : public AllGameObjectScript
{
public:
    RebornPickupObjectScript() : AllGameObjectScript("RebornPickupObjectScript") { }

    void OnGameObjectAddWorld(GameObject* go) override
    {
        if (!go)
            return;
        if (IsGlowDecor(go->GetEntry()))
        {
            go->SetPerViewerFlags(true);
            LOG_INFO("server.loading", "mod-reborn-pickups: glow decor added to world entry {} spawn {} type {}",
                     go->GetEntry(), go->GetSpawnId(), uint32(go->GetGoType()));
            return;
        }
        if (!go->GetSpawnId())
            return;
        PickupDef def;
        if (FindDef(static_cast<uint32>(go->GetSpawnId()), def))
            go->SetPerViewerFlags(true);
    }

    bool CanGameObjectGossipHello(Player* player, GameObject* go) override
    {
        if (!player || !go || !go->GetSpawnId() || !Enabled())
            return false;
        uint32 const spawnId = static_cast<uint32>(go->GetSpawnId());
        PickupDef def;
        if (!FindDef(spawnId, def))
            return false;

        ChatHandler chat(player->GetSession());
        uint32 const charGuid = player->GetGUID().GetCounter();
        if (!QuestOk(player, def))
        {
            chat.PSendSysMessage("你现在用不到这个。");
            return true;
        }
        uint32 remain = 0;
        if (IsTaken(charGuid, spawnId, def, &remain))
        {
            if (def.mode == 2)
                chat.PSendSysMessage("这里暂时没有东西了，{} 秒后再来。", remain);
            else
                chat.PSendSysMessage("你已经拿过这件东西了。");
            return true;
        }
        if (def.itemId && !sObjectMgr->GetItemTemplate(def.itemId))
        {
            chat.PSendSysMessage("这个拾取点的物品不存在（{}），请告诉GM。", def.itemId);
            return true;
        }

        ItemPosCountVec dest;
        if (def.itemId)
        {
            InventoryResult res = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, def.itemId, def.count);
            if (res != EQUIP_ERR_OK)
            {
                player->SendEquipError(res, nullptr, nullptr, def.itemId);
                return true;
            }
        }

        // Ledger first (memory + database), then the item; undo the ledger if the item cannot be created.
        if (def.mode == 0)
        {
            {
                std::lock_guard<std::mutex> lock(g_mutex);
                if (!g_looted[charGuid].insert(spawnId).second)
                    return true;
            }
            CharacterDatabase.DirectExecute("INSERT IGNORE INTO `character_reborn_pickup` (`guid`, `spawn_id`, `item_id`) VALUES ({}, {}, {})",
                                            charGuid, spawnId, def.itemId);
        }
        else if (def.mode == 2)
        {
            {
                std::lock_guard<std::mutex> lock(g_mutex);
                g_takenAt[charGuid][spawnId] = time(nullptr);
            }
            CharacterDatabase.DirectExecute("REPLACE INTO `character_reborn_pickup` (`guid`, `spawn_id`, `item_id`) VALUES ({}, {}, {})",
                                            charGuid, spawnId, def.itemId);
        }
        Item* item = nullptr;
        if (def.itemId)
        {
            item = player->StoreNewItem(dest, def.itemId, true, Item::GenerateItemRandomPropertyId(def.itemId));
            if (!item)
            {
                {
                    std::lock_guard<std::mutex> lock(g_mutex);
                    g_looted[charGuid].erase(spawnId);
                    g_takenAt[charGuid].erase(spawnId);
                }
                if (def.mode != 1)
                    CharacterDatabase.DirectExecute("DELETE FROM `character_reborn_pickup` WHERE `guid` = {} AND `spawn_id` = {}", charGuid, spawnId);
                player->SendEquipError(EQUIP_ERR_INVENTORY_FULL, nullptr, nullptr, def.itemId);
                return true;
            }
            player->SendNewItem(item, def.count, true, false);
        }
        // quest progress after the item exists (an item objective updates itself; these are the creature / game object objectives)
        if (def.creditNpc)
            player->KilledMonsterCredit(def.creditNpc);
        if (def.creditGo)
            player->KillCreditGO(def.creditGo, go->GetGUID());
        go->ForceValuesUpdateAtIndex(GAMEOBJECT_FLAGS);
        go->ForceValuesUpdateAtIndex(GAMEOBJECT_DYNAMIC);
        LOG_INFO("server.loading", "mod-reborn-pickups: {} used pickup spawn {} (item {} x{}, quest {}, npc credit {}, go credit {})",
                 player->GetName(), spawnId, def.itemId, def.count, def.questId, def.creditNpc, def.creditGo);
        return true;
    }
};

class RebornPickupPlayerScript : public PlayerScript
{
public:
    RebornPickupPlayerScript() : PlayerScript("RebornPickupPlayerScript", { PLAYERHOOK_ON_LOAD_FROM_DB, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE }) { }

    // Early enough that no gameobject has been sent to this client yet, so the first update already carries the right flags.
    void OnPlayerLoadFromDB(Player* player) override
    {
        uint32 const guid = player->GetGUID().GetCounter();
        std::unordered_set<uint32> looted;
        std::unordered_map<uint32, time_t> takenAt;
        if (QueryResult r = CharacterDatabase.Query("SELECT `spawn_id`, UNIX_TIMESTAMP(`taken`) FROM `character_reborn_pickup` WHERE `guid` = {}", guid))
        {
            do
            {
                looted.insert((*r)[0].Get<uint32>());
                takenAt[(*r)[0].Get<uint32>()] = static_cast<time_t>((*r)[1].Get<uint64>());
            } while (r->NextRow());
        }
        std::lock_guard<std::mutex> lock(g_mutex);
        g_looted[guid] = std::move(looted);
        g_takenAt[guid] = std::move(takenAt);
    }

    void OnPlayerLogout(Player* player) override
    {
        uint32 const guid = player->GetGUID().GetCounter();
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            g_looted.erase(guid);
            g_takenAt.erase(guid);
        }
        std::lock_guard<std::mutex> own(_m);
        _timer.erase(guid);
        _seen.erase(guid);
    }

    // Quest-bound pickups: every 2 seconds compare who may use them now with the last answer; on a change (quest accepted,
    // completed, abandoned, or a repeat timer ran out) resend that object's flags so the glow appears or goes out.
    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        uint32 const guid = player->GetGUID().GetCounter();
        std::lock_guard<std::mutex> own(_m);
        uint32& t = _timer[guid];
        if (t > diff)
        {
            t -= diff;
            return;
        }
        t = 2000;
        std::vector<std::pair<uint32, PickupDef>> gated;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            for (auto const& d : g_defs)
                if (d.second.questId || d.second.mode == 2)
                    gated.emplace_back(d.first, d.second);
        }
        if (gated.empty())
            return;
        Map* map = player->GetMap();
        if (!map)
            return;
        auto& seen = _seen[guid];
        for (auto const& g : gated)
        {
            bool const usable = QuestOk(player, g.second) && !IsTaken(guid, g.first, g.second);
            auto it = seen.find(g.first);
            if (it != seen.end() && it->second == usable)
                continue;
            bool const first = it == seen.end();
            seen[g.first] = usable;
            if (first)
                continue;   // the first full update already carried the right flags
            auto bounds = map->GetGameObjectBySpawnIdStore().equal_range(g.first);
            for (auto b = bounds.first; b != bounds.second; ++b)
            {
                b->second->ForceValuesUpdateAtIndex(GAMEOBJECT_FLAGS);
                b->second->ForceValuesUpdateAtIndex(GAMEOBJECT_DYNAMIC);
            }
        }
    }

private:
    std::mutex _m;
    std::unordered_map<uint32, uint32> _timer;
    std::unordered_map<uint32, std::unordered_map<uint32, bool>> _seen;
};

class RebornPickupWorldScript : public WorldScript
{
public:
    RebornPickupWorldScript() : WorldScript("RebornPickupWorldScript", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        EnsureTables();
        if (uint32 removed = CleanOrphans())
            LOG_INFO("server.loading", ">> mod-reborn-pickups: removed {} orphan pickup rows (object no longer in `gameobject`).", removed);
        LoadDefs();
    }
};

class RebornPickupCommandScript : public CommandScript
{
public:
    RebornPickupCommandScript() : CommandScript("RebornPickupCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable pickupCommands =
        {
            { "new",    HandleNew,    SEC_GAMEMASTER, Console::No },
            { "set",    HandleSet,    SEC_GAMEMASTER, Console::No },
            { "del",    HandleDel,    SEC_GAMEMASTER, Console::No },
            { "list",   HandleList,   SEC_GAMEMASTER, Console::No },
            { "models", HandleModels, SEC_GAMEMASTER, Console::No },
            { "reset",  HandleReset,  SEC_GAMEMASTER, Console::No },
            { "probe",  HandleProbe,  SEC_GAMEMASTER, Console::No },
            { "clean",  HandleClean,  SEC_GAMEMASTER, Console::No },
            { "put",    HandlePut,    SEC_GAMEMASTER, Console::No },
            { "edit",   HandleEdit,   SEC_GAMEMASTER, Console::No },
            { "rm",     HandleRm,     SEC_GAMEMASTER, Console::No },
            { "ui",     HandleUi,     SEC_GAMEMASTER, Console::No }
        };
        static ChatCommandTable rootCommands =
        {
            { "pickup", pickupCommands }
        };
        return rootCommands;
    }

    // .pickup clean   removes pickup rows whose object was deleted elsewhere
    static bool HandleClean(ChatHandler* handler)
    {
        handler->PSendSysMessage("已清理 {} 条孤儿拾取点记录。", CleanOrphans());
        return true;
    }

    // ---------------------------------------------------------------- WPICK2A / 2B: full control for the GM panel
    // The panel gets its list as addon whispers (prefix RBNHOME, the same channel the housing window reads):
    //   WB|count                 start of a list
    //   WK|spawn|dist|entry|item|count|quest|npc|go|mode|secs|itemName|questTitle
    static void PanelSend(Player* p, std::string const& text)
    {
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, LANG_ADDON, p, p, std::string("RBNHOME\t") + text);
        p->GetSession()->SendPacket(&data);
    }

    static std::string Clean(std::string s, size_t maxBytes)
    {
        for (char& c : s)
            if (c == '|' || c == '\n' || static_cast<unsigned char>(c) < 0x20)
                c = ' ';
        if (s.size() > maxBytes)
        {
            size_t cut = maxBytes;
            while (cut > 0 && (static_cast<unsigned char>(s[cut]) & 0xC0) == 0x80)
                --cut;
            s.resize(cut);
        }
        return s;
    }

    static void SendPanelList(Player* gm)
    {
        std::vector<std::pair<float, uint32>> rows;
        std::unordered_map<uint32, PickupDef> defs;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            defs = g_defs;
        }
        for (auto const& d : defs)
        {
            auto bounds = gm->GetMap()->GetGameObjectBySpawnIdStore().equal_range(d.first);
            for (auto it = bounds.first; it != bounds.second; ++it)
                rows.emplace_back(gm->GetDistance(it->second), d.first);
        }
        std::sort(rows.begin(), rows.end());
        if (rows.size() > 30)
            rows.resize(30);
        PanelSend(gm, "WB|" + std::to_string(rows.size()));
        for (auto const& r : rows)
        {
            PickupDef const& d = defs[r.second];
            uint32 entry = 0;
            auto bounds = gm->GetMap()->GetGameObjectBySpawnIdStore().equal_range(r.second);
            if (bounds.first != bounds.second)
                entry = bounds.first->second->GetEntry();
            std::string questTitle;
            if (d.questId)
                if (Quest const* q = sObjectMgr->GetQuestTemplate(d.questId))
                    questTitle = q->GetTitle();
            PanelSend(gm, Acore::StringFormat("WK|{}|{:.0f}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}", r.second, r.first, entry, d.itemId, d.count, d.questId,
                d.creditNpc, d.creditGo, d.mode, d.secs, Clean(d.itemId ? ItemLabel(d.itemId) : std::string(), 40), Clean(questTitle, 40)));
        }
    }

    // checks the optional fields; returns false and tells the GM what is wrong
    static bool CheckOpts(ChatHandler* handler, uint32 itemId, uint32 questId, uint32 npc, uint32 go, uint32 mode)
    {
        auto fail = [&](std::string const& m)
        {
            handler->SendErrorMessage("{}", m);
            PanelSend(handler->GetPlayer(), "U|err|" + Clean(m, 150));
            return false;
        };
        if (itemId && !sObjectMgr->GetItemTemplate(itemId))
            return fail("物品 " + std::to_string(itemId) + " 不存在。");
        if (questId && !sObjectMgr->GetQuestTemplate(questId))
            return fail("任务 " + std::to_string(questId) + " 不存在。");
        if (npc && !sObjectMgr->GetCreatureTemplate(npc))
            return fail("生物模板 " + std::to_string(npc) + " 不存在（任务目标里的生物ID）。");
        if (go && !sObjectMgr->GetGameObjectTemplate(go))
            return fail("物体模板 " + std::to_string(go) + " 不存在（任务目标里的物体ID）。");
        if (!itemId && !npc && !go)
            return fail("物品、生物目标、物体目标至少要填一个。");
        if (mode > 2)
            return fail("重复规则只能是 0（每人一次）、1（每次点击）、2（隔一段时间）。");
        return true;
    }

    static void StoreDef(uint32 spawnId, uint32 itemId, uint32 count, uint32 questId, uint32 npc, uint32 go, uint32 mode, uint32 secs)
    {
        WorldDatabase.DirectExecute("REPLACE INTO `reborn_pickup` (`spawn_id`, `item_id`, `count`, `quest_id`, `credit_npc`, `credit_go`, `repeat_mode`, `repeat_secs`) "
            "VALUES ({}, {}, {}, {}, {}, {}, {}, {})", spawnId, itemId, count, questId, npc, go, mode, secs);
        std::lock_guard<std::mutex> lock(g_mutex);
        PickupDef d;
        d.itemId = itemId;
        d.count = count;
        d.questId = questId;
        d.creditNpc = npc;
        d.creditGo = go;
        d.mode = mode;
        d.secs = secs;
        g_defs[spawnId] = d;
    }

    static void ResendFlags(Map* map, uint32 spawnId, bool enable)
    {
        auto bounds = map->GetGameObjectBySpawnIdStore().equal_range(spawnId);
        for (auto it = bounds.first; it != bounds.second; ++it)
        {
            if (enable)
                it->second->SetPerViewerFlags(true);
            it->second->ForceValuesUpdateAtIndex(GAMEOBJECT_FLAGS);
            it->second->ForceValuesUpdateAtIndex(GAMEOBJECT_DYNAMIC);
        }
    }

    // .pickup put <entry|catalog id> <item> <count> <quest> <npc credit> <go credit> <mode> <secs>
    static bool HandlePut(ChatHandler* handler, uint32 entry, uint32 itemId, uint32 count, uint32 questId, uint32 npc, uint32 go, uint32 mode, uint32 secs)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        entry = ResolveTemplate(entry);
        if (!CheckOpts(handler, itemId, questId, npc, go, mode))
            return false;
        count = std::min<uint32>(std::max<uint32>(count, 1u), 200u);
        uint32 spawnId = 0;
        if (!SpawnPickup(gm, entry, spawnId))
        {
            handler->SendErrorMessage("摆放失败：模板 {} 不存在或不是可点击的拾取模板。先导入家具镜像SQL，或用 .pickup models 查看可用模板。", entry);
            return false;
        }
        StoreDef(spawnId, itemId, count, questId, npc, go, mode, secs);
        ResendFlags(gm->GetMap(), spawnId, true);
        handler->PSendSysMessage("已摆放拾取点 {}。", spawnId);
        PanelSend(gm, Acore::StringFormat("U|ok|已摆放拾取点 {}。", spawnId));
        SendPanelList(gm);
        return true;
    }

    // .pickup edit <spawn> <item> <count> <quest> <npc credit> <go credit> <mode> <secs>
    static bool HandleEdit(ChatHandler* handler, uint32 spawnId, uint32 itemId, uint32 count, uint32 questId, uint32 npc, uint32 go, uint32 mode, uint32 secs)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        PickupDef old;
        if (!FindDef(spawnId, old))
        {
            handler->SendErrorMessage("拾取点 {} 不存在。", spawnId);
            return false;
        }
        if (!CheckOpts(handler, itemId, questId, npc, go, mode))
            return false;
        count = std::min<uint32>(std::max<uint32>(count, 1u), 200u);
        StoreDef(spawnId, itemId, count, questId, npc, go, mode, secs);
        ResendFlags(gm->GetMap(), spawnId, false);
        handler->PSendSysMessage("已保存拾取点 {}。已经用过的角色按旧记录算。", spawnId);
        PanelSend(gm, Acore::StringFormat("U|ok|已保存拾取点 {}。", spawnId));
        SendPanelList(gm);
        return true;
    }

    // .pickup rm <spawn>   delete by spawn id (the object must be on your map)
    static bool HandleRm(ChatHandler* handler, uint32 spawnId)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        PickupDef d;
        if (!FindDef(spawnId, d))
        {
            handler->SendErrorMessage("拾取点 {} 不存在。", spawnId);
            return false;
        }
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            g_defs.erase(spawnId);
            for (auto& l : g_looted)
                l.second.erase(spawnId);
            for (auto& l : g_takenAt)
                l.second.erase(spawnId);
        }
        WorldDatabase.DirectExecute("DELETE FROM `reborn_pickup` WHERE `spawn_id` = {}", spawnId);
        CharacterDatabase.DirectExecute("DELETE FROM `character_reborn_pickup` WHERE `spawn_id` = {}", spawnId);
        auto bounds = gm->GetMap()->GetGameObjectBySpawnIdStore().equal_range(spawnId);
        std::vector<GameObject*> gos;
        for (auto it = bounds.first; it != bounds.second; ++it)
            gos.push_back(it->second);
        for (GameObject* go : gos)
        {
            go->SetRespawnTime(0);
            go->Delete();
            go->DeleteFromDB();
        }
        handler->PSendSysMessage("已删除拾取点 {}。", spawnId);
        PanelSend(gm, Acore::StringFormat("U|ok|已删除拾取点 {}。", spawnId));
        SendPanelList(gm);
        return true;
    }

    // .pickup ui   sends the nearby pickups to the panel
    static bool HandleUi(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        SendPanelList(gm);
        return true;
    }

    // .pickup new <template entry | housing catalog id> <item> [count]
    static bool HandleNew(ChatHandler* handler, uint32 entry, uint32 itemId, Optional<uint32> countArg)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        entry = ResolveTemplate(entry);
        if (!sObjectMgr->GetItemTemplate(itemId))
        {
            handler->SendErrorMessage("物品 {} 不存在。", itemId);
            return false;
        }
        uint32 const count = std::min<uint32>(std::max<uint32>(countArg ? *countArg : 1u, 1u), 200u);
        uint32 spawnId = 0;
        if (!SpawnPickup(gm, entry, spawnId))
        {
            handler->SendErrorMessage("摆放失败：模板 {} 不存在或不是可点击的拾取模板（.pickup models 查看可用的）。", entry);
            return false;
        }
        WorldDatabase.DirectExecute("REPLACE INTO `reborn_pickup` (`spawn_id`, `item_id`, `count`) VALUES ({}, {}, {})", spawnId, itemId, count);
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            PickupDef d;
            d.itemId = itemId;
            d.count = count;
            g_defs[spawnId] = d;
        }
        // The object was loaded before the definition existed: switch on the per-viewer flags and resend.
        auto bounds = gm->GetMap()->GetGameObjectBySpawnIdStore().equal_range(spawnId);
        for (auto it = bounds.first; it != bounds.second; ++it)
        {
            it->second->SetPerViewerFlags(true);
            it->second->ForceValuesUpdateAtIndex(GAMEOBJECT_FLAGS);
            it->second->ForceValuesUpdateAtIndex(GAMEOBJECT_DYNAMIC);
        }
        handler->PSendSysMessage("已摆放拾取点 {}（物品 {} x{}：{}）。", spawnId, itemId, count, ItemLabel(itemId));
        return true;
    }

    static bool HandleSet(ChatHandler* handler, uint32 itemId, Optional<uint32> countArg)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        if (!sObjectMgr->GetItemTemplate(itemId))
        {
            handler->SendErrorMessage("物品 {} 不存在。", itemId);
            return false;
        }
        uint32 spawnId = 0;
        if (!NearestPickup(gm, 15.0f, spawnId))
        {
            handler->SendErrorMessage("15 码内没有拾取点。");
            return false;
        }
        uint32 const count = std::min<uint32>(std::max<uint32>(countArg ? *countArg : 1u, 1u), 200u);
        WorldDatabase.DirectExecute("UPDATE `reborn_pickup` SET `item_id` = {}, `count` = {} WHERE `spawn_id` = {}", itemId, count, spawnId);
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            g_defs[spawnId].itemId = itemId;
            g_defs[spawnId].count = count;
        }
        handler->PSendSysMessage("拾取点 {} 现在给：物品 {} x{}（{}）。已经拿过的角色不会再拿到新物品。", spawnId, itemId, count, ItemLabel(itemId));
        return true;
    }

    static bool HandleDel(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        uint32 spawnId = 0;
        GameObject* go = NearestPickup(gm, 15.0f, spawnId);
        if (!go)
        {
            handler->SendErrorMessage("15 码内没有拾取点。");
            return false;
        }
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            g_defs.erase(spawnId);
            for (auto& l : g_looted)
                l.second.erase(spawnId);
        }
        WorldDatabase.DirectExecute("DELETE FROM `reborn_pickup` WHERE `spawn_id` = {}", spawnId);
        CharacterDatabase.DirectExecute("DELETE FROM `character_reborn_pickup` WHERE `spawn_id` = {}", spawnId);
        go->SetRespawnTime(0);
        go->Delete();
        go->DeleteFromDB();
        handler->PSendSysMessage("已删除拾取点 {}。", spawnId);
        return true;
    }

    static bool HandleList(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        std::vector<std::pair<uint32, PickupDef>> rows;
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            for (auto const& d : g_defs)
                rows.emplace_back(d.first, d.second);
        }
        std::sort(rows.begin(), rows.end(), [](auto const& a, auto const& b) { return a.first < b.first; });
        uint32 shown = 0;
        for (auto const& row : rows)
        {
            auto bounds = gm->GetMap()->GetGameObjectBySpawnIdStore().equal_range(row.first);
            for (auto it = bounds.first; it != bounds.second; ++it)
            {
                if (shown++ >= 40)
                    break;
                handler->PSendSysMessage("拾取点 {}：物品 {} x{}（{}），距离 {:.0f} 码", row.first, row.second.itemId, row.second.count,
                                         ItemLabel(row.second.itemId), gm->GetDistance(it->second));
            }
        }
        handler->PSendSysMessage("本地图共 {} 个拾取点（全服 {} 个，最多显示 40 个）。", shown, rows.size());
        return true;
    }

    // WEAPDECOR1F: shows what the server really has for the housing weapon decor (and pickups) within 40 yards.
    static bool HandleProbe(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        uint32 shown = 0;
        for (uint32 entry : { 9200401u, 9200402u, 9200403u, 9300001u, 9300002u, 9300003u })
        {
            GameObjectTemplate const* info = sObjectMgr->GetGameObjectTemplate(entry);
            if (!info)
            {
                handler->PSendSysMessage("模板 {}：服务端没有这个模板。", entry);
                continue;
            }
            std::list<GameObject*> found;
            gm->GetGameObjectListWithEntryInGrid(found, entry, 40.0f);
            handler->PSendSysMessage("模板 {} 类型 {}（10=可点击，5=装饰） displayId {} 附近 {} 个", entry, uint32(info->type), info->displayId, uint32(found.size()));
            for (GameObject* go : found)
            {
                ++shown;
                handler->PSendSysMessage("  spawn {} 距离 {:.1f} 标志 {} 动态 {} 状态 {}", uint32(go->GetSpawnId()), gm->GetDistance(go),
                                         go->GetUInt32Value(GAMEOBJECT_FLAGS), go->GetUInt32Value(GAMEOBJECT_DYNAMIC), uint32(go->GetGoState()));
            }
        }
        if (!shown)
            handler->SendSysMessage("40 码内没有这几个模板的物件。");
        return true;
    }

    static bool HandleModels(ChatHandler* handler)
    {
        QueryResult r = WorldDatabase.Query("SELECT `entry`, `name` FROM `gameobject_template` WHERE `type` = 10 AND `name` LIKE 'Reborn Pickup:%' ORDER BY `entry`");
        if (!r)
        {
            handler->SendErrorMessage("没有拾取模板：先导入 WPICK1A 的 SQL。");
            return false;
        }
        do
        {
            Field* f = r->Fetch();
            handler->PSendSysMessage("{}  {}", f[0].Get<uint32>(), f[1].Get<std::string>());
        } while (r->NextRow());
        return true;
    }

    static bool HandleReset(ChatHandler* handler, Optional<std::string> allArg)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        if (allArg && *allArg == "all")
        {
            CharacterDatabase.DirectExecute("DELETE FROM `character_reborn_pickup`");
            {
                std::lock_guard<std::mutex> lock(g_mutex);
                for (auto& l : g_looted)
                    l.second.clear();
            }
            RefreshAll(gm->GetMap());
            handler->PSendSysMessage("已清空所有角色的拾取记录。");
            return true;
        }
        Player* target = handler->getSelectedPlayerOrSelf();
        if (!target)
            return false;
        uint32 const guid = target->GetGUID().GetCounter();
        CharacterDatabase.DirectExecute("DELETE FROM `character_reborn_pickup` WHERE `guid` = {}", guid);
        {
            std::lock_guard<std::mutex> lock(g_mutex);
            g_looted[guid].clear();
        }
        RefreshAll(gm->GetMap());
        handler->PSendSysMessage("已清空 {} 的拾取记录。", target->GetName());
        return true;
    }
};

void AddSC_mod_reborn_pickups()
{
    GameObject::SetPerViewerFlagsHook(&PerViewerFlags);
    new RebornPickupObjectScript();
    new RebornPickupPlayerScript();
    new RebornPickupWorldScript();
    new RebornPickupCommandScript();
}
