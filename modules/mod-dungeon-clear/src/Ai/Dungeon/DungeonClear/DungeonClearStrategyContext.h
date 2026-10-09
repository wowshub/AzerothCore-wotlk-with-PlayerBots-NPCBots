/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_DUNGEONCLEARSTRATEGYCONTEXT_H
#define _PLAYERBOT_DUNGEONCLEARSTRATEGYCONTEXT_H

#include "NamedObjectContext.h"
#include "Strategy.h"
#include "Ai/Dungeon/DungeonClear/Strategy/DungeonClearStrategy.h"
#include "Ai/Dungeon/DungeonClear/Strategy/DcSelfBotStrategy.h"

class DungeonClearStrategyContext : public NamedObjectContext<Strategy>
{
public:
    DungeonClearStrategyContext() : NamedObjectContext<Strategy>(false, false)
    {
        // Single consolidated strategy: chat keywords + driving ladder +
        // follow-tank. The former separate "dungeon clear chat" was folded in.
        creators["dungeon clear"] = &DungeonClearStrategyContext::dungeon_clear;
        // Combat-engine companion holding the advanced-pull maneuver trigger.
        creators["dungeon clear combat"] = &DungeonClearStrategyContext::dungeon_clear_combat;
        // Self-bot helpers (RebornWOW DCSB1A, see DcSelfBotStrategy.h).
        creators["dc selfbot regroup"] = &DungeonClearStrategyContext::selfbot_regroup;
        creators["dc selfbot basic"] = &DungeonClearStrategyContext::selfbot_basic;
    }

private:
    static Strategy* dungeon_clear(PlayerbotAI* ai) { return new DungeonClearStrategy(ai); }
    static Strategy* dungeon_clear_combat(PlayerbotAI* ai) { return new DungeonClearCombatStrategy(ai); }
    static Strategy* selfbot_regroup(PlayerbotAI* ai) { return new DcSelfBotRegroupStrategy(ai); }
    static Strategy* selfbot_basic(PlayerbotAI* ai) { return new DcSelfBotBasicStrategy(ai); }
};

#endif
