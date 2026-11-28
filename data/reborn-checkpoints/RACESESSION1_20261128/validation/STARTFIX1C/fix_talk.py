from pathlib import Path
import pose_tools as p
from struct import pack,pack_into
from hashlib import sha256
p.load('bear');base=p.b;b=bytearray(base);seqN,seqO=p.u('<II',base,28);t=p.bo+16;nt,ot=p.u('<II',base,t+4);nv,ov=p.u('<II',base,t+12);times=[base[ot+8*i:ot+8*i+8] for i in range(nt)];values=[base[ov+8*i:ov+8*i+8] for i in range(nv)]
def emit(raw):
 while len(b)%4:b.append(0)
 off=len(b);b.extend(raw);return off
report=[]
for seq in range(seqN):
 ident,_,duration=p.u('<HHI',base,seqO+seq*64)
 if seq<78 or seq>98 or not (60<=ident<=84 or ident==113):continue
 ticks=list(range(0,duration,20))+[duration-1];coords=[]
 for ms in ticks:
  _,_,posed=p.posed(seq,ms);old=p.vector(p.bo,16,seq,ms,[0.,0.,0.]);rise=max(0.,.008-float(posed[:,2].min()));old[2]+=rise;coords.append(old)
 times[seq]=pack('<II',len(ticks),emit(pack('<'+str(len(ticks))+'I',*ticks)))
 values[seq]=pack('<II',len(ticks),emit(b''.join(pack('<3f',*v) for v in coords)));report.append((seq,ident,min(v[2] for v in coords),max(v[2] for v in coords)))
assert all(p.u('<I',base,ov+8*i)[0]==0 for i,_,_,_ in report)
pack_into('<H',b,t,1) # Linear interpolation; all original slots were empty.
pack_into('<II',b,t+4,nt,emit(b''.join(times)));pack_into('<II',b,t+12,nv,emit(b''.join(values)))
p.b=bytes(b)
for seq,ident,lo,hi in report:
 vals=[p.posed(seq,ms)[2][:,2].min() for ms in range(0,p.u('<I',b,seqO+seq*64+4)[0],20)]
 assert min(vals)>-.01,(seq,min(vals))
 allv=p.np.concatenate([p.posed(seq,ms)[2] for ms in range(0,p.u('<I',b,seqO+seq*64+4)[0],20)])
 pack_into('<7f',b,seqO+seq*64+32,*allv.min(0),*allv.max(0),float(p.np.linalg.norm(allv,axis=1).max()))
 print('seat',seq,ident,'root lift',round(lo,3),round(hi,3),'floor',round(float(min(vals)),4),round(float(max(vals)),4))
# Geometry, skeleton records other than this one track header and all old payload bytes retained.
allowed=set(range(t,t+2))|set(range(t+4,t+20));allowed.update(i for seq,_,_,_ in report for i in range(seqO+seq*64+32,seqO+seq*64+60))
assert all(x==y for i,(x,y) in enumerate(zip(base,b)) if i not in allowed)
(w:=Path(__file__).resolve().parent).joinpath('bear-fixed.m2').write_bytes(b)
print('PASS append-only root translation fix',sha256(b).hexdigest())

