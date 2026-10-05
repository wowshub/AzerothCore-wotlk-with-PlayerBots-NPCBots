from pathlib import Path
import sys

P=Path(__file__).resolve().parents[1]
B=Path('D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610041754_阶段WD125A_鱼油蛙骨双配料')
sys.path.insert(0,str(P/'tools'))
from wd19_common import dbc

for prefix in ('03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient'):
    for table in ('Spell','SkillLineAbility'):
        old,pool0=dbc((B/prefix/(table+'.dbc')).read_bytes())
        new,pool=dbc((P/prefix/(table+'.dbc')).read_bytes())
        assert pool.startswith(pool0),(prefix,table,'string prefix')
        assert all(new.get(key)==row for key,row in old.items()),(prefix,table,'old row changed')
        if table=='Spell':
            assert set(new)-set(old)=={9003910}
            row=new[9003910]
            assert row[29]==120000 and row[40]==31 and row[38:40]==[10,10] and row[204]==15
            assert row[71:74]==[6,3,6] and row[95:98]==[49,0,61]
            assert row[80]==49 and row[82]==2**32-26
            assert row[133]==1761
            assert row[2]==1
            for field in (136,153,170,187):
                assert all(0<=row[i]<len(pool) and pool.find(b'\0',row[i])>=0 for i in range(field,field+16))
        else:
            assert sum(row[2]==9003910 for row in new.values())==1

source=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
client=(P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/Allocation.lua').read_text(encoding='utf8')
sql=(P/'server_SQL/01_CHARACTERS_WD126A_必须执行.sql').read_text(encoding='utf8')
assert 'AEIds[87]' in source and '30888};' in source and '(mask>>99)!=0' in source
assert 'AEMask const maximum=(AEMask(1)<<99)-1;' in source
assert 'AERank(mask,86)' in source and '9003910' in source
assert '[30888]=86' in client and 'MaskFits(mask,99)' in client
assert 'r86' in sql and str(2**98) in sql and str(2**99-1) in sql
assert 'node_id IN(' in sql and '29738,30888)' in sql
assert 'r86<>0 AND (r74' not in sql
print('PASS WD126A: unchanged WD125 dual DBC rows, native aura, spellbook, 99-bit C++/Lua/SQL projection')
