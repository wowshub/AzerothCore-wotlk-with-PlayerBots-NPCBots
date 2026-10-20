/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "TestRun/DcDeathLog.h"

#include <algorithm>
#include <atomic>
#include <deque>
#include <map>
#include <mutex>
#include <unordered_map>

#include "Creature.h"
#include "GameTime.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "UnitScript.h"

namespace DcDeathLog
{
    namespace
    {
        constexpr std::size_t kRingCap = 40;      // hits / heals kept per member
        constexpr std::size_t kKeyCap = 160;      // distinct source+spell rows kept per member
        constexpr std::uint32_t kPendingMs = 250; // a remembered spell is good for the next hit only

        struct HitRec
        {
            std::uint32_t ms = 0;
            std::string src;
            std::uint32_t spellId = 0;
            std::string spell;
            std::uint32_t amount = 0;
            std::uint32_t overkill = 0;
            int srcHpPct = -1;
            bool srcBoss = false;
        };

        struct HealRec
        {
            std::uint32_t ms = 0;
            std::uint32_t amount = 0;
        };

        struct Pending
        {
            bool set = false;
            ObjectGuid attacker;
            std::uint32_t ms = 0;
            std::uint32_t spellId = 0;
            std::string spell;
        };

        struct Victim
        {
            std::string runId;
            std::deque<HitRec> hits;
            std::deque<HealRec> heals;
            std::unordered_map<std::string, SourceTotal> dmg;
            std::unordered_map<std::string, std::uint64_t> healBy;
            Pending pending;
            std::uint64_t taken = 0;
        };

        std::mutex g_mu;
        std::unordered_map<ObjectGuid, Victim> g_victims;
        std::atomic<std::uint32_t> g_count{0};

        std::uint32_t NowMs()
        {
            return static_cast<std::uint32_t>(GameTime::GetGameTimeMS().count());
        }

        std::string SpellLabel(SpellInfo const* si)
        {
            if (!si)
                return "melee";
            char const* n = si->SpellName[0];
            return n && *n ? std::string(n) : std::string("spell ") + std::to_string(si->Id);
        }

        void Remember(Unit* target, Unit* attacker, SpellInfo const* si)
        {
            if (!g_count.load(std::memory_order_relaxed) || !target || !target->IsPlayer())
                return;
            std::lock_guard<std::mutex> lock(g_mu);
            auto it = g_victims.find(target->GetGUID());
            if (it == g_victims.end())
                return;
            Pending& p = it->second.pending;
            p.set = true;
            p.attacker = attacker ? attacker->GetGUID() : ObjectGuid::Empty;
            p.ms = NowMs();
            p.spellId = si ? si->Id : 0;
            p.spell = SpellLabel(si);
        }

        class DcDeathLogScript : public UnitScript
        {
        public:
            DcDeathLogScript()
                : UnitScript("DcDeathLogScript", true, {
                    UNITHOOK_ON_DAMAGE,
                    UNITHOOK_ON_HEAL,
                    UNITHOOK_MODIFY_MELEE_DAMAGE,
                    UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                    UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK
                }) {}

            void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& /*damage*/) override
            {
                Remember(target, attacker, nullptr);
            }

            void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& /*damage*/, SpellInfo const* spellInfo) override
            {
                Remember(target, attacker, spellInfo);
            }

