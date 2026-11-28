import sys,json
from pathlib import Path
from struct import pack,pack_into as P
sys.path.insert(0,'stormforged-intake');sys.argv=['','C:/000ref/WarcraftXL\u8bd5\u88c5_client']
from probe import *
W=w/'bodygear1a';report={}
def modify(b,client):
 stride,rs,st=rows(b);pool=bytearray(st);new=[];existing={tuple(u('<3I',v,4))+tuple(u('<2I',v,32)) for v in rs};nextid=max(u('<I',v)[0] for v in rs)+1
 def string(value):
  o=len(pool);pool.extend(value.encode()+b'\0');return o
 for v in rs:
  if u('<I',v,4)[0]!=84:new.append(v);continue
  q=bytearray(v);gender,kind=u('<2I',v,8);color=u('<I',v,36)[0]
  prefix=f'Reborn\\StormforgedBody1A\\{"Female" if gender else "Male"}\\Skin{color:02}'
  if client and kind in (0,1,4):
   refs={0:[prefix+'.blp',None,None],1:[prefix+'_FL.blp',prefix+'_FU.blp',None],4:[prefix+'_LU.blp',prefix+'_TU.blp',None]}[kind]
   for j,ref in enumerate(refs):
    if ref:P('<I',q,16+4*j,string(ref))
  new.append(bytes(q))
 extra=[]
 for v in list(new):
  if u('<3I',v,4)[0:3] not in ((84,0,1),(84,1,1)) or u('<I',v,32)[0]!=0:continue
  for face in (1,2):
   key=(84,u('<I',v,8)[0],1,face,u('<I',v,36)[0])
   if key in existing:continue
   q=bytearray(v);P('<I',q,0,nextid);P('<I',q,32,face);nextid+=1;extra.append(bytes(q));existing.add(key)
 result=pack('<4s4I',b'WDBC',len(new)+len(extra),u('<I',b,8)[0],stride,len(pool))+b''.join(new+extra)+pool
 assert [v for v in rows(result)[1] if u('<I',v,4)[0]!=84]==[v for v in rs if u('<I',v,4)[0]!=84]
 assert rows(result)[2].startswith(st)
 return result,len(extra),sum(a!=b for a,b in zip(rs,new))
def put(rel,data,old):
 for stage,blob in [('after',data),('orig_true',old)]:
  p=W/stage/rel;p.parent.mkdir(parents=True,exist_ok=True)
  if stage=='orig_true' and p.exists():assert p.read_bytes()==blob
  else:p.write_bytes(blob)
for name in ('CharSections.dbc','CharSections.dbc1-race14'):
 key='DBFilesClient/'+name;b=read(c/'Data/Patch-YB.mpq',key)
 if b:
  modified,added,changed=modify(b,True);put('Patch-YB/'+key,modified,b);report[name]={'added':added,'updated_target_rows':changed,'old_non84_rows_unchanged':True}
server=r/'beascendserver/wowshub_playerbot_npcbot_newrace20261122Ascend/Data/dbc'
for lang in ('','zhCN/'):
 b=(server/lang/'CharSections.dbc').read_bytes();modified,added,changed=modify(b,False)
 assert changed==0
 if added:put('server/Data/dbc/'+lang+'CharSections.dbc',modified,b)
 report['server/'+lang+'CharSections']={'added_faces':added,'old_rows_unchanged':True}
(W/'dbc-report.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
