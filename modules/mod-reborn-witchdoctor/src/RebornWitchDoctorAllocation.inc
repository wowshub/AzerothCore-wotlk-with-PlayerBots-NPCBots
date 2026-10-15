// WD67A lives inside WD5A and deliberately shares its revision / actions / lock rules.

static uint32 const AESpells[8]={9003170,9003632,9003641,9003642,9003652,9003440,9003673,9003670};
uint32 AERank(AEMask const& mask,uint32 index)
{ return index<WD139::Count?mask.ranks[index]:0; }
uint32 AESpent(AEMask const& mask)
{
    uint32 total=0;for(uint32 i=0;i<6;++i) total+=AERank(mask,i);return AERank(mask,116)+AERank(mask,117)+AERank(mask,108)+AERank(mask,109)+AERank(mask,110)+total+AERank(mask,39)+AERank(mask,40)+AERank(mask,41)+AERank(mask,46)+AERank(mask,47)+AERank(mask,48)+AERank(mask,58)+AERank(mask,59)+AERank(mask,60)+AERank(mask,63)+AERank(mask,64)+AERank(mask,65)+AERank(mask,66)+AERank(mask,67)+AERank(mask,68)+AERank(mask,69)+AERank(mask,70)+AERank(mask,71)+AERank(mask,72)+AERank(mask,73);
}
// WD82A: threshold talents cannot bootstrap each other with circular pending points.
uint32 TEFoundation(AEMask const& mask)
{
    return AERank(mask,7)+AERank(mask,8)+AERank(mask,9)+AERank(mask,10)+AERank(mask,11)+AERank(mask,12)+AERank(mask,13)+AERank(mask,29);
}
uint32 TESpent(AEMask const& mask)
{
    return AERank(mask,128)+AERank(mask,129)+AERank(mask,130)+AERank(mask,126)+AERank(mask,127)+AERank(mask,125)+AERank(mask,122)+AERank(mask,123)+AERank(mask,124)+AERank(mask,118)+AERank(mask,120)+AERank(mask,121)+AERank(mask,114)+AERank(mask,115)+TEFoundation(mask)+AERank(mask,15)+AERank(mask,16)+AERank(mask,17)+AERank(mask,18)+AERank(mask,19)+AERank(mask,20)+AERank(mask,21)+AERank(mask,22)+AERank(mask,23)+AERank(mask,24)+AERank(mask,25)+AERank(mask,26)+AERank(mask,27)+AERank(mask,28)+AERank(mask,30)+AERank(mask,33)+AERank(mask,34)+AERank(mask,35)+AERank(mask,36)+AERank(mask,37)+AERank(mask,38)+AERank(mask,42)+AERank(mask,43)+AERank(mask,44)+AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,56)+AERank(mask,57)+AERank(mask,61)+AERank(mask,62)+AERank(mask,77)+AERank(mask,78)+AERank(mask,79)+AERank(mask,80)+AERank(mask,81)+AERank(mask,82)+AERank(mask,83)+AERank(mask,84)+AERank(mask,85)+AERank(mask,86)+AERank(mask,87)+AERank(mask,88)+AERank(mask,89)+AERank(mask,90)+AERank(mask,91)+AERank(mask,92)+AERank(mask,93)+AERank(mask,94)+AERank(mask,95)+AERank(mask,96)+AERank(mask,97)+AERank(mask,99)+AERank(mask,100)+AERank(mask,101)+AERank(mask,102)+AERank(mask,103)+AERank(mask,105)+AERank(mask,106)+AERank(mask,107);
}
bool AESpecValid(AEMask const& mask,uint32 spec)
{ return mask.SpecValid(spec); }
bool AEValid(AEMask const& mask,uint32 level,uint32 testAE,uint32 testTE)
{
    if(AERank(mask,128) && (level<20 || !AERank(mask,120) || AERank(mask,114)+AERank(mask,115)+AERank(mask,118)+AERank(mask,120)+AERank(mask,121)+AERank(mask,122)+AERank(mask,123)+AERank(mask,124)+AERank(mask,125)+AERank(mask,126)+AERank(mask,127)<8))return false;
    if(AERank(mask,129) && !AERank(mask,128))return false;
    if(AERank(mask,130) && !AERank(mask,129))return false;
    if(AERank(mask,126) && AERank(mask,127))return false;
    if((AERank(mask,126)||AERank(mask,127)) && (level<20 || !AERank(mask,124)))return false;
    if(AERank(mask,125) && (level<20 || !AERank(mask,124))) return false;
    // WD146: the tier-eight gate counts only the existing Shadow foundation.
    if((AERank(mask,122)||AERank(mask,123)||AERank(mask,124)) && !AERank(mask,111)) return false;
    if(AERank(mask,122) && (level<15 || !AERank(mask,114))) return false;
    if(AERank(mask,123) && (level<15 || !AERank(mask,122))) return false;
    if(AERank(mask,124) && (level<20 || !AERank(mask,123) || AERank(mask,114)+AERank(mask,115)+AERank(mask,118)+AERank(mask,120)+AERank(mask,121)+AERank(mask,122)+AERank(mask,123)<8)) return false;
    // WD145: preserve the authored Eclipse dependency and free level-20 passive.
    if((AERank(mask,118)||AERank(mask,119)||AERank(mask,120)||AERank(mask,121)) && !AERank(mask,111)) return false;
    if(AERank(mask,118) && (level<15 || !AERank(mask,115))) return false;
    if(AERank(mask,119) && level<20) return false;
    if((AERank(mask,120)||AERank(mask,121)) && (level<15 || !AERank(mask,118))) return false;
    // WD144: two Shadow ranks and the authored Class choice group 681465.
    if((AERank(mask,114)||AERank(mask,115)) && (level<11 || !AERank(mask,111))) return false;
    if(AERank(mask,114) && !AERank(mask,112)) return false;
    if(AERank(mask,115) && !AERank(mask,113)) return false;
    if(AERank(mask,116) && AERank(mask,117)) return false;
    if((AERank(mask,116)||AERank(mask,117)) && (level<26 || !AERank(mask,66) || AERank(mask,0)+AERank(mask,1)+AERank(mask,2)+AERank(mask,3)+AERank(mask,4)+AERank(mask,5)+AERank(mask,39)+AERank(mask,60)+AERank(mask,66)<9)) return false;
    if((AERank(mask,111)||AERank(mask,112)||AERank(mask,113)) && level<10) return false;
    if((AERank(mask,112)||AERank(mask,113)) && !AERank(mask,111)) return false;
    // WD142: only pre-existing Class investments count toward the tier-24 gate.
    if((AERank(mask,108)||AERank(mask,109)||AERank(mask,110)) &&
       (level<56 || AESpent(mask)-AERank(mask,108)-AERank(mask,109)-AERank(mask,110)<24)) return false;
    if(AERank(mask,109) && (level<58 || !AERank(mask,108))) return false;
    if(AERank(mask,83)>2 || AERank(mask,77)>2 || AERank(mask,69)>2 || AERank(mask,58) || !mask.Valid() || testAE>100 || testTE>100 || (AERank(mask,2)>2 || AERank(mask,21)>2 || AERank(mask,29)>2 || AERank(mask,30)>2 || AERank(mask,39)>2 || AERank(mask,49)>2 || AERank(mask,50)>2 || AERank(mask,51)>2) || AESpent(mask)>WD67Budget::AE(level)+testAE || TESpent(mask)>WD67Budget::TE(level)+testTE) return false;
    // WD136 excludes every tier-23 node from its own prerequisite investment.
    if(AERank(mask,105) && (level<57 || !AERank(mask,74) || !AERank(mask,75) || !AERank(mask,92) || AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,56)+AERank(mask,57)+AERank(mask,61)+AERank(mask,62)+AERank(mask,77)+AERank(mask,78)+AERank(mask,79)+AERank(mask,80)+AERank(mask,81)+AERank(mask,82)+AERank(mask,83)+AERank(mask,84)+AERank(mask,85)+AERank(mask,86)+AERank(mask,87)+AERank(mask,88)+AERank(mask,89)+AERank(mask,90)+AERank(mask,91)+AERank(mask,92)+AERank(mask,93)+AERank(mask,94)+AERank(mask,95)+AERank(mask,96)+AERank(mask,97)+AERank(mask,99)+AERank(mask,100)+AERank(mask,101)-AERank(mask,101)<23)) return false;
    if(AERank(mask,107) && (level<24 || !AERank(mask,101))) return false;
    if(AERank(mask,106) && (level<59 || !AERank(mask,105))) return false;
    uint32 const brewing134=AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,56)+AERank(mask,57)+AERank(mask,61)+AERank(mask,62)+AERank(mask,77)+AERank(mask,78)+AERank(mask,79)+AERank(mask,80)+AERank(mask,81)+AERank(mask,82)+AERank(mask,83)+AERank(mask,84)+AERank(mask,85)+AERank(mask,86)+AERank(mask,87)+AERank(mask,88)+AERank(mask,89)+AERank(mask,90)+AERank(mask,91)+AERank(mask,92)+AERank(mask,93)+AERank(mask,94)+AERank(mask,95)+AERank(mask,96)+AERank(mask,97)+AERank(mask,99)+AERank(mask,100)+AERank(mask,101);
    if((AERank(mask,102)||AERank(mask,103)) && (level<57 || !AERank(mask,74) || brewing134<23)) return false;
    if(AERank(mask,102) && !AERank(mask,92) && !AERank(mask,79) && !AERank(mask,80)) return false;
    if(AERank(mask,103) && !AERank(mask,102)) return false;
    uint32 const brewing133=AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,56)+AERank(mask,57)+AERank(mask,61)+AERank(mask,62)+AERank(mask,77)+AERank(mask,78)+AERank(mask,79)+AERank(mask,80)+AERank(mask,81)+AERank(mask,82)+AERank(mask,83)+AERank(mask,84)+AERank(mask,85)+AERank(mask,86)+AERank(mask,87)+AERank(mask,88)+AERank(mask,89)+AERank(mask,90)+AERank(mask,91)+AERank(mask,92)+AERank(mask,93)+AERank(mask,94)+AERank(mask,95)+AERank(mask,96)+AERank(mask,97)+AERank(mask,99)+AERank(mask,100);
    if((AERank(mask,99)||AERank(mask,100)||AERank(mask,101)) && (level<10 || !AERank(mask,74) || AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8)) return false;
    if(AERank(mask,99) && (level<16 || !AERank(mask,85))) return false;
    if(AERank(mask,100) && !AERank(mask,97) && !AERank(mask,61) && !AERank(mask,62)) return false;
    if(AERank(mask,101) && (!AERank(mask,100) || brewing133<23)) return false;
    if(AERank(mask,104) && (level<50 || !AERank(mask,98))) return false;
    if(AERank(mask,98) && (level<40 || !AERank(mask,54))) return false;
    if((AERank(mask,96) || AERank(mask,97)) && (level<10 || !AERank(mask,74) || !AERank(mask,75) ||
        AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8)) return false;
    if(AERank(mask,96) && !AERank(mask,85)) return false;
    if(AERank(mask,97) && !AERank(mask,91)) return false;
    if((AERank(mask,93) || AERank(mask,94) || AERank(mask,95)) &&
       (level<10 || !AERank(mask,74) || AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8)) return false;
    if(AERank(mask,93) && (level<29 || (!AERank(mask,81) && !AERank(mask,78)))) return false;
    if(AERank(mask,94) && !AERank(mask,81)) return false;
    if(AERank(mask,95) && AERank(mask,56)) return false;
    if(AERank(mask,95) && !AERank(mask,78) && !AERank(mask,85)) return false;
    if((AERank(mask,91) || AERank(mask,92)) && (level<10 || !AERank(mask,74) ||
       AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8)) return false;
    if(AERank(mask,89) && AERank(mask,90)) return false;
    if((AERank(mask,89) || AERank(mask,90)) &&
       AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8) return false;
    if((AERank(mask,88) || AERank(mask,89) || AERank(mask,90)) && !AERank(mask,74)) return false;
    if(AERank(mask,79) && AERank(mask,80)) return false; // WD122 authored choice group 706545.
    if(AERank(mask,81) && level<17) return false; // WD123 first Splash rank.
    if((AERank(mask,82) || AERank(mask,83) || AERank(mask,84) || AERank(mask,85) || AERank(mask,86) || AERank(mask,87)) &&
       AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8) return false;
    // WD121: tier-eight Brewing talents cannot bootstrap their own foundation.
    if((AERank(mask,77) || AERank(mask,78) || AERank(mask,79) || AERank(mask,80)) && AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8) return false;
    if(AERank(mask,85) && !AERank(mask,74) && !AERank(mask,0)) return false;
    if((AERank(mask,86) || AERank(mask,87)) && level<10) return false;
    // WD120: free Brewing nodes; authored prerequisites are alternative paths.
    if((AERank(mask,75) || AERank(mask,76)) && !AERank(mask,74) && !AERank(mask,0)) return false;
    if(AERank(mask,76) && level<14) return false;
    if((AERank(mask,71) || AERank(mask,72) || AERank(mask,73)) && level<26) return false;
    if((AERank(mask,72) || AERank(mask,73)) && !AERank(mask,71)) return false;
    if(AERank(mask,72) && AERank(mask,73)) return false;
    if(AERank(mask,70) && level<30) return false;
    if((AERank(mask,52) && level<20) || (AERank(mask,54) && level<30)) return false;
    // Both tier-eight nodes exclude themselves and one another from foundation.
    if((AERank(mask,56) || AERank(mask,57)) && AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8) return false;
    if((AERank(mask,56) && level<16) || (AERank(mask,57) && level<30)) return false;
    // WD110/112: class tier-nine and Brewing tier-eight are independent budgets.
    if((AERank(mask,58) || AERank(mask,59)) && AESpent(mask)-AERank(mask,40)-AERank(mask,41)-AERank(mask,46)-AERank(mask,47)-AERank(mask,48)-AERank(mask,58)-AERank(mask,59)-AERank(mask,63)-AERank(mask,64)-AERank(mask,65)-AERank(mask,67)-AERank(mask,68)-AERank(mask,69)-AERank(mask,70)-AERank(mask,71)-AERank(mask,72)-AERank(mask,73)<9) return false;
    if(AERank(mask,58) && level<58) return false;
    if(AERank(mask,59) && level<30) return false;
    if((AERank(mask,61) || AERank(mask,62)) && level<31) return false;
    if(AERank(mask,61) && AERank(mask,62)) return false;
    if((AERank(mask,61) || AERank(mask,62)) && AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8) return false;
    // WD113: tier-nine Class nodes cannot bootstrap one another.
    if((AERank(mask,63) || AERank(mask,64) || AERank(mask,65) || AERank(mask,67) || AERank(mask,68) || AERank(mask,69) || AERank(mask,70) || AERank(mask,71) || AERank(mask,72) || AERank(mask,73)) &&
       AERank(mask,0)+AERank(mask,1)+AERank(mask,2)+AERank(mask,3)+AERank(mask,4)+AERank(mask,5)+AERank(mask,39)+AERank(mask,60)+AERank(mask,66)<9) return false;
    if(AERank(mask,64) && AERank(mask,48)) return false; // Hir'eek / Dark Mojo choice.
    // WD100: the five tier-9 Class talents cannot count themselves toward nine AE.
    if((AERank(mask,40) || AERank(mask,41) || AERank(mask,46) || AERank(mask,47) || AERank(mask,48)) && AESpent(mask)-AERank(mask,40)-AERank(mask,41)-AERank(mask,46)-AERank(mask,47)-AERank(mask,48)-AERank(mask,58)-AERank(mask,59)-AERank(mask,63)-AERank(mask,64)-AERank(mask,65)-AERank(mask,67)-AERank(mask,68)-AERank(mask,69)-AERank(mask,70)-AERank(mask,71)-AERank(mask,72)-AERank(mask,73)<9) return false;
    if((AERank(mask,47) && level<28) || (AERank(mask,48) && level<32)) return false;
    if(AERank(mask,40) && level<28) return false;
    if(AERank(mask,45) && level<50) return false;
    if(AERank(mask,42) && (level<59 || TEFoundation(mask)<8)) return false;
    if(AERank(mask,44) && level<59) return false;
    if((AERank(mask,43) || AERank(mask,44)) && (level<57 || TESpent(mask)-AERank(mask,34)-AERank(mask,35)-AERank(mask,36)-AERank(mask,37)-AERank(mask,43)-AERank(mask,44)<23)) return false;
    if(AERank(mask,38) && (level<27 || TEFoundation(mask)<8)) return false;
    if(AERank(mask,32) && level<30) return false;
    if(AERank(mask,33) && level<33) return false;
    if((AERank(mask,36) || AERank(mask,37)) && (level<57 || TESpent(mask)-AERank(mask,34)-AERank(mask,35)-AERank(mask,36)-AERank(mask,37)-AERank(mask,43)-AERank(mask,44)<23)) return false;
    if(AERank(mask,37) && !AERank(mask,36)) return false;
    if(AERank(mask,35) && TESpent(mask)-AERank(mask,34)-AERank(mask,35)-AERank(mask,36)-AERank(mask,37)-AERank(mask,43)-AERank(mask,44)<23) return false;
    if(AERank(mask,34) && TESpent(mask)-AERank(mask,34)-AERank(mask,35)-AERank(mask,36)-AERank(mask,37)-AERank(mask,43)-AERank(mask,44)<23) return false;
    if(AERank(mask,31) && level<40) return false;
    if(AERank(mask,14) && level<20) return false;
    // WD81A: a choice spends one TE, but neither choice counts toward its own prerequisites.
    if(AERank(mask,15) && AERank(mask,16)) return false;
    if((AERank(mask,15) || AERank(mask,16) || AERank(mask,17) || AERank(mask,18) || AERank(mask,19) || AERank(mask,20) || AERank(mask,21) || AERank(mask,22) || AERank(mask,23) || AERank(mask,24) || AERank(mask,25) || AERank(mask,26) || AERank(mask,27) || AERank(mask,28) || AERank(mask,30) || AERank(mask,33)) && TEFoundation(mask)<8) return false;
    // Authored OR paths. The other official parent nodes are not open in this batch.
    if(AERank(mask,1) && !AERank(mask,0) && !AERank(mask,5)) return false;
    if((AERank(mask,2) || AERank(mask,3)) && !AERank(mask,1)) return false;
    if(AERank(mask,4) && !AERank(mask,2) && !AERank(mask,3)) return false;
    if(AERank(mask,4) && level<16) return false; // donor SpellLevel 16; existing spell check
    if(AERank(mask,7) && (level<11 || !AERank(mask,5) || !AERank(mask,6) || WD67Budget::TE(level)<1)) return false;
    if(AERank(mask,12) && level<15) return false;
    if(AERank(mask,10) && level<15) return false;
    return level>=10 || mask.Empty();
}
bool AELoad(Player* p,State* s)
{
    s->modern=false;s->layoutMismatch=false;s->aeMasks.fill(AEMask{});s->testAE=0;s->testTE=0;
    int enrolled=WD67::Enrollment(p);
    if(enrolled<0) return false;
    if(!enrolled) return true;
    QueryResult allowance=CharacterDatabase.Query("SELECT COALESCE(MAX(extra_ae),0),COALESCE(MAX(extra_te),0) FROM reborn_wd95_test_points WHERE guid={} AND account={}",p->GetGUID().GetCounter(),p->GetSession()->GetAccountId());
    if(!allowance) return false;
    s->testAE=allowance->Fetch()[0].Get<uint32>();s->testTE=allowance->Fetch()[1].Get<uint32>();
    if(s->testAE>100 || s->testTE>100) return false;

    QueryResult q=CharacterDatabase.Query(
        "SELECT slot,node_id,node_rank FROM reborn_wd67_nodes WHERE guid={} UNION ALL SELECT 3,0,0",p->GetGUID().GetCounter());
    if(!q) return false;
    do
    {
        Field* f=q->Fetch();uint32 slot=f[0].Get<uint32>(),id=f[1].Get<uint32>(),rank=f[2].Get<uint32>();
        if(slot==3 && id==0 && rank==0) continue;
        if(slot>2 || !rank) return false;
        uint32 index=0;for(;index<AEIdCount && AEIds[index]!=id;++index) {}
        if(index==AEIdCount) {s->layoutMismatch=true;return false;}
        if(rank>WD139::Nodes[index].maximum || s->aeMasks[slot].ranks[index]) return false;
        s->aeMasks[slot].ranks[index]=rank;
    } while(q->NextRow());
    // Level decreases keep the saved layout, but do not grant an invalid active build.
    for(uint32 slot=0;slot<3;++slot) if(!AEValid(s->aeMasks[slot],80,s->testAE,s->testTE) ||
        !AESpecValid(s->aeMasks[slot],s->specs[slot])) return false;
    if(s->builds) return false; // Legacy test nodes must not coexist after enrollment.
    s->modern=true;return true;
}
void AEApply(Player* p,State* s)
{
    if(!s->modern || !s->loaded) return;
    AEMask mask=AESpecValid(s->aeMasks[s->active],s->specs[s->active]) && AEValid(s->aeMasks[s->active],p->GetLevel(),s->testAE,s->testTE) ? s->aeMasks[s->active] : AEMask{};
    for(uint32 spell:{9003861u,9003862u,9003863u,9003859u,9003860u,9003857u,9003858u,9003855u,9003856u,9003853u,9003854u,9003850u,9003851u,9003852u,9003430u,9003452u,9003840u,9003841u,9003842u,9003843u,9003830u,9003470u,9003481u,9003630u,9003631u,9003480u,9003620u,9003621u,9003622u,9003623u,9003624u,9003625u,9003660u,9003663u,9003432u,9003433u,9003640u,9003800u,9003801u,9003810u,9003650u,9003651u,9003633u,9003653u,9003790u,9003780u,9003781u,9003782u,9003770u,9003760u,9003761u,9003762u,9003763u,9003764u,9003765u,9003750u,9003751u,9003752u,9003753u,9003754u,9003740u,9003741u,9003730u,9003731u,9003732u,9003720u,9003721u,9003511u,9003710u,9003711u,9003712u,9003520u,9003521u,9003522u,9003530u,9003531u,9003600u,9003601u,9003610u,9003611u,9003612u,9003690u,9003700u,9003701u,9003702u,9003703u}) if(!sSpellMgr->GetSpellInfo(spell)) return;
    for(uint32 id : {9004000u,9004001u,9004002u,9004003u,9004004u,9004005u,9004006u,9004010u,9004011u,9004012u,9004020u,9004021u,9004022u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 id : {9004030u,9004031u,9004032u,9004033u,9004034u,9004035u,9004036u,9004040u,9004041u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 id=9004080;id<=9004084;++id)if(!sSpellMgr->GetSpellInfo(id))return;
    for(uint32 id=9004070;id<=9004073;++id)if(!sSpellMgr->GetSpellInfo(id))return;
    for(uint32 id:{9004060u,9004061u}) if(!sSpellMgr->GetSpellInfo(id))return;
    for(uint32 id=9003990;id<=9003995;++id) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 id:{264u,266u,5011u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 id=9003967;id<=9003989;++id) if(id!=9003979 && !sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 id=9003962;id<=9003966;++id) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(auto const& rank:WD19A::BadJujuRanks) if(!sSpellMgr->GetSpellInfo(rank.spell)) return;
    for(auto const& rank:WD19A::HexfireRanks) if(!sSpellMgr->GetSpellInfo(rank.spell)) return;
    for(uint32 spell:AESpells) if(!sSpellMgr->GetSpellInfo(spell)) return;
    for(uint32 spell=9003680;spell<=9003689;++spell) if(!sSpellMgr->GetSpellInfo(spell)) return;
    for(uint32 id:{9003864u,9003865u,9003866u,9003867u,9003870u,9003871u,9003872u,9003873u,9003874u,9003875u,9003876u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 id:{9003877u,9003878u,9003879u,9003880u,9003881u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 id:{9003901u,9003902u,9003903u,9003904u,9003905u,9003906u,9003907u,9003908u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    if(!sSpellMgr->GetSpellInfo(9003910) || !sSpellMgr->GetSpellInfo(9003911)) return;
    for(uint32 id:{9003912u,9003913u,9003914u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    // WD128: remove old choice first; only the active saved build grants passives.
    for(uint32 i=0;i<3;++i) if(!AERank(mask,88+i))
    {
        p->RemoveAurasDueToSpell(9003912+i,p->GetGUID());
        if(p->HasSpell(9003912+i)) p->removeSpell(9003912+i,3,false);
    }
    for(uint32 i=0;i<3;++i) if(AERank(mask,88+i))
    {
        if(!p->HasSpell(9003912+i)) p->learnSpell(9003912+i);
        if(!p->HasAura(9003912+i)) p->CastSpell(p,9003912+i,true);
    }
    // WD129: prepare Bloodthistle only through the active saved build.
    for(uint32 id:{9003915u,9003916u,9003917u,9003918u,9003919u,9003920u,9003921u})
        if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 i=0;i<2;++i)
    {
        uint32 const id=i?9003920u:9003915u;
        if(!AERank(mask,91+i))
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(i) p->RemoveAurasDueToSpell(9003921,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
        else
        {
            if(!p->HasSpell(id)) p->learnSpell(id);
            if(i && !p->HasAura(id,p->GetGUID())) p->CastSpell(p,id,true);
        }
    }
    // WD130: highest eligible Beam rank, no free trainer or stale-slot ownership.
    uint32 beam=0;uint32 const beamLevels[7]={29,36,44,52,60,68,76};
    for(uint32 id=9003922;id<=9003932;++id) if(!sSpellMgr->GetSpellInfo(id)) return;
    if(AERank(mask,93)) for(uint32 i=0;i<7;++i) if(p->GetLevel()>=beamLevels[i]) beam=9003922+i;
    if(!beam) { if(Spell* ch=p->GetCurrentSpell(CURRENT_CHANNELED_SPELL)) if(ch->GetSpellInfo()->Id>=9003922 && ch->GetSpellInfo()->Id<=9003928) p->InterruptSpell(CURRENT_CHANNELED_SPELL); p->RemoveAurasDueToSpell(9003929); }
    for(uint32 id=9003922;id<=9003928;++id) if(id!=beam && p->HasSpell(id)) p->removeSpell(id,3,false);
    if(beam && !p->HasSpell(beam)) p->learnSpell(beam);
    for(uint32 i=0;i<2;++i)
    {
        uint32 id=9003930+i;
        if(!AERank(mask,94+i)) { p->RemoveAurasDueToSpell(id); if(p->HasSpell(id)) p->removeSpell(id,3,false); }
        else { if(!p->HasSpell(id)) p->learnSpell(id); if(!p->HasAura(id)) p->CastSpell(p,id,true); }
    }
    for(uint32 id=9003933;id<=9003936;++id) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 i=0;i<2;++i)
    {
        uint32 id=9003933+i;
        if(!AERank(mask,96+i)) { p->RemoveAurasDueToSpell(id,p->GetGUID()); if(p->HasSpell(id)) p->removeSpell(id,3,false); }
        else if(!p->HasSpell(id)) p->learnSpell(id);
    }
    for(uint32 id:{9003937u,9003938u,9003939u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    if(AERank(mask,98)) { if(!p->HasSpell(9003937)) p->learnSpell(9003937); if(!p->HasAura(9003937,p->GetGUID())) p->CastSpell(p,9003937,true); }
    else { p->RemoveAurasDueToSpell(9003937,p->GetGUID()); if(p->HasSpell(9003937)) p->removeSpell(9003937,3,false); }
    WD145Bridge::Apply(p,AERank(mask,118),AERank(mask,119),AERank(mask,120),AERank(mask,121));
    WD144Bridge::Apply(p,AERank(mask,114),AERank(mask,115),AERank(mask,116),AERank(mask,117));
    WD143Bridge::Apply(p,AERank(mask,111),AERank(mask,112),AERank(mask,113));
    WD146Bridge::Apply(p,AERank(mask,122),AERank(mask,123),AERank(mask,124));
    WD148Bridge::Apply(p,AERank(mask,125));
    WD149Bridge::Apply(p,AERank(mask,126),AERank(mask,127));
    WD150Bridge::Apply(p,AERank(mask,128),AERank(mask,129),AERank(mask,130));
    for(uint32 i=0;i<3;++i)
    {
        uint32 spell= i==0?9003962u:(i==1?9003964u:9003965u);
        if(AERank(mask,108+i)) { if(!p->HasSpell(spell)) p->learnSpell(spell); }
        else { if(i==0) WD142Bridge::Clear(p);
               p->RemoveAurasDueToSpell(spell,p->GetGUID()); if(p->HasSpell(spell)) p->removeSpell(spell,3,false); }
    }
    if(AERank(mask,107)) { if(!p->HasSpell(9003958)) p->learnSpell(9003958); if(!p->HasSpell(9003959)) p->learnSpell(9003959); }
    else { for(uint32 id:{9003958u,9003959u,9003960u,9003961u}) { p->RemoveAurasDueToSpell(id,p->GetGUID()); if(p->HasSpell(id)) p->removeSpell(id,3,false); } }
    if(AERank(mask,106)) { if(!p->HasSpell(9003957)) p->learnSpell(9003957); }
    else { p->RemoveAurasDueToSpell(9003957,p->GetGUID()); if(p->HasSpell(9003957)) p->removeSpell(9003957,3,false); }
    if(AERank(mask,105)) { if(!p->HasSpell(9003954)) p->learnSpell(9003954); if(!p->HasAura(9003954,p->GetGUID())) p->CastSpell(p,9003954,true); }
    else { p->RemoveAurasDueToSpell(9003954,p->GetGUID()); p->RemoveAurasDueToSpell(9003955,p->GetGUID()); if(p->HasSpell(9003954)) p->removeSpell(9003954,3,false); }
    if(AERank(mask,104)) { if(!p->HasSpell(9003953)) p->learnSpell(9003953); }
    else if(p->HasSpell(9003953)) p->removeSpell(9003953,3,false);
    for(uint32 i=0;i<2;++i)
    {
        uint32 id=i?9003950:9003947;

        if(AERank(mask,102+i)) { if(!p->HasSpell(id)) p->learnSpell(id); if(i && !p->HasAura(id,p->GetGUID())) p->CastSpell(p,id,true); }
        else { p->RemoveAurasDueToSpell(id,p->GetGUID()); if(p->HasSpell(id)) p->removeSpell(id,3,false); }
    }
    uint32 const new133[3]={9003940,9003942,9003944};
    for(uint32 i=0;i<3;++i)
    {
        uint32 id=new133[i];
        if(AERank(mask,99+i)) { if(!p->HasSpell(id)) p->learnSpell(id); }
        else { p->RemoveAurasDueToSpell(id,p->GetGUID()); if(p->HasSpell(id)) p->removeSpell(id,3,false); }
    }
    uint32 const fresh=AERank(mask,77);
    bool const cadenceChanged=p->HasAura(9003881)!=(AERank(mask,80)>0);
    uint32 const brewingPassives[5]={9003877,9003878,9003879,9003880,9003881};
    bool const brewingWanted[5]={fresh==1,fresh==2,AERank(mask,78)>0,AERank(mask,79)>0,AERank(mask,80)>0};
    // Remove lower ranks first; repeated activation restores a missing passive aura.
    for(uint32 i=0;i<5;++i) if(!brewingWanted[i])
    {
        p->RemoveAurasDueToSpell(brewingPassives[i],p->GetGUID());
        if(p->HasSpell(brewingPassives[i])) p->removeSpell(brewingPassives[i],3,false);
    }
    for(uint32 i=0;i<5;++i) if(brewingWanted[i])
    {
        if(!p->HasSpell(brewingPassives[i])) p->learnSpell(brewingPassives[i]);
        if(!p->HasAura(brewingPassives[i])) p->CastSpell(p,brewingPassives[i],true);
    }
    // WD124: saved-build-only native passives. Rank 2 supersedes rank 1.
    uint32 const support[4]={9003897,9003898,9003899,9003900};
    bool const supportWanted[4]={AERank(mask,82)>0,AERank(mask,83)==1,AERank(mask,83)==2,AERank(mask,84)>0};
    for(uint32 id:support) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 i=0;i<4;++i) if(!supportWanted[i])
    {
        p->RemoveAurasDueToSpell(support[i],p->GetGUID());
        if(p->HasSpell(support[i])) p->removeSpell(support[i],3,false);
    }
    for(uint32 i=0;i<4;++i) if(supportWanted[i])
    {
        if(!p->HasSpell(support[i])) p->learnSpell(support[i]);
        if(!p->HasAura(support[i])) p->CastSpell(p,support[i],true);
    }
    // WD122: update an already prepared ingredient on a saved-build cadence change.
    // Start a fresh interval, without an extra heal or reapplying the preparation.
    if(cadenceChanged)
        if(AuraEffect* effect=p->GetAuraEffect(9003865,EFFECT_0,p->GetGUID()))
        {
            effect->CalculatePeriodic(p);
            effect->SetPeriodicTimer(effect->GetAmplitude());
        }
    // WD120: preparation is an active saved-build ability, never granted by preview.
    for(uint32 i=0;i<2;++i)
    {
        uint32 id=9003864+i;
        if(!AERank(mask,74+i))
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
        else
        {
            if(!p->HasSpell(id)) p->learnSpell(id);
            // Only the passive restores automatically. The player prepares the ingredient.
            if(i==0 && !p->HasAura(id)) p->CastSpell(p,id,true);
        }
    }
    // WD125: Fish Oil is the official level-16 class ability; Frog Bones is a saved talent.
    bool const fish=p->GetLevel()>=16 || AERank(mask,88)>0;
    bool const bones=AERank(mask,85)>0;
    for(uint32 id:{WD125A::FishPrep,WD125A::BonesPrep})
    {
        bool enabled=id==WD125A::FishPrep?fish:bones;
        if(!enabled)
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
        else if(!p->HasSpell(id)) p->learnSpell(id);
    }
    // WD126: native eight-second dodge/size aura, owned by the active saved build.
    if(!AERank(mask,86))
    {
        if(p->HasSpell(9003910)) p->removeSpell(9003910,3,false);
    }
    else if(!p->HasSpell(9003910)) p->learnSpell(9003910);
    // WD127: saved-build passive; never retain its aura after a profile switch.
    if(!AERank(mask,87))
    {
        p->RemoveAurasDueToSpell(9003911,p->GetGUID());
        if(p->HasSpell(9003911)) p->removeSpell(9003911,3,false);
    }
    else
    {
        if(!p->HasSpell(9003911)) p->learnSpell(9003911);
        if(!p->HasAura(9003911)) p->CastSpell(p,9003911,true);
    }
    WD128A::Normalize(p); // Trim only after removing ineligible preparations.
    uint32 toss=0;
    uint32 const tossLevels[7]={14,22,30,38,46,54,60};
    if(AERank(mask,76)) for(uint32 i=0;i<7;++i) if(p->GetLevel()>=tossLevels[i]) toss=9003870+i;
    for(uint32 id=9003870;id<=9003876;++id) if(id!=toss && p->HasSpell(id)) p->removeSpell(id,3,false);
    if(toss && !p->HasSpell(toss)) p->learnSpell(toss);
    // WD123: one saved talent owns the highest eligible Splash rank only.
    for(uint32 id=9003890;id<=9003896;++id) if(!sSpellMgr->GetSpellInfo(id)) return;
    uint32 splash=0;
    uint32 const splashLevels[7]={17,22,28,36,44,50,58};
    if(AERank(mask,81)) for(uint32 i=0;i<7;++i) if(p->GetLevel()>=splashLevels[i]) splash=9003890+i;
    for(uint32 id=9003890;id<=9003896;++id) if(id!=splash && p->HasSpell(id)) p->removeSpell(id,3,false);
    if(splash && !p->HasSpell(splash)) p->learnSpell(splash);
    // WD97B: only the highest allocated Juju rank; all three passives are build-owned.
    uint32 const classSpells[4]={9003650,9003651,9003633,9003653};
    bool const classWanted[4]={AERank(mask,39)==1,AERank(mask,39)==2,AERank(mask,40)>0,AERank(mask,41)>0};
    for(uint32 i=0;i<4;++i) if(!classWanted[i])
    {
        if(p->HasSpell(classSpells[i])) p->removeSpell(classSpells[i],3,false);
        p->RemoveAurasDueToSpell(classSpells[i],p->GetGUID());
    }
    for(uint32 i=0;i<4;++i) if(classWanted[i] && !p->HasSpell(classSpells[i])) p->learnSpell(classSpells[i]);
    uint32 const endSpells[3]={9003800,9003801,9003810};
    for(uint32 i=0;i<3;++i)
    {
        if(!AERank(mask,42+i))
        {
            if(p->HasSpell(endSpells[i])) p->removeSpell(endSpells[i],3,false);
            p->RemoveAurasDueToSpell(endSpells[i],p->GetGUID());
            if(i==1) p->RemoveAurasDueToSpell(9003802,p->GetGUID());
            if(i==2) for(uint32 child:{9003811u,9003812u}) p->RemoveAurasDueToSpell(child,p->GetGUID());
        }
        else if(!p->HasSpell(endSpells[i])) p->learnSpell(endSpells[i]);
    }
    if(!AERank(mask,45))
    {
        p->RemoveAurasDueToSpell(9003821,p->GetGUID());
        p->RemoveAurasDueToSpell(9003820,p->GetGUID());
        for(uint32 id:{9003820u,9003822u}) if(p->HasSpell(id)) p->removeSpell(id,3,false);
    }
    else
    {
        if(!p->HasSpell(9003820)) p->learnSpell(9003820);
        if(!p->HasSpell(9003822)) p->learnSpell(9003822,true);
    }
    // WD100: all three Class talents are owned by the active saved build.
    uint32 const idolTalents[3]={9003660,9003432,9003640};
    for(uint32 i=0;i<3;++i)
    {
        if(!AERank(mask,46+i))
        {
            if(p->HasSpell(idolTalents[i])) p->removeSpell(idolTalents[i],3,false);
            p->RemoveAurasDueToSpell(idolTalents[i],p->GetGUID());
            if(i==0) p->RemoveAurasDueToSpell(9003663,p->GetGUID());
        }
        else if(!p->HasSpell(idolTalents[i])) p->learnSpell(idolTalents[i]);
    }
    // WD115A: retire the duplicate Class spell before granting the shared highest rank.
    p->RemoveAurasDueToSpell(9003854,p->GetGUID());
    if(p->HasSpell(9003854)) p->removeSpell(9003854,3,false);
    // Saved Brewing ranks and the Class rank share one Potent Mixes family.
    // Remove highest first, without lower-rank relearning, before granting desired rank.
    for(uint32 family=0;family<3;++family)
    {
        uint32 rank=AERank(mask,49+family);
        // WD115A: both progression nodes reference the same upstream rank family.
        if(family==0) rank=std::max(rank,AERank(mask,67));
        for(int tier=2;tier>=1;--tier)
        {
            uint32 spell=9003620+2*family+uint32(tier-1);
            if(rank!=uint32(tier))
            {
                if(p->HasSpell(spell)) p->removeSpell(spell,3,false);
                p->RemoveAurasDueToSpell(spell,p->GetGUID());
            }
        }
        if(rank)
        {
            uint32 spell=9003620+2*family+rank-1;
            if(!p->HasSpell(spell)) p->learnSpell(spell);
            if(family==0 && !p->HasAura(spell)) p->CastSpell(p,spell,true);
        }
    }
    // WD105A: three single-rank Brewing passives; only saved active ownership applies.
    uint32 const sustain[3]={9003630,9003631,9003480};
    for(uint32 i=0;i<3;++i)
    {
        if(!AERank(mask,52+i))
        {
            if(p->HasSpell(sustain[i])) p->removeSpell(sustain[i],3,false);
            p->RemoveAurasDueToSpell(sustain[i],p->GetGUID());
        }
        else if(!p->HasSpell(sustain[i])) p->learnSpell(sustain[i]);
    }
    // WD109: saved active ownership, including old test-trainer passives.
    uint32 const brewing109[3]={9003830,9003470,9003481};
    for(uint32 i=0;i<3;++i)
    {
        if(!AERank(mask,55+i))
        {
            if(p->HasSpell(brewing109[i])) p->removeSpell(brewing109[i],3,false);
            p->RemoveAurasDueToSpell(brewing109[i],p->GetGUID());
        }
        else if(!p->HasSpell(brewing109[i])) p->learnSpell(brewing109[i]);
    }
    uint32 const added112[5]={9003430,9003452,9003840,9003841,9003843};
    for(uint32 i=1;i<5;++i)
    {
        if(!AERank(mask,58+i))
        {
            if(p->HasSpell(added112[i])) p->removeSpell(added112[i],3,false);
            p->RemoveAurasDueToSpell(added112[i],p->GetGUID());
        }
        else if(!p->HasSpell(added112[i])) p->learnSpell(added112[i]);
    }
    if(!AERank(mask,60)) WD111ClearExtra(p);
    uint32 const class113[3]={9003850,9003851,9003852};
    for(uint32 i=0;i<3;++i)
    {
        if(!AERank(mask,63+i))
        {
            if(p->HasSpell(class113[i])) p->removeSpell(class113[i],3,false);
            p->RemoveAurasDueToSpell(class113[i],p->GetGUID());
        }
        else
        {
            if(!p->HasSpell(class113[i])) p->learnSpell(class113[i]);
            // Recover the permanent native modifier when restoring an active saved build.
            if(!p->HasAura(class113[i])) p->CastSpell(p,class113[i],true);
        }
    }
    for(uint32 i=0;i<1;++i)
    {
        uint32 const id=9003853+i;
        if(!AERank(mask,66+i))
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
        else
        {
            if(!p->HasSpell(id)) p->learnSpell(id);

        }
    }
    // WD119: remove unowned choices before restoring the active passive.
    uint32 const frogSpells[3]={9003861,9003862,9003863};
    for(uint32 i=0;i<3;++i) if(!AERank(mask,71+i))
    {
        p->RemoveAurasDueToSpell(frogSpells[i],p->GetGUID());
        if(p->HasSpell(frogSpells[i])) p->removeSpell(frogSpells[i],3,false);
    }
    for(uint32 i=0;i<3;++i) if(AERank(mask,71+i))
    {
        if(!p->HasSpell(frogSpells[i])) p->learnSpell(frogSpells[i]);
        if(i && !p->HasAura(frogSpells[i])) p->CastSpell(p,frogSpells[i],true);
    }
    // WD118: parent removal owns avoidance cleanup; do not leave either aura behind.
    if(!AERank(mask,70))
    {
        p->RemoveAurasDueToSpell(9003859,p->GetGUID());
        p->RemoveAurasDueToSpell(9003860,p->GetGUID());
        if(p->HasSpell(9003859)) p->removeSpell(9003859,3,false);
    }
    else if(!p->HasSpell(9003859)) p->learnSpell(9003859);
    // WD117: no stale strengthened guardian/aura may survive a rank change.
    uint32 const walker=AERank(mask,69);
    uint32 const previous=p->HasSpell(9003858)?2u:(p->HasSpell(9003857)?1u:0u);
    if(previous!=walker)
    {
        p->RemoveAurasDueToSpell(9003855,p->GetGUID());
        WD117ClearSwift(p);
    }
    for(int tier=2;tier>=1;--tier)
    {
        uint32 const id=9003856+uint32(tier);
        if(walker!=uint32(tier))
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
    }
    if(walker)
    {
        uint32 const id=9003856+walker;
        if(!p->HasSpell(id)) p->learnSpell(id);
        if(!p->HasAura(id)) p->CastSpell(p,id,true);
    }
    // WD116: active saved Class ownership. Cancel the running aura when ownership ends.
    if(!AERank(mask,68))
    {
        p->RemoveAurasDueToSpell(9003855,p->GetGUID());
        if(p->HasSpell(9003855)) p->removeSpell(9003855,3,false);
    }
    else if(!p->HasSpell(9003855)) p->learnSpell(9003855);
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
    uint32 const spells[19]={9003700,9003701,9003702,9003703,9003612,9003600,9003521,9003530,9003520,9003511,9003710,9003711,9003712,9003720,9003721,9003730,9003731,9003740,9003741};
    for(uint32 i=0;i<19;++i)
    {
        bool keep=i<3 ? AERank(mask,13)==i+1 : (i==3 ? AERank(mask,14)>0 : (i<10 ? AERank(mask,i+11)>0 : (i<12 ? AERank(mask,21)==i-9 : AERank(mask,i+10)>0)));
        if(!keep)
        {
            if(p->HasSpell(spells[i])) p->removeSpell(spells[i],3,false);
            p->RemoveAurasDueToSpell(spells[i],p->GetGUID());
        }
    }
    for(uint32 i=0;i<19;++i)
    {
        bool keep=i<3 ? AERank(mask,13)==i+1 : (i==3 ? AERank(mask,14)>0 : (i<10 ? AERank(mask,i+11)>0 : (i<12 ? AERank(mask,21)==i-9 : AERank(mask,i+10)>0)));
        if(keep && !p->HasSpell(spells[i])) p->learnSpell(spells[i]);
    }
    // WD87A: rank chains are exclusive, and the free level-40 node is still build-owned.
    uint32 const spiritTalents[5]={9003750,9003751,9003752,9003753,9003754};
    auto spiritWanted=[mask](uint32 i) {return i<2?AERank(mask,29)==i+1:(i<4?AERank(mask,30)==i-1:AERank(mask,31)>0);};
    for(uint32 i=1;i<5;++i) if(!spiritWanted(i))
    {
        if(p->HasSpell(spiritTalents[i])) p->removeSpell(spiritTalents[i],3,false);
        p->RemoveAurasDueToSpell(spiritTalents[i],p->GetGUID());
    }
    for(uint32 i=1;i<5;++i) if(spiritWanted(i) && !p->HasSpell(spiritTalents[i])) p->learnSpell(spiritTalents[i]);
    uint32 const advanced[7]={9003760,9003762,9003764,9003770,9003780,9003782,9003790};
    for(uint32 i=0;i<7;++i)
    {
        if(!AERank(mask,32+i))
        {
            if(p->HasSpell(advanced[i])) p->removeSpell(advanced[i],3,false);
            p->RemoveAurasDueToSpell(advanced[i],p->GetGUID());
        }
        else if(!p->HasSpell(advanced[i])) p->learnSpell(advanced[i]);
    }
    if(AuraEffect* voice=p->GetAuraEffect(9003780,EFFECT_2,p->GetGUID()))
        voice->ChangeAmount(AERank(mask,37) && p->HasAura(9003782,p->GetGUID())?100:0);
    if(!AERank(mask,32)) p->RemoveAurasDueToSpell(9003761,p->GetGUID());
    if(!AERank(mask,34)) p->RemoveAurasDueToSpell(9003765,p->GetGUID());
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
    for(uint32 spell:{9003861u,9003862u,9003863u,9003859u,9003860u,9003857u,9003858u,9003855u,9003856u,9003853u,9003854u,9003850u,9003851u,9003852u,9003430u,9003452u,9003840u,9003841u,9003842u,9003843u,9003830u,9003470u,9003481u,9003630u,9003631u,9003480u,9003620u,9003621u,9003622u,9003623u,9003624u,9003625u,9003660u,9003663u,9003432u,9003433u,9003640u,9003800u,9003801u,9003810u,9003650u,9003651u,9003633u,9003653u,9003790u,9003780u,9003781u,9003782u,9003770u,9003760u,9003761u,9003762u,9003763u,9003764u,9003765u,9003750u,9003751u,9003752u,9003753u,9003754u,9003740u,9003741u,9003730u,9003731u,9003732u,9003720u,9003721u,9003511u,9003710u,9003711u,9003712u,9003520u,9003521u,9003530u,9003600u,9003690u,9003612u,9003700u,9003701u,9003702u,9003703u}) if(p->HasSpell(spell)) known|=256u;
    if(p->HasSpell(9003610) || p->HasSpell(9003611)) known|=256u;
    for(auto const& rank:WD19A::HexfireRanks) if(p->HasSpell(rank.spell)) known|=256u;
    if(known || s->builds) {ProfileReply(p,"freshonly");return true;}
    QueryResult result=CharacterDatabase.Query("CALL reborn_wd67_join({},{},{})",
        p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),expected);
    uint32 code=result?result->Fetch()[0].Get<uint32>():0;
    if(!Load(p,s)) {s->loaded=false;ProfileReply(p,"database");return true;}
    Reply(p,"ok");ProfileReply(p,code==1?"ok":(code==2?"stale":"invalid"));return true;
}
bool AESaveBuild(ChatHandler* h,uint32 expected,uint32 slot,AEMask const& mask,bool legacy)
{
    Player* p=h->GetSession()->GetPlayer();if(!ProfileReady(p,true)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(legacy) for(auto const& stored:s->aeMasks) if(!WD139::LegacyCompatible(stored))
    {ProfileReply(p,"invalid");return true;}
    if(!s->modern || slot>=s->unlocked || slot>2 || s->specs[slot]==3 || !AEValid(mask,p->GetLevel(),s->testAE,s->testTE) || !AESpecValid(mask,s->specs[slot]))
    {ProfileReply(p,"invalid");return true;}
    if(expected!=s->revision) {ProfileReply(p,"stale");return true;}
    for(uint32 i=0;i<AEIdCount;++i) if(AERank(mask,i)<AERank(s->aeMasks[slot],i))
    {ProfileReply(p,"resetrequired");return true;}
    QueryResult result=CharacterDatabase.Query("CALL reborn_wd139_save({},{},{},{},'{}',{}, {},'{}')",
        p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),expected,slot,mask.Rows(),uint32(p->GetLevel()),WD139::Version,WD139::Hash);
    uint32 code=result?result->Fetch()[0].Get<uint32>():0;
    if(!Load(p,s)) {s->loaded=false;ProfileReply(p,"database");return true;}
    Reply(p,"ok");ProfileReply(p,code==1?"ok":(code==2?"stale":"invalid"));return true;
}

// Keep the legacy command during the staged addon rollout.
bool AESave(ChatHandler* h,uint32 expected,uint32 slot,std::string_view text)
{
    AEMask build;if(!WD139::ParseLegacy(text,build))return false;
    return AESaveBuild(h,expected,slot,build,true);
}
bool AESave139(ChatHandler* h,uint32 expected,uint32 slot,uint32 version,std::string_view hash,std::string_view hex)
{
    if(version!=WD139::Version || hash!=WD139::Hash) {h->SendSysMessage("WD139X|layout");return true;}
    AEMask build;if(!WD139::Build::ParseHex(hex,build))return false;
    return AESaveBuild(h,expected,slot,build,false);
}

// WD95: set (not increment) the current GM character's extra testing allowance.
bool AETestPoints(ChatHandler* h,uint32 extraAE,uint32 extraTE)
{
    if(!h->GetSession() || h->GetSession()->GetSecurity()<SEC_GAMEMASTER) return false;
    if(extraAE>100 || extraTE>100)
    { h->SendSysMessage("WD95: use .wdtestpoints <extra AE 0-100> <extra TE 0-100>; amounts replace the previous bonus.");return true; }
    Player* p=h->GetSession()->GetPlayer();
    if(!ProfileReady(p,true)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    if(!s->modern) { h->SendSysMessage("WD95: join the AE/TE talent system first.");return true; }
    QueryResult result=CharacterDatabase.Query("CALL reborn_wd95_testpoints({},{},{},{},{})",
        p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),s->revision,extraAE,extraTE);
    uint32 code=result?result->Fetch()[0].Get<uint32>():0;
    if(!Load(p,s)) {s->loaded=false;ClearEffects(p,s);ProfileReply(p,"database");return true;}
    Reply(p,"ok");ProfileReply(p,"ok");
    if(code==1) h->PSendSysMessage("WD95: extra AE={} TE={}; total AE={} TE={}. Saved builds kept. Set 0 0 to remove the bonus.",s->testAE,s->testTE,WD67Budget::AE(p->GetLevel())+s->testAE,WD67Budget::TE(p->GetLevel())+s->testTE);
    else if(code==4) h->SendSysMessage("WD95: a saved build uses more than the reduced budget. Reset that build first; no points or talents changed.");
    else if(code==2) h->SendSysMessage("WD95: build revision changed. Retry after talent operations finish; no points changed.");
    else h->SendSysMessage("WD95: allowance update failed; check the WD95 characters SQL. No success reported.");
    return true;
}




