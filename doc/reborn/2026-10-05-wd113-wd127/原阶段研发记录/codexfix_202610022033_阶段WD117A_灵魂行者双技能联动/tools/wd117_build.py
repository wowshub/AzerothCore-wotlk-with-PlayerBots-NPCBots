from pathlib import Path
import shutil,re,json,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd116_path.txt').read_text(encoding='utf8'));P=Path(Path('wd117_path.txt').read_text(encoding='utf8'))
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def edit(rel,fn):
 old=(P/rel).read_bytes();put('rollback_WD116/'+rel,old);put(rel,fn(old.decode('utf-8-sig').replace('\r\n','\n')))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def alloc(s):
 s=s.replace('AEIds[69]','AEIds[70]').replace('index<69','index<70').replace('index==69','index==70').replace('i<69','i<70').replace('mask>>78','mask>>80').replace('AEMask(1)<<78','AEMask(1)<<80')
 s=rep(s,'    if(index>=52)', '    if(index==69) return static_cast<uint32>((mask>>78)&3u);\n    if(index>=52)')
 s=s.replace('12264,6042};','12264,6042,9347};').replace('+AERank(mask,68);','+AERank(mask,68)+AERank(mask,69);')
 s=s.replace('-AERank(mask,68)<9','-AERank(mask,68)-AERank(mask,69)<9').replace('|| AERank(mask,68))','|| AERank(mask,68) || AERank(mask,69))')
 s=s.replace('if(AERank(mask,58) ||','if(AERank(mask,69)>2 || AERank(mask,58) ||')
 s=s.replace('rank>((index==2 ||','rank>((index==69 || index==2 ||')
 block='''    // WD117: no stale strengthened guardian/aura may survive a rank change.
    uint32 const walker=AERank(mask,69);
    uint32 const previous=p->HasSpell(9003858)?2u:(p->HasSpell(9003857)?1u:0u);
    if(previous!=walker)
    {
        p->RemoveAurasDueToSpell(9003855,p->GetGUID());
        WD117ClearSwift(p);
    }
    for(int tier=2;tier>=1;--tier)
    {
        uint32 const id=9003856+uint32(tier);
        if(walker!=uint32(tier))
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
    }
    if(walker)
    {
        uint32 const id=9003856+walker;
        if(!p->HasSpell(id)) p->learnSpell(id);
        if(!p->HasAura(id)) p->CastSpell(p,id,true);
    }
'''
 s=rep(s,'    // WD116: active saved Class ownership.',block+'    // WD116: active saved Class ownership.')
 return s.replace('for(uint32 spell:{9003855u,','for(uint32 spell:{9003857u,9003858u,9003855u,')
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
put(SF+SRC+'RebornWitchDoctorSpiritWalker.h','''#ifndef REBORN_WD117_SPIRIT_WALKER_H
#define REBORN_WD117_SPIRIT_WALKER_H
#include "Player.h"
namespace WD117
{
inline uint32 Bonus(Unit const* unit)
{
    Player const* p=unit?unit->ToPlayer():nullptr;
    if(!p) return 0;
    if(p->HasSpell(9003858) && p->HasAura(9003858)) return 20;
    return p->HasSpell(9003857) && p->HasAura(9003857)?10:0;
}
inline uint32 Duration(Unit const* unit) { return 10000*(100+Bonus(unit))/100; }
inline int32 SwiftAmount(Unit const* unit) { return int32(25*(100+Bonus(unit))/100); }
}
#endif
''')
def talents(s):
 s=s.replace('#include "SpellInfo.h"','#include "SpellInfo.h"\n#include "RebornWitchDoctorSpiritWalker.h"')
 s=s.replace('void WD111ClearExtra(Player*);','void WD111ClearExtra(Player*);\nvoid WD117ClearSwift(Player*);')
 s=s.replace('AEIds[69]','AEIds[70]').replace('i<69','i<70').replace('-AERank(s->aeMasks[slot],68);','-AERank(s->aeMasks[slot],68)-AERank(s->aeMasks[slot],69);').replace('n->id==6042))','n->id==6042 || n->id==9347))')
 s=s.replace('bool const allowed=wuju || jinx || base==9003240 || base==9003101;','bool const walkerTarget=id==9003855 || id==9003432;\n    bool const allowed=walkerTarget || wuju || jinx || base==9003240 || base==9003101;')
 anchor='    int32 const cost=p->GetCommandStatus(CHEAT_POWER)?0:info->CalcPowerCost(p,info->GetSchoolMask());'
 code='''    if(walkerTarget)
    {
        int32 const amount=id==9003855 ? -p->CalculateSpellDamage(p,info,EFFECT_0) : WD117::SwiftAmount(p);
        uint32 const healing=id==9003855 ? 2*(100+WD117::Bonus(p)) : 0;
        h->PSendSysMessage("WD114|{}|{}|ok|0|{}|{}|{}|{}|{}",sequence,id,WD117::Duration(p),amount,s->revision,s->active,healing);
        return true;
    }
'''
 return rep(s,anchor,code+anchor)
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talents)
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',lambda s:re.sub(r'(\{9347,[^\n]*?),false,',r'\1,true,',s))
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:s.replace('return spell==9003855','return spell==9003857 || spell==9003858 || spell==9003855'))
edit(SF+'src/server/game/Spells/SpellInfo.cpp',lambda s:s.replace('        case 9003854:', '        case 9003857: case 9003858: // WD117 exact Vigil targets only\n        case 9003854:'))
def gameplay(s):
 s=s.replace('#include "SpellInfo.h"','#include "SpellInfo.h"\n#include "RebornWitchDoctorSpiritWalker.h"\n#include "ScriptDefines/UnitScript.h"\n#include <limits>')
 s=rep(s,'cfg->entry==900202 ? 11000 : 61000','cfg->entry==900202 ? WD117::Duration(player)+1000 : 61000')
 s=rep(s,'ObjectGuid owner; WD38A::Config const* cfg=nullptr;','ObjectGuid owner; WD38A::Config const* cfg=nullptr;\n        int32 swiftAmount=25;')
 s=rep(s,'if(cfg->entry==900202)remaining=10000;','if(cfg->entry==900202) { remaining=WD117::Duration(player);swiftAmount=WD117::SwiftAmount(player); }')
 s=rep(s,'else me->CastSpell(unit,cfg->aura,true,nullptr,nullptr,owner);','else if(cfg->entry==900202) me->CastCustomSpell(unit,cfg->aura,&swiftAmount,&swiftAmount,&swiftAmount,true,nullptr,nullptr,owner);\n                        else me->CastSpell(unit,cfg->aura,true,nullptr,nullptr,owner);')
 s=rep(s,'        if(mod->spellId==9003854 && mod->op==SPELLMOD_THREAT) return false;','''        if(mod->spellId==9003857 || mod->spellId==9003858)
            return check->Id!=9003855 || (mod->op!=SPELLMOD_DURATION && mod->op!=SPELLMOD_EFFECT1);
        if(mod->spellId==9003854 && mod->op==SPELLMOD_THREAT) return false;''')
 code='''// WD117 scales actual health, not the integer "2 percent" spell base point.
class reborn_wd117_heal : public UnitScript
{
public:
    reborn_wd117_heal():UnitScript("reborn_wd117_heal") { }
    void ModifyHealReceived(Unit* a,Unit* b,uint32& heal,SpellInfo const* spell) override
    {
        if(!spell || spell->Id!=9003856 || !a || a!=b) return;
        heal=uint32(std::min<uint64>(std::numeric_limits<uint32>::max(),uint64(heal)*(100+WD117::Bonus(a))/100));
    }
};
namespace WD5A
{
void WD117ClearSwift(Player* p)
{
    Creature* idol=ObjectAccessor::GetCreature(*p,p->CustomData.GetDefault<WD36A::State>(WD36A::Key)->guid);
    if(idol && idol->GetEntry()==900202 && idol->GetOwnerGUID()==p->GetGUID()) WD36A::Clear(p);
}
}

'''
 s=rep(s,'void AddRebornWitchDoctorScripts()',code+'void AddRebornWitchDoctorScripts()')
 return rep(s,'void AddRebornWitchDoctorScripts()\n{','void AddRebornWitchDoctorScripts()\n{\n    new reborn_wd117_heal();')
