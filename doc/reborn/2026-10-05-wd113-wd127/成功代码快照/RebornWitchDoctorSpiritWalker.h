#ifndef REBORN_WD117_SPIRIT_WALKER_H
#define REBORN_WD117_SPIRIT_WALKER_H
#include "Player.h"
namespace WD117
{
inline uint32 Bonus(Unit const* unit)
{
    Player const* p=unit?unit->ToPlayer():nullptr;
    if(!p) return 0;
    if(p->HasSpell(9003858) && p->HasAura(9003858)) return 20;
    return p->HasSpell(9003857) && p->HasAura(9003857)?10:0;
}
inline uint32 Duration(Unit const* unit) { return 10000*(100+Bonus(unit))/100; }
inline int32 SwiftAmount(Unit const* unit) { return int32(25*(100+Bonus(unit))/100); }
}
#endif
