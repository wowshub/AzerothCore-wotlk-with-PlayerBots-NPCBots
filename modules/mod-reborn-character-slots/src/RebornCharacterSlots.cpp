#include "Config.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Realm.h"
#include "ScriptMgr.h"
#include "World.h"
#include "WorldSession.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cctype>
#include <mutex>
#include <optional>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{
struct PriceTier
{
    uint32 First = 0;
    uint32 Last = 0;
    uint32 Price = 0;
};

struct PendingCharge
{
    std::string RequestKey;
    std::string CharacterName;
    uint32 SlotNumber = 0;
    uint32 Price = 0;
};

class RebornCharacterSlotBilling
{
public:
    static RebornCharacterSlotBilling& Instance()
    {
        static RebornCharacterSlotBilling instance;
        return instance;
    }

    void LoadConfig()
    {
        _enabled = sConfigMgr->GetOption<bool>("RebornCharacterSlots.Enabled", false);
        // S.7.4 client intentionally lets the first ten slots pass without a
        // network quote.  Keep the configurable free tier within that public
        // contract and the supported 50-slot client ceiling.
        _freeSlots = std::clamp<uint32>(
            sConfigMgr->GetOption<uint32>("RebornCharacterSlots.FreeSlots", 10), 10, 50);
        _currencyCode = sConfigMgr->GetOption<std::string>("RebornCharacterSlots.CurrencyCode", "DP");
        _database = sConfigMgr->GetOption<std::string>("RebornCharacterSlots.Database", "sahtout_site");
        _reserveProcedure = sConfigMgr->GetOption<std::string>("RebornCharacterSlots.ReserveProcedure", "reborn_character_slot_reserve");
        _commitProcedure = sConfigMgr->GetOption<std::string>("RebornCharacterSlots.CommitProcedure", "reborn_character_slot_commit");
        _refundProcedure = sConfigMgr->GetOption<std::string>("RebornCharacterSlots.RefundProcedure", "reborn_character_slot_refund");
        _reconcileProcedure = sConfigMgr->GetOption<std::string>("RebornCharacterSlots.ReconcileProcedure", "reborn_character_slot_reconcile_stale");
        _failClosed = sConfigMgr->GetOption<bool>("RebornCharacterSlots.FailClosed", true);
        _refundOnFailure = sConfigMgr->GetOption<bool>("RebornCharacterSlots.RefundOnFailure", true);
        _reservationTimeout = std::max<uint32>(30, sConfigMgr->GetOption<uint32>("RebornCharacterSlots.ReservationTimeoutSeconds", 300));
        _gmBypass = sConfigMgr->GetOption<bool>("RebornCharacterSlots.GMBypassEnabled", true);
        _gmBypassSecurity = sConfigMgr->GetOption<uint32>("RebornCharacterSlots.GMBypassSecurity", 3);

        _currencyValid = _currencyCode == "DP";
        _identifiersValid = IsIdentifier(_database) && IsIdentifier(_reserveProcedure) &&
            IsIdentifier(_commitProcedure) && IsIdentifier(_refundProcedure) && IsIdentifier(_reconcileProcedure);
        _priceTiersText = sConfigMgr->GetOption<std::string>("RebornCharacterSlots.PriceTiers",
            "11-20:100,21-30:200,31-50:400");
        _tiers = ParseTiers(_priceTiersText);

        if (!_currencyValid || !_identifiersValid || _tiers.empty())
        {
            LOG_ERROR("module.reborn-character-slots", "CurrencyCode must be DP, identifiers must be valid, and PriceTiers must not be empty; paid slot requests will {}.",
                _failClosed ? "be rejected" : "continue for free (development mode)");
        }

        LOG_INFO("module.reborn-character-slots", "Loaded: enabled={}, freeSlots={}, currency={}, tiers={}, failClosed={}, refundOnFailure={}.",
            _enabled, _freeSlots, _currencyCode, _tiers.size(), _failClosed, _refundOnFailure);
    }

    void ReconcileStale()
    {
        if (!_enabled || !_identifiersValid)
            return;

        QueryResult result = LoginDatabase.Query("CALL `{}`.`{}`({})", _database, _reconcileProcedure, _reservationTimeout);
        if (!result)
        {
            LOG_ERROR("module.reborn-character-slots", "Startup stale-reservation reconciliation returned no result. Check SQL installation and grants.");
            return;
        }

        Field* fields = result->Fetch();
        LOG_INFO("module.reborn-character-slots", "Startup reconciliation: committed={}, refunded={}.",
            fields[0].Get<uint32>(), fields[1].Get<uint32>());
    }

