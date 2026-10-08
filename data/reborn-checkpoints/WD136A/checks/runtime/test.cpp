#include "D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261007/codexfix_20261007_191952_阶段WD136A_调制大师施法归属/01_覆盖到源代码根目录/src/server/game/Spells/RebornWitchDoctorConcoctions.h"
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
