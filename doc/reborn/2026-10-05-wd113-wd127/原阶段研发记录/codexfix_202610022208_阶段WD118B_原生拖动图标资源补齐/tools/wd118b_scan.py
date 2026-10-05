exec(open('wd118b_audit.py',encoding='utf8').read().split("a=Archive(C/'Data/patch-XA.MPQ')")[0])
hits=[];errors=[]
for f in (C/'Data').rglob('*'):
 if f.suffix.lower()!='.mpq':continue
 try:
  a=Archive(f)
  for i,path in icons.items():
   if a.read(path+'.blp'):hits.append([str(f),i,path])
  raw=a.read('Interface\\FrameXML\\SpellBookFrame.lua')
  if raw:
   name=f.parent.name+'_'+f.stem+'_SpellBookFrame.lua';(P/'research'/name).write_bytes(raw);print(name)
  a.close()
 except Exception as e:errors.append([str(f),str(e)])
(P/'research/all_archive_scan.json').write_text(json.dumps(dict(icon_hits=hits,errors=errors),ensure_ascii=False,indent=2),encoding='utf8');print('hits',hits,'errors',errors)
