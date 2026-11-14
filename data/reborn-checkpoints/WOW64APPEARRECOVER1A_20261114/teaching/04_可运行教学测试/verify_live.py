from pathlib import Path
import hashlib,json
r=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO')
c=r/'beascendclient/newrebornWOWli20261107beAscend'
a=r/'000Ascendupdate/000Ascendupdate20261111/codexwork_WOW64CREATORAUDIT1A/audit.py'
ns={'__file__':str(a)}
exec(a.read_text('utf8').split('clients=')[0],ns)
report={'active_disable_flag':(c/'EsteriaOff.txt').exists(),'files':[]}
def add(name,b):report['files'].append({'file':name,'size':len(b),'sha256':hashlib.sha256(b).hexdigest()})
for name in ('WowClient64.exe','EsteriaAppearanceGeometry.bin'):add(name,(c/name).read_bytes())
for archive,entries in [('Patch-YB.mpq',[r'Esteria\RebornNativeMechagnome.bin',r'Interface\GlueXML\CharacterSelect.lua']),('Patch-YI.mpq',[r'custom\mechagnome\native\male\mechagnomemale00.skin',r'custom\mechagnome\native\female\mechagnomefemale00.skin'])]:
 m=ns['StormReader'](str(c/'Data'/archive))
 try:
  for entry in entries:
   b=m.read_file(entry);assert b is not None,entry;add(archive+':'+entry,b)
 finally:m.close()
print(json.dumps(report,ensure_ascii=False,indent=2))
