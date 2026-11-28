
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
static void FitStormforgedClothing(CCharacterComponent* character, bool female) {
    auto* model = character->m_data.m_model;
    const auto* data = model->m_shared->m_data;
    if (data->m_vertices.m_count != (female ? 14733u : 13941u)) return;
    uint32_t coverage = 0;
    for (unsigned slot = 2; slot <= 9; ++slot) {
        ItemDisplayInfoRec item{};
        if (!character->m_itemDisplayID[slot] || !g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[slot], &item)) continue;
        for (unsigned region = 0; region < 8; ++region)
            if (item.m_texture[region] && *item.m_texture[region]) coverage |= 1u << region;
    }
    if (character->m_itemDisplayID[ITEMSLOT_TABARD]) coverage |= (1u << 3) | (1u << 4);
    ItemDisplayInfoRec chest{}, pants{}, cape{};
    unsigned robe = 0;
    if (character->m_itemDisplayID[ITEMSLOT_CHEST] && g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[ITEMSLOT_CHEST], &chest))
        robe = chest.m_geosetGroup[2];
    if (!robe && !(character->m_flags & 0x20) && character->m_itemDisplayID[ITEMSLOT_PANTS]
        && g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[ITEMSLOT_PANTS], &pants)) robe = pants.m_geosetGroup[2];
    if (robe) coverage |= (1u << 5) | (1u << 6);
    const bool ready = character->m_baseSkinTexture && !character->m_dirtySections && !(character->m_flags & 1);
    for (unsigned region = 0; region < 8; ++region)
        model->SetGeometryVisible(22001u + region, 22001u + region, ready && (coverage & (1u << region)) ? 1 : 0);
    for (unsigned variant = 0; variant < 10; ++variant)
        model->SetGeometryVisible(1301u + variant, 1301u + variant, ready && robe && variant == std::min(robe, 9u) ? 1 : 0);
    unsigned capeVariant = 0;
    bool hasCape = character->m_itemDisplayID[ITEMSLOT_CAPE]
        && g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[ITEMSLOT_CAPE], &cape);
    if (hasCape) capeVariant = std::min(static_cast<unsigned>(cape.m_geosetGroup[0]), 9u);
    bool capeReady = false;
    if (hasCape && model->m_textures) {
        for (unsigned i = 0; i < data->m_textures.m_count; ++i)
            if (data->m_textures[i].m_type == 2 && model->m_textures[i]
                && std::strncmp(model->m_textures[i]->m_filename, "SolidTexture", 12)) capeReady = true;
    }
    for (unsigned variant = 0; variant < 10; ++variant)
        model->SetGeometryVisible(1501u + variant, 1501u + variant, capeReady && variant == capeVariant ? 1 : 0);
    // No incremental offsets/scales, no resetting the whole body on retries.
    model->OptimizeVisibleGeometry();
    static uint64_t last[2] = {~uint64_t{0},~uint64_t{0}};
    static unsigned lines[2] = {};
    const uint64_t key = coverage | (uint64_t(ready) << 8) | (uint64_t(robe) << 9)
        | (uint64_t(capeReady) << 25) | (uint64_t(capeVariant) << 26);
    if (last[female] != key && lines[female] < 64) {
        last[female] = key; char path[MAX_PATH] = {};
        if (GetModuleFileNameA(nullptr,path,MAX_PATH)) {
            char* slash = strrchr(path,'\\');
            if (slash) {
                strcpy(slash+1,"StormforgedClothing.log"); FILE* f = nullptr;
                if (!fopen_s(&f,path,"a") && f) {
                    fprintf(f,"BODY1A sex=%u vertices=%u coverage=%02X ready=%u robe=%u cape=%u capeVariant=%u dirty=%08X\n",
                        female?1u:0u,data->m_vertices.m_count,coverage,ready?1u:0u,robe,capeReady?1u:0u,capeVariant,character->m_dirtySections);
                    fclose(f); ++lines[female];
                }
            }
        }
    }
}


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
