# -*- coding: utf-8 -*-
import sys, os, ctypes, glob, struct
sys.stdout.reconfigure(encoding='utf-8')
exec(open(r'D:\_zsdc\cls_check.py', encoding='utf-8').read().split("D = r'")[0])
D = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendclient\newrebornWOWli20261107beAscend\Data'
names = ['Character\\Draenei\\Male\\DraeneiMale.m2', 'Character\\Draenei\\Female\\DraeneiFemale.m2',
         'Character\\Human\\Male\\HumanMale.m2', 'Character\\Human\\Female\\HumanFemale.m2']
os.makedirs(r'D:\_zsdc\dr', exist_ok=True)
order = ['common.MPQ', 'common-2.MPQ', 'expansion.MPQ', 'lichking.MPQ', 'patch.MPQ', 'patch-2.MPQ', 'patch-3.MPQ']
found = {}
for arch in order:
    p = D + '\\' + arch
    if not os.path.exists(p): continue
    h = ctypes.c_void_p()
    if not L.SFileOpenArchive(p, 0, 0x100, ctypes.byref(h)): print('noopen', arch); continue
    for nm in names:
        f = ctypes.c_void_p()
        if L.SFileOpenFileEx(h, nm.encode(), 0, ctypes.byref(f)):
            sz = L.SFileGetFileSize(f, None)
            buf = ctypes.create_string_buffer(sz); n = ctypes.c_uint()
            L.SFileReadFile(f, buf, sz, ctypes.byref(n), None); L.SFileCloseFile(f)
            found[nm] = (arch, buf.raw[:n.value])      # later archives override earlier
    L.SFileCloseArchive(h)
for nm, (arch, b) in found.items():
    open(r'D:\_zsdc\dr\%s' % nm.split('\\')[-1], 'wb').write(b)
    print(arch, len(b), nm, b[:4], struct.unpack_from('<I', b, 4)[0])
print('missing', [n for n in names if n not in found])
