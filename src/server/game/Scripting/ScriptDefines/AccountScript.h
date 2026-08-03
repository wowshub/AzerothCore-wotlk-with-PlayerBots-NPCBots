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

#ifndef SCRIPT_OBJECT_ACCOUNT_SCRIPT_H_
#define SCRIPT_OBJECT_ACCOUNT_SCRIPT_H_

#include "ScriptObject.h"
#include <vector>

class ObjectGuid;
class WorldSession;

enum AccountHook
{
    ACCOUNTHOOK_ON_ACCOUNT_LOGIN,
    ACCOUNTHOOK_ON_BEFORE_ACCOUNT_DELETE,
    ACCOUNTHOOK_ON_LAST_IP_UPDATE,
    ACCOUNTHOOK_ON_FAILED_ACCOUNT_LOGIN,
    ACCOUNTHOOK_ON_EMAIL_CHANGE,
    ACCOUNTHOOK_ON_FAILED_EMAIL_CHANGE,
    ACCOUNTHOOK_ON_PASSWORD_CHANGE,
    ACCOUNTHOOK_ON_FAILED_PASSWORD_CHANGE,
    ACCOUNTHOOK_CAN_ACCOUNT_CREATE_CHARACTER,
    ACCOUNTHOOK_ON_ACCOUNT_CHARACTER_CREATE_REQUEST,
    ACCOUNTHOOK_ON_ACCOUNT_SELECT_CHARACTER,
    ACCOUNTHOOK_ON_BEFORE_ACCOUNT_CHARACTER_ENUM,
    ACCOUNTHOOK_CAN_ACCOUNT_LIST_CHARACTER,
    ACCOUNTHOOK_ON_ACCOUNT_REALM_CHARACTER_COUNT,
    ACCOUNTHOOK_CAN_ACCOUNT_DELETE_CHARACTER,
    ACCOUNTHOOK_ON_ACCOUNT_CHARACTER_CREATE_PREPARED,
    ACCOUNTHOOK_ON_ACCOUNT_CHARACTER_CREATE_RESULT,
    ACCOUNTHOOK_END
};

class AccountScript : public ScriptObject
{
protected:
    AccountScript(const char* name, std::vector<uint16> enabledHooks = std::vector<uint16>());

public:
    // Called when an account logged in successfully
    virtual void OnAccountLogin(uint32 /*accountId*/) { }

    // Called when an account is about to be deleted
    virtual void OnBeforeAccountDelete(uint32 /*accountId*/) { }

    // Called when an ip logged in successfully
    virtual void OnLastIpUpdate(uint32 /*accountId*/, std::string /*ip*/) { }

    // Called when an account login failed
    virtual void OnFailedAccountLogin(uint32 /*accountId*/) { }

    // Called when Email is successfully changed for Account
    virtual void OnEmailChange(uint32 /*accountId*/) { }

    // Called when Email failed to change for Account
    virtual void OnFailedEmailChange(uint32 /*accountId*/) { }

    // Called when Password is successfully changed for Account
    virtual void OnPasswordChange(uint32 /*accountId*/) { }

    // Called when Password failed to change for Account
    virtual void OnFailedPasswordChange(uint32 /*accountId*/) { }

    // Called when creating a character on the Account
    [[nodiscard]] virtual bool CanAccountCreateCharacter(uint32 /*accountId*/, uint8 /*charRace*/, uint8 /*charClass*/) { return true;}

    // Called immediately after an authenticated CMSG_CHAR_CREATE has been decoded and before any
    // normal character-creation validation. Set consumed=true only for a complete custom request.
    virtual void OnAccountCharacterCreateRequest(WorldSession* /*session*/, std::string const& /*name*/, bool& /*consumed*/) { }

    // Called after the client-selected GUID has passed the normal ownership check. A script may
    // replace it with another GUID owned by the same authenticated account; the core checks the
    // replacement against the legitimate-character set again before loading it.
    virtual void OnAccountSelectCharacter(WorldSession* /*session*/, ObjectGuid& /*guid*/) { }

    // Called immediately before the authenticated session requests its character list.
    virtual void OnBeforeAccountCharacterEnum(WorldSession* /*session*/) { }

    // Return false to keep a character out of SMSG_CHAR_ENUM while retaining it as a legitimate
    // character that the authenticated session may log in by GUID.
    [[nodiscard]] virtual bool CanAccountListCharacter(uint32 /*accountId*/, uint32 /*guidLow*/) { return true; }

    // Adjust the visible character count stored or checked for this realm.
    virtual void OnAccountRealmCharacterCount(uint32 /*accountId*/, uint64& /*count*/) { }

    // Return false to reject a client-side character-delete request.
    [[nodiscard]] virtual bool CanAccountDeleteCharacter(uint32 /*accountId*/, uint32 /*guidLow*/) { return true; }

    // Called after all normal creation validation and the final name-cache check, immediately
    // before Player::Create. Set allowed=false to reject the request. This is the safe point for
    // an external module to reserve account-level currency.
    virtual void OnAccountCharacterCreatePrepared(WorldSession* /*session*/, std::string const& /*name*/, uint32 /*slotNumber*/, bool& /*allowed*/) { }

    // Completes a request that previously reached OnAccountCharacterCreatePrepared. A payment
    // module can settle the reservation on success or refund it on any create/database failure.
    virtual void OnAccountCharacterCreateResult(WorldSession* /*session*/, std::string const& /*name*/, bool /*success*/) { }
};

#endif
