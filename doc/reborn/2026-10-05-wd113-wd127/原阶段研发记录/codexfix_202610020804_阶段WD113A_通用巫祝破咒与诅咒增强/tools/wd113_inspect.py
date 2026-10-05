from pathlib import Path
import re,json
import wd19_common as c
P=Path(Path('wd112_path.txt').read_text(encoding='utf8'))
s=(c.R/'beascendclient/newrebornWOWli20260929beAscend/Interface/AddOns/RebornWitchDoctorTalents/Data.lua').read_text(encoding='utf-8-sig')
a=c.Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));rows,pool=c.dbc(a.read('DBFilesClient\\Spell.dbc'));a.close()
out=[]
for p in s.split('{["ID"]=')[1:]:
    id=int(p.split(',')[0])
    if id not in [6645,7128,29741,29303,6022,6498,6015,6009,6014,6023,6021,30823,4112,7130,4733]:continue
    ids=[int(x) for x in re.search(r'\["Spells"\]=\{(.*?)\}',p)[1].split(',')]
    for sid in ids:
        r=rows[sid]
        name=pool[r[136]:].split(b'\0')[0].decode('utf8');desc=pool[r[170]:].split(b'\0')[0].decode('utf8')
        out.append(dict(node=id,spell=sid,name=name,desc=desc,row=r))
        print(id,sid,name,desc,'effects',r[71:74],r[80:83],r[95:98],r[110:113],r[116:119])
Path('wd113_candidates.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
