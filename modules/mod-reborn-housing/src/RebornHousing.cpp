// mod-reborn-housing  (HOME1A + HOME1B)
//
// First server slice of the housing system (see 设计_家园系统.md): plots, a decor catalog, and
// placement that is kept on the server and seen by every player.
//
// Spawn method = design option B: each piece of decor is a normal row in the core `gameobject`
// table (so grid loading, respawn and visibility are the core's own), and `reborn_housing_object`
// links that row to a plot and a catalog entry. The mapping tables live in the WORLD database next to
// the `gameobject` rows they point to, so a database restore never leaves them out of step.
//
// Commands (".home ..."):
//   players : plot info | catalog [page] | add <catalog_id> | list | move <object_id> | rotate <object_id> <degrees> | remove <object_id>
//   GMs     : plot create [radius] (for the selected player, or yourself) | plot list | plot delete <plot_id> | plot mark
//   HOME4   : several plots per player. tp [plot_id] [pay] | plot mylist | plot buy (costs gold, see conf).
//             GMs: plot list shows "mine" and "others" apart; tp <plot_id> reaches any plot with no cooldown.
//             add / list / plot info / plot show use the plot you stand in, else your plot on this map, else your first.
//   HOME1B  : plot show (a ring of braziers for a few seconds); plot info also tells the distance and direction.
//             plot create / plot mark put a flag in the middle and posts along the edge (table reborn_housing_marker).
// Placement is checked against the plot (same map, inside the radius) and the per-plot cap; GMs may place
// anywhere inside any plot and ignore the cap.

