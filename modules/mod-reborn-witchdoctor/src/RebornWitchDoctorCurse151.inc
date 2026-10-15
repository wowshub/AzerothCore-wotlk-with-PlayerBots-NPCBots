// WD151: exact Jinx enhancement, dispel retaliation, Shadowflare->Hex, Strength.
namespace WD151
{
constexpr uint32 EnchantOne=9004090,EnchantTwo=9004091,Dark=9004092,Latent=9004093,Misery=9004094,Strength=9004095;
bool Owns(Player* p,uint32 id) { return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&p->HasAura(id,p->GetGUID()); }
class modifiers:public GlobalScript
{
public:modifiers():GlobalScript("reborn_wd151_modifiers"){}
 bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod)override
 {
  if(!check||!mod)return true;
  if(mod->spellId==Strength)return !(check->Id==9003574&&mod->op==SPELLMOD_ACTIVATION_TIME);
  if(mod->spellId==EnchantOne||mod->spellId==EnchantTwo)
   return !((WD59A::Jinx(check->Id,WD59A::FamilyBase(check->Id))||check->Id==9003211)&&(mod->op==SPELLMOD_ALL_EFFECTS||mod->op==SPELLMOD_DURATION));
  return true;
 }
};
class dark:public SpellScript
{
 PrepareSpellScript(dark);std::vector<ObjectGuid> previous;uint32 hits=0;
 void Hex(Player* p,ObjectGuid guid)
 {
  Unit* target=ObjectAccessor::GetUnit(*p,guid);if(!target||!target->IsAlive()||!p->IsValidAttackTarget(target)||!p->InSamePhase(target))return;
  uint32 id=0;for(auto const& rank:WD19A::HexRanks)if(p->HasSpell(rank.spell))id=rank.spell;
  if(id)p->CastSpell(target,id,true);
 }
 void Hit()
 {
  Player* p=GetCaster()->ToPlayer();Unit* u=GetHitUnit();
  if(!Owns(p,Dark)||!u||GetHitDamage()<=0||p->IsFriendlyTo(u))return;
  if(++hits<3) { previous.push_back(u->GetGUID());return; }
  if(hits==3)for(auto guid:previous)Hex(p,guid);
  Hex(p,u->GetGUID());
 }
 void Register()override { AfterHit+=SpellHitFn(dark::Hit); }
};
class latent:public AuraScript
{
 PrepareAuraScript(latent);
 void Dispelled(DispelInfo* info)
 {
  Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;Unit* u=info?info->GetDispeller():nullptr;
  if(Owns(p,Latent)&&u&&u->IsAlive()&&p->IsInMap(u)&&p->InSamePhase(u)&&p->IsValidAttackTarget(u))p->CastSpell(u,Misery,true);
 }
 void Register()override { AfterDispel+=AuraDispelFn(latent::Dispelled); }
};
class jinx_caps:public AuraScript
{
 PrepareAuraScript(jinx_caps);
 void Amount(AuraEffect const*,int32& amount,bool&)
 {
  Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
  if(Owns(p,EnchantOne)||Owns(p,EnchantTwo))amount=std::max(-100,amount);
 }
 void Register()override { DoEffectCalcAmount+=AuraEffectCalcAmountFn(jinx_caps::Amount,EFFECT_1,SPELL_AURA_MOD_POWER_REGEN_PERCENT); }
};
class misery:public AuraScript
{
 PrepareAuraScript(misery);
 void Amount(AuraEffect const*,int32& amount,bool& recalc)
 {
  Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;if(!IsDoctor(p))return;
  amount=int32(9.0*WD120A::Scaling(p->GetLevel())+.6f*std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));recalc=false;
 }
 void Register()override { DoEffectCalcAmount+=AuraEffectCalcAmountFn(misery::Amount,EFFECT_0,SPELL_AURA_PERIODIC_DAMAGE); }
};
void Register() { new modifiers();RegisterSpellScript(WD151::dark);RegisterSpellScript(WD151::latent);RegisterSpellScript(WD151::misery);RegisterSpellScript(WD151::jinx_caps); }
}
namespace WD151Bridge
{
void Apply(Player* p,uint32 enchant,bool dark,bool latent,bool strength)
{
 if(!IsDoctor(p))return;bool flags[]={enchant==1,enchant==2,dark,latent,strength};uint32 ids[]={9004090,9004091,9004092,9004093,9004095};
 for(uint32 i=0;i<5;++i)if(flags[i]) { if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true); }
 else { p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false); }
}
}
