# -*- coding: utf-8 -*-
"""SLIM1A: collect every retail file the ported maps and models need into a decoded cache, so that a client
copy works without the local retail installation. Reads D:\\wow12 only; writes only under D:\\_zsdc\\slim.

  python collect.py          collect (resumable: files already cached are not fetched again)
"""
import io, os, re, shutil, struct, subprocess, sys, time, pickle

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
J = os.path.join
W = r'D:\_zsdc\slim'
PROBE = r'D:\_zsdc\fx\build\Release\RetailAssetProbe.exe'
CLIENT = u'C:\\000ref\\WarcraftXL试装_client'
BUILD = 'c9fa1a64b0170829cc5c5c98c71025c3'
REL = J('Data', 'Retail', 'CdnCache', 'wow-' + BUILD)
STAGE = J(W, 'stage')                      # the client's cache plus everything fetched here
CACHE = J(STAGE, REL, '2', 'strict')
INI = J(STAGE, 'Data', 'Retail', 'collect.ini')


def setup():
    os.makedirs(CACHE, exist_ok=True)
    user = J(CLIENT, REL)
    mark = J(W, 'user_files.pkl')
    if not os.path.exists(mark):
        have = set()
        for root, _, files in os.walk(user):
            for f in files:
                if f.endswith('.tmp'):
                    continue
                rel = os.path.relpath(J(root, f), user)
                have.add(rel)
                dst = J(STAGE, REL, rel)
                if not os.path.exists(dst):
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    shutil.copyfile(J(root, f), dst)
        pickle.dump(have, open(mark, 'wb'))
        print('copied the client cache into the staging folder:', len(have), 'files')
    open(INI, 'w', newline='\n').write('mode=local\npath=D:/wow12/World of Warcraft69587\nproduct=wow\nregion=us\nbuild=%s\nlocale=2\n' % BUILD)


def path_of(fid):
    return J(CACHE, 'id-%d.bin' % fid)


def raw(fid):
    try:
        b = open(path_of(fid), 'rb').read()
    except OSError:
        return None
    if len(b) < 16 or b[:4] != b'WDC1' or struct.unpack_from('<I', b, 4)[0] != len(b) - 16:
        return None
    return b[16:]


def chunks(b, start=0):
    o = start
    while o + 8 <= len(b):
        tag = b[o:o + 4]
        n = struct.unpack_from('<I', b, o + 4)[0]
        yield tag, b[o + 8:o + 8 + n]
        o += 8 + n


