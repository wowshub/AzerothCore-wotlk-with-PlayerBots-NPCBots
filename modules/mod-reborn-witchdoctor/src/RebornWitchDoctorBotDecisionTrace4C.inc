// Read the last actual TickAction observation. Never call Choose or cast here.
bool BotWhyState4C(ChatHandler* h,uint32 guid,uint32 nonce,uint32 mode)
{
    auto* bot=BotPanelTarget(h,guid,nonce,false,"WDWHY4");if(!bot)return true;
    if(mode>2){h->PSendSysMessage("WDWHY4|{}|{}|ERROR|mode",guid,nonce);return true;}
    WDWHY4::Control(bot,mode);
    auto* state=bot->CustomData.Get<WDWHY4::State>(WDWHY4::Key);auto now=WDWHY4::Clock::now();
    auto v=state?state->value:WDWHY4::Snapshot{};
    auto remaining=WDWHY4::Remaining(state,now);
    h->PSendSysMessage("WDWHY4|{}|{}|BEGIN|1|{}|{}|{}|{}|{}",guid,nonce,remaining?1:0,v.observed?1:0,v.observed?WDWHY4::Age(v.sampled,now):0,remaining,v.samples);
    h->PSendSysMessage("WDWHY4|{}|{}|PLAN|{}|{}|{}|{}|{}",guid,nonce,v.planAvailable?1:0,v.slot,v.spec,v.revision,v.planReason);
    h->PSendSysMessage("WDWHY4|{}|{}|BOT|{}|{}|{}|{}|{}|{}|{}|{}",guid,nonce,v.hp,v.mana,v.maxMana,v.combat?1:0,v.moving?1:0,v.casting?1:0,v.basicMask,v.summonMask);
    h->PSendSysMessage("WDWHY4|{}|{}|DECISION|{}|{}|{}|{}|{}",guid,nonce,v.phase,v.spell,v.reason,v.damage?1:0,v.reposition?1:0);
    h->PSendSysMessage("WDWHY4|{}|{}|TARGET|{}",guid,nonce,v.target);
    h->PSendSysMessage("WDWHY4|{}|{}|ATTEMPT|{}|{}|{}",guid,nonce,v.attemptSpell,v.attemptResult,v.attemptResult?WDWHY4::Age(v.attempted,now):0);
    h->PSendSysMessage("WDWHY4|{}|{}|SPELL|{}|{}|{}|{}",guid,nonce,v.infoKnown?1:0,v.cost,v.cooldown,v.gcd);
    h->PSendSysMessage("WDWHY4|{}|{}|END",guid,nonce);return true;
}
