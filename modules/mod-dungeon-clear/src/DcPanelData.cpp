/*
 * mod-dungeon-clear — DcPanelData.cpp  (RebornWOW DCUI3B)  See DcPanelData.h.
 */

#include "DcPanelData.h"

#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "PlayerbotAIConfig.h"  // DCTEST8A
#include "Playerbots.h"
#include "SocialMgr.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include "TestRun/DcTestDungeonRegistry.h"
#include "bot_ai.h"
#include "botmgr.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>  // DCUI3C3: std::abs(int)
#include <map>
#include <set>
#include <vector>

namespace
{
    std::string Clean(std::string s)
    {
        for (char& c : s)
            if (c == '\t' || c == '\n' || c == '\r')
                c = ' ';
        return s;
    }

    std::string Lower(std::string s)
    {
        std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) { return std::tolower(c); });
        return s;
    }

    // ASCII case-insensitive; multibyte names (Chinese) match byte-for-byte.
    bool NameMatches(std::string const& name, std::string const& q)
    {
        return q.empty() || Lower(name).find(Lower(q)) != std::string::npos;
    }

    struct Cand
    {
        std::string name;
        uint32 cls = 0, level = 0, race = 0;
        bool online = false, mine = false;
        std::string extra;  // "f" friend, "g" guild, "n" npcbot, "b" bot, "p" player
    };

    void Emit(DcPanelData::Send const& send, std::string const& cat, Cand const& c)
    {
        uint32 const team = c.race ? (Player::TeamIdForRace(static_cast<uint8>(c.race)) == TEAM_HORDE ? 1 : 0) : 2;
        send(Acore::StringFormat("DC\tRO\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", cat, Clean(c.name), c.cls, c.level,
                                 c.race, team, c.online ? 1 : 0, c.mine ? 1 : 0, c.extra.empty() ? "-" : c.extra));
    }

    void SortByLevel(std::vector<Cand>& v, uint32 myLevel)
    {
        std::sort(v.begin(), v.end(), [myLevel](Cand const& a, Cand const& b)
        {
            int const da = std::abs(int(a.level) - int(myLevel)), db = std::abs(int(b.level) - int(myLevel));
            if (da != db)
                return da < db;
            if (a.level != b.level)
                return a.level > b.level;
            return a.name < b.name;
        });
    }

    void Account(Player* me, std::vector<Cand>& out)
    {
        uint32 const account = me->GetSession()->GetAccountId();
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT guid, name, class, level, race FROM characters WHERE account = {}", account))
        {
            do
            {
                Field* f = r->Fetch();
                ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(f[0].Get<uint32>());
                if (guid == me->GetGUID())
                    continue;
                Cand c;
                c.name = f[1].Get<std::string>();
                c.cls = f[2].Get<uint8>();
                Player* p = ObjectAccessor::FindConnectedPlayer(guid);
                c.level = p ? p->GetLevel() : f[3].Get<uint8>();
                c.race = f[4].Get<uint8>();
                c.online = p != nullptr;
                c.mine = true;
                c.extra = "a";
                out.push_back(c);
            } while (r->NextRow());
        }
    }

    bool SameGroup(Player* me, Player* p)
    {
        Group* g = me->GetGroup();
        return g && p->GetGroup() == g;
    }

    void OnlineBots(Player* me, std::vector<Cand>& out)
    {
        TeamId const myTeam = me->GetTeamId();
        for (auto const& kv : ObjectAccessor::GetPlayers())
        {
            Player* p = kv.second;
            if (!p || p == me || !p->IsInWorld() || p->GetTeamId() != myTeam || SameGroup(me, p))
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(p);
            if (!ai || ai->IsRealPlayer())
                continue;
            Cand c;
            c.name = p->GetName();
            c.cls = p->getClass();
            c.level = p->GetLevel();
            c.race = p->getRace();
            c.online = true;
            c.mine = p->GetSession()->GetAccountId() == me->GetSession()->GetAccountId();
            c.extra = "b";
            out.push_back(c);
        }
    }

    void NpcBots(Player* me, std::vector<Cand>& out)
    {
        BotMgr* mgr = me->GetBotMgr();
        if (!mgr)
            return;
        for (auto const& kv : *mgr->GetBotMap())
        {
            Creature* bot = kv.second;
            if (!bot)
                continue;
            Cand c;
            c.name = bot->GetName();
            bot_ai const* ai = bot->GetBotAI();
            c.cls = ai ? ai->GetBotClass() : 0;
            c.level = bot->GetLevel();
            c.race = bot->getRace();
            c.online = bot->IsAlive();
            c.mine = true;
            c.extra = "n";
            out.push_back(c);
        }
    }

    void RealPlayers(Player* me, std::vector<Cand>& out)
    {
        int32 const mode = sConfigMgr->GetOption<int32>("DungeonClear.PartyPicker.RealPlayers", 2, false);
        if (mode <= 0)
            return;
        PlayerSocial* social = me->GetSocial();
        for (auto const& kv : ObjectAccessor::GetPlayers())
        {
            Player* p = kv.second;
            if (!p || p == me || !p->IsInWorld() || !p->GetSession())
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(p);
            if (ai && !ai->IsRealPlayer())
                continue;  // a bot, not a person
            bool const friendOf = social && social->HasFriend(p->GetGUID());
            bool const guildmate = me->GetGuildId() && p->GetGuildId() == me->GetGuildId();
            if (mode == 1 && !friendOf && !guildmate)
                continue;
            Cand c;
            c.name = p->GetName();
            c.cls = p->getClass();
            c.level = p->GetLevel();
            c.race = p->getRace();
            c.online = true;
            c.extra = std::string("p") + (friendOf ? "f" : "") + (guildmate ? "g" : "");
            out.push_back(c);
        }
    }

    // RebornWOW DCTEST8A: OFFLINE random-bot characters of the player's faction within 3
    // levels of `level` (0 = the player's own) -- what a `.dc test ... party=` roster can
    // use. The server still checks each name when the run starts.
    void Pool(Player* me, uint32 level, std::vector<Cand>& out)
    {
        int const lv = int(level ? level : me->GetLevel());
        TeamId const team = me->GetTeamId();
        if (QueryResult r = CharacterDatabase.Query(
                "SELECT guid, name, class, level, race, account FROM characters "
                "WHERE online = 0 AND level BETWEEN {} AND {} LIMIT 600",
                std::max(1, lv - 3), lv + 3))
        {
            do
            {
                Field* f = r->Fetch();
                if (!sPlayerbotAIConfig.IsInRandomAccountList(f[5].Get<uint32>()))
                    continue;
                uint8 const race = f[4].Get<uint8>();
                if (Player::TeamIdForRace(race) != team)
                    continue;
                Cand c;
                c.name = f[1].Get<std::string>();
                c.cls = f[2].Get<uint8>();
                c.level = f[3].Get<uint8>();
                c.race = race;
                c.online = false;
                c.extra = "o";
                out.push_back(c);
            } while (r->NextRow());
        }
    }
}

