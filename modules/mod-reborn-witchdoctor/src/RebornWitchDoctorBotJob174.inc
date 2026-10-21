// Included inside WD5A after WD173. Runtime owns state on each opted-in Player.
} // WD5A
namespace WD174 {
constexpr char Key[]="RebornWD174.Preparation";
struct Job:DataMap::Base{State value;};
struct Provider {
 Player* p;std::string const& profile;
 Observation Sample(bool checkSafety=true){
  Observation o;o.actor=WD173::Bot(p);if(!o.actor)return o;
  o.safe=checkSafety&&WD173::Safe(p);o.level=p->GetLevel();
  auto busy=[&](Player* ally){return ally&&ally->IsAlive()&&ally->IsInWorld()&&p->IsInMap(ally)&&p->InSamePhase(ally)&&p->IsWithinDistInMap(ally,40.f)&&ally->IsInCombat();};
  if(checkSafety)if(auto* ai=GET_PLAYERBOT_AI(p))if(busy(ai->GetMaster()))o.safe=false;
  if(checkSafety)if(auto* group=p->GetGroup())for(auto* ref=group->GetFirstMember();ref;ref=ref->next())if(busy(ref->GetSource()))o.safe=false;
  if(o.safe&&RebornWD171::NPCCombat(p))o.safe=false;
  if(auto* s=p->CustomData.Get<WD5A::State>(WD5A::Key)){o.loaded=s->loaded;o.revision=s->revision;o.slot=s->active;if(s->active<3)o.spec=s->specs[s->active];}
  return o;
 }
 WD173::Receipt Preview(){return WD173::Preview(p,profile);}
 WD173::Receipt Enroll(unsigned rev){return WD173::Enroll(p,rev);}
 WD173::Receipt Bind(unsigned rev){return WD173::Bind(p,profile,rev);}
 WD173::Receipt Apply(WD173::Receipt const& r){return WD173::Apply(p,profile,r.revision,r.level,r.build.Hex());}
 WD173::Receipt Train(unsigned cap){return WD173::TrainOne(p,p->FindNearestCreature(900189,INTERACTION_DISTANCE),cap);}
 WD173::Receipt Confirm(unsigned spell){return WD173::ConfirmTraining(p,spell);}
};
inline void Report(Player* p,State const& s){
 LOG_INFO("playerbots","WD174 bot={} guid={} phase={} reason={} spent={} purchases={} confirmed={} rev={} level={}",p->GetName(),p->GetGUID().GetCounter(),Name(s.phase),s.detail,s.spent,s.purchases,s.confirmed,s.revision,s.appliedLevel);
}
State Status(Player* p){if(p)if(auto* job=p->CustomData.Get<Job>(Key))return job->value;return {};}
State Start(Player* p,std::string_view profile,unsigned cap,bool watch){
 State rejected;
 if(!WD173::Bot(p)){Stop(rejected,"not_bot");return rejected;}
 if(WD173::Spec(profile)>2){Stop(rejected,"unknown_profile");return rejected;}
 if(cap>100000000){Stop(rejected,"budget_limit");return rejected;}
 if(p->GetLevel()<10){Stop(rejected,"level_too_low");return rejected;}
 if(auto* old=p->CustomData.Get<Job>(Key))if(Running(old->value.phase)){auto result=old->value;result.detail="already_running";return result;}
 auto* job=p->CustomData.GetDefault<Job>(Key);job->value=Begin(profile,cap,watch,p->GetLevel());return job->value;
}
State Cancel(Player* p,std::string_view reason){
 if(p)if(auto* job=p->CustomData.Get<Job>(Key)){if(Running(job->value.phase)){Stop(job->value,std::string(reason));Report(p,job->value);}return job->value;}
 return {};
}
void Tick(Player* p,unsigned diff){
 if(!p)return;auto* job=p->CustomData.Get<Job>(Key);if(!job||!Running(job->value.phase))return;
 Phase before=job->value.phase;Provider ops{p,job->value.profile};Advance(job->value,ops,diff);
 if(before!=job->value.phase&&(job->value.phase==Phase::Done||job->value.phase==Phase::Stopped||job->value.phase==Phase::Watching))
  Report(p,job->value);
}
void Forget(Player* p){if(p){Cancel(p,"logout");p->CustomData.Erase(Key);}}
} // WD174
namespace WD5A {
inline bool BotReport174(ChatHandler* h,Player* p,WD174::State const& s){
 h->PSendSysMessage("WD174 bot={} guid={} phase={} reason={} profile={} watch={} ready={} spent_copper={}/{} purchases={} confirmed={} pending_spell={} revision={} slot={} spec={} level={} missing={} hex={}",p?p->GetName():"none",p?p->GetGUID().GetCounter():0,WD174::Name(s.phase),s.detail,s.profile,s.watch?1:0,s.ready?1:0,s.spent,s.cap,s.purchases,s.confirmed,s.pendingSpell,s.revision,s.slot,s.spec,s.appliedLevel,s.last.missing,s.last.build.Hex());return true;
}
bool BotStart174(ChatHandler* h,std::string_view profile,uint32 copper,uint32 watch){auto* p=BotTarget173(h);if(watch>1){h->SendSysMessage("WD174: watch must be 0 or 1.");return true;}return BotReport174(h,p,WD174::Start(p,profile,copper,watch==1));}
bool BotState174(ChatHandler* h){auto* p=BotTarget173(h);return BotReport174(h,p,WD174::Status(p));}
bool BotStop174(ChatHandler* h){auto* p=BotTarget173(h);return BotReport174(h,p,WD174::Cancel(p));}
