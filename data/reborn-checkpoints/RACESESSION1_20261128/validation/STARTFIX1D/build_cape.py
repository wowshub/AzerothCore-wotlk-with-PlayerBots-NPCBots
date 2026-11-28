from pathlib import Path
from struct import unpack_from as u,pack,pack_into
import numpy as np,json,hashlib,math
w=Path(__file__).parent;base=(w/'bear.m2').read_bytes();skinbase=(w/'bear00.skin').read_bytes();assert hashlib.sha256(base).hexdigest()=='643e4ff13efdde3a6dd1c660d45fb58716364c09a679d9cee7abce7d4c47fc97'
b=bytearray(base);sk=bytearray(skinbase)
def arr(blob,h,stride):
 n,o=u('<II',blob,h);assert o+n*stride<=len(blob);return [blob[o+i*stride:o+(i+1)*stride] for i in range(n)]
def shorts(blob,h):return [u('<H',v)[0] for v in arr(blob,h,2)]
def emit(blob,h,items,fmt=None):
 blob.extend(bytes(-len(blob)%16));off=len(blob);blob.extend(pack('<'+str(len(items))+fmt,*items) if fmt else b''.join(items));pack_into('<II',blob,h,len(items),off)
opacities=arr(base,88,20);weightCombos=shorts(base,144)
vertices=arr(base,60,48);oldnv=len(vertices);textures=arr(base,80,16);assert 2 not in [u('<I',v)[0] for v in textures];materials=arr(base,112,4);palette=shorts(base,120);combo=shorts(base,128);replace=shorts(base,104)
texidx=len(textures);textures.append(pack('<4I',2,0,0,0));capecombo=len(combo);combo.append(texidx);matidx=len(materials);materials.append(pack('<HH',4,0));palstart=len(palette);bones=[10,6,2];palette+=bones
while len(replace)<3:replace.append(65535)
assert replace[2]==65535;replace[2]=texidx
points=[];weights=[]
for row in range(9):
 t=row/8;z=1.84-.99*t;x=-.39-.11*t;width=.245+.11*t
 if z>=1.45:
  a=max(0,min(1,(z-1.45)/.30));ww=[round(128+127*a),127-round(127*a),0,0]
 elif z>=1.20:
  a=(1.45-z)/.25;ww=[round(128*(1-a)),127,round(128*a),0]
 else:
  a=max(0,min(1,(z-.98)/.22));ww=[0,round(127*a),255-round(127*a),0]
 assert sum(ww)==255
 for col in range(7):
  s=(col-3)/3;points.append((x+.025*s*s,width*s,z+.018*s*s));weights.append(ww)
if (w/'cape-fit.json').exists():points=json.loads((w/'cape-fit.json').read_text('utf8'))['points']
for i,xyz in enumerate(points):
 row,col=divmod(i,7);left=points[row*7+max(0,col-1)];right=points[row*7+min(6,col+1)];top=points[max(0,row-1)*7+col];bottom=points[min(8,row+1)*7+col];normal=np.cross(np.subtract(right,left),np.subtract(bottom,top));normal/=np.linalg.norm(normal);assert normal[0]<0
 side=abs((col-3)/3);uv=(.99-.74*side,.99*row/8)
 vertices.append(pack('<3f8B7f',*xyz,*weights[i],10,6,2,0,*normal,*uv,*uv))
# Do not reuse the original empty opacity track: the new cape needs real opaque keys.
def raw(payload):
 b.extend(bytes(-len(b)%16));off=len(b);b.extend(payload);return off
seqN=u('<I',base,28)[0];time=raw(pack('<I',0));value=raw(pack('<h',32767))
times=raw(pack('<II',1,time)*seqN);values=raw(pack('<II',1,value)*seqN)
opacityIndex=len(opacities);opacities.append(pack('<Hh4I',0,-1,seqN,times,seqN,values))
weightCombo=len(weightCombos);weightCombos.append(opacityIndex)
for h,items,fmt in [(88,opacities,None),(144,weightCombos,'H'),(60,vertices,None),(80,textures,None),(104,replace,'H'),(112,materials,None),(120,palette,'H'),(128,combo,'H')]:emit(b,h,items,fmt)
lookup=shorts(skinbase,4);tris=shorts(skinbase,12);props=arr(skinbase,20,4);sections=arr(skinbase,28,48);batches=arr(skinbase,36,24);assert not any(1500<=u('<I',v)[0]<1600 for v in sections)
start=len(lookup);first=len(tris);lookup+=list(range(oldnv,len(vertices)));props += [bytes([0,1,2,0])]*63
for row in range(8):
 for col in range(6):
  j=start+row*7+col;tris.extend([j,j+7,j+1,j+1,j+7,j+8])
center=tuple(np.mean(points,axis=0));radius=max(math.dist(v,center) for v in points)
for gid in range(1501,1511):
 sec=len(sections);sections.append(pack('<I8H7f',gid,start,63,first,288,3,palstart,3,10,*center,*center,radius));batches.append(pack('<BB11H',0,0,0,sec,sec,65535,matidx,0,1,capecombo,0,weightCombo,0))
for h,items,fmt in [(4,lookup,'H'),(12,tris,'H'),(20,props,None),(28,sections,None),(36,batches,None)]:emit(sk,h,items,fmt)
# Original geometry, animation payload and all original batches remain bit-for-bit intact.
allowed={j for off in [60,80,88,104,112,120,128,144] for j in range(off,off+8)}
assert all(x==y for j,(x,y) in enumerate(zip(base,b)) if j not in allowed)
for h,stride in [(60,48),(80,16),(88,20),(112,4),(120,2),(128,2),(144,2)]:assert arr(b,h,stride)[:u('<I',base,h)[0]]==arr(base,h,stride)
for h,stride in [(4,2),(12,2),(20,4),(28,48),(36,24)]:assert arr(sk,h,stride)[:u('<I',skinbase,h)[0]]==arr(skinbase,h,stride)
assert max(tris)<len(lookup) and max(lookup)<len(vertices)
(w/'bear-cape.m2').write_bytes(b);(w/'bear-cape00.skin').write_bytes(sk);(w/'cape.json').write_text(json.dumps({'points':points,'weights':weights,'old_vertices':oldnv,'cape_vertices':63,'geosets':list(range(1501,1511))},indent=2),'utf8')
print('PASS append-only model and skin: 63 vertices, 96 shared triangles, 10 native cape styles; motion/old geometry preserved')
