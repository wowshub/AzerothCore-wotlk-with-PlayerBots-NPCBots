#include <chrono>
#include "CombatManager.h"
#include "ThreatManager.h"
#include <vector>
#include <algorithm>
#include "ObjectAccessor.h"
#include "WorldPacket.h"
#include "Opcodes.h"
#include "GameObject.h"
#include "Map.h"
#include "PathGenerator.h"
#include <cmath>
#include "CellImpl.h"
#include "ScriptedCreature.h"
#include "TemporarySummon.h"
#include "ObjectMgr.h"
#include "Chat.h"
#include "Group.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "Random.h"

#include <algorithm>
#include <list>
#include <set>
#include <vector>

namespace
{
constexpr uint8 MONK_CLASS_ID = 14;
constexpr uint32 MONK_CHI_AURA_ID = 9001511;
constexpr uint8 MONK_BLACKOUT_KICK_CHI_COST = 2;
constexpr uint8 MONK_RISING_SUN_KICK_CHI_COST = 2;
constexpr uint32 MONK_RISING_SUN_KICK_MORTAL_WOUNDS_ID = 9001514;
constexpr uint32 MONK_RISING_SUN_KICK_VULNERABILITY_ID = 9001515;
constexpr float MONK_RISING_SUN_KICK_VULNERABILITY_RADIUS = 8.0f;
constexpr int32 MONK_RISING_SUN_KICK_VULNERABILITY_DAMAGE_PCT = 15;
constexpr uint32 MONK_BLACKOUT_KICK_DOT_ID = 9001508;
constexpr uint32 MONK_BLACKOUT_KICK_HEAL_ID = 9001509;

// MONKM3H: real native talent ownership in the active build is authoritative.
// Rank IDs are consecutive, highest rank wins; never sum old/new ranks.
int32 RebornMonkScaleTalentValue(Unit* caster, int32 value, uint32 firstRank)
{
    Player* player = caster ? caster->ToPlayer() : nullptr;
    if (!player || player->getClass() != MONK_CLASS_ID || value <= 0)
        return value;
    uint8 activeSpec = player->GetActiveSpec();
    for (int32 rank = 3; rank >= 1; --rank)
        if (player->HasTalent(firstRank + uint32(rank - 1), activeSpec))
            return int32(std::min<int64>(2147483647, int64(value) * (100 + rank * 5) / 100));
    return value;
}

// MONKM3I: active-build ownership; ignore other builds and stale aura markers.
uint32 RebornMonkActiveTalentRank(Unit* unit, uint32 firstRank)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    if (!player || player->getClass() != MONK_CLASS_ID)
        return 0;
    for (uint32 rank = 3; rank > 0; --rank)
        if (player->HasTalent(firstRank + rank - 1, player->GetActiveSpec()))
            return rank;
    return 0;
}

// MONKM3N: one-rank nodes require exact ownership, not consecutive-rank lookup.
int32 RebornMonkScaleResolve(Unit* caster, int32 value, uint32 talent, uint32 stance, uint32 pct)
{
    Player* player = caster ? caster->ToPlayer() : nullptr;
    if (!player || player->getClass() != MONK_CLASS_ID || value <= 0 ||
        !player->HasTalent(talent, player->GetActiveSpec()) || !player->HasAura(stance))
        return value;
    return int32(std::min<int64>(2147483647, int64(value) * (100u + pct) / 100));
}

// MONKM3O: two-rank talents, never inspect a third adjacent spell ID.
uint32 RebornMonkStanceEconomyChance(Unit* caster, uint32 firstRank, uint32 stance)
{
    Player* player = caster ? caster->ToPlayer() : nullptr;
    if (!player || player->getClass() != MONK_CLASS_ID || !player->HasAura(stance))
        return 0;
    uint8 spec = player->GetActiveSpec();
    if (player->HasTalent(firstRank + 1, spec))
        return 20;
    return player->HasTalent(firstRank, spec) ? 10 : 0;
}

bool IsMonkDirectDamageSpell(uint32 spellId)
{
    switch (spellId)
    {
        case 9001501: // Monk Direct Hit
        case 9001502: // Tiger Palm
        case 9001504: // Expel Harm retaliation
        case 9001507: // Blackout Kick
        case 9001510: // Jab
        case 9001513: // Rising Sun Kick
        case 9001536: // Flying Serpent Kick landing
        case 9001539: // Rushing Jade Wind triggered weapon strike
        case 9001532: // Spinning Crane Kick triggered weapon strike
        case 9001519: // Fists of Fury triggered weapon strike
            return true;
        default:
            return false;
    }
}
}

// 9001510 - 贯日击 / Jab
//
// The 3.3.5 protocol has no native Monk Chi power type.  M6K1 therefore uses
// a visible, harmless, four-stack dummy aura (9001511) as the authoritative
// Chi counter.  Chi is granted only after real damage lands: misses, dodges,
// parries and immune hits do not create a stack.
// MONKWW4: state belongs to the current player's aura or individual cast.
static bool WW4Tiger(Player* p)
{
    return p && p->getClass() == 14 && p->IsAlive() && p->HasAura(9001550);
}
static uint32 WW4Rank(Player* p, uint32 first, uint32 count)
{
    if (!p || p->getClass() != 14) return 0;
    for (uint32 n = count; n; --n)
        if (p->HasTalent(first + n - 1, p->GetActiveSpec())) return n;
    return 0;
}

class aura_reborn_ww4_state : public AuraScript
{
    PrepareAuraScript(aura_reborn_ww4_state);
    uint8 _spec = 0;
    uint32 _last = 0;
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* p = GetTarget()->ToPlayer()) _spec = p->GetActiveSpec();
    }
    void Guard(AuraEffect const*)
    {
        Player* p = GetTarget()->ToPlayer();
        uint32 id = GetId();
        uint32 talent = id == 9001852 ? 9001840 : id == 9001850 ? 9001850 : 9001842;
        if (!Valid(p) || !WW4Rank(p, talent, id == 9001852 ? 2 : 1) ||
            (id == 9001850 && !WW4Rank(p, 9001842, 1)))
        { Remove(); return; }
        if (id == 9001851 && GetStackAmount() > 3 && !p->HasAura(9001850))
            GetAura()->SetStackAmount(3);
    }
    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetId() == 9001850)
            if (Aura* a = GetTarget()->GetAura(9001851))
                if (a->GetStackAmount() > 3) a->SetStackAmount(3);
    }
public:
    bool Valid(Player* p) const { return WW4Tiger(p) && p->GetActiveSpec() == _spec; }
    void Earn(Player* p, uint32 id)
    {
        uint8 cap = WW4Rank(p, 9001850, 1) && p->HasAura(9001850) ? 5 : 3;
        uint8 stacks = _last && _last != id ? std::min<uint8>(cap, GetStackAmount() + 1) : 1;
        _last = id;
        GetAura()->SetStackAmount(stacks);
        int32 duration = 6000 + 1000 * WW4Rank(p, 9001845, 3);
        GetAura()->SetMaxDuration(duration);
        GetAura()->SetDuration(duration);
    }
private:
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_ww4_state::Applied, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_ww4_state::Guard, EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_ww4_state::End, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};
static aura_reborn_ww4_state* WW4State(Player* p, uint32 id)
{
    Aura* a = p ? p->GetAura(id) : nullptr;
    auto* s = a ? a->GetScript<aura_reborn_ww4_state>("aura_reborn_ww4_state") : nullptr;
    return s && s->Valid(p) ? s : nullptr;
}
static void WW4Earn(Player* p, uint32 id)
{
    if (!WW4Tiger(p) || !WW4Rank(p, 9001842, 1)) return;
    if (!WW4State(p, 9001851))
    {
        p->RemoveAurasDueToSpell(9001851);
        p->CastSpell(p, 9001851, true);
    }
    if (auto* s = WW4State(p, 9001851)) s->Earn(p, id);
}
struct WW4Cast
{
    uint32 bonus = 0;
    uint32 palmBonus = 0;
    uint8 spec = 0;
    bool paid = false;
    void Start(Unit* u, uint32 id)
    {
        Player* p = u ? u->ToPlayer() : nullptr;
        if (!WW4Tiger(p)) return;
        spec = p->GetActiveSpec();
        if (id == 9001507 && WW4State(p, 9001852))
        {
            palmBonus = 3 * WW4Rank(p, 9001840, 2);
            p->RemoveAurasDueToSpell(9001852);
        }
        if (id != 9001507 && id != 9001513 && id != 9001518) return;
        if (WW4Rank(p, 9001842, 1) && WW4State(p, 9001851))
        {
            uint32 stacks = p->GetAura(9001851)->GetStackAmount();
            stacks = std::min<uint32>(stacks, WW4Rank(p, 9001850, 1) && p->HasAura(9001850) ? 5 : 3);
            bonus = 2 * stacks;
            if (stacks >= 3 && (id == 9001513 || id == 9001518))
                bonus += 2 * WW4Rank(p, 9001843, 2);
            p->RemoveAurasDueToSpell(9001851);
        }
    }
    bool Valid(Unit* u) const
    {
        Player* p = u ? u->ToPlayer() : nullptr;
        return WW4Tiger(p) && p->GetActiveSpec() == spec;
    }
    int32 Scale(Unit* u, int32 damage) const
    {
        return damage > 0 && Valid(u) ? int32(int64(damage) * (100 + bonus + palmBonus) / 100) : damage;
    }
    // Only Palm and Kick is excluded from Blackout's derived damage/healing.
    int32 Derived(Unit* u, int32 damage) const
    {
        return Valid(u) && palmBonus ? int32(int64(damage) * (100 + bonus) / (100 + bonus + palmBonus)) : damage;
    }
    void Hit(Unit* u, uint32 id, int32 damage)
    {
        if (paid || damage <= 0 || !Valid(u)) return;
        paid = true;
        Player* p = u->ToPlayer();
        WW4Earn(p, id);
        if (id == 9001502 && WW4Rank(p, 9001840, 2)) p->CastSpell(p, 9001852, true);
    }
};

// The channel aura snapshots once; all FoF targets/pulses use the same context.
class aura_reborn_ww4_fists : public AuraScript
{
    PrepareAuraScript(aura_reborn_ww4_fists);
    WW4Cast _cast;
    void Start(AuraEffect const*, AuraEffectHandleModes) { _cast.Start(GetCaster(), 9001518); }
public:
    int32 Scale(Unit* u, int32 d) const { return _cast.Scale(u, d); }
    void Hit(Unit* u, int32 d) { _cast.Hit(u, 9001518, d); }
private:
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_ww4_fists::Start, EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};
class spell_reborn_ww4_fists_pulse : public SpellScript
{
    PrepareSpellScript(spell_reborn_ww4_fists_pulse);
    aura_reborn_ww4_fists* Context()
    {
        Aura* a = GetCaster()->GetAura(9001518);
        return a ? a->GetScript<aura_reborn_ww4_fists>("aura_reborn_ww4_fists") : nullptr;
    }
    void Scale() { if (auto* s = Context()) SetHitDamage(s->Scale(GetCaster(), GetHitDamage())); }
    void Hit() { if (auto* s = Context()) s->Hit(GetCaster(), GetHitDamage()); }
    void Register() override
    {
        OnHit += SpellHitFn(spell_reborn_ww4_fists_pulse::Scale);
        AfterHit += SpellHitFn(spell_reborn_ww4_fists_pulse::Hit);
    }
};

class spell_reborn_ww4_mastery : public SpellScript
{
    PrepareSpellScript(spell_reborn_ww4_mastery);
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p || p->getClass() != 14) return SPELL_FAILED_BAD_TARGETS;
        if (!WW4Rank(p, 9001850, 1) || !WW4Rank(p, 9001842, 1))
        {
            ChatHandler(p->GetSession()).SendNotification("踏风宗师：需要本套天赋的连势入门与踏风宗师。 / Requires Combo Initiate and Windwalker Mastery in the active build.");
            return SPELL_FAILED_DONT_REPORT;
        }
        if (!p->HasAura(9001550))
        {
            ChatHandler(p->GetSession()).SendNotification("踏风宗师：请先切换到猛虎式。 / Windwalker Mastery: Switch to Tiger Stance first.");
            return SPELL_FAILED_DONT_REPORT;
        }
        return SPELL_CAST_OK;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_reborn_ww4_mastery::Check); }
};

// A temporary owned creature, not a permanent hunter pet or decorative statue.
class npc_reborn_ww4_xuen : public CreatureScript
{
public:
    npc_reborn_ww4_xuen() : CreatureScript("npc_reborn_ww4_xuen") { }
    struct AI : public ScriptedAI
    {
        AI(Creature* c) : ScriptedAI(c) { }
        uint8 spec = 0;
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* p = summoner ? summoner->ToPlayer() : nullptr;
            if (!p) { me->DespawnOrUnsummon(); return; }
            spec = p->GetActiveSpec();
            me->SetOwnerGUID(p->GetGUID());
            me->SetCreatorGUID(p->GetGUID());
            me->SetFaction(p->GetFaction());
            me->SetLevel(p->GetLevel());
            me->SetMaxHealth(std::max<uint32>(1, p->GetMaxHealth() / 2));
            me->SetHealth(me->GetMaxHealth());
            float damage = std::max(1.0f, p->GetTotalAttackPowerValue(BASE_ATTACK) * 0.20f);
            // Creature damage is DPS-normalized by core attack time. Clear its
            // template AP/base damage so the owner's snapshot is counted once.
            me->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, BASE_VALUE, 0.0f);
            me->SetStatFlatModifier(UNIT_MOD_ATTACK_POWER, TOTAL_VALUE, 0.0f);
            me->SetStatFlatModifier(UNIT_MOD_DAMAGE_MAINHAND, BASE_VALUE, 0.0f);
            me->SetStatFlatModifier(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_VALUE, 0.0f);
            me->SetStatPctModifier(UNIT_MOD_DAMAGE_MAINHAND, BASE_PCT, 1.0f);
            me->SetStatPctModifier(UNIT_MOD_DAMAGE_MAINHAND, TOTAL_PCT, 1.0f);
            me->UpdateAttackPowerAndDamage();
            float dps = damage / std::max(0.1f, me->GetAPMultiplier(BASE_ATTACK, false));
            me->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, dps);
            me->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, dps);
            me->UpdateDamagePhysical(BASE_ATTACK);
            me->CastSpell(p, 9001857, true);
            if (uint32 rank = WW4Rank(p, 9001848, 2))
                me->CastCustomSpell(9001853, SPELLVALUE_BASE_POINT0, int32(2 * rank), p, true);
        }
        void UpdateAI(uint32 /*diff*/) override
        {
            Player* p = me->GetOwner() ? me->GetOwner()->ToPlayer() : nullptr;
            if (!WW4Tiger(p) || p->GetActiveSpec() != spec || !me->IsWithinDistInMap(p, 60.0f))
            { me->DespawnOrUnsummon(); return; }
            Unit* target = p->getAttackerForHelper();
            if (target && target->IsAlive() && p->IsValidAttackTarget(target) && me->IsWithinDistInMap(target, 40.0f))
            {
                if (me->GetVictim() != target) AttackStart(target);
            }
            else
            {
                if (me->GetVictim()) me->AttackStop();
                if (me->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE)
                    me->GetMotionMaster()->MoveFollow(p, 2.0f, 0.5f);
                return;
            }
            DoMeleeAttackIfReady();
        }
    };
    CreatureAI* GetAI(Creature* c) const override { return new AI(c); }
};
class aura_reborn_ww4_xuen_presence : public AuraScript
{
    PrepareAuraScript(aura_reborn_ww4_xuen_presence);
    uint8 _spec = 0;
    void Start(AuraEffect const*, AuraEffectHandleModes)
    { if (Player* p = GetTarget()->ToPlayer()) _spec = p->GetActiveSpec(); }
    void Guard(AuraEffect const*)
    {
        Player* p = GetTarget()->ToPlayer();
        Unit* tiger = GetCaster();
        if (!WW4Tiger(p) || p->GetActiveSpec() != _spec || !tiger || !tiger->IsAlive() ||
            tiger->GetEntry() != 900184 || tiger->GetOwnerGUID() != p->GetGUID() ||
            !tiger->IsWithinDistInMap(p, 60.0f) || (GetId() == 9001853 && !WW4Rank(p, 9001848, 2)))
        { Remove(); return; }
        if (GetId() == 9001853)
            if (AuraEffect* e = GetEffect(EFFECT_0))
                if (e->GetAmount() > int32(2 * WW4Rank(p, 9001848, 2)))
                    e->ChangeAmount(int32(2 * WW4Rank(p, 9001848, 2)));
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_ww4_xuen_presence::Start, EFFECT_1, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_ww4_xuen_presence::Guard, EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
    }
};
class spell_reborn_ww4_xuen : public SpellScript
{
    PrepareSpellScript(spell_reborn_ww4_xuen);
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p || p->getClass() != 14) return SPELL_FAILED_BAD_TARGETS;
        if (!sObjectMgr->GetCreatureTemplate(900184))
        {
            ChatHandler(p->GetSession()).SendNotification("白虎召唤数据未加载，请安装本包SQL并重启服务端。 / Xuen creature data is missing; install the package SQL and restart the server.");
            return SPELL_FAILED_DONT_REPORT;
        }
        if (!p->HasAura(9001550))
        {
            ChatHandler(p->GetSession()).SendNotification("召唤白虎：请先切换到猛虎式。 / Invoke Xuen: Switch to Tiger Stance first.");
            return SPELL_FAILED_DONT_REPORT;
        }
        if (p->HasAura(9001857)) return SPELL_FAILED_ALREADY_HAVE_SUMMON;
        return SPELL_CAST_OK;
    }
    void Summon(SpellEffIndex)
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p) return;
        Position pos = p->GetPosition();
        if (Creature* tiger = p->SummonCreature(900184, pos, TEMPSUMMON_TIMED_DESPAWN, 45000))
        {
            if (Unit* target = p->getAttackerForHelper())
                if (p->IsValidAttackTarget(target)) tiger->AI()->AttackStart(target);
        }
        else ChatHandler(p->GetSession()).SendNotification("白虎召唤失败，请检查服务端召唤记录。 / Xuen summon failed; check the server summon log.");
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_ww4_xuen::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_ww4_xuen::Summon, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_reborn_monk_jab : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_jab);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ MONK_CHI_AURA_ID });
    }

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    void GenerateChi()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || !GetHitUnit() || GetHitDamage() <= 0)
            return;

        if (Aura* chi = player->GetAura(MONK_CHI_AURA_ID))
        {
            if (chi->GetStackAmount() < 4)
                chi->ModStackAmount(1);
        }
        else
            player->CastSpell(player, MONK_CHI_AURA_ID, true);
    }

    void PreserveMovingAnimation()
    {
        if (Player* player = GetCaster()->ToPlayer(); player && player->isMoving())
            player->HandleEmoteCommand(EMOTE_ONESHOT_ATTACK_UNARMED);
    }


    WW4Cast _ww4;
    void WW4Start() { _ww4.Start(GetCaster(), GetSpellInfo()->Id); }
    void WW4Scale() { SetHitDamage(_ww4.Scale(GetCaster(), GetHitDamage())); }
    void WW4Hit() { _ww4.Hit(GetCaster(), GetSpellInfo()->Id, GetHitDamage()); }

    void Register() override
    {
        OnCast += SpellCastFn(spell_reborn_monk_jab::PreserveMovingAnimation);
        AfterHit += SpellHitFn(spell_reborn_monk_jab::GenerateChi);
        OnCast += SpellCastFn(spell_reborn_monk_jab::WW4Start);
        OnHit += SpellHitFn(spell_reborn_monk_jab::WW4Scale);
        AfterHit += SpellHitFn(spell_reborn_monk_jab::WW4Hit);
    }
};

