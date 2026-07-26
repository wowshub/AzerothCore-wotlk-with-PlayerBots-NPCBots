/*
 * RebornWOW stage S.4.1
 *
 * Account-bound C++ prototype for an ordinary-world spectator carrier.
 *
 * This module deliberately proves only the server-side carrier path:
 *   - resolve an online Player or Playerbot by selection, name, or low GUID;
 *   - move a dedicated GM test character to the target's ordinary world map;
 *   - establish the already proven spell-6277 viewpoint;
 *   - apply reversible prototype protection to the observer;
 *   - remove only this observer's Bind Sight aura and restore the observer.
 *
 * S.3 added the authenticated server-side bridge required by the future Glue/DLL flow:
 *   - bind one dedicated carrier character to an authenticated account;
 *   - store explicit opt-in for real-player targets (Playerbot sessions default to allowed);
 *   - consume one short-lived request exactly once when that account logs in its carrier;
 *   - enter the already proven spell-6277 viewpoint without an in-world start command.
 *
 * S.4 adds an opt-in automatic carrier factory and the core hooks needed to hide only
 * auto-created carriers from CharacterEnum while keeping their GUID authorized for a later
 * authenticated direct login. Hidden carriers are removed from visible slot/faction checks and
 * protected from client-side deletion.
 *
 * It is still NOT the complete production login-screen system. The Web/DLL authenticated request
 * endpoint, direct Glue login, instances, target map following, spectator roster UI, database
 * audit history, and crash recovery belong to later stages.
 */

#include "ArenaSpectator.h"
#include "AccountScript.h"
#include "CharacterCache.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Util.h"
#include "World.h"
#include "WorldSession.h"

#include <algorithm>
#include <map>
#include <memory>
#include <mutex>
#include <string>

namespace
{
constexpr uint32 REBORN_BIND_SIGHT_SPELL = 6277;
constexpr uint32 REBORN_CHECK_INTERVAL_MS = 250;

bool g_RebornSpectatorEnabled = true;
bool g_RebornReturnOnStop = true;
bool g_RebornCarrierLoginEnabled = true;
bool g_RebornAutoCarrierProvisionEnabled = false;
bool g_RebornHideAutoCarrierFromEnum = false;
uint8 g_RebornAutoCarrierRace = RACE_HUMAN;
uint8 g_RebornAutoCarrierClass = CLASS_WARRIOR;
uint8 g_RebornAutoCarrierGender = GENDER_MALE;
uint32 g_RebornBindRetryMs = 250;
uint32 g_RebornBindTimeoutMs = 7000;
uint32 g_RebornCarrierLoginDelayMs = 1500;
uint32 g_RebornRequestTtlSeconds = 120;

enum class RebornSpectatorStage : uint8
{
    PendingViewpoint,
    Active
};

struct RebornSpectatorSession
{
    ObjectGuid observerGuid;
    ObjectGuid targetGuid;
    RebornSpectatorStage stage = RebornSpectatorStage::PendingViewpoint;

    uint32 returnMapId = 0;
    float returnX = 0.0f;
    float returnY = 0.0f;
    float returnZ = 0.0f;
    float returnO = 0.0f;
    uint32 returnPhaseMask = PHASEMASK_NORMAL;

    uint32 targetMapId = 0;
    uint32 targetInstanceId = 0;

    bool wasGMVisible = true;
    bool hadRoot = false;
    bool hadDisableMove = false;
    bool hadNonAttackable = false;
    bool hadPacified = false;
    bool hadSilenced = false;
    bool hadNotSelectable = false;

    uint32 totalPendingMs = 0;
    uint32 retryTimerMs = 0;
    uint32 activeCheckTimerMs = 0;
};

struct RebornPendingCarrierLogin
{
    uint32 accountId = 0;
    uint32 targetGuidLow = 0;
    uint32 elapsedMs = 0;
};

struct RebornCarrierRecord
{
    uint32 guidLow = 0;
    bool enabled = false;
    bool autoCreated = false;
    bool characterOwnedByAccount = false;
};

std::string EncodeCarrierToken(uint32 value)
{
    // Adjacent positions deliberately use disjoint alphabets.  The 3.3.5 core
    // rejects names containing three identical consecutive letters, so a
    // fixed-width ordinary base-26 value such as "aaaa..." is not valid for
    // the relatively small Player GUIDs used by this realm.
    static constexpr char Consonants[] = "bcdfghjklmnpqrstvwxyz";
    static constexpr char Vowels[] = "aeiou";

    std::string token(7, 'a');
    for (std::size_t index = token.size(); index > 0; --index)
    {
        bool const consonantPosition = ((index - 1) % 2) == 0;
        char const* alphabet = consonantPosition ? Consonants : Vowels;
        uint32 const alphabetSize = consonantPosition ? uint32(sizeof(Consonants) - 1) : uint32(sizeof(Vowels) - 1);
        token[index - 1] = alphabet[value % alphabetSize];
        value /= alphabetSize;
    }
    return token;
}

char const* StageName(RebornSpectatorStage stage)
{
    switch (stage)
    {
        case RebornSpectatorStage::PendingViewpoint:
            return "pending viewpoint";
        case RebornSpectatorStage::Active:
            return "active";
    }

    return "unknown";
}

void SendPrototypeMessage(Player* player, std::string const& text)
{
    if (player && player->GetSession())
        ChatHandler(player->GetSession()).PSendSysMessage("|cff33ff99[Reborn Spectator S.4.1]|r {}", text);
}

class RebornSpectatorMgr
{
public:
    static RebornSpectatorMgr& Instance()
    {
        static RebornSpectatorMgr instance;
        return instance;
    }

    void PrepareCharacterEnum(WorldSession* session)
    {
        if (!g_RebornSpectatorEnabled || !session || session->IsBot())
            return;

        uint32 const accountId = session->GetAccountId();
        RebornCarrierRecord record;
        if (LoadCarrierRecord(accountId, record))
        {
            if (!record.characterOwnedByAccount)
            {
                ClearCachedCarrier(accountId);
                LOG_ERROR(
                    "module",
                    "RebornSpectator S.4: account {} has invalid carrier binding to GUIDLow {}; automatic replacement was refused",
                    accountId,
                    record.guidLow);
                return;
            }

            CacheCarrier(accountId, record);
            if (g_RebornHideAutoCarrierFromEnum && record.enabled && record.autoCreated)
                sWorld->UpdateRealmCharCount(accountId);
            return;
        }

        ClearCachedCarrier(accountId);
        if (!g_RebornAutoCarrierProvisionEnabled)
            return;

        CreateAutoCarrier(session);
    }

