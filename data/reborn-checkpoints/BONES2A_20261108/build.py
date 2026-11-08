# -*- coding: utf-8 -*-
from pathlib import Path
import json,hashlib,struct,mpyq,datetime,io
from PIL import Image
W=Path(__file__).resolve().parent;D=W.parent;R=W.parents[2];C=R/'beascendclient/newrebornWOWli20261107beAscend'
stamp=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-8))).strftime('%Y%m%d_%H%M%S')
assert stamp.startswith('20261108'), 'Recheck actual user date before packaging'
P=D/('codexfix_'+stamp+'_阶段BONES2A_四新族复活遗骨方块修复候选');assert not P.exists();P.mkdir();(W/'package_path.txt').write_text(str(P),encoding='utf8')
audit=json.loads((W/'audit.json').read_text(encoding='utf8'));sha=lambda b:hashlib.sha256(b).hexdigest()
root='World/Generic/PassiveDoodads/DeathSkeletons/';manifest=[];models=[];outputs={}
ar={};orders=sorted([Path(a['archive']) for a in audit['archives'] if a['tag']=='current'],key=lambda p:(p.parent==C/'Data',p.name.lower()),reverse=True)
def archive(p):
 if p not in ar:
  a=mpyq.MPQArchive(str(p),listfile=False)
  index={}
  for e in a.hash_table:index.setdefault((e.hash_a,e.hash_b),e)
  a.get_hash_table_entry=lambda name,a=a,index=index:index.get((a._hash(name,'HASH_A'),a._hash(name,'HASH_B')))
  ar[p]=a
 return ar[p]
def readcurrent(n,prefer=None):
 paths=([prefer] if prefer else [])+[p for p in orders if p!=prefer]
 for p in paths:
  a=archive(p);key=n.replace('/','\\')
  if a.get_hash_table_entry(key):return a.read_file(key),str(p)
 raise AssertionError('Missing donor dependency '+n)
def emit(n,b,**meta):
 if n in outputs:assert outputs[n]==b;return
 outputs[n]=b;f=P/'01_导入Patch-YJ.mpq'/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b)
 manifest.append(dict(path='01_导入Patch-YJ.mpq/'+n,input=None,output=sha(b),bytes=len(b),**meta))
byid={r['id']:r for r in audit['races']}
for race,donor in [(36,'Human'),(37,'Orc'),(39,'Human'),(49,'Orc')]:
 r=byid[race];assert not r['Male'] and not r['Female']
 for sex in ['Male','Female']:
  source=root+donor+sex+'DeathSkeleton.m2';target=root+r['prefix']+sex+'DeathSkeleton.m2'
  native=next(h for h in audit['hits'] if h['tag']=='current' and Path(h['archive']).name=='Patch-T.mpq' and h['path'].lower()==source.lower())
  b=Path(native['file']).read_bytes();assert sha(b)==native['sha256'];m=bytearray(b);assert b[:4]==b'MD20' and struct.unpack_from('<I',b,4)[0]==264
  views=struct.unpack_from('<I',b,68)[0];assert 1<=views<=4
  details=dict(race=race,prefix=r['prefix'],sex=sex,donor=donor,compatibility=True,source=source,source_archive=native['archive'],source_sha256=sha(b),target=target,skins=[],textures=[],external_animations=[],changed_ranges=[])
  for i in range(views):
   sn=source[:-3]+'%02d.skin'%i;sb,sp=readcurrent(sn,Path(native['archive']));tn=target[:-3]+'%02d.skin'%i
   emit(tn,sb,source=sn,source_archive=sp);details['skins'].append(dict(path=tn,source=sn,archive=sp,sha256=sha(sb)))
  nt,ot=struct.unpack_from('<II',b,80)
  for i in range(nt):
   ty,flags,n,o=struct.unpack_from('<4I',b,ot+16*i);assert ty==0 and 0<n<1024 and o+n<=len(b)
   oldpath=b[o:o+n].split(b'\0')[0].decode('ascii').replace('\\','/');tb,tp=readcurrent(oldpath,Path(native['archive']))
   im=Image.open(io.BytesIO(tb));im.load();dest=root+'BONES2A/'+sha(tb)[:24]+'.blp';data=dest.replace('/','\\').encode()+b'\0'
   no=len(m);m.extend(data);struct.pack_into('<II',m,ot+16*i+8,len(data),no)
   details['changed_ranges'].append([ot+16*i+8,ot+16*i+16]);emit(dest,tb,source=oldpath,source_archive=tp)
   details['textures'].append(dict(path=dest,source=oldpath,archive=tp,sha256=sha(tb),dimensions=list(im.size)))
  na,oa=struct.unpack_from('<II',b,28)
  for i in range(na):
   ident,variation=struct.unpack_from('<HH',b,oa+64*i);flags=struct.unpack_from('<I',b,oa+64*i+12)[0]
   if not flags&0x20:
    an=source[:-3]+'%04d-%02d.anim'%(ident,variation);ab,ap=readcurrent(an,Path(native['archive']));dest=target[:-3]+'%04d-%02d.anim'%(ident,variation)
    emit(dest,ab,source=an,source_archive=ap);details['external_animations'].append(dict(path=dest,source=an,archive=ap,sha256=sha(ab)))
  # No geometry, bones, tracks, skin, materials, flags or lookups are rewritten.
  allowed={j for a,z in details['changed_ranges'] for j in range(a,z)}
  assert all(b[i]==m[i] for i in range(len(b)) if i not in allowed)
  emit(target,bytes(m),source=source,source_archive=native['archive']);details['output_sha256']=sha(m);models.append(details)
# Check every added internal path directly in each readable current archive.
# Locked Patch-9/Housing remain explicitly unaudited; no editor or live file is touched.
for p in orders:
 a=archive(p)
 for n in outputs:
  assert not a.get_hash_table_entry(n.replace('/','\\')),('existing target; stop additive build',str(p),n)
for n in outputs:assert not (C/n).exists()
for a in ar.values():a.file.close()
(P/'checks').mkdir();(P/'checks/model_dependency_manifest.json').write_text(json.dumps(models,ensure_ascii=False,indent=2),encoding='utf8');(P/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps(dict(package=str(P),payload_files=len(outputs),models=len(models),textures=len([n for n in outputs if n.lower().endswith('.blp')]),skins=len([n for n in outputs if n.lower().endswith('.skin')]),external_animations=sum(len(m['external_animations']) for m in models),all_target_paths_absent_in_readable_archives=len(orders)),ensure_ascii=False))
