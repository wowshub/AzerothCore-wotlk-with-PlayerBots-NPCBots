from pathlib import Path
import json,struct,hashlib,re
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());C=R/'beascendclient/newrebornWOWli20260929beAscend';S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend/Data/dbc'
archives={};failed={};rows={};pools={};payload={};report={'tables':{},'assets':{},'notes':['Existing Loa Brew healing visual reused; no new cauldron model or bottle projectile claimed. Archive asset candidates are inventoried, not treated as proven mount precedence.']}
for f in (C/'Data').rglob('*'):
 if f.suffix.lower()!='.mpq':continue
 try:archives[f]=Archive(f)
 except AssertionError as e:failed[str(f)]=str(e)
xa=next((a for f,a in archives.items() if f.name.lower()=='patch-xa.mpq'),None)
def table(n):
 if n in rows:return rows[n]
 data=xa.read('DBFilesClient\\'+n+'.dbc') if xa else None
 origin='current Patch-XA override'
 if not data:data=(S/(n+'.dbc')).read_bytes();origin='server reference only'
 rows[n],pools[n]=dbc(data);report['tables'][n]={'source':origin,'sha256':hashlib.sha256(data).hexdigest()};return rows[n]
def asset(path):
 key=path.replace('/','\\');entry=report['assets'].get(key)
 if entry:return payload.get(key)
 matches=[];data=None
 for f,a in archives.items():
  raw=a.read(key)
  if raw is not None:
   matches.append({'archive':str(f),'sha256':hashlib.sha256(raw).hexdigest()});data=raw
 report['assets'][key]={'candidates':matches,'exists':bool(matches)}
 assert data is not None,key
 payload[key]=data
 return data
def model(path):
 path=re.sub(r'\.mdx$','.m2',path,flags=re.I);data=asset(path)
 assert data[:4]==b'MD20',path
 count,off=struct.unpack_from('<2I',data,80)
 for i in range(count):
  typ,flags,length,pos=struct.unpack_from('<4I',data,off+i*16)
  if typ==0 and length:asset(data[pos:pos+length].split(b'\0')[0].decode())
 for i in range(struct.unpack_from('<I',data,68)[0]):asset(path[:-3]+str(i).zfill(2)+'.skin')
 count,off=struct.unpack_from('<2I',data,28)
 for i in range(count):
  aid,sub=struct.unpack_from('<2H',data,off+i*64);flags=struct.unpack_from('<I',data,off+i*64+12)[0]
  if not flags&0x20 and not flags&0x40:asset(path[:-3]+str(aid).zfill(4)+'-'+str(sub).zfill(2)+'.anim')
seen=set()
def follow(n,i):
 if i in [0,0xffffffff] or (n,i) in seen:return
 seen.add((n,i));r=table(n)[i]
 if n=='SpellVisual':
  for k in [1,2,3,4,5,6,14,15,23,24,25]:follow('SpellVisualKit',r[k])
  follow('SpellVisualEffectName',r[8]);follow('SoundEntries',r[11]);follow('SoundEntries',r[12]);follow('SpellMissile',r[21])
 elif n=='SpellVisualKit':
  for k in range(3,15):follow('SpellVisualEffectName',r[k])
  follow('SoundEntries',r[15])
  for ar in table('SpellVisualKitModelAttach').values():
   if ar[1]==i:follow('SpellVisualEffectName',ar[2])
 elif n=='SpellVisualEffectName':
  pool=pools[n];off=r[2];path=pool[off:pool.find(b'\0',off)].decode()
  if path:model(path)
 elif n=='SoundEntries':
  pool=pools[n]
  def text(off):return pool[off:pool.find(b'\0',off)].decode()
  for k in range(3,13):
   if text(r[k]):asset(text(r[23])+'\\'+text(r[k]))
try:
 for i in [887925]:follow('SpellVisual',i)
 report['status']='all referenced native assets found';report['records']=[list(x) for x in sorted(seen)]
except Exception as e:report['status']='limited: '+repr(e)
finally:
 for a in archives.values():a.close()
report['unreadable_archives']=failed
(P/'checks/native_visual_closure.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8');print(report['status'],len(report['assets']),'assets')
