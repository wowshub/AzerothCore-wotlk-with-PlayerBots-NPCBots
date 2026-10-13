// WD144: native cooldown/stat/target-aura handlers, exact private-ID scope.
namespace WD144
{
constexpr uint32 Arrow1=9003990,Arrow2=9003991,Strength1=9003992,Strength2=9003993,Decay=9003994,Serpent=9003995,Jinx=9003150;
struct State : DataMap::Base { std::unordered_set<ObjectGuid> targets; };
char const* const Key="RebornWD144.Targets";
bool Owns(Player* p,uint32 id) { return IsDoctor(p) && p->HasSpell(id) && p->HasAura(id,p->GetGUID()); }
// WD144C: visible markers only; actual 308/259 modifiers remain on Lethargy Jinx.
constexpr uint32 DecayMark=9003996,SerpentMark=9003997;
void RemoveMarks(Unit* target,ObjectGuid caster)
{
    target->RemoveAurasDueToSpell(DecayMark,caster);
    target->RemoveAurasDueToSpell(SerpentMark,caster);
}
void SyncMarks(Player* p,Unit* target,Aura* parent)
{
    if(!p || !target) return;
    for(uint32 id : {DecayMark,SerpentMark})
    {
        AuraEffect* effect=parent?parent->GetEffect(id==DecayMark?EFFECT_2:EFFECT_1):nullptr;
        bool wanted=effect && (id==DecayMark?effect->GetAmount()<0:effect->GetAmount()>0);
        if(!wanted) { target->RemoveAurasDueToSpell(id,p->GetGUID());continue; }
        Aura* mark=target->GetAura(id,p->GetGUID());
        if(!mark) mark=p->AddAura(id,target); // no damage/proc, no second resistance roll
        if(mark)
        {
            mark->SetMaxDuration(parent->GetMaxDuration());
            mark->SetDuration(parent->GetDuration());
        }
    }
}
class marker : public AuraScript
{
    PrepareAuraScript(marker);
    void Tick(AuraEffect const*)
    {
        // Resolve by parent + original caster GUID even if the caster is out of range.
        Aura* parent=GetTarget()->GetAura(Jinx,GetCasterGUID());
        AuraEffect* effect=parent?parent->GetEffect(GetId()==DecayMark?EFFECT_2:EFFECT_1):nullptr;
        bool active=effect && (GetId()==DecayMark?effect->GetAmount()<0:effect->GetAmount()>0);
        if(!active) { GetAura()->Remove();return; }
        // Parent refresh/PvP duration wins; markers must never extend gameplay effects.
        if(GetAura()->GetMaxDuration()!=parent->GetMaxDuration()) GetAura()->SetMaxDuration(parent->GetMaxDuration());
        int32 difference=GetAura()->GetDuration()-parent->GetDuration();
        if(difference>500 || difference< -500) GetAura()->SetDuration(parent->GetDuration());
    }
    void Register() override { OnEffectPeriodic += AuraEffectPeriodicFn(marker::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY); }
};
void Refresh(Player* p)
{
    if(!IsDoctor(p)) return;
    auto* state=p->CustomData.GetDefault<State>(Key);
    for(auto it=state->targets.begin();it!=state->targets.end();)
    {
        Unit* target=ObjectAccessor::GetUnit(*p,*it);
        Aura* aura=target?target->GetAura(Jinx,p->GetGUID()):nullptr;
        if(!aura) { it=state->targets.erase(it);continue; }
        if(AuraEffect* e=aura->GetEffect(EFFECT_1)) e->ChangeAmount(Owns(p,Serpent)?10:0);
        if(AuraEffect* e=aura->GetEffect(EFFECT_2)) e->ChangeAmount(Owns(p,Decay)?-30:0);
        SyncMarks(p,target,aura);
        ++it;
    }
}
class exact_mods : public GlobalScript
{
public:
    exact_mods():GlobalScript("reborn_wd144_exact_mods"){}
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod) override
    {
        if(!check||!mod) return true;
        if(mod->spellId==Arrow1||mod->spellId==Arrow2)
            return !(mod->op==SPELLMOD_COOLDOWN&&check->Id>=9003970&&check->Id<=9003978);
        if(mod->spellId==Decay) return !(mod->op==SPELLMOD_EFFECT3&&check->Id==Jinx);
        if(mod->spellId==Serpent) return !(mod->op==SPELLMOD_EFFECT2&&check->Id==Jinx);
        return true;
    }
};
class jinx : public AuraScript
{
    PrepareAuraScript(jinx);
    void Applied(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if(IsDoctor(p))
        {
            p->CustomData.GetDefault<State>(Key)->targets.insert(GetTarget()->GetGUID());
            SyncMarks(p,GetTarget(),GetAura());
        }
    }
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        RemoveMarks(GetTarget(),GetCasterGUID());
        if(IsDoctor(p)) p->CustomData.GetDefault<State>(Key)->targets.erase(GetTarget()->GetGUID());
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(jinx::Applied,EFFECT_1,SPELL_AURA_MOD_CRIT_CHANCE_FOR_CASTER,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(jinx::Removed,EFFECT_1,SPELL_AURA_MOD_CRIT_CHANCE_FOR_CASTER,AURA_EFFECT_HANDLE_REAL);
    }
};
class talent : public AuraScript
{
    PrepareAuraScript(talent);
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        // The removing aura is no longer active; clear only its caster's tracked effects.
        Player* p=GetTarget()->ToPlayer();if(!IsDoctor(p)) return;
        auto* state=p->CustomData.GetDefault<State>(Key);
        for(ObjectGuid guid:state->targets)
            if(Unit* target=ObjectAccessor::GetUnit(*p,guid))
            {
                if(AuraEffect* e=target->GetAuraEffect(Jinx,GetId()==Decay?EFFECT_2:EFFECT_1,p->GetGUID())) e->ChangeAmount(0);
                target->RemoveAurasDueToSpell(GetId()==Decay?DecayMark:SerpentMark,p->GetGUID());
            }
    }
    void Register() override { AfterEffectRemove += AuraEffectRemoveFn(talent::Removed,EFFECT_0,SPELL_AURA_ADD_FLAT_MODIFIER,AURA_EFFECT_HANDLE_REAL); }
};
}
namespace WD144Bridge
{
void Apply(Player* p,uint32 arrow,uint32 strength,bool decay,bool serpent)
{
    if(!IsDoctor(p)) return;
    bool wanted[]={arrow==1,arrow==2,strength==1,strength==2,decay,serpent};
    for(uint32 i=0;i<6;++i) if(!wanted[i])
    {
        p->RemoveAurasDueToSpell(9003990+i,p->GetGUID());
        if(p->HasSpell(9003990+i)) p->removeSpell(9003990+i,3,false);
    }
    for(uint32 i=0;i<6;++i) if(wanted[i])
    {
        if(!p->HasSpell(9003990+i)) p->learnSpell(9003990+i);
        if(!p->HasAura(9003990+i,p->GetGUID())) p->CastSpell(p,9003990+i,true);
    }
    WD144::Refresh(p);
}
}
