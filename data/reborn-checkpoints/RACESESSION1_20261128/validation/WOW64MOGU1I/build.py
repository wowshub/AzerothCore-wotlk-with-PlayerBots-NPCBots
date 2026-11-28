# -*- coding: utf-8 -*-
from probe import *
from struct import pack,pack_into
from zipfile import ZipFile,ZIP_DEFLATED
from io import BytesIO
from PIL import Image
import numpy as np
import ctypes as ct
from tempfile import TemporaryDirectory

p=w.parent/'codexfix_20261126_WOW64MOGU1I_女魔古脸与小腿贴图'
yb=c/'Data/Patch-YB.mpq'; yj=c/'Data/Patch-YJ.mpq'
outputs={}
def save(group,key,old,new):
 for folder,data in [('backup_原文件/'+group,old),('01_导入现有'+group,new)]:
  if data is None:continue
  f=p/folder/key; f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(data)
 outputs[group,key]=new
def entries(b,h,size):
 n,o=u('<II',b,h);return [b[o+i*size:o+(i+1)*size] for i in range(n)]
def emit(b,h,records):
 b.extend(bytes(-len(b)%16));pack_into('<II',b,h,len(records),len(b));b.extend(b''.join(records))
def pal_blp(im):
 im=im.convert('RGBA'); quant=im.convert('RGB').quantize(colors=256)
 palette=quant.getpalette(); palette=(palette+[0]*768)[:768]
 pal=b''.join(bytes((palette[i+2],palette[i+1],palette[i],255)) for i in range(0,768,3))
 chunks=[];size=im.size
 while True:
  q=im.convert('RGB').quantize(palette=quant)
  chunks.append(q.tobytes()+im.getchannel('A').tobytes())
  if im.size==(1,1):break
  im=im.resize((max(1,im.width//2),max(1,im.height//2)),Image.Resampling.LANCZOS)
 offsets=[];pos=1172
 for data in chunks:offsets.append(pos);pos+=len(data)
 fields=lambda x:pack('<16I',*(x+[0]*(16-len(x))))
 b=pack('<4sI4BII',b'BLP2',1,1,8,0,1,*size)+fields(offsets)+fields(list(map(len,chunks)))+pal+b''.join(chunks)
 decoded=Image.open(BytesIO(b)).convert('RGBA');assert decoded.size==size
 return b

key='DBFilesClient/CharSections.dbc'; original=read(yb,key);_,rr,strings=rows(original)
aux=read(yb,key+'1-race14');_,aa,ss=rows(aux)
val=lambda q:u('<10I',q)
ident=lambda a:(a[3],a[7],a[8],a[9])
ref={ident(val(q)):val(q) for q in aa if val(q)[1:3]==(123,1)}
st=bytearray(strings); cache={};assets={};newrows=[];fixed=0
def string(s,i):return s[i:].split(b'\0')[0]
def offset(s):
 if s not in cache:cache[s]=len(st);st.extend(s+b'\0')
 return cache[s]
for q in rr:
 a=val(q)
 if a[1:3]!=(123,1):newrows.append(q);continue
 b=bytearray(q)
 if a[3] in (1,4):
  donor=ref[ident(a)]
  for col in (4,5):
   name=string(ss,donor[col]);assert name.lower().startswith(b'reborn\\bake\\')
   data=read(yj,name.decode());assert data;Image.open(BytesIO(data)).load()
   pack_into('<I',b,col*4,offset(name))
  fixed+=1
 if a[3]==0:
  body=string(strings,a[4]);armor=string(strings,a[5]);pair=body,armor
  if pair not in assets:
   im1=Image.open(BytesIO(read(yj,body.decode()))).convert('RGBA')
   im2=Image.open(BytesIO(read(yj,armor.decode()))).convert('RGBA')
   width=max(im1.width,im2.width);height=max(im1.height,im2.height)
   atlas=Image.new('RGBA',(width*2,height))
   atlas.paste(im1.resize((width,height)),(0,0));atlas.paste(im2.resize((width,height)),(width,0))
   path=f'Creature/MoguFemale/RebornFaceAtlas/skin{len(assets):02d}.blp'
   assets[pair]=path
   save('Patch-YJ.mpq',path,None,pal_blp(atlas))
  pack_into('<I',b,20,offset(assets[pair].replace('/',chr(92)).encode()))
 newrows.append(bytes(b))
assert fixed>0 and len(assets)==12
sig,n,cols,stride,_=u('<4s4I',original)
data=pack('<4s4I',sig,n,cols,stride,len(st))+b''.join(newrows)+st
assert all(x==y for x,y in zip(rr,newrows) if val(x)[1:3]!=(123,1))
save('Patch-YB.mpq',key,original,data)

stem='Creature/MoguFemale/MoguPlayerFemale'
with ZipFile(next(w.parent.glob('*WOW64MOGU1F*.zip'))) as source:
 base=source.read('01_导入现有Patch-YJ.mpq/'+stem+'.m2');model=bytearray(base)
 vertices=entries(base,60,48); lookup_tex=[u('<H',q)[0] for q in entries(base,128,2)]
 types=[u('<I',q)[0] for q in entries(base,80,16)]
 direct=next(i for i,index in enumerate(lookup_tex) if types[index]==8)
 duplicated={};face_total=0
 for lod in range(3):
  path=f'{stem}{lod:02d}.skin';b=source.read('01_导入现有Patch-YJ.mpq/'+path);s=bytearray(b)
  lut=entries(b,4,2);tri=entries(b,12,2);weights=entries(b,20,4);sections=entries(b,28,48);batches=entries(b,36,24)
  for batch_id,batch in enumerate(list(batches)):
   combo=u('<H',batch,16)[0];kind=types[lookup_tex[combo]]
   if kind not in (8,11):continue
   sec_id=u('<H',batch,4)[0];sec=bytearray(sections[sec_id]);gid,start,count,first,number=u('<I4H',sec)
   mapping={};begin=len(lut)
   for index in range(start,start+count):
    vertex=u('<H',lut[index])[0];tag=(vertex,kind)
    if tag not in duplicated:
     v=bytearray(vertices[vertex]);uv=u('<2f',v,32)
     # Left half is the clean skin. Right half is the original decorative armor.
     pack_into('<2f',v,32,uv[0]*.5+(0.5 if kind==8 else 0),uv[1])
     duplicated[tag]=len(vertices);vertices.append(bytes(v))
    mapping[index]=len(lut);lut.append(pack('<H',duplicated[tag]));weights.append(weights[index])
   newfirst=len(tri)
   tri.extend(pack('<H',mapping[u('<H',index)[0]]) for index in tri[first:first+number])
   pack_into('<4H',sec,4,begin,count,newfirst,number)
   new_sec=len(sections);sections.append(bytes(sec));newbatch=bytearray(batch)
   pack_into('<HH',newbatch,4,new_sec,new_sec);pack_into('<H',newbatch,16,direct);batches[batch_id]=bytes(newbatch)
   if kind==11:face_total+=number//3
  for h,v in ((4,lut),(12,tri),(20,weights),(28,sections),(36,batches)):emit(s,h,v)
  assert len(lut)<65536 and max(u('<H',x)[0] for x in tri)<len(lut)
  assert all(types[lookup_tex[u('<H',q,16)[0]]]!=11 for q in batches)
  save('Patch-YJ.mpq',path,read(yj,path),bytes(s))
 assert face_total==5220
 emit(model,60,vertices)
 assert entries(model,60,48)[:len(entries(base,60,48))]==entries(base,60,48)
 save('Patch-YJ.mpq',stem+'.m2',read(yj,stem+'.m2'),bytes(model))

d,H,U,check=(mpq[n] for n in ('d','H','U','require'))
d.SFileCreateArchive.argtypes=[ct.c_wchar_p,U,U,ct.POINTER(H)];d.SFileCreateArchive.restype=ct.c_bool
with TemporaryDirectory(dir=w) as td:
 for group in ('Patch-YJ.mpq','Patch-YB.mpq'):
  archive=Path(td)/group;h=H();check(d.SFileCreateArchive(str(archive),0x00100000,128,ct.byref(h)))
  try:
   for (g,key),data in outputs.items():
    if g==group:check(d.SFileAddFileEx(h,str(p/('01_导入现有'+group)/key),key.replace('/',chr(92)).encode(),0x80000200,2,2))
  finally:check(d.SFileCloseArchive(h))
  for (g,key),data in outputs.items():
   if g==group:assert read(archive,key)==data
(p/'README.md').write_text(f'女魔古脸部与小腿贴图修复\n\n退出游戏，将两个01目录里的文件按路径分别导入现有Patch-YB和Patch-YJ。沿用当前客户端程序。恢复女魔古脸部/内衣的{fixed}条烘焙记录，防止小腿出现默认人脸。12个肤色图集由原肤色和原装饰图合成，脸单独走原生type8直贴，身体保留衣甲合成。保留1F披风网格。\n\n检查NO/T7/T14、所有肤色、男女切换和进游戏。已通过贴图解码、原顶点保留、三套LOD与隔离MPQ回读。实际画面和面部边界仍待实测。回退时需先核对备份对应的版本，新增图集在回退模型和DBC后成为无引用条目。\n',encoding='utf8')
files={f.relative_to(p).as_posix():f.read_bytes() for f in p.rglob('*') if f.is_file() and f.name!='SHA256SUMS.txt'}
manifest=''.join(f'{sha256(b).hexdigest()}  {n}\n' for n,b in sorted(files.items())).encode();(p/'SHA256SUMS.txt').write_bytes(manifest);files['SHA256SUMS.txt']=manifest
with ZipFile(p.with_suffix('.zip'),'w',ZIP_DEFLATED) as z:
 for name,b in files.items():z.writestr(name,b)
print('PASS',fixed,len(assets),face_total,sha256(p.with_suffix('.zip').read_bytes()).hexdigest())