    bool CanListCharacter(uint32 accountId, uint32 guidLow)
    {
        if (!g_RebornSpectatorEnabled || !g_RebornHideAutoCarrierFromEnum)
            return true;

        RebornCarrierRecord record;
        if (!GetCarrierRecord(accountId, record))
            return true;

        return !(record.enabled && record.autoCreated && record.characterOwnedByAccount &&
                 record.guidLow == guidLow);
    }

    void AdjustRealmCharacterCount(uint32 accountId, uint64& count)
    {
        if (!g_RebornSpectatorEnabled || !g_RebornHideAutoCarrierFromEnum || count == 0)
            return;

        RebornCarrierRecord record;
        if (GetCarrierRecord(accountId, record) && record.enabled && record.autoCreated &&
            record.characterOwnedByAccount)
        {
            --count;
        }
    }

    bool CanDeleteCharacter(uint32 accountId, uint32 guidLow)
    {
        RebornCarrierRecord record;
        if (!GetCarrierRecord(accountId, record))
            return true;

        bool const protectedAutoCarrier =
            record.autoCreated && record.characterOwnedByAccount && record.guidLow == guidLow;
        if (protectedAutoCarrier)
        {
            LOG_WARN(
                "module",
                "RebornSpectator S.4: rejected client-side deletion of automatic carrier GUIDLow {} for account {}",
                guidLow,
                accountId);
        }

        return !protectedAutoCarrier;
    }

    bool Start(Player* observer, Player* target, bool authenticatedCarrierLogin = false)
    {
        if (!g_RebornSpectatorEnabled)
        {
            SendPrototypeMessage(observer, "|cffff5555The prototype is disabled in RebornSpectator.conf.|r");
            return false;
        }

        if (!observer || !target || !observer->GetSession())
            return false;

        if (!authenticatedCarrierLogin && observer->GetSession()->GetSecurity() < SEC_GAMEMASTER)
        {
            SendPrototypeMessage(observer, "|cffff5555Manual start remains GM-only in stage S.4.|r");
            return false;
        }

        if (HasSession(observer->GetGUID()))
        {
            SendPrototypeMessage(observer, "|cffff5555A prototype session is already active. Use .rebornspec stop first.|r");
            return false;
        }

        if (observer->GetGUID() == target->GetGUID())
        {
            SendPrototypeMessage(observer, "|cffff5555You cannot observe yourself.|r");
            return false;
        }

        if (IsObserver(target->GetGUID()))
        {
            SendPrototypeMessage(observer, "|cffff5555The selected target is already acting as a Reborn spectator carrier.|r");
            return false;
        }

        if (!observer->IsInWorld() || !target->IsInWorld() || observer->IsBeingTeleported() || target->IsBeingTeleported())
        {
            SendPrototypeMessage(observer, "|cffff5555Observer and target must be fully present in the world and not teleporting.|r");
            return false;
        }

        if (!observer->IsAlive() || !target->IsAlive())
        {
            SendPrototypeMessage(observer, "|cffff5555Observer and target must both be alive.|r");
            return false;
        }

        if (observer->IsSpectator() || target->IsSpectator())
        {
            SendPrototypeMessage(observer, "|cffff5555Stage S.4 cannot overlap the existing arena spectator state.|r");
            return false;
        }

        Map* observerMap = observer->FindMap();
        Map* targetMap = target->FindMap();
        if (!observerMap || !targetMap || observerMap->Instanceable() || targetMap->Instanceable() ||
            observer->GetInstanceId() != 0 || target->GetInstanceId() != 0)
        {
            SendPrototypeMessage(observer, "|cffff5555Stage S.4 only permits ordinary open-world maps (InstanceId 0).|r");
            return false;
        }

        if (observer->IsInCombat() || observer->GetVehicle() || observer->IsInFlight() || observer->IsMounted() ||
            observer->GetGroup())
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555Before testing, leave combat/group/vehicle/flight and dismount the observer carrier.|r");
            return false;
        }

        if (observer->GetViewpoint())
        {
            SendPrototypeMessage(observer, "|cffff5555The observer already has a remote viewpoint. Clear it before S.4.|r");
            return false;
        }

        RebornSpectatorSession session;
        session.observerGuid = observer->GetGUID();
        session.targetGuid = target->GetGUID();
        session.returnMapId = observer->GetMapId();
        session.returnX = observer->GetPositionX();
        session.returnY = observer->GetPositionY();
        session.returnZ = observer->GetPositionZ();
        session.returnO = observer->GetOrientation();
        session.returnPhaseMask = observer->GetPhaseMask();
        session.targetMapId = target->GetMapId();
        session.targetInstanceId = target->GetInstanceId();
        session.wasGMVisible = observer->isGMVisible();
        session.hadRoot = observer->HasUnitState(UNIT_STATE_ROOT);
        session.hadDisableMove = observer->HasUnitFlag(UNIT_FLAG_DISABLE_MOVE);
        session.hadNonAttackable = observer->HasUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
        session.hadPacified = observer->HasUnitFlag(UNIT_FLAG_PACIFIED);
        session.hadSilenced = observer->HasUnitFlag(UNIT_FLAG_SILENCED);
        session.hadNotSelectable = observer->HasUnitFlag(UNIT_FLAG_NOT_SELECTABLE);

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _sessions.emplace(observer->GetGUID().GetRawValue(), session);
        }

        if (session.wasGMVisible)
        {
            observer->SetGMVisible(false);
            observer->UpdateObjectVisibility();
        }

        observer->CombatStopWithPets();
        observer->SetPhaseMask(target->GetPhaseMask(), true);

        SendPrototypeMessage(
            observer,
            "Preparing direct viewpoint for |cffffff00" + target->GetName() + "|r (GUIDLow " +
                std::to_string(target->GetGUID().GetCounter()) + ").");

        float const destinationZ = target->GetPositionZ() + 0.25f;
        if (!observer->TeleportTo(
                target->GetMapId(),
                target->GetPositionX(),
                target->GetPositionY(),
                destinationZ,
                target->GetOrientation(),
                TELE_TO_GM_MODE))
        {
            SendPrototypeMessage(observer, "|cffff5555Teleport preparation failed; restoring the observer.|r");
            Stop(observer, false, "teleport failed");
            return false;
        }

