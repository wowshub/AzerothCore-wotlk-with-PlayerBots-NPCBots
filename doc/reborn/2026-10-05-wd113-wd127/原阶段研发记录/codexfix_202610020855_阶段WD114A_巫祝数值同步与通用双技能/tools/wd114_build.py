from pathlib import Path
import re,shutil,json,struct
import wd19_common as c
B=Path(Path('wd113_path.txt').read_text(encoding='utf8').strip());P=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip())
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def rep(s,a,b):
 assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def edit(rel,fn):
 old=(B/rel).read_bytes();put('rollback_WD113/'+rel,old);put(rel,fn(old.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[66]','AEIds[68]').replace('index<66','index<68').replace('index==66','index==68').replace('i<66','i<68').replace('mask>>75','mask>>77').replace('AEMask(1)<<75','AEMask(1)<<77')
 s=rep(s,'6381,12048,11323};','6381,12048,11323,31118,12264};')
 s=rep(s,'+AERank(mask,65);','+AERank(mask,65)+AERank(mask,66)+AERank(mask,67);')
 s=s.replace('-AERank(mask,65)<9','-AERank(mask,65)-AERank(mask,67)<9')
 s=s.replace('AERank(mask,64) || AERank(mask,65))','AERank(mask,64) || AERank(mask,65) || AERank(mask,67))')
 s=s.replace('+AERank(mask,60)<9','+AERank(mask,60)+AERank(mask,66)<9')
 s=rep(s,'    uint32 const class113[3]={9003850,9003851,9003852};','    uint32 const class113[3]={9003850,9003851,9003852};')
 anchor='''        else if(!p->HasSpell(class113[i])) p->learnSpell(class113[i]);'''
 s=rep(s,anchor,'''        else
        {
            if(!p->HasSpell(class113[i])) p->learnSpell(class113[i]);
            // Recover the permanent native modifier when restoring an active saved build.
            if(!p->HasAura(class113[i])) p->CastSpell(p,class113[i],true);
        }''')
 s=rep(s,'    bool wanted[8]=','''    for(uint32 i=0;i<2;++i)
    {
        uint32 const id=9003853+i;
        if(!AERank(mask,66+i))
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
        else
        {
            if(!p->HasSpell(id)) p->learnSpell(id);
            if(i==1 && !p->HasAura(id)) p->CastSpell(p,id,true);
        }
    }
    bool wanted[8]=''')
 s=s.replace('for(uint32 spell:{9003850u,','for(uint32 spell:{9003853u,9003854u,9003850u,')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
def talents(s):
 s=s.replace('AEIds[66]','AEIds[68]').replace('i<66','i<68').replace('-AERank(s->aeMasks[slot],65);','-AERank(s->aeMasks[slot],65)-AERank(s->aeMasks[slot],67);')
 s=s.replace('n->id==11323))','n->id==11323 || n->id==12264))').replace('+AERank(mask,60);','+AERank(mask,60)+AERank(mask,66);')
 s=rep(s,'    if(s->modern && n->id==31349)', '    if(s->modern && n->id==31118) level=10;\n    if(s->modern && n->id==31349)')
 s=rep(s,'    std::chrono::steady_clock::time_point auditRequest;', '    std::chrono::steady_clock::time_point numberRequest;\n    std::chrono::steady_clock::time_point auditRequest;')
 # Read-only, self-only, bounded whitelist. No Ready/Load/database call, no state mutation.
 code='''// WD114: tooltip uses the same cost/effect calculator as the cast itself.
bool SpellNumbers(ChatHandler* h,uint32 sequence,uint32 id)
{
    Player* p=h->GetSession()->GetPlayer();
    if(!Doctor(p)) return true;
    State* s=p->CustomData.GetDefault<State>(Key);
    auto const now=std::chrono::steady_clock::now();
    if(now-s->numberRequest<std::chrono::milliseconds(400)) return true;
    s->numberRequest=now;
    WD19A::Family const* family=WD19A::FindFamily(id);
    uint32 const base=family?family->ranks[0].spell:0;
    bool const wuju=base==9003140 || base==9003180 || base==9003190 || base==9003280 || base==9003290 || base==9003300;
    bool const jinx=base==9003150 || base==9003200 || base==9003210 || base==9003220 || id==9003762;
    bool const allowed=wuju || jinx || base==9003240 || base==9003101;
    SpellInfo const* info=sSpellMgr->GetSpellInfo(id);
    if(!Enabled() || !allowed || !info || !p->HasSpell(id) || !s->loaded)
    {
        h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true;
    }
    int32 const cost=p->GetCommandStatus(CHEAT_POWER)?0:info->CalcPowerCost(p,info->GetSchoolMask());
    // Only fixed-range effects: don't roll RNG just to display a tooltip.
    int32 a=0,b=0;
    if(base==9003180 || base==9003300 || base==9003240)
    {
        a=p->CalculateSpellDamage(p,info,EFFECT_0);
        if(base!=9003240) b=p->CalculateSpellDamage(p,info,EFFECT_1);
    }
    h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,a,b,s->revision,s->active);
    return true;
}

'''
 s=rep(s,'class Commands : public CommandScript',code+'class Commands : public CommandScript')
 s=rep(s,'            {"wdtestpoints",','            {"wd114numbers",SpellNumbers,SEC_PLAYER,Console::No},\n            {"wdtestpoints",')
 return s
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talents)
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return spell==9003850','return spell==9003853 || spell==9003854 || spell==9003850'))
def meta(s):
 for id in [31118,12264]:
  s,n=re.subn(r'(\{'+str(id)+r',[^\n]*?),false,',r'\1,true,',s);assert n==1
 return s
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',meta)
# Potent Mixes uses SPELLMOD_THREAT, restricted to actual spell calls, not white melee threat.
def gameplay(s):
 return rep(s,'        // WD113: explicit positive matching;', '        if(mod->spellId==9003854 && mod->op==SPELLMOD_THREAT) return false;\n        // WD113: explicit positive matching;')
edit(SF+SRC+'RebornWitchDoctor.cpp',gameplay)
edit(SF+'src/server/game/Spells/SpellInfo.cpp',lambda s:rep(s,'        case 9003850:', '        case 9003854: // WD114: Potent Mixes spell threat only\n        case 9003850:'))
def lua(s):
 s=rep(s,'[11323]=65}','[11323]=65,[31118]=66,[12264]=67}')
 s=rep(s,'[11323]=1}','[11323]=1,[31118]=1,[12264]=1}')
 s=s.replace('MaskFits(mask,75)','MaskFits(mask,77)').replace('i<=65','i<=67')
 s=s.replace('-rank(11323)<9','-rank(11323)-rank(12264)<9')
 s=s.replace('-M.AERank(11323)>=9','-M.AERank(11323)-M.AERank(12264)>=9')
 s=s.replace('rank(11323)>0) and','rank(11323)>0 or rank(12264)>0) and')
 s=s.replace('+rank(6030)<9','+rank(6030)+rank(31118)<9')
 s=s.replace('if id==6381 or id==12048 or id==11323 then','if id==6381 or id==12048 or id==11323 or id==12264 then')
 s=s.replace('+M.AERank(6030)>=9','+M.AERank(6030)+M.AERank(31118)>=9')
 # Keep the older preview eligibility aligned with the save validator, too.
 s=s.replace('-M.AERank(6048)>=9','-M.AERank(6048)-M.AERank(5113)-M.AERank(30891)-M.AERank(6381)-M.AERank(12048)-M.AERank(11323)-M.AERank(12264)>=9')
 t='''details[31118]={zh="假死药剂",en="Death Draught",level=10,early="10",kind="通用主动 / Class active",effects={{"进入假死，最多持续5分钟，30秒冷却。","Feign death for up to 5 minutes; 30 sec cooldown."}},limit={"沿用原生假死；不是无敌，副本中不保证脱战。移动/主动取消后恢复。","Native feign death, not immunity; dungeon combat may persist. Move or cancel to stand."},path={"10级花1 AE；本批不强制图中连线为技能前置。","Level 10 and one AE; graph connections are not extra prerequisites."}}
details[12264]={zh="强效混合",en="Potent Mixes",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{"治疗量提高4%；法术产生的威胁降低15%。","Healing done +4%; threat generated by spells -15%."}},limit={"不直接削减已有仇恨，不降低普通近战白字仇恨；保存激活后生效。","Does not erase existing threat or reduce white melee threat; active saved build only."},path={"9点基础AE后花1 AE；同层不能凑前置。","Nine foundation AE, then one AE; same-tier nodes do not count."}}
'''
 return rep(s,'local function Pair(',t+'local function Pair(')
edit(CF+ADD+'Allocation.lua',lua)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',75)',',77)'))
edit(CF+ADD+'Progress.lua',lambda s:rep(s,'RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [31118]={name="假死药剂",spells={9003853}},\n [12264]={name="强效混合",spells={9003854}},'))
s=(B/'server_SQL/01_CHARACTERS_WD113A_必须执行.sql').read_text(encoding='utf8').replace('wd113_schema','wd114_schema').replace('WD113A','WD114A')
s=s.replace('6381,12048,11323)','6381,12048,11323,31118,12264)').replace('6381,12048,11323,4004','6381,12048,11323,31118,12264,4004')
s=rep(s,' DECLARE r65 INT DEFAULT 0;',' DECLARE r65 INT DEFAULT 0;\n DECLARE r66 INT DEFAULT 0;\n DECLARE r67 INT DEFAULT 0;')
s=s.replace(str(2**75-1),str(2**77-1))
s=rep(s,f'SET r65=MOD(FLOOR(p_mask/{2**74}),2);',f'SET r65=MOD(FLOOR(p_mask/{2**74}),2);SET r66=MOD(FLOOR(p_mask/{2**75}),2);SET r67=MOD(FLOOR(p_mask/{2**76}),2);')
s=s.replace('r63+r64+r65>v_ae','r63+r64+r65+r66+r67>v_ae')
s=s.replace('r63<>0 OR r64<>0 OR r65<>0)','r63<>0 OR r64<>0 OR r65<>0 OR r67<>0)').replace('r0+r1+r2+r3+r4+r5+r39+r60<9','r0+r1+r2+r3+r4+r5+r39+r60+r66<9')
# Older Class thresholds use the equivalent explicit foundation sum.
s=s.replace('r0+r1+r2+r3+r4+r5+r39<9','r0+r1+r2+r3+r4+r5+r39+r66<9')
s=rep(s,f'WHEN 11323 THEN node_rank*{2**74} END',f'WHEN 11323 THEN node_rank*{2**74} WHEN 31118 THEN node_rank*{2**75} WHEN 12264 THEN node_rank*{2**76} END')
s=rep(s,f'OR r65<MOD(FLOOR(v_saved/{2**74}),2)',f'OR r65<MOD(FLOOR(v_saved/{2**74}),2) OR r66<MOD(FLOOR(v_saved/{2**75}),2) OR r67<MOD(FLOOR(v_saved/{2**76}),2)')
s=rep(s,' IF r65>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,11323,r65);END IF;',' IF r65>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,11323,r65);END IF;\n IF r66>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,31118,r66);END IF;\n IF r67>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,12264,r67);END IF;')
put('server_SQL/01_CHARACTERS_WD114A_必须执行.sql',s)
# Old cumulative SQL is retained in history only, not alongside the one users should install.
old=P/'server_SQL/01_CHARACTERS_WD113A_必须执行.sql'
if old.exists():old.unlink()
print('WD114 cumulative code, UI allocation and SQL prepared')
