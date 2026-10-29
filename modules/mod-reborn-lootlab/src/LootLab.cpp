#include "Chat.h"
#include "ChatCommand.h"
#include "Config.h"
#include "LootMgr.h"
#include "Log.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "World.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include <algorithm>
#include <functional>
#include <cstdio>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <cstdlib>
#include <cmath>
#include <limits>
#include <map>
#include <mutex>
#include <set>
#include <random>
#include <string>
#include <vector>

using namespace Acore::ChatCommands;

// LAB1 (掉落工坊 / LootLab): read-only. The GM panel sends ".lootlab ui <what> ..." and gets addon lines
// "LL\t<kind>\t<fields...>". Nothing here writes to the database.

namespace
{
    // One row per kind of loot table. Everything the commands do (list, read, who uses it, who drops an item,
    // simulate) is driven by this table, so a new kind of source is one more row.
    struct Kind
    {
        char const* key;
        char const* zh;
        char const* en;
        char const* table;      // the loot template table
        uint32 cond;            // conditions.SourceTypeOrReferenceId of that table
        // the list of sources: `from` with aliases, the columns, the fixed filter
        char const* from;
        char const* idCol;      // the source's own id
        char const* lootCol;    // the loot template entry it uses
        char const* nameCol;
        char const* zhCol;
        char const* info;       // an SQL expression, a short text per source
        char const* where;
        char const* rankCol;    // empty: no rank filter
        char const* mapExists;  // empty: no map filter; {MAP} is replaced
        // who uses a loot entry: `ufrom` WHERE `ucol` = id
        char const* ufrom;
        char const* uid;
        char const* uname;
        char const* uzh;
        char const* ucol;
        char const* uwhere;
        bool area;              // the loot entry is an area id
    };

    std::string const CT_LOC = "LEFT JOIN creature_template_locale l ON l.entry = ct.entry AND l.locale = 'zhCN'";
    std::string const IT_LOC = "LEFT JOIN item_template_locale l ON l.ID = it.entry AND l.locale = 'zhCN'";

    char const* const CT_FROM = "creature_template ct LEFT JOIN creature_template_locale l ON l.entry = ct.entry AND l.locale = 'zhCN'";
    char const* const GT_FROM = "gameobject_template gt LEFT JOIN gameobject_template_locale l ON l.entry = gt.entry AND l.locale = 'zhCN'";
    char const* const IT_FROM = "item_template it LEFT JOIN item_template_locale l ON l.ID = it.entry AND l.locale = 'zhCN'";
    char const* const CT_INFO =
        "CONCAT('Lv ', ct.minlevel, '-', ct.maxlevel, '  ', CASE ct.`rank` WHEN 0 THEN '普通' WHEN 1 THEN '精英' WHEN 2 THEN '稀有精英' WHEN 3 THEN '首领' ELSE '稀有' END)";
    char const* const CT_MAP = "EXISTS (SELECT 1 FROM creature c WHERE c.id1 = ct.entry AND c.map = {MAP})";

    Kind const KINDS[] =
    {
        { "creature", "怪物掉落", "Creature loot", "creature_loot_template", 1,
          CT_FROM, "ct.entry", "ct.lootid", "ct.name", "IFNULL(l.Name, '')", CT_INFO, "ct.lootid > 0", "ct.`rank`", CT_MAP,
          CT_FROM, "ct.entry", "ct.name", "IFNULL(l.Name, '')", "ct.lootid", "1 = 1", false },
        { "gameobject", "游戏物件", "Game objects", "gameobject_loot_template", 4,
          GT_FROM, "gt.entry", "gt.data1", "gt.name", "IFNULL(l.name, '')", "CONCAT('type ', gt.type)", "gt.type = 3 AND gt.data1 > 0", "",
          "EXISTS (SELECT 1 FROM gameobject g WHERE g.id = gt.entry AND g.map = {MAP})",
          GT_FROM, "gt.entry", "gt.name", "IFNULL(l.name, '')", "gt.data1", "gt.type = 3", false },
        { "skinning", "剥皮", "Skinning", "skinning_loot_template", 11,
          CT_FROM, "ct.entry", "ct.skinloot", "ct.name", "IFNULL(l.Name, '')", CT_INFO, "ct.skinloot > 0", "ct.`rank`", CT_MAP,
          CT_FROM, "ct.entry", "ct.name", "IFNULL(l.Name, '')", "ct.skinloot", "1 = 1", false },
        { "pickpocketing", "偷窃", "Pickpocketing", "pickpocketing_loot_template", 8,
          CT_FROM, "ct.entry", "ct.pickpocketloot", "ct.name", "IFNULL(l.Name, '')", CT_INFO, "ct.pickpocketloot > 0", "ct.`rank`", CT_MAP,
          CT_FROM, "ct.entry", "ct.name", "IFNULL(l.Name, '')", "ct.pickpocketloot", "1 = 1", false },
        { "fishing", "钓鱼", "Fishing", "fishing_loot_template", 3,
          "fishing_loot_template t", "t.Entry", "t.Entry", "''", "''", "''", "1 = 1", "", "",
          "", "", "", "", "", "", true },
        { "item", "可打开的物品", "Containers", "item_loot_template", 5,
          IT_FROM, "it.entry", "it.entry", "it.name", "IFNULL(l.Name, '')", "''", "1 = 1", "", "",
          IT_FROM, "it.entry", "it.name", "IFNULL(l.Name, '')", "it.entry", "1 = 1", false },
        { "disenchant", "分解", "Disenchanting", "disenchant_loot_template", 2,
          "disenchant_loot_template t", "t.Entry", "t.Entry", "''", "''",
          "IFNULL((SELECT it.name FROM item_template it WHERE it.DisenchantID = t.Entry LIMIT 1), '')", "1 = 1", "", "",
          IT_FROM, "it.entry", "it.name", "IFNULL(l.Name, '')", "it.DisenchantID", "1 = 1", false },
        { "prospecting", "选矿", "Prospecting", "prospecting_loot_template", 9,
          IT_FROM, "it.entry", "it.entry", "it.name", "IFNULL(l.Name, '')", "''", "1 = 1", "", "",
          IT_FROM, "it.entry", "it.name", "IFNULL(l.Name, '')", "it.entry", "1 = 1", false },
        { "milling", "研磨", "Milling", "milling_loot_template", 7,
          IT_FROM, "it.entry", "it.entry", "it.name", "IFNULL(l.Name, '')", "''", "1 = 1", "", "",
          IT_FROM, "it.entry", "it.name", "IFNULL(l.Name, '')", "it.entry", "1 = 1", false },
        { "reference", "引用表", "Reference tables", "reference_loot_template", 10,
          // a reference table has no name: its info is the first three items it holds, so the list says what is inside
          "reference_loot_template t", "t.Entry", "t.Entry", "''", "''",
          "IFNULL((SELECT SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(l2.Name, i2.name) ORDER BY r.Chance DESC SEPARATOR ', '), ', ', 3) "
          "FROM reference_loot_template r JOIN item_template i2 ON i2.entry = r.Item AND r.Reference = 0 "
          "LEFT JOIN item_template_locale l2 ON l2.ID = i2.entry AND l2.locale = 'zhCN' WHERE r.Entry = t.Entry), '')",
          "1 = 1", "", "",
          "", "", "", "", "", "", false },
    };
    constexpr std::size_t KIND_COUNT = sizeof(KINDS) / sizeof(KINDS[0]);

    Kind const* FindKind(std::string const& key)
    {
        for (Kind const& k : KINDS)
            if (key == k.key)
                return &k;
        return nullptr;
    }

    bool IsNumber(std::string const& s)
    {
        return !s.empty() && s.size() < 10 && std::all_of(s.begin(), s.end(), [](char ch) { return ch >= '0' && ch <= '9'; });
    }

    uint32 Num(std::string const& s)
    {
        return IsNumber(s) ? static_cast<uint32>(std::strtoul(s.c_str(), nullptr, 10)) : 0;
    }

    std::string Fld(std::string s)
    {
        for (char& ch : s)
            if (ch == '\t' || ch == '\n' || ch == '\r' || ch == '|')
                ch = ' ';
        return s;
    }

    std::string Clip(std::string s, std::size_t max = 250)
    {
        if (s.size() <= max)
            return s;
        std::size_t cut = max;
        while (cut > 0 && (static_cast<unsigned char>(s[cut]) & 0xC0) == 0x80)
            --cut;
        s.resize(cut);
        return s;
    }

