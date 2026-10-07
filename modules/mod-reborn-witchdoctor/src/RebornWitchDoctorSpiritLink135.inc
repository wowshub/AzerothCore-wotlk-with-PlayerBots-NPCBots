// WD135: Spirit Link redistributes health; it is not a healing or damage proc.
#include "RebornWitchDoctorLinkBalance.h"
namespace WD135
{
constexpr uint32 SpellId=9003953,Entry=900232;
bool Eligible(Player* p,Creature* idol,Unit* u)
{
    // Upstream and official description are player party/raid members, not pets/NPC bots.
    return u && u->IsPlayer() && u->GetMaxHealth() && WD134::Ally(p,idol,u,10.0f);
}
}
class spell_reborn_wd135_link : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd135_link);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p) || !p->IsAlive() || !p->IsInWorld() || p->GetLevel()<50 || !p->HasSpell(WD135::SpellId)) return SPELL_FAILED_CASTER_AURASTATE;
        return sObjectMgr->GetCreatureTemplate(WD135::Entry)?SPELL_CAST_OK:SPELL_FAILED_ERROR;
    }
    void Place(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* p=GetCaster()->ToPlayer();if(!IsDoctor(p)) return;
        Position pos=p->GetPosition();p->MovePositionToFirstCollision(pos,1.5f,WD53A::Angle(p));
        if(TempSummon* idol=p->SummonCreature(WD135::Entry,pos,TEMPSUMMON_MANUAL_DESPAWN,0))
        {
            WD36A::Clear(p);
            p->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid=idol->GetGUID();
            WD53A::Track(p,GetSpell(),idol->GetGUID());
        }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd135_link::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd135_link::Place,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd135_link : public CreatureScript
{
public:
    npc_reborn_wd135_link():CreatureScript("npc_reborn_wd135_link"){}
    struct AI : ScriptedAI
    {
        explicit AI(Creature* c):ScriptedAI(c){}
        ObjectGuid owner;uint32 remaining=14000,timer=2000;
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* p=summoner?summoner->ToPlayer():nullptr;
            if(!IsDoctor(p)){me->DespawnOrUnsummon();return;}
            owner=p->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);me->SetFaction(p->GetFaction());me->SetLevel(p->GetLevel());
            me->SetMaxHealth(std::max(5u,uint32(p->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);me->setActive(true);
        }
        void AttackStart(Unit*) override{}
        void MoveInLineOfSight(Unit*) override{}
        void JustDied(Unit*) override {me->DespawnOrUnsummon();}
        void UpdateAI(uint32 diff) override
        {
            Player* p=ObjectAccessor::GetPlayer(*me,owner);
            if(!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(WD135::SpellId) || !p->IsInMap(me) || !p->InSamePhase(me) ||
               p->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid!=me->GetGUID()) {me->DespawnOrUnsummon();return;}
            uint32 step=std::min(diff,remaining);remaining-=step;
            if(timer<=step)
            {
                timer=2000-std::min(step-timer,1999u); // no catch-up burst after a stalled update
                auto recipients=WD134::Allies(p,me,10.0f);
                std::sort(recipients.begin(),recipients.end());
                std::vector<Player*> players;std::vector<WD135::Health> input;
                for(ObjectGuid guid:recipients) if(Unit* u=ObjectAccessor::GetUnit(*me,guid))
                    if(WD135::Eligible(p,me,u)) {players.push_back(u->ToPlayer());input.push_back({u->GetHealth(),u->GetMaxHealth()});}
                if(players.size()>1)
                {
                    auto result=WD135::Balance(input);
                    for(size_t i=0;i<players.size();++i) players[i]->SetHealth(result[i]);
                }
            }
            else timer-=step;
            if(!remaining) me->DespawnOrUnsummon();
        }
    };
    CreatureAI* GetAI(Creature* c) const override{return new AI(c);}
};
