from pathlib import Path
from struct import unpack_from as U,pack_into as P
from hashlib import sha256
from PIL import Image
from io import BytesIO
import json,collections,math
W=Path('stormforged-intake/bodygear1a');report={};geometry=json.loads((W/'geometry-report.json').read_text())
def arr(b,h,size):
 n,o=U('<2I',b,h);assert o+n*size<=len(b);return [b[o+i*size:o+(i+1)*size] for i in range(n)]
def val16(b,h):return [U('<H',v)[0] for v in arr(b,h,2)]
def valid_resources(m,s):
 nv,vo=U('<2I',m,60);boneN,_=U('<2I',m,44);idx=val16(s,4);tri=val16(s,12);props=arr(s,20,4);sec=arr(s,28,48);batches=arr(s,36,24)
 assert len(idx)==len(props) and max(idx)<nv and max(tri)<len(idx)
 bones=val16(m,120);tx=arr(m,80,16);mat=arr(m,112,4);combo=val16(m,128);coord=val16(m,136);weight=val16(m,144);trans=val16(m,152)
 tracks=arr(m,88,20)
 for v in sec:
  gid,hi,vs,vc,ts,tc,bn,bc,inf,centre=U('<10H',v);ts|=hi<<16
  assert vs+vc<=len(idx) and ts+tc<=len(tri) and tc%3==0 and bc+bn<=len(bones) and inf<=4 and centre<boneN
  assert all(vs<=j<vs+vc for j in tri[ts:ts+tc])
  for j in range(vs,vs+vc):
   weights=m[vo+48*idx[j]+12:vo+48*idx[j]+16]
   for k in range(inf):
    if weights[k]:assert props[j][k]<bn and bones[bc+props[j][k]]<boneN
 for v in batches:
  f=U('<Bb11H',v);n=f[8]
  assert f[3]<len(sec) and f[6]<len(mat)
  assert f[5]==65535 or f[5]<U('<I',m,72)[0]
  assert f[9]+n<=len(combo) and f[10]+n<=len(coord) and f[11]+n<=len(weight) and f[12]+n<=len(trans)
  for j in range(n):
   assert combo[f[9]+j]<len(tx) and coord[f[10]+j] in (0,1,65535)
   assert weight[f[11]+j]<len(tracks)
   assert trans[f[12]+j]==65535 or trans[f[12]+j]<U('<I',m,96)[0]
 # New opaque track must contain a real global key, not empty/default zero.
 track=tracks[-1];interpolation,loop,nt,ot,nk,ok=U('<HH4I',track)
 assert nt==nk==1 and loop<U('<I',m,20)[0]
 assert U('<I',m,U('<I',m,24)[0]+4*loop)[0]>0
 tn,to=U('<2I',m,ot);kn,ko=U('<2I',m,ok)
 assert tn==kn==1 and U('<I',m,to)[0]==0 and U('<h',m,ko)[0]==32767
 return {'vertices':nv,'skin_vertices':len(idx),'indices':len(tri),'sections':len(sec),'batches':len(batches)}
for sex in ('Male','Female'):
 g=geometry[sex];stem=g['stem'];m=(W/'after/Patch-YJ'/(stem+'.m2')).read_bytes();old=(W/'orig_true/Patch-YJ'/(stem+'.m2')).read_bytes()
 before=arr(old,60,48);after=arr(m,60,48)
 assert after[:len(before)]==before,'original vertex/UV/weight changed'
 assert arr(m,44,88)==arr(old,44,88),'bones changed'
 assert arr(m,240,40)==arr(old,240,40) and arr(m,248,2)==arr(old,248,2),'accepted sockets changed'
 assert arr(m,28,64)==arr(old,28,64),'animation sequences changed'
 # Cloak columns must remain symmetric and share weights within each row.
 first,count=g['cape_vertices'];cape=after[first:first+count]
 for row in range(11):
  vr=cape[row*9:(row+1)*9]
  assert len({v[12:20] for v in vr})==1
  for col in range(9):
   a=U('<3f',vr[col]);b=U('<3f',vr[8-col]);assert abs(a[0]-b[0])<1e-6 and abs(a[1]+b[1])<1e-6 and abs(a[2]-b[2])<1e-6
 texturetypes=[U('<I',x)[0] for x in arr(m,80,16)];assert texturetypes.count(1)==texturetypes.count(2)==1
 assert U('<2H',arr(m,112,4)[g['cape_material']])==(4,1),'cloak alpha cutout must stay enabled'
 for ni,(oi,reg) in g['overlay_duplicate_sources'].items():
  assert after[int(ni)][:40]==before[oi][:40],'duplicate changed positions/normals/weights/UV1'
 lods=[]
 for lod in range(len(g['lods'])):
  s=(W/'after/Patch-YJ'/(stem+f'{lod:02}.skin')).read_bytes();s0=(W/'orig_true/Patch-YJ'/(stem+f'{lod:02}.skin')).read_bytes()
  for h,size in ((4,2),(12,2),(20,4),(28,48),(36,24)):
   a=arr(s0,h,size);assert arr(s,h,size)[:len(a)]==a,'original skin arrays changed'
  lods.append(valid_resources(m,s))
  ids=[U('<H',v)[0] for v in arr(s,28,48)]
  assert all(gid in ids for gid in [*range(22001,22009),*range(1501,1511),*range(1301,1311)])
  for section in arr(s,28,48):
   gid,hi,vs,vc,ts,tc=U('<6H',section);ts|=hi<<16
   if 22001<=gid<=22008:
    iv=val16(s,4);it=val16(s,12);vo=U('<I',m,64)[0]
    assert max(U('<f',m,vo+48*iv[i]+8)[0] for i in it[ts:ts+tc])<(1.98 if sex=='Female' else 2.12)
 # Negative fixture: a poison texture-weight combo must be rejected before rendering.
 corrupt=bytearray(m);_,wo=U('<2I',m,144);P('<H',corrupt,wo+2*(len(val16(m,144))-1),65535)
 try:valid_resources(corrupt,s)
 except AssertionError:pass
 else:raise AssertionError('poisoned opacity combo accepted')
 report[sex]={'lods':lods,'original_geometry_animation_sockets_preserved':True,'opacity_poison_rejected':True,'head_excluded':True}
