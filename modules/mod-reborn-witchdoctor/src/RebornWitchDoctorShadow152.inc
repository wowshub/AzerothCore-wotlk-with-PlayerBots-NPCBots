// WD152: Traditionalist + the authored mutually exclusive Eclipse talents.
namespace WD152
{
constexpr uint32 Traditionalist=9004096,Edge=9004097,Dambala=9004098,Ready=9004099;
bool Owns(Player* p,uint32 id) {return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&p->HasAura(id,p->GetGUID());}
uint32 TakeReady(Player* p)
{
 if(!Owns(p,Dambala)||!p->HasAura(Ready,p->GetGUID()))return 0;
 p->RemoveAurasDueToSpell(Ready,p->GetGUID());return 50;
}
class modifiers:public GlobalScript
{
public:modifiers():GlobalScript("reborn_wd152_modifiers"){}
 bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod)override
 {
  if(check&&mod&&mod->spellId==Edge)return !(check->Id==9004021&&mod->op==SPELLMOD_DAMAGE);
  return true;
 }
};
class traditionalist:public AuraScript
{
 PrepareAuraScript(traditionalist);bool executing=false;
 bool Check(ProcEventInfo& e)
 {
  Player* p=GetTarget()?GetTarget()->ToPlayer():nullptr;auto* info=e.GetSpellInfo();auto* damage=e.GetDamageInfo();
  return !executing&&Owns(p,Traditionalist)&&GetCasterGUID()==p->GetGUID()&&e.GetActor()==p&&e.GetActionTarget()&&
    p->IsValidAttackTarget(e.GetActionTarget())&&info&&info->Id>=9003104&&info->Id<=9003112&&
    (e.GetTypeMask()&PROC_FLAG_DONE_PERIODIC)&&damage&&damage->GetDamage()>0&&roll_chance_i(30);
 }
 void Proc(ProcEventInfo&)
 {
  PreventDefaultAction();Player* p=GetTarget()?GetTarget()->ToPlayer():nullptr;if(!Owns(p,Traditionalist)||executing)return;
  executing=true;p->CastSpell(p,9003574,true);executing=false;
 }
 void Register()override {DoCheckProc+=AuraCheckProcFn(traditionalist::Check);OnProc+=AuraProcFn(traditionalist::Proc);}
};
class eclipse:public SpellScript
{
 PrepareSpellScript(eclipse);
 void Cast(){Player* p=GetCaster()->ToPlayer();if(!GetSpell()->IsTriggered()&&Owns(p,Dambala))p->CastSpell(p,Ready,true);}
 void Register()override {AfterCast+=SpellCastFn(eclipse::Cast);}
};
void Register(){new modifiers();RegisterSpellScript(WD152::traditionalist);RegisterSpellScript(WD152::eclipse);}
}
namespace WD152Bridge
{
void Apply(Player* p,bool traditionalist,bool edge,bool dambala)
{
 if(!IsDoctor(p))return;bool flags[]={traditionalist,edge,dambala};uint32 ids[]={WD152::Traditionalist,WD152::Edge,WD152::Dambala};
 for(uint32 i=0;i<3;++i)if(flags[i]) {if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}
 else {p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}
 if(!dambala)p->RemoveAurasDueToSpell(WD152::Ready,p->GetGUID());
}
}
