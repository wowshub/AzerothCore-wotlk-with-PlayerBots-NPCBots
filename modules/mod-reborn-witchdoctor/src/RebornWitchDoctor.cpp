// WD3: isolated level-one Witch Doctor mechanics adapted from local CoA.
// CoA AscensionWitchDoctorAbilities.cpp: previousBrew, effective healing / 2.
#include "ScriptMgr.h"
#include "Log.h" // WD101 clone initialization diagnostic
#include "WorldPacket.h"
#include "ScriptDefines/AllSpellScript.h"
#include "GameObject.h"
#include "ScriptDefines/GlobalScript.h"
#include "RebornWitchDoctorRanks.h"
#include "WitchDoctorTalentPolicy.h"
#include <unordered_set>
#include <vector>
#include <utility>
#include "SpellScript.h"
#include "Spell.h"
#include "RebornWitchDoctorBeam.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "RebornWitchDoctorSpiritWalker.h"
#include "ScriptDefines/UnitScript.h"
#include <limits>
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
#include "CommandScript.h"
#include "Group.h"
#include "GameTime.h"
#include <chrono>
#include <sstream>
#include "WorldSession.h"
#include "ObjectMgr.h"
#include "Trainer.h"
#include <algorithm>

namespace WD5A { uint32 RitualHexingRank(Player* player); bool CanUseHexTalent(Player* player,uint32 spell); bool CanUseHollow(Player* player); bool CanCastBadJuju(Player* player); void TrainerOptions(Player* player); void TrainerPurchase(Player* player); }

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
        if ((player->GetLevel()>=rank.level || (WD67::Managed(rank.spell) && WD67::Enrollment(player)==1)) && player->HasSpell(rank.spell)) return rank.spell;
    }
    return 0;
}
// WD52A: native spellbook categories, independent of talent specialization.
constexpr uint16 WitchDoctorBookSkills[] = {9004, 9005, 9006};
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
        if (WD67::Managed(family.ranks[0].spell) && WD67::Enrollment(player)!=0) continue;
        if (family.ranks[0].spell==9003103) continue; // WD48B: talent-owned, synchronized by WD5A after profile load.
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
        if (buttons[button] && buttons[button]->ranks[0].spell!=9003103)
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
// WD48B: preserve the original talent identity and paid ranks, across all profiles.
void SyncBadJuju(Player* player)
{
    if (!IsDoctor(player)) return;
    for (Rank const& rank:BadJujuRanks) if (!sSpellMgr->GetSpellInfo(rank.spell)) return;
    QueryResult ledger=CharacterDatabase.Query(
        "SELECT spell FROM reborn_wd12_training WHERE guid={} UNION ALL SELECT 0",
        player->GetGUID().GetCounter());
    if (!ledger) return; // Query failure must not erase skills/actions.
    int acquired=0;
    do {
        uint32 bought=ledger->Fetch()[0].Get<uint32>();
        for (std::size_t i=0;i<sizeof(BadJujuRanks)/sizeof(Rank);++i)
            if (bought==BadJujuRanks[i].spell) acquired=std::max(acquired,int(i));
    } while (ledger->NextRow());
    bool buttons[MAX_ACTION_BUTTONS]={};
    for (uint8 b=0;b<MAX_ACTION_BUTTONS;++b)
        if (ActionButton const* a=player->GetActionButton(b))
            buttons[b]=a->GetType()==ACTION_BUTTON_SPELL && IsBadJuju(a->GetAction());
    bool enabled=WD5A::CanCastBadJuju(player);
    // WD79A: modern TE ownership unlocks free spell ranks; legacy paid ledger remains separate.
    if(WD67::Enrollment(player)==1) acquired=int(sizeof(BadJujuRanks)/sizeof(Rank))-1;
    for (std::size_t i=sizeof(BadJujuRanks)/sizeof(Rank);i>0;--i)
    {
        Rank const& rank=BadJujuRanks[i-1];
        if ((!enabled || player->GetLevel()<rank.level) && player->HasSpell(rank.spell))
            player->removeSpell(rank.spell,3,false);
    }
    if (player->HasSpell(9003490)) player->removeSpell(9003490,3,false);
    if (enabled) for (int i=0;i<=acquired;++i)
        if (player->GetLevel()>=BadJujuRanks[i].level && !player->HasSpell(BadJujuRanks[i].spell))
            player->learnSpell(BadJujuRanks[i].spell);
    uint32 best=enabled?BestKnownRank(player,*FindFamily(9003103)):0;
    bool changed=false;
    for (uint8 b=0;b<MAX_ACTION_BUTTONS;++b) if (buttons[b])
    {
        ActionButton const* a=player->GetActionButton(b);
        if (a && a->GetAction()==best) continue;
        player->removeActionButton(b);
        if (best) player->addActionButton(b,best,ACTION_BUTTON_SPELL);
        changed=true;
    }
    if (changed) player->SendActionButtons(1);
}
uint32 ResolveAction(Player* player, uint32 spell)
{
    Family const* family=FindFamily(spell);
    return IsDoctor(player) && family ? BestKnownRank(player,*family) : spell;
}
}

// WD84A: use the current official donor's SP-only scaling and three-second cooldown.
namespace WD84A
{
constexpr uint32 Overflowing=9003720, Unleashed=9003721;
float PowerScale(Player* p) { return IsDoctor(p) && p->HasAura(Overflowing) ? 1.20f : 1.0f; }
}
// WD85A: stored Threads power is released only by the original caster.
namespace WD85A { constexpr uint32 Strings=9003730, Spirits=9003731, StringsTick=9003732; }
#include "RebornWitchDoctorSpiritTalents.inc"
#include "RebornWitchDoctorAdvancedTalents.inc"

// WD86A: exact private Puppet IDs; both timings snapshot the caster's current Spirits.
namespace WD86A
{
constexpr uint32 Mind=9003740, Blessing=9003741, Spirit=9003574;
bool Owns(Player* p,uint32 spell)
{
    // A raid recipient has the damage aura, but must not inherit the owner's talent.
    return IsDoctor(p) && p->HasSpell(spell) && p->HasAura(spell);
}
uint32 MindPercent(Player* p)
{
    if (!Owns(p,Mind)) return 100;
    Aura* spirit=p->GetAura(Spirit,p->GetGUID());
    return 100+10*(spirit ? std::min<uint32>(5,spirit->GetStackAmount()) : 0);
}
int32 Interval(Player* p,int32 amplitude)
{
    int64 value=int64(amplitude)*100/MindPercent(p);
    if (Owns(p,Blessing)) value=value*80/100;
    return int32(std::max<int64>(1,value));
}
int32 Duration(Player* p,int32 duration)
{
    int64 value=int64(duration)*MindPercent(p)/100;
    if (Owns(p,Blessing)) value=value*80/100;
    return int32(std::min<int64>(2147483647,value));
}
}
// WD68A: owned Mimic slot and Voodoo entry effects. No legacy character conversion.
namespace WD68A
{
constexpr uint32 Puppeteer=9003670, Threads=9003671, Burst=9003672, Mimic=9003673;
constexpr uint32 PuppetFirst=9003680, PuppetLast=9003689, PuppetHit=9003695, PuppetVisual=9003696;
constexpr uint32 MimicEntry=900213;
struct State : DataMap::Base { ObjectGuid mimic, extra; std::unordered_set<ObjectGuid> marked; };
char const* const Key="RebornWD68A";
Player* Caster(Unit* unit)
{
    if (!unit) return nullptr;
    if (Player* p=unit->ToPlayer()) return IsDoctor(p)?p:nullptr;
    Creature* c=unit->ToCreature();
    if (!c || c->GetEntry()!=MimicEntry || !c->IsAlive()) return nullptr;
    Player* p=ObjectAccessor::GetPlayer(*c,c->GetOwnerGUID());
    return IsDoctor(p) && p->IsAlive() && p->HasSpell(Mimic) &&
        (p->CustomData.GetDefault<State>(Key)->mimic==c->GetGUID() ||
         (p->HasSpell(9003840) && p->HasAura(9003840) && p->CustomData.GetDefault<State>(Key)->extra==c->GetGUID())) ? p : nullptr;
}
void Clear(Player* p)
{
    State* s=p->CustomData.GetDefault<State>(Key);
    if (Creature* c=ObjectAccessor::GetCreature(*p,s->mimic))
        if(c->GetEntry()==MimicEntry && c->GetOwnerGUID()==p->GetGUID()) c->DespawnOrUnsummon();
    if (Creature* c=ObjectAccessor::GetCreature(*p,s->extra))
        if(c->GetEntry()==MimicEntry && c->GetOwnerGUID()==p->GetGUID()) c->DespawnOrUnsummon();
    s->extra.Clear();s->mimic.Clear();
}
void Mirror(Player* p,Unit* target,uint32 spell)
{
    if (!IsDoctor(p) || !target || !p->IsAlive() || !p->HasSpell(Mimic)) return;
    State* state=p->CustomData.GetDefault<State>(Key);
    for(ObjectGuid guid : {state->mimic,state->extra})
    {
        Creature* c=ObjectAccessor::GetCreature(*p,guid);
        if (!c || Caster(c)!=p || !c->IsInMap(target) || !c->InSamePhase(target) ||
            !c->IsWithinDistInMap(target,40.0f) || !c->IsWithinLOSInMap(target)) continue;
        if(spell==9003822) c->CastSpell(target,spell,true,nullptr,nullptr,p->GetGUID());
        else c->CastSpell(target,spell,true);
    }
}
}
#include "RebornWitchDoctorMimicStatus.inc"
class spell_reborn_wd68a_summon : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd68a_summon);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return IsDoctor(p) && p->HasSpell(GetSpellInfo()->Id) && p->GetLevel()>=GetSpellInfo()->SpellLevel
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Summon(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* p=GetCaster()->ToPlayer();if (!IsDoctor(p)) return;
        int32 duration=GetSpellInfo()->GetDuration();p->ApplySpellMod(GetSpellInfo()->Id,SPELLMOD_DURATION,duration);
        // Allocate the new group first; a partial failure preserves the previous group.
        bool const chosen=p->HasSpell(9003840) && p->HasAura(9003840);
        TempSummon* fresh[2]={nullptr,nullptr};
        uint32 count=chosen?2u:1u;
        for(uint32 i=0;i<count;++i)
        {
            Position pos=p->GetPosition();p->MovePositionToFirstCollision(pos,1.5f,i?5.48f:0.8f);
            fresh[i]=p->SummonCreature(WD68A::MimicEntry,pos,TEMPSUMMON_TIMED_DESPAWN,uint32(std::max(1,duration)));
            if(!fresh[i])
            {
                for(uint32 j=0;j<i;++j) fresh[j]->DespawnOrUnsummon();
                ChatHandler(p->GetSession()).SendSysMessage("拟态守卫召唤失败，原守卫已保留。");return;
            }
            fresh[i]->SetOwnerGUID(p->GetGUID());fresh[i]->SetCreatorGUID(p->GetGUID());
            fresh[i]->SetFaction(p->GetFaction());fresh[i]->SetLevel(p->GetLevel());
            fresh[i]->SetMaxHealth(std::max(5u,uint32(p->GetLevel())*10));fresh[i]->SetHealth(fresh[i]->GetMaxHealth());
        }
        WD68A::Clear(p);
        auto* state=p->CustomData.GetDefault<WD68A::State>(WD68A::Key);
        state->mimic=fresh[0]->GetGUID();
        if(chosen) state->extra=fresh[1]->GetGUID();
        p->CustomData.GetDefault<WD87B::Status>(WD87B::Key)->lifetime=fresh[0]->GetTimer();
        WD87B::Snapshot(p);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd68a_summon::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd68a_summon::Summon,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd68a_mimic : public CreatureScript
{
public:
    npc_reborn_wd68a_mimic():CreatureScript("npc_reborn_wd68a_mimic") {}
    struct AI : ScriptedAI
    {
        explicit AI(Creature* c):ScriptedAI(c) {me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);}
        void AttackStart(Unit*) override {}
        void UpdateAI(uint32) override
        {
            if (!WD68A::Caster(me)) me->DespawnOrUnsummon();
        }
    };
    CreatureAI* GetAI(Creature* c) const override {return new AI(c);}
};
class aura_reborn_wd68a_puppeteer : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd68a_puppeteer);
    bool Check(ProcEventInfo& event)
    {
        Player* p=GetTarget()->ToPlayer();Unit* t=event.GetActionTarget();
        SpellInfo const* info=event.GetSpellInfo();
        if (!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(WD68A::Puppeteer) || event.GetActor()!=p ||
            !t || !t->IsAlive() || !p->IsValidAttackTarget(t) || !event.GetDamageInfo() || !event.GetDamageInfo()->GetDamage()) return false;
        if (info && (info->Id==WD68A::Burst || info->Id==9003102)) return false;
        bool periodic=(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) || (info && info->Id==WD68A::PuppetHit);
        return t->HasAura(WD68A::Threads,p->GetGUID()) || (info && !periodic);
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();Player* p=GetTarget()->ToPlayer();Unit* t=event.GetActionTarget();
        Aura* a=t->GetAura(WD68A::Threads,p->GetGUID());
        if (!a) a=p->AddAura(WD68A::Threads,t);
        if (!a) return;
        if (AuraEffect* e=a->GetEffect(EFFECT_0))
            e->ChangeAmount(int32(std::min<uint64>(2147483647u,uint64(std::max(0,e->GetAmount()))+uint64(event.GetDamageInfo()->GetDamage())*15/100)));
        p->CustomData.GetDefault<WD68A::State>(WD68A::Key)->marked.insert(t->GetGUID());
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_reborn_wd68a_puppeteer::Check);
        OnProc += AuraProcFn(aura_reborn_wd68a_puppeteer::Proc);
    }
};
class aura_reborn_wd68a_threads : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd68a_threads);
    bool released=false;
    void Remove(AuraEffect const* e,AuraEffectHandleModes)
    {
        if (released) return;released=true;
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if (!IsDoctor(p)) return;
        p->CustomData.GetDefault<WD68A::State>(WD68A::Key)->marked.erase(GetTarget()->GetGUID());
        if (p->IsAlive() && p->HasAura(WD68A::Puppeteer) && GetTarget()->IsAlive() && e->GetAmount()>0)
            p->CastCustomSpell(WD68A::Burst,SPELLVALUE_BASE_POINT0,e->GetAmount(),GetTarget(),true);
    }
    void Register() override {AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd68a_threads::Remove,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);}
};
class spell_reborn_wd68a_puppet : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd68a_puppet);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return IsDoctor(p) && p->HasSpell(GetSpellInfo()->Id) && p->GetLevel()>=GetSpellInfo()->SpellLevel &&
            p->HasAura(WD68A::Puppeteer) && p->HasSpell(WD68A::Mimic) ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override {OnCheckCast += SpellCheckCastFn(spell_reborn_wd68a_puppet::Check);}
};
// WD70B: visual posture only. Does not create a channel or block movement/casting.
namespace WD70B
{
constexpr char Key[]="RebornWD70B.PuppetPose";
struct State : DataMap::Base
{
    uint64 generation=0;
    bool active=false;
    uint32 previous=0, spell=0;
    ObjectGuid target;
};
void End(Player* p,uint64 generation=0)
{
    if (!p) return;
    State* s=p->CustomData.Get<State>(Key);
    if (!s || !s->active || (generation && generation!=s->generation)) return;
    // Never overwrite an emote subsequently chosen by another system.
    if (p->GetUInt32Value(UNIT_NPC_EMOTESTATE)==EMOTE_STATE_SPELL_CHANNEL_DIRECTED)
        p->SetEmoteState(p->IsAlive()?Emote(s->previous):EMOTE_ONESHOT_NONE);
    s->active=false;s->target.Clear();s->spell=0;
}
uint64 Begin(Player* p,Unit* target,uint32 spell)
{
    if (!IsDoctor(p) || !p->IsAlive() || !target) return 0;
    State* s=p->CustomData.GetDefault<State>(Key);
    if (!s->active || p->GetUInt32Value(UNIT_NPC_EMOTESTATE)!=EMOTE_STATE_SPELL_CHANNEL_DIRECTED)
        s->previous=p->GetUInt32Value(UNIT_NPC_EMOTESTATE);
    if (++s->generation==0) ++s->generation;
    s->active=true;s->target=target->GetGUID();s->spell=spell;
    p->SetEmoteState(EMOTE_STATE_SPELL_CHANNEL_DIRECTED);
    return s->generation;
}
class Lifecycle : public PlayerScript
{
public:
    Lifecycle() : PlayerScript("reborn_wd70b_puppet_pose") { }
    void OnPlayerLogout(Player* p) override { End(p); }
    void OnPlayerMapChanged(Player* p) override { End(p); }
    void OnPlayerJustDied(Player* p) override { End(p); }
    void OnPlayerUpdate(Player* p,uint32) override
    {
        State* s=p->CustomData.Get<State>(Key);
        if (!s || !s->active) return;
        Unit* target=ObjectAccessor::GetUnit(*p,s->target);
        if (!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(s->spell) || !target ||
            !target->IsAlive() || !p->IsInMap(target) || !p->InSamePhase(target) ||
            !target->HasAura(s->spell,p->GetGUID())) End(p);
    }
};
}
class aura_reborn_wd68a_puppet : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd68a_puppet);
    uint64 poseGeneration=0;
    void PoseStart(AuraEffect const*,AuraEffectHandleModes)
    {
        if (poseGeneration) return;
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        poseGeneration=WD70B::Begin(p,GetTarget(),GetId());
    }
    void PoseEnd(AuraEffect const*,AuraEffectHandleModes)
    {
        if (!poseGeneration) return;
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        WD70B::End(p,poseGeneration);poseGeneration=0;
    }
    void Amount(AuraEffect const*,int32& amount,bool& recalculate)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if (!IsDoctor(p)) return;
        amount+=int32(std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW))*0.22f);
        amount=int32(p->SpellDamageBonusDone(GetUnitOwner(),GetSpellInfo(),uint32(std::max(0,amount)),SPELL_DIRECT_DAMAGE,EFFECT_0));
        recalculate=false;
    }
    void Periodic(AuraEffect const*,bool& periodic,int32& amplitude)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if (IsDoctor(p) && periodic && amplitude>0) amplitude=WD86A::Interval(p,amplitude);
    }
    void Tick(AuraEffect const* e)
    {
        PreventDefaultAction();Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if (!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(GetId()) || !GetTarget()->IsAlive()) return;
        p->CastCustomSpell(WD68A::PuppetHit,SPELLVALUE_BASE_POINT0,e->GetAmount(),GetTarget(),true,nullptr,e);
        p->CastSpell(GetTarget(),WD68A::PuppetVisual,true);
        p->CastSpell(p,9003574,true);
    }
    void Register() override
    {
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_reborn_wd68a_puppet::Periodic,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd68a_puppet::Amount,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd68a_puppet::PoseStart,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd68a_puppet::PoseEnd,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_wd68a_puppet::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY);
    }
};
namespace WD5A
{
void WD111ClearExtra(Player* p)
{
    auto* state=p->CustomData.GetDefault<WD68A::State>(WD68A::Key);
    if(Creature* c=ObjectAccessor::GetCreature(*p,state->extra))
        if(c->GetEntry()==WD68A::MimicEntry && c->GetOwnerGUID()==p->GetGUID()) c->DespawnOrUnsummon();
    state->extra.Clear();
}
void WD68Clear(Player* p,bool mimic,bool puppeteer)
{
    if (mimic) WD68A::Clear(p);
    if (puppeteer)
    {
        auto* s=p->CustomData.GetDefault<WD68A::State>(WD68A::Key);
        auto marked=s->marked;s->marked.clear();
        for (auto guid:marked) if(Unit* t=ObjectAccessor::GetUnit(*p,guid)) t->RemoveAurasDueToSpell(WD68A::Threads,p->GetGUID());
    }
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
        Player* player=WD68A::Caster(GetCaster());
        uint32 id=GetSpellInfo()->Id;
        return IsDoctor(player) && (WD19A::IsWrath(id) || WD19A::IsBrew(id)) &&
            player->GetLevel()>=GetSpellInfo()->SpellLevel && player->HasSpell(id)
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void AddCoACoefficient(SpellEffIndex)
    {
        Player* player = WD68A::Caster(GetCaster());
        if (!IsDoctor(player))
            return;
        bool healing = WD19A::IsBrew(GetSpellInfo()->Id);
        int32 power = healing ? player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)
                              : player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE);
        float coefficient = healing ? (player->HasAura(9003911) ? 0.84f*1.15f : 0.84f) : 0.625f*WD84A::PowerScale(player);
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
    void MirrorCast()
    {
        Player* p=GetCaster()->ToPlayer();
        if (p && !GetSpell()->IsTriggered() && GetHitUnit()) WD68A::Mirror(p,GetHitUnit(),GetSpellInfo()->Id);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd3_birth::CheckDoctor);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd3_birth::AddCoACoefficient, EFFECT_0, SPELL_EFFECT_ANY);
        AfterHit += SpellHitFn(spell_reborn_wd3_birth::AfterBrew);
        AfterHit += SpellHitFn(spell_reborn_wd3_birth::MirrorCast);
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
        // WD52A: reconcile both existing and new characters; never unlearn spells.
        // SkillLineAbility acquireMethod stays zero: these pages grant no abilities.
        for (uint16 skill : WitchDoctorBookSkills)
            if (!player->HasSkill(skill))
                player->SetSkill(skill, 0, 1, 1);
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
        Player* p=WD68A::Caster(GetCaster());
        if (!GetCaster()->IsPlayer() && (!p || !p->HasAura(WD84A::Unleashed) || !GetSpell()->IsTriggered())) return SPELL_FAILED_CASTER_AURASTATE;
        return WD5A::CanCastBadJuju(p) && p->HasSpell(9003103) ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void AddCoefficient(SpellEffIndex)
    {
        Player* p=WD68A::Caster(GetCaster());
        if (!IsDoctor(p)) return;
        int32 power=std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW));
        SetEffectValue(int32(float(GetEffectValue())+power*WD84A::PowerScale(p)+std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.30f));
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
    // One successful parent cast, including a miss, grants one reduction.
    // Triggered casts and the owned Mimic copy cannot recursively reduce cooldowns.
    void UnleashCooldown()
    {
        Player* p=GetCaster()->ToPlayer();
        if (!IsDoctor(p) || !p->IsAlive() || GetSpell()->IsTriggered() || !p->HasAura(WD84A::Unleashed)) return;
        for (auto const& rank:WD19A::PuppetRanks)
        {
            uint32 remaining=p->GetSpellCooldownDelay(rank.spell);
            if (remaining) p->ModifySpellCooldown(rank.spell,-int32(std::min(remaining,3000u)));
        }
    }
    void UnleashMirror()
    {
        Player* p=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        if (IsDoctor(p) && p->HasAura(WD84A::Unleashed) && !GetSpell()->IsTriggered() && target && target->IsAlive() && p->IsValidAttackTarget(target))
            WD68A::Mirror(p,target,GetSpellInfo()->Id);
    }
    void ApplyStrings()
    {
        Player* p=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        if (!IsDoctor(p) || !p->IsAlive() || !p->HasAura(WD85A::Strings) ||
            !target || !target->IsAlive() || GetHitDamage()<=0 ||
            !target->HasAura(WD68A::Threads,p->GetGUID())) return;
        int32 perTick=int32(std::min<uint64>(2147483647u,uint64(GetHitDamage())*30/100));
        if (perTick>0) p->CastCustomSpell(WD85A::StringsTick,SPELLVALUE_BASE_POINT0,perTick,target,true);
    }
    void Register() override
    {
        AfterHit += SpellHitFn(spell_reborn_wd9a_bad_juju::ApplyMark);
        AfterHit += SpellHitFn(spell_reborn_wd9a_bad_juju::ApplyStrings);
        AfterHit += SpellHitFn(spell_reborn_wd9a_bad_juju::UnleashMirror);
        AfterCast += SpellCastFn(spell_reborn_wd9a_bad_juju::UnleashCooldown);
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
    // WD37A: snapshot periodic crit on application AND recast/refresh.
    // The core still rolls each tick and calculates its normal critical damage.
    void SnapshotPeriodicCrit(AuraEffect const* effect, AuraEffectHandleModes /*mode*/)
    {
        Player* player=GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!IsDoctor(player) || !GetTarget()) return;
        bool isHex=false;
        for (WD19A::Rank const& rank : WD19A::HexRanks)
            if (rank.spell==GetSpellInfo()->Id) { isHex=true;break; }
        if (!isHex || effect->GetEffIndex()!=EFFECT_0 ||
            effect->GetAuraType()!=SPELL_AURA_PERIODIC_DAMAGE) return;
        if (AuraEffect* periodic=GetEffect(EFFECT_0))
        {
            SpellInfo const* info=GetSpellInfo();
            float chance=player->SpellDoneCritChance(nullptr,info,info->GetSchoolMask(),BASE_ATTACK,true);
            chance=GetTarget()->SpellTakenCritChance(player,info,info->GetSchoolMask(),chance,BASE_ATTACK,true);
            periodic->SetCritChance(std::max(0.0f,std::min(100.0f,chance)));
        }
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd10a_hex::SnapshotPeriodicCrit, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd10a_hex::PeriodicCoefficient, EFFECT_0, SPELL_AURA_PERIODIC_DAMAGE);
    }
};

