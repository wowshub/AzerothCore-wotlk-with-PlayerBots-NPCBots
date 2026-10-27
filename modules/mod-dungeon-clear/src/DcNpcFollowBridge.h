// WDN6B: DC owns run state and PartyTank. Core NPC AI owns all movement.
#ifndef DC_NPC_FOLLOW_BRIDGE_H
#define DC_NPC_FOLLOW_BRIDGE_H
#include "Creature.h"
#include "Group.h"
#include "Player.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "bot_ai.h"
#include "Ai/Dungeon/DungeonClear/DcValueKeys.h"
#include "Ai/Dungeon/DungeonClear/Util/DcLeaderSignal.h"
#include "Ai/Dungeon/DungeonClear/Util/DcRun.h"
namespace DcNpcFollowBridge
{
inline Player* Resolve(Creature* npc)
{
    if (!npc || !npc->GetBotAI()) return nullptr;
    Player* owner=npc->GetBotAI()->GetBotOwner();
    if (!owner || !owner->IsInWorld() || !npc->IsInMap(owner)) return nullptr;
    Player* runOwner=DcLeaderSignal::FindRunOwner(owner);
    if (!runOwner || !runOwner->IsInWorld() || !npc->IsInMap(runOwner)) return nullptr;
    PlayerbotAI* ai=GET_PLAYERBOT_AI(runOwner);
    if (!ai) return nullptr;
    auto const& run=DcRun::Of(ai);
    if (!run.enabled || run.paused) return nullptr;
    // Never invent a second election, even when there is a human tank.
    return ai->GetAiObjectContext()->GetValue<Player*>(DcKey::PartyTank)->Get();
}
}
#endif
