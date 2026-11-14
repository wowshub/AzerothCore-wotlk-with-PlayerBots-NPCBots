exec((__import__('pathlib').Path(__file__).parent/'inspect_inputs.py').read_text('utf8').split("for n in ['Patch-YB.mpq'")[0])
from PIL import Image
import io
m=R(str(c/'Data/Patch-YI.mpq'));paths=set();report=[]
for fn in ['RebornNativeMechagnome.bin','RebornNativeEarthenEyes.bin']:
 b=(w/'client_patch/Esteria'/fn).read_bytes();_,_,n=struct.unpack_from('<3I',b)
 for i in range(n):
  row=struct.unpack_from('<7I128s',b,12+i*156)
  if row[1]==1:paths.add(row[7].split(b'\0')[0].decode())
for p in sorted(paths):
 b=m.read_file(p);assert b and b[:4]==b'BLP2',p;wi,he=struct.unpack_from('<II',b,12);off=struct.unpack_from('<I',b,20)[0]
 if b[8]==3:im=Image.frombytes('RGBA',(wi,he),b[off:off+wi*he*4],'raw','BGRA')
 else:im=Image.open(io.BytesIO(b));im.load()
 report.append({'path':p,'sha256':hashlib.sha256(b).hexdigest(),'dimensions':im.size})
m.close();(w/'texture-validation.json').write_text(json.dumps(report,indent=2),'utf8')
# Current installed native variants match the original generator geoset vocabulary,
# not the upstream's later full geometry/topology. Preserve current skin/animation.
for p in (w/'model_patch').rglob('*.m2'):
 b=p.read_bytes();old=(w.parent/'codexwork_WOW64RACEPORT1B/backup_models'/p.relative_to(w/'model_patch')).read_bytes();assert b==old
(w/'data-test.log').write_text('PASS %d material paths decoded; restored pre-B native M2 exactly; no SKIN/UV/bone/animation replacement\n'%len(paths),'utf8');print('PASS',len(paths),'eye atlas paths decode')
