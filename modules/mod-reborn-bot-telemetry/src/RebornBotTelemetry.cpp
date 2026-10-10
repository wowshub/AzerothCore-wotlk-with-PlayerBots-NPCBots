/*
 * RebornWOW mod-reborn-bot-telemetry (DC line P1).
 *
 * One JSON line per group fight in a dungeon, appended to BotTelemetry.File
 * (default dc_fights.jsonl next to worldserver.exe): who was in the party
 * (class / spec tab / role / bot or human / item level), damage done, effective
 * healing done, damage taken, deaths, time spent under 50% and 25% health, the
 * boss if one was fought, and whether the party wiped.
 *
 * It is the per-fight half of the bot statistics; mod-dungeon-clear's
 * dc_testruns.jsonl is the per-run half. They join on mapId + instanceId + time
 * window + member guids (P2 aggregation script).
 *
 * Read-only towards other modules: it only calls the public static helpers
 * PlayerbotAI::IsTank/IsHeal and AiFactory::GetPlayerSpecTab, and changes no
 * playerbots or mod-dungeon-clear behaviour.
 *
 * DCDIAG1A: a fall recorder. Each sample keeps the last few positions of every
 * tracked player; when one ends up BotTelemetry.FallMinDrop yards or more below
 * a recent position, mostly straight down (not a ramp walk or a teleport), one
 * JSON line goes to BotTelemetry.FallFile (default dc_falls.jsonl) with the
 * trajectory, combat state, target and movement generator, to tell a bot
 * walking off a ledge from a knockback or a scripted pull.
 *
 * Threading: OnDamage/OnHeal/OnUnitDeath fire on map-update threads, so the
 * per-player counters are mutex-guarded. Fight boundaries are sampled in
 * WorldScript::OnUpdate, which runs on the world thread before the map update
 * pass, so reading player state there does not race the map threads.
 */

