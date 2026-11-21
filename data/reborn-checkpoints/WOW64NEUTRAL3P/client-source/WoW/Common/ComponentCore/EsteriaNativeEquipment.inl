// BODY1C: local Kyrian=108; Venthyr=76 unchanged. Four-slot cache uses explicit family index.
// Adapted from the approved 20261021 Kyrian/Venthyr equipment fit.

// Pixel decoding and GPU texture ownership use the existing Esteria compositor.
std::vector<unsigned char> NativeBlpData(char const* path) {
    void* data = nullptr;
    unsigned size = 0;
    if (!SFileLoadFileEx(nullptr, path, &data, &size, 0, 0, nullptr)) return {};
    auto* first = static_cast<unsigned char*>(data);
    std::vector<unsigned char> result(first, first + size);
    SFileUnloadFile(data);
    return result;
}
struct NativePixelSource {
    std::vector<unsigned char> bytes;
    std::array<std::vector<unsigned char>, 1> levels;
    unsigned Word(unsigned offset) const {
        unsigned value = 0;
        if (offset <= bytes.size() && bytes.size() - offset >= sizeof(value))
            std::memcpy(&value, bytes.data() + offset, sizeof(value));
        return value;
    }
    bool Mip(unsigned level, unsigned& pitch, void*& pixels) {
        if (level || bytes.size() < 148) return false;
        auto* header = reinterpret_cast<BLPHeader const*>(bytes.data());
        if (header->m_magic != 0x32504c42 || !header->m_width || !header->m_height
            || header->m_width > 2048 || header->m_height > 2048) return false;
        auto& decoded = levels[0];
        if (header->m_colorEncoding == 2) {
            if (!DecodeDxtBlp(header, static_cast<unsigned>(bytes.size()), decoded)) return false;
        } else {
            decoded.resize(header->m_width * header->m_height * 4);
            for (unsigned y = 0; y < header->m_height; ++y)
                for (unsigned x = 0; x < header->m_width; ++x)
                    if (!ClothingPixel(header, static_cast<unsigned>(bytes.size()), x, y,
                        decoded.data() + 4 * (y * header->m_width + x))) return false;
        }
        pitch = header->m_width * 4; pixels = decoded.data(); return true;
    }
};
bool SelectorLayerPixels(void* handle, NativePixelSource& source) {
    TCTEXTUREINFO info{};
    if (!handle || !TextureCacheGetInfo(handle, info, 0)) return false;
    auto* entry = static_cast<CACHEENTRY*>(handle);
    if (!entry->m_data || entry->m_loadFailed || entry->m_size < 148) return false;
    auto* first = reinterpret_cast<unsigned char const*>(entry->m_data);
    source.bytes.assign(first, first + entry->m_size);
    unsigned pitch = 0; void* pixels = nullptr;
    return source.Mip(0, pitch, pixels);
}
std::shared_ptr<void> NativeTexture(char const* name, std::vector<unsigned char> const& pixels,
    unsigned width, unsigned height, bool resident = false) {
    std::vector<unsigned char> blp;
    if (!BuildBlp(pixels, width, height, false, false, blp)) return {};
    CGxTexFlags flags(GxTex_LinearMipNearest, 0, 0, 0, 0, 0, 1);
    auto* texture = resident ? TextureCreateResidentBlp(name, flags, blp.data(), blp.size())
                             : TextureCreateFromBlpData(name, flags, blp.data());
    return std::shared_ptr<void>(texture, [](void* value) {
        if (value) HandleClose(reinterpret_cast<HOBJECT>(value));
    });
}
#include "RebornEquipmentLayers.inl"

// Native body fitting preserves the creature atlas and applies player clothing
// through a UV map. Hair and wings retain their authored replacement channels.
struct SelectorOutfit {
    CM2Model* model=nullptr;
    std::array<unsigned,12> gear{};
    Fields13 fields{};
    std::uint64_t layers=0;
    std::shared_ptr<void> texture;
    std::shared_ptr<void> robeTexture;
    std::shared_ptr<void> capeTexture;
    unsigned capeDisplay=0;
    bool hasRobe=false;
    bool hasShoes=false;
    bool hasGreaves=false;
    bool hasGloves=false;
    unsigned gloveStyle=0;
    unsigned bootStyle=0;
    std::uint64_t hash=0;
};
std::unordered_map<CCharacterComponent*,SelectorOutfit> selectorOutfits;
std::unordered_set<CCharacterComponent*> pendingSelectorBind;

bool SelectorTextureBound(CM2Model* model,unsigned type,void* expected) {
    auto* data=model&&model->m_shared?model->m_shared->m_data:nullptr;
    if(!data||!model->m_textures||!expected)return false;
    for(unsigned n=0;n<data->m_textures.m_count;++n)
        if(data->m_textures[n].m_type==type&&model->m_textures[n]==reinterpret_cast<CTexture*>(expected))
            return TextureGetGxTex(model->m_textures[n],0,nullptr)!=nullptr;
    return false;
}

