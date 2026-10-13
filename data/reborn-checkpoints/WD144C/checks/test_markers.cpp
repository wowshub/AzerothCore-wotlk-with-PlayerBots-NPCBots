
#include <cassert>
#include <map>
#include <iostream>
using uint32=unsigned;using int32=int;using ObjectGuid=unsigned;
enum{EFFECT_0,EFFECT_1,EFFECT_2};constexpr unsigned Jinx=9003150;
struct AuraEffect {int amount=0;int GetAmount(){return amount;}};
struct Aura {
 AuraEffect eff[3];int duration=20000,max=20000;bool removed=false;
 AuraEffect* GetEffect(int i){return &eff[i];}int GetDuration(){return duration;}int GetMaxDuration(){return max;}
 void SetDuration(int x){duration=x;}void SetMaxDuration(int x){max=x;}void Remove(){removed=true;}
};
struct Unit {
 std::map<std::pair<unsigned,unsigned>,Aura> auras;
 Aura* GetAura(unsigned id,unsigned owner){auto i=auras.find({id,owner});return i==auras.end()||i->second.removed?nullptr:&i->second;}
 void RemoveAurasDueToSpell(unsigned id,unsigned owner){auto a=GetAura(id,owner);if(a)a->Remove();}
};
struct Player {unsigned owner;unsigned GetGUID(){return owner;}Aura* AddAura(unsigned id,Unit* t){auto& a=t->auras[{id,owner}];a=Aura{};return &a;}};
constexpr uint32 DecayMark=9003996,SerpentMark=9003997;
void RemoveMarks(Unit* target,ObjectGuid caster)
{
    target->RemoveAurasDueToSpell(DecayMark,caster);
    target->RemoveAurasDueToSpell(SerpentMark,caster);
}
void SyncMarks(Player* p,Unit* target,Aura* parent)
{
    if(!p || !target) return;
    for(uint32 id : {DecayMark,SerpentMark})
    {
        AuraEffect* effect=parent?parent->GetEffect(id==DecayMark?EFFECT_2:EFFECT_1):nullptr;
        bool wanted=effect && (id==DecayMark?effect->GetAmount()<0:effect->GetAmount()>0);
        if(!wanted) { target->RemoveAurasDueToSpell(id,p->GetGUID());continue; }
        Aura* mark=target->GetAura(id,p->GetGUID());
        if(!mark) mark=p->AddAura(id,target); // no damage/proc, no second resistance roll
        if(mark)
        {
            mark->SetMaxDuration(parent->GetMaxDuration());
            mark->SetDuration(parent->GetDuration());
        }
    }
}
struct Marker {Unit* target;unsigned owner,id;Aura* self;Unit* GetTarget(){return target;}unsigned GetCasterGUID(){return owner;}unsigned GetId(){return id;}Aura* GetAura(){return self;}void tick(){
        // Resolve by parent + original caster GUID even if the caster is out of range.
        Aura* parent=GetTarget()->GetAura(Jinx,GetCasterGUID());
        AuraEffect* effect=parent?parent->GetEffect(GetId()==DecayMark?EFFECT_2:EFFECT_1):nullptr;
        bool active=effect && (GetId()==DecayMark?effect->GetAmount()<0:effect->GetAmount()>0);
        if(!active) { GetAura()->Remove();return; }
        // Parent refresh/PvP duration wins; markers must never extend gameplay effects.
        if(GetAura()->GetMaxDuration()!=parent->GetMaxDuration()) GetAura()->SetMaxDuration(parent->GetMaxDuration());
        int32 difference=GetAura()->GetDuration()-parent->GetDuration();
        if(difference>500 || difference< -500) GetAura()->SetDuration(parent->GetDuration());
}};

int main(){unsigned checks=0;
 for(unsigned owner:{1u,2u})for(int choice=0;choice<3;++choice)for(int duration:{1000,6000,20000}){
  Player p{owner},other{3};Unit t;Aura* parent=p.AddAura(Jinx,&t);parent->duration=duration;parent->max=duration;
  parent->eff[1].amount=choice==1?10:0;parent->eff[2].amount=choice==2?-30:0;
  other.AddAura(DecayMark,&t);other.AddAura(SerpentMark,&t);
  SyncMarks(&p,&t,parent);
  assert(bool(t.GetAura(SerpentMark,owner))==(choice==1));assert(bool(t.GetAura(DecayMark,owner))==(choice==2));
  assert(parent->eff[1].amount==(choice==1?10:0)&&parent->eff[2].amount==(choice==2?-30:0));checks+=3;
  if(choice){unsigned id=choice==1?SerpentMark:DecayMark;Aura* a=t.GetAura(id,owner);assert(a->duration==duration);++checks;
   Marker m{&t,owner,id,a};parent->duration+=3000;parent->max+=3000;m.tick();assert(a->duration==parent->duration&&a->max==parent->max);++checks;
   parent->eff[choice==1?1:2].amount=0;m.tick();assert(a->removed);++checks;
   parent->eff[choice==1?1:2].amount=choice==1?10:-30;SyncMarks(&p,&t,parent);a=t.GetAura(id,owner);assert(a&&!a->removed);++checks;
   m.self=a;parent->Remove();m.tick();assert(a->removed);++checks;
  }
  RemoveMarks(&t,owner);assert(!t.GetAura(DecayMark,owner)&&!t.GetAura(SerpentMark,owner));assert(t.GetAura(DecayMark,3)&&t.GetAura(SerpentMark,3));checks+=2;
 }
 // Switching an existing same-caster curse must remove the old marker and add only the new.
 Player p{1};Unit t;Aura* parent=p.AddAura(Jinx,&t);parent->eff[2].amount=-30;SyncMarks(&p,&t,parent);
 parent->eff[2].amount=0;parent->eff[1].amount=10;SyncMarks(&p,&t,parent);assert(!t.GetAura(DecayMark,1)&&t.GetAura(SerpentMark,1));++checks;
 std::cout<<checks<<" delivered helper/marker lifecycle assertions passed\n";
}
