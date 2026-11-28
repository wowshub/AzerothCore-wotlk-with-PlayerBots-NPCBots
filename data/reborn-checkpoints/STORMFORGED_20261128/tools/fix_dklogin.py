import sys,json
from struct import pack,pack_into
sys.path.insert(0,'stormforged-intake');sys.argv=['','C:/000ref/WarcraftXL\u8bd5\u88c5_client']
from probe import *
server=r/'beascendserver/wowshub_playerbot_npcbot_newrace20261122Ascend'
dbc=server/'Data/dbc';out=w/'dklogin1a';report={}
def put(path,data):
 f=out/path;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(data)
for name,ids,stringcols in [('CreatureDisplayInfo',{977660,977661},(6,7,8,9)),('CreatureModelData',{901408,901409},(2,))]:
 original=(dbc/(name+'.dbc')).read_bytes();donor=(dbc/'zhCN'/(name+'.dbc')).read_bytes()
 stride,old,strings=rows(original);dstride,rr,ds=rows(donor);assert stride==dstride
 seen={u('<I',v)[0] for v in old};pool=bytearray(strings);extra=[]
 for id in sorted(ids):
  if id in seen:continue
  rowdata=bytearray(next(v for v in rr if u('<I',v)[0]==id))
  for col in stringcols:
   offset=u('<I',rowdata,4*col)[0]
   if not offset:continue
   value=ds[offset:].split(b'\0')[0]+b'\0'
   pack_into('<I',rowdata,4*col,len(pool));pool.extend(value)
  extra.append(bytes(rowdata))
 assert len(extra)==2,(name,'unexpected live baseline change',len(extra))
 result=pack('<4s4I',b'WDBC',len(old)+len(extra),u('<I',original,8)[0],stride,len(pool))+b''.join(old+extra)+pool
 assert rows(result)[1][:len(old)]==old and rows(result)[2].startswith(strings)
 put('before/Data/dbc/'+name+'.dbc',original);put('after/Data/dbc/'+name+'.dbc',result)
 report[name]={'added':len(extra),'ids':sorted(ids),'old_records_preserved':len(old),'input_sha256':sha256(original).hexdigest(),'output_sha256':sha256(result).hexdigest()}
# Validate each race/sex against each actual server baseline, including every
# installed preexisting race, plus model filenames and the client's display chain.
for lang in ('','zhCN'):
 def table(name):
  f=out/'after/Data/dbc'/(name+'.dbc')
  return f.read_bytes() if not lang and f.is_file() else (dbc/lang/(name+'.dbc')).read_bytes()
 displays={u('<I',v)[0]:u('<I',v,4)[0] for v in rows(table('CreatureDisplayInfo'))[1]}
 models={u('<I',v)[0]:v for v in rows(table('CreatureModelData'))[1]}
 tested=0
 for v in rows(table('ChrRaces'))[1]:
  for id in u('<2I',v,16):
   if not id:continue
   assert id in displays and displays[id] in models,(lang,u('<I',v)[0],id)
   tested+=1
 report[lang or 'root']={'race_gender_links_checked':tested,'missing_links':0}
clientDisplay=read(c/'Data/Patch-YB.mpq','DBFilesClient/CreatureDisplayInfo.dbc')
clientModel=read(c/'Data/Patch-YB.mpq','DBFilesClient/CreatureModelData.dbc')
for id,mid in ((977660,901408),(977661,901409)):
 dr,_=row(clientDisplay,id);assert u('<I',dr,4)[0]==mid
 mr,ms=row(clientModel,mid);path=ms[u('<I',mr,8)[0]:].split(b'\0')[0].decode().replace('.mdx','.m2')
 assert read(c/'Data/Patch-YJ.mpq',path)
report['client_display_chain']='both existing and model M2 files readable'
report['root_before_missing_native_display_ids']=[977660,977661]
report['game_DK_login']='not tested after installation'
put('checks/verification.json',json.dumps(report,ensure_ascii=False,indent=2).encode())
print(json.dumps(report))
