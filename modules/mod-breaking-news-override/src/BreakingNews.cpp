/*
 * HighFork-compatible Breaking News delivery.
 * Based on wowshub/Breaking-News-Rewrite and adapted to the current
 * SERVERHOOK_CAN_PACKET_SEND const-packet API.
 */

#include "BreakingNews.h"

#include "ScriptDefines/AccountScript.h"
#include "Config.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"
#include "Warden.h"
#include "WardenPayloadMgr.h"

#include <algorithm>
#include <atomic>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <mutex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#ifdef _WIN32
#include <Windows.h>
#endif

namespace
{
constexpr uint16 PRE_PAYLOAD_ID = 9520;
constexpr uint16 CHUNK_PAYLOAD_ID = 9521;
constexpr uint16 POST_PAYLOAD_ID = 9522;
constexpr std::size_t HEX_CHUNK_SIZE = 160;

std::atomic<bool> g_enabled{ false };
std::atomic<uint32> g_retryIntervalMs{ 100 };
std::atomic<uint32> g_retryWindowMs{ 15000 };
std::atomic<uint32> g_deliveryDelayMs{ 400 };

std::mutex g_contentMutex;
std::vector<std::string> g_encodedChunkPayloads;

std::mutex g_pendingMutex;
std::unordered_map<uint32, uint32> g_pendingAccounts;
uint32 g_retryAccumulatorMs = 0;

std::filesystem::path GetExecutableDirectory()
{
#ifdef _WIN32
    std::wstring buffer(32768, L'\0');
    DWORD const length = GetModuleFileNameW(nullptr, buffer.data(), static_cast<DWORD>(buffer.size()));
    if (length > 0 && length < buffer.size())
    {
        buffer.resize(length);
        return std::filesystem::path(buffer).parent_path();
    }
#endif
    return std::filesystem::current_path();
}

std::filesystem::path ResolveContentPath(std::string const& configuredPath)
{
    std::filesystem::path path(configuredPath);
    if (path.is_absolute())
        return path;

    return GetExecutableDirectory() / path;
}

bool ReadHtmlFile(std::filesystem::path const& path, std::string& result)
{
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open())
        return false;

    std::ostringstream stream;
    stream << file.rdbuf();
    result = stream.str();

    result.erase(std::remove(result.begin(), result.end(), '\r'), result.end());
    result.erase(std::remove(result.begin(), result.end(), '\n'), result.end());
    return !result.empty();
}

std::string EscapeLuaSingleQuoted(std::string const& value)
{
    std::string escaped;
    escaped.reserve(value.size() + 32);

    for (char const character : value)
    {
        switch (character)
        {
            case '\\': escaped += "\\\\"; break;
            case '\'': escaped += "\\\'"; break;
            case '\r': break;
            case '\n': escaped += "\\n"; break;
            default: escaped += character; break;
        }
    }

    return escaped;
}

std::string HexEncode(std::string const& value)
{
    static constexpr char digits[] = "0123456789ABCDEF";
    std::string encoded;
    encoded.reserve(value.size() * 2);

    for (unsigned char const byte : value)
    {
        encoded += digits[(byte >> 4) & 0x0F];
        encoded += digits[byte & 0x0F];
    }

    return encoded;
}

void ClearPendingDeliveries()
{
    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_pendingAccounts.clear();
}

void QueuePendingDelivery(uint32 accountId)
{
    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_pendingAccounts[accountId] = 0;
}

void RemovePendingDelivery(uint32 accountId)
{
    std::lock_guard<std::mutex> lock(g_pendingMutex);
    g_pendingAccounts.erase(accountId);
}

