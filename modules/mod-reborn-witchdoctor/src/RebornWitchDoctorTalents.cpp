// WD5A: one working CoA talent, three independent saved test builds.
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DataMap.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "RebornWitchDoctorRanks.h"
#include "ScriptDefines/GlobalScript.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "WorldSession.h"
#include "ScriptedGossip.h"
#include "Transaction.h"
#include <array>
#include <sstream>
#include <chrono>
#include <mutex>
#include <unordered_map>
using namespace Acore::ChatCommands;
namespace WD19A { uint32 ResolveAction(Player* player, uint32 spell); }

namespace WD5A
{
constexpr uint32 Wrath=9003100, BadJuju=9003103, Node=6058;
uint32 PointsUsed(uint32 mask) { return (mask&1u)+((mask>>1)&1u); }
constexpr char Key[]="Reborn.WD5A";
using ActionLayout=std::array<uint32,MAX_ACTION_BUTTONS>;
struct State : DataMap::Base
{
    SpellModifier* modifier=nullptr;
    uint32 revision=0, active=0, builds=0;
    bool loaded=false;
    uint32 unlocked=0;
    uint32 quoteSlot=0, quoteGold=0, quoteLevel=0;
    bool quoteValid=false;
    std::chrono::steady_clock::time_point quoteTime;
    bool pendingActionRestore=false;
    ActionLayout pendingActions{};
    uint32 specs[3]={3,3,3}; // 3 = unlocked build with no chosen specialization.
    bool resetQuoteValid=false;
    uint32 resetSlot=0,resetRevision=0,resetGold=0;
    std::chrono::steady_clock::time_point resetQuoteTime;
    std::chrono::steady_clock::time_point request;
};
std::mutex registryMutex;
std::unordered_map<SpellModifier const*,Player*> registry;
bool ProfilesEnabled() { return sConfigMgr->GetOption<bool>("RebornWD8.Enable",false); }
bool Enabled() { return sConfigMgr->GetOption<bool>("RebornWD5A.Enable",false); }
bool Doctor(Player* p) { return p && p->getClass()==13 && p->getRace()==1; }
// WD9E: same ordering as native Monk ActivateSpec: snapshot, switch spells, restore bars.
ActionLayout CaptureActions(Player* p)
{
    ActionLayout result{};
    for (uint8 button=0;button<MAX_ACTION_BUTTONS;++button)
        if (ActionButton const* action=p->GetActionButton(button)) result[button]=action->packedData;
    return result;
}
std::string EncodeActions(ActionLayout const& actions)
{
    std::ostringstream out;
    for (uint32 packed:actions) out << packed << ' ';
    return out.str(); // Server-generated decimal integers and spaces only.
}
bool ReadActions(Player* p,uint32 slot,ActionLayout& actions)
{
    QueryResult q=CharacterDatabase.Query("SELECT COALESCE((SELECT buttons FROM reborn_wd16_actions WHERE guid={} AND build_slot={}), '')",p->GetGUID().GetCounter(),slot);
    if (!q) return false; // Missing table is not the same thing as a first visit.
    std::string value=q->Fetch()[0].Get<std::string>();
    if (value.empty()) return true; // First visit inherits the captured current layout.
    std::istringstream in(value);
    for (uint32& packed:actions)
    {
        uint64 wide=0;
        if (!(in>>wide) || wide>0xFFFFFFFFULL) return false;
        packed=uint32(wide);
        uint32 type=ACTION_BUTTON_TYPE(packed);
        if (type!=ACTION_BUTTON_SPELL && type!=ACTION_BUTTON_C && type!=ACTION_BUTTON_EQSET && type!=ACTION_BUTTON_MACRO && type!=ACTION_BUTTON_CMACRO && type!=ACTION_BUTTON_ITEM) return false;
    }
    std::string extra;return !(in>>extra);
}
void RestoreActions(Player* p,ActionLayout const& actions)
{
    for (uint8 button=0;button<MAX_ACTION_BUTTONS;++button)
    {
        p->removeActionButton(button);
        uint32 action=ACTION_BUTTON_ACTION(actions[button]);
        uint8 type=uint8(ACTION_BUTTON_TYPE(actions[button]));
        // Learn/unlearn must already have finished; never put an unavailable spell back.
        if (type==ACTION_BUTTON_SPELL) action=WD19A::ResolveAction(p,action);
        if (action) p->addActionButton(button,action,type);
    }
    p->SendActionButtons(1);
}
void Remove(Player* p,State* s)
{
    if (!s->modifier) return;
    { std::lock_guard<std::mutex> lock(registryMutex); registry.erase(s->modifier); }
    p->AddSpellMod(s->modifier,false); // Player owns deletion for a modifier without an aura.
    s->modifier=nullptr;
}
bool CanCastBadJuju(Player* p)
{
    if (!Doctor(p) || !Enabled() || !ProfilesEnabled() || p->GetLevel()<15) return false;
    State* s=p->CustomData.GetDefault<State>(Key);
    return s->loaded && s->specs[s->active]==0 && ((s->builds>>(s->active+3))&1u);
}
void ClearEffects(Player* p,State* s)
{
    Remove(p,s);
    if (Doctor(p) && p->HasSpell(BadJuju)) p->removeSpell(BadJuju,3,false);
}
void Apply(Player* p,State* s)
{
    if (Doctor(p))
    {
        bool learn=CanCastBadJuju(p) && sSpellMgr->GetSpellInfo(BadJuju);
        if (learn && !p->HasSpell(BadJuju)) p->learnSpell(BadJuju);
        else if (!learn && p->HasSpell(BadJuju)) p->removeSpell(BadJuju,3,false);
    }
    bool wanted=Enabled() && Doctor(p) && p->GetLevel()>=10 && s->loaded && s->specs[s->active]==0 && ((s->builds>>s->active)&1);
    if (!wanted) { Remove(p,s);return; }
    if (s->modifier) return;
    if (!sSpellMgr->GetSpellInfo(Wrath)) return;
    s->modifier=new SpellModifier();s->modifier->op=SPELLMOD_CASTING_TIME;
    s->modifier->type=SPELLMOD_FLAT;s->modifier->value=-500;s->modifier->spellId=Wrath;
    // Zero mask: no broad class/family match. Global hook matches only this registered modifier and explicit Wrath ranks/Bad Juju.
    { std::lock_guard<std::mutex> lock(registryMutex);registry.emplace(s->modifier,p); }
    p->AddSpellMod(s->modifier,true);
}
bool Load(Player* p,State* s)
{
    QueryResult q=CharacterDatabase.Query("SELECT b.revision,b.active,b.builds+(COALESCE(n.juju,0)*8) FROM reborn_wd5a_builds b LEFT JOIN reborn_wd9a_nodes n ON n.guid=b.guid WHERE b.guid={}",p->GetGUID().GetCounter());
    if (!q) return false;
    Field* f=q->Fetch();uint32 rev=f[0].Get<uint32>(),active=f[1].Get<uint32>(),builds=f[2].Get<uint32>();
    if (active>2 || builds>63 || rev>2000000000) return false;
    if (ProfilesEnabled())
    {
        QueryResult profile=CharacterDatabase.Query("SELECT MAX(IF(slot=0,spec,NULL)),MAX(IF(slot=1,spec,NULL)),MAX(IF(slot=2,spec,NULL)),COUNT(*) FROM reborn_wd16_profiles WHERE guid={}",p->GetGUID().GetCounter());
        if (!profile || profile->Fetch()[3].Get<uint32>()!=3) return false;
        for (uint32 i=0;i<3;++i) { s->specs[i]=profile->Fetch()[i].Get<uint32>();if(s->specs[i]>3)return false; }
    }
    QueryResult slots=CharacterDatabase.Query("SELECT COALESCE(SUM(1 << slot),0) FROM reborn_wd13_slots WHERE guid={}",p->GetGUID().GetCounter());
    if (!slots) return false;
    uint32 mask=slots->Fetch()[0].Get<uint32>();
    s->unlocked=mask==1?1:(mask==3?2:(mask==7?3:0));
    if (!s->unlocked || active>=s->unlocked) return false;
    s->revision=rev;s->active=active;s->builds=builds;s->loaded=true;Apply(p,s);
    if (s->pendingActionRestore)
    {
        RestoreActions(p,s->pendingActions);
        s->pendingActionRestore=false;
    }
    return true;
}
void Reply(Player* p,char const* status)
{
    State* s=p->CustomData.GetDefault<State>(Key);
    uint32 effective=s->builds & 7u;
    for (uint32 i=0;i<3;++i) if(s->specs[i]!=0) effective &= ~(1u<<i);
    // Legacy tooltip messages expose effective ranks, while WD9A exposes retained records.
    ChatHandler(p->GetSession()).PSendSysMessage("WD5A|{}|{}|{}|{}|{}|{}",status,s->revision,s->active,effective,p->GetLevel(),s->loaded?1:0);
}
bool Ready(Player* p,bool mutation)
{
    if (!Doctor(p)) return false;
    if (!Enabled()) { ClearEffects(p,p->CustomData.GetDefault<State>(Key));Reply(p,"disabled");return false; }
    if (!sSpellMgr->GetSpellInfo(Wrath) || !sSpellMgr->GetSpellInfo(BadJuju)) { Reply(p,"spell");return false; }
    State* s=p->CustomData.GetDefault<State>(Key);
    auto now=std::chrono::steady_clock::now();
    if (now-s->request<std::chrono::milliseconds(250)) { Reply(p,"busy");return false; }
    s->request=now;
    if (mutation && (!p->IsAlive() || p->IsInCombat() || p->IsNonMeleeSpellCast(false) || p->IsInFlight() || p->GetVehicle() || p->GetTransport()))
    { Reply(p,"unsafe");return false; }
    if (!s->loaded)
    {
        CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd5a_builds (guid,revision,active,builds) VALUES ({},0,0,0)",p->GetGUID().GetCounter());
        if (ProfilesEnabled()) CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd8_profiles(guid) VALUES ({})",p->GetGUID().GetCounter());
        CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES ({},0,0)",p->GetGUID().GetCounter());
        for(uint32 slot=0;slot<3;++slot) CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd16_profiles(guid,slot,spec) VALUES ({},{},3)",p->GetGUID().GetCounter(),slot);
        if (!Load(p,s)) { Reply(p,"database");return false; }
    }
    return true;
}
bool StateCommand(ChatHandler* h)
{
    Player* p=h->GetSession()->GetPlayer();if (!Ready(p,false)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    if (!Load(p,s)) { s->loaded=false;ClearEffects(p,s);Reply(p,"database");return true; }
    Reply(p,"ok");return true;
}
// WD8: three existing saved builds, explicit draft commit and confirmed activation.
// WD8A: one shared point per level from 10, capped at the level-80 budget.
uint32 ProfilePoints(Player* p)
{
    uint32 level=p->GetLevel();
    return level<10 ? 0 : (level>80 ? 71 : level-9);
}
void ProfileReply(Player* p,char const* result)
{
    State* s=p->CustomData.GetDefault<State>(Key);
    ChatHandler(p->GetSession()).PSendSysMessage("WD16|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",result,s->revision,s->active,s->builds,s->specs[0],s->specs[1],s->specs[2],p->GetLevel(),s->loaded?1:0,ProfilePoints(p),s->unlocked);
}
bool ProfileReady(Player* p,bool mutation)
{
    if(!Doctor(p))return false;
    if(!ProfilesEnabled() || !Enabled()) { ClearEffects(p,p->CustomData.GetDefault<State>(Key));ProfileReply(p,"disabled");return false; }
    if(!Ready(p,mutation)) { ProfileReply(p,"blocked");return false; }
    State* s=p->CustomData.GetDefault<State>(Key);
    if(!Load(p,s)) { s->loaded=false;ClearEffects(p,s);ProfileReply(p,"database");return false; }
    return true;
}
bool ProfileState(ChatHandler* h)
{
    Player* p=h->GetSession()->GetPlayer();if(ProfileReady(p,false))ProfileReply(p,"ok");return true;
}
bool ProfileWrite(ChatHandler* h,uint32 expected,uint32 slot,uint32 spec,uint32 rank,uint32 operation)
{
    Player* p=h->GetSession()->GetPlayer();if(!ProfileReady(p,true))return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(slot>=s->unlocked) { ProfileReply(p,"locked");return true; }
    if(slot>2 || spec>2 || rank>3 || operation>2 || (operation==0 && spec!=0 && rank) || PointsUsed(rank)>ProfilePoints(p) || ((rank&2u) && p->GetLevel()<15))
    { ProfileReply(p,"invalid");return true; }
    if(expected!=s->revision) { ProfileReply(p,"stale");return true; }
    if (operation==0 && s->specs[slot]!=spec) { ProfileReply(p,"bound");return true; }
    uint32 saved=((s->builds>>slot)&1u)|(((s->builds>>(slot+3))&1u)<<1);
    if (operation==0 && (rank&saved)!=saved) { ProfileReply(p,"resetrequired");return true; }
    if (operation==1 && s->specs[slot]==3) { ProfileReply(p,"unbound");return true; }
    if (operation==2 && (s->specs[slot]!=3 || p->GetLevel()<10)) { ProfileReply(p,"bound");return true; }

    uint32 targetSlot=operation==1 ? slot : s->active;
    bool switching=operation==1 && targetSlot!=s->active;
    ActionLayout current=CaptureActions(p),target=current;
    if (switching && !ReadActions(p,targetSlot,target))
    { ProfileReply(p,"database");return true; }
    // Snapshot and talent activation commit together. Failed/stale requests do not change bars.
    QueryResult result=CharacterDatabase.Query("CALL reborn_wd16_write({},{},{},{},{},{},{},{},'{}')",p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),expected,operation,slot,spec,rank,uint32(p->GetLevel()),EncodeActions(current));
    if(!result) { ProfileReply(p,"database");return true; }
    uint32 code=result->Fetch()[0].Get<uint32>();
    if (code==1 && switching)
    {
        s->pendingActions=target;s->pendingActionRestore=true;
        p->SendActionButtons(2); // Clear before spell-removal packets, as in native spec switching.
    }
    if(!Load(p,s)) { s->loaded=false;ClearEffects(p,s);ProfileReply(p,"database");return true; }
    // Keep the cast-time display addon synchronized through the existing WD5A message.
    Reply(p,"ok");ProfileReply(p,code==1?"ok":(code==2?"stale":"invalid"));return true;
}
bool ProfileSave(ChatHandler* h,uint32 rev,uint32 slot,uint32 spec,uint32 rank) { return ProfileWrite(h,rev,slot,spec,rank,0); }
bool ProfileActivate(ChatHandler* h,uint32 rev,uint32 slot) { return ProfileWrite(h,rev,slot,0,0,1); }

bool ProfileBind(ChatHandler* h,uint32 rev,uint32 slot,uint32 spec) { return ProfileWrite(h,rev,slot,spec,0,2); }
bool ResetPrice(uint32& gold)
{
    int32 configured=sConfigMgr->GetOption<int32>("RebornWD16.Reset.Gold",10);
    if (configured<0 || configured>200000) return false;
    gold=uint32(configured);return true;
}
bool ResetQuote(ChatHandler* h,uint32 rev,uint32 slot)
{
    Player* p=h->GetSession()->GetPlayer();if(!ProfileReady(p,true))return true;
    State* s=p->CustomData.GetDefault<State>(Key);s->resetQuoteValid=false;
    uint32 gold=0;
    if (slot>=s->unlocked || slot>2 || s->specs[slot]==3 || rev!=s->revision || !ResetPrice(gold))
    { ProfileReply(p,"invalid");return true; }
    s->resetSlot=slot;s->resetRevision=rev;s->resetGold=gold;
    s->resetQuoteTime=std::chrono::steady_clock::now();s->resetQuoteValid=true;
    ChatHandler(p->GetSession()).PSendSysMessage("WD16Q|{}|{}|{}",rev,slot,gold);return true;
}
bool ResetConfirm(ChatHandler* h,uint32 rev,uint32 slot,uint32 quotedGold)
{
    Player* p=h->GetSession()->GetPlayer();if(!Doctor(p))return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    bool valid=s->resetQuoteValid;s->resetQuoteValid=false;uint32 gold=0;
    if (!valid || !ResetPrice(gold) || gold!=quotedGold || gold!=s->resetGold || rev!=s->resetRevision || slot!=s->resetSlot ||
        std::chrono::steady_clock::now()-s->resetQuoteTime>std::chrono::seconds(60))
    { ProfileReply(p,"quoteexpired");return true; }
    if(!ProfileReady(p,true))return true;
    if (slot>2 || slot>=s->unlocked || s->specs[slot]==3 || s->revision!=rev || rev>=2000000000)
    { ProfileReply(p,"stale");return true; }
    uint32 cost=gold*10000u,before=p->GetMoney();
    if(before<cost) { ProfileReply(p,"money");return true; }
    p->ModifyMoney(-int32(cost));
    if(p->GetMoney()!=before-cost) { p->SetMoney(before);ProfileReply(p,"money");return true; }
    CharacterDatabaseTransaction trans=CharacterDatabase.BeginTransaction();
    // Procedure uses SIGNAL on any guard failure; outer native transaction rolls everything back.
    trans->Append("CALL reborn_wd16_reset({},{},{},{},{})",p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),rev,slot,cost);
    p->SaveGoldToDB(trans);
    auto result=CharacterDatabase.AsyncCommitTransaction(trans);
    if(!result.m_future.get())
    { p->SetMoney(before);ProfileReply(p,"database");return true; }
    if(!Load(p,s)) { s->loaded=false;ClearEffects(p,s);ProfileReply(p,"database");return true; }
    Reply(p,"ok");ProfileReply(p,"ok");return true;
}