// WD85A: Hexfire snaps only this Witch Doctor's stored Threads after a real hit.
class aura_reborn_wd85a_strings_tick : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd85a_strings_tick);
    void ExactSnapshot(AuraEffect const* effect,int32& amount,bool& recalculate)
    {
        // The parent hit already included spell power and target mitigation.
        amount=std::max(0,effect->GetOldAmount());
        recalculate=false;
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd85a_strings_tick::ExactSnapshot,EFFECT_0,SPELL_AURA_PERIODIC_DAMAGE);
    }
};
class spell_reborn_wd85a_hexfire : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd85a_hexfire);
    void Release()
    {
        Player* p=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        if (!IsDoctor(p) || !p->IsAlive() || !p->HasAura(WD85A::Spirits) ||
            !target || GetHitDamage()<=0) return;
        Aura* threads=target->GetAura(WD68A::Threads,p->GetGUID());
        if (!threads) return;
        int32 damage=0;
        if (AuraEffect* effect=threads->GetEffect(EFFECT_0))
        {
            damage=std::max(0,effect->GetAmount());
            effect->ChangeAmount(0); // prevents the removal callback from bursting twice
        }
        threads->Remove();
        if (damage>0 && target->IsAlive())
            p->CastCustomSpell(WD68A::Burst,SPELLVALUE_BASE_POINT0,damage,target,true);
        p->CastSpell(p,9003574,true);
    }
    void Register() override { AfterHit += SpellHitFn(spell_reborn_wd85a_hexfire::Release); }
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
    if(spell==WD88A::Jinx) return 2;
    WD19A::Family const* family=WD19A::FindFamily(spell);
    if (!family) return 0;
    if (family->ranks[0].spell==9003140 || family->ranks[0].spell==9003180 || family->ranks[0].spell==9003190 || family->ranks[0].spell==9003280 || family->ranks[0].spell==9003290 || family->ranks[0].spell==9003300) return 1; // Spirit/Power/Resourceful/Greater Resourceful/Greater Spirit/Greater Power Wuju
    if (family->ranks[0].spell==9003150 || family->ranks[0].spell==9003200 || family->ranks[0].spell==9003210 || family->ranks[0].spell==9003220) return 2; // Lethargy/Hireek/Mana/Shrinking Jinx
    return 0;
}
}
// WD34A: creation is Witch Doctor-only; using/trading the resulting items is not.
class spell_reborn_wd34a_provisions : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd34a_provisions);
    SpellCastResult CheckDoctor()
    {
        Player* player = GetCaster()->ToPlayer();
        uint32 id = GetSpellInfo()->Id;
        bool provision = (id >= 9003310 && id <= 9003316) || (id >= 9003320 && id <= 9003326) || (id >= 9003350 && id <= 9003354);
        return provision && IsDoctor(player) && player->HasSpell(id) &&
            player->GetLevel() >= GetSpellInfo()->SpellLevel ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd34a_provisions::CheckDoctor);
    }
};
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


// WD36B: opt-in bounded diagnostics. No eligibility, cooldown or power changes.
namespace WD36B
{
struct DebugState : DataMap::Base { uint64 until=0; uint32 lines=0; };
uint64 Now() { return uint64(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch()).count()); }
bool Active(Player* player)
{
    auto* state=player->CustomData.GetDefault<DebugState>("RebornWD36B.Debug");
    return state->until>Now() && state->lines<80;
}
void Print(Player* player,std::string const& text)
{
    if (!Active(player)) return;
    ++player->CustomData.GetDefault<DebugState>("RebornWD36B.Debug")->lines;
    ChatHandler(player->GetSession()).SendSysMessage(text.c_str());
}
void Inspect(Player* player,Creature* summon,Unit* unit,char const* kind,bool found)
{
    if (!Active(player) || !unit) return;
    std::ostringstream o;
    o<<"[WD36B "<<kind<<"] "<<unit->GetName()<<" Lv"<<uint32(unit->GetLevel())
     <<" found="<<found<<" hp="<<unit->GetHealth()<<"/"<<unit->GetMaxHealth()
     <<" mana="<<unit->GetPower(POWER_MANA)<<"/"<<unit->GetMaxPower(POWER_MANA)
     <<" powerType="<<uint32(unit->getPowerType())<<" alive="<<unit->IsAlive()
     <<" map="<<player->IsInMap(unit)<<" phase="<<summon->InSamePhase(unit)
     <<" raid="<<player->IsInRaidWith(unit)<<" friendly="<<player->IsFriendlyTo(unit)
     <<" range="<<summon->IsWithinDistInMap(unit,30.0f)<<" los="<<summon->IsWithinLOSInMap(unit)
     <<" assist="<<summon->IsValidAssistTarget(unit)<<" npcImmune="<<unit->IsImmuneToNPC();
    Print(player,o.str());
}
void Scan(Player* player,Creature* summon,std::list<Unit*> const& units,char const* kind)
{
    if (!Active(player)) return;
    auto report=[&](Unit* unit) { Inspect(player,summon,unit,kind,std::find(units.begin(),units.end(),unit)!=units.end()); };
    report(player);
    if (Group* group=player->GetGroup())
        for (GroupReference* ref=group->GetFirstMember();ref;ref=ref->next())
            if (Player* member=ref->GetSource())
                if (member!=player) report(member);
#ifdef MOD_NPCERBOTS
    for (Unit* unit : units)
        if (unit->IsNPCBot()) report(unit);
#endif
}
void Cast(Player* player,Creature* summon,Unit* target,uint32 spell,ObjectGuid owner)
{
    uint32 mana=target->GetPower(POWER_MANA),health=target->GetHealth();
    SpellCastResult result=summon->CastSpell(target,spell,true,nullptr,nullptr,owner);
    if (!Active(player)) return;
    std::ostringstream o;
    o<<"[WD36B CAST] "<<target->GetName()<<" spell="<<spell<<" result="<<uint32(result)
     <<" OK="<<uint32(SPELL_CAST_OK)<<" mana="<<mana<<"->"<<target->GetPower(POWER_MANA)
     <<" hp="<<health<<"->"<<target->GetHealth();
    Print(player,o.str());
}
class Commands : public CommandScript
{
public:
    Commands():CommandScript("reborn_wd36b_diagnostics") { }
    static bool Toggle(ChatHandler* handler)
    {
        Player* player=handler->GetSession()->GetPlayer();
        auto* state=player->CustomData.GetDefault<DebugState>("RebornWD36B.Debug");
        if (Active(player)) { state->until=0;handler->SendSysMessage("WD36B诊断已关闭。");return true; }
        state->until=Now()+30000;state->lines=0;
        handler->SendSysMessage("WD36B诊断开启30秒，最多80行。现在施放灵魂神像；再次输入 .wdwardcheck 可关闭。无CAST行时请保留SCAN行；完全无输出也请反馈。");
        return true;
    }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;
        static ChatCommandTable commands={{"wdwardcheck",Toggle,SEC_PLAYER,Console::No}};
        return commands;
    }
};
}

