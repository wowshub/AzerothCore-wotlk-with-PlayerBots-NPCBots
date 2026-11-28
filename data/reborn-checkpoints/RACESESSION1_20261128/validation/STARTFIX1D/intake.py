from probe import *
key='Character/Furbolg/FurbolgRace';b=read(c/'Data/Patch-YI.mpq',key+'.m2');(w/'bear.m2').write_bytes(b);print('sha',sha256(b).hexdigest(),'LODs',u('<I',b,68)[0]);print('vertices/bones',u('<I',b,60)[0],u('<I',b,44)[0]);n,o=u('<II',b,80);print('textures',[u('<4I',b,o+16*i) for i in range(n)])
n,o=u('<II',b,44)
print('bone pivots',[(i,u('<i',b,o+88*i)[0],u('<h',b,o+88*i+8)[0],tuple(round(v,3) for v in u('<3f',b,o+88*i+76))) for i in range(min(n,30))])
for lod in range(u('<I',b,68)[0]):
 sk=read(c/'Data/Patch-YI.mpq',key+f'{lod:02d}.skin');(w/(f'bear{lod:02d}.skin')).write_bytes(sk);n,o=u('<II',sk,28);print('sections',lod,[(u('<10H',sk,o+48*i)) for i in range(n)])
