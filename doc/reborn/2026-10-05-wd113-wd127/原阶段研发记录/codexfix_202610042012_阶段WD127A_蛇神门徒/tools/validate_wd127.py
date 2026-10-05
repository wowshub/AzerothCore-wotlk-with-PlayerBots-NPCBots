from pathlib import Path
import sys

P=Path(__file__).resolve().parents[1]
B=P/'rollback_WD126A'
sys.path.insert(0,str(P/'tools'))
from wd19_common import dbc

for prefix in ('03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient'):
    for table in ('Spell','SkillLineAbility'):
        old,pool0=dbc(((B if table=='Spell' else P)/prefix/(table+'.dbc')).read_bytes())
        new,pool=dbc((P/prefix/(table+'.dbc')).read_bytes())
        assert pool.startswith(pool0),(prefix,table,'string prefix')
        assert all(new.get(key)==row for key,row in old.items()),(prefix,table,'old row changed')
        if table=='Spell':
            assert set(new)-set(old)=={9003911}
            row=new[9003911]
            assert row[71:74]==[6,0,0] and row[95:98]==[4,0,0]
            assert row[38:40]==[10,10]
            for field in (136,153,170,187):
                assert all(0<=row[i]<len(pool) and pool.find(b'\0',row[i])>=0 for i in range(field,field+16))
        else:
            assert new==old and pool==pool0 and not any(row[2]==9003911 for row in new.values())

source=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
cpp=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp').read_text(encoding='utf8')
client=(P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/Allocation.lua').read_text(encoding='utf8')
sql=(P/'server_SQL/01_CHARACTERS_WD127A_必须执行.sql').read_text(encoding='utf8')
assert 'AEIds[88]' in source and '30888,35051};' in source and '(mask>>100)!=0' in source
assert 'AEMask const maximum=(AEMask(1)<<100)-1;' in source
assert 'AERank(mask,87)' in source and '9003911' in source
assert '0.84f*1.15f' in cpp and '0.45f*1.15f' in cpp
assert 'spell_reborn_wd28a_hexbreak::ExtraAlly' in cpp and 'ShorterGlobalCooldown' in cpp
assert '[35051]=87' in client and 'MaskFits(mask,100)' in client
assert 'r87' in sql and str(2**99) in sql and str(2**100-1) in sql
assert 'node_id IN(' in sql and '30888,35051)' in sql
print('PASS WD127A: unchanged WD126 rows, hidden passive, 100-bit C++/Lua/SQL projection')
