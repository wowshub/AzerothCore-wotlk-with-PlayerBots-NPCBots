import pose_tools as p
from pathlib import Path
import numpy as np,json
w=Path(__file__).parent;p.load('bear');d=json.loads((w/'cape.json').read_text());points=np.array(d['points']);weights=np.array(d['weights'])/255;n,o=p.u('<II',p.b,36);frames=[]
for ident in [0,4,5,60,97]:
 seq=p.u('<h',p.b,o+ident*2)[0];duration=p.u('<I',p.b,p.u('<I',p.b,32)[0]+64*seq+4)[0]
 for ms in [0,duration//3,2*duration//3,duration-1]:
  R,T,body=p.posed(seq,ms);tri=body[p.tris];a=tri[:,1,1:]-tri[:,0,1:];c=tri[:,2,1:]-tri[:,0,1:];det=a[:,0]*c[:,1]-a[:,1]*c[:,0];valid=abs(det)>1e-7;frames.append((R,T,tri[valid],a[valid],c[valid],det[valid]))
def gap(idx,dx):
 out=[];v=points[idx].copy();v[0]+=dx
 for R,T,tri,a,c,det in frames:
  q=(weights[idx,:3,None]*(v@R[[10,6,2]]+T[[10,6,2]])).sum(0);dif=q[1:]-tri[:,0,1:];l=(dif[:,0]*c[:,1]-dif[:,1]*c[:,0])/det;m=(a[:,0]*dif[:,1]-a[:,1]*dif[:,0])/det;mask=(l>=0)&(m>=0)&(l+m<=1)
  if mask.any():
   x=tri[:,0,0]+l*(tri[:,1,0]-tri[:,0,0])+m*(tri[:,2,0]-tri[:,0,0]);out.append(float(x[mask].min()-q[0]))
 return min(out) if out else None
fits=[]
for row in range(9):
 for col in range(4):
  ids=[row*7+col,row*7+6-col];ids=list(set(ids));lo,hi=0,.30
  initial=[gap(i,0) for i in ids]
  if all(v is None for v in initial):hi=.04
  for _ in range(12):
   mid=(lo+hi)/2;g=[gap(i,mid) for i in ids];valid=[v for v in g if v is not None]
   if not valid or min(valid)>=.035:lo=mid
   else:hi=mid
  for i in ids:points[i,0]+=lo
  fits.append((row,col,lo))
(w/'cape-fit.json').write_text(json.dumps({'points':points.tolist(),'pushes':fits},indent=2),'utf8');print('symmetric cape surface fitted; max push',max(v[2] for v in fits))
