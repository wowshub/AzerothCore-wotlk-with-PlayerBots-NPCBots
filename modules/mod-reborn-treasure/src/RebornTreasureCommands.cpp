#include "RebornTreasure.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include <algorithm>
#include <cstdlib>
#include <map>
#include <cctype>
#include <set>
#include <ctime>
#include <string>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    // TREAS2A: the GM panel talks to the server through ".treasure ui <what> ..." (GM only, like every
    // .treasure command) and gets its answer as addon lines "TR\t<kind>\t<fields...>".

    std::string Fld(std::string s)
    {
        for (char& ch : s)
            if (ch == '\t' || ch == '\n' || ch == '\r' || ch == '|')
                ch = ' ';
        return s;
    }

    // keep a payload inside one chat packet, never cutting a UTF-8 sequence
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
                                     Clip("TR\t" + payload), CHAT_TAG_NONE, player->GetName());
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

    // everything after the first `skip` words, as typed
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

    bool IsNumber(std::string const& s)
    {
        return !s.empty() && s.size() < 10 && std::all_of(s.begin(), s.end(), [](char ch) { return ch >= '0' && ch <= '9'; });
    }

    uint32 Num(std::string const& s)
    {
        return IsNumber(s) ? static_cast<uint32>(std::strtoul(s.c_str(), nullptr, 10)) : 0;
    }

    std::string IconOfDisplay(uint32 displayId)
    {
        ItemDisplayInfoEntry const* e = sItemDisplayInfoStore.LookupEntry(displayId);
        if (e && e->inventoryIcon && *e->inventoryIcon)
            return std::string("Interface\\Icons\\") + e->inventoryIcon;
        return "Interface\\Icons\\INV_Misc_QuestionMark";
    }

    void SendType(Player* p, TreasureType const& t)
    {
        Send(p, Acore::StringFormat("TY\t{}\t{}\t{}\t{}\t{:.2f}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", t.entry, Fld(t.name), Fld(t.icon), t.displayId,
                                    t.size, t.goldMin, t.goldMax, uint32(t.rarity), t.respawnMin, t.respawnMax, t.active ? 1 : 0,
                                    t.dungeonGoldScale ? 1 : 0));
        if (GameObjectDisplayInfoEntry const* d = sGameObjectDisplayInfoStore.LookupEntry(t.displayId))
            Send(p, Acore::StringFormat("TYM\t{}\t{}", t.entry, Fld(d->filename ? d->filename : "")));
    }

    void SendTypes(Player* p)
    {
        Send(p, "TY_START");
        for (TreasureType const& t : sRebornTreasure->Types())
            SendType(p, t);
        Send(p, "TY_END");
    }

    void SendLoot(Player* p, uint32 entry)
    {
        Send(p, Acore::StringFormat("LT_START\t{}", entry));
        QueryResult r = WorldDatabase.Query(
            "SELECT g.Item, g.Chance, g.MinCount, g.MaxCount, g.GroupId, IFNULL(i.Quality, 0), IFNULL(i.displayid, 0), IFNULL(i.name, ''), IFNULL(l.Name, '') "
            "FROM gameobject_loot_template g LEFT JOIN item_template i ON i.entry = g.Item "
            "LEFT JOIN item_template_locale l ON l.ID = g.Item AND l.locale = 'zhCN' "
            "WHERE g.Entry = {} AND g.Reference = 0 ORDER BY g.GroupId, g.Item LIMIT 120", entry);
        if (r)
        {
            do
            {
                Field* f = r->Fetch();
                Send(p, Acore::StringFormat("LT\t{}\t{}\t{:.2f}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", entry, f[0].Get<uint32>(), f[1].Get<float>(),
                                            f[2].Get<uint32>(), f[3].Get<uint32>(), f[4].Get<uint32>(), f[5].Get<uint32>(),
                                            IconOfDisplay(f[6].Get<uint32>()), Fld(f[7].Get<std::string>()), Fld(f[8].Get<std::string>())));
            } while (r->NextRow());
        }
        Send(p, Acore::StringFormat("LT_END\t{}", entry));
    }

    // the right-hand list's categories -> a WHERE fragment on item_template (alias `i`)
    char const* CategoryCond(std::string const& cat)
    {
        if (cat == "use")    return "i.class = 0";
        if (cat == "gear")   return "i.class = 4 AND i.InventoryType NOT IN (4, 16, 19)";
        if (cat == "cloth")  return "i.class = 4 AND i.InventoryType IN (4, 16, 19)";   // shirts, cloaks, tabards
        if (cat == "weapon") return "i.class = 2";
        if (cat == "mount")  return "i.class = 15 AND i.subclass = 5";
        if (cat == "pet")    return "i.class = 15 AND i.subclass = 2";
        if (cat == "recipe") return "(i.class = 9 OR (i.class = 0 AND (i.name LIKE '%Scroll%' OR l.Name LIKE '%卷轴%')))";
        if (cat == "trade")  return "i.class IN (5, 7)";
        if (cat == "quest")  return "i.class = 12";
        if (cat == "gem")    return "i.class = 3";
        if (cat == "misc")   return "(i.class = 15 AND i.subclass NOT IN (2, 5)) OR i.class IN (1, 6, 10, 11, 13, 14)";
        return "1 = 1";
    }

    void SendItems(Player* p, std::string const& cat, uint32 page, std::string text)
    {
        // one text box: a number is an item id, anything else is searched in the English and the Chinese name
        text.erase(std::remove_if(text.begin(), text.end(), [](char ch) { return ch == '%' || ch == '_' || ch == '\\' || ch == '\''; }), text.end());
        WorldDatabase.EscapeString(text);

        std::string where = std::string("(") + CategoryCond(cat) + ")";
        if (!text.empty())
        {
            if (IsNumber(text))
                where += Acore::StringFormat(" AND i.entry = {}", Num(text));
            else
                where += Acore::StringFormat(" AND (i.name LIKE '%{}%' OR l.Name LIKE '%{}%')", text, text);
        }

        constexpr uint32 PAGE = 40;
        QueryResult r = WorldDatabase.Query(
            "SELECT i.entry, i.Quality, i.class, i.subclass, i.InventoryType, i.displayid, i.name, IFNULL(l.Name, '') "
            "FROM item_template i LEFT JOIN item_template_locale l ON l.ID = i.entry AND l.locale = 'zhCN' "
            "WHERE {} ORDER BY i.Quality DESC, i.entry LIMIT {} OFFSET {}", where, PAGE + 1, page * PAGE);
        uint32 count = 0;
        bool more = false;
        Send(p, Acore::StringFormat("IT_START\t{}\t{}", cat, page));
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
                Send(p, Acore::StringFormat("IT\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", f[0].Get<uint32>(), f[1].Get<uint32>(), f[2].Get<uint32>(),
                                            f[3].Get<uint32>(), f[4].Get<uint32>(), IconOfDisplay(f[5].Get<uint32>()),
                                            Fld(f[6].Get<std::string>()), Fld(f[7].Get<std::string>())));
                ++count;
            } while (r->NextRow());
        }
        Send(p, Acore::StringFormat("IT_END\t{}\t{}\t{}", page, more ? 1 : 0, count));
    }

    // TREASFIX2: icons for the chest-type list, by category. The names come from the item display table (so the
    // game knows them); the categories are picked by the icon file's own name, not by the name of an item (an item
    // called "...Chest" is armor).
    void SendIcons(Player* p, std::string cat)
    {
        std::transform(cat.begin(), cat.end(), cat.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        Send(p, "IC_START\t" + cat);

        std::map<std::string, std::string> all;   // lower case -> the table's spelling, sorted by name
        for (uint32 i = 0; i < sItemDisplayInfoStore.GetNumRows(); ++i)
            if (ItemDisplayInfoEntry const* e = sItemDisplayInfoStore.LookupEntry(i))
                if (e->inventoryIcon && *e->inventoryIcon)
                {
                    std::string name = e->inventoryIcon;
                    std::string lo = name;
                    std::transform(lo.begin(), lo.end(), lo.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
                    if (lo.find('.') == std::string::npos && lo.find('\\') == std::string::npos)
                        all.emplace(lo, name);
                }

        auto starts = [](std::string const& s, char const* pre) { return s.rfind(pre, 0) == 0; };
        uint32 sent = 0;
        for (auto const& kv : all)
        {
            std::string const& lo = kv.first;
            bool ok = false;
            if (cat == "chest")
                ok = (starts(lo, "inv_box_") && lo.find("birdcage") == std::string::npos && lo.find("petcarrier") == std::string::npos) ||
                     starts(lo, "inv_crate_") || lo == "inv_misc_ornatebox" || starts(lo, "inv_misc_urn_") ||
                     starts(lo, "inv_misc_gift_") || starts(lo, "inv_misc_giftwrap_") || starts(lo, "inv_chest_christmas") ||
                     starts(lo, "inv_holiday_christmas_present") || starts(lo, "inv_misc_basket_") || lo == "inv_misc_easterbasket" ||
                     starts(lo, "inv_valentinesbox");
            else if (cat == "key")
                ok = starts(lo, "inv_misc_key_");
            else if (cat == "coin")
                ok = starts(lo, "inv_misc_coin_");
            else if (cat == "gem")
                ok = starts(lo, "inv_misc_gem_");
            else if (cat == "bag")
                ok = starts(lo, "inv_misc_bag_");
            else if (cat == "scroll")
                ok = starts(lo, "inv_scroll_") || starts(lo, "inv_misc_book_") || starts(lo, "inv_misc_note_") ||
                     starts(lo, "inv_misc_stonetablet_") || starts(lo, "inv_misc_map") || starts(lo, "inv_misc_rune_");
            if (!ok)
                continue;
            if (sent >= 120)
                break;
            Send(p, Acore::StringFormat("IC\t{}", kv.second));
            ++sent;
        }
        Send(p, Acore::StringFormat("IC_END\t{}\t{}", cat, sent));
    }

    // the appearances a chest can have: every model the stock chests use, most common first
    void SendLooks(Player* p)
    {
        Send(p, "LK_START");
        QueryResult r = WorldDatabase.Query(
            "SELECT displayId, MIN(name), COUNT(*) FROM gameobject_template WHERE type = 3 AND displayId > 0 "
            "GROUP BY displayId ORDER BY COUNT(*) DESC, displayId LIMIT 150");
        if (r)
        {
            do
            {
                Field* f = r->Fetch();
                uint32 id = f[0].Get<uint32>();
                if (GameObjectDisplayInfoEntry const* d = sGameObjectDisplayInfoStore.LookupEntry(id))
                    Send(p, Acore::StringFormat("LK\t{}\t{}\t{}", id, Fld(d->filename ? d->filename : ""), Fld(f[1].Get<std::string>())));
            } while (r->NextRow());
        }
        Send(p, "LK_END");
    }

    std::string MapNameOf(uint32 id, LocaleConstant loc)
    {
        if (MapEntry const* e = sMapStore.LookupEntry(id))
            return (e->name[loc] && *e->name[loc]) ? e->name[loc] : (e->name[0] ? e->name[0] : "?");
        return "?";
    }

    std::string AreaNameOf(uint32 id, LocaleConstant loc)
    {
        if (AreaTableEntry const* e = sAreaTableStore.LookupEntry(id))
            return (e->area_name[loc] && *e->area_name[loc]) ? e->area_name[loc] : (e->area_name[0] ? e->area_name[0] : "?");
        return "?";
    }

    // TREAS2C: the spawns of one chest type (entry 0 = every spawn in the world)
    void SendSpawns(Player* p, uint32 entry)
    {
        LocaleConstant const loc = p->GetSession()->GetSessionDbcLocale();
        uint64 const now = static_cast<uint64>(time(nullptr));
        std::vector<TreasureSpawn> all = sRebornTreasure->Snapshot();
        Send(p, Acore::StringFormat("SP_START\t{}", entry));
        uint32 sent = 0, total = 0;
        for (TreasureSpawn const& s : all)
        {
            if (entry && s.entry != entry)
                continue;
            ++total;
            if (sent >= 300)
                continue;
            ++sent;
            uint32 left = (s.chests.empty() && s.nextRespawnTime > now) ? static_cast<uint32>(s.nextRespawnTime - now) : 0;
            int dist = p->GetMapId() == s.mapId ? static_cast<int>(p->GetDistance(s.x, s.y, s.z)) : -1;
            std::string clue = sRebornTreasure->GetSpawnClue(s.spawnId);
            Send(p, Acore::StringFormat("SP\t{}\t{}\t{}\t{}\t{}\t{}\t{:.1f}\t{:.1f}\t{:.1f}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                                        s.spawnId, s.entry, s.mapId, Fld(MapNameOf(s.mapId, loc)), s.zoneId, Fld(AreaNameOf(s.zoneId, loc)),
                                        s.x, s.y, s.z, s.chests.empty() ? 0 : 1, left, s.respawnMinSecs, s.respawnMaxSecs, dist,
                                        clue.empty() ? 0 : 1, s.wet ? 1 : 0, Fld(Clip(s.comment, 80))));
            if (!clue.empty())
                Send(p, Acore::StringFormat("SPC\t{}\t{}", s.spawnId, Fld(Clip(clue, 200))));
        }
        Send(p, Acore::StringFormat("SP_END\t{}\t{}\t{}", entry, sent, total));
    }

    void Fail(ChatHandler* handler, Player* p, std::string const& what)
    {
        Send(p, "ERR\t" + Fld(what));
        handler->PSendSysMessage("|cffff0000[野外寻宝]|r {}", what);
    }
}

class RebornTreasureCommandScript : public CommandScript
{
public:
    RebornTreasureCommandScript() : CommandScript("RebornTreasureCommandScript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable treasureSubCommands =
        {
            { "add",     HandleTreasureAdd,     SEC_GAMEMASTER, Console::No  },
            { "list",    HandleTreasureList,    SEC_GAMEMASTER, Console::Yes },
            { "respawn", HandleTreasureRespawn, SEC_GAMEMASTER, Console::Yes },
            { "remove",  HandleTreasureRemove,  SEC_GAMEMASTER, Console::Yes },
            { "reload",  HandleTreasureReload,  SEC_GAMEMASTER, Console::Yes },
            { "ui",      HandleTreasureUi,      SEC_GAMEMASTER, Console::No  }
        };

        static ChatCommandTable rootCommands =
        {
            { "treasure", treasureSubCommands }
        };

        return rootCommands;
    }

    // .treasure add <1|2|3 or a chest type's entry> [respawn_secs] [comment...]
    static bool HandleTreasureAdd(ChatHandler* handler, uint32 quality, Optional<uint32> respawnSecs, Optional<Tail> comment)
    {
        Player* player = handler->GetPlayer();
        if (!player)
        {
            handler->SendSysMessage("该指令必须由处于游戏中的 GM 角色执行以获取当前坐标。");
            return false;
        }

        TreasureType probe;
        if ((quality < 1 || quality > 3) && !(sRebornTreasure->GetType(quality, probe) && probe.active))
        {
            handler->SendSysMessage("宝箱参数错误！1 = 普通, 2 = 稀有, 3 = 史诗，或写宝箱种类的编号（990200-990299）。示例: .treasure add 1 300 湖畔宝箱");
            return false;
        }

        if (!sRebornTreasure->IsDbReady())
        {
            handler->SendSysMessage("|cffff0000[野外寻宝]|r 数据表还没有导入，请先导入 TREAS1B 的 SQL。");
            return false;
        }

        uint32 respawn = respawnSecs.value_or(300);
        std::string commentStr = comment ? std::string(comment->data(), comment->size()) : std::string("GM手动创建点位");

        uint32 newSpawnId = sRebornTreasure->AddSpawn(quality, player->GetMapId(), player->GetZoneId(),
            player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), player->GetOrientation(), respawn, commentStr, player->GetMap());

        if (newSpawnId > 0)
        {
            handler->PSendSysMessage("|cff00ff00[野外寻宝]|r 成功创建宝箱点位！SpawnID: {}, 品质: {}, 刷新间隔: {} 秒, 描述: {}",
                newSpawnId, uint32(quality), respawn, commentStr);
            TreasureSpawn made;
            if (sRebornTreasure->GetSpawn(newSpawnId, made) && made.wet)
                handler->SendSysMessage("|cffff9933[野外寻宝]|r 提示：这里是水下，宝箱已放在水底。想放在岸上：站到岸上用面板右键“把点位移到我脚下”。");
        }
        else
            handler->SendSysMessage("|cffff0000[野外寻宝]|r 创建宝箱点位失败，请检查数据库配置或日志。");
        return true;
    }

    // .treasure list
    static bool HandleTreasureList(ChatHandler* handler)
    {
        std::vector<TreasureSpawn> spawns = sRebornTreasure->Snapshot();
        if (spawns.empty())
        {
            handler->SendSysMessage("当前没有任何寻宝点位。");
            return true;
        }

        handler->PSendSysMessage("===== 野外寻宝点位列表 (共 {} 个点位) =====", spawns.size());
        for (TreasureSpawn const& s : spawns)
        {
            TreasureType type;
            std::string qName = sRebornTreasure->GetType(s.entry, type) ? type.name : std::string(s.quality == 1 ? "普通" : (s.quality == 2 ? "稀有" : "史诗"));
            std::string status = !s.chests.empty() ? Acore::StringFormat("|cff00ff00已刷出 {} 处|r", s.chests.size()) : std::string("|cffff0000等待刷新|r");
            handler->PSendSysMessage("ID: {} | 地图: {} | 区域: {} | 品质: {} | 状态: {} | 坐标: ({:.1f}, {:.1f}, {:.1f}) | 备注: {}",
                s.spawnId, s.mapId, s.zoneId, qName, status, s.x, s.y, s.z, s.comment);
        }
        return true;
    }

    // .treasure respawn <spawn_id>
    static bool HandleTreasureRespawn(ChatHandler* handler, uint32 spawnId)
    {
        Player* gm = handler->GetPlayer();
        if (sRebornTreasure->ForceRespawn(spawnId, gm ? gm->GetMap() : nullptr))
            handler->PSendSysMessage("|cff00ff00[野外寻宝]|r 点位 {} 已被强制刷新！", spawnId);
        else
            handler->PSendSysMessage("|cffff0000[野外寻宝]|r 强制刷新失败，未找到点位 {}，或该地图/区域当前没有加载。", spawnId);
        return true;
    }

    // .treasure remove <spawn_id>
    static bool HandleTreasureRemove(ChatHandler* handler, uint32 spawnId)
    {
        if (sRebornTreasure->RemoveSpawn(spawnId))
            handler->PSendSysMessage("|cff00ff00[野外寻宝]|r 点位 {} 已成功移除并清除数据库记录！", spawnId);
        else
            handler->PSendSysMessage("|cffff0000[野外寻宝]|r 移除失败，未找到点位 {}。", spawnId);
        return true;
    }

    // .treasure ui <what> ...   (what the GM panel sends; see Send())
    static bool HandleTreasureUi(ChatHandler* handler, Optional<Tail> tail)
    {
        Player* gm = handler->GetPlayer();
        if (!gm)
            return false;

        std::string line = tail ? std::string(tail->data(), tail->size()) : std::string();
        std::vector<std::string> w = Split(line);
        if (w.empty())
        {
            handler->SendSysMessage("用法: .treasure ui types|loot|items|looks|typeset|typenew|typecopy|typedel|lootset|lootdel|spawns|spawngo|spawnshow|spawndel|spawnhere|spawnrespawn|spawncomment|spawnclue|spawntype ...");
            return true;
        }
        std::string const& what = w[0];

        if (what == "ping")
        {
            Send(gm, Acore::StringFormat("PONG\t{}", sRebornTreasure->IsDbReady() ? 1 : 0));
            return true;
        }
        if (!sRebornTreasure->IsDbReady())
        {
            Fail(handler, gm, "数据表还没有导入，请先导入 TREAS1B 与 TREAS2A 的 SQL");
            return true;
        }

        if (what == "types")
        {
            SendTypes(gm);
            return true;
        }
        if (what == "looks")
        {
            SendLooks(gm);
            return true;
        }
        if (what == "icons")   // TREASFIX2: icons [category]
        {
            SendIcons(gm, w.size() >= 2 ? w[1] : std::string("chest"));
            return true;
        }
        if (what == "loot" && w.size() >= 2)
        {
            SendLoot(gm, Num(w[1]));
            return true;
        }
        if (what == "items" && w.size() >= 3)          // items <category> <page> [text...]
        {
            SendItems(gm, w[1], Num(w[2]), Rest(line, 3));
            return true;
        }

        std::string err;
        if (what == "typenew")                         // typenew <name...>
        {
            uint32 entry = sRebornTreasure->NewType(Rest(line, 1), err);
            if (!entry)
                Fail(handler, gm, err);
            else
            {
                Send(gm, Acore::StringFormat("OK\ttypenew\t{}", entry));
                SendTypes(gm);
            }
            return true;
        }
        if (what == "typedel" && w.size() >= 2)        // typedel <entry>
        {
            if (!sRebornTreasure->DeleteType(Num(w[1]), err))
                Fail(handler, gm, err);
            else
            {
                Send(gm, Acore::StringFormat("OK\ttypedel\t{}", Num(w[1])));
                SendTypes(gm);
            }
            return true;
        }
        if (what == "typecopy" && w.size() >= 2)       // typecopy <entry>  (TREAS2B)
        {
            uint32 entry = sRebornTreasure->CopyType(Num(w[1]), err);
            if (!entry)
                Fail(handler, gm, err);
            else
            {
                Send(gm, Acore::StringFormat("OK\ttypecopy\t{}", entry));
                SendTypes(gm);
            }
            return true;
        }
        if (what == "typeset" && w.size() >= 4)        // typeset <entry> <field> <value...>
        {
            uint32 entry = Num(w[1]);
            TreasureType t;
            if (!sRebornTreasure->GetType(entry, t))
            {
                Fail(handler, gm, "没有这种宝箱");
                return true;
            }
            std::string const& field = w[2];
            std::string value = Rest(line, 3);
            if (field == "name")            t.name = value;
            else if (field == "icon")       t.icon = value;
            else if (field == "display")    t.displayId = Num(value);
            else if (field == "size")       t.size = static_cast<float>(std::atof(value.c_str()));
            else if (field == "gold" && w.size() >= 5) { t.goldMin = Num(w[3]); t.goldMax = Num(w[4]); }
            else if (field == "rarity")     t.rarity = static_cast<uint8>(Num(value));
            else if (field == "respawn" && w.size() >= 5) { t.respawnMin = Num(w[3]); t.respawnMax = Num(w[4]); }
            else if (field == "active")     t.active = Num(value) != 0;
            else if (field == "dscale")     t.dungeonGoldScale = Num(value) != 0;   // TREAS2B
            else
            {
                Fail(handler, gm, "不认识的设置项: " + field);
                return true;
            }
            if (!sRebornTreasure->SaveType(t, err))
                Fail(handler, gm, err);
            else
            {
                Send(gm, Acore::StringFormat("OK\ttypeset\t{}", entry));
                if (sRebornTreasure->GetType(entry, t))
                    SendType(gm, t);
            }
            return true;
        }
        // ---- TREAS2C: spawns (point = a place where a chest of a type stands)
        if (what == "spawns")                          // spawns [entry]
        {
            SendSpawns(gm, w.size() >= 2 ? Num(w[1]) : 0);
            return true;
        }
        if (what == "spawngo" && w.size() >= 2)        // spawngo <id>: teleport the GM there
        {
            TreasureSpawn s;
            if (!sRebornTreasure->GetSpawn(Num(w[1]), s))
            {
                Fail(handler, gm, "没有这个点位");
                return true;
            }
            if (gm->IsInCombat() || gm->IsBeingTeleported())
            {
                Fail(handler, gm, "战斗中或正在传送，稍后再试");
                return true;
            }
            if (!gm->TeleportTo(s.mapId, s.x, s.y, s.z + 1.0f, s.o))
                Fail(handler, gm, "传送失败（副本里的点位要先进入那个副本）");
            else
                Send(gm, Acore::StringFormat("OK\tspawngo\t{}", s.spawnId));
            return true;
        }
        if (what == "spawnshow" && w.size() >= 2)      // spawnshow <id>: put the chest there now (it may have been taken)
        {
            if (!sRebornTreasure->ForceRespawn(Num(w[1]), gm->GetMap()))
                Fail(handler, gm, "刷出失败：没有这个点位，或那张地图现在没有加载（先传送过去）");
            else
                Send(gm, Acore::StringFormat("OK\tspawnshow\t{}", Num(w[1])));
            return true;
        }
        if (what == "spawndel" && w.size() >= 2)       // spawndel <id>
        {
            if (!sRebornTreasure->RemoveSpawn(Num(w[1])))
                Fail(handler, gm, "没有这个点位");
            else
                Send(gm, Acore::StringFormat("OK\tspawndel\t{}", Num(w[1])));
            return true;
        }
        if (what == "spawnhere" && w.size() >= 2)      // spawnhere <id>: move the point to where the GM stands
        {
            if (!sRebornTreasure->MoveSpawn(Num(w[1]), static_cast<uint16>(gm->GetMapId()), gm->GetZoneId(), gm->GetPositionX(),
                                            gm->GetPositionY(), gm->GetPositionZ(), gm->GetOrientation(), gm->GetMap()))
                Fail(handler, gm, "没有这个点位");
            else
            {
                Send(gm, Acore::StringFormat("OK\tspawnhere\t{}", Num(w[1])));
                TreasureSpawn moved;
                if (sRebornTreasure->GetSpawn(Num(w[1]), moved) && moved.wet)
                    handler->SendSysMessage("|cffff9933[野外寻宝]|r 提示：这里是水下，宝箱会沉在水底。");
            }
            return true;
        }
        if (what == "spawnsnap" && w.size() >= 2)      // spawnsnap <id|0>: put the point(s) on the ground
        {
            uint32 const id = Num(w[1]);
            TreasureSpawn probe;
            if (id && !sRebornTreasure->GetSpawn(id, probe))
            {
                Fail(handler, gm, "没有这个点位");
                return true;
            }
            RebornTreasureMgr::SnapResult const r = sRebornTreasure->SnapSpawns(id, gm->GetMap());
            Send(gm, Acore::StringFormat("OK\tspawnsnap\t{}\t{}\t{}\t{}", id, r.moved, r.wet, r.skipped));
            return true;
        }
        if (what == "spawnrespawn" && w.size() >= 4)   // spawnrespawn <id> <min> <max>
        {
            if (!sRebornTreasure->SetSpawnRespawn(Num(w[1]), Num(w[2]), Num(w[3])))
                Fail(handler, gm, "没有这个点位");
            else
                Send(gm, Acore::StringFormat("OK\tspawnrespawn\t{}", Num(w[1])));
            return true;
        }
        if (what == "spawncomment" && w.size() >= 2)   // spawncomment <id> [text...]
        {
            if (!sRebornTreasure->SetSpawnComment(Num(w[1]), Rest(line, 2)))
                Fail(handler, gm, "没有这个点位");
            else
                Send(gm, Acore::StringFormat("OK\tspawncomment\t{}", Num(w[1])));
            return true;
        }
        if (what == "spawnclue" && w.size() >= 2)      // spawnclue <id> [text...]  (no text = remove the clue)
        {
            if (!sRebornTreasure->SetSpawnClue(Num(w[1]), Rest(line, 2)))
                Fail(handler, gm, "没有这个点位");
            else
                Send(gm, Acore::StringFormat("OK\tspawnclue\t{}", Num(w[1])));
            return true;
        }
        if (what == "spawntype" && w.size() >= 3)      // spawntype <id> <entry>
        {
            if (!sRebornTreasure->SetSpawnType(Num(w[1]), Num(w[2]), err))
                Fail(handler, gm, err);
            else
                Send(gm, Acore::StringFormat("OK\tspawntype\t{}", Num(w[1])));
            return true;
        }
        if (what == "lootset" && w.size() >= 7)        // lootset <entry> <item> <chance> <min> <max> <group>
        {
            uint32 entry = Num(w[1]);
            uint32 item = Num(w[2]);
            float chance = static_cast<float>(std::atof(w[3].c_str()));
            uint32 mn = std::max<uint32>(1, std::min<uint32>(Num(w[4]), 255));
            uint32 mx = std::max<uint32>(mn, std::min<uint32>(Num(w[5]), 255));
            uint32 group = std::min<uint32>(Num(w[6]), 255);
            TreasureType t;
            if (!sRebornTreasure->GetType(entry, t))
            {
                Fail(handler, gm, "没有这种宝箱");
                return true;
            }
            if (!sObjectMgr->GetItemTemplate(item))
            {
                Fail(handler, gm, "没有这个物品: " + w[2]);
                return true;
            }
            chance = std::max(0.0f, std::min(chance, 100.0f));
            WorldDatabase.Execute(
                "REPLACE INTO gameobject_loot_template (Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment) "
                "VALUES ({}, {}, 0, {}, 0, 1, {}, {}, {}, 'TREAS2A panel')", entry, item, chance, group, mn, mx);
            sRebornTreasure->MarkLootDirty();
            Send(gm, Acore::StringFormat("OK\tlootset\t{}\t{}", entry, item));
            return true;
        }
        if (what == "lootdel" && w.size() >= 3)        // lootdel <entry> <item>
        {
            WorldDatabase.Execute("DELETE FROM gameobject_loot_template WHERE Entry = {} AND Item = {}", Num(w[1]), Num(w[2]));
            sRebornTreasure->MarkLootDirty();
            Send(gm, Acore::StringFormat("OK\tlootdel\t{}\t{}", Num(w[1]), Num(w[2])));
            return true;
        }

        Fail(handler, gm, "不认识的面板指令: " + what);
        return true;
    }

    // .treasure reload
    static bool HandleTreasureReload(ChatHandler* handler)
    {
        sRebornTreasure->Reload();
        handler->SendSysMessage("|cff00ff00[野外寻宝]|r 模块配置与数据库点位数据已重新加载！");
        return true;
    }
};

void AddSC_mod_reborn_treasure_commands()
{
    new RebornTreasureCommandScript();
}
