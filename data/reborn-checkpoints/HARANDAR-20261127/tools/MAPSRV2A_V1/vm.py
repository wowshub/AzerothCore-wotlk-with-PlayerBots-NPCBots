# -*- coding: utf-8 -*-
"""vmaps + mmaps for maps 12570 and 12694 (same pipeline as the island run VMAP12175A)."""
import os, sys, struct, ctypes, shutil, subprocess, time, glob, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
exec(open(r'D:\_zsdc\maps2\prep.py', encoding='utf-8').read().split("if __name__")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
SRV = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend'
CL = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendclient\newrebornWOWli20261122beAscend\Data'
V = r'D:\_vm\n2'
STOCK = ['common.MPQ', 'common-2.MPQ', 'expansion.MPQ', 'lichking.MPQ', 'patch.MPQ', 'patch-2.MPQ', 'patch-3.MPQ']
L = ctypes.CDLL(r'D:\_zsdc\pkg\StormLib.dll')
t0 = time.time()
STEP = sys.argv[1]


def log(*a):
    print('[%5ds]' % (time.time() - t0), *a)


def run(cmd, cwd, logf):
    with open(logf, 'wb') as fo:
        return subprocess.run(cmd, cwd=cwd, stdout=fo, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode


if STEP == 'prepare':
    assert not os.path.exists(V), V + ' already exists'
    stage = J(V, 'stage')
    shutil.copytree(J(W, 'stage'), stage)          # tiles, WDTs, Map.dbc (two rows), LiquidType.dbc
    os.makedirs(J(stage, 'retail'))
    n = 0
    for sub in ('wmo', 'm2'):
        for p in glob.glob(J(W, sub, '*.*')):
            shutil.copy2(p, J(stage, 'retail', os.path.basename(p)))
            n += 1
    gd = open(J(SRV, 'Data', 'dbc', 'GameObjectDisplayInfo.dbc'), 'rb').read()
    _, rc2, fc2, rs2, ss2 = struct.unpack_from('<4sIIII', gd, 0)
    open(J(stage, 'DBFilesClient', 'GameObjectDisplayInfo.dbc'), 'wb').write(struct.pack('<4sIIII', b'WDBC', 0, fc2, rs2, 1) + b'\0')
    os.makedirs(J(V, 'Data'))
    for s in STOCK:
        os.link(J(CL, s), J(V, 'Data', s))
    allfiles = []
    for dp, _dn, fn in os.walk(stage):
        allfiles += [(J(dp, f), os.path.relpath(J(dp, f), stage)) for f in fn]
    cap = 1
    while cap < len(allfiles) + 64:
        cap *= 2
    h = ctypes.c_void_p()
    mp = J(V, 'Data', 'patch-4.MPQ')
    assert L.SFileCreateArchive(mp, 0x01000000, cap, ctypes.byref(h)), ctypes.GetLastError()
    bad = sum(0 if L.SFileAddFileEx(h, q, rel.encode(), 0x80000200, 0x02, 0x02) else 1 for q, rel in allfiles)
    L.SFileCloseArchive(h)
    log('patch-4.MPQ', os.path.getsize(mp) // 1048576, 'MB, files', len(allfiles), 'failed', bad, 'assets', n)

elif STEP == 'vmap':
    rd = J(V, 'run')
    os.makedirs(J(rd, 'vmaps'), exist_ok=True)
    for f in ('vmap4_extractor.exe', 'vmap4_assembler.exe'):
        shutil.copy2(J(SRV, f), J(rd, f))
    d = open(J(rd, 'vmap4_assembler.exe'), 'rb').read()
    open(J(rd, 'vmap4_assembler_fix.exe'), 'wb').write(d.replace(b'VMAP047\0', b'VMAP048\0'))
    log('extract exit', run([J(rd, 'vmap4_extractor.exe'), '-d', J(V, 'Data') + os.sep], rd, J(rd, 'extract.log')))
    log('assemble exit', run([J(rd, 'vmap4_assembler_fix.exe'), 'Buildings', 'vmaps'], rd, J(rd, 'assemble.log')))
    v = os.listdir(J(rd, 'vmaps'))
    log('vmaps files', len(v), {m: len([x for x in v if x.startswith(str(m))]) for m in MAPS})

elif STEP == 'mmap':
    mm = J(V, 'mm')
    for s in ('maps', 'vmaps', 'mmaps'):
        os.makedirs(J(mm, s), exist_ok=True)
    for f in os.listdir(J(V, 'run', 'vmaps')):
        shutil.copy2(J(V, 'run', 'vmaps', f), J(mm, 'vmaps', f))
    shutil.copy2(r'D:\_hlbg_build\mmaps-config.yaml', J(mm, 'mmaps-config.yaml'))
    shutil.copy2(J(SRV, 'mmaps_generator.exe'), J(mm, 'mmaps_generator.exe'))
    n = 0
    for mid in MAPS:
        for p in glob.glob(J(W, 'ext', 'maps', '%d*.map' % mid)):
            shutil.copy2(p, J(mm, 'maps', os.path.basename(p)))
            n += 1
    log('map tiles copied', n)
    for mid in MAPS:
        log(mid, 'mmaps exit', run([J(mm, 'mmaps_generator.exe'), str(mid)], mm, J(mm, 'mmaps_%d.log' % mid)))
        log(mid, 'mmaps files', len([f for f in os.listdir(J(mm, 'mmaps')) if f.startswith(str(mid))]))
