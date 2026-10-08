# coding: utf-8
from wd136_init import *
T=P/'checks/runtime';T.mkdir(parents=True,exist_ok=True)
stub=r'''#pragma once
#include <algorithm>
#include <cstdint>
#include <map>
#include <vector>
using uint32=uint32_t;using uint64=uint64_t;
struct ObjectGuid {uint64 n;ObjectGuid(uint64 v=0):n(v){}uint64 GetRawValue()const{return n;}bool operator<(ObjectGuid b)const{return n<b.n;}};
struct SpellInfo {uint32 GetSchoolMask()const{return 8;}};
class Player;class Aura;struct Application {Aura* a;Aura* GetBase(){return a;}};
struct HealInfo;
class Unit {public:virtual ~Unit(){}virtual Player* ToPlayer(){return nullptr;}bool alive=true,world=true,phase=true,friendly=true;uint64 id=0;uint32 healed=0;std::map<int,Application*> apps;
bool IsAlive(){return alive;}bool IsInWorld(){return world;}bool InSamePhase(Unit* u){return phase&&u->phase;}bool IsFriendlyTo(Unit* u){return friendly&&u->friendly;}ObjectGuid GetGUID(){return ObjectGuid(id);}auto const& GetAppliedAuras(){return apps;}int HealBySpell(HealInfo&,bool);
};
class Player:public Unit {public:bool known=true,aura=true;uint32 cls=13;Player* ToPlayer()override{return this;}uint32 getClass(){return cls;}bool HasSpell(uint32){return known;}bool HasAura(uint32,ObjectGuid){return aura;}};
class Aura {public:Player* caster;uint32 charges=3,spell=9003955;uint32 GetId(){return spell;}uint32 GetCharges(){return charges;}Unit* GetCaster(){return caster;}ObjectGuid GetCasterGUID(){return caster->GetGUID();}void DropCharge(){if(charges)--charges;}};
struct HealInfo {Unit* source;Unit* target;uint32 amount;HealInfo(Unit* s,Unit* t,uint32 a,SpellInfo const*,uint32):source(s),target(t),amount(a){}};
inline int Unit::HealBySpell(HealInfo& h,bool){h.target->healed+=h.amount;return h.amount;}
inline std::map<uint64,Unit*> units;
namespace ObjectAccessor {inline Unit* GetUnit(Unit&,ObjectGuid g){auto i=units.find(g.n);return i==units.end()?nullptr:i->second;}}
struct SpellMgr {SpellInfo spell;SpellInfo const* GetSpellInfo(uint32){return &spell;}};inline SpellMgr mgr;inline SpellMgr* sSpellMgr=&mgr;
'''
(T/'test_runtime.h').write_text(stub,encoding='utf8')
for h in ['Player.h','SpellAuras.h','SpellAuraEffects.h','SpellMgr.h','ObjectAccessor.h']:(T/h).write_text('#include "test_runtime.h"\n')
header=(P/SF/'src/server/game/Spells/RebornWitchDoctorConcoctions.h').as_posix()
test=r'''#include "HEADER"
#include <cassert>
#include <iostream>
#include <random>
int main(){using namespace RebornConcoctions;
 Player doctor;doctor.id=1;units[1]=&doctor;Player other;other.id=2;units[2]=&other;Unit ally;ally.id=3;
 Aura buff{&doctor};Application app{&buff};ally.apps[1]=&app;
 Snapshot casts[4];for(auto& c:casts)c=Launch(&ally);
 assert(buff.charges==0 && casts[0].doctor==1 && casts[2].percent==5 && casts[3].percent==0);
 // One cast, ten targets: ten damage results retain one consumed charge.
 buff.charges=3;auto aoe=Launch(&ally);for(int i=0;i<10;i++)Heal(&ally,aoe,1000,1000);
 assert(buff.charges==2 && ally.healed==500);
 // A DoT snapshot outlives the consumed recipient buff; refresh without buff replaces it.
 Snapshot dot=casts[2];ally.apps.clear();assert(Launch(&ally).percent==0);
 auto before=ally.healed;for(int i=0;i<6;i++)Heal(&ally,dot,200,200);assert(ally.healed==before+60);
 dot=Launch(&ally);Heal(&ally,dot,1000,1000);assert(ally.healed==before+60);
 // No overkill healing; fully absorbed damage; dead/invalid provider/phase/lost talent.
 before=ally.healed;Heal(&ally,casts[0],10000,100);assert(ally.healed==before+5);
 before=ally.healed;Heal(&ally,casts[0],0,100);assert(ally.healed==before);
 doctor.known=false;Heal(&ally,casts[0],1000,1000);assert(ally.healed==before);doctor.known=true;
 doctor.alive=false;Heal(&ally,casts[0],1000,1000);assert(ally.healed==before);doctor.alive=true;
 ally.phase=false;Heal(&ally,casts[0],1000,1000);assert(ally.healed==before);ally.phase=true;
 ally.alive=false;Heal(&ally,casts[0],1000,1000);assert(ally.healed==before);ally.alive=true;
 // Multiple doctors: one provider only, deterministic order independent of app order.
 Aura b2{&other};Application a2{&b2};buff.charges=3;ally.apps[9]=&app;ally.apps[0]=&a2;
 auto single=Launch(&ally);assert(single.doctor==1 && buff.charges==2 && b2.charges==3);
 doctor.known=false;single=Launch(&ally);assert(single.doctor==2 && b2.charges==2);doctor.known=true;
 std::mt19937 rng(136);for(int i=0;i<10000;++i){uint32 d=rng(),h=rng();auto amount=HealAmount(d,h,5);assert(amount==uint64(std::min(d,h))*5/100);}
 std::cout<<"PASS actual helper: three casts, AoE, DoT snapshot/refresh, provider ownership/lifecycle, 10000 integer caps\n";
}
'''.replace('HEADER',header)
(T/'test.cpp').write_text(test,encoding='utf8')
cmd='@echo off\nchcp 65001 >nul\ncall "D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat" >nul\n'
cmd+='cl /nologo /std:c++20 /EHsc /utf-8 /I"'+str(T)+'" "'+str(T/'test.cpp')+'" /Fe:"'+str(T/'test.exe')+'" /Fo:"'+str(T/'test.obj')+'"\nif errorlevel 1 exit /b 1\n"'+str(T/'test.exe')+'"\n'
Path('D:/000rebornWOW/wd136_runtime_test.cmd').write_text(cmd,encoding='utf8')
