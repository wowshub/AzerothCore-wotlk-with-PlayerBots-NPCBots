// WD196B: automatic-only control eligibility; native spell effects remain authoritative.
#ifndef REBORN_WD_CONTROL_196_H
#define REBORN_WD_CONTROL_196_H
#include "RebornWitchDoctorBotState168.h"
#include "ObjectMgr.h"
#include "SpellMgr.h"
#include "ObjectGuid.h"
#include "Player.h"
namespace WD196
{
// WD203: request lifetime is the native prepare call only, not player state.
inline thread_local Player* requestPlayer=nullptr;
inline thread_local ObjectGuid requestTarget,requestFocus;
class TargetScope
{
 Player* previous;ObjectGuid previousTarget,previousFocus;
public:
 TargetScope(Player* p,Unit* u,Unit* focus=nullptr):previous(requestPlayer),previousTarget(requestTarget),previousFocus(requestFocus)
 {requestPlayer=p;requestTarget=u?u->GetGUID():ObjectGuid::Empty;requestFocus=focus?focus->GetGUID():ObjectGuid::Empty;}
 ~TargetScope(){requestPlayer=previous;requestTarget=previousTarget;requestFocus=previousFocus;}
 TargetScope(TargetScope const&)=delete;TargetScope& operator=(TargetScope const&)=delete;
};
inline ObjectGuid RequestedTarget(Player* p){return requestPlayer==p?requestTarget:ObjectGuid::Empty;}
inline ObjectGuid RequestedFocus(Player* p){return requestPlayer==p?requestFocus:ObjectGuid::Empty;}
inline bool Bound()
{
 uint32 id=sObjectMgr->GetScriptId("spell_reborn_wd196_control");
 if(!id)return false;
 auto bounds=sObjectMgr->GetSpellScriptsBounds(9003861);
 for(auto it=bounds.first;it!=bounds.second;++it)if(it->second==id)return true;
 return false;
}
inline bool Safe(Player* p,Unit* u)
{
 if(!WD168::SafeAutomaticTarget(p,u)||u->GetTypeId()==TYPEID_PLAYER||
    !u->getAttackers().empty()||u->HasAuraType(SPELL_AURA_PERIODIC_DAMAGE)||
    u->HasAuraType(SPELL_AURA_PERIODIC_DAMAGE_PERCENT)||u->HasAuraType(SPELL_AURA_PERIODIC_LEECH))return false;
 // WD202: effect 0 is the actual transform; do not spend automatic control on
 // a target immune to that effect, even if the ancillary effects could land.
 auto* info=sSpellMgr->GetSpellInfo(9003861);
 return info&&!u->IsImmunedToSpell(info)&&!u->IsImmunedToSpellEffect(info,EFFECT_0,p);
}
}
#endif
