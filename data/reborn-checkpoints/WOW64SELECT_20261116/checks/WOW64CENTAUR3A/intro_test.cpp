
#include <cassert>
#include <cstdint>
#include <vector>
enum{ATTACH_HANDRIGHT=1,ATTACH_HANDLEFT=2};
struct CM2Model{float m_fadeAlpha=1;CM2Model*m_attachList=nullptr,*m_attachNext=nullptr;unsigned m_attachmentId=0;int calls=0;bool hidden=false;void SetRenderSuppressed(bool b){hidden=b;}void SetBoneSequence(uint32_t bone,uint32_t id,uint32_t variation,uint32_t time,float speed,int blend,int primary){assert(bone==0xffffffff&&id==0&&variation==0xffffffff&&time==0&&speed==1&&blend==0&&primary==1);++calls;}};
struct Component{struct{CM2Model*m_model;}m_data;};
struct CharacterSelectionDisplay{Component*m_component;struct{unsigned m_raceID;}m_characterInfo;CM2Model*m_petModel=nullptr;};
struct Arr{std::vector<CharacterSelectionDisplay>v;unsigned Count(){return unsigned(v.size());}CharacterSelectionDisplay&operator[](unsigned i){return v[i];}};
struct CCharacterSelection{static Arr s_characterList;};Arr CCharacterSelection::s_characterList;
bool s_introFading=false;int s_introSalute=0;uint32_t s_introStartMs=0,s_introReadyFrame=0;float s_introBaseAlpha=1;Component*s_introComponent=nullptr;
uint32_t OsGetAsyncTimeMs(){return 100;}
static void SetHandItemsHidden(CM2Model* model, bool hidden) {
    for (CM2Model* attached = model->m_attachList; attached; attached = attached->m_attachNext) {
        if (attached->m_attachmentId == ATTACH_HANDRIGHT || attached->m_attachmentId == ATTACH_HANDLEFT) {
            attached->m_fadeAlpha = hidden ? 0.0f : 1.0f;
        }
    }
}static void BeginSelectionIntro(CharacterSelectionDisplay& display, bool newComponent) {
    // A pick made mid-salute must not leave the previous character unarmed.
    for (uint32_t i = 0; i < CCharacterSelection::s_characterList.Count(); i++) {
        CharacterSelectionDisplay& other = CCharacterSelection::s_characterList[i];

        if (other.m_component && other.m_component->m_data.m_model) {
            SetHandItemsHidden(other.m_component->m_data.m_model, false);
            other.m_component->m_data.m_model->SetRenderSuppressed(false);
        }
    }

    CM2Model* model = display.m_component ? display.m_component->m_data.m_model : nullptr;

    if (!model) {
        return;
    }

    // Reselecting mid-fade must not take the half-faded alpha as the character's real one (ghosts are translucent).
    if (newComponent || !s_introFading || s_introComponent != display.m_component) {
        s_introBaseAlpha = model->m_fadeAlpha;
    }

    s_introComponent = display.m_component;
    s_introReadyFrame=0xffffffff;
    model->SetRenderSuppressed(display.m_characterInfo.m_raceID==102);
    s_introFading = true;
    s_introSalute = 0;
    // CENTAUR3A: this rig's 113 is a Stand alias, not an authored salute.
    // Queue/restore the real Stand before the readiness barrier, including
    // cached roster entries. Never blend from the collapsed alias pose.
    if(display.m_characterInfo.m_raceID==102) {
        model->SetBoneSequence(0xFFFFFFFF,0,0xFFFFFFFF,0,1.0f,0,1);
        s_introSalute=2;
    }
    s_introStartMs = OsGetAsyncTimeMs();
    model->m_fadeAlpha = 0.0f;

    if (display.m_petModel) {
        display.m_petModel->m_fadeAlpha = 0.0f;
    }
}
int main(){for(unsigned race:{102u,28u,67u,108u,50u,36u}){
 CM2Model model,hand,pet;model.m_attachList=&hand;hand.m_attachmentId=1;hand.m_fadeAlpha=0;Component c{{&model}};CharacterSelectionDisplay d{&c,{race},&pet};CCharacterSelection::s_characterList.v={d};
 BeginSelectionIntro(d,true);assert(model.m_fadeAlpha==0&&pet.m_fadeAlpha==0&&hand.m_fadeAlpha==1);
 assert(model.hidden==(race==102));assert(model.calls==(race==102?1:0));assert(s_introSalute==(race==102?2:0));
 BeginSelectionIntro(d,false);assert(model.calls==(race==102?2:0));assert(s_introBaseAlpha==1);
} }
