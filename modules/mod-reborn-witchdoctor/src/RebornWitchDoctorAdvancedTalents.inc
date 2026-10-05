// WD88A: exact local spell families; no CoA global class-mask replacement.
namespace WD88A
{
constexpr uint32 Overflow=9003760, Ready=9003761, Jinx=9003762, Silence=9003763, Other=9003764, OtherBuff=9003765;
bool Juju(uint32 id)
{
    WD19A::Family const* f=WD19A::FindFamily(id);
    return f && f->ranks[0].spell==9003103;
}
bool Puppet(uint32 id)
{
    WD19A::Family const* f=WD19A::FindFamily(id);
    return f && f->ranks[0].spell==9003680;
}
class aura_wd88_talent : public AuraScript
{
    PrepareAuraScript(aura_wd88_talent);
    bool executing=false;
    bool Check(ProcEventInfo& e)
    {
        Player* p=GetTarget()->ToPlayer();
        SpellInfo const* info=e.GetSpellInfo();
        if (executing || !IsDoctor(p) || !p->IsAlive() || !p->HasSpell(GetId()) ||
            e.GetActor()!=p || !info || !e.GetDamageInfo() || !e.GetDamageInfo()->GetDamage()) return false;
        if (GetId()==Overflow) return (Puppet(info->Id) || info->Id==9003672) && roll_chance_i(15);
        return GetId()==Other && Puppet(info->Id);
    }
    void Proc(ProcEventInfo&)
    {
        PreventDefaultAction();
        Player* p=GetTarget()->ToPlayer();
        if (!IsDoctor(p) || executing) return;
        executing=true;
        if (GetId()==Overflow)
        {
            WD19A::Family const* f=WD19A::FindFamily(9003103);
            if (f) for (std::size_t i=0;i<f->count;++i) p->RemoveSpellCooldown(f->ranks[i].spell,true);
            p->CastSpell(p,Ready,true);
        }
        else
        {
            Aura* before=p->GetAura(OtherBuff,p->GetGUID());
            int32 remaining=before?before->GetDuration():0;
            bool existed=before!=nullptr;
            p->CastSpell(p,OtherBuff,true);
            // Never dereference the old aura after casting; it may have been replaced.
            if (existed) if (Aura* now=p->GetAura(OtherBuff,p->GetGUID())) now->SetDuration(remaining);
        }
        executing=false;
    }
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(GetId()==Overflow?Ready:OtherBuff,GetTarget()->GetGUID());
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wd88_talent::Check);
        OnProc += AuraProcFn(aura_wd88_talent::Proc);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wd88_talent::Removed,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};
class spell_wd88_juju : public SpellScript
{
    PrepareSpellScript(spell_wd88_juju);
    bool ready=false;
    void Before()
    {
        Player* p=GetCaster()->ToPlayer();
        ready=IsDoctor(p) && !GetSpell()->IsTriggered() && p->HasAura(Ready,p->GetGUID());
    }
    void After()
    {
        // Cooldown is already calculated at this hook. Misses consume; cancelled casts do not.
        if (ready)
        {
            Player* p=GetCaster()->ToPlayer();
            p->RemoveAurasDueToSpell(Ready,p->GetGUID());
            // Same proven post-SpellGo correction as WD63E; never alter server time twice.
            uint32 remaining=p->GetSpellCooldownDelay(GetSpellInfo()->Id);
            p->SendClearCooldown(GetSpellInfo()->Id,p);
            if (remaining)
            {
                WorldPacket packet;
                p->BuildCooldownPacket(packet,SPELL_COOLDOWN_FLAG_NONE,GetSpellInfo()->Id,remaining);
                p->SendDirectMessage(&packet);
            }
        }
    }
    void Register() override
    {
        BeforeCast += SpellCastFn(spell_wd88_juju::Before);
        AfterCast += SpellCastFn(spell_wd88_juju::After);
    }
};
class spell_wd88_jinx : public SpellScript
{
    PrepareSpellScript(spell_wd88_jinx);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return IsDoctor(p) && p->HasSpell(Jinx) && p->GetLevel()>=33 ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_wd88_jinx::Check); }
};
class casts : public AllSpellScript
{
public:
    casts():AllSpellScript("reborn_wd88_jinx_casts",{ALLSPELLHOOK_ON_CAST}) { }
    void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const*,bool) override
    {
        if (!caster || !spell || spell->IsTriggered()) return;
        std::vector<ObjectGuid> owners;
        for (auto const& entry:caster->GetAppliedAuras())
            if (entry.second->GetBase()->GetId()==Jinx) owners.push_back(entry.second->GetBase()->GetCasterGUID());
        for (ObjectGuid guid:owners)
        {
            caster->RemoveAurasDueToSpell(Jinx,guid);
            if (Unit* doctor=ObjectAccessor::GetUnit(*caster,guid)) doctor->CastSpell(caster,Silence,true);
        }
    }
};
class mods : public GlobalScript
{
public:
    mods():GlobalScript("reborn_wd88_overflow_mods") { }
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod) override
    {
        if (check && mod && mod->spellId==Ready && mod->op==SPELLMOD_COOLDOWN) return !Juju(check->Id);
        return true;
    }
};
void Register()
{
    RegisterSpellScript(aura_wd88_talent);
    RegisterSpellScript(spell_wd88_juju);
    RegisterSpellScript(spell_wd88_jinx);
    new casts();new mods();
}
}
