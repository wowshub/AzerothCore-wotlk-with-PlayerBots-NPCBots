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

#include "CombatPackets.h"
#include "CreatureAI.h"
#include "Item.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Opcodes.h"
#include "Player.h"
#include "Vehicle.h"
#include "WorldPacket.h"
#include "WorldSession.h"

void WorldSession::HandleAttackSwingOpcode(WorldPacket& recvData)
{
    ObjectGuid guid;
    recvData >> guid;

    LOG_DEBUG("network", "WORLD: Recvd CMSG_ATTACKSWING: {}", guid.ToString());

    Unit* pEnemy = ObjectAccessor::GetUnit(*_player, guid);

    if (!pEnemy)
    {
        // stop attack state at client
        SendAttackStop(nullptr);
        return;
    }

    if (!_player->IsValidAttackTarget(pEnemy))
    {
        // stop attack state at client
        SendAttackStop(pEnemy);
        return;
    }

    //! Client explicitly checks the following before sending CMSG_ATTACKSWING packet,
    //! so we'll place the same check here. Note that it might be possible to reuse this snippet
    //! in other places as well.
    if (Vehicle* vehicle = _player->GetVehicle())
    {
        VehicleSeatEntry const* seat = vehicle->GetSeatForPassenger(_player);
        ASSERT(seat);
        if (!(seat->m_flags & VEHICLE_SEAT_FLAG_CAN_ATTACK))
        {
            SendAttackStop(pEnemy);
            return;
        }
    }

    // WD71E: explicitly supported custom classes use native ranged repeat
    // with an equipped usable weapon. Original classes retain their behavior.
    if ((_player->getClass() == CLASS_WITCH_DOCTOR || _player->getClass() == CLASS_MONK) && !_player->IsWithinMeleeRange(pEnemy))
    {
        if (Item* weapon = _player->GetWeaponForAttack(RANGED_ATTACK, true))
        {
            uint32 shot = 0;
            switch (weapon->GetTemplate()->SubClass)
            {
                case ITEM_SUBCLASS_WEAPON_GUN:
                case ITEM_SUBCLASS_WEAPON_BOW:
                case ITEM_SUBCLASS_WEAPON_CROSSBOW:
                    shot = 75; // Auto Shot; the manual Shoot spell 3018 remains available.
                    break;
                case ITEM_SUBCLASS_WEAPON_WAND:
                    shot = 5019; // Native repeating wand Shoot.
                    break;
                default:
                    break;
            }

            if (shot && _player->HasSpell(shot))
            {
                _player->Attack(pEnemy, false);
                _player->CastSpell(pEnemy, shot, false);
                return;
            }
        }
    }

    if ((_player->getClass() == CLASS_WITCH_DOCTOR || _player->getClass() == CLASS_MONK))
    {
        _player->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);
        _player->SetSheath(SHEATH_STATE_MELEE);
    }
    _player->Attack(pEnemy, true);
}

void WorldSession::HandleAttackStopOpcode(WorldPacket& /*recvData*/)
{
    if ((GetPlayer()->getClass() == CLASS_WITCH_DOCTOR || GetPlayer()->getClass() == CLASS_MONK))
        GetPlayer()->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);
    GetPlayer()->AttackStop();
}

void WorldSession::HandleSetSheathedOpcode(WorldPackets::Combat::SetSheathed& packet)
{
    if (packet.CurrentSheathState >= MAX_SHEATH_STATE)
    {
        LOG_ERROR("network.opcode", "Unknown sheath state {} ??", packet.CurrentSheathState);
        return;
    }

    // WD71C: a late client melee-sheath request must not clear the ranged
    // slot while the custom class is already running native Auto Shot.
    if ((_player->getClass() == CLASS_WITCH_DOCTOR || _player->getClass() == CLASS_MONK) &&
        packet.CurrentSheathState == SHEATH_STATE_MELEE &&
        (_player->FindCurrentSpellBySpellId(75) || _player->FindCurrentSpellBySpellId(5019)) &&
        _player->GetWeaponForAttack(RANGED_ATTACK, true))
    {
        if (Unit* victim = _player->GetVictim())
        {
            if (!_player->IsWithinMeleeRange(victim))
            {
                _player->SetSheath(SHEATH_STATE_RANGED);
                _player->ForceValuesUpdateAtIndex(UNIT_FIELD_BYTES_2);
                _player->ForceValuesUpdateAtIndex(UNIT_VIRTUAL_ITEM_SLOT_ID + 2);
                return;
            }
        }
    }
    _player->SetSheath(SheathState(packet.CurrentSheathState));
}

void WorldSession::SendAttackStop(Unit const* enemy)
{
    WorldPacket data(SMSG_ATTACKSTOP, (8 + 8 + 4)); // we guess size
    data << GetPlayer()->GetPackGUID();

    if (enemy)
    {
        data << enemy->GetPackGUID();               // must be packed guid
        data << (uint32)enemy->isDead();
    }
    SendPacket(&data);
}
