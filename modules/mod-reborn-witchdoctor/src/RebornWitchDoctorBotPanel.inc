// MBWD2A. Included inside WD5A after the existing allocation and WD174 APIs.
// No stored Player pointers, target selection, GM bypass, or arbitrary command forwarding.
namespace BotPanelPolicy
{
inline bool Authorized(bool identity,bool owner,bool group,bool map,bool phase,bool range)
{ return identity && owner && group && map && phase && range; }
}
// A single outstanding remote quote per bot. No actor pointers are retained.
struct BotPanelQuote : DataMap::Base
{
    WDRemoteQuote::Identity id{};
    uint32 gold=0,token=0;
    std::chrono::steady_clock::time_point time;
};
constexpr char BotPanelQuoteKey[]="Reborn.MBWD2B.Quote";
inline void BotPanelInvalidateQuote(Player* bot)
{
    if(auto* q=bot->CustomData.Get<BotPanelQuote>(BotPanelQuoteKey)) q->id.active=false;
    if(auto* s=bot->CustomData.Get<State>(Key))
    { s->resetQuoteValid=false;s->panelQuoteValid=false;s->quoteValid=false; }
}
inline void BotPanelArmQuote(Player* bot,Player* owner,uint32 nonce,uint32 revision,uint32 slot,uint32 kind,uint32 gold,uint32 token=0)
{
    auto* q=bot->CustomData.GetDefault<BotPanelQuote>(BotPanelQuoteKey);
    q->id={owner->GetGUID().GetCounter(),bot->GetGUID().GetCounter(),nonce,revision,slot,kind,true};
    q->gold=gold;q->token=token;q->time=std::chrono::steady_clock::now();
}
inline bool BotPanelConsumeQuote(Player* bot,Player* owner,uint32 quoteNonce,uint32 revision,uint32 slot,uint32 kind,uint32 token,uint32 gold)
{
    auto* q=bot->CustomData.Get<BotPanelQuote>(BotPanelQuoteKey);
    if(!q) return false;
    auto age=std::chrono::duration_cast<std::chrono::seconds>(std::chrono::steady_clock::now()-q->time).count();
    bool valid=WDRemoteQuote::Matches(q->id,owner->GetGUID().GetCounter(),bot->GetGUID().GetCounter(),quoteNonce,revision,slot,kind,age)
        && q->token==token && q->gold==gold;
    q->id.active=false; // single use, including a rejected confirmation
    return valid;
}
Player* BotPanelTarget(ChatHandler* h,uint32 guid,uint32 nonce,bool mutation)
{
    auto fail=[&](char const* reason)->Player* {
        h->PSendSysMessage("WDBOT|{}|{}|ERROR|{}",guid,nonce,reason);return nullptr;
    };
    Player* owner=h->GetSession()?h->GetSession()->GetPlayer():nullptr;
    if(!owner || !owner->IsInWorld() || !guid || !nonce || nonce>2147483647u) return fail("identity");
    // Resolve only on the caller's current map; never access another map's actor.
    Player* bot=ObjectAccessor::GetPlayer(*owner,ObjectGuid::Create<HighGuid::Player>(guid));
    if(!bot || !bot->IsInWorld() || !Doctor(bot) || bot==owner || !bot->GetSession()) return fail("unavailable");
    auto* ai=GET_PLAYERBOT_AI(bot);
    if(!BotPanelPolicy::Authorized(ai && !ai->IsRealPlayer(),ai && ai->GetMaster()==owner,
        owner->GetGroup() && owner->GetGroup()==bot->GetGroup(),owner->GetMap()==bot->GetMap(),
        owner->InSamePhase(bot),owner->IsWithinDistInMap(bot,50.0f))) return fail("permission");
    if(mutation && (!WD173::Safe(bot) || !owner->IsAlive() || owner->IsInCombat() || owner->IsBeingTeleported()))
        return fail("unsafe");
    if(mutation && WD174::Running(WD174::Status(bot).phase)) return fail("auto_job_running");
    return bot;
}
bool BotPanelState(ChatHandler* h,uint32 guid,uint32 nonce,uint32 version,std::string_view hash)
{
    auto* bot=BotPanelTarget(h,guid,nonce,false);if(!bot) return true;
    BotPanelInvalidateQuote(bot);
    BotPanelRelay relay{h->GetSession()->GetPlayer(),bot->GetGUID(),nonce};BotPanelScope scope(relay);
    BotPanelChat chat(bot);return ProfileState139(&chat,version,hash);
}
bool BotPanelJoin(ChatHandler* h,uint32 guid,uint32 nonce,uint32 revision)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    BotPanelInvalidateQuote(bot);
    BotPanelRelay relay{h->GetSession()->GetPlayer(),bot->GetGUID(),nonce};BotPanelScope scope(relay);
    BotPanelChat chat(bot);return AEJoin(&chat,revision);
}
bool BotPanelBind(ChatHandler* h,uint32 guid,uint32 nonce,uint32 revision,uint32 slot,uint32 spec)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    BotPanelInvalidateQuote(bot);
    BotPanelRelay relay{h->GetSession()->GetPlayer(),bot->GetGUID(),nonce};BotPanelScope scope(relay);
    BotPanelChat chat(bot);return ProfileBind(&chat,revision,slot,spec);
}
bool BotPanelSave(ChatHandler* h,uint32 guid,uint32 nonce,uint32 revision,uint32 slot,uint32 version,std::string_view hash,std::string_view hex)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    BotPanelInvalidateQuote(bot);
    BotPanelRelay relay{h->GetSession()->GetPlayer(),bot->GetGUID(),nonce};BotPanelScope scope(relay);
    BotPanelChat chat(bot);
    // Check parsing before dispatch so every supported request has a response.
    WD139::Build build;
    if(!WD139::Build::ParseHex(hex,build)) { chat.SendSysMessage("ERROR|invalid_mask");return true; }
    return AESave139(&chat,revision,slot,version,hash,hex);
}
bool BotPanelActivate(ChatHandler* h,uint32 guid,uint32 nonce,uint32 revision,uint32 slot)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    BotPanelInvalidateQuote(bot);
    BotPanelRelay relay{h->GetSession()->GetPlayer(),bot->GetGUID(),nonce};BotPanelScope scope(relay);
    BotPanelChat chat(bot);return ProfileActivate(&chat,revision,slot);
}

