from pathlib import Path
from struct import unpack_from as u
import numpy as np
from math import cos,sin
w=Path(__file__).resolve().parent
def load(stem):
 global b,skin,nb,bo,nv,vo,lut,tris,vr,wgt,bidx
 b=(w/(stem+".m2")).read_bytes();skin=(w/(stem+"00.skin")).read_bytes()
 nb,bo=u('<II',b,44); nv,vo=u('<II',b,60)
 n,ofs=u('<II',skin,4); lut=np.frombuffer(skin,'<u2',count=n,offset=ofs)
 n,ofs=u('<II',skin,12); tris=lut[np.frombuffer(skin,'<u2',count=n,offset=ofs)].reshape(-1,3)
 vr=np.array([u('<3f',b,vo+48*i) for i in range(nv)])
 wgt=np.array([u('<4B',b,vo+48*i+12) for i in range(nv)])/255
 bidx=np.array([u('<4B',b,vo+48*i+16) for i in range(nv)])
def vector(o,track,seq,ms,default,quat=False):
 nc,oc=u('<II',b,o+track+12)
 if not nc:return np.array(default)
 n,k=u('<II',b,oc+8*(seq if seq<nc else 0))
 if not n:return np.array(default)
 nt,ot=u('<II',b,o+track+4)
 m,t=u('<II',b,ot+8*(seq if seq<nt else 0))
 ts=np.frombuffer(b,'<u4',count=m,offset=t)
 dv=np.frombuffer(b,'<u2' if quat else '<f4',count=n*(4 if quat else 3),offset=k).reshape(n,-1)
 if quat:dv=dv.astype(float)*(2/65535)-1
 slot=int(np.searchsorted(ts,ms,'right'))
 idx=min(n-1,max(0,slot-1))
 if slot<=0 or slot>=min(m,n):return dv[idx]
 a,c=dv[idx],dv[slot]
 if quat and a@c<0:c=-c
 f=(ms-int(ts[idx]))/max(1,int(ts[slot])-int(ts[idx]))
 return (1-f)*a+f*c
def rot(q):
 x,y,z,w=q/np.linalg.norm(q)
 return np.array([[1-2*y*y-2*z*z,2*x*y+2*w*z,2*x*z-2*w*y],[2*x*y-2*w*z,1-2*x*x-2*z*z,2*y*z+2*w*x],[2*x*z+2*w*y,2*y*z-2*w*x,1-2*x*x-2*y*y]])
def bone_frames(seq,ms):
 R=[];T=[]
 for i in range(nb):
  o=bo+i*88
  parent=u('<h',b,o+8)[0]
  pivot=np.array(u('<3f',b,o+76))
  lr=np.diag(vector(o,56,seq,ms,[1,1,1]))@rot(vector(o,36,seq,ms,[0,0,0,1],True))
  lt=pivot-pivot@lr+vector(o,16,seq,ms,[0,0,0])
  if parent>=0:lr,lt=lr@R[parent],lt@R[parent]+T[parent]
  R.append(lr);T.append(lt)
 return np.array(R),np.array(T)

def posed(seq,t):
 R,T=bone_frames(seq,t);v=(wgt[...,None]*(np.einsum('vi,vkij->vkj',vr,R[bidx])+T[bidx])).sum(1);return R,T,v
if __name__=='__main__':
 load('bear');n,so=u('<II',b,28)
 for i in range(n):
  ident,sub,duration=u('<HHI',b,so+i*64)
  if ident in [0,96,97,98,99]:
   vals=[]
   for t in [0,duration//2,max(0,duration-1)]:
    R,T,v=posed(i,t);vals.append((t,float(v[:,2].min()),float(v[:,2].max())))
   print('pose',i,ident,duration,vals)
 print('roots',[(i,u('<ih',b,bo+88*i),u('<h',b,bo+88*i+8)[0]) for i in range(nb) if u('<h',b,bo+88*i+8)[0]<0])
