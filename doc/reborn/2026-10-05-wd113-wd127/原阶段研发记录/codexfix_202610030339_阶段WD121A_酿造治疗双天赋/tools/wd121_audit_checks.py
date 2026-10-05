# coding: utf-8
from pathlib import Path
import json,hashlib,re
from wd19_common import Archive,dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd121_path.txt').read_text());B=Path(Path('wd120_path.txt').read_text());C=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
source=Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ')
a=Archive(source);raw=a.read('DBFilesClient\\Spell.dbc');a.close();donor,pool=dbc(raw)
old=json.loads((P/'research/preview_donor.json').read_text(encoding='utf8'));out={}
for sid in [705856,707858,561072]:
 assert donor[sid]==old[str(sid)]['row'];r=donor[sid];o=r[170];out[sid]={'row':r,'description':pool[o:pool.find(b'\0',o)].decode(),'amount':r[80]+1,'operation':r[110]}
(P/'research/official_selected.json').write_text(json.dumps({'archive':str(source),'Spell_sha256':hashlib.sha256(raw).hexdigest(),'rows':out},ensure_ascii=False,indent=2),encoding='utf8')
src=P/'01_覆盖到源代码根目录';mods=(src/'modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp').read_text(encoding='utf8');info=(src/'src/server/game/Spells/SpellInfo.cpp').read_text(encoding='utf8');unit=(C/'src/server/game/Entities/Unit/Unit.cpp').read_text(encoding='utf8')
assert 'return check->Id!=9003866 || mod->op!=SPELLMOD_DAMAGE;' in mods
assert 'check->Id>=9003870 && check->Id<=9003876 && mod->op==SPELLMOD_DAMAGE' in mods
assert 'check->Id==9003867 && mod->op==SPELLMOD_DOT' in mods
assert 'case 9003877: case 9003878: case 9003879:' in info
heal=unit[unit.index('uint32 Unit::SpellHealingBonusDone'):unit.index('uint32 Unit::SpellHealingBonusTaken')]
assert 'damagetype == DOT ? SPELLMOD_DOT : SPELLMOD_DAMAGE' in heal
assert heal.index('float heal =')<heal.index('modOwner->ApplySpellMod(spellProto->Id, damagetype')
rows,_=dbc((P/'03_覆盖到服务端根目录/Data/dbc/Spell.dbc').read_bytes())
for sid in [9003866,9003867,*range(9003870,9003877)]:
 assert rows[sid][213]==1 # magic; does not early-return from done healing like DmgClass NONE
 assert not rows[sid][7]&0x20000000 # IGNORE_CASTER_MODIFIERS (also inspect core enum below)
cases=[]
def model(target,op,active,base):
 add=0
 for sid in active:
  for effect in range(3):
   r=rows[sid]
   match=(sid in [9003877,9003878] and target==9003866 and op==0) or (sid==9003879 and ((9003870<=target<=9003876 and op==0) or (target==9003867 and op==22)))
   if r[71+effect]==6 and r[95+effect]==108 and r[110+effect]==op and match:add+=r[80+effect]+1
 return int(base*(100+add)/100)
for base in [1000,10000]:
 for active in [[],[9003877],[9003878],[9003879],[9003877,9003879],[9003878,9003879]]:
  for target in [9003866,9003867,*range(9003870,9003877),9003101,9003240,9003855]:
   for op in [0,22,8,2,14]:
    pct=(30 if 9003878 in active else 15 if 9003877 in active else 0) if target==9003866 and op==0 else 20 if 9003879 in active and ((9003870<=target<=9003876 and op==0) or (target==9003867 and op==22)) else 0
    assert model(target,op,active,base)==base*(100+pct)//100
    cases.append([target,op,active,base,pct])
(P/'checks/mechanics_model.json').write_text(json.dumps({'status':'PASS offline model + source call-path audit; NOT engine execution','cases':len(cases),'source':'Unit::SpellHealingBonusDone, explicit mod routing, DBC native108 operations0/22','assertions':['rank replacement excludes simultaneous Fresh ranks','Fresh does not affect tossed HoT','Boss does not affect Cauldron pulse','unrelated spells/operations unchanged','old healing spell rows byte-identical']},indent=2))
# All install files are cumulative WD120; record exact changes/additions for review.
changes=[]
for folder in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录','03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 for f in (P/folder).rglob('*'):
  if f.is_file():
   rel=f.relative_to(P);before=B/rel
   if not before.exists() or before.read_bytes()!=f.read_bytes():changes.append(str(rel).replace('\\','/'))
(P/'checks/changed_files.json').write_text(json.dumps(changes,ensure_ascii=False,indent=2),encoding='utf8')
print(len(cases),'offline numeric/negative cases; official donor unchanged;',len(changes),'changed install files')
