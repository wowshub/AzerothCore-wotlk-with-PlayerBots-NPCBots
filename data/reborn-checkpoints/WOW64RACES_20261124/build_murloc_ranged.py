from pathlib import Path
from hashlib import sha256
from argparse import ArgumentParser
import struct as s

def arr(b,at):return s.unpack_from('<II',b,at)
def chunks(b,at,size):
 n,o=arr(b,at)
 assert o+n*size<=len(b)
 return [b[o+i*size:o+(i+1)*size] for i in range(n)]
BOW={29:(108,False),46:(107,True),47:(107,True),105:(108,True),109:(108,False),48:(108,False),49:(107,True),106:(108,True),110:(108,False)}
def attachments(b):
 return {s.unpack_from('<I',a)[0]:a for a in chunks(b,240,40)}
def seqmap(b):
 return {s.unpack_from('<H',a)[0]:i for i,a in enumerate(chunks(b,28,64)) if s.unpack_from('<H',a,2)[0]==0}
def times(b,event,index):
 n,o=arr(event,28)
 if index>=n:return ()
 ct,at=arr(b,o+8*index)
 return s.unpack_from(f'<{ct}I',b,at) if ct else ()
plus=(b"$BWR",b"$BWP")
def patch(old):
 seq=list(chunks(old,28,64)); names=seqmap(old); prior=len(seq)
 lookup=[s.unpack('<h',x)[0] for x in chunks(old,36,2)]
 assert len(lookup)>max(BOW)
 out=bytearray(old)
 allowed=set()
 def append(data,align=16):
  out.extend(bytes(-len(out)%align));start=len(out);out.extend(data);return start
 def write(at,data):
  allowed.update(range(at,at+len(data)));out[at:at+len(data)]=data
 def pair(at,n,o):
  write(at,s.pack('<II',n,o))
 source={}
 for aid,(donor,oneshot) in BOW.items():
  i=names[donor]
  rec=bytearray(seq[i]); idx=len(seq)
  flags=s.unpack_from('<I',rec,12)[0]
  assert flags&0x20 and not flags&0x40 and aid not in names
  assert lookup[aid]==-1 or (aid in {48,49} and s.unpack_from('<H',seq[lookup[aid]])[0] in (108,225))
  s.pack_into('<HH',rec,0,aid,0)
  s.pack_into('<I',rec,12,0x21 if oneshot else 0x20)
  s.pack_into('<HH',rec,60,65535,idx)
  source[idx]=i
  seq.append(rec);lookup[aid]=idx
 pair(28,len(seq),append(b''.join(seq)))
 pair(36,len(lookup),append(s.pack(f'<{len(lookup)}h',*lookup)))
 def extend_track(at):
  typ,loop,tn,to,kn,ko=s.unpack_from('<Hh4I',old,at)
  if loop!=-1 or not tn:return
  assert tn==kn and tn<=prior and to+8*tn<=len(old) and ko+8*kn<=len(old)
  tails=[b'',b'']
  for idx in source:
   i=source[idx]
   for j,base in enumerate((to,ko)):
    tails[j]+=old[base+8*i:base+8*(i+1)] if i<tn else bytes(8)
  gap=bytes(8*(prior-tn))
  for field,base,tail in zip((4,12),(to,ko),tails):
   pair(at+field,len(seq),append(old[base:base+8*tn]+gap+tail))
 for field,size,tracks in [(44,88,(16,36,56)),(72,40,(0,20)),(88,20,(0,)),(96,60,(0,20,40)),(240,40,(20,)),(272,100,(16,48,80))]:
  n,start=arr(old,field)
  assert n==0 or start+n*size<=len(old)
  for i in range(n):
   for off in tracks:
    extend_track(start+i*size+off)
 assert all(arr(old,field)[0]==0 for field in (264,288,296))
 # Recover the extended attachment records, then add the right-hand arrow point.
 aa=chunks(out,240,40)
 right=attachments(out)[1]
 al=[s.unpack('<H',a)[0] for a in chunks(out,248,2)]
 if len(al)<=36:al.extend([65535]*(37-len(al)))
 for socket in (35,36):
  assert al[socket]==65535
  al[socket]=len(aa)
  record=bytearray(right)
  s.pack_into('<I',record,0,socket)
  if socket==36:
   s.pack_into('<f',record,8,s.unpack_from('<f',right,8)[0]+0.18)
  aa.append(record)
 pair(240,len(aa),append(b''.join(aa)))
 pair(248,len(al),append(s.pack(f'<{len(al)}H',*al)))
 # Ship native bow events on the new records only; the donor's generic
 # missile event would also set aim origin and must stay on 107 alone.
 ev=chunks(old,256,36)
 release=next(times(old,e,names[107])[0] for e in ev if e[:4]==b'$CSR' and times(old,e,names[107]))
 assert not {e[:4] for e in ev}.intersection(plus)
 prep=round(633*s.unpack_from('<I',seq[lookup[105]],4)[0]/1000)
 for tag,items in [(b'$BWP',{lookup[x]:prep for x in (105,106)}),(b'$BWR',{lookup[x]:release for x in (46,47,49)})]:
  time_table=[bytes(8)]*len(seq)
  for index,t in items.items():
   assert 0<t<s.unpack_from('<I',seq[index],4)[0]
   time_table[index]=s.pack('<II',1,append(s.pack('<I',t),4))
  ev.append(tag+s.pack('<II',0,s.unpack_from('<H',right,4)[0])+right[8:20]+s.pack('<HhII',0,-1,len(seq),append(b''.join(time_table))))
 pair(256,len(ev),append(b''.join(ev)))
 assert all(x==y or i in allowed for i,(x,y) in enumerate(zip(old,out)))
 return bytes(out),release,prep