#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Log.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Transport.h"
#include <algorithm>
#include <cmath>
#include <ctime>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    constexpr float kPi = 3.14159265f;

    struct Plot
    {
        uint32 id = 0;
        uint32 ownerGuid = 0;
        uint32 mapId = 0;
        float x = 0.0f, y = 0.0f, z = 0.0f;
        float radius = 0.0f;
    };

    struct ObjectRow
    {
        uint32 id = 0;
        uint32 plotId = 0;
        uint32 catalogId = 0;
        uint32 entry = 0;
        uint32 spawnId = 0;
        uint32 mapId = 0;
        float x = 0.0f, y = 0.0f, z = 0.0f, o = 0.0f;
        float scale = 1.0f;
    };

    bool Enabled()
    {
        return sConfigMgr->GetOption<bool>("Housing.Enable", true);
    }

    bool LoadPlotWhere(std::string const& where, Plot& out)
    {
        QueryResult r = WorldDatabase.Query(
            "SELECT plot_id, owner_guid, map_id, x, y, z, radius FROM reborn_housing_plot WHERE " + where + " LIMIT 1");
        if (!r)
            return false;
        Field* f = r->Fetch();
        out.id = f[0].Get<uint32>();
        out.ownerGuid = f[1].Get<uint32>();
        out.mapId = f[2].Get<uint32>();
        out.x = f[3].Get<float>();
        out.y = f[4].Get<float>();
        out.z = f[5].Get<float>();
        out.radius = f[6].Get<float>();
        return true;
    }

    bool LoadObject(uint32 objectId, ObjectRow& out)
    {
        QueryResult r = WorldDatabase.Query(
            "SELECT object_id, plot_id, catalog_id, gobject_entry, spawn_id, map_id, x, y, z, o, scale "
            "FROM reborn_housing_object WHERE object_id = {}", objectId);
        if (!r)
            return false;
        Field* f = r->Fetch();
        out.id = f[0].Get<uint32>();
        out.plotId = f[1].Get<uint32>();
        out.catalogId = f[2].Get<uint32>();
        out.entry = f[3].Get<uint32>();
        out.spawnId = f[4].Get<uint32>();
        out.mapId = f[5].Get<uint32>();
        out.x = f[6].Get<float>();
        out.y = f[7].Get<float>();
        out.z = f[8].Get<float>();
        out.o = f[9].Get<float>();
        out.scale = f[10].Get<float>();
        return true;
    }

    bool InsidePlot(Plot const& plot, uint32 mapId, float x, float y)
    {
        if (plot.mapId != mapId)
            return false;
        float dx = x - plot.x;
        float dy = y - plot.y;
        return dx * dx + dy * dy <= plot.radius * plot.radius;
    }

    uint32 ObjectCount(uint32 plotId)
    {
        QueryResult r = WorldDatabase.Query("SELECT COUNT(*) FROM reborn_housing_object WHERE plot_id = {}", plotId);
        return r ? r->Fetch()[0].Get<uint32>() : 0;
    }

    bool IsGM(Player* player)
    {
        return player->GetSession()->GetSecurity() >= SEC_GAMEMASTER;
    }

    // ------------------------------------------------------------------ HOME4: several plots per player
    Plot PlotFromRow(Field* f)
    {
        Plot p;
        p.id = f[0].Get<uint32>();
        p.ownerGuid = f[1].Get<uint32>();
        p.mapId = f[2].Get<uint32>();
        p.x = f[3].Get<float>();
        p.y = f[4].Get<float>();
        p.z = f[5].Get<float>();
        p.radius = f[6].Get<float>();
        return p;
    }

    // Which of the owner's plots a command means: the one the position is standing in; else the owner's
    // first plot on the same map; else the owner's lowest-numbered plot.
    bool FindMyPlot(uint32 ownerGuid, uint32 mapId, float x, float y, Plot& out)
    {
        QueryResult r = WorldDatabase.Query(
            "SELECT plot_id, owner_guid, map_id, x, y, z, radius FROM reborn_housing_plot WHERE owner_guid = {} ORDER BY plot_id LIMIT 200", ownerGuid);
        if (!r)
            return false;
        Plot first, sameMap;
        bool haveFirst = false, haveSame = false;
        do
        {
            Plot p = PlotFromRow(r->Fetch());
            if (InsidePlot(p, mapId, x, y))
            {
                out = p;
                return true;
            }
            if (!haveFirst)
            {
                first = p;
                haveFirst = true;
            }
            if (!haveSame && p.mapId == mapId)
            {
                sameMap = p;
                haveSame = true;
            }
        } while (r->NextRow());
        out = haveSame ? sameMap : first;
        return true;
    }

    uint32 PlotCountOf(uint32 ownerGuid)
    {
        QueryResult r = WorldDatabase.Query("SELECT COUNT(*) FROM reborn_housing_plot WHERE owner_guid = {}", ownerGuid);
        return r ? r->Fetch()[0].Get<uint32>() : 0;
    }

    // true when a circle (map, x, y, radius) touches an existing plot; the plot is returned in `hit`
    bool OverlapsAnyPlot(uint32 mapId, float x, float y, float radius, uint32& hit)
    {
        QueryResult r = WorldDatabase.Query("SELECT plot_id, x, y, radius FROM reborn_housing_plot WHERE map_id = {}", mapId);
        if (!r)
            return false;
        do
        {
            Field* f = r->Fetch();
            float dx = x - f[1].Get<float>();
            float dy = y - f[2].Get<float>();
            float limit = radius + f[3].Get<float>();
            if (dx * dx + dy * dy < limit * limit)
            {
                hit = f[0].Get<uint32>();
                return true;
            }
        } while (r->NextRow());
        return false;
    }

    // "0,1,530,571" -> is mapId in the list
    bool MapInList(std::string const& list, uint32 mapId)
    {
        size_t pos = 0;
        while (pos < list.size())
        {
            while (pos < list.size() && (list[pos] < '0' || list[pos] > '9'))
                ++pos;
            if (pos >= list.size())
                break;
            uint32 v = 0;
            while (pos < list.size() && list[pos] >= '0' && list[pos] <= '9')
                v = v * 10 + static_cast<uint32>(list[pos++] - '0');
            if (v == mapId)
                return true;
        }
        return false;
    }

    // Last .home tp per character (seconds since epoch). Kept in memory: a restart clears the cooldowns.
    std::unordered_map<uint32, time_t>& LastTpMap()
    {
        static std::unordered_map<uint32, time_t> m;
        return m;
    }

    uint32 TpRemainSeconds(uint32 guid)
    {
        auto it = LastTpMap().find(guid);
        if (it == LastTpMap().end() || !it->second)
            return 0;
        time_t remain = it->second + static_cast<time_t>(sConfigMgr->GetOption<uint32>("Housing.Tp.Cooldown", 60)) - time(nullptr);
        return remain > 0 ? static_cast<uint32>(remain) : 0;
    }

    // ------------------------------------------------------------------ HOME4B: data for the client window
    // The window gets its lists as addon whispers: prefix RBNHOME, at most ~230 bytes each, lines split by NEWLINE.
    // Nothing is printed in the chat window.
    class UiBatch
    {
    public:
        explicit UiBatch(Player* p) : _p(p) { }
        ~UiBatch() { Flush(); }
        void Line(std::string const& line)
        {
            if (!_buf.empty() && _buf.size() + 1 + line.size() > 230)
                Flush();
            if (!_buf.empty())
                _buf += '\n';
            _buf += line;
        }
        void Flush()
        {
            if (_buf.empty())
                return;
            WorldPacket data;
            ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, LANG_ADDON, _p, _p, std::string("RBNHOME\t") + _buf);
            _p->GetSession()->SendPacket(&data);
            _buf.clear();
        }
    private:
        Player* _p;
        std::string _buf;
    };

    // Text that goes into a '|'-separated line: no separators or control characters, at most `maxBytes` bytes
    // (cut on a UTF-8 character boundary).
    std::string UiText(std::string s, size_t maxBytes)
    {
        for (char& c : s)
            if (c == '|' || static_cast<unsigned char>(c) < 0x20)
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

    std::string MoneyText(uint32 copper)
    {
        return std::to_string(copper / 10000) + " 金" + (copper % 10000 ? " " + std::to_string((copper % 10000) / 100) + " 银" : std::string());
    }

    // Price settings are copper, clamped so a silly value cannot overflow the player's money.
    uint32 ConfigCopper(char const* key, uint32 def)
    {
        uint32 v = sConfigMgr->GetOption<uint32>(key, def);
        return std::min<uint32>(v, 2000000000u);
    }

    // ------------------------------------------------------------------ H3C: per-piece scale
    // The core keeps no scale per spawn (only the template's `size`), so ours lives in reborn_housing_object.scale
    // and is applied when a piece is spawned and again whenever the core loads it into the world.
    bool IsHousingEntry(uint32 entry)
    {
        return (entry >= 9190001 && entry <= 9190004) || (entry >= 9200001 && entry <= 9299999);
    }

    std::mutex& ScaleLock()
    {
        static std::mutex m;
        return m;
    }

    std::unordered_map<uint32, float>& ScaleCache()
    {
        static std::unordered_map<uint32, float> cache;
        return cache;
    }

    bool& ScaleCacheLoaded()
    {
        static bool loaded = false;
        return loaded;
    }

    void RememberScale(uint32 spawnId, float scale)
    {
        std::lock_guard<std::mutex> guard(ScaleLock());
        ScaleCache()[spawnId] = scale;
    }

    // H3C safety: if the SQL was not imported (or went into another database) add the column ourselves,
    // so a missing column can never bring the whole server down.
    void EnsureScaleColumn()
    {
        QueryResult r = WorldDatabase.Query("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() "
            "AND table_name = 'reborn_housing_object' AND column_name = 'scale'");
        if (r && r->Fetch()[0].Get<uint64>() == 0)
        {
            WorldDatabase.DirectExecute("ALTER TABLE `reborn_housing_object` ADD COLUMN `scale` FLOAT NOT NULL DEFAULT 1");
            LOG_WARN("server.loading", ">> mod-reborn-housing: column reborn_housing_object.scale was missing and has been added.");
        }
    }

    float LookupScale(uint32 spawnId)
    {
        std::lock_guard<std::mutex> guard(ScaleLock());
        if (!ScaleCacheLoaded())
        {
            ScaleCacheLoaded() = true;
            QueryResult r = WorldDatabase.Query("SELECT spawn_id, scale FROM reborn_housing_object WHERE scale <> 1");
            if (r)
            {
                do
                {
                    Field* f = r->Fetch();
                    ScaleCache()[f[0].Get<uint32>()] = f[1].Get<float>();
                } while (r->NextRow());
            }
        }
        auto it = ScaleCache().find(spawnId);
        return it == ScaleCache().end() ? 1.0f : it->second;
    }

    // Spawns one gameobject the same way the core's ".gobject add" does: create, save to the
    // `gameobject` table, then load a clean instance from the database.
    bool SpawnDecor(Player* player, uint32 entry, float x, float y, float z, float o, uint32& spawnIdOut, float scale = 1.0f)
    {
        Map* map = player->GetMap();
        GameObjectTemplate const* info = sObjectMgr->GetGameObjectTemplate(entry);
        if (!info || sObjectMgr->IsGameObjectStaticTransport(entry))
            return false;

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
        if (scale != 1.0f)
        {
            RememberScale(spawnIdOut, scale);
            object->SetObjectScale(info->size * scale);
        }
        return true;
    }

    // Removes a spawned decor from the world and from the `gameobject` table. Only works while the
    // object is loaded on the player's map (stand near the plot).
    bool DespawnDecor(Player* player, uint32 spawnId)
    {
        auto bounds = player->GetMap()->GetGameObjectBySpawnIdStore().equal_range(spawnId);
        if (bounds.first == bounds.second)
            return false;
        GameObject* object = bounds.first->second;
        object->SetRespawnTime(0);
        object->Delete();
        object->DeleteFromDB();
        return true;
    }

    // ------------------------------------------------------------------ HOME1B: plot markers
    float GroundZ(Map* map, uint32 phase, float x, float y, float refZ)
    {
        float h = map->GetHeight(phase, x, y, refZ + 5.0f);
        if (h <= INVALID_HEIGHT + 1.0f || std::fabs(h - refZ) > 25.0f)
            return refZ;
        return h;
    }

    uint32 RingCount(float radius, float spacing, uint32 minN, uint32 maxN)
    {
        float n = std::floor(2.0f * kPi * radius / std::max(spacing, 2.0f) + 0.5f);
        uint32 count = n < 0.0f ? 0u : static_cast<uint32>(n);
        return std::min(std::max(count, minN), maxN);
    }

    // Removes the permanent markers of a plot that are loaded on the player's map. Rows whose
    // gameobject is already gone are dropped. `missing` counts the ones that could not be reached.
    void RemoveMarkers(Player* player, uint32 plotId, uint32& removed, uint32& missing)
    {
        WorldDatabase.DirectExecute(
            "DELETE m FROM reborn_housing_marker m LEFT JOIN gameobject g ON g.guid = m.spawn_id WHERE m.plot_id = {} AND g.guid IS NULL", plotId);
        QueryResult r = WorldDatabase.Query("SELECT marker_id, spawn_id FROM reborn_housing_marker WHERE plot_id = {}", plotId);
        if (!r)
            return;
        do
        {
            Field* f = r->Fetch();
            uint32 markerId = f[0].Get<uint32>();
            uint32 spawnId = f[1].Get<uint32>();
            if (DespawnDecor(player, spawnId))
            {
                ++removed;
                WorldDatabase.Execute("DELETE FROM reborn_housing_marker WHERE marker_id = {}", markerId);
            }
            else
                ++missing;
        } while (r->NextRow());
    }

    // One flag in the middle and posts along the edge. The caller stands inside the plot.
    // kind 1 = flag, kind 2 = post. Returns false (with `err` set) when a template is missing.
    bool SpawnMarkers(Player* player, Plot const& plot, uint32& flags, uint32& posts, std::string& err)
    {
        Map* map = player->GetMap();
        uint32 phase = player->GetPhaseMaskForSpawn();
        uint32 flagEntry = sConfigMgr->GetOption<uint32>("Housing.Mark.FlagEntry", 19664);
        uint32 postEntry = sConfigMgr->GetOption<uint32>("Housing.Mark.PostEntry", 19457);
        float spacing = sConfigMgr->GetOption<float>("Housing.Mark.PostSpacing", 12.0f);

        auto put = [&](uint32 entry, uint32 kind, float x, float y, float o) -> bool
        {
            float z = GroundZ(map, phase, x, y, plot.z);
            uint32 spawnId = 0;
            if (!SpawnDecor(player, entry, x, y, z, o, spawnId))
            {
                err = "无法生成标记（模板 " + std::to_string(entry) + " 不存在，或不能在这里生成）。检查 Housing.Mark.* 配置。";
                return false;
            }
            WorldDatabase.Execute(
                "INSERT INTO reborn_housing_marker (plot_id, kind, spawn_id, map_id, x, y, z) VALUES ({}, {}, {}, {}, {}, {}, {})",
                plot.id, kind, spawnId, plot.mapId, x, y, z);
            return true;
        };

        if (flagEntry)
        {
            if (!put(flagEntry, 1, plot.x, plot.y, player->GetOrientation()))
                return false;
            ++flags;
        }

        if (postEntry)
        {
            uint32 n = RingCount(plot.radius, spacing, 8, 48);
            for (uint32 k = 0; k < n; ++k)
            {
                float a = 2.0f * kPi * static_cast<float>(k) / static_cast<float>(n);
                if (!put(postEntry, 2, plot.x + plot.radius * std::cos(a), plot.y + plot.radius * std::sin(a), a))
                    return false;
                ++posts;
            }
        }
        return true;
    }

    char const* CompassWord(float dx, float dy)
    {
        // WoW: +x is north, +y is west. Bearing is measured clockwise from north.
        static char const* names[8] = { "北", "东北", "东", "东南", "南", "西南", "西", "西北" };
        float angle = std::atan2(-dy, dx);
        int idx = static_cast<int>(std::floor(angle / (kPi / 4.0f) + 0.5f));
        idx = ((idx % 8) + 8) % 8;
        return names[idx];
    }

    std::string CatalogName(uint32 catalogId)
    {
        QueryResult r = WorldDatabase.Query("SELECT name_zh FROM reborn_housing_catalog WHERE catalog_id = {}", catalogId);
        return r ? r->Fetch()[0].Get<std::string>() : std::string("?");
    }
}

