// NEUTRAL3A: private, skin-parented equipment overlay. The authored body is untouched.
struct NeutralClothingState {
    CM2Model* model=nullptr;
    Fields13 fields{};
    std::array<unsigned,12> gear{};
    std::uint64_t layers=0;
    std::shared_ptr<void> texture;
    std::shared_ptr<void> capeTexture;
    unsigned capeDisplay=0;
    bool pending=false;
    unsigned decodeRetries=0;
    std::uint64_t nextDecodeRetry=0;
};
std::unordered_map<CCharacterComponent*,NeutralClothingState> neutralClothing;
bool NeutralNeedsOwnCape(CCharacterComponent* c) {
    if(!c->m_itemDisplayID[ITEMSLOT_CAPE])return false;
    auto* model=c->m_data.m_model;auto* data=model->m_shared->m_data;
    auto* skin=model->m_shared->m_skinData;bool texture=false,geometry=false;
    for(unsigned n=0;n<data->m_textures.m_count;++n)texture=texture||data->m_textures[n].m_type==2;
    if(skin)for(unsigned n=0;n<skin->m_skinSections.m_count;++n) {
        unsigned id=skin->m_skinSections[n].m_skinSectionId&0xffff;
        geometry=geometry||(id>=1501&&id<1600);
    }
    return !texture||!geometry;
}
struct NeutralFormWarmup {
    std::vector<std::shared_ptr<CM2Model>> models;
    std::vector<std::shared_ptr<void>> textures;
};
std::unordered_map<CCharacterComponent*,NeutralFormWarmup> neutralFormWarmup;
void WarmNeutralDruidForm(CCharacterComponent* c) {
    auto const& p=c->m_data.m_preferences;
    if(p.m_raceID!=112||p.m_classId!=11||neutralFormWarmup.count(c))return;
    auto& warm=neutralFormWarmup[c];auto* form=g_spellShapeshiftFormDB.GetRecord(1);
    if(!form)return;
    // Request model and palette without RenderPrep(1), sleeps or waiting for GPU.
    // The normal model/texture caches can finish these while the player is idle.
    std::unordered_set<unsigned> displays;
    for(auto id:form->m_creatureDisplayID)if(id>0)displays.insert(id);
    if(displays.empty())displays.insert(892);
    for(auto id:displays) {
        auto* display=g_creatureDisplayInfoDB.GetRecord(id);if(!display)continue;
        auto* model=g_creatureModelDataDB.GetRecord(display->m_modelID);if(!model||!model->m_modelName)continue;
        std::string path=model->m_modelName;auto ext=path.find_last_of('.');if(ext!=std::string::npos)path.resize(ext);path+=".m2";
        auto* instance=c->m_data.m_model->m_scene->CreateModel(path.c_str(),0);
        if(instance) {
            instance->SetRenderSuppressed(true);instance->m_fadeAlpha=0.0f;
            warm.models.emplace_back(instance,[](CM2Model* m){m->Release();});
        }
        auto slash=path.find_last_of("\\/");std::string folder=slash==std::string::npos?"":path.substr(0,slash+1);
        for(auto texture:display->m_textureVariation) {
            if(!texture||!*texture)continue;
            std::string file=texture;if(file.find_first_of("\\/")==std::string::npos)file=folder+file;
            if(file.find_last_of('.')==std::string::npos)file+=".blp";
            CStatus status;if(auto* image=CreateTexture(file.c_str(),&status))
                warm.textures.emplace_back(image,[](void* t){HandleClose(reinterpret_cast<HOBJECT>(t));});
        }
    }
}

bool ScopedClothingRace(unsigned race) {
    return race==76||race==89||race==90||race==112;
}

