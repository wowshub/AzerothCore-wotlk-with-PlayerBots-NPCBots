import pose_tools as p
from pathlib import Path
import json,numpy as np
w=Path(__file__).parent;p.load('bear');base=p.b;data=json.loads((w/'cape.json').read_text());points=np.array(data['points']);weights=np.array(data['weights'])/255;nb,ofs=p.u('<II',base,36);results=[];rows=[[] for _ in range(9)]
for ident in [0,4,5,60,97]:
 seq=p.u('<h',base,ofs+ident*2)[0];dur=p.u('<I',base,p.u('<I',base,32)[0]+seq*64+4)[0]
 for ms in [0,dur//3,2*dur//3,dur-1]:
  R,T,body=p.posed(seq,ms);cape=(weights[:,:3,None]*(np.einsum('vi,kij->vkj',points,R[[10,6,2]])+T[[10,6,2]])).sum(1);tri=body[p.tris];a=tri[:,1,1:]-tri[:,0,1:];c=tri[:,2,1:]-tri[:,0,1:];det=a[:,0]*c[:,1]-a[:,1]*c[:,0];valid=abs(det)>1e-7;tri,a,c,det=tri[valid],a[valid],c[valid],det[valid];gaps=[]
  for vi,q in enumerate(cape):
   d=q[1:]-tri[:,0,1:];l=(d[:,0]*c[:,1]-d[:,1]*c[:,0])/det;m=(a[:,0]*d[:,1]-a[:,1]*d[:,0])/det;mask=(l>=0)&(m>=0)&(l+m<=1);x=tri[:,0,0]+l*(tri[:,1,0]-tri[:,0,0])+m*(tri[:,2,0]-tri[:,0,0])
   if mask.any():
    value=float(x[mask].min()-q[0]);gaps.append(value);rows[vi//7].append(value)
  results.append({'id':ident,'ms':ms,'gap_min':min(gaps) if gaps else None,'gap_median':float(np.median(gaps)) if gaps else None,'floor':float(cape[:,2].min())});print(results[-1])
(w/'cape-pose-results.json').write_text(json.dumps(results,indent=2),'utf8')

print("row min/median",[(round(min(v),3),round(float(np.median(v)),3)) for v in rows])