// WD53A: selected families and actual paid costs belong to this player only.
namespace WD53A
{
constexpr uint32 Rite=9003540, Recall=9003541;
constexpr char Key[]="RebornWD53A.Summons";
struct Paid { ObjectGuid guid; uint32 mana=0; };
struct State : DataMap::Base { uint32 selected[3]={}; Paid paid[3]; float placementAngle=0.0f; };
float Angle(Player* player) { return player->CustomData.GetDefault<State>(Key)->placementAngle; }
int Slot(uint32 id)
{
    switch(id)
    {
        case 9003160: case 9003170: case 9003450: case 9003400: return 0;
        case 9003953: case 9003370: case 9003440: case 9003432: case 9003382: case 9003380: case 9003390: return 1;
        case 9003410: case 9003420: case 9003422: case 9003430: return 2;
        default: return -1;
    }
}
void Track(Player* player, Spell* spell, ObjectGuid guid)
{
    int slot=Slot(spell->GetSpellInfo()->Id);
    if (slot<0) return;
    auto& paid=player->CustomData.GetDefault<State>(Key)->paid[slot];
    player->CustomData.GetDefault<State>(Key)->selected[slot]=spell->GetSpellInfo()->Id;
    // Only successful, owned Idol placement reaches Track; failures give no buff.
    if (slot==1 && IsDoctor(player) && player->HasSpell(9003660) && player->HasAura(9003660))
        player->CastSpell(player,9003663,true);
    paid.guid=guid;
    paid.mana=spell->HasTriggeredCastFlag(TRIGGERED_IGNORE_POWER_AND_REAGENT_COST) ||
        player->GetCommandStatus(CHEAT_POWER) ? 0u : uint32(std::max(0,spell->GetPowerCost()));
}
}

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
bool IsWardEntry(uint32 entry) { return entry==Entry || entry==HealingEntry || entry==900196 || entry==900204; }
constexpr char Key[] = "RebornWD21A.Ward";
struct State : DataMap::Base { ObjectGuid guid; };
void Clear(Player* player)
{
    State* state=player->CustomData.GetDefault<State>(Key);
    if (!state->guid.IsEmpty() && player->IsInWorld())
        if (Creature* old=ObjectAccessor::GetCreature(*player,state->guid))
            if (IsWardEntry(old->GetEntry()) && old->GetOwnerGUID()==player->GetGUID())
            {
                if (old->GetEntry()==900196) old->AI()->DoAction(40);
                old->DespawnOrUnsummon();
            }
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
        player->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(player));
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
        WD53A::Track(player,GetSpell(),ward->GetGUID());
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
        float timer=2000.0f; // WD51A: preserve fractional attack progress under haste.
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
            WD36B::Scan(player,me,units,"HEAL");
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
                        WD36B::Cast(player,me,target,WD21A::Heal,owner);
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
            float step=float(diff);
            if (me->GetEntry()==WD21A::Entry && player->HasSpell(9003532) && player->HasAura(9003532))
                if (AuraEffect* haste=me->GetAuraEffect(9003533,EFFECT_0,owner))
                    step*=1.0f+float(std::max(0,std::min(9,haste->GetAmount())))/100.0f;
            if (timer>step) { timer-=step;return; }
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
    void ExtraAlly()
    {
        Player* player=GetCaster()->ToPlayer();
        Unit* center=GetHitUnit();
        if(!IsDoctor(player) || !player->HasAura(9003911) || !center || GetSpell()->IsTriggered()) return;
        std::list<Unit*> nearby;
        Acore::AnyUnitInObjectRangeCheck check(center,8.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,nearby,check);
        Cell::VisitObjects(center,search,8.0f);
        nearby.remove_if([player,center](Unit* unit)
        {
            if(unit==center || !unit->IsAlive() || !player->IsValidAssistTarget(unit) ||
                !player->IsInMap(unit) || !player->InSamePhase(unit) || !center->IsWithinLOSInMap(unit)) return true;
            for(auto const& aura:unit->GetAppliedAuras())
                if(aura.second && aura.second->GetBase()->GetSpellInfo()->Dispel==DISPEL_CURSE)
                    return false;
            return true;
        });
        nearby.sort([center](Unit* a,Unit* b)
        {
            float da=center->GetDistance(a),db=center->GetDistance(b);
            return da==db ? a->GetGUID()<b->GetGUID() : da<db;
        });
        if(!nearby.empty()) player->CastSpell(nearby.front(),GetSpellInfo()->Id,true);
    }
    void ShorterGlobalCooldown()
    {
        Player* player=GetCaster()->ToPlayer();
        if(!IsDoctor(player) || !player->HasAura(9003911) || GetSpell()->IsTriggered()) return;
        uint32 remaining=player->GetGlobalCooldownMgr().GetGlobalCooldown(GetSpellInfo());
        if(remaining>1000) player->GetGlobalCooldownMgr().AddGlobalCooldown(GetSpellInfo(),1000);
    }
    void Register() override
    {
        AfterHit += SpellHitFn(spell_reborn_wd28a_hexbreak::ExtraAlly);
        AfterCast += SpellCastFn(spell_reborn_wd28a_hexbreak::ShorterGlobalCooldown);
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
    // WD44A: only characters who learned the group version share its cooldown.
    void SharedCooldown()
    {
        if(Player* player=GetCaster()->ToPlayer())
            if(player->HasSpell(9003442))
                player->AddSpellCooldown(9003442,0,GameTime::GetGameTime().count()+GetSpellInfo()->RecoveryTime/1000,true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd29a_allcure::CheckDoctor);
        AfterCast += SpellCastFn(spell_reborn_wd29a_allcure::SharedCooldown);
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


// WD36A: independent Idol slot; never replaces the primary pet or Ward slot.
namespace WD36A
{
constexpr uint32 Summon=9003370, Mana=9003371, Entry=900192;
constexpr char Key[]="RebornWD36A.Idol";
struct State : DataMap::Base { ObjectGuid guid; };
void Clear(Player* player)
{
    State* state=player->CustomData.GetDefault<State>(Key);
    if (!state->guid.IsEmpty() && player->IsInWorld())
        if (Creature* old=ObjectAccessor::GetCreature(*player,state->guid))
            if ((old->GetEntry()==Entry || old->GetEntry()==900193 || old->GetEntry()==900194 || old->GetEntry()==900195 || old->GetEntry()==900202 || old->GetEntry()==900203 || old->GetEntry()==900232) && old->GetOwnerGUID()==player->GetGUID())
            {
                if (old->GetEntry()!=Entry && old->AI()) old->AI()->DoAction(38);
                old->DespawnOrUnsummon();
            }
    state->guid.Clear();
}
bool Eligible(Player* player, Creature* idol, Unit* target)
{
    if (!target || !target->IsAlive() || target->getPowerType()!=POWER_MANA ||
        !target->GetMaxPower(POWER_MANA) || !player->IsInMap(target) ||
        !idol->InSamePhase(target) || !player->IsFriendlyTo(target) ||
        !idol->IsWithinDistInMap(target,30.0f) || !idol->IsWithinLOSInMap(target)) return false;
    if (target->GetTypeId()==TYPEID_PLAYER)
        return target==player || player->IsInRaidWith(target);
#ifdef MOD_NPCERBOTS
    if (target->IsNPCBot())
        return player->GetGroup() && target->ToCreature()->GetBotGroup()==player->GetGroup();
#endif
    return false;
}
}
class spell_reborn_wd36a_idol : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd36a_idol);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({WD36A::Summon,WD36A::Mana}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !player->HasSpell(WD36A::Summon) || player->GetLevel()<14)
            return SPELL_FAILED_CASTER_AURASTATE;
        return sObjectMgr->GetCreatureTemplate(WD36A::Entry) ? SPELL_CAST_OK : SPELL_FAILED_ERROR;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (handled) return;
        handled=true;
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player)) return;
        Position pos=player->GetPosition();
        player->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(player));
        // AI owns the precise 15s deadline, including its final pulse; 16s is a safety expiry.
        TempSummon* idol=player->SummonCreature(WD36A::Entry,pos,TEMPSUMMON_TIMED_DESPAWN,16000);
        if (!idol)
        {
            ChatHandler(player->GetSession()).SendSysMessage("灵魂神像召唤失败，原神像已保留。");
            return;
        }
        WD36A::Clear(player);
        player->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid=idol->GetGUID();
        WD53A::Track(player,GetSpell(),idol->GetGUID());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd36a_idol::CheckDoctor);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd36a_idol::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd36a_idol : public CreatureScript
{
public:
    npc_reborn_wd36a_idol() : CreatureScript("npc_reborn_wd36a_idol") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature) : ScriptedAI(creature) { }
        ObjectGuid owner;
        uint32 timer=3000, remaining=15000;
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer() : nullptr;
            if (!IsDoctor(player)) { me->DespawnOrUnsummon();return; }
            owner=player->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction());me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
            timer=3000;remaining=15000;
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { me->DespawnOrUnsummon(); }
        void UpdateAI(uint32 diff) override
        {
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
                !player->IsInMap(me) || !player->InSamePhase(me) ||
                !player->HasSpell(WD36A::Summon) ||
                player->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid!=me->GetGUID())
            { me->DespawnOrUnsummon();return; }
            uint32 step=std::min(diff,remaining);
            remaining-=step;
            if (timer>step) timer-=step;
            else
            {
                timer=3000; // One pulse per update; never catch-up bursts after lag.
                std::list<Unit*> units;
                Acore::AnyUnitInObjectRangeCheck check(me,30.0f);
                Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);
                Cell::VisitObjects(me,search,30.0f);
                WD36B::Scan(player,me,units,"MANA");
                std::vector<ObjectGuid> recipients;
                for (Unit* unit : units)
                    if (WD36A::Eligible(player,me,unit)) recipients.push_back(unit->GetGUID());
                for (ObjectGuid const& guid : recipients)
                    if (Unit* unit=ObjectAccessor::GetUnit(*me,guid))
                        if (WD36A::Eligible(player,me,unit))
                            WD36B::Cast(player,me,unit,WD36A::Mana,owner);
            }
            if (!remaining) me->DespawnOrUnsummon();
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};
class player_reborn_wd36a_idol_lifecycle : public PlayerScript
{
public:
    player_reborn_wd36a_idol_lifecycle() : PlayerScript("player_reborn_wd36a_idol_lifecycle") { }
    void OnPlayerLogout(Player* player) override { WD36A::Clear(player); }
    void OnPlayerMapChanged(Player* player) override { WD36A::Clear(player); }
};


// WD38A/WD39A: resistance and Serene Idols share the proven Spirit Idol slot.
namespace WD38A
{
struct Config { uint32 spell, aura, entry; uint8 level; };
constexpr Config Idols[]={{9003380,9003381,900193,56},{9003382,9003383,900194,52},{9003390,9003391,900195,60},{9003432,9003433,900202,28}};
Config const* BySpell(uint32 id) { for (auto const& c:Idols) if(c.spell==id)return &c;return nullptr; }
Config const* ByEntry(uint32 id) { for (auto const& c:Idols) if(c.entry==id)return &c;return nullptr; }
bool Eligible(Player* player, Creature* idol, Unit* target)
{
    if (!target || !target->IsAlive() || !player->IsInMap(target) || !idol->InSamePhase(target) ||
        !player->IsFriendlyTo(target) || !idol->IsWithinDistInMap(target,30.0f) || !idol->IsWithinLOSInMap(target)) return false;
    if (target->GetTypeId()==TYPEID_PLAYER) return target==player || player->IsInRaidWith(target);
#ifdef MOD_NPCERBOTS
    if (target->IsNPCBot()) return player->GetGroup() && target->ToCreature()->GetBotGroup()==player->GetGroup();
#endif
    return false;
}
}
class spell_reborn_wd38a_idol : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd38a_idol);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003380,9003381,9003382,9003383,9003390,9003391,9003432,9003433}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();auto const* cfg=WD38A::BySpell(GetSpellInfo()->Id);
        if (!cfg || !IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !player->HasSpell(cfg->spell) || player->GetLevel()<cfg->level) return SPELL_FAILED_CASTER_AURASTATE;
        return SPELL_CAST_OK;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);if (handled)return;handled=true;
        Player* player=GetCaster()->ToPlayer();auto const* cfg=WD38A::BySpell(GetSpellInfo()->Id);
        if (!cfg || !IsDoctor(player))return;
        Position pos=player->GetPosition();player->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(player));
        TempSummon* idol=player->SummonCreature(cfg->entry,pos,TEMPSUMMON_TIMED_DESPAWN,cfg->entry==900202 ? WD117::Duration(player)+1000 : 61000);
        if (!idol) { ChatHandler(player->GetSession()).SendSysMessage("神像召唤失败，原神像已保留。");return; }
        WD36A::Clear(player);
        player->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid=idol->GetGUID();
        WD53A::Track(player,GetSpell(),idol->GetGUID());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd38a_idol::CheckDoctor);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd38a_idol::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd38a_idol : public CreatureScript
{
public:
    npc_reborn_wd38a_idol():CreatureScript("npc_reborn_wd38a_idol") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature):ScriptedAI(creature) { }
        ObjectGuid owner; WD38A::Config const* cfg=nullptr;
        int32 swiftAmount=25;
        uint32 timer=1,remaining=60000;
        std::vector<ObjectGuid> affected;
        void Remove(ObjectGuid const& guid)
        {
            if (cfg) if(Unit* target=ObjectAccessor::GetUnit(*me,guid)) target->RemoveAurasDueToSpell(cfg->aura,owner);
        }
        void ClearFields() { for(auto const& guid:affected) Remove(guid);affected.clear(); }
        void DoAction(int32 action) override { if(action==38) ClearFields(); }
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer():nullptr;cfg=WD38A::ByEntry(me->GetEntry());
            if(!cfg || !IsDoctor(player)) { me->DespawnOrUnsummon();return; }
            if(cfg->entry==900202) { remaining=WD117::Duration(player);swiftAmount=WD117::SwiftAmount(player); }
            owner=player->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction());me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { ClearFields();me->DespawnOrUnsummon(); }
        void UpdateAI(uint32 diff) override
        {
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if(!cfg || !IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
                !player->IsInMap(me) || !player->InSamePhase(me) || !player->HasSpell(cfg->spell) ||
                player->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid!=me->GetGUID())
            { ClearFields();me->DespawnOrUnsummon();return; }
            if(diff>=remaining) { ClearFields();me->DespawnOrUnsummon();return; }
            remaining-=diff;
            if(timer>diff) { timer-=diff;return; }timer=1000;
            std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(me,30.0f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);Cell::VisitObjects(me,search,30.0f);
            std::vector<ObjectGuid> next;
            for(Unit* unit:units) if(WD38A::Eligible(player,me,unit)) next.push_back(unit->GetGUID());
            for(auto const& guid:affected) if(std::find(next.begin(),next.end(),guid)==next.end()) Remove(guid);
            affected=next;
            for(auto const& guid:affected)
                if(Unit* unit=ObjectAccessor::GetUnit(*me,guid))
                    if(WD38A::Eligible(player,me,unit))
                    {
                        // Refresh the same aura in place; never remove/re-add each second.
                        if(Aura* aura=unit->GetAura(cfg->aura,owner)) aura->SetDuration(2200);
                        else if(cfg->entry==900202) me->CastCustomSpell(unit,cfg->aura,&swiftAmount,&swiftAmount,&swiftAmount,true,nullptr,nullptr,owner);
                        else me->CastSpell(unit,cfg->aura,true,nullptr,nullptr,owner);
                    }
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};

