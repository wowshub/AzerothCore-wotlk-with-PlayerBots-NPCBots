# -*- coding: utf-8 -*-
from pathlib import Path
import struct,json,hashlib,mpyq
W=Path(__file__).resolve().parent;R=W.parents[2];C=R/'beascendclient/newrebornWOWli20261107beAscend'
sha=lambda b:hashlib.sha256(b).hexdigest()
root='World/Generic/PassiveDoodads/DeathSkeletons/'
base=mpyq.MPQArchive(str(C/'Data/Patch-YB.mpq'),listfile=False).read_file('DBFilesClient\\ChrRaces.dbc')
magic,n,nf,rs,ns=struct.unpack_from('<4s4I',base);assert magic==b'WDBC'
strings=base[20+n*rs:];races=[]
for i in range(n):
 row=struct.unpack_from('<'+'I'*nf,base,20+i*rs)
 prefix=strings[row[11]:].split(b'\0')[0].decode('utf8');races.append(dict(id=row[0],prefix=prefix,male=row[4],female=row[5]))
targets={root+r['prefix']+sex+'DeathSkeleton'+ext for r in races for sex in ['Male','Female'] for ext in ['.m2','.mdx','00.skin']}
expected={root+r['prefix']+sex+'DeathSkeleton.m2' for r in races if r['id'] in [36,37,39,49] for sex in ['Male','Female']}
sources=[('current',C/'Data'),('coa192',Path('D:/game/ascend/coa新种族/coa新种族1.9.2')),('coa_official',Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data'))]
hits=[];errors=[];archives=[]
for tag,folder in sources:
 paths=sorted({p for p in folder.rglob('*') if p.suffix.lower()=='.mpq' and (tag!='current' or p.parent in [C/'Data',C/'Data/enUS',C/'Data/zhCN'])})
 for p in paths:
  try:a=mpyq.MPQArchive(str(p),listfile=False)
  except Exception as e:errors.append(dict(tag=tag,archive=str(p),error=str(e)));continue
  archives.append(dict(tag=tag,archive=str(p),bytes=p.stat().st_size))
  try:listed=(a.read_file('(listfile)') or b'').decode('utf8',errors='replace').splitlines()
  except Exception as e:listed=[];errors.append(dict(tag=tag,archive=str(p),listfile_error=str(e)))
  names={x.strip().replace('\\','/') for x in listed if 'deathskeleton' in x.lower() and x.lower().endswith(('.m2','.mdx','.skin','.blp'))}
  names.update(targets)
  # Original CoA prefixes may differ from the project REBORN* tokens.
  for prefix in ['Human','Orc','Ogre','Sethrak','KulTiran','Maghar','MagharOrc','KulTiranHuman']:
   for sex in ['Male','Female']:
    for ext in ['.m2','.mdx','00.skin']:names.add(root+prefix+sex+'DeathSkeleton'+ext)
  for name in sorted(names):
   key=name.replace('/','\\')
   if not a.get_hash_table_entry(key):continue
   try:b=a.read_file(key)
   except Exception as e:errors.append(dict(tag=tag,archive=str(p),path=name,error=str(e)));continue
   if not b:continue
   dest=W/'reference'/tag/(p.parent.name+'_'+p.name)/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(b)
   hits.append(dict(tag=tag,archive=str(p),path=name,sha256=sha(b),size=len(b),file=str(dest)))
  a.file.close()
matrix=[]
for r in races:
 if not r['prefix']:continue
 row=dict(r)
 for sex in ['Male','Female']:
  name=(root+r['prefix']+sex+'DeathSkeleton.m2').lower()
  row[sex]=[h for h in hits if h['tag']=='current' and h['path'].lower()==name]
 matrix.append(row)
e=(C/'Wow.exe').read_bytes();template=b'World\\Generic\\PassiveDoodads\\DeathSkeletons\\%s%sDeathSkeleton.mdx'
report=dict(chr_races_sha256=sha(base),exe_sha256=sha(e),exe_template_offset=e.find(template),races=matrix,archives=archives,unreadable=errors,hits=hits,target_paths=sorted(expected))
(W/'audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8');(W/'ChrRaces_input.dbc').write_bytes(base)
print(json.dumps(dict(current_four=[dict(id=r['id'],prefix=r['prefix'],male_found=len(r['Male']),female_found=len(r['Female'])) for r in matrix if r['id'] in [36,37,39,49]],archives=len(archives),unreadable=errors,donor_model_paths=sorted({h['path'] for h in hits if h['tag']!='current' and h['path'].lower().endswith(('.m2','.mdx'))})),ensure_ascii=False,indent=2))
