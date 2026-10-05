from pathlib import Path
from wd9a_storm import Archive
from wd19_common import dbc
root=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
a=Archive(root/'beascendclient/newrebornWOWli20260929beAscend/Data/Patch-XA.mpq')
try:
 raw=a.read('DBFilesClient\\Spell.dbc');r,s=dbc(raw)
 for i in [9003850,9003851,9003852,9003853,9003854]:
  x=r.get(i);print(i, 'MISSING' if x is None else (x[136],s[x[136]:s.index(b'\0',x[136])].decode(),list(map(hex,x[4:12]))))
finally:a.close()
for name in ['Patch-XA.mpq','Patch-X.mpq']:
 a=Archive(root/'beascendclient/newrebornWOWli20260929beAscend/Data'/name)
 try:
  for f in ['Interface\\FrameXML\\SpellBookFrame.lua','Interface\\FrameXML\\SpellBookFrame.xml']:
   raw=a.read(f)
   if raw:
    dest=Path('D:/000rebornWOW')/('wd114c_'+name+'_'+f.rsplit('\\',1)[-1]);dest.write_bytes(raw);print(dest)
 finally:a.close()
