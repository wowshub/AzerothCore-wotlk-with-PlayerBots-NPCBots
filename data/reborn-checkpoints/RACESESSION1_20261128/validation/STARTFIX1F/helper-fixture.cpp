#include <cstdint>
#include <cassert>
#include <cmath>
#include <cstring>
#include <cstdio>
struct Vec {Vec()=default;Vec(float a,float b,float c):x(a),y(b),z(c){}float x=1,y=2,z=3;};
using C3Vector=Vec;
struct C44Matrix {int marker=42;};
struct Socket {unsigned m_bone=1; Vec m_position;};
struct Array {unsigned m_count=1; Socket value; const Socket& operator[](unsigned)const{return value;}};
struct Rig {Array m_attachments; struct {unsigned m_count=2;} m_bones;};
struct Shared {Rig* m_data=nullptr; const char* m_fileName="Item/Staff_Test.m2";};
struct Model {unsigned m_fFlags=1; Shared* m_shared=nullptr; Model* m_attachList=nullptr; Model* m_attachNext=nullptr; unsigned m_attachmentIndex=0,m_attachmentId=30; C44Matrix m_worldTransform; int calls=0; Vec applied; unsigned bone=99; float scale=0;Vec offset;
 bool SetAttachmentFrame(unsigned b,Vec p,Vec sizes,float yaw,Vec move){float s=sizes.x;offset=move;++calls;bool changed=bone!=b||applied.z!=p.z;bone=b;applied=p;scale=s;if(changed)m_worldTransform.marker=0;return changed;}
 void SetWorldTransform(C44Matrix m){m_worldTransform=m;}};
struct CCharacterComponent {struct {Model* m_model;struct{unsigned m_raceID=27;}m_preferences;}m_data;unsigned form=3;};
namespace app {enum {FormDragon=3};}
enum {ATTACH_BACK=30,ATTACH_BACK_OFFHAND=31,ATTACH_SHEATH_MAINHAND=26};
bool IsRetailModel(Model*){return true;} unsigned RetailRaceId(unsigned r){return r==27?52:r;}unsigned ActiveForm(CCharacterComponent*c){return c->form;}

#include <initializer_list>
static void FitDracthyrSheathedStaff(CCharacterComponent* character) {
    auto* model = character ? character->m_data.m_model : nullptr;
    if (!model || !(model->m_fFlags & 1) || !model->m_shared
        || !model->m_shared->m_data || !IsRetailModel(model)) return;
    const uint32_t retail = RetailRaceId(character->m_data.m_preferences.m_raceID);
    if ((retail != 52 && retail != 70) || ActiveForm(character) != app::FormDragon) return;
    const auto* rig = model->m_shared->m_data;
    for (auto* child = model->m_attachList; child; child = child->m_attachNext) {
        if (!child->m_shared || child->m_attachmentIndex >= rig->m_attachments.m_count) continue;
        if (child->m_attachmentId != ATTACH_BACK && child->m_attachmentId != ATTACH_BACK_OFFHAND
            && child->m_attachmentId != ATTACH_SHEATH_MAINHAND) continue;
        const char* name = child->m_shared->m_fileName;
        if (!name) continue;
        for (const char* cursor = name; *cursor; ++cursor)
            if (*cursor == '/' || *cursor == char(92)) name = cursor + 1;
        if (_strnicmp(name, "Staff", 5) && _strnicmp(name, "Stave", 5)) continue;
        const auto& socket = rig->m_attachments[child->m_attachmentIndex];
        if (socket.m_bone >= rig->m_bones.m_count) continue;
        auto position = socket.m_position;
        // STARTFIX1F: leave socket coordinates intact; lower in actor space after bone rotation.
        const C44Matrix local = child->m_worldTransform;
        if (child->SetAttachmentFrame(socket.m_bone, position, C3Vector(1.0f, 1.0f, 1.0f), 0.0f, C3Vector(0.0f, 0.0f, -0.55f)))
            child->SetWorldTransform(local);
    }
}

int main(){Rig rig; Shared body{&rig},weapon;Model child;child.m_shared=&weapon;Model parent;parent.m_shared=&body;parent.m_attachList=&child;CCharacterComponent c{{&parent}};
 for(unsigned race:{27u,70u})for(unsigned id:{30u,31u,26u}){c.m_data.m_preferences.m_raceID=race;child.m_attachmentId=id;FitDracthyrSheathedStaff(&c);assert(std::abs(child.applied.z-3.f)<.00001f);assert(child.applied.x==1&&child.applied.y==2&&child.bone==1&&child.scale==1&&std::abs(child.offset.z+.55f)<.00001f&&child.m_worldTransform.marker==42);}
 for(int i=0;i<100;i++)FitDracthyrSheathedStaff(&c);assert(std::abs(child.applied.z-3.f)<.00001f);assert(child.m_worldTransform.marker==42);
 int n=child.calls;child.m_attachmentId=0;FitDracthyrSheathedStaff(&c);assert(n==child.calls);child.m_attachmentId=30;
 weapon.m_fileName="Item/Sword_Test.m2";FitDracthyrSheathedStaff(&c);assert(n==child.calls);
 weapon.m_fileName="Item\\Stave_Test.m2";c.form=4;FitDracthyrSheathedStaff(&c);assert(n==child.calls);c.form=3;
 c.m_data.m_preferences.m_raceID=50;FitDracthyrSheathedStaff(&c);assert(n==child.calls);c.m_data.m_preferences.m_raceID=27;
 parent.m_fFlags=0;FitDracthyrSheathedStaff(&c);assert(n==child.calls);parent.m_fFlags=1;
 child.m_attachmentIndex=1;FitDracthyrSheathedStaff(&c);assert(n==child.calls);child.m_attachmentIndex=0;
 rig.m_attachments.value.m_bone=2;FitDracthyrSheathedStaff(&c);assert(n==child.calls);rig.m_attachments.value.m_bone=1;
 FitDracthyrSheathedStaff(nullptr);weapon.m_fileName=nullptr;FitDracthyrSheathedStaff(&c);assert(n==child.calls);
 weapon.m_fileName="Item\\sTaFf_Test.m2";FitDracthyrSheathedStaff(&c);assert(n+1==child.calls);
 puts("PASS: dragon IDs, three sheath sockets, actor-space offset/no drift, authored local matrix; held weapon/sword/visage/other race/unloaded/bounds/null guards. Fixture does not prove in-game fit or runtime detach.");}
