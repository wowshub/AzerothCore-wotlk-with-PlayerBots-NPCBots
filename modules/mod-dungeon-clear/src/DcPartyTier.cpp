/*
 * mod-dungeon-clear — DcPartyTier.cpp  (RebornWOW DCGM1F)  See DcPartyTier.h.
 */

#include "DcPartyTier.h"

#include "Creature.h"
#include "Group.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "botmgr.h"
#include "TestRun/DcTestRunManager.h"

#include <atomic>
#include <mutex>
#include <set>
#include <unordered_map>
#include <unordered_set>

namespace
{
    struct LeaderState
    {
        std::string tier;                 // never "normal": a normal tier erases the entry
        std::set<ObjectGuid> playerBots;  // playerbots the tier was put on
        std::set<ObjectGuid> npcBots;     // NPCBots the tier was put on
    };

    std::unordered_map<ObjectGuid, LeaderState> g_leaders;  // world thread

    std::mutex g_godMutex;                                  // read from map threads
    std::unordered_set<ObjectGuid> g_npcGod;
    std::atomic<bool> g_npcGodAny{false};

    uint32 g_tickMs = 0;

    uint32 DamagePct(std::string const& tier)
    {
        return tier == "casual" ? 50u : tier == "speed" ? 1000u : 0u;  // 0 = unscaled
    }

    bool IsOwnPlayerbot(Player* p, Player* leader)
    {
        if (!p || p == leader)
            return false;
        PlayerbotAI* ai = GET_PLAYERBOT_AI(p);
        return ai && !ai->IsRealPlayer();
    }

    void SetNpcGod(ObjectGuid guid, bool on)
    {
        std::lock_guard<std::mutex> lock(g_godMutex);
        if (on)
            g_npcGod.insert(guid);
        else
            g_npcGod.erase(guid);
        g_npcGodAny.store(!g_npcGod.empty(), std::memory_order_relaxed);
    }

    void ClearPlayerbot(ObjectGuid guid)
    {
        if (Player* p = ObjectAccessor::FindConnectedPlayer(guid))
        {
            p->SetCommandStatusOff(CHEAT_GOD);
            p->SetCommandStatusOff(CHEAT_POWER);
            p->SetCommandStatusOff(CHEAT_COOLDOWN);
            p->SetCommandStatusOff(CHEAT_CASTTIME);
        }
        DcTestRunManager::SetCheatDamagePct(guid, 0);
    }

    void PutOnPlayerbot(Player* p, std::string const& tier)
    {
        p->SetCommandStatusOff(CHEAT_COOLDOWN);
        p->SetCommandStatusOff(CHEAT_CASTTIME);
        p->SetCommandStatusOn(CHEAT_GOD);
        p->SetCommandStatusOn(CHEAT_POWER);
        if (tier == "speed")
        {
            p->SetCommandStatusOn(CHEAT_COOLDOWN);
            p->SetCommandStatusOn(CHEAT_CASTTIME);
        }
        p->SetPower(p->getPowerType(), p->GetMaxPower(p->getPowerType()));
        DcTestRunManager::SetCheatDamagePct(p->GetGUID(), DamagePct(tier));
    }

    void ClearNpcBot(ObjectGuid guid)
    {
        SetNpcGod(guid, false);
        DcTestRunManager::SetCheatDamagePct(guid, 0);
    }

    void PutOnNpcBot(Creature* bot, std::string const& tier)
    {
        SetNpcGod(bot->GetGUID(), true);
        if (bot->getPowerType() == POWER_MANA)
            bot->SetPower(POWER_MANA, bot->GetMaxPower(POWER_MANA));
        DcTestRunManager::SetCheatDamagePct(bot->GetGUID(), DamagePct(tier));
    }

    void ClearAll(LeaderState& st)
    {
        for (ObjectGuid const& g : st.playerBots)
            ClearPlayerbot(g);
        for (ObjectGuid const& g : st.npcBots)
            ClearNpcBot(g);
        st.playerBots.clear();
        st.npcBots.clear();
    }

    // The leader's current playerbots (same group) and NPCBots (its BotMgr).
    void Current(Player* leader, std::vector<Player*>& pbots, std::vector<Creature*>& nbots)
    {
        if (Group* group = leader->GetGroup())
        {
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            {
                Player* m = ref->GetSource();
                // in the group even mid-teleport (not in world): a map change is not leaving
                if (m && IsOwnPlayerbot(m, leader))
                    pbots.push_back(m);
            }
        }
        if (BotMgr* mgr = leader->GetBotMgr())
        {
            for (auto const& kv : *mgr->GetBotMap())
            {
                Creature* bot = kv.second;
                if (bot)
                    nbots.push_back(bot);
            }
        }
    }

