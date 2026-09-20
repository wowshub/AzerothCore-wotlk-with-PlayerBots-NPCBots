// WD3: isolated level-one Witch Doctor mechanics adapted from local CoA.
// CoA AscensionWitchDoctorAbilities.cpp: previousBrew, effective healing / 2.
#include "ScriptMgr.h"
#include "RebornWitchDoctorRanks.h"
#include <unordered_set>
#include <vector>
#include <utility>
#include "SpellScript.h"
#include "Spell.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "SpellAuraEffects.h"
#include "Player.h"
#include "ObjectAccessor.h"
#include "DataMap.h"
#include "DatabaseEnv.h"
#include "ScriptedGossip.h"
#include "Creature.h"
#include "TemporarySummon.h"
#include "ScriptedCreature.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include <list>
#include "Chat.h"
#include "WorldSession.h"
#include "ObjectMgr.h"
#include "Trainer.h"
#include <algorithm>

namespace WD5A { bool CanCastBadJuju(Player* player); void TrainerOptions(Player* player); void TrainerPurchase(Player* player); }

namespace
{
constexpr uint32 Wrath = 9003100;
constexpr uint32 Brew = 9003101;
constexpr uint32 Echo = 9003102;
constexpr uint32 Hex = 9003104;
constexpr uint32 Mark = 9003105;
uint32 BestKnownRank(Player* player, WD19A::Family const& family)
{
    for (std::size_t i=family.count; i>0; --i)
    {
        WD19A::Rank const& rank=family.ranks[i-1];
        if (player->GetLevel()>=rank.level && player->HasSpell(rank.spell)) return rank.spell;
    }
    return 0;
}
constexpr uint16 WitchDoctorSkill = 9004;
constexpr char StateKey[] = "RebornWD3.PreviousBrew";
struct BrewState : DataMap::Base { ObjectGuid previous; };
bool IsDoctor(Player const* player)
{
    return player && player->getClass() == 13 && player->getRace() == 1;
}
// Base class skill: available in every specialization, no talent point is consumed.
void SyncRanks(Player* player)
{
    if (!IsDoctor(player)) return;
    for (WD19A::Family const& family : WD19A::Families)
        for (std::size_t i=0; i<family.count; ++i)
            if (!sSpellMgr->GetSpellInfo(family.ranks[i].spell)) return;
    // Sentinel gives empty ledgers one row. A null result means query/schema failure;
    // do not change any existing skills or action buttons in that case.
    QueryResult ledger=CharacterDatabase.Query(
        "SELECT spell FROM reborn_wd12_training WHERE guid={} UNION ALL SELECT 0",
        player->GetGUID().GetCounter());
    if (!ledger) return;
    std::unordered_set<uint32> purchased;
    do { purchased.insert(ledger->Fetch()[0].Get<uint32>()); } while (ledger->NextRow());
    WD19A::Family const* buttons[MAX_ACTION_BUTTONS] = {};
    for (uint8 button=0; button<MAX_ACTION_BUTTONS; ++button)
        if (ActionButton const* action=player->GetActionButton(button))
            if (action->GetType()==ACTION_BUTTON_SPELL)
                buttons[button]=WD19A::FindFamily(action->GetAction());
    for (WD19A::Family const& family : WD19A::Families)
    {
        int acquired=family.starter ? 0 : -1;
        for (std::size_t i=0; i<family.count; ++i)
            if (purchased.count(family.ranks[i].spell)) acquired=int(i);
        for (std::size_t i=family.count; i>0; --i)
        {
            WD19A::Rank const& rank=family.ranks[i-1];
            if (player->GetLevel()<rank.level && player->HasSpell(rank.spell))
                player->removeSpell(rank.spell,3,false);
        }
        // Higher ranks can only be recovered from this family's purchase history.
        // Native training requires each previous rank, so a higher purchase proves
        // the earlier ranks were acquired. Leveling alone is never a purchase.
        for (int i=0; i<=acquired; ++i)
        {
            WD19A::Rank const& rank=family.ranks[i];
            if (player->GetLevel()>=rank.level && !player->HasSpell(rank.spell))
                player->learnSpell(rank.spell);
        }
    }
    bool changed=false;
    for (uint8 button=0; button<MAX_ACTION_BUTTONS; ++button)
        if (buttons[button])
        {
            uint32 best=BestKnownRank(player,*buttons[button]);
            ActionButton const* action=player->GetActionButton(button);
            if (action && action->GetAction()==best) continue;
            player->removeActionButton(button);
            if (best) player->addActionButton(button,best,ACTION_BUTTON_SPELL);
            changed=true;
        }
    if (changed) player->SendActionButtons(1);
}
}