// WD40A: Sentry Ward. Private native dispel-immunity aura; no global visibility hooks.
namespace WD40A
{
constexpr uint32 Spell=9003400, Reveal=9003401, Entry=900196;
bool Eligible(Player* player,Creature* ward,Unit* target)
{
    return target && target->IsAlive() && target->IsInWorld() && ward->IsInMap(target) &&
        ward->InSamePhase(target) && ward->IsWithinDistInMap(target,30.0f) &&
        player->IsHostileTo(target) && ward->IsWithinLOSInMap(target);
}
}
class spell_reborn_wd40a_sentry : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd40a_sentry);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({WD40A::Spell,WD40A::Reveal}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !player->HasSpell(WD40A::Spell) || player->GetLevel()<30) return SPELL_FAILED_CASTER_AURASTATE;
        return sObjectMgr->GetCreatureTemplate(WD40A::Entry) ? SPELL_CAST_OK : SPELL_FAILED_ERROR;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);if(handled)return;handled=true;
        Player* player=GetCaster()->ToPlayer();if(!IsDoctor(player))return;
        Position pos=player->GetPosition();player->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(player));
        TempSummon* ward=player->SummonCreature(WD40A::Entry,pos,TEMPSUMMON_TIMED_DESPAWN,61000);
        if(!ward) { ChatHandler(player->GetSession()).SendSysMessage("哨戒守卫召唤失败，原守卫已保留。");return; }
        WD21A::Clear(player);
        player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid=ward->GetGUID();
        WD53A::Track(player,GetSpell(),ward->GetGUID());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd40a_sentry::CheckDoctor);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd40a_sentry::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd40a_sentry : public CreatureScript
{
public:
    npc_reborn_wd40a_sentry():CreatureScript("npc_reborn_wd40a_sentry") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature):ScriptedAI(creature) { }
        ObjectGuid owner;
        uint32 timer=1,remaining=60000;
        std::vector<ObjectGuid> affected;
        void Remove(ObjectGuid const& guid)
        {
            if(Unit* target=ObjectAccessor::GetUnit(*me,guid)) target->RemoveAurasDueToSpell(WD40A::Reveal,owner);
        }
        void ClearFields() { for(auto const& guid:affected) Remove(guid);affected.clear(); }
        void DoAction(int32 action) override { if(action==40) ClearFields(); }
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer():nullptr;
            if(!IsDoctor(player)) { me->DespawnOrUnsummon();return; }
            owner=player->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction());me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { ClearFields();me->DespawnOrUnsummon(); }
        void UpdateAI(uint32 diff) override
        {
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if(!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
                !player->IsInMap(me) || !player->InSamePhase(me) || !player->HasSpell(WD40A::Spell) ||
                player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid!=me->GetGUID())
            { ClearFields();me->DespawnOrUnsummon();return; }
            if(diff>=remaining) { ClearFields();me->DespawnOrUnsummon();return; }
            remaining-=diff;
            if(timer>diff) { timer-=diff;return; }timer=1000;
            std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(me,30.0f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);Cell::VisitObjects(me,search,30.0f);
            std::vector<ObjectGuid> next;
            for(Unit* unit:units) if(WD40A::Eligible(player,me,unit)) next.push_back(unit->GetGUID());
            for(auto const& guid:affected) if(std::find(next.begin(),next.end(),guid)==next.end()) Remove(guid);
            affected=next;
            for(auto const& guid:affected)
                if(Unit* unit=ObjectAccessor::GetUnit(*me,guid))
                    if(WD40A::Eligible(player,me,unit))
                    {
                        // Direct application deliberately does not require seeing the hidden target.
                        // Native IMMUNITY_PURGES_EFFECT removes stealth/invisibility by dispel type.
                        if(Aura* aura=unit->GetAura(WD40A::Reveal,owner)) aura->SetDuration(2200);
                        else if(Aura* aura=player->AddAura(WD40A::Reveal,unit)) aura->SetDuration(2200);
                    }
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};

// WD41A/WD42A: shared Effigy slot; independent of Ward, Idol and primary pet.
namespace WD41A
{
struct Config { uint32 spell, field, entry, level; bool hexing; };
constexpr Config Configs[]={{9003410,9003411,900197,8,false},{9003420,9003421,900198,24,true},{9003422,9003423,900199,34,false},{9003430,9003431,900201,58,false}};
Config const* BySpell(uint32 id) { for(auto const& c:Configs)if(c.spell==id)return &c;return nullptr; }
Config const* ByEntry(uint32 id) { for(auto const& c:Configs)if(c.entry==id)return &c;return nullptr; }
constexpr char Key[]="RebornWD41A.Effigy";
struct State : DataMap::Base { ObjectGuid guid; };
void Clear(Player* player)
{
    State* state=player->CustomData.GetDefault<State>(Key);
    if(!state->guid.IsEmpty() && player->IsInWorld())
        if(Creature* old=ObjectAccessor::GetCreature(*player,state->guid))
            if(ByEntry(old->GetEntry()) && old->GetOwnerGUID()==player->GetGUID())
            {
                if(old->AI())old->AI()->DoAction(41);
                old->DespawnOrUnsummon();
            }
    state->guid.Clear();
}
bool Eligible(Player* player,Creature* ward,Unit* target)
{
    return target && target->IsAlive() && target->IsInWorld() && ward->IsInMap(target) &&
        ward->InSamePhase(target) && ward->IsWithinDistInMap(target,ward->GetEntry()==900201 ? 15.0f : 30.0f) &&
        player->IsValidAttackTarget(target) && ward->IsWithinLOSInMap(target);
}
}
class spell_reborn_wd41a_effigy : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd41a_effigy);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003410,9003411,9003420,9003421,9003422,9003423,9003430,9003431}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();auto const* cfg=WD41A::BySpell(GetSpellInfo()->Id);
        if (!cfg || !IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !player->HasSpell(cfg->spell) || player->GetLevel()<cfg->level) return SPELL_FAILED_CASTER_AURASTATE;
        return sObjectMgr->GetCreatureTemplate(cfg->entry) ? SPELL_CAST_OK : SPELL_FAILED_ERROR;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);if(handled)return;handled=true;
        Player* player=GetCaster()->ToPlayer();auto const* cfg=WD41A::BySpell(GetSpellInfo()->Id);if(!cfg || !IsDoctor(player))return;
        Position pos=player->GetPosition();player->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(player));
        TempSummon* ward=player->SummonCreature(cfg->entry,pos,TEMPSUMMON_TIMED_DESPAWN,cfg->entry==900201 ? 16000 : 61000);
        if(!ward) { ChatHandler(player->GetSession()).SendSysMessage("雕像召唤失败，原雕像已保留。");return; }
        WD41A::Clear(player);
        player->CustomData.GetDefault<WD41A::State>(WD41A::Key)->guid=ward->GetGUID();
        WD53A::Track(player,GetSpell(),ward->GetGUID());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd41a_effigy::CheckDoctor);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd41a_effigy::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd41a_effigy : public CreatureScript
{
public:
    npc_reborn_wd41a_effigy():CreatureScript("npc_reborn_wd41a_effigy") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature):ScriptedAI(creature) { }
        ObjectGuid owner, pendingCaster;
        WD41A::Config const* cfg=nullptr;
        uint32 timer=1,remaining=60000;
        std::vector<ObjectGuid> affected;
        void Remove(ObjectGuid const& guid)
        {
            if(Unit* target=ObjectAccessor::GetUnit(*me,guid)) if(cfg && !cfg->hexing)target->RemoveAurasDueToSpell(cfg->field,owner);
        }
        void ClearFields() { for(auto const& guid:affected) Remove(guid);affected.clear(); }
        void DoAction(int32 action) override { if(action==41) ClearFields(); }
        void SetGUID(ObjectGuid const& guid, int32 id) override
        {
            if(id==42 && cfg && cfg->hexing && pendingCaster.IsEmpty())pendingCaster=guid;
        }
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer():nullptr;cfg=WD41A::ByEntry(me->GetEntry());
            if(!cfg || !IsDoctor(player)) { me->DespawnOrUnsummon();return; }
            if(cfg->entry==900201)remaining=15000;
            owner=player->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction());me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { ClearFields();me->DespawnOrUnsummon(); }
        void UpdateAI(uint32 diff) override
        {
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if(!cfg || !IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
                !player->IsInMap(me) || !player->InSamePhase(me) || !player->HasSpell(cfg->spell) ||
                (pendingCaster.IsEmpty() && player->CustomData.GetDefault<WD41A::State>(WD41A::Key)->guid!=me->GetGUID()))
            { ClearFields();me->DespawnOrUnsummon();return; }
            // React on the next AI update, outside the hostile caster's Spell::cast stack.
            if(!pendingCaster.IsEmpty())
            {
                ObjectGuid targetGuid=pendingCaster;pendingCaster.Clear();
                if(Unit* target=ObjectAccessor::GetUnit(*me,targetGuid))
                    if(target->IsAlive() && player->IsInMap(target) && player->InSamePhase(target) &&
                        player->IsValidAttackTarget(target) && player->IsWithinLOSInMap(target))
                        player->CastSpell(target,cfg->field,true);
                me->DespawnOrUnsummon();return;
            }
            if(diff>=remaining) { ClearFields();me->DespawnOrUnsummon();return; }
            remaining-=diff;
            if(cfg->hexing)return;
            if(timer>diff) { timer-=diff;return; }timer=1000;
            std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(me,30.0f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);Cell::VisitObjects(me,search,30.0f);
            std::vector<ObjectGuid> next;
            for(Unit* unit:units) if(WD41A::Eligible(player,me,unit)) next.push_back(unit->GetGUID());
            for(auto const& guid:affected) if(std::find(next.begin(),next.end(),guid)==next.end()) Remove(guid);
            affected=next;
            for(auto const& guid:affected)
                if(Unit* unit=ObjectAccessor::GetUnit(*me,guid))
                    if(WD41A::Eligible(player,me,unit))
                    {
                        // Both native slow effects live in ONE short aura. No periodic trigger or implicit target cast.
                        // AddAura still checks native spell/effect immunity.
                        if(Aura* aura=unit->GetAura(cfg->field,owner)) aura->SetDuration(2200);
                        else if(Aura* aura=player->AddAura(cfg->field,unit)) aura->SetDuration(2200);
                    }
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};

class player_reborn_wd41a_effigy : public PlayerScript
{
public:
    player_reborn_wd41a_effigy():PlayerScript("player_reborn_wd41a_effigy") { }
    void OnPlayerLogout(Player* player) override { WD41A::Clear(player); }
    void OnPlayerMapChanged(Player* player) override { WD41A::Clear(player); }
};

// WD42A: hooks are gated by private Effigy IDs/state. No shared core modification.
class wd42a_effigy_events : public AllSpellScript
{
public:
    wd42a_effigy_events():AllSpellScript("wd42a_effigy_events",{ALLSPELLHOOK_ON_CAST,ALLSPELLHOOK_ON_CALC_MAX_DURATION}) { }
    void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const* info,bool /*skip*/) override
    {
        if(!spell || !caster || !info || spell->IsTriggered() || info->IsPositive())return;
        Unit* target=spell->m_targets.GetUnitTarget();
        Player* player=target ? target->ToPlayer():nullptr;
        if(!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !caster->IsAlive() || !player->IsInMap(caster) || !player->InSamePhase(caster) ||
            !player->IsValidAttackTarget(caster) || !player->HasSpell(9003420))return;
        auto* state=player->CustomData.GetDefault<WD41A::State>(WD41A::Key);
        if(state->guid.IsEmpty())return;
        Creature* effigy=ObjectAccessor::GetCreature(*player,state->guid);
        if(!effigy || effigy->GetEntry()!=900198 || !effigy->IsAlive() ||
            effigy->GetOwnerGUID()!=player->GetGUID() || !effigy->InSamePhase(player) || !effigy->AI())return;
        // Consume once before queuing the reaction. Never interrupt the current Spell::cast stack.
        state->guid.Clear();
        effigy->AI()->SetGUID(caster->GetGUID(),42);
    }
    void OnCalcMaxDuration(Aura const* aura,int32& duration) override
    {
        if(!aura || duration<=0)return;
        Unit* target=aura->GetOwner()->ToUnit();
        if(!target)return; // DynamicObject auras are not unit-owned.
        SpellInfo const* info=aura->GetSpellInfo();
        // WD136: eight delivered ingredient effects only; preparation/other HoTs excluded.
        switch(info->Id)
        {
            case 9003867: case 9003889: case 9003903: case 9003904:
            case 9003907: case 9003908: case 9003917: case 9003918:
                if(Unit* source=aura->GetCaster())
                    if(Player* doctor=source->ToPlayer())
                        if(IsDoctor(doctor) && doctor->HasSpell(9003954) && doctor->HasAura(9003954,doctor->GetGUID()))
                            duration=int32(int64(duration)*120/100);
                break;
            default:break;
        }
        // WD86A: native duration hook runs before effect periodic initialization.
        if (info->Id>=WD68A::PuppetFirst && info->Id<=WD68A::PuppetLast)
            if (Player* player=aura->GetCaster()?aura->GetCaster()->ToPlayer():nullptr)
                if (IsDoctor(player)) duration=WD86A::Duration(player,duration);
        // WD45A: private passive increases only this new stun before native diminishing.
        if(info->Id==9003451)
            if(Unit* caster=aura->GetCaster())
                if(Player* player=caster->GetCharmerOrOwnerPlayerOrPlayerItself())
                    if(IsDoctor(player) && player->HasSpell(9003452) && player->HasAura(9003452))duration+=1000;

        if(info->Id==9003421)
        {
            bool pvp=target->GetTypeId()==TYPEID_PLAYER;
#ifdef MOD_NPCERBOTS
            pvp=pvp || target->IsNPCBotOrPet();
#endif
            if(pvp)duration=std::min(duration,8000);
            return; // Keep the authored Hexed PvP ceiling; native diminishing follows.
        }
        if(info->IsPositive() || info->HasAttribute(SPELL_ATTR7_NO_TARGET_DURATION_MOD))return;
        Aura* field=target->GetAura(9003423);
        if(!field)return;
        Player* player=ObjectAccessor::GetPlayer(*target,field->GetCasterGUID());
        if(!IsDoctor(player) || !player->IsAlive() || !player->HasSpell(9003422))return;
        auto* state=player->CustomData.GetDefault<WD41A::State>(WD41A::Key);
        if(state->guid.IsEmpty())return;
        Creature* effigy=ObjectAccessor::GetCreature(*target,state->guid);
        if(!effigy || effigy->GetEntry()!=900199 || !effigy->IsAlive() ||
            effigy->GetOwnerGUID()!=player->GetGUID() || !WD41A::Eligible(player,effigy,target))return;
        uint64 mechanics=info->GetAllEffectsMechanicMask();
        // Official 504767: root uses radius18=15yd; snare/disorient use radius10=30yd.
        bool affected=(mechanics & ((1ULL<<MECHANIC_SNARE)|(1ULL<<MECHANIC_DISORIENTED))) ||
            ((mechanics & (1ULL<<MECHANIC_ROOT)) && effigy->IsWithinDistInMap(target,15.0f));
        if(affected)
            duration=int32(std::min<int64>(int64(duration)*125/100,INT32_MAX));
        // Base duration only: native PvP caps, diminishing and resistance run afterward.
    }
};

class spell_reborn_wd44a_cleanse : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd44a_cleanse);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003440,9003441}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !player->HasSpell(9003440) || player->GetLevel()<16)
            return SPELL_FAILED_CASTER_AURASTATE;
        return sObjectMgr->GetCreatureTemplate(900203) ? SPELL_CAST_OK : SPELL_FAILED_ERROR;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (handled) return;
        handled=true;
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player)) return;
        Position pos=player->GetPosition();
        player->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(player));
        // WD44A: first dispel after 3s; 60s deadline includes final pulse, 61s safety expiry.
        TempSummon* idol=player->SummonCreature(900203,pos,TEMPSUMMON_TIMED_DESPAWN,61000);
        if (!idol)
        {
            ChatHandler(player->GetSession()).SendSysMessage("净化神像召唤失败，原神像已保留。");
            return;
        }
        WD36A::Clear(player);
        player->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid=idol->GetGUID();
        WD53A::Track(player,GetSpell(),idol->GetGUID());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd44a_cleanse::CheckDoctor);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd44a_cleanse::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd44a_cleanse : public CreatureScript
{
public:
    npc_reborn_wd44a_cleanse() : CreatureScript("npc_reborn_wd44a_cleanse") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature) : ScriptedAI(creature) { }
        ObjectGuid owner;
        uint32 timer=3000, remaining=60000;
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer() : nullptr;
            if (!IsDoctor(player)) { me->DespawnOrUnsummon();return; }
            owner=player->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction());me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
            timer=3000;remaining=60000;
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { me->DespawnOrUnsummon(); }
        void UpdateAI(uint32 diff) override
        {
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
                !player->IsInMap(me) || !player->InSamePhase(me) ||
                !player->HasSpell(9003440) ||
                player->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid!=me->GetGUID())
            { me->DespawnOrUnsummon();return; }
            uint32 step=std::min(diff,remaining);
            remaining-=step;
            if (timer>step) timer-=step;
            else
            {
                timer=3000; // One pulse per update; never catch-up bursts after lag.
                std::list<Unit*> units;
                Acore::AnyUnitInObjectRangeCheck check(me,30.0f);
                Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);
                Cell::VisitObjects(me,search,30.0f);
                std::vector<ObjectGuid> recipients;
                for (Unit* unit : units)
                    if (WD38A::Eligible(player,me,unit)) recipients.push_back(unit->GetGUID());
                for (ObjectGuid const& guid : recipients)
                    if (Unit* unit=ObjectAccessor::GetUnit(*me,guid))
                        if (WD38A::Eligible(player,me,unit))
                            me->CastSpell(unit,9003441,true,nullptr,nullptr,owner);
            }
            if (!remaining) me->DespawnOrUnsummon();
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};