def u32s(b):
    return struct.unpack_from('<%dI' % (len(b) // 4), b)


def refs(fid, kind, b):
    """(fileDataID, kind) pairs named by one file."""
    out = []
    add = lambda f, k: f and out.append((f, k))
    if kind == 'wdt':
        for t, d in chunks(b):
            if t == b'DIAM':
                for i in range(len(d) // 32):
                    e = struct.unpack_from('<8I', d, i * 32)
                    for f, k in zip(e, ('leaf', 'obj', 'leaf', 'tex', 'leaf', 'leaf', 'leaf', 'leaf')):
                        add(f, k)
            elif t == b'FDOM':
                for i in range(len(d) // 64):
                    if struct.unpack_from('<H', d, i * 64 + 56)[0] & 8:
                        add(struct.unpack_from('<I', d, i * 64)[0], 'wmo')
    elif kind == 'obj':
        for t, d in chunks(b):
            if t in (b'FDDM', b'DDLM'):
                for i in range(len(d) // 36):
                    if struct.unpack_from('<H', d, i * 36 + 34)[0] & 0x40:
                        add(struct.unpack_from('<I', d, i * 36)[0], 'm2')
            elif t == b'FDOM':
                for i in range(len(d) // 64):
                    if struct.unpack_from('<H', d, i * 64 + 56)[0] & 8:
                        add(struct.unpack_from('<I', d, i * 64)[0], 'wmo')
    elif kind == 'tex':
        for t, d in chunks(b):
            if t in (b'DIDM', b'DIHM'):
                for f in u32s(d):
                    add(f, 'leaf')
    elif kind == 'wmo':
        for t, d in chunks(b):
            if t == b'DIFG':
                for f in u32s(d):
                    add(f, 'leaf')
            elif t == b'IDOM':
                for f in u32s(d):
                    add(f & 0xFFFFFF, 'm2')
            elif t == b'ISOM':
                for f in u32s(d):
                    add(f, 'm2')
            elif t == b'TMOM':
                for i in range(len(d) // 64):
                    shader = struct.unpack_from('<I', d, i * 64 + 4)[0]
                    at = (12, 24, 36) if shader != 23 else (12, 24, 36, 40, 44, 48, 52, 56, 60)
                    for a in at:
                        f = struct.unpack_from('<I', d, i * 64 + a)[0]
                        if 1000 < f < 20000000:
                            add(f, 'leaf')
    elif kind in ('m2', 'skel'):
        for t, d in chunks(b):
            if t in (b'SFID', b'BFID', b'PFID'):
                for f in u32s(d):
                    add(f, 'leaf')
            elif t == b'TXID':
                for f in u32s(d):
                    add(f, 'leaf')
            elif t == b'AFID':
                for i in range(len(d) // 8):
                    add(struct.unpack_from('<I', d, i * 8 + 4)[0], 'leaf')
            elif t == b'SKID' and len(d) >= 4:
                add(u32s(d)[0], 'skel')
            elif t == b'SKPD' and len(d) >= 12:
                add(u32s(d)[2], 'skel')
            elif t in (b'RPID', b'GPID'):
                for f in u32s(d):
                    add(f, 'm2')
    return out


def fetch(fids, tag):
    """Let the engine's own CASC source read each file; it writes the decoded cache. The batch tool reports
    'fail' for a '.bin' name after the read (it cannot prepare that type), so the cache file is the result."""
    todo = [f for f in fids if raw(f) is None]
    for n in range(0, len(todo), 4000):
        part = todo[n:n + 4000]
        lst = J(W, 'list_%s.txt' % tag)
        open(lst, 'w', newline='\n').write(''.join('retail/%d.bin\n' % f for f in part))
        t = time.time()
        r = subprocess.run([PROBE, INI, '--batch', lst], capture_output=True, cwd=W, timeout=3600)
        got = sum(os.path.exists(path_of(f)) for f in part)
        print('  fetch %s %d-%d: %d of %d in %ds' % (tag, n, n + len(part), got, len(part), time.time() - t))
        if not got:
            print(r.stdout.decode('utf-8', 'replace')[-1500:], r.stderr.decode('utf-8', 'replace')[-1500:])
    return len(todo)


def main():
    setup()
    alias = []
    for line in open(J(CLIENT, 'Data', 'Retail', 'aliases_maps.csv'), encoding='utf-8-sig'):
        if ';' in line and not line.startswith('#'):
            a, p = line.strip().split(';', 1)
            alias.append((int(a), p))
    kind_of = lambda p: {'wdt': 'wdt', 'm2': 'm2', 'wmo': 'wmo'}.get(p.rsplit('.', 1)[-1].lower(), 'leaf')
    wave = {}
    for f, p in alias:
        wave[f] = kind_of(p)
    seen, source = {}, {f: p for f, p in alias}
    roots = [(f, p) for f, p in alias]
    level = 0
    while wave:
        level += 1
        print('level', level, ':', len(wave), 'files')
        fetch(sorted(wave), 'L%d' % level)
        nxt = {}
        for f, k in wave.items():
            seen[f] = k
        for f, k in wave.items():
            b = raw(f)
            if b is None or k == 'leaf':
                continue
            for g, gk in refs(f, k, b):
                if g not in seen:
                    if nxt.get(g, 'leaf') == 'leaf':
                        nxt[g] = gk
                    source.setdefault(g, f)
                elif seen[g] == 'leaf' and gk != 'leaf':
                    nxt[g] = gk
        wave = nxt
    missing = [f for f in seen if raw(f) is None]
    kinds = {}
    for f, k in seen.items():
        kinds[k] = kinds.get(k, 0) + 1
    pickle.dump({'seen': seen, 'missing': missing, 'source': source, 'alias': alias}, open(J(W, 'closure.pkl'), 'wb'))
    size = sum(os.path.getsize(path_of(f)) for f in seen if os.path.exists(path_of(f)))
    print('closure', len(seen), kinds, 'size %.2f GB' % (size / 2 ** 30), 'could not be read', len(missing))
    for f in missing[:30]:
        print('  missing', f, seen[f], 'named by', source.get(f))


if __name__ == '__main__':
    main()
