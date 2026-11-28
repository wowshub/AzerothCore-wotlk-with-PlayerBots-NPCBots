# -*- coding: utf-8 -*-
from probe import *
from zipfile import ZipFile,ZIP_DEFLATED
from PIL import Image
from io import BytesIO
from tempfile import TemporaryDirectory
import ctypes as ct

p=w.parent/'codexfix_20261126_WOW64MOGU1J_女魔古绿模格式修复'
arc=c/'Data/Patch-YJ.mpq'
prefix='Creature/MoguFemale/RebornFaceAtlas/'
original=read(arc,'Creature/MoguFemale/mogufemale_sunbody.blp')
assert original[8:12]==bytes((1,8,8,1))
source=next(w.parent.glob('*WOW64MOGU1I*.zip'))
files={};log=[]
with ZipFile(source) as z:
 for i in range(12):
  key=prefix+f'skin{i:02d}.blp'
  old=read(arc,key)
  assert old==z.read('01_导入现有Patch-YJ.mpq/'+key)
  assert old[8:12]==bytes((1,8,0,1))
  new=bytearray(old);new[10]=8;new=bytes(new)
  assert new[:10]==old[:10] and new[11:]==old[11:]
  before=Image.open(BytesIO(old)).convert('RGBA')
  after=Image.open(BytesIO(new)).convert('RGBA')
  assert after.tobytes()==before.tobytes()
  assert new[8:12]==original[8:12]
  width,height=u('<II',new,12)
  offsets=u('<16I',new,20);lengths=u('<16I',new,84)
  for level,(offset,length) in enumerate(zip(offsets,lengths)):
   if offset:
    x,y=max(1,width>>level),max(1,height>>level)
    assert length==x*y*2 and offset+length<=len(new)
    assert offset>=1172
  for folder,data in [('01_导入现有Patch-YJ.mpq',new),('backup_1I/'+ 'Patch-YJ.mpq',old)]:
   f=p/folder/key;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(data)
  files[key]=new
  log.append(f'{key} {sha256(old).hexdigest()} -> {sha256(new).hexdigest()}; byte 10 only; all pixels/mips retained')
d,H,U,check=(mpq[n] for n in ('d','H','U','require'))
d.SFileCreateArchive.argtypes=[ct.c_wchar_p,U,U,ct.POINTER(H)];d.SFileCreateArchive.restype=ct.c_bool
with TemporaryDirectory(dir=w) as td:
 test=Path(td)/'Patch-YJ.mpq';h=H();check(d.SFileCreateArchive(str(test),0x00100000,64,ct.byref(h)))
 try:
  for key in files:check(d.SFileAddFileEx(h,str(p/'01_导入现有Patch-YJ.mpq'/key),key.replace('/',chr(92)).encode(),0x80000200,2,2))
 finally:check(d.SFileCloseArchive(h))
 assert all(read(test,key)==data for key,data in files.items())
(p/'checks.txt').write_text('\n'.join(log)+'\nMPQ readback passed\n',encoding='utf8')
(p/'README.md').write_text('女魔古绿模格式修复 1J\n\n当前1I图集是调色板数据，头部preferredFormat错误写为0（DXT1）。引擎TextureGetTextureFormats把它作为压缩格式，调色板解码路径不能处理该格式，加载回退。此包将12张图集的该字段改为原版调色板的8。每张只有第10字节变化，像素、透明度和所有mip数据一致。\n\n退出游戏，把01内12张BLP按原路径导入现有Patch-YJ.mpq，保存关闭编辑器后启动游戏。当前1I模型与YB保持配套。检查NO/T7/T14脸部、小腿及全部肤色。\n\n已核对原生BLP头、当前引擎格式分支、全部像素/mip与隔离MPQ回读。真实画面仍待实测。backup保存的是有故障的1I图集，仅供核对。\n',encoding='utf8')
entries={f.relative_to(p).as_posix():f.read_bytes() for f in p.rglob('*') if f.is_file() and f.name!='SHA256SUMS.txt'}
manifest=''.join(f'{sha256(b).hexdigest()}  {n}\n' for n,b in sorted(entries.items())).encode();(p/'SHA256SUMS.txt').write_bytes(manifest);entries['SHA256SUMS.txt']=manifest
with ZipFile(p.with_suffix('.zip'),'w',ZIP_DEFLATED) as z:
 for name,b in entries.items():z.writestr(name,b)
with ZipFile(p.with_suffix('.zip')) as z:
 assert not z.testzip() and all(z.read(name)==b for name,b in entries.items())
print('PASS 12 header corrections',sha256(p.with_suffix('.zip').read_bytes()).hexdigest())
