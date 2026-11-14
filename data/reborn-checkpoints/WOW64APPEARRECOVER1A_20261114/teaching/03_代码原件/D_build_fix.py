from pathlib import Path
import struct,hashlib,json,collections
w=Path(__file__).parent
u16=lambda b,o:struct.unpack_from('<H',b,o)[0]
u32=lambda b,o:struct.unpack_from('<I',b,o)[0]
def arr(b,o,stride):
 n,p=struct.unpack_from('<II',b,o);assert p+n*stride<=len(b);return n,p
def sections(k):
 n,o=arr(k,28,48);return [(o+i*48,struct.unpack_from('<10H',k,o+i*48)) for i in range(n)]
def verts(b,k):
 n,o=arr(k,4,2);vn,vo=arr(b,60,48);pn,po=arr(k,20,4);assert pn==n
 out=[]
 for i in range(n):
  ix=u16(k,o+2*i);assert ix<vn;v=b[vo+ix*48:vo+(ix+1)*48]
  out.append((v[:12]+v[20:40],v[12:16]+k[po+i*4:po+i*4+4]+v[40:48]))
 return out
def indices(k):
 n,o=arr(k,12,2);return list(struct.unpack_from('<%dH'%n,k,o))
def tri(k,row):
 ix=indices(k);s=row[4]+(row[1]<<16);return ix[s:s+row[5]]
def validate(k):
 assert k[:4]==b'SKIN'
 for o,s in [(4,2),(12,2),(20,4),(28,48),(36,24)]:arr(k,o,s)
 nv,_=arr(k,4,2);ni,_=arr(k,12,2);ns,_=arr(k,28,48);assert 0<nv<=65535 and ni>0 and ns<=4096
 for p,x in sections(k):
  start=x[4]+(x[1]<<16);assert start<=ni and x[5]<=ni-start and x[2]+x[3]<=nv and x[6]<=75
  ts=tri(k,x);assert all(x[2]<=i<x[2]+x[3] for i in ts)
 return {'lookup_count':nv,'index_count':ni,'sections':ns}
report=[];patched={}
for sex in ['male','female']:
 sb=(w/(sex+'-source.m2')).read_bytes();sk=(w/(sex+'-source.skin')).read_bytes()
 db=(w/(sex+'-target.m2')).read_bytes();dk=(w/(sex+'-target.skin')).read_bytes()
 assert dk==(w/(sex+'-catalog.skin')).read_bytes(), 'MPQ/catalog baseline differs'
 sa,da=verts(sb,sk),verts(db,dk);old=indices(dk);new=list(old);out=bytearray(dk);changed=[];details=[]
 for sg,dg in [(2902,302),(2903,303),(2904,304),(3002,502),(3102,1002)]:
  sp,sx=next((p,x) for p,x in sections(sk) if x[0]==sg)
  dp,dx=next((p,x) for p,x in sections(dk) if x[0]==dg)
  assert dx[5]==0 and sx[5]>0 and sx[5]%3==0
  dest=collections.defaultdict(list)
  for i in range(dx[2],dx[2]+dx[3]):dest[da[i][0]].append(i)
  assert set(dest)=={sa[i][0] for i in range(sx[2],sx[2]+sx[3])}
  for ids in dest.values():assert len({da[i][1] for i in ids})==1,'ambiguous target deformation'
  source=tri(sk,sx);assert len(source)==sx[5] and all(sx[2]<=i<sx[2]+sx[3] for i in source)
  for key in {sa[i][0] for i in source}:
   assert len({sa[i][1] for i in range(sx[2],sx[2]+sx[3]) if sa[i][0]==key})==1,'ambiguous donor deformation'
  mapped=[dest[sa[i][0]][0] for i in source];start=len(new);new+=mapped
  struct.pack_into('<H',out,dp+2,start>>16);struct.pack_into('<HH',out,dp+8,start&65535,len(mapped))
  changed.extend(range(dp+2,dp+4));changed.extend(range(dp+8,dp+12))
  assert [sa[i][0] for i in source]==[da[i][0] for i in mapped], 'triangle positions/normals/UV/winding differ'
  def deg(attrs,ii):return sum(len({attrs[j][0][:12] for j in ii[t:t+3]})<3 for t in range(0,len(ii),3))
  assert deg(sa,source)==deg(da,mapped)
  bn,bo=arr(dk,36,24);assert any(u16(dk,bo+i*24+4)==(dp-arr(dk,28,48)[1])//48 for i in range(bn)), 'no batch'
  details.append({'source':sg,'target':dg,'triangles':len(mapped)//3,'start':start,'high_word':start>>16,'same_triangle_attributes':True,'duplicate_deformation_ambiguity':0})
 while len(out)%4:out.append(0)
 offset=len(out);out.extend(struct.pack('<%dH'%len(new),*new));struct.pack_into('<II',out,12,len(new),offset);changed+=list(range(12,20))
 assert all(a==b or i in changed for i,(a,b) in enumerate(zip(dk,out))), 'unrelated original bytes changed'
 assert indices(out)[:len(old)]==old
 for (_,x),(_,y) in zip(sections(dk),sections(out)):
  if x[5]:assert x==y and tri(dk,x)==tri(out,y)
  elif y[0] not in [302,303,304,502,1002]:assert x==y
 stats=validate(out);patched[sex]=bytes(out);(w/(sex+'-fixed.skin')).write_bytes(out)
 report.append({'sex':sex,'before_sha256':hashlib.sha256(dk).hexdigest(),'after_sha256':hashlib.sha256(out).hexdigest(),'details':details,'validation':stats,'original_drawable_sections_unchanged':True,'M2_unchanged':True})
root=w.parents[2];client=root/'beascendclient/newrebornWOWli20261107beAscend';before=(w/'catalog-before.bin').read_bytes()
assert struct.unpack_from('<3I',before)==(0x4d474145,1,26)
at=12;out=bytearray(before[:12]);replaced=[]
for i in range(26):
 header=before[at:at+128];path=header.split(b'\0')[0].decode();size=u32(before,at+128);blob=before[at+132:at+132+size];at+=132+size
 sex=next((s for s in ['female','male'] if path.lower().replace('\\','/').endswith('/'+s+'/mechagnome'+s+'.m2')),None)
 if sex:
  assert blob==(w/(sex+'-target.skin')).read_bytes();blob=patched[sex];replaced.append(path)
 out.extend(header);out.extend(struct.pack('<I',len(blob)));out.extend(blob)
assert at==len(before) and len(replaced)==2
(w/'EsteriaAppearanceGeometry.fixed.bin').write_bytes(out)
(w/'validation.json').write_text(json.dumps({'skins':report,'catalog':{'rows':26,'replaced':replaced,'other_24_rows_byte_identical':True,'before_sha256':hashlib.sha256(before).hexdigest(),'after_sha256':hashlib.sha256(out).hexdigest()}},indent=2),'utf8')
print(json.dumps(report,indent=2));print('PASS: triangles restored; original vertices, deformation, UVs, batches and other catalog rows preserved')

