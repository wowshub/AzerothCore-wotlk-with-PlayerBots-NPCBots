from pathlib import Path
import shutil,re,json,struct,hashlib
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd116_path.txt').read_text(encoding='utf8'));B=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip());V=Path(Path('wd115_path.txt').read_text(encoding='utf8'))
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
 if (V/sub).exists():shutil.copytree(V/sub,P/sub,dirs_exist_ok=True)
# Preserve the actual tooltip/navigation fixes without overwriting the just-integrated allocation.
C=R/'beascendclient/newrebornWOWli20260929beAscend'
for rel in [ADD+'NumericTooltip.lua','Interface/AddOns/RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua']:
 if (C/rel).exists() and (P/CF/rel).exists():shutil.copy2(C/rel,P/CF/rel)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def edit(rel,fn):
 old=(P/rel).read_bytes();put('rollback_WD115/'+rel,old);put(rel,fn(old.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[68]','AEIds[69]').replace('index<68','index<69').replace('index==68','index==69').replace('i<68','i<69').replace('mask>>77','mask>>78').replace('AEMask(1)<<77','AEMask(1)<<78')
 s=s.replace('31118,12264};','31118,12264,6042};').replace('+AERank(mask,67);','+AERank(mask,67)+AERank(mask,68);')
 s=s.replace('-AERank(mask,67)<9','-AERank(mask,67)-AERank(mask,68)<9').replace('|| AERank(mask,67))','|| AERank(mask,67) || AERank(mask,68))')
 anchor='    bool wanted[8]=';assert s.count(anchor)==1
 s=s.replace(anchor,'''    // WD116: active saved Class ownership. Cancel the running aura when ownership ends.
    if(!AERank(mask,68))
    {
        p->RemoveAurasDueToSpell(9003855,p->GetGUID());
        if(p->HasSpell(9003855)) p->removeSpell(9003855,3,false);
    }
    else if(!p->HasSpell(9003855)) p->learnSpell(9003855);
    bool wanted[8]=''')
 return s.replace('for(uint32 spell:{9003853u,','for(uint32 spell:{9003855u,9003856u,9003853u,')
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
def talents(s):
 return s.replace('AEIds[68]','AEIds[69]').replace('i<68','i<69').replace('-AERank(s->aeMasks[slot],67);','-AERank(s->aeMasks[slot],67)-AERank(s->aeMasks[slot],68);').replace('n->id==12264))','n->id==12264 || n->id==6042))').replace('n->id==31118) level=10','(n->id==31118 || n->id==6042)) level=10')
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talents)
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',lambda s:s.replace('{6042,3,0,1,1,0,9,0,0,false,','{6042,3,0,1,1,0,9,0,0,true,'))
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:s.replace('return spell==9003853','return spell==9003855 || spell==9003856 || spell==9003853'))
def ui(s):
 s=s.replace('[12264]=67}','[12264]=67,[6042]=68}').replace('[12264]=1}','[12264]=1,[6042]=1}').replace('MaskFits(mask,77)','MaskFits(mask,78)').replace('i<=67','i<=68')
 s=s.replace('-rank(12264)<9','-rank(12264)-rank(6042)<9').replace('-M.AERank(12264)>=9','-M.AERank(12264)-M.AERank(6042)>=9')
 s=s.replace('rank(12264)>0) and','rank(12264)>0 or rank(6042)>0) and').replace('or id==12264 then','or id==12264 or id==6042 then')
 # AESpent's sum is authored independently from the node map.
 s=s.replace('+M.AERank(12264,mask)','+M.AERank(12264,mask)+M.AERank(6042,mask)')
 detail='''details[6042]={zh="沃金守望",en="Vol'jin's Vigil",level=10,early="先投9 AE",kind="通用主动 / Class active",effects={{"受到的伤害降低25%；每秒恢复最大生命值的2%，持续10秒。冷却2分钟。","Damage taken -25%; restore 2% of maximum health each second for 10 sec. 2 min cooldown."}},limit={"仅自身；恢复量受实际治疗修正影响；不是免疫。灵魂行者增强尚未开放。","Self only; actual healing follows healing modifiers, not immunity. Spirit Walker is not yet enabled."},path={"9点基础AE后花1 AE；保存并激活生效。","Nine foundation AE, then one AE; save and activate."}}
'''
 return s.replace('local function Pair(',detail+'local function Pair(')
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',77)',',78)'))
edit(CF+ADD+'Progress.lua',lambda s:s.replace('RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [6042]={name="沃金守望",spells={9003855}},'))
sql=(B/'server_SQL/01_CHARACTERS_WD114A_必须执行.sql').read_text(encoding='utf8').replace('wd114_schema','wd116_schema').replace('WD114A','WD116A')
sql=sql.replace('31118,12264)','31118,12264,6042)').replace('31118,12264,4004','31118,12264,6042,4004')
sql=sql.replace(' DECLARE r67 INT DEFAULT 0;',' DECLARE r67 INT DEFAULT 0;\n DECLARE r68 INT DEFAULT 0;').replace(str(2**77-1),str(2**78-1))
sql=sql.replace(f'SET r67=MOD(FLOOR(p_mask/{2**76}),2);',f'SET r67=MOD(FLOOR(p_mask/{2**76}),2);SET r68=MOD(FLOOR(p_mask/{2**77}),2);')
sql=sql.replace('r66+r67>v_ae','r66+r67+r68>v_ae').replace('OR r67<>0)','OR r67<>0 OR r68<>0)')
sql=sql.replace(f'WHEN 12264 THEN node_rank*{2**76} END',f'WHEN 12264 THEN node_rank*{2**76} WHEN 6042 THEN node_rank*{2**77} END')
sql=sql.replace(f'OR r67<MOD(FLOOR(v_saved/{2**76}),2)',f'OR r67<MOD(FLOOR(v_saved/{2**76}),2) OR r68<MOD(FLOOR(v_saved/{2**77}),2)')
sql=sql.replace(' IF r67>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,12264,r67);END IF;',' IF r67>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,12264,r67);END IF;\n IF r68>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,6042,r68);END IF;')
put('server_SQL/01_CHARACTERS_WD116A_必须执行.sql',sql)
(P/'server_SQL/01_CHARACTERS_WD114A_必须执行.sql').unlink()
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
data=(C/(ADD+'Data.lua')).read_text(encoding='utf-8-sig');node=next(x for x in data.split('{["ID"]=')[1:] if x.startswith('6042,'));print('NODE',node[:1100])
icon=re.search(r'\["Icon"\]="([^"]+)"',node).group(1).replace('\\\\','\\');file=C/(icon.replace('\\','/')+'.blp');assert file.exists();put(CF+icon.replace('\\','/')+'.blp',file.read_bytes())
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(P/prefix/'Spell.dbc').read_bytes();put('rollback_WD115/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw);oldpool=pool
 for sid in [9003855,9003856]:assert sid not in rows
 r=rows[22812].copy();r[0]=9003855;r[29]=120000;r[30]=0;r[38]=r[39]=10;r[40]=1;r[208:212]=[0]*4
 # Caster-only defensive aura. Native 23 triggers native 136 once per second, matching official 503598/681004.
 r[4:12]=[16,1024,4,0,0,0,0,0];r[71:74]=[6,6,0];r[80:83]=[(-26)&0xffffffff,0,0];r[95:98]=[87,23,0];r[98:101]=[0,1000,0];r[110:113]=[127,0,0];r[116:119]=[0,9003856,0];r[133]=910117
 r[86:89]=[1,1,0];r[89:92]=[0,0,0];r[41:46]=[0]*5;r[46]=1
 rows[r[0]]=r
 h=r.copy();h[0]=9003856;h[4:12]=[0x80,0,0,0,0,0,0,0];h[29]=0;h[40]=0;h[71:74]=[136,0,0];h[80:83]=[1,0,0];h[95:101]=[0]*6;h[110:113]=[0]*3;h[116:119]=[0]*3;h[131:133]=[0,0];rows[h[0]]=h
 for sid in [9003855,9003856]:
  desc='受到的伤害降低25%，每秒恢复最大生命值的2%，持续10秒。冷却2分钟。 / Damage taken -25%; heal 2% of maximum health each second for 10 sec. 2 min cooldown.' if sid==9003855 else ''
  for start,text in [(136,"沃金守望 / Vol'jin's Vigil"),(153,''),(170,desc),(187,desc)]:
   off=len(pool);pool+=text.encode()+b'\0';rows[sid][start:start+16]=[off]*16
 for row in rows.values():
  for start in [136,153,170,187]:
   assert all(off<len(pool) and pool.find(b'\0',off)>=0 for off in row[start:start+16])
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(P/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD115/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw)
 assert not any(r[2] in [9003855,9003856] for r in rows.values());r=next(r[:] for r in rows.values() if r[2]==9003853);r[0]=max(rows)+1;r[2]=9003855;rows[r[0]]=r;put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(P/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD115/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw);assert 910117 not in rows;rows[910117]=[910117,len(pool)];pool+=icon.encode()+b'\0';put(prefix+'/SpellIcon.dbc',pack(rows,pool))
print('WD116 candidate built. SQL/Lua/DBC verification pending.')
