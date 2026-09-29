// WD67A lives inside WD5A and deliberately shares its revision / actions / lock rules.
uint32 const AEIds[27]={29744,6054,6047,7092,29309,29301,4004,31154,31344,31340,7157,6058,29928,30973,4533,31341,6045,31347,31348,6644,6046,6062,30889,31343,6053,31350,5333};
static uint32 const AESpells[8]={9003170,9003632,9003641,9003642,9003652,9003440,9003673,9003670};
uint32 AERank(uint32 mask,uint32 index)
{
    if(index==21) return (mask>>23)&3u;
    if(index>=22) return (mask>>(index+3))&1u;
    if(index==13) return (mask>>14)&3u;
    if(index>=14) return (mask>>(index+2))&1u;
    if(index==2) return (mask>>2)&3u;
    return (mask>>(index<2?index:index+1))&1u;
}
uint32 AESpent(uint32 mask)
{
    uint32 total=0;for(uint32 i=0;i<6;++i) total+=AERank(mask,i);return total;
}
// WD82A: threshold talents cannot bootstrap each other with circular pending points.
uint32 TEFoundation(uint32 mask)
{
    return AERank(mask,7)+AERank(mask,8)+AERank(mask,9)+AERank(mask,10)+AERank(mask,11)+AERank(mask,12)+AERank(mask,13);
}
uint32 TESpent(uint32 mask)
{
    return TEFoundation(mask)+AERank(mask,15)+AERank(mask,16)+AERank(mask,17)+AERank(mask,18)+AERank(mask,19)+AERank(mask,20)+AERank(mask,21)+AERank(mask,22)+AERank(mask,23)+AERank(mask,24)+AERank(mask,25)+AERank(mask,26);
}
bool AEValid(uint32 mask,uint32 level)
{
    if(mask>1073741823 || (AERank(mask,2)>2 || AERank(mask,21)>2) || AESpent(mask)>WD67Budget::AE(level) || TESpent(mask)>WD67Budget::TE(level)) return false;
    if(AERank(mask,14) && level<20) return false;
    // WD81A: a choice spends one TE, but neither choice counts toward its own prerequisites.
    if(AERank(mask,15) && AERank(mask,16)) return false;
    if((AERank(mask,15) || AERank(mask,16) || AERank(mask,17) || AERank(mask,18) || AERank(mask,19) || AERank(mask,20) || AERank(mask,21) || AERank(mask,22) || AERank(mask,23) || AERank(mask,24) || AERank(mask,25) || AERank(mask,26)) && TEFoundation(mask)<8) return false;
    // Authored OR paths. The other official parent nodes are not open in this batch.
    if(AERank(mask,1) && !AERank(mask,0) && !AERank(mask,5)) return false;
    if((AERank(mask,2) || AERank(mask,3)) && !AERank(mask,1)) return false;
    if(AERank(mask,4) && !AERank(mask,2) && !AERank(mask,3)) return false;
    if(AERank(mask,4) && level<16) return false; // donor SpellLevel 16; existing spell check
    if(AERank(mask,7) && (level<11 || !AERank(mask,5) || !AERank(mask,6) || WD67Budget::TE(level)<1)) return false;
    if(AERank(mask,12) && level<15) return false;
    if(AERank(mask,10) && level<15) return false;
    return level>=10 || mask==0;
}
bool AELoad(Player* p,State* s)
{
    s->modern=false;s->aeMasks.fill(0);
    int enrolled=WD67::Enrollment(p);
    if(enrolled<0) return false;
    if(!enrolled) return true;
    QueryResult q=CharacterDatabase.Query(
        "SELECT slot,node_id,node_rank FROM reborn_wd67_nodes WHERE guid={} UNION ALL SELECT 3,0,0",p->GetGUID().GetCounter());
    if(!q) return false;
    do
    {
        Field* f=q->Fetch();uint32 slot=f[0].Get<uint32>(),id=f[1].Get<uint32>(),rank=f[2].Get<uint32>();
        if(slot==3 && id==0 && rank==0) continue;
        if(slot>2 || !rank) return false;
        uint32 index=0;for(;index<27 && AEIds[index]!=id;++index) {}
        if(index==27 || rank>((index==2 || index==21)?2u:(index==13?3u:1u))) return false;
        s->aeMasks[slot]|=rank<<(index<3?index:(index>=22?index+3:(index>=14?index+2:index+1)));
    } while(q->NextRow());
    // Level decreases keep the saved layout, but do not grant an invalid active build.
    for(uint32 slot=0;slot<3;++slot) if(!AEValid(s->aeMasks[slot],80) ||
        ((s->aeMasks[slot]&1073741696) && s->specs[slot]!=0)) return false;
    if(s->builds) return false; // Legacy test nodes must not coexist after enrollment.
    s->modern=true;return true;
}
void AEApply(Player* p,State* s)
{
    if(!s->modern || !s->loaded) return;
    uint32 mask=s->specs[s->active]<3 && AEValid(s->aeMasks[s->active],p->GetLevel()) ? s->aeMasks[s->active] : 0;
    for(uint32 spell:{9003730u,9003731u,9003732u,9003720u,9003721u,9003511u,9003710u,9003711u,9003712u,9003520u,9003521u,9003522u,9003530u,9003531u,9003600u,9003601u,9003610u,9003611u,9003612u,9003690u,9003700u,9003701u,9003702u,9003703u}) if(!sSpellMgr->GetSpellInfo(spell)) return;
    for(auto const& rank:WD19A::BadJujuRanks) if(!sSpellMgr->GetSpellInfo(rank.spell)) return;
    for(auto const& rank:WD19A::HexfireRanks) if(!sSpellMgr->GetSpellInfo(rank.spell)) return;
    for(uint32 spell:AESpells) if(!sSpellMgr->GetSpellInfo(spell)) return;
    for(uint32 spell=9003680;spell<=9003689;++spell) if(!sSpellMgr->GetSpellInfo(spell)) return;
    bool wanted[8]={AERank(mask,0)>0,AERank(mask,1)>0,AERank(mask,2)>=1,
        AERank(mask,2)==2,AERank(mask,3)>0,AERank(mask,4)>0,AERank(mask,5)>0,AERank(mask,6)>0};
    for(uint32 i=0;i<8;++i)
    {
        if(!wanted[i])
        {
            if(p->HasSpell(AESpells[i])) p->removeSpell(AESpells[i],3,false);
            p->RemoveAurasDueToSpell(AESpells[i],p->GetGUID());
        }
        else if(!p->HasSpell(AESpells[i])) p->learnSpell(AESpells[i]);
    }
    // WD78B: talent ownership replaces legacy trainer recovery only for enrolled builds.
    uint32 const passives[2]={9003610,9003611};
    for(uint32 i=0;i<2;++i)
    {
        bool keep=AERank(mask,8+i)>0;
        if(!keep)
        {
            if(p->HasSpell(passives[i])) p->removeSpell(passives[i],3,false);
            p->RemoveAurasDueToSpell(passives[i],p->GetGUID());
        }
        else if(!p->HasSpell(passives[i])) p->learnSpell(passives[i]);
    }
    for(int i=7;i>=0;--i)
    {
        auto const& rank=WD19A::HexfireRanks[i];
        if((!AERank(mask,10) || p->GetLevel()<rank.level) && p->HasSpell(rank.spell))
            p->removeSpell(rank.spell,3,false);
    }
    for(auto const& rank:WD19A::HexfireRanks)
        if(AERank(mask,10) && p->GetLevel()>=rank.level && !p->HasSpell(rank.spell)) p->learnSpell(rank.spell);
    // WD79A: display ownership; the narrow registered modifier implements Dark Magic.
    if(AERank(mask,11)>0)
    {
        if(!p->HasSpell(9003690)) p->learnSpell(9003690);
    }
    else
    {
        if(p->HasSpell(9003690)) p->removeSpell(9003690,3,false);
        p->RemoveAurasDueToSpell(9003690,p->GetGUID());
    }
    // WD80A: the highest Coven rank is exclusive; free level passive is build-owned.
    uint32 const spells[17]={9003700,9003701,9003702,9003703,9003612,9003600,9003521,9003530,9003520,9003511,9003710,9003711,9003712,9003720,9003721,9003730,9003731};
    for(uint32 i=0;i<17;++i)
    {
        bool keep=i<3 ? AERank(mask,13)==i+1 : (i==3 ? AERank(mask,14)>0 : (i<10 ? AERank(mask,i+11)>0 : (i<12 ? AERank(mask,21)==i-9 : AERank(mask,i+10)>0)));
        if(!keep)
        {
            if(p->HasSpell(spells[i])) p->removeSpell(spells[i],3,false);
            p->RemoveAurasDueToSpell(spells[i],p->GetGUID());
        }
    }
    for(uint32 i=0;i<17;++i)
    {
        bool keep=i<3 ? AERank(mask,13)==i+1 : (i==3 ? AERank(mask,14)>0 : (i<10 ? AERank(mask,i+11)>0 : (i<12 ? AERank(mask,21)==i-9 : AERank(mask,i+10)>0)));
        if(keep && !p->HasSpell(spells[i])) p->learnSpell(spells[i]);
    }
    // Removes only this character's managed ward/idol and their owned effects.
    WD67ClearSummons(p,!wanted[0],!wanted[5]);
    WD68Clear(p,!wanted[6],!wanted[7]);
    uint32 const levels[10]={11,18,24,30,36,42,48,54,60,68};
    for(int i=9;i>=0;--i)
    {
        uint32 spell=9003680+uint32(i);
        bool keep=AERank(mask,7) && p->GetLevel()>=levels[i];
        if(!keep && p->HasSpell(spell)) p->removeSpell(spell,3,false);
    }
    for(uint32 i=0;i<10;++i)
        if(AERank(mask,7) && p->GetLevel()>=levels[i] && !p->HasSpell(9003680+i)) p->learnSpell(9003680+i);
}
bool AEJoin(ChatHandler* h,uint32 expected)
{
    Player* p=h->GetSession()->GetPlayer();if(!ProfileReady(p,true)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(!sConfigMgr->GetOption<bool>("RebornWD67.Enable",false) || s->modern || expected!=s->revision)
    { ProfileReply(p,"invalid");return true; }
    uint32 known=0;for(uint32 i=0;i<8;++i)
    {
        if(!sSpellMgr->GetSpellInfo(AESpells[i])) {ProfileReply(p,"spell");return true;}
        if(p->HasSpell(AESpells[i])) known|=1u<<i;
    }
    // This release is for newly created characters only; no legacy migration.
    for(uint32 spell:{9003730u,9003731u,9003732u,9003720u,9003721u,9003511u,9003710u,9003711u,9003712u,9003520u,9003521u,9003530u,9003600u,9003690u,9003612u,9003700u,9003701u,9003702u,9003703u}) if(p->HasSpell(spell)) known|=256u;
    if(p->HasSpell(9003610) || p->HasSpell(9003611)) known|=256u;
    for(auto const& rank:WD19A::HexfireRanks) if(p->HasSpell(rank.spell)) known|=256u;
    if(known || s->builds) {ProfileReply(p,"freshonly");return true;}
    QueryResult result=CharacterDatabase.Query("CALL reborn_wd67_join({},{},{})",
        p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),expected);
    uint32 code=result?result->Fetch()[0].Get<uint32>():0;
    if(!Load(p,s)) {s->loaded=false;ProfileReply(p,"database");return true;}
    Reply(p,"ok");ProfileReply(p,code==1?"ok":(code==2?"stale":"invalid"));return true;
}
bool AESave(ChatHandler* h,uint32 expected,uint32 slot,uint32 mask)
{
    Player* p=h->GetSession()->GetPlayer();if(!ProfileReady(p,true)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(!s->modern || slot>=s->unlocked || slot>2 || s->specs[slot]==3 || !AEValid(mask,p->GetLevel()) || ((mask&1073741696) && s->specs[slot]!=0))
    {ProfileReply(p,"invalid");return true;}
    if(expected!=s->revision) {ProfileReply(p,"stale");return true;}
    for(uint32 i=0;i<27;++i) if(AERank(mask,i)<AERank(s->aeMasks[slot],i))
    {ProfileReply(p,"resetrequired");return true;}
    QueryResult result=CharacterDatabase.Query("CALL reborn_wd67_save({},{},{},{},{},{})",
        p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),expected,slot,mask,uint32(p->GetLevel()));
    uint32 code=result?result->Fetch()[0].Get<uint32>():0;
    if(!Load(p,s)) {s->loaded=false;ProfileReply(p,"database");return true;}
    Reply(p,"ok");ProfileReply(p,code==1?"ok":(code==2?"stale":"invalid"));return true;
}
