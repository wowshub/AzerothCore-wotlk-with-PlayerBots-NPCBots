from pathlib import Path
import shutil,re,json,struct
import wd19_common as c
B=Path(Path('wd112_path.txt').read_text(encoding='utf8'));P=Path(Path('wd113_path.txt').read_text(encoding='utf8'))
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
nodes=[(6381,9003850,'洛阿强化','Loa Empowerment'),(12048,9003851,'希里克的祝福',"Blessing of Hir’eek"),(11323,9003852,'显性诅咒','Blatant Curse')]
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def rep(s,a,b):
 assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
for prefix in [SF,CF,'03_覆盖到服务端根目录/','client_mpq输入_导入现有Patch-XA/']:
 for f in (B/prefix).rglob('*'):
  if f.is_file():put(str(f.relative_to(B)),f.read_bytes())
def edit(rel,fn):
 old=(P/rel).read_bytes();put('rollback_WD112/'+rel,old);put(rel,fn(old.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[63]','AEIds[66]').replace('index<63','index<66').replace('index==63','index==66').replace('i<63','i<66')
 s=rep(s,'6030,7132,29753};','6030,7132,29753,6381,12048,11323};')
 s=rep(s,'+AERank(mask,60);','+AERank(mask,60)+AERank(mask,63)+AERank(mask,64)+AERank(mask,65);')
 # Exclude all new tier-nine nodes from every existing foundation calculation.
 s=s.replace('-AERank(mask,59)<9','-AERank(mask,59)-AERank(mask,63)-AERank(mask,64)-AERank(mask,65)<9')
 s=s.replace('mask>>72','mask>>75').replace('AEMask(1)<<72','AEMask(1)<<75')
 s=rep(s,'    // WD100: the five','''    // WD113: tier-nine Class nodes cannot bootstrap one another.
    if((AERank(mask,63) || AERank(mask,64) || AERank(mask,65)) &&
       AERank(mask,0)+AERank(mask,1)+AERank(mask,2)+AERank(mask,3)+AERank(mask,4)+AERank(mask,5)+AERank(mask,39)+AERank(mask,60)<9) return false;
    if(AERank(mask,64) && AERank(mask,48)) return false; // Hir'eek / Dark Mojo choice.
    // WD100: the five''')
 s=rep(s,'    bool wanted[8]=','''    uint32 const class113[3]={9003850,9003851,9003852};
    for(uint32 i=0;i<3;++i)
    {
        if(!AERank(mask,63+i))
        {
            if(p->HasSpell(class113[i])) p->removeSpell(class113[i],3,false);
            p->RemoveAurasDueToSpell(class113[i],p->GetGUID());
        }
        else if(!p->HasSpell(class113[i])) p->learnSpell(class113[i]);
    }
    bool wanted[8]=''')
 s=s.replace('for(uint32 spell:{9003430u,','for(uint32 spell:{9003850u,9003851u,9003852u,9003430u,')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
def talents(s):
 s=s.replace('AEIds[63]','AEIds[66]').replace('i<63','i<66')
 s=s.replace('-AERank(s->aeMasks[slot],59);','-AERank(s->aeMasks[slot],59)-AERank(s->aeMasks[slot],63)-AERank(s->aeMasks[slot],64)-AERank(s->aeMasks[slot],65);')
 s=rep(s,'    if(s->modern && n->id==31349)', '''    if(s->modern && (n->id==6381 || n->id==12048 || n->id==11323))
    {
        level=10;
        auto mask=s->aeMasks[slot];
        ae=AERank(mask,0)+AERank(mask,1)+AERank(mask,2)+AERank(mask,3)+AERank(mask,4)+AERank(mask,5)+AERank(mask,39)+AERank(mask,60);
    }
    if(s->modern && n->id==31349)''')
 return s
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talents)
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return spell==9003452','return spell==9003850 || spell==9003851 || spell==9003852 || spell==9003452'))
def meta(s):
 for id,_,_,_ in nodes:
  s,n=re.subn(r'(\{'+str(id)+r',[^\n]*?),false,',r'\1,true,',s);assert n==1
 return s
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',meta)
def gameplay(s):
 anchor='        // ThreatManager calls SPELLMOD_THREAT only for spell-generated threat.'
 code='''        // WD113: explicit positive matching; SpellInfo rejects all other targets.
        uint32 const base=WD59A::FamilyBase(check->Id);
        if(mod->spellId==9003850)
        {
            if(mod->op==SPELLMOD_COST)
                return !(base==9003140 || base==9003180 || base==9003190 ||
                         base==9003280 || base==9003290 || base==9003300);
            if(mod->op==SPELLMOD_ALL_EFFECTS)
                return !(base==9003180 || base==9003300);
            return true;
        }
        if(mod->spellId==9003851 && mod->op==SPELLMOD_EFFECT1)
            return check->Id!=9003240;
        if(mod->spellId==9003852 && mod->op==SPELLMOD_COST)
            return !(base==9003150 || base==9003200 || base==9003210 ||
                     base==9003220 || check->Id==WD88A::Jinx);
'''
 return rep(s,anchor,code+anchor)
edit(SF+SRC+'RebornWitchDoctor.cpp',gameplay)
edit(SF+'src/server/game/Spells/SpellInfo.cpp',lambda s:rep(s,'        case 9003830:', '        case 9003850: // WD113: exact Wuju cost / Power Wuju amount\n        case 9003851: // WD113: Hexbreak first effect only\n        case 9003852: // WD113: Jinx cost only\n        case 9003830:'))
effects=['巫祝技能耗蓝降低50%；力量巫祝效果提高20%。包括已移植的强效巫祝。','破咒术额外尝试移除一个诅咒，与黑暗魔精互斥。','倦怠、希里克、法力、缩小及恶毒诅咒耗蓝降低25%；不影响其他巫毒伤害或治疗技能。']
eneffects=['Wuju mana cost -50%; Power Wuju effectiveness +20%, including supported Greater Wujus.','Hexbreak attempts to remove one additional curse; exclusive with Dark Mojo.','Supported Jinx mana cost -25%; does not affect other damage/healing spells.']
foundation='rank(29744)+rank(6054)+rank(6047)+rank(7092)+rank(29309)+rank(29301)+rank(7088)+rank(6030)'
def lua(s):
 s=rep(s,'[29753]=62}','[29753]=62,[6381]=63,[12048]=64,[11323]=65}')
 s=rep(s,'[29753]=1}','[29753]=1,[6381]=1,[12048]=1,[11323]=1}')
 s=s.replace('MaskFits(mask,72)','MaskFits(mask,75)')
 s=s.replace('(i>=58 and i<=60) then','(i>=58 and i<=60) or (i>=63 and i<=65) then')
 s=s.replace('-rank(30891)<9','-rank(30891)-rank(6381)-rank(12048)-rank(11323)<9')
 s=s.replace('-M.AERank(30891)>=9','-M.AERank(30891)-M.AERank(6381)-M.AERank(12048)-M.AERank(11323)>=9')
 s=rep(s,' if rank(31154)>0 then',f''' if (rank(6381)>0 or rank(12048)>0 or rank(11323)>0) and {foundation}<9 then return false,"先投入9点基础AE；同层不能互相凑点" end
 if rank(12048)>0 and rank(6048)>0 then return false,"希里克的祝福与黑暗魔精二选一" end
 if rank(31154)>0 then''')
 s=rep(s,'local function PathReady(id)','''local function PathReady(id)
 if id==6381 or id==12048 or id==11323 then return M.AERank(29744)+M.AERank(6054)+M.AERank(6047)+M.AERank(7092)+M.AERank(29309)+M.AERank(29301)+M.AERank(7088)+M.AERank(6030)>=9 end''')
 text='\n'
 for (id,spell,zh,en),eff,eng in zip(nodes,effects,eneffects):
  text+=f'details[{id}]={{zh="{zh}",en="{en}",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{{{"{eff}","{eng}"}}}},limit={{"保存并激活后生效；既有增益需重新施放。","Active saved build only; recast existing buffs."}},path={{"9点基础AE后花1 AE；同层不计前置。","Nine foundation AE, then one AE."}}}}\n'
 return rep(s,'local function Pair(',text+'local function Pair(')
edit(CF+ADD+'Allocation.lua',lua)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',72)',',75)'))
edit(CF+ADD+'Progress.lua',lambda s:rep(s,'RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n'+''.join(f' [{id}]={{name="{zh}",spells={{{spell}}}}},\n'for id,spell,zh,en in nodes)))
s=(B/'server_SQL/01_CHARACTERS_WD112A_必须执行.sql').read_text(encoding='utf8').replace('wd112_schema','wd113_schema').replace('WD112A','WD113A')
s=s.replace('6030,7132,29753)','6030,7132,29753,6381,12048,11323)')
s=rep(s,' DECLARE r62 INT DEFAULT 0;',' DECLARE r62 INT DEFAULT 0;\n'+''.join(f' DECLARE r{i} INT DEFAULT 0;\n'for i in range(63,66)))
s=s.replace(str(2**72-1),str(2**75-1))
s=rep(s,f'SET r62=MOD(FLOOR(p_mask/{2**71}),2);',f'SET r62=MOD(FLOOR(p_mask/{2**71}),2);'+''.join(f'SET r{i}=MOD(FLOOR(p_mask/{2**(i+9)}),2);'for i in range(63,66)))
s=s.replace('r59+r60>v_ae','r59+r60+r63+r64+r65>v_ae')
s=rep(s,' IF r58<>0 THEN', ' IF (r64<>0 AND r48<>0) OR ((r63<>0 OR r64<>0 OR r65<>0) AND r0+r1+r2+r3+r4+r5+r39+r60<9) THEN SET p_result=5;LEAVE main;END IF;\n IF r58<>0 THEN') if ' IF r58<>0 THEN' in s else s
# Place validation before any mutation, following existing invalid-mask branch.
anchor=' IF r58<>0 OR ((r58<>0 OR r59<>0)'
assert anchor in s
s=rep(s,anchor,' IF r58<>0 OR (r64<>0 AND r48<>0) OR ((r63<>0 OR r64<>0 OR r65<>0) AND r0+r1+r2+r3+r4+r5+r39+r60<9) OR ((r58<>0 OR r59<>0)')
s=rep(s,f'WHEN 29753 THEN node_rank*{2**71} END',f'WHEN 29753 THEN node_rank*{2**71} '+''.join(f'WHEN {n[0]} THEN node_rank*{2**(i+72)} 'for i,n in enumerate(nodes))+'END')
s=rep(s,f'OR r62<MOD(FLOOR(v_saved/{2**71}),2)',f'OR r62<MOD(FLOOR(v_saved/{2**71}),2)'+''.join(f' OR r{i}<MOD(FLOOR(v_saved/{2**(i+9)}),2)'for i in range(63,66)))
s=rep(s,' IF r62>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29753,r62);END IF;',' IF r62>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29753,r62);END IF;\n'+''.join(f' IF r{i+63}>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,{n[0]},r{i+63});END IF;\n'for i,n in enumerate(nodes)))
# Enrollment migration recognizes these Class nodes without changing old rows.
s=s.replace('30891,6030)','30891,6030,6381,12048,11323)').replace('30891,6030,4004','30891,6030,6381,12048,11323,4004')
put('server_SQL/01_CHARACTERS_WD113A_必须执行.sql',s)
print('WD113 source, allocation, UI and SQL prepared')

