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
    return spell==9003910 || spell==9003911 || spell==9003915 || spell==9003920 || (spell>=9003912 && spell<=9003914) || (spell>=9003901 && spell<=9003908) || (spell>=9003897 && spell<=9003900) || (spell>=9003890 && spell<=9003896) || (spell>=9003877 && spell<=9003881) || spell==9003864 || spell==9003865 || (spell>=9003870 && spell<=9003876) || spell==9003861 || spell==9003862 || spell==9003863 || spell==9003859 || spell==9003860 || spell==9003857 || spell==9003858 || spell==9003855 || spell==9003856 || spell==9003853 || spell==9003854 || spell==9003850 || spell==9003851 || spell==9003852 || spell==9003452 || spell==9003840 || spell==9003841 || spell==9003843 || spell==9003830 || spell==9003470 || spell==9003481 || spell==9003630 || spell==9003631 || spell==9003480 || (spell>=9003620 && spell<=9003625) || spell==9003660 || spell==9003432 || spell==9003640 || spell==9003820 || spell==9003822 || spell==9003800 || spell==9003801 || spell==9003810 || spell==9003650 || spell==9003651 || spell==9003633 || spell==9003653 || spell==9003790 || (spell>=9003780 && spell<=9003782) || spell==9003770 || spell==9003760 || spell==9003762 || spell==9003764 || (spell>=9003750 && spell<=9003754) || (spell>=9003740 && spell<=9003741) || (spell>=9003730 && spell<=9003731) || (spell>=9003720 && spell<=9003721) || spell==9003511 || (spell>=9003710 && spell<=9003712) || (spell>=9003700 && spell<=9003703) || spell==9003520 || spell==9003521 || spell==9003530 || spell==9003600 || spell==9003612 || spell==9003690 || WD79BadJuju(spell) || spell==9003610 || spell==9003611 || (spell>=9003500 && spell<=9003507) || spell==9003170 || spell==9003632 || spell==9003641 ||
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
