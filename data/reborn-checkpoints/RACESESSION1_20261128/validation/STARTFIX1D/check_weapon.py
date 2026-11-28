exec((__import__('pathlib').Path(__file__).parent/'check_pose.py').read_text().split('for ident in [')[0])
results=[]
for ident in [0,4,5]:
 seq=p.u('<h',base,ofs+ident*2)[0]
 for ms in [0,350,650]:
  R,T,body=p.posed(seq,ms);cape=(weights[:,:3,None]*(np.einsum('vi,kij->vkj',points,R[[10,6,2]])+T[[10,6,2]])).sum(1)
  ct=[]
  for row in range(8):
   for col in range(6):
    j=row*7+col;ct.extend([[j,j+7,j+1],[j+1,j+7,j+8]])
  tri=cape[np.array(ct)];a=tri[:,1,1:]-tri[:,0,1:];c=tri[:,2,1:]-tri[:,0,1:];det=a[:,0]*c[:,1]-a[:,1]*c[:,0];valid=abs(det)>1e-7;tri,a,c,det=tri[valid],a[valid],c[valid],det[valid]
  vec=np.array([p.cos(.08)*p.cos(.47),p.cos(.08)*p.sin(.47),-p.sin(.08)])
  gaps=[]
  for k in np.linspace(0,1.45,15):
   q=(np.array([-.49,-.42,2.05])+.9*k*vec)@R[72]+T[72];d=q[1:]-tri[:,0,1:];l=(d[:,0]*c[:,1]-d[:,1]*c[:,0])/det;m=(a[:,0]*d[:,1]-a[:,1]*d[:,0])/det;mask=(l>=0)&(m>=0)&(l+m<=1);x=tri[:,0,0]+l*(tri[:,1,0]-tri[:,0,0])+m*(tri[:,2,0]-tri[:,0,0])
   if mask.any():gaps.append(float(x[mask].min()-q[0]))
  print(ident,ms,'sword outside cape gap',np.round(gaps,3))
