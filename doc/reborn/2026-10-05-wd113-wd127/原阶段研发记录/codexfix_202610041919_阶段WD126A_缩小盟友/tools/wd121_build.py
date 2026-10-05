# coding: utf-8
from pathlib import Path
import shutil,re,json,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd120_path.txt').read_text());P=Path(Path('wd121_path.txt').read_text())
C=R/'beascendclient/newrebornWOWli20260929beAscend';SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL','tools','rollback']:
 shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def edit(rel,fn):
 raw=(B/rel).read_bytes();put('rollback_WD120A/'+rel,raw);put(rel,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[77]','AEIds[79]').replace('index<77','index<79').replace('index==77','index==79').replace('i<77','i<79').replace('mask>>87','mask>>90').replace('AEMask(1)<<87','AEMask(1)<<90')
 s=rep(s,'4005,12645,12646};','4005,12645,12646,6498,29303};')
 s=rep(s,'    if(index>=70)', '    if(index==77) return static_cast<uint32>((mask>>87)&3u);\n    if(index>=78) return static_cast<uint32>((mask>>(index+11))&1u);\n    if(index>=70)')
 s=s.replace('(index==69 ||','(index==77 || index==69 ||').replace('<<(index>=70?', '<<(index==77?87:index>=78?index+11:index>=70?')
 s=s.replace('if(AERank(mask,69)>2','if(AERank(mask,77)>2 || AERank(mask,69)>2')
 s=rep(s,'+AERank(mask,61)+AERank(mask,62);','+AERank(mask,61)+AERank(mask,62)+AERank(mask,77)+AERank(mask,78);')
 s=rep(s,'!AERank(mask,76) || spec==1','!AERank(mask,76) && !AERank(mask,77) && !AERank(mask,78) || spec==1')
 s=rep(s,'    // WD120: free', '''    // WD121: tier-eight Brewing talents cannot bootstrap their own foundation.
    if((AERank(mask,77) || AERank(mask,78)) && AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)<8) return false;
    // WD120: free''')
 s=rep(s,'    // WD120: preparation', '''    for(uint32 id:{9003877u,9003878u,9003879u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    uint32 const fresh=AERank(mask,77);
    uint32 const brewingPassives[3]={9003877,9003878,9003879};
    bool const brewingWanted[3]={fresh==1,fresh==2,AERank(mask,78)>0};
    // Remove lower ranks first; repeated activation restores a missing passive aura.
    for(uint32 i=0;i<3;++i) if(!brewingWanted[i])
    {
        p->RemoveAurasDueToSpell(brewingPassives[i],p->GetGUID());
        if(p->HasSpell(brewingPassives[i])) p->removeSpell(brewingPassives[i],3,false);
    }
    for(uint32 i=0;i<3;++i) if(brewingWanted[i])
    {
        if(!p->HasSpell(brewingPassives[i])) p->learnSpell(brewingPassives[i]);
        if(!p->HasAura(brewingPassives[i])) p->CastSpell(p,brewingPassives[i],true);
    }
    // WD120: preparation''')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
def talent(s):
 s=s.replace('AEIds[77]','AEIds[79]').replace('i<77','i<79')
 return rep(s,'    if(s->modern && (n->id==4005', '''    if(s->modern && (n->id==6498 || n->id==29303))
    {
        level=10;te=rank(7131)+rank(30884)+rank(29736)+rank(5055)+rank(7129);
    }
    if(s->modern && (n->id==4005''')
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talent)
def nodes(s):
 for n in [6498,29303]:
  pat=r'(\{'+str(n)+r',1,\d+,\d+,\d+,\d+,\d+,\d+,\d+,)false,'
  s,k=re.subn(pat,r'\1true,',s);assert k==1,(n,k)
 return s
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',nodes)
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return spell==9003864','return (spell>=9003877 && spell<=9003879) || spell==9003864'))
edit(SF+'src/server/game/Spells/SpellInfo.cpp',lambda s:rep(s,'        case 9003862:','        case 9003877: case 9003878: case 9003879: // WD121 exact Brewing healing only\n        case 9003862:'))
def mods(s):
 return rep(s,'        if(mod->spellId==9003862)', '''        // WD121: use native done-healing modifiers after coefficients, not base-only edits.
        if(mod->spellId==9003877 || mod->spellId==9003878)
            return check->Id!=9003866 || mod->op!=SPELLMOD_DAMAGE;
        if(mod->spellId==9003879)
            return !((check->Id>=9003870 && check->Id<=9003876 && mod->op==SPELLMOD_DAMAGE) ||
                     (check->Id==9003867 && mod->op==SPELLMOD_DOT));
        if(mod->spellId==9003862)''')