namespace DcPanelData
{
    void SendDungeons(Player* player, Send const& send)
    {
        if (!player || !player->GetSession())
            return;
        LocaleConstant const loc = player->GetSession()->GetSessionDbcLocale();

        // .dc test rows per map: token, recommended / heroic level, entrance.
        std::map<uint32, std::vector<DcTestDungeonRegistry::Row const*>> rows;
        for (DcTestDungeonRegistry::Row const& r : DcTestDungeonRegistry::All())
            if (!DcTestDungeonRegistry::IsScenario(r))
                rows[r.mapId].push_back(&r);

        // Lowest LFG level per map.
        std::map<uint32, uint32> minLevel;
        for (uint32 i = 0; i < sLFGDungeonStore.GetNumRows(); ++i)
            if (LFGDungeonEntry const* d = sLFGDungeonStore.LookupEntry(i))
            {
                auto it = minLevel.find(d->MapID);
                if (d->MinLevel && (it == minLevel.end() || d->MinLevel < it->second))
                    minLevel[d->MapID] = d->MinLevel;
            }

        send("DC\tDL_START");
        for (uint32 id = 0; id < sMapStore.GetNumRows(); ++id)
        {
            MapEntry const* m = sMapStore.LookupEntry(id);
            if (!m || !m->IsDungeon() || !sObjectMgr->GetInstanceTemplate(id))
                continue;
            std::string name = m->name[loc] && *m->name[loc] ? m->name[loc] : (m->name[0] ? m->name[0] : "");
            if (name.empty())
                continue;
            uint32 normal = m->maxPlayers;
            if (MapDifficulty const* d = GetMapDifficultyData(id, Difficulty(0)))
                if (d->maxPlayers)
                    normal = d->maxPlayers;
            std::string sizes = std::to_string(normal);
            if (m->IsRaid())
                if (MapDifficulty const* d = GetMapDifficultyData(id, Difficulty(1)))
                    if (d->maxPlayers && d->maxPlayers != normal)
                        sizes += "/" + std::to_string(d->maxPlayers);
            std::string tokens;
            uint32 rec = 0, heroic = 0;
            float ex = 0, ey = 0, ez = 0;
            auto rit = rows.find(id);
            if (rit != rows.end())
                for (DcTestDungeonRegistry::Row const* r : rit->second)
                {
                    tokens += (tokens.empty() ? "" : ",") + std::string(r->token);
                    if (!rec)
                    {
                        rec = r->recommendedLevel;
                        heroic = r->heroicLevel;
                        ex = r->x;
                        ey = r->y;
                        ez = r->z;
                    }
                }
            auto lit = minLevel.find(id);
            send(Acore::StringFormat("DC\tDL\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{:.1f}\t{:.1f}\t{:.1f}", id,
                                     m->IsRaid() ? 1 : 0, sizes, lit != minLevel.end() ? lit->second : 0, rec, heroic,
                                     m->Expansion(), Clean(name), tokens.empty() ? "-" : tokens, ex, ey, ez));
        }
        send("DC\tDL_END");
    }