// WD44A: local separately purchased group upgrade; native Aura41 manages immunity.
class spell_reborn_wd44a_mass_allcure : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd44a_mass_allcure);
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        return IsDoctor(player) && player->HasSpell(9003442) && player->HasSpell(9003250) && player->GetLevel()>=58
            ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Allies(std::list<WorldObject*>& targets)
    {
        targets.clear();Player* player=GetCaster()->ToPlayer();if(!IsDoctor(player))return;
        std::list<Unit*> units;
        Acore::AnyUnitInObjectRangeCheck check(player,30.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(player,units,check);
        Cell::VisitObjects(player,search,30.0f);
        for(Unit* unit:units)
        {
            if(!unit->IsAlive() || !player->IsInMap(unit) || !player->InSamePhase(unit) ||
               !player->IsFriendlyTo(unit) || !player->IsWithinDistInMap(unit,30.0f) ||
               !player->IsWithinLOSInMap(unit))continue;
            bool member=unit==player || (unit->GetTypeId()==TYPEID_PLAYER && player->IsInRaidWith(unit));
#ifdef MOD_NPCERBOTS
            if(unit->IsNPCBot())member=player->GetGroup() && unit->ToCreature()->GetBotGroup()==player->GetGroup();
#endif
            if(member)targets.push_back(unit);
        }
        if(std::find(targets.begin(),targets.end(),player)==targets.end())targets.push_back(player);
    }
    void SharedCooldown()
    {
        if(Player* player=GetCaster()->ToPlayer())
            player->AddSpellCooldown(9003250,0,GameTime::GetGameTime().count()+GetSpellInfo()->RecoveryTime/1000,true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd44a_mass_allcure::CheckDoctor);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd44a_mass_allcure::Allies,EFFECT_0,TARGET_UNIT_CASTER_AREA_RAID);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd44a_mass_allcure::Allies,EFFECT_1,TARGET_UNIT_CASTER_AREA_RAID);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd44a_mass_allcure::Allies,EFFECT_2,TARGET_UNIT_CASTER_AREA_RAID);
        AfterCast += SpellCastFn(spell_reborn_wd44a_mass_allcure::SharedCooldown);
    }
};

// WD45A: delayed one-shot Ward; no self periodic suicide spell or raw target pointer.
class spell_reborn_wd45a_stasis : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd45a_stasis);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003450,9003451,9003452}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        if(!IsDoctor(player) || !player->IsAlive() || !player->HasSpell(9003450) || player->GetLevel()<14)
            return SPELL_FAILED_CASTER_AURASTATE;
        return sObjectMgr->GetCreatureTemplate(900204) ? SPELL_CAST_OK : SPELL_FAILED_ERROR;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);if(handled)return;handled=true;
        Player* player=GetCaster()->ToPlayer();if(!IsDoctor(player))return;
        Position pos=player->GetPosition();player->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(player));
        TempSummon* ward=player->SummonCreature(900204,pos,TEMPSUMMON_TIMED_DESPAWN,5000);
        if(!ward) { ChatHandler(player->GetSession()).SendSysMessage("静滞守卫召唤失败，原守卫已保留。");return; }
        WD21A::Clear(player);
        player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid=ward->GetGUID();
        WD53A::Track(player,GetSpell(),ward->GetGUID());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd45a_stasis::CheckDoctor);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd45a_stasis::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd45a_stasis : public CreatureScript
{
public:
    npc_reborn_wd45a_stasis():CreatureScript("npc_reborn_wd45a_stasis") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature):ScriptedAI(creature) { }
        ObjectGuid owner;
        uint32 timer=2000;
        bool fired=false;
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer():nullptr;
            if(!IsDoctor(player)) { me->DespawnOrUnsummon();return; }
            owner=player->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction());me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { fired=true;me->DespawnOrUnsummon(); }
        void UpdateAI(uint32 diff) override
        {
            if(fired)return;
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if(!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() || !player->IsInMap(me) ||
                !player->InSamePhase(me) || !player->HasSpell(9003450) ||
                player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid!=me->GetGUID())
            { fired=true;me->DespawnOrUnsummon();return; }
            if(timer>diff) { timer-=diff;return; }
            // Consume the slot before callbacks. A second AI tick cannot fire again.
            fired=true;player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid.Clear();
            me->CastSpell(me,9003451,true,nullptr,nullptr,owner);
            me->DespawnOrUnsummon(std::chrono::milliseconds(1));
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};
class spell_reborn_wd45a_burst : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd45a_burst);
    void Enemies(std::list<WorldObject*>& targets)
    {
        Unit* ward=GetCaster();Player* player=ward->GetCharmerOrOwnerPlayerOrPlayerItself();
        targets.remove_if([ward,player](WorldObject* object)
        {
            Unit* unit=object->ToUnit();
            return !IsDoctor(player) || !unit || !unit->IsAlive() || !ward->IsInMap(unit) ||
                !ward->InSamePhase(unit) || !ward->IsWithinDistInMap(unit,10.0f) ||
                !ward->IsWithinLOSInMap(unit) || !player->IsValidAttackTarget(unit);
        });
    }
    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd45a_burst::Enemies,EFFECT_0,TARGET_UNIT_SRC_AREA_ENEMY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd45a_burst::Enemies,EFFECT_2,TARGET_UNIT_SRC_AREA_ENEMY);
    }
};

// WD46A: copy effective healing once, after the native heal has completed.
namespace WD46A
{
    constexpr uint32 Damage = 9003468, Touch = 9003470, Debuff = 9003471;
    bool Enemy(Player* player, Unit* center, Unit* unit)
    {
        return IsDoctor(player) && center && unit && unit->IsAlive() &&
            player->IsInMap(unit) && player->InSamePhase(unit) && center->IsInMap(unit) &&
            center->InSamePhase(unit) && center->IsWithinDistInMap(unit,5.0f) &&
            center->IsWithinLOSInMap(unit) && player->IsValidAttackTarget(unit);
    }
}
class spell_reborn_wd46a_bottle : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd46a_bottle);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({WD46A::Damage,WD46A::Touch,WD46A::Debuff}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        return IsDoctor(player) && player->IsAlive() && player->HasSpell(GetSpellInfo()->Id) &&
            player->GetLevel()>=GetSpellInfo()->SpellLevel ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Coefficient(SpellEffIndex)
    {
        Player* player=GetCaster()->ToPlayer();if(!IsDoctor(player))return;
        // Match CoA base-value scaling; native SQL coefficient is zero, also for old ranks.
        int32 power=std::max(0,player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_SHADOW));
        SetEffectValue(int32(float(GetEffectValue())+float(power)*(player->HasAura(9003911)?0.45f*1.15f:0.45f)));
    }
    void Splash()
    {
        if(handled)return;
        handled=true;
        Player* player=GetCaster()->ToPlayer();Unit* center=GetHitUnit();
        // In this core AfterHit reads m_healing after HealBySpell writes effective gain.
        int32 healing=GetHitHeal();
        if(!IsDoctor(player) || !player->IsAlive() || !center || healing<=0)return;
        int32 amount=int32(uint64(healing)*4/100);
        if(!amount)return;
        ObjectGuid centerGuid=center->GetGUID();
        std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(center,5.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,units,check);
        Cell::VisitObjects(center,search,5.0f);
        units.remove_if([player,center](Unit* unit) { return !WD46A::Enemy(player,center,unit); });
        units.sort([center](Unit* a,Unit* b)
        {
            float da=center->GetDistance(a),db=center->GetDistance(b);
            return da==db ? a->GetGUID()<b->GetGUID() : da<db;
        });
        // Snapshot GUIDs before any synchronous spell/proc callback can alter nearby units.
        std::vector<ObjectGuid> targets;
        for(Unit* unit:units) { targets.push_back(unit->GetGUID());if(targets.size()==5)break; }
        for(ObjectGuid guid:targets)
        {
            Unit* liveCenter=ObjectAccessor::GetUnit(*player,centerGuid);
            Unit* enemy=ObjectAccessor::GetUnit(*player,guid);
            if(!player->IsAlive() || !WD46A::Enemy(player,liveCenter,enemy))continue;
            player->CastCustomSpell(enemy,WD46A::Damage,&amount,nullptr,nullptr,true);
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd46a_bottle::CheckDoctor);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd46a_bottle::Coefficient,EFFECT_0,SPELL_EFFECT_HEAL);
        AfterHit += SpellHitFn(spell_reborn_wd46a_bottle::Splash);
    }
};
class spell_reborn_wd46a_damage : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd46a_damage);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({WD46A::Touch,WD46A::Debuff}); }
    void ApplyTouch()
    {
        if(handled)return;
        handled=true;
        Player* player=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        // AfterHit damage is post immunity/resist/absorb. No debuff on a fully absorbed hit.
        if(GetHitDamage()<=0 || !IsDoctor(player) || !player->IsAlive() || !target || !target->IsAlive() ||
            !player->HasSpell(WD46A::Touch) || !player->HasAura(WD46A::Touch) || !player->IsValidAttackTarget(target))return;
        player->CastSpell(target,WD46A::Debuff,true);
    }
    void Register() override { AfterHit += SpellHitFn(spell_reborn_wd46a_damage::ApplyTouch); }
};

// WD47A: direct Loa's Brew healing only; echoes and copied heals never re-enter.
namespace WD47A
{
    constexpr uint32 Blessing=9003480, Secrets=9003481, Heal=9003486;
    bool Ally(Player* player, Creature* effigy, Unit* unit, ObjectGuid primary)
    {
        if (!unit || unit->GetGUID()==primary || !unit->IsAlive() || !unit->IsInWorld() ||
            unit->GetHealth()>=unit->GetMaxHealth() || !player->IsInMap(unit) ||
            !player->InSamePhase(unit) || !player->IsFriendlyTo(unit) ||
            !effigy->IsInMap(unit) || !effigy->InSamePhase(unit) ||
            !effigy->IsWithinDistInMap(unit,20.0f) || !effigy->IsWithinLOSInMap(unit))return false;
        if(unit->GetTypeId()==TYPEID_PLAYER)return unit==player || player->IsInRaidWith(unit);
#ifdef MOD_NPCERBOTS
        if(unit->IsNPCBot())return player->GetGroup() && unit->ToCreature()->GetBotGroup()==player->GetGroup();
#endif
        return false;
    }
    void Echo(Player* player, ObjectGuid primary, int32 healing)
    {
        int32 amount=int32(uint64(healing)*35/100);
        if(!amount || !player->HasSpell(Secrets) || !player->HasAura(Secrets))return;
        // Resolve the accepted Effigy slot; Ward and Idol slots are intentionally unrelated.
        ObjectGuid guid=player->CustomData.GetDefault<WD41A::State>(WD41A::Key)->guid;
        Creature* effigy=ObjectAccessor::GetCreature(*player,guid);
        if(!effigy || !effigy->IsAlive() || !effigy->IsInWorld() || !WD41A::ByEntry(effigy->GetEntry()) ||
            effigy->GetOwnerGUID()!=player->GetGUID() || !player->IsInMap(effigy) ||
            !player->InSamePhase(effigy))return;
        std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(effigy,20.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(effigy,units,check);
        Cell::VisitObjects(effigy,search,20.0f);
        units.remove_if([player,effigy,primary](Unit* unit){return !Ally(player,effigy,unit,primary);});
        units.sort([](Unit* a,Unit* b)
        {
            // Integer cross product compares percentages without float rounding.
            uint64 left=uint64(a->GetHealth())*b->GetMaxHealth();
            uint64 right=uint64(b->GetHealth())*a->GetMaxHealth();
            return left==right ? a->GetGUID()<b->GetGUID() : left<right;
        });
        if(!units.empty())player->CastCustomSpell(units.front(),Heal,&amount,nullptr,nullptr,true);
    }
}
class spell_reborn_wd47a_brew : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd47a_brew);
    bool handled=false;
    bool Validate(SpellInfo const*) override {return ValidateSpellInfo({9003480,9003481,9003482,9003483,9003484,9003485,9003486});}
    void Empower()
    {
        if(handled)return;
        handled=true;
        Player* player=GetCaster()->ToPlayer();Unit* primary=GetHitUnit();int32 healing=GetHitHeal();
        if(!IsDoctor(player) || !player->IsAlive() || !primary || !primary->IsAlive() ||
            !WD19A::IsBrew(GetSpellInfo()->Id) || GetSpell()->IsTriggered() || healing<=0)return;
        ObjectGuid primaryGuid=primary->GetGUID();
        WD47A::Echo(player,primaryGuid,healing);
        // A synchronous heal/proc can change target state, so resolve it again.
        primary=ObjectAccessor::GetUnit(*player,primaryGuid);
        if(player->IsAlive() && primary && primary->IsAlive() && player->HasSpell(WD47A::Blessing) && player->HasAura(WD47A::Blessing) &&
            player->IsInMap(primary) && player->InSamePhase(primary) && player->IsFriendlyTo(primary))
        {
            constexpr uint32 blessings[]={9003482,9003483,9003484,9003485};
            player->CastSpell(primary,blessings[urand(0,3)],true);
        }
    }
    void Register() override {AfterHit += SpellHitFn(spell_reborn_wd47a_brew::Empower);}
};

class spell_reborn_wd47a_heal : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd47a_heal);
    int32 copied=0;
    void Capture(SpellEffIndex) { copied=std::max(0,GetEffectValue()); }
    void ExactCopy() { SetHitHeal(copied); }
    void Register() override
    {
        // This core's healing-taken path ignores ATTR4 damage flags. Restore the
        // copied amount before native absorb/overheal rather than amplify it twice.
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd47a_heal::Capture,EFFECT_0,SPELL_EFFECT_HEAL);
        OnHit += SpellHitFn(spell_reborn_wd47a_heal::ExactCopy);
    }
};

// WD48A: two direct-damage families, with native damage settlement and cooldowns.
namespace WD48A
{
    bool Juju(uint32 id) { return WD19A::IsBadJuju(id) && id!=9003490; }
    bool Fire(uint32 id) { return id>=9003500 && id<=9003507; }
    bool Hexed(Unit* target)
    {
        for(auto const& rank:WD19A::HexRanks)if(target->HasAura(rank.spell))return true;
        return false;
    }
}
class spell_reborn_wd48a_attack : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd48a_attack);
    bool marked=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003499}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();uint32 id=GetSpellInfo()->Id;
        return IsDoctor(player) && player->IsAlive() && (WD48A::Juju(id) || WD48A::Fire(id)) &&
            player->HasSpell(id) && (!WD48A::Juju(id) || WD5A::CanCastBadJuju(player)) &&
            player->GetLevel()>=GetSpellInfo()->SpellLevel ?
            SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Scale(SpellEffIndex)
    {
        Player* player=GetCaster()->ToPlayer();if(!IsDoctor(player))return;
        float extra=0.0f;
        if(WD48A::Juju(GetSpellInfo()->Id))
            extra=float(std::max(0,player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)))+
                player->GetStat(STAT_SPIRIT)*0.30f;
        else
        {
            float fire=float(std::max(0,player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE)));
            float nature=float(std::max(0,player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE)));
            // Preserve the selected official tooltip's conditional, including the tie.
            extra=fire>nature ? fire*0.55f : nature*0.55f+player->GetStat(STAT_SPIRIT)*0.50f;
        }
        SetEffectValue(int32(float(GetEffectValue())+extra));
    }
    void Mark()
    {
        if(marked)return;
        marked=true;
        Player* player=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        if(!WD48A::Juju(GetSpellInfo()->Id) || GetHitDamage()<=0 || !IsDoctor(player) ||
            !player->IsAlive() || !target || !target->IsAlive() || !player->IsInMap(target) ||
            !player->InSamePhase(target) || !player->IsValidAttackTarget(target) || !WD48A::Hexed(target))return;
        // The source contract accepts Hex of Malice from any caster, not other curses.
        player->CastSpell(target,9003499,true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd48a_attack::CheckDoctor);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd48a_attack::Scale,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(spell_reborn_wd48a_attack::Mark);
    }
};

