from pathlib import Path
import re
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());SF='01_覆盖到源代码根目录/';SRC='modules/mod-reborn-witchdoctor/src/';ADD='02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/'
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
inc=(P/SF/SRC/'RebornWitchDoctorBrewingFoundation.inc').read_text(encoding='utf8')
start=inc.index('namespace WD120A');end=inc.index('class spell_reborn_wd120_brewing')
shared=inc[start:end].replace('bool IsToss','inline bool IsToss').replace('double Scaling','inline double Scaling').replace('float Bonus','inline float Bonus')
put(SF+SRC+'RebornWitchDoctorBrewingNumbers.h','#pragma once\n#include "Player.h"\n#include "SpellInfo.h"\n'+shared)
inc=inc[:start]+'#include "RebornWitchDoctorBrewingNumbers.h"\n'+inc[end:]
put(SF+SRC+'RebornWitchDoctorBrewingFoundation.inc',inc)
f=P/SF/SRC/'RebornWitchDoctorTalents.cpp';s=f.read_text(encoding='utf8');s='#include "RebornWitchDoctorBrewingNumbers.h"\n'+s
s=s.replace('bool const allowed=id==9003861','bool const allowed=id==WD120A::Shrooms || WD120A::IsToss(id) || id==9003861')
anchor='    if(id==9003861)\n'
block='''    if(id==WD120A::Shrooms || WD120A::IsToss(id))
    {
        bool pulse=id==WD120A::Shrooms;
        SpellInfo const* heal=pulse?sSpellMgr->GetSpellInfo(WD120A::Pulse):info;
        if(!heal) { h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true; }
        auto const& effect=heal->Effects[EFFECT_0];
        int32 level=int32(p->GetLevel());
        if(heal->MaxLevel && level>int32(heal->MaxLevel)) level=int32(heal->MaxLevel);
        level=std::max(level,int32(heal->BaseLevel))-int32(std::max(heal->BaseLevel,heal->SpellLevel));
        int32 base=effect.BasePoints+int32(level*effect.RealPointsPerLevel);
        auto estimate=[&](int32 dice)
        {
            float amount=p->ApplyEffectModifiers(heal,EFFECT_0,float(base+dice));
            if(pulse) amount=float(int32(double(amount)*WD120A::Scaling(p->GetLevel())));
            uint32 result=uint32(std::max(0,int32(amount+WD120A::Bonus(p,pulse))));
            return p->SpellHealingBonusDone(p,heal,result,HEAL,EFFECT_0);
        };
        uint32 lo=estimate(effect.DieSides==0?0:1),hi=estimate(effect.DieSides);
        h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active);
        return true;
    }
'''
assert s.count(anchor)==1;s=s.replace(anchor,block+anchor);put(SF+SRC+'RebornWitchDoctorTalents.cpp',s)
f=P/ADD/'NumericTooltip.lua';s=f.read_text(encoding='utf8');s=s.replace('allowed[9003861]=true;','allowed[9003865]=true;range(9003870,9003876);allowed[9003861]=true;')
s=s.replace('if id==9003861 or power[id]','if id==9003865 or (id>=9003870 and id<=9003876) or id==9003861 or power[id]')
s=s.replace('   if id==9003861 then','''   if id==9003865 or (id>=9003870 and id<=9003876) then
    local label=id==9003865 and "每6秒范围治疗 / Pulse per 6 sec: " or "直接治疗 / Direct heal: "
    text=label..value.a.."–"..value.b.."（含自身加成；未计目标增减益及暴击 / self bonuses, before target modifiers and crit）"
   elseif id==9003861 then''')
put(ADD+'NumericTooltip.lua',s)
ids=[9003864,9003865,9003866,9003867]+list(range(9003870,9003877));active=[9003865,9003866]+list(range(9003870,9003877));heals=[9003866]+list(range(9003870,9003877))
sql='''-- WORLD database. WD120A adds only private IDs; replay-safe, conflicts rejected before writes.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd120_world$$
CREATE PROCEDURE reborn_wd120_world()
BEGIN
'''
sql+=" IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN("+','.join(map(str,ids))+") AND ScriptName<>'spell_reborn_wd120_brewing') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD120A script ID conflict';END IF;\n"
sql+=" IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN("+','.join(map(str,heals))+") AND (direct_bonus<>0 OR dot_bonus<>0 OR ap_bonus<>0 OR ap_dot_bonus<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD120A coefficient ID conflict';END IF;\n"
sql+=" IF EXISTS(SELECT 1 FROM spell_ranks WHERE (first_spell_id=9003870 OR spell_id BETWEEN 9003870 AND 9003876) AND (first_spell_id<>9003870 OR spell_id NOT BETWEEN 9003870 AND 9003876 OR `rank`<>spell_id-9003869)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD120A rank ID conflict';END IF;\n"
sql+=' INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES '+','.join("(%d,'spell_reborn_wd120_brewing')"%i for i in active)+';\n'
sql+=" INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES "+','.join("(%d,0,0,0,0,'WD120A manual CoA coefficient before native done/taken')"%i for i in heals)+" ON DUPLICATE KEY UPDATE comments=VALUES(comments);\n"
sql+=' INSERT IGNORE INTO spell_ranks(first_spell_id,spell_id,`rank`) VALUES '+','.join('(9003870,%d,%d)'%(9003870+i,i+1) for i in range(7))+';\n'
sql+='END$$\nCALL reborn_wd120_world()$$\nDROP PROCEDURE reborn_wd120_world$$\nDELIMITER ;\n'
put('server_SQL/03_WORLD_WD120A_必须执行.sql',sql)
print('WD120 query and WORLD SQL built')
