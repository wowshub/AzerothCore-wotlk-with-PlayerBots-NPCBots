// MBTG1A: native talents and durable, single-use bot unlock quotes.
namespace BT1
{
constexpr char QuoteKey[]="Reborn.MBTG1A.Quote";
struct Quote:DataMap::Base
{uint32 owner=0,account=0,nonce=0,slot=0,currency=0,price=0,level=0;bool valid=false;std::chrono::steady_clock::time_point time;};
bool Classic(Player* p){return p&&p->getClass()<=11&&p->getClass()!=10;}
Player* Target(ChatHandler* h,uint32 guid,uint32 nonce,bool write)
{
 auto fail=[&](char const* why)->Player*{h->PSendSysMessage("BTT1|{}|{}|ERROR|{}",guid,nonce,why);return nullptr;};
 auto* owner=h->GetSession()?h->GetSession()->GetPlayer():nullptr;
 if(!owner||!owner->IsInWorld()||!guid||!nonce||nonce>2147483647)return fail("identity");
 auto* b=ObjectAccessor::GetPlayer(*owner,ObjectGuid::Create<HighGuid::Player>(guid));
 auto* ai=b?GET_PLAYERBOT_AI(b):nullptr;
 if(!b||b==owner||!b->IsInWorld()||!b->GetSession()||(!Classic(b)&&!Doctor(b))||!ai||ai->IsRealPlayer()||ai->GetMaster()!=owner||!owner->GetGroup()||owner->GetGroup()!=b->GetGroup()||owner->GetMap()!=b->GetMap()||!owner->InSamePhase(b)||!owner->IsWithinDistInMap(b,50.f))return fail("permission");
 if(write&&(!WD173::Safe(b)||!owner->IsAlive()||owner->IsInCombat()||owner->IsBeingTeleported()))return fail("unsafe");
 return b;
}
std::map<uint32,uint32> Ranks(Player* b)
{
 std::map<uint32,uint32> ranks;
 for(auto const& [spell,t]:b->GetTalentMap())if(t->State!=PLAYERSPELL_REMOVED&&t->IsInSpec(b->GetActiveSpec()))
  if(auto* n=sTalentStore.LookupEntry(t->talentID))for(uint32 i=0;i<MAX_TALENT_RANK;++i)if(n->RankID[i]==spell)ranks[t->talentID]=std::max(ranks[t->talentID],i+1);
 return ranks;
}
uint32 Stamp(Player* b)
{
 std::ostringstream out;out<<uint32(b->GetLevel())<<':'<<uint32(b->GetActiveSpec())<<':'<<b->GetFreeTalentPoints()<<':'<<uint32(b->GetSpecsCount());for(auto [id,r]:Ranks(b))out<<':'<<id<<':'<<r;
 uint64 hash=1;for(unsigned char c:out.str())hash=(hash*31+c)%2147483647;return uint32(hash);
}
void SnapshotReply(ChatHandler* h,Player* b,uint32 nonce)
{
 auto guid=b->GetGUID().GetCounter();auto ranks=Ranks(b);
 h->PSendSysMessage("BTT1|{}|{}|BEGIN|{}|{}|{}|{}|{}|{}|{}|{}",guid,nonce,uint32(b->getClass()),uint32(b->GetLevel()),uint32(b->GetActiveSpec()),uint32(b->GetSpecsCount()),b->GetFreeTalentPoints(),b->GetMoney(),Stamp(b),ranks.size());
 std::string chunk;for(auto [id,r]:ranks){auto item=std::to_string(id)+":"+std::to_string(r)+",";if(chunk.size()+item.size()>120){h->PSendSysMessage("BTT1|{}|{}|ROWS|{}",guid,nonce,chunk);chunk.clear();}chunk+=item;}
 if(!chunk.empty())h->PSendSysMessage("BTT1|{}|{}|ROWS|{}",guid,nonce,chunk);
 h->PSendSysMessage("BTT1|{}|{}|END",guid,nonce);
}
bool Read(ChatHandler* h,uint32 guid,uint32 nonce){auto* b=Target(h,guid,nonce,false);if(b&&Classic(b))SnapshotReply(h,b,nonce);return true;}
bool Switch(ChatHandler* h,uint32 guid,uint32 nonce,uint32 group,uint32 stamp)
{
 auto* b=Target(h,guid,nonce,true);if(!b)return true;
 if(!Classic(b)||group>=b->GetSpecsCount()||group>1||stamp!=Stamp(b)){h->PSendSysMessage("BTT1|{}|{}|ERROR|stale",guid,nonce);return true;}
 if(group!=b->GetActiveSpec()){b->ActivateSpec(group);if(auto* ai=GET_PLAYERBOT_AI(b))ai->ResetStrategies();}
 SnapshotReply(h,b,nonce);return true;
}
bool Point(ChatHandler* h,uint32 guid,uint32 nonce,uint32 group,uint32 stamp,uint32 id,uint32 rank)
{
 auto* b=Target(h,guid,nonce,true);if(!b)return true;
 auto fail=[&](char const* why){h->PSendSysMessage("BTT1|{}|{}|ERROR|{}",guid,nonce,why);return true;};
 if(!Classic(b)||group!=b->GetActiveSpec()||stamp!=Stamp(b))return fail("stale");
 auto* n=sTalentStore.LookupEntry(id);auto* tab=n?sTalentTabStore.LookupEntry(n->TalentTab):nullptr;
 auto ranks=Ranks(b);uint32 before=ranks[id];
 if(!tab||!(tab->ClassMask&b->getClassMask())||!rank||rank>MAX_TALENT_RANK||!n->RankID[rank-1]||rank!=before+1||!b->GetFreeTalentPoints())return fail("point");
 b->LearnTalent(id,rank-1,false);if(Ranks(b)[id]!=rank)return fail("native_rejected");
 b->SendTalentsInfoData(false);SnapshotReply(h,b,nonce);return true;
}
bool Storage()
{
 auto r=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='reborn_bt1_receipt' AND engine='InnoDB'");
 auto p=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema=DATABASE() AND routine_name='reborn_bt1_buy'");
 return r&&p&&r->Fetch()[0].Get<uint32>()==1&&p->Fetch()[0].Get<uint32>()==1;
}
bool Policy(Player* b,uint32 slot,uint32 currency,uint32& level,uint32& price)
{
 if(currency>2)return false;
 if(Doctor(b)){uint32 old=0;if(!PurchasePolicy(slot,level,old))return false;}
 else if(Classic(b)&&slot==1)level=sWorld->getIntConfig(CONFIG_MIN_DUALSPEC_LEVEL);else return false;
 price=sConfigMgr->GetOption<uint32>(currency==0?"Reborn.BotTalents.Unlock.Gold":currency==1?"Reborn.BotTalents.Unlock.DP":"Reborn.BotTalents.Unlock.VP",currency==0?1000:100);
 return price>0&&price<=(currency==0?200000u:2000000000u);
}
bool Recover(Player* b)
{
 if(Doctor(b))return ProfileReady(b,true);
 if(b->GetSpecsCount()>1)return true;
 auto r=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_bt1_receipt WHERE guid={} AND account_id={} AND class_id={} AND slot=1",b->GetGUID().GetCounter(),b->GetSession()->GetAccountId(),b->getClass());
 if(!r||!r->Fetch()[0].Get<uint32>())return false;
 b->CastSpell(b,63680,true,nullptr,nullptr,b->GetGUID());b->CastSpell(b,63624,true,nullptr,nullptr,b->GetGUID());return b->GetSpecsCount()>1;
}
bool Ask(ChatHandler* h,uint32 guid,uint32 nonce,uint32 slot,uint32 currency)
{
 auto* b=Target(h,guid,nonce,true);if(!b)return true;
 auto fail=[&](char const* why){h->PSendSysMessage("BTT1|{}|{}|ERROR|{}",guid,nonce,why);return true;};
 if(auto* old=b->CustomData.Get<Quote>(QuoteKey))old->valid=false;
 if(!Storage())return fail("storage");
 if(Doctor(b)){if(!ProfileReady(b,true))return fail("profile");auto* s=b->CustomData.Get<State>(Key);if(!s||slot!=s->unlocked)return fail("slot");}
 else if(Recover(b))return fail("already_unlocked");
 uint32 level=0,price=0;if(!Policy(b,slot,currency,level,price))return fail("disabled");
 if(b->GetLevel()<level)return fail("level");
 uint32 balance=b->GetMoney()/10000;
 if(currency){auto r=CharacterDatabase.Query("SELECT {} FROM sahtout_site.user_currencies WHERE account_id={}",currency==1?"tokens":"points",b->GetSession()->GetAccountId());if(!r)return fail("wallet_unavailable");balance=r->Fetch()[0].Get<uint32>();}
 if(balance<price)return fail("insufficient");
 auto* q=b->CustomData.GetDefault<Quote>(QuoteKey);q->owner=h->GetSession()->GetPlayer()->GetGUID().GetCounter();q->account=b->GetSession()->GetAccountId();q->nonce=nonce;q->slot=slot;q->currency=currency;q->price=price;q->level=level;q->time=std::chrono::steady_clock::now();q->valid=true;
 h->PSendSysMessage("BTT1|{}|{}|QUOTE|{}|{}|{}|{}|{}|{}",guid,nonce,slot,currency,price,balance,level,q->account);return true;
}
bool Buy(ChatHandler* h,uint32 guid,uint32 nonce,uint32 token)
{
 auto* b=Target(h,guid,nonce,true);if(!b)return true;
 auto fail=[&](char const* why){h->PSendSysMessage("BTT1|{}|{}|ERROR|{}",guid,nonce,why);return true;};
 auto* saved=b->CustomData.Get<Quote>(QuoteKey);if(!saved)return fail("expired");auto q=*saved;saved->valid=false;
 uint32 level=0,price=0;
 if(!q.valid||token!=q.nonce||q.owner!=h->GetSession()->GetPlayer()->GetGUID().GetCounter()||q.account!=b->GetSession()->GetAccountId()||std::chrono::steady_clock::now()-q.time>std::chrono::seconds(55)||!Policy(b,q.slot,q.currency,level,price)||price!=q.price||level!=q.level||b->GetLevel()<level)return fail("expired");
 if(!Storage())return fail("storage");
 if(Doctor(b)){if(!ProfileReady(b,true))return fail("profile");auto* s=b->CustomData.Get<State>(Key);if(!s||s->unlocked!=q.slot)return fail("slot");}
 else if(Recover(b))return fail("already_unlocked");
 uint32 before=b->GetMoney(),cost=q.currency==0?q.price*10000:0;
 if(before<cost)return fail("insufficient");
 // Persist live gold and entitlement in one transaction. DP/VP are one
 // cross-schema InnoDB transaction in the audited same-instance wallet.
 if(cost)
 {
  b->ModifyMoney(-int32(cost));if(b->GetMoney()!=before-cost){b->SetMoney(before);return fail("debit");}
  auto tx=CharacterDatabase.BeginTransaction();b->SaveGoldToDB(tx);
  tx->Append("INSERT INTO reborn_bt1_receipt(guid,account_id,class_id,slot,currency,amount) VALUES({},{},{},{},0,{})",guid,q.account,b->getClass(),q.slot,q.price);
  if(Doctor(b))tx->Append("INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({},{},{})",guid,q.slot,cost);
  auto done=CharacterDatabase.AsyncCommitTransaction(tx);if(!done.m_future.get()){b->SetMoney(before);return fail("transaction");}
 }
 else
 {
  auto r=CharacterDatabase.Query("CALL reborn_bt1_buy({},{},{},{},{},{})",guid,q.account,b->getClass(),q.slot,q.currency,q.price);
  if(!r)return fail("unconfirmed");auto code=r->Fetch()[0].Get<uint32>();if(code!=1&&code!=2)return fail(code==3?"insufficient":"transaction");
 }
 bool ready=false;if(Doctor(b)){auto* s=b->CustomData.Get<State>(Key);ready=s&&Load(b,s)&&s->unlocked>q.slot;}else ready=Recover(b);
 h->PSendSysMessage("BTT1|{}|{}|{}",guid,nonce,ready?"BOUGHT":"RECOVERY_REQUIRED");return true;
}
}
