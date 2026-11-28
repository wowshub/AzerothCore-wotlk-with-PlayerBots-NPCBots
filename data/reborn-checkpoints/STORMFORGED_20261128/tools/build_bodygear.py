import sys,json,math
from pathlib import Path
from struct import unpack_from as U,pack,pack_into as P
import numpy as np
W=Path('stormforged-intake/bodygear1a');ORIG=W/'orig_true/Patch-YJ';OUT=W/'after/Patch-YJ'
REG=[(0,0,128,64),(0,64,128,64),(0,128,128,32),(128,0,128,64),(128,64,128,32),(128,96,128,64),(128,160,128,64),(128,224,128,32)]
def array(b,h,size):
 n,o=U('<2I',b,h);return [bytes(b[o+i*size:o+(i+1)*size]) for i in range(n)]
def emit(b,h,data,n):
 b.extend(bytes(-len(b)%16));o=len(b);b.extend(data);P('<2I',b,h,n,o);return o
def halfs(b,h):return [U('<H',v)[0] for v in array(b,h,2)]
def emit16(b,h,vals):return emit(b,h,pack('<'+'H'*len(vals),*vals),len(vals))
def save(path,b):
 p=OUT/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
report={};bake={}
for sex,folder in [('Male','StormforgedVrykul'),('Female','IronVrykulFemale2')]:
 female=sex=='Female';stem=f'Creature/{folder}/StormforgedPlayer{sex}';base=(ORIG/(stem+'.m2')).read_bytes();m=bytearray(base)
 oldverts=array(base,60,48);verts=list(oldverts);pos=np.array([U('<3f',v) for v in oldverts]);nb,bo=U('<2I',base,44)
 parent=[U('<h',base,bo+i*88+8)[0] for i in range(nb)]
 def ancestor(bone,roots):
  while bone>=0:
   if bone in roots:return True
   bone=parent[bone]
  return False
 arms=(19,21) if female else (27,28);neck=1.98 if female else 2.12;hip=1.12 if female else 1.25;chest=1.38 if female else 1.50;knee=.69 if female else .72;wrist=1.189 if female else 1.375;elbow=1.51 if female else 1.715;shoulder=1.812 if female else 2.032
 upperY=.241 if female else .309;elbowY=.347 if female else .536;wristY=.431 if female else .781
 def classify(point,arm):
  x,y,z=point
  if arm:return 0 if z>elbow else 1 if z>wrist else 2
  if z>chest:return 3
  if z>hip:return 4
  if z>knee:return 5
  if z>.17:return 6
  return 7
 def uv(point,region):
  x,y,z=point
  if region<3:
   high,low=[(shoulder,elbow),(elbow,wrist),(wrist,wrist-.25)][region]
   ya,yb=[(upperY,elbowY),(elbowY,wristY),(wristY,wristY+.06)][region]
   t=np.clip((high-z)/(high-low),0,1);yc=ya+(yb-ya)*t
   u=abs(math.atan2(abs(y)-yc,x+.11))/math.pi;v=t
  elif region in (3,4):
   high,low=(neck,chest) if region==3 else (chest,hip)
   u=abs(math.atan2(y,x+.05))/math.pi;v=(high-z)/(high-low)
  else:
   high,low=[(hip,knee),(knee,.17),(.17,-.02)][region-5]
   yc=.19 if female else .20
   u=abs(math.atan2(abs(y)-yc,x+.04))/math.pi;v=(high-z)/(high-low)
  rx,ry,rw,rh=REG[region]
  return ((rx+np.clip(u,.004,.996)*rw)/256,(ry+np.clip(v,.004,.996)*rh)/256)
 # New stable opaque weight track. All original animation/texture tracks remain.
 times=emit(m,0,b'',0) if False else None
 def append(data):
  m.extend(bytes(-len(m)%16));o=len(m);m.extend(data);return o
 time=append(pack('<I',0));value=append(pack('<h',32767));ta=append(pack('<2I',1,time));ka=append(pack('<2I',1,value))
 tracks=array(base,88,20);weight=len(tracks);tracks.append(pack('<HH4I',0,0,1,ta,1,ka));emit(m,88,b''.join(tracks),len(tracks))
 weights=halfs(base,144);wc=len(weights);weights.append(weight);emit16(m,144,weights)
 transforms=halfs(base,152);tc=len(transforms);transforms.append(65535);emit16(m,152,transforms)
 textures=array(base,80,16);clothTex=len(textures);textures.append(pack('<4I',1,0,0,0));capeTex=len(textures);textures.append(pack('<4I',2,0,0,0));emit(m,80,b''.join(textures),len(textures))
 replace=halfs(base,104)
 while len(replace)<3:replace.append(65535)
 assert not any(U('<I',entry)[0] in (1,2) for entry in textures[:-2])
 replace[1]=clothTex;replace[2]=capeTex;emit16(m,104,replace)
 combos=halfs(base,128);clothCombo=len(combos);combos.append(clothTex);capeCombo=len(combos);combos.append(capeTex);emit16(m,128,combos)
 coords=halfs(base,136);uv2=len(coords);coords.append(1);uv0=len(coords);coords.append(0);emit16(m,136,coords)
 mats=array(base,112,4);material=len(mats);mats.append(pack('<2H',4,0));capeMaterial=len(mats);mats.append(pack('<2H',4,1));emit(m,112,b''.join(mats),len(mats))
 boneCombos=halfs(base,120);extraBoneCombo=len(boneCombos);spine=7 if female else 14;waist=3;boneCombos.extend([spine,waist]);emit16(m,120,boneCombos)
 def batch(section,combo,coordsIndex,layer=2,mat=None):return pack('<Bb11H',16,0,0,section,section,65535,material if mat is None else mat,layer,1,combo,coordsIndex,wc,tc)
 # Overlay vertices are copies. The original UV2, weights, normals and mesh
 # bytes are untouched, including the female specular effects and face.
 duplicates={};vertexSources={};allBody=set();bakeTris=[];lods=[]
 def duplicate(orig,region):
  key=(orig,region)
  if key not in duplicates:
   v=bytearray(oldverts[orig]);P('<2f',v,40,*uv(pos[orig],region))
   duplicates[key]=len(verts);vertexSources[len(verts)]=[orig,region];verts.append(bytes(v))
  return duplicates[key]
 for lod in range(U('<I',base,68)[0]):
  sk0=(ORIG/(stem+f'{lod:02}.skin')).read_bytes();idx=halfs(sk0,4);tri=halfs(sk0,12);props=array(sk0,20,4);sections=array(sk0,28,48);batches=array(sk0,36,24)
  body=[];primary={}
  for j,sec in enumerate(sections):
   if U('<H',sec)[0]!=0:continue
   for b in batches:
    if U('<H',b,4)[0]!=j or U('<H',b,8)[0]!=65535 or not U('<H',b,14)[0]:continue
    ti=halfs(base,128)[U('<H',b,16)[0]]
    slot=U('<I',base,U('<I',base,84)[0]+16*ti)[0]
    if slot in (11,12):body.append(j);primary[j]=(b,slot);break
  assert body,(sex,lod,'no body sections')
  nsec0=len(sections);added=[];bodyTriangles=0
  for si in body:
   sec=sections[si];vs,vc,start,count,bn,bcombo=U('<6H',sec,4);start|=U('<H',sec,2)[0]<<16
   template,slot=primary[si]
   assert slot in (11,12),(sex,lod,si,slot)
   groups={i:[] for i in range(8)}
   for k in range(start,start+count,3):
    t=tri[k:k+3];ids=[idx[j] for j in t];pp=pos[ids]
    if np.max(pp[:,2])>=neck:continue
    influence=0
    for vi,orig in zip(t,ids):
     for q,weightVal in enumerate(oldverts[orig][12:16]):
      if weightVal:
       bone=boneCombos[bcombo+props[vi][q]];influence+=weightVal*ancestor(bone,arms)
    region=classify(pp.mean(0),influence>255*1.15)
    groups[region].append(t);allBody.update(ids)
    if lod==0:bakeTris.append([slot,[list(U('<2f',oldverts[v],32)) for v in ids],[list(uv(pos[v],region)) for v in ids]])
   for region,tt in groups.items():
    if not tt:continue
    used=sorted({v for t in tt for v in t});local={v:len(idx)+k for k,v in enumerate(used)};vstart=len(idx);tstart=len(tri)
    idx.extend(duplicate(idx[v],region) for v in used);props.extend(props[v] for v in used)
    tri.extend(local[v] for t in tt for v in t)
    s=bytearray(sec);P('<2H',s,0,22001+region,tstart>>16);P('<4H',s,4,vstart,len(used),tstart&65535,len(tt)*3)
    sections.append(bytes(s));batches.append(batch(len(sections)-1,clothCombo,uv2));added.append([22001+region,len(tt)]);bodyTriangles+=len(tt)
  lods.append(dict(original=sk0,idx=idx,tri=tri,props=props,sections=sections,batches=batches,body=body,added=added,bodyTriangles=bodyTriangles))
 # Geometry for cloak and robes uses an independent two-bone palette. Every
 # column in a row has identical weights; no accidental binding to the arms.
 def vertex(point,normal,uvs,w0,w1):return pack('<3f4B4B3f2f2f',*point,w0,w1,0,0,0,1,0,0,*normal,*uvs,*uvs)
 bodyPoints=pos[sorted(allBody)]
 cape=[];capeTris=[];rows=10;cols=8;ztop=1.80 if female else 1.97;zbottom=.36;previousBack=None
 for row in range(rows+1):
  t=row/rows;z=ztop+(zbottom-ztop)*t
  nearby=bodyPoints[(abs(bodyPoints[:,2]-z)<.085)&(abs(bodyPoints[:,1])<.28)]
  bx=float(nearby[:,0].min())-.05 if len(nearby) else -.28
  # Smooth continuous backwards envelope, never folded towards the body.
  bx=min(bx,(-.27 if previousBack is None else previousBack-.004));previousBack=bx
  for col in range(cols+1):
   e=2*col/cols-1;x=bx-.012*math.cos(abs(e)*math.pi*3);y=e*(.24+.07*t)
   cape.append((x,y,z))
 capeStart=len(verts)
 for j,pnt in enumerate(cape):
  t=(j//(cols+1))/rows;e=2*(j%(cols+1))/cols-1;lo=round(255*.60*t)
  verts.append(vertex(pnt,(-1,0,0),(.99-.74*abs(e),.99*t),255-lo,lo))
 for row in range(rows):
  for col in range(cols):
   a=row*(cols+1)+col;b=a+1;d=a+cols+1;e=d+1;capeTris.extend([(a,d,b),(b,d,e)])
 robe=[];robeTris=[];rr=10;cc=16
 for row in range(rr+1):
  t=row/rr;z=hip+.055-(hip+.055-.095)*t
  for col in range(cc+1):
   ang=2*math.pi*col/cc;x=-.05+(.24+.04*t)*math.cos(ang);y=(.29+.045*t)*math.sin(ang)
   robe.append((x,y,z))
 robeStart=len(verts)
 for j,pnt in enumerate(robe):
  ang=2*math.pi*(j%(cc+1))/cc;t=(j//(cc+1))/rr;z=pnt[2]
  region=5 if z>=knee else 6 if z>=.17 else 7;uvs=uv(pnt,region)
  # Long robe follows the pelvis; skirt deformation/leg clipping must be
  # checked in the game. The original walking animation is untouched.
  verts.append(vertex(pnt,(math.cos(ang),math.sin(ang),0),uvs,0,255))
 for row in range(rr):
  for col in range(cc):
   a=row*(cc+1)+col;b=a+1;d=a+cc+1;e=d+1;robeTris.extend([(a,b,d),(b,e,d)])
 def append_grid(lod,points,triangles,first,gids,combo):
  idx,tri,props,sections,batches=[lod[k] for k in ('idx','tri','props','sections','batches')];vs=len(idx)
  idx.extend(range(first,first+len(points)));props.extend([bytes((0,1,0,0))]*len(points))
  centre=np.array(points).mean(0);radius=float(np.linalg.norm(np.array(points)-centre,axis=1).max())
  for gid in gids:
   # Separate source triangle spans per variant avoid depending on an older
   # engine's index-buffer allocation assumptions for overlapping sections.
   ts=len(tri);tri.extend(vs+v for t in triangles for v in t)
   s=bytearray(48);P('<10H',s,0,gid,ts>>16,vs,len(points),ts&65535,len(triangles)*3,2,extraBoneCombo,2,spine)
   P('<3f',s,20,*centre);P('<3f',s,32,*centre);P('<f',s,44,radius)
   sections.append(bytes(s));batches.append(batch(len(sections)-1,combo,uv0,0 if gid>=1500 else 2,capeMaterial if gid>=1500 else material))
 for lod,sk in enumerate(lods):
  append_grid(sk,cape,capeTris,capeStart,range(1501,1511),capeCombo)
  append_grid(sk,robe,robeTris,robeStart,range(1301,1311),clothCombo)
  assert len(sk['idx'])<65536 and len(verts)<65536
  out=bytearray(sk['original']);emit16(out,4,sk['idx']);emit16(out,12,sk['tri']);emit(out,20,b''.join(sk['props']),len(sk['props']));emit(out,28,b''.join(sk['sections']),len(sk['sections']));emit(out,36,b''.join(sk['batches']),len(sk['batches']))
  save(stem+f'{lod:02}.skin',out)
 emit(m,60,b''.join(verts),len(verts));save(stem+'.m2',m)
 report[sex]={'stem':stem,'old_vertices':len(oldverts),'new_vertices':len(verts),'overlay_duplicate_sources':vertexSources,'cape_vertices':[capeStart,len(cape)],'robe_vertices':[robeStart,len(robe)],'material':material,'cape_material':capeMaterial,'weight_combo':wc,'transform_combo':tc,'lods':[{'original_body_sections':sk['body'],'added_body_regions':sk['added'],'body_triangles':sk['bodyTriangles'],'vertices':len(sk['idx']),'index_count':len(sk['tri'])} for sk in lods]}
 bake[sex]=bakeTris
 print(sex,'vertices',len(oldverts),'->',len(verts),'LOD regions',[sk['added'] for sk in lods],flush=True)
(W/'geometry-report.json').write_text(json.dumps(report,indent=2));(W/'bake-triangles.json').write_text(json.dumps(bake))
