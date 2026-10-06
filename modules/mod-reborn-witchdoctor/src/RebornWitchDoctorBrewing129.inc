// WD129: Bloodthistle proc and Sen'jin charge source. Included after BrewingFoundation.
namespace WD129A
{
struct LeechClock : DataMap::Base
{
    std::chrono::steady_clock::time_point next{};
};
}
class aura_reborn_wd129_thistle : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd129_thistle);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003917,9003918,9003919}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner=GetTarget();Unit* enemy=event.GetActionTarget();
        if(!owner || !owner->IsAlive() || event.GetActor()!=owner || !enemy || enemy==owner ||
           owner->IsFriendlyTo(enemy) || !event.GetDamageInfo() || !event.GetDamageInfo()->GetDamage()) return false;
        if(event.GetSpellInfo() && event.GetSpellInfo()->Id==9003919) return false;
        // One recipient-wide 500ms clock covers Toss/Splash and multiple doctors.
        auto* state=owner->CustomData.GetDefault<WD129A::LeechClock>("Reborn.WD129.Leech");
        if(std::chrono::steady_clock::now()<state->next) return false;
        int32 amount=GetEffect(EFFECT_0)->GetAmount();
        for(AuraEffect const* effect:owner->GetAuraEffectsByType(SPELL_AURA_DUMMY))
            if((effect->GetId()==9003917 || effect->GetId()==9003918) && effect->GetAmount()>amount) return false;
        return amount>0;
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner=GetTarget();
        auto* state=owner->CustomData.GetDefault<WD129A::LeechClock>("Reborn.WD129.Leech");
        auto const now=std::chrono::steady_clock::now();
        if(now<state->next) return;
        int32 heal=int32(std::min<uint64>(INT32_MAX,uint64(event.GetDamageInfo()->GetDamage())*uint32(std::max(0,GetEffect(EFFECT_0)->GetAmount()))/100));
        if(!heal) return;
        state->next=now+std::chrono::milliseconds(500); // reserve before nested heal/proc calls
        Unit* source=GetCaster();
        if(!source || !source->IsInMap(owner)) source=owner;
        source->CastCustomSpell(owner,9003919,&heal,nullptr,nullptr,true);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_reborn_wd129_thistle::Check);
        OnProc += AuraProcFn(aura_reborn_wd129_thistle::Proc);
    }
};
class wd129_senjin_events : public AllSpellScript
{
public:
    wd129_senjin_events():AllSpellScript("wd129_senjin_events",{ALLSPELLHOOK_ON_CAST}) { }
    void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const* info,bool) override
    {
        Player* p=caster?caster->ToPlayer():nullptr;
        if(!spell || spell->IsTriggered() || !info || !IsDoctor(p) || !p->IsAlive() ||
           !p->HasSpell(9003920) || !p->HasAura(9003920,p->GetGUID())) return;
        if(!WD120A::IsToss(info->Id) && !(info->Id>=9003460 && info->Id<=9003467)) return;
        // Successful cast only; native charged spellmod consumes once per Brew and restores on cancel.
        p->CastSpell(p,9003921,true);
        if(Aura* buff=p->GetAura(9003921,p->GetGUID())) buff->SetCharges(2);
    }
};
