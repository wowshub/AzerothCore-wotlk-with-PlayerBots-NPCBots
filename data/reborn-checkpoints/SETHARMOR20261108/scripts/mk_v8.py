# -*- coding: utf-8 -*-
"""v8: make every mapping bilaterally symmetric (the standard character texture is shared by the left and right half of the body).
torso : u = |azimuth| / pi   (front at the left edge of the region, back at the right edge, both sides in the middle)
legs  : angle around the leg axis, measured on the mirrored (outer = +) side
tail  : angle uses |y|
Applied to the male builder (-> seth_build8.py, out8) and to the female script in place."""
D = r'D:\_zsdc' + '\\'
BS = chr(92)


def fix_classify(t):
    pairs = [
        ("ang = (math.atan2(z - 0.8, y) + math.pi) / (2 * math.pi)", "ang = (math.atan2(z - 0.8, abs(y)) + math.pi / 2) / math.pi"),
        ("ang = (math.atan2(y - side * 0.17, x - X0) + math.pi) / (2 * math.pi)", "ang = (math.atan2((y - side * 0.17) * side, x - X0) + math.pi) / (2 * math.pi)"),
    ]
    for old, new in pairs:
        assert t.count(old) == 1, (t.count(old), old)
        t = t.replace(old, new)
    # torso (two places: the head parking and the real torso) use the mirrored azimuth
    old = "(math.atan2(y, x - X0) + math.pi) / (2 * math.pi)"
    assert t.count(old) == 2, t.count(old)
    t = t.replace(old, "abs(math.atan2(y, x - X0)) / math.pi")
    return t


# male builder
m = open(D + 'seth_build7.py', encoding='utf-8').read()
m = fix_classify(m)
m = m.replace("OUT = WORK + r'" + BS + "out7'", "OUT = WORK + r'" + BS + "out8'")
assert 'out8' in m
# the male classify also has the ArmUpper/ArmLower/Hand angle (x, z only): symmetric already.
open(D + 'seth_build8.py', 'w', encoding='utf-8').write(m)
b = open(D + 'seth_bake7.py', encoding='utf-8').read().replace(BS + "out7" + BS, BS + "out8" + BS).replace("bake7_png", "bake8_png").replace("bake7_report", "bake8_report")
open(D + 'seth_bake8.py', 'w', encoding='utf-8').write(b)
f = open(D + 'seth_bake_faces7.py', encoding='utf-8').read().replace(BS + "out7" + BS, BS + "out8" + BS).replace("bake7_png", "bake8_png")
open(D + 'seth_bake_faces8.py', 'w', encoding='utf-8').write(f)
v = open(D + 'seth_verify7.py', encoding='utf-8').read().replace('out7', 'out8')
open(D + 'seth_verify8.py', 'w', encoding='utf-8').write(v)

# female script
fe = open(D + 'seth_female.py', encoding='utf-8').read()
fe = fix_classify(fe)
open(D + 'seth_female.py', 'w', encoding='utf-8').write(fe)
print('v8 male scripts derived; female script patched')