bool LoadBreakingNewsContent()
{
    std::string const configuredPath = sConfigMgr->GetOption<std::string>(
        "BreakingNews.CharacterHtmlPath", "./breakingnews_character.html");
    std::string const title = sConfigMgr->GetOption<std::string>(
        "BreakingNews.CharacterTitle", "Newest updates 最新更新");

    if (configuredPath.empty())
    {
        LOG_ERROR("module", "mod-breaking-news: BreakingNews.CharacterHtmlPath is empty.");
        return false;
    }

    std::filesystem::path const resolvedPath = ResolveContentPath(configuredPath);
    std::string body;
    if (!ReadHtmlFile(resolvedPath, body))
    {
        LOG_ERROR("module", "mod-breaking-news: failed to read HTML file '{}'.", resolvedPath.string());
        std::lock_guard<std::mutex> lock(g_contentMutex);
        g_encodedChunkPayloads.clear();
        return false;
    }

    std::string const payload = Acore::StringFormat(
        "local a,b,c,d=ServerAlertFrame,ServerAlertText,ServerAlertTitle,CharacterSelect;"
        "if a and b and c and d then "
        "a:SetParent(d);a:ClearAllPoints();a:SetPoint('TOPLEFT',d,'TOPLEFT',10,-130);"
        "a:SetFrameStrata('DIALOG');c:SetText('{}');b:SetText('{}');a:Show();"
        "else message('BreakingNews: required GlueXML frames are missing.') end",
        EscapeLuaSingleQuoted(title), EscapeLuaSingleQuoted(body));

    std::string const encoded = HexEncode(payload);
    std::vector<std::string> encodedChunkPayloads;
    encodedChunkPayloads.reserve((encoded.size() + HEX_CHUNK_SIZE - 1) / HEX_CHUNK_SIZE);
    for (std::size_t offset = 0; offset < encoded.size(); offset += HEX_CHUNK_SIZE)
    {
        std::string const chunk = encoded.substr(offset, HEX_CHUNK_SIZE);
        encodedChunkPayloads.emplace_back("wlhex=wlhex..'" + chunk + "';");
    }

    {
        std::lock_guard<std::mutex> lock(g_contentMutex);
        g_encodedChunkPayloads = std::move(encodedChunkPayloads);
    }

    LOG_INFO("module", "mod-breaking-news: loaded '{}' ({} body bytes).", resolvedPath.string(), body.size());
    return true;
}

void SendEncodedPayload(
    Warden* warden,
    WardenPayloadMgr* payloadMgr,
    std::vector<std::string> const& encodedChunkPayloads)
{
    std::string const prePayload = "wlhex='';";
    std::string const postPayload =
        "local s=wlhex:gsub('..',function(h)return string.char(tonumber(h,16))end);"
        "local f,e=loadstring(s);if not f then message(e)else f()end";
    payloadMgr->RegisterPayload(prePayload, PRE_PAYLOAD_ID, true);
    payloadMgr->QueuePayload(PRE_PAYLOAD_ID);
    warden->ForceChecks();

    for (std::string const& chunkPayload : encodedChunkPayloads)
    {
        payloadMgr->RegisterPayload(chunkPayload, CHUNK_PAYLOAD_ID, true);
        payloadMgr->QueuePayload(CHUNK_PAYLOAD_ID);
        warden->ForceChecks();
    }

    payloadMgr->RegisterPayload(postPayload, POST_PAYLOAD_ID, true);
    payloadMgr->QueuePayload(POST_PAYLOAD_ID);
    warden->ForceChecks();
}

bool TryDeliver(WorldSession* session, char const* reason)
{
    if (!session || session->GetPlayer())
        return false;

    Warden* warden = session->GetWarden();
    if (!warden || !warden->IsInitialized())
        return false;

    WardenPayloadMgr* payloadMgr = warden->GetPayloadMgr();
    if (!payloadMgr)
        return false;

    if (!sConfigMgr->GetOption<bool>("BreakingNews.Cache", true) && !LoadBreakingNewsContent())
        return false;

    std::vector<std::string> encodedChunkPayloads;
    {
        std::lock_guard<std::mutex> lock(g_contentMutex);
        encodedChunkPayloads = g_encodedChunkPayloads;
    }

    if (encodedChunkPayloads.empty())
        return false;

    SendEncodedPayload(warden, payloadMgr, encodedChunkPayloads);
    LOG_INFO("module", "mod-breaking-news: queued panel for account {} via {}.", session->GetAccountId(), reason);
    return true;
}

class BreakingNewsServerScript final : public ServerScript
{
public:
    BreakingNewsServerScript() : ServerScript("BreakingNewsServerScript", { SERVERHOOK_CAN_PACKET_SEND }) { }

    bool CanPacketSend(WorldSession* session, WorldPacket const& packet) override
    {
        if (!g_enabled.load() || packet.GetOpcode() != SMSG_CHAR_ENUM || !session)
            return true;

        uint32 const accountId = session->GetAccountId();
        QueuePendingDelivery(accountId);

        if (sConfigMgr->GetOption<bool>("BreakingNews.Verbose", false))
            LOG_INFO("module", "mod-breaking-news: account {} queued until the character-selection critical path is complete.", accountId);

        return true;
    }
};