        LOG_INFO(
            "module",
            "RebornSpectator S.4: observer {} ({}) started pending session for target {} ({})",
            observer->GetName(),
            observer->GetGUID().GetCounter(),
            target->GetName(),
            target->GetGUID().GetCounter());

        return true;
    }

    bool Stop(Player* observer, bool returnToOrigin, std::string const& reason)
    {
        if (!observer)
            return false;

        RebornSpectatorSession session;
        if (!TakeSession(observer->GetGUID(), session))
        {
            SendPrototypeMessage(observer, "No tracked S.4 session is active.");
            return false;
        }

        RemoveViewpoint(observer);
        RestoreProtection(observer, session);

        if (returnToOrigin && g_RebornReturnOnStop && observer->IsInWorld() && !observer->IsBeingTeleported())
        {
            if (!observer->TeleportTo(
                    session.returnMapId,
                    session.returnX,
                    session.returnY,
                    session.returnZ,
                    session.returnO,
                    TELE_TO_GM_MODE))
            {
                SendPrototypeMessage(
                    observer,
                    "|cffff5555Viewpoint stopped, but returning to the original position failed. Use a GM teleport command.|r");
                LOG_ERROR(
                    "module",
                    "RebornSpectator S.4: failed to return observer {} ({}) to map {}",
                    observer->GetName(),
                    observer->GetGUID().GetCounter(),
                    session.returnMapId);
            }
        }

        std::string message = "|cffffff00Prototype stopped";
        if (!reason.empty())
            message += " (" + reason + ")";
        message += ". Camera control belongs to the observer again.|r";
        SendPrototypeMessage(observer, message);

        LOG_INFO(
            "module",
            "RebornSpectator S.4: observer {} ({}) stopped session for target GUIDLow {} ({})",
            observer->GetName(),
            observer->GetGUID().GetCounter(),
            session.targetGuid.GetCounter(),
            reason);

        return true;
    }

    void Update(Player* observer, uint32 diff)
    {
        if (!observer)
            return;

        RebornSpectatorSession session;
        bool shouldCheck = false;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _sessions.find(observer->GetGUID().GetRawValue());
            if (itr == _sessions.end())
                return;

            if (itr->second.stage == RebornSpectatorStage::PendingViewpoint)
            {
                itr->second.totalPendingMs += diff;
                itr->second.retryTimerMs += diff;
                if (itr->second.retryTimerMs >= g_RebornBindRetryMs)
                {
                    itr->second.retryTimerMs = 0;
                    shouldCheck = true;
                }
            }
            else
            {
                itr->second.activeCheckTimerMs += diff;
                if (itr->second.activeCheckTimerMs >= REBORN_CHECK_INTERVAL_MS)
                {
                    itr->second.activeCheckTimerMs = 0;
                    shouldCheck = true;
                }
            }

            session = itr->second;
        }

        if (!shouldCheck)
            return;

        Player* target = ObjectAccessor::FindPlayer(session.targetGuid);
        if (!target || !target->IsInWorld())
        {
            Stop(observer, true, "target left the world");
            return;
        }

        if (!target->IsAlive())
        {
            Stop(observer, true, "target died");
            return;
        }

        if (target->IsBeingTeleported() || target->GetMapId() != session.targetMapId ||
            target->GetInstanceId() != session.targetInstanceId)
        {
            Stop(observer, true, "target changed map or started teleporting");
            return;
        }

        if (session.stage == RebornSpectatorStage::Active)
        {
            WorldObject* viewpoint = observer->GetViewpoint();
            if (!viewpoint || viewpoint->GetGUID() != session.targetGuid)
                Stop(observer, true, "6277 viewpoint ended");
            return;
        }

        if (session.totalPendingMs >= g_RebornBindTimeoutMs)
        {
            Stop(observer, true, "6277 viewpoint timed out");
            return;
        }

        if (observer->IsBeingTeleported() || observer->GetMapId() != target->GetMapId() ||
            observer->GetInstanceId() != target->GetInstanceId())
            return;

        observer->SetPhaseMask(target->GetPhaseMask(), true);
        observer->UpdateObjectVisibility();

        if (!observer->HaveAtClient(target))
            return;

        observer->CastSpell(target, REBORN_BIND_SIGHT_SPELL, true);

        WorldObject* viewpoint = observer->GetViewpoint();
        if (!viewpoint || viewpoint->GetGUID() != target->GetGUID())
            return;

        ApplyProtection(observer, session);

        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _sessions.find(observer->GetGUID().GetRawValue());
            if (itr == _sessions.end() || itr->second.targetGuid != target->GetGUID())
                return;

            itr->second.stage = RebornSpectatorStage::Active;
            itr->second.activeCheckTimerMs = 0;
        }

        SendPrototypeMessage(
            observer,
            "|cff00ff00PASS (server-side immediate check): direct 6277 viewpoint is now " + target->GetName() +
                ". Use .rebornspec stop before logout or reload.|r");

        LOG_INFO(
            "module",
            "RebornSpectator S.4: observer {} ({}) activated viewpoint on target {} ({})",
            observer->GetName(),
            observer->GetGUID().GetCounter(),
            target->GetName(),
            target->GetGUID().GetCounter());
    }

    void ShowStatus(Player* observer)
    {
        if (!observer)
            return;

        RebornSpectatorSession session;
        if (!GetSession(observer->GetGUID(), session))
        {
            SendPrototypeMessage(observer, "Status: no tracked S.4 session.");
            return;
        }

        Player* target = ObjectAccessor::FindPlayer(session.targetGuid);
        std::string targetName = target ? target->GetName() : "<offline>";
        SendPrototypeMessage(
            observer,
            "Status: " + std::string(StageName(session.stage)) + ", target " + targetName + ", GUIDLow " +
                std::to_string(session.targetGuid.GetCounter()) + ".");
    }

    void HandleBeforeLogout(Player* player)
    {
        if (!player)
            return;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _pendingCarrierLogins.erase(player->GetGUID().GetRawValue());
        }

        if (HasSession(player->GetGUID()))
            Stop(player, true, "observer logout");
    }

    void HandlePlayerLogin(Player* player)
    {
        if (!g_RebornSpectatorEnabled || !g_RebornCarrierLoginEnabled || !player || !player->GetSession() ||
            player->GetSession()->IsBot())
        {
            return;
        }

        uint32 const accountId = player->GetSession()->GetAccountId();
        uint32 const carrierGuidLow = player->GetGUID().GetCounter();
        QueryResult request = CharacterDatabase.Query(
            "SELECT r.`target_guid` "
            "FROM `reborn_spectator_carrier` c "
            "INNER JOIN `reborn_spectator_request` r "
            "ON r.`account_id` = c.`account_id` AND r.`carrier_guid` = c.`carrier_guid` "
            "WHERE c.`account_id` = {} AND c.`carrier_guid` = {} AND c.`enabled` = 1 "
            "AND r.`expires_at` > UTC_TIMESTAMP() LIMIT 1",
            accountId,
            carrierGuidLow);

        if (!request)
        {
            CharacterDatabase.DirectExecute(
                "DELETE FROM `reborn_spectator_request` "
                "WHERE `account_id` = {} AND `expires_at` <= UTC_TIMESTAMP()",
                accountId);
            return;
        }

        uint32 const targetGuidLow = request->Fetch()[0].Get<uint32>();

        // Consume before starting. A failed/offline target must never replay on a later login.
        CharacterDatabase.DirectExecute(
            "DELETE FROM `reborn_spectator_request` "
            "WHERE `account_id` = {} AND `carrier_guid` = {} AND `target_guid` = {}",
            accountId,
            carrierGuidLow,
            targetGuidLow);

        RebornPendingCarrierLogin pending;
        pending.accountId = accountId;
        pending.targetGuidLow = targetGuidLow;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _pendingCarrierLogins[player->GetGUID().GetRawValue()] = pending;
        }

        SendPrototypeMessage(
            player,
            "|cff00ff00Authenticated account/carrier request accepted.|r Waiting for the carrier to finish entering the world.");

        LOG_INFO(
            "module",
            "RebornSpectator S.4: consumed one-time login request for account {}, carrier {}, target {}",
            accountId,
            carrierGuidLow,
            targetGuidLow);
    }

    void UpdateCarrierLogin(Player* observer, uint32 diff)
    {
        if (!observer || !observer->GetSession())
            return;

        RebornPendingCarrierLogin pending;
        bool ready = false;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _pendingCarrierLogins.find(observer->GetGUID().GetRawValue());
            if (itr == _pendingCarrierLogins.end())
                return;

            itr->second.elapsedMs += diff;
            if (itr->second.elapsedMs < g_RebornCarrierLoginDelayMs)
                return;

            pending = itr->second;
            _pendingCarrierLogins.erase(itr);
            ready = true;
        }

        if (!ready)
            return;

        if (observer->GetSession()->GetAccountId() != pending.accountId)
        {
            SendPrototypeMessage(observer, "|cffff5555Account binding changed; the one-time request was rejected.|r");
            return;
        }

        Player* target = ObjectAccessor::FindPlayerByLowGUID(pending.targetGuidLow);
        if (!target || !target->IsInWorld())
        {
            SendPrototypeMessage(observer, "|cffff5555The requested target is no longer online.|r");
            return;
        }

        if (!IsTargetAllowed(target))
        {
            SendPrototypeMessage(observer, "|cffff5555The requested real player has not enabled observation.|r");
            return;
        }

        if (!Start(observer, target, true))
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555The authenticated carrier request was consumed, but viewpoint startup failed. Queue a new request after correcting the reported condition.|r");
        }
    }

    void SetOwnConsent(Player* player, bool allowed)
    {
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            return;

        CharacterDatabase.DirectExecute(
            "INSERT INTO `reborn_spectator_consent` "
            "(`character_guid`, `allow_spectate`, `updated_at`) "
            "VALUES ({}, {}, UTC_TIMESTAMP()) "
            "ON DUPLICATE KEY UPDATE `allow_spectate` = VALUES(`allow_spectate`), "
            "`updated_at` = VALUES(`updated_at`)",
            player->GetGUID().GetCounter(),
            allowed ? 1 : 0);

        SendPrototypeMessage(
            player,
            allowed
                ? "|cff00ff00Observation permission is ON for this character.|r"
                : "|cffff5555Observation permission is OFF for this character.|r");
    }

    void ShowOwnConsent(Player* player)
    {
        if (!player || !player->GetSession())
            return;

        if (player->GetSession()->IsBot())
        {
            SendPrototypeMessage(player, "Consent: Playerbot session, allowed by default.");
            return;
        }

        QueryResult result = CharacterDatabase.Query(
            "SELECT `allow_spectate` FROM `reborn_spectator_consent` "
            "WHERE `character_guid` = {} LIMIT 1",
            player->GetGUID().GetCounter());

        bool const allowed = result && result->Fetch()[0].Get<uint8>() != 0;
        SendPrototypeMessage(player, allowed ? "Consent: ON." : "Consent: OFF (default).");
    }

    void RegisterCarrier(Player* player)
    {
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            return;

        uint32 const accountId = player->GetSession()->GetAccountId();
        uint32 const carrierGuidLow = player->GetGUID().GetCounter();

        QueryResult existing = CharacterDatabase.Query(
            "SELECT `carrier_guid`, `auto_created` FROM `reborn_spectator_carrier` "
            "WHERE `account_id` = {} LIMIT 1",
            accountId);
        if (existing && existing->Fetch()[1].Get<uint8>() != 0)
        {
            SendPrototypeMessage(
                player,
                "|cffff5555This account already owns an automatic S.4 carrier; manual replacement was refused.|r");
            return;
        }

        CharacterDatabase.DirectExecute(
            "DELETE FROM `reborn_spectator_request` WHERE `account_id` = {}",
            accountId);
        CharacterDatabase.DirectExecute(
            "INSERT INTO `reborn_spectator_carrier` "
            "(`account_id`, `carrier_guid`, `public_alias`, `enabled`, `auto_created`, `updated_at`) "
            "VALUES ({}, {}, 'Spectator', 1, 0, UTC_TIMESTAMP()) "
            "ON DUPLICATE KEY UPDATE `carrier_guid` = VALUES(`carrier_guid`), "
            "`enabled` = 1, `auto_created` = 0, `updated_at` = VALUES(`updated_at`)",
            accountId,
            carrierGuidLow);

        RebornCarrierRecord record;
        record.guidLow = carrierGuidLow;
        record.enabled = true;
        record.autoCreated = false;
        record.characterOwnedByAccount = true;
        CacheCarrier(accountId, record);

        SendPrototypeMessage(
            player,
            "|cff00ff00This character is now the dedicated manual S.4 carrier for the authenticated account.|r");
    }

    void UnregisterCarrier(Player* player)
    {
        if (!player || !player->GetSession())
            return;

        uint32 const accountId = player->GetSession()->GetAccountId();
        RebornCarrierRecord record;
        if (GetCarrierRecord(accountId, record) && record.autoCreated)
        {
            SendPrototypeMessage(
                player,
                "|cffff5555Automatic S.4 carriers cannot be unregistered from the client. Use the documented GM rollback procedure.|r");
            return;
        }

        CharacterDatabase.DirectExecute(
            "DELETE FROM `reborn_spectator_request` WHERE `account_id` = {}",
            accountId);
        CharacterDatabase.DirectExecute(
            "DELETE FROM `reborn_spectator_carrier` "
            "WHERE `account_id` = {} AND `carrier_guid` = {}",
            accountId,
            player->GetGUID().GetCounter());

        ClearCachedCarrier(accountId);
        SendPrototypeMessage(player, "Carrier binding and any pending request were removed for this account.");
    }

    void ShowCarrier(Player* player)
    {
        if (!player || !player->GetSession())
            return;

        uint32 const accountId = player->GetSession()->GetAccountId();
        QueryResult result = CharacterDatabase.Query(
            "SELECT `carrier_guid`, `public_alias`, `enabled`, `auto_created` "
            "FROM `reborn_spectator_carrier` WHERE `account_id` = {} LIMIT 1",
            accountId);

        if (!result)
        {
            SendPrototypeMessage(player, "Carrier: not registered for this account.");
            return;
        }

        Field* fields = result->Fetch();
        SendPrototypeMessage(
            player,
            "Carrier GUIDLow " + std::to_string(fields[0].Get<uint32>()) + ", public alias '" +
                fields[1].Get<std::string>() + "', enabled " +
                std::string(fields[2].Get<uint8>() != 0 ? "yes" : "no") + ", type " +
                std::string(fields[3].Get<uint8>() != 0 ? "automatic" : "manual") +
                ", hidden-from-enum " +
                std::string(g_RebornHideAutoCarrierFromEnum && fields[3].Get<uint8>() != 0 ? "yes." : "no."));
    }

    bool QueueRequest(Player* requester, Player* target)
    {
        if (!requester || !requester->GetSession() || !target || !target->GetSession())
            return false;

        if (!IsTargetAllowed(target))
        {
            SendPrototypeMessage(requester, "|cffff5555That real player has not enabled observation.|r");
            return false;
        }

        uint32 const accountId = requester->GetSession()->GetAccountId();
        QueryResult carrier = CharacterDatabase.Query(
            "SELECT `carrier_guid` FROM `reborn_spectator_carrier` "
            "WHERE `account_id` = {} AND `enabled` = 1 LIMIT 1",
            accountId);

        if (!carrier)
        {
            SendPrototypeMessage(
                requester,
                "|cffff5555No enabled carrier is registered for this account. Log in the dedicated character and use .rebornspec carrier first.|r");
            return false;
        }

        uint32 const carrierGuidLow = carrier->Fetch()[0].Get<uint32>();
        uint32 const targetGuidLow = target->GetGUID().GetCounter();
        if (carrierGuidLow == targetGuidLow || target->GetSession()->GetAccountId() == accountId)
        {
            SendPrototypeMessage(requester, "|cffff5555A carrier cannot observe a character on its own account.|r");
            return false;
        }

        CharacterDatabase.DirectExecute(
            "INSERT INTO `reborn_spectator_request` "
            "(`account_id`, `carrier_guid`, `target_guid`, `requested_at`, `expires_at`) "
            "VALUES ({}, {}, {}, UTC_TIMESTAMP(), "
            "DATE_ADD(UTC_TIMESTAMP(), INTERVAL {} SECOND)) "
            "ON DUPLICATE KEY UPDATE `carrier_guid` = VALUES(`carrier_guid`), "
            "`target_guid` = VALUES(`target_guid`), `requested_at` = VALUES(`requested_at`), "
            "`expires_at` = VALUES(`expires_at`)",
            accountId,
            carrierGuidLow,
            targetGuidLow,
            g_RebornRequestTtlSeconds);

        SendPrototypeMessage(
            requester,
            "|cff00ff00One-time request queued for target " + target->GetName() + " (GUIDLow " +
                std::to_string(targetGuidLow) + ").|r Log out, then enter the registered carrier before it expires.");
        return true;
    }

    void CancelRequest(Player* player)
    {
        if (!player || !player->GetSession())
            return;

        CharacterDatabase.DirectExecute(
            "DELETE FROM `reborn_spectator_request` WHERE `account_id` = {}",
            player->GetSession()->GetAccountId());
        SendPrototypeMessage(player, "Pending one-time request cancelled.");
    }

    void ShowRequest(Player* player)
    {
        if (!player || !player->GetSession())
            return;

        QueryResult result = CharacterDatabase.Query(
            "SELECT `carrier_guid`, `target_guid`, "
            "GREATEST(0, TIMESTAMPDIFF(SECOND, UTC_TIMESTAMP(), `expires_at`)) "
            "FROM `reborn_spectator_request` "
            "WHERE `account_id` = {} AND `expires_at` > UTC_TIMESTAMP() LIMIT 1",
            player->GetSession()->GetAccountId());

        if (!result)
        {
            SendPrototypeMessage(player, "Request: none or expired.");
            return;
        }

        Field* fields = result->Fetch();
        SendPrototypeMessage(
            player,
            "Request: carrier GUIDLow " + std::to_string(fields[0].Get<uint32>()) +
                ", target GUIDLow " + std::to_string(fields[1].Get<uint32>()) +
                ", expires in " + std::to_string(fields[2].Get<uint32>()) + " second(s).");
    }

