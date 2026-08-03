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
#include "MoveSplineInit.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Util.h"
#include "World.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cmath>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

namespace
{
constexpr uint32 REBORN_BIND_SIGHT_SPELL = 6277;
constexpr uint32 REBORN_CHECK_INTERVAL_MS = 250;
constexpr char REBORN_ROSTER_ADDON_PREFIX[] = "RBSPEC";
constexpr std::size_t REBORN_ROOM_CHAT_MAX_BYTES = 120;
constexpr uint32 REBORN_ROOM_CHAT_COOLDOWN_MS = 1000;
constexpr uint32 REBORN_ASSIST_INVITE_TTL_SECONDS = 30;
constexpr uint32 REBORN_ASSIST_MOVE_COOLDOWN_MS = 120;
constexpr float REBORN_ASSIST_STEP_DISTANCE = 3.0f;
constexpr float REBORN_ASSIST_TURN_RADIANS = 0.26179939f; // 15 degrees

bool g_RebornSpectatorEnabled = true;
bool g_RebornReturnOnStop = true;
bool g_RebornCarrierLoginEnabled = true;
bool g_RebornAutoLeaveGroupAuthenticatedCarrier = true;
bool g_RebornPreloginBridgeEnabled = false;
bool g_RebornAutoCarrierProvisionEnabled = false;
bool g_RebornAutoCarrierOnlyForEmptyAccount = true;
bool g_RebornHideAutoCarrierFromEnum = false;
uint8 g_RebornAutoCarrierRace = RACE_HUMAN;
uint8 g_RebornAutoCarrierClass = CLASS_WARRIOR;
uint8 g_RebornAutoCarrierGender = GENDER_MALE;
uint32 g_RebornBindRetryMs = 250;
uint32 g_RebornBindTimeoutMs = 7000;
uint32 g_RebornCarrierLoginDelayMs = 1500;
uint32 g_RebornRequestTtlSeconds = 120;
uint32 g_RebornPreloginRequestTtlMs = 15000;
uint32 g_RebornCarrierAliveWaitMs = 600000;
float g_RebornPreloginCarrierOffset = 12.0f;

enum class RebornSpectatorStage : uint8
{
    PendingViewpoint,
    Active
};

enum class RebornSpectatorChatSource : char
{
    Target = 'T',
    Observer = 'O',
    Playerbot = 'B',
    Ai = 'A'
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
    bool hadCanFly = false;
    bool protectionApplied = false;

    uint32 totalPendingMs = 0;
    uint32 retryTimerMs = 0;
    uint32 activeCheckTimerMs = 0;
};

struct RebornPendingCarrierLogin
{
    uint32 accountId = 0;
    uint32 targetGuidLow = 0;
    uint32 elapsedMs = 0;
    uint32 aliveWaitMs = 0;
    bool waitNoticeSent = false;
    bool returnCaptured = false;
    bool worldPrepared = false;
    uint32 returnMapId = 0;
    float returnX = 0.0f;
    float returnY = 0.0f;
    float returnZ = 0.0f;
    float returnO = 0.0f;
    uint32 returnPhaseMask = PHASEMASK_NORMAL;
    bool returnCanFly = false;
};

struct RebornPendingReturn
{
    uint32 mapId = 0;
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float o = 0.0f;
    uint32 retryTimerMs = 0;
    uint32 totalElapsedMs = 0;
    uint32 attempts = 0;
    bool hadCanFly = false;
};

struct RebornResumeWatch
{
    ObjectGuid observerGuid;
    ObjectGuid targetGuid;
    std::chrono::steady_clock::time_point expiresAt;
    bool resurrectionSeen = false;
    uint32 retryTimerMs = 0;
};

struct RebornPreloginRequest
{
    uint32 accountId = 0;
    uint32 carrierGuidLow = 0;
    uint32 targetGuidLow = 0;
    uint32 requestedGuidLow = 0;
    std::chrono::steady_clock::time_point expiresAt;
    bool loginArmed = false;
    bool worldPrepared = false;
    bool preparationRejected = false;
    bool returnCaptured = false;

    uint32 returnMapId = 0;
    float returnX = 0.0f;
    float returnY = 0.0f;
    float returnZ = 0.0f;
    float returnO = 0.0f;
    uint32 returnPhaseMask = PHASEMASK_NORMAL;
    bool returnCanFly = false;
};

struct RebornCarrierRecord
{
    uint32 guidLow = 0;
    bool enabled = false;
    bool autoCreated = false;
    bool characterOwnedByAccount = false;
};

enum class RebornAssistState : char
{
    Pending = 'P',
    Granted = 'G'
};

struct RebornAssistHandshake
{
    ObjectGuid targetGuid;
    ObjectGuid observerGuid;
    RebornAssistState state = RebornAssistState::Pending;
    std::chrono::steady_clock::time_point expiresAt;
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

bool DecodePreloginSignal(std::string const& name, uint32& targetGuidLow)
{
    // "Rq" plus ten alternating consonant/vowel digits is exactly twelve characters. Alternating
    // disjoint alphabets can represent every uint32 GUIDLow while never producing three equal
    // consecutive letters, so the stock 3.3.5 Glue name guard allows the authenticated control
    // request to reach this hook. The reserved shape never creates a database character.
    if (name.size() != 12 ||
        std::tolower(static_cast<unsigned char>(name[0])) != 'r' ||
        std::tolower(static_cast<unsigned char>(name[1])) != 'q')
    {
        return false;
    }

    static std::string const Consonants = "bcdfghjklmnpqrstvwxyz";
    static std::string const Vowels = "aeiou";
    uint64 value = 0;
    for (std::size_t index = 2; index < name.size(); ++index)
    {
        char const decoded = char(std::tolower(static_cast<unsigned char>(name[index])));
        std::size_t const tokenIndex = index - 2;
        std::string const& alphabet = (tokenIndex % 2) == 0 ? Consonants : Vowels;
        std::size_t const digit = alphabet.find(decoded);
        if (digit == std::string::npos)
            return false;

        value = value * alphabet.size() + digit;
        if (value > uint64(std::numeric_limits<uint32>::max()))
            return false;
    }

    targetGuidLow = uint32(value);
    return true;
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

std::string BuildWatcherLabel(Player* observer)
{
    if (!observer)
        return "<offline observer>";

    std::string label = observer->GetName();
    if (observer->GetSession())
        label += " / account #" + std::to_string(observer->GetSession()->GetAccountId());
    return label;
}

void SendRosterAddonPayload(Player* receiver, std::string const& payload)
{
    if (!receiver || !receiver->GetSession() || receiver->GetSession()->IsBot())
        return;

    std::string const message = std::string(REBORN_ROSTER_ADDON_PREFIX) + "\t" + payload;
    WorldPacket data(SMSG_MESSAGECHAT, 1 + 4 + 8 + 4 + 8 + 4 + 1 + message.size() + 1);
    data << uint8(CHAT_MSG_WHISPER);
    data << uint32(LANG_ADDON);
    data << uint64(receiver->GetGUID().GetRawValue());
    data << uint32(0);
    data << uint64(receiver->GetGUID().GetRawValue());
    data << uint32(message.size() + 1);
    data << message;
    data << uint8(0);
    receiver->GetSession()->SendPacket(&data);
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

        if (g_RebornAutoCarrierOnlyForEmptyAccount)
        {
            QueryResult characterCountResult = CharacterDatabase.Query(
                "SELECT COUNT(*) FROM `characters` WHERE `account` = {}",
                accountId);
            uint64 const characterCount = characterCountResult
                ? characterCountResult->Fetch()[0].Get<uint64>()
                : 0;

            if (!characterCountResult)
            {
                LOG_ERROR(
                    "module",
                    "RebornSpectator S.7.8: failed to count characters for account {}; automatic carrier creation was refused",
                    accountId);
                return;
            }

            if (characterCount > 0)
            {
                LOG_INFO(
                    "module",
                    "RebornSpectator S.7.8: account {} already owns {} character(s); use a selected existing character instead of provisioning Rsp",
                    accountId,
                    characterCount);
                return;
            }
        }

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

    bool HandleAuthenticatedPreloginSignal(WorldSession* session, std::string const& signalName)
    {
        uint32 targetGuidLow = 0;
        if (!DecodePreloginSignal(signalName, targetGuidLow))
            return false;

        if (!session || session->IsBot() || !g_RebornSpectatorEnabled ||
            !g_RebornCarrierLoginEnabled || !g_RebornPreloginBridgeEnabled ||
            targetGuidLow == 0)
        {
            if (session)
                session->SendCharCreate(CHAR_CREATE_FAILED);
            return true;
        }

        uint32 const accountId = session->GetAccountId();
        RebornCarrierRecord record;
        if (!GetCarrierRecord(accountId, record) || !record.enabled || !record.autoCreated ||
            !record.characterOwnedByAccount)
        {
            session->SendCharCreate(CHAR_CREATE_FAILED);
            LOG_WARN(
                "module",
                "RebornSpectator S.5.10: rejected authenticated pre-login signal for account {}, target {}",
                accountId,
                targetGuidLow);
            return true;
        }

        RebornPreloginRequest request;
        request.accountId = accountId;
        request.carrierGuidLow = record.guidLow;
        request.targetGuidLow = targetGuidLow;
        request.expiresAt =
            std::chrono::steady_clock::now() + std::chrono::milliseconds(g_RebornPreloginRequestTtlMs);

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _preloginRequests[accountId] = request;
        }

        // The packet was consumed as a control request; no character is created. CHAR_CREATE_SUCCESS
        // asks the stock Glue client to refresh its existing character list, which S.5.10 uses as
        // the acknowledgement before entering one ordinary visible trigger character.
        session->SendCharCreate(CHAR_CREATE_SUCCESS);
        LOG_INFO(
            "module",
            "RebornSpectator S.5.10: authenticated pre-login signal accepted for account {}, carrier {}, target {}",
            accountId,
            record.guidLow,
            targetGuidLow);
        return true;
    }

    void SelectAuthenticatedLoginCharacter(WorldSession* session, ObjectGuid& playerGuid)
    {
        if (!session || session->IsBot() || !g_RebornPreloginBridgeEnabled)
            return;

        uint32 const accountId = session->GetAccountId();
        RebornPreloginRequest request;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _preloginRequests.find(accountId);
            if (itr == _preloginRequests.end())
                return;
            request = itr->second;
        }

        bool const expired = std::chrono::steady_clock::now() >= request.expiresAt;
        RebornCarrierRecord record;
        if (expired || !GetCarrierRecord(accountId, record) || !record.enabled ||
            !record.autoCreated || !record.characterOwnedByAccount ||
            record.guidLow != request.carrierGuidLow)
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _preloginRequests.erase(accountId);
            playerGuid = ObjectGuid::Empty;
            LOG_WARN(
                "module",
                "RebornSpectator S.5.10: pre-login request became invalid before character selection for account {}",
                accountId);
            return;
        }

        request.requestedGuidLow = playerGuid.GetCounter();
        request.loginArmed = true;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _preloginRequests[accountId] = request;
        }

