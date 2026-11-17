
#include <cassert>
#include <cstring>
#include <cstdint>
#include <map>
#include <mutex>
struct CM2Model;
template<class T>struct List{T*head=nullptr;T*Head(){return head;}bool IsEnd(T*p){return !p;}T*RawNext(T*p){return p->next;}};
struct Play{Play*next=nullptr;CM2Model*m_model=nullptr;};
struct Load{Load*next=nullptr;List<Play>m_playbacks;};
struct Texture{const char*m_filename;bool ready;};
void* TextureGetGxTex(Texture*t,int,void*){return t->ready?t:nullptr;}
struct TexRec{unsigned m_type=11;};
struct A{unsigned m_count=1;TexRec v[1];const TexRec&operator[](unsigned i)const{assert(i==0);return v[0];}};
struct Data{A m_textures;};struct Shared{Data*m_data;List<Load>m_sequenceLoads;};
struct CM2Model{unsigned m_fFlags=1;Shared*m_shared;Texture**m_textures;CM2Model*m_attachParent=nullptr;void SetRenderSuppressed(bool);bool IsRenderSuppressed()const;};
std::mutex s_skinParentMutex;std::map<const CM2Model*,bool>s_renderSuppressed;
static bool CentaurBodyReady(CM2Model* model) {
    if(!model||!(model->m_fFlags&1)||!model->m_shared||!model->m_shared->m_data||!model->m_textures)return false;
    // Texture completion does not imply the deferred Stand sequence is ready.
    auto& loads=model->m_shared->m_sequenceLoads;
    for(auto* load=loads.Head();!loads.IsEnd(load);load=loads.RawNext(load)) {
        auto& plays=load->m_playbacks;
        for(auto* play=plays.Head();!plays.IsEnd(play);play=plays.RawNext(play))
            if(play->m_model==model)return false;
    }
    const auto& textures=model->m_shared->m_data->m_textures;
    bool found=false;
    for(uint32_t i=0;i<textures.m_count;++i)if(textures[i].m_type==11) {
        found=true;auto* texture=model->m_textures[i];
        if(!texture||!std::strncmp(texture->m_filename,"SolidTexture",12)||!TextureGetGxTex(texture,0,nullptr))return false;
    }
    return found;
}void CM2Model::SetRenderSuppressed(bool suppressed) {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    if(suppressed)s_renderSuppressed[this]=true;else s_renderSuppressed.erase(this);
}bool CM2Model::IsRenderSuppressed() const {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    for(auto* model=this;model;model=model->m_attachParent)
        if(s_renderSuppressed.find(model)!=s_renderSuppressed.end())return true;
    return false;
}
int main(){Data d;Shared s{&d};Texture t{"real.blp",true};Texture*tex=&t;CM2Model parent{1,&s,&tex},child{1,&s,&tex,&parent},unrelated{1,&s,&tex};
assert(CentaurBodyReady(&parent));assert(!CentaurBodyReady(nullptr));tex=nullptr;assert(!CentaurBodyReady(&parent));tex=&t;t.m_filename="SolidTexture0";assert(!CentaurBodyReady(&parent));t.m_filename="real.blp";t.ready=false;assert(!CentaurBodyReady(&parent));t.ready=true;
Play p{nullptr,&parent};Load l;l.m_playbacks.head=&p;s.m_sequenceLoads.head=&l;assert(!CentaurBodyReady(&parent));p.m_model=&unrelated;assert(CentaurBodyReady(&parent));s.m_sequenceLoads.head=nullptr;
assert(!child.IsRenderSuppressed());parent.SetRenderSuppressed(true);assert(parent.IsRenderSuppressed()&&child.IsRenderSuppressed()&&!unrelated.IsRenderSuppressed());parent.SetRenderSuppressed(false);assert(!parent.IsRenderSuppressed()&&!child.IsRenderSuppressed());child.SetRenderSuppressed(true);assert(child.IsRenderSuppressed()&&!parent.IsRenderSuppressed());child.m_attachParent=&unrelated;assert(!unrelated.IsRenderSuppressed());child.SetRenderSuppressed(false);assert(s_renderSuppressed.empty());
}