namespace WD19A
{
uint32 ResolveAction(Player* player, uint32 spell)
{
    Family const* family=FindFamily(spell);
    return IsDoctor(player) && family ? BestKnownRank(player,*family) : spell;
}
}

class spell_reborn_wd3_birth : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd3_birth);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({Wrath, Brew, Echo});
    }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        uint32 id=GetSpellInfo()->Id;
        return IsDoctor(player) && (WD19A::IsWrath(id) || WD19A::IsBrew(id)) &&
            player->GetLevel()>=GetSpellInfo()->SpellLevel && player->HasSpell(id)
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void AddCoACoefficient(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        if (!IsDoctor(player))
            return;
        bool healing = WD19A::IsBrew(GetSpellInfo()->Id);
        int32 power = healing ? player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)
                              : player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE);
        float coefficient = healing ? 0.84f : 0.625f;
        // CoA adds power to base value before native done/taken modifiers.
        // SQL disables native coefficients to avoid double scaling and low-rank penalties.
        float bonus=float(std::max(0,power))*coefficient;
        // Donor contract: rank one has zero RAP; Wrath ranks 2-9 have 11% RAP.
        if (!healing && GetSpellInfo()->Id!=Wrath)
            bonus+=std::max(0.0f,player->GetTotalAttackPowerValue(RANGED_ATTACK))*0.11f;
        SetEffectValue(int32(float(GetEffectValue())+bonus));
    }
    void AfterBrew()
    {
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!IsDoctor(player) || !WD19A::IsBrew(GetSpellInfo()->Id) || GetSpell()->IsTriggered() || !target)
            return;
        BrewState* state = player->CustomData.GetDefault<BrewState>(StateKey);
        if (state->previous == target->GetGUID())
            return;
        ObjectGuid previousGuid = state->previous;
        // Update even after a fully overhealed successful cast, exactly like CoA.
        state->previous = target->GetGUID();
        Unit* previous = ObjectAccessor::GetUnit(*player, previousGuid);
        int32 amount = std::max(0, GetHitHeal()) / 2;
        if (!amount || !previous || !previous->IsAlive() || !player->IsInMap(previous) ||
            !player->InSamePhase(previous) || !player->IsFriendlyTo(previous) ||
            (player != previous && !player->IsInRaidWith(previous)) ||
            !player->IsWithinDistInMap(previous, 40.0f))
            return;
        player->CastCustomSpell(Echo, SPELLVALUE_BASE_POINT0, amount, previous, true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd3_birth::CheckDoctor);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd3_birth::AddCoACoefficient, EFFECT_0, SPELL_EFFECT_ANY);
        AfterHit += SpellHitFn(spell_reborn_wd3_birth::AfterBrew);
    }
};

class reborn_wd3_player : public PlayerScript
{
public:
    reborn_wd3_player() : PlayerScript("reborn_wd3_player") { }
    void OnPlayerLogin(Player* player) override
    {
        if (!IsDoctor(player))
            return;
        // WD5B: repair legacy human Witch Doctors before birth-spell validation.
        // Skill 98 is Common; spell 668 exposes the language to the client.
        if (!player->HasSkill(98))
            player->SetSkill(98, 0, 300, 300);
        if (!player->HasSpell(668) && sSpellMgr->GetSpellInfo(668))
            player->learnSpell(668);

        if (!sSpellMgr->GetSpellInfo(Wrath) ||
            !sSpellMgr->GetSpellInfo(Brew) || !sSpellMgr->GetSpellInfo(Echo))
            return;
        SyncRanks(player);
        player->CustomData.Erase(StateKey);
        if (!player->HasSkill(WitchDoctorSkill))
            player->SetSkill(WitchDoctorSkill, 0, 1, 1);
        if (!player->HasSpell(Wrath))
            player->learnSpell(Wrath);
        if (!player->HasSpell(Brew))
            player->learnSpell(Brew);
    }
    void OnPlayerLevelChanged(Player* player, uint8) override { SyncRanks(player); }
    void OnPlayerLogout(Player* player) override
    {
        player->CustomData.Erase(StateKey);
    }
};

