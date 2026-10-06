#include "RebornWitchDoctorBrewingNumbers.h"
// WD5A: one working CoA talent, three independent saved test builds.
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DataMap.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "RebornWitchDoctorRanks.h"
#include "RebornWitchDoctorTalentNodes.h"
#include "RebornWitchDoctorBudget.h"
#include "WitchDoctorTalentPolicy.h"
#include "ScriptDefines/GlobalScript.h"
#include "SpellInfo.h"
#include "RebornWitchDoctorSpiritWalker.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "WorldSession.h"
#include "ScriptedGossip.h"
#include "Transaction.h"
#include <boost/multiprecision/cpp_int.hpp>
#include <string_view>
#include <array>
#include <sstream>
#include <chrono>
#include <mutex>
#include <unordered_map>
using namespace Acore::ChatCommands;
namespace WD19A { uint32 ResolveAction(Player* player, uint32 spell); void SyncBadJuju(Player* player); }

namespace WD5A
{
constexpr uint32 Wrath=9003100, BadJuju=9003103, Node=6058;
uint32 PointsUsed(uint32 mask) { return (mask&1u)+((mask>>1)&1u); }
constexpr char Key[]="Reborn.WD5A";
// WD109: exact mask transport; persistent storage remains node rows.
using AEMask=boost::multiprecision::uint128_t;
using ActionLayout=std::array<uint32,MAX_ACTION_BUTTONS>;
struct State : DataMap::Base
{
    SpellModifier* modifier=nullptr;
    uint32 revision=0, active=0, builds=0;
    bool loaded=false;
    char const* readyError="blocked"; // WD67B: preserve the actual rejection reason.
    bool modern=false;
    uint32 testAE=0,testTE=0; // WD95: character/account-scoped GM test allowance.
    std::array<AEMask,3> aeMasks{};
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
    std::chrono::steady_clock::time_point mutationRequest; // WD101: reads never consume the write cooldown.
    std::chrono::steady_clock::time_point numberRequest;
    std::chrono::steady_clock::time_point auditRequest;
};
bool AELoad(Player*,State*);
void AEApply(Player*,State*);
void WD67ClearSummons(Player*,bool,bool);
void WD68Clear(Player*,bool,bool);
void WD111ClearExtra(Player*);
void WD117ClearSwift(Player*);
uint32 AESpent(AEMask);
uint32 TEFoundation(AEMask);
uint32 TESpent(AEMask);
uint32 AERank(AEMask,uint32);
bool AEValid(AEMask,uint32,uint32=0,uint32=0);
constexpr uint32 AEIdCount=98;
extern uint32 const AEIds[AEIdCount];
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
// WD81A: no database query on every hit; use the already loaded active build.
bool CanUseHollow(Player* p)
{
    if(!Doctor(p)) return false;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(s->modern) return Enabled() && ProfilesEnabled() && s->loaded && s->specs[s->active]==0 &&
        AEValid(s->aeMasks[s->active],p->GetLevel(),s->testAE,s->testTE) && AERank(s->aeMasks[s->active],16)>0;
    return p->GetLevel()>=30 && (!ProfilesEnabled() || s->loaded);
}
// WD82A: legacy trainer ranks keep level30; modern ownership comes from the active saved build.
bool CanUseHexTalent(Player* p,uint32 spell)
{
    if(!Doctor(p)) return false;
    uint32 index=spell==9003521?17u:(spell==9003530?18u:(spell==9003520?19u:20u));
    if(index==20) return false;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(s->modern) return Enabled() && ProfilesEnabled() && s->loaded && s->specs[s->active]==0 &&
        AEValid(s->aeMasks[s->active],p->GetLevel(),s->testAE,s->testTE) && AERank(s->aeMasks[s->active],index)>0;
    return p->GetLevel()>=30 && (!ProfilesEnabled() || s->loaded);
}
// WD83A: read only active, committed ownership; no database lookup in hit hooks.
uint32 RitualHexingRank(Player* p)
{
    if(!Doctor(p)) return 0;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(!Enabled() || !ProfilesEnabled() || !s->modern || !s->loaded || s->specs[s->active]!=0 ||
        !AEValid(s->aeMasks[s->active],p->GetLevel(),s->testAE,s->testTE)) return 0;
    return AERank(s->aeMasks[s->active],21);
}
bool CanCastBadJuju(Player* p)
{
    if (!Doctor(p) || !Enabled() || !ProfilesEnabled() || p->GetLevel()<15) return false;
    State* s=p->CustomData.GetDefault<State>(Key);
    return s->loaded && s->specs[s->active]==0 &&
        (s->modern ? AEValid(s->aeMasks[s->active],p->GetLevel(),s->testAE,s->testTE) && AERank(s->aeMasks[s->active],12)>0 : ((s->builds>>(s->active+3))&1u));
}
void ClearEffects(Player* p,State* s)
{
    Remove(p,s);
    if (Doctor(p)) {
        for (auto const& rank:WD19A::BadJujuRanks) if(p->HasSpell(rank.spell)) p->removeSpell(rank.spell,3,false);
        if(p->HasSpell(9003490)) p->removeSpell(9003490,3,false);
    }
}
void Apply(Player* p,State* s)
{
    AEApply(p,s);
    WD19A::SyncBadJuju(p);
    bool wanted=Enabled() && Doctor(p) && p->GetLevel()>=10 && s->loaded && s->specs[s->active]==0 &&
        (s->modern ? AEValid(s->aeMasks[s->active],p->GetLevel(),s->testAE,s->testTE) && AERank(s->aeMasks[s->active],11)>0 : ((s->builds>>s->active)&1));
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
    s->revision=rev;s->active=active;s->builds=builds;
    if(!AELoad(p,s)) return false;
    s->loaded=true;Apply(p,s);
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
    State* state=p->CustomData.GetDefault<State>(Key);state->readyError="blocked";
    if (!Enabled()) { ClearEffects(p,p->CustomData.GetDefault<State>(Key));Reply(p,"disabled");return false; }
    if (!sSpellMgr->GetSpellInfo(Wrath) || !sSpellMgr->GetSpellInfo(BadJuju)) { state->readyError="spell";Reply(p,"spell");return false; }
    State* s=p->CustomData.GetDefault<State>(Key);
    auto now=std::chrono::steady_clock::now();
    auto& lastRequest = mutation ? s->mutationRequest : s->request;
    if (now-lastRequest<std::chrono::milliseconds(250)) { state->readyError="busy";Reply(p,"busy");return false; }
    lastRequest=now;
    if (mutation)
    {
        char const* reason=!p->IsAlive()?"dead":p->IsInCombat()?"combat":
            p->IsNonMeleeSpellCast(false)?"casting":(p->IsInFlight() || p->GetVehicle() || p->GetTransport())?"transport":nullptr;
        if(reason) { state->readyError=reason;Reply(p,reason);return false; }
    }
    if (!s->loaded)
    {
        CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd5a_builds (guid,revision,active,builds) VALUES ({},0,0,0)",p->GetGUID().GetCounter());
        if (ProfilesEnabled()) CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd8_profiles(guid) VALUES ({})",p->GetGUID().GetCounter());
        CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES ({},0,0)",p->GetGUID().GetCounter());
        for(uint32 slot=0;slot<3;++slot) CharacterDatabase.DirectExecute("INSERT IGNORE INTO reborn_wd16_profiles(guid,slot,spec) VALUES ({},{},3)",p->GetGUID().GetCounter(),slot);
        if (!Load(p,s)) { state->readyError="database";Reply(p,"database");return false; }
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
bool ResetPrice(uint32& gold);
void ProfileReply(Player* p,char const* result)
{
    State* s=p->CustomData.GetDefault<State>(Key);
    uint32 resetGold=0;
    if(ResetPrice(resetGold)) ChatHandler(p->GetSession()).PSendSysMessage("WD16P|{}",resetGold);
    else ChatHandler(p->GetSession()).PSendSysMessage("WD16P|invalid");
    ChatHandler(p->GetSession()).PSendSysMessage("WD16|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",result,s->revision,s->active,s->builds,s->specs[0],s->specs[1],s->specs[2],p->GetLevel(),s->loaded?1:0,ProfilePoints(p),s->unlocked,s->modern?1:0,s->aeMasks[0].str(),s->aeMasks[1].str(),s->aeMasks[2].str(),WD67Budget::AE(p->GetLevel())+s->testAE,WD67Budget::TE(p->GetLevel())+s->testTE);
}
bool ProfileReady(Player* p,bool mutation)
{
    if(!Doctor(p))return false;
    if(!ProfilesEnabled() || !Enabled()) { ClearEffects(p,p->CustomData.GetDefault<State>(Key));ProfileReply(p,"disabled");return false; }
    if(!Ready(p,mutation)) { ProfileReply(p,p->CustomData.GetDefault<State>(Key)->readyError);return false; }
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
    if(s->modern && operation==0) { ProfileReply(p,"invalid");return true; }
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
    Player* p=h->GetSession()->GetPlayer();if(!Doctor(p))return true;
    State* s=p->CustomData.GetDefault<State>(Key);s->resetQuoteValid=false;
    uint32 gold=0;
    if(!ProfilesEnabled() || !Enabled()) { ProfileReply(p,"disabled");return true; }
    if(!ResetPrice(gold)) { ProfileReply(p,"invalid");return true; }
    // Quote is not a purchase. Report insufficient funds before transient action guards.
    if(p->GetMoney()<gold*10000u) { ProfileReply(p,"money");return true; }
    if(!ProfileReady(p,true))return true;
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
    if(p->GetMoney()<gold*10000u) { ProfileReply(p,"money");return true; }
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
    if(s->modern) trans->Append("DELETE FROM reborn_wd67_nodes WHERE guid={} AND slot={}",p->GetGUID().GetCounter(),slot);
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

// WD64A: read-only server projection. This never awards spells or talent points.
bool AuditNode(ChatHandler* h,uint32 expected,uint32 slot,uint32 nodeID)
{
    Player* p=h->GetSession()->GetPlayer();
    if (!Doctor(p)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    auto now=std::chrono::steady_clock::now();
    if (now-s->auditRequest<std::chrono::milliseconds(500)) return true;
    s->auditRequest=now;
    WD64A::Node const* n=WD64A::Find(nodeID);
    // No Ready/Load here: inspecting a node must not create records or reapply effects.
    if (!Enabled() || !ProfilesEnabled() || !s->loaded || expected!=s->revision || slot>2 || slot>=s->unlocked || !n)
    {
        h->PSendSysMessage("WD64|{}|{}|{}|unavailable",s->revision,slot,nodeID);
        return true;
    }
    auto rank=[&](uint32 id)->uint32 {
        if (s->modern) { for(uint32 i=0;i<AEIdCount;++i) if(AEIds[i]==id) return AERank(s->aeMasks[slot],i);return 0; }
        if (s->specs[slot]!=0) return 0;
        if (id==6058) return (s->builds>>slot)&1u;
        if (id==29928) return (s->builds>>(slot+3))&1u;
        return 0; // Trainer ownership never counts as an allocated talent point.
    };
    uint32 ae=0,te=0,missing=0,group=0;
    for (auto const& other:WD64A::Nodes)
    {
        uint32 r=rank(other.id);
        if (other.tree==n->tree) { ae+=r*other.ae;te+=r*other.te; }
        if (n->group && other.group==n->group && other.id!=n->id && r) group=1;
    }
    for (uint32 required:n->required) if (!rank(required)) ++missing;
    uint32 flags=0,level=n->level;
    if (n->id==6058 || n->id==7131 || n->id==30884 || n->id==29736 || n->id==5055 || n->id==7129) level=10;
    if (n->id==29928) level=15;
    bool legacy=!s->modern && (n->id==6058 || n->id==29928);
    bool open=legacy;
    if(s->modern) for(uint32 id:AEIds) if(id==n->id) open=true;
    if(s->modern && (n->id==31344 || n->id==31340)) level=10;
    if(s->modern && n->id==7157) level=15;
    if(s->modern && (n->id==30147 || n->id==4132 || n->id==7033 || n->id==6051 || n->id==6048)) ae=AESpent(s->aeMasks[slot])-AERank(s->aeMasks[slot],40)-AERank(s->aeMasks[slot],41)-AERank(s->aeMasks[slot],46)-AERank(s->aeMasks[slot],47)-AERank(s->aeMasks[slot],48)-AERank(s->aeMasks[slot],58)-AERank(s->aeMasks[slot],59)-AERank(s->aeMasks[slot],63)-AERank(s->aeMasks[slot],64)-AERank(s->aeMasks[slot],65)-AERank(s->aeMasks[slot],67)-AERank(s->aeMasks[slot],68)-AERank(s->aeMasks[slot],69)-AERank(s->aeMasks[slot],70)-AERank(s->aeMasks[slot],71)-AERank(s->aeMasks[slot],72)-AERank(s->aeMasks[slot],73);
    if(s->modern && (n->id==7948 || n->id==31137)) { level=n->id==31137?30:16;te=AERank(s->aeMasks[slot],49)+AERank(s->aeMasks[slot],50)+AERank(s->aeMasks[slot],51)+AERank(s->aeMasks[slot],53)+AERank(s->aeMasks[slot],55)+AERank(s->aeMasks[slot],81); }
    if(s->modern && (n->id==5113 || n->id==30891 || n->id==6030 || n->id==7132 || n->id==29753))
    {
        level=n->id==5113?58:n->id==30891?30:n->id==6030?10:31;
        if(n->id==5113 || n->id==30891) ae=AESpent(s->aeMasks[slot])-AERank(s->aeMasks[slot],40)-AERank(s->aeMasks[slot],41)-AERank(s->aeMasks[slot],46)-AERank(s->aeMasks[slot],47)-AERank(s->aeMasks[slot],48)-AERank(s->aeMasks[slot],58)-AERank(s->aeMasks[slot],59)-AERank(s->aeMasks[slot],63)-AERank(s->aeMasks[slot],64)-AERank(s->aeMasks[slot],65)-AERank(s->aeMasks[slot],67)-AERank(s->aeMasks[slot],68)-AERank(s->aeMasks[slot],69)-AERank(s->aeMasks[slot],70)-AERank(s->aeMasks[slot],71)-AERank(s->aeMasks[slot],72)-AERank(s->aeMasks[slot],73);
        if(n->id==7132 || n->id==29753) te=AERank(s->aeMasks[slot],49)+AERank(s->aeMasks[slot],50)+AERank(s->aeMasks[slot],51)+AERank(s->aeMasks[slot],53)+AERank(s->aeMasks[slot],55)+AERank(s->aeMasks[slot],81);
    }
    if(s->modern && (n->id==6381 || n->id==12048 || n->id==11323 || n->id==12264 || n->id==6042 || n->id==9347 || n->id==29306 || n->id==6031 || n->id==6525 || n->id==12525))
    {
        level=10;
        auto mask=s->aeMasks[slot];
        ae=AERank(mask,0)+AERank(mask,1)+AERank(mask,2)+AERank(mask,3)+AERank(mask,4)+AERank(mask,5)+AERank(mask,39)+AERank(mask,60)+AERank(mask,66);
    }
    if(s->modern && (n->id==31118 || n->id==6042 || n->id==9347)) level=10;
    if(s->modern && (n->id==6031 || n->id==6525 || n->id==12525)) level=26;
    if(s->modern && (n->id==6016 || n->id==6009))
    {
        level=10;missing=rank(4005) && rank(12645) && rank(n->id==6016?29738:6021)?0:1;
        te=rank(7131)+rank(30884)+rank(29736)+rank(5055)+rank(7129)+rank(7128);
    }
    if(s->modern && (n->id==30823 || n->id==6022 || n->id==6013))
    {
        level=n->id==30823?29:10;
        bool parent=n->id==30823?(rank(7128)||rank(29303)):(n->id==6022?rank(7128):(rank(29303)||rank(29738)));
        missing=rank(4005) && parent?0:1;
        te=rank(7131)+rank(30884)+rank(29736)+rank(5055)+rank(7129)+rank(7128);
    }
    if(s->modern && (n->id==6021 || n->id==6014))
    {
        level=10;missing=rank(4005)?0:1;
        te=rank(7131)+rank(30884)+rank(29736)+rank(5055)+rank(7129)+rank(7128);
    }
    if(s->modern && (n->id==6645 || n->id==4112 || n->id==7130))
    {
        level=10;missing=rank(4005)?0:1;
        te=rank(7131)+rank(30884)+rank(29736)+rank(5055)+rank(7129)+rank(7128);
    }
    if(s->modern && n->id==7128) level=17;
    if(s->modern && (n->id==6498 || n->id==29303 || n->id==6020 || n->id==29737 || n->id==35065 || n->id==35064 || n->id==35068 || n->id==29738 || n->id==30888 || n->id==35051))
    {
        level=10;te=rank(7131)+rank(30884)+rank(29736)+rank(5055)+rank(7129)+rank(7128);
    }
    if(s->modern && (n->id==4005 || n->id==12645 || n->id==12646))
    {
        level=n->id==12646?14:10;
        if(n->id!=4005) missing=(rank(4005) || rank(29744))?0:1;
    }
    if(s->modern && n->id==29306) level=30;
    if(s->modern && n->id==31349) { level=59;te=TEFoundation(s->aeMasks[slot]); }
    if(s->modern && (n->id==29929 || n->id==6055)) te=TESpent(s->aeMasks[slot])-AERank(s->aeMasks[slot],34)-AERank(s->aeMasks[slot],35)-AERank(s->aeMasks[slot],36)-AERank(s->aeMasks[slot],37)-AERank(s->aeMasks[slot],43)-AERank(s->aeMasks[slot],44);
    if(s->modern && n->id==30596) { level=27;te=TEFoundation(s->aeMasks[slot]); }
    if(s->modern && (n->id==29768 || n->id==6057)) { level=57;te=TESpent(s->aeMasks[slot])-AERank(s->aeMasks[slot],34)-AERank(s->aeMasks[slot],35)-AERank(s->aeMasks[slot],36)-AERank(s->aeMasks[slot],37)-AERank(s->aeMasks[slot],43)-AERank(s->aeMasks[slot],44); }
    if(s->modern && n->id==7100) { level=10;te=TESpent(s->aeMasks[slot])-AERank(s->aeMasks[slot],34)-AERank(s->aeMasks[slot],35)-AERank(s->aeMasks[slot],36)-AERank(s->aeMasks[slot],37)-AERank(s->aeMasks[slot],43)-AERank(s->aeMasks[slot],44); }
    if(s->modern && n->id==31346) { level=10;te=TESpent(s->aeMasks[slot])-AERank(s->aeMasks[slot],34)-AERank(s->aeMasks[slot],35)-AERank(s->aeMasks[slot],36)-AERank(s->aeMasks[slot],37)-AERank(s->aeMasks[slot],43)-AERank(s->aeMasks[slot],44); }
    if(s->modern && (n->id==6045 || n->id==31341 || n->id==31347 || n->id==31348 || n->id==6644 || n->id==6046 || n->id==6062 || n->id==30889 || n->id==31343 || n->id==6053 || n->id==31350 || n->id==5333 || n->id==6059 || n->id==5332 || n->id==6007 || n->id==29121)) { level=n->id==29121?33:10;te=TEFoundation(s->aeMasks[slot]); }
    if (s->specs[slot]==3 || (n->tree!=3 && s->specs[slot]!=n->tree)) flags|=1;
    if (p->GetLevel()<level) flags|=2;
    if (missing) flags|=4;
    if (ae<n->needAE) flags|=8;
    if (te<n->needTE) flags|=16;
    if (group) flags|=32;
    if (!n->mapped) flags|=64;
    if (!open) flags|=128;
    if (rank(n->id)>=n->maxRank) flags|=256;
    if (!s->modern && rank(n->id)==0 && PointsUsed(((s->builds>>slot)&1u)|(((s->builds>>(slot+3))&1u)<<1))>=ProfilePoints(p)) flags|=512;
    // Graph ConnectedNodes are preserved in the source but not invented as AND/OR rules.
    h->PSendSysMessage("WD64|{}|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}|{}|{}",s->revision,slot,nodeID,flags,rank(n->id),level,ae,n->needAE,te,n->needTE,missing,open?1:0);
    return true;
}

#include "RebornWitchDoctorAllocation.inc"

// WD114: tooltip uses the same cost/effect calculator as the cast itself.
bool SpellNumbers(ChatHandler* h,uint32 sequence,uint32 id)
{
    Player* p=h->GetSession()->GetPlayer();
    if(!Doctor(p)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    auto const now=std::chrono::steady_clock::now();
    if(now-s->numberRequest<std::chrono::milliseconds(400)) return true;
    s->numberRequest=now;
    WD19A::Family const* family=WD19A::FindFamily(id);
    uint32 const base=family?family->ranks[0].spell:0;
    bool const wuju=base==9003140 || base==9003180 || base==9003190 || base==9003280 || base==9003290 || base==9003300;
    bool const jinx=base==9003150 || base==9003200 || base==9003210 || base==9003220 || id==9003762;
    bool const walkerTarget=id==9003855 || id==9003432;
    bool const allowed=(id>=9003922 && id<=9003928) || (id>=9003460 && id<=9003467) || id==WD120A::Shrooms || (WD120A::IsToss(id) || WD120A::IsSplash(id)) || id==9003861 || id==9003859 || walkerTarget || wuju || jinx || base==9003240 || base==9003101;
    SpellInfo const* info=sSpellMgr->GetSpellInfo(id);
    if(!Enabled() || !allowed || !info || !p->HasSpell(id) || !s->loaded)
    {
        h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true;
    }
    if(walkerTarget)
    {
        int32 const amount=id==9003855 ? -p->CalculateSpellDamage(p,info,EFFECT_0) : WD117::SwiftAmount(p);
        uint32 const healing=id==9003855 ? 2*(100+WD117::Bonus(p)) : 0;
        h->PSendSysMessage("WD114|{}|{}|ok|0|{}|{}|{}|{}|{}",sequence,id,WD117::Duration(p),amount,s->revision,s->active,healing);
        return true;
    }
    int32 const cost=p->GetCommandStatus(CHEAT_POWER)?0:info->CalcPowerCost(p,info->GetSchoolMask());
    if(id==WD120A::Shrooms || WD120A::IsToss(id) || WD120A::IsSplash(id))
    {
        bool pulse=id==WD120A::Shrooms;
        SpellInfo const* heal=pulse?sSpellMgr->GetSpellInfo(WD120A::Pulse):info;
        if(!heal) { h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true; }
        auto const& effect=heal->Effects[EFFECT_0];
        int32 level=int32(p->GetLevel());
        if(heal->MaxLevel && level>int32(heal->MaxLevel)) level=int32(heal->MaxLevel);
        level=std::max(level,int32(heal->BaseLevel))-int32(std::max(heal->BaseLevel,heal->SpellLevel));
        int32 base=effect.BasePoints+int32(level*effect.RealPointsPerLevel);
        auto estimate=[&](int32 dice)
        {
            float amount=p->ApplyEffectModifiers(heal,EFFECT_0,float(base+dice));
            if(pulse) amount=float(int32(double(amount)*WD120A::Scaling(p->GetLevel())));
            uint32 result=uint32(std::max(0,int32(amount+(WD120A::IsSplash(id)?WD120A::SplashBonus(p):WD120A::Bonus(p,pulse)))));
            return p->SpellHealingBonusDone(p,heal,result,HEAL,EFFECT_0);
        };
        uint32 lo=estimate(effect.DieSides==0?0:1),hi=estimate(effect.DieSides);
        int32 cooldown=info->RecoveryTime;
        p->ApplySpellMod(id,SPELLMOD_COOLDOWN,cooldown);
        if(p->HasAura(9003897) && (WD120A::IsToss(id) || WD120A::IsSplash(id)))
            cooldown=std::min<int32>(cooldown,std::max<int32>(0,int32(info->RecoveryTime)-5000));
        if(pulse)
        {
            int32 interval=info->Effects[EFFECT_0].Amplitude;
            p->ApplySpellMod(id,SPELLMOD_ACTIVATION_TIME,interval);
            if(AuraEffect* effect=p->GetAuraEffect(id,EFFECT_0,p->GetGUID())) interval=effect->GetAmplitude();
            h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,interval,WD120A::PulseTargets(p));
        }
        else if(WD120A::IsSplash(id))
        {
            SpellInfo const* hot=sSpellMgr->GetSpellInfo(WD120A::SplashHot);
            if(!hot) { h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true; }
            uint32 tick=p->SpellHealingBonusDone(p,hot,uint32(std::max(0,hot->Effects[EFFECT_0].CalcValue(p))),DOT,EFFECT_0);
            h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,tick,12000,std::max(0,cooldown));
        }
        else h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,0,0,std::max(0,cooldown));
        return true;
    }
    if(id==9003861)
    {
        int32 cooldown=info->RecoveryTime;
        p->ApplySpellMod(id,SPELLMOD_COOLDOWN,cooldown);
        h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,info->CalcCastTime(p),std::max(0,cooldown),s->revision,s->active);
        return true;
    }
    // Only fixed-range effects: don't roll RNG just to display a tooltip.
    int32 a=0,b=0;
    if(base==9003180 || base==9003300 || base==9003240)
    {
        a=p->CalculateSpellDamage(p,info,EFFECT_0);
        if(base!=9003240) b=p->CalculateSpellDamage(p,info,EFFECT_1);
    }
    h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,a,b,s->revision,s->active);
    return true;
}

class Commands : public CommandScript
{
public:
    Commands():CommandScript("reborn_wd5a_commands"){}
    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable cmds={
            {"wd114numbers",SpellNumbers,SEC_PLAYER,Console::No},
            {"wdtestpoints",AETestPoints,SEC_GAMEMASTER,Console::No},
            {"wd67join",AEJoin,SEC_PLAYER,Console::No},
            {"wd67save",AESave,SEC_PLAYER,Console::No},
            {"wd64check",AuditNode,SEC_PLAYER,Console::No},
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
        if (!Enabled() || !check || (!WD19A::IsWrath(check->Id) && !WD19A::IsBadJuju(check->Id)) || !mod || mod->op!=SPELLMOD_CASTING_TIME) return true;
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
