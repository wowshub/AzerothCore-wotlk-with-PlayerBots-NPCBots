// mod-reborn-bg-hinterland (HLBG1A)
//
// Registers the Hinterland battleground (DarkChaos-255 "HLBG", type 20, queue 14) with the core, the same way the
// Helias battleground modules do: the module fills BattlegroundMgr's static tables at script-load time.
// The battleground class itself is BattlegroundHLBG.cpp (ported from DarkChaos, DarkChaos systems replaced by HLBGShim.h).
//
// Ids used by this module (all must stay unique in this project):
//   battleground type 20, queue type 14, map 20411 (HinterlandBGTest), area/zone 20411.

#include "BattlegroundHLBG.h"
#include "HLBGShim.h"
#include "BattlegroundMgr.h"
#include "Chat.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "WorldStatePackets.h"
#include "hlbg.h"
#include "hlbg_constants.h"

// Player statistics: DarkChaos wrote them to its own tables. Not ported in the first batch.
void HLBGPlayerStats::OnPlayerEnterBG(Player* /*player*/) { }
void HLBGPlayerStats::OnPlayerKill(Player* /*killer*/, Player* /*victim*/) { }
void HLBGPlayerStats::OnResourceCapture(Player* /*player*/, uint32 /*resourceAmount*/) { }
void HLBGPlayerStats::OnPlayerWin(Player* /*player*/) { }
void HLBGPlayerStats::OnTeamWin(TeamId /*winningTeam*/, uint32 /*zoneId*/) { }

// Live HUD numbers for the client addon (RebornBGHinterlandHUD). An addon whisper "HLBG<TAB>body" raises CHAT_MSG_ADDON
// on the client and is never shown in the chat window.
namespace
{
    void SendHudMessage(Player* player, std::string const& body)
    {
        if (!player || !player->GetSession())
            return;

        std::string const message = "HLBG\t" + body;
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_WHISPER, message, LANG_ADDON, CHAT_TAG_NONE, player->GetGUID(),
                                     player->GetName(), player->GetGUID(), player->GetName());
        player->GetSession()->SendPacket(&data);
    }
}

void DCAddon::HLBG::SendStatus(Player* player, HLBGStatus status, uint32 mapId, uint32 timeRemaining)
{
    SendHudMessage(player, "S:" + std::to_string(uint32(status)) + ":" + std::to_string(mapId) + ":" + std::to_string(timeRemaining));
}

void DCAddon::HLBG::SendResources(Player* player, uint32 allianceRes, uint32 hordeRes, uint32 /*allianceBases*/,
                                  uint32 /*hordeBases*/, uint32 alliancePlayers, uint32 hordePlayers,
                                  uint32 alliancePlayerKills, uint32 hordePlayerKills, uint32 allianceNpcKills,
                                  uint32 hordeNpcKills)
{
    SendHudMessage(player, "R:" + std::to_string(allianceRes) + ":" + std::to_string(hordeRes) + ":" +
                               std::to_string(alliancePlayers) + ":" + std::to_string(hordePlayers) + ":" +
                               std::to_string(alliancePlayerKills) + ":" + std::to_string(hordePlayerKills) + ":" +
                               std::to_string(allianceNpcKills) + ":" + std::to_string(hordeNpcKills));
}

class RebornBGHinterlandWorld : public WorldScript
{
public:
    RebornBGHinterlandWorld() : WorldScript("RebornBGHinterlandWorld") { }
};

void AddSC_mod_reborn_bg_hinterland()
{
    new RebornBGHinterlandWorld();

    BattlegroundMgr::queueToBg[BATTLEGROUND_QUEUE_HLBG] = BATTLEGROUND_HLBG;
    BattlegroundMgr::bgToQueue[BATTLEGROUND_HLBG] = BATTLEGROUND_QUEUE_HLBG;
    BattlegroundMgr::bgtypeToBattleground[BATTLEGROUND_HLBG] = new BattlegroundHLBG;
    BattlegroundMgr::bgTypeToTemplate[BATTLEGROUND_HLBG] = [](Battleground* bgTemplate) -> Battleground*
    {
        return new BattlegroundHLBG(*static_cast<BattlegroundHLBG*>(bgTemplate));
    };

    // World states of the battleground are sent for its own zone (area table row 20411 is its own zone).
    Player::bgZoneIdToFillWorldStates[HinterlandBGConstants::HLBG_ZONE_ID] =
        [](Battleground* bg, WorldPackets::WorldState::InitWorldStates& packet)
    {
        if (bg && bg->GetBgTypeID(true) == BATTLEGROUND_HLBG)
            bg->FillInitialWorldStates(packet);
    };
}
