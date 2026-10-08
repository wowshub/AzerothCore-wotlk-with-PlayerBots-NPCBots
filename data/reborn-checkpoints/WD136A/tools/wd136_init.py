from pathlib import Path
import shutil,json,hashlib,sys
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');S=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
C=R/'beascendclient/newrebornWOWli20261007beAscend';D=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261007Ascend/Data/dbc'
P=Path(Path('D:/000rebornWOW/wd136_path.txt').read_text().strip());B=Path(Path('D:/000rebornWOW/wd135_path.txt').read_text().strip())
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
def put(n,data):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(data if isinstance(data,bytes) else data.encode('utf-8'))
def rep(s,a,b):
 assert s.count(a)==1,(a[:130],s.count(a));return s.replace(a,b)
def edit(n,fn):
 raw=(P/n).read_bytes();backup=P/'rollback_WD135UI'/n
 if not backup.exists():put('rollback_WD135UI/'+n,raw)
 put(n,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
if __name__=='__main__':
 evidence=[]
 for folder,live in [(SF,S),(CF,C)]:
  for f in (B/folder).rglob('*'):
   if f.is_file():
    rel=f.relative_to(B/folder);actual=live/rel;raw=actual.read_bytes();put(folder+rel.as_posix(),raw)
    evidence.append({'path':str(actual),'sha256':hashlib.sha256(raw).hexdigest(),'matches_WD135':raw==f.read_bytes()})
 # Preserve accepted summon-bar changes in the cumulative package too.
 rel='Interface/AddOns/DragonUI/modules/actionbars/witchdoctorbar.lua';put(CF+rel,(C/rel).read_bytes())
 for rel in ['src/server/game/Spells/Spell.h','src/server/game/Spells/Spell.cpp','src/server/game/Spells/SpellEffects.cpp','src/server/game/Spells/Auras/SpellAuras.h','src/server/game/Spells/Auras/SpellAuraEffects.cpp']:
  put(SF+rel,(S/rel).read_bytes())
 shutil.copytree(B/'server_SQL',P/'server_SQL',dirs_exist_ok=True)
 sys.path.insert(0,str(Path(Path('D:/000rebornWOW/wd128_path.txt').read_text().strip())/'tools'));from wd19_common import Archive,dbc
 archives=[Archive(C/'Data'/n) for n in ['Patch-XA.mpq','patch-ZA.mpq']]
 audit={}
 for name in ['Spell.dbc','SpellIcon.dbc','SkillLineAbility.dbc','CreatureDisplayInfo.dbc']:
  sources=[]
  for a in archives:
   try: raw=a.read('DBFilesClient\\'+name)
   except Exception:continue
   if raw: sources.append(raw)
  assert sources,name
  # Spell ZA contains the accepted icon and LIGHT8B chain; preserve its complete rows.
  raw=sources[-1];sr,sp=dbc(raw)
  assert name!='Spell.dbc' or 9003953 in sr
  put('client_mpq输入_导入现有Patch-XA/DBFilesClient/'+name,raw)
  put('03_覆盖到服务端根目录/Data/dbc/'+name,(D/name).read_bytes())
  audit[name]=[hashlib.sha256(v).hexdigest() for v in sources]
 for a in archives:a.close()
 put('research/baseline_sources.json',json.dumps({'files':evidence,'client_archive_order_XA_ZA':audit},ensure_ascii=False,indent=2))
 print('Cumulative working copies prepared; live source, client and server unchanged.')