private:
    bool LoadCarrierRecord(uint32 accountId, RebornCarrierRecord& record)
    {
        QueryResult result = CharacterDatabase.Query(
            "SELECT sc.`carrier_guid`, sc.`enabled`, sc.`auto_created`, "
            "IF(c.`guid` IS NULL, 0, IF(c.`account` = sc.`account_id`, 1, 0)) "
            "FROM `reborn_spectator_carrier` sc "
            "LEFT JOIN `characters` c ON c.`guid` = sc.`carrier_guid` "
            "WHERE sc.`account_id` = {} LIMIT 1",
            accountId);

        if (!result)
            return false;

        Field* fields = result->Fetch();
        record.guidLow = fields[0].Get<uint32>();
        record.enabled = fields[1].Get<uint8>() != 0;
        record.autoCreated = fields[2].Get<uint8>() != 0;
        record.characterOwnedByAccount = fields[3].Get<uint8>() != 0;
        return true;
    }

    bool GetCarrierRecord(uint32 accountId, RebornCarrierRecord& record)
    {
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _carrierCache.find(accountId);
            if (itr != _carrierCache.end())
            {
                record = itr->second;
                return true;
            }
        }

        if (!LoadCarrierRecord(accountId, record))
            return false;

        CacheCarrier(accountId, record);
        return true;
    }

    void CacheCarrier(uint32 accountId, RebornCarrierRecord const& record)
    {
        std::lock_guard<std::mutex> lock(_mutex);
        _carrierCache[accountId] = record;
    }

    void ClearCachedCarrier(uint32 accountId)
    {
        std::lock_guard<std::mutex> lock(_mutex);
        _carrierCache.erase(accountId);
    }

    bool CreateAutoCarrier(WorldSession* session)
    {
        if (!session)
            return false;

        uint32 const accountId = session->GetAccountId();
        if (!sObjectMgr->GetPlayerInfo(g_RebornAutoCarrierRace, g_RebornAutoCarrierClass) ||
            !Player::IsValidGender(g_RebornAutoCarrierGender))
        {
            LOG_ERROR(
                "module",
                "RebornSpectator S.4: invalid automatic carrier race/class/gender {}/{}/{}",
                g_RebornAutoCarrierRace,
                g_RebornAutoCarrierClass,
                g_RebornAutoCarrierGender);
            return false;
        }

        ObjectGuid::LowType guidLow = 0;
        std::string name;
        bool nameAvailable = false;
        uint8 lastNameResult = CHAR_NAME_SUCCESS;
        for (uint8 attempt = 0; attempt < 32; ++attempt)
        {
            guidLow = sObjectMgr->GetGenerator<HighGuid::Player>().Generate();
            name = "Rsp" + EncodeCarrierToken(guidLow);
            normalizePlayerName(name);

            lastNameResult = ObjectMgr::CheckPlayerName(name, true);
            if (lastNameResult != CHAR_NAME_SUCCESS ||
                sCharacterCache->GetCharacterGuidByName(name))
            {
                continue;
            }

            CharacterDatabasePreparedStatement* nameStatement =
                CharacterDatabase.GetPreparedStatement(CHAR_SEL_CHECK_NAME);
            nameStatement->SetData(0, name);
            if (CharacterDatabase.Query(nameStatement))
                continue;

            nameAvailable = true;
            break;
        }

        if (!nameAvailable || guidLow == 0 || name.empty())
        {
            LOG_ERROR(
                "module",
                "RebornSpectator S.4.1: failed to allocate an automatic carrier name for account {}; "
                "last candidate '{}', validation result {}",
                accountId,
                name,
                lastNameResult);
            return false;
        }

        CharacterCreateInfo createInfo(
            name,
            g_RebornAutoCarrierRace,
            g_RebornAutoCarrierClass,
            g_RebornAutoCarrierGender,
            0,
            0,
            0,
            0,
            0);

        std::shared_ptr<Player> carrier(new Player(session), [](Player* player)
            {
                if (player->HasAtLoginFlag(AT_LOGIN_FIRST))
                    player->CleanupsBeforeDelete();
                delete player;
            });

        carrier->GetMotionMaster()->Initialize();
        if (!carrier->Create(guidLow, &createInfo))
        {
            LOG_ERROR(
                "module",
                "RebornSpectator S.4: Player::Create failed for account {}, GUIDLow {}, name {}",
                accountId,
                guidLow,
                name);
            return false;
        }

        carrier->setCinematic(1);
        carrier->SetAtLoginFlag(AT_LOGIN_FIRST);

        CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
        carrier->SaveToDB(transaction, true, false);
        transaction->Append(
            "INSERT INTO `reborn_spectator_carrier` "
            "(`account_id`, `carrier_guid`, `public_alias`, `enabled`, `auto_created`, `created_at`, `updated_at`) "
            "VALUES ({}, {}, 'Spectator', 1, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())",
            accountId,
            guidLow);
        CharacterDatabase.CommitTransaction(transaction);

        sScriptMgr->OnPlayerCreate(carrier.get());
        sCharacterCache->AddCharacterCacheEntry(
            carrier->GetGUID(),
            accountId,
            carrier->GetName(),
            carrier->getGender(),
            carrier->getRace(),
            carrier->getClass(),
            carrier->GetLevel());

        RebornCarrierRecord record;
        record.guidLow = guidLow;
        record.enabled = true;
        record.autoCreated = true;
        record.characterOwnedByAccount = true;
        CacheCarrier(accountId, record);
        sWorld->UpdateRealmCharCount(accountId);

        LOG_INFO(
            "module",
            "RebornSpectator S.4.1: automatically created carrier {} (GUIDLow {}) for authenticated account {}; hidden={}",
            name,
            guidLow,
            accountId,
            g_RebornHideAutoCarrierFromEnum ? 1 : 0);
        return true;
    }

    static bool IsTargetAllowed(Player* target)
    {
        if (!target || !target->GetSession())
            return false;

        // Playerbot is a real Player instance with a bot WorldSession in this fork.
        if (target->GetSession()->IsBot())
            return true;

        QueryResult result = CharacterDatabase.Query(
            "SELECT `allow_spectate` FROM `reborn_spectator_consent` "
            "WHERE `character_guid` = {} LIMIT 1",
            target->GetGUID().GetCounter());
        return result && result->Fetch()[0].Get<uint8>() != 0;
    }

    bool HasSession(ObjectGuid observerGuid)
    {
        std::lock_guard<std::mutex> lock(_mutex);
        return _sessions.find(observerGuid.GetRawValue()) != _sessions.end();
    }

    bool IsObserver(ObjectGuid guid)
    {
        return HasSession(guid);
    }

    bool GetSession(ObjectGuid observerGuid, RebornSpectatorSession& session)
    {
        std::lock_guard<std::mutex> lock(_mutex);
        auto itr = _sessions.find(observerGuid.GetRawValue());
        if (itr == _sessions.end())
            return false;

        session = itr->second;
        return true;
    }

    bool TakeSession(ObjectGuid observerGuid, RebornSpectatorSession& session)
    {
        std::lock_guard<std::mutex> lock(_mutex);
        auto itr = _sessions.find(observerGuid.GetRawValue());
        if (itr == _sessions.end())
            return false;

        session = itr->second;
        _sessions.erase(itr);
        return true;
    }

    static void ApplyProtection(Player* observer, RebornSpectatorSession const& session)
    {
        if (!session.hadDisableMove)
            observer->SetUnitFlag(UNIT_FLAG_DISABLE_MOVE);
        if (!session.hadNonAttackable)
            observer->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
        if (!session.hadPacified)
            observer->SetUnitFlag(UNIT_FLAG_PACIFIED);
        if (!session.hadSilenced)
            observer->SetUnitFlag(UNIT_FLAG_SILENCED);
        if (!session.hadNotSelectable)
            observer->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        if (!session.hadRoot)
            observer->SetControlled(true, UNIT_STATE_ROOT);
    }

    static void RestoreProtection(Player* observer, RebornSpectatorSession const& session)
    {
        // A pending session has not applied these flags yet. Removing flags based only on the
        // original snapshot could otherwise erase a legitimate state acquired while teleporting.
        if (session.stage == RebornSpectatorStage::Active)
        {
            if (!session.hadRoot && observer->HasUnitState(UNIT_STATE_ROOT))
                observer->SetControlled(false, UNIT_STATE_ROOT);
            if (!session.hadDisableMove)
                observer->RemoveUnitFlag(UNIT_FLAG_DISABLE_MOVE);
            if (!session.hadNonAttackable)
                observer->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
            if (!session.hadPacified)
                observer->RemoveUnitFlag(UNIT_FLAG_PACIFIED);
            if (!session.hadSilenced)
                observer->RemoveUnitFlag(UNIT_FLAG_SILENCED);
            if (!session.hadNotSelectable)
                observer->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        }

        observer->SetPhaseMask(session.returnPhaseMask, true);

        if (session.wasGMVisible && !observer->isGMVisible())
        {
            observer->SetGMVisible(true);
            observer->UpdateObjectVisibility();
        }
    }

    static void RemoveViewpoint(Player* observer)
    {
        if (!observer)
            return;

        if (WorldObject* viewpoint = observer->GetViewpoint())
        {
            if (Unit* unit = viewpoint->ToUnit())
            {
                unit->RemoveAurasByType(SPELL_AURA_BIND_SIGHT, observer->GetGUID());
                observer->RemoveAurasDueToSpell(
                    REBORN_BIND_SIGHT_SPELL,
                    observer->GetGUID(),
                    (1 << EFFECT_1));

                if (observer->GetViewpoint())
                    observer->SetViewpoint(unit, false);
            }
        }

        observer->RemoveAurasDueToSpell(
            REBORN_BIND_SIGHT_SPELL,
            observer->GetGUID(),
            (1 << EFFECT_1));
    }

    std::mutex _mutex;
    std::map<uint64, RebornSpectatorSession> _sessions;
    std::map<uint64, RebornPendingCarrierLogin> _pendingCarrierLogins;
    std::map<uint32, RebornCarrierRecord> _carrierCache;
};