// Permanent saved-build slots. Browsing specialization pages is always free.
bool PurchasePolicy(uint32 slot,uint32& level,uint32& gold)
{
    if (slot==1) { level=40;gold=1000;return true; }
    if (slot!=2 || !sConfigMgr->GetOption<bool>("RebornWD13.ThirdSlot.Enable",false)) return false;
    level=sConfigMgr->GetOption<uint32>("RebornWD13.ThirdSlot.MinLevel",40);
    gold=sConfigMgr->GetOption<uint32>("RebornWD13.ThirdSlot.Gold",1000);
    return level>=1 && level<=80 && gold<=200000;
}
void TrainerOptions(Player* p)
{
    if (!ProfileReady(p,false)) return;
    State* s=p->CustomData.GetDefault<State>(Key);
    s->quoteValid=false;
    uint32 level=0,gold=0;
    if (s->unlocked>=3 || !PurchasePolicy(s->unlocked,level,gold)) return;
    s->quoteSlot=s->unlocked;s->quoteLevel=level;s->quoteGold=gold;
    s->quoteTime=std::chrono::steady_clock::now();s->quoteValid=true;
    std::string label="解锁方案 "+std::to_string(s->unlocked+1)+" / Unlock build "+std::to_string(s->unlocked+1)+
        " (一次性 / One-time "+std::to_string(gold)+" Gold, Lv "+std::to_string(level)+")";
    // BoxMoney zero: only the server transaction below charges, never gossip itself.
    AddGossipItemFor(p,GOSSIP_ICON_CHAT,label,GOSSIP_SENDER_MAIN,13,
        "永久解锁此保存方案？ / Permanently unlock this saved build?",0,false);
}
void TrainerPurchase(Player* p)
{
    if (!Doctor(p)) return;
    State* s=p->CustomData.GetDefault<State>(Key);
    bool valid=s->quoteValid;s->quoteValid=false; // single-use, including failures
    uint32 slot=s->quoteSlot,level=0,gold=0;
    if (!valid || std::chrono::steady_clock::now()-s->quoteTime>std::chrono::seconds(60) ||
        !PurchasePolicy(slot,level,gold) || level!=s->quoteLevel || gold!=s->quoteGold)
    { ChatHandler(p->GetSession()).SendSysMessage("WD16: 报价已失效，请重新与导师对话。 / Quote expired; reopen the trainer.");return; }
    if (!ProfileReady(p,true)) return;
    if (s->unlocked!=slot || p->GetLevel()<level)
    { ChatHandler(p->GetSession()).SendSysMessage("WD16: 等级不足或方案已解锁，请重新对话。 / Level too low or build already unlocked.");return; }
    uint32 cost=gold*10000u;
    if (p->GetMoney()<cost)
    { ChatHandler(p->GetSession()).SendSysMessage("WD16: 金币不足。 / Not enough gold.");return; }
    uint32 before=p->GetMoney();
    p->ModifyMoney(-int32(cost));
    if (p->GetMoney()!=before-cost)
    { p->SetMoney(before);return; }
    CharacterDatabaseTransaction trans=CharacterDatabase.BeginTransaction();
    trans->Append("INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES ({},{},{})",p->GetGUID().GetCounter(),slot,cost);
    p->SaveGoldToDB(trans); // Native money persistence; no unrelated spell/inventory dirty flags touched.
    // Await the database result before announcing ownership or accepting a second purchase.
    // This path is rare, like synchronous queries already used by talent activation.
    auto result=CharacterDatabase.AsyncCommitTransaction(trans);
    if (!result.m_future.get())
    {
        p->SetMoney(before);
        ChatHandler(p->GetSession()).SendSysMessage("WD16: 购买事务失败，金币已恢复；请检查服务端数据库日志。 / Purchase failed; gold restored. Check database logs.");
        return;
    }
    if (!Load(p,s))
    { s->loaded=false;ProfileReply(p,"database");return; } // Receipt already committed; no second charge.
    ProfileReply(p,"ok");
    ChatHandler(p->GetSession()).SendSysMessage("WD16: 保存方案已永久解锁，切换不再收费。 / Build unlocked permanently; switching is free.");
}

