/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "DcTestRunRecord.h"

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <mutex>
#include <sstream>

namespace DcTestRunRecord
{
    namespace
    {
        void AppendEscaped(std::ostringstream& s, std::string_view v)
        {
            s << '"' << EscapeJson(v) << '"';
        }

        // RebornWOW DCBOSS1A: ,"damageTakenTotal":N,"damageTaken":[...],"healDone":[...]
        std::string DamageJson(Record const& rec)
        {
            std::ostringstream s;
            s << ",\"damageTakenTotal\":" << rec.damageTakenTotal << ",\"damageTaken\":[";
            for (std::size_t i = 0; i < rec.damageTaken.size(); ++i)
            {
                DamageSource const& d = rec.damageTaken[i];
                if (i)
                    s << ',';
                s << "{\"src\":";
                AppendEscaped(s, d.src);
                s << ",\"spell\":";
                AppendEscaped(s, d.spell);
                s << ",\"spellId\":" << d.spellId << ",\"total\":" << d.total << ",\"hits\":" << d.hits << '}';
            }
            s << "],\"healDone\":[";
            for (std::size_t i = 0; i < rec.healDone.size(); ++i)
            {
                if (i)
                    s << ',';
                s << "{\"name\":";
                AppendEscaped(s, rec.healDone[i].name);
                s << ",\"total\":" << rec.healDone[i].total << '}';
            }
            s << "],\"healerStats\":[";  // RebornWOW DCBOSS1B
            for (std::size_t i = 0; i < rec.healerStats.size(); ++i)
            {
                HealerStat const& h = rec.healerStats[i];
                if (i)
                    s << ',';
                s << "{\"name\":";
                AppendEscaped(s, h.name);
                s << ",\"combatS\":" << h.combatS << ",\"movingS\":" << h.movingS << ",\"castingS\":" << h.castingS
                  << ",\"lowAllyS\":" << h.lowAllyS << ",\"lowAllyMovingS\":" << h.lowAllyMovingS
                  << ",\"lowAllyIdleS\":" << h.lowAllyIdleS << ",\"minManaPct\":" << h.minManaPct
                  << ",\"castChecks\":{";
                bool firstKey = true;  // RebornWOW DCBOSS1C
                for (auto const& kv : h.castChecks)
                {
                    if (!firstKey)
                        s << ',';
                    firstKey = false;
                    s << '"' << EscapeJson(kv.first) << "\":" << kv.second;
                }
                s << "}}";
            }
            s << ']';
            return s.str();
        }

        // RebornWOW DCWD1A: ,"spellTotals":[...],"spellRows":[...]
        std::string SpellLedgerJson(Record const& rec)
        {
            std::ostringstream s;
            s << ",\"spellTotals\":[";
            for (std::size_t i = 0; i < rec.spellTotals.size(); ++i)
            {
                SpellOwnerTotals const& t = rec.spellTotals[i];
                if (i)
                    s << ',';
                s << "{\"owner\":";
                AppendEscaped(s, t.owner);
                s << ",\"damageAll\":" << t.damageAll << ",\"overkillAll\":" << t.overkillAll
                  << ",\"healAll\":" << t.healAll << ",\"damageUnattributed\":" << t.damageUnattributed
                  << ",\"healUnattributed\":" << t.healUnattributed << '}';
            }
            s << "],\"spellRows\":[";
            for (std::size_t i = 0; i < rec.spellRows.size(); ++i)
            {
                SpellRow const& r = rec.spellRows[i];
                if (i)
                    s << ',';
                s << "{\"owner\":";
                AppendEscaped(s, r.owner);
                s << ",\"sourceEntry\":" << r.sourceEntry << ",\"source\":";
                AppendEscaped(s, r.source);
                s << ",\"spellId\":" << r.spellId << ",\"spell\":";
                AppendEscaped(s, r.spell);
                s << ",\"started\":" << r.started << ",\"succeeded\":" << r.succeeded << ",\"cancelled\":" << r.cancelled
                  << ",\"triggered\":" << r.triggered << ",\"hits\":" << r.hits << ",\"heals\":" << r.heals
                  << ",\"damage\":" << r.damage << ",\"overkill\":" << r.overkill << ",\"healSelf\":" << r.healSelf
                  << ",\"healOther\":" << r.healOther << '}';
            }
            s << ']';
            return s.str();
        }

