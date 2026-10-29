/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "TestRun/DcSpellLedger.h"

#include <algorithm>
#include <atomic>
#include <map>
#include <mutex>
#include <unordered_map>

#include "AllSpellScript.h"
#include "Creature.h"
#include "GameTime.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "UnitScript.h"

namespace DcSpellLedger
{
    namespace
    {
        constexpr std::uint32_t kPendingMs = 250;   // a remembered spell is good for that actor's next event only
        constexpr std::size_t kPendingCap = 512;
        constexpr std::size_t kCellCap = 400;       // distinct (source, spell) rows kept per member

        struct Cell
        {
            std::uint32_t started = 0, succeeded = 0, cancelled = 0, triggered = 0;
            std::uint32_t hits = 0, heals = 0;
            std::uint64_t damage = 0, overkill = 0, healSelf = 0, healOther = 0;
        };

        struct Pend
        {
            ObjectGuid other;
            std::uint32_t ms = 0;
            std::uint32_t spellId = 0;
        };

        struct Owner
        {
            std::string runId;
            std::string name;
            std::unordered_map<std::uint64_t, Cell> cells;
            std::unordered_map<std::uint32_t, std::string> sourceNames;
            std::unordered_map<std::uint32_t, std::string> spellNames;
            OwnerTotals totals;
        };

        std::mutex g_mu;
        std::unordered_map<ObjectGuid, Owner> g_owners;
        std::unordered_map<ObjectGuid, Pend> g_pendDmg, g_pendHeal;
        std::atomic<std::uint32_t> g_count{0};

        std::uint32_t NowMs()
        {
            return static_cast<std::uint32_t>(GameTime::GetGameTimeMS().count());
        }

        Player* OwnerOf(Unit* u)
        {
            return u ? u->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
        }

        std::uint64_t KeyOf(std::uint32_t entry, std::uint32_t spellId)
        {
            return (static_cast<std::uint64_t>(entry) << 32) | spellId;
        }

        // The cell of (source, spell) for an owner. Caller holds g_mu. Past the cap everything new goes to one
        // "other" cell so the totals stay right.
        Cell& CellFor(Owner& o, Unit* source, Player* owner, std::uint32_t spellId, SpellInfo const* si)
        {
            std::uint32_t entry = 0;
            if (source && source != owner && source->IsCreature())
            {
                entry = source->GetEntry();
                o.sourceNames.emplace(entry, source->GetName());
            }
            if (si && !o.spellNames.count(spellId))
            {
                char const* n = si->SpellName[0];
                o.spellNames[spellId] = n && *n ? n : "";
            }
            std::uint64_t key = KeyOf(entry, spellId);
            if (!o.cells.count(key) && o.cells.size() >= kCellCap)
                key = KeyOf(0xFFFFFFFEu, kUnattributed);
            return o.cells[key];
        }

        void Remember(std::unordered_map<ObjectGuid, Pend>& pend, Unit* actor, Unit* other, std::uint32_t spellId)
        {
            if (!g_count.load(std::memory_order_relaxed) || !actor)
                return;
            Player* owner = OwnerOf(actor);
            if (!owner)
                return;
            std::lock_guard<std::mutex> lock(g_mu);
            if (!g_owners.count(owner->GetGUID()))
                return;
            if (pend.size() >= kPendingCap)
                pend.clear();
            Pend& p = pend[actor->GetGUID()];
            p.other = other ? other->GetGUID() : ObjectGuid::Empty;
            p.ms = NowMs();
            p.spellId = spellId;
        }

        std::uint32_t Take(std::unordered_map<ObjectGuid, Pend>& pend, Unit* actor, Unit* other)
        {
            auto it = pend.find(actor->GetGUID());
            if (it == pend.end())
                return kUnattributed;
            Pend const p = it->second;
            pend.erase(it);
            if (p.other != (other ? other->GetGUID() : ObjectGuid::Empty) || NowMs() - p.ms > kPendingMs)
                return kUnattributed;
            return p.spellId;
        }

        class LedgerUnitScript : public UnitScript
        {
        public:
            LedgerUnitScript()
                : UnitScript("DcSpellLedgerUnitScript", true, {
                    UNITHOOK_ON_DAMAGE,
                    UNITHOOK_ON_HEAL,
                    UNITHOOK_MODIFY_MELEE_DAMAGE,
                    UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN,
                    UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK,
                    UNITHOOK_MODIFY_HEAL_RECEIVED
                }) {}

