// WD67A: narrow shared policy used by the trainer and the Witch Doctor module.
// Character database SELECT only; schema is installed by the WD67A package.
#pragma once
#include "Config.h"
#include "DatabaseEnv.h"
#include "Player.h"
namespace WD67
{
inline bool WD79BadJuju(uint32 spell) { return spell==9003103 || (spell>=9003491 && spell<=9003498); }
inline bool Managed(uint32 spell)
{
    return (spell>=9003730 && spell<=9003731) || (spell>=9003720 && spell<=9003721) || spell==9003511 || (spell>=9003710 && spell<=9003712) || (spell>=9003700 && spell<=9003703) || spell==9003520 || spell==9003521 || spell==9003530 || spell==9003600 || spell==9003612 || spell==9003690 || WD79BadJuju(spell) || spell==9003610 || spell==9003611 || (spell>=9003500 && spell<=9003507) || spell==9003170 || spell==9003632 || spell==9003641 ||
        spell==9003642 || spell==9003652 || spell==9003440 || spell==9003670 || spell==9003673 ||
        (spell>=9003680 && spell<=9003689);
}
// -1 is a database failure, not an unenrolled character. Callers fail closed.
inline int Enrollment(Player const* p)
{
    if (!p || p->getClass()!=13 || p->getRace()!=1 ||
        !sConfigMgr->GetOption<bool>("RebornWD67.Enable",false)) return 0;
    QueryResult q=CharacterDatabase.Query(
        "SELECT COALESCE((SELECT enabled FROM reborn_wd67_members WHERE guid={}),0)",p->GetGUID().GetCounter());
    if (!q) return -1;
    return q->Fetch()[0].Get<uint32>()==1 ? 1 : 0;
}
}
