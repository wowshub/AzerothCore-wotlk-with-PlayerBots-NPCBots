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
#include "TestRun/DcDeathLog.h"
#include "TestRun/DcPrepSnapshot.h"
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
        // DCSTAT2A: a member's death, from DcDeathLog (empty for a boss kill or an NPCBot)
        std::string killer, spell;
        uint32 amount = 0, overkill = 0, dmg5 = 0, heal5 = 0;
    };

    struct Member
    {
        std::string name;
        uint32 cls = 0, level = 0;
        char kind = 'p';       // a = your account, b = playerbot, n = NPCBot, p = real player
        uint32 ilvl = 0;       // DCSTAT2A: average equipped item level at the start (0 = unknown)
        std::string role;      // DCSTAT2A: tank | heal | dps ("" = unknown)
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
        // DCSTAT2A: damage the party took by source+spell and healing done by healer (merged over restarts)
        std::vector<DcDeathLog::SourceTotal> taken;
        std::vector<DcDeathLog::HealerTotal> healers;
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

    // DCSTAT2A: fold a finished stretch's totals into the run's (a restarted run keeps its earlier ones)
    void MergeTotals(Run& r, std::vector<DcDeathLog::SourceTotal> const& src,
                     std::vector<DcDeathLog::HealerTotal> const& heal)
    {
        for (DcDeathLog::SourceTotal const& t : src)
        {
            auto it = std::find_if(r.taken.begin(), r.taken.end(), [&](DcDeathLog::SourceTotal const& x)
                                   { return x.src == t.src && x.spell == t.spell; });
            if (it == r.taken.end())
                r.taken.push_back(t);
            else
            {
                it->total += t.total;
                it->hits += t.hits;
            }
        }
        for (DcDeathLog::HealerTotal const& t : heal)
        {
            auto it = std::find_if(r.healers.begin(), r.healers.end(),
                                   [&](DcDeathLog::HealerTotal const& x) { return x.name == t.name; });
            if (it == r.healers.end())
                r.healers.push_back(t);
            else
                it->total += t.total;
        }
        auto bySize = [](auto const& a, auto const& b) { return a.total > b.total; };
        std::sort(r.taken.begin(), r.taken.end(), bySize);
        std::sort(r.healers.begin(), r.healers.end(), bySize);
        if (r.taken.size() > 12)
            r.taken.resize(12);
        if (r.healers.size() > 8)
            r.healers.resize(8);
    }

    // DCSTAT2A: log every Player in the tank's group (playerbots and real players; NPCBots are creatures)
    void TrackMembers(Player* tank, std::string const& runId)
    {
        if (Group* g = tank->GetGroup())
        {
            for (GroupReference* r = g->GetFirstMember(); r; r = r->next())
                if (Player* p = r->GetSource())
                    DcDeathLog::Track(p->GetGUID(), runId);
        }
        else
            DcDeathLog::Track(tank->GetGUID(), runId);
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
            if (!v[i].killer.empty() || !v[i].spell.empty())  // DCSTAT2A
            {
                s << ",\"killer\":";
                Esc(s, v[i].killer);
                s << ",\"spell\":";
                Esc(s, v[i].spell);
                s << ",\"amount\":" << v[i].amount << ",\"overkill\":" << v[i].overkill << ",\"dmg5\":" << v[i].dmg5
                  << ",\"heal5\":" << v[i].heal5;
            }
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
        s << ",\"taken\":[";
        for (std::size_t i = 0; i < r.taken.size(); ++i)
        {
            s << (i ? "," : "") << "{\"src\":";
            Esc(s, r.taken[i].src);
            s << ",\"spell\":";
            Esc(s, r.taken[i].spell);
            s << ",\"total\":" << r.taken[i].total << ",\"hits\":" << r.taken[i].hits << '}';
        }
        s << "],\"healers\":[";
        for (std::size_t i = 0; i < r.healers.size(); ++i)
        {
            s << (i ? "," : "") << "{\"name\":";
            Esc(s, r.healers[i].name);
            s << ",\"total\":" << r.healers[i].total << '}';
        }
        s << ']';
        s << ",\"members\":[";
        for (std::size_t i = 0; i < r.members.size(); ++i)
        {
            if (i)
                s << ',';
            s << "{\"name\":";
            Esc(s, r.members[i].name);
            s << ",\"class\":" << r.members[i].cls << ",\"level\":" << r.members[i].level << ",\"kind\":\""
              << r.members[i].kind << "\",\"ilvl\":" << r.members[i].ilvl << ",\"role\":";
            Esc(s, r.members[i].role);
            s << '}';
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
        {   // DCSTAT2A: what this stretch of the run took and healed, then stop logging
            std::vector<DcDeathLog::SourceTotal> src;
            std::vector<DcDeathLog::HealerTotal> heal;
            std::uint64_t taken = 0;
            DcDeathLog::Totals(r.id, 12, 8, &src, &heal, &taken);
            MergeTotals(r, src, heal);
            DcDeathLog::Untrack(r.id);
        }
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
            DcPrep::Snapshot const prep = DcPrep::Capture(p, "");  // DCSTAT2A
            if (prep.valid)
            {
                m.ilvl = prep.avgIlvl;
                m.role = prep.role;
            }
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
                        DcPrep::Snapshot const prep = DcPrep::CaptureBot(bot);  // DCSTAT2B (DCPREP2A)
                        if (prep.valid)
                        {
                            m.ilvl = prep.avgIlvl;
                            m.role = prep.role;
                        }
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
            // DCSTAT2A: what killed a player (DcDeathLog keeps its own lock; taken before ours)
            DcDeathLog::Detail cause;
            if (!boss && unit->IsPlayer())
                cause = DcDeathLog::TakeDeath(unit->GetGUID());
            std::lock_guard<std::mutex> lock(gMtx);
            for (auto& kv : gActive)
            {
                Run& r = kv.second;
                if (r.instance != inst || r.map != map)
                    continue;
                std::vector<RunEvent>& list = boss ? r.bosses : r.deaths;
                if (list.size() < kMaxEvents)
                {
                    RunEvent e;
                    e.t = static_cast<uint32>(time(nullptr) - r.start);
                    e.name = unit->GetName();
                    if (cause.any)
                    {
                        e.killer = cause.killer;
                        e.spell = cause.killerSpell;
                        e.amount = cause.killerAmount;
                        e.overkill = cause.killerOverkill;
                        e.dmg5 = cause.dmg5s;
                        e.heal5 = cause.heal5s;
                    }
                    list.push_back(std::move(e));
                }
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
                TrackMembers(tank, it->second.id);  // DCSTAT2A: idempotent; picks up whoever joined
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
                TrackMembers(tank, r.id);        // DCSTAT2A: logging stopped when it ended
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
        TrackMembers(tank, r.id);                // DCSTAT2A
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
        if (copy.result == "running")  // DCSTAT2A: a live run shows what the log holds so far
        {
            std::vector<DcDeathLog::SourceTotal> src;
            std::vector<DcDeathLog::HealerTotal> heal;
            std::uint64_t taken = 0;
            DcDeathLog::Totals(copy.id, 12, 8, &src, &heal, &taken);
            MergeTotals(copy, src, heal);
        }
        std::string const cid = Clean(id);
        send(Acore::StringFormat("DC\tMRX\t{}\tR\t{}", cid, Clean(copy.reason)));
        send(Acore::StringFormat("DC\tMRX\t{}\tS\t{}", cid, copy.restarts));
        for (Member const& m : copy.members)
            send(Acore::StringFormat("DC\tMRX\t{}\tM\t{}\t{}\t{}\t{}", cid, Clean(m.name), m.cls, m.level,
                                     std::string(1, m.kind)));
        for (Member const& m : copy.members)  // DCSTAT2A: item level and role per member
            if (m.ilvl > 0 || !m.role.empty())
                send(Acore::StringFormat("DC\tMRX\t{}\tI\t{}\t{}\t{}", cid, Clean(m.name), m.ilvl, Clean(m.role)));
        for (RunEvent const& e : copy.bosses)
            send(Acore::StringFormat("DC\tMRX\t{}\tB\t{}\t{}", cid, e.t, Clean(e.name)));
        for (RunEvent const& e : copy.deaths)
        {
            send(Acore::StringFormat("DC\tMRX\t{}\tD\t{}\t{}", cid, e.t, Clean(e.name)));
            if (!e.killer.empty() || !e.spell.empty())  // DCSTAT2A: follows its D line
                send(Acore::StringFormat("DC\tMRX\t{}\tK\t{}\t{}\t{}\t{}\t{}\t{}\t{}", cid, Clean(e.killer),
                                         Clean(e.spell), e.amount, e.overkill, e.dmg5, e.heal5, e.t));
        }
        for (DcDeathLog::SourceTotal const& t : copy.taken)  // DCSTAT2A
            send(Acore::StringFormat("DC\tMRX\t{}\tT\t{}\t{}\t{}\t{}", cid, Clean(t.src), Clean(t.spell),
                                     static_cast<uint64>(t.total), t.hits));
        for (DcDeathLog::HealerTotal const& t : copy.healers)
            send(Acore::StringFormat("DC\tMRX\t{}\tH\t{}\t{}", cid, Clean(t.name), static_cast<uint64>(t.total)));
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
