// Native three-effect aura. Manual casts retain their original area and targeting rules.
#include "RebornWitchDoctorControl196.h"
class spell_reborn_wd196_control : public SpellScript
{
 PrepareSpellScript(spell_reborn_wd196_control);
 bool automatic=false,blocked=false;
 bool Validate(SpellInfo const* info) override
 {
  for(auto const& effect:info->Effects)
   if(effect.Effect!=SPELL_EFFECT_APPLY_AURA||effect.TargetA.GetTarget()!=TARGET_UNIT_DEST_AREA_ENEMY)return false;
  return true;
 }
 bool Load() override
 {
  automatic=WD168::IsAutomaticCast(GetCaster()->ToPlayer(),9003861);
  return true;
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
  OnObjectAreaTargetSelect+=SpellObjectAreaTargetSelectFn(spell_reborn_wd196_control::Filter,EFFECT_0,TARGET_UNIT_DEST_AREA_ENEMY);
  OnObjectAreaTargetSelect+=SpellObjectAreaTargetSelectFn(spell_reborn_wd196_control::Filter,EFFECT_1,TARGET_UNIT_DEST_AREA_ENEMY);
  OnObjectAreaTargetSelect+=SpellObjectAreaTargetSelectFn(spell_reborn_wd196_control::Filter,EFFECT_2,TARGET_UNIT_DEST_AREA_ENEMY);
  BeforeHit+=BeforeSpellHitFn(spell_reborn_wd196_control::Before);
  OnEffectHitTarget+=SpellEffectFn(spell_reborn_wd196_control::Effect,EFFECT_0,SPELL_EFFECT_APPLY_AURA);
  OnEffectHitTarget+=SpellEffectFn(spell_reborn_wd196_control::Effect,EFFECT_1,SPELL_EFFECT_APPLY_AURA);
  OnEffectHitTarget+=SpellEffectFn(spell_reborn_wd196_control::Effect,EFFECT_2,SPELL_EFFECT_APPLY_AURA);
 }
};
