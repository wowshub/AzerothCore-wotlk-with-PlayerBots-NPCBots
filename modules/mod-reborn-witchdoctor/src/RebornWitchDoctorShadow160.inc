#include "RebornWitchDoctorFool200.h"
// WD160: Viper Ward + Fool's Play. Independent summon groups; latest-source deviations recorded.
namespace WD160
{
constexpr uint32 Talent=9004180,Fool=9004181,Ward=9004182,Blast=9004183,Presence=9004184,Clone=9004185,FoolPresence=9004186,ViperEntry=900255,FoolEntry=900256;
constexpr char Key[]="RebornWD160.Summons";
struct State:DataMap::Base{ObjectGuid viper,fool;uint32 attacks=0,blasts=0,copies=0;};
State* Data(Player* p){return p->CustomData.GetDefault<State>(Key);}
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&(id!=Talent||p->HasAura(Talent,p->GetGUID()));}
Creature* Viper(Player* p)
{
    if(!Owns(p,Talent)||!p->HasSpell(WD150::Call)||!p->HasSpell(Ward)||!p->IsInWorld())return nullptr;auto* s=p->CustomData.Get<State>(Key);if(!s)return nullptr;
    Creature* c=ObjectAccessor::GetCreature(*p,s->viper);return c&&c->GetEntry()==ViperEntry&&c->GetOwnerGUID()==p->GetGUID()&&c->IsAlive()&&p->IsInMap(c)&&p->InSamePhase(c)?c:nullptr;
}
bool OwnedViper(Player* p,ObjectGuid id){Creature* c=Viper(p);return c&&c->GetGUID()==id;}
void Clear(Player* p,bool viper)
{
    if(!viper)p->RemoveAurasDueToSpell(FoolPresence,p->GetGUID());
    auto* s=p->CustomData.Get<State>(Key);if(!s)return;ObjectGuid id=viper?s->viper:s->fool;if(viper)s->viper.Clear();else s->fool.Clear();
    if(p->IsInWorld())if(Creature* c=ObjectAccessor::GetCreature(*p,id))if(c->GetEntry()==(viper?ViperEntry:FoolEntry)&&c->GetOwnerGUID()==p->GetGUID())c->DespawnOrUnsummon();
    if(viper)p->RemoveAurasDueToSpell(Presence,p->GetGUID());
}
void Replacement(Player* p){if(!IsDoctor(p)||!p->IsInWorld())return;bool enabled=Owns(p,Talent)&&p->HasSpell(WD150::Call)&&p->HasActiveSpell(Ward);p->SetTemporarySpellReplacement(WD150::Call,enabled?Ward:0);}
float Chance(Player* p){return IsDoctor(p)?std::min(100.f,50.f+std::max(0.f,p->GetRatingBonusValue(CR_CRIT_RANGED))):0.f;}
void SyncPresence(Player* p)
{
    Creature* c=Viper(p);TempSummon* t=c?c->ToTempSummon():nullptr;uint32 ms=t?t->GetTimer():0;
    if(ms){Aura* a=p->GetAura(Presence,p->GetGUID());if(!a)a=p->AddAura(Presence,p);if(a){a->SetMaxDuration(int32(ms));a->SetDuration(int32(ms));}}
    else p->RemoveAurasDueToSpell(Presence,p->GetGUID());
}
// WD162B: owner-side duration indicator, never an extra combat benefit or cooldown.
Creature* FoolCopy(Player* p)
{
    if(!Owns(p,Fool)||!p->IsInWorld())return nullptr;auto* state=p->CustomData.Get<State>(Key);if(!state)return nullptr;
    Creature* c=ObjectAccessor::GetCreature(*p,state->fool);
    if(!c||c->GetEntry()!=FoolEntry||c->GetOwnerGUID()!=p->GetGUID()||!c->IsAlive()||!p->IsInMap(c)||!p->InSamePhase(c)||!c->IsAIEnabled)return nullptr;
    Unit* target=ObjectAccessor::GetUnit(*c,c->AI()->GetGUID(1));
    return target&&target->IsAlive()&&p->IsInMap(target)&&p->InSamePhase(target)&&p->IsValidAttackTarget(target)?c:nullptr;
}
void SyncFoolPresence(Player* p)
{
    Creature* c=FoolCopy(p);TempSummon* t=c?c->ToTempSummon():nullptr;uint32 ms=t?t->GetTimer():0;
    if(!ms){p->RemoveAurasDueToSpell(FoolPresence,p->GetGUID());return;}
    Aura* a=p->GetAura(FoolPresence,p->GetGUID());
    if(!a){a=p->AddAura(FoolPresence,p);if(a){a->SetMaxDuration(int32(ms));a->SetDuration(int32(ms));}}
    else if(std::abs(a->GetDuration()-int32(ms))>1000)a->SetDuration(int32(ms)); // native countdown; no reapply or packet churn every frame
}
// Only a source spell with native damage-only effects and no attached script can be replayed.
bool CanMirrorSpell(SpellInfo const* info)
{
    if(!info||info->IsPositive()||(!info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE)&&!info->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE)))return false;
    auto scripts=sObjectMgr->GetSpellScriptsBounds(info->Id);if(scripts.first!=scripts.second)return false;
    for(auto const& effect:info->Effects)if(effect.IsEffect()&&effect.Effect!=SPELL_EFFECT_SCHOOL_DAMAGE&&effect.Effect!=SPELL_EFFECT_WEAPON_PERCENT_DAMAGE&&effect.Effect!=SPELL_EFFECT_WEAPON_DAMAGE&&effect.Effect!=SPELL_EFFECT_NORMALIZED_WEAPON_DMG)return false;
    return true;
}
class summon:public SpellScript
{
    PrepareSpellScript(summon);bool made=false,automatic=false;
    bool Load()override{automatic=WD168::IsAutomaticCast(GetCaster()->ToPlayer(),GetSpellInfo()->Id);return true;}
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();bool viper=GetSpellInfo()->Id==Ward;
        if(!Owns(p,viper?Talent:Fool)||!p->HasSpell(GetSpellInfo()->Id))return SPELL_FAILED_CASTER_AURASTATE;
        if(!sObjectMgr->GetCreatureTemplate(viper?ViperEntry:FoolEntry))return SPELL_FAILED_ERROR;
        if(viper){if(!p->HasSpell(WD150::Call))return SPELL_FAILED_CASTER_AURASTATE;uint32 remaining=p->GetSpellCooldownDelay(WD150::Call);if(remaining)return SPELL_FAILED_NOT_READY;}
        else{Unit* u=GetExplTargetUnit();if(!u||!u->IsAlive()||!p->IsInMap(u)||!p->InSamePhase(u)||!p->IsValidAttackTarget(u)||!p->IsWithinLOSInMap(u))return SPELL_FAILED_BAD_TARGETS;}
        if(automatic&&!viper){Unit* u=GetExplTargetUnit();if(!u||u->IsPlayer()||!WD168::SafeAutomaticTarget(p,u))return SPELL_FAILED_BAD_TARGETS;if(FoolCopy(p))return SPELL_FAILED_NOT_READY;}
        return SPELL_CAST_OK;
    }
    void Hit(SpellEffIndex)
    {
        if(made)return;made=true;Player* p=GetCaster()->ToPlayer();bool viper=GetSpellInfo()->Id==Ward;Unit* target=GetExplTargetUnit();if(!Owns(p,viper?Talent:Fool))return;
        if(automatic&&!viper&&(!target||target->IsPlayer()||!WD168::SafeAutomaticTarget(p,target)))return;
        Position pos=p->GetPosition();if(viper){if(WorldLocation const* dest=GetExplTargetDest())pos=*dest;}else if(target)pos=target->GetNearPosition(1.f,0.f);else return;
        int32 duration=20000;if(viper)p->ApplySpellMod(9003160,SPELLMOD_DURATION,duration);
        TempSummon* c=p->SummonCreature(viper?ViperEntry:FoolEntry,pos,TEMPSUMMON_TIMED_DESPAWN,std::max(1,duration));
        if(!c){ChatHandler(p->GetSession()).SendNotification("召唤失败，原有召唤物已保留。");return;}
        Clear(p,viper);if(viper){Data(p)->viper=c->GetGUID();WD150::Clear(p);WD149::Gain(p);SyncPresence(p);}
        else{Data(p)->fool=c->GetGUID();c->AI()->SetData(WD200::AutomaticKey,automatic?1u:0u);c->AI()->SetGUID(target->GetGUID(),1);SyncFoolPresence(p);}
    }
    void SharedCooldown(){Player* p=GetCaster()->ToPlayer();if(GetSpellInfo()->Id==Ward&&!GetSpell()->IsTriggered()&&Owns(p,Talent)){uint32 remaining=p->GetSpellCooldownDelay(Ward),old=p->GetSpellCooldownDelay(WD150::Call);if(remaining>old)p->AddSpellCooldown(WD150::Call,0,GameTime::GetGameTime().count()+(remaining+999)/1000,true);}}
    void Register()override{OnCheckCast+=SpellCheckCastFn(summon::Check);OnEffectHit+=SpellEffectFn(summon::Hit,EFFECT_0,SPELL_EFFECT_DUMMY);AfterCast+=SpellCastFn(summon::SharedCooldown);}
};
class blast:public SpellScript
{
    PrepareSpellScript(blast);
    void Damage(SpellEffIndex)
    {
        Unit* original=GetOriginalCaster();Player* p=original?original->ToPlayer():nullptr;Creature* c=GetCaster()->ToCreature();if(!Owns(p,Talent)||!c||!OwnedViper(p,c->GetGUID())){SetEffectValue(0);return;}
        SetEffectValue(GetEffectValue()+int32(.15f*std::max(0.f,p->GetTotalAttackPowerValue(RANGED_ATTACK))));
    }
    void Register()override{OnEffectLaunchTarget+=SpellEffectFn(blast::Damage,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);}
};
class viper:public CreatureScript
{
public:viper():CreatureScript("npc_reborn_wd160_viper"){}
    struct AI:npc_reborn_wd21a_serpent::AI
    {
        explicit AI(Creature* c):npc_reborn_wd21a_serpent::AI(c){}
        void IsSummonedBy(WorldObject* summoner)override{npc_reborn_wd21a_serpent::AI::IsSummonedBy(summoner);timer=1000;me->m_ControlledByPlayer=true;me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);if(Player* p=summoner?summoner->ToPlayer():nullptr)me->SetByteValue(UNIT_FIELD_BYTES_2,1,p->GetByteValue(UNIT_FIELD_BYTES_2,1));}
        void UpdateAI(uint32 diff)override
        {
            Player* p=ObjectAccessor::GetPlayer(*me,owner);if(!Owns(p,Talent)||!p->IsInWorld()||!OwnedViper(p,me->GetGUID())){me->DespawnOrUnsummon();return;}
            me->SetByteValue(UNIT_FIELD_BYTES_2,1,p->GetByteValue(UNIT_FIELD_BYTES_2,1));float step=float(diff);
            if(p->HasSpell(9003532)&&p->HasAura(9003532,p->GetGUID()))if(AuraEffect* haste=me->GetAuraEffect(9003533,EFFECT_0,owner))step*=1.f+float(std::clamp(haste->GetAmount(),0,9))/100.f;
            if(timer>step){timer-=step;return;}timer=1000; // one shot per update; never catch-up burst
            Unit* target=Enemy(p);if(!target)return;ObjectGuid victim=target->GetGUID();++Data(p)->attacks;me->SetFacingToObject(target);me->CastSpell(target,WD21A::Attack,true,nullptr,nullptr,owner);WD150::Shot(me,victim);
            if(!OwnedViper(p,me->GetGUID())||!roll_chance_f(Chance(p)))return;
            if(Unit* u=ObjectAccessor::GetUnit(*me,victim))if(Valid(p,u)){++Data(p)->blasts;me->CastSpell(u,Blast,true,nullptr,nullptr,owner);}
        }
    };
    CreatureAI* GetAI(Creature* c)const override{return new AI(c);}
};
class fool:public CreatureScript
{
public:fool():CreatureScript("npc_reborn_wd160_fool"){}
    struct AI:ScriptedAI
    {
        ObjectGuid owner,target;bool automatic=false;explicit AI(Creature* c):ScriptedAI(c){}
        void IsSummonedBy(WorldObject* source)override{Player* p=source?source->ToPlayer():nullptr;if(!Owns(p,Fool)){me->DespawnOrUnsummon();return;}owner=p->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);me->SetFaction(p->GetFaction());me->m_ControlledByPlayer=true;me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);me->SetByteValue(UNIT_FIELD_BYTES_2,1,p->GetByteValue(UNIT_FIELD_BYTES_2,1));me->SetReactState(REACT_PASSIVE);}
        void SetData(uint32 key,uint32 value)override{if(key==WD200::AutomaticKey)automatic=value!=0;}
        uint32 GetData(uint32 key)const override{return key==WD200::AutomaticKey&&automatic?1u:0u;}
        void SetGUID(ObjectGuid const& id,int32 key)override
        {
            if(key!=1)return;target=id;Unit* u=ObjectAccessor::GetUnit(*me,target);if(!u||!u->IsAlive()){me->DespawnOrUnsummon();return;}
            if(automatic&&!WD168::SafeAutomaticTarget(ObjectAccessor::GetPlayer(*me,owner),u)){me->DespawnOrUnsummon();return;}
            me->SetDisplayId(u->GetDisplayId());me->SetObjectScale(u->GetObjectScale());me->SetLevel(u->GetLevel());
            me->SetMaxHealth(std::max<uint32>(1,u->GetMaxHealth()));me->SetHealth(std::max<uint32>(1,std::min<uint32>(u->GetHealth(),me->GetMaxHealth())));
            float lo=u->GetFloatValue(UNIT_FIELD_MINDAMAGE),hi=u->GetFloatValue(UNIT_FIELD_MAXDAMAGE);
            me->SetFloatValue(UNIT_FIELD_MINDAMAGE,lo);me->SetFloatValue(UNIT_FIELD_MAXDAMAGE,hi);
            me->SetBaseWeaponDamage(BASE_ATTACK,MINDAMAGE,lo);me->SetBaseWeaponDamage(BASE_ATTACK,MAXDAMAGE,hi);me->SetAttackTime(BASE_ATTACK,u->GetAttackTime(BASE_ATTACK));
            u->CastSpell(me,Clone,true);me->SetCombatMovement(true);me->SetReactState(REACT_AGGRESSIVE);AttackStart(u);if(me->GetVictim()==u)me->EngageWithTarget(u);
        }
        ObjectGuid GetGUID(int32 key)const override{return key==1?target:owner;}
        void MoveInLineOfSight(Unit*)override{}
        void JustDied(Unit*)override{me->DespawnOrUnsummon();}
        void UpdateAI(uint32)override
        {
            Player* p=ObjectAccessor::GetPlayer(*me,owner);Unit* u=ObjectAccessor::GetUnit(*me,target);
            if(!Owns(p,Fool)||!p->IsInWorld()||Data(p)->fool!=me->GetGUID()||me->GetOwnerGUID()!=owner||!p->IsInMap(me)||!p->InSamePhase(me)||!u||!u->IsAlive()||!p->IsValidAttackTarget(u)||!me->InSamePhase(u)){me->DespawnOrUnsummon();return;}
            if(automatic&&!WD168::SafeAutomaticTarget(p,u)){me->AttackStop();me->DespawnOrUnsummon();return;}
            me->SetByteValue(UNIT_FIELD_BYTES_2,1,p->GetByteValue(UNIT_FIELD_BYTES_2,1));if(me->GetVictim()!=u)AttackStart(u);if(UpdateVictim())DoMeleeAttackIfReady();
        }
    };
    CreatureAI* GetAI(Creature* c)const override{return new AI(c);}
};
class echoes:public AllSpellScript
{
public:echoes():AllSpellScript("reborn_wd160_enemy_echoes",{ALLSPELLHOOK_ON_CAST}){}
    void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const* info,bool)override
    {
        if(!spell||spell->IsTriggered()||!caster||!CanMirrorSpell(info))return;
        std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(caster,40.f);Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(caster,units,check);Cell::VisitObjects(caster,search,40.f);
        std::vector<ObjectGuid> copies;for(Unit* u:units)if(Creature* c=u->ToCreature())if(c->GetEntry()==FoolEntry&&c->IsAlive()&&c->IsAIEnabled&&c->AI()->GetGUID(1)==caster->GetGUID())copies.push_back(c->GetGUID());
        for(ObjectGuid id:copies)if(Creature* c=ObjectAccessor::GetCreature(*caster,id))
        {
            Player* p=ObjectAccessor::GetPlayer(*c,c->GetOwnerGUID());if(!Owns(p,Fool)||Data(p)->fool!=id||!p->IsValidAttackTarget(caster)||!c->InSamePhase(caster)||!c->IsWithinDistInMap(caster,40.f)||!c->IsWithinLOSInMap(caster))continue;
            bool automatic=c->AI()->GetData(WD200::AutomaticKey)!=0;
            if(automatic&&(!WD168::SafeAutomaticTarget(p,caster)||!WD200::AutomaticEcho(info)))continue;
            WD168::AutomaticCastScope scope(p,automatic?info->Id:0u);
            ++Data(p)->copies;c->CastSpell(caster,info->Id,true); // clone is the caster, never the enemy/player; triggered copies cannot recurse
        }
    }
};
class lifecycle:public PlayerScript
{
public:lifecycle():PlayerScript("reborn_wd160_lifecycle"){}
    static void Exit(Player* p){Clear(p,true);Clear(p,false);p->SetTemporarySpellReplacement(WD150::Call,0);}
    void OnPlayerUpdate(Player* p,uint32)override{if(!IsDoctor(p))return;if(!Owns(p,Talent)||!p->HasSpell(WD150::Call))Clear(p,true);if(!Owns(p,Fool))Clear(p,false);Replacement(p);SyncPresence(p);SyncFoolPresence(p);}
    void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p))Exit(p);}
    void OnPlayerLogout(Player* p)override{if(IsDoctor(p))Exit(p);}
};
class diagnostics:public CommandScript
{
public:diagnostics():CommandScript("reborn_wd160_diagnostics"){}
    static bool Check(ChatHandler* h){Player* p=h->GetSession()->GetPlayer();if(!IsDoctor(p))return false;State* s=Data(p);Creature* v=Viper(p);Creature* f=ObjectAccessor::GetCreature(*p,s->fool);h->PSendSysMessage("WD160 viper_talent={} call_replacement={} viper_alive={} viper_remaining_ms={} blast_chance_percent={} attacks={} blasts={} fool_learned={} fool_alive={} copies={} ward_cd_ms={} call_cd_ms={} fool_cd_ms={}",Owns(p,Talent)?1:0,p->GetTemporarySpellReplacement(WD150::Call),v?1:0,v&&v->ToTempSummon()?v->ToTempSummon()->GetTimer():0,Chance(p),s->attacks,s->blasts,Owns(p,Fool)?1:0,f&&f->IsAlive()?1:0,s->copies,p->GetSpellCooldownDelay(Ward),p->GetSpellCooldownDelay(WD150::Call),p->GetSpellCooldownDelay(Fool));if(f)h->PSendSysMessage("WD160 clone_health={} clone_max_health={} clone_min_damage={} clone_max_damage={} clone_attack_ms={}",f->GetHealth(),f->GetMaxHealth(),f->GetWeaponDamageRange(BASE_ATTACK,MINDAMAGE),f->GetWeaponDamageRange(BASE_ATTACK,MAXDAMAGE),f->GetAttackTime(BASE_ATTACK));return true;}
    Acore::ChatCommands::ChatCommandTable GetCommands()const override{using namespace Acore::ChatCommands;static ChatCommandTable t={{"wd160check",Check,SEC_PLAYER,Console::No}};return t;}
};
void Register(){new viper();new fool();new echoes();new lifecycle();new diagnostics();RegisterSpellScript(WD160::summon);RegisterSpellScript(WD160::blast);}
}
namespace WD160Bridge
{
void Apply(Player* p,bool viper,bool fool)
{
    if(!IsDoctor(p))return;if(viper){if(!p->HasSpell(WD160::Talent))p->learnSpell(WD160::Talent);if(!p->HasAura(WD160::Talent,p->GetGUID()))p->CastSpell(p,WD160::Talent,true);if(p->HasSpell(WD150::Call)){if(!p->HasSpell(WD160::Ward))p->learnSpell(WD160::Ward,true);}else{WD160::Clear(p,true);if(p->HasSpell(WD160::Ward))p->removeSpell(WD160::Ward,3,false);}WD150::Clear(p);}else{p->RemoveAurasDueToSpell(WD160::Talent,p->GetGUID());WD160::Replacement(p);WD160::Clear(p,true);if(p->HasSpell(WD160::Ward))p->removeSpell(WD160::Ward,3,false);if(p->HasSpell(WD160::Talent))p->removeSpell(WD160::Talent,3,false);}
    if(fool){if(!p->HasSpell(WD160::Fool))p->learnSpell(WD160::Fool);}else{WD160::Clear(p,false);if(p->HasSpell(WD160::Fool))p->removeSpell(WD160::Fool,3,false);}WD160::Replacement(p);
}
}