// 9001513 - 旭日东升踢 / Rising Sun Kick
//
// The retail donor spends two Chi and has an eight-second cooldown.  Because
// the 3.3.5 protocol has no native Monk Chi power type, the DBC carries zero
// Energy cost and this script validates/consumes two stacks of 9001511.
// Consumption happens only after real damage lands, matching the already
// verified Blackout Kick rule: misses, dodges, parries and immunities do not
// consume the emulated resource.
class spell_reborn_monk_rising_sun_kick : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_rising_sun_kick);

    bool _chiConsumed = false;
    bool _mortalWoundsApplied = false;
    bool _vulnerabilityApplied = false;

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            { MONK_CHI_AURA_ID,
              MONK_RISING_SUN_KICK_MORTAL_WOUNDS_ID,
              MONK_RISING_SUN_KICK_VULNERABILITY_ID });
    }

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    SpellCastResult CheckChi()
    {
        Player* player = GetCaster()->ToPlayer();
        Aura* chi = player ? player->GetAura(MONK_CHI_AURA_ID) : nullptr;
        if (!chi || chi->GetStackAmount() < MONK_RISING_SUN_KICK_CHI_COST)
            return SPELL_FAILED_NO_POWER;

        return SPELL_CAST_OK;
    }

    void PreserveMovingAnimation()
    {
        if (Player* player = GetCaster()->ToPlayer(); player && player->isMoving())
            player->HandleEmoteCommand(EMOTE_ONESHOT_CUSTOM_SPELL_09);
    }

    void ConsumeChi()
    {
        if (_chiConsumed || !GetHitUnit() || GetHitDamage() <= 0)
            return;

        Player* player = GetCaster()->ToPlayer();
        Aura* chi = player ? player->GetAura(MONK_CHI_AURA_ID) : nullptr;
        if (!chi || chi->GetStackAmount() < MONK_RISING_SUN_KICK_CHI_COST)
            return;

        uint32 chance = RebornMonkStanceEconomyChance(player, 9001720, 9001550);
        int32 cost = MONK_RISING_SUN_KICK_CHI_COST;
        if (chance && roll_chance_i(chance))
            --cost;
        chi->ModStackAmount(-cost);
        _chiConsumed = true;
    }

    void ApplyRisingSunTraining()
    {
        if (GetHitUnit() && GetHitDamage() > 0)
            SetHitDamage(RebornMonkScaleTalentValue(GetCaster(), GetHitDamage(), 9001650));
    }

    void ApplyMortalWounds()
    {
        if (_mortalWoundsApplied || !GetHitUnit() || GetHitDamage() <= 0)
            return;

        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!player || !target)
            return;

        player->CastSpell(target, MONK_RISING_SUN_KICK_MORTAL_WOUNDS_ID, true);
        _mortalWoundsApplied = true;
    }

    void ApplyNearbyVulnerability()
    {
        if (_vulnerabilityApplied || !GetHitUnit() || GetHitDamage() <= 0)
            return;

        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return;

        std::list<Unit*> targets;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(
            player, player, MONK_RISING_SUN_KICK_VULNERABILITY_RADIUS);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(
            player, targets, check);
        Cell::VisitObjects(player, searcher, MONK_RISING_SUN_KICK_VULNERABILITY_RADIUS);

        for (Unit* target : targets)
            if (target && target->IsAlive())
                player->CastSpell(target, MONK_RISING_SUN_KICK_VULNERABILITY_ID, true);

        _vulnerabilityApplied = true;
    }


    WW4Cast _ww4;
    void WW4Start() { _ww4.Start(GetCaster(), GetSpellInfo()->Id); }
    void WW4Scale() { SetHitDamage(_ww4.Scale(GetCaster(), GetHitDamage())); }
    void WW4Hit() { _ww4.Hit(GetCaster(), GetSpellInfo()->Id, GetHitDamage()); }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_rising_sun_kick::CheckChi);
        OnCast += SpellCastFn(spell_reborn_monk_rising_sun_kick::PreserveMovingAnimation);
        OnHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::ApplyRisingSunTraining);
        AfterHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::ApplyMortalWounds);
        AfterHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::ApplyNearbyVulnerability);
        AfterHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::ConsumeChi);
        OnCast += SpellCastFn(spell_reborn_monk_rising_sun_kick::WW4Start);
        OnHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::WW4Scale);
        AfterHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::WW4Hit);
    }
};

// 9001515 - 旭日易伤 / Rising Sun Vulnerability
//
// MoP uses aura 271 to make only the applying Monk's abilities deal more
// damage.  That aura type does not exist in the 3.3.5 core.  The visible DBC
// aura is therefore only a per-caster marker.  This UnitScript checks the real
// damage event, its spell ID and the marker caster GUID before adding 15%.
// Party members, another Monk, pets and auto attacks cannot inherit the bonus.
class spell_reborn_monk_rising_sun_kick_vulnerability : public UnitScript
{
public:
    spell_reborn_monk_rising_sun_kick_vulnerability()
        : UnitScript("spell_reborn_monk_rising_sun_kick_vulnerability", true)
    {
    }

    static bool CanAmplify(Unit* target, Unit* attacker, SpellInfo const* spellInfo)
    {
        Player* player = attacker ? attacker->ToPlayer() : nullptr;
        return target && player && player->getClass() == MONK_CLASS_ID && spellInfo &&
            target->GetAura(MONK_RISING_SUN_KICK_VULNERABILITY_ID, player->GetGUID());
    }

    void ModifySpellDamageTaken(
        Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (damage <= 0 || !CanAmplify(target, attacker, spellInfo) ||
            !IsMonkDirectDamageSpell(spellInfo->Id))
            return;

        damage += CalculatePct(damage, MONK_RISING_SUN_KICK_VULNERABILITY_DAMAGE_PCT);
    }

    void ModifyPeriodicDamageAurasTick(
        Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (!damage || !CanAmplify(target, attacker, spellInfo) ||
            spellInfo->Id != MONK_BLACKOUT_KICK_DOT_ID)
            return;

        damage += CalculatePct(damage, MONK_RISING_SUN_KICK_VULNERABILITY_DAMAGE_PCT);
    }
};

// 9001504 - 移花接木 / Expel Harm
//
// The 3.3.5 client has no native Chi protocol.  This implementation therefore
// keeps the verified Energy model and links the retaliation damage to effective
// healing instead of copying unsupported post-WotLK aura types.
class spell_reborn_monk_expel_harm : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_expel_harm);

    uint32 _effectiveHealing = 0;

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    void CaptureEffectiveHealing(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        uint32 missingHealth = caster->GetMaxHealth() - caster->GetHealth();
        uint32 requestedHealing = caster->CountPctFromMaxHealth(GetEffectValue());
        _effectiveHealing = std::min(missingHealth, requestedHealing);
    }

    void ScaleRetaliation(SpellEffIndex /*effIndex*/)
    {
        SetHitDamage(_effectiveHealing / 2);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(
            spell_reborn_monk_expel_harm::CaptureEffectiveHealing,
            EFFECT_0,
            SPELL_EFFECT_HEAL_PCT);
        OnEffectHitTarget += SpellEffectFn(
            spell_reborn_monk_expel_harm::ScaleRetaliation,
            EFFECT_1,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

// MONKARCH2A: the two-rank range is deliberately bounded.
uint32 RebornMonkArchRank(Unit* unit, uint32 firstRank)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    if (!player || player->getClass() != MONK_CLASS_ID)
        return 0;
    uint8 spec = player->GetActiveSpec();
    return player->HasTalent(firstRank + 1, spec) ? 2u :
        (player->HasTalent(firstRank, spec) ? 1u : 0u);
}

class aura_reborn_monk_arch_roll_end : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_arch_roll_end);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001760, 9001761, 9001764, 9001765, 9001766, 9001767});
    }
    void Finished(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !player->IsAlive() || GetCasterGUID() != player->GetGUID() ||
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        if (uint32 rank = RebornMonkArchRank(player, 9001760))
            player->CastCustomSpell(9001766, SPELLVALUE_BASE_POINT0, int32(5 * rank), player, true);
        if (player->HasAura(9001552))
            if (uint32 rank = RebornMonkArchRank(player, 9001764))
                player->CastCustomSpell(9001767, SPELLVALUE_BASE_POINT0, int32(3 * rank), player, true);
    }
    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_arch_roll_end::Finished,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_reborn_monk_arch_sobering : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_arch_sobering);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001762, 9001763}); }
    void Finished(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !player->IsAlive() || GetCasterGUID() != player->GetGUID() ||
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        uint32 rank = RebornMonkArchRank(player, 9001762);
        if (!rank)
            return;
        // Effect 2 is removed after the max-health effect 1; use the restored maximum.
        uint32 amount = uint32(uint64(player->GetMaxHealth()) * rank / 100);
        SpellInfo const* info = sSpellMgr->GetSpellInfo(9001761 + rank);
        if (!amount || !info)
            return;
        HealInfo heal(player, player, amount, info, SPELL_SCHOOL_MASK_NATURE);
        player->HealBySpell(heal); // heal absorb and heal log; no invented spell-power scaling
    }
    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_arch_sobering::Finished,
            EFFECT_2, SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN, AURA_EFFECT_HANDLE_REAL);
    }
};

// ARCH45M: the active capstone uses normal spell cooldowns, never a client timer.
class spell_reborn_monk_mist_mastery : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_mist_mastery);
    SpellCastResult Check()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || player->getClass() != MONK_CLASS_ID)
            return SPELL_FAILED_CASTER_AURASTATE;
        if (!player->HasTalent(9001800, player->GetActiveSpec()) ||
            !player->HasTalent(9001785, player->GetActiveSpec()))
        {
            ChatHandler(player->GetSession()).SendNotification("织雾宗师：需要本套天赋中的宗师及灵雾分流2/2。 / Requires Mistweaver Mastery and Shared Mists 2/2 in this build.");
            return SPELL_FAILED_DONT_REPORT;
        }
        if (!player->HasAura(9001552))
        {
            ChatHandler(player->GetSession()).SendNotification("织雾宗师：请先切换到灵蛇式。 / Mistweaver Mastery: Switch to Serpent Stance first.");
            return SPELL_FAILED_DONT_REPORT;
        }
        return SPELL_CAST_OK;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_mist_mastery::Check);
    }
};

class aura_reborn_monk_mist_mastery : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_mist_mastery);
    uint8 _spec = 0;
    bool _bound = false;
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr)
        {
            _spec = player->GetActiveSpec();
            _bound = true;
        }
    }
public:
    bool ActiveFor(Player* player) const
    {
        return player && _bound && player->GetActiveSpec() == _spec &&
            player->HasAura(9001552) && player->HasTalent(9001800, _spec) &&
            player->HasTalent(9001785, _spec);
    }
private:
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_mist_mastery::Applied,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

// ARCH2B: target and active build are scoped to this short-lived readiness aura.
class aura_reborn_monk_arch_continuity_ready : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_arch_continuity_ready);
    ObjectGuid _target;
    uint8 _spec = 0;
public:
    void Bind(ObjectGuid target, uint8 spec)
    {
        _target = target;
        _spec = spec;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return;
        uint32 extension = player->HasTalent(9001780, spec) ?
            RebornMonkActiveTalentRank(player, 9001790) : 0;
        int32 duration = 6000 + 1000 * extension;
        SetMaxDuration(duration);
        SetDuration(duration);
        if (GetId() == 9001778)
        {
            player->RemoveAurasDueToSpell(9001802);
            if (player->HasAura(9001552))
                if (uint32 rank = RebornMonkArchRank(player, 9001798))
                {
                    player->CastCustomSpell(9001802, SPELLVALUE_BASE_POINT0, int32(10 * rank), player, true);
                    if (Aura* calm = player->GetAura(9001802))
                    {
                        calm->SetMaxDuration(duration);
                        calm->SetDuration(duration);
                    }
                }
        }
    }
    bool CurrentFor(Player* player) const
    {
        return player && !_target.IsEmpty() && player->GetActiveSpec() == _spec;
    }
    bool Matches(ObjectGuid target, uint8 spec) const
    {
        return !_target.IsEmpty() && _target == target && _spec == spec;
    }
private:
    void Removed(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetId() == 9001778 && GetCaster())
            GetCaster()->RemoveAurasDueToSpell(9001802);
    }
    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_arch_continuity_ready::Removed,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

// A short-lived local guard, no map scan; removed with its owning readiness.
class aura_reborn_monk_calm_within : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_calm_within);
    void Check(AuraEffect const*)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Aura* ready = player ? player->GetAura(9001778) : nullptr;
        auto* script = ready ? ready->GetScript<aura_reborn_monk_arch_continuity_ready>("aura_reborn_monk_arch_continuity_ready") : nullptr;
        uint32 rank = player ? RebornMonkArchRank(player, 9001798) : 0;
        if (!player || !player->IsAlive() || !player->HasAura(9001552) || !rank ||
            !script || !script->CurrentFor(player))
        {
            Remove();
            return;
        }
        if (AuraEffect* effect = GetEffect(EFFECT_0))
            if (effect->GetAmount() > int32(10 * rank))
                effect->ChangeAmount(int32(10 * rank));
    }
    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_calm_within::Check,
            EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// This state belongs to this target's exact channel aura, not to a global player map.
class aura_reborn_monk_arch_mist_start : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_arch_mist_start);
    uint32 _bonus = 0;
    uint32 _threadBonus = 0;
    uint8 _spec = 0;
    uint8 _continuityPulses = 0;
    bool _continuityGranted = false;
    bool _recoveryEffective = false;
    bool _recoveryPaid = false;
    uint32 _recoveryRank = 0;
    uint32 _expectedTicks = 0;
    void Completed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (_recoveryPaid || !_recoveryEffective || !_recoveryRank || !_expectedTicks ||
            effect->GetTickNumber() < _expectedTicks ||
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        _recoveryPaid = true;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !player->IsAlive() || !GetTarget()->IsAlive() ||
            !player->HasAura(9001552) || player->GetActiveSpec() != _spec || player->HasAura(9001801))
            return;
        uint32 rank = std::min(_recoveryRank, RebornMonkActiveTalentRank(player, 9001793));
        if (!rank)
            return;
        player->CastSpell(player, 9001801, true);
        if (player->HasAura(9001801))
            player->EnergizeBySpell(player, 9001792 + rank, 2 * rank, POWER_ENERGY);
    }
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001764, 9001765, 9001767, 9001780, 9001781, 9001793, 9001794, 9001795, 9001801}); }
    void Started(AuraEffect const*, AuraEffectHandleModes)
    {
        _bonus = 0;
        _threadBonus = 0;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return;
        _spec = player->GetActiveSpec();
        _continuityPulses = 0;
        _continuityGranted = false;
        _recoveryEffective = false;
        _recoveryPaid = false;
        _recoveryRank = player->HasAura(9001552) ? RebornMonkActiveTalentRank(player, 9001793) : 0;
        AuraEffect const* periodic = GetEffect(EFFECT_0);
        _expectedTicks = periodic ? uint32(std::max<int32>(0, periodic->GetTotalTicks())) : 0;
        // Starting another channel resets both count and old target readiness.
        player->RemoveAurasDueToSpell(9001778);
        AuraEffect const* ready = player->GetAuraEffect(9001767, EFFECT_0);
        if (ready && player->HasAura(9001552))
            _bonus = std::min<uint32>(std::max<int32>(0, ready->GetAmount()),
                3 * RebornMonkArchRank(player, 9001764));
        // ARCH2C: snapshot only the matching target, then consume on channel start.
        if (player->getClass() == MONK_CLASS_ID && player->HasAura(9001552) &&
            player->HasTalent(9001780, _spec))
            if (Aura* thread = player->GetAura(9001781))
                if (auto* script = thread->GetScript<aura_reborn_monk_arch_continuity_ready>("aura_reborn_monk_arch_continuity_ready"))
                    if (script->Matches(GetOwner()->GetGUID(), _spec))
                        _threadBonus = 5;
        player->RemoveAurasDueToSpell(9001781);
        // Casting a new channel consumes readiness, even when the talent was reset.
        player->RemoveAurasDueToSpell(9001767);
    }
public:
    void RecordContinuityPulse(Unit* target)
    {
        // Caller is AfterHit and only calls this for effective primary healing.
        _recoveryEffective = true;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !target || !target->IsAlive() || _continuityGranted ||
            !player->HasAura(9001552) || player->GetActiveSpec() != _spec)
            return;
        uint32 rank = RebornMonkArchRank(player, 9001774);
        if (!rank)
            return;
        if (++_continuityPulses < 3)
            return;
        _continuityGranted = true;
        player->CastCustomSpell(9001778, SPELLVALUE_BASE_POINT0, int32(3 * rank), player, true);
        if (Aura* ready = player->GetAura(9001778))
            if (auto* script = ready->GetScript<aura_reborn_monk_arch_continuity_ready>("aura_reborn_monk_arch_continuity_ready"))
                script->Bind(target->GetGUID(), _spec);
    }
    uint32 ConsumeFirstBonus()
    {
        uint32 value = _bonus;
        uint32 threadValue = _threadBonus;
        _bonus = 0;
        _threadBonus = 0;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        AuraEffect const* periodic = GetEffect(EFFECT_0);
        if (!player || !player->HasAura(9001552) || player->GetActiveSpec() != _spec ||
            !periodic || periodic->GetTickNumber() != 1)
            return 0;
        // Sum once with Footwork; never multiply both bonuses or grant extra Chi.
        return std::min<uint32>(value, 3 * RebornMonkArchRank(player, 9001764)) +
            (player->getClass() == MONK_CLASS_ID && player->HasTalent(9001780, _spec) ? threadValue : 0);
    }
private:
    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_arch_mist_start::Completed,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_arch_mist_start::Started,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

// 9001505 - 滚地翻 / Roll
//
// The Roll movement itself is data-driven.  Spell 9001505 applies the original
// short periodic aura and triggers 9001506 (the port of 109132).  Its LEAP
// effect uses TARGET_DEST_TARGET_FRONT, so the core resolves every small step
// with MovePositionToFirstCollision just like the reference implementation.
// Keep only project-specific cast guards here; do not replace the native chain
// with MoveCharge, because that forces the 3.3.5 client into a run/charge state
// and suppresses the Roll animation.
//
// SpellVisual 22459 ultimately selects Animation 219 (CustomSpell07).  Aura
// application does not reliably start that one-shot animation on the 3.3.5
// client, so explicitly broadcast the matching Emotes.dbc row (408) once at
// cast start.  This changes only presentation; the DBC LEAP chain still owns
// movement and collision.
class spell_reborn_monk_roll : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_roll);

    static constexpr float ROLL_DISTANCE = 8.0f;
    static constexpr float MIN_USABLE_DISTANCE = 1.5f;

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player)
            return SPELL_FAILED_DONT_REPORT;

        if (player->IsMounted() || player->GetVehicleBase())
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;

        if (player->IsFlying() || player->IsFalling() || player->HasUnitState(UNIT_STATE_JUMPING))
            return SPELL_FAILED_NOT_ON_GROUND;

        if (player->HasUnitState(UNIT_STATE_ROOT))
            return SPELL_FAILED_ROOTED;

        Position const destination = player->GetFirstCollisionPosition(ROLL_DISTANCE, 0.0f);
        if (player->GetExactDist2d(destination) < MIN_USABLE_DISTANCE)
            return SPELL_FAILED_NOPATH;

        return SPELL_CAST_OK;
    }

    void PlayRollAnimation()
    {
        if (Player* player = GetCaster()->ToPlayer())
            player->HandleEmoteCommand(EMOTE_ONESHOT_CUSTOM_SPELL_07);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_roll::CheckCast);
        OnCast += SpellCastFn(spell_reborn_monk_roll::PlayRollAnimation);
    }
};

// 9001502 - 虎掌 / Tiger Palm
//
// Its verified actor kits select Animation 220 (CustomSpell08).  The DBC
// request is sufficient while idle, but continuous locomotion can suppress the
// one-shot on this client.  Re-broadcast only while moving so the already-good
// stationary presentation remains untouched.
class aura_reborn_monk_crane_momentum_ready : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_crane_momentum_ready);
    uint8 _spec = 0;
    bool _bound = false;
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr)
        {
            _spec = player->GetActiveSpec();
            _bound = true;
        }
    }
public:
    uint32 Bonus(Player* player) const
    {
        if (!player || !_bound || player->GetActiveSpec() != _spec || !player->HasAura(9001550))
            return 0;
        AuraEffect const* effect = GetEffect(EFFECT_0);
        return effect ? std::min<uint32>(std::max<int32>(0, effect->GetAmount()),
            2 * RebornMonkArchRank(player, 9001810)) : 0;
    }
private:
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_crane_momentum_ready::Applied,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

