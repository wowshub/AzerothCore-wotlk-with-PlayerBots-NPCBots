import io,sys,struct,pickle,os
sys.stdout=io.TextIOWrapper(sys.stdout.buffer,encoding='utf-8')
exec(open(r'D:\_zsdc\slim\collect.py',encoding='utf-8').read().split('def main():')[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)",''))
C=pickle.load(open(J(W,'closure.pkl'),'rb'))
nw=sw=sg=allg=0; size=0; list_=[]
for fid,k in C['seen'].items():
    if k!='wmo': continue
    ch={t:d for t,d in chunks(raw(fid))}
    if b'DHOM' not in ch or b'DIFG' not in ch: continue
    nw+=1; n=struct.unpack_from('<I',ch[b'DHOM'],4)[0]; g=u32s(ch[b'DIFG'])[:n]
    hit=[]
    for f in g:
        b=raw(f) if f else None
        if not b: continue
        allg+=1
        m=[d for t,d in chunks(b) if t==b'PGOM'][0]
        fl=struct.unpack_from('<I',m,8)[0]
        if struct.unpack_from('<I',m,60)[0]&0xC0 and fl&0x2000: hit.append(f); size+=len(b)
    if hit: sw+=1; sg+=len(hit); list_.append((fid,len(hit)))
print('buildings',nw,'groups',allg,'buildings with indoor split groups',sw,'such groups',sg,'size MB',round(size/2**20))
print(sorted(list_,key=lambda x:-x[1])[:10])