edit(SF+SRC+'RebornWitchDoctor.cpp',gameplay)
def ui(s):
 s=s.replace('[6042]=68}','[6042]=68,[9347]=69}').replace('[6042]=1}','[6042]=1,[9347]=2}').replace('MaskFits(mask,78)','MaskFits(mask,80)').replace('i<=68','i<=69')
 s=s.replace('i==2 or i==13','i==69 or i==2 or i==13').replace('(M.AERank(6047,mask)>2','(M.AERank(9347,mask)>2 or M.AERank(6047,mask)>2')
 s=s.replace('-rank(6042)<9','-rank(6042)-rank(9347)<9').replace('-M.AERank(6042)>=9','-M.AERank(6042)-M.AERank(9347)>=9').replace('rank(6042)>0) and','rank(6042)>0 or rank(9347)>0) and').replace('or id==6042 then','or id==6042 or id==9347 then')
 s=s.replace('灵魂行者增强尚未开放。','可受灵魂行者增强，当前数值查看技能书。').replace('Spirit Walker is not yet enabled.','Spirit Walker applies; see spellbook for current values.')
 detail='''details[9347]={zh="灵魂行者",en="Spirit Walker",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{"沃金守望和迅捷神像的持续时间与效果提高10%。","Vigil and Swift Idol duration/effectiveness +10%."},{"沃金守望和迅捷神像的持续时间与效果提高20%。","Vigil and Swift Idol duration/effectiveness +20%."}},limit={"不缩短冷却、不增加范围；百分比光环数值按核心整数截断。变更等级会结束旧沃金守望/迅捷神像，需要重新施放。","No cooldown/range change. Percentage aura amounts truncate to integers. Rank changes end existing Vigil/Swift Idol; recast."},path={"9点基础AE后，每级1 AE；同层不能凑前置。","Nine foundation AE; one AE per rank; no same-tier bootstrap."}}
'''
 return rep(s,'local function Pair(',detail+'local function Pair(')
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',78)',',80)'))
edit(CF+ADD+'Progress.lua',lambda s:s.replace('RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [9347]={name="灵魂行者",spells={9003857,9003858}},'))
def numeric(s):
 s=s.replace('local en=GetLocale()', 'allowed[9003855]=true;allowed[9003432]=true\nlocal en=GetLocale()')
 s=s.replace('if power[id] or id==9003240 then','if power[id] or id==9003240 or id==9003855 or id==9003432 then')
 s=s.replace('   if power[id] then text=', '''   if id==9003855 then
    text=en and string.format("Current: %.1f sec; damage taken -%d%%; base healing %.2f%% max health/sec",value.a/1000,value.b,(value.c or 200)/100) or string.format("当前：%.1f秒；减伤%d%%；基础每秒恢复%.2f%%最大生命",value.a/1000,value.b,(value.c or 200)/100)
   elseif id==9003432 then
    text=en and string.format("Current: %.1f sec; speed and root/snare resistance +%d%%",value.a/1000,value.b) or string.format("当前：%.1f秒；移速、抵抗定身/减速提高%d%%",value.a/1000,value.b)
   elseif power[id] then text=''')
 old=' local cost,a,b,rev,active=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)$")'
 new=' local cost,a,b,rev,active,c=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)$")\n if not cost then cost,a,b,rev,active=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)$") end'
 s=rep(s,old,new).replace('cache[id]={cost=tonumber(cost),','cache[id]={c=tonumber(c),cost=tonumber(cost),')
 return s