class spell_reborn_monk_tiger_palm_animation : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_tiger_palm_animation);

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    void PreserveMovingAnimation()
    {
        if (Player* player = GetCaster()->ToPlayer(); player && player->isMoving())
            player->HandleEmoteCommand(EMOTE_ONESHOT_CUSTOM_SPELL_08);
    }

    bool _momentumConsumed = false;
    void ConsumeMomentum()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (_momentumConsumed || !player || !player->IsAlive() || !GetHitUnit() || GetHitDamage() <= 0)
            return;
        Aura* ready = player->GetAura(9001812);
        if (!ready)
            return;
        auto* script = ready->GetScript<aura_reborn_monk_crane_momentum_ready>("aura_reborn_monk_crane_momentum_ready");
        uint32 amount = script ? script->Bonus(player) : 0;
        _momentumConsumed = true;
        player->RemoveAurasDueToSpell(9001812);
        if (amount)
            player->EnergizeBySpell(player, 9001809 + amount / 2, amount, POWER_ENERGY);
    }
    void PrepareBrew()
    {
        Unit* caster = GetCaster();
        if (!GetHitUnit() || GetHitDamage() <= 0 || !caster->HasAura(9001551))
            return;
        if (uint32 rank = RebornMonkArchRank(caster, 9001772))
            caster->CastCustomSpell(9001777, SPELLVALUE_BASE_POINT0, int32(3 * rank), caster, true);
    }

    WW4Cast _ww4;
    void WW4Start() { _ww4.Start(GetCaster(), GetSpellInfo()->Id); }
    void WW4Scale() { SetHitDamage(_ww4.Scale(GetCaster(), GetHitDamage())); }
    void WW4Hit() { _ww4.Hit(GetCaster(), GetSpellInfo()->Id, GetHitDamage()); }

    void Register() override
    {
        OnCast += SpellCastFn(spell_reborn_monk_tiger_palm_animation::PreserveMovingAnimation);
        AfterHit += SpellHitFn(spell_reborn_monk_tiger_palm_animation::PrepareBrew);
        AfterHit += SpellHitFn(spell_reborn_monk_tiger_palm_animation::ConsumeMomentum);
        OnCast += SpellCastFn(spell_reborn_monk_tiger_palm_animation::WW4Start);
        OnHit += SpellHitFn(spell_reborn_monk_tiger_palm_animation::WW4Scale);
        AfterHit += SpellHitFn(spell_reborn_monk_tiger_palm_animation::WW4Hit);
    }
};

// 9001507 - 幻灭踢 / Blackout Kick
//
// M6J7 returns presentation ownership to the single SpellVisual 22525 time
// line.  The matching CustomSpell06 actor sequence and purple arc must start
// together; server-side emote/VisualKit replays caused visible direction and
// timing drift.  Movement compatibility is tested in AnimationData.dbc, while
// this script remains responsible only for gameplay mechanics.
//
// Combat Conditioning behavior is based on the damage that actually landed:
// - caster behind the victim: 20% additional physical damage over 4 seconds;
// - otherwise: heal the caster for 20% of the dealt damage.
//
// M6K2 adds the gameplay resource loop without touching the proven actor
// animation chain.  Blackout Kick requires two stacks of the Chi aura.  The
// stacks are consumed only after real damage lands, so misses, dodges, parries
// and immune hits do not waste Chi.  Spell.dbc carries no Energy cost in this
// stage, preventing an unintended Energy + Chi double charge.
class spell_reborn_monk_blackout_kick : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_blackout_kick);

    bool _castFromBehind = false;
    bool _chiConsumed = false;

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo(
            { MONK_CHI_AURA_ID, MONK_BLACKOUT_KICK_DOT_ID, MONK_BLACKOUT_KICK_HEAL_ID });
    }

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    SpellCastResult CheckChi()
    {
        Player* player = GetCaster()->ToPlayer();
        Aura* chi = player ? player->GetAura(MONK_CHI_AURA_ID) : nullptr;
        if (!chi || chi->GetStackAmount() < MONK_BLACKOUT_KICK_CHI_COST)
            return SPELL_FAILED_NO_POWER;

        return SPELL_CAST_OK;
    }

    void CaptureCastContext()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();

        // Snapshot position before damage makes an idle creature turn toward
        // its attacker.  Checking this in AfterHit can turn a genuine rear
        // opener into a front hit simply because the victim has reacted.
        _castFromBehind = caster && target && target->isInBack(caster);

    }

    void ApplyCombatConditioning()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        int32 damage = _ww4.Derived(caster, GetHitDamage());
        if (!caster || !target || damage <= 0)
            return;

        // This uses the cast-start snapshot.  At this point an idle creature
        // may already have turned toward the player in response to the hit.
        if (_castFromBehind)
        {
            int32 tickDamage = std::max(CalculatePct(damage, 20) / 4, 1);
            target->CastDelayedSpellWithPeriodicAmount(
                caster,
                MONK_BLACKOUT_KICK_DOT_ID,
                SPELL_AURA_PERIODIC_DAMAGE,
                tickDamage,
                EFFECT_0);
        }
        else
        {
            int32 healing = std::max(CalculatePct(damage, 20), 1);
            caster->CastCustomSpell(
                MONK_BLACKOUT_KICK_HEAL_ID,
                SPELLVALUE_BASE_POINT0,
                healing,
                caster,
                TRIGGERED_FULL_MASK);
        }
    }

    void ConsumeChi()
    {
        if (_chiConsumed || !GetHitUnit() || GetHitDamage() <= 0)
            return;

        Player* player = GetCaster()->ToPlayer();
        Aura* chi = player ? player->GetAura(MONK_CHI_AURA_ID) : nullptr;
        if (!chi || chi->GetStackAmount() < MONK_BLACKOUT_KICK_CHI_COST)
            return;

        chi->ModStackAmount(-MONK_BLACKOUT_KICK_CHI_COST);
        _chiConsumed = true;
    }


    WW4Cast _ww4;
    void WW4Start() { _ww4.Start(GetCaster(), GetSpellInfo()->Id); }
    void WW4Scale() { SetHitDamage(_ww4.Scale(GetCaster(), GetHitDamage())); }
    void WW4Hit() { _ww4.Hit(GetCaster(), GetSpellInfo()->Id, GetHitDamage()); }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_blackout_kick::CheckChi);
        OnCast += SpellCastFn(spell_reborn_monk_blackout_kick::CaptureCastContext);
        AfterHit += SpellHitFn(spell_reborn_monk_blackout_kick::ApplyCombatConditioning);
        AfterHit += SpellHitFn(spell_reborn_monk_blackout_kick::ConsumeChi);
        OnCast += SpellCastFn(spell_reborn_monk_blackout_kick::WW4Start);
        OnHit += SpellHitFn(spell_reborn_monk_blackout_kick::WW4Scale);
        AfterHit += SpellHitFn(spell_reborn_monk_blackout_kick::WW4Hit);
    }
};

// M6L1: 9001516 - Spear Hand Strike. The native effect owns interrupt/lockout.
class spell_reborn_monk_spear_hand_strike : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_spear_hand_strike);
    bool _targetFacingCaster = false;

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ 9001517 });
    }

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    void CaptureFacing()
    {
        Unit* target = GetExplTargetUnit();
        _targetFacingCaster = target && target->isInFront(GetCaster());
    }

    void ApplyFrontalSilence(SpellEffIndex /*effIndex*/)
    {
        // Effect-hit hook does not depend on damage: this ability deals none.
        // A separate silence spell retains native silence immunity and DR checks.
        if (_targetFacingCaster && GetHitUnit() && GetHitUnit()->IsAlive())
            GetCaster()->CastSpell(GetHitUnit(), 9001517, true);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_reborn_monk_spear_hand_strike::CaptureFacing);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_monk_spear_hand_strike::ApplyFrontalSilence, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};

// M6M2: PRO Windwalker resource/cooldown policy for the proven Fury visual.
// Channeled abilities pay once when the accepted cast starts. Cancellation
// does not refund Chi, and triggered ticks never charge the resource again.
class spell_reborn_monk_fists_of_fury : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_fists_of_fury);

    static constexpr uint8 CHI_COST = 3;
    bool _chiConsumed = false;

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ MONK_CHI_AURA_ID, 9001519 });
    }

    bool Load() override
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID;
    }

    SpellCastResult CheckChi()
    {
        Aura* chi = GetCaster()->GetAura(MONK_CHI_AURA_ID);
        return chi && chi->GetStackAmount() >= CHI_COST
            ? SPELL_CAST_OK : SPELL_FAILED_NO_POWER;
    }

    void ConsumeChi()
    {
        if (_chiConsumed)
            return;

        if (Aura* chi = GetCaster()->GetAura(MONK_CHI_AURA_ID))
        {
            if (chi->GetStackAmount() >= CHI_COST)
            {
                chi->ModStackAmount(-CHI_COST);
                _chiConsumed = true;
            }
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_fists_of_fury::CheckChi);
        OnCast += SpellCastFn(spell_reborn_monk_fists_of_fury::ConsumeChi);
    }
};

// MONKWW2: completion is owned by the parent channel, never a damage target.
class aura_reborn_monk_fists_recovery : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_fists_recovery);
    uint32 _rank = 0;
    uint32 _expectedTicks = 0;
    uint8 _spec = 0;
    bool _paid = false;
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001820, 9001821, 9001822, 9001823});
    }
    void Started(AuraEffect const* effect, AuraEffectHandleModes)
    {
        _rank = 0;
        _paid = false;
        _expectedTicks = uint32(std::max<int32>(0, effect->GetTotalTicks()));
        if (Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr)
        {
            _spec = player->GetActiveSpec();
            if (player->getClass() == MONK_CLASS_ID && player->HasAura(9001550))
                _rank = RebornMonkActiveTalentRank(player, 9001820);
        }
    }
    void Completed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (_paid || !_rank || !_expectedTicks || effect->GetTickNumber() < _expectedTicks ||
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        _paid = true;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !player->IsAlive() || !player->HasAura(9001550) ||
            player->GetActiveSpec() != _spec || player->HasAura(9001823))
            return;
        uint32 rank = std::min(_rank, RebornMonkActiveTalentRank(player, 9001820));
        if (!rank)
            return;
        player->CastSpell(player, 9001823, true);
        if (player->HasAura(9001823))
            player->EnergizeBySpell(player, 9001819 + rank, 2 * rank, POWER_ENERGY);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_fists_recovery::Started,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_fists_recovery::Completed,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

// M6N1: conditional absorption at the core's school-absorb stage.
// Threshold uses remaining damage at this stage (after armor/resistance and
// any earlier shields). Charges are consumed only after actual absorption.
class spell_reborn_monk_dampen_harm : public AuraScript
{
    PrepareAuraScript(spell_reborn_monk_dampen_harm);

    void CalculateAmount(AuraEffect const* /*effect*/, int32& amount, bool& canBeRecalculated)
    {
        amount = -1; // Script-managed capacity, not a finite damage pool.
        canBeRecalculated = false;
    }

    void Absorb(AuraEffect* /*effect*/, DamageInfo& damageInfo, uint32& absorbAmount)
    {
        absorbAmount = 0;
        uint32 damage = damageInfo.GetDamage();
        uint32 maxHealth = GetTarget()->GetMaxHealth();
        if (!GetAura()->GetCharges() || !damage || !maxHealth)
            return;

        // MONKM3I: lower the trigger threshold, preserving absorption and charges.
        uint32 thresholdPct = 20u - 2u * RebornMonkActiveTalentRank(GetTarget(), 9001663);
        // Compare remaining damage at the absorb stage without rounding the threshold.
        if (uint64(damage) * 100u < uint64(maxHealth) * thresholdPct)
            return;

        // MONKM3J: 50/52/54/56%, with wide multiplication and unchanged charges.
        uint32 absorbPct = 50u + 2u * RebornMonkActiveTalentRank(GetTarget(), 9001673);
        absorbAmount = uint32(uint64(damage) * absorbPct / 100u);
    }

    void AfterAbsorb(AuraEffect* /*effect*/, DamageInfo& /*damageInfo*/, uint32& absorbAmount)
    {
        if (absorbAmount > 0)
            GetAura()->DropCharge(); // Third successful absorption removes aura.
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_reborn_monk_dampen_harm::CalculateAmount, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_reborn_monk_dampen_harm::Absorb, EFFECT_0);
        AfterEffectAbsorb += AuraEffectAbsorbFn(spell_reborn_monk_dampen_harm::AfterAbsorb, EFFECT_0);
    }
};

// M6O1: cleanse once after the friendly speed aura was successfully applied.
// Newly applied roots/snares are not prevented during the speed buff.
class spell_reborn_monk_tigers_lust : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_tigers_lust);

    void RemoveImpairments()
    {
        Unit* target = GetHitUnit();
        if (target && GetHitAura())
            target->RemoveMovementImpairingAuras(true);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_reborn_monk_tigers_lust::RemoveImpairments);
    }
};

// M6S2: native aura handles CC, one-target ownership, damage break and DR.
// Snapshot facing before an idle creature reacts to the hostile spell.
class spell_reborn_monk_paralysis : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_paralysis);
    bool _castFromBehind = false;

    void CaptureCastContext()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();
        _castFromBehind = caster && target && target->isInBack(caster);
    }

    void ExtendCreatureDuration()
    {
        Unit* target = GetHitUnit();
        Aura* aura = GetHitAura();
        // Do not undo player/PvP diminishing or its duration cap.
        if (!_castFromBehind || !target || target->GetAffectingPlayer() || !aura)
            return;
        int32 duration = aura->GetDuration();
        if (duration <= 0)
            return;
        duration += duration / 2;
        aura->SetMaxDuration(duration);
        aura->SetDuration(duration);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_reborn_monk_paralysis::CaptureCastContext);
        AfterHit += SpellHitFn(spell_reborn_monk_paralysis::ExtendCreatureDuration);
    }
};

// M6V1: keep native threat matching/taunt; reject non-threat-list targets.
class spell_reborn_monk_provoke : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_provoke);

    SpellCastResult CheckTarget()
    {
        Unit* target = GetExplTargetUnit();
        if (!target || !target->IsAlive() || target->GetAffectingPlayer() || !target->CanHaveThreatList())
            return SPELL_FAILED_BAD_TARGETS;
        return SPELL_CAST_OK;
    }

    void KeepSpeedWithTaunt()
    {
        Unit* target = GetHitUnit();
        Aura* aura = GetHitAura();
        if (!target || !aura)
            return;
        AuraApplication const* application = aura->GetApplicationOfTarget(target->GetGUID());
        // If native immunity rejects the taunt aura, do not leave only a speed buff.
        if (!application || !application->HasEffect(EFFECT_1))
            aura->Remove();
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_provoke::CheckTarget);
        AfterHit += SpellHitFn(spell_reborn_monk_provoke::KeepSpeedWithTaunt);
    }
};

// M6W1: native periodic energize handles ticks/capping; only gate the cast here.
class spell_reborn_monk_energizing_brew : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_energizing_brew);

    SpellCastResult CheckCombat()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID || !player->IsAlive())
            return SPELL_FAILED_BAD_TARGETS;
        if (!player->IsInCombat())
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        return SPELL_CAST_OK;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_energizing_brew::CheckCombat);
    }
};

// M6X1: snapshot pre-hit snares; the first successful slow must not root itself.
class spell_reborn_monk_disable : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_disable);
    bool _wasSlowed = false;

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ 9001530 });
    }

    void SnapshotSlow(SpellMissInfo missInfo)
    {
        Unit* target = GetHitUnit();
        _wasSlowed = missInfo == SPELL_MISS_NONE && target &&
            target->HasAuraType(SPELL_AURA_MOD_DECREASE_SPEED);
    }

    void ApplyRoot()
    {
        Unit* target = GetHitUnit();
        Aura* aura = GetHitAura();
        if (!target || !aura)
            return;
        AuraApplication const* application = aura->GetApplicationOfTarget(target->GetGUID());
        // Do not leave an endlessly refreshing dummy aura on a slow-immune target.
        if (!application || !application->HasEffect(EFFECT_0))
        {
            aura->Remove();
            return;
        }
        if (_wasSlowed && target->IsAlive())
            GetCaster()->CastSpell(target, 9001530, true);
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_reborn_monk_disable::SnapshotSlow);
        AfterHit += SpellHitFn(spell_reborn_monk_disable::ApplyRoot);
    }
};

class aura_reborn_monk_disable : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_disable);

    void RefreshNearby(AuraEffect const*)
    {
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (caster && target && caster->IsAlive() && target->IsAlive() &&
            caster->IsWithinDistInMap(target, 10.0f))
            GetAura()->SetDuration(GetAura()->GetMaxDuration());
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_disable::RefreshNearby,
            EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
    }
};

// MONKWW3: independent completion reward, does not share Crane Momentum's gate.
class aura_reborn_monk_crane_rebound_speed : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_crane_rebound_speed);
    uint8 _spec = 0;
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr)
            _spec = player->GetActiveSpec();
    }
    void Guard(AuraEffect const*)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        uint32 rank = player ? RebornMonkArchRank(player, 9001830) : 0;
        if (!player || !player->IsAlive() || !rank || !player->HasAura(9001550) || player->GetActiveSpec() != _spec)
        {
            Remove();
            return;
        }
        if (AuraEffect* effect = GetEffect(EFFECT_0))
            if (effect->GetAmount() > int32(5 * rank))
                effect->ChangeAmount(int32(5 * rank));
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_crane_rebound_speed::Applied,
            EFFECT_0, SPELL_AURA_MOD_INCREASE_SPEED, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_crane_rebound_speed::Guard,
            EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
    }
};

class aura_reborn_monk_crane_rebound : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_crane_rebound);
    uint32 _rank = 0;
    uint32 _ticks = 0;
    uint8 _spec = 0;
    bool _paid = false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001830, 9001831, 9001832}); }
    void Started(AuraEffect const* effect, AuraEffectHandleModes)
    {
        _paid = false;
        _rank = 0;
        _ticks = uint32(std::max<int32>(0, effect->GetTotalTicks()));
        if (Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr)
        {
            _spec = player->GetActiveSpec();
            if (player->HasAura(9001550))
                _rank = RebornMonkArchRank(player, 9001830);
        }
    }
    void Completed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (_paid || !_rank || !_ticks || effect->GetTickNumber() < _ticks ||
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        _paid = true;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !player->IsAlive() || !player->HasAura(9001550) || player->GetActiveSpec() != _spec)
            return;
        uint32 rank = std::min(_rank, RebornMonkArchRank(player, 9001830));
        if (rank)
            player->CastCustomSpell(9001832, SPELLVALUE_BASE_POINT0, int32(5 * rank), player, true);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_crane_rebound::Started,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_crane_rebound::Completed,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

// M6Y1: the aura owns one cast's hit set; no global or cross-player state.
class aura_reborn_monk_spinning_crane_kick : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_spinning_crane_kick);
    uint32 _momentumRank = 0;
    uint32 _expectedTicks = 0;
    uint8 _momentumSpec = 0;
    bool _momentumGranted = false;
    void Started(AuraEffect const* effect, AuraEffectHandleModes)
    {
        _momentumGranted = false;
        _momentumRank = 0;
        _expectedTicks = uint32(std::max<int32>(0, effect->GetTotalTicks()));
        if (Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr)
        {
            _momentumSpec = player->GetActiveSpec();
            if (player->HasAura(9001550))
                _momentumRank = RebornMonkArchRank(player, 9001810);
        }
    }
    void Completed(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (_momentumGranted || !_momentumRank || !_expectedTicks ||
            effect->GetTickNumber() < _expectedTicks ||
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        _momentumGranted = true;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !player->IsAlive() || !player->HasAura(9001550) ||
            player->GetActiveSpec() != _momentumSpec || player->HasAura(9001813))
            return;
        uint32 rank = std::min(_momentumRank, RebornMonkArchRank(player, 9001810));
        if (!rank)
            return;
        player->CastSpell(player, 9001813, true);
        if (player->HasAura(9001813))
            player->CastCustomSpell(9001812, SPELLVALUE_BASE_POINT0, int32(2 * rank), player, true);
    }
    std::set<ObjectGuid> _damagedTargets;
    bool _chiGranted = false;
