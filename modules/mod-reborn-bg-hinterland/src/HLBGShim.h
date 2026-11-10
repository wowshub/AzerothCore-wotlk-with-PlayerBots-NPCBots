// HLBGShim.h - stand-ins for the DarkChaos systems BattlegroundHLBG depends on.
//
// The original battleground class (DarkChaos-255, src/server/scripts/DC/HinterlandBG) talks to
//   * the DC addon protocol   (DCAddon::HLBG::Send*)  - pushes a live HUD to their client addon
//   * HLBGService             - season counter and match history in their database
//   * DCUtils                 - one string helper
// None of these exist here. This header keeps the call sites unchanged and does nothing for them.
// The HUD is the standard world-state HUD (WorldStateUI rows for map 20411); history/stats can be added later.
#ifndef MOD_REBORN_BG_HINTERLAND_SHIM_H
#define MOD_REBORN_BG_HINTERLAND_SHIM_H

#include "Define.h"
#include "SharedDefines.h"

#include <cstdint>
#include <cstdlib>
#include <string>
#include <vector>

class Player;

namespace DCAddon
{
    namespace HLBG
    {
        enum HLBGStatus : uint8
        {
            STATUS_NONE   = 0,
            STATUS_QUEUED = 1,
            STATUS_PREP   = 2,
            STATUS_ACTIVE = 3,
            STATUS_ENDED  = 4,
        };

        // Implemented in RebornBGHinterland.cpp: they push the live numbers to the client addon "RebornBGHinterlandHUD"
        // as an addon whisper with the prefix "HLBG" (the same channel DarkChaos used for its own addon).
        void SendStatus(Player* player, HLBGStatus status, uint32 mapId, uint32 timeRemaining);
        void SendResources(Player* player, uint32 allianceRes, uint32 hordeRes, uint32 allianceBases, uint32 hordeBases,
                           uint32 alliancePlayers, uint32 hordePlayers, uint32 alliancePlayerKills, uint32 hordePlayerKills,
                           uint32 allianceNpcKills, uint32 hordeNpcKills);
        inline void SendAffixInfo(Player*, uint32, uint32, uint32, uint32) { }
        inline void SendMatchEnd(Player*, bool, uint32, uint32, uint32, uint32) { }
    }
}

namespace DCUtils
{
    // "1,2,3" -> {1,2,3}; empty and invalid tokens are skipped.
    inline std::vector<uint32> ParseUInt32List(std::string const& input)
    {
        std::vector<uint32> out;
        std::size_t start = 0;
        while (start <= input.size())
        {
            std::size_t comma = input.find(',', start);
            std::string token = input.substr(start, comma == std::string::npos ? std::string::npos : comma - start);
            char* end = nullptr;
            unsigned long value = std::strtoul(token.c_str(), &end, 10);
            if (end != token.c_str() && value > 0)
                out.push_back(static_cast<uint32>(value));
            if (comma == std::string::npos)
                break;
            start = comma + 1;
        }
        return out;
    }
}

class HLBGService
{
public:
    static HLBGService& Instance()
    {
        static HLBGService instance;
        return instance;
    }

    uint32 GetSeason() const { return 1u; }

    void RecordWinner(TeamId, uint32, uint32, uint32, char const*, uint8, uint8, uint8, uint32, float, uint32) { }
    void RecordManualReset(uint32, uint32, uint32, uint8, uint8, uint8, uint32, float, uint32) { }

private:
    HLBGService() = default;
};

#endif // MOD_REBORN_BG_HINTERLAND_SHIM_H
