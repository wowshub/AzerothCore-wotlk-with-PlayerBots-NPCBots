import pose_tools as p
import numpy as np
from pathlib import Path
p.load('bear');old=p.b;before={}
n,o=p.u('<II',old,36)
for ident in [0,4,5,96,97,98]:
 seq=p.u('<h',old,o+ident*2)[0]
 if seq>=0:
  for ms in [0,200,700]:before[(seq,ms)]=p.posed(seq,ms)[2].copy()
p.b=(Path(__file__).parent/'bear-fixed.m2').read_bytes()
for key,v in before.items():assert np.array_equal(v,p.posed(*key)[2]),key
print('PASS',len(before),'original stand/walk/run/sit poses byte-equivalent after talk fixes')