    void Send(Player* player, std::string const& payload)
    {
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_PARTY, LANG_ADDON, player->GetGUID(), ObjectGuid::Empty,
                                     Clip("LL\t" + payload), CHAT_TAG_NONE, player->GetName());
        player->SendDirectMessage(&data);
    }

    std::vector<std::string> Split(std::string const& text)
    {
        std::vector<std::string> out;
        std::size_t i = 0;
        while (i < text.size())
        {
            while (i < text.size() && text[i] == ' ')
                ++i;
            std::size_t j = i;
            while (j < text.size() && text[j] != ' ')
                ++j;
            if (j > i)
                out.push_back(text.substr(i, j - i));
            i = j;
        }
        return out;
    }

    std::string Rest(std::string const& text, std::size_t skip)
    {
        std::size_t i = 0;
        for (std::size_t w = 0; w < skip; ++w)
        {
            while (i < text.size() && text[i] == ' ')
                ++i;
            while (i < text.size() && text[i] != ' ')
                ++i;
        }
        while (i < text.size() && text[i] == ' ')
            ++i;
        return text.substr(i);
    }

    std::string Sub(std::string s, char const* token, std::string const& value)
    {
        std::size_t p = 0;
        std::string const t = token;
        while ((p = s.find(t, p)) != std::string::npos)
        {
            s.replace(p, t.size(), value);
            p += value.size();
        }
        return s;
    }

    std::string Id(uint32 n) { return std::to_string(n); }

    QueryResult Q(std::string const& sql)
    {
        return WorldDatabase.Query("{}", sql);
    }

    std::string IconOfDisplay(uint32 displayId)
    {
        ItemDisplayInfoEntry const* e = sItemDisplayInfoStore.LookupEntry(displayId);
        if (e && e->inventoryIcon && *e->inventoryIcon)
            return std::string("Interface\\Icons\\") + e->inventoryIcon;
        return "Interface\\Icons\\INV_Misc_QuestionMark";
    }

    // The server's own DBC structure leaves out the model file name of a creature, so CreatureModelData.dbc is read here
    // (id = field 0, model name = field 2, a string offset), once, from the server's data folder.
    std::map<uint32, std::string> const& ModelPaths()
    {
        static std::map<uint32, std::string> paths;
        static bool loaded = false;
        if (loaded)
            return paths;
        loaded = true;
        std::string const file = sWorld->GetDataPath() + "dbc/CreatureModelData.dbc";
        FILE* f = fopen(file.c_str(), "rb");
        if (!f)
        {
            LOG_WARN("module", "[LootLab] cannot open {}: creature heads will show as icons", file);
            return paths;
        }
        uint32 h[5] = { 0, 0, 0, 0, 0 };
        if (fread(h, 4, 5, f) == 5 && h[0] == 0x43424457 && h[3] >= 12 && h[1] < 200000 && h[4] < 16000000)
        {
            std::vector<char> rec(static_cast<std::size_t>(h[1]) * h[3]);
            std::vector<char> str(h[4] + 1, '\0');
            if (fread(rec.data(), 1, rec.size(), f) == rec.size() && fread(str.data(), 1, h[4], f) == h[4])
                for (uint32 i = 0; i < h[1]; ++i)
                {
                    uint32 const* r = reinterpret_cast<uint32 const*>(rec.data() + static_cast<std::size_t>(i) * h[3]);
                    if (r[2] < h[4] && str[r[2]])
                        paths[r[0]] = &str[r[2]];
                }
        }
        fclose(f);
        return paths;
    }

    std::string ModelOf(char const* kindKey, uint32 displayId)
    {
        if (!displayId)
            return "";
        if (std::string(kindKey) == "gameobject")
        {
            if (GameObjectDisplayInfoEntry const* d = sGameObjectDisplayInfoStore.LookupEntry(displayId))
                return d->filename ? d->filename : "";
            return "";
        }
        if (CreatureDisplayInfoEntry const* e = sCreatureDisplayInfoStore.LookupEntry(displayId))
        {
            auto const& m = ModelPaths();
            auto it = m.find(e->ModelId);
            if (it != m.end())
                return it->second;
        }
        return "";
    }

    std::string AreaNameOf(uint32 id, LocaleConstant loc)
    {
        if (AreaTableEntry const* e = sAreaTableStore.LookupEntry(id))
            return (e->area_name[loc] && *e->area_name[loc]) ? e->area_name[loc] : (e->area_name[0] ? e->area_name[0] : "?");
        return "?";
    }

    std::string MapNameOf(uint32 id, LocaleConstant loc)
    {
        if (MapEntry const* e = sMapStore.LookupEntry(id))
            return (e->name[loc] && *e->name[loc]) ? e->name[loc] : (e->name[0] ? e->name[0] : "?");
        return "?";
    }

    void Fail(ChatHandler* handler, Player* p, std::string const& what)
    {
        Send(p, "ERR\t" + Fld(what));
        handler->PSendSysMessage("|cffff0000[掉落工坊]|r {}", what);
    }

    // ---- kinds: the tabs, with how many loot tables each has
    void SendKinds(Player* p)
    {
        Send(p, "KD_START");
        for (Kind const& k : KINDS)
        {
            uint32 n = 0;
            if (QueryResult r = Q(std::string("SELECT COUNT(DISTINCT Entry) FROM ") + k.table))
                n = r->Fetch()[0].Get<uint32>();
            Send(p, Acore::StringFormat("KD\t{}\t{}\t{}\t{}\t{}\t{}", k.key, k.zh, k.en, n, k.rankCol[0] ? 1 : 0, k.mapExists[0] ? 1 : 0));
        }
        Send(p, "KD_END");
    }

    // ---- the maps that have something to look at (the world tree's top level)
    void SendMaps(Player* p)
    {
        LocaleConstant const loc = p->GetSession()->GetSessionDbcLocale();
        Send(p, "MP_START");
        // dungeons, raids, battlegrounds and the open world, by the map table (instance type 0 = world)
        for (uint32 i = 0; i < sMapStore.GetNumRows(); ++i)
            if (MapEntry const* e = sMapStore.LookupEntry(i))
                if (e->IsDungeon() || e->IsRaid() || i == 0 || i == 1 || i == 530 || i == 571)
                    Send(p, Acore::StringFormat("MP\t{}\t{}\t{}", i, e->IsDungeon() ? (e->IsRaid() ? 2 : 1) : 0, Fld(MapNameOf(i, loc))));
        Send(p, "MP_END");
    }

    // ---- the list of sources of one kind
    void SendList(Player* p, Kind const& k, int rank, int mapId, uint32 page, std::string text)
    {
        LocaleConstant const loc = p->GetSession()->GetSessionDbcLocale();
        text.erase(std::remove_if(text.begin(), text.end(), [](char ch) { return ch == '%' || ch == '_' || ch == '\\' || ch == '\''; }), text.end());
        WorldDatabase.EscapeString(text);

        std::string where = std::string("(") + k.where + ") AND EXISTS (SELECT 1 FROM " + k.table + " x WHERE x.Entry = " + k.lootCol + ")";
        if (rank >= 0 && k.rankCol[0])
            where += std::string(" AND ") + k.rankCol + " = " + Id(static_cast<uint32>(rank));
        if (mapId >= 0 && k.mapExists[0])
            where += " AND " + Sub(k.mapExists, "{MAP}", Id(static_cast<uint32>(mapId)));
        if (!text.empty())
        {
            if (IsNumber(text))
                where += std::string(" AND (") + k.idCol + " = " + Id(Num(text)) + " OR " + k.lootCol + " = " + Id(Num(text)) + ")";
            else if (!k.area)
                where += std::string(" AND (") + k.nameCol + " LIKE '%" + text + "%' OR " + k.zhCol + " LIKE '%" + text + "%')";
        }

        constexpr uint32 PAGE = 40;
        bool const one = std::string(k.idCol) == "t.Entry";   // the loot tables themselves (fishing, disenchant, reference): one row per entry
        std::string sql = std::string("SELECT ") + (one ? "DISTINCT " : "") + k.idCol + ", " + k.lootCol + ", " + k.nameCol + ", " + k.zhCol + ", " + k.info + ", " + (k.rankCol[0] ? k.rankCol : "0") + ", " + (k.rankCol[0] ? "ct.`type`, ct.family" : "0, 0") + ", " +
                          (k.rankCol[0] ? "IFNULL((SELECT m.CreatureDisplayID FROM creature_template_model m WHERE m.CreatureID = ct.entry ORDER BY m.Idx LIMIT 1), 0)"
                                        : (std::string(k.key) == "gameobject" ? "gt.displayId" : "0")) +
                          " FROM " + k.from + " WHERE " + where + " ORDER BY " + k.idCol + " LIMIT " + Id(PAGE + 1) + " OFFSET " + Id(page * PAGE);
        QueryResult r = Q(sql);
        uint32 count = 0;
        bool more = false;
        if (!r)
            LOG_INFO("module", "[LootLab] list of '{}' returned no rows (an empty result, or a SQL error above): {}", k.key, sql);
        Send(p, Acore::StringFormat("SRC_START\t{}\t{}", k.key, page));
        try
        {
        if (r)
        {
            do
            {
                if (count == PAGE)
                {
                    more = true;
                    break;
                }
                Field* f = r->Fetch();
                uint32 const id = f[0].Get<uint32>();
                std::string name = Fld(f[2].Get<std::string>());
                std::string zh = Fld(f[3].Get<std::string>());
                std::string info = Fld(f[4].Get<std::string>());
                if (k.area)
                {
                    name = Fld(AreaNameOf(id, LOCALE_enUS));
                    zh = Fld(AreaNameOf(id, loc));
                }
                Send(p, Acore::StringFormat("SRC\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", id, f[1].Get<uint32>(), f[5].Get<uint32>(), f[6].Get<uint32>(), f[7].Get<uint32>(), Fld(ModelOf(k.key, f[8].Get<uint32>())), Clip(info, 40), name, zh, f[8].Get<uint32>()));
                ++count;
            } while (r->NextRow());
        }
        }
        catch (std::exception const& e)
        {
            LOG_ERROR("module", "[LootLab] list of '{}' failed after {} rows: {}", k.key, count, e.what());
            Send(p, "ERR\tlist " + std::string(k.key) + ": " + Fld(e.what()));
        }
        Send(p, Acore::StringFormat("SRC_END\t{}\t{}\t{}", page, more ? 1 : 0, count));
    }

    // ---- one loot table
    void SendLoot(Player* p, Kind const& k, uint32 lootId)
    {
        std::map<uint32, uint32> conds;
        if (QueryResult c = Q("SELECT SourceEntry, COUNT(*) FROM conditions WHERE SourceTypeOrReferenceId = " + Id(k.cond) +
                              " AND SourceGroup = " + Id(lootId) + " GROUP BY SourceEntry"))
            do
                conds[c->Fetch()[0].Get<uint32>()] = c->Fetch()[1].Get<uint32>();
            while (c->NextRow());

        QueryResult r = Q(std::string("SELECT g.Item, g.Chance, g.MinCount, g.MaxCount, g.GroupId, g.QuestRequired, g.Reference, i.Quality, i.displayid, "
                                      "IFNULL(i.name, ''), IFNULL(l.Name, '') FROM ") + k.table + " g LEFT JOIN item_template i ON i.entry = g.Item "
                          "LEFT JOIN item_template_locale l ON l.ID = g.Item AND l.locale = 'zhCN' WHERE g.Entry = " + Id(lootId) +
                          " ORDER BY g.GroupId, g.Reference, g.Item LIMIT 250");
        Send(p, Acore::StringFormat("LT_START\t{}\t{}", k.key, lootId));
        uint32 n = 0;
        if (r)
        {
            do
            {
                Field* f = r->Fetch();
                uint32 const item = f[0].Get<uint32>();
                uint32 const ref = f[6].Get<uint32>();
                uint32 nc = 0;
                if (auto it = conds.find(item); it != conds.end())
                    nc = it->second;
                std::string icon = ref ? "Interface\\Icons\\INV_Misc_Note_01" : IconOfDisplay(f[8].Get<uint32>());
                std::string nameEn = Fld(f[9].Get<std::string>()), nameZh = Fld(f[10].Get<std::string>());
                if (ref)
                {
                    // a reference line says what is inside: "<count>|<first items>"
                    nameEn = nameZh = "0|";
                    if (QueryResult s = Q("SELECT COUNT(*), SUBSTRING_INDEX(GROUP_CONCAT(i.name ORDER BY r.Chance DESC SEPARATOR ', '), ', ', 3), "
                                          "SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(l.Name, i.name) ORDER BY r.Chance DESC SEPARATOR ', '), ', ', 3) "
                                          "FROM reference_loot_template r JOIN item_template i ON i.entry = r.Item AND r.Reference = 0 "
                                          "LEFT JOIN item_template_locale l ON l.ID = i.entry AND l.locale = 'zhCN' WHERE r.Entry = " + Id(ref)))
                    {
                        Field* sf = s->Fetch();
                        uint32 const cnt = sf[0].Get<uint32>();
                        nameEn = Id(cnt) + "|" + Clip(Fld(sf[1].Get<std::string>()), 60);
                        nameZh = Id(cnt) + "|" + Clip(Fld(sf[2].Get<std::string>()), 60);
                    }
                }
                Send(p, Acore::StringFormat("LT\t{}\t{}\t{:.2f}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", k.key, ref ? 0 : item, f[1].Get<float>(),
                                            f[2].Get<uint32>(), f[3].Get<uint32>(), f[4].Get<uint32>(), f[5].Get<uint32>(), nc, ref,
                                            ref ? 0 : f[7].Get<uint32>(), icon, nameEn + "\t" + nameZh));
                ++n;
            } while (r->NextRow());
        }
        Send(p, Acore::StringFormat("LT_END\t{}\t{}\t{}", k.key, lootId, n));
    }

    // ---- who uses a loot table ("被 N 个来源使用")
    void SendUsers(Player* p, Kind const& k, uint32 lootId)
    {
        LocaleConstant const loc = p->GetSession()->GetSessionDbcLocale();
        Send(p, Acore::StringFormat("US_START\t{}\t{}", k.key, lootId));
        uint32 total = 0, sent = 0;
        if (k.area)
        {
            total = 1;
            Send(p, Acore::StringFormat("US\t{}\t{}\t{}", lootId, Fld(AreaNameOf(lootId, LOCALE_enUS)), Fld(AreaNameOf(lootId, loc))));
            sent = 1;
        }
        else if (!k.ufrom[0])
        {
            // a reference table: every loot table of every kind that has a line pointing at it
            for (Kind const& o : KINDS)
            {
                if (QueryResult r = Q(std::string("SELECT COUNT(DISTINCT Entry), MIN(Entry) FROM ") + o.table + " WHERE Reference = " + Id(lootId)))
                {
                    Field* f = r->Fetch();
                    uint32 const n = f[0].Get<uint32>();
                    if (!n)
                        continue;
                    total += n;
                    if (sent < 12)
                    {
                        ++sent;
                        Send(p, Acore::StringFormat("US\t{}\t{}\t{}", f[1].Get<uint32>(), Fld(std::string(o.en) + " x" + Id(n)), Fld(std::string(o.zh) + " x" + Id(n))));
                    }
                }
            }
        }
        else
        {
            std::string const where = std::string(k.ucol) + " = " + Id(lootId) + " AND " + k.uwhere;
            if (QueryResult c = Q(std::string("SELECT COUNT(*) FROM ") + k.ufrom + " WHERE " + where))
                total = c->Fetch()[0].Get<uint32>();
            if (QueryResult r = Q(std::string("SELECT ") + k.uid + ", " + k.uname + ", " + k.uzh + " FROM " + k.ufrom + " WHERE " + where + " ORDER BY " + k.uid + " LIMIT 12"))
                do
                {
                    Field* f = r->Fetch();
                    Send(p, Acore::StringFormat("US\t{}\t{}\t{}", f[0].Get<uint32>(), Fld(f[1].Get<std::string>()), Fld(f[2].Get<std::string>())));
                    ++sent;
                } while (r->NextRow());
        }
        Send(p, Acore::StringFormat("US_END\t{}\t{}\t{}", k.key, lootId, total));
    }

    // ---- simulate: roll a table many times with the server's own rules (without conditions and quest lines)
    struct SimRow
    {
        uint32 item, ref, minC, maxC, group;
        float chance;
    };

    struct Sim
    {
        std::map<uint32, std::vector<SimRow>> cache;   // table + entry
        std::mt19937 rng{std::random_device{}()};
        uint32 skippedQuest = 0;

        std::vector<SimRow> const& Rows(Kind const& k, uint32 entry)
        {
            uint32 const key = (static_cast<uint32>(&k - KINDS) << 28) ^ entry;   // entries are well below 2^28
            auto it = cache.find(key);
            if (it != cache.end())
                return it->second;
            std::vector<SimRow> v;
            if (QueryResult r = Q(std::string("SELECT Item, Reference, MinCount, MaxCount, GroupId, Chance, QuestRequired FROM ") + k.table +
                                  " WHERE Entry = " + Id(entry)))
                do
                {
                    Field* f = r->Fetch();
                    if (f[6].Get<uint32>() && !f[1].Get<uint32>())
                    {
                        ++skippedQuest;
                        continue;
                    }
                    v.push_back({ f[0].Get<uint32>(), f[1].Get<uint32>(), std::max<uint32>(1, f[2].Get<uint32>()), std::max<uint32>(1, f[3].Get<uint32>()),
                                  f[4].Get<uint32>(), std::fabs(f[5].Get<float>()) });
                } while (r->NextRow());
            return cache.emplace(key, std::move(v)).first->second;
        }

        float Roll() { return std::uniform_real_distribution<float>(0.f, 100.f)(rng); }
        uint32 Between(uint32 a, uint32 b) { return a >= b ? a : std::uniform_int_distribution<uint32>(a, b)(rng); }

        void Emit(Kind const& k, SimRow const& row, uint32 depth, std::map<uint32, std::pair<uint32, uint32>>& out, std::map<uint32, bool>& seen)
        {
            if (row.ref)
            {
                if (depth >= 3)
                    return;
                Kind const& rk = *FindKind("reference");
                uint32 const times = row.maxC;
                for (uint32 t = 0; t < times; ++t)
                    Table(rk, row.ref, depth + 1, out, seen);
                return;
            }
            uint32 const qty = Between(row.minC, row.maxC);
            out[row.item].second += qty;
            if (!seen[row.item])
            {
                seen[row.item] = true;
                out[row.item].first += 1;
            }
            (void)k;
        }

        void Table(Kind const& k, uint32 entry, uint32 depth, std::map<uint32, std::pair<uint32, uint32>>& out, std::map<uint32, bool>& seen)
        {
            std::vector<SimRow> const& rows = Rows(k, entry);
            std::map<uint32, std::vector<SimRow const*>> groups;
            for (SimRow const& row : rows)
            {
                if (row.group == 0)
                {
                    if (row.chance >= 100.f || Roll() < row.chance)
                        Emit(k, row, depth, out, seen);
                }
                else
                    groups[row.group].push_back(&row);
            }
            for (auto& g : groups)
            {
                std::vector<SimRow const*> equal;
                float sum = 0.f;
                for (SimRow const* row : g.second)
                    if (row->chance > 0.f)
                        sum += row->chance;
                    else
                        equal.push_back(row);
                float r = Roll();
                bool done = false;
                for (SimRow const* row : g.second)
                {
                    if (row->chance <= 0.f)
                        continue;
                    if (r < row->chance)
                    {
                        Emit(k, *row, depth, out, seen);
                        done = true;
                        break;
                    }
                    r -= row->chance;
                }
                if (!done && !equal.empty() && sum < 100.f)
                    Emit(k, *equal[std::uniform_int_distribution<std::size_t>(0, equal.size() - 1)(rng)], depth, out, seen);
            }
        }
    };

    void SendSim(Player* p, Kind const& k, uint32 lootId, uint32 runs)
    {
        uint32 const maxRuns = std::max<uint32>(1, sConfigMgr->GetOption<uint32>("RebornLootLab.SimMaxRuns", 20000));
        runs = std::min(std::max<uint32>(1, runs), maxRuns);
        Sim sim;
        std::map<uint32, std::pair<uint32, uint32>> out;   // item -> (runs it dropped in, total quantity)
        std::map<uint32, std::pair<uint32, uint32>> total;
        for (uint32 i = 0; i < runs; ++i)
        {
            std::map<uint32, bool> seen;
            std::map<uint32, std::pair<uint32, uint32>> one;
            sim.Table(k, lootId, 0, one, seen);
            for (auto const& kv : one)
            {
                total[kv.first].first += 1;
                total[kv.first].second += kv.second.second;
            }
        }
        std::vector<std::pair<uint32, std::pair<uint32, uint32>>> order(total.begin(), total.end());
        std::sort(order.begin(), order.end(), [](auto const& a, auto const& b) { return a.second.first > b.second.first; });

        Send(p, Acore::StringFormat("SM_START\t{}\t{}\t{}", k.key, lootId, runs));
        uint32 sent = 0;
        for (auto const& kv : order)
        {
            if (sent >= 60)
                break;
            ++sent;
            std::string name, zh, icon = "Interface\\Icons\\INV_Misc_QuestionMark";
            uint32 quality = 1;
            if (QueryResult r = Q("SELECT i.Quality, i.displayid, i.name, IFNULL(l.Name, '') FROM item_template i LEFT JOIN item_template_locale l ON l.ID = i.entry "
                                  "AND l.locale = 'zhCN' WHERE i.entry = " + Id(kv.first)))
            {
                Field* f = r->Fetch();
                quality = f[0].Get<uint32>();
                icon = IconOfDisplay(f[1].Get<uint32>());
                name = Fld(f[2].Get<std::string>());
                zh = Fld(f[3].Get<std::string>());
            }
            Send(p, Acore::StringFormat("SM\t{}\t{}\t{}\t{}\t{}\t{}\t{}", kv.first, kv.second.first, kv.second.second, quality, icon, name, zh));
        }
        Send(p, Acore::StringFormat("SM_END\t{}\t{}\t{}\t{}", k.key, lootId, runs, sim.skippedQuest));
    }

    // ---- reverse lookup: who drops this item
    void SendWho(Player* p, uint32 item)
    {
        Send(p, Acore::StringFormat("WH_START\t{}", item));
        uint32 sent = 0;
        auto owner = [&](Kind const& k, uint32 lootId, float chance, uint32 quest, uint32 via)
        {
            if (sent >= 60)
                return;
            ++sent;
            uint32 users = 0;
            std::string name, zh;
            if (k.area)
            {
                users = 1;
                name = AreaNameOf(lootId, LOCALE_enUS);
                zh = AreaNameOf(lootId, p->GetSession()->GetSessionDbcLocale());
            }
            else if (k.ufrom[0])
            {
                std::string const where = std::string(k.ucol) + " = " + Id(lootId) + " AND " + k.uwhere;
                if (QueryResult c = Q(std::string("SELECT COUNT(*) FROM ") + k.ufrom + " WHERE " + where))
                    users = c->Fetch()[0].Get<uint32>();
                if (QueryResult r = Q(std::string("SELECT ") + k.uname + ", " + k.uzh + " FROM " + k.ufrom + " WHERE " + where + " ORDER BY " + k.uid + " LIMIT 1"))
                {
                    name = r->Fetch()[0].Get<std::string>();
                    zh = r->Fetch()[1].Get<std::string>();
                }
            }
            Send(p, Acore::StringFormat("WH\t{}\t{}\t{:.2f}\t{}\t{}\t{}\t{}\t{}", k.key, lootId, chance, quest, via, users, Fld(name), Fld(zh)));
        };

        for (Kind const& k : KINDS)
        {
            if (QueryResult r = Q(std::string("SELECT Entry, Chance, QuestRequired FROM ") + k.table + " WHERE Item = " + Id(item) + " AND Reference = 0 ORDER BY Entry LIMIT 30"))
                do
                {
                    Field* f = r->Fetch();
                    owner(k, f[0].Get<uint32>(), std::fabs(f[1].Get<float>()), f[2].Get<uint32>(), 0);
                } while (r->NextRow());
        }
        // one step through the reference tables: tables that point at a reference table holding the item
        if (QueryResult refs = Q("SELECT DISTINCT Entry FROM reference_loot_template WHERE Item = " + Id(item) + " AND Reference = 0 LIMIT 8"))
            do
            {
                uint32 const ref = refs->Fetch()[0].Get<uint32>();
                for (Kind const& k : KINDS)
                    if (QueryResult r = Q(std::string("SELECT DISTINCT Entry FROM ") + k.table + " WHERE Reference = " + Id(ref) + " ORDER BY Entry LIMIT 8"))
                        do
                            owner(k, r->Fetch()[0].Get<uint32>(), 0.f, 0, ref);
                        while (r->NextRow());
            } while (refs->NextRow());
        Send(p, Acore::StringFormat("WH_END\t{}\t{}", item, sent));
    }

    // ---- item search for the reverse lookup
    void SendItems(Player* p, uint32 page, std::string text)
    {
        text.erase(std::remove_if(text.begin(), text.end(), [](char ch) { return ch == '%' || ch == '_' || ch == '\\' || ch == '\''; }), text.end());
        WorldDatabase.EscapeString(text);
        std::string where = "1 = 1";
        if (!text.empty())
            where = IsNumber(text) ? "i.entry = " + Id(Num(text)) : "(i.name LIKE '%" + text + "%' OR l.Name LIKE '%" + text + "%')";
        constexpr uint32 PAGE = 30;
        QueryResult r = Q("SELECT i.entry, i.Quality, i.displayid, i.name, IFNULL(l.Name, '') FROM item_template i LEFT JOIN item_template_locale l ON l.ID = i.entry "
                          "AND l.locale = 'zhCN' WHERE " + where + " ORDER BY i.Quality DESC, i.entry LIMIT " + Id(PAGE + 1) + " OFFSET " + Id(page * PAGE));
        uint32 count = 0;
        bool more = false;
        Send(p, Acore::StringFormat("IT_START\t{}", page));
        if (r)
            do
            {
                if (count == PAGE)
                {
                    more = true;
                    break;
                }
                Field* f = r->Fetch();
                Send(p, Acore::StringFormat("IT\t{}\t{}\t{}\t{}\t{}", f[0].Get<uint32>(), f[1].Get<uint32>(), IconOfDisplay(f[2].Get<uint32>()),
                                            Fld(f[3].Get<std::string>()), Fld(f[4].Get<std::string>())));
                ++count;
            } while (r->NextRow());
        Send(p, Acore::StringFormat("IT_END\t{}\t{}\t{}", page, more ? 1 : 0, count));
    }

    // ---- the change log (LAB2 fills it; here it is only read)
    void SendLog(Player* p)
    {
        Send(p, "LG_START");
        QueryResult has = Q("SHOW TABLES LIKE 'reborn_lootlab_log'");
        if (has)
            if (QueryResult r = Q("SELECT id, UNIX_TIMESTAMP(at), who, kind, loot_id, action FROM reborn_lootlab_log ORDER BY id DESC LIMIT 60"))
                do
                {
                    Field* f = r->Fetch();
                    Send(p, Acore::StringFormat("LG\t{}\t{}\t{}\t{}\t{}\t{}", f[0].Get<uint32>(), f[1].Get<uint64>(), Fld(f[2].Get<std::string>()),
                                                Fld(f[3].Get<std::string>()), f[4].Get<uint32>(), Fld(Clip(f[5].Get<std::string>(), 80))));
                } while (r->NextRow());
        Send(p, Acore::StringFormat("LG_END\t{}", has ? 1 : 0));
    }

    // =====================================================================
    // LAB2: editing one loot table. Off unless RebornLootLab.Edit.Enable = 1.
    //   Edit.Lock = 1           production lock: nobody edits, whatever their level
    //   Edit.MinSecurity = 3    the lowest account level that may edit (3 = administrator)
    // Before the first change to a table its official content is saved once (INSERT IGNORE, never overwritten);
    // every change writes a log row holding the rows before and after; "restore" and "undo" read those back.
    // Snapshots are JSON made by MySQL (JSON_ARRAYAGG) and read back with JSON_TABLE, so no JSON is parsed here.
    // =====================================================================
    bool EditEnabled() { return sConfigMgr->GetOption<bool>("RebornLootLab.Edit.Enable", false); }
    bool EditLocked() { return sConfigMgr->GetOption<bool>("RebornLootLab.Edit.Lock", false); }
    bool MayEdit(Player* p)
    {
        return EditEnabled() && !EditLocked() &&
               static_cast<uint32>(p->GetSession()->GetSecurity()) >= sConfigMgr->GetOption<uint32>("RebornLootLab.Edit.MinSecurity", 3);
    }

    std::mutex g_dirtyMu;
    std::set<std::string> g_dirty;   // kinds whose loot store must be read again (done on the world thread, see the WorldScript)

    void ReloadKind(std::string const& key)
    {
        if (key == "creature") { LoadLootTemplates_Creature(); LootTemplates_Creature.CheckLootRefs(); }
        else if (key == "gameobject") { LoadLootTemplates_Gameobject(); LootTemplates_Gameobject.CheckLootRefs(); }
        else if (key == "skinning") { LoadLootTemplates_Skinning(); LootTemplates_Skinning.CheckLootRefs(); }
        else if (key == "pickpocketing") { LoadLootTemplates_Pickpocketing(); LootTemplates_Pickpocketing.CheckLootRefs(); }
        else if (key == "fishing") { LoadLootTemplates_Fishing(); LootTemplates_Fishing.CheckLootRefs(); }
        else if (key == "item") { LoadLootTemplates_Item(); LootTemplates_Item.CheckLootRefs(); }
        else if (key == "disenchant") { LoadLootTemplates_Disenchant(); LootTemplates_Disenchant.CheckLootRefs(); }
        else if (key == "prospecting") { LoadLootTemplates_Prospecting(); LootTemplates_Prospecting.CheckLootRefs(); }
        else if (key == "milling") { LoadLootTemplates_Milling(); LootTemplates_Milling.CheckLootRefs(); }
        else if (key == "reference") { LoadLootTemplates_Reference(); }
    }

    std::string Snapshot(Kind const& k, uint32 lootId)
    {
        std::string out = "[]";
        if (QueryResult r = Q(std::string("SELECT CAST(IFNULL(JSON_ARRAYAGG(JSON_OBJECT('Entry', Entry, 'Item', Item, 'Reference', Reference, 'Chance', Chance, "
                                          "'QuestRequired', QuestRequired, 'LootMode', LootMode, 'GroupId', GroupId, 'MinCount', MinCount, 'MaxCount', MaxCount, "
                                          "'Comment', IFNULL(Comment, ''))), '[]') AS CHAR) FROM ") + k.table + " WHERE Entry = " + Id(lootId)))
            out = r->Fetch()[0].Get<std::string>();
        return out.empty() ? "[]" : out;
    }

    std::string Esc(std::string s)
    {
        WorldDatabase.EscapeString(s);
        return s;
    }

    // replace the whole table of one loot id by a snapshot
    void ApplySnapshot(Kind const& k, uint32 lootId, std::string const& json)
    {
        auto trans = WorldDatabase.BeginTransaction();
        trans->Append(std::string("DELETE FROM ") + k.table + " WHERE Entry = " + Id(lootId));
        trans->Append(std::string("INSERT INTO ") + k.table + " (Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment) "
                      "SELECT jt.Entry, jt.Item, jt.Reference, jt.Chance, jt.QuestRequired, jt.LootMode, jt.GroupId, jt.MinCount, jt.MaxCount, jt.Comment FROM JSON_TABLE('" +
                      Esc(json) + "', '$[*]' COLUMNS (Entry INT PATH '$.Entry', Item INT PATH '$.Item', Reference INT PATH '$.Reference', Chance FLOAT PATH '$.Chance', "
                      "QuestRequired INT PATH '$.QuestRequired', LootMode INT PATH '$.LootMode', GroupId INT PATH '$.GroupId', MinCount INT PATH '$.MinCount', "
                      "MaxCount INT PATH '$.MaxCount', Comment VARCHAR(255) PATH '$.Comment')) jt");
        WorldDatabase.DirectCommitTransaction(trans);
    }

    void MarkDirty(std::string const& key)
    {
        std::lock_guard<std::mutex> lock(g_dirtyMu);
        g_dirty.insert(key);
    }

    void WriteLog(Player* gm, Kind const& k, uint32 lootId, std::string const& action, std::string const& oldRows, std::string const& newRows, bool reverted)
    {
        WorldDatabase.DirectExecute("INSERT INTO reborn_lootlab_log (who, kind, loot_id, action, old_rows, new_rows, reverted) VALUES ('{}', '{}', {}, '{}', '{}', '{}', {})",
                                    Esc(gm->GetName()), k.key, lootId, Esc(Clip(action, 250)), Esc(oldRows), Esc(newRows), reverted ? 1 : 0);
    }

    struct EditResult
    {
        bool ok = false;
        std::string msg;
    };

    // runs the statements, keeping the official copy, the log and the reload
    EditResult RunEdit(Player* gm, Kind const& k, uint32 lootId, std::string const& action, std::vector<std::string> const& statements)
    {
        EditResult res;
        std::string const oldRows = Snapshot(k, lootId);
        WorldDatabase.DirectExecute("INSERT IGNORE INTO reborn_lootlab_baseline (kind, loot_id, rows_json) VALUES ('{}', {}, '{}')", k.key, lootId, Esc(oldRows));
        auto trans = WorldDatabase.BeginTransaction();
        for (std::string const& s : statements)
            trans->Append(s);
        WorldDatabase.DirectCommitTransaction(trans);
        std::string const newRows = Snapshot(k, lootId);
        WriteLog(gm, k, lootId, action, oldRows, newRows, false);
        MarkDirty(k.key);
        res.ok = true;
        res.msg = action;
        return res;
    }

    EditResult HandleEdit(Player* gm, Kind const& k, uint32 lootId, std::vector<std::string> const& w)
    {
        EditResult bad;
        std::string const& op = w[3];
        std::string const table = k.table;
        auto rowExists = [&](uint32 item)
        {
            QueryResult r = Q("SELECT 1 FROM " + table + " WHERE Entry = " + Id(lootId) + " AND Item = " + Id(item) + " AND Reference = 0 LIMIT 1");
            return r != nullptr;
        };
        auto numberOk = [](float chance, uint32 minC, uint32 maxC, uint32 group)
        {
            return chance >= 0.f && chance <= 100.f && minC >= 1 && maxC >= minC && maxC <= 255 && group <= 255;
        };

        if ((op == "set" && w.size() >= 10) || (op == "add" && w.size() >= 9))
        {
            uint32 const item = Num(w[4]);
            float const chance = static_cast<float>(std::atof(w[5].c_str()));
            uint32 const minC = Num(w[6]), maxC = Num(w[7]), group = Num(w[8]);
            uint32 const quest = op == "set" ? (Num(w[9]) ? 1 : 0) : 0;
            if (!item || !numberOk(chance, minC, maxC, group))
            {
                bad.msg = "数值不合法（概率 0–100，数量 1–255 且最小不大于最大，分组 0–255）";
                return bad;
            }
            if (op == "set")
            {
                if (!rowExists(item))
                {
                    bad.msg = "这张表里没有这件物品（引用行暂不能在这里改）";
                    return bad;
                }
                return RunEdit(gm, k, lootId, Acore::StringFormat("set item {} chance={:.4f} count={}-{} group={} quest={}", item, chance, minC, maxC, group, quest),
                               { "UPDATE " + table + " SET Chance = " + Acore::StringFormat("{:.4f}", chance) + ", MinCount = " + Id(minC) + ", MaxCount = " + Id(maxC) +
                                 ", GroupId = " + Id(group) + ", QuestRequired = " + Id(quest) + " WHERE Entry = " + Id(lootId) + " AND Item = " + Id(item) + " AND Reference = 0" });
            }
            // add
            if (!Q("SELECT 1 FROM item_template WHERE entry = " + Id(item)))
            {
                bad.msg = "没有这件物品";
                return bad;
            }
            if (Q("SELECT 1 FROM " + table + " WHERE Entry = " + Id(lootId) + " AND Item = " + Id(item) + " LIMIT 1"))
            {
                bad.msg = "这张表里已经有这件物品了，请改它的行";
                return bad;
            }
            return RunEdit(gm, k, lootId, Acore::StringFormat("add item {} chance={:.4f} count={}-{} group={}", item, chance, minC, maxC, group),
                           { "INSERT INTO " + table + " (Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment) VALUES (" + Id(lootId) + ", " +
                             Id(item) + ", 0, " + Acore::StringFormat("{:.4f}", chance) + ", 0, 1, " + Id(group) + ", " + Id(minC) + ", " + Id(maxC) + ", 'LootLab')" });
        }
        if (op == "del" && w.size() >= 5)
        {
            uint32 const item = Num(w[4]);
            if (!item || !rowExists(item))
            {
                bad.msg = "这张表里没有这件物品（引用行暂不能在这里删）";
                return bad;
            }
            return RunEdit(gm, k, lootId, Acore::StringFormat("del item {}", item),
                           { "DELETE FROM " + table + " WHERE Entry = " + Id(lootId) + " AND Item = " + Id(item) + " AND Reference = 0" });
        }
        if (op == "restore")
        {
            QueryResult b = Q("SELECT rows_json FROM reborn_lootlab_baseline WHERE kind = '" + std::string(k.key) + "' AND loot_id = " + Id(lootId));
            if (!b)
            {
                bad.msg = "这张表还没有被工坊改过，现在就是官方内容";
                return bad;
            }
            std::string const official = b->Fetch()[0].Get<std::string>();
            std::string const oldRows = Snapshot(k, lootId);
            ApplySnapshot(k, lootId, official);
            WriteLog(gm, k, lootId, "restore official", oldRows, Snapshot(k, lootId), false);
            MarkDirty(k.key);
            EditResult ok;
            ok.ok = true;
            ok.msg = "已还原为官方爆率";
            return ok;
        }
        if (op == "undo")
        {
            QueryResult l = Q("SELECT id, old_rows FROM reborn_lootlab_log WHERE kind = '" + std::string(k.key) + "' AND loot_id = " + Id(lootId) + " AND reverted = 0 ORDER BY id DESC LIMIT 1");
            if (!l)
            {
                bad.msg = "没有可以撤销的改动";
                return bad;
            }
            Field* f = l->Fetch();
            uint32 const logId = f[0].Get<uint32>();
            std::string const before = f[1].Get<std::string>();
            std::string const current = Snapshot(k, lootId);
            ApplySnapshot(k, lootId, before);
            WorldDatabase.DirectExecute("UPDATE reborn_lootlab_log SET reverted = 1 WHERE id = {}", logId);
            WriteLog(gm, k, lootId, "undo #" + Id(logId), current, Snapshot(k, lootId), true);
            MarkDirty(k.key);
            EditResult ok;
            ok.ok = true;
            ok.msg = "已撤销上一步改动";
            return ok;
        }
        bad.msg = "编辑命令参数不对: " + op;
        return bad;
    }

    // =====================================================================
    // LAB3B: the size of the change log, and "archive and clean".
    //   Log.WarnMB = 20       the size from which the panel warns (orange)
    //   Log.CriticalMB = 100  the size from which the panel insists (red)
    //   Log.KeepDays = 30     the default of the archive dialog: logs older than this go to a file
    //   Log.ArchiveDir        where the archive files (one JSON object per line) are written
    // The size is the real size of the stored text (the rows before and after of every change); the
    // table file on disk is a little larger. Archiving writes the old log rows to a file FIRST and
    // deletes them from the database only after the file was written without error. The newest log row
    // of every table is always kept, so "undo" still works for each table; the official copies
    // (reborn_lootlab_baseline) are never touched, so "restore official" is not affected.
    // =====================================================================
    std::string JsonStr(std::string const& s)
    {
        std::string o = "\"";
        for (unsigned char c : s)
        {
            switch (c)
            {
                case '"': o += "\\\""; break;
                case '\\': o += "\\\\"; break;
                case '\n': o += "\\n"; break;
                case '\r': o += "\\r"; break;
                case '\t': o += "\\t"; break;
                default:
                    if (c < 0x20)
                    {
                        char b[8];
                        std::snprintf(b, sizeof b, "\\u%04x", c);
                        o += b;
                    }
                    else
                        o += static_cast<char>(c);
            }
        }
        return o + "\"";
    }

    void SendLogSize(Player* p)
    {
        uint32 const warn = sConfigMgr->GetOption<uint32>("RebornLootLab.Log.WarnMB", 20);
        uint32 const crit = sConfigMgr->GetOption<uint32>("RebornLootLab.Log.CriticalMB", 100);
        uint32 const keep = sConfigMgr->GetOption<uint32>("RebornLootLab.Log.KeepDays", 30);
        uint64 rows = 0, bytes = 0, baseRows = 0, baseBytes = 0;
        if (Q("SHOW TABLES LIKE 'reborn_lootlab_log'"))
            if (QueryResult r = Q("SELECT COUNT(*), CAST(IFNULL(SUM(LENGTH(IFNULL(old_rows, '')) + LENGTH(IFNULL(new_rows, '')) + LENGTH(action) + LENGTH(who) + LENGTH(kind) + 40), 0) AS UNSIGNED) FROM reborn_lootlab_log"))
            {
                rows = r->Fetch()[0].Get<uint64>();
                bytes = r->Fetch()[1].Get<uint64>();
            }
        if (Q("SHOW TABLES LIKE 'reborn_lootlab_baseline'"))
            if (QueryResult r = Q("SELECT COUNT(*), CAST(IFNULL(SUM(LENGTH(rows_json) + LENGTH(IFNULL(conds_json, '')) + LENGTH(kind) + 30), 0) AS UNSIGNED) FROM reborn_lootlab_baseline"))
            {
                baseRows = r->Fetch()[0].Get<uint64>();
                baseBytes = r->Fetch()[1].Get<uint64>();
            }
        Send(p, Acore::StringFormat("LS\t{}\t{}\t{}\t{}\t{}\t{}\t{}", rows, bytes, warn, crit, keep, baseRows, baseBytes));
    }

    EditResult ArchiveLog(Player* gm, uint32 days)
    {
        EditResult res;
        if (!Q("SHOW TABLES LIKE 'reborn_lootlab_log'"))
        {
            res.msg = "日志表不存在";
            return res;
        }
        std::string const where = "at < NOW() - INTERVAL " + Id(days) + " DAY AND id NOT IN (SELECT mid FROM (SELECT MAX(id) AS mid FROM reborn_lootlab_log GROUP BY kind, loot_id) latest)";
        QueryResult c = Q("SELECT COUNT(*) FROM reborn_lootlab_log WHERE " + where);
        if (!c || !c->Fetch()[0].Get<uint64>())
        {
            res.msg = "没有可以归档的旧日志（每张表最新的一条会保留）";
            return res;
        }
        std::string const dir = sConfigMgr->GetOption<std::string>("RebornLootLab.Log.ArchiveDir", "lootlab_archive");
        std::error_code ec;
        std::filesystem::create_directories(dir, ec);
        if (ec)
        {
            res.msg = "不能创建归档目录 " + dir;
            return res;
        }
        char stamp[32];
        std::time_t const now = std::time(nullptr);
        std::strftime(stamp, sizeof stamp, "%Y%m%d_%H%M%S", std::localtime(&now));
        std::string const path = dir + "/lootlab_log_" + stamp + ".jsonl";
        std::ofstream out(path, std::ios::binary);
        if (!out)
        {
            res.msg = "不能写归档文件 " + path;
            return res;
        }
        std::vector<uint32> ids;
        uint32 last = 0;
        for (;;)
        {
            QueryResult r = Q("SELECT id, UNIX_TIMESTAMP(at), who, kind, loot_id, action, reverted, IFNULL(old_rows, ''), IFNULL(new_rows, '') FROM reborn_lootlab_log WHERE id > " +
                              Id(last) + " AND " + where + " ORDER BY id LIMIT 200");
            if (!r)
                break;
            do
            {
                Field* f = r->Fetch();
                uint32 const id = f[0].Get<uint32>();
                last = id;
                ids.push_back(id);
                out << "{\"id\":" << id << ",\"at\":" << f[1].Get<uint64>() << ",\"who\":" << JsonStr(f[2].Get<std::string>()) << ",\"kind\":" << JsonStr(f[3].Get<std::string>())
                    << ",\"loot_id\":" << f[4].Get<uint32>() << ",\"action\":" << JsonStr(f[5].Get<std::string>()) << ",\"reverted\":" << static_cast<uint32>(f[6].Get<uint8>())
                    << ",\"old_rows\":" << JsonStr(f[7].Get<std::string>()) << ",\"new_rows\":" << JsonStr(f[8].Get<std::string>()) << "}\n";
            } while (r->NextRow());
        }
        out.flush();
        bool const good = out.good();
        out.close();
        if (!good || ids.empty())
        {
            std::filesystem::remove(path, ec);
            res.msg = "写归档文件失败，没有删除任何日志";
            return res;
        }
        for (std::size_t i = 0; i < ids.size(); i += 500)
        {
            std::string list;
            for (std::size_t j = i; j < ids.size() && j < i + 500; ++j)
                list += (list.empty() ? "" : ",") + Id(ids[j]);
            WorldDatabase.DirectExecute("DELETE FROM reborn_lootlab_log WHERE id IN (" + list + ")");
        }
        Q("OPTIMIZE TABLE reborn_lootlab_log");
        LOG_INFO("module", "[LootLab] {} archived {} old log row(s) to {} and removed them from the database", gm->GetName(), ids.size(), path);
        res.ok = true;
        res.msg = Acore::StringFormat("已把 {} 条旧日志归档到 {}，并从数据库清理", ids.size(), path);
        return res;
    }

    // =====================================================================
    // LAB3C: time points. A time point is a copy of the CURRENT content of every loot table the workshop has
    // ever changed (the tables listed in reborn_lootlab_baseline), taken at one moment:
    //   manual  - a GM saved it with a name
    //   auto    - taken every Snapshot.AutoMinutes when something changed since the last one (same content = skipped)
    //   before  - taken automatically just before going back to a time point, so going back can be undone
    // Going back to a time point puts every changed table to its content at that time; a table the time point
    // does not hold (it was first changed later) goes back to its official copy. Every table that really changes
    // gets a log row, and the loot stores are read again like after any edit.
    // Automatic and "before" points are pruned (Snapshot.AutoKeep newest, Snapshot.AutoKeepDays); manual ones never.
    //   Snapshot.AutoMinutes = 60    0 turns the automatic points off
    //   Snapshot.AutoKeep = 48       how many automatic / before points to keep (0 = no count limit)
    //   Snapshot.AutoKeepDays = 14   how many days they live (0 = no age limit)
    // =====================================================================
    struct StateRow
    {
        std::string kind;
        uint32 lootId;
        std::string json;
    };

    bool SnapTablesExist()
    {
        return Q("SHOW TABLES LIKE 'reborn_lootlab_snapshot'") && Q("SHOW TABLES LIKE 'reborn_lootlab_snapshot_row'") && Q("SHOW TABLES LIKE 'reborn_lootlab_baseline'");
    }

    std::vector<StateRow> CaptureState()
    {
        std::vector<StateRow> out;
        std::vector<std::pair<std::string, uint32>> keys;
        if (QueryResult b = Q("SELECT kind, loot_id FROM reborn_lootlab_baseline ORDER BY kind, loot_id"))
            do
            {
                Field* f = b->Fetch();
                keys.emplace_back(f[0].Get<std::string>(), f[1].Get<uint32>());
            } while (b->NextRow());
        for (auto const& kv : keys)
            if (Kind const* k = FindKind(kv.first))
                out.push_back({ kv.first, kv.second, Snapshot(*k, kv.second) });
        return out;
    }

    std::string StateHash(std::vector<StateRow> const& rows)
    {
        std::string all;
        for (StateRow const& r : rows)
            all += r.kind + ":" + Id(r.lootId) + "=" + r.json + "\n";
        if (QueryResult q = Q("SELECT MD5('" + Esc(all) + "')"))
            return q->Fetch()[0].Get<std::string>();
        return std::string();
    }

    // returns the new id; 0 when skipIfSame and the content equals the newest time point
    uint32 SaveSnapshot(std::string const& type, std::string const& name, std::string const& who, bool skipIfSame, bool& same)
    {
        same = false;
        std::vector<StateRow> const rows = CaptureState();
        std::string const hash = StateHash(rows);
        if (skipIfSame)
            if (QueryResult q = Q("SELECT hash FROM reborn_lootlab_snapshot ORDER BY id DESC LIMIT 1"))
                if (q->Fetch()[0].Get<std::string>() == hash)
                {
                    same = true;
                    return 0;
                }
        uint64 bytes = 0;
        for (StateRow const& r : rows)
            bytes += r.json.size() + r.kind.size() + 20;
        WorldDatabase.DirectExecute("INSERT INTO reborn_lootlab_snapshot (name, snap_type, who, tables_n, bytes, hash) VALUES ('{}', '{}', '{}', {}, {}, '{}')",
                                    Esc(Clip(name, 80)), type, Esc(who), rows.size(), bytes, hash);
        uint32 id = 0;
        if (QueryResult q = Q("SELECT MAX(id) FROM reborn_lootlab_snapshot"))
            id = q->Fetch()[0].Get<uint32>();
        if (!id)
            return 0;
        auto trans = WorldDatabase.BeginTransaction();
        for (StateRow const& r : rows)
            trans->Append("INSERT INTO reborn_lootlab_snapshot_row (snap_id, kind, loot_id, rows_json) VALUES (" + Id(id) + ", '" + r.kind + "', " + Id(r.lootId) + ", '" + Esc(r.json) + "')");
        WorldDatabase.DirectCommitTransaction(trans);
        return id;
    }

    void DeleteSnapshot(uint32 id)
    {
        WorldDatabase.DirectExecute("DELETE FROM reborn_lootlab_snapshot_row WHERE snap_id = {}", id);
        WorldDatabase.DirectExecute("DELETE FROM reborn_lootlab_snapshot WHERE id = {}", id);
    }

    void PruneSnapshots()
    {
        uint32 const keep = sConfigMgr->GetOption<uint32>("RebornLootLab.Snapshot.AutoKeep", 48);
        uint32 const days = sConfigMgr->GetOption<uint32>("RebornLootLab.Snapshot.AutoKeepDays", 14);
        std::vector<uint32> del;
        if (QueryResult r = Q("SELECT id, UNIX_TIMESTAMP(at) FROM reborn_lootlab_snapshot WHERE snap_type <> 'manual' ORDER BY id DESC"))
        {
            uint32 n = 0;
            uint64 const now = static_cast<uint64>(std::time(nullptr));
            do
            {
                ++n;
                Field* f = r->Fetch();
                uint64 const at = f[1].Get<uint64>();
                if ((keep && n > keep) || (days && now > at && now - at > static_cast<uint64>(days) * 86400))
                    del.push_back(f[0].Get<uint32>());
            } while (r->NextRow());
        }
        for (uint32 id : del)
            DeleteSnapshot(id);
    }

    // the rows of one loot table, keyed by (item, reference)
    struct RowV
    {
        float chance = 0;
        uint32 minC = 1, maxC = 1, group = 0, quest = 0, ref = 0;
    };
    typedef std::map<std::pair<uint32, uint32>, RowV> RowMap;

    RowMap RowsOf(std::string const& json)
    {
        RowMap m;
        if (QueryResult r = Q("SELECT jt.Item, jt.Reference, jt.Chance, jt.QuestRequired, jt.GroupId, jt.MinCount, jt.MaxCount FROM JSON_TABLE('" + Esc(json) +
                              "', '$[*]' COLUMNS (Item INT PATH '$.Item', Reference INT PATH '$.Reference', Chance FLOAT PATH '$.Chance', QuestRequired INT PATH '$.QuestRequired', "
                              "GroupId INT PATH '$.GroupId', MinCount INT PATH '$.MinCount', MaxCount INT PATH '$.MaxCount')) jt"))
            do
            {
                Field* f = r->Fetch();
                RowV v;
                v.ref = f[1].Get<uint32>();
                v.chance = f[2].Get<float>();
                v.quest = f[3].Get<uint32>();
                v.group = f[4].Get<uint32>();
                v.minC = f[5].Get<uint32>();
                v.maxC = f[6].Get<uint32>();
                m[{ f[0].Get<uint32>(), v.ref }] = v;
            } while (r->NextRow());
        return m;
    }

    bool SameRow(RowV const& a, RowV const& b)
    {
        return std::fabs(a.chance - b.chance) < 0.0001f && a.minC == b.minC && a.maxC == b.maxC && a.group == b.group && a.quest == b.quest;
    }

    std::string RowText(RowV const& v)
    {
        return Acore::StringFormat("{:g}% x{}-{} g{}{}", v.chance, v.minC, v.maxC, v.group, v.quest ? " q" : "");
    }

    // what a table holds in a time point: its row there, or the official copy when the time point does not have it
    std::map<std::pair<std::string, uint32>, std::string> SnapshotTables(uint32 snapId)
    {
        std::map<std::pair<std::string, uint32>, std::string> m;
        if (QueryResult b = Q("SELECT kind, loot_id, rows_json FROM reborn_lootlab_baseline"))
            do
            {
                Field* f = b->Fetch();
                m[{ f[0].Get<std::string>(), f[1].Get<uint32>() }] = f[2].Get<std::string>();
            } while (b->NextRow());
        if (QueryResult r = Q("SELECT kind, loot_id, rows_json FROM reborn_lootlab_snapshot_row WHERE snap_id = " + Id(snapId)))
            do
            {
                Field* f = r->Fetch();
                m[{ f[0].Get<std::string>(), f[1].Get<uint32>() }] = f[2].Get<std::string>();
            } while (r->NextRow());
        return m;
    }

    bool SnapshotExists(uint32 id, std::string* name = nullptr, uint64* at = nullptr)
    {
        if (id == 0)   // LAB3D: the official original, not stored: every changed table at its baseline copy
        {
            if (name)
                *name = "官方原始";
            if (at)
                *at = 0;
            return true;
        }
        if (QueryResult q = Q("SELECT name, UNIX_TIMESTAMP(at) FROM reborn_lootlab_snapshot WHERE id = " + Id(id)))
        {
            if (name)
                *name = q->Fetch()[0].Get<std::string>();
            if (at)
                *at = q->Fetch()[1].Get<uint64>();
            return true;
        }
        return false;
    }

    struct DiffCnt
    {
        uint32 add = 0, del = 0, chg = 0;
    };

    // how many rows going back to a time point would add / remove / change, against the tables as they are now
    // curJson / curRows are read once by the caller and shared by all the points of one list
    DiffCnt CountDiff(uint32 snapId, std::map<std::pair<std::string, uint32>, std::string> const& curJson,
                      std::map<std::pair<std::string, uint32>, RowMap>& curRows)
    {
        DiffCnt c;
        for (auto const& kv : SnapshotTables(snapId))
        {
            auto cj = curJson.find(kv.first);
            if (cj == curJson.end() || cj->second == kv.second)
                continue;
            auto cr = curRows.find(kv.first);
            if (cr == curRows.end())
                cr = curRows.emplace(kv.first, RowsOf(cj->second)).first;
            RowMap const want = RowsOf(kv.second);
            RowMap const& have = cr->second;
            for (auto const& w : want)
            {
                auto it = have.find(w.first);
                if (it == have.end())
                    ++c.add;
                else if (!SameRow(it->second, w.second))
                    ++c.chg;
            }
            for (auto const& h : have)
                if (want.find(h.first) == want.end())
                    ++c.del;
        }
        return c;
    }

    // LAB3D: "SN" lines (manual points first, then automatic / before points, newest first), one "SNX" line per point with
    // what going back would change, and the official original as id 0. SNX is only sent for the newest points.
    void SendSnapList(Player* p)
    {
        Send(p, "SN_START");
        bool const ok = SnapTablesExist();
        uint64 total = 0;
        uint32 count = 0;
        std::vector<uint32> ids;
        if (ok)
            for (char const* where : { "snap_type = 'manual'", "snap_type <> 'manual'" })
                if (QueryResult r = Q(std::string("SELECT id, UNIX_TIMESTAMP(at), snap_type, who, name, tables_n, bytes FROM reborn_lootlab_snapshot WHERE ") + where + " ORDER BY id DESC LIMIT 100"))
                    do
                    {
                        Field* f = r->Fetch();
                        ++count;
                        total += f[6].Get<uint64>();
                        ids.push_back(f[0].Get<uint32>());
                        Send(p, Acore::StringFormat("SN	{}	{}	{}	{}	{}	{}	{}", f[0].Get<uint32>(), f[1].Get<uint64>(), f[2].Get<std::string>(), Fld(f[3].Get<std::string>()),
                                                    Fld(Clip(f[4].Get<std::string>(), 80)), f[5].Get<uint32>(), f[6].Get<uint64>()));
                    } while (r->NextRow());
        if (ok)
        {
            std::map<std::pair<std::string, uint32>, std::string> curJson;
            for (StateRow const& r : CaptureState())
                curJson[{ r.kind, r.lootId }] = r.json;
            std::map<std::pair<std::string, uint32>, RowMap> curRows;
            uint32 n = 0;
            ids.push_back(0);   // the original is last in the list but always summarised
            std::sort(ids.begin(), ids.end(), std::greater<uint32>());
            for (uint32 id : ids)
            {
                if (id != 0 && ++n > 40)
                    continue;
                DiffCnt const c = CountDiff(id, curJson, curRows);
                Send(p, Acore::StringFormat("SNX	{}	{}	{}	{}", id, c.add, c.del, c.chg));
            }
        }
        Send(p, Acore::StringFormat("SN_END	{}	{}	{}	{}	{}	{}", ok ? 1 : 0, count, total,
                                    sConfigMgr->GetOption<uint32>("RebornLootLab.Snapshot.AutoMinutes", 60), sConfigMgr->GetOption<uint32>("RebornLootLab.Snapshot.AutoKeep", 48),
                                    sConfigMgr->GetOption<uint32>("RebornLootLab.Snapshot.AutoKeepDays", 14)));
    }

    // what going back to a time point would change, table by table (nothing is changed here)
    void SendSnapDiff(Player* p, uint32 snapId)
    {
        std::string name;
        uint64 at = 0;
        if (!SnapTablesExist() || !SnapshotExists(snapId, &name, &at))
        {
            Send(p, "ERR\t没有这个时间点");
            return;
        }
        Send(p, Acore::StringFormat("SD_START\t{}\t{}\t{}", snapId, at, Fld(name)));
        uint32 tables = 0, lines = 0;
        for (auto const& kv : SnapshotTables(snapId))
        {
            Kind const* k = FindKind(kv.first.first);
            if (!k)
                continue;
            uint32 const lootId = kv.first.second;
            RowMap const want = RowsOf(kv.second);
            RowMap const have = RowsOf(Snapshot(*k, lootId));
            uint32 add = 0, del = 0, chg = 0;
            std::vector<std::string> detail;
            auto itemName = [](uint32 item) -> std::string
            {
                if (QueryResult q = Q("SELECT name FROM item_template WHERE entry = " + Id(item)))
                    return Fld(Clip(q->Fetch()[0].Get<std::string>(), 40));
                return std::string();
            };
            for (auto const& w : want)
            {
                auto it = have.find(w.first);
                if (it == have.end())
                {
                    ++add;
                    detail.push_back(Acore::StringFormat("+\t{}\t{}\t\t{}", w.first.first, itemName(w.first.first), RowText(w.second)));
                }
                else if (!SameRow(it->second, w.second))
                {
                    ++chg;
                    detail.push_back(Acore::StringFormat("~\t{}\t{}\t{}\t{}", w.first.first, itemName(w.first.first), RowText(it->second), RowText(w.second)));
                }
            }
            for (auto const& h : have)
                if (want.find(h.first) == want.end())
                {
                    ++del;
                    detail.push_back(Acore::StringFormat("-\t{}\t{}\t{}\t", h.first.first, itemName(h.first.first), RowText(h.second)));
                }
            if (!add && !del && !chg)
                continue;
            ++tables;
            Send(p, Acore::StringFormat("SD\t{}\t{}\t{}\t{}\t{}", k->key, lootId, add, del, chg));
            for (std::string const& d : detail)
                if (lines < 400)
                {
                    ++lines;
                    Send(p, Acore::StringFormat("SDI\t{}\t{}\t{}", k->key, lootId, d));
                }
        }
        Send(p, Acore::StringFormat("SD_END\t{}\t{}", snapId, tables));
    }

    EditResult RestoreSnapshot(Player* gm, uint32 snapId)
    {
        EditResult res;
        if (!SnapTablesExist() || !SnapshotExists(snapId))
        {
            res.msg = "没有这个时间点";
            return res;
        }
        // first keep where we are, so going back can be undone with the "before" point
        bool same = false;
        uint32 const beforeId = SaveSnapshot("before", (snapId ? Acore::StringFormat("回到 #{} 之前自动保存", snapId) : std::string("回到官方原始之前自动保存")), gm->GetName(), true, same);
        uint32 changed = 0, kept = 0;
        for (auto const& kv : SnapshotTables(snapId))
        {
            Kind const* k = FindKind(kv.first.first);
            if (!k)
                continue;
            std::string const cur = Snapshot(*k, kv.first.second);
            RowMap const want = RowsOf(kv.second), have = RowsOf(cur);
            bool differs = want.size() != have.size();
            if (!differs)
                for (auto const& w : want)
                {
                    auto it = have.find(w.first);
                    if (it == have.end() || !SameRow(it->second, w.second))
                    {
                        differs = true;
                        break;
                    }
                }
            if (!differs)
            {
                ++kept;
                continue;
            }
            ApplySnapshot(*k, kv.first.second, kv.second);
            WriteLog(gm, *k, kv.first.second, Acore::StringFormat("go back to time point #{}", snapId), cur, Snapshot(*k, kv.first.second), false);
            MarkDirty(k->key);
            ++changed;
        }
        LOG_INFO("module", "[LootLab] {} went back to time point #{}: {} table(s) changed, {} already the same", gm->GetName(), snapId, changed, kept);
        res.ok = true;
        res.msg = (snapId ? Acore::StringFormat("已回到时间点 #{}：改回 {} 张表，{} 张本来就一样", snapId, changed, kept) : Acore::StringFormat("已回到官方原始：改回 {} 张表，{} 张本来就一样", changed, kept)) +
                  (beforeId ? Acore::StringFormat("。回来之前的状态已存为时间点 #{}，想反悔就回到它", beforeId) : std::string());
        return res;
    }

    // the automatic points: called from the world thread, every Snapshot.AutoMinutes, only when the change log moved
    void AutoSnapshotTick(uint32 diff)
    {
        static uint32 acc = 0;
        static uint64 lastSeen = std::numeric_limits<uint64>::max();
        uint32 const minutes = sConfigMgr->GetOption<uint32>("RebornLootLab.Snapshot.AutoMinutes", 60);
        if (!minutes)
            return;
        acc += diff;
        if (acc < minutes * 60000u)
            return;
        acc = 0;
        if (!SnapTablesExist() || !Q("SHOW TABLES LIKE 'reborn_lootlab_log'"))
            return;
        uint64 cur = 0;
        if (QueryResult q = Q("SELECT IFNULL(MAX(id), 0) FROM reborn_lootlab_log"))
            cur = q->Fetch()[0].Get<uint64>();
        if (cur == lastSeen)
            return;
        lastSeen = cur;
        bool same = false;
        std::vector<StateRow> const probe = CaptureState();
        if (probe.empty())
            return;
        uint32 const id = SaveSnapshot("auto", "自动", "system", true, same);
        if (id)
            LOG_INFO("module", "[LootLab] automatic time point #{} saved ({} table(s))", id, probe.size());
        PruneSnapshots();
    }
}

