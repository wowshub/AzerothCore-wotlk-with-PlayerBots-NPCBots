# C_native_test.cpp 逐行读法
原件见03_代码原件；这里每行引用真实代码。空行只起分隔作用。下述是历史构建/测试代码，别直接向运行端执行。

**第1行**
```
#include "WoW/Common/ComponentCore/RebornCatalogAppearance.h"
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第2行**
```
#include <cassert>
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第3行**
```
#include <fstream>
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第4行**
```
#include <iostream>
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第5行**
```
#include <set>
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第6行**
```
struct R {uint32_t sex,kind,target,value,pred[3];char path[128];};
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第7行**
```
std::vector<R> read(const char* p){std::ifstream f(p,std::ios::binary);uint32_t h[3];f.read((char*)h,12);assert(f&&h[0]==0x314d4845&&h[1]==1);std::vector<R> v(h[2]);f.read((char*)v.data(),v.size()*sizeof(R));assert(f);return v;}
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第8行**
```
bool match(const R&r,const std::vector<RebornCatalog::Option>&ops,const std::array<unsigned,5>&f){for(auto p:r.pred)if(p!=0xffffffff){auto o=ops.at(p&65535);if(f[o.field]/o.factor%o.count!=(p>>16))return false;}return true;}
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第9行**
```
int main(int argc,char**argv){using namespace RebornCatalog;assert(argc==3);
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第10行**
```
 assert(Resolve(67,"Mechagnome")==Mechagnome&&Resolve(68,"Earthen")==EarthenEyes);
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 同时核对真实ID和身份token，防止同号异族被错误接管。

**第11行**
```
 assert(Resolve(67,"DrakkinHorde")==None&&Resolve(68,"EarthenHorde")==None);
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 同时核对真实ID和身份token，防止同号异族被错误接管。

**第12行**
```
 assert(Resolve(99,"DrakkinAlliance")==Tarasek&&!Enabled(Tarasek,1));
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 同时核对真实ID和身份token，防止同号异族被错误接管。

**第13行**
```
 assert(Resolve(101,"VenthyrHorde")==Venthyr&&Resolve(102,"CentaurHorde")==Centaur&&Resolve(110,"SylvariAlliance")==Vorkai);
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 同时核对真实ID和身份token，防止同号异族被错误接管。

**第14行**
```
 auto m=read(argv[1]),e=read(argv[2]);unsigned eyeCases=0,partCases=0;
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第15行**
```
 for(auto p:{Mechagnome,EarthenEyes})for(unsigned sex=0;sex<2;sex++){
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第16行**
```
  const auto&ops=Options(p,sex);assert(ops.size()==Labels(p,sex).size());auto&rows=p==Mechagnome?m:e;
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第17行**
```
  for(auto row:rows)if(row.sex==sex)for(auto pred:row.pred)if(pred!=0xffffffff){assert((pred&65535)<ops.size());assert((pred>>16)<ops[pred&65535].count);}
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第18行**
```
  std::array<unsigned,5>cap{};for(auto o:ops)cap[o.field]+=(o.count-1)*o.factor;for(auto n:cap)assert(n<256);
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 累计每个基础字段的最大编码值，必须小于256，避免一字节溢出。

**第19行**
```
  unsigned eyes=p==Mechagnome?33:14,styles=p==Mechagnome?3:1,sights=4;
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第20行**
```
  for(unsigned eye=0;eye<eyes;eye++)for(unsigned style=0;style<styles;style++)for(unsigned sight=0;sight<sights;sight++){
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第21行**
```
   std::array<unsigned,5> f{};f[3]=eye*(p==Mechagnome?7:14);f[p==Mechagnome?4:1]=p==Mechagnome?style*20:sight*10;if(p==Mechagnome)f[0]=sight*24;
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第22行**
```
   unsigned matches=0;for(auto row:rows)if(row.sex==sex&&row.kind==1&&row.target==5&&match(row,ops,f))matches++;assert(matches==1);eyeCases++;
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 统计满足条件的配方条数；应恰好1，0是缺配方，大于1是歧义。

**第23行**
```
  }
```
结束当前函数、分支或结构；作用范围到这里为止。

**第24行**
```
 }
```
结束当前函数、分支或结构；作用范围到这里为止。

**第25行**
```
 for(unsigned sex=0;sex<2;sex++)for(unsigned arm=0;arm<4;arm++)for(unsigned leg=0;leg<2;leg++)for(unsigned mod=0;mod<20;mod++){
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第26行**
```
  auto&ops=Options(Mechagnome,sex);std::array<unsigned,5>f{};f[2]=arm*ops[5].factor+leg*ops[6].factor;f[4]=mod;
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第27行**
```
  std::set<unsigned>seen;for(auto row:m)if(row.sex==sex&&row.kind==0&&match(row,ops,f)){assert(seen.insert(row.target).second);if(row.target==3)assert(row.value==301+arm);if(row.target==5)assert(row.value==501+leg);}
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第28行**
```
  assert(seen.count(3)&&seen.count(5)&&seen.count(10)&&seen.count(16));partCases++;
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第29行**
```
 }
```
结束当前函数、分支或结构；作用范围到这里为止。

**第30行**
```
 std::cout<<"PASS actual production header: "<<eyeCases<<" eye/style/eyesight cases, "<<partCases<<" arm/leg/modification cases, real-ID guards and five-byte capacity\n";
```
输出已执行的断言案例计数，不是游戏渲染通过证明。

**第31行**
```
}
```
结束当前函数、分支或结构；作用范围到这里为止。
