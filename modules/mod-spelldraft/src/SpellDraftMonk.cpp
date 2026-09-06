#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "MotionMaster.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"

#include <algorithm>
#include <list>

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

    void Register() override
    {
        OnCast += SpellCastFn(spell_reborn_monk_jab::PreserveMovingAnimation);
        AfterHit += SpellHitFn(spell_reborn_monk_jab::GenerateChi);
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

        chi->ModStackAmount(-MONK_RISING_SUN_KICK_CHI_COST);
        _chiConsumed = true;
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

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_rising_sun_kick::CheckChi);
        OnCast += SpellCastFn(spell_reborn_monk_rising_sun_kick::PreserveMovingAnimation);
        AfterHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::ApplyMortalWounds);
        AfterHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::ApplyNearbyVulnerability);
        AfterHit += SpellHitFn(spell_reborn_monk_rising_sun_kick::ConsumeChi);
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

    void Register() override
    {
        OnCast += SpellCastFn(spell_reborn_monk_tiger_palm_animation::PreserveMovingAnimation);
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
        int32 damage = GetHitDamage();
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

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_monk_blackout_kick::CheckChi);
        OnCast += SpellCastFn(spell_reborn_monk_blackout_kick::CaptureCastContext);
        AfterHit += SpellHitFn(spell_reborn_monk_blackout_kick::ApplyCombatConditioning);
        AfterHit += SpellHitFn(spell_reborn_monk_blackout_kick::ConsumeChi);
    }
};

void AddSpellDraftMonkScripts()
{
    RegisterSpellScript(spell_reborn_monk_jab);
    RegisterSpellScript(spell_reborn_monk_rising_sun_kick);
    new spell_reborn_monk_rising_sun_kick_vulnerability();
    RegisterSpellScript(spell_reborn_monk_expel_harm);
    RegisterSpellScript(spell_reborn_monk_roll);
    RegisterSpellScript(spell_reborn_monk_tiger_palm_animation);
    RegisterSpellScript(spell_reborn_monk_blackout_kick);
}