class RebornLootLabCommandScript : public CommandScript
{
public:
    RebornLootLabCommandScript() : CommandScript("RebornLootLabCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable subCommands =
        {
            { "ui", HandleUi, SEC_GAMEMASTER, Console::No }
        };
        static ChatCommandTable rootCommands =
        {
            { "lootlab", subCommands }
        };
        return rootCommands;
    }

    static bool HandleUi(ChatHandler* handler, Optional<Tail> tail)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;
        std::string line = tail ? std::string(tail->data(), tail->size()) : std::string();
        std::vector<std::string> w = Split(line);
        if (w.empty())
        {
            handler->SendSysMessage("用法: .lootlab ui ping|kinds|maps|list|loot|users|sim|who|items|log|edit ...");
            return true;
        }
        std::string const& what = w[0];

        if (what == "ping")
        {
            Send(gm, Acore::StringFormat("PONG\t{}\t{}\t{}\t{}", sConfigMgr->GetOption<bool>("RebornLootLab.Enable", true) ? 1 : 0,
                                         MayEdit(gm) ? 1 : 0, EditLocked() ? 1 : 0, EditEnabled() ? 1 : 0));
            return true;
        }
        if (!sConfigMgr->GetOption<bool>("RebornLootLab.Enable", true))
        {
            Fail(handler, gm, "掉落工坊已在配置中关闭");
            return true;
        }
        if (what == "kinds")
        {
            SendKinds(gm);
            return true;
        }
        if (what == "maps")
        {
            SendMaps(gm);
            return true;
        }
        if (what == "log")
        {
            SendLog(gm);
            return true;
        }
        if (what == "logsize")   // LAB3B
        {
            SendLogSize(gm);
            return true;
        }
        if (what == "logarchive" && w.size() >= 2)   // LAB3B: logarchive <days>
        {
            if (!MayEdit(gm))
            {
                Send(gm, std::string("ED\t0\t") + (EditLocked() ? "正式服已锁定，不能编辑" : (EditEnabled() ? "你的账号等级不够编辑" : "编辑功能没有开启（服务端配置 RebornLootLab.Edit.Enable）")));
                return true;
            }
            uint32 const days = std::min<uint32>(Num(w[1]), 3650);
            EditResult er = ArchiveLog(gm, days);
            Send(gm, std::string("ED\t") + (er.ok ? "1" : "0") + "\t" + Fld(er.msg));
            SendLogSize(gm);
            return true;
        }
        if (what == "snaplist")   // LAB3C
        {
            SendSnapList(gm);
            return true;
        }
        if (what == "snapdiff" && w.size() >= 2)
        {
            SendSnapDiff(gm, Num(w[1]));
            return true;
        }
        if (what == "snapsave" || what == "snaprestore" || what == "snapdel")
        {
            if (!MayEdit(gm))
            {
                Send(gm, std::string("ED\t0\t") + (EditLocked() ? "正式服已锁定，不能编辑" : (EditEnabled() ? "你的账号等级不够编辑" : "编辑功能没有开启（服务端配置 RebornLootLab.Edit.Enable）")));
                return true;
            }
            if (!SnapTablesExist())
            {
                Send(gm, "ED\t0\t" + Fld("时间点的数据表还没建：请在 world 库执行 LAB3C_snapshot_tables.sql"));
                return true;
            }
            EditResult er;
            if (what == "snapsave")
            {
                std::string name = Rest(line, 1);
                if (name.empty())
                    name = "手动时间点";
                bool same = false;
                uint32 const id = SaveSnapshot("manual", name, gm->GetName(), false, same);
                er.ok = id != 0;
                er.msg = id ? Acore::StringFormat("已保存时间点 #{}（{}）", id, Clip(name, 60)) : std::string("保存失败");
            }
            else if (what == "snaprestore" && w.size() >= 2)
                er = RestoreSnapshot(gm, Num(w[1]));
            else if (what == "snapdel" && w.size() >= 2)
            {
                uint32 const id = Num(w[1]);
                if (id == 0)
                    er.msg = "官方原始不能删除";
                else if (SnapshotExists(id))
                {
                    DeleteSnapshot(id);
                    er.ok = true;
                    er.msg = Acore::StringFormat("已删除时间点 #{}", id);
                }
                else
                    er.msg = "没有这个时间点";
            }
            else
                er.msg = "命令参数不对";
            Send(gm, std::string("ED\t") + (er.ok ? "1" : "0") + "\t" + Fld(er.msg));
            SendSnapList(gm);
            return true;
        }
        if (what == "who" && w.size() >= 2)
        {
            SendWho(gm, Num(w[1]));
            return true;
        }
        if (what == "items" && w.size() >= 2)
        {
            SendItems(gm, Num(w[1]), Rest(line, 2));
            return true;
        }