    void PublishQuoteConfig()
    {
        if (!_identifiersValid)
            return;

        std::string escapedTiers = _priceTiersText;
        LoginDatabase.EscapeString(escapedTiers);
        LoginDatabase.DirectExecute(
            "INSERT INTO `{}`.`reborn_character_slot_public_config` "
            "(`realm_id`,`enabled`,`free_slots`,`currency_code`,`price_tiers`,"
            "`gm_bypass_enabled`,`gm_bypass_security`) "
            "VALUES ({},{},{},'DP','{}',{},{}) ON DUPLICATE KEY UPDATE "
            "`enabled`=VALUES(`enabled`),`free_slots`=VALUES(`free_slots`),"
            "`currency_code`=VALUES(`currency_code`),`price_tiers`=VALUES(`price_tiers`),"
            "`gm_bypass_enabled`=VALUES(`gm_bypass_enabled`),"
            "`gm_bypass_security`=VALUES(`gm_bypass_security`),"
            "`updated_at`=CURRENT_TIMESTAMP",
            _database, realm.Id.Realm, _enabled ? 1 : 0, _freeSlots, escapedTiers,
            _gmBypass ? 1 : 0, _gmBypassSecurity);
        LOG_INFO("module.reborn-character-slots",
            "Published read-only quote configuration: realm={}, enabled={}, freeSlots={}, tiers={}.",
            realm.Id.Realm, _enabled, _freeSlots, _priceTiersText);
    }

    void Prepare(WorldSession* session, std::string const& characterName, uint32 slotNumber, bool& allowed)
    {
        if (!_enabled || !session || slotNumber <= _freeSlots)
            return;

        if (_gmBypass && uint32(session->GetSecurity()) >= _gmBypassSecurity)
        {
            LOG_INFO("module.reborn-character-slots", "GM bypass account={} slot={}.", session->GetAccountId(), slotNumber);
            return;
        }

        std::optional<uint32> price = PriceFor(slotNumber);
        if (!price || !_currencyValid || !_identifiersValid)
        {
            allowed = !_failClosed;
            LOG_ERROR("module.reborn-character-slots", "No valid billing configuration for account={} slot={}; allowed={}.",
                session->GetAccountId(), slotNumber, allowed);
            return;
        }

        {
            std::lock_guard<std::mutex> lock(_mutex);
            if (_pending.find(session->GetAccountId()) != _pending.end())
            {
                allowed = false;
                LOG_WARN("module.reborn-character-slots", "Concurrent in-flight create rejected for account={} name={}.",
                    session->GetAccountId(), characterName);
                return;
            }
        }

        std::string requestKey = MakeRequestKey(session->GetAccountId(), slotNumber);
        std::string escapedName = characterName;
        LoginDatabase.EscapeString(escapedName);

        QueryResult result = LoginDatabase.Query("CALL `{}`.`{}`('{}', {}, {}, {}, '{}', {})",
            _database, _reserveProcedure, requestKey, session->GetAccountId(), realm.Id.Realm,
            slotNumber, escapedName, *price);

        if (!result)
        {
            allowed = !_failClosed;
            LOG_ERROR("module.reborn-character-slots", "DP reserve database call failed for account={} slot={}; allowed={}.",
                session->GetAccountId(), slotNumber, allowed);
            return;
        }

        Field* fields = result->Fetch();
        uint32 resultCode = fields[0].Get<uint32>();
        uint64 ledgerId = fields[1].Get<uint64>();
        uint32 balanceAfter = fields[2].Get<uint32>();
        if (resultCode != 0)
        {
            allowed = false;
            LOG_WARN("module.reborn-character-slots", "DP reserve denied account={} slot={} price={} code={} balance={}.",
                session->GetAccountId(), slotNumber, *price, resultCode, balanceAfter);
            return;
        }

        {
            std::lock_guard<std::mutex> lock(_mutex);
            _pending.emplace(session->GetAccountId(), PendingCharge{ requestKey, characterName, slotNumber, *price });
        }

        LOG_INFO("module.reborn-character-slots", "DP reserved account={} name={} slot={} price={} {} balanceAfter={} ledger={}.",
            session->GetAccountId(), characterName, slotNumber, *price, _currencyCode, balanceAfter, ledgerId);
    }

