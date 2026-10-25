// WD120: CoA d7620151, isolated Brewing ingredient / Potion Toss closure.
#include "RebornWitchDoctorBrewingNumbers.h"
#include "Containers.h"
#include "RebornWitchDoctorNpcBrewing2.h"
class spell_reborn_wd120_brewing : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd120_brewing);
    bool _npcHit=false;
    bool _shrooms=false,_fish=false,_bones=false,_thistle=false,_concoctions=false;
    uint32 _mojo=0;
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({WD120A::Brewer,WD120A::Shrooms,WD120A::Pulse,WD120A::Hot,WD120A::SplashHot,WD125A::FishPrep,WD125A::FishField,WD125A::FishPotion,WD125A::FishSplash,WD125A::BonesPrep,WD125A::BonesField,WD125A::BonesPotion,WD125A::BonesSplash,9003915,9003917,9003918});
    }
    SpellCastResult Check()
    {
        if(Creature*c=GetCaster()->ToCreature())
        {
            uint32 id=GetSpellInfo()->Id;
            if(id==WDN2P::Pulse)return WDN2P::Prepared(c)?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;
            if(!WDN2P::Active(c)||!WDN2P::Known(c,id))return SPELL_FAILED_CASTER_AURASTATE;
            if(id==WDN2P::Prep)return SPELL_CAST_OK;
            if(WD120A::IsSplash(id))return WDN2P::Prepared(c)&&WDN2P::Destination(c,GetExplTargetDest())?SPELL_CAST_OK:SPELL_FAILED_BAD_TARGETS;
            return WDN2P::Prepared(c)&&WDN2P::Eligible(c,GetExplTargetUnit())?SPELL_CAST_OK:SPELL_FAILED_BAD_TARGETS;
        }
        if(GetSpellInfo()->Id==WD120A::Pulse) return SPELL_CAST_OK;
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p) || !p->HasSpell(GetSpellInfo()->Id)) return SPELL_FAILED_CASTER_AURASTATE;
        if((WD120A::IsToss(GetSpellInfo()->Id) || WD120A::IsSplash(GetSpellInfo()->Id)) && !p->HasAura(WD120A::Shrooms) && !p->HasAura(WD125A::FishPrep) && !p->HasAura(WD125A::BonesPrep) && !p->HasAura(9003915)) return SPELL_FAILED_CASTER_AURASTATE;
        return SPELL_CAST_OK;
    }
    void PulseTargets(std::list<WorldObject*>& targets)
    {
        if(Creature*c=GetCaster()->ToCreature())
        {
            targets.clear();
            if(WDN2P::Prepared(c))for(Unit*t:WDN2P::Targets(c))
            {targets.push_back(t);if(targets.size()==8)break;}
            return;
        }
        if(GetSpellInfo()->Id==WD120A::Pulse)
            Acore::Containers::RandomResize(targets,WD120A::PulseTargets(GetCaster()));
    }
    void SplashTargets(std::list<WorldObject*>&targets)
    {
        if(Creature*c=GetCaster()->ToCreature())
        {
            targets.clear();
            if(WDN2P::Prepared(c))for(Unit*t:WDN2P::SplashTargets(c,GetExplTargetDest()))targets.push_back(t);
        }
    }
    void Snapshot()
    {
        // Never pass a Creature through the player-only ingredient FIFO.
        if(Creature*c=GetCaster()->ToCreature())
        {_shrooms=WDN2P::Prepared(c);return;}
        // Per-cast state: a different preparation while the missile travels cannot change it.
        _shrooms=GetCaster()->HasAura(WD120A::Shrooms);
        _concoctions=GetCaster()->HasAura(9003954);
        _fish=GetCaster()->HasAura(WD125A::FishPrep);
        _bones=GetCaster()->HasAura(WD125A::BonesPrep);
        _thistle=GetCaster()->HasAura(9003915);
        uint32 id=GetSpellInfo()->Id;
        if(WD120A::IsToss(id) || WD120A::IsSplash(id))
        {
            // Consume at successful launch, once per cast; every hit uses this snapshot.
            if(GetCaster()->HasAura(9003933)) _mojo=9003935;
            else if(GetCaster()->HasAura(9003934)) _mojo=9003936;
            else if(GetCaster()->HasAura(9003940)) _mojo=9003941;
            GetCaster()->RemoveAurasDueToSpell(9003933);
            GetCaster()->RemoveAurasDueToSpell(9003934);
            GetCaster()->RemoveAurasDueToSpell(9003940);
        }
        if(WD125A::IsPrep(id)) WD128A::Normalize(GetCaster()->ToPlayer(),id);
    }
    void HealBase(SpellEffIndex)
    {
        if(GetSpellInfo()->Id!=WD120A::Pulse && !WD120A::IsToss(GetSpellInfo()->Id) && !WD120A::IsSplash(GetSpellInfo()->Id)) return;
        if(Creature*c=GetCaster()->ToCreature())
        {
            bool pulse=GetSpellInfo()->Id==WDN2P::Pulse;
            bool splash=WD120A::IsSplash(GetSpellInfo()->Id);
            Unit*t=GetExplTargetUnit();
            // Launch-target hooks have no hit target yet for area heals. Eligibility
            // is checked in target selection and again at hit below.
            if(!WDN2P::Prepared(c)||(!pulse&&(!WDN2P::Known(c,GetSpellInfo()->Id)||!(splash?WDN2P::Destination(c,GetExplTargetDest()):WDN2P::Eligible(c,t)))))
            {SetEffectValue(0);return;}
            SetEffectValue(WDN2P::Amount(c,GetEffectValue(),pulse,splash));return;
        }
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p)) return;
        bool pulse=GetSpellInfo()->Id==WD120A::Pulse;
        // The upstream scaling hook runs after level growth/dice, before done/taken modifiers.
        float base=float(GetEffectValue());
        if(pulse) base=float(int32(double(base)*WD120A::Scaling(p->GetLevel())));
        SetEffectValue(int32(base+(WD120A::IsSplash(GetSpellInfo()->Id)?WD120A::SplashBonus(p):WD120A::Bonus(p,pulse))));
    }
    void IngredientEffect()
    {
        if(Creature*c=GetCaster()->ToCreature())
        {
            if(_npcHit&&_shrooms&&(WD120A::IsToss(GetSpellInfo()->Id)||WD120A::IsSplash(GetSpellInfo()->Id))&&WDN2P::Known(c,GetSpellInfo()->Id)&&WDN2P::Eligible(c,GetHitUnit()))
                c->CastSpell(GetHitUnit(),WD120A::IsSplash(GetSpellInfo()->Id)?WDN2P::SplashHot:WDN2P::Hot,true);
            return;
        }
        Player* p=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        if(!IsDoctor(p) || (!WD120A::IsToss(GetSpellInfo()->Id) && !WD120A::IsSplash(GetSpellInfo()->Id)) || !target ||
           !target->IsAlive() || !p->IsFriendlyTo(target)) return;
        // Correct official 803698 healing route, not upstream 803273 Fish Oil.
        bool splash=WD120A::IsSplash(GetSpellInfo()->Id);
        if(_mojo) p->CastSpell(target,_mojo,true);
        if(_shrooms)
        {
            p->CastSpell(target,splash?WD120A::SplashHot:WD120A::Hot,true);
            if(_concoctions && p->HasSpell(9003954) && p->HasAura(9003954,p->GetGUID()))
                p->CastSpell(target,9003955,true);
        }
        if(_fish)
            p->CastSpell(target,splash?WD125A::FishSplash:WD125A::FishPotion,true);
        if(_thistle) p->CastSpell(target,splash?9003918u:9003917u,true);
        if(_bones)
        {
            // Donor formula: base + 35% Spirit + 80% bonus healing.
            float amount=(splash?25.0f:100.0f)+std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.35f
                +float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.80f;
            int32 shield=std::max(1,int32(amount));
            p->CastCustomSpell(target,splash?WD125A::BonesSplash:WD125A::BonesPotion,&shield,nullptr,nullptr,true);
        }
    }
    void NpcHit()
    {
        if(Creature*c=GetCaster()->ToCreature())
        {
            bool pulse=GetSpellInfo()->Id==WDN2P::Pulse;
            _npcHit=WDN2P::Eligible(c,GetHitUnit())&&(pulse?WDN2P::Prepared(c):(_shrooms&&WDN2P::Known(c,GetSpellInfo()->Id)));
            if(WD120A::IsSplash(GetSpellInfo()->Id))_npcHit=_npcHit&&WDN2P::SplashEligible(c,GetHitUnit(),GetExplTargetDest());
            if(!_npcHit)SetHitHeal(0); // Heal is calculated at launch; clear it before native hit settlement.
        }
    }
    void Register() override
    {
        // Pulse is a hidden triggered heal, not an independently learned player ability.
        if(m_scriptSpellId==WD120A::Pulse)
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::PulseTargets,EFFECT_0,TARGET_UNIT_CASTER_AREA_RAID);
        if(WD120A::IsSplash(m_scriptSpellId))
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::SplashTargets,EFFECT_0,TARGET_UNIT_DEST_AREA_ALLY);
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd120_brewing::Check);
        OnCast += SpellCastFn(spell_reborn_wd120_brewing::Snapshot);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd120_brewing::HealBase,EFFECT_0,SPELL_EFFECT_ANY);
        if(m_scriptSpellId==WDN2P::Pulse||WD120A::IsToss(m_scriptSpellId)||WD120A::IsSplash(m_scriptSpellId))
            OnHit += SpellHitFn(spell_reborn_wd120_brewing::NpcHit);
        AfterHit += SpellHitFn(spell_reborn_wd120_brewing::IngredientEffect);
    }
};

