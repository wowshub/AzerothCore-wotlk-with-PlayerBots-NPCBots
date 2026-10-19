/*
 * mod-dungeon-clear — DcPlayerRuns.cpp  (RebornWOW DCRUN1A)  See DcPlayerRuns.h.
 */

#include "DcPlayerRuns.h"

#include "Creature.h"
#include "DBCStores.h"
#include "Group.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include "DcPartyTier.h"
#include "TestRun/DcTestDungeonRegistry.h"
#include "TestRun/DcTestRunManager.h"
#include "bot_ai.h"
#include "botmgr.h"

#include <algorithm>
#include <ctime>
#include <deque>
#include <fstream>
#include <map>
#include <mutex>
#include <sstream>
#include <vector>

namespace
{
    struct RunEvent
    {
        uint32 t = 0;          // seconds since the run started
        std::string name;
    };

    struct Member
    {
        std::string name;
        uint32 cls = 0, level = 0;
        char kind = 'p';       // a = your account, b = playerbot, n = NPCBot, p = real player
    };

    struct Run
    {
        std::string id;
        uint32 owner = 0;      // owner's character guid (low)
        uint32 map = 0, instance = 0;
        bool heroic = false;
        time_t start = 0, end = 0;
        uint32 total = 0, restarts = 0;
        std::vector<RunEvent> bosses, deaths;
        std::vector<Member> members;
        std::string tier, result = "running", reason;
        std::vector<uint32> viewers;  // DCRUN1B: real players who get the record (owner first)
    };

    constexpr std::size_t kKeep = 20;          // finished runs kept per owner
    constexpr time_t kContinueWindow = 1800;   // `dc on` again within 30 min continues
    constexpr std::size_t kMaxEvents = 80;

    std::mutex gMtx;
    std::map<ObjectGuid, Run> gActive;                 // by DC tank
    std::map<uint32, std::deque<Run>> gDone;           // by viewer (DCRUN1B; was owner), newest first

    std::string Clean(std::string s)
    {
        for (char& c : s)
            if (c == '\t' || c == '\n' || c == '\r')
                c = ' ';
        return s;
    }

    bool IsReal(Player* p)
    {
        PlayerbotAI* ai = GET_PLAYERBOT_AI(p);
        return !ai || ai->IsRealPlayer();
    }

    // The real player the run belongs to: the group leader if real, else the tank's
    // master, else any real member, else the tank itself when it is a self-botted player.
    Player* OwnerOf(Player* tank)
    {
        Group* g = tank->GetGroup();
        if (g)
            if (Player* l = ObjectAccessor::FindConnectedPlayer(g->GetLeaderGUID()); l && IsReal(l))
                return l;
        if (PlayerbotAI* ai = GET_PLAYERBOT_AI(tank))
            if (Player* m = ai->GetMaster(); m && m != tank && IsReal(m))
                return m;
        if (g)
            for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
                if (Player* p = r->GetSource(); p && IsReal(p))
                    return p;
        return IsReal(tank) ? tank : nullptr;
    }

    // RebornWOW DCRUN1B: the real players of the tank's party (owner first).
    std::vector<uint32> ViewersOf(Player* tank, Player* owner)
    {
        std::vector<uint32> out{ owner->GetGUID().GetCounter() };
        if (Group* g = tank->GetGroup())
            for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
                if (Player* p = r->GetSource(); p && IsReal(p))
                {
                    uint32 const low = p->GetGUID().GetCounter();
                    if (std::find(out.begin(), out.end(), low) == out.end())
                        out.push_back(low);
                }
        return out;
    }

    bool Sees(Run const& r, uint32 low)
    {
        return r.owner == low || std::find(r.viewers.begin(), r.viewers.end(), low) != r.viewers.end();
    }

    void AddViewers(Run& r, std::vector<uint32> const& more)
    {
        for (uint32 low : more)
            if (std::find(r.viewers.begin(), r.viewers.end(), low) == r.viewers.end())
                r.viewers.push_back(low);
    }

    // Called with gMtx held: drop every viewer's copy of this run id (it runs again).
    void ForgetDoneLocked(std::string const& id)
    {
        for (auto& kv : gDone)
            for (auto it = kv.second.begin(); it != kv.second.end();)
                it = it->id == id ? kv.second.erase(it) : it + 1;
    }