class RebornSpectatorConfigScript : public WorldScript
{
public:
    RebornSpectatorConfigScript() : WorldScript("RebornSpectatorConfigScript") { }

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        g_RebornSpectatorEnabled = sConfigMgr->GetOption<bool>("RebornSpectator.Enable", true);
        g_RebornReturnOnStop = sConfigMgr->GetOption<bool>("RebornSpectator.ReturnOnStop", true);
        g_RebornCarrierLoginEnabled = sConfigMgr->GetOption<bool>("RebornSpectator.CarrierLoginEnable", true);
        g_RebornAutoCarrierProvisionEnabled =
            sConfigMgr->GetOption<bool>("RebornSpectator.AutoCarrierProvisionEnable", false);
        g_RebornHideAutoCarrierFromEnum =
            sConfigMgr->GetOption<bool>("RebornSpectator.AutoCarrierHideFromCharacterEnum", false);

        uint32 retryMs = sConfigMgr->GetOption<uint32>("RebornSpectator.BindRetryMs", 250);
        uint32 timeoutMs = sConfigMgr->GetOption<uint32>("RebornSpectator.BindTimeoutMs", 7000);
        uint32 carrierDelayMs = sConfigMgr->GetOption<uint32>("RebornSpectator.CarrierLoginDelayMs", 1500);
        uint32 requestTtlSeconds = sConfigMgr->GetOption<uint32>("RebornSpectator.RequestTtlSeconds", 120);
        uint32 carrierRace = sConfigMgr->GetOption<uint32>("RebornSpectator.AutoCarrierRace", RACE_HUMAN);
        uint32 carrierClass = sConfigMgr->GetOption<uint32>("RebornSpectator.AutoCarrierClass", CLASS_WARRIOR);
        uint32 carrierGender = sConfigMgr->GetOption<uint32>("RebornSpectator.AutoCarrierGender", GENDER_MALE);