#include "AiFactory.h"
#include "Config.h"
#include "Creature.h"
#include "Group.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "Timer.h"
#include "UnitScript.h"
#include "WorldScript.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <fstream>
#include <mutex>
#include <shared_mutex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
    struct Config
    {
        bool enable = true;
        bool dungeonsOnly = true;
        bool botGroupsOnly = true;
        uint32 sampleMs = 500;
        uint32 endAfterMs = 4000;
        uint32 minFightMs = 5000;
        std::string file = "dc_fights.jsonl";
        bool fallLog = true;
        float fallMinDrop = 10.0f;
        std::string fallFile = "dc_falls.jsonl";
    } cfg;

    // Accumulated from the combat hooks (map threads), keyed by player guid.
    struct Counters
    {
        uint64 dmgDone = 0;
        uint64 dmgTaken = 0;
        uint64 healDone = 0;
        uint32 deaths = 0;
    };
    std::mutex countersLock;
    std::unordered_map<ObjectGuid::LowType, Counters> counters;

    // Sampled on the world thread, keyed by group guid.
    struct MemberSample
    {
        uint32 lowHpMs = 0;   // time under 50% health
        uint32 critHpMs = 0;  // time under 25% health
    };
    struct Fight
    {
        bool active = false;
        uint64 startUnixMs = 0;
        uint32 startMs = 0;
        uint32 lastCombatMs = 0;
        uint32 mapId = 0;
        uint32 instanceId = 0;
        uint32 difficulty = 0;
        uint32 bossEntry = 0;
        std::string bossName;
        std::unordered_map<ObjectGuid::LowType, MemberSample> members;
        std::unordered_set<ObjectGuid> enemies;
    };
    std::unordered_map<ObjectGuid::LowType, Fight> fights;
    uint32 sampleTimer = 0;

    // Fall recorder (world thread only): recent positions per player, oldest first.
    struct PosSample
    {
        uint32 ms = 0;
        float x = 0.0f, y = 0.0f, z = 0.0f;
    };
    struct Track
    {
        uint32 mapId = 0;
        uint32 instanceId = 0;
        std::vector<PosSample> recent;
        uint32 lastAirMs = 0;
    };
    std::unordered_map<ObjectGuid::LowType, Track> tracks;
    constexpr std::size_t TRACK_SAMPLES = 10;  // 5 s at the default 500 ms


    uint64 NowUnixMs()
    {
        return uint64(std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
    }

    std::string JsonEscape(std::string const& s)
    {
        std::string out;
        out.reserve(s.size() + 2);
        for (char c : s)
        {
            switch (c)
            {
                case '"': out += "\\\""; break;
                case '\\': out += "\\\\"; break;
                case '\n': out += "\\n"; break;
                case '\r': out += "\\r"; break;
                case '\t': out += "\\t"; break;
                default:
                    if (static_cast<unsigned char>(c) < 0x20)
                        out += ' ';
                    else
                        out += c;  // UTF-8 passes through unchanged
            }
        }
        return out;
    }

    // Pets, guardians and totems count for their owning player.
    Player* OwningPlayer(Unit* unit)
    {
        return unit ? unit->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    }

    bool Tracked(Player* player)
    {
        if (!cfg.enable || !player || !player->GetGroup())
            return false;
        if (cfg.dungeonsOnly)
        {
            Map* map = player->FindMap();
            if (!map || !map->IsDungeon())
                return false;
        }
        return true;
    }

    static char const* RoleName(bool tank, bool heal)
    {
        return tank ? "tank" : heal ? "heal" : "dps";
    }

    void EndFight(Fight& fight)
    {
        uint32 const durationMs = getMSTimeDiff(fight.startMs, fight.lastCombatMs);
        fight.active = false;

        std::vector<ObjectGuid::LowType> lows;
        for (auto const& entry : fight.members)
            lows.push_back(entry.first);

        // Snapshot and clear this fight's counters together, so the next fight
        // starts from zero. Events between fights are already filtered to
        // in-combat ones by the hooks, so nothing worth keeping is lost.
        std::unordered_map<ObjectGuid::LowType, Counters> taken;
        {
            std::lock_guard<std::mutex> guard(countersLock);
            for (ObjectGuid::LowType low : lows)
            {
                auto itr = counters.find(low);
                if (itr != counters.end())
                {
                    taken[low] = itr->second;
                    counters.erase(itr);
                }
            }
        }

        if (durationMs < cfg.minFightMs || lows.empty())
            return;

        std::ostringstream js;
        uint32 alive = 0;
        uint32 present = 0;
        js << "{\"schema\":2"
           << ",\"startedAtMs\":" << fight.startUnixMs
           << ",\"durationMs\":" << durationMs
           << ",\"mapId\":" << fight.mapId
           << ",\"instanceId\":" << fight.instanceId
           << ",\"difficulty\":" << fight.difficulty
           << ",\"bossEntry\":" << fight.bossEntry
           << ",\"bossName\":\"" << JsonEscape(fight.bossName) << "\""
           << ",\"enemies\":" << fight.enemies.size()
           << ",\"members\":[";
        bool first = true;
        for (ObjectGuid::LowType low : lows)
        {
            Player* player = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(low));
            if (!player)
                continue;
            ++present;
            if (player->IsAlive())
                ++alive;
            Counters const& c = taken[low];
            MemberSample const& s = fight.members[low];
            // Default (bySpec = false): bots answer from their strategies, real players from talents.
            bool const tank = PlayerbotAI::IsTank(player);
            bool const heal = PlayerbotAI::IsHeal(player);
            js << (first ? "" : ",")
               << "{\"guid\":" << low
               << ",\"name\":\"" << JsonEscape(player->GetName()) << "\""
               << ",\"class\":" << uint32(player->getClass())
               << ",\"race\":" << uint32(player->getRace())
               << ",\"level\":" << uint32(player->GetLevel())
               << ",\"specTab\":" << uint32(AiFactory::GetPlayerSpecTab(player))
               // role: what the bot is actually doing (its tank / heal strategies, as mod-dungeon-clear
               // sees it); real players fall back to talents. specRole: what the talents say. A fury
               // warrior tanking shows role tank / specRole dps; a hybrid healer has heal=true.
               << ",\"role\":\"" << RoleName(tank, heal) << "\""
               << ",\"specRole\":\"" << RoleName(PlayerbotAI::IsTank(player, true), PlayerbotAI::IsHeal(player, true)) << "\""
               << ",\"tank\":" << (tank ? "true" : "false")
               << ",\"heal\":" << (heal ? "true" : "false")
               << ",\"bot\":" << (GET_PLAYERBOT_AI(player) ? "true" : "false")
               << ",\"ilvl\":" << uint32(player->GetAverageItemLevel() + 0.5f)
               << ",\"dmgDone\":" << c.dmgDone
               << ",\"healDone\":" << c.healDone
               << ",\"dmgTaken\":" << c.dmgTaken
               << ",\"deaths\":" << c.deaths
               << ",\"lowHpMs\":" << s.lowHpMs
               << ",\"critHpMs\":" << s.critHpMs
               << "}";
            first = false;
        }
        js << "],\"wipe\":" << ((present > 0 && alive == 0) ? "true" : "false") << "}";

        if (present == 0)
            return;

        std::ofstream out(cfg.file, std::ios::app);
        if (out)
            out << js.str() << '\n';
        else
            LOG_ERROR("module", "BotTelemetry: cannot open {} for writing", cfg.file);
    }

    void RecordFall(Player* player, Track const& track, PosSample const& from, PosSample const& to, char const* kind)
    {
        Unit* victim = player->GetVictim();
        std::ostringstream js;
        js.setf(std::ios::fixed);
        js.precision(2);
        js << "{\"t\":" << NowUnixMs()
           << ",\"kind\":\"" << kind << "\""
           << ",\"guid\":" << player->GetGUID().GetCounter()
           << ",\"name\":\"" << JsonEscape(player->GetName()) << "\""
           << ",\"bot\":" << (GET_PLAYERBOT_AI(player) ? "true" : "false")
           << ",\"tank\":" << (PlayerbotAI::IsTank(player) ? "true" : "false")
           << ",\"map\":" << track.mapId
           << ",\"instance\":" << track.instanceId
           << ",\"from\":[" << from.x << "," << from.y << "," << from.z << "]"
           << ",\"to\":[" << to.x << "," << to.y << "," << to.z << "]"
           << ",\"drop\":" << (from.z - to.z)
           << ",\"overMs\":" << getMSTimeDiff(from.ms, to.ms)
           << ",\"alive\":" << (player->IsAlive() ? "true" : "false")
           << ",\"hpPct\":" << player->GetHealthPct()
           << ",\"combat\":" << (player->IsInCombat() ? "true" : "false")
           << ",\"falling\":" << (player->HasUnitMovementFlag(MOVEMENTFLAG_FALLING) ? "true" : "false")
           << ",\"motion\":" << uint32(player->GetMotionMaster()->GetCurrentMovementGeneratorType())
           << ",\"victimEntry\":" << (victim && victim->ToCreature() ? victim->GetEntry() : 0)
           << ",\"victim\":\"" << (victim ? JsonEscape(victim->GetName()) : std::string()) << "\""
           << ",\"path\":[";
        for (std::size_t i = 0; i < track.recent.size(); ++i)
        {
            PosSample const& p = track.recent[i];
            js << (i ? "," : "") << "[" << getMSTimeDiff(p.ms, to.ms) << "," << p.x << "," << p.y << "," << p.z << "]";
        }
        js << "]}";

        LOG_INFO("module", "BotTelemetry: {} {} map {} ({:.1f},{:.1f},{:.1f}) -> ({:.1f},{:.1f},{:.1f}) drop {:.1f} combat={}",
            kind, player->GetName(), track.mapId, from.x, from.y, from.z, to.x, to.y, to.z, from.z - to.z, player->IsInCombat());

        std::ofstream out(cfg.fallFile, std::ios::app);
        if (out)
            out << js.str() << '\n';
        else
            LOG_ERROR("module", "BotTelemetry: cannot open {} for writing", cfg.fallFile);
    }

    void TrackFall(Player* player, uint32 now)
    {
        Map* map = player->FindMap();
        if (!map)
            return;
        Track& track = tracks[player->GetGUID().GetCounter()];
        if (track.mapId != map->GetId() || track.instanceId != map->GetInstanceId())
        {
            track = Track();
            track.mapId = map->GetId();
            track.instanceId = map->GetInstanceId();
        }

        PosSample cur;
        cur.ms = now;
        cur.x = player->GetPositionX();
        cur.y = player->GetPositionY();
        cur.z = player->GetPositionZ();

        // Highest recent point this position dropped from steeply: a fall, not a ramp
        // (steeper than about 35 degrees) and not a teleport.
        PosSample const* from = nullptr;
        for (PosSample const& p : track.recent)
        {
            float const drop = p.z - cur.z;
            float const horiz = std::hypot(p.x - cur.x, p.y - cur.y);
            if (drop >= cfg.fallMinDrop && drop >= 0.7f * horiz && horiz < 60.0f && (!from || p.z > from->z))
                from = &p;
        }

        // DCDIAG1B: a staircase descends as steeply, but only ~2yd per sample. A real
        // drop has one sample-to-sample step of 4yd or more (free fall passes 8yd/s
        // within half a second).
        float maxStep = 0.0f;
        float prevZ = from ? from->z : cur.z;
        bool afterFrom = false;
        for (PosSample const& p : track.recent)
        {
            if (&p == from)
                afterFrom = true;
            else if (afterFrom)
            {
                maxStep = std::max(maxStep, prevZ - p.z);
                prevZ = p.z;
            }
        }
        maxStep = std::max(maxStep, prevZ - cur.z);

        if (from && maxStep >= 4.0f)
        {
            RecordFall(player, track, *from, cur, "fall");
            track.recent.clear();  // one line per fall
        }
        else if (Map* m = player->GetMap(); m && getMSTimeDiff(track.lastAirMs, now) >= 10000)
        {
            // DCDIAG1B: walking on air -- a straight spline over a gap (the event hop
            // DCMOV1A fixes) never "falls", it glides down at walking pace.
            float const ground = m->GetHeight(player->GetPhaseMask(), cur.x, cur.y, cur.z + 2.0f, true, 50.0f);
            if (ground > INVALID_HEIGHT && cur.z - ground > 6.0f && !player->IsFlying() &&
                !player->IsInWater() && !player->GetVehicle() && !player->HasUnitMovementFlag(MOVEMENTFLAG_FALLING))
            {
                PosSample below = cur;
                below.z = ground;
                RecordFall(player, track, cur, below, "air");
                track.lastAirMs = now;
            }
        }

        track.recent.push_back(cur);
        if (track.recent.size() > TRACK_SAMPLES)
            track.recent.erase(track.recent.begin());
    }

    void Sample()
    {
        uint32 const now = getMSTime();

        // Collect tracked groups: group guid -> members on the leader's dungeon map.
        struct GroupView
        {
            Map* map = nullptr;
            std::vector<Player*> members;
            bool hasBot = false;
        };
        std::unordered_map<ObjectGuid::LowType, GroupView> groups;
        {
            std::shared_lock<std::shared_mutex> lock(*HashMapHolder<Player>::GetLock());
            for (auto const& entry : ObjectAccessor::GetPlayers())
            {
                Player* player = entry.second;
                if (!player || !player->IsInWorld() || !Tracked(player))
                    continue;
                if (cfg.fallLog)
                    TrackFall(player, now);
                GroupView& view = groups[player->GetGroup()->GetGUID().GetCounter()];
                Map* map = player->FindMap();
                if (!view.map)
                    view.map = map;
                if (map != view.map)
                    continue;  // a member elsewhere is not part of this fight
                view.members.push_back(player);
                if (GET_PLAYERBOT_AI(player))
                    view.hasBot = true;
            }
        }

        std::unordered_set<ObjectGuid::LowType> seen;
        for (auto& entry : groups)
        {
            GroupView& view = entry.second;
            if (cfg.botGroupsOnly && !view.hasBot)
                continue;
            seen.insert(entry.first);
            Fight& fight = fights[entry.first];

            bool inCombat = false;
            for (Player* member : view.members)
                if (member->IsAlive() && member->IsInCombat())
                    inCombat = true;

            if (inCombat)
            {
                if (!fight.active)
                {
                    fight = Fight();
                    fight.active = true;
                    fight.startUnixMs = NowUnixMs();
                    fight.startMs = now;
                    fight.mapId = view.map->GetId();
                    fight.instanceId = view.map->GetInstanceId();
                    fight.difficulty = uint32(view.map->GetDifficulty());
                }
                fight.lastCombatMs = now;

                for (Player* member : view.members)
                {
                    MemberSample& s = fight.members[member->GetGUID().GetCounter()];
                    float const pct = member->GetHealthPct();
                    if (member->IsAlive() && pct < 50.0f)
                        s.lowHpMs += cfg.sampleMs;
                    if (member->IsAlive() && pct < 25.0f)
                        s.critHpMs += cfg.sampleMs;

                    Unit* victim = member->GetVictim();
                    if (Creature* creature = victim ? victim->ToCreature() : nullptr)
                    {
                        fight.enemies.insert(creature->GetGUID());
                        if (!fight.bossEntry && (creature->IsDungeonBoss() || creature->isWorldBoss()))
                        {
                            fight.bossEntry = creature->GetEntry();
                            fight.bossName = creature->GetName();
                        }
                    }
                }
            }
            else if (fight.active && getMSTimeDiff(fight.lastCombatMs, now) >= cfg.endAfterMs)
            {
                EndFight(fight);
            }
        }

        // Groups that vanished mid-fight (left the dungeon, disbanded): close them.
        for (auto& entry : fights)
            if (entry.second.active && !seen.count(entry.first) &&
                getMSTimeDiff(entry.second.lastCombatMs, now) >= cfg.endAfterMs)
                EndFight(entry.second);
    }

    void AddDamage(Unit* attacker, Unit* victim, uint32 damage)
    {
        if (!damage || !cfg.enable)
            return;
        Player* dealer = OwningPlayer(attacker);
        Player* target = victim ? victim->ToPlayer() : nullptr;
        bool const countDealer = dealer && Tracked(dealer) && attacker != victim && !(target && target == dealer);
        bool const countTarget = target && Tracked(target);
        if (!countDealer && !countTarget)
            return;
        std::lock_guard<std::mutex> guard(countersLock);
        if (countDealer)
            counters[dealer->GetGUID().GetCounter()].dmgDone += damage;
        if (countTarget)
            counters[target->GetGUID().GetCounter()].dmgTaken += damage;
    }

    void AddHeal(Unit* healer, Unit* receiver, uint32 gain)
    {
        if (!gain || !cfg.enable)
            return;
        Player* player = OwningPlayer(healer);
        if (!player || !Tracked(player))
            return;
        // Topping off between pulls is not fight healing.
        if (!player->IsInCombat() && !(receiver && receiver->IsInCombat()))
            return;
        std::lock_guard<std::mutex> guard(countersLock);
        counters[player->GetGUID().GetCounter()].healDone += gain;
    }
}