            void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& /*damage*/, SpellInfo const* spellInfo) override
            {
                Remember(target, attacker, spellInfo);
            }

            void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
            {
                if (!damage || !victim || !g_count.load(std::memory_order_relaxed) || !victim->IsPlayer() || !victim->IsAlive())
                    return;
                // RebornWOW DCBOSS1B: this hook runs BEFORE the core's god-mode check, so an
                // invincible player's hits were counted (the damage totals were inflated)
                if (victim->ToPlayer()->GetCommandStatus(CHEAT_GOD))
                    return;
                // health is still the value before this hit
                std::uint32_t const hpBefore = victim->GetHealth();
                HitRec rec;
                rec.src = attacker ? attacker->GetName() : std::string("environment");
                rec.amount = damage;
                rec.overkill = damage > hpBefore ? damage - hpBefore : 0;
                if (attacker && attacker->IsCreature())
                {
                    rec.srcHpPct = static_cast<int>(attacker->GetHealthPct());
                    rec.srcBoss = attacker->ToCreature()->IsDungeonBoss();
                }
                ObjectGuid const from = attacker ? attacker->GetGUID() : ObjectGuid::Empty;

                std::lock_guard<std::mutex> lock(g_mu);
                auto it = g_victims.find(victim->GetGUID());
                if (it == g_victims.end())
                    return;
                Victim& v = it->second;
                rec.ms = NowMs();
                if (v.pending.set && v.pending.attacker == from && rec.ms - v.pending.ms <= kPendingMs)
                {
                    rec.spellId = v.pending.spellId;
                    rec.spell = v.pending.spell;
                }
                v.pending.set = false;

                v.hits.push_back(rec);
                if (v.hits.size() > kRingCap)
                    v.hits.pop_front();
                v.taken += damage;

                std::string key = rec.src + "|" + (rec.spell.empty() ? std::string("?") : rec.spell);
                auto row = v.dmg.find(key);
                if (row == v.dmg.end())
                {
                    bool const overflow = v.dmg.size() >= kKeyCap;
                    if (overflow)
                        key = "other|";
                    row = v.dmg.find(key);
                    if (row == v.dmg.end())
                    {
                        SourceTotal t;
                        t.src = overflow ? std::string("other") : rec.src;
                        t.spell = overflow ? std::string() : rec.spell;
                        t.spellId = overflow ? 0 : rec.spellId;
                        row = v.dmg.emplace(key, std::move(t)).first;
                    }
                }
                row->second.total += damage;
                row->second.hits += 1;
            }

            void OnHeal(Unit* healer, Unit* receiver, uint32& gain) override
            {
                if (!gain || !receiver || !g_count.load(std::memory_order_relaxed) || !receiver->IsPlayer())
                    return;
                std::string const who = healer ? healer->GetName() : std::string("unknown");
                std::lock_guard<std::mutex> lock(g_mu);
                auto it = g_victims.find(receiver->GetGUID());
                if (it == g_victims.end())
                    return;
                Victim& v = it->second;
                HealRec h;
                h.ms = NowMs();
                h.amount = gain;
                v.heals.push_back(h);
                if (v.heals.size() > kRingCap)
                    v.heals.pop_front();
                v.healBy[who] += gain;
            }
        };
    }

    void Track(ObjectGuid guid, std::string const& runId)
    {
        std::lock_guard<std::mutex> lock(g_mu);
        auto it = g_victims.find(guid);
        if (it != g_victims.end())
        {
            if (it->second.runId == runId)
                return;
            it->second = Victim();  // another run: start clean
            it->second.runId = runId;
            return;
        }
        Victim v;
        v.runId = runId;
        g_victims.emplace(guid, std::move(v));
        g_count.fetch_add(1, std::memory_order_relaxed);
    }

    void Untrack(std::string const& runId)
    {
        std::lock_guard<std::mutex> lock(g_mu);
        for (auto it = g_victims.begin(); it != g_victims.end();)
        {
            if (it->second.runId == runId)
            {
                it = g_victims.erase(it);
                g_count.fetch_sub(1, std::memory_order_relaxed);
            }
            else
                ++it;
        }
    }

    Detail TakeDeath(ObjectGuid guid)
    {
        Detail d;
        std::lock_guard<std::mutex> lock(g_mu);
        auto it = g_victims.find(guid);
        if (it == g_victims.end() || it->second.hits.empty())
            return d;
        Victim const& v = it->second;
        HitRec const& last = v.hits.back();
        d.any = true;
        d.killer = last.src;
        d.killerSpell = last.spell;
        d.killerSpellId = last.spellId;
        d.killerAmount = last.amount;
        d.killerOverkill = last.overkill;
        d.killerHpPct = last.srcHpPct;
        d.killerBoss = last.srcBoss;

        std::uint32_t const ref = last.ms;  // the moment of the last hit
        std::map<std::pair<std::string, std::string>, std::uint64_t> top;
        for (HitRec const& h : v.hits)
        {
            if (h.ms > ref)
                continue;
            std::uint32_t const age = ref - h.ms;
            if (age > 10000)
                continue;
            d.dmg10s += h.amount;
            if (age <= 5000)
            {
                d.dmg5s += h.amount;
                top[{ h.src, h.spell }] += h.amount;
            }
        }
        for (HealRec const& h : v.heals)
        {
            if (h.ms > ref)
                continue;
            std::uint32_t const age = ref - h.ms;
            if (age > 10000)
                continue;
            d.heal10s += h.amount;
            if (age <= 5000)
                d.heal5s += h.amount;
        }
        for (auto const& [k, total] : top)
            if (total > d.topAmount)
            {
                d.topAmount = static_cast<std::uint32_t>(std::min<std::uint64_t>(total, 0xFFFFFFFFull));
                d.topSrc = k.first;
                d.topSpell = k.second;
            }
        for (auto rit = v.hits.rbegin(); rit != v.hits.rend() && d.lastHits.size() < 5; ++rit)
        {
            LastHit lh;
            lh.ageMs = ref >= rit->ms ? ref - rit->ms : 0;
            lh.src = rit->src;
            lh.spell = rit->spell;
            lh.amount = rit->amount;
            d.lastHits.push_back(std::move(lh));
        }
        return d;
    }

    void Totals(std::string const& runId, std::size_t maxSources, std::size_t maxHealers,
                std::vector<SourceTotal>* sources, std::vector<HealerTotal>* healers, std::uint64_t* taken)
    {
        std::map<std::string, SourceTotal> src;
        std::map<std::string, std::uint64_t> heal;
        std::uint64_t sum = 0;
        {
            std::lock_guard<std::mutex> lock(g_mu);
            for (auto const& entry : g_victims)
            {
                Victim const& v = entry.second;
                if (v.runId != runId)
                    continue;
                sum += v.taken;
                for (auto const& row : v.dmg)
                {
                    SourceTotal& a = src[row.first];
                    if (a.src.empty())
                    {
                        a.src = row.second.src;
                        a.spell = row.second.spell;
                        a.spellId = row.second.spellId;
                    }
                    a.total += row.second.total;
                    a.hits += row.second.hits;
                }
                for (auto const& h : v.healBy)
                    heal[h.first] += h.second;
            }
        }
        if (taken)
            *taken = sum;
        if (sources)
        {
            for (auto const& row : src)
                sources->push_back(row.second);
            std::sort(sources->begin(), sources->end(),
                      [](SourceTotal const& a, SourceTotal const& b) { return a.total > b.total; });
            if (sources->size() > maxSources)
                sources->resize(maxSources);
        }
        if (healers)
        {
            for (auto const& h : heal)
            {
                HealerTotal t;
                t.name = h.first;
                t.total = h.second;
                healers->push_back(std::move(t));
            }
            std::sort(healers->begin(), healers->end(),
                      [](HealerTotal const& a, HealerTotal const& b) { return a.total > b.total; });
            if (healers->size() > maxHealers)
                healers->resize(maxHealers);
        }
    }

    void Register()
    {
        new DcDeathLogScript();
    }
}