textureCount=0
for p in (W/'after/Patch-YJ/Reborn').rglob('*.blp'):
 b=p.read_bytes();assert b[:4]==b'BLP2' and b[8:12]==bytes((1,8,0,1))
 width,height=U('<2I',b,12);off=U('<16I',b,20);size=U('<16I',b,84)
 assert width<=512 and height<=512
 for o,n in zip(off,size):
  if n:assert o>=1172 and o+n<=len(b)
 im=Image.open(BytesIO(b)).convert('RGBA');assert im.size==(width,height) and im.getchannel('A').getextrema()==(255,255)
 textureCount+=1
assert textureCount==130
native={key.replace('\\','/') for palettes in json.loads((W/'palettes.json').read_text()).values() for palette in palettes for key in palette['refs'].values()}
for name in ('CharSections.dbc','CharSections.dbc1-race14'):
 a=(W/'orig_true/Patch-YB/DBFilesClient'/name).read_bytes();b=(W/'after/Patch-YB/DBFilesClient'/name).read_bytes()
 def records(blob):
  n,nc,stride,sl=U('<4I',blob,4);return [blob[20+i*stride:20+(i+1)*stride] for i in range(n)],blob[20+n*stride:]
 old,os=records(a);new,ns=records(b);assert len(old)==len(new) and ns.startswith(os)
 assert [r for r in new if U('<I',r,4)[0]!=84]==[r for r in old if U('<I',r,4)[0]!=84]
 for r in new:
  if U('<I',r,4)[0]!=84 or U('<I',r,12)[0] not in (0,1,4):continue
  for i in (4,5):
   offset=U('<I',r,4*i)[0]
   if offset:
    key=ns[offset:].split(b'\0')[0].decode().replace('\\','/')
    assert (W/'after/Patch-YJ'/key).exists() or key in native,key
report['textures']={'opaque_palette_BLPs_checked':textureCount}
report['shared_tables']={'non84_records_preserved':True,'row_ids_and_counts_unchanged':True,'client_creature_tables':'not included','server_tables':'not included'}
src=Path('helmet-work/src/WoW/Common/ComponentCore/EsteriaAppearance.cpp').read_text('utf8')
oldsrc=(W/'EsteriaAppearance.before-bodygear.cpp').read_text('utf8')
for start,end in [('static void FitSurekiFemaleEquipment(', '// STORMFORGEDBODY1A'),('static void FitMoguEquipment(','static void FitFurbolgRunedSoulblade(')]:
 # The Sureki block used to end immediately before FitStormforgedEquipment.
 a=src.index(start);b=src.index(end,a)
 if 'Sureki' in start:
  oa=oldsrc.index(start);ob=oldsrc.index('static void FitStormforgedEquipment(',oa)
  assert src[a:b]==oldsrc[oa:ob]
 else:
  oa=oldsrc.index(start);ob=oldsrc.index(end,oa);assert src[a:b]==oldsrc[oa:ob]
assert 'if (female) child->SetAttachmentFrame(18u, C3Vector(0.065f, 0.0f, 2.272f), 0.785f);' in src
report['accepted_female_helmet']='1F frame preserved exactly'
(W/'checks/geometry-validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