bool BotPanelResetQuote(ChatHandler* h,uint32 guid,uint32 nonce,uint32 revision,uint32 slot)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    BotPanelInvalidateQuote(bot);
    auto* owner=h->GetSession()->GetPlayer();
    BotPanelRelay relay{owner,bot->GetGUID(),nonce};BotPanelScope scope(relay);
    BotPanelChat chat(bot);BotPanelMoney(bot);
    ResetQuote(&chat,revision,slot);
    auto* s=bot->CustomData.Get<State>(Key);
    if(s && s->resetQuoteValid && s->resetRevision==revision && s->resetSlot==slot)
        BotPanelArmQuote(bot,owner,nonce,revision,slot,1,s->resetGold);
    return true;
}
bool BotPanelReset(ChatHandler* h,uint32 guid,uint32 nonce,uint32 quoteNonce,uint32 revision,uint32 slot,uint32 gold)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    auto* owner=h->GetSession()->GetPlayer();
    BotPanelRelay relay{owner,bot->GetGUID(),nonce};BotPanelScope scope(relay);BotPanelChat chat(bot);
    if(!BotPanelConsumeQuote(bot,owner,quoteNonce,revision,slot,1,0,gold))
    { BotPanelInvalidateQuote(bot);chat.SendSysMessage("ERROR|quoteexpired");return true; }
    return ResetConfirm(&chat,revision,slot,gold);
}
bool BotPanelUnlockQuote(ChatHandler* h,uint32 guid,uint32 nonce,uint32 revision,uint32 slot)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    BotPanelInvalidateQuote(bot);
    auto* owner=h->GetSession()->GetPlayer();
    BotPanelRelay relay{owner,bot->GetGUID(),nonce};BotPanelScope scope(relay);
    BotPanelChat chat(bot);BotPanelMoney(bot);
    PanelUnlockQuote(&chat,nonce,revision,slot);
    auto* s=bot->CustomData.Get<State>(Key);
    if(s && s->panelQuoteValid && s->panelQuoteRevision==revision && s->quoteSlot==slot)
        BotPanelArmQuote(bot,owner,nonce,revision,slot,2,s->quoteGold,s->panelQuoteToken);
    return true;
}
bool BotPanelUnlock(ChatHandler* h,uint32 guid,uint32 nonce,uint32 quoteNonce,uint32 revision,uint32 slot,uint32 token,uint32 gold)
{
    auto* bot=BotPanelTarget(h,guid,nonce,true);if(!bot) return true;
    auto* owner=h->GetSession()->GetPlayer();
    BotPanelRelay relay{owner,bot->GetGUID(),nonce};BotPanelScope scope(relay);BotPanelChat chat(bot);
    if(!BotPanelConsumeQuote(bot,owner,quoteNonce,revision,slot,2,token,gold))
    { BotPanelInvalidateQuote(bot);chat.SendSysMessage("ERROR|quoteexpired");return true; }
    if(gold>200000u || bot->GetMoney()<gold*10000u)
    { BotPanelInvalidateQuote(bot);BotPanelMoney(bot);chat.SendSysMessage("ERROR|money");return true; }
    auto* s=bot->CustomData.Get<State>(Key);
    if(!s || bot->GetLevel()<s->quoteLevel)
    { BotPanelInvalidateQuote(bot);chat.SendSysMessage("ERROR|level");return true; }
    return PanelUnlockBuy(&chat,nonce,token,revision,slot);
}