        void AppendStatus(std::ostringstream& s, StatusEntry const& e)
        {
            s << "{\"t\":" << e.t << ",\"state\":";
            AppendEscaped(s, e.state);
            s << ",\"detail\":";
            AppendEscaped(s, e.detail);
            s << '}';
        }
    }

    bool IsJsonNumber(std::string_view v)
    {
        // -?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?
        std::size_t i = 0, n = v.size();
        auto digit = [&](std::size_t k) { return k < n && v[k] >= '0' && v[k] <= '9'; };
        if (i < n && v[i] == '-')
            ++i;
        if (!digit(i))
            return false;
        if (v[i] == '0')
            ++i;
        else
            while (digit(i))
                ++i;
        if (i < n && v[i] == '.')
        {
            ++i;
            if (!digit(i))
                return false;
            while (digit(i))
                ++i;
        }
        if (i < n && (v[i] == 'e' || v[i] == 'E'))
        {
            ++i;
            if (i < n && (v[i] == '+' || v[i] == '-'))
                ++i;
            if (!digit(i))
                return false;
            while (digit(i))
                ++i;
        }
        return i == n;
    }

    std::string EscapeJson(std::string_view s)
    {
        std::string out;
        out.reserve(s.size());
        for (unsigned char c : s)
        {
            switch (c)
            {
                case '"':  out += "\\\""; break;
                case '\\': out += "\\\\"; break;
                case '\n': out += "\\n";  break;
                case '\r': out += "\\r";  break;
                case '\t': out += "\\t";  break;
                default:
                    if (c < 0x20)
                    {
                        char buf[8];
                        std::snprintf(buf, sizeof(buf), "\\u%04x", c);
                        out += buf;
                    }
                    else
                        out += static_cast<char>(c);
                    break;
            }
        }
        return out;
    }

    std::string TierClass(Record const& rec)
    {
        if (rec.cheatTier.empty())
            return "normal";
        if (rec.cheatTier.find('>') != std::string::npos)
            return "mixed";
        return rec.cheatTier;
    }