def verify(old,new,release,prep):
 oldseq=chunks(old,28,64); names=seqmap(new)
 assert chunks(new,28,64)[:len(oldseq)]==oldseq
 assert set(names)-set(seqmap(old))==set(BOW)
 assert chunks(new,60,48)==chunks(old,60,48)
 assert chunks(new,80,16)==chunks(old,80,16)
 before=attachments(old);after=attachments(new)
 assert after[35][4:20]==after[1][4:20] and after[36][4:8]==after[1][4:8] and all(after[k][:20]==v[:20] for k,v in before.items())
 evold=chunks(old,256,36); evnew=chunks(new,256,36)
 assert evnew[:len(evold)]==evold
 events={e[:4]:e for e in evnew[-2:]}
 for aid,(donor,_) in BOW.items():
  index=names[aid];base=names[donor]
  rec=chunks(new,28,64)[index]
  assert s.unpack_from('<H',chunks(new,36,2)[aid])[0]==index
  assert s.unpack_from('<H',rec,62)[0]==index
  assert times(new,events[b'$BWP'],index)==((prep,) if aid in (105,106) else ())
  assert times(new,events[b'$BWR'],index)==((release,) if aid in (46,47,49) else ())
  n,o=arr(new,44); moving=0
  for i in range(n):
   _,g,count,t,k,key=s.unpack_from('<Hh4I',new,o+88*i+36)
   if g!=-1 or not count:continue
   assert count==k and index<count
   refs=lambda start,slot:arr(new,start+8*slot)
   assert refs(t,index)==refs(t,base) and refs(key,index)==refs(key,base)
   ct,where=refs(t,index)
   ck,kwhere=refs(key,index)
   assert ct==ck and where+ct*4<=len(new) and kwhere+ck*8<=len(new)
   moving+=ct>1
  assert moving>=18,(aid,moving)
 assert all(not times(new,event,names[46]) for event in evold if event[:4]==b'$CSR')

MODELS = {'MurlocHordeMale.m2': ('40906bc158a5c225c0325c239b12a5dff747a1ed6b8eee5b7ea306ecb38c9cd3', '854b34a525107d8f872ecc8f382fe9f0c73f672cb26ab9c7deeffc5bc32d4ef7'), 'MurlocHordeFemale.m2': ('6a25d3b998e59b1118255d095a27c6198661dd649e9c4388f6b43c8af8a51517', '3125c4ba10a06680894d9a4549916c87ed66ed18831986b09e4056e196e0b612')}

if __name__ == "__main__":
    parser = ArgumentParser(description="Reproduce the 3G file from the exact 3D baseline.")
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    source = args.source.read_bytes()
    match = MODELS.get(args.source.name)
    if not match or sha256(source).hexdigest() != match[0]:
        parser.error("input must match one of the two 3D models")
    result, release, prep = patch(source)
    verify(source, result, release, prep)
    if sha256(result).hexdigest() != match[1]:
        raise RuntimeError("output hash mismatch")
    with args.destination.open("xb") as dest:
        dest.write(result)
