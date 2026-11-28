import sys,json
from pathlib import Path
import numpy as np
from struct import unpack_from as u
w=Path('stormforged-intake');out=w/'helmetfit1f';p=Path('helmet-work/src/WoW/Common/ComponentCore/EsteriaAppearance.cpp')
s=p.read_text('utf8');(out/'EsteriaAppearance.before-1f.cpp').write_text(s,'utf8')
old='''            // Authored helmet helpers have an extra tilt (and female scale1.74).
            // Retain the authored crown position on the actual animated head.
            child->SetAttachmentFrame(female ? 18u : 30u, socket.m_position, 1.0f);'''
new='''            // STORMFORGED1F: female socket108 is 0.182 in front of head18.
            // Directly reusing its crown on head18 put the hood ahead of the face.
            // Fit the existing GnF hood envelope to the native anatomical skull;
            // absolute frame, so retry/preview refresh cannot accumulate shifts.
            if (female) child->SetAttachmentFrame(18u, C3Vector(0.065f, 0.0f, 2.272f), 0.785f);
            else child->SetAttachmentFrame(30u, socket.m_position, 1.0f);'''
assert s.count(old)==1;s=s.replace(old,new);p.write_text(s,'utf8')
# Geometry regression based on the extracted standard GnF DK hood (item34652)
# and the current female anatomical skull, not screenshot pixel estimates.
data=json.loads((w/'helmet-measure.json').read_text())['Female'];head=np.array(data['head_bounds'])
hood=(out/'models/Item/ObjectComponents/Head/Helm_Plate_DeathKnight_B_01_GnF.m2').read_bytes()
count,offset=u('<2I',hood,60)
points=np.array([u('<3f',hood,offset+48*i) for i in range(count)])
before=points+np.array(data['socket'][2:]);after=points*.785+np.array([.065,0,2.272])
def bounds(p):return np.array([p.min(0),p.max(0)])
oldBounds=bounds(before);newBounds=bounds(after)
assert oldBounds[0,0]>head[0,0]+.1,'old forward-placement fixture should fail skull enclosure'
assert np.all(newBounds[0]<=head[0]+.001) and np.all(newBounds[1]>=head[1]-.001)
# Every non-helmet part of the cumulative source remains byte-for-byte intact.
assert s.replace(new,old)==(out/'EsteriaAppearance.before-1f.cpp').read_text('utf8')
report={'target_hash':data['input_hash'],'reference_helmet_sha256':__import__('hashlib').sha256(hood).hexdigest(),'target_skull_bounds':head.tolist(),'old_helmet_bounds':oldBounds.tolist(),'candidate_helmet_bounds':newBounds.tolist(),'candidate_bone':18,'candidate_crown':[.065,0,2.272],'candidate_scale':.785,'forward_shift':.065-data['socket'][2],'height_shift':2.272-data['socket'][4],'other_source_unchanged':True,'old_failure_reproduced':True,'game_visual_validation':'pending; bbox enclosure is not proof of hollow helmet interior fit'}
(out/'verification.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
