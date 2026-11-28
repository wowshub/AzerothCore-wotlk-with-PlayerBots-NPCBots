from pathlib import Path
W=Path('stormforged-intake/bodygear1a');s=Path('helmet-work/src/WoW/Common/ComponentCore/EsteriaAppearance.cpp').read_text('utf8')
a=s.index('static void FitStormforgedClothing(');b=s.index('static void FitStormforgedEquipment(',a)
stub=r'''
#define NOMINMAX
#include <windows.h>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <algorithm>
#include <map>
#include <cassert>
#define GetModuleFileNameA(...) 0
enum {ITEMSLOT_HEAD=0,ITEMSLOT_SHOULDER=1,ITEMSLOT_SHIRT=2,ITEMSLOT_CHEST=3,ITEMSLOT_BELT=4,ITEMSLOT_PANTS=5,ITEMSLOT_BOOTS=6,ITEMSLOT_BRACERS=7,ITEMSLOT_GLOVES=8,ITEMSLOT_TABARD=9,ITEMSLOT_CAPE=10};
struct ItemDisplayInfoRec { const char* m_texture[8]={}; int m_geosetGroup[3]={}; };
struct DB {std::map<unsigned,ItemDisplayInfoRec> records;bool GetRecord(unsigned id,ItemDisplayInfoRec* out){auto it=records.find(id);if(it==records.end())return false;*out=it->second;return true;}} g_itemDisplayInfoDB;
struct CTexture {const char* m_filename;};
struct TextureEntry {unsigned m_type;};
struct TextureArray {unsigned m_count=2;TextureEntry entries[2]={{1},{2}};const TextureEntry& operator[](unsigned i)const{return entries[i];}};
struct Data {struct{unsigned m_count;}m_vertices;TextureArray m_textures;};
struct Shared {Data* m_data;};
struct CM2Model {Shared* m_shared;CTexture** m_textures;std::map<unsigned,bool> visible;unsigned changes=0;
 void SetGeometryVisible(unsigned first,unsigned last,int v){assert(first==last);bool value=v!=0;if(visible[first]!=value){visible[first]=value;++changes;}}
 void OptimizeVisibleGeometry(){}
};
struct CCharacterComponent {struct{CM2Model* m_model;}m_data;unsigned m_itemDisplayID[11]={};void* m_baseSkinTexture=reinterpret_cast<void*>(1);unsigned m_dirtySections=0,m_flags=0;};
'''
tests=r'''
int main(){
 for(bool female:{false,true}){
  Data data{};data.m_vertices.m_count=female?14733u:13941u;Shared shared{&data};CTexture loaded{"Item/Cape/loaded.blp"},solid{"SolidTextureWhite"};CTexture* textures[2]={nullptr,&loaded};CM2Model model{&shared,textures};CCharacterComponent c{};c.m_data.m_model=&model;
  FitStormforgedClothing(&c,female);for(unsigned g=22001;g<=22008;g++)assert(!model.visible[g]);for(unsigned g=1501;g<=1510;g++)assert(!model.visible[g]);
  ItemDisplayInfoRec all{};for(unsigned i=0;i<8;i++)all.m_texture[i]="present";g_itemDisplayInfoDB.records[1]=all;c.m_itemDisplayID[ITEMSLOT_CHEST]=1;
  FitStormforgedClothing(&c,female);for(unsigned g=22001;g<=22008;g++)assert(model.visible[g]);
  unsigned changed=model.changes;for(unsigned i=0;i<500;i++)FitStormforgedClothing(&c,female);assert(model.changes==changed);
  c.m_dirtySections=0xffffffff;FitStormforgedClothing(&c,female);for(unsigned g=22001;g<=22008;g++)assert(!model.visible[g]);c.m_dirtySections=0;FitStormforgedClothing(&c,female);assert(model.visible[22001]);
  c.m_flags=1;FitStormforgedClothing(&c,female);assert(!model.visible[22001]);c.m_flags=0;
  c.m_baseSkinTexture=nullptr;FitStormforgedClothing(&c,female);assert(!model.visible[22001]);c.m_baseSkinTexture=reinterpret_cast<void*>(1);
  c.m_itemDisplayID[ITEMSLOT_CHEST]=0;c.m_itemDisplayID[ITEMSLOT_TABARD]=777;FitStormforgedClothing(&c,female);assert(model.visible[22004]&&model.visible[22005]&&!model.visible[22001]);c.m_itemDisplayID[ITEMSLOT_TABARD]=0;
  for(unsigned variant=1;variant<10;variant++){
   ItemDisplayInfoRec robe{};robe.m_geosetGroup[2]=variant;g_itemDisplayInfoDB.records[2]=robe;c.m_itemDisplayID[ITEMSLOT_CHEST]=2;FitStormforgedClothing(&c,female);
   for(unsigned j=0;j<10;j++)assert(model.visible[1301+j]==(j==variant));
  }
  c.m_itemDisplayID[ITEMSLOT_CHEST]=0;
  for(unsigned variant=0;variant<10;variant++){
   ItemDisplayInfoRec cape{};cape.m_geosetGroup[0]=variant;g_itemDisplayInfoDB.records[3]=cape;c.m_itemDisplayID[ITEMSLOT_CAPE]=3;FitStormforgedClothing(&c,female);
   for(unsigned j=0;j<10;j++)assert(model.visible[1501+j]==(j==variant));
  }
  textures[1]=&solid;FitStormforgedClothing(&c,female);for(unsigned j=0;j<10;j++)assert(!model.visible[1501+j]);textures[1]=&loaded;
  c.m_itemDisplayID[ITEMSLOT_CAPE]=0;FitStormforgedClothing(&c,female);for(unsigned j=0;j<10;j++)assert(!model.visible[1501+j]);for(unsigned j=0;j<10;j++)assert(!model.visible[1301+j]);for(unsigned j=0;j<8;j++)assert(!model.visible[22001+j]);
  data.m_vertices.m_count=123;changed=model.changes;c.m_itemDisplayID[ITEMSLOT_CHEST]=1;FitStormforgedClothing(&c,female);assert(model.changes==changed);
 }
 std::puts("PASS: production clothing function; both sexes; equip/unequip; pending/ready; all cloak groups; all robe groups; wrong rig; 500 repeated refreshes without visibility churn");
}
'''
(W/'checks/runtime-tests.cpp').write_text(stub+s[a:b]+tests,'utf8')
(W/'checks/build-runtime-tests.bat').write_text('@echo off\ncall "D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat" >nul\nif errorlevel 1 exit /b 1\ncl /nologo /EHsc /std:c++17 runtime-tests.cpp /Fe:runtime-tests.exe\nif errorlevel 1 exit /b 1\nruntime-tests.exe\n','ascii')
print('Extracted production clothing function into runtime fixture')
