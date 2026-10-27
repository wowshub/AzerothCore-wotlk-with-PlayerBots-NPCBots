// WDN6A: read-only, per-call NPC roster. No stored pointers or movement orders.
#ifndef DC_NPC_PARTY_SNAPSHOT_H
#define DC_NPC_PARTY_SNAPSHOT_H
#include "Creature.h"
#include "Group.h"
#include "Player.h"
#include "bot_ai.h"
#include "botmgr.h"
#include <set>
#include <vector>
namespace DcNpcPartySnapshot
{
inline std::vector<Creature*> Collect(Player* anchor)
{
    std::vector<Creature*> out;
    if (!anchor || !anchor->IsInWorld()) return out;
    Group* group = anchor->GetGroup();
    std::set<ObjectGuid> seen;
    auto addOwner = [&](Player* owner)
    {
        // A dead/ghost owner may still own a living bot in this instance.
        if (!owner || !owner->HaveBot() || !owner->GetBotMgr()) return;
        for (auto const& item : *owner->GetBotMgr()->GetBotMap())
        {
            Creature* c = item.second;
            if (!c || !c->IsNPCBot() || !c->IsInWorld() ||
                !anchor->IsInMap(c) || !anchor->InSamePhase(c)) continue;
            bot_ai* ai = c->GetBotAI();
            if (!ai || ai->GetBotOwnerGuid() != owner->GetGUID().GetCounter()) continue;
            // Only party-enrolled bots, never dismissed or parked non-party followers.
            if (group && c->GetBotGroup() != group) continue;
            if (seen.insert(c->GetGUID()).second) out.push_back(c);
        }
    };
    addOwner(anchor);
    if (group)
        for (GroupReference* ref=group->GetFirstMember(); ref; ref=ref->next())
            if (ref->GetSource()!=anchor) addOwner(ref->GetSource());
    return out; // Dead entries deliberately retained; each consumer applies its policy.
}
inline bool Engaged(Creature* c)
{
    return c->IsAlive() && (c->GetVictim() || !c->getAttackers().empty());
}
}
#endif
