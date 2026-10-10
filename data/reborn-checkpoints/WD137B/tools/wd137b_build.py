from pathlib import Path
import json,struct,hashlib,datetime,zipfile,shutil
from wd19_common import dbc
from wd9a_storm import Archive
import pympq
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');C=R/'beascendclient/newrebornWOWli20261008beAscend';D=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261008Ascend';S=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
A=Path(Path('wd137_path.txt').read_text().strip())
P=R/'000Ascendupdate/000Ascendupdate20261008'/('codexfix_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'_阶段WD137B_瓶中之灵移动施法客户端修正');P.mkdir();Path('wd137b_path.txt').write_text(str(P),encoding='utf8')
def put(n,b):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b if isinstance(b,bytes) else b.encode('utf8'))
def sha(b):return hashlib.sha256(b).hexdigest()
za=C/'Data/patch-ZA.mpq';xa=C/'Data/Patch-XA.mpq'
a=Archive(za);names=[x for x in a.read('(listfile)').decode().splitlines() if not x.startswith('(')];content={n:a.read(n) for n in names};a.close()
key=next(n for n in names if n.lower()=='dbfilesclient\\spell.dbc');before=content[key]
a=Archive(xa);xb=a.read('DBFilesClient\\Spell.dbc');a.close()
assert xb==before,'XA and ZA Spell baselines differ; audit precedence before building'
rows,pool=dbc(before);old={i:v.copy() for i,v in rows.items()};sr,sp=dbc((D/'Data/dbc/Spell.dbc').read_bytes())
for i in range(9003460,9003468):
 assert rows[i][31]==15 and sr[i][31]==15 and rows[i][32:34]==[0,0]
 rows[i][31]&=~1
f=len(next(iter(rows.values())));after=struct.pack('<4s4I',b'WDBC',len(rows),f,f*4,len(pool))+b''.join(struct.pack('<'+'I'*f,*v) for v in rows.values())+pool
new,np=dbc(after);diff=[(i,k,v,new[i][k]) for i,r in old.items() for k,v in enumerate(r) if v!=new[i][k]]
assert diff==[(i,31,15,14) for i in range(9003460,9003468)] and np==pool
content[key]=after
put('rollback/patch-ZA.mpq',za.read_bytes());put('rollback/Spell.dbc',before)
put('client_mpq输入_导入现有Patch-XA/DBFilesClient/Spell.dbc',after)
mpq=P/'02_覆盖到客户端根目录/Data/patch-ZA.mpq';mpq.parent.mkdir(parents=True)
stage=P/'checks/mpq_payload';stage.mkdir(parents=True)
for n,b in content.items():
 q=stage/n.replace('\\','/');q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(b)
a=pympq.create_archive(str(mpq),[pympq.MPQ_CREATE_ARCHIVE_V1],max(64,len(content)*2))
for n in content:a.add_file(str(stage/n.replace('\\','/')),n,[pympq.MPQ_FILE_COMPRESS],[pympq.MPQ_COMPRESSION_ZLIB])
a.close();a=Archive(mpq)
for n,b in content.items():assert a.read(n)==b
a.close()
# Check installed source against WD137A, without overwriting it.
scope={}
for rel in ['src/server/game/Spells/Spell.cpp','src/server/game/Spells/SpellInfo.cpp','modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewing137.inc']:
 live=(S/rel).read_bytes();expected=(A/'01_覆盖到源代码根目录'/rel).read_bytes();assert live==expected,rel;scope[rel]=sha(live)
s=(S/'src/server/game/Spells/Spell.cpp').read_text(encoding='utf-8-sig')
assert s.count('!RebornWD96CanCastWhileMoving(m_caster,m_spellInfo)')==2
assert 'mixer->HasAura(9003957,mixer->GetGUID())' in s
assert all(sr[i][31]&1 for i in range(9003460,9003468))
report={'client_before':sha(before),'client_after':sha(after),'server_spell':sha((D/'Data/dbc/Spell.dbc').read_bytes()),'changed_fields':diff,'all_other_records_and_string_pool_unchanged':True,'mpq_files_read_back':len(content),'installed_source_equals_137A':scope,'runtime_test':'pending; client cancellation cause inferred from flags and previous WD96 mechanism, no packet capture'}
put('checks/verification.json',json.dumps(report,ensure_ascii=False,indent=2))
put('checks/source_baseline.txt','\n'.join(scope))
shutil.copy2(__file__,P/'checks/build_script.py')
print(P);print(json.dumps(report,ensure_ascii=False))
