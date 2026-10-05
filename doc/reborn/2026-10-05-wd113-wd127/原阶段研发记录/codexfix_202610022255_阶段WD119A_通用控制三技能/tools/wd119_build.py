from pathlib import Path
import shutil,re,json,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd118_path.txt').read_text(encoding='utf8'));P=Path(Path('wd119_path.txt').read_text(encoding='utf8'));C=R/'beascendclient/newrebornWOWli20260929beAscend';CODE=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
# WD118B confirmed: native cursor needs these paths available in the MPQ too.
B118=Path(Path('wd118b_path.txt').read_text(encoding='utf8'))
shutil.copytree(B118/'client_mpq输入_导入现有Patch-XA',P/'client_mpq输入_导入现有Patch-XA',dirs_exist_ok=True)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def edit(rel,fn):
 if not (P/rel).exists():put(rel,(CODE/rel[len(SF):]).read_bytes())
 raw=(P/rel).read_bytes();put('rollback_WD118/'+rel,raw);put(rel,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[71]','AEIds[74]').replace('index<71','index<74').replace('index==71','index==74').replace('i<71','i<74').replace('mask>>81','mask>>84').replace('AEMask(1)<<81','AEMask(1)<<84')
 s=rep(s,'9347,29306};','9347,29306,6031,6525,12525};')
 s=s.replace('if(index==70) return static_cast<uint32>((mask>>80)&1u);','if(index>=70) return static_cast<uint32>((mask>>(index+10))&1u);').replace('index==70?80:','index>=70?index+10:')
 s=s.replace('+AERank(mask,70);','+AERank(mask,70)+AERank(mask,71)+AERank(mask,72)+AERank(mask,73);').replace('-AERank(mask,70)<9','-AERank(mask,70)-AERank(mask,71)-AERank(mask,72)-AERank(mask,73)<9').replace('|| AERank(mask,70))','|| AERank(mask,70) || AERank(mask,71) || AERank(mask,72) || AERank(mask,73))')
 s=rep(s,'    if(AERank(mask,70)', '''    if((AERank(mask,71) || AERank(mask,72) || AERank(mask,73)) && level<26) return false;
    if((AERank(mask,72) || AERank(mask,73)) && !AERank(mask,71)) return false;
    if(AERank(mask,72) && AERank(mask,73)) return false;
    if(AERank(mask,70)''')
 s=s.replace('for(uint32 spell:{9003859u,','for(uint32 spell:{9003861u,9003862u,9003863u,9003859u,')
 s=rep(s,'    // WD118: parent removal', '''    // WD119: remove unowned choices before restoring the active passive.
    uint32 const frogSpells[3]={9003861,9003862,9003863};
    for(uint32 i=0;i<3;++i) if(!AERank(mask,71+i))
    {
        p->RemoveAurasDueToSpell(frogSpells[i],p->GetGUID());
        if(p->HasSpell(frogSpells[i])) p->removeSpell(frogSpells[i],3,false);
    }
    for(uint32 i=0;i<3;++i) if(AERank(mask,71+i))
    {
        if(!p->HasSpell(frogSpells[i])) p->learnSpell(frogSpells[i]);
        if(i && !p->HasAura(frogSpells[i])) p->CastSpell(p,frogSpells[i],true);
    }
    // WD118: parent removal''')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
def talent(s):
 s=s.replace('AEIds[71]','AEIds[74]').replace('i<71','i<74').replace('-AERank(s->aeMasks[slot],70);','-AERank(s->aeMasks[slot],70)-AERank(s->aeMasks[slot],71)-AERank(s->aeMasks[slot],72)-AERank(s->aeMasks[slot],73);')
 s=s.replace('n->id==29306))','n->id==29306 || n->id==6031 || n->id==6525 || n->id==12525))')
 s=rep(s,'    if(s->modern && n->id==29306)', '    if(s->modern && (n->id==6031 || n->id==6525 || n->id==12525)) level=26;\n    if(s->modern && n->id==29306)')
 s=s.replace('bool const allowed=id==9003859','bool const allowed=id==9003861 || id==9003859')
 s=rep(s,'    // Only fixed-range effects:', '''    if(id==9003861)
    {
        int32 cooldown=info->RecoveryTime;
        p->ApplySpellMod(id,SPELLMOD_COOLDOWN,cooldown);
        h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,info->CalcCastTime(p),std::max(0,cooldown),s->revision,s->active);
        return true;
    }
    // Only fixed-range effects:''')
 return s
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talent)
def nodes(s):
 for n in [6031,6525,12525]:
  group=0 if n==6031 else 807855
  s=rep(s,'{%d,3,0,1,1,0,9,0,%d,false,'%(n,group),'{%d,3,26,1,1,0,9,0,%d,true,'%(n,group))
 return s
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',nodes)
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:s.replace('return spell==9003859','return spell==9003861 || spell==9003862 || spell==9003863 || spell==9003859'))
def mechanics(s):
 return rep(s,'        if(mod->spellId==9003857', '''        // Native flat/pct modifiers, exact target; no family-wide fallback.
        if(mod->spellId==9003862) return check->Id!=9003861 || (mod->op!=SPELLMOD_COOLDOWN && mod->op!=SPELLMOD_CASTING_TIME);
        if(mod->spellId==9003863) return check->Id!=9003861 || mod->op!=SPELLMOD_CASTING_TIME;
        if(mod->spellId==9003857''')
