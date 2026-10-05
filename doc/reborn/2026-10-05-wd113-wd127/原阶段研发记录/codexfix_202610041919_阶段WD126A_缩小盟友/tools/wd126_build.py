from pathlib import Path
import datetime, json, re, shutil, struct, sys

BASE = Path(Path('wd125_path.txt').read_text(encoding='utf8').strip())
sys.path.insert(0, str(BASE / 'tools'))
from wd19_common import Archive, dbc

ROOT = Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
stamp = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
OUT = ROOT / f'000Ascendupdate/000Ascendupdate{stamp[:8]}/codexfix_{stamp}_阶段WD126A_缩小盟友'
OUT.mkdir(parents=True, exist_ok=False)
Path('wd126_path.txt').write_text(str(OUT), encoding='utf8')
for sub in ('01_覆盖到源代码根目录', '02_覆盖到客户端根目录', '03_覆盖到服务端根目录',
            'client_mpq输入_导入现有Patch-XA', 'server_SQL', 'tools'):
    shutil.copytree(BASE / sub, OUT / sub)
SF = '01_覆盖到源代码根目录/'
CF = '02_覆盖到客户端根目录/'
SRC = 'modules/mod-reborn-witchdoctor/src/'
ADD = 'Interface/AddOns/RebornWitchDoctorTalents/'

def put(rel, value):
    path = OUT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(value if isinstance(value, bytes) else value.encode('utf8'))

def rep(value, old, new):
    count = value.count(old)
    assert count == 1, (old[:90], count)
    return value.replace(old, new)

def edit(rel, transform):
    original = (OUT / rel).read_bytes()
    put('rollback_WD125A/' + rel, original)
    put(rel, transform(original.decode('utf-8-sig').replace('\r\n', '\n')))

def pack(rows, strings):
    width = len(next(iter(rows.values())))
    return struct.pack('<4s4I', b'WDBC', len(rows), width, width * 4, len(strings)) + \
        b''.join(struct.pack('<' + 'I'*width, *row) for row in rows.values()) + strings