class RebornBotTelemetryUnitScript : public UnitScript
{
public:
    RebornBotTelemetryUnitScript() : UnitScript("RebornBotTelemetryUnitScript", true, {
        UNITHOOK_ON_DAMAGE,
        UNITHOOK_ON_HEAL,
        UNITHOOK_ON_UNIT_DEATH,
    }) { }

    void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
    {
        AddDamage(attacker, victim, damage);
    }

    // `gain` is the effective heal (overheal already removed by Unit::DealHeal).
    void OnHeal(Unit* healer, Unit* receiver, uint32& gain) override
    {
        AddHeal(healer, receiver, gain);
    }

    void OnUnitDeath(Unit* unit, Unit* /*killer*/) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || !Tracked(player))
            return;
        std::lock_guard<std::mutex> guard(countersLock);
        ++counters[player->GetGUID().GetCounter()].deaths;
    }
};

class RebornBotTelemetryWorldScript : public WorldScript
{
public:
    RebornBotTelemetryWorldScript() : WorldScript("RebornBotTelemetryWorldScript", {
        WORLDHOOK_ON_AFTER_CONFIG_LOAD,
        WORLDHOOK_ON_UPDATE,
    }) { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        cfg.enable = sConfigMgr->GetOption<bool>("BotTelemetry.Enable", true);
        cfg.dungeonsOnly = sConfigMgr->GetOption<bool>("BotTelemetry.DungeonsOnly", true);
        cfg.botGroupsOnly = sConfigMgr->GetOption<bool>("BotTelemetry.BotGroupsOnly", true);
        cfg.sampleMs = std::max<uint32>(100, sConfigMgr->GetOption<uint32>("BotTelemetry.SampleMs", 500));
        cfg.endAfterMs = sConfigMgr->GetOption<uint32>("BotTelemetry.EndAfterMs", 4000);
        cfg.minFightMs = sConfigMgr->GetOption<uint32>("BotTelemetry.MinFightMs", 5000);
        cfg.file = sConfigMgr->GetOption<std::string>("BotTelemetry.File", "dc_fights.jsonl");
        cfg.fallLog = sConfigMgr->GetOption<bool>("BotTelemetry.FallLog", true);
        cfg.fallMinDrop = std::max(3.0f, sConfigMgr->GetOption<float>("BotTelemetry.FallMinDrop", 10.0f));
        cfg.fallFile = sConfigMgr->GetOption<std::string>("BotTelemetry.FallFile", "dc_falls.jsonl");
        LOG_INFO("module", "BotTelemetry: {} (dungeonsOnly={}, botGroupsOnly={}, file={}, fallLog={}, fallFile={})",
            cfg.enable ? "enabled" : "disabled", cfg.dungeonsOnly, cfg.botGroupsOnly, cfg.file, cfg.fallLog, cfg.fallFile);
    }

    void OnUpdate(uint32 diff) override
    {
        if (!cfg.enable)
            return;
        sampleTimer += diff;
        if (sampleTimer < cfg.sampleMs)
            return;
        sampleTimer = 0;
        Sample();
    }
};

void AddSC_reborn_bot_telemetry()
{
    new RebornBotTelemetryUnitScript();
    new RebornBotTelemetryWorldScript();
}
