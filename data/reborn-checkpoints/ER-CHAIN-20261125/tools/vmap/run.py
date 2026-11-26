"""vmaps + mmaps for map 12175 (Exile's Reach, retail geometry converted to 3.3.5 bytes). Same pipeline as the HLBG VMAP1A run (vm_run_batch.py)."""
import os, sys, struct, ctypes, shutil, subprocess, time, glob
sys.stdout.reconfigure(encoding='utf-8')
BS = chr(92)
SRV = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend' + BS
CL = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendclient\newrebornWOWli20261122beAscend\Data' + BS
SRC = r'D:\_zsdc\vm12175' + BS
W = r'D:\_vm\er' + BS
MAPID = 12175
STOCK = ['common.MPQ', 'common-2.MPQ', 'expansion.MPQ', 'lichking.MPQ', 'patch.MPQ', 'patch-2.MPQ', 'patch-3.MPQ']
L = ctypes.CDLL(r'D:\_zsdc\pkg\StormLib.dll')
t0 = time.time()
STEP = sys.argv[1]


def log(*a):
    print('[%5ds]' % (time.time() - t0), *a, flush=True)


def run(cmd, cwd, logf):
    with open(logf, 'wb') as fo:
        return subprocess.run(cmd, cwd=cwd, stdout=fo, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode


if STEP == 'prepare':
    assert not os.path.exists(W), W + ' already exists'
    stage = W + 'stage' + BS
    os.makedirs(stage + 'World' + BS + 'Maps' + BS + 'ExilesReach')
    os.makedirs(stage + 'retail')
    os.makedirs(stage + 'DBFilesClient')
    n = 0
    for p in glob.glob(r'D:\_zsdc\er_srv\out2\ExilesReach*.*'):
        shutil.copy2(p, stage + 'World' + BS + 'Maps' + BS + 'ExilesReach' + BS + os.path.basename(p)); n += 1
    for sub in ('wmo', 'm2'):
        for p in glob.glob(SRC + sub + BS + '*.*'):
            shutil.copy2(p, stage + 'retail' + BS + os.path.basename(p)); n += 1
    dbc = SRV + 'Data' + BS + 'dbc' + BS
    md = open(dbc + 'Map.dbc', 'rb').read()
    _, rc, fc, rs, ss = struct.unpack_from('<4sIIII', md, 0)
    sel = [md[20 + i * rs:20 + (i + 1) * rs] for i in range(rc) if struct.unpack_from('<I', md, 20 + i * rs)[0] == MAPID]
    assert len(sel) == 1, 'Map.dbc row'
    open(stage + 'DBFilesClient' + BS + 'Map.dbc', 'wb').write(struct.pack('<4sIIII', b'WDBC', 1, fc, rs, ss) + sel[0] + md[20 + rc * rs:])
    shutil.copy2(dbc + 'LiquidType.dbc', stage + 'DBFilesClient' + BS + 'LiquidType.dbc')
    gd = open(dbc + 'GameObjectDisplayInfo.dbc', 'rb').read()
    _, rc2, fc2, rs2, ss2 = struct.unpack_from('<4sIIII', gd, 0)
    open(stage + 'DBFilesClient' + BS + 'GameObjectDisplayInfo.dbc', 'wb').write(struct.pack('<4sIIII', b'WDBC', 0, fc2, rs2, 1) + b'\0')
    os.makedirs(W + 'Data')
    for s in STOCK:
        os.link(CL + s, W + 'Data' + BS + s)
    allfiles = []
    for dp, dn, fn in os.walk(stage):
        for f in fn:
            q = os.path.join(dp, f); allfiles.append((q, os.path.relpath(q, stage)))
    cap = 1
    while cap < len(allfiles) + 64:
        cap *= 2
    h = ctypes.c_void_p()
    mp = W + 'Data' + BS + 'patch-4.MPQ'
    assert L.SFileCreateArchive(mp, 0x01000000, cap, ctypes.byref(h)), ctypes.GetLastError()
    bad = sum(0 if L.SFileAddFileEx(h, q, rel.encode(), 0x80000200, 0x02, 0x02) else 1 for q, rel in allfiles)
    L.SFileCloseArchive(h)
    log('patch-4.MPQ', os.path.getsize(mp), 'files', len(allfiles), 'failed', bad)

elif STEP == 'vmap':
    rd = W + 'run' + BS
    os.makedirs(rd + 'vmaps', exist_ok=True)
    for f in ('vmap4_extractor.exe', 'vmap4_assembler.exe'):
        shutil.copy2(SRV + f, rd + f)
    d = open(rd + 'vmap4_assembler.exe', 'rb').read()
    open(rd + 'vmap4_assembler_fix.exe', 'wb').write(d.replace(b'VMAP047\0', b'VMAP048\0'))
    log('extract exit', run([rd + 'vmap4_extractor.exe', '-d', W + 'Data'], rd, rd + 'extract.log'))
    log('assemble exit', run([rd + 'vmap4_assembler_fix.exe', 'Buildings', 'vmaps'], rd, rd + 'assemble.log'))
    v = os.listdir(rd + 'vmaps')
    log('vmaps files', len(v), 'tree/tiles for map', len([x for x in v if x.startswith(str(MAPID))]))

elif STEP == 'mmap':
    mm = W + 'mm' + BS
    os.makedirs(mm + 'maps', exist_ok=True)
    os.makedirs(mm + 'vmaps', exist_ok=True)
    os.makedirs(mm + 'mmaps', exist_ok=True)
    for f in os.listdir(W + 'run' + BS + 'vmaps'):
        shutil.copy2(W + 'run' + BS + 'vmaps' + BS + f, mm + 'vmaps' + BS + f)
    shutil.copy2(r'D:\_hlbg_build\mmaps-config.yaml', mm + 'mmaps-config.yaml')
    shutil.copy2(SRV + 'mmaps_generator.exe', mm + 'mmaps_generator.exe')
    n = 0
    for f in os.listdir(SRV + 'Data' + BS + 'maps'):
        if f.endswith('.map') and f[:-8] == str(MAPID):
            shutil.copy2(SRV + 'Data' + BS + 'maps' + BS + f, mm + 'maps' + BS + f); n += 1
    log('map tiles copied', n)
    log('mmaps exit', run([mm + 'mmaps_generator.exe', str(MAPID)], mm, mm + 'mmaps.log'))
    log('mmaps files', len(os.listdir(mm + 'mmaps')))
