/*
 * mod-dungeon-clear — DcSelfBotStrategy.h  (RebornWOW DCSB1A)
 *
 * Combat-engine helpers for a self-botted player (Util/DcSelfBot.h), found in
 * the first in-game test (Utgarde Keep, Witch Doctor):
 *
 *   "dc selfbot regroup" — every self-bot. A real player stays in combat long
 *       after the bots (a far target picked by dps assist keeps the flag up), and
 *       the dungeon-clear follow-tank rung only runs out of combat, so the run sat
 *       "Waiting on <player> (out of range)" until the stuck-member teleport. When
 *       the self-bot is in combat but the run's tank is not, drop the fight and
 *       walk back to the tank.
 *
 *   "dc selfbot basic" — classes with no playerbots class AI (Witch Doctor and
 *       later CoA classes). dps assist only picks a target; nothing attacked it,
 *       so the character shot a few times (the client's own auto-repeat) and then
 *       stood still. Default to the ranged weapon, else melee, so fights finish.
 *
 * DCSB1C (second in-game test): the AI only leaves its combat engine through
 * "drop target", which class strategies get from CombatStrategy ("invalid
 * target" -> drop target). The basic strategy lacked it, so after the mob died
 * the self-bot sat in the combat engine forever, out of combat, bow drawn --
 * and regroup (which required IsInCombat) never fired either. Basic now derives
 * from CombatStrategy, and regroup fires on a held target as well.
 */

#ifndef MOD_DUNGEON_CLEAR_DC_SELF_BOT_STRATEGY_H
#define MOD_DUNGEON_CLEAR_DC_SELF_BOT_STRATEGY_H

#include "Action.h"
#include "Playerbots.h"
#include "Player.h"
#include "Strategy.h"
#include "CombatStrategy.h"
#include "Trigger.h"
#include "Ai/Dungeon/DungeonClear/DcValueKeys.h"

// Still fighting (in combat, swinging, or holding a target) while the run's tank
// is not: this fight is ours alone, the target is dead, or the flag is stale.
class DcSelfBotStrayTrigger : public Trigger
{
public:
    DcSelfBotStrayTrigger(PlayerbotAI* botAI) : Trigger(botAI, "dc selfbot stray", 1) {}

    bool IsActive() override
    {
        if (!bot || bot->isDead())
            return false;
        Player* tank = AI_VALUE(Player*, DcKey::PartyTank);
        if (!tank || tank == bot || !tank->IsAlive() || tank->IsInCombat())
            return false;
        bool const holding = bot->GetVictim() || AI_VALUE(Unit*, "current target");
        return holding || (bot->IsInCombat() && bot->GetExactDist(tank) > 10.0f);
    }
};

// Stop attacking (melee and auto-repeat shooting), forget the target and hand the
// AI back to its non-combat engine, where the dungeon-clear follow-tank rung runs.
class DcSelfBotDropFightAction : public Action
{
public:
    DcSelfBotDropFightAction(PlayerbotAI* botAI) : Action(botAI, "dc selfbot drop fight") {}

    bool Execute(Event /*event*/) override
    {
        bot->AttackStop();
        bot->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);
        bot->SetTarget(ObjectGuid::Empty);
        bot->SetSelection(ObjectGuid::Empty);
        context->GetValue<Unit*>("current target")->Set(nullptr);
        botAI->ChangeEngine(BOT_STATE_NON_COMBAT);
        return true;
    }
};

class DcSelfBotRegroupStrategy : public Strategy
{
public:
    DcSelfBotRegroupStrategy(PlayerbotAI* botAI) : Strategy(botAI) {}
    std::string const getName() override { return "dc selfbot regroup"; }

    void InitTriggers(std::vector<TriggerNode*>& triggers) override
    {
        // Below "avoid aoe" (90): dodging still wins over walking back.
        triggers.push_back(new TriggerNode("dc selfbot stray",
            { NextAction("dc selfbot drop fight", ACTION_MOVE + 9),
              NextAction("dungeon clear follow tank", ACTION_MOVE + 8) }));
    }
};

// CombatStrategy brings "enemy out of spell" -> reach spell (walk into bow range)
// and "invalid target" -> drop target (leave the combat engine when it dies).
class DcSelfBotBasicStrategy : public CombatStrategy
{
public:
    DcSelfBotBasicStrategy(PlayerbotAI* botAI) : CombatStrategy(botAI) {}
    std::string const getName() override { return "dc selfbot basic"; }

    // "shoot" is impossible without a ranged weapon (or out of range), then melee runs.
    std::vector<NextAction> getDefaultActions() override
    {
        return { NextAction("shoot", 5.1f), NextAction("melee", 5.0f) };
    }
};

#endif