class RebornHousingCommandScript : public CommandScript
{
public:
    RebornHousingCommandScript() : CommandScript("RebornHousingCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable plotCommands =
        {
            { "info",   HandlePlotInfo,   SEC_PLAYER,     Console::No },
            { "create", HandlePlotCreate, SEC_GAMEMASTER, Console::No },
            { "list",   HandlePlotList,   SEC_GAMEMASTER, Console::Yes },
            { "delete", HandlePlotDelete, SEC_GAMEMASTER, Console::No },
            { "mark",   HandlePlotMark,   SEC_GAMEMASTER, Console::No },
            { "show",   HandlePlotShow,   SEC_PLAYER,     Console::No },
            { "mylist", HandlePlotMyList, SEC_PLAYER,     Console::No },
            { "buy",    HandlePlotBuy,    SEC_PLAYER,     Console::No },
            { "rename", HandlePlotRename, SEC_PLAYER,     Console::No }
        };

        static ChatCommandTable homeCommands =
        {
            { "plot",    plotCommands },
            { "tp",      HandleTp,      SEC_PLAYER, Console::No },
            { "ui",      HandleUi,      SEC_PLAYER, Console::No },
            { "put",     HandlePut,     SEC_PLAYER, Console::No },
            { "set",     HandleSet,     SEC_PLAYER, Console::No },
            { "catalog", HandleCatalog, SEC_PLAYER, Console::No },
            { "add",     HandleAdd,     SEC_PLAYER, Console::No },
            { "list",    HandleList,    SEC_PLAYER, Console::No },
            { "move",    HandleMove,    SEC_PLAYER, Console::No },
            { "rotate",  HandleRotate,  SEC_PLAYER, Console::No },
            { "remove",  HandleRemove,  SEC_PLAYER, Console::No }
        };

        static ChatCommandTable rootCommands =
        {
            { "home", homeCommands }
        };

        return rootCommands;
    }

    // ------------------------------------------------------------------ plots

    // .home plot create [radius]    (GM) the selected player (or you) gets a plot centred where you stand
    static bool HandlePlotCreate(ChatHandler* handler, Optional<float> radiusArg)
    {
        Player* gm = handler->GetPlayer();
        if (!gm || !Enabled())
            return false;
        Player* owner = handler->getSelectedPlayerOrSelf();
        if (!owner)
        {
            handler->SendErrorMessage("没有选中玩家。");
            return false;
        }

        float radius = radiusArg ? *radiusArg : sConfigMgr->GetOption<float>("Housing.DefaultPlotRadius", 30.0f);
        float maxRadius = sConfigMgr->GetOption<float>("Housing.MaxPlotRadius", 80.0f);
        if (radius < 5.0f || radius > maxRadius)
        {
            handler->SendErrorMessage("半径必须在 5 到 {} 码之间。", maxRadius);
            return false;
        }

        // HOME4: a player may own several plots; a GM is not limited by the per-player cap.
        uint32 hit = 0;
        if (OverlapsAnyPlot(gm->GetMapId(), gm->GetPositionX(), gm->GetPositionY(), radius, hit))
        {
            handler->SendErrorMessage("这里和地块 {} 重叠了。请换个位置，或先缩小半径。", hit);
            return false;
        }

        uint32 plotId = 0;
        if (!CreatePlotAt(handler, gm, owner->GetGUID().GetCounter(), owner->GetName(), radius, plotId))
            return false;
        handler->PSendSysMessage("已给 {} 建立家园地块 {}：中心在你脚下，半径 {} 码（他现在共 {} 块）。",
            owner->GetName(), plotId, radius, PlotCountOf(owner->GetGUID().GetCounter()));
        return true;
    }

    // Inserts the plot where `at` stands and puts the markers (when enabled). `plotIdOut` is the new plot_id.
    static bool CreatePlotAt(ChatHandler* handler, Player* at, uint32 ownerGuid, std::string const& ownerName, float radius, uint32& plotIdOut)
    {
        WorldDatabase.DirectExecute(
            "INSERT INTO reborn_housing_plot (owner_guid, map_id, x, y, z, radius, name) VALUES ({}, {}, {}, {}, {}, {}, '{}')",
            ownerGuid, at->GetMapId(), at->GetPositionX(), at->GetPositionY(), at->GetPositionZ(), radius, ownerName);

        Plot created;
        if (!LoadPlotWhere("plot_id = (SELECT MAX(plot_id) FROM reborn_housing_plot WHERE owner_guid = " + std::to_string(ownerGuid) + ")", created))
        {
            handler->SendErrorMessage("地块没能建立（数据库没有返回新地块）。");
            return false;
        }
        plotIdOut = created.id;

        if (sConfigMgr->GetOption<bool>("Housing.Mark.OnCreate", true))
        {
            uint32 flags = 0, posts = 0;
            std::string err;
            if (SpawnMarkers(at, created, flags, posts, err))
                handler->PSendSysMessage("已立标记：中心旗帜 {} 面，边界桩 {} 根。", flags, posts);
            else
                handler->SendErrorMessage("{}（地块已建立，可稍后用 .home plot mark 补做标记）", err);
        }
        return true;
    }