// WD10A: Bad Juju conditionally applies Mark after a damaging hit on a Hexed target.
class spell_reborn_wd9a_bad_juju : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd9a_bad_juju);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003103, Hex, Mark}); }
    SpellCastResult CheckTalent()
    {
        Player* p=GetCaster()->ToPlayer();
        return WD5A::CanCastBadJuju(p) && p->HasSpell(9003103) ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void AddCoefficient(SpellEffIndex)
    {
        Player* p=GetCaster()->ToPlayer();
        if (!IsDoctor(p)) return;
        int32 power=std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW));
        SetEffectValue(int32(float(GetEffectValue())+power+std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.30f));
    }
    bool HasHex(Unit* target)
    {
        for (WD19A::Rank const& rank : WD19A::HexRanks) if (target->HasAura(rank.spell)) return true;
        return false;
    }
    void ApplyMark()
    {
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        // Any Witch Doctor's Hex qualifies, as in CoA. Absorbed/missed hits do not.
        if (IsDoctor(player) && target && target->IsAlive() && GetHitDamage() > 0 && HasHex(target))
            player->CastSpell(target, Mark, true);
    }
    void Register() override
    {
        AfterHit += SpellHitFn(spell_reborn_wd9a_bad_juju::ApplyMark);
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd9a_bad_juju::CheckTalent);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd9a_bad_juju::AddCoefficient,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

// WD11A all eight Hex ranks. SQL sets native SP/AP coefficients to zero;
// these handlers add the verified CoA coefficients before native damage modifiers.
class spell_reborn_wd10a_hex : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd10a_hex);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Hex, Mark}); }
    SpellCastResult CheckDoctor()
    {
        Player* player = GetCaster()->ToPlayer();
        return IsDoctor(player) && player->GetLevel() >= GetSpellInfo()->SpellLevel && player->HasSpell(GetSpellInfo()->Id)
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void DirectCoefficient(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        if (!IsDoctor(player)) return;
        float power = float(std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
        float rangedPower = std::max(0.0f, player->GetTotalAttackPowerValue(RANGED_ATTACK));
        SetEffectValue(int32(float(GetEffectValue()) + power * 0.08f + rangedPower * 0.10f));
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd10a_hex::CheckDoctor);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd10a_hex::DirectCoefficient, EFFECT_1, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};
class aura_reborn_wd10a_hex : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd10a_hex);
    void PeriodicCoefficient(AuraEffect const* effect, int32& amount, bool& canRecalculate)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!IsDoctor(player)) return;
        // Core calls this after native damage scaling. Rebuild from the unscaled
        // stored amount so percentage modifiers are applied exactly once.
        int32 base = effect->GetOldAmount(); // Hex has one stack only.
        int32 power = std::max(0, player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW));
        uint32 scaled = uint32(std::max(0, int32(float(base) + power * 0.05f)));
        amount = int32(player->SpellDamageBonusDone(GetTarget(), GetSpellInfo(), scaled, DOT, EFFECT_0, effect->GetPctMods(), 1));
        canRecalculate = false;
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd10a_hex::PeriodicCoefficient, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

