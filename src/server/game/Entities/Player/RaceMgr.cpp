/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "RaceMgr.h"
#include "DBCStores.h"
#include "AccountMgr.h"
#include "DatabaseEnv.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Log.h"
#include "Util.h"
#include "WorldPacket.h"
#include "WorldSession.h"

uint8  RaceMgr::_maxRaces = 0;

uint32 RaceMgr::_playableRaceMask = 0;
uint32 RaceMgr::_allianceRaceMask = 0;
uint32 RaceMgr::_hordeRaceMask = 0;

RaceMgr::RaceMgr()
{
}

RaceMgr::~RaceMgr()
{
}

RaceMgr* RaceMgr::instance()
{
    static RaceMgr instance;
    return &instance;
}

bool RaceMgr::IsRacePlayable(uint8 race)
{
    if (ChrRacesEntry const* raceEntry = sChrRacesStore.LookupEntry(race))
        return !(raceEntry->Flags & CHRRACES_FLAGS_NOT_PLAYABLE);

    return false;
}

void RaceMgr::LoadRaces()
{
    SetMaxRaces(0 + 1);
    _playableRaceMask = 0;
    _hordeRaceMask    = 0;
    _allianceRaceMask = 0;

    for (auto const& raceEntry : sChrRacesStore)
    {
        if (!raceEntry)
            continue;

        uint8 alliance = raceEntry->alliance;
        uint8 raceId = raceEntry->RaceID;

        if (raceEntry->Flags & CHRRACES_FLAGS_NOT_PLAYABLE)
            continue;

        if (GetMaxRaces() <= raceId)
            SetMaxRaces(raceId + 1);

        uint32 raceBit = GetRaceMaskForRace(raceId);
        if (!raceBit)
            continue;


        // RACENEXT3A: a race id >= 38 shares its bit with id-32; both must be the same faction.
        if (IsRaceMaskAlias(raceId))
        {
            uint8 baseRace = uint8(((raceId - 1) & 31) + 1);
            bool sameFaction = false;
            if (ChrRacesEntry const* baseEntry = sChrRacesStore.LookupEntry(baseRace))
                sameFaction = baseEntry->alliance == alliance;
            if (!sameFaction)
            {
                LOG_ERROR("server.loading", "RaceMgr: race {} shares mask bit {} with race {} but they are different factions or the base race is missing - race {} is NOT enabled.",
                    uint32(raceId), uint32((raceId - 1) & 31), uint32(baseRace), uint32(raceId));
                continue;
            }
        }

        _playableRaceMask |= raceBit;

        if (alliance == ALLIANCE_HORDE)
            _hordeRaceMask |= raceBit;
        else if (alliance == ALLIANCE_ALLIANCE)
            _allianceRaceMask |= raceBit;

        if (IsRaceMaskAlias(raceId))
            LOG_INFO("server.loading", "RaceMgr: alias race {} enabled, faction {}, shared mask bit {} (mask 0x{:08X}), template race {}",
                uint32(raceId), uint32(alliance), uint32((raceId - 1) & 31), raceBit, uint32(GetRaceAliasTemplateRace(raceId)));
    }

    LOG_INFO("server.loading", "RaceMgr: capacity max race id+1 = {}, playable mask 0x{:08X}, alliance 0x{:08X}, horde 0x{:08X}",
        uint32(GetMaxRaces()), _playableRaceMask, _allianceRaceMask, _hordeRaceMask);
}
