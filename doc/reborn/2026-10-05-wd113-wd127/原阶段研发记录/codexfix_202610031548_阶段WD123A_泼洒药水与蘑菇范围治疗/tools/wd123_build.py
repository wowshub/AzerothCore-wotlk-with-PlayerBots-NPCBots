from pathlib import Path
import re,json,struct,shutil
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd122_path.txt').read_text());P=Path(Path('wd123_path.txt').read_text());C=R/'beascendclient/newrebornWOWli20260929beAscend'
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL','tools']:shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def edit(rel,fn):
 raw=(P/rel).read_bytes();back=P/'rollback_WD122A'/rel
 if not back.exists():put('rollback_WD122A/'+rel,(B/rel).read_bytes())
 put(rel,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[81]','AEIds[82]').replace('index<81','index<82').replace('index==81','index==82').replace('i<81','i<82').replace('mask>>92','mask>>93').replace('AEMask(1)<<92','AEMask(1)<<93')
 s=rep(s,'6020,29737};','6020,29737,7128};')
 s=rep(s,'+AERank(mask,79)+AERank(mask,80);','+AERank(mask,79)+AERank(mask,80)+AERank(mask,81);')
 s=rep(s,'!AERank(mask,80) || spec==1','!AERank(mask,80) && !AERank(mask,81) || spec==1')
 s=s.replace('AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)<8','AERank(mask,49)+AERank(mask,50)+AERank(mask,51)+AERank(mask,53)+AERank(mask,55)+AERank(mask,81)<8')
 s=rep(s,'    // WD122 authored choice', '    // WD122 authored choice') if '    // WD122 authored choice' in s else s
 s=rep(s,'    // WD121: tier-eight','    if(AERank(mask,81) && level<17) return false; // WD123 first Splash rank.\n    // WD121: tier-eight')
 s=rep(s,'    // WD97B: only the highest', '''    // WD123: one saved talent owns the highest eligible Splash rank only.
    for(uint32 id=9003890;id<=9003896;++id) if(!sSpellMgr->GetSpellInfo(id)) return;
    uint32 splash=0;
    uint32 const splashLevels[7]={17,22,28,36,44,50,58};
    if(AERank(mask,81)) for(uint32 i=0;i<7;++i) if(p->GetLevel()>=splashLevels[i]) splash=9003890+i;
    for(uint32 id=9003890;id<=9003896;++id) if(id!=splash && p->HasSpell(id)) p->removeSpell(id,3,false);
    if(splash && !p->HasSpell(splash)) p->learnSpell(splash);
    // WD97B: only the highest''')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',lambda s:rep(s.replace('AEIds[81]','AEIds[82]').replace('i<81','i<82').replace('rank(29736)+rank(5055)+rank(7129);','rank(29736)+rank(5055)+rank(7129)+rank(7128);').replace('AERank(s->aeMasks[slot],53)+AERank(s->aeMasks[slot],55);','AERank(s->aeMasks[slot],53)+AERank(s->aeMasks[slot],55)+AERank(s->aeMasks[slot],81);'),'    if(s->modern && (n->id==6498','    if(s->modern && n->id==7128) level=17;\n    if(s->modern && (n->id==6498'))
def nodes(s):
 s,n=re.subn(r'(\{7128,1,\d+,\d+,\d+,\d+,\d+,\d+,\d+,)false,',r'\1true,',s);assert n==1;return s
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',nodes)
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return (spell>=9003877','return (spell>=9003890 && spell<=9003896) || (spell>=9003877'))
edit(SF+SRC+'RebornWitchDoctor.cpp',lambda s:rep(s,'check->Id==9003867 && mod->op==SPELLMOD_DOT','(check->Id==9003867 || check->Id==9003889) && mod->op==SPELLMOD_DOT'))
edit(SF+SRC+'RebornWitchDoctorBrewingNumbers.h',lambda s:rep(s,'inline double Scaling', '''constexpr uint32 SplashHot=9003889;
inline bool IsSplash(uint32 id) { return id>=9003890 && id<=9003896; }
inline float SplashBonus(Player* p)
{
    return float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.224494f
        +std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.08f;
}
inline double Scaling'''))
def mechanics(s):
 s=rep(s,'WD120A::Pulse,WD120A::Hot});','WD120A::Pulse,WD120A::Hot,WD120A::SplashHot});')
 s=rep(s,'if(WD120A::IsToss(GetSpellInfo()->Id) &&','if((WD120A::IsToss(GetSpellInfo()->Id) || WD120A::IsSplash(GetSpellInfo()->Id)) &&')
 s=rep(s,'&& !WD120A::IsToss(GetSpellInfo()->Id))','&& !WD120A::IsToss(GetSpellInfo()->Id) && !WD120A::IsSplash(GetSpellInfo()->Id))')
 s=rep(s,'SetEffectValue(int32(base+WD120A::Bonus(p,pulse)));','SetEffectValue(int32(base+(WD120A::IsSplash(GetSpellInfo()->Id)?WD120A::SplashBonus(p):WD120A::Bonus(p,pulse))));')
 s=rep(s,'!WD120A::IsToss(GetSpellInfo()->Id) || !_shrooms','(!WD120A::IsToss(GetSpellInfo()->Id) && !WD120A::IsSplash(GetSpellInfo()->Id)) || !_shrooms')
 s=rep(s,'p->CastSpell(target,WD120A::Hot,true);','// Correct official 803698 healing route, not upstream 803273 Fish Oil.\n        p->CastSpell(target,WD120A::IsSplash(GetSpellInfo()->Id)?WD120A::SplashHot:WD120A::Hot,true);')
 return s
edit(SF+SRC+'RebornWitchDoctorBrewingFoundation.inc',mechanics)
def query(s):
 s=s.replace('WD120A::IsToss(id) || id==9003861','(WD120A::IsToss(id) || WD120A::IsSplash(id)) || id==9003861').replace('if(id==WD120A::Shrooms || WD120A::IsToss(id))','if(id==WD120A::Shrooms || WD120A::IsToss(id) || WD120A::IsSplash(id))')
 s=rep(s,'int32(amount+WD120A::Bonus(p,pulse))','int32(amount+(WD120A::IsSplash(id)?WD120A::SplashBonus(p):WD120A::Bonus(p,pulse)))')
 s=rep(s,'        else h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active);','''        else if(WD120A::IsSplash(id))
        {
            SpellInfo const* hot=sSpellMgr->GetSpellInfo(WD120A::SplashHot);
            if(!hot) { h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true; }
            uint32 tick=p->SpellHealingBonusDone(p,hot,uint32(std::max(0,hot->Effects[EFFECT_0].CalcValue(p))),DOT,EFFECT_0);
            h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,tick,12000);
        }
        else h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active);''')
 return s
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',query)
def ui(s):
 s=s.replace('[29737]=80}','[29737]=80,[7128]=81}').replace('[29737]=1}','[29737]=1,[7128]=1}').replace('MaskFits(mask,92)','MaskFits(mask,93)')
 s=rep(s,'function M.BrewingSpent(mask) return','function M.BrewingSpent(mask) return M.AERank(7128,mask)+')
 s=rep(s,'function M.BrewingFoundation(mask) return','function M.BrewingFoundation(mask) return M.AERank(7128,mask)+')
 s=rep(s,' if rank(12646)>0 and',' if rank(7128)>0 and M.level<17 then return false,"泼洒药水需要17级" end\n if rank(12646)>0 and')
 s=rep(s,' if id==6498 or',' if id==7128 then return M.level>=17 and M.specs[M.slot+1]==1 end\n if id==6498 or')
 s=rep(s,'local function Pair(','''details[7128]={zh="泼洒药水",en="Splash Potion",level=17,early="17",kind="酿造技能 / Brewing ability",effects={{"向40码内地点泼洒，治疗10码内最多8名友方；7个技能等级，冷却15秒。蘑菇附加每3秒一次、持续12秒的治疗。","Splash at a location within 40 yd, healing up to 8 allies within 10 yd. Seven ranks, 15 sec cooldown. Shrooms adds healing every 3 sec for 12 sec."}},limit={"需准备丛林蘑菇。药水增效只增强附加持续治疗，不增强泼洒直接治疗。","Requires prepared Shrooms. Potion Boss boosts the added HoT only, not direct Splash healing."},path={"酿造专精，17级，1 TE；按等级自动学习最高技能等级。","Brewing, level 17, one TE; highest rank learned by level."}}
local function Pair(''')
 s=s.replace('提高药水投掷直接治疗和投掷附带丛林蘑菇持续治疗；不提高大锅周期治疗。','提高药水投掷直接治疗及投掷／泼洒附带的蘑菇持续治疗；不提高泼洒直接或大锅治疗。').replace('Potion Toss and its Shrooms heal over time; excludes Cauldron pulse.','Potion Toss direct and tossed/splashed Shrooms HoT; excludes direct Splash and Cauldron pulses.')
 return s
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',92)',',93)'))
edit(CF+ADD+'Progress.lua',lambda s:rep(s,'RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [7128]={name="泼洒药水",spells={9003890,9003891,9003892,9003893,9003894,9003895,9003896}},'))
def tooltip(s):
 s=rep(s,'range(9003870,9003876);','range(9003870,9003876);range(9003890,9003896);')
 s=s.replace('(id>=9003870 and id<=9003876) or id==9003861','(id>=9003870 and id<=9003876) or (id>=9003890 and id<=9003896) or id==9003861')
 s=rep(s,'   if id==9003865 or','''   if id>=9003890 and id<=9003896 then
    text=string.format("当前直接治疗 / Direct heal: %d–%d；蘑菇 / Shrooms: %d / 3秒，持续%g秒 / sec",value.a,value.b,value.c or 0,(value.d or 12000)/1000)
   elseif id==9003865 or''')
 return s
edit(CF+ADD+'NumericTooltip.lua',tooltip)
sql=(B/'server_SQL/01_CHARACTERS_WD122A_必须执行.sql').read_text(encoding='utf8').replace('wd122_schema','wd123_schema').replace('WD122A','WD123A').replace('6020,29737)','6020,29737,7128)').replace(str(2**92-1),str(2**93-1))
sql=rep(sql,' DECLARE r80 INT DEFAULT 0;',' DECLARE r81 INT DEFAULT 0;\n DECLARE r80 INT DEFAULT 0;')
sql=rep(sql,' SET r0=v_low&1;',f' SET r81=MOD(FLOOR(p_mask/{2**92}),2);\n SET r0=v_low&1;')
sql=rep(sql,'WHEN 29737 THEN node_rank*',f'WHEN 7128 THEN node_rank*{2**92} WHEN 29737 THEN node_rank*')
sql=rep(sql,' IF r80<',f' IF r81<MOD(FLOOR(v_saved/{2**92}),2) OR r80<')
sql=rep(sql,' IF r80>0 THEN',' IF r81>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,7128,r81);END IF;\n IF r80>0 THEN')
sql=sql.replace('r79+r80>v_te','r79+r80+r81>v_te').replace('r78+r79+r80>0','r78+r79+r80+r81>0')
sql=sql.replace('r49+r50+r51+r53+r55<8','r49+r50+r51+r53+r55+r81<8')
sql=rep(sql,' IF r79<>0 AND',' IF r81<>0 AND p_level<17 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;\n IF r79<>0 AND')
put('server_SQL/01_CHARACTERS_WD123A_必须执行.sql',sql);(P/'server_SQL/01_CHARACTERS_WD122A_必须执行.sql').unlink()
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
donor=json.loads((P/'research/splash_closure.json').read_text(encoding='utf8'));text=(P/'research/node7128.txt').read_text(encoding='utf8');icon=re.search(r'\["Icon"\]="([^"]+)"',text)[1].replace('\\\\','\\');path=icon.replace('\\','/')+'.blp'
put(CF+path,(C/path).read_bytes());put('client_mpq输入_导入现有Patch-XA/'+path,(C/path).read_bytes())
mapping={802710:9003890,**{567731+i:9003891+i for i in range(6)}}
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(B/prefix/'Spell.dbc').read_bytes();put('rollback_WD122A/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw)
 for src,sid in {803698:9003889,**mapping}.items():
  assert sid not in rows
  r=rows[9003867 if sid==9003889 else 9003870][:];d=donor[str(src)]['row'];r[0]=sid;r[37:40]=d[37:40];r[74]=d[74];r[77]=d[77];r[80]=d[80];r[133]=910130
  r[116:119]=[0]*3;r[122:131]=[0]*9;r[208:212]=[0]*4
  if sid!=9003889:
   r[71:74]=[10,0,0];r[86:92]=[87,0,0,31,0,0];r[92:95]=[13,0,0];r[212]=8;r[29]=15000;r[30]=0;r[46]=5;r[204]=20;r[40]=0;r[28]=1
   name='泼洒药水 / Splash Potion';rank=f'等级 {sid-9003889} / Rank {sid-9003889}';desc='向40码内地点泼洒药水，治疗10码内最多8名友方。基础治疗$s1，另加22.4494%治疗加成和8%精神。需先准备蘑菇，附加每3秒一次、持续12秒的治疗。15秒冷却。 / Splash within 40 yd, healing up to 8 allies within 10 yd. Base heal $s1 plus 22.4494% bonus healing and 8% Spirit. Prepared Shrooms adds a 12 sec HoT ticking every 3 sec. 15 sec cooldown.'
  else:
   r[40]=29;r[98]=3000;r[204:208]=[0]*4
   name='泼洒蘑菇 / Splashed Shrooms';rank='';desc='每3秒恢复$s1生命值，持续12秒。 / Restores $s1 health every 3 sec for 12 sec.'
  for start,txt in [(136,name),(153,rank),(170,desc),(187,desc)]:
   off=len(pool);pool+=txt.encode()+b'\0';r[start:start+16]=[off]*16
  rows[sid]=r
 # Explain the existing Boss scope now that its second ingredient route is available.
 for start in [170,187]:
  txt='药水投掷直接治疗及投掷／泼洒附带的蘑菇持续治疗提高20%；不提高泼洒直接治疗或大锅治疗。 / Potion Toss direct healing and tossed/splashed Shrooms HoT +20%; excludes direct Splash and Cauldron pulses.'
  off=len(pool);pool+=txt.encode()+b'\0';rows[9003879][start:start+16]=[off]*16
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(B/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD122A/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw)
 for sid in mapping.values():
  assert not any(r[2]==sid for r in rows.values());r=next(r[:] for r in rows.values() if r[2]==9003870);r[0]=max(rows)+1;r[2]=sid;r[8]=sid+1 if sid<9003896 else 0;rows[r[0]]=r
 put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(B/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD122A/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw);assert 910130 not in rows;rows[910130]=[910130,len(pool)];pool+=icon.encode()+b'\0';put(prefix+'/SpellIcon.dbc',pack(rows,pool))
ids=','.join(str(i) for i in mapping.values());hot=9003889
world=f'''-- WORLD. Conflict checks precede all writes; only WD123 private spell IDs.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd123_world$$
CREATE PROCEDURE reborn_wd123_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN({ids}) AND ScriptName<>'spell_reborn_wd120_brewing') OR EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id={hot}) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD123A script ID conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN({ids}) AND (direct_bonus<>0 OR dot_bonus<>0 OR ap_bonus<>0 OR ap_dot_bonus<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD123A coefficient conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_ranks WHERE (first_spell_id=9003890 OR spell_id BETWEEN 9003890 AND 9003896) AND (first_spell_id<>9003890 OR spell_id NOT BETWEEN 9003890 AND 9003896 OR `rank`<>spell_id-9003889)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD123A rank conflict';END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES '''+','.join(f"({i},'spell_reborn_wd120_brewing')" for i in mapping.values())+''';
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES '''+','.join(f"({i},0,0,0,0,'WD123A manual Splash coefficient')" for i in mapping.values())+''' ON DUPLICATE KEY UPDATE comments=VALUES(comments);
 INSERT IGNORE INTO spell_ranks(first_spell_id,spell_id,`rank`) VALUES '''+','.join(f'(9003890,{i},{i-9003889})' for i in mapping.values())+''';
END$$
CALL reborn_wd123_world()$$
DROP PROCEDURE reborn_wd123_world$$
DELIMITER ;
'''
put('server_SQL/04_WORLD_WD123A_必须执行.sql',world)
print('WD123 candidate built',P)