public:
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ MONK_CHI_AURA_ID, 9001532, 9001810, 9001811, 9001812, 9001813 });
    }

    void RecordDamage(Unit* target)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (_chiGranted || !target || !player || player->getClass() != MONK_CLASS_ID)
            return;
        _damagedTargets.insert(target->GetGUID());
        if (_damagedTargets.size() < 3)
            return;
        _chiGranted = true; // Reaching the cap never banks an extra award.
        if (Aura* chi = player->GetAura(MONK_CHI_AURA_ID))
        {
            if (chi->GetStackAmount() < 4)
                chi->ModStackAmount(1);
        }
        else
            player->CastSpell(player, MONK_CHI_AURA_ID, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_spinning_crane_kick::Started,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_spinning_crane_kick::Completed,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_reborn_monk_spinning_crane_kick : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_spinning_crane_kick);
    SpellCastResult CheckChannel()
    {
        return (GetCaster()->HasAura(9001531) || GetCaster()->HasAura(9001538) || GetCaster()->HasAura(9001541)) ? SPELL_FAILED_SPELL_IN_PROGRESS : SPELL_CAST_OK;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_spinning_crane_kick::CheckChannel);
    }
};

class spell_reborn_monk_spinning_crane_pulse : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_spinning_crane_pulse);
    void RecordHit()
    {
        if (!GetHitUnit() || GetHitDamage() <= 0)
            return; // Miss/dodge/parry/immunity/fully absorbed damage earns no Chi.
        if (Aura* channel = GetCaster()->GetAura(9001531))
            if (auto* script = channel->GetScript<aura_reborn_monk_spinning_crane_kick>(
                "aura_reborn_monk_spinning_crane_kick"))
                script->RecordDamage(GetHitUnit());
    }
    void Register() override
    {
        AfterHit += SpellHitFn(spell_reborn_monk_spinning_crane_pulse::RecordHit);
    }
};

// M6Z1: remove only the supported mechanics; do not use a full PvP-trinket mask.
class spell_reborn_monk_nimble_brew : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_nimble_brew);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ 9001534 });
    }
    void Cleanse()
    {
        constexpr uint64 mask = (1ULL << MECHANIC_ROOT) | (1ULL << MECHANIC_STUN) |
            (1ULL << MECHANIC_FEAR) | (1ULL << MECHANIC_HORROR) | (1ULL << MECHANIC_TURN);
        GetCaster()->RemoveAurasWithMechanic(mask, AURA_REMOVE_BY_DEFAULT, 9001533);
    }
    void AddHorrorProtection()
    {
        if (GetHitAura())
            GetCaster()->CastSpell(GetCaster(), 9001534, true);
    }
    void Register() override
    {
        OnCast += SpellCastFn(spell_reborn_monk_nimble_brew::Cleanse);
        AfterHit += SpellHitFn(spell_reborn_monk_nimble_brew::AddHorrorProtection);
    }
};

class aura_reborn_monk_nimble_brew : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_nimble_brew);
    void Cleanup(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(9001534);
    }
    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_nimble_brew::Cleanup,
            EFFECT_0, SPELL_AURA_MECHANIC_DURATION_MOD_NOT_STACK, AURA_EFFECT_HANDLE_REAL);
    }
};

// M6AA1: native forward-motion aura; the client retains normal world collision.
class spell_reborn_monk_flying_serpent_kick : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_flying_serpent_kick);
    SpellCastResult CheckStart()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID || player->IsMounted() || player->GetVehicleBase())
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        if (player->IsFlying() || player->IsFalling() || player->IsInWater() || player->HasUnitState(UNIT_STATE_JUMPING))
            return SPELL_FAILED_NOT_ON_GROUND;
        if (player->HasUnitState(UNIT_STATE_ROOT))
            return SPELL_FAILED_ROOTED;
        if (player->HasAura(9001535))
            return SPELL_FAILED_SPELL_IN_PROGRESS;
        Position const next = player->GetFirstCollisionPosition(1.5f, 0.0f);
        return player->GetExactDist2d(next) < 0.5f ? SPELL_FAILED_NOPATH : SPELL_CAST_OK;
    }
    void Start()
    {
        GetCaster()->AttackStop();
        GetCaster()->HandleEmoteCommand(EMOTE_ONESHOT_CUSTOM_SPELL_04);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_flying_serpent_kick::CheckStart);
        OnCast += SpellCastFn(spell_reborn_monk_flying_serpent_kick::Start);
    }
};

class aura_reborn_monk_flying_serpent_kick : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_flying_serpent_kick);
    bool _landed = false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({ 9001536 }); }
    void CheckMovement(AuraEffect const*)
    {
        Unit* target = GetTarget();
        if (!target->IsAlive() || target->IsInWater() || target->IsFalling() || target->IsMounted() ||
            target->GetVehicleBase() || target->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_FLEEING | UNIT_STATE_CONFUSED))
        {
            GetAura()->Remove(AURA_REMOVE_BY_DEFAULT);
            return;
        }
        Position const next = target->GetFirstCollisionPosition(1.5f, 0.0f);
        if (target->GetExactDist2d(next) < 0.5f)
            GetAura()->Remove(AURA_REMOVE_BY_CANCEL);
    }
    void Land(AuraEffect const*, AuraEffectHandleModes)
    {
        AuraRemoveMode mode = GetTargetApplication()->GetRemoveMode();
        Unit* target = GetTarget();
        if (_landed || (mode != AURA_REMOVE_BY_EXPIRE && mode != AURA_REMOVE_BY_CANCEL) ||
            !target->IsAlive() || target->IsFalling() || target->IsInWater() ||
            target->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_FLEEING | UNIT_STATE_CONFUSED))
            return;
        _landed = true;
        target->CastSpell(target, 9001536, true);
    }
    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_flying_serpent_kick::CheckMovement, EFFECT_2, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_flying_serpent_kick::Land,
            EFFECT_1, SPELL_AURA_FORCE_MOVE_FORWARD, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_reborn_monk_flying_serpent_land : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_flying_serpent_land);
    void Damage(SpellEffIndex)
    {
        SetEffectValue(1 + int32(std::max(0.0f, GetCaster()->GetTotalAttackPowerValue(BASE_ATTACK)) * 0.45f));
    }
    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_flying_serpent_land::Damage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};


// M6AC1: independent per-cast state, no world-wide scan or per-player timer.
class aura_reborn_monk_jade_wind : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_jade_wind);
    std::set<ObjectGuid> _targets;
    bool _granted = false;
public:
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001539, MONK_CHI_AURA_ID}); }
    void RecordDamage(Unit* target)
    {
        Player* caster = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (_granted || !target || !caster || caster->getClass() != MONK_CLASS_ID)
            return;
        _targets.insert(target->GetGUID());
        if (_targets.size() < 3)
            return;
        _granted = true; // A full Chi bar never banks a later grant.
        if (Aura* chi = caster->GetAura(MONK_CHI_AURA_ID))
        {
            if (chi->GetStackAmount() < 4)
                chi->ModStackAmount(1);
        }
        else
            caster->CastSpell(caster, MONK_CHI_AURA_ID, true);
    }
    void Register() override { }
};

class spell_reborn_monk_jade_wind : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_jade_wind);
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID)
            return SPELL_FAILED_BAD_TARGETS;
        return player->HasAura(9001538) || player->HasAura(9001531) || player->HasAura(9001541)
            ? SPELL_FAILED_SPELL_IN_PROGRESS : SPELL_CAST_OK;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_reborn_monk_jade_wind::Check); }
};

class spell_reborn_monk_jade_wind_pulse : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_jade_wind_pulse);
    void Hit()
    {
        if (!GetHitUnit() || GetHitDamage() <= 0)
            return;
        if (Aura* wind = GetCaster()->GetAura(9001538))
            if (auto* script = wind->GetScript<aura_reborn_monk_jade_wind>("aura_reborn_monk_jade_wind"))
                script->RecordDamage(GetHitUnit());
    }
    void Register() override { AfterHit += SpellHitFn(spell_reborn_monk_jade_wind_pulse::Hit); }
};

class spell_reborn_monk_guard : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_guard);
    bool _spent = false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MONK_CHI_AURA_ID}); }
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID)
            return SPELL_FAILED_BAD_TARGETS;
        Aura* chi = player->GetAura(MONK_CHI_AURA_ID);
        return chi && chi->GetStackAmount() >= 2 ? SPELL_CAST_OK : SPELL_FAILED_NO_POWER;
    }
    void Spend()
    {
        if (_spent || !GetHitAura())
            return; // Failed application does not spend the emulated resource.
        if (Aura* chi = GetCaster()->GetAura(MONK_CHI_AURA_ID))
        {
            if (chi->GetStackAmount() >= 2)
            {
                uint32 rank = RebornMonkActiveTalentRank(GetCaster(), 9001683);
                uint32 chance = 10u * rank + RebornMonkStanceEconomyChance(GetCaster(), 9001722, 9001551);
                // One combined roll: at most one Chi saved, and no relaxed cast requirement.
                bool saveChi = chance && roll_chance_i(chance);
                chi->ModStackAmount(saveChi ? -1 : -2);
                _spent = true;
            }
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_guard::Check);
        AfterHit += SpellHitFn(spell_reborn_monk_guard::Spend);
    }
};

// MONKBW1: only real damage exhausting Guard can grant Lingering Guard.
class aura_reborn_monk_lingering_guard : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_lingering_guard);
    uint8 _spec = 0;
    uint32 _rank = 0;
    bool _paid = false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001860,9001861,9001862,9001863}); }
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        _paid = false;
        Player* p = GetTarget()->ToPlayer();
        _spec = p ? p->GetActiveSpec() : 0;
        _rank = p && p->HasAura(9001551) ? RebornMonkArchRank(p,9001860) : 0;
    }
    void AfterAbsorb(AuraEffect* effect, DamageInfo&, uint32& absorbed)
    {
        // In this core AfterAbsorb runs before remaining capacity is decremented.
        // Removal reason alone cannot distinguish dispelling from shield damage.
        if (_paid || !_rank || effect->GetAmount() <= 0 || absorbed < uint32(effect->GetAmount())) return;
        _paid = true;
        Player* p = GetTarget()->ToPlayer();
        if (!p || p->getClass()!=14 || !p->IsAlive() || p->GetActiveSpec()!=_spec ||
            !p->HasAura(9001551) || p->HasAura(9001863)) return;
        uint32 rank = std::min(_rank,RebornMonkArchRank(p,9001860));
        if (!rank) return;
        p->CastSpell(p,9001863,true);
        p->CastCustomSpell(9001862,SPELLVALUE_BASE_POINT0,-int32(2*rank),p,true);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_lingering_guard::Applied,EFFECT_0,SPELL_AURA_SCHOOL_ABSORB,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_monk_lingering_guard::AfterAbsorb,EFFECT_0);
    }
};
class aura_reborn_monk_lingering_guard_buff : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_lingering_guard_buff);
    uint8 _spec = 0;
    void Applied(AuraEffect const*,AuraEffectHandleModes)
    {
        if (Player* p=GetTarget()->ToPlayer()) _spec=p->GetActiveSpec();
    }
    void Guard(AuraEffect const*)
    {
        Player* p=GetTarget()->ToPlayer();
        uint32 rank=p ? RebornMonkArchRank(p,9001860) : 0;
        if (!p || p->getClass()!=14 || !p->IsAlive() || p->GetActiveSpec()!=_spec || !p->HasAura(9001551) || !rank)
        { Remove(); return; }
        if (AuraEffect* effect=GetEffect(EFFECT_0))
            if (effect->GetAmount() < -int32(2*rank)) effect->ChangeAmount(-int32(2*rank));
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_lingering_guard_buff::Applied,EFFECT_0,SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_lingering_guard_buff::Guard,EFFECT_1,SPELL_AURA_PERIODIC_DUMMY);
    }
};

class aura_reborn_monk_guard : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_guard);
    uint32 _brewBonus = 0;
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        if (_brewBonus && GetCaster())
            GetCaster()->RemoveAurasDueToSpell(9001777);
        _brewBonus = 0;
    }
    void Capacity(AuraEffect const*, int32& amount, bool& recalculate)
    {
        recalculate = false;
        Unit* caster = GetCaster();
        if (!caster) { amount = 0; return; }
        double capacity = double(caster->GetMaxHealth()) * 0.20 +
            double(std::max(0.0f, caster->GetTotalAttackPowerValue(BASE_ATTACK))) * 1.50;
        amount = int32(std::min(2147483647.0, std::max(1.0, capacity)));
        amount = RebornMonkScaleTalentValue(caster, amount, 9001653);
        amount = RebornMonkScaleResolve(caster, amount, 9001711, 9001551, 10);
        _brewBonus = 0;
        if (caster->HasAura(9001551))
            if (AuraEffect const* ready = caster->GetAuraEffect(9001777, EFFECT_0))
                _brewBonus = std::min<uint32>(std::max<int32>(0, ready->GetAmount()),
                    3 * RebornMonkArchRank(caster, 9001772));
        amount = int32(std::min<int64>(2147483647, int64(amount) * (100 + _brewBonus) / 100));
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_monk_guard::Capacity, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_guard::Applied, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

class spell_reborn_monk_zen : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_zen);
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID)
            return SPELL_FAILED_BAD_TARGETS;
        if (player->isMoving())
            return SPELL_FAILED_MOVING;
        return player->HasAura(9001538) || player->HasAura(9001531) || player->HasAura(9001541)
            ? SPELL_FAILED_SPELL_IN_PROGRESS : SPELL_CAST_OK;
    }
    void StopSwing() { GetCaster()->AttackStop(); }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_zen::Check);
        OnCast += SpellCastFn(spell_reborn_monk_zen::StopSwing);
    }
};

class aura_reborn_monk_zen : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_zen);
    bool Check(ProcEventInfo& event)
    {
        // Landed melee only; magic, ranged, DoTs, misses and avoidance do not break it.
        return event.GetDamageInfo() && event.GetDamageInfo()->GetDamageType() != DOT &&
            (event.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS)) &&
            (event.GetHitMask() & (PROC_HIT_NORMAL | PROC_HIT_CRITICAL | PROC_HIT_ABSORB | PROC_HIT_BLOCK));
    }
    void Break(ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        Spell* channel = target->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
        bool ownChannel = channel && channel->GetSpellInfo()->Id == 9001541;
        Remove();
        if (ownChannel)
            target->InterruptSpell(CURRENT_CHANNELED_SPELL);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_reborn_monk_zen::Check);
        OnProc += AuraProcFn(aura_reborn_monk_zen::Break);
    }
};


// M6AD1: keep emulated Chi bounded, including when only one free slot remains.
namespace
{
void RebornMonkAddChi(Unit* unit, uint8 count)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    if (!player || player->getClass() != MONK_CLASS_ID || !count)
        return;
    if (Aura* chi = player->GetAura(MONK_CHI_AURA_ID))
    {
        uint8 current = chi->GetStackAmount();
        if (current < 4)
            chi->ModStackAmount(std::min<uint8>(count, 4 - current));
    }
    else
    {
        player->CastSpell(player, MONK_CHI_AURA_ID, true);
        if (Aura* chi = player->GetAura(MONK_CHI_AURA_ID))
            chi->SetStackAmount(std::min<uint8>(count, 4));
    }
}

// H6: dedicated healing gear route; no attack-power fallback.
double RebornMonkHealingPower(Unit* caster)
{
    if (!caster) return 0.0;
    double healing = std::max<int32>(0, caster->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE));
    return healing;
}
int32 RebornMonkHealingValue(Unit* caster, double ratio, double perLevel)
{
    if (!caster) return 0;
    double value = RebornMonkHealingPower(caster) * ratio +
        double(std::min<uint32>(80, caster->GetLevel())) * perLevel;
    return int32(std::max(1.0, std::min(double(INT32_MAX), value)));
}

int32 RebornMonkPowerValue(Unit* caster, double ratio, double perLevel)
{
    double value = double(std::max(0.0f, caster->GetTotalAttackPowerValue(BASE_ATTACK))) * ratio +
        double(caster->GetLevel()) * perLevel;
    return int32(std::max(1.0, std::min(2147483647.0, value)));
}
}

// Shared by the two new normal stationary channels. Existing channels are untouched.
class spell_reborn_monk_mist_channel : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_mist_channel);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001543,9001547,MONK_CHI_AURA_ID}); }
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID)
            return SPELL_FAILED_BAD_TARGETS;
        if (player->isMoving())
            return SPELL_FAILED_MOVING;
        if (player->HasAura(9001541))
            return SPELL_FAILED_SPELL_IN_PROGRESS;
        return SPELL_CAST_OK;
    }
    void StopSwing() { GetCaster()->AttackStop(); }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_mist_channel::Check);
        OnCast += SpellCastFn(spell_reborn_monk_mist_channel::StopSwing);
    }
};

// An orphaned/late triggered pulse cannot continue after its channel has ended.
class spell_reborn_monk_jade_lightning_pulse : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_jade_lightning_pulse);
    SpellCastResult Check()
    {
        Spell* channel = GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID && player->HasSpell(9001542) &&
            channel && channel->GetSpellInfo()->Id == 9001542 &&
            channel->m_targets.GetUnitTarget() == GetExplTargetUnit()
            ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }
    void Damage(SpellEffIndex)
    {
        SetEffectValue(RebornMonkPowerValue(GetCaster(), 0.40, 2.0));
    }
    void Chi()
    {
        if (GetHitUnit() && GetHitDamage() > 0 && roll_chance_i(30))
            RebornMonkAddChi(GetCaster(), 1);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_jade_lightning_pulse::Check);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_jade_lightning_pulse::Damage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(spell_reborn_monk_jade_lightning_pulse::Chi);
    }
};

