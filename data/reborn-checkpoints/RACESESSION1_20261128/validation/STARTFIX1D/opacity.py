from pathlib import Path
import struct as st,numpy as np,json
w=Path(__file__).parent;b=(w/'bear.m2').read_bytes();sk=(w/'bear00.skin').read_bytes();u=st.unpack_from
print('opacity0',u('<Hh4I',b,u('<I',b,92)[0]));print('lookups',[(o,u('<H',b,u('<I',b,o+4)[0])[0]) for o in [136,144,152]])
no,oo=u('<II',sk,36);print('batch0',u('<BB11H',sk,oo))