    std::string Classify(std::string const& reason)
    {
        if (reason == "All bosses cleared!")
            return "clear";
        if (reason == "Dungeon clear disabled.")
            return "stop";
        if (reason.find("wiped") != std::string::npos)
            return "wipe";
        if (reason.find("Left the dungeon") != std::string::npos)
            return "left";
        if (reason.find("died") != std::string::npos || reason.find("deaths") != std::string::npos ||
            reason.find("resurrected") != std::string::npos)
            return "death";
        return "end";
    }

    void Esc(std::ostringstream& s, std::string const& v)
    {
        s << '"';
        for (char c : v)
        {
            if (c == '"' || c == '\\')
                s << '\\' << c;
            else if (c == '\n')
                s << "\\n";
            else if (static_cast<unsigned char>(c) < 0x20)
                s << ' ';
            else
                s << c;
        }
        s << '"';
    }

    void EscEvents(std::ostringstream& s, std::vector<RunEvent> const& v)
    {
        s << '[';
        for (std::size_t i = 0; i < v.size(); ++i)
        {
            if (i)
                s << ',';
            s << "{\"t\":" << v[i].t << ",\"name\":";
            Esc(s, v[i].name);
            s << '}';
        }
        s << ']';
    }

    // Called with gMtx held.
    void AppendFile(Run const& r)
    {
        static std::ofstream file;
        static bool opened = false;
        if (!opened)
        {
            file.open("dc_playerruns.jsonl", std::ios::out | std::ios::app);
            opened = true;
        }
        if (!file.is_open())
            return;
        std::ostringstream s;
        s << "{\"id\":";
        Esc(s, r.id);
        s << ",\"owner\":" << r.owner << ",\"viewers\":[";  // viewers: DCRUN1B
        for (std::size_t i = 0; i < r.viewers.size(); ++i)
            s << (i ? "," : "") << r.viewers[i];
        s << "],\"map\":" << r.map << ",\"instance\":" << r.instance
          << ",\"heroic\":" << (r.heroic ? "true" : "false") << ",\"start\":" << r.start << ",\"end\":" << r.end
          << ",\"result\":";
        Esc(s, r.result);
        s << ",\"reason\":";
        Esc(s, r.reason);
        s << ",\"tier\":";
        Esc(s, r.tier);
        s << ",\"bossTotal\":" << r.total << ",\"restarts\":" << r.restarts << ",\"bosses\":";
        EscEvents(s, r.bosses);
        s << ",\"deaths\":";
        EscEvents(s, r.deaths);
        s << ",\"members\":[";
        for (std::size_t i = 0; i < r.members.size(); ++i)
        {
            if (i)
                s << ',';
            s << "{\"name\":";
            Esc(s, r.members[i].name);
            s << ",\"class\":" << r.members[i].cls << ",\"level\":" << r.members[i].level << ",\"kind\":\""
              << r.members[i].kind << "\"}";
        }
        s << "]}";
        file << s.str() << '\n';
        file.flush();
    }

    // Called with gMtx held.
    void FinishLocked(std::map<ObjectGuid, Run>::iterator it, std::string const& reason)
    {
        Run r = std::move(it->second);
        gActive.erase(it);
        r.end = time(nullptr);
        r.reason = reason;
        r.result = Classify(reason);
        AppendFile(r);
        // RebornWOW DCRUN1B: a copy for every viewer (the owner included)
        std::vector<uint32> viewers = r.viewers;
        if (std::find(viewers.begin(), viewers.end(), r.owner) == viewers.end())
            viewers.insert(viewers.begin(), r.owner);
        ForgetDoneLocked(r.id);
        for (uint32 low : viewers)
        {
            std::deque<Run>& done = gDone[low];
            done.push_front(r);
            while (done.size() > kKeep)
                done.pop_back();
        }
    }