        // LAB3A: restoreall -- every table the workshop has changed (one row per table in reborn_lootlab_baseline)
        // goes back to its official content; each one is logged like a single "restore official".
        if (what == "restoreall")
        {
            if (!MayEdit(gm))
            {
                Send(gm, std::string("ED\t0\t") + (EditLocked() ? "正式服已锁定，不能编辑" : (EditEnabled() ? "你的账号等级不够编辑" : "编辑功能没有开启（服务端配置 RebornLootLab.Edit.Enable）")));
                return true;
            }
            struct Saved { std::string kind; uint32 lootId; std::string official; };
            std::vector<Saved> saved;
            if (QueryResult b = Q("SELECT kind, loot_id, rows_json FROM reborn_lootlab_baseline ORDER BY kind, loot_id"))
                do
                {
                    Field* f = b->Fetch();
                    saved.push_back({ f[0].Get<std::string>(), f[1].Get<uint32>(), f[2].Get<std::string>() });
                } while (b->NextRow());
            uint32 restored = 0, skipped = 0;
            for (Saved const& sv : saved)
            {
                Kind const* kk = FindKind(sv.kind);
                if (!kk)
                {
                    ++skipped;
                    continue;
                }
                std::string const oldRows = Snapshot(*kk, sv.lootId);
                ApplySnapshot(*kk, sv.lootId, sv.official);
                WriteLog(gm, *kk, sv.lootId, "restore official (all)", oldRows, Snapshot(*kk, sv.lootId), false);
                MarkDirty(kk->key);
                ++restored;
            }
            LOG_INFO("module", "[LootLab] {} restored {} loot table(s) to the official content ({} skipped)", gm->GetName(), restored, skipped);
            Send(gm, std::string("ED\t1\t") + (saved.empty() ? Fld("还没有改过任何掉落表，现在都是官方内容")
                                                             : Fld(Acore::StringFormat("已把 {} 张掉落表还原为官方爆率", restored) + (skipped ? Acore::StringFormat("（{} 张不认识的类型已跳过）", skipped) : std::string()))));
            return true;
        }

