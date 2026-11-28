import sys,json
import numpy as np
sys.path.insert(0,'stormforged-intake');sys.argv=['','C:/000ref/WarcraftXL\u8bd5\u88c5_client']
from probe import *
p=w/'helmetfit1f/verification.json';report=json.loads(p.read_text())
key='Item/ObjectComponents/Head/Helm_Plate_DeathKnight_B_01_GnF.m2'
# Patch-H and Patch-6 supersede the original patch.MPQ copy. Verify the actual
# newer geometry as well; do not infer priority from alphabetical enumeration.
hood=read(c/'Data/patch-H.mpq',key)
assert hood==read(c/'Data/Patch-6.mpq',key)
n,o=u('<2I',hood,60);points=np.array([u('<3f',hood,o+48*i) for i in range(n)])
new=points*.785+np.array([.065,0,2.272]);bounds=np.array([new.min(0),new.max(0)])
head=np.array(report['target_skull_bounds'])
assert np.all(bounds[0]<=head[0]+.001) and np.all(bounds[1]>=head[1]-.001)
report['newer_helmet_archives']=['Patch-6.mpq','patch-H.mpq']
report['newer_helmet_sha256']=sha256(hood).hexdigest()
report['newer_candidate_bounds']=bounds.tolist()
p.write_text(json.dumps(report,indent=2))
print('Newer Patch-H / Patch-6 geometry: enclosure check passed',bounds.tolist())
