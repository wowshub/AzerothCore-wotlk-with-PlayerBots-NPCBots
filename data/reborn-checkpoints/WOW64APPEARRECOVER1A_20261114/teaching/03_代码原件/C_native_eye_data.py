exec((__import__('pathlib').Path(__file__).parent/'inspect_inputs.py').read_text('utf8').split("for n in ['Patch-YB.mpq'")[0])
from PIL import Image
import io
m=R(str(c/'Data/Patch-YI.mpq'));ls=m.read_file('(listfile)').decode('utf8','replace').splitlines();print('\n'.join(x for x in ls if 'mechagnome' in x.lower() and 'eye' in x.lower())[:6000])
for race in ['mechagnome','earthen']:
 for sex in ['male','female']:
  for k in [1,2,3]:
   p='custom\\%s\\native\\%s\\eyes0_%d.blp'%(race,sex,k)
   try:b=m.read_file(p)
   except Exception:continue
   if not b:continue
   wi,he=struct.unpack_from('<II',b,12);print(p,wi,he,b[8]);off=struct.unpack_from('<I',b,20)[0];im=Image.frombytes('RGBA',(wi,he),b[off:off+wi*he*4],'raw','BGRA') if b[8]==3 else Image.open(io.BytesIO(b));im.save(w/(race+'-'+sex+str(k)+'.png'))
m.close()
y=R(str(c/'Data/Patch-YB.mpq'));b=y.read_file('DBFilesClient\\CharSections.dbc');_,n,nf,rs,ss=struct.unpack_from('<4s4I',b);st=b[20+n*rs:];rows=[struct.unpack_from('<10I',b,20+i*rs) for i in range(n)];s=lambda x:st[x:].split(b'\0')[0].decode()
for race in [67,68]:
 for sex in [0,1]:
  for section in [0,1,2,3,4]:
   q=[x for x in rows if x[1:4]==(race,sex,section)];print(race,sex,section,'count',len(q), [(x[8:],[s(a) for a in x[4:7]]) for x in q[:1]])
y.close()
