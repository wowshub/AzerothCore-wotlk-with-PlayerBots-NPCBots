# coding: utf-8
from pathlib import Path
import shutil,json,struct,hashlib
from wd19_common import dbc
from wd9a_storm import Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');S=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots';C=R/'beascendclient/newrebornWOWli20261008beAscend';D=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261008Ascend'
B=Path(Path('wd136_path.txt').read_text().strip());P=Path(Path('wd137_path.txt').read_text().strip())
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
def put(n,b):
 p=P/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b if isinstance(b,bytes) else b.encode('utf8'))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def edit(n,fn):
 raw=(P/n).read_bytes();put('rollback/'+n,raw);put(n,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
def pack(r,p):
 f=len(next(iter(r.values())));return struct.pack('<4s4I',b'WDBC',len(r),f,f*4,len(p))+b''.join(struct.pack('<'+'I'*f,*v) for v in r.values())+p
for pre,live in [(SF,S),(CF,C)]:
 for f in (B/pre).rglob('*'):
  if f.is_file():
   rel=f.relative_to(B/pre)
   if rel.suffix.lower()!='.mpq':put(pre+rel.as_posix(),(live/rel).read_bytes())
put(SF+'src/server/game/Spells/SpellInfo.cpp',(S/'src/server/game/Spells/SpellInfo.cpp').read_bytes())
for f in (B/'server_SQL').glob('*.sql'):put('server_SQL/'+f.name,f.read_bytes())
a=Archive(C/'Data/patch-ZA.mpq');content={k:a.read(k) for k in a.read('(listfile)').decode().splitlines() if not k.startswith('(')};a.close()
for k,v in content.items():put('client_mpq输入_导入现有Patch-XA/'+k.replace('\\','/'),v)
a=Archive(C/'Data/Patch-XA.mpq')
for name in ['Spell.dbc','SpellIcon.dbc','SkillLineAbility.dbc','CreatureDisplayInfo.dbc']:
 out='client_mpq输入_导入现有Patch-XA/DBFilesClient/'+name
 if not (P/out).exists():put(out,a.read('DBFilesClient\\'+name))
 put('03_覆盖到服务端根目录/Data/dbc/'+name,(D/'Data/dbc'/name).read_bytes())
a.close()
# Saved-build node: index106, bit118; retain all previous bit positions.
def alloc(s):
 s=rep(s,'6027,13133,6026};','6027,13133,6026,29740};').replace('(mask>>118)!=0','(mask>>119)!=0').replace('(AEMask(1)<<118)-1','(AEMask(1)<<119)-1')
 s=rep(s,'!AERank(mask,105) || spec==1','!AERank(mask,105) && !AERank(mask,106) || spec==1')
 s=rep(s,'+AERank(mask,103)+AERank(mask,105);','+AERank(mask,103)+AERank(mask,105)+AERank(mask,106);')
 s=rep(s,'    uint32 const brewing134=','    if(AERank(mask,106) && (level<59 || !AERank(mask,105))) return false;\n    uint32 const brewing134=')
 s=rep(s,'    if(AERank(mask,105))','    if(AERank(mask,106)) { if(!p->HasSpell(9003957)) p->learnSpell(9003957); }\n    else { p->RemoveAurasDueToSpell(9003957,p->GetGUID()); if(p->HasSpell(9003957)) p->removeSpell(9003957,3,false); }\n    if(AERank(mask,105))')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',lambda s:rep(s.replace('AEIdCount=106','AEIdCount=107'),'    if(s->modern && n->id==6026)','    if(s->modern && n->id==29740) { level=59;missing=rank(6026)?0:1;te=rank(6026)?23:0; }\n    if(s->modern && n->id==6026)'))
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',lambda s:rep(s,'{29740,1,0,1,0,1,0,23,0,false,{}}','{29740,1,59,1,0,1,0,23,0,true,{6026}}'))
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return spell==9003954','return spell==9003957 || spell==9003954'))
def lua(s):
 s=rep(s,'[6026]=105}','[6026]=105,[29740]=106}');s=rep(s,'[6026]=1}','[6026]=1,[29740]=1}').replace('MaskFits(mask,118)','MaskFits(mask,119)')
 s=s.replace('M.BrewingSpent(mask)-rank(','M.BrewingSpent(mask)-rank(29740)-rank(')
 s=rep(s,'function M.BrewingSpent(mask) return ','function M.BrewingSpent(mask) return M.AERank(29740,mask)+')
 s=rep(s,' if rank(6026)>0',' if rank(29740)>0 and (M.level<59 or M.specs[M.slot+1]~=1 or rank(6026)==0) then return false,"需要59级、酿造方案和调制大师" end\n if rank(6026)>0')
 s=rep(s,' if id==6026 or id==30333',' if id==29740 or id==6026 or id==30333')
 return rep(s,'local function Pair(','''details[29740]={zh="调酒大师",en="Master Mixologist",level=59,early="59",kind="酿造主动 / Brewing active",effects={{"持续10秒，大锅中四种配料及投掷/泼洒附带的配料效果提高100%，期间可以移动施放瓶中之灵。2分钟冷却。","For 10 sec, Cauldron ingredient effects and delivered Ingredients gain 100% effectiveness; Spirit in a Bottle can be cast while moving. 2 min cooldown."}},limit={"按官方配料掩码限定蘑菇、鱼油、蛙骨与血蓟；不增加范围、持续时间、层数或药水直接治疗，不增强独立的大锅基底与调制大师吸血。","Ingredient whitelist only; no radius/duration/charge increase, direct potion healing, independent bases or Concoctions leech."},path={"59级、调制大师；再花1 TE。","Level 59 and Master of Concoctions; one additional TE."}}
local function Pair(''')
edit(CF+ADD+'Allocation.lua',lua)
edit(CF+ADD+'WD8.lua',lambda s:s.replace('MaskFits(a0,118)','MaskFits(a0,119)').replace('MaskFits(a1,118)','MaskFits(a1,119)').replace('MaskFits(a2,118)','MaskFits(a2,119)'))
edit(CF+ADD+'Progress.lua',lambda s:rep(s,' [6026]',' [29740]={name="调酒大师",spells={9003957}},\n [6026]'))
edit(CF+ADD+'Data.lua',lambda s:s+'\n-- WD137: official spell level59; previous node6026 remains required.\nfor _,n in ipairs(RebornWDTreeData) do if n.ID==29740 then n.RequiredLevel=59 end end\n')
def sql(s):
 s=s.replace('WD136A','WD137A').replace('reborn_wd136_schema','reborn_wd137_schema').replace('6027,13133,6026)','6027,13133,6026,29740)').replace(str(2**118-1),str(2**119-1))
 s=rep(s,' DECLARE r105 INT DEFAULT 0;',' DECLARE r105 INT DEFAULT 0;\n DECLARE r106 INT DEFAULT 0;')
 a=f' SET r105=MOD(FLOOR(p_mask/{2**117}),2);';s=rep(s,a,a+f'\n SET r106=MOD(FLOOR(p_mask/{2**118}),2);')
 s=rep(s,' IF r105<>0',' IF r106<>0 AND (p_level<59 OR r105=0) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;\n IF r105<>0')
 s=s.replace('+r103+r104+r105>0)','+r103+r104+r105+r106>0)')
 s=rep(s,'+r103+r105>v_te','+r103+r105+r106>v_te')
 a=' WHEN 6026 THEN node_rank*'+str(2**117);s=rep(s,a,a+f' WHEN 29740 THEN node_rank*{2**118}')
 s=rep(s,' IF r105<MOD',f' IF r106<MOD(FLOOR(v_saved/{2**118}),2) OR r105<MOD')
 a=' IF r105>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,6026,r105);END IF;';s=rep(s,a,a+'\n IF r106>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29740,r106);END IF;');return s
old='server_SQL/01_CHARACTERS_WD136A_必须执行.sql';put('rollback/'+old,(P/old).read_bytes());put('server_SQL/01_CHARACTERS_WD137A_必须执行.sql',sql((P/old).read_text(encoding='utf8')));(P/old).unlink()
# Exact native spell modifiers; no generic family fallback.
def mechanics(s):
 marker='        if(mod->spellId==9003914)'
 return rep(s,marker,'''        if(mod->spellId==9003957)
            return !((check->Id==9003866 && mod->op==SPELLMOD_DAMAGE) ||
                     ((check->Id==9003867 || check->Id==9003889) && mod->op==SPELLMOD_DOT) ||
                     (((check->Id>=9003902 && check->Id<=9003908 && check->Id!=9003905) || (check->Id>=9003916 && check->Id<=9003918)) && mod->op==SPELLMOD_ALL_EFFECTS));
'''+marker)
edit(SF+SRC+'RebornWitchDoctor.cpp',mechanics)
edit(SF+'src/server/game/Spells/SpellInfo.cpp',lambda s:rep(s,'        case 9003914:','        case 9003957: // WD137 exact four-ingredient boost\n        case 9003914:'))
def moving(s):
 marker='    if(!info || !(info->Id==9003822'
 return rep(s,marker,'''    // WD137: timed, owned Master Mixologist permits only Spirit in a Bottle ranks.
    Player const* mixer=caster?caster->ToPlayer():nullptr;
    if(info && info->Id>=9003460 && info->Id<=9003467 && mixer && mixer->IsAlive() &&
       mixer->getClass()==13 && mixer->HasSpell(9003957) && mixer->HasAura(9003957,mixer->GetGUID())) return true;
'''+marker)
edit(SF+'src/server/game/Spells/Spell.cpp',moving)
# Native periodic preparation refreshes Fish/Bones/Thistle every 1.5sec.
# Refresh at buff transition too, after the final spell modifier has changed.
inc='''// WD137: refresh prepared ingredient fields after native modifiers change.
class aura_reborn_wd137_master : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd137_master);
    void Refresh(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetTarget()?GetTarget()->ToPlayer():nullptr;
        if(!IsDoctor(p) || !p->IsAlive() || !p->IsInWorld()) return;
        uint32 const prep[3]={9003901,9003905,9003915},field[3]={9003902,9003906,9003916};
        for(uint32 i=0;i<3;++i) if(p->HasAura(prep[i],p->GetGUID())) p->CastSpell(p,field[i],true);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd137_master::Refresh,EFFECT_2,SPELL_AURA_ADD_PCT_MODIFIER,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd137_master::Refresh,EFFECT_2,SPELL_AURA_ADD_PCT_MODIFIER,AURA_EFFECT_HANDLE_REAL);
    }
};
'''
put(SF+SRC+'RebornWitchDoctorBrewing137.inc',inc)
edit(SF+SRC+'RebornWitchDoctor.cpp',lambda s:rep(rep(s,'#include "RebornWitchDoctorBrewing134.inc"','#include "RebornWitchDoctorBrewing134.inc"\n#include "RebornWitchDoctorBrewing137.inc"'),'    RegisterSpellScript(aura_reborn_wd129_thistle);','    RegisterSpellScript(aura_reborn_wd137_master);\n    RegisterSpellScript(aura_reborn_wd129_thistle);'))
world='''-- WD137A: run manually in WORLD after backing up. No other spell bindings removed.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd137_bind$$
CREATE PROCEDURE reborn_wd137_bind()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003957 AND ScriptName<>'aura_reborn_wd137_master') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD137 spell binding conflict';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003957 AND ScriptName='aura_reborn_wd137_master') THEN
  INSERT INTO spell_script_names(spell_id,ScriptName) VALUES(9003957,'aura_reborn_wd137_master');
 END IF;
END$$
CALL reborn_wd137_bind()$$
DROP PROCEDURE reborn_wd137_bind$$
DELIMITER ;
'''
put('server_SQL/14_WORLD_WD137A_必须执行.sql',world)
icon=ADD+'Icons/6e64f414c5e93979.blp';put(CF+icon,(C/icon).read_bytes());put('client_mpq输入_导入现有Patch-XA/'+icon,(C/icon).read_bytes())
for pre in ['client_mpq输入_导入现有Patch-XA/DBFilesClient','03_覆盖到服务端根目录/Data/dbc']:
 for name in ['Spell.dbc','SpellIcon.dbc','SkillLineAbility.dbc']:put('rollback/'+pre+'/'+name,(P/pre/name).read_bytes())
 ir,ip=dbc((P/pre/'SpellIcon.dbc').read_bytes());iid=max(ir)+1;ir[iid]=[iid,len(ip)];ip+=icon[:-4].replace('/','\\').encode()+b'\0';put(pre+'/SpellIcon.dbc',pack(ir,ip))
 r,pool=dbc((P/pre/'Spell.dbc').read_bytes());assert 9003957 not in r and 9003956 in r
 v=r[9003954].copy();v[0]=9003957;v[4:12]=[0]*8;v[28]=1;v[29:34]=[120000,0,0,0,0];v[34:37]=[0,0,0];v[37:40]=[0,59,59];v[40]=1;v[41:45]=[0]*4;v[46]=1;v[71:131]=[0]*60;v[71:74]=[6]*3;v[74:77]=[1]*3;v[80:83]=[99]*3;v[86:89]=[1]*3;v[95:98]=[108]*3;v[110:113]=[0,22,8];v[133]=iid;v[208:212]=[0]*4
 description='持续10秒，大锅配料与投掷/泼洒配料效果提高100%，可移动施放瓶中之灵。2分钟冷却。For 10 sec, Cauldron ingredient and delivered Ingredient effects gain 100% effectiveness; cast Spirit in a Bottle while moving.'
 for start,text in [(136,'调酒大师 / Master Mixologist'),(153,''),(170,description),(187,description)]:
  off=len(pool);pool+=text.encode('utf8')+b'\0';v[start:start+16]=[off]*16
 r[9003957]=v;put(pre+'/Spell.dbc',pack(r,pool))
 sr,sp=dbc((P/pre/'SkillLineAbility.dbc').read_bytes());v=next(v.copy() for v in sr.values() if v[2]==9003954);v[0]=max(sr)+1;v[2]=9003957;sr[v[0]]=v;put(pre+'/SkillLineAbility.dbc',pack(sr,sp))
print('WD137 candidate generated; originals unchanged')
