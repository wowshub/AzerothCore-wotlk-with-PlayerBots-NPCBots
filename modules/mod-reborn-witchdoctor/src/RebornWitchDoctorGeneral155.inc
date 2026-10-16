// WD155: Mojo Madness, One Armed Waltz and For Da Loa.
namespace WD155
{
constexpr uint32 Mojo=9004120,Waltz=9004121,Loa=9004122,Ready=9004123,Mass=9004124,Base=9003250,LegacyMass=9003442;
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&p->HasAura(id,p->GetGUID());}
bool Derived(SpellInfo const* info){return WD87A::Derived(info)||(info&&(info->Id==9003932||info->Id==9003961));}
void Replacement(Player* p){if(!IsDoctor(p)||!p->IsInWorld())return;
 if(Owns(p,Loa)&&p->HasSpell(Base)){uint32 target=p->HasSpell(LegacyMass)?LegacyMass:Mass;if(!p->HasSpell(target))p->learnSpell(target);p->SetTemporarySpellReplacement(Base,target);}
 else if(p->GetTemporarySpellReplacement(Base)==Mass||p->GetTemporarySpellReplacement(Base)==LegacyMass)p->SetTemporarySpellReplacement(Base,0);
}
class modifiers:public GlobalScript
{
public:modifiers():GlobalScript("reborn_wd155_modifiers"){}
bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod)override
{if(check&&mod&&mod->spellId==Waltz)return !((check->Id==9003581&&(mod->op==SPELLMOD_EFFECT2||mod->op==SPELLMOD_EFFECT3))||(check->Id==9003582&&mod->op==SPELLMOD_EFFECT1));return true;}
};
class mojo:public AuraScript
{
PrepareAuraScript(mojo);bool executing=false;
bool Check(ProcEventInfo& e){Player* p=GetTarget()->ToPlayer();return !executing&&Owns(p,Mojo)&&GetCasterGUID()==p->GetGUID()&&e.GetActor()==p&&e.GetActionTarget()&&!Derived(e.GetSpellInfo())&&((e.GetDamageInfo()&&e.GetDamageInfo()->GetDamage()>0)||(e.GetHealInfo()&&e.GetHealInfo()->GetEffectiveHeal()>0))&&roll_chance_i(5);}
void Proc(ProcEventInfo&){PreventDefaultAction();Player* p=GetTarget()->ToPlayer();if(executing||!Owns(p,Mojo))return;executing=true;p->CastSpell(p,Ready,true);executing=false;}
void Register()override{DoCheckProc+=AuraCheckProcFn(mojo::Check);OnProc+=AuraProcFn(mojo::Proc);}
};
class casts:public AllSpellScript
{
public:casts():AllSpellScript("reborn_wd155_casts",{ALLSPELLHOOK_CAN_PREPARE,ALLSPELLHOOK_ON_CAST,ALLSPELLHOOK_ON_CAST_CANCEL}){}
bool CanPrepare(Spell* spell,SpellCastTargets const*,AuraEffect const*)override{Player* p=spell->GetCaster()?spell->GetCaster()->ToPlayer():nullptr;spell->SetRebornWD155MojoSnapshot(!spell->IsTriggered()&&Owns(p,Mojo)&&p->HasAura(Ready,p->GetGUID()));return true;}
void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const*,bool)override{Player* p=caster?caster->ToPlayer():nullptr;if(spell->TakeRebornWD155MojoSnapshot()&&IsDoctor(p)&&!spell->IsTriggered())p->RemoveAurasDueToSpell(Ready,p->GetGUID());}
void OnSpellCastCancel(Spell* spell,Unit*,SpellInfo const*,bool)override{spell->TakeRebornWD155MojoSnapshot();}
};
class lifecycle:public PlayerScript
{
public:lifecycle():PlayerScript("reborn_wd155_lifecycle"){}
void OnPlayerUpdate(Player* p,uint32)override{if(!IsDoctor(p))return;if(!Owns(p,Mojo))p->RemoveAurasDueToSpell(Ready,p->GetGUID());Replacement(p);}
void OnPlayerLogout(Player* p)override{if(IsDoctor(p)){p->RemoveAurasDueToSpell(Ready,p->GetGUID());p->SetTemporarySpellReplacement(Base,0);}}
void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p)){p->RemoveAurasDueToSpell(Ready,p->GetGUID());Replacement(p);}}
};
class diagnostics:public CommandScript
{
public:diagnostics():CommandScript("reborn_wd155_diagnostics"){}
static bool Check(ChatHandler* h){Player* p=h->GetSession()->GetPlayer();if(!IsDoctor(p))return false;Aura* ready=p->GetAura(Ready,p->GetGUID());AuraEffect* d=p->GetAuraEffect(9003581,EFFECT_1,p->GetGUID());AuraEffect* heal=p->GetAuraEffect(9003581,EFFECT_2,p->GetGUID());
 h->PSendSysMessage("WD155 mojo={} ready_ms={} waltz={} self_damage_penalty={} self_healing_penalty={} loa={} original_learned={} legacy_mass_learned={} private_mass_learned={} replacement={} base_cd_ms={} mass_cd_ms={}",Owns(p,Mojo)?1:0,ready?ready->GetDuration():0,Owns(p,Waltz)?1:0,d?d->GetAmount():0,heal?heal->GetAmount():0,Owns(p,Loa)?1:0,p->HasSpell(Base)?1:0,p->HasSpell(LegacyMass)?1:0,p->HasSpell(Mass)?1:0,p->GetTemporarySpellReplacement(Base),p->GetSpellCooldownDelay(Base),std::max(p->GetSpellCooldownDelay(Mass),p->GetSpellCooldownDelay(LegacyMass)));
 if(Unit* u=p->GetSelectedUnit())if(AuraEffect* a=u->GetAuraEffect(9003582,EFFECT_0,p->GetGUID()))h->PSendSysMessage("WD155 target_owned_damage_taken_percent={}",a->GetAmount());return true;
}
Acore::ChatCommands::ChatCommandTable GetCommands()const override{using namespace Acore::ChatCommands;static ChatCommandTable commands={{"wd155check",Check,SEC_PLAYER,Console::No}};return commands;}
};
void Register(){new modifiers();new casts();new lifecycle();new diagnostics();RegisterSpellScript(WD155::mojo);}
}
namespace WD155Bridge
{
void Apply(Player* p,bool mojo,bool waltz,bool loa){if(!IsDoctor(p))return;bool flags[]={mojo,waltz,loa};uint32 ids[]={WD155::Mojo,WD155::Waltz,WD155::Loa};
 for(uint32 i=0;i<3;++i)if(!flags[i]){p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}
 for(uint32 i=0;i<3;++i)if(flags[i]){if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}
 if(!mojo)p->RemoveAurasDueToSpell(WD155::Ready,p->GetGUID());WD155::Replacement(p);if(!loa&&p->HasSpell(WD155::Mass))p->removeSpell(WD155::Mass,3,false);
}
}