        // the rest all start with a kind
        Kind const* k = w.size() >= 2 ? FindKind(w[1]) : nullptr;
        if (!k)
        {
            Fail(handler, gm, "未知的来源类型");
            return true;
        }
        if (what == "list" && w.size() >= 5)
        {
            // list <kind> <rank|-1> <map|-1> <page> [text...]
            int const rank = w[2] == "-1" ? -1 : static_cast<int>(Num(w[2]));
            int const mapId = w[3] == "-1" ? -1 : static_cast<int>(Num(w[3]));
            SendList(gm, *k, rank, mapId, w.size() >= 5 ? Num(w[4]) : 0, Rest(line, 5));
            return true;
        }
        if (what == "loot" && w.size() >= 3)
        {
            SendLoot(gm, *k, Num(w[2]));
            return true;
        }
        if (what == "users" && w.size() >= 3)
        {
            SendUsers(gm, *k, Num(w[2]));
            return true;
        }
        if (what == "edit" && w.size() >= 4)
        {
            if (!MayEdit(gm))
            {
                Send(gm, std::string("ED\t0\t") + (EditLocked() ? "正式服已锁定，不能编辑" : (EditEnabled() ? "你的账号等级不够编辑" : "编辑功能没有开启（服务端配置 RebornLootLab.Edit.Enable）")));
                return true;
            }
            EditResult er = HandleEdit(gm, *k, Num(w[2]), w);
            Send(gm, std::string("ED\t") + (er.ok ? "1" : "0") + "\t" + Fld(er.msg));
            return true;
        }
        if (what == "sim" && w.size() >= 4)
        {
            SendSim(gm, *k, Num(w[2]), Num(w[3]));
            return true;
        }
        Fail(handler, gm, "命令参数不对: " + what);
        return true;
    }
};

// A changed loot table is read again here, on the world thread (the same way the treasure panel does it), never from the command.
class RebornLootLabWorldScript : public WorldScript
{
public:
    RebornLootLabWorldScript() : WorldScript("RebornLootLabWorldScript") { }

    void OnUpdate(uint32 diff) override
    {
        AutoSnapshotTick(diff);   // LAB3C
        std::set<std::string> todo;
        {
            std::lock_guard<std::mutex> lock(g_dirtyMu);
            if (g_dirty.empty())
                return;
            todo.swap(g_dirty);
        }
        for (std::string const& key : todo)
        {
            ReloadKind(key);
            LOG_INFO("module", "[LootLab] loot store '{}' read again after an edit", key);
        }
    }
};

void AddSC_mod_reborn_lootlab()
{
    new RebornLootLabCommandScript();
    new RebornLootLabWorldScript();
}
