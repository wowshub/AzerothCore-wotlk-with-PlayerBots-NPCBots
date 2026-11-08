from pathlib import Path
import json,struct,hashlib,mpyq,sys,math
W=Path(__file__).resolve().parent;D=W.parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf8'))
sys.path.insert(0,str(D/'codexwork_RACECOMBO1A'));from assets import dbc
sha=lambda b:hashlib.sha256(b).hexdigest()
m=json.loads((P/'manifest.json').read_text(encoding='utf8'));assert len(m)==1;e=m[0]
old=(P/'backup_原文件'/e['path']).read_bytes();new=(P/e['path']).read_bytes();assert sha(old)==e['input'] and sha(new)==e['output']
def check(b):
 na,oa=struct.unpack_from('<II',old,240);nb,ob=struct.unpack_from('<II',old,44)
 candidates=[oa+40*i for i in range(na) if struct.unpack_from('<I',old,oa+i*40)[0]==11]
 assert len(candidates)==1;at=candidates[0]
 assert len(b)==len(old) and b[:at+8]==old[:at+8] and b[at+20:]==old[at+20:]
 bone=struct.unpack_from('<H',b,at+4)[0];assert bone==175<nb
 pivot=struct.unpack_from('<3f',old,ob+bone*88+76);pos=struct.unpack_from('<3f',b,at+8)
 assert pos==pivot and all(math.isfinite(x) for x in pos)
 for offset,width in [(44,88),(60,48),(28,64),(80,16),(104,2),(128,2),(136,2),(248,2)]:
  n,o=struct.unpack_from('<II',old,offset);assert o+n*width<=len(old)
  assert b[o:o+n*width]==old[o:o+n*width]
 chain=[];i=bone
 while i>=0:
  assert i<nb and i not in chain;chain.append(i);i=struct.unpack_from('<h',old,ob+88*i+8)[0]
 return dict(only_attachment11_position_changed=True,head_bone_chain=chain,vertices_bones_animations_and_lookups_bit_identical=True,all_other_attachments_preserved=True)
report=check(new)
broken=bytearray(new);nv,ov=struct.unpack_from('<II',new,60);broken[ov]^=1
try:check(bytes(broken));raise RuntimeError('Validator accepted geometry corruption')
except AssertionError:report['negative_geometry_corruption_rejected']=True
C=R/'beascendclient/newrebornWOWli20261107beAscend';a=mpyq.MPQArchive(str(C/'Data/Patch-YB.mpq'),listfile=False)
live=a.read_file(e['path'].split('/',1)[1].replace('/','\\'));assert live==old
rows,st,nf,rs=dbc(a.read_file('DBFilesClient\\ChrRaces.dbc'));r=next(r for r in rows if r[0]==39);assert st[r[6]:st.find(b'\0',r[6])]==b'KT'
xa=mpyq.MPQArchive(str(C/'Data/Patch-XA.mpq'),listfile=False);raw=xa.read_file('DBFilesClient\\ItemDisplayInfo.dbc');rows,st,nf,rs=dbc(raw);r=next(r for r in rows if r[0]==57061)
model=st[r[1]:st.find(b'\0',r[1])].decode();assert model.lower()=='helm_robe_raidshaman_c_01.mdx'
report.update(current_male_and_KT_prefix_verified=True,display57061_model=model,ItemDisplayInfo_SHA256=sha(raw),game_test=False)
(W/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
print('PASS:one model, only attachment11 position; all other bytes preserved; broken geometry rejected; live KT prefix and57061 verified.')