// WD12A: both factions can summon; training permission is checked again by Trainer.cpp.
class npc_reborn_wd12_trainer : public CreatureScript
{
public:
    npc_reborn_wd12_trainer() : CreatureScript("npc_reborn_wd12_trainer") { }
    bool OnGossipHello(Player* p, Creature* npc) override
    {
        ClearGossipMenuFor(p);
        if (IsDoctor(p) && p->IsAlive() && !p->IsInCombat())
        {
            AddGossipItemFor(p,GOSSIP_ICON_TRAINER,"学习巫医技能 / Train Witch Doctor skills",GOSSIP_SENDER_MAIN,1);
            AddGossipItemFor(p,GOSSIP_ICON_CHAT,"打开飞升天赋 / Open talents",GOSSIP_SENDER_MAIN,2);
            WD5A::TrainerOptions(p);
        }
        else ChatHandler(p->GetSession()).SendSysMessage("巫医导师只训练存活且非战斗的巫医。 / Witch Doctors only; leave combat first.");
        SendGossipMenuFor(p,68,npc->GetGUID());
        return true;
    }
    bool OnGossipSelect(Player* p, Creature* npc, uint32 sender, uint32 action) override
    {
        ClearGossipMenuFor(p);
        if (sender!=GOSSIP_SENDER_MAIN || !IsDoctor(p) || !p->IsAlive() || p->IsInCombat())
        {
            CloseGossipMenuFor(p);
            ChatHandler(p->GetSession()).SendSysMessage("WD12B: 请脱战，并使用存活的巫医角色。 / Use a living Witch Doctor out of combat.");
            return true;
        }
        if (action==1)
        {
            // Match native npc_professions: clear menus, but do NOT send GOSSIP_COMPLETE
            // before TRAINER_LIST. Let the native client transition into its trainer frame.
            Trainer::Trainer const* trainer = sObjectMgr->GetTrainer(npc->GetEntry());
            if (!trainer)
            {
                ChatHandler(p->GetSession()).SendSysMessage("WD12B: 服务端尚未加载900189训练映射，请核对WD12A世界库并重启。 / Trainer mapping unavailable; check WD12A world SQL and restart.");
                return true;
            }
            QueryResult ledger = CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_wd12_training WHERE guid={}",p->GetGUID().GetCounter());
            if (!ledger)
            {
                ChatHandler(p->GetSession()).SendSysMessage("WD12B: 技能购买台账读取失败，请检查WD12A角色库SQL。 / Training ledger unavailable; check WD12A character SQL.");
                return true;
            }
            if (!trainer->IsTrainerValidForPlayer(p))
            {
                ChatHandler(p->GetSession()).SendSysMessage("WD12B: 训练权限校验未通过，请核对导师Requirement=13及当前角色职业。 / Trainer eligibility failed; check requirement 13 and player class.");
                return true;
            }
            p->GetSession()->SendTrainerList(npc);
        }
        else if (action==13)
        {
            CloseGossipMenuFor(p);
            WD5A::TrainerPurchase(p);
        }
        else if (action==2)
        {
            CloseGossipMenuFor(p);
            ChatHandler(p->GetSession()).SendSysMessage("WD12A|open");
        }
        return true;
    }
};

