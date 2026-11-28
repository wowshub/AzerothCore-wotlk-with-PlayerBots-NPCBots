#include <cassert>
#include <cmath>
#include <cstdio>
#include <map>
#include <mutex>
#include "Engine/Source/Tempest/C44Matrix.h"
struct M2Data {struct{unsigned m_count=1;}m_bones;};
struct CM2Shared {M2Data* m_data;};
struct CM2Model {CM2Model* m_attachParent=nullptr;unsigned m_fFlags=1,m_attachmentIndex=0;CM2Shared* m_shared=nullptr;C44Matrix* m_boneMatrices=nullptr;C44Matrix m_matrixF4,m_worldTransform;
 bool SetAttachmentFrame(uint32_t,const C3Vector&,float=1);
 bool SetAttachmentFrame(uint32_t,const C3Vector&,const C3Vector&);
 bool SetAttachmentFrame(uint32_t,const C3Vector&,const C3Vector&,float);
 bool SetAttachmentFrame(uint32_t,const C3Vector&,const C3Vector&,float,const C3Vector&);
};
std::mutex s_skinParentMutex;
struct AttachmentFrame {
    CM2Model* parent;
    const CM2Shared* childShared;
    const M2Data* parentData;
    uint32_t bone;
    C3Vector position;
    C3Vector scale;
    float yaw;
    C3Vector modelOffset; // STARTFIX1F: actor/model-space displacement, independent of animated socket axes.
};
std::map<const CM2Model*, AttachmentFrame> s_attachmentFrames;
void ApplyAttachmentFrame(CM2Model* child, CM2Model* parent, C44Matrix& matrix) {
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    const auto found = s_attachmentFrames.find(child);
    if (found == s_attachmentFrames.end()) return;
    const auto& frame = found->second;
    if (child->m_attachParent != parent || frame.parent != parent || child->m_shared != frame.childShared ||
        !parent->m_shared || parent->m_shared->m_data != frame.parentData ||
        frame.bone >= frame.parentData->m_bones.m_count || !parent->m_boneMatrices) {
        s_attachmentFrames.erase(found);
        return;
    }
    matrix = parent->m_boneMatrices[frame.bone];
    matrix.Translate(frame.position);
    if (frame.yaw != 0.0f) matrix.RotateAroundZ(frame.yaw);
    matrix.Scale(frame.scale);
    // Apply after the socket's rotated/scaled frame: model down stays model down.
    const C3Vector offset = TransformDirection(frame.modelOffset, parent->m_matrixF4);
    matrix.d0 += offset.x;
    matrix.d1 += offset.y;
    matrix.d2 += offset.z;
}

bool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, float scale) {
    return this->SetAttachmentFrame(bone,position,C3Vector(scale,scale,scale));
}

bool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, const C3Vector& scale) {
    return this->SetAttachmentFrame(bone, position, scale, 0.0f);
}

bool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, const C3Vector& scale, float yaw) {
    return this->SetAttachmentFrame(bone, position, scale, yaw, C3Vector(0.0f, 0.0f, 0.0f));
}

bool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, const C3Vector& scale, float yaw, const C3Vector& modelOffset) {
    CM2Model* parent = this->m_attachParent;
    if (!parent || !(parent->m_fFlags & 1) || this->m_attachmentIndex == 0xffff ||
        !this->m_shared || !parent->m_shared || !parent->m_shared->m_data ||
        bone >= parent->m_shared->m_data->m_bones.m_count ||
        !std::isfinite(modelOffset.x) || !std::isfinite(modelOffset.y) || !std::isfinite(modelOffset.z) ||
        !std::isfinite(yaw) || !std::isfinite(position.x) || !std::isfinite(position.y) || !std::isfinite(position.z) ||
        !std::isfinite(scale.x) || !std::isfinite(scale.y) || !std::isfinite(scale.z) || scale.x <= 0 || scale.y <= 0 || scale.z <= 0) return false;
    std::lock_guard<std::mutex> lock(s_skinParentMutex);
    const M2Data* data = parent->m_shared->m_data;
    const auto found = s_attachmentFrames.find(this);
    if (found != s_attachmentFrames.end()) {
        const auto& old = found->second;
        if (old.parent == parent && old.childShared == this->m_shared && old.parentData == data &&
            old.bone == bone && old.position.x == position.x && old.position.y == position.y &&
            old.position.z == position.z && old.scale.x == scale.x && old.scale.y == scale.y && old.scale.z == scale.z && old.yaw == yaw &&
            old.modelOffset.x == modelOffset.x && old.modelOffset.y == modelOffset.y && old.modelOffset.z == modelOffset.z) return false;
    }
    s_attachmentFrames.insert_or_assign(this, AttachmentFrame{parent, this->m_shared, data, bone, position, scale, yaw, modelOffset});
    // The replacement socket carries the full correction; discard a previous local socket shift.
    this->m_worldTransform.Identity();
    this->m_fFlags |= 0x8000;
    return true;
}


