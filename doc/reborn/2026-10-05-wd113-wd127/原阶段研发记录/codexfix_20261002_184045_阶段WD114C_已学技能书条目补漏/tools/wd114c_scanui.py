from pathlib import Path
from wd9a_storm import Archive
C=Path('D:/000rebornWOW/000RebornWOWHighForkPRO/beascendclient/newrebornWOWli20260929beAscend')
out=Path('D:/000rebornWOW/wd114c_ui');out.mkdir(exist_ok=True)
for p in (C/'Data').rglob('*.mpq'):
 if 'cache' in str(p).lower():continue
 try:
  a=Archive(p)
  try:
   raw=a.read('Interface\\FrameXML\\SpellBookFrame.lua')
   if raw:(out/(p.name+'.lua')).write_bytes(raw);print(p, len(raw),flush=True)
  finally:a.close()
 except Exception as e:print(p.name,type(e).__name__,flush=True)