edit(SF+SRC+'RebornWitchDoctor.cpp',mechanics)
edit(SF+'src/server/game/Spells/SpellInfo.cpp',lambda s:rep(s,'        case 9003857:', '        case 9003862: case 9003863: // WD119 Amphibimorph only\n        case 9003857:'))
# Preserve actual current core files, including previous Hireek/PvP and playerbot fixes.
edit(SF+'src/server/game/Spells/SpellMgr.cpp',lambda s:rep(s,'    // WD25A: official Hireek', '    // WD119: clamp before native diminishing (8/4/2 seconds), not after it.\n    if (spellproto->Id == 9003861) return 8 * IN_MILLISECONDS;\n\n    // WD25A: official Hireek'))
edit(SF+'src/server/game/Entities/Unit/Unit.cpp',lambda s:rep(s,'uint32 Unit::GetCreatureType() const\n{', '''uint32 Unit::GetCreatureType() const
{
    // WD119: temporary frog category without changing templates or shapeshift state.
    if (HasAura(9003861)) return CREATURE_TYPE_BEAST;'''))
def ui(s):
 s=s.replace('[29306]=70}','[29306]=70,[6031]=71,[6525]=72,[12525]=73}').replace('[29306]=1}','[29306]=1,[6031]=1,[6525]=1,[12525]=1}').replace('MaskFits(mask,81)','MaskFits(mask,84)').replace('i<=70','i<=73').replace('i==70 and 80','i>=70 and (i+10)')
 s=s.replace('-rank(29306)<9','-rank(29306)-rank(6031)-rank(6525)-rank(12525)<9').replace('-M.AERank(29306)>=9','-M.AERank(29306)-M.AERank(6031)-M.AERank(6525)-M.AERank(12525)>=9').replace('or rank(29306)>0) and','or rank(29306)>0 or rank(6031)>0 or rank(6525)>0 or rank(12525)>0) and')
 s=rep(s,' if rank(29306)>0 and', ''' if (rank(6031)>0 or rank(6525)>0 or rank(12525)>0) and M.level<26 then return false,"蛙变术及祝福需要26级" end
 if (rank(6525)>0 or rank(12525)>0) and rank(6031)==0 then return false,"需先学习蛙变术" end
 if rank(6525)>0 and rank(12525)>0 then return false,"贡克与克拉格瓦祝福二选一" end
 if rank(29306)>0 and''')
 s=rep(s,' if id==29306 then', ''' if id==6031 or id==6525 or id==12525 then
  local foundation=M.AERank(29744)+M.AERank(6054)+M.AERank(6047)+M.AERank(7092)+M.AERank(29309)+M.AERank(29301)+M.AERank(7088)+M.AERank(6030)+M.AERank(31118)
  return M.level>=26 and foundation>=9 and (id==6031 or M.AERank(6031)>0) and (id~=6525 or M.AERank(12525)==0) and (id~=12525 or M.AERank(6525)==0)
 end
 if id==29306 then''')
 for n,zh,en,effect,english in [
 (6031,'蛙变术','Amphibimorph','30码内选定区域的敌人变蛙，不能攻击施法，移速降低25%，视为野兽；持续40秒，对玩家最多8秒，受伤解除。基础施法1秒，冷却120秒。','Frog enemies in the target area; pacify/silence, -25% speed, Beast type. 40 sec, up to 8 sec on players; damage breaks. Base cast 1 sec, cooldown 120 sec.'),
 (6525,'贡克祝福',"Gonk's Blessing",'蛙变术冷却缩短60秒，基础施法时间增加0.5秒。','Amphibimorph cooldown -60 sec; base cast time +0.5 sec.'),
 (12525,'克拉格瓦祝福',"Krag'wa's Blessing",'蛙变术变为瞬发；冷却仍为120秒。','Amphibimorph becomes instant; cooldown remains 120 sec.')]:
  detail='details[%d]={zh=%s,en=%s,level=26,early="26；先投9 AE",kind="通用技能 / Class ability",effects={{%s,%s}},limit={"仅激活且已保存方案生效；两种祝福互斥，玩家控制受递减规则约束。","Active saved build; blessings exclusive; native PvP diminishing applies."},path={"9点基础AE后每节点1 AE；祝福需先学习蛙变术。","Nine foundation AE, one AE per node; blessings require Amphibimorph."}}\n'%(n,json.dumps(zh,ensure_ascii=False),json.dumps(en),json.dumps(effect,ensure_ascii=False),json.dumps(english))
  s=rep(s,'local function Pair(',detail+'local function Pair(')
 return s
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',81)',',84)'))
edit(CF+ADD+'Progress.lua',lambda s:s.replace('RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [6031]={name="蛙变术",spells={9003861}},\n [6525]={name="贡克祝福",spells={9003862}},\n [12525]={name="克拉格瓦祝福",spells={9003863}},'))
def numeric(s):
 s=s.replace('allowed[9003859]=true;','allowed[9003861]=true;allowed[9003859]=true;')
 s=rep(s,'    else\n     self.wd114Lines[key]=nil', '''    elseif id==9003861 and (clean:match("秒施法$") or clean:match("秒施放$") or clean:match("sec cast$") or clean=="瞬发法术" or clean=="瞬发" or clean=="Instant") then
     local rendered=value and (value.a==0 and (en and "Instant" or "瞬发法术") or string.format(en and "%.2f sec cast" or "%.2f秒施法",value.a/1000)) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered};if text~=rendered then font:SetText(rendered);changed=true end
    elseif id==9003861 and (clean:match("秒冷却时间$") or clean:match("分钟冷却时间$") or clean:match("sec cooldown$") or clean:match("min cooldown$")) then
     local rendered=value and string.format(en and "%g sec cooldown" or "%g秒冷却时间",value.b/1000) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered};if text~=rendered then font:SetText(rendered);changed=true end
    else
     self.wd114Lines[key]=nil''')
 s=s.replace('if power[id] or id==9003240','if id==9003861 or power[id] or id==9003240')
 s=rep(s,'   if id==9003855 then','''   if id==9003861 then
    text=en and string.format("Current: %.2f sec cast; %g sec cooldown",value.a/1000,value.b/1000) or string.format("当前：施法%.2f秒；冷却%g秒",value.a/1000,value.b/1000)
   elseif id==9003855 then''')
 return s