bool close(float a,float b){return std::fabs(a-b)<.0001f;}
int main(){M2Data data;CM2Shared shared{&data};CM2Model parent,child;parent.m_shared=&shared;child.m_shared=&shared;child.m_attachParent=&parent;C44Matrix bones[1];parent.m_boneMatrices=bones;
 for(int i=0;i<20;i++){parent.m_matrixF4=C44Matrix::RotationAroundX(.13f*i)*C44Matrix::RotationAroundZ(.25f*i);parent.m_matrixF4.Scale(1.3f);bones[0]=C44Matrix::RotationAroundY(.22f*i)*parent.m_matrixF4;
  C3Vector socket(.2f,.3f,.4f);child.SetAttachmentFrame(0,socket,C3Vector(1,1,1),0,C3Vector(0,0,0));C44Matrix original;ApplyAttachmentFrame(&child,&parent,original);
  assert(child.SetAttachmentFrame(0,socket,C3Vector(1,1,1),0,C3Vector(0,0,-.55f)));assert(!child.SetAttachmentFrame(0,socket,C3Vector(1,1,1),0,C3Vector(0,0,-.55f)));
  C44Matrix actual;for(int n=0;n<100;n++)ApplyAttachmentFrame(&child,&parent,actual);
  auto delta=TransformDirection(C3Vector(0,0,-.55f),parent.m_matrixF4);assert(close(actual.d0-original.d0,delta.x)&&close(actual.d1-original.d1,delta.y)&&close(actual.d2-original.d2,delta.z));
  const float* a=&actual.a0;const float* b=&original.a0;for(int k=0;k<12;k++)assert(close(a[k],b[k]));
 }
 parent.m_matrixF4.Identity();bones[0]=C44Matrix::RotationAroundX(3.14159265f);C44Matrix old=bones[0];old.Translate(C3Vector(0,0,-.35f));assert(old.d2>0.349f); // old local-down becomes actor-up
 C3Vector socket(0,0,0);child.SetAttachmentFrame(0,socket,C3Vector(1,1,1),0,C3Vector(0,0,-.55f));C44Matrix fixed;ApplyAttachmentFrame(&child,&parent,fixed);assert(close(fixed.d2,-.55f));
 child.SetAttachmentFrame(0,socket,1.0f);ApplyAttachmentFrame(&child,&parent,fixed);assert(close(fixed.d2,0));
 assert(!child.SetAttachmentFrame(0,socket,C3Vector(1,1,1),0,C3Vector(NAN,0,0)));assert(!child.SetAttachmentFrame(9,socket,C3Vector(1,1,1),0,C3Vector(0,0,-.55f)));
 child.m_attachParent=nullptr;ApplyAttachmentFrame(&child,&parent,fixed);assert(s_attachmentFrames.empty());
 puts("PASS: actual ApplyAttachmentFrame and SetAttachmentFrame with real Tempest matrices: 20 animated bone/body/view transforms x100 repetitions, model-down displacement, orientation intact, old inverted-bone up reproduced, zero-offset legacy behavior, finite/bounds guards and parent invalidation.");}