    std::vector<Member> Snapshot(Player* tank, Player* owner)
    {
        std::vector<Member> out;
        uint32 const account = owner->GetSession() ? owner->GetSession()->GetAccountId() : 0;
        auto add = [&](Player* p)
        {
            Member m;
            m.name = p->GetName();
            m.cls = p->getClass();
            m.level = p->GetLevel();
            bool const mine = p->GetSession() && p->GetSession()->GetAccountId() == account;
            m.kind = mine ? 'a' : (IsReal(p) ? 'p' : 'b');
            out.push_back(m);
        };
        if (Group* g = tank->GetGroup())
        {
            for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
                if (Player* p = r->GetSource())
                    add(p);
        }
        else
            add(tank);
        // the owner's NPCBots in the same map (they are creatures, not group members)
        if (owner->GetMap() == tank->GetMap())
            if (BotMgr* mgr = owner->GetBotMgr())
                for (auto const& kv : *mgr->GetBotMap())
                    if (Creature* bot = kv.second; bot && bot->GetMap() == tank->GetMap())
                    {
                        Member m;
                        m.name = bot->GetName();
                        bot_ai const* ai = bot->GetBotAI();
                        m.cls = ai ? ai->GetBotClass() : 0;
                        m.level = bot->GetLevel();
                        m.kind = 'n';
                        out.push_back(m);
                    }
        return out;
    }

    Run const* FindLocked(uint32 owner, std::string const& id)
    {
        for (auto const& kv : gActive)
            if (Sees(kv.second, owner) && kv.second.id == id)  // DCRUN1B: viewers too
                return &kv.second;
        auto it = gDone.find(owner);
        if (it != gDone.end())
            for (Run const& r : it->second)
                if (r.id == id)
                    return &r;
        return nullptr;
    }

    std::string TokenFor(uint32 map)
    {
        for (DcTestDungeonRegistry::Row const& r : DcTestDungeonRegistry::All())
            if (r.mapId == map && !DcTestDungeonRegistry::IsScenario(r))
                return r.token;
        return "-";
    }

    class DcPlayerRunsDeathScript : public UnitScript
    {
    public:
        DcPlayerRunsDeathScript() : UnitScript("DcPlayerRunsDeathScript", true, { UNITHOOK_ON_UNIT_DEATH }) {}

        void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
        {
            if (!unit || !unit->GetMap() || !unit->GetMap()->IsDungeon())
                return;
            Creature* c = unit->ToCreature();
            bool const boss = c && c->IsDungeonBoss();
            bool const member = unit->IsPlayer() || (c && c->IsNPCBot());
            if (!boss && !member)
                return;
            uint32 const inst = unit->GetInstanceId(), map = unit->GetMapId();
            std::lock_guard<std::mutex> lock(gMtx);
            for (auto& kv : gActive)
            {
                Run& r = kv.second;
                if (r.instance != inst || r.map != map)
                    continue;
                std::vector<RunEvent>& list = boss ? r.bosses : r.deaths;
                if (list.size() < kMaxEvents)
                    list.push_back({ static_cast<uint32>(time(nullptr) - r.start), unit->GetName() });
                break;
            }
        }
    };
}

namespace DcPlayerRuns
{
    void OnRunStarted(Player* tank, uint32 bossTotal)
    {
        if (!tank || !tank->GetMap() || !tank->GetMap()->IsDungeon())
            return;
        if (DcTestRunManager::Instance().IsTestTank(tank->GetGUID()))
            return;
        Player* owner = OwnerOf(tank);
        if (!owner)
            return;
        uint32 const ownerLow = owner->GetGUID().GetCounter();
        uint32 const inst = tank->GetInstanceId(), map = tank->GetMapId();
        std::string const tier = DcPartyTier::TierFor(owner);
        std::vector<Member> members = Snapshot(tank, owner);
        std::vector<uint32> const viewers = ViewersOf(tank, owner);  // DCRUN1B

        std::lock_guard<std::mutex> lock(gMtx);
        auto it = gActive.find(tank->GetGUID());
        if (it != gActive.end())
        {
            if (it->second.instance == inst && it->second.map == map)
            {
                ++it->second.restarts;           // `dc on` again mid-run
                AddViewers(it->second, viewers);  // DCRUN1B: whoever joined since
                return;
            }
            FinishLocked(it, "Left the dungeon (a new run started).");
        }
        // continue a recent unfinished run in the same instance
        std::deque<Run>& done = gDone[ownerLow];
        if (!done.empty())
        {
            Run& last = done.front();
            if (last.instance == inst && last.map == map && last.result != "clear" &&
                time(nullptr) - last.end < kContinueWindow)
            {
                Run r = last;
                ForgetDoneLocked(r.id);          // DCRUN1B: every viewer's copy
                AddViewers(r, viewers);
                r.result = "running";
                r.reason.clear();
                r.end = 0;
                ++r.restarts;
                gActive[tank->GetGUID()] = std::move(r);
                return;
            }
        }
        Run r;
        r.start = time(nullptr);
        r.id = Acore::StringFormat("{}-{}", static_cast<uint64>(r.start), tank->GetGUID().GetCounter());
        r.owner = ownerLow;
        r.map = map;
        r.instance = inst;
        r.heroic = tank->GetMap()->IsHeroic();
        r.total = bossTotal;
        r.tier = tier.empty() ? "normal" : tier;
        r.members = std::move(members);
        r.viewers = viewers;                     // DCRUN1B
        gActive[tank->GetGUID()] = std::move(r);
    }

