import sys,json,math
from pathlib import Path
from struct import unpack_from as U,pack
from io import BytesIO
import numpy as np
from PIL import Image
sys.path.insert(0,'stormforged-intake');sys.argv=['','C:/000ref/WarcraftXL\u8bd5\u88c5_client']
from probe import read,c
W=Path('stormforged-intake/bodygear1a');OUT=W/'after/Patch-YJ';S=512
triangles=json.loads((W/'bake-triangles.json').read_text());catalog=(W/'orig_true/client-root/EsteriaRebornStormforged84.bin').read_bytes()
records=[catalog[12+i*156:12+(i+1)*156] for i in range(U('<I',catalog,8)[0])]
def blp(image):
 image=image.convert('RGB');w,h=image.size;q=image.quantize(colors=256,method=Image.Quantize.MEDIANCUT)
 palette=q.getpalette();palette+=[0]*(768-len(palette));pal=bytes(v for i in range(256) for v in (palette[i*3+2],palette[i*3+1],palette[i*3],255))
 offsets=[];sizes=[];data=[];start=1172;ww,hh=w,h
 while True:
  level=image.resize((ww,hh),Image.Resampling.LANCZOS).quantize(palette=q,dither=Image.Dither.FLOYDSTEINBERG)
  b=level.tobytes()+bytes([255])*(ww*hh);offsets.append(start);sizes.append(len(b));data.append(b);start+=len(b)
  if ww==hh==1:break
  ww=max(1,ww//2);hh=max(1,hh//2)
 offsets+=[0]*(16-len(offsets));sizes+=[0]*(16-len(sizes))
 return pack('<4sI4BII',b'BLP2',1,1,8,0,1,w,h)+pack('<32I',*(offsets+sizes))+pal+b''.join(data)
def put(key,b):
 p=OUT/key;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
def resolve(sex,color):
 target={};fields=[color,0,0,0,0]
 for r in records:
  gender,kind,slot,value,*sel=U('<7I',r)
  if gender!=sex or kind!=1 or slot not in (11,12):continue
  if not all(q==0xffffffff or (q>>16)==fields[q&65535] for q in sel):continue
  target.setdefault(slot,r[28:].split(b'\0')[0].decode())
 assert set(target)=={11,12};return target
report={};palettes={}
for sexname,gender in [('Male',0),('Female',1)]:
 sourceuv=np.zeros((S,S,2),np.float32);slots=np.zeros((S,S),np.uint8);skipped=0
 for slot,rawUV,newUV in triangles[sexname]:
  xy=np.array(newUV)*S;tex=np.array(rawUV)
  if np.ptp(xy[:,0])>.54*S or np.ptp(xy[:,1])>.54*S:skipped+=1;continue
  x0=max(0,int(xy[:,0].min()));x1=min(S-1,math.ceil(xy[:,0].max()));y0=max(0,int(xy[:,1].min()));y1=min(S-1,math.ceil(xy[:,1].max()))
  x,y=np.meshgrid(np.arange(x0,x1+1)+.5,np.arange(y0,y1+1)+.5)
  a,b,d=xy;den=(b[1]-d[1])*(a[0]-d[0])+(d[0]-b[0])*(a[1]-d[1])
  if abs(den)<1e-10:continue
  l0=((b[1]-d[1])*(x-d[0])+(d[0]-b[0])*(y-d[1]))/den
  l1=((d[1]-a[1])*(x-d[0])+(a[0]-d[0])*(y-d[1]))/den;l2=1-l0-l1
  ok=(l0>=-.008)&(l1>=-.008)&(l2>=-.008)
  uv=l0[...,None]*tex[0]+l1[...,None]*tex[1]+l2[...,None]*tex[2]
  sourceuv[y0:y1+1,x0:x1+1][ok]=uv[ok];slots[y0:y1+1,x0:x1+1][ok]=slot
 covered=slots!=0;palettes[sexname]=[]
 for color in range(13):
  refs=resolve(gender,color);pixels=np.zeros((S,S,3),np.uint8)
  for slot,key in refs.items():
   raw=read(c/'Data/Patch-YJ.mpq',key);assert raw,key
   im=Image.open(BytesIO(raw)).convert('RGB');im=im.resize((max(1,im.width//2),max(1,im.height//2)),Image.Resampling.LANCZOS);atlas=np.array(im)
   xx=np.clip((sourceuv[:,:,0]*im.width).astype(int),0,im.width-1);yy=np.clip((sourceuv[:,:,1]*im.height).astype(int),0,im.height-1);mask=slots==slot
   pixels[mask]=atlas[yy[mask],xx[mask]]
  valid=covered.copy()
  # Colour dilation at seams without copying one skin's artwork into another.
  for _ in range(8):
   total=np.zeros_like(pixels,dtype=np.uint32);count=np.zeros((S,S),np.uint16)
   for dy,dx in ((-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)):
    mask=np.roll(valid,(dy,dx),(0,1));colour=np.roll(pixels,(dy,dx),(0,1))
    if dy<0:mask[dy:]=False
    if dy>0:mask[:dy]=False
    if dx<0:mask[:,dx:]=False
    if dx>0:mask[:,:dx]=False
    total+=colour*mask[:,:,None];count+=mask
   fill=(~valid)&(count>0);pixels[fill]=(total[fill]/count[fill,None]).astype(np.uint8);valid|=fill
  pixels[~valid]=pixels[valid].mean(0).astype(np.uint8)
  image=Image.fromarray(pixels);prefix=f'Reborn/StormforgedBody1A/{sexname}/Skin{color:02}'
  put(prefix+'.blp',blp(image))
  for suffix,rect in {'FL':(0,384,256,512),'FU':(0,320,256,384),'LU':(256,192,512,320),'TU':(256,0,512,128)}.items():put(prefix+'_'+suffix+'.blp',blp(image.crop(rect)))
  if color==0:
   p=W/'checks'/f'{sexname}-composite-base.png';p.parent.mkdir(exist_ok=True);image.save(p)
  palettes[sexname].append({'color':color,'base':prefix+'.blp','refs':refs})
  print(sexname,'baked palette',color,flush=True)
 report[sexname]={'mapped_pixels':int(covered.sum()),'skipped_seam_triangles':skipped,'textures':65,'base_resolution':512}
(W/'palettes.json').write_text(json.dumps(palettes,indent=2));(W/'bake-report.json').write_text(json.dumps(report,indent=2))
