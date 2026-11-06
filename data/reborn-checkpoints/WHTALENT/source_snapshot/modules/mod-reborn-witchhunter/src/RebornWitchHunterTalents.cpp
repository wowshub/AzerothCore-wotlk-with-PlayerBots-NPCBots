// WHTAL5A: two owned common talents. Browsing a spec never activates it.
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
#include "SpellScript.h"
#include "SpellAuraEffects.h"
#include "Log.h"
#include "GameTime.h"
#include "Timer.h"
#include "SpellAuras.h"
#include "DBCStores.h"
#include "RebornWitchHunterTalentData.h"
#include <atomic>
#include <chrono>
#include <string>
using namespace Acore::ChatCommands;
namespace
{
constexpr uint32 Night = 9005067, Survival = 9005068, Training1 = 9005069, Training2 = 9005070, Hatred = 9005071, Restore = 9005072, Sleepless = 9005073, NightHunter = 9005074, DayHunter = 9005075, Night2 = 9005076, ResetCopper = 100000;
constexpr char Key[] = "Reborn.WHTAL5A";
bool storageReady = false;
std::atomic<uint32> serial{1};
struct State : DataMap::Base
{
    bool loaded = false, stored = false, busy = false, quote = false;
    uint32 revision = 0, mask = 0, tick = 0, quoteToken = 0, quoteRevision = 0;
    std::chrono::steady_clock::time_point quoteTime{};
};
bool Hunter(Player* p) { return p && p->getClass() == CLASS_WITCH_HUNTER; }
bool BookContract()
{
    for (uint32 id = 9200; id <= 9204; ++id)
    {
        auto line = sSkillLineStore.LookupEntry(id);
        if (!line || line->categoryId != SKILL_CATEGORY_CLASS) return false;
        for (uint32 race : {1u, 4u, 5u})
            if (!GetSkillRaceClassInfo(id, race, CLASS_WITCH_HUNTER)) return false;
    }
    return true;
}
void EnsureBookSkills(Player* p)
{
    if (!Hunter(p) || !BookContract()) return;
    for (uint32 id = 9200; id <= 9204; ++id)
        if (!p->HasSkill(id)) p->SetSkill(id, 0, 1, 1);
}
bool Contract()
{
    auto n = sSpellMgr->GetSpellInfo(Night);
    auto n2 = sSpellMgr->GetSpellInfo(Night2);
    auto s = sSpellMgr->GetSpellInfo(Survival);
    auto t1 = sSpellMgr->GetSpellInfo(Training1);
    auto t2 = sSpellMgr->GetSpellInfo(Training2);
    bool training = t1 && t2;
    for (auto spell : {t1, t2})
        training = training && spell && spell->SpellFamilyName == 21 && spell->IsPassive() &&
            spell->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_DAMAGE_PERCENT_DONE) && spell->Effects[EFFECT_0].MiscValue == 1 &&
            spell->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_PARRY_PERCENT) &&
            spell->Effects[EFFECT_0].BasePoints == (spell == t1 ? 2 : 5) &&
            spell->Effects[EFFECT_1].BasePoints == (spell == t1 ? 2 : 5);
    auto h = sSpellMgr->GetSpellInfo(Hatred);
    auto e = sSpellMgr->GetSpellInfo(Restore);
    auto proc = sSpellMgr->GetSpellProcEntry(Hatred);
    bool hatred = h && e && h->IsPassive() && h->SpellFamilyName == 21 && e->SpellFamilyName == 21 &&
        h->Effects[EFFECT_0].IsAura(SPELL_AURA_PROC_TRIGGER_SPELL) && h->Effects[EFFECT_0].TriggerSpell == Restore &&
        e->Effects[EFFECT_0].Effect == SPELL_EFFECT_ENERGIZE_PCT && e->Effects[EFFECT_0].BasePoints == 4 && e->Effects[EFFECT_0].MiscValue == POWER_MANA &&
        e->Effects[EFFECT_1].Effect == SPELL_EFFECT_ENERGIZE && e->Effects[EFFECT_1].BasePoints == 99 && e->Effects[EFFECT_1].MiscValue == POWER_RAGE &&
        proc && proc->ProcFlags == 349524 && proc->SpellTypeMask == PROC_SPELL_TYPE_DAMAGE &&
        proc->SpellPhaseMask == PROC_SPELL_PHASE_HIT && proc->HitMask == PROC_HIT_CRITICAL &&
        proc->Cooldown == std::chrono::milliseconds(3000) && proc->Chance == 100 && proc->Charges == 0 &&
        proc->AttributesMask == PROC_ATTR_TRIGGERED_CAN_PROC && proc->DisableEffectsMask == 0 &&
        proc->ProcsPerMinute == 0 && proc->SchoolMask == 0 && proc->SpellFamilyName == 0 &&
        proc->SpellFamilyMask[0] == 0 && proc->SpellFamilyMask[1] == 0 && proc->SpellFamilyMask[2] == 0;
    auto parent = sSpellMgr->GetSpellInfo(Sleepless);
    auto night = sSpellMgr->GetSpellInfo(NightHunter);
    auto day = sSpellMgr->GetSpellInfo(DayHunter);
    bool clock = parent && night && day && parent->IsPassive() && parent->SpellFamilyName == 21 &&
        parent->GetDuration() == -1 && parent->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
        parent->Effects[EFFECT_1].IsAura(SPELL_AURA_DUMMY) &&
        !parent->Effects[EFFECT_0].TriggerSpell && !parent->Effects[EFFECT_1].TriggerSpell &&
        night->GetDuration() == 30000 && day->GetDuration() == 30000 &&
        night->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE) &&
        night->Effects[EFFECT_0].BasePoints == 3 && night->Effects[EFFECT_0].MiscValue == STAT_AGILITY &&
        !night->Effects[EFFECT_1].Effect && day->Effects[EFFECT_0].IsAura(SPELL_AURA_HASTE_SPELLS) &&
        day->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_MELEE_RANGED_HASTE) &&
        day->Effects[EFFECT_0].BasePoints == 2 && day->Effects[EFFECT_1].BasePoints == 2;
    return n2 && n2->IsPassive() && n2->SpellFamilyName == 21 && n2->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_CRIT_PCT) && n2->Effects[EFFECT_1].BasePoints == 5 && BookContract() && clock && hatred && training && n && s && n->SpellFamilyName == 21 && s->SpellFamilyName == 21 &&
        n->IsPassive() && s->IsPassive() &&
        n->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_CRIT_PCT) && n->Effects[EFFECT_1].BasePoints == 2 &&
        s->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_AURA_DURATION_BY_DISPEL) &&
        s->Effects[EFFECT_0].BasePoints == -31 && s->Effects[EFFECT_0].MiscValue == 3;
}
void Reply(Player* p, uint32 nonce, char const* status, uint32 token = 0)
{
    auto s = p->CustomData.GetDefault<State>(Key);
    ChatHandler(p->GetSession()).PSendSysMessage("WHT5|{}|{}|{}|{}|{}|{}|{}|{}|{}|10|{}|{}",
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
        "SELECT COUNT(*),COALESCE(MAX(account),0),COALESCE(MAX(revision),0),COALESCE(MAX(schema_version),5),"
        "(SELECT COALESCE(SUM(IF(node_id=34538,IF(`rank`=2,65,1),IF(node_id=7451,2,IF(node_id=6415,`rank`*4,IF(node_id=6457,16,IF(node_id=7424,32,0)))))),0) FROM reborn_wh_t1_nodes WHERE guid={}),"
        "(SELECT COUNT(*) FROM reborn_wh_t1_nodes WHERE guid={} AND (node_id NOT IN(34538,7451,6415,6457,7424) OR (node_id IN(7451,6457,7424) AND `rank`<>1) OR (node_id IN(34538,6415) AND `rank` NOT IN(1,2)))),"
        "(SELECT COUNT(*) FROM reborn_wh_t1_nodes WHERE guid={}) FROM reborn_wh_t1_state WHERE guid={}",
        p->GetGUID().GetCounter(), p->GetGUID().GetCounter(), p->GetGUID().GetCounter(), p->GetGUID().GetCounter());
    s->loaded = false;
    if (!q) return false;
    auto f = q->Fetch();
    if (f[0].Get<uint32>() > 1 || f[3].Get<uint32>() != 5 || f[5].Get<uint32>() ||
        f[6].Get<uint32>() > 5 || f[4].Get<uint32>() > 123 || f[2].Get<uint32>() >= 2000000000 ||
        (f[0].Get<uint32>() && f[1].Get<uint32>() != p->GetSession()->GetAccountId())) return false;
    s->stored = f[0].Get<uint32>() == 1;
    if (!s->stored && (f[6].Get<uint32>() || p->HasSpell(Night) || p->HasSpell(Survival) || p->HasSpell(Training1) || p->HasSpell(Training2) || p->HasSpell(Hatred) || p->HasSpell(Sleepless) || p->HasSpell(Night2))) return false;
    s->revision = f[2].Get<uint32>(); s->mask = f[4].Get<uint32>();
    s->loaded = Contract();
    return s->loaded;
}
bool NightHour(uint32 hour) { return hour < 6 || hour >= 18; }
void ClearDayNight(Player* player)
{
    if (!Hunter(player)) return;
    player->RemoveAurasDueToSpell(NightHunter, player->GetGUID());
    player->RemoveAurasDueToSpell(DayHunter, player->GetGUID());
}
void MaintainDayNight(Player* player)
{
    if (!Hunter(player)) return;
    auto state = player->CustomData.GetDefault<State>(Key);
    if (!state->loaded || !(state->mask & 32u) || !WHT1::Valid(state->mask, player->GetLevel()) ||
        !player->IsAlive() || !player->IsInWorld() || !player->HasSpell(Sleepless) ||
        !player->HasAura(Sleepless, player->GetGUID()))
    { ClearDayNight(player); return; }
    bool night = NightHour(Acore::Time::GetHours(GameTime::GetGameTime()));
    uint32 selected = night ? NightHunter : DayHunter;
    player->RemoveAurasDueToSpell(night ? DayHunter : NightHunter, player->GetGUID());
    if (Aura* aura = player->GetAura(selected, player->GetGUID()))
        aura->RefreshDuration(); // PR4878: refresh instead of allowing a30s gap or recasting every tick.
    else
        player->CastSpell(player, selected, TRIGGERED_FULL_MASK);
}