edit(CF+ADD+'NumericTooltip.lua',numeric)
sql=(B/'server_SQL/01_CHARACTERS_WD116A_必须执行.sql').read_text(encoding='utf8').replace('wd116_schema','wd117_schema').replace('WD116A','WD117A')
sql=sql.replace('12264,6042)','12264,6042,9347)').replace('12264,6042,4004','12264,6042,9347,4004').replace('CASE node_id WHEN 7131','CASE node_id WHEN 9347 THEN 2 WHEN 7131')
sql=sql.replace(' DECLARE r68 INT DEFAULT 0;',' DECLARE r68 INT DEFAULT 0;\n DECLARE r69 INT DEFAULT 0;').replace(str(2**78-1),str(2**80-1))
sql=sql.replace(f'SET r68=MOD(FLOOR(p_mask/{2**77}),2);',f'SET r68=MOD(FLOOR(p_mask/{2**77}),2);SET r69=MOD(FLOOR(p_mask/{2**78}),4);')
sql=sql.replace('r67+r68>v_ae','r67+r68+r69>v_ae').replace('OR r68<>0)','OR r68<>0 OR r69<>0)').replace(' IF r58<>0',' IF r69>2 OR r58<>0')
sql=sql.replace(f'WHEN 6042 THEN node_rank*{2**77} END',f'WHEN 6042 THEN node_rank*{2**77} WHEN 9347 THEN node_rank*{2**78} END')
sql=sql.replace(f'OR r68<MOD(FLOOR(v_saved/{2**77}),2)',f'OR r68<MOD(FLOOR(v_saved/{2**77}),2) OR r69<MOD(FLOOR(v_saved/{2**78}),4)')
sql=sql.replace(' IF r68>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,6042,r68);END IF;',' IF r68>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,6042,r68);END IF;\n IF r69>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,9347,r69);END IF;')
put('server_SQL/01_CHARACTERS_WD117A_必须执行.sql',sql);(P/'server_SQL/01_CHARACTERS_WD116A_必须执行.sql').unlink()
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
C=R/'beascendclient/newrebornWOWli20260929beAscend';icon='Interface/AddOns/RebornWitchDoctorTalents/Icons/d3d8f35d3ff29325';put(CF+icon+'.blp',(C/(icon+'.blp')).read_bytes())
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(P/prefix/'Spell.dbc').read_bytes();put('rollback_WD116/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw)
 for rank,sid in enumerate([9003857,9003858],1):
  assert sid not in rows;r=rows[9003850].copy();r[0]=sid;r[133]=910118;r[71:74]=[6,6,0];r[95:98]=[108,108,0];r[80:83]=[rank*10-1,rank*10-1,0];r[110:113]=[1,3,0];r[208:212]=[0]*4;rows[sid]=r
  for start,text in [(136,'灵魂行者 / Spirit Walker'),(153,f'等级 {rank} / Rank {rank}'),(170,f'沃金守望与迅捷神像的持续时间和效果提高{rank*10}%。不缩短冷却，不增加范围。 / Vigil and Swift Idol duration and effectiveness +{rank*10}%; no cooldown or range change.'),(187,'')]:
   off=len(pool);pool+=text.encode()+b'\0';r[start:start+16]=[off]*16
 for sid in [9003855,9003432]:
  text='基础（未计灵魂行者）：'+pool[rows[sid][170]:].split(b'\0')[0].decode('utf8')+' 当前加成后数值见同步提示。 / Base values; current values shown below.'
  off=len(pool);pool+=text.encode()+b'\0';rows[sid][170:186]=[off]*16
 for r in rows.values():
  for st in [136,153,170,187]:assert all(off<len(pool) and pool.find(b'\0',off)>=0 for off in r[st:st+16])
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(P/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD116/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw)
 for sid in [9003857,9003858]:
  assert not any(r[2]==sid for r in rows.values());r=next(r[:] for r in rows.values() if r[2]==9003850);r[0]=max(rows)+1;r[2]=sid;rows[r[0]]=r
 put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(P/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD116/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw);assert 910118 not in rows;rows[910118]=[910118,len(pool)];pool+=icon.replace('/','\\').encode()+b'\0';put(prefix+'/SpellIcon.dbc',pack(rows,pool))
print('WD117 cumulative candidate built; tests pending.')
