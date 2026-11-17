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
}void FitCentaurHelmet(CCharacterComponent* c) {
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
}void FitMechagnomeHelmet(CCharacterComponent* c) {
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
int main(){Data d;Shared sh{&d};Model p,h,shoulder;p.m_shared=&sh;p.m_attachList=&h;h.m_attachNext=&shoulder;shoulder.m_attachmentId=5;CCharacterComponent c;c.m_data.m_model=&p;
for(unsigned race:{108u,102u,67u})for(unsigned sex:{0u,1u}){
 c.m_data.m_preferences={race,sex};unsigned head=race==108?29:race==102?67:sex?52:48;
 d.m_bones.m_count=race==108?251:race==102?208:sex?214:202;d.m_boneIndicesById[6]=head;d.m_bones[head].m_pivot=C3Vector(.874f,0,2.8f);h.calls=0;
 auto fit=[&](){if(race==108)FitNativePlayerHelmet(&c);if(race==102)FitCentaurHelmet(&c);if(race==67)FitMechagnomeHelmet(&c);};
 fit();if(race==67&&!sex){assert(h.calls==0);continue;}
 assert(h.calls==1&&h.bone==head);auto first=h.pos;auto shape=h.shape;fit();assert(h.calls==2&&h.pos.x==first.x&&h.shape.y==shape.y);
 if(race==108)assert(h.scale==(sex?2.5f:2.05f));if(race==102)assert(h.scale==(sex?1.9f:1.65f));if(race==67)assert(h.shape.y==1.22f);
 --d.m_bones.m_count;fit();assert(h.calls==2);++d.m_bones.m_count;c.m_itemDisplayID[0]=0;fit();assert(h.calls==2);c.m_itemDisplayID[0]=1;
}assert(shoulder.calls==0);
}
