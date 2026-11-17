
#include <cassert>
#include <cstdint>
#include <array>
#include <cstdio>
struct CM2Model{std::array<unsigned,16>textures{};unsigned body=0;bool collectionBound=false;};
struct Component{struct{struct{unsigned m_raceID=109,m_sexID=0;}m_preferences;CM2Model*m_model=nullptr;}m_data;bool active=true;};
struct CGUnit_C{Component*m_characterComponent=nullptr;CM2Model*m_worldModel=nullptr;struct Unit{unsigned m_unitFieldNativedisplayid=1;}*m_unit;};
void EsteriaTraceText(const char*){}
bool RetailRaceActive(Component*c){return c&&c->active;}
struct Display{unsigned m_modelID=1;};struct ModelData{const char*m_modelName="legacy-placeholder.m2";};
using CreatureDisplayInfoRec=Display;using CreatureModelDataRec=ModelData;
struct DisplayDB{Display r;Display*GetRecord(unsigned id){return id?&r:nullptr;}}g_creatureDisplayInfoDB;
struct ModelDB{ModelData r;ModelData*GetRecord(unsigned id){return id?&r:nullptr;}}g_creatureModelDataDB;
struct Scene{CM2Model copy;unsigned duplicates=0,creates=0;CM2Model*CreateModel(const char*,int){++creates;copy={};return &copy;}CM2Model*DuplicateModel(CM2Model*src,int){++duplicates;if(!src)return nullptr;copy=*src;copy.collectionBound=false;return &copy;}};
unsigned collectionCopies=0;
void RetailRaceDuplicateCollections(CM2Model*source,CM2Model*target){assert(source&&target&&source!=target);target->collectionBound=true;++collectionCopies;}
struct CGCharacterModelBase{Scene scene;Scene*GetScene(){return &scene;}CM2Model*GetDuplicateUnitCharacterModel(CGUnit_C*);};
struct CGDressUpModelFrame:CGCharacterModelBase{unsigned m_previewSex=0;CM2Model*GetDuplicateUnitCharacterModel(CGUnit_C*);CM2Model*OldGet(CGUnit_C*);};
CM2Model* CGCharacterModelBase::GetDuplicateUnitCharacterModel(CGUnit_C* unit) {
    if (!unit) {
        return nullptr;
    }

    CM2Model* model = this->GetScene()->DuplicateModel(unit->m_worldModel, 0);
    RetailRaceDuplicateCollections(unit->m_worldModel, model);
    return model;
}CM2Model* CGDressUpModelFrame::GetDuplicateUnitCharacterModel(CGUnit_C* unit) {
    if (!unit) {
        return nullptr;
    }

    // ETHPREVIEW2A: the native-display DBC is only the legacy placeholder for
    // Ethereal. Keep the current Retail body, materials and collection rigs.
    // The base UI duplicator already restores collection skin parents.
    auto* source=unit->m_characterComponent;
    if(!this->m_previewSex&&source&&source->m_data.m_preferences.m_raceID==109
        &&RetailRaceActive(source)&&source->m_data.m_model==unit->m_worldModel) {
        static unsigned traceCount=0;
        if(traceCount++<24)EsteriaTraceText("ETHPREVIEW2A: copying active Ethereal body for DressUpModel");
        return CGCharacterModelBase::GetDuplicateUnitCharacterModel(unit);
    }

    CreatureDisplayInfoRec* display = g_creatureDisplayInfoDB.GetRecord(unit->m_unit->m_unitFieldNativedisplayid);

    if (!display) {
        return nullptr;
    }

    CreatureModelDataRec* modelData = g_creatureModelDataDB.GetRecord(display->m_modelID);

    if (!modelData) {
        return nullptr;
    }

    const char* modelName = modelData->m_modelName;

    if (!modelName || !*modelName) {
        return nullptr;
    }

    return this->GetScene()->CreateModel(modelName, 0);
}CM2Model* CGDressUpModelFrame::OldGet(CGUnit_C* unit) {
    if (!unit) {
        return nullptr;
    }

    CreatureDisplayInfoRec* display = g_creatureDisplayInfoDB.GetRecord(unit->m_unit->m_unitFieldNativedisplayid);

    if (!display) {
        return nullptr;
    }

    CreatureModelDataRec* modelData = g_creatureModelDataDB.GetRecord(display->m_modelID);

    if (!modelData) {
        return nullptr;
    }

    const char* modelName = modelData->m_modelName;

    if (!modelName || !*modelName) {
        return nullptr;
    }

    return this->GetScene()->CreateModel(modelName, 0);
}
int main(){CGDressUpModelFrame f;CGUnit_C::Unit native;Component c;CM2Model world,other;CGUnit_C u{&c,&world,&native};c.m_data.m_model=&world;unsigned cases=0;
for(unsigned sex:{0u,1u})for(unsigned body:{5926159u,6152557u,6254042u}){
 c.m_data.m_preferences.m_sexID=sex;world.body=body;for(unsigned i=0;i<16;++i)world.textures[i]=100+i+sex;auto original=world.textures;
 auto* prior=f.OldGet(&u);assert(prior->textures[11]==0&&prior->body==0); // DBC placeholder has no live bindings
 auto* model=f.GetDuplicateUnitCharacterModel(&u);assert(model!=&world&&model->body==body&&model->textures==original&&model->collectionBound);
 model->textures[11]=999;assert(world.textures==original);++cases;
}
auto creates=f.scene.creates,duplicates=f.scene.duplicates;
assert(!f.GetDuplicateUnitCharacterModel(nullptr));assert(f.scene.creates==creates);
for(unsigned race:{1u,16u,27u,102u,108u}){c.m_data.m_preferences.m_raceID=race;f.GetDuplicateUnitCharacterModel(&u);++cases;}
assert(f.scene.duplicates==duplicates);c.m_data.m_preferences.m_raceID=109;
for(unsigned previewSex:{1u,2u}){f.m_previewSex=previewSex;f.GetDuplicateUnitCharacterModel(&u);++cases;}f.m_previewSex=0;assert(f.scene.duplicates==duplicates);
c.active=false;f.GetDuplicateUnitCharacterModel(&u);c.active=true;c.m_data.m_model=&other;f.GetDuplicateUnitCharacterModel(&u);c.m_data.m_model=&world;u.m_characterComponent=nullptr;f.GetDuplicateUnitCharacterModel(&u);assert(f.scene.duplicates==duplicates);
printf("%u sex/body/isolation cases; current model/material copy + independent collection rebind; legacy/forced-human/transformed paths preserved\n",cases+4);
}
