from pathlib import Path
import json, re, shutil, struct, datetime, hashlib, zipfile
import sys

BASE = Path(Path('wd124_path.txt').read_text().strip())
sys.path.insert(0, str(BASE / 'tools'))
from wd19_common import Archive, dbc

ROOT = Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
stamp = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
OUT = ROOT / f'000Ascendupdate/000Ascendupdate{stamp[:8]}/codexfix_{stamp}_阶段WD125A_鱼油蛙骨双配料'
OUT.mkdir(parents=True, exist_ok=True)
Path('wd125_path.txt').write_text(str(OUT), encoding='utf8')
for sub in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录','03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL','tools']:
    shutil.copytree(BASE/sub,OUT/sub,dirs_exist_ok=True)
SF='01_覆盖到源代码根目录/'
CF='02_覆盖到客户端根目录/'
SRC='modules/mod-reborn-witchdoctor/src/'
ADD='Interface/AddOns/RebornWitchDoctorTalents/'
def put(rel,data):
    p=OUT/rel;p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes(data if isinstance(data,bytes) else data.encode('utf8'))
def rep(s,a,b):
    assert s.count(a)==1,(a,s.count(a))
    return s.replace(a,b)
def edit(rel,fn):
    b=(OUT/rel).read_bytes()
    put('rollback_WD124A/'+rel,b)
    put(rel,fn(b.decode('utf-8-sig').replace('\r\n','\n')))
def pack(rows,pool):
    n=len(next(iter(rows.values())))
    return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*row) for row in rows.values())+pool