        playerGuid = ObjectGuid::Create<HighGuid::Player>(record.guidLow);
        LOG_INFO(
            "module",
            "RebornSpectator S.5.10: account {} visible login trigger {} redirected to hidden carrier {}",
            accountId,
            request.requestedGuidLow,
            record.guidLow);
    }

    void PrepareAuthenticatedCarrierWorld(Player* carrier)
    {
        if (!carrier || !carrier->GetSession() || carrier->GetSession()->IsBot() ||
            !g_RebornPreloginBridgeEnabled)
        {
            return;
        }

        uint32 const accountId = carrier->GetSession()->GetAccountId();
        RebornPreloginRequest request;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _preloginRequests.find(accountId);
            if (itr == _preloginRequests.end() || !itr->second.loginArmed ||
                itr->second.carrierGuidLow != carrier->GetGUID().GetCounter())
            {
                return;
            }
            request = itr->second;
        }

        Player* target = nullptr;
        if (std::chrono::steady_clock::now() >= request.expiresAt ||
            !ResolveAllowedPreloginTarget(accountId, request.targetGuidLow, target))
        {
            request.preparationRejected = true;
            request.worldPrepared = false;
            {
                std::lock_guard<std::mutex> lock(_mutex);
                _preloginRequests[accountId] = request;
            }
            LOG_WARN(
                "module",
                "RebornSpectator S.5.10: target {} became invalid before carrier LoadFromDB completed for account {}",
                request.targetGuidLow,
                accountId);
            return;
        }

        Map* destinationMap = target->FindMap();
        if (!destinationMap || destinationMap->Instanceable() || target->GetInstanceId() != 0)
        {
            request.preparationRejected = true;
            request.worldPrepared = false;
            {
                std::lock_guard<std::mutex> lock(_mutex);
                _preloginRequests[accountId] = request;
            }
            LOG_WARN(
                "module",
                "RebornSpectator S.5.10: target {} map is not eligible for one-load preparation; account {}",
                request.targetGuidLow,
                accountId);
            return;
        }

        request.returnMapId = carrier->GetMapId();
        request.returnX = carrier->GetPositionX();
        request.returnY = carrier->GetPositionY();
        request.returnZ = carrier->GetPositionZ();
        request.returnO = carrier->GetOrientation();
        request.returnPhaseMask = carrier->GetPhaseMask();
        request.returnCanFly = carrier->CanFly();
        request.returnCaptured = true;

        // Never move a corpse or ghost to the observation target during the pre-login bridge.
        // Doing so would allow a later graveyard release/resurrection to retain the target's
        // location. Keep the authenticated request in memory and start only after the player has
        // resurrected through the normal game flow at the original location.
        if (!carrier->IsAlive())
        {
            request.worldPrepared = false;
            request.expiresAt =
                std::chrono::steady_clock::now() + std::chrono::milliseconds(g_RebornCarrierAliveWaitMs);
            {
                std::lock_guard<std::mutex> lock(_mutex);
                _preloginRequests[accountId] = request;
            }
            LOG_INFO(
                "module",
                "RebornSpectator S.7.8.4: dead/ghost carrier {} stayed at its original location; target {} remains queued until normal resurrection",
                request.carrierGuidLow,
                request.targetGuidLow);
            return;
        }

        Position const nearPosition =
            target->GetNearPosition(g_RebornPreloginCarrierOffset, 3.14159265f);
        // The physical carrier may be prepared beside a flying or high-altitude target. Grant
        // temporary flight before relocation so it cannot fall during the login/viewpoint gap.
        carrier->SetCanFly(true);
        carrier->ResetMap();
        carrier->Relocate(
            nearPosition.GetPositionX(),
            nearPosition.GetPositionY(),
            nearPosition.GetPositionZ(),
            target->GetOrientation());
        carrier->SetMap(destinationMap);
        carrier->SetPhaseMask(target->GetPhaseMask(), false);

        request.worldPrepared = true;
        request.expiresAt =
            std::chrono::steady_clock::now() + std::chrono::milliseconds(g_RebornPreloginRequestTtlMs);
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _preloginRequests[accountId] = request;
        }

        LOG_INFO(
            "module",
            "RebornSpectator S.5.10: hidden carrier {} prepared on target map {} before SMSG_LOGIN_VERIFY_WORLD; target {}",
            request.carrierGuidLow,
            carrier->GetMapId(),
            request.targetGuidLow);
    }

    bool Start(
        Player* observer,
        Player* target,
        bool authenticatedCarrierLogin = false,
        RebornPreloginRequest const* preparedLogin = nullptr)
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

        // Never revive a carrier for a target that is already dead. Observed targets retain the
        // normal alive requirement and are never resurrected by the spectator system.
        if (!target->IsAlive())
        {
            SendPrototypeMessage(observer, "|cffff5555The selected observation target must be alive.|r");
            return false;
        }

        if (!observer->IsAlive())
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555Observer carrier is dead/ghost: observation is blocked. Resurrect normally; the authenticated target will resume automatically.|r");
            ChatHandler(observer->GetSession()).SendNotification(
                "Dead/ghost carrier cannot observe. Resurrect normally; observation will resume automatically.");
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

        // A character chosen on CharacterSelect may still belong to a normal party from its
        // previous play session. Login-screen observation is an explicit one-shot transition, so
        // detach only that authenticated carrier before applying spectator protection. Manual GM
        // starts retain the original requirement to leave the group explicitly.
        if (authenticatedCarrierLogin && g_RebornAutoLeaveGroupAuthenticatedCarrier && observer->GetGroup())
        {
            observer->RemoveFromGroup(GROUP_REMOVEMETHOD_LEAVE);

            if (!observer->GetGroup())
            {
                SendPrototypeMessage(
                    observer,
                    "|cff00ff00Authenticated spectator carrier left its previous group before observation.|r");
                LOG_INFO(
                    "module",
                    "RebornSpectator S.7.8.3: authenticated carrier {} ({}) left its previous group before starting viewpoint on target {} ({})",
                    observer->GetName(),
                    observer->GetGUID().GetCounter(),
                    target->GetName(),
                    target->GetGUID().GetCounter());
            }
        }

        if (observer->IsInCombat() || observer->GetVehicle() || observer->IsInFlight() || observer->IsMounted() ||
            observer->GetGroup())
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555Before testing, leave combat/group/vehicle/flight and dismount the observer carrier.|r");
            return false;
        }

        if (!observer->CanFreeMove())
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555The selected observer character must be able to move freely before spectating starts.|r");
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
        if (preparedLogin && preparedLogin->returnCaptured)
        {
            session.returnMapId = preparedLogin->returnMapId;
            session.returnX = preparedLogin->returnX;
            session.returnY = preparedLogin->returnY;
            session.returnZ = preparedLogin->returnZ;
            session.returnO = preparedLogin->returnO;
            session.returnPhaseMask = preparedLogin->returnPhaseMask;
        }
        else
        {
            session.returnMapId = observer->GetMapId();
            session.returnX = observer->GetPositionX();
            session.returnY = observer->GetPositionY();
            session.returnZ = observer->GetPositionZ();
            session.returnO = observer->GetOrientation();
            session.returnPhaseMask = observer->GetPhaseMask();
        }
        session.targetMapId = target->GetMapId();
        session.targetInstanceId = target->GetInstanceId();
        session.wasGMVisible = observer->isGMVisible();
        session.hadRoot = observer->HasUnitState(UNIT_STATE_ROOT);
        session.hadDisableMove = observer->HasUnitFlag(UNIT_FLAG_DISABLE_MOVE);
        session.hadNonAttackable = observer->HasUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
        session.hadPacified = observer->HasUnitFlag(UNIT_FLAG_PACIFIED);
        session.hadSilenced = observer->HasUnitFlag(UNIT_FLAG_SILENCED);
        session.hadNotSelectable = observer->HasUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        session.hadCanFly = preparedLogin && preparedLogin->returnCaptured
            ? preparedLogin->returnCanFly
            : observer->CanFly();
        session.protectionApplied = true;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            // Starting any observation is an explicit newer choice. It
            // supersedes a death-resume record for an older target. During
            // S.6.14 automatic resume this simply consumes its own record.
            _resumeWatches.erase(observer->GetGUID().GetRawValue());
            _sessions.emplace(observer->GetGUID().GetRawValue(), session);
        }

        if (session.wasGMVisible)
        {
            observer->SetGMVisible(false);
            observer->UpdateObjectVisibility();
        }

        // Protection starts before any relocation. This closes the old high-altitude window in
        // which the physical carrier could fall, die, and later revive at the observed target.
        ApplyProtection(observer, session);
        observer->CombatStopWithPets();
        observer->SetPhaseMask(target->GetPhaseMask(), true);

        SendPrototypeMessage(
            observer,
            "Preparing direct viewpoint for |cffffff00" + target->GetName() + "|r (GUIDLow " +
                std::to_string(target->GetGUID().GetCounter()) + ").");

        if (!preparedLogin || !preparedLogin->worldPrepared)
        {
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
        }
        else
        {
            SendPrototypeMessage(
                observer,
                "|cff00ff00S.5.10 pre-login world preparation accepted; no second world transfer was requested.|r");
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

        ClearAssistForParticipant(observer->GetGUID());
        RemoveViewpoint(observer);
        RestoreProtection(observer, session);

        if (returnToOrigin && g_RebornReturnOnStop && observer->IsInWorld())
        {
            QueueReturn(observer, session);
            ProcessPendingReturn(observer, 0, true);
        }

        std::string message = "|cffffff00Prototype stopped";
        if (!reason.empty())
            message += " (" + reason + ")";
        message += ". Camera control belongs to the observer again.|r";
        SendPrototypeMessage(observer, message);

        if (session.stage == RebornSpectatorStage::Active)
        {
            ClearWatcherRoster(observer);
            if (Player* target = ObjectAccessor::FindPlayer(session.targetGuid))
            {
                if (target->GetSession() && !target->GetSession()->IsBot())
                {
                    SendPrototypeMessage(
                        target,
                        "|cffffff00Viewer left:|r " + BuildWatcherLabel(observer) + ".");
                }
            }
            PushWatcherRoster(session.targetGuid);
        }

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

        ProcessPendingReturn(observer, diff, false);
        UpdateResumeWatch(observer, diff);

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

        if (target->GetSession() && !target->GetSession()->IsBot())
        {
            SendPrototypeMessage(
                target,
                "|cff00ff00Viewer joined:|r " + BuildWatcherLabel(observer) +
                    ". Use |cffffff00.rebornspec watchers|r to inspect the active read-only roster.");
        }
        PushWatcherRoster(target->GetGUID());

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

    void ShowWatchers(Player* requester)
    {
        if (!requester)
            return;

        ObjectGuid targetGuid = requester->GetGUID();
        RebornSpectatorSession requesterSession;
        bool const requesterIsObserver = GetSession(requester->GetGUID(), requesterSession);
        if (requesterIsObserver)
            targetGuid = requesterSession.targetGuid;

        PushWatcherRoster(targetGuid);

        std::vector<ObjectGuid> observerGuids;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            for (auto const& pair : _sessions)
            {
                RebornSpectatorSession const& session = pair.second;
                if (session.stage == RebornSpectatorStage::Active && session.targetGuid == targetGuid)
                    observerGuids.push_back(session.observerGuid);
            }
        }

        Player* target = ObjectAccessor::FindPlayer(targetGuid);
        std::string const targetName = target ? target->GetName() : "<offline target>";
        if (observerGuids.empty())
        {
            SendPrototypeMessage(
                requester,
                "S.6.1 roster: no active viewers for |cffffff00" + targetName + "|r.");
            return;
        }

        SendPrototypeMessage(
            requester,
            "S.6.1 roster for |cffffff00" + targetName + "|r: " +
                std::to_string(observerGuids.size()) + " active viewer(s).");

        uint32 row = 0;
        for (ObjectGuid observerGuid : observerGuids)
        {
            ++row;
            Player* observer = ObjectAccessor::FindPlayer(observerGuid);
            SendPrototypeMessage(
                requester,
                "  " + std::to_string(row) + ". " + BuildWatcherLabel(observer));
        }
    }

    void RefreshWatcherRoster(Player* requester)
    {
        if (!requester)
            return;

        ObjectGuid targetGuid = requester->GetGUID();
        RebornSpectatorSession requesterSession;
        if (GetSession(requester->GetGUID(), requesterSession))
            targetGuid = requesterSession.targetGuid;
        PushWatcherRoster(targetGuid);
        PushAssistHandshake(targetGuid, requester);
    }

    void PushWatcherRoster(ObjectGuid targetGuid)
    {
        std::vector<ObjectGuid> observerGuids;
        uint32 generation = 0;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            generation = ++_rosterGeneration;
            for (auto const& pair : _sessions)
            {
                RebornSpectatorSession const& session = pair.second;
                if (session.stage == RebornSpectatorStage::Active && session.targetGuid == targetGuid)
                    observerGuids.push_back(session.observerGuid);
            }
        }

        Player* target = ObjectAccessor::FindPlayer(targetGuid);
        std::string const targetName = target ? target->GetName() : "<offline>";
        std::vector<Player*> recipients;
        if (target && target->GetSession() && !target->GetSession()->IsBot())
            recipients.push_back(target);

        struct RosterRow
        {
            uint32 guidLow = 0;
            uint32 accountId = 0;
            std::string name;
        };
        std::vector<RosterRow> rows;

        for (ObjectGuid observerGuid : observerGuids)
        {
            Player* observer = ObjectAccessor::FindPlayer(observerGuid);
            if (!observer || !observer->GetSession() || observer->GetSession()->IsBot())
                continue;

            RosterRow row;
            row.guidLow = observer->GetGUID().GetCounter();
            row.accountId = observer->GetSession()->GetAccountId();
            row.name = observer->GetName();
            rows.push_back(row);

            if (std::find(recipients.begin(), recipients.end(), observer) == recipients.end())
                recipients.push_back(observer);
        }

        std::string const beginPayload =
            "B|" + std::to_string(generation) + "|" + std::to_string(targetGuid.GetCounter()) + "|" +
            targetName + "|" + std::to_string(rows.size());
        std::string const endPayload = "E|" + std::to_string(generation);

        for (Player* recipient : recipients)
        {
            SendRosterAddonPayload(recipient, beginPayload);
            for (RosterRow const& row : rows)
            {
                SendRosterAddonPayload(
                    recipient,
                    "R|" + std::to_string(generation) + "|" + std::to_string(row.guidLow) + "|" +
                        row.name + "|" + std::to_string(row.accountId));
            }
            SendRosterAddonPayload(recipient, endPayload);
        }
    }

    void ClearWatcherRoster(Player* observer)
    {
        if (!observer)
            return;

        uint32 generation = 0;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            generation = ++_rosterGeneration;
        }
        SendRosterAddonPayload(observer, "C|" + std::to_string(generation));
    }

    void HandleBeforeLogout(Player* player)
    {
        if (!player)
            return;

        ClearAssistForParticipant(player->GetGUID());
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _pendingCarrierLogins.erase(player->GetGUID().GetRawValue());
            _resumeWatches.erase(player->GetGUID().GetRawValue());
            for (auto itr = _resumeWatches.begin(); itr != _resumeWatches.end();)
            {
                if (itr->second.targetGuid == player->GetGUID())
                    itr = _resumeWatches.erase(itr);
                else
                    ++itr;
            }
            if (player->GetSession())
                _preloginRequests.erase(player->GetSession()->GetAccountId());
        }

        if (HasSession(player->GetGUID()))
            Stop(player, true, "observer logout");

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _pendingReturns.erase(player->GetGUID().GetRawValue());
        }
    }

    void HandlePlayerDeath(Player* killed, char const* cause)
    {
        if (!killed)
            return;

        std::vector<ObjectGuid> observers;
        bool killedWasObserver = false;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            killedWasObserver =
                _sessions.find(killed->GetGUID().GetRawValue()) !=
                _sessions.end();
            for (auto const& pair : _sessions)
            {
                RebornSpectatorSession const& session = pair.second;
                if (session.targetGuid == killed->GetGUID())
                {
                    observers.push_back(session.observerGuid);
                    RebornResumeWatch resume;
                    resume.observerGuid = session.observerGuid;
                    resume.targetGuid = killed->GetGUID();
                    resume.expiresAt =
                        std::chrono::steady_clock::now() +
                        std::chrono::minutes(10);
                    _resumeWatches[session.observerGuid.GetRawValue()] =
                        resume;
                }
            }
        }

        // Death can remove charm/control fields before the ordinary 250 ms
        // spectator poll runs. End every viewpoint synchronously while both
        // Player objects are still valid, so native mover ownership cannot be
        // left pointing at a dead target.
        for (ObjectGuid observerGuid : observers)
        {
            if (Player* observer = ObjectAccessor::FindPlayer(observerGuid))
            {
                Stop(
                    observer,
                    true,
                    std::string("controlled target died") +
                        (cause && *cause ? " (" + std::string(cause) + ")" : ""));
            }
        }

        if (killedWasObserver && HasSession(killed->GetGUID()))
        {
            // An authenticated observer must never be allowed to keep a corpse or
            // release at the remote target position. Protection is applied before
            // teleport, but this invariant also closes forced-kill and edge-case
            // damage paths: revive only as an internal recovery step, then use the
            // saved origin from the active session.
            killed->ResurrectPlayer(1.0f, false);
            killed->SpawnCorpseBones();
            Stop(killed, true, "observer died; forced safe return");
            SendPrototypeMessage(
                killed,
                "|cffff5555S.7.8.4 safety recovery: the observer carrier died during observation and was returned to its saved origin. Remote release/revival is not permitted.|r");
            if (killed->GetSession())
            {
                ChatHandler(killed->GetSession()).SendNotification(
                    "Spectator safety recovery: returned to the carrier's original position.");
            }
        }
        else
            ClearAssistForParticipant(killed->GetGUID());
    }

    void HandlePlayerResurrect(Player* resurrected)
    {
        if (!resurrected)
            return;

        bool retainedCarrierRequest = false;
        std::vector<ObjectGuid> observers;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto carrierItr = _pendingCarrierLogins.find(resurrected->GetGUID().GetRawValue());
            if (carrierItr != _pendingCarrierLogins.end())
            {
                carrierItr->second.elapsedMs = g_RebornCarrierLoginDelayMs;
                carrierItr->second.aliveWaitMs = 0;
                // A normal resurrection can move the player from corpse/ghost
                // coordinates to a graveyard or resurrection point. That live
                // location becomes the only legitimate return origin.
                carrierItr->second.returnCaptured = true;
                carrierItr->second.worldPrepared = false;
                carrierItr->second.returnMapId = resurrected->GetMapId();
                carrierItr->second.returnX = resurrected->GetPositionX();
                carrierItr->second.returnY = resurrected->GetPositionY();
                carrierItr->second.returnZ = resurrected->GetPositionZ();
                carrierItr->second.returnO = resurrected->GetOrientation();
                carrierItr->second.returnPhaseMask = resurrected->GetPhaseMask();
                carrierItr->second.returnCanFly = resurrected->CanFly();
                retainedCarrierRequest = true;
            }

            for (auto& pair : _resumeWatches)
            {
                if (pair.second.targetGuid != resurrected->GetGUID())
                    continue;

                pair.second.resurrectionSeen = true;
                pair.second.retryTimerMs = 0;
                observers.push_back(pair.second.observerGuid);
            }
        }

        if (retainedCarrierRequest)
        {
            SendPrototypeMessage(
                resurrected,
                "|cff00ff00S.7.8.4: the observer carrier is alive again. The retained observation target will reconnect automatically.|r");
            if (resurrected->GetSession())
            {
                ChatHandler(resurrected->GetSession()).SendNotification(
                    "Resurrection confirmed; retained observation will continue automatically.");
            }
        }

        for (ObjectGuid observerGuid : observers)
        {
            if (Player* observer = ObjectAccessor::FindPlayer(observerGuid))
            {
                SendPrototypeMessage(
                    observer,
                    "|cff00ff00S.6.14: the previous target has resurrected. Read-only observation will reconnect automatically; assistance control still requires a new invitation and acceptance.|r");
            }
        }

        if (!observers.empty() && resurrected->GetSession() &&
            !resurrected->GetSession()->IsBot())
        {
            SendPrototypeMessage(
                resurrected,
                "|cff00ff00S.6.14: previous viewer(s) may reconnect automatically. Movement assistance was not restored; invite and obtain acceptance again if help is still wanted.|r");
        }
    }

    bool StartPreparedPrelogin(Player* carrier)
    {
        if (!carrier || !carrier->GetSession() || carrier->GetSession()->IsBot())
            return false;

        uint32 const accountId = carrier->GetSession()->GetAccountId();
        RebornPreloginRequest request;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _preloginRequests.find(accountId);
            if (itr == _preloginRequests.end() || !itr->second.loginArmed ||
                itr->second.carrierGuidLow != carrier->GetGUID().GetCounter())
            {
                return false;
            }

            request = itr->second;
            _preloginRequests.erase(itr);
        }

        if (request.preparationRejected)
        {
            ReturnRejectedPreparedCarrier(carrier, request);
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.5.10 rejected: target is offline, denied, on the same account, or outside the open-world probe boundary.|r");
            return true;
        }

        Player* target = nullptr;
        if (std::chrono::steady_clock::now() >= request.expiresAt ||
            !ResolveAllowedPreloginTarget(accountId, request.targetGuidLow, target))
        {
            ReturnRejectedPreparedCarrier(carrier, request);
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.5.10 pre-login target expired, went offline, or withdrew permission.|r");
            return true;
        }

        if (!carrier->IsAlive())
        {
            RebornPendingCarrierLogin pending;
            pending.accountId = accountId;
            pending.targetGuidLow = request.targetGuidLow;
            pending.waitNoticeSent = true;
            pending.returnCaptured = request.returnCaptured;
            pending.worldPrepared = request.worldPrepared;
            pending.returnMapId = request.returnMapId;
            pending.returnX = request.returnX;
            pending.returnY = request.returnY;
            pending.returnZ = request.returnZ;
            pending.returnO = request.returnO;
            pending.returnPhaseMask = request.returnPhaseMask;
            pending.returnCanFly = request.returnCanFly;
            {
                std::lock_guard<std::mutex> lock(_mutex);
                _pendingCarrierLogins[carrier->GetGUID().GetRawValue()] = pending;
            }
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.7.8.4: this observer carrier is dead or a ghost. Observation is blocked; resurrect normally and the retained target will reconnect automatically.|r");
            ChatHandler(carrier->GetSession()).SendNotification(
                "Dead/ghost carrier: resurrect normally to continue the retained observation request.");
            return true;
        }

        if (!Start(carrier, target, true, &request))
        {
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.5.10 loaded the hidden carrier on the target map, but 6277 startup failed.|r");
        }
        return true;
    }

    void HandlePlayerLogin(Player* player)
    {
        if (!g_RebornSpectatorEnabled || !g_RebornCarrierLoginEnabled || !player || !player->GetSession() ||
            player->GetSession()->IsBot())
        {
            return;
        }

        if (StartPreparedPrelogin(player))
            return;

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
        bool sendWaitNotice = false;
        bool waitExpired = false;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _pendingCarrierLogins.find(observer->GetGUID().GetRawValue());
            if (itr == _pendingCarrierLogins.end())
                return;

            itr->second.elapsedMs += diff;
            if (!observer->IsAlive())
            {
                itr->second.aliveWaitMs += diff;
                if (!itr->second.waitNoticeSent)
                {
                    itr->second.waitNoticeSent = true;
                    sendWaitNotice = true;
                }

                if (itr->second.aliveWaitMs >= g_RebornCarrierAliveWaitMs)
                {
                    pending = itr->second;
                    _pendingCarrierLogins.erase(itr);
                    waitExpired = true;
                }
            }
            else if (itr->second.elapsedMs >= g_RebornCarrierLoginDelayMs)
            {
                pending = itr->second;
                _pendingCarrierLogins.erase(itr);
                ready = true;
            }
        }

        if (sendWaitNotice)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.7.8.4: dead/ghost observer carrier cannot start observation. Resurrect normally; the target request is retained and will continue automatically.|r");
            ChatHandler(observer->GetSession()).SendNotification(
                "Dead/ghost carrier cannot observe. Resurrect normally to continue automatically.");
        }

        if (waitExpired)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.7.8.4: the retained observation request expired while waiting for this carrier to resurrect.|r");
            return;
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

        RebornPreloginRequest prepared;
        RebornPreloginRequest const* preparedPtr = nullptr;
        if (pending.returnCaptured)
        {
            prepared.accountId = pending.accountId;
            prepared.targetGuidLow = pending.targetGuidLow;
            prepared.returnCaptured = true;
            prepared.returnMapId = pending.returnMapId;
            prepared.returnX = pending.returnX;
            prepared.returnY = pending.returnY;
            prepared.returnZ = pending.returnZ;
            prepared.returnO = pending.returnO;
            prepared.returnPhaseMask = pending.returnPhaseMask;
            prepared.returnCanFly = pending.returnCanFly;
            prepared.worldPrepared = pending.worldPrepared &&
                observer->GetMapId() == target->GetMapId() &&
                observer->GetInstanceId() == target->GetInstanceId();
            preparedPtr = &prepared;
        }

        if (!Start(observer, target, true, preparedPtr))
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

        if (!allowed)
        {
            ClearAssistForParticipant(player->GetGUID());
            StopWatchersForTarget(player->GetGUID());
        }

        SendPrototypeMessage(
            player,
            allowed
                ? "|cff00ff00Observation permission is ON for this character.|r"
                : "|cffff5555Observation permission is OFF for this character.|r");
        PushOwnConsent(player, allowed);
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

        bool const allowed = GetOwnConsent(player);
        SendPrototypeMessage(player, allowed ? "Consent: ON." : "Consent: OFF (default).");
        PushOwnConsent(player, allowed);
    }

    void RefreshOwnConsent(Player* player)
    {
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            return;

        PushOwnConsent(player, GetOwnConsent(player));
    }

    void PushOwnConsent(Player* player, bool allowed)
    {
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            return;

        uint32 generation = 0;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            generation = ++_consentGeneration;
        }
        SendRosterAddonPayload(
            player,
            "P|" + std::to_string(generation) + "|" + (allowed ? "1" : "0"));
    }

    void SendRoomChat(Player* sender, std::string message)
    {
        if (!sender || !sender->GetSession() || sender->GetSession()->IsBot())
            return;

        while (!message.empty() && std::isspace(static_cast<unsigned char>(message.front())))
            message.erase(message.begin());
        while (!message.empty() && std::isspace(static_cast<unsigned char>(message.back())))
            message.pop_back();

        if (message.empty())
        {
            SendPrototypeMessage(sender, "|cffff5555Type a spectator-room message first.|r");
            return;
        }

        if (message.size() > REBORN_ROOM_CHAT_MAX_BYTES)
        {
            SendPrototypeMessage(
                sender,
                "|cffff5555Spectator-room messages are limited to 120 UTF-8 bytes.|r");
            return;
        }

        for (unsigned char value : message)
        {
            if (value == '|' || value == '\r' || value == '\n' || value == '\t' ||
                (value < 0x20 && value != ' '))
            {
                SendPrototypeMessage(
                    sender,
                    "|cffff5555That spectator-room message contains an unsupported control character.|r");
                return;
            }
        }

        ObjectGuid roomTargetGuid = sender->GetGUID();
        RebornSpectatorChatSource source = RebornSpectatorChatSource::Target;
        std::vector<ObjectGuid> observerGuids;
        uint32 generation = 0;
        auto const now = std::chrono::steady_clock::now();
        {
            std::lock_guard<std::mutex> lock(_mutex);

            auto senderSession = _sessions.find(sender->GetGUID().GetRawValue());
            if (senderSession != _sessions.end() &&
                senderSession->second.stage == RebornSpectatorStage::Active)
            {
                roomTargetGuid = senderSession->second.targetGuid;
                source = RebornSpectatorChatSource::Observer;
            }

            for (auto const& pair : _sessions)
            {
                RebornSpectatorSession const& session = pair.second;
                if (session.stage == RebornSpectatorStage::Active &&
                    session.targetGuid == roomTargetGuid)
                {
                    observerGuids.push_back(session.observerGuid);
                }
            }

            if (observerGuids.empty())
            {
                SendPrototypeMessage(
                    sender,
                    "|cffff5555No active spectator room is available for this character.|r");
                return;
            }

            auto lastMessage = _chatLastMessageAt.find(sender->GetGUID().GetRawValue());
            if (lastMessage != _chatLastMessageAt.end() &&
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    now - lastMessage->second).count() < REBORN_ROOM_CHAT_COOLDOWN_MS)
            {
                SendPrototypeMessage(
                    sender,
                    "|cffff5555Please wait one second before sending another spectator-room message.|r");
                return;
            }

            _chatLastMessageAt[sender->GetGUID().GetRawValue()] = now;
            generation = ++_chatGeneration;
        }

        std::vector<Player*> recipients;
        Player* target = ObjectAccessor::FindPlayer(roomTargetGuid);
        if (target && target->GetSession() && !target->GetSession()->IsBot())
            recipients.push_back(target);

        for (ObjectGuid observerGuid : observerGuids)
        {
            Player* observer = ObjectAccessor::FindPlayer(observerGuid);
            if (!observer || !observer->GetSession() || observer->GetSession()->IsBot())
                continue;
            if (std::find(recipients.begin(), recipients.end(), observer) == recipients.end())
                recipients.push_back(observer);
        }

        std::string const payload =
            "M|" + std::to_string(generation) + "|" +
            std::to_string(roomTargetGuid.GetCounter()) + "|" +
            std::string(1, static_cast<char>(source)) + "|" + sender->GetName() + "|" + message;
        for (Player* recipient : recipients)
            SendRosterAddonPayload(recipient, payload);
    }

    void PushQuickReplies(Player* player, std::string locale)
    {
        if (!player || !player->GetSession() || player->GetSession()->IsBot())
            return;

        locale = locale == "enUS" ? "enUS" : "zhCN";
        struct QuickReply
        {
            uint32 id = 0;
            std::string text;
        };
        std::vector<QuickReply> replies;

        QueryResult result = CharacterDatabase.Query(
            "SELECT `id`, `reply_text` FROM `reborn_spectator_quick_reply` "
            "WHERE `locale` = '{}' AND `enabled` = 1 "
            "ORDER BY `sort_order`, `id` LIMIT 20",
            locale);
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                QuickReply reply;
                reply.id = fields[0].Get<uint32>();
                reply.text = fields[1].Get<std::string>();
                if (reply.text.empty() || reply.text.size() > REBORN_ROOM_CHAT_MAX_BYTES ||
                    reply.text.find('|') != std::string::npos ||
                    reply.text.find('\r') != std::string::npos ||
                    reply.text.find('\n') != std::string::npos ||
                    reply.text.find('\t') != std::string::npos)
                {
                    continue;
                }
                replies.push_back(reply);
            } while (result->NextRow());
        }

        uint32 generation = 0;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            generation = ++_quickReplyGeneration;
        }

        SendRosterAddonPayload(
            player,
            "Q|" + std::to_string(generation) + "|B|" + locale + "|" +
                std::to_string(replies.size()));
        for (QuickReply const& reply : replies)
        {
            SendRosterAddonPayload(
                player,
                "Q|" + std::to_string(generation) + "|R|" +
                    std::to_string(reply.id) + "|" + reply.text);
        }
        SendRosterAddonPayload(player, "Q|" + std::to_string(generation) + "|E");
    }

    // Reserved S.6.7 provider boundary. A later audited Playerbot canned-reply
    // library or external AI adapter may publish B/A source messages through
    // the same room protocol after independently validating room membership,
    // length, rate and content. This stage intentionally never calls it.

    void SendAssistPayload(
        ObjectGuid targetGuid,
        ObjectGuid observerGuid,
        char state,
        Player* extraRecipient = nullptr)
    {
        uint32 generation = 0;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            generation = ++_assistGeneration;
        }

        Player* target = ObjectAccessor::FindPlayer(targetGuid);
        Player* observer = ObjectAccessor::FindPlayer(observerGuid);
        std::string const targetName = target ? target->GetName() : "<offline>";
        std::string const observerName = observer ? observer->GetName() : "";
        std::string const payload =
            "H|" + std::to_string(generation) + "|" + std::string(1, state) + "|" +
            std::to_string(targetGuid.GetCounter()) + "|" + targetName + "|" +
            std::to_string(observerGuid.GetCounter()) + "|" + observerName;

        std::vector<Player*> recipients;
        if (target && target->GetSession() && !target->GetSession()->IsBot())
            recipients.push_back(target);
        if (observer && observer->GetSession() && !observer->GetSession()->IsBot() &&
            std::find(recipients.begin(), recipients.end(), observer) == recipients.end())
        {
            recipients.push_back(observer);
        }
        if (extraRecipient && extraRecipient->GetSession() &&
            !extraRecipient->GetSession()->IsBot() &&
            std::find(recipients.begin(), recipients.end(), extraRecipient) == recipients.end())
        {
            recipients.push_back(extraRecipient);
        }

        for (Player* recipient : recipients)
            SendRosterAddonPayload(recipient, payload);
    }

    void InviteAssist(Player* target, uint32 observerGuidLow)
    {
        if (!target || !target->GetSession() || target->GetSession()->IsBot())
            return;

        Player* observer = ObjectAccessor::FindPlayerByLowGUID(observerGuidLow);
        if (!observer || !observer->GetSession() || observer->GetSession()->IsBot())
        {
            SendPrototypeMessage(target, "|cffff5555That observer is no longer online.|r");
            return;
        }

        bool validObserver = false;
        bool alreadyExists = false;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto session = _sessions.find(observer->GetGUID().GetRawValue());
            validObserver =
                session != _sessions.end() &&
                session->second.stage == RebornSpectatorStage::Active &&
                session->second.targetGuid == target->GetGUID();
            auto existing =
                _assistHandshakes.find(target->GetGUID().GetRawValue());
            if (existing != _assistHandshakes.end() &&
                existing->second.state == RebornAssistState::Pending &&
                std::chrono::steady_clock::now() >= existing->second.expiresAt)
            {
                _assistHandshakes.erase(existing);
            }
            alreadyExists =
                _assistHandshakes.find(target->GetGUID().GetRawValue()) !=
                _assistHandshakes.end();
            if (validObserver && !alreadyExists)
            {
                RebornAssistHandshake handshake;
                handshake.targetGuid = target->GetGUID();
                handshake.observerGuid = observer->GetGUID();
                handshake.state = RebornAssistState::Pending;
                handshake.expiresAt =
                    std::chrono::steady_clock::now() +
                    std::chrono::seconds(REBORN_ASSIST_INVITE_TTL_SECONDS);
                _assistHandshakes.emplace(
                    target->GetGUID().GetRawValue(),
                    handshake);
            }
        }

        if (!validObserver)
        {
            SendPrototypeMessage(
                target,
                "|cffff5555Only an active viewer of this character can receive an assistance invitation.|r");
            return;
        }
        if (alreadyExists)
        {
            SendPrototypeMessage(
                target,
                "|cffff5555An assistance invitation or grant already exists. Revoke it before selecting another viewer.|r");
            return;
        }

        SendPrototypeMessage(
            target,
            "|cff00ff00Assistance invitation sent to " + observer->GetName() +
                ". S.6.9 permits only small movement/turning actions after acceptance.|r");
        SendPrototypeMessage(
            observer,
            "|cffffff00" + target->GetName() +
                " invited you to an assistance-control handshake. Accept or decline in the spectator window.|r");
        PushAssistHandshake(target->GetGUID());
    }

    void RespondAssist(Player* observer, uint32 targetGuidLow, bool accepted)
    {
        if (!observer || !observer->GetSession() || observer->GetSession()->IsBot())
            return;

        ObjectGuid targetGuid = ObjectGuid::Create<HighGuid::Player>(targetGuidLow);
        bool valid = false;
        bool expired = false;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto handshake = _assistHandshakes.find(targetGuid.GetRawValue());
            if (handshake != _assistHandshakes.end() &&
                handshake->second.observerGuid == observer->GetGUID() &&
                handshake->second.state == RebornAssistState::Pending)
            {
                expired =
                    std::chrono::steady_clock::now() >=
                    handshake->second.expiresAt;
                if (!expired)
                {
                    valid = true;
                    if (!accepted)
                    {
                        _assistHandshakes.erase(handshake);
                    }
                }
                else
                {
                    _assistHandshakes.erase(handshake);
                }
            }
        }

        if (!valid)
        {
            SendPrototypeMessage(
                observer,
                expired
                    ? "|cffff5555That assistance invitation expired.|r"
                    : "|cffff5555No matching assistance invitation is pending.|r");
            SendAssistPayload(targetGuid, observer->GetGUID(), 'N', observer);
            return;
        }

        Player* target = ObjectAccessor::FindPlayer(targetGuid);
        if (accepted)
        {
            if (!ActivateNativeAssistControl(observer, target))
            {
                {
                    std::lock_guard<std::mutex> lock(_mutex);
                    auto handshake =
                        _assistHandshakes.find(targetGuid.GetRawValue());
                    if (handshake != _assistHandshakes.end() &&
                        handshake->second.observerGuid == observer->GetGUID() &&
                        handshake->second.state == RebornAssistState::Pending)
                    {
                        _assistHandshakes.erase(handshake);
                    }
                }
                SendPrototypeMessage(
                    observer,
                    "|cffff5555S.6.13 native control could not start. The target must be an online, alive, out-of-combat, unmounted real player on the same ordinary map.|r");
                SendAssistPayload(
                    targetGuid,
                    observer->GetGUID(),
                    'N',
                    observer);
                return;
            }

            bool committed = false;
            {
                std::lock_guard<std::mutex> lock(_mutex);
                auto handshake =
                    _assistHandshakes.find(targetGuid.GetRawValue());
                if (handshake != _assistHandshakes.end() &&
                    handshake->second.observerGuid == observer->GetGUID() &&
                    handshake->second.state == RebornAssistState::Pending)
                {
                    handshake->second.state = RebornAssistState::Granted;
                    handshake->second.expiresAt =
                        std::chrono::steady_clock::time_point::max();
                    committed = true;
                }
            }
            if (!committed)
            {
                RestoreNativeAssistControl(observer->GetGUID(), targetGuid);
                SendPrototypeMessage(
                    observer,
                    "|cffff5555The assistance invitation changed before native control could be committed.|r");
                SendAssistPayload(
                    targetGuid,
                    observer->GetGUID(),
                    'N',
                    observer);
                return;
            }

            SendPrototypeMessage(
                observer,
                "|cff00ff00S.6.13 native mover control is active. Use the normal W/A/S/D keys; the old spline-step controls are disabled.|r");
            if (target)
            {
                SendPrototypeMessage(
                    target,
                    "|cff00ff00" + observer->GetName() +
                        " accepted assistance and now has native movement control. You can revoke it at any time.|r");
            }
            PushAssistHandshake(targetGuid);
        }
        else
        {
            SendPrototypeMessage(observer, "Assistance invitation declined.");
            if (target)
            {
                SendPrototypeMessage(
                    target,
                    observer->GetName() + " declined the assistance invitation.");
            }
            SendAssistPayload(targetGuid, observer->GetGUID(), 'N');
        }
    }

    void RevokeAssist(Player* target)
    {
        if (!target || !target->GetSession() || target->GetSession()->IsBot())
            return;

        ObjectGuid observerGuid;
        bool removed = false;
        bool granted = false;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto handshake =
                _assistHandshakes.find(target->GetGUID().GetRawValue());
            if (handshake != _assistHandshakes.end() &&
                handshake->second.targetGuid == target->GetGUID())
            {
                observerGuid = handshake->second.observerGuid;
                granted = handshake->second.state == RebornAssistState::Granted;
                _assistHandshakes.erase(handshake);
                _assistLastMoveAt.erase(observerGuid.GetRawValue());
                _assistLastTurnAt.erase(observerGuid.GetRawValue());
                removed = true;
            }
        }

        if (!removed)
        {
            SendPrototypeMessage(target, "No assistance invitation or grant is active.");
            PushAssistHandshake(target->GetGUID(), target);
            return;
        }

        if (granted)
        {
            RestoreNativeAssistControl(observerGuid, target->GetGUID());
        }

        SendPrototypeMessage(target, "|cffffff00Assistance authorization revoked.|r");
        if (Player* observer = ObjectAccessor::FindPlayer(observerGuid))
            SendPrototypeMessage(observer, "|cffffff00The target revoked assistance authorization.|r");
        SendAssistPayload(target->GetGUID(), observerGuid, 'N');
    }

    void AssistMove(Player* observer, char action)
    {
        if (!observer || !observer->GetSession() || observer->GetSession()->IsBot())
            return;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            if (_nativeAssistTargetByObserver.find(
                    observer->GetGUID().GetRawValue()) !=
                _nativeAssistTargetByObserver.end())
            {
                SendPrototypeMessage(
                    observer,
                    "|cffffff00S.6.13 is using the native mover. Use normal W/A/S/D input instead of .rebornspec assistmove.|r");
                return;
            }
        }

        action = char(std::toupper(static_cast<unsigned char>(action)));
        if (action != 'F' && action != 'B' && action != 'L' &&
            action != 'R' && action != 'X')
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.12 accepts only F/B/L/R movement or X stop.|r");
            return;
        }

        RebornSpectatorSession spectatorSession;
        if (!GetSession(observer->GetGUID(), spectatorSession) ||
            spectatorSession.stage != RebornSpectatorStage::Active)
        {
            SendPrototypeMessage(observer, "|cffff5555No active spectator session can use assistance control.|r");
            return;
        }

        bool authorized = false;
        bool rateLimited = false;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto handshake = _assistHandshakes.find(
                spectatorSession.targetGuid.GetRawValue());
            authorized =
                handshake != _assistHandshakes.end() &&
                handshake->second.state == RebornAssistState::Granted &&
                handshake->second.targetGuid == spectatorSession.targetGuid &&
                handshake->second.observerGuid == observer->GetGUID();

            if (authorized && action == 'X')
            {
                _assistLastMoveAt.erase(observer->GetGUID().GetRawValue());
                _assistLastTurnAt.erase(observer->GetGUID().GetRawValue());
            }
            else if (authorized)
            {
                auto const now = std::chrono::steady_clock::now();
                auto& rateMap =
                    (action == 'L' || action == 'R') ?
                        _assistLastTurnAt : _assistLastMoveAt;
                auto last = rateMap.find(observer->GetGUID().GetRawValue());
                if (last != rateMap.end() &&
                    std::chrono::duration_cast<std::chrono::milliseconds>(
                        now - last->second).count() <
                        REBORN_ASSIST_MOVE_COOLDOWN_MS)
                {
                    rateLimited = true;
                }
                else
                {
                    rateMap[observer->GetGUID().GetRawValue()] = now;
                }
            }
        }

        if (!authorized)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555The target has not granted this observer S.6.9 movement assistance.|r");
            return;
        }
        if (rateLimited)
            return;

        Player* target = ObjectAccessor::FindPlayer(spectatorSession.targetGuid);
        if (!target || !target->GetSession() || target->GetSession()->IsBot() ||
            !target->IsInWorld() || !target->IsAlive() ||
            target->IsBeingTeleported())
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555The assisted real-player target is no longer available.|r");
            return;
        }

        // STOP is deliberately processed before the ordinary-world movement
        // gates. A release, revoke, or UI close must be able to halt an
        // assistance spline even if the target just entered combat or water.
        if (action == 'X')
        {
            target->GetMotionMaster()->Clear(false);
            target->GetMotionMaster()->MoveIdle();
            target->StopMoving();
            return;
        }

        Map* targetMap = target->FindMap();
        if (!targetMap || targetMap->Instanceable() ||
            target->GetInstanceId() != 0 ||
            target->IsInCombat() || target->GetVehicle() ||
            target->GetVehicleKit() || target->IsInFlight() ||
            target->IsMounted() || target->IsInWater() ||
            !target->CanFreeMove())
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.9 movement is limited to a stopped, out-of-combat, unmounted real player on an ordinary dry-world map.|r");
            return;
        }

        if (action == 'L' || action == 'R')
        {
            float const delta =
                action == 'L' ? REBORN_ASSIST_TURN_RADIANS :
                                -REBORN_ASSIST_TURN_RADIANS;
            target->SetFacingTo(
                Position::NormalizeOrientation(target->GetOrientation() + delta));
            return;
        }

        float const relativeAngle = action == 'F' ? 0.0f : 3.14159265f;
        Position const destination =
            target->GetFirstCollisionPosition(
                REBORN_ASSIST_STEP_DISTANCE,
                relativeAngle);
        if (!destination.IsPositionValid() ||
            target->GetExactDist2d(
                destination.GetPositionX(),
                destination.GetPositionY()) < 0.10f ||
            std::fabs(destination.GetPositionZ() - target->GetPositionZ()) > 1.75f ||
            !target->IsWithinLOS(
                destination.GetPositionX(),
                destination.GetPositionY(),
                destination.GetPositionZ()))
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555That assistance step was blocked by terrain or collision.|r");
            return;
        }

        // Launch directly from the current spline position. Replacing a
        // PointMovementGenerator calls StopMoving() first and creates the
        // visible micro-pause reported in S.6.12.
        Movement::MoveSplineInit spline(target);
        spline.MoveTo(
            destination.GetPositionX(),
            destination.GetPositionY(),
            destination.GetPositionZ(),
            false,
            false);
        if (action == 'B')
        {
            spline.SetOrientationInversed();
            spline.SetVelocity(target->GetSpeed(MOVE_RUN_BACK));
        }
        else
        {
            spline.SetVelocity(target->GetSpeed(MOVE_RUN));
        }
        spline.Launch();
    }

    void RefreshAssist(Player* requester)
    {
        if (!requester)
            return;

        ObjectGuid targetGuid = requester->GetGUID();
        RebornSpectatorSession session;
        if (GetSession(requester->GetGUID(), session))
            targetGuid = session.targetGuid;
        PushAssistHandshake(targetGuid, requester);
    }

    void PushAssistHandshake(ObjectGuid targetGuid, Player* extraRecipient = nullptr)
    {
        ObjectGuid observerGuid;
        char state = 'N';
        bool expired = false;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto handshake = _assistHandshakes.find(targetGuid.GetRawValue());
            if (handshake != _assistHandshakes.end())
            {
                if (handshake->second.state == RebornAssistState::Pending &&
                    std::chrono::steady_clock::now() >= handshake->second.expiresAt)
                {
                    observerGuid = handshake->second.observerGuid;
                    _assistHandshakes.erase(handshake);
                    expired = true;
                }
                else
                {
                    observerGuid = handshake->second.observerGuid;
                    state = static_cast<char>(handshake->second.state);
                }
            }
        }

        SendAssistPayload(targetGuid, observerGuid, state, extraRecipient);
        if (expired)
        {
            if (Player* target = ObjectAccessor::FindPlayer(targetGuid))
                SendPrototypeMessage(target, "|cffff5555Assistance invitation expired.|r");
            if (Player* observer = ObjectAccessor::FindPlayer(observerGuid))
                SendPrototypeMessage(observer, "|cffff5555Assistance invitation expired.|r");
        }
    }

    void ClearAssistForParticipant(ObjectGuid participantGuid)
    {
        std::vector<RebornAssistHandshake> removed;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _assistLastMoveAt.erase(participantGuid.GetRawValue());
            _assistLastTurnAt.erase(participantGuid.GetRawValue());
            for (auto itr = _assistHandshakes.begin();
                 itr != _assistHandshakes.end();)
            {
                if (itr->second.targetGuid == participantGuid ||
                    itr->second.observerGuid == participantGuid)
                {
                    _assistLastMoveAt.erase(
                        itr->second.observerGuid.GetRawValue());
                    _assistLastTurnAt.erase(
                        itr->second.observerGuid.GetRawValue());
                    removed.push_back(itr->second);
                    itr = _assistHandshakes.erase(itr);
                }
                else
                {
                    ++itr;
                }
            }
        }

        for (RebornAssistHandshake const& handshake : removed)
        {
            if (handshake.state == RebornAssistState::Granted)
            {
                RestoreNativeAssistControl(
                    handshake.observerGuid,
                    handshake.targetGuid);
            }
            SendAssistPayload(
                handshake.targetGuid,
                handshake.observerGuid,
                'N');
        }
    }

    void StopWatchersForTarget(ObjectGuid targetGuid)
    {
        std::vector<ObjectGuid> observerGuids;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            for (auto const& pair : _sessions)
            {
                RebornSpectatorSession const& session = pair.second;
                if (session.stage == RebornSpectatorStage::Active && session.targetGuid == targetGuid)
                    observerGuids.push_back(session.observerGuid);
            }
        }

        for (ObjectGuid observerGuid : observerGuids)
        {
            if (Player* observer = ObjectAccessor::FindPlayer(observerGuid))
                Stop(observer, true, "target withdrew observation permission");
        }
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

    bool StartAuthenticatedCarrierRequest(Player* carrier, uint32 targetGuidLow)
    {
        if (!g_RebornSpectatorEnabled || !g_RebornCarrierLoginEnabled)
        {
            SendPrototypeMessage(
                carrier,
                "|cffff5555Authenticated carrier requests are disabled in RebornSpectator.conf.|r");
            return false;
        }

        if (!carrier || !carrier->GetSession() || carrier->GetSession()->IsBot())
            return false;

        uint32 const accountId = carrier->GetSession()->GetAccountId();
        uint32 const carrierGuidLow = carrier->GetGUID().GetCounter();
        RebornCarrierRecord record;
        if (!GetCarrierRecord(accountId, record) || !record.enabled ||
            !record.characterOwnedByAccount || record.guidLow != carrierGuidLow)
        {
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.5.5 rejected: only this authenticated account's registered carrier may use watchguid.|r");
            LOG_WARN(
                "module",
                "RebornSpectator S.5.5: rejected watchguid from account {}, character {}; "
                "registered carrier {}, enabled {}, owned {}",
                accountId,
                carrierGuidLow,
                record.guidLow,
                record.enabled ? 1 : 0,
                record.characterOwnedByAccount ? 1 : 0);
            return false;
        }

        if (targetGuidLow == 0 || targetGuidLow == carrierGuidLow)
        {
            SendPrototypeMessage(carrier, "|cffff5555S.5.5 rejected: invalid spectator target GUIDLow.|r");
            return false;
        }

        Player* target = ObjectAccessor::FindPlayerByLowGUID(targetGuidLow);
        if (!target || !target->IsInWorld() || !target->GetSession())
        {
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.5.5 rejected: no online Player or Playerbot has that GUIDLow.|r");
            return false;
        }

        if (target->GetSession()->GetAccountId() == accountId)
        {
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.5.5 rejected: a carrier cannot observe a character on its own account.|r");
            return false;
        }

        if (!IsTargetAllowed(target))
        {
            SendPrototypeMessage(
                carrier,
                "|cffff5555S.5.5 rejected: that real player has not enabled observation.|r");
            return false;
        }

        if (!Start(carrier, target, true))
            return false;

        SendPrototypeMessage(
            carrier,
            "|cff00ff00S.5.5 authenticated carrier request accepted for " + target->GetName() +
                " (GUIDLow " + std::to_string(targetGuidLow) + ").|r");
        LOG_INFO(
            "module",
            "RebornSpectator S.5.5: authenticated carrier {} on account {} accepted target {} ({})",
            carrierGuidLow,
            accountId,
            target->GetName(),
            targetGuidLow);
        return true;
    }

    bool StartExistingCharacterRequest(Player* observer, uint32 targetGuidLow)
    {
        if (!g_RebornSpectatorEnabled)
        {
            SendPrototypeMessage(observer, "|cffff5555Reborn Spectator is disabled in the server configuration.|r");
            return false;
        }

        if (!observer || !observer->GetSession() || observer->GetSession()->IsBot())
            return false;

        uint32 const accountId = observer->GetSession()->GetAccountId();
        uint32 const observerGuidLow = observer->GetGUID().GetCounter();
        if (targetGuidLow == 0 || targetGuidLow == observerGuidLow)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.2 rejected: the selected existing character cannot observe itself.|r");
            return false;
        }

        Player* target = ObjectAccessor::FindPlayerByLowGUID(targetGuidLow);
        if (!target || !target->IsInWorld() || !target->GetSession())
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.2 rejected: no online Player or Playerbot has that GUIDLow.|r");
            return false;
        }

        if (target->GetSession()->GetAccountId() == accountId)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.2 rejected: a character cannot observe another character on its own authenticated account.|r");
            return false;
        }

        if (!IsTargetAllowed(target))
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.2 rejected: that real player has not enabled observation.|r");
            return false;
        }

        if (!Start(observer, target, true))
            return false;

        SendPrototypeMessage(
            observer,
            "|cff00ff00S.6.2 PASS: existing character " + observer->GetName() +
                " is the temporary read-only carrier for target " + target->GetName() +
                " (GUIDLow " + std::to_string(targetGuidLow) + "). No Rsp carrier was required.|r");
        LOG_INFO(
            "module",
            "RebornSpectator S.6.2: authenticated account {} used existing character {} ({}) "
            "as temporary carrier for target {} ({})",
            accountId,
            observer->GetName(),
            observerGuidLow,
            target->GetName(),
            targetGuidLow);
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
    void UpdateResumeWatch(Player* observer, uint32 diff)
    {
        if (!observer || !observer->GetSession() ||
            observer->GetSession()->IsBot())
        {
            return;
        }

        RebornResumeWatch resume;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _resumeWatches.find(
                observer->GetGUID().GetRawValue());
            if (itr == _resumeWatches.end())
                return;

            if (std::chrono::steady_clock::now() >= itr->second.expiresAt)
            {
                _resumeWatches.erase(itr);
                SendPrototypeMessage(
                    observer,
                    "|cffffff00S.6.14 automatic re-observation expired after 10 minutes.|r");
                return;
            }

            if (!itr->second.resurrectionSeen)
                return;

            itr->second.retryTimerMs += diff;
            if (itr->second.retryTimerMs < 2000)
                return;
            itr->second.retryTimerMs = 0;
            resume = itr->second;

            // A death return must reach its saved origin before a new
            // observation is allowed to capture another return point.
            if (_pendingReturns.find(observer->GetGUID().GetRawValue()) !=
                _pendingReturns.end())
            {
                return;
            }
        }

        if (HasSession(observer->GetGUID()))
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _resumeWatches.erase(observer->GetGUID().GetRawValue());
            return;
        }

        Player* target = ObjectAccessor::FindPlayer(resume.targetGuid);
        if (!target || !target->GetSession() || !target->IsInWorld() ||
            !target->IsAlive() || target->IsBeingTeleported() ||
            observer->IsBeingTeleported())
        {
            return;
        }

        if (!IsTargetAllowed(target))
        {
            {
                std::lock_guard<std::mutex> lock(_mutex);
                _resumeWatches.erase(observer->GetGUID().GetRawValue());
            }
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.14 automatic re-observation was cancelled because the target no longer permits observation.|r");
            return;
        }

        if (observer->IsInCombat() || observer->GetVehicle() ||
            observer->IsInFlight() || observer->IsMounted() ||
            observer->GetGroup() || !observer->CanFreeMove() ||
            observer->GetViewpoint())
        {
            return;
        }

        if (!Start(observer, target, true))
            return;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _resumeWatches.erase(observer->GetGUID().GetRawValue());
        }
        SendPrototypeMessage(
            observer,
            "|cff00ff00S.6.14 PASS: read-only observation resumed without returning to the login screen. Assistance control remains ungranted.|r");
    }

    void ReturnRejectedPreparedCarrier(Player* carrier, RebornPreloginRequest const& request)
    {
        if (!carrier || !request.worldPrepared || !request.returnCaptured)
            return;

        // The pre-login bridge may already have placed the physical carrier near
        // the target. If that target expires or withdraws consent before 6277 is
        // established, immediately use the same confirmed-return machinery; do
        // not leave the account at the remote/high-altitude preparation point.
        RebornSpectatorSession returnSession;
        returnSession.returnMapId = request.returnMapId;
        returnSession.returnX = request.returnX;
        returnSession.returnY = request.returnY;
        returnSession.returnZ = request.returnZ;
        returnSession.returnO = request.returnO;
        returnSession.returnPhaseMask = request.returnPhaseMask;
        returnSession.hadCanFly = request.returnCanFly;
        carrier->SetPhaseMask(request.returnPhaseMask, true);
        QueueReturn(carrier, returnSession);
        ProcessPendingReturn(carrier, 0, true);
    }

    void QueueReturn(Player* observer, RebornSpectatorSession const& session)
    {
        if (!observer)
            return;

        RebornPendingReturn pending;
        pending.mapId = session.returnMapId;
        pending.x = session.returnX;
        pending.y = session.returnY;
        pending.z = session.returnZ;
        pending.o = session.returnO;
        pending.hadCanFly = session.hadCanFly;

        // Keep gravity from turning an asynchronous cross-map return into a
        // second fall window. The original flag is restored only after arrival.
        observer->SetCanFly(true);

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _pendingReturns[observer->GetGUID().GetRawValue()] = pending;
        }

        LOG_INFO(
            "module",
            "RebornSpectator S.6.13.3: queued confirmed return for observer {} ({}) from map {} ({}, {}, {}) to map {} ({}, {}, {})",
            observer->GetName(),
            observer->GetGUID().GetCounter(),
            observer->GetMapId(),
            observer->GetPositionX(),
            observer->GetPositionY(),
            observer->GetPositionZ(),
            pending.mapId,
            pending.x,
            pending.y,
            pending.z);
    }

    void ProcessPendingReturn(Player* observer, uint32 diff, bool force)
    {
        if (!observer || !observer->IsInWorld())
            return;

        RebornPendingReturn pending;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _pendingReturns.find(observer->GetGUID().GetRawValue());
            if (itr == _pendingReturns.end())
                return;

            itr->second.totalElapsedMs += diff;
            itr->second.retryTimerMs += diff;
            pending = itr->second;
        }

        bool const arrived =
            observer->GetMapId() == pending.mapId &&
            std::fabs(observer->GetPositionX() - pending.x) <= 3.0f &&
            std::fabs(observer->GetPositionY() - pending.y) <= 3.0f &&
            std::fabs(observer->GetPositionZ() - pending.z) <= 6.0f;
        if (arrived)
        {
            {
                std::lock_guard<std::mutex> lock(_mutex);
                _pendingReturns.erase(observer->GetGUID().GetRawValue());
            }
            observer->SetCanFly(pending.hadCanFly);
            SendPrototypeMessage(
                observer,
                "|cff00ff00S.6.13.3 return confirmed: the observer carrier reached its original position.|r");
            LOG_INFO(
                "module",
                "RebornSpectator S.6.13.3: confirmed return for observer {} ({}) after {} ms and {} attempt(s)",
                observer->GetName(),
                observer->GetGUID().GetCounter(),
                pending.totalElapsedMs,
                pending.attempts);
            return;
        }

        if (!force && pending.retryTimerMs < 500)
            return;

        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _pendingReturns.find(observer->GetGUID().GetRawValue());
            if (itr == _pendingReturns.end())
                return;
            itr->second.retryTimerMs = 0;
        }

        if (observer->IsBeingTeleported())
        {
            LOG_DEBUG(
                "module",
                "RebornSpectator S.6.13.3: observer {} ({}) is still teleporting; confirmed return will retry",
                observer->GetName(),
                observer->GetGUID().GetCounter());
            return;
        }

        bool const accepted = observer->TeleportTo(
            pending.mapId,
            pending.x,
            pending.y,
            pending.z,
            pending.o,
            TELE_TO_GM_MODE);

        uint32 attempts = 0;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _pendingReturns.find(observer->GetGUID().GetRawValue());
            if (itr != _pendingReturns.end())
                attempts = ++itr->second.attempts;
        }

        if (!accepted)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555S.6.13.3 return attempt was rejected; the server will retry automatically.|r");
            LOG_ERROR(
                "module",
                "RebornSpectator S.6.13.3: return attempt {} rejected for observer {} ({}) to map {} ({}, {}, {})",
                attempts,
                observer->GetName(),
                observer->GetGUID().GetCounter(),
                pending.mapId,
                pending.x,
                pending.y,
                pending.z);
        }
        else
        {
            LOG_INFO(
                "module",
                "RebornSpectator S.6.13.3: return attempt {} accepted for observer {} ({}); awaiting arrival confirmation",
                attempts,
                observer->GetName(),
                observer->GetGUID().GetCounter());
        }
    }

    bool ActivateNativeAssistControl(Player* observer, Player* target)
    {
        if (!observer || !target || !observer->GetSession() ||
            !target->GetSession() || observer->GetSession()->IsBot() ||
            target->GetSession()->IsBot() || !observer->IsInWorld() ||
            !target->IsInWorld() || !observer->IsAlive() ||
            !target->IsAlive() || observer->IsBeingTeleported() ||
            target->IsBeingTeleported() ||
            observer->GetMapId() != target->GetMapId() ||
            observer->GetInstanceId() != target->GetInstanceId())
        {
            return false;
        }

        RebornSpectatorSession spectatorSession;
        if (!GetSession(observer->GetGUID(), spectatorSession) ||
            spectatorSession.stage != RebornSpectatorStage::Active ||
            spectatorSession.targetGuid != target->GetGUID())
        {
            return false;
        }

        Map* targetMap = target->FindMap();
        if (!targetMap || targetMap->Instanceable() ||
            target->GetInstanceId() != 0 || target->IsInCombat() ||
            target->GetVehicle() || target->GetVehicleKit() ||
            target->IsInFlight() || target->IsMounted() ||
            target->IsInWater() || target->IsCharmed() ||
            observer->GetCharmGUID() ||
            target->HasUnitState(UNIT_STATE_FLEEING | UNIT_STATE_CONFUSED) ||
            !target->CanFreeMove())
        {
            return false;
        }

        {
            std::lock_guard<std::mutex> lock(_mutex);
            if (_nativeAssistTargetByObserver.find(
                    observer->GetGUID().GetRawValue()) !=
                    _nativeAssistTargetByObserver.end() ||
                _nativeAssistObserverByTarget.find(
                    target->GetGUID().GetRawValue()) !=
                    _nativeAssistObserverByTarget.end())
            {
                return false;
            }
        }

        // End any old S.6.12 server-generated spline before handing the mover
        // to the observer's authenticated client.
        target->GetMotionMaster()->Clear(false);
        target->GetMotionMaster()->MoveIdle();
        target->StopMoving();

        // A 3.3.5 client does not accept an unrelated real Player as its active
        // mover from SMSG_CLIENT_CONTROL_UPDATE alone. Publish the minimum
        // native charm/control relationship first. Unlike SetCharmedBy(), this
        // deliberately does not change faction, initialize a possess spell
        // bar, or remove the already proven 6277 viewpoint.
        observer->SetCharm(target, true);
        if (observer->GetCharmGUID() != target->GetGUID() ||
            target->GetCharmerGUID() != observer->GetGUID())
        {
            if (target->GetCharmerGUID() == observer->GetGUID())
                observer->SetCharm(target, false);
            return false;
        }
        target->AddUnitState(UNIT_STATE_CHARMED);

        // Keep spell 6277 as the camera source. packetOnly avoids changing the
        // viewpoint while the explicit SetMover call switches movement packet
        // ownership to the observed real player.
        target->SetClientControl(target, false, true);
        observer->SetClientControl(target, true, true);
        observer->SetMover(target);

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _nativeAssistTargetByObserver[
                observer->GetGUID().GetRawValue()] = target->GetGUID();
            _nativeAssistObserverByTarget[
                target->GetGUID().GetRawValue()] = observer->GetGUID();
        }

        return true;
    }

    void RestoreNativeAssistControl(
        ObjectGuid observerGuid,
        ObjectGuid targetGuid)
    {
        {
            std::lock_guard<std::mutex> lock(_mutex);
            _nativeAssistTargetByObserver.erase(observerGuid.GetRawValue());
            _nativeAssistObserverByTarget.erase(targetGuid.GetRawValue());
        }

        Player* observer = ObjectAccessor::FindPlayer(observerGuid);
        Player* target = ObjectAccessor::FindPlayer(targetGuid);

        if (observer)
        {
            if (target)
                observer->SetClientControl(target, false, true);

            observer->SetMover(observer);
            if (target &&
                observer->GetCharmGUID() == target->GetGUID() &&
                target->GetCharmerGUID() == observer->GetGUID())
            {
                observer->SetCharm(target, false);
            }
            observer->SetClientControl(observer, true, true);

            // An active spectator carrier remains read-only after the delegated
            // target is released. Stop() subsequently restores normal control.
            RebornSpectatorSession spectatorSession;
            if (GetSession(observerGuid, spectatorSession) &&
                spectatorSession.stage == RebornSpectatorStage::Active)
            {
                observer->SetClientControl(observer, false, true);
            }
        }

        if (target)
        {
            target->SetMover(target);
            target->SetClientControl(target, true, true);
            target->GetMotionMaster()->Clear(false);
            target->GetMotionMaster()->MoveIdle();
            target->StopMoving();
        }
    }

    bool ResolveAllowedPreloginTarget(uint32 accountId, uint32 targetGuidLow, Player*& target)
    {
        target = ObjectAccessor::FindPlayerByLowGUID(targetGuidLow);
        if (!target || !target->GetSession() || !target->IsInWorld() || !target->IsAlive() ||
            target->IsBeingTeleported() || target->GetSession()->GetAccountId() == accountId)
        {
            return false;
        }

        Map* targetMap = target->FindMap();
        if (!targetMap || targetMap->Instanceable() || target->GetInstanceId() != 0)
            return false;

        return IsTargetAllowed(target);
    }

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

    static bool GetOwnConsent(Player* player)
    {
        if (!player || !player->GetSession())
            return false;
        if (player->GetSession()->IsBot())
            return true;

        QueryResult result = CharacterDatabase.Query(
            "SELECT `allow_spectate` FROM `reborn_spectator_consent` "
            "WHERE `character_guid` = {} LIMIT 1",
            player->GetGUID().GetCounter());
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
        // Keep the server-side player in a normal free-move state so the 3.3.5 logout
        // flow can sit the character and start its countdown.  The packet-only client
        // control lock prevents ordinary movement input without poisoning CanFreeMove().
        // Flight protection must be active before any target relocation. This
        // prevents a physical carrier from falling when the target is flying,
        // airborne, or standing on geometry that is not valid for the carrier.
        observer->SetCanFly(true);
        observer->SetClientControl(observer, false, true);
        if (!session.hadNonAttackable)
            observer->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
        if (!session.hadPacified)
            observer->SetUnitFlag(UNIT_FLAG_PACIFIED);
        if (!session.hadSilenced)
            observer->SetUnitFlag(UNIT_FLAG_SILENCED);
        if (!session.hadNotSelectable)
            observer->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
    }

    static void RestoreProtection(Player* observer, RebornSpectatorSession const& session)
    {
        if (session.protectionApplied)
        {
            observer->SetClientControl(observer, true, true);
            if (!session.hadNonAttackable)
                observer->RemoveUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
            if (!session.hadPacified)
                observer->RemoveUnitFlag(UNIT_FLAG_PACIFIED);
            if (!session.hadSilenced)
                observer->RemoveUnitFlag(UNIT_FLAG_SILENCED);
            if (!session.hadNotSelectable)
                observer->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        }

        observer->SetCanFly(session.hadCanFly);

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
    std::map<uint64, RebornPendingReturn> _pendingReturns;
    std::map<uint64, RebornResumeWatch> _resumeWatches;
    std::map<uint32, RebornPreloginRequest> _preloginRequests;
    std::map<uint32, RebornCarrierRecord> _carrierCache;
    std::map<uint64, std::chrono::steady_clock::time_point> _chatLastMessageAt;
    std::map<uint64, RebornAssistHandshake> _assistHandshakes;
    std::map<uint64, std::chrono::steady_clock::time_point> _assistLastMoveAt;
    std::map<uint64, std::chrono::steady_clock::time_point> _assistLastTurnAt;
    std::map<uint64, ObjectGuid> _nativeAssistTargetByObserver;
    std::map<uint64, ObjectGuid> _nativeAssistObserverByTarget;
    uint32 _rosterGeneration = 0;
    uint32 _consentGeneration = 0;
    uint32 _chatGeneration = 0;
    uint32 _quickReplyGeneration = 0;
    uint32 _assistGeneration = 0;
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
        g_RebornAutoLeaveGroupAuthenticatedCarrier =
            sConfigMgr->GetOption<bool>("RebornSpectator.AutoLeaveGroupAuthenticatedCarrier", true);
        g_RebornPreloginBridgeEnabled =
            sConfigMgr->GetOption<bool>("RebornSpectator.PreloginBridgeEnable", false);
        g_RebornAutoCarrierProvisionEnabled =
            sConfigMgr->GetOption<bool>("RebornSpectator.AutoCarrierProvisionEnable", false);
        g_RebornAutoCarrierOnlyForEmptyAccount =
            sConfigMgr->GetOption<bool>("RebornSpectator.AutoCarrierOnlyForEmptyAccount", true);
        g_RebornHideAutoCarrierFromEnum =
            sConfigMgr->GetOption<bool>("RebornSpectator.AutoCarrierHideFromCharacterEnum", false);

        uint32 retryMs = sConfigMgr->GetOption<uint32>("RebornSpectator.BindRetryMs", 250);
        uint32 timeoutMs = sConfigMgr->GetOption<uint32>("RebornSpectator.BindTimeoutMs", 7000);
        uint32 carrierDelayMs = sConfigMgr->GetOption<uint32>("RebornSpectator.CarrierLoginDelayMs", 1500);
        uint32 carrierAliveWaitSeconds =
            sConfigMgr->GetOption<uint32>("RebornSpectator.CarrierAliveWaitSeconds", 600);
        uint32 requestTtlSeconds = sConfigMgr->GetOption<uint32>("RebornSpectator.RequestTtlSeconds", 120);
        uint32 preloginTtlMs =
            sConfigMgr->GetOption<uint32>("RebornSpectator.PreloginRequestTtlMs", 15000);
        float preloginOffset =
            sConfigMgr->GetOption<float>("RebornSpectator.PreloginCarrierOffset", 12.0f);
        uint32 carrierRace = sConfigMgr->GetOption<uint32>("RebornSpectator.AutoCarrierRace", RACE_HUMAN);
        uint32 carrierClass = sConfigMgr->GetOption<uint32>("RebornSpectator.AutoCarrierClass", CLASS_WARRIOR);
        uint32 carrierGender = sConfigMgr->GetOption<uint32>("RebornSpectator.AutoCarrierGender", GENDER_MALE);

        g_RebornBindRetryMs = std::max<uint32>(100, std::min<uint32>(retryMs, 2000));
        g_RebornBindTimeoutMs = std::max<uint32>(1000, std::min<uint32>(timeoutMs, 30000));
        g_RebornCarrierLoginDelayMs = std::max<uint32>(500, std::min<uint32>(carrierDelayMs, 10000));
        g_RebornCarrierAliveWaitMs =
            std::max<uint32>(30, std::min<uint32>(carrierAliveWaitSeconds, 1800)) * 1000;
        g_RebornRequestTtlSeconds = std::max<uint32>(30, std::min<uint32>(requestTtlSeconds, 600));
        g_RebornPreloginRequestTtlMs =
            std::max<uint32>(5000, std::min<uint32>(preloginTtlMs, 60000));
        g_RebornPreloginCarrierOffset =
            std::max<float>(5.0f, std::min<float>(preloginOffset, 30.0f));
        g_RebornAutoCarrierRace = uint8(std::min<uint32>(carrierRace, 255));
        g_RebornAutoCarrierClass = uint8(std::min<uint32>(carrierClass, 255));
        g_RebornAutoCarrierGender = uint8(std::min<uint32>(carrierGender, 255));
    }
};