void SelectorOver(unsigned char* dst,unsigned char const* src) {
    unsigned a=src[3],prior=dst[3],total=a*255+prior*(255-a);
    for(unsigned channel=0;channel<3;++channel)
        dst[channel]=static_cast<unsigned char>(total?(src[channel]*a*255+dst[channel]*prior*(255-a)+total/2)/total:0);
    dst[3]=static_cast<unsigned char>((total+127)/255);
}
bool SealNativeBootFoot(std::vector<unsigned char>& pixels,int stride=512,int scale=1) {
    // Extend the authored boot colors to the foot chart border. This prevents
    // a transparent edge from exposing the baked foot/shoe underneath the shell.
    int const width=256*scale,height=64*scale,left=256*scale,top=448*scale;
    std::vector<int> rows(height,-1);
    for(int y=0;y<height;++y) {
        std::vector<int> valid;
        auto* row=pixels.data()+4*((top+y)*stride+left);
        for(int x=0;x<width;++x)if(row[4*x+3]>=128)valid.push_back(x);
        if(valid.empty())continue;
        rows[y]=y;
        auto original=std::vector<unsigned char>(row,row+4*width);
        for(int x=0;x<width;++x) {
            if(row[4*x+3]<128) {
                int nearest=valid[0];
                for(auto candidate:valid)if(std::abs(candidate-x)<std::abs(nearest-x))nearest=candidate;
                std::copy_n(original.data()+4*nearest,3,row+4*x);
            }
            row[4*x+3]=255;
        }
    }
    bool any=false;for(auto row:rows)any=any||row>=0;if(!any)return false;
    for(int y=0;y<height;++y)if(rows[y]<0) {
        int nearest=-1;for(int i=0;i<height;++i)if(rows[i]>=0&&(nearest<0||std::abs(i-y)<std::abs(nearest-y)))nearest=i;
        std::copy_n(pixels.data()+4*((top+nearest)*stride+left),4*width,pixels.data()+4*((top+y)*stride+left));
    }
    return true;
}
void ExtendNativeClothRegion(std::vector<unsigned char>& pixels,int left,int top,int width,int height,int stride=512) {
    std::vector<int> columns(width,-1);
    for(int x=0;x<width;++x) {
        std::vector<int> rows;
        for(int y=0;y<height;++y)if(pixels[4*((top+y)*stride+left+x)+3]>=160)rows.push_back(y);
        if(rows.empty())continue;columns[x]=x;
        for(int y=0;y<height;++y) {
            auto* dst=pixels.data()+4*((top+y)*stride+left+x);
            if(dst[3]>=160)continue;
            int nearest=rows[0];for(auto row:rows)if(std::abs(row-y)<std::abs(nearest-y))nearest=row;
            std::copy_n(pixels.data()+4*((top+nearest)*stride+left+x),4,dst);dst[3]=255;
        }
    }
    for(int x=0;x<width;++x)if(columns[x]<0) {
        int nearest=-1;for(int i=0;i<width;++i)if(columns[i]>=0&&(nearest<0||std::abs(i-x)<std::abs(nearest-x)))nearest=i;
        if(nearest<0)continue;
        for(int y=0;y<height;++y)std::copy_n(pixels.data()+4*((top+y)*stride+left+nearest),4,pixels.data()+4*((top+y)*stride+left+x));
    }
}
// Native creatures have a different body UV atlas from player equipment. Bake
// the equipment into that atlas instead of substituting it for skin or wings.
bool SelectorNativeBodyPixels(CCharacterComponent* c,std::vector<unsigned char>& outfit,
    unsigned& width,unsigned& height,std::vector<unsigned char> const* gloveless=nullptr,std::vector<unsigned char> const* hires=nullptr) {
    struct FittingMap {unsigned width=0,height=0;std::vector<unsigned> pixels;std::vector<unsigned char> coverage;};
    static std::array<FittingMap,8> maps;
    auto const& prefs=c->m_data.m_preferences;
    if((prefs.m_raceID!=108&&prefs.m_raceID!=76&&prefs.m_raceID!=101&&prefs.m_raceID!=110)||prefs.m_sexID>1)return false;
    auto& map=maps[(prefs.m_raceID==101?4u:prefs.m_raceID==110?6u:prefs.m_raceID==108?0u:2u)+prefs.m_sexID];
    if(map.pixels.empty()) {
        wchar_t path[128]{};
        swprintf_s(path,L"Data\\Retail\\Assets\\EquipmentFitting\\%u-%u.bin",prefs.m_raceID,prefs.m_sexID);
        Catalog file=CatalogFile(path);if(!file){KTrace("why","fitting map missing %ls",path);return false;}
        unsigned header[6]{};
        bool valid=file.Read(header,sizeof(header),1)==1&&header[0]==0x3146554e&&header[1]==1
            &&header[2]&&header[2]<=1024&&header[3]&&header[3]<=1024&&header[4]==512&&header[5]==512;
        if(valid) {
            map.width=header[2];map.height=header[3];map.pixels.resize(map.width*map.height);
            valid=file.Read(map.pixels.data(),sizeof(unsigned),map.pixels.size())==map.pixels.size();
            valid=valid&&std::all_of(map.pixels.begin(),map.pixels.end(),[](unsigned p){
                return p==0xffffffffu||((p&65535u)<512&&(p>>16)<512);});
            if(valid&&((prefs.m_raceID==108&&prefs.m_sexID==1)||(prefs.m_raceID==76||prefs.m_raceID==101))) {
                map.coverage.resize(map.pixels.size());
                if(file.Read(map.coverage.data(),1,map.coverage.size())!=map.coverage.size()
                    || !std::all_of(map.coverage.begin(),map.coverage.end(),[](unsigned char value){return value<=4;}))map.coverage.clear();
            }
        }
        if(!valid){KTrace("why","fitting map invalid %ls",path);map=FittingMap{};return false;}
    }
    char const* skinPath=nullptr;
    for(auto const& record:RaceSelections(prefs.m_raceID)) {
        if(record.gender==prefs.m_sexID&&record.kind==1&&record.target==11
            &&record.choices[0]==(unsigned(prefs.m_skinID)<<16)
            &&record.choices[1]==0xffffffffu&&record.choices[2]==0xffffffffu) {
            skinPath=record.path;break;
        }
    }
    if(!skinPath){KTrace("why","no skin record for race=%u sex=%u skin=%u",prefs.m_raceID,prefs.m_sexID,unsigned(prefs.m_skinID));return false;}
    NativePixelSource skin;
    // Keep the authored skin detail and underwear beneath equipped clothing.
    skin.bytes=NativeBlpData(skinPath);
    if((prefs.m_raceID==76||prefs.m_raceID==101)&&c->m_itemDisplayID[ITEMSLOT_PANTS]) {
        // Only the baked trouser regions are replaced, using this palette's
        // own forearm skin detail. Face, torso and underwear retain their atlas.
        char bareLegs[160]{};
        sprintf_s(bareLegs,"custom\\equipment\\native\\legskin-v3-61-%u-%u.blp",prefs.m_sexID,unsigned(prefs.m_skinID));
        auto detailedSkin=NativeBlpData(bareLegs);
        if(!detailedSkin.empty())skin.bytes=std::move(detailedSkin);
    }
    unsigned pitch=0;void* decoded=nullptr;
    if(!skin.Mip(0,pitch,decoded)||skin.Word(12)!=map.width||skin.Word(16)!=map.height){KTrace("why","skin decode/size mismatch path=%s skin=%ux%u map=%ux%u bytes=%zu",skinPath,skin.Word(12),skin.Word(16),map.width,map.height,skin.bytes.size());return false;}
    std::vector<unsigned char> composed(map.width*map.height*4);
    auto* native=static_cast<unsigned char const*>(decoded);
    auto extended=outfit;
    if(!map.coverage.empty()) {
        if(c->m_itemDisplayID[ITEMSLOT_CHEST]) {
            ExtendNativeClothRegion(extended,256,0,256,192);
            ExtendNativeClothRegion(extended,0,0,256,128);
        }
        if(c->m_itemDisplayID[ITEMSLOT_PANTS])ExtendNativeClothRegion(extended,256,192,256,128);
        if((prefs.m_raceID==76||prefs.m_raceID==101)&&c->m_itemDisplayID[ITEMSLOT_BOOTS])ExtendNativeClothRegion(extended,256,320,256,128);
    }
    unsigned long long tintSum[3]{};unsigned tintCount=0;
    std::vector<unsigned char> armor(map.width*map.height,0),plain(map.width*map.height,0);
    if((prefs.m_raceID==76||prefs.m_raceID==101)&&c->m_itemDisplayID[ITEMSLOT_BOOTS]) {
        for(unsigned y=448;y<512;++y)for(unsigned x=256;x<512;++x) {
            auto* color=outfit.data()+4*(y*512+x);if(color[3]<128)continue;
            for(unsigned k=0;k<3;++k)tintSum[k]+=color[k];++tintCount;
        }
    }
    for(unsigned y=0;y<map.height;++y) {
        std::copy_n(native+y*pitch,map.width*4,composed.data()+y*map.width*4);
        for(unsigned x=0;x<map.width;++x) {
            // Body albedo alpha stores Retail material data, not skin coverage.
            // The native body is opaque; uncovered armor pixels retain its RGB.
            if(prefs.m_raceID!=110)composed[4*(y*map.width+x)+3]=255; // Vorkai fur cards retain coverage alpha.
            unsigned sample=map.pixels[y*map.width+x];if(sample==0xffffffffu)continue;
            if((prefs.m_raceID==76||prefs.m_raceID==101)&&!map.coverage.empty()&&map.coverage[y*map.width+x]==4&&c->m_itemDisplayID[ITEMSLOT_BOOTS]) {
                // Carry the greave's lower edge over the ankle until the native
                // shoe collar begins. Do not tint this band as bare skin.
                auto* ankle=extended.data()+4*(447*512+(sample&65535u));
                if(ankle[3])SelectorOver(composed.data()+4*(y*map.width+x),ankle);
                continue;
            }
            if((prefs.m_raceID==76||prefs.m_raceID==101)&&((sample>>16)>=448||(!map.coverage.empty()&&map.coverage[y*map.width+x]==3))) {
                // Greaves stop at the original dress shoes. A restrained tint
                // follows the equipped boots while preserving shoe detail.
                if(tintCount) {
                    auto* color=composed.data()+4*(y*map.width+x);
                    unsigned shade=(unsigned(color[0])+color[1]+color[2])/3;
                    for(unsigned k=0;k<3;++k)color[k]=static_cast<unsigned char>(std::min(255ull,
                        (color[k]*65ull+shade*(tintSum[k]/tintCount)*35ull/128ull)/100ull));
                }
                continue;
            }
            auto const* layer=outfit.data()+4*((sample>>16)*512+(sample&65535u));
            bool direct=true;
            if(gloveless&&c->m_itemDisplayID[ITEMSLOT_GLOVES]&&(sample&65535u)<256&&(sample>>16)>=128&&(sample>>16)<256) {
                float compression=prefs.m_raceID==108?.82f:.78f;
                int gloveY=256-int((256-int(sample>>16))/compression);
                if(gloveY>=128)layer=outfit.data()+4*(gloveY*512+(sample&65535u));
                else layer=gloveless->data()+4*((sample>>16)*512+(sample&65535u));
                direct=false;
            }
            if(!map.coverage.empty()&&layer[3]<160) {
                auto mask=map.coverage[y*map.width+x];
                if((mask==1&&(sample>>16)<128&&c->m_itemDisplayID[ITEMSLOT_CHEST])||(mask==2&&c->m_itemDisplayID[ITEMSLOT_PANTS]))
                {layer=extended.data()+4*((sample>>16)*512+(sample&65535u));direct=false;}
            }
            if(layer[3]){SelectorOver(composed.data()+4*(y*map.width+x),layer);armor[y*map.width+x]=1;if(direct)plain[y*map.width+x]=1;}
        }
    }
    // The equipment textures are 2x the 512x512 atlas, which the whole-texel fitting map throws away. Rebuild the
    // body at double size: skin and unfitted regions are interpolated, plain armor texels come from the 2x atlas.
    if(hires&&hires->size()==1024u*1024u*4u) {
        unsigned const W=map.width*2,H=map.height*2;
        std::vector<unsigned char> big(size_t(W)*H*4);
        auto bilinear=[](unsigned char const* data,unsigned stride,unsigned rows,float fx,float fy,unsigned char* out) {
            fx=std::clamp(fx,0.f,float(stride-1));fy=std::clamp(fy,0.f,float(rows-1));
            unsigned x0=unsigned(fx),y0=unsigned(fy),x1=std::min(x0+1,stride-1),y1=std::min(y0+1,rows-1);
            float ax=fx-x0,ay=fy-y0;
            for(unsigned k=0;k<4;++k) {
                float top=data[4*(y0*stride+x0)+k]*(1-ax)+data[4*(y0*stride+x1)+k]*ax;
                float bottom=data[4*(y1*stride+x0)+k]*(1-ax)+data[4*(y1*stride+x1)+k]*ax;
                out[k]=static_cast<unsigned char>(top*(1-ay)+bottom*ay+.5f);
            }
        };
        std::vector<unsigned char> skin(size_t(map.width)*map.height*4);
        for(unsigned y=0;y<map.height;++y)std::copy_n(native+y*pitch,map.width*4,skin.data()+size_t(y)*map.width*4);
        for(unsigned Y=0;Y<H;++Y)for(unsigned X=0;X<W;++X) {
            float fx=(X+.5f)/2-.5f,fy=(Y+.5f)/2-.5f;
            unsigned nx=unsigned(std::clamp(int(fx+.5f),0,int(map.width)-1)),ny=unsigned(std::clamp(int(fy+.5f),0,int(map.height)-1));
            auto* out=big.data()+4*(size_t(Y)*W+X);
            if(!plain[ny*map.width+nx]) {
                bilinear(composed.data(),map.width,map.height,fx,fy,out);out[3]=255;
                continue;
            }
            bilinear(skin.data(),map.width,map.height,fx,fy,out);out[3]=255;
            float sx=float(map.pixels[ny*map.width+nx]&65535u),sy=float(map.pixels[ny*map.width+nx]>>16);
            unsigned x0=unsigned(std::clamp(int(std::floor(fx)),0,int(map.width)-2)),y0=unsigned(std::clamp(int(std::floor(fy)),0,int(map.height)-2));
            bool smooth=true;
            for(unsigned dy=0;dy<2&&smooth;++dy)for(unsigned dx=0;dx<2;++dx) {
                unsigned i=(y0+dy)*map.width+x0+dx;
                if(!plain[i]||std::abs(int(map.pixels[i]&65535u)-int(sx))>3||std::abs(int(map.pixels[i]>>16)-int(sy))>3){smooth=false;break;}
            }
            if(smooth) {
                float ax=std::clamp(fx-x0,0.f,1.f),ay=std::clamp(fy-y0,0.f,1.f);
                auto at=[&](unsigned dx,unsigned dy,bool horizontal) {
                    unsigned v=map.pixels[(y0+dy)*map.width+x0+dx];return float(horizontal?(v&65535u):(v>>16));
                };
                sx=(at(0,0,true)*(1-ax)+at(1,0,true)*ax)*(1-ay)+(at(0,1,true)*(1-ax)+at(1,1,true)*ax)*ay;
                sy=(at(0,0,false)*(1-ax)+at(1,0,false)*ax)*(1-ay)+(at(0,1,false)*(1-ax)+at(1,1,false)*ax)*ay;
            }
            unsigned char armorPixel[4]{};
            bilinear(hires->data(),1024,1024,2*sx+.5f,2*sy+.5f,armorPixel);
            if(armorPixel[3])SelectorOver(out,armorPixel);
        }
        width=W;height=H;outfit=std::move(big);return true;
    }
    width=map.width;height=map.height;outfit=std::move(composed);return true;
}
// HELM2C: legacy Hu/Or meshes need independent crown and scale profiles.
// Limit this to the installed Seven1A skeletons; never alter a shapeshift or another race.
void FitLargeRaceHelmet(CCharacterComponent* c) {
    auto const& prefs=c->m_data.m_preferences;
    if ((prefs.m_raceID!=57&&prefs.m_raceID!=66)||prefs.m_sexID>1||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto* parent=c->m_data.m_model;
    if(!parent||!(parent->m_fFlags&1)||!parent->m_shared||!parent->m_shared->m_data)return;
    auto* data=parent->m_shared->m_data;
    const bool female=prefs.m_sexID!=0, vrykul=prefs.m_raceID==57;
    const unsigned expectedBones=vrykul?(female?163u:154u):(female?237u:109u);
    const unsigned expectedHead=vrykul?(female?16u:39u):(female?45u:15u);
    if(data->m_bones.m_count!=expectedBones||data->m_boneIndicesById.m_count<=6)return;
    unsigned head=data->m_boneIndicesById[6];if(head!=expectedHead||head>=data->m_bones.m_count)return;
    auto const& pivot=data->m_bones[head].m_pivot;
    // Per-sex fitting candidates from native head measurements and user screenshots.
    const float scale=vrykul?(female?1.40f:2.30f):(female?1.50f:1.35f);
    const float dx=vrykul?(female?.08508668f:.0625562f):(female?.10806789f:.12566625f);
    const float dz=vrykul?(female?.18511772f:.18413198f):(female?.19042838f:.19398522f);
    C3Vector crown(pivot.x+dx*scale,pivot.y,pivot.z+dz*scale);
    for(auto* helmet=parent->m_attachList;helmet;helmet=helmet->m_attachNext) {
        if(helmet->m_attachmentId!=ATTACH_HELM)continue;
        // Instance-local, animated head frame. Does not mutate shared mesh or body size.
        helmet->SetAttachmentFrame(head,crown,scale);
    }
}
void FitNativePlayerHelmet(CCharacterComponent* c) {
    auto const& prefs=c->m_data.m_preferences;
    if ((prefs.m_raceID!=108&&prefs.m_raceID!=76)||prefs.m_sexID>1||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto* parent=c->m_data.m_model;
    if (!parent||!(parent->m_fFlags&1)||!parent->m_shared||!parent->m_shared->m_data)return;
    auto* data=parent->m_shared->m_data;
    if(data->m_boneIndicesById.m_count<=6)return;
    unsigned head=data->m_boneIndicesById[6];if(head>=data->m_bones.m_count)return;
    auto const& pivot=data->m_bones[head].m_pivot;
    float scale=pivot.z/(prefs.m_sexID?1.7118653f:1.8430222f);
    // RACE12A: native Kyrian head meshes are about twice the donor width.
    // Guard the installed skeleton; do not resize a transformed actor or Venthyr.
    const bool fitKyrian=prefs.m_raceID==108 && data->m_bones.m_count==251 && head==29;
    if(prefs.m_raceID==108&&!fitKyrian)return; // Keep transformed rigs outside the native profile.
    if(fitKyrian)scale=prefs.m_sexID?2.50f:2.05f; // CENTAUR2B: Honor female only; Gregory male unchanged
    C3Vector crown(pivot.x+(prefs.m_sexID?.08508668f:.0625562f)*scale,pivot.y,
        pivot.z+(prefs.m_sexID?.18511772f:.18413198f)*scale);
    for(auto* helmet=parent->m_attachList;helmet;helmet=helmet->m_attachNext) {
        if(helmet->m_attachmentId!=ATTACH_HELM)continue;
        // Keep attachment transforms in the model's native space. Setting the
        // attached model's world transform here can corrupt its parent-relative
        // matrix and crash when the roster recreates the character model.
        helmet->SetAttachmentFrame(head,crown,fitKyrian?scale:1.0f);
    }
}
void FitNativePlayerShoulders(CCharacterComponent* c) {
    if(c->m_data.m_preferences.m_raceID!=108||!c->m_data.m_model)return;
    auto* parent=c->m_data.m_model;
    auto* data=parent->m_shared?parent->m_shared->m_data:nullptr;
    if(!data||data->m_bones.m_count!=251)return;
    float scale=data->m_bones[29].m_pivot.z/1.8430222f;
    for(auto* pad=parent->m_attachList;pad;pad=pad->m_attachNext) {
        if(pad->m_attachmentId!=5&&pad->m_attachmentId!=6)continue;
        bool left=pad->m_attachmentId==6;
        auto position=data->m_bones[left?25:28].m_pivot;
        position.x+=.020f*scale;position.y-=(left?1.f:-1.f)*.068f*scale;position.z+=.065f*scale;
        // Use the clavicle's native frame, avoiding the extra rotated cosmetic
        // socket bones. Both sides receive the same anatomical offset.
        pad->SetAttachmentFrame(left?17:19,position,c->m_data.m_preferences.m_sexID?1.59f:1.80f);
    }
}
// CENTAUR1A: installed male/female heads share skeleton 208/head67.
void FitCentaurHelmet(CCharacterComponent* c) {
    const auto& p=c->m_data.m_preferences;
    if(p.m_raceID!=102||p.m_sexID>1||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto* model=c->m_data.m_model;
    if(!model||!(model->m_fFlags&1)||!model->m_shared||!model->m_shared->m_data)return;
    auto* data=model->m_shared->m_data;
    if(data->m_bones.m_count!=208||data->m_boneIndicesById.m_count<=6||data->m_boneIndicesById[6]!=67)return;
    const auto& pivot=data->m_bones[67].m_pivot;
    const float scale=p.m_sexID?1.90f:1.65f;
    C3Vector crown(pivot.x+(p.m_sexID?.20f:.0625562f*scale),pivot.y,
        pivot.z+.18413198f*(p.m_sexID?1.65f:scale));
    for(auto* helmet=model->m_attachList;helmet;helmet=helmet->m_attachNext)
        if(helmet->m_attachmentId==ATTACH_HELM)helmet->SetAttachmentFrame(67,crown,scale);
}
// Native mechanical skull and separate hair need their own per-sex fit.
void FitMechagnomeHelmet(CCharacterComponent* c) {
    const auto& p=c->m_data.m_preferences;
    if(p.m_raceID!=67||p.m_sexID>1||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto* model=c->m_data.m_model;
    if(!model||!(model->m_fFlags&1)||!model->m_shared||!model->m_shared->m_data)return;
    auto* data=model->m_shared->m_data;
    const unsigned head=p.m_sexID?52u:48u;
    if(data->m_bones.m_count!=(p.m_sexID?214u:202u)||data->m_boneIndicesById.m_count<=6||data->m_boneIndicesById[6]!=head)return;
    // Keep the male profile untouched until a male fit is actually reported.
    if(!p.m_sexID)return;
    const auto& pivot=data->m_bones[head].m_pivot;
    const C3Vector crown(pivot.x+.025f,0.0f,1.14f);
    for(auto* helmet=model->m_attachList;helmet;helmet=helmet->m_attachNext)
        if(helmet->m_attachmentId==ATTACH_HELM)helmet->SetAttachmentFrame(head,crown,C3Vector(1.16f,1.22f,1.12f));
}
void FitTuskarrJinyuHelmet(CCharacterComponent* c) {
    const auto& p=c->m_data.m_preferences;
    if((p.m_raceID!=28&&p.m_raceID!=78)||p.m_sexID>1||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto* model=c->m_data.m_model;
    if(!model||!(model->m_fFlags&1)||!model->m_shared||!model->m_shared->m_data)return;
    auto* data=model->m_shared->m_data;
    unsigned head;
    float scale;
    if(p.m_raceID==28) {
        // This model has no keybone6. Authored helm attachment11 is helper96,
        // parent22, and its pivot is already the crown socket.
        if(data->m_bones.m_count!=112)return;
        head=96;scale=3.0f;
    } else {
        head=p.m_sexID?29:15;scale=p.m_sexID?1.50f:1.20f;
        if(data->m_bones.m_count!=(p.m_sexID?174u:173u)||data->m_boneIndicesById.m_count<=6||data->m_boneIndicesById[6]!=head)return;
    }
    const auto& pivot=data->m_bones[head].m_pivot;
    C3Vector crown=pivot;
    if(p.m_raceID==78) {
        crown.x+=(p.m_sexID?.08508668f:.0625562f)*scale;
        crown.z+=(p.m_sexID?.18511772f:.18413198f)*scale;
    }
    // HELM99B: broad/long heads need width and depth independently of height.
    const C3Vector shape=p.m_raceID==28?C3Vector(3.40f,3.90f,3.20f):
        p.m_sexID?C3Vector(1.65f,1.80f,1.50f):C3Vector(1.35f,1.50f,1.20f);
    for(auto* helmet=model->m_attachList;helmet;helmet=helmet->m_attachNext)
        if(helmet->m_attachmentId==ATTACH_HELM)helmet->SetAttachmentFrame(head,crown,shape);
}
void FitVenthyr101Helmet(CCharacterComponent* c) {
    const auto& p=c->m_data.m_preferences;
    if(p.m_raceID!=101||p.m_sexID>1||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto* model=c->m_data.m_model;
    if(!model||!(model->m_fFlags&1)||!model->m_shared||!model->m_shared->m_data)return;
    auto* data=model->m_shared->m_data;
    const unsigned head=p.m_sexID?50:57;
    if(data->m_bones.m_count!=(p.m_sexID?212u:223u)||data->m_boneIndicesById.m_count<=6||data->m_boneIndicesById[6]!=head)return;
    const auto& pivot=data->m_bones[head].m_pivot;
    const float scale=1.5f;
    C3Vector crown(pivot.x+(p.m_sexID?.08508668f:.0625562f)*scale,pivot.y,pivot.z+(p.m_sexID?.18511772f:.18413198f)*scale);
    for(auto* helmet=model->m_attachList;helmet;helmet=helmet->m_attachNext)
        if(helmet->m_attachmentId==ATTACH_HELM)helmet->SetAttachmentFrame(head,crown,scale);
}
// PREVIEW1A: Drakkin's sexes use different authored skeletons, not a shared scale.
void FitDrakkin99Helmet(CCharacterComponent* c) {
    const auto& p=c->m_data.m_preferences;
    if(p.m_raceID!=99||p.m_sexID>1||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto* model=c->m_data.m_model;
    if(!model||!(model->m_fFlags&1)||!model->m_shared||!model->m_shared->m_data)return;
    auto* data=model->m_shared->m_data;
    const unsigned bones=p.m_sexID?222u:142u,head=p.m_sexID?59u:24u;
    if(data->m_bones.m_count!=bones||data->m_boneIndicesById.m_count<=6||data->m_boneIndicesById[6]!=head)return;
    const auto& pivot=data->m_bones[head].m_pivot;
    // HELM99B: male helmet 10% smaller; retain the accepted crown position.
    const float scale=p.m_sexID?1.0f:1.8f;
    const C3Vector shape=p.m_sexID?C3Vector(1.10f,1.25f,1.0f):C3Vector(2.10f,2.10f,1.8f);
    const float anchorScale=p.m_sexID?1.0f:2.0f;
    C3Vector crown(pivot.x+(p.m_sexID?.0464388f:.0625562f)*anchorScale,pivot.y,
        pivot.z+(p.m_sexID?.20299816f:.18413198f)*anchorScale);
    for(auto* helmet=model->m_attachList;helmet;helmet=helmet->m_attachNext)
        if(helmet->m_attachmentId==ATTACH_HELM)helmet->SetAttachmentFrame(head,crown,shape);
}
// CM2Cache::CreateShared otherwise keys these identical basenames together.
inline constexpr uint32_t ClothingCacheByFullPath = 0x10;

bool ScopedClothingRace(unsigned race);

enum class ClothingBindStage : unsigned { WrongRig, NoAtlas, ChildPending, SkinRejected, DevicePending, Bound };

void TraceClothingBind(CCharacterComponent* c, ClothingBindStage stage) {
    const auto& prefs=c->m_data.m_preferences;
    if (!ScopedClothingRace(prefs.m_raceID) && prefs.m_raceID!=93 && prefs.m_raceID!=102) return;
    auto* model=c->m_data.m_model;
    if (!model || !model->m_shared || !model->m_shared->m_data || prefs.m_sexID>1) return;
    static unsigned reported[113][2]{};
    auto& stages=reported[prefs.m_raceID][prefs.m_sexID];
    const unsigned bit=1u<<static_cast<unsigned>(stage);
    if (stages&bit) return;
    stages|=bit;
    static const char* names[]={"rig-rejected","atlas-empty","child-pending","skin-rejected","device-pending","bound"};
    KTrace("cloth-bind","race=%u sex=%u stage=%s parent=%s chest=%u pants=%u",
        prefs.m_raceID,prefs.m_sexID,names[static_cast<unsigned>(stage)],model->m_shared->m_fileName,
        c->m_itemDisplayID[ITEMSLOT_CHEST],c->m_itemDisplayID[ITEMSLOT_PANTS]);
}

// JOY2A: legacy Centaur keeps its accepted body/appearance and receives
// the donor's private, skin-parented equipment mesh. Never replace the body.
bool BindLegacyCentaurClothing(CCharacterComponent* c,CTexture* texture,CTexture* beltTexture) {
    auto* parent=c->m_data.m_model;
    constexpr unsigned socket=0xee000102u;
    CM2Model* child=nullptr;
    for(auto* item=parent->m_attachList;item;item=item->m_attachNext)
        if(item->m_attachmentId==socket){child=item;break;}
    if(!texture&&!c->m_itemDisplayID[ITEMSLOT_CAPE]) {
        if(child)parent->DetachAllChildrenById(socket);
        return true;
    }
    if(!child) {
        char path[128]{};sprintf_s(path,"custom/rebornfit/centaur/%u/clothing.m2",c->m_data.m_preferences.m_sexID);
        child=parent->m_scene->CreateModel(path, ClothingCacheByFullPath);
        if(!child)return false;
        child->SetGeometryVisible(0,65535,0);
        child->AttachToParent(parent,socket,nullptr,1);
        child->Release();
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
    if(texture)child->ReplaceTexture(14,texture);
    const bool beltReady=beltTexture&&TextureGetGxTex(beltTexture,0,nullptr);
    if(beltReady)child->ReplaceTexture(15,beltTexture);
    child->SetGeometryVisible(0,65535,0);
    ItemDisplayInfoRec item{};
    if(texture) {
        child->SetGeometryVisible(1,1,1);
        for(unsigned geo:c->m_data.m_geosets)child->SetGeometryVisible(geo,geo,1);
        for(auto slot:{ITEMSLOT_GLOVES,ITEMSLOT_CHEST,ITEMSLOT_SHIRT,ITEMSLOT_TABARD}) {
            if(!c->m_itemDisplayID[slot]||!g_itemDisplayInfoDB.GetRecord(c->m_itemDisplayID[slot],&item))continue;
            const unsigned group=slot==ITEMSLOT_GLOVES?4u:slot==ITEMSLOT_TABARD?12u:8u;
            if(item.m_geosetGroup[0])child->SetGeometryVisible(group*100+1+item.m_geosetGroup[0],group*100+1+item.m_geosetGroup[0],1);
        }
        child->SetGeometryVisible(2002,2002,c->m_itemDisplayID[ITEMSLOT_BOOTS]?1:0);
        child->SetGeometryVisible(1800,1899,0);
        child->SetGeometryVisible(1805,1805,c->m_itemDisplayID[ITEMSLOT_BELT]&&beltReady?1:0);
    }
    child->SetGeometryVisible(1500,1599,0);
    if(c->m_itemDisplayID[ITEMSLOT_CAPE]&&g_itemDisplayInfoDB.GetRecord(c->m_itemDisplayID[ITEMSLOT_CAPE],&item)) {
        // The original Centaur has no type-2 slot. AddCape's replacement on
        // that parent was discarded; load the real ItemDisplay cape directly.
        auto& outfit=selectorOutfits[c];
        if(outfit.capeDisplay!=c->m_itemDisplayID[ITEMSLOT_CAPE]||!outfit.capeTexture) {
            outfit.capeTexture.reset();outfit.capeDisplay=0;
            if(*item.m_modelTexture[0]) {
                char path[512]{};sprintf_s(path,"Item/ObjectComponents/Cape/%s.blp",item.m_modelTexture[0]);
                CStatus status;
                if(auto* cape=CreateTexture(path,&status)) {
                    outfit.capeTexture=std::shared_ptr<void>(cape,[](void* t){HandleClose(reinterpret_cast<HOBJECT>(t));});
                    outfit.capeDisplay=c->m_itemDisplayID[ITEMSLOT_CAPE];
                }
            }
        }
        if(auto* cape=reinterpret_cast<CTexture*>(outfit.capeTexture.get())) {
            if(TextureGetGxTex(cape,0,nullptr)) {
                child->ReplaceTexture(2,cape);
                child->SetGeometryVisible(1501+item.m_geosetGroup[0],1501+item.m_geosetGroup[0],1);
            }
        }
    }
    child->UnoptimizeVisibleGeometry();
    const bool bodyReady=child->IsDrawable(0,0)&&(!texture||SelectorTextureBound(child,14,texture));
    if(texture) TraceClothingBind(c,bodyReady?ClothingBindStage::Bound:ClothingBindStage::DevicePending);
    return bodyReady&&(!beltTexture||beltReady);
}
void FitNeutralPlayerHelmet(CCharacterComponent* c) {
    auto* parent=c->m_data.m_model;
    auto* mesh=parent&&parent->m_shared?parent->m_shared->m_data:nullptr;
    if(!mesh||!(parent->m_fFlags&1)||!c->m_itemDisplayID[ITEMSLOT_HEAD])return;
    auto const* f=RebornNeutralHelmet::Find(c->m_data.m_preferences.m_raceID,c->m_data.m_preferences.m_sexID,mesh->m_bones.m_count,mesh->m_vertices.m_count);
    if(!f)return;
    CM2Model* helm=parent->m_attachList;while(helm&&helm->m_attachmentId!=ATTACH_HELM)helm=helm->m_attachNext;
    if(!helm) {
        // An initial AddHelm may run before the NPC rig has its sockets loaded.
        // Recreate once the real parent is ready instead of waiting for a gear toggle.
        c->AddHelm(0);
        helm=parent->m_attachList;while(helm&&helm->m_attachmentId!=ATTACH_HELM)helm=helm->m_attachNext;
    }
    if(!helm||!helm->m_shared)return;
    if(helm->m_attachmentIndex==0xffff) {
        unsigned socket=0;while(socket<mesh->m_attachmentIndicesById.m_count&&mesh->m_attachmentIndicesById[socket]>=mesh->m_attachments.m_count)++socket;
        if(socket==mesh->m_attachmentIndicesById.m_count)return;
        helm->AttachToParent(parent,socket,nullptr,0);helm->m_attachmentId=ATTACH_HELM;
    }
    const char* path=helm->m_shared->m_fileName;bool human=strstr(path,"_HuM.")||strstr(path,"_HuF.");
    const float* q=human?f->humanCrown:f->nativeCrown;const float* z=human?f->humanScale:f->nativeScale;
    helm->SetAttachmentFrame(f->head,C3Vector(q[0],q[1],q[2]),C3Vector(z[0],z[1],z[2]));
}
bool NeutralHelmetNeedsBind(CCharacterComponent* c) {
    if(!c||!c->m_itemDisplayID[ITEMSLOT_HEAD]||!c->m_data.m_model)return false;
    auto* parent=c->m_data.m_model;auto* data=parent->m_shared?parent->m_shared->m_data:nullptr;
    if(!data||!(parent->m_fFlags&1))return false;
    if(!RebornNeutralHelmet::Find(c->m_data.m_preferences.m_raceID,c->m_data.m_preferences.m_sexID,data->m_bones.m_count,data->m_vertices.m_count))return false;
    ItemDisplayInfoRec item{};if(!g_itemDisplayInfoDB.GetRecord(c->m_itemDisplayID[ITEMSLOT_HEAD],&item)||!*item.m_modelName[0])return false;
    for(auto* child=parent->m_attachList;child;child=child->m_attachNext)
        if(child->m_attachmentId==ATTACH_HELM)return child->m_attachmentIndex==0xffff;
    return true;
}

#include "RebornNeutralClothing.inl"

bool SelectorLayerNeedsBind(CCharacterComponent* c) {
    if(!c)return false;
    const auto race=c->m_data.m_preferences.m_raceID;
    if(race!=102&&race!=110&&race!=101&&race!=108)return false;
    auto i=selectorOutfits.find(c);if(i==selectorOutfits.end())return true;
    const unsigned type=race==102?14u:11u;
    auto* model=c->m_data.m_model;
    if(i->second.model!=model||!i->second.texture||!model||!model->m_shared||!model->m_shared->m_data)return true;
    if(race!=102&&!SelectorTextureBound(model,type,i->second.texture.get()))return true;
    return i->second.fields!=FieldsOf(c)||i->second.layers!=NeutralClothingLayerKey(c)
        ||!std::equal(i->second.gear.begin(),i->second.gear.end(),c->m_itemDisplayID);
}

void BindSelectorOutfit(CCharacterComponent* c) {
    BindNeutralClothing(c);
    FitNeutralPlayerHelmet(c);
    FitLargeRaceHelmet(c);
    FitCentaurHelmet(c);
    FitMechagnomeHelmet(c);
    FitDrakkin99Helmet(c);
    FitVenthyr101Helmet(c);
    FitTuskarrJinyuHelmet(c);
    auto race=c->m_data.m_preferences.m_raceID;
    if(race!=108&&race!=101&&race!=110&&race!=102)return;
    bool nativeBody=race==108||(race==101)||race==101||race==110;
    unsigned textureType=nativeBody?11:race==62?1:14;
    FitNativePlayerHelmet(c);
    FitNativePlayerShoulders(c);
    static bool busy=false;if(busy)return;
    struct Guard{bool& value;Guard(bool& v):value(v){value=true;}~Guard(){value=false;}}guard(busy);
    auto& state=selectorOutfits[c];auto fields=FieldsOf(c);
    std::array<unsigned,12> gear{};std::copy_n(c->m_itemDisplayID,12,gear.begin());
    ItemDisplayInfoRec chestRecord{},pantsRecord{};
    bool chestRobe=nativeBody&&gear[ITEMSLOT_CHEST]&&g_itemDisplayInfoDB.GetRecord(gear[ITEMSLOT_CHEST],&chestRecord)&&chestRecord.m_geosetGroup[2]!=0;
    bool legSkirt=nativeBody&&gear[ITEMSLOT_PANTS]&&g_itemDisplayInfoDB.GetRecord(gear[ITEMSLOT_PANTS],&pantsRecord)&&pantsRecord.m_geosetGroup[2]!=0;
    bool robe=chestRobe||legSkirt;
    bool shoes=nativeBody&&race==108&&gear[ITEMSLOT_BOOTS]&&(c->m_section[SECTION_FOOT].m_layerMask&1);
    bool greaves=nativeBody&&(race==101)&&gear[ITEMSLOT_BOOTS];
    bool gloves=nativeBody&&gear[ITEMSLOT_GLOVES];
    unsigned gloveStyle=0;ItemDisplayInfoRec gloveRecord{};
    if(gloves&&g_itemDisplayInfoDB.GetRecord(gear[ITEMSLOT_GLOVES],&gloveRecord))gloveStyle=std::min(3u,static_cast<unsigned>(gloveRecord.m_geosetGroup[0]));
    unsigned bootStyle=0;ItemDisplayInfoRec bootRecord{};
    if(nativeBody&&gear[ITEMSLOT_BOOTS]&&g_itemDisplayInfoDB.GetRecord(gear[ITEMSLOT_BOOTS],&bootRecord))
        bootStyle=std::min(4u,static_cast<unsigned>(bootRecord.m_geosetGroup[0]));
    unsigned upperLegGeo=nativeBody&&!robe&&pantsRecord.m_geosetGroup[0]?(pantsRecord.m_geosetGroup[0]>2?20104u:20102u):0;
    unsigned lowerLegGeo=nativeBody&&!robe&&!bootStyle&&pantsRecord.m_geosetGroup[1]?(pantsRecord.m_geosetGroup[1]>1?20113u:20112u):0;
    ItemDisplayInfoRec shirtRecord{};
    unsigned waistGeo=nativeBody&&!robe&&gear[ITEMSLOT_SHIRT]&&g_itemDisplayInfoDB.GetRecord(gear[ITEMSLOT_SHIRT],&shirtRecord)&&shirtRecord.m_geosetGroup[1]?20122u:0;
    ItemDisplayInfoRec beltRecord{};
    unsigned beltGeo=nativeBody&&gear[ITEMSLOT_BELT]&&g_itemDisplayInfoDB.GetRecord(gear[ITEMSLOT_BELT],&beltRecord)&&beltRecord.m_geosetGroup[0]?20132u:0;
    bool legMeshes=upperLegGeo||lowerLegGeo||waistGeo||beltGeo;
    auto bindLegMeshes=[&]() {
        if(!nativeBody)return;
        c->m_data.m_model->SetGeometryVisible(20100,20139,0);
        c->m_data.m_model->SetGeometryVisible(20200,20200,0);
        c->m_data.m_model->SetGeometryVisible(0,0,1);
        if (race == 108) c->m_data.m_model->SetGeometryVisible(20300,20300,robe?0:1);
        if((race==101)&&(robe||std::any_of(gear.begin(),gear.end(),[](unsigned value){return value!=0;})))
            c->m_data.m_model->SetGeometryVisible(3101,3101,1);
        for(unsigned geo:{upperLegGeo,lowerLegGeo,waistGeo,beltGeo})if(geo)c->m_data.m_model->SetGeometryVisible(geo,geo,1);
    };
    KTrace("bind","race=%u sex=%u robe=%d(chest=%d,legs=%d) shoes=%d gloves=%d(style=%u) legMeshes=%d gear=%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u fields=%u,%u,%u,%u,%u",
        race,c->m_data.m_preferences.m_sexID,robe,chestRobe,legSkirt,shoes,gloves,gloveStyle,legMeshes,gear[0],gear[1],gear[2],gear[3],gear[4],gear[5],gear[6],gear[7],gear[8],gear[9],gear[10],gear[11],fields[0],fields[1],fields[2],fields[3],fields[4]);
    bindLegMeshes();
    if(state.model==c->m_data.m_model && state.texture && state.gear==gear && state.fields==fields && state.layers==NeutralClothingLayerKey(c) && state.hasRobe==robe && state.hasShoes==shoes && state.hasGreaves==greaves && state.bootStyle==bootStyle&&state.hasGloves==gloves&&state.gloveStyle==gloveStyle) {
        c->m_data.m_model->ReplaceTexture(textureType,reinterpret_cast<CTexture*>(state.texture.get()));
        if(nativeBody) {
            c->m_data.m_model->SetGeometryVisible(1302,1302,robe?1:0);
            c->m_data.m_model->SetGeometryVisible(20002,20034,0);
            if(shoes&&!robe)c->m_data.m_model->SetGeometryVisible(20010+bootStyle,20010+bootStyle,1);
            if(greaves)c->m_data.m_model->SetGeometryVisible(20020+bootStyle,20020+bootStyle,1);
            if(gloves)c->m_data.m_model->SetGeometryVisible(20030+gloveStyle,20030+gloveStyle,1);
            if((robe||shoes||greaves||gloves||legMeshes)&&state.robeTexture)c->m_data.m_model->ReplaceTexture(15,reinterpret_cast<CTexture*>(state.robeTexture.get()));
        }
        if(race==108){KOverrides(c->m_data.m_model);KVisible(c->m_data.m_model,c->m_data.m_preferences.m_sexID);}
        if(race==102&&!BindLegacyCentaurClothing(c,reinterpret_cast<CTexture*>(state.texture.get()),reinterpret_cast<CTexture*>(state.robeTexture.get()))){pendingSelectorBind.insert(c);return;}
        pendingSelectorBind.erase(c);return;
    }
    auto& sources=OutfitSources(c);
    if(!sources.ready&&race!=102){pendingSelectorBind.insert(c);return;}
    std::vector<unsigned char> pixels(512*512*4);
    auto gloveless=pixels;
    std::vector<unsigned char> centaurBelt(512u*512u*4u,0);
    bool centaurBeltUpper=false,centaurFoot=false;
    if(race==102)for(unsigned layer=0;layer<7;++layer) {
        centaurBeltUpper=centaurBeltUpper||((OutfitSources(c).rows[5].m_layerMask&(1u<<layer))&&gear[ITEMSLOT_BELT]&&OutfitSources(c).rows[5].m_layerItemDisplayId[layer]==gear[ITEMSLOT_BELT]);
        centaurFoot=centaurFoot||((OutfitSources(c).rows[7].m_layerMask&(1u<<layer))&&gear[ITEMSLOT_BOOTS]&&OutfitSources(c).rows[7].m_layerItemDisplayId[layer]==gear[ITEMSLOT_BOOTS]);
    }
    std::vector<unsigned char> hires(1024u*1024u*4u,0);
    constexpr unsigned counts[]={2,7,1,5,7,3,6,1};
    for(unsigned region=0;region<8;++region) {
        auto const& row=sources.rows[region];
        bool legacyRobe=!nativeBody&&(c->m_flags&0x20)!=0;
        unsigned first=legacyRobe&&(region==5||region==6)?1:0;
        unsigned end=legacyRobe&&region==5?2:legacyRobe&&region==6?4:counts[region];
        for(unsigned layer=first;layer<end;++layer) {
            if(!(row.m_layerMask&(1u<<layer))) {
                if(race!=102&&row.m_layerItemDisplayId[layer]){pendingSelectorBind.insert(c);return;}
                continue;
            }
            // Skirt textures live in lower-leg layer 4. Read every native layer
            // and suppress the covered item by display ID, not a layer cutoff.
            if(nativeBody&&robe&&region==6&&row.m_layerItemDisplayId[layer]==gear[ITEMSLOT_BOOTS])continue;
            if(nativeBody&&chestRobe&&region==5&&row.m_layerItemDisplayId[layer]==gear[ITEMSLOT_PANTS])continue;
            unsigned destination=region;
            if(race==102&&gear[ITEMSLOT_BOOTS]&&row.m_layerItemDisplayId[layer]==gear[ITEMSLOT_BOOTS]) {
                if(region==7||(region==6&&!centaurFoot))destination=7;else continue;
            }
            auto const& rect=CCharacterComponent::s_sectionInfoRaw[destination];
            NativePixelSource source;
            if(!SelectorLayerPixels(row.m_layerTex[layer],source)) {
                if(race==102)continue;
                Trace("Native outfit layer decode failed component=%p region=%u layer=%u",c,region,layer);
                pendingSelectorBind.insert(c);return;
            }
            auto const& data=source.levels[0];unsigned w=source.Word(12),h=source.Word(16);
            if(race==102&&gear[ITEMSLOT_BELT]&&row.m_layerItemDisplayId[layer]==gear[ITEMSLOT_BELT]) {
                if(region==5||(!centaurBeltUpper&&region==4)) {
                    unsigned top=h,bottom=0;
                    for(unsigned y=0;y<h;++y)for(unsigned x=0;x<w;++x)if(data[4*(y*w+x)+3]){top=std::min(top,y);bottom=std::max(bottom,y+1);}
                    if(top<bottom)for(unsigned y=0;y<128;++y)for(unsigned x=0;x<256;++x)
                        SelectorOver(centaurBelt.data()+4*((192+y)*512+256+x),data.data()+4*((top+y*(bottom-top)/128)*w+x*w/256));
                }
                continue;
            }
            if(race==108)KTrace("layer","region=%u layer=%u item=%u source=%ux%u rect=%dx%d",region,layer,row.m_layerItemDisplayId[layer],w,h,int(rect.m_size.x),int(rect.m_size.y));
            for(unsigned y=0;y<unsigned(rect.m_size.y);++y)for(unsigned x=0;x<unsigned(rect.m_size.x);++x) {
                SelectorOver(pixels.data()+4*((rect.m_pos.y+y)*512+rect.m_pos.x+x),
                    data.data()+4*((y*h/rect.m_size.y)*w+x*w/rect.m_size.x));
                if(!hires.empty())for(unsigned sy=0;sy<2;++sy)for(unsigned sx=0;sx<2;++sx) {
                    unsigned hx=x*2+sx,hy=y*2+sy;
                    SelectorOver(hires.data()+4*((2*rect.m_pos.y+hy)*1024+2*rect.m_pos.x+hx),
                        data.data()+4*((hy*h/(2*rect.m_size.y))*w+hx*w/(2*rect.m_size.x)));
                }
                if(!gear[ITEMSLOT_GLOVES]||row.m_layerItemDisplayId[layer]!=gear[ITEMSLOT_GLOVES])
                    SelectorOver(gloveless.data()+4*((rect.m_pos.y+y)*512+rect.m_pos.x+x),
                        data.data()+4*((y*h/rect.m_size.y)*w+x*w/rect.m_size.x));
            }
        }
    }
    if(nativeBody&&race==108&&gear[ITEMSLOT_BOOTS]){SealNativeBootFoot(pixels);if(!hires.empty())SealNativeBootFoot(hires,1024,2);}
    std::shared_ptr<void> robeTexture;
    if(race==102&&gear[ITEMSLOT_BELT]) {
        std::vector<unsigned char> sheet(2048u*1024u*4u,0);
        for(unsigned y=0;y<1024;++y)for(unsigned x=0;x<1024;++x)
            std::copy_n(centaurBelt.data()+4*((y/2)*512+x/2),4,sheet.data()+4*(y*2048+x));
        std::uint64_t hash=14695981039346656037ull;for(auto v:sheet)hash=(hash^v)*1099511628211ull;
        char name[128]{};sprintf_s(name,"Data/Retail/Cache/Appearance/Equipment/centaur-belt-%016llx.blp",static_cast<unsigned long long>(hash));
        robeTexture=NativeTexture(name,sheet,2048,1024,true);
        if(!robeTexture){pendingSelectorBind.insert(c);return;}
    }
    if(robe||shoes||greaves||gloves||legMeshes) {
        auto garment=pixels;unsigned garmentSize=512;
        if(!hires.empty()){garment=hires;garmentSize=1024;}
        if(greaves&&!robe) {
            // Only seal the lower greave edge. Keep the item's upper alpha
            // silhouette so its cuff appears once, at the body's chart height.
            auto sealed=garment;
            unsigned const scale=garmentSize/512;
            ExtendNativeClothRegion(sealed,256*scale,320*scale,256*scale,128*scale,garmentSize);
            for(unsigned y=420*scale;y<448*scale;++y)
                std::copy_n(sealed.data()+4*(y*garmentSize+256*scale),256*scale*4,
                    garment.data()+4*(y*garmentSize+256*scale));
        }
        std::uint64_t garmentHash=14695981039346656037ull;
        for(auto value:garment)garmentHash=(garmentHash^value)*1099511628211ull;
        char garmentPath[160]{};
        sprintf_s(garmentPath,"Data\\Retail\\Cache\\Appearance\\Equipment\\garment-v2-%016llx.blp",static_cast<unsigned long long>(garmentHash));
        if((robeTexture=NativeTexture(garmentPath,garment,garmentSize,garmentSize,race==102))==nullptr) {
            KTrace("fail","garment texture failed");pendingSelectorBind.insert(c);return;
        }
    }
    unsigned width=512,height=512;
    if(nativeBody&&!SelectorNativeBodyPixels(c,pixels,width,height,&gloveless,(race==110||hires.empty())?nullptr:&hires)) {
        KTrace("fail","SelectorNativeBodyPixels failed (see why)");pendingSelectorBind.insert(c);return;
    }
    if(race==102) {
        // Layout141 uses the standard Wrath sheet at 2x in its left half.
        std::vector<unsigned char> sheet(2048u*1024u*4u,0);
        for(unsigned y=0;y<1024;++y)for(unsigned x=0;x<1024;++x)
            std::copy_n(pixels.data()+4*((y/2)*512+x/2),4,sheet.data()+4*(y*2048+x));
        pixels=std::move(sheet);width=2048;height=1024;
    }
    std::uint64_t hash=14695981039346656037ull;
    for(auto value:pixels)hash=(hash^value)*1099511628211ull;
    if(race==108){char tag[64];sprintf_s(tag,"body-sex%u-robe%d-gloves%d-skin%u",c->m_data.m_preferences.m_sexID,robe?1:0,gloves?1:0,unsigned(fields[0]));KDump(tag,pixels,width,height);}
    char path[160]{};
    if(nativeBody)sprintf_s(path,"Data\\Retail\\Cache\\Appearance\\Equipment\\native-v3-%u-%u-%016llx.blp",race,c->m_data.m_preferences.m_sexID,static_cast<unsigned long long>(hash));
    else sprintf_s(path,"DHCache\\Outfits\\v2-%u-%016llx.blp",race,static_cast<unsigned long long>(hash));
    auto texture=NativeTexture(path,pixels,width,height,race==102);
    if(!texture){KTrace("fail","native texture create failed");pendingSelectorBind.insert(c);return;}
    state.model=c->m_data.m_model;state.gear=gear;state.fields=fields;state.layers=NeutralClothingLayerKey(c);state.texture=texture;state.robeTexture=robeTexture;state.hasRobe=robe;state.hasShoes=shoes;state.hasGreaves=greaves;state.bootStyle=bootStyle;state.hash=hash;
    state.hasGloves=gloves;state.gloveStyle=gloveStyle;
    c->m_data.m_model->ReplaceTexture(textureType,reinterpret_cast<CTexture*>(texture.get()));
    if(nativeBody) {
        c->m_data.m_model->SetGeometryVisible(1302,1302,robe?1:0);
        c->m_data.m_model->SetGeometryVisible(20002,20034,0);
        if(shoes&&!robe)c->m_data.m_model->SetGeometryVisible(20010+bootStyle,20010+bootStyle,1);
        if(greaves)c->m_data.m_model->SetGeometryVisible(20020+bootStyle,20020+bootStyle,1);
        if(gloves)c->m_data.m_model->SetGeometryVisible(20030+gloveStyle,20030+gloveStyle,1);
        if(robeTexture)c->m_data.m_model->ReplaceTexture(15,reinterpret_cast<CTexture*>(robeTexture.get()));
    }
    if(race==108){KOverrides(c->m_data.m_model);KVisible(c->m_data.m_model,c->m_data.m_preferences.m_sexID);}
    if(race==102&&!BindLegacyCentaurClothing(c,reinterpret_cast<CTexture*>(texture.get()),reinterpret_cast<CTexture*>(robeTexture.get()))){pendingSelectorBind.insert(c);return;}
    pendingSelectorBind.erase(c);
    KTrace("fail","bound ok %ux%u path=%s",width,height,path);
    Trace("Native outfit bound component=%p fields=%u,%u,%u,%u,%u type1=%p path=%s",c,fields[0],fields[1],fields[2],fields[3],fields[4],texture.get(),path);
}


