// WD131: official 705851 / 500472 descriptions override stale donor ingredient trigger IDs.
class spell_reborn_wd131_mojo : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd131_mojo);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003933,9003934,9003935,9003936,9003940,9003941,9003901,9003865,9003905,9003915}); }
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        uint32 id=GetSpellInfo()->Id,first=id==9003940?9003901:9003865,partner=id==9003934?9003915:9003905;
        return IsDoctor(p) && p->HasSpell(GetSpellInfo()->Id) && p->HasSpell(first) && p->HasSpell(partner)
            ?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;
    }
    void Mix()
    {
        Player* p=GetCaster()->ToPlayer(); if(!IsDoctor(p)) return;
        uint32 id=GetSpellInfo()->Id,first=id==9003940?9003901:9003865,partner=id==9003934?9003915:9003905;
        auto* state=p->CustomData.GetDefault<WD128A::Ingredients>("Reborn.WD128.Ingredients");
        state->mixing=true;state->mojoPair=id;
        for(uint32 other:{9003933u,9003934u,9003940u}) if(other!=id) p->RemoveAurasDueToSpell(other);
        for(uint32 prep:{9003865u,9003901u,9003905u,9003915u}) p->RemoveAurasDueToSpell(prep,p->GetGUID());
        p->CastSpell(p,first,true);p->CastSpell(p,partner,true);
        state->order={first,partner};state->mixing=false;
        WD128A::Normalize(p);
        for(uint32 first:{9003870u,9003890u})
            for(uint32 rank=0;rank<7;++rank) if(p->GetSpellCooldownDelay(first+rank)) p->RemoveSpellCooldown(first+rank,true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd131_mojo::Check);
        AfterCast += SpellCastFn(spell_reborn_wd131_mojo::Mix);
    }
};
