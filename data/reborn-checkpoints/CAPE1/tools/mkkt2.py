import struct, os, hashlib
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])
rel = 'Character/RebornUIR3A/KulTiran/Female/KulTiranFemale.m2'
m, s = read(rel.replace('/', BS)); cur = bytes(m)
print('client now serves', s, hashlib.sha256(cur).hexdigest()[:16])
root = 'D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261113/'
orig = open(root + 'claudefix_20261113_阶段KTCAPE1A_库尔提拉斯女披风透明材质改不透明_Claude/00_真原件备份_回滚用/Character/RebornUIR3A/KulTiran/Female/KulTiranFemale.m2', 'rb').read()
print('equals saved original:', cur == orig)
nM, oM = struct.unpack_from('<II', orig, 0x70)
fpos = oM + 2*4; bpos = fpos + 2
print('material2 flags', struct.unpack_from('<H', orig, fpos)[0], 'blend', struct.unpack_from('<H', orig, bpos)[0])
assert struct.unpack_from('<HH', orig, fpos) == (0, 1)
new = bytearray(orig); struct.pack_into('<H', new, fpos, 4)
base = root + 'claudefix_20261113_阶段KTCAPE1B_库尔提拉斯女披风材质改双面渲染_Claude'
for sub, data in (('00_真原件备份_回滚用', orig), ('01_只需导入这1个文件', bytes(new))):
    d = os.path.join(base, sub, 'Character', 'RebornUIR3A', 'KulTiran', 'Female'); os.makedirs(d, exist_ok=True)
    open(os.path.join(d, 'KulTiranFemale.m2'), 'wb').write(data)
    print(sub, hashlib.sha256(data).hexdigest()[:16])
print('changed offsets', [i for i in range(len(orig)) if orig[i] != new[i]])