    std::string ToJsonl(Record const& rec)
    {
        std::ostringstream s;
        s.precision(9);
        s << "{\"schema\":" << rec.schema
          << ",\"runId\":";
        AppendEscaped(s, rec.runId);
        s << ",\"planId\":";
        AppendEscaped(s, rec.planId);
        s << ",\"dungeon\":";
        AppendEscaped(s, rec.dungeon);
        s << ",\"dungeonName\":";
        AppendEscaped(s, rec.dungeonName);
        s << ",\"wing\":";
        AppendEscaped(s, rec.wing);
        s << ",\"mapId\":" << rec.mapId
          << ",\"instanceId\":" << rec.instanceId
          << ",\"level\":" << rec.level
          << ",\"heroic\":" << (rec.heroic ? "true" : "false")
          << ",\"size\":" << rec.size
          << ",\"compSeed\":" << rec.compSeed
          << ",\"gearIlvl\":" << rec.gearIlvl
          << ",\"gearQuality\":" << rec.gearQuality
          << ",\"roster\":" << (rec.roster ? "true" : "false")
          << ",\"comp\":[";
        for (std::size_t i = 0; i < rec.comp.size(); ++i)
        {
            CompEntry const& c = rec.comp[i];
            if (i)
                s << ',';
            s << "{\"name\":";
            AppendEscaped(s, c.name);
            s << ",\"class\":";
            AppendEscaped(s, c.className);
            s << ",\"spec\":";
            AppendEscaped(s, c.spec);
            s << ",\"role\":";
            AppendEscaped(s, c.role);
            s << ",\"guid\":" << c.guid
              << ",\"level\":" << c.level
              << ",\"detectedRole\":";
            AppendEscaped(s, c.detectedRole);
            s << ",\"roleMismatch\":" << (c.roleMismatch ? "true" : "false")
              << ",\"talents\":";
            AppendEscaped(s, c.talents);  // RebornWOW DCP1C
            s << ",\"fp\":";
            AppendEscaped(s, c.fingerprint);
            s << ",\"glyphs\":";
            AppendEscaped(s, c.glyphs);
            s << ",\"avgIlvl\":" << c.avgIlvl << ",\"gear\":[";
            for (std::size_t k = 0; k < c.gear.size(); ++k)
                s << (k ? "," : "") << '[' << c.gear[k].slot << ',' << c.gear[k].entry << ',' << c.gear[k].ilvl << ','
                  << c.gear[k].enchant << ']';
            s << ']'
              << ",\"prep\":" << DcPrep::ToJson(c.prep)  // RebornWOW DCPREP1A
              << ",\"from\":{\"map\":" << c.fromMap
              << ",\"x\":" << c.fromX << ",\"y\":" << c.fromY << ",\"z\":" << c.fromZ
              << ",\"o\":" << c.fromO << "}}";
        }
        s << "],\"joined\":{\"name\":";
        AppendEscaped(s, rec.joinedName);  // RebornWOW DCPREP1A
        s << ",\"prep\":" << DcPrep::ToJson(rec.joinedPrep) << "}";
        s << ",\"startedAtMs\":" << rec.startedAtMs
          << ",\"endedAtMs\":" << rec.endedAtMs
          << ",\"durationS\":" << rec.durationS
          << ",\"result\":";
        AppendEscaped(s, rec.result);
        s << ",\"failReason\":";
        AppendEscaped(s, rec.failReason);
        s << ",\"disableReason\":";
        AppendEscaped(s, rec.disableReason);
        s << ",\"bossesTotal\":" << rec.bossesTotal
          << ",\"bossesKilled\":" << rec.bossesKilled
          << ",\"bossRoster\":[";
        for (std::size_t i = 0; i < rec.bossRoster.size(); ++i)
        {
            if (i)
                s << ',';
            AppendEscaped(s, rec.bossRoster[i]);
        }
        s << "],\"bossTimeline\":[";
        for (std::size_t i = 0; i < rec.bossTimeline.size(); ++i)
        {
            BossKill const& b = rec.bossTimeline[i];
            if (i)
                s << ',';
            s << "{\"t\":" << b.t << ",\"entry\":" << b.entry << ",\"name\":";
            AppendEscaped(s, b.name);
            s << ",\"via\":";
            AppendEscaped(s, b.via);
            s << '}';
        }
        s << "],\"deaths\":[";
        for (std::size_t i = 0; i < rec.deaths.size(); ++i)
        {
            DeathEntry const& d = rec.deaths[i];
            if (i)
                s << ',';
            s << "{\"t\":" << d.t << ",\"name\":";
            AppendEscaped(s, d.name);
            s << ",\"opponent\":";
            AppendEscaped(s, d.opponent);
            s << ",\"opponentEntry\":" << d.opponentEntry
              << ",\"onBoss\":" << (d.onBoss ? "true" : "false");
            // RebornWOW DCBOSS1A
            s << ",\"killer\":";
            AppendEscaped(s, d.killer);
            s << ",\"killerSpell\":";
            AppendEscaped(s, d.killerSpell);
            s << ",\"killerSpellId\":" << d.killerSpellId << ",\"killerAmount\":" << d.killerAmount
              << ",\"killerOverkill\":" << d.killerOverkill << ",\"killerHpPct\":" << d.killerHpPct
              << ",\"killerBoss\":" << (d.killerBoss ? "true" : "false")
              << ",\"dmg5s\":" << d.dmg5s << ",\"dmg10s\":" << d.dmg10s
              << ",\"heal5s\":" << d.heal5s << ",\"heal10s\":" << d.heal10s << ",\"topSrc\":";
            AppendEscaped(s, d.topSrc);
            s << ",\"topSpell\":";
            AppendEscaped(s, d.topSpell);
            s << ",\"topAmount\":" << d.topAmount << ",\"role\":";
            AppendEscaped(s, d.role);
            s << ",\"pos\":[" << d.x << ',' << d.y << ',' << d.z << "],\"lastHits\":[";
            for (std::size_t k = 0; k < d.lastHits.size(); ++k)
            {
                if (k)
                    s << ',';
                s << "{\"ageMs\":" << d.lastHits[k].ageMs << ",\"src\":";
                AppendEscaped(s, d.lastHits[k].src);
                s << ",\"spell\":";
                AppendEscaped(s, d.lastHits[k].spell);
                s << ",\"amount\":" << d.lastHits[k].amount << '}';
            }
            s << "],\"healers\":";
            AppendEscaped(s, d.healers);  // RebornWOW DCBOSS1B
            s << '}';
        }
        s << "],\"pulls\":[";
        for (std::size_t i = 0; i < rec.pulls.size(); ++i)
        {
            PullEntry const& p = rec.pulls[i];
            if (i)
                s << ',';
            s << "{\"t\":" << p.t
              << ",\"entry\":" << p.targetEntry
              << ",\"predicted\":" << p.predictedCount
              << ",\"predictedThirds\":" << p.predictedThirds
              << ",\"ceilingThirds\":" << p.ceilingThirds
              << ",\"observed\":" << p.observedMax
              << ",\"observedElites\":" << p.observedElites
              << ",\"advanced\":" << (p.advanced ? "true" : "false")
              << ",\"wipedHere\":" << (p.wipedHere ? "true" : "false") << '}';
        }
        s << "],\"pullsElided\":" << rec.pullsElided
          << ",\"testRegroups\":" << rec.testRegroups
          << ",\"testRegroupLog\":[";
        for (std::size_t i = 0; i < rec.testRegroupLog.size(); ++i)
            s << (i ? "," : "") << "{\"t\":" << rec.testRegroupLog[i].t
              << ",\"why\":\"" << rec.testRegroupLog[i].why << "\"}";
        s << "],\"cheatTier\":\"" << rec.cheatTier << '"'
          << ",\"tierClass\":\"" << TierClass(rec) << '"'  // RebornWOW DCGM1B3
          << ",\"gm\":\"" << EscapeJson(rec.gmName) << '"'  // RebornWOW DCTEST10A
          << DamageJson(rec)  // RebornWOW DCBOSS1A
          << SpellLedgerJson(rec)  // RebornWOW DCWD1A
          << ",\"clean\":" << (rec.cheatTier.empty() && rec.cheats.empty() ? "true" : "false")
          << ",\"cheats\":[";
        for (std::size_t i = 0; i < rec.cheats.size(); ++i)
            s << (i ? "," : "") << "{\"t\":" << rec.cheats[i].t
              << ",\"who\":\"" << rec.cheats[i].who
              << "\",\"what\":\"" << rec.cheats[i].what << "\"}";
        s << "]"
          << ",\"statusTimeline\":[";
        {
            std::vector<StatusEntry> const& st = rec.statusTimeline;
            bool first = true;
            if (st.size() <= kStatusHead + kStatusTail)
            {
                for (StatusEntry const& e : st)
                {
                    if (!first)
                        s << ',';
                    first = false;
                    AppendStatus(s, e);
                }
            }
            else
            {
                for (std::size_t i = 0; i < kStatusHead; ++i)
                {
                    if (!first)
                        s << ',';
                    first = false;
                    AppendStatus(s, st[i]);
                }
                s << ",{\"t\":" << st[kStatusHead].t << ",\"state\":\"...\",\"detail\":\""
                  << (st.size() - kStatusHead - kStatusTail) << " transitions elided\"}";
                for (std::size_t i = st.size() - kStatusTail; i < st.size(); ++i)
                {
                    s << ',';
                    AppendStatus(s, st[i]);
                }
            }
        }
        s << "],\"pauses\":[";
        for (std::size_t i = 0; i < rec.pauses.size(); ++i)
        {
            if (i)
                s << ',';
            s << "{\"t\":" << rec.pauses[i].t << ",\"reason\":";
            AppendEscaped(s, rec.pauses[i].reason);
            s << '}';
        }
        s << "],\"finalTankPos\":{\"map\":" << rec.finalMap
          << ",\"x\":" << rec.finalX << ",\"y\":" << rec.finalY << ",\"z\":" << rec.finalZ
          << "},\"watchdog\":{\"pauseGraceS\":" << rec.pauseGraceS
          << ",\"stallGraceS\":" << rec.stallGraceS
          << ",\"noProgressS\":" << rec.noProgressS
          << ",\"overallS\":" << rec.overallS
          << "},\"setupStage\":";
        AppendEscaped(s, rec.setupStage);
        s << ",\"stallAtEnd\":";
        AppendEscaped(s, rec.stallAtEnd);
        s << ",\"phaseAtEnd\":";
        AppendEscaped(s, rec.phaseAtEnd);
        if (!rec.traceFile.empty())
        {
            s << ",\"traceFile\":";
            AppendEscaped(s, rec.traceFile);
            s << ",\"oracles\":";
            AppendEscaped(s, rec.oracles);
        }
        s << ",\"wipeOnBoss\":" << (rec.wipeOnBoss ? "true" : "false")
          << ",\"wipeOpponentEntry\":" << rec.wipeOpponentEntry
          << ",\"wipeOpponent\":";
        AppendEscaped(s, rec.wipeOpponent);
        s << ",\"scenario\":";
        AppendEscaped(s, rec.scenario);
        s << ",\"scenarioOf\":";
        AppendEscaped(s, rec.scenarioOf);
        s << ",\"focus\":[";
        for (std::size_t i = 0; i < rec.focus.size(); ++i)
            s << (i ? "," : "") << rec.focus[i];
        s << "],\"successPredicate\":";
        AppendEscaped(s, rec.successPredicate);
        s << ",\"successBy\":";
        AppendEscaped(s, rec.successBy);
        s << ",\"tailPending\":" << (rec.tailPending ? "true" : "false")
          << ",\"extras\":{";
        for (std::size_t i = 0; i < rec.extras.size(); ++i)
        {
            Record::Extra const& e = rec.extras[i];
            if (i)
                s << ',';
            AppendEscaped(s, e.key);
            s << ':';
            // A numeric extra is emitted bare only when it really is a JSON
            // number; anything else (a producer bug) degrades to a string rather
            // than corrupting the line.
            if (e.numeric && IsJsonNumber(e.value))
                s << e.value;
            else
                AppendEscaped(s, e.value);
        }
        s << '}';
        s << ",\"diag\":";
        DcDiag::AppendJson(s, rec.diag);
        s << '}';
        return s.str();
    }

    std::string CapturePath()
    {
        if (char const* env = std::getenv("DC_TESTRUNS_FILE"))
            if (env[0])
                return env;
        return "dc_testruns.jsonl";
    }

    std::string LivePath()
    {
        if (char const* env = std::getenv("DC_TESTRUN_LIVE_FILE"))
            if (env[0])
                return env;
        return "dc_testrun_live.json";
    }

    void Append(Record const& rec)
    {
        // One process-wide append stream; runs end minutes apart, so a mutex
        // plus flush-per-line is plenty (same shape as DungeonClearApproachIo).
        static std::mutex mtx;
        static std::ofstream file;
        static bool opened = false;

        std::lock_guard<std::mutex> lock(mtx);
        if (!opened)
        {
            file.open(CapturePath(), std::ios::out | std::ios::app);
            opened = true;
        }
        if (!file.is_open())
            return;

        file << ToJsonl(rec) << '\n';
        file.flush();
    }
}