    // .home plot info
    static bool HandlePlotInfo(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        Player* who = IsGM(player) ? handler->getSelectedPlayerOrSelf() : player;
        Plot plot;
        if (!who || !FindMyPlot(who->GetGUID().GetCounter(), player->GetMapId(), player->GetPositionX(), player->GetPositionY(), plot))
        {
            handler->SendSysMessage("还没有家园地块。请联系 GM 开通，或用 .home plot buy 购买。");
            return true;
        }
        if (PlotCountOf(who->GetGUID().GetCounter()) > 1)
            handler->PSendSysMessage("（共 {} 块地，这里显示的是你站着的那块或同地图最近的一块；.home plot mylist 看全部。）",
                PlotCountOf(who->GetGUID().GetCounter()));
        handler->PSendSysMessage("地块 {}：地图 {}，中心 ({:.1f}, {:.1f}, {:.1f})，半径 {:.0f} 码，已摆放 {} / {}。",
            plot.id, plot.mapId, plot.x, plot.y, plot.z, plot.radius, ObjectCount(plot.id),
            sConfigMgr->GetOption<uint32>("Housing.MaxObjectsPerPlot", 60));
        if (plot.mapId != player->GetMapId())
            handler->PSendSysMessage("你现在不在这块地所在的地图（地图 {}）。", plot.mapId);
        else
        {
            float dx = plot.x - player->GetPositionX();
            float dy = plot.y - player->GetPositionY();
            float dist = std::sqrt(dx * dx + dy * dy);
            if (dist <= plot.radius)
                handler->PSendSysMessage("你在这块地里面，离中心 {:.0f} 码。", dist);
            else
                handler->PSendSysMessage("你在地块外面，中心在你的{}方，约 {:.0f} 码（边界还要走 {:.0f} 码）。",
                    CompassWord(dx, dy), dist, dist - plot.radius);
        }
        return true;
    }

    // .home plot list   (GM)
    static bool HandlePlotList(ChatHandler* handler)
    {
        // HOME4: the GM's own plots first, then everybody else's
        Player* gm = handler->GetPlayer();
        uint32 mine = gm ? gm->GetGUID().GetCounter() : 0;
        QueryResult r = WorldDatabase.Query("SELECT plot_id, owner_guid, name, map_id, radius FROM reborn_housing_plot ORDER BY plot_id LIMIT 200");
        if (!r)
        {
            handler->SendSysMessage("没有任何地块。");
            return true;
        }
        std::vector<std::string> own, others;
        do
        {
            Field* f = r->Fetch();
            std::string line = Acore::StringFormat("地块 {}：{}（角色 {}），地图 {}，半径 {:.0f}，物件 {}",
                f[0].Get<uint32>(), f[2].Get<std::string>(), f[1].Get<uint32>(), f[3].Get<uint32>(), f[4].Get<float>(),
                ObjectCount(f[0].Get<uint32>()));
            (f[1].Get<uint32>() == mine ? own : others).push_back(line);
        } while (r->NextRow());
        handler->PSendSysMessage("== 我的地块（{} 块）==", own.size());
        for (std::string const& line : own)
            handler->SendSysMessage(line.c_str());
        handler->PSendSysMessage("== 其他人的地块（{} 块）==", others.size());
        for (std::string const& line : others)
            handler->SendSysMessage(line.c_str());
        return true;
    }

    // .home plot mylist   the plots you own, with how to get there
    static bool HandlePlotMyList(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        QueryResult r = WorldDatabase.Query(
            "SELECT plot_id, owner_guid, map_id, x, y, z, radius FROM reborn_housing_plot WHERE owner_guid = {} ORDER BY plot_id LIMIT 200",
            player->GetGUID().GetCounter());
        if (!r)
        {
            handler->SendSysMessage("你还没有家园地块。用 .home plot buy 购买。");
            return true;
        }
        uint32 max = sConfigMgr->GetOption<uint32>("Housing.Plot.MaxPerPlayer", 5);
        handler->PSendSysMessage("你的地块（上限 {}）：", max ? std::to_string(max) : std::string("不限"));
        do
        {
            Plot p = PlotFromRow(r->Fetch());
            handler->PSendSysMessage("  地块 {}：地图 {}，中心 ({:.0f}, {:.0f})，半径 {:.0f}，物件 {}  → .home tp {}",
                p.id, p.mapId, p.x, p.y, p.radius, ObjectCount(p.id), p.id);
        } while (r->NextRow());
        return true;
    }

    // .home plot buy   buy another plot centred where you stand
    static bool HandlePlotBuy(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        bool gm = IsGM(player);
        if (!sConfigMgr->GetOption<bool>("Housing.Plot.BuyEnabled", true) && !gm)
        {
            handler->SendErrorMessage("现在不能自己购买地块，请联系 GM。");
            return false;
        }
        if (!gm && (player->IsInCombat() || !player->IsAlive()))
        {
            handler->SendErrorMessage("战斗中或死亡时不能购买地块。");
            return false;
        }
        Map* map = player->GetMap();
        if (map->Instanceable())
        {
            handler->SendErrorMessage("副本、战场里不能建地块。");
            return false;
        }
        if (!gm && !MapInList(sConfigMgr->GetOption<std::string>("Housing.Plot.BuyMaps", "0,1,530,571"), player->GetMapId()))
        {
            handler->SendErrorMessage("这张地图（{}）不允许购买地块。", player->GetMapId());
            return false;
        }

        uint32 guid = player->GetGUID().GetCounter();
        uint32 count = PlotCountOf(guid);
        uint32 max = sConfigMgr->GetOption<uint32>("Housing.Plot.MaxPerPlayer", 5);
        if (!gm && max && count >= max)
        {
            handler->SendErrorMessage("你已经有 {} 块地，达到上限 {}。", count, max);
            return false;
        }

        uint32 price = gm ? 0 : ConfigCopper("Housing.Plot.Price", 10000000u);
        if (count == 0 && sConfigMgr->GetOption<bool>("Housing.Plot.FirstFree", false))
            price = 0;
        if (player->GetMoney() < price)
        {
            handler->SendErrorMessage("钱不够：购买一块地需要 {}。", MoneyText(price));
            return false;
        }

        float radius = sConfigMgr->GetOption<float>("Housing.DefaultPlotRadius", 30.0f);
        uint32 hit = 0;
        if (OverlapsAnyPlot(player->GetMapId(), player->GetPositionX(), player->GetPositionY(), radius, hit))
        {
            handler->SendErrorMessage("这里离地块 {} 太近（会重叠）。请走远一点再买。", hit);
            return false;
        }

        uint32 plotId = 0;
        if (!CreatePlotAt(handler, player, guid, player->GetName(), radius, plotId))
            return false;
        if (price)
            player->ModifyMoney(-static_cast<int32>(price));
        handler->PSendSysMessage("已购买地块 {}（半径 {} 码），花费 {}。你现在共 {} 块。", plotId, radius, MoneyText(price), count + 1);
        return true;
    }

    // .home tp [plot_id] [pay]   teleport to your plot (a GM may go to any plot, no cooldown)
    static bool HandleTp(ChatHandler* handler, Optional<uint32> plotIdArg, Optional<std::string> mode)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        bool gm = IsGM(player);
        uint32 guid = player->GetGUID().GetCounter();

        Plot plot;
        if (plotIdArg)
        {
            if (!LoadPlotWhere("plot_id = " + std::to_string(*plotIdArg), plot))
            {
                handler->SendErrorMessage("没有这块地。");
                return false;
            }
            if (plot.ownerGuid != guid && !gm)
            {
                handler->SendErrorMessage("这不是你的地块。");
                return false;
            }
        }
        else
        {
            if (!LoadPlotWhere("owner_guid = " + std::to_string(guid) + " ORDER BY plot_id", plot))
            {
                handler->SendErrorMessage("你还没有家园地块。");
                return false;
            }
            if (PlotCountOf(guid) > 1)
                handler->PSendSysMessage("你有多块地，这次去编号最小的地块 {}。想去别的用 .home tp <编号>（.home plot mylist 看编号）。", plot.id);
        }

        // already standing in that plot: nothing to do, and the cooldown is not used up
        if (InsidePlot(plot, player->GetMapId(), player->GetPositionX(), player->GetPositionY()))
        {
            float ix = plot.x - player->GetPositionX();
            float iy = plot.y - player->GetPositionY();
            handler->PSendSysMessage("你已经在地块 {} 里面了（离中心 {:.0f} 码）。", plot.id, std::sqrt(ix * ix + iy * iy));
            return true;
        }

