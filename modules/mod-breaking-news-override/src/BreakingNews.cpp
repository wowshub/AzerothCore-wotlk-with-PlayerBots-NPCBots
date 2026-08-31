/*
 * HighFork-compatible Breaking News delivery.
 * Based on wowshub/Breaking-News-Rewrite and adapted to the current
 * SERVERHOOK_CAN_PACKET_SEND const-packet API.
 */

#include "BreakingNews.h"

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

std::mutex g_contentMutex;
std::string g_formattedPayload;

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
        g_formattedPayload.clear();
        return false;
    }

    std::string const payload = Acore::StringFormat(
        "local a,b,c,d=ServerAlertFrame,ServerAlertText,ServerAlertTitle,CharacterSelect;"
        "if a and b and c and d then "
        "a:SetParent(d);a:ClearAllPoints();a:SetPoint('TOPLEFT',d,'TOPLEFT',10,-130);"
        "a:SetFrameStrata('DIALOG');c:SetText('{}');b:SetText('{}');a:Show();"
        "else message('BreakingNews: required GlueXML frames are missing.') end",
        EscapeLuaSingleQuoted(title), EscapeLuaSingleQuoted(body));

    {
        std::lock_guard<std::mutex> lock(g_contentMutex);
        g_formattedPayload = payload;
    }

    LOG_INFO("module", "mod-breaking-news: loaded '{}' ({} body bytes).", resolvedPath.string(), body.size());
    return true;
}

void SendEncodedPayload(Warden* warden, WardenPayloadMgr* payloadMgr, std::string const& payload)
{
    std::string const prePayload = "wlhex='';";
    std::string const postPayload =
        "local s=wlhex:gsub('..',function(h)return string.char(tonumber(h,16))end);"
        "local f,e=loadstring(s);if not f then message(e)else f()end";
    std::string const encoded = HexEncode(payload);

    payloadMgr->RegisterPayload(prePayload, PRE_PAYLOAD_ID, true);
    payloadMgr->QueuePayload(PRE_PAYLOAD_ID);
    warden->ForceChecks();

    for (std::size_t offset = 0; offset < encoded.size(); offset += HEX_CHUNK_SIZE)
    {
        std::string const chunk = encoded.substr(offset, HEX_CHUNK_SIZE);
        std::string const chunkPayload = "wlhex=wlhex..'" + chunk + "';";
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

    std::string payload;
    {
        std::lock_guard<std::mutex> lock(g_contentMutex);
        payload = g_formattedPayload;
    }

    if (payload.empty())
        return false;

    if (!sConfigMgr->GetOption<bool>("BreakingNews.Cache", true) && !LoadBreakingNewsContent())
        return false;

    {
        std::lock_guard<std::mutex> lock(g_contentMutex);
        payload = g_formattedPayload;
    }

    SendEncodedPayload(warden, payloadMgr, payload);
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

        if (TryDeliver(session, "SMSG_CHAR_ENUM"))
            RemovePendingDelivery(accountId);
        else if (sConfigMgr->GetOption<bool>("BreakingNews.Verbose", false))
            LOG_INFO("module", "mod-breaking-news: account {} is waiting for Warden initialization.", accountId);

        return true;
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
        bool const characterEnabled = masterEnabled && (displayMode == 2 || displayMode == 3);
        g_enabled.store(characterEnabled);

        uint32 retryInterval = sConfigMgr->GetOption<uint32>("BreakingNews.RetryIntervalMs", 100);
        uint32 retryWindow = sConfigMgr->GetOption<uint32>("BreakingNews.RetryWindowMs", 15000);
        g_retryIntervalMs.store(std::clamp<uint32>(retryInterval, 50, 1000));
        g_retryWindowMs.store(std::clamp<uint32>(retryWindow, 1000, 60000));

        ClearPendingDeliveries();
        g_retryAccumulatorMs = 0;

        if (!masterEnabled)
        {
            LOG_INFO("module", "mod-breaking-news: disabled.");
            return;
        }

        if (!characterEnabled)
        {
            LOG_INFO("module", "mod-breaking-news: display mode {} does not include the character-selection page.", displayMode);
            return;
        }

        if (LoadBreakingNewsContent())
            LOG_INFO("module", "mod-breaking-news: enabled for character selection (display mode {}) with reliable Warden retry delivery.", displayMode);
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
                else
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
}

void Addmod_breaking_news_overrideScripts()
{
    AddBreakingNewsScripts();
}