        g_RebornBindRetryMs = std::max<uint32>(100, std::min<uint32>(retryMs, 2000));
        g_RebornBindTimeoutMs = std::max<uint32>(1000, std::min<uint32>(timeoutMs, 30000));
        g_RebornCarrierLoginDelayMs = std::max<uint32>(500, std::min<uint32>(carrierDelayMs, 10000));
        g_RebornRequestTtlSeconds = std::max<uint32>(30, std::min<uint32>(requestTtlSeconds, 600));
        g_RebornAutoCarrierRace = uint8(std::min<uint32>(carrierRace, 255));
        g_RebornAutoCarrierClass = uint8(std::min<uint32>(carrierClass, 255));
        g_RebornAutoCarrierGender = uint8(std::min<uint32>(carrierGender, 255));
    }
};

class RebornSpectatorAccountScript : public AccountScript
{
public:
    RebornSpectatorAccountScript() : AccountScript("RebornSpectatorAccountScript") { }

    void OnBeforeAccountCharacterEnum(WorldSession* session) override
    {
        RebornSpectatorMgr::Instance().PrepareCharacterEnum(session);
    }

    bool CanAccountListCharacter(uint32 accountId, uint32 guidLow) override
    {
        return RebornSpectatorMgr::Instance().CanListCharacter(accountId, guidLow);
    }