        uint32 cost = 0;
        std::unordered_map<uint32, time_t>& lastTp = LastTpMap();
        if (!gm)
        {
            if (!player->IsAlive() || player->IsInCombat() || player->InBattleground() || player->InArena() || player->IsBeingTeleported())
            {
                handler->SendErrorMessage("现在不能传送（死亡、战斗中、战场或正在传送）。");
                return false;
            }
            time_t now = time(nullptr);
            uint32 cooldown = sConfigMgr->GetOption<uint32>("Housing.Tp.Cooldown", 60);
            time_t& last = lastTp[guid];
            time_t remain = last + static_cast<time_t>(cooldown) - now;
            if (last && remain > 0)
            {
                uint32 skipCost = ConfigCopper("Housing.Tp.SkipCost", 100000u);
                bool pay = mode && *mode == "pay";
                if (!pay || skipCost == 0)
                {
                    if (skipCost)
                        handler->PSendSysMessage("传送还要等 {} 秒。花 {} 可以立刻传：.home tp {} pay", static_cast<uint32>(remain), MoneyText(skipCost), plot.id);
                    else
                        handler->PSendSysMessage("传送还要等 {} 秒。", static_cast<uint32>(remain));
                    return false;
                }
                if (player->GetMoney() < skipCost)
                {
                    handler->SendErrorMessage("钱不够：免等待需要 {}。", MoneyText(skipCost));
                    return false;
                }
                cost = skipCost;
            }
        }

