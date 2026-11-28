from pathlib import Path
w=Path(r'D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261127/codexwork_STARTFIX1F');s=(w/'src/Engine/Source/Model2/M2Model.cpp').read_text()
frame=s[s.index('struct AttachmentFrame {'):s.index('std::map<const CM2Model*, bool> s_renderSuppressed;')]
apply=s[s.index('void ApplyAttachmentFrame('):s.index('bool SameSkinPivot(')]
methods=s[s.index('bool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, float scale)'):s.index('// VERIFY: 767a1eb1 auto',s.index('bool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, float scale)'))]
pre=r'''#include <cassert>
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
'''
post=r'''
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
'''
(w/'matrix-fixture.cpp').write_text(pre+frame+apply+methods+post)