    void OnAccountRealmCharacterCount(uint32 accountId, uint64& count) override
    {
        RebornSpectatorMgr::Instance().AdjustRealmCharacterCount(accountId, count);
    }

    bool CanAccountDeleteCharacter(uint32 accountId, uint32 guidLow) override
    {
        return RebornSpectatorMgr::Instance().CanDeleteCharacter(accountId, guidLow);
    }
};

class RebornSpectatorPlayerScript : public PlayerScript
{
public:
    RebornSpectatorPlayerScript() : PlayerScript("RebornSpectatorPlayerScript") { }

    void OnPlayerLogin(Player* player) override
    {
        RebornSpectatorMgr::Instance().HandlePlayerLogin(player);
    }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        RebornSpectatorMgr::Instance().UpdateCarrierLogin(player, diff);
        RebornSpectatorMgr::Instance().Update(player, diff);
    }

    void OnPlayerBeforeLogout(Player* player) override
    {
        RebornSpectatorMgr::Instance().HandleBeforeLogout(player);
    }

};

class RebornSpectatorCommandScript : public CommandScript
{
public:
    RebornSpectatorCommandScript() : CommandScript("RebornSpectatorCommandScript") { }

    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;

        static ChatCommandTable rebornSpecSubCommands =
        {
            { "start",         HandleStartCommand,         SEC_GAMEMASTER, Console::No },
            { "startguid",     HandleStartGuidCommand,     SEC_GAMEMASTER, Console::No },
            { "stop",          HandleStopCommand,          SEC_PLAYER,     Console::No },
            { "status",        HandleStatusCommand,        SEC_PLAYER,     Console::No },
            { "allow",         HandleAllowCommand,         SEC_PLAYER,     Console::No },
            { "deny",          HandleDenyCommand,          SEC_PLAYER,     Console::No },
            { "consent",       HandleConsentCommand,       SEC_PLAYER,     Console::No },
            { "carrier",       HandleCarrierCommand,       SEC_GAMEMASTER, Console::No },
            { "uncarrier",     HandleUncarrierCommand,     SEC_GAMEMASTER, Console::No },
            { "carrierstatus", HandleCarrierStatusCommand, SEC_GAMEMASTER, Console::No },
            { "queue",         HandleQueueCommand,         SEC_GAMEMASTER, Console::No },
            { "queueguid",     HandleQueueGuidCommand,     SEC_GAMEMASTER, Console::No },
            { "requeststatus", HandleRequestStatusCommand, SEC_GAMEMASTER, Console::No },
            { "cancelrequest", HandleCancelRequestCommand, SEC_GAMEMASTER, Console::No }
        };

