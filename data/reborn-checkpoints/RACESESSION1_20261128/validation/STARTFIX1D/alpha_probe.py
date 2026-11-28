from pathlib import Path
from struct import unpack_from as u
b=(Path(__file__).parent/'bear.m2').read_bytes();o=u('<I',b,92)[0];n,k=u('<II',b,o+12)
for seq in [2,4,5,78,99,100,101]:
 count,off=u('<II',b,k+seq*8);print(seq,count,off,u('<'+str(min(count,8))+'h',b,off) if count else None)