edit(CF+ADD+'NumericTooltip.lua',numeric)
sql=(B/'server_SQL/01_CHARACTERS_WD118A_必须执行.sql').read_text(encoding='utf8').replace('wd118_schema','wd119_schema').replace('WD118A','WD119A')
sql=sql.replace('9347,29306)','9347,29306,6031,6525,12525)').replace('9347,29306,4004','9347,29306,6031,6525,12525,4004').replace(str(2**81-1),str(2**84-1))
for i,n in enumerate([6031,6525,12525],71):
 sql=rep(sql,' DECLARE r70 INT DEFAULT 0;',' DECLARE r70 INT DEFAULT 0;\n DECLARE r%d INT DEFAULT 0;'%i)
 sql=rep(sql,f'SET r70=MOD(FLOOR(p_mask/{2**80}),2);',f'SET r70=MOD(FLOOR(p_mask/{2**80}),2);SET r{i}=MOD(FLOOR(p_mask/{2**(i+10)}),2);')
 sql=rep(sql,f'WHEN 29306 THEN node_rank*{2**80} END',f'WHEN {n} THEN node_rank*{2**(i+10)} WHEN 29306 THEN node_rank*{2**80} END')
 sql=sql.replace(f'OR r70<MOD(FLOOR(v_saved/{2**80}),2)',f'OR r{i}<MOD(FLOOR(v_saved/{2**(i+10)}),2) OR r70<MOD(FLOOR(v_saved/{2**80}),2)')
 sql=rep(sql,' IF r70>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29306,r70);END IF;',f' IF r{i}>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,{n},r{i});END IF;\n IF r70>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29306,r70);END IF;')