        static ChatCommandTable commandTable =
        {
            { "rebornspec", rebornSpecSubCommands }
        };

        return commandTable;
    }

    static bool HandleStartCommand(ChatHandler* handler, Optional<std::string> targetName)
    {
        Player* observer = handler->GetSession()->GetPlayer();
        if (!observer)
            return true;

        Player* target = nullptr;
        if (targetName && !targetName->empty())
        {
            std::string normalizedName = *targetName;
            if (!normalizePlayerName(normalizedName))
            {
                SendPrototypeMessage(observer, "|cffff5555Invalid target name.|r");
                return true;
            }

            target = ObjectAccessor::FindPlayerByName(normalizedName);
        }
        else
        {
            target = observer->GetSelectedPlayer();
        }

        if (!target)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555Select a nearby Player/Playerbot or use .rebornspec start CharacterName.|r");
            return true;
        }

        RebornSpectatorMgr::Instance().Start(observer, target);
        return true;
    }

    static bool HandleStartGuidCommand(ChatHandler* handler, uint32 targetGuidLow)
    {
        Player* observer = handler->GetSession()->GetPlayer();
        if (!observer)
            return true;

        Player* target = ObjectAccessor::FindPlayerByLowGUID(targetGuidLow);
        if (!target)
        {
            SendPrototypeMessage(observer, "|cffff5555No online Player or Playerbot has that GUIDLow.|r");
            return true;
        }

        RebornSpectatorMgr::Instance().Start(observer, target);
        return true;
    }

    static bool HandleStopCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        Player* observer = handler->GetSession()->GetPlayer();
        if (observer)
            RebornSpectatorMgr::Instance().Stop(observer, true, "manual stop");
        return true;
    }

    static bool HandleStatusCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        Player* observer = handler->GetSession()->GetPlayer();
        if (observer)
            RebornSpectatorMgr::Instance().ShowStatus(observer);
        return true;
    }

    static bool HandleAllowCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().SetOwnConsent(player, true);
        return true;
    }

    static bool HandleDenyCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().SetOwnConsent(player, false);
        return true;
    }

    static bool HandleConsentCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().ShowOwnConsent(player);
        return true;
    }

    static bool HandleCarrierCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().RegisterCarrier(player);
        return true;
    }

    static bool HandleUncarrierCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().UnregisterCarrier(player);
        return true;
    }

    static bool HandleCarrierStatusCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().ShowCarrier(player);
        return true;
    }

    static bool HandleQueueCommand(ChatHandler* handler, Optional<std::string> targetName)
    {
        Player* requester = handler->GetSession()->GetPlayer();
        if (!requester)
            return true;

        if (!targetName || targetName->empty())
        {
            SendPrototypeMessage(requester, "|cffff5555Usage: .rebornspec queue CharacterName|r");
            return true;
        }

        std::string normalizedName = *targetName;
        if (!normalizePlayerName(normalizedName))
        {
            SendPrototypeMessage(requester, "|cffff5555Invalid target name.|r");
            return true;
        }

        Player* target = ObjectAccessor::FindPlayerByName(normalizedName);
        if (!target)
        {
            SendPrototypeMessage(requester, "|cffff5555No online Player or Playerbot has that name.|r");
            return true;
        }

        RebornSpectatorMgr::Instance().QueueRequest(requester, target);
        return true;
    }

    static bool HandleQueueGuidCommand(ChatHandler* handler, uint32 targetGuidLow)
    {
        Player* requester = handler->GetSession()->GetPlayer();
        if (!requester)
            return true;

        Player* target = ObjectAccessor::FindPlayerByLowGUID(targetGuidLow);
        if (!target)
        {
            SendPrototypeMessage(requester, "|cffff5555No online Player or Playerbot has that GUIDLow.|r");
            return true;
        }

        RebornSpectatorMgr::Instance().QueueRequest(requester, target);
        return true;
    }

    static bool HandleRequestStatusCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().ShowRequest(player);
        return true;
    }

    static bool HandleCancelRequestCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().CancelRequest(player);
        return true;
    }
};
}

void AddRebornSpectatorScripts()
{
    new RebornSpectatorConfigScript();
    new RebornSpectatorAccountScript();
    new RebornSpectatorPlayerScript();
    new RebornSpectatorCommandScript();
}