class RebornSpectatorAccountScript : public AccountScript
{
public:
    RebornSpectatorAccountScript() : AccountScript("RebornSpectatorAccountScript") { }

    void OnAccountCharacterCreateRequest(
        WorldSession* session,
        std::string const& name,
        bool& consumed) override
    {
        if (!consumed)
            consumed = RebornSpectatorMgr::Instance().HandleAuthenticatedPreloginSignal(session, name);
    }

    void OnAccountSelectCharacter(WorldSession* session, ObjectGuid& guid) override
    {
        RebornSpectatorMgr::Instance().SelectAuthenticatedLoginCharacter(session, guid);
    }

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

    void OnPlayerLoadFromDB(Player* player) override
    {
        RebornSpectatorMgr::Instance().PrepareAuthenticatedCarrierWorld(player);
    }

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

    void OnPlayerKilledByCreature(Creature* /*killer*/, Player* killed) override
    {
        RebornSpectatorMgr::Instance().HandlePlayerDeath(killed, "creature");
    }

    void OnPlayerPVPKill(Player* /*killer*/, Player* killed) override
    {
        RebornSpectatorMgr::Instance().HandlePlayerDeath(killed, "pvp");
    }

    void OnPlayerJustDied(Player* player) override
    {
        RebornSpectatorMgr::Instance().HandlePlayerDeath(player, "generic");
    }

