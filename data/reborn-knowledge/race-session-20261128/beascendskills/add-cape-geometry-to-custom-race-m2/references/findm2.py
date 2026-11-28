import sys, ctypes
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])
pat = sys.argv[1].encode()
L.SFileFindFirstFile.restype = ctypes.c_void_p
L.SFileFindFirstFile.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_char_p]
L.SFileFindNextFile.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
L.SFileFindClose.argtypes = [ctypes.c_void_p]
for f, h in H:
    buf = ctypes.create_string_buffer(2048)
    fh = L.SFileFindFirstFile(h, pat, buf, None)
    if not fh: continue
    n = 0
    while True:
        name = buf.raw[:260].split(b'\0')[0].decode('latin1')
        if name.lower().endswith(('.m2', '.skin')) or len(sys.argv) > 2: print(f, name); n += 1
        if not L.SFileFindNextFile(fh, buf): break
    L.SFileFindClose(fh)
