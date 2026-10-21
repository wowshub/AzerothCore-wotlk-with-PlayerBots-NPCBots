// WD174: finite map-thread steps. No database/game pointers or sleeps in policy state.
#pragma once
#include "RebornWitchDoctorBotBuild173.h"
#include <algorithm>
#include <cstdint>
namespace WD174 {
enum class Phase{None,Check,Enroll,Bind,Apply,Train,Confirm,Verify,Watching,Done,Stopped};
inline char const* Name(Phase p){switch(p){case Phase::None:return "none";case Phase::Check:return "check";case Phase::Enroll:return "enroll";case Phase::Bind:return "bind";case Phase::Apply:return "apply";case Phase::Train:return "train";case Phase::Confirm:return "confirm";case Phase::Verify:return "verify";case Phase::Watching:return "watching";case Phase::Done:return "done";default:return "stopped";}}
inline bool Running(Phase p){return p!=Phase::None&&p!=Phase::Done&&p!=Phase::Stopped;}
struct Observation{bool actor=false,safe=false,loaded=false;unsigned revision=0,slot=0,spec=3,level=0;};
struct State {
 Phase phase=Phase::None;
 std::string profile,detail="none";
 unsigned cap=0,purchases=0,confirmed=0,revision=0,slot=0,spec=3,seenLevel=0,appliedLevel=0;
 unsigned cycleMs=0,phaseMs=0,nextMs=0,pendingSpell=0;
 std::uint64_t spent=0;
 bool watch=false,identity=false,ready=false,hasChanges=false;
 WD173::Receipt last;
};
inline void Stop(State& s,std::string reason){s.phase=Phase::Stopped;s.detail=std::move(reason);s.ready=false;}
inline void Set(State& s,Phase p,char const* reason){s.phase=p;s.detail=reason;s.phaseMs=0;}
inline void Accept(State& s,WD173::Receipt const& r){s.last=r;s.revision=r.revision;s.slot=r.slot;s.spec=r.spec;s.identity=true;s.hasChanges=s.hasChanges||r.committed;}
inline bool Applied(WD173::Receipt const& r){std::string_view v=r.status;return v=="saved_core_ready"||v=="unchanged_core_ready"||v=="saved_missing_skills"||v=="unchanged_missing_skills";}
inline State Begin(std::string_view profile,unsigned cap,bool watch,unsigned level){State s;s.profile=profile;s.cap=cap;s.watch=watch;s.seenLevel=level;Set(s,Phase::Check,"started");return s;}
// Provider supplies only current map-thread observations and the normal WD173 operations.
template<class Provider>void Advance(State& s,Provider& ops,unsigned diff) {
 if(!Running(s.phase))return;
 if(s.phase!=Phase::Watching) {
  auto elapsed=std::uint64_t(s.cycleMs)+diff;
  if(elapsed>=300000){Stop(s,"preparation_timeout");return;}
  s.cycleMs=unsigned(elapsed);s.phaseMs=unsigned(std::min<std::uint64_t>(std::uint64_t(s.phaseMs)+diff,300000));
 }
 if(s.nextMs>diff){s.nextMs-=diff;return;}s.nextMs=1000;
 auto o=ops.Sample(s.phase!=Phase::Watching);
 if(!o.actor){Stop(s,"not_bot");return;}
 if(o.level<s.seenLevel){Stop(s,"level_decreased");return;}s.seenLevel=o.level;
 if(s.identity&&(!o.loaded||o.revision!=s.revision||o.slot!=s.slot||o.spec!=s.spec)){Stop(s,"external_build_change");return;}
 if(s.phase==Phase::Watching){
  if(o.level==s.appliedLevel)return;
  s.cycleMs=0;s.ready=false;Set(s,Phase::Check,"level_changed");return;
 }
 if(!o.safe){s.detail="paused_unsafe_or_party_combat";return;}
 if(s.phase==Phase::Check){
  auto r=ops.Preview();s.last=r;std::string_view result=r.status;
  if(o.loaded){s.identity=true;s.revision=o.revision;s.slot=o.slot;s.spec=o.spec;}
  if(result=="not_loaded"||result=="enroll_required"){Set(s,Phase::Enroll,"enroll_required");return;}
  if(result=="bind_required"){Set(s,Phase::Bind,"bind_required");return;}
  if(result=="preview"){Set(s,Phase::Apply,"preview_ready");return;}
  Stop(s,r.status);return;
 }
 if(s.phase==Phase::Enroll){
  auto r=ops.Enroll(s.identity?s.revision:0);s.last=r;
  if((std::string_view(r.status)=="enrolled"&&r.committed)||std::string_view(r.status)=="already_enrolled"){Accept(s,r);Set(s,Phase::Check,"enrolled");return;}
  Stop(s,r.status);return;
 }
 if(s.phase==Phase::Bind){
  auto r=ops.Bind(s.revision);s.last=r;
  if(r.committed&&std::string_view(r.status)=="bound"){Accept(s,r);Set(s,Phase::Check,"bound");return;}
  Stop(s,r.status);return;
 }
 if(s.phase==Phase::Apply){
  auto preview=ops.Preview();s.last=preview;
  if(std::string_view(preview.status)!="preview"){Stop(s,preview.status);return;}
  auto r=ops.Apply(preview);s.last=r;
  if(!Applied(r)){Stop(s,r.status);return;}
  Accept(s,r);s.appliedLevel=r.level;Set(s,Phase::Train,"build_confirmed");return;
 }
 if(s.phase==Phase::Train){
  if(o.level!=s.appliedLevel){Set(s,Phase::Check,"level_changed");return;}
  if(s.spent>s.cap){Stop(s,"budget_overrun");return;}
  if(s.purchases>=128){Stop(s,"purchase_limit");return;}
  auto r=ops.Train(unsigned(s.cap-s.spent));s.last=r;s.spent+=r.paid;
  if(s.spent>s.cap){Stop(s,"budget_overrun");return;}
  std::string_view result=r.status;
  if(result=="trainer_unreachable"){s.detail="waiting_for_trainer";return;}
  if(result=="no_available_direct_spell"){Set(s,Phase::Verify,"training_complete");return;}
  if(result=="learned_ledger_queued"&&r.ready&&r.spell){++s.purchases;s.pendingSpell=r.spell;s.hasChanges=true;Set(s,Phase::Confirm,"awaiting_training_ledger");return;}
  Stop(s,r.status);return;
 }
 if(s.phase==Phase::Confirm){
  auto r=ops.Confirm(s.pendingSpell);s.last=r;
  if(r.ready&&std::string_view(r.status)=="training_confirmed"){++s.confirmed;s.pendingSpell=0;Set(s,Phase::Train,"training_confirmed");return;}
  if(std::string_view(r.status)!="training_pending"){Stop(s,r.status);return;}
  if(s.phaseMs>=10000){Stop(s,"training_confirmation_timeout");return;}
  s.detail="awaiting_training_ledger";return;
 }
 if(s.phase==Phase::Verify){
  if(o.level!=s.appliedLevel){Set(s,Phase::Check,"level_changed");return;}
  auto preview=ops.Preview();s.last=preview;
  if(std::string_view(preview.status)!="preview"){Stop(s,preview.status);return;}
  auto r=ops.Apply(preview);s.last=r;
  if(!Applied(r)){Stop(s,r.status);return;}Accept(s,r);
  if(!r.ready){Stop(s,"core_skills_missing");return;}
  s.ready=true;s.appliedLevel=r.level;
  Set(s,s.watch?Phase::Watching:Phase::Done,s.watch?"ready_waiting_for_level":"ready");return;
 }
}
}
