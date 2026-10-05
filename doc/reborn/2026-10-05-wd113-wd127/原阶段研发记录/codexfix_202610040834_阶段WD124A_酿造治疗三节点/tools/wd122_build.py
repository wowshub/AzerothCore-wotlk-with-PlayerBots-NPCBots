from pathlib import Path
import shutil,re,json,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd121_path.txt').read_text());P=Path(Path('wd122_path.txt').read_text());Q=Path(Path('wd121b_path.txt').read_text())
C=R/'beascendclient/newrebornWOWli20260929beAscend';SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='Interface/AddOns/RebornWitchDoctorTalents/'
for sub in [SF,CF,'03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL','tools']:
 shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
shutil.copytree(Q/SF,P/SF,dirs_exist_ok=True)
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def rep(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def edit(rel,fn):
 raw=(P/rel).read_bytes();put('rollback_WD121A_B/'+rel,raw);put(rel,fn(raw.decode('utf-8-sig').replace('\r\n','\n')))
def alloc(s):
 s=s.replace('AEIds[79]','AEIds[81]').replace('index<79','index<81').replace('index==79','index==81').replace('i<79','i<81').replace('mask>>90','mask>>92').replace('AEMask(1)<<90','AEMask(1)<<92')
 s=rep(s,'6498,29303};','6498,29303,6020,29737};')
 s=rep(s,'+AERank(mask,77)+AERank(mask,78);','+AERank(mask,77)+AERank(mask,78)+AERank(mask,79)+AERank(mask,80);')
 s=rep(s,'!AERank(mask,78) || spec==1','!AERank(mask,78) && !AERank(mask,79) && !AERank(mask,80) || spec==1')
 s=rep(s,'if((AERank(mask,77) || AERank(mask,78))','if((AERank(mask,77) || AERank(mask,78) || AERank(mask,79) || AERank(mask,80))')
 s=rep(s,'    // WD121: tier-eight','    if(AERank(mask,79) && AERank(mask,80)) return false; // WD122 authored choice group 706545.\n    // WD121: tier-eight')
 s=rep(s,'{9003877u,9003878u,9003879u}','{9003877u,9003878u,9003879u,9003880u,9003881u}')
 s=rep(s,'uint32 const brewingPassives[3]={9003877,9003878,9003879};','bool const cadenceChanged=p->HasAura(9003881)!=(AERank(mask,80)>0);\n    uint32 const brewingPassives[5]={9003877,9003878,9003879,9003880,9003881};')
 s=rep(s,'bool const brewingWanted[3]={fresh==1,fresh==2,AERank(mask,78)>0};','bool const brewingWanted[5]={fresh==1,fresh==2,AERank(mask,78)>0,AERank(mask,79)>0,AERank(mask,80)>0};')
 s=s.replace('for(uint32 i=0;i<3;++i) if(!brewingWanted','for(uint32 i=0;i<5;++i) if(!brewingWanted').replace('for(uint32 i=0;i<3;++i) if(brewingWanted','for(uint32 i=0;i<5;++i) if(brewingWanted')
 s=rep(s,'    // WD120: preparation', '''    // WD122: update an already prepared ingredient on a saved-build cadence change.
    // Start a fresh interval, without an extra heal or reapplying the preparation.
    if(cadenceChanged)
        if(AuraEffect* effect=p->GetAuraEffect(9003865,EFFECT_0,p->GetGUID()))
        {
            effect->CalculatePeriodic(p);
            effect->SetPeriodicTimer(effect->GetAmplitude());
        }
    // WD120: preparation''')
 return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',lambda s:s.replace('AEIds[79]','AEIds[81]').replace('i<79','i<81').replace('n->id==6498 || n->id==29303','n->id==6498 || n->id==29303 || n->id==6020 || n->id==29737'))
def nodes(s):
 for n in [6020,29737]:
  s,k=re.subn(r'(\{'+str(n)+r',1,\d+,\d+,\d+,\d+,\d+,\d+,\d+,)false,',r'\1true,',s);assert k==1
 return s
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',nodes)
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'spell<=9003879','spell<=9003881'))
edit(SF+'src/server/game/Spells/SpellInfo.cpp',lambda s:rep(s,'case 9003877: case 9003878: case 9003879:','case 9003880: case 9003881: // WD122 exact pulse/cadence modifiers\n        case 9003877: case 9003878: case 9003879:'))
edit(SF+SRC+'RebornWitchDoctor.cpp',lambda s:rep(s,'        if(mod->spellId==9003877', '''        if(mod->spellId==9003880) return check->Id!=9003866 || mod->op!=SPELLMOD_DAMAGE;
        if(mod->spellId==9003881) return check->Id!=9003865 || mod->op!=SPELLMOD_ACTIVATION_TIME;
        if(mod->spellId==9003877'''))
