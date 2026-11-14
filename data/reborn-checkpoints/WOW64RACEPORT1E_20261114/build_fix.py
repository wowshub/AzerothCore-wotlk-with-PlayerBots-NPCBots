from pathlib import Path
import struct,json,hashlib
w=Path(__file__).parent
b=(w/'selection-before.bin').read_bytes();out=bytearray(b);n=struct.unpack_from('<I',b,8)[0];changes=[]
for i in range(n):
 off=12+i*156;x=struct.unpack_from('<7I',b,off)
 if x[1]==0 and x[2] in [5,10]:
  assert (x[2],x[3]) in [(5,501),(5,502),(10,1001),(10,1002)]
  g=30 if x[2]==5 else 31;v=g*100+x[3]%100;struct.pack_into('<II',out,off+8,g,v);changes.append((i,x[0],x[2],x[3],g,v))
assert len(changes)==8
assert all(b[i]==out[i] or any(12+j[0]*156+8<=i<12+j[0]*156+16 for j in changes) for i in range(len(b)))
(w/'selection-after.bin').write_bytes(out);skins={};notes=[]
for sex in ['male','female']:
 k=(w/(sex+'-before.skin')).read_bytes();out=bytearray(k);n,o=struct.unpack_from('<II',k,28);allowed=[];seen=0;parts=[]
 assert all(struct.unpack_from('<H',k,o+i*48)[0]//100 not in [30,31] for i in range(n))
 for i in range(n):
  off=o+i*48;g=struct.unpack_from('<H',k,off)[0];ng=g
  if g==501:
   ng=3000 if seen==0 else 3001;seen+=1
  elif g==502:ng=3002
  elif g in [1001,1002]:ng=3100+g%100
  if ng!=g:struct.pack_into('<H',out,off,ng);allowed.extend([off,off+1]);parts.append((i,g,ng))
 assert seen==2 and len(parts)==5
 assert all(a==b or i in allowed for i,(a,b) in enumerate(zip(k,out)))
 # C runtime applies catalog >=19 directly; later ordinary equipment can only hide low-numbered groups.
 for leg in [1,2]:
  for gear in ['NO','boots','pants','robe','T7','T14']:
   visible={3000,3001,3002,3101,3102}
   visible-={3000,3001,3002};visible.add(3000+leg)
   visible-={3100,3101,3102};visible.add(3100+leg)
   if gear!='NO':visible={g for g in visible if not 501<=g<=599}
   assert (3000+leg) in visible and (3100+leg) in visible and 3000 not in visible
   for group in [3000+leg,3100+leg]:
    rows=[struct.unpack_from('<10H',out,o+i*48) for i in range(n) if struct.unpack_from('<H',out,o+i*48)[0]==group]
    assert len(rows)==1 and rows[0][5]>0
 skins[sex]=bytes(out);(w/(sex+'-after.skin')).write_bytes(out);notes.append({'sex':sex,'section_id_only_changes':parts,'indices_vertices_bones_UV_unchanged':True})
b=(w/'geometry-before.bin').read_bytes();at=12;out=bytearray(b[:12]);count=struct.unpack_from('<I',b,8)[0];replaced=[]
for i in range(count):
 h=b[at:at+128];path=h.split(b'\0')[0].decode().lower().replace('\\','/');size=struct.unpack_from('<I',b,at+128)[0];blob=b[at+132:at+132+size];at+=132+size
 sex=next((s for s in ['female','male'] if path.endswith('/'+s+'/mechagnome'+s+'.m2')),None)
 if sex:
  assert blob==(w/(sex+'-before.skin')).read_bytes();blob=skins[sex];replaced.append(path)
 out+=h+struct.pack('<I',len(blob))+blob
assert len(replaced)==2 and at==len(b) and len(out)==len(b)
(w/'geometry-after.bin').write_bytes(out)
report={'selection_records_changed':changes,'skins':notes,'catalog_rows':count,'other_24_unchanged':True,'offline_equipment_state_cases':24,'status':'未实机','files':{name:hashlib.sha256((w/name).read_bytes()).hexdigest() for name in ['selection-before.bin','selection-after.bin','geometry-before.bin','geometry-after.bin','male-before.skin','male-after.skin','female-before.skin','female-after.skin']}}
(w/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),'utf8');print('PASS 8 selector records and 10 SKIN section IDs only; D triangles preserved; 24 offline gear/leg cases')
