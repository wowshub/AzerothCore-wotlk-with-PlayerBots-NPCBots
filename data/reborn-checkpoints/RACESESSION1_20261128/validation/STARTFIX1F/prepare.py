from pathlib import Path
import re,difflib,json
p=Path(r'D:/000rebornWOW/000RebornWOWHighForkPRO');day=p/'000Ascendupdate/000Ascendupdate20261127';w=day/'codexwork_STARTFIX1F';e=day/'codexwork_STARTFIX1E';b=p/'000Ascendupdate/000Ascendupdate20261126/codexwork_STARTFIX1B';old=b/'relink';t=p/'000Ascendupdate/000Ascendupdate20261124/codexwork_WOW64TITAN2C/client-src'
rel='Engine/Source/Model2/M2Model.h'
hpath=next(q for q in [b/'src'/rel,t/rel,Path('D:/_zsdc/fx/src')/rel] if q.exists())
h=hpath.read_text(encoding='utf8'); needle='    bool SetAttachmentFrame(uint32_t bone, const C3Vector& position, const C3Vector& scale, float yaw);';assert h.count(needle)==1
h=h.replace(needle,needle+'\n    bool SetAttachmentFrame(uint32_t bone, const C3Vector& position, const C3Vector& scale, float yaw, const C3Vector& modelOffset);')
cpp=(b/'src/Engine/Source/Model2/M2Model.cpp').read_text(encoding='utf8')
cpp=cpp.replace('    float yaw;\n};\nstd::map<const CM2Model*, AttachmentFrame>', '    float yaw;\n    C3Vector modelOffset; // STARTFIX1F: actor/model-space displacement, independent of animated socket axes.\n};\nstd::map<const CM2Model*, AttachmentFrame>',1)
needle='    matrix.Scale(frame.scale);\n}'
replacement='''    matrix.Scale(frame.scale);
    // Apply after the socket's rotated/scaled frame: model down stays model down.
    const C3Vector offset = TransformDirection(frame.modelOffset, parent->m_matrixF4);
    matrix.d0 += offset.x;
    matrix.d1 += offset.y;
    matrix.d2 += offset.z;
}'''
assert cpp.count(needle)==1;cpp=cpp.replace(needle,replacement,1)
needle='bool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, const C3Vector& scale, float yaw) {'
assert cpp.count(needle)==1;cpp=cpp.replace(needle,needle+'\n    return this->SetAttachmentFrame(bone, position, scale, yaw, C3Vector(0.0f, 0.0f, 0.0f));\n}\n\nbool CM2Model::SetAttachmentFrame(uint32_t bone, const C3Vector& position, const C3Vector& scale, float yaw, const C3Vector& modelOffset) {',1)
cpp=cpp.replace('        !std::isfinite(yaw) || !std::isfinite(position.x)', '        !std::isfinite(modelOffset.x) || !std::isfinite(modelOffset.y) || !std::isfinite(modelOffset.z) ||\n        !std::isfinite(yaw) || !std::isfinite(position.x)',1)
cpp=cpp.replace('old.scale.z == scale.z && old.yaw == yaw) return false;', 'old.scale.z == scale.z && old.yaw == yaw &&\n            old.modelOffset.x == modelOffset.x && old.modelOffset.y == modelOffset.y && old.modelOffset.z == modelOffset.z) return false;',1)
cpp=cpp.replace('AttachmentFrame{parent, this->m_shared, data, bone, position, scale, yaw}', 'AttachmentFrame{parent, this->m_shared, data, bone, position, scale, yaw, modelOffset}',1)
cpp=cpp.replace('return this->SetAttachmentFrame(frame.bone, frame.position, frame.scale, frame.yaw);','return this->SetAttachmentFrame(frame.bone, frame.position, frame.scale, frame.yaw, frame.modelOffset);',1)
r=(e/'src/WoW/Common/ComponentCore/RetailRace.cpp').read_text(encoding='utf8')
r=r.replace('        position.z -= 0.35f;\n        // Keep the authored angle/scale and derive an absolute offset from the native socket.','        // STARTFIX1F: leave socket coordinates intact; lower in actor space after bone rotation.')
r=r.replace('child->SetAttachmentFrame(socket.m_bone, position, 1.0f)', 'child->SetAttachmentFrame(socket.m_bone, position, C3Vector(1.0f, 1.0f, 1.0f), 0.0f, C3Vector(0.0f, 0.0f, -0.55f))')
for name,data in [('Engine/Source/Model2/M2Model.h',h),('Engine/Source/Model2/M2Model.cpp',cpp),('WoW/Common/ComponentCore/RetailRace.cpp',r)]:
 f=w/'src'/name;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(data,encoding='utf8')
wp=lambda x:str(x).replace('/','\\')
for name,source,fo in [('RetailRace',e/'RetailRace.rsp','RetailRace.obj'),('M2MODEL',old/'M2MODEL.rsp','M2MODEL.OBJ')]:
 rsp=source.read_text();rsp='/I"'+wp(w/'src')+'" '+rsp
 rsp=re.sub(r'/Fo"[^"]+"','/Fo"'+wp(w/fo).replace('\\','\\\\')+'"',rsp)
 target=w/'src'/('WoW/Common/ComponentCore/RetailRace.cpp' if name=='RetailRace' else 'Engine/Source/Model2/M2Model.cpp')
 rsp=re.sub(r'"[^"]+\\'+name+r'\.cpp"',lambda m:'"'+wp(target)+'"',rsp,flags=re.I)
 (w/(name+'.rsp')).write_text(rsp)
for name,srcpath,objname in [('WoWCommon',e/'WoWCommon.rsp','RetailRace.obj'),('Model2',old/'Model2.rsp','M2MODEL.OBJ')]:
 rsp=srcpath.read_text();rsp=re.sub(r'/OUT:"[^"]+"',lambda m:'/OUT:"'+wp(w/(name+'.lib'))+'"',rsp)
 rsp=re.sub(r'"[^"]+\\'+re.escape(objname)+'"',lambda m:'"'+wp(w/objname)+'"',rsp,flags=re.I);(w/(name+'.rsp')).write_text(rsp)
rsp=(e/'WowClient64.rsp').read_text().replace(wp(e/'WoWCommon.lib'),wp(w/'WoWCommon.lib')).replace(wp(old/'Model2.lib'),wp(w/'Model2.lib'))
for flag,ext in [('OUT','exe'),('PDB','pdb'),('IMPLIB','lib'),('MAP','map')]:rsp=re.sub('/'+flag+r':"[^"]+"',lambda m:'/'+flag+':"'+wp(w/('WowClient64.'+ext))+'"',rsp,flags=re.I)
(w/'WowClient64.rsp').write_text(rsp)
(w/'header-baseline.txt').write_text(str(hpath))
(w/'source.diff').write_text(''.join(difflib.unified_diff((e/'src/WoW/Common/ComponentCore/RetailRace.cpp').read_text().splitlines(True),r.splitlines(True),fromfile='1E/RetailRace.cpp',tofile='1F/RetailRace.cpp'))+'\n'+''.join(difflib.unified_diff((b/'src/Engine/Source/Model2/M2Model.cpp').read_text().splitlines(True),cpp.splitlines(True),fromfile='1B/M2Model.cpp',tofile='1F/M2Model.cpp')),encoding='utf8')
print('Prepared independent cumulative overlay')
