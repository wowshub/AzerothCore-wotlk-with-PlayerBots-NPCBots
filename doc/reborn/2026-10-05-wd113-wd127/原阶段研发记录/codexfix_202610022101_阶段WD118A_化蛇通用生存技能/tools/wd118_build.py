from pathlib import Path
import shutil,re,json,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd117_path.txt').read_text(encoding='utf8'));P=Path(Path('wd118_path.txt').read_text(encoding='utf8'));C=R/'beascendclient/newrebornWOWli20260929beAscend'
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def edit(rel,fn):
 raw=(P/rel).read_bytes();put('rollback_WD117/'+rel,raw);put(rel,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def alloc(s):
 s=s.replace('AEIds[70]','AEIds[71]').replace('index<70','index<71').replace('index==70','index==71').replace('i<70','i<71').replace('mask>>80','mask>>81').replace('AEMask(1)<<80','AEMask(1)<<81')
 s=rep(s,'    if(index==69)', '    if(index==70) return static_cast<uint32>((mask>>80)&1u);\n    if(index==69)')
 s=rep(s,'6042,9347};','6042,9347,29306};')
 s=s.replace('+AERank(mask,69);','+AERank(mask,69)+AERank(mask,70);').replace('-AERank(mask,69)<9','-AERank(mask,69)-AERank(mask,70)<9').replace('|| AERank(mask,69))','|| AERank(mask,69) || AERank(mask,70))')
 s=rep(s,'    if((AERank(mask,52)', '    if(AERank(mask,70) && level<30) return false;\n    if((AERank(mask,52)')
 s=rep(s,'<<(index>=52?', '<<(index==70?80:index>=52?')
 block='''    // WD118: parent removal owns avoidance cleanup; do not leave either aura behind.
    if(!AERank(mask,70))
    {
        p->RemoveAurasDueToSpell(9003859,p->GetGUID());
        p->RemoveAurasDueToSpell(9003860,p->GetGUID());
        if(p->HasSpell(9003859)) p->removeSpell(9003859,3,false);
    }
    else if(!p->HasSpell(9003859)) p->learnSpell(9003859);
'''
 s=rep(s,'    // WD117: no stale',block+'    // WD117: no stale')
 return s.replace('for(uint32 spell:{9003857u,','for(uint32 spell:{9003859u,9003860u,9003857u,')
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
def talents(s):
 s=s.replace('AEIds[70]','AEIds[71]').replace('i<70','i<71').replace('-AERank(s->aeMasks[slot],69);','-AERank(s->aeMasks[slot],69)-AERank(s->aeMasks[slot],70);')
 # Include in the common foundation calculation, then retain donor level 30.
 s=s.replace('n->id==9347))\n    {','n->id==9347 || n->id==29306))\n    {')
 s=rep(s,'    if(s->modern && n->id==31349)', '    if(s->modern && n->id==29306) level=30;\n    if(s->modern && n->id==31349)')
 s=s.replace('bool const allowed=walkerTarget ||','bool const allowed=id==9003859 || walkerTarget ||')
 return s
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',talents)
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',lambda s:s.replace('{29306,3,0,1,1,0,9,0,0,false,','{29306,3,30,1,1,0,9,0,0,true,'))
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:s.replace('return spell==9003857','return spell==9003859 || spell==9003860 || spell==9003857'))
code='''
// WD118: native speed, transform, pacify/silence; helper follows the parent lifetime.
class aura_reborn_wd118_slither : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd118_slither);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003860}); }
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        Unit* unit=GetTarget();
        unit->RemoveMovementImpairingAuras(true);
        unit->AttackStop();
        unit->CastSpell(unit,9003860,true);
    }
    void Remove(AuraEffect const*,AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(9003860,GetCasterGUID());
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd118_slither::Apply,EFFECT_0,SPELL_AURA_MOD_INCREASE_SPEED,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd118_slither::Remove,EFFECT_0,SPELL_AURA_MOD_INCREASE_SPEED,AURA_EFFECT_HANDLE_REAL);
    }
};
'''
def gameplay(s):
 s=rep(s,'    reborn_wd60a_brewing_mods() : GlobalScript("reborn_wd60a_brewing_mods") { }','''    reborn_wd60a_brewing_mods() : GlobalScript("reborn_wd60a_brewing_mods") { }
    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        // Upstream PR6192: keep pacify/silence; make the self buff cancellable.
        if(info && (info->Id==9003859 || info->Id==9003860)) info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE;
    }
''')
 s=rep(s,'class reborn_wd117_heal',code+'\nclass reborn_wd117_heal')
 s=s.replace('    new reborn_wd117_heal();','    new reborn_wd117_heal();\n    RegisterSpellScript(aura_reborn_wd118_slither);')
 return s
edit(SF+SRC+'RebornWitchDoctor.cpp',gameplay)
def ui(s):
 s=s.replace('[9347]=69}','[9347]=69,[29306]=70}').replace('[9347]=2}','[9347]=2,[29306]=1}').replace('MaskFits(mask,80)','MaskFits(mask,81)').replace('i<=69','i<=70')
 s=rep(s,'local function Shift(i) return ', 'local function Shift(i) return i==70 and 80 or ')
 s=s.replace('+M.AERank(9347,mask)','+M.AERank(9347,mask)+M.AERank(29306,mask)').replace('-rank(9347)<9','-rank(9347)-rank(29306)<9').replace('-M.AERank(9347)>=9','-M.AERank(9347)-M.AERank(29306)>=9').replace('rank(9347)>0) and','rank(9347)>0 or rank(29306)>0) and')
 s=rep(s,' if (rank(6381)>0', ' if rank(29306)>0 and M.level<30 then return false,"化蛇需要角色等级30" end\n if (rank(6381)>0')
 s=rep(s,' if id==6381 or', ' if id==29306 then return M.level>=30 and M.AERank(29744)+M.AERank(6054)+M.AERank(6047)+M.AERank(7092)+M.AERank(29309)+M.AERank(29301)+M.AERank(7088)+M.AERank(6030)+M.AERank(31118)>=9 end\n if id==6381 or')
 detail='''details[29306]={zh="化蛇",en="Slither",level=30,early="等级30；先投9 AE",kind="通用主动 / Class active",effects={{"化为蛇，解除已有定身/减速；移动速度提高80%，持续5秒。远程攻击与法术命中率降低100个百分点，游泳速度提高80%。冷却60秒。","Transform into a serpent, remove existing roots/snares, +80% movement for 5 sec; ranged/spell hit chance -100 percentage points, +80% swim speed. 60 sec cooldown."}},limit={"期间不能攻击或施法；可右键取消。不免疫近战、已有持续伤害或后续控制。","Cannot attack/cast; right-click to cancel. Not immune to melee, existing periodic damage or subsequent control."},path={"等级30，9点基础AE后花1 AE；保存并激活。","Level 30, nine foundation AE then one AE; save and activate."}}
'''
 return rep(s,'local function Pair(',detail+'local function Pair(')
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',80)',',81)'))
edit(CF+ADD+'Progress.lua',lambda s:s.replace('RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [29306]={name="化蛇",spells={9003859}},'))
edit(CF+ADD+'NumericTooltip.lua',lambda s:s.replace('allowed[9003855]=true;','allowed[9003859]=true;allowed[9003855]=true;'))
sql=(B/'server_SQL/01_CHARACTERS_WD117A_必须执行.sql').read_text(encoding='utf8').replace('wd117_schema','wd118_schema').replace('WD117A','WD118A')
sql=sql.replace('6042,9347)','6042,9347,29306)').replace('6042,9347,4004','6042,9347,29306,4004').replace(str(2**80-1),str(2**81-1))
sql=rep(sql,' DECLARE r69 INT DEFAULT 0;',' DECLARE r69 INT DEFAULT 0;\n DECLARE r70 INT DEFAULT 0;')
sql=rep(sql,f'SET r69=MOD(FLOOR(p_mask/{2**78}),4);',f'SET r69=MOD(FLOOR(p_mask/{2**78}),4);SET r70=MOD(FLOOR(p_mask/{2**80}),2);')
sql=sql.replace('r68+r69>v_ae','r68+r69+r70>v_ae').replace('OR r69<>0)','OR r69<>0 OR r70<>0)')
sql=rep(sql,' IF r69>2 OR', ' IF r70<>0 AND p_level<30 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;\n IF r69>2 OR')
sql=rep(sql,f'WHEN 9347 THEN node_rank*{2**78} END',f'WHEN 9347 THEN node_rank*{2**78} WHEN 29306 THEN node_rank*{2**80} END')
sql=sql.replace(f'OR r69<MOD(FLOOR(v_saved/{2**78}),4)',f'OR r69<MOD(FLOOR(v_saved/{2**78}),4) OR r70<MOD(FLOOR(v_saved/{2**80}),2)')
sql=rep(sql,' IF r69>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,9347,r69);END IF;',' IF r69>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,9347,r69);END IF;\n IF r70>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29306,r70);END IF;')
put('server_SQL/01_CHARACTERS_WD118A_必须执行.sql',sql);(P/'server_SQL/01_CHARACTERS_WD117A_必须执行.sql').unlink()
put('server_SQL/02_WORLD_WD118A_必须执行.sql',"-- No character data or creature templates are modified.\nINSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES (9003859,'aura_reborn_wd118_slither');\n")
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
node=(P/'research/node.txt').read_text(encoding='utf8');icon=re.search(r'\["Icon"\]="([^"]+)"',node)[1].replace('\\\\','\\');put(CF+icon.replace('\\','/')+'.blp',(C/(icon.replace('\\','/')+'.blp')).read_bytes())
donor=json.loads((P/'research/donor.json').read_text(encoding='utf8'))
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(P/prefix/'Spell.dbc').read_bytes();put('rollback_WD117/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw)
 for sid,source in [(9003859,500947),(9003860,806295)]:
  assert sid not in rows;r=rows[9003855].copy();d=donor[str(source)]['row'];r[0]=sid
  r[1:28]=[0]*27;r[4:12]=d[4:12] if sid==9003859 else [128,0,0,0,0,0,0,0]
  r[28]=1;r[29]=60000 if sid==9003859 else 0;r[30]=0;r[31:38]=[0]*7;r[38]=r[39]=30;r[40]=28;r[41:46]=d[41:46] if sid==9003859 else [0]*5;r[46]=1
  r[71:122]=d[71:122];r[131:133]=[0,0];r[133]=910119;r[204]=d[204] if sid==9003859 else 0;r[205:207]=[133,1500] if sid==9003859 else [0,0];r[208:212]=[0]*4;r[225]=d[225]
  # Cumulative baseline columns outside copied ranges cannot leave cooldown proc or coefficients.
  r[229:232]=[0]*3
  desc='化为蛇，解除已有定身和减速，移动速度提高80%，持续5秒；不能攻击或施法，可右键取消。远程攻击与法术命中率降低100个百分点，游泳速度提高80%。不免疫近战、已有持续伤害或后续控制。冷却60秒。 / Serpent form for 5 sec; remove roots/snares; +80% speed, no attacks/casts. Ranged/spell hit chance -100 points; +80% swim speed. 60 sec cooldown.' if sid==9003859 else '化蛇期间远程攻击及法术命中率降低100个百分点，游泳速度提高80%。'
  for st,text in [(136,'化蛇 / Slither'),(153,''),(170,desc),(187,desc)]:
   off=len(pool);pool+=text.encode()+b'\0';r[st:st+16]=[off]*16
  rows[sid]=r
 for r in rows.values():
  for st in [136,153,170,187]:assert all(off<len(pool) and pool.find(b'\0',off)>=0 for off in r[st:st+16])
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(P/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD117/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw);assert not any(r[2] in [9003859,9003860] for r in rows.values());r=next(r[:] for r in rows.values() if r[2]==9003855);r[0]=max(rows)+1;r[2]=9003859;rows[r[0]]=r;put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(P/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD117/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw);assert 910119 not in rows;rows[910119]=[910119,len(pool)];pool+=icon.encode()+b'\0';put(prefix+'/SpellIcon.dbc',pack(rows,pool))
print('WD118 built, tests pending')
