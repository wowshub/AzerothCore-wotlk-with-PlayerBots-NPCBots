// Included inside WD5A, after the ordinary profile/allocation functions.
} // WD5A
namespace WD173 {
inline bool Bot(Player* p) {
 if(!WD5A::Doctor(p)||!p->GetSession()||!p->IsInWorld())return false;
 auto* ai=GET_PLAYERBOT_AI(p);return ai&&!ai->IsRealPlayer();
}
inline bool Safe(Player* p) {
 return p->IsAlive()&&!p->IsInCombat()&&!p->IsBeingTeleported()&&!p->IsNonMeleeSpellCast(false)&&
  !p->HasUnitState(UNIT_STATE_LOST_CONTROL)&&p->GetCharmerGUID().IsEmpty()&&
  !p->IsInFlight()&&!p->GetVehicle()&&!p->GetTransport();
}
inline void Observe(Player* p,Receipt& r) {
 r.level=p->GetLevel();
 if(auto* s=p->CustomData.Get<WD5A::State>(WD5A::Key)) {
  r.revision=s->revision;r.slot=s->active;
  if(s->active<3){r.spec=s->specs[s->active];r.build=s->aeMasks[s->active];}
 }
 r.ae=WD5A::AESpent(r.build);r.te=WD5A::TESpent(r.build);
}
inline unsigned Missing(Player* p,WD139::Build const& b,unsigned spec) {
 unsigned missing=0;
 auto required=[&](unsigned node,unsigned spell){unsigned i=Index(node);if(i<WD139::Count&&b.ranks[i]&&!WD168::ReadSpell(p,spell).learned)++missing;};
 if(spec==0){if(!WD168::ReadSpell(p,9003100).learned)++missing;}
 if(spec==1){if(!WD168::ReadSpell(p,9003101).learned)++missing;}
 if(spec==2){required(12086,9003970);required(4505,9003980);required(7086,9004000);required(8574,9004030);}
 required(29744,9003170);required(6054,9003370);
 return missing;
}
Receipt Preview(Player* p,std::string_view profile) {
 Receipt r;if(!Bot(p)){r.status="not_bot";return r;}Observe(p,r);
 unsigned spec=Spec(profile);if(spec>2){r.status="unknown_profile";return r;}
 if(!WD5A::Enabled()||!WD5A::ProfilesEnabled()||!sConfigMgr->GetOption<bool>("RebornWD67.Enable",false)){r.status="disabled";return r;}
 auto* s=p->CustomData.Get<WD5A::State>(WD5A::Key);
 if(!s||!s->loaded){r.status="not_loaded";return r;}
 if(!s->modern){r.status="enroll_required";return r;}
 if(s->layoutMismatch||r.slot>=3||r.slot>=s->unlocked){r.status="invalid_state";return r;}
 if(r.spec!=spec){r.status=r.spec==3?"bind_required":"different_spec";return r;}
 if(s->testAE||s->testTE){r.status="test_allowance";return r;}
 WD139::Build next;
 if(!Grow(r.build,spec,r.level,[&](WD139::Build const& b){return WD5A::AEValid(b,r.level,0,0);},next)) {r.status="invalid_build";return r;}
 r.build=next;r.ae=WD5A::AESpent(next);r.te=WD5A::TESpent(next);r.status="preview";return r;
}
Receipt Enroll(Player* p,unsigned expected) {
 Receipt r;if(!Bot(p)){r.status="not_bot";return r;}Observe(p,r);
 if(!Safe(p)){r.status="unsafe";return r;}
 // Read/load through the ordinary UI initialization first, then prove this was not already enrolled.
 if(!WD5A::ProfileReady(p,false)){r.status="not_ready";return r;}
 Observe(p,r);auto* before=p->CustomData.Get<WD5A::State>(WD5A::Key);
 if(before->modern){r.status="already_enrolled";return r;}
 if(r.revision!=expected){r.status="stale";return r;}
 ChatHandler local(p->GetSession());WD5A::AEJoin(&local,expected);Observe(p,r);
 auto* s=p->CustomData.Get<WD5A::State>(WD5A::Key);
 r.committed=s&&s->loaded&&s->modern&&r.revision==expected+1;
 r.status=r.committed?"enrolled":"enroll_not_confirmed";return r;
}
Receipt Bind(Player* p,std::string_view profile,unsigned expected) {
 Receipt r;if(!Bot(p)){r.status="not_bot";return r;}Observe(p,r);
 if(!Safe(p)){r.status="unsafe";return r;}
 unsigned spec=Spec(profile);if(spec>2){r.status="unknown_profile";return r;}
 auto* s=p->CustomData.Get<WD5A::State>(WD5A::Key);
 if(!s||!s->loaded||!s->modern||r.slot>=3||!s->aeMasks[r.slot].Empty()||r.spec!=3||r.revision!=expected){r.status="bind_precondition";return r;}
 ChatHandler local(p->GetSession());WD5A::ProfileBind(&local,expected,r.slot,spec);Observe(p,r);
 r.committed=s->loaded&&r.revision==expected+1&&r.spec==spec;
 r.status=r.committed?"bound":"bind_not_confirmed";return r;
}
Receipt Apply(Player* p,std::string_view profile,unsigned expected,unsigned level,std::string_view hex) {
 Receipt r=Preview(p,profile);if(std::string_view(r.status)!="preview")return r;
 if(!Safe(p)){r.status="unsafe";return r;}
 if(r.revision!=expected||r.level!=level||r.build.Hex()!=hex){r.status="stale_preview";return r;}
 auto wanted=r.build;unsigned slot=r.slot,spec=r.spec;
 // Re-use ordinary refresh/250ms mutation gate; do not impersonate the GM account in SQL.
 if(!WD5A::ProfileReady(p,true)){r.status="not_ready";return r;}
 auto* s=p->CustomData.Get<WD5A::State>(WD5A::Key);
 if(s->revision!=expected||s->active!=slot||s->specs[slot]!=spec){r.status="stale";Observe(p,r);return r;}
 auto checked=Preview(p,profile);
 if(std::string_view(checked.status)!="preview"||checked.build.Hex()!=hex){r.status="stale_preview";return r;}
 bool same=s->aeMasks[slot].Hex()==hex;
 if(!same) {
  QueryResult q=CharacterDatabase.Query("CALL reborn_wd139_save({},{},{},{},'{}',{},{},'{}')",
   p->GetGUID().GetCounter(),p->GetSession()->GetAccountId(),expected,slot,wanted.Rows(),level,WD139::Version,WD139::Hash);
  unsigned code=q?q->Fetch()[0].Get<unsigned>():0;
  if(!WD5A::Load(p,s)){s->loaded=false;WD5A::ClearEffects(p,s);r.status="reload_failed";return r;}
  Observe(p,r);
  if(code!=1){r.status=code==2?"stale":"save_not_confirmed";return r;}
  if(s->active!=slot||s->specs[slot]!=spec||s->revision!=expected+1||s->aeMasks[slot].Hex()!=hex){r.status="receipt_mismatch";return r;}
  r.committed=true;
 }
 Observe(p,r);r.missing=Missing(p,r.build,r.spec);
 r.ready=WD168::ReadPlan(p).available&&r.missing==0;
 r.status=r.ready?(same?"unchanged_core_ready":"saved_core_ready"):(same?"unchanged_missing_skills":"saved_missing_skills");
 WD5A::Reply(p,"ok");WD5A::ProfileReply(p,"ok");return r;
}
Receipt TrainOne(Player* p,Creature* npc,unsigned cap) {
 Receipt r;if(!Bot(p)){r.status="not_bot";return r;}Observe(p,r);
 if(!Safe(p)){r.status="unsafe";return r;}
 if(!npc||npc->GetEntry()!=900189||!npc->IsAlive()||!p->IsWithinLOSInMap(npc)||p->GetNPCIfCanInteractWith(npc->GetGUID(),UNIT_NPC_FLAG_TRAINER)!=npc){r.status="trainer_unreachable";return r;}
 auto* trainer=sObjectMgr->GetTrainer(npc->GetEntry());
 if(!trainer||!trainer->IsTrainerValidForPlayer(p)){r.status="trainer_invalid";return r;}
 // A talent replacement can hide a paid rank. Never charge for that purchase a second time.
 QueryResult ledger=CharacterDatabase.Query("SELECT spell FROM reborn_wd12_training WHERE guid={} UNION ALL SELECT 0",p->GetGUID().GetCounter());
 if(!ledger){r.status="ledger_unavailable";return r;}
 std::unordered_set<unsigned> purchased;
 do {purchased.insert(ledger->Fetch()[0].Get<unsigned>());}while(ledger->NextRow());
 Trainer::Spell const* choice=nullptr;
 for(auto const& spell:trainer->GetSpells()) {
  if(purchased.count(spell.SpellId)||(p->HasSpell(9003968)&&WD19A::IsWrath(spell.SpellId))||!sSpellMgr->GetSpellInfo(spell.SpellId)||WD67::Managed(spell.SpellId)||spell.IsCastable()||!trainer->CanTeachSpell(p,&spell))continue;
  if(!choice||spell.ReqLevel<choice->ReqLevel||(spell.ReqLevel==choice->ReqLevel&&spell.SpellId<choice->SpellId))choice=&spell;
 }
 if(!choice){r.status="no_available_direct_spell";return r;}
 unsigned cost=unsigned(choice->MoneyCost*p->GetReputationPriceDiscount(npc));
 r.spell=choice->SpellId;
 if(cost>cap||cost>p->GetMoney()){r.status="training_budget";return r;}
 unsigned before=p->GetMoney();trainer->TeachSpell(npc,p,choice->SpellId);
 r.paid=before>=p->GetMoney()?before-p->GetMoney():0;
 r.ready=p->HasSpell(choice->SpellId);r.status=r.ready?"learned_ledger_queued":"not_learned";
 return r;
}
} // WD173
namespace WD5A {
inline Player* BotTarget173(ChatHandler* h){return h->getSelectedPlayer();}
inline bool BotReport173(ChatHandler* h,Player* p,WD173::Receipt const& r) {
 h->PSendSysMessage("WD173 status={} bot={} guid={} rev={} slot={} spec={} level={} AE={} TE={} committed={} ready={} missing={} spell={} paid_copper={} hex={}",r.status,p?p->GetName():"none",p?p->GetGUID().GetCounter():0,r.revision,r.slot,r.spec,r.level,r.ae,r.te,r.committed?1:0,r.ready?1:0,r.missing,r.spell,r.paid,r.build.Hex());return true;
}
bool BotPreview173(ChatHandler* h,std::string_view profile){auto* p=BotTarget173(h);return BotReport173(h,p,WD173::Preview(p,profile));}
bool BotEnroll173(ChatHandler* h,uint32 rev){auto* p=BotTarget173(h);return BotReport173(h,p,WD173::Enroll(p,rev));}
bool BotBind173(ChatHandler* h,std::string_view profile,uint32 rev){auto* p=BotTarget173(h);return BotReport173(h,p,WD173::Bind(p,profile,rev));}
bool BotApply173(ChatHandler* h,std::string_view profile,uint32 rev,uint32 level,std::string_view hex){auto* p=BotTarget173(h);return BotReport173(h,p,WD173::Apply(p,profile,rev,level,hex));}
bool BotTrain173(ChatHandler* h,uint32 maxCopper){auto* p=BotTarget173(h);return BotReport173(h,p,WD173::TrainOne(p,p?p->FindNearestCreature(900189,INTERACTION_DISTANCE):nullptr,maxCopper));}