class spell_reborn_monk_chi_brew : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_chi_brew);
    bool _granted = false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MONK_CHI_AURA_ID}); }
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID)
            return SPELL_FAILED_BAD_TARGETS;
        Aura* chi = player->GetAura(MONK_CHI_AURA_ID);
        return chi && chi->GetStackAmount() >= 4 ? SPELL_FAILED_ALREADY_AT_FULL_POWER : SPELL_CAST_OK;
    }
    void Restore(SpellEffIndex)
    {
        if (!_granted && GetHitUnit() == GetCaster())
        {
            _granted = true;
            RebornMonkAddChi(GetCaster(), 2);
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_chi_brew::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_monk_chi_brew::Restore, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_reborn_monk_soothing_pulse : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_soothing_pulse);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001784, 9001785, 9001786, 9001796, 9001797, 9001800});
    }
    void ShareHealing()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Unit* primary = GetHitUnit();
        if (!player || !primary || !player->IsAlive() || !primary->IsAlive() ||
            GetHitHeal() <= 0 || !player->HasAura(9001552) || player->HasAura(9001786))
            return;
        uint32 rank = RebornMonkArchRank(player, 9001784);
        auto member = [player](Unit* unit)
        {
            if (!unit || !unit->IsInWorld() || !player->InSamePhase(unit) || !player->IsInRaidWith(unit))
                return false;
            Unit* owner = unit->GetCharmerOrOwnerOrSelf();
            if (owner->IsPlayer()) return true; // Humans, Playerbots, and their pets.
#ifdef MOD_NPCERBOTS
            if (unit->IsNPCBotOrPet() || owner->IsNPCBot()) return true;
#endif
            return false;
        };
        if (!rank || !member(primary) || !player->IsValidAssistTarget(primary))
            return;
        uint32 shelter = rank == 2 ? RebornMonkArchRank(player, 9001796) : 0;
        // Keep precision until the final division: 6% * 1.2 = 7.2%.
        uint32 amount = uint32(uint64(GetHitHeal()) * (3 * rank) * (100 + 10 * shelter) / 10000);
        if (!amount)
            return;
        uint32 targetLimit = 1;
        if (Aura* masteryAura = player->GetAura(9001800))
            if (auto* masteryScript = masteryAura->GetScript<aura_reborn_monk_mist_mastery>("aura_reborn_monk_mist_mastery"))
                if (masteryScript->ActiveFor(player))
                    targetLimit = 2;
        std::vector<Unit*> candidates;
        std::list<Unit*> nearby;
        // Local 8-yard search includes Creature-based NPCbots, unlike GroupReference.
        Acore::AnyUnitInObjectRangeCheck rangeCheck(primary, 8.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(primary, nearby, rangeCheck);
        Cell::VisitObjects(primary, searcher, 8.0f);
        for (Unit* candidate : nearby)
        {
            if (!member(candidate) || candidate == primary || !candidate->IsAlive() ||
                candidate->GetHealth() >= candidate->GetMaxHealth() ||
                !primary->IsWithinDistInMap(candidate, 8.0f) ||
                !player->IsValidAssistTarget(candidate) || !primary->IsWithinLOSInMap(candidate) ||
                !player->IsWithinLOSInMap(candidate))
                continue;
            if (std::find(candidates.begin(), candidates.end(), candidate) == candidates.end())
                candidates.push_back(candidate);
        }
        SpellInfo const* info = sSpellMgr->GetSpellInfo(9001783 + rank);
        if (candidates.empty() || !info)
            return;
        std::sort(candidates.begin(), candidates.end(), [](Unit* a, Unit* b)
        {
            uint64 lhs = uint64(a->GetHealth()) * b->GetMaxHealth();
            uint64 rhs = uint64(b->GetHealth()) * a->GetMaxHealth();
            return lhs < rhs || (lhs == rhs && a->GetGUID() < b->GetGUID());
        });
        // Commit the 1-second gate before healing. It survives channel restarts.
        player->CastSpell(player, 9001786, true);
        if (!player->HasAura(9001786))
            return;
        // Source is actual primary healing: no second crit, SP scaling or proc chain.
        uint32 paid = 0;
        for (Unit* chosen : candidates)
        {
            if (paid >= targetLimit)
                break;
            if (!chosen->IsInWorld() || !chosen->IsAlive() || !member(chosen) ||
                chosen->GetHealth() >= chosen->GetMaxHealth() ||
                !primary->IsWithinDistInMap(chosen, 8.0f) || !primary->IsWithinLOSInMap(chosen) ||
                !player->IsWithinLOSInMap(chosen) || !player->IsValidAssistTarget(chosen))
                continue;
            HealInfo heal(player, chosen, amount, info, info->GetSchoolMask());
            player->HealBySpell(heal);
            ++paid;
        }
    }
    SpellCastResult Check()
    {
        Spell* channel = GetCaster()->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
        Player* player = GetCaster()->ToPlayer();
        return player && player->getClass() == MONK_CLASS_ID && player->HasSpell(9001546) &&
            channel && channel->GetSpellInfo()->Id == 9001546 &&
            channel->m_targets.GetUnitTarget() == GetExplTargetUnit()
            ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }
    void Healing(SpellEffIndex)
    {
        int32 value = RebornMonkHealingValue(GetCaster(), 0.30, 2.0);
        value = RebornMonkScaleTalentValue(GetCaster(), value, 9001656);
        value = RebornMonkScaleResolve(GetCaster(), value, 9001712, 9001552, 10);
        if (Unit* target = GetHitUnit())
            if (Aura* channelAura = target->GetAura(9001546, GetCaster()->GetGUID()))
                if (auto* script = channelAura->GetScript<aura_reborn_monk_arch_mist_start>("aura_reborn_monk_arch_mist_start"))
                {
                    uint32 bonus = script->ConsumeFirstBonus();
                    value = int32(std::min<int64>(2147483647, int64(value) * (100 + bonus) / 100));
                }
        if (Unit* target = GetHitUnit())
            if (target->HasAura(9001548, GetCaster()->GetGUID()))
                value = int32(std::min<int64>(2147483647, int64(value) * 130 / 100));
        SetEffectValue(value);
    }
    void Chi()
    {
        // ARCH2B: count only effective healing, not overheal or the number of nearby units.
        if (Unit* target = GetHitUnit(); target && GetHitHeal() > 0)
            if (Aura* channel = target->GetAura(9001546, GetCaster()->GetGUID()))
                if (auto* script = channel->GetScript<aura_reborn_monk_arch_mist_start>("aura_reborn_monk_arch_mist_start"))
                    script->RecordContinuityPulse(target);
        // Spell::DoAllEffectOnTarget assigns effective healing before AfterHit.
        uint32 chiChance = 30u + 5u * RebornMonkActiveTalentRank(GetCaster(), 9001676);
        if (GetHitUnit() && GetHitHeal() > 0 && roll_chance_i(chiChance))
            RebornMonkAddChi(GetCaster(), 1);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_soothing_pulse::Check);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_soothing_pulse::Healing, EFFECT_0, SPELL_EFFECT_HEAL);
        AfterHit += SpellHitFn(spell_reborn_monk_soothing_pulse::Chi);
        AfterHit += SpellHitFn(spell_reborn_monk_soothing_pulse::ShareHealing);
    }
};

class spell_reborn_monk_enveloping : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_enveloping);
    bool _spent = false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MONK_CHI_AURA_ID}); }
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID)
            return SPELL_FAILED_BAD_TARGETS;
        Aura* chi = player->GetAura(MONK_CHI_AURA_ID);
        return chi && chi->GetStackAmount() >= 3 ? SPELL_CAST_OK : SPELL_FAILED_NO_POWER;
    }
    void Spend()
    {
        if (_spent || !GetHitAura())
            return;
        if (Aura* chi = GetCaster()->GetAura(MONK_CHI_AURA_ID))
            if (chi->GetStackAmount() >= 3)
            {
                uint32 rank = RebornMonkActiveTalentRank(GetCaster(), 9001686);
                uint32 chance = 10u * rank + RebornMonkStanceEconomyChance(GetCaster(), 9001724, 9001552);
                // One combined roll: at most one Chi saved, and no relaxed cast requirement.
                bool saveChi = chance && roll_chance_i(chance);
                chi->ModStackAmount(saveChi ? -2 : -3);
                _spent = true;
            }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_enveloping::Check);
        AfterHit += SpellHitFn(spell_reborn_monk_enveloping::Spend);
    }
};

class aura_reborn_monk_enveloping : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_enveloping);
    uint32 _continuityBonus = 0;
    uint32 _sustainRank = 0;
    uint8 _sustainSpec = 0;
    bool _sustainPaid = false;
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001780, 9001782, 9001783});
    }
    void Expired(AuraEffect const*, AuraEffectHandleModes)
    {
        if (_sustainPaid || !_sustainRank ||
            GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        _sustainPaid = true;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Unit* target = GetTarget();
        if (!player || !player->IsAlive() || !target || !target->IsAlive() ||
            player->getClass() != MONK_CLASS_ID || !player->HasAura(9001552) ||
            player->GetActiveSpec() != _sustainSpec || !player->HasTalent(9001780, _sustainSpec))
            return;
        uint32 rank = std::min(_sustainRank, RebornMonkArchRank(player, 9001782));
        if (!rank)
            return;
        SpellInfo const* info = sSpellMgr->GetSpellInfo(9001781 + rank);
        uint32 amount = uint32(uint64(target->GetMaxHealth()) * rank / 200);
        if (!info || !amount)
            return;
        // A fixed max-health heal: absorb/overheal/log handling, no new proc chain.
        HealInfo heal(player, target, amount, info, info->GetSchoolMask());
        player->HealBySpell(heal);
    }
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        _sustainPaid = false;
        _sustainRank = 0;
        if (Player* owner = GetCaster() ? GetCaster()->ToPlayer() : nullptr)
        {
            _sustainSpec = owner->GetActiveSpec();
            if (owner->HasAura(9001552) && owner->HasTalent(9001780, _sustainSpec))
                _sustainRank = RebornMonkArchRank(owner, 9001782);
        }
        if (_continuityBonus && GetCaster())
            GetCaster()->RemoveAurasDueToSpell(9001778);
        _continuityBonus = 0;
        // Only a successfully applied (or refreshed) Enveloping Mist grants readiness.
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player)
            return;
        player->RemoveAurasDueToSpell(9001781);
        if (player->getClass() != MONK_CLASS_ID || !player->IsAlive() || !GetTarget()->IsAlive() ||
            !player->HasAura(9001552) || !player->HasTalent(9001780, player->GetActiveSpec()))
            return;
        player->CastSpell(player, 9001781, true);
        if (Aura* thread = player->GetAura(9001781))
            if (auto* script = thread->GetScript<aura_reborn_monk_arch_continuity_ready>("aura_reborn_monk_arch_continuity_ready"))
                script->Bind(GetTarget()->GetGUID(), player->GetActiveSpec());
    }
    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        recalculate = false;
        amount = GetCaster() ? RebornMonkHealingValue(GetCaster(), 0.60, 3.0) : 0;
        amount = RebornMonkScaleTalentValue(GetCaster(), amount, 9001666);
        amount = RebornMonkScaleResolve(GetCaster(), amount, 9001712, 9001552, 10);
        _continuityBonus = 0;
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (player && player->HasAura(9001552))
            if (Aura* ready = player->GetAura(9001778))
                if (auto* script = ready->GetScript<aura_reborn_monk_arch_continuity_ready>("aura_reborn_monk_arch_continuity_ready"))
                    if (script->Matches(GetOwner()->GetGUID(), player->GetActiveSpec()))
                        if (AuraEffect const* effect = ready->GetEffect(EFFECT_0))
                            _continuityBonus = std::min<uint32>(std::max<int32>(0, effect->GetAmount()),
                                3 * RebornMonkArchRank(player, 9001774));
        amount = int32(std::min<int64>(2147483647, int64(amount) * (100 + _continuityBonus) / 100));
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_monk_enveloping::Amount, EFFECT_0, SPELL_AURA_PERIODIC_HEAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_enveloping::Expired, EFFECT_0, SPELL_AURA_PERIODIC_HEAL, AURA_EFFECT_HANDLE_REAL);
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_enveloping::Applied, EFFECT_0, SPELL_AURA_PERIODIC_HEAL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};


// MONKM2: independent stance auras, never reuse native shapeshift form IDs.
class spell_reborn_monk_stance : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_stance);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001550, 9001551, 9001552});
    }
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != MONK_CLASS_ID ||
            !player->HasSkill(9001) || !player->HasSkill(9002) || !player->HasSkill(9003))
            return SPELL_FAILED_BAD_TARGETS;
        if (!player->IsAlive())
            return SPELL_FAILED_CASTER_DEAD;
        if (player->IsInCombat())
            return SPELL_FAILED_AFFECTING_COMBAT;
        if (player->IsMounted() || player->GetVehicleBase() || player->GetShapeshiftForm() != FORM_NONE)
            return SPELL_FAILED_NOT_SHAPESHIFT;
        if (player->GetCurrentSpell(CURRENT_CHANNELED_SPELL))
            return SPELL_FAILED_SPELL_IN_PROGRESS;
        if (player->HasAura(GetSpellInfo()->Id))
            return SPELL_FAILED_CASTER_AURASTATE;
        return SPELL_CAST_OK;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_stance::Check);
    }
};

// MONKM3I: only the damaging pulse, never the parent channel or stun.
class spell_reborn_monk_fists_training : public UnitScript
{
public:
    spell_reborn_monk_fists_training() : UnitScript("spell_reborn_monk_fists_training", true) { }
    void ModifySpellDamageTaken(
        Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (target && spellInfo && spellInfo->Id == 9001519 && damage > 0)
            damage = RebornMonkScaleTalentValue(attacker, damage, 9001660);
    }
};

// MONKM3J: only the real Crane damage pulse, preserving the existing Chi path.
class spell_reborn_monk_crane_training : public UnitScript
{
public:
    spell_reborn_monk_crane_training() : UnitScript("spell_reborn_monk_crane_training", true) { }
    void ModifySpellDamageTaken(
        Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (target && spellInfo && spellInfo->Id == 9001532 && damage > 0)
            damage = RebornMonkScaleTalentValue(attacker, damage, 9001670);
    }
};

// MONKM3K: Blackout derived effects retain their existing damage ratios.
class spell_reborn_monk_blackout_training : public UnitScript
{
public:
    spell_reborn_monk_blackout_training() : UnitScript("spell_reborn_monk_blackout_training", true) { }
    void ModifySpellDamageTaken(
        Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (target && spellInfo && spellInfo->Id == 9001507 && damage > 0)
            damage = RebornMonkScaleTalentValue(attacker, damage, 9001680);
    }
};

// Only the four documented direct-damage spell IDs; no auto attacks or other pulses.
class spell_reborn_monk_tiger_resolve : public UnitScript
{
public:
    spell_reborn_monk_tiger_resolve() : UnitScript("spell_reborn_monk_tiger_resolve", true) { }
    void ModifySpellDamageTaken(
        Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (!target || !spellInfo || damage <= 0)
            return;
        switch (spellInfo->Id)
        {
            case 9001507: // Blackout Kick
            case 9001513: // Rising Sun Kick
            case 9001519: // Fists of Fury damage pulse
            case 9001532: // Spinning Crane Kick damage pulse
                damage = RebornMonkScaleResolve(attacker, damage, 9001710, 9001550, 5);
                break;
            default:
                break;
        }
    }
};

class spell_reborn_monk_purifying_brew : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_purifying_brew);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001870, 9001871, 9001872, 9001873}); }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p || p->getClass() != 14) return SPELL_FAILED_BAD_TARGETS;
        char const* reason = nullptr;
        if (!p->HasTalent(9001870, p->GetActiveSpec()))
            reason = "净化酒：需要当前天赋的化劲入门。 / Requires Stagger Initiate in the active build.";
        else if (!p->RebornBrewStorageReady())
            reason = "净化酒：化劲存储未就绪，请检查characters数据库迁移。 / Stagger storage unavailable; check the characters migration.";
        else if (!p->HasAura(9001551))
            reason = "净化酒：请先切换到玄牛式。 / Purifying Brew: Switch to Ox Stance first.";
        else if (!p->RebornBrewDebt())
            reason = "净化酒：当前没有可清除的化劲伤害。 / No stagger damage to purify.";
        if (reason)
        {
            ChatHandler(p->GetSession()).SendNotification(reason);
            return SPELL_FAILED_DONT_REPORT;
        }
        return SPELL_CAST_OK;
    }
    void Purify(SpellEffIndex)
    {
        if (Player* p = GetCaster()->ToPlayer())
        {
            uint32 removed = p->RebornBrewPurify();
            ChatHandler(p->GetSession()).SendNotification("净化酒 / Purifying Brew: -{}; 剩余 / remaining: {}", removed, p->RebornBrewDebt());
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_purifying_brew::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_monk_purifying_brew::Purify, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// MONKBW3: only a successfully applied Guard arms Brew and Guard.
class aura_reborn_bw3_guard_link : public AuraScript
{
    PrepareAuraScript(aura_reborn_bw3_guard_link);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001882,9001883,9001894}); }
    void Applied(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (effect->GetAmount() <= 0) return;
        if (Player* p = GetTarget()->ToPlayer()) p->RebornBrewArmGuard();
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_bw3_guard_link::Applied, EFFECT_0,
            SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

class aura_reborn_bw3_purifying_guard : public AuraScript
{
    PrepareAuraScript(aura_reborn_bw3_purifying_guard);
    uint8 _spec = 0;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001880,9001881,9001893}); }
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* p = GetTarget()->ToPlayer()) _spec = p->GetActiveSpec();
    }
    void Guard(AuraEffect const*)
    {
        Player* p = GetTarget()->ToPlayer();
        uint32 rank = p ? p->RebornBrewRank(9001880, 2) : 0;
        if (!p || !rank || !p->IsAlive() || !p->HasAura(9001551) ||
            !p->HasTalent(9001870, p->GetActiveSpec()) || p->GetActiveSpec() != _spec)
        { Remove(); return; }
        // Rank loss can shrink a live shield, never refill consumed capacity.
        int32 cap = int32(std::min<uint64>(0x7fffffff, uint64(p->GetMaxHealth()) * rank / 100));
        if (AuraEffect* effect = GetEffect(EFFECT_0))
            if (effect->GetAmount() > cap) effect->ChangeAmount(cap);
    }
    void Absorb(AuraEffect*, DamageInfo&, uint32& amount)
    {
        Player* p = GetTarget()->ToPlayer();
        if (!p || !p->IsAlive() || !p->HasAura(9001551) || p->GetActiveSpec() != _spec ||
            !p->HasTalent(9001870, p->GetActiveSpec()) || !p->RebornBrewRank(9001880, 2))
        { amount = 0; Remove(); }
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_bw3_purifying_guard::Applied, EFFECT_0,
            SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_bw3_purifying_guard::Absorb, EFFECT_0);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_bw3_purifying_guard::Guard, EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
    }
};