edit(SF+SRC+'RebornWitchDoctorBrewingNumbers.h',lambda s:rep(s,'inline bool IsToss', '''// WD122: shared runtime / tooltip cap; private aura avoids donor family-mask leakage.
inline uint32 PulseTargets(Unit* caster) { return caster->HasAura(9003880)?5u:8u; }
inline bool IsToss'''))
edit(SF+SRC+'RebornWitchDoctorBrewingFoundation.inc',lambda s:rep(rep(s.replace('#include "RebornWitchDoctorBrewingNumbers.h"','#include "RebornWitchDoctorBrewingNumbers.h"\n#include "Containers.h"'),'    void Snapshot()', '''    void PulseTargets(std::list<WorldObject*>& targets)
    {
        if(GetSpellInfo()->Id==WD120A::Pulse)
            Acore::Containers::RandomResize(targets,WD120A::PulseTargets(GetCaster()));
    }
    void Snapshot()'''),'        OnCheckCast +=','        if(m_scriptSpellId==WD120A::Pulse)\n            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::PulseTargets,EFFECT_0,TARGET_UNIT_SRC_AREA_RAID);\n        OnCheckCast +='))
def numeric(s):
 return rep(s,'        h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active);', '''        if(pulse)
        {
            int32 interval=info->Effects[EFFECT_0].Amplitude;
            p->ApplySpellMod(id,SPELLMOD_ACTIVATION_TIME,interval);
            if(AuraEffect* effect=p->GetAuraEffect(id,EFFECT_0,p->GetGUID())) interval=effect->GetAmplitude();
            h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,interval,WD120A::PulseTargets(p));
        }
        else h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active);''')
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',numeric)
def ui(s):
 s=s.replace('[29303]=78}','[29303]=78,[6020]=79,[29737]=80}').replace('[29303]=1}','[29303]=1,[6020]=1,[29737]=1}').replace('MaskFits(mask,90)','MaskFits(mask,92)')
 s=rep(s,'function M.BrewingSpent(mask) return','function M.BrewingSpent(mask) return M.AERank(6020,mask)+M.AERank(29737,mask)+')
 s=s.replace('(rank(6498)>0 or rank(29303)>0)','(rank(6498)>0 or rank(29303)>0 or rank(6020)>0 or rank(29737)>0)')
 s=rep(s,' if rank(12646)>0 and',' if rank(6020)>0 and rank(29737)>0 then return false,"丛林绽放与丛林医师二选一" end\n if rank(12646)>0 and')
 s=s.replace('if id==6498 or id==29303 then','if id==6498 or id==29303 or id==6020 or id==29737 then')
 for n,zh,en,e,eng in [(6020,'丛林绽放','Jungle Booms','大锅丛林蘑菇单次治疗提高100%，每跳目标由8人降至5人；间隔仍为6秒。','Cauldron Shrooms healing +100%, target cap reduced from 8 to 5; interval remains 6 sec.'),(29737,'丛林医师','Doctor of the Jungle','大锅丛林蘑菇治疗间隔缩短2秒，由6秒变为4秒；目标上限仍为8人。','Cauldron Shrooms interval -2 sec, from 6 to 4 sec; target cap remains 8.')]:
  detail=f'details[{n}]={{zh={json.dumps(zh,ensure_ascii=False)},en={json.dumps(en)},level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{{{{json.dumps(e,ensure_ascii=False)},{json.dumps(eng)}}}}},limit={{"两者互斥；不影响投掷及其持续治疗；仅保存并激活后生效。","Mutually exclusive; excludes Potion Toss and its HoT; active saved build only."}},path={{"先投入8点基础酿造TE，再花1 TE；同层不计前置。","Eight foundation Brewing TE, then one TE; same-tier points excluded."}}}}\n'
  s=rep(s,'local function Pair(',detail+'local function Pair(')
 return s
edit(CF+ADD+'Allocation.lua',ui)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',90)',',92)'))
edit(CF+ADD+'Progress.lua',lambda s:rep(s,'RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [6020]={name="丛林绽放",spells={9003880}},\n [29737]={name="丛林医师",spells={9003881}},'))
def tooltip(s):
 s=rep(s,'local label=id==9003865 and "每6秒范围治疗 / Pulse per 6 sec: " or "直接治疗 / Direct heal: "','local label=id==9003865 and string.format("当前每%g秒，最多%d人 / Pulse every %g sec, up to %d allies: ",(value.c or 6000)/1000,value.d or 8,(value.c or 6000)/1000,value.d or 8) or "直接治疗 / Direct heal: "')
 s=rep(s,' local cost,a,b,rev,active,c=rest:match(', ' local cost,a,b,rev,active,c,d=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)|(%d+)$")\n if not cost then cost,a,b,rev,active,c=rest:match(')
 s=rep(s,'|(%d+)$")\n if not cost then cost,a,b,rev,active=rest:match','|(%d+)$") end\n if not cost then cost,a,b,rev,active=rest:match')
 s=rep(s,'cache[id]={c=tonumber(c),','cache[id]={d=tonumber(d),c=tonumber(c),')
 return s