    void SendRoster(Player* player, std::string const& param, Send const& send)
    {
        if (!player || !player->GetSession())
            return;
        std::size_t const tab = param.find('\t');
        std::string const cat = tab == std::string::npos ? param : param.substr(0, tab);
        std::string const q = tab == std::string::npos ? "" : param.substr(tab + 1);
        // RebornWOW DCTEST8A: "pool" takes "<name fragment>\t<level>"
        std::string frag = q;
        uint32 poolLevel = 0;
        if (std::size_t const t2 = q.find('\t'); t2 != std::string::npos)
        {
            frag = q.substr(0, t2);
            poolLevel = static_cast<uint32>(std::strtoul(q.c_str() + t2 + 1, nullptr, 10));
        }

        std::vector<Cand> v;
        if (cat == "account")
            Account(player, v);
        else if (cat == "bots")
            OnlineBots(player, v);
        else if (cat == "npcbots")
            NpcBots(player, v);
        else if (cat == "players")
            RealPlayers(player, v);
        else if (cat == "pool")
            Pool(player, poolLevel, v);
        else if (cat == "search")
        {
            Account(player, v);
            OnlineBots(player, v);
            NpcBots(player, v);
            RealPlayers(player, v);
            std::set<std::string> seen;
            std::vector<Cand> uniq;
            for (Cand const& c : v)
                if (seen.insert(c.name).second)
                    uniq.push_back(c);
            v.swap(uniq);
        }
        std::vector<Cand> kept;
        for (Cand const& c : v)
            if (NameMatches(c.name, frag))
                kept.push_back(c);
        SortByLevel(kept, player->GetLevel());
        if (kept.size() > 40)
            kept.resize(40);
        send("DC\tRO_START\t" + cat);
        for (Cand const& c : kept)
            Emit(send, cat, c);
        send(Acore::StringFormat("DC\tRO_END\t{}\t{}", cat, v.size()));
    }

    // RebornWOW DCUI3C5: each group member's role for the panel's party column (sorting
    // and the role tag): playerbots' own test -- a bot by its tank / heal strategy, a
    // real player by talents.
    void SendPartyRoles(Player* player, Send const& send)
    {
        if (!player)
            return;
        send("DC\tPR_START");
        auto one = [&](Player* m)
        {
            char const* role = PlayerbotAI::IsTank(m) ? "t" : (PlayerbotAI::IsHeal(m) ? "h" : "d");
            send(Acore::StringFormat("DC\tPR\t{}\t{}", Clean(m->GetName()), role));
        };
        if (Group* g = player->GetGroup())
        {
            for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
                if (Player* m = r->GetSource())
                    one(m);
        }
        else
            one(player);
        send("DC\tPR_END");
    }

