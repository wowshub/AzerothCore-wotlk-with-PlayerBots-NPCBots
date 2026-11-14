#include "WoW/Common/ComponentCore/RebornCatalogAppearance.h"
#include <cassert>
#include <fstream>
#include <iostream>
#include <set>
struct R {uint32_t sex,kind,target,value,pred[3];char path[128];};
std::vector<R> read(const char* p){std::ifstream f(p,std::ios::binary);uint32_t h[3];f.read((char*)h,12);assert(f&&h[0]==0x314d4845&&h[1]==1);std::vector<R> v(h[2]);f.read((char*)v.data(),v.size()*sizeof(R));assert(f);return v;}
bool match(const R&r,const std::vector<RebornCatalog::Option>&ops,const std::array<unsigned,5>&f){for(auto p:r.pred)if(p!=0xffffffff){auto o=ops.at(p&65535);if(f[o.field]/o.factor%o.count!=(p>>16))return false;}return true;}
int main(int argc,char**argv){using namespace RebornCatalog;assert(argc==3);
 assert(Resolve(67,"Mechagnome")==Mechagnome&&Resolve(68,"Earthen")==EarthenEyes);
 assert(Resolve(67,"DrakkinHorde")==None&&Resolve(68,"EarthenHorde")==None);
 assert(Resolve(99,"DrakkinAlliance")==Tarasek&&!Enabled(Tarasek,1));
 assert(Resolve(101,"VenthyrHorde")==Venthyr&&Resolve(102,"CentaurHorde")==Centaur&&Resolve(110,"SylvariAlliance")==Vorkai);
 auto m=read(argv[1]),e=read(argv[2]);unsigned eyeCases=0,partCases=0;
 for(auto p:{Mechagnome,EarthenEyes})for(unsigned sex=0;sex<2;sex++){
  const auto&ops=Options(p,sex);assert(ops.size()==Labels(p,sex).size());auto&rows=p==Mechagnome?m:e;
  for(auto row:rows)if(row.sex==sex)for(auto pred:row.pred)if(pred!=0xffffffff){assert((pred&65535)<ops.size());assert((pred>>16)<ops[pred&65535].count);}
  std::array<unsigned,5>cap{};for(auto o:ops)cap[o.field]+=(o.count-1)*o.factor;for(auto n:cap)assert(n<256);
  unsigned eyes=p==Mechagnome?33:14,styles=p==Mechagnome?3:1,sights=4;
  for(unsigned eye=0;eye<eyes;eye++)for(unsigned style=0;style<styles;style++)for(unsigned sight=0;sight<sights;sight++){
   std::array<unsigned,5> f{};f[3]=eye*(p==Mechagnome?7:14);f[p==Mechagnome?4:1]=p==Mechagnome?style*20:sight*10;if(p==Mechagnome)f[0]=sight*24;
   unsigned matches=0;for(auto row:rows)if(row.sex==sex&&row.kind==1&&row.target==5&&match(row,ops,f))matches++;assert(matches==1);eyeCases++;
  }
 }
 for(unsigned sex=0;sex<2;sex++)for(unsigned arm=0;arm<4;arm++)for(unsigned leg=0;leg<2;leg++)for(unsigned mod=0;mod<20;mod++){
  auto&ops=Options(Mechagnome,sex);std::array<unsigned,5>f{};f[2]=arm*ops[5].factor+leg*ops[6].factor;f[4]=mod;
  std::set<unsigned>seen;for(auto row:m)if(row.sex==sex&&row.kind==0&&match(row,ops,f)){assert(seen.insert(row.target).second);if(row.target==3)assert(row.value==301+arm);if(row.target==5)assert(row.value==501+leg);}
  assert(seen.count(3)&&seen.count(5)&&seen.count(10)&&seen.count(16));partCases++;
 }
 std::cout<<"PASS actual production header: "<<eyeCases<<" eye/style/eyesight cases, "<<partCases<<" arm/leg/modification cases, real-ID guards and five-byte capacity\n";
}