class BreakingNewsAccountScript final : public AccountScript
{
public:
    BreakingNewsAccountScript() : AccountScript(
        "BreakingNewsAccountScript", { ACCOUNTHOOK_ON_ACCOUNT_SELECT_CHARACTER }) { }

    void OnAccountSelectCharacter(WorldSession* session, ObjectGuid& /*guid*/) override
    {
        if (!session)
            return;

        // Never carry a not-yet-started GlueXML payload into character login.
        RemovePendingDelivery(session->GetAccountId());
    }
};

class BreakingNewsWorldScript final : public WorldScript
{
public:
    BreakingNewsWorldScript() : WorldScript(
        "BreakingNewsWorldScript", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_UPDATE }) { }

    void OnAfterConfigLoad(bool /*reload*/) override
    {
        bool const masterEnabled = sConfigMgr->GetOption<bool>("BreakingNews.Enable", false);
        uint32 const displayMode = std::clamp<uint32>(
            sConfigMgr->GetOption<uint32>("BreakingNews.DisplayMode", 3), 0, 3);
        bool const useWardenDelivery = sConfigMgr->GetOption<bool>(
            "BreakingNews.CharacterUseWardenDelivery", false);
        bool const characterEnabled = masterEnabled && useWardenDelivery &&
            (displayMode == 2 || displayMode == 3);
        g_enabled.store(characterEnabled);

        uint32 retryInterval = sConfigMgr->GetOption<uint32>("BreakingNews.RetryIntervalMs", 100);
        uint32 retryWindow = sConfigMgr->GetOption<uint32>("BreakingNews.RetryWindowMs", 15000);
        uint32 deliveryDelay = sConfigMgr->GetOption<uint32>("BreakingNews.CharacterDeliveryDelayMs", 400);
        g_retryIntervalMs.store(std::clamp<uint32>(retryInterval, 50, 1000));
        g_retryWindowMs.store(std::clamp<uint32>(retryWindow, 1000, 60000));
        g_deliveryDelayMs.store(std::clamp<uint32>(deliveryDelay, 0, 5000));

        ClearPendingDeliveries();
        g_retryAccumulatorMs = 0;

        if (!masterEnabled)
        {
            LOG_INFO("module", "mod-breaking-news: disabled.");
            return;
        }

        if (!characterEnabled)
        {
            if ((displayMode == 2 || displayMode == 3) && !useWardenDelivery)
                LOG_INFO("module", "mod-breaking-news: character page uses local GlueXML content; Warden delivery disabled.");
            else
                LOG_INFO("module", "mod-breaking-news: display mode {} does not include the character-selection page.", displayMode);
            return;
        }

        if (LoadBreakingNewsContent())
            LOG_INFO(
                "module",
                "mod-breaking-news: enabled for character selection (display mode {}) with a {} ms non-blocking delivery delay.",
                displayMode,
                g_deliveryDelayMs.load());
    }

    void OnUpdate(uint32 diff) override
    {
        if (!g_enabled.load())
            return;

        g_retryAccumulatorMs += diff;
        uint32 const retryInterval = g_retryIntervalMs.load();
        if (g_retryAccumulatorMs < retryInterval)
            return;

        uint32 const elapsed = g_retryAccumulatorMs;
        g_retryAccumulatorMs = 0;

        std::vector<uint32> pending;
        std::vector<uint32> expired;
        {
            std::lock_guard<std::mutex> lock(g_pendingMutex);
            for (auto& [accountId, waitedMs] : g_pendingAccounts)
            {
                waitedMs += elapsed;
                if (waitedMs >= g_retryWindowMs.load())
                    expired.push_back(accountId);
                else if (waitedMs >= g_deliveryDelayMs.load())
                    pending.push_back(accountId);
            }

            for (uint32 const accountId : expired)
                g_pendingAccounts.erase(accountId);
        }

        for (uint32 const accountId : expired)
            LOG_ERROR("module", "mod-breaking-news: delivery timed out for account {}; Warden never became ready.", accountId);

        for (uint32 const accountId : pending)
        {
            WorldSession* session = sWorldSessionMgr->FindSession(accountId);
            if (!session || session->GetPlayer())
            {
                RemovePendingDelivery(accountId);
                continue;
            }

            if (TryDeliver(session, "Warden retry"))
                RemovePendingDelivery(accountId);
        }
    }
};
}

void AddBreakingNewsScripts()
{
    new BreakingNewsWorldScript();
    new BreakingNewsServerScript();
    new BreakingNewsAccountScript();
}

void Addmod_breaking_news_overrideScripts()
{
    AddBreakingNewsScripts();
}
