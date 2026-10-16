// WD153: independently owned additional Mimic, Hex-proc wards and Arrow-derived poison.
namespace WD153
{
constexpr uint32 Mojo=9004100,Mass=9004101,Guile=9004102,Poison=9004103,MassSummon=9004104;
constexpr char Key[]="RebornWD153.ProcWards";
struct State:DataMap::Base {std::vector<ObjectGuid> wards,poisoned;std::chrono::steady_clock::time_point next{};};
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&p->HasAura(id,p->GetGUID());}
bool OwnedWard(Player* p,ObjectGuid guid){if(!Owns(p,Mass))return false;auto* s=p->CustomData.Get<State>(Key);return s&&std::find(s->wards.begin(),s->wards.end(),guid)!=s->wards.end();}
void Clear(Player* p){auto* s=p->CustomData.Get<State>(Key);if(!s)return;auto ids=s->wards;s->wards.clear();if(p->IsInWorld())for(auto id:ids)if(Creature* c=ObjectAccessor::GetCreature(*p,id))if(c->GetEntry()==900190&&c->GetOwnerGUID()==p->GetGUID())c->DespawnOrUnsummon();}
void ClearPoison(Player* p){auto* s=p->CustomData.Get<State>(Key);if(!s)return;auto ids=s->poisoned;s->poisoned.clear();if(p->IsInWorld())for(auto id:ids)if(Unit* u=ObjectAccessor::GetUnit(*p,id))u->RemoveAurasDueToSpell(Poison,p->GetGUID());}
void ClearMojo(Player* p){auto* s=p->CustomData.Get<WD68A::State>(WD68A::Key);if(!s)return;ObjectGuid id=s->mojo;s->mojo.Clear();if(p->IsInWorld())if(Creature* c=ObjectAccessor::GetCreature(*p,id))if(c->GetEntry()==WD68A::MimicEntry&&c->GetOwnerGUID()==p->GetGUID())c->DespawnOrUnsummon();}
class modifiers:public GlobalScript
{
public:modifiers():GlobalScript("reborn_wd153_modifiers"){}
bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod)override
{if(check&&mod&&mod->spellId==Mojo)return !(check->Id==WD68A::Mimic&&mod->op==SPELLMOD_DURATION);return true;}
};
class poison:public SpellScript
{
PrepareSpellScript(poison);
void Hit(){Player* p=GetCaster()->ToPlayer();Unit* u=GetHitUnit();if(!Owns(p,Guile)||!u||!u->IsAlive()||GetHitDamage()<=0||p->IsFriendlyTo(u))return;
 p->CastCustomSpell(Poison,SPELLVALUE_BASE_POINT0,PoisonTick(GetHitDamage()),u,true);
 auto* s=p->CustomData.GetDefault<State>(Key);s->poisoned.erase(std::remove_if(s->poisoned.begin(),s->poisoned.end(),[p](ObjectGuid id){Unit* t=ObjectAccessor::GetUnit(*p,id);return !t||!t->HasAura(Poison,p->GetGUID());}),s->poisoned.end());
 if(u->HasAura(Poison,p->GetGUID())&&std::find(s->poisoned.begin(),s->poisoned.end(),u->GetGUID())==s->poisoned.end())s->poisoned.push_back(u->GetGUID());}
void Register()override{AfterHit+=SpellHitFn(poison::Hit);}
};
class mass:public AuraScript
{
PrepareAuraScript(mass);bool executing=false;
bool Check(ProcEventInfo& e){Player* p=GetTarget()?GetTarget()->ToPlayer():nullptr;auto* info=e.GetSpellInfo();auto* d=e.GetDamageInfo();
return !executing&&Owns(p,Mass)&&GetCasterGUID()==p->GetGUID()&&e.GetActor()==p&&e.GetActionTarget()&&e.GetActionTarget()->IsAlive()&&
info&&info->Id>=9003104&&info->Id<=9003112&&(e.GetTypeMask()&PROC_FLAG_DONE_PERIODIC)&&d&&d->GetDamage()>0&&
std::chrono::steady_clock::now()>=p->CustomData.GetDefault<State>(Key)->next&&roll_chance_i(30);}
void Proc(ProcEventInfo& e){PreventDefaultAction();Player* p=GetTarget()?GetTarget()->ToPlayer():nullptr;if(!Owns(p,Mass)||executing)return;
executing=true;p->CustomData.GetDefault<State>(Key)->next=std::chrono::steady_clock::now()+std::chrono::seconds(3);p->CastSpell(e.GetActionTarget(),MassSummon,true);executing=false;}
void Register()override{DoCheckProc+=AuraCheckProcFn(mass::Check);OnProc+=AuraProcFn(mass::Proc);}
};
class summon:public SpellScript
{
PrepareSpellScript(summon);
void Hit(SpellEffIndex){Player* p=GetCaster()->ToPlayer();Unit* u=GetHitUnit();if(!Owns(p,Mass)||!u||!u->IsAlive()||!p->IsInMap(u)||!p->InSamePhase(u)||p->IsFriendlyTo(u))return;
auto* s=p->CustomData.GetDefault<State>(Key);s->wards.erase(std::remove_if(s->wards.begin(),s->wards.end(),[p](ObjectGuid id){return !ObjectAccessor::GetCreature(*p,id);}),s->wards.end());
int32 duration=10000;p->ApplySpellMod(9003160,SPELLMOD_DURATION,duration);
if(TempSummon* c=p->SummonCreature(900190,u->GetPosition(),TEMPSUMMON_TIMED_DESPAWN,std::max(1,duration))){s->wards.push_back(c->GetGUID());WD149::Gain(p);}}
void Register()override{OnEffectHitTarget+=SpellEffectFn(summon::Hit,EFFECT_0,SPELL_EFFECT_DUMMY);}
};
class lifecycle:public PlayerScript
{
public:lifecycle():PlayerScript("reborn_wd153_lifecycle"){}
void OnPlayerLogout(Player* p)override{if(IsDoctor(p)){Clear(p);ClearMojo(p);ClearPoison(p);}}
void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p)){Clear(p);ClearMojo(p);ClearPoison(p);}}
void OnPlayerUpdate(Player* p,uint32)override{if(IsDoctor(p)){if(!Owns(p,Mass))Clear(p);if(!Owns(p,Mojo))ClearMojo(p);if(!Owns(p,Guile))ClearPoison(p);}}
};
void Register(){new modifiers();new lifecycle();RegisterSpellScript(WD153::poison);RegisterSpellScript(WD153::mass);RegisterSpellScript(WD153::summon);}
}
namespace WD153Bridge
{
void Apply(Player* p,bool mojo,bool mass,bool guile){if(!IsDoctor(p))return;bool flags[]={mojo,mass,guile};uint32 ids[]={WD153::Mojo,WD153::Mass,WD153::Guile};
for(uint32 i=0;i<3;++i)if(flags[i]){if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}else{p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}
if(!mojo)WD153::ClearMojo(p);if(!mass)WD153::Clear(p);if(!guile)WD153::ClearPoison(p);}
}
