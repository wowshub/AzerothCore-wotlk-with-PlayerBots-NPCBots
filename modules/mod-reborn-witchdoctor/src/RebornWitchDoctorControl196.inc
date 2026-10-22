// Native three-effect aura. Manual casts retain their original area and targeting rules.
#include "RebornWitchDoctorControl196.h"
namespace WD203
{
inline bool Urgent(Player* p)
{
 if(p->GetHealthPct()<70.f)return true;
 std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(p,40.f);
 Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(p,units,check);Cell::VisitObjects(p,search,40.f);
 for(Unit* u:units)
 {
  if(!u||!u->IsAlive()||!p->IsInMap(u)||!p->InSamePhase(u)||!p->IsValidAssistTarget(u)||!p->IsWithinLOSInMap(u))continue;
  bool member=u==p||(u->GetTypeId()==TYPEID_PLAYER&&p->IsInRaidWith(u));
#ifdef MOD_NPCERBOTS
  if(u->IsNPCBot())member=p->GetGroup()&&u->ToCreature()->GetBotGroup()==p->GetGroup();
#endif
  if(member&&u->GetHealthPct()<45.f)return true;
 }
 return false;
}
}
class spell_reborn_wd196_control : public SpellScript
{
 PrepareSpellScript(spell_reborn_wd196_control);
 bool automatic=false,blocked=false,shortCast=false;ObjectGuid requested,focus;WD168::Plan plan;
 bool Validate(SpellInfo const* info) override
 {
  for(auto const& effect:info->Effects)
   if(effect.Effect!=SPELL_EFFECT_APPLY_AURA||effect.TargetA.GetTarget()!=TARGET_UNIT_DEST_AREA_ENEMY)return false;
  return true;
 }
 bool Load() override
 {
  Player* p=GetCaster()->ToPlayer();automatic=WD168::IsAutomaticCast(p,9003861);
  shortCast=automatic&&GetSpellInfo()->CalcCastTime(p)>0;
  requested=shortCast?WD196::RequestedTarget(p):ObjectGuid::Empty;
  focus=shortCast?WD196::RequestedFocus(p):ObjectGuid::Empty;
  if(shortCast)plan=WD168::ReadPlan(p);
  return true;
 }
 // Core invokes this before prepare and again before completion/costs for a cast.
 SpellCastResult Check()
 {
  if(!shortCast)return SPELL_CAST_OK;
  Player* p=GetCaster()->ToPlayer();if(!p||!p->HasSpell(9003861)||p->isMoving()||p->IsBeingTeleported())return SPELL_FAILED_CASTER_AURASTATE;
  auto now=WD168::ReadPlan(p);
  if(!plan.available||!now.available||now.slot!=plan.slot||now.spec!=plan.spec||now.revision!=plan.revision||WD203::Urgent(p))return SPELL_FAILED_CASTER_AURASTATE;
  Unit* u=requested.IsEmpty()?nullptr:ObjectAccessor::GetUnit(*p,requested);
  WorldLocation const* dest=GetExplTargetDest();float radius=GetSpellInfo()->Effects[EFFECT_0].CalcRadius(p);
  if(!dest||radius<=0.f||!WD196::Safe(p,u)||!u->IsNonMeleeSpellCast(false,false,true)||
     !u->IsWithinDist3d(dest->GetPositionX(),dest->GetPositionY(),dest->GetPositionZ(),radius))return SPELL_FAILED_BAD_TARGETS;
  Unit* primary=focus.IsEmpty()?nullptr:ObjectAccessor::GetUnit(*p,focus);
  if(!WD168::SafeAutomaticTarget(p,primary)||primary->IsWithinDist3d(dest->GetPositionX(),dest->GetPositionY(),dest->GetPositionZ(),radius+4.f))return SPELL_FAILED_BAD_TARGETS;
  return SPELL_CAST_OK;
 }
 void Filter(std::list<WorldObject*>& targets)
 {
  if(!automatic)return;
  Player* p=GetCaster()->ToPlayer();
  targets.remove_if([&](WorldObject* o){return !o||!WD196::Safe(p,o->ToUnit());});
 }
 void Before(SpellMissInfo)
 {
  // Cache before our transform exists: later effects must not reject our own CC.
  blocked=automatic&&!WD196::Safe(GetCaster()->ToPlayer(),GetHitUnit());
 }
 void Effect(SpellEffIndex index)
 {
  if(!blocked)return;
  // BeforeHit runs before Aura creation. Remove here, before _ApplyEffectForTargets.
  PreventHitAura();
  PreventHitDefaultEffect(index);
 }
 void Register() override
 {
  OnCheckCast+=SpellCheckCastFn(spell_reborn_wd196_control::Check);
  OnObjectAreaTargetSelect+=SpellObjectAreaTargetSelectFn(spell_reborn_wd196_control::Filter,EFFECT_0,TARGET_UNIT_DEST_AREA_ENEMY);
  OnObjectAreaTargetSelect+=SpellObjectAreaTargetSelectFn(spell_reborn_wd196_control::Filter,EFFECT_1,TARGET_UNIT_DEST_AREA_ENEMY);
  OnObjectAreaTargetSelect+=SpellObjectAreaTargetSelectFn(spell_reborn_wd196_control::Filter,EFFECT_2,TARGET_UNIT_DEST_AREA_ENEMY);
  BeforeHit+=BeforeSpellHitFn(spell_reborn_wd196_control::Before);
  OnEffectHitTarget+=SpellEffectFn(spell_reborn_wd196_control::Effect,EFFECT_0,SPELL_EFFECT_APPLY_AURA);
  OnEffectHitTarget+=SpellEffectFn(spell_reborn_wd196_control::Effect,EFFECT_1,SPELL_EFFECT_APPLY_AURA);
  OnEffectHitTarget+=SpellEffectFn(spell_reborn_wd196_control::Effect,EFFECT_2,SPELL_EFFECT_APPLY_AURA);
 }
};