// WD20A: adapted from upstream ccd276b6 AscensionWitchDoctorAuras.cpp.
// Match only this port's explicit private families, not donor class-family flags.
namespace
{
uint8 WD20AuraGroup(uint32 spell)
{
    WD19A::Family const* family=WD19A::FindFamily(spell);
    if (!family) return 0;
    if (family->ranks[0].spell==9003140 || family->ranks[0].spell==9003180 || family->ranks[0].spell==9003190 || family->ranks[0].spell==9003280 || family->ranks[0].spell==9003290 || family->ranks[0].spell==9003300) return 1; // Spirit/Power/Resourceful/Greater Resourceful/Greater Spirit/Greater Power Wuju
    if (family->ranks[0].spell==9003150 || family->ranks[0].spell==9003200 || family->ranks[0].spell==9003210 || family->ranks[0].spell==9003220) return 2; // Lethargy/Hireek/Mana/Shrinking Jinx
    return 0;
}
}
class spell_reborn_wd20a_support : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd20a_support);
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        return IsDoctor(player) && WD20AuraGroup(GetSpellInfo()->Id) &&
            player->HasSpell(GetSpellInfo()->Id) && player->GetLevel()>=GetSpellInfo()->SpellLevel
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd20a_support::CheckDoctor);
    }
};
class aura_reborn_wd20a_support : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd20a_support);
    void Applied(AuraEffect const*, AuraEffectHandleModes)
    {
        uint8 group=WD20AuraGroup(GetId());
        if (!group) return;
        Unit* target=GetTarget();
        // Snapshot before erasing. Failed casts, misses and immunities never enter
        // this callback; existing buffs are not removed pre-emptively on cast.
        std::vector<std::pair<uint32,ObjectGuid>> remove;
        for (auto const& entry : target->GetAppliedAuras())
        {
            Aura* aura=entry.second->GetBase();
            if (aura!=GetAura() && WD20AuraGroup(aura->GetId())==group)
                remove.emplace_back(aura->GetId(),aura->GetCasterGUID());
        }
        for (auto const& entry : remove)
            target->RemoveAurasDueToSpell(entry.first,entry.second);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd20a_support::Applied,
            EFFECT_0,SPELL_AURA_ANY,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

// WD21A: base Serpent Ward, adapted from community upstream ccd276b6.
// Keep this temporary summon separate from all native primary pets/guardians.
namespace WD21A
{
constexpr uint32 Ward = 9003160;
constexpr uint32 Attack = 9003161;
constexpr uint32 Entry = 900190;
constexpr uint32 HealingWard = 9003170;
constexpr uint32 Heal = 9003171;
constexpr uint32 HealingEntry = 900191;
bool IsWardEntry(uint32 entry) { return entry==Entry || entry==HealingEntry; }
constexpr char Key[] = "RebornWD21A.Ward";
struct State : DataMap::Base { ObjectGuid guid; };
void Clear(Player* player)
{
    State* state=player->CustomData.GetDefault<State>(Key);
    if (!state->guid.IsEmpty() && player->IsInWorld())
        if (Creature* old=ObjectAccessor::GetCreature(*player,state->guid))
            if (IsWardEntry(old->GetEntry()) && old->GetOwnerGUID()==player->GetGUID())
                old->DespawnOrUnsummon();
    state->guid.Clear();
}
}
class spell_reborn_wd21a_serpent : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd21a_serpent);
    bool _handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({WD21A::Ward,WD21A::Attack,WD21A::HealingWard,WD21A::Heal}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !player->HasSpell(GetSpellInfo()->Id) || player->GetLevel()<GetSpellInfo()->SpellLevel)
            return SPELL_FAILED_CASTER_AURASTATE;
        uint32 entry=GetSpellInfo()->Id==WD21A::HealingWard ? WD21A::HealingEntry : WD21A::Entry;
        return sObjectMgr->GetCreatureTemplate(entry) ? SPELL_CAST_OK : SPELL_FAILED_ERROR;
    }
    void Summon(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        if (_handled) return;
        _handled=true;
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player)) return;
        Position pos=player->GetPosition();
        player->MovePositionToFirstCollision(pos,1.5f,0.0f);
        // Only replace the old ward after the new summon succeeds.
        uint32 entry=GetSpellInfo()->Id==WD21A::HealingWard ? WD21A::HealingEntry : WD21A::Entry;
        TempSummon* ward=player->SummonCreature(entry,pos,TEMPSUMMON_TIMED_DESPAWN,60000);
        if (!ward)
        {
            ChatHandler(player->GetSession()).SendSysMessage("守卫召唤失败，原守卫已保留。");
            return;
        }
        WD21A::Clear(player);
        player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid=ward->GetGUID();
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd21a_serpent::CheckDoctor);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd21a_serpent::Summon,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd21a_serpent : public CreatureScript
{
public:
    npc_reborn_wd21a_serpent() : CreatureScript("npc_reborn_wd21a_serpent") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature) : ScriptedAI(creature) { }
        ObjectGuid owner;
        uint32 timer=2000;
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer() : nullptr;
            if (!IsDoctor(player)) { me->DespawnOrUnsummon(); return; }
            owner=player->GetGUID();
            me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction());me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10));
            me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
            timer=me->GetEntry()==WD21A::HealingEntry ? 2500 : 2000; // No immediate resummon burst.
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { me->DespawnOrUnsummon(); }
        bool Valid(Player* player,Unit* unit) const
        {
            return unit && unit->IsAlive() && player->IsValidAttackTarget(unit) &&
                me->InSamePhase(unit) && me->IsWithinDistInMap(unit,30.0f) &&
                me->IsWithinLOSInMap(unit) && !unit->HasBreakableByDamageCrowdControlAura();
        }
        Unit* Enemy(Player* player)
        {
            if (!player->IsInCombat()) return nullptr;
            if (Unit* target=player->GetSelectedUnit())
                if (Valid(player,target)) return target;
            std::list<Unit*> units;
            Acore::AnyUnitInObjectRangeCheck check(me,30.0f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);
            Cell::VisitObjects(me,search,30.0f);
            for (Unit* unit : units)
                if (Valid(player,unit) && player->IsInCombatWith(unit)) return unit;
            return nullptr;
        }
        bool IsHealingMember(Player* player,Unit* target) const
        {
            if (!target) return false;
            // Playerbot is a Player; use normal player party/raid membership.
            if (target->GetTypeId()==TYPEID_PLAYER)
                return target==player || player->IsInRaidWith(target);
#ifdef MOD_NPCERBOTS
            // Require actual group membership, not merely ownership/faction.
            if (target->IsNPCBot())
                return player->GetGroup() && target->ToCreature()->GetBotGroup()==player->GetGroup();
#endif
            return false;
        }
        bool CanHeal(Player* player,Unit* target) const
        {
            return IsHealingMember(player,target) && target->IsAlive() &&
                target->GetHealth()<target->GetMaxHealth() &&
                player->IsInMap(target) && me->InSamePhase(target) &&
                player->IsFriendlyTo(target) &&
                me->IsWithinDistInMap(target,30.0f) && me->IsWithinLOSInMap(target);
        }
        void HealAllies(Player* player)
        {
            std::list<Unit*> units;
            Acore::AnyUnitInObjectRangeCheck check(me,30.0f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);
            Cell::VisitObjects(me,search,30.0f);
            units.remove_if([this,player](Unit* unit) { return !CanHeal(player,unit); });
            units.sort([](Unit* a,Unit* b)
            {
                if (a->GetHealthPct()!=b->GetHealthPct()) return a->GetHealthPct()<b->GetHealthPct();
                return a->GetGUID()<b->GetGUID();
            });
            if (units.size()>8) units.resize(8);
            std::vector<ObjectGuid> recipients;
            for (Unit* unit : units) recipients.push_back(unit->GetGUID());
            // Resolve again between casts: procs may change membership or remove a unit.
            for (ObjectGuid const& guid : recipients)
                if (Unit* target=ObjectAccessor::GetUnit(*me,guid))
                    if (CanHeal(player,target))
                        me->CastSpell(target,WD21A::Heal,true,nullptr,nullptr,owner);
        }
        void UpdateAI(uint32 diff) override
        {
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
                !player->IsInMap(me) || !player->InSamePhase(me) ||
                player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid!=me->GetGUID())
            {
                me->DespawnOrUnsummon();return;
            }
            if (timer>diff) { timer-=diff;return; }
            if (me->GetEntry()==WD21A::HealingEntry)
            {
                timer=2500;
                HealAllies(player);return;
            }
            timer=2000; // One shot maximum per update, never catch-up burst.
            if (Unit* target=Enemy(player))
            {
                me->SetFacingToObject(target);
                // Keep donor base/per-level damage in DBC, evaluated once by core.
                // Credit the owner as upstream does; do not add a second SP formula.
                me->CastSpell(target,WD21A::Attack,true,nullptr,nullptr,owner);
            }
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};
class player_reborn_wd21a_lifecycle : public PlayerScript
{
public:
    player_reborn_wd21a_lifecycle() : PlayerScript("player_reborn_wd21a_lifecycle") { }
    void OnPlayerLogout(Player* player) override { if (IsDoctor(player)) WD21A::Clear(player); }
    void OnPlayerMapChanged(Player* player) override
    {
        // Old-map AI self-cleans on owner disappearance. Clear the handle so a
        // fast return to the same map cannot revive the previous ward's logic.
        if (IsDoctor(player)) WD21A::Clear(player);
    }
};