    void OnRunEnded(Player* tank, std::string const& reason)
    {
        if (!tank)
            return;
        std::lock_guard<std::mutex> lock(gMtx);
        auto it = gActive.find(tank->GetGUID());
        if (it != gActive.end())
            FinishLocked(it, reason);
    }

    void RegisterScripts()
    {
        new DcPlayerRunsDeathScript();
    }

    void SendList(Player* player, Send const& send)
    {
        if (!player || !player->GetSession())
            return;
        uint32 const owner = player->GetGUID().GetCounter();
        std::vector<Run> rows;
        {
            std::lock_guard<std::mutex> lock(gMtx);
            for (auto const& kv : gActive)
                if (Sees(kv.second, owner))      // DCRUN1B: viewers too
                    rows.push_back(kv.second);
            auto it = gDone.find(owner);
            if (it != gDone.end())
                rows.insert(rows.end(), it->second.begin(), it->second.end());
        }
        LocaleConstant const loc = player->GetSession()->GetSessionDbcLocale();
        time_t const now = time(nullptr);
        send("DC\tMR_START");
        for (Run const& r : rows)
        {
            std::string name = "?";
            if (MapEntry const* m = sMapStore.LookupEntry(r.map))
                name = (m->name[loc] && *m->name[loc]) ? m->name[loc] : (m->name[0] ? m->name[0] : "?");
            send(Acore::StringFormat("DC\tMR\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", r.id, r.map,
                                     r.heroic ? 1 : 0, static_cast<uint64>(r.start),
                                     static_cast<uint64>((r.end ? r.end : now) - r.start), r.result, r.bosses.size(),
                                     r.total, r.deaths.size(), r.tier, TokenFor(r.map), Clean(name)));
        }
        send("DC\tMR_END");
    }

    void SendDetail(Player* player, std::string const& id, Send const& send)
    {
        if (!player)
            return;
        Run copy;
        {
            std::lock_guard<std::mutex> lock(gMtx);
            Run const* r = FindLocked(player->GetGUID().GetCounter(), id);
            if (!r)
            {
                send("DC\tMRX_END\t" + Clean(id));
                return;
            }
            copy = *r;
        }
        std::string const cid = Clean(id);
        send(Acore::StringFormat("DC\tMRX\t{}\tR\t{}", cid, Clean(copy.reason)));
        send(Acore::StringFormat("DC\tMRX\t{}\tS\t{}", cid, copy.restarts));
        for (Member const& m : copy.members)
            send(Acore::StringFormat("DC\tMRX\t{}\tM\t{}\t{}\t{}\t{}", cid, Clean(m.name), m.cls, m.level,
                                     std::string(1, m.kind)));
        for (RunEvent const& e : copy.bosses)
            send(Acore::StringFormat("DC\tMRX\t{}\tB\t{}\t{}", cid, e.t, Clean(e.name)));
        for (RunEvent const& e : copy.deaths)
            send(Acore::StringFormat("DC\tMRX\t{}\tD\t{}\t{}", cid, e.t, Clean(e.name)));
        send("DC\tMRX_END\t" + cid);
    }

    void Delete(Player* player, std::string const& id)
    {
        if (!player)
            return;
        std::lock_guard<std::mutex> lock(gMtx);
        auto it = gDone.find(player->GetGUID().GetCounter());
        if (it == gDone.end())
            return;
        if (id == "all")
        {
            it->second.clear();
            return;
        }
        for (auto r = it->second.begin(); r != it->second.end(); ++r)
            if (r->id == id)
            {
                it->second.erase(r);
                return;
            }
    }
}