    void Complete(WorldSession* session, std::string const& characterName, bool success)
    {
        if (!_enabled || !session)
            return;

        PendingCharge pending;
        {
            std::lock_guard<std::mutex> lock(_mutex);
            auto itr = _pending.find(session->GetAccountId());
            if (itr == _pending.end())
                return;
            if (itr->second.CharacterName != characterName)
            {
                LOG_ERROR("module.reborn-character-slots", "Create result name mismatch for account={}: pending={}, result={}; reservation left for startup reconciliation.",
                    session->GetAccountId(), itr->second.CharacterName, characterName);
                return;
            }
            pending = itr->second;
            _pending.erase(itr);
        }

        std::string const& procedure = success ? _commitProcedure : _refundProcedure;
        if (!success && !_refundOnFailure)
        {
            LOG_ERROR("module.reborn-character-slots", "Character creation failed but RefundOnFailure=0: account={} request={}.",
                session->GetAccountId(), pending.RequestKey);
            return;
        }

        QueryResult result = LoginDatabase.Query("CALL `{}`.`{}`('{}', {})", _database, procedure,
            pending.RequestKey, session->GetAccountId());
        if (!result)
        {
            LOG_ERROR("module.reborn-character-slots", "Unable to {} DP reservation account={} request={}; startup reconciliation will repair it.",
                success ? "commit" : "refund", session->GetAccountId(), pending.RequestKey);
            return;
        }

        Field* fields = result->Fetch();
        LOG_INFO("module.reborn-character-slots", "DP reservation {} account={} slot={} price={} result={} balance={}.",
            success ? "committed" : "refunded", session->GetAccountId(), pending.SlotNumber, pending.Price,
            fields[0].Get<uint32>(), fields[1].Get<uint32>());
    }

private:
    static bool IsIdentifier(std::string const& value)
    {
        return !value.empty() && std::all_of(value.begin(), value.end(), [](unsigned char c)
        {
            return std::isalnum(c) || c == '_';
        });
    }

    static std::vector<PriceTier> ParseTiers(std::string const& text)
    {
        std::vector<PriceTier> tiers;
        std::stringstream stream(text);
        std::string item;
        while (std::getline(stream, item, ','))
        {
            std::size_t dash = item.find('-');
            std::size_t colon = item.find(':');
            if (dash == std::string::npos || colon == std::string::npos || dash >= colon)
                continue;
            try
            {
                PriceTier tier{ uint32(std::stoul(item.substr(0, dash))),
                    uint32(std::stoul(item.substr(dash + 1, colon - dash - 1))),
                    uint32(std::stoul(item.substr(colon + 1))) };
                if (tier.First > 0 && tier.First <= tier.Last)
                    tiers.push_back(tier);
            }
            catch (...)
            {
                LOG_ERROR("module.reborn-character-slots", "Ignored invalid price tier '{}'.", item);
            }
        }
        std::sort(tiers.begin(), tiers.end(), [](PriceTier const& a, PriceTier const& b) { return a.First < b.First; });
        return tiers;
    }

    std::optional<uint32> PriceFor(uint32 slotNumber) const
    {
        for (PriceTier const& tier : _tiers)
            if (slotNumber >= tier.First && slotNumber <= tier.Last)
                return tier.Price;
        return std::nullopt;
    }

    static std::string MakeRequestKey(uint32 accountId, uint32 slotNumber)
    {
        uint64 millis = uint64(std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
        uint64 serial = ++_serial;
        return "RCS-" + std::to_string(realm.Id.Realm) + "-" + std::to_string(accountId) + "-" +
            std::to_string(slotNumber) + "-" + std::to_string(millis) + "-" + std::to_string(serial);
    }

    bool _enabled = false;
    bool _currencyValid = false;
    bool _identifiersValid = false;
    bool _failClosed = true;
    bool _refundOnFailure = true;
    bool _gmBypass = true;
    uint32 _freeSlots = 10;
    uint32 _reservationTimeout = 300;
    uint32 _gmBypassSecurity = 3;
    std::string _currencyCode = "DP";
    std::string _database = "sahtout_site";
    std::string _reserveProcedure;
    std::string _commitProcedure;
    std::string _refundProcedure;
    std::string _reconcileProcedure;
    std::string _priceTiersText;
    std::vector<PriceTier> _tiers;
    std::mutex _mutex;
    std::unordered_map<uint32, PendingCharge> _pending;
    static std::atomic<uint64> _serial;
};

std::atomic<uint64> RebornCharacterSlotBilling::_serial{ 0 };

class RebornCharacterSlotsWorldScript : public WorldScript
{
public:
    RebornCharacterSlotsWorldScript() : WorldScript("RebornCharacterSlotsWorldScript") { }

    void OnBeforeConfigLoad(bool /*reload*/) override
    {
        RebornCharacterSlotBilling::Instance().LoadConfig();
    }

    void OnStartup() override
    {
        RebornCharacterSlotBilling::Instance().PublishQuoteConfig();
        RebornCharacterSlotBilling::Instance().ReconcileStale();
    }
};

class RebornCharacterSlotsAccountScript : public AccountScript
{
public:
    RebornCharacterSlotsAccountScript() : AccountScript("RebornCharacterSlotsAccountScript") { }

    void OnAccountCharacterCreatePrepared(WorldSession* session, std::string const& name, uint32 slotNumber, bool& allowed) override
    {
        RebornCharacterSlotBilling::Instance().Prepare(session, name, slotNumber, allowed);
    }

    void OnAccountCharacterCreateResult(WorldSession* session, std::string const& name, bool success) override
    {
        RebornCharacterSlotBilling::Instance().Complete(session, name, success);
    }
};
}

void AddRebornCharacterSlotsScripts()
{
    new RebornCharacterSlotsWorldScript();
    new RebornCharacterSlotsAccountScript();
}
