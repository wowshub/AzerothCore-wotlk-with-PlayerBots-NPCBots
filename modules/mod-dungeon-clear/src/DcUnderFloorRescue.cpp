/*
 * mod-dungeon-clear — DcUnderFloorRescue.cpp  (RebornWOW DCHOL2A)  See the header.
 */

#include "DcUnderFloorRescue.h"

#include "Ai/Dungeon/DungeonClear/Util/DcStatusPublisher.h"
#include "Chat.h"
#include "Group.h"
#include "Log.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "Timer.h"

#include <string>
#include <unordered_map>
#include <vector>

namespace
{
    // The lowest REAL floor of each listed map, minus a margin. Halls of Lightning:
    // the lowest spawn on the map is the Slag Furnace pit at z 23.23 (the Slag,
    // 28585); the phantom sheets are at -1.9 and -13.9. Anything under 15 is under
    // the dungeon.
    struct FloorRow
    {
        uint32 mapId;
        float minZ;
    };
    constexpr FloorRow kFloors[] = {
        { 602, 15.0f },  // Halls of Lightning
    };

    bool MinZ(uint32 mapId, float* out)
    {
        for (FloorRow const& r : kFloors)
            if (r.mapId == mapId)
            {
                *out = r.minZ;
                return true;
            }
        return false;
    }

    struct Good
    {
        uint32 mapId = 0;
        uint32 instanceId = 0;
        float x = 0, y = 0, z = 0, o = 0;
    };
    std::unordered_map<ObjectGuid, Good> g_lastGood;   // world thread
    std::unordered_map<ObjectGuid, uint32> g_toldAt;   // human told at (ms)
    uint32 g_tickMs = 0;

    void Remember(Player* p)
    {
        Good& g = g_lastGood[p->GetGUID()];
        g.mapId = p->GetMapId();
        g.instanceId = p->GetInstanceId();
        g.x = p->GetPositionX();
        g.y = p->GetPositionY();
        g.z = p->GetPositionZ();
        g.o = p->GetOrientation();
    }

    bool OnRealFloor(Player* p, float minZ)
    {
        return p && p->IsInWorld() && p->IsAlive() && p->GetPositionZ() >= minZ && !p->IsFalling();
    }
}

namespace DcUnderFloorRescue
{
    void Tick(uint32 diff)
    {
        g_tickMs += diff;
        if (g_tickMs < 1000)
            return;
        g_tickMs = 0;
        uint32 const now = getMSTime();

        for (ObjectGuid const& tankGuid : DcStatusPublisher::ActiveTanks())
        {
            Player* tank = ObjectAccessor::FindConnectedPlayer(tankGuid);
            if (!tank || !tank->IsInWorld())
                continue;
            float minZ = 0.0f;
            if (!MinZ(tank->GetMapId(), &minZ))
                continue;

            std::vector<Player*> members;
            if (Group* group = tank->GetGroup())
            {
                for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
                    if (Player* m = ref->GetSource())
                        members.push_back(m);
            }
            else
                members.push_back(tank);

            bool const tankOnFloor = OnRealFloor(tank, minZ);
            for (Player* m : members)
            {
                if (!m->IsInWorld() || !m->IsAlive() || m->GetMapId() != tank->GetMapId() ||
                    m->GetInstanceId() != tank->GetInstanceId())
                    continue;
                if (m->GetPositionZ() >= minZ)
                {
                    if (!m->IsFalling())
                        Remember(m);
                    continue;
                }

                PlayerbotAI* ai = GET_PLAYERBOT_AI(m);
                if (!ai)
                {
                    // Playing by hand: never move them, say how to get back.
                    uint32& told = g_toldAt[m->GetGUID()];
                    if (told == 0 || getMSTimeDiff(told, now) > 30000)
                    {
                        told = now ? now : 1;
                        ChatHandler(m->GetSession()).SendSysMessage(
                            "|cff33ccff[\xe6\xb8\x85\xe6\x9c\xac]|r \xe4\xbd\xa0\xe6\x8e\x89\xe5\x88\xb0\xe4\xba\x86"
                            "\xe5\x89\xaf\xe6\x9c\xac\xe4\xb8\x8b\xe6\x96\xb9\xe3\x80\x82\xe8\xbe\x93\xe5\x85\xa5 "
                            ".appear " + tank->GetName() + " \xe5\x9b\x9e\xe5\x88\xb0\xe5\x9d\xa6\xe5\x85\x8b"
                            "\xe8\xba\xab\xe8\xbe\xb9\xe3\x80\x82");
                    }
                    continue;
                }

                // A bot, or a player the AI is playing: bring it back.
                float x, y, z, o;
                std::string where;
                if (tankOnFloor && m != tank)
                {
                    x = tank->GetPositionX();
                    y = tank->GetPositionY();
                    z = tank->GetPositionZ();
                    o = tank->GetOrientation();
                    where = "the tank";
                }
                else
                {
                    auto it = g_lastGood.find(m->GetGUID());
                    if (it == g_lastGood.end() || it->second.mapId != m->GetMapId() ||
                        it->second.instanceId != m->GetInstanceId())
                        continue;   // never seen on real ground in this instance
                    x = it->second.x;
                    y = it->second.y;
                    z = it->second.z;
                    o = it->second.o;
                    where = "its last position on real ground";
                }
                LOG_INFO("playerbots.dungeonclear",
                         "[DC:{}] DCHOL2A under-floor rescue: {} at ({:.1f},{:.1f},{:.1f}) is under the "
                         "dungeon (floor {:.0f}) -> back to {} ({:.1f},{:.1f},{:.1f})",
                         tank->GetName(), m->GetName(), m->GetPositionX(), m->GetPositionY(),
                         m->GetPositionZ(), minZ, where, x, y, z);
                m->GetMotionMaster()->Clear();
                m->NearTeleportTo(x, y, z, o);
            }
        }
    }
}