// WD49A: native modifiers; exact families prevent effects leaking into other classes.
class reborn_wd49a_exact_crit : public GlobalScript
{
public:
    reborn_wd49a_exact_crit() : GlobalScript("reborn_wd49a_exact_crit") { }
    bool OnIsAffectedBySpellModCheck(SpellInfo const*, SpellInfo const* check,
        SpellModifier const* mod) override
    {
        if (!check || !mod) return true;
        // In this core false means this modifier affects this spell, bypassing
        // family-mask matching. WD89A rejects other targets before native fallback.
        if (mod->spellId==9003510 && mod->op==SPELLMOD_CRITICAL_CHANCE)
            return !(WD19A::IsWrath(check->Id) || WD48A::Juju(check->Id));
        if (mod->spellId==9003511 &&
            (mod->op==SPELLMOD_CRITICAL_CHANCE || mod->op==SPELLMOD_CRIT_DAMAGE_BONUS))
            return !WD48A::Fire(check->Id);
        return true;
    }
};

// WD83A: one target-local multiplier, before critical damage / resistance / absorb.
// Current upstream abd08cd3 uses OwnedHex and exactly these three spell families.
class spell_reborn_wd83a_ritual : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd83a_ritual);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003710,9003711}); }
    void Damage()
    {
        Player* player=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        if(!IsDoctor(player) || !player->IsAlive() || !target || player->IsFriendlyTo(target) ||
            !(WD19A::IsWrath(GetSpellInfo()->Id) || WD48A::Juju(GetSpellInfo()->Id) || WD48A::Fire(GetSpellInfo()->Id))) return;
        uint32 rank=WD5A::RitualHexingRank(player);
        if(!rank || rank>2 || !player->HasAura(rank==2?9003711:9003710)) return;
        bool owned=false;
        for(auto const& hex:WD19A::HexRanks)
            if(target->HasAura(hex.spell,player->GetGUID())) {owned=true;break;}
        int32 damage=GetHitDamage();
        if(owned && damage>0) SetHitDamage(int32(int64(damage)*(100+10*rank)/100));
    }
    void Register() override { OnHit += SpellHitFn(spell_reborn_wd83a_ritual::Damage); }
};

// WD50A: bounded propagation preserves the owner's original periodic snapshot.
namespace WD50A
{
    constexpr uint32 Malignant=9003520, Hexplosion=9003521, Haste=9003522;
    Aura* OwnedHex(Player* player, Unit* target)
    {
        for (auto const& rank:WD19A::HexRanks)
            if (Aura* aura=target->GetAura(rank.spell,player->GetGUID())) return aura;
        return nullptr;
    }
    bool Enemy(Player* player, Unit* center, Unit* unit)
    {
        return unit && unit!=center && unit->IsAlive() && unit->IsInWorld() &&
            player->IsInMap(unit) && player->InSamePhase(unit) &&
            center->IsInMap(unit) && center->InSamePhase(unit) &&
            player->IsValidAttackTarget(unit) && center->IsWithinDistInMap(unit,8.0f) &&
            center->IsWithinLOSInMap(unit) && !OwnedHex(player,unit);
    }
    void Spread(Player* player, Unit* primary)
    {
        Aura* source=OwnedHex(player,primary);
        AuraEffect* original=source ? source->GetEffect(EFFECT_0) : nullptr;
        if (!original || source->GetDuration()<=0) return;
        // Snapshot scalar values before AddAura: application hooks may change auras.
        uint32 spell=source->GetId();int32 duration=source->GetDuration();
        int32 amount=original->GetAmount(),timer=original->GetPeriodicTimer();
        float crit=original->GetCritChance();
        std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(primary,8.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(primary,units,check);
        Cell::VisitObjects(primary,search,8.0f);
        units.remove_if([player,primary](Unit* unit){return !Enemy(player,primary,unit);});
        units.sort([primary](Unit* a,Unit* b)
        {
            float da=primary->GetDistance(a),db=primary->GetDistance(b);
            return da==db ? a->GetGUID()<b->GetGUID() : da<db;
        });
        for (Unit* unit:units)
        {
            if (!player->IsAlive() || !primary->IsAlive()) return;
            if (!Enemy(player,primary,unit)) continue;
            // AddAura, not CastSpell: no initial direct damage or further spreading.
            if (Aura* copy=player->AddAura(spell,unit))
            {
                copy->SetDuration(duration);
                if (AuraEffect* effect=copy->GetEffect(EFFECT_0))
                {
                    effect->ChangeAmount(amount);
                    effect->SetPeriodicTimer(timer);
                    // Core still rolls each tick. Do not resnapshot at spread time.
                    effect->SetCritChance(crit);
                }
                break; // At most one successfully affected secondary enemy per hit.
            }
        }
    }
}
class spell_reborn_wd50a_spread : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd50a_spread);
    bool handled=false;
    bool Validate(SpellInfo const*) override {return ValidateSpellInfo({9003520});}
    void AfterDamage()
    {
        if (handled) return;
        handled=true;
        Player* player=GetCaster()->ToPlayer();Unit* primary=GetHitUnit();
        if (!IsDoctor(player) || !player->IsAlive() || !WD5A::CanUseHexTalent(player,WD50A::Malignant) ||
            !player->HasSpell(WD50A::Malignant) || !player->HasAura(WD50A::Malignant) ||
            GetHitDamage()<=0 || !primary || !primary->IsAlive() ||
            !player->IsInMap(primary) || !player->InSamePhase(primary) ||
            !player->IsValidAttackTarget(primary) ||
            (!WD48A::Juju(GetSpellInfo()->Id) && !WD48A::Fire(GetSpellInfo()->Id))) return;
        WD50A::Spread(player,primary);
    }
    void Register() override {AfterHit += SpellHitFn(spell_reborn_wd50a_spread::AfterDamage);}
};
class aura_reborn_wd50a_hexplosion : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd50a_hexplosion);
    bool Validate(SpellInfo const*) override {return ValidateSpellInfo({9003521,9003522});}
    bool Check(ProcEventInfo& event)
    {
        Player* player=GetTarget()->ToPlayer();Unit* target=event.GetActionTarget();
        return IsDoctor(player) && player->IsAlive() && WD5A::CanUseHexTalent(player,WD50A::Hexplosion) &&
            player->HasSpell(WD50A::Hexplosion) && event.GetActor()==player &&
            target && target!=player && !player->IsFriendlyTo(target) && player->IsInMap(target) && player->InSamePhase(target) &&
            event.GetDamageInfo() && event.GetDamageInfo()->GetDamage()>0 &&
            (event.GetHitMask() & PROC_HIT_CRITICAL);
    }
    void Proc(ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(),WD50A::Haste,true);
    }
    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(WD50A::Haste);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_reborn_wd50a_hexplosion::Check);
        OnProc += AuraProcFn(aura_reborn_wd50a_hexplosion::Proc);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd50a_hexplosion::Remove,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};

// WD51A: periodic procs; raw DoT snapshots remain unchanged.
namespace WD51A
{
    constexpr uint32 Growth=9003530, GrowthDebuff=9003531, Berserking=9003532, WardHaste=9003533;
    // WD51B: this project exposes HexRanks, not WD19A::IsHex.
    bool IsHex(uint32 spell)
    {
        for (auto const& rank : WD19A::HexRanks)
            if (rank.spell == spell) return true;
        return false;
    }
    constexpr char Key[]="RebornWD51A.GrowthTargets";
    struct State : DataMap::Base { std::vector<ObjectGuid> targets; };
    Creature* OwnedSerpent(Player* player)
    {
        Creature* ward=ObjectAccessor::GetCreature(*player,player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid);
        return ward && ward->GetEntry()==WD21A::Entry && ward->GetOwnerGUID()==player->GetGUID() &&
            ward->IsAlive() && player->IsInMap(ward) && player->InSamePhase(ward) ? ward : nullptr;
    }
}
class aura_reborn_wd51a_periodic : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd51a_periodic);
    bool Validate(SpellInfo const*) override {return ValidateSpellInfo({9003530,9003531,9003532,9003533});}
    bool Check(ProcEventInfo& event)
    {
        Player* player=GetTarget()->ToPlayer();Unit* target=event.GetActionTarget();
        if (!IsDoctor(player) || !player->IsAlive() ||
            (GetId()==WD51A::Growth ? !WD5A::CanUseHexTalent(player,WD51A::Growth) : player->GetLevel()<30) ||
            !player->HasSpell(GetId()) || event.GetActor()!=player ||
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) ||
            !event.GetDamageInfo() || !event.GetDamageInfo()->GetDamage() ||
            !target || !target->IsAlive() || player->IsFriendlyTo(target) ||
            !player->IsInMap(target) || !player->InSamePhase(target)) return false;
        if (GetId()==WD51A::Growth)
            return event.GetSpellInfo() && WD51A::IsHex(event.GetSpellInfo()->Id) && WD50A::OwnedHex(player,target);
        return GetId()==WD51A::Berserking && WD51A::OwnedSerpent(player);
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* player=GetTarget()->ToPlayer();
        if (GetId()==WD51A::Growth)
        {
            Unit* target=event.GetActionTarget();
            if (!target || !WD50A::OwnedHex(player,target)) return;
            // Applied after the damaging tick: only the NEXT tick receives the new stack.
            if (player->AddAura(WD51A::GrowthDebuff,target))
            {
                auto& targets=player->CustomData.GetDefault<WD51A::State>(WD51A::Key)->targets;
                if (std::find(targets.begin(),targets.end(),target->GetGUID())==targets.end())
                    targets.push_back(target->GetGUID());
            }
        }
        else if (Creature* ward=WD51A::OwnedSerpent(player))
            // Bounded owned summon, native apply-aura; no CoA Effect190/area targeting.
            player->AddAura(WD51A::WardHaste,ward);
    }
    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetId()==WD51A::Growth)
            if (Player* player=GetTarget()->ToPlayer())
            {
                auto targets=player->CustomData.GetDefault<WD51A::State>(WD51A::Key)->targets;
                player->CustomData.GetDefault<WD51A::State>(WD51A::Key)->targets.clear();
                for (ObjectGuid guid:targets)
                    if (Unit* target=ObjectAccessor::GetUnit(*player,guid))
                        target->RemoveAurasDueToSpell(WD51A::GrowthDebuff,player->GetGUID());
            }
        if (GetId()==WD51A::Berserking)
            if (Player* player=GetTarget()->ToPlayer())
                if (Creature* ward=WD51A::OwnedSerpent(player))
                    ward->RemoveAurasDueToSpell(WD51A::WardHaste,player->GetGUID());
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_reborn_wd51a_periodic::Check);
        OnProc += AuraProcFn(aura_reborn_wd51a_periodic::Proc);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd51a_periodic::Remove,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};
class aura_reborn_wd51a_hex_cleanup : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd51a_hex_cleanup);
    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(WD51A::GrowthDebuff,GetCasterGUID());
        if (Unit* caster=GetCaster())
            if (Player* player=caster->ToPlayer())
            {
                auto& targets=player->CustomData.GetDefault<WD51A::State>(WD51A::Key)->targets;
                targets.erase(std::remove(targets.begin(),targets.end(),GetTarget()->GetGUID()),targets.end());
            }
    }
    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd51a_hex_cleanup::Remove,EFFECT_0,SPELL_AURA_PERIODIC_DAMAGE,AURA_EFFECT_HANDLE_REAL);
    }
};

