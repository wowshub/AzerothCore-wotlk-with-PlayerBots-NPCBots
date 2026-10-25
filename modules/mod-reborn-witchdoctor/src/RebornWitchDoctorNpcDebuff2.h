// WDN2A: NPC-owned baseline debuffs; no recruiter talent inheritance.
#ifndef REBORN_WD_NPC_DEBUFF_2_H
#define REBORN_WD_NPC_DEBUFF_2_H
#include "RebornWitchDoctorNpcActor1.h"
namespace WDN2
{
constexpr uint32 Hex=9003104, Lethargy=9003150, Shrinking=9003220;
inline uint32 Base(uint32 id)
{
 for(auto const& r:WD19A::HexRanks)if(r.spell==id)return Hex;
 if(id==Lethargy)return Lethargy;
 for(auto const& r:WD19A::ShrinkingRanks)if(r.spell==id)return Shrinking;
 return 0;
}
inline bool Known(Unit* unit,uint32 id)
{
 auto* c=WDN1::Actor(unit);uint32 base=Base(id);
 if(!c||!base)return false;
 uint32 level=6;
 if(base==Hex)for(auto const& r:WD19A::HexRanks)if(r.spell==id)level=r.level;
 if(base==Shrinking)for(auto const& r:WD19A::ShrinkingRanks)if(r.spell==id)level=r.level;
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(base);
 return c->GetLevel()>=level&&it!=spells.end()&&it->second&&it->second->enabled&&it->second->spellId==id;
}
inline bool OwnHex(Unit* caster,Unit* target)
{
 if(!caster||!target)return false;
 for(auto const& r:WD19A::HexRanks)if(target->HasAura(r.spell,caster->GetGUID()))return true;
 return false;
}
inline bool JinxOccupied(Unit* target)
{
 if(!target)return false;
 // WD20AuraGroup(2), all casters. Never replace a teammate's Jinx.
 for(uint32 id:{9003150u,9003200u,9003210u,9003220u,9003221u,9003222u,
                9003223u,9003224u,9003225u,9003762u})if(target->HasAura(id))return true;
 return false;
}
inline bool Allowed(Unit* caster,Unit* target,uint32 id)
{
 auto* c=WDN1::Actor(caster);
 if(!c||!Known(c,id)||!WDN1::Safe(c,target)||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)||
    c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 return Base(id)==Hex?!OwnHex(c,target):!JinxOccupied(target);
}
}
#endif