    // Bring one leader's state in line with its party: newcomers get the tier,
    // leavers lose it. Returns the names covered.
    std::vector<std::string> Sync(Player* leader, LeaderState& st)
    {
        std::vector<Player*> pbots;
        std::vector<Creature*> nbots;
        Current(leader, pbots, nbots);
        std::vector<std::string> names;

        std::set<ObjectGuid> nowP;
        for (Player* p : pbots)
        {
            nowP.insert(p->GetGUID());
            if (!st.playerBots.count(p->GetGUID()))
                PutOnPlayerbot(p, st.tier);
            names.push_back(p->GetName());
        }
        for (ObjectGuid const& g : st.playerBots)
            if (!nowP.count(g))
            {
                ClearPlayerbot(g);
                LOG_INFO("playerbots.dungeonclear", "DCGM1F party tier {} of {}: bot {} left the party, tier removed",
                         st.tier, leader->GetName(), g.ToString());
            }
        st.playerBots = std::move(nowP);

        std::set<ObjectGuid> nowN;
        for (Creature* b : nbots)
        {
            nowN.insert(b->GetGUID());
            if (!st.npcBots.count(b->GetGUID()))
                PutOnNpcBot(b, st.tier);
            else if (b->IsAlive() && b->getPowerType() == POWER_MANA)
                b->SetPower(POWER_MANA, b->GetMaxPower(POWER_MANA));  // unlimited power
            names.push_back(b->GetName());
        }
        for (ObjectGuid const& g : st.npcBots)
            if (!nowN.count(g))
                ClearNpcBot(g);
        st.npcBots = std::move(nowN);
        return names;
    }
}

namespace DcPartyTier
{
    std::vector<std::string> Apply(Player* leader, std::string const& tier)
    {
        std::vector<std::string> names;
        if (!leader)
            return names;
        ObjectGuid const key = leader->GetGUID();
        auto it = g_leaders.find(key);
        std::string const from = it == g_leaders.end() ? std::string("normal") : it->second.tier;
        if (it != g_leaders.end())
        {
            ClearAll(it->second);
            g_leaders.erase(it);
        }
        if (tier != "normal")
        {
            LeaderState& st = g_leaders[key];
            st.tier = tier;
            names = Sync(leader, st);
        }
        else
        {
            std::vector<Player*> pbots;
            std::vector<Creature*> nbots;
            Current(leader, pbots, nbots);
            for (Player* p : pbots)
                names.push_back(p->GetName());
            for (Creature* b : nbots)
                names.push_back(b->GetName());
        }
        LOG_INFO("playerbots.dungeonclear", "DCGM1F party tier {} -> {} by {} ({} bot(s)) tier={}", from, tier,
                 leader->GetName(), names.size(), tier);
        return names;
    }

    std::string TierFor(Player* player)
    {
        if (!player)
            return "normal";
        auto own = g_leaders.find(player->GetGUID());
        if (own != g_leaders.end())
            return own->second.tier;
        if (Group* group = player->GetGroup())
        {
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            {
                Player* m = ref->GetSource();
                if (!m)
                    continue;
                auto it = g_leaders.find(m->GetGUID());
                if (it != g_leaders.end())
                    return it->second.tier;
            }
        }
        // An NPCBot's owner, or a bot owned by a leader: the leader's tier.
        return "normal";
    }

    bool IsNpcBotGod(ObjectGuid guid)
    {
        if (!g_npcGodAny.load(std::memory_order_relaxed))
            return false;
        std::lock_guard<std::mutex> lock(g_godMutex);
        return g_npcGod.count(guid) != 0;
    }

    void Tick(uint32 diff)
    {
        if (g_leaders.empty())
            return;
        g_tickMs += diff;
        if (g_tickMs < 1000)
            return;
        g_tickMs = 0;
        for (auto it = g_leaders.begin(); it != g_leaders.end();)
        {
            Player* leader = ObjectAccessor::FindConnectedPlayer(it->first);
            if (!leader)  // logged out (a teleport keeps the session: still connected)
            {
                LOG_INFO("playerbots.dungeonclear", "DCGM1F party tier {}: leader {} gone, tier removed",
                         it->second.tier, it->first.ToString());
                ClearAll(it->second);
                it = g_leaders.erase(it);
                continue;
            }
            if (leader->IsInWorld())  // mid-teleport: leave everything as it is
                Sync(leader, it->second);
            ++it;
        }
    }
}