edit(CF+ADD+'NumericTooltip.lua',tooltip)
sql=(B/'server_SQL/01_CHARACTERS_WD121A_必须执行.sql').read_text(encoding='utf8').replace('wd121_schema','wd122_schema').replace('WD121A','WD122A')
sql=sql.replace('6498,29303)','6498,29303,6020,29737)').replace(str(2**90-1),str(2**92-1))
for idx,node,shift in [(79,6020,90),(80,29737,91)]:
 sql=rep(sql,' DECLARE r78 INT DEFAULT 0;',f' DECLARE r{idx} INT DEFAULT 0;\n DECLARE r78 INT DEFAULT 0;')
 sql=rep(sql,' SET r0=v_low&1;',f' SET r{idx}=MOD(FLOOR(p_mask/{2**shift}),2);\n SET r0=v_low&1;')
 sql=rep(sql,'WHEN 29303 THEN node_rank*',f'WHEN {node} THEN node_rank*{2**shift} WHEN 29303 THEN node_rank*')
 sql=rep(sql,' IF r78<',f' IF r{idx}<MOD(FLOOR(v_saved/{2**shift}),2) OR r78<') if idx==79 else rep(sql,' IF r79<',f' IF r{idx}<MOD(FLOOR(v_saved/{2**shift}),2) OR r79<')
 sql=rep(sql,' IF r78>0 THEN',f' IF r{idx}>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,{node},r{idx});END IF;\n IF r78>0 THEN')
sql=sql.replace('r77+r78>v_te','r77+r78+r79+r80>v_te').replace('r76+r77+r78>0','r76+r77+r78+r79+r80>0').replace('(r77<>0 OR r78<>0)','(r77<>0 OR r78<>0 OR r79<>0 OR r80<>0)')
sql=rep(sql,' IF r77>2 OR',' IF r79<>0 AND r80<>0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;\n IF r77>2 OR')
put('server_SQL/01_CHARACTERS_WD122A_必须执行.sql',sql);(P/'server_SQL/01_CHARACTERS_WD121A_必须执行.sql').unlink()
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
icons=[]
for node in [6020,29737]:
 text=(P/f'research/node{node}.txt').read_text(encoding='utf8');icon=re.search(r'\["Icon"\]="([^"]+)"',text)[1].replace('\\\\','\\');icons.append(icon)
 path=icon.replace('\\','/')+'.blp';data=(C/path).read_bytes();put(CF+path,data);put('client_mpq输入_导入现有Patch-XA/'+path,data)
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(B/prefix/'Spell.dbc').read_bytes();put('rollback_WD121A_B/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw)
 for sid,name,desc in [(9003880,'丛林绽放 / Jungle Booms','大锅丛林蘑菇治疗提高100%，每跳最多5人（原8人），间隔仍为6秒。与丛林医师互斥，不影响投掷治疗。 / Cauldron Shrooms healing +100%; up to 5 allies instead of 8, every 6 sec. Exclusive with Doctor of the Jungle; excludes tossed healing.'),(9003881,'丛林医师 / Doctor of the Jungle','大锅丛林蘑菇每4秒治疗一次（原6秒），每跳最多8人。与丛林绽放互斥，不影响投掷持续治疗。 / Cauldron Shrooms heals every 4 sec instead of 6, up to 8 allies. Exclusive with Jungle Booms; excludes tossed HoT.')]:
  assert sid not in rows;r=rows[9003877][:];r[0]=sid;r[133]=910128+sid-9003880;r[95]=108 if sid==9003880 else 107;r[80]=99 if sid==9003880 else (-2001)&0xffffffff;r[110]=0 if sid==9003880 else 19
  for start,txt in [(136,name),(153,''),(170,desc),(187,desc)]:
   off=len(pool);pool+=txt.encode()+b'\0';r[start:start+16]=[off]*16
  rows[sid]=r
 # Keep baseline cadence/cap explicit; the authoritative current line is dynamic.
 for start in [170,187]:
  original=pool[rows[9003865][start]:].split(b'\0')[0].decode()
  desc='基础（未计丛林绽放／丛林医师） / Base (before Jungle Booms / Doctor): '+original+' 当前间隔、人数与治疗见同步数值。 / Current interval, targets and healing shown below.'
  off=len(pool);pool+=desc.encode()+b'\0';rows[9003865][start:start+16]=[off]*16
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(B/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD121A_B/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw)
 for sid in [9003880,9003881]:
  assert not any(r[2]==sid for r in rows.values());r=next(r[:] for r in rows.values() if r[2]==9003879);r[0]=max(rows)+1;r[2]=sid;r[8]=0;rows[r[0]]=r
 put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(B/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD121A_B/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw)
for i,icon in enumerate(icons):
 assert 910128+i not in rows;rows[910128+i]=[910128+i,len(pool)];pool+=icon.encode()+b'\0'
put(prefix+'/SpellIcon.dbc',pack(rows,pool))
print('WD122 built',P)
for f in (P/'rollback_WD121A_B').rglob('*'):
 if f.is_file():
  rel=f.relative_to(P/'rollback_WD121A_B');base=Q/rel if (Q/rel).exists() else B/rel
  assert base.exists(),base
  f.write_bytes(base.read_bytes())
