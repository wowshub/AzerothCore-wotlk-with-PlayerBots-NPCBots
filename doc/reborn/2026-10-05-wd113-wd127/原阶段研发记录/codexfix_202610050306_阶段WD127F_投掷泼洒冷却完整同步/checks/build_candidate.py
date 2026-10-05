from pathlib import Path
import shutil, struct, re, json, hashlib, datetime
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
D=R/'000Ascendupdate'
B=D/'000Ascendupdate20261004/codexfix_202610042116_阶段WD127B_AEIds编译修正'
E=D/'000Ascendupdate20261005/codexfix_202610050149_阶段WD127E_冷却整型编译修正'
P=D/('000Ascendupdate20261005/codexfix_'+datetime.datetime.now().strftime('%Y%m%d%H%M')+'_阶段WD127F_投掷泼洒冷却完整同步')
P.mkdir(exist_ok=True)
Path('D:/000rebornWOW/wd127f_path.txt').write_text(str(P),encoding='utf-8')
for name in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录','03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 if (B/name).exists():shutil.copytree(B/name,P/name,dirs_exist_ok=True)
for name in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录']:
 shutil.copytree(E/name,P/name,dirs_exist_ok=True)
source=P/'01_覆盖到源代码根目录'
def edit(path,old,new):
 s=path.read_text(encoding='utf-8-sig');assert s.count(old)==1,(path,old[:80],s.count(old))
 rollback=P/'rollback_本次修改前'/path.relative_to(P);rollback.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,rollback)
 path.write_bytes(s.replace(old,new).encode('utf-8'))
spell=source/'src/server/game/Spells/Spell.cpp'
edit(spell,'bool exactCooldown = false;','''// WD127F: both potion families need the same post-GO correction.
            // Use the cooldown already stored by Player; do not subtract twice.
            bool exactCooldown = ((m_spellInfo->Id >= 9003870 && m_spellInfo->Id <= 9003876) ||
                                  (m_spellInfo->Id >= 9003890 && m_spellInfo->Id <= 9003896)) &&
                                 player->HasAura(9003897);''')
talents=source/'modules/mod-reborn-witchdoctor/src/RebornWitchDoctorTalents.cpp'
edit(talents,'else h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,0,0,std::max(0,cooldown));',
 'else h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,0,0,std::max(0,cooldown));')
lua=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua'
edit(lua,'''elseif (id>=9003870 and id<=9003876 or id>=9003890 and id<=9003896) and side=="Left" and (clean:find("15秒冷却",1,true) or clean:find("15 sec cooldown",1,true)) then
     local seconds=value and value.e and value.e/1000
     local rendered=seconds and clean:gsub("15秒冷却",string.format("%g秒冷却",seconds)):gsub("15 sec cooldown",string.format("%g sec cooldown",seconds)) or clean''',
 '''elseif (id>=9003870 and id<=9003876 or id>=9003890 and id<=9003896) and (clean:find("15秒冷却",1,true) or clean:find("15 sec cooldown",1,true) or clean:find("15 sec Cooldown",1,true)) then
     -- WD127F: native cooldown headings are Right FontStrings; descriptions are Left.
     -- Always rebuild from original text, including when a saved build is changed.
     local seconds=value and value.e and value.e/1000
     local rendered=seconds and clean:gsub("15秒冷却",string.format("%g秒冷却",seconds)):gsub("15 sec cooldown",string.format("%g sec cooldown",seconds)):gsub("15 sec Cooldown",string.format("%g sec Cooldown",seconds)) or (original..(en and " (syncing)" or "（同步中）"))''')
# Do not invent a potion cooldown on the separate mushroom pulse ability.
s=lua.read_text(encoding='utf-8')
old='text=label..value.a.."–"..value.b..string.format("；冷却%g秒 / cooldown %g sec（含自身加成；未计目标增减益及暴击 / self bonuses, before target modifiers and crit）",(value.e or 15000)/1000,(value.e or 15000)/1000)'
new='text=label..value.a.."–"..value.b..(id==9003865 and "" or (value.e and string.format("；冷却%g秒 / cooldown %g sec",value.e/1000,value.e/1000) or "；冷却同步中 / cooldown syncing")).."（含自身加成；未计目标增减益及暴击 / self bonuses, before target modifiers and crit）"'
assert s.count(old)==1;s=s.replace(old,new);lua.write_bytes(s.encode('utf-8'))
proof=[]
fmt=re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"',(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/DataStores/DBCfmt.h').read_text())[1]
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 path=P/prefix/'Spell.dbc';raw=path.read_bytes();magic,n,f,size,ss=struct.unpack_from('<4s4I',raw)
 assert magic==b'WDBC' and f==len(fmt) and len(raw)==20+n*size+ss
 index=next(i for i in range(n) if struct.unpack_from('<I',raw,20+i*size)[0]==9003897)
 off=20+index*size;row=struct.unpack_from('<'+'I'*f,raw,off)
 assert row[74]==0 and row[80]==(-5001 & 0xffffffff) and row[95]==107
 backup=P/'rollback_本次修改前'/path.relative_to(P);backup.parent.mkdir(parents=True,exist_ok=True);backup.write_bytes(raw)
 out=bytearray(raw);struct.pack_into('<i',out,off+80*4,-5000)
 assert out[:off+80*4]==raw[:off+80*4] and out[off+81*4:]==raw[off+81*4:]
 pool=out[20+n*size:]
 for i in range(n):
  values=struct.unpack_from('<'+'I'*f,out,20+i*size)
  for j,t in enumerate(fmt):
   if t=='s':assert values[j]<ss and pool.find(b'\0',values[j])>=0,(i,j)
 path.write_bytes(out);proof.append({'side':prefix,'only_changed':{'spell':9003897,'field':80,'before':-5001,'after':-5000},'rows':n,'sha256':hashlib.sha256(out).hexdigest()})
(P/'checks').mkdir(exist_ok=True);(P/'checks/dbc_validation.json').write_text(json.dumps(proof,indent=2),encoding='utf-8')
for rel in [spell.relative_to(source),talents.relative_to(source)]:
 dest=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'/rel;shutil.copy2(source/rel,dest)
print(P)