    void OnPlayerResurrect(
        Player* player,
        float /*restore_percent*/,
        bool& /*applySickness*/) override
    {
        RebornSpectatorMgr::Instance().HandlePlayerResurrect(player);
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
            { "watchers",      HandleWatchersCommand,      SEC_PLAYER,     Console::No },
            { "roster",        HandleRosterCommand,        SEC_PLAYER,     Console::No },
            { "allow",         HandleAllowCommand,         SEC_PLAYER,     Console::No },
            { "deny",          HandleDenyCommand,          SEC_PLAYER,     Console::No },
            { "consent",       HandleConsentCommand,       SEC_PLAYER,     Console::No },
            { "consentui",     HandleConsentUiCommand,     SEC_PLAYER,     Console::No },
            { "chat",          HandleChatCommand,          SEC_PLAYER,     Console::No },
            { "replies",       HandleRepliesCommand,       SEC_PLAYER,     Console::No },
            { "assistinvite",  HandleAssistInviteCommand,  SEC_PLAYER,     Console::No },
            { "assistaccept",  HandleAssistAcceptCommand,  SEC_PLAYER,     Console::No },
            { "assistdeny",    HandleAssistDenyCommand,    SEC_PLAYER,     Console::No },
            { "assistrevoke",  HandleAssistRevokeCommand,  SEC_PLAYER,     Console::No },
            { "assiststatus",  HandleAssistStatusCommand,  SEC_PLAYER,     Console::No },
            { "assistmove",    HandleAssistMoveCommand,    SEC_PLAYER,     Console::No },
            { "watchguid",     HandleWatchGuidCommand,     SEC_PLAYER,     Console::No },
            { "watchasguid",   HandleWatchAsGuidCommand,   SEC_PLAYER,     Console::No },
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

    static bool HandleWatchersCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().ShowWatchers(player);
        return true;
    }