class Commands : public CommandScript
{
public:
    Commands():CommandScript("reborn_wd5a_commands"){}
    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable cmds={
            {"wd16bind",ProfileBind,SEC_PLAYER,Console::No},
            {"wd16quote",ResetQuote,SEC_PLAYER,Console::No},
            {"wd16reset",ResetConfirm,SEC_PLAYER,Console::No},
            {"wd16state",ProfileState,SEC_PLAYER,Console::No},
            {"wd16save",ProfileSave,SEC_PLAYER,Console::No},
            {"wd16activate",ProfileActivate,SEC_PLAYER,Console::No},
            {"wd5astate",StateCommand,SEC_PLAYER,Console::No},
            };
        return cmds;
    }
};
class ExactModifier : public GlobalScript
{
public:
    ExactModifier():GlobalScript("reborn_wd5a_exact_modifier"){}
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod) override
    {
        if (!Enabled() || !check || (!WD19A::IsWrath(check->Id) && check->Id!=BadJuju) || !mod || mod->op!=SPELLMOD_CASTING_TIME) return true;
        std::lock_guard<std::mutex> lock(registryMutex);
        // In this core false bypasses family-mask matching and returns affected=true (SpellInfo.cpp).
        auto it=registry.find(mod);
        return it==registry.end() || !Doctor(it->second) || it->second->GetLevel()<10;
    }
};
class Players : public PlayerScript
{
public:
    Players():PlayerScript("reborn_wd5a_player"){}
    void OnPlayerLogin(Player* p) override
    {
        if (!Doctor(p)) return;
        State* s=p->CustomData.GetDefault<State>(Key);
        // Read existing builds only on login; first UI query creates a blank row.
        if (!Enabled() || !Load(p,s)) { s->loaded=false;ClearEffects(p,s); }
    }
    void OnPlayerLevelChanged(Player* p,uint8) override
    { if (Doctor(p)) Apply(p,p->CustomData.GetDefault<State>(Key)); }
    void OnPlayerLogout(Player* p) override
    {
        State* s=p->CustomData.GetDefault<State>(Key);Remove(p,s);p->CustomData.Erase(Key);
    }
};
}
void AddRebornWitchDoctorTalentScripts()
{
    new WD5A::Commands();new WD5A::ExactModifier();new WD5A::Players();
}