namespace WD53A
{
uint32 Default(Player* player,uint32 slot)
{
    uint32 const choices[]={9003160,9003170,9003450,9003400,9003370,9003440,9003432,
        9003382,9003380,9003390,9003410,9003420,9003422,9003430};
    for (uint32 id:choices) if (Slot(id)==int(slot) && player->HasSpell(id)) return id;
    return 0;
}
ObjectGuid Current(Player* player, uint32 slot)
{
    if (slot==0) return player->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid;
    if (slot==1) return player->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid;
    return player->CustomData.GetDefault<WD41A::State>(WD41A::Key)->guid;
}
bool Entry(uint32 slot,uint32 entry)
{
    if (slot==0) return WD21A::IsWardEntry(entry);
    if (slot==1) return entry==900192 || entry==900193 || entry==900194 || entry==900195 || entry==900202 || entry==900203;
    return WD41A::ByEntry(entry)!=nullptr;
}
void Clear(Player* player,uint32 slot)
{
    if (slot==0) WD21A::Clear(player);
    else if (slot==1) WD36A::Clear(player);
    else WD41A::Clear(player);
}
class Selection : public PlayerScript
{
public:
    Selection():PlayerScript("player_reborn_wd53a_selection") { }
    bool OnPlayerCanUseChat(Player* player,uint32,uint32 language,std::string& msg,Player* receiver) override
    {
        if (language!=LANG_ADDON || msg.compare(0,9,"RBWD53\tS ")!=0) return true;
        // Consume only our protocol. This is selection metadata, never a cast request.
        auto* state=player->CustomData.GetDefault<State>(Key);
        if (receiver!=player || !IsDoctor(player)) return false;
        std::istringstream input(msg.substr(9)); uint32 ids[3]={}; std::string extra;
        if (!(input>>ids[0]>>ids[1]>>ids[2]) || (input>>extra)) return false;
        for (uint32 i=0;i<3;++i)
            if (ids[i] && (Slot(ids[i])!=int(i) || !player->HasSpell(ids[i]))) return false;
        for (uint32 i=0;i<3;++i) state->selected[i]=ids[i];
        return false;
    }
    void OnPlayerMapChanged(Player* player) override
    {
        for (auto& paid:player->CustomData.GetDefault<State>(Key)->paid) paid=Paid{};
    }
};
}
class spell_reborn_wd53a_rite : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd53a_rite);
    uint32 selected[3]={};
    SpellCastResult Check()
    {
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
            !player->HasSpell(WD53A::Rite) || player->GetLevel()<30)
            return SPELL_FAILED_CASTER_AURASTATE;
        auto* state=player->CustomData.GetDefault<WD53A::State>(WD53A::Key);
        int64 total=0; bool any=false;
        for (uint32 i=0;i<3;++i)
        {
            selected[i]=state->selected[i] ? state->selected[i] : WD53A::Default(player,i);
            if (!selected[i]) continue;
            any=true;
            SpellInfo const* info=sSpellMgr->GetSpellInfo(selected[i]);
            if (!info || WD53A::Slot(selected[i])!=int(i) || !player->HasSpell(selected[i]) ||
                player->GetLevel()<info->SpellLevel || info->PowerType!=POWER_MANA)
                return SPELL_FAILED_NOT_KNOWN;
            if (player->HasSpellCooldown(selected[i])) return SPELL_FAILED_NOT_READY;
            total+=std::max(0,info->CalcPowerCost(player,info->GetSchoolMask()));
        }
        if (!any) return SPELL_FAILED_NOT_READY;
        if (!player->GetCommandStatus(CHEAT_POWER) && total>player->GetPower(POWER_MANA)) return SPELL_FAILED_NO_POWER;
        return SPELL_CAST_OK;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player=GetCaster()->ToPlayer(); if (!IsDoctor(player)) return;
        // Same three flags as native EffectCastButtons: retain mana, individual cooldowns,
        // school/silence checks and existing per-family CheckDoctor scripts.
        TriggerCastFlags flags=TriggerCastFlags(TRIGGERED_IGNORE_GCD|TRIGGERED_IGNORE_CAST_IN_PROGRESS|TRIGGERED_CAST_DIRECTLY);
        auto* state=player->CustomData.GetDefault<WD53A::State>(WD53A::Key);
        for (uint32 slot=0;slot<3;++slot)
        {
            state->placementAngle=float(slot)*2.0943951f;
            if (selected[slot] && player->HasSpell(selected[slot])) player->CastSpell(player,selected[slot],flags);
        }
        state->placementAngle=0.0f;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd53a_rite::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd53a_rite::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class spell_reborn_wd53a_recall : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd53a_recall);
    SpellCastResult Check()
    {
        Player* player=GetCaster()->ToPlayer();
        return IsDoctor(player) && player->IsAlive() && player->IsInWorld() &&
            player->HasSpell(WD53A::Recall) && player->GetLevel()>=30 ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Recall(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player=GetCaster()->ToPlayer(); if (!IsDoctor(player)) return;
        auto* state=player->CustomData.GetDefault<WD53A::State>(WD53A::Key);
        uint64 total=0;
        for (uint32 slot=0;slot<3;++slot)
        {
            ObjectGuid guid=WD53A::Current(player,slot);
            Creature* summon=ObjectAccessor::GetCreature(*player,guid);
            auto paid=state->paid[slot]; state->paid[slot]=WD53A::Paid{};
            if (!summon || !summon->IsAlive() || !summon->IsInWorld() ||
                summon->GetOwnerGUID()!=player->GetGUID() || !WD53A::Entry(slot,summon->GetEntry())) continue;
            // Consume the receipt before the lifecycle cleanup; repeated casts cannot refund it again.
            if (paid.guid==guid) total+=paid.mana;
            WD53A::Clear(player,slot);
        }
        uint32 refund=uint32(std::min<uint64>(total/2,player->GetMaxPower(POWER_MANA)));
        if (refund) player->EnergizeBySpell(player,GetSpellInfo()->Id,refund,POWER_MANA);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd53a_recall::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd53a_recall::Recall,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};

// WD55A: Shadowflare is a direct ground AoE in current CoA, not a channel.
// Spirit's native periodic heal/energize and stack lifecycle remain in the DBC.
class spell_reborn_wd55a_shadowflare : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd55a_shadowflare);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003574}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        WD19A::Family const* family=WD19A::FindFamily(GetSpellInfo()->Id);
        return IsDoctor(player) && player->IsAlive() && family &&
            family->ranks[0].spell==9003560 && player->HasSpell(GetSpellInfo()->Id) &&
            player->GetLevel()>=GetSpellInfo()->SpellLevel ?
            SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Scale(SpellEffIndex)
    {
        Player* player=GetCaster()->ToPlayer();
        if (!IsDoctor(player)) return;
        float shadow=float(std::max(0,player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
        float ranged=std::max(0.0f,player->GetTotalAttackPowerValue(RANGED_ATTACK));
        SetEffectValue(int32(float(GetEffectValue())+0.35f*shadow*WD84A::PowerScale(player)+0.10f*ranged));
    }
    void RewardKill()
    {
        Player* player=GetCaster()->ToPlayer();
        Unit* target=GetHitUnit();
        // AfterHit is after native damage resolution. Surviving, immune and absorbed
        // hits grant nothing. Each killed target in this AoE grants one stack.
        if (!IsDoctor(player) || !player->IsAlive() || !target ||
            GetHitDamage()<=0 || target->IsAlive()) return;
        player->CastSpell(player,9003574,true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd55a_shadowflare::CheckDoctor);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd55a_shadowflare::Scale,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(spell_reborn_wd55a_shadowflare::RewardKill);
    }
};

// WD56A: separate cooldown summon; never occupies Ward/Idol/Effigy slots.
namespace WD56A
{
constexpr uint32 Spell=9003580, Immunity=9003581, Protection=9003582, Lock=9003583, Entry=900211;
constexpr char Key[]="RebornWD56A.Bwonsamdi";
struct State : DataMap::Base { ObjectGuid guid; };
void Clear(Player* player)
{
    if (!player) return;
    auto* state=player->CustomData.GetDefault<State>(Key);
    ObjectGuid guid=state->guid; state->guid.Clear();
    if (Creature* summon=ObjectAccessor::GetCreature(*player,guid))
        if (summon->GetOwnerGUID()==player->GetGUID() && summon->GetEntry()==Entry)
        { if (summon->AI()) summon->AI()->DoAction(56); summon->DespawnOrUnsummon(); }
    player->RemoveAurasDueToSpell(Immunity,player->GetGUID());
}
bool Eligible(Player* owner,Creature* source,Unit* unit)
{
    if (!unit || !unit->IsAlive() || !unit->IsInWorld() || !source->IsInMap(unit) ||
        !source->InSamePhase(unit) || !owner->IsFriendlyTo(unit) ||
        !source->IsWithinDistInMap(unit,15.0f) || !source->IsWithinLOSInMap(unit)) return false;
    if (unit==owner) return true;
    if (unit->IsPlayer()) return owner->IsInRaidWith(unit);
#ifdef MOD_NPCERBOTS
    if (unit->IsNPCBot()) return owner->GetGroup() && unit->ToCreature()->GetBotGroup()==owner->GetGroup();
#endif
    return false;
}
}
class spell_reborn_wd56a_voodoo : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd56a_voodoo);
    bool handled=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({WD56A::Immunity,WD56A::Protection,WD56A::Lock}); }
    SpellCastResult Check()
    {
        Player* player=GetCaster()->ToPlayer();
        return IsDoctor(player) && player->IsAlive() && player->IsInWorld() &&
            player->GetLevel()>=40 && player->HasSpell(WD56A::Spell) && !player->HasAura(WD56A::Lock) ?
            SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index); if (handled) return; handled=true;
        Player* player=GetCaster()->ToPlayer(); if (!IsDoctor(player)) return;
        Position pos=player->GetPosition(); player->MovePositionToFirstCollision(pos,1.5f,0.0f);
        TempSummon* summon=player->SummonCreature(WD56A::Entry,pos,TEMPSUMMON_TIMED_DESPAWN,8100);
        if (!summon) { ChatHandler(player->GetSession()).SendSysMessage("大巫毒召唤失败，原召唤物已保留。"); return; }
        WD56A::Clear(player);
        player->CustomData.GetDefault<WD56A::State>(WD56A::Key)->guid=summon->GetGUID();
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd56a_voodoo::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd56a_voodoo::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd56a_voodoo : public CreatureScript
{
public:
    npc_reborn_wd56a_voodoo():CreatureScript("npc_reborn_wd56a_voodoo") { }
    struct AI : ScriptedAI
    {
        explicit AI(Creature* creature):ScriptedAI(creature) { }
        ObjectGuid owner;
        uint32 timer=1,remaining=8000;
        std::vector<ObjectGuid> affected;
        // Recipients may continue receiving THIS summon after their lock is set.
        // Another summon cannot start protecting them during that lock.
        std::vector<ObjectGuid> admitted;
        void Remove(ObjectGuid const& guid)
        {
            if (Unit* unit=ObjectAccessor::GetUnit(*me,guid))
            { unit->RemoveAurasDueToSpell(WD56A::Immunity,owner); unit->RemoveAurasDueToSpell(WD56A::Protection,owner); }
        }
        void Cleanup() { for (auto const& guid:affected) Remove(guid); affected.clear(); }
        void DoAction(int32 action) override { if (action==56) Cleanup(); }
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* player=summoner ? summoner->ToPlayer() : nullptr;
            if (!IsDoctor(player)) { me->DespawnOrUnsummon(); return; }
            owner=player->GetGUID(); me->SetOwnerGUID(owner); me->SetCreatorGUID(owner);
            me->SetFaction(player->GetFaction()); me->SetLevel(player->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(player->GetLevel())*10)); me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE); me->SetCombatMovement(false);
        }
        void AttackStart(Unit*) override { }
        void MoveInLineOfSight(Unit*) override { }
        void JustDied(Unit*) override { Cleanup(); me->DespawnOrUnsummon(); }
        void UpdateAI(uint32 diff) override
        {
            Player* player=ObjectAccessor::GetPlayer(*me,owner);
            if (!IsDoctor(player) || !player->IsAlive() || !player->IsInWorld() ||
                !player->IsInMap(me) || !player->InSamePhase(me) || !player->HasSpell(WD56A::Spell) ||
                player->CustomData.GetDefault<WD56A::State>(WD56A::Key)->guid!=me->GetGUID() || diff>=remaining)
            { Cleanup(); me->DespawnOrUnsummon(); return; }
            remaining-=diff;
            if (timer>diff) { timer-=diff; return; } timer=250;
            std::list<Unit*> units;
            Acore::AnyUnitInObjectRangeCheck check(me,15.0f);
            Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(me,units,check);
            Cell::VisitObjects(me,search,15.0f);
            std::vector<ObjectGuid> next;
            for (Unit* unit:units)
            {
                if (!WD56A::Eligible(player,me,unit)) continue;
                ObjectGuid guid=unit->GetGUID();
                bool accepted=std::find(admitted.begin(),admitted.end(),guid)!=admitted.end();
                if (!accepted && (unit->HasAura(WD56A::Lock) || unit->HasAura(WD56A::Immunity) || unit->HasAura(WD56A::Protection))) continue;
                uint32 auraId=unit==player ? WD56A::Immunity : WD56A::Protection;
                Aura* aura=unit->GetAura(auraId,owner);
                // AddAura uses the resolved Unit directly. No rewritten implicit
                // target caches or unimplemented effect143 can assert here.
                if (!aura) aura=player->AddAura(auraId,unit);
                if (!aura) continue;
                aura->SetDuration(std::min(600u,remaining));
                if (!accepted) admitted.push_back(guid);
                next.push_back(guid);
                if (Aura* lock=unit->GetAura(WD56A::Lock,owner)) lock->SetDuration(120000);
                else player->AddAura(WD56A::Lock,unit);
            }
            for (auto const& guid:affected) if (std::find(next.begin(),next.end(),guid)==next.end()) Remove(guid);
            affected=next;
        }
    };
    CreatureAI* GetAI(Creature* creature) const override { return new AI(creature); }
};
class player_reborn_wd56a_voodoo : public PlayerScript
{
public:
    player_reborn_wd56a_voodoo():PlayerScript("player_reborn_wd56a_voodoo") { }
    void OnPlayerLogout(Player* player) override { WD56A::Clear(player); }
    void OnPlayerMapChanged(Player* player) override { WD56A::Clear(player); }
};

// WD57A: native type-22 cauldron supplies existing WD35A consumables.
class spell_reborn_wd57a_cauldron : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd57a_cauldron);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003591,9003364}); }
    SpellCastResult CheckDoctor()
    {
        Player* player=GetCaster()->ToPlayer();
        return IsDoctor(player) && player->IsAlive() && player->HasSpell(9003590) &&
            player->GetLevel()>=60 ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd57a_cauldron::CheckDoctor);
    }
};
class go_reborn_wd57a_cauldron : public GameObjectScript
{
public:
    go_reborn_wd57a_cauldron() : GameObjectScript("go_reborn_wd57a_cauldron") { }
    bool OnGossipHello(Player* player, GameObject* go) override
    {
        // Native Use() adds a charge only after a successful, non-triggered cast.
        // Reject immediately at 25; its normal despawn runs on the next GO update.
        // Returning false delegates party/owner and inventory checks to the core.
        return !player->IsAlive() || go->GetUseCount()>=25 || go->getLootState()!=GO_READY;
    }
};

// WD58A: apply only after the owner's eligible direct spell deals damage.
class spell_reborn_wd58a_hollow : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd58a_hollow);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003600,9003601}); }
    void AfterDamage()
    {
        Player* player=GetCaster()->ToPlayer();
        Unit* target=GetHitUnit();
        if (!IsDoctor(player) || !player->IsAlive() || !WD5A::CanUseHollow(player) ||
            !player->HasSpell(9003600) || !player->HasAura(9003600) ||
            GetHitDamage()<=0 || !target || !target->IsAlive() ||
            !player->IsInMap(target) || !player->InSamePhase(target) ||
            !player->IsValidAttackTarget(target)) return;
        uint32 id=GetSpellInfo()->Id;
        bool eligible=WD48A::Fire(id);
        for (auto const& rank : WD19A::ShadowflareRanks)
            if (rank.spell==id) { eligible=true; break; }
        if (eligible) player->CastSpell(target,9003601,true);
    }
    void Register() override { AfterHit += SpellHitFn(spell_reborn_wd58a_hollow::AfterDamage); }
};

// WD59A: native spell modifiers scoped to exact local skill families.
namespace WD59A
{
    constexpr uint32 Style=9003610, Zalazane=9003611, Voodoo=9003612;
    uint32 FamilyBase(uint32 id)
    {
        if(id==9003822) return 9003100; // WD99 inherits Wrath threat modifiers.
        WD19A::Family const* family=WD19A::FindFamily(id);
        return family ? family->ranks[0].spell : 0;
    }
    bool Offensive(uint32 base)
    {
        return base==9003100 || base==9003103 || base==9003104 ||
            base==9003500 || base==9003560;
    }
    bool Jinx(uint32 id, uint32 base)
    {
        // Shrinking's linked spellpower component must expire with its parent.
        return id==WD88A::Jinx || base==9003150 || base==9003200 || base==9003210 || base==9003220 ||
            (id>=9003230 && id<=9003235);
    }
}
class reborn_wd59a_exact_mods : public GlobalScript
{
public:
    reborn_wd59a_exact_mods() : GlobalScript("reborn_wd59a_exact_mods") { }
    bool OnIsAffectedBySpellModCheck(SpellInfo const*, SpellInfo const* check,
        SpellModifier const* mod) override
    {
        if (!check || !mod) return true;
        uint32 base=WD59A::FamilyBase(check->Id);
        // This core interprets false as an exact positive match. Non-matches
        // are rejected by WD89A before the generic-family native fallback.
        if (mod->spellId==WD59A::Style && mod->op==SPELLMOD_THREAT)
            return !WD59A::Offensive(base);
        if (mod->spellId==WD59A::Zalazane)
        {
            if (mod->op==SPELLMOD_DOT) return base!=9003104;
            if (mod->op==SPELLMOD_DURATION) return !WD59A::Jinx(check->Id,base);
        }
        if (mod->spellId==WD59A::Voodoo && mod->op==SPELLMOD_DAMAGE)
            return base!=9003560;
        return true;
    }
};