bool HasNeutralClothingRig(CCharacterComponent* c) {
    if(!c||!c->m_data.m_model||!c->m_data.m_model->m_shared)return false;
    auto* data=c->m_data.m_model->m_shared->m_data;if(!data)return false;
    const auto& prefs=c->m_data.m_preferences;
    // Fungarian's body mesh is rewritten by the model loader. Pose binding
    // checks the complete parent/child skeleton; use the known rig file, not
    // the mutable count of flattened vertices, to admit this one model.
    const char* file=c->m_data.m_model->m_shared->m_fileName;
    if(prefs.m_raceID==93&&prefs.m_sexID==0&&data->m_bones.m_count==127&&
       (!_stricmp(file,"Creature\\Fungarian\\FungarianPlayer.m2")
        ||!_stricmp(file,"Creature/Fungarian/FungarianPlayer.m2")))return true;
    // Match the actual playable asset even when an LOD rewrites the live
    // vertex count. SetSkinParent still verifies the authored skeleton.
    struct NamedRig {unsigned race,sex,bones;const char* path;};
    static const NamedRig scoped[]={
        {76,0,72,"creature\\sporeling\\sporelingplayer.m2"},
        {89,0,78,"creature\\dreadlord\\dreadlordplayerfemale.m2"},
        {90,1,156,"creature\\banshee\\bansheeplayer.m2"},
        {112,0,141,"custom\\hozen\\unknown\\536927.m2"},
    };
    if(ScopedClothingRace(prefs.m_raceID)) {
        std::string path=file;
        std::replace(path.begin(),path.end(),'/',char(92));
        for(const auto& rig:scoped)
            if(prefs.m_raceID==rig.race&&(prefs.m_sexID==rig.sex||rig.race==90||rig.race==112)&&data->m_bones.m_count==rig.bones
                &&!_stricmp(path.c_str(),rig.path))return true;
    }
    struct Rig {unsigned race,sex,bones,vertices;};
    static const Rig rigs[]={
    {76,0,72,1349},
    {89,0,78,6407},
    {90,1,156,965},
    {93,0,127,5825},
    {97,0,119,25656},
    {97,0,119,22252}, // CPU skin profile flattening

    {98,0,181,33464},
    {98,0,181,12232}, // CPU skin profile flattening

    {106,0,128,20464},
    {112,0,141,41496},
    {114,0,153,6323},
    };
    for(auto const& r:rigs)if(c->m_data.m_preferences.m_raceID==r.race&&c->m_data.m_preferences.m_sexID==r.sex
        &&data->m_bones.m_count==r.bones&&data->m_vertices.m_count==r.vertices)return true;
    return false;
}
std::uint64_t NeutralClothingLayerKey(const EquipmentSourceState& sources) {
    std::uint64_t key=14695981039346656037ull;
    for(auto const& row:sources.rows)for(unsigned layer=0;layer<7;++layer) {
        const auto id=row.m_layerItemDisplayId[layer];
        key=(key^id)*1099511628211ull;
        if(id)key=(key^((row.m_layerMask>>layer)&1u))*1099511628211ull;
    }
    return key;
}
std::uint64_t NeutralClothingLayerKey(CCharacterComponent* c) {
    return NeutralClothingLayerKey(OutfitSources(c));
}
bool NeutralClothingBound(CCharacterComponent* c) {
    auto i=neutralClothing.find(c);if(i==neutralClothing.end()||i->second.model!=c->m_data.m_model||i->second.pending)return false;
    // NEUTRAL3C: a cached body can receive new items without replacing the actor.
    if(i->second.fields!=FieldsOf(c)||!std::equal(i->second.gear.begin(),i->second.gear.end(),c->m_itemDisplayID)
        ||i->second.layers!=NeutralClothingLayerKey(c))return false;
    if(i->second.nextDecodeRetry && GetTickCount64() >= i->second.nextDecodeRetry) return false;
    if(!i->second.texture&&!NeutralNeedsOwnCape(c))return true;
    for(auto* child=c->m_data.m_model->m_attachList;child;child=child->m_attachNext)
        if(child->m_attachmentId==0xee003a00u) {
            if(!child->HasSkinParent(c->m_data.m_model)||!child->IsDrawable(0,0))return false;
            auto bound=[&](unsigned type,void* expected) {
                auto* data=child->m_shared?child->m_shared->m_data:nullptr;
                if(!data||!child->m_textures||!expected)return false;
                for(unsigned n=0;n<data->m_textures.m_count;++n)
                    if(data->m_textures[n].m_type==type&&child->m_textures[n]==reinterpret_cast<CTexture*>(expected))
                        return TextureGetGxTex(child->m_textures[n],0,nullptr)!=nullptr;
                return false;
            };
            if(i->second.texture&&!bound(14,i->second.texture.get()))return false;
            auto* skin=child->m_shared?child->m_shared->m_skinData:nullptr;
            if(!skin||!child->m_skinSections)return false;
            for(unsigned n=0;n<skin->m_skinSections.m_count;++n)
                if(i->second.texture&&(skin->m_skinSections[n].m_skinSectionId&0xffff)==1&&!child->m_skinSections[n])return false;
            if(NeutralNeedsOwnCape(c)&&(!i->second.capeTexture||i->second.capeDisplay!=c->m_itemDisplayID[ITEMSLOT_CAPE]))return false;
            if(NeutralNeedsOwnCape(c)&&!bound(2,i->second.capeTexture.get()))return false;
            return true;
        }
    return false;
}
void BindNeutralClothing(CCharacterComponent* c) {
    if(!HasNeutralClothingRig(c)) {
        if(c->m_data.m_preferences.m_raceID!=102) TraceClothingBind(c,ClothingBindStage::WrongRig);
        return;
    }
    auto* parent=c->m_data.m_model;
    if(!(parent->m_fFlags&1))return;
    WarmNeutralDruidForm(c);
    auto& state=neutralClothing[c];auto fields=FieldsOf(c);
    const auto race=c->m_data.m_preferences.m_raceID;
    const bool isolated=ScopedClothingRace(race)||race==93;
    std::array<unsigned,12> gear{};std::copy_n(c->m_itemDisplayID,12,gear.begin());
    constexpr unsigned socket=0xee003a00u;
    auto childOf=[&](){CM2Model* child=parent->m_attachList;while(child&&child->m_attachmentId!=socket)child=child->m_attachNext;return child;};
    auto bind=[&](){
        auto* child=childOf();
        const bool ownCape=NeutralNeedsOwnCape(c);
        if(!state.texture&&!ownCape){if(child)parent->DetachAllChildrenById(socket);state.capeTexture.reset();state.capeDisplay=0;return true;}
        if(!child) {
            char path[160]{};
            // Banshee and Hozen each have a single visual rig during Glue updates.
            const auto visualSex = race==90 ? 1u : race==112 ? 0u : c->m_data.m_preferences.m_sexID;
            sprintf_s(path,"custom/rebornfit/neutral/%u/%u/clothing.m2",race,visualSex);
            child=parent->m_scene->CreateModel(path, (isolated || race==114) ? ClothingCacheByFullPath : 0);
            if(!child)return false;
            child->SetGeometryVisible(0,65535,0);child->AttachToParent(parent,socket,nullptr,1);child->Release();
        }
        child->LinkToAsyncHead(1);
        if(!(child->m_fFlags&1)) {
            TraceClothingBind(c,ClothingBindStage::ChildPending);
            return false;
        }
        if(!child->SetSkinParent(parent)) {
            TraceClothingBind(c,ClothingBindStage::SkinRejected);
            return false;
        }
        if(state.texture)child->ReplaceTexture(14,reinterpret_cast<CTexture*>(state.texture.get()));
        child->SetGeometryVisible(0,65535,0);child->SetGeometryVisible(1,1,state.texture?1:0);
        bool capeReady=true;
        if(ownCape) {
            unsigned id=c->m_itemDisplayID[ITEMSLOT_CAPE];
            if(state.capeDisplay!=id||!state.capeTexture) {
                state.capeTexture.reset();state.capeDisplay=0;ItemDisplayInfoRec item{};
                if(g_itemDisplayInfoDB.GetRecord(id,&item)&&*item.m_modelTexture[0]) {
                    char path[512]{};sprintf_s(path,"Item/ObjectComponents/Cape/%s.blp",item.m_modelTexture[0]);
                    CStatus status;if(auto* texture=CreateTexture(path,&status)) {
                        state.capeTexture=std::shared_ptr<void>(texture,[](void* t){HandleClose(reinterpret_cast<HOBJECT>(t));});
                        state.capeDisplay=id;
                    }
                }
            }
            capeReady=state.capeTexture&&TextureGetGxTex(reinterpret_cast<CTexture*>(state.capeTexture.get()),0,nullptr);
            // IsDrawable checks even textures on hidden sections. Delay
            // installing the optional cape until it cannot block the body.
            if(state.capeTexture&&(!isolated||capeReady))
                child->ReplaceTexture(2,reinterpret_cast<CTexture*>(state.capeTexture.get()));
            child->SetGeometryVisible(1501,1501,capeReady?1:0);
        } else {state.capeTexture.reset();state.capeDisplay=0;}
        const bool drawable=child->IsDrawable(0,0)!=0;
        if(c->m_data.m_preferences.m_raceID==114) {
            // The original optional meshes are painted with the fixed green skin.
            // Use their real geosets on the equipment layer, retaining the bare skeleton.
            for(unsigned geo:{402u,403u,502u,1302u}) {
                bool selected=false;for(auto current:c->m_data.m_geosets)selected=selected||current==geo;
                // Stock GeosRenderPrep selects robe/glove/boot styles directly on
                // the model; m_geosets is not a snapshot of that final selection.
                ItemDisplayInfoRec item{};
                const unsigned slot=geo/100==4?ITEMSLOT_GLOVES:geo/100==5?ITEMSLOT_BOOTS:ITEMSLOT_CHEST;
                if(c->m_itemDisplayID[slot]&&g_itemDisplayInfoDB.GetRecord(c->m_itemDisplayID[slot],&item))
                    selected=selected||geo==(geo/100==13?1301u+item.m_geosetGroup[2]:geo/100*100+1+item.m_geosetGroup[0]);
                if(geo==1302&&!selected&&c->m_itemDisplayID[ITEMSLOT_PANTS]
                    &&g_itemDisplayInfoDB.GetRecord(c->m_itemDisplayID[ITEMSLOT_PANTS],&item))
                    selected=item.m_geosetGroup[2]==1;
                child->SetGeometryVisible(geo,geo,selected?1:0);
                if(drawable&&selected)parent->SetGeometryVisible(geo,geo,0);
            }
        }
        // The private sheet has only two batches. Draw the authored
        // sections directly for these rigs to avoid re-packing the
        // palette and binding while the asynchronous child is settling.
        if(isolated)child->UnoptimizeVisibleGeometry();
        else child->OptimizeVisibleGeometry();
        if(state.texture) TraceClothingBind(c,drawable?ClothingBindStage::Bound:ClothingBindStage::DevicePending);
        return drawable&&capeReady;
    };
    auto& sources=OutfitSources(c);
    const auto layerKey=NeutralClothingLayerKey(sources);
    const bool sameOutfit=state.model==parent&&state.fields==fields&&state.gear==gear&&state.layers==layerKey;
    const bool retryDecode=isolated&&race!=90;
    if(!sameOutfit) {
        state.decodeRetries=0;
        state.nextDecodeRetry=0;
    }
    if(sameOutfit && (!state.nextDecodeRetry || GetTickCount64() < state.nextDecodeRetry)) {
        state.pending=!bind();return;
    }
    bool equipped=false;for(auto slot:{ITEMSLOT_CHEST,ITEMSLOT_SHIRT,ITEMSLOT_TABARD,ITEMSLOT_PANTS,ITEMSLOT_GLOVES,ITEMSLOT_BOOTS,ITEMSLOT_BELT,ITEMSLOT_BRACERS})equipped=equipped||gear[slot]!=0;
    if(!equipped) {
        state.model=parent;state.fields=fields;state.gear=gear;state.layers=layerKey;state.texture.reset();state.pending=!bind();return;
    }
    // Each source may finish in a different frame. Commit the available layers;
    // the key includes each ready bit, so a later layer triggers recomposition.
    std::vector<unsigned char> pixels(512u*512u*4u,0);
    constexpr unsigned counts[]={2,7,1,5,7,3,6,1};
    unsigned painted=0;
    bool decodeIncomplete=false;
    for(unsigned region=0;region<8;++region) {
        auto const& row=sources.rows[region];auto const& rect=CCharacterComponent::s_sectionInfoRaw[region];
        for(unsigned layer=0;layer<counts[region];++layer) {
            // Never project skin/face/underwear into a garment.
            if(!row.m_layerItemDisplayId[layer])continue;
            // Only use layers with finished mip data.
            if(!(row.m_layerMask&(1u<<layer)))continue;
            NativePixelSource source;
            if(!SelectorLayerPixels(row.m_layerTex[layer],source)) {
                decodeIncomplete=true;
                KTrace("cloth-decode","race=%u display=%u region=%u layer=%u",
                    c->m_data.m_preferences.m_raceID,row.m_layerItemDisplayId[layer],region,layer);
                continue;
            }
            auto const& data=source.levels[0];unsigned width=source.Word(12),height=source.Word(16);
            for(unsigned y=0;y<unsigned(rect.m_size.y);++y)for(unsigned x=0;x<unsigned(rect.m_size.x);++x)
                SelectorOver(pixels.data()+4*((rect.m_pos.y+y)*512+rect.m_pos.x+x),data.data()+4*((y*height/rect.m_size.y)*width+x*width/rect.m_size.x));
            ++painted;
        }
    }
    if(c->m_data.m_preferences.m_raceID==93) {
        static unsigned reports=0;
        if(reports<40) {
            ++reports;
            KTrace("cloth-93","model=%s vertices=%u chest=%u pants=%u layers=%u complete=%u",
                parent->m_shared->m_fileName,parent->m_shared->m_data->m_vertices.m_count,
                gear[ITEMSLOT_CHEST],gear[ITEMSLOT_PANTS],painted,unsigned(sources.ready));
        }
    }
    // A source can pass the mip check before its bytes can be decoded.
    // Allow a few paced rebuilds without blocking clothing from other layers.
    if(retryDecode && decodeIncomplete && state.decodeRetries < 3) {
        ++state.decodeRetries;
        state.nextDecodeRetry=GetTickCount64()+500;
    } else {
        state.nextDecodeRetry=0;
    }
    if(!painted) {
        if(sources.ready) TraceClothingBind(c,ClothingBindStage::NoAtlas);
        // Some slots have geometry only. No painted layers is a valid result,
        // not an infinite pending state which hides the selected character.
        state.model=parent;state.fields=fields;state.gear=gear;state.layers=layerKey;state.texture.reset();state.pending=!bind();return;
    }
    std::uint64_t hash=14695981039346656037ull;for(auto v:pixels)hash=(hash^v)*1099511628211ull;
    char name[160]{};sprintf_s(name,"RebornNeutralCloth-%u-%u-%016llx",c->m_data.m_preferences.m_raceID,c->m_data.m_preferences.m_sexID,static_cast<unsigned long long>(hash));
    auto texture=NativeTexture(name,pixels,512,512,true);if(!texture){state.pending=true;return;}
    state.model=parent;state.fields=fields;state.gear=gear;state.layers=layerKey;state.texture=std::move(texture);state.pending=!bind();
}
// The initial world actor may finish loading after its one-shot geometry pass.
// Retry catalog materials on actual readiness, including naked/new actors.
bool NeutralCatalogNeedsBind(CCharacterComponent* c) {
    if(!HasNeutralClothingRig(c))return false; // Never bind original skin onto a shapeshift rig.
    if(!c||!c->m_data.m_model||!c->m_data.m_model->m_shared||!c->m_data.m_model->m_shared->m_data)return false;
    auto profile=RebornCatalogProfile(c->m_data.m_preferences.m_raceID);
    if(profile!=RebornCatalog::Drakonid&&profile!=RebornCatalog::Saberon&&profile!=RebornCatalog::Hozen&&profile!=RebornCatalog::Mantid&&profile!=RebornCatalog::Banshee)return false;
    auto* model=c->m_data.m_model;auto* data=model->m_shared->m_data;
    if(!(model->m_fFlags&1)||!model->m_textures)return true;
    for(unsigned i=0;i<data->m_textures.m_count;++i) {
        auto type=data->m_textures[i].m_type;
        if(type!=11)continue;
        auto* texture=model->m_textures[i];
        if(!texture||!std::strncmp(texture->m_filename,"SolidTexture",12)||!TextureGetGxTex(texture,0,nullptr))return true;
    }
    return false;
}
