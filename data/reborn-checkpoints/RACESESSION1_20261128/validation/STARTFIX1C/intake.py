from probe import *
b=read(c/'Data/Patch-YI.mpq','Character/Furbolg/FurbolgRace.m2');(w/'bear.m2').write_bytes(b);print('bear live',sha256(b).hexdigest())