edit(SF+SRC+'RebornWitchDoctor.cpp',mods)
def ui(s):
 s=s.replace('[12646]=76}','[12646]=76,[6498]=77,[29303]=78}').replace('[12646]=1}','[12646]=1,[6498]=2,[29303]=1}').replace('MaskFits(mask,87)','MaskFits(mask,90)')
 s=rep(s,'return i>=70 and','return i==77 and 87 or i>=78 and (i+11) or i>=70 and')
 s=s.replace('(i==69 or','(i==77 or i==69 or').replace('(M.AERank(9347,mask)>2','(M.AERank(6498,mask)>2 or M.AERank(9347,mask)>2')
 s=rep(s,'function M.BrewingSpent(mask) return','function M.BrewingFoundation(mask) return M.AERank(7131,mask)+M.AERank(30884,mask)+M.AERank(29736,mask)+M.AERank(5055,mask)+M.AERank(7129,mask) end\nfunction M.BrewingSpent(mask) return M.AERank(6498,mask)+M.AERank(29303,mask)+')
 # Existing tier-eight gates must not count the new tier-eight nodes.
 s=s.replace('M.BrewingSpent(mask)-rank(7948)-rank(31137)-rank(7132)-rank(29753)','M.BrewingFoundation(mask)')
 s=s.replace('M.BrewingSpent(M.draftAE)-M.AERank(7948)-M.AERank(31137)-M.AERank(7132)-M.AERank(29753)','M.BrewingFoundation(M.draftAE)')
 s=rep(s,' if rank(12646)>0 and', ' if (rank(6498)>0 or rank(29303)>0) and M.BrewingFoundation(mask)<8 then return false,"需要先投入8点基础酿造TE；同层不计前置" end\n if rank(12646)>0 and')
 s=rep(s,' if id==4005 then',' if id==6498 or id==29303 then return M.level>=10 and M.specs[M.slot+1]==1 and M.BrewingFoundation(M.draftAE)>=8 end\n if id==4005 then')
 for n,zh,en,es in [(6498,'新鲜配料','Fresh Ingredients',[(15,'只提高大锅丛林蘑菇的周期范围治疗；不提高投掷附带治疗。'),(30,'只提高大锅丛林蘑菇的周期范围治疗；不提高投掷附带治疗。')]),(29303,'药水增效','Potion Boss',[(20,'提高药水投掷直接治疗和投掷附带丛林蘑菇持续治疗；不提高大锅周期治疗。')])]:
  effects=[[f'治疗量提高{v}%。{t}',f'Healing +{v}%. '+('Cauldron Shrooms pulse only; excludes tossed heal over time.' if n==6498 else 'Potion Toss and its Shrooms heal over time; excludes Cauldron pulse.')] for v,t in es]
  detail='details[%d]={zh=%s,en=%s,level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects=%s,limit={"仅保存并激活后生效；持续治疗增益在重新投掷时生效。","Active saved build only; recast Potion Toss to update its existing heal over time."},path={"先投入8点基础酿造TE，每级1 TE；同层不能互相凑前置。","Eight foundation Brewing TE, then one TE per rank; same-tier points do not qualify."}}\n'%(n,json.dumps(zh,ensure_ascii=False),json.dumps(en),json.dumps(effects,ensure_ascii=False).replace('[','{').replace(']','}'))
  s=rep(s,'local function Pair(',detail+'local function Pair(')
 return s
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',87)',',90)'))
edit(CF+ADD+'Progress.lua',lambda s:s.replace('RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [6498]={name="新鲜配料",spells={9003877,9003878}},\n [29303]={name="药水增效",spells={9003879}},'))
sql=(B/'server_SQL/01_CHARACTERS_WD120A_必须执行.sql').read_text(encoding='utf8').replace('wd120_schema','wd121_schema').replace('WD120A','WD121A')
sql=sql.replace('4005,12645,12646)','4005,12645,12646,6498,29303)').replace(str(2**87-1),str(2**90-1)).replace('WHEN 9347 THEN 2','WHEN 6498 THEN 2 WHEN 9347 THEN 2')
for idx,node,shift,width in [(77,6498,87,4),(78,29303,89,2)]:
 sql=rep(sql,' DECLARE r76 INT DEFAULT 0;',f' DECLARE r{idx} INT DEFAULT 0;\n DECLARE r76 INT DEFAULT 0;')
 sql=rep(sql,' SET r0=v_low&1;',f' SET r{idx}=MOD(FLOOR(p_mask/{2**shift}),{width});\n SET r0=v_low&1;')
 sql=rep(sql,'WHEN 29306 THEN node_rank*',f'WHEN {node} THEN node_rank*{2**shift} WHEN 29306 THEN node_rank*')
 sql=rep(sql,' IF r0<(v_saved_low&1)',f' IF r{idx}<MOD(FLOOR(v_saved/{2**shift}),{width}) OR r0<(v_saved_low&1)') if idx==77 else rep(sql,' IF r77<',f' IF r{idx}<MOD(FLOOR(v_saved/{2**shift}),{width}) OR r77<')
 sql=rep(sql,' IF r76>0 THEN',f' IF r{idx}>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,{node},r{idx});END IF;\n IF r76>0 THEN')