void Sync(Player* p)
{
    auto s = p->CustomData.GetDefault<State>(Key);
    if (!s->loaded || !Contract()) return;
    bool eligible = WHT1::Valid(s->mask, p->GetLevel());
    uint32 ids[] = {Night, Night2, Survival, Training1, Training2, Hatred, Sleepless};
    bool selected[] = {bool(s->mask & 1u) && !(s->mask & 64u), bool(s->mask & 64u), bool(s->mask & 2u), ((s->mask >> 2u) & 3u) == 1u, ((s->mask >> 2u) & 3u) == 2u, bool(s->mask & 16u), bool(s->mask & 32u)};
    // Remove all inactive ranks first, then grant; neither upgrade nor downgrade stacks ranks.
    if (s->stored)
        for (uint32 i = 0; i < 7; ++i)
            if (!selected[i] || !eligible)
            {
                if (p->HasSpell(ids[i])) p->removeSpell(ids[i], 255, false);
                p->RemoveAurasDueToSpell(ids[i]);
            }
    if (eligible && p->IsAlive())
        for (uint32 i = 0; i < 7; ++i)
            if (selected[i])
            {
                if (!p->HasSpell(ids[i])) p->learnSpell(ids[i]);
                if (!p->HasAura(ids[i])) p->CastSpell(p, ids[i], TRIGGERED_FULL_MASK);
            }
    MaintainDayNight(p);
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
    if (!reset && (!WHT1::Valid(mask, p->GetLevel()) || (mask & (s->mask & 115u)) != (s->mask & 115u) || ((mask >> 2u) & 3u) < ((s->mask >> 2u) & 3u)))
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
        { s->loaded = false; p->GetSession()->KickPlayer("WHTAL5A database recovery required"); }
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
            p->GetSession()->KickPlayer("WHTAL5A gold recovery unavailable"); return true;
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
        p->GetSession()->KickPlayer("WHTAL5A unresolved database operation; receipt recovery on login");
        return true;
    }
    s->busy = false;
    if (!Load(p)) { Reply(p, nonce, "database"); return true; }
    Sync(p);
    if (!acknowledged && committed)
        LOG_WARN("module", "WHTAL5A receipt confirmed a committed operation after missing acknowledgement: {}", operation);
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
struct TrainingParryLease
{
    bool captured = false, hadParry = false, hadNativeSpell = false, hadOtherAura = false;
    void Capture(Player* player, AuraEffect const* self)
    {
        if (!player || captured)
            return;
        captured = true;
        hadParry = player->CanParry();
        hadNativeSpell = player->HasSpell(3127);
        hadOtherAura = false;
        for (AuraEffect const* other : player->GetAuraEffectsByType(SPELL_AURA_MOD_PARRY_PERCENT))
            if (other != self)
                hadOtherAura = true;
    }
    void Release(Player* player)
    {
        if (!player || !captured)
            return;
        captured = false;
        // This effect is already unregistered by the core before removal callbacks.
        // Preserve a currently learned native capability or any remaining parry aura.
        if (player->HasSpell(3127) || player->HasAuraType(SPELL_AURA_MOD_PARRY_PERCENT))
            return;
        // If an observed native owner was lost during the buff, do not resurrect it.
        // An original capability with no observable native owner is left unchanged.
        if (!hadParry || hadNativeSpell || hadOtherAura)
            player->SetCanParry(false);
    }
};
class aura_reborn_whtraining2a : public AuraScript
{
    PrepareAuraScript(aura_reborn_whtraining2a);
    TrainingParryLease lease;
    bool Validate(SpellInfo const* info) override { return info && (info->Id == Training1 || info->Id == Training2) && Contract(); }
    void Before(AuraEffect const* effect, AuraEffectHandleModes)
    {
        lease.Capture(GetTarget()->ToPlayer(), effect);
    }
    void After(AuraEffect const*, AuraEffectHandleModes)
    {
        lease.Release(GetTarget()->ToPlayer());
    }
    void Register() override
    {
        OnEffectApply += AuraEffectApplyFn(aura_reborn_whtraining2a::Before, EFFECT_1, SPELL_AURA_MOD_PARRY_PERCENT, AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_whtraining2a::After, EFFECT_1, SPELL_AURA_MOD_PARRY_PERCENT, AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK);
    }
};
// Positive outgoing critical damage only. Native proc preparation owns the shared 3s ICD.
bool HatredEvent(Player* player, ProcEventInfo& event)
{
    return Hunter(player) && player->IsAlive() && event.GetActor() == player &&
        event.GetDamageInfo() && event.GetDamageInfo()->GetDamage() > 0 &&
        (event.GetTypeMask() & 349524u) && (event.GetHitMask() & PROC_HIT_CRITICAL);
}
class aura_reborn_whhatred3a : public AuraScript
{
    PrepareAuraScript(aura_reborn_whhatred3a);
    bool Validate(SpellInfo const* info) override { return info && info->Id == Hatred && Contract(); }
    bool Check(ProcEventInfo& event) { return HatredEvent(GetTarget()->ToPlayer(), event); }
    void Proc(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (HatredEvent(player, event)) player->CastSpell(player, Restore, TRIGGERED_FULL_MASK);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_reborn_whhatred3a::Check);
        OnEffectProc += AuraEffectProcFn(aura_reborn_whhatred3a::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class aura_reborn_whsleepless4a : public AuraScript
{
    PrepareAuraScript(aura_reborn_whsleepless4a);
    bool Validate(SpellInfo const* info) override { return info && info->Id == Sleepless && Contract(); }
    void Periodic(AuraEffect const*, bool& periodic, int32& amplitude) { periodic = true; amplitude = 500; }
    void Tick(AuraEffect const*) { PreventDefaultAction(); MaintainDayNight(GetTarget()->ToPlayer()); }
    void Applied(AuraEffect const*, AuraEffectHandleModes) { MaintainDayNight(GetTarget()->ToPlayer()); }
    void Removed(AuraEffect const*, AuraEffectHandleModes) { ClearDayNight(GetTarget()->ToPlayer()); }
    void Register() override
    {
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_reborn_whsleepless4a::Periodic, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_whsleepless4a::Tick, EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_whsleepless4a::Applied, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_whsleepless4a::Removed, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

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
        auto version = CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_state' AND COLUMN_NAME='schema_version' AND COLUMN_DEFAULT='5'");
        auto bindings = WorldDatabase.Query("SELECT COUNT(DISTINCT spell_id) FROM spell_script_names WHERE spell_id IN(9005069,9005070) AND ScriptName='aura_reborn_whtraining2a'");
        auto hatredBinding = WorldDatabase.Query("SELECT COUNT(*) FROM spell_script_names WHERE spell_id=9005071 AND ScriptName='aura_reborn_whhatred3a'");
        auto clockBinding = WorldDatabase.Query("SELECT COUNT(*) FROM spell_script_names WHERE spell_id=9005073 AND ScriptName='aura_reborn_whsleepless4a'");
        storageReady = clockBinding && clockBinding->Fetch()[0].Get<uint32>() == 1 && hatredBinding && hatredBinding->Fetch()[0].Get<uint32>() == 1 && q && r && version && bindings && q->Fetch()[0].Get<uint32>() == 3 &&
            r->Fetch()[0].Get<uint32>() == 3 && version->Fetch()[0].Get<uint32>() == 1 &&
            bindings->Fetch()[0].Get<uint32>() == 2;
        if (!storageReady || !Contract()) LOG_ERROR("module", "WHTAL5A storage/data incomplete; talent purchases disabled");
    }
};
class Lifecycle final : public PlayerScript
{
public:
    Lifecycle() : PlayerScript("RebornWitchHunterTalentsLifecycle", {
        PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_UPDATE}) { }
    void OnPlayerLogin(Player* p) override
    {
        EnsureBookSkills(p);
        if (!Hunter(p) || !storageReady) return;
        bool ignored = false;
        if (!Recover(p, "", ignored))
        { p->GetSession()->KickPlayer("WHTAL5A receipt recovery unavailable"); return; }
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
{ new Startup(); new Commands(); new Lifecycle(); RegisterSpellScript(aura_reborn_whtraining2a); RegisterSpellScript(aura_reborn_whhatred3a); RegisterSpellScript(aura_reborn_whsleepless4a); }
