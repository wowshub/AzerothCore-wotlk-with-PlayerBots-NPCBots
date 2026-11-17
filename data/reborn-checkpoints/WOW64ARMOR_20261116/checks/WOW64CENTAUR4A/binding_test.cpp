
#include <cassert>
#include <cstdint>
#include <vector>
#include <map>
#include <set>
#include <mutex>
#include <cmath>
#include <cstdio>
struct M2Data{};struct Shared{M2Data*m_data;};
struct Matrix{float v[16]{};};
struct CM2Model{CM2Model*m_attachParent=nullptr;unsigned m_attachmentIndex=0xffff,m_fFlags=0x40001;Shared*m_shared=nullptr;Matrix*m_boneMatrices=nullptr;Matrix m_matrixF4;float m_scaleSq=1;CM2Model*m_attachList=nullptr,*m_attachNext=nullptr;unsigned m_attachmentId=0;bool HasSkinParent(const CM2Model*)const;};
struct SkinParentBinding{CM2Model*parent;const M2Data*childData;const M2Data*parentData;std::vector<uint16_t>bones;};
struct AttachmentFrame{CM2Model*parent;};
std::mutex s_skinParentMutex;std::map<const CM2Model*,SkinParentBinding>s_skinParents;std::map<const CM2Model*,AttachmentFrame>s_attachmentFrames;std::map<const CM2Model*,bool>s_renderSuppressed;
struct CCharacterComponent{struct{struct{unsigned m_raceID=102;}m_preferences;CM2Model*m_model;}m_data;};
struct Outfit{bool texture=true;};std::map<CCharacterComponent*,Outfit>selectorOutfits;std::set<CCharacterComponent*>pendingSelectorBind;
void ClearSkinParents(CM2Model* model) {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    s_renderSuppressed.erase(model);
    for (auto it = s_skinParents.begin(); it != s_skinParents.end();) {
        if (it->first == model || it->second.parent == model) it = s_skinParents.erase(it);
        else ++it;
    }
    for (auto it = s_attachmentFrames.begin(); it != s_attachmentFrames.end();) {
        if (it->first == model || it->second.parent == model) it = s_attachmentFrames.erase(it);
        else ++it;
    }
}void ClearDetachedAttachment(CM2Model* model) {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    s_renderSuppressed.erase(model);
    s_skinParents.erase(model);
    s_attachmentFrames.erase(model);
}void CopySkinParentPose(CM2Model* child) {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    const auto found = s_skinParents.find(child);
    if (found == s_skinParents.end()) return;
    const auto& binding = found->second;
    CM2Model* parent = binding.parent;
    if (child->m_attachParent != parent || child->m_attachmentIndex != 0xffff ||
        !(child->m_fFlags & 0x40000) || !(parent->m_fFlags & 1) ||
        !child->m_shared || !parent->m_shared || child->m_shared->m_data != binding.childData ||
        parent->m_shared->m_data != binding.parentData || !child->m_boneMatrices || !parent->m_boneMatrices) {
        s_skinParents.erase(found);
        return;
    }
    // Matrices already contain the parent's animation and view transform. Copy,
    // never alias: both model instances own and free their own matrix allocation.
    for (size_t i = 0; i < binding.bones.size(); ++i)
        child->m_boneMatrices[i] = parent->m_boneMatrices[binding.bones[i]];
    child->m_matrixF4 = parent->m_matrixF4;
    child->m_scaleSq = parent->m_scaleSq;
}bool CM2Model::HasSkinParent(const CM2Model* parent) const {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    const auto found = s_skinParents.find(this);
    if (!parent || found == s_skinParents.end()) return false;
    const auto& binding = found->second;
    return binding.parent == parent && this->m_attachParent == parent &&
        this->m_attachmentIndex == 0xffff && (this->m_fFlags & 0x40000) &&
        (this->m_fFlags & 1) && (parent->m_fFlags & 1) && this->m_shared && parent->m_shared &&
        this->m_shared->m_data == binding.childData && parent->m_shared->m_data == binding.parentData &&
        this->m_boneMatrices && parent->m_boneMatrices;
}bool EsteriaNativeEquipmentPending(CCharacterComponent* character) {
    if(pendingSelectorBind.count(character))return true;
    // CENTAUR4A: cached actors may outlive a model/attachment rebuild. Repair
    // the Centaur collection before rendering, even when item IDs are unchanged.
    if(character&&character->m_data.m_preferences.m_raceID==102) {
        const auto outfit=selectorOutfits.find(character);
        auto* parent=character->m_data.m_model;
        if(outfit!=selectorOutfits.end()&&outfit->second.texture&&parent) {
            for(auto* child=parent->m_attachList;child;child=child->m_attachNext)
                if(child->m_attachmentId==0xee000102u)return !child->HasSkinParent(parent);
            return true;
        }
    }
    return false;
}void OldDetachCleanup(CM2Model* model) {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    s_renderSuppressed.erase(model);
    for (auto it = s_skinParents.begin(); it != s_skinParents.end();) {
        if (it->first == model || it->second.parent == model) it = s_skinParents.erase(it);
        else ++it;
    }
    for (auto it = s_attachmentFrames.begin(); it != s_attachmentFrames.end();) {
        if (it->first == model || it->second.parent == model) it = s_attachmentFrames.erase(it);
        else ++it;
    }
}
bool equal(const Matrix&a,const Matrix&b){for(int i=0;i<16;++i)if(a.v[i]!=b.v[i])return false;return true;}
int main(){
 M2Data d,cd;Shared ps{&d},cs{&cd};Matrix pm[208],cm[208];CM2Model bg,body,cloth,helm,unrelated;
 body.m_shared=&ps;body.m_boneMatrices=pm;body.m_attachParent=&bg;cloth.m_shared=&cs;cloth.m_boneMatrices=cm;cloth.m_attachParent=&body;cloth.m_attachmentId=0xee000102u;body.m_attachList=&cloth;
 CCharacterComponent c;c.m_data.m_model=&body;selectorOutfits[&c]={true};
 std::vector<uint16_t>indices(208);for(unsigned i=0;i<208;++i)indices[i]=uint16_t(i);
 auto bind=[&](){s_skinParents[&cloth]={&body,&cd,&d,indices};s_attachmentFrames[&helm]={&body};};
 bind();assert(cloth.HasSkinParent(&body)&&!EsteriaNativeEquipmentPending(&c));
 OldDetachCleanup(&body);assert(!cloth.HasSkinParent(&body));assert(EsteriaNativeEquipmentPending(&c)); // reproduce the old lost follow
 unsigned checks=0;
 for(unsigned sex=0;sex<2;++sex)for(unsigned pose=0;pose<100;++pose){
  bind();s_skinParents[&body]={&bg,&d,&d,{0}};s_attachmentFrames[&body]={&bg};s_renderSuppressed[&body]=true;
  ClearDetachedAttachment(&body);body.m_attachParent=&unrelated;
  assert(!s_skinParents.count(&body)&&!s_attachmentFrames.count(&body)&&!s_renderSuppressed.count(&body));
  assert(cloth.HasSkinParent(&body)&&s_attachmentFrames.count(&helm));
  for(unsigned i=0;i<208;++i)for(unsigned k=0;k<16;++k)pm[i].v[k]=float(i*100+pose+k+sex);
  CopySkinParentPose(&cloth);for(unsigned i=0;i<208;++i){assert(equal(pm[i],cm[i]));++checks;}
  assert(!EsteriaNativeEquipmentPending(&c));
 }
 ClearDetachedAttachment(&cloth);assert(!cloth.HasSkinParent(&body)&&EsteriaNativeEquipmentPending(&c));
 c.m_data.m_preferences.m_raceID=108;assert(!EsteriaNativeEquipmentPending(&c));c.m_data.m_preferences.m_raceID=102;
 body.m_attachList=nullptr;assert(EsteriaNativeEquipmentPending(&c));selectorOutfits.erase(&c);assert(!EsteriaNativeEquipmentPending(&c));pendingSelectorBind.insert(&c);assert(EsteriaNativeEquipmentPending(&c));pendingSelectorBind.clear();body.m_attachList=&cloth;
 bind();cloth.m_attachParent=&body;ClearSkinParents(&body);assert(!s_skinParents.count(&cloth)&&!s_attachmentFrames.count(&helm));
 bind();cloth.m_attachParent=&body;ps.m_data=&cd;CopySkinParentPose(&cloth);assert(!s_skinParents.count(&cloth)); // replaced parent rig rejects stale binding
 printf("old detach loss reproduced; %u mapped-matrix checks across both sexes/poses; detach, rebind, missing collection, other races, unload and rig replacement passed\n",checks);
}
