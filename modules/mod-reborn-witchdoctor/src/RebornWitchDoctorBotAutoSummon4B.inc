// MBWD4B: separate preferences and wire prefix; original WDMB3 remains unchanged.
bool BotAutoReply4B(ChatHandler* h,uint32 guid,uint32 nonce,WDAS4::Snapshot value,char const* result)
{
    h->PSendSysMessage("WDAS4|{}|{}|STATE|{}|{}|{}|{}",guid,nonce,WDAS4::Version,result,value.revision,value.mask);return true;
}
bool BotAutoState4B(ChatHandler* h,uint32 guid,uint32 nonce)
{
    auto* bot=BotPanelTarget(h,guid,nonce,false,"WDAS4");if(!bot)return true;
    bool stored=WDAS4::LoadPersistent(bot);
    h->PSendSysMessage("WDAS4|{}|{}|STORE|1|{}",guid,nonce,stored?"persistent":"unavailable");
    return BotAutoReply4B(h,guid,nonce,WDAS4::Read(bot),"ok");
}
bool BotAutoSet4B(ChatHandler* h,uint32 guid,uint32 nonce,uint32 expected,uint32 mask)
{
    auto* bot=BotPanelTarget(h,guid,nonce,false,"WDAS4");if(!bot)return true;
    auto result=WDAS4::SetPersistent(bot,expected,mask);
    if(result.result==WDAS4::Result::Database)
    {h->PSendSysMessage("WDAS4|{}|{}|ERROR|storage",guid,nonce);return true;}
    h->PSendSysMessage("WDAS4|{}|{}|STORE|1|persistent",guid,nonce);
    return BotAutoReply4B(h,guid,nonce,result.value,result.result==WDAS4::Result::Ok?"ok":result.result==WDAS4::Result::Stale?"stale":"invalid");
}
