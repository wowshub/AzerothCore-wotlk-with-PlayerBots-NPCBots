exec((__import__('pathlib').Path(__file__).parent/'inspect_inputs.py').read_text('utf8').split("for n in ['Patch-YB.mpq'")[0])
import shutil
bwork=w.parent/'codexwork_WOW64RACEPORT1B'
j=json.loads((w/'preparation.json').read_text('utf8'));opt={};labels=j['labels'];offsets={0x28:0,0x2c:1,0x34:2,0x24:3,0x30:4}
fields=[0,1,2,3,1,2,2,4,3,0,0,4]
remap={**{2900+i:300+i for i in range(1,5)},**{3000+i:500+i for i in range(1,3)},**{3100+i:1000+i for i in range(1,3)},**{2400+i:1600+i for i in range(5)},1603:1803}
records=[];allgeos=[]
m=R(str(c/'Data/Patch-YI.mpq'))
for gender,sex in enumerate(['male','female']):
 p=j['sexes'][sex]['profile'];co={l:max(1,len(p['choices'][l])) for l in labels};factors=[1,1,1,1,co['Face'],co['Hair Style'],co['Hair Style']*co['Arm Upgrade'],1,co['Hair Color'],co['Skin Color'],co['Skin Color']*co['Paint'],co['Modification']];ops=list(zip(fields,[co[l] for l in labels],factors));opt[sex]=ops
 base='custom\\mechagnome\\native\\%s\\mechagnome%s'%(sex,sex);orig=m.read_file(base+'.m2');skin=m.read_file(base+'00.skin');n,o=struct.unpack_from('<II',skin,28);geos=set(struct.unpack_from('<H',skin,o+i*48)[0] for i in range(n));allgeos.append(sorted(geos))
 # Restore the correct shared type-5 material slots from the exact pre-B native model.
 restored=(bwork/'backup_models'/Path(base.replace('\\','/')+'.m2')).read_bytes();assert len(restored)<=len(orig)
 out=w/'model_patch'/Path(base.replace('\\','/')+'.m2');out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(restored)
 bak=w/'backup_models'/out.relative_to(w/'model_patch');bak.parent.mkdir(parents=True,exist_ok=True);bak.write_bytes(orig)
 for idx,label in enumerate(labels):
  choices=p['choices'][label];mapping=[]
  for choice in choices:mapping.append([remap.get(g,g) for g in p['geometry'].get(str(choice['ID']),[])])
  groups={g//100 for ls in mapping for g in ls if g!=0}
  for value,gs in enumerate(mapping):
   for group in groups:
    matches=[g for g in gs if g//100==group];assert len(matches)<=1
    target=matches[0] if matches else group*100
    assert target%100==0 or target in geos,(sex,label,target)
    records.append(struct.pack('<7I128s',gender,0,group,target,(value<<16)|idx,0xffffffff,0xffffffff,b''))
# Reuse actual installed material catalog, convert predicates to EHM1 selector indices.
blob=(c/'EsteriaAppearanceMaterials.bin').read_bytes();magic,ver,count=struct.unpack_from('<3I',blob);assert magic==0x544d4145 and len(blob)==12+count*188
for i in range(count):
 row=struct.unpack_from('<15I128s',blob,12+i*188)
 if row[0]!=47:continue
 sex=row[1];ops=opt[['male','female'][sex]];pred=[]
 for k in range(3):
  offset,factor,n,value=row[3+k*4:7+k*4];field=offsets[offset];idx=ops.index((field,n,factor));pred.append((value<<16)|idx)
 records.append(struct.pack('<7I128s',sex,1,row[2],0,*pred,row[15]))
assert sum(struct.unpack_from('<I',v,4)[0]==1 for v in records)==792
out=w/'client_patch/Esteria/RebornNativeMechagnome.bin';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(struct.pack('<3I',0x314d4845,1,len(records))+b''.join(records))
# Earthen: install only eye/eyesight records, leave body/gear handling on its current native tables.
blob=(c/'EsteriaEarthen.bin').read_bytes();count=struct.unpack_from('<I',blob,8)[0];er=[]
for i in range(count):
 row=list(struct.unpack_from('<7I128s',blob,12+i*156))
 if row[1]!=1 or row[2]!=5:continue
 for k in [4,5,6]:
  if row[k]==0xffffffff:continue
  idx=row[k]&65535;assert idx in [6,7];row[k]=(row[k]&0xffff0000)|(idx-1)
 er.append(struct.pack('<7I128s',*row))
(w/'client_patch/Esteria/RebornNativeEarthenEyes.bin').write_bytes(struct.pack('<3I',0x314d4845,1,len(er))+b''.join(er))
m.close();(w/'options.json').write_text(json.dumps({'options':opt,'labels':labels,'earthen_options':[[0,14,1],[1,10,1],[2,11,1],[3,14,1],[4,11,1],[3,14,14],[1,4,10]],'earthen_labels':['Skin Color','Face','Hair Style','Hair Color','Beard Style','Eye Color','Eyesight'],'mecha_records':len(records),'earthen_records':len(er)},indent=2),'utf8');print('Catalogs',len(records),len(er),'restored native type5 slots; no geometry/model version replacement')