class spell_reborn_bw3_mastery : public SpellScript
{
    PrepareSpellScript(spell_reborn_bw3_mastery);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001870,9001892,9001896}); }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p || p->getClass() != 14) return SPELL_FAILED_BAD_TARGETS;
        char const* reason = nullptr;
        if (!p->HasTalent(9001870,p->GetActiveSpec()) || !p->HasTalent(9001892,p->GetActiveSpec()))
            reason = "酒仙宗师：需要当前配置的化劲入门和酒仙宗师。 / Requires Stagger Initiate and Brewmaster Mastery in the active build.";
        else if (!p->RebornBrewStorageReady())
            reason = "酒仙宗师：化劲存储未就绪，请检查characters迁移。 / Stagger storage unavailable; check the characters migration.";
        else if (!p->HasAura(9001551))
            reason = "酒仙宗师：请先切换到玄牛式。 / Brewmaster Mastery: Switch to Ox Stance first.";
        if (reason)
        {
            ChatHandler(p->GetSession()).SendNotification(reason);
            return SPELL_FAILED_DONT_REPORT;
        }
        return SPELL_CAST_OK;
    }
    void Activate(SpellEffIndex)
    {
        if (Player* p = GetCaster()->ToPlayer())
        {
            uint32 removed = p->RebornBrewBeginMastery();
            ChatHandler(p->GetSession()).SendNotification("酒仙宗师 / Brewmaster Mastery: 清除 / cleared {}; 化劲伤害降低20%，持续6秒 / 20% less stagger damage for 6 sec.", removed);
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_bw3_mastery::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_bw3_mastery::Activate, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// MONKCOM1: map-local, owner-bound Transcendence. No persistent coordinates.
namespace
{
constexpr uint32 MONK_TRANSCENDENCE = 9001900;
constexpr uint32 MONK_TRANSFER = 9001901;
constexpr uint32 MONK_ANCHOR_READY = 9001902;
constexpr uint32 MONK_TRANSFER_ARRIVAL = 9001903;
constexpr uint32 MONK_ANCHOR_ENTRY = 900190;

SpellCastResult MonkAnchorError(Player* p, char const* text)
{
    if (p)
        ChatHandler(p->GetSession()).SendNotification("{}", text);
    return SPELL_FAILED_DONT_REPORT;
}

void MonkClearAnchor(Player* p)
{
    p->RemoveAurasDueToSpell(MONK_ANCHOR_READY);
    p->RemoveGameObject(MONK_ANCHOR_READY, true);
}

bool MonkAnchorGround(Player* p, float x, float y, float z)
{
    float ground = p->GetMap()->GetHeight(p->GetPhaseMask(), x, y, z + 1.0f, true, 3.0f);
    return std::isfinite(ground) && std::abs(ground - z) <= 1.25f;
}

SpellCastResult MonkAnchorState(Player* p)
{
    if (!p || p->getClass() != MONK_CLASS_ID || !p->IsAlive() || !p->IsInWorld())
        return SPELL_FAILED_CASTER_DEAD;
    if (p->IsBeingTeleported() || p->IsInFlight() || p->GetTransport() || p->GetVehicle() ||
        p->IsMounted() || p->IsFalling() || p->IsInWater())
        return MonkAnchorError(p, "请在稳定地面、离开坐骑或载具后使用。 / Use on stable ground, off mounts and vehicles.");
    if (p->HasUnitState(UNIT_STATE_ROOT | UNIT_STATE_STUNNED | UNIT_STATE_CONFUSED | UNIT_STATE_FLEEING) || p->GetCharmerGUID())
        return MonkAnchorError(p, "受控制时无法使用魂体双分；本技能不解除控制。 / Cannot use while controlled; this does not break control.");
    if (p->HasAura(32727) || p->HasAura(44521) || p->HasAura(23333) || p->HasAura(23335) || p->HasAura(34976))
        return MonkAnchorError(p, "准备阶段或携带战场旗帜时无法使用。 / Unavailable during preparation or while carrying a battleground flag.");
    if (!MonkAnchorGround(p, p->GetPositionX(), p->GetPositionY(), p->GetPositionZ()))
        return MonkAnchorError(p, "当前位置没有安全地面。 / No safe ground at your current position.");
    return SPELL_CAST_OK;
}

SpellCastResult MonkTransferCheck(Player* p, GameObject*& anchor)
{
    anchor = nullptr;
    SpellCastResult state = MonkAnchorState(p);
    if (state != SPELL_CAST_OK)
        return state;
    anchor = p->GetGameObject(MONK_ANCHOR_READY);
    if (!p->HasAura(MONK_ANCHOR_READY) || !anchor || !anchor->IsInWorld() ||
        anchor->GetEntry() != MONK_ANCHOR_ENTRY || anchor->GetOwnerGUID() != p->GetGUID() ||
        anchor->GetMap() != p->GetMap() || !p->InSamePhase(anchor))
        return MonkAnchorError(p, "请先施放魂体双分，建立当前区域的锚点。 / First create a Transcendence anchor in this area.");
    if (p->GetExactDist(anchor) > 25.0f)
        return MonkAnchorError(p, "灵体锚点超过25码。 / Your spirit anchor is more than 25 yards away.");
    if (!p->IsWithinLOSInMap(anchor) || !MonkAnchorGround(p, anchor->GetPositionX(), anchor->GetPositionY(), anchor->GetPositionZ()))
        return MonkAnchorError(p, "锚点被障碍物阻挡或落点不安全。 / The anchor is obstructed or its landing position is unsafe.");
    PathGenerator path(p);
    path.SetPathLengthLimit(52.0f);
    if (!path.CalculatePath(anchor->GetPositionX(), anchor->GetPositionY(), anchor->GetPositionZ(), false) ||
        path.GetPathType() != PATHFIND_NORMAL || path.getPathLength() > 50.0f)
        return MonkAnchorError(p, "到锚点没有有效地面路径；请换位置重放锚点。 / No valid ground path to the anchor; place it elsewhere.");
    auto const& end = path.GetActualEndPosition();
    float dx = end.x - anchor->GetPositionX(), dy = end.y - anchor->GetPositionY(), dz = end.z - anchor->GetPositionZ();
    if (dx * dx + dy * dy + dz * dz > 2.25f)
        return MonkAnchorError(p, "路径没有抵达锚点。 / The path does not reach your anchor.");
    return SPELL_CAST_OK;
}
}

class aura_reborn_monk_anchor_ready : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_anchor_ready);
public:
    void AwaitArrival() { arrivalTicks = 20; }
    void CancelArrival() { arrivalTicks = 0; }
private:
    uint8 arrivalTicks = 0;
    void Tick(AuraEffect const*)
    {
        Player* p = GetTarget()->ToPlayer();
        GameObject* go = p ? p->GetGameObject(MONK_ANCHOR_READY) : nullptr;
        if (!p || !p->IsAlive() || !p->HasActiveSpell(MONK_TRANSCENDENCE) || !p->HasActiveSpell(MONK_TRANSFER) ||
            !go || !go->IsInWorld() || go->GetMap() != p->GetMap() || !p->InSamePhase(go))
        {
            Remove();
            return;
        }
        if (arrivalTicks)
        {
            --arrivalTicks;
            if (!p->IsBeingTeleported() && p->GetExactDist(go) <= 1.0f)
            {
                arrivalTicks = 0;
                p->CastSpell(p, MONK_TRANSFER_ARRIVAL, true);
            }
        }
    }
    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveGameObject(MONK_ANCHOR_READY, true);
    }
    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_anchor_ready::Tick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_anchor_ready::End, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_reborn_monk_transcendence : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_transcendence);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({MONK_ANCHOR_READY, MONK_TRANSFER});
    }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        SpellCastResult result = MonkAnchorState(p);
        if (result != SPELL_CAST_OK)
            return result;
        if (!sObjectMgr->GetGameObjectTemplate(MONK_ANCHOR_ENTRY))
            return MonkAnchorError(p, "灵体锚点数据未安装，请检查MONKCOM1的SQL。 / Anchor data missing: install MONKCOM1 SQL.");
        return SPELL_CAST_OK;
    }
    void Place(SpellEffIndex)
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p || Check() != SPELL_CAST_OK)
        {
            if (p) p->RemoveSpellCooldown(MONK_TRANSCENDENCE, true);
            return;
        }
        float o = p->GetOrientation();
        GameObject* next = p->SummonGameObject(MONK_ANCHOR_ENTRY, p->GetPositionX(), p->GetPositionY(), p->GetPositionZ(),
            o, 0.0f, 0.0f, std::sin(o * 0.5f), std::cos(o * 0.5f), 900, false);
        if (!next)
        {
            MonkAnchorError(p, "灵体锚点建立失败，旧锚点保留。 / Failed to create a spirit anchor; your old anchor is retained.");
            p->RemoveSpellCooldown(MONK_TRANSCENDENCE, true);
            return;
        }
        // The new object's temporary SpellId is 1; clearing the old anchor cannot delete it.
        MonkClearAnchor(p);
        next->SetSpellId(MONK_ANCHOR_READY);
        p->CastSpell(p, MONK_ANCHOR_READY, true);
        if (!p->HasAura(MONK_ANCHOR_READY))
        {
            p->RemoveGameObject(MONK_ANCHOR_READY, true);
            p->RemoveSpellCooldown(MONK_TRANSCENDENCE, true);
            MonkAnchorError(p, "灵体锚点状态建立失败。 / Failed to establish anchor readiness.");
            return;
        }
        ChatHandler(p->GetSession()).SendNotification("灵体锚点已建立，持续15分钟。 / Spirit anchor placed for 15 minutes.");
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_transcendence::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_monk_transcendence::Place, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_reborn_monk_transcendence_transfer : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_transcendence_transfer);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MONK_ANCHOR_READY, MONK_TRANSFER_ARRIVAL}); }
    SpellCastResult Check()
    {
        GameObject* anchor = nullptr;
        return MonkTransferCheck(GetCaster()->ToPlayer(), anchor);
    }
    void Transfer(SpellEffIndex)
    {
        Player* p = GetCaster()->ToPlayer();
        GameObject* anchor = nullptr;
        if (MonkTransferCheck(p, anchor) != SPELL_CAST_OK)
        {
            if (p) p->RemoveSpellCooldown(MONK_TRANSFER, true);
            return;
        }
        auto* ready = p->GetAura(MONK_ANCHOR_READY)->GetScript<aura_reborn_monk_anchor_ready>("aura_reborn_monk_anchor_ready");
        if (ready) ready->AwaitArrival();
        // Same Map* was checked (including the instance); never use saved map coordinates.
        if (!p->TeleportTo(p->GetMapId(), anchor->GetPositionX(), anchor->GetPositionY(), anchor->GetPositionZ(),
            anchor->GetOrientation(), TELE_TO_NOT_LEAVE_COMBAT | TELE_TO_SPELL))
        {
            if (ready) ready->CancelArrival();
            p->RemoveSpellCooldown(MONK_TRANSFER, true);
            MonkAnchorError(p, "转移未能完成，锚点仍保留。 / Transfer failed; your anchor is retained.");
            return;
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_transcendence_transfer::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_monk_transcendence_transfer::Transfer, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class player_reborn_monk_anchor_cleanup : public PlayerScript
{
public:
    player_reborn_monk_anchor_cleanup() : PlayerScript("player_reborn_monk_anchor_cleanup") { }
    void OnPlayerLogout(Player* p) override { MonkClearAnchor(p); }
    void OnPlayerLogin(Player* p) override { MonkClearAnchor(p); }
    void OnPlayerJustDied(Player* p) override { MonkClearAnchor(p); }
    void OnPlayerMapChanged(Player* p) override { MonkClearAnchor(p); }
    bool OnPlayerBeforeTeleport(Player* p, uint32 mapId, float, float, float, float, uint32, Unit*) override
    {
        // Destroy while the old map is still accessible. Same-map transfers retain the anchor.
        if (mapId != p->GetMapId())
            MonkClearAnchor(p);
        return true;
    }
};

// MONKWWB1: basic Windwalker abilities, independent of talent ownership.
namespace
{
constexpr uint32 MONK_KARMA = 9001910;
constexpr uint32 MONK_KARMA_SHIELD = 9001911;
constexpr uint32 MONK_KARMA_RETURN = 9001912;
constexpr uint32 MONK_KARMA_MARK = 9001913;
constexpr uint32 MONK_TOUCH_DEATH = 9001914;

SpellCastResult MonkTouchState(Player* p)
{
    if (!p || p->getClass() != MONK_CLASS_ID || !p->IsAlive())
        return SPELL_FAILED_CASTER_DEAD;
    if (!p->HasAura(9001550))
        return MonkAnchorError(p, "请先切换到猛虎式。 / Switch to Tiger Stance first.");
    return SPELL_CAST_OK;
}

bool MonkTouchEnemy(Player* p, Unit* target, float range)
{
    return p && target && target != p && target->IsInWorld() && target->IsAlive() &&
        p->GetMap() == target->GetMap() && p->InSamePhase(target) &&
        p->IsValidAttackTarget(target) && p->IsWithinCombatRange(target, range) &&
        p->IsWithinLOSInMap(target);
}
}

class aura_reborn_monk_karma_shield : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_karma_shield);
public:
    void Initialize(ObjectGuid enemyGuid, uint32 capacity, uint8 activeSpec)
    {
        // Called by SpellScript after CastSpell returns, outside an AuraScript hook.
        // GetTarget() has no application context here and returns nullptr.
        // Capture values from the already validated caster/target at the call site.
        targetGuid = enemyGuid;
        remaining = std::min<uint32>(capacity, 2147483647u);
        queued = 0;
        spec = activeSpec;
        initialized = true;
    }
private:
    ObjectGuid targetGuid;
    uint32 remaining = 0;
    uint32 queued = 0;
    uint8 spec = 0;
    bool initialized = false;

    Unit* Enemy(bool requireMark = true)
    {
        Player* p = GetTarget()->ToPlayer();
        if (!initialized || !p || !p->IsAlive() || !p->HasAura(9001550) ||
            !p->HasActiveSpell(MONK_KARMA) || p->GetActiveSpec() != spec)
            return nullptr;
        Unit* enemy = ObjectAccessor::GetUnit(*p, targetGuid);
        if (!MonkTouchEnemy(p, enemy, 40.0f) || (requireMark && !enemy->HasAura(MONK_KARMA_MARK, p->GetGUID())))
            return nullptr;
        return enemy;
    }
    void Calculate(AuraEffect const*, int32& amount, bool& recalculate)
    {
        // The finite budget belongs to this script. Keep the aura alive after budget
        // exhaustion so that queued damage is not lost when core consumes a shield.
        amount = -1;
        recalculate = false;
    }
    void Absorb(AuraEffect*, DamageInfo& info, uint32& amount)
    {
        amount = 0;
        Unit* attacker = info.GetAttacker();
        if (!Enemy() || !attacker || attacker == GetTarget() ||
            info.GetDamageType() == SELF_DAMAGE || info.GetDamageType() == NODAMAGE ||
            (info.GetSpellInfo() && (info.GetSpellInfo()->Id == MONK_KARMA_RETURN ||
                info.GetSpellInfo()->HasAura(SPELL_AURA_DAMAGE_SHIELD))))
            return;
        amount = std::min(remaining, info.GetDamage());
    }
    void Absorbed(AuraEffect*, DamageInfo&, uint32& amount)
    {
        uint32 paid = std::min(remaining, amount);
        remaining -= paid;
        queued += paid; // Sum cannot exceed the original INT32_MAX-clamped capacity.
    }
    void Flush(Unit* enemy)
    {
        uint32 paid = queued;
        queued = 0; // Clear before casting: never recursively return the same packet.
        if (paid && enemy)
            GetTarget()->CastCustomSpell(MONK_KARMA_RETURN, SPELLVALUE_BASE_POINT0, int32(paid), enemy, true);
    }
    void Tick(AuraEffect const*)
    {
        Unit* enemy = Enemy();
        if (!enemy)
        {
            queued = 0;
            Remove();
            return;
        }
        Flush(enemy);
    }
    void Removed(AuraEffect const*, AuraEffectHandleModes)
    {
        // Only natural expiry settles the final fraction of a second. Dispel,
        // cancellation, death, lost stance/target/build intentionally end the link.
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
            Flush(Enemy());
        queued = 0;
        if (Unit* enemy = ObjectAccessor::GetUnit(*GetTarget(), targetGuid))
            enemy->RemoveAurasDueToSpell(MONK_KARMA_MARK, GetTarget()->GetGUID());
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_monk_karma_shield::Calculate, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_monk_karma_shield::Absorb, EFFECT_0);
        AfterEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_monk_karma_shield::Absorbed, EFFECT_0);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_karma_shield::Tick, EFFECT_1, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_karma_shield::Removed, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_reborn_monk_touch_karma : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_touch_karma);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({MONK_KARMA_SHIELD, MONK_KARMA_RETURN, MONK_KARMA_MARK});
    }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        SpellCastResult state = MonkTouchState(p);
        if (state != SPELL_CAST_OK)
            return state;
        if (!MonkTouchEnemy(p, GetExplTargetUnit(), 20.0f))
            return MonkAnchorError(p, "请选择20码内、视线可达的敌方目标。 / Select an enemy in line of sight within 20 yards.");
        return SPELL_CAST_OK;
    }
    void Hit(SpellEffIndex)
    {
        Player* p = GetCaster()->ToPlayer();
        Unit* enemy = GetHitUnit();
        if (!p)
            return;
        if (MonkTouchState(p) != SPELL_CAST_OK || !MonkTouchEnemy(p, enemy, 20.0f))
        {
            p->RemoveSpellCooldown(MONK_KARMA, true);
            return;
        }
        p->RemoveAurasDueToSpell(MONK_KARMA_SHIELD);
        p->CastSpell(enemy, MONK_KARMA_MARK, true);
        if (!enemy->HasAura(MONK_KARMA_MARK, p->GetGUID()))
        {
            p->RemoveSpellCooldown(MONK_KARMA, true);
            MonkAnchorError(p, "目标无法建立业报连接。 / Cannot establish the Karma link on this target.");
            return;
        }
        p->CastSpell(p, MONK_KARMA_SHIELD, true);
        Aura* aura = p->GetAura(MONK_KARMA_SHIELD);
        auto* script = aura ? aura->GetScript<aura_reborn_monk_karma_shield>("aura_reborn_monk_karma_shield") : nullptr;
        if (!script)
        {
            p->RemoveAurasDueToSpell(MONK_KARMA_SHIELD);
            enemy->RemoveAurasDueToSpell(MONK_KARMA_MARK, p->GetGUID());
            p->RemoveSpellCooldown(MONK_KARMA, true);
            MonkAnchorError(p, "业报数据未正确加载，请检查本包SQL和两端DBC。 / Karma data is incomplete; check this package's SQL and both DBC sets.");
            return;
        }
        script->Initialize(enemy->GetGUID(), uint32(std::min<uint64>(uint64(p->GetMaxHealth()) * 30 / 100, 2147483647u)), p->GetActiveSpec());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_touch_karma::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_monk_touch_karma::Hit, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_reborn_monk_karma_return : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_karma_return);
    void Hit(SpellEffIndex index)
    {
        // Bypass bonus-coefficient calculations; normal target mitigation/absorb
        // still runs later in Spell::DoAllEffectOnTarget. DBC also disables crit/procs.
        PreventHitDefaultEffect(index);
        uint32 amount = uint32(std::max<int32>(0, GetEffectValue()));
        if (Unit* target = GetHitUnit())
            amount = target->SpellDamageBonusTaken(GetCaster(), GetSpellInfo(), amount, SPELL_DIRECT_DAMAGE);
        SetHitDamage(int32(std::min<uint32>(amount, 2147483647u)));
    }
    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_karma_return::Hit, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class spell_reborn_monk_touch_death : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_touch_death);
    SpellCastResult CheckTarget(Unit* target)
    {
        Player* p = GetCaster()->ToPlayer();
        SpellCastResult state = MonkTouchState(p);
        if (state != SPELL_CAST_OK)
            return state;
        Creature* c = target ? target->ToCreature() : nullptr;
        if (!c || c->IsTrigger() || c->IsCivilian() || c->IsPet() || c->IsSummon() ||
            c->IsTotem() || c->GetCharmerOrOwnerGUID() || c->IsNPCBotOrPet())
            return MonkAnchorError(p, "轮回之触需要敌方怪物，不能用于玩家、宠物或召唤物。 / Touch of Death requires an enemy creature, not a player, pet or summon.");
        if (!MonkTouchEnemy(p, c, 5.0f))
            return MonkAnchorError(p, "请选择近战范围内、视线可达的敌方怪物。 / Select an enemy creature in melee range and line of sight.");
        // Rank is not an eligibility rule: elites and bosses take bounded damage.
        if (uint64(c->GetHealth()) * 5 > c->GetMaxHealth())
            return MonkAnchorError(p, "轮回之触需要目标生命值不超过20%。 / Touch of Death requires a target at 20% health or less.");
        return SPELL_CAST_OK;
    }
    SpellCastResult Check() { return CheckTarget(GetExplTargetUnit()); }
    void Launch(SpellEffIndex index)
    {
        // Like native Execute, use the ordinary spell-damage and kill-credit path.
        // Suppress the safe one-point DBC placeholder before providing our amount.
        PreventHitDefaultEffect(index);
        SetHitDamage(0);
        Player* p = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!p || !target || CheckTarget(target) != SPELL_CAST_OK)
            return;
        uint32 cap = uint32(std::min<uint64>(p->GetMaxHealth(), 2147483647u));
        uint32 damage = target->SpellDamageBonusTaken(p, GetSpellInfo(), cap, SPELL_DIRECT_DAMAGE);
        // Even target vulnerability cannot turn this into an unlimited boss kill.
        SetHitDamage(int32(std::min(cap, damage)));
    }
    void Hit(SpellEffIndex)
    {
        // Recheck at impact in case health, ownership or target validity changed.
        if (CheckTarget(GetHitUnit()) != SPELL_CAST_OK)
        {
            SetHitDamage(0);
            if (Player* p = GetCaster()->ToPlayer())
                p->RemoveSpellCooldown(MONK_TOUCH_DEATH, true);
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_touch_death::Check);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_touch_death::Launch, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_monk_touch_death::Hit, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

// MONKBWK1: native instant area damage, once-per-cast Chi, caster-owned brew mark.
class spell_reborn_monk_keg_smash : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_keg_smash);
    bool _granted = false;

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001921, 9001551, MONK_CHI_AURA_ID});
    }
    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->ToPlayer()->getClass() == MONK_CLASS_ID;
    }
    SpellCastResult Check()
    {
        return GetCaster()->HasAura(9001551) ? SPELL_CAST_OK :
            MonkAnchorError(GetCaster()->ToPlayer(), "请先切换到玄牛式。 / Switch to Ox Stance first.");
    }
    void Filter(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        targets.remove_if([caster](WorldObject* object)
        {
            Unit* unit = object ? object->ToUnit() : nullptr;
            return !unit || !unit->IsAlive() || !caster->IsValidAttackTarget(unit) ||
                !caster->InSamePhase(unit) || !caster->IsWithinLOSInMap(unit);
        });
    }
    void Damage(SpellEffIndex)
    {
        // Exactly one AP growth formula. SQL disables automatic flat spell/AP bonuses.
        SetEffectValue(RebornMonkPowerValue(GetCaster(), 0.60, 2.0));
    }
    void Landed()
    {
        Unit* target = GetHitUnit();
        if (!target || GetHitDamage() <= 0 || !GetCaster()->HasAura(9001551))
            return;
        // Death from this hit still earns Chi, but a corpse receives no brew mark.
        if (target->IsAlive())
            GetCaster()->CastSpell(target, 9001921, true);
        if (!_granted)
        {
            _granted = true; // Set before casting the resource aura to prevent reentry.
            RebornMonkAddChi(GetCaster(), 2);
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_keg_smash::Check);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_monk_keg_smash::Filter,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ENEMY);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_keg_smash::Damage,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(spell_reborn_monk_keg_smash::Landed);
    }
};

