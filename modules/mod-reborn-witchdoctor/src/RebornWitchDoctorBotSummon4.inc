// MBWD4A. Included inside WD5A after BotPanelTarget. All pointers are call-local.
struct WardRow4
{
    uint32 key=0,spell=0,cost=0,cooldown=0,gcd=0;
    int32 power=0;
    char const* reason="unlearned";
};
WardRow4 ReadWard4(Player* bot,Player* owner,uint32 key)
{
    WardRow4 row;row.key=key;auto base=WDWS4::Base(key);if(!base)return row;
    auto learned=WD168::ReadSpell(bot,base);if(!learned.learned)return row;
    row.spell=WDWS4::Resolve(key,learned.learned,learned.replacement,
        bot->HasSpell(9004180)&&bot->HasAura(9004180,bot->GetGUID()));
    if(!row.spell){row.reason="replacement";return row;}
    auto* info=sSpellMgr->GetSpellInfo(row.spell);
    if(!info){row.reason="data";return row;}
    row.power=int32(info->PowerType);row.cost=uint32(std::max(0,info->CalcPowerCost(bot,info->GetSchoolMask())));
    row.cooldown=std::max(learned.cooldownMs,bot->GetSpellCooldownDelay(row.spell));
    row.gcd=bot->GetGlobalCooldownMgr().GetGlobalCooldown(info);
    if(!owner->IsAlive()||!bot->IsAlive())row.reason="dead";
    else if(!bot->IsInWorld()||bot->IsBeingTeleported()||bot->IsInFlight()||bot->IsCharmed())row.reason="unsafe";
    else if(WD174::Running(WD174::Status(bot).phase))row.reason="job";
    else if(bot->IsNonMeleeSpellCast(false,false,true))row.reason="busy";
    else if(row.cooldown)row.reason="cooldown";
    else if(row.gcd)row.reason="gcd";
    else if(row.cost&&(row.power<0||row.power>=MAX_POWERS||bot->GetPower(Powers(row.power))<row.cost))row.reason="resource";
    else if(bot->isMoving()&&info->CalcCastTime(bot)>0)row.reason="moving";
    else row.reason="ready"; // basic readiness, not a replacement for native CheckCast
    return row;
}
bool WardSnapshot4(ChatHandler* h,Player* bot,uint32 nonce)
{
    auto s=WD168::Capture(bot);auto guid=bot->GetGUID().GetCounter();
    h->PSendSysMessage("WDWS4|{}|{}|BEGIN|1|8|{}|{}|{}|{}|{}|{}|{}|{}|{}",guid,nonce,
        s.alive?1:0,s.mana,s.maxMana,s.summons[0].present?1:0,s.summons[1].present?1:0,s.summons[2].present?1:0,
        s.massWards,s.mimicPresent?1:0,s.viperPresent?1:0);
    for(uint32 key=1;key<=8;++key)
    {
        auto r=ReadWard4(bot,h->GetSession()->GetPlayer(),key);
        h->PSendSysMessage("WDWS4|{}|{}|ROW|{}|{}|{}|{}|{}|{}|{}|{}",guid,nonce,
            key,WDWS4::Base(key),r.spell,r.cost,r.power,r.cooldown,r.gcd,r.reason);
    }
    h->PSendSysMessage("WDWS4|{}|{}|END",guid,nonce);return true;
}
bool BotWardState4(ChatHandler* h,uint32 guid,uint32 nonce)
{
    auto* bot=BotPanelTarget(h,guid,nonce,false,"WDWS4");if(!bot)return true;
    return WardSnapshot4(h,bot,nonce);
}
struct WardReplay4 : DataMap::Base
{
    uint32 owner=0,nonce=0;
    std::chrono::steady_clock::time_point when;
};
bool BotWardCast4(ChatHandler* h,uint32 guid,uint32 nonce,uint32 key,uint32 expectedSpell)
{
    auto* bot=BotPanelTarget(h,guid,nonce,false,"WDWS4");if(!bot)return true;
    auto r=ReadWard4(bot,h->GetSession()->GetPlayer(),key);
    if(!WDWS4::Base(key)||!r.spell||r.spell!=expectedSpell||std::string_view(r.reason)!="ready")
    {
        h->PSendSysMessage("WDWS4|{}|{}|ACK|rejected|{}",guid,nonce,r.spell!=expectedSpell?"changed":r.reason);
        return WardSnapshot4(h,bot,nonce);
    }
    auto* replay=bot->CustomData.GetDefault<WardReplay4>("Reborn.MBWD4A.ManualCast");
    auto now=std::chrono::steady_clock::now();auto owner=h->GetSession()->GetPlayer()->GetGUID().GetCounter();
    if(replay->owner==owner&&replay->nonce==nonce&&now-replay->when<std::chrono::seconds(30))
    { h->PSendSysMessage("WDWS4|{}|{}|ERROR|duplicate",guid,nonce);return true; }
    replay->owner=owner;replay->nonce=nonce;replay->when=now;
    // Explicit owner command, not an automatic cast or triggered/free summon.
    SpellCastResult result=bot->CastSpell(bot,r.spell,TRIGGERED_NONE);
    h->PSendSysMessage("WDWS4|{}|{}|ACK|{}|{}",guid,nonce,result==SPELL_CAST_OK?"accepted":"native",uint32(result));
    return WardSnapshot4(h,bot,nonce);
}
