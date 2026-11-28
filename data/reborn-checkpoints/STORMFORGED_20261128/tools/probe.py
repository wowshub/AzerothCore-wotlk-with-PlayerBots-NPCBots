from pathlib import Path
from hashlib import sha256
from struct import unpack_from as u
import sys
w=Path(__file__).resolve().parent
r=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
c=Path(sys.argv[1])
mpq={};sys.argv=['','x','x']
exec((r/'000Ascendupdate/000Ascendupdate20261121/codexwork_WOW64NEUTRAL3P/verify_mpq.py').read_text('utf8').split('baseline=digest(original)')[0],mpq)
def read(arc,key):
    h=mpq['open_mpq'](arc,0x100)
    try:
        return mpq['read'](h,key)
    except OSError as e:
        if e.winerror in (2,1002):return None
        raise
    finally:mpq['require'](mpq['d'].SFileCloseArchive(h))
def layers(key):
    arcs=sorted((x for x in (c/'Data').glob('*.mpq') if x.is_file()),key=lambda p:p.name.lower())
    for arc in arcs:
        try:v=read(arc,key)
        except PermissionError: print("locked",arc.name,key);continue
        if v is not None:yield arc.name,v
def take(key,top=True):
    found=list(layers(key)); print(key,[x[0] for x in found],flush=True)
    return found[-1 if top else 0][1]
def rows(b):
    _,n,cols,size,sl=u('<4s4I',b)
    assert 20+n*size+sl==len(b)
    return size,[b[20+i*size:20+(i+1)*size] for i in range(n)],b[20+n*size:]
def row(b,index):
    size,rr,s=rows(b)
    return next(v for v in rr if u('<I',v)[0]==index),s
def modelinfo(b):
    n,vert=u('<II',b,60);boneN,bones=u('<II',b,44)
    _,keys=u('<II',b,52)
    na,a=u('<II',b,240);nl,l=u('<II',b,248)
    print('mesh',n,boneN,'bounds',u('<7f',b,160))
    if nl>11:
        i=u('<H',b,l+22)[0]
        if i<na:
            head=u('<h',b,keys+12)[0] if keys else -1
            bp=lambda j:u('<3f',b,bones+j*88+76) if j>=0 else None
            print('attachment',u('<IH2x3f',b,a+i*40),'head',head,bp(head))
            if head>=0:
                vv=[u('<3f',b,vert+j*48) for j in range(n) if head in b[vert+j*48+16:vert+j*48+20]]
                if vv:print('head weighted bounds',tuple((round(min(v[i] for v in vv),3),round(max(v[i] for v in vv),3)) for i in range(3)))
if __name__=='__main__':
    for k in ('CharBaseInfo','CharStartOutfit','Item','ItemDisplayInfo','SkillRaceClassInfo','Spell'):
        for n,b in layers('DBFilesClient/'+k+'.dbc'):
            (w/(n+'-'+k+'.dbc')).write_bytes(b)
            if k=='SkillRaceClassInfo':
                _,rr,_=rows(b); print(n,'Runeforging skill 776', [u('<8I',v) for v in rr if u('<I',v,4)[0]==776])
        print(k,[x.name for x in w.glob('*-'+k+'.dbc')])
    fit=next(w.glob('Patch-XA.mpq-CharStartOutfit.dbc'))
    for v in rows(fit.read_bytes())[1]:
        if v[4:6]==bytes((121,6)):print('OUTFIT',v[6],u('<24i',v,8))
    d=take('DBFilesClient/ItemDisplayInfo.dbc')
    for id in (15340,51738):
        v,s=row(d,id)
        off=u('<I',v,4)[0];print('display',id,s[off:s.index(0,off)])
        stem=s[off:s.index(0,off)].decode().split('.')[0]
        for suffix in ('OrM','OrF','HuM','HuF','ScM','ScF'):
            found=list(layers(f'Item/ObjectComponents/Head/{stem}_{suffix}.m2'))
            if found:
                print('head file',stem,suffix,found[-1][0]);modelinfo(found[-1][1]); (w/(stem+'_'+suffix+'.m2')).write_bytes(found[-1][1])
    for sex in ('Male','Female'):
        name='MurlocHorde'+sex+'.m2'
        b=take('custom/rebornfit/murloc/'+name);(w/name).write_bytes(b); modelinfo(b)