    // RebornWOW DCUI3C3: candidates for "fill". Roles by playerbots' own test (a bot by
    // its tank / heal strategy, a real player by talent spec).
    void SendFill(Player* player, std::string const& param, Send const& send)
    {
        if (!player || !player->GetSession())
            return;
        uint32 size = 5;
        try { size = static_cast<uint32>(std::stoul(param)); } catch (...) {}
        // wanted tanks / healers per group size
        uint32 wantT = 1, wantH = 1;
        if (size >= 40) { size = 40; wantT = 4; wantH = 10; }
        else if (size >= 25) { size = 25; wantT = 3; wantH = 6; }
        else if (size >= 20) { size = 20; wantT = 3; wantH = 5; }
        else if (size >= 10) { size = 10; wantT = 2; wantH = 3; }
        else size = 5;

        uint32 have = 1, tanks = 0, heals = 0;
        auto countRole = [&](Player* m)
        {
            if (PlayerbotAI::IsTank(m))
                ++tanks;
            else if (PlayerbotAI::IsHeal(m))
                ++heals;
        };
        if (Group* g = player->GetGroup())
        {
            have = g->GetMembersCount();
            for (GroupReference* itr = g->GetFirstMember(); itr; itr = itr->next())
                if (Player* m = itr->GetSource())
                    countRole(m);
        }
        else
            countRole(player);
        if (have >= size)
        {
            send(Acore::StringFormat("DC\tFILL_END\t0\t0"));
            return;
        }
        uint32 const need = size - have;
        uint32 needT = wantT > tanks ? wantT - tanks : 0;
        uint32 needH = wantH > heals ? wantH - heals : 0;

        // free bots: online, same faction, alive, no group, nobody's alt, not in a battleground
        TeamId const team = player->GetTeamId();
        int const myLevel = int(player->GetLevel());
        std::vector<Player*> pool;
        for (auto const& kv : ObjectAccessor::GetPlayers())
        {
            Player* p = kv.second;
            if (!p || p == player || !p->IsInWorld() || !p->IsAlive() || p->GetGroup() || p->GetTeamId() != team ||
                p->InBattleground())
                continue;
            PlayerbotAI* ai = GET_PLAYERBOT_AI(p);
            if (!ai || ai->IsRealPlayer())
                continue;
            Player* master = ai->GetMaster();
            if (master && master != p)
                continue;  // somebody's own bot
            if (std::abs(int(p->GetLevel()) - myLevel) > 10)
                continue;
            pool.push_back(p);
        }
        std::sort(pool.begin(), pool.end(), [myLevel](Player* a, Player* b)
        {
            int const da = std::abs(int(a->GetLevel()) - myLevel), db = std::abs(int(b->GetLevel()) - myLevel);
            if (da != db)
                return da < db;
            return a->GetName() < b->GetName();
        });

        std::vector<std::pair<Player*, char>> picked;
        std::set<Player*> used;
        auto take = [&](char role, uint32 count, auto&& test)
        {
            for (Player* p : pool)
            {
                if (count == 0 || picked.size() >= need)
                    return;
                if (used.count(p) || !test(p))
                    continue;
                used.insert(p);
                picked.emplace_back(p, role);
                --count;
            }
        };
        take('t', needT, [](Player* p) { return PlayerbotAI::IsTank(p); });
        take('h', needH, [](Player* p) { return PlayerbotAI::IsHeal(p); });
        take('d', need, [](Player* p) { return !PlayerbotAI::IsTank(p) && !PlayerbotAI::IsHeal(p); });
        take('d', need, [](Player*) { return true; });  // short of pure DPS: anyone left

        for (auto const& pr : picked)
            send(Acore::StringFormat("DC\tFILL\t{}\t{}", Clean(pr.first->GetName()), std::string(1, pr.second)));
        send(Acore::StringFormat("DC\tFILL_END\t{}\t{}", picked.size(), need));
    }
}
