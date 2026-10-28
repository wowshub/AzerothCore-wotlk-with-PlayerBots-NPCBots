// MBWD2A. Included inside WD5A. Scope exists only for one synchronous command.
struct BotPanelRelay
{
    Player* owner;
    ObjectGuid target;
    uint32 nonce;
};
inline thread_local BotPanelRelay const* botPanelRelay=nullptr;
class BotPanelScope
{
    BotPanelRelay const* previous;
public:
    explicit BotPanelScope(BotPanelRelay const& relay):previous(botPanelRelay) { botPanelRelay=&relay; }
    ~BotPanelScope() { botPanelRelay=previous; }
    BotPanelScope(BotPanelScope const&)=delete;
};
class BotPanelChat : public ChatHandler
{
    Player* subject;
public:
    explicit BotPanelChat(Player* p):ChatHandler(p->GetSession()),subject(p) {}
    void SendSysMessage(std::string_view text,bool escape=false) override
    {
        auto* relay=botPanelRelay;
        if(relay && subject->GetGUID()==relay->target && relay->owner && relay->owner->GetSession())
        {
            ChatHandler(relay->owner->GetSession()).PSendSysMessage("WDBOT|{}|{}|{}",relay->target.GetCounter(),relay->nonce,text);
            return;
        }
        ChatHandler::SendSysMessage(text,escape);
    }
};

// MBWD2B: balance is the subject bot's current copper, never the owner's.
inline void BotPanelMoney(Player* p)
{
    if(botPanelRelay && p->GetGUID()==botPanelRelay->target)
    {
        BotPanelChat(p).PSendSysMessage("MONEY|{}",p->GetMoney());
        BotPanelChat(p).PSendSysMessage("LEVEL|{}",p->GetLevel());
    }
}
