import pose_tools as p
p.load('bear');n,o=p.u('<II',p.b,88);print('opacity',n,o);print('array sizes',[(k,p.u('<II',p.b,k)) for k in [104,112,120,128,136,144,152]])
for z in [1.9,1.75,1.6,1.45,1.3,1.15,1.0,.85,.7]:
 q=p.vr[(abs(p.vr[:,2]-z)<.13)&(abs(p.vr[:,1])<.32)]
 print('band',z,'back',float(q[:,0].min()) if len(q) else None,'width',float(abs(q[:,1]).max()) if len(q) else None)
 if len(q):
  ids=p.np.where((abs(p.vr[:,2]-z)<.13)&(abs(p.vr[:,1])<.15))[0]
  if len(ids):
   i=min(ids,key=lambda j:p.vr[j,0]);print('center sample',i,p.vr[i].round(3),p.bidx[i].tolist(),p.wgt[i].round(3).tolist())
