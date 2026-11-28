from pathlib import Path
from struct import unpack_from as u
w=Path(__file__).parent;b=(w/'bear-cape.m2').read_bytes();s=(w/'bear-cape00.skin').read_bytes()
def hdr(blob,h):return u('<II',blob,h)
def sh(h,i):n,o=hdr(b,h);assert i<n;return u('<H',b,o+2*i)[0]
nsec,osec=hdr(s,28);nb,ob=hdr(s,36);nv,ov=hdr(b,60);nmat,omat=hdr(b,112);ntex,otex=hdr(b,80);npal,opal=hdr(b,120);nidx,oidx=hdr(s,4);ntri,otri=hdr(s,12);nprops,oprops=hdr(s,20);boneN=hdr(b,44)[0];opacityN,opacityO=hdr(b,88)
seen=[]
for i in range(nb):
 vals=u('<BB11H',s,ob+i*24);flags,_,shader,sec,sec2,color,material,layer,count,combo,coord,weight,transform=vals;assert sec<nsec and sec2<nsec
 gid=u('<I',s,osec+48*sec)[0]
 if not 1501<=gid<=1510:continue
 seen.append(gid);assert flags==0 and shader==0 and count==1 and color==65535 and material<nmat
 assert u('<HH',b,omat+material*4)==(4,0)
 assert sh(136,coord)==0 and sh(144,weight)<opacityN and sh(152,transform)==65535
 tid=sh(128,combo);assert tid<ntex and u('<I',b,otex+16*tid)[0]==2 and sh(104,2)==tid
 _,start,num,first,numtri,numbones,bonestart,influences,centerbone=u('<I8H',s,osec+48*sec);assert num==63 and numtri==288 and bonestart+numbones<=npal and centerbone<boneN
 for j in range(start,start+num):
  vid=u('<H',s,oidx+j*2)[0];assert vid<nv;v=ov+vid*48;weights=u('<4B',b,v+12);globalbones=u('<4B',b,v+16);local=u('<4B',s,oprops+j*4);assert sum(weights)==255
  for k,weightv in enumerate(weights):
   if weightv:assert local[k]<numbones and globalbones[k]<boneN and sh(120,bonestart+local[k])==globalbones[k]
 for j in range(first,first+numtri):assert start<=u('<H',s,otri+j*2)[0]<start+num
assert sorted(seen)==list(range(1501,1511))
# All relevant opacity keys are real, readable and opaque for the selected native request owners.
track=opacityO+20*sh(144,weight);nt,ts=hdr(b,track+4);nk,ks=hdr(b,track+12);assert nt==nk
for seq in [2,4,5,78,99,100,101]:
 n,off=u('<II',b,ks+seq*8);assert n>0 and off+n*2<=len(b);assert all(x>=32766 for x in u('<'+str(n)+'h',b,off))
print('PASS 10 cape batches: indices/bone windows/materials/texture replacement/UV/opacity chains')
