from pathlib import Path
import json,struct,shutil,hashlib
from wd9a_storm import Archive
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd115_path.txt').read_text(encoding='utf8'))
C=R/'beascendclient/newrebornWOWli20260929beAscend';S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend';B=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip())
def put(rel,b):
 p=P/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b if isinstance(b,bytes) else b.encode('utf8'))
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
donor=Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/Content/CharacterAdvancementData.json')
data=json.loads(donor.read_text(encoding='utf-8-sig'))
selected=[x for x in data if set(x.get('Spells',[])) & {503748,504888,602220}]
put('research/advancement.json',json.dumps(selected,ensure_ascii=False,indent=2));print('DONOR',selected)
rel='01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc'
src=(B/rel).read_bytes();assert src==(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_bytes()
s=src.decode('utf-8-sig');old='        uint32 rank=AERank(mask,49+family);';assert s.count(old)==1
s=s.replace(old,old+'\n        // WD115A: both progression nodes reference the same upstream rank family.\n        if(family==0) rank=std::max(rank,AERank(mask,67));')
s=s.replace('    // WD104A: only the active saved Brewing ranks own these six legacy spells.','    // WD115A: retire the duplicate Class spell before granting the shared highest rank.\n    p->RemoveAurasDueToSpell(9003854,p->GetGUID());\n    if(p->HasSpell(9003854)) p->removeSpell(9003854,3,false);\n    // Saved Brewing ranks and the Class rank share one Potent Mixes family.')
old='            if(!p->HasSpell(spell)) p->learnSpell(spell);\n        }\n    }\n    // WD105A:'
assert s.count(old)==1;s=s.replace(old,'            if(!p->HasSpell(spell)) p->learnSpell(spell);\n            if(family==0 && !p->HasAura(spell)) p->CastSpell(p,spell,true);\n        }\n    }\n    // WD105A:')
old='    for(uint32 i=0;i<2;++i)\n    {\n        uint32 const id=9003853+i;';assert s.count(old)==1
s=s.replace(old,'    for(uint32 i=0;i<1;++i)\n    {\n        uint32 const id=9003853+i;').replace('            if(i==1 && !p->HasAura(id)) p->CastSpell(p,id,true);','')
put(rel,s);put('rollback/'+rel,src)
rel='02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/Allocation.lua'
src=(C/'Interface/AddOns/RebornWitchDoctorTalents/Allocation.lua').read_bytes();s=src.decode('utf-8-sig')
assert 'details[12264]' in s
s=s.replace('zh="强效调配",en="Potent Mixes"','zh="强效混合",en="Potent Mixes"')
s=s.replace('通用树同名节点仍未开放。','与通用强效混合共用技能，只取较高等级；重复投入不增加收益。')
s=s.replace('The Class-tree duplicate remains unavailable.','Shared with Class Potent Mixes; highest rank only. Duplicate investment adds no benefit.')
s=s.replace('不直接削减已有仇恨，不降低普通近战白字仇恨；保存激活后生效。','与酿造强效混合共用技能，只取较高等级；重复投入不增加收益。保存激活后生效。')
s=s.replace('Does not erase existing threat or reduce white melee threat; active saved build only.','Shared with Brewing Potent Mixes; highest rank only, no duplicate benefit; active saved build only.')
put(rel,s);put('rollback/'+rel,src)
icons={910115:'Interface\\AddOns\\RebornWitchDoctorTalents\\Icons\\7e06e90aea7e069e',910116:'Interface\\AddOns\\RebornWitchDoctorTalents\\Icons\\36a212983bcf60a7'}
a=Archive(C/'Data/patch-XA.MPQ');clientSpell=a.read('DBFilesClient\\Spell.dbc');clientIcon=a.read('DBFilesClient\\SpellIcon.dbc');a.close()
records=[]
for label,raw,prefix in [('client',clientSpell,'client_mpq输入_导入现有Patch-XA/DBFilesClient'),('server',(S/'Data/dbc/Spell.dbc').read_bytes(),'03_覆盖到服务端根目录/Data/dbc')]:
 rows,pool=dbc(raw);original={k:v[:] for k,v in rows.items()};oldpool=pool
 rows[9003853][133]=910115
 for sid in [9003620,9003621,9003854]:
  rows[sid][133]=910116
  off=len(pool);pool+='强效混合 / Potent Mixes'.encode()+b'\0';rows[sid][136:152]=[off]*16
 changed=[k for k in rows if rows[k]!=original[k]];assert set(changed)=={9003853,9003620,9003621,9003854}
 out=pack(rows,pool);assert dbc(out)[0]==rows and pool.startswith(oldpool)
 for row in rows.values():
  for st in [136,153,170,187]:
   for off in row[st:st+16]:assert off<len(pool) and pool.find(b'\0',off)>=0
 put(prefix+'/Spell.dbc',out);put('rollback/'+prefix+'/Spell.dbc',raw)
 records.append({'side':label,'before':hashlib.sha256(raw).hexdigest(),'after':hashlib.sha256(out).hexdigest(),'changed':changed})
rows,pool=dbc(clientIcon)
for sid,path in icons.items():
 assert sid not in rows;rows[sid]=[sid,len(pool)];pool+=path.encode()+b'\0'
put('client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc',pack(rows,pool));put('rollback/client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc',clientIcon)
for path in icons.values():
 file=C/(path.replace('\\','/')+'.blp');assert file.exists();put('02_覆盖到客户端根目录/'+path.replace('\\','/')+'.blp',file.read_bytes())
put('checks/dbc.json',json.dumps(records,indent=2));print('Built isolated overwrite files; only selected rows changed.')
