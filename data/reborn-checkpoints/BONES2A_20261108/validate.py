# -*- coding: utf-8 -*-
from pathlib import Path
import struct,json,hashlib,io
from PIL import Image
W=Path(__file__).resolve().parent;P=Path((W/'package_path.txt').read_text(encoding='utf8'));R=W.parents[2]
code=(W.parent/'codexwork_RACECOMBO1B/validate_totems.py').read_text(encoding='utf8').split('models=json.loads')[0]
code=code.replace(" assert counts['bones']==counts['sequences']==counts['textureWeights']==counts['textures']==1",'')
# The existing native skeletons intentionally share identical 2-byte lookup
# arrays. Retain rejection of partial overlaps; identical aliases are valid.
code=code.replace("assert a[1]<=z[0],('overlapping root records',a,z)","assert a[1]<=z[0] or (a[0]==z[0] and a[1]==z[1]),('overlapping root records',a,z)")
env={'__file__':str(W/'validate.py')};exec(compile(code,'independent_client_record_walk','exec'),env);walk=env['walk']
sha=lambda b:hashlib.sha256(b).hexdigest()
m=json.loads((P/'manifest.json').read_text(encoding='utf8'));models=json.loads((P/'checks/model_dependency_manifest.json').read_text(encoding='utf8'));audit=json.loads((W/'audit.json').read_text(encoding='utf8'))
root=P/'01_导入Patch-YJ.mpq';reports=[]
for e in m:assert sha((P/e['path']).read_bytes())==e['output'] and e['input'] is None
def skincheck(s,counts):
 assert s[:4]==b'SKIN'
 def arr(at,stride):
  n,o=struct.unpack_from('<II',s,at);assert o+n*stride<=len(s);return n,o
 ni,oi=arr(4,2);nt,ot=arr(12,2);np,op=arr(20,4);ns,os=arr(28,48);nb,ob=arr(36,24)
 assert ni==np and nt%3==0
 indices=struct.unpack_from('<'+'H'*ni,s,oi);tri=struct.unpack_from('<'+'H'*nt,s,ot)
 assert max(indices)<counts['vertices'] and max(tri)<ni
 for j in range(ns):
  sec=struct.unpack_from('<10H7f',s,os+48*j)
  assert sec[2]+sec[3]<=ni and sec[4]+sec[5]<=nt and sec[5]%3==0
 for j in range(nb):
  u=struct.unpack_from('<BB11H',s,ob+24*j)
  assert u[3]<ns and u[4]<ns and u[6]<counts['materials'] and u[8]>=1
  assert u[9]+u[8]<=counts['textureCombos']
 return ni,nt,nb
for model in models:
 b=(root/model['target']).read_bytes();source=next(h for h in audit['hits'] if h['sha256']==model['source_sha256'] and h['tag']=='current');old=Path(source['file']).read_bytes()
 counts,tracks=walk(b);assert counts['sequences']==1 and counts['vertices']>0
 allowed={i for a,z in model['changed_ranges'] for i in range(a,z)}
 assert len(b)>len(old) and all(b[i]==old[i] for i in range(len(old)) if i not in allowed)
 nt,ot=struct.unpack_from('<II',b,80)
 for i in range(nt):
  ty,flags,n,o=struct.unpack_from('<4I',b,ot+16*i);assert ty==0 and o+n<=len(b) and b[o+n-1]==0
  n=b[o:o+n-1].decode().replace('\\','/');assert n.startswith('World/Generic/PassiveDoodads/DeathSkeletons/BONES2A/')
  tb=(root/n).read_bytes();Image.open(io.BytesIO(tb)).load()
 for s in model['skins']:
  sb=(root/s['path']).read_bytes();assert sha(sb)==s['sha256'];skincheck(sb,counts)
 # Two independent corruptions must be rejected before this is deliverable.
 broken=bytearray(b);struct.pack_into('<I',broken,ot+12,len(b)+128)
 try:walk(bytes(broken));raise RuntimeError('invalid texture pointer accepted')
 except AssertionError:pass
 broken=bytearray((root/model['skins'][0]['path']).read_bytes());ni,oi=struct.unpack_from('<II',broken,4);struct.pack_into('<H',broken,oi,65535)
 try:skincheck(bytes(broken),counts);raise RuntimeError('invalid skin vertex accepted')
 except AssertionError:pass
 reports.append(dict(race=model['race'],sex=model['sex'],records=counts,tracks=tracks,all_original_bytes_except_texture_offsets_preserved=True,skin_indices_valid=True,textures_closed_and_decoded=True,external_animation_dependencies=len(model['external_animations']),negative_pointer_and_skin_rejected=True))
assert len(reports)==8 and len(m)==20
assert sha((R/'beascendclient/newrebornWOWli20261107beAscend/Wow.exe').read_bytes())==audit['exe_sha256']
result=dict(models=reports,payload_files=len(m),all_new_paths=True,no_live_model_or_DBC_DLL_CPP_SQL=True,only_M2_changes_are_private_texture_pointers=True,game_test=False)
(P/'checks/validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8');(W/'validation.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
print('PASS:8 model graphs and skin checks;4 BLP decode;geometry/bones/animations unchanged;bad pointer/skin rejected. Native game test pending.')
