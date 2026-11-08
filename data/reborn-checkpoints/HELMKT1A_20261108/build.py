from pathlib import Path
import struct,json,hashlib,mpyq,math
import numpy as np
W=Path(__file__).resolve().parent;R=W.parents[2];D=W.parent
P=D/'codexfix_20261108_阶段HELMKT1A_库尔男性头盔挂点基准修正候选'
assert not P.with_suffix('.zip').exists();P.mkdir(exist_ok=True);(W/'package_path.txt').write_text(str(P),encoding='utf8')
C=R/'beascendclient/newrebornWOWli20261107beAscend';n='Character/RebornUIR3A/KulTiran/Male/kultiranmale.m2'
sha=lambda b:hashlib.sha256(b).hexdigest()
a=mpyq.MPQArchive(str(C/'Data/Patch-YB.mpq'),listfile=False);old=a.read_file(n.replace('/','\\'))
assert sha(old)=='80e7ae1f66e38b2e586b818d80ee01a2d1b302470250f54b4df34d75f33a133e'
assert old==(W/'inputs'/n).read_bytes()
b=bytearray(old);na,oa=struct.unpack_from('<II',b,240);nb,ob=struct.unpack_from('<II',b,44)
index=[i for i in range(na) if struct.unpack_from('<I',b,oa+40*i)[0]==11];assert len(index)==1
at=oa+index[0]*40;bone=struct.unpack_from('<H',b,at+4)[0];assert bone==175
pos=struct.unpack_from('<3f',b,at+8);pivot=struct.unpack_from('<3f',b,ob+bone*88+76)
assert all(abs(x-y)<1e-5 for x,y in zip(pos,[.1,0,2.600470066]))
assert all(abs(x-y)<1e-5 for x,y in zip(pivot,[-.066322185,0,2.390470266]))
# Restore the attachment point to its existing helmet-bone pivot. The native
# KT helmet meshes already have their own race-specific offsets and scale.
struct.pack_into('<3f',b,at+8,*pivot)
assert len(b)==len(old) and b[:at+8]==old[:at+8] and b[at+20:]==old[at+20:]
rel='01_导入Patch-YB.mpq/'+n
for root,data in [(P,bytes(b)),(P/'backup_原文件',old)]:
 f=root/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(data)
(P/'manifest.json').write_text(json.dumps([dict(path=rel,input=sha(old),output=sha(b))],ensure_ascii=False,indent=2),encoding='utf8')
# Inspect, do not alter, the helper's actual fixed global rotation. Evaluate
# both point locations in the same helper transform, not by adding a pivot twice.
ip,g,nt,ot,nv,ov=struct.unpack_from('<Hh4I',old,ob+175*88+36);assert g==0
nk,ok=struct.unpack_from('<II',old,ot);nv,oval=struct.unpack_from('<II',old,ov);assert nk==nv
raw=[struct.unpack_from('<4h',old,oval+8*i) for i in range(nv)];assert len(set(raw))==1
q=np.array([(v+32768)/32767 if v<0 else (v-32767)/32767 for v in raw[0]]);q=q/np.linalg.norm(q)
x,y,z,w=q
rot=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],[2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],[2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]])
fits=[]
for filename in ['Helm_Robe_RaidShaman_C_01_KTM.m2','Helm_Mail_Northrend_D_01_KTM.m2']:
 h=(W/'inputs/Item/ObjectComponents/Head'/filename).read_bytes();nv,vo=struct.unpack_from('<II',h,60)
 verts=np.array([struct.unpack_from('<3f',h,vo+i*48) for i in range(nv)])
 # Pivot + R * ((mesh + attachment-position) - pivot) is a bind-space
 # comparison. The animated head ancestor matrix is common to both cases.
 before=np.array(pivot)+(verts+np.array(pos)-np.array(pivot))@rot.T
 after=np.array(pivot)+verts@rot.T
 fits.append(dict(helmet=filename,source_sha256=sha(h),before_bounds=[before.min(0).tolist(),before.max(0).tolist()],after_bounds=[after.min(0).tolist(),after.max(0).tolist()]))
report=dict(input_sha256=sha(old),output_sha256=sha(b),attachment=11,bone=175,attachment_record=index[0],position_offset=at+8,old_position=list(pos),new_position=list(pivot),model_space_delta=(np.array(pivot)-np.array(pos)).tolist(),helper_rotation_raw=list(raw[0]),helper_rotation_unchanged=True,
 only_attachment_position_12byte_range_changed=True,all_geometry_UVs_bones_animations_skin_unchanged=True,reference_helmets=fits,
 native_runtime_transform_not_instrumented=True,bind_space_comparison_not_game_test=True,game_test=False)
(W/'patch.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('Built one male model, only attachment11 coordinates changed. '+sha(b))
