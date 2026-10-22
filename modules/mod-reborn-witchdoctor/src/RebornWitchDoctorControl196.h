// WD196B: automatic-only control eligibility; native spell effects remain authoritative.
#ifndef REBORN_WD_CONTROL_196_H
#define REBORN_WD_CONTROL_196_H
#include "RebornWitchDoctorBotState168.h"
#include "ObjectMgr.h"
#include "SpellMgr.h"
#include "Player.h"
namespace WD196
{
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