# The official advancement labels are stale: spell 801662 is Fish Oil, 801663 is Frog Bones.
official=json.loads(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/Content/CharacterAdvancementData.json').read_text(encoding='utf-8-sig'))
put('research/official_nodes_WD125.json',json.dumps([x for x in official if x['ID'] in (6600,29738)],ensure_ascii=False,indent=2))
arc=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'))
donor,pool=dbc(arc.read('DBFilesClient\\Spell.dbc'));arc.close()
donor_ids=[801662,801663,803269,803697,802969,802971,803273,803699]
put('research/official_spells_WD125.json',json.dumps({i:{'row':donor[i],'name':pool[donor[i][136]:].split(b'\0')[0].decode('utf8','replace'),'description':pool[donor[i][170]:].split(b'\0')[0].decode('utf8','replace')} for i in donor_ids},ensure_ascii=False,indent=2))

def alloc(s):
    s=s.replace('AEIds[85]','AEIds[86]').replace('index<85','index<86').replace('index==85','index==86').replace('i<85','i<86')
    s=rep(s,'35065,35064,35068};','35065,35064,35068,29738};')
    s=rep(s,'+AERank(mask,83)+AERank(mask,84);','+AERank(mask,83)+AERank(mask,84)+AERank(mask,85);')
    s=rep(s,'!AERank(mask,83) && !AERank(mask,84) || spec==1','!AERank(mask,83) && !AERank(mask,84) && !AERank(mask,85) || spec==1')
    s=rep(s,'(mask>>97)!=0','(mask>>98)!=0')
    s=rep(s,'if((AERank(mask,82) || AERank(mask,83) || AERank(mask,84))','if((AERank(mask,82) || AERank(mask,83) || AERank(mask,84) || AERank(mask,85))')
    s=rep(s,'    // WD120: free Brewing nodes;', '''    if(AERank(mask,85) && !AERank(mask,74) && !AERank(mask,0)) return false;
    // WD120: free Brewing nodes;''')
    s=rep(s,'    uint32 const fresh=AERank(mask,77);','    for(uint32 id:{9003901u,9003902u,9003903u,9003904u,9003905u,9003906u,9003907u,9003908u}) if(!sSpellMgr->GetSpellInfo(id)) return;\n    uint32 const fresh=AERank(mask,77);')
    s=rep(s,'    uint32 toss=0;', '''    // WD125: Fish Oil is the official level-16 class ability; Frog Bones is a saved talent.
    bool const fish=AERank(mask,74)>0 && p->GetLevel()>=16;
    bool const bones=AERank(mask,85)>0;
    for(uint32 id:{WD125A::FishPrep,WD125A::BonesPrep})
    {
        bool enabled=id==WD125A::FishPrep?fish:bones;
        if(!enabled)
        {
            p->RemoveAurasDueToSpell(id,p->GetGUID());
            if(p->HasSpell(id)) p->removeSpell(id,3,false);
        }
        else if(!p->HasSpell(id)) p->learnSpell(id);
    }
    uint32 toss=0;''')
    return s
edit(SF+SRC+'RebornWitchDoctorAllocation.inc',alloc)
edit(SF+SRC+'RebornWitchDoctorTalentNodes.h',lambda s:rep(s,'    {35068,1,10,1,0,1,0,8,0,true,{}},','    {35068,1,10,1,0,1,0,8,0,true,{}},\n    {29738,1,10,1,0,1,0,8,0,true,{}},'))
edit(SF+SRC+'RebornWitchDoctorTalents.cpp',lambda s:rep(s,'n->id==35068','n->id==35068 || n->id==29738'))
edit(SF+'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h',lambda s:rep(s,'return (spell>=9003897','return (spell>=9003901 && spell<=9003908) || (spell>=9003897'))

numbers='''// WD125: private ingredient spell IDs; never use the donor IDs in live spellbook.
namespace WD125A
{
constexpr uint32 FishPrep=9003901,FishField=9003902,FishPotion=9003903,FishSplash=9003904;
constexpr uint32 BonesPrep=9003905,BonesField=9003906,BonesPotion=9003907,BonesSplash=9003908;
inline bool IsPrep(uint32 id) { return id==FishPrep || id==BonesPrep || id==WD120A::Shrooms; }
}
'''
edit(SF+SRC+'RebornWitchDoctorBrewingNumbers.h',lambda s:s+'\n'+numbers)
def brewing(s):
    s=rep(s,'    bool _shrooms=false;','    bool _shrooms=false,_fish=false,_bones=false;')
    s=rep(s,'WD120A::SplashHot});','WD120A::SplashHot,WD125A::FishPrep,WD125A::FishField,WD125A::FishPotion,WD125A::FishSplash,WD125A::BonesPrep,WD125A::BonesField,WD125A::BonesPotion,WD125A::BonesSplash});')
    s=rep(s,'!p->HasAura(WD120A::Shrooms))','!p->HasAura(WD120A::Shrooms) && !p->HasAura(WD125A::FishPrep) && !p->HasAura(WD125A::BonesPrep))')
    s=rep(s,'        _shrooms=GetCaster()->HasAura(WD120A::Shrooms);','''        _shrooms=GetCaster()->HasAura(WD120A::Shrooms);
        _fish=GetCaster()->HasAura(WD125A::FishPrep);
        _bones=GetCaster()->HasAura(WD125A::BonesPrep);
        // Exactly one prepared ingredient until the Mixologist capacity node is implemented.
        uint32 id=GetSpellInfo()->Id;
        if(WD125A::IsPrep(id))
            for(uint32 other:{WD120A::Shrooms,WD125A::FishPrep,WD125A::BonesPrep})
                if(other!=id) GetCaster()->RemoveAurasDueToSpell(other,GetCaster()->GetGUID());''')
    s=rep(s,'|| !_shrooms || !target ||','|| !target ||')
    s=rep(s,'        p->CastSpell(target,WD120A::IsSplash(GetSpellInfo()->Id)?WD120A::SplashHot:WD120A::Hot,true);','''        bool splash=WD120A::IsSplash(GetSpellInfo()->Id);
        if(_shrooms)
            p->CastSpell(target,splash?WD120A::SplashHot:WD120A::Hot,true);
        else if(_fish)
            p->CastSpell(target,splash?WD125A::FishSplash:WD125A::FishPotion,true);
        else if(_bones)
        {
            // Donor formula: base + 35% Spirit + 80% bonus healing.
            float amount=(splash?25.0f:100.0f)+std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.35f
                +float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.80f;
            int32 shield=std::max(1,int32(amount));
            p->CastCustomSpell(target,splash?WD125A::BonesSplash:WD125A::BonesPotion,&shield,nullptr,nullptr,true);
        }''')
    return s
edit(SF+SRC+'RebornWitchDoctorBrewingFoundation.inc',brewing)

def lua(s):
    s=s.replace('[35068]=84}','[35068]=84,[29738]=85}').replace('[35068]=1}','[35068]=1,[29738]=1}').replace('MaskFits(mask,97)','MaskFits(mask,98)')
    s=rep(s,'function M.BrewingSpent(mask) return','function M.BrewingSpent(mask) return M.AERank(29738,mask)+')
    s=rep(s,'rank(35068)>0) and M.BrewingFoundation(mask)<8','rank(35068)>0 or rank(29738)>0) and M.BrewingFoundation(mask)<8')
    s=rep(s,'if id==6498 or id==29303 or','if id==29738 or id==6498 or id==29303 or')
    s=rep(s,'local function Pair(','''details[29738]={zh="配料：蛙骨",en="Ingredient: Frog Bones",level=10,early="先投8 TE",kind="酿造主动 / Brewing active",effects={{"酿入大锅后，40码内团队成员受到的伤害降低3%；药水投掷附加护盾：100＋35%精神＋80%自然治疗加成。泼洒药水附加护盾基础值25，采用相同加成。","Prepare in the Cauldron: raid members within 40 yd take 3% less damage. Toss adds a shield of 100 + 35% Spirit + 80% Nature healing bonus; Splash uses base 25 with the same scaling."}},limit={"与丛林蘑菇、鱼油配料互斥；仅已保存并激活的方案可用。","Exclusive with Jungle Shrooms and Fish Oil; active saved build only."},path={"先投入8点基础酿造TE，再花1 TE。","Eight foundation Brewing TE, then one TE."}}
local function Pair(''')
    return s
edit(CF+ADD+'Allocation.lua',lua)
edit(CF+ADD+'WD8.lua',lambda s:s.replace(',97)',',98)'))
edit(CF+ADD+'Progress.lua',lambda s:rep(s,'RebornWDProgress = { nodes = {','RebornWDProgress = { nodes = {\n [29738]={name="配料：蛙骨",spells={9003905}},'))

# Keep server and client bases independent; add identical private rows to each base.
defs={
 9003901:(801662,'配料：鱼油 / Ingredient: Fish Oil','将鱼油酿入大锅。40码内队友移动及游泳速度提高10%；药水投掷附加8秒加速、闪避及施法加速。 / Prepare Fish Oil: raid speed +10% within 40 yd; Toss grants 8 sec movement, dodge and spell haste.'),
 9003902:(803269,'鱼油：大锅 / Cauldron: Fish Oil','40码内移动及游泳速度提高10%。 / Movement and swim speed +10% within 40 yd.'),
 9003903:(802969,'鱼油：药水 / Potion: Fish Oil','8秒内闪避提高5%、移动速度提高20%、施法速度提高10%。 / 8 sec: dodge +5%, movement +20%, spell haste +10%.'),
 9003904:(803273,'鱼油：泼洒 / Splash: Fish Oil','8秒内近战远程急速提高5%、移动速度提高15%、施法速度提高5%。 / 8 sec: melee/ranged haste +5%, movement +15%, spell haste +5%.'),
 9003905:(801663,'配料：蛙骨 / Ingredient: Frog Bones','将蛙骨酿入大锅。40码内队友受到伤害降低3%；药水投掷附加护盾。 / Prepare Frog Bones: raid damage taken -3% within 40 yd; potions add an absorb shield.'),
 9003906:(803697,'蛙骨：大锅 / Cauldron: Frog Bones','40码内受到的伤害降低3%。 / Damage taken -3% within 40 yd.'),
 9003907:(802971,'蛙骨：药水 / Potion: Frog Bones','8秒护盾：100＋35%精神＋80%自然治疗加成。 / 8 sec shield: 100 + 35% Spirit + 80% Nature healing bonus.'),
 9003908:(803699,'蛙骨：泼洒 / Splash: Frog Bones','8秒护盾：25＋35%精神＋80%自然治疗加成。 / 8 sec shield: 25 + 35% Spirit + 80% Nature healing bonus.')}
for pref in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
    raw=(OUT/pref/'Spell.dbc').read_bytes();put('rollback_WD124A/'+pref+'/Spell.dbc',raw)
    rows,strings=dbc(raw)
    for sid,(donor_id,title,desc) in defs.items():
        assert sid not in rows
        src=donor[donor_id]
        # Use the existing custom spell rows for safe family/class, then copy only
        # the donor's effect, aura, target, radius, duration and icon geometry.
        parent=9003865 if sid in (9003901,9003905) else (9003867 if sid in (9003903,9003904,9003907,9003908) else 9003865)
        row=rows[parent][:];row[0]=sid
        row[29:31]=[0,0]
        row[40]=src[40];row[133]=src[133]
        for a,b in [(71,77),(80,83),(86,101),(110,119)]:row[a:b]=src[a:b]
        if sid in (9003901,9003905):
            # Our preparation is a single periodic trigger, unlike the donor's
            # extra dummy aura. Aura lifecycle and categories match Shrooms.
            row[71:74]=[6,0,0];row[80:83]=[0,0,0];row[86:89]=[1,0,0]
            row[95:98]=[23,0,0];row[98:101]=[1500,0,0]
            row[116:119]=[9003902 if sid==9003901 else 9003906,0,0]
            row[29]=500
        if sid in (9003902,9003906):
            row[71:74]=src[71:74];row[86:89]=[1,1 if sid==9003902 else 0,0]
        if sid in (9003907,9003908):row[80]=0 # server CastCustomSpell supplies the full value
        for start,value in [(136,title),(153,''),(170,desc),(187,desc)]:
            offset=len(strings);strings+=value.encode()+b'\0';row[start:start+16]=[offset]*16
        rows[sid]=row
    put(pref+'/Spell.dbc',pack(rows,strings))
    raw=(OUT/pref/'SkillLineAbility.dbc').read_bytes();put('rollback_WD124A/'+pref+'/SkillLineAbility.dbc',raw)
    rows,strings=dbc(raw)
    for sid in (9003901,9003905):
        assert not any(x[2]==sid for x in rows.values())
        row=next(x[:] for x in rows.values() if x[2]==9003865);row[0]=max(rows)+1;row[2]=sid;rows[row[0]]=row
    put(pref+'/SkillLineAbility.dbc',pack(rows,strings))

world='''-- WORLD database. Guard private spell IDs and preserve WD120/WD123 bindings.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd125_world$$
CREATE PROCEDURE reborn_wd125_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003901,9003905) AND ScriptName<>'spell_reborn_wd120_brewing') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD125A spell script ID conflict'; END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES
 (9003901,'spell_reborn_wd120_brewing'),(9003905,'spell_reborn_wd120_brewing');
END$$
CALL reborn_wd125_world()$$
DROP PROCEDURE reborn_wd125_world$$
DELIMITER ;
'''
put('server_SQL/05_WORLD_WD125A_必须执行.sql',world)
print(OUT)