sql=sql.replace('r61+r62>v_te','r61+r62+r77+r78>v_te').replace('r74+r75+r76>0','r74+r75+r76+r77+r78>0')
sql=rep(sql,' IF ((r75<>0', ' IF r77>2 OR ((r77<>0 OR r78<>0) AND r49+r50+r51+r53+r55<8) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;\n IF ((r75<>0')
put('server_SQL/01_CHARACTERS_WD121A_必须执行.sql',sql);(P/'server_SQL/01_CHARACTERS_WD120A_必须执行.sql').unlink()
# Build private native passives from a known compatible local passive, retain all old rows.
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
icons=[]
for node in [6498,29303]:
 text=(P/f'research/node{node}.txt').read_text(encoding='utf8');icon=re.search(r'\["Icon"\]="([^"]+)"',text)[1].replace('\\\\','\\');icons.append(icon)
 path=icon.replace('\\','/')+'.blp';data=(C/path).read_bytes();put(CF+path,data);put('client_mpq输入_导入现有Patch-XA/'+path,data)
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(B/prefix/'Spell.dbc').read_bytes();put('rollback_WD120A/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw)
 for sid,amount,name,desc in [(9003877,15,'新鲜配料 / Fresh Ingredients','大锅丛林蘑菇周期治疗提高15%；不影响投掷附带治疗。 / Cauldron Jungle Shrooms healing +15%; excludes tossed heal over time.'),(9003878,30,'新鲜配料 / Fresh Ingredients','大锅丛林蘑菇周期治疗提高30%；不影响投掷附带治疗。 / Cauldron Jungle Shrooms healing +30%; excludes tossed heal over time.'),(9003879,20,'药水增效 / Potion Boss','药水投掷直接治疗及其丛林蘑菇持续治疗提高20%；不影响大锅周期治疗。重新投掷更新已有持续治疗。 / Potion Toss direct healing and its Shrooms heal over time +20%; excludes Cauldron pulses. Recast to update existing effects.')]:
  assert sid not in rows
  r=rows[9003864][:];r[0]=sid;r[133]=910126 if sid<9003879 else 910127;r[71:74]=[6,6 if sid==9003879 else 0,0];r[95:98]=[108,108 if sid==9003879 else 0,0];r[80:83]=[amount-1,amount-1 if sid==9003879 else 0,0];r[110:113]=[0,22 if sid==9003879 else 0,0];r[86:89]=[1,1 if sid==9003879 else 0,0]
  for start,txt in [(136,name),(153,('等级 %d / Rank %d'%((sid-9003876,)*2)) if sid<9003879 else ''),(170,desc),(187,desc)]:
   off=len(pool);pool+=txt.encode()+b'\0';r[start:start+16]=[off]*16
  rows[sid]=r
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(B/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD120A/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw)
 for sid in range(9003877,9003880):
  assert not any(r[2]==sid for r in rows.values());r=next(r[:] for r in rows.values() if r[2]==9003864);r[0]=max(rows)+1;r[2]=sid;r[8]=9003878 if sid==9003877 else 0;rows[r[0]]=r
 put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(B/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD120A/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw)
for i,icon in enumerate(icons):
 assert 910126+i not in rows;rows[910126+i]=[910126+i,len(pool)];pool+=icon.encode()+b'\0'
put(prefix+'/SpellIcon.dbc',pack(rows,pool))
print('WD121 candidate generated',P)