sql=sql.replace('r69+r70>v_ae','r69+r70+r71+r72+r73>v_ae').replace('OR r70<>0)','OR r70<>0 OR r71<>0 OR r72<>0 OR r73<>0)')
sql=rep(sql,' IF r70<>0 AND p_level<30', ''' IF ((r71<>0 OR r72<>0 OR r73<>0) AND p_level<26) OR ((r72<>0 OR r73<>0) AND r71=0) OR (r72<>0 AND r73<>0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r70<>0 AND p_level<30''')
put('server_SQL/01_CHARACTERS_WD119A_必须执行.sql',sql);(P/'server_SQL/01_CHARACTERS_WD118A_必须执行.sql').unlink()
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
icons=[]
for n in [6031,6525,12525]:
 node=(P/f'research/node{n}.txt').read_text(encoding='utf8');icon=re.search(r'\["Icon"\]="([^"]+)"',node)[1].replace('\\\\','\\');icons.append(icon);path=icon.replace('\\','/')+'.blp';data=(C/path).read_bytes();put(CF+path,data);put('client_mpq输入_导入现有Patch-XA/'+path,data)
donor=json.loads((P/'research/donor.json').read_text(encoding='utf8'))
names=['蛙变术 / Amphibimorph',"贡克祝福 / Gonk's Blessing","克拉格瓦祝福 / Krag'wa's Blessing"]
descs=['将目标区域内敌人变为青蛙，不能攻击施法，移速降低25%，视为野兽。持续40秒，对玩家最多8秒并受递减；受到伤害解除。基础施法1秒、冷却120秒，实际施法和冷却见当前值。 / Frog enemies in target area; no attacks/casts, -25% speed, Beast. 40 sec, up to 8 sec on players with DR; damage breaks. Base cast 1 sec, cooldown 120 sec; current values reflect talents.', '蛙变术冷却缩短60秒，但基础施法时间增加0.5秒。与克拉格瓦祝福互斥。 / Amphibimorph cooldown -60 sec; base cast time +0.5 sec. Exclusive with Krag\'wa\'s Blessing.', '蛙变术变为瞬发。与贡克祝福互斥。 / Amphibimorph is instant. Exclusive with Gonk\'s Blessing.']
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(P/prefix/'Spell.dbc').read_bytes();put('rollback_WD118/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw)
 for j,source in enumerate([500952,806469,807855]):
  sid=9003861+j;assert sid not in rows;r=rows[9003855].copy();d=donor[str(source)]['row'];r[0]=sid;r[1:28]=d[1:28];r[1]=0;r[28:136]=d[28:136];r[204:232]=d[204:232]
  r[34:38]=[0]*4;r[38:40]=[26,26];r[122:131]=[0]*9;r[131:133]=[0,0];r[133]=910120+j;r[134]=0;r[208:212]=[0]*4;r[229:232]=[0]*3
  if j==0:
   r[110]=13321;r[32]|=2 # native damage break; creature template is the existing Hex frog
   r[131]=rows[51514][131]
  else:
   r[4:12]=[0x1d0,0,0,0,0,0,0,0];r[14]=0;r[29:38]=[0]*9;r[204:208]=[0]*4
  for st,t in [(136,names[j]),(153,''),(170,descs[j]),(187,descs[j])]:
   off=len(pool);pool+=t.encode()+b'\0';r[st:st+16]=[off]*16
  rows[sid]=r
 for r in rows.values():
  for st in [136,153,170,187]:assert all(off<len(pool) and pool.find(b'\0',off)>=0 for off in r[st:st+16])
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(P/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD118/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw)
 for sid in [9003861,9003862,9003863]:
  assert not any(r[2]==sid for r in rows.values());r=next(r[:] for r in rows.values() if r[2]==9003855);r[0]=max(rows)+1;r[2]=sid;rows[r[0]]=r
 put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(P/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD118/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw)
for j,icon in enumerate(icons):
 assert 910120+j not in rows;rows[910120+j]=[910120+j,len(pool)];pool+=icon.encode()+b'\0'
put(prefix+'/SpellIcon.dbc',pack(rows,pool))
print('WD119 built; tests pending')
