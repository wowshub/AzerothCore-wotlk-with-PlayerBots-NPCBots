// WD156: Eye of Kimbul, Serpent Handler, Frenzied Spirits.
namespace WD156
{
constexpr uint32 Eye=9004130,Handler=9004131,Frenzy=9004132,Mark=9004133,Buff=9004134,Heal=9004135;
constexpr char Key[]="RebornWD156.Targets";
struct State:DataMap::Base{std::vector<ObjectGuid> marked;};
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&(id==Frenzy||p->HasAura(id,p->GetGUID()));}
void Clear(Player* p){auto* s=p->CustomData.Get<State>(Key);if(!s)return;auto ids=s->marked;s->marked.clear();if(p->IsInWorld())for(auto id:ids)if(Unit* u=ObjectAccessor::GetUnit(*p,id))u->RemoveAurasDueToSpell(Mark,p->GetGUID());}
class modifiers:public GlobalScript{public:modifiers():GlobalScript("reborn_wd156_modifiers"){}
bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod)override{if(check&&mod&&mod->spellId==Handler)return !(check->Id==WD150::Call&&mod->op==SPELLMOD_COOLDOWN);return true;}};
class eye:public AuraScript{PrepareAuraScript(eye);bool executing=false;
bool Check(ProcEventInfo& e){Player* p=GetTarget()->ToPlayer();Unit* u=e.GetActionTarget();return !executing&&Owns(p,Eye)&&GetCasterGUID()==p->GetGUID()&&e.GetActor()==p&&u&&u->IsAlive()&&p->IsValidAttackTarget(u)&&e.GetDamageInfo()&&e.GetDamageInfo()->GetDamage()>0&&(e.GetHitMask()&PROC_HIT_CRITICAL)&&!WD155::Derived(e.GetSpellInfo());}
void Proc(ProcEventInfo& e){PreventDefaultAction();Player* p=GetTarget()->ToPlayer();Unit* u=e.GetActionTarget();if(executing||!Owns(p,Eye)||!u)return;executing=true;p->CastSpell(u,Mark,true);executing=false;
 auto* s=p->CustomData.GetDefault<State>(Key);s->marked.erase(std::remove_if(s->marked.begin(),s->marked.end(),[p](ObjectGuid id){Unit* t=ObjectAccessor::GetUnit(*p,id);return !t||!t->HasAura(Mark,p->GetGUID());}),s->marked.end());if(u->HasAura(Mark,p->GetGUID())&&std::find(s->marked.begin(),s->marked.end(),u->GetGUID())==s->marked.end())s->marked.push_back(u->GetGUID());}
void Register()override{DoCheckProc+=AuraCheckProcFn(eye::Check);OnProc+=AuraProcFn(eye::Proc);}};
class mark:public AuraScript{PrepareAuraScript(mark);
void Apply(AuraEffect const*,AuraEffectHandleModes){Unit* u=GetTarget();u->RemoveAurasByType(SPELL_AURA_MOD_STEALTH);u->RemoveAurasByType(SPELL_AURA_MOD_INVISIBILITY);}
void Register()override{AfterEffectApply+=AuraEffectApplyFn(mark::Apply,EFFECT_0,SPELL_AURA_MOD_DAMAGE_FROM_CASTER,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);}};
class stealth:public AllSpellScript{public:stealth():AllSpellScript("reborn_wd156_stealth",{ALLSPELLHOOK_ON_SPELL_CHECK_CAST}){}
void OnSpellCheckCast(Spell* s,bool,SpellCastResult& result)override{Unit* u=s->GetCaster();if(result==SPELL_CAST_OK&&u&&u->HasAura(Mark)&&(s->GetSpellInfo()->HasAura(SPELL_AURA_MOD_STEALTH)||s->GetSpellInfo()->HasAura(SPELL_AURA_MOD_INVISIBILITY)))result=SPELL_FAILED_CASTER_AURASTATE;}};
class frenzy:public SpellScript{PrepareSpellScript(frenzy);
SpellCastResult Check(){Player* p=GetCaster()->ToPlayer();if(!Owns(p,Frenzy))return SPELL_FAILED_CASTER_AURASTATE;if(!WD87A::Count(p)){ChatHandler(p->GetSession()).SendSysMessage("需要至少1层灵魂：先使用灵魂回收，或通过已学习的灵魂获取天赋积累灵魂。");return SPELL_FAILED_DONT_REPORT;}return SPELL_CAST_OK;}
void Hit(SpellEffIndex){Player* p=GetCaster()->ToPlayer();uint32 count=WD87A::Count(p);if(!Owns(p,Frenzy)||!count)return;
 p->CastCustomSpell(Buff,SPELLVALUE_BASE_POINT0,int32(10*count),p,true);if(Aura* a=p->GetAura(Buff,p->GetGUID())){if(AuraEffect* e=a->GetEffect(EFFECT_1))e->ChangeAmount(int32(5*count));if(AuraEffect* e=a->GetEffect(EFFECT_2))e->ChangeAmount(int32(2*count));a->SetMaxDuration(int32(4000*count));a->SetDuration(int32(4000*count));p->RemoveAurasDueToSpell(WD87A::Spirit,p->GetGUID());WD87A::Sync(p);}}
void Register()override{OnCheckCast+=SpellCheckCastFn(frenzy::Check);OnEffectHitTarget+=SpellEffectFn(frenzy::Hit,EFFECT_0,SPELL_EFFECT_DUMMY);}};
class buff:public AuraScript{PrepareAuraScript(buff);bool executing=false;
void Tick(AuraEffect const*){Player* p=GetTarget()->ToPlayer();if(Owns(p,Frenzy)&&GetCasterGUID()==p->GetGUID()){p->CastSpell(p,WD87A::Spirit,true);WD87A::Sync(p);}}
bool Check(ProcEventInfo& e){Player* p=GetTarget()->ToPlayer();return !executing&&Owns(p,Frenzy)&&GetCasterGUID()==p->GetGUID()&&e.GetActor()==p&&e.GetDamageInfo()&&e.GetDamageInfo()->GetDamage()>0&&!WD155::Derived(e.GetSpellInfo());}
void Proc(ProcEventInfo& e){PreventDefaultAction();Player* p=GetTarget()->ToPlayer();if(executing||!Owns(p,Frenzy))return;uint32 amount=uint32(uint64(e.GetDamageInfo()->GetDamage())*std::max(0,GetEffect(EFFECT_2)->GetAmount())/100);if(!amount)return;executing=true;p->CastCustomSpell(Heal,SPELLVALUE_BASE_POINT0,int32(std::min<uint32>(amount,INT32_MAX)),p,true);executing=false;}
void Register()override{OnEffectPeriodic+=AuraEffectPeriodicFn(buff::Tick,EFFECT_2,SPELL_AURA_PERIODIC_DUMMY);DoCheckProc+=AuraCheckProcFn(buff::Check);OnProc+=AuraProcFn(buff::Proc);}};
class lifecycle:public PlayerScript{public:lifecycle():PlayerScript("reborn_wd156_lifecycle"){}
void OnPlayerUpdate(Player* p,uint32)override{if(IsDoctor(p)){if(!Owns(p,Eye))Clear(p);if(!Owns(p,Frenzy))p->RemoveAurasDueToSpell(Buff,p->GetGUID());}}
void OnPlayerLogout(Player* p)override{if(IsDoctor(p)){Clear(p);p->RemoveAurasDueToSpell(Buff,p->GetGUID());}}
void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p)){Clear(p);p->RemoveAurasDueToSpell(Buff,p->GetGUID());}}};
class diagnostics:public CommandScript{public:diagnostics():CommandScript("reborn_wd156_diagnostics"){}
static bool Check(ChatHandler* h){Player* p=h->GetSession()->GetPlayer();if(!IsDoctor(p))return false;Aura* b=p->GetAura(Buff,p->GetGUID());int32 cd=40000;p->ApplySpellMod(WD150::Call,SPELLMOD_COOLDOWN,cd);h->PSendSysMessage("WD156 eye={} handler={} mass_count={} call_cd_ms={} call_remaining_ms={} spirits={} frenzy_ms={} rating={} crit_damage={} damage_heal_percent={}",Owns(p,Eye)?1:0,Owns(p,Handler)?1:0,Owns(p,Handler)?6:4,cd,p->GetSpellCooldownDelay(WD150::Call),WD87A::Count(p),b?b->GetDuration():0,b&&b->GetEffect(EFFECT_0)?b->GetEffect(EFFECT_0)->GetAmount():0,b&&b->GetEffect(EFFECT_1)?b->GetEffect(EFFECT_1)->GetAmount():0,b&&b->GetEffect(EFFECT_2)?b->GetEffect(EFFECT_2)->GetAmount():0);if(Unit* u=p->GetSelectedUnit())if(Aura* a=u->GetAura(Mark,p->GetGUID()))h->PSendSysMessage("WD156 own_mark stacks={} remaining_ms={} damage_percent={} crit_chance_points={}",a->GetStackAmount(),a->GetDuration(),a->GetEffect(EFFECT_0)->GetAmount(),a->GetEffect(EFFECT_1)->GetAmount());return true;}
Acore::ChatCommands::ChatCommandTable GetCommands()const override{using namespace Acore::ChatCommands;static ChatCommandTable t={{"wd156check",Check,SEC_PLAYER,Console::No}};return t;}};
void Register(){new modifiers();new stealth();new lifecycle();new diagnostics();RegisterSpellScript(WD156::eye);RegisterSpellScript(WD156::mark);RegisterSpellScript(WD156::frenzy);RegisterSpellScript(WD156::buff);}
}
namespace WD156Bridge{void Apply(Player* p,bool eye,bool handler,bool frenzy){if(!IsDoctor(p))return;bool flags[]={eye,handler,frenzy};uint32 ids[]={WD156::Eye,WD156::Handler,WD156::Frenzy};for(uint32 i=0;i<3;++i)if(flags[i]){if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(i<2&&!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}else{p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}if(!eye)WD156::Clear(p);if(!frenzy)p->RemoveAurasDueToSpell(WD156::Buff,p->GetGUID());}}