// WD60A: exact local spell modifiers; native aura handlers own their lifecycle.
class reborn_wd60a_brewing_mods : public GlobalScript
{
public:
    reborn_wd60a_brewing_mods() : GlobalScript("reborn_wd60a_brewing_mods") { }
    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        // Upstream PR6192: keep pacify/silence; make the self buff cancellable.
        if(info && (info->Id==9003859 || info->Id==9003860)) info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE;
    }

    bool OnIsAffectedBySpellModCheck(SpellInfo const*, SpellInfo const* check,
                                   SpellModifier const* mod) override
    {
        if (!check || !mod)
            return true;
        if (mod->spellId==9003830 && mod->op==SPELLMOD_COST)
        {
            WD19A::Family const* family=WD19A::FindFamily(check->Id);
            return !family || (family->ranks[0].spell!=9003101 && family->ranks[0].spell!=9003240);
        }
        // Native flat/pct modifiers, exact target; no family-wide fallback.
        // WD121: use native done-healing modifiers after coefficients, not base-only edits.
        // WD128: coefficient-complete healing uses DAMAGE/DOT; utility/absorb use ALL_EFFECTS.
        if(mod->spellId==9003929)
            return !WD130A::Side(check->Id) || (mod->op!=SPELLMOD_CASTING_TIME && mod->op!=SPELLMOD_COST);
        if(mod->spellId==9003921)
            return mod->op!=SPELLMOD_CASTING_TIME || !WD19A::IsBrew(check->Id);
        if(mod->spellId==9003957)
            return !((check->Id==9003866 && mod->op==SPELLMOD_DAMAGE) ||
                     ((check->Id==9003867 || check->Id==9003889) && mod->op==SPELLMOD_DOT) ||
                     (((check->Id>=9003902 && check->Id<=9003908 && check->Id!=9003905) || (check->Id>=9003916 && check->Id<=9003918)) && mod->op==SPELLMOD_ALL_EFFECTS));
        if(mod->spellId==9003914)
            return !((check->Id==9003866 && mod->op==SPELLMOD_DAMAGE) ||
                     ((check->Id==9003867 || check->Id==9003889) && mod->op==SPELLMOD_DOT) ||
                     (((check->Id>=9003902 && check->Id<=9003908 && check->Id!=9003905) || (check->Id>=9003916 && check->Id<=9003918)) && mod->op==SPELLMOD_ALL_EFFECTS));
        if(mod->spellId==9003897)
            return !((check->Id>=9003870 && check->Id<=9003876 ||
                      check->Id>=9003890 && check->Id<=9003896) && mod->op==SPELLMOD_COOLDOWN);
        if(mod->spellId==9003880) return check->Id!=9003866 || mod->op!=SPELLMOD_DAMAGE;
        if(mod->spellId==9003881) return check->Id!=9003865 || mod->op!=SPELLMOD_ACTIVATION_TIME;
        if(mod->spellId==9003877 || mod->spellId==9003878)
            return check->Id!=9003866 || mod->op!=SPELLMOD_DAMAGE;
        if(mod->spellId==9003879)
            return !((check->Id>=9003870 && check->Id<=9003876 && mod->op==SPELLMOD_DAMAGE) ||
                     ((check->Id==9003867 || check->Id==9003889) && mod->op==SPELLMOD_DOT));
        if(mod->spellId==9003862) return check->Id!=9003861 || (mod->op!=SPELLMOD_COOLDOWN && mod->op!=SPELLMOD_CASTING_TIME);
        if(mod->spellId==9003863) return check->Id!=9003861 || mod->op!=SPELLMOD_CASTING_TIME;
        if(mod->spellId==9003857 || mod->spellId==9003858)
            return check->Id!=9003855 || (mod->op!=SPELLMOD_DURATION && mod->op!=SPELLMOD_EFFECT1);
        if(mod->spellId==9003854 && mod->op==SPELLMOD_THREAT) return false;
        // WD113: explicit positive matching; SpellInfo rejects all other targets.
        uint32 const base=WD59A::FamilyBase(check->Id);
        if(mod->spellId==9003850)
        {
            if(mod->op==SPELLMOD_COST)
                return !(base==9003140 || base==9003180 || base==9003190 ||
                         base==9003280 || base==9003290 || base==9003300);
            if(mod->op==SPELLMOD_ALL_EFFECTS)
                return !(base==9003180 || base==9003300);
            return true;
        }
        if(mod->spellId==9003851 && mod->op==SPELLMOD_EFFECT1)
            return check->Id!=9003240;
        if(mod->spellId==9003852 && mod->op==SPELLMOD_COST)
            return !(base==9003150 || base==9003200 || base==9003210 ||
                     base==9003220 || check->Id==WD88A::Jinx);
        // ThreatManager calls SPELLMOD_THREAT only for spell-generated threat.
        // Native melee swings have no SpellInfo and never enter this path.
        if ((mod->spellId == 9003620 || mod->spellId == 9003621) && mod->op == SPELLMOD_THREAT)
            return false;
        if ((mod->spellId == 9003624 || mod->spellId == 9003625) && mod->op == SPELLMOD_CASTING_TIME)
        {
            WD19A::Family const* family = WD19A::FindFamily(check->Id);
            return !family || family->ranks[0].spell != 9003101;
        }
        return true;
    }
};

// WD63A: summon-only native percentage modifiers, scoped to local families.
class reborn_wd63a_summon_mods : public GlobalScript
{
public:
    reborn_wd63a_summon_mods() : GlobalScript("reborn_wd63a_summon_mods") { }
    bool OnIsAffectedBySpellModCheck(SpellInfo const*, SpellInfo const* check,
                                   SpellModifier const* mod) override
    {
        if (!check || !mod)
            return true;
        if (!((mod->spellId == 9003652 && mod->op == SPELLMOD_COST) ||
              (mod->spellId == 9003653 && mod->op == SPELLMOD_COOLDOWN)))
            return true;
        WD19A::Family const* family = WD19A::FindFamily(check->Id);
        // false requests a positive match in this core's GlobalScript hook.
        // WD89A excludes unrelated targets before the native fallback.
        return check->Id!=WD68A::Mimic && (!family || WD53A::Slot(family->ranks[0].spell) < 0);
    }
};

// WD63D: read-only runtime evidence for the unresolved cooldown.
class reborn_wd63d_diagnostics : public CommandScript
{
public:
    reborn_wd63d_diagnostics() : CommandScript("reborn_wd63d_diagnostics") { }
    static bool Check(ChatHandler* h)
    {
        Player* p=h->GetSession()->GetPlayer();
        if (!p || p->getClass()!=13) return true;
        SpellInfo const* info=sSpellMgr->GetSpellInfo(9003370);
        if (!info) { h->SendSysMessage("WD63D missing Spirit Idol");return true; }
        for (uint32 id : {9003653u,9003652u})
        {
            AuraEffect* effect=p->GetAuraEffect(id,EFFECT_0);
            SpellModifier* mod=effect ? effect->GetSpellModifier() : nullptr;
            bool match=mod && p->IsAffectedBySpellmod(info,mod,nullptr);
            h->PSendSysMessage("WD63D spell={} learned={} aura={} op={} type={} value={} match={}",id,p->HasSpell(id)?1:0,effect?1:0,mod?int32(mod->op):-1,mod?int32(mod->type):-1,mod?mod->value:0,match?1:0);
        }
        WD19A::Family const* family=WD19A::FindFamily(info->Id);
        h->PSendSysMessage("WD63D idol base_ms={} category_ms={} server_remaining_ms={} family={} slot={}",info->RecoveryTime,info->CategoryRecoveryTime,p->GetSpellCooldownDelay(info->Id),family?family->ranks[0].spell:0,family?WD53A::Slot(family->ranks[0].spell):-1);
        return true;
    }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;
        static ChatCommandTable commands={{"wd63check",Check,SEC_PLAYER,Console::No}};
        return commands;
    }
};

// WD65A: native dispel count; preserves native eligibility/resist/charge handling.
class spell_reborn_wd65a_hexbreak : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd65a_hexbreak);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003661}); }
    void Count(SpellEffIndex)
    {
        if (IsDoctor(GetCaster()->ToPlayer()) && GetCaster()->HasAura(9003661))
            SetEffectValue(GetEffectValue()+1);
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd65a_hexbreak::Count,EFFECT_0,SPELL_EFFECT_DISPEL);
    }
};
// These amounts are read from the protecting caster, never the recipient.
class aura_reborn_wd65a_voodoo_self : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd65a_voodoo_self);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003662}); }
    void Amount(AuraEffect const*,int32& amount,bool& canBeRecalculated)
    {
        canBeRecalculated=false;
        if (GetCaster() && IsDoctor(GetCaster()->ToPlayer()) && GetCaster()->HasAura(9003662))
            amount+=25;
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd65a_voodoo_self::Amount,EFFECT_1,SPELL_AURA_MOD_DAMAGE_PERCENT_DONE);
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd65a_voodoo_self::Amount,EFFECT_2,SPELL_AURA_MOD_HEALING_DONE_PERCENT);
    }
};
class aura_reborn_wd65a_voodoo_party : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd65a_voodoo_party);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003662}); }
    void Amount(AuraEffect const*,int32& amount,bool& canBeRecalculated)
    {
        canBeRecalculated=false;
        if (GetCaster() && IsDoctor(GetCaster()->ToPlayer()) && GetCaster()->HasAura(9003662))
            amount-=5;
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd65a_voodoo_party::Amount,EFFECT_0,SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN);
    }
};

#include "RebornWitchDoctorDarkEffigy.inc"

#include "RebornWitchDoctorVoice.inc"

#include "RebornWitchDoctorGrasp.inc"

#include "RebornWitchDoctorEndVoodoo.inc"

#include "RebornWitchDoctorHexfire.inc"

// WD112: native energize percent / native flat aura scaling; no custom duplicate stat math.
class spell_reborn_wd112_brew : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd112_brew);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003841,9003842,9003843}); }
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p) || !p->HasSpell(GetSpellInfo()->Id) || p->GetLevel()<31) return SPELL_FAILED_CASTER_AURASTATE;
        Unit* target=GetExplTargetUnit();
        return target && target->IsAlive() && p->IsValidAssistTarget(target) ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }
    void Hit()
    {
        if(GetSpellInfo()->Id==9003841 && GetHitUnit())
            GetCaster()->CastSpell(GetHitUnit(),9003842,true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd112_brew::Check);
        AfterHit += SpellHitFn(spell_reborn_wd112_brew::Hit);
    }
};

// WD117 scales actual health, not the integer "2 percent" spell base point.

// WD118: native speed, transform, pacify/silence; helper follows the parent lifetime.
class aura_reborn_wd118_slither : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd118_slither);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003860}); }
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        Unit* unit=GetTarget();
        unit->RemoveMovementImpairingAuras(true);
        unit->AttackStop();
        unit->CastSpell(unit,9003860,true);
    }
    void Remove(AuraEffect const*,AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(9003860,GetCasterGUID());
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd118_slither::Apply,EFFECT_0,SPELL_AURA_MOD_INCREASE_SPEED,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd118_slither::Remove,EFFECT_0,SPELL_AURA_MOD_INCREASE_SPEED,AURA_EFFECT_HANDLE_REAL);
    }
};

class reborn_wd117_heal : public UnitScript
{
public:
    reborn_wd117_heal():UnitScript("reborn_wd117_heal") { }
    void ModifyHealReceived(Unit* a,Unit* b,uint32& heal,SpellInfo const* spell) override
    {
        if(!spell || spell->Id!=9003856 || !a || a!=b) return;
        heal=uint32(std::min<uint64>(std::numeric_limits<uint32>::max(),uint64(heal)*(100+WD117::Bonus(a))/100));
    }
};
namespace WD5A
{
void WD117ClearSwift(Player* p)
{
    Creature* idol=ObjectAccessor::GetCreature(*p,p->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid);
    if(idol && idol->GetEntry()==900202 && idol->GetOwnerGUID()==p->GetGUID()) WD36A::Clear(p);
}
}

#include "RebornWitchDoctorBrewingFoundation.inc"
#include "RebornWitchDoctorBrewing129.inc"
#include "RebornWitchDoctorBrewing133.inc"
#include "RebornWitchDoctorBrewing134.inc"
#include "RebornWitchDoctorBrewing137.inc"
#include "RebornWitchDoctorSpiritLink135.inc"
#include "RebornWitchDoctorBrewing132.inc"
#include "RebornWitchDoctorBrewing130.inc"
#include "RebornWitchDoctorBrewing131.inc"

// WD126: the donor spell's Dodge and Scale auras remain native 3.3.5a effects.
class spell_reborn_wd126_shrink_ally : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd126_shrink_ally);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        Unit* target=GetExplTargetUnit();
        return IsDoctor(p) && p->HasSpell(9003910) && target && target->IsAlive() &&
            p->IsValidAssistTarget(target) ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd126_shrink_ally::Check);
    }
};

void AddRebornWitchDoctorScripts()
{
    new reborn_wd117_heal();
    RegisterSpellScript(aura_reborn_wd118_slither);
    RegisterSpellScript(spell_reborn_wd112_brew);
    RegisterSpellScript(spell_reborn_wd68a_summon);
    WD87A::Register();
    new WD87B::StatusScript();
    new WD89A::Diagnostics();
    WD88A::Register();
    WD91A::Register();
    RegisterSpellScript(spell_reborn_wd120_brewing);
    RegisterSpellScript(aura_reborn_wd137_master);
    RegisterSpellScript(aura_reborn_wd129_thistle);
    new wd129_senjin_events();
    RegisterSpellScript(aura_reborn_wd130_beam);
    RegisterSpellScript(spell_reborn_wd130_beam);
    RegisterSpellScript(spell_reborn_wd130_heal);
    new wd130_events();
    RegisterSpellScript(spell_reborn_wd134_cauldron);
    RegisterSpellScript(spell_reborn_wd134_unstable);
    RegisterSpellScript(spell_reborn_wd134_heal);
    new npc_reborn_wd134_cauldron();
    RegisterSpellScript(spell_reborn_wd135_link);
    new npc_reborn_wd135_link();
    new player_reborn_wd134_lifecycle();
    RegisterSpellScript(spell_reborn_wd133_base);
    RegisterSpellScript(aura_reborn_wd133_base);
    RegisterSpellScript(aura_reborn_wd133_beast);
    new wd133_crystal_heal();
    RegisterSpellScript(spell_reborn_wd131_mojo);
    RegisterSpellScript(spell_reborn_wd126_shrink_ally);
    WD93A::Register();
    WD96A::Register();
    WD98A::Register();
    WD99A::Register();
    RegisterSpellScript(aura_reborn_wd68a_puppeteer);
    RegisterSpellScript(aura_reborn_wd68a_threads);
    RegisterSpellScript(spell_reborn_wd68a_puppet);
    RegisterSpellScript(aura_reborn_wd68a_puppet);
    new npc_reborn_wd68a_mimic();
    new WD70B::Lifecycle();
    RegisterSpellScript(spell_reborn_wd65a_hexbreak);
    RegisterSpellScript(aura_reborn_wd65a_voodoo_self);
    RegisterSpellScript(aura_reborn_wd65a_voodoo_party);
    new reborn_wd63d_diagnostics();
    new reborn_wd63a_summon_mods();
    new reborn_wd60a_brewing_mods();
    new reborn_wd59a_exact_mods();
    RegisterSpellScript(spell_reborn_wd58a_hollow);
    RegisterSpellScript(spell_reborn_wd57a_cauldron);
    new go_reborn_wd57a_cauldron();
    RegisterSpellScript(spell_reborn_wd56a_voodoo);
    new npc_reborn_wd56a_voodoo();
    new player_reborn_wd56a_voodoo();
    RegisterSpellScript(spell_reborn_wd55a_shadowflare);
    new WD53A::Selection();
    RegisterSpellScript(spell_reborn_wd53a_rite);
    RegisterSpellScript(spell_reborn_wd53a_recall);
    RegisterSpellScript(aura_reborn_wd51a_periodic);
    RegisterSpellScript(aura_reborn_wd51a_hex_cleanup);
    RegisterSpellScript(spell_reborn_wd50a_spread);
    RegisterSpellScript(aura_reborn_wd50a_hexplosion);
    new reborn_wd49a_exact_crit();
    RegisterSpellScript(spell_reborn_wd83a_ritual);
    RegisterSpellScript(spell_reborn_wd48a_attack);
    RegisterSpellScript(spell_reborn_wd47a_brew);
    RegisterSpellScript(spell_reborn_wd47a_heal);
    RegisterSpellScript(spell_reborn_wd46a_bottle);
    RegisterSpellScript(spell_reborn_wd46a_damage);
    RegisterSpellScript(spell_reborn_wd45a_stasis);
    new npc_reborn_wd45a_stasis();
    RegisterSpellScript(spell_reborn_wd45a_burst);
    RegisterSpellScript(spell_reborn_wd44a_cleanse);
    new npc_reborn_wd44a_cleanse();
    RegisterSpellScript(spell_reborn_wd44a_mass_allcure);
    new wd42a_effigy_events();
    RegisterSpellScript(spell_reborn_wd41a_effigy);
    new npc_reborn_wd41a_effigy();
    new player_reborn_wd41a_effigy();
    RegisterSpellScript(spell_reborn_wd40a_sentry);
    new npc_reborn_wd40a_sentry();
    RegisterSpellScript(spell_reborn_wd38a_idol);
    new npc_reborn_wd38a_idol();
    new WD36B::Commands();
    RegisterSpellScript(spell_reborn_wd36a_idol);
    new npc_reborn_wd36a_idol();
    new player_reborn_wd36a_idol_lifecycle();
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
    RegisterSpellScript(spell_reborn_wd34a_provisions);
    RegisterSpellScript(aura_reborn_wd20a_support);
    RegisterSpellScript(spell_reborn_wd3_birth);
    RegisterSpellScript(spell_reborn_wd9a_bad_juju);
    RegisterSpellScript(aura_reborn_wd85a_strings_tick);
    RegisterSpellScript(spell_reborn_wd85a_hexfire);
    RegisterSpellScript(spell_reborn_wd10a_hex);
    RegisterSpellScript(aura_reborn_wd10a_hex);
    new reborn_wd3_player();
    new npc_reborn_wd12_trainer();
}

namespace WD5A {
void WD67ClearSummons(Player* player,bool healing,bool cleansing)
{
    for(uint32 slot=0;slot<2;++slot)
    {
        Creature* summon=ObjectAccessor::GetCreature(*player,WD53A::Current(player,slot));
        if(!summon || summon->GetOwnerGUID()!=player->GetGUID()) continue;
        if((healing && slot==0 && summon->GetEntry()==900191) ||
           (cleansing && slot==1 && summon->GetEntry()==900203)) WD53A::Clear(player,slot);
    }
}
}