// WD22A uses the same base-Ward slot and lifecycle as the accepted Serpent Ward.
class npc_reborn_wd22a_healing : public CreatureScript
{
public:
    npc_reborn_wd22a_healing() : CreatureScript("npc_reborn_wd22a_healing") { }
    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_reborn_wd21a_serpent::AI(creature);
    }
};
class spell_reborn_wd22a_heal : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd22a_heal);
    void Scale(SpellEffIndex effIndex)
    {
        Unit* original=GetOriginalCaster();
        Player* player=original ? original->ToPlayer() : nullptr;
        Creature* ward=GetCaster()->ToCreature();
        if (!IsDoctor(player) || !ward || ward->GetEntry()!=WD21A::HealingEntry ||
            ward->GetOwnerGUID()!=player->GetGUID())
        {
            PreventHitDefaultEffect(effIndex);return;
        }
        // Official formula: base + level growth + 18.5% healing power + 8% RAP.
        // Zero native coefficients in the matching SQL prevent double scaling.
        float power=float(std::max(0,player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)));
        float rap=std::max(0.0f,player->GetTotalAttackPowerValue(RANGED_ATTACK));
        SetEffectValue(int32(float(GetEffectValue())+power*0.185f+rap*0.08f));
    }
    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd22a_heal::Scale,EFFECT_0,SPELL_EFFECT_HEAL);
    }
};

