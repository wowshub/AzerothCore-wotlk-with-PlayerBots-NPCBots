# -*- coding: utf-8 -*-
import sys, struct, ctypes, os
sys.stdout.reconfigure(encoding='utf-8')
BS=chr(92)
L=ctypes.CDLL(r'D:\_zsdc\pkg\StormLib.dll')
CL=r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendclient\newrebornWOWli20261107beAscend\Data'+BS
files=[f for f in os.listdir(CL) if f.lower().endswith('.mpq') and os.path.isfile(CL+f)]
files+= ['enUS'+BS+f for f in os.listdir(CL+'enUS') if f.lower().endswith('.mpq') and os.path.isfile(CL+'enUS'+BS+f)]
order=sorted(files,key=lambda s:s.lower())
H=[]
for f in order:
    h=ctypes.c_void_p()
    if L.SFileOpenArchive(CL+f,0,0x100,ctypes.byref(h)): H.append((f,h))
def read(name):
    for f,h in reversed(H):
        fh=ctypes.c_void_p()
        if L.SFileOpenFileEx(h,name.encode(),0,ctypes.byref(fh)):
            sz=L.SFileGetFileSize(fh,None)&0xFFFFFFFF
            if sz==0xFFFFFFFF: L.SFileCloseFile(fh); continue
            buf=ctypes.create_string_buffer(sz); got=ctypes.c_uint()
            L.SFileReadFile(fh,buf,sz,ctypes.byref(got),None); L.SFileCloseFile(fh)
            return buf.raw[:got.value], f
    return None,None
hits=[]
for f,h in H:
    fh=ctypes.c_void_p()
    if L.SFileOpenFileEx(h,(b'DBFilesClient'+BS.encode()+b'GameObjectDisplayInfo.dbc'),0,ctypes.byref(fh)):
        L.SFileCloseFile(fh); hits.append(f)
print('GameObjectDisplayInfo.dbc found in (load order):',hits)
d,src=read('DBFilesClient'+BS+'GameObjectDisplayInfo.dbc')
n,rc,fc,rs,ss=struct.unpack_from('<4sIIII',d,0); st=20+rc*rs
def s(o):
    e=d.index(b'\0',st+o); return d[st+o:e].decode('latin1')
print('effective from',src,'rows',rc,'fields',fc)
for i in range(rc):
    f=struct.unpack_from('<%dI'%fc,d,20+i*rs)
    if f[0] in (661,): print('id',f[0],'model',s(f[1]))
    if 'guardtower' in s(f[1]).lower(): print('  guardtower row id',f[0],s(f[1]))