// MONKBWF1: front cone, one Chi payment, and only this caster's Brew Mark.
class spell_reborn_monk_breath_fire : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_breath_fire);
    bool _paid = false;
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001921, 9001923, 9001551, MONK_CHI_AURA_ID});
    }
    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->ToPlayer()->getClass() == MONK_CLASS_ID;
    }
    SpellCastResult Check()
    {
        if (!GetCaster()->HasAura(9001551))
            return MonkAnchorError(GetCaster()->ToPlayer(), "请先切换到玄牛式。 / Switch to Ox Stance first.");
        Aura* chi = GetCaster()->GetAura(MONK_CHI_AURA_ID);
        if (!chi || chi->GetStackAmount() < 2)
            return MonkAnchorError(GetCaster()->ToPlayer(),
                "真气点不足，需要2点真气。 / Not enough Chi. Requires 2 Chi.");
        return SPELL_CAST_OK;
    }
    void Pay()
    {
        if (_paid)
            return;
        if (Aura* chi = GetCaster()->GetAura(MONK_CHI_AURA_ID))
            if (chi->GetStackAmount() >= 2)
            {
                _paid = true;
                chi->ModStackAmount(-2);
            }
    }
    void Filter(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        targets.remove_if([caster](WorldObject* object)
        {
            Unit* target = object ? object->ToUnit() : nullptr;
            return !target || !target->IsAlive() || !caster->IsValidAttackTarget(target) ||
                !caster->InSamePhase(target) || !caster->IsWithinLOSInMap(target) ||
                !caster->HasInArc(float(M_PI / 2), target);
        });
    }
    void Damage(SpellEffIndex)
    {
        // If the resource disappeared unexpectedly, fail closed before damage.
        if (!_paid)
        {
            PreventHitDefaultEffect(EFFECT_0);
            return;
        }
        SetEffectValue(RebornMonkPowerValue(GetCaster(), 0.40, 2.0));
    }
    void Burn()
    {
        Unit* target = GetHitUnit();
        if (!_paid || !target || !target->IsAlive() || GetHitDamage() <= 0 ||
            !target->HasAura(9001921, GetCaster()->GetGUID()))
            return;
        // Snapshot once. Refresh only our DoT; never consume another monk's mark.
        GetCaster()->CastCustomSpell(9001923, SPELLVALUE_BASE_POINT0,
            RebornMonkPowerValue(GetCaster(), 0.12, 1.0), target, true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_breath_fire::Check);
        OnCast += SpellCastFn(spell_reborn_monk_breath_fire::Pay);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_monk_breath_fire::Filter,
            EFFECT_0, TARGET_UNIT_CONE_ENEMY_24);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_breath_fire::Damage,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(spell_reborn_monk_breath_fire::Burn);
    }
};

// MONKBWS1: bounded, stationary PvE threat helper. No automatic taunts.
namespace
{
constexpr uint32 MONK_OX_STATUE = 9001924;
constexpr uint32 MONK_OX_PRESENCE = 9001925;
constexpr uint32 MONK_OX_ENTRY = 900186;
bool MonkOxOwner(Player* p)
{
    return p && p->IsInWorld() && p->IsAlive() && p->getClass() == MONK_CLASS_ID &&
        p->HasAura(9001551) && p->HasActiveSpell(MONK_OX_STATUE);
}
}

class aura_reborn_monk_ox_presence : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_ox_presence);
public:
    ObjectGuid StatueGuid;
    uint8 Spec = 0;
    void Initialize(ObjectGuid guid, uint8 spec) { StatueGuid = guid; Spec = spec; }
private:
    void Tick(AuraEffect const*)
    {
        Player* p = GetTarget()->ToPlayer();
        Creature* statue = ObjectAccessor::GetCreature(*GetTarget(), StatueGuid);
        if (!MonkOxOwner(p) || p->GetActiveSpec() != Spec || !statue || !statue->IsAlive() ||
            !statue->InSamePhase(p) || !statue->IsWithinDistInMap(p, 40.0f))
            Remove();
    }
    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Creature* statue = ObjectAccessor::GetCreature(*GetTarget(), StatueGuid))
            statue->DespawnOrUnsummon(Milliseconds(1));
    }
    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_ox_presence::Tick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_ox_presence::End, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_reborn_monk_ox_statue : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_ox_statue);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MONK_OX_PRESENCE}); }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p) return SPELL_FAILED_BAD_TARGETS;
        if (!MonkOxOwner(p))
            return MonkAnchorError(p, "请先切换到玄牛式。 / Switch to Ox Stance first.");
        if (!sObjectMgr->GetCreatureTemplate(MONK_OX_ENTRY))
            return MonkAnchorError(p, "玄牛雕像数据未安装。 / Black Ox Statue data is missing.");
        return SPELL_CAST_OK;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_reborn_monk_ox_statue::Check); }
};

class npc_reborn_monk_ox_statue : public CreatureScript
{
public:
    npc_reborn_monk_ox_statue() : CreatureScript("npc_reborn_monk_ox_statue") { }
    struct AI : public ScriptedAI
    {
        AI(Creature* c) : ScriptedAI(c) { }
        uint32 timer = 1000;
        uint32 elapsed = 0;
        uint8 spec = 0;
        float threat = 0.0f;
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* p = summoner ? summoner->ToPlayer() : nullptr;
            if (!MonkOxOwner(p)) { me->DespawnOrUnsummon(Milliseconds(1)); return; }
            spec = p->GetActiveSpec();
            me->SetOwnerGUID(p->GetGUID());
            me->SetCreatorGUID(p->GetGUID());
            me->SetFaction(p->GetFaction());
            me->SetLevel(p->GetLevel());
            me->SetReactState(REACT_PASSIVE);
            me->SetControlled(true, UNIT_STATE_ROOT);
            me->GetMotionMaster()->Clear();
            me->GetMotionMaster()->MoveIdle();
            me->SetMaxHealth(std::max<uint32>(1, p->GetMaxHealth() / 2));
            me->SetHealth(me->GetMaxHealth());
            threat = std::max(1.0f, 0.5f * p->GetTotalAttackPowerValue(BASE_ATTACK) + 5.0f * p->GetLevel());
            // Removing the owner's old presence despawns only its own old GUID.
            p->RemoveAurasDueToSpell(MONK_OX_PRESENCE);
            p->CastSpell(p, MONK_OX_PRESENCE, true);
            Aura* aura = p->GetAura(MONK_OX_PRESENCE);
            auto* state = aura ? aura->GetScript<aura_reborn_monk_ox_presence>("aura_reborn_monk_ox_presence") : nullptr;
            if (!state) { me->DespawnOrUnsummon(Milliseconds(1)); return; }
            // R1 convention: no GetTarget() outside an aura application hook.
            state->Initialize(me->GetGUID(), spec);
        }
        void UpdateAI(uint32 diff) override
        {
            if (timer > diff) { timer -= diff; return; }
            timer = 1000;
            Player* p = me->GetOwner() ? me->GetOwner()->ToPlayer() : nullptr;
            Aura* aura = p ? p->GetAura(MONK_OX_PRESENCE) : nullptr;
            auto* state = aura ? aura->GetScript<aura_reborn_monk_ox_presence>("aura_reborn_monk_ox_presence") : nullptr;
            if (!MonkOxOwner(p) || p->GetActiveSpec() != spec || !state || state->StatueGuid != me->GetGUID() ||
                !me->InSamePhase(p) || !me->IsWithinDistInMap(p, 40.0f))
            { me->DespawnOrUnsummon(Milliseconds(1)); return; }
            if (!me->IsAlive()) return;
            elapsed += 1000;
            if (elapsed < 2000) return;
            elapsed = 0;
            // Snapshot GUIDs: adding threat may mutate combat-manager containers.
            std::vector<ObjectGuid> enemies;
            for (auto const& pair : p->GetCombatManager().GetPvECombatRefs())
                if (Unit* u = pair.second->GetOther(p))
                    enemies.push_back(u->GetGUID());
            std::vector<Creature*> eligible;
            for (ObjectGuid guid : enemies)
            {
                Creature* c = ObjectAccessor::GetCreature(*me, guid);
                if (!c || !c->IsAlive() || !c->CanHaveThreatList() || c->IsPet() || c->IsSummon() ||
                    c->IsTotem() || c->IsTrigger() || c->IsCivilian() || c->IsNPCBotOrPet() ||
                    c->GetCharmerOrOwnerGUID() || !c->IsInCombatWith(p) || !p->IsValidAttackTarget(c) ||
                    !me->InSamePhase(c) || !me->IsWithinDistInMap(c, 8.0f) || !me->IsWithinLOSInMap(c))
                    continue;
                eligible.push_back(c);
            }
            std::sort(eligible.begin(), eligible.end(), [this](Creature* a, Creature* b)
            {
                float da = me->GetExactDist(a), db = me->GetExactDist(b);
                return da == db ? a->GetGUID() < b->GetGUID() : da < db;
            });
            if (eligible.size() > 5) eligible.resize(5);
            for (Creature* c : eligible)
                c->GetThreatMgr().AddThreat(me, threat, nullptr, true, true);
        }
    };
    CreatureAI* GetAI(Creature* c) const override { return new AI(c); }
};

// MONKMWS2: native periodic healing; caster-owned registry enforces three applications.
class spell_reborn_monk_renewing_mist : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_renewing_mist);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001552}); }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        return p && p->getClass() == MONK_CLASS_ID && p->HasSpell(9001927)
            ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }

    // H2: one manual application seeds at most two injured, unmarked group allies.
    bool _spread = false;
    size_t Count(Player* p)
    {
        size_t count = 0;
        for (Aura* aura : p->GetSingleCastAuras())
            if (!aura->IsRemoved() && aura->GetId() == 9001927 && aura->GetCasterGUID() == p->GetGUID())
                ++count;
        return count;
    }
    bool CanSpread(Player* p, Unit* origin, Unit* target)
    {
        return target && target != origin && target->IsInWorld() && target->IsAlive() &&
            target->GetHealth() < target->GetMaxHealth() && p->IsInRaidWith(target) &&
            p->IsValidAssistTarget(target) && p->InSamePhase(target) &&
            origin->IsWithinDistInMap(target, 20.0f) && origin->IsWithinLOSInMap(target) &&
            p->IsWithinDistInMap(target, 40.0f) && p->IsWithinLOSInMap(target) &&
            !target->GetAura(9001927, p->GetGUID());
    }
    void Spread()
    {
        Player* p = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Unit* origin = GetHitUnit();
        Aura* applied = GetHitAura();
        if (_spread || GetSpell()->IsTriggered() || !p || p->getClass() != MONK_CLASS_ID ||
            !p->IsAlive() || !p->HasSpell(9001927) || !p->HasAura(9001552) ||
            !origin || !origin->IsInWorld() || !origin->IsAlive() ||
            !applied || applied->IsRemoved() || applied->GetCasterGUID() != p->GetGUID())
            return;
        _spread = true; // Set before nested casts; triggered copies never spread.
        std::list<Unit*> candidates;
        Acore::AnyFriendlyUnitInObjectRangeCheck check(origin, p, 20.0f);
        Acore::UnitListSearcher<Acore::AnyFriendlyUnitInObjectRangeCheck> searcher(origin, candidates, check);
        Cell::VisitObjects(origin, searcher, 20.0f);
        candidates.remove_if([&](Unit* target) { return !CanSpread(p, origin, target); });
        candidates.sort([](Unit* a, Unit* b)
        {
            return uint64(a->GetHealth()) * b->GetMaxHealth() < uint64(b->GetHealth()) * a->GetMaxHealth();
        });
        uint8 attempts = 0;
        for (Unit* target : candidates)
        {
            if (attempts >= 2 || Count(p) >= 5) break;
            if (!CanSpread(p, origin, target)) continue;
            ++attempts;
            p->CastSpell(target, 9001927, true);
        }
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_renewing_mist::Check);
        AfterHit += SpellHitFn(spell_reborn_monk_renewing_mist::Spread);
    }
};

class aura_reborn_monk_renewing_mist : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_renewing_mist);
    bool Validate(SpellInfo const* info) override
    {
        // Do not set native LIMIT_N: it would replace the first target before this hook.
        // Spellsteal cannot transfer this caster-bound registry to a non-Monk caster.
        return !info->HasAttribute(SPELL_ATTR5_LIMIT_N) &&
            info->HasAttribute(SPELL_ATTR4_CANNOT_BE_STOLEN);
    }
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        // Aura access is restricted to a real hook (never an external initializer).
        Player* p = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!p || p->getClass() != MONK_CLASS_ID)
        {
            Remove();
            return;
        }
        Aura* current = GetAura();
        auto& tracked = p->GetSingleCastAuras();
        // Use the core-owned list: RemoveOwnedAura unregisters on expiry/dispel/death,
        // and RemoveNotOwnSingleTargetAuras handles leaving the map/logout.
        // Reapplication moves this same aura to the newest position, without a duplicate.
        tracked.remove(current);
        current->SetIsSingleTarget(true);
        tracked.push_back(current);

        std::vector<Aura*> ours;
        for (Aura* aura : tracked)
            if (aura->GetId() == 9001927 && !aura->IsRemoved() &&
                aura->GetCasterGUID() == p->GetGUID())
                ours.push_back(aura);
        // Snapshot before removing: Remove() mutates the native list.
        for (size_t i = 0; i + 5 < ours.size(); ++i)
            ours[i]->Remove();
    }
    void Tick(AuraEffect const*)
    {
        Player* p = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        // Removing the learned spell (e.g. leaving Classic mode) ends outstanding HoTs
        // before the next native heal. No extra timer or global player state is needed.
        if (!p || p->getClass() != MONK_CLASS_ID || !p->HasSpell(9001927))
        {
            PreventDefaultAction();
            Remove();
        }
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_monk_renewing_mist::Applied,
            EFFECT_0, SPELL_AURA_PERIODIC_HEAL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_renewing_mist::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_HEAL);
    }
};

// MONKMWS3: native area heal, selected only from this caster's Renewing Mist registry.
class spell_reborn_monk_uplift : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_uplift);
    bool _paid = false;
    std::vector<ObjectGuid> _targets;
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({9001927, 9001552, MONK_CHI_AURA_ID});
    }
    bool Eligible(Player* p, Unit* target)
    {
        return p && target && target->IsInWorld() && target->IsAlive() &&
            p->InSamePhase(target) && p->IsWithinDistInMap(target, 40.0f) &&
            p->IsWithinLOSInMap(target) && p->IsInRaidWith(target) &&
            p->IsValidAssistTarget(target) && target->GetAura(9001927, p->GetGUID());
    }
    std::vector<Unit*> Collect(Player* p)
    {
        std::vector<Unit*> result;
        if (!p) return result;
        for (Aura* aura : p->GetSingleCastAuras())
        {
            if (aura->IsRemoved() || aura->GetId() != 9001927 ||
                aura->GetCasterGUID() != p->GetGUID())
                continue;
            Unit* target = aura->GetUnitOwner();
            if (Eligible(p, target) && std::find(result.begin(), result.end(), target) == result.end())
                result.push_back(target);
        }
        // Defensive cap even if an old build or test command left extra applications.
        if (result.size() > 5) result.resize(5);
        return result;
    }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p || p->getClass() != MONK_CLASS_ID || !p->HasSpell(9001928) || !p->HasSpell(9001927))
            return SPELL_FAILED_BAD_TARGETS;
        if (!p->HasAura(9001552))
            return MonkAnchorError(p, "请先切换到灵蛇式。 / Switch to Serpent Stance first.");
        Aura* chi = p->GetAura(MONK_CHI_AURA_ID);
        if (!chi || chi->GetStackAmount() < 2)
            return MonkAnchorError(p, "真气点不足，需要2点真气。 / Not enough Chi. Requires 2 Chi.");
        if (Collect(p).empty())
            return MonkAnchorError(p, "40码内没有本人复苏之雾覆盖的存活队友。 / No eligible ally with your Renewing Mist within 40 yards.");
        return SPELL_CAST_OK;
    }
    void Select(std::list<WorldObject*>& targets)
    {
        targets.clear();
        _targets.clear();
        Player* p = GetCaster()->ToPlayer();
        for (Unit* target : Collect(p))
        {
            targets.push_back(target);
            _targets.push_back(target->GetGUID());
        }
        // Core checks the finished state immediately after SelectSpellTargets.
        if (targets.empty())
            FinishCast(MonkAnchorError(p, "没有符合条件的复苏之雾目标。 / No eligible Renewing Mist targets."));
    }
    void Pay()
    {
        if (_paid) return;
        Player* p = GetCaster()->ToPlayer();
        bool any = false;
        if (p && p->getClass() == MONK_CLASS_ID && p->HasAura(9001552) && p->HasSpell(9001928) && p->HasSpell(9001927))
            for (ObjectGuid guid : _targets)
                if (Eligible(p, ObjectAccessor::GetUnit(*p, guid))) { any = true; break; }
        if (!any) return;
        Aura* chi = p->GetAura(MONK_CHI_AURA_ID);
        if (!chi || chi->GetStackAmount() < 2)
        {
            MonkAnchorError(p, "真气点不足，需要2点真气。 / Not enough Chi. Requires 2 Chi.");
            return;
        }
        _paid = true; // Commit before the aura change; never pay per target.
        chi->ModStackAmount(-2);
    }
    void Launch(SpellEffIndex effect)
    {
        if (!_paid || !Eligible(GetCaster()->ToPlayer(), GetHitUnit()))
            PreventHitDefaultEffect(effect); // Skip native HEAL entirely, including its AP bonus.
    }
    void BeforeHealing(SpellMissInfo)
    {
        if (!_paid || !Eligible(GetCaster()->ToPlayer(), GetHitUnit()))
            PreventHitHeal();
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_uplift::Check);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_monk_uplift::Select,
            EFFECT_0, TARGET_UNIT_CASTER_AREA_RAID);
        OnCast += SpellCastFn(spell_reborn_monk_uplift::Pay);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_uplift::Launch, EFFECT_0, SPELL_EFFECT_HEAL);
        BeforeHit += BeforeSpellHitFn(spell_reborn_monk_uplift::BeforeHealing);
    }
};

// MONKMWS4: Life Cocoon. Finite native absorb, independent of Brewmaster Guard.
class spell_reborn_monk_life_cocoon : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_life_cocoon);

    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != 14 || player->GetLevel() < 40 || !player->HasSpell(9001929))
            return SPELL_FAILED_SPELL_UNAVAILABLE;
        if (!player->HasAura(9001552))
            return MonkAnchorError(player, "作茧缚命需要灵蛇式");
        return SPELL_CAST_OK;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_life_cocoon::Check);
    }
};

class aura_reborn_monk_life_cocoon : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_life_cocoon);

    void Capacity(AuraEffect const*, int32& amount, bool& canRecalculate)
    {
        // Snapshot once on application: taking damage must never refill this shield.
        canRecalculate = false;
        Unit* caster = GetCaster();
        if (!caster)
        {
            amount = 0;
            return;
        }
        double const health = double(caster->GetMaxHealth());
        double const attackPower = RebornMonkHealingPower(caster);
        double const capacity = std::min(health, health * 0.50 + attackPower * 2.0);
        amount = int32(std::min(double(INT32_MAX), std::max(1.0, capacity)));
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_monk_life_cocoon::Capacity, EFFECT_0, SPELL_AURA_SCHOOL_ABSORB);
    }
};


// MONKMWS5: one pending choice, stored in the caster's native tea aura.
class spell_reborn_monk_thunder_focus_tea : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_thunder_focus_tea);
    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != 14 || player->GetLevel() < 46 || !player->HasSpell(9001930))
            return SPELL_FAILED_SPELL_UNAVAILABLE;
        if (!player->HasAura(9001552))
            return MonkAnchorError(player, "雷光聚神茶需要灵蛇式");
        return SPELL_CAST_OK;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_thunder_focus_tea::Check);
    }
};