// WD28A: native EffectDispel keeps resistance, dispel callbacks and bot Unit support.
class spell_reborn_wd28a_hexbreak : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd28a_hexbreak);
    SpellCastResult CheckDoctor()
    {
        Player* player = GetCaster()->ToPlayer();
        return IsDoctor(player) && GetSpellInfo()->Id == 9003240 &&
            player->HasSpell(9003240) && player->GetLevel() >= 16
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd28a_hexbreak::CheckDoctor);
    }
};

// WD29A: native Aura41 purges pre-existing effects and manages immunity lifetime.
class spell_reborn_wd29a_allcure : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd29a_allcure);
    SpellCastResult CheckDoctor()
    {
        Player* player = GetCaster()->ToPlayer();
        return IsDoctor(player) && GetSpellInfo()->Id == 9003250 &&
            player->HasSpell(9003250) && player->GetLevel() >= 28
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd29a_allcure::CheckDoctor);
    }
};

// WD30A: native resurrection request; NPCBot receives its existing AI SpellHit path.
class spell_reborn_wd30a_reclaim : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd30a_reclaim);
    SpellCastResult CheckDoctor()
    {
        Player* player = GetCaster()->ToPlayer();
        return IsDoctor(player) && GetSpellInfo()->Id >= 9003260 && GetSpellInfo()->Id <= 9003267 &&
            player->HasSpell(GetSpellInfo()->Id) && player->GetLevel() >= GetSpellInfo()->SpellLevel
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd30a_reclaim::CheckDoctor);
    }
};

// WD31A: native self aura owns haste and shadow reduction apply/remove lifecycle.
class spell_reborn_wd31a_avatar : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd31a_avatar);
    SpellCastResult CheckDoctor()
    {
        Player* player = GetCaster()->ToPlayer();
        return IsDoctor(player) && GetSpellInfo()->Id == 9003270 &&
            player->HasSpell(GetSpellInfo()->Id) && player->GetLevel() >= GetSpellInfo()->SpellLevel
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd31a_avatar::CheckDoctor);
    }
};

void AddRebornWitchDoctorScripts()
{
    RegisterSpellScript(spell_reborn_wd31a_avatar);
    RegisterSpellScript(spell_reborn_wd30a_reclaim);
    RegisterSpellScript(spell_reborn_wd29a_allcure);
    RegisterSpellScript(spell_reborn_wd28a_hexbreak);
    new npc_reborn_wd22a_healing();
    RegisterSpellScript(spell_reborn_wd22a_heal);
    RegisterSpellScript(spell_reborn_wd21a_serpent);
    new npc_reborn_wd21a_serpent();
    new player_reborn_wd21a_lifecycle();
    RegisterSpellScript(spell_reborn_wd20a_support);
    RegisterSpellScript(aura_reborn_wd20a_support);
    RegisterSpellScript(spell_reborn_wd3_birth);
    RegisterSpellScript(spell_reborn_wd9a_bad_juju);
    RegisterSpellScript(spell_reborn_wd10a_hex);
    RegisterSpellScript(aura_reborn_wd10a_hex);
    new reborn_wd3_player();
    new npc_reborn_wd12_trainer();
}
