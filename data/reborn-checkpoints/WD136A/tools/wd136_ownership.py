# coding: utf-8
from wd136_init import *
brewing=[49,50,51,53,55,56,57,61,62]+list(range(77,98))+[99,100,101]
total='+'.join('AERank(mask,%d)'%i for i in brewing)
def alloc(s):
 s=rep(s,'6027,13133};','6027,13133,6026};').replace('(mask>>117)!=0','(mask>>118)!=0').replace('(AEMask(1)<<117)-1','(AEMask(1)<<118)-1')
 s=rep(s,'!AERank(mask,104) || spec==1','!AERank(mask,104) && !AERank(mask,105) || spec==1')
 s=rep(s,'+AERank(mask,102)+AERank(mask,103);','+AERank(mask,102)+AERank(mask,103)+AERank(mask,105);')
 s=rep(s,'    uint32 const brewing134=',f'''    // WD136 excludes every tier-23 node from its own prerequisite investment.
    if(AERank(mask,105) && (level<57 || !AERank(mask,74) || !AERank(mask,75) || !AERank(mask,92) || {total}-AERank(mask,101)<23)) return false;
    uint32 const brewing134=''')
 s=rep(s,'    if(AERank(mask,104))','''    if(AERank(mask,105)) { if(!p->HasSpell(9003954)) p->learnSpell(9003954); if(!p->HasAura(9003954,p->GetGUID())) p->CastSpell(p,9003954,true); }
    else { p->RemoveAurasDueToSpell(9003954,p->GetGUID()); p->RemoveAurasDueToSpell(9003955,p->GetGUID()); if(p->HasSpell(9003954)) p->removeSpell(9003954,3,false); }
    if(AERank(mask,104))''');return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',lambda s:rep(s.replace('AEIdCount=105','AEIdCount=106'),'    if(s->modern && n->id==13133)',f'    if(s->modern && n->id==6026) {{ level=57;missing=rank(4005)&&rank(12645)&&rank(6014)?0:1;te={total.replace("mask,","s->aeMasks[slot],")}-rank(29754); }}\n    if(s->modern && n->id==13133)'))
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',lambda s:rep(s,'{6026,1,0,1,0,1,0,23,0,false,{}}','{6026,1,57,1,0,1,0,23,0,true,{6014}}'))
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return spell==9003953','return spell==9003954 || spell==9003953'))
def lua(s):
 s=rep(s,'[13133]=104}','[13133]=104,[6026]=105}');s=rep(s,'[13133]=1}','[13133]=1,[6026]=1}').replace('MaskFits(mask,117)','MaskFits(mask,118)')
 s=rep(s,'function M.BrewingSpent(mask) return ','function M.BrewingSpent(mask) return M.AERank(6026,mask)+')
 s=rep(s,' if rank(13133)>0',' if rank(6026)>0 and (M.level<57 or M.specs[M.slot+1]~=1 or rank(4005)==0 or rank(12645)==0 or rank(6014)==0 or M.BrewingSpent(mask)-rank(6026)-rank(30333)-rank(6027)-rank(29754)<23) then return false,"需要57级、大锅、丛林蘑菇、森金之仪和23点前层酿造TE" end\n if rank(13133)>0')
 s=rep(s,' if id==30333 or id==6027',' if id==6026 or id==30333 or id==6027')
 return rep(s,'local function Pair(','''details[6026]={zh="调制大师",en="Master of Concoctions",level=57,early="57",kind="酿造被动 / Brewing passive",effects={{"药水投掷与泼洒附带的配料效果持续时间延长20%。丛林蘑菇使受益者在15秒内接下来3次进攻技能按实际伤害的5%恢复自身生命。","Delivered ingredient effects last 20% longer. Jungle Shrooms grants 15 sec to heal for 5% of resolved damage from the next 3 offensive casts."}},limit={"每次成功施法扣一次，群攻不按目标扣，周期伤害沿用该次施法；普攻、自动射击及无关触发不消耗。回收治疗不重复吃法强或暴击。","One charge per successful cast, not per target/tick. Autoattacks and unrelated procs are excluded; leech does not double-scale or crit."},path={"大锅、丛林蘑菇、森金之仪，先投入23点前层酿造TE，再花1 TE。","Cauldron Brewer, Jungle Shrooms and Senjin Presence; 23 prior Brewing TE, then 1 TE."}}
local function Pair(''')
edit(CF+ADD+'Allocation.lua',lua)
edit(CF+ADD+'WD8.lua',lambda s:s.replace('MaskFits(a0,117)','MaskFits(a0,118)').replace('MaskFits(a1,117)','MaskFits(a1,118)').replace('MaskFits(a2,117)','MaskFits(a2,118)'))
edit(CF+ADD+'Progress.lua',lambda s:rep(s,' [13133]',' [6026]={name="调制大师",spells={9003954}},\n [13133]'))
edit(CF+ADD+'Data.lua',lambda s:s+'\n-- WD136: Concoctions depends on implemented Senjin path; Cauldron Empowerment 6023 remains preview.\nfor _,n in ipairs(RebornWDTreeData) do if n.ID==6026 then n.RequiredLevel=57 end end\n')
def sql(s):
 s=s.replace('WD135A','WD136A').replace('reborn_wd135_schema','reborn_wd136_schema').replace('6027,13133)','6027,13133,6026)').replace(str(2**117-1),str(2**118-1))
 s=rep(s,' DECLARE r104 INT DEFAULT 0;',' DECLARE r104 INT DEFAULT 0;\n DECLARE r105 INT DEFAULT 0;')
 a=f' SET r104=MOD(FLOOR(p_mask/{2**116}),2);';s=rep(s,a,a+f'\n SET r105=MOD(FLOOR(p_mask/{2**117}),2);')
 expr='+'.join('r%d'%i for i in brewing if i!=101)
 s=rep(s,' IF r104<>0',f' IF r105<>0 AND (p_level<57 OR r74=0 OR r75=0 OR r92=0 OR {expr}<23) THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;\n IF r104<>0')
 s=s.replace('+r102+r103+r104>0)','+r102+r103+r104+r105>0)')
 s=rep(s,'+r102+r103>v_te','+r102+r103+r105>v_te')
 a=' WHEN 13133 THEN node_rank*'+str(2**116);s=rep(s,a,a+f' WHEN 6026 THEN node_rank*{2**117}')
 s=rep(s,' IF r104<MOD',f' IF r105<MOD(FLOOR(v_saved/{2**117}),2) OR r104<MOD')
 a=' IF r104>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,13133,r104);END IF;';s=rep(s,a,a+'\n IF r105>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,6026,r105);END IF;');return s
old='server_SQL/01_CHARACTERS_WD135A_必须执行.sql';put('rollback_WD135UI/'+old,(P/old).read_bytes());put('server_SQL/01_CHARACTERS_WD136A_必须执行.sql',sql((P/old).read_text(encoding='utf-8')));(P/old).unlink()
print('WD136 index105/bit117 saved build, Lua and Characters SQL written.')
