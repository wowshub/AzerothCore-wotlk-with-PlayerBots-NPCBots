from pathlib import Path
import shutil,re,json,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd119_path.txt').read_text());C119=Path(Path('wd119c_path.txt').read_text());P=Path(Path('wd120_path.txt').read_text());CODE=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots';C=R/'beascendclient/newrebornWOWli20260929beAscend'
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
 if (C119/sub).exists():shutil.copytree(C119/sub,P/sub,dirs_exist_ok=True)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def edit(rel,fn):
 raw=(P/rel).read_bytes();put('rollback_WD119C/'+rel,raw);put(rel,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[74]','AEIds[77]').replace('index<74','index<77').replace('index==74','index==77').replace('i<74','i<77').replace('mask>>84','mask>>87').replace('AEMask(1)<<84','AEMask(1)<<87')
 s=rep(s,'6525,12525};','6525,12525,4005,12645,12646};')
 s=rep(s,'!AERank(mask,62) || spec==1','!AERank(mask,62) && !AERank(mask,74) && !AERank(mask,75) && !AERank(mask,76) || spec==1')
 s=rep(s,'    if((AERank(mask,71)', '''    // WD120: free Brewing nodes; authored prerequisites are alternative paths.
    if((AERank(mask,75) || AERank(mask,76)) && !AERank(mask,74) && !AERank(mask,0)) return false;
    if(AERank(mask,76) && level<14) return false;
    if((AERank(mask,71)''')
 s=rep(s,'    // WD97B:', '''    for(uint32 id:{9003864u,9003865u,9003866u,9003867u,9003870u,9003871u,9003872u,9003873u,9003874u,9003875u,9003876u}) if(!sSpellMgr->GetSpellInfo(id)) return;
    // WD120: preparation is an active saved-build ability, never granted by preview.
    for(uint32 i=0;i<2;++i)
    {
        uint32 id=9003864+i;
        if(!AERank(mask,74+i))
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
        else
        {
            if(!p->HasSpell(id)) p->learnSpell(id);
            // Only the passive restores automatically. The player prepares the ingredient.
            if(i==0 && !p->HasAura(id)) p->CastSpell(p,id,true);
        }
    }
    uint32 toss=0;
    uint32 const tossLevels[7]={14,22,30,38,46,54,60};
    if(AERank(mask,76)) for(uint32 i=0;i<7;++i) if(p->GetLevel()>=tossLevels[i]) toss=9003870+i;
    for(uint32 id=9003870;id<=9003876;++id) if(id!=toss && p->HasSpell(id)) p->removeSpell(id,3,false);
    if(toss && !p->HasSpell(toss)) p->learnSpell(toss);
    // WD97B:''')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
def talent(s):
 s=s.replace('AEIds[74]','AEIds[77]').replace('i<74','i<77')
 s=rep(s,'    if(s->modern && n->id==29306)', '''    if(s->modern && (n->id==4005 || n->id==12645 || n->id==12646))
    {
        level=n->id==12646?14:10;
        if(n->id!=4005) missing=(rank(4005) || rank(29744))?0:1;
    }
    if(s->modern && n->id==29306)''')
 return s
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talent)
def nodes(s):
 for n,l in [(4005,10),(12645,10),(12646,14)]:
  pat=r'\{'+str(n)+r',1,\d+,1,0,0,0,0,0,false,'
  s,count=re.subn(pat,'{%d,1,%d,1,0,0,0,0,0,true,'%(n,l),s);assert count==1,(n,count)
 return s
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',nodes)
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return spell==9003861','return spell==9003864 || spell==9003865 || (spell>=9003870 && spell<=9003876) || spell==9003861'))
def ui(s):
 s=s.replace('[12525]=73}','[12525]=73,[4005]=74,[12645]=75,[12646]=76}').replace('[12525]=1}','[12525]=1,[4005]=1,[12645]=1,[12646]=1}').replace('MaskFits(mask,84)','MaskFits(mask,87)')
 s=rep(s,' if rank(9311)>0 and', ''' if (rank(4005)>0 or rank(12645)>0 or rank(12646)>0) and M.specs[M.slot+1]~=1 then return false,"本方案需要绑定酿造专精" end
 if (rank(12645)>0 or rank(12646)>0) and rank(4005)==0 and rank(29744)==0 then return false,"需要大锅酿造或治疗守卫" end
 if rank(12646)>0 and M.level<14 then return false,"药水投掷需要14级" end
 if rank(9311)>0 and''')
 s=rep(s,' if id==7131 or', ''' if id==4005 then return M.level>=10 and M.specs[M.slot+1]==1 end
 if id==12645 or id==12646 then return M.level>=(id==12646 and 14 or 10) and M.specs[M.slot+1]==1 and (M.AERank(4005)>0 or M.AERank(29744)>0) end
 if id==7131 or''')
 for n,zh,en,l,e,english in [
 (4005,'大锅酿造','Cauldron Brewer',10,'解锁酿造配料体系。本批支持丛林蘑菇；配料需主动准备，基础同时保留一种。','Unlocks ingredient brewing. This batch supports Jungle Shrooms; prepare it actively, one ingredient at a time.'),
 (12645,'配料：丛林蘑菇','Ingredient: Jungle Shrooms',10,'准备后每6秒治疗周围30码最多8名队友；基础治疗随角色等级缩放，另加20%治疗加成。药水投掷附加每3秒一次、持续18秒的治疗。','Prepare to heal up to 8 raid allies within 30 yd every 6 sec; level-scaled base plus 20% bonus healing. Potion Toss adds a heal every 3 sec for 18 sec.'),
 (12646,'药水投掷','Potion Toss',14,'需先准备配料。瞬发治疗友方，冷却15秒；随等级学习对应技能等级，直接治疗增加28%治疗加成及10%精神。','Requires a prepared ingredient. Instant friendly heal, 15 sec cooldown; ranks follow level. Direct heal gains 28% bonus healing and 10% Spirit.')]:
  detail='details[%d]={zh=%s,en=%s,level=%d,early="%d",kind="酿造技能 / Brewing ability",effects={{%s,%s}},limit={"仅已保存的激活酿造方案生效；配料不是可消耗物品。","Active saved Brewing build only; ingredients are not consumable items."},path={"免费节点；配料及投掷需要大锅酿造或治疗守卫。","Free nodes; ingredient and toss require Cauldron Brewer or Healing Ward."}}\n'%(n,json.dumps(zh,ensure_ascii=False),json.dumps(en),l,l,json.dumps(e,ensure_ascii=False),json.dumps(english))
  s=rep(s,'local function Pair(',detail+'local function Pair(')
 return s
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',84)',',87)'))
edit(CF+ADD+'Progress.lua',lambda s:s.replace('RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [4005]={name="大锅酿造",spells={9003864}},\n [12645]={name="配料：丛林蘑菇",spells={9003865}},\n [12646]={name="药水投掷",spells={9003870,9003871,9003872,9003873,9003874,9003875,9003876}},'))
sql=(B/'server_SQL/01_CHARACTERS_WD119A_必须执行.sql').read_text(encoding='utf8').replace('wd119_schema','wd120_schema').replace('WD119A','WD120A')
sql=sql.replace('6525,12525)','6525,12525,4005,12645,12646)').replace('6525,12525,4004','6525,12525,4005,12645,12646,4004').replace(str(2**84-1),str(2**87-1))
# Free nodes are excluded from both pools, including the GM budget reduction guard.
sql=sql.replace('6525,12525,4005,12645,12646) THEN node_rank ELSE 0 END)>36+p_ae','6525,12525) THEN node_rank ELSE 0 END)>36+p_ae')
for i,n in enumerate([4005,12645,12646],74):
 sql=rep(sql,' DECLARE r73 INT DEFAULT 0;',' DECLARE r73 INT DEFAULT 0;\n DECLARE r%d INT DEFAULT 0;'%i)
 sql=rep(sql,f'SET r73=MOD(FLOOR(p_mask/{2**83}),2);',f'SET r73=MOD(FLOOR(p_mask/{2**83}),2);SET r{i}=MOD(FLOOR(p_mask/{2**(i+10)}),2);')
 sql=rep(sql,f'WHEN 29306 THEN node_rank*{2**80} END',f'WHEN {n} THEN node_rank*{2**(i+10)} WHEN 29306 THEN node_rank*{2**80} END')
 sql=sql.replace(f'OR r73<MOD(FLOOR(v_saved/{2**83}),2)',f'OR r{i}<MOD(FLOOR(v_saved/{2**(i+10)}),2) OR r73<MOD(FLOOR(v_saved/{2**83}),2)')
 sql=rep(sql,' IF r73>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,12525,r73);END IF;',f' IF r{i}>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,{n},r{i});END IF;\n IF r73>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,12525,r73);END IF;')
sql=sql.replace('r49+r50+r51+r52+r53+r54+r55+r56+r57+r61+r62>0','r49+r50+r51+r52+r53+r54+r55+r56+r57+r61+r62+r74+r75+r76>0')
sql=rep(sql,' IF ((r71<>0', ''' IF ((r75<>0 OR r76<>0) AND r74=0 AND r0=0) OR (r76<>0 AND p_level<14) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF ((r71<>0''')
put('server_SQL/01_CHARACTERS_WD120A_必须执行.sql',sql)
(P/'server_SQL/01_CHARACTERS_WD119A_必须执行.sql').unlink()
print('WD120 storage/UI candidate built')
