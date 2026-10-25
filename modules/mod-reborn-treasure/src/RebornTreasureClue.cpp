#include "RebornTreasure.h"
#include "Chat.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldSession.h"
#include <ctime>
#include <unordered_map>

namespace
{
    // Lives in Player::CustomData, so it needs no global map and no lock, and goes away
    // with the player on logout.
    constexpr char TrackerKey[] = "RebornTreasure.ClueTracker";

    struct ClueTracker : DataMap::Base
    {
        uint32 timer = 0;
        std::unordered_map<uint32, uint64> lastAlert; // spawnId -> unix time
    };
}

class RebornTreasurePlayerScript : public PlayerScript
{
public:
    RebornTreasurePlayerScript() : PlayerScript("RebornTreasurePlayerScript") { }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        if (!sRebornTreasure->IsEnabled() || !player || !player->IsInWorld() || !player->IsAlive())
            return;

        // playerbots are Players too; a hundred of them must not each scan and chat
        WorldSession* session = player->GetSession();
        if (!session || session->IsBot())
            return;

        ClueTracker* tracker = player->CustomData.GetDefault<ClueTracker>(TrackerKey);
        if (tracker->timer > diff)
        {
            tracker->timer -= diff;
            return;
        }
        tracker->timer = sRebornTreasure->GetClueIntervalMs();

        if (player->IsInCombat())
            return;

        std::vector<TreasureNearby> nearby;
        sRebornTreasure->CollectNearby(player->GetMapId(), player->GetInstanceId(), player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), nearby);
        if (nearby.empty())
            return;

        uint64 now = static_cast<uint64>(time(nullptr));
        ChatHandler handler(session);
        for (TreasureNearby const& clue : nearby)
        {
            uint64& last = tracker->lastAlert[clue.spawnId];
            if (last && now - last < 60) // the same chest at most once a minute
                continue;
            last = now;

            // the client add-on records this line; keep the [寻宝线索] tag
            handler.PSendSysMessage("|cffffd700[寻宝线索]|r {}", clue.text);
            if (uint32 sound = sRebornTreasure->GetClueSoundId())
                player->PlayDirectSound(sound, player);
        }
    }
};

void AddSC_mod_reborn_treasure_clues()
{
    new RebornTreasurePlayerScript();
}
