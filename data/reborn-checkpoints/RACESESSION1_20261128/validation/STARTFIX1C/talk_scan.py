import pose_tools as p
p.load('bear');n,o=p.u('<II',p.b,28)
for seq in range(n):
 ident,sub,duration=p.u('<HHI',p.b,o+64*seq)
 if seq<90 and ident not in [0,60,64,65,66,67,68,69,84]:continue
 vals=[float(p.posed(seq,t)[2][:,2].min()) for t in [0,duration//4,duration//2,3*duration//4,max(0,duration-1)]]
 print(seq,ident,sub,duration,','.join(f'{x:.3f}' for x in vals))