        if (!player->TeleportTo(plot.mapId, plot.x, plot.y, plot.z + 1.0f, player->GetOrientation()))
        {
            handler->SendErrorMessage("传送失败（目的地不可用）。");
            return false;
        }
        if (!gm)
            lastTp[guid] = time(nullptr);
        if (cost)
        {
            player->ModifyMoney(-static_cast<int32>(cost));
            handler->PSendSysMessage("花费 {}，跳过等待。", MoneyText(cost));
        }
        handler->PSendSysMessage("正在传送到地块 {}。", plot.id);
        return true;
    }

    // .home plot delete <plot_id>   (GM) removes the plot and every decor on it; stand near the plot first
    static bool HandlePlotDelete(ChatHandler* handler, uint32 plotId)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        Plot plot;
        if (!LoadPlotWhere("plot_id = " + std::to_string(plotId), plot))
        {
            handler->SendErrorMessage("没有这块地。");
            return false;
        }
        if (plot.mapId != gm->GetMapId())
        {
            handler->SendErrorMessage("请先站到这块地所在的地图，附近的物件才能被清掉。");
            return false;
        }

        QueryResult r = WorldDatabase.Query("SELECT spawn_id FROM reborn_housing_object WHERE plot_id = {}", plotId);
        uint32 removed = 0;
        uint32 missing = 0;
        if (r)
        {
            do
            {
                uint32 spawnId = r->Fetch()[0].Get<uint32>();
                if (DespawnDecor(gm, spawnId))
                    ++removed;
                else
                    ++missing;
            } while (r->NextRow());
        }
        uint32 markersRemoved = 0;
        RemoveMarkers(gm, plotId, markersRemoved, missing);
        removed += markersRemoved;
        if (missing > 0)
        {
            // keep the rows so nothing is orphaned; the loaded ones are already gone from the world
            handler->PSendSysMessage("已清掉 {} 件，还有 {} 件没加载（离得太远）。请走到地块中心附近再运行一次，地块没有删除。", removed, missing);
            WorldDatabase.Execute("DELETE o FROM reborn_housing_object o LEFT JOIN gameobject g ON g.guid = o.spawn_id WHERE o.plot_id = {} AND g.guid IS NULL", plotId);
            return true;
        }
        WorldDatabase.Execute("DELETE FROM reborn_housing_object WHERE plot_id = {}", plotId);
        WorldDatabase.Execute("DELETE FROM reborn_housing_plot WHERE plot_id = {}", plotId);
        handler->PSendSysMessage("地块 {} 已删除，清掉 {} 件物件。", plotId, removed);
        return true;
    }

    // .home plot mark   (GM) puts (or re-puts) the flag and edge posts on the plot you are standing in
    static bool HandlePlotMark(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        if (!gm || !Enabled())
            return false;
        Plot plot;
        std::string where = "map_id = " + std::to_string(gm->GetMapId()) +
            " AND POW(x - " + std::to_string(gm->GetPositionX()) + ", 2) + POW(y - " + std::to_string(gm->GetPositionY()) +
            ", 2) <= radius * radius";
        if (!LoadPlotWhere(where, plot))
        {
            handler->SendErrorMessage("你不在任何地块里面。请站到地块范围内再用。");
            return false;
        }
        uint32 removed = 0, missing = 0;
        RemoveMarkers(gm, plot.id, removed, missing);
        if (missing > 0)
        {
            handler->SendErrorMessage("还有 {} 个旧标记没加载（离得太远）。请走到地块中心附近再试。", missing);
            return false;
        }
        uint32 flags = 0, posts = 0;
        std::string err;
        if (!SpawnMarkers(gm, plot, flags, posts, err))
        {
            handler->SendErrorMessage("{}", err);
            return false;
        }
        handler->PSendSysMessage("地块 {}：清掉旧标记 {} 个，立了中心旗帜 {} 面、边界桩 {} 根。", plot.id, removed, flags, posts);
        return true;
    }

    // .home plot show   shows the edge of your plot for a few seconds with a ring of braziers
    static bool HandlePlotShow(ChatHandler* handler, Optional<uint32> plotIdArg)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        Plot plot;
        if (plotIdArg)
        {
            if (!LoadPlotWhere("plot_id = " + std::to_string(*plotIdArg), plot))
            {
                handler->SendErrorMessage("没有这块地。");
                return false;
            }
            if (plot.ownerGuid != player->GetGUID().GetCounter() && !IsGM(player))
            {
                handler->SendErrorMessage("这不是你的地块。");
                return false;
            }
        }
        else if (!FindMyPlot(player->GetGUID().GetCounter(), player->GetMapId(), player->GetPositionX(), player->GetPositionY(), plot))
        {
            handler->SendErrorMessage("你还没有家园地块。");
            return false;
        }
        if (plot.mapId != player->GetMapId())
        {
            handler->SendErrorMessage("你现在不在这块地所在的地图。");
            return false;
        }
        {
            float fx = plot.x - player->GetPositionX();
            float fy = plot.y - player->GetPositionY();
            float farAway = std::sqrt(fx * fx + fy * fy);
            if (farAway > plot.radius + 300.0f)
            {
                handler->SendErrorMessage("地块 {} 离你 {:.0f} 码，太远了，火盆你看不到。先用 .home tp {} 传送过去，或走到它附近。", plot.id, farAway, plot.id);
                return false;
            }
        }
        static std::unordered_map<uint32, time_t> lastShow;
        time_t now = time(nullptr);
        time_t& last = lastShow[player->GetGUID().GetCounter()];
        uint32 cooldown = sConfigMgr->GetOption<uint32>("Housing.Show.Cooldown", 10);
        if (now - last < static_cast<time_t>(cooldown))
        {
            handler->SendErrorMessage("请稍等几秒再显示范围。");
            return false;
        }
        last = now;

        uint32 entry = sConfigMgr->GetOption<uint32>("Housing.Show.Entry", 31576);
        uint32 seconds = sConfigMgr->GetOption<uint32>("Housing.Show.Seconds", 30);
        float spacing = sConfigMgr->GetOption<float>("Housing.Show.Spacing", 8.0f);
        uint32 n = RingCount(plot.radius, spacing, 12, 64);
        Map* map = player->GetMap();
        uint32 made = 0;
        for (uint32 k = 0; k < n; ++k)
        {
            float a = 2.0f * kPi * static_cast<float>(k) / static_cast<float>(n);
            float x = plot.x + plot.radius * std::cos(a);
            float y = plot.y + plot.radius * std::sin(a);
            float z = GroundZ(map, player->GetPhaseMask(), x, y, plot.z);
            if (player->SummonGameObject(entry, x, y, z, a, 0.0f, 0.0f, 0.0f, 1.0f, seconds, false))
                ++made;
        }
        if (!made)
        {
            handler->SendErrorMessage("没能显示范围（模板 {} 可能不存在，见 Housing.Show.Entry）。", entry);
            return false;
        }
        float cx = plot.x - player->GetPositionX();
        float cy = plot.y - player->GetPositionY();
        handler->PSendSysMessage("地块边界已用 {} 个火盆标出，约 {} 秒后消失。中心在你的{}方 {:.0f} 码。",
            made, seconds, CompassWord(cx, cy), std::sqrt(cx * cx + cy * cy));
        return true;
    }

    // .home plot rename <plot_id> <name>   HOME5A: name one of your plots (a GM may rename any). Empty name = default.
    static bool HandlePlotRename(ChatHandler* handler, uint32 plotId, Tail nameArg)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        Plot plot;
        if (!LoadPlotWhere("plot_id = " + std::to_string(plotId), plot) || (plot.ownerGuid != player->GetGUID().GetCounter() && !IsGM(player)))
        {
            handler->SendErrorMessage("没有这块地，或者它不是你的。");
            return false;
        }
        std::string name = UiText(std::string(nameArg), 30);
        while (!name.empty() && name.front() == ' ')
            name.erase(name.begin());
        while (!name.empty() && name.back() == ' ')
            name.pop_back();
        WorldDatabase.EscapeString(name);
        WorldDatabase.Execute("UPDATE reborn_housing_plot SET name = '{}' WHERE plot_id = {}", name, plotId);
        handler->PSendSysMessage("地块 {} 已改名。", plotId);
        return true;
    }

    // .home ui [plot_id | all]   data for the client's "My Homes" window; sends addon whispers, prints nothing
    //   (no argument)  H line + one P line per plot of yours + Z
    //   <plot_id>      T, then J lines (one per piece on that plot), then Y   (own plot, or any plot for a GM)
    //   all            GM only: Q line per plot of other players, then X
    static bool HandleUi(ChatHandler* handler, Optional<std::string> arg)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        bool gm = IsGM(player);
        uint32 guid = player->GetGUID().GetCounter();
        UiBatch out(player);

        if (!arg)
        {
            uint32 count = PlotCountOf(guid);
            uint32 price = ConfigCopper("Housing.Plot.Price", 10000000u);
            if (count == 0 && sConfigMgr->GetOption<bool>("Housing.Plot.FirstFree", false))
                price = 0;
            out.Line(Acore::StringFormat("H|{}|{}|{}|{}|{}|{}|{}|{}|{}|{:.1f}|{:.1f}|{}",
                guid, gm ? 1 : 0, sConfigMgr->GetOption<uint32>("Housing.Plot.MaxPerPlayer", 5), price,
                sConfigMgr->GetOption<uint32>("Housing.Tp.Cooldown", 60), ConfigCopper("Housing.Tp.SkipCost", 100000u),
                gm ? 0u : TpRemainSeconds(guid), player->GetMoney(), player->GetMapId(), player->GetPositionX(), player->GetPositionY(),
                sConfigMgr->GetOption<bool>("Housing.Plot.BuyEnabled", true) ? 1 : 0));
            QueryResult r = WorldDatabase.Query(
                "SELECT plot_id, owner_guid, map_id, x, y, z, radius, DATE_FORMAT(created, '%Y-%m-%d'), name FROM reborn_housing_plot "
                "WHERE owner_guid = {} ORDER BY plot_id LIMIT 50", guid);
            if (r)
            {
                uint32 maxObjs = sConfigMgr->GetOption<uint32>("Housing.MaxObjectsPerPlot", 60);
                do
                {
                    Field* f = r->Fetch();
                    Plot p = PlotFromRow(f);
                    // HOME5A: the plot's own name; the default (the owner's name from creation) is sent as empty
                    std::string plotName = f[8].Get<std::string>();
                    if (plotName == player->GetName())
                        plotName.clear();
                    out.Line(Acore::StringFormat("P|{}|{}|{:.1f}|{:.1f}|{:.1f}|{:.0f}|{}|{}|{}|{}",
                        p.id, p.mapId, p.x, p.y, p.z, p.radius, ObjectCount(p.id), maxObjs, f[7].Get<std::string>(), UiText(plotName, 30)));
                } while (r->NextRow());
            }
            out.Line("Z");
            return true;
        }

        if (*arg == "all")
        {
            if (!gm)
                return true;
            QueryResult r = WorldDatabase.Query(
                "SELECT p.plot_id, p.name, p.map_id, p.radius, (SELECT COUNT(*) FROM reborn_housing_object o WHERE o.plot_id = p.plot_id) "
                "FROM reborn_housing_plot p WHERE p.owner_guid <> {} ORDER BY p.plot_id LIMIT 150", guid);
            if (r)
            {
                do
                {
                    Field* f = r->Fetch();
                    out.Line(Acore::StringFormat("Q|{}|{}|{}|{:.0f}|{}", f[0].Get<uint32>(), UiText(f[1].Get<std::string>(), 24),
                        f[2].Get<uint32>(), f[3].Get<float>(), f[4].Get<uint32>()));
                } while (r->NextRow());
            }
            out.Line("X");
            return true;
        }

        uint32 plotId = static_cast<uint32>(std::strtoul(arg->c_str(), nullptr, 10));
        Plot plot;
        if (!plotId || !LoadPlotWhere("plot_id = " + std::to_string(plotId), plot) || (plot.ownerGuid != guid && !gm))
            return true;
        out.Line(Acore::StringFormat("T|{}", plot.id));
        QueryResult r = WorldDatabase.Query(
            "SELECT o.object_id, IFNULL(c.category, ''), IFNULL(c.name_zh, '?'), o.x, o.y, o.z, o.o, o.catalog_id, o.scale FROM reborn_housing_object o "
            "LEFT JOIN reborn_housing_catalog c ON c.catalog_id = o.catalog_id WHERE o.plot_id = {} ORDER BY o.object_id LIMIT 200", plot.id);
        if (r)
        {
            do
            {
                Field* f = r->Fetch();
                out.Line(Acore::StringFormat("J|{}|{}|{}|{:.1f}|{:.1f}|{}|{}|{:.3f}|{:.3f}|{:.3f}|{:.4f}|{:.3f}", plot.id, f[0].Get<uint32>(),
                    UiText(f[1].Get<std::string>(), 16), f[3].Get<float>() - plot.x, f[4].Get<float>() - plot.y,
                    UiText(f[2].Get<std::string>(), 30), f[7].Get<uint32>(), f[3].Get<float>(), f[4].Get<float>(), f[5].Get<float>(),
                    f[6].Get<float>(), f[8].Get<float>()));
            } while (r->NextRow());
        }
        out.Line(Acore::StringFormat("Y|{}", plot.id));
        return true;
    }

    // ------------------------------------------------------------------ catalog and decor

    // .home catalog [page]
    static bool HandleCatalog(ChatHandler* handler, Optional<uint32> pageArg)
    {
        uint32 page = pageArg ? std::max<uint32>(1, *pageArg) : 1;
        QueryResult r = WorldDatabase.Query(
            "SELECT catalog_id, name_zh, name_en, category FROM reborn_housing_catalog WHERE enabled = 1 ORDER BY category, catalog_id LIMIT 20 OFFSET {}",
            (page - 1) * 20);
        if (!r)
        {
            handler->SendSysMessage("目录里没有更多家具。");
            return true;
        }
        handler->PSendSysMessage("家具目录 第 {} 页（.home add <编号> 摆放）：", page);
        do
        {
            Field* f = r->Fetch();
            handler->PSendSysMessage("  {}：{} / {}  [{}]", f[0].Get<uint32>(), f[1].Get<std::string>(), f[2].Get<std::string>(), f[3].Get<std::string>());
        } while (r->NextRow());
        return true;
    }

    // .home add <catalog_id>   places the decor where you stand, facing the way you face
    static bool HandleAdd(ChatHandler* handler, uint32 catalogId)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;

        Plot plot;
        if (IsGM(player))
        {
            // a GM may place on whichever plot he is standing in
            QueryResult pr = WorldDatabase.Query("SELECT plot_id, owner_guid, map_id, x, y, z, radius FROM reborn_housing_plot WHERE map_id = {}", player->GetMapId());
            bool found = false;
            if (pr)
            {
                do
                {
                    Field* f = pr->Fetch();
                    Plot p;
                    p.id = f[0].Get<uint32>(); p.ownerGuid = f[1].Get<uint32>(); p.mapId = f[2].Get<uint32>();
                    p.x = f[3].Get<float>(); p.y = f[4].Get<float>(); p.z = f[5].Get<float>(); p.radius = f[6].Get<float>();
                    if (InsidePlot(p, player->GetMapId(), player->GetPositionX(), player->GetPositionY()))
                    {
                        plot = p;
                        found = true;
                        break;
                    }
                } while (pr->NextRow());
            }
            if (!found)
            {
                handler->SendErrorMessage("你不在任何地块里。");
                return false;
            }
        }
        else if (!FindMyPlot(player->GetGUID().GetCounter(), player->GetMapId(), player->GetPositionX(), player->GetPositionY(), plot))
        {
            handler->SendErrorMessage("你还没有家园地块。");
            return false;
        }

        if (!InsidePlot(plot, player->GetMapId(), player->GetPositionX(), player->GetPositionY()))
        {
            handler->SendErrorMessage("你不在自己的地块范围里（中心 {:.0f}, {:.0f}，半径 {:.0f} 码）。", plot.x, plot.y, plot.radius);
            return false;
        }

        uint32 cap = sConfigMgr->GetOption<uint32>("Housing.MaxObjectsPerPlot", 60);
        if (!IsGM(player) && ObjectCount(plot.id) >= cap)
        {
            handler->SendErrorMessage("这块地已经摆满了（上限 {} 件）。", cap);
            return false;
        }

        QueryResult cr = WorldDatabase.Query("SELECT gobject_entry FROM reborn_housing_catalog WHERE catalog_id = {} AND enabled = 1", catalogId);
        if (!cr)
        {
            handler->SendErrorMessage("目录里没有编号 {} 的家具。", catalogId);
            return false;
        }
        uint32 entry = cr->Fetch()[0].Get<uint32>();

        float x = player->GetPositionX(), y = player->GetPositionY(), z = player->GetPositionZ(), o = player->GetOrientation();
        uint32 spawnId = 0;
        if (!SpawnDecor(player, entry, x, y, z, o, spawnId))
        {
            handler->SendErrorMessage("摆放失败（模板 {} 不可用）。", entry);
            return false;
        }

        WorldDatabase.Execute(
            "INSERT INTO reborn_housing_object (plot_id, catalog_id, gobject_entry, spawn_id, map_id, x, y, z, o) VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {})",
            plot.id, catalogId, entry, spawnId, player->GetMapId(), x, y, z, o);
        QueryResult idr = WorldDatabase.Query("SELECT MAX(object_id) FROM reborn_housing_object WHERE spawn_id = {}", spawnId);
        handler->PSendSysMessage("已摆放 {}（物件编号 {}）。", CatalogName(catalogId), idr ? idr->Fetch()[0].Get<uint32>() : 0);
        return true;
    }

    // .home list
    static bool HandleList(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;
        Plot plot;
        if (!FindMyPlot(player->GetGUID().GetCounter(), player->GetMapId(), player->GetPositionX(), player->GetPositionY(), plot))
        {
            handler->SendSysMessage("你还没有家园地块。");
            return true;
        }
        handler->PSendSysMessage("地块 {} 的家具：", plot.id);
        QueryResult r = WorldDatabase.Query(
            "SELECT o.object_id, o.catalog_id, c.name_zh, o.x, o.y FROM reborn_housing_object o "
            "LEFT JOIN reborn_housing_catalog c ON c.catalog_id = o.catalog_id WHERE o.plot_id = {} ORDER BY o.object_id LIMIT 60", plot.id);
        if (!r)
        {
            handler->SendSysMessage("地块上还没有家具。");
            return true;
        }
        do
        {
            Field* f = r->Fetch();
            handler->PSendSysMessage("  物件 {}：{}，位置 ({:.0f}, {:.0f})", f[0].Get<uint32>(), f[2].IsNull() ? std::string("?") : f[2].Get<std::string>(),
                f[3].Get<float>(), f[4].Get<float>());
        } while (r->NextRow());
        return true;
    }

    // Common checks for move / rotate / remove: the row exists and its plot belongs to the player (or a GM).
    static bool OwnedObject(ChatHandler* handler, Player* player, uint32 objectId, ObjectRow& row, Plot& plot)
    {
        if (!LoadObject(objectId, row) || !LoadPlotWhere("plot_id = " + std::to_string(row.plotId), plot))
        {
            handler->SendErrorMessage("没有这件物件。");
            return false;
        }
        if (plot.ownerGuid != player->GetGUID().GetCounter() && !IsGM(player))
        {
            handler->SendErrorMessage("这件物件不是你的。");
            return false;
        }
        if (row.mapId != player->GetMapId())
        {
            handler->SendErrorMessage("请先站到这件物件所在的地图。");
            return false;
        }
        return true;
    }

    // .home remove <object_id>
    static bool HandleRemove(ChatHandler* handler, uint32 objectId)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        ObjectRow row;
        Plot plot;
        if (!OwnedObject(handler, player, objectId, row, plot))
            return false;
        if (!DespawnDecor(player, row.spawnId))
        {
            handler->SendErrorMessage("物件离得太远，没加载。请走近一些再试。");
            return false;
        }
        WorldDatabase.Execute("DELETE FROM reborn_housing_object WHERE object_id = {}", objectId);
        handler->PSendSysMessage("已收起物件 {}。", objectId);
        return true;
    }

    // Replaces the spawned decor of an object row by one at a new place/facing (the core cannot move a
    // loaded gameobject for the clients that already see it, so it is removed and spawned again).
    static bool Respawn(ChatHandler* handler, Player* player, ObjectRow const& row, float x, float y, float z, float o, float newScale = -1.0f)
    {
        float scale = newScale > 0.0f ? newScale : row.scale;
        if (!DespawnDecor(player, row.spawnId))
        {
            handler->SendErrorMessage("物件离得太远，没加载。请走近一些再试。");
            return false;
        }
        uint32 newSpawn = 0;
        if (!SpawnDecor(player, row.entry, x, y, z, o, newSpawn, scale))
        {
            // put the old one back so nothing is lost
            if (SpawnDecor(player, row.entry, row.x, row.y, row.z, row.o, newSpawn, row.scale))
                WorldDatabase.Execute("UPDATE reborn_housing_object SET spawn_id = {} WHERE object_id = {}", newSpawn, row.id);
            handler->SendErrorMessage("重新摆放失败，已放回原位。");
            return false;
        }
        WorldDatabase.Execute("UPDATE reborn_housing_object SET spawn_id = {}, x = {}, y = {}, z = {}, o = {}, scale = {} WHERE object_id = {}",
            newSpawn, x, y, z, o, scale, row.id);
        return true;
    }

    // ------------------------------------------------------------------ H3C: place / change a piece with exact numbers
    // The client's editor (drag, rotate, scale) ends in one of these two commands. The answer goes back as an addon
    // line "U|ok|<object_id>|text" or "U|err|text" so the client can drop its local preview, and as a chat line.
    static void UiReply(Player* player, bool ok, std::string const& text)
    {
        UiBatch out(player);
        out.Line(Acore::StringFormat("U|{}|{}", ok ? "ok" : "err", UiText(text, 150)));
    }

    // the plot (yours, or any for a GM) that contains the point; false when there is none
    static bool PlotAtPoint(Player* player, uint32 mapId, float x, float y, Plot& out)
    {
        QueryResult pr = WorldDatabase.Query("SELECT plot_id, owner_guid, map_id, x, y, z, radius FROM reborn_housing_plot WHERE map_id = {}", mapId);
        if (!pr)
            return false;
        bool gm = IsGM(player);
        uint32 guid = player->GetGUID().GetCounter();
        do
        {
            Plot p = PlotFromRow(pr->Fetch());
            if ((gm || p.ownerGuid == guid) && InsidePlot(p, mapId, x, y))
            {
                out = p;
                return true;
            }
        } while (pr->NextRow());
        return false;
    }

    static bool CheckPutArgs(ChatHandler* handler, Player* player, float x, float y, float z, float& o, Optional<float> const& scaleArg, float& scale, Plot& plot)
    {
        auto fail = [&](std::string const& text)
        {
            handler->SendErrorMessage("{}", text);
            UiReply(player, false, text);
            return false;
        };
        if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(z) || !std::isfinite(o))
            return fail("坐标不对。");
        if (!PlotAtPoint(player, player->GetMapId(), x, y, plot))
            return fail("那个位置不在你的地块里。");
        if (std::fabs(z - plot.z) > 150.0f)
            return fail("高度离地块太远。");
        float dx = x - player->GetPositionX(), dy = y - player->GetPositionY();
        if (std::sqrt(dx * dx + dy * dy) > plot.radius + 100.0f)
            return fail("你离那个位置太远，请走近一些。");
        o = std::fmod(o, 2.0f * kPi);
        if (o < 0.0f)
            o += 2.0f * kPi;
        float lo = sConfigMgr->GetOption<float>("Housing.Scale.Min", 0.25f);
        float hi = sConfigMgr->GetOption<float>("Housing.Scale.Max", 4.0f);
        scale = scaleArg ? *scaleArg : 1.0f;
        if (!std::isfinite(scale))
            scale = 1.0f;
        scale = std::min(std::max(scale, lo), hi);
        return true;
    }

    // .home put <catalog_id> <x> <y> <z> <o> [scale]
    static bool HandlePut(ChatHandler* handler, uint32 catalogId, float x, float y, float z, float o, Optional<float> scaleArg)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        Plot plot;
        float scale = 1.0f;
        if (!CheckPutArgs(handler, player, x, y, z, o, scaleArg, scale, plot))
            return false;

        uint32 cap = sConfigMgr->GetOption<uint32>("Housing.MaxObjectsPerPlot", 60);
        if (!IsGM(player) && ObjectCount(plot.id) >= cap)
        {
            std::string text = Acore::StringFormat("这块地已经摆满了（上限 {} 件）。", cap);
            handler->SendErrorMessage("{}", text);
            UiReply(player, false, text);
            return false;
        }
        QueryResult cr = WorldDatabase.Query("SELECT gobject_entry FROM reborn_housing_catalog WHERE catalog_id = {} AND enabled = 1", catalogId);
        if (!cr)
        {
            handler->SendErrorMessage("目录里没有编号 {} 的家具。", catalogId);
            UiReply(player, false, "目录里没有这件家具。");
            return false;
        }
        uint32 entry = cr->Fetch()[0].Get<uint32>();
        uint32 spawnId = 0;
        if (!SpawnDecor(player, entry, x, y, z, o, spawnId, scale))
        {
            handler->SendErrorMessage("摆放失败（模板 {} 不可用）。", entry);
            UiReply(player, false, "摆放失败，模板不可用。");
            return false;
        }
        WorldDatabase.Execute(
            "INSERT INTO reborn_housing_object (plot_id, catalog_id, gobject_entry, spawn_id, map_id, x, y, z, o, scale) VALUES ({}, {}, {}, {}, {}, {}, {}, {}, {}, {})",
            plot.id, catalogId, entry, spawnId, player->GetMapId(), x, y, z, o, scale);
        QueryResult idr = WorldDatabase.Query("SELECT MAX(object_id) FROM reborn_housing_object WHERE spawn_id = {}", spawnId);
        uint32 objectId = idr ? idr->Fetch()[0].Get<uint32>() : 0;
        handler->PSendSysMessage("已摆放 {}（物件编号 {}，大小 {:.2f}）。", CatalogName(catalogId), objectId, scale);
        UiReply(player, true, Acore::StringFormat("{}|{}", objectId, CatalogName(catalogId)));
        return true;
    }

    // .home set <object_id> <x> <y> <z> <o> [scale]
    static bool HandleSet(ChatHandler* handler, uint32 objectId, float x, float y, float z, float o, Optional<float> scaleArg)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        ObjectRow row;
        Plot ownPlot;
        if (!OwnedObject(handler, player, objectId, row, ownPlot))
        {
            UiReply(player, false, "这件物件不能改（不是你的，或不在这张地图）。");
            return false;
        }
        Plot plot;
        float scale = 1.0f;
        if (!CheckPutArgs(handler, player, x, y, z, o, scaleArg, scale, plot))
            return false;
        if (plot.id != row.plotId)
        {
            handler->SendErrorMessage("不能把物件挪到另一块地。");
            UiReply(player, false, "不能把物件挪到另一块地。");
            return false;
        }
        if (!Respawn(handler, player, row, x, y, z, o, scale))
        {
            UiReply(player, false, "物件离得太远或没加载，请走近一些再试。");
            return false;
        }
        handler->PSendSysMessage("物件 {} 已更新（大小 {:.2f}）。", objectId, scale);
        UiReply(player, true, Acore::StringFormat("{}|ok", objectId));
        return true;
    }

    // .home move <object_id>    moves it to where you stand (inside the plot), keeping its facing
    static bool HandleMove(ChatHandler* handler, uint32 objectId)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        ObjectRow row;
        Plot plot;
        if (!OwnedObject(handler, player, objectId, row, plot))
            return false;
        if (!InsidePlot(plot, player->GetMapId(), player->GetPositionX(), player->GetPositionY()))
        {
            handler->SendErrorMessage("你不在地块范围里，不能把家具挪到这里。");
            return false;
        }
        if (!Respawn(handler, player, row, player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), row.o))
            return false;
        handler->PSendSysMessage("物件 {} 已挪到你脚下。", objectId);
        return true;
    }

    // .home rotate <object_id> <degrees>   turns it by that many degrees (positive = anticlockwise from above)
    static bool HandleRotate(ChatHandler* handler, uint32 objectId, float degrees)
    {
        Player* player = handler->GetPlayer();
        if (!player || !Enabled())
            return false;
        ObjectRow row;
        Plot plot;
        if (!OwnedObject(handler, player, objectId, row, plot))
            return false;
        float o = std::fmod(row.o + degrees * kPi / 180.0f, 2.0f * kPi);
        if (o < 0.0f)
            o += 2.0f * kPi;
        if (!Respawn(handler, player, row, row.x, row.y, row.z, o))
            return false;
        handler->PSendSysMessage("物件 {} 已旋转 {:.0f} 度。", objectId, degrees);
        return true;
    }
};

class RebornHousingGameObjectScript : public AllGameObjectScript
{
public:
    RebornHousingGameObjectScript() : AllGameObjectScript("RebornHousingGameObjectScript") { }

    void OnGameObjectAddWorld(GameObject* go) override
    {
        if (!go || !IsHousingEntry(go->GetEntry()) || go->GetSpawnId() == 0)
            return;
        float scale = LookupScale(static_cast<uint32>(go->GetSpawnId()));
        if (scale != 1.0f && go->GetGOInfo())
            go->SetObjectScale(go->GetGOInfo()->size * scale);
    }
};

// The database pool is not up yet while scripts register, so the column check runs at world startup.
class RebornHousingWorldScript : public WorldScript
{
public:
    RebornHousingWorldScript() : WorldScript("RebornHousingWorldScript", { WORLDHOOK_ON_STARTUP }) { }
    void OnStartup() override { EnsureScaleColumn(); }
};

void AddSC_mod_reborn_housing()
{
    new RebornHousingCommandScript();
    new RebornHousingGameObjectScript();
    new RebornHousingWorldScript();
}