// Additional binding on Surging 9001926 and Renewing 9001927 only.
class spell_reborn_monk_thunder_focus_choice : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_thunder_focus_choice);
    bool _spent = false;

    Aura* Pending()
    {
        Player* player = GetCaster()->ToPlayer();
        if (GetSpell()->IsTriggered() || _spent || !player || player->getClass() != 14 || !player->HasSpell(9001930) || !player->HasAura(9001552))
            return nullptr;
        return player->GetAura(9001930, player->GetGUID());
    }

    void BoostHeal(SpellMissInfo missInfo)
    {
        if (GetSpellInfo()->Id != 9001926 || missInfo != SPELL_MISS_NONE || GetHitHeal() <= 0)
            return;
        if (Aura* tea = Pending())
        {
            int64 const healing = int64(GetHitHeal()) * 150 / 100;
            _spent = true;
            tea->Remove();
            SetHitHeal(int32(std::min<int64>(INT32_MAX, healing)));
        }
    }

    void ExtendMist()
    {
        if (GetSpellInfo()->Id != 9001927)
            return;
        Aura* mist = GetHitAura();
        if (!mist || mist->IsRemoved() || mist->GetId() != 9001927 || mist->GetCasterGUID() != GetCaster()->GetGUID())
            return;
        if (Aura* tea = Pending())
        {
            _spent = true;
            tea->Remove();
            // Fixed total duration, never +6 repeatedly on the same aura.
            // Native refresh resets the base duration before this AfterHit hook.
            mist->SetMaxDuration(30000);
            mist->SetDuration(30000);
        }
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_reborn_monk_thunder_focus_choice::BoostHeal);
        AfterHit += SpellHitFn(spell_reborn_monk_thunder_focus_choice::ExtendMist);
    }
};


// MONKMWS6: bounded emergency group healing. Not resurrection or mass dispel.
class spell_reborn_monk_revival : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_revival);

    bool Eligible(Unit* target)
    {
        Player* player = GetCaster()->ToPlayer();
        return player && target && target->IsInWorld() && target->IsAlive()
            && target->GetHealth() < target->GetMaxHealth()
            && player->InSamePhase(target) && player->IsInRaidWith(target)
            && player->IsValidAssistTarget(target)
            && player->IsWithinDistInMap(target, 40.0f)
            && player->IsWithinLOSInMap(target);
    }

    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->getClass() != 14 || player->GetLevel() < 70 || !player->HasSpell(9001931))
            return SPELL_FAILED_SPELL_UNAVAILABLE;
        if (!player->HasAura(9001552))
            return MonkAnchorError(player, "还魂术需要灵蛇式");
        return SPELL_CAST_OK;
    }

    void Select(std::list<WorldObject*>& targets)
    {
        targets.remove_if([this](WorldObject* object) { return !Eligible(object->ToUnit()); });
        // Stable ordering for equal health fractions; cross products avoid integer division.
        targets.sort([](WorldObject* left, WorldObject* right)
        {
            Unit* a = left->ToUnit();
            Unit* b = right->ToUnit();
            return uint64(a->GetHealth()) * b->GetMaxHealth() < uint64(b->GetHealth()) * a->GetMaxHealth();
        });
        if (targets.size() > 5)
            targets.resize(5);
        if (targets.empty())
            FinishCast(MonkAnchorError(GetCaster()->ToPlayer(), "40码内没有符合条件的受伤队友"));
    }

    void Launch(SpellEffIndex effect)
    {
        if (!Eligible(GetHitUnit()))
            PreventHitDefaultEffect(effect);
    }

    void BeforeHealing(SpellMissInfo)
    {
        if (!Eligible(GetHitUnit()))
            PreventHitHeal();
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_revival::Check);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_monk_revival::Select, EFFECT_0, TARGET_UNIT_CASTER_AREA_RAID);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_revival::Launch, EFFECT_0, SPELL_EFFECT_HEAL);
        BeforeHit += BeforeSpellHitFn(spell_reborn_monk_revival::BeforeHealing);
    }
};


// MONKMWS7: bounded reactive healing statue. No autonomous healing.
namespace
{
constexpr uint32 MONK_JADE_STATUE = 9001932;
constexpr uint32 MONK_JADE_PRESENCE = 9001933;
constexpr uint32 MONK_JADE_ENTRY = 900187;
bool MonkJadeOwner(Player* p)
{
    return p && p->IsInWorld() && p->IsAlive() && p->getClass() == MONK_CLASS_ID &&
        p->HasAura(9001552) && p->HasActiveSpell(MONK_JADE_STATUE);
}
}

class aura_reborn_monk_jade_presence : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_jade_presence);
public:
    ObjectGuid StatueGuid;
    uint8 Spec = 0;
    std::chrono::steady_clock::time_point NextHeal{};
    void Initialize(ObjectGuid guid, uint8 spec) { StatueGuid = guid; Spec = spec; }
    bool Respond(Player* p, Unit* target, uint32 effectiveHealing)
    {
        // Called from a SpellScript, not an aura hook: GetTarget() is not available here.
        if (!p) return false;
        Creature* statue = ObjectAccessor::GetCreature(*p, StatueGuid);
        auto now = std::chrono::steady_clock::now();
        if (!MonkJadeOwner(p) || p->GetActiveSpec() != Spec || !statue || !statue->IsAlive() ||
            now < NextHeal || !statue->InSamePhase(p) || !statue->IsWithinDistInMap(p, 40.0f) ||
            !target || !target->IsInWorld() || !target->IsAlive() || target->IsFullHealth() ||
            !p->IsInRaidWith(target) || !p->IsValidAssistTarget(target) || !statue->InSamePhase(target) ||
            !statue->IsWithinDistInMap(target, 40.0f) || !statue->IsWithinLOSInMap(target))
            return false;
        uint32 amount = std::min(effectiveHealing / 4, p->GetMaxHealth() / 10);
        if (!amount) return false;
        NextHeal = now + std::chrono::milliseconds(2000);
        statue->CastCustomSpell(9001934, SPELLVALUE_BASE_POINT0, int32(std::min<uint32>(amount, INT32_MAX)),
            target, true, nullptr, nullptr, p->GetGUID());
        return true;
    }

private:
    void Tick(AuraEffect const*)
    {
        Player* p = GetTarget()->ToPlayer();
        Creature* statue = ObjectAccessor::GetCreature(*GetTarget(), StatueGuid);
        if (!MonkJadeOwner(p) || p->GetActiveSpec() != Spec || !statue || !statue->IsAlive() ||
            !statue->InSamePhase(p) || !statue->IsWithinDistInMap(p, 40.0f))
            Remove();
    }
    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Creature* statue = ObjectAccessor::GetCreature(*GetTarget(), StatueGuid))
            statue->DespawnOrUnsummon(Milliseconds(1));
    }
    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_monk_jade_presence::Tick, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_monk_jade_presence::End, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_reborn_monk_jade_statue : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_jade_statue);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({MONK_JADE_PRESENCE}); }
    SpellCastResult Check()
    {
        Player* p = GetCaster()->ToPlayer();
        if (!p) return SPELL_FAILED_BAD_TARGETS;
        if (!MonkJadeOwner(p))
            return MonkAnchorError(p, "请先切换到青龙式。 / Switch to Serpent Stance first.");
        if (!sObjectMgr->GetCreatureTemplate(MONK_JADE_ENTRY))
            return MonkAnchorError(p, "青龙雕像数据未安装。 / Jade Serpent Statue data is missing.");
        return SPELL_CAST_OK;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_reborn_monk_jade_statue::Check); }
};

class npc_reborn_monk_jade_statue : public CreatureScript
{
public:
    npc_reborn_monk_jade_statue() : CreatureScript("npc_reborn_monk_jade_statue") { }
    struct AI : public ScriptedAI
    {
        AI(Creature* c) : ScriptedAI(c) { }
        uint32 timer = 1000;
        uint8 spec = 0;
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* p = summoner ? summoner->ToPlayer() : nullptr;
            if (!MonkJadeOwner(p)) { me->DespawnOrUnsummon(Milliseconds(1)); return; }
            spec = p->GetActiveSpec();
            me->SetOwnerGUID(p->GetGUID());
            me->SetCreatorGUID(p->GetGUID());
            me->SetFaction(p->GetFaction());
            me->SetLevel(p->GetLevel());
            me->SetReactState(REACT_PASSIVE);
            me->SetControlled(true, UNIT_STATE_ROOT);
            me->GetMotionMaster()->Clear();
            me->GetMotionMaster()->MoveIdle();
            me->SetMaxHealth(std::max<uint32>(1, p->GetMaxHealth() / 2));
            me->SetHealth(me->GetMaxHealth());
            // Removing the owner's old presence despawns only its own old GUID.
            p->RemoveAurasDueToSpell(MONK_JADE_PRESENCE);
            p->CastSpell(p, MONK_JADE_PRESENCE, true);
            Aura* aura = p->GetAura(MONK_JADE_PRESENCE);
            auto* state = aura ? aura->GetScript<aura_reborn_monk_jade_presence>("aura_reborn_monk_jade_presence") : nullptr;
            if (!state) { me->DespawnOrUnsummon(Milliseconds(1)); return; }
            // R1 convention: no GetTarget() outside an aura application hook.
            state->Initialize(me->GetGUID(), spec);
        }
        void UpdateAI(uint32 diff) override
        {
            if (timer > diff) { timer -= diff; return; }
            timer = 1000;
            Player* p = me->GetOwner() ? me->GetOwner()->ToPlayer() : nullptr;
            Aura* aura = p ? p->GetAura(MONK_JADE_PRESENCE) : nullptr;
            auto* state = aura ? aura->GetScript<aura_reborn_monk_jade_presence>("aura_reborn_monk_jade_presence") : nullptr;
            if (!MonkJadeOwner(p) || p->GetActiveSpec() != spec || !state || state->StatueGuid != me->GetGUID() ||
                !me->InSamePhase(p) || !me->IsWithinDistInMap(p, 40.0f))
            { me->DespawnOrUnsummon(Milliseconds(1)); return; }
            if (!me->IsAlive()) return;
        }
    };
    CreatureAI* GetAI(Creature* c) const override { return new AI(c); }
};

class spell_reborn_monk_jade_response : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_jade_response);
    bool used = false;
    void Healed()
    {
        uint32 id = GetSpellInfo()->Id;
        if (used || (id != 9001926 && id != 9001928 && id != 9001931) ||
            GetSpell()->IsTriggered() || GetHitHeal() <= 0)
            return;
        Player* p = GetCaster()->ToPlayer();
        if (!MonkJadeOwner(p)) return;
        Aura* aura = p->GetAura(MONK_JADE_PRESENCE);
        auto* state = aura ? aura->GetScript<aura_reborn_monk_jade_presence>("aura_reborn_monk_jade_presence") : nullptr;
        if (state) used = state->Respond(p, GetHitUnit(), uint32(GetHitHeal()));
    }
    void Register() override
    {
        AfterHit += SpellHitFn(spell_reborn_monk_jade_response::Healed);
    }
};


// MONKHEALH1: effective manual Surging Mist grants one Chi per cast.
class spell_reborn_monk_surging_chi : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_surging_chi);
    bool _granted = false;

    void GrantChi()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (_granted || !player || player->getClass() != MONK_CLASS_ID ||
            !player->IsAlive() || !player->HasSpell(9001926) ||
            !player->HasAura(9001552) || GetSpell()->IsTriggered() ||
            GetHitHeal() <= 0)
            return;
        _granted = true;
        RebornMonkAddChi(player, 1);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_reborn_monk_surging_chi::GrantChi);
    }
};

// H3: Resolve coverage for new heals. Existing Soothing/Enveloping hooks stay intact.
class spell_reborn_monk_resolve_direct : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_resolve_direct);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001712, 9001552}); }
    void Boost(SpellMissInfo miss)
    {
        uint32 id = GetSpellInfo()->Id;
        if ((id != 9001926 && id != 9001928 && id != 9001931) ||
            miss != SPELL_MISS_NONE || GetHitHeal() <= 0 || GetSpell()->IsTriggered())
            return;
        // BeforeHit is per target: Uplift/Revival receive the bonus on every valid heal.
        SetHitHeal(RebornMonkScaleResolve(GetCaster(), GetHitHeal(), 9001712, 9001552, 10));
    }
    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_reborn_monk_resolve_direct::Boost);
    }
};

class aura_reborn_monk_resolve_renewing : public AuraScript
{
    PrepareAuraScript(aura_reborn_monk_resolve_renewing);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9001712, 9001552}); }
    void Amount(AuraEffect const*, int32& amount, bool& recalculate)
    {
        // Core supplies the native AP/level/healing-modified amount here.
        // Snapshot once on application/refresh, including H2 spread copies.
        recalculate = false;
        Unit* caster = GetCaster();
        amount = caster ? int32(std::min<uint32>(INT32_MAX,
            caster->SpellHealingBonusDone(GetAura()->GetUnitOwner(), GetSpellInfo(),
                RebornMonkHealingValue(caster, 0.15, 1.0), DOT, EFFECT_0))) : 0;
        amount = RebornMonkScaleResolve(GetCaster(), amount, 9001712, 9001552, 10);
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_monk_resolve_renewing::Amount,
            EFFECT_0, SPELL_AURA_PERIODIC_HEAL);
    }
};

// H6: native direct-heal pipeline retains crit, healing modifiers and absorbs.
class spell_reborn_monk_healing_equipment : public SpellScript
{
    PrepareSpellScript(spell_reborn_monk_healing_equipment);
    void Base(SpellEffIndex)
    {
        switch (GetSpellInfo()->Id)
        {
            case 9001926: SetEffectValue(RebornMonkHealingValue(GetCaster(), 0.90, 6.0)); break;
            case 9001928: SetEffectValue(RebornMonkHealingValue(GetCaster(), 0.60, 4.0)); break;
            case 9001931: SetEffectValue(RebornMonkHealingValue(GetCaster(), 1.50, 8.0)); break;
            default: break;
        }
    }
    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_monk_healing_equipment::Base, EFFECT_0, SPELL_EFFECT_HEAL);
    }
};
void AddSpellDraftMonkScripts()
{
    RegisterSpellScript(spell_reborn_monk_healing_equipment);
    RegisterSpellScript(spell_reborn_monk_resolve_direct);
    RegisterSpellScript(aura_reborn_monk_resolve_renewing);
    RegisterSpellScript(spell_reborn_monk_surging_chi);
    RegisterSpellScript(spell_reborn_monk_jade_statue);
    RegisterSpellScript(aura_reborn_monk_jade_presence);
    RegisterSpellScript(spell_reborn_monk_jade_response);
    new npc_reborn_monk_jade_statue();
    RegisterSpellScript(spell_reborn_monk_revival);
    RegisterSpellScript(spell_reborn_monk_thunder_focus_tea);
    RegisterSpellScript(spell_reborn_monk_thunder_focus_choice);
    RegisterSpellScript(spell_reborn_monk_life_cocoon);
    RegisterSpellScript(aura_reborn_monk_life_cocoon);
    RegisterSpellScript(spell_reborn_monk_uplift);
    RegisterSpellScript(spell_reborn_monk_renewing_mist);
    RegisterSpellScript(aura_reborn_monk_renewing_mist);
    RegisterSpellScript(spell_reborn_monk_ox_statue);
    RegisterSpellScript(aura_reborn_monk_ox_presence);
    new npc_reborn_monk_ox_statue();
    RegisterSpellScript(spell_reborn_monk_breath_fire);
    RegisterSpellScript(spell_reborn_monk_keg_smash);
    RegisterSpellScript(aura_reborn_monk_karma_shield);
    RegisterSpellScript(spell_reborn_monk_touch_karma);
    RegisterSpellScript(spell_reborn_monk_karma_return);
    RegisterSpellScript(spell_reborn_monk_touch_death);
    RegisterSpellScript(aura_reborn_monk_anchor_ready);
    RegisterSpellScript(spell_reborn_monk_transcendence);
    RegisterSpellScript(spell_reborn_monk_transcendence_transfer);
    new player_reborn_monk_anchor_cleanup();
    RegisterSpellScript(aura_reborn_bw3_guard_link);
    RegisterSpellScript(aura_reborn_bw3_purifying_guard);
    RegisterSpellScript(spell_reborn_bw3_mastery);
    RegisterSpellScript(spell_reborn_monk_purifying_brew);
    RegisterSpellScript(aura_reborn_monk_lingering_guard);
    RegisterSpellScript(aura_reborn_monk_lingering_guard_buff);
    RegisterSpellScript(aura_reborn_ww4_state);
    RegisterSpellScript(aura_reborn_ww4_fists);
    RegisterSpellScript(spell_reborn_ww4_fists_pulse);
    RegisterSpellScript(spell_reborn_ww4_mastery);
    RegisterSpellScript(aura_reborn_ww4_xuen_presence);
    RegisterSpellScript(spell_reborn_ww4_xuen);
    new npc_reborn_ww4_xuen();

    new spell_reborn_monk_fists_training();
    new spell_reborn_monk_crane_training();
    new spell_reborn_monk_blackout_training();
    new spell_reborn_monk_tiger_resolve();
    RegisterSpellScript(spell_reborn_monk_mist_channel);
    RegisterSpellScript(spell_reborn_monk_jade_lightning_pulse);
    RegisterSpellScript(spell_reborn_monk_stance);
    RegisterSpellScript(spell_reborn_monk_chi_brew);
    RegisterSpellScript(spell_reborn_monk_soothing_pulse);
    RegisterSpellScript(spell_reborn_monk_enveloping);
    RegisterSpellScript(aura_reborn_monk_enveloping);

    RegisterSpellScript(aura_reborn_monk_jade_wind);
    RegisterSpellScript(spell_reborn_monk_jade_wind);
    RegisterSpellScript(spell_reborn_monk_jade_wind_pulse);
    RegisterSpellScript(spell_reborn_monk_guard);
    RegisterSpellScript(aura_reborn_monk_guard);
    RegisterSpellScript(spell_reborn_monk_zen);
    RegisterSpellScript(aura_reborn_monk_zen);

    RegisterSpellScript(spell_reborn_monk_flying_serpent_kick);
    RegisterSpellScript(aura_reborn_monk_flying_serpent_kick);
    RegisterSpellScript(spell_reborn_monk_flying_serpent_land);
    RegisterSpellScript(spell_reborn_monk_nimble_brew);
    RegisterSpellScript(aura_reborn_monk_nimble_brew);
    RegisterSpellScript(aura_reborn_monk_spinning_crane_kick);
    RegisterSpellScript(spell_reborn_monk_spinning_crane_kick);
    RegisterSpellScript(spell_reborn_monk_spinning_crane_pulse);
    RegisterSpellScript(spell_reborn_monk_disable);
    RegisterSpellScript(aura_reborn_monk_disable);
    RegisterSpellScript(spell_reborn_monk_energizing_brew);
    RegisterSpellScript(spell_reborn_monk_provoke);
    RegisterSpellScript(spell_reborn_monk_paralysis);
    RegisterSpellScript(spell_reborn_monk_tigers_lust);
    RegisterSpellScript(spell_reborn_monk_dampen_harm);
    RegisterSpellScript(spell_reborn_monk_fists_of_fury);
    RegisterSpellScript(spell_reborn_monk_spear_hand_strike);
    RegisterSpellScript(spell_reborn_monk_jab);
    RegisterSpellScript(spell_reborn_monk_rising_sun_kick);
    new spell_reborn_monk_rising_sun_kick_vulnerability();
    RegisterSpellScript(spell_reborn_monk_expel_harm);
    RegisterSpellScript(spell_reborn_monk_roll);
    RegisterSpellScript(aura_reborn_monk_arch_roll_end);
    RegisterSpellScript(aura_reborn_monk_arch_sobering);
    RegisterSpellScript(aura_reborn_monk_arch_mist_start);
    RegisterSpellScript(aura_reborn_monk_arch_continuity_ready);
    RegisterSpellScript(spell_reborn_monk_mist_mastery);
    RegisterSpellScript(aura_reborn_monk_mist_mastery);
    RegisterSpellScript(aura_reborn_monk_calm_within);
    RegisterSpellScript(aura_reborn_monk_crane_momentum_ready);
    RegisterSpellScript(aura_reborn_monk_fists_recovery);
    RegisterSpellScript(aura_reborn_monk_crane_rebound);
    RegisterSpellScript(aura_reborn_monk_crane_rebound_speed);
    RegisterSpellScript(spell_reborn_monk_tiger_palm_animation);
    RegisterSpellScript(spell_reborn_monk_blackout_kick);
}
