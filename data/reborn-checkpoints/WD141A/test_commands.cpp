
#include <cassert>
#include <chrono>
#include <cstdint>
#include <iostream>
#include <string>
using uint32=uint32_t;
struct State { bool panelQuoteValid=false,quoteValid=false,layoutMismatch=false,hexProtocol=true,loaded=true; uint32 revision=5,unlocked=2,quoteSlot=0,quoteGold=0,quoteLevel=0,panelQuoteRevision=0,panelQuoteToken=0;std::chrono::steady_clock::time_point quoteTime; } state;
struct Data { template<class T>T* GetDefault(const char*){return &state;} };
struct Player { Data CustomData; } player;
struct Session { Player* GetPlayer(){return &player;} } session;
struct ChatHandler {Session* GetSession(){return &session;} template<class... T>void PSendSysMessage(const char*,T...){} } handler;
const char* Key="key";
bool ready=true,doctor=true,enabled=true,canPay=true;int transactions=0;
bool Doctor(Player*){return doctor;}
bool ProfileReady(Player*,bool){return ready;}
bool PurchasePolicy(uint32 slot,uint32& level,uint32& gold){level=40;gold=1000;return enabled && slot>=1 && slot<=2;}
void TrainerPurchase(Player*) {if(state.quoteValid && canPay && state.unlocked==state.quoteSlot){++transactions;++state.unlocked;}state.quoteValid=false;}
bool PanelUnlockQuote(ChatHandler* h,uint32 sequence,uint32 revision,uint32 slot)
{
    Player* p=h->GetSession()->GetPlayer();
    if(!Doctor(p)) return false;
    State* s=p->CustomData.GetDefault<State>(Key);
    s->panelQuoteValid=false;s->quoteValid=false;
    auto error=[&](char const* reason) { h->PSendSysMessage("WD141|{}|error|{}",sequence,reason);return true; };
    if(!ProfileReady(p,false)) return error("unavailable");
    if(s->layoutMismatch || !s->hexProtocol || revision!=s->revision) return error("refresh");
    if(slot<1 || slot>2 || slot!=s->unlocked) return error("slot");
    uint32 level=0,gold=0;
    if(!PurchasePolicy(slot,level,gold)) return error("disabled");
    s->quoteSlot=slot;s->quoteGold=gold;s->quoteLevel=level;
    s->quoteTime=std::chrono::steady_clock::now();
    s->panelQuoteRevision=revision;
    if(++s->panelQuoteToken==0) ++s->panelQuoteToken;
    s->panelQuoteValid=true;
    h->PSendSysMessage("WD141|{}|quote|{}|{}|{}|{}|{}",sequence,revision,slot,s->panelQuoteToken,level,gold);
    return true;
}
bool PanelUnlockBuy(ChatHandler* h,uint32 sequence,uint32 token,uint32 revision,uint32 slot)
{
    Player* p=h->GetSession()->GetPlayer();
    if(!Doctor(p)) return false;
    State* s=p->CustomData.GetDefault<State>(Key);
    bool valid=s->panelQuoteValid && token==s->panelQuoteToken && revision==s->panelQuoteRevision && slot==s->quoteSlot;
    s->panelQuoteValid=false; // every confirmation is single-use, including failures.
    auto error=[&](char const* reason) { h->PSendSysMessage("WD141|{}|error|{}",sequence,reason);return true; };
    if(!valid || std::chrono::steady_clock::now()-s->quoteTime>std::chrono::seconds(60)) return error("expired");
    if(!s->loaded || s->layoutMismatch || !s->hexProtocol || revision!=s->revision) return error("refresh");
    // TrainerPurchase rechecks configuration, live ownership, level, money and safe state,
    // then commits the existing unique purchase receipt and gold in one transaction.
    s->quoteValid=true;
    TrainerPurchase(p);
    if(!s->loaded) return error("verify");
    if(s->unlocked<=slot) return error("failed");
    h->PSendSysMessage("WD141|{}|ok|{}",sequence,slot);
    return true;
}


int main(){
 auto reset=[](){state=State{};ready=doctor=enabled=canPay=true;transactions=0;};
 auto quote=[](){return PanelUnlockQuote(&handler,1,5,2);};
 auto buy=[](uint32 t=1,uint32 r=5,uint32 s=2){return PanelUnlockBuy(&handler,2,t,r,s);};
 reset();quote();assert(state.panelQuoteValid && !state.quoteValid);buy();assert(transactions==1 && state.unlocked==3);buy();assert(transactions==1);
 reset();quote();buy(99);assert(transactions==0 && !state.panelQuoteValid);buy();assert(transactions==0);
 reset();quote();buy(1,6);assert(transactions==0);
 reset();quote();buy(1,5,1);assert(transactions==0);
 reset();quote();state.quoteTime-=std::chrono::seconds(61);buy();assert(transactions==0);
 reset();quote();state.revision=6;buy();assert(transactions==0);
 reset();quote();state.layoutMismatch=true;buy();assert(transactions==0);
 reset();quote();canPay=false;buy();assert(transactions==0 && !state.quoteValid);
 reset();enabled=false;quote();assert(!state.panelQuoteValid);
 reset();ready=false;quote();assert(!state.panelQuoteValid);
 reset();state.unlocked=1;quote();assert(!state.panelQuoteValid);
 reset();PanelUnlockQuote(&handler,1,5,3);assert(!state.panelQuoteValid);
 reset();quote();quote();buy(1);assert(transactions==0); // replaced quote invalidates old token
 reset();quote();state.panelQuoteValid=false;buy();assert(transactions==0); // NPC interaction invalidates panel quote
 reset();state.quoteValid=true;quote();assert(!state.quoteValid); // panel interaction invalidates NPC quote
 reset();state.panelQuoteToken=UINT32_MAX;quote();assert(state.panelQuoteToken==1);
 std::cout<<"PASS 16 actual panel-command scenarios (transaction mocked; no production SQL)\n";
}
