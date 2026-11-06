// WHTAL1A: two owned common talents. Browsing a spec never activates it.
#include "ScriptMgr.h"
#include "Player.h"
#include "WorldSession.h"
#include "Chat.h"
#include "CommandScript.h"
#include "DatabaseEnv.h"
#include "Transaction.h"
#include "DataMap.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "Log.h"
#include "RebornWitchHunterTalentData.h"
#include <atomic>
#include <chrono>
#include <string>
using namespace Acore::ChatCommands;
namespace
{
constexpr uint32 Night = 9005067, Survival = 9005068, ResetCopper = 100000;
constexpr char Key[] = "Reborn.WHTAL1A";
bool storageReady = false;
std::atomic<uint32> serial{1};
struct State : DataMap::Base
{
    bool loaded = false, stored = false, busy = false, quote = false;
    uint32 revision = 0, mask = 0, tick = 0, quoteToken = 0, quoteRevision = 0;
    std::chrono::steady_clock::time_point quoteTime{};
};
bool Hunter(Player* p) { return p && p->getClass() == CLASS_WITCH_HUNTER; }
bool Contract()
{
    auto n = sSpellMgr->GetSpellInfo(Night);
    auto s = sSpellMgr->GetSpellInfo(Survival);
    return n && s && n->SpellFamilyName == 21 && s->SpellFamilyName == 21 &&
        n->IsPassive() && s->IsPassive() &&
        n->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_CRIT_PCT) && n->Effects[EFFECT_1].BasePoints == 2 &&
        s->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_AURA_DURATION_BY_DISPEL) &&
        s->Effects[EFFECT_0].BasePoints == -31 && s->Effects[EFFECT_0].MiscValue == 3;
}
void Reply(Player* p, uint32 nonce, char const* status, uint32 token = 0)
{
    auto s = p->CustomData.GetDefault<State>(Key);
    ChatHandler(p->GetSession()).PSendSysMessage("WHT1|{}|{}|{}|{}|{}|{}|{}|{}|{}|10|{}|{}",
        nonce, p->GetGUID().GetCounter(), s->revision, s->mask, p->GetLevel(),
        WHT1::AE(p->GetLevel()), WHT1::TE(p->GetLevel()),
        s->loaded && WHT1::Valid(s->mask, p->GetLevel()) ? 1 : 0, s->loaded ? 1 : 0, token, status);
}
// The receipt is committed with the talent rows AND native gold snapshot.
// Recovery locks the same character row; it cannot race an unresolved COMMIT.
bool Recover(Player* p, std::string const& operation, bool& committed)
{
    auto q = CharacterDatabase.Query("CALL reborn_wht1_recover({},{},'{}')",
        p->GetGUID().GetCounter(), p->GetSession()->GetAccountId(), operation);
    if (!q) return false;
    auto f = q->Fetch();
    committed = f[1].Get<uint32>() == 1;
    if (f[0].Get<uint32>() == 1) p->SetMoney(f[2].Get<uint32>());
    return operation.empty() || f[0].Get<uint32>() != 0;
}
bool Load(Player* p)
{
    auto s = p->CustomData.GetDefault<State>(Key);
    auto q = CharacterDatabase.Query(
        "SELECT COUNT(*),COALESCE(MAX(account),0),COALESCE(MAX(revision),0),COALESCE(MAX(schema_version),1),"
        "(SELECT COALESCE(SUM(IF(node_id=34538,1,IF(node_id=7451,2,0))),0) FROM reborn_wh_t1_nodes WHERE guid={}),"
        "(SELECT COUNT(*) FROM reborn_wh_t1_nodes WHERE guid={} AND (node_id NOT IN(34538,7451) OR `rank`<>1)),"
        "(SELECT COUNT(*) FROM reborn_wh_t1_nodes WHERE guid={}) FROM reborn_wh_t1_state WHERE guid={}",
        p->GetGUID().GetCounter(), p->GetGUID().GetCounter(), p->GetGUID().GetCounter(), p->GetGUID().GetCounter());
    s->loaded = false;
    if (!q) return false;
    auto f = q->Fetch();
    if (f[0].Get<uint32>() > 1 || f[3].Get<uint32>() != 1 || f[5].Get<uint32>() ||
        f[6].Get<uint32>() > 2 || f[4].Get<uint32>() > 3 || f[2].Get<uint32>() >= 2000000000 ||
        (f[0].Get<uint32>() && f[1].Get<uint32>() != p->GetSession()->GetAccountId())) return false;
    s->stored = f[0].Get<uint32>() == 1;
    if (!s->stored && (f[6].Get<uint32>() || p->HasSpell(Night) || p->HasSpell(Survival))) return false;
    s->revision = f[2].Get<uint32>(); s->mask = f[4].Get<uint32>();
    s->loaded = Contract();
    return s->loaded;
}
void Sync(Player* p)
{
    auto s = p->CustomData.GetDefault<State>(Key);
    if (!s->loaded || !Contract()) return;
    bool eligible = WHT1::Valid(s->mask, p->GetLevel());
    uint32 ids[] = {Night, Survival};
    for (uint32 bit = 0; bit < 2; ++bit)
    {
        uint32 id = ids[bit];
        if ((s->mask & (1u << bit)) && eligible)
        {
            if (!p->IsAlive()) continue;
            if (!p->HasSpell(id)) p->learnSpell(id);
            if (!p->HasAura(id)) p->CastSpell(p, id, TRIGGERED_FULL_MASK);
        }
        else if (s->stored)
        {
            // These private IDs are granted only by this persisted owner.
            if (p->HasSpell(id)) p->removeSpell(id, 255, false);
            p->RemoveAurasDueToSpell(id);
        }
    }
}
bool Ready(Player* p, uint32 nonce, bool mutation)
{
    if (!Hunter(p) || nonce > 2000000000) return false;
    if (!storageReady) { Reply(p, nonce, "schema"); return false; }
    auto s = p->CustomData.GetDefault<State>(Key);
    if (s->busy) { Reply(p, nonce, "busy"); return false; }
    if (mutation && (!p->IsAlive() || p->IsInCombat() || p->IsNonMeleeSpellCast(false) ||
        p->GetVehicle() || p->IsInFlight())) { Reply(p, nonce, "unsafe"); return false; }
    bool committed = false;
    if (!Recover(p, "", committed) || !Load(p)) { Reply(p, nonce, "database"); return false; }
    Sync(p); return true;
}
bool Query(ChatHandler* h, uint32 nonce)
{
    auto p = h->GetSession()->GetPlayer(); if (Ready(p, nonce, false)) Reply(p, nonce, "ok"); return true;
}
bool Write(Player* p, uint32 nonce, uint32 revision, uint32 mask, bool reset)
{
    if (!Ready(p, nonce, true)) return true;
    auto s = p->CustomData.GetDefault<State>(Key);
    if (revision != s->revision) { Reply(p, nonce, "stale"); return true; }
    if (!reset && (!WHT1::Valid(mask, p->GetLevel()) || (mask & s->mask) != s->mask))
    { Reply(p, nonce, "invalid"); return true; }
    if (reset && (!s->mask || mask)) { Reply(p, nonce, "invalid"); return true; }
    if (!reset && mask == s->mask) { Reply(p, nonce, "ok"); return true; }
    uint32 cost = reset ? ResetCopper : 0, before = p->GetMoney();
    if (before < cost) { Reply(p, nonce, "money"); return true; }
    auto stamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    std::string operation = std::to_string(p->GetGUID().GetCounter()) + "-" +
        std::to_string(stamp) + "-" + std::to_string(serial.fetch_add(1));
    s->busy = true;
    auto prepared = CharacterDatabase.Query("CALL reborn_wht1_prepare('{}',{},{},{},{},{},{},{})", operation,
        p->GetGUID().GetCounter(), p->GetSession()->GetAccountId(), revision, mask, uint32(reset), uint32(p->GetLevel()), before);
    if (!prepared)
    {
        bool ignored = false;
        if (!Recover(p, "", ignored))
        { s->loaded = false; p->GetSession()->KickPlayer("WHTAL1A database recovery required"); }
        s->busy = false; Load(p); Reply(p, nonce, "database"); return true;
    }
    // Never call a worker with a retained Player*. Native SaveGoldToDB appends values.
    p->ModifyMoney(-int32(cost));
    if (p->GetMoney() != before - cost)
    {
        bool ignored = false;
        if (!Recover(p, operation, ignored))
        {
            s->loaded = false; s->busy = false; Reply(p, nonce, "uncertain");
            p->GetSession()->KickPlayer("WHTAL1A gold recovery unavailable"); return true;
        }
        s->busy = false;
        Reply(p, nonce, "money"); return true;
    }
    auto tx = CharacterDatabase.BeginTransaction();
    tx->Append("CALL reborn_wht1_apply('{}',{},{})", operation,
        p->GetGUID().GetCounter(), p->GetSession()->GetAccountId());
    p->SaveGoldToDB(tx);
    auto result = CharacterDatabase.AsyncCommitTransaction(tx);
    bool acknowledged = result.m_future.get();
    bool committed = false;
    if (!Recover(p, operation, committed))
    {
        s->loaded = false; s->busy = false;
        // An unresolved durable intent is repaired before the next successful login.
        Reply(p, nonce, "uncertain");
        p->GetSession()->KickPlayer("WHTAL1A unresolved database operation; receipt recovery on login");
        return true;
    }
    s->busy = false;
    if (!Load(p)) { Reply(p, nonce, "database"); return true; }
    Sync(p);
    if (!acknowledged && committed)
        LOG_WARN("module", "WHTAL1A receipt confirmed a committed operation after missing acknowledgement: {}", operation);
    Reply(p, nonce, committed ? (reset ? "reset" : "saved") : "database");
    return true;
}
bool Save(ChatHandler* h, uint32 nonce, uint32 revision, uint32 mask)
{ return Write(h->GetSession()->GetPlayer(), nonce, revision, mask, false); }
bool Quote(ChatHandler* h, uint32 nonce, uint32 revision)
{
    auto p = h->GetSession()->GetPlayer(); if (!Ready(p, nonce, true)) return true;
    auto s = p->CustomData.GetDefault<State>(Key); s->quote = false;
    if (s->revision != revision || !s->mask) { Reply(p, nonce, "stale"); return true; }
    s->quoteRevision = revision; s->quoteToken = (serial.fetch_add(1) % 1999999999u) + 1u;
    s->quoteTime = std::chrono::steady_clock::now(); s->quote = true;
    Reply(p, nonce, "quote", s->quoteToken); return true;
}
bool Reset(ChatHandler* h, uint32 nonce, uint32 revision, uint32 token)
{
    auto p = h->GetSession()->GetPlayer(); if (!Hunter(p)) return true;
    auto s = p->CustomData.GetDefault<State>(Key);
    bool valid = s->quote && s->quoteToken == token && s->quoteRevision == revision &&
        std::chrono::steady_clock::now() - s->quoteTime <= std::chrono::seconds(60);
    s->quote = false;
    if (!valid) { Reply(p, nonce, "stale"); return true; }
    return Write(p, nonce, revision, 0, true);
}
class Commands final : public CommandScript
{
public:
    Commands() : CommandScript("RebornWitchHunterTalentsCommands") { }
    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable children = {
            {"state", Query, SEC_PLAYER, Console::No}, {"save", Save, SEC_PLAYER, Console::No},
            {"quote", Quote, SEC_PLAYER, Console::No}, {"reset", Reset, SEC_PLAYER, Console::No}};
        static ChatCommandTable root = {{"whtalent", children}};
        return root;
    }
};
class Startup final : public WorldScript
{
public:
    Startup() : WorldScript("RebornWitchHunterTalentsStartup") { }
    void OnStartup() override
    {
        auto q = CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN('reborn_wh_t1_state','reborn_wh_t1_nodes','reborn_wh_t1_intents') AND ENGINE='InnoDB'");
        auto r = CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE() AND ROUTINE_TYPE='PROCEDURE' AND ROUTINE_NAME IN('reborn_wht1_prepare','reborn_wht1_apply','reborn_wht1_recover')");
        storageReady = q && r && q->Fetch()[0].Get<uint32>() == 3 && r->Fetch()[0].Get<uint32>() == 3;
        if (!storageReady || !Contract()) LOG_ERROR("module", "WHTAL1A storage/data incomplete; talent purchases disabled");
    }
};
class Lifecycle final : public PlayerScript
{
public:
    Lifecycle() : PlayerScript("RebornWitchHunterTalentsLifecycle", {
        PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_UPDATE}) { }
    void OnPlayerLogin(Player* p) override
    {
        if (!Hunter(p) || !storageReady) return;
        bool ignored = false;
        if (!Recover(p, "", ignored))
        { p->GetSession()->KickPlayer("WHTAL1A receipt recovery unavailable"); return; }
        if (Load(p)) Sync(p);
    }
    void OnPlayerLevelChanged(Player* p, uint8) override { if (Hunter(p)) Sync(p); }
    void OnPlayerUpdate(Player* p, uint32 diff) override
    {
        if (!Hunter(p)) return;
        auto s = p->CustomData.GetDefault<State>(Key); s->tick += diff;
        if (s->tick < 1000 || s->busy) return;
        s->tick = 0; Sync(p);
    }
};
}
void AddRebornWitchHunterTalentsScripts()
{ new Startup(); new Commands(); new Lifecycle(); }