official = json.loads(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/Content/CharacterAdvancementData.json').read_text(encoding='utf-8-sig'))
node = next(x for x in official if x['ID'] == 30888)
assert node['Spells'] == [806282] and node['RequiredTEInvestment'] == 8
put('research/official_node_30888.json', json.dumps(node, ensure_ascii=False, indent=2))
archive = Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'))
donor, donor_strings = dbc(archive.read('DBFilesClient\\Spell.dbc'))
archive.close()
spell = donor[806282]
assert spell[71:74] == [6,3,6] and spell[95:98] == [49,0,61]
assert spell[40] == 31 and spell[29] == 120000 and spell[80] == 49
put('research/official_spell_806282.json', json.dumps({'row': spell,
    'name': donor_strings[spell[136]:].split(b'\0')[0].decode('utf8','replace'),
    'description': donor_strings[spell[170]:].split(b'\0')[0].decode('utf8','replace')}, ensure_ascii=False, indent=2))

def alloc(source):
    source = source.replace('AEIds[86]', 'AEIds[87]').replace('index<86', 'index<87').replace('index==86', 'index==87')
    source = rep(source, '35068,29738};', '35068,29738,30888};')
    source = rep(source, '+AERank(mask,84)+AERank(mask,85);', '+AERank(mask,84)+AERank(mask,85)+AERank(mask,86);')
    source = rep(source, '!AERank(mask,84) && !AERank(mask,85) || spec==1', '!AERank(mask,84) && !AERank(mask,85) && !AERank(mask,86) || spec==1')
    source = rep(source, '(mask>>98)!=0', '(mask>>99)!=0')
    source = rep(source, 'AERank(mask,84) || AERank(mask,85))', 'AERank(mask,84) || AERank(mask,85) || AERank(mask,86))')
    source = rep(source, '    // WD120: free Brewing nodes;', '    if(AERank(mask,86) && level<10) return false;\n    // WD120: free Brewing nodes;')
    source = rep(source, '    uint32 const fresh=AERank(mask,77);', '    if(!sSpellMgr->GetSpellInfo(9003910)) return;\n    uint32 const fresh=AERank(mask,77);')
    source = rep(source, '    uint32 toss=0;', '''    // WD126: native eight-second dodge/size aura, owned by the active saved build.
    if(!AERank(mask,86))
    {
        if(p->HasSpell(9003910)) p->removeSpell(9003910,3,false);
    }
    else if(!p->HasSpell(9003910)) p->learnSpell(9003910);
    uint32 toss=0;''')
    source = rep(source, 'AEMask const maximum=(AEMask(1)<<98)-1;', 'AEMask const maximum=(AEMask(1)<<99)-1;')
    return source
edit(SF + SRC + 'RebornWitchDoctorAllocation.inc', alloc)
edit(SF + SRC + 'RebornWitchDoctorTalentNodes.h', lambda s: rep(s,
    '    {29738,1,10,1,0,1,0,8,0,true,{}},',
    '    {29738,1,10,1,0,1,0,8,0,true,{}},\n    {30888,1,10,1,0,1,0,8,0,true,{}},'))
edit(SF + SRC + 'RebornWitchDoctorTalents.cpp', lambda s: rep(s,
    'n->id==35068 || n->id==29738', 'n->id==35068 || n->id==29738 || n->id==30888'))
edit(SF + 'src/server/game/Entities/Player/WitchDoctorTalentPolicy.h', lambda s: rep(s,
    'return (spell>=9003901', 'return spell==9003910 || (spell>=9003901'))

def cpp(source):
    source = rep(source, '#include "RebornWitchDoctorBrewingFoundation.inc"', '''#include "RebornWitchDoctorBrewingFoundation.inc"

// WD126: the donor spell's Dodge and Scale auras remain native 3.3.5a effects.
class spell_reborn_wd126_shrink_ally : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd126_shrink_ally);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        Unit* target=GetExplTargetUnit();
        return IsDoctor(p) && p->HasSpell(9003910) && target && target->IsAlive() &&
            p->IsValidAssistTarget(target) ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd126_shrink_ally::Check);
    }
};''')
    return rep(source, '    RegisterSpellScript(spell_reborn_wd120_brewing);',
               '    RegisterSpellScript(spell_reborn_wd120_brewing);\n    RegisterSpellScript(spell_reborn_wd126_shrink_ally);')
edit(SF + SRC + 'RebornWitchDoctor.cpp', cpp)

def lua(source):
    source = rep(source, '[29738]=85}', '[29738]=85,[30888]=86}')
    source = rep(source, '[29738]=1}', '[29738]=1,[30888]=1}')
    source = rep(source, 'MaskFits(mask,98)', 'MaskFits(mask,99)')
    source = rep(source, 'function M.BrewingSpent(mask) return M.AERank(29738,mask)+',
                 'function M.BrewingSpent(mask) return M.AERank(30888,mask)+M.AERank(29738,mask)+')
    source = rep(source, 'rank(35068)>0 or rank(29738)>0)',
                 'rank(35068)>0 or rank(29738)>0 or rank(30888)>0)')
    source = rep(source, 'if id==29738 or id==6498', 'if id==30888 or id==29738 or id==6498')
    source = rep(source, 'local function Pair(', '''details[30888]={zh="缩小盟友",en="Shrink Ally",level=10,early="先投8 TE",kind="酿造主动 / Brewing active",effects={{"使一名友方缩小8秒，闪避几率提高50%；冷却2分钟。缩小外观约25%。","Shrink an ally for 8 sec, increasing dodge chance by 50%; 2 min cooldown. Appearance shrinks by about 25%."}},limit={"仅已保存并激活的酿造方案可施放。","Active saved Brewing build only."},path={"先投入8点基础酿造TE，再花1 TE。","Eight foundation Brewing TE, then one TE."}}
local function Pair(''')
    return source
edit(CF + ADD + 'Allocation.lua', lua)
edit(CF + ADD + 'WD8.lua', lambda s: s.replace(',98)', ',99)') if s.count(',98)') == 3 else rep(s, ',98)', ',99)'))
edit(CF + ADD + 'Progress.lua', lambda s: rep(s,
    'RebornWDProgress = { nodes = {',
    'RebornWDProgress = { nodes = {\n [30888]={name="缩小盟友",spells={9003910}},'))

for prefix in ('03_覆盖到服务端根目录/Data/dbc', 'client_mpq输入_导入现有Patch-XA/DBFilesClient'):
    rel = prefix + '/Spell.dbc'
    raw = (OUT / rel).read_bytes()
    put('rollback_WD125A/' + rel, raw)
    rows, strings = dbc(raw)
    assert 9003910 not in rows
    row = rows[9003870][:]
    row[0] = 9003910
    row[2] = spell[2]  # magical buff dispel type
    row[29] = spell[29]
    row[30] = 0
    row[40] = spell[40]
    row[38:40] = [10,10]  # authored talent unlock, not the rank-14 Toss skeleton
    row[204] = spell[204]  # donor uses 15% base mana
    row[133] = spell[133]
    for start, end in ((71,77),(80,83),(86,101),(110,119)):
        row[start:end] = spell[start:end]
    # The donor spell's effect index 1 is a harmless dummy; indexes 0/2
    # remain native Dodge + model-scale auras with the same expiration.
    for start, value in ((136,'缩小盟友 / Shrink Ally'), (153,''),
                         (170,'使一名友方缩小8秒，闪避几率提高50%。2分钟冷却。 / Shrink an ally for 8 sec, increasing dodge chance by 50%. 2 min cooldown.'),
                         (187,'使一名友方缩小8秒，闪避几率提高50%。2分钟冷却。 / Shrink an ally for 8 sec, increasing dodge chance by 50%. 2 min cooldown.')):
        offset = len(strings)
        strings += value.encode('utf8') + b'\0'
        row[start:start+16] = [offset]*16
    rows[9003910] = row
    put(rel, pack(rows, strings))
    rel = prefix + '/SkillLineAbility.dbc'
    raw = (OUT / rel).read_bytes()
    put('rollback_WD125A/' + rel, raw)
    rows, strings = dbc(raw)
    assert not any(record[2] == 9003910 for record in rows.values())
    line = next(record[:] for record in rows.values() if record[2] == 9003865)
    line[0] = max(rows)+1
    line[2] = 9003910
    rows[line[0]] = line
    put(rel, pack(rows, strings))

put('server_SQL/06_WORLD_WD126A_必须执行.sql', '''-- WORLD database; keep prior WD125 SQL in order.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd126_world$$
CREATE PROCEDURE reborn_wd126_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003910 AND ScriptName<>'spell_reborn_wd126_shrink_ally') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD126A private spell script ID conflict'; END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003910,'spell_reborn_wd126_shrink_ally');
END$$
CALL reborn_wd126_world()$$
DROP PROCEDURE reborn_wd126_world$$
DELIMITER ;
''')

old = OUT / 'server_SQL/01_CHARACTERS_WD125A_必须执行.sql'
sql = old.read_text(encoding='utf8')
sql = sql.replace('reborn_wd125_schema', 'reborn_wd126_schema').replace('WD125A', 'WD126A')
sql = sql.replace('35068,29738)', '35068,29738,30888)')
sql = rep(sql, ' DECLARE r85 INT DEFAULT 0;', ' DECLARE r86 INT DEFAULT 0;\n DECLARE r85 INT DEFAULT 0;')
sql = rep(sql, ' SET r85=MOD(FLOOR(p_mask/', f' SET r86=MOD(FLOOR(p_mask/{2**98}),2);\n SET r85=MOD(FLOOR(p_mask/')
sql = rep(sql, str(2**98-1), str(2**99-1))
sql = rep(sql, 'r84<>0 OR r85<>0) AND r49', 'r84<>0 OR r85<>0 OR r86<>0) AND r49')
sql = rep(sql, 'r84+r85>v_te', 'r84+r85+r86>v_te')
sql = rep(sql, 'r84+r85>0)', 'r84+r85+r86>0)')
sql = rep(sql, f'WHEN 29738 THEN node_rank*{2**97}', f'WHEN 30888 THEN node_rank*{2**98} WHEN 29738 THEN node_rank*{2**97}')
sql = rep(sql, f' IF r85<MOD(FLOOR(v_saved/{2**97}),2)', f' IF r86<MOD(FLOOR(v_saved/{2**98}),2) OR r85<MOD(FLOOR(v_saved/{2**97}),2)')
sql = rep(sql, ' IF r85>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29738,r85);END IF;',
          ' IF r85>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29738,r85);END IF;\n IF r86>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,30888,r86);END IF;')
put('server_SQL/01_CHARACTERS_WD126A_必须执行.sql', sql)
old.unlink()
print(OUT)