    static bool HandleRosterCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().RefreshWatcherRoster(player);
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

    static bool HandleConsentUiCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().RefreshOwnConsent(player);
        return true;
    }

    static bool HandleChatCommand(ChatHandler* handler, Acore::ChatCommands::Tail message)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().SendRoomChat(player, std::string(message));
        return true;
    }

    static bool HandleRepliesCommand(ChatHandler* handler, Optional<std::string> locale)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().PushQuickReplies(
                player,
                locale && *locale == "enUS" ? "enUS" : "zhCN");
        return true;
    }

    static bool HandleAssistInviteCommand(ChatHandler* handler, uint32 observerGuidLow)
    {
        if (Player* target = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().InviteAssist(target, observerGuidLow);
        return true;
    }

    static bool HandleAssistAcceptCommand(ChatHandler* handler, uint32 targetGuidLow)
    {
        if (Player* observer = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().RespondAssist(observer, targetGuidLow, true);
        return true;
    }

    static bool HandleAssistDenyCommand(ChatHandler* handler, uint32 targetGuidLow)
    {
        if (Player* observer = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().RespondAssist(observer, targetGuidLow, false);
        return true;
    }

    static bool HandleAssistRevokeCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* target = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().RevokeAssist(target);
        return true;
    }

    static bool HandleAssistStatusCommand(ChatHandler* handler, Optional<std::string> /*unused*/)
    {
        if (Player* player = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().RefreshAssist(player);
        return true;
    }

    static bool HandleAssistMoveCommand(ChatHandler* handler, Optional<std::string> action)
    {
        Player* observer = handler->GetSession()->GetPlayer();
        if (!observer)
            return true;

        if (!action || action->size() != 1)
        {
            SendPrototypeMessage(
                observer,
                "|cffff5555Usage: .rebornspec assistmove F, B, L, R, or X (stop).|r");
            return true;
        }

        RebornSpectatorMgr::Instance().AssistMove(observer, (*action)[0]);
        return true;
    }

    static bool HandleWatchGuidCommand(ChatHandler* handler, uint32 targetGuidLow)
    {
        if (Player* carrier = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().StartAuthenticatedCarrierRequest(carrier, targetGuidLow);
        return true;
    }

    static bool HandleWatchAsGuidCommand(ChatHandler* handler, uint32 targetGuidLow)
    {
        if (Player* observer = handler->GetSession()->GetPlayer())
            RebornSpectatorMgr::Instance().StartExistingCharacterRequest(observer, targetGuidLow);
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