            void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& /*damage*/) override
            {
                Remember(g_pendDmg, attacker, target, kMelee);
            }

            void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& /*damage*/, SpellInfo const* spellInfo) override
            {
                Remember(g_pendDmg, attacker, target, spellInfo ? spellInfo->Id : kUnattributed);
            }

            void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& /*damage*/, SpellInfo const* spellInfo) override
            {
                // this hook also fires for periodic HEAL ticks: only damage auras are remembered for damage
                if (spellInfo && (spellInfo->HasAura(SPELL_AURA_PERIODIC_DAMAGE) || spellInfo->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT) ||
                                  spellInfo->HasAura(SPELL_AURA_PERIODIC_LEECH)))
                    Remember(g_pendDmg, attacker, target, spellInfo->Id);
            }

            void ModifyHealReceived(Unit* target, Unit* healer, uint32& /*heal*/, SpellInfo const* spellInfo) override
            {
                Remember(g_pendHeal, healer, target, spellInfo ? spellInfo->Id : kUnattributed);
            }

            void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
            {
                if (!damage || !attacker || !victim || !g_count.load(std::memory_order_relaxed))
                    return;
                if (victim->IsPlayer() || OwnerOf(victim))   // friendly fire, duels: not the party's output
                    return;
                Player* owner = OwnerOf(attacker);
                if (!owner)
                    return;
                std::uint32_t const hp = victim->GetHealth();
                std::uint32_t const overkill = damage > hp ? damage - hp : 0;
                std::lock_guard<std::mutex> lock(g_mu);
                auto it = g_owners.find(owner->GetGUID());
                if (it == g_owners.end())
                    return;
                Owner& o = it->second;
                std::uint32_t const spellId = Take(g_pendDmg, attacker, victim);
                SpellInfo const* si = (spellId != kMelee && spellId != kUnattributed) ? sSpellMgr->GetSpellInfo(spellId) : nullptr;
                Cell& c = CellFor(o, attacker, owner, spellId, si);
                c.hits += 1;
                c.damage += damage;
                c.overkill += overkill;
                o.totals.damageAll += damage;
                o.totals.overkillAll += overkill;
                if (spellId == kUnattributed)
                    o.totals.damageUnattributed += damage;
            }

            void OnHeal(Unit* healer, Unit* receiver, uint32& gain) override
            {
                if (!gain || !healer || !receiver || !g_count.load(std::memory_order_relaxed))
                    return;
                Player* owner = OwnerOf(healer);
                if (!owner)
                    return;
                std::lock_guard<std::mutex> lock(g_mu);
                auto it = g_owners.find(owner->GetGUID());
                if (it == g_owners.end())
                    return;
                Owner& o = it->second;
                std::uint32_t const spellId = Take(g_pendHeal, healer, receiver);
                SpellInfo const* si = spellId != kUnattributed ? sSpellMgr->GetSpellInfo(spellId) : nullptr;
                Cell& c = CellFor(o, healer, owner, spellId, si);
                c.heals += 1;
                if (receiver == owner)
                    c.healSelf += gain;
                else
                    c.healOther += gain;
                o.totals.healAll += gain;
                if (spellId == kUnattributed)
                    o.totals.healUnattributed += gain;
            }
        };

        class LedgerSpellScript : public AllSpellScript
        {
        public:
            LedgerSpellScript()
                : AllSpellScript("DcSpellLedgerSpellScript", { ALLSPELLHOOK_ON_PREPARE, ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_CAST_CANCEL }) {}

            void OnSpellPrepare(Spell* /*spell*/, Unit* caster, SpellInfo const* spellInfo) override
            {
                Bump(caster, spellInfo, 0, false);
            }

            void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* spellInfo, bool /*skipCheck*/) override
            {
                Bump(caster, spellInfo, 1, spell && spell->IsTriggered());
            }

            void OnSpellCastCancel(Spell* /*spell*/, Unit* caster, SpellInfo const* spellInfo, bool /*bySelf*/) override
            {
                Bump(caster, spellInfo, 2, false);
            }

        private:
            static void Bump(Unit* caster, SpellInfo const* si, int what, bool triggered)
            {
                if (!si || !caster || !g_count.load(std::memory_order_relaxed))
                    return;
                Player* owner = OwnerOf(caster);
                if (!owner)
                    return;
                std::lock_guard<std::mutex> lock(g_mu);
                auto it = g_owners.find(owner->GetGUID());
                if (it == g_owners.end())
                    return;
                Cell& c = CellFor(it->second, caster, owner, si->Id, si);
                if (what == 0)
                    c.started += 1;
                else if (what == 1)
                {
                    c.succeeded += 1;
                    if (triggered)
                        c.triggered += 1;
                }
                else
                    c.cancelled += 1;
            }
        };
    }

    void Track(ObjectGuid owner, std::string const& runId, std::string const& name)
    {
        std::lock_guard<std::mutex> lock(g_mu);
        auto it = g_owners.find(owner);
        if (it != g_owners.end())
        {
            if (it->second.runId == runId)
                return;
            it->second = Owner();  // another run: start clean
        }
        else
            g_count.fetch_add(1, std::memory_order_relaxed);
        Owner& o = g_owners[owner];
        o.runId = runId;
        o.name = name;
        o.totals.owner = name;
    }

    void Untrack(std::string const& runId)
    {
        std::lock_guard<std::mutex> lock(g_mu);
        for (auto it = g_owners.begin(); it != g_owners.end();)
        {
            if (it->second.runId == runId)
            {
                it = g_owners.erase(it);
                g_count.fetch_sub(1, std::memory_order_relaxed);
            }
            else
                ++it;
        }
        if (g_owners.empty())
        {
            g_pendDmg.clear();
            g_pendHeal.clear();
        }
    }

    void Snapshot(std::string const& runId, std::size_t maxRows, std::vector<Row>* rows, std::vector<OwnerTotals>* totals)
    {
        std::lock_guard<std::mutex> lock(g_mu);
        std::vector<Owner const*> mine;
        for (auto const& e : g_owners)
            if (e.second.runId == runId)
                mine.push_back(&e.second);
        std::size_t const perOwner = std::max<std::size_t>(20, maxRows / std::max<std::size_t>(1, mine.size()));
        for (Owner const* o : mine)
        {
            if (totals)
                totals->push_back(o->totals);
            if (!rows)
                continue;
            std::vector<Row> own;
            for (auto const& kv : o->cells)
            {
                Row r;
                r.owner = o->name;
                r.sourceEntry = static_cast<std::uint32_t>(kv.first >> 32);
                r.spellId = static_cast<std::uint32_t>(kv.first & 0xFFFFFFFFu);
                if (r.sourceEntry == 0xFFFFFFFEu)
                    r.source = "other";
                else if (r.sourceEntry)
                {
                    auto sn = o->sourceNames.find(r.sourceEntry);
                    r.source = sn != o->sourceNames.end() ? sn->second : std::string("creature ") + std::to_string(r.sourceEntry);
                }
                if (r.spellId == kMelee)
                    r.spell = "melee";
                else if (r.spellId == kUnattributed)
                    r.spell = "unattributed";
                else
                {
                    auto nm = o->spellNames.find(r.spellId);
                    r.spell = nm != o->spellNames.end() && !nm->second.empty() ? nm->second : std::string("spell ") + std::to_string(r.spellId);
                }
                Cell const& c = kv.second;
                r.started = c.started;
                r.succeeded = c.succeeded;
                r.cancelled = c.cancelled;
                r.triggered = c.triggered;
                r.hits = c.hits;
                r.heals = c.heals;
                r.damage = c.damage;
                r.overkill = c.overkill;
                r.healSelf = c.healSelf;
                r.healOther = c.healOther;
                own.push_back(std::move(r));
            }
            std::sort(own.begin(), own.end(), [](Row const& a, Row const& b)
            {
                std::uint64_t const ea = a.damage + a.healSelf + a.healOther, eb = b.damage + b.healSelf + b.healOther;
                if (ea != eb)
                    return ea > eb;
                return a.succeeded > b.succeeded;
            });
            if (own.size() > perOwner)
                own.resize(perOwner);
            for (Row& r : own)
                rows->push_back(std::move(r));
        }
    }

    void Register()
    {
        new LedgerUnitScript();
        new LedgerSpellScript();
    }
}
