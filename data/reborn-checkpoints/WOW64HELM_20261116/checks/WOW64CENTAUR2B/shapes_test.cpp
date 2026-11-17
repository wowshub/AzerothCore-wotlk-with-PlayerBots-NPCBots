#include <initializer_list>

#include <cassert>
#include <cmath>
#include <cstdint>
constexpr int ITEMSLOT_HEAD=0,ATTACH_HELM=11;
struct C3Vector{float x=0,y=0,z=0;C3Vector(){}C3Vector(float a,float b,float c):x(a),y(b),z(c){}};
template<class T,int N>struct A{unsigned m_count=N;T v[N]{};T&operator[](unsigned i){return v[i];}};
struct Bone{C3Vector m_pivot;};struct Data{A<Bone,300>m_bones;A<unsigned,10>m_boneIndicesById;};struct Shared{Data*m_data;};
struct Model{unsigned m_fFlags=1,m_attachmentId=11;Shared*m_shared=nullptr;Model*m_attachList=nullptr,*m_attachNext=nullptr;int calls=0;float scale=0;unsigned bone=0;C3Vector pos,shape;void SetAttachmentFrame(unsigned b,C3Vector p,float s){++calls;bone=b;pos=p;scale=s;shape=C3Vector(s,s,s);}void SetAttachmentFrame(unsigned b,C3Vector p,C3Vector v){SetAttachmentFrame(b,p,v.z);shape=v;}};
struct CCharacterComponent{struct{struct{unsigned m_raceID=0,m_sexID=0;}m_preferences;Model*m_model=nullptr;}m_data;unsigned m_itemDisplayID[1]={1};};
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
}void FitTuskarrJinyuHelmet(CCharacterComponent* c) {
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
int main(){Data d;Shared sh{&d};Model parent,helm,shoulder;parent.m_shared=&sh;parent.m_attachList=&helm;helm.m_attachNext=&shoulder;shoulder.m_attachmentId=5;CCharacterComponent c;c.m_data.m_model=&parent;
for(unsigned race:{99u,78u,28u})for(unsigned sex:{0u,1u}){
c.m_data.m_preferences={race,sex};unsigned bone=race==99?(sex?59:24):race==78?(sex?29:15):96;d.m_bones.m_count=race==99?(sex?222:142):race==78?(sex?174:173):112;d.m_boneIndicesById[6]=bone;helm.calls=0;
auto fit=[&](){if(race==99)FitDrakkin99Helmet(&c);else FitTuskarrJinyuHelmet(&c);};fit();assert(helm.calls==1&&helm.bone==bone&&helm.shape.y>helm.shape.z);
auto first=helm.shape;auto position=helm.pos;fit();assert(helm.calls==2&&helm.shape.x==first.x&&helm.shape.y==first.y&&helm.pos.z==position.z);
c.m_itemDisplayID[0]=0;fit();assert(helm.calls==2);c.m_itemDisplayID[0]=1;--d.m_bones.m_count;fit();assert(helm.calls==2);
if(race==99)assert(first.z==(sex?1.f:1.8f)&&first.y==(sex?1.25f:2.1f));
if(race==78)assert(first.z==(sex?1.5f:1.2f)&&first.y==(sex?1.8f:1.5f));
if(race==28)assert(first.z==3.2f&&first.y==3.9f);
}assert(shoulder.calls==0);
}
